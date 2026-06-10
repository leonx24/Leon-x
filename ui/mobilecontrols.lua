-- Leon X | Mobile Controls
-- Floating buttons for Fly up/down on mobile devices

local MobileControls = {}
MobileControls.Enabled = false

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- UI elements
local gui = nil
local upBtn = nil
local downBtn = nil

-- State
local pressingUp = false
local pressingDown = false

local function createUI()
    if not isMobile then return end
    if gui and gui.Parent then return gui end

    -- Cleanup old GUI
    pcall(function()
        if gui then gui:Destroy() end
    end)

    local pg = lp:WaitForChild("PlayerGui")

    gui = Instance.new("ScreenGui")
    gui.Name = "MobileControls"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true
    gui.Parent = pg

    -- Container frame (bottom-right corner)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 70, 0, 160)
    container.Position = UDim2.new(1, -80, 1, -180)
    container.BackgroundTransparency = 1
    container.Parent = gui

    local function mkBtn(icon, yPos, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 60, 0, 60)
        btn.Position = UDim2.new(0, 5, 0, yPos)
        btn.BackgroundColor3 = color
        btn.Text = icon
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 24
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.Parent = container

        -- Rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = btn

        -- Shadow/stroke
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 0, 0)
        stroke.Thickness = 2
        stroke.Transparency = 0.5
        stroke.Parent = btn

        return btn
    end

    -- Up button (↑)
    upBtn = mkBtn("▲", 5, Color3.fromRGB(80, 150, 255))

    -- Down button (↓)
    downBtn = mkBtn("▼", 85, Color3.fromRGB(255, 100, 100))

    return gui
end

function MobileControls:Enable()
    if not isMobile then return end
    self.Enabled = true

    createUI()

    if not upBtn or not downBtn then return end

    -- Up button handlers
    upBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            pressingUp = true
            upBtn.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        end
    end)

    upBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            pressingUp = false
            upBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
        end
    end)

    -- Down button handlers
    downBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            pressingDown = true
            downBtn.BackgroundColor3 = Color3.fromRGB(255, 120, 120)
        end
    end)

    downBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            pressingDown = false
            downBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)

    if gui then gui.Enabled = true end
end

function MobileControls:Disable()
    self.Enabled = false
    pressingUp = false
    pressingDown = false
    if gui then gui.Enabled = false end
end

function MobileControls:IsPressingUp()
    return pressingUp
end

function MobileControls:IsPressingDown()
    return pressingDown
end

function MobileControls:GetVerticalInput()
    if pressingUp then return 1 end
    if pressingDown then return -1 end
    return 0
end

return MobileControls
