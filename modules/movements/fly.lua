-- Leon X | Fly Module
-- PC:     WASD + Space/E naik + Q/Ctrl turun
--         RMB tahan + W/S = ikut pitch kamera
-- Mobile: thumbstick (MoveDirection) untuk horizontal
--         Virtual buttons untuk naik/turun (improved UX)

local Fly = {}
Fly.Name    = "Fly"
Fly.Enabled = false
Fly.Speed   = 60
Fly.SprintMultiplier = 2  -- shift-sprint speed multiplier

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local bv, bg, conn
local pendingSpawn = nil

-- detect platform
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ── Mobile vertical input via on-screen buttons ───────────────────────────
local verticalInput = 0   -- -1, 0, or 1
local sprintInput   = false  -- mobile sprint button state
local flyGui        = nil

local function buildFlyButtons()
    if flyGui then return end
    local gui2 = Instance.new("ScreenGui")
    gui2.Name           = "LeonFlyButtons"
    gui2.ResetOnSpawn   = false
    gui2.DisplayOrder   = 998
    gui2.IgnoreGuiInset = true
    gui2.Parent         = lp:WaitForChild("PlayerGui")
    flyGui = gui2

    local function mkBtn(icon, anchorY, callback)
        local btn = Instance.new("TextButton")
        btn.Size                  = UDim2.new(0, 56, 0, 56)
        btn.AnchorPoint           = Vector2.new(1, anchorY)
        btn.Position              = UDim2.new(1, -12, anchorY == 0 and 0.42 or 0.58, 0)
        btn.BackgroundColor3      = Color3.fromRGB(255,255,255)
        btn.BackgroundTransparency = 0.55
        btn.Text                  = icon
        btn.TextSize              = 26
        btn.Font                  = Enum.Font.GothamBold
        btn.TextColor3            = Color3.new(1,1,1)
        btn.AutoButtonColor       = false
        btn.BorderSizePixel       = 0
        btn.ZIndex                = 10
        btn.Parent                = gui2
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1,0); c.Parent = btn

        btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then
                callback(1)
            end
        end)
        btn.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then
                callback(0)
            end
        end)
        return btn
    end

    mkBtn("▲", 0,   function(v) verticalInput =  v end)
    mkBtn("▼", 1,   function(v) verticalInput = -v end)

    -- Sprint button (bottom-right, above the down button)
    local sprintBtn = Instance.new("TextButton")
    sprintBtn.Size                  = UDim2.new(0, 56, 0, 56)
    sprintBtn.AnchorPoint           = Vector2.new(1, 0.5)
    sprintBtn.Position              = UDim2.new(1, -80, 0.5, 0)
    sprintBtn.BackgroundColor3      = Color3.fromRGB(255, 180, 60)
    sprintBtn.BackgroundTransparency = 0.55
    sprintBtn.Text                  = "⚡"
    sprintBtn.TextSize              = 26
    sprintBtn.Font                  = Enum.Font.GothamBold
    sprintBtn.TextColor3            = Color3.new(1, 1, 1)
    sprintBtn.AutoButtonColor       = false
    sprintBtn.BorderSizePixel       = 0
    sprintBtn.ZIndex                = 10
    sprintBtn.Parent                = gui2
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(1, 0); sc.Parent = sprintBtn

    sprintBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            sprintInput = true
            sprintBtn.BackgroundTransparency = 0.2
        end
    end)
    sprintBtn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            sprintInput = false
            sprintBtn.BackgroundTransparency = 0.55
        end
    end)
end

local function destroyFlyButtons()
    if flyGui then
        pcall(function() flyGui:Destroy() end)
        flyGui = nil
    end
    verticalInput = 0
    sprintInput = false
end

