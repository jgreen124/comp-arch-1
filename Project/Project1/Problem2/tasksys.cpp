// tasksys.cpp — minimal runtime matching ISPC symbols (ISPCAlloc/ISPCLaunch/ISPCSync)
// Works with typical ISPC 1.22–1.29 Linux builds. Link with -pthread.

#include <pthread.h>
#include <vector>
#include <cstdint>
#include <cstdlib>
#include <cstring>

using ISPCTaskFunc = void (*)(void *data, int32_t threadIndex, int32_t threadCount);

struct ThreadInfo {
    ISPCTaskFunc func;
    void *data;
    int32_t tid;
    int32_t total;
};

static void *threadMain(void *arg) {
    ThreadInfo *t = (ThreadInfo *)arg;
    t->func(t->data, t->tid, t->total);
    return nullptr;
}

extern "C" {

// Opaque per-launch storage (not used beyond satisfying symbol)
void *ISPCAlloc(void **handlePtr, int32_t size) {
    void *mem = std::malloc((size_t)size);
    if (mem) std::memset(mem, 0, (size_t)size);
    if (handlePtr) *handlePtr = mem;
    return mem;
}

// Main entry that ISPC calls for launch[numTasks]
void ISPCLaunch(void *f, void *data, int /*count*/, int32_t taskCount) {
    ISPCTaskFunc func = (ISPCTaskFunc)f;

    if (taskCount <= 1) {
        func(data, 0, 1);
        return;
    }

    // Allocate on heap so addresses stay valid while threads run
    ThreadInfo *info = (ThreadInfo*)std::malloc(sizeof(ThreadInfo) * (size_t)taskCount);
    for (int32_t i = 0; i < taskCount; ++i)
        info[i] = ThreadInfo{ func, data, i, taskCount };

    std::vector<pthread_t> threads((size_t)(taskCount - 1));
    for (int32_t i = 1; i < taskCount; ++i)
        pthread_create(&threads[(size_t)i - 1], nullptr, threadMain, &info[i]);

    // Run task 0 on caller thread
    threadMain(&info[0]);

    for (auto &th : threads) pthread_join(th, nullptr);
    std::free(info);
}

void ISPCSync(void * /*handle*/) { /* already joined */ }

} // extern "C"
