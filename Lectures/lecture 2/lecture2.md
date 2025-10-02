# Lecture 2 - Basic Architecture: A Modern Multi-Core CPU

**Note:** Lecture 1 is mostly introductory concepts and does not have a corresponding file.

There is a general shift to hardware, specifically multi-core CPUs and GPUs to parallelize workloads. Previously working programs need to adjust to this:
* In CPU, different cores can run different parts of the programs, and threads can be scheduled. A program running on an 8-thread CPU will adapt to maximize the thread usage
* Graphics/Math applications are example, adjusting to utilize the GPU. 

The opposite is also true - hardware can be designed for specific pieces of software.
* FPGAs can be reprogrammed for specific tasks.
* ASICs are custom hardware for specific tasks, e.g. Bitcoin mining.

## Syllabus Information
* Simulation Projects
* Some Homeworks
* Paper Reviews (Some will be discussed in the class)
* Some quizzes and maybe a final

Canvas will be updated with sample projects and conference papers as we go through the course

## Parallel Execution
### Example Program: sin(x) with Taylor Expansion

Taylor Expansion is defined as `sin(x) = x - x^3/3! + x^5/5! - x^7/7! + ...`. The code below computes the expansion sequentially.

```c
void sinx(int N, int terms, float* x, float* result) {
    for (int i = 0; i<N; i++){ // Loops N-1 times with 5 instructions
        float value = x[i];
        float number = x[i] * x[i] * x[i];
        int denom = 6; //3!
        int sign = -1;

        for (int j=1; j<=terms; j++){ // Loops terms-1 times with 4 instructions
            value += sign * number/denom
            number *= x[i]*x[i];
            denom *=(2*j+2)*(2*j+3);
            sign *= -1;
        } 
        result[i] = value;
    }
}
```

The number of clock cycles needed for the program can be calculated fairly easily. Assuming each instruction takes 1 clock cycle, the total number of clock cycles is `(N-1)*5 + (terms+1)*4)`.

With 4 cores that are hyperthreaded, we would have 8 threads (virtual cores) that can be used to compute the expansion in parallel. At best, program runs 8 times faster but this is not guaranteed. Dependencies in the program (I.E. one part of the program depends on the other part of the program) can cause delays.
* In this case, the `i loop` is more parallelizable because `j loop` uses data that is determined by the current iteration of the `i loop`.
* Every iteration of the `i loop` is independent of each other, so they can be parallelized. With 8 threads, 8 iterations of the `i loop` can be executed at the same time.


### Another Example: Average Age in a Room
Calculation of the average age of people in a room can be parallelized by dividing the people into equal size groups, having different threads calculate the average of each group, and then calculating the average of those averages.

#### Question: If we have 8 rows and 14 columns with people filling each spot in the array, would it be better to divide by rows or columns?
If `N` is the number of rows and `M` is the number of columns:
* Sequentially: Complexity is O(NxM)
* If we have as many threads as rows: Complexity is O(M) + O(N-1) (each thread is O(M) for M people in each row, and then we have to combine the results which is O(N-1), the first thread  already knows its own result and just needs to combine the other N-1 results)
* If we have as many threads as columns: Complexity is O(N) + O(M-1) (each thread is O(N) for N people in each column, and then we have to combine the results which is O(M-1), the first thread already knows its own result and just needs to combine the other M-1 results)

**Note:** The result also changes depending on the number of cores available as some loops would need to wait for threads to become available if there aren't enough threads to run everything in parallel.

## Program Compiling and Architecture
Compiling the high level language code results in assembly instructions that are run by the CPU. Normal instructions steps include:
1. Fetch instruction from memory.
2. Decode instruction.
3. Execute instruction.

With multiple cores, this gets a little more complicated as data busses and memory are shared. Memory in the CPU is tiered:
1. L1 Cache - Smallest and fastest, usually private to each core.
2. L2 Cache - Larger and slower, usually private to each core. L2 Cache acts as buffer between L1 Cache and L3 Cache.
3. L3 Cache - Even larger and slower, usually shared between all cores.
4. RAM - Much larger and slower, shared between all cores. RAM is not physically located on the CPU chip.

The cache levels use SRAM and RAM is generally DRAM. As a result, cache is faster but more expensive per bit, while RAM is slower but cheaper per bit (and higher density).

### Spatial Locality
When we request data from memory to cache, we retrieve blocks of data at a time. This is because we can assume that a program accessing a specific memory location will need to access nearby memory locations soon. This can effectively cut down on the number of load operations we need to do if we are accessing data that is close together in memory.


### Superscalar Processor
Instruction Level Parallelism (ILP): Processor automatically finds independent instructions in a sequence and can execute them in parallel on multiple execution units.

Example: The code below does not have ILP because each instruction depends on the previous instruction.
```
ld r0, addr[r1]
mul r1, r0, r0
mul r1, r1, r0
```
Another Example: The code below has ILP because the first two instructions are independent of each other and can be executed in parallel.
```
add r0, r0, r1 // ILP here
add r2, r2, r3 // ILP here
mul r0, r2, r0 // No ILP here
```

Question: How many Fetch/Decode units do modern day (2025) CPUs have?