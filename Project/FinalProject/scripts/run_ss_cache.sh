#!/usr/bin/env bash
# Do NOT use -e here; we want to continue even if one benchmark fails
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../env.sh"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <benchmark_name> <benchmark_cmd...>" >&2
  echo "Example: $0 test-fmath \"${TRACE_DIR}/test-fmath\"" >&2
  exit 1
fi

BENCH_NAME="$1"
shift
# Treat the remaining arguments as an array (program + its args)
BENCH_CMD=( "$@" )

# Use cache configs from env.sh / config/ss_cache.sh
IL1="${SS_IL1_CONFIG}"
DL1="${SS_DL1_CONFIG}"
UL2="${SS_UL2_CONFIG}"

OUT_TXT="${SS_RESULTS}/${BENCH_NAME}_baseline.txt"
OUT_CSV="${SS_RESULTS}/ss_baseline.csv"

mkdir -p "${SS_RESULTS}"

echo "Running sim-cache for benchmark: ${BENCH_NAME}"
echo "Command: ${BENCH_CMD[*]}"
echo "IL1=${IL1}, DL1=${DL1}, UL2=${UL2}"
echo "Output file: ${OUT_TXT}"

# Run sim-cache; do NOT let non-zero exit kill the script
"${SS_ROOT}/sim-cache" \
  -redir:sim "${OUT_TXT}" \
  -cache:il1 "${IL1}" \
  -cache:dl1 "${DL1}" \
  -cache:il2 "${UL2}" \
  -cache:dl2 "${UL2}" \
  "${BENCH_CMD[@]}"
STATUS=$?

if [[ ${STATUS} -ne 0 ]]; then
  echo "WARNING: sim-cache exited with status ${STATUS} for benchmark ${BENCH_NAME}" >&2
fi

echo "Simulation complete. Parsing metrics (if available)..."

# Allow greps to fail without killing the script
IL1_MISS_RATE=$(grep -m1 "il1.miss_rate" "${OUT_TXT}" 2>/dev/null | awk '{print $2}' || true)
DL1_MISS_RATE=$(grep -m1 "dl1.miss_rate" "${OUT_TXT}" 2>/dev/null | awk '{print $2}' || true)
UL2_MISS_RATE=$(grep -m1 "ul2.miss_rate" "${OUT_TXT}" 2>/dev/null | awk '{print $2}' || true)

SIM_NUM_INSN=$(grep -m1 "sim_num_insn" "${OUT_TXT}" 2>/dev/null | awk '{print $2}' || true)
SIM_ELAPSED_TIME=$(grep -m1 "sim_elapsed_time" "${OUT_TXT}" 2>/dev/null | awk '{print $2}' || true)
SIM_CPI=$(grep -m1 "sim_CPI" "${OUT_TXT}" 2>/dev/null | awk '{print $2}' || true)

# Initialize CSV with header if it doesn't exist yet
if [[ ! -f "${OUT_CSV}" ]]; then
  echo "benchmark,il1_miss_rate,dl1_miss_rate,ul2_miss_rate,sim_num_insn,sim_elapsed_time,sim_CPI" \
    > "${OUT_CSV}"
fi

echo "${BENCH_NAME},${IL1_MISS_RATE},${DL1_MISS_RATE},${UL2_MISS_RATE},${SIM_NUM_INSN},${SIM_ELAPSED_TIME},${SIM_CPI}" \
  >> "${OUT_CSV}"

echo "Metrics appended to ${OUT_CSV}"

