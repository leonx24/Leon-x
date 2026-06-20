-- Leon X | AntiDetect v2
-- Aggressive multi-layered anti-cheat neutralization
-- Prevents "disallowed service detected" (error 267) kicks
-- MUST be loaded FIRST — before any game anti-cheat scripts run

local AntiDetect = {}
AntiDetect.Name    = "AntiDetect"
AntiDetect.Enabled = false

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local lp               = Players.LocalPlayer

-- Fast local flag (avoids table access in hot path)
local adEnabled = false

-- State tracking
local oldNamecall       = nil
local oldKick           = nil
local oldIsExec         = nil
local destroyedScripts  = {}
local scanConn          = nil
local childConn         = nil
local hookActive        = false

-- ════════════════════════════════════════════════════════════════════════════
-- PATTERNS
-- ════════════════════════════════════════════════════════════════════════════

-- Anti-cheat script name patterns (lowercase)
local AC_SCRIPT_NAMES = {
    "anticheat", "antiexploit", "antihack", "antiscrypt",
    "ac_", "ac-", "detection", "security", "secure",
    "exploitdetect", "hackdetect", "cheatdetect",
    "anticrasher", "antiteleport", "antispeed",
    "anticlone", "anticlient", "antibot",
    "senty", "topbarcorescript", "kick", "eac",
    "byfron", "hyperion", "guardian", "protector",
    "anticheese", "serverguard", "adonis_ac",
}

-- Anti-cheat remote name patterns (lowercase)
local AC_REMOTE_NAMES = {
    "anticheat", "antiexploit", "detection", "security",
    "ac_remote", "report", "securitycheck", "hackreport",
    "cheatreport", "clientreport", "kickplayer",
    "heartbeat", "ping", "validate", "verify",
    "integrity", "sanity", "check", "exploit",
    "ban", "moderation", "modlog",
}

-- Suspicious single-character or short script names often used by obfuscated AC
local SUSPICIOUS_SHORT_NAMES = {
    ["a"] = true, ["ac"] = true, ["e"] = true, ["s"] = true,
    ["k"] = true, ["x"] = true, ["z"] = true,
}

-- Check if a name matches anti-cheat patterns
local function isACName(name, patterns)
    local lower = name:lower()
    for _, pattern in ipairs(patterns) do
        if lower:find(pattern, 1, true) then
            return true
        end
    end
    return false
end

-- Check if a script looks suspicious (obfuscated AC)
local function isSuspiciousScript(obj)
    if not obj:IsA("LocalScript") and not obj:IsA("ModuleScript") then
        return false
    end

    -- Check AC name patterns
    if isACName(obj.Name, AC_SCRIPT_NAMES) then
        return true
    end

    -- Check suspicious short names in PlayerScripts
    local lower = obj.Name:lower()
    if SUSPICIOUS_SHORT_NAMES[lower] then
        return true
    end

    return false
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 1: __namecall Hook (Kick blocker ONLY — ultra lightweight)
-- ════════════════════════════════════════════════════════════════════════════

local function enableNamecallHook()
    pcall(function()
        if not hookmetamethod or not newcclosure or not getnamecallmethod then return end
        if hookActive then return end

        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            -- Ultra-lightweight: only intercept Kick, pass through EVERYTHING else
            if adEnabled and getnamecallmethod() == "Kick" then
                -- Only block Kick on local player
                if self == lp then
                    return
                end
            end
            return oldNamecall(self, ...)
        end))

        hookActive = true
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 2: Direct Function Hooks (Kick + Teleport + isexecutorclosure)
-- ════════════════════════════════════════════════════════════════════════════

