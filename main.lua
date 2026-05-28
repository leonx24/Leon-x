local Library = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/affaririzkyf/Leon-x/main/ui/library.lua"))()

local Movement = Library:CreateTab("Movement")
local Visual = Library:CreateTab("Visual")
local Player = Library:CreateTab("Player")

Movement:AddToggle({
Name = "Fly",


Callback = function(v)
	print("Fly:", v)
end


})

Movement:AddToggle({
Name = "Speed",


Callback = function(v)
	print("Speed:", v)
end


})

Visual:AddToggle({
Name = "ESP",


Callback = function(v)
	print("ESP:", v)
end


})

Visual:AddToggle({
Name = "FullBright",


Callback = function(v)
	print("FullBright:", v)
end


})

Player:AddToggle({
Name = "Anti AFK",


Callback = function(v)
	print("Anti AFK:", v)
end

})
