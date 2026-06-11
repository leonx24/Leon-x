-- Leon X | Aimbot & Silent Aim
-- Visible Aimbot: Smoothly aims camera at target
-- Silent Aim: Redirects tool/gun hits to target without moving camera

local Aimbot = {}
Aimbot.Name         = "Aimbot"
Aimbot.Enabled      = false
Aimbot.Mode         = "Visible"  -- "Visible" | "Silent"
Aimbot.TargetPart   = "Head"     -- "Head" | "Torso" | "HumanoidRootPart"
Aimbot.FOV          = 200        -- Field of view circle radius
Aimbot.Smoothness   = 5          -- Lower = smoother (1-10, only for Visible mode)
Aimbot.TeamCheck    = true       -- Skip teammates
Aimbot.VisibleCheck = true       -- Only target visible players
Aimbot.ShowFOV      = true       -- Show FOV circle
Aimbot.TriggerBot   = false      -- Auto shoot when aimed at target

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace      = game:GetService("Workspace")
local Camera         = Workspace.CurrentCamera
local lp             = Players.LocalPlayer

local fovCircle      = nil
local aimConnection  = nil
local target         = nil
local lastUpdate     = 0  -- Throttle updates
local UPDATE_RATE    = 1/60  -- 60 FPS cap

-- ── FOV Circle ────────────────────────────────────────────────────────────────

local function createFOVCircle()
    if fovCircle then fovCircle:Remove() end

    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2
    fovCircle.NumSides = 64
    fovCircle.Radius = Aimbot.FOV
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 0.7
    fovCircle.Visible = Aimbot.ShowFOV and Aimbot.Enabled
    fovCircle.Filled = false

    return fovCircle
end

local function updateFOVCircle()
    if not fovCircle then return end

    local vp = Camera.ViewportSize
    fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
    fovCircle.Radius = Aimbot.FOV
    fovCircle.Visible = Aimbot.ShowFOV and Aimbot.Enabled
    fovCircle.NumSides = math.clamp(Aimbot.FOV / 4, 32, 64)  -- Dynamic sides based on FOV
end

-- ── Utility Functions ─────────────────────────────────────────────────────────

local function isTeammate(player)
    if not Aimbot.TeamCheck then return false end
    if not lp.Team then return false end
    if not player.Team then return false end
    return lp.Team == player.Team
end

local function isVisible(targetPart)
    if not Aimbot.VisibleCheck then return true end
    if not targetPart then return false end

    local myChar = lp.Character
    if not myChar then return false end

    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end

    -- Use RaycastParams for better performance
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {myChar, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local direction = (targetPart.Position - myRoot.Position)
    local result = Workspace:Raycast(myRoot.Position, direction, raycastParams)

    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end

    return true
end

local function getTargetPart(character)
    if not character then return nil end

    if Aimbot.TargetPart == "Head" then
        return character:FindFirstChild("Head")
    elseif Aimbot.TargetPart == "Torso" then
        return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    else
        return character:FindFirstChild("HumanoidRootPart")
    end
end

local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local vp = Camera.ViewportSize
    local screenCenter = Vector2.new(vp.X / 2, vp.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == lp then continue end
        if not player.Character then continue end

        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        if isTeammate(player) then continue end

        local targetPart = getTargetPart(player.Character)
        if not targetPart then continue end

        -- Quick screen check before visibility check (optimization)
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

        if distance < Aimbot.FOV and distance < shortestDistance then
            -- Only do expensive visibility check for potential targets
            if isVisible(targetPart) then
                shortestDistance = distance
                closest = player
            end
        end
    end

    return closest
end

-- ── Visible Aimbot ────────────────────────────────────────────────────────────

local function aimAtTarget()
    if not target or not target.Character then
        target = nil
        return
    end

    local targetPart = getTargetPart(target.Character)
    if not targetPart then
        target = nil
        return
    end

    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        target = nil
        return
    end

    if not isVisible(targetPart) then
        target = nil
        return
    end

    -- Smooth camera aim
    local targetPos = targetPart.Position
    local camCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(camCFrame.Position, targetPos)

    -- Smoothness: lerp between current and target CFrame
    local alpha = 1 / math.max(1, Aimbot.Smoothness)
    Camera.CFrame = camCFrame:Lerp(targetCFrame, alpha)

    -- Trigger bot: auto shoot when aimed
    if Aimbot.TriggerBot and alpha > 0.9 then
        pcall(function()
            mouse1press()
            task.wait(0.05)
            mouse1release()
        end)
    end
end

-- ── Silent Aim ────────────────────────────────────────────────────────────────

local oldNamecall
local oldIndex
local function hookNamecall()
    if oldNamecall then return end  -- Already hooked

    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Hook FireServer/InvokeServer for silent aim
        if Aimbot.Enabled and Aimbot.Mode == "Silent" and (method == "FireServer" or method == "InvokeServer") then
            -- Check if this is a gun/tool remote
            if target and target.Character then
                local targetPart = getTargetPart(target.Character)
                if targetPart then
                    -- Replace position/CFrame arguments with target position
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "Vector3" then
                            args[i] = targetPart.Position
                        elseif typeof(arg) == "CFrame" then
                            args[i] = CFrame.new(targetPart.Position)
                        elseif typeof(arg) == "Ray" then
                            local origin = arg.Origin
                            local direction = (targetPart.Position - origin).Unit * arg.Direction.Magnitude
                            args[i] = Ray.new(origin, direction)
                        end
                    end
                end
            end
        end

        return oldNamecall(self, unpack(args))
    end)

    -- Hook mouse properties for gun aiming
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if Aimbot.Enabled and Aimbot.Mode == "Silent" then
            if target and target.Character then
                local targetPart = getTargetPart(target.Character)
                if targetPart then
                    -- Hook Mouse.Hit and Mouse.Target for shooting
                    if self == game.Players.LocalPlayer:GetMouse() then
                        if key == "Hit" then
                            return CFrame.new(targetPart.Position)
                        elseif key == "Target" then
                            return targetPart
                        elseif key == "X" then
                            local screenPos = Camera:WorldToViewportPoint(targetPart.Position)
                            return screenPos.X
                        elseif key == "Y" then
                            local screenPos = Camera:WorldToViewportPoint(targetPart.Position)
                            return screenPos.Y
                        end
                    end
                end
            end
        end

        return oldIndex(self, key)
    end)
