-- Leon X | main.lua v2.0
-- UI: ui/library.lua Noir v4
-- API: Library:CreateWindow → win:Tab → tab:Toggle / tab:Slider etc.

local BASE    = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local lp      = Players.LocalPlayer

local function load(p)
    return loadstring(game:HttpGet(BASE..p.."?t="..os.time()))()
end

-- ── UI Library ────────────────────────────────────────────────────────────────
local Library = load("ui/library.lua")

-- ── Module loader (silent fail → stub) ───────────────────────────────────────
local DUMMY = setmetatable({Enabled=false,Name="Dummy"},{
    __index = function() return function() end end
})
local function safeLoad(p)
    local ok, r = pcall(function()
        local src = game:HttpGet(BASE..p.."?t="..os.time())
        if not src or #src < 5 then error("empty") end
        local fn, e = loadstring(src)
        if not fn then error(e) end
        return fn()
    end)
    if not ok then warn("[LeonX] failed: "..p.." — "..tostring(r)); return DUMMY end
    return r or DUMMY
end

-- ── Modules ───────────────────────────────────────────────────────────────────
local Fly         = safeLoad("modules/movements/fly.lua")
local Speed       = safeLoad("modules/movements/speed.lua")
local InfJump     = safeLoad("modules/movements/infinitejump.lua")
local Noclip      = safeLoad("modules/movements/noclip.lua")
local AntiRagdoll = safeLoad("modules/movements/antiragdoll.lua")
local Invisible   = safeLoad("modules/movements/invisible.lua")
local FreeCam     = safeLoad("modules/movements/freecam.lua")
local ClickTP     = safeLoad("modules/movements/clickteleport.lua")
local ESP         = safeLoad("modules/visuals/esp.lua")
local Tracer      = safeLoad("modules/visuals/tracer.lua")
local FullBright  = safeLoad("modules/visuals/fullbright.lua")
local PerfStats   = safeLoad("modules/visuals/perfstats.lua")
local RemoveFog   = safeLoad("modules/visuals/removefog.lua")
local AntiAFK     = safeLoad("modules/player/antiafk.lua")
local InfStamina  = safeLoad("modules/player/infinitestamina.lua")
local AntiFling   = safeLoad("modules/player/antifling.lua")
local Rejoin      = safeLoad("modules/player/rejoin.lua")
local Teleport    = safeLoad("modules/player/teleport.lua")
local GodMode     = safeLoad("modules/player/godmode.lua")
local NoFallDmg   = safeLoad("modules/player/nofalldamage.lua")
local ConfigMgr   = safeLoad("modules/core/configmanager.lua")

-- ── Window ────────────────────────────────────────────────────────────────────
local win = Library:CreateWindow({
    Title     = "Leon X",
    Author    = "v2.0",
    Size      = UDim2.new(0, 660, 0, 460),
    ToggleKey = Enum.KeyCode.O,
    Theme     = "Default",
})

-- ── Notification helper ───────────────────────────────────────────────────────
local function N(title, text, duration)
    Library:Notify({ Title=title, Content=text or "", Duration=duration or 2 })
end

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local Mov = win:Tab({ Title="Movement", Icon="🏃" })
local Vis = win:Tab({ Title="Visual",   Icon="👁" })
local Ply = win:Tab({ Title="Player",   Icon="👤" })
local Set = win:Tab({ Title="Settings", Icon="⚙" })

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT
-- ══════════════════════════════════════════════════════════════════════════════
Mov:Section({ Title="Locomotion" })

local flyToggle = Mov:Toggle({ Title="Fly", Value=false,
    Callback=function(v)
        if v then Fly:Enable() else Fly:Disable() end
        N("Fly", v and "Enabled" or "Disabled")
    end })

Mov:Slider({ Title="Fly Speed", Value={ Min=10, Max=300, Default=60 },
    Callback=function(v) Fly:SetSpeed(v) end })

