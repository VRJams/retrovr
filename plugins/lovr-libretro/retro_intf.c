#include "log.h"
#include "retro_intf.h"

#include <assert.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include <libretro.h>

// Represent the interface with a libretro core.
typedef struct {
    void *handle;
    bool initialized;

    void (*retro_init)(void);
    void (*retro_deinit)(void);
    unsigned (*retro_api_version)(void);
    void (*retro_get_system_info)(struct retro_system_info *info);
    void (*retro_get_system_av_info)(struct retro_system_av_info *info);
    void (*retro_set_controller_port_device)(unsigned port, unsigned device);
    void (*retro_reset)(void);
    void (*retro_run)(void);
    //size_t (*retro_serialize_size)(void);
    //bool (*retro_serialize)(void *data, size_t size);
    //bool (*retro_unserialize)(const void *data, size_t size);
    //void retro_cheat_reset(void);
    //void retro_cheat_set(unsigned index, bool enabled, const char *code);
    bool (*retro_load_game)(const struct retro_game_info *game);
    //bool retro_load_game_special(unsigned game_type, const struct retro_game_info *info, size_t num_info);
    void (*retro_unload_game)(void);
    //unsigned retro_get_region(void);
    //void *retro_get_memory_data(unsigned id);
    //size_t retro_get_memory_size(unsigned id);

    void (*retro_set_environment)(retro_environment_t);
    void (*retro_set_video_refresh)(retro_video_refresh_t);
    void (*retro_set_input_poll)(retro_input_poll_t);
    void (*retro_set_input_state)(retro_input_state_t);
    void (*retro_set_audio_sample)(retro_audio_sample_t);
    void (*retro_set_audio_sample_batch)(retro_audio_sample_batch_t);
} retro_intf_core_t;

// The current libretro core.
static retro_intf_core_t gRetroCore;

// The destination of libretro's video frame.
static void* gVideoBufferPtr = NULL;


static void
_retro_cb_audio_sample(int16_t left, int16_t right)
{
    //TODO.
}

static size_t
_retro_cb_audio_sample_batch(int16_t const* data, size_t frame)
{
    //TODO.
    return frame;
}

static bool
_retro_cb_environment(unsigned cmd, void* data)
{
    // TODO.
    return false;
}

static void
_retro_cb_input_poll(void)
{
    //TODO.
}

static int16_t
_retro_cb_input_state(unsigned port, unsigned device, unsigned index,
    unsigned id)
{
    //TODO.
    return 0;
}

static void
_retro_cb_video_refresh(void const* data, unsigned width, unsigned height,
    size_t pitch)
{
    //TODO.
}

static bool
_retro_intf_core_load_core_from_file(char const* corePath)
{
    bool success = false;

    assert(corePath);
    assert(!gRetroCore.handle);

    gRetroCore.handle = dlopen(corePath, RTLD_LAZY);
    if (!gRetroCore.handle) {
        LOG("%s: dlopen() failed, reason: %s\n", __func__, dlerror());
        goto out;
    }

    // Load all supported libretro core symbols. Note that some functions
    // are not supported. These are not necessary to run games with most
    // cores.
#define _core_load_sym(S) do {                                          \
    *(void **) &gRetroCore.S = dlsym(gRetroCore.handle, #S);            \
    if (gRetroCore.S == NULL) {                                         \
        LOG("%s: dlsym() failed, reason: %s\n", __func__, dlerror());   \
        goto out;                                                       \
    }                                                                   \
} while (0)
    _core_load_sym(retro_init);
    _core_load_sym(retro_deinit);
    _core_load_sym(retro_api_version);
    _core_load_sym(retro_get_system_info);
    _core_load_sym(retro_get_system_av_info);
    _core_load_sym(retro_set_controller_port_device);
    _core_load_sym(retro_reset);
    _core_load_sym(retro_run);
    _core_load_sym(retro_load_game);
    _core_load_sym(retro_unload_game);
    _core_load_sym(retro_set_environment);
    _core_load_sym(retro_set_video_refresh);
    _core_load_sym(retro_set_input_poll);
    _core_load_sym(retro_set_input_state);
    _core_load_sym(retro_set_audio_sample);
    _core_load_sym(retro_set_audio_sample_batch);
#undef _core_load_sym

    // Register libretro callbacks.
    gRetroCore.retro_set_environment(_retro_cb_environment);
    gRetroCore.retro_set_video_refresh(_retro_cb_video_refresh);
    gRetroCore.retro_set_input_poll(_retro_cb_input_poll);
    gRetroCore.retro_set_input_state(_retro_cb_input_state);
    gRetroCore.retro_set_audio_sample(_retro_cb_audio_sample);
    gRetroCore.retro_set_audio_sample_batch(_retro_cb_audio_sample_batch);

    // We are done, let the core initialize itself.
    gRetroCore.retro_init();
    gRetroCore.initialized = true;

    success = true;
out:
    return success;
}

