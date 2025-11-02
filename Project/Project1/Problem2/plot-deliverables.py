#!/usr/bin/env python3
import sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def normalize(df: pd.DataFrame) -> pd.DataFrame:
    # Normalize column names we expect
    required = {"mode","threads","N","time_s","speedup_vs_serial"}
    missing = required - set(df.columns)
    if missing:
        raise SystemExit(f"CSV missing columns: {missing}")
    # Normalize values
    df = df.copy()
    df["mode"] = df["mode"].astype(str).str.strip().str.lower()
    # Convert threads to int (nullable), then fill with 1 if missing
    df["threads"] = pd.to_numeric(df["threads"], errors="coerce").astype("Int64")
    df["threads"] = df["threads"].fillna(1).astype(int)
    # Ensure numeric
    for c in ["N","time_s","speedup_vs_serial"]:
        df[c] = pd.to_numeric(df[c], errors="coerce")
    # Drop rows with missing essential numeric cells
    df = df.dropna(subset=["threads","time_s"])
    return df

def median_by_mode_threads(df: pd.DataFrame) -> pd.DataFrame:
    g = (
        df.groupby(["mode","threads"], as_index=False)
          .agg(time_s=("time_s","median"), N=("N","max"))
          .sort_values(["mode","threads"])
    )
    return g

def pick_baseline(g: pd.DataFrame, mode_name: str, want_threads: int = 1):
    rows = g[g["mode"] == mode_name]
    if rows.empty:
        return None
    exact = rows[rows["threads"] == want_threads]
    if not exact.empty:
        return exact.iloc[0]
    # fallback to smallest threads available
    smallest = rows.sort_values("threads").iloc[0]
    return smallest

def infer_serial_if_missing(df_norm: pd.DataFrame):
    # Try to infer from speedup_vs_serial ≈ 1
    approx_serial = df_norm.loc[(df_norm["speedup_vs_serial"] - 1.0).abs() < 1e-6]
    if approx_serial.empty:
        return None
    # Use median time of those rows
    return float(approx_serial["time_s"].median())

def get_series(g: pd.DataFrame, mode_name: str):
    s = g[g["mode"] == mode_name].sort_values("threads")
    return s["threads"].to_numpy(), s["time_s"].to_numpy()

def plot_bar(label, value, title, outfile):
    plt.figure()
    plt.bar([label], [value])
    plt.ylabel("Speedup")
    plt.title(title)
    plt.text(0, value, f"{value:.2f}x", ha="center", va="bottom")
    plt.tight_layout()
    plt.savefig(outfile, dpi=140)
    plt.close()

