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
GAG.AutoHarvest = false
GAG.AutoSell    = false
GAG.AutoBuySeed = false

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
        pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
    end
end

-- Get Steven NPC
local function getSteven()
    local ok, steven = pcall(function()
        return workspace:FindFirstChild("NPCS") and workspace.NPCS:FindFirstChild("Steven")
    end)
    return ok and steven or nil
end

-- Get Steven's position
local function getStevenPos()
    local steven = getSteven()
    if steven then
        local hrp = steven:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.Position end
    end
    return nil
end

-- ── Auto Harvest (uses CollectionService + Networking remote) ───────────────
-- HarvestPrompt tag = ONLY garden plants, not other E-key objects
local function startAutoHarvest()
    disconnect("harvest")

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

-- ── Auto Sell (teleport to Steven + fire NPCS.SellAll) ─────────────────────
local function startAutoSell()
    disconnect("sell")

    local actionTimer = 0
    local SELL_INTERVAL = 3 -- sell every 3 seconds
    local sellPhase = 0 -- 0=teleport, 1=fire remote, 2=wait

    connections.sell = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoSell then return end

        actionTimer = actionTimer + dt
        if actionTimer < SELL_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            local stevenPos = getStevenPos()
            if not stevenPos then return end

            -- Teleport to Steven
            teleportTo(stevenPos)
            task.wait(0.5)

            -- Try NPCS.SellAll remote (sell everything at once)
            if net and net.NPCS and net.NPCS.SellAll then
                pcall(function() net.NPCS.SellAll:Fire() end)
            end

            -- Also try NPCS.SellFruit as backup
            task.wait(0.3)
            if net and net.NPCS and net.NPCS.SellFruit then
                pcall(function() net.NPCS.SellFruit:Fire() end)
            end
        end)
    end)
end

-- ── Auto Buy Seed (uses SeedShop.PurchaseSeed remote) ──────────────────────
-- Scans seed shop for available seeds and buys them
local function startAutoBuySeed()
    disconnect("buy")

    local actionTimer = 0
    local BUY_INTERVAL = 2 -- buy every 2 seconds
    local seedIdx = 0

    -- Common seed names in Grow a Garden 2
    local seedNames = {
        "Carrot", "Tomato", "Strawberry", "Blueberry", "Corn",
        "Watermelon", "Pumpkin", "Wheat", "Potato", "Onion",
        "Grape", "Apple", "Banana", "Pepper", "Lettuce",
        "Cabbage", "Sunflower", "Rose", "Tulip", "Daisy",
    }

    connections.buy = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoBuySeed then return end

        actionTimer = actionTimer + dt
        if actionTimer < BUY_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            if not net or not net.SeedShop or not net.SeedShop.PurchaseSeed then return end

            -- Round-robin through seed names
            seedIdx = (seedIdx % #seedNames) + 1
            local seedName = seedNames[seedIdx]

            -- Try buying with seed name
            pcall(function() net.SeedShop.PurchaseSeed:Fire(seedName) end)
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
end

function GAG:Enable()
    self.Enabled = true
end

function GAG:Disable()
    self.Enabled = false
    self.AutoHarvest = false
    self.AutoSell = false
    self.AutoBuySeed = false
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
        Title    = "Auto Sell (Steven)",
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
        Title    = "Auto Buy Seed",
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

    tab:Section({ Title = "Info" })

    tab:Paragraph({
        Title   = "Auto Harvest",
        Content = "Uses HarvestPrompt tags to collect ONLY garden fruits. Fires Networking.Garden.CollectFruit remote."
    })

    tab:Paragraph({
        Title   = "Auto Sell",
        Content = "Teleports to Steven NPC and fires NPCS.SellAll + SellFruit remotes."
    })

    tab:Paragraph({
        Title   = "Auto Buy Seed",
        Content = "Fires SeedShop.PurchaseSeed remote with seed names. Cycles through available seeds."
    })
end

return GAG
