// tasksys.cpp — ISPC launch runtime for your build
// Callsite ABI (from your GDB trace): ISPCLaunch(void* data, void* func, int32_t dispatch, int32_t taskCount, ...)
// Task entry expects 5+ integer args in rsi, rdx, rcx, r8d (and stores r9d too). We fill r9d with 0.
// Build with:  g++ -O2 -g -fno-omit-frame-pointer -no-pie tasksys.cpp -pthread

#include <pthread.h>
#include <vector>
#include <cstdint>
#include <cstdlib>
#include <cstring>

using ISPCTaskFunc5 = void (*)(void*, int32_t, int32_t, int32_t, int32_t);

struct ThreadInfo {
    ISPCTaskFunc5 func;
    void *data;
    int32_t tid;
    int32_t total;
};

static void* threadMain(void *arg) {
    ThreadInfo *t = static_cast<ThreadInfo*>(arg);

    // SysV x86-64 integer args: rdi=data, rsi=progIdx, rdx=progCnt, rcx=taskIdx, r8d=taskCnt, r9d=extra
    // Zero r9d to avoid reading garbage if the kernel stores it.
    t->func(t->data,          // rdi
            t->tid,           // rsi: programIndex
            t->total,         // rdx: programCount
            t->tid,           // rcx: taskIndex
            t->total);        // r8d: taskCount
    return nullptr;
}

extern "C" {

void *ISPCAlloc(void **handlePtr, int64_t size) {
    void *mem = std::malloc((size_t)size);
    if (mem) std::memset(mem, 0, (size_t)size);
    if (handlePtr) *handlePtr = mem;
    return mem;
}

// Variadic to accept 4-arg or 5-arg ISPC call patterns; we ignore extras.
// IMPORTANT: first pointer is DATA, second is FUNC (matches your trace).
void ISPCLaunch(void *data, void *f, int32_t /*dispatch*/, int32_t taskCount, ...) {
    ISPCTaskFunc5 func = reinterpret_cast<ISPCTaskFunc5>(f);
    if (taskCount < 1) taskCount = 1;

    if (taskCount == 1) {
        func(data, 0, 1, 0, 1);
        return;
    }

    ThreadInfo *info = (ThreadInfo*)std::malloc(sizeof(ThreadInfo) * (size_t)taskCount);
    for (int32_t i = 0; i < taskCount; ++i) {
        info[i].func  = func;
        info[i].data  = data;
        info[i].tid   = i;
        info[i].total = taskCount;
    }

    std::vector<pthread_t> threads((size_t)(taskCount - 1));
    for (int32_t i = 1; i < taskCount; ++i)
        pthread_create(&threads[(size_t)i - 1], nullptr, threadMain, &info[i]);

    threadMain(&info[0]);

    for (auto &th : threads) pthread_join(th, nullptr);
    std::free(info);
}

void ISPCSync(void * /*handle*/) {}

} // extern "C"
