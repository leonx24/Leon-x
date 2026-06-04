-- Leon X | main.lua

local BASE = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"

local Library = loadstring(game:HttpGet(BASE .. "ui/library.lua"))()
local Fly     = loadstring(game:HttpGet(BASE .. "modules/movements/fly.lua"))()
local ConfigManager = loadstring(game:HttpGet(BASE .. "modules/core/configmanager.lua"))()

ConfigManager:Init(Library)

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local Movement = Library:CreateTab("Movement")
local Visual   = Library:CreateTab("Visual")
local Player   = Library:CreateTab("Player")
local Settings = Library:CreateTab("Settings")

-- ── Movement ──────────────────────────────────────────────────────────────────
Movement:AddSection("Locomotion")

local flyToggle = Movement:AddToggle({
    Name    = "Fly",
    Flag    = "Fly",
    Default = false,
    Callback = function(v)
        if v then Fly:Enable() else Fly:Disable() end
    end,
})

Movement:AddSlider({
    Name    = "Fly Speed",
    Flag    = "FlySpeed",
    Min     = 10,
    Max     = 300,
    Default = 60,
    Suffix  = " stud/s",
    Callback = function(v)
        Fly:SetSpeed(v)
    end,
})

Movement:AddToggle({
    Name    = "Speed Hack",
    Flag    = "SpeedHack",
    Default = false,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and 60 or 16 end
    end,
})

