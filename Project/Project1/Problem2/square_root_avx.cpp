#include "square_root_avx.h"
#include <immintrin.h>
#include <algorithm>
#include <cmath>

// AVX2 8-wide float Newton square root method
void square_root_avx(const float* in, float* out, int n) {
    const int V = 8; // AVX2: 8 floats per vector
    const __m256 half = _mm256_set1_ps(0.5f);
    const __m256 zero = _mm256_set1_ps(0.0f);
    const __m256 eps  = _mm256_set1_ps(1e-12f); // avoid divide by 0

    int i = 0;

    // Vectorized outer loop
    for (; i + V <= n; i += V) {
        __m256 s  = _mm256_loadu_ps(in + i);
        // Clamp negatives to zero (inputs should be between [0,8))
        s = _mm256_max_ps(s, zero);

        // Initial guess
        __m256 x  = _mm256_max_ps(s, eps);

        // 20 iterations of Newton's method (same as the other implementations)
        for (int it = 0; it < 20; ++it) {
            __m256 div = _mm256_div_ps(s, _mm256_max_ps(x, eps));
            x = _mm256_mul_ps(half, _mm256_add_ps(x, div));
        }

        _mm256_storeu_ps(out + i, x);
    }

    // Scalar tail
    for (; i < n; ++i) {
        float s = std::max(in[i], 0.0f);
        float x = std::max(s, 1e-12f);
        for (int it = 0; it < 20; ++it) {
            x = 0.5f * (x + s / x);
        }
        out[i] = x;
    }
}
