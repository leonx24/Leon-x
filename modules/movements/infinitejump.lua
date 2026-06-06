-- Leon X | InfiniteJump
-- Allows jumping infinitely while in the air

local InfiniteJump = {}
InfiniteJump.Name    = "InfiniteJump"
InfiniteJump.Enabled = false

local UIS = game:GetService("UserInputService")
local lp  = game:GetService("Players").LocalPlayer
local conn

function InfiniteJump:Enable()
    self.Enabled = true
    conn = UIS.JumpRequest:Connect(function()
        if not self.Enabled then return end
        local char = lp.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function InfiniteJump:Disable()
    self.Enabled = false
    if conn then conn:Disconnect(); conn = nil end
end

function InfiniteJump:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return InfiniteJump
