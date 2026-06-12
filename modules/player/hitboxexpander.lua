-- Leon X | Hitbox Expander v2
-- Creates visible overlay boxes on targets (always-on-top, see through walls)
-- Also expands the actual HumanoidRootPart for easier targeting
-- Color customizable

local HitboxExpander = {}
HitboxExpander.Name         = "Hitbox Expander"
HitboxExpander.Enabled      = false
HitboxExpander.Size         = 10
HitboxExpander.Transparency = 0.8
HitboxExpander.Color        = Color3.fromRGB(255, 60, 60)
HitboxExpander.TeamCheck    = true  -- Skip teammates

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local lp         = Players.LocalPlayer

local visuals    = {}  -- [player] = { box, weld, charConn }
local modifiedData = {}  -- [player] = { originalSize, originalTrans, originalCanCollide, originalMassless }
local playerConn = nil
local charConns  = {}
local updateConn = nil
local updateTimer = 0
local UPDATE_INTERVAL = 0.2

-- Anti-detection: random instance names
local function randomName()
    return HttpService:GenerateGUID(false):sub(1, 8)
end

local function isTeammate(player)
    if not HitboxExpander.TeamCheck then return false end
    if not lp.Team then return false end
    if not player.Team then return false end
    return lp.Team == player.Team
end

-- Remove visual overlay for a player
local function removeVisual(player)
    local d = visuals[player]
    if not d then return end
    pcall(function() if d.charConn then d.charConn:Disconnect() end end)
    pcall(function() if d.box then d.box:Destroy() end end)
    visuals[player] = nil
end

-- Restore original HRP properties for a player
local function restoreHitbox(player)
    local data = modifiedData[player]
    if not data then return end
    pcall(function()
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size         = data.originalSize
                hrp.Transparency = data.originalTrans
                hrp.CanCollide   = data.originalCanCollide
                hrp.Massless     = data.originalMassless
            end
        end
    end)
    modifiedData[player] = nil
end

-- Expand the actual HRP for hit detection
local function expandHitbox(player)
    if player == lp then return end
    if isTeammate(player) then return end

    pcall(function()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        if not modifiedData[player] then
            modifiedData[player] = {
                originalSize       = hrp.Size,
                originalTrans      = hrp.Transparency,
                originalCanCollide = hrp.CanCollide,
                originalMassless   = hrp.Massless,
            }
        end

        hrp.Size         = Vector3.new(HitboxExpander.Size, HitboxExpander.Size, HitboxExpander.Size)
        hrp.Transparency = 1  -- hide actual HRP, visual overlay handles display
        hrp.CanCollide   = false
        hrp.Massless     = true
    end)
end

-- Create visible overlay box (always-on-top, like ESP)
local function addVisual(player)
    if player == lp then return end
    if isTeammate(player) then return end
    removeVisual(player)

    local success, char = pcall(function() return player.Character end)
    if not success or not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    -- Visual overlay box
    local box = Instance.new("Part")
    box.Name             = randomName()
    box.Shape            = Enum.PartType.Block
    box.Size             = Vector3.new(HitboxExpander.Size, HitboxExpander.Size, HitboxExpander.Size)
    box.Material         = Enum.Material.Neon
    box.Color            = HitboxExpander.Color
    box.Transparency     = HitboxExpander.Transparency
    box.CanCollide       = false
    box.Anchored         = false
    box.Massless         = true
    box.CastShadow       = false
    box.CanTouch         = false
    box.CanQuery         = false

    -- Highlight for always-on-top visibility (see through walls)
    local hl = Instance.new("Highlight")
    hl.Name                = randomName()
    hl.Adornee             = box
    hl.FillColor           = HitboxExpander.Color
    hl.OutlineColor        = HitboxExpander.Color
    hl.FillTransparency    = math.min(HitboxExpander.Transparency + 0.1, 1)
    hl.OutlineTransparency = 0.3
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = box

    -- Weld to HRP so it follows the character
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = box
    weld.Part1 = hrp

    local ok = pcall(function()
        box.Parent = char
        weld.Parent = box
    end)
    if not ok then
        box:Destroy()
        return
    end

    -- Auto-cleanup when character is removed
    local charConn = char.AncestryChanged:Connect(function()
        if not char.Parent then
            removeVisual(player)
            restoreHitbox(player)
        end
    end)

    visuals[player] = { box = box, weld = weld, hl = hl, charConn = charConn }
