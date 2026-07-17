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
FAM.AntiAFK        = false
FAM.AutoBuyRod     = false
FAM.AutoBuyFloater = false
FAM.AutoBuyEgg     = false
FAM.SelectedEgg    = "Common Egg"


local connections = {}
local espObjects  = {}
local Fly, Speed, InfiniteJump, PerfStats, FullBright, RemoveFog, Rejoin, ServerHop, Noclip

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
            
            -- Bind Pet, Egg, Rod, and Potion services asynchronously to prevent infinite yielding if they don't exist
            local function bindAsync(name, key)
                task.spawn(function()
                    pcall(function()
                        local s = Knit.GetService(name)
                        if s then
                            services[key] = s
                            print("[Leon X] FAM: Bound " .. name .. " successfully!")
                        end
                    end)
                end)
            end
            
            bindAsync("PetService", "PetService")
            bindAsync("PetShopService", "PetShopService")
            bindAsync("EggService", "EggService")
            bindAsync("EggShopService", "EggShopService")
            bindAsync("RodShopService", "RodShopService")
            bindAsync("PotionShopService", "PotionShopService")
            bindAsync("SavePointService", "SavePointService")
            
            print("[Leon X] FAM: Bound all primary Knit services successfully!")
            
            pcall(function()
                logCast("Service Dump", "Dumping FishermanShopService:")
                for k, v in pairs(services.FishermanShopService) do
                    logCast("Service Dump", string.format("  .%s = %s", tostring(k), type(v)))
                end
                if services.FishermanShopService.RF then
                    for k, v in pairs(services.FishermanShopService.RF) do
                        logCast("Service Dump RF", string.format("  .RF.%s = %s", tostring(k), type(v)))
                    end
                end
                if services.FishermanShopService.RE then
                    for k, v in pairs(services.FishermanShopService.RE) do
                        logCast("Service Dump RE", string.format("  .RE.%s = %s", tostring(k), type(v)))
                    end
                end
            end)
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

local uiConnections = {}
local originalStates = {}

local targetGuis = {
    NewFishDiscovery = true,
    PetGachaGui = true,
    NotificationGui = true,
    NotificationGuiV2 = true,
    DailyRewardGUI = true,
    RewardGui = true
}

local scanGuis = {
    HUD = true,
    TreasureGUI = true,
    NotificationGui = true,
    NotificationGuiV2 = true,
    NewFishDiscovery = true,
    PetGachaGui = true,
    RewardGui = true,
    DailyRewardGUI = true
}

local targetFrames = {
    RewardPanel = true,
    LootNotification = true,
    CollectionNotification = true,
    CollectionNotificationFrame = true,
    Backdrop = true,
    Card = true,
    CaughtFrame = true,
    ObtainFrame = true,
    SuccessFrame = true,
    CatchFrame = true,
    LootFrame = true,
    RewardFrame = true,
    NotificationTemplate = true
}

local function startUIHider()
    stopUIHider() -- Ensure cleaned up first
    
    local function hideElement(child)
        if child:IsA("ScreenGui") then
            if originalStates[child] == nil then
                originalStates[child] = child.Enabled
            end
            child.Enabled = false
            if not uiConnections[child] then
                uiConnections[child] = child:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if FAM.HideCatchUI and child.Enabled then
                        child.Enabled = false
                    end
                end)
            end
        elseif child:IsA("GuiObject") then
            if originalStates[child] == nil then
                originalStates[child] = child.Visible
            end
            child.Visible = false
            if not uiConnections[child] then
                uiConnections[child] = child:GetPropertyChangedSignal("Visible"):Connect(function()
                    if FAM.HideCatchUI and child.Visible then
                        child.Visible = false
                    end
                end)
            end
        end
    end

    -- Process target ScreenGuis and parents that already exist in PlayerGui
    for name, _ in pairs(scanGuis) do
        local gui = lp.PlayerGui:FindFirstChild(name)
        if gui then
            if targetGuis[name] then
                hideElement(gui)
            end
            -- Hide target frames inside it
            for _, desc in ipairs(gui:GetDescendants()) do
                if targetFrames[desc.Name] then
                    hideElement(desc)
                end
            end
            -- Listen only to descendants added within this target Gui (extremely low frequency)
            uiConnections[gui.Name .. "_DescAdded"] = gui.DescendantAdded:Connect(function(desc)
                if targetFrames[desc.Name] then
                    hideElement(desc)
                end
            end)
        end
    end

    -- Listen to PlayerGui ChildAdded only for top-level ScreenGui additions (0% lag impact)
    connections.uihider = lp.PlayerGui.ChildAdded:Connect(function(child)
        local name = child.Name
        if scanGuis[name] then
            if targetGuis[name] then
                hideElement(child)
            end
            for _, desc in ipairs(child:GetDescendants()) do
                if targetFrames[desc.Name] then
                    hideElement(desc)
                end
            end
            uiConnections[child.Name .. "_DescAdded"] = child.DescendantAdded:Connect(function(desc)
                if targetFrames[desc.Name] then
                    hideElement(desc)
                end
            end)
        end
    end)
end

local function stopUIHider()
    disconnect("uihider")
    for inst, conn in pairs(uiConnections) do
        pcall(function() conn:Disconnect() end)
    end
    uiConnections = {}
    
    -- Restore original enabled/visible states to avoid breaking game HUD
    pcall(function()
        for child, origState in pairs(originalStates) do
            if child and child.Parent then
                if child:IsA("ScreenGui") then
                    child.Enabled = origState
                elseif child:IsA("GuiObject") then
                    child.Visible = origState
                end
            end
        end
    end)
    originalStates = {}
