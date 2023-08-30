local ffi = require('ffi')
local retro = nil
if ANDROID then
    retro = ffi.load("retro.so")
else
    -- on desktop lovr looks from the working dir for libraries, and i keep the compiled results in /results/OS/
    retro = ffi.load("results/linux_16/libretro.so")
end



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

    enum {
        DEVICE_NONE = 0,
        DEVICE_JOYPAD = 1,
        DEVICE_LIGHTGUN = 4,
    };


    /* defined in retro_intf.h */

    static const int INPUT_STATE_SIZE = 20;

    typedef struct {
        unsigned values[INPUT_STATE_SIZE];
    } input_state_t;

    typedef struct {
        unsigned curFrameW;
        unsigned curFrameH;
        unsigned maxFrameW;
        unsigned maxFrameH;
    } retro_intf_video_desc_t;

    bool retro_intf_init(char const*, char const*);
    void retro_intf_deinit(void);
    size_t retro_intf_drain_audio_buffer(void);
    double retro_intf_get_audio_sample_rate(void);
    retro_intf_video_desc_t retro_intf_get_video_desc(void);
    void retro_intf_set_input(int port, int type, int id);
    void retro_intf_set_input_callback(void (*cb)(input_state_t *));
    void retro_intf_set_audio_buffer(int16_t* dst, size_t len);
    void retro_intf_set_video_buffer(uint8_t* dst);
    void retro_intf_step(void);
]]

return retro
