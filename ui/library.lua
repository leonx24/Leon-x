-- Leon X UI Library v1.0
local Library = {}

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lp           = Players.LocalPlayer
local gui          = lp:WaitForChild("PlayerGui")

local C = {
    BG       = Color3.fromRGB(11,11,11),
    Surface  = Color3.fromRGB(17,17,17),
    Elevated = Color3.fromRGB(23,23,23),
    Border   = Color3.fromRGB(36,36,36),
    Accent   = Color3.fromRGB(255,255,255),
    Dim      = Color3.fromRGB(130,130,130),
    Text     = Color3.fromRGB(228,228,228),
    Sub      = Color3.fromRGB(95,95,95),
    OffTrack = Color3.fromRGB(44,44,44),
    OnTrack  = Color3.fromRGB(195,195,195),
    Hover    = Color3.fromRGB(29,29,29),
    Press    = Color3.fromRGB(38,38,38),
    Red      = Color3.fromRGB(170,40,40),
    RedH     = Color3.fromRGB(205,58,58),
}

local function tw(o,t,p)
    TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),p):Play()
end
local function rnd(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p end
local function strk(p,col) local s=Instance.new("UIStroke"); s.Color=col or C.Border; s.Thickness=1; s.Parent=p end
local function pdg(p,t,l,r,b)
    local u=Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,t or 0)
    u.PaddingLeft=UDim.new(0,l or 0)
    u.PaddingRight=UDim.new(0,r or 0)
    u.PaddingBottom=UDim.new(0,b or 0)
    u.Parent=p
end
local function mkF(parent,bg)
    local f=Instance.new("Frame")
    f.BackgroundColor3=bg or C.BG
    f.BorderSizePixel=0
    f.Parent=parent
    return f
end
local function mkL(parent,txt,sz,col,font,xa)
    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1
    l.BorderSizePixel=0
    l.Text=txt or ""
    l.TextSize=sz or 13
    l.TextColor3=col or C.Text
    l.Font=font or Enum.Font.GothamMedium
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.Parent=parent
    return l
end
local function hvr(b,n,h,a)
    b.MouseEnter:Connect(function() tw(b,.12,{BackgroundColor3=h}) end)
    b.MouseLeave:Connect(function() tw(b,.15,{BackgroundColor3=n}) end)
    b.MouseButton1Down:Connect(function() tw(b,.06,{BackgroundColor3=a}) end)
    b.MouseButton1Up:Connect(function() tw(b,.1,{BackgroundColor3=h}) end)
end

-- destroy old instance
pcall(function() gui:FindFirstChild("LeonX"):Destroy() end)

local Screen = Instance.new("ScreenGui")
Screen.Name = "LeonX"
Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder = 999
Screen.IgnoreGuiInset = true   -- prevent safe-area cutoff on mobile
Screen.Parent = gui

-- ── Responsive sizing ─────────────────────────────────────────────────────────
-- On mobile screens smaller than the default 640×410, scale the window down
-- so it fits within 90% of the viewport with a minimum of 320×260.
local vp       = workspace.CurrentCamera.ViewportSize
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local maxW     = math.floor(vp.X * (isMobile and 0.94 or 1))
local maxH     = math.floor(vp.Y * (isMobile and 0.88 or 1))
local WIN_W    = math.clamp(640, 320, maxW)
local WIN_H    = math.clamp(isMobile and math.min(410, maxH) or 410, 260, maxH)
-- sidebar and topbar scale proportionally
local SIDE_W   = math.floor(WIN_W * (130/640))   -- ~130px on desktop
local TOP_H    = 40

-- border frame
local R = 12
local BG = mkF(Screen, C.Border)
BG.Size = UDim2.new(0, WIN_W+2, 0, WIN_H+2)
BG.Position = UDim2.new(0.5, -(WIN_W+2)/2, 0.5, -(WIN_H+2)/2)
BG.Visible = false
rnd(BG, R)

local Win = mkF(Screen, C.BG)
Win.Name = "Win"
Win.Size = UDim2.new(0, WIN_W, 0, WIN_H)
Win.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Win.ClipsDescendants = true
Win.Visible = false
rnd(Win, R)

-- topbar
local Top = mkF(Win, C.BG)
Top.Size = UDim2.new(1,0,0,TOP_H)

local TopDiv = mkF(Top, C.Border)
TopDiv.Size = UDim2.new(1,0,0,1)
TopDiv.Position = UDim2.new(0,0,1,-1)

local Dot = mkF(Top, C.Accent)
Dot.Size = UDim2.new(0,7,0,7)
Dot.Position = UDim2.new(0,16,0.5,-3)
rnd(Dot, 4)

local TitleL = mkL(Top,"Leon X",14,C.Text,Enum.Font.GothamBold)
TitleL.Size = UDim2.new(0,80,1,0)
TitleL.Position = UDim2.new(0,30,0,0)

local VerL = mkL(Top,"v1.0",10,C.Sub,Enum.Font.Gotham)
VerL.Size = UDim2.new(0,36,1,0)
VerL.Position = UDim2.new(0,108,0,0)

-- active features counter in topbar
local ActiveL = mkL(Top,"",10,C.Dim,Enum.Font.Gotham,Enum.TextXAlignment.Right)
ActiveL.Size = UDim2.new(0,80,1,0)
ActiveL.Position = UDim2.new(1,-168,0,0)   -- left of window buttons

-- track active toggle count — recount from scratch to avoid drift
Library._activeCount = 0
local function updateActiveCount()
    -- recount all active toggles from Registry (source of truth)
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
        ActiveL.Text = count .. " active"
        ActiveL.TextColor3 = C.Accent
    else
        ActiveL.Text = ""
        ActiveL.TextColor3 = C.Dim
    end
end
Library._onToggleChanged = function(_)
    -- ignore the passed value, always recount for accuracy
    updateActiveCount()
end

-- window buttons — parented to Top so they auto-follow the window
local function mkWinBtn(icon, bg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,24,0,24)
    b.BackgroundColor3 = bg
    b.Text = icon
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 5
    b.Parent = Top   -- inside topbar, not Screen
    rnd(b, 6)
    return b
end

local BtnX = mkWinBtn("×", C.Red)
local BtnM = mkWinBtn("−", C.Elevated)
-- anchor to right side of topbar
BtnX.AnchorPoint = Vector2.new(1, 0.5)
BtnX.Position    = UDim2.new(1, -8, 0.5, 0)
BtnM.AnchorPoint = Vector2.new(1, 0.5)
BtnM.Position    = UDim2.new(1, -38, 0.5, 0)
BtnX.Visible = false   -- hidden until splash finishes
BtnM.Visible = false
hvr(BtnX, C.Red, C.RedH, Color3.fromRGB(215,55,55))
hvr(BtnM, C.Elevated, C.Hover, C.Press)

-- sidebar
local Side = mkF(Win, C.Surface)
Side.Size = UDim2.new(0, SIDE_W, 1, -TOP_H)
Side.Position = UDim2.new(0, 0, 0, TOP_H)

local SideDiv = mkF(Side, C.Border)
SideDiv.Size = UDim2.new(0,1,1,0)
SideDiv.Position = UDim2.new(1,0,0,0)

local SideScroll = Instance.new("ScrollingFrame")
SideScroll.Size = UDim2.new(1,0,1,-44)
SideScroll.CanvasSize = UDim2.new(0,0,0,0)
SideScroll.ScrollBarThickness = 0
SideScroll.BackgroundTransparency = 1
SideScroll.BorderSizePixel = 0
SideScroll.Parent = Side
pdg(SideScroll, 10, 0, 0, 10)

local SideLL = Instance.new("UIListLayout")
SideLL.Padding = UDim.new(0,4)
SideLL.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLL.SortOrder = Enum.SortOrder.LayoutOrder
SideLL.Parent = SideScroll
SideLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SideScroll.CanvasSize = UDim2.new(0,0,0,SideLL.AbsoluteContentSize.Y+20)
end)

