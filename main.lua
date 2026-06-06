-- Leon X | main.lua v4.4

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

-- shorthand for notifications
local function notify(title, text, ntype, dur)
    Library:Notify({ Title=title, Text=text, Type=ntype or "info", Duration=dur or 3 })
end

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
        notify("Fly", v and "Fly enabled" or "Fly disabled", v and "success" or "info", 2)
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

-- persisted values — deklarasi SEBELUM semua callback yang pakai mereka
local _walkSpeed   = 16
local _jumpPower   = 50
local _speedHackOn = false

Movement:AddToggle({
    Name     = "Speed Hack",
    Flag     = "SpeedHack",
    Default  = false,
    Callback = function(v)
        _speedHackOn = v
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = v and 60 or 16
            if v then _walkSpeed = 60 end
        end
        notify("Speed Hack", v and "Enabled (60)" or "Disabled", v and "success" or "info", 2)
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
        _walkSpeed = v
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
        _jumpPower = v
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower  = v
            hum.JumpHeight = v * 0.05
        end
    end,
})

-- re-apply setelah respawn
lp.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if _walkSpeed ~= 16 then hum.WalkSpeed = _walkSpeed end
    if _jumpPower ~= 50 then
        hum.JumpPower  = _jumpPower
        hum.JumpHeight = _jumpPower * 0.05
    end
end)

Movement:AddSection("Misc")

local infJumpOn = false
Movement:AddToggle({
    Name     = "Infinite Jump",
    Flag     = "InfiniteJump",
    Default  = false,
    Callback = function(v)
        infJumpOn = v
        notify("Infinite Jump", v and "Enabled" or "Disabled", v and "success" or "info", 2)
    end,
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

-- Fly keybind — single listener, no accumulation
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
    Callback = function(key)
        flyKey = key
        notify("Fly Keybind", "Set to " .. key.Name, "info", 2)
    end,
})

-- ── Noclip ────────────────────────────────────────────────────────────────────
local noclipOn   = false
local noclipConn = nil

local function setNoclip(state)
    noclipOn = state
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local char = lp.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        -- restore collision on all parts
        local char = lp.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

Movement:AddToggle({
    Name     = "Noclip",
    Flag     = "Noclip",
    Default  = false,
    Callback = function(v)
        setNoclip(v)
        notify("Noclip", v and "Enabled — tembus objek" or "Disabled", v and "success" or "info", 2)
    end,
})

-- restore collision after respawn
lp.CharacterAdded:Connect(function()
    if noclipOn then
        task.wait(0.5)
        setNoclip(true)
    end
end)

-- ── Anti Ragdoll ──────────────────────────────────────────────────────────────
local antiRagdollOn   = false
local antiRagdollConn = nil

