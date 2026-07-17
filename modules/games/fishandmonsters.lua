-- Leon X | Fish And Monsters
-- PlaceId: 111385005478215
-- Auto Cast, Auto Reel, Instant Bite, AFK Mode, Auto Sell, Auto Chest, ESP, Island Teleport
-- Powered by Sleitnick Knit Service bindings

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UIS               = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local lp = Players.LocalPlayer

local FAM = {}
FAM.Name = "Fish And Monsters"
FAM.PlaceIds = { 111385005478215 }
FAM.GameIds  = { 10009809198 }  -- Universe ID (works across Sea 1, 2, 3, etc.)
FAM.Enabled = false

-- ── Feature States ──────────────────────────────────────────────────────────
FAM.AutoCast       = false
FAM.AutoReel       = false
FAM.InstantBite    = false
FAM.AfkMode        = false
FAM.AutoSell       = false
FAM.AutoCollect    = false -- Auto Chest Open
FAM.AutoQuest      = false
FAM.FishESP        = false
FAM.MonsterESP     = false
FAM.TreasureESP    = false
FAM.SelectedIsland = ""
FAM.CastPower      = 100   -- 0-100%
FAM.BlatantMode    = false
FAM.HideCatchUI    = false
FAM.SellLimit      = 15

local connections = {}
local espObjects  = {}

-- ── Connection Helpers ──────────────────────────────────────────────────────
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

-- ── ESP Cleanup ─────────────────────────────────────────────────────────────
local function clearESP()
    for _, obj in pairs(espObjects) do
        pcall(function() obj:Destroy() end)
    end
    espObjects = {}
end

-- ── Helpers ─────────────────────────────────────────────────────────────────
local function getHRP()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- KNIT SERVICES LOAD
-- ═══════════════════════════════════════════════════════════════════════════
local Knit = nil
local services = {}

local function findRemotes()
    pcall(function()
        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if packages and packages:FindFirstChild("Knit") then
            Knit = require(packages.Knit)
        end
        
        if Knit then
            services.FishermanShopService = Knit.GetService("FishermanShopService")
            services.FishingReplicationService = Knit.GetService("FishingReplicationService")
            services.FishingRewardService = Knit.GetService("FishingRewardService")
            services.SeaLobbyService = Knit.GetService("SeaLobbyService")
            services.SpawnService = Knit.GetService("SpawnService")
            services.TreasureService = Knit.GetService("TreasureService")
            services.QuestService = Knit.GetService("QuestService")
            print("[Leon X] FAM: Bound all Knit services successfully!")
        else
            warn("[Leon X] FAM: Knit framework not found!")
        end
    end)
end

-- Helper to recursively find UUID in tables/strings
local function findUUID(obj)
    if type(obj) == "string" and #obj == 36 and obj:find("-") then
        return obj
    elseif type(obj) == "table" then
        for k, v in pairs(obj) do
            if type(v) == "string" and #v == 36 and v:find("-") then
                return v
            elseif type(v) == "table" then
                local res = findUUID(v)
                if res then return res end
            end
        end
    end
    return nil
end

local function getEquippedRod()
    local rod = "Default"
    pcall(function()
        local tool = lp.Character:FindFirstChildOfClass("Tool") or lp.Backpack:FindFirstChildOfClass("Tool")
        if tool then
            rod = tool.Name
        end
    end)
    return rod
end

local function getEquippedFloater()
    local floater = "Floater_Doll"
    pcall(function()
        local data = ReplicatedStorage:FindFirstChild("PlayerData") and ReplicatedStorage.PlayerData:FindFirstChild(tostring(lp.UserId))
        if data then
            local eq = data:FindFirstChild("Equipped") or data:FindFirstChild("EquippedFloater")
            if eq and eq:FindFirstChild("Floater") then
                floater = eq.Floater.Value
            end
        end
    end)
    return floater
end
-- asd
local function logCast(step, detail)
    local msg = string.format("[Leon X Debug] [%s] Step: %s | Detail: %s", os.date("%H:%M:%S"), tostring(step), tostring(detail))
    print(msg)
    pcall(function()
        local content = ""
        pcall(function() content = readfile("LeonX_CastLog.txt") or "" end)
        writefile("LeonX_CastLog.txt", content .. "\n" .. msg)
    end)
