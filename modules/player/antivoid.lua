-- Leon X | Anti Void
-- Detects when player is falling into void or below map
-- Teleports back to last safe position automatically
-- Works universally across all games

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local AntiVoid = {}
AntiVoid.Name = "AntiVoid"
AntiVoid.Enabled = false
AntiVoid.VoidThreshold = -50 -- Y position below this = falling into void
AntiVoid.FallSpeedThreshold = -30 -- velocity Y below this = falling fast
AntiVoid.SafeHeightOffset = 5 -- teleport this many studs above last safe position
AntiVoid.CheckInterval = 0.1 -- how often to check (seconds)

-- State tracking
local connection = nil
local lastSafePosition = nil
local lastSafeCFrame = nil
local lastCheckTime = 0
local lastSafeY = 0

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

-- Check if position is safe (on solid ground)
local function isSafePosition(hrp)
    if not hrp then return false end
    
    local pos = hrp.Position
    local velocity = hrp.AssemblyLinearVelocity
    
    -- Not falling fast
    if velocity.Y < AntiVoid.FallSpeedThreshold then
        return false
    end
    
    -- Not below void threshold
    if pos.Y < AntiVoid.VoidThreshold then
        return false
    end
    
    return true
end

local function saveSafePosition(hrp)
    if not hrp then return end
    lastSafePosition = hrp.Position
    lastSafeCFrame = hrp.CFrame
    lastSafeY = hrp.Position.Y
end

local function recoverFromVoid(hrp)
    if not hrp or not lastSafePosition then return false end
    
    pcall(function()
        -- Teleport to last safe position (with slight height offset)
        local recoveryPos = Vector3.new(
            lastSafePosition.X,
            lastSafePosition.Y + AntiVoid.SafeHeightOffset,
            lastSafePosition.Z
        )
        hrp.CFrame = CFrame.new(recoveryPos)
        
        -- Zero out velocity to stop falling
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.zero
        
        -- Update safe position to recovery position
        lastSafePosition = recoveryPos
        lastSafeY = recoveryPos.Y
    end)
    
    return true
end

function AntiVoid:Enable()
    if self.Enabled then return end
    self.Enabled = true
    
    -- Initialize safe position
    local hrp = getHRP()
    if hrp then
        saveSafePosition(hrp)
    end
    
    connection = RunService.Heartbeat:Connect(function(dt)
        if not self.Enabled then return end
        
        local now = tick()
        if now - lastCheckTime < self.CheckInterval then return end
        lastCheckTime = now
        
        local hrp = getHRP()
        if not hrp then return end
        
        local pos = hrp.Position
        local velocity = hrp.AssemblyLinearVelocity
        
        -- Check if position is safe and update
        if isSafePosition(hrp) then
            saveSafePosition(hrp)
            return
        end
        
        -- Detect void fall
        local isFallingIntoVoid = false
        local reason = ""
        
        -- Check 1: Below void threshold
        if pos.Y < self.VoidThreshold then
            isFallingIntoVoid = true
            reason = "below void threshold (" .. math.floor(pos.Y) .. ")"
        end
        
        -- Check 2: Falling very fast (likely off map)
        if velocity.Y < self.FallSpeedThreshold then
            -- Check if we have a safe position that's significantly higher
            if lastSafePosition and (lastSafeY - pos.Y) > 20 then
                isFallingIntoVoid = true
                reason = "falling fast (" .. math.floor(velocity.Y) .. " studs/s)"
            end
        end
        
        -- Check 3: Way below last known safe height
        if lastSafeY > 0 and (lastSafeY - pos.Y) > 50 then
            isFallingIntoVoid = true
            reason = "far below safe height"
        end
        
        if isFallingIntoVoid and lastSafePosition then
            if recoverFromVoid(hrp) then
                print("[Leon X] AntiVoid: Recovered! " .. reason)
            end
        end
    end)
    
    -- Handle character respawn
    lp.CharacterAdded:Connect(function(char)
        if not self.Enabled then return end
        task.wait(2) -- wait for character to load
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then
            saveSafePosition(hrp)
        end
    end)
    
    print("[Leon X] AntiVoid: Enabled (threshold: " .. self.VoidThreshold .. ")")
end

function AntiVoid:Disable()
    self.Enabled = false
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    print("[Leon X] AntiVoid: Disabled")
end

function AntiVoid:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

-- Setters
function AntiVoid:SetVoidThreshold(threshold)
    self.VoidThreshold = tonumber(threshold) or -50
end

function AntiVoid:SetFallSpeedThreshold(threshold)
    self.FallSpeedThreshold = tonumber(threshold) or -30
end

function AntiVoid:SetSafeHeightOffset(offset)
    self.SafeHeightOffset = tonumber(offset) or 5
end

function AntiVoid:SetCheckInterval(interval)
    self.CheckInterval = math.max(0.05, tonumber(interval) or 0.1)
end

-- Get last safe position (for external use)
function AntiVoid:GetLastSafePosition()
    return lastSafePosition
end

function AntiVoid:GetLastSafeCFrame()
    return lastSafeCFrame
end

return AntiVoid
