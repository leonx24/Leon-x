-- Leon X | main.lua v5.0
-- UI wiring only — all logic lives in module files

local BASE    = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local lp      = Players.LocalPlayer

local function load(p) return loadstring(game:HttpGet(BASE..p))() end

-- ── Splash shown immediately via library.lua ──────────────────────────────────
local Library   = load("ui/library.lua")
Library:SetSplashProgress(0.05)

local ConfigMgr = load("modules/core/configmanager.lua")
Library:SetSplashProgress(0.12)

local Fly         = load("modules/movements/fly.lua");         Library:SetSplashProgress(0.18)
local Speed       = load("modules/movements/speed.lua");       Library:SetSplashProgress(0.23)
local InfJump     = load("modules/movements/infinitejump.lua");Library:SetSplashProgress(0.28)
local Noclip      = load("modules/movements/noclip.lua");      Library:SetSplashProgress(0.33)
local AntiRagdoll = load("modules/movements/antiragdoll.lua"); Library:SetSplashProgress(0.38)
local Invisible   = load("modules/movements/invisible.lua");   Library:SetSplashProgress(0.42)
local FreeCam     = load("modules/movements/freecam.lua");     Library:SetSplashProgress(0.47)
local ESP         = load("modules/visuals/esp.lua");           Library:SetSplashProgress(0.53)
local Tracer      = load("modules/visuals/tracer.lua");        Library:SetSplashProgress(0.58)
local FullBright  = load("modules/visuals/fullbright.lua");    Library:SetSplashProgress(0.62)
local PerfStats   = load("modules/visuals/perfstats.lua");     Library:SetSplashProgress(0.67)
local AntiAFK     = load("modules/player/antiafk.lua");        Library:SetSplashProgress(0.72)
local AntiFling   = load("modules/player/antifling.lua");      Library:SetSplashProgress(0.77)
local Rejoin      = load("modules/player/rejoin.lua");         Library:SetSplashProgress(0.82)
local Teleport    = load("modules/player/teleport.lua");       Library:SetSplashProgress(0.87)
local GodMode     = load("modules/player/godmode.lua");        Library:SetSplashProgress(0.93)

ConfigMgr:Init(Library)

local function N(t,m,k,d) Library:Notify({Title=t,Text=m,Type=k or "info",Duration=d or 2}) end

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local Mov = Library:CreateTab("Movement")
local Vis = Library:CreateTab("Visual")
local Ply = Library:CreateTab("Player")
local Set = Library:CreateTab("Settings")

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT
-- ══════════════════════════════════════════════════════════════════════════════
Mov:AddSection("Locomotion")

local flyToggle = Mov:AddToggle({ Name="Fly", Flag="Fly", Default=false,
    Callback=function(v) if v then Fly:Enable() else Fly:Disable() end
        N("Fly", v and "Enabled" or "Disabled", v and "success" or "info") end })

Mov:AddSlider({ Name="Fly Speed", Flag="FlySpeed", Min=10, Max=300, Default=60, Suffix=" stud/s",
    Callback=function(v) Fly:SetSpeed(v) end })

local flyKey = Enum.KeyCode.F
UIS.InputBegan:Connect(function(i,gp)
    if gp or i.KeyCode~=flyKey then return end
    local s=not Fly.Enabled; flyToggle:Set(s)
    if s then Fly:Enable() else Fly:Disable() end
end)

Mov:AddKeybind({ Name="Fly Keybind", Flag="FlyKeybind", Default=Enum.KeyCode.F,
    Callback=function(k) flyKey=k; N("Fly Keybind","Set to "..k.Name) end })

Mov:AddToggle({ Name="Speed Hack", Flag="SpeedHack", Default=false,
    Callback=function(v) Speed:SetWalkSpeed(v and 60 or 16); if v then Speed:Enable() else Speed:Disable() end
        N("Speed Hack", v and "Enabled (60)" or "Disabled", v and "success" or "info") end })

