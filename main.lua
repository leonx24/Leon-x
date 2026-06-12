-- Leon X | main.lua
-- Custom UI Library version — splash screen, themes, float logo for mobile

local BASE = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"

local CURRENT_VERSION = "1.3"
pcall(function()
    CURRENT_VERSION = game:HttpGet(BASE.."version.txt?t="..os.time()):match("^%s*(.-)%s*$")
end)

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local lp      = Players.LocalPlayer

local cacheBust = "?t="..os.time()
local function load(p) return loadstring(game:HttpGet(BASE..p..cacheBust))() end

-- ── Load custom UI Library (splash starts automatically) ──────────────────────
local Library = load("ui/library.lua")

-- ── Load modules with splash progress ─────────────────────────────────────────
local ConfigMgr   = load("modules/core/configmanager.lua"); Library:SetSplashProgress(0.08)
local Fly         = load("modules/movements/fly.lua");       Library:SetSplashProgress(0.12)
local Speed       = load("modules/movements/speed.lua");     Library:SetSplashProgress(0.16)
local InfJump     = load("modules/movements/infinitejump.lua"); Library:SetSplashProgress(0.20)
local Noclip      = load("modules/movements/noclip.lua");    Library:SetSplashProgress(0.24)
local AntiRagdoll = load("modules/movements/antiragdoll.lua"); Library:SetSplashProgress(0.28)
local Invisible   = load("modules/movements/invisible.lua"); Library:SetSplashProgress(0.32)
local FreeCam     = load("modules/movements/freecam.lua");   Library:SetSplashProgress(0.36)
local ClickTP     = load("modules/movements/clickteleport.lua"); Library:SetSplashProgress(0.40)
local ESP         = load("modules/visuals/esp.lua");         Library:SetSplashProgress(0.44)
local Tracer      = load("modules/visuals/tracer.lua");      Library:SetSplashProgress(0.48)
local FullBright  = load("modules/visuals/fullbright.lua");  Library:SetSplashProgress(0.52)
local PerfStats   = load("modules/visuals/perfstats.lua");   Library:SetSplashProgress(0.56)
local RemoveFog   = load("modules/visuals/removefog.lua");   Library:SetSplashProgress(0.60)
local AntiAFK     = load("modules/player/antiafk.lua");      Library:SetSplashProgress(0.64)
local InfStamina  = load("modules/player/infinitestamina.lua"); Library:SetSplashProgress(0.68)
local AntiFling   = load("modules/player/antifling.lua");    Library:SetSplashProgress(0.72)
local Rejoin      = load("modules/player/rejoin.lua");       Library:SetSplashProgress(0.74)
local Teleport    = load("modules/player/teleport.lua");     Library:SetSplashProgress(0.76)
local HitboxExp   = load("modules/player/hitboxexpander.lua"); Library:SetSplashProgress(0.80)
local Waypoint    = load("modules/player/waypoint.lua");     Library:SetSplashProgress(0.84)
local GodMode     = load("modules/player/godmode.lua");      Library:SetSplashProgress(0.86)
local NoFallDmg   = load("modules/player/nofalldamage.lua"); Library:SetSplashProgress(0.88)
local InstantKill = load("modules/player/instantkill.lua");  Library:SetSplashProgress(0.90)

Waypoint:Init()

-- ── Notification helper ───────────────────────────────────────────────────────
local function N(title, state, duration)
    Library:Notify({
        Title    = title,
        Text     = state or "",
        Type     = "info",
        Duration = duration or 2,
    })
end

-- ── Tabs ──────────────────────────────────────────────────────────────────────
Library:SetSplashProgress(0.92)

local MovTab = Library:CreateTab("Movement", "🏃")
local VisTab = Library:CreateTab("Visual",   "👁")
local PlyTab = Library:CreateTab("Player",   "👤")
local SetTab = Library:CreateTab("Settings", "⚙")

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ══════════════════════════════════════════════════════════════════════════════
MovTab:AddSection("Locomotion")

