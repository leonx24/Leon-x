-- Leon X | Invisibility (Ghost Mode)
-- Safe, crash-free character invisibility with ghost visual feedback

local Invisible = {}
Invisible.Name    = "Invisible"
Invisible.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local savedParts = {}
local charConn   = nil

local function setInvis(char, enable)
    if not char then return end
    if enable then
        savedParts = {}
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                savedParts[p] = {
                    Transparency = p.Transparency,
                    LocalTransparencyModifier = p.LocalTransparencyModifier,
                }
                p.Transparency = 0.5
                p.LocalTransparencyModifier = 0.5
            elseif p:IsA("Decal") then
                savedParts[p] = { Transparency = p.Transparency }
                p.Transparency = 1
            end
        end
    else
        for p, data in pairs(savedParts) do
            if p and p.Parent then
                pcall(function()
                    if data.Transparency ~= nil then p.Transparency = data.Transparency end
                    if data.LocalTransparencyModifier ~= nil then p.LocalTransparencyModifier = data.LocalTransparencyModifier end
                end)
            end
        end
        savedParts = {}
    end
end

function Invisible:Enable()
    if self.Enabled then return end
    self.Enabled = true

    local char = lp.Character
    if char then
        setInvis(char, true)
    end

    if charConn then charConn:Disconnect() end
    charConn = lp.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        if self.Enabled then
            setInvis(newChar, true)
        end
    end)
    return true
end

function Invisible:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    if charConn then charConn:Disconnect(); charConn = nil end

    local char = lp.Character
    if char then
        setInvis(char, false)
    end
end

function Invisible:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Invisible
