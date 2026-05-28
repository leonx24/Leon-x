-- Leon X | UI Library v2.2
-- Modern · Minimal · Dark Monochrome · Premium

local Library = {}
Library.Version = "2.2.0"

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local lp  = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")

-- ── Palette ───────────────────────────────────────────────────────────────────
local C = {
    BG        = Color3.fromRGB(10,  10,  10),
    Surface   = Color3.fromRGB(16,  16,  16),
    Elevated  = Color3.fromRGB(22,  22,  22),
    Border    = Color3.fromRGB(35,  35,  35),
    BorderSub = Color3.fromRGB(28,  28,  28),
    Accent    = Color3.fromRGB(255, 255, 255),
    AccentDim = Color3.fromRGB(150, 150, 150),
    Text      = Color3.fromRGB(235, 235, 235),
    TextSub   = Color3.fromRGB(100, 100, 100),
    SwitchOff = Color3.fromRGB(42,  42,  42),
    SwitchOn  = Color3.fromRGB(210, 210, 210),
    Hover     = Color3.fromRGB(28,  28,  28),
    Active    = Color3.fromRGB(38,  38,  38),
    CloseRed  = Color3.fromRGB(160, 40,  40),
    CloseHov  = Color3.fromRGB(200, 55,  55),
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function tw(obj, t, props)
    TweenService:Create(obj,
        TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        props):Play()
end

local function mkCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = p
end

local function mkStroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color     = col   or C.Border
    s.Thickness = thick or 1
    s.Parent    = p
end

local function mkPad(p, t, l, r, b)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, t or 0)
    pad.PaddingLeft   = UDim.new(0, l or 0)
    pad.PaddingRight  = UDim.new(0, r or 0)
    pad.PaddingBottom = UDim.new(0, b or 0)
    pad.Parent = p
end

local function hover(btn, n, h, a)
    btn.MouseEnter:Connect(function()    tw(btn, 0.12, {BackgroundColor3 = h}) end)
    btn.MouseLeave:Connect(function()    tw(btn, 0.18, {BackgroundColor3 = n}) end)
    btn.MouseButton1Down:Connect(function() tw(btn, 0.06, {BackgroundColor3 = a}) end)
    btn.MouseButton1Up:Connect(function()   tw(btn, 0.12, {BackgroundColor3 = h}) end)
end

local function newLabel(parent, zi)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.ZIndex                 = zi or 1
    l.Parent                 = parent
    return l
end

-- ── Destroy old ───────────────────────────────────────────────────────────────
pcall(function() gui:FindFirstChild("LeonX"):Destroy() end)

-- ── ScreenGui ─────────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "LeonX"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder   = 999
ScreenGui.Parent         = gui

-- ── Main window ───────────────────────────────────────────────────────────────
-- Border frame behind Main (stroke on ClipsDescendants frame renders outside bounds)
local MainBorder = Instance.new("Frame")
MainBorder.Name             = "MainBorder"
MainBorder.Size             = UDim2.new(0, 662, 0, 422)
MainBorder.Position         = UDim2.new(0.5, -331, 0.5, -211)
MainBorder.BackgroundColor3 = C.Border
MainBorder.BorderSizePixel  = 0
MainBorder.ZIndex           = 9
MainBorder.Parent           = ScreenGui
mkCorner(MainBorder, 15)

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 660, 0, 420)
Main.Position         = UDim2.new(0.5, -330, 0.5, -210)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true   -- ← clips children to rounded shape
Main.ZIndex           = 10
Main.Parent           = ScreenGui
mkCorner(Main, 14)

-- ── Topbar ────────────────────────────────────────────────────────────────────
local Topbar = Instance.new("Frame")
Topbar.Name             = "Topbar"
Topbar.Size             = UDim2.new(1, 0, 0, 48)
Topbar.BackgroundColor3 = C.BG
Topbar.BorderSizePixel  = 0
Topbar.ZIndex           = 30
Topbar.Parent           = Main

