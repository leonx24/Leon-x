-- Leon X | Tracer
-- Draws lines from bottom-center of screen to each player's HumanoidRootPart

local Tracer = {}
Tracer.Name    = "Tracer"
Tracer.Enabled = false
Tracer.Color   = Color3.fromRGB(255, 255, 255)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local tracerGui  = nil
local lines      = {}   -- [player] = Frame (reused each frame)
local updateConn = nil

local function getOrCreateGui()
    if tracerGui and tracerGui.Parent then return tracerGui end
    -- destroy stale instance if it exists but lost its parent
    if tracerGui then pcall(function() tracerGui:Destroy() end) end
    local gui = Instance.new("ScreenGui")
    gui.Name           = "LeonTracer"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder   = 998
    gui.IgnoreGuiInset = true
    gui.Parent         = lp:WaitForChild("PlayerGui")
    tracerGui = gui
    return gui
end

local function removeLine(player)
    if lines[player] then
        pcall(function() lines[player]:Destroy() end)
        lines[player] = nil
    end
end

-- Update or create a single reused Frame to represent this line
local function setLine(player, x1, y1, x2, y2, color, parent)
    local dx  = x2 - x1
    local dy  = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then
        removeLine(player)
        return
    end

    local angle = math.atan2(dy, dx)
    local cx    = (x1 + x2) / 2
    local cy    = (y1 + y2) / 2

    local line = lines[player]
    if not line or not line.Parent then
        -- create a fresh frame for this player
        line = Instance.new("Frame")
        line.BackgroundColor3 = color
        line.BorderSizePixel  = 0
        line.AnchorPoint      = Vector2.new(0.5, 0.5)
        line.ZIndex           = 5
        line.Parent           = parent
        lines[player]         = line
    end

    -- update properties in-place (no destroy/recreate overhead)
    line.BackgroundColor3 = color
    line.Position         = UDim2.new(0, cx, 0, cy)
    line.Size             = UDim2.new(0, len, 0, 2)
    line.Rotation         = math.deg(angle)
end

local function updateTracers()
    local gui = getOrCreateGui()
    if not gui then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local vp      = camera.ViewportSize
    local originX = vp.X / 2
    local originY = vp.Y  -- bottom-center of screen

    -- remove lines for players who left or lost their character
    for p in pairs(lines) do
        if not p or not p.Parent or not p.Character then
            removeLine(p)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == lp then continue end

        local char = player.Character
        if not char then removeLine(player); continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then removeLine(player); continue end

        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            removeLine(player)
            continue
        end

        setLine(player, originX, originY, screenPos.X, screenPos.Y, Tracer.Color, gui)
    end
end

function Tracer:Enable()
    self.Enabled = true
    getOrCreateGui()
    if updateConn then updateConn:Disconnect(); updateConn = nil end
    updateConn = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        updateTracers()
    end)
end

function Tracer:Disable()
    self.Enabled = false
    if updateConn then updateConn:Disconnect(); updateConn = nil end
    for p in pairs(lines) do removeLine(p) end
    if tracerGui then
        pcall(function() tracerGui:Destroy() end)
        tracerGui = nil
    end
end

function Tracer:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function Tracer:SetColor(color)
    self.Color = color
    for _, line in pairs(lines) do
        if line and line.Parent then
            pcall(function() line.BackgroundColor3 = color end)
        end
    end
end

return Tracer
