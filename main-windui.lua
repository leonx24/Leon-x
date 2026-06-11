-- Leon X | main.lua (Wind UI version)
-- UI wiring with Wind UI library

local BASE = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"

-- Fetch current version from version.txt
local CURRENT_VERSION = "1.0"
pcall(function()
    CURRENT_VERSION = game:HttpGet(BASE.."version.txt?t="..os.time()):match("^%s*(.-)%s*$")
end)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Load Wind UI from GitHub
local _version = "1.6.64-fix"
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua"))()

-- Cache buster to force fresh loads
local cacheBust = "?t="..os.time()
local function load(p) return loadstring(game:HttpGet(BASE..p..cacheBust))() end

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Leon X v"..CURRENT_VERSION,
    Icon = "zap",
    Author = "by leonx24",
    Folder = "Leon X",
    Size = UDim2.new(0, 550, 0, 550),
    ToggleKey = Enum.KeyCode.O,
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
})

-- Notification helper
local function N(title, message, type, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration or 2,
    })
end

-- Load all modules
N("Leon X", "Loading modules...", "Info", 1)

local ConfigMgr = load("modules/core/configmanager.lua")
local Fly = load("modules/movements/fly.lua")
local Speed = load("modules/movements/speed.lua")
local InfJump = load("modules/movements/infinitejump.lua")
local Noclip = load("modules/movements/noclip.lua")
local AntiRagdoll = load("modules/movements/antiragdoll.lua")
local Invisible = load("modules/movements/invisible.lua")
local FreeCam = load("modules/movements/freecam.lua")
local ClickTP = load("modules/movements/clickteleport.lua")
local ESP = load("modules/visuals/esp.lua")
local Tracer = load("modules/visuals/tracer.lua")
local FullBright = load("modules/visuals/fullbright.lua")
local PerfStats = load("modules/visuals/perfstats.lua")
local RemoveFog = load("modules/visuals/removefog.lua")
local AntiAFK = load("modules/player/antiafk.lua")
local InfStamina = load("modules/player/infinitestamina.lua")
local AntiFling = load("modules/player/antifling.lua")
local Rejoin = load("modules/player/rejoin.lua")
local Teleport = load("modules/player/teleport.lua")
local HitboxExp = load("modules/player/hitboxexpander.lua")
local Waypoint = load("modules/player/waypoint.lua")
local GodMode = load("modules/player/godmode.lua")
local NoFallDmg = load("modules/player/nofalldamage.lua")

Waypoint:Init()

-- Create Tabs
local MovTab = Window:Tab({
    Title = "Movement",
    Icon = "person-standing",
})

local VisTab = Window:Tab({
    Title = "Visual",
    Icon = "eye",
})

local PlyTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

local SetTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ══════════════════════════════════════════════════════════════════════════════
MovTab:Section({ Title = "Locomotion" })

local flyToggle = MovTab:Toggle({
    Title = "Fly",
    Default = false,
    Callback = function(v)
        if v then Fly:Enable() else Fly:Disable() end
        N("Fly", v and "Enabled" or "Disabled")
    end
})

MovTab:Slider({
    Title = "Fly Speed",
    Min = 10,
    Max = 300,
    Default = 60,
    Callback = function(v) Fly:SetSpeed(v) end
})

local flyKey = Enum.KeyCode.F
MovTab:Keybind({
    Title = "Fly Keybind",
    Default = Enum.KeyCode.F,
    Callback = function(k)
        flyKey = k
        N("Fly Keybind", "Set to "..k.Name)
    end
})

UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= flyKey then return end
    local s = not Fly.Enabled
    flyToggle:Set(s)
    if s then Fly:Enable() else Fly:Disable() end
end)

MovTab:Toggle({
    Title = "Speed Hack",
    Default = false,
    Callback = function(v)
        Speed:SetWalkSpeed(v and 60 or 16)
        if v then Speed:Enable() else Speed:Disable() end
        N("Speed Hack", v and "Enabled (60)" or "Disabled")
    end
})

MovTab:Slider({
    Title = "Walk Speed",
    Min = 16,
    Max = 250,
    Default = 16,
    Callback = function(v)
        Speed:SetWalkSpeed(v)
        Speed:Enable()
    end
})

MovTab:Slider({
    Title = "Jump Power",
    Min = 50,
    Max = 500,
    Default = 50,
    Callback = function(v)
        Speed:SetJumpPower(v)
        Speed:Enable()
    end
})

