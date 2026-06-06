-- Leon X | InfiniteStamina
-- Prevents stamina/sprint energy drain by continuously refilling
-- any common stamina-like values on the Humanoid and character

local InfiniteStamina = {}
InfiniteStamina.Name    = "InfiniteStamina"
InfiniteStamina.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local heartConn = nil
local charConn  = nil

-- Common attribute/value names used by Roblox games for stamina
local STAMINA_ATTRS = {
    "Stamina", "Energy", "Sprint", "SprintStamina",
    "StaminaValue", "EnergyValue", "Endurance",
    "stamina", "energy", "sprint", "sprintStamina",
}

local STAMINA_VALUES = {
    "Stamina", "Energy", "Sprint", "SprintEnergy",
    "StaminaValue", "EnergyValue", "SprintStamina",
    "stamina", "energy", "sprint",
}

local function refill(char)
    if not char then return end

    -- 1. Humanoid attributes
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, attr in ipairs(STAMINA_ATTRS) do
            pcall(function()
                local val = hum:GetAttribute(attr)
                if type(val) == "number" and val < 99 then
                    hum:SetAttribute(attr, 100)
                end
            end)
        end
        -- Some games use Humanoid.Health-like custom props
        -- Also keep WalkSpeed from being zeroed by sprint drain
    end

    -- 2. NumberValue / IntValue children of character or HRP
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            for _, name in ipairs(STAMINA_VALUES) do
                if obj.Name == name then
                    pcall(function()
                        if obj.Value < obj.Value + 1 then   -- has a range
                            obj.Value = 100
                        end
                    end)
                end
            end
        end
    end
end

function InfiniteStamina:Enable()
    if self.Enabled then return end
    self.Enabled = true

    charConn = lp.CharacterAdded:Connect(function() end)  -- refresh on respawn

    if heartConn then heartConn:Disconnect(); heartConn = nil end
    heartConn = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        refill(lp.Character)
    end)
end

function InfiniteStamina:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    if heartConn then heartConn:Disconnect(); heartConn = nil end
    if charConn  then charConn:Disconnect();  charConn  = nil end
end

function InfiniteStamina:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return InfiniteStamina