end

local function startAntiAFK()
    disconnect("antiafk")
    disconnect("reconnect")
    
    pcall(function()
        connections.antiafk = lp.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
            logCast("Anti-AFK", "Prevented disconnect due to idling")
        end)
    end)
    
    pcall(function()
        connections.reconnect = game:GetService("GuiService").ErrorMessageChanged:Connect(function()
            task.wait(5)
            game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
        end)
    end)
end

local function stopAntiAFK()
    disconnect("antiafk")
    disconnect("reconnect")
end

local function openShopGUI(state)
    pcall(function()
        local playerGui = lp:WaitForChild("PlayerGui")
        -- Search for typical Shop/Pet GUIs and set their Enabled/Visible state
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local lowerName = gui.Name:lower()
                if lowerName:find("shop") or lowerName:find("pet") or lowerName:find("egg") or lowerName:find("hatch") or lowerName:find("upgrade") or lowerName:find("rod") then
                    gui.Enabled = state
                end
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                        local dName = desc.Name:lower()
                        if dName:find("shop") or dName:find("pet") or dName:find("egg") or dName:find("hatch") or dName:find("upgrade") or dName:find("rod") or dName:find("main") or dName:find("content") then
                            desc.Visible = state
                        end
                    end
                end
            end
        end
        
        -- Fallback: Check inside common parent frames
        for _, guiName in ipairs({"MainGui", "Main", "HUD", "LobbyGui", "ScreenGui"}) do
            local gui = playerGui:FindFirstChild(guiName)
            if gui then
                for _, child in ipairs(gui:GetDescendants()) do
                    if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                        local name = child.Name:lower()
                        if name:find("shop") or name:find("pet") or name:find("egg") or name:find("hatch") or name:find("upgrade") or name:find("rod") then
                            child.Visible = state
                        end
                    end
                end
            end
        end
    end)
end

