# -*- coding: utf-8 -*-
"""
benchmark_cuda.py – Đo thời gian CUDA encode/decode trên folder ảnh
=====================================================================
Tính toán latency của Encoder + Decoder (Baseline và QAT) trên 5k images.
Bao gồm đo CPU/GPU frequency và power consumption trong khi chạy inference.

Cách chạy:
  python benchmark_cuda.py --image-dir /path/to/5k/images
  python benchmark_cuda.py --image-dir /path/to/5k/images \\
                           --enc-base ./models/best_enc.pth \\
                           --dec-base ./models/best_dec.pth \\
                           --enc-qat ./models/best_enc_qat.pth \\
                           --dec-qat ./models/best_dec_qat.pth \\
                           --output ./benchmark_results.json

Phụ thuộc cho Hardware Monitoring:
  pip install psutil          # CPU frequency (Windows/Linux/macOS)
  pip install nvidia-ml-py    # GPU frequency + power (NVIDIA only)

  CPU Power (RAPL): Chỉ hỗ trợ trên Linux với Intel CPU.
                    Trên Windows → tự động bỏ qua, ghi "N/A".

Latency definition (batch_size >= 1):
  latencies_ms   = wall-clock time to process 1 BATCH (ms/batch)
  throughput     = sum(batch_sizes) / sum(latencies_ms) * 1000  (img/s)
  Khi batch_size=1 → latency per-batch == latency per-image.
"""

import os
import sys
import json
import time
import platform
import argparse
import logging
import threading
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime

import numpy as np
from PIL import Image
import torch
import torch.nn as nn
import torchvision.transforms as transforms

# ─── LOGGING ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s  %(message)s",
    datefmt="%H:%M:%S"
)
log = logging.getLogger("benchmark")

# ─── TORCHMETRICS ─────────────────────────────────────────────────────────────
try:
    from torchmetrics.image.psnr import PeakSignalNoiseRatio
    from torchmetrics.image.ssim import StructuralSimilarityIndexMeasure
    TORCHMETRICS_OK = True
except ImportError:
    TORCHMETRICS_OK = False
    log.warning("torchmetrics not found – using fallback PSNR/SSIM implementation.")

# ─── PSUTIL (CPU freq) ────────────────────────────────────────────────────────
try:
    import psutil
    PSUTIL_OK = True
except ImportError:
    PSUTIL_OK = False
    log.warning("psutil not found – CPU frequency monitoring disabled. Run: pip install psutil")

# ─── PYNVML (GPU freq + power) ────────────────────────────────────────────────
try:
    import pynvml
    pynvml.nvmlInit()
    PYNVML_OK = True
    log.info("✅ pynvml available – GPU monitoring enabled")
except Exception:
    PYNVML_OK = False
    log.warning("pynvml not available – GPU monitoring disabled. Run: pip install nvidia-ml-py")

# ─── RAPL CPU power path (Linux Intel only) ───────────────────────────────────
_IS_LINUX = platform.system() == "Linux"
_RAPL_PATH = "/sys/class/powercap/intel-rapl:0/energy_uj"
_RAPL_OK = _IS_LINUX and os.path.exists(_RAPL_PATH)
if not _RAPL_OK:
    if _IS_LINUX:
        log.warning("RAPL not accessible – CPU power monitoring disabled. "
                    "Try: sudo chmod a+r /sys/class/powercap/intel-rapl:0/energy_uj")
    else:
        log.info(f"Platform: {platform.system()} – CPU power via RAPL not supported (Linux-only). "
                 "CPU power will be reported as N/A.")


# ─────────────────────────────────────────────────────────────────────────────
# HARDWARE MONITOR
# ─────────────────────────────────────────────────────────────────────────────

def _read_rapl_uj() -> Optional[float]:
    if not _RAPL_OK:
        return None
    try:
        with open(_RAPL_PATH) as f:
            return float(f.read().strip())
    except Exception:
        return None


class HardwareMonitor:
    def __init__(self, interval_ms: float = 50, gpu_index: int = 0):
        self.interval_s  = interval_ms / 1000.0
        self.gpu_index   = gpu_index
        self._stop_event = threading.Event()
        self._thread: Optional[threading.Thread] = None

        self.cpu_freq_mhz: List[float] = []
        self.cpu_power_w:  List[float] = []
        self.gpu_freq_mhz: List[float] = []
        self.gpu_power_w:  List[float] = []

        self._gpu_handle = None
        if PYNVML_OK:
            try:
                self._gpu_handle = pynvml.nvmlDeviceGetHandleByIndex(gpu_index)
            except Exception as e:
                log.warning(f"GPU handle error (index={gpu_index}): {e}")

    def _poll(self):
        rapl_prev_uj = _read_rapl_uj()
        t_prev = time.perf_counter()

        while not self._stop_event.is_set():
            if PSUTIL_OK:
                freq = psutil.cpu_freq()
                if freq and freq.current > 0:
                    self.cpu_freq_mhz.append(freq.current)

            if _RAPL_OK:
                rapl_now_uj = _read_rapl_uj()
                t_now = time.perf_counter()
                if rapl_prev_uj is not None and rapl_now_uj is not None:
                    delta_j = (rapl_now_uj - rapl_prev_uj) * 1e-6
                    delta_t = t_now - t_prev
                    if delta_t > 0 and delta_j >= 0:
                        self.cpu_power_w.append(delta_j / delta_t)
                rapl_prev_uj = rapl_now_uj
                t_prev = t_now

            if self._gpu_handle is not None:
                try:
                    clk_mhz = pynvml.nvmlDeviceGetClockInfo(
                        self._gpu_handle, pynvml.NVML_CLOCK_GRAPHICS)
                    pwr_mw  = pynvml.nvmlDeviceGetPowerUsage(self._gpu_handle)
                    self.gpu_freq_mhz.append(float(clk_mhz))
                    self.gpu_power_w.append(pwr_mw / 1000.0)
                except Exception:
                    pass

            self._stop_event.wait(timeout=self.interval_s)

    def start(self):
        self.cpu_freq_mhz.clear()
        self.cpu_power_w.clear()
        self.gpu_freq_mhz.clear()
        self.gpu_power_w.clear()
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._poll, daemon=True)
        self._thread.start()

    def stop(self):
        self._stop_event.set()
        if self._thread:
            self._thread.join(timeout=2.0)

    @staticmethod
    def _stat(arr: List[float]) -> Dict:
        if not arr:
            return {"mean": None, "min": None, "max": None, "std": None, "n_samples": 0}
        a = np.array(arr, dtype=np.float64)
        return {
            "mean":      round(float(np.mean(a)), 3),
            "min":       round(float(np.min(a)),  3),
            "max":       round(float(np.max(a)),  3),
            "std":       round(float(np.std(a)),  3),
            "n_samples": len(arr),
        }

    def get_stats(self) -> Dict:
        return {
            "cpu_freq_mhz": self._stat(self.cpu_freq_mhz),
            "cpu_power_w":  self._stat(self.cpu_power_w),
            "gpu_freq_mhz": self._stat(self.gpu_freq_mhz),
            "gpu_power_w":  self._stat(self.gpu_power_w),
            "monitoring_available": {
                "cpu_freq":  PSUTIL_OK,
                "cpu_power": _RAPL_OK,
                "gpu_freq":  PYNVML_OK,
                "gpu_power": PYNVML_OK,
            }
        }


