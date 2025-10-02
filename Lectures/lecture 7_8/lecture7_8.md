# Lecture 7 and 8 Combined

We left off with methods for dealing with stalls (hiding and getting rid of them).

## Hardware-supported multi-threading
- Core manages execution contexts for multiple threads
  - Runs instructions from runnable threads (processor decides order, not OS)
  - Core has same number of ALU resources, multi-threadinig only helps them stay busy more efficiently
- Interleaved Multi-threading (temporal)
  - In each clock, core chooses thread and runs an instruction from the thread on the ALUs
- Simultaneous Multi-threading
    - Each clock, core chooses instructions from multiple threads to run on ALUs
    - Extension of superscalar CPU design
    - Intel Hyper-threading (2 threads per core)

## Interleaved Multi-Threading
### Enhances parallelism
    - Hides latency by scheduling another thread while the previous one waits for O(100) clock cycles to retreive data from memory
      - Course grained: switch thread after current thread performs long latency operation
      - Fine grained: switch thread after each clock cycle to migitate real hazards
- This works opposite to OS software threads: triggering mechanism is strictly a memory stall encountered by previous instruction stream
  - Current instruction stream by current thread now runs until it either hits a stall or finishes, then the next thread is triggered.
- Type of scheduling
  - Round robin
  - triggered on stall or termination

### Architecture
- 1 F/D unit
- 1 or more ALUs
- Partioning of execution contexts (number of partitions is a power of 2).

We partition execution contexts to maintain a thread state in the Thread Control Block. The Thread Control Block is handled as a linked list. This results in high overhead for context switching.

### Benefits
- Simple scheduling mechanism
- Fast thread state retrieval

### Drawbacks
- Need to know how many threads are going to be spawned in advance
- Smaller capacity of L1 cache allocated to each thread

## Simultaneous Multi-threading
Instructions from multiple threads execute at the same time on same clock cycle.

### Enchances parallelism
- Achieves latency hiding: if one thread stalls, there are still others running
- Exploits thread-level parallelism and improves ILP by improving superscalar processor utilization.
  - It is easier to find independent instructions across threads than in the same thread.
  - Threads can run parts of the same program or different programs.
  - It reduces context switch penalty: keep state of threads in execution context instead of thread control block data structure.

## Scheduling
- Dynamic instruciton shceduler searches the scheduling window to wake up and select ready instructions. As long as dependencies are correctly tracked, scheduler can be thread agnostic.
- The thread that is selected first in order to fetch one instruction from defines the remaining instructions to be fetched by other threads: they cannot be dependent on the first instructions. There are many policies:
  - Static policy: round robin, priority based
  - Dynamic policy: 
    - Favor threads with minimal in-flight branches
    - favor threads with minimal outstanding misses
    - Favor threads with minimal in-fligh instructions. Favor faster threads that have few instructions waiting
