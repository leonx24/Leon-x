-- Leon X | Speed
-- Controls WalkSpeed and JumpPower/JumpHeight for PC and mobile
-- Anti-fall protection: prevents game anti-cheat from teleporting you underground
-- Continuous enforcement: values persist through sit/crouch/cutscene/state changes

local Speed = {}
Speed.Name      = "Speed"
Speed.Enabled   = false
Speed.WalkSpeed = 16
Speed.JumpPower = 50

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local charConn, fallConn, enforceConn, stateConn
local lastSafeY = 100 -- track last safe Y position

-- Convert JumpPower to standard Roblox JumpHeight (50 JumpPower = 7.2 JumpHeight)
local function calcJumpHeight(jp)
    return (jp / 50) * 7.2
end

-- Apply speed values to humanoid (single application)
local function applyToChar(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        hum.WalkSpeed = Speed.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower    = Speed.JumpPower
        hum.JumpHeight   = calcJumpHeight(Speed.JumpPower)
    end)
end

-- Continuously enforce speed values (prevents game scripts from resetting)
local function startEnforcement(char)
    if enforceConn then enforceConn:Disconnect(); enforceConn = nil end
    if stateConn then stateConn:Disconnect(); stateConn = nil end

    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Heartbeat enforcement: re-apply values every frame if they differ
    enforceConn = RunService.Heartbeat:Connect(function()
        if not Speed.Enabled then return end
        pcall(function()
            if not hum or not hum.Parent then return end
            -- Only write when values differ to minimize overhead
            if hum.WalkSpeed ~= Speed.WalkSpeed then
                hum.WalkSpeed = Speed.WalkSpeed
            end
            if not hum.UseJumpPower then
                hum.UseJumpPower = true
            end
            if hum.JumpPower ~= Speed.JumpPower then
                hum.JumpPower = Speed.JumpPower
            end
            local targetJH = calcJumpHeight(Speed.JumpPower)
            if math.abs(hum.JumpHeight - targetJH) > 0.05 then
                hum.JumpHeight = targetJH
            end
        end)
    end)

    -- StateChanged: immediately re-apply on state transitions (sit→run, etc.)
    stateConn = hum.StateChanged:Connect(function(_, newState)
        if not Speed.Enabled then return end
        -- Delay slightly to let the game script set its values first, then override
        task.defer(function()
            if not Speed.Enabled then return end
            applyToChar(char)
        end)
    end)
end

local function startAntiFall(char)
    -- Track last safe Y position and restore if teleported below
    if fallConn then fallConn:Disconnect(); fallConn = nil end

    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    lastSafeY = hrp.Position.Y -- initialize with current Y

    fallConn = RunService.Heartbeat:Connect(function()
        if not Speed.Enabled then return end
        if not hrp or not hrp.Parent then return end

        local currentY = hrp.Position.Y

        -- Update safe Y when character is on ground or moving normally
        if currentY > 0 and currentY < 1000 then
            lastSafeY = currentY
        end

        -- If teleported below ground (anti-cheat), restore position
        if currentY < -50 then
            pcall(function()
                hrp.CFrame = CFrame.new(hrp.Position.X, math.max(lastSafeY, 50), hrp.Position.Z)
                hrp.AssemblyLinearVelocity = Vector3.zero
            end)
        end
    end)
end

function Speed:Enable()
    self.Enabled = true
    local char = lp.Character
    applyToChar(char)
    startAntiFall(char)
    startEnforcement(char)
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        applyToChar(char)
        startAntiFall(char)
        startEnforcement(char)
    end)
end

function Speed:Disable()
    self.Enabled = false
    if charConn then charConn:Disconnect(); charConn = nil end
    if fallConn then fallConn:Disconnect(); fallConn = nil end
    if enforceConn then enforceConn:Disconnect(); enforceConn = nil end
    if stateConn then stateConn:Disconnect(); stateConn = nil end
    -- restore defaults
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum.WalkSpeed  = 16
                hum.JumpPower  = 50
                hum.JumpHeight = 7.2
            end)
        end
    end
end

function Speed:SetWalkSpeed(v)
    self.WalkSpeed = v
    if self.Enabled then
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.WalkSpeed = v end) end
        end
    end
end

function Speed:SetJumpPower(v)
    self.JumpPower = v
    if self.Enabled then
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum.UseJumpPower = true
                    hum.JumpPower    = v
                    hum.JumpHeight   = calcJumpHeight(v)
                end)
            end
        end
    end
end

function Speed:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Speed
