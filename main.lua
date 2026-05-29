-- Leon X | main.lua

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/leonx24/Leon-x/main/ui/library.lua"
))()

local Fly = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/leonx24/Leon-x/main/modules/movements/fly.lua"
))()

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local Movement = Library:CreateTab("Movement")
local Visual   = Library:CreateTab("Visual")
local Player   = Library:CreateTab("Player")
local Settings = Library:CreateTab("Settings")

-- ── Movement ──────────────────────────────────────────────────────────────────
Movement:AddSection("Locomotion")

local flyToggle = Movement:AddToggle({
    Name    = "Fly",
    Default = false,
    Callback = function(v)
        if v then Fly:Enable() else Fly:Disable() end
    end,
})

Movement:AddSlider({
    Name    = "Fly Speed",
    Min     = 10,
    Max     = 300,
    Default = 60,
    Suffix  = " stud/s",
    Callback = function(v)
        Fly:SetSpeed(v)
    end,
})

Movement:AddToggle({
    Name    = "Speed Hack",
    Default = false,
    Callback = function(v)
        local lp  = game.Players.LocalPlayer
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = v and 60 or 16
        end
    end,
})

Movement:AddSlider({
    Name    = "Walk Speed",
    Min     = 16,
    Max     = 250,
    Default = 16,
    Suffix  = " stud/s",
    Callback = function(v)
        local lp   = game.Players.LocalPlayer
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

Movement:AddSlider({
    Name    = "Jump Power",
    Min     = 50,
    Max     = 500,
    Default = 50,
    Callback = function(v)
        local lp   = game.Players.LocalPlayer
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end,
})

Movement:AddSection("Misc")

Movement:AddToggle({
    Name    = "Infinite Jump",
    Default = false,
    Callback = function(v)
        _G.InfJump = v
    end,
})

-- infinite jump listener
game:GetService("UserInputService").JumpRequest:Connect(function()
    if _G.InfJump then
        local lp   = game.Players.LocalPlayer
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

Movement:AddKeybind({
    Name    = "Fly Keybind",
    Default = Enum.KeyCode.F,
    Callback = function(key)
        -- rebind: next press of this key toggles fly
        game:GetService("UserInputService").InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.KeyCode == key then
                local newState = not Fly.Enabled
                flyToggle:Set(newState)
                if newState then Fly:Enable() else Fly:Disable() end
            end
        end)
    end,
})

-- ── Visual ────────────────────────────────────────────────────────────────────
Visual:AddSection("Rendering")

Visual:AddToggle({
    Name    = "ESP",
    Default = false,
    Callback = function(v) print("ESP:", v) end,
})

Visual:AddToggle({
    Name    = "FullBright",
    Default = false,
    Callback = function(v)
        local Lighting = game:GetService("Lighting")
        if v then
            Lighting.Brightness    = 2
            Lighting.ClockTime     = 14
            Lighting.FogEnd        = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient       = Color3.fromRGB(178,178,178)
        else
            Lighting.Brightness    = 1
            Lighting.ClockTime     = 14
            Lighting.FogEnd        = 100000
            Lighting.GlobalShadows = true
            Lighting.Ambient       = Color3.fromRGB(70,70,70)
        end
    end,
})

Visual:AddSection("Appearance")

Visual:AddDropdown({
    Name    = "ESP Color",
    Options = { "White", "Red", "Green", "Blue", "Yellow" },
    Default = "White",
    Callback = function(v) print("ESP Color:", v) end,
})

Visual:AddSlider({
    Name    = "ESP Opacity",
    Min     = 0,
    Max     = 100,
    Default = 80,
    Suffix  = "%",
    Callback = function(v) print("ESP Opacity:", v) end,
})

Visual:AddColorPicker({
    Name    = "Chams Color",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(c) print("Chams:", c) end,
})

-- ── Player ────────────────────────────────────────────────────────────────────
Player:AddSection("Utility")

Player:AddToggle({
    Name    = "Anti AFK",
    Default = false,
    Callback = function(v)
        _G.AntiAFK = v
        if v then
            _G.AntiAFKConn = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(.1)
                game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        else
            if _G.AntiAFKConn then
                _G.AntiAFKConn:Disconnect()
                _G.AntiAFKConn = nil
            end
        end
    end,
})

Player:AddButton({
    Name     = "Rejoin Server",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
    end,
})

Player:AddButton({
    Name     = "Copy Player ID",
    Callback = function()
        setclipboard(tostring(game.Players.LocalPlayer.UserId))
        print("Copied:", game.Players.LocalPlayer.UserId)
    end,
})

Player:AddSection("Stats")

Player:AddLabel({
    Text  = "Username: " .. game.Players.LocalPlayer.Name,
    Color = Color3.fromRGB(100,100,100),
})

Player:AddLabel({
    Text  = "User ID: " .. tostring(game.Players.LocalPlayer.UserId),
    Color = Color3.fromRGB(100,100,100),
})

-- ── Settings ──────────────────────────────────────────────────────────────────
Settings:AddSection("Interface")

Settings:AddToggle({
    Name    = "Show Notifications",
    Default = true,
    Callback = function(v) print("Notifs:", v) end,
})

Settings:AddDropdown({
    Name    = "Theme",
    Options = { "Dark", "Midnight", "Slate" },
    Default = "Dark",
    Callback = function(v) print("Theme:", v) end,
})

Settings:AddSection("About")

Settings:AddLabel({
    Text  = "Leon X  ·  v4.1",
    Color = Color3.fromRGB(70,70,70),
    Align = Enum.TextXAlignment.Center,
})
