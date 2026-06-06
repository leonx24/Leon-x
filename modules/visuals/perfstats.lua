-- Leon X | PerfStats
-- HUD overlay: FPS, frame time (ms), ping, player count — center top

local PerfStats = {}
PerfStats.Name    = "PerfStats"
PerfStats.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local gui        = nil
local updateConn = nil

local FPS_SAMPLES = 20
local fpsBuf      = {}
local fpsIdx      = 1
for i = 1, FPS_SAMPLES do fpsBuf[i] = 60 end

local function bufAvg()
    local s = 0
    for i = 1, FPS_SAMPLES do s = s + fpsBuf[i] end
    return s / FPS_SAMPLES
end

local function getPing()
    local ok, val = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return (ok and type(val) == "number") and math.floor(val + 0.5) or 0
end

local function buildGui()
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end

    pcall(function()
        local old = pg:FindFirstChild("LeonStats")
        if old then old:Destroy() end
    end)

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name           = "LeonStats"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 999
    sg.IgnoreGuiInset = true
    sg.Parent         = pg

    -- fullscreen transparent container so UDim2 scale is always relative to full viewport
    local root = Instance.new("Frame")
    root.Name                    = "Root"
    root.Size                    = UDim2.new(1, 0, 1, 0)
    root.Position                = UDim2.new(0, 0, 0, 0)
    root.BackgroundTransparency  = 1
    root.BorderSizePixel         = 0
    root.Parent                  = sg

    -- pill: anchor center-top, positioned at top center
    local pill = Instance.new("Frame")
    pill.Name                   = "Pill"
    pill.BackgroundColor3       = Color3.fromRGB(8, 8, 8)
    pill.BackgroundTransparency = 0.2
    pill.BorderSizePixel        = 0
    pill.AnchorPoint            = Vector2.new(0.5, 0)
    pill.Position               = UDim2.new(0.5, 0, 0, 10)
    pill.Size                   = UDim2.new(0, 380, 0, 26)
    pill.Parent                 = root

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
    label.Size                   = UDim2.new(1, 0, 1, 0)
    label.Position               = UDim2.new(0, 0, 0, 0)
    label.Font                   = Enum.Font.Code
    label.TextSize               = 13
    label.TextColor3             = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment         = Enum.TextXAlignment.Center
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

    local label = buildGui()
    if not label then
        -- PlayerGui not ready yet, wait one frame
        task.spawn(function()
            local attempts = 0
            while not label and attempts < 60 do
                task.wait(0.1)
                attempts = attempts + 1
                label = buildGui()
            end
            if label and self.Enabled then
                self:_startLoop(label)
            else
                self.Enabled = false
            end
        end)
        return
    end
    self:_startLoop(label)
end

function PerfStats:_startLoop(label)
    if updateConn then updateConn:Disconnect(); updateConn = nil end

    local pingCache = 0
    local pingTick  = 0

    updateConn = RunService.RenderStepped:Connect(function(dt)
        if not self.Enabled then return end
        if not label or not label.Parent then return end

        fpsBuf[fpsIdx] = dt > 0 and (1 / dt) or 0
        fpsIdx = (fpsIdx % FPS_SAMPLES) + 1
        local fps = math.floor(bufAvg() + 0.5)
        local ms  = math.floor(dt * 1000 + 0.5)

        pingTick = pingTick + 1
        if pingTick >= 30 then
            pingCache = getPing()
            pingTick  = 0
        end

        local pc = #Players:GetPlayers()

        -- local clock (HH:MM)
        local t = os.date("*t")
        local clock = string.format("%02d:%02d", t.hour, t.min)

        local fc
        if fps >= 50 then fc = "rgb(100,220,100)"
        elseif fps >= 30 then fc = "rgb(255,200,50)"
        else fc = "rgb(220,80,80)" end

        label.Text = string.format(
            '<font color="%s">%d FPS</font>  '..
            '<font color="rgb(170,170,170)">%d ms</font>  '..
            '<font color="rgb(110,170,255)">%d ms ping</font>  '..
            '<font color="rgb(190,190,190)">%d players</font>  '..
            '<font color="rgb(140,140,140)">%s</font>',
            fc, fps, ms, pingCache, pc, clock
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
