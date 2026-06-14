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
GAG.PriceESP      = false

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

-- ── Auto Harvest (optimized — no E key, rapid parallel) ────────────────────
local function startAutoHarvest()
    disconnect("harvest")
    detectGardenBounds()

    -- Cache prompts with 3s refresh (avoid scanning every frame)
    local cachedPrompts = {}
    local lastCacheTime = 0
    local CACHE_REFRESH = 3

    local actionTimer = 0
    local ACTION_INTERVAL = 0.5

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
            -- Fire ALL CollectFruit remotes in parallel (fast, no wait)
            if net and net.Garden and net.Garden.CollectFruit then
                for _, prompt in ipairs(cachedPrompts) do
                    if prompt and prompt.Parent and prompt.Enabled then
                        -- Check bounds
                        local pos
                        local model = prompt.Parent:IsA("Model") and prompt.Parent
                            or prompt.Parent:FindFirstAncestorWhichIsA("Model")
                        if model then pos = model:GetPivot().Position end
                        if not pos and prompt.Parent:IsA("BasePart") then
                            pos = prompt.Parent.Position
                        end

                        if pos and isInGarden(pos) then
                            -- Fire remote instantly (no wait)
                            pcall(function() net.Garden.CollectFruit:Fire(prompt, "") end)
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

local function createPriceESP(plantModel)
    -- Skip if already has ESP
    if plantModel:FindFirstChild("LeonX_PriceESP") then return end

    -- Get plant info from model name or children
    local plantName = plantModel.Name
    local weight = ""
    
    -- Try to find weight from HarvestPart attributes or model attributes
    pcall(function()
        -- Check model attributes
        local w = plantModel:GetAttribute("Weight") or plantModel:GetAttribute("weight")
        if w then weight = string.format("%.2fkg", w) end
        
        -- Check children for weight info
        if weight == "" then
            for _, child in ipairs(plantModel:GetDescendants()) do
                if child:IsA("BasePart") then
                    local cw = child:GetAttribute("Weight") or child:GetAttribute("weight")
                    if cw then weight = string.format("%.2fkg", cw); break end
                end
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
    label.Text = plantName .. (weight ~= "" and ("\n" .. weight) or "")
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
    self.PriceESP      = false
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

    -- ══ VISUAL SECTION ═══════════════════════════════════════════════════════
    tab:Section({ Title = "Visual" })

    tab:Toggle({
        Title    = "Price ESP (Plant Labels)",
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

    -- ══ PLAYER SECTION ═══════════════════════════════════════════════════════
    tab:Section({ Title = "Player" })

    if Speed then
        tab:Toggle({
            Title    = "Speed Hack",
            Flag     = "GAG_SpeedHack",
            Default  = false,
            Callback = function(v)
                if v then
                    Speed:SetWalkSpeed(50)
                    Speed:SetJumpPower(50)
                    Speed:Enable()
                else
                    Speed:Disable()
                end
            end
        })

        tab:Slider({
            Title    = "Walk Speed",
            Flag     = "GAG_WalkSpeed",
            Value    = { Min = 16, Max = 250, Default = 50 },
            Step     = 1,
            Callback = function(v) Speed:SetWalkSpeed(v) end
        })

        tab:Slider({
            Title    = "Jump Power",
            Flag     = "GAG_JumpPower",
            Value    = { Min = 50, Max = 500, Default = 50 },
            Step     = 1,
            Callback = function(v) Speed:SetJumpPower(v) end
        })
    end

    if Fly then
        tab:Toggle({
            Title    = "Fly",
            Flag     = "GAG_Fly",
            Default  = false,
            Callback = function(v)
                if v then Fly:Enable() else Fly:Disable() end
            end
        })

        tab:Slider({
            Title    = "Fly Speed",
            Flag     = "GAG_FlySpeed",
            Value    = { Min = 10, Max = 300, Default = 60 },
            Step     = 1,
            Callback = function(v) if v >= 10 then Fly:SetSpeed(v) end end
        })
    end

    -- ══ INFO SECTION ════════════════════════════════════════════════════
    tab:Section({ Title = "Info" })

    tab:Paragraph({
        Title   = "Auto Harvest",
        Content = "Fires CollectFruit remote for all plants in your garden. No teleport."
    })

    tab:Paragraph({
        Title   = "Auto Sell",
        Content = "Fires NPCS.SellAll every 1s. Works from anywhere."
    })

    tab:Paragraph({
        Title   = "Price ESP",
        Content = "Shows plant name + weight above each crop in all gardens."
    })

    tab:Paragraph({
        Title   = "Auto Seed Event",
        Content = "Detects falling seeds (Corn, Pineapple, etc.) and collects them."
    })
end

return GAG
