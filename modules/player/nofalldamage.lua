-- Leon X | No Fall Damage
-- Prevents fall damage by restoring health when character lands after a fall.
-- Works by hooking Humanoid.StateChanged — when transitioning out of FreeFalling,
-- we snapshot health on the way down and restore it on landing.

local NoFallDamage = {}
NoFallDamage.Name    = "NoFallDamage"
NoFallDamage.Enabled = false

local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

local stateConn  = nil   -- Humanoid.StateChanged connection
local healthConn = nil   -- Humanoid.HealthChanged connection (snapshot)
local charConn   = nil   -- CharacterAdded connection

local savedHealth  = nil   -- health snapshot taken while airborne
local isFalling    = false

local function applyToChar(char)
    if not char then return end

    -- wait for humanoid
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
    end

    -- clean up previous connections
    if stateConn  then stateConn:Disconnect();  stateConn  = nil end
    if healthConn then healthConn:Disconnect();  healthConn = nil end
    savedHealth = nil
    isFalling   = false

    stateConn = hum.StateChanged:Connect(function(_, new)
        if not NoFallDamage.Enabled then return end

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
end

function NoFallDamage:Enable()
    self.Enabled = true
    applyToChar(lp.Character)
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        if self.Enabled then applyToChar(char) end
    end)
end

function NoFallDamage:Disable()
    self.Enabled = false
    if stateConn  then stateConn:Disconnect();  stateConn  = nil end
    if healthConn then healthConn:Disconnect();  healthConn = nil end
    if charConn   then charConn:Disconnect();   charConn   = nil end
    savedHealth = nil
    isFalling   = false
end

function NoFallDamage:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return NoFallDamage
