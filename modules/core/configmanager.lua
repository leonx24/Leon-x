-- Leon X | ConfigManager
-- Saves and loads named config snapshots via manual element registration.

local ConfigManager = {}

local HttpService = game:GetService("HttpService")

local DIR = "Leon X/configs"
local DOT = DIR .. "/.default"

-- Registry: { [flag] = { element = WindUIElement, serialize = fn, deserialize = fn } }
local Registry = {}

-- Notification callback (set by main.lua for debug feedback)
ConfigManager._notify = nil
ConfigManager._isLoading = false  -- true during AutoLoad, callbacks can check this

local function notify(title, msg)
    if ConfigManager._notify then
        pcall(ConfigManager._notify, title, msg)
    end
end

-- ── helpers ───────────────────────────────────────────────────────────────────

local function sanitize(name)
    local s = tostring(name):gsub('[\\/:*?"<>|]', "_")
    if s:find("%.%.") then return nil end
    if s == "" then return nil end
    return s
end

local function path(name)
    return DIR .. "/" .. name .. ".json"
end

local function ensureDir()
    if not isfolder("Leon X") then makefolder("Leon X") end
    if not isfolder(DIR) then makefolder(DIR) end
end

-- Read a WindUI element's current value reliably
local function getElementValue(el)
    -- WindUI stores value in .Value field
    local ok, val = pcall(function() return el.Value end)
    if ok and val ~= nil then return val end
    -- fallback: try :Get() method
    if type(el.Get) == "function" then
        ok, val = pcall(el.Get, el)
        if ok then return val end
    end
    return nil
end

-- Set a WindUI element's value reliably
local function setElementValue(el, val)
    -- try :Set() method first (most WindUI elements have this)
    if type(el.Set) == "function" then
        local ok = pcall(el.Set, el, val)
        if ok then return true end
    end
    -- fallback: set .Value directly
    pcall(function() el.Value = val end)
    return true
end

-- ── public API ────────────────────────────────────────────────────────────────

-- Call once after creating the Window (no-op in WindUI version, kept for compat)
function ConfigManager:Init(_library)
    -- no-op: WindUI version uses Register() instead
end

-- Register a UI element so it participates in Save/Load.
--   flag      : unique string key (e.g. "Fly", "FlySpeed")
--   element   : WindUI element reference (Toggle, Slider, Dropdown, etc.)
--   serialize : optional fn(val) -> saveable value  (default: identity)
--   deserialize: optional fn(saved) -> element value (default: identity)
function ConfigManager:Register(flag, element, serialize, deserialize)
    Registry[flag] = {
        element     = element,
        serialize   = serialize   or function(v) return v end,
        deserialize = deserialize or function(v) return v end,
    }
end

function ConfigManager:Save(name)
    local safe = sanitize(name)
    if not safe then
        notify("Config", "Invalid name: "..tostring(name))
        return false
    end

    ensureDir()

    local data = {}
    local count = 0
    for flag, entry in pairs(Registry) do
        local ok, err = pcall(function()
            local val = getElementValue(entry.element)
            if val ~= nil then
                -- auto-serialize Enum.KeyCode as name string
                if type(val) == "userdata" and pcall(function() return val.Name end) then
                    val = val.Name
                end
                data[flag] = entry.serialize(val)
                count = count + 1
            end
        end)
        if not ok then
            warn("[ConfigManager] Save error for "..flag..": "..tostring(err))
        end
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not ok or not encoded then
        notify("Config", "JSON encode failed")
        return false
    end

    local writeOk = pcall(function() writefile(path(safe), encoded) end)
    if not writeOk then
        notify("Config", "writefile failed for "..safe)
        return false
    end

    notify("Config", "Saved "..count.." settings to: "..safe)
    return true
end

function ConfigManager:Load(name)
    local safe = sanitize(name)
    if not safe then
        notify("Config", "Invalid name: "..tostring(name))
        return false
    end

    local p = path(safe)
    if not isfile(p) then
        notify("Config", "File not found: "..safe)
        return false
    end

    local raw
    local ok1 = pcall(function() raw = readfile(p) end)
    if not ok1 or not raw or raw == "" then
        notify("Config", "Read failed: "..safe)
        return false
    end

    local data
    local ok2 = pcall(function()
        data = HttpService:JSONDecode(raw)
    end)
    if not ok2 or type(data) ~= "table" then
        notify("Config", "JSON decode failed: "..safe)
        return false
    end

    local loaded = 0
    for flag, saved in pairs(data) do
        local entry = Registry[flag]
        if entry and entry.element then
            local ok, err = pcall(function()
                local val = entry.deserialize(saved)
                -- auto-convert keybind string names back to Enum.KeyCode
                if type(val) == "string" and flag:find("Key") and Enum.KeyCode[val] then
                    val = Enum.KeyCode[val]
                end
                -- set the element value
                setElementValue(entry.element, val)
                -- NOTE: callbacks are NOT fired during load.
                -- The caller (main.lua) must do a post-load sync to activate modules.
                loaded = loaded + 1
            end)
            if not ok then
                warn("[ConfigManager] Load error for "..flag..": "..tostring(err))
            end
        end
    end

    notify("Config", "Loaded "..loaded.." settings from: "..safe)
    return true
end

function ConfigManager:List()
    if not isfolder(DIR) then return {} end

    local files
    local ok = pcall(function() files = listfiles(DIR) end)
    if not ok or not files then return {} end

    local result = {}
    for _, f in ipairs(files) do
        local fname = f:match("[^/\\]+$") or f
        if fname:sub(-5) == ".json" then
            table.insert(result, fname:sub(1, -6))
        end
    end
    return result
end

function ConfigManager:Delete(name)
    local safe = sanitize(name)
    if not safe then return false end
    local p = path(safe)
    if not isfile(p) then return false end
    pcall(function() delfile(p) end)
    return true
end

function ConfigManager:SetDefault(name)
    local safe = sanitize(name)
    if not safe then return false end
    if not isfile(path(safe)) then return false end
    ensureDir()
    pcall(function() writefile(DOT, safe) end)
    return true
end

function ConfigManager:AutoLoad()
    local target = "default"
    if isfile(DOT) then
        local ok, content = pcall(readfile, DOT)
        if ok and content and content ~= "" then
            target = content:gsub("%s+", "")
        end
    end

    -- Check if config file actually exists before loading
    local p = path(target)
    if not isfile(p) then
        return false
    end

    self._isLoading = true
    local result = self:Load(target)
    self._isLoading = false
    return result
end

return ConfigManager
