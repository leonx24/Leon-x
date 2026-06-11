-- Leon X UI Library v3.0 - Modern Card-Based (iOS Style)
-- Complete redesign with no sidebar, card grid layout

local Library = {}

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local lp           = Players.LocalPlayer
local gui          = lp:WaitForChild("PlayerGui")

-- Fetch version
local VERSION = "1.0"
pcall(function()
    VERSION = game:HttpGet("https://raw.githubusercontent.com/leonx24/Leon-x/main/version.txt?t="..os.time()):match("^%s*(.-)%s*$")
end)

-- iOS-Inspired Color Scheme
local C = {
    -- Backgrounds
    BG       = Color3.fromRGB(18, 18, 20),    -- Dark gray
    Card     = Color3.fromRGB(28, 28, 32),    -- Card background
    Elevated = Color3.fromRGB(38, 38, 42),    -- Elevated elements

    -- Accents (iOS blue)
    Accent   = Color3.fromRGB(10, 132, 255),  -- iOS blue
    AccentDim = Color3.fromRGB(30, 100, 200), -- Dimmed accent

    -- Text
    Text     = Color3.fromRGB(255, 255, 255), -- White
    TextDim  = Color3.fromRGB(142, 142, 147), -- Gray
    TextSub  = Color3.fromRGB(99, 99, 102),   -- Lighter gray

    -- Status
    Success  = Color3.fromRGB(52, 199, 89),   -- Green
    Warning  = Color3.fromRGB(255, 149, 0),   -- Orange
    Error    = Color3.fromRGB(255, 59, 48),   -- Red

    -- Toggle
    ToggleOff = Color3.fromRGB(58, 58, 60),
    ToggleOn  = Color3.fromRGB(52, 199, 89),
}

-- Helper functions
local function tw(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p):Play()
end

local function twSpring(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), p):Play()
end

local function rnd(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 12)
    c.Parent = p
end

local function shadow(parent, size)
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"
    s.BackgroundTransparency = 1
    s.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    s.ImageColor3 = Color3.fromRGB(0, 0, 0)
    s.ImageTransparency = 0.7
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(10, 10, 10, 10)
    s.Size = UDim2.new(1, size, 1, size)
    s.Position = UDim2.new(0, -size/2, 0, -size/2)
    s.ZIndex = parent.ZIndex - 1
    s.Parent = parent
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
    f.Parent = parent
    return f
end

local function mkL(parent, txt, sz, col, font, xa)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Text = txt or ""
    l.TextSize = sz or 14
    l.TextColor3 = col or C.Text
    l.Font = font or Enum.Font.GothamMedium
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

-- Destroy old
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
local WIN_W = math.clamp(isMobile and 380 or 520, 320, vp.X * 0.9)
local WIN_H = math.clamp(isMobile and 600 or 650, 400, vp.Y * 0.9)

-- Main container
local Container = mkF(Screen, C.BG)
Container.Name = "Container"
Container.Size = UDim2.new(0, WIN_W, 0, WIN_H)
Container.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Container.ClipsDescendants = true
Container.Visible = false
rnd(Container, 20)

-- Topbar
local Topbar = mkF(Container, C.Card)
Topbar.Size = UDim2.new(1, 0, 0, 60)
Topbar.ZIndex = 10

local TopGrad = Instance.new("UIGradient")
TopGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.Card),
    ColorSequenceKeypoint.new(1, C.BG)
})
TopGrad.Rotation = 90
TopGrad.Parent = Topbar

-- Logo/Title
local Logo = mkL(Topbar, "LEON X", 18, C.Text, Enum.Font.GothamBold)
Logo.Size = UDim2.new(0, 100, 1, 0)
Logo.Position = UDim2.new(0, 20, 0, 0)
Logo.TextXAlignment = Enum.TextXAlignment.Left

local Ver = mkL(Topbar, "v"..VERSION, 11, C.TextDim, Enum.Font.Gotham)
Ver.Size = UDim2.new(0, 50, 1, 0)
Ver.Position = UDim2.new(0, 110, 0, 0)

