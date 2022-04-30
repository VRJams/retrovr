lovr.retro = require 'lua-libretro'

-- generate a string representation of a lua table
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function lovr.load()
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

  lovr.graphics.setBackgroundColor(.05, .05, .05)

  -- create an image to be the backing store of libretro video buffer.
  videoImg = lovr.data.newImage(320, 240, "rgba", nil)
  for y = 0, videoImg:getHeight() - 1, 1
  do
    for x = 0, videoImg:getWidth() - 1, 1
    do
      videoImg:setPixel(x, y, 0, 0, 0)
    end
  end

  -- libretro: init the core, game and set the audio/video buffers.
  wdir = '/data/data/org.lovr.app'
  corePath = wdir .. "/pcsx_rearmed_libretro_android.so"
  gamePath = wdir .. "/PointBlank.bin"
  lovr.retro:init(corePath, gamePath)
  lovr.retro:set_video_buffer(videoImg:getBlob():getPointer())
  lovr.retro:run_once()

  -- configure the texture and material used to render the plane
  tex = lovr.graphics.newTexture(videoImg)
  mat = lovr.graphics.newMaterial(tex)
end

function lovr.draw()
  lovr.graphics.setShader(shader)
  lovr.graphics.plane('fill', 0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0)
  lovr.graphics.setShader()

  -- libretro: run the core and update the screen texture.
  lovr.retro:run_once()
  tex:replacePixels(videoImg)

  -- screen plane where libretro will be retroprojected
  lovr.graphics.plane(mat, 0, 1, -4, 3, 2, math.pi, 1, 0, 0)
end
