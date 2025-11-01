#!/usr/bin/env bash
set -euo pipefail

# ------------ helpers ------------
have() { command -v "$1" >/dev/null 2>&1; }
die()  { echo "ERROR: $*" >&2; exit 1; }
msg()  { echo -e "\033[1;32m$*\033[0m"; }

# ------------ defaults ------------
BIN="${BIN:-./sqrt_compare}"
REPS="${REPS:-3}"
CSV="${CSV:-perf_results.csv}"
ELEMENTS="${ELEMENTS:-1000000,10000000}"   # comma-separated Ns
TASKS="${TASKS:-1,2,4,8}"                  # comma-separated tasks for program

# CLI overrides: --reps N --csv file.csv --elements "1e6,1e7" --tasks "1,2,4,8" --bin ./sqrt_compare
while [[ $# -gt 0 ]]; do
  case "$1" in
    --reps)     REPS="$2"; shift 2 ;;
    --csv)      CSV="$2"; shift 2 ;;
    --elements) ELEMENTS="$2"; shift 2 ;;
    --tasks)    TASKS="$2"; shift 2 ;;
    --bin)      BIN="$2"; shift 2 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -x "$BIN" ]] || die "Binary '$BIN' not found. Build first."

# ------------ run ------------
msg "Running sweeps"
msg "  REPS      = ${REPS}"
msg "  ELEMENTS  = ${ELEMENTS}"
msg "  TASKS     = ${TASKS}"
msg "  OUT CSV   = ${CSV}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

# CSV header
echo "n,tasks,avg_serial_s,avg_simd_s,avg_task_time_s,simd_speedup,task_speedup_vs_serial,task_speedup_vs_simd" > "${CSV}"

IFS=',' read -r -a NLIST <<< "${ELEMENTS}"

for N in "${NLIST[@]}"; do
  # accumulators per task across repetitions
  # we’ll store lines emitted by the program that start with 'CSV '
  lines_file="${tmpdir}/lines_${N}.txt"
  : > "${lines_file}"

  for r in $(seq 1 "${REPS}"); do
    msg "  N=${N}  run ${r}/${REPS}"
    # The program will iterate over the requested tasks internally and emit CSV lines.
    "${BIN}" --n "${N}" --tasks "${TASKS}" | tee "${tmpdir}/run_${N}_${r}.log" >/dev/null

    # Extract only the machine-readable lines
    grep -E '^CSV ' "${tmpdir}/run_${N}_${r}.log" >> "${lines_file}"
  done

  # Now average per (N, tasks)
  # Lines look like:
  # CSV n=10000000,tasks=4,serial=0.20,simd=0.045,task_time=0.013
  awk -v Nval="${N}" '
    BEGIN { FS="[ =,]"; OFS=","; }
    /^CSV / {
      # fields: CSV n <N> tasks <T> serial <S> simd <I> task_time <TT>
      # indexes: 1  2  3  4     5   6     7     8    9         10
      n=$3; t=$5; s=$7; i=$9; tt=$11;
      key = t;
      cnt[key] += 1;
      sumS[key] += s;
      sumI[key] += i;
      sumTT[key] += tt;
    }
    END {
      for (k in cnt) {
        avgS  = sumS[k]/cnt[k];
        avgI  = sumI[k]/cnt[k];
        avgTT = sumTT[k]/cnt[k];
        # speedups
        sp_simd  = avgS / avgI;
        sp_tasks_vs_serial = avgS / avgTT;
        sp_tasks_vs_simd   = avgI / avgTT;
        print Nval, k, avgS, avgI, avgTT, sp_simd, sp_tasks_vs_serial, sp_tasks_vs_simd;
      }
    }
  ' "${lines_file}" | sort -n -t, -k2,2 >> "${CSV}"
done

msg "Wrote ${CSV}"
