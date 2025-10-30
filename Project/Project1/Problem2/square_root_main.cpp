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
    // --- Input parameters ---
    const int N = 10'000'000;   // 10 million elements

    // --- Generate random data ---
    vector<float> input(N), out_serial(N), out_ispc(N);
    mt19937 gen(0);
    uniform_real_distribution<float> dist(0.0f, 8.0f);
    for (int i = 0; i < N; ++i)
        input[i] = dist(gen);

    cout << "Computing square roots for " << N << " numbers...\n";

    // --- Serial computation ---
    auto t1 = high_resolution_clock::now();
    square_root_serial(input.data(), out_serial.data(), N);
    auto t2 = high_resolution_clock::now();
    double t_serial = duration<double>(t2 - t1).count();
    cout << "Serial time: " << t_serial << " s\n";

    // --- ISPC SIMD (single-core) computation ---
    t1 = high_resolution_clock::now();
    square_root_ispc(input.data(), out_ispc.data(), N);
    t2 = high_resolution_clock::now();
    double t_ispc = duration<double>(t2 - t1).count();

    // --- Correctness check ---
    float maxErr = 0.0f;
    for (int i = 0; i < N; ++i)
        maxErr = max(maxErr, fabsf(out_serial[i] - out_ispc[i]));

    cout << "Max error (ISPC vs Serial): " << maxErr << "\n";
    cout << "ISPC SIMD time: " << t_ispc
         << " s (speedup " << t_serial / t_ispc << "x)\n";

    // --- Multicore task tests ---
    cout << "\n=== Multicore ISPC Task Tests ===\n";
    cout << "Tasks\tTime (s)\tSpeedup vs Serial\n";

    for (int numTasks = 1; numTasks <= 8; numTasks *= 2) {
        t1 = high_resolution_clock::now();
        square_root_ispc_tasks(input.data(), out_ispc.data(), N, numTasks);
        t2 = high_resolution_clock::now();
        double t_tasks = duration<double>(t2 - t1).count();

        cout << numTasks << "\t" << t_tasks << "\t"
             << t_serial / t_tasks << "x\n";
    }

    cout << "\nDone.\n";
    return 0;
}
