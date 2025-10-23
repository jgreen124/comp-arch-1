//Function called by main program for square root using ISPC (single core) 
export void square_root_ispc(uniform float input[], uniform float output[], uniform int count, uniform int maxIter) {
    
    //X is te variable which will output the square root and S is the input real number
    float X = 1, S;

    //Using foreach for SPMD implementation within the core
    foreach (i = 0 ... count) {
        S = input[i];
        for (uniform int j = 0; j < maxIter; j++) {
            X = 0.5 * (X + (S/X));
        }
        output[i] = X;
    }

}