Mov:AddSlider({ Name="Walk Speed", Flag="WalkSpeed", Min=16, Max=250, Default=16, Suffix=" stud/s",
    Callback=function(v) Speed:SetWalkSpeed(v); Speed:Enable() end })

Mov:AddSlider({ Name="Jump Power", Flag="JumpPower", Min=50, Max=500, Default=50,
    Callback=function(v) Speed:SetJumpPower(v); Speed:Enable() end })

Mov:AddSection("Misc")

Mov:AddToggle({ Name="Infinite Jump", Flag="InfiniteJump", Default=false,
    Callback=function(v) if v then InfJump:Enable() else InfJump:Disable() end
        N("Infinite Jump", v and "Enabled" or "Disabled", v and "success" or "info") end })

Mov:AddToggle({ Name="Noclip", Flag="Noclip", Default=false,
    Callback=function(v) if v then Noclip:Enable() else Noclip:Disable() end
        N("Noclip", v and "Enabled" or "Disabled", v and "success" or "info") end })

Mov:AddToggle({ Name="Anti Ragdoll", Flag="AntiRagdoll", Default=false,
    Callback=function(v) if v then AntiRagdoll:Enable() else AntiRagdoll:Disable() end
        N("Anti Ragdoll", v and "Enabled" or "Disabled", v and "success" or "info") end })

Mov:AddToggle({ Name="Invisible (local)", Flag="Invisible", Default=false,
    Callback=function(v) if v then Invisible:Enable() else Invisible:Disable() end
        N("Invisible", v and "Enabled" or "Disabled", v and "success" or "info") end })

Mov:AddSection("Camera")

local fcKey = Enum.KeyCode.V
local fcToggle = Mov:AddToggle({ Name="Free Cam", Flag="FreeCam", Default=false,
    Callback=function(v)
        if v then FreeCam:Enable() else FreeCam:Disable() end
        N("Free Cam", v and "Enabled" or "Disabled", v and "success" or "info")
    end })

Mov:AddSlider({ Name="Free Cam Speed", Flag="FreeCamSpeed", Min=5, Max=300, Default=40, Suffix=" stud/s",
    Callback=function(v) FreeCam:SetSpeed(v) end })

Mov:AddKeybind({ Name="FreeCam Keybind", Flag="FreeCamKeybind", Default=Enum.KeyCode.V,
    Callback=function(k) fcKey = k; N("FreeCam Keybind", "Set to "..k.Name) end })

UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= fcKey then return end
    local s = not FreeCam.Enabled
    fcToggle:Set(s)
    if s then FreeCam:Enable() else FreeCam:Disable() end
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUAL
-- ══════════════════════════════════════════════════════════════════════════════
Vis:AddSection("Rendering")

Vis:AddToggle({ Name="Perf Stats (HUD)", Flag="PerfStats", Default=true,
    Callback=function(v) if v then PerfStats:Enable() else PerfStats:Disable() end
        N("Perf Stats", v and "Enabled" or "Disabled", v and "success" or "info") end })

Vis:AddToggle({ Name="ESP", Flag="ESP", Default=false,
    Callback=function(v) if v then ESP:Enable() else ESP:Disable() end
        N("ESP", v and "Enabled" or "Disabled", v and "success" or "info") end })

Vis:AddToggle({ Name="FullBright", Flag="FullBright", Default=false,
    Callback=function(v) if v then FullBright:Enable() else FullBright:Disable() end
        N("FullBright", v and "Enabled" or "Disabled", v and "success" or "info") end })

Vis:AddSection("Appearance")

local EC = { White=Color3.fromRGB(255,255,255), Red=Color3.fromRGB(255,60,60),
             Green=Color3.fromRGB(60,220,80),   Blue=Color3.fromRGB(60,130,255),
             Yellow=Color3.fromRGB(255,220,50), Cyan=Color3.fromRGB(60,220,255),
             Pink=Color3.fromRGB(255,100,200) }