-- Active count
local ActiveCount = mkL(Topbar, "", 12, C.Success, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
ActiveCount.Size = UDim2.new(0, 100, 1, 0)
ActiveCount.Position = UDim2.new(1, -150, 0, 0)

-- Window buttons
local function mkBtn(icon, col, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 32, 0, 32)
    b.Position = UDim2.new(1, x, 0.5, -16)
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.BackgroundColor3 = col
    b.Text = icon
    b.TextColor3 = C.Text
    b.TextSize = 18
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.ZIndex = 11
    b.Parent = Topbar
    rnd(b, 16)

    b.MouseEnter:Connect(function()
        twSpring(b, 0.2, {BackgroundColor3 = Color3.fromRGB(col.R+20, col.G+20, col.B+20)})
        twSpring(b, 0.2, {Size = UDim2.new(0, 34, 0, 34)})
    end)

    b.MouseLeave:Connect(function()
        tw(b, 0.2, {BackgroundColor3 = col})
        tw(b, 0.2, {Size = UDim2.new(0, 32, 0, 32)})
    end)

    return b
end

local BtnClose = mkBtn("×", C.Error, -10)
local BtnMin = mkBtn("−", C.Elevated, -50)
BtnClose.Visible = false
BtnMin.Visible = false

-- Content scroll
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -80)
Content.Position = UDim2.new(0, 10, 0, 70)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = C.TextDim
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = Container

-- Grid layout for cards
local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.new(0, (WIN_W - 40) / 3 - 5, 0, 80)
Grid.CellPadding = UDim2.new(0, 8, 0, 8)
Grid.SortOrder = Enum.SortOrder.LayoutOrder
Grid.Parent = Content

Grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, Grid.AbsoluteContentSize.Y + 20)
end)

-- State
local Pages = {}
local CurrentPage = nil
Library.Registry = {}
Library._allComponents = {}
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
        ActiveCount.Text = count .. " ACTIVE"
    else
        ActiveCount.Text = ""
    end
end

Library._onToggleChanged = function()
    updateActiveCount()
end

-- Drag
do
    local dragging, dragStart, startPos = false, nil, nil

    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Container.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Container.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Create tab card
