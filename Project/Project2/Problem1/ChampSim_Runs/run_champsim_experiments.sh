#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# SCRIPT LOCATION & PATHS
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CHAMPSIM_ROOT="${SCRIPT_DIR}/../../ChampSim/ChampSim"
TRACE_DIR="${CHAMPSIM_ROOT}/../Traces"
BIN_DIR="${CHAMPSIM_ROOT}/bin"

OUT_CSV="${SCRIPT_DIR}/champsim_results.csv"
RESULTS_DIR="${SCRIPT_DIR}/results_txt"
mkdir -p "${RESULTS_DIR}"

# Temporary config file that is modified for 4-core and 1-core builds
TMP_CONFIG="${CHAMPSIM_ROOT}/champsim_tmp.json"

###############################################################################
# EXPERIMENT SETTINGS
###############################################################################

WARMUP_INS=1000000
SIM_INS=10000000

# Workloads: (trace_filename, label)
/bin/true
WORKLOADS=(
  "600.perlbench_s-210B.champsimtrace.xz,compute"
  "429.mcf-184B.champsimtrace.xz,mem_bound"
)

###############################################################################
# CSV HEADER
###############################################################################

if [[ ! -f "${OUT_CSV}" ]]; then
  echo "cores,trace,workload_label,warmup,sim,ipc" > "${OUT_CSV}"
fi

###############################################################################
# Function: Build ChampSim for N cores
###############################################################################
build_champsim() {
  local CORES="$1"

  echo "======================================================================" >&2
  echo "BUILDING CHAMPSIM FOR ${CORES} CORES" >&2
  echo "======================================================================" >&2

  # Copy base config into temporary working config
  cp "${CHAMPSIM_ROOT}/champsim_config.json" "${TMP_CONFIG}"

  # Modify the JSON to set the new core count
  sed -i "s/\"num_cores\":.*/\"num_cores\": ${CORES},/" "${TMP_CONFIG}"

  # Run config.sh and make
  cd "${CHAMPSIM_ROOT}"
  ./config.sh "$(basename "${TMP_CONFIG}")"
  make -j"$(nproc)"
  cd "${SCRIPT_DIR}"

  echo "Done building ChampSim with ${CORES} cores." >&2
}

###############################################################################
# Function: Run one simulation
###############################################################################
run_one() {
  local CORES="$1"
  local trace_file="$2"
  local workload_label="$3"

  local bin_path="${BIN_DIR}/champsim"
  local full_trace="${TRACE_DIR}/${trace_file}"

  [[ -f "${bin_path}" ]] || { echo "ERROR: ChampSim binary missing!"; exit 1; }
  [[ -f "${full_trace}" ]] || { echo "ERROR: Missing trace: ${full_trace}"; exit 1; }

  local trace_tag="${trace_file%.xz}"
  trace_tag="${trace_tag%.champsimtrace}"

  local run_tag="champsim_${CORES}core_${trace_tag}"
  local out_txt="${RESULTS_DIR}/${run_tag}.txt"

  echo "======================================================================" >&2
  echo "Running: ${run_tag}" >&2
  echo "  Cores    : ${CORES}" >&2
  echo "  Trace    : ${full_trace}" >&2
  echo "  Workload : ${workload_label}" >&2
  echo "======================================================================" >&2

  # Build trace argument list: one trace per core (can reuse same file)
  local trace_args=()
  for ((c=0; c<CORES; c++)); do
    trace_args+=("${full_trace}")
  done

  # Run ChampSim
  "${bin_path}" \
    --warmup-instructions "${WARMUP_INS}" \
    --simulation-instructions "${SIM_INS}" \
    "${trace_args[@]}" | tee "${out_txt}"

  # Extract IPC
  local ipc
  ipc="$(grep -o 'cumulative IPC: [0-9.]\+' "${out_txt}" | tail -n1 | awk '{print $3}')"
  ipc="${ipc:-NA}"

  echo "${CORES},${trace_file},${workload_label},${WARMUP_INS},${SIM_INS},${ipc}" \
    >> "${OUT_CSV}"

  echo " → Finished run: ${run_tag}  (IPC=${ipc})" >&2
}


###############################################################################
# MAIN EXECUTION
###############################################################################

echo "==============================================================" >&2
echo "    ChampSim Full Experiment Automation Script" >&2
echo "==============================================================" >&2

#############################
# 1-CORE EXPERIMENTS
#############################
build_champsim 1

for w in "${WORKLOADS[@]}"; do
  IFS=',' read -r trace_file wl_label <<< "$w"
  run_one 1 "${trace_file}" "${wl_label}"
done

#############################
# 4-CORE EXPERIMENTS
#############################
build_champsim 4

for w in "${WORKLOADS[@]}"; do
  IFS=',' read -r trace_file wl_label <<< "$w"
  run_one 4 "${trace_file}" "${wl_label}"
done

echo "==============================================================" >&2
echo "All experiments completed." >&2
echo "CSV summary at: ${OUT_CSV}" >&2
echo "Logs at: ${RESULTS_DIR}" >&2
echo "==============================================================" >&2
