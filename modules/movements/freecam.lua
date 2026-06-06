-- Leon X | FreeCam
-- Detaches camera from character — WASD to move, RMB + drag to look
-- E/Space = up | Q/Ctrl = down | Shift = slow | Scroll = adjust speed

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

local prevCamType    = nil
local prevMouseBeh   = nil

-- freeze character so WASD doesn't move it
local frozenConn     = nil
local frozenCFrame   = nil

local function freezeCharacter()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    frozenCFrame = hrp.CFrame

    hum.WalkSpeed    = 0
    hum.JumpPower    = 0
    hum.AutoRotate   = false
    hrp.Anchored     = true

    -- disable humanoid entirely so PlayerModule stops sending movement
    hum:ChangeState(Enum.HumanoidStateType.Physics)
end

local function unfreezeCharacter()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp then hrp.Anchored = false end
    if hum then
        hum.WalkSpeed  = 16
        hum.JumpPower  = 50
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    frozenCFrame = nil
end

-- camera state
local camCF     = CFrame.new(0, 10, 0)
local pitch     = 0
local yaw       = 0

local SHIFT_MULT = 0.25
local MAX_PITCH  = math.rad(89)
local SENS       = 0.35   -- mouse sensitivity (degrees per pixel)

-- decompose a CFrame into our pitch/yaw representation
local function decomposeCamera(cf)
    local lv    = cf.LookVector
    pitch       = math.asin(math.clamp(-lv.Y, -1, 1))
    yaw         = math.atan2(-lv.X, -lv.Z)
    camCF       = cf
end

-- called each frame to write back to the camera
local function applyCamera()
    local camera = workspace.CurrentCamera
    if camera then
        camera.CFrame = camCF
    end
end

function FreeCam:Enable()
    if self.Enabled then return end
    self.Enabled = true

    local camera = workspace.CurrentCamera
    if not camera then self.Enabled = false; return end

    -- save state
    prevCamType  = camera.CameraType
    prevMouseBeh = UIS.MouseBehavior

    -- start from current camera position
    decomposeCamera(camera.CFrame)

    -- override camera
    camera.CameraType = Enum.CameraType.Scriptable

    -- freeze character so WASD doesn't move it
    freezeCharacter()

    -- RMB: lock mouse while held for delta reads
    rmbConn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    end)

    local rmbEndConn
    rmbEndConn = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end)

    -- store both so we can disconnect later
    -- wrap them together via a table
    FreeCam._rmbEnd = rmbEndConn

    -- scroll to change speed
    scrollConn = UIS.InputChanged:Connect(function(input)
        if not self.Enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self.Speed = math.clamp(self.Speed + input.Position.Z * 5, 5, 500)
        end
    end)

    -- main render loop
    renderConn = RunService.RenderStepped:Connect(function(dt)
        if not self.Enabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end

        -- mouse look only while RMB held
        local rmb = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if rmb then
            local delta = UIS:GetMouseDelta()  -- only non-zero when mouse is locked
            yaw   = yaw   - math.rad(delta.X * SENS)
            pitch = math.clamp(pitch - math.rad(delta.Y * SENS), -MAX_PITCH, MAX_PITCH)
        end

        -- rebuild orientation from yaw + pitch
        local rot   = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
        local fwd   = rot.LookVector
        local right = rot.RightVector

        -- movement
        local speed = self.Speed
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
            speed = speed * SHIFT_MULT
        end

        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + fwd         end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - fwd         end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + right       end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - right       end
        if UIS:IsKeyDown(Enum.KeyCode.E)
        or UIS:IsKeyDown(Enum.KeyCode.Space)     then move = move + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.Q)
        or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.yAxis end

        if move.Magnitude > 0 then move = move.Unit end

        local newPos = camCF.Position + move * speed * dt
        camCF        = CFrame.new(newPos) * rot
        cam.CFrame   = camCF
    end)
end

function FreeCam:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    -- disconnect all
    if renderConn      then renderConn:Disconnect();      renderConn      = nil end
    if scrollConn      then scrollConn:Disconnect();      scrollConn      = nil end
    if rmbConn         then rmbConn:Disconnect();         rmbConn         = nil end
    if FreeCam._rmbEnd then FreeCam._rmbEnd:Disconnect(); FreeCam._rmbEnd = nil end

    -- unfreeze character
    unfreezeCharacter()

    -- restore mouse
    UIS.MouseBehavior = Enum.MouseBehavior.Default

    -- restore camera
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = prevCamType or Enum.CameraType.Custom
        local char = lp.Character
        if char then
            local subj = char:FindFirstChildOfClass("Humanoid")
                      or char:FindFirstChild("HumanoidRootPart")
            if subj then
                camera.CameraSubject = subj
            end
        end
    end

    prevCamType  = nil
    prevMouseBeh = nil
end

function FreeCam:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function FreeCam:SetSpeed(s)
    self.Speed = s
end

return FreeCam
