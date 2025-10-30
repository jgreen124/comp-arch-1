// Function executed by each launched task
task void square_root_task(uniform const float *uniform input,
                           uniform float *uniform output,
                           uniform int count,
                           uniform int numTasks)
{
    uniform int tIndex = taskIndex;
    uniform int chunk  = (count + numTasks - 1) / numTasks;
    uniform int start  = tIndex * chunk;
    uniform int end    = min((tIndex + 1) * chunk, count);

    // Loop variable declared as uniform before foreach
    uniform int i;
    foreach (i = start ... end) {
        float s = input[i];
        float x = s > 0.0f ? s : 0.0f;
        for (int j = 0; j < 20; ++j) {
            x = 0.5f * (x + s / x);
            if (abs(x * x - s) < 1e-4f)
                break;
        }
        output[i] = x;
    }
}

// Exported launcher that spawns numTasks tasks
export void square_root_ispc_tasks(uniform const float *uniform input,
                                   uniform float *uniform output,
                                   uniform int count,
                                   uniform int numTasks)
{
    launch[numTasks] square_root_task(input, output, count, numTasks);
}
