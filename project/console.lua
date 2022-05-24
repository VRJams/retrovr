-- entity / console
--

local console = {}

Console = {}
Console.__index = Console

-- mapping for console kind to asset path
local CONSOLE_ASSETS = {
    -- Playstation (PSX)
    psx = {
        model = 'assets/PLAYSTATION.gltf',
        texAlbedo = 'assets/PLAYSTATION_URP_AlbedoTransparency.png',
        texNormal = 'assets/PLAYSTATION_URP_Normal.png',
        texEmission = 'assets/PLAYSTATION_URP_Emission.png',
    },
    -- Nintendo Wii
    wii = {
        model = 'assets/WII.gltf',
        texAlbedo = 'assets/WII_URP_AlbedoTransparency.png',
        texNormal = 'assets/WII_URP_Normal.png',
        texEmission = 'assets/WII_URP_Emission.png',
    },
}

-- Creates a new Console.
function console.newConsole(kind, position)
    if not CONSOLE_ASSETS[kind] then
        error('unsupported console type: ' .. kind)
    end

    local obj = {}
    setmetatable(obj, Console)

    local assets = CONSOLE_ASSETS[kind]
    obj.kind = kind
    obj.position = position
    obj.renderModel = lovr.graphics.newModel(assets['model'])
    obj.renderTexAlbedo = lovr.graphics.newTexture(assets['texAlbedo'])
    obj.renderTexNormal = lovr.graphics.newTexture(assets['texNormal'])
    obj.renderTexEmission = lovr.graphics.newTexture(assets['texEmission'])

    -- TODO: Use a ShaderBuilder.
    obj.renderShader = lovr.graphics.newShader('standard', {
        flags = { normalMap = true, emissive=true }
    })

    return obj
end

function Console:draw()
    lovr.graphics.setShader(self.renderShader)
    self.renderShader:send('lovrDiffuseTexture', self.renderTexAlbedo)
    self.renderShader:send('lovrNormalTexture', self.renderTexNormal)
    self.renderShader:send('lovrLightDirection', { 1, 0, -1 })
    self.renderShader:send('lovrLightColor', { 1, 1, 1, 1 })
    self.renderShader:send('lovrDiffuseColor', { 1, 1, 1, 1 })
    self.renderModel:draw(self.position)
    lovr.graphics.setShader()
end

return console
