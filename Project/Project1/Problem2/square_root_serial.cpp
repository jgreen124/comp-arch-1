#include "square_root_serial.h"
#include <cmath>

// Scalar Newton square root method
void square_root_serial(const float* in, float* out, int n) {
    for (int i = 0; i < n; ++i) {
        float s = in[i];
        float x = (s > 0.0f) ? s : 0.0f;
        for (int it = 0; it < 20; ++it) {
            x = 0.5f * (x + s / x);
            if (std::fabs(x*x - s) < 1e-4f) break;
        }
        out[i] = x;
    }
}
