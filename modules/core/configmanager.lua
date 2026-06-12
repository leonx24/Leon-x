-- Leon X | ConfigManager (WindUI-compatible)
-- Saves and loads named config snapshots via manual element registration.

local ConfigManager = {}

local HttpService = game:GetService("HttpService")

local DIR = "Leon X/configs"
local DOT = DIR .. "/.default"

-- Registry: { [flag] = { element = WindUIElement, serialize = fn, deserialize = fn } }
local Registry = {}

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
    if not isfolder(DIR) then makefolder(DIR) end
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
    if not safe then return false end

    local data = {}
    for flag, entry in pairs(Registry) do
        pcall(function()
            local el = entry.element
            local val
            if el.Get then
                val = el:Get()
            else
                val = el.Value
            end
            -- auto-serialize Enum.KeyCode as name string
            if type(val) == "userdata" and pcall(function() return val.Name end) then
                val = val.Name
            end
            data[flag] = entry.serialize(val)
        end)
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not ok then return false end

    ensureDir()
    pcall(function() writefile(path(safe), encoded) end)
    return true
end

function ConfigManager:Load(name)
    local safe = sanitize(name)
    if not safe then return false end

    local p = path(safe)
    if not isfile(p) then return false end

    local raw
    local ok1 = pcall(function() raw = readfile(p) end)
    if not ok1 or not raw then return false end

    local data
    local ok2 = pcall(function()
        data = HttpService:JSONDecode(raw)
    end)
    if not ok2 or type(data) ~= "table" then return false end

    for flag, saved in pairs(data) do
        local entry = Registry[flag]
        if entry and entry.element then
            pcall(function()
                local val = entry.deserialize(saved)
                -- auto-convert keybind string names back to Enum.KeyCode
                if type(val) == "string" and flag:find("Key") and Enum.KeyCode[val] then
                    val = Enum.KeyCode[val]
                end
                if entry.element.Set then
                    entry.element:Set(val)
                end
                -- fire callback so feature actually activates
                if entry.element.Callback then
                    pcall(entry.element.Callback, val)
                end
            end)
        end
    end

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
    self:Load(target)
end

return ConfigManager
