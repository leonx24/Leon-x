-- Leon X | ConfigManager
-- Saves and loads named config snapshots for all registered UI components.

local ConfigManager = {}

local HttpService = game:GetService("HttpService")

local DIR  = "Leon X/configs"
local DOT  = DIR .. "/.default"
local _lib = nil   -- set by Init()

-- ── helpers ───────────────────────────────────────────────────────────────────

-- sanitize a config name: replace invalid path chars, block traversal
local function sanitize(name)
    -- replace invalid characters
    local s = tostring(name):gsub('[\\/:*?"<>|]', "_")
    -- block traversal attempts (.. or leading dots that resolve outside DIR)
    if s:find("%.%.") then return nil end
    if s == "" then return nil end
    return s
end

local function path(name)
    return DIR .. "/" .. name .. ".json"
end

local function ensureDir()
    if not isfolder(DIR) then
        makefolder(DIR)
    end
end

-- serialize a single component value for JSON
-- Keybind Get() returns an EnumItem; everything else is a plain Lua value
local function serialize(val)
    if typeof(val) == "EnumItem" then
        return val.Name   -- store as string e.g. "F"
    end
    return val
end

-- ── public API ────────────────────────────────────────────────────────────────

function ConfigManager:Init(library)
    _lib = library
end

function ConfigManager:Save(name)
    if not _lib then return false end
    local safe = sanitize(name)
    if not safe then return false end

    local data = {}
    for flag, api in pairs(_lib.Registry) do
        local ok, val = pcall(function() return api:Get() end)
        if ok then
            data[flag] = serialize(val)
        end
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
    if not _lib then return false end
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

    for flag, val in pairs(data) do
        local api = _lib.Registry[flag]
        if api and api.Set then
            pcall(function()
                -- Keybind values are stored as strings; convert back to KeyCode
                if type(val) == "string" then
                    local kc = Enum.KeyCode[val]
                    if kc then
                        api:Set(kc)
                        -- fire callback so keybind-dependent state updates
                        if api.Callback then pcall(api.Callback, kc) end
                        return
                    end
                end
                api:Set(val)
                -- fire callback after set so modules actually activate
                -- (api:Set is silent by design; callbacks enable/disable features)
                if api.Callback then pcall(api.Callback, val) end
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
        -- extract just the filename from the full path
        local fname = f:match("[^/\\]+$") or f
        if fname:sub(-5) == ".json" then
            table.insert(result, fname:sub(1, -6))  -- strip .json
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

-- called internally by main.lua after all Add* calls
function ConfigManager:AutoLoad()
    local target = "default"
    if isfile(DOT) then
        local ok, content = pcall(readfile, DOT)
        if ok and content and content ~= "" then
            target = content:gsub("%s+", "")  -- trim whitespace
        end
    end
    self:Load(target)
end

return ConfigManager