local function applyAntiRagdoll(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    -- Disable breakJointsOnDeath so limbs don't fly off
    hum.BreakJointsOnDeath = false
    -- Prevent falling → ragdoll states
    antiRagdollConn = hum.StateChanged:Connect(function(_, newState)
        if not antiRagdollOn then return end
        if newState == Enum.HumanoidStateType.FallingDown
        or newState == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

Movement:AddToggle({
    Name     = "Anti Ragdoll",
    Flag     = "AntiRagdoll",
    Default  = false,
    Callback = function(v)
        antiRagdollOn = v
        if v then
            applyAntiRagdoll(lp.Character)
            notify("Anti Ragdoll", "Enabled", "success", 2)
        else
            if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn = nil end
            notify("Anti Ragdoll", "Disabled", "info", 2)
        end
    end,
})

lp.CharacterAdded:Connect(function(char)
    if antiRagdollOn then
        task.wait(0.5)
        applyAntiRagdoll(char)
    end
end)

-- ── Invisible (local) ─────────────────────────────────────────────────────────
-- Makes your own character transparent to yourself only (client-side)
local invisOn = false
local partTransparency = {}   -- saves original transparency per part

local function setInvisible(state)
    invisOn = state
    local char = lp.Character
    if not char then return end
    if state then
        partTransparency = {}
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                partTransparency[p] = p.LocalTransparencyModifier
                p.LocalTransparencyModifier = 1
            end
        end
    else
        for p, orig in pairs(partTransparency) do
            pcall(function() p.LocalTransparencyModifier = orig end)
        end
        partTransparency = {}
    end
end

Movement:AddToggle({
    Name     = "Invisible (local)",
    Flag     = "Invisible",
    Default  = false,
    Callback = function(v)
        setInvisible(v)
        notify("Invisible", v and "You are now invisible (local)" or "Visible again",
               v and "success" or "info", 2)
    end,
})

lp.CharacterAdded:Connect(function()
    if invisOn then task.wait(0.5); setInvisible(true) end
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUAL
-- ══════════════════════════════════════════════════════════════════════════════

-- ── ESP ───────────────────────────────────────────────────────────────────────
-- Uses Highlight: ikut bentuk badan (bukan kotak), tembus objek (AlwaysOnTop)
local espOn      = false
local espColor   = Color3.fromRGB(255, 255, 255)
local espOpacity = 0.15
local espData    = {}   -- [player] = {hl, bbg}

local espPlayerConn = nil
local espCharConns  = {}

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

    -- Highlight — ikut mesh karakter, AlwaysOnTop = tembus dinding
    local hl = Instance.new("Highlight")
    hl.Name                = "LeonESP"
    hl.Adornee             = char
    hl.OutlineColor        = espColor
    hl.FillColor           = espColor
    hl.OutlineTransparency = 0
    hl.FillTransparency    = 1 - espOpacity
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = char   -- auto-removed when char despawns

    -- Name tag
    local bbg = Instance.new("BillboardGui")
    bbg.Name        = "LeonESP_Name"
    bbg.Adornee     = hrp
    bbg.Size        = UDim2.new(0, 130, 0, 28)
    bbg.StudsOffset = Vector3.new(0, 3.2, 0)
    bbg.AlwaysOnTop = true
    bbg.Parent      = hrp

    local nl = Instance.new("TextLabel")
    nl.Size                   = UDim2.new(1,0,1,0)
    nl.BackgroundTransparency = 1
    nl.Text                   = player.Name
    nl.TextColor3             = espColor
    nl.Font                   = Enum.Font.GothamBold
    nl.TextSize               = 13
    nl.TextStrokeTransparency = 0.4
    nl.TextStrokeColor3       = Color3.new(0,0,0)
    nl.Parent                 = bbg

    espData[player] = { hl = hl, bbg = bbg }
end

local function rebuildESP()
    for p in pairs(espData) do removeESP(p) end
    if not espOn then return end
    for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
end

local function updateESPVisuals()
    for _, d in pairs(espData) do
        if d.hl then
            d.hl.OutlineColor    = espColor
            d.hl.FillColor       = espColor
            d.hl.FillTransparency = 1 - espOpacity
        end
        if d.bbg then
            local nl = d.bbg:FindFirstChildOfClass("TextLabel")
            if nl then nl.TextColor3 = espColor end
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
            espPlayerConn = Players.PlayerAdded:Connect(function(p)
                local c = p.CharacterAdded:Connect(function()
                    task.wait(0.5); addESP(p)
                end)
                table.insert(espCharConns, c)
                if p.Character then addESP(p) end
            end)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp then
                    local c = p.CharacterAdded:Connect(function()
                        task.wait(0.5); addESP(p)
                    end)
                    table.insert(espCharConns, c)
                end
            end
            notify("ESP", "ESP enabled", "success", 2)
        else
            if espPlayerConn then espPlayerConn:Disconnect(); espPlayerConn = nil end
            for _, c in ipairs(espCharConns) do c:Disconnect() end
            espCharConns = {}
            notify("ESP", "ESP disabled", "info", 2)
        end
    end,
})

-- ── FullBright ────────────────────────────────────────────────────────────────
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
            Lighting.Ambient       = Color3.fromRGB(178,178,178)
        else
            Lighting.Brightness    = origLighting.Brightness
            Lighting.ClockTime     = origLighting.ClockTime
            Lighting.FogEnd        = origLighting.FogEnd
            Lighting.GlobalShadows = origLighting.GlobalShadows
            Lighting.Ambient       = origLighting.Ambient
        end
        notify("FullBright", v and "Enabled" or "Disabled", v and "success" or "info", 2)
    end,
})

Visual:AddSection("Appearance")

