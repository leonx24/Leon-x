-- Leon X | FullBright
-- Maximizes Lighting brightness and removes shadows/fog
-- Continuous enforcement: resists game scripts overriding lighting (day/night, weather, etc.)

local FullBright = {}
FullBright.Name    = "FullBright"
FullBright.Enabled = false

local Lighting    = game:GetService("Lighting")
local RunService  = game:GetService("RunService")

local enforceConn = nil

-- save original values on first load
local orig = {
    Brightness    = Lighting.Brightness,
    ClockTime     = Lighting.ClockTime,
    FogEnd        = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient       = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

-- Target values for FullBright
local TARGET = {
    Brightness     = 2,
    ClockTime      = 14,
    FogEnd         = 100000,
    GlobalShadows  = false,
    Ambient        = Color3.fromRGB(178, 178, 178),
    OutdoorAmbient = Color3.fromRGB(178, 178, 178),
}

local function applyFullBright()
    pcall(function()
        for key, val in pairs(TARGET) do
            if Lighting[key] ~= val then
                Lighting[key] = val
            end
        end
    end)
end

function FullBright:Enable()
    self.Enabled = true
    applyFullBright()

    -- Continuous enforcement: re-apply every frame if game scripts override
    if enforceConn then enforceConn:Disconnect(); enforceConn = nil end
    enforceConn = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        applyFullBright()
    end)
end

function FullBright:Disable()
    self.Enabled = false
    if enforceConn then enforceConn:Disconnect(); enforceConn = nil end

    -- Restore original values
    pcall(function()
        Lighting.Brightness     = orig.Brightness
        Lighting.ClockTime      = orig.ClockTime
        Lighting.FogEnd         = orig.FogEnd
        Lighting.GlobalShadows  = orig.GlobalShadows
        Lighting.Ambient        = orig.Ambient
        Lighting.OutdoorAmbient = orig.OutdoorAmbient
    end)
end

function FullBright:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return FullBright