# ─────────────────────────────────────────────────────────────────────────────
# MODEL ARCHITECTURE
# ─────────────────────────────────────────────────────────────────────────────
_Q_SCALE             = 1024.0
INT16_MIN, INT16_MAX = -32768, 32767


class FakeQuantizeQ6_10(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x):
        return torch.round(x * _Q_SCALE).clamp(INT16_MIN, INT16_MAX) / _Q_SCALE

    @staticmethod
    def backward(ctx, grad):
        return grad


def qat_quant(x):
    return FakeQuantizeQ6_10.apply(x)


class QuantIdentity(nn.Module):
    def forward(self, x):
        return qat_quant(x)


class SeparableConv2d(nn.Module):
    def __init__(self, in_c, out_c, kernel_size=3, stride=1, padding=1):
        super().__init__()
        self.depthwise = nn.Conv2d(in_c, in_c, kernel_size, stride, padding,
                                   groups=in_c, bias=False)
        self.pointwise = nn.Conv2d(in_c, out_c, kernel_size=1, bias=False)

    def forward(self, x):
        return self.pointwise(self.depthwise(x))


class QATSeparableConv2d(nn.Module):
    def __init__(self, in_c, out_c, kernel_size=3, stride=1, padding=1, activation=None):
        super().__init__()
        self.depthwise  = nn.Conv2d(in_c, in_c, kernel_size, stride, padding,
                                    groups=in_c, bias=False)
        self.pointwise  = nn.Conv2d(in_c, out_c, kernel_size=1, bias=False)
        self.bn_fused   = False
        self.activation = activation
        self._act_fn    = nn.ReLU(inplace=False) if activation == 'relu' else None
        self._quant_act    = QuantIdentity()
        self.probe_dw      = nn.Identity()
        self.probe_pw_pre  = nn.Identity()
        self.probe_pw_post = nn.Identity()

    def forward(self, x):
        w_dw = qat_quant(self.depthwise.weight)
        x = torch.nn.functional.conv2d(
            x, w_dw, None,
            self.depthwise.stride, self.depthwise.padding,
            self.depthwise.dilation, self.depthwise.groups)
        x = qat_quant(x)
        x = self.probe_dw(x)

        if self.bn_fused:
            x = torch.nn.functional.conv2d(
                x, self.pointwise.weight, self.pointwise.bias,
                self.pointwise.stride, self.pointwise.padding)
        else:
            w_pw = qat_quant(self.pointwise.weight)
            x = torch.nn.functional.conv2d(
                x, w_pw, None,
                self.pointwise.stride, self.pointwise.padding)

        x = self.probe_pw_pre(x)
        if self._act_fn is not None:
            x = self._act_fn(x)
            x = self._quant_act(x)
            x = self.probe_pw_post(x)
        else:
            x = self.probe_pw_post(x)
        return x


class Encoder(nn.Module):
    def __init__(self, base_c=16):
        super().__init__()

        def conv_block(in_c, out_c, stride=1):
            return nn.Sequential(
                SeparableConv2d(in_c, out_c, stride=stride),
                nn.BatchNorm2d(out_c), nn.ReLU(True))

        def conv_block_no_relu(in_c, out_c, stride=1):
            return nn.Sequential(SeparableConv2d(in_c, out_c, stride=stride))

        self.head       = conv_block(6,          base_c)
        self.down1      = conv_block(base_c,     base_c*2,  stride=2)
        self.down2      = conv_block(base_c*2,   base_c*4,  stride=2)
        self.down3      = conv_block(base_c*4,   base_c*8,  stride=2)
        self.bottleneck = conv_block(base_c*8,   base_c*8,  stride=2)
        self.upsample   = nn.Upsample(scale_factor=2, mode='nearest')
        self.up1        = conv_block(base_c*8*2, base_c*4)
        self.up2        = conv_block(base_c*4*2, base_c*2)
        self.up3        = conv_block(base_c*2*2, base_c)
        self.up4        = conv_block(base_c*2,   base_c)
        self.tail       = conv_block_no_relu(base_c, 3)

    def forward(self, x_cover, x_secret):
        x    = torch.cat([x_cover, x_secret], dim=1)
        head = self.head(x)
        d1   = self.down1(head)
        d2   = self.down2(d1)
        d3   = self.down3(d2)
        b    = self.bottleneck(d3)
        u1   = self.up1(torch.cat([self.upsample(b),  d3], dim=1))
        u2   = self.up2(torch.cat([self.upsample(u1), d2], dim=1))
        u3   = self.up3(torch.cat([self.upsample(u2), d1], dim=1))
        u4   = self.up4(torch.cat([self.upsample(u3), head], dim=1))
        return torch.clamp(x_cover + self.tail(u4), -1, 1)


class QATEncoder(nn.Module):
    def __init__(self, base_c=16):
        super().__init__()

        def qat_block(in_c, out_c, stride=1):
            return nn.Sequential(
                QATSeparableConv2d(in_c, out_c, stride=stride, activation=None),
                nn.BatchNorm2d(out_c), nn.ReLU(inplace=True), QuantIdentity())

        def qat_block_no_act(in_c, out_c):
            return nn.Sequential(QATSeparableConv2d(in_c, out_c, activation=None))

        self.head       = qat_block(6,          base_c)
        self.down1      = qat_block(base_c,     base_c*2,  stride=2)
        self.down2      = qat_block(base_c*2,   base_c*4,  stride=2)
        self.down3      = qat_block(base_c*4,   base_c*8,  stride=2)
        self.bottleneck = qat_block(base_c*8,   base_c*8,  stride=2)
        self.upsample   = nn.Upsample(scale_factor=2, mode='nearest')
        self.up1        = qat_block(base_c*8*2, base_c*4)
        self.up2        = qat_block(base_c*4*2, base_c*2)
        self.up3        = qat_block(base_c*2*2, base_c)
        self.up4        = qat_block(base_c*2,   base_c)
        self.tail       = qat_block_no_act(base_c, 3)

    def forward(self, x_cover, x_secret):
        x_cover  = qat_quant(x_cover)
        x_secret = qat_quant(x_secret)
        x  = torch.cat([x_cover, x_secret], dim=1)
        h  = self.head(x)
        d1 = self.down1(h)
        d2 = self.down2(d1)
        d3 = self.down3(d2)
        b  = self.bottleneck(d3)
        u1 = self.up1(torch.cat([self.upsample(b),  d3], dim=1))
        u2 = self.up2(torch.cat([self.upsample(u1), d2], dim=1))
        u3 = self.up3(torch.cat([self.upsample(u2), d1], dim=1))
        u4 = self.up4(torch.cat([self.upsample(u3), h],  dim=1))
        feat = self.tail[0](u4)
        out  = qat_quant(feat)
        return torch.clamp(x_cover + out, -1, 1)


