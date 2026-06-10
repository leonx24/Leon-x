-- Leon X | Tracer
-- Draws lines from bottom-center of screen to each player's HumanoidRootPart
-- Uses Drawing API if available, falls back to rotated Frames

local Tracer = {}
Tracer.Name      = "Tracer"
Tracer.Enabled   = false
Tracer.Color     = Color3.fromRGB(255, 255, 255)
Tracer.Opacity   = 1.0   -- 0.0–1.0
Tracer.Thickness = 2

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local lp         = Players.LocalPlayer

local updateConn = nil
local lines      = {}   -- [player] = line object (Drawing or Frame)

-- Anti-detection: generate random instance names
local function randomName()
    return HttpService:GenerateGUID(false):sub(1, 8)
end

-- ── detect which renderer to use ─────────────────────────────────────────────
local useDrawing = false
do
    local ok = pcall(function()
        local test = Drawing.new("Line")
        test:Remove()
    end)
    useDrawing = ok
end

-- ── Drawing renderer ─────────────────────────────────────────────────────────
local function drawingCreate()
    local l = Drawing.new("Line")
    l.Visible      = false
    l.Color        = Tracer.Color
    l.Thickness    = Tracer.Thickness
    l.Transparency = 1 - Tracer.Opacity
    l.ZIndex       = 5
    return l
end

local function drawingUpdate(l, x1, y1, x2, y2)
    l.From         = Vector2.new(x1, y1)
    l.To           = Vector2.new(x2, y2)
    l.Color        = Tracer.Color
    l.Thickness    = Tracer.Thickness
    l.Transparency = 1 - Tracer.Opacity
    l.Visible      = true
end

local function drawingHide(l)
    l.Visible = false
end

local function drawingRemove(l)
    pcall(function() l:Remove() end)
end

-- ── Frame renderer ────────────────────────────────────────────────────────────
local tracerGui = nil

local function getGui()
    if tracerGui and tracerGui.Parent then return tracerGui end
    if tracerGui then pcall(function() tracerGui:Destroy() end) end

    -- Error handling: safely get PlayerGui
    local success, pg = pcall(function()
        return lp:FindFirstChildOfClass("PlayerGui")
    end)
    if not success or not pg then return nil end

    -- Anti-detection: random GUI name
    local sg = Instance.new("ScreenGui")
    sg.Name           = randomName()
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 998
    sg.IgnoreGuiInset = true

    local ok = pcall(function() sg.Parent = pg end)
    if not ok then sg:Destroy(); return nil end

    tracerGui = sg
    return sg
end

local function frameCreate()
    local gui = getGui()
    if not gui then return nil end
    local f = Instance.new("Frame")
    f.BackgroundColor3   = Tracer.Color
    f.BorderSizePixel    = 0
    f.AnchorPoint        = Vector2.new(0.5, 0.5)
    f.BackgroundTransparency = 1 - Tracer.Opacity
    f.ZIndex             = 5
    f.Parent             = gui
    return f
end

local function frameUpdate(f, x1, y1, x2, y2)
    if not f or not f.Parent then return false end
    local dx  = x2 - x1
    local dy  = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then f.Visible = false; return true end
    local cx = (x1 + x2) / 2
    local cy = (y1 + y2) / 2
    f.Position               = UDim2.new(0, cx, 0, cy)
    f.Size                   = UDim2.new(0, len, 0, math.max(1, Tracer.Thickness))
    f.Rotation               = math.deg(math.atan2(dy, dx))
    f.BackgroundColor3       = Tracer.Color
    f.BackgroundTransparency = 1 - Tracer.Opacity
    f.Visible                = true
    return true
end

local function frameHide(f)
    if f and f.Parent then f.Visible = false end
end

local function frameRemove(f)
    pcall(function() f:Destroy() end)
end

-- ── unified helpers ───────────────────────────────────────────────────────────
local function createLine()
    if useDrawing then return drawingCreate() end
    return frameCreate()
end

local function updateLine(l, x1, y1, x2, y2)
    if not l then return false end
    if useDrawing then
        drawingUpdate(l, x1, y1, x2, y2)
        return true
    end
    return frameUpdate(l, x1, y1, x2, y2)
end

local function hideLine(l)
    if not l then return end
    if useDrawing then drawingHide(l) else frameHide(l) end
end

local function removeLine(player)
    if lines[player] then
        if useDrawing then drawingRemove(lines[player])
        else frameRemove(lines[player]) end
        lines[player] = nil
    end
end

-- ── main update ───────────────────────────────────────────────────────────────
local function updateTracers()
    -- Error handling: safely get camera
    local success, camera = pcall(function() return workspace.CurrentCamera end)
    if not success or not camera then return end

    local vp      = camera.ViewportSize
    local originX = vp.X / 2
    local originY = vp.Y  -- bottom-center

    -- collect stale players safely (can't modify table while iterating)
    local toRemove = {}
    for p in pairs(lines) do
        if not p or not p.Parent or not p.Character then
            toRemove[#toRemove + 1] = p
        end
    end
    for _, p in ipairs(toRemove) do removeLine(p) end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            pcall(function()
                local char = player.Character
                if not char then removeLine(player); return end

                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then removeLine(player); return end

                local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if not onScreen then
                    hideLine(lines[player])
                    return
                end

                -- create line object if needed
                if not lines[player] then
                    lines[player] = createLine()
                end

                if not updateLine(lines[player], originX, originY, screenPos.X, screenPos.Y) then
                    -- frame became invalid (gui was destroyed), recreate
                    lines[player] = createLine()
                    updateLine(lines[player], originX, originY, screenPos.X, screenPos.Y)
                end
            end)
        end
    end
end

-- ── public API ────────────────────────────────────────────────────────────────
function Tracer:Enable()
    self.Enabled = true
    if not useDrawing then getGui() end

    -- Cleanup old connection to prevent duplicates
    if updateConn then
        pcall(function() updateConn:Disconnect() end)
        updateConn = nil
    end

    updateConn = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        pcall(updateTracers)
    end)
end

function Tracer:Disable()
    self.Enabled = false

    -- Cleanup connection with error handling
    if updateConn then
        pcall(function() updateConn:Disconnect() end)
        updateConn = nil
    end

    -- Remove all lines
    local toRemove = {}
    for p in pairs(lines) do toRemove[#toRemove + 1] = p end
    for _, p in ipairs(toRemove) do pcall(function() removeLine(p) end) end

    -- Cleanup GUI
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
    for _, l in pairs(lines) do
        if l then pcall(function()
            if useDrawing then l.Color = color
            else l.BackgroundColor3 = color end
        end) end
    end
end

-- pct: 0–100
function Tracer:SetOpacity(pct)
    self.Opacity = math.clamp(pct / 100, 0, 1)
    local trans = 1 - self.Opacity
    for _, l in pairs(lines) do
        if l then pcall(function()
            if useDrawing then l.Transparency = trans
            else l.BackgroundTransparency = trans end
        end) end
    end
end

-- v: 1–8
function Tracer:SetThickness(v)
    self.Thickness = math.clamp(v, 1, 8)
    for _, l in pairs(lines) do
        if l then pcall(function()
            if useDrawing then l.Thickness = self.Thickness
            else l.Size = UDim2.new(0, l.Size.X.Offset, 0, self.Thickness) end
        end) end
    end
end

return Tracer
