local Toggle = require(script.Parent.components.toggle)

local Library = {}

local Players = game:GetService("Players")

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

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,170,1,-50)
Sidebar.Position = UDim2.new(0,0,0,50)
Sidebar.BackgroundColor3 = Color3.fromRGB(18,18,18)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0,8)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
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
