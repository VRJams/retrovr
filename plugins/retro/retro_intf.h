#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#define RETRO_INTF_INPUT_SIZE (20)

/// Represent the state of each input slot. It is defined as a
/// structure with a fixed array so it is easier to manipulate
/// with FFI.
typedef struct {
    unsigned values[RETRO_INTF_INPUT_SIZE];
} input_state_t;

typedef struct {
    unsigned curFrameW;
    unsigned curFrameH;
    unsigned maxFrameW;
    unsigned maxFrameH;
} retro_intf_video_desc_t;

/// Initialize libretro with paths to a core and game.
///
/// @param corePath
/// Path to a libretro core to be loaded.
///
/// @param gamePath
/// Path to a ROM file to be loaded.
///
/// @return
/// True on success, false on failure.
///
bool retro_intf_init(char const* corePath, char const* gamePath);

/// De-initialize libretro loaded core.
void retro_intf_deinit(void);

/// Drain the audio buffer that is currently set.
///
/// @return
/// Number of samples that were written into the audio buffer; note it is NOT the number
/// of frames.
size_t retro_intf_drain_audio_buffer(void);

/// Get the audio sample rate.
double retro_intf_get_audio_sample_rate(void);

/// Get the current video configuration.
retro_intf_video_desc_t retro_intf_get_video_desc(void);

/// Set the controller mapping.
///
/// @param port
/// The input slot; note that only 0 is supported right now and other ports are ignored.
void retro_intf_set_input(int port, int type, int id);

/// Set the audio buffer.
///
/// @param dst
/// Buffer of int16_t of length |len|.
///
/// @param len
/// Length of |buf|.
void retro_intf_set_audio_buffer(void* dst, size_t len);

/// Set the video buffer.
///
/// @param dst
/// RGBA8 buffer, must be able to store a frame of max_width/max_height as obtained by
/// retro_intf_get_video_desc().
void retro_intf_set_video_buffer(void* dst);

/// Set the callback for inputs polling.
///
/// NOTE:
/// The callback is triggered during call to retro_intf_step().
void retro_intf_set_input_callback(void (*cb)(input_state_t *));

/// Step the core once.
void retro_intf_step(void);
