-- Leon X | AntiDetect v4
-- Aggressive multi-layered anti-cheat + anti-admin neutralization
-- Blocks Adonis admin kicks/bans (server-side Kick cannot be blocked —
--   so we destroy all Adonis client infrastructure instead)
-- MUST be loaded FIRST — before any game anti-cheat scripts run

local AntiDetect = {}
AntiDetect.Name    = "AntiDetect"
AntiDetect.Enabled = false

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local lp               = Players.LocalPlayer

-- Fast local flag (avoids table access in hot path)
local adEnabled = false

local TeleportService    = game:GetService("TeleportService")

-- State tracking
local oldNamecall       = nil
local oldKick           = nil
local oldTeleport       = nil
local oldTeleportPlace  = nil
local oldIsExec         = nil
local destroyedScripts  = {}
local destroyedAdonis   = {}  -- track destroyed Adonis objects
local scanConn          = nil
local childConn         = nil
local gameChildConn     = nil  -- monitors entire game
local hookActive        = false
local adonisFound       = false -- true when any Adonis object is detected
local userTeleporting   = false -- flag for user-initiated teleports

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
    -- Adonis admin system
    "adonis", "::adonis::", "adonisadmin", "adminserver",
    "adonisclient", "adonis_core", "adonis_loader",
    "server_admin", "adminmodule",
}

