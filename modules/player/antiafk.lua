-- Leon X | AntiAFK (optimized — single Heartbeat connection)
-- Multi-layer AFK prevention without FPS impact

local AntiAFK = {}
AntiAFK.Name    = "AntiAFK"
AntiAFK.Enabled = false

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local VU            = game:GetService("VirtualUser")
local lp            = Players.LocalPlayer

local mainConn = nil
local cachedMoveRemote = nil

-- Simulate activity via VirtualUser (lightweight, no scanning)
local function simulateActivity()
    pcall(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end

-- Micro camera jitter (imperceptible)
local function cameraJitter()
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            local currentCF = cam.CFrame
            cam.CFrame = currentCF * CFrame.Angles(0, math.rad(0.01), 0)
            task.wait(0.01)
            cam.CFrame = currentCF
        end
    end)
end

-- Fire cached move remote (NO GetDescendants scan)
local function fireMoveRemote()
    pcall(function()
        if not cachedMoveRemote then
            -- One-time scan to find the move remote
            for _, descendant in pairs(game:GetDescendants()) do
                if descendant:IsA("RemoteEvent") and descendant.Name:lower():find("move") then
                    cachedMoveRemote = descendant
                    break
                end
            end
        end
        if cachedMoveRemote then
            cachedMoveRemote:FireServer()
        end
    end)
end

function AntiAFK:Enable()
    if self.Enabled then return end
    self.Enabled = true

    -- Idle event override (standard anti-AFK)
    pcall(function()
        lp.Idled:Connect(function()
            if not self.Enabled then return end
            simulateActivity()
        end)
    end)

    -- SINGLE Heartbeat connection with timer (no FPS impact)
    local lastActivity = tick()
    local nextInterval = math.random(20, 40)

    if mainConn then mainConn:Disconnect() end
    mainConn = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        local now = tick()
        if now - lastActivity < nextInterval then return end
        lastActivity = now
        nextInterval = math.random(20, 40)

        -- Rotate between methods
        local method = math.random(1, 3)
        if method == 1 then
            simulateActivity()
        elseif method == 2 then
            simulateActivity()
            cameraJitter()
        else
            simulateActivity()
            fireMoveRemote()
        end
    end)
end

function AntiAFK:Disable()
    self.Enabled = false
    if mainConn then mainConn:Disconnect(); mainConn = nil end
end

function AntiAFK:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return AntiAFK
