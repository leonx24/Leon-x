-- Leon X | GodMode
-- Keeps Health at max every frame — works against server-side damage
-- by repeatedly resetting Health before server can register death

local GodMode = {}
GodMode.Name    = "GodMode"
GodMode.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local conn     = nil
local charConn = nil

local function applyToChar(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Set max health
    hum.MaxHealth = math.huge
    hum.Health    = math.huge

    -- Loop: reset health every frame so server damage can't kill us
    if conn then conn:Disconnect(); conn = nil end
    conn = RunService.Heartbeat:Connect(function()
        if not GodMode.Enabled then return end
        if not hum or not hum.Parent then return end
        if hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end)
end

function GodMode:Enable()
    self.Enabled = true
    applyToChar(lp.Character)
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        if self.Enabled then applyToChar(char) end
    end)
end

function GodMode:Disable()
    self.Enabled = false
    if conn     then conn:Disconnect();     conn     = nil end
    if charConn then charConn:Disconnect(); charConn = nil end
    -- restore normal health
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = 100
            hum.Health    = 100
        end
    end
end

function GodMode:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return GodMode
