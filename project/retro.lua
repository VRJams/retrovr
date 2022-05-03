local ffi = require('ffi')
local retro = ffi.load('retro.so')

-- definition of the interface for retro_intf
ffi.cdef[[
    /* defined in libretro.h */
    enum {
        LIGHTGUN_SCREEN_X   = 13,
        LIGHTGUN_SCREEN_Y   = 14,
        LIGHTGUN_AUX_A      = 3,
        LIGHTGUN_AUX_B      = 4,
        LIGHTGUN_AUX_C      = 8,
        LIGHTGUN_START      = 6,
        LIGHTGUN_SELECT     = 7,
        LIGHTGUN_TRIGGER    = 2,
        LIGHTGUN_RELOAD     = 16,
    };

    /* defined in retro_intf.h */
    static const int INPUT_STATE_SIZE = 20;

    /* defined in retro_intf.h */
    typedef struct {
        unsigned values[INPUT_STATE_SIZE];
    } input_state_t;

    /* defined in retro_intf.h */
    bool retro_intf_init(char const*, char const*);
    void retro_intf_set_input_callback(void (*cb)(input_state_t *));
    void retro_intf_step(void);
]]

return retro
