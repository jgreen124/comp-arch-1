# Assignment 3

Josh Green and Akhil Sankar
Group 04

## Problem 1

Assume the following instruction stream is given:

```
for (int x = 0; x < dimX-1; x++) {
    for (int y = 0; y < dimY-1; y++) {
        for (int z = 0; z < dimZ-1; z++) {
            int index = x * dimY * dimZ + y * dimZ + z;
            if (y > 0 && x > 0) {
                solid = idx[index];
                    dH1 = (Hz[index] – Hz[index-incY])/dy[y]; //1 subtraction, 1 division, 2 FLOPS total
                    dH2 = (Hy[index] – Hy[index-incZ])/dz[z]; //1 subtraction, 1 division, 2 FLOPS total
                    Ex[index] = Ca[solid]*Ex[index]+Cb[solid]*(dH2-dH1); // 1 subtraction, 2 multiplications, 1 addition, 4 FLOPS total
            }
        }
    }
}
```

`dH1`, `dH2`, `Hy`, `Hz`, `dy`, `dz`, `Ca`, `Cb`, and `Ex` are all single-precision floating-point arrays and `idx` is an unsigned integer array.

### Part 1: What is the arithmetic intensity (how many operations performed in a certain number of clock cycles) of the instruction stream/kernel?

Since we are dealing with arithmetic intensity, we will be counting FLOPS and bytes

Let's consider the inner loop first:
* When the condition is satisfied, there are 8 FLOPS
* idx[index] is accessed once (4 bytes)
* Hz[index] and Hz[index-incY] are both accessed (8 bytes)
* Hy[index] and Hy[index-incZ] are both accessed (8 bytes)
* dy[y] and dz[z] are both accessed (8 bytes)
* Ca[solid] and Cb[solid] are both accessed (8 bytes)
* Ex[index] is accessed once (4 bytes) and written once (4 bytes). Therefore, it is 8 bytes total
The inner loop involves 44 bytes of data movement and 8 FLOPS. Therefore, the arithmetic intensity of the inner loop (worst case scenario) is `8 FLOPS`/`44 bytes` = `0.1818 FLOPS/byte`

By calculating the worst case scenario inner loop arithmetic intensity, we can assume that the overall arithmetic intensity of the entire kernel is also `0.1818 FLOPS/byte` since the non-worse case scenario will only result in less operations being performed.





### Part 2: Is this instruction stream/kernel amendable to vector or SIMD execution? Why or why not?

The code is friendly to SIMD execution, especially within the inner loop. Different iterations of the inner loop are independent of each other, meaning that they can be executed in parallel. Furthermore, the data strides in the inner loop would be consistent, further facilitating SIMD operation.

The outer loop is also possible to parallelize, but it would be preferable to use threads. Assign each thread an `(x, y)` pair, and have the thread iterate over `z`. This would ensure that each thread is working on contiguous memory locations, which is more cache friendly.

### Part 3: Assume this kernel is to be executed on a processor that has 30 GB/sec of memory bandwidth. Will this kernel be memory bound or compute bound?/

This process would be memory bound. The low arithmetic intensity indicates that we would need a lot of memory bandwidth to keep the processor busy. In order to compute 1 FLOP, we would need 5.5 Bytes of memory bandwidth. Therefore, with 30 GB/sec of memory bandwidth, we would be able to perform `30 GB/sec / 5.5 Bytes/FLOP = 5.45 GFLOPS`. This is a relatively low number, indicating that the processor would be waiting on memory access most of the time.

## Problem 2

Let’s now consider the following chip architectures:

- a) 4 core, 4 SMT, 4-wide SIMD capability
- b) 4 core, 2 interleaved/temporal Multithreading, 16-wide SIMD capability
- c) 2 core, 4 interleaved/temporal Multithreading, 16-wide SIMD capability
- d) 4 core, 8-way ILP, 4-wide SIMD capability
- e) 2 core, 8 interleaved/temporal multithreading, 8-wide SIMD capability
- f) 8 core, 2 SMT, 2-wide SIMD capability

### Question: Which are the top TWO architectures (out of SIX in total) better suited for a program with the following characteristics and why: Heavy in computations program. Takes input of 1024 array elements. Each element is a measure of “sunlight” sampled exactly every 30 minutes on a city exactly on the Earth’s equator. The result is a positive number when the sun is observed (day) and a negative number when the sun is not observed (night). The program is divergent and also exposes a lot of data re-use. Non-negative elements x[i] follow a heavy computational branch, while negative elements x[i] conduct the following calculation: y[i] = y[i] / x[i].

CPUs `d` and `f` are the best suited for this program. 
Note that the program is heavy in computations, divergent, and has a lot of data re-use. 

With a heavy computational workload, ILP will be the most beneficial. As we compute many different branches, we will see a heavy divergence in the instruction streams, making SIMD not as effective. Furthermore, the large amount of data re-use would be diluted by using multiple threads. 

Due to the parallelism of CPU `d` being primarily from the 8-Way ILP, it would be the best suited for this program. CPU `f` would be the second best, as it's low SMT count would help reduce cache thrashing and it's low SIMD width would help reduce the impact of divergence when compared to the other CPUs.

