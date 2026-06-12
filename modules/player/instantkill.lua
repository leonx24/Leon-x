local Module = {}
Module.Name = "InstantKill"
Module.Enabled = false
Module.Target = nil -- Target NPC name
Module.Mode = "All" -- "All" or "Specific"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local conn = nil
local processedNPCs = {} -- Track NPCs we've already killed
local lastScan = 0

-- Function to check if a model is an NPC (not a player character)
local function isNPC(model)
    if not model or not model:IsA("Model") then return false end

    -- Check if it has a Humanoid
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    -- Must have health > 0 to be killable
    if humanoid.Health <= 0 then return false end

    -- Check if it's NOT a player character
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character == model then
            return false
        end
    end

    return true
end

-- Multiple kill methods for better compatibility
local function killNPC(npc)
    local success = false

    pcall(function()
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        -- Method 1: Direct health manipulation
        humanoid.Health = 0
        success = true

        -- Method 2: BreakJoints (backup)
        if humanoid.Health > 0 then
            pcall(function()
                npc:BreakJoints()
                success = true
            end)
        end

        -- Method 3: Destroy head (aggressive backup)
        if humanoid.Health > 0 then
            pcall(function()
                local head = npc:FindFirstChild("Head")
                if head then
                    head:Destroy()
                    success = true
                end
            end)
        end

        -- Method 4: MaxHealth manipulation then kill
        if humanoid.Health > 0 then
            pcall(function()
                humanoid.MaxHealth = 0
                humanoid.Health = 0
                success = true
            end)
        end

        -- Method 5: Remove humanoid entirely (nuclear option)
        if humanoid.Health > 0 then
            pcall(function()
                humanoid:Destroy()
                success = true
            end)
        end
    end)

    return success
end

-- Function to find and kill NPCs
local function processNPCs()
    pcall(function()
        if not Module.Enabled then return end

        -- Throttle scanning to reduce lag
        if tick() - lastScan < 0.1 then return end
        lastScan = tick()

        local workspace = game:GetService("Workspace")

        -- Scan workspace for NPCs
        for _, descendant in pairs(workspace:GetDescendants()) do
            if not Module.Enabled then break end

            if descendant:IsA("Model") and isNPC(descendant) then
                local npcID = tostring(descendant:GetDebugId())

                -- Skip if already processed recently
                if processedNPCs[npcID] and tick() - processedNPCs[npcID] < 2 then
                    continue
                end

                -- Mode: All - kill all NPCs
                if Module.Mode == "All" then
                    if killNPC(descendant) then
                        processedNPCs[npcID] = tick()
                    end
                -- Mode: Specific - kill only NPCs with matching name
                elseif Module.Mode == "Specific" and Module.Target and Module.Target ~= "" then
                    if descendant.Name:lower():find(Module.Target:lower()) then
                        if killNPC(descendant) then
                            processedNPCs[npcID] = tick()
                        end
                    end
                end
            end
        end

        -- Clean up old entries from processedNPCs table
        for id, time in pairs(processedNPCs) do
            if tick() - time > 5 then
                processedNPCs[id] = nil
            end
        end
    end)
end

function Module:Enable()
    if self.Enabled then return end
    self.Enabled = true
    processedNPCs = {}
    lastScan = 0

    pcall(function()
        -- Initial aggressive kill pass
        task.spawn(function()
            for i = 1, 3 do
                processNPCs()
                task.wait(0.2)
            end
        end)

        -- Continuous monitoring with Heartbeat for maximum responsiveness
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

    processedNPCs = {}
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
    if self.Enabled then
        -- Restart to apply new mode
        self:Disable()
        task.wait(0.1)
        self:Enable()
    end
end

function Module:SetTarget(targetName)
    self.Target = targetName
end

return Module
