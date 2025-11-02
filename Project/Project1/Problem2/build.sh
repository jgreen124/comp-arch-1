#!/usr/bin/env bash
# Build the project:

set -euo pipefail

# Set up ISPC SIMD kernel
echo "[1/4] ISPC SIMD kernel"
# --target=avx2-i32x8 : 8-wide AVX2 gang
# --pic : generate position-independent code for -no-pie
ispc -O3 --pic --target=avx2-i32x8 square_root.ispc \
  -o square_root_ispc.o -h square_root_ispc.h

echo "[2/4] Serial obj"
g++ -O3 -c square_root_serial.cpp -o square_root_serial.o

echo "[3/4] AVX2 obj"
# -mavx2 -mfma enables AVX2 and FMA instructions
g++ -O3 -mavx2 -mfma -c square_root_avx.cpp -o square_root_avx.o

echo "[4/4] Link"
# -no-pie to avoid PIE relocation errors with ISPC objects
g++ -O3 -fno-omit-frame-pointer -no-pie \
  square_root_main.cpp square_root_serial.o square_root_ispc.o square_root_avx.o \
  -o sqrt_compare -lm -pthread

echo "Built ./sqrt_compare"
