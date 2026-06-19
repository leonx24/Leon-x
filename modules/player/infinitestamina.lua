-- Leon X | InfiniteStamina (Enhanced v2)
-- Prevents stamina/sprint energy drain by continuously refilling
-- Scans ALL possible locations: Humanoid attributes, character values,
-- Player attributes, PlayerGui, PlayerScripts, leaderstats

local InfiniteStamina = {}
InfiniteStamina.Name    = "InfiniteStamina"
InfiniteStamina.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local heartConn = nil
local charConn  = nil
local scanConn  = nil

-- Common stamina-related keywords to match against
local STAMINA_KEYWORDS = {
    "stamina", "energy", "sprint", "endurance", "stam", "energi",
    "fatigue", "exhaust", "breath", "oxygen", "oxy", "dash",
    "run", "jog", "tire",
}

-- Check if a name matches stamina patterns
local function isStaminaName(name)
    local lower = name:lower()
    for _, keyword in ipairs(STAMINA_KEYWORDS) do
        if lower:find(keyword) then
            return true
        end
    end
    return false
end

-- Get max value from sibling or parent
local function findMaxValue(obj)
    local parent = obj.Parent
    if not parent then return 100 end

    -- Check for MaxXxx or xxxMax siblings
    local maxNames = {
        "Max" .. obj.Name, obj.Name .. "Max",
        "Max", "Maximum", "MaxValue",
    }
    for _, mn in ipairs(maxNames) do
        local maxObj = parent:FindFirstChild(mn)
        if maxObj and (maxObj:IsA("NumberValue") or maxObj:IsA("IntValue")) then
            return math.max(maxObj.Value, 1)
        end
    end
    return 100
end