MovTab:Section({ Title = "Misc" })

MovTab:Toggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(v)
        if v then InfJump:Enable() else InfJump:Disable() end
        N("Infinite Jump", v and "Enabled" or "Disabled")
    end
})

MovTab:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        if v then Noclip:Enable() else Noclip:Disable() end
        N("Noclip", v and "Enabled" or "Disabled")
    end
})

MovTab:Toggle({
    Title = "Anti Ragdoll",
    Default = false,
    Callback = function(v)
        if v then AntiRagdoll:Enable() else AntiRagdoll:Disable() end
        N("Anti Ragdoll", v and "Enabled" or "Disabled")
    end
})

MovTab:Toggle({
    Title = "Invisible (local)",
    Default = false,
    Callback = function(v)
        if v then Invisible:Enable() else Invisible:Disable() end
        N("Invisible", v and "Enabled" or "Disabled")
    end
})

MovTab:Section({ Title = "Camera" })

local fcKey = Enum.KeyCode.V
local fcToggle = MovTab:Toggle({
    Title = "Free Cam",
    Default = false,
    Callback = function(v)
        if v then FreeCam:Enable() else FreeCam:Disable() end
        N("Free Cam", v and "Enabled" or "Disabled")
    end
})

MovTab:Slider({
    Title = "Free Cam Speed",
    Min = 5,
    Max = 300,
    Default = 40,
    Callback = function(v) FreeCam:SetSpeed(v) end
})

MovTab:Keybind({
    Title = "FreeCam Keybind",
    Default = Enum.KeyCode.V,
    Callback = function(k)
        fcKey = k
        N("FreeCam Keybind", "Set to "..k.Name)
    end
})

UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= fcKey then return end
    local s = not FreeCam.Enabled
    fcToggle:Set(s)
    if s then FreeCam:Enable() else FreeCam:Disable() end
end)

MovTab:Section({ Title = "Click Teleport" })

