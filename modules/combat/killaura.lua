-- Leon X | Kill Aura
-- Automatically attacks nearby enemies with equipped tool
-- Works universally across most combat games

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer

local KillAura = {}
KillAura.Name = "KillAura"
KillAura.Enabled = false
KillAura.Radius = 15
KillAura.AttackInterval = 0.1 -- seconds between attacks
KillAura.TargetPlayers = true
KillAura.TargetNPCs = true
KillAura.TeamCheck = true -- skip teammates

local connection = nil
local lastAttack = 0

local function getHRP()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getEquippedTool()
    local char = lp.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
    end
    return nil
end

local function isTeammate(target)
    if not KillAura.TeamCheck then return false end
    local myTeam = lp.Team
    local theirTeam = target.Team
    if myTeam and theirTeam and myTeam == theirTeam then
        return true
    end
    return false
end

local function isValidTarget(model)
    -- Check if it's a player
    local player = Players:GetPlayerFromCharacter(model)
    if player then
        if player == lp then return false end
        if isTeammate(player) then return false end
        if not KillAura.TargetPlayers then return false end
        -- Check if alive
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        return true
    end
    
    -- Check if it's an NPC
    if not KillAura.TargetNPCs then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    
    -- Skip if it has a player (already handled above)
    if Players:GetPlayerFromCharacter(model) then return false end
    
    -- Basic NPC validation - has humanoid and is not us
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    return true
end

local function getTargetsInRadius(centerPos, radius)
    local targets = {}
    
    -- Check players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            local char = player.Character
            if char and isValidTarget(char) then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - centerPos).Magnitude
                    if dist <= radius then
                        targets[#targets + 1] = { model = char, hrp = hrp, dist = dist }
                    end
                end
            end
        end
    end
    
    -- Check NPCs in workspace
    if KillAura.TargetNPCs then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and isValidTarget(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - centerPos).Magnitude
                    if dist <= radius then
                        targets[#targets + 1] = { model = obj, hrp = hrp, dist = dist }
                    end
                end
            end
        end
    end
    
    -- Sort by distance (closest first)
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    
    return targets
end

local function attackTarget(target)
    local tool = getEquippedTool()
    if not tool then
        -- No tool equipped, try to simulate click anyway
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(
                target.hrp.Position.X, 
                target.hrp.Position.Y, 
                0, true, game, 1
            )
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(
                target.hrp.Position.X, 
                target.hrp.Position.Y, 
                0, false, game, 1
            )
        end)
        return
    end
    
    -- Activate the tool (simulate click)
    pcall(function()
        tool:Activate()
    end)
end

function KillAura:Enable()
    if self.Enabled then return end
    self.Enabled = true
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    connection = RunService.Heartbeat:Connect(function(dt)
        if not self.Enabled then return end
        
        local now = tick()
        if now - lastAttack < self.AttackInterval then return end
        lastAttack = now
        
        local hrp = getHRP()
        if not hrp then return end
        
        local targets = getTargetsInRadius(hrp.Position, self.Radius)
        if #targets > 0 then
            -- Attack the closest target
            attackTarget(targets[1])
        end
    end)
end

function KillAura:Disable()
    self.Enabled = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

function KillAura:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

function KillAura:SetRadius(v)
    self.Radius = tonumber(v) or 15
end

function KillAura:SetAttackInterval(v)
    self.AttackInterval = tonumber(v) or 0.1
end

function KillAura:SetTargetPlayers(v)
    self.TargetPlayers = v
end

function KillAura:SetTargetNPCs(v)
    self.TargetNPCs = v
end

function KillAura:SetTeamCheck(v)
    self.TeamCheck = v
end

return KillAura
