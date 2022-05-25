console = require('console')
monitor = require('monitor')
retro = require('retro')
utils = require('utils')

-- TODO: remove this.
gConsole = console.newConsole('psx', lovr.math.newVec3(0, 1, 0))
gMonitor = monitor.newMonitor(lovr.math.newVec3(0, 1, -4),
    lovr.math.newVec2(3, 2), math.pi, lovr.math.newVec3(1, 0, 0))

-- TODO: dynamically select between keyboard and controller based on the OS
USE_KEYBOARD = lovr.system.getOS() ~= 'Android'
KEYBOARD_KEYPRESSED = {}
VIRTUAL_MOUSE_X = 0
VIRTUAL_MOUSE_Y = 0

function init_retro()
    local main_dir = lovr.filesystem.getWorkingDirectory()
    if lovr.system.getOS() == 'Android' then
        main_dir =  '/data/data/org.lovr.app'
    end
    print('main_dir: ' .. main_dir)

    local core_path = main_dir .. '/pcsx_rearmed_libretro.so'
    local game_path = main_dir .. '/Point Blank.bin'

    retro_success = retro.retro_intf_init(core_path, game_path)
    assert(retro_success)

    retro.retro_intf_set_input(0, retro.DEVICE_LIGHTGUN, 0)

    retro.retro_intf_set_input_callback(function (input_state)
        if USE_KEYBOARD then
            input_state.values[retro.LIGHTGUN_TRIGGER] = KEYBOARD_KEYPRESSED['space'] or 0
            input_state.values[retro.LIGHTGUN_RELOAD] = KEYBOARD_KEYPRESSED['tab'] or 0
            input_state.values[retro.LIGHTGUN_SELECT] = KEYBOARD_KEYPRESSED['z'] or 0
            input_state.values[retro.LIGHTGUN_START] = KEYBOARD_KEYPRESSED['x'] or 0
            input_state.values[retro.LIGHTGUN_AUX_A] = KEYBOARD_KEYPRESSED['1'] or 0
            input_state.values[retro.LIGHTGUN_AUX_B] = KEYBOARD_KEYPRESSED['2'] or 0
            input_state.values[retro.LIGHTGUN_AUX_C] = KEYBOARD_KEYPRESSED['3'] or 0
        else
            input_state.values[retro.LIGHTGUN_TRIGGER] = lovr.headset.isDown('right', 'trigger') or 0
            input_state.values[retro.LIGHTGUN_RELOAD] = lovr.headset.isDown('left', 'trigger') or 0
            input_state.values[retro.LIGHTGUN_SELECT] = lovr.headset.isDown('left', 'thumbstick') or 0
            input_state.values[retro.LIGHTGUN_START] = lovr.headset.isDown('right', 'thumbstick') or 0
            input_state.values[retro.LIGHTGUN_AUX_A] = lovr.headset.isDown('right', 'a') or 0
            input_state.values[retro.LIGHTGUN_AUX_B] = lovr.headset.isDown('right', 'b') or 0
            input_state.values[retro.LIGHTGUN_AUX_C] = lovr.headset.isDown('left', 'x') or 0
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
    for i, hand in ipairs(lovr.headset.getHands()) do
        tips[hand] = tips[hand] or lovr.math.newVec3()

        local rayPosition = vec3(lovr.headset.getPosition(hand))
        local rayDirection = vec3(quat(lovr.headset.getOrientation(hand)):direction())
        rayDirection = mat4():rotate(-math.pi/4, 1, 0, 0):mul(rayDirection)

        local hit = gMonitor:intersect(rayPosition, rayDirection)
        if hit then
            VIRTUAL_MOUSE_X = hit.x
            VIRTUAL_MOUSE_Y = hit.y
        end

        tips[hand]:set(rayPosition + rayDirection * 50)
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
    gMonitor:draw(screen_tex, tex_w, tex_h)

    for hand, tip in pairs(tips) do
        local position = vec3(lovr.headset.getPosition(hand))
        -- draw hand position
        lovr.graphics.setColor(1, 1, 1)
        lovr.graphics.sphere(position, .01)
        -- draw hand direction
        lovr.graphics.line(position, position + 0.2 * tip:normalize())
        lovr.graphics.setColor(1, 1, 1)
    end

    gConsole:draw()
end

function lovr.keypressed(key, scancode, w)
    if USE_KEYBOARD then
        KEYBOARD_KEYPRESSED[key] = 1

        -- virtual mouse
        if key == 'i' then
            VIRTUAL_MOUSE_Y = VIRTUAL_MOUSE_Y - 0.1;
        elseif key == 'k' then
            VIRTUAL_MOUSE_Y = VIRTUAL_MOUSE_Y + 0.1;
        elseif key == 'j' then
            VIRTUAL_MOUSE_X = VIRTUAL_MOUSE_X - 0.1;
        elseif key == 'l' then
            VIRTUAL_MOUSE_X = VIRTUAL_MOUSE_X + 0.1;
        end
        VIRTUAL_MOUSE_X = utils.clamp(VIRTUAL_MOUSE_X, -1.0, 1.0)
        VIRTUAL_MOUSE_Y = utils.clamp(VIRTUAL_MOUSE_Y, -1.0, 1.0)
    end
end

function lovr.keyreleased(key, scancode)
    if USE_KEYBOARD then
        KEYBOARD_KEYPRESSED[key] = 0
    end
end
