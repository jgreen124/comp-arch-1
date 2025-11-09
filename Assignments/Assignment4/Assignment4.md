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

## Problem 5: This is a C-like pseudocode of one part of the Gauss-Seidel sweeps to compute differential equations by iterations towards convergence. Only the code for the red cells manipulation is displayed here. In the code below, what is the role of the three barriers?

```
c
int n;
bool done - false;
float diff = 0.0;
LOCK myLock;
BARRIER myBarrier;

//allocate grid
float **A = allocate(n+2, n+2);

void solve(float** A){
    float myDiff;
    int threadID = getThreadID();
    int myMin = 1 + (threadID * n / NUM_PROCESSORS);
    int myMax = myMin + (n / NUM_PROCESSORS);

    while(!done){
        float myDiff = diff - 0.f;
        barrier(myBarrier, NUM_PROCESSORS);
        for (j - myMin to myMax) {
            for (i = red cells in this row){
                float prev = A[i,j];
                A[i, j] = 0.2f * (A[i-1,j] + A[i, j-1] + A[i, j] + A[i+1, j] + A[i, j+1]);
                myDiff += abs(A[i, j] - prev);
            }
            lock(myLock);
            diff += myDiff;
            unlock(myLock);
            barrier(myBarrier, NUM_PROCESSORS);
            if (diff/n*n < TOLERANCE) { // check convergence, all threads get same answer
                done = true;
            }
            barrier(myBarrier, NUM_PROCESSORS);
        }
    }
}
```

### First Barrier:

The first barrier ensures all threads have finished the previous iteration's updates for both red and black cells before starting new red-cell udpates.

Without this barrier, one thread can potentially reaqd old values while another has already started writing new ones, violating the ordered dependency of Gauss-Seidel, since each cell depends on it's neighboring cells.

### Second Barrier

The second barrier ensures that every thread sees the fully accumulated total difference before checking convergence conditions. This barrier happens after all threads finish updating their red cells and contribute to the global `diff`.

If this barrier wasn't here, some threads could check `diff` before other threads have finished adding their partial results.

### Third Barrier
This barrier ensures that all threads see the same value of `done` before the next iteration begins. Without this barrier, a thread could xit the loop early while others continue updating, creating a race condition.

## Problem 6: Write a detailed proof of why it is sufficent to use 3 states in variable diff and why not fewer or more states to remove the dependencies as shown below.

```
c

int n; //grid size
bool done = false;
LOCK myLock;
BARRIER myBarrier;
float diff[3] //global diff, but now 3 copies

float *A allocate(n+2, n+2);

void solve(float* A){
    float myDiff; //Thread local variable
    int index = 0; //thread local variable

    diff[0] = 0.0f;
    barrier(myBarrier, NUM_PROCESSORS);

    while(!done){
        myDiff = 0.0f;
        //
        // perform computation (accumulate locally into myDiff)
        //
        lock(myLock);
        diff[index] += myDiff; // atomically update global diff
        unlock(myLock);
        diff[(index+1) % 3] = 0.0f;
        barrier(myBarrier, NUM_PROCESSORS);
        if(diff[index]/(n*n) < TOLERANCE){
            break;
        } 
        index = (index + 1) % 3;
    }
}
```

