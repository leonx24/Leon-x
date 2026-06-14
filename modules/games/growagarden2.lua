-- Leon X | Grow a Garden 2
-- PlaceId: 97598239454123
-- Auto Buy Seed, Auto Sell, Auto Collect/Harvest

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local GAG = {}
GAG.Name = "Grow a Garden 2"
GAG.PlaceIds = { 97598239454123 }
GAG.Enabled = false

-- Feature states
GAG.AutoCollect = false
GAG.AutoSell    = false
GAG.AutoBuySeed = false

local connections = {}

local function disconnectAll()
    for _, conn in pairs(connections) do
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

local function getHumanoid()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- Find interactable objects by keywords
local function findInteractables(keywords)
    local results = {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
                local name = obj.Name:lower()
                for _, kw in ipairs(keywords) do
                    if name:find(kw) then
                        results[#results + 1] = obj
                        break
                    end
                end
            end
        end
    end)
    return results
end

-- Fire ProximityPrompt or ClickDetector on an object
local function interact(obj)
    if not obj then return false end
    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        pcall(function() prompt:Fire() end)
        return true
    end
    local click = obj:FindFirstChildOfClass("ClickDetector")
    if click then
        pcall(function() click:FireServer() end)
        return true
    end
    -- Check children recursively (max 2 levels)
    for _, child in ipairs(obj:GetChildren()) do
        local p = child:FindFirstChildOfClass("ProximityPrompt")
        if p then
            pcall(function() p:Fire() end)
            return true
        end
        local c = child:FindFirstChildOfClass("ClickDetector")
        if c then
            pcall(function() c:FireServer() end)
            return true
        end
    end
    return false
end

-- Teleport character to a position
local function teleportTo(pos)
    local hrp = getHRP()
    if hrp and pos then
        pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
    end
end

-- ── Auto Collect / Harvest ──────────────────────────────────────────────────
local function startAutoCollect()
    if connections.collect then connections.collect:Disconnect() end

    connections.collect = RunService.Heartbeat:Connect(function()
        if not GAG.Enabled or not GAG.AutoCollect then return end

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- Scan for harvestable/collectible items
            local keywords = {
                "harvest", "collect", "ready", "grown", "crop",
                "fruit", "plant", "flower", "mushroom", "produce",
                "pickup", "loot", "drop", "item", "coin", "reward"
            }

            local items = findInteractables(keywords)
            for _, item in ipairs(items) do
                local pos = item:IsA("Model") and item:GetPivot().Position or item.Position
                local dist = (pos - hrp.Position).Magnitude

                if dist < 50 then
                    teleportTo(pos)
                    task.wait(0.3)
                    interact(item)
                    task.wait(0.2)
                end
            end
        end)
    end)
end

-- ── Auto Sell ───────────────────────────────────────────────────────────────
local function startAutoSell()
    if connections.sell then connections.sell:Disconnect() end

    connections.sell = RunService.Heartbeat:Connect(function()
        if not GAG.Enabled or not GAG.AutoSell then return end

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- Find sell points (shop, sell area, NPC)
            local keywords = {
                "sell", "shop", "store", "market", "stand",
                "vendor", "trade", "npc"
            }

            local sellPoints = findInteractables(keywords)
            for _, sp in ipairs(sellPoints) do
                local pos = sp:IsA("Model") and sp:GetPivot().Position or sp.Position
                local dist = (pos - hrp.Position).Magnitude

                if dist < 30 then
                    teleportTo(pos)
                    task.wait(0.5)
                    interact(sp)
                    task.wait(1) -- wait for sell to process
                end
            end
        end)
    end)
end

-- ── Auto Buy Seed ───────────────────────────────────────────────────────────
local function startAutoBuySeed()
    if connections.buy then connections.buy:Disconnect() end

    connections.buy = RunService.Heartbeat:Connect(function()
        if not GAG.Enabled or not GAG.AutoBuySeed then return end

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- Find seed shop/vendor
            local keywords = {
                "seed", "shop", "store", "vendor", "buy",
                "market", "pack"
            }

            local shops = findInteractables(keywords)
            for _, shop in ipairs(shops) do
                local pos = shop:IsA("Model") and shop:GetPivot().Position or shop.Position
                local dist = (pos - hrp.Position).Magnitude

                if dist < 30 then
                    teleportTo(pos)
                    task.wait(0.5)
                    interact(shop)
                    task.wait(1)
                end
            end
        end)
    end)
end

-- ── Module Interface ────────────────────────────────────────────────────────
function GAG:Init()
    -- Pre-scan to verify game is loaded
    task.wait(2)
end

function GAG:Enable()
    self.Enabled = true
end

function GAG:Disable()
    self.Enabled = false
    self.AutoCollect = false
    self.AutoSell = false
    self.AutoBuySeed = false
    disconnectAll()
end

-- ── Wire UI ─────────────────────────────────────────────────────────────────
function GAG:WireUI(tab)
    tab:Section({ Title = "Auto Features" })

    tab:Toggle({
        Title    = "Auto Collect / Harvest",
        Flag     = "GAG_AutoCollect",
        Default  = false,
        Callback = function(v)
            GAG.AutoCollect = v
            if v then
                GAG.Enabled = true
                startAutoCollect()
            else
                pcall(function() connections.collect:Disconnect() end)
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
                pcall(function() connections.sell:Disconnect() end)
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
                pcall(function() connections.buy:Disconnect() end)
            end
        end
    })

    tab:Section({ Title = "Info" })

    tab:Paragraph({
        Title   = "How it works",
        Content = "Auto Collect: teleports to nearby plants/items and interacts.\nAuto Sell: finds sell points and sells.\nAuto Buy Seed: finds seed shops and buys."
    })

    tab:Paragraph({
        Title   = "Note",
        Content = "These features scan workspace for interactable objects. Effectiveness depends on the game's object naming."
    })
end

return GAG
