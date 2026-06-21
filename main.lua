-- Leon X | main.lua
-- Noir UI version with splash screen + floating open button

-- ═══════════════════════════════════════════════════════════════════════════
-- EARLY SETUP (line 1 — before ANY HTTP or game interaction)
-- NO hooks here — all hookfunction calls detected by Adonis integrity scan
-- AntiDetect module handles script destruction only (no function hooking)
-- ═══════════════════════════════════════════════════════════════════════════

_G._LeonX_AllowTeleport = function(allow)
    _G._LeonX_AllowTeleportActive = allow and true or false
end


local BASE = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"

local CURRENT_VERSION = "1.3"
pcall(function()
    CURRENT_VERSION = game:HttpGet(BASE.."version.txt?t="..os.time()):match("^%s*(.-)%s*$")
end)

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local lp           = Players.LocalPlayer
local gui          = lp:WaitForChild("PlayerGui")
local isMobile     = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ══════════════════════════════════════════════════════════════════════════════
-- SPLASH SCREEN (shown before UI loads)
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
-- LOAD CUSTOM UI LIBRARY (Noir)
-- ══════════════════════════════════════════════════════════════════════════════
local cacheBust = "?t="..os.time()
local function load(p) return loadstring(game:HttpGet(BASE..p..cacheBust))() end

local Library = load("ui/library.lua")
setSplashProgress(0.05)

-- AntiDetect loads FIRST — DISABLED for testing (v7.3 script destroyer may trigger Adonis absence detection)
local AntiDetect
pcall(function()
    AntiDetect = load("modules/player/antidetect.lua")
    -- AntiDetect:Enable()  -- DISABLED: testing if Adonis kick comes from our code or executor itself
end)

local ConfigMgr   = load("modules/core/configmanager.lua"); setSplashProgress(0.10)
local Fly         = load("modules/movements/fly.lua");       setSplashProgress(0.14)
local Speed       = load("modules/movements/speed.lua");     setSplashProgress(0.18)
local InfJump     = load("modules/movements/infinitejump.lua"); setSplashProgress(0.22)
local Noclip      = load("modules/movements/noclip.lua");    setSplashProgress(0.26)
local AntiRagdoll = load("modules/movements/antiragdoll.lua"); setSplashProgress(0.30)
local Invisible   = load("modules/movements/invisible.lua"); setSplashProgress(0.34)
local FreeCam     = load("modules/movements/freecam.lua");   setSplashProgress(0.38)
local ClickTP     = load("modules/movements/clickteleport.lua"); setSplashProgress(0.42)
local WalkOnWater = load("modules/movements/walkonwater.lua");  setSplashProgress(0.44)
local ESP         = load("modules/visuals/esp.lua");         setSplashProgress(0.46)
local Tracer      = load("modules/visuals/tracer.lua");      setSplashProgress(0.50)
local FullBright  = load("modules/visuals/fullbright.lua");  setSplashProgress(0.54)
local PerfStats   = load("modules/visuals/perfstats.lua");   setSplashProgress(0.58)
local RemoveFog   = load("modules/visuals/removefog.lua");   setSplashProgress(0.62)
local AntiAFK     = load("modules/player/antiafk.lua");      setSplashProgress(0.66)
local InfStamina  = load("modules/player/infinitestamina.lua"); setSplashProgress(0.70)
local AntiFling   = load("modules/player/antifling.lua");    setSplashProgress(0.72)
local Rejoin      = load("modules/player/rejoin.lua");       setSplashProgress(0.74)
local ServerHop   = load("modules/player/serverhop.lua");    setSplashProgress(0.75)
local Teleport    = load("modules/player/teleport.lua");     setSplashProgress(0.76)
local HitboxExp   = load("modules/player/hitboxexpander.lua"); setSplashProgress(0.78)
local Waypoint    = load("modules/player/waypoint.lua");     setSplashProgress(0.82)
local GodMode     = load("modules/player/godmode.lua");      setSplashProgress(0.84)
local NoFallDmg   = load("modules/player/nofalldamage.lua"); setSplashProgress(0.86)
local InstantKill = load("modules/player/instantkill.lua");  setSplashProgress(0.88)
local KillAura    = load("modules/combat/killaura.lua");     setSplashProgress(0.90)
local AutoClicker = load("modules/auto/autoclicker.lua");    setSplashProgress(0.91)
local MacroRec    = load("modules/movements/macrorecorder.lua"); setSplashProgress(0.93)
local AntiVoid    = load("modules/player/antivoid.lua");     setSplashProgress(0.94)
local GamepassSpoof = load("modules/player/gamepassspoofer.lua"); setSplashProgress(0.95)

-- ── Game-specific modules ────────────────────────────────────────────────────
local GAME_MODULES = {
    load("modules/games/growagarden2.lua");
    -- add more game modules here
}

local ActiveGameModule = nil
for _, gm in ipairs(GAME_MODULES) do
    for _, pid in ipairs(gm.PlaceIds) do
        if pid == game.PlaceId then
            ActiveGameModule = gm
            break
        end
    end
    if ActiveGameModule then break end
end

Waypoint:Init()

-- ── Window ────────────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title      = "Leon X v"..CURRENT_VERSION,
    Author     = "by leonx24",
    Size       = UDim2.new(0, 580, 0, 560),
    ToggleKey  = Enum.KeyCode.U,
    Theme      = "Default",
})

