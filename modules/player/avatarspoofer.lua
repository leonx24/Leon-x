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
local JointsService    = game:GetService("JointsService")

local lp = Players.LocalPlayer
while not lp do
    task.wait()
    lp = Players.LocalPlayer
end

local Connections = {}
local EquippedLocalAccessories = {}
local OriginalHeadState = {}
local OriginalLegState = {}

local function trackConnection(conn)
    if conn then
        table.insert(Connections, conn)
    end
    return conn
end

-- Helper to safely call Roblox methods without yielding/errors
local function safeCall(fn, ...)
    local args = {...}
    local ok, res = pcall(function() return fn(unpack(args)) end)
    return ok, res
end

-- Scan ReplicatedStorage for any RemoteEvent that looks like a catalog wearer/customizer
local function findAvatarRemotes()
    local remotes = {}
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            local name = desc.Name:lower()
            -- Match keywords commonly used in customizer remotes in hangout/mountain games
            if name:find("accessory") or name:find("wear") or name:find("equip") or name:find("avatar") or name:find("catalog") or name:find("headless") or name:find("korblox") then
                table.insert(remotes, desc)
            end
        end
    end
    return remotes
end

-- Replicate wear event to server if custom catalog remotes exist in the game
local function tryServerReplicate(assetId, customType)
    local remotes = findAvatarRemotes()
    local fired = false
    
    for _, remote in ipairs(remotes) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                -- Try typical payloads: (id), (type, id), (player, id), (type, name)
                if customType == "Headless" then
                    remote:FireServer(customType)
                    remote:FireServer("headless")
                    remote:FireServer(201307985) -- Headless Horseman bundle ID
                elseif customType == "Korblox" then
                    remote:FireServer(customType)
                    remote:FireServer("korblox")
                    remote:FireServer(139628042) -- Korblox leg package ID
                else
                    remote:FireServer(assetId)
                    remote:FireServer("Accessory", assetId)
                    remote:FireServer(tostring(assetId))
                end
                fired = true
            elseif remote:IsA("RemoteFunction") then
                task.spawn(function()
                    if customType == "Headless" then
                        remote:InvokeServer("headless")
                        remote:InvokeServer(201307985)
                    elseif customType == "Korblox" then
                        remote:InvokeServer("korblox")
                        remote:InvokeServer(139628042)
                    else
                        remote:InvokeServer(assetId)
                        remote:InvokeServer("Accessory", assetId)
                    end
                end)
                fired = true
            end
        end)
    end
    
    return fired
end

-- Apply local Headless head (Transparency = 1, hide face)
local function applyHeadless(char, enabled)
    if not char then return end
    local head = char:WaitForChild("Head", 2)
    if not head then return end
    
    pcall(function()
        if enabled then
            -- Store original state if not stored
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
        else
            -- Restore original state
            if OriginalHeadState.Transparency then
                head.Transparency = OriginalHeadState.Transparency
                OriginalHeadState.Transparency = nil
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
        end
    end)
end

-- Apply local Korblox Right Leg mesh (swaps R15 mesh properties, or welds custom R6 mesh part)
local function applyKorbloxLeg(char, enabled)
    if not char then return end
    
    pcall(function()
        local isR15 = char:FindFirstChild("RightUpperLeg") ~= nil
        if isR15 then
            local upper = char:FindFirstChild("RightUpperLeg")
            local lower = char:FindFirstChild("RightLowerLeg")
            local foot = char:FindFirstChild("RightFoot")
            
            if enabled then
                -- Store original mesh IDs
                if upper and not OriginalLegState.UpperMesh then
                    OriginalLegState.UpperMesh = upper.MeshId
                    OriginalLegState.UpperTexture = upper.TextureID
                end
                if lower and not OriginalLegState.LowerMesh then
                    OriginalLegState.LowerMesh = lower.MeshId
                    OriginalLegState.LowerTexture = lower.TextureID
                end
                if foot and not OriginalLegState.FootMesh then
                    OriginalLegState.FootMesh = foot.MeshId
                    OriginalLegState.FootTexture = foot.TextureID
                end
                
                -- Swap to Korblox R15 meshes
                if upper then
                    upper.MeshId = "rbxassetid://9029193798"
                    upper.TextureID = ""
                end
                if lower then
                    lower.MeshId = "rbxassetid://9029194200"
                    lower.TextureID = ""
                end
                if foot then
                    foot.MeshId = "rbxassetid://9029194553"
                    foot.TextureID = ""
                end
            else
                -- Revert to original meshes
                if upper and OriginalLegState.UpperMesh then
                    upper.MeshId = OriginalLegState.UpperMesh
                    upper.TextureID = OriginalLegState.UpperTexture
                end
                if lower and OriginalLegState.LowerMesh then
                    lower.MeshId = OriginalLegState.LowerMesh
                    lower.TextureID = OriginalLegState.LowerTexture
                end
                if foot and OriginalLegState.FootMesh then
                    foot.MeshId = OriginalLegState.FootMesh
                    foot.TextureID = OriginalLegState.FootTexture
                end
                
                table.clear(OriginalLegState)
            end
        else
            -- R6 Rig Character
            local rightLeg = char:FindFirstChild("Right Leg")
            if not rightLeg then return end
            
            if enabled then
                rightLeg.Transparency = 1
                
                -- Spawn local Korblox mesh model and weld it
                local existing = char:FindFirstChild("KorbloxLegLocal")
                if not existing then
                    local leg = Instance.new("MeshPart")
                    leg.Name = "KorbloxLegLocal"
                    leg.MeshId = "rbxassetid://139628042"
                    leg.Size = Vector3.new(1.1, 2.1, 1.1)
                    leg.CanCollide = false
                    leg.Massless = true
                    leg.Parent = char
                    
                    local weld = Instance.new("Weld")
                    weld.Name = "KorbloxWeld"
                    weld.Part0 = rightLeg
                    weld.Part1 = leg
                    weld.C0 = CFrame.new(0, 0.05, 0)
                    weld.Parent = leg
                end
            else
                rightLeg.Transparency = 0
                local existing = char:FindFirstChild("KorbloxLegLocal")
                if existing then
                    existing:Destroy()
                end
            end
        end
    end)
end

-- Wear a catalog accessory locally using game:GetObjects
local function wearAccessoryLocal(accessoryId)
    local char = lp.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    task.spawn(function()
        -- Load asset using game:GetObjects (standard for exploits, bypasses InsertService limits)
        local success, objects = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(accessoryId))
        end)
        
        if success and objects and objects[1] then
            local asset = objects[1]
            local toEquip = nil
            
            if asset:IsA("Accessory") then
                toEquip = asset
            elseif asset:IsA("Model") then
                toEquip = asset:FindFirstChildWhichIsA("Accessory")
            end
            
            if toEquip then
                -- Track to allow dynamic deletion on disable
                table.insert(EquippedLocalAccessories, toEquip)
                humanoid:AddAccessory(toEquip)
            else
                asset:Destroy()
            end
        else
            warn("[Leon X] AvatarSpoofer: Failed to load accessory ID " .. tostring(accessoryId))
        end
    end)
end

-- Re-apply all enabled customizations
local function applyCustomizations(char)
    if not char then return end
    
    -- Ensure character is loaded
    char:WaitForChild("Humanoid", 5)
    task.wait(0.2) -- Safe brief wait for textures/meshes to finalize loading
    
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
    local replicated = tryServerReplicate(idNum, "Accessory")
    
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