end

-- Create both visual overlay and expand actual hitbox
local function processPlayer(player)
    addVisual(player)
    expandHitbox(player)
end

local function updateAllHitboxes()
    if not HitboxExpander.Enabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and not isTeammate(player) then
            processPlayer(player)
        end
    end
end

function HitboxExpander:Enable()
    self.Enabled = true
    updateTimer = 0

    -- Cleanup old connections
    if playerConn then playerConn:Disconnect(); playerConn = nil end
    for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    charConns = {}
    if updateConn then updateConn:Disconnect(); updateConn = nil end

    -- Process existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and not isTeammate(player) then
            processPlayer(player)

            local conn = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if self.Enabled then
                    processPlayer(player)
                end
            end)
            table.insert(charConns, conn)
        end
    end

    -- Watch for new players
    playerConn = Players.PlayerAdded:Connect(function(player)
        local conn = player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self.Enabled then
                processPlayer(player)
            end
        end)
        table.insert(charConns, conn)

        if player.Character then
            task.wait(0.5)
            processPlayer(player)
        end
    end)

    -- Update loop
    updateConn = RunService.Heartbeat:Connect(function(deltaTime)
        if not self.Enabled then return end
        updateTimer = updateTimer + deltaTime
        if updateTimer >= UPDATE_INTERVAL then
            updateTimer = 0
            pcall(updateAllHitboxes)
        end
    end)
end

function HitboxExpander:Disable()
    self.Enabled = false
    updateTimer = 0

    -- Remove all visuals
    for player in pairs(visuals) do
        removeVisual(player)
    end

    -- Restore all hitboxes
    for player in pairs(modifiedData) do
        restoreHitbox(player)
    end

    -- Cleanup connections
    if playerConn then playerConn:Disconnect(); playerConn = nil end
    for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    charConns = {}
    if updateConn then updateConn:Disconnect(); updateConn = nil end
end

function HitboxExpander:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function HitboxExpander:SetSize(size)
    self.Size = size
    -- Update all existing visuals
    for player, d in pairs(visuals) do
        if d.box then
            pcall(function() d.box.Size = Vector3.new(size, size, size) end)
        end
    end
    -- Update actual hitboxes too
    if self.Enabled then
        updateAllHitboxes()
    end
end

function HitboxExpander:SetTransparency(pct)
    self.Transparency = pct / 100
    -- Update all existing visuals
    for _, d in pairs(visuals) do
        if d.box then
            pcall(function()
                d.box.Transparency = self.Transparency
            end)
        end
        if d.hl then
            pcall(function()
                d.hl.FillTransparency = math.min(self.Transparency + 0.1, 1)
            end)
        end
    end
end

function HitboxExpander:SetColor(color)
    self.Color = color
    -- Update all existing visuals
    for _, d in pairs(visuals) do
        if d.box then
            pcall(function() d.box.Color = color end)
        end
        if d.hl then
            pcall(function()
                d.hl.FillColor    = color
                d.hl.OutlineColor = color
            end)
        end
    end
end

function HitboxExpander:SetTeamCheck(enabled)
    self.TeamCheck = enabled
    if self.Enabled then
        if enabled then
            -- Restore teammates
            for player in pairs(visuals) do
                if isTeammate(player) then
                    removeVisual(player)
                    restoreHitbox(player)
                end
            end
        else
            -- Expand all players
            updateAllHitboxes()
        end
    end
end

return HitboxExpander
