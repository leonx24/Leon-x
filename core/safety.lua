-- Leon X | Safety & Anti-Detection Utilities
-- Centralized error handling and anti-cheat bypass helpers

local Safety = {}

-- Services must be retrieved locally in each file that loads this
-- These are just placeholders - actual modules should get their own services
local HttpService = game:GetService("HttpService") or error("HttpService not available")

-- ══════════════════════════════════════════════════════════════════════════════
-- ANTI-DETECTION
-- ══════════════════════════════════════════════════════════════════════════════

-- Generate random instance name (GUID-based)
function Safety.RandomName()
    return HttpService:GenerateGUID(false):sub(1, 8)
end

-- Generate random delay to avoid pattern detection (ms)
function Safety.RandomDelay(min, max)
    min = min or 50
    max = max or 150
    return (math.random(min, max)) / 1000
end

-- Safe health value instead of math.huge (less obvious to anti-cheat)
Safety.SAFE_MAX_HEALTH = 9999

-- ══════════════════════════════════════════════════════════════════════════════
-- ERROR HANDLING
-- ══════════════════════════════════════════════════════════════════════════════

-- Safe wrapper for any function - returns (success, result)
function Safety.Try(fn, ...)
    local args = {...}
    local success, result = pcall(function()
        return fn(table.unpack(args))
    end)
    return success, result
end

-- Safe wrapper that suppresses errors silently
function Safety.Silent(fn, ...)
    pcall(fn, ...)
end

-- Safe wrapper with fallback value on error
function Safety.TryOr(fallback, fn, ...)
    local success, result = Safety.Try(fn, ...)
    if success then return result else return fallback end
end

-- Safe disconnect for connections
function Safety.Disconnect(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
end

-- Safe destroy for instances
function Safety.Destroy(instance)
    if instance then
        pcall(function() instance:Destroy() end)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CHARACTER HELPERS
-- ══════════════════════════════════════════════════════════════════════════════

-- Safely get player's character
function Safety.GetCharacter(player)
    local success, char = pcall(function()
        return player.Character
    end)
    return success and char or nil
end

-- Safely get HumanoidRootPart
function Safety.GetHRP(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Safely get Humanoid
function Safety.GetHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- Get both HRP and Humanoid (returns hrp, hum)
function Safety.GetCharacterParts(player)
    local char = Safety.GetCharacter(player)
    if not char then return nil, nil end
    return Safety.GetHRP(char), Safety.GetHumanoid(char)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CONNECTION CLEANUP
-- ══════════════════════════════════════════════════════════════════════════════

-- Cleanup array of connections
function Safety.CleanupConnections(connArray)
    if not connArray then return end
    for _, conn in ipairs(connArray) do
        Safety.Disconnect(conn)
    end
    -- Clear array
    for i = #connArray, 1, -1 do
        connArray[i] = nil
    end
end

-- Cleanup single or array of connections, returns nil (for reassignment)
function Safety.CleanupAny(conn)
    if not conn then return nil end
    if type(conn) == "table" then
        Safety.CleanupConnections(conn)
    else
        Safety.Disconnect(conn)
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- RESPAWN HANDLER
-- ══════════════════════════════════════════════════════════════════════════════

-- Create a respawn-safe module wrapper
-- onEnable: function(char) called when character spawns
-- onDisable: function() called when character dies or module disabled
function Safety.RespawnHandler(player, onEnable, onDisable)
    local enabled = false
    local currentConn = nil
    local charConn = nil

    local handler = {}

    function handler:Enable()
        if enabled then return end
        enabled = true

        -- Apply to current character
        local char = Safety.GetCharacter(player)
        if char then
            Safety.Try(onEnable, char)
        end

        -- Setup respawn listener
        charConn = player.CharacterAdded:Connect(function(char)
            task.wait(Safety.RandomDelay(100, 300))
            if enabled then
                Safety.Try(onEnable, char)
            end
        end)

        -- Setup death listener
        if char then
            currentConn = char.AncestryChanged:Connect(function()
                if not char.Parent and enabled then
                    Safety.Try(onDisable)
                end
            end)
        end
    end

    function handler:Disable()
        enabled = false
        Safety.Try(onDisable)
        currentConn = Safety.CleanupAny(currentConn)
        charConn = Safety.CleanupAny(charConn)
    end

    function handler:IsEnabled()
        return enabled
    end

    return handler
end

return Safety
