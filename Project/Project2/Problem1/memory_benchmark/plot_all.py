import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# ============================
# Helper: load CSV safely
# ============================
def load_csv(path):
    return pd.read_csv(path)

# ============================
# 1. Cache Sweep Plot
# ============================
def plot_cache_sweep(df):
    # Convert to MB for nicer x-axis scale
    df["size_MB"] = df["size_bytes"] / (1024 * 1024)

    plt.figure(figsize=(10,6))
    plt.plot(df["size_MB"], df["bandwidth_GBps"], marker='o', linestyle='-')

    plt.xscale("log", base=2)
    plt.xlabel("Working Set Size (MB, log scale)")
    plt.ylabel("Effective Bandwidth (GB/s)")
    plt.title("Cache Sweep — Effective Bandwidth vs Working Set Size")
    plt.grid(True, which="both", ls="--", alpha=0.6)

    plt.tight_layout()
    plt.savefig("cache_sweep.png", dpi=200)
    print("[OK] Saved cache_sweep.png")

# ============================
# 2. Streaming BW Plot
# ============================
def plot_stream(df, outfile, title):
    size_MB = df["size_bytes"].iloc[0] / (1024 * 1024)

    plt.figure(figsize=(8,5))
    plt.bar([f"{size_MB:.0f} MB"], [df["bandwidth_GBps"].iloc[0]])

    plt.ylabel("Bandwidth (GB/s)")
    plt.title(title)
    plt.grid(axis='y', linestyle='--', alpha=0.6)

    plt.tight_layout()
    plt.savefig(outfile, dpi=200)
    print(f"[OK] Saved {outfile}")

# ============================
# MAIN
# ============================
if __name__ == "__main__":
    # -------- Load data --------
    cache_df = load_csv("cache_sweep.csv")
    dram_df  = load_csv("stream_dram_512mb.csv")
    l2_df    = load_csv("stream_cache_4mb.csv")

    # -------- Create plots --------
    plot_cache_sweep(cache_df)
    plot_stream(dram_df, "stream_dram_512mb.png",
                "Streaming DRAM Bandwidth (512 MB Array)")
    plot_stream(l2_df, "stream_cache_4mb.png",
                "Streaming Cache-Sized Bandwidth (4 MB Array)")
