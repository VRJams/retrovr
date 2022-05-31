local display = {}

Display = {}
Display.__index = Display

function display.newDisplay(center, dimension)
    local obj = {}
    setmetatable(obj, Display)

    obj.center = center
    obj.dimension = dimension
    obj.distanceFromViewer = 3
    obj.orientation = lovr.math.newQuat()
    obj.renderMaterial = lovr.graphics.newMaterial()

    -- TODO: must be calculated.
    obj.vecUp = lovr.math.newVec3(0, 1, 0)

    return obj
end

function Display:intersect(rayPos, rayDir)
    local hit = utils.raycast(rayPos, rayDir, self.center, self.vecUp)
    if not hit then
        return nil
    end

    local bx, by, bw, bh = 0, 1, 3/2, 2/2
    local inside = (hit.x > bx - bw)
        and (hit.x < bx + bw)
        and (hit.y > by - bh)
        and (hit.y < by + bh)
    if not inside then
        return nil
    end

    return lovr.math.newVec2((hit.x - bx / bw), -(hit.y - by) / bh)
end

function Display:draw(screenTex, screenTexCoordW, screenTexCoordH)
    lovr.graphics.setShader()
    self.renderMaterial:setTexture(screenTex)

    angle, ax, ay, az = self.orientation:unpack()

    lovr.graphics.plane(self.renderMaterial,
        self.center.x, self.center.y, self.center.z,
        self.dimension.x, self.dimension.y,
        angle, ax, ay, az,
        0, 0, screenTexCoordW, screenTexCoordH)
    lovr.graphics.setShader()
end

function Display:update(dt)
    local headPos = vec3(lovr.headset.getPosition('head'))
    local headDir = vec3(quat(lovr.headset.getOrientation('head')):direction()):normalize()
    local targetPos = headPos + headDir * self.distanceFromViewer

    self.center:set(targetPos:lerp(self.center, 0.995))
    self.orientation:set(lovr.headset.getOrientation('head'))
end

return display