local function toggleShopGUI(name, state)
    pcall(function()
        local playerGui = lp:WaitForChild("PlayerGui")
        local gui = playerGui:FindFirstChild(name)
        
        -- Case-insensitive fallback
        if not gui then
            for _, child in ipairs(playerGui:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name:lower() == name:lower() then
                    gui = child
                    break
                end
            end
        end
        
        -- Special fallbacks for Pet Gacha
        if not gui and name == "PetGachaGui" then
            for _, child in ipairs(playerGui:GetChildren()) do
                if child:IsA("ScreenGui") then
                    local ln = child.Name:lower()
                    if ln == "petgachagui" or ln == "petgacha" or ln == "petshop" or ln == "petshopgui" or ln == "egggachagui" or ln == "egggacha" or ln:find("petgacha") then
                        gui = child
                        break
                    end
                end
            end
        end

        -- Special fallbacks for Equipment Shop
        if not gui and name == "EquipmentShopGUI" then
            for _, child in ipairs(playerGui:GetChildren()) do
                if child:IsA("ScreenGui") then
                    local ln = child.Name:lower()
                    if ln == "equipmentshopgui" or ln == "equipmentshop" or ln == "gearshop" or ln == "gearshopgui" or ln:find("equipmentshop") then
                        gui = child
                        break
                    end
                end
            end
        end

        -- Special fallbacks for Potion/General Shop
        if not gui and name == "Shop" then
            for _, child in ipairs(playerGui:GetChildren()) do
                if child:IsA("ScreenGui") then
                    local ln = child.Name:lower()
                    if ln == "shop" or ln == "potionshop" or ln == "potionshopgui" or (ln:find("shop") and not ln:find("equipment") and not ln:find("pet")) then
                        gui = child
                        break
                    end
                end
            end
        end

        if gui then
            gui.Enabled = state
            local mainPanel = gui:FindFirstChild("MainPanel") 
                or gui:FindFirstChild("ShopPanel") 
                or gui:FindFirstChild("Frame")
                or gui:FindFirstChildWhichIsA("Frame")
            if mainPanel then
                mainPanel.Visible = state
            end
        end
    end)
end

local function buyNextEquipment(type)
    pcall(function()
        local shopGui = lp.PlayerGui:FindFirstChild("EquipmentShopGUI")
        if not shopGui then return end
        
        -- Open Shop GUI to bypass server checks
        shopGui.Enabled = true
        local mainPanel = shopGui:FindFirstChild("MainPanel")
        if mainPanel then mainPanel.Visible = true end
        
        task.wait(0.25)
        
        -- Switch Tab (RodsTab or FloatersTab)
        local tabFrame = mainPanel and mainPanel:FindFirstChild("TabFrame")
        local tabBtn = tabFrame and tabFrame:FindFirstChild(type .. "sTab")
        if tabBtn and tabBtn:IsA("TextButton") then
            -- Simulate clicking tab
            local clicked = false
            if getconnections then
                for _, conn in ipairs(getconnections(tabBtn.MouseButton1Click)) do
                    conn:Fire()
                    clicked = true
                end
            end
            if not clicked then
                tabBtn.Visible = true
            end
        end
        
        task.wait(0.35)
        
        -- Find first buyable item in ContentFrame
        local contentFrame = mainPanel and mainPanel:FindFirstChild("ContentFrame")
        if contentFrame then
            for _, card in ipairs(contentFrame:GetChildren()) do
                if card:IsA("Frame") and card.Name:find(type .. "Card_") then
                    local actionBtn = card:FindFirstChild("BottomContainer") 
                        and card.BottomContainer:FindFirstChild("ActionButton")
                    if actionBtn and actionBtn:IsA("TextButton") then
                        local txt = actionBtn.Text:lower()
                        -- If it is a buy button (doesn't say equip/equipped/owned)
                        if not txt:find("equip") and not txt:find("owned") and txt ~= "" then
                            -- Click buy button
                            local clicked = false
                            if getconnections then
                                for _, conn in ipairs(getconnections(actionBtn.MouseButton1Click)) do
                                    conn:Fire()
                                    clicked = true
                                end
                            end
                            
                            -- Knit service fallback
                            local itemId = card.Name:match(type .. "Card_(.+)")
                            if itemId and services.RodShopService then
                                pcall(function()
                                    if type == "Rod" then
                                        services.RodShopService:BuyRod(itemId)
                                    else
                                        services.RodShopService:BuyFloater(itemId)
                                    end
                                end)
                            end
                            
                            task.wait(0.2)
                            break -- Buy one item per loop iteration to be safe
                        end
                    end
                end
            end
        end
        
        task.wait(0.25)
        if mainPanel then mainPanel.Visible = false end
    end)
end

local function startUpgradeLoop()
end

local function stopUpgradeLoop()
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
        
        -- Continuously restore movement / controls when blatant is active to prevent freeze
        if FAM.BlatantMode then
            pcall(function()
                -- Re-enable controls
                local playerModule = lp.PlayerScripts:FindFirstChild("PlayerModule")
                if playerModule then
                    local controls = require(playerModule):GetControls()
                    if controls then
                        controls:Enable()
                    end
                end
                
                local char = lp.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.PlatformStand = false
                end
                
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Anchored then
                    hrp.Anchored = false
                end
            end)
        end
        
        if isFishing then return end
        
        -- Check if inventory limit reached before casting to allow Auto Sell to execute
        local fishCount = 0
        pcall(function()
            if services.FishermanShopService then
                local inv = services.FishermanShopService:GetFishInventory()
                if inv and type(inv) == "table" then
                    for _ in pairs(inv) do
                        fishCount = fishCount + 1
                    end
                end
            end
        end)
        local limit = FAM.SellLimit or 15
        if FAM.AutoSell and fishCount >= limit then
            return
        end
        
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
                -- Try to claim completed quest rewards
                services.QuestService:ClaimReward()
                
                -- Auto Accept Daily Quest Status
                safeQuestInvoke("GetDailyQuestStatus")
                
                -- Auto Accept Weekly Quests
                safeQuestInvoke("AcceptWeeklyQuest", "weekly_abyssal_collector")
                safeQuestInvoke("AcceptWeeklyQuest", "weekly_mythical_hunter")
                safeQuestInvoke("AcceptWeeklyQuest", "weekly_grand_merchant")
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
    islandNames = {}
    pcall(function()
        local activeIslands = workspace:FindFirstChild("ActiveIslands")
            or workspace:FindFirstChild("Islands")
            or workspace:FindFirstChild("Map")
            
        if activeIslands then
            for _, child in ipairs(activeIslands:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") or child:IsA("Part") then
                    table.insert(islandNames, child.Name)
                end
            end
        end
    end)
    -- Fallback list if folders don't exist/load (Fisch fallback removed; correct Fish and Monsters fallback)
    if #islandNames == 0 then
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
            "Treasure Bay"
        }
    end
    -- Sort names alphabetically
    table.sort(islandNames)
    return islandNames
end

local function getCurrentIsland()
    local hrp = getHRP()
    if not hrp then return nil end
    
    local closestIsland = nil
    local minDistance = math.huge
    
    pcall(function()
        local folder = workspace:FindFirstChild("ActiveIslands")
            or workspace:FindFirstChild("Islands")
            or workspace:FindFirstChild("Map")
            or workspace
            
        local targets = {}
        if folder == workspace then
            local known = {
                ["Starter Island"] = true, ["My Plot"] = true, ["Boat Shop"] = true, ["Base"] = true,
                ["Sea 1"] = true, ["Sea 2"] = true, ["Sea 3"] = true, ["Deep Sea"] = true,
                ["Coral Reef"] = true, ["Monster Cove"] = true, ["Treasure Bay"] = true
            }
            for _, child in ipairs(workspace:GetChildren()) do
                if child:IsA("Model") and known[child.Name] then
                    table.insert(targets, child)
                end
            end
        else
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") or child:IsA("Part") then
                    table.insert(targets, child)
                end
            end
        end
        
        for _, child in ipairs(targets) do
            local pos = child:IsA("Model") and (child.PrimaryPart and child.PrimaryPart.Position or child:GetBoundingBox().Position) or child.Position
            local dist = (hrp.Position - pos).Magnitude
            if dist < minDistance then
                minDistance = dist
                closestIsland = child.Name
            end
        end
    end)
    return closestIsland
end

local function setSavePoint(islandName)
    pcall(function()
        if services.SavePointService then
            services.SavePointService:ConfirmSave(islandName)
        else
            local rfFolder = ReplicatedStorage:FindFirstChild("Packages")
                and ReplicatedStorage.Packages:FindFirstChild("_Index")
                and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_knit@1.7.0")
                and ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"]:FindFirstChild("knit")
                and ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit:FindFirstChild("Services")
                and ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services:FindFirstChild("SavePointService")
                and ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.SavePointService:FindFirstChild("RF")
                
            if rfFolder then
                local remote = rfFolder:FindFirstChild("ConfirmSave")
                if remote and remote:IsA("RemoteFunction") then
                    remote:InvokeServer(islandName)
                end
            end
        end
    end)
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

local function safeQuestInvoke(methodName, ...)
    local args = {...}
    local success, res = pcall(function()
        if services.QuestService and services.QuestService[methodName] then
            return services.QuestService[methodName](services.QuestService, unpack(args))
        end
    end)
    if success and res ~= nil then return res end
    
    pcall(function()
        local rfFolder = ReplicatedStorage:FindFirstChild("Packages")
            and ReplicatedStorage.Packages:FindFirstChild("_Index")
            and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_knit@1.7.0")
            and ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"]:FindFirstChild("knit")
            and ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit:FindFirstChild("Services")
            and ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services:FindFirstChild("QuestService")
            and ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.QuestService:FindFirstChild("RF")
            
        if rfFolder then
            local remote = rfFolder:FindFirstChild(methodName)
            if remote and remote:IsA("RemoteFunction") then
                return remote:InvokeServer(unpack(args))
            end
        end
    end)
end

local function teleportToInnkeeper(islandName)
    local targetNPC = nil
    pcall(function()
        local function findNPC(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("Model") then
                    local name = child.Name:lower()
                    if name:find("keeper") or name:find("spawn") or name:find("save") or name:find("location") or name:find("point") or name:find("npc") then
                        targetNPC = child
                        break
                    end
                end
                if child:IsA("Folder") or child:IsA("Model") or child == workspace then
                    findNPC(child)
                end
                if targetNPC then break end
            end
        end

        local island = workspace:FindFirstChild(islandName)
            or (workspace:FindFirstChild("Islands") and workspace.Islands:FindFirstChild(islandName))
            or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild(islandName))
            
        if island then
            findNPC(island)
        end
        if not targetNPC then
            findNPC(workspace)
        end
    end)
    
    if targetNPC then
        pcall(function()
            local hrp = getHRP()
            if hrp then
                local pos = targetNPC.PrimaryPart and targetNPC.PrimaryPart.Position or targetNPC:GetBoundingBox().Position
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            end
        end)
        return true
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MODULE INTERFACE
-- ═══════════════════════════════════════════════════════════════════════════
function FAM:Init()
    task.wait(1)
    findRemotes()
    getIslandNames()
    self.Enabled = true
    print("[Leon X] Booting Version 5.0 (Optimized Blatant & Hider Performance Hotfix)")
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
    self.AntiAFK        = false
    self.AutoBuyRod     = false
    self.AutoBuyFloater = false
    self.AutoBuyEgg     = false
    stopUIHider()
    stopAntiAFK()
    stopUpgradeLoop()
    setAfkMode(false)
    clearESP()
    disconnectAll()
    
    pcall(function() if Fly and Fly.Disable then Fly:Disable() end end)
    pcall(function() if Speed and Speed.Disable then Speed:Disable() end end)
    pcall(function() if InfiniteJump and InfiniteJump.Disable then InfiniteJump:Disable() end end)
    pcall(function() if FullBright and FullBright.Disable then FullBright:Disable() end end)
    pcall(function() if RemoveFog and RemoveFog.Disable then RemoveFog:Disable() end end)
    pcall(function() if PerfStats and PerfStats.Disable then PerfStats:Disable() end end)
    pcall(function() if Noclip and Noclip.Disable then Noclip:Disable() end end)
    
    -- Close any opened shop GUIs
    pcall(function()
        for _, guiName in ipairs({"EquipmentShopGUI", "PetGachaGui", "Shop"}) do
            toggleShopGUI(guiName, false)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- WIRE UI
-- ═══════════════════════════════════════════════════════════════════════════
function FAM:WireUI(Window, extras)
    extras = extras or {}
    local ConfigMgr = extras.ConfigMgr
    local N = extras.N or function() end
    
    Fly          = extras.Fly
    Speed        = extras.Speed
    InfiniteJump = extras.InfiniteJump
    PerfStats    = extras.PerfStats
    FullBright   = extras.FullBright
    RemoveFog    = extras.RemoveFog
    Rejoin       = extras.Rejoin
    ServerHop    = extras.ServerHop
    Noclip       = extras.Noclip

    local FishTab     = Window:Tab({ Title = "Fishing",  Icon = "🎣" })
    local ESPTab      = Window:Tab({ Title = "ESP",      Icon = "👁️" })
    local TravelTab   = Window:Tab({ Title = "Travel",   Icon = "🏝️" })
    local SettingsTab = Window:Tab({ Title = "Settings", Icon = "⚙️" })

    -- Helper function to make sections collapsible with right-aligned arrows
    local function createCollapsible(tab, title, components)
        local collapsed = true
        local btnApi = tab:Button({
            Title    = title,
            Style    = "Surface",
            Callback = function() end -- Handled by textBtn click below
        })
        
        local arrow = Instance.new("TextLabel")
        arrow.Name = "CollapseArrow"
        arrow.Size = UDim2.new(0, 30, 1, 0)
        arrow.Position = UDim2.new(1, -35, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▶"
        arrow.TextColor3 = Window._theme.TextSub
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 12
        arrow.ZIndex = 8
        
        pcall(function()
            local textBtn = btnApi.Frame:FindFirstChildOfClass("TextButton")
            if textBtn then
                arrow.Parent = textBtn
                textBtn.TextXAlignment = Enum.TextXAlignment.Left
                local pad = Instance.new("UIPadding")
                pad.PaddingLeft = UDim.new(0, 14)
                pad.Parent = textBtn
            end
        end)
        
        local function toggle()
            collapsed = not collapsed
            arrow.Text = collapsed and "▶" or "▼"
            for _, comp in ipairs(components) do
                if comp and comp.Frame then
                    comp.Frame.Visible = not collapsed
                end
            end
        end
        
        btnApi.Callback = toggle
        
        pcall(function()
            local textBtn = btnApi.Frame:FindFirstChildOfClass("TextButton")
            if textBtn then
                textBtn.MouseButton1Click:Connect(toggle)
            end
        end)
        
        -- Start collapsed
        for _, comp in ipairs(components) do
            if comp and comp.Frame then
                comp.Frame.Visible = false
            end
        end
        
        return btnApi
    end

    -- ══ FISHING TAB ═══════════════════════════════════════════════════════
    -- toggleShopGUI is now defined at the top file level for global access

    local autoFishingComponents = {}
    createCollapsible(FishTab, "Auto Fishing Settings", autoFishingComponents)

    local autoCastToggle = FishTab:Toggle({
        Title    = "Auto Cast",
        Flag     = "FAM_AutoCast",
        Default  = false,
        Compact  = true,
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
    autoCastToggle.Frame.Visible = false
    table.insert(autoFishingComponents, autoCastToggle)

    local instantBiteToggle = FishTab:Toggle({
        Title    = "Instant Bite",
        Flag     = "FAM_InstantBite",
        Default  = false,
        Compact  = true,
        Tooltip  = "Force fish to bite instantly after cast",
        Callback = function(v)
            FAM.InstantBite = v
            N("Instant Bite", v and "Enabled" or "Disabled")
        end
    })
    instantBiteToggle.Frame.Visible = false
    table.insert(autoFishingComponents, instantBiteToggle)

    local blatantModeToggle = FishTab:Toggle({
        Title    = "Blatant Mode",
        Flag     = "FAM_BlatantMode",
        Default  = false,
        Compact  = true,
        Tooltip  = "⚠️ WARNING: Bypasses wait timers for ultra-fast catching. High Ban Risk!",
        Callback = function(v)
            FAM.BlatantMode = v
            N("Blatant Mode", v and "Enabled (High Risk)" or "Disabled")
        end
    })
    blatantModeToggle.Frame.Visible = false
    table.insert(autoFishingComponents, blatantModeToggle)

    local autoReelToggle = FishTab:Toggle({
        Title    = "Auto Reel",
        Flag     = "FAM_AutoReel",
        Default  = false,
        Compact  = true,
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
    autoReelToggle.Frame.Visible = false
    table.insert(autoFishingComponents, autoReelToggle)

    local afkModeToggle = FishTab:Toggle({
        Title    = "In-Game AFK Mode",
        Flag     = "FAM_AfkMode",
        Default  = false,
        Compact  = true,
        Tooltip  = "Toggles the game's built-in AFK fishing mode",
        Callback = function(v)
            FAM.AfkMode = v
            setAfkMode(v)
            N("AFK Fishing", v and "Enabled" or "Disabled")
        end
    })
    afkModeToggle.Frame.Visible = false
    table.insert(autoFishingComponents, afkModeToggle)

    local hideCatchToggle = FishTab:Toggle({
        Title    = "Hide Catch GUI",
        Flag     = "FAM_HideCatchUI",
        Default  = false,
        Compact  = true,
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
    hideCatchToggle.Frame.Visible = false
    table.insert(autoFishingComponents, hideCatchToggle)

    local antiAfkToggle = FishTab:Toggle({
        Title    = "Anti-AFK (Reconnect / Anti-Idle)",
        Flag     = "FAM_AntiAFK",
        Default  = false,
        Compact  = true,
        Tooltip  = "Prevents idling disconnect and automatically reconnects if kicked",
        Callback = function(v)
            FAM.AntiAFK = v
            if v then
                startAntiAFK()
            else
                stopAntiAFK()
            end
            N("Anti-AFK", v and "Enabled" or "Disabled")
        end
    })
    antiAfkToggle.Frame.Visible = false
    table.insert(autoFishingComponents, antiAfkToggle)

    local ecoComponents = {}
    createCollapsible(FishTab, "Economy & Collection", ecoComponents)

    local autoSellToggle = FishTab:Toggle({
        Title    = "Auto Sell Fish",
        Flag     = "FAM_AutoSell",
        Default  = false,
        Compact  = true,
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
    autoSellToggle.Frame.Visible = false
    table.insert(ecoComponents, autoSellToggle)

    local sellLimitSlider = FishTab:Slider({
        Title    = "Inventory Limit to Sell",
        Flag     = "FAM_SellLimit",
        Value    = { Min = 1, Max = 1000, Default = 15 },
        Step     = 1,
        Compact  = true,
        Tooltip  = "Number of fish in inventory before teleporting to sell",
        Callback = function(v)
            FAM.SellLimit = v
        end
    })
    sellLimitSlider.Frame.Visible = false
    table.insert(ecoComponents, sellLimitSlider)

    local sellAllBtn = FishTab:Button({
        Title    = "Sell All Fish Now",
        Style    = "Primary",
        Compact  = true,
        Callback = function()
            task.spawn(function()
                local hrp = getHRP()
                if not hrp then return end
                
                local originalCFrame = hrp.CFrame
                local fishermanShop = workspace:FindFirstChild("GameSystemObject")
                    and workspace.GameSystemObject:FindFirstChild("FishermanShop")
                
                if fishermanShop and fishermanShop:IsA("BasePart") then
                    hrp.CFrame = fishermanShop.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.4)
                end
                
                pcall(function()
                    if services.FishermanShopService then
                        services.FishermanShopService:SellAllFish()
                    end
                end)
                task.wait(0.4)
                
                if hrp and hrp.Parent then
                    hrp.CFrame = originalCFrame
                end
                N("Manual Sell", "All fish sold successfully")
            end)
        end
    })
    sellAllBtn.Frame.Visible = false
    table.insert(ecoComponents, sellAllBtn)

    local openEquipShopToggle = FishTab:Toggle({
        Title    = "Open Equipment Shop",
        Flag     = "FAM_OpenEquipmentShop",
        Default  = false,
        Compact  = true,
        Tooltip  = "Opens the rod & floater shop GUI from anywhere",
        Callback = function(v)
            toggleShopGUI("EquipmentShopGUI", v)
            N("Equipment Shop", v and "Opened" or "Closed")
        end
    })
    openEquipShopToggle.Frame.Visible = false
    table.insert(ecoComponents, openEquipShopToggle)

    local openPetShopToggle = FishTab:Toggle({
        Title    = "Open Pet Gacha",
        Flag     = "FAM_OpenPetShop",
        Default  = false,
        Compact  = true,
        Tooltip  = "Opens the pet egg hatching shop GUI from anywhere",
        Callback = function(v)
            toggleShopGUI("PetGachaGui", v)
            N("Pet Gacha", v and "Opened" or "Closed")
        end
    })
    openPetShopToggle.Frame.Visible = false
    table.insert(ecoComponents, openPetShopToggle)

    local openPotionShopToggle = FishTab:Toggle({
        Title    = "Open Potion Shop",
        Flag     = "FAM_OpenPotionShop",
        Default  = false,
        Compact  = true,
        Tooltip  = "Opens the general tool/potion shop GUI from anywhere",
        Callback = function(v)
            toggleShopGUI("Shop", v)
            N("Potion Shop", v and "Opened" or "Closed")
        end
    })
    openPotionShopToggle.Frame.Visible = false
    table.insert(ecoComponents, openPotionShopToggle)

    local autoCollectToggle = FishTab:Toggle({
        Title    = "Auto Collect Chests",
        Flag     = "FAM_AutoCollect",
        Default  = false,
        Compact  = true,
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
    autoCollectToggle.Frame.Visible = false
    table.insert(ecoComponents, autoCollectToggle)

    local autoQuestToggle = FishTab:Toggle({
        Title    = "Auto Claim Quests",
        Flag     = "FAM_AutoQuest",
        Default  = false,
        Compact  = true,
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
    autoQuestToggle.Frame.Visible = false
    table.insert(ecoComponents, autoQuestToggle)

    -- ══ ESP TAB ═══════════════════════════════════════════════════════════
    local espComponents = {}
    createCollapsible(ESPTab, "Entity ESP", espComponents)

    local fishEspToggle = ESPTab:Toggle({
        Title    = "Fish ESP",
        Flag     = "FAM_FishESP",
        Default  = false,
        Compact  = true,
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
    fishEspToggle.Frame.Visible = false
    table.insert(espComponents, fishEspToggle)

    local monsterEspToggle = ESPTab:Toggle({
        Title    = "Monster ESP",
        Flag     = "FAM_MonsterESP",
        Default  = false,
        Compact  = true,
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
    monsterEspToggle.Frame.Visible = false
    table.insert(espComponents, monsterEspToggle)

    local chestEspToggle = ESPTab:Toggle({
        Title    = "Chest ESP",
        Flag     = "FAM_TreasureESP",
        Default  = false,
        Compact  = true,
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
    chestEspToggle.Frame.Visible = false
    table.insert(espComponents, chestEspToggle)

    -- ══ TRAVEL TAB ═══════════════════════════════════════════════════════
    local travelComponents = {}
    createCollapsible(TravelTab, "Island & Shop Teleports", travelComponents)

    local selectIslandDrop = TravelTab:Dropdown({
        Title    = "Select Island",
        Flag     = "FAM_SelectedIsland",
        Default  = islandNames[1] or "Starter Island",
        Values   = islandNames,
        Compact  = true,
        Callback = function(v)
            FAM.SelectedIsland = v
        end
    })
    selectIslandDrop.Frame.Visible = false
    table.insert(travelComponents, selectIslandDrop)

    local teleportBtn = TravelTab:Button({
        Title    = "Teleport to Destination",
        Compact  = true,
        Callback = function()
            if FAM.SelectedIsland and FAM.SelectedIsland ~= "" then
                teleportToIsland(FAM.SelectedIsland)
                N("Travel", "Teleporting to " .. FAM.SelectedIsland)
            else
                N("Travel", "Select destination first!")
            end
        end
    })
    teleportBtn.Frame.Visible = false
    table.insert(travelComponents, teleportBtn)

    local teleportNpcBtn = TravelTab:Button({
        Title    = "Teleport to Spawn NPC (Innkeeper)",
        Compact  = true,
        Tooltip  = "Teleports you directly next to the Innkeeper/Beach Keeper on the selected island to set your spawn point",
        Callback = function()
            if FAM.SelectedIsland and FAM.SelectedIsland ~= "" then
                task.spawn(function()
                    N("Travel", "Teleporting to " .. FAM.SelectedIsland .. "...")
                    teleportToIsland(FAM.SelectedIsland)
                    task.wait(1.5) -- Wait for island and NPCs to stream in / load
                    local ok = teleportToInnkeeper(FAM.SelectedIsland)
                    if ok then
                        N("Travel", "Teleported to Innkeeper NPC!")
                    else
                        -- Try fallback one more time
                        task.wait(1.0)
                        ok = teleportToInnkeeper(FAM.SelectedIsland)
                        if ok then
                            N("Travel", "Teleported to Innkeeper NPC!")
                        else
                            N("Travel", "Innkeeper NPC not found on this island!")
                        end
                    end
                end)
            else
                N("Travel", "Select destination first!")
            end
        end
    })
    teleportNpcBtn.Frame.Visible = false
    table.insert(travelComponents, teleportNpcBtn)

    local saveSelectedSpawnBtn = TravelTab:Button({
        Title    = "Save Spawn on Selected Island",
        Compact  = true,
        Tooltip  = "Automatically set your spawn location to the selected island",
        Callback = function()
            if FAM.SelectedIsland and FAM.SelectedIsland ~= "" then
                setSavePoint(FAM.SelectedIsland)
                N("Spawn Location", "Set spawn to: " .. FAM.SelectedIsland)
            else
                N("Spawn Location", "Select island first!")
            end
        end
    })
    saveSelectedSpawnBtn.Frame.Visible = false
    table.insert(travelComponents, saveSelectedSpawnBtn)

    local saveCurrentSpawnBtn = TravelTab:Button({
        Title    = "Save Spawn on Current Island",
        Compact  = true,
        Tooltip  = "Automatically detects your current island and sets it as spawn location",
        Callback = function()
            local cur = getCurrentIsland()
            if cur then
                setSavePoint(cur)
                N("Spawn Location", "Set spawn to: " .. cur)
            else
                N("Spawn Location", "Could not detect current island!")
            end
        end
    })
    saveCurrentSpawnBtn.Frame.Visible = false
    table.insert(travelComponents, saveCurrentSpawnBtn)

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

    -- ══ PLAYER TAB ════════════════════════════════════════════════════════
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "👤" })

    PlayerTab:Section({ Title = "Flight & Noclip" })
    
    local flyToggle
    local flySpeedSlider
    local flyKeybind
    local flyKey = Enum.KeyCode.F

    flyToggle = PlayerTab:Toggle({
        Title    = "Fly",
        Flag     = "FAM_Fly",
        Default  = false,
        Compact  = true,
        Tooltip  = "Allows you to fly around the map",
        Callback = function(v)
            if Fly then
                if v then Fly:Enable() else Fly:Disable() end
                N("Fly", v and "Enabled" or "Disabled")
            else
                N("Error", "Fly module not loaded")
            end
        end
    })

    flySpeedSlider = PlayerTab:Slider({
        Title    = "Fly Speed",
        Flag     = "FAM_FlySpeed",
        Value    = { Min = 10, Max = 300, Default = 60 },
        Compact  = true,
        Tooltip  = "Adjust flight speed",
        Callback = function(v)
            if Fly and v >= 10 then
                Fly:SetSpeed(v)
            end
        end
    })

    flyKeybind = PlayerTab:Keybind({
        Title    = "Fly Keybind",
        Flag     = "FAM_FlyKey",
        Default  = "F",
        Tooltip  = "Press key to toggle flight",
        Callback = function(k)
            flyKey = Enum.KeyCode[k] or Enum.KeyCode.F
            N("Fly Keybind", "Set to " .. k)
        end
    })

    local noclipToggle
    local noclipKeybind
    local noclipKey = Enum.KeyCode.V

    noclipToggle = PlayerTab:Toggle({
        Title    = "Noclip",
        Flag     = "FAM_Noclip",
        Default  = false,
        Compact  = true,
        Tooltip  = "Walk through walls/objects",
        Callback = function(v)
            if Noclip then
                if v then Noclip:Enable() else Noclip:Disable() end
                N("Noclip", v and "Enabled" or "Disabled")
            else
                N("Error", "Noclip module not loaded")
            end
        end
    })

    noclipKeybind = PlayerTab:Keybind({
        Title    = "Noclip Keybind",
        Flag     = "FAM_NoclipKey",
        Default  = "V",
        Tooltip  = "Press key to toggle noclip",
        Callback = function(k)
            noclipKey = Enum.KeyCode[k] or Enum.KeyCode.V
            N("Noclip Keybind", "Set to " .. k)
        end
    })

    PlayerTab:Section({ Title = "Speed Hack" })

    local speedToggle
    local walkSpeedSlider
    local jumpPowerSlider

    speedToggle = PlayerTab:Toggle({
        Title    = "Speed Hack",
        Flag     = "FAM_SpeedHack",
        Default  = false,
        Compact  = true,
        Tooltip  = "Enable custom Walk Speed and Jump Power",
        Callback = function(v)
            if Speed then
                if v then
                    local ws = (walkSpeedSlider and walkSpeedSlider.Value) or 16
                    local jp = (jumpPowerSlider and jumpPowerSlider.Value) or 50
                    Speed:SetWalkSpeed(ws)
                    Speed:SetJumpPower(jp)
                    Speed:Enable()
                else
                    Speed:Disable()
                end
                N("Speed Hack", v and "Enabled" or "Disabled")
            else
                N("Error", "Speed module not loaded")
            end
        end
    })

    walkSpeedSlider = PlayerTab:Slider({
        Title    = "Walk Speed",
        Flag     = "FAM_WalkSpeed",
        Value    = { Min = 16, Max = 250, Default = 16 },
        Compact  = true,
        Tooltip  = "Adjust walking speed",
        Callback = function(v)
            if Speed then
                Speed:SetWalkSpeed(v)
            end
        end
    })

    jumpPowerSlider = PlayerTab:Slider({
        Title    = "Jump Power",
        Flag     = "FAM_JumpPower",
        Value    = { Min = 50, Max = 250, Default = 50 },
        Compact  = true,
        Tooltip  = "Adjust jump power",
        Callback = function(v)
            if Speed then
                Speed:SetJumpPower(v)
            end
        end
    })

    PlayerTab:Section({ Title = "Other Exploit" })

    local infJumpToggle = PlayerTab:Toggle({
        Title    = "Infinite Jump",
        Flag     = "FAM_InfiniteJump",
        Default  = false,
        Compact  = true,
        Tooltip  = "Allows you to jump infinitely in the air",
        Callback = function(v)
            if InfiniteJump then
                if v then InfiniteJump:Enable() else InfiniteJump:Disable() end
                N("Infinite Jump", v and "Enabled" or "Disabled")
            else
                N("Error", "Infinite Jump module not loaded")
            end
        end
    })

    local perfStatsToggle = PlayerTab:Toggle({
        Title    = "Performance HUD",
        Flag     = "FAM_PerfHUD",
        Default  = false,
        Compact  = true,
        Tooltip  = "Show real-time performance statistics overlay",
        Callback = function(v)
            if PerfStats then
                if v then PerfStats:Enable() else PerfStats:Disable() end
                N("Performance HUD", v and "Enabled" or "Disabled")
            else
                N("Error", "Performance HUD module not loaded")
            end
        end
    })

    UIS.InputBegan:Connect(function(i, gp)
        if gp or not FAM.Enabled then return end
        if i.KeyCode == flyKey then
            if flyToggle then
                flyToggle:Set(not flyToggle.Value)
            end
        elseif i.KeyCode == noclipKey then
            if noclipToggle then
                noclipToggle:Set(not noclipToggle.Value)
            end
        end
    end)

    if ConfigMgr then
        ConfigMgr:Register("FAM_Fly", flyToggle)
        ConfigMgr:Register("FAM_FlySpeed", flySpeedSlider)
        ConfigMgr:Register("FAM_FlyKey", flyKeybind)
        ConfigMgr:Register("FAM_Noclip", noclipToggle)
        ConfigMgr:Register("FAM_NoclipKey", noclipKeybind)
        ConfigMgr:Register("FAM_SpeedHack", speedToggle)
        ConfigMgr:Register("FAM_WalkSpeed", walkSpeedSlider)
        ConfigMgr:Register("FAM_JumpPower", jumpPowerSlider)
        ConfigMgr:Register("FAM_InfiniteJump", infJumpToggle)
        ConfigMgr:Register("FAM_PerfHUD", perfStatsToggle)
    end


    -- ══ MISC TAB ══════════════════════════════════════════════════════════
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "⚙️" })

    MiscTab:Section({ Title = "Visual Tweaks" })

    local clearFogToggle = MiscTab:Toggle({
        Title    = "Clear Fog",
        Flag     = "FAM_ClearFog",
        Default  = false,
        Compact  = true,
        Tooltip  = "Removes atmospheric fog and sky haze",
        Callback = function(v)
            if RemoveFog then
                if v then RemoveFog:Enable() else RemoveFog:Disable() end
                N("Clear Fog", v and "Enabled" or "Disabled")
            else
                N("Error", "RemoveFog module not loaded")
            end
        end
    })

    local autoBrightToggle = MiscTab:Toggle({
        Title    = "Auto Bright",
        Flag     = "FAM_AutoBright",
        Default  = false,
        Compact  = true,
        Tooltip  = "Maximizes in-game lighting brightness (FullBright)",
        Callback = function(v)
            if FullBright then
                if v then FullBright:Enable() else FullBright:Disable() end
                N("Auto Bright", v and "Enabled" or "Disabled")
            else
                N("Error", "FullBright module not loaded")
            end
        end
    })

    if ConfigMgr then
        ConfigMgr:Register("FAM_ClearFog", clearFogToggle)
        ConfigMgr:Register("FAM_AutoBright", autoBrightToggle)
    end

    MiscTab:Section({ Title = "Server Actions" })

    MiscTab:Button({
        Title    = "Rejoin Server",
        Style    = "Primary",
        Compact  = true,
        Callback = function()
            if Rejoin then
                N("Rejoin", "Rejoining map...")
                task.wait(0.5)
                Rejoin:Execute()
            else
                N("Error", "Rejoin module not loaded")
            end
        end
    })

    MiscTab:Button({
        Title    = "Server Hop",
        Style    = "Primary",
        Compact  = true,
        Callback = function()
            if ServerHop then
                N("Server Hop", "Finding new server...")
                task.wait(0.5)
                ServerHop:Execute()
            else
                N("Error", "Server Hop module not loaded")
            end
        end
    })

    SettingsTab:Section({ Title = "About" })
    SettingsTab:Paragraph({
        Title   = "Leon X - Fish And Monsters",
        Content = "v1.1 - by leonx24\n\nFully automated Knit features wired directly from the client."
    })
end

return FAM