function Library:CreateTab(name, icon)
    local tabCard = Instance.new("TextButton")
    tabCard.Size = UDim2.new(0, 100, 0, 80)
    tabCard.BackgroundColor3 = C.Card
    tabCard.Text = ""
    tabCard.AutoButtonColor = false
    tabCard.LayoutOrder = #Pages + 1
    tabCard.Parent = Content
    rnd(tabCard, 16)

    local iconLabel = mkL(tabCard, icon or "📁", 32, C.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    iconLabel.Size = UDim2.new(1, 0, 0, 40)
    iconLabel.Position = UDim2.new(0, 0, 0, 8)

    local nameLabel = mkL(tabCard, name, 12, C.TextDim, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 1, -28)

    -- Page container
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -20, 1, -80)
    page.Position = UDim2.new(0, 10, 0, 70)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = C.TextDim
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = Container

    local pageList = Instance.new("UIListLayout")
    pageList.Padding = UDim.new(0, 12)
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Parent = page

    pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 20)
    end)

    Pages[name] = {
        card = tabCard,
        page = page,
        icon = iconLabel,
        name = nameLabel
    }

    -- Click handler
    tabCard.MouseButton1Click:Connect(function()
        if CurrentPage == name then
            -- Back to grid
            Content.Visible = true
            page.Visible = false
            CurrentPage = nil
        else
            -- Show page
            Content.Visible = false
            for _, p in pairs(Pages) do
                p.page.Visible = false
            end
            page.Visible = true
            CurrentPage = name
        end
    end)

    -- Hover
    tabCard.MouseEnter:Connect(function()
        twSpring(tabCard, 0.2, {BackgroundColor3 = C.Elevated})
        twSpring(tabCard, 0.2, {Size = UDim2.new(0, 105, 0, 85)})
    end)

    tabCard.MouseLeave:Connect(function()
        tw(tabCard, 0.2, {BackgroundColor3 = C.Card})
        tw(tabCard, 0.2, {Size = UDim2.new(0, 100, 0, 80)})
    end)

    local Tab = {}
    Tab._page = page
    Tab._name = name

    -- Section (header only, no visual separator)
    function Tab:AddSection(name)
        local section = mkL(page, name:upper(), 11, C.TextDim, Enum.Font.GothamBold)
        section.Size = UDim2.new(1, 0, 0, 24)
        section.LayoutOrder = #page:GetChildren()
        return section
    end

    -- Toggle (iOS-style card)
    function Tab:AddToggle(data)
        local cb = data.Callback or function() end
        local on = data.Default == true

        local card = mkF(page, C.Card)
        card.Size = UDim2.new(1, 0, 0, 56)
        card.LayoutOrder = #page:GetChildren()
        rnd(card, 12)

        local label = mkL(card, data.Name or "Toggle", 15, C.Text, Enum.Font.GothamMedium)
        label.Size = UDim2.new(1, -80, 1, 0)
        label.Position = UDim2.new(0, 16, 0, 0)

        -- iOS-style toggle switch
        local switchBg = mkF(card, on and C.ToggleOn or C.ToggleOff)
        switchBg.Size = UDim2.new(0, 51, 0, 31)
        switchBg.Position = UDim2.new(1, -67, 0.5, -15.5)
        rnd(switchBg, 15.5)

        local knob = mkF(switchBg, Color3.fromRGB(255, 255, 255))
        knob.Size = UDim2.new(0, 27, 0, 27)
        knob.Position = on and UDim2.new(1, -29, 0.5, -13.5) or UDim2.new(0, 2, 0.5, -13.5)
        rnd(knob, 13.5)

        local function set(v, silent)
            local prev = on
            on = v
            if on then
                tw(switchBg, 0.3, {BackgroundColor3 = C.ToggleOn})
                twSpring(knob, 0.3, {Position = UDim2.new(1, -29, 0.5, -13.5)})
            else
                tw(switchBg, 0.3, {BackgroundColor3 = C.ToggleOff})
                twSpring(knob, 0.3, {Position = UDim2.new(0, 2, 0.5, -13.5)})
            end

            if prev ~= on and data.Flag and Library._onToggleChanged then
                Library._onToggleChanged(on)
            end
            if not silent then
                cb(on)
            end
        end

        -- Click handler
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = card
        btn.MouseButton1Click:Connect(function() set(not on) end)

        -- Hover
        btn.MouseEnter:Connect(function()
            tw(card, 0.2, {BackgroundColor3 = C.Elevated})
        end)
        btn.MouseLeave:Connect(function()
            tw(card, 0.2, {BackgroundColor3 = C.Card})
        end)

        local api = {Frame = card}
        function api:Set(v) set(v, true) end
        function api:Get() return on end

        if data.Flag then
            Library.Registry[data.Flag] = api
            if data.Callback then
                api.Callback = data.Callback
            end
        end

        return api
    end

    -- Button
    function Tab:AddButton(data)
        local cb = data.Callback or function() end

        local card = mkF(page, C.Accent)
        card.Size = UDim2.new(1, 0, 0, 48)
        card.LayoutOrder = #page:GetChildren()
        rnd(card, 12)

        local label = mkL(card, data.Name or "Button", 15, C.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
        label.Size = UDim2.new(1, 0, 1, 0)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = card

        btn.MouseButton1Click:Connect(function()
            tw(card, 0.1, {BackgroundColor3 = C.AccentDim})
            task.wait(0.1)
            tw(card, 0.2, {BackgroundColor3 = C.Accent})
            cb()
        end)

        btn.MouseEnter:Connect(function()
            twSpring(card, 0.2, {Size = UDim2.new(1, 0, 0, 52)})
        end)
        btn.MouseLeave:Connect(function()
            tw(card, 0.2, {Size = UDim2.new(1, 0, 0, 48)})
        end)

        local api = {Frame = card}
        function api:SetText(t) label.Text = t end
        return api
    end

    -- Slider
    function Tab:AddSlider(data)
        local cb = data.Callback or function() end
        local mn = data.Min or 0
        local mx = data.Max or 100
        local suffix = data.Suffix or ""
        local cur = math.clamp(data.Default or mn, mn, mx)

        local card = mkF(page, C.Card)
        card.Size = UDim2.new(1, 0, 0, 76)
        card.LayoutOrder = #page:GetChildren()
        rnd(card, 12)

        local label = mkL(card, data.Name or "Slider", 15, C.Text, Enum.Font.GothamMedium)
        label.Size = UDim2.new(1, -100, 0, 24)
        label.Position = UDim2.new(0, 16, 0, 12)

        local valueLabel = mkL(card, tostring(cur) .. suffix, 15, C.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
        valueLabel.Size = UDim2.new(0, 80, 0, 24)
        valueLabel.Position = UDim2.new(1, -96, 0, 12)

        -- Slider track
        local trackBg = mkF(card, C.Elevated)
        trackBg.Size = UDim2.new(1, -32, 0, 6)
        trackBg.Position = UDim2.new(0, 16, 1, -24)
        rnd(trackBg, 3)

        local fill = mkF(trackBg, C.Accent)
        fill.Size = UDim2.new((cur - mn) / (mx - mn), 0, 1, 0)
        rnd(fill, 3)

        local knob = mkF(trackBg, Color3.fromRGB(255, 255, 255))
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new((cur - mn) / (mx - mn), -10, 0.5, -10)
        knob.ZIndex = 3
        rnd(knob, 10)

        local function update(pct)
            pct = math.clamp(pct, 0, 1)
            cur = math.floor(mn + (mx - mn) * pct + 0.5)
            tw(fill, 0.15, {Size = UDim2.new(pct, 0, 1, 0)})
            twSpring(knob, 0.15, {Position = UDim2.new(pct, -10, 0.5, -10)})
            valueLabel.Text = tostring(cur) .. suffix
            cb(cur)
        end

        local sliding = false
        trackBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                update((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X)
            end
        end)

        UIS.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X)
            end
        end)

        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)

        local api = {Frame = card}
        function api:Set(v) update((math.clamp(v, mn, mx) - mn) / (mx - mn)) end
        function api:Get() return cur end

        if data.Flag then
            Library.Registry[data.Flag] = api
            if data.Callback then
                api.Callback = data.Callback
            end
        end

        return api
    end

    -- Dropdown
    function Tab:AddDropdown(data)
        local cb = data.Callback or function() end
        local opts = data.Options or {}
        local cur = data.Default or (opts[1] or "—")

        local card = mkF(page, C.Card)
        card.Size = UDim2.new(1, 0, 0, 56)
        card.LayoutOrder = #page:GetChildren()
        rnd(card, 12)

        local label = mkL(card, data.Name or "Dropdown", 15, C.Text, Enum.Font.GothamMedium)
        label.Size = UDim2.new(0, 200, 1, 0)
        label.Position = UDim2.new(0, 16, 0, 0)

        local value = mkL(card, cur, 14, C.Accent, Enum.Font.Gotham, Enum.TextXAlignment.Right)
        value.Size = UDim2.new(1, -230, 1, 0)
        value.Position = UDim2.new(0, 220, 0, 0)

        local arrow = mkL(card, "›", 18, C.TextDim, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.Position = UDim2.new(1, -36, 0, 0)

        -- Click to open (simplified - full implementation would add dropdown menu)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = card

        btn.MouseEnter:Connect(function()
            tw(card, 0.2, {BackgroundColor3 = C.Elevated})
        end)
        btn.MouseLeave:Connect(function()
            tw(card, 0.2, {BackgroundColor3 = C.Card})
        end)

        local api = {Frame = card}
        function api:Set(v) cur = v; value.Text = v end
        function api:Get() return cur end
        function api:SetOptions(newOpts) opts = newOpts end

        if data.Flag then
            Library.Registry[data.Flag] = api
            if data.Callback then
                api.Callback = data.Callback
            end
        end

        return api
    end

    -- Keybind (simplified)
    function Tab:AddKeybind(data)
        local cb = data.Callback or function() end
        local cur = data.Default or Enum.KeyCode.Unknown

        local card = mkF(page, C.Card)
        card.Size = UDim2.new(1, 0, 0, 56)
        card.LayoutOrder = #page:GetChildren()
        rnd(card, 12)

        local label = mkL(card, data.Name or "Keybind", 15, C.Text, Enum.Font.GothamMedium)
        label.Size = UDim2.new(1, -120, 1, 0)
        label.Position = UDim2.new(0, 16, 0, 0)

        local value = mkL(card, cur.Name, 14, C.Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
        value.Size = UDim2.new(0, 100, 1, 0)
        value.Position = UDim2.new(1, -116, 0, 0)

        local api = {Frame = card}
        function api:Set(k) cur = k; value.Text = k.Name end
        function api:Get() return cur end

        if data.Flag then
            Library.Registry[data.Flag] = api
            if data.Callback then
                api.Callback = data.Callback
            end
        end

        return api
    end

    -- Label
    function Tab:AddLabel(data)
        local label = mkL(page, data.Text or "", 14, data.Color or C.TextDim, Enum.Font.Gotham, data.Align or Enum.TextXAlignment.Left)
        label.Size = UDim2.new(1, 0, 0, 32)
        label.LayoutOrder = #page:GetChildren()

        local api = {Frame = label}
        function api:Set(t) label.Text = t end
        return api
    end

    -- TextInput (simplified)
    function Tab:AddTextInput(data)
        local cb = data.Callback or function() end
        local cur = data.Default or ""

        local card = mkF(page, C.Card)
        card.Size = UDim2.new(1, 0, 0, 56)
        card.LayoutOrder = #page:GetChildren()
        rnd(card, 12)

        local label = mkL(card, data.Name or "Input", 15, C.Text, Enum.Font.GothamMedium)
        label.Size = UDim2.new(0, 120, 1, 0)
        label.Position = UDim2.new(0, 16, 0, 0)

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(1, -156, 0, 32)
        input.Position = UDim2.new(0, 140, 0.5, -16)
        input.BackgroundColor3 = C.Elevated
        input.BorderSizePixel = 0
        input.Text = cur
        input.PlaceholderText = data.Placeholder or ""
        input.PlaceholderColor3 = C.TextSub
        input.TextColor3 = C.Text
        input.Font = Enum.Font.Gotham
        input.TextSize = 14
        input.ClearTextOnFocus = false
        input.Parent = card
        rnd(input, 8)

        input.FocusLost:Connect(function(enter)
            if enter then
                cur = input.Text
                cb(cur)
            end
        end)

        local api = {Frame = card}
        function api:Get() return input.Text end
        function api:Set(v) input.Text = v; cur = v end
        return api
    end

    return Tab
end

-- Show/Hide
function Library:Show()
    Container.Visible = true
    BtnClose.Visible = true
    BtnMin.Visible = true
end

function Library:Hide()
    Container.Visible = false
    BtnClose.Visible = false
    BtnMin.Visible = false
end

function Library:IsVisible()
    return Container.Visible
end

-- Toggle keybind
Library._toggleKey = Enum.KeyCode.O
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Library._toggleKey then
        if Container.Visible then
            Library:Hide()
        else
            Library:Show()
        end
    end
end)

function Library:SetToggleKey(key)
    self._toggleKey = key
end

-- Minimize
BtnMin.MouseButton1Click:Connect(function()
    Library:Hide()
end)

-- Close
BtnClose.MouseButton1Click:Connect(function()
    Screen:Destroy()
end)

-- Notifications (iOS-style)
function Library:Notify(data)
    local title = data.Title or "Leon X"
    local text = data.Text or ""
    local ntype = data.Type or "info"
    local duration = data.Duration or 3

    local typeColors = {
        info = C.Accent,
        success = C.Success,
        warn = C.Warning,
        error = C.Error
    }
    local col = typeColors[ntype] or C.Accent

    -- Notification card
    local notif = mkF(Screen, C.Card)
    notif.Size = UDim2.new(0, 300, 0, 0)
    notif.Position = UDim2.new(0.5, -150, 0, -100)
    notif.ZIndex = 100
    rnd(notif, 16)

    -- Accent bar
    local bar = mkF(notif, col)
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.Position = UDim2.new(0, 0, 0, 0)
    rnd(bar, 0)

    local titleLabel = mkL(notif, title, 14, C.Text, Enum.Font.GothamBold)
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 12, 0, 8)

    local textLabel = mkL(notif, text, 12, C.TextDim, Enum.Font.Gotham)
    textLabel.Size = UDim2.new(1, -20, 0, 32)
    textLabel.Position = UDim2.new(0, 12, 0, 28)
    textLabel.TextWrapped = true
    textLabel.TextYAlignment = Enum.TextYAlignment.Top

    -- Calculate height
    local h = math.max(64, 40 + textLabel.TextBounds.Y)

    -- Slide in
    twSpring(notif, 0.4, {
        Size = UDim2.new(0, 300, 0, h),
        Position = UDim2.new(0.5, -150, 0, 20)
    })

    -- Slide out and destroy
    task.delay(duration, function()
        tw(notif, 0.3, {
            Position = UDim2.new(0.5, -150, 0, -100),
            BackgroundTransparency = 1
        })
        task.wait(0.35)
        pcall(function() notif:Destroy() end)
    end)
end

-- Theme system (simplified - only supports iOS style)
Library._currentTheme = "iOS"
Library.Registry["Theme"] = {
    Get = function() return Library._currentTheme end,
    Set = function(_, v) Library._currentTheme = v end
}

function Library:SetTheme(name)
    -- iOS theme is built-in, could add more themes here
    Library._currentTheme = name
end

-- Splash screen (simplified)
function Library:SetSplashProgress(pct)
    -- No-op for card-based UI (instant load)
end

function Library:HideSplash()
    Container.Visible = true
    BtnClose.Visible = true
    BtnMin.Visible = true
end

-- Panic key
Library._panicKey = Enum.KeyCode.Delete
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Library._panicKey then
        Library:Hide()
        for flag, api in pairs(Library.Registry) do
            if api.Get and api.Callback then
                local ok, val = pcall(function() return api:Get() end)
                if ok and val == true then
                    pcall(function() api:Set(false) end)
                    pcall(function() api.Callback(false) end)
                end
            end
        end
    end
end)

function Library:SetPanicKey(key)
    self._panicKey = key
end

print("Leon X UI v3.0 - Card-Based Layout Loaded!")

return Library
