-- Leon X Test - Wind UI Alternative Load
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

print("Testing different Wind UI versions...")

-- Try Method 1: Latest release
local success1, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if success1 and WindUI then
    print("Method 1 SUCCESS: Latest release loaded")
else
    print("Method 1 FAILED:", WindUI)

    -- Try Method 2: Direct from repo
    local success2, WindUI2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)

    if success2 and WindUI2 then
        WindUI = WindUI2
        print("Method 2 SUCCESS: Repo version loaded")
    else
        print("Method 2 FAILED:", WindUI2)

        -- Try Method 3: Old example
        local success3, WindUI3 = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()
        end)

        if success3 and WindUI3 then
            WindUI = WindUI3
            print("Method 3 SUCCESS: Main.lua loaded")
        else
            print("Method 3 FAILED:", WindUI3)
            print("ALL METHODS FAILED - Wind UI cannot be loaded")
            return
        end
    end
end

-- If we got here, WindUI loaded successfully
print("Wind UI loaded successfully, type:", typeof(WindUI))

-- Try creating window
local windowSuccess, windowResult = pcall(function()
    return WindUI:CreateWindow({
        Title = "Leon X Test",
        Author = "Test",
    })
end)

if windowSuccess then
    print("Window created successfully!")
    local Window = windowResult

    -- Try creating tab
    local tabSuccess, tabResult = pcall(function()
        return Window:Tab({
            Title = "Test",
            Icon = "home",
        })
    end)

    if tabSuccess then
        print("Tab created successfully!")
        local Tab = tabResult

        -- Try adding elements
        pcall(function()
            Tab:Button({
                Title = "Test Button",
                Callback = function()
                    print("Button works!")
                end
            })
        end)

        print("Setup complete!")
    else
        print("Tab creation failed:", tabResult)
    end
else
    print("Window creation failed:", windowResult)
end
