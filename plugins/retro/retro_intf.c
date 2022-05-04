#include "retro_intf.h"

#include <assert.h>
#include <dlfcn.h>
#include <errno.h>
#include <math.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "libretro.h"

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

// Description of the current video configuration.
static struct {
    // Set by client, filled by the core video refresh callback.
    uint8_t* dst;
    // Set by the core.
    enum retro_pixel_format format;
    struct retro_game_geometry geometry;
} gVideoDesc;

// Description of the audio configuration.
static struct {
    int16_t* dst;
    size_t dstLen;
    size_t dstInd;
    double sampleRate;
} gAudioDesc;

// Description of the input configuration.
static struct {
    input_state_t inputState;
    // Callback registered by the client.
    void (*cb)(input_state_t *);
} gInputDesc;

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

static void
_core_cb_audio_sample(int16_t left, int16_t right)
{
}

static size_t
_core_cb_audio_sample_batch(int16_t const* data, size_t frame)
{
    size_t ncopies = 0;

    for (size_t i = 0; i < frame; ++i) {
        if ((gAudioDesc.dstInd + 2) >= gAudioDesc.dstLen)
            break;
        gAudioDesc.dst[gAudioDesc.dstInd++] = *data++;
        gAudioDesc.dst[gAudioDesc.dstInd++] = *data++;
        ncopies++;
    }

    return ncopies;
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
            gVideoDesc.format = *((enum retro_pixel_format *) data);
            printf("%s: changing pixel format (fmt=%d)\n", __func__, gVideoDesc.format);
            break;
        case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
            *(const char **)data = ".";
            break;
        case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
            *(const char **)data = ".";
            break;
        case RETRO_ENVIRONMENT_SET_GEOMETRY:
            gVideoDesc.geometry = *(const struct retro_game_geometry *) data;
            break;
        default:
            return false;
    }

    return true;
}

static void
_core_cb_input_poll(void)
{
    if (gInputDesc.cb) {
        gInputDesc.cb(&gInputDesc.inputState);
    }
}

static int16_t
_core_cb_input_state(unsigned port, unsigned device, unsigned index,
        unsigned id)
{
    assert(id < RETRO_INTF_INPUT_SIZE);

    if (port != 0 || index != 0) {
        return 0;
    }

    return gInputDesc.inputState.values[id];
}

static void
_core_cb_video_refresh(void const* data, unsigned width, unsigned height,
        size_t pitch)
{
    if (!gVideoDesc.dst) {
        return;
    }

    // NOTE: the core can render a frame with a different size than what it specified
    // as (max_width, max_height). In theory, the (width, height) passed as arguments
    // should match with what the core configured with the _SET_GEOMETRY environment.
    assert(width == gVideoDesc.geometry.base_width);
    assert(height == gVideoDesc.geometry.base_height);

    /*
     * TODO: as of right now, clients specify an RGBA8888 buffer and we
     * copy/convert the newly produced frame into the client's provided
     * destination buffer. Instead, I am wondering if we can avoid these
     * copies by either mmap'ing an OpenGL texture, or by providing the
     * buffer to the core directly.
     */
    if (gVideoDesc.format == RETRO_PIXEL_FORMAT_RGB565) {
        uint16_t const* src = (uint16_t const*) data;
        const size_t dstPitch = gVideoDesc.geometry.max_width * 4;

        for (size_t y = 0; y < height; ++y) {
            for (size_t x = 0; x < width; ++x) {
                const uint8_t r = (255.f / 31.f) * ((src[y * width + x] & 0xf800) >> 11);
                const uint8_t g = (255.f / 63.f) * ((src[y * width + x] & 0x07e0) >> 5);
                const uint8_t b = (255.f / 31.f) * ((src[y * width + x] & 0x001f));

                gVideoDesc.dst[y * dstPitch + (x * 4) + 0] = r;
                gVideoDesc.dst[y * dstPitch + (x * 4) + 1] = g;
                gVideoDesc.dst[y * dstPitch + (x * 4) + 2] = b;
                gVideoDesc.dst[y * dstPitch + (x * 4) + 3] = 255;

            }
        }
    } else {
        // TODO: support other format.
    }
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

    // Determine the initial a/v configuration.
    struct retro_system_av_info avInfo = {0};
    gCore.retro_get_system_av_info(&avInfo);
    gVideoDesc.geometry = avInfo.geometry;
    gAudioDesc.sampleRate = avInfo.timing.sample_rate;

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

retro_intf_video_desc_t
retro_intf_get_video_desc(void)
{
    retro_intf_video_desc_t desc = {
        .curFrameW = gVideoDesc.geometry.base_width,
        .curFrameH = gVideoDesc.geometry.base_height,
        .maxFrameW = gVideoDesc.geometry.max_width,
        .maxFrameH = gVideoDesc.geometry.max_height,
    };

    return desc;
}

void
retro_intf_set_input(int port, int type, int id)
{
    if (port != 0) {
        printf("%s: ignored unsupported input port %d\n", __func__, port);
        return;
    }

    gCore.retro_set_controller_port_device(0, RETRO_DEVICE_SUBCLASS(type, id));
}

size_t
retro_intf_drain_audio_buffer(void)
{
    size_t nframes = gAudioDesc.dstInd;
    gAudioDesc.dstInd = 0;
    return nframes;
}

void
retro_intf_set_audio_buffer(int16_t* dst, size_t len)
{
    gAudioDesc.dst = dst;
    gAudioDesc.dstLen = len;
    printf("%s: set audio buffer dst=%p len=%zu\n", __func__, dst, len);
}

void
retro_intf_set_input_callback(void (*cb)(input_state_t *))
{
    gInputDesc.cb = cb;
}

void
retro_intf_set_video_buffer(uint8_t* dst)
{
    gVideoDesc.dst = dst;
    printf("%s: set video buffer dst=%p\n", __func__, dst);
}

void
retro_intf_step(void)
{
    if (!gCore.initialized)
        return;
    gCore.retro_run();
}

double
retro_intf_get_audio_sample_rate(void)
{
    return gAudioDesc.sampleRate;
}
