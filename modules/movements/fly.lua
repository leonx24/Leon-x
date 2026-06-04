-- Leon X | Fly Module
-- WASD = gerak horizontal relatif kamera
-- Space/E = naik, Q/Ctrl = turun
-- RMB tahan + W/S = gerak ikut pitch kamera (naik/turun sesuai arah lihat)
-- Karakter tetap animasi normal (tidak freeze)

local Fly = {}
Fly.Name    = "Fly"
Fly.Enabled = false
Fly.Speed   = 60

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local bv, bg, conn

function Fly:Enable()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    self.Enabled    = true
    hum.AutoRotate  = false   -- kita kontrol rotasi manual

    bv              = Instance.new("BodyVelocity")
    bv.Velocity     = Vector3.zero
    bv.MaxForce     = Vector3.new(1e5, 1e5, 1e5)
    bv.P            = 1e4
    bv.Parent       = hrp

    bg              = Instance.new("BodyGyro")
    bg.MaxTorque    = Vector3.new(0, 1e5, 0)  -- yaw only
    bg.P            = 2e4
    bg.D            = 200
    bg.CFrame       = hrp.CFrame
    bg.Parent       = hrp

    conn = RunService.RenderStepped:Connect(function()
        local c2  = lp.Character;         if not c2  then return end
        local h2  = c2:FindFirstChild("HumanoidRootPart"); if not h2  then return end
        local hm2 = c2:FindFirstChildOfClass("Humanoid");  if not hm2 then return end
        if not bv or not bg then return end

        local cam   = workspace.CurrentCamera
        local cf    = cam.CFrame
        local dir   = Vector3.zero

        local flat  = Vector3.new(cf.LookVector.X,  0, cf.LookVector.Z)
        local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
        if flat.Magnitude  > 0.001 then flat  = flat.Unit  end
        if right.Magnitude > 0.001 then right = right.Unit end

        local rmb = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

        -- W / S
        if UIS:IsKeyDown(Enum.KeyCode.W) then
            if rmb then
                -- RMB tahan: W gerak ke arah full kamera (naik jika lihat ke atas)
                dir = dir + cf.LookVector
            else
                dir = dir + flat
            end
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            if rmb then
                dir = dir - cf.LookVector
            else
                dir = dir - flat
            end
        end

        -- A / D (selalu horizontal)
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end

        -- naik / turun (world-space, tidak terpengaruh RMB)
        if UIS:IsKeyDown(Enum.KeyCode.Space)        then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.E)            then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.Q)            then dir = dir + Vector3.new(0,-1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl)  then dir = dir + Vector3.new(0,-1,0) end

        if dir.Magnitude > 0 then dir = dir.Unit end
        bv.Velocity = dir * self.Speed

        -- gyro: karakter hadap arah gerak horizontal, atau arah kamera saat diam
        local hDir = Vector3.new(dir.X, 0, dir.Z)
        if hDir.Magnitude > 0.01 then
            bg.CFrame = CFrame.new(h2.Position) *
                CFrame.Angles(0, math.atan2(-hDir.X, -hDir.Z), 0)
        else
            bg.CFrame = CFrame.new(h2.Position) *
                CFrame.Angles(0, math.atan2(-cf.LookVector.X, -cf.LookVector.Z), 0)
        end
    end)
end

function Fly:Disable()
    self.Enabled = false
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
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
