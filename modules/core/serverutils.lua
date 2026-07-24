-- Leon X | Server Utilities
-- Server hopping, rejoining, and JobID clipboard copying utilities

local ServerUtils = {}
ServerUtils.Name    = "ServerUtils"
ServerUtils.Enabled = false

local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local lp              = Players.LocalPlayer

local _allowTP = _G._LeonX_AllowTeleport or function() end

function ServerUtils:Rejoin()
    pcall(function()
        _allowTP(true)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
        _allowTP(false)
    end)
end

function ServerUtils:ServerHop()
    local placeId = game.PlaceId
    local currentJobId = game.JobId

    local servers = {}
    local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", placeId)

    local success, result = pcall(function()
        local response = game:HttpGet(url)
        return HttpService:JSONDecode(response)
    end)

    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if server.id and server.id ~= currentJobId and server.playing and server.maxPlayers then
                if server.playing < server.maxPlayers then
                    table.insert(servers, server.id)
                end
            end
        end
    end

    pcall(function()
        _allowTP(true)
        if #servers > 0 then
            local targetJobId = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(placeId, targetJobId, lp)
        else
            TeleportService:Teleport(placeId, lp)
        end
        _allowTP(false)
    end)
end

function ServerUtils:CopyJobID()
    local jobId = game.JobId
    if setclipboard then
        pcall(function() setclipboard(tostring(jobId)) end)
        return true, jobId
    elseif toclipboard then
        pcall(function() toclipboard(tostring(jobId)) end)
        return true, jobId
    end
    return false, jobId
end

function ServerUtils:Enable() self.Enabled = true end
function ServerUtils:Disable() self.Enabled = false end
function ServerUtils:Toggle() self.Enabled = not self.Enabled end

return ServerUtils
