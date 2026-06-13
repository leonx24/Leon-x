-- Leon X | main.lua
-- Wind UI version with splash screen + mobile float logo

local BASE = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"

local CURRENT_VERSION = "1.3"
pcall(function()
    CURRENT_VERSION = game:HttpGet(BASE.."version.txt?t="..os.time()):match("^%s*(.-)%s*$")
end)

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lp           = Players.LocalPlayer
local gui          = lp:WaitForChild("PlayerGui")
local isMobile     = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ══════════════════════════════════════════════════════════════════════════════
-- SPLASH SCREEN (shown before WindUI loads)
-- ══════════════════════════════════════════════════════════════════════════════
local SplashGui = Instance.new("ScreenGui")
SplashGui.Name             = "LeonXSplash"
SplashGui.ResetOnSpawn     = false
SplashGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
SplashGui.DisplayOrder     = 9999
SplashGui.IgnoreGuiInset   = true
SplashGui.Parent           = gui

local SplashBg = Instance.new("Frame")
SplashBg.Size                = UDim2.fromScale(1, 1)
SplashBg.BackgroundColor3    = Color3.fromRGB(6, 6, 6)
SplashBg.BackgroundTransparency = 0.15
SplashBg.BorderSizePixel     = 0
SplashBg.ZIndex              = 200
SplashBg.Parent              = SplashGui

local SplashCard = Instance.new("Frame")
SplashCard.Size                = UDim2.new(0, 260, 0, 160)
SplashCard.AnchorPoint         = Vector2.new(0.5, 0.5)
SplashCard.Position            = UDim2.fromScale(0.5, 0.5)
SplashCard.BackgroundColor3    = Color3.fromRGB(14, 14, 14)
SplashCard.BorderSizePixel     = 0
SplashCard.ZIndex              = 201
SplashCard.Parent              = SplashGui

local SplashCorner = Instance.new("UICorner")
SplashCorner.CornerRadius = UDim.new(0, 16)
SplashCorner.Parent       = SplashCard

local SplashStroke = Instance.new("UIStroke")
SplashStroke.Color     = Color3.fromRGB(36, 36, 36)
SplashStroke.Thickness = 1
SplashStroke.Parent    = SplashCard

-- Animated accent glow on card border
task.spawn(function()
    while SplashCard and SplashCard.Parent do
        TweenService:Create(SplashStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine),
            {Color = Color3.fromRGB(80, 160, 255)}):Play()
        task.wait(1.5)
        TweenService:Create(SplashStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine),
            {Color = Color3.fromRGB(36, 36, 36)}):Play()
        task.wait(1.5)
    end
end)

-- Logo dot
local SplashDot = Instance.new("Frame")
SplashDot.Size             = UDim2.new(0, 10, 0, 10)
SplashDot.Position         = UDim2.new(0, 22, 0, 30)
SplashDot.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
SplashDot.BorderSizePixel  = 0
SplashDot.ZIndex           = 202
SplashDot.Parent           = SplashCard

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(0, 5)
DotCorner.Parent       = SplashDot

-- Pulsing dot animation
task.spawn(function()
    while SplashDot and SplashDot.Parent do
        TweenService:Create(SplashDot, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 13, 0, 13)}):Play()
        task.wait(0.6)
        TweenService:Create(SplashDot, TweenInfo.new(0.6, Enum.EasingStyle.Quint),
            {Size = UDim2.new(0, 10, 0, 10)}):Play()
        task.wait(0.6)
    end
end)

-- Title
local SplashTitle = Instance.new("TextLabel")
SplashTitle.Size                = UDim2.new(1, -50, 0, 26)
SplashTitle.Position            = UDim2.new(0, 40, 0, 20)
SplashTitle.BackgroundTransparency = 1
SplashTitle.Text                = "Leon X"
SplashTitle.TextColor3          = Color3.fromRGB(240, 240, 240)
SplashTitle.TextSize            = 20
SplashTitle.Font                = Enum.Font.GothamBold
SplashTitle.TextXAlignment      = Enum.TextXAlignment.Left
SplashTitle.ZIndex              = 202
SplashTitle.Parent              = SplashCard

-- Version
local SplashVer = Instance.new("TextLabel")
SplashVer.Size                = UDim2.new(0, 50, 0, 18)
SplashVer.Position            = UDim2.new(0, 40, 0, 46)
SplashVer.BackgroundTransparency = 1
SplashVer.Text                = "v" .. CURRENT_VERSION
SplashVer.TextColor3          = Color3.fromRGB(90, 90, 90)
SplashVer.TextSize            = 11
SplashVer.Font                = Enum.Font.Gotham
SplashVer.TextXAlignment      = Enum.TextXAlignment.Left
SplashVer.ZIndex              = 202
SplashVer.Parent              = SplashCard

-- Status text
local SplashStatus = Instance.new("TextLabel")
SplashStatus.Size                = UDim2.new(1, -28, 0, 18)
SplashStatus.Position            = UDim2.new(0, 14, 0, 80)
SplashStatus.BackgroundTransparency = 1
SplashStatus.Text                = "Initializing..."
SplashStatus.TextColor3          = Color3.fromRGB(110, 110, 110)
SplashStatus.TextSize            = 11
SplashStatus.Font                = Enum.Font.Gotham
SplashStatus.TextXAlignment      = Enum.TextXAlignment.Left
SplashStatus.ZIndex              = 202
SplashStatus.Parent              = SplashCard

-- Progress bar background
local SplashBarBg = Instance.new("Frame")
SplashBarBg.Size             = UDim2.new(1, -28, 0, 4)
SplashBarBg.Position         = UDim2.new(0, 14, 1, -28)
SplashBarBg.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
SplashBarBg.BorderSizePixel  = 0
SplashBarBg.ZIndex           = 202
SplashBarBg.Parent           = SplashCard

