-- Leon X | AvatarSpoofer
-- Allows local & remote avatar customization (Headless, Korblox leg, Accessories)

local AvatarSpoofer = {}
AvatarSpoofer.Name    = "AvatarSpoofer"
AvatarSpoofer.Enabled = false

-- Sub-settings
AvatarSpoofer.Headless          = false
AvatarSpoofer.KorbloxLeg        = false
AvatarSpoofer.CustomAccessoryId = ""

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService    = game:GetService("InsertService")
local RunService       = game:GetService("RunService")

local lp = Players.LocalPlayer
while not lp do
    task.wait()
    lp = Players.LocalPlayer
end

local Connections = {}
local EquippedLocalAccessories = {}
local OriginalHeadState = {}
local KorbloxContainer = nil -- R15: welded MeshParts container, R6: SpecialMesh override

local function trackConnection(conn)
    if conn then
        table.insert(Connections, conn)
    end
    return conn
end

local function safeIsA(obj, className)
    local ok, res = pcall(function() return obj:IsA(className) end)
    return ok and res
end

-- Scan ReplicatedStorage for any RemoteEvent that looks like a catalog wearer/customizer
local function findAvatarRemotes()
    local remotes = {}
    local descendants = {}
    pcall(function() descendants = ReplicatedStorage:GetDescendants() end)
    
    for _, desc in ipairs(descendants) do
        if safeIsA(desc, "RemoteEvent") or safeIsA(desc, "RemoteFunction") then
            local name = desc.Name:lower()
            if name:find("accessory") or name:find("wear") or name:find("equip") or name:find("avatar") or name:find("catalog") or name:find("headless") or name:find("korblox") then
                table.insert(remotes, desc)
            end
        end
    end
    return remotes
end

-- Try to replicate avatar customization to the server via game RemoteEvents
local function tryServerReplicate(assetId, customType)
    local remotes = findAvatarRemotes()
    if #remotes == 0 then return false end
    
    for _, remote in ipairs(remotes) do
        pcall(function()
            if safeIsA(remote, "RemoteEvent") then
                if customType == "Accessory" and assetId then
                    remote:FireServer(assetId)
                    remote:FireServer("Wear", assetId)
                    remote:FireServer({Type = "Accessory", Id = assetId})
                elseif customType == "Headless" then
                    remote:FireServer("Headless")
                    remote:FireServer({Type = "Headless"})
                elseif customType == "Korblox" then
                    remote:FireServer("Korblox")
                    remote:FireServer({Type = "Korblox"})
                end
            end
        end)
    end
    return true
end

