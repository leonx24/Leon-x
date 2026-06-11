-- Leon X UI Library v2.0 - Modern Glassmorphism + Neon
local Library = {}

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local lp           = Players.LocalPlayer
local gui          = lp:WaitForChild("PlayerGui")

-- Fetch version dynamically
local VERSION = "1.0"
pcall(function()
    VERSION = game:HttpGet("https://raw.githubusercontent.com/leonx24/Leon-x/main/version.txt?t="..os.time()):match("^%s*(.-)%s*$")
end)

-- Modern Color Scheme - Glassmorphism + Neon
local C = {
    -- Glass backgrounds (with transparency for blur effect)
    BG       = Color3.fromRGB(8, 8, 12),      -- Deep dark blue
    Surface  = Color3.fromRGB(15, 15, 22),    -- Slightly lighter
    Elevated = Color3.fromRGB(22, 22, 32),    -- Card backgrounds
    Border   = Color3.fromRGB(45, 45, 65),    -- Subtle borders

    -- Neon Accents (Cyan to Purple gradient)
    Accent   = Color3.fromRGB(0, 217, 255),   -- Cyan
    Accent2  = Color3.fromRGB(168, 85, 247),  -- Purple
    AccentPink = Color3.fromRGB(255, 0, 110), -- Pink highlight

    -- Text
    Text     = Color3.fromRGB(255, 255, 255), -- Pure white
    TextDim  = Color3.fromRGB(170, 170, 190), -- Dimmed text
    Sub      = Color3.fromRGB(120, 120, 140), -- Subtle text

    -- Toggle states
    OffTrack = Color3.fromRGB(35, 35, 45),
    OnTrack  = Color3.fromRGB(0, 217, 255),   -- Cyan when on

    -- Interactive states
    Hover    = Color3.fromRGB(28, 28, 40),
    Press    = Color3.fromRGB(35, 35, 50),

    -- Status colors
    Success  = Color3.fromRGB(0, 255, 150),
    Warning  = Color3.fromRGB(255, 200, 0),
    Error    = Color3.fromRGB(255, 60, 80),
}

-- Animated gradient for accents
local gradientHue = 0
RunService.Heartbeat:Connect(function(dt)
    gradientHue = (gradientHue + dt * 0.3) % 1
end)

local function getAnimatedAccent()
    return Color3.fromHSV(gradientHue, 0.8, 1)
end

-- Helper functions
local function tw(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p):Play()
end

local function twBounce(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Back, Enum.EasingDirection.Out), p):Play()
end

local function rnd(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 12)
    c.Parent = p
end

local function strk(p, col, thickness)
    local s = Instance.new("UIStroke")
    s.Color = col or C.Border
    s.Thickness = thickness or 1
    s.Transparency = 0.3
    s.Parent = p
    return s
end

local function glow(p, col, size)
    local s = Instance.new("UIStroke")
    s.Color = col or C.Accent
    s.Thickness = size or 2
    s.Transparency = 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p

    -- Animated glow
    task.spawn(function()
        while s and s.Parent do
            tw(s, 1, {Transparency = 0.2})
            task.wait(1)
            tw(s, 1, {Transparency = 0.6})
            task.wait(1)
        end
    end)

    return s
end

local function pdg(p, t, l, r, b)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0, t or 0)
    u.PaddingLeft = UDim.new(0, l or 0)
    u.PaddingRight = UDim.new(0, r or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.Parent = p
end

local function mkF(parent, bg)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = bg or C.BG
    f.BorderSizePixel = 0
    f.BackgroundTransparency = 0.1  -- Slight transparency for glass effect
    f.Parent = parent
    return f
end

local function mkL(parent, txt, sz, col, font, xa)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Text = txt or ""
    l.TextSize = sz or 13
    l.TextColor3 = col or C.Text
    l.Font = font or Enum.Font.GothamBold
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextStrokeTransparency = 0.8
    l.Parent = parent
    return l
end

-- Enhanced hover with scale and glow
local function hvr(b, n, h, a)
    local originalSize = b.Size

    b.MouseEnter:Connect(function()
        tw(b, 0.15, {BackgroundColor3 = h})
        twBounce(b, 0.2, {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, originalSize.Y.Scale, originalSize.Y.Offset + 2)})
    end)

    b.MouseLeave:Connect(function()
        tw(b, 0.2, {BackgroundColor3 = n})
        tw(b, 0.2, {Size = originalSize})
    end)

    b.MouseButton1Down:Connect(function()
        tw(b, 0.05, {BackgroundColor3 = a})
        tw(b, 0.1, {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, originalSize.Y.Scale, originalSize.Y.Offset - 2)})
    end)

    b.MouseButton1Up:Connect(function()
        tw(b, 0.1, {BackgroundColor3 = h})
        tw(b, 0.1, {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, originalSize.Y.Scale, originalSize.Y.Offset + 2)})
    end)