local function enableDirectHooks()
    pcall(function()
        if not hookfunction or not newcclosure then return end

        -- Hook Player:Kick() directly
        pcall(function()
            oldKick = hookfunction(
                lp.Kick,
                newcclosure(function()
                    return  -- block kick
                end)
            )
        end)

        -- Hook isexecutorclosure if available (anti-cheat uses this to detect executors)
        pcall(function()
            if isexecutorclosure then
                oldIsExec = hookfunction(
                    isexecutorclosure,
                    newcclosure(function(fn)
                        return false  -- always say "not an executor closure"
                    end)
                )
            end
        end)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 3: Aggressive Script Scanner
-- ════════════════════════════════════════════════════════════════════════════

local function destroyScript(obj)
    pcall(function()
        obj.Disabled = true
    end)
    pcall(function()
        obj:Destroy()
    end)
    destroyedScripts[#destroyedScripts + 1] = obj.Name
end

local function scanContainer(container, aggressive)
    if not container then return 0 end
    local count = 0

    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            if isSuspiciousScript(obj) then
                destroyScript(obj)
                count = count + 1
            end
        end
    end)

    return count
end

local function enableScriptScanner()
    -- Scan all common anti-cheat locations
    local total = 0
    local containers = {}

    pcall(function()
        local ps = lp:FindFirstChild("PlayerScripts")
        if ps then containers[#containers + 1] = ps end
    end)

    pcall(function()
        local sp = game:GetService("StarterPlayer")
        if sp then
            local sps = sp:FindFirstChild("StarterPlayerScripts")
            if sps then containers[#containers + 1] = sps end
        end
    end)

    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        if rs then containers[#containers + 1] = rs end
    end)

    pcall(function()
        local sgc = game:GetService("StarterGui")
        if sgc then containers[#containers + 1] = sgc end
    end)

    pcall(function()
        local lighting = game:GetService("Lighting")
        if lighting then containers[#containers + 1] = lighting end
    end)

    for _, container in ipairs(containers) do
        total = total + scanContainer(container)
    end

    -- Continuous monitoring — scan every heartbeat for new scripts
    if scanConn then scanConn:Disconnect() end
    scanConn = RunService.Heartbeat:Connect(function()
        if not AntiDetect.Enabled then return end

        pcall(function()
            local ps = lp:FindFirstChild("PlayerScripts")
            if ps then
                for _, obj in ipairs(ps:GetDescendants()) do
                    if isSuspiciousScript(obj) then
                        destroyScript(obj)
                    end
                end
            end
        end)
    end)

    -- Watch for NEW scripts being added to PlayerScripts
    if childConn then childConn:Disconnect() end
    pcall(function()
        local ps = lp:FindFirstChild("PlayerScripts")
        if ps then
            childConn = ps.DescendantAdded:Connect(function(obj)
                if not AntiDetect.Enabled then return end
                task.defer(function()
                    if isSuspiciousScript(obj) then
                        destroyScript(obj)
                    end
                end)
            end)
        end
    end)
end

local function disableScriptScanner()
    if scanConn then
        scanConn:Disconnect()
        scanConn = nil
    end
    if childConn then
        childConn:Disconnect()
        childConn = nil
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 4: Executor Environment Protection
-- ════════════════════════════════════════════════════════════════════════════

local function enableExecutorProtection()
    pcall(function()
        if not hookfunction or not newcclosure then return end

        -- Hook getfenv to strip executor functions from returned environments
        local origGetfenv = getfenv
        local executorFns = {
            "hookfunction", "hookmetamethod", "getgc", "getrenv", "getsenv",
            "getrawmetatable", "setrawmetatable", "getnamecallmethod",
            "checkcaller", "newcclosure", "newproxy", "clonefunction",
            "isexecutorclosure", "getinstances", "getnilinstances",
            "getscripts", "getrunningscripts", "getloadedmodules",
            "decompile", "getscriptclosure", "getscripthash",
            "getthreadidentity", "setthreadidentity", "setfpscap",
            "request", "http_request", "crypt", "base64_encode",
            "base64_decode", "readfile", "writefile", "appendfile",
            "isfile", "isfolder", "makefolder", "delfolder", "delfile",
            "listfiles", "getcustomasset", "getassets",
        }

        hookfunction(getfenv, newcclosure(function(...)
            local result = origGetfenv(...)
            if type(result) == "table" then
                local clean = {}
                for k, v in pairs(result) do
                    local isExecFn = false
                    for _, fn in ipairs(executorFns) do
                        if k == fn then isExecFn = true; break end
                    end
                    if not isExecFn then
                        clean[k] = v
                    end
                end
                return clean
            end
            return result
        end))
    end)

    -- Hook debug.getinfo to hide executor stack frames
    pcall(function()
        if not hookfunction or not newcclosure or not debug or not debug.getinfo then return end

        local origGetinfo = debug.getinfo
        hookfunction(debug.getinfo, newcclosure(function(fn, ...)
            local info = origGetinfo(fn, ...)
            if info and type(info) == "table" then
                -- Clean source to hide executor internals
                if info.source and (info.source:find("executor") or info.source:find("synapse") or
                   info.source:find("fluxus") or info.source:find("delta") or info.source:find("krnl")) then
                    info.source = "[Roblox]"
                    info.short_src = "[Roblox]"
                end
            end
            return info
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

    -- Layer 1: __namecall hook (MUST be first — catches everything)
    enableNamecallHook()

    -- Layer 2: Direct function hooks (Kick, isexecutorclosure)
    enableDirectHooks()

    -- Layer 3: Script scanner (destroy AC scripts)
    enableScriptScanner()

    -- Layer 4: Executor environment protection (hide from getfenv/debug)
    enableExecutorProtection()
end

function AntiDetect:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    adEnabled = false

    disableScriptScanner()

    -- Note: hooks are NOT removed — they stay active and check self.Enabled
    -- This prevents anti-cheat from detecting hook removal
end

function AntiDetect:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function AntiDetect:GetDestroyedCount()
    return #destroyedScripts
end

function AntiDetect:GetDestroyedNames()
    return destroyedScripts
end

return AntiDetect
