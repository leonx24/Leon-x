-- Leon X UI Library v3.0
-- Clean rewrite — simple hierarchy, no ZIndex hacks

local Library = {}

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local lp  = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")

local C = {
    BG        = Color3.fromRGB(12,  12,  12),
    Surface   = Color3.fromRGB(18,  18,  18),
    Elevated  = Color3.fromRGB(24,  24,  24),
    Border    = Color3.fromRGB(38,  38,  38),
    Accent    = Color3.fromRGB(255, 255, 255),
    AccentDim = Color3.fromRGB(140, 140, 140),
    Text      = Color3.fromRGB(230, 230, 230),
    TextSub   = Color3.fromRGB(100, 100, 100),
    SwitchOff = Color3.fromRGB(45,  45,  45),
    SwitchOn  = Color3.fromRGB(200, 200, 200),
    Hover     = Color3.fromRGB(30,  30,  30),
    Active    = Color3.fromRGB(40,  40,  40),
    Red       = Color3.fromRGB(180, 45,  45),
    RedHov    = Color3.fromRGB(210, 60,  60),
}

local function tw(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p):Play()
end
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p end
local function pad(p, t, l, r, b)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0,t or 0); u.PaddingLeft = UDim.new(0,l or 0)
    u.PaddingRight = UDim.new(0,r or 0); u.PaddingBottom = UDim.new(0,b or 0)
    u.Parent = p
end
local function lbl(parent, text, size, color, font, xalign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.BorderSizePixel = 0
    l.Text = text; l.TextSize = size or 13
    l.TextColor3 = color or C.Text
    l.Font = font or Enum.Font.GothamMedium
    l.TextXAlignment = xalign or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end
local function hvr(b, n, h, a)
    b.MouseEnter:Connect(function() tw(b,0.12,{BackgroundColor3=h}) end)
    b.MouseLeave:Connect(function() tw(b,0.15,{BackgroundColor3=n}) end)
    b.MouseButton1Down:Connect(function() tw(b,0.06,{BackgroundColor3=a}) end)
    b.MouseButton1Up:Connect(function() tw(b,0.1,{BackgroundColor3=h}) end)
end

-- destroy old
pcall(function() gui:FindFirstChild("LeonX"):Destroy() end)

local Screen = Instance.new("ScreenGui")
Screen.Name = "LeonX"; Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder = 999; Screen.Parent = gui

-- ── Window ────────────────────────────────────────────────────────────────────
-- Outer border frame (1px larger on each side)
local Border = Instance.new("Frame")
Border.Size = UDim2.new(0,662,0,422); Border.Position = UDim2.new(0.5,-331,0.5,-211)
Border.BackgroundColor3 = C.Border; Border.BorderSizePixel = 0; Border.Parent = Screen
corner(Border, 15)

local Win = Instance.new("Frame")
Win.Name = "Win"; Win.Size = UDim2.new(0,660,0,420)
Win.Position = UDim2.new(0.5,-330,0.5,-210)
Win.BackgroundColor3 = C.BG; Win.BorderSizePixel = 0
Win.ClipsDescendants = true          -- clips sidebar corners cleanly
Win.Parent = Screen
corner(Win, 14)

-- ── Topbar ────────────────────────────────────────────────────────────────────
local Top = Instance.new("Frame")
Top.Size = UDim2.new(1,0,0,46); Top.BackgroundColor3 = C.BG
Top.BorderSizePixel = 0; Top.Parent = Win

-- divider under topbar
local Div = Instance.new("Frame")
Div.Size = UDim2.new(1,0,0,1); Div.Position = UDim2.new(0,0,1,-1)
Div.BackgroundColor3 = C.Border; Div.BorderSizePixel = 0; Div.Parent = Top

-- dot + title
local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0,7,0,7); Dot.Position = UDim2.new(0,16,0.5,-3)
Dot.BackgroundColor3 = C.Accent; Dot.BorderSizePixel = 0; Dot.Parent = Top
corner(Dot, 4)

local Title = lbl(Top,"Leon X",15,C.Text,Enum.Font.GothamBold)
Title.Size = UDim2.new(0,80,1,0); Title.Position = UDim2.new(0,30,0,0)

local Ver = lbl(Top,"v3.0",11,C.TextSub,Enum.Font.Gotham)
Ver.Size = UDim2.new(0,40,1,0); Ver.Position = UDim2.new(0,110,0,0)