def plot_line(x, y, *, xlabel, ylabel, title, labels=None, outfile=None):
    plt.figure()
    if isinstance(y, list):
        for i, yi in enumerate(y):
            lbl = labels[i] if labels else None
            plt.plot(x[i], yi, marker="o", label=lbl)
    else:
        plt.plot(x, y, marker="o")
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.title(title)
    if labels:
        plt.legend()
    # nice integer ticks on thread axis
    if xlabel.lower().startswith("thread"):
        xs = np.unique(np.concatenate([np.asarray(xx) for xx in x])) if isinstance(x, list) else x
        plt.xticks(xs.astype(int))
    plt.tight_layout()
    if outfile:
        plt.savefig(outfile, dpi=140)
        plt.close()

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "perf_results.csv"
    df_raw = pd.read_csv(path)
    df = normalize(df_raw)
    g = median_by_mode_threads(df)

    # Baselines (median-based, with robust fallback)
    base_serial = pick_baseline(g, "serial", want_threads=1)
    if base_serial is None:
        # Try infer from rows with speedup_vs_serial≈1
        T_serial = infer_serial_if_missing(df)
        if T_serial is None:
            # As a last resort, pick the smallest-time row as "serial"
            T_serial = float(df["time_s"].min())
        serial_row = pd.Series({"mode":"serial","threads":1,"time_s":T_serial})
    else:
        serial_row = base_serial
        T_serial = float(serial_row["time_s"])

    base_ispc1 = pick_baseline(g, "ispc_simd", want_threads=1)
    if base_ispc1 is None:
        raise SystemExit("No ISPC single-core row found (mode='ispc_simd').")
    T_ispc1 = float(base_ispc1["time_s"])

    base_avx1 = pick_baseline(g, "avx_intrin", want_threads=1)
    T_avx1 = float(base_avx1["time_s"]) if base_avx1 is not None else None

    # D1a
    sp_ispc1 = T_serial / T_ispc1
    plot_bar("ISPC(1) vs Serial", sp_ispc1,
             "Deliverable 1A: ISPC single-core speedup vs Serial",
             "D1a_ispc_singlecore_speedup.png")

    # D1b: ISPC multicore vs Serial
    x_i, t_i = get_series(g, "ispc_threads")
    if len(x_i) > 0:
        sp_vs_serial = T_serial / t_i
        plot_line(x_i, sp_vs_serial,
                  xlabel="Threads",
                  ylabel="Speedup vs Serial",
                  title="Deliverable 1B: ISPC multicore speedup vs Serial",
                  outfile="D1b_ispc_multicore_speedup_vs_serial.png")

    # D2: SIMD speedup bars
    labels = ["ISPC(1)"]
    vals   = [T_serial / T_ispc1]
    if T_avx1 is not None:
        labels.append("AVX(1)")
        vals.append(T_serial / T_avx1)
    plt.figure()
    plt.bar(labels, vals)
    for i, v in enumerate(vals):
        plt.text(i, v, f"{v:.2f}x", ha="center", va="bottom")
    plt.ylabel("Speedup vs Serial")
    plt.title("Deliverable 2: SIMD speedup")
    plt.tight_layout()
    plt.savefig("D2_simd_speedup.png", dpi=140)
    plt.close()

    # D3: Multicore speedup over single-core SIMD
    xs, ys, names = [], [], []
    if len(x_i) > 0:
        sp_over_ispc1 = T_ispc1 / t_i
        xs.append(x_i); ys.append(sp_over_ispc1); names.append("ISPC threads")
    x_a, t_a = get_series(g, "avx_threads")
    if len(x_a) > 0 and T_avx1 is not None:
        sp_over_avx1 = T_avx1 / t_a
        xs.append(x_a); ys.append(sp_over_avx1); names.append("AVX threads")
    if xs:
        plot_line(xs, ys,
                  xlabel="Threads",
                  ylabel="Speedup over single-core SIMD",
                  title="Deliverable 3: Multicore speedup over SIMD(1)",
                  labels=names,
                  outfile="D3_multicore_speedup_over_ispc1.png")

    # D4: Speedup vs threads (Serial baseline)
    xs, ys, names = [], [], []
    if len(x_i) > 0:
        sp_ispc_vs_serial = T_serial / t_i
        xs.append(x_i); ys.append(sp_ispc_vs_serial); names.append("ISPC threads")
    if len(x_a) > 0:
        sp_avx_vs_serial = T_serial / t_a
        xs.append(x_a); ys.append(sp_avx_vs_serial); names.append("AVX threads")
    if xs:
        plot_line(xs, ys,
                  xlabel="Threads",
                  ylabel="Speedup vs Serial",
                  title="Deliverable 4: Speedup vs Threads (Serial baseline)",
                  labels=names,
                  outfile="D4_speedup_vs_threads_vs_serial.png")

    print("Baselines used:")
    print(f"  Serial:     time_s={T_serial:.6f}")
    print(f"  ISPC(1):    time_s={T_ispc1:.6f}")
    if T_avx1 is not None:
        print(f"  AVX(1):     time_s={T_avx1:.6f}")
    print("Wrote figures:")
    print("  D1a_ispc_singlecore_speedup.png")
    print("  D1b_ispc_multicore_speedup_vs_serial.png")
    print("  D2_simd_speedup.png")
    print("  D3_multicore_speedup_over_ispc1.png")
    print("  D4_speedup_vs_threads_vs_serial.png")

if __name__ == "__main__":
    main()
