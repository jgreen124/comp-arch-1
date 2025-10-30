// Minimal ISPC task system implementation
#include <pthread.h>
#include <vector>
#include <functional>
#include <cstdlib>
#include <cstring>
#include <cassert>

typedef void (*TaskFunc)(void *data, int threadIndex, int threadCount, void *extra);

struct TaskInfo {
    TaskFunc func;
    void *data;
    int threadIndex;
    int threadCount;
    void *extra;
};

void *ThreadMain(void *arg) {
    TaskInfo *info = (TaskInfo *)arg;
    info->func(info->data, info->threadIndex, info->threadCount, info->extra);
    return nullptr;
}

// Called by ISPC to allocate a task system context
extern "C" void *ISPCAlloc(void **handlePtr, int32_t size) {
    void *ptr = malloc(size);
    memset(ptr, 0, size);
    *handlePtr = ptr;
    return ptr;
}

// Called by ISPC to launch tasks
extern "C" void ISPCLaunch(void *f, void *data, int count, int taskCount, void *extra) {
    TaskFunc func = (TaskFunc)f;
    std::vector<pthread_t> threads(taskCount);
    std::vector<TaskInfo> infos(taskCount);

    for (int i = 0; i < taskCount; ++i) {
        infos[i] = { func, data, i, taskCount, extra };
        pthread_create(&threads[i], nullptr, ThreadMain, &infos[i]);
    }

    for (int i = 0; i < taskCount; ++i)
        pthread_join(threads[i], nullptr);
}

// Called by ISPC to synchronize after launching
extern "C" void ISPCSync(void *) {
    // Nothing needed — threads joined in ISPCLaunch
}
