# -*- coding: utf-8 -*-
"""
eval_ws_server.py  –  Laptop / Host · WebSocket Server
=======================================================
Nhận kết quả từ board KV260 qua WebSocket.
Chạy cả SW Baseline (Float32) VÀ SW QAT Encoder+Decoder độc lập,
ghi lại tốc độ (latency) encoder và decoder của từng model,
và tính đầy đủ 8 nhóm chỉ số so sánh:

  Nhóm nội bộ SW:
    [F] stego_baseline   vs cover          (imperceptibility Baseline)
    [G] recover_baseline vs secret         (decode quality Baseline)
    [H] stego_qat        vs cover          (imperceptibility QAT)
    [I] recover_qat      vs secret         (decode quality QAT)

  So sánh Baseline ↔ QAT:
    [J] stego_baseline   vs stego_qat      (Baseline encoder vs QAT encoder)
    [K] recover_baseline vs recover_qat    (Baseline decoder vs QAT decoder)

  So sánh với FPGA:
    [A] stego_fpga       vs cover          (imperceptibility FPGA)
    [B] stego_fpga       vs stego_baseline (FPGA vs Baseline)
    [C] stego_fpga       vs stego_qat      (FPGA vs QAT)
    [D] recover_fpga     vs secret         (decode quality FPGA)
    [E] recover_fpga     vs recover_baseline (FPGA recover vs Baseline recover)
    [L] recover_fpga     vs recover_qat    (FPGA recover vs QAT recover)

Giao thức nhị phân (Binary Frame) mỗi sample:
  ┌───────────────────────────────────────────────────────┐
  │  4 bytes (uint32 BE)  : độ dài JSON header            │
  │  N bytes              : UTF-8 JSON  (metrics + b64)   │
  │  M bytes              : PNG bytes  (stego_fpga)        │
  └───────────────────────────────────────────────────────┘

ACK trả về client:
  {"status": "ok", "sample_id": "...", "eval": {summary metrics}}

Cách chạy:
  python eval_ws_server.py                               # mặc định port 8765
  python eval_ws_server.py --port 9000
  python eval_ws_server.py --enc-base /path/enc.pth \\
                           --enc-qat  /path/enc_qat.pth \\
                           --dec-base /path/dec.pth \\
                           --dec-qat  /path/dec_qat.pth

Yêu cầu:
  pip install torch torchvision torchmetrics Pillow numpy matplotlib websockets
"""

# ─────────────────────────────────────────────────────────────────────────────
# 0. IMPORTS
# ─────────────────────────────────────────────────────────────────────────────
import os, sys, csv, json, time, struct, base64, logging, argparse, asyncio
import io
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

import numpy as np
from PIL import Image
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision.transforms as transforms

try:
    import websockets
    from websockets.server import serve as ws_serve
except ImportError:
    print("❌ websockets chưa cài: pip install websockets")
    sys.exit(1)

try:
    from torchmetrics.image.psnr import PeakSignalNoiseRatio
    from torchmetrics.image.ssim import StructuralSimilarityIndexMeasure
    TORCHMETRICS_OK = True
except ImportError:
    TORCHMETRICS_OK = False
    logging.warning("torchmetrics không tìm thấy – dùng fallback PSNR/SSIM.")


# ─────────────────────────────────────────────────────────────────────────────
# 1. CẤU HÌNH
# ─────────────────────────────────────────────────────────────────────────────
class ServerConfig:
    # ── WebSocket ─────────────────────────────────────────────────────────────
    HOST           = "0.0.0.0"
    PORT           = 8765
    WS_MAX_SIZE    = 50 * 1024 * 1024   # 50 MB

    # ── Lưu trữ ───────────────────────────────────────────────────────────────
    DATA_DIR       = "./fpga_results"
    REPORT_DIR     = "./reports"

    # ── Model checkpoints ─────────────────────────────────────────────────────
    # Baseline (Float32)
    ENC_BASE_PTH   = "./models/best_enc.pth"
    DEC_BASE_PTH   = "./models/best_dec.pth"
    # QAT (Quantization-Aware Training)
    ENC_QAT_PTH    = "./models/best_enc_qat.pth"
    DEC_QAT_PTH    = "./models/best_dec_qat.pth"

    BASE_CHANNEL   = 16
    IMG_SIZE       = 128

    # ── Device ────────────────────────────────────────────────────────────────
    DEVICE         = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # ── Q6.10 ─────────────────────────────────────────────────────────────────
    Q_SCALE        = 1024.0

    # ── Benchmark: số lần warm-up + số lần đo tốc độ mỗi model ───────────────
    BENCH_WARMUP   = 3
    BENCH_RUNS     = 10

    # ── Report ────────────────────────────────────────────────────────────────
    SUMMARY_CSV    = os.path.join(REPORT_DIR, "eval_summary.csv")
    SPEED_CSV      = os.path.join(REPORT_DIR, "speed_benchmark.csv")
    SERVER_LOG     = os.path.join(REPORT_DIR, "server.log")


# ─────────────────────────────────────────────────────────────────────────────
# 2. LOGGING
# ─────────────────────────────────────────────────────────────────────────────
os.makedirs(ServerConfig.DATA_DIR,   exist_ok=True)
os.makedirs(ServerConfig.REPORT_DIR, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s  %(message)s",
    datefmt="%H:%M:%S",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(ServerConfig.SERVER_LOG, mode="a", encoding="utf-8"),
    ]
)
log = logging.getLogger("ws_server")


# ─────────────────────────────────────────────────────────────────────────────
# 3. MODEL ARCHITECTURE  (đồng bộ với qat_stegano_fix_4_4.py)
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
    def forward(self, x): return qat_quant(x)


# ── Baseline: SeparableConv2d (Float32) ──────────────────────────────────────
class SeparableConv2d(nn.Module):
    def __init__(self, in_c, out_c, kernel_size=3, stride=1, padding=1):
        super().__init__()
        self.depthwise = nn.Conv2d(in_c, in_c, kernel_size, stride, padding,
                                   groups=in_c, bias=False)
        self.pointwise = nn.Conv2d(in_c, out_c, kernel_size=1, bias=False)

    def forward(self, x):
        return self.pointwise(self.depthwise(x))


