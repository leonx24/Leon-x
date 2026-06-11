-- Simple Rayfield Test
print("Starting Rayfield test...")

-- Load Rayfield
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success then
    print("ERROR: Rayfield failed to load:", Rayfield)
    return
end

print("Rayfield loaded successfully!")

-- Create Window
local windowSuccess, Window = pcall(function()
    return Rayfield:CreateWindow({
       Name = "Simple Test",
       LoadingTitle = "Loading...",
       LoadingSubtitle = "Test",
       ConfigurationSaving = { Enabled = false },
       Discord = { Enabled = false },
       KeySystem = false,
    })
end)

if not windowSuccess then
    print("ERROR: Window creation failed:", Window)
    return
end

print("Window created successfully!")

-- Create Tab
local tabSuccess, Tab = pcall(function()
    return Window:CreateTab("Test Tab", 4483362458)
end)

if not tabSuccess then
    print("ERROR: Tab creation failed:", Tab)
    return
end

print("Tab created successfully!")

-- Add elements
Tab:CreateSection("Test Section")
print("Section added!")

Tab:CreateToggle({
    Name = "Test Toggle",
    CurrentValue = false,
    Callback = function(v)
        print("Toggle:", v)
    end,
})
print("Toggle added!")

Tab:CreateButton({
    Name = "Test Button",
    Callback = function()
        print("Button clicked!")
        Rayfield:Notify({
            Title = "Success",
            Content = "Button works!",
            Duration = 2,
        })
    end,
})
print("Button added!")

Tab:CreateSlider({
    Name = "Test Slider",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        print("Slider:", v)
    end,
})
print("Slider added!")

print("ALL TESTS PASSED! UI should be visible now.")

Rayfield:Notify({
    Title = "Test Complete",
    Content = "All elements loaded!",
    Duration = 3,
})
