local TweenService = game:GetService("TweenService")

local Animations = {}

function Animations:Tween(object, time, properties)


local tween = TweenService:Create(
	object,
	TweenInfo.new(
		time,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	),
	properties
)

tween:Play()

return tween


end

return Animations
