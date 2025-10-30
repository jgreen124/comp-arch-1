// ISPC SIMD kernel (single-core SIMD)

export void square_root_ispc(uniform const float *uniform input,
                             uniform float *uniform output,
                             uniform int count)
{
    foreach (i = 0 ... count) {
        float s = input[i];
        float x = s > 0.0f ? s : 0.0f;
        for (int j = 0; j < 20; j++) {
            x = 0.5f * (x + s / x);
            if (abs(x * x - s) < 1e-4f) break;
        }
        output[i] = x;
    }
}