# ── QAT: QATSeparableConv2d ───────────────────────────────────────────────────
class QATSeparableConv2d(nn.Module):
    """Depthwise + Pointwise với FakeQuantize, 3 probe points và QuantIdentity.

    Tham số
    -------
    activation : 'relu' | None
        Hàm kích hoạt đặt BÊN TRONG lớp.
        - 'relu'  : dùng cho tất cả block thường (head, down*, up*, bottleneck)
        - None    : dùng cho tail block (activation = Tanh được áp ngoài)

    Luồng dữ liệu (khi activation='relu')
    ----------------------------------------
    x → DW_conv(quant_w) → qat_quant → [probe_dw]
      → PW_conv(quant_w / fused_w+b) → [probe_pw_pre]
      → BN (nếu chưa fuse; sau fuse BN đã hấp thụ vào PW)
      → ReLU → qat_quant → [probe_pw_post]

    Luồng dữ liệu (khi activation=None, tail)
    ------------------------------------------
    x → DW_conv(quant_w) → qat_quant → [probe_dw]
      → PW_conv(quant_w / fused_w+b) → [probe_pw_pre]
      → (không ReLU, không QuantIdentity) → [probe_pw_post alias pre]

    Lưu ý về fuse_model_qat
    -----------------------
    Khi bn_fused=True: PW conv đã hấp thụ BN (weight+bias),
    forward dùng trực tiếp không quantize lại.

    Probe points
    ------------
    probe_dw      – sau DW + qat_quant
    probe_pw_pre  – sau PW conv, TRƯỚC activation+quant
    probe_pw_post – sau activation + QuantIdentity (giá trị FPGA thực sự thấy)
    """

    def __init__(self, in_c, out_c, kernel_size=3, stride=1, padding=1,
                 activation=None):
        super().__init__()
        self.depthwise = nn.Conv2d(in_c, in_c, kernel_size, stride, padding,
                                   groups=in_c, bias=False)
        self.pointwise = nn.Conv2d(in_c, out_c, kernel_size=1, bias=False)
        self.bn_fused  = False   # set True bởi fuse_model_qat

        # Hàm kích hoạt
        self.activation = activation
        if activation == 'relu':
            self._act_fn = nn.ReLU(inplace=False)
        else:
            self._act_fn = None

        # QuantIdentity sau activation — đây là điểm fake-quant quan trọng
        # Chỉ có ý nghĩa khi activation != None
        self._quant_act = QuantIdentity()

        # 3 probe points — hook gắn vào đây để capture golden data
        self.probe_dw      = nn.Identity()   # sau DW
        self.probe_pw_pre  = nn.Identity()   # sau PW, trước activation
        self.probe_pw_post = nn.Identity()   # sau activation + quant

    def forward(self, x):
        # ── Depthwise ──────────────────────────────────────────────────────
        w_dw = qat_quant(self.depthwise.weight)
        x = F.conv2d(x, w_dw, None,
                     self.depthwise.stride, self.depthwise.padding,
                     self.depthwise.dilation, self.depthwise.groups)
        x = qat_quant(x)
        x = self.probe_dw(x)               # ← probe DW

        # ── Pointwise ──────────────────────────────────────────────────────
        if self.bn_fused:
            # BN đã hấp thụ vào weight+bias → dùng trực tiếp, không quant lại
            x = F.conv2d(x, self.pointwise.weight, self.pointwise.bias,
                         self.pointwise.stride, self.pointwise.padding)
        else:
            w_pw = qat_quant(self.pointwise.weight)
            x = F.conv2d(x, w_pw, None,
                         self.pointwise.stride, self.pointwise.padding)

        x = self.probe_pw_pre(x)           # ← probe PW (trước activation)

        # ── Activation + QuantIdentity ──────────────────────────────────────
        if self._act_fn is not None:
            x = self._act_fn(x)            # ReLU
            x = self._quant_act(x)         # fake-quant activation ← QUAN TRỌNG
            x = self.probe_pw_post(x)      # ← probe sau quant
        else:
            # tail: không activation, probe_pw_post = alias of probe_pw_pre
            x = self.probe_pw_post(x)

        return x


# ── Baseline Encoder (Float32 SeparableConv) ─────────────────────────────────
class Encoder(nn.Module):
    def __init__(self, base_c = 16):
        super().__init__()

        def conv_block(in_c, out_c, stride=1):
            return nn.Sequential(
                SeparableConv2d(in_c, out_c, stride=stride),
                nn.BatchNorm2d(out_c),
                nn.ReLU(True))

        def conv_block_no_relu(in_c, out_c, stride=1):
            return nn.Sequential(
                SeparableConv2d(in_c, out_c, stride=stride))


        self.head = conv_block(6, base_c) # 128x128x16
        self.down1 = conv_block(base_c, base_c*2, stride=2) # 64x64x32
        self.down2 = conv_block(base_c*2, base_c*4, stride=2) #  32x32x64
        self.down3 = conv_block(base_c*4, base_c*8, stride=2) #  16x16x128

        self.bottleneck = conv_block(base_c*8, base_c*8, stride=2) # 8x8x128
        self.upsample = nn.Upsample(scale_factor=2, mode='nearest')

        self.up1 = conv_block(base_c*8 + base_c*8, base_c*4)  # 16X16x
        self.up2 = conv_block(base_c*4 + base_c*4, base_c*2) # 32x32x
        self.up3 = conv_block(base_c*2 + base_c*2, base_c) # 64x64x
        self.up4 = conv_block(base_c + base_c, base_c) # 128x128xbase_c
        # self.tail = nn.Tanh()
        # self.up4 = nn.Conv2d(base_c + base_c, 3, )
        #self.tail = nn.Sequential(nn.Conv2d(base_c, 3, kernel_size=1, bias=False), nn.Tanh())
        self.tail = conv_block_no_relu(base_c, 3)


    def forward(self, x_cover, x_secret):
        x = torch.cat([x_cover, x_secret], dim=1)

        head = self.head(x)        # 128x128x8
        d1 = self.down1(head)      # 64x64x16
        d2 = self.down2(d1)      # 32x32x32
        d3 = self.down3(d2)      # 16x16x64
        b  = self.bottleneck(d3) # 4x4x128

        up0 = self.upsample(b)

        u1_sc_down4  = self.up1(torch.cat([up0, d3], dim=1))
        up1 = self.upsample(u1_sc_down4)

        up2_sc_down3 = self.up2(torch.cat([up1, d2], dim=1))
        up2 = self.upsample(up2_sc_down3)

        up3_sc_down2 = self.up3(torch.cat([up2, d1], dim=1))
        up3 = self.upsample(up3_sc_down2)

        u4_sc_head = self.up4(torch.cat([up3, head], dim=1))

        return torch.clamp(x_cover + self.tail(u4_sc_head), -1, 1)


# ── QAT Encoder ───────────────────────────────────────────────────────────────
class QATEncoder(nn.Module):
    """Encoder QAT tối ưu: 
    - Thứ tự chuẩn xác: Conv -> BN -> ReLU -> Quant
    - Giữ lại các điểm đo (Probe Points) cho FPGA
    - Có Tanh ở đầu ra giúp bảo vệ tín hiệu giấu tin
    """
    def __init__(self, base_c=16):
        super().__init__()

        # SỬA ĐỔI 1: Thiết lập lại thứ tự các lớp trong Block
        def qat_block(in_c, out_c, stride=1):
            return nn.Sequential(
                QATSeparableConv2d(in_c, out_c, stride=stride, activation=None),
                nn.BatchNorm2d(out_c),
                nn.ReLU(inplace=True),
                QuantIdentity()
            )

        def qat_block_no_act(in_c, out_c):
            """Tail block: Không activation, không BN"""
            return nn.Sequential(
                QATSeparableConv2d(in_c, out_c, activation=None)
            )

        # Khởi tạo các block (tên phải khớp với Baseline để copy weight)
        self.head       = qat_block(6,          base_c)
        self.down1      = qat_block(base_c,     base_c*2, stride=2)
        self.down2      = qat_block(base_c*2,   base_c*4, stride=2)
        self.down3      = qat_block(base_c*4,   base_c*8, stride=2)
        self.bottleneck = qat_block(base_c*8,   base_c*8, stride=2)
        self.upsample   = nn.Upsample(scale_factor=2, mode='nearest')
        self.up1        = qat_block(base_c*8*2, base_c*4)
        self.up2        = qat_block(base_c*4*2, base_c*2)
        self.up3        = qat_block(base_c*2*2, base_c)
        self.up4        = qat_block(base_c*2,   base_c)
        self.tail       = qat_block_no_act(base_c, 3)

    def forward(self, x_cover, x_secret):
        # Quantize input (mô phỏng pixel vào FPGA)
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

        # SỬA ĐỔI 2: Dùng module chuẩn để hỗ trợ Probe Points
        feat = self.tail[0](u4) 

        # SỬA ĐỔI 3: Giữ lại Tanh (Giống Bản 1) vì thực nghiệm cho kết quả giấu tin tốt hơn
        # out = qat_quant(torch.tanh(feat))
        out = qat_quant(feat)
        
        return torch.clamp(x_cover + out, -1, 1)


