# Assignment 2 

## Problem 1

How can we (if we can!) modify the following loops so that they can be maximally parallelized. As a first step identify
and clearly describe what sort of dependencies exist in every loop (instruction per instruction and loop iteration per loop
iteration). Clearly justify your answer whether the loop is parallelizable or not and if so how.

```c
Loop 1: (3 pts)
for (i = 0; i < 100; i++) {
	A[i] = A[i] * B[i]; /* S1 */
	B[i] = A[i] + c;    /* S2 */
	A[i] = C[i] * c;    /* S3 */
	C[i] = D[i] * A[i]; /* S4 */
}

Loop 2: (3 pts)
for (i = 0; i < 100; i++) {
	A[i] = A[i] + B[i];    /* S1 */
	B[i+1] = C[i] + D[i];  /* S2 */
}
```

### Loop 1 Analysis

In loop 1:
    - S2 depends on the updated value of S1
    - S4 depends on the updated value from S3
So S1 can be run before all other lines in the loop, S2 and S3 can be run in parallel after S1, and S4 can be run after S3. The modified loop is as follows. As for the loop iterations, they are independent and can run in parallel.

In other words, each loop has dependencies within itself, but different loop iterations are entirely independent, and each loop iteration can be run in parallel. For each loop iteration, S4 needs to wait for S3 to finish, and S2 needs to wait for S1 to finish. 

In Loop 2:
    - S1 and S2 have no dependencies within the loop, but S2 depends on the value of B[i+1] from a different loop iteration.
So S1 and S2 can be run in parallel within the same loop iteration, but different loop iterations cannot be run in parallel due to the dependency of S2 on the next iteration's value of B. In its current form, loop 2 cannot be parallelized. Furthermore, it isn't possible to modify loop 2 to be parallelizable without changing the logic of the program, as each iteration of S2 depends on the result of the previous iteration.