class Decoder(nn.Module):
    def __init__(self, base_c=16):
        super().__init__()

        def conv_block(in_c, out_c, stride=1):
            return nn.Sequential(
                nn.Conv2d(in_c, out_c, kernel_size=3, stride=stride, padding=1, bias=True),
                nn.BatchNorm2d(out_c), nn.LeakyReLU(0.1, inplace=True))

        self.head       = conv_block(3,           base_c)
        self.down1      = conv_block(base_c,      base_c*2,  stride=2)
        self.down2      = conv_block(base_c*2,    base_c*4,  stride=2)
        self.down3      = conv_block(base_c*4,    base_c*8,  stride=2)
        self.down4      = conv_block(base_c*8,    base_c*16, stride=2)
        self.bottleneck = conv_block(base_c*16,   base_c*16, stride=2)
        self.upsample   = nn.Upsample(scale_factor=2, mode='bilinear', align_corners=True)
        self.up1        = conv_block(base_c*16*2, base_c*8)
        self.up2        = conv_block(base_c*8*2,  base_c*4)
        self.up3        = conv_block(base_c*4*2,  base_c*2)
        self.up4        = conv_block(base_c*2*2,  base_c)
        self.up5        = conv_block(base_c*2,    base_c)
        self.tail       = nn.Sequential(
            nn.Conv2d(base_c, 3, kernel_size=3, padding=1), nn.Tanh())

    def forward(self, x_stego):
        c1 = self.head(x_stego)
        c2 = self.down1(c1)
        c3 = self.down2(c2)
        c4 = self.down3(c3)
        c5 = self.down4(c4)
        b  = self.bottleneck(c5)
        u1 = self.up1(torch.cat([self.upsample(b),  c5], dim=1))
        u2 = self.up2(torch.cat([self.upsample(u1), c4], dim=1))
        u3 = self.up3(torch.cat([self.upsample(u2), c3], dim=1))
        u4 = self.up4(torch.cat([self.upsample(u3), c2], dim=1))
        u5 = self.up5(torch.cat([self.upsample(u4), c1], dim=1))
        return self.tail(u5)


# ─────────────────────────────────────────────────────────────────────────────
# TRANSFORMS
# ─────────────────────────────────────────────────────────────────────────────
IMG_SIZE = 128
_transform = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize([0.5]*3, [0.5]*3),
])


def pil_to_tensor(img: Image.Image, device: torch.device) -> torch.Tensor:
    return _transform(img.convert("RGB")).unsqueeze(0).to(device)


# ─────────────────────────────────────────────────────────────────────────────
# METRICS: PSNR / SSIM
# ─────────────────────────────────────────────────────────────────────────────
if TORCHMETRICS_OK:
    _dev     = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    _psnr_fn = PeakSignalNoiseRatio(data_range=1.0).to(_dev)
    _ssim_fn = StructuralSimilarityIndexMeasure(data_range=1.0).to(_dev)

    def _psnr(a, b): return _psnr_fn(a, b).item()
    def _ssim(a, b): return _ssim_fn(a, b).item()
else:
    def _psnr(a, b):
        mse = torch.mean((a - b) ** 2).item()
        return float("inf") if mse == 0 else 10 * np.log10(1.0 / mse)

    def _ssim(a, b):
        af = a.flatten().float()
        bf = b.flatten().float()
        if len(af) == 0:
            return 1.0
        return torch.corrcoef(torch.stack([af, bf]))[0, 1].item()


def calc_metrics(pred: torch.Tensor, ref: torch.Tensor) -> Dict:
    p = ((pred + 1) / 2).clamp(0, 1)
    r = ((ref  + 1) / 2).clamp(0, 1)
    return {"psnr": round(_psnr(p, r), 4), "ssim": round(_ssim(p, r), 4)}


# ─────────────────────────────────────────────────────────────────────────────
# LOAD MODEL
# ─────────────────────────────────────────────────────────────────────────────
def load_model(model: nn.Module, path: str, name: str,
               device: torch.device) -> nn.Module:
    if not os.path.exists(path):
        log.warning(f"⚠️  {name} checkpoint not found: {path} – using random weights.")
        return model.to(device).eval()

    try:
        raw = torch.load(path, map_location=device, weights_only=True)
    except Exception as e:
        log.warning(f"Fallback to weights_only=False: {e}")
        raw = torch.load(path, map_location=device, weights_only=False)

    if isinstance(raw, dict):
        for k in ("enc", "encoder", "dec", "decoder", "state_dict"):
            if k in raw:
                raw = raw[k]
                break
    model.load_state_dict(raw, strict=True)
    model.to(device).eval()
    log.info(f"✅ Loaded {name} ← {path}")
    return model


# ─────────────────────────────────────────────────────────────────────────────
# CUDA BENCHMARK
# ─────────────────────────────────────────────────────────────────────────────

# ── FIX 1/3: thêm batch_sizes + throughput_img_per_s vào empty stats ─────────
def _empty_model_stats() -> Dict:
    return {
        # Raw observations – mỗi phần tử = 1 batch
        "latencies_ms": [],   # wall-clock time of 1 batch (ms/batch)
        "batch_sizes":  [],   # số ảnh trong batch tương ứng
        "psnr_vals":    [],
        "ssim_vals":    [],
        # Aggregated – điền sau khi pass xong
        "total_ms":             0.0,
        "mean_ms":              0.0,   # mean batch latency
        "std_ms":               0.0,
        "min_ms":               0.0,
        "max_ms":               0.0,
        "throughput_img_per_s": 0.0,   # tổng ảnh / tổng thời gian
        "mean_psnr": 0.0,
        "std_psnr":  0.0,
        "min_psnr":  0.0,
        "max_psnr":  0.0,
        "mean_ssim": 0.0,
        "std_ssim":  0.0,
        "min_ssim":  0.0,
        "max_ssim":  0.0,
        "hw": None,
    }