# ── Decoder (dùng chung cho cả Baseline và FPGA decode) ──────────────────────
class Decoder(nn.Module):
    def __init__(self, base_c=16): # Server có thể chạy base_c=32 hoặc 64 thoải mái
        super().__init__()

        # Khối conv_block sử dụng Tích chập đầy đủ (Full Convolution)
        def conv_block(in_c, out_c, stride=1):
            return nn.Sequential(
                nn.Conv2d(in_c, out_c, kernel_size=3, stride=stride, padding=1, bias=True),
                nn.BatchNorm2d(out_c),
                nn.LeakyReLU(0.1, inplace=True) # Dùng LeakyReLU tốt hơn cho việc khôi phục
            )

        # --- 1. DOWNSAMPLING PATH (Bóc tách đặc trưng từ ảnh Stego) ---
        self.head = conv_block(3, base_c)               # H x W
        self.down1 = conv_block(base_c, base_c*2, stride=2)    # H/2
        self.down2 = conv_block(base_c*2, base_c*4, stride=2)  # H/4
        self.down3 = conv_block(base_c*4, base_c*8, stride=2)  # H/8
        self.down4 = conv_block(base_c*8, base_c*16, stride=2) # H/16

        # Level 5: Bottleneck sâu nhất
        self.bottleneck = conv_block(base_c*16, base_c*16, stride=2) # H/32

        # --- 2. UPSAMPLING PATH (Tái tạo ảnh Secret) ---
        self.upsample = nn.Upsample(scale_factor=2, mode='bilinear', align_corners=True) # Bilinear mượt hơn Nearest

        # Up 1: H/32 -> H/16
        self.up1 = conv_block(base_c*16 + base_c*16, base_c*8)
        # Up 2: H/16 -> H/8
        self.up2 = conv_block(base_c*8 + base_c*8, base_c*4)
        # Up 3: H/8 -> H/4
        self.up3 = conv_block(base_c*4 + base_c*4, base_c*2)
        # Up 4: H/4 -> H/2
        self.up4 = conv_block(base_c*2 + base_c*2, base_c)
        # Up 5: H/2 -> H
        self.up5 = conv_block(base_c + base_c, base_c)

        # Output: Trả về ảnh Secret 3 kênh
        self.tail = nn.Sequential(
            nn.Conv2d(base_c, 3, kernel_size=3, padding=1),
            nn.Tanh() # Secret image thường được chuẩn hóa về [-1, 1]
        )

    def forward(self, x_stego):
        # --- Encoder Path (Down) ---
        c1 = self.head(x_stego)
        c2 = self.down1(c1)
        c3 = self.down2(c2)
        c4 = self.down3(c3)
        c5 = self.down4(c4)
        b  = self.bottleneck(c5)

        # --- Decoder Path (Up with Skip Connections) ---
        u1 = self.up1(torch.cat([self.upsample(b), c5], dim=1))
        u2 = self.up2(torch.cat([self.upsample(u1), c4], dim=1))
        u3 = self.up3(torch.cat([self.upsample(u2), c3], dim=1))
        u4 = self.up4(torch.cat([self.upsample(u3), c2], dim=1))
        u5 = self.up5(torch.cat([self.upsample(u4), c1], dim=1))

        return self.tail(u5)


# ─────────────────────────────────────────────────────────────────────────────
# 4. LOAD MODEL
# ─────────────────────────────────────────────────────────────────────────────
def load_model(model: nn.Module, path: str, name: str,
               device: torch.device) -> nn.Module:
    if not os.path.exists(path):
        log.warning(f"⚠️  {name} checkpoint không tìm thấy: {path} – dùng random weights.")
        return model.to(device).eval()
    raw = torch.load(path, map_location=device)
    if isinstance(raw, dict):
        for k in ("enc", "encoder", "dec", "decoder", "state_dict"):
            if k in raw:
                raw = raw[k]; break
    model.load_state_dict(raw, strict=True)
    model.to(device).eval()
    log.info(f"✅ Loaded {name} ← {path}")
    return model


