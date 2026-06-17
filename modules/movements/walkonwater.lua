-- Leon X | Walk on Water
-- Creates an invisible platform below the player so they can walk on water/void.
-- Detects water terrain and positions the platform at the water surface.

local WalkOnWater = {}
WalkOnWater.Name    = "WalkOnWater"
WalkOnWater.Enabled = false

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Terrain    = game:GetService("Workspace").Terrain
local lp         = Players.LocalPlayer

local platform   = nil
local conn       = nil
local charConn   = nil

local PLATFORM_SIZE   = Vector3.new(12, 1, 12)
local PLATFORM_OFFSET = 3  -- studs below HRP

local function createPlatform()
    if platform then pcall(function() platform:Destroy() end) end

    platform = Instance.new("Part")
    platform.Name         = "wow_platform"
    platform.Size         = PLATFORM_SIZE
    platform.Transparency = 1
    platform.CanCollide   = true
    platform.Anchored     = true
    platform.Massless     = true
    platform.Material     = Enum.Material.ForceField
    platform.CastShadow   = false
    platform.CanTouch     = true
    platform.CanQuery     = false
    platform.Parent       = workspace
end

local function destroyPlatform()
    if platform then
        pcall(function() platform:Destroy() end)
        platform = nil
    end
end

local function getWaterLevel(pos)
    -- Try to detect water terrain at the player's XZ using GetMaterial (more reliable)
    local waterY = nil

    -- Method 1: Use GetMaterial at various Y levels to find water surface
    pcall(function()
        for y = pos.Y + 10, pos.Y - 30, -2 do
            local checkPos = Vector3.new(pos.X, y, pos.Z)
            local material = Terrain:GetMaterial(checkPos)
            if material == Enum.Material.Water then
                waterY = y
                break
            end
        end
    end)

    -- Method 2: Fallback to ReadVoxels if GetMaterial didn't find water
    if not waterY then
        pcall(function()
            local region = Region3.new(
                Vector3.new(pos.X - 2, pos.Y - 20, pos.Z - 2),
                Vector3.new(pos.X + 2, pos.Y + 10, pos.Z + 2)
            )
            local materials, occupancy = Terrain:ReadVoxels(region, 4)

            if materials and #materials > 0 then
                -- ReadVoxels returns materials[y][x][z]
                local sizeY = #materials
                local sizeX = #materials[1]
                local sizeZ = #materials[1][1]

                -- Scan from top to bottom for water
                for y = sizeY, 1, -1 do
                    for x = 1, sizeX do
                        for z = 1, sizeZ do
                            if materials[y][x][z] == Enum.Material.Water then
                                -- Convert voxel index back to world Y
                                local baseY = pos.Y - 20
                                waterY = baseY + (y * 4)
                                return
                            end
                        end
                    end
                end
            end
        end)
    end

    return waterY
end

function WalkOnWater:Enable()
    self.Enabled = true
    createPlatform()

    if conn then conn:Disconnect() end
    conn = RunService.Heartbeat:Connect(function()
        if not self.Enabled or not platform then return end

        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local pos = hrp.Position
        local platY = pos.Y - PLATFORM_OFFSET

        -- Try to detect water below and snap platform to water surface
        local waterY = getWaterLevel(pos)
        if waterY then
            -- Position platform at water surface
            platY = math.max(platY, waterY - 0.5)
        end

        platform.CFrame = CFrame.new(pos.X, platY, pos.Z)
    end)

    -- Respawn handling
    if charConn then charConn:Disconnect() end
    charConn = lp.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if self.Enabled then
            createPlatform()
        end
    end)
end

function WalkOnWater:Disable()
    self.Enabled = false
    if conn then conn:Disconnect(); conn = nil end
    if charConn then charConn:Disconnect(); charConn = nil end
    destroyPlatform()
end

function WalkOnWater:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return WalkOnWater
