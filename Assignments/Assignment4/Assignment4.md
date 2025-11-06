# Assignment 4
*** Josh Green and Akhil Sankar ***

## Problem 1

## Problem 2

## Problem 3

### After calling the following function, please specify what values will array RET have and why?

```c
export void f_fu(
    uniform float RET[],
    uniform float aFOO[],
    uniform float b) {
        float v = aFOO[programIndex];
        uniform float m;
        m = reduce_add(v);
        RET[programIndex] = m;
    }
```

Step 1: `v = aFOO[programIndex];`
- Every ISPC program instance is going to load a single element of `aFOO`

Step 2: `m = reduce_add(v)`
- `reduce_add()` is a cross-lane reduction. It will add up v across all instances in the gang

If the gang has N instances, then `reduce_add()` returns $$\sum_{i=0}^{N-1} {aFOO[i]}$$
- Since `reduce_add()` is uniform, all instances in the gang return the same value.

Step 3: `RET[programIndex] = m;`
- Each instance writes its uniform value `m` into its own index of `RET`
- Since m is identical for every instance, all elements of `RET` get the same value.

Therefore, the array `RET` will have every index with a value of `m`, which itself will change between gangs. In other words, if the SIMD width is lesser than the array length, multiple gangs will be needed, and each gang can potentially have a different value of m if each gang processes a different slice of `aFOO`.

## Problem 4

### Inspect the following code and answer the questions for AVX vector intrinsics used, where each vector register contains eight 32-bit single-precision floating point numbers and N = 200;

```c
// ISPC Code
export void hello(
    uniform int N,
    uniform float* x, //input
    uniform float* y) //output
    {
        foreach (i = 0 ... N)
            y[(8*i) % 32] = x[i];
    }
```

#### Part 1: Is this code a valid data parallel program in its fundamental definition?

No, this code is not a valid data parallel program because `y[(8*i) % 32] = x[i]` maps x[i] to multiple different locations, some of which will collide with other instances (if instance i has `i = 1 + 30k`, then every instance that meets this criteria writes its result to `y[1]`). 

#### Part 2: Is this code a fvalid ISPC program? Why yes, why not?

The code is not semantically correct. ISPC allows for scatter stores, but since multiple lanes will be writing to the same address, the result will be undefined (we don't know which instance will have the last write).

#### Part 3: Does this code depend on the implementation of foreach of foreach to be a valid program? How?

Since we have write conflicts within the ISPC program, defining a mapping and order for how iterations are mapped, ordered, or sized will cause changes to the final output.

#### Part 4: Let’s assume that the implementation of foreach changes in the future. How does it affect the validity of this ISPC program?

Even with the same inputs and target, a different foreach partitioning or ordering could make a different iteration be the last writer to a location.

#### Part 5: Let’s assume that we switch to AVX512 we recompile the code. Our ISPC gang is now size 16. How does this change affect the validity of the ISPC program?

Switching to AVX512 does not resolve the core issue with the program because expanding the gang size does not remove the inherent collisions that will happen as we write to memory. In fact, this could potentially make collisions more problematic as an increase in the gang size would introduce more collisions per write instruction.