end

-- Gradient helper
local function addGradient(parent, colorSeq, rotation)
    local grad = Instance.new("UIGradient")
    grad.Color = colorSeq
    grad.Rotation = rotation or 0
    grad.Parent = parent
    return grad
end

-- destroy old instance
pcall(function() gui:FindFirstChild("LeonX"):Destroy() end)

local Screen = Instance.new("ScreenGui")
Screen.Name = "LeonX"
Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder = 999
Screen.IgnoreGuiInset = true
Screen.Parent = gui

-- Responsive sizing
local vp = workspace.CurrentCamera.ViewportSize
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local maxW = math.floor(vp.X * (isMobile and 0.94 or 1))
local maxH = math.floor(vp.Y * (isMobile and 0.88 or 1))
local WIN_W = math.clamp(660, 320, maxW)
local WIN_H = math.clamp(isMobile and math.min(420, maxH) or 420, 260, maxH)
local SIDE_W = math.floor(WIN_W * (140/660))
local TOP_H = 45

local R = 16  -- Larger corner radius

-- Main window with glass effect
local Win = mkF(Screen, C.BG)
Win.Name = "Win"
Win.Size = UDim2.new(0, WIN_W, 0, WIN_H)
Win.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Win.ClipsDescendants = true
Win.Visible = false
Win.BackgroundTransparency = 0.15  -- Glass transparency
rnd(Win, R)

-- Outer glow
local outerGlow = strk(Win, C.Accent, 2)
outerGlow.Transparency = 0.4

-- Animated gradient border
task.spawn(function()
    while outerGlow and outerGlow.Parent do
        outerGlow.Color = getAnimatedAccent()
        task.wait(0.05)
    end
end)

-- Topbar with gradient
local Top = mkF(Win, C.Surface)
Top.Size = UDim2.new(1, 0, 0, TOP_H)
Top.BackgroundTransparency = 0.2

local topGrad = addGradient(Top, ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.Accent),
    ColorSequenceKeypoint.new(0.5, C.Accent2),
    ColorSequenceKeypoint.new(1, C.AccentPink)
}), 90)

-- Animate gradient
task.spawn(function()
    while topGrad and topGrad.Parent do
        tw(topGrad, 2, {Rotation = 90})
        task.wait(2)
        tw(topGrad, 2, {Rotation = 270})
        task.wait(2)
    end
end)

local TopDiv = mkF(Top, C.Border)
TopDiv.Size = UDim2.new(1, 0, 0, 1)
TopDiv.Position = UDim2.new(0, 0, 1, -1)
TopDiv.BackgroundTransparency = 0.5

-- Glowing dot
local Dot = mkF(Top, C.Accent)
Dot.Size = UDim2.new(0, 8, 0, 8)
Dot.Position = UDim2.new(0, 18, 0.5, -4)
rnd(Dot, 4)
glow(Dot, C.Accent, 3)

-- Animated dot pulse
task.spawn(function()
    while Dot and Dot.Parent do
        twBounce(Dot, 0.8, {Size = UDim2.new(0, 10, 0, 10)})
        task.wait(0.8)
        tw(Dot, 0.8, {Size = UDim2.new(0, 8, 0, 8)})
        task.wait(0.8)
    end
end)

local TitleL = mkL(Top, "LEON X", 15, C.Text, Enum.Font.GothamBold)
TitleL.Size = UDim2.new(0, 100, 1, 0)
TitleL.Position = UDim2.new(0, 35, 0, 0)
TitleL.TextStrokeTransparency = 0.5

local VerL = mkL(Top, "v" .. VERSION, 11, C.TextDim, Enum.Font.Gotham)
VerL.Size = UDim2.new(0, 40, 1, 0)
VerL.Position = UDim2.new(0, 130, 0, 0)

