// ISPC SIMD kernel: Newton's method; converges to < 1e-4
export void square_root_ispc(uniform const float *uniform input,
                             uniform float *uniform output,
                             uniform int count)
{
    // foreach distributes instances across gangs
    foreach (i = 0 ... count) {
        float s = input[i];

        // s should be in [0, 8)
        float x = (s > 0.0f) ? s : 0.0f;

        // 20 iterations (will be enough for 1e-4 on [0,8])
        for (int it = 0; it < 20; ++it) {
            x = 0.5f * (x + s / x);
            if (abs(x*x - s) < 1e-4f) break;
        }
        output[i] = x;
    }
}