local TopDiv = Instance.new("Frame")
TopDiv.Size             = UDim2.new(1, 0, 0, 1)
TopDiv.Position         = UDim2.new(0, 0, 1, -1)
TopDiv.BackgroundColor3 = C.Border
TopDiv.BorderSizePixel  = 0
TopDiv.ZIndex           = 30
TopDiv.Parent           = Topbar

-- logo dot
local Dot = Instance.new("Frame")
Dot.Size             = UDim2.new(0, 7, 0, 7)
Dot.Position         = UDim2.new(0, 18, 0.5, -3)
Dot.BackgroundColor3 = C.Accent
Dot.BorderSizePixel  = 0
Dot.ZIndex           = 31
Dot.Parent           = Topbar
mkCorner(Dot, 4)

local TitleLbl = newLabel(Topbar, 31)
TitleLbl.Size           = UDim2.new(0, 80, 1, 0)
TitleLbl.Position       = UDim2.new(0, 32, 0, 0)
TitleLbl.Text           = "Leon X"
TitleLbl.TextColor3     = C.Text
TitleLbl.Font           = Enum.Font.GothamBold
TitleLbl.TextSize       = 15
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local VerLbl = newLabel(Topbar, 31)
VerLbl.Size           = UDim2.new(0, 40, 1, 0)
VerLbl.Position       = UDim2.new(0, 114, 0, 0)
VerLbl.Text           = "v2.2"
VerLbl.TextColor3     = C.TextSub
VerLbl.Font           = Enum.Font.Gotham
VerLbl.TextSize       = 11
VerLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ── Window controls (Close + Minimize) ───────────────────────────────────────
-- Both buttons parented to ScreenGui to avoid ClipsDescendants cutting them
local BtnClose = Instance.new("TextButton")
BtnClose.Size             = UDim2.new(0, 28, 0, 28)
BtnClose.BackgroundColor3 = C.CloseRed
BtnClose.Text             = "×"
BtnClose.TextColor3       = Color3.fromRGB(255, 255, 255)
BtnClose.Font             = Enum.Font.GothamBold
BtnClose.TextSize         = 18
BtnClose.AutoButtonColor  = false
BtnClose.BorderSizePixel  = 0
BtnClose.ZIndex           = 200
BtnClose.Parent           = ScreenGui
mkCorner(BtnClose, 8)
hover(BtnClose, C.CloseRed, C.CloseHov, Color3.fromRGB(220, 60, 60))

local BtnMin = Instance.new("TextButton")
BtnMin.Size             = UDim2.new(0, 28, 0, 28)
BtnMin.BackgroundColor3 = C.Elevated
BtnMin.Text             = "−"
BtnMin.TextColor3       = C.AccentDim
BtnMin.Font             = Enum.Font.GothamBold
BtnMin.TextSize         = 18
BtnMin.AutoButtonColor  = false
BtnMin.BorderSizePixel  = 0
BtnMin.ZIndex           = 200
BtnMin.Parent           = ScreenGui
mkCorner(BtnMin, 8)
hover(BtnMin, C.Elevated, C.Hover, C.Active)

-- keep buttons anchored to topbar right edge
local function updateBtnPos()
    local p = Main.AbsolutePosition
    local s = Main.AbsoluteSize
    -- Close: 14px from right, vertically centered in topbar (48px)
    BtnClose.Position = UDim2.new(0, p.X + s.X - 14 - 28, 0, p.Y + 10)
    -- Min: 8px gap left of close
    BtnMin.Position   = UDim2.new(0, p.X + s.X - 14 - 28 - 8 - 28, 0, p.Y + 10)
end
Main:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateBtnPos)
Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBtnPos)
task.defer(updateBtnPos)

-- ── Sidebar ───────────────────────────────────────────────────────────────────
local Sidebar = Instance.new("Frame")
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0, 158, 1, -48)
Sidebar.Position         = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = C.Surface
Sidebar.BorderSizePixel  = 0
Sidebar.ZIndex           = 20
Sidebar.Parent           = Main

-- right divider
local SideDiv = Instance.new("Frame")
SideDiv.Size             = UDim2.new(0, 1, 1, 0)
SideDiv.Position         = UDim2.new(1, 0, 0, 0)
SideDiv.BackgroundColor3 = C.Border
SideDiv.BorderSizePixel  = 0
SideDiv.ZIndex           = 20
SideDiv.Parent           = Sidebar

