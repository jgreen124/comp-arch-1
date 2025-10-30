// square_root_tasks.ispc

task void square_root_task(uniform const float *uniform input,
                           uniform float *uniform output,
                           uniform int count,
                           uniform int numTasks)
{
    uniform int tIndex = taskIndex;
    uniform int chunk  = (count + numTasks - 1) / numTasks;
    uniform int start  = tIndex * chunk;
    uniform int end    = min((tIndex + 1) * chunk, count);

    if (tIndex == 0)
        print("Entered square_root_task(): start=%d end=%d numTasks=%d\n",
              start, end, numTasks);

    foreach (i = start ... end) {
        float s = input[i];
        float x = (s > 0.0f) ? s : 0.0f;
        for (int it = 0; it < 20; ++it) {
            x = 0.5f * (x + s / x);
            if (abs(x * x - s) < 1e-4f) break;
        }
        output[i] = x;
    }
}

export void square_root_ispc_tasks(uniform const float *uniform input,
                                   uniform float *uniform output,
                                   uniform int count,
                                   uniform int numTasks)
{
    print("DEBUG: count=%d numTasks=%d\n", count, numTasks);
    launch[numTasks] square_root_task(input, output, count, numTasks);
}

// Debug helper: bypass launch[] and just run the body once (for isolation)
export void square_root_ispc_tasks_nolaunch(uniform const float *uniform input,
                                            uniform float *uniform output,
                                            uniform int count,
                                            uniform int numTasks)
{
    square_root_task(input, output, count, numTasks);
}
