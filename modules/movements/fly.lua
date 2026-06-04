-- Leon X | Fly Module
-- BodyVelocity + BodyGyro — WASD + RMB drag to steer

local Fly = {}
Fly.Name    = "Fly"
Fly.Enabled = false
Fly.Speed   = 60

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local bv, bg, conn

-- Keyboard direction vectors (local to camera yaw)
local KEYS = {
    [Enum.KeyCode.W]           = Vector3.new( 0, 0,-1),
    [Enum.KeyCode.S]           = Vector3.new( 0, 0, 1),
    [Enum.KeyCode.A]           = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.D]           = Vector3.new( 1, 0, 0),
    [Enum.KeyCode.Space]       = Vector3.new( 0, 1, 0),
    [Enum.KeyCode.LeftControl] = Vector3.new( 0,-1, 0),
    [Enum.KeyCode.Q]           = Vector3.new( 0,-1, 0),
    [Enum.KeyCode.E]           = Vector3.new( 0, 1, 0),
}

function Fly:Enable()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    self.Enabled = true
    hum.PlatformStand = true

    bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.zero
    bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    bv.P         = 1e4
    bv.Parent    = hrp

    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P         = 1e4
    bg.D         = 100
    bg.CFrame    = hrp.CFrame
    bg.Parent    = hrp

    conn = RunService.RenderStepped:Connect(function()
        local char2 = lp.Character
        if not char2 then return end
        local hrp2 = char2:FindFirstChild("HumanoidRootPart")
        if not hrp2 or not bv or not bg then return end

        local cam   = workspace.CurrentCamera
        local camCF = cam.CFrame
        local dir   = Vector3.zero

        -- ── WASD / Space / Ctrl / Q / E ───────────────────────────────────────
        for key, vec in pairs(KEYS) do
            if UIS:IsKeyDown(key) then
                if vec.Y ~= 0 then
                    -- up/down is always world-space
                    dir = dir + vec
                else
                    local flat  = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z).Unit
                    local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
                    if vec.Z ~= 0 then dir = dir + flat  * (-vec.Z) end
                    if vec.X ~= 0 then dir = dir + right *   vec.X  end
                end
            end
        end

        -- ── RMB held → fly in the direction the camera is looking ─────────────
        -- (standard Roblox camera: RMB + drag rotates camera, so looking = moving)
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            -- use the full camera look vector (includes vertical pitch)
            dir = dir + camCF.LookVector
        end

        if dir.Magnitude > 0 then dir = dir.Unit end

        bv.Velocity = dir * self.Speed

        -- gyro tracks camera yaw so character faces forward
        local yaw = math.atan2(-camCF.LookVector.X, -camCF.LookVector.Z)
        bg.CFrame  = CFrame.new(hrp2.Position) * CFrame.Angles(0, yaw, 0)
    end)
end

function Fly:Disable()
    self.Enabled = false
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    if conn then conn:Disconnect(); conn = nil end
    if bv   then bv:Destroy();     bv   = nil end
    if bg   then bg:Destroy();     bg   = nil end
end

function Fly:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function Fly:SetSpeed(s)
    self.Speed = s
end

return Fly
