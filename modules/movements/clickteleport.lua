-- Leon X | ClickTeleport
-- Mouse: left-click on any surface to teleport
-- Mobile: tap on any surface to teleport (Touch input)

local ClickTeleport = {}
ClickTeleport.Name    = "ClickTeleport"
ClickTeleport.Enabled = false

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local lp         = Players.LocalPlayer

local clickConn  = nil
local marker     = nil

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function getMarker()
    if marker and marker.Parent then return marker end
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

    local charHalfHeight = 3.0
    local dest = hitPos + hitNormal * charHalfHeight

    local m = getMarker()
    m.CFrame = CFrame.new(hitPos + hitNormal * 0.2)
              * CFrame.fromEulerAnglesYXZ(0, 0, math.pi / 2)
    m.Transparency = 0.2

    task.spawn(function()
        task.wait(0.08)
        local _, ry, _ = hrp.CFrame:ToEulerAnglesYXZ()
        hrp.CFrame = CFrame.new(dest) * CFrame.fromEulerAnglesYXZ(0, ry, 0)
        task.wait(0.12)
        pcall(function() m.Transparency = 1 end)
        task.wait(0.1)
        removeMarker()
    end)
end

local function tryTeleportFromScreen(screenX, screenY)
    local camera = workspace.CurrentCamera
    if not camera then return end

    local unitRay = camera:ScreenPointToRay(screenX, screenY)
    local params  = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = lp.Character
    if char then params.FilterDescendantsInstances = { char } end

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, params)
    if result then
        doTeleport(result.Position, result.Normal)
    end
end

function ClickTeleport:Enable()
    if self.Enabled then return end
    self.Enabled = true

    clickConn = UIS.InputBegan:Connect(function(input, gameProcessed)
        if not self.Enabled then return end
        if gameProcessed then return end

        -- handle both mouse click and touch tap
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            tryTeleportFromScreen(input.Position.X, input.Position.Y)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            -- on mobile, wait a tiny moment to distinguish tap from drag/scroll
            local startPos = input.Position
            task.delay(0.15, function()
                if not self.Enabled then return end
                -- check the touch didn't move much (i.e. it was a tap not a swipe)
                local moved = (input.Position - startPos).Magnitude
                if moved < 20 then
                    tryTeleportFromScreen(startPos.X, startPos.Y)
                end
            end)
        end
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
