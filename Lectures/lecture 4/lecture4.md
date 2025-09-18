# Continued Discussion on CPU Basic Architecture

To increase performance, we can add more ALUs to increase. compute capability.
* Each ALU will have its own partition of registers from cache


## Scalar vs Vector Programs
- Scalar: Processes one array element using scalar instructions on scalar registers.
- Vector: Processes multiple array elements using vector instructions on vector registers.

### Vector Programs
- Advanced Vector Extensions (AVX)
- Intrinsics available in C
    - Intrinsic functions operate on vectors of eight 32-bit values (e.g., vector of 8 registers)
- Example intrinsics:
    - `_ps`: packed single-precision, float
    - `_pd`: packed double-precision, double
    - `_ss`: scalar single-precision
    - `_mm_function`: multi-media function
    - `_m256`: multi-bit vector value (32 bits by 8 vectors)
    - `_epi8`: int8_t (C equivalent)
    - `_epi64`: int64_t (C equivalent)

### Example Vector Proram with AVX Intrinsics

```c
#include <immintrin.h>
void sinx(int N, int terms, float* x, float* result)
{
    for (int i=0; i<N; i+=8)
    {
        __m256 origx = _mm256_load_ps(&x[i]); 
        // Load 8 contiguous single-precision floats (x[i]..x[i+7]) 
        // into a 256-bit AVX register (requires 32-byte alignment).

        __m256 value = origx; 
        // Initialize running sum with the first Taylor term (x).

        __m256 numer = _mm256_mul_ps(origx, _mm256_mul_ps(origx, origx)); 
        // Compute x^3 for all 8 lanes: (x * x * x).

        __m256 denom = _mm256_broadcast_ss(6); 
        // Broadcast a single scalar float into all 8 lanes of a 256-bit register. 
        // Intended to represent 3! = 6 (but note: intrinsic expects a float*).

        int sign = -1; 
        // Alternating sign for Taylor expansion (next term is negative).

        for (int j=1; j<=terms; j++)
        { 
            // value += sign * numer / denom
            __m256 tmp = _mm256_div_ps(_mm256_mul_ps(_mm256_set1ps(sign), numer), denom);
            // Multiply numerator by sign (broadcast into all lanes), 
            // then divide element-wise by denom, producing the j-th Taylor term.

            value = _mm256_add_ps(value, tmp);
            // Accumulate the term into the running sum.

            numer = _mm256_mul_ps(numer, _mm256_mul_ps(origx, origx));
            // Increase power by 2: x^(2k+1) → x^(2k+3).

            denom = _mm256_mul_ps(denom, _mm256_broadcast_ss((2*j+2) * (2*j+3)));
            // Update factorial denominator: (2j+1)! → (2j+3)! 
            // by multiplying element-wise with scalar broadcast of (2j+2)(2j+3).

            sign *= -1; 
            // Flip sign for the next term.
        }

        _mm256_store_ps(&result[i], value);
        // Store the 8 single-precision results from the AVX register 
        // back into result[i]..result[i+7] (requires 32-byte alignment).
    }
}

```
- `__m256`: a 256-bit AVX register that holds 8 packed single-precision floats.
- `_ps`: operate on 8 floats in parallel ("packed single-precision").
- `_ss`: operate on just the low float element, somtimes broadcasting it (e.g., `_mm256_broadcast_ss`).

## Data-Parallel Expression

Parallelism is visible to compilers
- Compiler understands loop iterations are independent and same loop body will be executed on large number of data elements
- Abstraction facilities automatic generation of multi-core parallel code and vector instructions to make use of SIMD processing capabilities within a core.

Example (with some fictitious syntax):
```
void sinx(int N, int terms, float* x, float* result)
{
    // declare independent loop iterations
    forall (int i from 0 to N-1) {
        float value = x[i];
        float numer = x[i] * x[i] * x[i];
        int denom = 6; // 3!
        int sign = -1;
        for (int j=1; j<=terms; j++)
        {
            value += sign * numer / denom
            numer *= x[i] * x[i];
            denom *= (2*j+2) * (2*j+3);
            sign *= -1;
        }
        result[i] = value;
    }
}
```

Another Example: If we have 16 SIMD Cores, we can do 128 elements in parallel
- Each core does 8-wide float SIMD, so 16 cores * 8 elements/core = 128 elements in parallel
- This means we have 16 simultaneous instruction streams, each capable of doing 8-wide SIMD instructions.

This is different from superscalar processing
- SIMD: One instruction, multiple data lanes inside a single core.    
    - Example: a 256-bit add does 8 float additions at once.

- Multicore + SIMD: 16 cores, each doing 8-wide SIMD → 128 elements in parallel.
    - Each core still has its own instruction stream.

- Superscalar: One core can issue multiple independent instructions in the same cycle (to different functional units)

