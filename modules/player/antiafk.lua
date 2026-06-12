-- Leon X | AntiAFK
-- Multi-layer AFK prevention with aggressive bypass techniques

local AntiAFK = {}
AntiAFK.Name    = "AntiAFK"
AntiAFK.Enabled = false

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local VU            = game:GetService("VirtualUser")
local UIS           = game:GetService("UserInputService")
local GuiService    = game:GetService("GuiService")
local lp            = Players.LocalPlayer

local conn1, conn2, conn3, conn4
local lastAction    = 0
local idleConn

-- Multi-method anti-AFK approaches
local methods = {
    -- Method 1: VirtualUser CaptureController (classic)
    captureController = function()
        pcall(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end,

    -- Method 2: Virtual button presses
    virtualButton = function()
        pcall(function()
            VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.05)
            VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end,

    -- Method 3: Humanoid state manipulation
    humanoidJitter = function()
        pcall(function()
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end

            -- Micro movement to simulate activity
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local currentCF = rootPart.CFrame
                rootPart.CFrame = currentCF * CFrame.new(0, 0.001, 0)
                task.wait(0.01)
                rootPart.CFrame = currentCF
            end
        end)
    end,

    -- Method 4: Camera jitter (very subtle)
    cameraJitter = function()
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                local currentCF = cam.CFrame
                cam.CFrame = currentCF * CFrame.Angles(0, math.rad(0.01), 0)
                task.wait(0.01)
                cam.CFrame = currentCF
            end
        end)
    end,

    -- Method 5: Remote event spammer (for games that track remote calls)
    remoteActivity = function()
        pcall(function()
            -- Fire random RemoteEvents to simulate activity
            for _, descendant in pairs(game:GetDescendants()) do
                if descendant:IsA("RemoteEvent") and descendant.Name:lower():find("move") then
                    descendant:FireServer()
                    break
                end
            end
        end)
    end
}

function AntiAFK:Enable()
    if self.Enabled then return end
    self.Enabled = true
    lastAction = tick()

    -- Connection 1: Idle event override (highest priority)
    pcall(function()
        idleConn = lp.Idled:Connect(function()
            if not self.Enabled then return end
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end)
    end)

    -- Connection 2: Fast heartbeat (every 15 seconds - aggressive)
    conn1 = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        if tick() - lastAction >= 15 then
            lastAction = tick()
            methods.captureController()
            methods.virtualButton()
        end
    end)

    -- Connection 3: Medium interval (every 30 seconds)
    conn2 = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        if tick() - lastAction >= 30 then
            methods.humanoidJitter()
        end
    end)

    -- Connection 4: Camera + remote activity (every 45 seconds)
    conn3 = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        if tick() - lastAction >= 45 then
            methods.cameraJitter()
            methods.remoteActivity()
        end
    end)

    -- Connection 5: Random interval activity (20-40 seconds random)
    conn4 = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        local randomInterval = math.random(20, 40)
        if tick() - lastAction >= randomInterval then
            -- Randomize method to avoid pattern detection
            local methodList = {"captureController", "virtualButton", "humanoidJitter"}
            local randomMethod = methodList[math.random(1, #methodList)]
            methods[randomMethod]()
        end
    end)
end

function AntiAFK:Disable()
    self.Enabled = false

    if idleConn then idleConn:Disconnect(); idleConn = nil end
    if conn1 then conn1:Disconnect(); conn1 = nil end
    if conn2 then conn2:Disconnect(); conn2 = nil end
    if conn3 then conn3:Disconnect(); conn3 = nil end
    if conn4 then conn4:Disconnect(); conn4 = nil end
end

function AntiAFK:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return AntiAFK