-- ── Controls (on Screen so not clipped) ──────────────────────────────────────
local function mkBtn(icon, bg, zi)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,28,0,28); b.BackgroundColor3 = bg
    b.Text = icon; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 16
    b.AutoButtonColor = false; b.BorderSizePixel = 0
    b.ZIndex = zi or 10; b.Parent = Screen
    corner(b, 8)
    return b
end

local BtnX = mkBtn("×", C.Red, 10)
local BtnM = mkBtn("−", C.Elevated, 10)
hvr(BtnX, C.Red, C.RedHov, Color3.fromRGB(220,55,55))
hvr(BtnM, C.Elevated, C.Hover, C.Active)

local function posCtrl()
    local p = Win.AbsolutePosition; local s = Win.AbsoluteSize
    BtnX.Position = UDim2.new(0, p.X+s.X-14-28,   0, p.Y+9)
    BtnM.Position = UDim2.new(0, p.X+s.X-14-28-36, 0, p.Y+9)
end
Win:GetPropertyChangedSignal("AbsolutePosition"):Connect(posCtrl)
Win:GetPropertyChangedSignal("AbsoluteSize"):Connect(posCtrl)
task.defer(posCtrl)

-- ── Sidebar ───────────────────────────────────────────────────────────────────
local Side = Instance.new("Frame")
Side.Size = UDim2.new(0,155,1,-46); Side.Position = UDim2.new(0,0,0,46)
Side.BackgroundColor3 = C.Surface; Side.BorderSizePixel = 0; Side.Parent = Win

local SideDiv = Instance.new("Frame")
SideDiv.Size = UDim2.new(0,1,1,0); SideDiv.Position = UDim2.new(1,0,0,0)
SideDiv.BackgroundColor3 = C.Border; SideDiv.BorderSizePixel = 0; SideDiv.Parent = Side

local SideList = Instance.new("Frame")
SideList.Size = UDim2.new(1,0,1,0); SideList.BackgroundTransparency = 1
SideList.BorderSizePixel = 0; SideList.Parent = Side
pad(SideList, 10, 0, 0, 10)

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0,4)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = SideList

-- ── Content ───────────────────────────────────────────────────────────────────
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-156,1,-46); Content.Position = UDim2.new(0,156,0,46)
Content.BackgroundTransparency = 1; Content.BorderSizePixel = 0; Content.Parent = Win

local Pages = {}
Library._first = true

-- ── Drag ──────────────────────────────────────────────────────────────────────
do
    local on,ds,sp = false,nil,nil
    Top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            on=true; ds=i.Position; sp=Win.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if on and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position-ds
            local nx,ny = sp.X.Offset+d.X, sp.Y.Offset+d.Y
            Win.Position    = UDim2.new(sp.X.Scale,nx,sp.Y.Scale,ny)
            Border.Position = UDim2.new(sp.X.Scale,nx-1,sp.Y.Scale,ny-1)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then on=false end
    end)
end

-- ── Resize ────────────────────────────────────────────────────────────────────
local ResBtn = Instance.new("TextButton")
ResBtn.Size = UDim2.new(0,22,0,22); ResBtn.BackgroundColor3 = C.Elevated
ResBtn.Text = "⤡"; ResBtn.TextColor3 = C.AccentDim
ResBtn.Font = Enum.Font.GothamBold; ResBtn.TextSize = 13
ResBtn.AutoButtonColor = false; ResBtn.BorderSizePixel = 0
ResBtn.ZIndex = 10; ResBtn.Parent = Screen
corner(ResBtn, 6)

local function posRes()
    local p = Win.AbsolutePosition; local s = Win.AbsoluteSize
    ResBtn.Position = UDim2.new(0, p.X+s.X-26, 0, p.Y+s.Y-26)
end
Win:GetPropertyChangedSignal("AbsolutePosition"):Connect(posRes)
Win:GetPropertyChangedSignal("AbsoluteSize"):Connect(posRes)
task.defer(posRes)

do
    local on,rs,ss = false,nil,nil
    ResBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then on=true; rs=i.Position; ss=Win.Size end
    end)
    UIS.InputChanged:Connect(function(i)
        if on and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position-rs
            local nw = math.clamp(ss.X.Offset+d.X,520,1200)
            local nh = math.clamp(ss.Y.Offset+d.Y,320,800)
            Win.Size    = UDim2.new(0,nw,0,nh)
            Border.Size = UDim2.new(0,nw+2,0,nh+2)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then on=false end
    end)
