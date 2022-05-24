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

    -- TODO: Use a ShaderBuilder.
    obj.renderShader = lovr.graphics.newShader('unlit', {
        flags = {}
    })

    return obj
end

function Console:draw()
    lovr.graphics.setShader(self.renderShader)
    self.renderShader:send('lovrDiffuseTexture', self.renderTexAlbedo)
    self.renderShader:send('lovrLightDirection', { 1, 0, -1 })
    self.renderShader:send('lovrLightColor', { 1, 1, 1, 1 })
    self.renderShader:send('lovrDiffuseColor', { 1, 1, 1, 1 })
    self.renderModel:draw(self.position)
    lovr.graphics.setShader()
end

return console
