retro = require('retro')

-- TODO: dynamically select between keyboard and controller based on the OS
USE_KEYBOARD = true
KEYBOARD_KEYPRESSED = {}

function init_retro()
    local main_dir = '.'
    local core_path = main_dir .. '/pcsx_rearmed_libretro.so'
    local game_path = main_dir .. '/Point Blank.bin'

    retro_success = retro.retro_intf_init(core_path, game_path)
    assert(retro_success)

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
end

function lovr.draw()
    lovr.graphics.setBackgroundColor(.05, .05, .05)
    lovr.graphics.setShader(shader)
    lovr.graphics.plane('fill', 0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0)
    lovr.graphics.setShader()
end

function lovr.keypressed(key, scancode, w)
    KEYBOARD_KEYPRESSED[key] = 1
end

function lovr.keyreleased(key, scancode)
    KEYBOARD_KEYPRESSED[key] = 0
end
