local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/ui/library.lua"
))()

print("Leon X Loaded")

-- Tabs
local Movement = Library:CreateTab("Movement")
local Visual = Library:CreateTab("Visual")
local Player = Library:CreateTab("Player")

-- Toggles
Library:CreateToggle(Movement, "Fly", function(v)
	print("Fly:", v)

	if v then
		loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/fly.lua"
		))()
	end
end)

Library:CreateToggle(Movement, "Speed", function(v)
	print("Speed:", v)

	if v then
		loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/speed.lua"
		))()
	end
end)

Library:CreateToggle(Visual, "ESP", function(v)
	print("ESP:", v)

	if v then
		loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/esp.lua"
		))()
	end
end)

Library:CreateToggle(Visual, "FullBright", function(v)
	print("FullBright:", v)

	if v then
		loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/fullbright.lua"
		))()
	end
end)

Library:CreateToggle(Player, "Anti AFK", function(v)
	print("Anti AFK:", v)

	if v then
		loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/antiafk.lua"
		))()
	end
end)