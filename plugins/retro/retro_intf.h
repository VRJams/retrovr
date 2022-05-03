#pragma once

#include <stdbool.h>

#define RETRO_INTF_INPUT_SIZE (20)

/// Represent the state of each input slot. It is defined as a
/// structure with a fixed array so it is easier to manipulate
/// with FFI.
typedef struct {
    unsigned values[RETRO_INTF_INPUT_SIZE];
} input_state_t;

/// Initialize libretro with paths to a core and game.
bool retro_intf_init(char const* corePath, char const* gamePath);

/// De-initialize libretro loaded core.
void retro_intf_deinit(void);

/// Register the callback for inputs polling.
void retro_intf_set_input_callback(void (*cb)(input_state_t *));