end

-- ── Float ─────────────────────────────────────────────────────────────────────
local Float = Instance.new("TextButton")
Float.Size = UDim2.new(0,46,0,46); Float.Position = UDim2.new(0,20,0.5,-23)
Float.BackgroundColor3 = C.Surface; Float.Text = "LX"
Float.TextColor3 = C.Text; Float.Font = Enum.Font.GothamBold; Float.TextSize = 14
Float.AutoButtonColor = false; Float.BorderSizePixel = 0
Float.Visible = false; Float.ZIndex = 10; Float.Parent = Screen
corner(Float, 13)
local fs = Instance.new("UIStroke"); fs.Color = C.Border; fs.Parent = Float
hvr(Float, C.Surface, C.Elevated, C.Active)

do
    local on,ds,fp,mv = false,nil,nil,false
    Float.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            on=true; mv=false; ds=i.Position; fp=Float.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if on and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position-ds
            if math.abs(d.X)>4 or math.abs(d.Y)>4 then mv=true end
            Float.Position = UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and on then
            on=false
            if not mv then
                Win.Visible=true; Border.Visible=true
                Float.Visible=false; BtnX.Visible=true; BtnM.Visible=true; ResBtn.Visible=true
            end
            task.wait(); mv=false
        end
    end)
end

BtnM.MouseButton1Click:Connect(function()
    Win.Visible=false; Border.Visible=false
    Float.Visible=true; BtnX.Visible=false; BtnM.Visible=false; ResBtn.Visible=false
end)
BtnX.MouseButton1Click:Connect(function() Screen:Destroy() end)

-- ══════════════════════════════════════════════════════════════════════════════
-- COMPONENTS
-- ══════════════════════════════════════════════════════════════════════════════

local function mkSection(parent, name)
    local w = Instance.new("Frame")
    w.Size = UDim2.new(1,0,0,24); w.BackgroundTransparency=1; w.BorderSizePixel=0; w.Parent=parent
    local line = Instance.new("Frame")
    line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,0.5,0)
    line.BackgroundColor3=C.Border; line.BorderSizePixel=0; line.Parent=w
    local pill = Instance.new("Frame")
    pill.AnchorPoint=Vector2.new(0.5,0.5); pill.Position=UDim2.new(0.5,0,0.5,0)
    pill.Size=UDim2.new(0,80,1,0); pill.BackgroundColor3=C.BG; pill.BorderSizePixel=0; pill.Parent=w
    local t = lbl(pill,name,11,C.TextSub,Enum.Font.GothamMedium,Enum.TextXAlignment.Center)
    t.Size=UDim2.new(1,-10,1,0); t.Position=UDim2.new(0,5,0,0)
    task.defer(function() pill.Size=UDim2.new(0,t.TextBounds.X+14,1,0) end)
    return w
end

local function mkToggle(parent, data)
    local cb = data.Callback or function()end
    local on = data.Default or false
    local row = Instance.new("TextButton")
    row.Size=UDim2.new(1,0,0,42); row.BackgroundColor3=C.Elevated
    row.Text=""; row.AutoButtonColor=false; row.BorderSizePixel=0; row.Parent=parent
    corner(row,10)
    local sk = Instance.new("UIStroke"); sk.Color=C.Border; sk.Parent=row
    local name = lbl(row, data.Name or "Toggle", 13, C.Text, Enum.Font.GothamMedium)
    name.Size=UDim2.new(1,-68,1,0); name.Position=UDim2.new(0,14,0,0)
    local track = Instance.new("Frame")
    track.Size=UDim2.new(0,38,0,20); track.Position=UDim2.new(1,-52,0.5,-10)
    track.BackgroundColor3=on and C.SwitchOn or C.SwitchOff; track.BorderSizePixel=0; track.Parent=row
    corner(track,10)
    local knob = Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14)
    knob.Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3=on and C.BG or C.AccentDim; knob.BorderSizePixel=0; knob.Parent=track
    corner(knob,7)
    hvr(row,C.Elevated,C.Hover,C.Active)
    local function set(v,s)
        on=v
        if on then tw(track,.18,{BackgroundColor3=C.SwitchOn}); tw(knob,.18,{Position=UDim2.new(1,-17,0.5,-7),BackgroundColor3=C.BG})
        else tw(track,.18,{BackgroundColor3=C.SwitchOff}); tw(knob,.18,{Position=UDim2.new(0,3,0.5,-7),BackgroundColor3=C.AccentDim}) end
        if not s then cb(on) end
    end
    row.MouseButton1Click:Connect(function() set(not on) end)
    local api={Frame=row}; function api:Set(v) set(v,true) end; function api:Get() return on end; return api