-- tab container with UIListLayout
local TabList = Instance.new("Frame")
TabList.Name             = "TabList"
TabList.Size             = UDim2.new(1, 0, 1, 0)
TabList.BackgroundTransparency = 1
TabList.BorderSizePixel  = 0
TabList.ZIndex           = 20
TabList.Parent           = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding             = UDim.new(0, 4)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.SortOrder           = Enum.SortOrder.LayoutOrder
TabLayout.Parent              = TabList
mkPad(TabList, 12, 0, 0, 12)

-- ── Content area ──────────────────────────────────────────────────────────────
local ContentArea = Instance.new("Frame")
ContentArea.Name             = "Content"
ContentArea.Size             = UDim2.new(1, -159, 1, -48)
ContentArea.Position         = UDim2.new(0, 159, 0, 48)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel  = 0
ContentArea.ZIndex           = 15
ContentArea.Parent           = Main

local Pages = {}
Library.CurrentPage = nil

-- ── Drag ──────────────────────────────────────────────────────────────────────
do
    local drag, ds, sp = false, nil, nil
    Topbar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=Main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            local nx = sp.X.Offset + d.X
            local ny = sp.Y.Offset + d.Y
            Main.Position       = UDim2.new(sp.X.Scale, nx, sp.Y.Scale, ny)
            MainBorder.Position = UDim2.new(sp.X.Scale, nx-1, sp.Y.Scale, ny-1)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ── Resize (bottom-right corner, outside Main so not clipped) ─────────────────
-- We put it on ScreenGui and track Main position
local ResizeBtn = Instance.new("TextButton")
ResizeBtn.Size             = UDim2.new(0, 24, 0, 24)
ResizeBtn.BackgroundColor3 = C.Elevated
ResizeBtn.Text             = "⤡"
ResizeBtn.TextColor3       = C.AccentDim
ResizeBtn.Font             = Enum.Font.GothamBold
ResizeBtn.TextSize         = 14
ResizeBtn.AutoButtonColor  = false
ResizeBtn.BorderSizePixel  = 0
ResizeBtn.ZIndex           = 500
ResizeBtn.Parent           = ScreenGui
mkCorner(ResizeBtn, 6)

-- keep resize button anchored to bottom-right of Main
local function updateResizePos()
    local p = Main.AbsolutePosition
    local s = Main.AbsoluteSize
    ResizeBtn.Position = UDim2.new(0, p.X + s.X - 28, 0, p.Y + s.Y - 28)
end

Main:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateResizePos)
Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResizePos)
task.defer(updateResizePos)

do
    local rsz, rs, ss = false, nil, nil
    ResizeBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            rsz=true; rs=i.Position; ss=Main.Size
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if rsz and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - rs
            local nw = math.clamp(ss.X.Offset+d.X, 520, 1200)
            local nh = math.clamp(ss.Y.Offset+d.Y, 320, 800)
            Main.Size       = UDim2.new(0, nw, 0, nh)
            MainBorder.Size = UDim2.new(0, nw+2, 0, nh+2)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then rsz=false end
    end)
end

-- ── Float button ──────────────────────────────────────────────────────────────
local Float = Instance.new("TextButton")
Float.Size             = UDim2.new(0, 48, 0, 48)
Float.Position         = UDim2.new(0, 24, 0.5, -24)
Float.BackgroundColor3 = C.Surface
Float.Text             = "LX"
Float.TextColor3       = C.Text
Float.Font             = Enum.Font.GothamBold
Float.TextSize         = 14
Float.AutoButtonColor  = false
Float.Visible          = false
Float.ZIndex           = 100
Float.Parent           = ScreenGui
mkCorner(Float, 14)
mkStroke(Float, C.Border, 1)
hover(Float, C.Surface, C.Elevated, C.Active)

