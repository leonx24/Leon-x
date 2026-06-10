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

    -- Error handling: safely get humanoid
    local success, hum = pcall(function()
        return char:FindFirstChildOfClass("Humanoid")
    end)
    if not success or not hum then return end

    -- Anti-detection: use safer health value instead of math.huge
    -- math.huge is obvious to anti-cheat; use 9999 instead
    local MAX_SAFE_HEALTH = 9999

    -- Cleanup old connection
    if conn then pcall(function() conn:Disconnect() end) end
    conn = nil

    -- Loop: reset health every frame so server damage can't kill us
    conn = RunService.Heartbeat:Connect(function()
        if not GodMode.Enabled then return end

        -- Error handling: verify hum still exists
        if not hum or not hum.Parent then return end

        pcall(function()
            -- Set max health to safe value if not already set
            if hum.MaxHealth ~= MAX_SAFE_HEALTH then
                hum.MaxHealth = MAX_SAFE_HEALTH
            end
            -- Restore health if damaged
            if hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
    end)
end

function GodMode:Enable()
    self.Enabled = true

    -- Error handling: safely enable on current character
    pcall(function()
        if lp.Character then applyToChar(lp.Character) end
    end)

    -- Cleanup old connection
    if charConn then pcall(function() charConn:Disconnect() end) end
    charConn = nil

    -- Respawn handling: reapply on new character with error handling
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        if self.Enabled then
            pcall(function() applyToChar(char) end)
        end
    end)
end

function GodMode:Disable()
    self.Enabled = false

    -- Cleanup connections
    if conn then
        pcall(function() conn:Disconnect() end)
        conn = nil
    end
    if charConn then
        pcall(function() charConn:Disconnect() end)
        charConn = nil
    end

    -- Restore normal health with error handling
    pcall(function()
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = 100
                hum.Health = 100
            end
        end
    end)
end

function GodMode:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return GodMode