function Fly:Enable()
    -- Error handling: safely get character
    local success, char = pcall(function() return lp.Character end)
    if not success or not char or not char:FindFirstChild("HumanoidRootPart") then
        -- Character not ready yet — auto-enable when it spawns
        self.Enabled = true
        if not pendingSpawn then
            pendingSpawn = lp.CharacterAdded:Connect(function(newChar)
                task.wait(0.5) -- let character fully load
                if pendingSpawn then
                    pendingSpawn:Disconnect()
                    pendingSpawn = nil
                end
                if self.Enabled then
                    self.Enabled = false -- reset so Enable() runs fresh
                    self:Enable()
                end
            end)
        end
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Cancel any pending spawn connection
    if pendingSpawn then
        pendingSpawn:Disconnect()
        pendingSpawn = nil
    end

    self.Enabled = true

    -- Ensure speed is valid
    if not self.Speed or self.Speed < 10 then self.Speed = 60 end

    -- Build on-screen up/down buttons for mobile
    if isMobile then buildFlyButtons() end

    -- Safely configure humanoid physics for smooth flight
    pcall(function()
        hum.AutoRotate = false
        hum.PlatformStand = true
    end)

    -- Cleanup old connections to prevent duplicates
    if conn then pcall(function() conn:Disconnect() end) end
    if bv then pcall(function() bv:Destroy() end) end
    if bg then pcall(function() bg:Destroy() end) end

    -- High-power BodyVelocity for instantaneous and responsive flight
    local bv_ok = pcall(function()
        bv           = Instance.new("BodyVelocity")
        bv.Velocity  = Vector3.zero
        bv.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
        bv.P         = 1e5
        bv.Parent    = hrp
    end)

    local bg_ok = pcall(function()
        bg           = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P         = 3e4
        bg.D         = 500
        bg.CFrame    = hrp.CFrame
        bg.Parent    = hrp
    end)

    if not bv_ok or not bg_ok then
        self:Disable()
        return
    end

    conn = RunService.RenderStepped:Connect(function()
        pcall(function()
            local c2  = lp.Character
            if not c2 then return end
            local h2  = c2:FindFirstChild("HumanoidRootPart")
            if not h2 then return end
            local hm2 = c2:FindFirstChildOfClass("Humanoid")
            if not hm2 then return end
            if not bv or not bg then return end

            -- Keep PlatformStand enabled while flying
            if not hm2.PlatformStand then
                hm2.PlatformStand = true
            end

            local cam = workspace.CurrentCamera
            local cf  = cam.CFrame
            local dir = Vector3.zero

            if isMobile then
                -- ── Mobile: pakai MoveDirection dari thumbstick ───────────────────
                local md = hm2.MoveDirection
                if md.Magnitude > 0.01 then
                    local flat  = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
                    local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
                    if flat.Magnitude  > 0.01 then flat  = flat.Unit  end
                    if right.Magnitude > 0.01 then right = right.Unit end
                    local fwd = md.Magnitude > 0 and md.Unit or Vector3.zero
                    local dot_f = fwd:Dot(flat)
                    local dot_r = fwd:Dot(right)
                    dir = dir + flat * dot_f + right * dot_r
                end

                if verticalInput ~= 0 then
                    dir = dir + Vector3.new(0, verticalInput, 0)
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

            -- Sprint boost: Shift on PC, sprint button on mobile
            local sprinting = false
            if isMobile then
                sprinting = sprintInput
            else
                sprinting = UIS:IsKeyDown(Enum.KeyCode.LeftShift)
            end
            local finalSpeed = sprinting and (self.Speed * self.SprintMultiplier) or self.Speed

            bv.Velocity = dir * finalSpeed

            -- Gyro orientation
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

    -- Cancel pending spawn connection
    if pendingSpawn then
        pendingSpawn:Disconnect()
        pendingSpawn = nil
    end

    -- Destroy mobile fly buttons
    if isMobile then destroyFlyButtons() end

    -- Safely restore humanoid state
    pcall(function()
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.AutoRotate = true
                hum.PlatformStand = false
            end
        end
    end)

    -- Cleanup physics & connection
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
    if type(s) == "number" and s >= 10 then
        self.Speed = s
    end
end

return Fly
