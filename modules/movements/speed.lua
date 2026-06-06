-- Leon X | Speed
-- Controls WalkSpeed and JumpPower/JumpHeight for PC and mobile

local Speed = {}
Speed.Name      = "Speed"
Speed.Enabled   = false
Speed.WalkSpeed = 16
Speed.JumpPower = 50

local lp = game:GetService("Players").LocalPlayer

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

local charConn

function Speed:Enable()
    self.Enabled = true
    applyToChar(lp.Character)
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        applyToChar(char)
    end)
end

function Speed:Disable()
    self.Enabled = false
    if charConn then charConn:Disconnect(); charConn = nil end
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
