-- Leon X | Hitbox Expander v2
-- Expands target players' HRP (original method) + Highlight overlay for
-- always-on-top visibility (see through walls) + color customization

local HitboxExpander = {}
HitboxExpander.Name         = "Hitbox Expander"
HitboxExpander.Enabled      = false
HitboxExpander.Size         = 10
HitboxExpander.Transparency = 0.7
HitboxExpander.Color        = Color3.fromRGB(255, 60, 60)
HitboxExpander.TeamCheck    = true

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local lp          = Players.LocalPlayer

local modifiedData = {}  -- [player] = { originalSize, originalTrans, originalCanCollide, originalMassless, hl, charConn }
local playerConn   = nil
local charConns    = {}
local updateConn   = nil
local updateTimer  = 0
local UPDATE_INTERVAL = 0.2

local function randomName()
    return HttpService:GenerateGUID(false):sub(1, 8)
end

local function isTeammate(player)
    if not HitboxExpander.TeamCheck then return false end
    if not lp.Team then return false end
    if not player.Team then return false end
    return lp.Team == player.Team
end

-- Restore original HRP + remove highlight
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
    pcall(function() if data.hl then data.hl:Destroy() end end)
    pcall(function() if data.charConn then data.charConn:Disconnect() end end)
    modifiedData[player] = nil
end

-- Expand HRP + add Highlight overlay
local function expandHitbox(player)
    if player == lp then return end
    if isTeammate(player) then return end

    pcall(function()
        local char = player.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end

        -- Remove old data if exists
        if modifiedData[player] then
            pcall(function() if modifiedData[player].hl then modifiedData[player].hl:Destroy() end end)
            pcall(function() if modifiedData[player].charConn then modifiedData[player].charConn:Disconnect() end end)
        end

        -- Save original values
        local origSize = hrp.Size
        local origTrans = hrp.Transparency
        local origCollide = hrp.CanCollide
        local origMass = hrp.Massless

        -- Expand the actual HRP
        hrp.Size         = Vector3.new(HitboxExpander.Size, HitboxExpander.Size, HitboxExpander.Size)
        hrp.Transparency = HitboxExpander.Transparency
        hrp.Color        = HitboxExpander.Color
        hrp.Material     = Enum.Material.Neon
        hrp.CanCollide   = false
        hrp.Massless     = true

        -- Highlight for always-on-top (see through walls)
        local hl = Instance.new("Highlight")
        hl.Name                = randomName()
        hl.Adornee             = char
        hl.FillColor           = HitboxExpander.Color
        hl.OutlineColor        = HitboxExpander.Color
        hl.FillTransparency    = math.max(HitboxExpander.Transparency - 0.1, 0)
        hl.OutlineTransparency = 0.2
        hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent              = char

        -- Auto-cleanup on character removal
        local charConn = char.AncestryChanged:Connect(function()
            if not char.Parent then
                restoreHitbox(player)
            end
        end)

        modifiedData[player] = {
            originalSize       = origSize,
            originalTrans      = origTrans,
            originalCanCollide = origCollide,
            originalMassless   = origMass,
            hl                 = hl,
            charConn           = charConn,
        }
    end)
end

local function updateAllHitboxes()
    if not HitboxExpander.Enabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and not isTeammate(player) then
            expandHitbox(player)
        end
    end
end

function HitboxExpander:Enable()
    self.Enabled = true
    updateTimer = 0

    if playerConn then playerConn:Disconnect(); playerConn = nil end
    for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    charConns = {}
    if updateConn then updateConn:Disconnect(); updateConn = nil end

    -- Process existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and not isTeammate(player) then
            expandHitbox(player)
            local conn = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if self.Enabled then expandHitbox(player) end
            end)
            table.insert(charConns, conn)
        end
    end

    -- Watch for new players
    playerConn = Players.PlayerAdded:Connect(function(player)
        local conn = player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self.Enabled then expandHitbox(player) end
        end)
        table.insert(charConns, conn)
        if player.Character then
            task.wait(0.5)
            expandHitbox(player)
        end
    end)

    -- Periodic re-check
    updateConn = RunService.Heartbeat:Connect(function(dt)
        if not self.Enabled then return end
        updateTimer = updateTimer + dt
        if updateTimer >= UPDATE_INTERVAL then
            updateTimer = 0
            pcall(updateAllHitboxes)
        end
    end)
end

function HitboxExpander:Disable()
    self.Enabled = false
    updateTimer = 0

    for player in pairs(modifiedData) do
        restoreHitbox(player)
    end

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
    if self.Enabled then
        for player, data in pairs(modifiedData) do
            pcall(function()
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(size, size, size)
                    end
                end
            end)
        end
    end
end

function HitboxExpander:SetTransparency(pct)
    self.Transparency = pct / 100
    if self.Enabled then
        for player, data in pairs(modifiedData) do
            pcall(function()
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Transparency = self.Transparency
                    end
                end
                if data.hl then
                    data.hl.FillTransparency = math.max(self.Transparency - 0.1, 0)
                end
            end)
        end
    end
end

function HitboxExpander:SetColor(color)
    self.Color = color
    for player, data in pairs(modifiedData) do
        pcall(function()
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Color = color end
            end
            if data.hl then
                data.hl.FillColor    = color
                data.hl.OutlineColor = color
            end
        end)
    end
end

function HitboxExpander:SetTeamCheck(enabled)
    self.TeamCheck = enabled
    if self.Enabled then
        if enabled then
            for player in pairs(modifiedData) do
                if isTeammate(player) then
                    restoreHitbox(player)
                end
            end
        else
            updateAllHitboxes()
        end
    end
end

return HitboxExpander