local flyKey = Enum.KeyCode.F
Mov:Keybind({ Title="Fly Keybind", Value="F",
    Callback=function(k)
        flyKey = Enum.KeyCode[k] or Enum.KeyCode.F
        N("Fly Keybind", "Set to "..k)
    end })
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= flyKey then return end
    local s = not Fly.Enabled; flyToggle:Set(s)
    if s then Fly:Enable() else Fly:Disable() end
end)

Mov:Toggle({ Title="Speed Hack", Value=false,
    Callback=function(v)
        Speed:SetWalkSpeed(v and 60 or 16)
        if v then Speed:Enable() else Speed:Disable() end
        N("Speed Hack", v and "Enabled" or "Disabled")
    end })

Mov:Slider({ Title="Walk Speed", Value={ Min=16, Max=250, Default=16 },
    Callback=function(v) Speed:SetWalkSpeed(v); Speed:Enable() end })

Mov:Slider({ Title="Jump Power", Value={ Min=50, Max=500, Default=50 },
    Callback=function(v) Speed:SetJumpPower(v); Speed:Enable() end })

Mov:Section({ Title="Misc" })

Mov:Toggle({ Title="Infinite Jump", Value=false,
    Callback=function(v)
        if v then InfJump:Enable() else InfJump:Disable() end
        N("Infinite Jump", v and "Enabled" or "Disabled")
    end })

Mov:Toggle({ Title="Noclip", Value=false,
    Callback=function(v)
        if v then Noclip:Enable() else Noclip:Disable() end
        N("Noclip", v and "Enabled" or "Disabled")
    end })

Mov:Toggle({ Title="Anti Ragdoll", Value=false,
    Callback=function(v)
        if v then AntiRagdoll:Enable() else AntiRagdoll:Disable() end
        N("Anti Ragdoll", v and "Enabled" or "Disabled")
    end })

Mov:Toggle({ Title="Invisible (local)", Value=false,
    Callback=function(v)
        if v then Invisible:Enable() else Invisible:Disable() end
        N("Invisible", v and "Enabled" or "Disabled")
    end })

Mov:Section({ Title="Camera" })

local fcKey = Enum.KeyCode.V
local fcToggle = Mov:Toggle({ Title="Free Cam", Value=false,
    Callback=function(v)
        if v then FreeCam:Enable() else FreeCam:Disable() end
        N("Free Cam", v and "Enabled" or "Disabled")
    end })

Mov:Slider({ Title="Free Cam Speed", Value={ Min=5, Max=300, Default=40 },
    Callback=function(v) FreeCam:SetSpeed(v) end })

Mov:Keybind({ Title="FreeCam Keybind", Value="V",
    Callback=function(k)
        fcKey = Enum.KeyCode[k] or Enum.KeyCode.V
        N("FreeCam Keybind", "Set to "..k)
    end })
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= fcKey then return end
    local s = not FreeCam.Enabled; fcToggle:Set(s)
    if s then FreeCam:Enable() else FreeCam:Disable() end
end)

Mov:Section({ Title="Click Teleport" })

Mov:Toggle({ Title="Click Teleport", Value=false,
    Callback=function(v)
        if v then ClickTP:Enable() else ClickTP:Disable() end
        N("Click Teleport", v and (UIS.TouchEnabled and "Enabled — tap to tp" or "Enabled — click to tp") or "Disabled")
    end })

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUAL
-- ══════════════════════════════════════════════════════════════════════════════
Vis:Section({ Title="Rendering" })

Vis:Toggle({ Title="Perf Stats (HUD)", Value=true,
    Callback=function(v)
        if v then PerfStats:Enable() else PerfStats:Disable() end
        N("Perf Stats", v and "Enabled" or "Disabled")
    end })

Vis:Toggle({ Title="ESP", Value=false,
    Callback=function(v)
        if v then ESP:Enable() else ESP:Disable() end
        N("ESP", v and "Enabled" or "Disabled")
    end })

Vis:Toggle({ Title="FullBright", Value=false,
    Callback=function(v)
        if v then FullBright:Enable() else FullBright:Disable() end
        N("FullBright", v and "Enabled" or "Disabled")
    end })

Vis:Toggle({ Title="Remove Fog", Value=false,
    Callback=function(v)
        if v then RemoveFog:Enable() else RemoveFog:Disable() end
        N("Remove Fog", v and "Enabled" or "Disabled")
    end })