-- Anti-cheat remote name patterns (lowercase)
local AC_REMOTE_NAMES = {
    "anticheat", "antiexploit", "detection", "security",
    "ac_remote", "report", "securitycheck", "hackreport",
    "cheatreport", "clientreport", "kickplayer",
    "heartbeat", "ping", "validate", "verify",
    "integrity", "sanity", "check", "exploit",
    "ban", "moderation", "modlog",
    -- Adonis admin remotes
    "::adonis::", "adonis", "adminremote", "adminkick",
    "adminban", "adminteleport", "admincmd",
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

-- Check if a name is Adonis-related (separate from generic AC check)
local function isAdonisName(name)
    local lower = name:lower()
    return lower:find("adonis", 1, true)
        or lower:find("::adonis::", 1, true)
        or lower:find("admin_handler", 1, true)
        or lower:find("adminremote", 1, true)
end

-- Check if an object or any of its ancestors is Adonis-related
local function hasAdonisAncestor(obj)
    local current = obj
    while current do
        if isAdonisName(current.Name) then return true end
        local ok, parent = pcall(function() return current.Parent end)
        if not ok or not parent then break end
        current = parent
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

    -- Check if any ancestor is Adonis
    if hasAdonisAncestor(obj) then
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
-- LAYER 1: __namecall Hook (Kick + Adonis comms + Teleport blocker)
-- ════════════════════════════════════════════════════════════════════════════

local function enableNamecallHook()
    pcall(function()
        if not hookmetamethod or not newcclosure or not getnamecallmethod then return end
        if hookActive then return end

        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if adEnabled then
                local method = getnamecallmethod()

                -- Block Player:Kick()
                if method == "Kick" and self == lp then
                    return
                end

                -- ═══ ADONIS TOTAL COMMS BLOCK ═══
                -- Block ALL FireServer/InvokeServer on ANY Adonis-related remote
                -- Don't filter by args — block ALL communication so server
                -- never receives detection data and can never issue kicks
                if method == "FireServer" or method == "InvokeServer" then
                    local blocked = false

                    -- Check the remote itself
                    pcall(function()
                        if isAdonisName(self.Name) then
                            blocked = true
                        end
                    end)

                    -- Check parent chain (Adonis remotes are often nested)
                    if not blocked then
                        pcall(function()
                            if hasAdonisAncestor(self) then
                                blocked = true
                            end
                        end)
                    end

                    if blocked then
                        adonisFound = true
                        return  -- silently eat the remote call
                    end
                end

                -- ═══ TELEPORT BLOCK (Adonis force-disconnect vector) ═══
                if self == TeleportService then
                    if method == "Teleport" or method == "TeleportToPlaceInstance"
                       or method == "TeleportAsync" or method == "TeleportPartyAsync"
                       or method == "TeleportToPrivateServer" then
                        -- Allow user-initiated teleports (e.g. ServerHop)
                        if userTeleporting then
                            return oldNamecall(self, ...)
                        end
                        -- Block ALL teleports when Adonis was detected in game
                        -- Adonis uses teleport-to-dummy-place as kick bypass
                        if adonisFound then
                            return
                        end
                        -- Also block suspicious low placeIds regardless
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

        -- Hook TeleportService:Teleport() directly (Adonis backup kick vector)
        pcall(function()
            oldTeleport = hookfunction(
                TeleportService.Teleport,
                newcclosure(function(self, placeId, ...)
                    if adEnabled and not userTeleporting then
                        if adonisFound or (type(placeId) == "number" and placeId < 100) then
                            return
                        end
                    end
                    return oldTeleport(self, placeId, ...)
                end)
            )
        end)

        -- Hook TeleportService:TeleportToPlaceInstance() directly
        pcall(function()
            oldTeleportPlace = hookfunction(
                TeleportService.TeleportToPlaceInstance,
                newcclosure(function(self, placeId, ...)
                    if adEnabled and not userTeleporting then
                        if adonisFound or (type(placeId) == "number" and placeId < 100) then
                            return
                        end
                    end
                    return oldTeleportPlace(self, placeId, ...)
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

-- Destroy any Adonis-related object (script, remote, folder, anything)
local function destroyAdonisObj(obj)
    pcall(function()
        local name = obj.Name
        -- Disable if it's a script
        pcall(function() obj.Disabled = true end)
        -- Destroy parent connections
        pcall(function() obj.Parent = nil end)
        pcall(function() obj:Destroy() end)
        destroyedAdonis[#destroyedAdonis + 1] = name
        destroyedScripts[#destroyedScripts + 1] = name
        adonisFound = true
    end)
end

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
    -- ═══ PHASE 1: Nuke ALL Adonis objects across the entire game ═══
    -- Adonis can live anywhere: ReplicatedStorage, Workspace, ServerScriptService
    -- (client-visible parts), StarterGui, PlayerGui, PlayerScripts, etc.
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            pcall(function()
                if isAdonisName(obj.Name) or hasAdonisAncestor(obj) then
                    if obj:IsA("LocalScript") or obj:IsA("ModuleScript")
                       or obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                       or obj:IsA("Script") then
                        destroyAdonisObj(obj)
                    end
                end
            end)
        end
    end)

    -- ═══ PHASE 2: Scan specific containers for generic AC scripts ═══
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

    pcall(function()
        local ws = game:GetService("Workspace")
        if ws then containers[#containers + 1] = ws end
    end)

    for _, container in ipairs(containers) do
        total = total + scanContainer(container)
    end

    -- ═══ PHASE 3: Continuous full-game monitoring ═══
    -- Scan every heartbeat for new Adonis/AC scripts
    if scanConn then scanConn:Disconnect() end
    scanConn = RunService.Heartbeat:Connect(function()
        if not AntiDetect.Enabled then return end

        -- Check PlayerScripts
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

        -- Also sweep ReplicatedStorage for Adonis remotes being re-added
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            if rs then
                for _, obj in ipairs(rs:GetDescendants()) do
                    if isAdonisName(obj.Name) or hasAdonisAncestor(obj) then
                        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                           or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                            destroyAdonisObj(obj)
                        end
                    end
                end
            end
        end)
    end)

    -- ═══ PHASE 4: game.DescendantAdded — instant kill for any Adonis object ═══
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

    if gameChildConn then gameChildConn:Disconnect() end
    gameChildConn = game.DescendantAdded:Connect(function(obj)
        if not AntiDetect.Enabled then return end
        pcall(function()
            if isAdonisName(obj.Name) or hasAdonisAncestor(obj) then
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                   or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
                   or obj:IsA("Script") then
                    task.defer(function()
                        destroyAdonisObj(obj)
                    end)
                end
            end
        end)
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
    if gameChildConn then
        gameChildConn:Disconnect()
        gameChildConn = nil
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 3B: Adonis Remote Interceptor (backup — destroys remotes on contact)
-- ════════════════════════════════════════════════════════════════════════════

local adonisRemoteConn = nil

local function enableAdonisInterceptor()
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        if not rs then return end

        -- Destroy ALL existing Adonis remotes and scripts
        for _, obj in ipairs(rs:GetDescendants()) do
            pcall(function()
                if isAdonisName(obj.Name) or hasAdonisAncestor(obj) then
                    destroyAdonisObj(obj)
                end
            end)
        end
    end)

    -- Also sweep other common locations
    pcall(function()
        for _, service in ipairs({"StarterGui", "Workspace", "Lighting"}) do
            pcall(function()
                local svc = game:GetService(service)
                if svc then
                    for _, obj in ipairs(svc:GetDescendants()) do
                        pcall(function()
                            if isAdonisName(obj.Name) or hasAdonisAncestor(obj) then
                                destroyAdonisObj(obj)
                            end
                        end)
                    end
                end
            end)
        end
    end)
end

local function disableAdonisInterceptor()
    if adonisRemoteConn then
        adonisRemoteConn:Disconnect()
        adonisRemoteConn = nil
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
        end))
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

    -- Layer 3B: Adonis remote interceptor
    enableAdonisInterceptor()

    -- Layer 4: Executor environment protection (hide from getfenv/debug)
    enableExecutorProtection()
end

function AntiDetect:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    adEnabled = false

    disableScriptScanner()
    disableAdonisInterceptor()

    -- Note: hooks are NOT removed — they stay active and check self.Enabled
    -- This prevents anti-cheat from detecting hook removal
end

function AntiDetect:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

-- Set flag so teleport hooks allow user-initiated teleports (e.g. ServerHop)
-- Other modules call: _G._LeonX_AllowTeleport(true/false)
function AntiDetect:AllowTeleport()
    userTeleporting = true
end

function AntiDetect:BlockTeleport()
    userTeleporting = false
end

-- Global bridge for other modules (ServerHop, Rejoin, GAG)
_G._LeonX_AllowTeleport = function(allow)
    userTeleporting = allow and true or false
end

function AntiDetect:GetDestroyedCount()
    return #destroyedScripts
end

function AntiDetect:GetDestroyedNames()
    return destroyedScripts
end

function AntiDetect:IsAdonisPresent()
    return adonisFound
end

return AntiDetect