static bool
_retro_intf_core_load_game_from_file(char const* gamePath)
{
    assert(gamePath);
    assert(gRetroCore.handle);
    assert(gRetroCore.retro_load_game);

    // TODO.

    return true;
}

retro_intf_ret_t
retro_intf_init(char const* corePath, char const* gamePath)
{
    retro_intf_ret_t ret = kRetroIntfRetNoError;

    assert(corePath);
    assert(gamePath);
    assert(gRetroCore.initialized == false);

    // Firstly, load the core from its .so.
    if (!_retro_intf_core_load_core_from_file(corePath)) {
        LOG("%s: could not load core '%s'\n", __func__, corePath);
        ret = kRetroIntfRetCoreNotFound;
        goto out;
    }

    // Secondly, load the game (aka ROM).
    if (!_retro_intf_core_load_game_from_file(gamePath)) {
        LOG("%s: could not load game '%s'\n", __func__, gamePath);
        ret = kRetroIntfRetGameNotFound;
        goto out;
    }

    gRetroCore.initialized = true;
    LOG("%s: core initialized, core:%s game:%s\n",
        __func__, corePath, gamePath);

out:
    if (ret != kRetroIntfRetNoError)
        retro_intf_deinit();
    return ret;
}

void
retro_intf_deinit(void)
{
    if (gRetroCore.initialized) {
        gRetroCore.retro_deinit();
    }

    if (gRetroCore.handle) {
        int ret = dlclose(gRetroCore.handle);
        if (ret != 0) {
            LOG("%s: dlclose() failed, reason: %s\n",
                __func__, dlerror());
        }
    }

    (void)memset(&gRetroCore, 0, sizeof(gRetroCore));
}

void
retro_intf_run(void)
{
    // TODO(sgosselin): to be implemented.

    // TODO(sgosselin): remove this, right now the function will generate a
    // dummy texture that can be used to prove the pipeline is working. The
    // function should instead rely on the core video frame generation.
    if (gVideoBufferPtr) {
        static int offset = 0;

        uint8_t* data = (uint8_t*) gVideoBufferPtr;
        const size_t bufW = 640;
        const size_t bufH = 478;
        const size_t bufBpp = 4;

        for (size_t y = 0; y < bufH; ++y) {
            for (size_t x = 0; x < bufW; ++x) {
                uint8_t color = (((float) x) / bufW) * 255;
                data[(y * bufW * bufBpp) + (x * bufBpp)] =
                    (offset + color) % 255;
                data[(y * bufW * bufBpp) + (x * bufBpp) + 1] = 0;
                data[(y * bufW * bufBpp) + (x * bufBpp) + 2] = 0;
            }
        }

        offset++;
    }
}

void
retro_intf_set_video_buffer(void* buf)
{
    gVideoBufferPtr = buf;
    LOG("%s: changed video buffer destination, dst=%p\n", __func__, buf);
}

