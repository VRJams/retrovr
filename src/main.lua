print("BOOT")

ANDROID = lovr.system.getOS() == 'Android'
print("ANDROID " .. (ANDROID and 1 or 0))

retro = require('retro')
utils = require('utils')
display = require('display')
print(utils.dump(display))

-- TODO: remove this.
gDisplay = display.newDisplay(lovr.math.newVec3(1, 1, 1), lovr.math.newVec2(2, 2))


KEYBOARD_KEYPRESSED = {}
VIRTUAL_MOUSE_X = 0
VIRTUAL_MOUSE_Y = 0

function init_retro()


    local core_dir = lovr.filesystem.getSource() .. "/cores"
    if ANDROID then
        core_dir = "/data/data/retrovr.app"
    end

    print('core_dir: ' .. core_dir)
    
    print("ITEMS IN core_dir: ")
    for key, value in pairs(lovr.filesystem.getDirectoryItems(core_dir)) do
        print(value)
    end

    local core_path = core_dir .. '/pcsx_rearmed_libretro_x86.so'
    if ANDROID then
        core_path = core_dir .. '/pcsx_rearmed_libretro_android.so'
    end

    local game_dir = lovr.filesystem.getSource()
    if ANDROID then
        game_dir = lovr.filesystem.getSaveDirectory()
    end
    game_dir = game_dir .. "/games"
    print("game_dir: ".. game_dir)
    local game_path = game_dir .. '/Project - Horned Owl (USA).bin'
    local game_path = game_dir .. '/Point Blank (USA).bin'

    retro_success = retro.retro_intf_init(core_path, game_path)
    assert(retro_success)

    retro.retro_intf_set_input(0, retro.DEVICE_LIGHTGUN, 0)

    -- callback function called by the core to update the input_state internal variable, an array of unsigned ints
    retro.retro_intf_set_input_callback(function (input_state)
        if not ANDROID then
            input_state.values[retro.LIGHTGUN_TRIGGER] = KEYBOARD_KEYPRESSED['space'] or 0
            input_state.values[retro.LIGHTGUN_RELOAD] = KEYBOARD_KEYPRESSED['tab'] or 0
            input_state.values[retro.LIGHTGUN_SELECT] = KEYBOARD_KEYPRESSED['z'] or 0
            input_state.values[retro.LIGHTGUN_START] = KEYBOARD_KEYPRESSED['x'] or 0
            input_state.values[retro.LIGHTGUN_AUX_A] = KEYBOARD_KEYPRESSED['1'] or 0
            input_state.values[retro.LIGHTGUN_AUX_B] = KEYBOARD_KEYPRESSED['2'] or 0
            input_state.values[retro.LIGHTGUN_AUX_C] = KEYBOARD_KEYPRESSED['3'] or 0
        else
            input_state.values[retro.LIGHTGUN_TRIGGER] =
                lovr.headset.isDown('right', 'trigger') or 0
            input_state.values[retro.LIGHTGUN_RELOAD] =
                lovr.headset.isDown('left', 'trigger') or 0
            input_state.values[retro.LIGHTGUN_SELECT] =
                lovr.headset.isDown('left', 'thumbstick') or 0
            input_state.values[retro.LIGHTGUN_START] =
                lovr.headset.isDown('right', 'thumbstick') or 0
            input_state.values[retro.LIGHTGUN_AUX_A] =
                lovr.headset.isDown('right', 'a') or 0
            input_state.values[retro.LIGHTGUN_AUX_B] =
                lovr.headset.isDown('right', 'b') or 0
            input_state.values[retro.LIGHTGUN_AUX_C] =
                lovr.headset.isDown('left', 'x') or 0
        end
        input_state.values[retro.LIGHTGUN_SCREEN_X] = math.floor(VIRTUAL_MOUSE_X * 0x8000)
        input_state.values[retro.LIGHTGUN_SCREEN_Y] = math.floor(VIRTUAL_MOUSE_Y * 0x8000)
    end)
end

