-- Leon X | Grow a Garden 2
-- PlaceId: 97598239454123
-- Auto Harvest, Auto Sell, Auto Buy Seed (using game remotes)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
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
GAG.SelectedSeed  = "" -- which seed to auto-buy

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

-- ── Auto Harvest (uses CollectionService + Networking remote) ───────────────
-- HarvestPrompt tag = ONLY garden plants, not other E-key objects
local function startAutoHarvest()
    disconnect("harvest")
    detectGardenBounds() -- detect player's garden bounds

    local actionTimer = 0
    local ACTION_INTERVAL = 0.3 -- fast but not laggy
    local harvestIdx = 1 -- round-robin through prompts

    connections.harvest = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoHarvest then return end

        actionTimer = actionTimer + dt
        if actionTimer < ACTION_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            -- Get ALL prompts tagged "HarvestPrompt" (garden plants only)
            local prompts = CollectionService:GetTagged("HarvestPrompt")
            if #prompts == 0 then return end

            -- Round-robin: harvest one prompt per tick
            harvestIdx = (harvestIdx % math.max(#prompts, 1)) + 1
            local prompt = prompts[harvestIdx]

            if not prompt or not prompt.Parent then return end
            if not prompt.Enabled then return end

            -- Teleport to the plant
            local model = prompt.Parent:IsA("Model") and prompt.Parent
                or prompt.Parent:FindFirstAncestorWhichIsA("Model")
            local pos
            if model then
                pos = model:GetPivot().Position
            elseif prompt.Parent:IsA("BasePart") then
                pos = prompt.Parent.Position
            end

            if pos then
                -- Only harvest within your own garden
                if not isInGarden(pos) then return end
                teleportTo(pos)
                task.wait(0.05)
            end

            -- Fire the game's own harvest remote
            if net and net.Garden and net.Garden.CollectFruit then
                pcall(function() net.Garden.CollectFruit:Fire(prompt, "") end)
            else
                -- Fallback: direct prompt fire
                pcall(function() prompt:InputHoldBegin() end)
                task.wait(0.1)
                pcall(function() prompt:InputHoldEnd() end)
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

-- Buy specific seed (cycles through selected seed)
local function startAutoBuySeed()
    disconnect("buy")

    local actionTimer = 0
    local BUY_INTERVAL = 1

    connections.buy = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoBuySeed then return end
        if not GAG.SelectedSeed or GAG.SelectedSeed == "" then return end

        actionTimer = actionTimer + dt
        if actionTimer < BUY_INTERVAL then return end
        actionTimer = 0

        if net and net.SeedShop and net.SeedShop.PurchaseSeed then
            pcall(function() net.SeedShop.PurchaseSeed:Fire(GAG.SelectedSeed) end)
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

-- ── Auto Seed Event (hunts falling rainbow/gold/event seeds) ────────────────
-- Watches workspace for new seed objects and teleports to collect them
local seedEventKeywords = {
    "seed", "rainbow", "gold", "event", "meteor", "star", "drop",
    "pack", "chest", "loot", "reward", "crate", "gift"
}

local function isSeedEventObject(obj)
    local name = obj.Name:lower()
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
    detectGardenBounds() -- refresh garden bounds

    local knownObjects = {}
    local actionTimer = 0
    local SCAN_INTERVAL = 0.5

    -- Watch for new objects added to workspace
    connections.seedwatcher = workspace.DescendantAdded:Connect(function(obj)
        if not GAG.Enabled or not GAG.AutoSeedEvent then return end
        if not obj:IsA("BasePart") and not obj:IsA("Model") then return end
        if knownObjects[obj] then return end

        if isSeedEventObject(obj) then
            knownObjects[obj] = true
            -- Clean up when object is removed
            obj.AncestryChanged:Connect(function()
                if not obj:IsDescendantOf(workspace) then
                    knownObjects[obj] = nil
                end
            end)
        end
    end)

    -- Periodically scan and collect
    connections.seedevent = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoSeedEvent then return end

        actionTimer = actionTimer + dt
        if actionTimer < SCAN_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- Scan for seed event objects
            for _, obj in ipairs(workspace:GetDescendants()) do
                if (obj:IsA("BasePart") or obj:IsA("Model")) and isSeedEventObject(obj) then
                    -- Skip if it's a player or NPC
                    local skip = false
                    local ancestor = obj:FindFirstAncestorWhichIsA("Model")
                    if ancestor and ancestor:FindFirstChildOfClass("Humanoid") then
                        if ancestor ~= obj then skip = true end
                    end

                    if not skip then
                        -- Get position
                        local pos
                        if obj:IsA("BasePart") then
                            pos = obj.Position
                        elseif obj:IsA("Model") then
                            pos = obj:GetPivot().Position
                        end

                        if pos and pos.Y > -50 and pos.Y < 500 and isInGarden(pos) then
                            -- Teleport to the seed
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

                            -- Try touching the part
                            if obj:IsA("BasePart") then
                                pcall(function()
                                    hrp.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end)
end

-- ── Module Interface ────────────────────────────────────────────────────────
function GAG:Init()
    task.wait(1)
    -- Load the game's Networking module
    pcall(function()
        net = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
    end)
    if net then
        print("[Leon X] GAG Networking loaded successfully")
    else
        print("[Leon X] WARNING: Could not load GAG Networking module")
    end
    -- Pre-load seed names
    getSeedNames()
    print("[Leon X] GAG Seeds found: " .. #seedNames)
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
    disconnectAll()
end

-- ── Wire UI ─────────────────────────────────────────────────────────────────
function GAG:WireUI(tab)
    tab:Section({ Title = "Auto Features" })

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

    tab:Section({ Title = "Seed Shop" })

    -- Seed dropdown
    tab:Dropdown({
        Title    = "Select Seed",
        Flag     = "GAG_SelectedSeed",
        Default  = "",
        Values   = seedNames,
        Callback = function(v)
            GAG.SelectedSeed = v
        end
    })

    tab:Toggle({
        Title    = "Auto Buy Selected Seed",
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

    tab:Section({ Title = "Events" })

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

    tab:Section({ Title = "Info" })

    tab:Paragraph({
        Title   = "Auto Harvest",
        Content = "Uses HarvestPrompt tags to collect only garden fruits. Fires Garden.CollectFruit remote."
    })

    tab:Paragraph({
        Title   = "Auto Sell",
        Content = "Fires NPCS.SellAll every 1s. Works from anywhere."
    })

    tab:Paragraph({
        Title   = "Seed Shop",
        Content = "Pick a seed from dropdown to auto-buy that one, or toggle Buy All to buy every seed at once."
    })

    tab:Paragraph({
        Title   = "Auto Seed Event",
        Content = "Watches for falling seed events (rainbow/gold/meteor). Teleports to them and collects via ProximityPrompt or ClickDetector."
    })
end

return GAG
