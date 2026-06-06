-- Leon X | AutoWalk
-- Moves character forward toward camera direction, auto-jumps over obstacles

local AutoWalk = {}
AutoWalk.Name    = "AutoWalk"
AutoWalk.Enabled = false
AutoWalk.Speed   = 16

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer
local conn
local charConn

local function loop()
    conn = RunService.Heartbeat:Connect(function()
        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        hum.WalkSpeed = AutoWalk.Speed

        local cf  = workspace.CurrentCamera.CFrame
        local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if fwd.Magnitude < 0.001 then return end
        fwd = fwd.Unit

        hum:Move(fwd, false)

        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude

        local hit = workspace:Raycast(hrp.Position + Vector3.new(0,0.5,0), fwd * 3.5, params)
        if hit then
            local s = hum:GetState()
            if s ~= Enum.HumanoidStateType.Jumping
            and s ~= Enum.HumanoidStateType.FreeFalling then
                hum.Jump = true
            end
        end
    end)
end

function AutoWalk:Enable()
    self.Enabled = true
    loop()
    charConn = lp.CharacterAdded:Connect(function()
        if conn then conn:Disconnect(); conn = nil end
        task.wait(0.5)
        if self.Enabled then loop() end
    end)
end

function AutoWalk:Disable()
    self.Enabled = false
    if conn     then conn:Disconnect();     conn     = nil end
    if charConn then charConn:Disconnect(); charConn = nil end
    -- restore walkspeed
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

function AutoWalk:SetSpeed(v)
    self.Speed = v
end

function AutoWalk:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return AutoWalk
