#pragma once
#include <cstddef>

// AVX2 8-wide float Newton square root method
void square_root_avx(const float* in, float* out, int n);
