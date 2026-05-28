local Animations = require(script.Parent.Parent.Parent.core.animations)

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

		Animations:Tween(Circle, 0.2, {
			Position = UDim2.new(1,-18,0.5,-8)
		})

		Animations:Tween(Switch, 0.2, {
			BackgroundColor3 = Color3.fromRGB(255,255,255)
		})

	else

		Animations:Tween(Circle, 0.2, {
			Position = UDim2.new(0,2,0.5,-8)
		})

		Animations:Tween(Switch, 0.2, {
			BackgroundColor3 = Color3.fromRGB(40,40,40)
		})
	end

	callback(Enabled)
end)

return ToggleFrame

end

return Toggle