-- Apply headless (transparent head + hide face decal)
local function applyHeadless(char, enabled)
    if not char then return end
    
    pcall(function()
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        if enabled then
            -- Store original state
            if not OriginalHeadState.Transparency then
                OriginalHeadState.Transparency = head.Transparency
            end
            head.Transparency = 1
            
            local face = head:FindFirstChildOfClass("Decal")
            if face then
                if not OriginalHeadState.FaceTexture then
                    OriginalHeadState.FaceTexture = face.Texture
                    OriginalHeadState.FaceEnabled = face.Enabled
                end
                face.Enabled = false
            end
            
            -- Also hide any MeshPart head (R15 uses MeshPart heads sometimes)
            for _, child in ipairs(char:GetChildren()) do
                if child.Name == "Head" and safeIsA(child, "MeshPart") then
                    if not OriginalHeadState.MeshTransparency then
                        OriginalHeadState.MeshTransparency = child.Transparency
                    end
                    child.Transparency = 1
                end
            end
        else
            -- Revert
            if OriginalHeadState.Transparency then
                head.Transparency = OriginalHeadState.Transparency
            else
                head.Transparency = 0
            end
            
            local face = head:FindFirstChildOfClass("Decal")
            if face and OriginalHeadState.FaceTexture then
                face.Texture = OriginalHeadState.FaceTexture
                face.Enabled = OriginalHeadState.FaceEnabled
                OriginalHeadState.FaceTexture = nil
                OriginalHeadState.FaceEnabled = nil
            elseif face then
                face.Enabled = true
            end
            
            if OriginalHeadState.MeshTransparency then
                for _, child in ipairs(char:GetChildren()) do
                    if child.Name == "Head" and safeIsA(child, "MeshPart") then
                        child.Transparency = OriginalHeadState.MeshTransparency
                    end
                end
            end
            
            table.clear(OriginalHeadState)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- KORBLOX LEG
-- Both R15 and R6 use Part + SpecialMesh (FileMesh) approach.
-- Instance.new("MeshPart") does NOT render custom MeshId on client,
-- so we use a regular Part with a SpecialMesh child instead.
-- R15: Hide all 3 right leg parts, place one Korblox mesh welded to RightUpperLeg
-- R6:  Insert SpecialMesh directly into the existing "Right Leg" Part.
-- ═══════════════════════════════════════════════════════════════

-- Korblox R6/R15 mesh and texture IDs (community-verified working IDs)
local KORBLOX_MESH    = "rbxassetid://101851696"
local KORBLOX_TEXTURE = "rbxassetid://101851254"

local OriginalLegColor = nil
local OriginalLegMaterial = nil
local korbloxRenderConn = nil -- RenderStepped connection for R15 overlay positioning

local function applyKorbloxLeg(char, enabled)
    if not char then return end
    
    -- Clean up any previous Korblox overlay + RenderStepped connection
    pcall(function()
        if korbloxRenderConn then
            korbloxRenderConn:Disconnect()
            korbloxRenderConn = nil
        end
    end)
    pcall(function()
        local old = char:FindFirstChild("_KorbloxOverlay")
        if old then old:Destroy() end
    end)
    pcall(function()
        -- Also check workspace for anchored overlays
        local oldWs = workspace:FindFirstChild("_KorbloxOverlay_" .. lp.UserId)
        if oldWs then oldWs:Destroy() end
    end)
    pcall(function()
        local rightLeg = char:FindFirstChild("Right Leg")
        if rightLeg then
            local oldMesh = rightLeg:FindFirstChild("_KorbloxMesh")
            if oldMesh then oldMesh:Destroy() end
        end
    end)
    
    local isR15 = char:FindFirstChild("RightUpperLeg") ~= nil
    local R15_PARTS = {"RightUpperLeg", "RightLowerLeg", "RightFoot"}
    
    if not enabled then
        if isR15 then
            for _, name in ipairs(R15_PARTS) do
                pcall(function()
                    local part = char:FindFirstChild(name)
                    if part then part.Transparency = 0 end
                end)
            end
        else
            pcall(function()
                local leg = char:FindFirstChild("Right Leg")
                if leg then
                    local sm = leg:FindFirstChild("_KorbloxMesh")
                    if sm then sm:Destroy() end
                    if OriginalLegColor then
                        leg.Color = OriginalLegColor
                        OriginalLegColor = nil
                    end
                    if OriginalLegMaterial then
                        leg.Material = OriginalLegMaterial
                        OriginalLegMaterial = nil
                    end
                end
            end)
        end
        return
    end
    
    -- ENABLED
    if isR15 then
        pcall(function()
            -- Hide all 3 right leg R15 parts
            for _, name in ipairs(R15_PARTS) do
                local part = char:FindFirstChild(name)
                if part then part.Transparency = 1 end
            end
            
            local upperLeg = char:FindFirstChild("RightUpperLeg")
            if not upperLeg then return end
            
            -- Create Anchored overlay in workspace (NO physics interaction with character)
            local overlay = Instance.new("Part")
            overlay.Name = "_KorbloxOverlay_" .. lp.UserId
            overlay.Size = Vector3.new(1, 1, 1)
            overlay.Color = Color3.fromRGB(17, 17, 17)
            overlay.Material = Enum.Material.SmoothPlastic
            overlay.CanCollide = false
            overlay.CanTouch = false
            overlay.CanQuery = false
            overlay.Anchored = true  -- Anchored = no physics at all
            overlay.Transparency = 0
            overlay.CastShadow = false
            overlay.Parent = workspace  -- Parent to workspace, NOT character
            
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = KORBLOX_MESH
            mesh.TextureId = KORBLOX_TEXTURE
            mesh.Scale = Vector3.new(1.05, 1.05, 1.05)
            mesh.Parent = overlay
            
            -- Position the overlay every frame using RenderStepped (zero physics)
            overlay.CFrame = upperLeg.CFrame * CFrame.new(0, -0.5, 0)
            korbloxRenderConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    if not overlay or not overlay.Parent then
                        if korbloxRenderConn then
                            korbloxRenderConn:Disconnect()
                            korbloxRenderConn = nil
                        end
                        return
                    end
                    local ul = char and char:FindFirstChild("RightUpperLeg")
                    if ul then
                        overlay.CFrame = ul.CFrame * CFrame.new(0, -0.5, 0)
                    end
                end)
            end)
            trackConnection(korbloxRenderConn)
        end)
    else
        -- R6: Insert SpecialMesh directly into the "Right Leg" Part
        pcall(function()
            local rightLeg = char:FindFirstChild("Right Leg")
            if rightLeg then
                if not OriginalLegColor then
                    OriginalLegColor = rightLeg.Color
                    OriginalLegMaterial = rightLeg.Material
                end
                
                -- Remove any existing SpecialMesh to prevent layering
                for _, child in ipairs(rightLeg:GetChildren()) do
                    if safeIsA(child, "SpecialMesh") or safeIsA(child, "CharacterMesh") then
                        pcall(function() child:Destroy() end)
                    end
                end
                
                local mesh = Instance.new("SpecialMesh")
                mesh.Name = "_KorbloxMesh"
                mesh.MeshType = Enum.MeshType.FileMesh
                mesh.MeshId = KORBLOX_MESH
                mesh.TextureId = KORBLOX_TEXTURE
                mesh.Scale = Vector3.new(1, 1, 1)
                mesh.Parent = rightLeg
                
                rightLeg.Color = Color3.fromRGB(17, 17, 17)
                rightLeg.Material = Enum.Material.SmoothPlastic
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- WEAR ACCESSORY
-- Strategy: Try InsertService:LoadAsset first (works on many executors
-- at elevated privilege). If that fails, fall back to game:GetObjects.
-- If Humanoid:AddAccessory doesn't attach properly, manually weld
-- the Handle to the character's Head.
-- ═══════════════════════════════════════════════════════════════

local function manualWeldAccessory(acc, char)
    -- Humanoid:AddAccessory can fail on client. Manually weld Handle to Head.
    pcall(function()
        local handle = acc:FindFirstChild("Handle")
        if not handle then return end
        
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        -- Read attachment info from the accessory
        local accAttach = handle:FindFirstChildOfClass("Attachment")
        local headAttach = nil
        
        if accAttach then
            -- Find matching attachment on character
            headAttach = head:FindFirstChild(accAttach.Name)
            if not headAttach then
                -- Search all character parts for the matching attachment
                for _, part in ipairs(char:GetChildren()) do
                    if safeIsA(part, "BasePart") then
                        local a = part:FindFirstChild(accAttach.Name)
                        if a and safeIsA(a, "Attachment") then
                            headAttach = a
                            head = part -- weld to this part instead
                            break
                        end
                    end
                end
            end
        end
        
        acc.Parent = char
        handle.CanCollide = false
        handle.Massless = true
        handle.Anchored = false
        
        if headAttach and accAttach then
            -- Use attachment-based positioning
            local weld = Instance.new("Weld")
            weld.Name = "AccessoryWeld"
            weld.Part0 = head
            weld.Part1 = handle
            weld.C0 = headAttach.CFrame
            weld.C1 = accAttach.CFrame
            weld.Parent = handle
        else
            -- Fallback: weld directly on top of head
            local weld = Instance.new("Weld")
            weld.Name = "AccessoryWeld"
            weld.Part0 = head
            weld.Part1 = handle
            weld.C0 = CFrame.new(0, head.Size.Y / 2, 0) -- Top of head
            weld.C1 = CFrame.new()
            weld.Parent = handle
        end
    end)
end

local function loadAssetObjects(assetId)
    -- Method 1: InsertService:LoadAsset (works on many executors at high context level)
    local ok1, model = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)
    if ok1 and model then
        return {model}
    end
    
    -- Method 2: game:GetObjects
    local ok2, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))
    end)
    if ok2 and objects and type(objects) == "table" and #objects > 0 then
        return objects
    end
    
    return nil