-- search box at bottom of sidebar
local SearchBox = mkF(Side, C.Elevated)
SearchBox.Name            = "SearchBox"
SearchBox.Size            = UDim2.new(1,-8,0,30)
SearchBox.Position        = UDim2.new(0,4,1,-38)
SearchBox.BorderSizePixel = 0
rnd(SearchBox, 8)
strk(SearchBox)

local SearchIcon = mkL(SearchBox, "🔍", 12, C.Sub, Enum.Font.Gotham, Enum.TextXAlignment.Center)
SearchIcon.Size     = UDim2.new(0,22,1,0)
SearchIcon.Position = UDim2.new(0,4,0,0)

local SearchInput = Instance.new("TextBox")
SearchInput.Size              = UDim2.new(1,-30,1,-6)
SearchInput.Position          = UDim2.new(0,26,0,3)
SearchInput.BackgroundTransparency = 1
SearchInput.BorderSizePixel   = 0
SearchInput.Text              = ""
SearchInput.PlaceholderText   = "Search..."
SearchInput.PlaceholderColor3 = C.Sub
SearchInput.TextColor3        = C.Text
SearchInput.Font               = Enum.Font.Gotham
SearchInput.TextSize           = 11
SearchInput.ClearTextOnFocus   = false
SearchInput.TextXAlignment     = Enum.TextXAlignment.Left
SearchInput.Parent             = SearchBox

-- ── Global Search state (SearchPage created after Content below) ──────────────
Library._searchActive   = false
Library._preSearchTab   = nil
Library._movedFrames    = {}
Library._searchHeaders  = {}

local SearchPage          -- forward declaration, initialized after Content
local NoResultsLabel      -- forward declaration
local SearchPageLayout    -- forward declaration

local function restoreMovedFrames()
    for _, entry in ipairs(Library._movedFrames) do
        pcall(function()
            entry.frame.Parent      = entry.originalParent
            entry.frame.LayoutOrder = entry.originalOrder
            entry.frame.Visible     = true
        end)
    end
    Library._movedFrames = {}
    for _, h in ipairs(Library._searchHeaders) do
        pcall(function() h:Destroy() end)
    end
    Library._searchHeaders = {}
    if NoResultsLabel then NoResultsLabel.Visible = false end
end

local function captureCurrentTab(Pages)
    for _, v in pairs(Pages) do
        if v.page.Visible then
            local captured = v
            Library._preSearchTab = function()
                for _, vv in pairs(Pages) do
                    vv.page.Visible = false
                    tw(vv.btn,.15,{BackgroundColor3=C.Surface})
                    tw(vv.bar,.15,{BackgroundTransparency=1})
                    tw(vv.lbl,.15,{TextColor3=C.Sub})
                    if vv.ico then tw(vv.ico,.15,{TextColor3=C.Sub}) end
                end
                captured.page.Visible = true
                tw(captured.btn,.15,{BackgroundColor3=C.Elevated})
                tw(captured.bar,.15,{BackgroundTransparency=0})
                tw(captured.lbl,.15,{TextColor3=C.Text})
                if captured.ico then tw(captured.ico,.15,{TextColor3=C.Accent}) end
            end
            return
        end
    end
end

-- section header for search results grouped by tab
local function mkSearchHeader(tabName)
    local h = mkF(SearchPage, C.BG)
    h.BackgroundTransparency = 1
    h.Size = UDim2.new(1,0,0,24)
    local line = mkF(h, C.Border)
    line.Size = UDim2.new(1,0,0,1)
    line.Position = UDim2.new(0,0,0.5,0)
    local pill = mkF(h, C.BG)
    pill.AnchorPoint = Vector2.new(0,0.5)
    pill.Position    = UDim2.new(0,0,0.5,0)
    pill.Size        = UDim2.new(0,80,1,0)
    local t = mkL(pill, tabName:upper(), 10, C.Dim, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
    t.Size     = UDim2.new(1,0,1,0)
    t.Position = UDim2.new(0,4,0,0)
    task.defer(function()
        if t.TextBounds.X > 0 then
            pill.Size = UDim2.new(0, t.TextBounds.X+10, 1, 0)
        end
    end)
    return h
end

-- doSearch is defined here but captures Pages by upvalue set below
local _Pages  -- forward ref to Pages table
local function doSearch(query)
    query = query:match("^%s*(.-)%s*$"):lower()
    if not _Pages then return end

    -- ── clear search ─────────────────────────────────────────────────────────
    if query == "" then
        if Library._searchActive then
            Library._searchActive = false
            restoreMovedFrames()
            if SearchPage then SearchPage.Visible = false end
            if Library._preSearchTab then
                Library._preSearchTab()
                Library._preSearchTab = nil
            end
        end
        return
    end

    -- ── entering search mode ──────────────────────────────────────────────────
    if not Library._searchActive then
        Library._searchActive = true
        captureCurrentTab(_Pages)
        for _, v in pairs(_Pages) do
            v.page.Visible = false
            tw(v.btn,.15,{BackgroundColor3=C.Surface})
            tw(v.bar,.15,{BackgroundTransparency=1})
            tw(v.lbl,.15,{TextColor3=C.Sub})
            if v.ico then tw(v.ico,.15,{TextColor3=C.Sub}) end
        end
    else
        restoreMovedFrames()
    end

    -- ── collect matches grouped by tab ────────────────────────────────────────
    local tabOrder = {}
    local tabMap   = {}
    for _, entry in ipairs(Library._allComponents) do
        local ename = entry.name:lower()
        if ename:find(query, 1, true) then
            local tname = entry.tabName or "Other"
            if not tabMap[tname] then
                tabMap[tname] = {}
                table.insert(tabOrder, tname)
            end
            table.insert(tabMap[tname], entry)
        end
    end

    if SearchPage then
        SearchPage.Visible = true
        SearchPage.CanvasPosition = Vector2.zero
    end

    if #tabOrder == 0 then
        if NoResultsLabel then NoResultsLabel.Visible = true end
        return
    end
    if NoResultsLabel then NoResultsLabel.Visible = false end

    local order = 0
    for _, tname in ipairs(tabOrder) do
        local header = mkSearchHeader(tname)
        header.LayoutOrder = order
        order = order + 1
        table.insert(Library._searchHeaders, header)

        for _, entry in ipairs(tabMap[tname]) do
            table.insert(Library._movedFrames, {
                frame          = entry.frame,
                originalParent = entry.frame.Parent,
                originalOrder  = entry.frame.LayoutOrder,
            })
            entry.frame.Visible     = true
            entry.frame.Parent      = SearchPage
            entry.frame.LayoutOrder = order
            order = order + 1
        end
    end
end

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    doSearch(SearchInput.Text)
end)

-- content area
local Content = mkF(Win, C.BG)
Content.BackgroundTransparency = 1
Content.Size = UDim2.new(1, -(SIDE_W+1), 1, -TOP_H)
Content.Position = UDim2.new(0, SIDE_W+1, 0, TOP_H)