Vis:Section({ Title="ESP Options" })

local EC = {
    White=Color3.fromRGB(255,255,255), Red=Color3.fromRGB(255,60,60),
    Green=Color3.fromRGB(60,220,80),   Blue=Color3.fromRGB(60,130,255),
    Yellow=Color3.fromRGB(255,220,50), Cyan=Color3.fromRGB(60,220,255),
    Pink=Color3.fromRGB(255,100,200),
}
Vis:Dropdown({ Title="ESP Color", Values={"White","Red","Green","Blue","Yellow","Cyan","Pink"}, Value=1,
    Callback=function(v) ESP:SetColor(EC[v] or Color3.new(1,1,1)) end })

Vis:Slider({ Title="ESP Fill Opacity", Value={ Min=0, Max=100, Default=15 },
    Callback=function(v) ESP:SetOpacity(v) end })

Vis:Dropdown({ Title="ESP Show Mode", Values={"Both","Body","Name"}, Value=1,
    Callback=function(v) ESP:SetShowMode(v) end })

Vis:Section({ Title="Tracer" })

Vis:Toggle({ Title="Player Tracer", Value=false,
    Callback=function(v)
        if v then Tracer:Enable() else Tracer:Disable() end
        N("Tracer", v and "Enabled" or "Disabled")
    end })

local TC = {
    White=Color3.fromRGB(255,255,255), Red=Color3.fromRGB(255,60,60),
    Green=Color3.fromRGB(60,220,80),   Blue=Color3.fromRGB(60,130,255),
    Yellow=Color3.fromRGB(255,220,50), Cyan=Color3.fromRGB(60,220,255),
}
Vis:Dropdown({ Title="Tracer Color", Values={"White","Red","Green","Blue","Yellow","Cyan"}, Value=1,
    Callback=function(v) Tracer:SetColor(TC[v] or Color3.new(1,1,1)) end })

Vis:Slider({ Title="Tracer Opacity", Value={ Min=0, Max=100, Default=100 },
    Callback=function(v) Tracer:SetOpacity(v) end })

Vis:Slider({ Title="Tracer Thickness", Value={ Min=1, Max=8, Default=2 },
    Callback=function(v) Tracer:SetThickness(v) end })

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER
-- ══════════════════════════════════════════════════════════════════════════════
Ply:Section({ Title="Utility" })

Ply:Toggle({ Title="Anti AFK", Value=false,
    Callback=function(v)
        if v then AntiAFK:Enable() else AntiAFK:Disable() end
        N("Anti AFK", v and "Enabled" or "Disabled")
    end })

Ply:Toggle({ Title="Infinite Stamina", Value=false,
    Callback=function(v)
        if v then InfStamina:Enable() else InfStamina:Disable() end
        N("Infinite Stamina", v and "Enabled" or "Disabled")
    end })

Ply:Toggle({ Title="God Mode", Value=false,
    Callback=function(v)
        if v then GodMode:Enable() else GodMode:Disable() end
        N("God Mode", v and "Enabled" or "Disabled")
    end })

Ply:Section({ Title="Protection" })

Ply:Toggle({ Title="No Fall Damage", Value=false,
    Callback=function(v)
        if v then NoFallDmg:Enable() else NoFallDmg:Disable() end
        N("No Fall Damage", v and "Enabled" or "Disabled")
    end })

Ply:Toggle({ Title="Anti Fling", Value=false,
    Callback=function(v)
        if v then AntiFling:Enable() else AntiFling:Disable() end
        N("Anti Fling", v and "Enabled" or "Disabled")
    end })

Ply:Slider({ Title="Fling Threshold", Value={ Min=100, Max=1000, Default=200 },
    Callback=function(v) AntiFling:SetThreshold(v) end })

Ply:Section({ Title="Teleport" })

Ply:Button({ Title="📍  Copy My Position",
    Callback=function()
        local p = Teleport:SavePosition()
        if p then N("Teleport", ("Saved: %.0f, %.0f, %.0f"):format(p.X,p.Y,p.Z), 3)
        else N("Teleport", "No character", 3) end
    end })

