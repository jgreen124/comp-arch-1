#!/usr/bin/env python3
# Read perf_results.csv to produce PNG plots

import sys
import math
import pandas as pd
import matplotlib.pyplot as plt

path = sys.argv[1] if len(sys.argv) > 1 else "perf_results.csv"

df = pd.read_csv(path)

# Basic sanity
required = {"mode","threads","N","time_s","speedup_vs_serial"}
missing = required - set(df.columns)
if missing:
    raise SystemExit(f"CSV missing columns: {missing}")

# Grab single-core baselines
serial = df.query("mode=='serial' & threads==1").sort_values("time_s").iloc[0]
ispc1  = df.query("mode=='ispc_simd' & threads==1").sort_values("time_s").iloc[0]
avx1   = df.query("mode=='avx_intrin' & threads==1").sort_values("time_s").iloc[0] if (df["mode"]=="avx_intrin").any() else None

threads_ispc = df[df["mode"]=="ispc_threads"].sort_values("threads")
threads_avx  = df[df["mode"]=="avx_threads"].sort_values("threads")

# Derived metrics
threads_ispc = threads_ispc.copy()
threads_ispc["speedup_vs_ispc1"] = ispc1["time_s"] / threads_ispc["time_s"]
threads_ispc["efficiency"] = threads_ispc["speedup_vs_ispc1"] / threads_ispc["threads"]

if not threads_avx.empty and avx1 is not None:
    threads_avx = threads_avx.copy()
    threads_avx["speedup_vs_avx1"] = avx1["time_s"] / threads_avx["time_s"]
    threads_avx["efficiency"] = threads_avx["speedup_vs_avx1"] / threads_avx["threads"]

# 1) Speedup vs Threads
plt.figure()
plt.plot(threads_ispc["threads"], serial["time_s"]/threads_ispc["time_s"], marker="o", label="ISPC: vs Serial")
plt.plot(threads_ispc["threads"], ispc1["time_s"]/threads_ispc["time_s"], marker="s", label="ISPC: vs ISPC(1)")
if not threads_avx.empty and avx1 is not None:
    plt.plot(threads_avx["threads"], serial["time_s"]/threads_avx["time_s"], marker="^", label="AVX: vs Serial")
    plt.plot(threads_avx["threads"], avx1["time_s"]/threads_avx["time_s"], marker="v", label="AVX: vs AVX(1)")
plt.xlabel("Threads"); plt.ylabel("Speedup"); plt.title("Speedup vs Threads")
plt.legend(); plt.tight_layout()
plt.savefig("speedup_vs_threads.png", dpi=120); plt.close()

# 2) Time vs Threads
plt.figure()
plt.plot(threads_ispc["threads"], threads_ispc["time_s"], marker="o", label="ISPC")
if not threads_avx.empty:
    plt.plot(threads_avx["threads"], threads_avx["time_s"], marker="^", label="AVX")
plt.xlabel("Threads"); plt.ylabel("Time (s)"); plt.title("Runtime vs Threads")
plt.legend(); plt.tight_layout()
plt.savefig("time_vs_threads.png", dpi=120); plt.close()

# 3) Efficiency vs Threads
plt.figure()
plt.plot(threads_ispc["threads"], threads_ispc["efficiency"], marker="o", label="ISPC efficiency")
if not threads_avx.empty and "efficiency" in threads_avx:
    plt.plot(threads_avx["threads"], threads_avx["efficiency"], marker="^", label="AVX efficiency")
plt.xlabel("Threads"); plt.ylabel("Efficiency (speedup / threads)"); plt.title("Parallel Efficiency")
plt.axhline(1.0, color="k", linewidth=1)
plt.legend(); plt.tight_layout()
plt.savefig("efficiency_vs_threads.png", dpi=120); plt.close()

# 4) Print summary
print("=== Summary ===")
print(f"Serial time: {serial['time_s']:.6f}s")
print(f"ISPC(1) time: {ispc1['time_s']:.6f}s  | SIMD speedup vs serial: {serial['time_s']/ispc1['time_s']:.2f}x")
if avx1 is not None:
    print(f"AVX(1)  time: {avx1['time_s']:.6f}s  | AVX speedup vs serial: {serial['time_s']/avx1['time_s']:.2f}x")
print("Wrote: speedup_vs_threads.png, time_vs_threads.png, efficiency_vs_threads.png")
