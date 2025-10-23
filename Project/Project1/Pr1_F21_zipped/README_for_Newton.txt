
*** TO EXECUTE Serial, ISPC and ISPC with tasks in the ORBIT system ***
Copy square_root_serial.h, square_root.ispc, square_root_tasks.ispc and square_root_main.cpp files in the node.
Please copy, paste an press 'Enter' key (execute) the below lines in the root directory (the directory you are in when you ssh into a node).

For serial, ISPC and ISPC + tasks copy the below lines: 
--------------------------------------------------------------------------------------------------------------
g++ -c ispc-v1.9.1-linux/examples/tasksys.cpp
ispc-v1.9.1-linux/ispc square_root.ispc -o square_root_ispc.o -h square_root_ispc.h --target=sse4-i32x8
ispc-v1.9.1-linux/ispc square_root_tasks.ispc -o square_root_tasks_ispc.o -h square_root_tasks_ispc.h --target=sse4-i32x8
g++ -c square_root_main.cpp --std=c++11
g++ -o square_root_main square_root_main.o square_root_ispc.o square_root_tasks_ispc.o tasksys.o -lpthread --std=c++11
--------------------------------------------------------------------------------------------------------------

**Here sse4 intrinsics were used, but if avx instrinsics are required then use --target=avx1.1-i32x16 in the above lines for ispc compilation.

*** TO EXECUTE Serial and AVX intrinsics ***
Copy square_root_serial.h and square_root_avx.c file in the node
For program with AVX intrinsics copy the below line:
gcc -o square_root_avx square_root_avx.c -mavx -lm --std=c99