class CUDABenchmark:
    """
    Benchmark latency + quality metrics (PSNR/SSIM) + hardware metrics
    (CPU/GPU frequency & power) cho Baseline và QAT Encoder/Decoder.

    Latency semantics:
      latencies_ms[i] = thời gian thực (wall-clock) để xử lý batch thứ i.
      Khi batch_size=1  → đây là single-sample inference latency.
      Khi batch_size=N  → đây là batch latency (N ảnh song song trên GPU).
      Throughput = sum(batch_sizes) / sum(latencies_ms) * 1000  (img/s).
    """

    def __init__(self, image_dir: str,
                 enc_base_path: str, dec_base_path: str,
                 enc_qat_path:  str, dec_qat_path:  str,
                 base_channel: int = 16,
                 force_cpu:    bool = False,
                 encoder_only: bool = False,
                 monitor_interval_ms: float = 50.0,
                 gpu_index: int = 0):

        self.image_dir           = image_dir
        self.force_cpu           = force_cpu
        self.encoder_only        = encoder_only
        self.monitor_interval_ms = monitor_interval_ms
        self.gpu_index           = gpu_index

        self.device = (torch.device("cpu")
                       if force_cpu
                       else torch.device("cuda" if torch.cuda.is_available() else "cpu"))

        if TORCHMETRICS_OK:
            global _psnr_fn, _ssim_fn
            _psnr_fn = PeakSignalNoiseRatio(data_range=1.0).to(self.device)
            _ssim_fn = StructuralSimilarityIndexMeasure(data_range=1.0).to(self.device)

        log.info(f"📍 Device: {self.device}")
        log.info(f"📁 Image directory: {image_dir}")
        log.info(f"🔧 CPU freq monitor:  {'ON' if PSUTIL_OK else 'OFF'}")
        log.info(f"🔧 CPU power monitor: {'ON (RAPL)' if _RAPL_OK else 'OFF (N/A on this OS/HW)'}")
        log.info(f"🔧 GPU monitor:       {'ON (pynvml)' if PYNVML_OK else 'OFF'}")

        log.info("📦 Loading models...")
        self.enc_base = load_model(Encoder(base_channel),    enc_base_path, "Baseline Encoder", self.device)
        self.dec_base = (load_model(Decoder(base_channel),   dec_base_path, "Baseline Decoder", self.device)
                         if not encoder_only else None)
        self.enc_qat  = load_model(QATEncoder(base_channel), enc_qat_path,  "QAT Encoder",      self.device)
        self.dec_qat  = (load_model(Decoder(base_channel),   dec_qat_path,  "QAT Decoder",      self.device)
                         if not encoder_only else None)

        self._load_image_pairs()

    # ── Image pairs ───────────────────────────────────────────────────────────
    def _load_image_pairs(self):
        self.image_pairs: List[Tuple[str, str]] = []
        image_dir = Path(self.image_dir)
        sample_dirs = sorted(image_dir.glob("sample_?????"))

        for sd in sample_dirs:
            c = sd / "cover.png"
            s = sd / "secret.png"
            if c.exists() and s.exists():
                self.image_pairs.append((str(c), str(s)))
            else:
                log.warning(f"⚠️  Missing files in {sd.name}: "
                            f"cover={c.exists()}, secret={s.exists()}")

        log.info(f"📷 Found {len(self.image_pairs)} image pairs from {len(sample_dirs)} dirs")
        if not self.image_pairs:
            log.error("❌ No image pairs found!")
            sys.exit(1)

    # ── Single-model pass (với hw monitoring) ────────────────────────────────
    def _run_model_pass(
        self,
        model_key:   str,
        model_fn,
        pairs:       List[Tuple[str, str]],
        batch_size:  int,
        ref_fn=None,
        num_batches_total: int = 0,
        log_prefix:  str = "",
    ) -> Dict:
        stats    = _empty_model_stats()
        n        = len(pairs)
        n_batches = (n + batch_size - 1) // batch_size

        monitor = HardwareMonitor(
            interval_ms=self.monitor_interval_ms,
            gpu_index=self.gpu_index)
        monitor.start()

        for batch_idx in range(n_batches):
            s = batch_idx * batch_size
            e = min(s + batch_size, n)
            batch_pairs = pairs[s:e]
            bs = len(batch_pairs)

            try:
                covers  = [pil_to_tensor(Image.open(cp), self.device) for cp, _ in batch_pairs]
                secrets = [pil_to_tensor(Image.open(sp), self.device) for _, sp in batch_pairs]
                cover_t  = torch.cat(covers,  dim=0)
                secret_t = torch.cat(secrets, dim=0)

                with torch.no_grad():
                    t0    = time.perf_counter()
                    out_t = model_fn(cover_t, secret_t)
                    if self.device.type == "cuda":
                        torch.cuda.synchronize()
                    lat_ms = (time.perf_counter() - t0) * 1000

                # ── FIX 2/3: lưu batch latency nguyên, không chia bs ─────────
                stats["latencies_ms"].append(lat_ms)   # ms/batch
                stats["batch_sizes"].append(bs)        # để tính throughput

                # Quality metrics (vẫn tính per-image)
                ref_t = ref_fn(out_t, cover_t, secret_t) if ref_fn else cover_t
                for i in range(bs):
                    m = calc_metrics(out_t[i:i+1], ref_t[i:i+1])
                    stats["psnr_vals"].append(m["psnr"])
                    stats["ssim_vals"].append(m["ssim"])

                if (batch_idx + 1) % max(1, n_batches // 10) == 0:
                    log.info(f"  [{log_prefix}] {e}/{n} samples "
                             f"({batch_idx+1}/{n_batches} batches) done")

            except Exception as exc:
                log.error(f"  [{log_prefix}] Batch {batch_idx} error: {exc}")

        monitor.stop()
        stats["hw"] = monitor.get_stats()

        # ── FIX 3/3: aggregate latency + throughput ───────────────────────────
        lats = stats["latencies_ms"]
        bsizes = stats["batch_sizes"]
        if lats:
            a = np.array(lats, dtype=np.float64)
            total_imgs = sum(bsizes)
            total_ms   = float(a.sum())
            stats.update(
                total_ms             = total_ms,
                mean_ms              = float(a.mean()),
                std_ms               = float(a.std()),
                min_ms               = float(a.min()),
                max_ms               = float(a.max()),
                # throughput = tổng ảnh / tổng thời gian (giây)
                throughput_img_per_s = round(total_imgs / (total_ms / 1000.0), 2),
            )

        psnrs = stats["psnr_vals"]
        if psnrs:
            a = np.array(psnrs)
            stats.update(mean_psnr=float(a.mean()), std_psnr=float(a.std()),
                         min_psnr=float(a.min()),   max_psnr=float(a.max()))

        ssims = stats["ssim_vals"]
        if ssims:
            a = np.array(ssims)
            stats.update(mean_ssim=float(a.mean()), std_ssim=float(a.std()),
                         min_ssim=float(a.min()),   max_ssim=float(a.max()))

        return stats

    # ── Main benchmark ────────────────────────────────────────────────────────
    def run_benchmark(self, limit: Optional[int] = None,
                      batch_size: int = 1) -> Dict:
        num_samples = (min(len(self.image_pairs), limit)
                       if limit else len(self.image_pairs))
        batch_size  = max(1, int(batch_size))
        pairs       = self.image_pairs[:num_samples]

        log.info(f"\n🚀 Benchmark: {num_samples} samples, batch_size={batch_size}, "
                 f"device={self.device}")
        log.info(f"   Latency unit: ms/batch  |  Throughput: img/s")
        log.info(f"   Monitoring interval: {self.monitor_interval_ms} ms\n")

        start_wall = time.perf_counter()

        log.info("▶  Pass 1/4: BASELINE ENCODER")
        stats_enc_base = self._run_model_pass(
            model_key="enc_base",
            model_fn=lambda cov, sec: self.enc_base(cov, sec),
            pairs=pairs, batch_size=batch_size,
            ref_fn=lambda out, cov, sec: cov,
            log_prefix="enc_base",
        )

        stats_dec_base = None
        if not self.encoder_only:
            log.info("▶  Pass 2/4: BASELINE DECODER")
            def dec_base_fn(cov, sec):
                with torch.no_grad():
                    stego = self.enc_base(cov, sec)
                return self.dec_base(stego)
            stats_dec_base = self._run_model_pass(
                model_key="dec_base",
                model_fn=dec_base_fn,
                pairs=pairs, batch_size=batch_size,
                ref_fn=lambda out, cov, sec: sec,
                log_prefix="dec_base",
            )

        log.info("▶  Pass 3/4: QAT ENCODER")
        stats_enc_qat = self._run_model_pass(
            model_key="enc_qat",
            model_fn=lambda cov, sec: self.enc_qat(cov, sec),
            pairs=pairs, batch_size=batch_size,
            ref_fn=lambda out, cov, sec: cov,
            log_prefix="enc_qat",
        )

        stats_dec_qat = None
        if not self.encoder_only:
            log.info("▶  Pass 4/4: QAT DECODER")
            def dec_qat_fn(cov, sec):
                with torch.no_grad():
                    stego = self.enc_qat(cov, sec)
                return self.dec_qat(stego)
            stats_dec_qat = self._run_model_pass(
                model_key="dec_qat",
                model_fn=dec_qat_fn,
                pairs=pairs, batch_size=batch_size,
                ref_fn=lambda out, cov, sec: sec,
                log_prefix="dec_qat",
            )

        total_time_s = time.perf_counter() - start_wall

        return {
            "timestamp":           datetime.now().isoformat(),
            "num_samples":         num_samples,
            "batch_size":          batch_size,
            "device":              str(self.device),
            "is_cuda":             self.device.type == "cuda",
            "encoder_only":        self.encoder_only,
            "total_time_s":        round(total_time_s, 3),
            "monitor_interval_ms": self.monitor_interval_ms,
            "hw_support": {
                "cpu_freq":  PSUTIL_OK,
                "cpu_power": _RAPL_OK,
                "gpu_freq":  PYNVML_OK,
                "gpu_power": PYNVML_OK,
            },
            "models": {
                "enc_base": stats_enc_base,
                "dec_base": stats_dec_base,
                "enc_qat":  stats_enc_qat,
                "dec_qat":  stats_dec_qat,
            }
        }

    # ── Summary helpers ───────────────────────────────────────────────────────
    @staticmethod
    def _fmt_hw_stat(stat: Optional[Dict], unit: str) -> str:
        if stat is None or stat.get("mean") is None:
            return "N/A"
        return (f"mean={stat['mean']:.1f} {unit}  "
                f"min={stat['min']:.1f}  max={stat['max']:.1f}  "
                f"std={stat['std']:.1f}  (n={stat['n_samples']})")

    def _print_hw_block(self, model_name: str, stats: Optional[Dict]):
        if stats is None:
            return
        hw = stats.get("hw")
        if hw is None:
            return
        log.info(f"    ── Hardware Monitoring ({model_name})")
        log.info(f"    CPU Freq:  {self._fmt_hw_stat(hw['cpu_freq_mhz'], 'MHz')}")
        log.info(f"    CPU Power: {self._fmt_hw_stat(hw['cpu_power_w'],  'W  ')}  "
                 f"{'(RAPL)' if _RAPL_OK else '(N/A - not Linux/Intel)'}")
        log.info(f"    GPU Freq:  {self._fmt_hw_stat(hw['gpu_freq_mhz'], 'MHz')}  "
                 f"{'(pynvml)' if PYNVML_OK else '(N/A - no pynvml)'}")
        log.info(f"    GPU Power: {self._fmt_hw_stat(hw['gpu_power_w'],  'W  ')}  "
                 f"{'(pynvml)' if PYNVML_OK else '(N/A - no pynvml)'}")
        log.info("")

    def print_summary(self, results: Dict):
        log.info("\n" + "="*80)
        log.info("📊 CUDA BENCHMARK SUMMARY")
        log.info("="*80)
        log.info(f"Timestamp:     {results['timestamp']}")
        log.info(f"Device:        {results['device']}")
        log.info(f"Using CUDA:    {'✅ YES' if results['is_cuda'] else '❌ NO (CPU mode)'}")
        log.info(f"Encoder Only:  {'✅ YES' if results['encoder_only'] else '❌ NO (full pipeline)'}")
        log.info(f"Batch size:    {results.get('batch_size', 1)}")
        log.info(f"Num samples:   {results['num_samples']}")
        log.info(f"Total time:    {results['total_time_s']:.2f}s")
        log.info(f"Monitor interval: {results['monitor_interval_ms']} ms")
        log.info(f"Latency unit:  ms/batch  (batch_size={results.get('batch_size',1)})")
        log.info("")

        models_to_show = (["enc_base", "enc_qat"] if self.encoder_only
                          else ["enc_base", "dec_base", "enc_qat", "dec_qat"])

        for model_name in models_to_show:
            stats = results["models"][model_name]
            if stats is None or not stats["latencies_ms"]:
                continue
            n_batches = len(stats["latencies_ms"])
            log.info(f"  {model_name.upper()}")
            log.info(f"    Batch latency mean/std : {stats['mean_ms']:.3f} / {stats['std_ms']:.3f} ms/batch")
            log.info(f"    Batch latency min/max  : {stats['min_ms']:.3f} / {stats['max_ms']:.3f} ms/batch")
            log.info(f"    Throughput             : {stats['throughput_img_per_s']:.2f} img/s")
            log.info(f"    Num batches observed   : {n_batches}")
            log.info(f"    PSNR (mean):             {stats['mean_psnr']:.4f} dB")
            log.info(f"    SSIM (mean):             {stats['mean_ssim']:.4f}")
            self._print_hw_block(model_name, stats)

        log.info("  THROUGHPUT COMPARISON")
        m = results["models"]
        bs = results.get("batch_size", 1)
        if self.encoder_only:
            tp_b = m["enc_base"]["throughput_img_per_s"]
            tp_q = m["enc_qat"]["throughput_img_per_s"]
            lat_b = m["enc_base"]["mean_ms"]
            lat_q = m["enc_qat"]["mean_ms"]
            log.info(f"    Baseline Encoder: {lat_b:.3f} ms/batch  →  {tp_b:.2f} img/s")
            log.info(f"    QAT Encoder:      {lat_q:.3f} ms/batch  →  {tp_q:.2f} img/s")
            log.info(f"    Speedup (QAT/Base): {tp_q/tp_b:.2f}x throughput  |  "
                     f"{lat_b/lat_q:.2f}x latency")
        else:
            tp_eb = m["enc_base"]["throughput_img_per_s"]
            tp_db = m["dec_base"]["throughput_img_per_s"]
            tp_eq = m["enc_qat"]["throughput_img_per_s"]
            tp_dq = m["dec_qat"]["throughput_img_per_s"]
            lat_eb = m["enc_base"]["mean_ms"]; lat_db = m["dec_base"]["mean_ms"]
            lat_eq = m["enc_qat"]["mean_ms"];  lat_dq = m["dec_qat"]["mean_ms"]
            b_e2e  = lat_eb + lat_db
            q_e2e  = lat_eq + lat_dq
            # E2E throughput = bs / e2e_time_s
            tp_b_e2e = bs / (b_e2e / 1000.0)
            tp_q_e2e = bs / (q_e2e / 1000.0)
            log.info(f"    Baseline E2E: {b_e2e:.3f} ms/batch  →  {tp_b_e2e:.2f} img/s")
            log.info(f"    QAT E2E:      {q_e2e:.3f} ms/batch  →  {tp_q_e2e:.2f} img/s")
            log.info(f"    Speedup (QAT/Base): {tp_q_e2e/tp_b_e2e:.2f}x throughput  |  "
                     f"{b_e2e/q_e2e:.2f}x latency")
        log.info("="*80)

    # ── Save JSON ─────────────────────────────────────────────────────────────
    def save_results_json(self, results: Dict, output_path: str):
        clean = {
            "timestamp":           results["timestamp"],
            "num_samples":         results["num_samples"],
            "batch_size":          results["batch_size"],
            "device":              results["device"],
            "is_cuda":             results["is_cuda"],
            "encoder_only":        results["encoder_only"],
            "total_time_s":        results["total_time_s"],
            "monitor_interval_ms": results["monitor_interval_ms"],
            "hw_support":          results["hw_support"],
            "latency_unit":        "ms_per_batch",
            "models": {}
        }

        for key, stats in results["models"].items():
            if stats is None:
                clean["models"][key] = None
                continue
            clean["models"][key] = {
                # Latency: wall-clock time per batch
                "latency_mean_ms":      round(stats["mean_ms"],              3),
                "latency_std_ms":       round(stats["std_ms"],               3),
                "latency_min_ms":       round(stats["min_ms"],               3),
                "latency_max_ms":       round(stats["max_ms"],               3),
                "latency_total_ms":     round(stats["total_ms"],             2),
                "latency_unit":         "ms_per_batch",
                # Throughput
                "throughput_img_per_s": stats["throughput_img_per_s"],
                "num_batches":          len(stats["latencies_ms"]),
                "num_samples":          sum(stats["batch_sizes"]),
                # Quality
                "psnr_mean": round(stats["mean_psnr"], 4),
                "psnr_std":  round(stats["std_psnr"],  4),
                "psnr_min":  round(stats["min_psnr"],  4),
                "psnr_max":  round(stats["max_psnr"],  4),
                "ssim_mean": round(stats["mean_ssim"], 4),
                "ssim_std":  round(stats["std_ssim"],  4),
                "ssim_min":  round(stats["min_ssim"],  4),
                "ssim_max":  round(stats["max_ssim"],  4),
                # Hardware
                "hw": stats.get("hw"),
            }

        os.makedirs(os.path.dirname(os.path.abspath(output_path)) or ".", exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(clean, f, indent=2)
        log.info(f"✅ JSON saved → {output_path}")

    # ── Save TXT report ───────────────────────────────────────────────────────
    def save_report_txt(self, results: Dict, output_path: str):
        os.makedirs(os.path.dirname(os.path.abspath(output_path)) or ".", exist_ok=True)

        def fmt(stat: Optional[Dict], unit: str, na_reason: str = "N/A") -> str:
            if stat is None or stat.get("mean") is None:
                return na_reason
            return (f"{stat['mean']:.1f} {unit}  "
                    f"(min {stat['min']:.1f} / max {stat['max']:.1f} / "
                    f"std {stat['std']:.1f} / n={stat['n_samples']})")

        def hw_block(f, model_label: str, hw: Optional[Dict]):
            if hw is None:
                f.write("  Hardware Monitoring: N/A (model did not run)\n\n")
                return
            sup = hw.get("monitoring_available", {})
            f.write(f"HARDWARE MONITORING – {model_label}\n")
            f.write("-" * 90 + "\n")
            f.write("  (Sampled in background thread during entire model pass)\n\n")
            f.write("  CPU Frequency (MHz):\n")
            f.write(f"    {fmt(hw['cpu_freq_mhz'], 'MHz')}\n" if sup.get("cpu_freq")
                    else "    N/A – psutil not installed\n")
            f.write("\n  CPU Package Power (Watts)  [RAPL – Linux/Intel only]:\n")
            if sup.get("cpu_power"):
                f.write(f"    {fmt(hw['cpu_power_w'], 'W')}\n")
            else:
                f.write("    N/A – not Linux or RAPL not accessible\n")
                f.write("    Tip: sudo chmod a+r /sys/class/powercap/intel-rapl:0/energy_uj\n")
            f.write("\n  GPU Core Frequency (MHz)  [pynvml / NVIDIA only]:\n")
            if sup.get("gpu_freq"):
                f.write(f"    {fmt(hw['gpu_freq_mhz'], 'MHz')}\n")
            else:
                f.write("    N/A – pynvml not installed or no NVIDIA GPU\n")
                f.write("    Tip: pip install nvidia-ml-py\n")
            f.write("\n  GPU Power Draw (Watts)    [pynvml / NVIDIA only]:\n")
            f.write(f"    {fmt(hw['gpu_power_w'], 'W')}\n" if sup.get("gpu_power")
                    else "    N/A – pynvml not installed or no NVIDIA GPU\n")
            f.write("\n")

        bs = results["batch_size"]

        with open(output_path, "w", encoding="utf-8") as f:
            f.write("=" * 90 + "\n")
            f.write("CUDA BENCHMARK REPORT – STEGANOGRAPHY ENCODER/DECODER\n")
            f.write("Includes: Latency · Throughput · PSNR · SSIM · CPU/GPU Frequency · CPU/GPU Power\n")
            f.write("=" * 90 + "\n\n")

            f.write("EXECUTION INFO\n")
            f.write("-" * 90 + "\n")
            f.write(f"  Timestamp:            {results['timestamp']}\n")
            f.write(f"  Total Samples:        {results['num_samples']}\n")
            f.write(f"  Batch Size:           {bs}\n")
            f.write(f"  Total Wall Time:      {results['total_time_s']:.2f} s\n")
            f.write(f"  Monitor Interval:     {results['monitor_interval_ms']:.0f} ms\n\n")

            f.write("HARDWARE & MONITORING SUPPORT\n")
            f.write("-" * 90 + "\n")
            sup = results["hw_support"]
            f.write(f"  Device:               {results['device']}\n")
            f.write(f"  Running on CUDA:      {'✅ YES (CUDA)' if results['is_cuda'] else '❌ NO (CPU mode)'}\n")
            f.write(f"  Encoder-Only Mode:    {'✅ YES' if results['encoder_only'] else '❌ NO (full pipeline)'}\n")
            f.write(f"  CPU Freq (psutil):    {'✅' if sup['cpu_freq']  else '❌ pip install psutil'}\n")
            f.write(f"  CPU Power (RAPL):     {'✅' if sup['cpu_power'] else '❌ Linux+Intel only'}\n")
            f.write(f"  GPU Freq+Power (nvml):{'✅' if sup['gpu_freq']  else '❌ pip install nvidia-ml-py'}\n\n")

            f.write("LATENCY & THROUGHPUT DEFINITION\n")
            f.write("-" * 90 + "\n")
            f.write("  Latency  = wall-clock time to process 1 BATCH (ms/batch)\n")
            f.write(f"  Batch size used = {bs}\n")
            if bs == 1:
                f.write("  → batch_size=1: latency per batch == latency per image (single-sample latency)\n")
            else:
                f.write(f"  → batch_size={bs}: latency covers {bs} images processed in parallel (GPU)\n")
                f.write("     Use Throughput (img/s) for per-image comparison across platforms.\n")
            f.write("  Throughput = total_images / total_time_seconds  (img/s)\n")
            f.write("  START: tensors enter model forward()\n")
            f.write("  END  : output exits model + torch.cuda.synchronize() (if CUDA)\n")
            f.write("  NOTE : image I/O and tensor host→device transfer excluded from timing\n\n")

            f.write("HW MONITORING METHODOLOGY\n")
            f.write("-" * 90 + "\n")
            f.write("  Each model runs ALL batches sequentially (pass-per-model).\n")
            f.write(f"  Background thread polls every {results['monitor_interval_ms']:.0f} ms.\n")
            f.write("  Reported values = aggregate over all samples in that model's pass.\n\n")

            f.write("DETAILED RESULTS BY MODEL\n")
            f.write("=" * 90 + "\n\n")

            model_labels = {
                "enc_base": "BASELINE ENCODER (Float32)",
                "dec_base": "BASELINE DECODER (Float32)",
                "enc_qat":  "QAT ENCODER (Quantized – primary focus)",
                "dec_qat":  "QAT DECODER (Quantized)",
            }
            models_to_report = (["enc_base", "enc_qat"] if results["encoder_only"]
                                 else ["enc_base", "dec_base", "enc_qat", "dec_qat"])

            for mkey in models_to_report:
                label = model_labels[mkey]
                stats = results["models"][mkey]
                f.write(f"{label}\n")
                f.write("-" * 90 + "\n")

                if stats is None or not stats["latencies_ms"]:
                    f.write("  No data collected.\n\n")
                    continue

                n_batches_obs = len(stats["latencies_ms"])
                total_imgs    = sum(stats["batch_sizes"])

                f.write(f"LATENCY METRICS (ms/batch, batch_size={bs}):\n")
                f.write(f"  Mean:        {stats['mean_ms']:.3f} ms\n")
                f.write(f"  Std Dev:     {stats['std_ms']:.3f} ms\n")
                f.write(f"  Min:         {stats['min_ms']:.3f} ms\n")
                f.write(f"  Max:         {stats['max_ms']:.3f} ms\n")
                f.write(f"  Total:       {stats['total_ms']:.2f} ms "
                        f"({n_batches_obs} batches / {total_imgs} images)\n\n")

                f.write(f"THROUGHPUT:\n")
                f.write(f"  {stats['throughput_img_per_s']:.2f} img/s\n")
                f.write(f"  (= {total_imgs} images / {stats['total_ms']/1000:.3f} s)\n\n")

                cmp_note = ("Stego vs Cover (imperceptibility)"
                            if "enc" in mkey
                            else "Recovered Secret vs Original Secret")
                f.write(f"QUALITY METRICS ({cmp_note}):\n")
                f.write(f"  PSNR – mean {stats['mean_psnr']:.4f} dB  "
                        f"std {stats['std_psnr']:.4f}  "
                        f"range [{stats['min_psnr']:.4f}, {stats['max_psnr']:.4f}]\n")
                f.write(f"  SSIM – mean {stats['mean_ssim']:.4f}     "
                        f"std {stats['std_ssim']:.4f}  "
                        f"range [{stats['min_ssim']:.4f}, {stats['max_ssim']:.4f}]\n")
                f.write("  Note: SSIM ∈ [-1, 1], PSNR: higher is better.\n\n")

                hw_block(f, label, stats.get("hw"))

            f.write("PERFORMANCE SUMMARY\n")
            f.write("=" * 90 + "\n\n")

            m = results["models"]
            if results["encoder_only"]:
                lat_b = m["enc_base"]["mean_ms"];  tp_b = m["enc_base"]["throughput_img_per_s"]
                lat_q = m["enc_qat"]["mean_ms"];   tp_q = m["enc_qat"]["throughput_img_per_s"]
                f.write("ENCODER LATENCY & THROUGHPUT:\n")
                f.write("-" * 90 + "\n")
                f.write(f"  Baseline : {lat_b:.3f} ms/batch  →  {tp_b:.2f} img/s\n")
                f.write(f"  QAT      : {lat_q:.3f} ms/batch  →  {tp_q:.2f} img/s\n\n")
                spd_lat = lat_b / lat_q if lat_q > 0 else 1.0
                spd_tp  = tp_q  / tp_b  if tp_b  > 0 else 1.0
                f.write("COMPARISON (QAT vs Baseline):\n")
                f.write("-" * 90 + "\n")
                f.write(f"  Latency  speedup: {spd_lat:.2f}x  "
                        f"({'QAT faster' if spd_lat >= 1.0 else 'Baseline faster'})\n")
                f.write(f"  Throughput gain:  {spd_tp:.2f}x\n\n")
            else:
                lat_eb = m["enc_base"]["mean_ms"]; lat_db = m["dec_base"]["mean_ms"]
                lat_eq = m["enc_qat"]["mean_ms"];  lat_dq = m["dec_qat"]["mean_ms"]
                b_e2e  = lat_eb + lat_db
                q_e2e  = lat_eq + lat_dq
                tp_b_e2e = bs / (b_e2e / 1000.0)
                tp_q_e2e = bs / (q_e2e / 1000.0)
                f.write("BASELINE (Float32) FULL PIPELINE:\n")
                f.write("-" * 90 + "\n")
                f.write(f"  Encode:   {lat_eb:.3f} ms/batch\n")
                f.write(f"  Decode:   {lat_db:.3f} ms/batch\n")
                f.write(f"  E2E:      {b_e2e:.3f} ms/batch  →  {tp_b_e2e:.2f} img/s\n\n")
                f.write("QAT (Quantized) FULL PIPELINE:\n")
                f.write("-" * 90 + "\n")
                f.write(f"  Encode:   {lat_eq:.3f} ms/batch\n")
                f.write(f"  Decode:   {lat_dq:.3f} ms/batch\n")
                f.write(f"  E2E:      {q_e2e:.3f} ms/batch  →  {tp_q_e2e:.2f} img/s\n\n")
                spd_lat = b_e2e / q_e2e if q_e2e > 0 else 1.0
                spd_tp  = tp_q_e2e / tp_b_e2e if tp_b_e2e > 0 else 1.0
                f.write("COMPARISON (QAT vs Baseline):\n")
                f.write("-" * 90 + "\n")
                f.write(f"  E2E Latency  speedup: {spd_lat:.2f}x  "
                        f"({'QAT faster' if spd_lat >= 1.0 else 'Baseline faster'})\n")
                f.write(f"  E2E Throughput gain:  {spd_tp:.2f}x\n\n")

            f.write("=" * 90 + "\n")
            f.write("END OF REPORT\n")
            f.write("=" * 90 + "\n")

        log.info(f"✅ Report saved → {output_path}")


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def _build_output_path(base_output: str, suffix: str) -> str:
    if base_output in (".", "") or base_output.endswith(os.sep) or os.path.isdir(base_output):
        return os.path.join(os.path.abspath(base_output), f"benchmark_{suffix}.json")
    base, ext = os.path.splitext(base_output)
    return f"{base}_{suffix}{ext or '.json'}"


def _build_report_path(base_output: str, suffix: str) -> str:
    if base_output in (".", "") or base_output.endswith(os.sep) or os.path.isdir(base_output):
        return os.path.join(os.path.abspath(base_output), f"benchmark_{suffix}_report.txt")
    base, _ = os.path.splitext(base_output)
    return f"{base}_{suffix}_report.txt"


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Benchmark CUDA encode/decode latency + CPU/GPU hw metrics"
    )
    parser.add_argument("--image-dir", required=True)
    parser.add_argument("--enc-base",  default="./models/best_enc.pth")
    parser.add_argument("--dec-base",  default="./models/best_dec.pth")
    parser.add_argument("--enc-qat",   default="./models/best_enc_qat.pth")
    parser.add_argument("--dec-qat",   default="./models/best_dec_qat.pth")
    parser.add_argument("--output",    default="./benchmark_results.json")
    parser.add_argument("--limit",     type=int, default=None)
    parser.add_argument("--batch-size",type=int, default=1)
    parser.add_argument("--cpu",       action="store_true")
    parser.add_argument("--encoder-only", action="store_true")
    parser.add_argument("--monitor-interval", type=float, default=50.0)
    parser.add_argument("--gpu-index", type=int, default=0)
    parser.add_argument("--cpu-then-gpu", action="store_true")
    parser.add_argument("--output-cpu",  default=None)
    parser.add_argument("--output-gpu",  default=None)
    parser.add_argument("--report-cpu",  default=None)
    parser.add_argument("--report-gpu",  default=None)
    parser.add_argument("--base-channel", type=int, default=16)

    args = parser.parse_args()

    def make_bench(force_cpu: bool) -> CUDABenchmark:
        return CUDABenchmark(
            args.image_dir,
            args.enc_base, args.dec_base,
            args.enc_qat,  args.dec_qat,
            base_channel=args.base_channel,
            force_cpu=force_cpu,
            encoder_only=args.encoder_only,
            monitor_interval_ms=args.monitor_interval,
            gpu_index=args.gpu_index,
        )

    def run_and_save(bench: CUDABenchmark, json_path: str, txt_path: str):
        res = bench.run_benchmark(args.limit, batch_size=args.batch_size)
        bench.print_summary(res)
        bench.save_results_json(res, json_path)
        bench.save_report_txt(res,  txt_path)

    if args.cpu_then_gpu:
        cpu_json = args.output_cpu or _build_output_path(args.output, "cpu")
        cpu_txt  = args.report_cpu or _build_report_path(args.output, "cpu")
        gpu_json = args.output_gpu or _build_output_path(args.output, "gpu")
        gpu_txt  = args.report_gpu or _build_report_path(args.output, "gpu")
        log.info("🚀 [1/2] CPU benchmark")
        run_and_save(make_bench(True),  cpu_json, cpu_txt)
        log.info("🚀 [2/2] GPU benchmark")
        run_and_save(make_bench(False), gpu_json, gpu_txt)
        return

    json_path = args.output
    txt_path  = os.path.splitext(args.output)[0] + "_report.txt"
    run_and_save(make_bench(args.cpu), json_path, txt_path)


if __name__ == "__main__":
    main()