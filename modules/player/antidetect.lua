-- Leon X | AntiDetect v7.3 — Zero-Hook Anti-Adonis
-- v7.2 still kicked because hookfunction itself is detected by Adonis integrity scan.
-- Every hookfunction call (checkcaller, isexecutorclosure, debug.getinfo, lp.Kick)
-- modifies Roblox functions that Adonis verifies during initialization.
--
-- v7.3 STRATEGY: ZERO hookfunction, ZERO hookmetamethod
--   ONLY destroys Adonis detection scripts as they appear.
--   Does NOT modify any Roblox function or metatable.
--   Heartbeats flow naturally — no remote interception.

local AntiDetect = {}
AntiDetect.Name    = "AntiDetect"
AntiDetect.Enabled = false

-- Fast local flag
local adEnabled = false

-- State tracking
local gameChildConn = nil

-- ════════════════════════════════════════════════════════════════════════════
-- PATTERNS
-- ════════════════════════════════════════════════════════════════════════════

-- Adonis DETECTION script names (NOT core client or remotes)
local ADONIS_DETECTION_SCRIPTS = {
    "clientcheck", "anticheat", "antiexploit", "antihack",
    "detection", "exploitdetect", "hackdetect", "cheatdetect",
    "integrity", "sanity", "validate",
}

-- Check if a script is an Adonis DETECTION script
local function isDetectionScript(obj)
    if not obj:IsA("LocalScript") and not obj:IsA("ModuleScript") then
        return false
    end
    local lower = obj.Name:lower()
    for _, pattern in ipairs(ADONIS_DETECTION_SCRIPTS) do
        if lower:find(pattern, 1, true) then return true end
    end
    return false
end

-- ════════════════════════════════════════════════════════════════════════════
-- Detection Script Destroyer (ONLY layer — no hooks)
-- ════════════════════════════════════════════════════════════════════════════

local function destroyDetectionScript(obj)
    pcall(function()
        obj.Disabled = true
    end)
    pcall(function()
        obj:Destroy()
    end)
    print("[AntiDetect] Destroyed detection script: " .. tostring(obj.Name))
end

local function enableScriptFilter()
    -- Initial ONE-TIME scan (runs once at enable, then never again)
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if isDetectionScript(obj) then
                destroyDetectionScript(obj)
            end
        end
    end)

    -- Monitor for new detection scripts (zero FPS impact — event-driven)
    if gameChildConn then gameChildConn:Disconnect() end
    gameChildConn = game.DescendantAdded:Connect(function(obj)
        if not adEnabled then return end
        if isDetectionScript(obj) then
            destroyDetectionScript(obj)
        end
    end)

    -- NO periodic sweep — DescendantAdded catches everything
    print("[AntiDetect] Script filter active (event-driven, zero sweep)")
end

-- ════════════════════════════════════════════════════════════════════════════
-- Public API
-- ════════════════════════════════════════════════════════════════════════════

function AntiDetect:Enable()
    if self.Enabled then return end
    self.Enabled = true
    adEnabled = true

    print("[AntiDetect] Enabling v7.3 — zero-hook bypass")

    -- Only layer: destroy detection scripts
    enableScriptFilter()

    print("[AntiDetect] Active (script destroyer only, no hooks)")
end

function AntiDetect:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    adEnabled = false

    if gameChildConn then gameChildConn:Disconnect(); gameChildConn = nil end
end

function AntiDetect:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

-- Teleport bridge for ServerHop/Rejoin
function AntiDetect:AllowTeleport()
    _G._LeonX_AllowTeleportActive = true
end

function AntiDetect:BlockTeleport()
    _G._LeonX_AllowTeleportActive = false
end

_G._LeonX_AllowTeleport = function(allow)
    _G._LeonX_AllowTeleportActive = allow and true or false
end

return AntiDetect