MovTab:Toggle({
    Title = "Click Teleport",
    Default = false,
    Callback = function(v)
        if v then ClickTP:Enable() else ClickTP:Disable() end
        N("Click Teleport", v and "Enabled — click to tp" or "Disabled")
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUAL TAB
-- ══════════════════════════════════════════════════════════════════════════════
VisTab:Section({ Title = "Rendering" })

VisTab:Toggle({
    Title = "Perf Stats (HUD)",
    Default = true,
    Callback = function(v)
        if v then PerfStats:Enable() else PerfStats:Disable() end
        N("Perf Stats", v and "Enabled" or "Disabled")
    end
})

VisTab:Toggle({
    Title = "ESP",
    Default = false,
    Callback = function(v)
        if v then ESP:Enable() else ESP:Disable() end
        N("ESP", v and "Enabled" or "Disabled")
    end
})

VisTab:Toggle({
    Title = "FullBright",
    Default = false,
    Callback = function(v)
        if v then FullBright:Enable() else FullBright:Disable() end
        N("FullBright", v and "Enabled" or "Disabled")
    end
})

VisTab:Toggle({
    Title = "Remove Fog",
    Default = false,
    Callback = function(v)
        if v then RemoveFog:Enable() else RemoveFog:Disable() end
        N("Remove Fog", v and "Enabled" or "Disabled")
    end
})

VisTab:Section({ Title = "Appearance" })

local EC = {
    White = Color3.fromRGB(255,255,255),
    Red = Color3.fromRGB(255,60,60),
    Green = Color3.fromRGB(60,220,80),
    Blue = Color3.fromRGB(60,130,255),
    Yellow = Color3.fromRGB(255,220,50),
    Cyan = Color3.fromRGB(60,220,255),
    Pink = Color3.fromRGB(255,100,200)
}

VisTab:Dropdown({
    Title = "ESP Color",
    List = {"White","Red","Green","Blue","Yellow","Cyan","Pink"},
    Default = "White",
    Callback = function(v)
        ESP:SetColor(EC[v] or Color3.new(1,1,1))
    end
})

VisTab:Slider({
    Title = "ESP Fill Opacity",
    Min = 0,
    Max = 100,
    Default = 15,
    Callback = function(v) ESP:SetOpacity(v) end
})

VisTab:Dropdown({
    Title = "ESP Show Mode",
    List = {"Both","Body","Name"},
    Default = "Both",
    Callback = function(v) ESP:SetShowMode(v) end
})

VisTab:Section({ Title = "Tracer" })

VisTab:Toggle({
    Title = "Player Tracer",
    Default = false,
    Callback = function(v)
        if v then Tracer:Enable() else Tracer:Disable() end
        N("Tracer", v and "Enabled" or "Disabled")
    end
})

local TC = {
    White = Color3.fromRGB(255,255,255),
    Red = Color3.fromRGB(255,60,60),
    Green = Color3.fromRGB(60,220,80),
    Blue = Color3.fromRGB(60,130,255),
    Yellow = Color3.fromRGB(255,220,50),
    Cyan = Color3.fromRGB(60,220,255)
}

VisTab:Dropdown({
    Title = "Tracer Color",
    List = {"White","Red","Green","Blue","Yellow","Cyan"},
    Default = "White",
    Callback = function(v)
        Tracer:SetColor(TC[v] or Color3.new(1,1,1))
    end
})

VisTab:Slider({
    Title = "Tracer Opacity",
    Min = 0,
    Max = 100,
    Default = 100,
    Callback = function(v) Tracer:SetOpacity(v) end
})

VisTab:Slider({
    Title = "Tracer Thickness",
    Min = 1,
    Max = 8,
    Default = 2,
    Callback = function(v) Tracer:SetThickness(v) end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER TAB
-- ══════════════════════════════════════════════════════════════════════════════
PlyTab:Section({ Title = "Utility" })

PlyTab:Toggle({
    Title = "Anti AFK",
    Default = false,
    Callback = function(v)
        if v then AntiAFK:Enable() else AntiAFK:Disable() end
        N("Anti AFK", v and "Enabled" or "Disabled")
    end
})

PlyTab:Toggle({
    Title = "Infinite Stamina",
    Default = false,
    Callback = function(v)
        if v then InfStamina:Enable() else InfStamina:Disable() end
        N("Infinite Stamina", v and "Enabled" or "Disabled")
    end
})

PlyTab:Toggle({
    Title = "God Mode",
    Default = false,
    Callback = function(v)
        if v then GodMode:Enable() else GodMode:Disable() end
        N("God Mode", v and "Enabled" or "Disabled")
    end
})

PlyTab:Section({ Title = "Protection" })

PlyTab:Toggle({
    Title = "No Fall Damage",
    Default = false,
    Callback = function(v)
        if v then NoFallDmg:Enable() else NoFallDmg:Disable() end
        N("No Fall Damage", v and "Enabled" or "Disabled")
    end
})

PlyTab:Toggle({
    Title = "Anti Fling",
    Default = false,
    Callback = function(v)
        if v then AntiFling:Enable() else AntiFling:Disable() end
        N("Anti Fling", v and "Enabled" or "Disabled")
    end
})

PlyTab:Slider({
    Title = "Fling Threshold",
    Min = 100,
    Max = 1000,
    Default = 200,
    Callback = function(v) AntiFling:SetThreshold(v) end
})

PlyTab:Section({ Title = "Combat" })

PlyTab:Toggle({
    Title = "Hitbox Expander",
    Default = false,
    Callback = function(v)
        if v then HitboxExp:Enable() else HitboxExp:Disable() end
        N("Hitbox Expander", v and "Enabled" or "Disabled")
    end
})

PlyTab:Slider({
    Title = "Hitbox Size",
    Min = 5,
    Max = 30,
    Default = 10,
    Callback = function(v) HitboxExp:SetSize(v) end
})

PlyTab:Slider({
    Title = "Hitbox Transparency",
    Min = 0,
    Max = 100,
    Default = 80,
    Callback = function(v) HitboxExp:SetTransparency(v) end
})

PlyTab:Toggle({
    Title = "Team Check",
    Default = true,
    Callback = function(v)
        HitboxExp:SetTeamCheck(v)
        N("Team Check", v and "Skip teammates" or "Target all")
    end
})

PlyTab:Section({ Title = "Teleport" })

PlyTab:Button({
    Title = "📍 Copy My Position",
    Callback = function()
        local p = Teleport:SavePosition()
        if p then
            N("Teleport", ("Saved: %.0f, %.0f, %.0f"):format(p.X,p.Y,p.Z))
        else
            N("Teleport", "No character")
        end
    end
})

PlyTab:Button({
    Title = "🚀 Go to Saved Position",
    Callback = function()
        if Teleport:GotoSaved(Fly) then
            N("Teleport", "Teleported")
        else
            N("Teleport", "No position saved")
        end
    end
})

local tpDrop = PlyTab:Dropdown({
    Title = "Select Player",
    List = Teleport:GetPlayerList(),
    Default = Teleport:GetPlayerList()[1]
})

PlyTab:Button({
    Title = "🔄 Refresh Players",
    Callback = function()
        tpDrop:SetList(Teleport:GetPlayerList())
        N("Teleport", "Refreshed")
    end
})

PlyTab:Button({
    Title = "⚡ Teleport to Player",
    Callback = function()
        local name = tpDrop:GetValue()
        if name == "(no players)" then return end
        if Teleport:ToPlayer(name, Fly) then
            N("Teleport", "→ "..name)
        else
            N("Teleport", name.." not found")
        end
    end
})

PlyTab:Section({ Title = "Waypoints" })

local wpNameIn = PlyTab:Input({
    Title = "Waypoint Name",
    Placeholder = "e.g. spawn",
    Default = "",
    Callback = function() end
})

PlyTab:Button({
    Title = "➕ Create Waypoint",
    Callback = function()
        local name = wpNameIn:GetValue()
        if name == "" then
            N("Waypoint", "Enter a name")
            return
        end
        if Waypoint:Exists(name) then
            N("Waypoint", name.." already exists")
            return
        end
        if Waypoint:Create(name) then
            N("Waypoint", "Created: "..name)
        else
            N("Waypoint", "Failed to create")
        end
    end
})

local wpDrop = PlyTab:Dropdown({
    Title = "Select Waypoint",
    List = Waypoint:GetList(),
    Default = Waypoint:GetList()[1]
})

PlyTab:Button({
    Title = "🔄 Refresh Waypoints",
    Callback = function()
        wpDrop:SetList(Waypoint:GetList())
        N("Waypoint", "Refreshed")
    end
})

PlyTab:Button({
    Title = "📍 Teleport to Waypoint",
    Callback = function()
        local name = wpDrop:GetValue()
        if name == "(no waypoints)" then return end
        if Waypoint:Teleport(name, Fly) then
            N("Waypoint", "→ "..name)
        else
            N("Waypoint", "Failed")
        end
    end
})

PlyTab:Button({
    Title = "🗑 Delete Waypoint",
    Callback = function()
        local name = wpDrop:GetValue()
        if name == "(no waypoints)" then return end
        if Waypoint:Delete(name) then
            N("Waypoint", "Deleted: "..name)
            wpDrop:SetList(Waypoint:GetList())
        else
            N("Waypoint", "Failed to delete")
        end
    end
})

PlyTab:Section({ Title = "Server" })

PlyTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        N("Rejoin", "Rejoining...")
        task.wait(1.5)
        Rejoin:Execute()
    end
})

PlyTab:Button({
    Title = "Copy Player ID",
    Callback = function()
        pcall(function() setclipboard(tostring(lp.UserId)) end)
        N("Copied", "ID: "..lp.UserId)
    end
})

PlyTab:Section({ Title = "Stats" })

PlyTab:Paragraph({
    Title = "Username",
    Content = lp.Name
})

PlyTab:Paragraph({
    Title = "User ID",
    Content = tostring(lp.UserId)
})

-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ══════════════════════════════════════════════════════════════════════════════
SetTab:Section({ Title = "Interface" })

SetTab:Keybind({
    Title = "Toggle UI Key",
    Default = Enum.KeyCode.O,
    Callback = function(k)
        Window:SetToggleKey(k)
        N("Toggle Key", "Set to "..k.Name)
    end
})

SetTab:Dropdown({
    Title = "Theme",
    List = {"Dark","Light","Mocha","Aqua","Jester","Amber"},
    Default = "Dark",
    Callback = function(v)
        Window:SetTheme(v)
        N("Theme", v.." applied")
    end
})

SetTab:Toggle({
    Title = "Show Notifications",
    Default = true,
    Callback = function(v)
        N("Notifications", v and "Enabled" or "Disabled")
    end
})

SetTab:Section({ Title = "About" })

SetTab:Paragraph({
    Title = "Leon X",
    Content = "Version "..CURRENT_VERSION.." • by leonx24"
})

SetTab:Button({
    Title = "Join Discord",
    Callback = function()
        N("Discord", "Link copied to clipboard")
        pcall(function() setclipboard("https://discord.gg/leonx") end)
    end
})

-- Boot sequence
PerfStats:Enable()
task.delay(1, function()
    N("Leon X", "Welcome!")
end)