end

-- Strip animations, scripts, and other non-visual junk from an asset to prevent errors
local function stripNonVisual(obj)
    pcall(function()
        for _, desc in ipairs(obj:GetDescendants()) do
            local shouldRemove = false
            pcall(function()
                shouldRemove = desc:IsA("Animation") or desc:IsA("AnimationController") 
                    or desc:IsA("Animator") or desc:IsA("Script") 
                    or desc:IsA("LocalScript") or desc:IsA("ModuleScript")
            end)
            if shouldRemove then
                pcall(function() desc:Destroy() end)
            end
        end
    end)
end

local function findAccessoryInObjects(objects)
    for _, obj in ipairs(objects) do
        -- Direct accessory
        if safeIsA(obj, "Accessory") then
            return obj, nil
        end
        -- Child accessory
        local acc = nil
        pcall(function() acc = obj:FindFirstChildWhichIsA("Accessory") end)
        if acc then return acc, obj end
        -- Deep search
        pcall(function()
            for _, desc in ipairs(obj:GetDescendants()) do
                if safeIsA(desc, "Accessory") then
                    acc = desc
                    break
                end
            end
        end)
        if acc then return acc, obj end
        -- If obj itself has a Handle (some assets are raw accessory-like models)
        pcall(function()
            local handle = obj:FindFirstChild("Handle")
            if handle and safeIsA(handle, "BasePart") then
                -- Wrap it in an Accessory
                local wrapper = Instance.new("Accessory")
                wrapper.Name = obj.Name
                handle.Parent = wrapper
                acc = wrapper
            end
        end)
        if acc then return acc, obj end
    end
    return nil, nil
