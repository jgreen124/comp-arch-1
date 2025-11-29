// mem_bench.c

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/time.h>

// Timer
static double now_seconds(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec * 1e-6;
}

// Aligned allocation
static void* alloc_aligned(size_t size, size_t alignment) {
    // aligned_alloc requires size % alignment == 0
    size_t rounded = size;
    if (rounded % alignment != 0)
        rounded = ((size + alignment - 1) / alignment) * alignment;

    void* ptr = aligned_alloc(alignment, rounded);
    if (!ptr) {
        // Fall back
        ptr = malloc(rounded);
    }
    return ptr;
}


// Cache Sweep Benchmark
static void run_cache_sweep(void) {
    const size_t min_size_bytes = 1 * 1024;
    const size_t max_size_bytes = 256 * 1024 * 1024;
    const double target_total_bytes = 4.0 * 1024 * 1024 * 1024.0;
    const size_t alignment = 64;

    printf("test_type,size_bytes,repeats,bytes_touched,time_seconds,bandwidth_Bps,bandwidth_GBps\n");

    for (size_t size = min_size_bytes; size <= max_size_bytes; size <<= 1) {
        size_t n = size / sizeof(double);
        if (n == 0) continue;

        double *a = (double*)alloc_aligned(size, alignment);
        if (!a) { perror("alloc"); exit(1); }

        for (size_t i = 0; i < n; i++) a[i] = 1.0;

        double repeats_d = target_total_bytes / (double)size;
        if (repeats_d < 1.0) repeats_d = 1.0;
        uint64_t repeats = (uint64_t)repeats_d;

        double start = now_seconds();

        for (uint64_t r = 0; r < repeats; r++) {
            for (size_t i = 0; i < n; i++) {
                a[i] = a[i] + 1.0;
            }
        }

        double end = now_seconds();
        double elapsed = end - start;

        double accesses = (double)repeats * (double)n;
        double bytes_touched = accesses * sizeof(double) * 2.0;
        double bw = bytes_touched / elapsed;

        printf("cache_sweep,%zu,%llu,%.0f,%.9f,%.3f,%.3f\n",
            size,
            (unsigned long long)repeats,
            bytes_touched,
            elapsed,
            bw,
            bw / 1e9
        );

        volatile double sink = 0.0;
        for (size_t i = 0; i < n; i++) sink += a[i];
        (void)sink;

        free(a);
    }
}


// Streaming Bandwidth (For cache or DRAM depending on size)
 
static void run_stream(size_t size_bytes, const char *mode) {
    const size_t alignment = 64;
    size_t n = size_bytes / sizeof(double);

    printf("test_type,size_bytes,mode,bytes_touched,time_seconds,bandwidth_Bps,bandwidth_GBps\n");

    double *a = (double*)alloc_aligned(size_bytes, alignment);
    if (!a) { perror("alloc"); exit(1); }

    for (size_t i = 0; i < n; i++) a[i] = 1.0;

    volatile double sink = 0.0;

    double start = now_seconds();
    double bytes = 0;

    if (strcmp(mode, "read") == 0) {
        for (size_t i = 0; i < n; i++) sink += a[i];
        bytes = n * sizeof(double);
    }
    else if (strcmp(mode, "write") == 0) {
        for (size_t i = 0; i < n; i++) a[i] = (double)i;
        bytes = n * sizeof(double);
    }
    else { // readwrite
        for (size_t i = 0; i < n; i++) a[i] = a[i] + 2.0;
        bytes = 2.0 * n * sizeof(double);
    }

    double elapsed = now_seconds() - start;
    double bw = bytes / elapsed;

    printf("stream,%zu,%s,%.0f,%.9f,%.3f,%.3f\n",
        size_bytes,
        mode,
        bytes,
        elapsed,
        bw,
        bw / 1e9
    );

    free((void*)a);
    (void)sink;
}


static void usage(const char *p) {
    fprintf(stderr,
        "Usage:\n"
        "  %s cache_sweep\n"
        "  %s stream <size_MB> [read|write|readwrite]\n",
        p, p
    );
}


int main(int argc, char **argv) {
    if (argc < 2) { usage(argv[0]); return 1; }

    if (strcmp(argv[1], "cache_sweep") == 0) {
        run_cache_sweep();
        return 0;
    }
    else if (strcmp(argv[1], "stream") == 0) {
        if (argc < 3) { usage(argv[0]); return 1; }

        long mb = strtol(argv[2], NULL, 10);
        if (mb <= 0) { fprintf(stderr, "Invalid size: %s\n", argv[2]); return 1; }

        const char *mode = "readwrite";
        if (argc == 4) mode = argv[3];

        run_stream((size_t)mb * 1024 * 1024, mode);
        return 0;
    }

    usage(argv[0]);
    return 1;
}
