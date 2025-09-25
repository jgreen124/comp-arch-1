# Lecture 6: Memory in Multi-Core Processors

Terminology:
- **Memory Latency**: Time for a memory request from a processor to be serviced by memory system
- **Memory Bandwidth**: Rate at which data can be transferred between memory and processor

## Stalls

A processor "stalls" when it cannot run the next instruction in a stream because of a dependency on a previous instruction.

Example:
```assembly
    ld r0 mem[r2]
    ld r1 mem[r3]
    add r0,r0,r1
```
- The `add` instruction depends on the results of the two load instructions

The end result of the stall is that the memory access time climbs to the hundreds of cycles in count

## Methods to Reduce Stalls

### Cache reduces the length of stalls

Processors are more efficient when data is in cache
- Reduce memory access latency
    - No need to fetch data from DRAM when it is already in cache
- High bandwidth to the CPU

### Prefetching reduces stalls

All modern CPUs have logic for prefetching data into cache
- Dynamically analyze program's access patterns, predict what it will access soon and prefetch that data as well

Prefetching reduces stalls by fetching data before it is necessary. The necessary data resides in cache before it is even requested.

Example:
```assembly
    predict value of r2, initiate ld
    predict value of r3, initiate ld
    ...
    ...
    ...
    ...
    ...
    ld r0 mem[r2]
    ld r1 mem[r3]
    add r0,r0,r1
```

- The two `ld` instructions and the `add` instruction hit cache and not DRAM since data is prefetched.

### Multi-threading reduces stalls

We can interleave multiple threads to be processed by the same core to hide stalls. When on thread stall, while waiting, work on a different thread.
- Multi-threading hides latency, similar to multi-threading. This is not a latency reducing technique.



