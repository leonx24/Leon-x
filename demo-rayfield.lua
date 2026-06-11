-- Rayfield UI Demo
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Leon X Demo",
   LoadingTitle = "Leon X Loading...",
   LoadingSubtitle = "by leonx24",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "LeonX",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
})

-- Create Tabs
local MovementTab = Window:CreateTab("Movement 🏃", 4483362458)
local VisualTab = Window:CreateTab("Visual 👁", 4483362458)
local PlayerTab = Window:CreateTab("Player 👤", 4483362458)

-- Movement Section
local MovementSection = MovementTab:CreateSection("Locomotion")

local FlyToggle = MovementTab:CreateToggle({
   Name = "Fly",
   CurrentValue = false,
   Flag = "Fly",
   Callback = function(Value)
      print("Fly:", Value)
      Rayfield:Notify({
         Title = "Fly",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

local FlySpeedSlider = MovementTab:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 300},
   Increment = 5,
   Suffix = " stud/s",
   CurrentValue = 60,
   Flag = "FlySpeed",
   Callback = function(Value)
      print("Fly Speed:", Value)
   end,
})

local FlyKeybind = MovementTab:CreateKeybind({
   Name = "Fly Keybind",
   CurrentKeybind = "F",
   HoldToInteract = false,
   Flag = "FlyKeybind",
   Callback = function(Keybind)
      print("Fly Keybind:", Keybind)
   end,
})

MovementTab:CreateToggle({
   Name = "Speed Hack",
   CurrentValue = false,
   Flag = "SpeedHack",
   Callback = function(Value)
      print("Speed Hack:", Value)
   end,
})

MovementTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 250},
   Increment = 1,
   Suffix = " stud/s",
   CurrentValue = 16,
   Flag = "WalkSpeed",
   Callback = function(Value)
      print("Walk Speed:", Value)
   end,
})

local MiscSection = MovementTab:CreateSection("Misc")

MovementTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfJump",
   Callback = function(Value)
      print("Infinite Jump:", Value)
   end,
})

MovementTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "Noclip",
   Callback = function(Value)
      print("Noclip:", Value)
   end,
})

-- Visual Section
local RenderSection = VisualTab:CreateSection("Rendering")

VisualTab:CreateToggle({
   Name = "ESP",
   CurrentValue = false,
   Flag = "ESP",
   Callback = function(Value)
      print("ESP:", Value)
   end,
})

VisualTab:CreateToggle({
   Name = "FullBright",
   CurrentValue = false,
   Flag = "FullBright",
   Callback = function(Value)
      print("FullBright:", Value)
   end,
})

local AppearanceSection = VisualTab:CreateSection("Appearance")

local ESPColorPicker = VisualTab:CreateColorPicker({
   Name = "ESP Color",
   Color = Color3.fromRGB(255, 255, 255),
   Flag = "ESPColor",
   Callback = function(Value)
      print("ESP Color:", Value)
   end
})

VisualTab:CreateSlider({
   Name = "ESP Opacity",
   Range = {0, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = 15,
   Flag = "ESPOpacity",
   Callback = function(Value)
      print("ESP Opacity:", Value)
   end,
})

VisualTab:CreateDropdown({
   Name = "ESP Show Mode",
   Options = {"Both", "Body", "Name"},
   CurrentOption = "Both",
   Flag = "ESPMode",
   Callback = function(Option)
      print("ESP Mode:", Option)
   end,
})

-- Player Section
local UtilitySection = PlayerTab:CreateSection("Utility")

PlayerTab:CreateToggle({
   Name = "Anti AFK",
   CurrentValue = false,
   Flag = "AntiAFK",
   Callback = function(Value)
      print("Anti AFK:", Value)
   end,
})

PlayerTab:CreateToggle({
   Name = "God Mode",
   CurrentValue = false,
   Flag = "GodMode",
   Callback = function(Value)
      print("God Mode:", Value)
   end,
})

local TeleportSection = PlayerTab:CreateSection("Teleport")

PlayerTab:CreateButton({
   Name = "📍 Copy My Position",
   Callback = function()
      print("Position copied!")
      Rayfield:Notify({
         Title = "Teleport",
         Content = "Position saved to clipboard",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

PlayerTab:CreateButton({
   Name = "🚀 Go to Saved Position",
   Callback = function()
      print("Teleporting...")
      Rayfield:Notify({
         Title = "Teleport",
         Content = "Teleported!",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

local PlayerDropdown = PlayerTab:CreateDropdown({
   Name = "Select Player",
   Options = {"Player1", "Player2", "Player3"},
   CurrentOption = "Player1",
   Flag = "TeleportPlayer",
   Callback = function(Option)
      print("Selected:", Option)
   end,
})

PlayerTab:CreateInput({
   Name = "Waypoint Name",
   PlaceholderText = "e.g. spawn",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      print("Waypoint name:", Text)
   end,
})

-- Welcome notification
Rayfield:Notify({
   Title = "Leon X Demo",
   Content = "Welcome! All features are working.",
   Duration = 5,
   Image = 4483362458,
})

print("Rayfield UI Demo loaded successfully!")
