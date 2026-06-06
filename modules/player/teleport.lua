-- Leon X | Teleport
-- Save position, goto saved, teleport to player

local Teleport = {}
Teleport.Name      = "Teleport"
Teleport.SavedCFrame = nil

local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

function Teleport:SavePosition()
    local char = lp.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    self.SavedCFrame = hrp.CFrame
    local p = hrp.Position
    pcall(function()
        setclipboard(("%.1f, %.1f, %.1f"):format(p.X, p.Y, p.Z))
    end)
    return p
end

function Teleport:GotoSaved(flyModule)
    if not self.SavedCFrame then return false end
    local char = lp.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local wasFlying = flyModule and flyModule.Enabled
    if wasFlying then flyModule:Disable() end
    hrp.CFrame = self.SavedCFrame
    task.wait(0.1)
    if wasFlying then flyModule:Enable() end
    return true
end

function Teleport:ToPlayer(name, flyModule)
    local target = Players:FindFirstChild(name)
    if not target or not target.Character then return false end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local char  = lp.Character
    if not tHRP or not char then return false end
    local mHRP = char:FindFirstChild("HumanoidRootPart")
    if not mHRP then return false end
    local wasFlying = flyModule and flyModule.Enabled
    if wasFlying then flyModule:Disable() end
    mHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
    task.wait(0.1)
    if wasFlying then flyModule:Enable() end
    return true
end

function Teleport:GetPlayerList()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then t[#t+1] = p.Name end
    end
    return #t > 0 and t or {"(no players)"}
end

return Teleport
