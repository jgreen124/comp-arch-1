// tasksys.cpp — fixed version supporting both ISPCLaunch signatures

#include <pthread.h>
#include <vector>
#include <cstdint>
#include <cstdlib>
#include <cstring>

using ISPCTaskFunc3 = void (*)(void*, int32_t, int32_t);
using ISPCTaskFunc4 = void (*)(void*, int32_t, int32_t, void*);

struct ThreadInfo {
    void   *fnPtr;
    void   *data;
    int32_t tid;
    int32_t total;
    void   *extra;
};

static inline void callTask(void *fnPtr, void *data, int32_t tid, int32_t total, void *extra) {
    // call 4-arg if available, safe for 3-arg under SysV ABI (extra is ignored)
    reinterpret_cast<ISPCTaskFunc4>(fnPtr)(data, tid, total, extra);
}

static void* threadMain(void *arg) {
    ThreadInfo *t = static_cast<ThreadInfo*>(arg);
    callTask(t->fnPtr, t->data, t->tid, t->total, t->extra);
    return nullptr;
}

extern "C" {

// Alloc supports 64-bit size
void *ISPCAlloc(void **handlePtr, int64_t size) {
    void *mem = std::malloc((size_t)size);
    if (mem) std::memset(mem, 0, (size_t)size);
    if (handlePtr) *handlePtr = mem;
    return mem;
}

// Single unified entry that safely handles both 4- and 5-arg calls
void ISPCLaunch(void *f, void *data, int32_t count, int32_t taskCount, void *extra = nullptr) {
    if (taskCount < 1) taskCount = 1;

    if (taskCount == 1) {
        callTask(f, data, 0, 1, extra);
        return;
    }

    ThreadInfo *info = (ThreadInfo*)std::malloc(sizeof(ThreadInfo) * (size_t)taskCount);
    for (int32_t i = 0; i < taskCount; ++i)
        info[i] = ThreadInfo{ f, data, i, taskCount, extra };

    std::vector<pthread_t> threads((size_t)(taskCount - 1));
    for (int32_t i = 1; i < taskCount; ++i)
        pthread_create(&threads[(size_t)i - 1], nullptr, threadMain, &info[i]);

    threadMain(&info[0]);

    for (auto &th : threads) pthread_join(th, nullptr);
    std::free(info);
}

void ISPCSync(void * /*handle*/) {}

} // extern "C"