Ply:Button({ Title="🚀  Go to Saved Position",
    Callback=function()
        if Teleport:GotoSaved(Fly) then N("Teleport", "Teleported")
        else N("Teleport", "No position saved", 3) end
    end })

local tpDrop = Ply:Dropdown({ Title="Select Player",
    Values=Teleport:GetPlayerList(), Value=1 })

Ply:Button({ Title="🔄  Refresh Players",
    Callback=function()
        local list = Teleport:GetPlayerList()
        tpDrop:Refresh(list)
        N("Teleport", "Refreshed")
    end })

Ply:Button({ Title="⚡  Teleport to Player",
    Callback=function()
        local name = tpDrop.Value
        if not name or name == "(no players)" then return end
        if Teleport:ToPlayer(name, Fly) then N("Teleport", "→ "..name)
        else N("Teleport", name.." not found", 3) end
    end })

Ply:Section({ Title="Server" })

Ply:Button({ Title="Rejoin Server",
    Callback=function()
        N("Rejoin", "Rejoining...")
        task.wait(1.5); Rejoin:Execute()
    end })

Ply:Button({ Title="Copy Player ID",
    Callback=function()
        pcall(function() setclipboard(tostring(lp.UserId)) end)
        N("Copied", "ID: "..lp.UserId)
    end })

Ply:Section({ Title="Stats" })
Ply:Paragraph({ Title="Username", Content=lp.Name })
Ply:Paragraph({ Title="User ID",  Content=tostring(lp.UserId) })

-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS
-- ══════════════════════════════════════════════════════════════════════════════
Set:Section({ Title="Interface" })

Set:Keybind({ Title="Toggle UI Key", Value="O",
    Callback=function(k)
        win:SetToggleKey(Enum.KeyCode[k] or Enum.KeyCode.O)
        N("Toggle Key", "Set to "..k)
    end })

Set:Dropdown({ Title="Theme",
    Values={"Default","Gold","Emerald","Rose","Violet","Amber","Neon"}, Value=1,
    Callback=function(v)
        win:SetTheme(v)
        N("Theme", v.." applied")
    end })

Set:Section({ Title="Config" })

local nameIn = Set:Input({ Title="Config Name", Placeholder="e.g. pvp", Value="default",
    Callback=function() end })

local function cfgName()
    return (nameIn and nameIn.Value and nameIn.Value ~= "") and nameIn.Value or "default"
end
local function cfgList()
    local ok, l = pcall(function() return ConfigMgr:List() end)
    if ok and l and #l > 0 then return l end
    return {"(none)"}
end

local cfgDrop = Set:Dropdown({ Title="Select Config", Values=cfgList(), Value=1 })

Set:Button({ Title="💾  Save",
    Callback=function()
        local n = cfgName()
        local ok = pcall(function() ConfigMgr:Save(n) end)
        N("Config", ok and "Saved: "..n or "Save failed", 3)
        local l = cfgList(); cfgDrop:Refresh(l)
    end })

Set:Button({ Title="📂  Load",
    Callback=function()
        local s = cfgDrop.Value
        if not s or s == "(none)" then return end
        local ok = pcall(function() ConfigMgr:Load(s) end)
        N("Config", ok and "Loaded: "..s or "Load failed", 3)
    end })

Set:Button({ Title="🗑  Delete",
    Callback=function()
        local s = cfgDrop.Value
        if not s or s == "(none)" then return end
        pcall(function() ConfigMgr:Delete(s) end)
        N("Config", "Deleted: "..s, 3)
        local l = cfgList(); cfgDrop:Refresh(l)
    end })

Set:Section({ Title="About" })
Set:Paragraph({ Title="Leon X", Content="v2.0  ·  by leonx24" })

-- ── Boot ──────────────────────────────────────────────────────────────────────
pcall(function() ConfigMgr:Init(win) end)
pcall(function() ConfigMgr:AutoLoad() end)
PerfStats:Enable()
task.delay(1, function() N("Leon X", "Welcome!") end)
