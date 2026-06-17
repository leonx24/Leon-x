-- Leon X | Grow a Garden 2
-- PlaceId: 97598239454123
-- Auto Collect, Auto Sell, Auto Buy Seed, Auto Steal, Auto Fling (using game remotes)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UIS               = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local GAG = {}
GAG.Name = "Grow a Garden 2"
GAG.PlaceIds = { 97598239454123 }
GAG.Enabled = false

-- Feature states
GAG.AutoCollect       = false
GAG.AutoCollectAndSell = false
GAG.AutoSell          = false
GAG.AutoBuySeed   = false
GAG.AutoBuyAll    = false
GAG.AutoSeedEvent = false
GAG.SelectedSeed  = {} -- multi-select seeds to auto-buy
GAG.PriceESP      = false
GAG.AutoBuyGear   = false
GAG.SelectedGear  = {} -- multi-select gears to auto-buy
GAG.AutoSteal     = false
GAG.AutoFling     = false
GAG.FlingRadius   = 20

local connections = {}
local net = nil -- Networking module (loaded in Init)

local function disconnect(key)
    if connections[key] then
        pcall(function() connections[key]:Disconnect() end)
        connections[key] = nil
    end
end

local function disconnectAll()
    for k, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
end

-- ── Helpers ─────────────────────────────────────────────────────────────────
local function getHRP()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ── Garden Bounds Detection ─────────────────────────────────────────────────
-- Finds the player's own garden plot and stores its bounds
local gardenBounds = nil -- {minX, maxX, minZ, maxZ}

local function detectGardenBounds()
    gardenBounds = nil
    pcall(function()
        local gardens = workspace:FindFirstChild("Gardens")
        if not gardens then return end

        local hrp = getHRP()
        if not hrp then return end
        local playerPos = hrp.Position

        -- Find the closest plot to the player
        local bestPlot = nil
        local bestDist = math.huge

        for _, plot in ipairs(gardens:GetChildren()) do
            if plot.Name:find("Plot") then
                local zonePart = plot:FindFirstChild("Visual")
                    and plot.Visual:FindFirstChild("GardenZonePart")
                if zonePart then
                    local dist = (zonePart.Position - playerPos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestPlot = zonePart
                    end
                end
            end
        end

        if bestPlot then
            local pos = bestPlot.Position
            local size = bestPlot.Size
            -- Add generous padding (20 studs beyond the zone part)
            local pad = 20
            gardenBounds = {
                minX = pos.X - (size.X / 2) - pad,
                maxX = pos.X + (size.X / 2) + pad,
                minZ = pos.Z - (size.Z / 2) - pad,
                maxZ = pos.Z + (size.Z / 2) + pad,
            }
            print(string.format("[Leon X] Garden bounds: X[%.0f-%.0f] Z[%.0f-%.0f]",
                gardenBounds.minX, gardenBounds.maxX, gardenBounds.minZ, gardenBounds.maxZ))
        end
    end)
end

local function isInGarden(pos)
    -- If no bounds detected, allow all (fallback)
    if not gardenBounds then return true end
    return pos.X >= gardenBounds.minX and pos.X <= gardenBounds.maxX
       and pos.Z >= gardenBounds.minZ and pos.Z <= gardenBounds.maxZ
end

-- ── Auto Sell (fires NPCS.SellAll remote) ──────────────────────────────────
local function startAutoSell()
    disconnect("sell")

    local actionTimer = 0
    local SELL_INTERVAL = 1 -- sell every 1 second

    connections.sell = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoSell then return end

        actionTimer = actionTimer + dt
        if actionTimer < SELL_INTERVAL then return end
        actionTimer = 0

        -- Sell all fruits using the game's remote (works from anywhere)
        if net and net.NPCS and net.NPCS.SellAll then
            pcall(function() net.NPCS.SellAll:Fire() end)
        end
    end)
end

-- ── Auto Buy Seed (uses SeedShop.PurchaseSeed remote) ──────────────────────
-- Dynamically gets seed names from game assets
local seedNames = {}

local function getSeedNames()
    seedNames = {}
    pcall(function()
        local plants = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Plants")
        for _, plant in ipairs(plants:GetChildren()) do
            seedNames[#seedNames + 1] = plant.Name
        end
    end)
    if #seedNames == 0 then
        seedNames = {
            "Carrot", "Tomato", "Strawberry", "Blueberry", "Corn",
            "Watermelon", "Pumpkin", "Wheat", "Potato", "Onion",
            "Grape", "Apple", "Banana", "Pepper", "Lettuce",
        }
    end
    return seedNames
end

-- Buy selected seeds (multi-select support)
local function startAutoBuySeed()
    disconnect("buy")

    local actionTimer = 0
    local BUY_INTERVAL = 1
    local seedIndex = 1

    connections.buy = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoBuySeed then return end
        if not GAG.SelectedSeed or #GAG.SelectedSeed == 0 then return end

        actionTimer = actionTimer + dt
        if actionTimer < BUY_INTERVAL then return end
        actionTimer = 0

        if net and net.SeedShop and net.SeedShop.PurchaseSeed then
            -- Cycle through selected seeds
            local seed = GAG.SelectedSeed[seedIndex]
            if seed then
                pcall(function() net.SeedShop.PurchaseSeed:Fire(seed) end)
                seedIndex = seedIndex + 1
                if seedIndex > #GAG.SelectedSeed then seedIndex = 1 end
            end
        end
    end)
