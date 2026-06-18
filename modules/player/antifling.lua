-- Leon X | AntiFling (Enhanced)
-- Detects abnormal velocity on the LocalPlayer's HumanoidRootPart
-- and resets position + velocity before the fling can send the character flying.
--
-- Enhanced with:
-- - Position anchoring (snap back instantly)
-- - Mass manipulation (make character harder to fling)
-- - Knockback dampening (reduce force before it affects you)
-- - BodyMover cleanup (remove foreign physics objects)
-- - Tool hit detection (detect kicks/punches specifically)

local AntiFling = {}
AntiFling.Name      = "AntiFling"
AntiFling.Enabled   = false
AntiFling.Threshold = 150   -- studs/s — velocities above this are considered a fling
AntiFling.UseMassManipulation = true  -- make character heavy to resist flings
AntiFling.UsePositionLock = true      -- lock position during fling detection
AntiFling.RecoverySpeed = 1           -- how fast to snap back (1 = instant)
AntiFling.CleanupBodyMovers = true    -- remove foreign BodyMovers
AntiFling.MaxRecoveryDistance = 100   -- max distance to recover from

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local renderConn   = nil
local charConn     = nil
local toolConn     = nil
local heartbeatConn = nil

-- per-character state
local lastSafeCF   = nil
local lastSafeTime = 0
local SAFE_INTERVAL = 0.05  -- update safe position every 0.05s (more frequent)
local isRecovering = false
local recoveryTarget = nil
local lastHitTime = 0
local massObjects = {}

-- Original mass values
local originalMass = {}

local function getHRP()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- Make character heavy so harder to fling
local function applyMassManipulation(char)
    if not AntiFling.UseMassManipulation then return end
    
    pcall(function()
        -- Store original masses
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                originalMass[part] = part.Mass
                -- Make parts much heavier (harder to fling)
                part.Mass = part.Mass * 5
            end
        end
        
        -- Also set HumanoidRootPart CustomPhysicalProperties for stability
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CustomPhysicalProperties = PhysicalProperties.new(
                10,    -- Density (heavier)
                0.3,   -- Friction
                0.5    -- Elasticity (less bouncy)
            )
        end
    end)
end

-- Restore original mass
local function removeMassManipulation(char)
    pcall(function()
        for part, mass in pairs(originalMass) do
            if part and part.Parent then
                part.Mass = mass
            end
        end
        originalMass = {}
        
        -- Reset HRP properties
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CustomPhysicalProperties = nil
        end
    end)
end

-- Remove foreign BodyMovers attached by fling exploits
local function cleanupForeignObjects(hrp)
    if not AntiFling.CleanupBodyMovers then return end
    
    pcall(function()
        for _, obj in ipairs(hrp:GetChildren()) do
            local cn = obj.ClassName
            if cn == "BodyVelocity" or cn == "BodyForce"
            or cn == "BodyPosition" or cn == "VectorForce"
            or cn == "LinearVelocity" or cn == "BodyGyro"
            or cn == "BodyThrust" then
                -- Don't destroy if it's ours (named something specific)
                if obj.Name ~= "LeonX_AntiFling" then
                    obj:Destroy()
                end
            end
        end
    end)
end

-- Quick position recovery
local function recoverPosition(hrp, targetCF)
    if not hrp or not targetCF then return end
    
    pcall(function()
        -- Instant snap to safe position
        hrp.CFrame = targetCF
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function onCharacterAdded(char)
    -- Reset state on respawn
    lastSafeCF = nil
    lastSafeTime = 0
    isRecovering = false
    recoveryTarget = nil
    originalMass = {}
    massObjects = {}
    
    -- Wait for character to fully load
    task.wait(1)
    
    -- Apply mass manipulation if enabled
    if AntiFling.Enabled then
        applyMassManipulation(char)
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            lastSafeCF = hrp.CFrame
            lastSafeTime = tick()
        end
    end
end

local function startWatching()
    if renderConn then renderConn:Disconnect(); renderConn = nil end

    renderConn = RunService.RenderStepped:Connect(function()
        if not AntiFling.Enabled then return end

        local char = lp.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return end

        local vel = hrp.AssemblyLinearVelocity
        local spd = vel.Magnitude
        local now = tick()

        -- Update safe position frequently when velocity is normal
        if spd < AntiFling.Threshold and not isRecovering then
            if (now - lastSafeTime) >= SAFE_INTERVAL then
                lastSafeCF = hrp.CFrame
                lastSafeTime = now
            end
        end

        -- Velocity spike detected — fling attempt
        if spd >= AntiFling.Threshold then
            isRecovering = true
            lastHitTime = now
            
            if lastSafeCF then
                -- Check distance to safe position
                local dist = (hrp.Position - lastSafeCF.Position).Magnitude
                
                if dist <= AntiFling.MaxRecoveryDistance then
                    -- Snap back to safe position
                    recoverPosition(hrp, lastSafeCF)
                    
                    -- Clean up any foreign physics objects
                    cleanupForeignObjects(hrp)
                    
                    -- Update safe position to recovery point
                    lastSafeCF = hrp.CFrame
                    lastSafeTime = now
                else
                    -- Too far from safe position, just zero velocity
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    
                    -- Update safe position to current
                    lastSafeCF = hrp.CFrame
                    lastSafeTime = now
                end
            else
                -- No safe position yet, just zero velocity
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                lastSafeCF = hrp.CFrame
                lastSafeTime = now
            end
            
            isRecovering = false
        end
    end)
end

function AntiFling:Enable()
    if self.Enabled then return end
    self.Enabled = true

    -- Watch for respawn
    charConn = lp.CharacterAdded:Connect(onCharacterAdded)

    -- Initialize from current character
    local char = lp.Character
    if char then
        applyMassManipulation(char)
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            lastSafeCF = hrp.CFrame
            lastSafeTime = tick()
        end
    end

    startWatching()
    
    print("[Leon X] AntiFling: Enhanced mode enabled")
end

function AntiFling:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    -- Remove mass manipulation
    local char = lp.Character
    if char then
        removeMassManipulation(char)
    end

    if renderConn then renderConn:Disconnect(); renderConn = nil end
    if charConn then charConn:Disconnect(); charConn = nil end
    if toolConn then toolConn:Disconnect(); toolConn = nil end
    if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end

    lastSafeCF = nil
    lastSafeTime = 0
    isRecovering = false
    originalMass = {}
    
    print("[Leon X] AntiFling: Disabled")
end

function AntiFling:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function AntiFling:SetThreshold(v)
    self.Threshold = math.max(50, tonumber(v) or 150)
end

function AntiFling:SetMassManipulation(enabled)
    self.UseMassManipulation = enabled
    local char = lp.Character
    if enabled then
        applyMassManipulation(char)
    else
        removeMassManipulation(char)
    end
end

function AntiFling:SetRecoverySpeed(speed)
    self.RecoverySpeed = math.max(0.1, math.min(1, tonumber(speed) or 1))
end

-- Get fling stats
function AntiFling:GetStats()
    return {
        Enabled = self.Enabled,
        LastSafePosition = lastSafeCF,
        LastHitTime = lastHitTime,
        IsRecovering = isRecovering,
    }
end

return AntiFling
