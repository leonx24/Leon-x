-- Leon X | Fling/Anti-Fling Scanner
-- Run this in Just Baseplate to gather info about fling mechanics
-- Output saved to: LeonX/fling_scan_results.txt

local output = {}
local function log(text)
    table.insert(output, text)
    print(text)
end

log("=== LEON X FLING/ANTI-FLING SCANNER ===")
log("Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
log("PlaceId: " .. game.PlaceId)
log("Time: " .. os.date())
log("")

-- 1. Scan for BodyMovers in workspace
log("=== 1. BODYMOVERS IN WORKSPACE ===")
local bodyMoverCount = 0
for _, v in ipairs(workspace:GetDescendants()) do
    if v:IsA("BodyVelocity") or v:IsA("VectorForce") or v:IsA("BodyForce") 
    or v:IsA("BodyPosition") or v:IsA("BodyGyro") or v:IsA("BodyThrust")
    or v:IsA("LinearVelocity") then
        bodyMoverCount = bodyMoverCount + 1
        local parentName = v.Parent and v.Parent.Name or "nil"
        local grandparent = v.Parent and v.Parent.Parent and v.Parent.Parent.Name or "nil"
        log("  " .. v.ClassName .. " | Parent: " .. parentName .. " | GP: " .. grandparent)
        
        -- Get properties
        if v:IsA("BodyVelocity") then
            log("    Velocity: " .. tostring(v.Velocity) .. " | MaxForce: " .. tostring(v.MaxForce))
        elseif v:IsA("VectorForce") then
            log("    Force: " .. tostring(v.Force))
        end
    end
end
if bodyMoverCount == 0 then
    log("  (none found)")
end
log("")

-- 2. Scan player backpack tools
log("=== 2. TOOLS IN BACKPACK ===")
local lp = game.Players.LocalPlayer
for _, tool in ipairs(lp.Backpack:GetChildren()) do
    if tool:IsA("Tool") then
        log("  Tool: " .. tool.Name)
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
                log("    Script: " .. v.Name .. " (" .. v.ClassName .. ")")
            end
            if v:IsA("BodyVelocity") or v:IsA("VectorForce") then
                log("    BodyMover: " .. v.ClassName)
            end
        end
    end
end
log("")

-- 3. Scan equipped tools
log("=== 3. EQUIPPED TOOLS ===")
local char = lp.Character
if char then
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            log("  Equipped: " .. tool.Name)
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("Script") or v:IsA("LocalScript") then
                    log("    Script: " .. v.Name)
                end
            end
        end
    end
end
log("")

-- 4. Scan remotes in ReplicatedStorage
log("=== 4. REMOTES (FLING/KICK/HIT RELATED) ===")
local remotes = {}
for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        local name = v.Name:lower()
        if string.find(name, "fling") or string.find(name, "kick") 
        or string.find(name, "hit") or string.find(name, "damage")
        or string.find(name, "push") or string.find(name, "force")
        or string.find(name, "attack") then
            table.insert(remotes, v:GetFullName())
            log("  " .. v.ClassName .. ": " .. v:GetFullName())
        end
    end
end
if #remotes == 0 then
    log("  (no fling-related remotes found)")
end
log("")

-- 5. Scan all remotes (full list)
log("=== 5. ALL REMOTES IN REPLICATEDSTORAGE ===")
for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        log("  " .. v.ClassName .. ": " .. v:GetFullName())
    end
end
log("")

-- 6. Check for anti-fling scripts
log("=== 6. PLAYER SCRIPTS (ANTI-FLING RELATED) ===")
for _, v in ipairs(lp.PlayerScripts:GetDescendants()) do
    if v:IsA("LocalScript") or v:IsA("Script") then
        local name = v.Name:lower()
        if string.find(name, "fling") or string.find(name, "anti") 
        or string.find(name, "velocity") or string.find(name, "protection") then
            log("  " .. v.ClassName .. ": " .. v:GetFullName())
        end
    end
end
log("")

-- 7. All LocalScripts in PlayerScripts
log("=== 7. ALL LOCALSCRIPTS IN PLAYERSCRIPTS ===")
for _, v in ipairs(lp.PlayerScripts:GetDescendants()) do
    if v:IsA("LocalScript") then
        log("  " .. v:GetFullName())
    end
end
log("")

-- 8. Check StarterPlayerScripts
log("=== 8. STARTERPLAYER SCRIPTS ===")
for _, v in ipairs(game:GetService("StarterPlayer"):GetDescendants()) do
    if v:IsA("LocalScript") or v:IsA("Script") then
        log("  " .. v.ClassName .. ": " .. v:GetFullName())
    end
end
log("")

-- 9. Check for velocity on own character
log("=== 9. CHARACTER PHYSICS INFO ===")
if char then
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        log("  HRP Position: " .. tostring(hrp.Position))
        log("  HRP Velocity: " .. tostring(hrp.AssemblyLinearVelocity))
        log("  HRP Mass: " .. tostring(hrp.AssemblyMass))
        log("  HRP CustomPhysicalProperties: " .. tostring(hrp.CustomPhysicalProperties))
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        log("  Humanoid Health: " .. hum.Health)
        log("  Humanoid WalkSpeed: " .. hum.WalkSpeed)
        log("  Humanoid State: " .. tostring(hum:GetState()))
    end
end
log("")

-- 10. Check workspace for fling-related parts
log("=== 10. FLING-RELATED PARTS IN WORKSPACE ===")
for _, v in ipairs(workspace:GetDescendants()) do
    if v:IsA("BasePart") then
        local name = v.Name:lower()
        if string.find(name, "fling") or string.find(name, "kick") 
        or string.find(name, "push") or string.find(name, "launcher") then
            log("  Part: " .. v:GetFullName())
            log("    Position: " .. tostring(v.Position))
        end
    end
end
log("")

-- 11. Save to file
local filename = "LeonX/fling_scan_results.txt"
local content = table.concat(output, "\n")
writefile(filename, content)

log("=== SCAN COMPLETE ===")
log("Results saved to: " .. filename)
log("Open the file to see all results!")
