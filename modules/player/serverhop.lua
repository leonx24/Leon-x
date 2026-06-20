-- Leon X | Server Hop
-- Teleports to a different server of the same game (different JobId)

local ServerHop = {}
ServerHop.Name = "ServerHop"

local HttpService     = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local lp              = Players.LocalPlayer

local _allowTP = _G._LeonX_AllowTeleport or function() end

function ServerHop:Execute()
    local placeId = game.PlaceId
    local currentJobId = game.JobId

    -- Fetch available servers via Roblox API
    local servers = {}
    local url = string.format(
        "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100",
        placeId
    )

    local success, result = pcall(function()
        local response = game:HttpGet(url)
        return HttpService:JSONDecode(response)
    end)

    if not success or not result or not result.data then
        -- Fallback: just teleport to same place (different server)
        pcall(function()
            _allowTP(true)
            TeleportService:Teleport(placeId, lp)
            _allowTP(false)
        end)
        return
    end

    -- Filter out current server and pick a random one
    for _, server in ipairs(result.data) do
        if server.id and server.id ~= currentJobId and server.playing and server.maxPlayers then
            if server.playing < server.maxPlayers then
                table.insert(servers, server.id)
            end
        end
    end

    if #servers == 0 then
        -- No other servers found, just teleport to place
        pcall(function()
            _allowTP(true)
            TeleportService:Teleport(placeId, lp)
            _allowTP(false)
        end)
        return
    end

    -- Pick random server
    local targetJobId = servers[math.random(1, #servers)]
    pcall(function()
        _allowTP(true)
        TeleportService:TeleportToPlaceInstance(placeId, targetJobId, lp)
        _allowTP(false)
    end)
end

return ServerHop
