-- Leon X | AntiAFK
-- Prevents idle kick using RunService.Heartbeat loop

local AntiAFK = {}
AntiAFK.Name    = "AntiAFK"
AntiAFK.Enabled = false

local RunService = game:GetService("RunService")
local VU         = game:GetService("VirtualUser")
local conn
local lastTick   = 0

function AntiAFK:Enable()
    self.Enabled = true
    lastTick = tick()
    conn = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        if tick() - lastTick >= 60 then
            lastTick = tick()
            pcall(function()
                VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)
end

function AntiAFK:Disable()
    self.Enabled = false
    if conn then conn:Disconnect(); conn = nil end
end

function AntiAFK:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return AntiAFK
