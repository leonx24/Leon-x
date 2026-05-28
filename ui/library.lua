-- Leon X | UI Library
-- Modern · Minimal · Dark Monochrome · Premium

local Library = {}
Library.Version = "2.0.0"

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local lp  = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")

-- ── Palette ──────────────────────────────────────────────────────────────────
local C = {
    BG        = Color3.fromRGB(10, 10, 10),   -- main window
    Surface   = Color3.fromRGB(16, 16, 16),   -- sidebar / cards
    Elevated  = Color3.fromRGB(22, 22, 22),   -- buttons / toggles off
    Border    = Color3.fromRGB(32, 32, 32),   -- strokes
    BorderSub = Color3.fromRGB(26, 26, 26),   -- subtle strokes
    Accent    = Color3.fromRGB(255,255,255),  -- white accent
    AccentDim = Color3.fromRGB(160,160,160),  -- dimmed text / icons
    Text      = Color3.fromRGB(240,240,240),
    TextSub   = Color3.fromRGB(130,130,130),
    SwitchOff = Color3.fromRGB(38, 38, 38),
    SwitchOn  = Color3.fromRGB(220,220,220),
    Hover     = Color3.fromRGB(28, 28, 28),
    Active    = Color3.fromRGB(34, 34, 34),
}

-- ── Tween helper ─────────────────────────────────────────────────────────────
local function tween(obj, t, props, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir   = dir   or Enum.EasingDirection.Out
    local tw = TweenService:Create(obj, TweenInfo.new(t, style, dir), props)
    tw:Play()
    return tw
end

-- ── Utility: make frame ───────────────────────────────────────────────────────
local function frame(props)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    for k, v in pairs(props) do f[k] = v end
    return f
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or C.Border
    s.Thickness = thickness or 1
    s.Parent    = parent
    return s
end

local function label(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.Font                   = Enum.Font.Gotham
    l.TextSize               = 13
    l.TextColor3             = C.Text
    l.TextXAlignment         = Enum.TextXAlignment.Left
    for k, v in pairs(props) do l[k] = v end
    return l
end

local function padding(parent, top, left, right, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.Parent = parent
    return p
end

-- ── Hover / Press ripple helpers ──────────────────────────────────────────────
local function addHover(btn, normalColor, hoverColor, pressColor)
    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = hoverColor })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.2, { BackgroundColor3 = normalColor })
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, 0.08, { BackgroundColor3 = pressColor })
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = hoverColor })
    end)
end

-- ── Destroy old GUI ───────────────────────────────────────────────────────────
pcall(function()
    gui:FindFirstChild("LeonX"):Destroy()
end)

-- ── ScreenGui ─────────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "LeonX"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.Parent          = gui

-- ── Main Window ───────────────────────────────────────────────────────────────
local Main = frame({
    Name             = "Main",
    Size             = UDim2.new(0, 660, 0, 420),
    Position         = UDim2.new(0.5, -330, 0.5, -210),
    BackgroundColor3 = C.BG,
    Parent           = ScreenGui,
})
corner(Main, 14)
stroke(Main, C.Border, 1)

-- subtle inner shadow via gradient overlay
local Shadow = Instance.new("ImageLabel")
Shadow.Name               = "Shadow"
Shadow.Size               = UDim2.new(1, 30, 1, 30)
Shadow.Position           = UDim2.new(0, -15, 0, -15)
Shadow.BackgroundTransparency = 1
Shadow.Image              = "rbxassetid://6014261993"
Shadow.ImageColor3        = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency  = 0.55
Shadow.ScaleType          = Enum.ScaleType.Slice
Shadow.SliceCenter        = Rect.new(49, 49, 450, 450)
Shadow.ZIndex             = 0
Shadow.Parent             = Main

-- ── Topbar ────────────────────────────────────────────────────────────────────
local Topbar = frame({
    Name             = "Topbar",
    Size             = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = C.BG,
    ZIndex           = 5,
    Parent           = Main,
})
corner(Topbar, 14)

