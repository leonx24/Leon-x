-- Leon X | Aimbot & Silent Aim (Ultra Optimized)
-- Minimal lag version with aggressive optimizations

local Aimbot = {}
Aimbot.Name         = "Aimbot"
Aimbot.Enabled      = false
Aimbot.Mode         = "Silent"   -- "Visible" | "Silent"
Aimbot.TargetPart   = "Head"     -- "Head" | "Torso" | "HumanoidRootPart"
Aimbot.FOV          = 200        -- Field of view circle radius
Aimbot.Smoothness   = 5          -- Lower = smoother (1-10, only for Visible mode)
Aimbot.TeamCheck    = true       -- Skip teammates
Aimbot.VisibleCheck = false      -- Only target visible players (expensive, default off)
Aimbot.ShowFOV      = false      -- Show FOV circle (can cause lag, default off)
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
local targetUpdateTimer = 0
local TARGET_UPDATE_INTERVAL = 0.1  -- Update target every 100ms instead of every frame

-- ── FOV Circle ────────────────────────────────────────────────────────────────

local function createFOVCircle()
    if fovCircle then pcall(function() fovCircle:Remove() end) end

    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1
    fovCircle.NumSides = 32  -- Lower sides for better performance
    fovCircle.Radius = Aimbot.FOV
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 0.5
    fovCircle.Visible = false
    fovCircle.Filled = false

    return fovCircle
end

local function updateFOVCircle()
    if not fovCircle or not Aimbot.ShowFOV then return end

    local vp = Camera.ViewportSize
    fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
    fovCircle.Radius = Aimbot.FOV
    fovCircle.Visible = Aimbot.Enabled
end

-- ── Utility Functions ─────────────────────────────────────────────────────────

local function isTeammate(player)
    if not Aimbot.TeamCheck then return false end
    return lp.Team and player.Team and lp.Team == player.Team
end

local function isVisible(targetPart)
    if not Aimbot.VisibleCheck then return true end
    if not targetPart then return false end

    local myChar = lp.Character
    if not myChar then return false end

    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {myChar}
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

-- Cached player list to avoid recreating table every frame
local cachedPlayers = {}
local lastPlayerCacheUpdate = 0

local function getClosestPlayer()
    local currentTime = tick()

    -- Cache player list for 0.5 seconds
    if currentTime - lastPlayerCacheUpdate > 0.5 then
        cachedPlayers = Players:GetPlayers()
        lastPlayerCacheUpdate = currentTime
    end

    local closest = nil
    local shortestDistance = Aimbot.FOV
    local vp = Camera.ViewportSize
    local screenCenter = Vector2.new(vp.X / 2, vp.Y / 2)

    for _, player in ipairs(cachedPlayers) do
        if player == lp or not player.Character then continue end

        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        if isTeammate(player) then continue end

        local targetPart = getTargetPart(player.Character)
        if not targetPart then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

        if distance < shortestDistance then
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
    if not target or not target.Character then return false end

    local targetPart = getTargetPart(target.Character)
    if not targetPart then return false end

    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    -- Smooth camera aim
    local targetPos = targetPart.Position
    local camCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(camCFrame.Position, targetPos)

    local alpha = 1 / math.max(1, Aimbot.Smoothness)
    Camera.CFrame = camCFrame:Lerp(targetCFrame, alpha)

    -- Trigger bot
    if Aimbot.TriggerBot and alpha > 0.8 then
        pcall(function()
            mouse1press()
            task.wait(0.05)
            mouse1release()
        end)
    end

    return true
end

-- ── Silent Aim ────────────────────────────────────────────────────────────────

local oldNamecall
local oldIndex

local function hookNamecall()
    if oldNamecall then return end

    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Aimbot.Enabled and Aimbot.Mode == "Silent" and (method == "FireServer" or method == "InvokeServer") then
            if target and target.Character then
                local targetPart = getTargetPart(target.Character)
                if targetPart then
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

    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if Aimbot.Enabled and Aimbot.Mode == "Silent" then
            if target and target.Character then
                local targetPart = getTargetPart(target.Character)
                if targetPart then
                    if self == lp:GetMouse() then
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

    -- Create FOV circle only if enabled
    if self.ShowFOV and not fovCircle then
        createFOVCircle()
    end

    -- Hook for silent aim
    if self.Mode == "Silent" then
        pcall(hookNamecall)
    end

    -- Cleanup old connection
    if aimConnection then
        pcall(function() aimConnection:Disconnect() end)
        aimConnection = nil
    end

    -- Use Heartbeat instead of RenderStepped for better performance
    aimConnection = RunService.Heartbeat:Connect(function(deltaTime)
        pcall(function()
            targetUpdateTimer = targetUpdateTimer + deltaTime

            -- Update target less frequently
            if targetUpdateTimer >= TARGET_UPDATE_INTERVAL then
                targetUpdateTimer = 0

                -- Validate current target
                if not target or not target.Character or not target.Character:FindFirstChildOfClass("Humanoid")
                   or target.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
                    target = getClosestPlayer()
                end
            end

            -- Update FOV circle (only if visible)
            if self.ShowFOV then
                updateFOVCircle()
            end

            -- Visible aimbot: move camera
            if self.Mode == "Visible" and target then
                if not aimAtTarget() then
                    target = nil
                end
            end
        end)
    end)
end

function Aimbot:Disable()
    self.Enabled = false
    target = nil
    targetUpdateTimer = 0

    if aimConnection then
        pcall(function() aimConnection:Disconnect() end)
        aimConnection = nil
    end

    if fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end

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
    if fovCircle then
        fovCircle.Radius = fov
    end
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
    if enabled and not fovCircle then
        createFOVCircle()
    elseif not enabled and fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end
    updateFOVCircle()
end

function Aimbot:SetTriggerBot(enabled)
    self.TriggerBot = enabled
end

return Aimbot
