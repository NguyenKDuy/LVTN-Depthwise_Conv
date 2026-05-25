# -*- coding: utf-8 -*-
"""
run_benchmarks.py – Chạy benchmark cho cả CPU và CUDA
================================================================
Script wrapper để chạy benchmark_cuda.py trên 4 cấu hình:
  1. CUDA + Full Pipeline (Encoder + Decoder)
  2. CUDA + Encoder Only
  3. CPU  + Full Pipeline
  4. CPU  + Encoder Only

Mỗi benchmark sẽ sinh ra:
  - <name>_results.json           (latency + quality + hw stats dạng JSON)
  - <name>_results_report.txt     (báo cáo đầy đủ dạng văn bản)

Cách chạy:
  python run_benchmarks.py --image-dir /path/to/5k/images
  python run_benchmarks.py --image-dir /path/to/5k/images --quick-test
  python run_benchmarks.py --image-dir /path/to/5k/images --limit 500 \\
                           --monitor-interval 30 --batch-size 4
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path


# ─────────────────────────────────────────────────────────────────────────────
def run_benchmark(
    image_dir: str,
    cpu: bool = False,
    encoder_only: bool = False,
    limit: int = None,
    batch_size: int = 1,
    monitor_interval: float = 50.0,
    gpu_index: int = 0,
    output_dir: str = ".",
) -> bool:
    """Gọi benchmark_cuda.py như subprocess với các tham số cho sẵn."""

    mode     = "cpu"          if cpu          else "cuda"
    pipeline = "encoder_only" if encoder_only else "full_pipeline"
    tag      = f"{mode}_{pipeline}"

    output_json = os.path.join(output_dir, f"benchmark_{tag}_results.json")

    cmd = [
        sys.executable, "benchmark_cuda.py",
        "--image-dir", image_dir,
        "--output",    output_json,
        "--batch-size", str(batch_size),
        "--monitor-interval", str(monitor_interval),
        "--gpu-index", str(gpu_index),
    ]
    if cpu:
        cmd.append("--cpu")
    if encoder_only:
        cmd.append("--encoder-only")
    if limit:
        cmd.extend(["--limit", str(limit)])

    print(f"\n{'='*80}")
    print(f"▶  Benchmark: {mode.upper()} + {pipeline.replace('_', ' ').upper()}")
    print(f"   Command: {' '.join(cmd)}")
    print(f"{'='*80}")

    try:
        result = subprocess.run(
            cmd,
            capture_output=False,   # in trực tiếp ra terminal
            text=True,
            cwd=os.getcwd(),
        )
        ok = result.returncode == 0
        if ok:
            print(f"✅ Done: {tag}")
            report = output_json.replace(".json", "_report.txt")
            print(f"   JSON   → {output_json}")
            print(f"   Report → {report}")
        else:
            print(f"❌ FAILED: {tag}  (exit code {result.returncode})")
        return ok

    except FileNotFoundError:
        print("❌ benchmark_cuda.py not found in current directory.")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


# ─────────────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Run benchmark_cuda.py on all CPU/CUDA × full/encoder-only combos"
    )
    parser.add_argument("--image-dir", required=True,
                        help="Root folder chứa sample_00001/, sample_00002/, ...")
    parser.add_argument("--limit", type=int, default=None,
                        help="Giới hạn số ảnh mỗi benchmark (mặc định: tất cả)")
    parser.add_argument("--batch-size", type=int, default=1,
                        help="Batch size inference (mặc định 1)")
    parser.add_argument("--monitor-interval", type=float, default=50.0,
                        help="HW monitor polling interval ms (mặc định 50)")
    parser.add_argument("--gpu-index", type=int, default=0,
                        help="NVIDIA GPU index (mặc định 0)")
    parser.add_argument("--output-dir", default=".",
                        help="Thư mục lưu kết quả (mặc định: cwd)")
    parser.add_argument("--quick-test", action="store_true",
                        help="Chạy nhanh với 10 ảnh để kiểm tra")
    parser.add_argument("--skip-cpu", action="store_true",
                        help="Bỏ qua CPU benchmarks (chỉ chạy CUDA)")
    parser.add_argument("--encoder-only", action="store_true",
                        help="Chỉ chạy encoder-only benchmarks")

    args = parser.parse_args()

    # Validation
    if not os.path.exists(args.image_dir):
        print(f"❌ Image directory not found: {args.image_dir}")
        sys.exit(1)

    os.makedirs(args.output_dir, exist_ok=True)

    limit = 10 if args.quick_test else args.limit

    print("=" * 80)
    print("🚀 BENCHMARK SUITE")
    print("=" * 80)
    print(f"  Image dir:        {args.image_dir}")
    print(f"  Output dir:       {os.path.abspath(args.output_dir)}")
    print(f"  Sample limit:     {limit if limit else 'ALL'}")
    print(f"  Batch size:       {args.batch_size}")
    print(f"  Monitor interval: {args.monitor_interval} ms")
    print(f"  GPU index:        {args.gpu_index}")
    print(f"  Skip CPU:         {'YES' if args.skip_cpu else 'NO'}")
    print(f"  Encoder only:     {'YES' if args.encoder_only else 'NO'}")
    print("=" * 80)

    # Build list of benchmarks to run
    # Format: (label, cpu, encoder_only)
    all_benchmarks = [
        ("CUDA + Full Pipeline",    False, False),
        ("CUDA + Encoder Only",     False, True),
        ("CPU  + Full Pipeline",    True,  False),
        ("CPU  + Encoder Only",     True,  True),
    ]

    # Apply filters
    benchmarks = []
    for label, cpu, enc_only in all_benchmarks:
        if args.skip_cpu and cpu:
            continue
        if args.encoder_only and not enc_only:
            continue
        benchmarks.append((label, cpu, enc_only))

    if not benchmarks:
        print("⚠️  No benchmarks to run after applying filters.")
        sys.exit(0)

    print(f"\nWill run {len(benchmarks)} benchmark(s):\n")
    for i, (label, _, _) in enumerate(benchmarks, 1):
        print(f"  [{i}] {label}")
    print()

    # Run
    passed = []
    failed = []

    for label, cpu, enc_only in benchmarks:
        ok = run_benchmark(
            image_dir=args.image_dir,
            cpu=cpu,
            encoder_only=enc_only,
            limit=limit,
            batch_size=args.batch_size,
            monitor_interval=args.monitor_interval,
            gpu_index=args.gpu_index,
            output_dir=args.output_dir,
        )
        (passed if ok else failed).append(label)

    # Final summary
    print(f"\n{'='*80}")
    print("📊 BENCHMARK SUITE SUMMARY")
    print(f"{'='*80}")

    for label in passed:
        print(f"  ✅ {label}")
    for label in failed:
        print(f"  ❌ {label}")

    print(f"\n  Passed: {len(passed)}/{len(benchmarks)}")

    if not failed:
        print("\n🎉 All benchmarks completed successfully!")
        print(f"\nOutput files in: {os.path.abspath(args.output_dir)}/")
        for label, cpu, enc_only in benchmarks:
            mode = "cpu" if cpu else "cuda"
            pipe = "encoder_only" if enc_only else "full_pipeline"
            tag  = f"{mode}_{pipe}"
            print(f"  benchmark_{tag}_results.json")
            print(f"  benchmark_{tag}_results_report.txt")
    else:
        print("\n⚠️  Some benchmarks failed.")

    print(f"{'='*80}")
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())