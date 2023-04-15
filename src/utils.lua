local utils = {}

function utils.clamp(val, lower, upper)
    if lower > upper then
        lower, upper = upper, lower
    end

    return math.max(lower, math.min(upper, val))
end

function utils.dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. utils.dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

---Compute worldspace coords of line-plane intersect
---@param rayPos lovr.Vec3 ray origin
---@param rayDir lovr.Vec3 ray direction
---@param planePos lovr.Vec3 plane center
---@param planeDir lovr.Vec3 plane normal
---@return lovr.Vec3|nil worldposition position or nil
function utils.raycast(rayPos, rayDir, planePos, planeDir)
  
  local dot = rayDir:dot(planeDir)
  -- if ray fully parallel to plane
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

function utils.drawAxes()
  lovr.graphics.setColor(1, 0, 0)
  lovr.graphics.line(0, 0, 0, 1, 0, 0)
  lovr.graphics.setColor(0, 1, 0)
  lovr.graphics.line(0, 0, 0, 0, 1, 0)
  lovr.graphics.setColor(0, 0, 1)
  lovr.graphics.line(0, 0, 0, 0, 0, 1)
  lovr.graphics.setColor(1, 1, 1)
end

function utils.print_paths()
  ANDROID = lovr.system.getOS() == 'Android'
  print("ANDROID " .. (ANDROID and 1 or 0))

  print("EXEC PATH " .. lovr.filesystem.getExecutablePath())
  print("WORK DIR " .. lovr.filesystem.getWorkingDirectory())
  print("APPDATA DIR " .. lovr.filesystem.getAppdataDirectory())
  print("SAVE DIR " .. lovr.filesystem.getSaveDirectory())
  print("SOURCE DIR " .. lovr.filesystem.getSource())
  if not ANDROID then
    -- not valid on Android
    print("USER DIR " .. lovr.filesystem.getUserDirectory())
  end
end

return utils
