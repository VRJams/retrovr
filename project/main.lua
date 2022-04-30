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

  -- we will create a new image that is a backing store.
  img = lovr.data.newImage(640, 478, "rgba", nil)
  for y = 0, img:getHeight()-1, 1
  do
    for x = 0, img:getWidth()-1, 1
    do
      img:setPixel(x, y, (x / 640.0), 0, 0)
    end
  end

  -- libretro init
  lovr.retro:init()
  lovr.retro:set_video_buffer(img:getBlob():getPointer())
  lovr.retro:run_once()

  tex = lovr.graphics.newTexture(img)
  mat = lovr.graphics.newMaterial(tex)

  for y = 0, img:getHeight()-1, 1
  do
    for x = 0, img:getWidth()-1, 1
    do
      img:setPixel(x, y, 0, (x / 640.0), 0)
    end
  end
  tex:replacePixels(img)
end

function lovr.draw()
  lovr.graphics.setShader(shader)
  lovr.graphics.plane('fill', 0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0)
  lovr.graphics.setShader()

  -- screen plane where libretro will be retroprojected
  lovr.graphics.plane(mat, 0, 1, -4, 3, 2, 0, 0, 0, 0)
  -- TODO: apply the video buffer
end
