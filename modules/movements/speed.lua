-- Leon X | Speed
-- Controls WalkSpeed and JumpPower/JumpHeight for PC and mobile
-- Anti-fall protection: prevents game anti-cheat from teleporting you underground

local Speed = {}
Speed.Name      = "Speed"
Speed.Enabled   = false
Speed.WalkSpeed = 16
Speed.JumpPower = 50

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local charConn, fallConn
local lastSafeY = 100 -- track last safe Y position

local function applyToChar(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Speed.WalkSpeed ~= 16 then
        hum.WalkSpeed = Speed.WalkSpeed
    end
    if Speed.JumpPower ~= 50 then
        hum.JumpPower  = Speed.JumpPower
        hum.JumpHeight = Speed.JumpPower * 0.05
    end
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
    applyToChar(lp.Character)
    startAntiFall(lp.Character)
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        applyToChar(char)
        startAntiFall(char)
    end)
end

function Speed:Disable()
    self.Enabled = false
    if charConn then charConn:Disconnect(); charConn = nil end
    if fallConn then fallConn:Disconnect(); fallConn = nil end
    -- restore defaults
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed  = 16
            hum.JumpPower  = 50
            hum.JumpHeight = 7.2
        end
    end
end

function Speed:SetWalkSpeed(v)
    self.WalkSpeed = v
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end

function Speed:SetJumpPower(v)
    self.JumpPower = v
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower  = v
            hum.JumpHeight = v * 0.05
        end
    end
end

function Speed:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Speed
