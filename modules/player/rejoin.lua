-- Leon X | Rejoin & Auto Rejoin
-- Manual rejoin and automatic reconnect on disconnection/kick

local Rejoin = {}
Rejoin.Name    = "Rejoin"
Rejoin.Enabled = false

local TeleportService = game:GetService("TeleportService")
local CoreGui         = game:GetService("CoreGui")
local Players         = game:GetService("Players")
local lp              = Players.LocalPlayer
local conn            = nil

function Rejoin:Execute()
    pcall(function()
        local _allowTP = _G._LeonX_AllowTeleport or function() end
        _allowTP(true)
        if game.JobId and game.JobId ~= "" then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
        else
            TeleportService:Teleport(game.PlaceId, lp)
        end
        _allowTP(false)
    end)
end

function Rejoin:EnableAutoRejoin()
    if self.Enabled then return end
    self.Enabled = true

    pcall(function()
        local promptOverlay = CoreGui:FindFirstChild("RobloxPromptGui") and CoreGui.RobloxPromptGui:FindFirstChild("promptOverlay")
        if promptOverlay then
            if conn then conn:Disconnect() end
            conn = promptOverlay.ChildAdded:Connect(function(child)
                if self.Enabled and (child.Name == "ErrorPrompt" or child.Name:find("Prompt") or child.Name:find("Error")) then
                    task.wait(1.5)
                    self:Execute()
                end
            end)
        end
    end)
end

function Rejoin:DisableAutoRejoin()
    if not self.Enabled then return end
    self.Enabled = false
    if conn then
        conn:Disconnect()
        conn = nil
    end
end

return Rejoin
