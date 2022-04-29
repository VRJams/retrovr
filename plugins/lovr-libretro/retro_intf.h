/// Easier to use API for libretro, to be used by lua-libretro.
///
/// NOTE:
/// This interface must be used by a single thread and only support 1 core
/// running at a time.
#pragma once

typedef enum {
    kRetroIntfRetNoError = 0,
    kRetroIntfRetCoreNotFound,
    kRetroIntfRetGameNotFound,
    kRetroIntfRetCoreNotRunning,
} retro_intf_ret_t;

/// Initialize libretro with a core and a game.
retro_intf_ret_t retro_intf_init(char const* corePath, char const* gamePath);

/// Run the libretro core once.
void retro_intf_run(void);

/// Set the destination of the video buffer; i.e., where libretro must write
/// the resulting video output.
///
/// The caller is responsible for the lifetime of the provided buffer. This
/// function can be called with NULL to ensure libretro does not use the buffer
/// anymore.
void retro_intf_set_video_buffer(void* buf);
