-- ui/library.lua
-- Leon X UI Library

local Library = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
	playerGui:FindFirstChild("LeonX"):Destroy()
end)

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LeonX"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- Main Window
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 500, 0, 300)
Main.Position = UDim2.new(0.5, -250, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(20,20,20)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,12)
MainCorner.Parent = Main

-- TopBar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1,0,0,35)
TopBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0,12)
TopCorner.Parent = TopBar

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-80,1,0)
Title.Position = UDim2.new(0,10,0,0)
Title.BackgroundTransparency = 1
Title.Text = "Leon X"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize
local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.new(0,30,0,30)
Minimize.Position = UDim2.new(1,-70,0,2)
Minimize.BackgroundColor3 = Color3.fromRGB(45,45,45)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(255,255,255)
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 18
Minimize.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0,8)
MinCorner.Parent = Minimize

-- Close
local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0,30,0,30)
Close.Position = UDim2.new(1,-35,0,2)
Close.BackgroundColor3 = Color3.fromRGB(80,25,25)
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255,255,255)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 14
Close.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0,8)
CloseCorner.Parent = Close

-- Tabs
local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(0,120,1,-35)
Tabs.Position = UDim2.new(0,0,0,35)
Tabs.BackgroundColor3 = Color3.fromRGB(25,25,25)
Tabs.BorderSizePixel = 0
Tabs.Parent = Main

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-120,1,-35)
Content.Position = UDim2.new(0,120,0,35)
Content.BackgroundColor3 = Color3.fromRGB(15,15,15)
Content.BorderSizePixel = 0
Content.Parent = Main

-- LX Floating Button
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0,50,0,50)
OpenButton.Position = UDim2.new(0,20,0.5,-25)
OpenButton.BackgroundColor3 = Color3.fromRGB(25,25,25)
OpenButton.Text = "LX"
OpenButton.TextColor3 = Color3.fromRGB(255,255,255)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 18
OpenButton.Visible = false
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1,0)
OpenCorner.Parent = OpenButton

-- Minimize Logic
Minimize.MouseButton1Click:Connect(function()
	Main.Visible = false
	OpenButton.Visible = true
end)

-- Close Logic
Close.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

-- Main Dragging
local dragging = false
local dragInput
local dragStart
local startPos

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
	end
end)

TopBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart

		Main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- LX Dragging + Click Detection
local draggingLX = false
local dragInputLX
local dragStartLX
local startPosLX
local moved = false

OpenButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingLX = true
		moved = false

		dragStartLX = input.Position
		startPosLX = OpenButton.Position
	end
end)

OpenButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInputLX = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInputLX and draggingLX then
		local delta = input.Position - dragStartLX

		-- Detect drag movement
		if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
			moved = true
		end

		OpenButton.Position = UDim2.new(
			startPosLX.X.Scale,
			startPosLX.X.Offset + delta.X,
			startPosLX.Y.Scale,
			startPosLX.Y.Offset + delta.Y
		)
	end
end)

OpenButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingLX = false

		-- ONLY OPEN IF NOT DRAGGED
		if not moved then
			Main.Visible = true
			OpenButton.Visible = false
		end

		task.wait()
		moved = false
	end
end)

-- Create Tab
function Library:CreateTab(name)
	local count = #Tabs:GetChildren()

	local TabButton = Instance.new("TextButton")
	TabButton.Size = UDim2.new(1,-10,0,35)
	TabButton.Position = UDim2.new(0,5,0,(count-1)*40)
	TabButton.BackgroundColor3 = Color3.fromRGB(35,35,35)
	TabButton.Text = name
	TabButton.TextColor3 = Color3.fromRGB(255,255,255)
	TabButton.Font = Enum.Font.Gotham
	TabButton.TextSize = 14
	TabButton.Parent = Tabs

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,8)
	Corner.Parent = TabButton

	return TabButton
end

function Library:CreateToggle(parent, text, callback)
	local Toggle = Instance.new("TextButton")
	Toggle.Size = UDim2.new(1,-10,0,35)
	Toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
	Toggle.Text = text .. " : OFF"
	Toggle.TextColor3 = Color3.fromRGB(255,255,255)
	Toggle.Font = Enum.Font.Gotham
	Toggle.TextSize = 14
	Toggle.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,8)
	Corner.Parent = Toggle

	local enabled = false

	Toggle.MouseButton1Click:Connect(function()
		enabled = not enabled

		if enabled then
			Toggle.Text = text .. " : ON"
			Toggle.BackgroundColor3 = Color3.fromRGB(50,120,50)
		else
			Toggle.Text = text .. " : OFF"
			Toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
		end

		if callback then
			callback(enabled)
		end
	end)

	return Toggle
end

return Library