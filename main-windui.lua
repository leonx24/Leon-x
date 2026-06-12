-- Leon X | main-windui.lua
-- Wind UI version — mirrors main.lua feature set

local BASE = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"

local CURRENT_VERSION = "1.3"
pcall(function()
    CURRENT_VERSION = game:HttpGet(BASE.."version.txt?t="..os.time()):match("^%s*(.-)%s*$")
end)

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local lp      = Players.LocalPlayer

-- Load Wind UI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local cacheBust = "?t="..os.time()
local function load(p) return loadstring(game:HttpGet(BASE..p..cacheBust))() end

-- ── Loading notification (auto-dismiss) ───────────────────────────────────────
WindUI:Notify({ Title = "Leon X", Content = "Loading modules...", Duration = 8 })

-- ── Load modules ──────────────────────────────────────────────────────────────
local ConfigMgr   = load("modules/core/configmanager.lua")
local Fly         = load("modules/movements/fly.lua")
local Speed       = load("modules/movements/speed.lua")
local InfJump     = load("modules/movements/infinitejump.lua")
local Noclip      = load("modules/movements/noclip.lua")
local AntiRagdoll = load("modules/movements/antiragdoll.lua")
local Invisible   = load("modules/movements/invisible.lua")
local FreeCam     = load("modules/movements/freecam.lua")
local ClickTP     = load("modules/movements/clickteleport.lua")
local ESP         = load("modules/visuals/esp.lua")
local Tracer      = load("modules/visuals/tracer.lua")
local FullBright  = load("modules/visuals/fullbright.lua")
local PerfStats   = load("modules/visuals/perfstats.lua")
local RemoveFog   = load("modules/visuals/removefog.lua")
local AntiAFK     = load("modules/player/antiafk.lua")
local InfStamina  = load("modules/player/infinitestamina.lua")
local AntiFling   = load("modules/player/antifling.lua")
local Rejoin      = load("modules/player/rejoin.lua")
local Teleport    = load("modules/player/teleport.lua")
local HitboxExp   = load("modules/player/hitboxexpander.lua")
local Waypoint    = load("modules/player/waypoint.lua")
local GodMode     = load("modules/player/godmode.lua")
local NoFallDmg   = load("modules/player/nofalldamage.lua")
local InstantKill = load("modules/player/instantkill.lua")

Waypoint:Init()

-- ── Window ────────────────────────────────────────────────────────────────────
local Window = WindUI:CreateWindow({
    Title      = "Leon X v"..CURRENT_VERSION,
    Icon       = "zap",
    Author     = "by leonx24",
    Folder     = "Leon X",
    Size       = UDim2.new(0, 580, 0, 560),
    ToggleKey  = Enum.KeyCode.O,
    Transparent = true,
    Theme      = "Dark",
    NewElements = true,
})

-- Notification helper — simple title + state only
local function N(title, state, duration)
    WindUI:Notify({
        Title   = title,
        Content = state or "",
        Duration = duration or 2,
    })
end

ConfigMgr:Init(Window)

-- ── Tabs ──────────────────────────────────────────────────────────────────────
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
    Callback = function(v) Fly:SetSpeed(v) end
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

local speedToggle = MovTab:Toggle({
    Title    = "Speed Hack",
    Value    = false,
    Callback = function(v)
        Speed:SetWalkSpeed(v and 60 or 16)
        if v then Speed:Enable() else Speed:Disable() end
        N("Speed Hack", v and "Enabled" or "Disabled")
    end
})
ConfigMgr:Register("SpeedHack", speedToggle)
local walkSpeedSlider = MovTab:Slider({
    Title    = "Walk Speed",
    Value    = { Min = 16, Max = 250, Default = 16 },
    Step     = 1,
    Callback = function(v) Speed:SetWalkSpeed(v); Speed:Enable() end
})
ConfigMgr:Register("WalkSpeed", walkSpeedSlider)
local jumpPowerSlider = MovTab:Slider({
    Title    = "Jump Power",
    Value    = { Min = 50, Max = 500, Default = 50 },
    Step     = 1,
    Callback = function(v) Speed:SetJumpPower(v); Speed:Enable() end
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
VisTab:Dropdown({
    Title    = "ESP Color",
    Values   = {"White","Red","Green","Blue","Yellow","Cyan","Pink"},
    Value    = "White",
    Callback = function(v) ESP:SetColor(EC[v] or Color3.new(1,1,1)) end
})
VisTab:Slider({
    Title    = "ESP Fill Opacity",
    Value    = { Min = 0, Max = 100, Default = 15 },
    Step     = 1,
    Callback = function(v) ESP:SetOpacity(v) end
})
VisTab:Dropdown({
    Title    = "ESP Show Mode",
    Values   = {"Both","Body","Name"},
    Value    = "Both",
    Callback = function(v) ESP:SetShowMode(v) end
})

VisTab:Section({ Title = "Tracer" })

VisTab:Toggle({
    Title    = "Player Tracer",
    Value    = false,
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
VisTab:Dropdown({
    Title    = "Tracer Color",
    Values   = {"White","Red","Green","Blue","Yellow","Cyan"},
    Value    = "White",
    Callback = function(v) Tracer:SetColor(TC[v] or Color3.new(1,1,1)) end
})
VisTab:Slider({
    Title    = "Tracer Opacity",
    Value    = { Min = 0, Max = 100, Default = 100 },
    Step     = 1,
    Callback = function(v) Tracer:SetOpacity(v) end
})
VisTab:Slider({
    Title    = "Tracer Thickness",
    Value    = { Min = 1, Max = 8, Default = 2 },
    Step     = 1,
    Callback = function(v) Tracer:SetThickness(v) end
})

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
local ikTargetIn = PlyTab:Input({
    Title       = "Target NPC Name",
    Placeholder = "e.g. Zombie",
    Value       = "",
    Callback    = function(v) InstantKill:SetTarget(v) end
})
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

-- Track selected player via Callback (more reliable than .Value read on click)
local selectedPlayer = nil
local tpDrop = PlyTab:Dropdown({
    Title    = "Select Player",
    Values   = Teleport:GetPlayerList(),
    Value    = 1,
    Callback = function(v) selectedPlayer = v end
})
-- init with first value
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

-- Track selected waypoint via Callback
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
            -- auto-select the just-created waypoint
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
-- init
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
    Value    = "O",
    Callback = function(k)
        Window:SetToggleKey(Enum.KeyCode[k])
        N("Toggle Key", k)
    end
})
SetTab:Dropdown({
    Title    = "Theme",
    Values   = {"Dark","Light","Rose","Plant","Red","Indigo","Sky","Violet","Amber"},
    Value    = "Dark",
    Callback = function(v)
        Window:SetTheme(v)
        N("Theme", v)
    end
})

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

-- Track selected config via Callback
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

-- ── Boot ──────────────────────────────────────────────────────────────────────
PerfStats:Enable()
ConfigMgr:AutoLoad()
task.delay(1, function()
    N("Leon X", "Welcome!")
end)