Vis:AddDropdown({ Name="ESP Color", Flag="ESPColor",
    Options={"White","Red","Green","Blue","Yellow","Cyan","Pink"}, Default="White",
    Callback=function(v) ESP:SetColor(EC[v] or Color3.new(1,1,1)) end })

Vis:AddSlider({ Name="ESP Fill Opacity", Flag="ESPOpacity", Min=0, Max=100, Default=15, Suffix="%",
    Callback=function(v) ESP:SetOpacity(v) end })

Vis:AddDropdown({ Name="ESP Show Mode", Flag="ESPMode",
    Options={"Both","Body","Name"}, Default="Both",
    Callback=function(v) ESP:SetShowMode(v) end })

Vis:AddSection("Tracer")

Vis:AddToggle({ Name="Player Tracer", Flag="Tracer", Default=false,
    Callback=function(v) if v then Tracer:Enable() else Tracer:Disable() end
        N("Tracer", v and "Enabled" or "Disabled", v and "success" or "info") end })

local TC = { White=Color3.fromRGB(255,255,255), Red=Color3.fromRGB(255,60,60),
             Green=Color3.fromRGB(60,220,80),   Blue=Color3.fromRGB(60,130,255),
             Yellow=Color3.fromRGB(255,220,50), Cyan=Color3.fromRGB(60,220,255) }

Vis:AddDropdown({ Name="Tracer Color", Flag="TracerColor",
    Options={"White","Red","Green","Blue","Yellow","Cyan"}, Default="White",
    Callback=function(v) Tracer:SetColor(TC[v] or Color3.new(1,1,1)) end })

Vis:AddSlider({ Name="Tracer Opacity", Flag="TracerOpacity", Min=0, Max=100, Default=100, Suffix="%",
    Callback=function(v) Tracer:SetOpacity(v) end })

Vis:AddSlider({ Name="Tracer Thickness", Flag="TracerThickness", Min=1, Max=8, Default=2,
    Callback=function(v) Tracer:SetThickness(v) end })

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER
-- ══════════════════════════════════════════════════════════════════════════════
Ply:AddSection("Utility")

Ply:AddToggle({ Name="Anti AFK", Flag="AntiAFK", Default=false,
    Callback=function(v) if v then AntiAFK:Enable() else AntiAFK:Disable() end
        N("Anti AFK", v and "Enabled" or "Disabled", v and "success" or "info") end })

Ply:AddToggle({ Name="God Mode", Flag="GodMode", Default=false,
    Callback=function(v) if v then GodMode:Enable() else GodMode:Disable() end
        N("God Mode", v and "Enabled" or "Disabled", v and "success" or "info") end })

Ply:AddSection("Protection")

Ply:AddToggle({ Name="Anti Fling", Flag="AntiFling", Default=false,
    Callback=function(v) if v then AntiFling:Enable() else AntiFling:Disable() end
        N("Anti Fling", v and "Enabled" or "Disabled", v and "success" or "info") end })

Ply:AddSlider({ Name="Fling Threshold", Flag="FlingThreshold", Min=100, Max=1000, Default=200, Suffix=" stud/s",
    Callback=function(v) AntiFling:SetThreshold(v) end })

Ply:AddSection("Teleport")

Ply:AddButton({ Name="📍  Copy My Position", Callback=function()
    local p = Teleport:SavePosition()
    if p then N("Teleport",("Saved: %.0f, %.0f, %.0f"):format(p.X,p.Y,p.Z),"success",3)
    else N("Teleport","No character","error",3) end
end })

Ply:AddButton({ Name="🚀  Go to Saved Position", Callback=function()
    if Teleport:GotoSaved(Fly) then N("Teleport","Teleported","success")
    else N("Teleport","No position saved","warn",3) end
end })

local tpDrop = Ply:AddDropdown({ Name="Select Player",
    Options=Teleport:GetPlayerList(), Default=Teleport:GetPlayerList()[1] })