-- bottom border line on topbar
local TopLine = frame({
    Size             = UDim2.new(1, 0, 0, 1),
    Position         = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.Border,
    Parent           = Topbar,
})

-- Logo dot + title
local LogoDot = frame({
    Size             = UDim2.new(0, 7, 0, 7),
    Position         = UDim2.new(0, 18, 0.5, -3),
    BackgroundColor3 = C.Accent,
    ZIndex           = 6,
    Parent           = Topbar,
})
corner(LogoDot, 4)

local TitleLabel = label({
    Size             = UDim2.new(0, 120, 1, 0),
    Position         = UDim2.new(0, 32, 0, 0),
    Text             = "Leon X",
    TextColor3       = C.Text,
    Font             = Enum.Font.GothamBold,
    TextSize         = 15,
    ZIndex           = 6,
    Parent           = Topbar,
})

local VersionLabel = label({
    Size             = UDim2.new(0, 60, 1, 0),
    Position         = UDim2.new(0, 90, 0, 0),
    Text             = "v2.0",
    TextColor3       = C.TextSub,
    Font             = Enum.Font.Gotham,
    TextSize         = 11,
    ZIndex           = 6,
    Parent           = Topbar,
})

-- ── Window Controls ───────────────────────────────────────────────────────────
local function makeControl(xOffset, icon, bgColor)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 26, 0, 26)
    btn.Position         = UDim2.new(1, xOffset, 0.5, -13)
    btn.BackgroundColor3 = bgColor
    btn.Text             = icon
    btn.TextColor3       = C.AccentDim
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 12
    btn.AutoButtonColor  = false
    btn.ZIndex           = 6
    btn.Parent           = Topbar
    corner(btn, 8)
    return btn
end

local BtnClose    = makeControl(-14, "✕", Color3.fromRGB(28, 14, 14))
local BtnMinimize = makeControl(-46, "−", C.Elevated)

addHover(BtnClose,    Color3.fromRGB(28,14,14),  Color3.fromRGB(55,20,20),  Color3.fromRGB(70,22,22))
addHover(BtnMinimize, C.Elevated, C.Hover, C.Active)

-- ── Sidebar ───────────────────────────────────────────────────────────────────
local Sidebar = frame({
    Name             = "Sidebar",
    Size             = UDim2.new(0, 160, 1, -48),
    Position         = UDim2.new(0, 0, 0, 48),
    BackgroundColor3 = C.Surface,
    Parent           = Main,
})

-- right border
local SideRight = frame({
    Size             = UDim2.new(0, 1, 1, 0),
    Position         = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = C.Border,
    Parent           = Sidebar,
})

-- bottom-left corner fix
local SideCornerFix = frame({
    Size             = UDim2.new(0, 14, 0, 14),
    Position         = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = C.Surface,
    Parent           = Sidebar,
})

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding            = UDim.new(0, 4)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder          = Enum.SortOrder.LayoutOrder
SideLayout.Parent             = Sidebar

padding(Sidebar, 14, 0, 0, 14)

-- ── Content Area ──────────────────────────────────────────────────────────────
local ContentArea = frame({
    Name             = "Content",
    Size             = UDim2.new(1, -160, 1, -48),
    Position         = UDim2.new(0, 160, 0, 48),
    BackgroundTransparency = 1,
    Parent           = Main,
})

local Pages = {}
Library.CurrentPage = nil

-- ── Drag (Topbar) ─────────────────────────────────────────────────────────────
do
    local dragging, dragStart, startPos = false, nil, nil
    Topbar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = Main.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ── Resize Handle ─────────────────────────────────────────────────────────────
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size             = UDim2.new(0, 20, 0, 20)
ResizeHandle.AnchorPoint      = Vector2.new(1, 1)
ResizeHandle.Position         = UDim2.new(1, -4, 1, -4)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Text             = ""
ResizeHandle.AutoButtonColor  = false
ResizeHandle.ZIndex           = 10
ResizeHandle.Parent           = Main

