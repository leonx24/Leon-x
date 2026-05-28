local Services = require(script.Parent.services)

local Animations = {}

function Animations:Tween(object, time, properties)
    local tween = Services.TweenService:Create(
        object,
        TweenInfo.new(time),
        properties
    )

    tween:Play()

    return tween
end

return Animations
