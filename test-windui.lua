-- Leon X Test - Wind UI Simple Version
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

-- Load Wind UI
print("Loading Wind UI...")
local _version = "1.6.64-fix"
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua"))()
print("Wind UI loaded:", WindUI)

-- Create Window
print("Creating window...")
local Window = WindUI:CreateWindow({
    Title = "Leon X Test",
    Icon = "zap",
    Author = "Test",
    Folder = "LeonXTest",
})
print("Window created:", Window)

-- Create Tab
print("Creating tab...")
local TestTab = Window:Tab({
    Title = "Test",
    Icon = "home",
})
print("Tab created:", TestTab)

-- Add Section
print("Adding section...")
TestTab:Section({ Title = "Test Section" })

-- Add Toggle
print("Adding toggle...")
local toggle = TestTab:Toggle({
    Title = "Test Toggle",
    Default = false,
    Callback = function(v)
        print("Toggle changed:", v)
        WindUI:Notify({
            Title = "Test",
            Content = "Toggle is " .. (v and "ON" or "OFF"),
            Duration = 2,
        })
    end
})
print("Toggle created:", toggle)

-- Add Button
print("Adding button...")
TestTab:Button({
    Title = "Test Button",
    Callback = function()
        print("Button clicked!")
        WindUI:Notify({
            Title = "Test",
            Content = "Button clicked!",
            Duration = 2,
        })
    end
})

-- Add Slider
print("Adding slider...")
TestTab:Slider({
    Title = "Test Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(v)
        print("Slider value:", v)
    end
})

print("Script loaded successfully!")
WindUI:Notify({
    Title = "Leon X Test",
    Content = "Loaded successfully!",
    Duration = 3,
})
