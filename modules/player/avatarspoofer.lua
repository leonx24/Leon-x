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
        local realParts = {}
        
        if isR15 then
            realParts = {
                Upper = char:FindFirstChild("RightUpperLeg"),
                Lower = char:FindFirstChild("RightLowerLeg"),
                Foot = char:FindFirstChild("RightFoot")
            }
        else
            realParts = {
                Leg = char:FindFirstChild("Right Leg")
            }
        end
        
        -- Reset transparency of real parts first
        for _, part in pairs(realParts) do
            if part then
                part.Transparency = enabled and 1 or 0
            end
        end

        -- Handle cleaning up old cloned parts
        local old = char:FindFirstChild("RightLegLocal")
        if old then old:Destroy() end

        if not enabled then
            return
        end

        -- Load the Korblox Right Leg asset (Asset ID: 139607718)
        local success, objects = pcall(function()
            return game:GetObjects("rbxassetid://139607718")
        end)
        
        if success and objects and type(objects) == "table" then
            local container = Instance.new("Model")
            container.Name = "RightLegLocal"
            container.Parent = char
            
            for _, obj in ipairs(objects) do
                local function traverse(item)
                    if safeIsA(item, "MeshPart") or safeIsA(item, "Part") then
                        local clone = item:Clone()
                        clone.CanCollide = false
                        clone.Massless = true
                        clone.Parent = container
                        
                        local target = nil
                        if isR15 then
                            local itemName = clone.Name:lower()
                            if itemName:find("upper") then
                                target = realParts.Upper
                            elseif itemName:find("lower") then
                                target = realParts.Lower
                            elseif itemName:find("foot") then
                                target = realParts.Foot
                            end
                        else
                            local itemName = clone.Name:lower()
                            if itemName == "right leg" or itemName == "rightleg" or itemName == "meshpart" or itemName == "part" then
                                target = realParts.Leg
                            end
                        end
                        
                        if target then
                            local weld = Instance.new("Weld")
                            weld.Name = clone.Name .. "Weld"
                            weld.Part0 = target
                            weld.Part1 = clone
                            weld.C0 = CFrame.new(0, 0, 0)
                            weld.Parent = clone
                        else
                            clone:Destroy()
                        end
                    end
                    
                    for _, child in ipairs(item:GetChildren()) do
                        traverse(child)
                    end
                end
                
                traverse(obj)
                pcall(function() obj:Destroy() end)
            end
        else
            warn("[Leon X] AvatarSpoofer: Failed to fetch Korblox Right Leg mesh assets locally")
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
        
        if success and objects and type(objects) == "table" then
            for _, obj in ipairs(objects) do
                local acc = nil
                if safeIsA(obj, "Accessory") then
                    acc = obj
                else
                    pcall(function()
                        acc = obj:FindFirstChildWhichIsA("Accessory")
                    end)
                    if not acc then
                        pcall(function()
                            for _, desc in ipairs(obj:GetDescendants()) do
                                if safeIsA(desc, "Accessory") then
                                    acc = desc
                                    break
                                end
                            end
                        end)
                    end
                end
                
                if acc then
                    -- Extract the accessory so it isn't destroyed when we clean up the wrapper object
                    pcall(function() acc.Parent = nil end)
                    table.insert(EquippedLocalAccessories, acc)
                    pcall(function() humanoid:AddAccessory(acc) end)
                end
                
                -- Destroy the wrapper/loaded object container safely
                pcall(function() obj:Destroy() end)
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
