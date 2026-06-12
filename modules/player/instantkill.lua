local Module = {}
Module.Name = "InstantKill"
Module.Enabled = false
Module.Target = nil -- Target NPC name
Module.Mode = "All" -- "All" or "Specific"
Module.Debug = false -- Debug mode

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local conn = nil
local childAddedConn = nil
local descendantConn = nil
local killCount = 0

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

    -- Additional checks to confirm it's an NPC
    local hasHead = model:FindFirstChild("Head")
    local hasRootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")

    return hasHead ~= nil or hasRootPart ~= nil
end

-- Multiple kill methods for better compatibility
local function killNPC(npc)
    local success = false
    local humanoid = npc:FindFirstChildOfClass("Humanoid")

    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end

    -- Method 1: Direct health = 0 (most common)
    pcall(function()
        humanoid.Health = 0
        if humanoid.Health <= 0 then
            success = true
            if Module.Debug then
                print("[InstantKill] Killed:", npc.Name, "via Health=0")
            end
        end
    end)

    -- Method 2: TakeDamage (realistic damage)
    if not success then
        pcall(function()
            humanoid:TakeDamage(humanoid.MaxHealth * 999)
            if humanoid.Health <= 0 then
                success = true
                if Module.Debug then
                    print("[InstantKill] Killed:", npc.Name, "via TakeDamage")
                end
            end
        end)
    end

    -- Method 3: BreakJoints
    if not success then
        pcall(function()
            npc:BreakJoints()
            success = true
            if Module.Debug then
                print("[InstantKill] Killed:", npc.Name, "via BreakJoints")
            end
        end)
    end

    -- Method 4: Destroy critical parts
    if not success then
        pcall(function()
            local head = npc:FindFirstChild("Head")
            if head then
                head:Destroy()
                success = true
                if Module.Debug then
                    print("[InstantKill] Killed:", npc.Name, "via Destroy Head")
                end
            end
        end)
    end

    -- Method 5: MaxHealth manipulation
    if not success then
        pcall(function()
            humanoid.MaxHealth = 0
            humanoid.Health = 0
            if humanoid.Health <= 0 then
                success = true
                if Module.Debug then
                    print("[InstantKill] Killed:", npc.Name, "via MaxHealth=0")
                end
            end
        end)
    end

    -- Method 6: Parent manipulation
    if not success then
        pcall(function()
            npc.Parent = nil
            success = true
            if Module.Debug then
                print("[InstantKill] Killed:", npc.Name, "via Parent=nil")
            end
        end)
    end

    -- Method 7: Destroy entire model (nuclear)
    if not success then
        pcall(function()
            npc:Destroy()
            success = true
            if Module.Debug then
                print("[InstantKill] Killed:", npc.Name, "via Destroy Model")
            end
        end)
    end

    if success then
        killCount = killCount + 1
    end

    return success
end

-- Check if NPC matches target criteria
local function shouldKill(npc)
    if Module.Mode == "All" then
        return true
    elseif Module.Mode == "Specific" and Module.Target and Module.Target ~= "" then
        return npc.Name:lower():find(Module.Target:lower())
    end
    return false
end

-- Process a single model
local function processModel(model)
    if not Module.Enabled then return end

    pcall(function()
        if isNPC(model) and shouldKill(model) then
            killNPC(model)
        end
    end)
end

-- Scan workspace for NPCs
local function scanWorkspace()
    pcall(function()
        if not Module.Enabled then return end

        local workspace = game:GetService("Workspace")

        -- Scan immediate children (faster)
        for _, child in pairs(workspace:GetChildren()) do
            if child:IsA("Model") then
                processModel(child)
            end
        end

        -- Scan common NPC folders
        local commonFolders = {
            workspace:FindFirstChild("NPCs"),
            workspace:FindFirstChild("Enemies"),
            workspace:FindFirstChild("Monsters"),
            workspace:FindFirstChild("Mobs"),
            workspace:FindFirstChild("Characters"),
            workspace:FindFirstChild("Bots"),
        }

        for _, folder in pairs(commonFolders) do
            if folder then
                for _, npc in pairs(folder:GetDescendants()) do
                    if npc:IsA("Model") then
                        processModel(npc)
                    end
                end
            end
        end
    end)
end

function Module:Enable()
    if self.Enabled then return end
    self.Enabled = true
    killCount = 0

    if self.Debug then
        print("[InstantKill] Enabled - Mode:", self.Mode, "Target:", self.Target or "All")
    end

    pcall(function()
        -- Initial aggressive scan
        task.spawn(function()
            for i = 1, 5 do
                scanWorkspace()
                task.wait(0.1)
            end
        end)

        -- Heartbeat connection for continuous monitoring
        conn = RunService.Heartbeat:Connect(function()
            scanWorkspace()
        end)

        -- ChildAdded listener for instant detection
        local workspace = game:GetService("Workspace")
        childAddedConn = workspace.ChildAdded:Connect(function(child)
            if not self.Enabled then return end
            task.wait(0.05) -- Small delay for model to fully load
            if child:IsA("Model") then
                processModel(child)
            end
        end)

        -- DescendantAdded for nested spawns
        descendantConn = workspace.DescendantAdded:Connect(function(descendant)
            if not self.Enabled then return end
            if descendant:IsA("Humanoid") then
                task.wait(0.05)
                local npc = descendant.Parent
                if npc and npc:IsA("Model") then
                    processModel(npc)
                end
            end
        end)
    end)

    if self.Debug then
        task.spawn(function()
            while self.Enabled do
                task.wait(5)
                print("[InstantKill] Kill count:", killCount)
            end
        end)
    end
end

function Module:Disable()
    self.Enabled = false

    if self.Debug then
        print("[InstantKill] Disabled - Total kills:", killCount)
    end

    if conn then
        conn:Disconnect()
        conn = nil
    end

    if childAddedConn then
        childAddedConn:Disconnect()
        childAddedConn = nil
    end

    if descendantConn then
        descendantConn:Disconnect()
        descendantConn = nil
    end

    killCount = 0
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
    if self.Debug then
        print("[InstantKill] Mode changed to:", mode)
    end
    if self.Enabled then
        -- Restart to apply new mode
        self:Disable()
        task.wait(0.1)
        self:Enable()
    end
end

function Module:SetTarget(targetName)
    self.Target = targetName
    if self.Debug then
        print("[InstantKill] Target set to:", targetName or "None")
    end
end

function Module:EnableDebug()
    self.Debug = true
    print("[InstantKill] Debug mode enabled")
end

function Module:GetKillCount()
    return killCount
end

return Module
