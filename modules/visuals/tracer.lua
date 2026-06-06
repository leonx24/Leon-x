-- Leon X | Tracer
-- Draws smooth lines from bottom-center of screen to each player's HumanoidRootPart
-- Uses Drawing API for crisp anti-aliased lines (no rotated Frame artifacts)

local Tracer = {}
Tracer.Name        = "Tracer"
Tracer.Enabled     = false
Tracer.Color       = Color3.fromRGB(255, 255, 255)
Tracer.Opacity     = 1.0    -- 0.0 to 1.0
Tracer.Thickness   = 1.5

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local lines      = {}   -- [player] = Drawing Line object
local updateConn = nil

-- Drawing API is available in most executors
-- Each line is a Drawing.new("Line") object

local function removeLine(player)
    if lines[player] then
        pcall(function() lines[player]:Remove() end)
        lines[player] = nil
    end
end

local function getOrCreateLine(player)
    local line = lines[player]
    if line then return line end

    line = Drawing.new("Line")
    line.Visible   = false
    line.Color     = Tracer.Color
    line.Thickness = Tracer.Thickness
    line.Transparency = 1 - Tracer.Opacity   -- Drawing transparency: 0=opaque, 1=invisible
    line.ZIndex    = 5
    lines[player]  = line
    return line
end

local function updateTracers()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local vp      = camera.ViewportSize
    local originX = vp.X / 2
    local originY = vp.Y   -- bottom-center of screen

    -- hide lines for players who left or lost character
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
            -- hide but keep object alive
            if lines[player] then lines[player].Visible = false end
            continue
        end

        local line = getOrCreateLine(player)
        line.From         = Vector2.new(originX, originY)
        line.To           = Vector2.new(screenPos.X, screenPos.Y)
        line.Color        = Tracer.Color
        line.Thickness    = Tracer.Thickness
        line.Transparency = 1 - Tracer.Opacity
        line.Visible      = true
    end
end

function Tracer:Enable()
    self.Enabled = true
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
end

function Tracer:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function Tracer:SetColor(color)
    self.Color = color
    for _, line in pairs(lines) do
        if line then pcall(function() line.Color = color end) end
    end
end

-- opacity: 0–100 (percentage)
function Tracer:SetOpacity(pct)
    self.Opacity = math.clamp(pct / 100, 0, 1)
    local trans = 1 - self.Opacity
    for _, line in pairs(lines) do
        if line then pcall(function() line.Transparency = trans end) end
    end
end

-- thickness: 1–5
function Tracer:SetThickness(v)
    self.Thickness = math.clamp(v, 0.5, 8)
    for _, line in pairs(lines) do
        if line then pcall(function() line.Thickness = self.Thickness end) end
    end
end

return Tracer
