retro = require('retro')

-- TODO: dynamically select between keyboard and controller based on the OS
USE_KEYBOARD = lovr.system.getOS() ~= 'Android'
KEYBOARD_KEYPRESSED = {}
VIRTUAL_MOUSE_X = 0
VIRTUAL_MOUSE_X_NORM = 0
VIRTUAL_MOUSE_Y = 0
VIRTUAL_MOUSE_Y_NORM = 0

function raycast(rayPos, rayDir, planePos, planeDir)
  local dot = rayDir:dot(planeDir)
  if math.abs(dot) < .001 then
    return nil
  else
    local distance = (planePos - rayPos):dot(planeDir) / dot
    if distance > 0 then
      return rayPos + rayDir * distance
    else
      return nil
    end
  end
end

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

    retro.retro_intf_set_controller(0, retro.DEVICE_LIGHTGUN, 0)

    retro.retro_intf_set_input_callback(function (input_state)
        if USE_KEYBOARD then
            input_state.values[retro.LIGHTGUN_TRIGGER] =
                    KEYBOARD_KEYPRESSED['space'] or 0
            input_state.values[retro.LIGHTGUN_RELOAD] =
                    KEYBOARD_KEYPRESSED['tab'] or 0
            input_state.values[retro.LIGHTGUN_SELECT] =
                    KEYBOARD_KEYPRESSED['z'] or 0
            input_state.values[retro.LIGHTGUN_START] =
                    KEYBOARD_KEYPRESSED['x'] or 0
            input_state.values[retro.LIGHTGUN_AUX_A] =
                    KEYBOARD_KEYPRESSED['1'] or 0
            input_state.values[retro.LIGHTGUN_AUX_B] =
                    KEYBOARD_KEYPRESSED['2'] or 0
            input_state.values[retro.LIGHTGUN_AUX_C] =
                    KEYBOARD_KEYPRESSED['3'] or 0
            -- TODO: this is not so simple, we must adjust the coordinate into screen space.
            input_state.values[retro.LIGHTGUN_SCREEN_X] =
                 0x8000 * (2 * VIRTUAL_MOUSE_X_NORM - 1);
            input_state.values[retro.LIGHTGUN_SCREEN_Y] =
                 0x8000 * (2 * VIRTUAL_MOUSE_Y_NORM - 1);
        else
            input_state.values[retro.LIGHTGUN_TRIGGER] = lovr.headset.isDown(
                    'right', 'trigger') or 0
            input_state.values[retro.LIGHTGUN_RELOAD] = lovr.headset.isDown(
                    'left', 'trigger') or 0
            input_state.values[retro.LIGHTGUN_SELECT] = lovr.headset.isDown(
                    'left', 'thumbstick') or 0
            input_state.values[retro.LIGHTGUN_START] = lovr.headset.isDown(
                    'right', 'thumbstick') or 0
            input_state.values[retro.LIGHTGUN_AUX_A] = lovr.headset.isDown(
                    'right', 'a') or 0
            input_state.values[retro.LIGHTGUN_AUX_B] = lovr.headset.isDown(
                    'right', 'b') or 0
            input_state.values[retro.LIGHTGUN_AUX_C] = lovr.headset.isDown(
                    'left', 'x') or 0
        end
    end)
end

function lovr.load()
    -- initialize retro
    init_retro()

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
    screen_mat = lovr.graphics.newMaterial(screen_tex)

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

function lovr.update(dt)
    retro.retro_intf_step()
    screen_tex:replacePixels(screen_img)
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
    lovr.graphics.plane(screen_mat,
        0, 1, -4,                                       -- position
        3, 2,                                           -- dimension
        math.pi, 1, 0, 0,                               -- rotation
        0, 0, tex_w, tex_h)                             -- texture
end

function lovr.keypressed(key, scancode, w)
    if USE_KEYBOARD then
        KEYBOARD_KEYPRESSED[key] = 1

        -- virtual mouse
        if key == 'i' then
            VIRTUAL_MOUSE_Y = VIRTUAL_MOUSE_Y - 5;
        elseif key == 'k' then
            VIRTUAL_MOUSE_Y = VIRTUAL_MOUSE_Y + 5;
        elseif key == 'j' then
            VIRTUAL_MOUSE_X = VIRTUAL_MOUSE_X - 5;
        elseif key == 'l' then
            VIRTUAL_MOUSE_X = VIRTUAL_MOUSE_X + 5;
        end
        -- TODO: technically, we could work with only normalized mouse position.
        local video_desc = retro.retro_intf_get_video_desc()
        VIRTUAL_MOUSE_X = VIRTUAL_MOUSE_X % video_desc.curFrameW
        VIRTUAL_MOUSE_X_NORM = VIRTUAL_MOUSE_X / video_desc.curFrameW
        VIRTUAL_MOUSE_X = VIRTUAL_MOUSE_X % video_desc.curFrameH
        VIRTUAL_MOUSE_Y_NORM = VIRTUAL_MOUSE_Y / video_desc.curFrameH
    end
end

function lovr.keyreleased(key, scancode)
    if USE_KEYBOARD then
        KEYBOARD_KEYPRESSED[key] = 0
    end
end