Ply:AddButton({ Name="🔄  Refresh", Callback=function()
    tpDrop:SetOptions(Teleport:GetPlayerList()); N("Teleport","Refreshed") end })

Ply:AddButton({ Name="⚡  Teleport to Player", Callback=function()
    local name = tpDrop:Get()
    if name=="(no players)" then return end
    if Teleport:ToPlayer(name, Fly) then N("Teleport","→ "..name,"success")
    else N("Teleport",name.." not found","error",3) end
end })

Ply:AddSection("Server")

Ply:AddButton({ Name="Rejoin Server", Callback=function()
    N("Rejoin","Rejoining...","warn"); task.wait(1.5); Rejoin:Execute() end })

Ply:AddButton({ Name="Copy Player ID", Callback=function()
    pcall(function() setclipboard(tostring(lp.UserId)) end)
    N("Copied","ID: "..lp.UserId,"success") end })

Ply:AddSection("Stats")
Ply:AddLabel({ Text="Username: "..lp.Name,             Color=Color3.fromRGB(100,100,100) })
Ply:AddLabel({ Text="User ID: " ..tostring(lp.UserId), Color=Color3.fromRGB(100,100,100) })

-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS
-- ══════════════════════════════════════════════════════════════════════════════
Set:AddSection("Interface")

Set:AddDropdown({ Name="Theme", Flag="Theme",
    Options={"Dark","Midnight","Rose","Emerald","Amber","Violet"}, Default="Dark",
    Callback=function(v) Library:SetTheme(v); N("Theme",v.." applied","success") end })

Set:AddToggle({ Name="Show Notifications", Flag="ShowNotifs", Default=true,
    Callback=function(v) Library:Notify({Title="Notifications",
        Text=v and "Enabled" or "Disabled", Type=v and "success" or "info", Duration=2}) end })

Set:AddSection("Config")

local nameIn = Set:AddTextInput({ Name="Config Name", Placeholder="e.g. pvp", Default="default", Callback=function()end })
local function cfgName() local v=nameIn:Get(); return (v and v~="") and v or "default" end
local function cfgList() local l=ConfigMgr:List(); return #l>0 and l or {"(none)"} end

local cfgDrop = Set:AddDropdown({ Name="Select Config", Options=cfgList(), Default=ConfigMgr:List()[1] or "(none)" })

Set:AddButton({ Name="💾  Save", Callback=function()
    local n=cfgName(); local ok=ConfigMgr:Save(n)
    N("Config", ok and "Saved: "..n or "Save failed", ok and "success" or "error",3)
    cfgDrop:SetOptions(cfgList()); if ok then cfgDrop:Set(n) end end })

Set:AddButton({ Name="📂  Load", Callback=function()
    local s=cfgDrop:Get(); if s=="(none)" then return end
    local ok=ConfigMgr:Load(s)
    N("Config", ok and "Loaded: "..s or "Load failed", ok and "success" or "error",3) end })

Set:AddButton({ Name="🗑  Delete", Callback=function()
    local s=cfgDrop:Get(); if s=="(none)" then return end
    ConfigMgr:Delete(s); N("Config","Deleted: "..s,"info",3); cfgDrop:SetOptions(cfgList()) end })

Set:AddButton({ Name="⭐  Set as Default", Callback=function()
    local s=cfgDrop:Get(); if s=="(none)" then return end
    local ok=ConfigMgr:SetDefault(s)
    N("Config", ok and s.." is default" or "Failed", ok and "success" or "error",3) end })

Set:AddSection("About")
Set:AddLabel({ Text="Leon X  ·  v5.0", Color=Color3.fromRGB(70,70,70), Align=Enum.TextXAlignment.Center })

-- ── Boot ──────────────────────────────────────────────────────────────────────
ConfigMgr:AutoLoad()
Library:SetSplashProgress(1)
Library:HideSplash()
PerfStats:Enable()
task.delay(1, function() N("Leon X","Welcome!","success",3) end)
