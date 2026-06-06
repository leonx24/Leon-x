-- Leon X | AntiRagdoll
-- Prevents ragdoll state and disables joint breaking on death

local AntiRagdoll = {}
AntiRagdoll.Name    = "AntiRagdoll"
AntiRagdoll.Enabled = false

local lp   = game:GetService("Players").LocalPlayer
local conn = nil

local function apply(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.BreakJointsOnDeath = false
    if conn then conn:Disconnect() end
    conn = hum.StateChanged:Connect(function(_, s)
        if not AntiRagdoll.Enabled then return end
        if s == Enum.HumanoidStateType.FallingDown
        or s == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

local charConn

function AntiRagdoll:Enable()
    self.Enabled = true
    apply(lp.Character)
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.5); apply(char)
    end)
end

function AntiRagdoll:Disable()
    self.Enabled = false
    if conn    then conn:Disconnect();    conn    = nil end
    if charConn then charConn:Disconnect(); charConn = nil end
end

function AntiRagdoll:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return AntiRagdoll
