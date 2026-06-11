-- Leon X | main.lua (Rayfield UI version - Optimized)

local BASE = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"

-- Fetch current version
local CURRENT_VERSION = "1.0"
pcall(function()
    CURRENT_VERSION = game:HttpGet(BASE.."version.txt?t="..os.time()):match("^%s*(.-)%s*$")
end)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

print("[Leon X] Starting load...")

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
print("[Leon X] Rayfield loaded")

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
   Discord = { Enabled = false },
   KeySystem = false,
})

print("[Leon X] Window created")

-- Notification helper
local function N(title, message)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = 2,
        Image = 4483362458,
    })
end

-- Load modules with error handling (async to speed up)
local cacheBust = "?t="..os.time()
local modules = {}

local function loadModule(name, path)
    task.spawn(function()
        local success, result = pcall(function()
            return loadstring(game:HttpGet(BASE..path..cacheBust))()
        end)
        if success then
            modules[name] = result
            print("[Leon X] Loaded:", name)
        else
            warn("[Leon X] Failed to load:", name, result)
        end
    end)
end

-- Start loading all modules in parallel
loadModule("Fly", "modules/movements/fly.lua")
loadModule("Speed", "modules/movements/speed.lua")
loadModule("InfJump", "modules/movements/infinitejump.lua")
loadModule("Noclip", "modules/movements/noclip.lua")
loadModule("AntiRagdoll", "modules/movements/antiragdoll.lua")
loadModule("Invisible", "modules/movements/invisible.lua")
loadModule("FreeCam", "modules/movements/freecam.lua")
loadModule("ClickTP", "modules/movements/clickteleport.lua")
loadModule("ESP", "modules/visuals/esp.lua")
loadModule("Tracer", "modules/visuals/tracer.lua")
loadModule("FullBright", "modules/visuals/fullbright.lua")
loadModule("PerfStats", "modules/visuals/perfstats.lua")
loadModule("RemoveFog", "modules/visuals/removefog.lua")
loadModule("AntiAFK", "modules/player/antiafk.lua")
loadModule("InfStamina", "modules/player/infinitestamina.lua")
loadModule("AntiFling", "modules/player/antifling.lua")
loadModule("Rejoin", "modules/player/rejoin.lua")
loadModule("Teleport", "modules/player/teleport.lua")
loadModule("HitboxExp", "modules/player/hitboxexpander.lua")
loadModule("Waypoint", "modules/player/waypoint.lua")
loadModule("GodMode", "modules/player/godmode.lua")
loadModule("NoFallDmg", "modules/player/nofalldamage.lua")

-- Wait for all modules to load (max 10 seconds)
local startTime = tick()
while tick() - startTime < 10 do
    local allLoaded = true
    for name, mod in pairs(modules) do
        if not mod then allLoaded = false; break end
    end
    if allLoaded then break end
    task.wait(0.1)
end

print("[Leon X] Modules loaded, creating UI...")

-- Init waypoint
if modules.Waypoint then modules.Waypoint:Init() end

-- Create Tabs
local MovTab = Window:CreateTab("Movement 🏃", 4483362458)
local VisTab = Window:CreateTab("Visual 👁", 4483362458)
local PlyTab = Window:CreateTab("Player 👤", 4483362458)
local SetTab = Window:CreateTab("Settings ⚙", 4483362458)

print("[Leon X] Tabs created, adding elements...")

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ══════════════════════════════════════════════════════════════════════════════
MovTab:CreateSection("Locomotion")

if modules.Fly then
    local Fly = modules.Fly
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
            if Fly then Fly:SetSpeed(v) end
        end,
    })

    local flyKey = Enum.KeyCode.F
    MovTab:CreateKeybind({
        Name = "Fly Keybind",
        CurrentKeybind = "F",
        HoldToInteract = false,
        Flag = "FlyKeybind",
        Callback = function(keybind)
            -- Rayfield callback receives the key name as string
            pcall(function()
                flyKey = Enum.KeyCode[keybind]
                N("Fly Keybind", "Set to "..keybind)
            end)
        end,
    })

    UIS.InputBegan:Connect(function(i, gp)
        if gp or i.KeyCode ~= flyKey then return end
        pcall(function()
            local s = not Fly.Enabled
            flyToggle:Set(s)
            if s then Fly:Enable() else Fly:Disable() end
        end)
    end)
