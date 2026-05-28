-- ui/library.lua
-- Leon X Modern UI

local Library = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
	playerGui:FindFirstChild("LeonX"):Destroy()
end)

-- SCREEN GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LeonX"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

-- MAIN
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 650, 0, 400)
Main.Position = UDim2.new(0.5, -325, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(15,15,15)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(28,28,28)
MainStroke.Parent = Main

-- TOPBAR
local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1,0,0,50)
Topbar.BackgroundTransparency = 1
Topbar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,1,0)
Title.BackgroundTransparency = 1
Title.Text = "Leon X"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.Parent = Topbar

-- SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,170,1,-50)
Sidebar.Position = UDim2.new(0,0,0,50)
Sidebar.BackgroundColor3 = Color3.fromRGB(18,18,18)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SideStroke = Instance.new("UIStroke")
SideStroke.Color = Color3.fromRGB(26,26,26)
SideStroke.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0,8)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = Sidebar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0,12)
SidePadding.Parent = Sidebar

-- CONTENT
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-170,1,-50)
Content.Position = UDim2.new(0,170,0,50)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Pages = {}

-- MINIMIZE
local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.new(0,30,0,30)
Minimize.Position = UDim2.new(1,-75,0,10)
Minimize.BackgroundColor3 = Color3.fromRGB(24,24,24)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(255,255,255)
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 18
Minimize.Parent = Main

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1,0)
MinCorner.Parent = Minimize

-- CLOSE
local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0,30,0,30)
Close.Position = UDim2.new(1,-40,0,10)
Close.BackgroundColor3 = Color3.fromRGB(45,20,20)
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255,255,255)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 14
Close.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1,0)
CloseCorner.Parent = Close

-- FLOAT BUTTON
local Float = Instance.new("TextButton")
Float.Size = UDim2.new(0,55,0,55)
Float.Position = UDim2.new(0,20,0.5,-27)
Float.BackgroundColor3 = Color3.fromRGB(18,18,18)
Float.Text = "LX"
Float.TextColor3 = Color3.fromRGB(255,255,255)
Float.Font = Enum.Font.GothamBold
Float.TextSize = 20
Float.Visible = false
Float.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1,0)
FloatCorner.Parent = Float

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(35,35,35)
FloatStroke.Parent = Float

-- DRAG MAIN
local dragging = false
local dragStart
local startPos

Topbar.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then

		dragging = true
		dragStart = input.Position
		startPos = Main.Position
	end
end)

UIS.InputChanged:Connect(function(input)

	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then

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

-- RESIZE HANDLE

local ResizeCorner = Instance.new("Frame")
ResizeCorner.Size = UDim2.new(0,18,0,18)
ResizeCorner.AnchorPoint = Vector2.new(1,1)
ResizeCorner.Position = UDim2.new(1,-6,1,-6)
ResizeCorner.BackgroundTransparency = 1
ResizeCorner.ZIndex = 50
ResizeCorner.Parent = Main

local ResizeButton = Instance.new("TextButton")
ResizeButton.Size = UDim2.new(1,0,1,0)
ResizeButton.BackgroundTransparency = 1
ResizeButton.Text = ""
ResizeButton.AutoButtonColor = false
ResizeButton.Parent = ResizeCorner

local ResizeIcon = Instance.new("TextLabel")
ResizeIcon.Size = UDim2.new(1,0,1,0)
ResizeIcon.BackgroundTransparency = 1
ResizeIcon.Text = "◢"
ResizeIcon.TextColor3 = Color3.fromRGB(255,255,255)
ResizeIcon.TextTransparency = 0.35
ResizeIcon.Font = Enum.Font.GothamBold
ResizeIcon.TextSize = 14
ResizeIcon.TextXAlignment = Enum.TextXAlignment.Right
ResizeIcon.TextYAlignment = Enum.TextYAlignment.Bottom
ResizeIcon.Parent = ResizeCorner

ResizeButton.MouseEnter:Connect(function()

	TweenService:Create(
		ResizeIcon,
		TweenInfo.new(0.15),
		{
			TextTransparency = 0
		}
	):Play()
end)

ResizeButton.MouseLeave:Connect(function()

	TweenService:Create(
		ResizeIcon,
		TweenInfo.new(0.15),
		{
			TextTransparency = 0.35
		}
	):Play()
end)

local resizing = false
local resizeStart
local startSize

ResizeButton.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then

		resizing = true
		resizeStart = input.Position
		startSize = Main.Size
	end
end)

UIS.InputChanged:Connect(function(input)

	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then

		local delta = input.Position - resizeStart

		Main.Size = UDim2.new(
			0,
			math.clamp(startSize.X.Offset + delta.X, 520, 1200),

			0,
			math.clamp(startSize.Y.Offset + delta.Y, 320, 800)
		)
	end
end)

UIS.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = false
	end
end)

-- FLOAT DRAG
local draggingFloat = false
local dragFloatStart
local floatStartPos
local moved = false

Float.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then

		draggingFloat = true
		moved = false

		dragFloatStart = input.Position
		floatStartPos = Float.Position
	end
