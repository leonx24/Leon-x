-- Leon X | AutoWalk v2
-- BodyVelocity forward push + smart jump/climb detection
-- Works on mountain maps, stairs, rocks

local AutoWalk = {}
AutoWalk.Name    = "AutoWalk"
AutoWalk.Enabled = false
AutoWalk.Speed   = 16

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local bv       = nil
local conn     = nil
local charConn = nil
local jumpCD   = false   -- jump cooldown flag

local OBSTACLE_DIST = 2.8   -- stud, how close before jumping
local JUMP_COOLDOWN = 0.55  -- seconds between jumps
local STEP_HEIGHT   = 2.5   -- stud clearance check for walkable slope

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

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

    params.FilterDescendantsInstances = {char}

    -- BodyVelocity: X/Z push, Y stays at 0 so gravity applies normally
    bv          = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e3, 0, 9e3)
    bv.P        = 1.2e4
    bv.Velocity = Vector3.zero
    bv.Parent   = hrp

    conn = RunService.Heartbeat:Connect(function()
        local c2  = lp.Character;                          if not c2  then return end
        local h2  = c2:FindFirstChild("HumanoidRootPart"); if not h2  then return end
        local hm2 = c2:FindFirstChildOfClass("Humanoid");  if not hm2 then return end
        if hm2.Health <= 0 or not bv then return end

        -- camera-relative forward (yaw only)
        local cf  = workspace.CurrentCamera.CFrame
        local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        if fwd.Magnitude < 0.001 then bv.Velocity = Vector3.zero; return end
        fwd = fwd.Unit

        bv.Velocity = fwd * AutoWalk.Speed

        -- ── Obstacle & climb detection ────────────────────────────────────────
        local root   = h2.Position
        local state  = hm2:GetState()
        local midFwd = root + Vector3.new(0, 0.6, 0)

        -- 1. Check if there is something solid directly in front at body height
        local hitLow  = workspace:Raycast(root + Vector3.new(0, 0.3, 0), fwd * OBSTACLE_DIST, params)
        local hitMid  = workspace:Raycast(root + Vector3.new(0, 1.2, 0), fwd * OBSTACLE_DIST, params)

        local blocked = hitLow or hitMid

        if blocked and not jumpCD then
            -- 2. Check if the obstacle top is walkable (slope/stair) or too tall (wall)
            --    Cast downward from above the obstacle hit point
            local hitPos  = (hitLow or hitMid).Position
            local probeUp = Vector3.new(hitPos.X, root.Y + STEP_HEIGHT + 1, hitPos.Z)
            local downHit = workspace:Raycast(probeUp, Vector3.new(0, -(STEP_HEIGHT + 1.5), 0), params)

            if downHit then
                -- obstacle top is within step height → walkable, just jump over it
                local topY = downHit.Position.Y
                if topY - root.Y < STEP_HEIGHT then
                    -- low enough to jump
                    if state ~= Enum.HumanoidStateType.Jumping
                    and state ~= Enum.HumanoidStateType.FreeFalling then
                        hm2.Jump = true
                        jumpCD   = true
                        task.delay(JUMP_COOLDOWN, function() jumpCD = false end)
                    end
                else
                    -- too tall to jump — try to go around (slight right strafe)
                    local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
                    if right.Magnitude > 0.001 then
                        bv.Velocity = (fwd + right * 0.6).Unit * AutoWalk.Speed
                    end
                end
            else
                -- no surface above obstacle → probably a wall edge, jump anyway
                if state ~= Enum.HumanoidStateType.Jumping
                and state ~= Enum.HumanoidStateType.FreeFalling then
                    hm2.Jump = true
                    jumpCD   = true
                    task.delay(JUMP_COOLDOWN, function() jumpCD = false end)
                end
            end
        end

        -- 3. Ground ahead check — if ground drops, keep walking (don't jump off cliffs)
        local groundAhead = workspace:Raycast(root + fwd * 1.5 + Vector3.new(0, 0.3, 0),
                                              Vector3.new(0, -4, 0), params)
        if not groundAhead and not blocked then
            -- cliff edge ahead — slow down, don't walk off
            bv.Velocity = fwd * math.min(AutoWalk.Speed, 8)
        end
    end)
end

function AutoWalk:Enable()
    self.Enabled = true
    jumpCD = false
    startLoop()
    charConn = lp.CharacterAdded:Connect(function()
        stopLoop(); task.wait(0.5)
        if self.Enabled then startLoop() end
    end)
end

function AutoWalk:Disable()
    self.Enabled = false
    stopLoop()
    if charConn then charConn:Disconnect(); charConn = nil end
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

function AutoWalk:SetSpeed(v) self.Speed = v end

function AutoWalk:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return AutoWalk
