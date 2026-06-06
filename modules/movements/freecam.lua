-- Leon X | FreeCam
-- Detaches camera from character and lets you fly it freely with WASD + mouse
-- Q/E = down/up | Shift = slow | RMB hold = look around | scroll = speed

local FreeCam = {}
FreeCam.Name    = "FreeCam"
FreeCam.Enabled = false
FreeCam.Speed   = 40

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local ContextAction = game:GetService("ContextActionService")
local lp            = Players.LocalPlayer

local camera        = workspace.CurrentCamera
local prevCamType   = nil
local prevCamCFrame = nil
local renderConn    = nil
local scrollConn    = nil

-- internal camera state
local camCF   = CFrame.new(0, 10, 0)   -- current camera CFrame
local pitch   = 0                       -- vertical look angle (radians)
local yaw     = 0                       -- horizontal look angle (radians)
local lastMouse = nil                   -- Vector2 mouse position last frame

local SHIFT_MULT = 0.25   -- speed multiplier when shift held
local MAX_PITCH  = math.rad(89)

local function updateFromCF(cf)
    -- decompose current CFrame to extract yaw/pitch so mouse delta works correctly
    local _, ry, _ = cf:ToEulerAnglesYXZ()
    local look = cf.LookVector
    pitch = math.asin(-look.Y)
    yaw   = ry
    camCF = cf
end

function FreeCam:Enable()
    if self.Enabled then return end
    self.Enabled = true

    camera = workspace.CurrentCamera

    -- save & override camera type
    prevCamType   = camera.CameraType
    prevCamCFrame = camera.CFrame
    camera.CameraType = Enum.CameraType.Scriptable

    -- start from where the camera currently is
    updateFromCF(camera.CFrame)

    -- hide mouse cursor change — we use RMB drag for look
    -- (no cursor lock needed; just capture delta while RMB held)

    renderConn = RunService.RenderStepped:Connect(function(dt)
        if not self.Enabled then return end

        -- ── mouse look (RMB held) ─────────────────────────────────────────
        local rmb = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if rmb then
            local delta = UIS:GetMouseDelta()
            yaw   = yaw   - math.rad(delta.X * 0.3)
            pitch = pitch - math.rad(delta.Y * 0.3)
            pitch = math.clamp(pitch, -MAX_PITCH, MAX_PITCH)
        end

        -- ── build orientation ─────────────────────────────────────────────
        local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
        local fwd   = rot.LookVector
        local right = rot.RightVector

        -- ── movement ──────────────────────────────────────────────────────
        local speed = self.Speed
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
            speed = speed * SHIFT_MULT
        end

        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + fwd  end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - fwd  end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space) then
            move = move + Vector3.new(0, 1, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.Q) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            move = move + Vector3.new(0, -1, 0)
        end

        if move.Magnitude > 0 then move = move.Unit end
        local pos = camCF.Position + move * speed * dt

        camCF             = CFrame.new(pos) * rot
        camera.CFrame     = camCF
    end)

    -- scroll to adjust speed
    scrollConn = UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self.Speed = math.clamp(self.Speed + input.Position.Z * 5, 5, 500)
        end
    end)
end

function FreeCam:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    if renderConn then renderConn:Disconnect(); renderConn = nil end
    if scrollConn then scrollConn:Disconnect(); scrollConn = nil end

    -- restore camera
    camera = workspace.CurrentCamera
    if prevCamType then
        camera.CameraType = prevCamType
        prevCamType = nil
    end
    -- return to character camera
    if lp.Character then
        camera.CameraSubject = lp.Character:FindFirstChildOfClass("Humanoid") or lp.Character:FindFirstChild("HumanoidRootPart")
    end
end

function FreeCam:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function FreeCam:SetSpeed(s)
    self.Speed = s
end

return FreeCam
