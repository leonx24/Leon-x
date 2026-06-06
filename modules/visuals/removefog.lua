-- Leon X | Remove Fog
-- Removes atmospheric fog and sky haze from Lighting

local RemoveFog = {}
RemoveFog.Name    = "RemoveFog"
RemoveFog.Enabled = false

local Lighting = game:GetService("Lighting")

-- save originals on first load
local orig = {
    FogStart = Lighting.FogStart,
    FogEnd   = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
}

-- also handle Atmosphere instance if present
local function getAtmosphere()
    return Lighting:FindFirstChildOfClass("Atmosphere")
end

local origAtmo = {}
local function saveAtmosphere()
    local atmo = getAtmosphere()
    if atmo then
        origAtmo.Density    = atmo.Density
        origAtmo.Offset     = atmo.Offset
        origAtmo.Haze       = atmo.Haze
        origAtmo.Glare      = atmo.Glare
    end
end
saveAtmosphere()

function RemoveFog:Enable()
    self.Enabled = true

    -- push fog far away
    Lighting.FogStart = 100000
    Lighting.FogEnd   = 100000

    -- flatten Atmosphere if present
    local atmo = getAtmosphere()
    if atmo then
        atmo.Density = 0
        atmo.Offset  = 0
        atmo.Haze    = 0
        atmo.Glare   = 0
    end
end

function RemoveFog:Disable()
    self.Enabled = false

    Lighting.FogStart = orig.FogStart
    Lighting.FogEnd   = orig.FogEnd
    Lighting.FogColor = orig.FogColor

    local atmo = getAtmosphere()
    if atmo and next(origAtmo) then
        atmo.Density = origAtmo.Density
        atmo.Offset  = origAtmo.Offset
        atmo.Haze    = origAtmo.Haze
        atmo.Glare   = origAtmo.Glare
    end
end

function RemoveFog:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return RemoveFog
