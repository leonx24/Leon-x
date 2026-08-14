-- Leon X | Invisibility (Server-Side CFrame Void)
-- True server-side invisibility using CFrame void teleport trick
-- Other players cannot see you while invisible

local Invisible = {}
Invisible.Name    = "Invisible"
Invisible.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local VOID_POS = CFrame.new(0, 1e7, 0)

local savedCFrame    = nil
local ghostParts     = {}
local renderConn     = nil
local charConn       = nil
local stateConn      = nil
local fakeChar       = nil

local function destroyGhost()
    ghostParts = {}
    if fakeChar then
        pcall(function() fakeChar:Destroy() end)
        fakeChar = nil
    end
end

-- Create a local-only semi-transparent ghost so the player can see themselves
local function createGhost(char)
    destroyGhost()
    if not char then return end

    pcall(function()
        fakeChar = Instance.new("Model")
        fakeChar.Name = game:GetService("HttpService"):GenerateGUID(false)
        
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                pcall(function()
                    local clone = part:Clone()
                    clone.CanCollide = false
                    clone.CanTouch = false
                    clone.CanQuery = false
                    clone.Anchored = true
                    clone.Transparency = math.max(part.Transparency, 0.55)
                    clone.Parent = fakeChar
                    ghostParts[part] = clone
                end)
            elseif part:IsA("Decal") or part:IsA("Texture") then
                -- Skip decals, they'll show on cloned parts
            end
        end

        fakeChar.Parent = workspace.CurrentCamera
    end)
end

-- Update ghost part positions to follow originals
local function updateGhost(char)
    if not fakeChar then return end
    for original, clone in pairs(ghostParts) do
        if original and original.Parent and clone and clone.Parent then
            pcall(function()
                clone.CFrame = original.CFrame
                clone.Transparency = math.max(original.Transparency, 0.55)
            end)
        end
    end
end

local function applyInvisible(char)
    if not char then return end

    local hrp = char:WaitForChild("HumanoidRootPart", 3)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Save current position
    savedCFrame = hrp.CFrame

    -- Create ghost before hiding
    createGhost(char)

    -- Teleport HumanoidRootPart to void (server-side — other players lose sight)
    pcall(function()
        hrp.CFrame = VOID_POS
        hrp.Anchored = true
    end)

    -- Make character parts locally transparent so they don't block camera
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            pcall(function()
                p.LocalTransparencyModifier = 1
            end)
        end
    end

    -- Continuous render loop: keep HRP in void + update ghost + enforce local transparency
    if renderConn then renderConn:Disconnect() end
    renderConn = RunService.RenderStepped:Connect(function()
        if not Invisible.Enabled then return end
        pcall(function()
            -- Keep HRP anchored in void (prevent game scripts from moving it back)
            if hrp and hrp.Parent then
                hrp.CFrame = VOID_POS
                hrp.Anchored = true
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end

            -- Enforce local transparency on all parts
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.LocalTransparencyModifier = 1
                end
            end

            -- Update ghost positions
            updateGhost(char)

            -- Keep camera at saved position (not void)
            if savedCFrame then
                local cam = workspace.CurrentCamera
                if cam and cam.CameraType == Enum.CameraType.Custom then
                    -- Don't override camera if user has free cam or other camera mods
                end
            end
        end)
    end)

    -- Listen for state changes that might break invisibility
    if stateConn then stateConn:Disconnect() end
    stateConn = hum.StateChanged:Connect(function()
        if not Invisible.Enabled then return end
        pcall(function()
            if hrp and hrp.Parent then
                hrp.CFrame = VOID_POS
                hrp.Anchored = true
            end
        end)
    end)
end

local function removeInvisible(char)
    if renderConn then renderConn:Disconnect(); renderConn = nil end
    if stateConn then stateConn:Disconnect(); stateConn = nil end

    destroyGhost()

    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Restore position and physics
    pcall(function()
        hrp.Anchored = false
        if savedCFrame then
            hrp.CFrame = savedCFrame
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
    end)

    -- Restore local transparency
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p.LocalTransparencyModifier = 0
            end)
        end
    end

    savedCFrame = nil
end

function Invisible:Enable()
    if self.Enabled then return end
    self.Enabled = true

    local char = lp.Character
    if char then
        applyInvisible(char)
    end

    if charConn then charConn:Disconnect() end
    charConn = lp.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        if self.Enabled then
            applyInvisible(newChar)
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
        removeInvisible(char)
    end
end

function Invisible:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Invisible