function lovr.load()
    -- initialize retro
    init_retro()

    -- create a backing sound buffer
    local sample_rate = tonumber(retro.retro_intf_get_audio_sample_rate())
    screen_bin = lovr.data.newBlob(2 * 64000, 'screen_snd')
    retro.retro_intf_set_audio_buffer(screen_bin:getPointer(), screen_bin:getSize() / 2)
    screen_snd = lovr.data.newSound(
        screen_bin:getSize() / 2, 'i16', 'stereo', sample_rate, 'stream')
    screen_src = lovr.audio.newSource(screen_snd)

    -- create a backing texture for the libretro core video frame
    local video_desc = retro.retro_intf_get_video_desc()
    print('video_desc: ')
    print('    curW='..video_desc.curFrameW)
    print('    curH='..video_desc.curFrameW)
    print('    maxW='..video_desc.maxFrameW)
    print('    maxH='..video_desc.maxFrameH)
    screen_img = lovr.data.newImage(
        video_desc.maxFrameW, video_desc.maxFrameH, "rgba", nil)
    retro.retro_intf_set_video_buffer(screen_img:getBlob():getPointer())
    -- create a material that will be used to retro-project the core video frame
    screen_tex = lovr.graphics.newTexture(screen_img)

    -- grid floor shader
    shader = lovr.graphics.newShader([[
        vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
            return projection * transform * vertex;
        }
    ]], [[
        const float gridSize = 25.;
        const float cellSize = .5;

        vec4 color(vec4 gcolor, sampler2D image, vec2 uv) {
            // Distance-based alpha (1. at the middle, 0. at edges)
            float alpha = 1. - smoothstep(.15, .50, distance(uv, vec2(.5)));
            // Grid coordinate
            uv *= gridSize;
            uv /= cellSize;
            vec2 c = abs(fract(uv - .5) - .5) / fwidth(uv);
            float line = clamp(1. - min(c.x, c.y), 0., 1.);
            vec3 value = mix(vec3(.01, .01, .011), (vec3(.04)), line);

            return vec4(vec3(value), alpha);
        }
    ]], { flags = { highp = true } })
end

local tips = {}

function lovr.update(dt)
    if not ANDROID then
        local multiplier = 0.01
        VIRTUAL_MOUSE_X = VIRTUAL_MOUSE_X + multiplier * (KEYBOARD_KEYPRESSED['l'] or 0) -
            multiplier * (KEYBOARD_KEYPRESSED["j"] or 0)
        VIRTUAL_MOUSE_Y = VIRTUAL_MOUSE_Y - multiplier * (KEYBOARD_KEYPRESSED["i"] or 0) +
            multiplier * (KEYBOARD_KEYPRESSED["k"] or 0)
    else    
        for i, hand in ipairs(lovr.headset.getHands()) do
            tips[hand] = tips[hand] or lovr.math.newVec3()

            local rayPosition = vec3(lovr.headset.getPosition(hand))
            local rayDirection = vec3(quat(lovr.headset.getOrientation(hand)):mul(quat(-math.pi / 2, 1, 0, 0)):direction())
            rayDirection = mat4():mul(rayDirection):normalize()
            --:rotate(-math.pi / 4, 1, 0, 0)

            local hit = gDisplay:intersect(rayPosition, rayDirection)
            if hit then
                VIRTUAL_MOUSE_X = hit.x
                VIRTUAL_MOUSE_Y = hit.y
            end

            tips[hand]:set(rayPosition + rayDirection * 50)
        end
    end

    retro.retro_intf_step()
    screen_tex:replacePixels(screen_img)

    -- sound: frames are interleaved {l, r} and contain 2 samples each; so when we drain
    -- the audio buffer we get the total number of samples that were written, hence why
    -- we divide by two.
    local num_samples = tonumber(retro.retro_intf_drain_audio_buffer())
    local num_frames = num_samples / 2
    screen_snd:setFrames(screen_bin, num_frames)
    screen_src:play()

    --gDisplay:update()
end

function lovr.draw()
    -- Plane for floor.
    lovr.graphics.setBackgroundColor(.05, .05, .05)
    lovr.graphics.setShader(shader)
    lovr.graphics.plane('fill', 0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0) 
    lovr.graphics.setShader()

    -- Plane for libretro framebuffer. Note that because libretro cores can dynamically
    -- adjust the video buffer dimension, we need to adjust our texture mapping. We don't
    -- have to re-create the texture though.
    local video_desc = retro.retro_intf_get_video_desc()
    local tex_w = video_desc.curFrameW / video_desc.maxFrameW
    local tex_h = video_desc.curFrameH / video_desc.maxFrameH
    gDisplay:draw(screen_tex, tex_w, tex_h)

    for hand, tip in pairs(tips) do
        local position = vec3(lovr.headset.getPosition(hand))
        -- draw hand position
        lovr.graphics.setColor(1, 1, 1)
        lovr.graphics.sphere(position, .01)
        -- draw hand direction
        lovr.graphics.line(position, position + 0.2 * tip:normalize())
        lovr.graphics.setColor(1, 1, 1)
    end

    utils.drawAxes()
end

function lovr.keypressed(key, scancode, w)
    KEYBOARD_KEYPRESSED[key] = 1
end

function lovr.keyreleased(key, scancode)
    KEYBOARD_KEYPRESSED[key] = 0
end