# ─────────────────────────────────────────────────────────────────────────────
# 5. HELPERS: TRANSFORM + METRICS + BER
# ─────────────────────────────────────────────────────────────────────────────
_transform = transforms.Compose([
    transforms.Resize((ServerConfig.IMG_SIZE, ServerConfig.IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize([0.5]*3, [0.5]*3),
])


def pil_to_tensor(img: Image.Image, device: torch.device) -> torch.Tensor:
    return _transform(img.convert("RGB")).unsqueeze(0).to(device)


def bytes_to_tensor(png_bytes: bytes, device: torch.device) -> torch.Tensor:
    return pil_to_tensor(Image.open(io.BytesIO(png_bytes)), device)


def b64_to_tensor(b64_str: str, device: torch.device) -> torch.Tensor:
    return bytes_to_tensor(base64.b64decode(b64_str), device)


def tensor_to_pil(t: torch.Tensor) -> Image.Image:
    arr = ((t.squeeze(0).cpu().permute(1, 2, 0) + 1) / 2).clamp(0, 1)
    return Image.fromarray((arr.numpy() * 255).astype(np.uint8))


def save_tensor_png(t: torch.Tensor, path: str):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    tensor_to_pil(t).save(path)


# ── PSNR / SSIM ──────────────────────────────────────────────────────────────
if TORCHMETRICS_OK:
    _dev     = ServerConfig.DEVICE
    _psnr_fn = PeakSignalNoiseRatio(data_range=1.0).to(_dev)
    _ssim_fn = StructuralSimilarityIndexMeasure(data_range=1.0).to(_dev)

    def _psnr(a, b): return _psnr_fn(a, b).item()
    def _ssim(a, b): return _ssim_fn(a, b).item()
else:
    def _psnr(a, b):
        mse = torch.mean((a - b) ** 2).item()
        return float("inf") if mse == 0 else 10 * np.log10(1.0 / mse)

    def _ssim(a, b):
        af = a.flatten().float(); bf = b.flatten().float()
        return torch.corrcoef(torch.stack([af, bf]))[0, 1].item()


def calc_metrics(pred: torch.Tensor, ref: torch.Tensor) -> Dict[str, float]:
    """PSNR, SSIM, MAE, MSE, BER trên tensor ∈ [-1,1].
    BER dùng ngưỡng 0 (sign bit) – ý nghĩa: tỉ lệ pixel lệch dấu.
    Tất cả 12 nhóm đều có đủ 5 chỉ số.
    """
    p = ((pred + 1) / 2).clamp(0, 1)
    r = ((ref  + 1) / 2).clamp(0, 1)
    mse_val = torch.mean((p - r) ** 2).item()
    # BER: tỉ lệ bit (sign) khác nhau giữa pred và ref
    pred_bits = (pred > 0).flatten()
    ref_bits  = (ref  > 0).flatten()
    n = pred_bits.numel()
    ber_val = (pred_bits != ref_bits).sum().item() / n if n > 0 else 0.0
    return {
        "psnr": round(_psnr(p, r),                         4),
        "ssim": round(_ssim(p, r),                         4),
        "mae":  round(torch.mean(torch.abs(p - r)).item(), 6),
        "mse":  round(mse_val,                             6),
        "ber":  round(ber_val,                             6),
    }


def quality_tag(psnr: float, ssim: float) -> str:
    p = "GOOD(≥30dB)"  if psnr >= 30 else ("MED(20-30dB)" if psnr >= 20 else "POOR(<20dB)")
    s = "HIGH(≥0.9)"   if ssim >= 0.9 else ("MED(≥0.7)"   if ssim >= 0.7 else "LOW(<0.7)")
    return f"PSNR:{p}  SSIM:{s}"


# ─────────────────────────────────────────────────────────────────────────────
# 6. SPEED BENCHMARK
# ─────────────────────────────────────────────────────────────────────────────
def benchmark_model(model: nn.Module, inputs: tuple, label: str,
                    device: torch.device,
                    warmup: int = 3, runs: int = 10) -> Dict[str, float]:
    """
    Đo tốc độ inference của một model.
    - inputs: tuple các tensor đầu vào theo thứ tự forward()
    - Trả về dict: latency_ms (mean), latency_std_ms, fps
    """
    model.eval()
    # Warm-up
    with torch.no_grad():
        for _ in range(warmup):
            _ = model(*inputs)
    if device.type == "cuda":
        torch.cuda.synchronize()

    # Đo
    latencies = []
    with torch.no_grad():
        for _ in range(runs):
            t0 = time.perf_counter()
            _ = model(*inputs)
            if device.type == "cuda":
                torch.cuda.synchronize()
            latencies.append((time.perf_counter() - t0) * 1000)  # ms

    mean_ms = float(np.mean(latencies))
    std_ms  = float(np.std(latencies))
    fps     = 1000.0 / mean_ms if mean_ms > 0 else 0.0
    log.info(f"  ⏱  [{label}] latency={mean_ms:.2f}±{std_ms:.2f} ms  "
             f"fps={fps:.1f}")
    return {"label": label, "latency_mean_ms": round(mean_ms, 3),
            "latency_std_ms": round(std_ms, 3), "fps": round(fps, 2)}


# ─────────────────────────────────────────────────────────────────────────────
# 7. VISUALISATION
# ─────────────────────────────────────────────────────────────────────────────
def save_comparison_figure(imgs: Dict[str, torch.Tensor],
                            metrics: Dict,
                            path: str, title: str = ""):
    """
    Figure 3×4:
      Hàng 1: Cover | Secret | Stego Baseline  | Recover Baseline
      Hàng 2: Cover | Secret | Stego QAT       | Recover QAT
      Hàng 3: Cover | Secret | Stego FPGA      | Recover FPGA
    """
    def t2np(t):
        return ((t.squeeze(0).cpu().permute(1, 2, 0) + 1) / 2).clamp(0, 1).numpy()

    rows = [
        ("Baseline (Float32)",
         ["Cover", "Secret", "Stego Baseline", "Recover Baseline"],
         ["cover", "secret", "stego_baseline", "recover_baseline"]),
        ("QAT",
         ["Cover", "Secret", "Stego QAT", "Recover QAT"],
         ["cover", "secret", "stego_qat", "recover_qat"]),
        ("FPGA",
         ["Cover", "Secret", "Stego FPGA", "Recover FPGA"],
         ["cover", "secret", "stego_fpga", "recover_fpga"]),
    ]

    fig, axes = plt.subplots(3, 4, figsize=(18, 12))
    fig.suptitle(title, fontsize=13, fontweight="bold")

    psnr_map = {
        "stego_baseline":   metrics.get("F_stego_baseline_vs_cover",    {}).get("psnr"),
        "recover_baseline": metrics.get("G_recover_baseline_vs_secret",  {}).get("psnr"),
        "stego_qat":        metrics.get("H_stego_qat_vs_cover",          {}).get("psnr"),
        "recover_qat":      metrics.get("I_recover_qat_vs_secret",       {}).get("psnr"),
        "stego_fpga":       metrics.get("A_stego_fpga_vs_cover",         {}).get("psnr"),
        "recover_fpga":     metrics.get("D_recover_fpga_vs_secret",      {}).get("psnr"),
    }

    for row_idx, (row_title, labels, keys) in enumerate(rows):
        axes[row_idx, 0].set_ylabel(row_title, fontsize=9, fontweight="bold",
                                    rotation=90, labelpad=4)
        for col, (lbl, key) in enumerate(zip(labels, keys)):
            ax = axes[row_idx, col]
            if key in imgs:
                ax.imshow(t2np(imgs[key]))
            p = psnr_map.get(key)
            ax.set_title(f"{lbl}\n({p:.2f}dB)" if p is not None else lbl, fontsize=8)
            ax.axis("off")

    plt.tight_layout()
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    plt.savefig(path, dpi=120, bbox_inches="tight")
    plt.close(fig)


# ─────────────────────────────────────────────────────────────────────────────
# 8. PAYLOAD PARSER
# ─────────────────────────────────────────────────────────────────────────────
def parse_payload(data: bytes) -> tuple:
    if len(data) < 4:
        raise ValueError("Payload quá ngắn")
    json_len = struct.unpack(">I", data[:4])[0]
    if len(data) < 4 + json_len:
        raise ValueError(f"Thiếu JSON bytes: cần {json_len}, có {len(data)-4}")
    header   = json.loads(data[4 : 4 + json_len].decode("utf-8"))
    png_bytes = data[4 + json_len :]
    return header, png_bytes


# ─────────────────────────────────────────────────────────────────────────────
# 9. EVALUATOR
# ─────────────────────────────────────────────────────────────────────────────
class LaptopEvaluator:
    """
    Chạy cả Baseline (Float32) VÀ QAT Encoder+Decoder.
    Ghi lại tốc độ encoder / decoder của từng model.
    Tính 12 nhóm chỉ số so sánh.
    """

    def __init__(self, cfg: type = ServerConfig):
        self.cfg    = cfg
        self.device = cfg.DEVICE
        log.info(f"Device: {self.device}")

        # ── Load 4 model ─────────────────────────────────────────────────────
        self.enc_base = load_model(
            Encoder(cfg.BASE_CHANNEL),    cfg.ENC_BASE_PTH, "Baseline Encoder", self.device)
        self.dec_base = load_model(
            Decoder(cfg.BASE_CHANNEL),    cfg.DEC_BASE_PTH, "Baseline Decoder", self.device)
        self.enc_qat  = load_model(
            QATEncoder(cfg.BASE_CHANNEL), cfg.ENC_QAT_PTH,  "QAT Encoder",      self.device)
        self.dec_qat  = load_model(
            Decoder(cfg.BASE_CHANNEL),    cfg.DEC_QAT_PTH,  "QAT Decoder",      self.device)

        self._all_records: List[Dict] = []
        self._speed_records: List[Dict] = []

    # ── Đo tốc độ (gọi 1 lần trên ảnh đầu tiên) ─────────────────────────────
    def _run_speed_benchmark(self, cover_t: torch.Tensor,
                              secret_t: torch.Tensor) -> Dict[str, Dict]:
        log.info("  📏 Chạy speed benchmark...")
        dummy_stego = torch.zeros_like(cover_t)
        cfg = self.cfg
        results = {
            "baseline_enc": benchmark_model(self.enc_base, (cover_t, secret_t),
                                             "Baseline Encoder", self.device,
                                             cfg.BENCH_WARMUP, cfg.BENCH_RUNS),
            "baseline_dec": benchmark_model(self.dec_base, (dummy_stego,),
                                             "Baseline Decoder", self.device,
                                             cfg.BENCH_WARMUP, cfg.BENCH_RUNS),
            "qat_enc":      benchmark_model(self.enc_qat,  (cover_t, secret_t),
                                             "QAT Encoder",      self.device,
                                             cfg.BENCH_WARMUP, cfg.BENCH_RUNS),
            "qat_dec":      benchmark_model(self.dec_qat,  (dummy_stego,),
                                             "QAT Decoder",      self.device,
                                             cfg.BENCH_WARMUP, cfg.BENCH_RUNS),
        }
        # Ghi speed CSV
        speed_row = {"timestamp": datetime.now().isoformat()}
        for key, val in results.items():
            speed_row[f"{key}_latency_ms"]  = val["latency_mean_ms"]
            speed_row[f"{key}_std_ms"]      = val["latency_std_ms"]
            speed_row[f"{key}_fps"]         = val["fps"]
        self._speed_records.append(speed_row)
        write_csv(self.cfg.SPEED_CSV, self._speed_records)
        return results

    # ── Evaluate 1 sample ─────────────────────────────────────────────────────
    def evaluate(self, header: Dict, png_bytes: bytes) -> Dict:
        sid     = header["sample_id"]
        out_dir = os.path.join(self.cfg.DATA_DIR, sid)
        os.makedirs(out_dir, exist_ok=True)
        dev     = self.device

        # ── Lưu file từ board ────────────────────────────────────────────────
        stego_fpga_path = os.path.join(out_dir, "stego_fpga.png")
        with open(stego_fpga_path, "wb") as f:
            f.write(png_bytes)

        cover_path  = os.path.join(out_dir, "cover.png")
        secret_path = os.path.join(out_dir, "secret.png")
        with open(cover_path,  "wb") as f:
            f.write(base64.b64decode(header["cover_b64"]))
        with open(secret_path, "wb") as f:
            f.write(base64.b64decode(header["secret_b64"]))

        # ── Load tensors ─────────────────────────────────────────────────────
        cover_t  = pil_to_tensor(Image.open(cover_path),  dev)
        secret_t = pil_to_tensor(Image.open(secret_path), dev)
        fpga_t   = bytes_to_tensor(png_bytes, dev)

        # ── Speed benchmark (chỉ lần đầu) ────────────────────────────────────
        speed = None
        if not self._speed_records:
            speed = self._run_speed_benchmark(cover_t, secret_t)

        # ── Baseline Encoder + Decoder (đo latency từng lần) ─────────────────
        t0 = time.perf_counter()
        with torch.no_grad():
            stego_base_t = self.enc_base(cover_t, secret_t)
        lat_base_enc = time.perf_counter() - t0

        t0 = time.perf_counter()
        with torch.no_grad():
            recover_base_t = self.dec_base(stego_base_t)
        lat_base_dec = time.perf_counter() - t0

        save_tensor_png(stego_base_t,   os.path.join(out_dir, "stego_baseline.png"))
        save_tensor_png(recover_base_t, os.path.join(out_dir, "recover_baseline.png"))

        # ── QAT Encoder + Decoder ─────────────────────────────────────────────
        t0 = time.perf_counter()
        with torch.no_grad():
            stego_qat_t = self.enc_qat(cover_t, secret_t)
        lat_qat_enc = time.perf_counter() - t0

        t0 = time.perf_counter()
        with torch.no_grad():
            recover_qat_t = self.dec_qat(stego_qat_t)
        lat_qat_dec = time.perf_counter() - t0

        save_tensor_png(stego_qat_t,   os.path.join(out_dir, "stego_qat.png"))
        save_tensor_png(recover_qat_t, os.path.join(out_dir, "recover_qat.png"))

        # ── FPGA: decode bằng cả 2 decoder ───────────────────────────────────
        t0 = time.perf_counter()
        with torch.no_grad():
            recover_fpga_t = self.dec_qat(fpga_t)   # decoder chính (QAT)
        lat_fpga_dec = time.perf_counter() - t0

        save_tensor_png(recover_fpga_t, os.path.join(out_dir, "recover_fpga.png"))

        # ─────────────────────────────────────────────────────────────────────
        # 12 NHÓM METRICS
        # ─────────────────────────────────────────────────────────────────────
        # [A] stego_fpga   vs cover          (imperceptibility FPGA)
        mA = calc_metrics(fpga_t,          cover_t)
        # [B] stego_fpga   vs stego_baseline (FPGA vs Baseline encoder)
        mB = calc_metrics(fpga_t,          stego_base_t)
        # [C] stego_fpga   vs stego_qat      (FPGA vs QAT encoder)
        mC = calc_metrics(fpga_t,          stego_qat_t)
        # [D] recover_fpga vs secret         (decode quality FPGA)
        mD = calc_metrics(recover_fpga_t,  secret_t)
        # [E] recover_fpga vs recover_baseline (FPGA recover vs Baseline)
        mE = calc_metrics(recover_fpga_t,  recover_base_t)
        # [F] stego_baseline vs cover        (imperceptibility Baseline)
        mF = calc_metrics(stego_base_t,    cover_t)
        # [G] recover_baseline vs secret     (decode quality Baseline)
        mG = calc_metrics(recover_base_t,  secret_t)
        # [H] stego_qat vs cover             (imperceptibility QAT)
        mH = calc_metrics(stego_qat_t,     cover_t)
        # [I] recover_qat vs secret          (decode quality QAT)
        mI = calc_metrics(recover_qat_t,   secret_t)
        # [J] stego_baseline vs stego_qat    (Baseline encoder vs QAT encoder)
        mJ = calc_metrics(stego_base_t,    stego_qat_t)
        # [K] recover_baseline vs recover_qat (Baseline decoder vs QAT decoder)
        mK = calc_metrics(recover_base_t,  recover_qat_t)
        # [L] recover_fpga vs recover_qat    (FPGA recover vs QAT recover)
        mL = calc_metrics(recover_fpga_t,  recover_qat_t)

        # BER đã được tính trong calc_metrics cho tất cả 12 nhóm

        # ── Latency tổng hợp ─────────────────────────────────────────────────
        latencies = {
            "baseline_enc_latency_s": round(lat_base_enc, 6),
            "baseline_dec_latency_s": round(lat_base_dec, 6),
            "qat_enc_latency_s":      round(lat_qat_enc,  6),
            "qat_dec_latency_s":      round(lat_qat_dec,  6),
            "fpga_dec_latency_s":     round(lat_fpga_dec, 6),
        }

        metrics = {
            "sample_id": sid,
            **latencies,
            # FPGA groups
            "A_stego_fpga_vs_cover":           mA,
            "B_stego_fpga_vs_stego_baseline":  mB,
            "C_stego_fpga_vs_stego_qat":       mC,
            "D_recover_fpga_vs_secret":        mD,
            "E_recover_fpga_vs_recover_base":  mE,
            "L_recover_fpga_vs_recover_qat":   mL,
            # SW Baseline groups
            "F_stego_baseline_vs_cover":       mF,
            "G_recover_baseline_vs_secret":    mG,
            # SW QAT groups
            "H_stego_qat_vs_cover":            mH,
            "I_recover_qat_vs_secret":         mI,
            # Baseline vs QAT
            "J_stego_baseline_vs_stego_qat":   mJ,
            "K_recover_baseline_vs_recover_qat": mK,
        }

        # ── Ghi JSON + TXT ────────────────────────────────────────────────────
        with open(os.path.join(out_dir, "metrics.json"), "w", encoding="utf-8") as f:
            json.dump(metrics, f, indent=2, ensure_ascii=False)

        _write_metrics_txt(os.path.join(out_dir, "metrics.txt"),
                           sid, metrics, latencies, header)

        # ── Figure so sánh ────────────────────────────────────────────────────
        save_comparison_figure(
            {"cover": cover_t, "secret": secret_t,
             "stego_baseline":   stego_base_t,   "recover_baseline": recover_base_t,
             "stego_qat":        stego_qat_t,     "recover_qat":      recover_qat_t,
             "stego_fpga":       fpga_t,          "recover_fpga":     recover_fpga_t},
            metrics,
            os.path.join(out_dir, "comparison.png"),
            title=f"Baseline vs QAT vs FPGA – {sid}",
        )

        log.info(
            f"[{sid}] "
            f"[A]{mA['psnr']:.2f}  [B]{mB['psnr']:.2f}  [C]{mC['psnr']:.2f}  "
            f"[D]{mD['psnr']:.2f}  [F]{mF['psnr']:.2f}  [H]{mH['psnr']:.2f}  "
            f"[J]{mJ['psnr']:.2f} dB"
        )

        self._append_record(header, metrics)

        return {
            "A_psnr": mA["psnr"], "A_ssim": mA["ssim"], "A_mae": mA["mae"], "A_mse": mA["mse"], "A_ber": mA["ber"],
            "B_psnr": mB["psnr"], "B_ssim": mB["ssim"], "B_mae": mB["mae"], "B_mse": mB["mse"], "B_ber": mB["ber"],
            "C_psnr": mC["psnr"], "C_ssim": mC["ssim"], "C_mae": mC["mae"], "C_mse": mC["mse"], "C_ber": mC["ber"],
            "D_psnr": mD["psnr"], "D_ssim": mD["ssim"], "D_mae": mD["mae"], "D_mse": mD["mse"], "D_ber": mD["ber"],
            "E_psnr": mE["psnr"], "E_ssim": mE["ssim"], "E_mae": mE["mae"], "E_mse": mE["mse"], "E_ber": mE["ber"],
            "F_psnr": mF["psnr"], "F_ssim": mF["ssim"], "F_mae": mF["mae"], "F_mse": mF["mse"], "F_ber": mF["ber"],
            "G_psnr": mG["psnr"], "G_ssim": mG["ssim"], "G_mae": mG["mae"], "G_mse": mG["mse"], "G_ber": mG["ber"],
            "H_psnr": mH["psnr"], "H_ssim": mH["ssim"], "H_mae": mH["mae"], "H_mse": mH["mse"], "H_ber": mH["ber"],
            "I_psnr": mI["psnr"], "I_ssim": mI["ssim"], "I_mae": mI["mae"], "I_mse": mI["mse"], "I_ber": mI["ber"],
            "J_psnr": mJ["psnr"], "J_ssim": mJ["ssim"], "J_mae": mJ["mae"], "J_mse": mJ["mse"], "J_ber": mJ["ber"],
            "K_psnr": mK["psnr"], "K_ssim": mK["ssim"], "K_mae": mK["mae"], "K_mse": mK["mse"], "K_ber": mK["ber"],
            "L_psnr": mL["psnr"], "L_ssim": mL["ssim"], "L_mae": mL["mae"], "L_mse": mL["mse"], "L_ber": mL["ber"],
            **latencies,
        }

    def _append_record(self, header: Dict, metrics: Dict):
        sid = metrics["sample_id"]
        row = {
            "sample_id":         sid,
            "timestamp":         header.get("timestamp", ""),
            "hw_latency_s":      header.get("hw_latency_s", ""),
            "e2e_latency_s":     header.get("e2e_latency_s", ""),
            "fps":               header.get("fps", ""),
            "power_avg_W":       header.get("power_avg_W", ""),
            "energy_J":          header.get("energy_J", ""),
        }
        # Latency SW
        for k in ("baseline_enc_latency_s", "baseline_dec_latency_s",
                  "qat_enc_latency_s", "qat_dec_latency_s", "fpga_dec_latency_s"):
            row[k] = metrics.get(k, "")

        # Metrics mỗi nhóm
        group_keys = [
            "A_stego_fpga_vs_cover", "B_stego_fpga_vs_stego_baseline",
            "C_stego_fpga_vs_stego_qat", "D_recover_fpga_vs_secret",
            "E_recover_fpga_vs_recover_base", "L_recover_fpga_vs_recover_qat",
            "F_stego_baseline_vs_cover", "G_recover_baseline_vs_secret",
            "H_stego_qat_vs_cover", "I_recover_qat_vs_secret",
            "J_stego_baseline_vs_stego_qat", "K_recover_baseline_vs_recover_qat",
        ]
        for gk in group_keys:
            g     = metrics.get(gk, {})
            short = gk.split("_")[0]   # A, B, C ...
            for metric, val in g.items():
                row[f"{short}_{metric}"] = val

        self._all_records.append(row)
        write_csv(self.cfg.SUMMARY_CSV, self._all_records)
        log.info(f"  📊 Summary CSV cập nhật ({len(self._all_records)} records)")

        # Ghi / cập nhật report.txt tổng hợp 4 trụ cột sau mỗi sample
        report_path = os.path.join(self.cfg.REPORT_DIR, "report.txt")
        _write_final_report_txt(report_path, self._all_records, self._speed_records)
        log.info(f"  📄 report.txt cập nhật → {report_path}")


# ─────────────────────────────────────────────────────────────────────────────
# 10. CSV + TXT HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def write_csv(path: str, records: List[Dict]):
    if not records: return
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(records[0].keys()),
                           extrasaction="ignore")
        w.writeheader()
        w.writerows(records)


def _fmt_val(v, decimals=4) -> str:
    """Định dạng giá trị số hoặc N/A."""
    if v is None or v == "" or v == "N/A":
        return "N/A"
    try:
        return f"{float(v):.{decimals}f}"
    except (TypeError, ValueError):
        return str(v)




def _write_metrics_txt(path: str, sid: str, metrics: Dict,
                        latencies: Dict, header: Dict):
    """Ghi report per-sample theo 4 trụ cột, đầy đủ PSNR/SSIM/MAE/MSE/BER."""
    SEP  = "═" * 80
    SEP2 = "─" * 80
    HDR  = f"  {'Nhóm':<46}  {'PSNR(dB)':>9}  {'SSIM':>7}  {'MAE':>10}  {'MSE':>10}  {'BER':>10}\n"
    DIV  = f"  {'-'*46}  {'-'*9}  {'-'*7}  {'-'*10}  {'-'*10}  {'-'*10}\n"

    def row(label, m):
        return (
            f"  {label:<46}  "
            f"{_fmt_val(m.get('psnr'),4):>9}  "
            f"{_fmt_val(m.get('ssim'),4):>7}  "
            f"{_fmt_val(m.get('mae'),6):>10}  "
            f"{_fmt_val(m.get('mse'),6):>10}  "
            f"{_fmt_val(m.get('ber'),6):>10}\n"
        )

    hw_lat   = header.get("hw_latency_s",  "N/A")
    e2e_lat  = header.get("e2e_latency_s", "N/A")
    fps_fpga = header.get("fps",           "N/A")
    pwr_avg  = header.get("power_avg_W",   "N/A")
    pwr_min  = header.get("power_min_W",   "N/A")
    pwr_max  = header.get("power_max_W",   "N/A")
    energy   = header.get("energy_J",      "N/A")

    lat_base_enc = latencies.get("baseline_enc_latency_s", "N/A")
    lat_base_dec = latencies.get("baseline_dec_latency_s", "N/A")
    lat_qat_enc  = latencies.get("qat_enc_latency_s",      "N/A")
    lat_qat_dec  = latencies.get("qat_dec_latency_s",      "N/A")
    lat_fpga_dec = latencies.get("fpga_dec_latency_s",     "N/A")

    with open(path, "w", encoding="utf-8") as f:
        f.write(f"{SEP}\n  REPORT – {sid}\n")
        f.write(f"  {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n{SEP}\n\n")

        # ── Trụ cột 1: Imperceptibility ──────────────────────────────────────
        f.write(f"{SEP2}\n  TRU COT 1 – TINH TANG HINH (IMPERCEPTIBILITY)\n")
        f.write(f"  Stego Image vs Cover Image\n{SEP2}\n")
        f.write(HDR); f.write(DIV)
        f.write(row("[A] stego_fpga     vs cover          (FPGA)",
                    metrics["A_stego_fpga_vs_cover"]))
        f.write(row("[F] stego_baseline vs cover          (Baseline Float32)",
                    metrics["F_stego_baseline_vs_cover"]))
        f.write(row("[H] stego_qat      vs cover          (QAT)",
                    metrics["H_stego_qat_vs_cover"]))
        f.write("\n")

        # ── Trụ cột 2: Recovery Quality ───────────────────────────────────────
        f.write(f"{SEP2}\n  TRU COT 2 – KHA NANG KHOI PHUC (RECOVERY QUALITY)\n")
        f.write(f"  Recovered Image vs Secret Image\n{SEP2}\n")
        f.write(HDR); f.write(DIV)
        f.write(row("[D] recover_fpga    vs secret         (FPGA)",
                    metrics["D_recover_fpga_vs_secret"]))
        f.write(row("[G] recover_baseline vs secret        (Baseline Float32)",
                    metrics["G_recover_baseline_vs_secret"]))
        f.write(row("[I] recover_qat     vs secret         (QAT)",
                    metrics["I_recover_qat_vs_secret"]))
        f.write("\n")

        # ── Trụ cột 3: Fidelity ───────────────────────────────────────────────
        f.write(f"{SEP2}\n  TRU COT 3 – SU TRUNG THUC (FIDELITY)\n")
        f.write(f"  Quantization Error (Q6.10) & Hardware Implementation Error\n{SEP2}\n")
        f.write("  -- Encoder Fidelity --\n")
        f.write(HDR); f.write(DIV)
        f.write(row("[B] stego_fpga     vs stego_baseline  (FPGA vs Baseline)",
                    metrics["B_stego_fpga_vs_stego_baseline"]))
        f.write(row("[C] stego_fpga     vs stego_qat       (FPGA vs QAT)",
                    metrics["C_stego_fpga_vs_stego_qat"]))
        f.write(row("[J] stego_baseline vs stego_qat       (Baseline vs QAT)",
                    metrics["J_stego_baseline_vs_stego_qat"]))
        f.write("\n  -- Decoder Fidelity --\n")
        f.write(HDR); f.write(DIV)
        f.write(row("[E] recover_fpga   vs recover_baseline (FPGA vs Baseline)",
                    metrics["E_recover_fpga_vs_recover_base"]))
        f.write(row("[L] recover_fpga   vs recover_qat      (FPGA vs QAT)",
                    metrics["L_recover_fpga_vs_recover_qat"]))
        f.write(row("[K] recover_baseline vs recover_qat    (Baseline vs QAT)",
                    metrics["K_recover_baseline_vs_recover_qat"]))
        f.write("\n")

        # ── Trụ cột 4: Hardware Performance ───────────────────────────────────
        f.write(f"{SEP2}\n  TRU COT 4 – HIEU NANG PHAN CUNG (HARDWARE PERFORMANCE)\n{SEP2}\n")
        f.write(f"  -- FPGA IP Core (KV260) --\n")
        f.write(f"    HW Latency (pure IP)   : {_fmt_val(hw_lat,6)} s\n")
        f.write(f"    End-to-End Latency     : {_fmt_val(e2e_lat,6)} s\n")
        f.write(f"    Throughput             : {_fmt_val(fps_fpga,2)} FPS\n")
        f.write(f"    Power Avg/Min/Max      : {_fmt_val(pwr_avg,4)} W  /  "
                f"{_fmt_val(pwr_min,4)} W  /  {_fmt_val(pwr_max,4)} W\n")
        f.write(f"    Energy per image       : {_fmt_val(energy,6)} J\n")
        f.write(f"\n  -- CPU Laptop (SW inference, 1 image) --\n")
        for label, val in [
            ("Baseline Encoder", lat_base_enc),
            ("Baseline Decoder", lat_base_dec),
            ("QAT Encoder",      lat_qat_enc),
            ("QAT Decoder",      lat_qat_dec),
            ("FPGA Decoder(SW)", lat_fpga_dec),
        ]:
            f.write(f"    {label:<22} : {_fmt_val(val,6)} s  ({_fps_str(val)} FPS)\n")
        f.write(f"\n{SEP}\n")


def _fps_str(lat_s) -> str:
    """Chuyển latency (giây) sang FPS string."""
    try:
        v = float(lat_s)
        return f"{1.0/v:.2f}" if v > 0 else "N/A"
    except (TypeError, ValueError):
        return "N/A"


def _write_final_report_txt(path: str, records: List[Dict], speed_records: List[Dict]):
    """
    Ghi report.txt tổng hợp theo 4 trụ cột.
    Mỗi nhóm A–L hiển thị đủ PSNR / SSIM / MAE / MSE / BER.
    Cập nhật sau mỗi sample mới nhận được.
    """
    if not records:
        return

    # Lọc sample lỗi (PSNR = inf / nan)
    def _is_valid(rec):
        for k, v in rec.items():
            if "psnr" in k:
                try:
                    fv = float(v)
                    if not (fv == fv) or fv in (float("inf"), float("-inf")):
                        return False
                except (TypeError, ValueError):
                    pass
        return True

    valid     = [r for r in records if _is_valid(r)]
    n_total   = len(records)
    n_valid   = len(valid)
    n_skipped = n_total - n_valid
    if not valid:
        return

    def avg(col):
        vals = []
        for r in valid:
            try:
                v = float(r.get(col, ""))
                if v == v and v not in (float("inf"), float("-inf")):
                    vals.append(v)
            except (TypeError, ValueError):
                pass
        return sum(vals) / len(vals) if vals else None

    def fmt(v, d=4):
        return _fmt_val(v, d)

    SEP  = "═" * 100
    SEP2 = "─" * 100
    spd  = speed_records[0] if speed_records else {}

    # Header dòng chỉ số 5 cột
    def tbl_header():
        return (
            f"  {'Nhóm / Model':<48}  "
            f"{'PSNR(dB)':>9}  {'SSIM':>7}  {'MAE':>10}  {'MSE':>10}  {'BER':>10}\n"
            f"  {'-'*48}  {'-'*9}  {'-'*7}  {'-'*10}  {'-'*10}  {'-'*10}\n"
        )

    def tbl_row(label, grp_prefix):
        return (
            f"  {label:<48}  "
            f"{fmt(avg(grp_prefix+'_psnr')):>9}  "
            f"{fmt(avg(grp_prefix+'_ssim')):>7}  "
            f"{fmt(avg(grp_prefix+'_mae'),6):>10}  "
            f"{fmt(avg(grp_prefix+'_mse'),6):>10}  "
            f"{fmt(avg(grp_prefix+'_ber'),6):>10}\n"
        )

    with open(path, "w", encoding="utf-8") as f:
        f.write(f"{SEP}\n")
        f.write(f"  FINAL REPORT – FPGA STEGANOGRAPHY EVALUATION\n")
        f.write(f"  Thoi gian tao : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"  Tong sample   : {n_total}  |  Hop le : {n_valid}  |  Loai bo : {n_skipped}\n")
        f.write(f"{SEP}\n\n")

        # ══════════════════════════════════════════════════════════════════════
        # Trụ cột 1 – IMPERCEPTIBILITY
        # ══════════════════════════════════════════════════════════════════════
        f.write(f"{SEP2}\n")
        f.write(f"  TRU COT 1 – TINH TANG HINH (IMPERCEPTIBILITY)\n")
        f.write(f"  Stego Image vs Cover Image  |  Nhom A (FPGA) · F (Baseline) · H (QAT)\n")
        f.write(f"{SEP2}\n")
        f.write(tbl_header())
        f.write(tbl_row("[A] stego_fpga     vs cover   (FPGA)",      "A"))
        f.write(tbl_row("[F] stego_baseline vs cover   (Baseline)",  "F"))
        f.write(tbl_row("[H] stego_qat      vs cover   (QAT)",       "H"))
        f.write("\n")

        # ══════════════════════════════════════════════════════════════════════
        # Trụ cột 2 – RECOVERY QUALITY
        # ══════════════════════════════════════════════════════════════════════
        f.write(f"{SEP2}\n")
        f.write(f"  TRU COT 2 – KHA NANG KHOI PHUC (RECOVERY QUALITY)\n")
        f.write(f"  Recovered Image vs Secret Image  |  Nhom D (FPGA) · G (Baseline) · I (QAT)\n")
        f.write(f"{SEP2}\n")
        f.write(tbl_header())
        f.write(tbl_row("[D] recover_fpga    vs secret   (FPGA)",     "D"))
        f.write(tbl_row("[G] recover_baseline vs secret  (Baseline)", "G"))
        f.write(tbl_row("[I] recover_qat     vs secret   (QAT)",      "I"))
        f.write("\n")

        # ══════════════════════════════════════════════════════════════════════
        # Trụ cột 3 – FIDELITY
        # ══════════════════════════════════════════════════════════════════════
        f.write(f"{SEP2}\n")
        f.write(f"  TRU COT 3 – SU TRUNG THUC (FIDELITY)\n")
        f.write(f"  Quantization Error (Q6.10) & Hardware Implementation Error\n")
        f.write(f"{SEP2}\n")
        f.write("  -- Encoder Fidelity --\n")
        f.write(tbl_header())
        f.write(tbl_row("[B] stego_fpga     vs stego_baseline  (FPGA vs Baseline)", "B"))
        f.write(tbl_row("[C] stego_fpga     vs stego_qat       (FPGA vs QAT)",      "C"))
        f.write(tbl_row("[J] stego_baseline vs stego_qat       (Baseline vs QAT)",  "J"))
        f.write("\n  -- Decoder Fidelity --\n")
        f.write(tbl_header())
        f.write(tbl_row("[E] recover_fpga   vs recover_baseline (FPGA vs Baseline)", "E"))
        f.write(tbl_row("[L] recover_fpga   vs recover_qat      (FPGA vs QAT)",      "L"))
        f.write(tbl_row("[K] recover_baseline vs recover_qat    (Baseline vs QAT)",  "K"))
        f.write("\n")

        # ══════════════════════════════════════════════════════════════════════
        # Trụ cột 4 – HARDWARE PERFORMANCE
        # ══════════════════════════════════════════════════════════════════════
        f.write(f"{SEP2}\n")
        f.write(f"  TRU COT 4 – HIEU NANG PHAN CUNG (HARDWARE PERFORMANCE)\n")
        f.write(f"{SEP2}\n")

        hw_fps  = (1.0 / avg("hw_latency_s"))  if avg("hw_latency_s")  and avg("hw_latency_s")  > 0 else None
        sys_fps = (1.0 / avg("e2e_latency_s")) if avg("e2e_latency_s") and avg("e2e_latency_s") > 0 else None

        f.write(f"  -- FPGA IP Core (KV260) – trung binh tren {n_valid} sample hop le --\n")
        f.write(
            f"  {'Metric':<25}  {'HW Lat(s)':>12}  {'E2E Lat(s)':>12}  "
            f"{'HW FPS':>10}  {'Sys FPS':>10}  {'Power(W)':>10}  {'Energy(J)':>10}\n"
            f"  {'-'*99}\n"
        )
        f.write(
            f"  {'TRUNG BINH':<25}  "
            f"{fmt(avg('hw_latency_s'),6):>12}  "
            f"{fmt(avg('e2e_latency_s'),6):>12}  "
            f"{fmt(hw_fps,2):>10}  "
            f"{fmt(sys_fps,2):>10}  "
            f"{fmt(avg('power_avg_W'),4):>10}  "
            f"{fmt(avg('energy_J'),6):>10}\n"
        )

        f.write(f"\n  -- CPU Laptop (SW inference) – trung binh tren {n_valid} sample hop le --\n")
        sw_models = [
            ("Baseline Encoder", "baseline_enc", "baseline_enc_latency_s"),
            ("Baseline Decoder", "baseline_dec", "baseline_dec_latency_s"),
            ("QAT Encoder",      "qat_enc",      "qat_enc_latency_s"),
            ("QAT Decoder",      "qat_dec",      "qat_dec_latency_s"),
            ("FPGA Decoder(SW)", "fpga_dec",     "fpga_dec_latency_s"),
        ]
        f.write(
            f"  {'Model':<22}  {'Bench Lat(ms)':>14}  {'Bench Std(ms)':>14}  "
            f"{'Bench FPS':>10}  {'Avg Lat/img(s)':>16}  {'Avg FPS':>10}\n"
            f"  {'-'*99}\n"
        )
        for label, bkey, lat_col in sw_models:
            lat_ms = spd.get(f"{bkey}_latency_ms", "N/A")
            std_ms = spd.get(f"{bkey}_std_ms",     "N/A")
            fps_b  = spd.get(f"{bkey}_fps",        "N/A")
            avg_l  = avg(lat_col)
            avg_f  = (1.0 / avg_l) if avg_l and avg_l > 0 else None
            f.write(
                f"  {label:<22}  "
                f"{fmt(lat_ms,3):>14}  {fmt(std_ms,3):>14}  "
                f"{fmt(fps_b,2):>10}  "
                f"{fmt(avg_l,6):>16}  {fmt(avg_f,2):>10}\n"
            )

        f.write(f"\n{SEP}\n")

# ─────────────────────────────────────────────────────────────────────────────
# 11. WEBSOCKET HANDLER
# ─────────────────────────────────────────────────────────────────────────────
async def handle_client(websocket, evaluator: LaptopEvaluator):
    peer = websocket.remote_address
    log.info(f"🔌 Kết nối mới từ {peer}")
    try:
        data = await asyncio.wait_for(websocket.recv(), timeout=120)
        if not isinstance(data, bytes):
            raise ValueError("Nhận được text frame, mong đợi binary")

        log.info(f"  📦 Nhận {len(data)/1024:.1f} KB từ {peer}")

        header, png_bytes = parse_payload(data)
        sid = header.get("sample_id", "unknown")
        log.info(f"  ▶ Bắt đầu đánh giá sample: {sid}")

        loop         = asyncio.get_running_loop()
        eval_summary = await loop.run_in_executor(
            None, evaluator.evaluate, header, png_bytes)

        ack = {
            "status":    "ok",
            "sample_id": sid,
            "timestamp": datetime.now().isoformat(),
            "eval":      eval_summary,
        }
        await websocket.send(json.dumps(ack, ensure_ascii=False))
        log.info(f"  ✅ ACK gửi cho {peer} – sample {sid}")

    except asyncio.TimeoutError:
        log.error(f"  ⏰ Timeout nhận dữ liệu từ {peer}")
        try:
            await websocket.send(json.dumps({"status": "error", "msg": "receive timeout"}))
        except Exception: pass
    except Exception as e:
        log.error(f"  ❌ Lỗi xử lý {peer}: {e}", exc_info=True)
        try:
            await websocket.send(json.dumps({"status": "error", "msg": str(e)}))
        except Exception: pass
    finally:
        log.info(f"🔌 Đóng kết nối {peer}")


# ─────────────────────────────────────────────────────────────────────────────
# 12. MAIN SERVER
# ─────────────────────────────────────────────────────────────────────────────
async def main_server(cfg: type):
    evaluator = LaptopEvaluator(cfg)

    async def handler(ws):
        await handle_client(ws, evaluator)

    log.info("═" * 60)
    log.info(f"  🚀 WebSocket Server khởi động")
    log.info(f"     Địa chỉ    : ws://{cfg.HOST}:{cfg.PORT}")
    log.info(f"     Lưu dữ liệu: {cfg.DATA_DIR}")
    log.info(f"     Report     : {cfg.REPORT_DIR}")
    log.info(f"     Device     : {cfg.DEVICE}")
    log.info(f"     Baseline   : enc={cfg.ENC_BASE_PTH}  dec={cfg.DEC_BASE_PTH}")
    log.info(f"     QAT        : enc={cfg.ENC_QAT_PTH}   dec={cfg.DEC_QAT_PTH}")
    log.info("═" * 60)

    async with ws_serve(
        handler, cfg.HOST, cfg.PORT,
        max_size=cfg.WS_MAX_SIZE,
        ping_interval=20, ping_timeout=60,
    ):
        log.info("⏳ Đang chờ kết nối từ board KV260 ...")
        await asyncio.Future()


# ─────────────────────────────────────────────────────────────────────────────
# 13. ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="WebSocket Server – FPGA Steganography Evaluation (Baseline + QAT)")
    parser.add_argument("--host",      default=ServerConfig.HOST,         help="Bind host")
    parser.add_argument("--port",      default=ServerConfig.PORT, type=int, help="Bind port")
    parser.add_argument("--data",      default=ServerConfig.DATA_DIR,     help="Thư mục lưu sample")
    parser.add_argument("--report",    default=ServerConfig.REPORT_DIR,   help="Thư mục report")
    parser.add_argument("--enc-base",  default=ServerConfig.ENC_BASE_PTH, help="Baseline Encoder .pth")
    parser.add_argument("--dec-base",  default=ServerConfig.DEC_BASE_PTH, help="Baseline Decoder .pth")
    parser.add_argument("--enc-qat",   default=ServerConfig.ENC_QAT_PTH,  help="QAT Encoder .pth")
    parser.add_argument("--dec-qat",   default=ServerConfig.DEC_QAT_PTH,  help="QAT Decoder .pth")
    parser.add_argument("--warmup",    default=ServerConfig.BENCH_WARMUP, type=int,
                        help="Số lần warm-up benchmark")
    parser.add_argument("--bench-runs",default=ServerConfig.BENCH_RUNS,   type=int,
                        help="Số lần đo benchmark")
    args = parser.parse_args()

    ServerConfig.HOST          = args.host
    ServerConfig.PORT          = args.port
    ServerConfig.DATA_DIR      = args.data
    ServerConfig.REPORT_DIR    = args.report
    ServerConfig.ENC_BASE_PTH  = args.enc_base
    ServerConfig.DEC_BASE_PTH  = args.dec_base
    ServerConfig.ENC_QAT_PTH   = args.enc_qat
    ServerConfig.DEC_QAT_PTH   = args.dec_qat
    ServerConfig.BENCH_WARMUP  = args.warmup
    ServerConfig.BENCH_RUNS    = args.bench_runs
    ServerConfig.SUMMARY_CSV   = os.path.join(args.report, "eval_summary.csv")
    ServerConfig.SERVER_LOG    = os.path.join(args.report, "server.log")

    os.makedirs(ServerConfig.DATA_DIR,   exist_ok=True)
    os.makedirs(ServerConfig.REPORT_DIR, exist_ok=True)

    try:
        asyncio.run(main_server(ServerConfig))
    except KeyboardInterrupt:
        log.info("\n Server dừng theo yêu cầu người dùng.")