end)

UIS.InputChanged:Connect(function(input)

	if draggingFloat and input.UserInputType == Enum.UserInputType.MouseMovement then

		local delta = input.Position - dragFloatStart

		if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
			moved = true
		end

		Float.Position = UDim2.new(
			floatStartPos.X.Scale,
			floatStartPos.X.Offset + delta.X,

			floatStartPos.Y.Scale,
			floatStartPos.Y.Offset + delta.Y
		)
	end
end)

Float.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then

		draggingFloat = false

		if not moved then
			Main.Visible = true
			Float.Visible = false
		end

		task.wait()
		moved = false
	end
end)

-- MINIMIZE
Minimize.MouseButton1Click:Connect(function()

	Main.Visible = false
	Float.Visible = true
end)

-- CLOSE
Close.MouseButton1Click:Connect(function()

	ScreenGui:Destroy()
end)

-- CREATE TAB
function Library:CreateTab(name)

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1,-20,0,40)
	Button.BackgroundColor3 = Color3.fromRGB(22,22,22)
	Button.Text = name
	Button.TextColor3 = Color3.fromRGB(255,255,255)
	Button.Font = Enum.Font.GothamMedium
	Button.TextSize = 14
	Button.AutoButtonColor = false
	Button.Parent = Sidebar

	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(0,10)
	ButtonCorner.Parent = Button

	local ButtonStroke = Instance.new("UIStroke")
	ButtonStroke.Color = Color3.fromRGB(32,32,32)
	ButtonStroke.Parent = Button

	local Page = Instance.new("ScrollingFrame")
	Page.Size = UDim2.new(1,0,1,0)
	Page.CanvasSize = UDim2.new(0,0,0,0)
	Page.ScrollBarThickness = 0
	Page.BackgroundTransparency = 1
	Page.Visible = false
	Page.Parent = Content

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0,10)
	Layout.Parent = Page

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0,15)
	Padding.PaddingLeft = UDim.new(0,15)
	Padding.PaddingRight = UDim.new(0,15)
	Padding.Parent = Page

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()

		Page.CanvasSize = UDim2.new(
			0,
			0,
			0,
			Layout.AbsoluteContentSize.Y + 20
		)
	end)

	Pages[name] = Page

	if #Content:GetChildren() == 1 then
		Page.Visible = true
	end

	Button.MouseButton1Click:Connect(function()

		for _, v in pairs(Pages) do
			v.Visible = false
		end

		Page.Visible = true
	end)

	return Page
end

-- CREATE TOGGLE
function Library:CreateToggle(parent, text, callback)

	local Toggle = Instance.new("TextButton")
	Toggle.Size = UDim2.new(1,0,0,45)
	Toggle.BackgroundColor3 = Color3.fromRGB(20,20,20)
	Toggle.Text = ""
	Toggle.AutoButtonColor = false
	Toggle.Parent = parent

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(0,12)
	ToggleCorner.Parent = Toggle

	local ToggleStroke = Instance.new("UIStroke")
	ToggleStroke.Color = Color3.fromRGB(30,30,30)
	ToggleStroke.Parent = Toggle

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1,-70,1,0)
	Label.Position = UDim2.new(0,15,0,0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = Color3.fromRGB(255,255,255)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Toggle

	local Switch = Instance.new("Frame")
	Switch.Size = UDim2.new(0,40,0,20)
	Switch.Position = UDim2.new(1,-55,0.5,-10)
	Switch.BackgroundColor3 = Color3.fromRGB(40,40,40)
	Switch.Parent = Toggle

	local SwitchCorner = Instance.new("UICorner")
	SwitchCorner.CornerRadius = UDim.new(1,0)
	SwitchCorner.Parent = Switch

	local Circle = Instance.new("Frame")
	Circle.Size = UDim2.new(0,16,0,16)
	Circle.Position = UDim2.new(0,2,0.5,-8)
	Circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
	Circle.Parent = Switch

	local CircleCorner = Instance.new("UICorner")
	CircleCorner.CornerRadius = UDim.new(1,0)
	CircleCorner.Parent = Circle

	local Enabled = false

	Toggle.MouseButton1Click:Connect(function()

		Enabled = not Enabled

		if Enabled then

			TweenService:Create(
				Circle,
				TweenInfo.new(0.2),
				{
					Position = UDim2.new(1,-18,0.5,-8)
				}
			):Play()

			TweenService:Create(
				Switch,
				TweenInfo.new(0.2),
				{
					BackgroundColor3 = Color3.fromRGB(255,255,255)
				}
			):Play()

		else

			TweenService:Create(
				Circle,
				TweenInfo.new(0.2),
				{
					Position = UDim2.new(0,2,0.5,-8)
				}
			):Play()

			TweenService:Create(
				Switch,
				TweenInfo.new(0.2),
				{
					BackgroundColor3 = Color3.fromRGB(40,40,40)
				}
			):Play()
		end

		if callback then
			callback(Enabled)
		end
	end)

	return Toggle
end

return Library