end

-- Buy ALL seeds at once (fires all seed purchases in one tick)
local function startAutoBuyAll()
    disconnect("buyall")

    local actionTimer = 0
    local BUY_ALL_INTERVAL = 2

    connections.buyall = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoBuyAll then return end

        actionTimer = actionTimer + dt
        if actionTimer < BUY_ALL_INTERVAL then return end
        actionTimer = 0

        if not net or not net.SeedShop or not net.SeedShop.PurchaseSeed then return end

        -- Fire ALL seed purchases at once
        for _, seedName in ipairs(seedNames) do
            pcall(function() net.SeedShop.PurchaseSeed:Fire(seedName) end)
        end
    end)
end

-- ── Gear Auto-Buy ────────────────────────────────────────────────────────────
-- Dynamically gets gear names from game assets
local gearNames = {}

local function getGearNames()
    gearNames = {}
    pcall(function()
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        if not assets then return end
        -- Enumerate from all gear-related folders
        local gearFolders = {"WateringCans", "Sprinklers"}
        for _, folderName in ipairs(gearFolders) do
            local folder = assets:FindFirstChild(folderName)
            if folder then
                for _, item in ipairs(folder:GetChildren()) do
                    gearNames[#gearNames + 1] = item.Name
                end
            end
        end
    end)
    -- Add known individual tools
    local knownGear = {
        "Shovel", "Trowel", "Rake", "Crowbar",
        "Power Washer", "Rainbow Carpet",
    }
    for _, name in ipairs(knownGear) do
        local found = false
        for _, existing in ipairs(gearNames) do
            if existing == name then found = true; break end
        end
        if not found then gearNames[#gearNames + 1] = name end
    end
    return gearNames
end

-- Buy selected gears (multi-select support)
local function startAutoBuyGear()
    disconnect("buygear")

    local actionTimer = 0
    local BUY_INTERVAL = 1
    local gearIndex = 1

    connections.buygear = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoBuyGear then return end
        if not GAG.SelectedGear or #GAG.SelectedGear == 0 then return end

        actionTimer = actionTimer + dt
        if actionTimer < BUY_INTERVAL then return end
        actionTimer = 0

        -- Use the confirmed GearShop.PurchaseGear remote
        if net and net.GearShop and net.GearShop.PurchaseGear then
            local gear = GAG.SelectedGear[gearIndex]
            if gear then
                pcall(function() net.GearShop.PurchaseGear:Fire(gear) end)
                gearIndex = gearIndex + 1
                if gearIndex > #GAG.SelectedGear then gearIndex = 1 end
            end
        end
    end)
end

-- ── Auto Collect (own garden fruits via correct remote pattern) ─────────────
local cachedOwnerPlot = nil

local function getOwnerPlot()
    if cachedOwnerPlot and cachedOwnerPlot.Parent then return cachedOwnerPlot end
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return nil end

    -- Check by name/UserId first
    for _, plot in ipairs(gardens:GetChildren()) do
        if plot.Name:find(lp.Name) or plot.Name:find(tostring(lp.UserId)) then
            cachedOwnerPlot = plot
            return plot
        end
    end
    -- Fallback: closest plot
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, plot in ipairs(gardens:GetChildren()) do
        if plot.Name:find("Plot") then
            local zone = plot:FindFirstChild("Visual")
                and plot.Visual:FindFirstChild("GardenZonePart")
            if zone then
                local d = (zone.Position - hrp.Position).Magnitude
                if d < bestDist then bestDist = d; best = plot end
            end
        end
    end
    cachedOwnerPlot = best
    return best
end

local function fireCollectFruit(plantId, fruitId)
    if not net or not net.Garden or not net.Garden.CollectFruit then return false end
    return pcall(function()
        net.Garden.CollectFruit:Fire(plantId, fruitId or "")
    end)
end

local function collectAllFruits()
    local plot = getOwnerPlot()
    if not plot then return 0 end
    local plantsFolder = plot:FindFirstChild("Plants")
    if not plantsFolder then return 0 end

    local count = 0
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        if not GAG.AutoCollect and not GAG.AutoCollectAndSell then break end
        if plant:IsA("Model") then
            local plantId = plant:GetAttribute("PlantId")
            if plantId then
                local fruitsFolder = plant:FindFirstChild("Fruits")
                if fruitsFolder then
                    for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                        if fruit:IsA("Model") or fruit:IsA("BasePart") then
                            local fruitId = fruit:GetAttribute("FruitId") or ""
                            if fruitId ~= "" then
                                if fireCollectFruit(plantId, fruitId) then
                                    count = count + 1
                                end
                                task.wait(0.01)
                            end
                        end
                    end
                end
            end
        end
    end
    return count
end

local function startAutoCollect()
    disconnect("collect")

    local actionTimer = 0
    local ACTION_INTERVAL = 0.5

    connections.collect = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled then return end
        if not GAG.AutoCollect and not GAG.AutoCollectAndSell then return end

        actionTimer = actionTimer + dt
        if actionTimer < ACTION_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            local collected = collectAllFruits()

            -- Auto sell after collecting if enabled
            if GAG.AutoCollectAndSell and collected > 0 then
                if net and net.NPCS and net.NPCS.SellAll then
                    pcall(function() net.NPCS.SellAll:Fire() end)
                end
            end
        end)
    end)
