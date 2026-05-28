local Library = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
playerGui:FindFirstChild("LeonX"):Destroy()
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LeonX"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,650,0,400)
Main.Position = UDim2.new(0.5,-325,0.5,-200)
Main.BackgroundColor3 = Color3.fromRGB(15,15,15)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(28,28,28)
MainStroke.Parent = Main

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

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-170,1,-50)
Content.Position = UDim2.new(0,170,0,50)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Pages = {}

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

local Toggle = {}

function Toggle:Create(parent, data)


local callback = data.Callback or function() end

local ToggleFrame = Instance.new("TextButton")
ToggleFrame.Size = UDim2.new(1,0,0,45)
ToggleFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
ToggleFrame.Text = ""
ToggleFrame.AutoButtonColor = false
ToggleFrame.Parent = parent

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0,12)
Corner.Parent = ToggleFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(30,30,30)
Stroke.Parent = ToggleFrame

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1,-70,1,0)
Label.Position = UDim2.new(0,15,0,0)
Label.BackgroundTransparency = 1
Label.Text = data.Name or "Toggle"
Label.TextColor3 = Color3.fromRGB(255,255,255)
Label.Font = Enum.Font.Gotham
Label.TextSize = 14
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.Parent = ToggleFrame

local Switch = Instance.new("Frame")
Switch.Size = UDim2.new(0,40,0,20)
Switch.Position = UDim2.new(1,-55,0.5,-10)
Switch.BackgroundColor3 = Color3.fromRGB(40,40,40)
Switch.Parent = ToggleFrame

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

ToggleFrame.MouseButton1Click:Connect(function()

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

	callback(Enabled)
end)

return ToggleFrame


end

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

Pages[name] = {
	Page = Page,
	Button = Button
}

if table.getn(Content:GetChildren()) == 1 then
	Page.Visible = true
end

Button.MouseButton1Click:Connect(function()

	for _, v in pairs(Pages) do
		v.Page.Visible = false
		v.Button.BackgroundColor3 = Color3.fromRGB(22,22,22)
	end

	Page.Visible = true
	Button.BackgroundColor3 = Color3.fromRGB(30,30,30)
end)

local Tab = {}

function Tab:AddToggle(data)
	return Toggle:Create(Page, data)
end

return Tab


end

return Library
