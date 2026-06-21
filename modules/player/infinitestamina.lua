-- Leon X | InfiniteStamina (v3 — FPS-optimized)
-- Refills stamina from cached reference every frame (fast, no scanning)
-- Full deep scan only every 10 seconds to catch new values

local InfiniteStamina = {}
InfiniteStamina.Name    = "InfiniteStamina"
InfiniteStamina.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local mainConn = nil
local charConn = nil

-- Stamina-related keywords
local STAMINA_KEYWORDS = {
    "stamina", "energy", "sprint", "endurance", "stam", "energi",
    "fatigue", "exhaust", "breath", "oxygen", "oxy", "dash",
    "run", "jog", "tire",
}

-- Common attribute names to check
local COMMON_ATTRS = {
    "Stamina", "Energy", "Sprint", "SprintStamina",
    "StaminaValue", "EnergyValue", "Endurance",
    "stamina", "energy", "sprint", "sprintStamina",
    "MaxStamina", "CurrentStamina", "PlayerStamina",
    "SprintEnergy", "RunEnergy", "StaminaBar",
    "DashEnergy", "DashStamina", "BreathStamina",
}

local function isStaminaName(name)
    local lower = name:lower()
    for _, keyword in ipairs(STAMINA_KEYWORDS) do
        if lower:find(keyword) then return true end
    end
    return false
end

-- Cached stamina ref: { obj=Instance, maxVal=number }
local cachedRefs = {}

-- Get max value from sibling or parent
local function findMaxValue(obj)
    local parent = obj.Parent
    if not parent then return 100 end
    local maxNames = { "Max" .. obj.Name, obj.Name .. "Max", "Max", "Maximum", "MaxValue" }
    for _, mn in ipairs(maxNames) do
        local maxObj = parent:FindFirstChild(mn)
        if maxObj and (maxObj:IsA("NumberValue") or maxObj:IsA("IntValue")) then
            return math.max(maxObj.Value, 1)
        end
    end
    return 100
end

-- Deep scan: find ALL stamina values and cache them (runs every 10s, not every frame)
local function deepScan()
    cachedRefs = {}

    local function cache(obj)
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            if isStaminaName(obj.Name) then
                cachedRefs[#cachedRefs + 1] = {
                    obj = obj,
                    maxVal = findMaxValue(obj),
                }
            end
        end
    end

    -- Character descendants
    pcall(function()
        local char = lp.Character
        if char then
            for _, obj in ipairs(char:GetDescendants()) do cache(obj) end
        end
    end)

    -- Humanoid attributes
    pcall(function()
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local attrs = hum:GetAttributes()
            if attrs then
                for attrName, val in pairs(attrs) do
                    if type(val) == "number" and isStaminaName(attrName) then
                        local maxVal = hum:GetAttribute("Max" .. attrName)
                            or hum:GetAttribute(attrName .. "Max")
                            or 100
                        if type(maxVal) ~= "number" then maxVal = 100 end
                        cachedRefs[#cachedRefs + 1] = { attr = attrName, hum = hum, maxVal = maxVal }
                    end
                end
            end
            -- Common explicit attribute names
            for _, attr in ipairs(COMMON_ATTRS) do
                pcall(function()
                    local val = hum:GetAttribute(attr)
                    if type(val) == "number" then
                        local maxVal = hum:GetAttribute("Max" .. attr)
                            or hum:GetAttribute(attr .. "Max")
                            or 100
                        if type(maxVal) ~= "number" then maxVal = 100 end
                        cachedRefs[#cachedRefs + 1] = { attr = attr, hum = hum, maxVal = maxVal }
                    end
                end)
            end
        end
    end)

    -- Player-level attributes
    pcall(function()
        local attrs = lp:GetAttributes()
        if attrs then
            for attrName, val in pairs(attrs) do
                if type(val) == "number" and isStaminaName(attrName) then
                    local maxVal = lp:GetAttribute("Max" .. attrName)
                        or lp:GetAttribute(attrName .. "Max")
                        or 100
                    if type(maxVal) ~= "number" then maxVal = 100 end
                    cachedRefs[#cachedRefs + 1] = { attr = attrName, player = true, maxVal = maxVal }
                end
            end
        end
    end)

    -- PlayerGui
    pcall(function()
        local pg = lp:FindFirstChild("PlayerGui")
        if pg then
            for _, obj in ipairs(pg:GetDescendants()) do cache(obj) end
        end
    end)

    -- PlayerScripts
    pcall(function()
        local ps = lp:FindFirstChild("PlayerScripts")
        if ps then
            for _, obj in ipairs(ps:GetDescendants()) do cache(obj) end
        end
    end)

    -- leaderstats
    pcall(function()
        local ls = lp:FindFirstChild("leaderstats")
        if ls then
            for _, obj in ipairs(ls:GetDescendants()) do cache(obj) end
        end
    end)

    -- ReplicatedStorage player folder
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local pf = rs and (rs:FindFirstChild(lp.Name) or rs:FindFirstChild(tostring(lp.UserId)))
        if pf then
            for _, obj in ipairs(pf:GetDescendants()) do cache(obj) end
        end
    end)

    print("[InfiniteStamina] Deep scan: " .. #cachedRefs .. " stamina values cached")
end

function InfiniteStamina:Enable()
    if self.Enabled then return end
    self.Enabled = true

    -- Initial deep scan
    deepScan()

    -- Re-scan on character respawn
    charConn = lp.CharacterAdded:Connect(function()
        task.wait(1)
        if self.Enabled then deepScan() end
    end)

    -- SINGLE Heartbeat: refill cached refs every frame (no scanning)
    -- Deep scan every 10 seconds
    if mainConn then mainConn:Disconnect(); mainConn = nil end
    local scanTimer = 0
    local SCAN_INTERVAL = 10

    mainConn = RunService.Heartbeat:Connect(function(dt)
        if not self.Enabled then return end

        -- Fast refill: only touches cached values (zero scanning)
        for _, ref in ipairs(cachedRefs) do
            pcall(function()
                if ref.attr then
                    -- Attribute type
                    local owner = ref.hum or (ref.player and lp)
                    if owner then
                        local val = owner:GetAttribute(ref.attr)
                        if type(val) == "number" and val < ref.maxVal then
                            owner:SetAttribute(ref.attr, ref.maxVal)
                        end
                    end
                elseif ref.obj and ref.obj.Parent then
                    -- Instance type (NumberValue/IntValue)
                    if ref.obj.Value < ref.maxVal then
                        ref.obj.Value = ref.maxVal
                    end
                end
            end)
        end

        -- Periodic deep scan (every 10s) to catch dynamically created values
        scanTimer = scanTimer + dt
        if scanTimer >= SCAN_INTERVAL then
            scanTimer = 0
            deepScan()
        end
    end)

    print("[InfiniteStamina] v3 enabled (cached refill, 10s scan)")
end

function InfiniteStamina:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    if mainConn then mainConn:Disconnect(); mainConn = nil end
    if charConn then charConn:Disconnect(); charConn = nil end
    cachedRefs = {}
end

function InfiniteStamina:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return InfiniteStamina
