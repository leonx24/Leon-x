-- Leon X | Grow a Garden 2
-- PlaceId: 97598239454123
-- Auto Harvest, Auto Sell, Auto Buy Seed (using game remotes)

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
GAG.AutoHarvest   = false
GAG.AutoSell      = false
GAG.AutoBuySeed   = false
GAG.AutoBuyAll    = false
GAG.AutoSeedEvent = false
GAG.SelectedSeed  = {} -- multi-select seeds to auto-buy
GAG.PriceESP      = false
GAG.AutoBuyGear   = false
GAG.SelectedGear  = {} -- multi-select gears to auto-buy
GAG.GardenLock    = false
GAG.HarvestMode   = "remote"
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

local function teleportTo(pos)
    local hrp = getHRP()
    if hrp and pos then
        -- Keep player's current Y height, only move XZ
        local currentY = hrp.Position.Y
        local targetY = math.clamp(pos.Y + 2, currentY - 10, currentY + 10)
        pcall(function() hrp.CFrame = CFrame.new(pos.X, targetY, pos.Z) end)
    end
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

-- ── Auto Harvest (remote-only or teleport mode) ────────────────────────────
local function startAutoHarvest()
    disconnect("harvest")
    detectGardenBounds()

    -- Cache prompts with 3s refresh
    local cachedPrompts = {}
    local lastCacheTime = 0
    local CACHE_REFRESH = 3

    local actionTimer = 0
    local ACTION_INTERVAL = 0.5 -- slower to prevent server rejection

    connections.harvest = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoHarvest then return end

        actionTimer = actionTimer + dt
        if actionTimer < ACTION_INTERVAL then return end
        actionTimer = 0

        -- Refresh cache every 3 seconds
        local now = tick()
        if now - lastCacheTime > CACHE_REFRESH then
            cachedPrompts = CollectionService:GetTagged("HarvestPrompt")
            lastCacheTime = now
        end

        if #cachedPrompts == 0 then return end

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- Filter to only valid garden prompts and find ProximityPrompts
            local gardenPrompts = {}
            for _, tagged in ipairs(cachedPrompts) do
                if tagged and tagged.Parent then
                    -- Resolve the actual ProximityPrompt
                    local prompt
                    if tagged:IsA("ProximityPrompt") then
                        prompt = tagged
                    elseif tagged:IsA("Model") or tagged:IsA("BasePart") then
                        prompt = tagged:FindFirstChildWhichIsA("ProximityPrompt")
                    end

                    if prompt and prompt.Enabled then
                        -- Find the plant model (has SeedName attribute)
                        local model = prompt.Parent
                        while model and not (model:IsA("Model") and model:GetAttribute("SeedName")) do
                            if model == workspace then model = nil; break end
                            model = model.Parent
                        end
                        if not model and prompt.Parent:IsA("Model") then
                            model = prompt.Parent
                        end

                        -- Get position for garden bounds check + teleport
                        local pos
                        if model then
                            local hp = model:FindFirstChild("HarvestPart")
                            if hp and hp:IsA("BasePart") then
                                pos = hp.Position
                            else
                                pos = model:GetPivot().Position
                            end
                        elseif prompt.Parent:IsA("BasePart") then
                            pos = prompt.Parent.Position
                        end

                        if pos and isInGarden(pos) then
                            gardenPrompts[#gardenPrompts + 1] = {
                                prompt = prompt,
                                pos    = pos,
                                model  = model,
                            }
                        end
                    end
                end
            end

            if #gardenPrompts == 0 then return end

            -- Remote-only mode: fire CollectFruit remote without teleport
            if GAG.HarvestMode == "remote" then
                for _, entry in ipairs(gardenPrompts) do
                    local prompt = entry.prompt
                    if prompt and prompt.Parent and prompt.Enabled then
                        pcall(function()
                            if net and net.Garden and net.Garden.CollectFruit then
                                net.Garden.CollectFruit:Fire(prompt)
                            end
                        end)
                    end
                end
            else
                -- Teleport mode: teleport to each plant + use ProximityPrompt
                for _, entry in ipairs(gardenPrompts) do
                    local prompt = entry.prompt
                    local pos    = entry.pos

                    if prompt and prompt.Parent and prompt.Enabled then
                        -- Teleport directly to plant (use plant Y, small offset)
                        pcall(function()
                            hrp.CFrame = CFrame.new(pos.X, pos.Y + 1, pos.Z)
                        end)
                        task.wait(0.3)

                        -- Re-check prompt still enabled after teleport
                        if prompt and prompt.Parent and prompt.Enabled then
                            -- Primary: trigger ProximityPrompt (game's native harvest)
                            pcall(function()
                                prompt:InputHoldBegin()
                            end)
                            task.wait(0.2)
                            pcall(function()
                                if prompt and prompt.Parent then
                                    prompt:InputHoldEnd()
                                end
                            end)

                            -- Backup: also fire the Networking remote
                            pcall(function()
                                if net and net.Garden and net.Garden.CollectFruit then
                                    net.Garden.CollectFruit:Fire(prompt)
                                end
                            end)
                        end
                    end
                end
            end
        end)
    end)
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

