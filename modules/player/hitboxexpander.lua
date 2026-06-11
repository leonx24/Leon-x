-- Leon X | Hitbox Expander
-- Expands target players' hitboxes for easier targeting
-- Size: multiplier for hitbox (default 10x)
-- Transparency: 0 = invisible, 1 = fully visible

local HitboxExpander = {}
HitboxExpander.Name         = "Hitbox Expander"
HitboxExpander.Enabled      = false
HitboxExpander.Size         = 10
HitboxExpander.Transparency = 0.8

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local modifiedData = {}  -- [player] = { originalSize, originalTrans, originalCanCollide, originalMassless }
local playerConn   = nil
local charConns    = {}
local updateConn   = nil

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

local function expandHitbox(player)
    if player == lp then return end  -- don't expand own hitbox

    pcall(function()
        local char = player.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Save original values if not already saved
        if not modifiedData[player] then
            modifiedData[player] = {
                originalSize      = hrp.Size,
                originalTrans     = hrp.Transparency,
                originalCanCollide = hrp.CanCollide,
                originalMassless  = hrp.Massless,
            }
        end

        -- Apply expanded hitbox
        hrp.Size         = Vector3.new(HitboxExpander.Size, HitboxExpander.Size, HitboxExpander.Size)
        hrp.Transparency = HitboxExpander.Transparency
        hrp.CanCollide   = false
        hrp.Massless     = true
    end)
end

local function updateAllHitboxes()
    if not HitboxExpander.Enabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            expandHitbox(player)
        end
    end
end

function HitboxExpander:Enable()
    self.Enabled = true

    -- Cleanup old connections
    if playerConn then playerConn:Disconnect(); playerConn = nil end
    for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    charConns = {}
    if updateConn then updateConn:Disconnect(); updateConn = nil end

    -- Expand existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            expandHitbox(player)

            -- Watch for character respawns
            local conn = player.CharacterAdded:Connect(function()
                task.wait(0.5)  -- wait for character to load
                if self.Enabled then
                    expandHitbox(player)
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
                expandHitbox(player)
            end
        end)
        table.insert(charConns, conn)

        if player.Character then
            expandHitbox(player)
        end
    end)

    -- Update loop to maintain hitbox size (some games reset it)
    updateConn = RunService.Heartbeat:Connect(function()
        if self.Enabled then
            updateAllHitboxes()
        end
    end)
end

function HitboxExpander:Disable()
    self.Enabled = false

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
    if self.Enabled then
        updateAllHitboxes()
    end
end

function HitboxExpander:SetTransparency(pct)
    self.Transparency = pct / 100
    if self.Enabled then
        updateAllHitboxes()
    end
end

return HitboxExpander