do
    local df, dfs, fp, mv = false, nil, nil, false
    Float.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            df=true; mv=false; dfs=i.Position; fp=Float.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if df and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dfs
            if math.abs(d.X)>4 or math.abs(d.Y)>4 then mv=true end
            Float.Position = UDim2.new(fp.X.Scale, fp.X.Offset+d.X, fp.Y.Scale, fp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and df then
            df=false
            if not mv then
                Main.Visible=true; Float.Visible=false
                ResizeBtn.Visible=true; BtnClose.Visible=true; BtnMin.Visible=true
            end
            task.wait(); mv=false
        end
    end)
end

BtnMin.MouseButton1Click:Connect(function()
    Main.Visible=false; Float.Visible=true; ResizeBtn.Visible=false
    BtnClose.Visible=false; BtnMin.Visible=false
end)
BtnClose.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENTS
-- ══════════════════════════════════════════════════════════════════════════════

-- Section ─────────────────────────────────────────────────────────────────────
local function createSection(parent, name)
    local w = Instance.new("Frame")
    w.Size = UDim2.new(1, 0, 0, 26)
    w.BackgroundTransparency = 1
    w.BorderSizePixel = 0
    w.Parent = parent

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = C.Border
    line.BorderSizePixel = 0
    line.Parent = w

    local pill = Instance.new("Frame")
    pill.AnchorPoint = Vector2.new(0.5, 0.5)
    pill.Position = UDim2.new(0.5, 0, 0.5, 0)
    pill.Size = UDim2.new(0, 80, 1, 0)
    pill.BackgroundColor3 = C.BG
    pill.BorderSizePixel = 0
    pill.Parent = w

    local lbl = newLabel(pill, 1)
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.Text = name
    lbl.TextColor3 = C.TextSub
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Center

    task.defer(function()
        pill.Size = UDim2.new(0, lbl.TextBounds.X + 16, 1, 0)
    end)
    return w
end

