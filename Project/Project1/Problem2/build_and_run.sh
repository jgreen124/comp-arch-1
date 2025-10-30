#!/usr/bin/env bash
set -euo pipefail

# Clean
rm -f sqrt_compare sqrt_test *.o square_root_ispc.h square_root_ispc_tasks.h

# Detect AVX2 support (fallback to SSE4 if needed)
if lscpu | grep -qw avx2; then
  TGT="avx2-i32x8"
else
  echo "Warning: AVX2 not found; building for sse4.2"
  TGT="sse4-i32x4"
fi

echo "[1/3] ISPC SIMD kernel → ${TGT}"
ispc -g --pic -O0 square_root.ispc -o square_root_ispc.o -h square_root_ispc.h --target=${TGT}

echo "[2/3] ISPC tasks kernel → ${TGT}"
ispc -g --pic -O0 square_root_tasks.ispc -o square_root_ispc_tasks.o -h square_root_ispc_tasks.h --target=${TGT}

echo "[3/3] C++ link (non-PIE to match ISPC obj)"
g++ -O2 -g -fno-omit-frame-pointer -no-pie \
    square_root_main.cpp square_root_serial.cpp \
    square_root_ispc.o square_root_ispc_tasks.o tasksys.cpp \
    -o sqrt_compare -lm -pthread

echo
echo "Running…"
./sqrt_compare
