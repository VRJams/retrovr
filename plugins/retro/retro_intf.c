#include "retro_intf.h"

#include <assert.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <libretro.h>

/* main interface with a libretro core; functions must be looked up */
static struct {
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
} gCore;

/* clients registered callbacks */
static void (*gInputCallback)(input_state_t *);

/* global libretro states */
static input_state_t gInputState;

static void
_retro_intf_dump_input_state(input_state_t const* state)
{
    printf("input_state@%p={\n", state);
    for (size_t i = 0; i < RETRO_INTF_INPUT_SIZE; ++i) {
        printf("[%zu]=%u,", i, state->values[i]);
    }
    printf("}\n");
}

static void
_core_cb_audio_sample(int16_t left, int16_t right)
{
    //TODO.
}

static void
_core_cb_log(enum retro_log_level level, char const* fmt, ...)
{
    char buffer[4096] = {0};
    static const char * levelstr[] = { "dbg", "inf", "wrn", "err" };
    va_list va;

    va_start(va, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, va);
    va_end(va);

    printf("[%s] %s", levelstr[level], buffer);
}

static size_t
_core_cb_audio_sample_batch(int16_t const* data, size_t frame)
{
    return frame;
}

static bool
_core_cb_environment(unsigned cmd, void* data)
{
	switch (cmd) {
	case RETRO_ENVIRONMENT_GET_LOG_INTERFACE:
		((struct retro_log_callback *) data)->log = _core_cb_log;
		break;
	case RETRO_ENVIRONMENT_GET_CAN_DUPE:
		*((bool*)data) = true;
		break;
	case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT:
		// TODO(sgosselin): implement this.
		break;
	case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
		*(const char **)data = ".";
		break;
	case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
		*(const char **)data = ".";
		break;
	default:
		return false;
	}

	return true;
}

static void
_core_cb_input_poll(void)
{
    if (gInputCallback) {
        gInputCallback(&gInputState);
    }
}

static int16_t
_core_cb_input_state(unsigned port, unsigned device, unsigned index,
        unsigned id)
{
    assert(id < RETRO_INTF_INPUT_SIZE);

    // TODO(sgosselin): we only support one controller at this time; for now
    // let's ignore anything not coming from the first input port.
    if (port != 0 || index != 0) {
        return 0;
    }

    return gInputState.values[id];
}

static void
_core_cb_video_refresh(void const* data, unsigned width, unsigned height,
        size_t pitch)
{
    // TODO(sgosselin): implement me.
}

static bool
_retro_intf_load_core_from_file(char const* corePath)
{
    bool success = false;

    assert(corePath);
    assert(!gCore.handle);

    gCore.handle = dlopen(corePath, RTLD_LAZY);
    if (!gCore.handle) {
        printf("%s: dlopen() failed, reason: %s\n", __func__, dlerror());
        goto out;
    }

#define _core_load_sym(S) do {                                          \
    *(void **) &gCore.S = dlsym(gCore.handle, #S);            \
    if (gCore.S == NULL) {                                         \
        printf("%s: dlsym() failed, reason: %s\n", __func__, dlerror());   \
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

    gCore.retro_set_environment(_core_cb_environment);
    gCore.retro_set_video_refresh(_core_cb_video_refresh);
    gCore.retro_set_input_poll(_core_cb_input_poll);
    gCore.retro_set_input_state(_core_cb_input_state);
    gCore.retro_set_audio_sample(_core_cb_audio_sample);
    gCore.retro_set_audio_sample_batch(_core_cb_audio_sample_batch);

    gCore.retro_init();
    gCore.initialized = true;

	// TODO(sgosselin): this should not be set here.
    gCore.retro_set_controller_port_device(0,
            RETRO_DEVICE_SUBCLASS(RETRO_DEVICE_LIGHTGUN, 0));

    success = true;
out:
    return success;
}

static bool
_retro_intf_load_game_from_file(char const* gamePath)
{
    bool success = false;

    assert(gamePath);
    assert(gCore.handle);
    assert(gCore.retro_load_game);

    FILE* file = fopen(gamePath, "rb");
    if (!file) {
        printf("%s: fopen() failed, reason: %s\n", __func__, strerror(errno));
        goto out;
    }

    struct retro_game_info gameInfo = { gamePath, 0 };
    fseek(file, 0, SEEK_END);
    gameInfo.size = ftell(file);
    fseek(file, 0, SEEK_SET);

    struct retro_system_info systemInfo = {0};
    gCore.retro_get_system_info(&systemInfo);

    if (!systemInfo.need_fullpath) {
        gameInfo.data = malloc(gameInfo.size);
        if (!gameInfo.data) {
            printf("%s: couldn't allocate game's memory\n", __func__);
            goto out;
        }

        if (!fread((void*) gameInfo.data, gameInfo.size, 1, file)) {
            printf("%s: fread() failed, reason: %s\n",
					__func__, strerror(errno));
            goto out;
        }
    }

    if (!gCore.retro_load_game(&gameInfo)) {
        printf("%s: libretro failed to load game '%s'\n", __func__, gamePath);
        goto out;
    }

    success = true;

out:
    if (!success)
        free((void*) gameInfo.data);
    fclose(file);

    return true;
}

bool
retro_intf_init(char const* corePath, char const* gamePath)
{
    bool success = false;

    assert(corePath);
    assert(gamePath);
    assert(!gCore.handle);
    assert(!gCore.initialized);

    // Firstly, load the core from its .so.
    if (!_retro_intf_load_core_from_file(corePath)) {
        printf("%s: could not load core '%s'\n", __func__, corePath);
        goto out;
    }

    // Secondly, load the game (aka ROM).
    if (!_retro_intf_load_game_from_file(gamePath)) {
        printf("%s: could not load game '%s'\n", __func__, gamePath);
        goto out;
    }

    gCore.initialized = true;
    printf("%s: core initialized, core:%s game:%s\n",
            __func__, corePath, gamePath);

    // Determine the video frame dimension.
    struct retro_system_av_info avInfo;
    gCore.retro_get_system_av_info(&avInfo);
    //gVideo.frameWidth = avInfo.geometry.base_width;
    //gVideo.frameHeight = avInfo.geometry.base_height;

    success = true;
out:
    if (!success) {
        retro_intf_deinit();
    }

    return success;
}

void
retro_intf_deinit(void)
{
    if (gCore.initialized) {
        gCore.retro_deinit();
    }

    if (gCore.handle) {
        int ret = dlclose(gCore.handle);
        if (ret != 0) {
            printf("%s: dlclose() failed, reason: %s\n",
                    __func__, dlerror());
        }
    }

    (void)memset(&gCore, 0, sizeof(gCore));
}

void
retro_intf_set_input_callback(void (*cb)(input_state_t *))
{
    gInputCallback = cb;
}
