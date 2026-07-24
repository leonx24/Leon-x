-- Leon X | Performance & Anti-Lag Booster
-- FPS unlocker and graphics rendering optimizer for low-end devices

local PerfBooster = {}
PerfBooster.Name    = "PerfBooster"
PerfBooster.Enabled = false

local Lighting        = game:GetService("Lighting")
local Workspace       = game:GetService("Workspace")
local Terrain         = Workspace:FindFirstChildOfClass("Terrain")

local originalSettings = {}
local hiddenEffects    = {}

function PerfBooster:SetFPSCap(cap)
    cap = tonumber(cap) or 60
    pcall(function()
        if setfpscap then
            setfpscap(cap)
        end
    end)
end

function PerfBooster:Enable()
    if self.Enabled then return end
    self.Enabled = true

    pcall(function()
        -- Save original Lighting settings
        originalSettings.GlobalShadows = Lighting.GlobalShadows
        originalSettings.FogEnd = Lighting.FogEnd
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9

        -- Terrain optimizations
        if Terrain then
            originalSettings.WaterWaveSize = Terrain.WaterWaveSize
            originalSettings.WaterWaveSpeed = Terrain.WaterWaveSpeed
            originalSettings.WaterReflectance = Terrain.WaterReflectance
            originalSettings.WaterTransparency = Terrain.WaterTransparency
            originalSettings.Decoration = Terrain.Decoration

            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
            Terrain.Decoration = false
        end

        -- Disable particle effects and heavy visual instances
        hiddenEffects = {}
        for _, inst in ipairs(game:GetDescendants()) do
            if inst:IsA("ParticleEmitter") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
                if inst.Enabled then
                    table.insert(hiddenEffects, inst)
                    inst.Enabled = false
                end
            end
        end
    end)
end

function PerfBooster:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    pcall(function()
        -- Restore Lighting
        if originalSettings.GlobalShadows ~= nil then
            Lighting.GlobalShadows = originalSettings.GlobalShadows
        end
        if originalSettings.FogEnd ~= nil then
            Lighting.FogEnd = originalSettings.FogEnd
        end

        -- Restore Terrain
        if Terrain then
            if originalSettings.WaterWaveSize ~= nil then Terrain.WaterWaveSize = originalSettings.WaterWaveSize end
            if originalSettings.WaterWaveSpeed ~= nil then Terrain.WaterWaveSpeed = originalSettings.WaterWaveSpeed end
            if originalSettings.WaterReflectance ~= nil then Terrain.WaterReflectance = originalSettings.WaterReflectance end
            if originalSettings.WaterTransparency ~= nil then Terrain.WaterTransparency = originalSettings.WaterTransparency end
            if originalSettings.Decoration ~= nil then Terrain.Decoration = originalSettings.Decoration end
        end

        -- Restore particle effects
        for _, inst in ipairs(hiddenEffects) do
            if inst and inst.Parent then
                inst.Enabled = true
            end
        end
        hiddenEffects = {}
        originalSettings = {}
    end)
end

function PerfBooster:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

return PerfBooster
