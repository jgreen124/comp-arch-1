#!/usr/bin/env bash
# run_mem_experiments.sh

set -euo pipefail

PROG="mem_bench"

echo "Compiling ${PROG}.c ..."
gcc -O3 -march=native -std=c11 "${PROG}.c" -o "${PROG}"

echo "Running cache-sweep experiment (this may take a little while)..."
./"${PROG}" cache_sweep > cache_sweep.csv

# Large streaming test: approximate DRAM bandwidth, minimal reuse
DRAM_MB=512 # May need to adjust
echo "Running streaming DRAM bandwidth experiment (${DRAM_MB} MB, readwrite)..."
./"${PROG}" stream "${DRAM_MB}" readwrite > stream_dram_${DRAM_MB}mb.csv

# Smaller streaming test for L2/L3/cache bandwidth
CACHE_MB=4
echo "Running streaming cache-sized bandwidth experiment (${CACHE_MB} MB, readwrite)..."
./"${PROG}" stream "${CACHE_MB}" readwrite > stream_cache_${CACHE_MB}mb.csv

echo
echo "Done."
echo "Generated files:"
echo "  cache_sweep.csv              (cache size / reuse sweep)"
echo "  stream_dram_${DRAM_MB}mb.csv (streaming DRAM bandwidth, minimal reuse)"
echo "  stream_cache_${CACHE_MB}mb.csv (streaming cache-sized bandwidth)"
echo
echo "Next steps:"
echo "  1) Plot cache_sweep.csv: time_seconds or bandwidth_GBps vs size_bytes."
echo "     Look for sharp drops in bandwidth / increases in time to estimate L1, L2, L3 sizes."
echo "  2) Compare stream_dram_* vs stream_cache_* to discuss DRAM vs cache bandwidth."
