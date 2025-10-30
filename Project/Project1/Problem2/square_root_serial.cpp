#include <cmath>
#include "square_root_serial.h"

void square_root_serial(const float* input, float* output, int count) {
    for (int i = 0; i < count; i++) {
        float s = input[i];
        float x = s > 0.0f ? s : 0.0f;
        for (int j = 0; j < 20; j++) {
            x = 0.5f * (x + s / x);
            if (fabsf(x * x - s) < 1e-4f)
                break;
        }
        output[i] = x;
    }
}
