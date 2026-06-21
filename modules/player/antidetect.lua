-- Leon X | AntiDetect v6 — Smart Adonis Bypass
-- Based on analysis of actual Adonis anti.lua source code:
--   RemovePlayer() calls service.UnWrap(p):Kick() on the SERVER
--   CheckAllClients() runs every 30s, kicks after 300s without heartbeat
--   Detected() routes all kick/kill/crash through server
--
-- KEY INSIGHT: Our previous versions blocked ALL Adonis remotes, which
--   prevented heartbeats from reaching the server → CheckAllClients
--   kicked us for "Client Not Responding [>300 seconds]".
--   We were CAUSING the kick by blocking heartbeats!
--
-- NEW STRATEGY: Executor invisibility
--   1. DON'T destroy Adonis remotes (heartbeats must flow)
--   2. Hook checkcaller/getfenv/isexecutorclosure (hide executor)
--   3. Block Player:Kick() in namecall (prevent client-side kicks)
--   4. Only block FireServer with detection-reporting patterns
--   5. Destroy only Adonis DETECTION scripts (not core client/remotes)
-- MUST be loaded FIRST — before any game scripts run

local AntiDetect = {}
AntiDetect.Name    = "AntiDetect"
AntiDetect.Enabled = false

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")
local lp               = Players.LocalPlayer

-- Fast local flag
local adEnabled = false

-- State tracking
local oldNamecall       = nil
local oldKick           = nil
local oldIsExec         = nil
local oldCheckCaller   = nil
local oldGetfenv        = nil
local hookActive        = false
local scanConn          = nil
local gameChildConn     = nil

-- ════════════════════════════════════════════════════════════════════════════
-- PATTERNS
-- ════════════════════════════════════════════════════════════════════════════

-- Adonis DETECTION script names (NOT core client or remotes)
-- These are the scripts that CHECK for executors and report to server
local ADONIS_DETECTION_SCRIPTS = {
    "clientcheck", "anticheat", "antiexploit", "antihack",
    "detection", "exploitdetect", "hackdetect", "cheatdetect",
    "integrity", "sanity", "validate",
}

-- FireServer args that indicate a detection report (NOT a heartbeat)
-- Adonis Detected() uses: "Kick", "Kill", "Crash", "Log"
local DETECTION_KEYWORDS = {
    "detected", "exploit", "cheating", "hacking", "speedhack",
    "anticheat", "antiexploit", "injection", "executor",
    "tamper", "modified", "integrity", "violation",
}

-- Check if FireServer args look like a detection report
local function isDetectionReport(args)
    for _, arg in ipairs(args) do
        if type(arg) == "string" then
            local lower = arg:lower()
            for _, keyword in ipairs(DETECTION_KEYWORDS) do
                if lower:find(keyword, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

-- Check if a script is an Adonis DETECTION script (not core client)
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
-- LAYER 1: __namecall Hook (Kick block + smart remote filter)
-- ════════════════════════════════════════════════════════════════════════════

local function enableNamecallHook()
    pcall(function()
        if not hookmetamethod or not newcclosure or not getnamecallmethod then return end
        if hookActive then return end

        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if adEnabled then
                local method = getnamecallmethod()

                -- Block Player:Kick() — catches any client-side kick attempt
                if method == "Kick" and self == lp then
                    return
                end

                -- Smart remote filter: block detection reports, ALLOW heartbeats
                if method == "FireServer" or method == "InvokeServer" then
                    local args = {...}
                    -- Only block if args contain detection-reporting keywords
                    if isDetectionReport(args) then
                        return  -- silently eat the detection report
                    end
                    -- Everything else (heartbeats, normal game traffic) passes through
                end

                -- Block suspicious teleports (some admin commands use teleport-to-kick)
                if self == TeleportService then
                    if method == "Teleport" or method == "TeleportToPlaceInstance"
                       or method == "TeleportAsync" or method == "TeleportToPrivateServer" then
                        -- Allow user-initiated teleports
                        if _G._LeonX_AllowTeleportActive then
                            return oldNamecall(self, ...)
                        end
                        local args = {...}
                        local placeId = args[1]
                        if placeId and type(placeId) == "number" and placeId < 100 then
                            return
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end))

        hookActive = true
        print("[AntiDetect] namecall hook active")
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 2: Executor Invisibility (the REAL defense against detection)
-- ════════════════════════════════════════════════════════════════════════════

