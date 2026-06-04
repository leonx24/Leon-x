-- Leon X | main.lua v4.3

local BASE = "https://raw.githubusercontent.com/leonx24/Leon-x/main/"

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local Library       = loadstring(game:HttpGet(BASE .. "ui/library.lua"))()
local Fly           = loadstring(game:HttpGet(BASE .. "modules/movements/fly.lua"))()
local ConfigManager = loadstring(game:HttpGet(BASE .. "modules/core/configmanager.lua"))()

ConfigManager:Init(Library)

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local Movement = Library:CreateTab("Movement")
local Visual   = Library:CreateTab("Visual")
local Player   = Library:CreateTab("Player")
local Settings = Library:CreateTab("Settings")

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT
-- ══════════════════════════════════════════════════════════════════════════════
Movement:AddSection("Locomotion")

local flyToggle = Movement:AddToggle({
    Name     = "Fly",
    Flag     = "Fly",
    Default  = false,
    Callback = function(v)
        if v then Fly:Enable() else Fly:Disable() end
    end,
})

Movement:AddSlider({
    Name     = "Fly Speed",
    Flag     = "FlySpeed",
    Min      = 10,
    Max      = 300,
    Default  = 60,
    Suffix   = " stud/s",
    Callback = function(v) Fly:SetSpeed(v) end,
})

Movement:AddToggle({
    Name     = "Speed Hack",
    Flag     = "SpeedHack",
    Default  = false,
    Callback = function(v)
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and 60 or 16 end
    end,
})

