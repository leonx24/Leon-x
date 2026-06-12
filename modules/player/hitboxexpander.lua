-- Leon X | Hitbox Expander v2
-- Creates visible overlay on targets (always-on-top, see through walls)
-- Also expands the actual HumanoidRootPart for easier targeting
-- Color customizable

local HitboxExpander = {}
HitboxExpander.Name         = "Hitbox Expander"
HitboxExpander.Enabled      = false
HitboxExpander.Size         = 10
HitboxExpander.Transparency = 0.8
HitboxExpander.Color        = Color3.fromRGB(255, 60, 60)
HitboxExpander.TeamCheck    = true

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local lp         = Players.LocalPlayer

local visuals      = {}  -- [player] = { box, hl, selectionBox, charConn }
local modifiedData = {}  -- [player] = { originalSize, originalTrans, originalCanCollide, originalMassless }
local playerConn   = nil
local charConns    = {}
local renderConn   = nil
local updateConn   = nil
local updateTimer  = 0
local UPDATE_INTERVAL = 0.5

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
    pcall(function() if d.selectionBox then d.selectionBox:Destroy() end end)
    pcall(function() if d.hl then d.hl:Destroy() end end)
    pcall(function() if d.box then d.box:Destroy() end end)
    visuals[player] = nil
end

-- Restore original HRP properties
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

-- Expand actual HRP for hit detection
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

        if not modifiedData[player] then
            modifiedData[player] = {
                originalSize       = hrp.Size,
                originalTrans      = hrp.Transparency,
                originalCanCollide = hrp.CanCollide,
                originalMassless   = hrp.Massless,
            }
        end
        hrp.Size         = Vector3.new(HitboxExpander.Size, HitboxExpander.Size, HitboxExpander.Size)
        hrp.Transparency = 1
        hrp.CanCollide   = false
        hrp.Massless     = true
    end)
end

-- Create visible overlay (Highlight on character + SelectionBox on invisible Part)
local function addVisual(player)
    if player == lp then return end
    if isTeammate(player) then return end
    removeVisual(player)

    local ok, char = pcall(function() return player.Character end)
    if not ok or not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local size = HitboxExpander.Size
    local color = HitboxExpander.Color

    -- 1) Highlight on the character model (always-on-top body glow)
    local hl = Instance.new("Highlight")
    hl.Name                = randomName()
    hl.Adornee             = char
    hl.FillColor           = color
    hl.OutlineColor        = color
    hl.FillTransparency    = math.max(HitboxExpander.Transparency - 0.2, 0)
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = char

    -- 2) Invisible anchor Part + SelectionBox (gives the visible box shape)
    local box = Instance.new("Part")
    box.Name         = randomName()
    box.Shape        = Enum.PartType.Block
    box.Size         = Vector3.new(size, size, size)
    box.Transparency = 1
    box.CanCollide   = false
    box.Anchored     = true
    box.Massless     = true
    box.CanTouch     = false
    box.CanQuery     = false
    box.CastShadow   = false
    box.CFrame       = hrp.CFrame
    box.Parent       = workspace

    local sb = Instance.new("SelectionBox")
    sb.Name         = randomName()
    sb.Adornee      = box
    sb.Color3       = color
    sb.Transparency = HitboxExpander.Transparency
    sb.SurfaceColor3 = color
    sb.Parent       = box

    -- Auto-cleanup when character is removed
    local charConn = char.AncestryChanged:Connect(function()
        if not char.Parent then
            removeVisual(player)
            restoreHitbox(player)
        end
    end)

    visuals[player] = {
        box = box, hl = hl, selectionBox = sb,
        hrp = hrp, charConn = charConn
    }
end

local function processPlayer(player)
    addVisual(player)
    expandHitbox(player)
end

-- Track all overlay parts to their target HRPs every frame
local function startRenderLoop()
    if renderConn then renderConn:Disconnect(); renderConn = nil end
    renderConn = RunService.RenderStepped:Connect(function()
        if not HitboxExpander.Enabled then return end
        for _, d in pairs(visuals) do
            if d.box and d.hrp and d.hrp.Parent then
                pcall(function()
                    d.box.CFrame = d.hrp.CFrame
                end)
            end
        end
    end)
end

local function stopRenderLoop()
    if renderConn then renderConn:Disconnect(); renderConn = nil end
end

function HitboxExpander:Enable()
    self.Enabled = true
    updateTimer = 0

    -- Cleanup old connections
    if playerConn then playerConn:Disconnect(); playerConn = nil end
    for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    charConns = {}
    if updateConn then updateConn:Disconnect(); updateConn = nil end
    stopRenderLoop()

    -- Process existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and not isTeammate(player) then
            processPlayer(player)
            local conn = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if self.Enabled then processPlayer(player) end
            end)
            table.insert(charConns, conn)
        end
    end

    -- Watch for new players
    playerConn = Players.PlayerAdded:Connect(function(player)
        local conn = player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self.Enabled then processPlayer(player) end
        end)
        table.insert(charConns, conn)
        if player.Character then
            task.wait(0.5)
            processPlayer(player)
        end
    end)

    -- Periodic re-check for missed players
    updateConn = RunService.Heartbeat:Connect(function(dt)
        if not self.Enabled then return end
        updateTimer = updateTimer + dt
        if updateTimer >= UPDATE_INTERVAL then
            updateTimer = 0
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= lp and not isTeammate(player) and not visuals[player] then
                    pcall(function() processPlayer(player) end)
                end
            end
        end
    end)

    -- Start CFrame tracking
    startRenderLoop()
end

function HitboxExpander:Disable()
    self.Enabled = false
    updateTimer = 0
    stopRenderLoop()

    for player in pairs(visuals) do removeVisual(player) end
    for player in pairs(modifiedData) do restoreHitbox(player) end

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
    for _, d in pairs(visuals) do
        if d.box then
            pcall(function() d.box.Size = Vector3.new(size, size, size) end)
        end
    end
    if self.Enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp and not isTeammate(player) then
                expandHitbox(player)
            end
        end
    end
end

function HitboxExpander:SetTransparency(pct)
    self.Transparency = pct / 100
    for _, d in pairs(visuals) do
        if d.selectionBox then
            pcall(function() d.selectionBox.Transparency = self.Transparency end)
        end
        if d.hl then
            pcall(function()
                d.hl.FillTransparency = math.max(self.Transparency - 0.2, 0)
            end)
        end
    end
end

function HitboxExpander:SetColor(color)
    self.Color = color
    for _, d in pairs(visuals) do
        if d.selectionBox then
            pcall(function()
                d.selectionBox.Color3      = color
                d.selectionBox.SurfaceColor3 = color
            end)
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
            for player in pairs(visuals) do
                if isTeammate(player) then
                    removeVisual(player)
                    restoreHitbox(player)
                end
            end
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= lp and not visuals[player] then
                    pcall(function() processPlayer(player) end)
                end
            end
        end
    end
end

return HitboxExpander
