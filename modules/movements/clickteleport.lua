-- Leon X | ClickTeleport
-- Left-click on any surface to teleport character there
-- Shows a brief marker at destination before teleporting

local ClickTeleport = {}
ClickTeleport.Name    = "ClickTeleport"
ClickTeleport.Enabled = false

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp       = Players.LocalPlayer

local clickConn  = nil
local marker     = nil   -- visual indicator at target

local function getMarker()
    if marker and marker.Parent then return marker end
    -- simple semi-transparent cylinder at ground level
    local m = Instance.new("Part")
    m.Name          = "LeonTPMarker"
    m.Shape         = Enum.PartType.Cylinder
    m.Size          = Vector3.new(0.3, 2.4, 2.4)
    m.Material      = Enum.Material.Neon
    m.Color         = Color3.fromRGB(255, 255, 255)
    m.Transparency  = 0.35
    m.CanCollide    = false
    m.CanQuery      = false
    m.Anchored      = true
    m.CastShadow    = false
    m.Parent        = workspace
    marker = m
    return m
end

local function removeMarker()
    if marker and marker.Parent then
        pcall(function() marker:Destroy() end)
    end
    marker = nil
end

local function doTeleport(hitPos, hitNormal)
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- offset upward so character stands on surface
    local charHalfHeight = 3.0
    local dest = hitPos + hitNormal * charHalfHeight

    -- show marker briefly at destination
    local m = getMarker()
    -- lay flat on the surface
    m.CFrame = CFrame.new(hitPos + hitNormal * 0.2)
              * CFrame.fromEulerAnglesYXZ(0, 0, math.pi / 2)
    m.Transparency = 0.2

    -- small flash then teleport
    task.spawn(function()
        task.wait(0.08)
        hrp.CFrame = CFrame.new(dest) * CFrame.Angles(0, hrp.CFrame:ToEulerAnglesYXZ(), 0)
        -- keep yaw, reset pitch/roll
        local _, ry, _ = hrp.CFrame:ToEulerAnglesYXZ()
        hrp.CFrame = CFrame.new(dest) * CFrame.fromEulerAnglesYXZ(0, ry, 0)
        -- fade marker out
        task.wait(0.12)
        pcall(function() m.Transparency = 1 end)
        task.wait(0.1)
        removeMarker()
    end)
end

function ClickTeleport:Enable()
    if self.Enabled then return end
    self.Enabled = true

    clickConn = UIS.InputBegan:Connect(function(input, gameProcessed)
        if not self.Enabled then return end
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        local camera = workspace.CurrentCamera
        if not camera then return end

        -- raycast from camera through mouse position
        local unitRay = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        -- exclude local character from raycast
        local char = lp.Character
        if char then
            raycastParams.FilterDescendantsInstances = { char }
        end

        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, raycastParams)
        if not result then return end

        doTeleport(result.Position, result.Normal)
    end)
end

function ClickTeleport:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    if clickConn then clickConn:Disconnect(); clickConn = nil end
    removeMarker()
end

function ClickTeleport:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return ClickTeleport