## Problem 4

Consider the following three CPU organizations:
- **CPU SS**: A two-core supserscalar microprocessor that provides out-of-order issue capabilities on two FUs. Only a single thread can run on each core at a time.
- **CPU MT**: A fine-grained multithreaded processor that allows instructions from two threads to be run concurrently (i.e., there are two functional units), though only instructions from a single thread can be issued on any cycle.
- **CPU SMT**: An SMT processor that allows instructions from two threads to be run concurrently (i.e., there are two functional units), and instructions from either or both threads can be issued to run on any cycle.

Assume we have two threads `X` and `Y` to run on these CPUs that include the following operations:

| Thread X | Thread Y |
|----------|----------|
| A1: takes 3 cycles to execute | B1: takes 2 cycles to execute |
| A2: no dependencies | B2: conflicts for a functional unit with B1 |
| A3: conflicts for a functional unit with A1 | B3: depends on the result of B2 |
| A4: depends on the results of A3 | B4 : no dependencies and takes 2 cycles to execute |

Assume all instructions take a single cycle to execute unless noted otherwise or they encounter a hazard.

### Question 1: Assume that you have one SS CPU. How many cycles will it take to execute these two threads? How many issue slots are wasted due to hazards?

Since we have two cores, we can run both threads in parallel (one on each core). Furthermore, each core has two FUs to work with.

For Core 1 (Thread X):

FU1 spends 3 cycles on A1.
FU2 can execute A2 in parallel with A1, taking 1 cycle.
A3 must wait for A1 to finish, so A3 will occur on FU1 at cycle number 4, taking 1 cycle.
A4 must wait for A3 to finish, so A4 will occur on FU1 at cycle 5, taking 1 cycle.

Therefore, Thread X will take 5 cycles to complete. There are 4 cycles wasted where FU1 is doing work while FU2 is idle

| Cycle | FU1       | FU2       |
|-------|-----------|-----------|
| 1     | A1 (1/3)  | A2 (1/1)  |
| 2     | A1 (2/3)  | Idle      |
| 3     | A1 (3/3)  | Idle      |
| 4     | A3 (1/1)  | Idle      |
| 5     | A4 (1/1)  | Idle      |   

For Core 2 (Thread Y):
FU1 spends 2 cycles on B1.
B2 needs to wait for B1 to finish, so B2 will occur on FU1 at cycle number 3, taking 1 cycle.
B3 needs to wait for B2 to finish, so B3 will occur on FU1 at cycle number 4, taking 1 cycle.
B4 has no dependencies, and can be run on FU2 in parallel with the other instructions.

Therefore, Thread Y will take 4 cycles to complete. There are 2 cycles wasted where FU1 is doing work while FU2 is idle.

| Cycle | FU1       | FU2       |
|-------|-----------|-----------|
| 1     | B1 (1/2)  | B4 (1/2)  |
| 2     | B1 (2/2)  | B4 (2/2)  |
| 3     | B2 (1/1)  | Idle      |
| 4     | B3 (1/1)  | Idle      |

In total, we have 6 wasted slots (4 from Thread X and 2 from Thread Y). Since Thread X takes longer to complete, the total number of cycles to execute both threads is 5 cycles.

### Question 2: Now assume you have two SS CPUs. How many cycles will it take to execute these two threads.

Adding additional CPUs does not help in this case, since we only have two threads to execute and a single SS CPU was already able to execute both threads in parallel. Therefore, the total number of cycles to execute both threads remains 5 cycles.

### Question 3: Assume you have one MT CPU. How many cycles will it take to execute these two threads? How many issue slots are wasted due to hazards?

| Cycle | Issuing Thread | FU1      | FU2      |
| ----- | -------------- | -------- | -------- |
| 1     | X              | A1 (1/3) | Idle     |
| 2     | Y              | A1 (2/3) | B4 (1/2) |
| 3     | —              | A1 (3/3) | B4 (2/2) |
| 4     | Y              | B1 (1/2) | Idle     |
| 5     | X              | B1 (2/2) | A2 (2/2) |
| 6     | X              | A3 (1/1) | Idle     |
| 7     | X              | A4 (1/1) | Idle     |
| 8     | Y              | B2 (1/1) | Idle     |
| 9     | Y              | B3 (1/1) | Idle     |



In total, we have 6 wasted slots and can run the two threads in 9 cycles, mainly due to the fact that we can only issue instructions from one thread at a time.

### Question 4: Assume you have one SMT CPU. How many cycles will it take to execute these two threads? How many issue slots are wasted due to hazards?

| Cycle | FU1       | FU2       |
|-------|-----------|-----------|
| 1     | A1 (1/3)  | B1 (1/2)  |
| 2     | A1 (2/3)  | B1 (2/2)  |
| 3     | A1 (3/3)  | B2 (1/1)  |
| 4     | A3 (1/1)  | B3 (1/1)  |
| 5     | A4 (1/1)  | B4 (1/2)  |
| 6     | A2 (1/1)  | B4 (2/2)  |

In total, we have 0 wasted slots and can run the two threads in 6 cycles.