end

-- ── Auto Steal (steal fruits from other gardens) ────────────────────────────
-- Uses CollectFruit remote with correct PlantId + FruitId from Fruits folder
local stolenPlants = {} -- track visited plants to avoid getting stuck

local function startAutoSteal()
    disconnect("steal")
    detectGardenBounds()
    stolenPlants = {} -- reset visited list

    local actionTimer = 0
    local ACTION_INTERVAL = 0.8 -- faster cycling
    local MAX_PLANTS_PER_TICK = 3 -- process multiple plants per tick

    connections.steal = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoSteal then return end

        actionTimer = actionTimer + dt
        if actionTimer < ACTION_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            local gardens = workspace:FindFirstChild("Gardens")
            if not gardens then return end

            -- Refresh bounds periodically
            if not gardenBounds then detectGardenBounds() end

            local processed = 0
            local myUserId = lp.UserId

            for _, plot in ipairs(gardens:GetChildren()) do
                if processed >= MAX_PLANTS_PER_TICK or not GAG.AutoSteal then break end

                -- Skip owner's own garden by checking plot name or UserId attribute
                local isOwnPlot = false
                if plot.Name:find(lp.Name) or plot.Name:find(tostring(myUserId)) then
                    isOwnPlot = true
                end
                -- Also check UserId attribute on the plot
                if not isOwnPlot then
                    local plotUserId = plot:GetAttribute("UserId")
                    if plotUserId and plotUserId == myUserId then
                        isOwnPlot = true
                    end
                end
                -- Also check the cached owner plot
                if not isOwnPlot and cachedOwnerPlot and plot == cachedOwnerPlot then
                    isOwnPlot = true
                end

                if not isOwnPlot then
                    local plantsFolder = plot:FindFirstChild("Plants")
                    if plantsFolder then
                        for _, plant in ipairs(plantsFolder:GetChildren()) do
                            if processed >= MAX_PLANTS_PER_TICK or not GAG.AutoSteal then break end
                            if plant:IsA("Model") then
                                local plantId = plant:GetAttribute("PlantId")
                                if plantId and not stolenPlants[plantId] then
                                    -- Get plant position
                                    local pos
                                    local harvestPart = plant:FindFirstChild("HarvestPart")
                                    if harvestPart and harvestPart:IsA("BasePart") then
                                        pos = harvestPart.Position
                                    else
                                        pcall(function() pos = plant:GetPivot().Position end)
                                    end

                                    -- Only steal from OTHER gardens (not own bounds)
                                    if pos and not isInGarden(pos) then
                                        -- Check Fruits folder for actual fruits
                                        local fruitsFolder = plant:FindFirstChild("Fruits")
                                        if fruitsFolder and #fruitsFolder:GetChildren() > 0 then
                                            -- Mark as visited
                                            stolenPlants[plantId] = true
                                            processed = processed + 1

                                            -- Teleport to the fruit
                                            pcall(function()
                                                hrp.CFrame = CFrame.new(pos.X, pos.Y + 1, pos.Z)
                                            end)
                                            task.wait(0.2)

                                            -- Fire CollectFruit for each fruit
                                            for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                                                if fruit:IsA("Model") or fruit:IsA("BasePart") then
                                                    local fruitId = fruit:GetAttribute("FruitId") or ""
                                                    if fruitId ~= "" then
                                                        fireCollectFruit(plantId, fruitId)
                                                        task.wait(0.03)
                                                    end
                                                end
                                            end

                                            -- Also trigger ProximityPrompt if present
                                            local prompt
                                            for _, desc in ipairs(plant:GetDescendants()) do
                                                if desc:IsA("ProximityPrompt") then
                                                    prompt = desc; break
                                                end
                                            end
                                            if prompt and prompt.Enabled then
                                                pcall(function() prompt:InputHoldBegin() end)
                                                task.wait(0.3)
                                                pcall(function()
                                                    if prompt and prompt.Parent then
                                                        prompt:InputHoldEnd()
                                                    end
                                                end)
                                            end

                                            -- Only try Steal remotes if plant belongs to another player
                                            local plantUserId = plant:GetAttribute("UserId")
                                            if plantUserId and plantUserId ~= lp.UserId and net and net.Steal then
                                                pcall(function()
                                                    if net.Steal.BeginSteal then
                                                        net.Steal.BeginSteal:Fire(plant)
                                                    end
                                                end)
                                                task.wait(0.5)
                                                pcall(function()
                                                    if net.Steal.CompleteSteal then
                                                        net.Steal.CompleteSteal:Fire(plant)
                                                    end
                                                end)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- If we processed nothing (all visited or no fruits), reset the visited list
            if processed == 0 then
                stolenPlants = {}
            end
        end)
    end)
end

