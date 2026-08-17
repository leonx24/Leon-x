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
local lastSafeY = nil -- track last safe Y position (only when grounded)
local lastRestoreTick = 0 -- cooldown to prevent teleport loops
local origWalkSpeed = nil  -- save original values to restore on disable
local origJumpPower = nil
local origJumpHeight = nil

-- Grounded humanoid states (safe to record Y position)
local groundedStates = {
    [Enum.HumanoidStateType.Running]   = true,
    [Enum.HumanoidStateType.Landed]    = true,
    [Enum.HumanoidStateType.Climbing]  = true,
    [Enum.HumanoidStateType.Swimming]  = true,
    [Enum.HumanoidStateType.Seated]    = true,
}

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
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Initialize lastSafeY only if currently grounded
    local initState = hum:GetState()
    if groundedStates[initState] then
        lastSafeY = hrp.Position.Y
    else
        lastSafeY = nil
    end

    fallConn = RunService.Heartbeat:Connect(function()
        if not Speed.Enabled then return end
        if not hrp or not hrp.Parent then return end
        if not hum or not hum.Parent then return end

        local currentY = hrp.Position.Y

        -- Only update safe Y when humanoid is in a grounded state
        -- This prevents saving mid-air/freefall positions
        local ok, state = pcall(function() return hum:GetState() end)
        if ok and groundedStates[state] and currentY > 0 then
            lastSafeY = currentY
        end

        -- If teleported below ground (anti-cheat), restore position with cooldown
        if currentY < -50 and lastSafeY then
            local now = tick()
            if now - lastRestoreTick > 1.0 then -- 1 second cooldown
                lastRestoreTick = now
                pcall(function()
                    hrp.CFrame = CFrame.new(hrp.Position.X, lastSafeY, hrp.Position.Z)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end)
            end
        end
    end)
end

function Speed:Enable()
    self.Enabled = true
    local char = lp.Character

    -- Save original values on first enable (so we can restore them on disable)
    if not origWalkSpeed and char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                origWalkSpeed  = hum.WalkSpeed
                origJumpPower  = hum.JumpPower
                origJumpHeight = hum.JumpHeight
            end)
        end
    end

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
    -- restore original values (or defaults if originals not captured)
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum.WalkSpeed  = origWalkSpeed  or 16
                hum.JumpPower  = origJumpPower  or 50
                hum.JumpHeight = origJumpHeight or 7.2
            end)
        end
    end
    origWalkSpeed  = nil
    origJumpPower  = nil
    origJumpHeight = nil
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
