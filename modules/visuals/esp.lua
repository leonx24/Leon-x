-- Leon X | ESP
-- Highlight-based ESP: follows body shape, always on top (wall hack)

local ESP = {}
ESP.Name    = "ESP"
ESP.Enabled = false
ESP.Color   = Color3.fromRGB(255,255,255)
ESP.Opacity = 0.15

local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

local espData       = {}
local playerConn    = nil
local charConns     = {}

local function removeESP(player)
    local d = espData[player]
    if not d then return end
    pcall(function() if d.hl  then d.hl:Destroy()  end end)
    pcall(function() if d.bbg then d.bbg:Destroy() end end)
    espData[player] = nil
end

local function addESP(player)
    if player == lp then return end
    removeESP(player)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hl = Instance.new("Highlight")
    hl.Name                = "LeonESP"
    hl.Adornee             = char
    hl.OutlineColor        = ESP.Color
    hl.FillColor           = ESP.Color
    hl.OutlineTransparency = 0
    hl.FillTransparency    = 1 - ESP.Opacity
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = char

    local bbg = Instance.new("BillboardGui")
    bbg.Name        = "LeonESP_Name"
    bbg.Adornee     = hrp
    bbg.Size        = UDim2.new(0,130,0,28)
    bbg.StudsOffset = Vector3.new(0,3.2,0)
    bbg.AlwaysOnTop = true
    bbg.Parent      = hrp

    local nl = Instance.new("TextLabel")
    nl.Size                   = UDim2.new(1,0,1,0)
    nl.BackgroundTransparency = 1
    nl.Text                   = player.Name
    nl.TextColor3             = ESP.Color
    nl.Font                   = Enum.Font.GothamBold
    nl.TextSize               = 13
    nl.TextStrokeTransparency = 0.4
    nl.TextStrokeColor3       = Color3.new(0,0,0)
    nl.Parent                 = bbg

    espData[player] = { hl=hl, bbg=bbg }
end

function ESP:Rebuild()
    for p in pairs(espData) do removeESP(p) end
    if not self.Enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
end

function ESP:UpdateVisuals()
    for _, d in pairs(espData) do
        if d.hl then
            d.hl.OutlineColor    = self.Color
            d.hl.FillColor       = self.Color
            d.hl.FillTransparency = 1 - self.Opacity
        end
        if d.bbg then
            local nl = d.bbg:FindFirstChildOfClass("TextLabel")
            if nl then nl.TextColor3 = self.Color end
        end
    end
end

function ESP:Enable()
    self.Enabled = true
    self:Rebuild()
    playerConn = Players.PlayerAdded:Connect(function(p)
        local c = p.CharacterAdded:Connect(function()
            task.wait(0.5); addESP(p)
        end)
        table.insert(charConns, c)
        if p.Character then addESP(p) end
    end)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local c = p.CharacterAdded:Connect(function()
                task.wait(0.5); addESP(p)
            end)
            table.insert(charConns, c)
        end
    end
end

function ESP:Disable()
    self.Enabled = false
    if playerConn then playerConn:Disconnect(); playerConn = nil end
    for _, c in ipairs(charConns) do c:Disconnect() end
    charConns = {}
    self:Rebuild()
end

function ESP:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function ESP:SetColor(color)
    self.Color = color
    self:UpdateVisuals()
end

function ESP:SetOpacity(pct)
    self.Opacity = pct / 100
    self:UpdateVisuals()
end

return ESP