local BarBgCorner = Instance.new("UICorner")
BarBgCorner.CornerRadius = UDim.new(0, 2)
BarBgCorner.Parent       = SplashBarBg

-- Progress bar fill
local SplashBarFill = Instance.new("Frame")
SplashBarFill.Size             = UDim2.new(0, 0, 1, 0)
SplashBarFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
SplashBarFill.BorderSizePixel  = 0
SplashBarFill.ZIndex           = 203
SplashBarFill.Parent           = SplashBarBg

local BarFillCorner = Instance.new("UICorner")
BarFillCorner.CornerRadius = UDim.new(0, 2)
BarFillCorner.Parent       = SplashBarFill

-- Animated dots
local SplashDots = Instance.new("TextLabel")
SplashDots.Size                = UDim2.new(1, 0, 0, 16)
SplashDots.Position            = UDim2.new(0, 0, 0, 106)
SplashDots.BackgroundTransparency = 1
SplashDots.Text                = "●  ○  ○"
SplashDots.TextColor3          = Color3.fromRGB(80, 160, 255)
SplashDots.TextSize            = 10
SplashDots.Font                = Enum.Font.GothamMedium
SplashDots.TextXAlignment      = Enum.TextXAlignment.Center
SplashDots.ZIndex              = 202
SplashDots.Parent              = SplashCard

-- Splash entrance animation
SplashCard.BackgroundTransparency = 1
SplashCard.Size = UDim2.new(0, 210, 0, 130)
local function tw(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p):Play()
end
tw(SplashCard, 0.4, {BackgroundTransparency = 0, Size = UDim2.new(0, 260, 0, 160)})
tw(SplashBg, 0.3, {BackgroundTransparency = 0.15})