-- ── Auto Fling (push nearby players away from you) ──────────────────────
local function startAutoFling()
    disconnect("fling")

    connections.fling = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoFling then return end

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end
            local myPos = hrp.Position

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= lp then
                    local char = player.Character
                    if char then
                        local theirHRP = char:FindFirstChild("HumanoidRootPart")
                        local theirHum = char:FindFirstChildOfClass("Humanoid")
                        if theirHRP and theirHum and theirHum.Health > 0 then
                            local dist = (theirHRP.Position - myPos).Magnitude
                            if dist < GAG.FlingRadius then
                                -- Push them away from you with high velocity
                                local dir = (theirHRP.Position - myPos).Unit
                                if dir.Magnitude < 0.01 then
                                    dir = Vector3.new(1, 0.5, 0) -- fallback direction
                                end
                                pcall(function()
                                    theirHRP.AssemblyLinearVelocity = dir * 800 + Vector3.new(0, 300, 0)
                                    theirHRP.AssemblyAngularVelocity = Vector3.new(
                                        math.random(-50, 50),
                                        math.random(-50, 50),
                                        math.random(-50, 50)
                                    )
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end)
end

-- ── Auto Seed Event (hunts falling rainbow/gold/event seeds) ────────────────
-- Watches workspace for new seed objects and teleports to collect them
local seedEventKeywords = {
    "seed", "rainbow", "gold", "event", "meteor", "star", "drop",
    "pack", "chest", "loot", "reward", "crate", "gift"
}

-- Plant/fruit names that appear as falling seed events
local plantNames = {}
local function loadPlantNames()
    pcall(function()
        local plants = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Plants", 2)
        if plants then
            for _, plant in ipairs(plants:GetChildren()) do
                plantNames[#plantNames + 1] = plant.Name:lower()
            end
        end
    end)
    -- Also add common crop names as fallback
    local fallback = {"corn", "pineapple", "wheat", "carrot", "tomato", "strawberry", "blueberry", "pumpkin"}
    for _, name in ipairs(fallback) do
        local found = false
        for _, existing in ipairs(plantNames) do
            if existing == name then found = true; break end
        end
        if not found then plantNames[#plantNames + 1] = name end
    end
end

local function isSeedEventObject(obj)
    -- Check if it's a direct child of workspace (falling seeds appear here)
    local isDirectChild = (obj.Parent == workspace)
    if not isDirectChild then
        -- Also check if it's a Model/Part in workspace with seed-related name
        local parentName = obj.Parent and obj.Parent.Name:lower() or ""
        if not parentName:find("workspace") then
            -- Not a seed event object
            return false
        end
    end

    local name = obj.Name:lower()

    -- Check if name matches a plant/fruit (falling seeds use plant names)
    for _, plantName in ipairs(plantNames) do
        if name == plantName or name:find(plantName) then
            -- Only count if it has FruitAnchor or Base part (indicates seed event)
            if obj:IsA("Model") then
                if obj:FindFirstChild("FruitAnchor") or obj:FindFirstChild("Base") then
                    return true
                end
            end
        end
    end

    -- Check keywords
    for _, kw in ipairs(seedEventKeywords) do
        if name:find(kw) then return true end
    end

    -- Check tags
    local ok, tags = pcall(function() return CollectionService:GetTags(obj) end)
    if ok then
        for _, tag in ipairs(tags) do
            local tagLower = tag:lower()
            if tagLower:find("seed") or tagLower:find("event") or tagLower:find("drop") then
                return true
            end
        end
    end

    return false
end

local function startAutoSeedEvent()
    disconnect("seedevent")
    disconnect("seedwatcher")
    detectGardenBounds()
    loadPlantNames() -- load plant names for detection

    local knownObjects = {}
    local actionTimer = 0
    local SCAN_INTERVAL = 0.3 -- faster scan for falling seeds

    -- Watch for new objects added to workspace (instant detection)
    connections.seedwatcher = workspace.ChildAdded:Connect(function(obj)
        if not GAG.Enabled or not GAG.AutoSeedEvent then return end
        if not obj:IsA("BasePart") and not obj:IsA("Model") then return end
        if knownObjects[obj] then return end

        if isSeedEventObject(obj) then
            knownObjects[obj] = true
            print("[Leon X] Seed event detected: " .. obj.Name)
            -- Clean up when object is removed
            obj.AncestryChanged:Connect(function()
                if not obj:IsDescendantOf(workspace) then
                    knownObjects[obj] = nil
                end
            end)
        end
    end)

    -- Periodically scan direct workspace children (not all descendants)
    connections.seedevent = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoSeedEvent then return end

        actionTimer = actionTimer + dt
        if actionTimer < SCAN_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- Only check direct children of workspace (where seed events appear)
            for _, obj in ipairs(workspace:GetChildren()) do
                if (obj:IsA("BasePart") or obj:IsA("Model")) and isSeedEventObject(obj) then
                    -- Get position (prefer FruitAnchor if exists)
                    local pos
                    local anchor = obj:IsA("Model") and obj:FindFirstChild("FruitAnchor")
                    if anchor and anchor:IsA("BasePart") then
                        pos = anchor.Position
                    elseif obj:IsA("BasePart") then
                        pos = obj.Position
                    elseif obj:IsA("Model") then
                        pos = obj:GetPivot().Position
                    end

                    if pos then
                        -- Teleport to the seed (clamp Y)
                        local currentY = hrp.Position.Y
                        local targetY = math.clamp(pos.Y + 2, currentY - 15, currentY + 15)
                        pcall(function() hrp.CFrame = CFrame.new(pos.X, targetY, pos.Z) end)
                        task.wait(0.1)

                        -- Try ProximityPrompt
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
                        if not prompt and obj:IsA("Model") then
                            for _, child in ipairs(obj:GetDescendants()) do
                                if child:IsA("ProximityPrompt") then
                                    prompt = child
                                    break
                                end
                            end
                        end
                        if prompt then
                            pcall(function() prompt:InputHoldBegin() end)
                            task.wait(0.1)
                            pcall(function() prompt:InputHoldEnd() end)
                        end

                        -- Try ClickDetector
                        local click = obj:FindFirstChildWhichIsA("ClickDetector")
                        if not click and obj:IsA("Model") then
                            for _, child in ipairs(obj:GetDescendants()) do
                                if child:IsA("ClickDetector") then
                                    click = child
                                    break
                                end
                            end
                        end
                        if click then
                            pcall(function() fireclickdetector(click) end)
                        end

                        -- Try touching the Base part
                        local base = obj:IsA("Model") and obj:FindFirstChild("Base")
                        if base and base:IsA("BasePart") then
                            pcall(function()
                                hrp.CFrame = base.CFrame
                            end)
                        end
                    end
                end
            end
        end)
    end)
