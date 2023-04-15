local display = {}

Display = {}
Display.__index = Display

function display.newDisplay(center, dimension)
    local obj = {}
    setmetatable(obj, Display)

    obj.center = center
    obj.dimension = dimension
    obj.distanceFromViewer = 3
    -- define screen normal and flip to correct upside down image
    obj.orientation = lovr.math.newQuat(vec3(0, 0, 1)):mul(quat(math.pi, 1, 0, 0))
    obj.renderMaterial = lovr.graphics.newMaterial()

    -- TODO: must be calculated.
    obj.vecUp = lovr.math.newVec3(0, 1, 0)

    return obj
end

function Display:intersect(rayPos, rayDir)
    -- get worldpsace collision between ray and screen plane
    local hit = utils.raycast(rayPos, rayDir, self.center, self.orientation:direction())
    if not hit then -- if nil then no real intersection
        return nil
    end

    -- compute the screen space X and Y versors
    local screen_x = vec3(0, 1, 0):cross(gDisplay.orientation:direction()):normalize()
    local screen_y = gDisplay.orientation:direction():cross(screen_x):normalize()

    -- normalize for screen position
    local repositioned_hit = hit - gDisplay.center
    -- convert to screen space position
    local screen_hit = vec2(repositioned_hit:dot(screen_x), repositioned_hit:dot(screen_y))
    -- screen hit is relative tp the screen center, in meters and corrected for rotation of the screen ( NOT ROLL )
    
    -- corrected for the screen size to a (-1, 1) scale
    local relative_hit = screen_hit:div(self.dimension/2)
    -- clamp inputs as they wrap if left free 
    relative_hit = vec2(utils.clamp(relative_hit.x, -1, 1), utils.clamp(-relative_hit.y, -1, 1))

    return relative_hit
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

---Udate position based on user head
function Display:update()
    local headPos = vec3(lovr.headset.getPosition('head'))
    local headDir = vec3(quat(lovr.headset.getOrientation('head')):direction()):normalize()
    local targetPos = headPos + headDir * self.distanceFromViewer

    self.center:set(targetPos:lerp(self.center, 0.995))
    self.orientation:set(lovr.headset.getOrientation('head'))
end

return display
