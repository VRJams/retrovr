#include "log.h"
#include "retro_intf.h"

#include <assert.h>
#include <stdint.h>

/*
 * The interface supports a single instance of a core running so we are fine
 * keeping these global variables here.
 */

// The destination of libretro's video frame.
static void* gVideoBufferPtr = NULL;

static void
_generate_fake_video_frame(void)
{
    static int offset = 0;

    assert(gVideoBufferPtr);

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

retro_intf_ret_t
retro_intf_init(char const* corePath, char const* gamePath)
{
    assert(corePath);
    assert(gamePath);

    return kRetroIntfRetNoError;
}

void
retro_intf_run(void)
{
    // TODO(sgosselin): to be implemented.

    // TODO(sgosselin): remove this, right now the function will generate a
    // dummy texture that can be used to prove the pipeline is working. The
    // function should instead rely on the core video frame generation.
    if (gVideoBufferPtr) {
        _generate_fake_video_frame();
    }
}

void
retro_intf_set_video_buffer(void* buf)
{
    gVideoBufferPtr = buf;
    LOG("%s: changed video buffer destination, dst=%p\n", __func__, buf);
}

