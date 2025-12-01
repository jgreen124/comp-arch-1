# Assignment 5 - Branch Prediction

## Problem 1

## Problem 2

Let’s inspect the following code:
00x0038 Loop3: LD R1, 0(R4)
00x003C LD R2, 0(R5)
00x0040 DSUBI R3, R1, #4
00x0044 BNEZ R3, Loop1
00x0048 DADD R1, R0, R8
00x004C Loop1: DSUBI R3, R2, #4
00x0050 BEQZ R3, Loop2
00x0054 DADD R2, R6, R7
00x0058 Loop2: DSUBI R3, R2, R1
00x005C BEQZ R3, Loop3

We will be using a table with n-bit predictors (FSM similar to this of baseline 2-bit predictor, but the counter is
higher and depends on the size of n). The above instruction stream has already iterated for 12 times. During
execution it is found that the branch instructions in positions 0x0044 and 0x0050 were Taken in 50% of cases.
Currently, the CPU fetched the instruction with PC 00x0038 and it is about to execute the instruction stream for
the 13th time.

### Question 1: Based on the code, above, what should be the entry size of the predictors so that the possibility of having aliases is zero?

We should have an entry size of 4 entries to ensure that there are no collisions. We have static branches at the following instructions:
- `0x0044` : `BNEX R3, (Loop1)`
- `0x0050` : `BEQZ R3, (Loop2)`
- `0x005C` : `BEQZ R3, (Loop3)`

In general, some lower bits of the PC will be used for indexing the predictors. Ignoring the 2 LSBs for alignment, a bit shift should result in each branch instruction mapping to a unique entry in the predictor table:
- `0x0044 >> 2 = 0x0011`: low 2 bits are `01`
- `0x0050 >> 2 = 0x0014`: low 2 bits are `00`
- `0x005C >> 2 = 0x0017`: low 2 bits are `11`

So with a four entry predictor, we have no collisions, while if we had a two entry predictor, we would have collisions.

### Question 2: Assume that the predictors have been initialized to 00. What is the range of values that the predictors can have for the two branch instructions in PC 00x0044 and 00x0050? Why?

Each table entry is an n-bit saturating counter, with each counter starting at 0 (strongly not taken branch). Each time the branch is taken, the counter is incremented by 1, up to `2^n - 1`, and each time the branch is not taken, the counter is decremented by 1, down to 0.

Since the branches are taken 50% of the time, and the instruction stream has already executed 12 times, we would expect that there are 6 taken branches and 6 untaken branches. Depending on the order of branches taken or not taken, somewhere between 0 to 6 for the range would be a good guess, assuming that `6 < 2^n - 1`, since the counter would saturate at that point. This is also the same reasoning as to why the counter can't go below 0.

### Question 3: What is a sequence of four outcomes where Predictor A will be superior to Predictor B?

T, T, N, N

The table below shows the guesses that each Predictor would make

| Outcome | Predictor A (2-bit) | Predictor B (2-bit) | A Correct? | B Correct? |
|---------|---------------------|---------------------|------------|------------|
| T       | 00 (Not Taken)                 | 00 (Not Taken)                 | No        | No         |
| T       | 01 (Not Taken)                  | 01 (Not Taken)                 | No       | No        |
| N       | 10 (Taken)                  | 11 (Taken)                 | No       | No        |
| N       | 01 (Not Taken)                   | 10 (Taken)                  | Yes       | No        |

So Predictor A would have 1 correct prediction, while Predictor B would have 0 correct predictions.


## Problem 3 (FINISH THIS): Assume a 2-bit predictor with 1024 entires, a global history predictor (6,1) and a local history predictor (4,3).

### Question 1: Design a global history predictor and local history predictor so that the three predictors have the same hardware overhead. Ignore the bits of the history register.

Since the global history predictor and local history predictor have fixed specifications (6,1) and (4,3) respectively, we will need to modify the number of entries.

For the global history predictor (6,1):
- m = 6 history bits
- n = 1 bit counter in the pattern history table
Since we are ignoring the bits of the history register, the hardware overhead is determined by the size of the PHT times the number of bits n, which in this case would be `PHT size * 1`. Since the 2-bit predictor has 1024 entires, the hardware overhead is going to be 2048 bits. So the global history predictor will have 2048 entries, each at 1-bit.


## Problem 4: Problem 4: (4 pts) How many bits are in the (4, 4) branch predictor with 4K entries (K=210)? As I am not giving additional details on whether the entries refer only to the distinct branch instructions exclusively or to a mix of distinct branch instructions including the distinct patterns or history for each branch, you are allowed to make your own assumptions. How many entries are in a (6,8) predictor with the same number of bits? Also, how does your answers change if the predictor is specifically global and/or local? Or it does not matter?

Let's assume:
- history length is 4-bits
- counter width is 4-bits
- number of entries is 4K = 4096 entries
- Ignore history registers/tables unless specified otherwise

Each entry has a 4-bit counter, so the total number of bits is `4096 * 4 = 16384 bits` for the counter table.

For a (6,8) predictor with the same number of bits (16384 bits):
- `number of entries * 8 = 16384 bits`
So there will be 2048 entries in the (6,8) predictor.

Since the assumption is that we are ignoring PHT/Counter table bits, there won't be a change in the answers if the predictor is local or global, just how they are indexed. If there is a count history table or pattern history table, then the number of bits would increase accordingly, as the global predictor would have a global history register, and the local predictor would have a local history table with one set of history per tracked branch.