for _, child in ipairs(SplashCard:GetDescendants()) do
    if child:IsA("TextLabel") then
        child.TextTransparency = 1
        TweenService:Create(child, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    elseif child:IsA("Frame") then
        child.BackgroundTransparency = 1
        TweenService:Create(child, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    end
end

-- Animated dots cycle
local dotFrames = {"●  ○  ○", "○  ●  ○", "○  ○  ●"}
local statusSteps = {
    "Initializing...",
    "Loading UI engine...",
    "Fetching modules...",
    "Wiring features...",
    "Almost ready...",
}
local dotIdx, stepIdx = 1, 1

task.spawn(function()
    local lastDot, lastStep = tick(), tick()
    while SplashCard and SplashCard.Parent do
        local now = tick()
        if now - lastDot >= 0.3 then
            lastDot = now
            dotIdx = (dotIdx % #dotFrames) + 1
            pcall(function() SplashDots.Text = dotFrames[dotIdx] end)
        end
        if now - lastStep >= 0.9 then
            lastStep = now
            stepIdx = (stepIdx % #statusSteps) + 1
            pcall(function() SplashStatus.Text = statusSteps[stepIdx] end)
        end
        task.wait(0.05)
    end
end)

-- Splash progress API (used below during module loading)
local function setSplashProgress(pct)
    pcall(function()
        tw(SplashBarFill, 0.25, {Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)})
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- LOAD WIND UI
-- ══════════════════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
setSplashProgress(0.05)

local cacheBust = "?t="..os.time()
local function load(p) return loadstring(game:HttpGet(BASE..p..cacheBust))() end

-- ── Load modules with splash progress ─────────────────────────────────────────
local ConfigMgr   = load("modules/core/configmanager.lua"); setSplashProgress(0.10)
local Fly         = load("modules/movements/fly.lua");       setSplashProgress(0.15)
local Speed       = load("modules/movements/speed.lua");     setSplashProgress(0.20)
local InfJump     = load("modules/movements/infinitejump.lua"); setSplashProgress(0.24)
local Noclip      = load("modules/movements/noclip.lua");    setSplashProgress(0.28)
local AntiRagdoll = load("modules/movements/antiragdoll.lua"); setSplashProgress(0.32)
local Invisible   = load("modules/movements/invisible.lua"); setSplashProgress(0.36)
local FreeCam     = load("modules/movements/freecam.lua");   setSplashProgress(0.40)
local ClickTP     = load("modules/movements/clickteleport.lua"); setSplashProgress(0.44)
local WalkOnWater = load("modules/movements/walkonwater.lua");  setSplashProgress(0.46)
local ESP         = load("modules/visuals/esp.lua");         setSplashProgress(0.48)
local Tracer      = load("modules/visuals/tracer.lua");      setSplashProgress(0.52)
local FullBright  = load("modules/visuals/fullbright.lua");  setSplashProgress(0.56)
local PerfStats   = load("modules/visuals/perfstats.lua");   setSplashProgress(0.60)
local RemoveFog   = load("modules/visuals/removefog.lua");   setSplashProgress(0.64)
local AntiAFK     = load("modules/player/antiafk.lua");      setSplashProgress(0.68)
local InfStamina  = load("modules/player/infinitestamina.lua"); setSplashProgress(0.72)
local AntiFling   = load("modules/player/antifling.lua");    setSplashProgress(0.74)
local Rejoin      = load("modules/player/rejoin.lua");       setSplashProgress(0.76)
local ServerHop   = load("modules/player/serverhop.lua");    setSplashProgress(0.77)
local Teleport    = load("modules/player/teleport.lua");     setSplashProgress(0.78)
local HitboxExp   = load("modules/player/hitboxexpander.lua"); setSplashProgress(0.80)
local Waypoint    = load("modules/player/waypoint.lua");     setSplashProgress(0.84)
local GodMode     = load("modules/player/godmode.lua");      setSplashProgress(0.86)
local NoFallDmg   = load("modules/player/nofalldamage.lua"); setSplashProgress(0.88)
local InstantKill = load("modules/player/instantkill.lua");  setSplashProgress(0.90)

Waypoint:Init()

-- ── Window ────────────────────────────────────────────────────────────────────
local Window = WindUI:CreateWindow({
    Title      = "Leon X v"..CURRENT_VERSION,
    Icon       = "zap",
    Author     = "by leonx24",
    Folder     = "Leon X",
    Size       = UDim2.new(0, 580, 0, 560),
    ToggleKey  = Enum.KeyCode.U,
    Transparent = true,
    Theme      = "Dark",
    NewElements = true,
})

-- Notification helper
local function N(title, state, duration)
    WindUI:Notify({
        Title    = title,
        Content  = state or "",
        Duration = duration or 2,
    })
end

ConfigMgr:Init(Window)
ConfigMgr._notify = function(title, msg)
    N(title, msg)
end

-- ── Tabs ──────────────────────────────────────────────────────────────────────
setSplashProgress(0.92)

local MovTab = Window:Tab({ Title = "Movement", Icon = "person-standing" })
local VisTab = Window:Tab({ Title = "Visual",   Icon = "eye" })
local PlyTab = Window:Tab({ Title = "Player",   Icon = "user" })
local SetTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ══════════════════════════════════════════════════════════════════════════════
MovTab:Section({ Title = "Locomotion" })

local flyToggle = MovTab:Toggle({
    Title    = "Fly",
    Value    = false,
    Callback = function(v)
        if v then Fly:Enable() else Fly:Disable() end
        N("Fly", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("Fly", flyToggle)
local flySpeedSlider = MovTab:Slider({
    Title    = "Fly Speed",
    Value    = { Min = 10, Max = 300, Default = 60 },
    Step     = 1,
    Callback = function(v) if v >= 10 then Fly:SetSpeed(v) end end
})
ConfigMgr:Register("FlySpeed", flySpeedSlider)
local flyKey = Enum.KeyCode.F
MovTab:Keybind({
    Title    = "Fly Keybind",
    Value    = "F",
    Callback = function(k)
        flyKey = Enum.KeyCode[k] or Enum.KeyCode.F
        N("Fly Keybind", k)
    end
})
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= flyKey then return end
    -- Use Fly.Enabled (actual state) instead of toggle UI (may be out of sync)
    local s = not Fly.Enabled
    flyToggle:Set(s)
    if s then Fly:Enable() else Fly:Disable() end
end)

local speedToggle = MovTab:Toggle({
    Title    = "Speed Hack",
    Value    = false,
    Callback = function(v)
        if v then
            local cur = walkSpeedSlider.Value or 16
            Speed:SetWalkSpeed(cur)
            local jp = jumpPowerSlider.Value or 50
            Speed:SetJumpPower(jp)
            Speed:Enable()
        else
            Speed:Disable()
        end
        N("Speed Hack", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("SpeedHack", speedToggle)
local walkSpeedSlider = MovTab:Slider({
    Title    = "Walk Speed",
    Value    = { Min = 16, Max = 250, Default = 16 },
    Step     = 1,
    Callback = function(v) Speed:SetWalkSpeed(v) end
})
ConfigMgr:Register("WalkSpeed", walkSpeedSlider)
local jumpPowerSlider = MovTab:Slider({
    Title    = "Jump Power",
    Value    = { Min = 50, Max = 500, Default = 50 },
    Step     = 1,
    Callback = function(v) Speed:SetJumpPower(v) end
})
ConfigMgr:Register("JumpPower", jumpPowerSlider)

MovTab:Section({ Title = "Misc" })

local infJumpToggle = MovTab:Toggle({
    Title    = "Infinite Jump",
    Value    = false,
    Callback = function(v)
        if v then InfJump:Enable() else InfJump:Disable() end
        N("Infinite Jump", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("InfiniteJump", infJumpToggle)
local noclipToggle = MovTab:Toggle({
    Title    = "Noclip",
    Value    = false,
    Callback = function(v)
        if v then Noclip:Enable() else Noclip:Disable() end
        N("Noclip", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("Noclip", noclipToggle)
local antiRagdollToggle = MovTab:Toggle({
    Title    = "Anti Ragdoll",
    Value    = false,
    Callback = function(v)
        if v then AntiRagdoll:Enable() else AntiRagdoll:Disable() end
        N("Anti Ragdoll", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("AntiRagdoll", antiRagdollToggle)
local invisToggle = MovTab:Toggle({
    Title    = "Invisible (local)",
    Value    = false,
    Callback = function(v)
        if v then Invisible:Enable() else Invisible:Disable() end
        N("Invisible", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("Invisible", invisToggle)
MovTab:Section({ Title = "Camera" })

local fcKey    = Enum.KeyCode.V
local fcToggle = MovTab:Toggle({
    Title    = "Free Cam",
    Value    = false,
    Callback = function(v)
        if v then FreeCam:Enable() else FreeCam:Disable() end
        N("Free Cam", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("FreeCam", fcToggle)
local fcSpeedSlider = MovTab:Slider({
    Title    = "Free Cam Speed",
    Value    = { Min = 5, Max = 300, Default = 40 },
    Step     = 1,
    Callback = function(v) FreeCam:SetSpeed(v) end
})
ConfigMgr:Register("FreeCamSpeed", fcSpeedSlider)
MovTab:Keybind({
    Title    = "FreeCam Keybind",
    Value    = "V",
    Callback = function(k)
        fcKey = Enum.KeyCode[k] or Enum.KeyCode.V
        N("FreeCam Keybind", k)
    end
})
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= fcKey then return end
    -- Use FreeCam.Enabled (actual state) instead of toggle UI
    local s = not FreeCam.Enabled
    fcToggle:Set(s)
    if s then FreeCam:Enable() else FreeCam:Disable() end
end)

MovTab:Section({ Title = "Click Teleport" })

local clickTPToggle = MovTab:Toggle({
    Title    = "Click Teleport",
    Value    = false,
    Callback = function(v)
        if v then ClickTP:Enable() else ClickTP:Disable() end
        N("Click Teleport", v and "Enabled — click to tp" or "Disabled")
    end
})
ConfigMgr:Register("ClickTeleport", clickTPToggle)

MovTab:Section({ Title = "Water" })

local wowToggle = MovTab:Toggle({
    Title    = "Walk on Water",
    Value    = false,
    Callback = function(v)
        if v then WalkOnWater:Enable() else WalkOnWater:Disable() end
        N("Walk on Water", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("WalkOnWater", wowToggle)

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUAL TAB
-- ══════════════════════════════════════════════════════════════════════════════
VisTab:Section({ Title = "Rendering" })

local perfStatsToggle = VisTab:Toggle({
    Title    = "Perf Stats (HUD)",
    Value    = true,
    Callback = function(v)
        if v then PerfStats:Enable() else PerfStats:Disable() end
        N("Perf Stats", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("PerfStats", perfStatsToggle)
local espToggle = VisTab:Toggle({
    Title    = "ESP",
    Value    = false,
    Callback = function(v)
        if v then ESP:Enable() else ESP:Disable() end
        N("ESP", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("ESP", espToggle)
local fullBrightToggle = VisTab:Toggle({
    Title    = "FullBright",
    Value    = false,
    Callback = function(v)
        if v then FullBright:Enable() else FullBright:Disable() end
        N("FullBright", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("FullBright", fullBrightToggle)
local removeFogToggle = VisTab:Toggle({
    Title    = "Remove Fog",
    Value    = false,
    Callback = function(v)
        if v then RemoveFog:Enable() else RemoveFog:Disable() end
        N("Remove Fog", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("RemoveFog", removeFogToggle)

VisTab:Section({ Title = "ESP Settings" })

local EC = {
    White  = Color3.fromRGB(255,255,255), Red    = Color3.fromRGB(255,60,60),
    Green  = Color3.fromRGB(60,220,80),   Blue   = Color3.fromRGB(60,130,255),
    Yellow = Color3.fromRGB(255,220,50),  Cyan   = Color3.fromRGB(60,220,255),
    Pink   = Color3.fromRGB(255,100,200)
}
local espColorDrop = VisTab:Dropdown({
    Title    = "ESP Color",
    Values   = {"White","Red","Green","Blue","Yellow","Cyan","Pink"},
    Value    = "White",
    Callback = function(v) ESP:SetColor(EC[v] or Color3.new(1,1,1)) end
})
ConfigMgr:Register("ESPColor", espColorDrop)
local espOpacitySlider = VisTab:Slider({
    Title    = "ESP Fill Opacity",
    Value    = { Min = 0, Max = 100, Default = 15 },
    Step     = 1,
    Callback = function(v) ESP:SetOpacity(v) end
})
ConfigMgr:Register("ESPOpacity", espOpacitySlider)
local espModeDrop = VisTab:Dropdown({
    Title    = "ESP Show Mode",
    Values   = {"Both","Body","Name"},
    Value    = "Both",
    Callback = function(v) ESP:SetShowMode(v) end
})
ConfigMgr:Register("ESPMode", espModeDrop)

VisTab:Section({ Title = "Tracer" })

local tracerToggle = VisTab:Toggle({
    Title    = "Player Tracer",
    Value    = false,
    Callback = function(v)
        if v then Tracer:Enable() else Tracer:Disable() end
        N("Tracer", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("Tracer", tracerToggle)
local TC = {
    White  = Color3.fromRGB(255,255,255), Red    = Color3.fromRGB(255,60,60),
    Green  = Color3.fromRGB(60,220,80),   Blue   = Color3.fromRGB(60,130,255),
    Yellow = Color3.fromRGB(255,220,50),  Cyan   = Color3.fromRGB(60,220,255),
}
local tracerColorDrop = VisTab:Dropdown({
    Title    = "Tracer Color",
    Values   = {"White","Red","Green","Blue","Yellow","Cyan"},
    Value    = "White",
    Callback = function(v) Tracer:SetColor(TC[v] or Color3.new(1,1,1)) end
})
ConfigMgr:Register("TracerColor", tracerColorDrop)
local tracerOpacitySlider = VisTab:Slider({
    Title    = "Tracer Opacity",
    Value    = { Min = 0, Max = 100, Default = 100 },
    Step     = 1,
    Callback = function(v) Tracer:SetOpacity(v) end
})
ConfigMgr:Register("TracerOpacity", tracerOpacitySlider)
local tracerThickSlider = VisTab:Slider({
    Title    = "Tracer Thickness",
    Value    = { Min = 1, Max = 8, Default = 2 },
    Step     = 1,
    Callback = function(v) Tracer:SetThickness(v) end
})
ConfigMgr:Register("TracerThickness", tracerThickSlider)

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER TAB
-- ══════════════════════════════════════════════════════════════════════════════
PlyTab:Section({ Title = "Utility" })

local antiAFKToggle = PlyTab:Toggle({
    Title    = "Anti AFK",
    Value    = false,
    Callback = function(v)
        if v then AntiAFK:Enable() else AntiAFK:Disable() end
        N("Anti AFK", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("AntiAFK", antiAFKToggle)
local infStaminaToggle = PlyTab:Toggle({
    Title    = "Infinite Stamina",
    Value    = false,
    Callback = function(v)
        if v then InfStamina:Enable() else InfStamina:Disable() end
        N("Infinite Stamina", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("InfStamina", infStaminaToggle)
local godModeToggle = PlyTab:Toggle({
    Title    = "God Mode",
    Value    = false,
    Callback = function(v)
        if v then GodMode:Enable() else GodMode:Disable() end
        N("God Mode", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("GodMode", godModeToggle)
PlyTab:Section({ Title = "Protection" })

local noFallToggle = PlyTab:Toggle({
    Title    = "No Fall Damage",
    Value    = false,
    Callback = function(v)
        if v then NoFallDmg:Enable() else NoFallDmg:Disable() end
        N("No Fall Damage", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("NoFallDamage", noFallToggle)
local antiFlingToggle = PlyTab:Toggle({
    Title    = "Anti Fling",
    Value    = false,
    Callback = function(v)
        if v then AntiFling:Enable() else AntiFling:Disable() end
        N("Anti Fling", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("AntiFling", antiFlingToggle)
local flingThreshSlider = PlyTab:Slider({
    Title    = "Fling Threshold",
    Value    = { Min = 100, Max = 1000, Default = 200 },
    Step     = 1,
    Callback = function(v) AntiFling:SetThreshold(v) end
})
ConfigMgr:Register("FlingThreshold", flingThreshSlider)

PlyTab:Section({ Title = "Combat" })

local hitboxToggle = PlyTab:Toggle({
    Title    = "Hitbox Expander",
    Value    = false,
    Callback = function(v)
        if v then HitboxExp:Enable() else HitboxExp:Disable() end
        N("Hitbox Expander", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("HitboxExpander", hitboxToggle)
local hitboxSizeSlider = PlyTab:Slider({
    Title    = "Hitbox Size",
    Value    = { Min = 5, Max = 30, Default = 10 },
    Step     = 1,
    Callback = function(v) HitboxExp:SetSize(v) end
})
ConfigMgr:Register("HitboxSize", hitboxSizeSlider)
local hitboxAlphaSlider = PlyTab:Slider({
    Title    = "Hitbox Transparency",
    Value    = { Min = 0, Max = 100, Default = 80 },
    Step     = 1,
    Callback = function(v) HitboxExp:SetTransparency(v) end
})
ConfigMgr:Register("HitboxTransparency", hitboxAlphaSlider)
local HC = {
    Red    = Color3.fromRGB(255,60,60),  Green  = Color3.fromRGB(60,220,80),
    Blue   = Color3.fromRGB(60,130,255), Yellow = Color3.fromRGB(255,220,50),
    Cyan   = Color3.fromRGB(60,220,255), Pink   = Color3.fromRGB(255,100,200),
    White  = Color3.fromRGB(255,255,255), Orange = Color3.fromRGB(255,150,30),
}
local hitboxColorDrop = PlyTab:Dropdown({
    Title    = "Hitbox Color",
    Values   = {"Red","Green","Blue","Yellow","Cyan","Pink","White","Orange"},
    Value    = "Red",
    Callback = function(v) HitboxExp:SetColor(HC[v] or Color3.fromRGB(255,60,60)) end
})
ConfigMgr:Register("HitboxColor", hitboxColorDrop)
local teamCheckToggle = PlyTab:Toggle({
    Title    = "Team Check",
    Value    = true,
    Callback = function(v)
        HitboxExp:SetTeamCheck(v)
        N("Team Check", v and "Skip teammates" or "Target all")
    end
})
ConfigMgr:Register("TeamCheck", teamCheckToggle)

PlyTab:Section({ Title = "NPC" })

local ikToggle = PlyTab:Toggle({
    Title    = "Instant Kill NPC",
    Value    = false,
    Callback = function(v)
        if v then InstantKill:Enable() else InstantKill:Disable() end
        N("Instant Kill", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("InstantKill", ikToggle)
local ikModeDrop
ikModeDrop = PlyTab:Dropdown({
    Title    = "Kill Mode",
    Values   = {"All","Specific"},
    Value    = "All",
    Callback = function(v)
        InstantKill:SetMode(v)
        N("Kill Mode", v)
    end
})
ConfigMgr:Register("KillMode", ikModeDrop)
local ikTargetIn = PlyTab:Input({
    Title       = "Target NPC Name",
    Placeholder = "e.g. Zombie",
    Value       = "",
    Callback    = function(v) InstantKill:SetTarget(v) end
})
ConfigMgr:Register("KillTarget", ikTargetIn)
PlyTab:Button({
    Title    = "🐛 Enable Debug Mode",
    Callback = function()
        InstantKill:EnableDebug()
        N("InstantKill", "Debug on — check F9 console")
    end
})
PlyTab:Button({
    Title    = "📊 Show Kill Count",
    Callback = function()
        N("Kill Count", tostring(InstantKill:GetKillCount()).." NPCs")
    end
})

PlyTab:Section({ Title = "Teleport" })

PlyTab:Button({
    Title    = "📍 Copy My Position",
    Callback = function()
        local p = Teleport:SavePosition()
        if p then N("Teleport", ("Saved: %.0f, %.0f, %.0f"):format(p.X,p.Y,p.Z))
        else N("Teleport", "No character") end
    end
})
PlyTab:Button({
    Title    = "🚀 Go to Saved Position",
    Callback = function()
        if Teleport:GotoSaved(Fly) then N("Teleport", "Teleported")
        else N("Teleport", "No position saved") end
    end
})

local selectedPlayer = nil
local tpDrop = PlyTab:Dropdown({
    Title    = "Select Player",
    Values   = Teleport:GetPlayerList(),
    Value    = 1,
    Callback = function(v) selectedPlayer = v end
})
do local list = Teleport:GetPlayerList(); selectedPlayer = list[1] end

PlyTab:Button({
    Title    = "🔄 Refresh Players",
    Callback = function()
        local list = Teleport:GetPlayerList()
        tpDrop:Refresh(list)
        selectedPlayer = list[1]
        N("Players", "Refreshed")
    end
})
PlyTab:Button({
    Title    = "⚡ Teleport to Player",
    Callback = function()
        local name = selectedPlayer
        if not name or name == "(no players)" then return end
        if Teleport:ToPlayer(name, Fly) then N("Teleport", "→ "..name)
        else N("Teleport", name.." not found") end
    end
})

PlyTab:Section({ Title = "Waypoints" })

local wpNameIn = PlyTab:Input({
    Title       = "Waypoint Name",
    Placeholder = "e.g. spawn",
    Value       = "",
    Callback    = function() end
})

local selectedWaypoint = nil
local wpDrop

PlyTab:Button({
    Title    = "➕ Create Waypoint",
    Callback = function()
        local name = wpNameIn.Value or ""
        if name == "" then N("Waypoint", "Enter a name"); return end
        if Waypoint:Exists(name) then N("Waypoint", name.." already exists"); return end
        if Waypoint:Create(name) then
            N("Waypoint", "Created: "..name)
            local list = Waypoint:GetList()
            wpDrop:Refresh(list)
            selectedWaypoint = name
            wpDrop:Select(name)
        else
            N("Waypoint", "Failed to create")
        end
    end
})

wpDrop = PlyTab:Dropdown({
    Title    = "Select Waypoint",
    Values   = Waypoint:GetList(),
    Value    = 1,
    Callback = function(v) selectedWaypoint = v end
})
do local list = Waypoint:GetList(); selectedWaypoint = list[1] end

PlyTab:Button({
    Title    = "🔄 Refresh Waypoints",
    Callback = function()
        local list = Waypoint:GetList()
        wpDrop:Refresh(list)
        selectedWaypoint = list[1]
        N("Waypoints", "Refreshed")
    end
})
PlyTab:Button({
    Title    = "📍 Teleport to Waypoint",
    Callback = function()
        local name = selectedWaypoint
        if not name or name == "(no waypoints)" then
            N("Waypoint", "Select a waypoint first"); return
        end
        if Waypoint:Teleport(name, Fly) then N("Waypoint", "→ "..name)
        else N("Waypoint", "Failed") end
    end
})
PlyTab:Button({
    Title    = "🗑 Delete Waypoint",
    Callback = function()
        local name = selectedWaypoint
        if not name or name == "(no waypoints)" then return end
        if Waypoint:Delete(name) then
            N("Waypoint", "Deleted: "..name)
            local list = Waypoint:GetList()
            wpDrop:Refresh(list)
            selectedWaypoint = list[1]
        else
            N("Waypoint", "Failed to delete")
        end
    end
})

PlyTab:Section({ Title = "Server" })

PlyTab:Button({
    Title    = "Rejoin Server",
    Callback = function()
        N("Rejoin", "Rejoining...")
        task.wait(1.5)
        Rejoin:Execute()
    end
})
PlyTab:Button({
    Title    = "Server Hop",
    Callback = function()
        N("Server Hop", "Finding server...")
        task.wait(0.5)
        ServerHop:Execute()
    end
})
PlyTab:Button({
    Title    = "Copy Player ID",
    Callback = function()
        pcall(function() setclipboard(tostring(lp.UserId)) end)
        N("Player ID", tostring(lp.UserId))
    end
})

PlyTab:Section({ Title = "Stats" })
PlyTab:Paragraph({ Title = "Username", Content = lp.Name })
PlyTab:Paragraph({ Title = "User ID",  Content = tostring(lp.UserId) })

-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ══════════════════════════════════════════════════════════════════════════════
SetTab:Section({ Title = "Interface" })

SetTab:Keybind({
    Title    = "Toggle UI Key",
    Value    = "U",
    Callback = function(k)
        Window:SetToggleKey(Enum.KeyCode[k])
        N("Toggle Key", k)
    end
})
local themeDrop = SetTab:Dropdown({
    Title    = "Theme",
    Values   = {"Dark","Light","Rose","Plant","Red","Indigo","Sky","Violet","Amber"},
    Value    = "Dark",
    Callback = function(v)
        Window:SetTheme(v)
        N("Theme", v)
    end
})
ConfigMgr:Register("Theme", themeDrop)

SetTab:Section({ Title = "Config" })

local cfgNameIn = SetTab:Input({
    Title       = "Config Name",
    Placeholder = "e.g. pvp",
    Value       = "default",
    Callback    = function() end
})

local function getCfgName()
    local v = cfgNameIn.Value
    return (v and v ~= "") and v or "default"
end
local function getCfgList()
    local l = ConfigMgr:List()
    return #l > 0 and l or {"(none)"}
end

local selectedConfig = nil
local cfgDrop = SetTab:Dropdown({
    Title    = "Select Config",
    Values   = getCfgList(),
    Value    = 1,
    Callback = function(v) selectedConfig = v end
})
do local list = getCfgList(); selectedConfig = list[1] end

SetTab:Button({
    Title    = "💾 Save",
    Callback = function()
        local n = getCfgName()
        local ok = ConfigMgr:Save(n)
        N("Config", ok and "Saved: "..n or "Save failed")
        if ok then
            local list = getCfgList()
            cfgDrop:Refresh(list)
            selectedConfig = n
            cfgDrop:Select(n)
        end
    end
})
SetTab:Button({
    Title    = "📂 Load",
    Callback = function()
        local s = selectedConfig
        if not s or s == "(none)" then return end
        local ok = ConfigMgr:Load(s)
        N("Config", ok and "Loaded: "..s or "Load failed")
    end
})
SetTab:Button({
    Title    = "🗑 Delete",
    Callback = function()
        local s = selectedConfig
        if not s or s == "(none)" then return end
        ConfigMgr:Delete(s)
        N("Config", "Deleted: "..s)
        local list = getCfgList()
        cfgDrop:Refresh(list)
        selectedConfig = list[1]
    end
})
SetTab:Button({
    Title    = "⭐ Set as Default",
    Callback = function()
        local s = selectedConfig
        if not s or s == "(none)" then return end
        local ok = ConfigMgr:SetDefault(s)
        N("Config", ok and s.." is default" or "Failed")
    end
})

SetTab:Section({ Title = "About" })
SetTab:Paragraph({
    Title   = "Leon X",
    Content = "v"..CURRENT_VERSION.." • by leonx24"
})

-- ══════════════════════════════════════════════════════════════════════════════
-- MOBILE FLOAT LOGO (appears when WindUI window is minimized)
-- ══════════════════════════════════════════════════════════════════════════════
setSplashProgress(0.96)

local FloatGui = Instance.new("ScreenGui")
FloatGui.Name             = "LeonXFloat"
FloatGui.ResetOnSpawn     = false
FloatGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
FloatGui.DisplayOrder     = 998
FloatGui.IgnoreGuiInset   = true
FloatGui.Parent           = gui

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size                = UDim2.new(0, 56, 0, 56)
FloatBtn.Position            = UDim2.new(0, 16, 0.5, -28)
FloatBtn.BackgroundColor3    = Color3.fromRGB(18, 18, 18)
FloatBtn.BackgroundTransparency = 0.1
FloatBtn.Text                = ""
FloatBtn.AutoButtonColor     = false
FloatBtn.BorderSizePixel     = 0
FloatBtn.Visible             = false
FloatBtn.ZIndex              = 10
FloatBtn.Parent              = FloatGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)  -- perfect circle
FloatCorner.Parent       = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color     = Color3.fromRGB(50, 50, 50)
FloatStroke.Thickness = 1.5
FloatStroke.Parent    = FloatBtn

-- Animated glow ring
task.spawn(function()
    while FloatBtn and FloatBtn.Parent do
        TweenService:Create(FloatStroke, TweenInfo.new(2, Enum.EasingStyle.Sine),
            {Color = Color3.fromRGB(80, 160, 255)}):Play()
        task.wait(2)
        TweenService:Create(FloatStroke, TweenInfo.new(2, Enum.EasingStyle.Sine),
            {Color = Color3.fromRGB(50, 50, 50)}):Play()
        task.wait(2)
    end
end)

-- "LX" text
local FloatLabel = Instance.new("TextLabel")
FloatLabel.Size                = UDim2.new(1, 0, 0, 22)
FloatLabel.Position            = UDim2.new(0, 0, 0, 10)
FloatLabel.BackgroundTransparency = 1
FloatLabel.Text                = "LX"
FloatLabel.TextColor3          = Color3.fromRGB(240, 240, 240)
FloatLabel.TextSize            = 16
FloatLabel.Font                = Enum.Font.GothamBold
FloatLabel.TextXAlignment      = Enum.TextXAlignment.Center
FloatLabel.ZIndex              = 11
FloatLabel.Parent              = FloatBtn

-- Active count below "LX"
local FloatCount = Instance.new("TextLabel")
FloatCount.Size                = UDim2.new(1, 0, 0, 14)
FloatCount.Position            = UDim2.new(0, 0, 0, 32)
FloatCount.BackgroundTransparency = 1
FloatCount.Text                = ""
FloatCount.TextColor3          = Color3.fromRGB(80, 160, 255)
FloatCount.TextSize            = 9
FloatCount.Font                = Enum.Font.GothamMedium
FloatCount.TextXAlignment      = Enum.TextXAlignment.Center
FloatCount.ZIndex              = 11
FloatCount.Parent              = FloatBtn

-- Drag support (touch + mouse)
do
    local dragging, dragStart, startPos, didMove = false, nil, nil, false
    local function isTap(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end
    FloatBtn.InputBegan:Connect(function(i)
        if isTap(i) then
            dragging = true; didMove = false
            dragStart = i.Position; startPos = FloatBtn.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then didMove = true end
            FloatBtn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if isTap(i) and dragging then
            dragging = false
            if not didMove then
                -- Tap = reopen the WindUI window
                pcall(function() Window:Open() end)
                FloatBtn.Visible = false
            end
        end
    end)
end

-- Hook into WindUI's window visibility to show/hide float logo
-- WindUI fires when minimized; we detect via RenderStepped
task.spawn(function()
    task.wait(1)  -- let WindUI fully initialize
    local windGui = nil
    -- Find WindUI's ScreenGui
    for _, g in ipairs(gui:GetChildren()) do
        if g:IsA("ScreenGui") and g.Name ~= "LeonXSplash" and g.Name ~= "LeonXFloat" then
            windGui = g
            break
        end
    end
    if not windGui then return end

    -- Find the main window frame inside WindUI's gui
    local lastVisible = true
    game:GetService("RunService").RenderStepped:Connect(function()
        if not windGui or not windGui.Parent then return end
        -- Check if WindUI's main frame is visible
        local mainFrame = windGui:FindFirstChild("Main") or windGui:FindFirstChild("Window")
        if not mainFrame then
            -- Try first Frame child
            for _, child in ipairs(windGui:GetChildren()) do
                if child:IsA("Frame") then
                    mainFrame = child
                    break
                end
            end
        end
        if not mainFrame then return end

        local isVisible = mainFrame.Visible
        if isVisible ~= lastVisible then
            lastVisible = isVisible
            if not isVisible then
                -- Window hidden → show float logo
                FloatBtn.Visible = true
            else
                -- Window shown → hide float logo
                FloatBtn.Visible = false
            end
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- HIDE SPLASH → REVEAL MAIN UI
-- ══════════════════════════════════════════════════════════════════════════════
setSplashProgress(1.0)

PerfStats:Enable()

-- AutoLoad with delay so WindUI elements are fully ready
task.delay(1.5, function()
    ConfigMgr:AutoLoad()

    -- ── Post-load sync: activate modules based on loaded toggle states ────────
    -- ConfigManager:Load() does NOT fire callbacks, so we manually sync here
    -- in a deterministic order to avoid race conditions.
    pcall(function()
        -- 1. Sync slider/dropdown values to modules (callbacks don't fire during load)
        pcall(function()
            -- Speed sliders
            local ws = walkSpeedSlider.Value or 16
            if ws < 16 then ws = 16 end
            Speed:SetWalkSpeed(ws)
            local jp = jumpPowerSlider.Value or 50
            Speed:SetJumpPower(jp)

            -- Fly speed
            local fs = flySpeedSlider.Value or 60
            if fs < 10 then fs = 60; flySpeedSlider:Set(60) end
            Fly:SetSpeed(fs)

            -- FreeCam speed
            local fcs = fcSpeedSlider.Value or 40
            FreeCam:SetSpeed(fcs)

            -- AntiFling threshold
            AntiFling:SetThreshold(flingThreshSlider.Value or 200)

            -- Hitbox
            HitboxExp:SetSize(hitboxSizeSlider.Value or 10)
            HitboxExp:SetTransparency(hitboxAlphaSlider.Value or 80)
            pcall(function() HitboxExp:SetColor(HC[hitboxColorDrop.Value] or Color3.fromRGB(255,60,60)) end)

            -- ESP settings (applied even if ESP off — will take effect on enable)
            pcall(function() ESP:SetColor(EC[espColorDrop.Value] or Color3.new(1,1,1)) end)
            pcall(function() ESP:SetOpacity(espOpacitySlider.Value or 15) end)
            pcall(function() ESP:SetShowMode(espModeDrop.Value or "Both") end)

            -- Tracer settings
            pcall(function() Tracer:SetColor(TC[tracerColorDrop.Value] or Color3.new(1,1,1)) end)
            pcall(function() Tracer:SetOpacity(tracerOpacitySlider.Value or 100) end)
            pcall(function() Tracer:SetThickness(tracerThickSlider.Value or 2) end)

            -- InstantKill settings
            pcall(function() InstantKill:SetMode(ikModeDrop.Value or "All") end)
            pcall(function() InstantKill:SetTarget(ikTargetIn.Value or "") end)

            -- TeamCheck
            pcall(function() HitboxExp:SetTeamCheck(teamCheckToggle.Value) end)
        end)

        -- 2. Speed Hack
        if speedToggle.Value == true then
            Speed:Enable()
        end

        -- 3. Fly
        if flyToggle.Value == true then
            Fly:Enable()
        end

        -- 4. FreeCam
        if fcToggle.Value == true then
            FreeCam:Enable()
        end

        -- 5. Movement features
        if infJumpToggle.Value == true then InfJump:Enable() end
        if noclipToggle.Value == true then Noclip:Enable() end
        if antiRagdollToggle.Value == true then AntiRagdoll:Enable() end
        if invisToggle.Value == true then Invisible:Enable() end
        if clickTPToggle.Value == true then ClickTP:Enable() end
        if wowToggle.Value == true then WalkOnWater:Enable() end

        -- 6. Visual features
        if perfStatsToggle.Value == true then
            PerfStats:Enable()
        else
            PerfStats:Disable()
        end

        if espToggle.Value == true then ESP:Enable() end
        if fullBrightToggle.Value == true then FullBright:Enable() end
        if removeFogToggle.Value == true then RemoveFog:Enable() end
        if tracerToggle.Value == true then Tracer:Enable() end

        -- 7. Player features
        if antiAFKToggle.Value == true then AntiAFK:Enable() end
        if infStaminaToggle.Value == true then InfStamina:Enable() end
        if godModeToggle.Value == true then GodMode:Enable() end
        if noFallToggle.Value == true then NoFallDmg:Enable() end
        if antiFlingToggle.Value == true then AntiFling:Enable() end
        if hitboxToggle.Value == true then HitboxExp:Enable() end
        if ikToggle.Value == true then InstantKill:Enable() end

        -- 8. Theme (always sync)
        pcall(function()
            local tv = themeDrop.Value
            if tv and tv ~= "" then
                Window:SetTheme(tv)
            end
        end)

        -- 9. WalkSpeed safety: ensure character can walk
        pcall(function()
            local char = game:GetService("Players").LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if not Speed.Enabled and hum.WalkSpeed < 16 then
                        hum.WalkSpeed = 16
                    end
                    if not Speed.Enabled and hum.JumpPower < 50 then
                        hum.JumpPower = 50
                        hum.JumpHeight = 7.2
                    end
                end
            end
        end)
    end)
end)

-- ── Character respawn handler ─────────────────────────────────────────────────
-- Re-enables features that use physics instances (BodyVelocity/BodyGyro)
-- because they get destroyed when the character respawns.
lp.CharacterAdded:Connect(function(char)
    task.wait(1) -- let character fully load
    pcall(function()
        if Fly.Enabled then Fly:Disable(); Fly:Enable() end
        if FreeCam.Enabled then FreeCam:Disable(); FreeCam:Enable() end
    end)
end)

-- Also handle FreeCam if it was enabled by AutoLoad but character wasn't ready
-- (Fly handles itself via its own auto-spawn handler in fly.lua)
task.spawn(function()
    local tries = 0
    while not lp.Character and tries < 30 do
        task.wait(1)
        tries = tries + 1
    end
    if not lp.Character then return end
    task.wait(2)

    pcall(function()
        if fcToggle.Value == true and not FreeCam.Enabled then
            FreeCam:Enable()
        end
    end)
end)

-- Smooth splash exit
task.spawn(function()
    task.wait(0.3)
    -- Fill bar to 100%
    tw(SplashBarFill, 0.2, {Size = UDim2.new(1, 0, 1, 0)})
    task.wait(0.35)

    -- Fade out splash card
    tw(SplashCard, 0.5, {BackgroundTransparency = 1})
    for _, child in ipairs(SplashCard:GetDescendants()) do
        pcall(function()
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
            elseif child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            elseif child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(0.4), {Transparency = 1}):Play()
            end
        end)
    end
    -- Fade out overlay
    tw(SplashBg, 0.5, {BackgroundTransparency = 1})

    task.wait(0.55)
    pcall(function() SplashGui:Destroy() end)
end)

task.delay(2, function()
    N("Leon X", "Welcome!")
end)

