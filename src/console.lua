-- entity / console
--

local console = {}

Console = {}
Console.__index = Console

-- mapping for console kind to asset path
local CONSOLE_ASSETS = {
    -- Playstation (PSX)
    psx = {
        model = 'assets/MODEL/PLAYSTATION.gltf',
        texAlbedo = 'assets/TEXTURE/PLAYSTATION_URP_AlbedoTransparency.png',
        texEmissive = 'assets/TEXTURE/PLAYSTATION_URP_Emission.png',
        texNormal = 'assets/TEXTURE/PLAYSTATION_URP_Normal.png',
        texMetalness = 'assets/TEXTURE/PLAYSTATION_URP_MetallicSmoothness.png',
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
    obj.renderTexEmissive = lovr.graphics.newTexture(assets['texEmissive'])
    obj.renderTexNormal = lovr.graphics.newTexture(assets['texNormal'])
    obj.renderTexMetalness = lovr.graphics.newTexture(assets['texMetalness'])

    -- TODO: find out how to apply rectangular area lights; modify the engine?
    obj.renderShader = lovr.graphics.newShader('standard', {
        flags = { normalMap=true, emissive=true, }
    })

    local m = obj.renderModel:getMaterial(1)
    m:setColor('emissive', 0, 0.5, 0, 1)
    m:setTexture('diffuse', obj.renderTexAlbedo)
    m:setTexture('emissive', obj.renderTexEmissive)
    m:setTexture('normal', obj.renderTexNormal)
    m:setTexture('metalness', obj.renderTexMetalness)

    return obj
end

function Console:draw()
    lovr.graphics.setShader(self.renderShader)
    self.renderShader:send('lovrLightDirection', { -1, -1, 1 })
    self.renderShader:send('lovrLightColor', { 1, 1, 1, 1 })
    self.renderModel:draw(self.position)
    lovr.graphics.setShader()
end

return console