-- Toggle ──────────────────────────────────────────────────────────────────────
local function createToggle(parent, data)
    local cb = data.Callback or function() end
    local on = data.Default or false

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = C.Elevated
    row.Text = ""
    row.AutoButtonColor = false
    row.BorderSizePixel = 0
    row.Parent = parent
    mkCorner(row, 10)
    mkStroke(row, C.BorderSub, 1)

    local lbl = newLabel(row, 1)
    lbl.Size = UDim2.new(1, -68, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.Text = data.Name or "Toggle"
    lbl.TextColor3 = C.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 38, 0, 20)
    track.Position = UDim2.new(1, -52, 0.5, -10)
    track.BackgroundColor3 = on and C.SwitchOn or C.SwitchOff
    track.BorderSizePixel = 0
    track.Parent = row
    mkCorner(track, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3 = on and C.BG or C.AccentDim
    knob.BorderSizePixel = 0
    knob.Parent = track
    mkCorner(knob, 7)

    hover(row, C.Elevated, C.Hover, C.Active)

    local function set(v, silent)
        on = v
        if on then
            tw(track, 0.18, {BackgroundColor3 = C.SwitchOn})
            tw(knob,  0.18, {Position = UDim2.new(1,-17,0.5,-7), BackgroundColor3 = C.BG})
        else
            tw(track, 0.18, {BackgroundColor3 = C.SwitchOff})
            tw(knob,  0.18, {Position = UDim2.new(0,3,0.5,-7), BackgroundColor3 = C.AccentDim})
        end
        if not silent then cb(on) end
    end

    row.MouseButton1Click:Connect(function() set(not on) end)

    local api = {Frame=row}
    function api:Set(v) set(v,true) end
    function api:Get() return on end
    return api
end

-- Button ──────────────────────────────────────────────────────────────────────
local function createButton(parent, data)
    local cb = data.Callback or function() end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = C.Elevated
    btn.Text = data.Name or "Button"
    btn.TextColor3 = C.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = parent
    mkCorner(btn, 10)
    mkStroke(btn, C.BorderSub, 1)

    hover(btn, C.Elevated, C.Hover, C.Active)
    btn.MouseButton1Click:Connect(function()
        tw(btn, 0.06, {BackgroundColor3 = Color3.fromRGB(50,50,50)})
        task.delay(0.12, function() tw(btn, 0.15, {BackgroundColor3 = C.Elevated}) end)
        cb()
    end)

    local api = {Frame=btn}
    function api:SetText(t) btn.Text=t end
    return api
end

-- Slider ──────────────────────────────────────────────────────────────────────
local function createSlider(parent, data)
    local cb  = data.Callback or function() end
    local min = data.Min or 0
    local max = data.Max or 100
    local suf = data.Suffix or ""
    local cur = math.clamp(data.Default or min, min, max)

    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 54)
    wrap.BackgroundColor3 = C.Elevated
    wrap.BorderSizePixel = 0
    wrap.Parent = parent
    mkCorner(wrap, 10)
    mkStroke(wrap, C.BorderSub, 1)

    local nameLbl = newLabel(wrap, 1)
    nameLbl.Size = UDim2.new(1,-80, 0, 22)
    nameLbl.Position = UDim2.new(0, 14, 0, 8)
    nameLbl.Text = data.Name or "Slider"
    nameLbl.TextColor3 = C.Text
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = newLabel(wrap, 1)
    valLbl.Size = UDim2.new(0, 70, 0, 22)
    valLbl.Position = UDim2.new(1, -80, 0, 8)
    valLbl.Text = tostring(cur)..suf
    valLbl.TextColor3 = C.AccentDim
    valLbl.Font = Enum.Font.GothamMedium
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local trackBg = Instance.new("Frame")
    trackBg.Size = UDim2.new(1, -28, 0, 4)
    trackBg.Position = UDim2.new(0, 14, 1, -16)
    trackBg.BackgroundColor3 = C.SwitchOff
    trackBg.BorderSizePixel = 0
    trackBg.Parent = wrap
    mkCorner(trackBg, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((cur-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel = 0
    fill.Parent = trackBg
    mkCorner(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((cur-min)/(max-min), 0, 0.5, 0)
    knob.BackgroundColor3 = C.Accent
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = trackBg
    mkCorner(knob, 6)

    local function upd(pct)
        pct = math.clamp(pct, 0, 1)
        cur = math.floor(min + (max-min)*pct + 0.5)
        tw(fill, 0.05, {Size = UDim2.new(pct, 0, 1, 0)})
        tw(knob, 0.05, {Position = UDim2.new(pct, 0, 0.5, 0)})
        valLbl.Text = tostring(cur)..suf
        cb(cur)
    end

    local sliding = false
    trackBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            upd((i.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            upd((i.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding=false end
    end)

    local api = {Frame=wrap}
    function api:Set(v) upd((math.clamp(v,min,max)-min)/(max-min)) end
    function api:Get() return cur end
    return api
end

-- Dropdown ────────────────────────────────────────────────────────────────────
-- List parented to ScreenGui → escapes ClipsDescendants on Main
local function createDropdown(parent, data)
    local cb      = data.Callback or function() end
    local options = data.Options  or {}
    local cur     = data.Default  or (options[1] or "Select")
    local open    = false

    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 42)
    wrap.BackgroundColor3 = C.Elevated
    wrap.BorderSizePixel = 0
    wrap.Parent = parent
    mkCorner(wrap, 10)
    mkStroke(wrap, C.BorderSub, 1)

    local hdr = Instance.new("TextButton")
    hdr.Size = UDim2.new(1, 0, 1, 0)
    hdr.BackgroundTransparency = 1
    hdr.Text = ""
    hdr.AutoButtonColor = false
    hdr.BorderSizePixel = 0
    hdr.Parent = wrap

    local nameLbl = newLabel(hdr, 1)
    nameLbl.Size = UDim2.new(1, -110, 1, 0)
    nameLbl.Position = UDim2.new(0, 14, 0, 0)
    nameLbl.Text = data.Name or "Dropdown"
    nameLbl.TextColor3 = C.Text
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = newLabel(hdr, 1)
    valLbl.Size = UDim2.new(0, 90, 1, 0)
    valLbl.Position = UDim2.new(1, -106, 0, 0)
    valLbl.Text = cur
    valLbl.TextColor3 = C.AccentDim
    valLbl.Font = Enum.Font.Gotham
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local arrow = newLabel(hdr, 1)
    arrow.Size = UDim2.new(0, 18, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.Text = "›"
    arrow.TextColor3 = C.TextSub
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 16
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    -- floating list on ScreenGui
    local listH = math.min(#options * 34 + 8, 170)

    local List = Instance.new("Frame")
    List.BackgroundColor3 = C.Surface
    List.BorderSizePixel = 0
    List.ZIndex = 500
    List.Visible = false
    List.ClipsDescendants = true
    List.Size = UDim2.new(0, 10, 0, 0)
    List.Parent = ScreenGui
    mkCorner(List, 10)
    mkStroke(List, C.Border, 1)

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = List
    mkPad(List, 4, 0, 0, 4)

    for _, opt in ipairs(options) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, 0, 0, 34)
        item.BackgroundColor3 = C.Surface
        item.Text = ""
        item.AutoButtonColor = false
        item.BorderSizePixel = 0
        item.ZIndex = 501
        item.Parent = List

        local itemLbl = newLabel(item, 501)
        itemLbl.Size = UDim2.new(1, -20, 1, 0)
        itemLbl.Position = UDim2.new(0, 12, 0, 0)
        itemLbl.Text = opt
        itemLbl.TextColor3 = C.Text
        itemLbl.Font = Enum.Font.Gotham
        itemLbl.TextSize = 12
        itemLbl.TextXAlignment = Enum.TextXAlignment.Left

        hover(item, C.Surface, C.Elevated, C.Active)

        item.MouseButton1Click:Connect(function()
            cur = opt; valLbl.Text = opt
            open = false
            tw(arrow, 0.15, {Rotation = 0})
            tw(List,  0.15, {Size = UDim2.new(0, List.Size.X.Offset, 0, 0)})
            task.delay(0.16, function() List.Visible = false end)
            cb(opt)
        end)
    end

    local function closeDD()
        open = false
        tw(arrow, 0.15, {Rotation = 0})
        tw(List,  0.15, {Size = UDim2.new(0, List.Size.X.Offset, 0, 0)})
        task.delay(0.16, function() List.Visible = false end)
    end

    local function openDD()
        open = true
        local ap = wrap.AbsolutePosition
        local as = wrap.AbsoluteSize
        List.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 4)
        List.Size     = UDim2.new(0, as.X, 0, 0)
        List.Visible  = true
        tw(arrow, 0.15, {Rotation = 90})
        tw(List,  0.18, {Size = UDim2.new(0, as.X, 0, listH)})
    end

    hdr.MouseButton1Click:Connect(function()
        if open then closeDD() else openDD() end
    end)

    UIS.InputBegan:Connect(function(i)
        if not open or i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local mp = i.Position
        local function outside(f)
            local p = f.AbsolutePosition; local s = f.AbsoluteSize
            return mp.X<p.X or mp.X>p.X+s.X or mp.Y<p.Y or mp.Y>p.Y+s.Y
        end
        if outside(List) and outside(wrap) then closeDD() end
    end)

    local api = {Frame=wrap}
    function api:Set(v) cur=v; valLbl.Text=v end
    function api:Get() return cur end
    return api
end

-- Keybind ─────────────────────────────────────────────────────────────────────
local function createKeybind(parent, data)
    local cb  = data.Callback or function() end
    local cur = data.Default  or Enum.KeyCode.Unknown
    local waiting = false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = C.Elevated
    row.BorderSizePixel = 0
    row.Parent = parent
    mkCorner(row, 10)
    mkStroke(row, C.BorderSub, 1)

    local lbl = newLabel(row, 1)
    lbl.Size = UDim2.new(1, -110, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.Text = data.Name or "Keybind"
    lbl.TextColor3 = C.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 80, 0, 26)
    keyBtn.Position = UDim2.new(1, -90, 0.5, -13)
    keyBtn.BackgroundColor3 = C.Surface
    keyBtn.Text = cur == Enum.KeyCode.Unknown and "None" or cur.Name
    keyBtn.TextColor3 = C.AccentDim
    keyBtn.Font = Enum.Font.GothamMedium
    keyBtn.TextSize = 11
    keyBtn.AutoButtonColor = false
    keyBtn.BorderSizePixel = 0
    keyBtn.Parent = row
    mkCorner(keyBtn, 7)
    mkStroke(keyBtn, C.Border, 1)
    hover(keyBtn, C.Surface, C.Elevated, C.Active)

    keyBtn.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting = true; keyBtn.Text = "..."; keyBtn.TextColor3 = C.Text
    end)
    UIS.InputBegan:Connect(function(i, gp)
        if not waiting or gp then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            cur = i.KeyCode; waiting = false
            keyBtn.Text = i.KeyCode.Name; keyBtn.TextColor3 = C.AccentDim
            cb(cur)
        end
    end)

    local api = {Frame=row}
    function api:Get() return cur end
    return api
end

-- Label ───────────────────────────────────────────────────────────────────────
local function createLabel(parent, data)
    local lbl = newLabel(parent, 1)
    lbl.Size = UDim2.new(1, 0, 0, 26)
    lbl.Text = data.Text or ""
    lbl.TextColor3 = data.Color or C.TextSub
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = data.Align or Enum.TextXAlignment.Left

    local api = {Frame=lbl}
    function api:Set(t) lbl.Text=t end
    return api
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CreateTab
-- ══════════════════════════════════════════════════════════════════════════════
function Library:CreateTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, -16, 0, 36)
    tabBtn.BackgroundColor3 = C.Surface
    tabBtn.Text = ""
    tabBtn.AutoButtonColor = false
    tabBtn.BorderSizePixel = 0
    tabBtn.ZIndex = 21
    tabBtn.Parent = TabList
    mkCorner(tabBtn, 9)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 18)
    bar.Position = UDim2.new(0, 0, 0.5, -9)
    bar.BackgroundColor3 = C.Accent
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel = 0
    bar.ZIndex = 22
    bar.Parent = tabBtn
    mkCorner(bar, 2)

    local tabLbl = newLabel(tabBtn, 22)
    tabLbl.Size = UDim2.new(1, -14, 1, 0)
    tabLbl.Position = UDim2.new(0, 14, 0, 0)
    tabLbl.Text = name
    tabLbl.TextColor3 = C.TextSub
    tabLbl.Font = Enum.Font.GothamMedium
    tabLbl.TextSize = 13
    tabLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- scrolling page
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = C.BorderSub
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ZIndex = 16
    page.Visible = false
    page.Parent = ContentArea

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page
    mkPad(page, 16, 14, 14, 16)

    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 32)
    end)

    Pages[name] = {page=page, btn=tabBtn, bar=bar, lbl=tabLbl}

    local function activate()
        for _, v in pairs(Pages) do
            v.page.Visible = false
            tw(v.btn, 0.15, {BackgroundColor3 = C.Surface})
            tw(v.bar, 0.15, {BackgroundTransparency = 1})
            tw(v.lbl, 0.15, {TextColor3 = C.TextSub})
        end
        page.Visible = true
        tw(tabBtn, 0.15, {BackgroundColor3 = C.Elevated})
        tw(bar,    0.15, {BackgroundTransparency = 0})
        tw(tabLbl, 0.15, {TextColor3 = C.Text})
        Library.CurrentPage = page
    end

    -- First tab: activate immediately (no other tabs exist yet to hide)
    if not Library.CurrentPage then
        Library.CurrentPage = page
        page.Visible = true
        tabBtn.BackgroundColor3 = C.Elevated
        bar.BackgroundTransparency = 0
        tabLbl.TextColor3 = C.Text
    end

    tabBtn.MouseButton1Click:Connect(activate)
    hover(tabBtn, C.Surface, C.Hover, C.Active)

    local Tab = {}
    function Tab:AddSection(n)  return createSection(page, n)  end
    function Tab:AddToggle(d)   return createToggle(page, d)   end
    function Tab:AddButton(d)   return createButton(page, d)   end
    function Tab:AddSlider(d)   return createSlider(page, d)   end
    function Tab:AddDropdown(d) return createDropdown(page, d) end
    function Tab:AddKeybind(d)  return createKeybind(page, d)  end
    function Tab:AddLabel(d)    return createLabel(page, d)    end
    return Tab
end

return Library
