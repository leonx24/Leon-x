-- Leon X | FreeCam
-- Detaches camera — WASD moves camera, character stays frozen
-- RMB + drag = look | E/Space = up | Q/Ctrl = down | Shift = slow | Scroll = speed

local FreeCam = {}
FreeCam.Name    = "FreeCam"
FreeCam.Enabled = false
FreeCam.Speed   = 40

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local renderConn = nil
local scrollConn = nil
local rmbConn    = nil
local rmbEndConn = nil

local prevCamType  = nil
local savedWS      = 16
local savedJP      = 50

-- camera state
local camCF    = CFrame.new(0, 10, 0)
local pitch    = 0
local yaw      = 0
local MAX_PITCH = math.rad(89)
local SENS      = 0.4

local function decomposeCamera(cf)
    local lv = cf.LookVector
    pitch = math.asin(math.clamp(-lv.Y, -1, 1))
    yaw   = math.atan2(-lv.X, -lv.Z)
    camCF = cf
end

-- Block character movement by disabling PlayerModule controls
-- This is the reliable way — PlayerModule is a LocalScript under PlayerScripts
local function disableControls()
    local ok = pcall(function()
        local pm = lp:WaitForChild("PlayerScripts", 3)
                    :WaitForChild("PlayerModule", 3)
        local controls = require(pm):GetControls()
        controls:Disable()
    end)
    -- fallback if require not allowed: zero walkspeed + anchor HRP
    if not ok then
        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            savedWS = hum.WalkSpeed
            savedJP = hum.JumpPower
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end
        if hrp then hrp.Anchored = true end
    end
end

local function enableControls()
    local ok = pcall(function()
        local pm = lp:WaitForChild("PlayerScripts", 3)
                    :WaitForChild("PlayerModule", 3)
        local controls = require(pm):GetControls()
        controls:Enable()
    end)
    if not ok then
        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.Anchored = false end
        if hum then
            hum.WalkSpeed = savedWS
            hum.JumpPower = savedJP
        end
    end
end

function FreeCam:Enable()
    if self.Enabled then return end
    self.Enabled = true

    local cam = workspace.CurrentCamera
    if not cam then self.Enabled = false; return end

    prevCamType       = cam.CameraType
    cam.CameraType    = Enum.CameraType.Scriptable
    decomposeCamera(cam.CFrame)

    -- stop character from moving
    disableControls()

    -- RMB lock for mouse delta
    rmbConn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end)
    rmbEndConn = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

    -- scroll = speed
    scrollConn = UIS.InputChanged:Connect(function(input)
        if not self.Enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self.Speed = math.clamp(self.Speed + input.Position.Z * 5, 5, 500)
        end
    end)

    -- main loop
    renderConn = RunService.RenderStepped:Connect(function(dt)
        if not self.Enabled then return end
        local camera = workspace.CurrentCamera
        if not camera then return end

        -- look
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local d = UIS:GetMouseDelta()
            yaw   = yaw   - math.rad(d.X * SENS)
            pitch = math.clamp(pitch - math.rad(d.Y * SENS), -MAX_PITCH, MAX_PITCH)
        end

        local rot   = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
        local fwd   = rot.LookVector
        local right = rot.RightVector

        -- speed
        local spd = self.Speed
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
            spd = spd * 0.25
        end

        -- movement (consume input so it doesn't reach character)
        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + fwd          end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - fwd          end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + right        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - right        end
        if UIS:IsKeyDown(Enum.KeyCode.E)
        or UIS:IsKeyDown(Enum.KeyCode.Space)        then move = move + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.Q)
        or UIS:IsKeyDown(Enum.KeyCode.LeftControl)  then move = move - Vector3.yAxis end

        if move.Magnitude > 0 then move = move.Unit end
        camCF          = CFrame.new(camCF.Position + move * spd * dt) * rot
        camera.CFrame  = camCF
    end)
end

function FreeCam:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    if renderConn  then renderConn:Disconnect();  renderConn  = nil end
    if scrollConn  then scrollConn:Disconnect();  scrollConn  = nil end
    if rmbConn     then rmbConn:Disconnect();     rmbConn     = nil end
    if rmbEndConn  then rmbEndConn:Disconnect();  rmbEndConn  = nil end

    UIS.MouseBehavior = Enum.MouseBehavior.Default

    enableControls()

    local cam = workspace.CurrentCamera
    if cam then
        cam.CameraType = prevCamType or Enum.CameraType.Custom
        local char = lp.Character
        if char then
            local subj = char:FindFirstChildOfClass("Humanoid")
                      or char:FindFirstChild("HumanoidRootPart")
            if subj then cam.CameraSubject = subj end
        end
    end

    prevCamType = nil
end

function FreeCam:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function FreeCam:SetSpeed(s)
    self.Speed = s
end

return FreeCam
