-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Leon X  |  Performance HUD Overlay v5                           ║
-- ║  "Segmented Dark Glass HUD with Realtime FPS, Ping & Stats"      ║
-- ╚══════════════════════════════════════════════════════════════════╝

local PerfStats = {}
PerfStats.Name    = "PerfStats"
PerfStats.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats      = game:GetService("Stats")
local UIS        = game:GetService("UserInputService")
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
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return (ok and type(val) == "number") and math.floor(val + 0.5) or 0
end

local function buildGui()
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end

    pcall(function()
        local old = pg:FindFirstChild("LeonStatsHUD")
        if old then old:Destroy() end
    end)

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name           = "LeonStatsHUD"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 9999
    sg.IgnoreGuiInset = true
    sg.Parent         = pg

    -- Fullscreen container
    local root = Instance.new("Frame")
    root.Name                   = "Root"
    root.Size                   = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.BorderSizePixel        = 0
    root.Parent                 = sg

    -- Main HUD Bar (Glass Pill Container)
    local bar = Instance.new("Frame")
    bar.Name                   = "HUDBar"
    bar.BackgroundColor3       = Color3.fromRGB(12, 12, 18)
    bar.BackgroundTransparency = 0.15
    bar.BorderSizePixel        = 0
    bar.AnchorPoint            = Vector2.new(0.5, 0)
    bar.Position               = UDim2.new(0.5, 0, 0, 10)
    bar.Size                   = UDim2.new(0, 460, 0, 32)
    bar.Active                 = true
    bar.Parent                 = root

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 10)
    barCorner.Parent       = bar

    local barStroke = Instance.new("UIStroke")
    barStroke.Color        = Color3.fromRGB(38, 38, 54)
    barStroke.Thickness    = 1.2
    barStroke.Transparency = 0.2
    barStroke.Parent       = bar

    -- Subtle Ambient Gradient
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 14)),
    })
    grad.Rotation = 90
    grad.Parent = bar

    -- Horizontal Layout for Cards
    local layout = Instance.new("UIListLayout")
    layout.FillDirection        = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment    = Enum.VerticalAlignment.Center
    layout.SortOrder            = Enum.SortOrder.LayoutOrder
    layout.Padding              = UDim.new(0, 8)
    layout.Parent               = bar

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 8)
    pad.PaddingRight  = UDim.new(0, 8)
    pad.Parent        = bar

    -- Segment Creation Helper
    local function mkSegment(order, width, titleText)
        local card = Instance.new("Frame")
        card.Size                = UDim2.new(0, width, 0, 22)
        card.BackgroundColor3    = Color3.fromRGB(20, 20, 30)
        card.BackgroundTransparency = 0.2
        card.BorderSizePixel     = 0
        card.LayoutOrder         = order
        card.Parent              = bar

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 6)
        cCorner.Parent       = card

        local cStroke = Instance.new("UIStroke")
        cStroke.Color        = Color3.fromRGB(32, 32, 46)
        cStroke.Thickness    = 1
        cStroke.Parent       = card

        -- Status Indicator Dot (Left)
        local dot = Instance.new("Frame")
        dot.Size             = UDim2.fromOffset(6, 6)
        dot.Position         = UDim2.new(0, 8, 0.5, -3)
        dot.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
        dot.BorderSizePixel  = 0
        dot.Parent           = card

        local dCorner = Instance.new("UICorner")
        dCorner.CornerRadius = UDim.new(1, 0)
        dCorner.Parent       = dot

        -- Stat Value Label
        local lbl = Instance.new("TextLabel")
        lbl.Size                = UDim2.new(1, -20, 1, 0)
        lbl.Position            = UDim2.fromOffset(18, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text                = titleText
        lbl.TextColor3          = Color3.fromRGB(220, 225, 240)
        lbl.TextSize            = 11
        lbl.Font                = Enum.Font.GothamBold
        lbl.TextXAlignment      = Enum.TextXAlignment.Left
        lbl.RichText            = true
        lbl.Parent              = card

        return { Card = card, Dot = dot, Label = lbl }
    end

    local fpsSeg  = mkSegment(1, 88,  "60 FPS")
    local msSeg   = mkSegment(2, 70,  "16 ms")
    local pingSeg = mkSegment(3, 98,  "130 ms ping")
    local pcSeg   = mkSegment(4, 95,  "8 players")
    local timeSeg = mkSegment(5, 68,  "21:30")

    -- Dragging Support
    local dragging, dragStart, startPos = false, nil, nil
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = bar.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            bar.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
            bar.AnchorPoint = Vector2.new(0, 0)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    gui = sg
    return {
        FPS = fpsSeg,
        MS  = msSeg,
        Ping = pingSeg,
        Players = pcSeg,
        Time = timeSeg,
    }
end

function PerfStats:Enable()
    if self.Enabled then return end
    self.Enabled = true

    local components = buildGui()
    if not components then
        task.spawn(function()
            local attempts = 0
            while not components and attempts < 60 do
                task.wait(0.1)
                attempts = attempts + 1
                components = buildGui()
            end
            if components and self.Enabled then
                self:_startLoop(components)
            else
                self.Enabled = false
            end
        end)
        return
    end
    self:_startLoop(components)
end

function PerfStats:_startLoop(comps)
    if updateConn then updateConn:Disconnect(); updateConn = nil end

    local pingCache = 0
    local pingTick  = 0
    local frameSkip = 0

    updateConn = RunService.RenderStepped:Connect(function(dt)
        if not self.Enabled then return end
        if not comps or not comps.FPS.Card.Parent then return end

        fpsBuf[fpsIdx] = dt > 0 and (1 / dt) or 0
        fpsIdx = (fpsIdx % FPS_SAMPLES) + 1

        frameSkip = frameSkip + 1
        if frameSkip < 5 then return end
        frameSkip = 0

        local fps = math.floor(bufAvg() + 0.5)
        local ms  = math.floor(dt * 1000 + 0.5)

        pingTick = pingTick + 1
        if pingTick >= 30 then
            pingCache = getPing()
            pingTick  = 0
        end

        local pc = #Players:GetPlayers()
        local t = os.date("*t")
        local clock = string.format("%02d:%02d", t.hour, t.min)

        -- FPS Color & Dot
        if fps >= 50 then
            comps.FPS.Label.Text = string.format('<font color="rgb(100,230,120)">%d</font> FPS', fps)
            comps.FPS.Dot.BackgroundColor3 = Color3.fromRGB(100, 230, 120)
        elseif fps >= 30 then
            comps.FPS.Label.Text = string.format('<font color="rgb(255,200,60)">%d</font> FPS', fps)
            comps.FPS.Dot.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
        else
            comps.FPS.Label.Text = string.format('<font color="rgb(245,80,95)">%d</font> FPS', fps)
            comps.FPS.Dot.BackgroundColor3 = Color3.fromRGB(245, 80, 95)
        end

        -- Frame latency
        comps.MS.Label.Text = string.format('<font color="rgb(180,185,205)">%d ms</font>', ms)

        -- Ping Color
        if pingCache <= 80 then
            comps.Ping.Label.Text = string.format('<font color="rgb(100,180,255)">%d ms</font> ping', pingCache)
            comps.Ping.Dot.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        elseif pingCache <= 160 then
            comps.Ping.Label.Text = string.format('<font color="rgb(255,190,60)">%d ms</font> ping', pingCache)
            comps.Ping.Dot.BackgroundColor3 = Color3.fromRGB(255, 190, 60)
        else
            comps.Ping.Label.Text = string.format('<font color="rgb(245,80,95)">%d ms</font> ping', pingCache)
            comps.Ping.Dot.BackgroundColor3 = Color3.fromRGB(245, 80, 95)
        end

        -- Players & Time
        comps.Players.Label.Text = string.format('<font color="rgb(200,205,225)">%d players</font>', pc)
        comps.Time.Label.Text    = string.format('<font color="rgb(150,155,175)">%s</font>', clock)
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
