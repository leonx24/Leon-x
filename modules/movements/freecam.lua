-- Leon X | FreeCam
-- Desktop : WASD move | RMB drag = look | E/Space = up | Q/Ctrl = down
--           Shift = slow | Scroll = adjust speed
-- Mobile  : Left thumb joystick (left half of screen) = move + up/down
--           Right thumb swipe (right half of screen)  = look
--           Two-finger pinch on right half            = adjust speed

local FreeCam = {}
FreeCam.Name    = "FreeCam"
FreeCam.Enabled = false
FreeCam.Speed   = 40

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- connections
local renderConn = nil
local scrollConn = nil
local rmbConn    = nil
local rmbEndConn = nil
local touchConns = {}

-- saved state
local prevCamType = nil
local savedWS     = 16
local savedJP     = 50

-- camera state
local camCF    = CFrame.new(0, 10, 0)
local pitch    = 0
local yaw      = 0
local MAX_PITCH = math.rad(89)

-- mobile touch state
-- left half  = move joystick  (trackId → startPos, currentPos)
-- right half = look swipe     (trackId → lastPos)
local moveTouch = nil   -- { id, start, current }
local lookTouch = nil   -- { id, last }

-- on-screen virtual joystick UI
local joystickGui  = nil
local joystickBase = nil
local joystickThumb = nil

local function getVP()
    return workspace.CurrentCamera.ViewportSize
end

local function buildJoystick()
    if joystickGui then return end
    local playerGui = lp:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name             = "FreeCamJoystick"
    sg.ResetOnSpawn     = false
    sg.DisplayOrder     = 50
    sg.IgnoreGuiInset   = true
    sg.Parent           = playerGui
    joystickGui = sg

    -- base ring
    local base = Instance.new("Frame")
    base.Size                  = UDim2.new(0, 100, 0, 100)
    base.AnchorPoint           = Vector2.new(0.5, 0.5)
    base.Position              = UDim2.new(0.18, 0, 0.78, 0)
    base.BackgroundColor3      = Color3.fromRGB(255, 255, 255)
    base.BackgroundTransparency = 0.75
    base.BorderSizePixel       = 0
    base.Parent                = sg
    local c1 = Instance.new("UICorner")
    c1.CornerRadius = UDim.new(1, 0)
    c1.Parent = base
    joystickBase = base

    -- thumb dot
    local thumb = Instance.new("Frame")
    thumb.Size                  = UDim2.new(0, 40, 0, 40)
    thumb.AnchorPoint           = Vector2.new(0.5, 0.5)
    thumb.Position              = UDim2.new(0.5, 0, 0.5, 0)
    thumb.BackgroundColor3      = Color3.fromRGB(255, 255, 255)
    thumb.BackgroundTransparency = 0.45
    thumb.BorderSizePixel       = 0
    thumb.Parent                = base
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(1, 0)
    c2.Parent = thumb
    joystickThumb = thumb
end

local function destroyJoystick()
    if joystickGui then
        pcall(function() joystickGui:Destroy() end)
        joystickGui   = nil
        joystickBase  = nil
        joystickThumb = nil
    end
end

local function updateJoystickThumb(dx, dy)
    if not joystickThumb then return end
    local maxR = 30  -- max offset in pixels
    local len  = math.sqrt(dx*dx + dy*dy)
    if len > maxR then
        dx = dx / len * maxR
        dy = dy / len * maxR
    end
    joystickThumb.Position = UDim2.new(0.5, dx, 0.5, dy)
end

local function decomposeCamera(cf)
    local lv = cf.LookVector
    pitch = math.asin(math.clamp(-lv.Y, -1, 1))
    yaw   = math.atan2(-lv.X, -lv.Z)
    camCF = cf
end

local function disableControls()
    local ok = pcall(function()
        local pm = lp:WaitForChild("PlayerScripts", 3)
                    :WaitForChild("PlayerModule", 3)
        local controls = require(pm):GetControls()
        controls:Disable()
    end)
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

-- ── Desktop input ─────────────────────────────────────────────────────────────
local function setupDesktopInput()
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
    scrollConn = UIS.InputChanged:Connect(function(input)
        if not FreeCam.Enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            FreeCam.Speed = math.clamp(FreeCam.Speed + input.Position.Z * 5, 5, 500)
        end
    end)
end