-- ── Garden Lock Protection ───────────────────────────────────────────────────
-- NOTE: No garden lock remote exists in the Networking module.
-- The Steal category only has BeginSteal/CompleteSteal/CancelSteal (for thieves).
-- There is no Lock/ToggleLock/SetLocked remote for protecting gardens.
-- This feature is kept as placeholder for future game updates.
local function startGardenLock()
    disconnect("gardenlock")
    print("[Leon X] Garden Lock: No lock remote found in Networking module.")
    print("[Leon X] The game may not support automated garden locking.")
end

-- ── Auto Steal (steal fruits from other gardens at night) ─────────────────
local function startAutoSteal()
    disconnect("steal")

    local cachedPrompts = {}
    local lastCacheTime = 0
    local CACHE_REFRESH = 3
    local actionTimer = 0
    local ACTION_INTERVAL = 1

    connections.steal = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoSteal then return end

        actionTimer = actionTimer + dt
        if actionTimer < ACTION_INTERVAL then return end
        actionTimer = 0

        local now = tick()
        if now - lastCacheTime > CACHE_REFRESH then
            -- Look for steal-related prompts (HoldToSteal tag or similar)
            cachedPrompts = {}
            pcall(function()
                local stealTagged = CollectionService:GetTagged("HoldToSteal")
                for _, p in ipairs(stealTagged) do
                    cachedPrompts[#cachedPrompts + 1] = p
                end
                -- Also try HarvestPrompt outside own garden
                local harvestTagged = CollectionService:GetTagged("HarvestPrompt")
                for _, p in ipairs(harvestTagged) do
                    cachedPrompts[#cachedPrompts + 1] = p
                end
            end)
            lastCacheTime = now
        end

        if #cachedPrompts == 0 then return end

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            for _, tagged in ipairs(cachedPrompts) do
                if tagged and tagged.Parent then

                -- Resolve ProximityPrompt
                local prompt
                if tagged:IsA("ProximityPrompt") then
                    prompt = tagged
                elseif tagged:IsA("Model") or tagged:IsA("BasePart") then
                    prompt = tagged:FindFirstChildWhichIsA("ProximityPrompt")
                end

                if prompt and prompt.Enabled then
                    -- Skip if in own garden (only steal from others)
                    local pos
                    if tagged:IsA("BasePart") then
                        pos = tagged.Position
                    elseif tagged:IsA("Model") then
                        pos = tagged:GetPivot().Position
                    elseif prompt.Parent:IsA("BasePart") then
                        pos = prompt.Parent.Position
                    end

                    if pos and not isInGarden(pos) then
                        -- Teleport to the fruit
                        pcall(function()
                            hrp.CFrame = CFrame.new(pos.X, pos.Y + 1, pos.Z)
                        end)
                        task.wait(0.3)

                        -- Trigger steal via ProximityPrompt
                        if prompt and prompt.Parent and prompt.Enabled then
                            pcall(function() prompt:InputHoldBegin() end)
                            task.wait(0.5)
                            pcall(function()
                                if prompt and prompt.Parent then
                                    prompt:InputHoldEnd()
                                end
                            end)
                        end

                        -- Also fire Steal remotes as backup
                        if net and net.Steal then
                            pcall(function()
                                if net.Steal.BeginSteal then
                                    net.Steal.BeginSteal:Fire(prompt)
                                end
                            end)
                            task.wait(0.3)
                            pcall(function()
                                if net.Steal.CompleteSteal then
                                    net.Steal.CompleteSteal:Fire(prompt)
                                end
                            end)
                        end
                    end
                end
                end -- close if tagged
            end
        end)
    end)
