#include <iostream>
#include <vector>
#include <random>
#include <chrono>
#include <cmath>

#include "square_root_serial.h"
#include "square_root_ispc.h"
#include "square_root_ispc_tasks.h"

using namespace std;
using namespace std::chrono;
using namespace ispc;

int main() {
    const int N = 10'000'000;   // adjust to 2 when debugging
    vector<float> input(N), out_serial(N), out_ispc(N);

    // random input
    mt19937 gen(0);
    uniform_real_distribution<float> dist(0.0f, 8.0f);
    for (int i = 0; i < N; ++i) input[i] = dist(gen);

    cout << "Computing square roots for " << N << " numbers...\n";

    // Serial baseline
    auto t1 = high_resolution_clock::now();
    square_root_serial(input.data(), out_serial.data(), N);
    auto t2 = high_resolution_clock::now();
    double t_serial = duration<double>(t2 - t1).count();
    cout << "Serial time: " << t_serial << " s\n";

    // ISPC SIMD (single-core)
    t1 = high_resolution_clock::now();
    square_root_ispc(input.data(), out_ispc.data(), N);
    t2 = high_resolution_clock::now();
    double t_ispc = duration<double>(t2 - t1).count();

    double maxErr = 0.0; // use double to avoid std::max<double,float> ambiguity
    for (int i = 0; i < N; ++i) {
        double diff = std::fabs((double)out_serial[i] - (double)out_ispc[i]);
        if (diff > maxErr) maxErr = diff;
    }
    cout << "Max error (ISPC vs Serial): " << maxErr << "\n";
    cout << "ISPC SIMD time: " << t_ispc
         << " s (speedup " << (t_serial / t_ispc) << "x)\n";

    // Multicore with ISPC tasks
    cout << "\n=== Multicore ISPC Task Tests (launch[numTasks]) ===\n";
    cout << "Tasks\tTime (s)\tSpeedup vs Serial\tSpeedup vs ISPC(1 task)\n";

    for (int numTasks : {1, 2, 4, 8}) {
        t1 = high_resolution_clock::now();
        
        // square_root_ispc_tasks(input.data(), out_ispc.data(), N, numTasks);
        square_root_ispc_tasks_nolaunch(input.data(), out_ispc.data(), N, 1);
        
        t2 = high_resolution_clock::now();
        double t_tasks = duration<double>(t2 - t1).count();

        cout << numTasks << '\t'
             << t_tasks << '\t'
             << (t_serial / t_tasks) << "x\t\t"
             << (t_ispc   / t_tasks) << "x\n";
    }

    cout << "\nDone.\n";
    return 0;
}