-- ── Mobile touch input ────────────────────────────────────────────────────────
local function setupMobileInput()
    buildJoystick()

    local function isLeftHalf(pos)
        return pos.X < getVP().X * 0.5
    end

    local began = UIS.InputBegan:Connect(function(input, gp)
        if not FreeCam.Enabled then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        -- allow gameProcessed touches so joystick overrides game UI on left side
        local pos = input.Position
        if isLeftHalf(pos) and not moveTouch then
            moveTouch = { id = input, start = pos, current = pos }
        elseif not isLeftHalf(pos) and not lookTouch then
            lookTouch = { id = input, last = pos }
        end
    end)

    local changed = UIS.InputChanged:Connect(function(input)
        if not FreeCam.Enabled then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = input.Position

        if moveTouch and input == moveTouch.id then
            moveTouch.current = pos
            local dx = pos.X - moveTouch.start.X
            local dy = pos.Y - moveTouch.start.Y
            updateJoystickThumb(dx, dy)
        elseif lookTouch and input == lookTouch.id then
            local dx = pos.X - lookTouch.last.X
            local dy = pos.Y - lookTouch.last.Y
            local SENS = 0.007
            yaw   = yaw   - dx * SENS
            pitch = math.clamp(pitch - dy * SENS, -MAX_PITCH, MAX_PITCH)
            lookTouch.last = pos
        end
    end)

    local ended = UIS.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        if moveTouch and input == moveTouch.id then
            moveTouch = nil
            updateJoystickThumb(0, 0)
        elseif lookTouch and input == lookTouch.id then
            lookTouch = nil
        end
    end)

    touchConns = { began, changed, ended }
end

-- ── Main render loop ──────────────────────────────────────────────────────────
local function startRenderLoop()
    renderConn = RunService.RenderStepped:Connect(function(dt)
        if not FreeCam.Enabled then return end
        local camera = workspace.CurrentCamera
        if not camera then return end

        -- ── desktop look (RMB drag) ───────────────────────────────────────────
        if not isMobile and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local d = UIS:GetMouseDelta()
            local SENS = 0.4
            yaw   = yaw   - math.rad(d.X * SENS)
            pitch = math.clamp(pitch - math.rad(d.Y * SENS), -MAX_PITCH, MAX_PITCH)
        end

        local rot   = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
        local fwd   = rot.LookVector
        local right = rot.RightVector
        local spd   = FreeCam.Speed

        -- ── desktop movement ──────────────────────────────────────────────────
        local move = Vector3.zero
        if not isMobile then
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
                spd = spd * 0.25
            end
            if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + fwd          end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - fwd          end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + right        end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - right        end
            if UIS:IsKeyDown(Enum.KeyCode.E)
            or UIS:IsKeyDown(Enum.KeyCode.Space)        then move = move + Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.Q)
            or UIS:IsKeyDown(Enum.KeyCode.LeftControl)  then move = move - Vector3.yAxis end
        end

        -- ── mobile movement (left joystick) ───────────────────────────────────
        if isMobile and moveTouch then
            local dx = moveTouch.current.X - moveTouch.start.X
            local dy = moveTouch.current.Y - moveTouch.start.Y
            local deadzone = 8
            local maxR     = 50
            -- horizontal → strafe / forward
            if math.abs(dx) > deadzone then
                local t = math.clamp(dx / maxR, -1, 1)
                move = move + right * t
            end
            -- vertical → forward / backward
            if math.abs(dy) > deadzone then
                local t = math.clamp(dy / maxR, -1, 1)
                move = move - fwd * t   -- drag down = move forward
            end
        end

        if move.Magnitude > 0 then move = move.Unit end
        camCF         = CFrame.new(camCF.Position + move * spd * dt) * rot
        camera.CFrame = camCF
    end)
end

-- ── Enable / Disable ──────────────────────────────────────────────────────────
function FreeCam:Enable()
    if self.Enabled then return end
    self.Enabled = true

    local cam = workspace.CurrentCamera
    if not cam then self.Enabled = false; return end

    prevCamType    = cam.CameraType
    cam.CameraType = Enum.CameraType.Scriptable
    decomposeCamera(cam.CFrame)

    disableControls()

    if isMobile then
        setupMobileInput()
    else
        setupDesktopInput()
    end
    startRenderLoop()
end

function FreeCam:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    if renderConn  then renderConn:Disconnect();  renderConn  = nil end
    if scrollConn  then scrollConn:Disconnect();  scrollConn  = nil end
    if rmbConn     then rmbConn:Disconnect();     rmbConn     = nil end
    if rmbEndConn  then rmbEndConn:Disconnect();  rmbEndConn  = nil end
    for _, c in ipairs(touchConns) do pcall(function() c:Disconnect() end) end
    touchConns = {}

    moveTouch = nil
    lookTouch = nil
    UIS.MouseBehavior = Enum.MouseBehavior.Default

    destroyJoystick()
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