end

-- ── Auto Fling (push nearby players away) ───────────────────────────────
local function startAutoFling()
    disconnect("fling")

    local actionTimer = 0
    local FLING_INTERVAL = 0.3

    connections.fling = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoFling then return end

        actionTimer = actionTimer + dt
        if actionTimer < FLING_INTERVAL then return end
        actionTimer = 0

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
                                -- Push them away with velocity spike
                                local dir = (theirHRP.Position - myPos).Unit
                                pcall(function()
                                    theirHRP.AssemblyLinearVelocity = dir * 500 + Vector3.new(0, 200, 0)
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

-- ── Price ESP (shows plant name + weight above each crop) ─────────────
local espObjects = {} -- track created BillboardGuis

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

    -- Create BillboardGui
    local gui = Instance.new("BillboardGui")
    gui.Name = "LeonX_PriceESP"
    gui.Size = UDim2.new(0, 120, 0, 30)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = harvestPart or plantModel.PrimaryPart or plantModel:FindFirstChildWhichIsA("BasePart")
    gui.Parent = plantModel

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.4
    label.TextColor3 = Color3.fromRGB(255, 255, 100)
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.Text = plantName .. (info ~= "" and ("\n" .. info) or "")
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
    self.AutoHarvest   = false
    self.AutoSell      = false
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

    -- ══ MAIN SECTION (Auto Features) ═════════════════════════════════════════
    tab:Section({ Title = "Main — Auto Features" })

    -- Harvest Mode selector
    tab:Dropdown({
        Title    = "Harvest Mode",
        Flag     = "GAG_HarvestMode",
        Default  = "remote",
        Values   = {"remote", "teleport"},
        Callback = function(v)
            GAG.HarvestMode = v
        end
    })

    tab:Toggle({
        Title    = "Auto Harvest",
        Flag     = "GAG_AutoHarvest",
        Default  = false,
        Callback = function(v)
            GAG.AutoHarvest = v
            if v then
                GAG.Enabled = true
                startAutoHarvest()
            else
                disconnect("harvest")
            end
        end
    })

    tab:Toggle({
        Title    = "Auto Sell",
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

    -- Seed dropdown (multi-select)
    tab:Dropdown({
        Title    = "Select Seeds (Multi)",
        Flag     = "GAG_SelectedSeeds",
        Default  = {},
        Values   = seedNames,
        Multi    = true,
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

    -- ══ SHOP SECTION ═════════════════════════════════════════════════════════
    tab:Section({ Title = "Shop — Gear" })

    -- Multi-select gear dropdown
    tab:Dropdown({
        Title    = "Select Gear (Multi)",
        Flag     = "GAG_SelectedGear",
        Default  = {},
        Values   = gearNames,
        Multi    = true,
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

    -- ══ STEAL SECTION ═══════════════════════════════════════════════════════
    tab:Section({ Title = "Steal" })

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

    -- ══ PROTECTION SECTION ═══════════════════════════════════════════════════
    tab:Section({ Title = "Protection / Combat" })

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

    -- ══ VISUAL SECTION ═══════════════════════════════════════════════════════
    tab:Section({ Title = "Visual" })

    tab:Toggle({
        Title    = "Plant ESP (Labels)",
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

    -- ══ PLAYER SIDEBAR ═══════════════════════════════════════════════════════
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

        -- F keybind for Fly
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

    -- ══ UTILITY SIDEBAR ════════════════════════════════════════════════════
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
                -- Inline server hop fallback
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

    -- ══ INFO SECTION ════════════════════════════════════════════════════
    tab:Section({ Title = "Info" })

    tab:Paragraph({
        Title   = "Auto Harvest",
        Content = "Teleport mode: TP + ProximityPrompt. Remote mode: CollectFruit remote."
    })

    tab:Paragraph({
        Title   = "Auto Steal",
        Content = "Steals fruits from other players' gardens using HoldToSteal prompts."
    })

    tab:Paragraph({
        Title   = "Auto Fling",
        Content = "Pushes nearby players away with velocity force."
    })

    tab:Paragraph({
        Title   = "Plant ESP",
        Content = "Shows plant name + mutation + growth above each crop."
    })

    tab:Paragraph({
        Title   = "Utility",
        Content = "Rejoin/Server Hop for quick server switching."
    })
end

return GAG
