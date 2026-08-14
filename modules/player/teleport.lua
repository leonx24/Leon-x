-- Leon X | Teleport
-- Save position, goto saved, teleport to player
-- Robust player lookup: matches both Name and DisplayName

local Teleport = {}
Teleport.Name      = "Teleport"
Teleport.SavedCFrame = nil

local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

function Teleport:SavePosition()
    local char = lp.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    self.SavedCFrame = hrp.CFrame
    local p = hrp.Position
    pcall(function()
        setclipboard(("%.1f, %.1f, %.1f"):format(p.X, p.Y, p.Z))
    end)
    return p
end

function Teleport:GotoSaved(flyModule)
    if not self.SavedCFrame then return false end
    local char = lp.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local wasFlying = flyModule and flyModule.Enabled
    if wasFlying then flyModule:Disable() end
    hrp.CFrame = self.SavedCFrame
    task.wait(0.1)
    if wasFlying then flyModule:Enable() end
    return true
end

-- Robust player finder: tries FindFirstChild, then loops through all players
-- matching by Name or DisplayName (case-insensitive)
local function findPlayer(name)
    if not name or name == "" then return nil end

    -- Try exact FindFirstChild first (fastest)
    local exact = Players:FindFirstChild(name)
    if exact and exact:IsA("Player") then return exact end

    -- Loop through all players, match Name or DisplayName
    local nameLower = name:lower()
    local bestMatch = nil
    local bestScore = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            -- Exact Name match (case-insensitive)
            if player.Name:lower() == nameLower then
                return player
            end

            -- Exact DisplayName match (case-insensitive)
            if player.DisplayName:lower() == nameLower then
                return player
            end

            -- Partial match (prefix)
            if player.Name:lower():sub(1, #nameLower) == nameLower then
                local score = #nameLower / #player.Name
                if score > bestScore then
                    bestScore = score
                    bestMatch = player
                end
            end
            if player.DisplayName:lower():sub(1, #nameLower) == nameLower then
                local score = #nameLower / #player.DisplayName
                if score > bestScore then
                    bestScore = score
                    bestMatch = player
                end
            end
        end
    end

    return bestMatch
end

function Teleport:ToPlayer(name, flyModule)
    local target = findPlayer(name)
    if not target then return false, "left" end
    if not target.Character then return false, "nochar" end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local char  = lp.Character
    if not tHRP or not char then return false, "nochar" end
    local mHRP = char:FindFirstChild("HumanoidRootPart")
    if not mHRP then return false, "nochar" end
    local wasFlying = flyModule and flyModule.Enabled
    if wasFlying then flyModule:Disable() end
    mHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
    task.wait(0.1)
    if wasFlying then flyModule:Enable() end
    return true
end

function Teleport:GetPlayerList()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            -- Show "DisplayName (@Username)" for clarity
            if p.DisplayName ~= p.Name then
                t[#t+1] = p.DisplayName .. " (@" .. p.Name .. ")"
            else
                t[#t+1] = p.Name
            end
        end
    end
    return #t > 0 and t or {"(no players)"}
end

-- Extract the actual username from a formatted display string like "DisplayName (@Username)"
function Teleport:ExtractName(displayStr)
    if not displayStr then return nil end
    -- Check for "DisplayName (@Username)" format
    local username = displayStr:match("@(.+)%)$")
    if username then return username end
    -- Otherwise it's just the plain name
    return displayStr
end

return Teleport
