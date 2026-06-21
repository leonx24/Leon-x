-- Leon X | AntiDetect v7.2 — Lightweight Anti-Adonis
-- v7.1 FROZE at splash because:
--   1. getfenv hook copied environment tables → broke WindUI library loading
--   2. hookfunction(remote.FireServer) → unstable on many executors
--
-- v7.2 STRATEGY (based on Adonis source: most detections are OFF):
--   CheckClients = true (heartbeat only — MUST flow, don't touch remotes)
--   All other detections = false (no client-side checks to block)
--
-- WHAT WE DO:
--   1. Hook checkcaller/isexecutorclosure (hide executor from any future checks)
--   2. Hook debug.getinfo (hide executor stack frames)
--   3. Destroy Adonis detection scripts as they appear
--   4. Hook Player:Kick as last-resort backup
-- WHAT WE DON'T DO:
--   - NO hookmetamethod (detected by namecall scanner 0x273A)
--   - NO getfenv hook (freezes UI loading — copies env tables)
--   - NO remote FireServer hook (unstable, breaks heartbeats)

local AntiDetect = {}
AntiDetect.Name    = "AntiDetect"
AntiDetect.Enabled = false

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local lp               = Players.LocalPlayer

-- Fast local flag
local adEnabled = false

-- State tracking
local scanConn        = nil
local gameChildConn   = nil

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
-- LAYER 1: Executor Invisibility (hide from Adonis detection checks)
-- ════════════════════════════════════════════════════════════════════════════

local function enableStealthHooks()
    pcall(function()
        if not hookfunction or not newcclosure then return end

        -- Hook checkcaller — Adonis checks if functions are executor-made
        pcall(function()
            if checkcaller then
                hookfunction(checkcaller, newcclosure(function()
                    return false
                end))
                print("[AntiDetect] checkcaller hooked")
            end
        end)

        -- Hook isexecutorclosure — same purpose
        pcall(function()
            if isexecutorclosure then
                hookfunction(isexecutorclosure, newcclosure(function()
                    return false
                end))
                print("[AntiDetect] isexecutorclosure hooked")
            end
        end)

        -- NO getfenv hook — it copies environment tables and freezes UI loading
        -- checkcaller + isexecutorclosure are sufficient to hide the executor

        -- Hook debug.getinfo — hide executor stack frames
        pcall(function()
            if debug and debug.getinfo then
                local origGetinfo = debug.getinfo
                hookfunction(debug.getinfo, newcclosure(function(fn, ...)
                    local info = origGetinfo(fn, ...)
                    if info and type(info) == "table" then
                        if info.source and (info.source:find("executor") or info.source:find("synapse") or
                           info.source:find("fluxus") or info.source:find("delta") or info.source:find("krnl")) then
                            info.source = "[Roblox]"
                            info.short_src = "[Roblox]"
                        end
                    end
                    return info
                end))
                print("[AntiDetect] debug.getinfo hooked")
            end
        end)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 2: Selective Detection Script Destroyer
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
    -- Initial scan
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if isDetectionScript(obj) then
                destroyDetectionScript(obj)
            end
        end
    end)

    -- Monitor for new detection scripts
    if gameChildConn then gameChildConn:Disconnect() end
    gameChildConn = game.DescendantAdded:Connect(function(obj)
        if not adEnabled then return end
        if isDetectionScript(obj) then
            destroyDetectionScript(obj)
        end
    end)

    -- Periodic sweep every 5 seconds (NOT every frame — too expensive)
    if scanConn then scanConn:Disconnect() end
    local sweepTimer = 0
    scanConn = RunService.Heartbeat:Connect(function(dt)
        if not adEnabled then return end
        sweepTimer = sweepTimer + dt
        if sweepTimer < 5 then return end
        sweepTimer = 0
        pcall(function()
            for _, obj in ipairs(game:GetDescendants()) do
                if isDetectionScript(obj) then
                    destroyDetectionScript(obj)
                end
            end
        end)
    end)

    print("[AntiDetect] Script filter active (detection scripts only)")
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 3: Direct Kick Hook (hookfunction on Player:Kick)
-- ════════════════════════════════════════════════════════════════════════════

local function enableDirectHooks()
    pcall(function()
        if not hookfunction or not newcclosure then return end
        pcall(function()
            hookfunction(
                lp.Kick,
                newcclosure(function()
                    return
                end)
            )
            print("[AntiDetect] Player:Kick hooked")
        end)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- Public API
-- ════════════════════════════════════════════════════════════════════════════

function AntiDetect:Enable()
    if self.Enabled then return end
    self.Enabled = true
    adEnabled = true

    print("[AntiDetect] Enabling v7.2 — lightweight anti-Adonis")

    -- Layer 1: Executor invisibility (checkcaller, isexecutorclosure, debug.getinfo)
    enableStealthHooks()

    -- Layer 2: Destroy only detection scripts
    enableScriptFilter()

    -- Layer 3: Direct Kick hook (backup)
    enableDirectHooks()

    print("[AntiDetect] All layers active (no hookmetamethod, no getfenv, no remote hook)")
end

function AntiDetect:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    adEnabled = false

    if scanConn then scanConn:Disconnect(); scanConn = nil end
    if gameChildConn then gameChildConn:Disconnect(); gameChildConn = nil end

    -- Note: hooks stay active — they check adEnabled flag
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
