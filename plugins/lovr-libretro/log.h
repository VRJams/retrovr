#pragma once

#ifdef ANDROID
#include <android/log.h>
#define LOG(...) do {                                                       \
        __android_log_print(ANDROID_LOG_VERBOSE, "RetroVR", __VA_ARGS__);   \
    } while (0)
#else
#include <stdio.h>
#define LOG(...) do {                                                       \
        printf(__VA_ARGS__);                                                \
    } while (0)
#endif

