-- Leon X | No Fall Damage
-- Prevents fall damage by restoring health when character lands after a fall.
-- Works by hooking Humanoid.StateChanged — when transitioning out of FreeFalling,
-- we snapshot health on the way down and restore it on landing.

local NoFallDamage = {}
NoFallDamage.Name    = "NoFallDamage"
NoFallDamage.Enabled = false

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local lp      = Players.LocalPlayer

-- Inline safety utilities
local function randomDelay(min, max)
    min = min or 50
    max = max or 150
    return (math.random(min, max)) / 1000
end

local function safeDisconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local stateConn  = nil   -- Humanoid.StateChanged connection
local charConn   = nil   -- CharacterAdded connection

local savedHealth  = nil   -- health snapshot taken while airborne
local isFalling    = false

local function applyToChar(char)
    if not char then return end

    -- Error handling: safely get humanoid with timeout
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        local success
        success, hum = pcall(function()
            return char:WaitForChild("Humanoid", 5)
        end)
        if not success or not hum then return end
    end

    -- Clean up previous connections to prevent memory leaks
    safeDisconnect(stateConn)
    stateConn = nil
    savedHealth = nil
    isFalling   = false

    stateConn = hum.StateChanged:Connect(function(_, new)
        if not NoFallDamage.Enabled then return end

        pcall(function()
            if new == Enum.HumanoidStateType.FreeFalling then
                -- started falling — take a health snapshot
                isFalling   = true
                savedHealth = hum.Health

            elseif isFalling and (
                new == Enum.HumanoidStateType.Landed      or
                new == Enum.HumanoidStateType.Running     or
                new == Enum.HumanoidStateType.RunningNoPhysics or
                new == Enum.HumanoidStateType.Jumping     or
                new == Enum.HumanoidStateType.Climbing
            ) then
                -- just landed — restore health before the game can apply damage
                isFalling = false
                if savedHealth and hum and hum.Parent then
                    -- Anti-detection: add random micro-delay
                    task.wait(randomDelay(10, 50))
                    -- defer one frame so damage calculation runs first,
                    -- then we override it back
                    task.defer(function()
                        if NoFallDamage.Enabled and hum and hum.Parent then
                            if hum.Health < savedHealth then
                                hum.Health = savedHealth
                            end
                        end
                    end)
                end
                savedHealth = nil
            end
        end)
    end)
end

function NoFallDamage:Enable()
    self.Enabled = true

    -- Error handling: safely apply to current character
    pcall(function()
        local char = lp.Character
        if char then applyToChar(char) end
    end)

    -- Cleanup old connection
    safeDisconnect(charConn)
    charConn = nil

    -- Respawn handling with error handling
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(randomDelay(80, 200))
        if self.Enabled then
            pcall(applyToChar, char)
        end
    end)
end

function NoFallDamage:Disable()
    self.Enabled = false
    safeDisconnect(stateConn)
    safeDisconnect(charConn)
    stateConn = nil
    charConn  = nil
    savedHealth = nil
    isFalling   = false
end

function NoFallDamage:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return NoFallDamage
