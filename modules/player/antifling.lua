-- Leon X | AntiFling
-- Detects abnormal velocity on the LocalPlayer's HumanoidRootPart
-- and resets position + velocity before the fling can send the character flying.
--
-- How flings work: someone attaches a high-force object (BodyVelocity, VectorForce,
-- or touches a physics exploit part) to your HRP, causing velocity to spike.
-- We catch the spike on the client in RenderStepped (before physics replication)
-- and zero it out + restore position.

local AntiFling = {}
AntiFling.Name      = "AntiFling"
AntiFling.Enabled   = false
AntiFling.Threshold = 200   -- studs/s — velocities above this are considered a fling

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local renderConn   = nil
local charConn     = nil   -- fires when character respawns

-- per-character state
local lastSafeCF   = nil   -- last known safe CFrame
local lastSafeTime = 0
local SAFE_INTERVAL = 0.1  -- update safe position every 0.1s

local function onCharacterAdded(char)
    -- reset safe state when character respawns
    lastSafeCF   = nil
    lastSafeTime = 0
end

local function startWatching()
    if renderConn then renderConn:Disconnect(); renderConn = nil end

    renderConn = RunService.RenderStepped:Connect(function()
        if not AntiFling.Enabled then return end

        local char = lp.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return end   -- don't interfere while dead

        local vel = hrp.AssemblyLinearVelocity
        local spd = vel.Magnitude

        local now = tick()

        -- update safe position periodically when velocity is normal
        if spd < AntiFling.Threshold then
            if (now - lastSafeTime) >= SAFE_INTERVAL then
                lastSafeCF   = hrp.CFrame
                lastSafeTime = now
            end
            return
        end

        -- velocity spike detected — fling attempt
        if not lastSafeCF then
            -- no safe position recorded yet, just zero the velocity
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            return
        end

        -- teleport back to last safe spot and kill velocity
        hrp.CFrame                      = lastSafeCF
        hrp.AssemblyLinearVelocity      = Vector3.zero
        hrp.AssemblyAngularVelocity     = Vector3.zero

        -- also remove any foreign BodyMovers attached by the fling exploit
        for _, obj in ipairs(hrp:GetChildren()) do
            local cn = obj.ClassName
            if cn == "BodyVelocity" or cn == "BodyForce"
            or cn == "BodyPosition" or cn == "VectorForce"
            or cn == "LinearVelocity" then
                pcall(function() obj:Destroy() end)
            end
        end
    end)
end

function AntiFling:Enable()
    if self.Enabled then return end
    self.Enabled = true

    -- watch for respawn
    charConn = lp.CharacterAdded:Connect(onCharacterAdded)

    -- init safe position from current character
    local char = lp.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            lastSafeCF   = hrp.CFrame
            lastSafeTime = tick()
        end
    end

    startWatching()
end

function AntiFling:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    if renderConn then renderConn:Disconnect(); renderConn = nil end
    if charConn   then charConn:Disconnect();   charConn   = nil end

    lastSafeCF   = nil
    lastSafeTime = 0
end

function AntiFling:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function AntiFling:SetThreshold(v)
    self.Threshold = v
end

return AntiFling