local espColorMap = {
    White  = Color3.fromRGB(255,255,255),
    Red    = Color3.fromRGB(255,60,60),
    Green  = Color3.fromRGB(60,220,80),
    Blue   = Color3.fromRGB(60,130,255),
    Yellow = Color3.fromRGB(255,220,50),
    Cyan   = Color3.fromRGB(60,220,255),
    Pink   = Color3.fromRGB(255,100,200),
}

Visual:AddDropdown({
    Name     = "ESP Color",
    Flag     = "ESPColor",
    Options  = { "White","Red","Green","Blue","Yellow","Cyan","Pink" },
    Default  = "White",
    Callback = function(v)
        espColor = espColorMap[v] or Color3.fromRGB(255,255,255)
        updateESPVisuals()
    end,
})

Visual:AddSlider({
    Name     = "ESP Fill Opacity",
    Flag     = "ESPOpacity",
    Min      = 0,
    Max      = 100,
    Default  = 15,
    Suffix   = "%",
    Callback = function(v)
        espOpacity = v / 100
        updateESPVisuals()
    end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER
-- ══════════════════════════════════════════════════════════════════════════════
Player:AddSection("Utility")

-- Anti AFK — Heartbeat-based, reliable on all executors
local antiAfkOn   = false
local antiAfkConn = nil

Player:AddToggle({
    Name     = "Anti AFK",
    Flag     = "AntiAFK",
    Default  = false,
    Callback = function(v)
        antiAfkOn = v
        if v then
            local VU      = game:GetService("VirtualUser")
            local lastTick = tick()
            antiAfkConn = RunService.Heartbeat:Connect(function()
                if tick() - lastTick >= 60 then
                    lastTick = tick()
                    pcall(function()
                        VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    end)
                end
            end)
            notify("Anti AFK", "Enabled", "success", 2)
        else
            if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
            notify("Anti AFK", "Disabled", "info", 2)
        end
    end,
})

-- ── Teleport ──────────────────────────────────────────────────────────────────
Player:AddSection("Teleport")

local savedCFrame = nil

Player:AddButton({
    Name     = "📍  Copy My Position",
    Callback = function()
        local char = lp.Character
        if not char then notify("Teleport","No character found","error",3); return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        savedCFrame = hrp.CFrame
        local p = hrp.Position
        pcall(function()
            setclipboard(string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z))
        end)
        notify("Teleport",
            string.format("Saved: %.0f, %.0f, %.0f", p.X, p.Y, p.Z),
            "success", 3)
    end,
})

Player:AddButton({
    Name     = "🚀  Go to Saved Position",
    Callback = function()
        if not savedCFrame then
            notify("Teleport", "No position saved yet", "warn", 3)
            return
        end
        local char = lp.Character
        if not char then notify("Teleport","No character","error",3); return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local wasFlying = Fly.Enabled
        if wasFlying then Fly:Disable() end
        hrp.CFrame = savedCFrame
        task.wait(0.1)
        if wasFlying then Fly:Enable() end
        notify("Teleport", "Teleported to saved position", "success", 2)
    end,
})

-- ── Teleport to Player ────────────────────────────────────────────────────────
-- Dropdown shows all players in server; refreshes on open
local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            table.insert(names, p.Name)
        end
    end
    return #names > 0 and names or {"(no players)"}
end

local tpPlayerSelect = Player:AddDropdown({
    Name    = "Select Player",
    Options = getPlayerNames(),
    Default = getPlayerNames()[1],
})

Player:AddButton({
    Name     = "🔄  Refresh Player List",
    Callback = function()
        tpPlayerSelect:SetOptions(getPlayerNames())
        notify("Teleport", "Player list refreshed", "info", 2)
    end,
})

Player:AddButton({
    Name     = "⚡  Teleport to Player",
    Callback = function()
        local targetName = tpPlayerSelect:Get()
        if targetName == "(no players)" then
            notify("Teleport", "No player selected", "warn", 2)
            return
        end
        local target = Players:FindFirstChild(targetName)
        if not target then
            notify("Teleport", targetName .. " not found", "error", 3)
            return
        end
        local targetChar = target.Character
        if not targetChar then
            notify("Teleport", targetName .. " has no character", "warn", 3)
            return
        end
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHRP then return end

        local myChar = lp.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local wasFlying = Fly.Enabled
        if wasFlying then Fly:Disable() end
        -- offset slightly so we don't clip inside them
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
        task.wait(0.1)
        if wasFlying then Fly:Enable() end
        notify("Teleport", "Teleported to " .. targetName, "success", 2)
    end,
})

-- ── Server ────────────────────────────────────────────────────────────────────
Player:AddSection("Server")

Player:AddButton({
    Name     = "Rejoin Server",
    Callback = function()
        notify("Rejoin", "Rejoining...", "warn", 2)
        task.wait(1.5)
        game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
    end,
})

Player:AddButton({
    Name     = "Copy Player ID",
    Callback = function()
        pcall(function() setclipboard(tostring(lp.UserId)) end)
        notify("Copied", "UserID: " .. tostring(lp.UserId), "success", 2)
    end,
})

Player:AddSection("Stats")
Player:AddLabel({ Text="Username: " .. lp.Name,             Color=Color3.fromRGB(100,100,100) })
Player:AddLabel({ Text="User ID: "  .. tostring(lp.UserId), Color=Color3.fromRGB(100,100,100) })

-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS
-- ══════════════════════════════════════════════════════════════════════════════
Settings:AddSection("Interface")

Settings:AddToggle({
    Name     = "Show Notifications",
    Flag     = "ShowNotifs",
    Default  = true,
    Callback = function(v)
        -- stored but enforcement would need wrapping notify()
        -- here we just confirm it toggled
        Library:Notify({ Title="Notifications", Text=v and "Enabled" or "Disabled",
                         Type=v and "success" or "info", Duration=2 })
    end,
})

Settings:AddDropdown({
    Name     = "Theme",
    Flag     = "Theme",
    Options  = { "Dark", "Midnight", "Slate" },
    Default  = "Dark",
    Callback = function(v)
        notify("Theme", v .. " selected (restart to apply)", "info", 3)
    end,
})

-- ── Config ────────────────────────────────────────────────────────────────────
Settings:AddSection("Config")

-- TextInput untuk nama config custom dari user
local configNameInput = Settings:AddTextInput({
    Name        = "Config Name",
    Placeholder = "e.g. my-config",
    Default     = "default",
    Callback    = function(v)
        -- live update label when user presses Enter
    end,
})

local function getConfigName()
    local v = configNameInput:Get()
    return (v and v ~= "") and v or "default"
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
        local name = getConfigName()
        local ok = ConfigManager:Save(name)
        notify("Config", ok and ("Saved: "..name) or "Save failed",
               ok and "success" or "error", 3)
        configSelect:SetOptions(getConfigList())
        if ok then configSelect:Set(name) end
    end,
})

