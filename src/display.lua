local display = {}

display = {}
display.__index = display

function display.newdisplay(center, dimension, rotAng, rotVec)
    local obj = {}
    setmetatable(obj, display)

    obj.center = center
    obj.dimension = dimension
    obj.rotAng = rotAng
    obj.rotVec = rotVec
    obj.renderMaterial = lovr.graphics.newMaterial()

    -- TODO: calculate plane axes
    local m = lovr.math.newMat4():rotate(rotAng, rotVec.x, rotVec.y, rotVec.z)
    obj.vecRight = m:mul(lovr.math.newVec3(1, 0, 0))
    obj.vecUp = m:mul(lovr.math.newVec3(0, -1, 0))
    obj.vecNormal = obj.vecRight:cross(obj.vecUp):normalize()
    obj.vecRight = m:mul(lovr.math.newVec3(1, 0, 0))

    return obj
end

function display:intersect(rayPos, rayDir)
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

function display:draw(screenTex, screenTexCoordW, screenTexCoordH)
    lovr.graphics.setShader()

    self.renderMaterial:setTexture(screenTex)

    lovr.graphics.plane(self.renderMaterial,
        self.center.x, self.center.y, self.center.z,
        self.dimension.x, self.dimension.y,
        self.rotAng, self.rotVec.x, self.rotVec.y, self.rotVec.z,
        0, 0, screenTexCoordW, screenTexCoordH)

    lovr.graphics.setShader()
end

return display
