#include <math.h>

void square_root_serial(float* input, float* output, int count, int maxIter) {

    //X is te variable which will output the square root and S is the input real number
    float X = 1, S;

    for (int i = 0; i < count; i++) {
        S = input[i];
        for (int j = 0; j < maxIter; j++) {
            //Square root calculation
            X = 0.5 * (X + (S/X));
        }
        output[i] = X;
    }

}