end

-- ── Price ESP (shows plant name + weight + price above each crop) ─────────────
local espObjects = {} -- track created BillboardGuis
local fruitPriceCache = {} -- cache prices to avoid repeated lookups

local function getFruitPrice(plantModel)
    -- Try to get price from plant model attributes first
    local price = plantModel:GetAttribute("Price") or plantModel:GetAttribute("Value")
    if price and type(price) == "number" then return price end

    -- Try to get price from ReplicatedStorage plant assets
    local seedName = plantModel:GetAttribute("SeedName")
    if not seedName or type(seedName) ~= "string" or #seedName == 0 then return nil end

    -- Check cache first
    if fruitPriceCache[seedName] then return fruitPriceCache[seedName] end

    -- Look up in game assets
    pcall(function()
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        if not assets then return end

        -- Check Plants folder
        local plants = assets:FindFirstChild("Plants")
        if plants then
            local plantAsset = plants:FindFirstChild(seedName)
            if plantAsset then
                local p = plantAsset:GetAttribute("Price") or plantAsset:GetAttribute("Value")
                    or plantAsset:GetAttribute("SellPrice") or plantAsset:GetAttribute("BasePrice")
                if p and type(p) == "number" then
                    fruitPriceCache[seedName] = p
                    return
                end
                -- Check for Price/Value in children
                for _, child in ipairs(plantAsset:GetChildren()) do
                    if child:IsA("ValueBase") or child:IsA("IntValue") or child:IsA("NumberValue") then
                        if child.Name:lower():find("price") or child.Name:lower():find("value") then
                            fruitPriceCache[seedName] = child.Value
                            return
                        end
                    end
                end
            end
        end

        -- Check for a Prices/Values module
        local pricesModule = assets:FindFirstChild("Prices") or assets:FindFirstChild("FruitPrices")
            or ReplicatedStorage:FindFirstChild("Prices") or ReplicatedStorage:FindFirstChild("FruitPrices")
        if pricesModule and pricesModule:IsA("ModuleScript") then
            local prices = require(pricesModule)
            if type(prices) == "table" then
                local p = prices[seedName] or prices[seedName:lower()]
                if p and type(p) == "number" then
                    fruitPriceCache[seedName] = p
                end
            end
        end
    end)

    return fruitPriceCache[seedName]
end

local function getPlantDisplayName(plantModel)
    -- GAG uses SeedName for the real plant name, Mutation for special types
    local seedName = plantModel:GetAttribute("SeedName")
    local mutation = plantModel:GetAttribute("Mutation")
    
    if seedName and type(seedName) == "string" and #seedName > 0 then
        if mutation and type(mutation) == "string" and #mutation > 0 then
            return mutation .. " " .. seedName
        end
        return seedName
    end

    -- Fallback: check CorePartName on first fruit
    local fruits = plantModel:FindFirstChild("Fruits")
    if fruits then
        for _, fruit in ipairs(fruits:GetChildren()) do
            local coreName = fruit:GetAttribute("CorePartName")
            if coreName and type(coreName) == "string" and #coreName > 0 then
                local fruitMut = fruit:GetAttribute("Mutation")
                if fruitMut and type(fruitMut) == "string" and #fruitMut > 0 then
                    return fruitMut .. " " .. coreName
                end
                return coreName
            end
        end
    end

    -- Last resort: model name if not UUID
    local name = plantModel.Name
    if #name < 30 and not name:match("^%d+_") and not name:match("%x%x%x%x%x%x%x%x%-") then
        return name
    end

    return "Plant"
end