-- Notification helper
local function N(title, state, duration)
    Library:Notify({
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

-- Anti-AFK: always active on ALL maps
AntiAFK:Enable()

-- PerfStats HUD: always active on ALL maps (draggable)
PerfStats:Enable()

if ActiveGameModule then
    -- ══ GAME MODE: game tab + player sidebar ══════════════════════════════
    local GameTab = Window:Tab({ Title = ActiveGameModule.Name, Icon = "gamepad-2" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    ActiveGameModule:Init()
    ActiveGameModule:WireUI(GameTab, {
        Fly          = Fly,
        Speed        = Speed,
        Window       = Window,
        PlayerTab    = PlayerTab,
        AntiAFK      = AntiAFK,
        InfiniteJump = InfJump,
        AntiFling    = AntiFling,
        Rejoin       = Rejoin,
        ServerHop    = ServerHop,
        ConfigMgr    = ConfigMgr,
        N            = N,
    })
    N("Game Detected", ActiveGameModule.Name)
else
    -- ══ UNIVERSAL MODE: all standard tabs ═══════════════════════════════════
    local MovTab = Window:Tab({ Title = "Movement", Icon = "person-standing" })
    local CombatTab = Window:Tab({ Title = "Combat", Icon = "swords" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    local TeleTab = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
    local VisTab = Window:Tab({ Title = "Visual", Icon = "eye" })
    local AutoTab = Window:Tab({ Title = "Auto", Icon = "zap" })
    local MacroTab = Window:Tab({ Title = "Macro", Icon = "radio" })
    local SetTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ── Macro Recorder UI ────────────────────────────────────────────────────────
-- Keybind variables (used by InputBegan handlers below)
-- Note: no keybind for InfJump, ESP, FullBright (use UI toggle only)
local noclipKey      = Enum.KeyCode.N
local tpWaypointKey  = Enum.KeyCode.G  -- G (not T, T opens Roblox chat)
local autoClickerKey = Enum.KeyCode.C
local wpQueueKey     = Enum.KeyCode.X  -- X = start/stop waypoint queue (Q conflicts with FPS weapon switch)
local hitboxKey      = Enum.KeyCode.H  -- H = hitbox expander

local macroStatusText = nil
local macroDropdown = nil
local selectedMacroName = nil

-- Refresh dropdown helper
local function refreshMacroList()
    local list = MacroRec:ListMacros()
    if #list == 0 then list = {"(no macros)"} end
    selectedMacroName = list[1]
    if macroDropdown then
        macroDropdown:Refresh(list)
        macroDropdown:Select(list[1])
    end
    return list
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ══════════════════════════════════════════════════════════════════════════════
MovTab:Section({ Title = "Flight" })

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
    local s = not Fly.Enabled
    flyToggle:Set(s)
    if s then Fly:Enable() else Fly:Disable() end
end)

MovTab:Section({ Title = "Speed" })

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

MovTab:Section({ Title = "Physics" })

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
MovTab:Keybind({
    Title    = "Noclip Keybind",
    Value    = "N",
    Callback = function(k)
        noclipKey = Enum.KeyCode[k] or Enum.KeyCode.N
        N("Noclip Keybind", k)
    end
})
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
    local s = not FreeCam.Enabled
    fcToggle:Set(s)
    if s then FreeCam:Enable() else FreeCam:Disable() end
end)

MovTab:Section({ Title = "Special" })

local clickTPToggle = MovTab:Toggle({
    Title    = "Click Teleport",
    Value    = false,
    Callback = function(v)
        if v then ClickTP:Enable() else ClickTP:Disable() end
        N("Click Teleport", v and "Enabled — click to tp" or "Disabled")
    end
})
ConfigMgr:Register("ClickTeleport", clickTPToggle)

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
-- MACRO RECORDER TAB
-- ══════════════════════════════════════════════════════════════════════════════

-- Macro name input
local macroNameInput = MacroTab:Input({
    Title = "Macro Name",
    Placeholder = "e.g. route_to_peak",
    Value = "",
    Callback = function() end
})

MacroTab:Section({ Title = "Status" })
macroStatusText = MacroTab:Paragraph({
    Title = "Status",
    Content = "Idle"
})

MacroTab:Section({ Title = "Recording" })

MacroTab:Button({
    Title = "⏺️ Start Recording",
    Callback = function()
        local name = macroNameInput.Value
        if not name or name == "" then
            name = "macro_" .. os.time()
        end
        if MacroRec:StartRecording(name) then
            N("Macro", "Recording: " .. name)
        end
    end
})

MacroTab:Button({
    Title = "⏹️ Stop Recording",
    Callback = function()
        local macro = MacroRec:StopRecording()
        if macro then
            N("Macro", "Stopped: " .. #macro.points .. " points captured")
        end
    end
})

MacroTab:Section({ Title = "Playback" })

MacroTab:Button({
    Title = "▶️ Play Current Macro",
    Callback = function()
        local macro = MacroRec:GetCurrentMacro()
        if macro then
            MacroRec:StartPlayback(macro)
            N("Macro", "Playing: " .. (macro.name or "unnamed"))
        else
            N("Macro", "No macro loaded")
        end
    end
})

MacroTab:Button({
    Title = "⏸️ Pause / Resume",
    Callback = function()
        MacroRec:PausePlayback()
    end
})

MacroTab:Button({
    Title = "⏹️ Stop Playback",
    Callback = function()
        MacroRec:StopPlayback()
    end
})

local speedSlider = MacroTab:Slider({
    Title = "Playback Speed",
    Value = { Min = 1, Max = 10, Default = 1 },
    Step = 1,
    Callback = function(v) MacroRec:SetPlaybackSpeed(v) end
})
ConfigMgr:Register("MacroSpeed", speedSlider)

local loopToggle = MacroTab:Toggle({
    Title = "Loop Playback",
    Value = false,
    Callback = function(v) MacroRec:SetLoop(v) end
})
ConfigMgr:Register("MacroLoop", loopToggle)

local antiFallToggle = MacroTab:Toggle({
    Title = "Anti-Fall (auto-recover)",
    Value = true,
    Callback = function(v) MacroRec.AntiFall = v end
})
ConfigMgr:Register("MacroAntiFall", antiFallToggle)

local recordInputsToggle = MacroTab:Toggle({
    Title = "Record Inputs (jump, WASD, click)",
    Value = true,
    Callback = function(v) MacroRec.RecordInputs = v end
})
ConfigMgr:Register("MacroRecordInputs", recordInputsToggle)

MacroTab:Section({ Title = "Save / Load" })

MacroTab:Button({
    Title = "💾 Save Current Macro",
    Callback = function()
        local macro = MacroRec:GetCurrentMacro()
        if macro then
            local ok, err = MacroRec:SaveMacro(macro.name, macro)
            if ok then
                refreshMacroList()
                N("Macro", "Saved: " .. macro.name)
            else
                N("Macro", "Save failed: " .. tostring(err))
            end
        else
            N("Macro", "No macro to save")
        end
    end
})

macroDropdown = MacroTab:Dropdown({
    Title = "Select Macro",
    Values = refreshMacroList(),
    Value = 1,
    Callback = function(v) selectedMacroName = v end
})

MacroTab:Button({
    Title = "🔄 Refresh List",
    Callback = function()
        refreshMacroList()
        N("Macro", "List refreshed")
    end
})

MacroTab:Button({
    Title = "📂 Load Selected",
    Callback = function()
        if selectedMacroName and selectedMacroName ~= "(no macros)" then
            local macro = MacroRec:LoadMacro(selectedMacroName)
            if macro then
                N("Macro", "Loaded: " .. selectedMacroName .. " (" .. #macro.points .. " pts)")
            else
                N("Macro", "Failed to load")
            end
        end
    end
})

MacroTab:Button({
    Title = "🗑️ Delete Selected",
    Callback = function()
        if selectedMacroName and selectedMacroName ~= "(no macros)" then
            MacroRec:DeleteMacro(selectedMacroName)
            refreshMacroList()
            N("Macro", "Deleted: " .. selectedMacroName)
        end
    end
})

MacroTab:Section({ Title = "Import / Export" })

MacroTab:Button({
    Title = "📤 Export to Clipboard",
    Callback = function()
        if selectedMacroName and selectedMacroName ~= "(no macros)" then
            local json, err = MacroRec:ExportMacro(selectedMacroName)
            if json then
                N("Macro", "Exported to clipboard")
            else
                N("Macro", "Export failed: " .. tostring(err))
            end
        end
    end
})

local importInput = MacroTab:Input({
    Title = "Paste JSON to Import",
    Placeholder = "Paste exported macro here...",
    Value = "",
    Callback = function() end
})

MacroTab:Button({
    Title = "📥 Import from Clipboard",
    Callback = function()
        local clipboard = ""
        if getclipboard then
            pcall(function() clipboard = getclipboard() end)
        end
        if clipboard == "" then
            clipboard = importInput.Value
        end
        if clipboard ~= "" then
            local name, err = MacroRec:ImportMacro(clipboard)
            if name then
                refreshMacroList()
                N("Macro", "Imported: " .. name)
            else
                N("Macro", "Import failed: " .. tostring(err))
            end
        else
            N("Macro", "No data in clipboard or input")
        end
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- MACRO QUEUE SECTION (Sequential Playback)
-- ══════════════════════════════════════════════════════════════════════════════
MacroTab:Section({ Title = "Macro Queue (Sequential)" })

MacroTab:Paragraph({
    Title = "Queue Info",
    Content = "Chain macros: play one after another automatically"
})

-- Queue dropdown to show current queue
local queueDisplayDropdown = nil
local selectedQueueItem = nil

local function refreshQueueDisplay()
    local queue = MacroRec:GetQueue()
    local names = {}
    for i, item in ipairs(queue) do
        names[#names + 1] = (i .. ". " .. item.name)
    end
    if #names == 0 then names = {"(empty queue)"} end
    if queueDisplayDropdown then
        queueDisplayDropdown:Refresh(names)
        queueDisplayDropdown:Select(names[1])
        selectedQueueItem = names[1]
    end
    return names
end

MacroTab:Button({
    Title = "➕ Add Selected to Queue",
    Callback = function()
        if selectedMacroName and selectedMacroName ~= "(no macros)" then
            if MacroRec:AddToQueue(selectedMacroName) then
                refreshQueueDisplay()
                N("Queue", "Added: " .. selectedMacroName)
            else
                N("Queue", "Already in queue or invalid")
            end
        else
            N("Queue", "Select a macro first")
        end
    end
})

MacroTab:Button({
    Title = "➖ Remove Selected from Queue",
    Callback = function()
        if selectedQueueItem and selectedQueueItem ~= "(empty queue)" then
            -- Extract macro name from "1. macro_name" format
            local macroName = selectedQueueItem:match("%d+%.%s+(.+)")
            if macroName and MacroRec:RemoveFromQueue(macroName) then
                refreshQueueDisplay()
                N("Queue", "Removed: " .. macroName)
            end
        end
    end
})

MacroTab:Button({
    Title = "🗑 Clear Queue",
    Callback = function()
        MacroRec:ClearQueue()
        refreshQueueDisplay()
        N("Queue", "Queue cleared")
    end
})

queueDisplayDropdown = MacroTab:Dropdown({
    Title = "Current Queue",
    Values = refreshQueueDisplay(),
    Value = 1,
    Callback = function(v) selectedQueueItem = v end
})

local queueLoopToggle = MacroTab:Toggle({
    Title = "Loop Queue",
    Value = true,
    Callback = function(v) 
        MacroRec:SetQueueLoop(v) 
        N("Queue", v and "Loop enabled" or "Loop disabled")
    end
})
ConfigMgr:Register("MacroQueueLoop", queueLoopToggle)

MacroTab:Section({ Title = "Queue Playback" })

MacroTab:Button({
    Title = "▶️ Start Queue Playback",
    Callback = function()
        if #MacroRec:GetQueue() == 0 then
            N("Queue", "Queue is empty! Add macros first")
            return
        end
        if MacroRec:StartQueuePlayback() then
            N("Queue", "Queue playback started")
        else
            N("Queue", "Failed to start queue playback")
        end
    end
})

MacroTab:Button({
    Title = "⏹️ Stop Queue Playback",
    Callback = function()
        MacroRec:StopQueuePlayback()
        N("Queue", "Queue stopped")
    end
})

-- Per-map info
MacroTab:Section({ Title = "Map Info" })
MacroTab:Paragraph({
    Title = "Current Map",
    Content = "PlaceId: " .. tostring(game.PlaceId)
})

local perMapToggle = MacroTab:Toggle({
    Title = "Per-Map Macros",
    Value = true,
    Callback = function(v)
        MacroRec.PerMapEnabled = v
        N("Macro", v and "Macros saved per game" or "Macros shared across games")
        refreshMacroList()
    end
})
ConfigMgr:Register("MacroPerMap", perMapToggle)

-- Status updater
task.spawn(function()
    while true do
        if macroStatusText then
            pcall(function()
                local status = MacroRec:GetStatus()
                macroStatusText:Set(status)
            end)
        end
        task.wait(0.5)
    end
end)

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
-- COMBAT TAB
-- ══════════════════════════════════════════════════════════════════════════════
CombatTab:Section({ Title = "Kill Aura" })

local killAuraToggle = CombatTab:Toggle({
    Title    = "Kill Aura",
    Value    = false,
    Callback = function(v)
        if v then KillAura:Enable() else KillAura:Disable() end
        N("Kill Aura", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("KillAura", killAuraToggle)

local killAuraRadiusSlider = CombatTab:Slider({
    Title    = "Radius",
    Value    = { Min = 5, Max = 50, Default = 15 },
    Step     = 1,
    Callback = function(v) KillAura:SetRadius(v) end
})
ConfigMgr:Register("KillAuraRadius", killAuraRadiusSlider)

local killAuraIntervalSlider = CombatTab:Slider({
    Title    = "Attack Interval (ms)",
    Value    = { Min = 50, Max = 1000, Default = 100 },
    Step     = 50,
    Callback = function(v) KillAura:SetAttackInterval(v / 1000) end
})
ConfigMgr:Register("KillAuraInterval", killAuraIntervalSlider)

local killAuraPlayersToggle = CombatTab:Toggle({
    Title    = "Target Players",
    Value    = true,
    Callback = function(v) KillAura:SetTargetPlayers(v) end
})
ConfigMgr:Register("KillAuraPlayers", killAuraPlayersToggle)

local killAuraNPCsToggle = CombatTab:Toggle({
    Title    = "Target NPCs",
    Value    = true,
    Callback = function(v) KillAura:SetTargetNPCs(v) end
})
ConfigMgr:Register("KillAuraNPCs", killAuraNPCsToggle)

local killAuraTeamToggle = CombatTab:Toggle({
    Title    = "Team Check",
    Value    = true,
    Callback = function(v) KillAura:SetTeamCheck(v) end
})
ConfigMgr:Register("KillAuraTeamCheck", killAuraTeamToggle)

CombatTab:Section({ Title = "Hitbox Expander" })

local hitboxToggle = CombatTab:Toggle({
    Title    = "Hitbox Expander",
    Value    = false,
    Callback = function(v)
        if v then HitboxExp:Enable() else HitboxExp:Disable() end
        N("Hitbox Expander", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("HitboxExpander", hitboxToggle)
local hitboxSizeSlider = CombatTab:Slider({
    Title    = "Size",
    Value    = { Min = 5, Max = 30, Default = 10 },
    Step     = 1,
    Callback = function(v) HitboxExp:SetSize(v) end
})
ConfigMgr:Register("HitboxSize", hitboxSizeSlider)
local hitboxAlphaSlider = CombatTab:Slider({
    Title    = "Transparency",
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
local hitboxColorDrop = CombatTab:Dropdown({
    Title    = "Color",
    Values   = {"Red","Green","Blue","Yellow","Cyan","Pink","White","Orange"},
    Value    = "Red",
    Callback = function(v) HitboxExp:SetColor(HC[v] or Color3.fromRGB(255,60,60)) end
})
ConfigMgr:Register("HitboxColor", hitboxColorDrop)
local teamCheckToggle = CombatTab:Toggle({
    Title    = "Team Check",
    Value    = true,
    Callback = function(v)
        HitboxExp:SetTeamCheck(v)
        N("Team Check", v and "Skip teammates" or "Target all")
    end
})
ConfigMgr:Register("TeamCheck", teamCheckToggle)

CombatTab:Keybind({
    Title    = "Hitbox Keybind",
    Value    = "H",
    Callback = function(k)
        hitboxKey = Enum.KeyCode[k] or Enum.KeyCode.H
        N("Hitbox Keybind", k)
    end
})

CombatTab:Section({ Title = "Instant Kill" })

local ikToggle = CombatTab:Toggle({
    Title    = "Instant Kill NPC",
    Value    = false,
    Callback = function(v)
        if v then InstantKill:Enable() else InstantKill:Disable() end
        N("Instant Kill", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("InstantKill", ikToggle)
local ikModeDrop
ikModeDrop = CombatTab:Dropdown({
    Title    = "Kill Mode",
    Values   = {"All","Specific"},
    Value    = "All",
    Callback = function(v)
        InstantKill:SetMode(v)
        N("Kill Mode", v)
    end
})
ConfigMgr:Register("KillMode", ikModeDrop)
local ikTargetIn = CombatTab:Input({
    Title       = "Target NPC Name",
    Placeholder = "e.g. Zombie",
    Value       = "",
    Callback    = function(v) InstantKill:SetTarget(v) end
})
ConfigMgr:Register("KillTarget", ikTargetIn)
CombatTab:Button({
    Title    = "Show Kill Count",
    Callback = function()
        N("Kill Count", tostring(InstantKill:GetKillCount()).." NPCs")
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER TAB (Utility & Protection)
-- ══════════════════════════════════════════════════════════════════════════════
PlayerTab:Section({ Title = "Utility" })

local antiAFKToggle = PlayerTab:Toggle({
    Title    = "Anti AFK",
    Value    = false,
    Callback = function(v)
        if v then AntiAFK:Enable() else AntiAFK:Disable() end
        N("Anti AFK", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("AntiAFK", antiAFKToggle)

local infStaminaToggle = PlayerTab:Toggle({
    Title    = "Infinite Stamina",
    Value    = false,
    Callback = function(v)
        if v then InfStamina:Enable() else InfStamina:Disable() end
        N("Infinite Stamina", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("InfStamina", infStaminaToggle)

local godModeToggle = PlayerTab:Toggle({
    Title    = "God Mode",
    Value    = false,
    Callback = function(v)
        if v then GodMode:Enable() else GodMode:Disable() end
        N("God Mode", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("GodMode", godModeToggle)

PlayerTab:Section({ Title = "Protection" })

local antiDetectToggle = PlayerTab:Toggle({
    Title    = "Anti Detect (Adonis/AC)",
    Value    = false,
    Callback = function(v)
        if AntiDetect then
            if v then AntiDetect:Enable() else AntiDetect:Disable() end
            N("Anti Detect", v and "Enabled" or "Disabled")
        end
    end
})
ConfigMgr:Register("AntiDetect", antiDetectToggle)

local noFallToggle = PlayerTab:Toggle({
    Title    = "No Fall Damage",
    Value    = false,
    Callback = function(v)
        if v then NoFallDmg:Enable() else NoFallDmg:Disable() end
        N("No Fall Damage", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("NoFallDamage", noFallToggle)

local antiFlingToggle = PlayerTab:Toggle({
    Title    = "Anti Fling",
    Value    = false,
    Callback = function(v)
        if v then AntiFling:Enable() else AntiFling:Disable() end
        N("Anti Fling", v and "Enabled (Enhanced)" or "Disabled")
    end
})
ConfigMgr:Register("AntiFling", antiFlingToggle)

local flingThreshSlider = PlayerTab:Slider({
    Title    = "Fling Threshold",
    Value    = { Min = 50, Max = 500, Default = 150 },
    Step     = 10,
    Callback = function(v) AntiFling:SetThreshold(v) end
})
ConfigMgr:Register("FlingThreshold", flingThreshSlider)

local massManipToggle = PlayerTab:Toggle({
    Title    = "Mass Manipulation",
    Value    = true,
    Callback = function(v) 
        AntiFling:SetMassManipulation(v)
        N("Anti Fling", v and "Heavy mode ON" or "Heavy mode OFF")
    end
})
ConfigMgr:Register("MassManipulation", massManipToggle)

local antiVoidToggle = PlayerTab:Toggle({
    Title    = "Anti Void",
    Value    = false,
    Callback = function(v)
        if v then AntiVoid:Enable() else AntiVoid:Disable() end
        N("Anti Void", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("AntiVoid", antiVoidToggle)

local voidThreshSlider = PlayerTab:Slider({
    Title    = "Void Threshold (Y)",
    Value    = { Min = -200, Max = 0, Default = -50 },
    Step     = 10,
    Callback = function(v) AntiVoid:SetVoidThreshold(v) end
})
ConfigMgr:Register("VoidThreshold", voidThreshSlider)

PlayerTab:Section({ Title = "Exploit" })

local gpSpoofToggle = PlayerTab:Toggle({
    Title    = "Gamepass Spoof",
    Value    = false,
    Callback = function(v)
        if v then GamepassSpoof:Enable() else GamepassSpoof:Disable() end
        N("Gamepass Spoof", v and "Spoofing ownership" or "Disabled")
    end
})
ConfigMgr:Register("GamepassSpoof", gpSpoofToggle)

PlayerTab:Section({ Title = "Info" })
PlayerTab:Paragraph({ Title = "Username", Content = lp.Name })
PlayerTab:Paragraph({ Title = "User ID",  Content = tostring(lp.UserId) })
PlayerTab:Button({
    Title    = "Copy Player ID",
    Callback = function()
        pcall(function() setclipboard(tostring(lp.UserId)) end)
        N("Player ID", tostring(lp.UserId))
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- TELEPORT TAB
-- ══════════════════════════════════════════════════════════════════════════════
TeleTab:Section({ Title = "Position" })

TeleTab:Button({
    Title    = "Copy My Position",
    Callback = function()
        local p = Teleport:SavePosition()
        if p then N("Teleport", ("Saved: %.0f, %.0f, %.0f"):format(p.X,p.Y,p.Z))
        else N("Teleport", "No character") end
    end
})
TeleTab:Button({
    Title    = "Go to Saved Position",
    Callback = function()
        if Teleport:GotoSaved(Fly) then N("Teleport", "Teleported")
        else N("Teleport", "No position saved") end
    end
})

TeleTab:Section({ Title = "To Player" })

local selectedPlayer = nil
local tpDrop = TeleTab:Dropdown({
    Title    = "Select Player",
    Values   = Teleport:GetPlayerList(),
    Value    = 1,
    Callback = function(v) selectedPlayer = v end
})
do local list = Teleport:GetPlayerList(); selectedPlayer = list[1] end

TeleTab:Button({
    Title    = "Refresh Players",
    Callback = function()
        local list = Teleport:GetPlayerList()
        tpDrop:Refresh(list)
        selectedPlayer = list[1]
        N("Players", "Refreshed")
    end
})
TeleTab:Button({
    Title    = "Teleport to Player",
    Callback = function()
        local name = selectedPlayer
        if not name or name == "(no players)" then return end
        if Teleport:ToPlayer(name, Fly) then N("Teleport", "→ "..name)
        else N("Teleport", name.." not found") end
    end
})

TeleTab:Section({ Title = "Waypoints" })

local wpNameIn = TeleTab:Input({
    Title       = "Waypoint Name",
    Placeholder = "e.g. spawn",
    Value       = "",
    Callback    = function() end
})

local selectedWaypoint = nil
local wpDrop

TeleTab:Button({
    Title    = "Create Waypoint",
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

wpDrop = TeleTab:Dropdown({
    Title    = "Select Waypoint",
    Values   = Waypoint:GetList(),
    Value    = 1,
    Callback = function(v) selectedWaypoint = v end
})
do local list = Waypoint:GetList(); selectedWaypoint = list[1] end

TeleTab:Button({
    Title    = "Refresh Waypoints",
    Callback = function()
        local list = Waypoint:GetList()
        wpDrop:Refresh(list)
        selectedWaypoint = list[1]
        N("Waypoints", "Refreshed")
    end
})
TeleTab:Button({
    Title    = "Teleport to Waypoint",
    Callback = function()
        local name = selectedWaypoint
        if not name or name == "(no waypoints)" then
            N("Waypoint", "Select a waypoint first"); return
        end
        if Waypoint:Teleport(name, Fly) then N("Waypoint", "→ "..name)
        else N("Waypoint", "Failed") end
    end
})
TeleTab:Button({
    Title    = "Delete Waypoint",
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

TeleTab:Keybind({
    Title    = "Teleport Keybind",
    Value    = "G",
    Callback = function(k)
        tpWaypointKey = Enum.KeyCode[k] or Enum.KeyCode.G
        N("TP Keybind", k)
    end
})

TeleTab:Section({ Title = "Waypoint Queue (Sequential)" })

TeleTab:Paragraph({
    Title = "Queue Info",
    Content = "Teleport through waypoints in order — stops at last"
})

local wpQueueDropdown = nil
local selectedQueueItem = nil

local function refreshWpQueue()
    local queue = Waypoint:GetQueue()
    local names = {}
    for i, name in ipairs(queue) do
        names[#names + 1] = (i .. ". " .. name)
    end
    if #names == 0 then names = {"(empty queue)"} end
    if wpQueueDropdown then
        wpQueueDropdown:Refresh(names)
        wpQueueDropdown:Select(names[1])
        selectedQueueItem = names[1]
    end
    return names
end

TeleTab:Button({
    Title = "➕ Add Selected to Queue",
    Callback = function()
        local name = selectedWaypoint
        if not name or name == "(no waypoints)" then
            N("Queue", "Select a waypoint first"); return
        end
        if Waypoint:AddToQueue(name) then
            refreshWpQueue()
            N("Queue", "Added: " .. name)
        else
            N("Queue", "Already in queue or invalid")
        end
    end
})

TeleTab:Button({
    Title = "➖ Remove Selected from Queue",
    Callback = function()
        if selectedQueueItem and selectedQueueItem ~= "(empty queue)" then
            local wpName = selectedQueueItem:match("%d+%.%s+(.+)")
            if wpName and Waypoint:RemoveFromQueue(wpName) then
                refreshWpQueue()
                N("Queue", "Removed: " .. wpName)
            end
        end
    end
})

TeleTab:Button({
    Title = "🗑 Clear Queue",
    Callback = function()
        Waypoint:ClearQueue()
        refreshWpQueue()
        N("Queue", "Queue cleared")
    end
})

wpQueueDropdown = TeleTab:Dropdown({
    Title = "Current Queue",
    Values = refreshWpQueue(),
    Value = 1,
    Callback = function(v) selectedQueueItem = v end
})

local queueDelaySlider = TeleTab:Slider({
    Title = "Delay Between TPs (sec)",
    Value = { Min = 1, Max = 10, Default = 2 },
    Step = 1,
    Callback = function(v) Waypoint:SetQueueDelay(v) end
})
ConfigMgr:Register("WpQueueDelay", queueDelaySlider)

TeleTab:Button({
    Title = "▶️ Start Queue",
    Callback = function()
        if #Waypoint:GetQueue() == 0 then
            N("Queue", "Queue is empty! Add waypoints first"); return
        end
        if Waypoint:StartQueue(Fly, N) then
            N("Queue", "Queue started")
        else
            N("Queue", "Queue already running")
        end
    end
})

TeleTab:Button({
    Title = "⏹️ Stop Queue",
    Callback = function()
        Waypoint:StopQueue()
        N("Queue", "Queue stopped")
    end
})

TeleTab:Keybind({
    Title    = "Queue Keybind",
    Value    = "X",
    Callback = function(k)
        wpQueueKey = Enum.KeyCode[k] or Enum.KeyCode.X
        N("Queue Keybind", k)
    end
})

TeleTab:Section({ Title = "Server" })

TeleTab:Button({
    Title    = "Rejoin Server",
    Callback = function()
        N("Rejoin", "Rejoining...")
        task.wait(1.5)
        Rejoin:Execute()
    end
})
TeleTab:Button({
    Title    = "Server Hop",
    Callback = function()
        N("Server Hop", "Finding server...")
        task.wait(0.5)
        ServerHop:Execute()
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- AUTO TAB (Automation Features)
-- ══════════════════════════════════════════════════════════════════════════════
AutoTab:Section({ Title = "Auto Clicker" })

local autoClickerToggle = AutoTab:Toggle({
    Title    = "Auto Clicker",
    Value    = false,
    Callback = function(v)
        if v then AutoClicker:Enable() else AutoClicker:Disable() end
        N("Auto Clicker", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("AutoClicker", autoClickerToggle)

local cpsSlider = AutoTab:Slider({
    Title    = "Clicks Per Second (CPS)",
    Value    = { Min = 1, Max = 100, Default = 10 },
    Step     = 1,
    Callback = function(v) AutoClicker:SetCPS(v) end
})
ConfigMgr:Register("AutoClickerCPS", cpsSlider)

local clickTypeDrop = AutoTab:Dropdown({
    Title    = "Click Type",
    Values   = {"mouse", "tool"},
    Value    = "mouse",
    Callback = function(v) 
        AutoClicker:SetClickType(v)
        N("Auto Clicker", "Click type: " .. v)
    end
})
ConfigMgr:Register("AutoClickerType", clickTypeDrop)

local holdDownToggle = AutoTab:Toggle({
    Title    = "Hold Mouse Down",
    Value    = false,
    Callback = function(v) 
        AutoClicker:SetHoldDown(v)
        N("Auto Clicker", v and "Hold mode" or "Click mode")
    end
})
ConfigMgr:Register("AutoClickerHold", holdDownToggle)

local randomDelayToggle = AutoTab:Toggle({
    Title    = "Random Delay",
    Value    = true,
    Callback = function(v) 
        AutoClicker:SetRandomDelay(v)
        N("Auto Clicker", v and "Randomized timing" or "Fixed timing")
    end
})
ConfigMgr:Register("AutoClickerRandom", randomDelayToggle)

AutoTab:Keybind({
    Title    = "Auto Clicker Keybind",
    Value    = "C",
    Callback = function(k)
        autoClickerKey = Enum.KeyCode[k] or Enum.KeyCode.C
        N("AutoClicker Keybind", k)
    end
})

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
    Values   = {"Default","Gold","Emerald","Rose","Violet","Amber","Neon"},
    Value    = "Default",
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

-- ════════════════════════════════════════════════════════════════════════════
-- KEYBIND HANDLERS (Universal Mode)
-- ════════════════════════════════════════════════════════════════════════════

-- Noclip keybind
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= noclipKey then return end
    local s = not Noclip.Enabled
    noclipToggle:Set(s)
    if s then Noclip:Enable() else Noclip:Disable() end
end)

-- Teleport to selected waypoint keybind
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= tpWaypointKey then return end
    local name = selectedWaypoint
    if not name or name == "(no waypoints)" then
        N("Waypoint", "No waypoint selected"); return
    end
    if Waypoint:Teleport(name, Fly) then
        N("Waypoint", "→ " .. name)
    else
        N("Waypoint", "Teleport failed")
    end
end)

-- Auto Clicker keybind
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= autoClickerKey then return end
    local s = not AutoClicker.Enabled
    autoClickerToggle:Set(s)
    if s then AutoClicker:Enable() else AutoClicker:Disable() end
end)

-- Hitbox Expander keybind (H)
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= hitboxKey then return end
    local s = not HitboxExp.Enabled
    hitboxToggle:Set(s)
    if s then HitboxExp:Enable() else HitboxExp:Disable() end
end)

-- Waypoint Queue keybind (X) — start if idle, stop if running
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= wpQueueKey then return end
    if Waypoint:IsQueueRunning() then
        Waypoint:StopQueue()
        N("Queue", "Queue stopped")
    else
        if #Waypoint:GetQueue() == 0 then
            N("Queue", "Queue is empty!"); return
        end
        if Waypoint:StartQueue(Fly, N) then
            N("Queue", "Queue started")
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- PANIC KEY (Delete) — Disable ALL active modules + hide window
-- ════════════════════════════════════════════════════════════════════════════
local panicKey = Enum.KeyCode.Delete

UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= panicKey then return end

    -- Disable all movement modules
    pcall(function() if Fly.Enabled then flyToggle:Set(false); Fly:Disable() end end)
    pcall(function() if Speed.Enabled then speedToggle:Set(false); Speed:Disable() end end)
    pcall(function() if FreeCam.Enabled then fcToggle:Set(false); FreeCam:Disable() end end)
    pcall(function() if InfJump.Enabled then infJumpToggle:Set(false); InfJump:Disable() end end)
    pcall(function() if Noclip.Enabled then noclipToggle:Set(false); Noclip:Disable() end end)
    pcall(function() if AntiRagdoll.Enabled then antiRagdollToggle:Set(false); AntiRagdoll:Disable() end end)
    pcall(function() if Invisible.Enabled then invisToggle:Set(false); Invisible:Disable() end end)
    pcall(function() if ClickTP.Enabled then clickTPToggle:Set(false); ClickTP:Disable() end end)
    pcall(function() if WalkOnWater.Enabled then wowToggle:Set(false); WalkOnWater:Disable() end end)

    -- Disable visual modules
    pcall(function() if ESP.Enabled then espToggle:Set(false); ESP:Disable() end end)
    pcall(function() if FullBright.Enabled then fullBrightToggle:Set(false); FullBright:Disable() end end)
    pcall(function() if Tracer.Enabled then tracerToggle:Set(false); Tracer:Disable() end end)
    pcall(function() if RemoveFog.Enabled then removeFogToggle:Set(false); RemoveFog:Disable() end end)

    -- Disable combat modules
    pcall(function() if KillAura.Enabled then killAuraToggle:Set(false); KillAura:Disable() end end)
    pcall(function() if HitboxExp.Enabled then hitboxToggle:Set(false); HitboxExp:Disable() end end)
    pcall(function() if InstantKill.Enabled then ikToggle:Set(false); InstantKill:Disable() end end)

    -- Disable player modules
    pcall(function() if InfStamina.Enabled then infStaminaToggle:Set(false); InfStamina:Disable() end end)
    pcall(function() if GodMode.Enabled then godModeToggle:Set(false); GodMode:Disable() end end)
    pcall(function() if NoFallDmg.Enabled then noFallToggle:Set(false); NoFallDmg:Disable() end end)
    pcall(function() if AntiFling.Enabled then antiFlingToggle:Set(false); AntiFling:Disable() end end)
    pcall(function() if AntiVoid.Enabled then antiVoidToggle:Set(false); AntiVoid:Disable() end end)
    pcall(function() if GamepassSpoof.Enabled then gpSpoofToggle:Set(false); GamepassSpoof:Disable() end end)

    -- Disable auto modules
    pcall(function() if AutoClicker.Enabled then autoClickerToggle:Set(false); AutoClicker:Disable() end end)

    -- Stop waypoint queue
    pcall(function() Waypoint:StopQueue() end)

    -- Reset WalkSpeed/JumpPower to normal
    pcall(function()
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.JumpHeight = 7.2
            end
        end
    end)

    -- Hide the window
    pcall(function() Window:Close() end)

    N("PANIC", "All features disabled")
end)

SetTab:Section({ Title = "Panic Key" })
SetTab:Keybind({
    Title    = "Panic Key (Disable All)",
    Value    = "Delete",
    Callback = function(k)
        panicKey = Enum.KeyCode[k] or Enum.KeyCode.Delete
        N("Panic Key", k)
    end
})
SetTab:Paragraph({
    Title = "Panic Key Info",
    Content = "Press to disable ALL features and hide the UI"
})
end -- end universal mode

setSplashProgress(0.96)

-- ══════════════════════════════════════════════════════════════════════════════
-- HIDE SPLASH → REVEAL MAIN UI
-- ══════════════════════════════════════════════════════════════════════════════
setSplashProgress(1.0)

-- PerfStats already enabled above (universal)

-- AutoLoad with delay so UI elements are fully ready
task.delay(1.5, function()
    ConfigMgr:AutoLoad()

    -- Anti-AFK is already auto-enabled above (universal)

    if not ActiveGameModule then
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

            -- AntiVoid threshold
            pcall(function() AntiVoid:SetVoidThreshold(voidThreshSlider.Value or -50) end)

            -- AntiFling mass manipulation
            pcall(function() AntiFling:SetMassManipulation(massManipToggle.Value) end)
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
        if AntiDetect and antiDetectToggle.Value == true then AntiDetect:Enable() end
        if antiAFKToggle.Value == true then AntiAFK:Enable() end
        if infStaminaToggle.Value == true then InfStamina:Enable() end
        if godModeToggle.Value == true then GodMode:Enable() end
        if noFallToggle.Value == true then NoFallDmg:Enable() end
        if antiFlingToggle.Value == true then AntiFling:Enable() end
        if antiVoidToggle.Value == true then AntiVoid:Enable() end
        if gpSpoofToggle.Value == true then GamepassSpoof:Enable() end
        if hitboxToggle.Value == true then HitboxExp:Enable() end
        if ikToggle.Value == true then InstantKill:Enable() end

        -- 7b. Auto features
        if autoClickerToggle.Value == true then AutoClicker:Enable() end
        pcall(function() AutoClicker:SetCPS(cpsSlider.Value or 10) end)
        pcall(function() AutoClicker:SetClickType(clickTypeDrop.Value or "mouse") end)
        pcall(function() AutoClicker:SetHoldDown(holdDownToggle.Value) end)
        pcall(function() AutoClicker:SetRandomDelay(randomDelayToggle.Value) end)

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
    end -- end if not ActiveGameModule
end)

-- ── Character respawn handler ─────────────────────────────────────────────────
if not ActiveGameModule then
lp.CharacterAdded:Connect(function(char)
    task.wait(1)
    pcall(function()
        if Fly.Enabled then Fly:Disable(); Fly:Enable() end
        if FreeCam.Enabled then FreeCam:Disable(); FreeCam:Enable() end
    end)
end)

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
end

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

