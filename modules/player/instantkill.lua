local Module = {}
Module.Name = "InstantKill"
Module.Enabled = false
Module.Target = nil -- Target NPC name
Module.Mode = "All" -- "All" or "Specific"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local conn = nil

-- Function to check if a model is an NPC (not a player character)
local function isNPC(model)
    if not model or not model:IsA("Model") then return false end

    -- Check if it has a Humanoid
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    -- Check if it's NOT a player character
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character == model then
            return false
        end
    end

    return true
end

-- Function to kill an NPC
local function killNPC(npc)
    pcall(function()
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid.Health = 0
        end
    end)
end

-- Function to find and kill NPCs
local function processNPCs()
    pcall(function()
        if not Module.Enabled then return end

        local workspace = game:GetService("Workspace")

        for _, descendant in pairs(workspace:GetDescendants()) do
            if Module.Enabled and isNPC(descendant) then
                -- Mode: All - kill all NPCs
                if Module.Mode == "All" then
                    killNPC(descendant)
                -- Mode: Specific - kill only NPCs with matching name
                elseif Module.Mode == "Specific" and Module.Target then
                    if descendant.Name:lower():find(Module.Target:lower()) then
                        killNPC(descendant)
                    end
                end
            end
        end
    end)
end

function Module:Enable()
    if self.Enabled then return end
    self.Enabled = true

    pcall(function()
        -- Initial kill pass
        processNPCs()

        -- Continuous monitoring for respawning NPCs
        conn = RunService.Heartbeat:Connect(function()
            processNPCs()
        end)
    end)
end

function Module:Disable()
    self.Enabled = false

    if conn then
        conn:Disconnect()
        conn = nil
    end
end

function Module:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

function Module:SetMode(mode)
    self.Mode = mode
end

function Module:SetTarget(targetName)
    self.Target = targetName
end

return Module