-- Refill stamina in ALL possible locations
local function refill(char)
    if not char then return end

    -- 1. Humanoid attributes (iterate ALL, not just known names)
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                local attrs = hum:GetAttributes()
                if attrs then
                    for attrName, val in pairs(attrs) do
                        if type(val) == "number" and isStaminaName(attrName) then
                            local maxVal = 100
                            -- Try to find max attribute
                            local maxAttr = hum:GetAttribute("Max" .. attrName)
                                or hum:GetAttribute(attrName .. "Max")
                            if type(maxAttr) == "number" and maxAttr > 0 then
                                maxVal = maxAttr
                            end
                            if val < maxVal then
                                hum:SetAttribute(attrName, maxVal)
                            end
                        end
                    end
                end
            end)
            -- Also try common explicit names
            for _, attr in ipairs({
                "Stamina", "Energy", "Sprint", "SprintStamina",
                "StaminaValue", "EnergyValue", "Endurance",
                "stamina", "energy", "sprint", "sprintStamina",
                "MaxStamina", "CurrentStamina", "PlayerStamina",
                "SprintEnergy", "RunEnergy", "StaminaBar",
                "DashEnergy", "DashStamina", "BreathStamina",
            }) do
                pcall(function()
                    local val = hum:GetAttribute(attr)
                    if type(val) == "number" then
                        local maxVal = hum:GetAttribute("Max" .. attr)
                            or hum:GetAttribute(attr .. "Max")
                            or 100
                        if type(maxVal) ~= "number" then maxVal = 100 end
                        hum:SetAttribute(attr, math.max(val, maxVal))
                    end
                end)
            end
        end
    end)

    -- 2. Scan ALL descendants of character for NumberValue/IntValue
    pcall(function()
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                if isStaminaName(obj.Name) then
                    pcall(function()
                        local maxVal = findMaxValue(obj)
                        if obj.Value < maxVal then
                            obj.Value = maxVal
                        end
                    end)
                end
            end
        end
    end)

    -- 3. Player-level attributes (iterate ALL)
    pcall(function()
        local attrs = lp:GetAttributes()
        if attrs then
            for attrName, val in pairs(attrs) do
                if type(val) == "number" and isStaminaName(attrName) then
                    local maxVal = lp:GetAttribute("Max" .. attrName)
                        or lp:GetAttribute(attrName .. "Max")
                        or 100
                    if type(maxVal) ~= "number" then maxVal = 100 end
                    if val < maxVal then
                        lp:SetAttribute(attrName, maxVal)
                    end
                end
            end
        end
    end)

    -- 4. Scan PlayerGui for stamina-related values
    pcall(function()
        local pg = lp:FindFirstChild("PlayerGui")
        if pg then
            for _, obj in ipairs(pg:GetDescendants()) do
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    if isStaminaName(obj.Name) then
                        pcall(function()
                            local maxVal = findMaxValue(obj)
                            if obj.Value < maxVal then
                                obj.Value = maxVal
                            end
                        end)
                    end
                end
            end
        end
    end)

    -- 5. Scan leaderstats and other player stats
    pcall(function()
        local leaderstats = lp:FindFirstChild("leaderstats")
        if leaderstats then
            for _, obj in ipairs(leaderstats:GetDescendants()) do
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    if isStaminaName(obj.Name) then
                        pcall(function()
                            local maxVal = findMaxValue(obj)
                            if obj.Value < maxVal then
                                obj.Value = maxVal
                            end
                        end)
                    end
                end
            end
        end
    end)

    -- 6. Scan PlayerScripts for stamina values (some games store here)
    pcall(function()
        local ps = lp:FindFirstChild("PlayerScripts")
        if ps then
            for _, obj in ipairs(ps:GetDescendants()) do
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    if isStaminaName(obj.Name) then
                        pcall(function()
                            local maxVal = findMaxValue(obj)
                            if obj.Value < maxVal then
                                obj.Value = maxVal
                            end
                        end)
                    end
                end
            end
        end
    end)

    -- 7. Scan ReplicatedStorage for player-specific stamina modules
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        if rs then
            -- Look for player-named folders that might contain stamina
            local playerFolder = rs:FindFirstChild(lp.Name) or rs:FindFirstChild(tostring(lp.UserId))
            if playerFolder then
                for _, obj in ipairs(playerFolder:GetDescendants()) do
                    if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                        if isStaminaName(obj.Name) then
                            pcall(function()
                                local maxVal = findMaxValue(obj)
                                if obj.Value < maxVal then
                                    obj.Value = maxVal
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
end

-- Initial deep scan: find ALL stamina-like values once and cache them
local cachedStaminaPaths = {}

local function deepScan()
    cachedStaminaPaths = {}
    local function scanContainer(container, path)
        pcall(function()
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                    if isStaminaName(obj.Name) then
                        cachedStaminaPaths[#cachedStaminaPaths + 1] = obj
                    end
                end
            end
        end)
    end
    if lp.Character then scanContainer(lp.Character, "char") end
    scanContainer(lp, "player")
    pcall(function()
        local pg = lp:FindFirstChild("PlayerGui")
        if pg then scanContainer(pg, "pg") end
    end)
    pcall(function()
        local ps = lp:FindFirstChild("PlayerScripts")
        if ps then scanContainer(ps, "ps") end
    end)
    print("[Leon X] InfiniteStamina: Deep scan found " .. #cachedStaminaPaths .. " stamina-like values")
end

function InfiniteStamina:Enable()
    if self.Enabled then return end
    self.Enabled = true

    -- Do initial deep scan
    deepScan()

    charConn = lp.CharacterAdded:Connect(function()
        task.wait(1)
        deepScan()
    end)

    if heartConn then heartConn:Disconnect(); heartConn = nil end
    heartConn = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        -- Refill cached paths first (fast)
        for _, obj in ipairs(cachedStaminaPaths) do
            pcall(function()
                if obj and obj.Parent then
                    local maxVal = findMaxValue(obj)
                    if obj.Value < maxVal then
                        obj.Value = maxVal
                    end
                end
            end)
        end
        -- Also do full refill (catches new values)
        refill(lp.Character)
    end)

    -- Periodic deep scan (every 5s) to catch dynamically created values
    if scanConn then scanConn:Disconnect(); scanConn = nil end
    scanConn = RunService.Heartbeat:Connect(function()
        -- Use a simple timer
    end)
    task.spawn(function()
        while self.Enabled do
            task.wait(5)
            if self.Enabled then
                deepScan()
            end
        end
    end)

    print("[Leon X] InfiniteStamina: Enhanced v2 mode enabled")
end

function InfiniteStamina:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    if heartConn then heartConn:Disconnect(); heartConn = nil end
    if charConn  then charConn:Disconnect();  charConn  = nil end
    if scanConn  then scanConn:Disconnect();  scanConn  = nil end
    cachedStaminaPaths = {}
end

function InfiniteStamina:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return InfiniteStamina