local function enableStealthHooks()
    pcall(function()
        if not hookfunction or not newcclosure then return end

        -- Hook checkcaller — Adonis checks if functions are executor-made
        -- Always return false so our closures look like legitimate Roblox functions
        pcall(function()
            if checkcaller then
                oldCheckCaller = hookfunction(checkcaller, newcclosure(function()
                    return false
                end))
                print("[AntiDetect] checkcaller hooked")
            end
        end)

        -- Hook isexecutorclosure — same purpose as checkcaller
        pcall(function()
            if isexecutorclosure then
                oldIsExec = hookfunction(isexecutorclosure, newcclosure(function()
                    return false
                end))
                print("[AntiDetect] isexecutorclosure hooked")
            end
        end)

        -- Hook getfenv — strip executor functions from returned environments
        -- When Adonis inspects script environments, executor functions are hidden
        pcall(function()
            if getfenv then
                local origGetfenv = getfenv
                local execFns = {
                    hookfunction=1, hookmetamethod=1, getgc=1, getrenv=1, getsenv=1,
                    getrawmetatable=1, setrawmetatable=1, getnamecallmethod=1,
                    checkcaller=1, newcclosure=1, newproxy=1, clonefunction=1,
                    isexecutorclosure=1, getinstances=1, getnilinstances=1,
                    getscripts=1, getrunningscripts=1, getloadedmodules=1,
                    decompile=1, getscriptclosure=1, getscripthash=1,
                    getthreadidentity=1, setthreadidentity=1, setfpscap=1,
                    request=1, http_request=1, crypt=1,
                    base64_encode=1, base64_decode=1,
                    readfile=1, writefile=1, appendfile=1, isfile=1, isfolder=1,
                    makefolder=1, delfolder=1, delfile=1, listfiles=1,
                    getcustomasset=1, getassets=1,
                }
                oldGetfenv = hookfunction(getfenv, newcclosure(function(...)
                    local result = origGetfenv(...)
                    if type(result) == "table" then
                        local clean = {}
                        for k, v in pairs(result) do
                            if not execFns[k] then
                                clean[k] = v
                            end
                        end
                        return clean
                    end
                    return result
                end))
                print("[AntiDetect] getfenv hooked")
            end
        end)

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
-- LAYER 3: Selective Detection Script Destroyer
-- ════════════════════════════════════════════════════════════════════════════
-- Only destroys Adonis DETECTION scripts, NOT core client or remotes.
-- This preserves heartbeat communication while removing detection logic.

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
    -- Scan for Adonis detection scripts across the game
    -- IMPORTANT: Only destroy DETECTION scripts, NOT core Adonis client/remotes
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if isDetectionScript(obj) then
                destroyDetectionScript(obj)
            end
        end
    end)

    -- Monitor for new detection scripts being added
    if gameChildConn then gameChildConn:Disconnect() end
    gameChildConn = game.DescendantAdded:Connect(function(obj)
        if not adEnabled then return end
        if isDetectionScript(obj) then
            destroyDetectionScript(obj)
        end
    end)

    -- Periodic sweep (catches scripts that respawn)
    if scanConn then scanConn:Disconnect() end
    scanConn = RunService.Heartbeat:Connect(function()
        if not adEnabled then return end
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
-- LAYER 4: Direct Kick Hook (backup for namecall)
-- ════════════════════════════════════════════════════════════════════════════

local function enableDirectHooks()
    pcall(function()
        if not hookfunction or not newcclosure then return end

        -- Hook Player:Kick() directly as backup
        pcall(function()
            oldKick = hookfunction(
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

    print("[AntiDetect] Enabling v6 — smart Adonis bypass")

    -- Layer 1: namecall hook (Kick block + smart remote filter)
    enableNamecallHook()

    -- Layer 2: Executor invisibility (checkcaller, getfenv, etc.)
    enableStealthHooks()

    -- Layer 3: Destroy only detection scripts (keep core client alive)
    enableScriptFilter()

    -- Layer 4: Direct Kick hook (backup)
    enableDirectHooks()

    print("[AntiDetect] All layers active")
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
