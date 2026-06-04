-- Leon X | Fly Module
-- BodyVelocity approach — karakter tetap animasi normal (tidak freeze)
-- RMB hanya memutar kamera (Roblox default), tidak menambah arah gerak

local Fly = {}
Fly.Name    = "Fly"
Fly.Enabled = false
Fly.Speed   = 60

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local bv, bg, conn

-- Keyboard mapping: key → arah lokal relatif kamera
local KEYS = {
    [Enum.KeyCode.W]           = Vector3.new( 0, 0,-1),  -- maju
    [Enum.KeyCode.S]           = Vector3.new( 0, 0, 1),  -- mundur
    [Enum.KeyCode.A]           = Vector3.new(-1, 0, 0),  -- kiri
    [Enum.KeyCode.D]           = Vector3.new( 1, 0, 0),  -- kanan
    [Enum.KeyCode.Space]       = Vector3.new( 0, 1, 0),  -- naik
    [Enum.KeyCode.LeftControl] = Vector3.new( 0,-1, 0),  -- turun
    [Enum.KeyCode.Q]           = Vector3.new( 0,-1, 0),  -- turun (alt)
    [Enum.KeyCode.E]           = Vector3.new( 0, 1, 0),  -- naik (alt)
}

function Fly:Enable()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    self.Enabled = true

    -- TIDAK pakai PlatformStand supaya animasi karakter tetap jalan
    -- hum.PlatformStand = false  (biarkan default)

    -- BodyVelocity untuk override physics movement
    bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.zero
    bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    bv.P         = 1e4
    bv.Parent    = hrp

    -- BodyGyro supaya karakter menghadap arah yang benar
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(0, 1e5, 0)   -- hanya yaw, bukan pitch/roll
    bg.P         = 2e4
    bg.D         = 200
    bg.CFrame    = hrp.CFrame
    bg.Parent    = hrp

    conn = RunService.RenderStepped:Connect(function()
        local char2 = lp.Character
        if not char2 then return end
        local hrp2 = char2:FindFirstChild("HumanoidRootPart")
        local hum2 = char2:FindFirstChildOfClass("Humanoid")
        if not hrp2 or not bv or not bg then return end

        local cam   = workspace.CurrentCamera
        local camCF = cam.CFrame
        local dir   = Vector3.zero

        -- ── WASD / Space / Ctrl / Q / E ───────────────────────────────────────
        for key, vec in pairs(KEYS) do
            if UIS:IsKeyDown(key) then
                if vec.Y ~= 0 then
                    -- naik/turun: world-space, tidak ikut kamera pitch
                    dir = dir + vec
                else
                    -- horizontal: relatif ke arah kamera (yaw only)
                    local flat  = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z).Unit
                    local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
                    if vec.Z ~= 0 then dir = dir + flat  * (-vec.Z) end
                    if vec.X ~= 0 then dir = dir + right *   vec.X  end
                end
            end
        end

        -- ── RMB: HANYA memutar kamera, TIDAK menambah arah gerak ──────────────
        -- (Roblox sudah handle rotasi kamera saat RMB ditahan secara default)
        -- Tidak ada kode tambahan di sini untuk RMB

        -- normalize agar diagonal tidak lebih cepat
        if dir.Magnitude > 0 then dir = dir.Unit end

        bv.Velocity = dir * self.Speed

        -- Animasi berjalan: set WalkDirection supaya Humanoid tahu kita bergerak
        if hum2 then
            if dir.Magnitude > 0 then
                -- arahkan karakter ke arah gerak horizontal
                local hDir = Vector3.new(dir.X, 0, dir.Z)
                if hDir.Magnitude > 0 then
                    hum2.AutoRotate = false
                    local yaw = math.atan2(-hDir.X, -hDir.Z)
                    bg.CFrame = CFrame.new(hrp2.Position) * CFrame.Angles(0, yaw, 0)
                end
            else
                -- diam: hadap ke arah kamera
                hum2.AutoRotate = false
                local yaw = math.atan2(-camCF.LookVector.X, -camCF.LookVector.Z)
                bg.CFrame = CFrame.new(hrp2.Position) * CFrame.Angles(0, yaw, 0)
            end
        end
    end)
end

function Fly:Disable()
    self.Enabled = false

    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutoRotate = true   -- kembalikan auto rotate
        end
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