Movement:AddSlider({
    Name     = "Walk Speed",
    Flag     = "WalkSpeed",
    Min      = 16,
    Max      = 250,
    Default  = 16,
    Suffix   = " stud/s",
    Callback = function(v)
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

Movement:AddSlider({
    Name     = "Jump Power",
    Flag     = "JumpPower",
    Min      = 50,
    Max      = 500,
    Default  = 50,
    Callback = function(v)
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end,
})

Movement:AddSection("Misc")

local infJumpOn = false
Movement:AddToggle({
    Name     = "Infinite Jump",
    Flag     = "InfiniteJump",
    Default  = false,
    Callback = function(v) infJumpOn = v end,
})

UIS.JumpRequest:Connect(function()
    if not infJumpOn then return end
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly keybind — single listener wired at startup
local flyKey = Enum.KeyCode.F
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == flyKey then
        local newState = not Fly.Enabled
        flyToggle:Set(newState)
        if newState then Fly:Enable() else Fly:Disable() end
    end
end)

Movement:AddKeybind({
    Name     = "Fly Keybind",
    Flag     = "FlyKeybind",
    Default  = Enum.KeyCode.F,
    Callback = function(key) flyKey = key end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUAL
-- ══════════════════════════════════════════════════════════════════════════════

-- ── ESP state ─────────────────────────────────────────────────────────────────
local espOn       = false
local espColor    = Color3.fromRGB(255, 255, 255)
local espOpacity  = 0.2   -- box fill transparency (0=opaque, 1=invisible)
local espBoxes    = {}    -- [player] = {box, nameTag}
local espConn     = nil

local function removeESP(player)
    if espBoxes[player] then
        pcall(function()
            if espBoxes[player].box    then espBoxes[player].box:Destroy()     end
            if espBoxes[player].nameTag then espBoxes[player].nameTag:Destroy() end
        end)
        espBoxes[player] = nil
    end
end

local function addESP(player)
    if player == lp then return end
    removeESP(player)

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- BillboardGui for name + distance
    local bbg = Instance.new("BillboardGui")
    bbg.Name         = "LeonESP_Name"
    bbg.Adornee      = hrp
    bbg.Size         = UDim2.new(0, 100, 0, 30)
    bbg.StudsOffset  = Vector3.new(0, 3, 0)
    bbg.AlwaysOnTop  = true
    bbg.Parent       = hrp

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size              = UDim2.new(1,0,1,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text              = player.Name
    nameLbl.TextColor3        = espColor
    nameLbl.Font              = Enum.Font.GothamBold
    nameLbl.TextSize          = 13
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.Parent            = bbg

    -- Highlight for box
    local hl = Instance.new("SelectionBox")
    hl.Name            = "LeonESP_Box"
    hl.Adornee         = char
    hl.Color3          = espColor
    hl.LineThickness   = 0.04
    hl.SurfaceTransparency = 1 - espOpacity
    hl.SurfaceColor3   = espColor
    hl.Parent          = workspace

    espBoxes[player] = { box = hl, nameTag = bbg }

    -- clean up when char removed
    char.AncestryChanged:Connect(function()
        if not char.Parent then removeESP(player) end
    end)
end

local function rebuildESP()
    -- clear all
    for p, _ in pairs(espBoxes) do removeESP(p) end
    if not espOn then return end
    for _, p in ipairs(Players:GetPlayers()) do
        addESP(p)
    end
end

local function updateESPColors()
    for _, data in pairs(espBoxes) do
        if data.box then
            data.box.Color3        = espColor
            data.box.SurfaceColor3 = espColor
            data.box.SurfaceTransparency = 1 - espOpacity
        end
        if data.nameTag then
            local lbl = data.nameTag:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.TextColor3 = espColor end
        end
    end
end

Visual:AddSection("Rendering")

Visual:AddToggle({
    Name     = "ESP",
    Flag     = "ESP",
    Default  = false,
    Callback = function(v)
        espOn = v
        rebuildESP()
        if v then
            -- watch for new players/chars
            espConn = Players.PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(function() task.wait(.5); addESP(p) end)
            end)
            for _, p in ipairs(Players:GetPlayers()) do
                p.CharacterAdded:Connect(function() task.wait(.5); addESP(p) end)
            end
        else
            if espConn then espConn:Disconnect(); espConn = nil end
        end
    end,
})

-- ── FullBright ────────────────────────────────────────────────────────────────
-- Save original values so we can restore them
local origLighting = {
    Brightness    = Lighting.Brightness,
    ClockTime     = Lighting.ClockTime,
    FogEnd        = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient       = Lighting.Ambient,
}

Visual:AddToggle({
    Name     = "FullBright",
    Flag     = "FullBright",
    Default  = false,
    Callback = function(v)
        if v then
            Lighting.Brightness    = 2
            Lighting.ClockTime     = 14
            Lighting.FogEnd        = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient       = Color3.fromRGB(178, 178, 178)
        else
            Lighting.Brightness    = origLighting.Brightness
            Lighting.ClockTime     = origLighting.ClockTime
            Lighting.FogEnd        = origLighting.FogEnd
            Lighting.GlobalShadows = origLighting.GlobalShadows
            Lighting.Ambient       = origLighting.Ambient
        end
    end,
})

Visual:AddSection("Appearance")

Visual:AddDropdown({
    Name     = "ESP Color",
    Flag     = "ESPColor",
    Options  = { "White", "Red", "Green", "Blue", "Yellow", "Cyan" },
    Default  = "White",
    Callback = function(v)
        local colorMap = {
            White  = Color3.fromRGB(255,255,255),
            Red    = Color3.fromRGB(255,60,60),
            Green  = Color3.fromRGB(60,255,60),
            Blue   = Color3.fromRGB(60,130,255),
            Yellow = Color3.fromRGB(255,230,60),
            Cyan   = Color3.fromRGB(60,230,255),
        }
        espColor = colorMap[v] or Color3.fromRGB(255,255,255)
        updateESPColors()
    end,
})

Visual:AddSlider({
    Name     = "ESP Opacity",
    Flag     = "ESPOpacity",
    Min      = 0,
    Max      = 100,
    Default  = 20,
    Suffix   = "%",
    Callback = function(v)
        espOpacity = v / 100
        updateESPColors()
    end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER
-- ══════════════════════════════════════════════════════════════════════════════
Player:AddSection("Utility")

-- ── Anti AFK — RunService loop approach (reliable across all executors) ────────
local antiAfkOn   = false
local antiAfkConn = nil

Player:AddToggle({
    Name     = "Anti AFK",
    Flag     = "AntiAFK",
    Default  = false,
    Callback = function(v)
        antiAfkOn = v
        if v then
            local VU = game:GetService("VirtualUser")
            antiAfkConn = RunService.Heartbeat:Connect(function()
                -- fire VirtualUser every 60s to prevent idle detection
                if tick() % 60 < 0.05 then
                    pcall(function()
                        VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    end)
                end
            end)
        else
            if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
        end
    end,
})

-- ── Teleport ──────────────────────────────────────────────────────────────────
Player:AddSection("Teleport")

local savedPosition = nil

Player:AddButton({
    Name     = "Copy My Position",
    Callback = function()
        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        savedPosition = hrp.CFrame
        local p = hrp.Position
        pcall(function()
            setclipboard(string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z))
        end)
        print(string.format("[Leon X] Position saved & copied: %.1f, %.1f, %.1f", p.X, p.Y, p.Z))
    end,
})

Player:AddButton({
    Name     = "Teleport to Saved Position",
    Callback = function()
        if not savedPosition then
            print("[Leon X] No position saved yet. Click 'Copy My Position' first.")
            return
        end
        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        -- disable fly momentarily so physics doesn't fight the teleport
        local wasFlying = Fly.Enabled
        if wasFlying then Fly:Disable() end
        hrp.CFrame = savedPosition
        task.wait(0.1)
        if wasFlying then Fly:Enable() end
        print("[Leon X] Teleported to saved position.")
    end,
})

-- ── Other player utilities ────────────────────────────────────────────────────
Player:AddSection("Server")

Player:AddButton({
    Name     = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
    end,
})

Player:AddButton({
    Name     = "Copy Player ID",
    Callback = function()
        pcall(function() setclipboard(tostring(lp.UserId)) end)
        print("[Leon X] Copied UserId:", lp.UserId)
    end,
})

Player:AddSection("Stats")

Player:AddLabel({ Text = "Username: " .. lp.Name,            Color = Color3.fromRGB(100,100,100) })
Player:AddLabel({ Text = "User ID: "  .. tostring(lp.UserId), Color = Color3.fromRGB(100,100,100) })

-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS
-- ══════════════════════════════════════════════════════════════════════════════
Settings:AddSection("Interface")

Settings:AddToggle({
    Name     = "Show Notifications",
    Flag     = "ShowNotifs",
    Default  = true,
    Callback = function(v) print("Notifs:", v) end,
})

Settings:AddDropdown({
    Name     = "Theme",
    Flag     = "Theme",
    Options  = { "Dark", "Midnight", "Slate" },
    Default  = "Dark",
    Callback = function(v) print("Theme:", v) end,
})

-- ── Config manager UI ─────────────────────────────────────────────────────────
Settings:AddSection("Config")

local configName    = "default"
local configNameLbl = Settings:AddLabel({
    Text  = "Save name: default",
    Color = Color3.fromRGB(160,160,160),
})

local function setConfigName(n)
    configName = n
    configNameLbl:Set("Save name: " .. n)
end

for _, n in ipairs({"default", "pvp", "farming", "custom"}) do
    local nc = n
    Settings:AddButton({ Name = "› " .. n, Callback = function() setConfigName(nc) end })
end

local function getConfigList()
    local list = ConfigManager:List()
    return #list > 0 and list or {"(none)"}
end

local configSelect = Settings:AddDropdown({
    Name    = "Select Config",
    Options = getConfigList(),
    Default = ConfigManager:List()[1] or "(none)",
})

Settings:AddButton({
    Name     = "💾  Save Config",
    Callback = function()
        local ok = ConfigManager:Save(configName)
        print(ok and ("Saved: " .. configName) or "Save failed")
        configSelect:SetOptions(getConfigList())
        configSelect:Set(configName)
    end,
})

Settings:AddButton({
    Name     = "📂  Load Config",
    Callback = function()
        local sel = configSelect:Get()
        if sel == "(none)" then return end
        local ok = ConfigManager:Load(sel)
        print(ok and ("Loaded: " .. sel) or "Load failed: " .. sel)
    end,
})

Settings:AddButton({
    Name     = "🗑  Delete Config",
    Callback = function()
        local sel = configSelect:Get()
        if sel == "(none)" then return end
        ConfigManager:Delete(sel)
        configSelect:SetOptions(getConfigList())
    end,
})

Settings:AddButton({
    Name     = "⭐  Set as Default",
    Callback = function()
        local sel = configSelect:Get()
        if sel == "(none)" then return end
        ConfigManager:SetDefault(sel)
        print(sel .. " set as default")
    end,
})

Settings:AddSection("About")
Settings:AddLabel({
    Text  = "Leon X  ·  v4.3",
    Color = Color3.fromRGB(70,70,70),
    Align = Enum.TextXAlignment.Center,
})

-- ── Auto-load default config — MUST be last ───────────────────────────────────
ConfigManager:AutoLoad()
