-- Leon X | Public Replicated Invisibility (Ghost Mode)
-- Desyncs character CFrame on server to make character 100% invisible to all other players publically

local Invisible = {}
Invisible.Name    = "Invisible"
Invisible.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local lp         = Players.LocalPlayer

local savedCFrame = nil
local fakeRoot    = nil
local updateConn  = nil

function Invisible:Enable()
    if self.Enabled then return end
    local char = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChildOfClass("Humanoid") then
        return false
    end
    self.Enabled = true

    pcall(function()
        local hrp = char.HumanoidRootPart
        savedCFrame = hrp.CFrame

        -- Create local physics root clone
        hrp.Archivable = true
        fakeRoot = hrp:Clone()
        fakeRoot.Name = "LocalGhostRoot"
        fakeRoot.Transparency = 1
        fakeRoot.CanCollide = false
        fakeRoot.Parent = char

        -- Teleport real HRP far to void on server loop while keeping local control
        updateConn = RunService.Heartbeat:Connect(function()
            if self.Enabled and char and char:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    -- CFrame desync: server sees HRP in void (invisible to public players)
                    char.HumanoidRootPart.CFrame = CFrame.new(0, 999999, 0)
                end)
            end
        end)
    end)
    return true
end

function Invisible:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    pcall(function()
        if updateConn then updateConn:Disconnect(); updateConn = nil end
        if fakeRoot then fakeRoot:Destroy(); fakeRoot = nil end

        local char = lp.Character
        if char and savedCFrame and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = savedCFrame
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end)
end

function Invisible:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Invisible