Settings:AddButton({
    Name     = "📂  Load Config",
    Callback = function()
        local sel = configSelect:Get()
        if sel == "(none)" then notify("Config","No config selected","warn",2); return end
        local ok = ConfigManager:Load(sel)
        notify("Config", ok and ("Loaded: "..sel) or "Load failed: "..sel,
               ok and "success" or "error", 3)
    end,
})

Settings:AddButton({
    Name     = "🗑  Delete Config",
    Callback = function()
        local sel = configSelect:Get()
        if sel == "(none)" then return end
        local ok = ConfigManager:Delete(sel)
        notify("Config", ok and ("Deleted: "..sel) or "Delete failed",
               ok and "info" or "error", 3)
        configSelect:SetOptions(getConfigList())
    end,
})

Settings:AddButton({
    Name     = "⭐  Set as Default",
    Callback = function()
        local sel = configSelect:Get()
        if sel == "(none)" then return end
        local ok = ConfigManager:SetDefault(sel)
        notify("Config", ok and (sel.." is now default") or "SetDefault failed",
               ok and "success" or "error", 3)
    end,
})

Settings:AddSection("About")
Settings:AddLabel({
    Text  = "Leon X  ·  v4.4",
    Color = Color3.fromRGB(70,70,70),
    Align = Enum.TextXAlignment.Center,
})

-- ── Auto-load default config — MUST be last ───────────────────────────────────
local loaded = ConfigManager:AutoLoad()
if loaded ~= false then
    task.delay(1, function()
        notify("Leon X", "Config loaded. Welcome!", "success", 3)
    end)
end
