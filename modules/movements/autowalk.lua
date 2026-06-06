-- Leon X | AutoWalk
-- Uses BodyVelocity to force movement — bypasses Roblox control override
-- Auto-jumps when obstacle detected in front

local AutoWalk = {}
AutoWalk.Name    = "AutoWalk"
AutoWalk.Enabled = false
AutoWalk.Speed   = 16

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local bv         = nil   -- BodyVelocity
local conn       = nil
local charConn   = nil
local jumpCool   = false

local function stopLoop()
    if conn then conn:Disconnect(); conn = nil end
    if bv   then bv:Destroy();     bv   = nil end
end

local function startLoop()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- BodyVelocity: override physics to push forward
    bv          = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e4, 0, 1e4)   -- horizontal only, Y=0 so gravity works
    bv.P        = 1e4
    bv.Velocity = Vector3.zero
    bv.Parent   = hrp

    conn = RunService.Heartbeat:Connect(function()
        local c2  = lp.Character;                           if not c2  then return end
        local h2  = c2:FindFirstChild("HumanoidRootPart");  if not h2  then return end
        local hm2 = c2:FindFirstChildOfClass("Humanoid");   if not hm2 then return end
        if hm2.Health <= 0 or not bv then return end

        -- forward direction = camera yaw (flat, no pitch)
        local cf  = workspace.CurrentCamera.CFrame
        local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if fwd.Magnitude < 0.001 then bv.Velocity = Vector3.zero; return end
        fwd = fwd.Unit

        -- push forward
        bv.Velocity = fwd * AutoWalk.Speed

        -- face direction of movement
        hm2.AutoRotate = false
        h2.CFrame = CFrame.new(h2.Position, h2.Position + fwd)
            * CFrame.Angles(0, 0, 0)

        -- obstacle raycast — 3 levels: low / mid / high
        local origins = {
            h2.Position + Vector3.new(0, 0.3, 0),
            h2.Position + Vector3.new(0, 1.2, 0),
            h2.Position + Vector3.new(0, 2.2, 0),
        }
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {c2}
        params.FilterType = Enum.RaycastFilterType.Exclude

        local blocked = false
        for _, orig in ipairs(origins) do
            if workspace:Raycast(orig, fwd * 3, params) then
                blocked = true; break
            end
        end

        if blocked and not jumpCool then
            local s = hm2:GetState()
            if s ~= Enum.HumanoidStateType.Jumping
            and s ~= Enum.HumanoidStateType.FreeFalling then
                hm2.Jump = true
                jumpCool = true
                task.delay(0.6, function() jumpCool = false end)
            end
        end
    end)
end

function AutoWalk:Enable()
    self.Enabled = true
    jumpCool = false
    startLoop()
    charConn = lp.CharacterAdded:Connect(function()
        stopLoop()
        task.wait(0.5)
        if self.Enabled then startLoop() end
    end)
end

function AutoWalk:Disable()
    self.Enabled = false
    stopLoop()
    if charConn then charConn:Disconnect(); charConn = nil end
    -- restore
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true; hum.WalkSpeed = 16 end
    end
end

function AutoWalk:SetSpeed(v)
    self.Speed = v
end

function AutoWalk:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return AutoWalk