end

local function unhookNamecall()
    if oldNamecall then
        hookmetamethod(game, "__namecall", oldNamecall)
        oldNamecall = nil
    end
    if oldIndex then
        hookmetamethod(game, "__index", oldIndex)
        oldIndex = nil
    end
end

-- ── Main Functions ────────────────────────────────────────────────────────────

function Aimbot:Enable()
    self.Enabled = true

    -- Create FOV circle
    if not fovCircle then
        createFOVCircle()
    end
    updateFOVCircle()

    -- Hook for silent aim
    if self.Mode == "Silent" then
        pcall(hookNamecall)
    end

    -- Cleanup old connection
    if aimConnection then
        pcall(function() aimConnection:Disconnect() end)
        aimConnection = nil
    end

    -- Main aimbot loop
    aimConnection = RunService.RenderStepped:Connect(function()
        pcall(function()
            local currentTime = tick()

            -- Throttle updates to reduce lag
            if currentTime - lastUpdate < UPDATE_RATE then
                return
            end
            lastUpdate = currentTime

            updateFOVCircle()

            -- Update target every frame but less expensive operations
            if not target or not target.Character or not target.Character:FindFirstChildOfClass("Humanoid") or target.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
                target = getClosestPlayer()
            end

            -- Visible aimbot: move camera
            if self.Mode == "Visible" and target then
                aimAtTarget()
            end
            -- Silent aim: target is used in __index hook
        end)
    end)
end

function Aimbot:Disable()
    self.Enabled = false
    target = nil

    -- Cleanup connection
    if aimConnection then
        pcall(function() aimConnection:Disconnect() end)
        aimConnection = nil
    end

    -- Remove FOV circle
    if fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end

    -- Unhook namecall
    unhookNamecall()
end

function Aimbot:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function Aimbot:SetMode(mode)
    local wasEnabled = self.Enabled
    if wasEnabled then self:Disable() end

    self.Mode = mode

    if wasEnabled then self:Enable() end
end

function Aimbot:SetTargetPart(part)
    self.TargetPart = part
end

function Aimbot:SetFOV(fov)
    self.FOV = fov
    updateFOVCircle()
end

function Aimbot:SetSmoothness(smoothness)
    self.Smoothness = smoothness
end

function Aimbot:SetTeamCheck(enabled)
    self.TeamCheck = enabled
end

function Aimbot:SetVisibleCheck(enabled)
    self.VisibleCheck = enabled
end

function Aimbot:SetShowFOV(enabled)
    self.ShowFOV = enabled
    updateFOVCircle()
end

function Aimbot:SetTriggerBot(enabled)
    self.TriggerBot = enabled
end

return Aimbot