-- Active features counter
local ActiveL = mkL(Top, "", 11, C.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
ActiveL.Size = UDim2.new(0, 100, 1, 0)
ActiveL.Position = UDim2.new(1, -190, 0, 0)

Library._activeCount = 0
local function updateActiveCount()
    local count = 0
    for _, api in pairs(Library.Registry) do
        if api.Get then
            local ok, val = pcall(function() return api:Get() end)
            if ok and val == true then
                count = count + 1
            end
        end
    end
    Library._activeCount = count
    if count > 0 then
        ActiveL.Text = count .. " ACTIVE"
        ActiveL.TextColor3 = C.Success
    else
        ActiveL.Text = ""
    end
end
Library._onToggleChanged = function(_)
    updateActiveCount()
end

-- Window buttons
local function mkWinBtn(icon, bg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 28)
    b.BackgroundColor3 = bg
    b.Text = icon
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 5
    b.BackgroundTransparency = 0.3
    b.Parent = Top
    rnd(b, 8)
    return b
end

local BtnX = mkWinBtn("×", C.Error)
local BtnM = mkWinBtn("−", C.Elevated)
BtnX.AnchorPoint = Vector2.new(1, 0.5)
BtnX.Position = UDim2.new(1, -10, 0.5, 0)
BtnM.AnchorPoint = Vector2.new(1, 0.5)
BtnM.Position = UDim2.new(1, -45, 0.5, 0)
BtnX.Visible = false
BtnM.Visible = false

hvr(BtnX, C.Error, Color3.fromRGB(255, 80, 100), Color3.fromRGB(200, 50, 70))
hvr(BtnM, C.Elevated, C.Hover, C.Press)

-- Sidebar dengan glass effect
local Side = mkF(Win, C.Surface)
Side.Size = UDim2.new(0, SIDE_W, 1, -TOP_H)
Side.Position = UDim2.new(0, 0, 0, TOP_H)
Side.BackgroundTransparency = 0.2

local SideDiv = mkF(Side, C.Border)
SideDiv.Size = UDim2.new(0, 1, 1, 0)
SideDiv.Position = UDim2.new(1, 0, 0, 0)
SideDiv.BackgroundTransparency = 0.5

local SideScroll = Instance.new("ScrollingFrame")
SideScroll.Size = UDim2.new(1, 0, 1, -50)
SideScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SideScroll.ScrollBarThickness = 3
SideScroll.ScrollBarImageColor3 = C.Accent
SideScroll.BackgroundTransparency = 1
SideScroll.BorderSizePixel = 0
SideScroll.Parent = Side
pdg(SideScroll, 12, 0, 0, 12)

local SideLL = Instance.new("UIListLayout")
SideLL.Padding = UDim.new(0, 6)
SideLL.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLL.SortOrder = Enum.SortOrder.LayoutOrder
SideLL.Parent = SideScroll
SideLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SideScroll.CanvasSize = UDim2.new(0, 0, 0, SideLL.AbsoluteContentSize.Y + 24)
end)

-- Search box with neon glow
local SearchBox = mkF(Side, C.Elevated)
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -12, 0, 34)
SearchBox.Position = UDim2.new(0, 6, 1, -42)
SearchBox.BackgroundTransparency = 0.3
rnd(SearchBox, 10)
glow(SearchBox, C.Accent, 2)

local SearchIcon = mkL(SearchBox, "🔍", 13, C.Accent, Enum.Font.Gotham, Enum.TextXAlignment.Center)
SearchIcon.Size = UDim2.new(0, 24, 1, 0)
SearchIcon.Position = UDim2.new(0, 6, 0, 0)

local SearchInput = Instance.new("TextBox")
SearchInput.Size = UDim2.new(1, -36, 1, -8)
SearchInput.Position = UDim2.new(0, 30, 0, 4)
SearchInput.BackgroundTransparency = 1
SearchInput.Text = ""
SearchInput.PlaceholderText = "Search..."
SearchInput.PlaceholderColor3 = C.Sub
SearchInput.TextColor3 = C.Text
SearchInput.Font = Enum.Font.Gotham
SearchInput.TextSize = 11
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.Parent = SearchBox

-- Content area
local Content = mkF(Win, C.BG)
Content.BackgroundTransparency = 1
Content.Size = UDim2.new(1, -(SIDE_W + 1), 1, -TOP_H)
Content.Position = UDim2.new(0, SIDE_W + 1, 0, TOP_H)

-- Initialize
local Pages = {}
Library._first = true
Library._currentTheme = "Dark"
Library.Registry = {}
Library._allComponents = {}
Library.PanicKey = Enum.KeyCode.Delete

print("Leon X UI v2.0 - Loaded with Modern Glassmorphism + Neon theme!")

-- Will continue with component creation functions...
-- This is part 1 of the new UI
