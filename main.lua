local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/affaririzkyf/Leon-x/main/ui/library.lua"))()

local Movement = Library:CreateTab("Movement")
local Visual   = Library:CreateTab("Visual")
local Player   = Library:CreateTab("Player")
local Settings = Library:CreateTab("Settings")

-- ── Movement ──────────────────────────────────────────────────────────────────
Movement:AddSection("Locomotion")

Movement:AddToggle({
    Name = "Fly",
    Default = false,
    Callback = function(v) print("Fly:", v) end,
})

Movement:AddToggle({
    Name = "Speed Hack",
    Default = false,
    Callback = function(v) print("Speed:", v) end,
})

Movement:AddSlider({
    Name = "Walk Speed",
    Min = 16, Max = 250, Default = 16,
    Suffix = " stud/s",
    Callback = function(v) print("WalkSpeed:", v) end,
})

Movement:AddSlider({
    Name = "Jump Power",
    Min = 50, Max = 500, Default = 50,
    Callback = function(v) print("JumpPower:", v) end,
})

Movement:AddSection("Misc")

Movement:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(v) print("InfJump:", v) end,
})

Movement:AddKeybind({
    Name = "Fly Keybind",
    Default = Enum.KeyCode.F,
    Callback = function(k) print("Fly key:", k.Name) end,
})

-- ── Visual ────────────────────────────────────────────────────────────────────
Visual:AddSection("Rendering")

Visual:AddToggle({
    Name = "ESP",
    Default = false,
    Callback = function(v) print("ESP:", v) end,
})

Visual:AddToggle({
    Name = "FullBright",
    Default = false,
    Callback = function(v) print("FullBright:", v) end,
})

Visual:AddSection("Appearance")

Visual:AddDropdown({
    Name = "ESP Color",
    Options = { "White", "Red", "Green", "Blue", "Yellow" },
    Default = "White",
    Callback = function(v) print("ESP Color:", v) end,
})

Visual:AddSlider({
    Name = "ESP Opacity",
    Min = 0, Max = 100, Default = 80,
    Suffix = "%",
    Callback = function(v) print("ESP Opacity:", v) end,
})

Visual:AddColorPicker({
    Name = "Chams Color",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(c) print("Chams:", c) end,
})

-- ── Player ────────────────────────────────────────────────────────────────────
Player:AddSection("Utility")

Player:AddToggle({
    Name = "Anti AFK",
    Default = false,
    Callback = function(v) print("AntiAFK:", v) end,
})

Player:AddButton({
    Name = "Rejoin Server",
    Callback = function() print("Rejoining...") end,
})

Player:AddButton({
    Name = "Copy Player ID",
    Callback = function()
        print("ID:", game.Players.LocalPlayer.UserId)
    end,
})

Player:AddSection("Stats")

Player:AddLabel({
    Text = "Username: " .. game.Players.LocalPlayer.Name,
    Color = Color3.fromRGB(100, 100, 100),
})

Player:AddLabel({
    Text = "User ID: " .. tostring(game.Players.LocalPlayer.UserId),
    Color = Color3.fromRGB(100, 100, 100),
})

-- ── Settings ──────────────────────────────────────────────────────────────────
Settings:AddSection("Interface")

Settings:AddToggle({
    Name = "Show Notifications",
    Default = true,
    Callback = function(v) print("Notifs:", v) end,
})

Settings:AddDropdown({
    Name = "Theme",
    Options = { "Dark", "Midnight", "Slate" },
    Default = "Dark",
    Callback = function(v) print("Theme:", v) end,
})

Settings:AddSlider({
    Name = "UI Transparency",
    Min = 0, Max = 100, Default = 0,
    Suffix = "%",
    Callback = function(v) print("Transparency:", v) end,
})

Settings:AddSection("About")

Settings:AddLabel({
    Text = "Leon X  ·  v4.0  ·  github.com/affaririzkyf",
    Color = Color3.fromRGB(70, 70, 70),
    Align = Enum.TextXAlignment.Center,
})
