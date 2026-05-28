-- Leon X | main.lua

-- Load library: coba lokal dulu, fallback ke GitHub
local Library
local ok, err = pcall(function()
    Library = loadstring(readfile("Leon X/ui/library.lua"))()
end)
if not ok then
    Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/ui/library.lua"
    ))()
end

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local Movement = Library:CreateTab("Movement")
local Visual   = Library:CreateTab("Visual")
local Player   = Library:CreateTab("Player")
local Settings = Library:CreateTab("Settings")

-- ── Movement ──────────────────────────────────────────────────────────────────
Movement:AddSection("Locomotion")

Movement:AddToggle({
    Name     = "Fly",
    Default  = false,
    Callback = function(v) print("Fly:", v) end,
})

Movement:AddToggle({
    Name     = "Speed",
    Default  = false,
    Callback = function(v) print("Speed:", v) end,
})

Movement:AddSlider({
    Name     = "Walk Speed",
    Min      = 16,
    Max      = 200,
    Default  = 16,
    Suffix   = " stud/s",
    Callback = function(v) print("WalkSpeed:", v) end,
})

Movement:AddSlider({
    Name     = "Jump Power",
    Min      = 50,
    Max      = 500,
    Default  = 50,
    Callback = function(v) print("JumpPower:", v) end,
})

Movement:AddSection("Misc")

Movement:AddToggle({
    Name     = "Infinite Jump",
    Default  = false,
    Callback = function(v) print("InfJump:", v) end,
})

Movement:AddKeybind({
    Name     = "Fly Keybind",
    Default  = Enum.KeyCode.F,
    Callback = function(key) print("Fly key:", key.Name) end,
})

-- ── Visual ────────────────────────────────────────────────────────────────────
Visual:AddSection("Rendering")

Visual:AddToggle({
    Name     = "ESP",
    Default  = false,
    Callback = function(v) print("ESP:", v) end,
})

Visual:AddToggle({
    Name     = "FullBright",
    Default  = false,
    Callback = function(v) print("FullBright:", v) end,
})

Visual:AddSection("Appearance")

Visual:AddDropdown({
    Name     = "ESP Color",
    Options  = { "White", "Red", "Green", "Blue", "Yellow" },
    Default  = "White",
    Callback = function(v) print("ESP Color:", v) end,
})

Visual:AddSlider({
    Name     = "ESP Opacity",
    Min      = 0,
    Max      = 100,
    Default  = 80,
    Suffix   = "%",
    Callback = function(v) print("ESP Opacity:", v) end,
})

-- ── Player ────────────────────────────────────────────────────────────────────
Player:AddSection("Utility")

Player:AddToggle({
    Name     = "Anti AFK",
    Default  = false,
    Callback = function(v) print("AntiAFK:", v) end,
})

Player:AddButton({
    Name     = "Rejoin Server",
    Callback = function() print("Rejoining...") end,
})

Player:AddButton({
    Name     = "Copy Player ID",
    Callback = function()
        print("Copied:", game.Players.LocalPlayer.UserId)
    end,
})

-- ── Settings ──────────────────────────────────────────────────────────────────
Settings:AddSection("Interface")

Settings:AddToggle({
    Name     = "Show Notifications",
    Default  = true,
    Callback = function(v) print("Notifications:", v) end,
})

Settings:AddDropdown({
    Name     = "UI Scale",
    Options  = { "Small", "Normal", "Large" },
    Default  = "Normal",
    Callback = function(v) print("Scale:", v) end,
})

Settings:AddSection("About")

Settings:AddLabel({
    Text  = "Leon X  ·  v2.2.0",
    Color = Color3.fromRGB(80, 80, 80),
    Align = Enum.TextXAlignment.Center,
})