-- ── Search results page (needs Content to exist first) ────────────────────────
SearchPage = Instance.new("ScrollingFrame")
SearchPage.Size                 = UDim2.new(1,0,1,0)
SearchPage.CanvasSize           = UDim2.new(0,0,0,0)
SearchPage.ScrollBarThickness   = 2
SearchPage.ScrollBarImageColor3 = C.Border
SearchPage.BackgroundTransparency = 1
SearchPage.BorderSizePixel      = 0
SearchPage.Visible              = false
SearchPage.Parent               = Content
SearchPageLayout = Instance.new("UIListLayout")
SearchPageLayout.Padding        = UDim.new(0,8)
SearchPageLayout.SortOrder      = Enum.SortOrder.LayoutOrder
SearchPageLayout.Parent         = SearchPage
pdg(SearchPage, 14, 14, 14, 14)
SearchPageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SearchPage.CanvasSize = UDim2.new(0,0,0, SearchPageLayout.AbsoluteContentSize.Y+28)
end)
NoResultsLabel = mkL(SearchPage, "No results", 13, C.Sub, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
NoResultsLabel.Size       = UDim2.new(1,0,0,40)
NoResultsLabel.LayoutOrder = 9999
NoResultsLabel.Visible    = false

local Pages = {}
_Pages = Pages   -- wire forward ref so doSearch can access Pages
Library._first = true
Library._currentTheme = "Dark"
Library.Registry = {}   -- Flag → component api, populated by Tab:Add* when Flag is set
Library._allComponents = {}  -- {frame, name, page} for search
Library.PanicKey = Enum.KeyCode.Delete

-- internal helper: register a component api if data.Flag is provided
local function reg(data, api)
    if type(data.Flag) == "string" and data.Flag ~= "" then
        -- store callback on api so ConfigManager can fire it on load
        if type(data.Callback) == "function" then
            api.Callback = data.Callback
        end
        Library.Registry[data.Flag] = api
    end
    return api
end

-- Theme pseudo-component so ConfigManager can save/load the active theme
Library.Registry["Theme"] = {
    Get = function() return Library._currentTheme end,
    Set = function(_, v)
        if type(v) == "string" then
            Library:SetTheme(v)
        end
    end,
}

-- drag (Mouse + Touch)
do
    local on,ds,sp = false,nil,nil
    local function isTap(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end
    Top.InputBegan:Connect(function(i)
        if isTap(i) then on=true; ds=i.Position; sp=Win.Position end
    end)
    UIS.InputChanged:Connect(function(i)
        if on and (i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position-ds
            local nx,ny = sp.X.Offset+d.X, sp.Y.Offset+d.Y
            Win.Position = UDim2.new(sp.X.Scale,nx,sp.Y.Scale,ny)
            BG.Position  = UDim2.new(sp.X.Scale,nx-1,sp.Y.Scale,ny-1)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if isTap(i) then on=false end
    end)
end

-- resize handle — corner triangle indicator
-- resize handle — parented to Win, anchored to bottom-right corner
local ResBtn = Instance.new("TextButton")
ResBtn.Size = UDim2.new(0,18,0,18)
ResBtn.AnchorPoint = Vector2.new(1,1)
ResBtn.Position = UDim2.new(1,-2,1,-2)
ResBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
ResBtn.BackgroundTransparency = 1
ResBtn.Text = ""
ResBtn.AutoButtonColor = false
ResBtn.BorderSizePixel = 0
ResBtn.ZIndex = 5
ResBtn.Visible = false
ResBtn.Parent = Win   -- inside Win, auto-follows window size

-- two diagonal lines to form a resize corner indicator
local function mkDiagLine(parent, x1,y1,x2,y2)
    local dx = x2-x1; local dy = y2-y1
    local len = math.sqrt(dx*dx+dy*dy)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = C.Dim
    f.BorderSizePixel = 0
    f.AnchorPoint = Vector2.new(0.5,0.5)
    f.Size = UDim2.new(0,len,0,1)
    f.Position = UDim2.new(0,(x1+x2)/2,0,(y1+y2)/2)
    f.Rotation = math.deg(math.atan2(dy,dx))
    f.ZIndex = 6
    f.Parent = parent
    return f
end
mkDiagLine(ResBtn, 2,14, 14,2)
mkDiagLine(ResBtn, 7,14, 14,7)

do
    local on,rs,ss = false,nil,nil
    local function isTap(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end
    ResBtn.InputBegan:Connect(function(i)
        if isTap(i) then on=true; rs=i.Position; ss=Win.Size end
    end)
    UIS.InputChanged:Connect(function(i)
        if on and (i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position-rs
            local nw = math.clamp(ss.X.Offset+d.X, isMobile and 280 or 480, 1400)
            local nh = math.clamp(ss.Y.Offset+d.Y, isMobile and 220 or 300, 900)
            Win.Size = UDim2.new(0,nw,0,nh)
            BG.Size  = UDim2.new(0,nw+2,0,nh+2)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if isTap(i) then on=false end
    end)
end

-- float pill (minimized state)
local Float = Instance.new("TextButton")
Float.Size = UDim2.new(0,52,0,36)
Float.Position = UDim2.new(0,18,0.5,-18)
Float.BackgroundColor3 = C.Surface
Float.Text = ""
Float.AutoButtonColor = false
Float.BorderSizePixel = 0
Float.Visible = false
Float.ZIndex = 5
Float.Parent = Screen
rnd(Float, 10)
strk(Float)
hvr(Float, C.Surface, C.Elevated, C.Press)

local FloatTitle = mkL(Float, "LX", 12, C.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
FloatTitle.Size = UDim2.new(1,0,0,16)
FloatTitle.Position = UDim2.new(0,0,0,6)

local FloatCount = mkL(Float, "", 9, C.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Center)
FloatCount.Size = UDim2.new(1,0,0,12)
FloatCount.Position = UDim2.new(0,0,0,20)

-- hook active count updates to also refresh Float pill
local _origToggleChanged = Library._onToggleChanged
Library._onToggleChanged = function(isOn)
    _origToggleChanged(isOn)
    local count = Library._activeCount
    if count > 0 then
        FloatCount.Text = count .. " on"
        FloatCount.TextColor3 = C.Accent
    else
        FloatCount.Text = ""
    end
end

local function showWin()
    Win.Visible=true; BG.Visible=true
    Float.Visible=false
    BtnX.Visible=true; BtnM.Visible=true; ResBtn.Visible=true
end
local function hideWin()
    Win.Visible=false; BG.Visible=false
    Float.Visible=true
    BtnX.Visible=false; BtnM.Visible=false; ResBtn.Visible=false
end

-- expose for external keybind wiring
function Library:Show() showWin() end
function Library:Hide() hideWin() end
function Library:IsVisible() return Win.Visible end

-- toggle open/close keybind (default O, configurable via SetToggleKey)
Library._toggleKey = Enum.KeyCode.O
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode ~= Library._toggleKey then return end
    if Win.Visible then hideWin() else showWin() end
end)

function Library:SetToggleKey(keyCode)
    self._toggleKey = keyCode
end

do
    local on,ds,fp,mv = false,nil,nil,false
    -- support both Mouse and Touch
    local function isTap(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end
    Float.InputBegan:Connect(function(i)
        if isTap(i) then
            on=true; mv=false; ds=i.Position; fp=Float.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if on and (i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position-ds
            if math.abs(d.X)>6 or math.abs(d.Y)>6 then mv=true end
            Float.Position = UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if isTap(i) and on then
            on=false
            if not mv then showWin() end
            task.wait(); mv=false
        end
    end)
end

BtnM.MouseButton1Click:Connect(hideWin)

-- Panic key: disable all active toggles + hide window
Library._panicKey = Enum.KeyCode.Delete
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode ~= Library._panicKey then return end
    -- hide window
    hideWin()
    -- disable all active toggles via their callbacks
    for flag, api in pairs(Library.Registry) do
        if api.Get and api.Callback then
            local ok, val = pcall(function() return api:Get() end)
            if ok and val == true then
                pcall(function() api:Set(false) end)
                pcall(function() api.Callback(false) end)
            end
        end
    end
end)

function Library:SetPanicKey(keyCode)
    self._panicKey = keyCode
end
BtnX.MouseButton1Click:Connect(function() Screen:Destroy() end)

-- ── Tooltip system ────────────────────────────────────────────────────────────
local Tooltip = mkF(Screen, C.Surface)
Tooltip.Name              = "Tooltip"
Tooltip.Size              = UDim2.new(0, 160, 0, 28)
Tooltip.BackgroundTransparency = 1
Tooltip.BorderSizePixel   = 0
Tooltip.ZIndex            = 50
Tooltip.Visible           = false
Tooltip.Parent            = Screen
rnd(Tooltip, 6)
local _tStroke = Instance.new("UIStroke")
_tStroke.Color     = C.Border
_tStroke.Thickness = 1
_tStroke.Parent    = Tooltip

local TooltipLabel = mkL(Tooltip, "", 11, C.Text, Enum.Font.Gotham, Enum.TextXAlignment.Left)
TooltipLabel.Size          = UDim2.new(1, -12, 1, -8)
TooltipLabel.Position      = UDim2.new(0, 6, 0, 4)
TooltipLabel.TextWrapped   = true
TooltipLabel.ZIndex        = 51

local _tooltipThread = nil

local function addTooltip(frame, text)
    frame.MouseEnter:Connect(function()
        _tooltipThread = task.delay(0.5, function()
            _tooltipThread = nil
            -- measure text to set height
            local maxW = 200
            TooltipLabel.Text = text
            Tooltip.Size = UDim2.new(0, maxW, 0, 28)
            -- allow label to wrap and measure
            task.defer(function()
                local boundsY = TooltipLabel.TextBounds.Y
                local h = math.max(28, boundsY + 12)
                -- position near cursor
                local mp = UIS:GetMouseLocation()
                local sw = workspace.CurrentCamera.ViewportSize.X
                local sh = workspace.CurrentCamera.ViewportSize.Y
                local px = math.clamp(mp.X + 12, 0, sw - maxW - 4)
                local py = math.clamp(mp.Y + 16, 0, sh - h - 4)
                Tooltip.Size     = UDim2.new(0, maxW, 0, h)
                Tooltip.Position = UDim2.new(0, px, 0, py)
                Tooltip.BackgroundTransparency = 0
                Tooltip.Visible  = true
            end)
        end)
    end)
    frame.MouseLeave:Connect(function()
        if _tooltipThread then
            task.cancel(_tooltipThread)
            _tooltipThread = nil
        end
        Tooltip.Visible = false
        Tooltip.BackgroundTransparency = 1
    end)
end

-- components

local function mkSection(parent, name)
    local w = mkF(parent, C.BG)
    w.BackgroundTransparency = 1
    w.Size = UDim2.new(1,0,0,24)
    local line = mkF(w, C.Border)
    line.Size = UDim2.new(1,0,0,1)
    line.Position = UDim2.new(0,0,0.5,0)
    local pill = mkF(w, C.BG)
    pill.AnchorPoint = Vector2.new(0,0.5)
    pill.Position = UDim2.new(0,0,0.5,0)
    pill.Size = UDim2.new(0,80,1,0)
    -- uppercase section name, slightly brighter
    local t = mkL(pill, name:upper(), 10, C.Dim, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
    t.Size = UDim2.new(1,0,1,0)
    t.Position = UDim2.new(0,4,0,0)
    task.defer(function()
        if t.TextBounds.X > 0 then
            pill.Size = UDim2.new(0, t.TextBounds.X+10, 1, 0)
        end
    end)
    return w
end

local function mkToggle(parent, data)
    local cb = data.Callback or function() end
    local on = data.Default == true
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1,0,0,42)
    row.BackgroundColor3 = C.Elevated
    row.Text = ""
    row.AutoButtonColor = false
    row.BorderSizePixel = 0
    row.Parent = parent
    rnd(row, 10); strk(row)
    local nl = mkL(row, data.Name or "Toggle", 13, C.Text, Enum.Font.GothamMedium)
    nl.Size = UDim2.new(1,-68,1,0)
    nl.Position = UDim2.new(0,14,0,0)
    local track = mkF(row, on and C.OnTrack or C.OffTrack)
    track.Size = UDim2.new(0,38,0,20)
    track.Position = UDim2.new(1,-52,0.5,-10)
    rnd(track, 10)
    local knob = mkF(track, on and C.BG or C.Dim)
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
    rnd(knob, 7)
    hvr(row, C.Elevated, C.Hover, C.Press)
    local function set(v, silent)
        local prev = on
        on = v
        if on then
            tw(track,.18,{BackgroundColor3=C.OnTrack})
            tw(knob,.18,{Position=UDim2.new(1,-17,0.5,-7),BackgroundColor3=C.BG})
        else
            tw(track,.18,{BackgroundColor3=C.OffTrack})
            tw(knob,.18,{Position=UDim2.new(0,3,0.5,-7),BackgroundColor3=C.Dim})
        end
        -- always update counter when value actually changed
        if prev ~= on and data.Flag and Library._onToggleChanged then
            Library._onToggleChanged(on)
        end
        if not silent then
            cb(on)
        end
    end
    row.MouseButton1Click:Connect(function() set(not on) end)
    local api = {Frame=row}
    function api:Set(v) set(v,true) end
    function api:Get() return on end
    addTooltip(row, data.Desc or data.Name or "Toggle")
    return api
end

local function mkButton(parent, data)
    local cb = data.Callback or function() end
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,38)
    b.BackgroundColor3 = C.Elevated
    b.Text = data.Name or "Button"
    b.TextColor3 = C.Text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Parent = parent
    rnd(b, 10); strk(b)
    hvr(b, C.Elevated, C.Hover, C.Press)
    b.MouseButton1Click:Connect(function()
        tw(b,.07,{BackgroundColor3=Color3.fromRGB(48,48,48)})
        task.delay(.14, function() tw(b,.15,{BackgroundColor3=C.Elevated}) end)
        cb()
    end)
    local api = {Frame=b}
    function api:SetText(t) b.Text=t end
    addTooltip(b, data.Desc or data.Name or "Button")
    return api
end

local function mkSlider(parent, data)
    local cb = data.Callback or function() end
    local mn = data.Min or 0
    local mx = data.Max or 100
    local sf = data.Suffix or ""
    local cur = math.clamp(data.Default or mn, mn, mx)
    local w = mkF(parent, C.Elevated)
    w.Size = UDim2.new(1,0,0,54)
    rnd(w, 10); strk(w)
    local nl = mkL(w, data.Name or "Slider", 13, C.Text, Enum.Font.GothamMedium)
    nl.Size = UDim2.new(1,-80,0,22)
    nl.Position = UDim2.new(0,14,0,8)
    local vl = mkL(w, tostring(cur)..sf, 12, C.Dim, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
    vl.Size = UDim2.new(0,70,0,22)
    vl.Position = UDim2.new(1,-80,0,8)
    local trackBg = mkF(w, C.OffTrack)
    trackBg.Size = UDim2.new(1,-28,0,4)
    trackBg.Position = UDim2.new(0,14,1,-16)
    rnd(trackBg, 2)
    local fill = mkF(trackBg, C.Accent)
    fill.Size = UDim2.new((cur-mn)/(mx-mn),0,1,0)
    rnd(fill, 2)
    local knob = mkF(trackBg, C.Accent)
    knob.Size = UDim2.new(0,12,0,12)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new((cur-mn)/(mx-mn),0,0.5,0)
    knob.ZIndex = 3
    rnd(knob, 6)
    local function upd(pct)
        pct = math.clamp(pct,0,1)
        cur = math.floor(mn+(mx-mn)*pct+.5)
        tw(fill,.05,{Size=UDim2.new(pct,0,1,0)})
        tw(knob,.05,{Position=UDim2.new(pct,0,0.5,0)})
        vl.Text = tostring(cur)..sf
        cb(cur)
    end
    local sl = false
    local function isTouchOrMouse1(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end
    trackBg.InputBegan:Connect(function(i)
        if isTouchOrMouse1(i) then
            sl=true; upd((i.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if sl and (i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch) then
            upd((i.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if isTouchOrMouse1(i) then sl=false end
    end)
    local api = {Frame=w}
    function api:Set(v) upd((math.clamp(v,mn,mx)-mn)/(mx-mn)) end
    function api:Get() return cur end
    addTooltip(w, data.Desc or data.Name or "Slider")
    return api
end

local function mkDropdown(parent, data)
    local cb = data.Callback or function() end
    local opts = data.Options or {}
    local cur = data.Default or (opts[1] or "—")
    local open = false
    local w = mkF(parent, C.Elevated)
    w.Size = UDim2.new(1,0,0,42)
    rnd(w, 10); strk(w)
    local hdr = Instance.new("TextButton")
    hdr.Size = UDim2.new(1,0,1,0)
    hdr.BackgroundTransparency = 1
    hdr.Text = ""
    hdr.AutoButtonColor = false
    hdr.BorderSizePixel = 0
    hdr.Parent = w
    local nl = mkL(hdr, data.Name or "Dropdown", 13, C.Text, Enum.Font.GothamMedium)
    nl.Size = UDim2.new(1,-110,1,0)
    nl.Position = UDim2.new(0,14,0,0)
    local vl = mkL(hdr, cur, 12, C.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Right)
    vl.Size = UDim2.new(0,90,1,0)
    vl.Position = UDim2.new(1,-106,0,0)
    local ar = mkL(hdr, "›", 16, C.Sub, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    ar.Size = UDim2.new(0,18,1,0)
    ar.Position = UDim2.new(1,-22,0,0)
    local itemH = 34
    local maxVisibleH = 180   -- max height sebelum scroll
    local fullH = math.min(#opts*itemH+8, maxVisibleH)

    -- list floats on Screen — pakai ScrollingFrame supaya bisa di-scroll
    local List = Instance.new("ScrollingFrame")
    List.Size                  = UDim2.new(0,10,0,0)
    List.CanvasSize            = UDim2.new(0,0,0,0)
    List.ScrollBarThickness    = 3
    List.ScrollBarImageColor3  = C.Border
    List.ScrollingDirection    = Enum.ScrollingDirection.Y
    List.BackgroundColor3      = C.Surface
    List.BorderSizePixel       = 0
    List.Visible               = false
    List.ZIndex                = 20
    List.ClipsDescendants      = true
    List.ElasticBehavior       = Enum.ElasticBehavior.Never
    List.Parent                = Screen
    rnd(List, 10); strk(List)

    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent    = List
    pdg(List, 4, 0, 0, 4)

    -- auto-update CanvasSize as items are added
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        List.CanvasSize = UDim2.new(0,0,0, ll.AbsoluteContentSize.Y + 8)
    end)
    for _, opt in ipairs(opts) do
        local it = Instance.new("TextButton")
        it.Size = UDim2.new(1,0,0,itemH)
        it.BackgroundColor3 = C.Surface
        it.Text = ""
        it.AutoButtonColor = false
        it.BorderSizePixel = 0
        it.ZIndex = 21
        it.Parent = List
        local il = mkL(it, opt, 12, C.Text, Enum.Font.Gotham)
        il.Size = UDim2.new(1,-20,1,0)
        il.Position = UDim2.new(0,12,0,0)
        il.ZIndex = 21
        hvr(it, C.Surface, C.Elevated, C.Press)
        it.MouseButton1Click:Connect(function()
            cur=opt; vl.Text=opt; open=false
            tw(ar,.15,{Rotation=0})
            tw(List,.15,{Size=UDim2.new(0,List.Size.X.Offset,0,0)})
            task.delay(.16, function() List.Visible=false end)
            cb(opt)
        end)
    end
    local function closeDD()
        open=false
        tw(ar,.15,{Rotation=0})
        tw(List,.15,{Size=UDim2.new(0,List.Size.X.Offset,0,0)})
        task.delay(.16, function() List.Visible=false end)
    end
    local function openDD()
        open=true
        local ap = w.AbsolutePosition
        local as = w.AbsoluteSize
        -- recalculate height based on current item count
        local contentH = #opts * itemH + 8
        fullH = math.min(contentH, maxVisibleH)
        List.Position = UDim2.new(0,ap.X,0,ap.Y+as.Y+4)
        List.Size = UDim2.new(0,as.X,0,0)
        List.Visible = true
        List.CanvasPosition = Vector2.zero   -- reset scroll to top
        tw(ar,.15,{Rotation=90})
        tw(List,.2,{Size=UDim2.new(0,as.X,0,fullH)})
    end
    hdr.MouseButton1Click:Connect(function()
        if open then closeDD() else openDD() end
    end)
    UIS.InputBegan:Connect(function(i)
        if not open or i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local mp = i.Position
        local function out(f)
            local p=f.AbsolutePosition; local s=f.AbsoluteSize
            return mp.X<p.X or mp.X>p.X+s.X or mp.Y<p.Y or mp.Y>p.Y+s.Y
        end
        if out(List) and out(w) then closeDD() end
    end)
    local api = {Frame=w}
    function api:Set(v) cur=v; vl.Text=v end
    function api:Get() return cur end
    function api:SetOptions(newOpts)
        opts = newOpts
        fullH = math.min(#opts*itemH+8, maxVisibleH)
        -- destroy old items
        for _, child in ipairs(List:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        -- rebuild
        for _, opt in ipairs(opts) do
            local it = Instance.new("TextButton")
            it.Size = UDim2.new(1,0,0,itemH)
            it.BackgroundColor3 = C.Surface
            it.Text = ""
            it.AutoButtonColor = false
            it.BorderSizePixel = 0
            it.ZIndex = 21
            it.Parent = List
            local il = mkL(it, opt, 12, C.Text, Enum.Font.Gotham)
            il.Size = UDim2.new(1,-20,1,0)
            il.Position = UDim2.new(0,12,0,0)
            il.ZIndex = 21
            hvr(it, C.Surface, C.Elevated, C.Press)
            it.MouseButton1Click:Connect(function()
                cur=opt; vl.Text=opt; open=false
                tw(ar,.15,{Rotation=0})
                tw(List,.15,{Size=UDim2.new(0,List.Size.X.Offset,0,0)})
                task.delay(.16, function() List.Visible=false end)
                cb(opt)
            end)
        end
        if #opts > 0 then
            cur = opts[1]; vl.Text = opts[1]
        end
    end
    addTooltip(w, data.Desc or data.Name or "Dropdown")
    return api
end

local function mkKeybind(parent, data)
    local cb = data.Callback or function() end
    local cur = data.Default or Enum.KeyCode.Unknown
    local waiting = false
    local row = mkF(parent, C.Elevated)
    row.Size = UDim2.new(1,0,0,42)
    rnd(row, 10); strk(row)
    local nl = mkL(row, data.Name or "Keybind", 13, C.Text, Enum.Font.GothamMedium)
    nl.Size = UDim2.new(1,-110,1,0)
    nl.Position = UDim2.new(0,14,0,0)
    local kb = Instance.new("TextButton")
    kb.Size = UDim2.new(0,78,0,26)
    kb.Position = UDim2.new(1,-88,0.5,-13)
    kb.BackgroundColor3 = C.Surface
    kb.Text = cur==Enum.KeyCode.Unknown and "None" or cur.Name
    kb.TextColor3 = C.Dim
    kb.Font = Enum.Font.GothamMedium
    kb.TextSize = 11
    kb.AutoButtonColor = false
    kb.BorderSizePixel = 0
    kb.Parent = row
    rnd(kb, 7); strk(kb)
    hvr(kb, C.Surface, C.Elevated, C.Press)
    kb.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting=true; kb.Text="..."; kb.TextColor3=C.Text
    end)
    UIS.InputBegan:Connect(function(i, gp)
        if not waiting or gp then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            cur=i.KeyCode; waiting=false
            kb.Text=i.KeyCode.Name; kb.TextColor3=C.Dim; cb(cur)
        end
    end)
    local api = {Frame=row}
    function api:Set(keyCode)
        -- always silent: update state + label, exit waiting, never fires cb
        waiting = false
        cur = keyCode
        kb.Text = keyCode.Name
        kb.TextColor3 = C.Dim
    end
    function api:Get() return cur end
    return api
end

local function mkLabel(parent, data)
    local l = mkL(parent, data.Text or "", 12, data.Color or C.Sub, Enum.Font.Gotham,
        data.Align or Enum.TextXAlignment.Left)
    l.Size = UDim2.new(1,0,0,24)
    l.BorderSizePixel = 0
    local api = {Frame=l}
    function api:Set(t) l.Text=t end
    return api
end

local function mkColorPicker(parent, data)
    local cb = data.Callback or function() end
    local cur = data.Default or Color3.fromRGB(255,255,255)
    local w = mkF(parent, C.Elevated)
    w.Size = UDim2.new(1,0,0,54)
    rnd(w, 10); strk(w)
    local nl = mkL(w, data.Name or "Color", 13, C.Text, Enum.Font.GothamMedium)
    nl.Size = UDim2.new(1,-80,0,22)
    nl.Position = UDim2.new(0,14,0,8)
    local swatch = mkF(w, cur)
    swatch.Size = UDim2.new(0,22,0,22)
    swatch.Position = UDim2.new(1,-36,0,8)
    rnd(swatch, 6)
    local hueBar = mkF(w, C.OffTrack)
    hueBar.Size = UDim2.new(1,-28,0,6)
    hueBar.Position = UDim2.new(0,14,1,-18)
    rnd(hueBar, 3)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,1,1)),
        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
        ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5,1,1)),
        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1,1)),
        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
        ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,1,1)),
    })
    grad.Parent = hueBar
    local cursor = mkF(hueBar, Color3.new(1,1,1))
    cursor.Size = UDim2.new(0,8,0,8)
    cursor.AnchorPoint = Vector2.new(0.5,0.5)
    cursor.Position = UDim2.new(0,0,0.5,0)
    cursor.ZIndex = 3
    rnd(cursor, 4)
    strk(cursor, Color3.new(0,0,0))
    local function pick(pct)
        pct = math.clamp(pct,0,1)
        cur = Color3.fromHSV(pct,1,1)
        cursor.Position = UDim2.new(pct,0,0.5,0)
        swatch.BackgroundColor3 = cur
        cb(cur)
    end
    local picking = false
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            picking=true; pick((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if picking and i.UserInputType == Enum.UserInputType.MouseMovement then
            pick((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then picking=false end
    end)
    local api = {Frame=w}
    function api:Set(c) cur=c; swatch.BackgroundColor3=c end
    function api:Get() return cur end
    return api
end

local function mkTextInput(parent, data)
    local cb          = data.Callback    or function() end
    local placeholder = data.Placeholder or "Type here..."
    local label       = data.Name        or "Input"
    local current     = data.Default     or ""

    local w = mkF(parent, C.Elevated)
    w.Size = UDim2.new(1,0,0,42)
    rnd(w,10); strk(w)

    local nl = mkL(w, label, 13, C.Text, Enum.Font.GothamMedium)
    nl.Size = UDim2.new(0,90,1,0); nl.Position = UDim2.new(0,14,0,0)

    -- TextBox
    local box = Instance.new("TextBox")
    box.Size                  = UDim2.new(1,-110,0,26)
    box.Position              = UDim2.new(0,104,0.5,-13)
    box.BackgroundColor3      = C.Surface
    box.BorderSizePixel       = 0
    box.Text                  = current
    box.PlaceholderText       = placeholder
    box.PlaceholderColor3     = C.Sub
    box.TextColor3            = C.Text
    box.Font                  = Enum.Font.Gotham
    box.TextSize              = 12
    box.ClearTextOnFocus      = false
    box.ClipsDescendants      = true
    box.Parent                = w
    rnd(box, 7); strk(box)

    -- confirm on Enter or focus lost
    local function confirm()
        current = box.Text
        cb(current)
    end
    box.FocusLost:Connect(function(enter)
        if enter then confirm() end
        -- dim placeholder when empty
        if box.Text == "" then
            box.TextColor3 = C.Sub
        else
            box.TextColor3 = C.Text
        end
    end)
    box.Focused:Connect(function()
        box.TextColor3 = C.Text
    end)

    local api = { Frame = w }
    function api:Get() return box.Text end
    function api:Set(v) box.Text = v; current = v end
    return api
end

function Library:CreateTab(name, icon)
    icon = icon or ""
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-10,0,34)
    btn.BackgroundColor3 = C.Surface
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = SideScroll
    rnd(btn, 8)
    local bar = mkF(btn, C.Accent)
    bar.Size = UDim2.new(0,3,0,16)
    bar.Position = UDim2.new(0,0,0.5,-8)
    bar.BackgroundTransparency = 1
    rnd(bar, 2)
    -- icon label
    local il = mkL(btn, icon, 14, C.Sub, Enum.Font.GothamBold)
    il.Size = UDim2.new(0,22,1,0)
    il.Position = UDim2.new(0,12,0,0)
    il.TextXAlignment = Enum.TextXAlignment.Center
    -- tab name label
    local bl = mkL(btn, name, 12, C.Sub, Enum.Font.GothamMedium)
    bl.Size = UDim2.new(1,-38,1,0)
    bl.Position = UDim2.new(0,36,0,0)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1,0,1,0)
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = C.Border
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Visible = false
    page.Parent = Content
    local pl = Instance.new("UIListLayout")
    pl.Padding = UDim.new(0,8)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    pl.Parent = page
    pdg(page, 14, 14, 14, 14)
    pl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0,0,0,pl.AbsoluteContentSize.Y+28)
    end)
    Pages[name] = {page=page, btn=btn, bar=bar, lbl=bl, ico=il}
    local function activate()
        for _,v in pairs(Pages) do
            v.page.Visible = false
            tw(v.btn,.15,{BackgroundColor3=C.Surface})
            tw(v.bar,.15,{BackgroundTransparency=1})
            tw(v.lbl,.15,{TextColor3=C.Sub})
            if v.ico then tw(v.ico,.15,{TextColor3=C.Sub}) end
        end
        page.Visible = true
        tw(btn,.15,{BackgroundColor3=C.Elevated})
        tw(bar,.15,{BackgroundTransparency=0})
        tw(bl,.15,{TextColor3=C.Text})
        if il then tw(il,.15,{TextColor3=C.Accent}) end
    end
    if Library._first then
        Library._first = false
        page.Visible = true
        btn.BackgroundColor3 = C.Elevated
        bar.BackgroundTransparency = 0
        bl.TextColor3 = C.Text
        if il then il.TextColor3 = C.Accent end
    end
    btn.MouseButton1Click:Connect(function()
        -- if search is active, clear it first then activate this tab
        if Library._searchActive then
            SearchInput.Text = ""
            -- doSearch("") will run via the Text signal, but we need to ensure
            -- we activate THIS tab, not the previously captured one
            Library._searchActive = false
            restoreMovedFrames()
            SearchPage.Visible = false
            Library._preSearchTab = nil
        end
        activate()
    end)
    hvr(btn, C.Surface, C.Hover, C.Press)
    local Tab = {}
    local tabName = name   -- captured in closure
    local _order  = 0      -- per-tab sequential LayoutOrder counter

    -- assign LayoutOrder and register in _allComponents
    local function finalize(frame, cname)
        frame.LayoutOrder = _order
        _order = _order + 1
        table.insert(Library._allComponents, {
            frame   = frame,
            name    = cname or "",
            page    = page,
            tabName = tabName,
        })
    end

    function Tab:AddSection(n)
        local f = mkSection(page, n)
        f.LayoutOrder = _order; _order = _order + 1
        return f
    end
    function Tab:AddToggle(d)
        Library._currentTabName = tabName
        local api = reg(d, mkToggle(page, d))
        finalize(api.Frame, d.Name)
        return api
    end
    function Tab:AddButton(d)
        Library._currentTabName = tabName
        local api = mkButton(page, d)
        finalize(api.Frame, d.Name)
        return api
    end
    function Tab:AddSlider(d)
        Library._currentTabName = tabName
        local api = reg(d, mkSlider(page, d))
        finalize(api.Frame, d.Name)
        return api
    end
    function Tab:AddDropdown(d)
        Library._currentTabName = tabName
        local api = reg(d, mkDropdown(page, d))
        finalize(api.Frame, d.Name)
        return api
    end
    function Tab:AddKeybind(d)
        Library._currentTabName = tabName
        local api = reg(d, mkKeybind(page, d))
        finalize(api.Frame, d.Name)
        return api
    end
    function Tab:AddLabel(d)
        Library._currentTabName = tabName
        local api = mkLabel(page, d)
        finalize(api.Frame, d.Text or d.Name or "")
        return api
    end
    function Tab:AddColorPicker(d)
        Library._currentTabName = tabName
        local api = mkColorPicker(page, d)
        finalize(api.Frame, d.Name)
        return api
    end
    function Tab:AddTextInput(d)
        Library._currentTabName = tabName
        local api = mkTextInput(page, d)
        finalize(api.Frame, d.Name)
        return api
    end
    return Tab
end

-- ── Theme system ──────────────────────────────────────────────────────────────
local THEMES = {
    -- ── Dark (default) ─ pure black monochrome
    Dark = {
        BG       = Color3.fromRGB(11, 11, 11),
        Surface  = Color3.fromRGB(17, 17, 17),
        Elevated = Color3.fromRGB(23, 23, 23),
        Border   = Color3.fromRGB(36, 36, 36),
        Accent   = Color3.fromRGB(255,255,255),
        Dim      = Color3.fromRGB(130,130,130),
        Text     = Color3.fromRGB(228,228,228),
        Sub      = Color3.fromRGB(95, 95, 95),
        OffTrack = Color3.fromRGB(44, 44, 44),
        OnTrack  = Color3.fromRGB(210,210,210),
        Hover    = Color3.fromRGB(29, 29, 29),
        Press    = Color3.fromRGB(38, 38, 38),
        Red      = Color3.fromRGB(170,40, 40),
        RedH     = Color3.fromRGB(205,58, 58),
    },
    -- ── Midnight ─ deep navy blue, electric blue accent
    Midnight = {
        BG       = Color3.fromRGB(6,   8,  16),
        Surface  = Color3.fromRGB(10,  13, 25),
        Elevated = Color3.fromRGB(15,  19, 38),
        Border   = Color3.fromRGB(30,  40, 75),
        Accent   = Color3.fromRGB(80, 150,255),
        Dim      = Color3.fromRGB(70,  95,160),
        Text     = Color3.fromRGB(200,215,255),
        Sub      = Color3.fromRGB(65,  85,145),
        OffTrack = Color3.fromRGB(22,  28, 55),
        OnTrack  = Color3.fromRGB(80, 150,255),
        Hover    = Color3.fromRGB(16,  21, 42),
        Press    = Color3.fromRGB(22,  28, 55),
        Red      = Color3.fromRGB(180, 50, 50),
        RedH     = Color3.fromRGB(215, 70, 70),
    },
    -- ── Rose ─ dark charcoal with soft rose/pink accent
    Rose = {
        BG       = Color3.fromRGB(12, 10, 12),
        Surface  = Color3.fromRGB(20, 16, 20),
        Elevated = Color3.fromRGB(28, 22, 28),
        Border   = Color3.fromRGB(55, 38, 50),
        Accent   = Color3.fromRGB(240,100,140),
        Dim      = Color3.fromRGB(160, 80,110),
        Text     = Color3.fromRGB(245,220,230),
        Sub      = Color3.fromRGB(130, 90,110),
        OffTrack = Color3.fromRGB(48,  34, 44),
        OnTrack  = Color3.fromRGB(240,100,140),
        Hover    = Color3.fromRGB(30,  24, 30),
        Press    = Color3.fromRGB(42,  32, 40),
        Red      = Color3.fromRGB(200, 55, 75),
        RedH     = Color3.fromRGB(230, 75, 95),
    },
    -- ── Emerald ─ deep forest green, neon mint accent
    Emerald = {
        BG       = Color3.fromRGB(8,  13, 10),
        Surface  = Color3.fromRGB(12, 19, 15),
        Elevated = Color3.fromRGB(17, 27, 21),
        Border   = Color3.fromRGB(28, 50, 36),
        Accent   = Color3.fromRGB(50, 220,130),
        Dim      = Color3.fromRGB(50, 140, 90),
        Text     = Color3.fromRGB(200,240,220),
        Sub      = Color3.fromRGB(55, 110, 80),
        OffTrack = Color3.fromRGB(20,  38, 28),
        OnTrack  = Color3.fromRGB(50, 220,130),
        Hover    = Color3.fromRGB(14,  22, 17),
        Press    = Color3.fromRGB(20,  32, 24),
        Red      = Color3.fromRGB(200, 60, 60),
        RedH     = Color3.fromRGB(230, 80, 80),
    },
    -- ── Amber ─ dark warm brown, golden yellow accent
    Amber = {
        BG       = Color3.fromRGB(13, 10,  6),
        Surface  = Color3.fromRGB(20, 16,  9),
        Elevated = Color3.fromRGB(28, 22, 12),
        Border   = Color3.fromRGB(55, 42, 18),
        Accent   = Color3.fromRGB(255,190, 50),
        Dim      = Color3.fromRGB(160,120, 40),
        Text     = Color3.fromRGB(250,235,200),
        Sub      = Color3.fromRGB(130, 98, 45),
        OffTrack = Color3.fromRGB(48,  36, 15),
        OnTrack  = Color3.fromRGB(255,190, 50),
        Hover    = Color3.fromRGB(28,  22, 10),
        Press    = Color3.fromRGB(40,  30, 14),
        Red      = Color3.fromRGB(200, 60, 40),
        RedH     = Color3.fromRGB(230, 80, 55),
    },
    -- ── Violet ─ deep purple, lavender accent
    Violet = {
        BG       = Color3.fromRGB(10,  8, 16),
        Surface  = Color3.fromRGB(16, 12, 26),
        Elevated = Color3.fromRGB(22, 17, 38),
        Border   = Color3.fromRGB(48, 32, 75),
        Accent   = Color3.fromRGB(165,110,255),
        Dim      = Color3.fromRGB(110, 75,175),
        Text     = Color3.fromRGB(230,220,255),
        Sub      = Color3.fromRGB(95,  70,155),
        OffTrack = Color3.fromRGB(35,  24, 58),
        OnTrack  = Color3.fromRGB(165,110,255),
        Hover    = Color3.fromRGB(18,  14, 30),
        Press    = Color3.fromRGB(28,  20, 48),
        Red      = Color3.fromRGB(195, 55,100),
        RedH     = Color3.fromRGB(225, 75,120),
    },
}

-- Tracked instances for live recolor
-- Each entry: { instance, property, colorKey }
local _tracked = {}

local function track(inst, prop, key)
    table.insert(_tracked, {inst, prop, key})
end

-- Wrap mkF and mkL to auto-track color properties
local _origMkF = mkF
local function mkFT(parent, bg, key)
    local f = _origMkF(parent, bg)
    if key then track(f, "BackgroundColor3", key) end
    return f
end

function Library:SetTheme(name)
    local t = THEMES[name]
    if not t then return end

    Library._currentTheme = name   -- track active theme for config save

    -- build a color map: old color value → new color value
    -- based on current C vs new theme
    local colorMap = {}
    for k, newColor in pairs(t) do
        local oldColor = C[k]
        if oldColor then
            -- use string key as lookup (Color3 not hashable directly)
            local key = string.format("%.3f,%.3f,%.3f",
                oldColor.R, oldColor.G, oldColor.B)
            colorMap[key] = newColor
        end
    end

    -- update C table to new theme values
    for k, v in pairs(t) do C[k] = v end

    -- helper to remap a color
    local function remap(col)
        if not col then return nil end
        local k = string.format("%.3f,%.3f,%.3f", col.R, col.G, col.B)
        return colorMap[k]
    end

    -- traverse ALL descendants of Screen and recolor
    for _, inst in ipairs(Screen:GetDescendants()) do
        pcall(function()
            if inst:IsA("Frame") or inst:IsA("ScrollingFrame")
            or inst:IsA("TextButton") or inst:IsA("TextBox") then
                local mapped = remap(inst.BackgroundColor3)
                if mapped then inst.BackgroundColor3 = mapped end
            end
            if inst:IsA("TextLabel") or inst:IsA("TextButton")
            or inst:IsA("TextBox") then
                local mapped = remap(inst.TextColor3)
                if mapped then inst.TextColor3 = mapped end
            end
            if inst:IsA("UIStroke") then
                local mapped = remap(inst.Color)
                if mapped then inst.Color = mapped end
            end
        end)
    end

    -- also recolor floating dropdown lists (parented to Screen directly)
    -- already covered by Screen:GetDescendants()
end
-- Container stacks toasts bottom-right, parented to Screen
local NotifContainer = Instance.new("Frame")
NotifContainer.Name              = "NotifContainer"
NotifContainer.Size              = UDim2.new(0, 260, 1, 0)
NotifContainer.Position          = UDim2.new(1, -270, 0, 0)
NotifContainer.BackgroundTransparency = 1
NotifContainer.BorderSizePixel   = 0
NotifContainer.ZIndex            = 100
NotifContainer.Parent            = Screen

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.Padding              = UDim.new(0, 8)
NotifLayout.SortOrder            = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment    = Enum.VerticalAlignment.Bottom
NotifLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Right
NotifLayout.Parent               = NotifContainer

local notifCount = 0

local typeColor = {
    info    = Color3.fromRGB(60,  130, 255),
    success = Color3.fromRGB(60,  200, 100),
    warn    = Color3.fromRGB(255, 180, 40),
    error   = Color3.fromRGB(220, 55,  55),
}

function Library:Notify(data)
    local title    = data.Title    or "Leon X"
    local text     = data.Text     or ""
    local ntype    = data.Type     or "info"
    local duration = data.Duration or 3

    notifCount = notifCount + 1
    local accentCol = typeColor[ntype] or typeColor.info

    -- card
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, 0, 0, 58)
    card.BackgroundColor3 = C.Surface
    card.BorderSizePixel  = 0
    card.BackgroundTransparency = 1   -- start invisible, tween in
    card.LayoutOrder      = notifCount
    card.ZIndex           = 100
    card.Parent           = NotifContainer
    rnd(card, 10)

    -- left accent bar
    local bar = mkF(card, accentCol)
    bar.Size     = UDim2.new(0, 3, 1, -16)
    bar.Position = UDim2.new(0, 8, 0, 8)
    bar.ZIndex   = 101
    rnd(bar, 2)

    -- title
    local tl = mkL(card, title, 12, C.Text, Enum.Font.GothamBold)
    tl.Size     = UDim2.new(1, -26, 0, 16)
    tl.Position = UDim2.new(0, 18, 0, 10)
    tl.ZIndex   = 101

    -- body
    local bl = mkL(card, text, 11, C.Dim, Enum.Font.Gotham)
    bl.Size           = UDim2.new(1, -26, 0, 24)
    bl.Position       = UDim2.new(0, 18, 0, 27)
    bl.ZIndex         = 101
    bl.TextWrapped    = true

    -- progress bar (shrinks over duration)
    local progBg = mkF(card, C.Elevated)
    progBg.Size     = UDim2.new(1, -16, 0, 2)
    progBg.Position = UDim2.new(0, 8, 1, -8)
    progBg.ZIndex   = 101
    rnd(progBg, 1)

    local prog = mkF(progBg, accentCol)
    prog.Size    = UDim2.new(1, 0, 1, 0)
    prog.ZIndex  = 102
    rnd(prog, 1)

    -- slide in + fade in
    card.Position = UDim2.new(1, 20, 0, 0)
    tw(card, 0.25, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })

    -- shrink progress bar
    TweenService:Create(prog,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 1, 0) }
    ):Play()

    -- fade out and destroy
    task.delay(duration, function()
        tw(card, 0.3, { BackgroundTransparency = 1 })
        task.wait(0.32)
        pcall(function() card:Destroy() end)
    end)
