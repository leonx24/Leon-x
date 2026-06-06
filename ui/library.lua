-- Leon X UI Library v4.1
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
Screen.Parent = gui

-- border frame (same radius as Win, 1px larger each side = clean border)
local R = 12
local BG = mkF(Screen, C.Border)
BG.Size = UDim2.new(0,662,0,422)
BG.Position = UDim2.new(0.5,-331,0.5,-211)
rnd(BG, R)

local Win = mkF(Screen, C.BG)
Win.Name = "Win"
Win.Size = UDim2.new(0,660,0,420)
Win.Position = UDim2.new(0.5,-330,0.5,-210)
Win.ClipsDescendants = true
rnd(Win, R)

-- topbar
local Top = mkF(Win, C.BG)
Top.Size = UDim2.new(1,0,0,46)

local TopDiv = mkF(Top, C.Border)
TopDiv.Size = UDim2.new(1,0,0,1)
TopDiv.Position = UDim2.new(0,0,1,-1)

local Dot = mkF(Top, C.Accent)
Dot.Size = UDim2.new(0,7,0,7)
Dot.Position = UDim2.new(0,16,0.5,-3)
rnd(Dot, 4)

local TitleL = mkL(Top,"Leon X",15,C.Text,Enum.Font.GothamBold)
TitleL.Size = UDim2.new(0,80,1,0)
TitleL.Position = UDim2.new(0,30,0,0)

local VerL = mkL(Top,"v4.1",11,C.Sub,Enum.Font.Gotham)
VerL.Size = UDim2.new(0,40,1,0)
VerL.Position = UDim2.new(0,110,0,0)

-- window buttons on Screen (not inside Win, so not clipped)
local function mkWinBtn(icon, bg)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,26,0,26)
    b.BackgroundColor3 = bg
    b.Text = icon
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 5
    b.Parent = Screen
    rnd(b, 7)
    return b
end

local BtnX = mkWinBtn("×", C.Red)
local BtnM = mkWinBtn("−", C.Elevated)
hvr(BtnX, C.Red, C.RedH, Color3.fromRGB(215,55,55))
hvr(BtnM, C.Elevated, C.Hover, C.Press)

local function syncBtns()
    local p = Win.AbsolutePosition
    local s = Win.AbsoluteSize
    BtnX.Position = UDim2.new(0, p.X+s.X-42,    0, p.Y+10)
    BtnM.Position = UDim2.new(0, p.X+s.X-42-34, 0, p.Y+10)
end
Win:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncBtns)
Win:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncBtns)
task.defer(syncBtns)

-- sidebar
local Side = mkF(Win, C.Surface)
Side.Size = UDim2.new(0,152,1,-46)
Side.Position = UDim2.new(0,0,0,46)

local SideDiv = mkF(Side, C.Border)
SideDiv.Size = UDim2.new(0,1,1,0)
SideDiv.Position = UDim2.new(1,0,0,0)

local SideScroll = Instance.new("ScrollingFrame")
SideScroll.Size = UDim2.new(1,0,1,0)
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

-- content area
local Content = mkF(Win, C.BG)
Content.BackgroundTransparency = 1
Content.Size = UDim2.new(1,-153,1,-46)
Content.Position = UDim2.new(0,153,0,46)

local Pages = {}
Library._first = true
Library._currentTheme = "Dark"
Library.Registry = {}   -- Flag → component api, populated by Tab:Add* when Flag is set

-- internal helper: register a component api if data.Flag is provided
local function reg(data, api)
    if type(data.Flag) == "string" and data.Flag ~= "" then
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

-- resize button on Screen
local ResBtn = Instance.new("TextButton")
ResBtn.Size = UDim2.new(0,20,0,20)
ResBtn.BackgroundColor3 = C.Elevated
ResBtn.Text = "⤡"
ResBtn.TextColor3 = C.Dim
ResBtn.Font = Enum.Font.GothamBold
ResBtn.TextSize = 12
ResBtn.AutoButtonColor = false
ResBtn.BorderSizePixel = 0
ResBtn.ZIndex = 5
ResBtn.Parent = Screen
rnd(ResBtn, 5)

local function syncRes()
    local p = Win.AbsolutePosition
    local s = Win.AbsoluteSize
    ResBtn.Position = UDim2.new(0, p.X+s.X-24, 0, p.Y+s.Y-24)
