local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/ui/library.lua"
))()

local Movement = Library:CreateTab("Movement")
local Visual = Library:CreateTab("Visual")
local Player = Library:CreateTab("Player")

Library:CreateToggle(Movement, "Fly", function(v)
	print(v)
end)

Library:CreateToggle(Movement, "Speed", function(v)
	print(v)
end)

Library:CreateToggle(Visual, "ESP", function(v)
	print(v)
end)

Library:CreateToggle(Visual, "FullBright", function(v)
	print(v)
end)

Library:CreateToggle(Player, "Anti AFK", function(v)
	print(v)
end)