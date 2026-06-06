-- Leon X | PerfStats
-- Persistent HUD overlay: FPS, frame time (ms), ping, player count
-- Shown automatically on script execute; toggle from Visual tab

local PerfStats = {}
PerfStats.Name    = "PerfStats"
PerfStats.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local gui        = nil
local updateConn = nil

-- rolling FPS buffer (20 samples)
local FPS_SAMPLES = 20
local fpsBuf      = {}
local fpsIdx      = 1
for i = 1, FPS_SAMPLES do fpsBuf[i] = 60 end

local function bufAvg()
    local s = 0
    for _, v in ipairs(fpsBuf) do s = s + v end
    return s / FPS_SAMPLES
end

-- ping via network stats — works in live game, returns 0 in Studio
local function getPing()
    local ok, val = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and val then return math.floor(val + 0.5) end
    -- fallback: some executors expose this global
    local ok2, val2 = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Received"]:GetValue() end)
    return 0
end

local function buildGui()
    -- safe parent wait with timeout
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then
        local ok
        ok, pg = pcall(function() return lp:WaitForChild("PlayerGui", 5) end)
        if not ok or not pg then return nil end
    end

    -- destroy any previous instance
    pcall(function()
        local old = pg:FindFirstChild("LeonStats")
        if old then old:Destroy() end
    end)

    local sg = Instance.new("ScreenGui")
    sg.Name                = "LeonStats"
    sg.ResetOnSpawn        = false
    sg.ZIndexBehavior      = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder        = 999
    sg.IgnoreGuiInset      = true
    sg.Parent              = pg

    -- dark pill
    local pill = Instance.new("Frame")
    pill.Name                    = "Pill"
    pill.BackgroundColor3        = Color3.fromRGB(8, 8, 8)
    pill.BackgroundTransparency  = 0.2
    pill.BorderSizePixel         = 0
    pill.AnchorPoint             = Vector2.new(0, 0)
    pill.Position                = UDim2.new(0, 10, 0, 10)
    pill.Size                    = UDim2.new(0, 300, 0, 26)
    pill.Parent                  = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent       = pill

    local stroke = Instance.new("UIStroke")
    stroke.Color        = Color3.fromRGB(60, 60, 60)
    stroke.Thickness    = 1
    stroke.Transparency = 0.4
    stroke.Parent       = pill

    local label = Instance.new("TextLabel")
    label.Name                   = "Stats"
    label.BackgroundTransparency = 1
    label.BorderSizePixel        = 0
    label.Size                   = UDim2.new(1, -10, 1, 0)
    label.Position               = UDim2.new(0, 8, 0, 0)
    label.Font                   = Enum.Font.Code
    label.TextSize               = 13
    label.TextColor3             = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.TextYAlignment         = Enum.TextYAlignment.Center
    label.RichText               = true
    label.Text                   = "..."
    label.Parent                 = pill

    gui = sg
    return label
end

function PerfStats:Enable()
    if self.Enabled then return end
    self.Enabled = true

    -- build GUI; if PlayerGui not ready yet, retry after a tick
    local label = buildGui()
    if not label then
        task.defer(function()
            if not self.Enabled then return end
            label = buildGui()
            if not label then self.Enabled = false; return end
            self:_startLoop(label)
        end)
        return
    end
    self:_startLoop(label)
end

function PerfStats:_startLoop(label)
    if updateConn then updateConn:Disconnect(); updateConn = nil end

    -- ping throttle — only read every 30 frames (expensive pcall)
    local pingCache  = 0
    local pingTick   = 0

    updateConn = RunService.RenderStepped:Connect(function(dt)
        if not self.Enabled then return end
        if not label or not label.Parent then return end

        -- FPS rolling average
        fpsBuf[fpsIdx] = dt > 0 and (1 / dt) or 0
        fpsIdx = (fpsIdx % FPS_SAMPLES) + 1
        local fps = math.floor(bufAvg() + 0.5)

        -- frame time ms
        local ms = math.floor(dt * 1000 + 0.5)

        -- ping (throttled)
        pingTick = pingTick + 1
        if pingTick >= 30 then
            pingCache = getPing()
            pingTick  = 0
        end

        -- player count
        local pc = #Players:GetPlayers()

        -- FPS color
        local fc
        if fps >= 50 then fc = "rgb(100,220,100)"
        elseif fps >= 30 then fc = "rgb(255,200,50)"
        else fc = "rgb(220,80,80)" end

        label.Text = string.format(
            '<font color="%s">%d FPS</font>  '..
            '<font color="rgb(170,170,170)">%d ms</font>  '..
            '<font color="rgb(110,170,255)">%d ms ping</font>  '..
            '<font color="rgb(190,190,190)">%d players</font>',
            fc, fps, ms, pingCache, pc
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