end

local function startUIHider()
    disconnect("uihider")
    local function processUI(child)
        if not FAM.HideCatchUI then return end
        local name = child.Name:lower()
        if name:find("caught") or name:find("obtain") or name:find("reward") then
            task.wait()
            pcall(function()
                if child:IsA("ScreenGui") then
                    child.Enabled = false
                else
                    child.Visible = false
                end
            end)
        end
    end
    pcall(function()
        for _, child in ipairs(lp.PlayerGui:GetChildren()) do
            processUI(child)
        end
    end)
    connections.uihider = lp.PlayerGui.ChildAdded:Connect(processUI)
end

local function stopUIHider()
    disconnect("uihider")
    pcall(function()
        for _, child in ipairs(lp.PlayerGui:GetChildren()) do
            local name = child.Name:lower()
            if name:find("caught") or name:find("obtain") or name:find("reward") then
                if child:IsA("ScreenGui") then
                    child.Enabled = true
                else
                    child.Visible = true
                end
            end
        end
    end)
end

local isFishing = false
local activeUUID = nil

local currentCastSession = 0

local function doPull(uuid)
    if not uuid then return end
    logCast("Reel", "Starting pulling sequence for UUID: " .. tostring(uuid))
    
    -- Trigger client pull state animation
    pcall(function()
        services.FishingReplicationService:StartPulling()
    end)
    
    -- Send multiple pull inputs to complete minigame
    task.spawn(function()
        pcall(function()
            services.FishingRewardService:FishingPullInput(uuid, "begin")
        end)
        task.wait(0.02)
        
        local tapInterval = FAM.BlatantMode and 0.02 or 0.08
        for i = 1, 60 do
            if not FAM.AutoReel or not FAM.Enabled or not activeUUID then break end
            pcall(function()
                services.FishingRewardService:FishingPullInput(uuid, "tap")
            end)
            task.wait(tapInterval)
        end
        
        -- Safe fallback: wait 2.0 seconds before unlocking, giving time for event to fire.
        task.wait(2.0)
        if activeUUID == uuid then
            logCast("Reel Fallback", "Resetting isFishing after 2.0s pull fallback")
            isFishing = false
            activeUUID = nil
        end
    end)
end

