-- Run this in your executor to dump plant attributes and fruit data
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local output = {}

local function log(msg)
    output[#output + 1] = msg
    print(msg)
end

log("=== GAG Plant Debug ===")

local gardens = workspace:FindFirstChild("Gardens")
if not gardens then
    log("ERROR: No Gardens folder!")
    writefile("GAG_PlantDebug.txt", table.concat(output, "\n"))
    return
end

-- Find our plot (closest one)
local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
local bestPlot, bestDist = nil, math.huge
for _, plot in ipairs(gardens:GetChildren()) do
    if plot.Name:find("Plot") then
        local zone = plot:FindFirstChild("Visual") and plot.Visual:FindFirstChild("GardenZonePart")
        if zone and hrp then
            local d = (zone.Position - hrp.Position).Magnitude
            if d < bestDist then bestDist = d; bestPlot = plot end
        end
    end
end

if not bestPlot then
    log("ERROR: No plot found!")
    writefile("GAG_PlantDebug.txt", table.concat(output, "\n"))
    return
end

log("Plot: " .. bestPlot.Name)

local plantsFolder = bestPlot:FindFirstChild("Plants")
if not plantsFolder then
    log("ERROR: No Plants folder!")
    writefile("GAG_PlantDebug.txt", table.concat(output, "\n"))
    return
end

log("Plants count: " .. #plantsFolder:GetChildren())

-- Dump ALL attributes of EVERY plant
for i, plant in ipairs(plantsFolder:GetChildren()) do
    if plant:IsA("Model") then
        log("\n--- Plant " .. i .. ": " .. plant.Name .. " ---")
        
        -- All attributes
        local attrs = plant:GetAttributes()
        local attrCount = 0
        for k, v in pairs(attrs) do
            attrCount = attrCount + 1
            log("  ATTR: " .. k .. " = " .. tostring(v))
        end
        if attrCount == 0 then
            log("  ATTR: (none)")
        end
        
        -- Children structure
        log("  Children:")
        for _, child in ipairs(plant:GetChildren()) do
            log("    " .. child.ClassName .. ": " .. child.Name)
            
            -- If it's a folder like "Fruits", dump its children too
            if child:IsA("Folder") or child:IsA("Model") then
                for _, sub in ipairs(child:GetChildren()) do
                    log("      " .. sub.ClassName .. ": " .. sub.Name)
                    -- Also dump attributes of sub-children
                    local subAttrs = sub:GetAttributes()
                    for k, v in pairs(subAttrs) do
                        log("        ATTR: " .. k .. " = " .. tostring(v))
                    end
                end
            end
            
            -- Check for ProximityPrompt
            if child:IsA("ProximityPrompt") then
                log("      ActionText: " .. tostring(child.ActionText))
                log("      ObjectText: " .. tostring(child.ObjectText))
            end
            
            -- Attributes on children
            local childAttrs = child:GetAttributes()
            for k, v in pairs(childAttrs) do
                log("    ATTR: " .. k .. " = " .. tostring(v))
            end
        end
    end
end

-- Also check if there's a Fruits folder directly on the plot
local plotFruits = bestPlot:FindFirstChild("Fruits")
if plotFruits then
    log("\n--- Plot-level Fruits folder ---")
    for _, f in ipairs(plotFruits:GetChildren()) do
        log("  " .. f.ClassName .. ": " .. f.Name)
        local fAttrs = f:GetAttributes()
        for k, v in pairs(fAttrs) do
            log("    ATTR: " .. k .. " = " .. tostring(v))
        end
    end
end

-- Check the Networking module for CollectFruit remote structure
log("\n=== Networking Module Check ===")
local ok, net = pcall(function()
    return require(game.ReplicatedStorage.SharedModules.Networking)
end)
if ok and net then
    log("Networking loaded OK")
    if net.Garden then
        log("net.Garden exists")
        for k, v in pairs(net.Garden) do
            log("  net.Garden." .. k .. " = " .. tostring(v) .. " (type: " .. type(v) .. ")")
        end
    else
        log("net.Garden is NIL")
        -- List all top-level keys
        for k, v in pairs(net) do
            log("  net." .. k .. " (type: " .. type(v) .. ")")
        end
    end
end

writefile("GAG_PlantDebug2.txt", table.concat(output, "\n"))
log("\n=== Output saved to GAG_PlantDebug2.txt ===")
