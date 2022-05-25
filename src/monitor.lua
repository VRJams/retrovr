local monitor = {}

Monitor = {}
Monitor.__index = Monitor

function monitor.newMonitor(center, dimension, rotAng, rotVec)
    local obj = {}
    setmetatable(obj, Monitor)

    obj.center = center
    obj.dimension = dimension
    obj.rotAng = rotAng
    obj.rotVec = rotVec
    obj.renderMaterial = lovr.graphics.newMaterial()

    -- TODO: calculate plane axes
    obj.vecNormal = lovr.math.newVec3(0, 0, 1)
    obj.vecRight = lovr.math.newVec3(1, 0, 0)
    obj.vecUp = lovr.math.newVec3(0, 1, 0)

    return obj
end

function Monitor:intersect(rayPos, rayDir)
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

function Monitor:draw(screenTex, screenTexCoordW, screenTexCoordH)
    lovr.graphics.setShader()

    self.renderMaterial:setTexture(screenTex)

    lovr.graphics.plane(self.renderMaterial,
        self.center.x, self.center.y, self.center.z,
        self.dimension.x, self.dimension.y,
        self.rotAng, self.rotVec.x, self.rotVec.y, self.rotVec.z,
        0, 0, screenTexCoordW, screenTexCoordH)

    lovr.graphics.setShader()
end

return monitor
