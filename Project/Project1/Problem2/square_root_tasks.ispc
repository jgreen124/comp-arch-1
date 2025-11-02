// square_root_tasks.ispc

// Workhorse over a [start,end) range
inline void do_range(uniform const float *uniform input,
                     uniform float *uniform output,
                     uniform int start,
                     uniform int end)
{
    foreach (i = start ... end) {
        float s = input[i];
        float x = (s > 0.0f) ? s : 0.0f;
        // Newton iterations with early exit
        for (int it = 0; it < 20; ++it) {
            x = 0.5f * (x + s / x);
            if (abs(x * x - s) < 1e-4f) break;
        }
        output[i] = x;
    }
}

rm -f *.o sqrt_compare square_root_ispc.h square_root_ispc_tasks.h
ispc -g --pic -O0 square_root.ispc \
  -o square_root_ispc.o -h square_root_ispc.h --target=avx2-i32x8
ispc -g --pic -O0 square_root_tasks.ispc \
  -o square_root_ispc_tasks.o -h square_root_ispc_tasks.h --target=avx2-i32x8
g++ -O2 -g -fno-omit-frame-pointer -no-pie \
  square_root_main.cpp square_root_serial.cpp \
  square_root_ispc.o square_root_ispc_tasks.o tasksys.cpp \
  -o sqrt_compare -lm -pthread


// Public API that actually launches numTasks tasks
export void square_root_ispc_tasks(uniform const float *uniform input,
                                   uniform float *uniform output,
                                   uniform int count,
                                   uniform int numTasks)
{
    launch[numTasks] square_root_task(input, output, count, numTasks);
}

// Debug helper: same computation but without launch[] (single thread)
export void square_root_ispc_tasks_nolaunch(uniform const float *uniform input,
                                            uniform float *uniform output,
                                            uniform int count,
                                            uniform int numTasks /*ignored*/)
{
    do_range(input, output, 0, count);
}