end

if modules.Speed then
    local Speed = modules.Speed
    MovTab:CreateToggle({
        Name = "Speed Hack",
        CurrentValue = false,
        Flag = "SpeedHack",
        Callback = function(v)
            if Speed then
                Speed:SetWalkSpeed(v and 60 or 16)
                if v then Speed:Enable() else Speed:Disable() end
                N("Speed Hack", v and "Enabled (60)" or "Disabled")
            end
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
            if Speed then
                Speed:SetWalkSpeed(v)
                Speed:Enable()
            end
        end,
    })

    MovTab:CreateSlider({
        Name = "Jump Power",
        Range = {50, 500},
        Increment = 5,
        CurrentValue = 50,
        Flag = "JumpPower",
        Callback = function(v)
            if Speed then
                Speed:SetJumpPower(v)
                Speed:Enable()
            end
        end,
    })
end

MovTab:CreateSection("Misc")

if modules.InfJump then
    local InfJump = modules.InfJump
    MovTab:CreateToggle({
        Name = "Infinite Jump",
        CurrentValue = false,
        Flag = "InfiniteJump",
        Callback = function(v)
            if InfJump then
                if v then InfJump:Enable() else InfJump:Disable() end
                N("Infinite Jump", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.Noclip then
    local Noclip = modules.Noclip
    MovTab:CreateToggle({
        Name = "Noclip",
        CurrentValue = false,
        Flag = "Noclip",
        Callback = function(v)
            if Noclip then
                if v then Noclip:Enable() else Noclip:Disable() end
                N("Noclip", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.AntiRagdoll then
    local AntiRagdoll = modules.AntiRagdoll
    MovTab:CreateToggle({
        Name = "Anti Ragdoll",
        CurrentValue = false,
        Flag = "AntiRagdoll",
        Callback = function(v)
            if AntiRagdoll then
                if v then AntiRagdoll:Enable() else AntiRagdoll:Disable() end
                N("Anti Ragdoll", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.Invisible then
    local Invisible = modules.Invisible
    MovTab:CreateToggle({
        Name = "Invisible (local)",
        CurrentValue = false,
        Flag = "Invisible",
        Callback = function(v)
            if Invisible then
                if v then Invisible:Enable() else Invisible:Disable() end
                N("Invisible", v and "Enabled" or "Disabled")
            end
        end,
    })
end

MovTab:CreateSection("Camera")

if modules.FreeCam then
    local FreeCam = modules.FreeCam
    local fcKey = Enum.KeyCode.V
    local fcToggle = MovTab:CreateToggle({
        Name = "Free Cam",
        CurrentValue = false,
        Flag = "FreeCam",
        Callback = function(v)
            if FreeCam then
                if v then FreeCam:Enable() else FreeCam:Disable() end
                N("Free Cam", v and "Enabled" or "Disabled")
            end
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
            if FreeCam then FreeCam:SetSpeed(v) end
        end,
    })

    MovTab:CreateKeybind({
        Name = "FreeCam Keybind",
        CurrentKeybind = "V",
        HoldToInteract = false,
        Flag = "FreeCamKeybind",
        Callback = function(keybind)
            pcall(function()
                fcKey = Enum.KeyCode[keybind]
                N("FreeCam Keybind", "Set to "..keybind)
            end)
        end,
    })

    UIS.InputBegan:Connect(function(i, gp)
        if gp or i.KeyCode ~= fcKey then return end
        pcall(function()
            local s = not FreeCam.Enabled
            fcToggle:Set(s)
            if s then FreeCam:Enable() else FreeCam:Disable() end
        end)
    end)
end

MovTab:CreateSection("Click Teleport")

if modules.ClickTP then
    local ClickTP = modules.ClickTP
    MovTab:CreateToggle({
        Name = "Click Teleport",
        CurrentValue = false,
        Flag = "ClickTP",
        Callback = function(v)
            if ClickTP then
                if v then ClickTP:Enable() else ClickTP:Disable() end
                N("Click Teleport", v and "Enabled — click to tp" or "Disabled")
            end
        end,
    })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUAL TAB
-- ══════════════════════════════════════════════════════════════════════════════
VisTab:CreateSection("Rendering")

if modules.PerfStats then
    local PerfStats = modules.PerfStats
    VisTab:CreateToggle({
        Name = "Perf Stats (HUD)",
        CurrentValue = true,
        Flag = "PerfStats",
        Callback = function(v)
            if PerfStats then
                if v then PerfStats:Enable() else PerfStats:Disable() end
                N("Perf Stats", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.ESP then
    local ESP = modules.ESP
    VisTab:CreateToggle({
        Name = "ESP",
        CurrentValue = false,
        Flag = "ESP",
        Callback = function(v)
            if ESP then
                if v then ESP:Enable() else ESP:Disable() end
                N("ESP", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.FullBright then
    local FullBright = modules.FullBright
    VisTab:CreateToggle({
        Name = "FullBright",
        CurrentValue = false,
        Flag = "FullBright",
        Callback = function(v)
            if FullBright then
                if v then FullBright:Enable() else FullBright:Disable() end
                N("FullBright", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.RemoveFog then
    local RemoveFog = modules.RemoveFog
    VisTab:CreateToggle({
        Name = "Remove Fog",
        CurrentValue = false,
        Flag = "RemoveFog",
        Callback = function(v)
            if RemoveFog then
                if v then RemoveFog:Enable() else RemoveFog:Disable() end
                N("Remove Fog", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.ESP then
    local ESP = modules.ESP
    VisTab:CreateSection("Appearance")

    VisTab:CreateColorPicker({
        Name = "ESP Color",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "ESPColor",
        Callback = function(color)
            if ESP then
                ESP:SetColor(color)
            end
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
            if ESP then
                ESP:SetOpacity(v)
            end
        end,
    })

    VisTab:CreateDropdown({
        Name = "ESP Show Mode",
        Options = {"Both", "Body", "Name"},
        CurrentOption = "Both",
        Flag = "ESPMode",
        Callback = function(option)
            if ESP then
                ESP:SetShowMode(option)
            end
        end,
    })
end

if modules.Tracer then
    local Tracer = modules.Tracer
    VisTab:CreateSection("Tracer")

    VisTab:CreateToggle({
        Name = "Player Tracer",
        CurrentValue = false,
        Flag = "Tracer",
        Callback = function(v)
            if Tracer then
                if v then Tracer:Enable() else Tracer:Disable() end
                N("Tracer", v and "Enabled" or "Disabled")
            end
        end,
    })

    VisTab:CreateColorPicker({
        Name = "Tracer Color",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "TracerColor",
        Callback = function(color)
            if Tracer then
                Tracer:SetColor(color)
            end
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
            if Tracer then
                Tracer:SetOpacity(v)
            end
        end,
    })

    VisTab:CreateSlider({
        Name = "Tracer Thickness",
        Range = {1, 8},
        Increment = 1,
        CurrentValue = 2,
        Flag = "TracerThickness",
        Callback = function(v)
            if Tracer then
                Tracer:SetThickness(v)
            end
        end,
    })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER TAB
-- ══════════════════════════════════════════════════════════════════════════════
PlyTab:CreateSection("Utility")

if modules.AntiAFK then
    local AntiAFK = modules.AntiAFK
    PlyTab:CreateToggle({
        Name = "Anti AFK",
        CurrentValue = false,
        Flag = "AntiAFK",
        Callback = function(v)
            if AntiAFK then
                if v then AntiAFK:Enable() else AntiAFK:Disable() end
                N("Anti AFK", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.InfStamina then
    local InfStamina = modules.InfStamina
    PlyTab:CreateToggle({
        Name = "Infinite Stamina",
        CurrentValue = false,
        Flag = "InfStamina",
        Callback = function(v)
            if InfStamina then
                if v then InfStamina:Enable() else InfStamina:Disable() end
                N("Infinite Stamina", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.GodMode then
    local GodMode = modules.GodMode
    PlyTab:CreateToggle({
        Name = "God Mode",
        CurrentValue = false,
        Flag = "GodMode",
        Callback = function(v)
            if GodMode then
                if v then GodMode:Enable() else GodMode:Disable() end
                N("God Mode", v and "Enabled" or "Disabled")
            end
        end,
    })
end

PlyTab:CreateSection("Protection")

if modules.NoFallDmg then
    local NoFallDmg = modules.NoFallDmg
    PlyTab:CreateToggle({
        Name = "No Fall Damage",
        CurrentValue = false,
        Flag = "NoFallDamage",
        Callback = function(v)
            if NoFallDmg then
                if v then NoFallDmg:Enable() else NoFallDmg:Disable() end
                N("No Fall Damage", v and "Enabled" or "Disabled")
            end
        end,
    })
end

if modules.AntiFling then
    local AntiFling = modules.AntiFling
    PlyTab:CreateToggle({
        Name = "Anti Fling",
        CurrentValue = false,
        Flag = "AntiFling",
        Callback = function(v)
            if AntiFling then
                if v then AntiFling:Enable() else AntiFling:Disable() end
                N("Anti Fling", v and "Enabled" or "Disabled")
            end
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
            if AntiFling then
                AntiFling:SetThreshold(v)
            end
        end,
    })
end

if modules.HitboxExp then
    local HitboxExp = modules.HitboxExp
    PlyTab:CreateSection("Combat")

    PlyTab:CreateToggle({
        Name = "Hitbox Expander",
        CurrentValue = false,
        Flag = "HitboxExpander",
        Callback = function(v)
            if HitboxExp then
                if v then HitboxExp:Enable() else HitboxExp:Disable() end
                N("Hitbox Expander", v and "Enabled" or "Disabled")
            end
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
            if HitboxExp then
                HitboxExp:SetSize(v)
            end
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
            if HitboxExp then
                HitboxExp:SetTransparency(v)
            end
        end,
    })

    PlyTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = true,
        Flag = "HitboxTeamCheck",
        Callback = function(v)
            if HitboxExp then
                HitboxExp:SetTeamCheck(v)
                N("Team Check", v and "Skip teammates" or "Target all")
            end
        end,
    })
end

if modules.Teleport then
    local Teleport = modules.Teleport
    local Fly = modules.Fly
    PlyTab:CreateSection("Teleport")

    PlyTab:CreateButton({
        Name = "📍 Copy My Position",
        Callback = function()
            if Teleport then
                local p = Teleport:SavePosition()
                if p then
                    N("Teleport", ("Saved: %.0f, %.0f, %.0f"):format(p.X,p.Y,p.Z))
                else
                    N("Teleport", "No character")
                end
            end
        end,
    })

    PlyTab:CreateButton({
        Name = "🚀 Go to Saved Position",
        Callback = function()
            if Teleport then
                if Teleport:GotoSaved(Fly) then
                    N("Teleport", "Teleported")
                else
                    N("Teleport", "No position saved")
                end
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
            if Teleport then
                local list = Teleport:GetPlayerList()
                -- Rayfield uses :Set() to update dropdown, not :Refresh() or :UpdateDropdown()
                tpDrop:Set(list[1] or "(no players)")
                N("Teleport", "Refreshed")
            end
        end,
    })

    PlyTab:CreateButton({
        Name = "⚡ Teleport to Player",
        Callback = function()
            if Teleport then
                -- Get current value from dropdown
                local name = tpDrop.CurrentOption or "(no players)"
                if name == "(no players)" then
                    N("Teleport", "No players available")
                    return
                end
                if Teleport:ToPlayer(name, Fly) then
                    N("Teleport", "→ "..name)
                else
                    N("Teleport", name.." not found")
                end
            end
        end,
    })
end

if modules.Waypoint then
    local Waypoint = modules.Waypoint
    local Fly = modules.Fly
    PlyTab:CreateSection("Waypoints")

    local wpNameInput = PlyTab:CreateInput({
        Name = "Waypoint Name",
        PlaceholderText = "e.g. spawn",
        RemoveTextAfterFocusLost = false,
        Flag = "WaypointName",
        Callback = function(v) end,
    })

    PlyTab:CreateButton({
        Name = "➕ Create Waypoint",
        Callback = function()
            if Waypoint then
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
            if Waypoint then
                local list = Waypoint:GetList()
                -- Rayfield uses :Set() to update dropdown
                wpDrop:Set(list[1] or "(no waypoints)")
                N("Waypoint", "Refreshed")
            end
        end,
    })

    PlyTab:CreateButton({
        Name = "📍 Teleport to Waypoint",
        Callback = function()
            if Waypoint then
                local name = wpDrop.CurrentOption or "(no waypoints)"
                if name == "(no waypoints)" then
                    N("Waypoint", "No waypoints available")
                    return
                end
                if Waypoint:Teleport(name, Fly) then
                    N("Waypoint", "→ "..name)
                else
                    N("Waypoint", "Failed")
                end
            end
        end,
    })

    PlyTab:CreateButton({
        Name = "🗑 Delete Waypoint",
        Callback = function()
            if Waypoint then
                local name = wpDrop.CurrentOption or "(no waypoints)"
                if name == "(no waypoints)" then
                    N("Waypoint", "No waypoints available")
                    return
                end
                if Waypoint:Delete(name) then
                    N("Waypoint", "Deleted: "..name)
                    local list = Waypoint:GetList()
                    wpDrop:Set(list[1] or "(no waypoints)")
                else
                    N("Waypoint", "Failed to delete")
                end
            end
        end,
    })
end

if modules.Rejoin then
    local Rejoin = modules.Rejoin
    PlyTab:CreateSection("Server")

    PlyTab:CreateButton({
        Name = "Rejoin Server",
        Callback = function()
            if Rejoin then
                N("Rejoin", "Rejoining...")
                task.wait(1.5)
                Rejoin:Execute()
            end
        end,
    })
end

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
SetTab:CreateSection("Interface")

local toggleUIKey = Enum.KeyCode.RightShift
SetTab:CreateKeybind({
    Name = "Toggle UI Key",
    CurrentKeybind = "RightShift",
    HoldToInteract = false,
    Flag = "ToggleUIKey",
    Callback = function(keybind)
        pcall(function()
            toggleUIKey = Enum.KeyCode[keybind]
            N("Toggle UI Key", "Set to "..keybind)
        end)
    end,
})

UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= toggleUIKey then return end
    pcall(function()
        Rayfield:Toggle()
    end)
end)

SetTab:CreateDropdown({
    Name = "Theme",
    Options = {"Default", "Light", "Amethyst", "Bloom"},
    CurrentOption = "Default",
    Flag = "Theme",
    Callback = function(theme)
        pcall(function()
            Rayfield:SetTheme(theme)
            N("Theme", theme.." applied")
        end)
    end,
})

SetTab:CreateToggle({
    Name = "Show Notifications",
    CurrentValue = true,
    Flag = "ShowNotifications",
    Callback = function(v)
        N("Notifications", v and "Enabled" or "Disabled")
    end,
})

SetTab:CreateSection("Config")

SetTab:CreateParagraph({
    Title = "Configuration",
    Content = "Rayfield automatically saves your settings.\nUse the buttons below for manual control."
})

SetTab:CreateButton({
    Name = "💾 Save Config Now",
    Callback = function()
        N("Config", "Settings saved automatically")
    end,
})

SetTab:CreateButton({
    Name = "🔄 Reset to Defaults",
    Callback = function()
        N("Config", "Please restart the script to reset")
    end,
})

SetTab:CreateSection("About")

SetTab:CreateParagraph({
    Title = "Leon X",
    Content = "Version "..CURRENT_VERSION.." • by leonx24\n\nRayfield UI Integration"
})

SetTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Rayfield:Destroy()
    end,
})

-- Boot sequence
if modules.PerfStats then
    modules.PerfStats:Enable()
end

print("[Leon X] UI fully loaded!")

Rayfield:Notify({
    Title = "Leon X",
    Content = "Welcome! All features loaded.",
    Duration = 3,
    Image = 4483362458,
})
