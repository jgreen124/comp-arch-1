#!/usr/bin/env bash
# Build ISPC + C++ for the sqrt project
set -euo pipefail

# ---------- helpers ----------
have() { command -v "$1" >/dev/null 2>&1; }
die() { echo "ERROR: $*" >&2; exit 1; }
msg() { echo -e "\033[1;34m$*\033[0m"; }

pick_ispc_target() {
  if lscpu | grep -qw avx2; then
    echo "avx2-i32x8"
  else
    echo "sse4-i32x4"
  fi
}

# ---------- config ----------
TGT="${ISPC_TARGET:-$(pick_ispc_target)}"  # override: ISPC_TARGET=avx2-i32x8 ./build.sh
CXX="${CXX:-g++}"
ISPC_BIN="${ISPC_BIN:-ispc}"

# Add --pic to ISPC objs and -no-pie to link to avoid PIE mismatch
CXXFLAGS="${CXXFLAGS:- -O2 -g -fno-omit-frame-pointer -no-pie}"
LDFLAGS="${LDFLAGS:- -lm -pthread}"
ISPCFLAGS="${ISPCFLAGS:- -g --pic -O0}"

# ---------- checks ----------
have "${ISPC_BIN}" || die "ispc not found. Install ispc or set ISPC_BIN=/path/to/ispc"
have "${CXX}" || die "C++ compiler '${CXX}' not found"

# ---------- build ----------
msg "[1/3] ISPC SIMD kernel → ${TGT}"
${ISPC_BIN} ${ISPCFLAGS} square_root.ispc \
  -o square_root_ispc.o -h square_root_ispc.h --target="${TGT}"

msg "[2/3] ISPC tasks kernel → ${TGT}"
${ISPC_BIN} ${ISPCFLAGS} square_root_tasks.ispc \
  -o square_root_ispc_tasks.o -h square_root_ispc_tasks.h --target="${TGT}"

msg "[3/3] C++ link"
${CXX} ${CXXFLAGS} \
  square_root_main.cpp square_root_serial.cpp \
  square_root_ispc.o square_root_ispc_tasks.o tasksys.cpp \
  -o sqrt_compare ${LDFLAGS}

msg "Build complete: ./sqrt_compare"
