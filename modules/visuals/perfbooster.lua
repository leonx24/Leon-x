-- Leon X | Performance & Anti-Lag Booster
-- FPS unlocker, graphics rendering optimizer, and Super Anti-Lag (Potato Low-Poly Mode)

local PerfBooster = {}
PerfBooster.Name          = "PerfBooster"
PerfBooster.Enabled       = false
PerfBooster.PotatoEnabled = false

local Lighting        = game:GetService("Lighting")
local Workspace       = game:GetService("Workspace")
local Terrain         = Workspace:FindFirstChildOfClass("Terrain")

local originalSettings = {}
local hiddenEffects    = {}
local potatoBackups    = {}
local hiddenTextures   = {}
local hiddenPostFx     = {}
local potatoConn       = nil

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
        originalSettings.GlobalShadows = Lighting.GlobalShadows
        originalSettings.FogEnd = Lighting.FogEnd
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9

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
        if originalSettings.GlobalShadows ~= nil then
            Lighting.GlobalShadows = originalSettings.GlobalShadows
        end
        if originalSettings.FogEnd ~= nil then
            Lighting.FogEnd = originalSettings.FogEnd
        end

        if Terrain then
            if originalSettings.WaterWaveSize ~= nil then Terrain.WaterWaveSize = originalSettings.WaterWaveSize end
            if originalSettings.WaterWaveSpeed ~= nil then Terrain.WaterWaveSpeed = originalSettings.WaterWaveSpeed end
            if originalSettings.WaterReflectance ~= nil then Terrain.WaterReflectance = originalSettings.WaterReflectance end
            if originalSettings.WaterTransparency ~= nil then Terrain.WaterTransparency = originalSettings.WaterTransparency end
            if originalSettings.Decoration ~= nil then Terrain.Decoration = originalSettings.Decoration end
        end

        for _, inst in ipairs(hiddenEffects) do
            if inst and inst.Parent then
                inst.Enabled = true
            end
        end
        hiddenEffects = {}
        originalSettings = {}
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SUPER ANTI-LAG (Potato Low-Poly Map Booster)
-- ══════════════════════════════════════════════════════════════════════════════
local function formatPartPotato(part)
    pcall(function()
        if part:IsA("BasePart") then
            if not potatoBackups[part] then
                potatoBackups[part] = {
                    Material    = part.Material,
                    Reflectance = part.Reflectance,
                }
            end
            part.Material    = Enum.Material.SmoothPlastic
            part.Reflectance = 0
        end

        if part:IsA("MeshPart") then
            if not potatoBackups[part] then
                potatoBackups[part] = {
                    Material    = part.Material,
                    Reflectance = part.Reflectance,
                    TextureID   = part.TextureID,
                }
            end
            part.Material    = Enum.Material.SmoothPlastic
            part.Reflectance = 0
            part.TextureID   = ""
        end

        if part:IsA("Decal") or part:IsA("Texture") then
            if not hiddenTextures[part] then
                hiddenTextures[part] = { Texture = part.Texture, Transparency = part.Transparency }
            end
            part.Transparency = 1
        end

        if part:IsA("SurfaceAppearance") then
            if not hiddenTextures[part] then
                hiddenTextures[part] = { Parent = part.Parent }
            end
            part.Parent = nil
        end
    end)
end

function PerfBooster:EnablePotato()
    if self.PotatoEnabled then return end
    self.PotatoEnabled = true

    pcall(function()
        -- Also enable standard light anti-lag
        self:Enable()

        potatoBackups  = {}
        hiddenTextures = {}
        hiddenPostFx   = {}

        -- Disable Post-Processing Shaders in Lighting
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") or fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("SunRaysEffect") or fx:IsA("ColorCorrectionEffect") or fx:IsA("DepthOfFieldEffect") then
                if fx.Enabled then
                    hiddenPostFx[fx] = true
                    fx.Enabled = false
                end
            end
        end

        -- Format existing parts in Workspace
        for _, obj in ipairs(Workspace:GetDescendants()) do
            formatPartPotato(obj)
        end

        -- Stream-in hook for new map chunks
        if potatoConn then potatoConn:Disconnect() end
        potatoConn = Workspace.DescendantAdded:Connect(function(child)
            if self.PotatoEnabled then
                formatPartPotato(child)
            end
        end)
    end)
end

function PerfBooster:DisablePotato()
    if not self.PotatoEnabled then return end
    self.PotatoEnabled = false

    pcall(function()
        if potatoConn then potatoConn:Disconnect(); potatoConn = nil end

        -- Restore part materials and reflectance
        for part, data in pairs(potatoBackups) do
            if part and part.Parent then
                if data.Material then part.Material = data.Material end
                if data.Reflectance then part.Reflectance = data.Reflectance end
                if data.TextureID and part:IsA("MeshPart") then part.TextureID = data.TextureID end
            end
        end
        potatoBackups = {}

        -- Restore textures and decals
        for inst, data in pairs(hiddenTextures) do
            if inst and inst.Parent then
                if data.Transparency then inst.Transparency = data.Transparency end
                if data.Texture then inst.Texture = data.Texture end
            end
            if data.Parent and inst:IsA("SurfaceAppearance") then
                inst.Parent = data.Parent
            end
        end
        hiddenTextures = {}

        -- Restore post-processing lighting shaders
        for fx, _ in pairs(hiddenPostFx) do
            if fx and fx.Parent then
                fx.Enabled = true
            end
        end
        hiddenPostFx = {}
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
