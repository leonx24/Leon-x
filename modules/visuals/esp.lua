-- Leon X | ESP v2
-- Highlight body + name tag with distance
-- ShowMode: "Both" | "Body" | "Name"

local ESP = {}
ESP.Name     = "ESP"
ESP.Enabled  = false
ESP.Color    = Color3.fromRGB(255, 255, 255)
ESP.Opacity  = 0.15
ESP.ShowMode = "Both"   -- "Both" | "Body" | "Name"

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local lp         = Players.LocalPlayer

local espData    = {}   -- [player] = { hl, bbg, nameLbl, distLbl, cleanupConn }
local playerConn = nil
local charConns  = {}
local updateConn = nil  -- Heartbeat for distance update

-- Anti-detection: generate random instance names
local function randomName()
    return HttpService:GenerateGUID(false):sub(1, 8)
end

local function removeESP(player)
    local d = espData[player]
    if not d then return end
    -- Cleanup connections first to prevent memory leaks
    pcall(function() if d.cleanupConn then d.cleanupConn:Disconnect() end end)
    pcall(function() if d.hl  then d.hl:Destroy()  end end)
    pcall(function() if d.bbg then d.bbg:Destroy() end end)
    espData[player] = nil
end

local function addESP(player)
    if player == lp then return end
    removeESP(player)

    -- Error handling: safely check character exists
    local success, char = pcall(function() return player.Character end)
    if not success or not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Highlight (body) - with anti-detection random name
    local hl = Instance.new("Highlight")
    hl.Name                = randomName()  -- Anti-detection: random GUID
    hl.Adornee             = char
    hl.OutlineColor        = ESP.Color
    hl.FillColor           = ESP.Color
    hl.OutlineTransparency = 0
    hl.FillTransparency    = 1 - ESP.Opacity
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled             = (ESP.ShowMode == "Both" or ESP.ShowMode == "Body")

    -- Error handling: parent might fail
    local ok = pcall(function() hl.Parent = char end)
    if not ok then hl:Destroy(); return end

    -- BillboardGui (name + distance) - with anti-detection random name
    local bbg = Instance.new("BillboardGui")
    bbg.Name        = randomName()  -- Anti-detection: random GUID
    bbg.Adornee     = hrp
    bbg.Size        = UDim2.new(0, 150, 0, 40)
    bbg.StudsOffset = Vector3.new(0, 3.4, 0)
    bbg.AlwaysOnTop = true
    bbg.Enabled     = (ESP.ShowMode == "Both" or ESP.ShowMode == "Name")

    ok = pcall(function() bbg.Parent = hrp end)
    if not ok then hl:Destroy(); bbg:Destroy(); return end

    -- layout inside bbg
    local layout = Instance.new("UIListLayout")
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Padding             = UDim.new(0, 1)
    layout.Parent              = bbg

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size                   = UDim2.new(1, 0, 0, 18)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                   = player.Name
    nameLbl.TextColor3             = ESP.Color
    nameLbl.Font                   = Enum.Font.GothamBold
    nameLbl.TextSize               = 13
    nameLbl.TextStrokeTransparency = 0.35
    nameLbl.TextStrokeColor3       = Color3.new(0, 0, 0)
    nameLbl.Parent                 = bbg

    local distLbl = Instance.new("TextLabel")
    distLbl.Size                   = UDim2.new(1, 0, 0, 14)
    distLbl.BackgroundTransparency = 1
    distLbl.Text                   = "? stud"
    distLbl.TextColor3             = Color3.fromRGB(180, 180, 180)
    distLbl.Font                   = Enum.Font.Gotham
    distLbl.TextSize               = 11
    distLbl.TextStrokeTransparency = 0.4
    distLbl.TextStrokeColor3       = Color3.new(0, 0, 0)
    distLbl.Parent                 = bbg

    -- Respawn handling: cleanup connection that auto-removes ESP when character dies
    local cleanupConn = char.AncestryChanged:Connect(function()
        if not char.Parent then removeESP(player) end
    end)

    espData[player] = { hl=hl, bbg=bbg, nameLbl=nameLbl, distLbl=distLbl, cleanupConn=cleanupConn }
end

local function applyShowMode()
    local showBody = (ESP.ShowMode == "Both" or ESP.ShowMode == "Body")
    local showName = (ESP.ShowMode == "Both" or ESP.ShowMode == "Name")
    for _, d in pairs(espData) do
        if d.hl  then d.hl.Enabled  = showBody end
        if d.bbg then d.bbg.Enabled = showName end
    end
end

local function startDistanceUpdate()
    if updateConn then return end
    updateConn = RunService.Heartbeat:Connect(function()
        -- Error handling: safely get player's HRP
        local success, myHRP = pcall(function()
            return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        end)
        if not success or not myHRP then return end

        for player, d in pairs(espData) do
            if d.distLbl then
                pcall(function()
                    local char = player.Character
                    if char then
                        local tHRP = char:FindFirstChild("HumanoidRootPart")
                        if tHRP then
                            local dist = math.floor((myHRP.Position - tHRP.Position).Magnitude)
                            d.distLbl.Text = dist .. " stud"
                        end
                    end
                end)
            end
        end
    end)
end

local function stopDistanceUpdate()
    if updateConn then updateConn:Disconnect(); updateConn = nil end
end

function ESP:Rebuild()
    for p in pairs(espData) do removeESP(p) end
    if not self.Enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
    applyShowMode()
end

function ESP:UpdateVisuals()
    local showBody = (self.ShowMode == "Both" or self.ShowMode == "Body")
    local showName = (self.ShowMode == "Both" or self.ShowMode == "Name")
    for _, d in pairs(espData) do
        if d.hl then
            d.hl.OutlineColor    = self.Color
            d.hl.FillColor       = self.Color
            d.hl.FillTransparency = 1 - self.Opacity
            d.hl.Enabled         = showBody
        end
        if d.bbg then d.bbg.Enabled = showName end
        if d.nameLbl then d.nameLbl.TextColor3 = self.Color end
    end
end

function ESP:Enable()
    self.Enabled = true
    self:Rebuild()
    startDistanceUpdate()

    -- Cleanup old connections to prevent duplicates
    if playerConn then playerConn:Disconnect(); playerConn = nil end
    for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    charConns = {}

    playerConn = Players.PlayerAdded:Connect(function(p)
        local c = p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self.Enabled then
                pcall(function() addESP(p) end)
            end
        end)
        table.insert(charConns, c)
        if p.Character then
            pcall(function() addESP(p) end)
        end
    end)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local c = p.CharacterAdded:Connect(function()
                task.wait(0.5)
                if self.Enabled then
                    pcall(function() addESP(p) end)
                end
            end)
            table.insert(charConns, c)
        end
    end
end

function ESP:Disable()
    self.Enabled = false
    stopDistanceUpdate()
    if playerConn then playerConn:Disconnect(); playerConn = nil end
    for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    charConns = {}
    self:Rebuild()
end

function ESP:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function ESP:SetColor(color)
    self.Color = color; self:UpdateVisuals()
end

function ESP:SetOpacity(pct)
    self.Opacity = pct / 100; self:UpdateVisuals()
end

function ESP:SetShowMode(mode)
    self.ShowMode = mode; self:UpdateVisuals()
end

return ESP
