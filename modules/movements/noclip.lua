-- Leon X | Noclip
-- Disables collision on all character parts every Stepped frame

local Noclip = {}
Noclip.Name    = "Noclip"
Noclip.Enabled = false

local RunService = game:GetService("RunService")
local lp         = game:GetService("Players").LocalPlayer
local conn

function Noclip:Enable()
    self.Enabled = true
    conn = RunService.Stepped:Connect(function()
        local char = lp.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end)
end

function Noclip:Disable()
    self.Enabled = false
    if conn then conn:Disconnect(); conn = nil end
    local char = lp.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

function Noclip:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Noclip