end

-- ── Splash / loading screen ───────────────────────────────────────────────────
do
    -- card parented directly to Screen — no fullscreen overlay, game stays visible
    local card = mkF(Screen, C.Surface)
    card.Name        = "SplashCard"
    card.Size        = UDim2.new(0, 240, 0, 136)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position    = UDim2.new(0.5, 0, 0.5, 0)
    card.ZIndex      = 200
    rnd(card, 14)
    strk(card, C.Border)

    -- logo dot
    local logoDot = mkF(card, C.Accent)
    logoDot.Size        = UDim2.new(0, 8, 0, 8)
    logoDot.Position    = UDim2.new(0, 20, 0, 26)
    logoDot.AnchorPoint = Vector2.new(0, 0.5)
    logoDot.ZIndex      = 201
    rnd(logoDot, 4)

    local titleSp = mkL(card, "Leon X", 17, C.Text, Enum.Font.GothamBold)
    titleSp.Size     = UDim2.new(1, -46, 0, 22)
    titleSp.Position = UDim2.new(0, 36, 0, 16)
    titleSp.ZIndex   = 201

    local verSp = mkL(card, "v1.0", 11, C.Sub, Enum.Font.Gotham)
    verSp.Size     = UDim2.new(0, 40, 0, 16)
    verSp.Position = UDim2.new(0, 36, 0, 38)
    verSp.ZIndex   = 201

    local statusL = mkL(card, "Initializing...", 11, C.Dim, Enum.Font.Gotham)
    statusL.Size     = UDim2.new(1, -24, 0, 16)
    statusL.Position = UDim2.new(0, 14, 0, 68)
    statusL.ZIndex   = 201

    local barBg = mkF(card, C.Elevated)
    barBg.Size     = UDim2.new(1, -28, 0, 3)
    barBg.Position = UDim2.new(0, 14, 1, -18)
    barBg.ZIndex   = 201
    rnd(barBg, 2)

    local barFill = mkF(barBg, C.Accent)
    barFill.Size   = UDim2.new(0, 0, 1, 0)
    barFill.ZIndex = 202
    rnd(barFill, 2)

    local dotsL = mkL(card, "●  ○  ○", 9, C.Sub, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
    dotsL.Size     = UDim2.new(1, 0, 0, 14)
    dotsL.Position = UDim2.new(0, 0, 0, 92)
    dotsL.ZIndex   = 201

    -- entrance: scale up + fade in
    card.BackgroundTransparency = 1
    card.Size = UDim2.new(0, 200, 0, 110)
    tw(card, 0.35, { BackgroundTransparency = 0, Size = UDim2.new(0, 240, 0, 136) })
    for _, child in ipairs(card:GetDescendants()) do
        if child:IsA("TextLabel") then
            child.TextTransparency = 1
            tw(child, 0.4, { TextTransparency = 0 })
        elseif child:IsA("Frame") then
            child.BackgroundTransparency = 1
            tw(child, 0.4, { BackgroundTransparency = 0 })
        end
    end

    -- animated dots + status text
    local dotFrames = { "●  ○  ○", "○  ●  ○", "○  ○  ●", "●  ○  ○" }
    local steps = {
        "Initializing...",
        "Loading UI engine...",
        "Fetching modules...",
        "Wiring features...",
        "Almost ready...",
    }
    local dotIdx  = 1
    local stepIdx = 1

    task.spawn(function()
        local lastDot  = tick()
        local lastStep = tick()
        while card and card.Parent do
            local now = tick()
            if now - lastDot >= 0.28 then
                lastDot = now
                dotIdx = (dotIdx % #dotFrames) + 1
                pcall(function() dotsL.Text = dotFrames[dotIdx] end)
            end
            if now - lastStep >= 0.85 then
                lastStep = now
                stepIdx = (stepIdx % #steps) + 1
                pcall(function() statusL.Text = steps[stepIdx] end)
            end
            task.wait(0.05)
        end
    end)

    Library._splashCard = card
    Library._splashBar  = barFill

    function Library:SetSplashProgress(pct)
        pcall(function()
            tw(self._splashBar, 0.2, { Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0) })
        end)
    end

    function Library:HideSplash()
        task.spawn(function()
            pcall(function()
                local c = self._splashCard
                if not c or not c.Parent then return end
                -- fill bar to 100%
                tw(self._splashBar, 0.2, { Size = UDim2.new(1, 0, 1, 0) })
                task.wait(0.25)
                -- reveal main window first, then fade out splash card together
                BtnX.Visible = true; BtnM.Visible = true; ResBtn.Visible = true
                Win.Visible = true; BG.Visible = true
                -- fade out card
                tw(c, 0.45, { BackgroundTransparency = 1 })
                for _, child in ipairs(c:GetDescendants()) do
                    pcall(function()
                        if child:IsA("TextLabel") then
                            tw(child, 0.35, { TextTransparency = 1 })
                        elseif child:IsA("Frame") then
                            tw(child, 0.35, { BackgroundTransparency = 1 })
                        end
                    end)
                end
                task.wait(0.5)
                pcall(function() c:Destroy() end)
                self._splashCard = nil
                self._splashBar  = nil
            end)
        end)
    end
end

return Library