local flyToggle = MovTab:AddToggle({
    Name     = "Fly",
    Flag     = "Fly",
    Default  = false,
    Callback = function(v)
        if v then Fly:Enable() else Fly:Disable() end
        N("Fly", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("Fly", flyToggle)

local flySpeedSlider = MovTab:AddSlider({
    Name     = "Fly Speed",
    Flag     = "FlySpeed",
    Min      = 10,
    Max      = 300,
    Default  = 60,
    Callback = function(v) Fly:SetSpeed(v) end
})
ConfigMgr:Register("FlySpeed", flySpeedSlider)

local flyKey = Enum.KeyCode.F
MovTab:AddKeybind({
    Name     = "Fly Keybind",
    Flag     = "FlyKey",
    Default  = Enum.KeyCode.F,
    Callback = function(k)
        flyKey = k
        N("Fly Keybind", k.Name)
    end
})
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= flyKey then return end
    local s = not Fly.Enabled
    flyToggle:Set(s)
    if s then Fly:Enable() else Fly:Disable() end
end)

local speedToggle = MovTab:AddToggle({
    Name     = "Speed Hack",
    Flag     = "SpeedHack",
    Default  = false,
    Callback = function(v)
        Speed:SetWalkSpeed(v and 60 or 16)
        if v then Speed:Enable() else Speed:Disable() end
        N("Speed Hack", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("SpeedHack", speedToggle)

local walkSpeedSlider = MovTab:AddSlider({
    Name     = "Walk Speed",
    Flag     = "WalkSpeed",
    Min      = 16,
    Max      = 250,
    Default  = 16,
    Callback = function(v) Speed:SetWalkSpeed(v); Speed:Enable() end
})
ConfigMgr:Register("WalkSpeed", walkSpeedSlider)

local jumpPowerSlider = MovTab:AddSlider({
    Name     = "Jump Power",
    Flag     = "JumpPower",
    Min      = 50,
    Max      = 500,
    Default  = 50,
    Callback = function(v) Speed:SetJumpPower(v); Speed:Enable() end
})
ConfigMgr:Register("JumpPower", jumpPowerSlider)

MovTab:AddSection("Misc")

local infJumpToggle = MovTab:AddToggle({
    Name     = "Infinite Jump",
    Flag     = "InfiniteJump",
    Default  = false,
    Callback = function(v)
        if v then InfJump:Enable() else InfJump:Disable() end
        N("Infinite Jump", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("InfiniteJump", infJumpToggle)

local noclipToggle = MovTab:AddToggle({
    Name     = "Noclip",
    Flag     = "Noclip",
    Default  = false,
    Callback = function(v)
        if v then Noclip:Enable() else Noclip:Disable() end
        N("Noclip", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("Noclip", noclipToggle)

local antiRagdollToggle = MovTab:AddToggle({
    Name     = "Anti Ragdoll",
    Flag     = "AntiRagdoll",
    Default  = false,
    Callback = function(v)
        if v then AntiRagdoll:Enable() else AntiRagdoll:Disable() end
        N("Anti Ragdoll", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("AntiRagdoll", antiRagdollToggle)

local invisToggle = MovTab:AddToggle({
    Name     = "Invisible (local)",
    Flag     = "Invisible",
    Default  = false,
    Callback = function(v)
        if v then Invisible:Enable() else Invisible:Disable() end
        N("Invisible", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("Invisible", invisToggle)

MovTab:AddSection("Camera")

local fcKey    = Enum.KeyCode.V
local fcToggle = MovTab:AddToggle({
    Name     = "Free Cam",
    Flag     = "FreeCam",
    Default  = false,
    Callback = function(v)
        if v then FreeCam:Enable() else FreeCam:Disable() end
        N("Free Cam", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("FreeCam", fcToggle)

local fcSpeedSlider = MovTab:AddSlider({
    Name     = "Free Cam Speed",
    Flag     = "FreeCamSpeed",
    Min      = 5,
    Max      = 300,
    Default  = 40,
    Callback = function(v) FreeCam:SetSpeed(v) end
})
ConfigMgr:Register("FreeCamSpeed", fcSpeedSlider)

MovTab:AddKeybind({
    Name     = "FreeCam Keybind",
    Flag     = "FreeCamKey",
    Default  = Enum.KeyCode.V,
    Callback = function(k)
        fcKey = k
        N("FreeCam Keybind", k.Name)
    end
})
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= fcKey then return end
    local s = not FreeCam.Enabled
    fcToggle:Set(s)
    if s then FreeCam:Enable() else FreeCam:Disable() end
end)

MovTab:AddSection("Click Teleport")

local clickTPToggle = MovTab:AddToggle({
    Name     = "Click Teleport",
    Flag     = "ClickTeleport",
    Default  = false,
    Callback = function(v)
        if v then ClickTP:Enable() else ClickTP:Disable() end
        N("Click Teleport", v and "Enabled — click to tp" or "Disabled")
    end
})
ConfigMgr:Register("ClickTeleport", clickTPToggle)

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUAL TAB
-- ══════════════════════════════════════════════════════════════════════════════
VisTab:AddSection("Rendering")

local perfStatsToggle = VisTab:AddToggle({
    Name     = "Perf Stats (HUD)",
    Flag     = "PerfStats",
    Default  = true,
    Callback = function(v)
        if v then PerfStats:Enable() else PerfStats:Disable() end
        N("Perf Stats", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("PerfStats", perfStatsToggle)

local espToggle = VisTab:AddToggle({
    Name     = "ESP",
    Flag     = "ESP",
    Default  = false,
    Callback = function(v)
        if v then ESP:Enable() else ESP:Disable() end
        N("ESP", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("ESP", espToggle)

local fullBrightToggle = VisTab:AddToggle({
    Name     = "FullBright",
    Flag     = "FullBright",
    Default  = false,
    Callback = function(v)
        if v then FullBright:Enable() else FullBright:Disable() end
        N("FullBright", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("FullBright", fullBrightToggle)

local removeFogToggle = VisTab:AddToggle({
    Name     = "Remove Fog",
    Flag     = "RemoveFog",
    Default  = false,
    Callback = function(v)
        if v then RemoveFog:Enable() else RemoveFog:Disable() end
        N("Remove Fog", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("RemoveFog", removeFogToggle)

VisTab:AddSection("ESP Settings")

local EC = {
    White  = Color3.fromRGB(255,255,255), Red    = Color3.fromRGB(255,60,60),
    Green  = Color3.fromRGB(60,220,80),   Blue   = Color3.fromRGB(60,130,255),
    Yellow = Color3.fromRGB(255,220,50),  Cyan   = Color3.fromRGB(60,220,255),
    Pink   = Color3.fromRGB(255,100,200)
}
VisTab:AddDropdown({
    Name     = "ESP Color",
    Flag     = "ESPColor",
    Options  = {"White","Red","Green","Blue","Yellow","Cyan","Pink"},
    Default  = "White",
    Callback = function(v) ESP:SetColor(EC[v] or Color3.new(1,1,1)) end
})
VisTab:AddSlider({
    Name     = "ESP Fill Opacity",
    Flag     = "ESPOpacity",
    Min      = 0,
    Max      = 100,
    Default  = 15,
    Callback = function(v) ESP:SetOpacity(v) end
})
VisTab:AddDropdown({
    Name     = "ESP Show Mode",
    Flag     = "ESPShowMode",
    Options  = {"Both","Body","Name"},
    Default  = "Both",
    Callback = function(v) ESP:SetShowMode(v) end
})

VisTab:AddSection("Tracer")

VisTab:AddToggle({
    Name     = "Player Tracer",
    Flag     = "Tracer",
    Default  = false,
    Callback = function(v)
        if v then Tracer:Enable() else Tracer:Disable() end
        N("Tracer", v and "Enabled" or "Disabled")
    end
})
local TC = {
    White  = Color3.fromRGB(255,255,255), Red    = Color3.fromRGB(255,60,60),
    Green  = Color3.fromRGB(60,220,80),   Blue   = Color3.fromRGB(60,130,255),
    Yellow = Color3.fromRGB(255,220,50),  Cyan   = Color3.fromRGB(60,220,255),
}
VisTab:AddDropdown({
    Name     = "Tracer Color",
    Flag     = "TracerColor",
    Options  = {"White","Red","Green","Blue","Yellow","Cyan"},
    Default  = "White",
    Callback = function(v) Tracer:SetColor(TC[v] or Color3.new(1,1,1)) end
})
VisTab:AddSlider({
    Name     = "Tracer Opacity",
    Flag     = "TracerOpacity",
    Min      = 0,
    Max      = 100,
    Default  = 100,
    Callback = function(v) Tracer:SetOpacity(v) end
})
VisTab:AddSlider({
    Name     = "Tracer Thickness",
    Flag     = "TracerThickness",
    Min      = 1,
    Max      = 8,
    Default  = 2,
    Callback = function(v) Tracer:SetThickness(v) end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER TAB
-- ══════════════════════════════════════════════════════════════════════════════
PlyTab:AddSection("Utility")

local antiAFKToggle = PlyTab:AddToggle({
    Name     = "Anti AFK",
    Flag     = "AntiAFK",
    Default  = false,
    Callback = function(v)
        if v then AntiAFK:Enable() else AntiAFK:Disable() end
        N("Anti AFK", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("AntiAFK", antiAFKToggle)

local infStaminaToggle = PlyTab:AddToggle({
    Name     = "Infinite Stamina",
    Flag     = "InfStamina",
    Default  = false,
    Callback = function(v)
        if v then InfStamina:Enable() else InfStamina:Disable() end
        N("Infinite Stamina", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("InfStamina", infStaminaToggle)

local godModeToggle = PlyTab:AddToggle({
    Name     = "God Mode",
    Flag     = "GodMode",
    Default  = false,
    Callback = function(v)
        if v then GodMode:Enable() else GodMode:Disable() end
        N("God Mode", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("GodMode", godModeToggle)

PlyTab:AddSection("Protection")

local noFallToggle = PlyTab:AddToggle({
    Name     = "No Fall Damage",
    Flag     = "NoFallDamage",
    Default  = false,
    Callback = function(v)
        if v then NoFallDmg:Enable() else NoFallDmg:Disable() end
        N("No Fall Damage", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("NoFallDamage", noFallToggle)

local antiFlingToggle = PlyTab:AddToggle({
    Name     = "Anti Fling",
    Flag     = "AntiFling",
    Default  = false,
    Callback = function(v)
        if v then AntiFling:Enable() else AntiFling:Disable() end
        N("Anti Fling", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("AntiFling", antiFlingToggle)

local flingThreshSlider = PlyTab:AddSlider({
    Name     = "Fling Threshold",
    Flag     = "FlingThreshold",
    Min      = 100,
    Max      = 1000,
    Default  = 200,
    Callback = function(v) AntiFling:SetThreshold(v) end
})
ConfigMgr:Register("FlingThreshold", flingThreshSlider)

PlyTab:AddSection("Combat")

local hitboxToggle = PlyTab:AddToggle({
    Name     = "Hitbox Expander",
    Flag     = "HitboxExpander",
    Default  = false,
    Callback = function(v)
        if v then HitboxExp:Enable() else HitboxExp:Disable() end
        N("Hitbox Expander", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("HitboxExpander", hitboxToggle)

local hitboxSizeSlider = PlyTab:AddSlider({
    Name     = "Hitbox Size",
    Flag     = "HitboxSize",
    Min      = 5,
    Max      = 30,
    Default  = 10,
    Callback = function(v) HitboxExp:SetSize(v) end
})
ConfigMgr:Register("HitboxSize", hitboxSizeSlider)

local hitboxAlphaSlider = PlyTab:AddSlider({
    Name     = "Hitbox Transparency",
    Flag     = "HitboxTransparency",
    Min      = 0,
    Max      = 100,
    Default  = 80,
    Callback = function(v) HitboxExp:SetTransparency(v) end
})
ConfigMgr:Register("HitboxTransparency", hitboxAlphaSlider)

local teamCheckToggle = PlyTab:AddToggle({
    Name     = "Team Check",
    Flag     = "TeamCheck",
    Default  = true,
    Callback = function(v)
        HitboxExp:SetTeamCheck(v)
        N("Team Check", v and "Skip teammates" or "Target all")
    end
})
ConfigMgr:Register("TeamCheck", teamCheckToggle)

PlyTab:AddSection("NPC")

local ikToggle = PlyTab:AddToggle({
    Name     = "Instant Kill NPC",
    Flag     = "InstantKill",
    Default  = false,
    Callback = function(v)
        if v then InstantKill:Enable() else InstantKill:Disable() end
        N("Instant Kill", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("InstantKill", ikToggle)

local ikModeDrop
ikModeDrop = PlyTab:AddDropdown({
    Name     = "Kill Mode",
    Flag     = "KillMode",
    Options  = {"All","Specific"},
    Default  = "All",
    Callback = function(v)
        InstantKill:SetMode(v)
        N("Kill Mode", v)
    end
})

local ikTargetIn = PlyTab:AddTextInput({
    Name        = "Target NPC Name",
    Flag        = "TargetNPC",
    Placeholder = "e.g. Zombie",
    Default     = "",
    Callback    = function(v) InstantKill:SetTarget(v) end
})

PlyTab:AddButton({
    Name     = "🐛 Enable Debug Mode",
    Callback = function()
        InstantKill:EnableDebug()
        N("InstantKill", "Debug on — check F9 console")
    end
})
PlyTab:AddButton({
    Name     = "📊 Show Kill Count",
    Callback = function()
        N("Kill Count", tostring(InstantKill:GetKillCount()).." NPCs")
    end
})

PlyTab:AddSection("Teleport")

PlyTab:AddButton({
    Name     = "📍 Copy My Position",
    Callback = function()
        local p = Teleport:SavePosition()
        if p then N("Teleport", ("Saved: %.0f, %.0f, %.0f"):format(p.X,p.Y,p.Z))
        else N("Teleport", "No character") end
    end
})
PlyTab:AddButton({
    Name     = "🚀 Go to Saved Position",
    Callback = function()
        if Teleport:GotoSaved(Fly) then N("Teleport", "Teleported")
        else N("Teleport", "No position saved") end
    end
})

-- Track selected player via Callback
local selectedPlayer = nil
local tpDrop = PlyTab:AddDropdown({
    Name     = "Select Player",
    Flag     = "TeleportPlayer",
    Options  = Teleport:GetPlayerList(),
    Default  = Teleport:GetPlayerList()[1] or "(no players)",
    Callback = function(v) selectedPlayer = v end
})
do local list = Teleport:GetPlayerList(); selectedPlayer = list[1] end

PlyTab:AddButton({
    Name     = "🔄 Refresh Players",
    Callback = function()
        local list = Teleport:GetPlayerList()
        tpDrop:SetOptions(list)
        selectedPlayer = list[1]
        N("Players", "Refreshed")
    end
})
PlyTab:AddButton({
    Name     = "⚡ Teleport to Player",
    Callback = function()
        local name = selectedPlayer
        if not name or name == "(no players)" then return end
        if Teleport:ToPlayer(name, Fly) then N("Teleport", "→ "..name)
        else N("Teleport", name.." not found") end
    end
})

PlyTab:AddSection("Waypoints")

local wpNameIn = PlyTab:AddTextInput({
    Name        = "Waypoint Name",
    Flag        = "WaypointName",
    Placeholder = "e.g. spawn",
    Default     = "",
    Callback    = function() end
})

-- Track selected waypoint via Callback
local selectedWaypoint = nil
local wpDrop

PlyTab:AddButton({
    Name     = "➕ Create Waypoint",
    Callback = function()
        local name = wpNameIn:Get() or ""
        if name == "" then N("Waypoint", "Enter a name"); return end
        if Waypoint:Exists(name) then N("Waypoint", name.." already exists"); return end
        if Waypoint:Create(name) then
            N("Waypoint", "Created: "..name)
            local list = Waypoint:GetList()
            wpDrop:SetOptions(list)
            selectedWaypoint = name
        else
            N("Waypoint", "Failed to create")
        end
    end
})

wpDrop = PlyTab:AddDropdown({
    Name     = "Select Waypoint",
    Flag     = "WaypointSelect",
    Options  = Waypoint:GetList(),
    Default  = Waypoint:GetList()[1] or "(no waypoints)",
    Callback = function(v) selectedWaypoint = v end
})
do local list = Waypoint:GetList(); selectedWaypoint = list[1] end

PlyTab:AddButton({
    Name     = "🔄 Refresh Waypoints",
    Callback = function()
        local list = Waypoint:GetList()
        wpDrop:SetOptions(list)
        selectedWaypoint = list[1]
        N("Waypoints", "Refreshed")
    end
})
PlyTab:AddButton({
    Name     = "📍 Teleport to Waypoint",
    Callback = function()
        local name = selectedWaypoint
        if not name or name == "(no waypoints)" then
            N("Waypoint", "Select a waypoint first"); return
        end
        if Waypoint:Teleport(name, Fly) then N("Waypoint", "→ "..name)
        else N("Waypoint", "Failed") end
    end
})
PlyTab:AddButton({
    Name     = "🗑 Delete Waypoint",
    Callback = function()
        local name = selectedWaypoint
        if not name or name == "(no waypoints)" then return end
        if Waypoint:Delete(name) then
            N("Waypoint", "Deleted: "..name)
            local list = Waypoint:GetList()
            wpDrop:SetOptions(list)
            selectedWaypoint = list[1]
        else
            N("Waypoint", "Failed to delete")
        end
    end
})

PlyTab:AddSection("Server")

PlyTab:AddButton({
    Name     = "Rejoin Server",
    Callback = function()
        N("Rejoin", "Rejoining...")
        task.wait(1.5)
        Rejoin:Execute()
    end
})
PlyTab:AddButton({
    Name     = "Copy Player ID",
    Callback = function()
        pcall(function() setclipboard(tostring(lp.UserId)) end)
        N("Player ID", tostring(lp.UserId))
    end
})

PlyTab:AddSection("Stats")
PlyTab:AddLabel({Text = "Username: " .. lp.Name})
PlyTab:AddLabel({Text = "User ID: " .. tostring(lp.UserId)})

-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ══════════════════════════════════════════════════════════════════════════════
SetTab:AddSection("Interface")

SetTab:AddKeybind({
    Name     = "Toggle UI Key",
    Flag     = "ToggleUIKey",
    Default  = Enum.KeyCode.O,
    Callback = function(k)
        Library:SetToggleKey(k)
        N("Toggle Key", k.Name)
    end
})
SetTab:AddDropdown({
    Name     = "Theme",
    Flag     = "Theme",
    Options  = {"Dark","Midnight","Rose","Emerald","Amber","Violet","Neon"},
    Default  = "Dark",
    Callback = function(v)
        Library:SetTheme(v)
        N("Theme", v)
    end
})

SetTab:AddSection("Config")

local cfgNameIn = SetTab:AddTextInput({
    Name        = "Config Name",
    Flag        = "ConfigName",
    Placeholder = "e.g. pvp",
    Default     = "default",
    Callback    = function() end
})

local function getCfgName()
    local v = cfgNameIn:Get()
    return (v and v ~= "") and v or "default"
end
local function getCfgList()
    local l = ConfigMgr:List()
    return #l > 0 and l or {"(none)"}
end

-- Track selected config via Callback
local selectedConfig = nil
local cfgDrop = SetTab:AddDropdown({
    Name     = "Select Config",
    Flag     = "ConfigSelect",
    Options  = getCfgList(),
    Default  = getCfgList()[1] or "(none)",
    Callback = function(v) selectedConfig = v end
})
do local list = getCfgList(); selectedConfig = list[1] end

SetTab:AddButton({
    Name     = "💾 Save",
    Callback = function()
        local n = getCfgName()
        local ok = ConfigMgr:Save(n)
        N("Config", ok and "Saved: "..n or "Save failed")
        if ok then
            local list = getCfgList()
            cfgDrop:SetOptions(list)
            selectedConfig = n
        end
    end
})
SetTab:AddButton({
    Name     = "📂 Load",
    Callback = function()
        local s = selectedConfig
        if not s or s == "(none)" then return end
        local ok = ConfigMgr:Load(s)
        N("Config", ok and "Loaded: "..s or "Load failed")
    end
})
SetTab:AddButton({
    Name     = "🗑 Delete",
    Callback = function()
        local s = selectedConfig
        if not s or s == "(none)" then return end
        ConfigMgr:Delete(s)
        N("Config", "Deleted: "..s)
        local list = getCfgList()
        cfgDrop:SetOptions(list)
        selectedConfig = list[1]
    end
})
SetTab:AddButton({
    Name     = "⭐ Set as Default",
    Callback = function()
        local s = selectedConfig
        if not s or s == "(none)" then return end
        local ok = ConfigMgr:SetDefault(s)
        N("Config", ok and s.." is default" or "Failed")
    end
})

SetTab:AddSection("About")
SetTab:AddLabel({Text = "Leon X v" .. CURRENT_VERSION .. " • by leonx24"})

-- ── Boot ──────────────────────────────────────────────────────────────────────
Library:SetSplashProgress(1.0)

PerfStats:Enable()
ConfigMgr:Init(Library)
ConfigMgr:AutoLoad()

-- Hide splash → reveals main UI with smooth transition
Library:HideSplash()

task.delay(1.5, function()
    N("Leon X", "Welcome!")
end)