local ResizeIcon = label({
    Size             = UDim2.new(1, 0, 1, 0),
    Text             = "⤡",
    TextColor3       = C.TextSub,
    TextTransparency = 0.4,
    Font             = Enum.Font.Gotham,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Right,
    TextYAlignment   = Enum.TextYAlignment.Bottom,
    ZIndex           = 10,
    Parent           = ResizeHandle,
})

do
    local resizing, resizeStart, startSize = false, nil, nil
    ResizeHandle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing    = true
            resizeStart = inp.Position
            startSize   = Main.Size
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - resizeStart
            Main.Size = UDim2.new(
                0, math.clamp(startSize.X.Offset + d.X, 520, 1200),
                0, math.clamp(startSize.Y.Offset + d.Y, 320, 800)
            )
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
end

-- ── Float Button (minimized state) ────────────────────────────────────────────
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
Float.ZIndex           = 20
Float.Parent           = ScreenGui
corner(Float, 14)
stroke(Float, C.Border, 1)

addHover(Float, C.Surface, C.Elevated, C.Active)

do
    local draggingF, dragFStart, floatStart, moved = false, nil, nil, false
    Float.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingF  = true
            moved      = false
            dragFStart = inp.Position
            floatStart = Float.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if draggingF and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragFStart
            if math.abs(d.X) > 4 or math.abs(d.Y) > 4 then moved = true end
            Float.Position = UDim2.new(
                floatStart.X.Scale, floatStart.X.Offset + d.X,
                floatStart.Y.Scale, floatStart.Y.Offset + d.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 and draggingF then
            draggingF = false
            if not moved then
                Main.Visible  = true
                Float.Visible = false
                tween(Main, 0.25, { Size = UDim2.new(0, 660, 0, 420) })
            end
            task.wait()
            moved = false
        end
    end)
end

-- ── Window Controls Logic ─────────────────────────────────────────────────────
BtnMinimize.MouseButton1Click:Connect(function()
    Main.Visible  = false
    Float.Visible = true
end)

