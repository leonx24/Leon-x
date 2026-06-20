-- Leon X | Rejoin
-- Rejoins the current game server

local Rejoin = {}
Rejoin.Name = "Rejoin"

local lp = game:GetService("Players").LocalPlayer

function Rejoin:Execute()
    local TeleportService = game:GetService("TeleportService")
    local _allowTP = _G._LeonX_AllowTeleport or function() end
    _allowTP(true)
    TeleportService:Teleport(game.PlaceId, lp)
    _allowTP(false)
end

return Rejoin