end

local function wearAccessoryLocal(accessoryId)
    local char = lp.Character
    if not char then
        warn("[Leon X] AvatarSpoofer: No character found")
        return
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[Leon X] AvatarSpoofer: No humanoid found")
        return
    end

    task.spawn(function()
        local objects = loadAssetObjects(accessoryId)
        
        if not objects then
            warn("[Leon X] AvatarSpoofer: Failed to load accessory ID " .. tostring(accessoryId) .. " — both InsertService and GetObjects failed")
            return
        end
        
        local acc, container = findAccessoryInObjects(objects)
        
        if acc then
            -- Detach from container if needed
            pcall(function() acc.Parent = nil end)
            
            -- Strip animations/scripts to prevent console errors
            stripNonVisual(acc)
            
            -- ALWAYS use manual welding — Humanoid:AddAccessory silently fails on client
            manualWeldAccessory(acc, char)
            
            -- Verify it attached
            if acc.Parent == char then
                table.insert(EquippedLocalAccessories, acc)
                print("[Leon X] AvatarSpoofer: Equipped accessory " .. tostring(accessoryId))
            else
                -- Last resort: try AddAccessory
                pcall(function()
                    humanoid:AddAccessory(acc)
                end)
                if acc.Parent then
                    table.insert(EquippedLocalAccessories, acc)
                    print("[Leon X] AvatarSpoofer: Equipped accessory (via AddAccessory) " .. tostring(accessoryId))
                else
                    warn("[Leon X] AvatarSpoofer: Accessory loaded but failed to attach " .. tostring(accessoryId))
                end
            end
        else
            warn("[Leon X] AvatarSpoofer: No Accessory found inside asset " .. tostring(accessoryId))
        end
        
        -- Clean up containers
        for _, obj in ipairs(objects) do
            if obj ~= acc then
                pcall(function() obj:Destroy() end)
            end
        end
    end)
end

-- Re-apply all enabled customizations
local function applyCustomizations(char)
    if not char then return end
    
    -- Ensure character is loaded
    char:WaitForChild("Humanoid", 5)
    task.wait(0.5) -- Wait for meshes/textures to finish loading
    
    if AvatarSpoofer.Headless then
        applyHeadless(char, true)
    end
    if AvatarSpoofer.KorbloxLeg then
        applyKorbloxLeg(char, true)
    end
end

function AvatarSpoofer:SetHeadless(enabled)
    self.Headless = enabled
    if not self.Enabled then return end
    
    local char = lp.Character
    if char then
        applyHeadless(char, enabled)
    end
    if enabled then
        tryServerReplicate(nil, "Headless")
    end
end

function AvatarSpoofer:SetKorbloxLeg(enabled)
    self.KorbloxLeg = enabled
    if not self.Enabled then return end
    
    local char = lp.Character
    if char then
        applyKorbloxLeg(char, enabled)
    end
    if enabled then
        tryServerReplicate(nil, "Korblox")
    end
end

function AvatarSpoofer:WearAccessory(accessoryId)
    if not accessoryId or accessoryId == "" then return end
    local idNum = tonumber(accessoryId)
    if not idNum then return end

    self.CustomAccessoryId = tostring(accessoryId)
    if not self.Enabled then return end
    
    -- Replicate to server if possible
    tryServerReplicate(idNum, "Accessory")
    
    -- Always load locally so client sees it immediately
    wearAccessoryLocal(idNum)
end

function AvatarSpoofer:Enable()
    if self.Enabled then return end
    self.Enabled = true

    local char = lp.Character
    if char then
        applyCustomizations(char)
    end

    -- Setup CharacterAdded listener for respawns
    trackConnection(lp.CharacterAdded:Connect(function(newChar)
        applyCustomizations(newChar)
    end))

    -- Trigger server customizer remotes if configurations are active
    if self.Headless then
        tryServerReplicate(nil, "Headless")
    end
    if self.KorbloxLeg then
        tryServerReplicate(nil, "Korblox")
    end

    print("[Leon X] AvatarSpoofer: Enabled — local modifications active")
end

function AvatarSpoofer:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    -- Disconnect CharacterAdded connection
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    -- Revert headless and Korblox edits on the current character
    local char = lp.Character
    if char then
        applyHeadless(char, false)
        applyKorbloxLeg(char, false)
    end

    -- Destroy all custom accessories loaded locally during the session
    for _, acc in ipairs(EquippedLocalAccessories) do
        pcall(function()
            if acc and acc.Parent then
                acc:Destroy()
            end
        end)
    end
    table.clear(EquippedLocalAccessories)

    print("[Leon X] AvatarSpoofer: Disabled — custom styles removed")
end

function AvatarSpoofer:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return AvatarSpoofer