BtnClose.MouseButton1Click:Connect(function()
    tween(Main, 0.2, { BackgroundTransparency = 1 })
    task.wait(0.22)
    ScreenGui:Destroy()
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENT: Section header
-- ══════════════════════════════════════════════════════════════════════════════
local function createSection(parent, name)
    local wrap = frame({
        Size             = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent           = parent,
    })

    local line = frame({
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.Border,
        Parent           = wrap,
    })

    local bg = frame({
        Size             = UDim2.new(0, 0, 1, 0),
        AnchorPoint      = Vector2.new(0.5, 0),
        Position         = UDim2.new(0.5, 0, 0, 0),
        BackgroundColor3 = C.BG,
        Parent           = wrap,
    })

    local lbl = label({
        Size             = UDim2.new(1, -16, 1, 0),
        Position         = UDim2.new(0, 8, 0, 0),
        Text             = name,
        TextColor3       = C.TextSub,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Center,
        Parent           = bg,
    })

    -- auto-size bg to text
    task.defer(function()
        local tw = lbl.TextBounds.X + 16
        bg.Size = UDim2.new(0, tw, 1, 0)
    end)

    return wrap
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENT: Toggle
-- ══════════════════════════════════════════════════════════════════════════════
local function createToggle(parent, data)
    local cb      = data.Callback or function() end
    local enabled = data.Default  or false

    local Row = Instance.new("TextButton")
    Row.Size             = UDim2.new(1, 0, 0, 42)
    Row.BackgroundColor3 = C.Elevated
    Row.Text             = ""
    Row.AutoButtonColor  = false
    Row.Parent           = parent
    corner(Row, 10)
    stroke(Row, C.BorderSub, 1)

    local Lbl = label({
        Size           = UDim2.new(1, -70, 1, 0),
        Position       = UDim2.new(0, 14, 0, 0),
        Text           = data.Name or "Toggle",
        TextColor3     = C.Text,
        Font           = Enum.Font.GothamMedium,
        TextSize       = 13,
        Parent         = Row,
    })

    -- pill track
    local Track = frame({
        Size             = UDim2.new(0, 38, 0, 20),
        Position         = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = enabled and C.SwitchOn or C.SwitchOff,
        Parent           = Row,
    })
    corner(Track, 10)

    -- knob
    local Knob = frame({
        Size             = UDim2.new(0, 14, 0, 14),
        Position         = enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = enabled and C.BG or C.AccentDim,
        Parent           = Track,
    })
    corner(Knob, 7)

    addHover(Row, C.Elevated, C.Hover, C.Active)

    local function setState(state, silent)
        enabled = state
        if enabled then
            tween(Track, 0.18, { BackgroundColor3 = C.SwitchOn  })
            tween(Knob,  0.18, { Position = UDim2.new(1, -17, 0.5, -7), BackgroundColor3 = C.BG })
        else
            tween(Track, 0.18, { BackgroundColor3 = C.SwitchOff })
            tween(Knob,  0.18, { Position = UDim2.new(0, 3, 0.5, -7),   BackgroundColor3 = C.AccentDim })
        end
        if not silent then cb(enabled) end
    end

    Row.MouseButton1Click:Connect(function()
        setState(not enabled)
    end)

    local api = { Frame = Row }
    function api:Set(v) setState(v, true) end
    function api:Get() return enabled end
    return api
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENT: Button
-- ══════════════════════════════════════════════════════════════════════════════
local function createButton(parent, data)
    local cb = data.Callback or function() end

    local Btn = Instance.new("TextButton")
    Btn.Size             = UDim2.new(1, 0, 0, 38)
    Btn.BackgroundColor3 = C.Elevated
    Btn.Text             = ""
    Btn.AutoButtonColor  = false
    Btn.Parent           = parent
    corner(Btn, 10)
    stroke(Btn, C.BorderSub, 1)

    local Lbl = label({
        Size           = UDim2.new(1, 0, 1, 0),
        Text           = data.Name or "Button",
        TextColor3     = C.Text,
        Font           = Enum.Font.GothamMedium,
        TextSize       = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent         = Btn,
    })

    addHover(Btn, C.Elevated, C.Hover, C.Active)

    Btn.MouseButton1Click:Connect(function()
        -- brief flash
        tween(Btn, 0.06, { BackgroundColor3 = Color3.fromRGB(50,50,50) })
        task.delay(0.12, function()
            tween(Btn, 0.15, { BackgroundColor3 = C.Elevated })
        end)
        cb()
    end)

    local api = { Frame = Btn }
    function api:SetText(t) Lbl.Text = t end
    return api
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENT: Slider
-- ══════════════════════════════════════════════════════════════════════════════
local function createSlider(parent, data)
    local cb      = data.Callback or function() end
    local min     = data.Min      or 0
    local max     = data.Max      or 100
    local default = data.Default  or min
    local suffix  = data.Suffix   or ""
    local current = math.clamp(default, min, max)

    local Wrap = frame({
        Size             = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = C.Elevated,
        Parent           = parent,
    })
    corner(Wrap, 10)
    stroke(Wrap, C.BorderSub, 1)

    local Lbl = label({
        Size           = UDim2.new(1, -80, 0, 22),
        Position       = UDim2.new(0, 14, 0, 8),
        Text           = data.Name or "Slider",
        TextColor3     = C.Text,
        Font           = Enum.Font.GothamMedium,
        TextSize       = 13,
        Parent         = Wrap,
    })

    local ValLbl = label({
        Size           = UDim2.new(0, 70, 0, 22),
        Position       = UDim2.new(1, -80, 0, 8),
        Text           = tostring(current) .. suffix,
        TextColor3     = C.AccentDim,
        Font           = Enum.Font.GothamMedium,
        TextSize       = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent         = Wrap,
    })

    -- track bg
    local TrackBG = frame({
        Size             = UDim2.new(1, -28, 0, 4),
        Position         = UDim2.new(0, 14, 1, -16),
        BackgroundColor3 = C.SwitchOff,
        Parent           = Wrap,
    })
    corner(TrackBG, 2)

    -- fill
    local Fill = frame({
        Size             = UDim2.new((current - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C.Accent,
        Parent           = TrackBG,
    })
    corner(Fill, 2)

    -- knob
    local Knob = frame({
        Size             = UDim2.new(0, 12, 0, 12),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new((current - min) / (max - min), 0, 0.5, 0),
        BackgroundColor3 = C.Accent,
        ZIndex           = 3,
        Parent           = TrackBG,
    })
    corner(Knob, 6)

    local function updateSlider(pct)
        pct     = math.clamp(pct, 0, 1)
        current = math.floor(min + (max - min) * pct + 0.5)
        tween(Fill,  0.05, { Size     = UDim2.new(pct, 0, 1, 0) })
        tween(Knob,  0.05, { Position = UDim2.new(pct, 0, 0.5, 0) })
        ValLbl.Text = tostring(current) .. suffix
        cb(current)
    end

    local sliding = false
    TrackBG.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            local rel = (inp.Position.X - TrackBG.AbsolutePosition.X) / TrackBG.AbsoluteSize.X
            updateSlider(rel)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = (inp.Position.X - TrackBG.AbsolutePosition.X) / TrackBG.AbsoluteSize.X
            updateSlider(rel)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    local api = { Frame = Wrap }
    function api:Set(v)
        local pct = (math.clamp(v, min, max) - min) / (max - min)
        updateSlider(pct)
    end
    function api:Get() return current end
    return api
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENT: Dropdown
-- ══════════════════════════════════════════════════════════════════════════════
local function createDropdown(parent, data)
    local cb      = data.Callback or function() end
    local options = data.Options  or {}
    local current = data.Default  or (options[1] or "Select")
    local open    = false

    local Wrap = frame({
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = C.Elevated,
        ClipsDescendants = false,
        Parent           = parent,
    })
    corner(Wrap, 10)
    stroke(Wrap, C.BorderSub, 1)

    local Header = Instance.new("TextButton")
    Header.Size             = UDim2.new(1, 0, 0, 42)
    Header.BackgroundTransparency = 1
    Header.Text             = ""
    Header.AutoButtonColor  = false
    Header.ZIndex           = 5
    Header.Parent           = Wrap

    local Lbl = label({
        Size           = UDim2.new(1, -80, 1, 0),
        Position       = UDim2.new(0, 14, 0, 0),
        Text           = data.Name or "Dropdown",
        TextColor3     = C.Text,
        Font           = Enum.Font.GothamMedium,
        TextSize       = 13,
        ZIndex         = 5,
        Parent         = Header,
    })

    local ValLbl = label({
        Size           = UDim2.new(0, 100, 1, 0),
        Position       = UDim2.new(1, -114, 0, 0),
        Text           = current,
        TextColor3     = C.AccentDim,
        Font           = Enum.Font.Gotham,
        TextSize       = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex         = 5,
        Parent         = Header,
    })

    local Arrow = label({
        Size           = UDim2.new(0, 20, 1, 0),
        Position       = UDim2.new(1, -24, 0, 0),
        Text           = "›",
        TextColor3     = C.TextSub,
        Font           = Enum.Font.GothamBold,
        TextSize       = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex         = 5,
        Parent         = Header,
    })

    -- dropdown list
    local List = frame({
        Size             = UDim2.new(1, 0, 0, 0),
        Position         = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = C.Surface,
        ClipsDescendants = true,
        ZIndex           = 20,
        Visible          = false,
        Parent           = Wrap,
    })
    corner(List, 10)
    stroke(List, C.Border, 1)

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent    = List
    padding(List, 4, 0, 0, 4)

    local function closeList()
        open = false
        tween(Arrow, 0.15, { Rotation = 0 })
        tween(List,  0.15, { Size = UDim2.new(1, 0, 0, 0) })
        task.delay(0.16, function() List.Visible = false end)
    end

    local function openList()
        open = true
        List.Visible = true
        local h = math.min(#options * 34 + 8, 160)
        tween(Arrow, 0.15, { Rotation = 90 })
        tween(List,  0.15, { Size = UDim2.new(1, 0, 0, h) })
    end

    for _, opt in ipairs(options) do
        local Item = Instance.new("TextButton")
        Item.Size             = UDim2.new(1, 0, 0, 34)
        Item.BackgroundColor3 = C.Surface
        Item.Text             = ""
        Item.AutoButtonColor  = false
        Item.ZIndex           = 21
        Item.Parent           = List

        local ItemLbl = label({
            Size           = UDim2.new(1, -20, 1, 0),
            Position       = UDim2.new(0, 12, 0, 0),
            Text           = opt,
            TextColor3     = C.Text,
            Font           = Enum.Font.Gotham,
            TextSize       = 12,
            ZIndex         = 21,
            Parent         = Item,
        })

        addHover(Item, C.Surface, C.Elevated, C.Active)

        Item.MouseButton1Click:Connect(function()
            current     = opt
            ValLbl.Text = opt
            closeList()
            cb(opt)
        end)
    end

    Header.MouseButton1Click:Connect(function()
        if open then closeList() else openList() end
    end)

    local api = { Frame = Wrap }
    function api:Set(v) current = v; ValLbl.Text = v end
    function api:Get() return current end
    return api
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENT: Keybind
-- ══════════════════════════════════════════════════════════════════════════════
local function createKeybind(parent, data)
    local cb      = data.Callback or function() end
    local current = data.Default  or Enum.KeyCode.Unknown
    local waiting = false

    local Row = frame({
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = C.Elevated,
        Parent           = parent,
    })
    corner(Row, 10)
    stroke(Row, C.BorderSub, 1)

    local Lbl = label({
        Size           = UDim2.new(1, -110, 1, 0),
        Position       = UDim2.new(0, 14, 0, 0),
        Text           = data.Name or "Keybind",
        TextColor3     = C.Text,
        Font           = Enum.Font.GothamMedium,
        TextSize       = 13,
        Parent         = Row,
    })

    local KeyBtn = Instance.new("TextButton")
    KeyBtn.Size             = UDim2.new(0, 80, 0, 26)
    KeyBtn.Position         = UDim2.new(1, -90, 0.5, -13)
    KeyBtn.BackgroundColor3 = C.Surface
    KeyBtn.Text             = current == Enum.KeyCode.Unknown and "None" or current.Name
    KeyBtn.TextColor3       = C.AccentDim
    KeyBtn.Font             = Enum.Font.GothamMedium
    KeyBtn.TextSize         = 11
    KeyBtn.AutoButtonColor  = false
    KeyBtn.Parent           = Row
    corner(KeyBtn, 7)
    stroke(KeyBtn, C.Border, 1)

    addHover(KeyBtn, C.Surface, C.Elevated, C.Active)

    KeyBtn.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting         = true
        KeyBtn.Text     = "..."
        KeyBtn.TextColor3 = C.Text
    end)

    UIS.InputBegan:Connect(function(inp, gp)
        if not waiting or gp then return end
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            current         = inp.KeyCode
            waiting         = false
            KeyBtn.Text     = inp.KeyCode.Name
            KeyBtn.TextColor3 = C.AccentDim
            cb(current)
        end
    end)

    local api = { Frame = Row }
    function api:Get() return current end
    return api
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENT: Label (info text)
-- ══════════════════════════════════════════════════════════════════════════════
local function createLabel(parent, data)
    local Lbl = label({
        Size           = UDim2.new(1, 0, 0, 28),
        Text           = data.Text or "",
        TextColor3     = data.Color or C.TextSub,
        Font           = Enum.Font.Gotham,
        TextSize       = 12,
        TextXAlignment = data.Align or Enum.TextXAlignment.Left,
        Parent         = parent,
    })
    local api = { Frame = Lbl }
    function api:Set(t) Lbl.Text = t end
    return api
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB BUILDER
-- ══════════════════════════════════════════════════════════════════════════════
function Library:CreateTab(name, icon)
    -- sidebar button
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size             = UDim2.new(1, -16, 0, 36)
    TabBtn.BackgroundColor3 = C.Surface
    TabBtn.Text             = ""
    TabBtn.AutoButtonColor  = false
    TabBtn.Parent           = Sidebar
    corner(TabBtn, 9)

    -- active indicator bar
    local Indicator = frame({
        Size             = UDim2.new(0, 3, 0, 18),
        Position         = UDim2.new(0, 0, 0.5, -9),
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 1,
        Parent           = TabBtn,
    })
    corner(Indicator, 2)

    local TabLbl = label({
        Size           = UDim2.new(1, -16, 1, 0),
        Position       = UDim2.new(0, 14, 0, 0),
        Text           = (icon and (icon .. "  ") or "") .. name,
        TextColor3     = C.TextSub,
        Font           = Enum.Font.GothamMedium,
        TextSize       = 13,
        Parent         = TabBtn,
    })

    -- page (scrolling)
    local Page = Instance.new("ScrollingFrame")
    Page.Size               = UDim2.new(1, 0, 1, 0)
    Page.CanvasSize         = UDim2.new(0, 0, 0, 0)
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = C.Border
    Page.BackgroundTransparency = 1
    Page.Visible            = false
    Page.Parent             = ContentArea

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.Padding       = UDim.new(0, 8)
    PageLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    PageLayout.Parent        = Page

    padding(Page, 16, 16, 16, 16)

    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 32)
    end)

    Pages[name] = { Page = Page, Button = TabBtn, Indicator = Indicator, Label = TabLbl }

    local function activate()
        for _, v in pairs(Pages) do
            v.Page.Visible = false
            tween(v.Button,    0.15, { BackgroundColor3 = C.Surface })
            tween(v.Indicator, 0.15, { BackgroundTransparency = 1 })
            tween(v.Label,     0.15, { TextColor3 = C.TextSub })
        end
        Page.Visible = true
        tween(TabBtn,    0.15, { BackgroundColor3 = C.Elevated })
        tween(Indicator, 0.15, { BackgroundTransparency = 0 })
        tween(TabLbl,    0.15, { TextColor3 = C.Text })
        Library.CurrentPage = Page
    end

    if not Library.CurrentPage then activate() end

    TabBtn.MouseButton1Click:Connect(activate)
    addHover(TabBtn, C.Surface, C.Hover, C.Active)

    -- ── Tab API ───────────────────────────────────────────────────────────────
    local Tab = {}

    function Tab:AddSection(sectionName)
        return createSection(Page, sectionName)
    end

    function Tab:AddToggle(data)
        return createToggle(Page, data)
    end

    function Tab:AddButton(data)
        return createButton(Page, data)
    end

    function Tab:AddSlider(data)
        return createSlider(Page, data)
    end

    function Tab:AddDropdown(data)
        return createDropdown(Page, data)
    end

    function Tab:AddKeybind(data)
        return createKeybind(Page, data)
    end

    function Tab:AddLabel(data)
        return createLabel(Page, data)
    end

    return Tab
end

return Library