Movement:AddSlider({
    Name    = "Walk Speed",
    Flag    = "WalkSpeed",
    Min     = 16,
    Max     = 250,
    Default = 16,
    Suffix  = " stud/s",
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

Movement:AddSlider({
    Name    = "Jump Power",
    Flag    = "JumpPower",
    Min     = 50,
    Max     = 500,
    Default = 50,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end,
})

Movement:AddSection("Misc")

local infJumpEnabled = false

Movement:AddToggle({
    Name    = "Infinite Jump",
    Flag    = "InfiniteJump",
    Default = false,
    Callback = function(v)
        infJumpEnabled = v
        _G.InfJump = v
    end,
})

-- Infinite jump listener — single connection, checks upvalue directly
game:GetService("UserInputService").JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ── Keybind listener — wired once at startup, key is read at press time ────────
local flyKey = Enum.KeyCode.F   -- tracks current keybind
local UIS2   = game:GetService("UserInputService")

UIS2.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == flyKey then
        local newState = not Fly.Enabled
        flyToggle:Set(newState)
        if newState then Fly:Enable() else Fly:Disable() end
    end
end)

Movement:AddKeybind({
    Name    = "Fly Keybind",
    Flag    = "FlyKeybind",
    Default = Enum.KeyCode.F,
    Callback = function(key)
        -- just update the tracked key — listener above handles the rest
        flyKey = key
    end,
})

-- ── Visual ────────────────────────────────────────────────────────────────────
Visual:AddSection("Rendering")

Visual:AddToggle({
    Name    = "ESP",
    Flag    = "ESP",
    Default = false,
    Callback = function(v) print("ESP:", v) end,
})

Visual:AddToggle({
    Name    = "FullBright",
    Flag    = "FullBright",
    Default = false,
    Callback = function(v)
        local Lighting = game:GetService("Lighting")
        if v then
            Lighting.Brightness    = 2
            Lighting.ClockTime     = 14
            Lighting.FogEnd        = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient       = Color3.fromRGB(178,178,178)
        else
            Lighting.Brightness    = 1
            Lighting.ClockTime     = 14
            Lighting.FogEnd        = 100000
            Lighting.GlobalShadows = true
            Lighting.Ambient       = Color3.fromRGB(70,70,70)
        end
    end,
})

Visual:AddSection("Appearance")

Visual:AddDropdown({
    Name    = "ESP Color",
    Flag    = "ESPColor",
    Options = { "White", "Red", "Green", "Blue", "Yellow" },
    Default = "White",
    Callback = function(v) print("ESP Color:", v) end,
})

Visual:AddSlider({
    Name    = "ESP Opacity",
    Flag    = "ESPOpacity",
    Min     = 0,
    Max     = 100,
    Default = 80,
    Suffix  = "%",
    Callback = function(v) print("ESP Opacity:", v) end,
})

Visual:AddColorPicker({
    Name    = "Chams Color",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(c) print("Chams:", c) end,
})

-- ── Player ────────────────────────────────────────────────────────────────────
Player:AddSection("Utility")

Player:AddToggle({
    Name    = "Anti AFK",
    Flag    = "AntiAFK",
    Default = false,
    Callback = function(v)
        _G.AntiAFK = v
        if v then
            _G.AntiAFKConn = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(.1)
                game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        else
            if _G.AntiAFKConn then
                _G.AntiAFKConn:Disconnect()
                _G.AntiAFKConn = nil
            end
        end
    end,
})

Player:AddButton({
    Name     = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end,
})

Player:AddButton({
    Name     = "Copy Player ID",
    Callback = function()
        setclipboard(tostring(game.Players.LocalPlayer.UserId))
    end,
})

Player:AddSection("Stats")

Player:AddLabel({
    Text  = "Username: " .. game.Players.LocalPlayer.Name,
    Color = Color3.fromRGB(100,100,100),
})

Player:AddLabel({
    Text  = "User ID: " .. tostring(game.Players.LocalPlayer.UserId),
    Color = Color3.fromRGB(100,100,100),
})

-- ── Settings ──────────────────────────────────────────────────────────────────
Settings:AddSection("Interface")

Settings:AddToggle({
    Name    = "Show Notifications",
    Flag    = "ShowNotifs",
    Default = true,
    Callback = function(v) print("Notifs:", v) end,
})

Settings:AddDropdown({
    Name    = "Theme",
    Flag    = "Theme",
    Options = { "Dark", "Midnight", "Slate" },
    Default = "Dark",
    Callback = function(v) print("Theme:", v) end,
})

Settings:AddSection("Config")

-- current config name (typed by user via a label that updates)
local configName = "default"

-- show/edit config name — we use a keybind-less button as a name display
-- user types name in chat then clicks "Set Name" ... but since library
-- has no TextBox, we provide a label + quick‑name buttons
local configNameLbl = Settings:AddLabel({
    Text  = "Name: default",
    Color = Color3.fromRGB(160,160,160),
})

-- preset name buttons so user can quickly pick names without typing
local function setConfigName(n)
    configName = n
    configNameLbl:Set("Name: " .. n)
end

-- config name presets (extend as needed)
for _, n in ipairs({"default", "pvp", "farming", "custom"}) do
    local nameCopy = n
    Settings:AddButton({
        Name     = "› " .. n,
        Callback = function() setConfigName(nameCopy) end,
    })
end

-- config list dropdown — populated from disk
local function getConfigList()
    local list = ConfigManager:List()
    if #list == 0 then list = {"(none)"} end
    return list
end

local configSelect = Settings:AddDropdown({
    Name    = "Select Config",
    Options = getConfigList(),
    Default = (ConfigManager:List()[1] or "(none)"),
})

Settings:AddButton({
    Name     = "💾  Save Config",
    Callback = function()
        local ok = ConfigManager:Save(configName)
        print(ok and ("Saved: " .. configName) or "Save failed")
        local newList = getConfigList()
        configSelect:SetOptions(newList)
        configSelect:Set(configName)
    end,
})

Settings:AddButton({
    Name     = "📂  Load Config",
    Callback = function()
        local sel = configSelect:Get()
        if sel == "(none)" then return end
        local ok = ConfigManager:Load(sel)
        print(ok and ("Loaded: " .. sel) or "Load failed: " .. sel)
    end,
})

Settings:AddButton({
    Name     = "🗑  Delete Config",
    Callback = function()
        local sel = configSelect:Get()
        if sel == "(none)" then return end
        local ok = ConfigManager:Delete(sel)
        print(ok and ("Deleted: " .. sel) or "Delete failed: " .. sel)
        local newList = getConfigList()
        configSelect:SetOptions(newList)
    end,
})

Settings:AddButton({
    Name     = "⭐  Set as Default",
    Callback = function()
        local sel = configSelect:Get()
        if sel == "(none)" then return end
        local ok = ConfigManager:SetDefault(sel)
        print(ok and (sel .. " set as default") or "SetDefault failed")
    end,
})

Settings:AddSection("About")

Settings:AddLabel({
    Text  = "Leon X  ·  v4.2",
    Color = Color3.fromRGB(70,70,70),
    Align = Enum.TextXAlignment.Center,
})

-- ── Auto-load default config (must be LAST, after all Add* calls) ─────────────
ConfigManager:AutoLoad()
