-- Leon X | AntiDetect
-- Multi-layered anti-cheat neutralization
-- Prevents "disallowed service detected" (error 267) kicks

local AntiDetect = {}
AntiDetect.Name    = "AntiDetect"
AntiDetect.Enabled = false

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local lp           = Players.LocalPlayer

-- State tracking
local oldNamecall     = nil
local oldKick         = nil
local destroyedScripts = {}
local scanConn        = nil

-- Anti-cheat script name patterns (lowercase)
local AC_SCRIPT_NAMES = {
    "anticheat", "antiexploit", "antihack", "antiscrypt",
    "ac_", "ac-", "detection", "security", "secure",
    "exploitdetect", "hackdetect", "cheatdetect",
    "anticrasher", "antiteleport", "antispeed",
    "anticlone", "anticlient", "antibot",
}

-- Anti-cheat remote name patterns (lowercase)
local AC_REMOTE_NAMES = {
    "anticheat", "antiexploit", "detection", "security",
    "ac_remote", "report", "securitycheck", "hackreport",
    "cheatreport", "clientreport", "kickplayer",
}

-- Check if a name matches anti-cheat patterns
local function isACName(name, patterns)
    local lower = name:lower()
    for _, pattern in ipairs(patterns) do
        if lower:find(pattern) then
            return true
        end
    end
    return false
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 1: Kick Blocker
-- ════════════════════════════════════════════════════════════════════════════

local function enableKickBlocker()
    -- Hook Player:Kick() directly
    pcall(function()
        if not hookfunction then return end
        oldKick = hookfunction(
            lp.Kick,
            newcclosure(function()
                return  -- silently ignore kicks
            end)
        )
    end)

    -- Hook __namecall to block Kick calls
    pcall(function()
        if not hookmetamethod or not getnamecallmethod or not newcclosure then return end
        if not checkcaller then
            -- Fallback: just block all Kick namecalls
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "Kick" and self == lp then
                    return  -- block kick
                end
                return oldNamecall(self, ...)
            end))
            return
        end

        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()

            -- Block Kick calls on local player
            if method == "Kick" and self == lp then
                return
            end

            -- Block anti-cheat remote calls (FireServer/InvokeServer)
            if (method == "FireServer" or method == "InvokeServer") then
                if self and typeof(self) == "Instance" then
                    if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                        if isACName(self.Name, AC_REMOTE_NAMES) then
                            return  -- block anti-cheat remote
                        end
                    end
                end
            end

            return oldNamecall(self, ...)
        end))
    end)

    print("[Leon X] AntiDetect: Kick blocker enabled")
end

local function disableKickBlocker()
    pcall(function()
        if oldKick and hookfunction then
            hookfunction(lp.Kick, oldKick)
            oldKick = nil
        end
    end)
    -- Note: hookmetamethod can't easily be unhooked, but we set a flag
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 2: Anti-Cheat Script Scanner
-- ════════════════════════════════════════════════════════════════════════════

local function scanAndDestroy(container)
    if not container then return 0 end
    local count = 0

    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                if isACName(obj.Name, AC_SCRIPT_NAMES) then
                    pcall(function()
                        obj.Disabled = true
                        obj:Destroy()
                        destroyedScripts[#destroyedScripts + 1] = obj.Name
                        count = count + 1
                    end)
                end
            end
        end
    end)

    return count
end

local function enableScriptScanner()
    -- Initial scan
    local total = 0

    pcall(function()
        total = total + scanAndDestroy(lp:FindFirstChild("PlayerScripts"))
    end)

    pcall(function()
        local starterPlayer = game:GetService("StarterPlayer")
        if starterPlayer then
            total = total + scanAndDestroy(starterPlayer:FindFirstChild("StarterPlayerScripts"))
        end
    end)

    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        if rs then
            total = total + scanAndDestroy(rs)
        end
    end)

    if total > 0 then
        print("[Leon X] AntiDetect: Destroyed " .. total .. " anti-cheat script(s)")
    end

    -- Continuous scan for dynamically created scripts
    if scanConn then scanConn:Disconnect() end
    scanConn = RunService.Heartbeat:Connect(function()
        if not AntiDetect.Enabled then return end

        pcall(function()
            local ps = lp:FindFirstChild("PlayerScripts")
            if ps then
                for _, obj in ipairs(ps:GetDescendants()) do
                    if obj:IsA("LocalScript") then
                        if isACName(obj.Name, AC_SCRIPT_NAMES) then
                            pcall(function()
                                obj.Disabled = true
                                obj:Destroy()
                            end)
                        end
                    end
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
end

-- ════════════════════════════════════════════════════════════════════════════
-- LAYER 3: Executor Function Protection
-- ════════════════════════════════════════════════════════════════════════════

local function enableExecutorProtection()
    -- Hook getfenv to hide executor environment
    pcall(function()
        if not hookfunction or not newcclosure then return end

        local oldGetfenv = getfenv
        hookfunction(getfenv, newcclosure(function(...)
            local result = oldGetfenv(...)
            -- If result contains executor functions, return a clean env
            if type(result) == "table" then
                local clean = {}
                for k, v in pairs(result) do
                    -- Hide executor-specific functions
                    if k ~= "hookfunction" and k ~= "hookmetamethod" and
                       k ~= "getgc" and k ~= "getrenv" and k ~= "getsenv" and
                       k ~= "getrawmetatable" and k ~= "setrawmetatable" and
                       k ~= "getnamecallmethod" and k ~= "checkcaller" and
                       k ~= "newcclosure" and k ~= "newproxy" and
                       k ~= "clonefunction" and k ~= "isexecutorclosure" then
                        clean[k] = v
                    end
                end
                return clean
            end
            return result
        end))
    end)

    print("[Leon X] AntiDetect: Executor function protection enabled")
end

-- ════════════════════════════════════════════════════════════════════════════
-- Public API
-- ════════════════════════════════════════════════════════════════════════════

function AntiDetect:Enable()
    if self.Enabled then return end

    -- Check executor support
    if not hookfunction and not hookmetamethod then
        warn("[Leon X] AntiDetect: Executor doesn't support hooks — limited protection only")
    end

    self.Enabled = true

    -- Layer 1: Kick blocker
    enableKickBlocker()

    -- Layer 2: Script scanner
    enableScriptScanner()

    -- Layer 3: Executor protection
    enableExecutorProtection()

    print("[Leon X] AntiDetect: Full protection enabled")
end

function AntiDetect:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    disableKickBlocker()
    disableScriptScanner()

    -- Note: Executor protection hooks can't easily be removed
    -- This is intentional — keeping executor hidden even when disabled

    print("[Leon X] AntiDetect: Disabled (executor protection remains active)")
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