local function startAutoCast()
    disconnect("cast")
    disconnect("castloop")
    disconnect("fishcaught")
    disconnect("fishsuccess")
    
    pcall(function() writefile("LeonX_CastLog.txt", "=== Cast Log Started ===") end)
    logCast("Init", "AutoCast initialized")
    
    -- Listen for fish caught event to know when to re-cast
    pcall(function()
        if services.FishingRewardService then
            connections.fishcaught = services.FishingRewardService.FishCaught:Connect(function()
                logCast("Event", "FishCaught event fired")
                isFishing = false
                activeUUID = nil
            end)
            connections.fishsuccess = services.FishingRewardService.FishingSuccess:Connect(function()
                logCast("Event", "FishingSuccess event fired")
                isFishing = false
                activeUUID = nil
            end)
        end
    end)
    
    local actionTimer = 0
    
    connections.castloop = RunService.Heartbeat:Connect(function(dt)
        if not FAM.Enabled or not FAM.AutoCast then return end
        if isFishing then return end
        
        local CAST_INTERVAL = FAM.BlatantMode and 0.5 or 3.0
        actionTimer = actionTimer + dt
        if actionTimer < CAST_INTERVAL then return end
        actionTimer = 0
        
        isFishing = true
        currentCastSession = currentCastSession + 1
        local mySession = currentCastSession
        
        logCast("Cast Loop", "Triggering cast sequence for session: " .. mySession)
        
        task.spawn(function()
            local success, err = pcall(function()
                if not services.FishingReplicationService then error("FishingReplicationService nil") end
                
                local hrp = getHRP()
                if not hrp then error("HRP nil") end
                
                local charPos = hrp.Position
                
                -- Use Raycast to find exact water height
                local castY = 168.50004577637 -- Fallback to Sea 1 water level
                pcall(function()
                    local params = RaycastParams.new()
                    params.IgnoreWater = false
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {lp.Character}
                    local result = workspace:Raycast(charPos + hrp.CFrame.LookVector * 15, Vector3.new(0, -150, 0), params)
                    if result then
                        castY = result.Position.Y
                    end
                end)
                
                local castPos = charPos + hrp.CFrame.LookVector * 15
                castPos = Vector3.new(castPos.X, castY, castPos.Z)
                
                local rod = getEquippedRod()
                local floater = getEquippedFloater()
                local visualData = {
                    LightInfluence = 0,
                    FaceCamera = true,
                    Color = Color3.new(1, 0.27058824896812, 0),
                    Transparency = 0.08,
                    LightEmission = 1,
                    Width = 0.16
                }
                local power = FAM.CastPower or 8.8843638102214
                
                logCast("Variables", string.format("Rod: %s | Floater: %s | Power: %f | AutoReel: %s", tostring(rod), tostring(floater), power, tostring(FAM.AutoReel)))
                
                -- Step 1: Stop any previous fishing session
                logCast("StopFishing", "Invoking StopFishing...")
                pcall(function() services.FishingReplicationService:StopFishing() end)
                task.wait(0.15)
                
                -- Step 2: Start fishing (ready the rod)
                logCast("StartFishing", "Invoking StartFishing...")
                services.FishingReplicationService:StartFishing(rod, floater)
                task.wait(0.1)
                
                -- Step 3: Throw the floater
                logCast("ThrowFloater", string.format("CharPos: %s | CastPos: %s", tostring(charPos), tostring(castPos)))
                services.FishingReplicationService:ThrowFloater(charPos, castPos, rod, floater, visualData, power)
                
                -- Wait for flight simulation (1.2 seconds in normal, 0.15 seconds in blatant)
                task.wait(FAM.BlatantMode and 0.15 or 1.2)
                
                -- Step 4: Confirm the cast landed on water
                logCast("ConfirmFloatingCast", "Invoking ConfirmFloatingCast...")
                pcall(function() services.FishingReplicationService:ConfirmFloatingCast(castPos) end)
                task.wait(FAM.BlatantMode and 0.1 or 0.5)
                
                -- Step 5: Instant Bite (force fish to bite immediately)
                if (FAM.InstantBite or FAM.BlatantMode) and services.FishingRewardService then
                    logCast("RequestFishBite", "Invoking RequestFishBite...")
                    local res = services.FishingRewardService:RequestFishBite(castPos)
                    logCast("RequestFishBite Result", tostring(res))
                    if res and type(res) == "table" then
                        -- Print full table structure
                        for k, v in pairs(res) do
                            logCast("BiteTableKey", string.format("key: %s | value: %s (%s)", tostring(k), tostring(v), type(v)))
                            if type(v) == "table" then
                                for k2, v2 in pairs(v) do
                                    logCast("BiteTableKeySub", string.format("  .%s = %s (%s)", tostring(k2), tostring(v2), type(v2)))
                                end
                            end
                        end
                        
                        local found = findUUID(res)
                        logCast("UUID Search", "Found: " .. tostring(found))
                        if found then
                            activeUUID = found
                            
                            -- Trigger auto reel immediately
                            if FAM.AutoReel then
                                task.wait(0.05)
                                doPull(found)
                            end
                        end
                    end
                end
            end)
            
            if not success then
                logCast("Error", "AutoCast failed: " .. tostring(err))
                isFishing = false
            end
            
            -- Safety: reset fishing state unconditionally after a short time if stuck
            task.delay(FAM.BlatantMode and 4 or 12, function()
                if isFishing and currentCastSession == mySession then
                    logCast("Timeout Safety", "Resetting isFishing to false (timeout reached) for session: " .. mySession)
                    isFishing = false
                    activeUUID = nil
                end
            end)
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTO REEL
-- ═══════════════════════════════════════════════════════════════════════════
local function startAutoReel()
    disconnect("reel")
    
    pcall(function()
        if services.FishingRewardService and services.FishingReplicationService then
            connections.reel = services.FishingRewardService.FishingPullState:Connect(function(arg1, arg2)
                -- Determine which parameter is active and if there's a UUID
                local state = arg1
                local uuid = activeUUID
                
                -- Extract UUID from argument if present
                local found1 = findUUID(arg1)
                local found2 = findUUID(arg2)
                if found1 then
                    uuid = found1
                    state = arg2
                elseif found2 then
                    uuid = found2
                    state = arg1
                end
                
                if state == false then
                    isFishing = false
                    activeUUID = nil
                end
                
                if state and FAM.AutoReel then
                    activeUUID = uuid
                    if uuid then
                        doPull(uuid)
                    end
                end
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AFK MODE (Game's Built-in AFK fishing)
-- ═══════════════════════════════════════════════════════════════════════════
local function setAfkMode(v)
    pcall(function()
        if services.FishingRewardService then
            services.FishingRewardService:SetAfkMode(v)
            print("[Leon X] FAM: AfkMode set to " .. tostring(v))
        end
    end)
end

local function startAutoSell()
    disconnect("sell")
    
    local actionTimer = 0
    
    connections.sell = RunService.Heartbeat:Connect(function(dt)
        if not FAM.Enabled or not FAM.AutoSell then return end
        if isFishing then return end -- Never sell while actively fishing
        
        -- Check every 2 seconds for inventory limit
        actionTimer = actionTimer + dt
        if actionTimer < 2.0 then return end
        actionTimer = 0
        
        task.spawn(function()
            local success, err = pcall(function()
                if not services.FishermanShopService then return end
                
                local hrp = getHRP()
                if not hrp then return end
                
                -- Count fish in inventory
                local fishCount = 0
                pcall(function()
                    local inv = services.FishermanShopService:GetFishInventory()
                    if inv and type(inv) == "table" then
                        for _ in pairs(inv) do
                            fishCount = fishCount + 1
                        end
                    end
                end)
                
                -- Only sell if count meets the threshold (defaults to 15)
                local limit = FAM.SellLimit or 15
                if fishCount < limit then return end
                
                -- Set state so we don't start fishing during sell
                isFishing = true
                
                -- Save original position
                local originalCFrame = hrp.CFrame
                
                -- Teleport to Fisherman NPC
                local fishermanShop = workspace:FindFirstChild("GameSystemObject")
                    and workspace.GameSystemObject:FindFirstChild("FishermanShop")
                
                if fishermanShop and fishermanShop:IsA("BasePart") then
                    hrp.CFrame = fishermanShop.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.4)
                end
                
                -- Sell all fish
                pcall(function()
                    services.FishermanShopService:SellAllFish()
                end)
                task.wait(0.4)
                
                -- Teleport back to original position
                if hrp and hrp.Parent then
                    hrp.CFrame = originalCFrame
                end
                
                task.wait(0.2)
                isFishing = false
            end)
            if not success then
                isFishing = false
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTO CHEST / TREASURE COLLECTOR (Teleport → Open → Return)
-- ═══════════════════════════════════════════════════════════════════════════
local isCollecting = false

local function startAutoCollect()
    disconnect("collect")
    
    local actionTimer = 0
    local COLLECT_INTERVAL = FAM.BlatantMode and 5 or 15
    
    connections.collect = RunService.Heartbeat:Connect(function(dt)
        if not FAM.Enabled or not FAM.AutoCollect then return end
        if isCollecting then return end
        
        actionTimer = actionTimer + dt
        if actionTimer < COLLECT_INTERVAL then return end
        actionTimer = 0
        
        isCollecting = true
        
        task.spawn(function()
            pcall(function()
                if not services.TreasureService then isCollecting = false return end
                
                local hrp = getHRP()
                if not hrp then isCollecting = false return end
                
                -- Save original position
                local originalCFrame = hrp.CFrame
                
                -- Get all active chests
                local chests = services.TreasureService:GetActiveChests()
                if not chests then isCollecting = false return end
                
                local opened = 0
                for chestId, chestData in pairs(chests) do
                    if not FAM.AutoCollect or not FAM.Enabled then break end
                    
                    pcall(function()
                        -- Get chest position from Attachment
                        local attachment = chestData.Attachment
                        if attachment and typeof(attachment) == "Instance" then
                            local pos = attachment.WorldPosition or attachment.Position
                            if pos then
                                -- Teleport to chest
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                task.wait(FAM.BlatantMode and 0.2 or 0.5)
                            end
                        end
                        
                        -- Open chest
                        services.TreasureService:RequestOpenChest(chestId)
                        opened = opened + 1
                        task.wait(FAM.BlatantMode and 0.3 or 0.8)
                    end)
                end
                
                -- Teleport back to original position
                if hrp and hrp.Parent and opened > 0 then
                    hrp.CFrame = originalCFrame
                end
            end)
            
            isCollecting = false
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AUTO QUEST
-- ═══════════════════════════════════════════════════════════════════════════
local function startAutoQuest()
    disconnect("quest")
    
    local actionTimer = 0
    local QUEST_INTERVAL = 5
    
    connections.quest = RunService.Heartbeat:Connect(function(dt)
        if not FAM.Enabled or not FAM.AutoQuest then return end
        
        actionTimer = actionTimer + dt
        if actionTimer < QUEST_INTERVAL then return end
        actionTimer = 0
        
        pcall(function()
            if services.QuestService then
                -- Try to claim normal quest reward
                services.QuestService:ClaimReward()
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ENTITY ESP (Highlights)
-- ═══════════════════════════════════════════════════════════════════════════
local function createESPHighlight(instance, color, label)
    if not instance or not instance:IsA("BasePart") and not instance:IsA("Model") then return nil end
    
    local espName = "LeonX_ESP_" .. HttpService:GenerateGUID(false)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = espName
    highlight.FillColor = color
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0.3
    highlight.Adornee = instance
    highlight.Parent = instance
    espObjects[#espObjects + 1] = highlight
    
    if label then
        local adornee = instance
        if instance:IsA("Model") then
            adornee = instance:FindFirstChild("HumanoidRootPart") or instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
        end
        if not adornee then return highlight end

        local bb = Instance.new("BillboardGui")
        bb.Name = espName .. "_BB"
        bb.Size = UDim2.new(0, 120, 0, 30)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = adornee
        
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.fromScale(1, 1)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = color
        txt.TextStrokeTransparency = 0.5
        txt.TextStrokeColor3 = Color3.new(0, 0, 0)
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 13
        txt.TextScaled = false
        txt.Text = label
        txt.Parent = bb
        
        bb.Parent = adornee
        espObjects[#espObjects + 1] = bb
    end
    
    return highlight
end

local function startFishESP()
    disconnect("fishesp")
    clearESP()
    
    local function scanForEntities()
        clearESP()
        if not FAM.FishESP and not FAM.MonsterESP and not FAM.TreasureESP then return end
        
        pcall(function()
            -- Scan Fish
            if FAM.FishESP then
                local fishFolder = workspace:FindFirstChild("Fish") or workspace:FindFirstChild("Fishes")
                if fishFolder then
                    for _, fish in ipairs(fishFolder:GetChildren()) do
                        createESPHighlight(fish, Color3.fromRGB(0, 170, 255), fish.Name)
                    end
                end
            end
            
            -- Scan Monsters
            if FAM.MonsterESP then
                local monsterFolder = workspace:FindFirstChild("Monsters") or workspace:FindFirstChild("SeaMonsters")
                if monsterFolder then
                    for _, monster in ipairs(monsterFolder:GetChildren()) do
                        createESPHighlight(monster, Color3.fromRGB(255, 50, 50), "👹 " .. monster.Name)
                    end
                end
            end
            
            -- Scan Chests
            if FAM.TreasureESP then
                local chestsFolder = workspace:FindFirstChild("Chests") or workspace:FindFirstChild("Treasures")
                if chestsFolder then
                    for _, chest in ipairs(chestsFolder:GetChildren()) do
                        createESPHighlight(chest, Color3.fromRGB(255, 215, 0), "🎁 Chest")
                    end
                end
            end
        end)
    end
    
    scanForEntities()
    
    -- Periodic rescan
    local espTimer = 0
    connections.fishesp = RunService.Heartbeat:Connect(function(dt)
        if not FAM.FishESP and not FAM.MonsterESP and not FAM.TreasureESP then return end
        espTimer = espTimer + dt
        if espTimer < 5 then return end
        espTimer = 0
        scanForEntities()
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ISLAND TELEPORT
-- ═══════════════════════════════════════════════════════════════════════════
local islandNames = {}

local function getIslandNames()
    islandNames = {
        "Starter Island",
        "My Plot",
        "Boat Shop",
        "Base",
        "Sea 1",
        "Sea 2",
        "Sea 3",
        "Deep Sea",
        "Coral Reef",
        "Monster Cove",
        "Treasure Bay",
    }
    return islandNames
end

local function teleportToIsland(islandName)
    pcall(function()
        if Knit then
            if islandName == "Boat Shop" then
                if services.SpawnService then services.SpawnService:RequestBoatShopTeleport() end
            elseif islandName == "My Plot" then
                if services.SpawnService then services.SpawnService:RequestPlotTeleport() end
            elseif islandName == "Base" then
                if services.SeaLobbyService then services.SeaLobbyService:ReturnToBase() end
            else
                if services.SeaLobbyService then services.SeaLobbyService:RequestSea(islandName) end
            end
        end
        
        -- Fallback: Physical CFrame teleport
        local hrp = getHRP()
        if not hrp then return end
        
        local target = workspace:FindFirstChild(islandName) 
            or (workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild(islandName))
            or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild(islandName))
            
        if target then
            local pos = target:IsA("Model") and (target.PrimaryPart and target.PrimaryPart.Position or target:GetBoundingBox().Position) or target.Position
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 10, 0))
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MODULE INTERFACE
-- ═══════════════════════════════════════════════════════════════════════════
function FAM:Init()
    task.wait(1)
    findRemotes()
    getIslandNames()
end

function FAM:Enable()
    self.Enabled = true
end

function FAM:Disable()
    self.Enabled = false
    self.AutoCast       = false
    self.AutoReel       = false
    self.InstantBite    = false
    self.AfkMode        = false
    self.AutoSell       = false
    self.AutoCollect    = false
    self.AutoQuest      = false
    self.FishESP        = false
    self.MonsterESP     = false
    self.TreasureESP    = false
    self.BlatantMode    = false
    self.HideCatchUI    = false
    stopUIHider()
    setAfkMode(false)
    clearESP()
    disconnectAll()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- WIRE UI
-- ═══════════════════════════════════════════════════════════════════════════
function FAM:WireUI(Window, extras)
    extras = extras or {}
    local ConfigMgr = extras.ConfigMgr
    local N = extras.N or function() end

    local FishTab     = Window:Tab({ Title = "Fishing",  Icon = "🎣" })
    local ESPTab      = Window:Tab({ Title = "ESP",      Icon = "👁️" })
    local TravelTab   = Window:Tab({ Title = "Travel",   Icon = "🏝️" })
    local SettingsTab = Window:Tab({ Title = "Settings", Icon = "⚙️" })

    -- ══ FISHING TAB ═══════════════════════════════════════════════════════
    FishTab:Section({ Title = "Auto Fishing" })

    FishTab:Toggle({
        Title    = "Auto Cast",
        Flag     = "FAM_AutoCast",
        Default  = false,
        Tooltip  = "Automatically cast your fishing rod",
        Callback = function(v)
            FAM.AutoCast = v
            if v then
                FAM.Enabled = true
                startAutoCast()
            else
                disconnect("cast")
            end
            N("Auto Cast", v and "Enabled" or "Disabled")
        end
    })

    FishTab:Toggle({
        Title    = "Instant Bite",
        Flag     = "FAM_InstantBite",
        Default  = false,
        Tooltip  = "Force fish to bite instantly after cast",
        Callback = function(v)
            FAM.InstantBite = v
            N("Instant Bite", v and "Enabled" or "Disabled")
        end
    })

    FishTab:Toggle({
        Title    = "Blatant Mode",
        Flag     = "FAM_BlatantMode",
        Default  = false,
        Tooltip  = "⚠️ WARNING: Bypasses wait timers for ultra-fast catching. High Ban Risk!",
        Callback = function(v)
            FAM.BlatantMode = v
            N("Blatant Mode", v and "Enabled (High Risk)" or "Disabled")
        end
    })

    FishTab:Toggle({
        Title    = "Auto Reel",
        Flag     = "FAM_AutoReel",
        Default  = false,
        Tooltip  = "Automatically reel fish when it bites",
        Callback = function(v)
            FAM.AutoReel = v
            if v then
                FAM.Enabled = true
                startAutoReel()
            else
                disconnect("reel")
            end
            N("Auto Reel", v and "Enabled" or "Disabled")
        end
    })

    FishTab:Toggle({
        Title    = "In-Game AFK Mode",
        Flag     = "FAM_AfkMode",
        Default  = false,
        Tooltip  = "Toggles the game's built-in AFK fishing mode",
        Callback = function(v)
            FAM.AfkMode = v
            setAfkMode(v)
            N("AFK Fishing", v and "Enabled" or "Disabled")
        end
    })

    FishTab:Toggle({
        Title    = "Hide Catch GUI",
        Flag     = "FAM_HideCatchUI",
        Default  = false,
        Tooltip  = "Hides the obtain fish pop-up screen to reduce clutter",
        Callback = function(v)
            FAM.HideCatchUI = v
            if v then
                startUIHider()
            else
                stopUIHider()
            end
            N("Hide Catch GUI", v and "Enabled" or "Disabled")
        end
    })

    FishTab:Section({ Title = "Economy & Collection" })

    FishTab:Toggle({
        Title    = "Auto Sell Fish",
        Flag     = "FAM_AutoSell",
        Default  = false,
        Tooltip  = "Automatically sells all fish in inventory",
        Callback = function(v)
            FAM.AutoSell = v
            if v then
                FAM.Enabled = true
                startAutoSell()
            else
                disconnect("sell")
            end
            N("Auto Sell", v and "Enabled" or "Disabled")
        end
    })

    FishTab:Slider({
        Title    = "Inventory Limit to Sell",
        Flag     = "FAM_SellLimit",
        Value    = { Min = 1, Max = 30, Default = 15 },
        Step     = 1,
        Tooltip  = "Number of fish in inventory before teleporting to sell",
        Callback = function(v)
            FAM.SellLimit = v
        end
    })

    FishTab:Toggle({
        Title    = "Auto Collect Chests",
        Flag     = "FAM_AutoCollect",
        Default  = false,
        Tooltip  = "Automatically claims spawned chests",
        Callback = function(v)
            FAM.AutoCollect = v
            if v then
                FAM.Enabled = true
                startAutoCollect()
            else
                disconnect("collect")
            end
            N("Auto Collect Chests", v and "Enabled" or "Disabled")
        end
    })

    FishTab:Toggle({
        Title    = "Auto Claim Quests",
        Flag     = "FAM_AutoQuest",
        Default  = false,
        Tooltip  = "Automatically claim completed quest rewards",
        Callback = function(v)
            FAM.AutoQuest = v
            if v then
                FAM.Enabled = true
                startAutoQuest()
            else
                disconnect("quest")
            end
            N("Auto Quest", v and "Enabled" or "Disabled")
        end
    })

    -- ══ ESP TAB ═══════════════════════════════════════════════════════════
    ESPTab:Section({ Title = "Entity ESP" })

    ESPTab:Toggle({
        Title    = "Fish ESP",
        Flag     = "FAM_FishESP",
        Default  = false,
        Callback = function(v)
            FAM.FishESP = v
            if v then
                FAM.Enabled = true
                startFishESP()
            else
                clearESP()
            end
            N("Fish ESP", v and "Enabled" or "Disabled")
        end
    })

    ESPTab:Toggle({
        Title    = "Monster ESP",
        Flag     = "FAM_MonsterESP",
        Default  = false,
        Callback = function(v)
            FAM.MonsterESP = v
            if v then
                FAM.Enabled = true
                startFishESP()
            else
                clearESP()
                if FAM.FishESP or FAM.TreasureESP then startFishESP() end
            end
            N("Monster ESP", v and "Enabled" or "Disabled")
        end
    })

    ESPTab:Toggle({
        Title    = "Chest ESP",
        Flag     = "FAM_TreasureESP",
        Default  = false,
        Callback = function(v)
            FAM.TreasureESP = v
            if v then
                FAM.Enabled = true
                startFishESP()
            else
                clearESP()
                if FAM.FishESP or FAM.MonsterESP then startFishESP() end
            end
            N("Chest ESP", v and "Enabled" or "Disabled")
        end
    })

    -- ══ TRAVEL TAB ═══════════════════════════════════════════════════════
    TravelTab:Section({ Title = "Island & Shop Teleports" })

    TravelTab:Dropdown({
        Title    = "Select Island",
        Flag     = "FAM_SelectedIsland",
        Default  = islandNames[1] or "Starter Island",
        Values   = islandNames,
        Callback = function(v)
            FAM.SelectedIsland = v
        end
    })

    TravelTab:Button({
        Title    = "Teleport to Destination",
        Callback = function()
            if FAM.SelectedIsland and FAM.SelectedIsland ~= "" then
                teleportToIsland(FAM.SelectedIsland)
                N("Travel", "Teleporting to " .. FAM.SelectedIsland)
            else
                N("Travel", "Select destination first!")
            end
        end
    })

    -- ══ SETTINGS TAB ═══════════════════════════════════════════════════════
    if ConfigMgr then
        SettingsTab:Section({ Title = "Config" })
        
        local cfgNameIn = SettingsTab:Input({
            Title       = "Config Name",
            Flag        = "FAM_ConfigName",
            Placeholder = "e.g. myconfig",
            Value       = "default",
            Callback    = function() end
        })
        
        local function getCfgName()
            local v = cfgNameIn.Value
            return (v and v ~= "") and v or "default"
        end
        
        local function getCfgList()
            local l = ConfigMgr:List()
            return #l > 0 and l or {"(none)"}
        end
        
        local selectedConfig = nil
        local cfgDrop = SettingsTab:Dropdown({
            Title    = "Select Config",
            Values   = getCfgList(),
            Value    = 1,
            Callback = function(v) selectedConfig = v end
        })
        do local list = getCfgList(); selectedConfig = list[1] end
        
        SettingsTab:Button({
            Title    = "Save Config",
            Callback = function()
                local n = getCfgName()
                local ok = ConfigMgr:Save(n)
                if ok then
                    local list = getCfgList()
                    cfgDrop:Refresh(list)
                    selectedConfig = n
                    cfgDrop:Select(n)
                    N("Config", "Saved: " .. n)
                else
                    N("Config", "Save failed")
                end
            end
        })
        
        SettingsTab:Button({
            Title    = "Load Config",
            Callback = function()
                local s = selectedConfig
                if not s or s == "(none)" then return end
                local ok = ConfigMgr:Load(s)
                if ok then
                    N("Config", "Loaded: " .. s)
                else
                    N("Config", "Load failed")
                end
            end
        })
        
        SettingsTab:Button({
            Title    = "Delete Config",
            Callback = function()
                local s = selectedConfig
                if not s or s == "(none)" then return end
                ConfigMgr:Delete(s)
                local list = getCfgList()
                cfgDrop:Refresh(list)
                selectedConfig = list[1]
                N("Config", "Deleted: " .. s)
            end
        })
        
        SettingsTab:Button({
            Title    = "Set as Default",
            Callback = function()
                local s = selectedConfig
                if not s or s == "(none)" then return end
                local ok = ConfigMgr:SetDefault(s)
                if ok then
                    N("Config", s .. " is now default")
                end
            end
        })
    end

    SettingsTab:Section({ Title = "About" })
    SettingsTab:Paragraph({
        Title   = "Leon X - Fish And Monsters",
        Content = "v1.1 - by leonx24\n\nFully automated Knit features wired directly from the client."
    })
end

return FAM
