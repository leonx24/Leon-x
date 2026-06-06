-- Leon X | Rejoin
-- Rejoins the current game server

local Rejoin = {}
Rejoin.Name = "Rejoin"

local lp = game:GetService("Players").LocalPlayer

function Rejoin:Execute()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, lp)
end

return Rejoin
