-- Leon X | Fly Module
-- PC:     WASD + Space/E naik + Q/Ctrl turun
--         RMB tahan + W/S = ikut pitch kamera
-- Mobile: thumbstick (MoveDirection) untuk horizontal
--         naik/turun lewat toggle UI atau Humanoid.Jump

local Fly = {}
Fly.Name    = "Fly"
Fly.Enabled = false
Fly.Speed   = 60

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local bv, bg, conn

-- detect platform
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

function Fly:Enable()
    -- Error handling: safely get character
    local success, char = pcall(function() return lp.Character end)
    if not success or not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    self.Enabled   = true

    -- Error handling: safely disable auto rotate
    pcall(function() hum.AutoRotate = false end)

    -- Cleanup old connections to prevent duplicates
    if conn then pcall(function() conn:Disconnect() end) end
    if bv then pcall(function() bv:Destroy() end) end
    if bg then pcall(function() bg:Destroy() end) end

    -- Error handling: safely create physics objects
    local bv_ok = pcall(function()
        bv           = Instance.new("BodyVelocity")
        bv.Velocity  = Vector3.zero
        bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
        bv.P         = 1e4
        bv.Parent    = hrp
    end)

    local bg_ok = pcall(function()
        bg           = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(0, 1e5, 0)
        bg.P         = 2e4
        bg.D         = 200
        bg.CFrame    = hrp.CFrame
        bg.Parent    = hrp
    end)

    if not bv_ok or not bg_ok then
        self:Disable()
        return
    end

    conn = RunService.RenderStepped:Connect(function()
        -- Error handling: verify objects still exist
        pcall(function()
            local c2  = lp.Character
            if not c2 then return end
            local h2  = c2:FindFirstChild("HumanoidRootPart")
            if not h2 then return end
            local hm2 = c2:FindFirstChildOfClass("Humanoid")
            if not hm2 then return end
            if not bv or not bg then return end

            local cam = workspace.CurrentCamera
            local cf  = cam.CFrame
            local dir = Vector3.zero

            if isMobile then
                -- ── Mobile: pakai MoveDirection dari thumbstick ───────────────────
                local md = hm2.MoveDirection  -- sudah world-space dari thumbstick
                if md.Magnitude > 0.01 then
                    -- horizontal: ikut arah yaw kamera
                    local flat  = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
                    local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
                    if flat.Magnitude  > 0.01 then flat  = flat.Unit  end
                    if right.Magnitude > 0.01 then right = right.Unit end
                    -- decompose MoveDirection ke forward/right lokal kamera
                    local fwd = md.Magnitude > 0 and md.Unit or Vector3.zero
                    local dot_f = fwd:Dot(flat)
                    local dot_r = fwd:Dot(right)
                    dir = dir + flat * dot_f + right * dot_r
                end
                -- naik/turun mobile: Jump state dari humanoid
                if hm2:GetState() == Enum.HumanoidStateType.Jumping
                or hm2:GetState() == Enum.HumanoidStateType.FreeFalling then
                    -- di mobile, tekan lompat = naik
                    dir = dir + Vector3.new(0, 0.8, 0)
                end
            else
                -- ── PC: keyboard ──────────────────────────────────────────────────
                local flat  = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
                local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
                if flat.Magnitude  > 0.001 then flat  = flat.Unit  end
                if right.Magnitude > 0.001 then right = right.Unit end

                local rmb = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    dir = dir + (rmb and cf.LookVector or flat)
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    dir = dir - (rmb and cf.LookVector or flat)
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end

                if UIS:IsKeyDown(Enum.KeyCode.Space)
                or UIS:IsKeyDown(Enum.KeyCode.E) then
                    dir = dir + Vector3.new(0, 1, 0)
                end
                if UIS:IsKeyDown(Enum.KeyCode.Q)
                or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    dir = dir + Vector3.new(0, -1, 0)
                end
            end

            if dir.Magnitude > 0 then dir = dir.Unit end
            bv.Velocity = dir * self.Speed

            -- gyro: hadap arah gerak, atau arah kamera saat diam
            local hDir = Vector3.new(dir.X, 0, dir.Z)
            if hDir.Magnitude > 0.01 then
                bg.CFrame = CFrame.new(h2.Position) *
                    CFrame.Angles(0, math.atan2(-hDir.X, -hDir.Z), 0)
            else
                bg.CFrame = CFrame.new(h2.Position) *
                    CFrame.Angles(0, math.atan2(-cf.LookVector.X, -cf.LookVector.Z), 0)
            end
        end)
    end)
end

function Fly:Disable()
    self.Enabled = false

    -- Error handling: safely restore auto rotate
    pcall(function()
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
        end
    end)

    -- Cleanup with error handling
    if conn then
        pcall(function() conn:Disconnect() end)
        conn = nil
    end
    if bv then
        pcall(function() bv:Destroy() end)
        bv   = nil
    end
    if bg then
        pcall(function() bg:Destroy() end)
        bg   = nil
    end
end

function Fly:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function Fly:SetSpeed(s)
    self.Speed = s
end

return Fly