local function createPriceESP(plantModel)
    -- Skip if already has ESP
    if plantModel:FindFirstChild("LeonX_PriceESP") then return end

    -- Get plant display name (resolve UUID -> real name)
    local plantName = getPlantDisplayName(plantModel)
    local info = ""
    local priceText = ""

    -- Build info line: mutation + growth progress + fruit count
    pcall(function()
        local mutation = plantModel:GetAttribute("Mutation")
        if mutation and type(mutation) == "string" and #mutation > 0 then
            info = "[" .. mutation .. "]"
        end

        local age = plantModel:GetAttribute("Age")
        local maxAge = plantModel:GetAttribute("MaxAge")
        if age and maxAge and type(age) == "number" and type(maxAge) == "number" then
            info = info .. (info ~= "" and " " or "") .. math.floor(age) .. "/" .. maxAge
        end

        local fruits = plantModel:FindFirstChild("Fruits")
        if fruits then
            local fruitCount = #fruits:GetChildren()
            if fruitCount > 0 then
                info = info .. (info ~= "" and " | " or "") .. fruitCount .. " fruits"
            end
        end

        -- Get price
        local price = getFruitPrice(plantModel)
        if price then
            priceText = "$" .. tostring(price)
        end
    end)

    -- Get position (prefer HarvestPart or PrimaryPart)
    local pos
    local harvestPart = plantModel:FindFirstChild("HarvestPart")
    if harvestPart and harvestPart:IsA("BasePart") then
        pos = harvestPart.Position + Vector3.new(0, 5, 0)
    elseif plantModel:IsA("Model") then
        local pp = plantModel.PrimaryPart or plantModel:FindFirstChildWhichIsA("BasePart")
        if pp then pos = pp.Position + Vector3.new(0, 5, 0) end
    end
    if not pos then return end

    -- Debug: if we couldn't find the name, log it
    if plantName == "Plant" then
        pcall(function()
            local debugAttrs = {}
            local attrs = plantModel:GetAttributes()
            for k, v in pairs(attrs) do
                debugAttrs[#debugAttrs + 1] = k .. "=" .. tostring(v):sub(1, 20)
            end
            local fruits = plantModel:FindFirstChild("Fruits")
            if fruits then
                for _, f in ipairs(fruits:GetChildren()) do
                    debugAttrs[#debugAttrs + 1] = "Fruit:" .. f.Name
                end
            end
            print("[Leon X ESP] Unknown plant - attrs: " .. table.concat(debugAttrs, ", "))
        end)
    end

    -- Build display text
    local displayText = plantName
    if info ~= "" then
        displayText = displayText .. "\n" .. info
    end
    if priceText ~= "" then
        displayText = displayText .. "\n" .. priceText
    end

    -- Create BillboardGui
    local gui = Instance.new("BillboardGui")
    gui.Name = "LeonX_PriceESP"
    gui.Size = UDim2.new(0, 140, 0, 40)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = harvestPart or plantModel.PrimaryPart or plantModel:FindFirstChildWhichIsA("BasePart")
    gui.Parent = plantModel

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.4
    label.TextColor3 = Color3.fromRGB(255, 255, 100)
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.Text = displayText
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label

    espObjects[gui] = true
end

local function startPriceESP()
    disconnect("priceesp")
    
    -- Initial scan
    pcall(function()
        local gardens = workspace:FindFirstChild("Gardens")
        if not gardens then return end
        
        for _, plot in ipairs(gardens:GetChildren()) do
            local plants = plot:FindFirstChild("Plants")
            if plants then
                for _, plant in ipairs(plants:GetChildren()) do
                    if plant:IsA("Model") then
                        createPriceESP(plant)
                    end
                end
                
                -- Watch for new plants
                plants.ChildAdded:Connect(function(plant)
                    if GAG.PriceESP and plant:IsA("Model") then
                        task.wait(0.5)
                        createPriceESP(plant)
                    end
                end)
            end
        end
    end)
end

local function stopPriceESP()
    disconnect("priceesp")
    -- Remove all ESP Guis
    for gui, _ in pairs(espObjects) do
        pcall(function() gui:Destroy() end)
    end
    espObjects = {}
    
    -- Also remove from workspace
    pcall(function()
        local gardens = workspace:FindFirstChild("Gardens")
        if not gardens then return end
        for _, plot in ipairs(gardens:GetChildren()) do
            local plants = plot:FindFirstChild("Plants")
            if plants then
                for _, plant in ipairs(plants:GetChildren()) do
                    local esp = plant:FindFirstChild("LeonX_PriceESP")
                    if esp then esp:Destroy() end
                end
            end
        end
    end)
end

-- ── Module Interface ────────────────────────────────────────────────────────
function GAG:Init()
    task.wait(1)
    -- Load the game's Networking module
    pcall(function()
        net = require(ReplicatedStorage:WaitForChild("SharedModules", 5):WaitForChild("Networking", 5))
    end)
    if net then
        print("[Leon X] GAG Networking loaded successfully")
    else
        print("[Leon X] WARNING: Could not load GAG Networking module")
    end
    -- Pre-load seed and gear names
    pcall(function() getSeedNames() end)
    pcall(function() getGearNames() end)
    print("[Leon X] GAG Seeds found: " .. #seedNames .. ", Gear found: " .. #gearNames)
end

function GAG:Enable()
    self.Enabled = true
end

function GAG:Disable()
    self.Enabled = false
    self.AutoCollect       = false
    self.AutoCollectAndSell = false
    self.AutoSell          = false
    self.AutoBuySeed   = false
    self.AutoBuyAll    = false
    self.AutoSeedEvent = false
    self.PriceESP      = false
    self.AutoSteal     = false
    self.AutoFling     = false
    stopPriceESP()
    disconnectAll()
end

-- ── Wire UI ─────────────────────────────────────────────────────────────────
function GAG:WireUI(tab, extras)
    extras = extras or {}
    local Fly   = extras.Fly
    local Speed = extras.Speed

    -- ══ FARMING ═══════════════════════════════════════════════════════════
    tab:Section({ Title = "Farming" })

    tab:Toggle({
        Title    = "Auto Collect + Sell",
        Flag     = "GAG_AutoCollectAndSell",
        Default  = false,
        Callback = function(v)
            GAG.AutoCollectAndSell = v
            if v then
                GAG.Enabled = true
                startAutoCollect()
            else
                disconnect("collect")
            end
        end
    })

    tab:Toggle({
        Title    = "Auto Collect Only",
        Flag     = "GAG_AutoCollect",
        Default  = false,
        Callback = function(v)
            GAG.AutoCollect = v
            if v then
                GAG.Enabled = true
                startAutoCollect()
            else
                disconnect("collect")
            end
        end
    })

    tab:Toggle({
        Title    = "Auto Sell Only",
        Flag     = "GAG_AutoSell",
        Default  = false,
        Callback = function(v)
            GAG.AutoSell = v
            if v then
                GAG.Enabled = true
                startAutoSell()
            else
                disconnect("sell")
            end
        end
    })

    tab:Toggle({
        Title    = "Auto Seed Event (Rainbow/Gold)",
        Flag     = "GAG_AutoSeedEvent",
        Default  = false,
        Callback = function(v)
            GAG.AutoSeedEvent = v
            if v then
                GAG.Enabled = true
                startAutoSeedEvent()
            else
                disconnect("seedevent")
                disconnect("seedwatcher")
            end
        end
    })

    -- ══ SHOP ═══════════════════════════════════════════════════════════════
    tab:Section({ Title = "Shop" })

    tab:Dropdown({
        Title    = "Select Seeds (Multi)",
        Flag     = "GAG_SelectedSeeds",
        Default  = {},
        Values   = seedNames,
        Multi    = true,
        SearchBarEnabled = true,
        Callback = function(v)
            GAG.SelectedSeed = type(v) == "table" and v or {v}
        end
    })

    tab:Toggle({
        Title    = "Auto Buy Selected Seeds",
        Flag     = "GAG_AutoBuySeed",
        Default  = false,
        Callback = function(v)
            GAG.AutoBuySeed = v
            if v then
                GAG.Enabled = true
                startAutoBuySeed()
            else
                disconnect("buy")
            end
        end
    })

    tab:Toggle({
        Title    = "Auto Buy ALL Seeds",
        Flag     = "GAG_AutoBuyAll",
        Default  = false,
        Callback = function(v)
            GAG.AutoBuyAll = v
            if v then
                GAG.Enabled = true
                startAutoBuyAll()
            else
                disconnect("buyall")
            end
        end
    })

    tab:Dropdown({
        Title    = "Select Gear (Multi)",
        Flag     = "GAG_SelectedGear",
        Default  = {},
        Values   = gearNames,
        Multi    = true,
        SearchBarEnabled = true,
        Callback = function(v)
            GAG.SelectedGear = type(v) == "table" and v or {v}
        end
    })

    tab:Toggle({
        Title    = "Auto Buy Selected Gear",
        Flag     = "GAG_AutoBuyGear",
        Default  = false,
        Callback = function(v)
            GAG.AutoBuyGear = v
            if v then
                GAG.Enabled = true
                startAutoBuyGear()
            else
                disconnect("buygear")
            end
        end
    })

    -- ══ PVP / STEAL ══════════════════════════════════════════════════════
    tab:Section({ Title = "PvP / Steal" })

    tab:Toggle({
        Title    = "Auto Steal (Other Gardens)",
        Flag     = "GAG_AutoSteal",
        Default  = false,
        Callback = function(v)
            GAG.AutoSteal = v
            if v then
                GAG.Enabled = true
                startAutoSteal()
            else
                disconnect("steal")
            end
        end
    })

    tab:Toggle({
        Title    = "Auto Fling (Push Players)",
        Flag     = "GAG_AutoFling",
        Default  = false,
        Callback = function(v)
            GAG.AutoFling = v
            if v then
                GAG.Enabled = true
                startAutoFling()
            else
                disconnect("fling")
            end
        end
    })

    tab:Slider({
        Title    = "Fling Radius",
        Flag     = "GAG_FlingRadius",
        Value    = { Min = 5, Max = 50, Default = 20 },
        Step     = 1,
        Callback = function(v) GAG.FlingRadius = v end
    })

    tab:Toggle({
        Title    = "Anti Fling",
        Flag     = "GAG_AntiFling",
        Default  = false,
        Callback = function(v)
            local AntiFling = extras.AntiFling
            if AntiFling then
                pcall(function()
                    if v then AntiFling:Enable() else AntiFling:Disable() end
                end)
            end
        end
    })

    -- ══ VISUAL ═══════════════════════════════════════════════════════════
    tab:Section({ Title = "Visual" })

    tab:Toggle({
        Title    = "Plant ESP (Labels + Info)",
        Flag     = "GAG_PriceESP",
        Default  = false,
        Callback = function(v)
            GAG.PriceESP = v
            if v then
                startPriceESP()
            else
                stopPriceESP()
            end
        end
    })

    -- ══ PLAYER SIDEBAR ═══════════════════════════════════════════════════
    local pTab = extras.PlayerTab or tab

    if Speed then
        pTab:Section({ Title = "Movement" })

        pTab:Toggle({
            Title    = "Speed Hack",
            Flag     = "GAG_SpeedHack",
            Default  = false,
            Callback = function(v)
                pcall(function()
                    if v then
                        Speed:SetWalkSpeed(50)
                        Speed:SetJumpPower(50)
                        Speed:Enable()
                    else
                        Speed:Disable()
                    end
                end)
            end
        })

        pTab:Slider({
            Title    = "Walk Speed",
            Flag     = "GAG_WalkSpeed",
            Value    = { Min = 16, Max = 250, Default = 50 },
            Step     = 1,
            Callback = function(v) pcall(function() Speed:SetWalkSpeed(v) end) end
        })

        pTab:Slider({
            Title    = "Jump Power",
            Flag     = "GAG_JumpPower",
            Value    = { Min = 50, Max = 500, Default = 50 },
            Step     = 1,
            Callback = function(v) pcall(function() Speed:SetJumpPower(v) end) end
        })

        pTab:Toggle({
            Title    = "Infinite Jump",
            Flag     = "GAG_InfiniteJump",
            Default  = false,
            Callback = function(v)
                local InfJump = extras.InfiniteJump
                if InfJump then
                    pcall(function()
                        if v then InfJump:Enable() else InfJump:Disable() end
                    end)
                end
            end
        })

        pTab:Toggle({
            Title    = "Anti-AFK",
            Flag     = "GAG_AntiAFK",
            Default  = false,
            Callback = function(v)
                local AntiAFK = extras.AntiAFK
                if AntiAFK then
                    pcall(function()
                        if v then AntiAFK:Enable() else AntiAFK:Disable() end
                    end)
                end
            end
        })
    end

    if Fly then
        pTab:Section({ Title = "Flight" })

        local gagFlyToggle = pTab:Toggle({
            Title    = "Fly",
            Flag     = "GAG_Fly",
            Default  = false,
            Callback = function(v)
                pcall(function()
                    if v then Fly:Enable() else Fly:Disable() end
                end)
            end
        })

        pTab:Slider({
            Title    = "Fly Speed",
            Flag     = "GAG_FlySpeed",
            Value    = { Min = 10, Max = 300, Default = 60 },
            Step     = 1,
            Callback = function(v)
                pcall(function()
                    if v >= 10 then Fly:SetSpeed(v) end
                end)
            end
        })

        pTab:Keybind({
            Title    = "Fly Keybind",
            Flag     = "GAG_FlyKey",
            Default  = "F",
            Callback = function() end
        })

        UIS.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.F then
                pcall(function()
                    local newState = not Fly.Enabled
                    gagFlyToggle:Set(newState)
                    if newState then Fly:Enable() else Fly:Disable() end
                end)
            end
        end)
    end

    -- ══ UTILITY ══════════════════════════════════════════════════════════
    tab:Section({ Title = "Utility" })

    tab:Button({
        Title    = "Rejoin Server",
        Flag     = "GAG_Rejoin",
        Callback = function()
            local Rejoin = extras.Rejoin
            if Rejoin then
                pcall(function() Rejoin:Execute() end)
            else
                pcall(function()
                    game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
                end)
            end
        end
    })

    tab:Button({
        Title    = "Server Hop",
        Flag     = "GAG_ServerHop",
        Callback = function()
            local SHop = extras.ServerHop
            if SHop then
                pcall(function() SHop:Execute() end)
            else
                pcall(function()
                    local HttpService = game:GetService("HttpService")
                    local TeleportService = game:GetService("TeleportService")
                    local url = string.format(
                        "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100",
                        game.PlaceId
                    )
                    local response = game:HttpGet(url)
                    local data = HttpService:JSONDecode(response)
                    if data and data.data then
                        local servers = {}
                        for _, s in ipairs(data.data) do
                            if s.id and s.id ~= game.JobId and s.playing and s.maxPlayers then
                                if s.playing < s.maxPlayers then
                                    servers[#servers + 1] = s.id
                                end
                            end
                        end
                        if #servers > 0 then
                            local target = servers[math.random(1, #servers)]
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, target, lp)
                            return
                        end
                    end
                    TeleportService:Teleport(game.PlaceId, lp)
                end)
            end
        end
    })
end

return GAG
