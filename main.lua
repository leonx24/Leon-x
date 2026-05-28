loadstring(game:HttpGet("https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/fly.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/esp.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/antiafk.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/fullbright.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/infinitejump.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/rejoin.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/modules/speed.lua"))()

local Library = loadstring(game:HttpGet("RAW_UI_LINK"))()

local Movement = Library:CreateTab("Movement")

Library:CreateToggle(Movement, "Fly", function(v)
	print("Fly:", v)
end)

Library:CreateToggle(Movement, "Speed", function(v)
	print("Speed:", v)
end)