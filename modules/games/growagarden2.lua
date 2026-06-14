-- Leon X | Grow a Garden 2
-- PlaceId: 97598239454123
-- Auto Harvest (E key), Auto Sell, Auto Buy Seed (shop-based)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
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

local function getHumanoid()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- Teleport character smoothly
local function teleportTo(pos)
    local hrp = getHRP()
    if hrp and pos then
        pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end)
    end
end

-- Simulate pressing E key (for ProximityPrompt)
local function pressE()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- Find nearest ProximityPrompt within range
local function findNearestPrompt(maxDist)
    local hrp = getHRP()
    if not hrp then return nil, nil end

    local best, bestDist = nil, maxDist or 20
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local parent = prompt.Parent
            if parent then
                local part = parent:IsA("BasePart") and parent
                    or (parent:IsA("Model") and parent.PrimaryPart)
                if part then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist < bestDist then
                        best = prompt
                        bestDist = dist
                    end
                end
            end
        end
    end
    return best, bestDist
end

-- ── Cached scan (non-laggy) ────────────────────────────────────────────────
-- Instead of scanning every frame, we cache results and refresh periodically
local cachedPrompts = {}
local cacheRefreshTimer = 0
local CACHE_REFRESH_INTERVAL = 3 -- seconds

local function refreshPromptCache()
    cachedPrompts = {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                cachedPrompts[#cachedPrompts + 1] = obj
            end
        end
    end)
end

-- ── Auto Harvest (press E near plants) ──────────────────────────────────────
local function startAutoHarvest()
    disconnect("harvest")
    refreshPromptCache()

    local actionTimer = 0
    local ACTION_INTERVAL = 0.5 -- act every 0.5s, not every frame

    connections.harvest = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoHarvest then return end

        actionTimer = actionTimer + dt
        cacheRefreshTimer = cacheRefreshTimer + dt

        -- Refresh cache periodically
        if cacheRefreshTimer >= CACHE_REFRESH_INTERVAL then
            cacheRefreshTimer = 0
            refreshPromptCache()
        end

        if actionTimer < ACTION_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- Find nearest enabled ProximityPrompt
            local bestPrompt = nil
            local bestDist = 30 -- max range

            for _, prompt in ipairs(cachedPrompts) do
                if prompt and prompt.Parent and prompt.Enabled then
                    local parent = prompt.Parent
                    local part = parent:IsA("BasePart") and parent
                        or (parent:IsA("Model") and parent.PrimaryPart)
                    if part then
                        local dist = (part.Position - hrp.Position).Magnitude
                        if dist < bestDist then
                            bestPrompt = prompt
                            bestDist = dist
                        end
                    end
                end
            end

            if bestPrompt then
                -- Teleport near it and press E
                local parent = bestPrompt.Parent
                local pos = parent:IsA("BasePart") and parent.Position
                    or (parent:IsA("Model") and parent:GetPivot().Position)
                if pos then
                    teleportTo(pos)
                    task.wait(0.1)
                    -- Try both methods: direct fire + key press
                    pcall(function() bestPrompt:Fire() end)
                    pressE()
                end
            end
        end)
    end)
end

-- ── Auto Sell ───────────────────────────────────────────────────────────────
-- Scans for sell/shop interactables, walks to them, and interacts
local sellKeywords = {
    "sell", "shop", "store", "market", "vendor",
    "trade", "checkout", "register", "counter"
}