end

local function mkButton(parent, data)
    local cb = data.Callback or function()end
    local b = Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,38); b.BackgroundColor3=C.Elevated
    b.Text=data.Name or "Button"; b.TextColor3=C.Text
    b.Font=Enum.Font.GothamMedium; b.TextSize=13
    b.AutoButtonColor=false; b.BorderSizePixel=0; b.Parent=parent
    corner(b,10)
    local sk=Instance.new("UIStroke"); sk.Color=C.Border; sk.Parent=b
    hvr(b,C.Elevated,C.Hover,C.Active)
    b.MouseButton1Click:Connect(function()
        tw(b,.06,{BackgroundColor3=Color3.fromRGB(50,50,50)})
        task.delay(.12,function() tw(b,.15,{BackgroundColor3=C.Elevated}) end)
        cb()
    end)
    local api={Frame=b}; function api:SetText(t) b.Text=t end; return api
end

local function mkSlider(parent, data)
    local cb=data.Callback or function()end
    local mn=data.Min or 0; local mx=data.Max or 100
    local sf=data.Suffix or ""; local cur=math.clamp(data.Default or mn,mn,mx)
    local w=Instance.new("Frame")
    w.Size=UDim2.new(1,0,0,54); w.BackgroundColor3=C.Elevated; w.BorderSizePixel=0; w.Parent=parent
    corner(w,10); local sk=Instance.new("UIStroke"); sk.Color=C.Border; sk.Parent=w
    local nl=lbl(w,data.Name or "Slider",13,C.Text,Enum.Font.GothamMedium)
    nl.Size=UDim2.new(1,-80,0,22); nl.Position=UDim2.new(0,14,0,8)
    local vl=lbl(w,tostring(cur)..sf,12,C.AccentDim,Enum.Font.GothamMedium,Enum.TextXAlignment.Right)
    vl.Size=UDim2.new(0,70,0,22); vl.Position=UDim2.new(1,-80,0,8)
    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(1,-28,0,4); bg.Position=UDim2.new(0,14,1,-16)
    bg.BackgroundColor3=C.SwitchOff; bg.BorderSizePixel=0; bg.Parent=w; corner(bg,2)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((cur-mn)/(mx-mn),0,1,0); fill.BackgroundColor3=C.Accent
    fill.BorderSizePixel=0; fill.Parent=bg; corner(fill,2)
    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,12,0,12); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((cur-mn)/(mx-mn),0,0.5,0); knob.BackgroundColor3=C.Accent
    knob.BorderSizePixel=0; knob.ZIndex=3; knob.Parent=bg; corner(knob,6)
    local function upd(pct)
        pct=math.clamp(pct,0,1); cur=math.floor(mn+(mx-mn)*pct+.5)
        tw(fill,.05,{Size=UDim2.new(pct,0,1,0)}); tw(knob,.05,{Position=UDim2.new(pct,0,0.5,0)})
        vl.Text=tostring(cur)..sf; cb(cur)
    end
    local sl=false
    bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sl=true; upd((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X) end end)
    UIS.InputChanged:Connect(function(i) if sl and i.UserInputType==Enum.UserInputType.MouseMovement then upd((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sl=false end end)
    local api={Frame=w}; function api:Set(v) upd((math.clamp(v,mn,mx)-mn)/(mx-mn)) end; function api:Get() return cur end; return api
end

local function mkDropdown(parent, data)
    local cb=data.Callback or function()end
    local opts=data.Options or {}; local cur=data.Default or (opts[1] or "Select"); local open=false
    local w=Instance.new("Frame")
    w.Size=UDim2.new(1,0,0,42); w.BackgroundColor3=C.Elevated; w.BorderSizePixel=0; w.Parent=parent
    corner(w,10); local sk=Instance.new("UIStroke"); sk.Color=C.Border; sk.Parent=w
    local hdr=Instance.new("TextButton")
    hdr.Size=UDim2.new(1,0,1,0); hdr.BackgroundTransparency=1; hdr.Text=""; hdr.AutoButtonColor=false; hdr.BorderSizePixel=0; hdr.Parent=w
    local nl=lbl(hdr,data.Name or "Dropdown",13,C.Text,Enum.Font.GothamMedium); nl.Size=UDim2.new(1,-110,1,0); nl.Position=UDim2.new(0,14,0,0)
    local vl=lbl(hdr,cur,12,C.AccentDim,Enum.Font.Gotham,Enum.TextXAlignment.Right); vl.Size=UDim2.new(0,90,1,0); vl.Position=UDim2.new(1,-106,0,0)
    local ar=lbl(hdr,"›",16,C.TextSub,Enum.Font.GothamBold,Enum.TextXAlignment.Center); ar.Size=UDim2.new(0,18,1,0); ar.Position=UDim2.new(1,-22,0,0)
    local lh=math.min(#opts*34+8,170)
    local List=Instance.new("Frame")
    List.BackgroundColor3=C.Surface; List.BorderSizePixel=0; List.ZIndex=50
    List.Visible=false; List.ClipsDescendants=true; List.Size=UDim2.new(0,10,0,0); List.Parent=Screen
    corner(List,10); local lsk=Instance.new("UIStroke"); lsk.Color=C.Border; lsk.Parent=List
    local ll=Instance.new("UIListLayout"); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Parent=List
    pad(List,4,0,0,4)
    for _,opt in ipairs(opts) do
        local it=Instance.new("TextButton")
        it.Size=UDim2.new(1,0,0,34); it.BackgroundColor3=C.Surface; it.Text=""; it.AutoButtonColor=false; it.BorderSizePixel=0; it.ZIndex=51; it.Parent=List
        local il=lbl(it,opt,12,C.Text,Enum.Font.Gotham); il.Size=UDim2.new(1,-20,1,0); il.Position=UDim2.new(0,12,0,0); il.ZIndex=51
        hvr(it,C.Surface,C.Elevated,C.Active)
        it.MouseButton1Click:Connect(function()
            cur=opt; vl.Text=opt; open=false
            tw(ar,.15,{Rotation=0}); tw(List,.15,{Size=UDim2.new(0,List.Size.X.Offset,0,0)})
            task.delay(.16,function() List.Visible=false end); cb(opt)
        end)
    end
    local function closeDD() open=false; tw(ar,.15,{Rotation=0}); tw(List,.15,{Size=UDim2.new(0,List.Size.X.Offset,0,0)}); task.delay(.16,function() List.Visible=false end) end
    local function openDD()
        open=true; local ap=w.AbsolutePosition; local as=w.AbsoluteSize
        List.Position=UDim2.new(0,ap.X,0,ap.Y+as.Y+4); List.Size=UDim2.new(0,as.X,0,0); List.Visible=true
        tw(ar,.15,{Rotation=90}); tw(List,.18,{Size=UDim2.new(0,as.X,0,lh)})
    end
    hdr.MouseButton1Click:Connect(function() if open then closeDD() else openDD() end end)
    UIS.InputBegan:Connect(function(i)
        if not open or i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        local mp=i.Position
        local function out(f) local p=f.AbsolutePosition; local s=f.AbsoluteSize; return mp.X<p.X or mp.X>p.X+s.X or mp.Y<p.Y or mp.Y>p.Y+s.Y end
        if out(List) and out(w) then closeDD() end
    end)
    local api={Frame=w}; function api:Set(v) cur=v; vl.Text=v end; function api:Get() return cur end; return api
end

local function mkKeybind(parent, data)
    local cb=data.Callback or function()end; local cur=data.Default or Enum.KeyCode.Unknown; local waiting=false
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,42); row.BackgroundColor3=C.Elevated; row.BorderSizePixel=0; row.Parent=parent
    corner(row,10); local sk=Instance.new("UIStroke"); sk.Color=C.Border; sk.Parent=row
    local nl=lbl(row,data.Name or "Keybind",13,C.Text,Enum.Font.GothamMedium); nl.Size=UDim2.new(1,-110,1,0); nl.Position=UDim2.new(0,14,0,0)
    local kb=Instance.new("TextButton")
    kb.Size=UDim2.new(0,80,0,26); kb.Position=UDim2.new(1,-90,0.5,-13); kb.BackgroundColor3=C.Surface
    kb.Text=cur==Enum.KeyCode.Unknown and "None" or cur.Name; kb.TextColor3=C.AccentDim
    kb.Font=Enum.Font.GothamMedium; kb.TextSize=11; kb.AutoButtonColor=false; kb.BorderSizePixel=0; kb.Parent=row
    corner(kb,7); local ksk=Instance.new("UIStroke"); ksk.Color=C.Border; ksk.Parent=kb
    hvr(kb,C.Surface,C.Elevated,C.Active)
    kb.MouseButton1Click:Connect(function() if waiting then return end; waiting=true; kb.Text="..."; kb.TextColor3=C.Text end)
    UIS.InputBegan:Connect(function(i,gp)
        if not waiting or gp then return end
        if i.UserInputType==Enum.UserInputType.Keyboard then cur=i.KeyCode; waiting=false; kb.Text=i.KeyCode.Name; kb.TextColor3=C.AccentDim; cb(cur) end
    end)
    local api={Frame=row}; function api:Get() return cur end; return api
end

local function mkLabel(parent, data)
    local l=lbl(parent,data.Text or "",12,data.Color or C.TextSub,Enum.Font.Gotham,data.Align or Enum.TextXAlignment.Left)
    l.Size=UDim2.new(1,0,0,26); l.BorderSizePixel=0
    local api={Frame=l}; function api:Set(t) l.Text=t end; return api
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CreateTab
-- ══════════════════════════════════════════════════════════════════════════════
function Library:CreateTab(name)
    -- sidebar button
    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(1,-14,0,36); btn.BackgroundColor3=C.Surface
    btn.Text=""; btn.AutoButtonColor=false; btn.BorderSizePixel=0; btn.Parent=SideList
    corner(btn,9)

    local bar = Instance.new("Frame")
    bar.Size=UDim2.new(0,3,0,18); bar.Position=UDim2.new(0,0,0.5,-9)
    bar.BackgroundColor3=C.Accent; bar.BackgroundTransparency=1; bar.BorderSizePixel=0; bar.Parent=btn
    corner(bar,2)

    local bl = lbl(btn,name,13,C.TextSub,Enum.Font.GothamMedium)
    bl.Size=UDim2.new(1,-14,1,0); bl.Position=UDim2.new(0,14,0,0)

    -- page
    local page = Instance.new("ScrollingFrame")
    page.Size=UDim2.new(1,0,1,0); page.CanvasSize=UDim2.new(0,0,0,0)
    page.ScrollBarThickness=2; page.ScrollBarImageColor3=C.Border
    page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.Visible=false; page.Parent=Content

    local pl = Instance.new("UIListLayout")
    pl.Padding=UDim.new(0,8); pl.SortOrder=Enum.SortOrder.LayoutOrder; pl.Parent=page
    pad(page,14,14,14,14)

    pl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,pl.AbsoluteContentSize.Y+28)
    end)

    Pages[name] = {page=page,btn=btn,bar=bar,lbl=bl}

    local function activate()
        for _,v in pairs(Pages) do
            v.page.Visible=false
            tw(v.btn,.15,{BackgroundColor3=C.Surface})
            tw(v.bar,.15,{BackgroundTransparency=1})
            tw(v.lbl,.15,{TextColor3=C.TextSub})
        end
        page.Visible=true
        tw(btn,.15,{BackgroundColor3=C.Elevated})
        tw(bar,.15,{BackgroundTransparency=0})
        tw(bl,.15,{TextColor3=C.Text})
    end

    -- first tab: show immediately, no tween needed
    if Library._first then
        Library._first = false
        page.Visible = true
        btn.BackgroundColor3 = C.Elevated
        bar.BackgroundTransparency = 0
        bl.TextColor3 = C.Text
    end

    btn.MouseButton1Click:Connect(activate)
    hvr(btn, C.Surface, C.Hover, C.Active)

    local Tab = {}
    function Tab:AddSection(n)  return mkSection(page,n)   end
    function Tab:AddToggle(d)   return mkToggle(page,d)    end
    function Tab:AddButton(d)   return mkButton(page,d)    end
    function Tab:AddSlider(d)   return mkSlider(page,d)    end
    function Tab:AddDropdown(d) return mkDropdown(page,d)  end
    function Tab:AddKeybind(d)  return mkKeybind(page,d)   end
    function Tab:AddLabel(d)    return mkLabel(page,d)     end
    return Tab
end

return Library
