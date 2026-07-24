-- Leon X | Mobile Quick-Toggle Overlay
-- Creates a floating, draggable button for touch devices to toggle main window visibility

local MobileOverlay = {}
MobileOverlay.Name    = "MobileOverlay"
MobileOverlay.Enabled = false

local UIS        = game:GetService("UserInputService")
local Players    = game:GetService("Players")
local lp         = Players.LocalPlayer

local guiInstance = nil
local buttonInst  = nil
local connBegan   = nil
local connChanged = nil
local toggleCallback = nil

function MobileOverlay:SetCallback(cb)
    toggleCallback = cb
end

function MobileOverlay:Enable()
    if self.Enabled then return end
    self.Enabled = true

    pcall(function()
        if guiInstance then guiInstance:Destroy() end

        local playerGui = lp:WaitForChild("PlayerGui")

        guiInstance = Instance.new("ScreenGui")
        guiInstance.Name = "LeonXMobileOverlay"
        guiInstance.ResetOnSpawn = false
        guiInstance.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        guiInstance.DisplayOrder = 999
        guiInstance.Parent = playerGui

        buttonInst = Instance.new("TextButton")
        buttonInst.Name = "OverlayBtn"
        buttonInst.Size = UDim2.fromOffset(50, 50)
        buttonInst.Position = UDim2.new(0, 20, 0.5, -25)
        buttonInst.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        buttonInst.BorderSizePixel = 0
        buttonInst.Text = "LX"
        buttonInst.Font = Enum.Font.GothamBold
        buttonInst.TextSize = 18
        buttonInst.TextColor3 = Color3.fromRGB(130, 155, 210)
        buttonInst.AutoButtonColor = false
        buttonInst.ZIndex = 10
        buttonInst.Parent = guiInstance

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = buttonInst

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(130, 155, 210)
        stroke.Thickness = 1.5
        stroke.Parent = buttonInst

        -- Dragging & Tapping logic
        local dragging = false
        local dragStart = nil
        local startPos = nil
        local didMove = false

        connBegan = buttonInst.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                didMove = false
                dragStart = input.Position
                startPos = buttonInst.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if not didMove and toggleCallback then
                            pcall(toggleCallback)
                        end
                    end
                end)
            end
        end)

        connChanged = UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
                    didMove = true
                end
                buttonInst.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end)
end

function MobileOverlay:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    pcall(function()
        if connBegan then connBegan:Disconnect(); connBegan = nil end
        if connChanged then connChanged:Disconnect(); connChanged = nil end
        if guiInstance then guiInstance:Destroy(); guiInstance = nil end
        buttonInst = nil
    end)
end

function MobileOverlay:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

return MobileOverlay
