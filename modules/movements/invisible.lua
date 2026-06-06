-- Leon X | Invisible
-- Makes local character transparent (client-side only)

local Invisible = {}
Invisible.Name    = "Invisible"
Invisible.Enabled = false

local lp        = game:GetService("Players").LocalPlayer
local saved     = {}
local charConn

local function apply(char)
    if not char then return end
    saved = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            saved[p] = p.LocalTransparencyModifier
            p.LocalTransparencyModifier = 1
        end
    end
end

local function restore()
    for p, v in pairs(saved) do
        pcall(function() p.LocalTransparencyModifier = v end)
    end
    saved = {}
end

function Invisible:Enable()
    self.Enabled = true
    apply(lp.Character)
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.5); if self.Enabled then apply(char) end
    end)
end

function Invisible:Disable()
    self.Enabled = false
    restore()
    if charConn then charConn:Disconnect(); charConn = nil end
end

function Invisible:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Invisible