local function startAutoSell()
    disconnect("sell")

    local actionTimer = 0
    local SELL_INTERVAL = 2 -- try every 2 seconds

    connections.sell = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoSell then return end

        actionTimer = actionTimer + dt
        if actionTimer < SELL_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- Scan for sell-related ProximityPrompts
            for _, prompt in ipairs(cachedPrompts) do
                if prompt and prompt.Parent and prompt.Enabled then
                    local name = prompt.Parent.Name:lower()
                    local grandName = ""
                    pcall(function() grandName = prompt.Parent.Parent.Name:lower() end)

                    local isSell = false
                    for _, kw in ipairs(sellKeywords) do
                        if name:find(kw) or grandName:find(kw) then
                            isSell = true
                            break
                        end
                    end

                    if isSell then
                        local parent = prompt.Parent
                        local pos = parent:IsA("BasePart") and parent.Position
                            or (parent:IsA("Model") and parent:GetPivot().Position)
                        if pos then
                            teleportTo(pos)
                            task.wait(0.2)
                            pcall(function() prompt:Fire() end)
                            pressE()
                            task.wait(0.5)
                        end
                    end
                end
            end

            -- Also try clicking any sell GUI buttons
            pcall(function()
                local pg = lp:FindFirstChildOfClass("PlayerGui")
                if pg then
                    for _, btn in ipairs(pg:GetDescendants()) do
                        if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                            local name = btn.Name:lower()
                            local text = ""
                            pcall(function() text = (btn.Text or ""):lower() end)
                            for _, kw in ipairs(sellKeywords) do
                                if name:find(kw) or text:find(kw) then
                                    pcall(function()
                                        if btn:IsA("TextButton") then
                                            btn.MouseButton1Click:Fire()
                                        elseif btn:IsA("ImageButton") then
                                            btn.MouseButton1Click:Fire()
                                        end
                                    end)
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end)
end

-- ── Auto Buy Seed (shop-based) ─────────────────────────────────────────────
-- Finds shop NPCs/areas, opens shop, buys available seeds
local shopKeywords = {
    "seed", "shop", "store", "vendor", "buy",
    "market", "pack", "garden", "plant"
}

local function startAutoBuySeed()
    disconnect("buy")

    local actionTimer = 0
    local BUY_INTERVAL = 3 -- try every 3 seconds

    connections.buy = RunService.Heartbeat:Connect(function(dt)
        if not GAG.Enabled or not GAG.AutoBuySeed then return end

        actionTimer = actionTimer + dt
        if actionTimer < BUY_INTERVAL then return end
        actionTimer = 0

        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- Step 1: Find shop ProximityPrompts
            for _, prompt in ipairs(cachedPrompts) do
                if prompt and prompt.Parent and prompt.Enabled then
                    local name = prompt.Parent.Name:lower()
                    local grandName = ""
                    pcall(function() grandName = prompt.Parent.Parent.Name:lower() end)

                    local isShop = false
                    for _, kw in ipairs(shopKeywords) do
                        if name:find(kw) or grandName:find(kw) then
                            isShop = true
                            break
                        end
                    end

                    if isShop then
                        local parent = prompt.Parent
                        local pos = parent:IsA("BasePart") and parent.Position
                            or (parent:IsA("Model") and parent:GetPivot().Position)
                        if pos then
                            teleportTo(pos)
                            task.wait(0.3)
                            pcall(function() prompt:Fire() end)
                            pressE()
                            task.wait(1) -- wait for shop GUI to open
                        end
                    end
                end
            end

            -- Step 2: Scan for buy buttons in any open GUI
            local pg = lp:FindFirstChildOfClass("PlayerGui")
            if pg then
                for _, btn in ipairs(pg:GetDescendants()) do
                    if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                        local name = btn.Name:lower()
                        local text = ""
                        pcall(function() text = (btn.Text or ""):lower() end)

                        local isBuy = false
                        for _, kw in ipairs({"buy", "purchase", "seed", "pack"}) do
                            if name:find(kw) or text:find(kw) then
                                isBuy = true
                                break
                            end
                        end

                        if isBuy and btn.Visible then
                            pcall(function() btn.MouseButton1Click:Fire() end)
                            task.wait(0.3)
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
    refreshPromptCache()
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
        Title    = "Auto Harvest (press E)",
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

    tab:Toggle({
        Title    = "Auto Buy Seed (from shop)",
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

    tab:Section({ Title = "How it works" })

    tab:Paragraph({
        Title   = "Auto Harvest",
        Content = "Finds nearest ProximityPrompt (plant/fruit), teleports to it, and presses E. Scans every 0.5s with cached prompt list (refreshed every 3s) — no lag."
    })

    tab:Paragraph({
        Title   = "Auto Sell",
        Content = "Finds sell/shop prompts in workspace + clicks sell buttons in GUI. Tries every 2s."
    })

    tab:Paragraph({
        Title   = "Auto Buy Seed",
        Content = "Finds shop NPCs/areas, opens shop via E key, then clicks buy/purchase/seed buttons in the GUI. Tries every 3s."
    })
end

return GAG
