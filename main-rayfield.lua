-- Leon X | main.lua (Rayfield UI version)
-- UI wiring with Rayfield library

local BASE = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"

-- Fetch current version from version.txt
local CURRENT_VERSION = "1.0"
pcall(function()
    CURRENT_VERSION = game:HttpGet(BASE.."version.txt?t="..os.time()):match("^%s*(.-)%s*$")
end)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Cache buster to force fresh loads
local cacheBust = "?t="..os.time()
local function load(p) return loadstring(game:HttpGet(BASE..p..cacheBust))() end

-- Create Window
local Window = Rayfield:CreateWindow({
   Name = "Leon X v"..CURRENT_VERSION,
   LoadingTitle = "Leon X",
   LoadingSubtitle = "by leonx24",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "LeonX",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "",
      RememberJoins = false
   },
   KeySystem = false,
})

-- Notification helper
local function N(title, message)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = 2,
        Image = 4483362458,
    })
end

-- Load all modules
N("Leon X", "Loading modules...")

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
local MovTab = Window:CreateTab("Movement 🏃", 4483362458)
local VisTab = Window:CreateTab("Visual 👁", 4483362458)
local PlyTab = Window:CreateTab("Player 👤", 4483362458)
local SetTab = Window:CreateTab("Settings ⚙", 4483362458)

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ══════════════════════════════════════════════════════════════════════════════
MovTab:CreateSection("Locomotion")

local flyToggle = MovTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v)
        if v then Fly:Enable() else Fly:Disable() end
        N("Fly", v and "Enabled" or "Disabled")
    end,
})

MovTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    Suffix = " stud/s",
    CurrentValue = 60,
    Flag = "FlySpeed",
    Callback = function(v)
        Fly:SetSpeed(v)
    end,
})

local flyKey = Enum.KeyCode.F
MovTab:CreateKeybind({
    Name = "Fly Keybind",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Flag = "FlyKeybind",
    Callback = function(k)
        -- Rayfield keybind returns string, convert to KeyCode
        local keyName = tostring(k):upper()
        if Enum.KeyCode[keyName] then
            flyKey = Enum.KeyCode[keyName]
            N("Fly Keybind", "Set to "..keyName)
        end
    end,
})

UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= flyKey then return end
    local s = not Fly.Enabled
    flyToggle:Set(s)
    if s then Fly:Enable() else Fly:Disable() end
end)

MovTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(v)
        Speed:SetWalkSpeed(v and 60 or 16)
        if v then Speed:Enable() else Speed:Disable() end
        N("Speed Hack", v and "Enabled (60)" or "Disabled")
    end,
})

MovTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 250},
    Increment = 1,
    Suffix = " stud/s",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        Speed:SetWalkSpeed(v)
        Speed:Enable()
    end,
})

MovTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        Speed:SetJumpPower(v)
        Speed:Enable()
    end,
})

MovTab:CreateSection("Misc")

MovTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(v)
        if v then InfJump:Enable() else InfJump:Disable() end
        N("Infinite Jump", v and "Enabled" or "Disabled")
    end,
})

MovTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        if v then Noclip:Enable() else Noclip:Disable() end
        N("Noclip", v and "Enabled" or "Disabled")
    end,
})

MovTab:CreateToggle({
    Name = "Anti Ragdoll",
    CurrentValue = false,
    Flag = "AntiRagdoll",
    Callback = function(v)
        if v then AntiRagdoll:Enable() else AntiRagdoll:Disable() end
        N("Anti Ragdoll", v and "Enabled" or "Disabled")
    end,
})

MovTab:CreateToggle({
    Name = "Invisible (local)",
    CurrentValue = false,
    Flag = "Invisible",
    Callback = function(v)
        if v then Invisible:Enable() else Invisible:Disable() end
        N("Invisible", v and "Enabled" or "Disabled")
    end,
})

MovTab:CreateSection("Camera")

local fcKey = Enum.KeyCode.V
local fcToggle = MovTab:CreateToggle({
    Name = "Free Cam",
    CurrentValue = false,
    Flag = "FreeCam",
    Callback = function(v)
        if v then FreeCam:Enable() else FreeCam:Disable() end
        N("Free Cam", v and "Enabled" or "Disabled")
    end,
})

MovTab:CreateSlider({
    Name = "Free Cam Speed",
    Range = {5, 300},
    Increment = 5,
    Suffix = " stud/s",
    CurrentValue = 40,
    Flag = "FreeCamSpeed",
    Callback = function(v)
        FreeCam:SetSpeed(v)
    end,
})

MovTab:CreateKeybind({
    Name = "FreeCam Keybind",
    CurrentKeybind = "V",
    HoldToInteract = false,
    Flag = "FreeCamKeybind",
    Callback = function(k)
        local keyName = tostring(k):upper()
        if Enum.KeyCode[keyName] then
            fcKey = Enum.KeyCode[keyName]
            N("FreeCam Keybind", "Set to "..keyName)
        end
    end,
})

UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= fcKey then return end
    local s = not FreeCam.Enabled
    fcToggle:Set(s)
    if s then FreeCam:Enable() else FreeCam:Disable() end
end)

MovTab:CreateSection("Click Teleport")

MovTab:CreateToggle({
    Name = "Click Teleport",
    CurrentValue = false,
    Flag = "ClickTP",
    Callback = function(v)
        if v then ClickTP:Enable() else ClickTP:Disable() end
        N("Click Teleport", v and "Enabled — click to tp" or "Disabled")
    end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUAL TAB
-- ══════════════════════════════════════════════════════════════════════════════
VisTab:CreateSection("Rendering")

VisTab:CreateToggle({
    Name = "Perf Stats (HUD)",
    CurrentValue = true,
    Flag = "PerfStats",
    Callback = function(v)
        if v then PerfStats:Enable() else PerfStats:Disable() end
        N("Perf Stats", v and "Enabled" or "Disabled")
    end,
})

VisTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        if v then ESP:Enable() else ESP:Disable() end
        N("ESP", v and "Enabled" or "Disabled")
    end,
})

VisTab:CreateToggle({
    Name = "FullBright",
    CurrentValue = false,
    Flag = "FullBright",
    Callback = function(v)
        if v then FullBright:Enable() else FullBright:Disable() end
        N("FullBright", v and "Enabled" or "Disabled")
    end,
})

VisTab:CreateToggle({
    Name = "Remove Fog",
    CurrentValue = false,
    Flag = "RemoveFog",
    Callback = function(v)
        if v then RemoveFog:Enable() else RemoveFog:Disable() end
        N("Remove Fog", v and "Enabled" or "Disabled")
    end,
})

VisTab:CreateSection("Appearance")

VisTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPColor",
    Callback = function(v)
        ESP:SetColor(v)
    end
})

VisTab:CreateSlider({
    Name = "ESP Fill Opacity",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 15,
    Flag = "ESPOpacity",
    Callback = function(v)
        ESP:SetOpacity(v)
    end,
})

VisTab:CreateDropdown({
    Name = "ESP Show Mode",
    Options = {"Both", "Body", "Name"},
    CurrentOption = "Both",
    Flag = "ESPMode",
    Callback = function(v)
        ESP:SetShowMode(v)
    end,
})

VisTab:CreateSection("Tracer")

VisTab:CreateToggle({
    Name = "Player Tracer",
    CurrentValue = false,
    Flag = "Tracer",
    Callback = function(v)
        if v then Tracer:Enable() else Tracer:Disable() end
        N("Tracer", v and "Enabled" or "Disabled")
    end,
})

VisTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "TracerColor",
    Callback = function(v)
        Tracer:SetColor(v)
    end
})

VisTab:CreateSlider({
    Name = "Tracer Opacity",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "TracerOpacity",
    Callback = function(v)
        Tracer:SetOpacity(v)
    end,
})

VisTab:CreateSlider({
    Name = "Tracer Thickness",
    Range = {1, 8},
    Increment = 1,
    CurrentValue = 2,
    Flag = "TracerThickness",
    Callback = function(v)
        Tracer:SetThickness(v)
    end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER TAB
-- ══════════════════════════════════════════════════════════════════════════════
PlyTab:CreateSection("Utility")

PlyTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        if v then AntiAFK:Enable() else AntiAFK:Disable() end
        N("Anti AFK", v and "Enabled" or "Disabled")
    end,
})

PlyTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Flag = "InfStamina",
    Callback = function(v)
        if v then InfStamina:Enable() else InfStamina:Disable() end
        N("Infinite Stamina", v and "Enabled" or "Disabled")
    end,
})

PlyTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(v)
        if v then GodMode:Enable() else GodMode:Disable() end
        N("God Mode", v and "Enabled" or "Disabled")
    end,
})

PlyTab:CreateSection("Protection")

PlyTab:CreateToggle({
    Name = "No Fall Damage",
    CurrentValue = false,
    Flag = "NoFallDamage",
    Callback = function(v)
        if v then NoFallDmg:Enable() else NoFallDmg:Disable() end
        N("No Fall Damage", v and "Enabled" or "Disabled")
    end,
})

PlyTab:CreateToggle({
    Name = "Anti Fling",
    CurrentValue = false,
    Flag = "AntiFling",
    Callback = function(v)
        if v then AntiFling:Enable() else AntiFling:Disable() end
        N("Anti Fling", v and "Enabled" or "Disabled")
    end,
})

PlyTab:CreateSlider({
    Name = "Fling Threshold",
    Range = {100, 1000},
    Increment = 10,
    Suffix = " stud/s",
    CurrentValue = 200,
    Flag = "FlingThreshold",
    Callback = function(v)
        AntiFling:SetThreshold(v)
    end,
})

PlyTab:CreateSection("Combat")

PlyTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Flag = "HitboxExpander",
    Callback = function(v)
        if v then HitboxExp:Enable() else HitboxExp:Disable() end
        N("Hitbox Expander", v and "Enabled" or "Disabled")
    end,
})

PlyTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {5, 30},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 10,
    Flag = "HitboxSize",
    Callback = function(v)
        HitboxExp:SetSize(v)
    end,
})

PlyTab:CreateSlider({
    Name = "Hitbox Transparency",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 80,
    Flag = "HitboxTransparency",
    Callback = function(v)
        HitboxExp:SetTransparency(v)
    end,
})

PlyTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "HitboxTeamCheck",
    Callback = function(v)
        HitboxExp:SetTeamCheck(v)
        N("Team Check", v and "Skip teammates" or "Target all")
    end,
})

PlyTab:CreateSection("Teleport")

PlyTab:CreateButton({
    Name = "📍 Copy My Position",
    Callback = function()
        local p = Teleport:SavePosition()
        if p then
            N("Teleport", ("Saved: %.0f, %.0f, %.0f"):format(p.X,p.Y,p.Z))
        else
            N("Teleport", "No character")
        end
    end,
})

PlyTab:CreateButton({
    Name = "🚀 Go to Saved Position",
    Callback = function()
        if Teleport:GotoSaved(Fly) then
            N("Teleport", "Teleported")
        else
            N("Teleport", "No position saved")
        end
    end,
})

local tpDrop = PlyTab:CreateDropdown({
    Name = "Select Player",
    Options = Teleport:GetPlayerList(),
    CurrentOption = Teleport:GetPlayerList()[1],
    Flag = "TeleportPlayer",
    Callback = function(v) end,
})

PlyTab:CreateButton({
    Name = "🔄 Refresh Players",
    Callback = function()
        local list = Teleport:GetPlayerList()
        tpDrop:UpdateDropdown(list)
        N("Teleport", "Refreshed")
    end,
})

PlyTab:CreateButton({
    Name = "⚡ Teleport to Player",
    Callback = function()
        local name = tpDrop.CurrentOption
        if name == "(no players)" then return end
        if Teleport:ToPlayer(name, Fly) then
            N("Teleport", "→ "..name)
        else
            N("Teleport", name.." not found")
        end
    end,
})

PlyTab:CreateSection("Waypoints")

local wpNameInput
wpNameInput = PlyTab:CreateInput({
    Name = "Waypoint Name",
    PlaceholderText = "e.g. spawn",
    RemoveTextAfterFocusLost = false,
    Flag = "WaypointName",
    Callback = function(v) end,
})

PlyTab:CreateButton({
    Name = "➕ Create Waypoint",
    Callback = function()
        local name = wpNameInput.CurrentValue or ""
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
    end,
})

local wpDrop = PlyTab:CreateDropdown({
    Name = "Select Waypoint",
    Options = Waypoint:GetList(),
    CurrentOption = Waypoint:GetList()[1],
    Flag = "SelectWaypoint",
    Callback = function(v) end,
})

PlyTab:CreateButton({
    Name = "🔄 Refresh Waypoints",
    Callback = function()
        local list = Waypoint:GetList()
        wpDrop:UpdateDropdown(list)
        N("Waypoint", "Refreshed")
    end,
})

PlyTab:CreateButton({
    Name = "📍 Teleport to Waypoint",
    Callback = function()
        local name = wpDrop.CurrentOption
        if name == "(no waypoints)" then return end
        if Waypoint:Teleport(name, Fly) then
            N("Waypoint", "→ "..name)
        else
            N("Waypoint", "Failed")
        end
    end,
})

PlyTab:CreateButton({
    Name = "🗑 Delete Waypoint",
    Callback = function()
        local name = wpDrop.CurrentOption
        if name == "(no waypoints)" then return end
        if Waypoint:Delete(name) then
            N("Waypoint", "Deleted: "..name)
            wpDrop:UpdateDropdown(Waypoint:GetList())
        else
            N("Waypoint", "Failed to delete")
        end
    end,
})

PlyTab:CreateSection("Server")

PlyTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        N("Rejoin", "Rejoining...")
        task.wait(1.5)
        Rejoin:Execute()
    end,
})

PlyTab:CreateButton({
    Name = "Copy Player ID",
    Callback = function()
        pcall(function() setclipboard(tostring(lp.UserId)) end)
        N("Copied", "ID: "..lp.UserId)
    end,
})

PlyTab:CreateSection("Stats")

PlyTab:CreateLabel("Username: "..lp.Name)
PlyTab:CreateLabel("User ID: "..tostring(lp.UserId))

-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ══════════════════════════════════════════════════════════════════════════════
SetTab:CreateSection("About")

SetTab:CreateParagraph({Title = "Leon X", Content = "Version "..CURRENT_VERSION.." • by leonx24\n\nAll features loaded successfully!"})

SetTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Rayfield:Destroy()
    end,
})

-- Boot sequence
PerfStats:Enable()

Rayfield:Notify({
    Title = "Leon X",
    Content = "Welcome! All features loaded.",
    Duration = 3,
    Image = 4483362458,
})
