-- Leon X | FullBright
-- Maximizes Lighting brightness and removes shadows/fog

local FullBright = {}
FullBright.Name    = "FullBright"
FullBright.Enabled = false

local Lighting = game:GetService("Lighting")

-- save original values on first load
local orig = {
    Brightness    = Lighting.Brightness,
    ClockTime     = Lighting.ClockTime,
    FogEnd        = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient       = Lighting.Ambient,
}

function FullBright:Enable()
    self.Enabled           = true
    Lighting.Brightness    = 2
    Lighting.ClockTime     = 14
    Lighting.FogEnd        = 100000
    Lighting.GlobalShadows = false
    Lighting.Ambient       = Color3.fromRGB(178,178,178)
end

function FullBright:Disable()
    self.Enabled           = false
    Lighting.Brightness    = orig.Brightness
    Lighting.ClockTime     = orig.ClockTime
    Lighting.FogEnd        = orig.FogEnd
    Lighting.GlobalShadows = orig.GlobalShadows
    Lighting.Ambient       = orig.Ambient
end

function FullBright:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return FullBright