end
Win:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncRes)
Win:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncRes)
task.defer(syncRes)

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
            local nw = math.clamp(ss.X.Offset+d.X, 480, 1400)
            local nh = math.clamp(ss.Y.Offset+d.Y, 300, 900)
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
Float.Size = UDim2.new(0,44,0,44)
Float.Position = UDim2.new(0,18,0.5,-22)
Float.BackgroundColor3 = C.Surface
Float.Text = "LX"
Float.TextColor3 = C.Text
Float.Font = Enum.Font.GothamBold
Float.TextSize = 13
Float.AutoButtonColor = false
Float.BorderSizePixel = 0
Float.Visible = false
Float.ZIndex = 5
Float.Parent = Screen
rnd(Float, 12)
strk(Float)
hvr(Float, C.Surface, C.Elevated, C.Press)

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
BtnX.MouseButton1Click:Connect(function() Screen:Destroy() end)

-- components

local function mkSection(parent, name)
    local w = mkF(parent, C.BG)
    w.BackgroundTransparency = 1
    w.Size = UDim2.new(1,0,0,22)
    local line = mkF(w, C.Border)
    line.Size = UDim2.new(1,0,0,1)
    line.Position = UDim2.new(0,0,0.5,0)
    local pill = mkF(w, C.BG)
    pill.AnchorPoint = Vector2.new(0.5,0.5)
    pill.Position = UDim2.new(0.5,0,0.5,0)
    pill.Size = UDim2.new(0,60,1,0)
    local t = mkL(pill, name, 10, C.Sub, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
    t.Size = UDim2.new(1,0,1,0)
    task.defer(function()
        if t.TextBounds.X > 0 then
            pill.Size = UDim2.new(0, t.TextBounds.X+16, 1, 0)
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
        on = v
        if on then
            tw(track,.18,{BackgroundColor3=C.OnTrack})
            tw(knob,.18,{Position=UDim2.new(1,-17,0.5,-7),BackgroundColor3=C.BG})
        else
            tw(track,.18,{BackgroundColor3=C.OffTrack})
            tw(knob,.18,{Position=UDim2.new(0,3,0.5,-7),BackgroundColor3=C.Dim})
        end
        if not silent then cb(on) end
    end
    row.MouseButton1Click:Connect(function() set(not on) end)
    local api = {Frame=row}
    function api:Set(v) set(v,true) end
    function api:Get() return on end
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

function Library:CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-12,0,36)
    btn.BackgroundColor3 = C.Surface
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = SideScroll
    rnd(btn, 9)
    local bar = mkF(btn, C.Accent)
    bar.Size = UDim2.new(0,3,0,18)
    bar.Position = UDim2.new(0,0,0.5,-9)
    bar.BackgroundTransparency = 1
    rnd(bar, 2)
    local bl = mkL(btn, name, 13, C.Sub, Enum.Font.GothamMedium)
    bl.Size = UDim2.new(1,-14,1,0)
    bl.Position = UDim2.new(0,14,0,0)
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
    Pages[name] = {page=page, btn=btn, bar=bar, lbl=bl}
    local function activate()
        for _,v in pairs(Pages) do
            v.page.Visible = false
            tw(v.btn,.15,{BackgroundColor3=C.Surface})
            tw(v.bar,.15,{BackgroundTransparency=1})
            tw(v.lbl,.15,{TextColor3=C.Sub})
        end
        page.Visible = true
        tw(btn,.15,{BackgroundColor3=C.Elevated})
        tw(bar,.15,{BackgroundTransparency=0})
        tw(bl,.15,{TextColor3=C.Text})
    end
    if Library._first then
        Library._first = false
        page.Visible = true
        btn.BackgroundColor3 = C.Elevated
        bar.BackgroundTransparency = 0
        bl.TextColor3 = C.Text
    end
    btn.MouseButton1Click:Connect(activate)
    hvr(btn, C.Surface, C.Hover, C.Press)
    local Tab = {}
    function Tab:AddSection(n)     return mkSection(page,n)           end
    function Tab:AddToggle(d)      return reg(d, mkToggle(page,d))    end
    function Tab:AddButton(d)      return mkButton(page,d)            end
    function Tab:AddSlider(d)      return reg(d, mkSlider(page,d))    end
    function Tab:AddDropdown(d)    return reg(d, mkDropdown(page,d))  end
    function Tab:AddKeybind(d)     return reg(d, mkKeybind(page,d))   end
    function Tab:AddLabel(d)       return mkLabel(page,d)             end
    function Tab:AddColorPicker(d) return mkColorPicker(page,d)       end
    function Tab:AddTextInput(d)   return mkTextInput(page,d)         end
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
    local Splash = Instance.new("Frame")
    Splash.Name                   = "Splash"
    Splash.Size                   = UDim2.new(1, 0, 1, 0)
    Splash.Position               = UDim2.new(0, 0, 0, 0)
    Splash.BackgroundColor3       = Color3.fromRGB(6, 6, 6)
    Splash.BackgroundTransparency = 0
    Splash.BorderSizePixel        = 0
    Splash.ZIndex                 = 200
    Splash.Parent                 = Screen

    -- centered card
    local card = mkF(Splash, C.Surface)
    card.Size        = UDim2.new(0, 240, 0, 136)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position    = UDim2.new(0.5, 0, 0.5, 0)
    card.ZIndex      = 201
    rnd(card, 14)
    strk(card, C.Border)

    -- logo dot
    local logoDot = mkF(card, C.Accent)
    logoDot.Size        = UDim2.new(0, 8, 0, 8)
    logoDot.Position    = UDim2.new(0, 20, 0, 26)
    logoDot.AnchorPoint = Vector2.new(0, 0.5)
    logoDot.ZIndex      = 202
    rnd(logoDot, 4)

    local titleSp = mkL(card, "Leon X", 17, C.Text, Enum.Font.GothamBold)
    titleSp.Size     = UDim2.new(1, -46, 0, 22)
    titleSp.Position = UDim2.new(0, 36, 0, 16)
    titleSp.ZIndex   = 202

    local verSp = mkL(card, "v5.0", 11, C.Sub, Enum.Font.Gotham)
    verSp.Size     = UDim2.new(0, 40, 0, 16)
    verSp.Position = UDim2.new(0, 36, 0, 38)
    verSp.ZIndex   = 202

    local statusL = mkL(card, "Initializing...", 11, C.Dim, Enum.Font.Gotham)
    statusL.Size     = UDim2.new(1, -24, 0, 16)
    statusL.Position = UDim2.new(0, 14, 0, 68)
    statusL.ZIndex   = 202

    local barBg = mkF(card, C.Elevated)
    barBg.Size     = UDim2.new(1, -28, 0, 3)
    barBg.Position = UDim2.new(0, 14, 1, -18)
    barBg.ZIndex   = 202
    rnd(barBg, 2)

    local barFill = mkF(barBg, C.Accent)
    barFill.Size   = UDim2.new(0, 0, 1, 0)
    barFill.ZIndex = 203
    rnd(barFill, 2)

    local dotsL = mkL(card, "●  ○  ○", 9, C.Sub, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
    dotsL.Size     = UDim2.new(1, 0, 0, 14)
    dotsL.Position = UDim2.new(0, 0, 0, 92)
    dotsL.ZIndex   = 202

    -- card entrance animation
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

    -- dot animation loop
    local dotFrames = { "●  ○  ○", "○  ●  ○", "○  ○  ●", "●  ○  ○" }
    local steps = {
        "Initializing...",
        "Loading UI engine...",
        "Fetching modules...",
        "Wiring features...",
        "Almost ready...",
    }
    local dotIdx   = 1
    local stepIdx  = 1

    task.spawn(function()
        local lastDot  = tick()
        local lastStep = tick()
        while Splash and Splash.Parent do
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

    Library._splash    = Splash
    Library._splashBar = barFill

    function Library:SetSplashProgress(pct)
        pcall(function()
            tw(self._splashBar, 0.2, { Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0) })
        end)
    end

    function Library:HideSplash()
        task.spawn(function()
            pcall(function()
                local sp = self._splash
                if not sp or not sp.Parent then return end
                tw(self._splashBar, 0.2, { Size = UDim2.new(1, 0, 1, 0) })
                task.wait(0.25)
                tw(sp, 0.5, { BackgroundTransparency = 1 })
                for _, child in ipairs(sp:GetDescendants()) do
                    pcall(function()
                        if child:IsA("TextLabel") then
                            tw(child, 0.35, { TextTransparency = 1 })
                        elseif child:IsA("Frame") then
                            tw(child, 0.35, { BackgroundTransparency = 1 })
                        end
                    end)
                end
                task.wait(0.55)
                pcall(function() sp:Destroy() end)
                self._splash    = nil
                self._splashBar = nil
            end)
        end)
    end
end

return Library
