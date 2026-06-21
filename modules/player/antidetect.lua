-- Leon X | AntiDetect v7 — No-namecall Adonis Bypass
-- v6 got detected by "namecall instance detector" (0x273A)
-- Adonis checks if game's __namecall metamethod was tampered via hookmetamethod.
--
-- v7 STRATEGY: ZERO hookmetamethod usage
--   1. hookfunction on individual Adonis remotes' FireServer (invisible to game metatable scan)
--   2. Stealth hooks: checkcaller/getfenv/isexecutorclosure/debug.getinfo
--   3. Destroy only Adonis DETECTION scripts (heartbeats must flow)
--   4. Direct hookfunction on Player:Kick as backup
--
-- WHY THIS WORKS: hookfunction modifies a specific function pointer,
--   NOT the game metatable. Adonis' namecall detector only checks
--   getrawmetatable(game).__namecall — we never touch it.

local AntiDetect = {}
AntiDetect.Name    = "AntiDetect"
AntiDetect.Enabled = false

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp               = Players.LocalPlayer

-- Fast local flag
local adEnabled = false

-- State tracking
local hookedRemotes   = {}
local scanConn        = nil
local gameChildConn   = nil
local remoteAddedConn = nil

-- ════════════════════════════════════════════════════════════════════════════
-- PATTERNS
-- ════════════════════════════════════════════════════════════════════════════

-- Adonis DETECTION script names (NOT core client or remotes)
local ADONIS_DETECTION_SCRIPTS = {
    "clientcheck", "anticheat", "antiexploit", "antihack",
    "detection", "exploitdetect", "hackdetect", "cheatdetect",
    "integrity", "sanity", "validate",
}

-- FireServer args that indicate a detection report (NOT a heartbeat)
local DETECTION_KEYWORDS = {
    "detected", "exploit", "cheating", "hacking", "speedhack",
    "anticheat", "antiexploit", "injection", "executor",
    "tamper", "modified", "integrity", "violation",
    "namecall", "instance detector",
}

-- Known Adonis remote folder names
local ADONIS_REMOTE_NAMES = {
    "__adonis", "adonis", "__admin", "admin",
    "__server", "sb_", "remote",
}

-- Check if FireServer args look like a detection report
local function isDetectionReport(...)
    local args = {...}
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

-- Check if an object looks like an Adonis remote
local function isAdonisRemote(obj)
    if not obj:IsA("RemoteEvent") and not obj:IsA("RemoteFunction") then
        return false
    end
    local lower = obj.Name:lower()
    -- Check name patterns
    for _, pattern in ipairs(ADONIS_REMOTE_NAMES) do
        if lower:find(pattern, 1, true) then return true end
    end
    -- Check if parent chain contains Adonis-related folders
    local parent = obj.Parent
    while parent do
        local pLower = parent.Name:lower()
        if pLower:find("adonis", 1, true) or pLower:find("__admin", 1, true) then
            return true
        end
        parent = parent.Parent
    end
    return false
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 1: Direct Remote Hook (hookfunction on individual remotes)
-- NO hookmetamethod — Adonis namecall detector cannot see this
-- ════════════════════════════════════════════════════════════════════════════

local function hookAdonisRemote(remote)
    if hookedRemotes[remote] then return end
    if not hookfunction or not newcclosure then return end

    local success = pcall(function()
        if remote:IsA("RemoteEvent") then
            local origFire = remote.FireServer
            hookedRemotes[remote] = hookfunction(origFire, newcclosure(function(self, ...)
                if adEnabled and isDetectionReport(...) then
                    return -- silently eat detection report
                end
                return origFire(self, ...)
            end))
            print("[AntiDetect] Hooked RemoteEvent: " .. remote:GetFullName())
        elseif remote:IsA("RemoteFunction") then
            local origInvoke = remote.InvokeServer
            hookedRemotes[remote] = hookfunction(origInvoke, newcclosure(function(self, ...)
                if adEnabled and isDetectionReport(...) then
                    return -- silently eat detection report
                end
                return origInvoke(self, ...)
            end))
            print("[AntiDetect] Hooked RemoteFunction: " .. remote:GetFullName())
        end
    end)

    if not success then
        print("[AntiDetect] Failed to hook: " .. remote:GetFullName())
    end
end

local function scanAndHookRemotes()
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if isAdonisRemote(obj) then
                hookAdonisRemote(obj)
            end
        end
    end)
end

local function enableRemoteHooks()
    -- Initial scan
    scanAndHookRemotes()

    -- Monitor for new Adonis remotes appearing
    if remoteAddedConn then remoteAddedConn:Disconnect() end
    remoteAddedConn = game.DescendantAdded:Connect(function(obj)
        if not adEnabled then return end
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and isAdonisRemote(obj) then
            hookAdonisRemote(obj)
        end
    end)

    print("[AntiDetect] Remote hook layer active (no hookmetamethod)")
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 2: Executor Invisibility (hide from Adonis detection checks)
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

        -- Hook getfenv — strip executor functions from returned environments
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
                hookfunction(getfenv, newcclosure(function(...)
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

    -- Periodic sweep
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
-- LAYER 4: Direct Kick Hook (hookfunction on Player:Kick)
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

    print("[AntiDetect] Enabling v7 — zero hookmetamethod bypass")

    -- Layer 1: Hook individual Adonis remotes (no game metatable touch)
    enableRemoteHooks()

    -- Layer 2: Executor invisibility (checkcaller, getfenv, etc.)
    enableStealthHooks()

    -- Layer 3: Destroy only detection scripts
    enableScriptFilter()

    -- Layer 4: Direct Kick hook (backup)
    enableDirectHooks()

    print("[AntiDetect] All layers active (no hookmetamethod used)")
end

function AntiDetect:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    adEnabled = false

    if scanConn then scanConn:Disconnect(); scanConn = nil end
    if gameChildConn then gameChildConn:Disconnect(); gameChildConn = nil end
    if remoteAddedConn then remoteAddedConn:Disconnect(); remoteAddedConn = nil end

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
