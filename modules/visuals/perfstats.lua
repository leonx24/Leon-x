-- Leon X | PerfStats
-- Persistent HUD overlay: FPS, frame time (ms), ping, and player count
-- Auto-shown on script execute; can be toggled via UI

local PerfStats = {}
PerfStats.Name    = "PerfStats"
PerfStats.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats      = game:GetService("Stats")
local lp         = Players.LocalPlayer

local gui        = nil
local updateConn = nil

-- rolling FPS average over N samples
local FPS_SAMPLES = 20
local fpsBuf = {}
local fpsIdx = 1
for i = 1, FPS_SAMPLES do fpsBuf[i] = 60 end

local function avg(t)
    local s = 0
    for _, v in ipairs(t) do s = s + v end
    return s / #t
end

local function buildGui()
    -- destroy old gui if it exists
    pcall(function()
        local old = lp:WaitForChild("PlayerGui"):FindFirstChild("LeonStats")
        if old then old:Destroy() end
    end)

    local pg = lp:WaitForChild("PlayerGui")

    local sg = Instance.new("ScreenGui")
    sg.Name           = "LeonStats"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 999
    sg.IgnoreGuiInset = true
    sg.Parent         = pg

    -- pill background
    local pill = Instance.new("Frame")
    pill.Name               = "Pill"
    pill.BackgroundColor3   = Color3.fromRGB(8, 8, 8)
    pill.BackgroundTransparency = 0.25
    pill.BorderSizePixel    = 0
    pill.AnchorPoint        = Vector2.new(0, 0)
    pill.Position           = UDim2.new(0, 10, 0, 10)
    pill.Size               = UDim2.new(0, 280, 0, 26)
    pill.Parent             = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent       = pill

    local stroke = Instance.new("UIStroke")
    stroke.Color       = Color3.fromRGB(50, 50, 50)
    stroke.Thickness   = 1
    stroke.Transparency = 0.5
    stroke.Parent      = pill

    -- label inside pill
    local label = Instance.new("TextLabel")
    label.Name            = "Stats"
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Size            = UDim2.new(1, -8, 1, 0)
    label.Position        = UDim2.new(0, 8, 0, 0)
    label.Font            = Enum.Font.Code
    label.TextSize        = 13
    label.TextColor3      = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment  = Enum.TextXAlignment.Left
    label.TextYAlignment  = Enum.TextYAlignment.Center
    label.Text            = "Loading..."
    label.Parent          = pill

    gui = sg
    return label
end

function PerfStats:Enable()
    if self.Enabled then return end
    self.Enabled = true

    local label = buildGui()

    local tick0  = tick()
    local frames = 0

    if updateConn then updateConn:Disconnect(); updateConn = nil end

    updateConn = RunService.RenderStepped:Connect(function(dt)
        if not self.Enabled then return end
        if not label or not label.Parent then return end

        -- FPS rolling average
        local instantFps = dt > 0 and (1 / dt) or 0
        fpsBuf[fpsIdx] = instantFps
        fpsIdx = (fpsIdx % FPS_SAMPLES) + 1
        local fps = math.floor(avg(fpsBuf) + 0.5)

        -- frame time in ms
        local ms = math.floor(dt * 1000 + 0.5)

        -- ping via Stats service (may be 0 in Studio)
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
        end)

        -- player count
        local playerCount = #Players:GetPlayers()

        -- color-code FPS
        local fpsColor
        if fps >= 50 then
            fpsColor = "rgb(100,220,100)"   -- green
        elseif fps >= 30 then
            fpsColor = "rgb(255,200,50)"    -- yellow
        else
            fpsColor = "rgb(220,80,80)"     -- red
        end

        -- rich text label
        label.RichText = true
        label.Text = string.format(
            '<font color="%s">%d FPS</font>  <font color="rgb(180,180,180)">%d ms</font>  <font color="rgb(120,180,255)">%d ms ping</font>  <font color="rgb(200,200,200)">%d players</font>',
            fpsColor, fps, ms, ping, playerCount
        )
    end)
end

function PerfStats:Disable()
    self.Enabled = false
    if updateConn then updateConn:Disconnect(); updateConn = nil end
    if gui then
        pcall(function() gui:Destroy() end)
        gui = nil
    end
end

function PerfStats:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return PerfStats
