-- Leon X | Waypoint System
-- Create, manage, and teleport to custom waypoints

local Waypoint = {}
Waypoint.Name      = "Waypoint"
Waypoint.Waypoints = {}  -- { [name] = CFrame }

local Players         = game:GetService("Players")
local HttpService     = game:GetService("HttpService")
local lp              = Players.LocalPlayer

local DIR = "Leon X/waypoints"

-- ── Persistence ───────────────────────────────────────────────────────────────

local function ensureDir()
    if not isfolder(DIR) then
        makefolder(DIR)
    end
end

local function getGameId()
    return tostring(game.PlaceId)
end

local function getWaypointFile()
    return DIR .. "/" .. getGameId() .. ".json"
end

local function saveToDisk()
    ensureDir()

    local data = {}
    for name, cf in pairs(Waypoint.Waypoints) do
        data[name] = {
            X  = cf.Position.X,
            Y  = cf.Position.Y,
            Z  = cf.Position.Z,
            LX = cf.LookVector.X,
            LY = cf.LookVector.Y,
            LZ = cf.LookVector.Z,
        }
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if ok then
        pcall(function()
            writefile(getWaypointFile(), encoded)
        end)
    end
end

local function loadFromDisk()
    local file = getWaypointFile()
    if not isfile(file) then return end

    local raw
    local ok1 = pcall(function() raw = readfile(file) end)
    if not ok1 or not raw then return end

    local data
    local ok2 = pcall(function()
        data = HttpService:JSONDecode(raw)
    end)
    if not ok2 or type(data) ~= "table" then return end

    for name, info in pairs(data) do
        if type(info) == "table" and info.X and info.Y and info.Z then
            local pos = Vector3.new(info.X, info.Y, info.Z)
            local look = Vector3.new(info.LX or 0, info.LY or 0, info.LZ or 1)
            Waypoint.Waypoints[name] = CFrame.lookAt(pos, pos + look)
        end
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Waypoint:Init()
    loadFromDisk()
end

function Waypoint:Create(name)
    if not name or name == "" then return false end

    local char = lp.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    self.Waypoints[name] = hrp.CFrame
    saveToDisk()
    return true
end

function Waypoint:Delete(name)
    if not self.Waypoints[name] then return false end
    self.Waypoints[name] = nil
    saveToDisk()
    return true
end

function Waypoint:Teleport(name, flyModule)
    local cf = self.Waypoints[name]
    if not cf then return false end

    local char = lp.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Temporarily disable fly during teleport to prevent conflicts
    local wasFlying = flyModule and flyModule.Enabled
    if wasFlying then flyModule:Disable() end

    hrp.CFrame = cf

    task.wait(0.1)
    if wasFlying then flyModule:Enable() end

    return true
end

function Waypoint:GetList()
    local list = {}
    for name in pairs(self.Waypoints) do
        table.insert(list, name)
    end
    table.sort(list)
    return #list > 0 and list or {"(no waypoints)"}
end

function Waypoint:GetPosition(name)
    local cf = self.Waypoints[name]
    if not cf then return nil end
    return cf.Position
end

function Waypoint:Exists(name)
    return self.Waypoints[name] ~= nil
end

function Waypoint:Rename(oldName, newName)
    if not self.Waypoints[oldName] then return false end
    if not newName or newName == "" then return false end
    if self.Waypoints[newName] then return false end  -- name already exists

    self.Waypoints[newName] = self.Waypoints[oldName]
    self.Waypoints[oldName] = nil
    saveToDisk()
    return true
end

function Waypoint:Clear()
    self.Waypoints = {}
    saveToDisk()
end

-- ── Waypoint Queue ─────────────────────────────────────

Waypoint._queue     = {}   -- ordered list of waypoint names
Waypoint._queueIdx  = 0
Waypoint._queueRunning = false
Waypoint._queueDelay   = 1.5  -- seconds between teleports

function Waypoint:AddToQueue(name)
    if not self.Waypoints[name] then return false end
    -- Don't add duplicates
    for _, qn in ipairs(self._queue) do
        if qn == name then return false end
    end
    self._queue[#self._queue + 1] = name
    return true
end

function Waypoint:RemoveFromQueue(name)
    for i, qn in ipairs(self._queue) do
        if qn == name then
            table.remove(self._queue, i)
            return true
        end
    end
    return false
end

function Waypoint:ClearQueue()
    self._queue = {}
    self._queueIdx = 0
    self._queueRunning = false
end

function Waypoint:GetQueue()
    return self._queue
end

function Waypoint:SetQueueDelay(d)
    self._queueDelay = math.max(0.5, d)
end

function Waypoint:IsQueueRunning()
    return self._queueRunning
end

-- Start sequential teleport through queue (no loop, stops at last)
function Waypoint:StartQueue(flyModule, notifyFn)
    if #self._queue == 0 then return false end
    if self._queueRunning then return false end

    self._queueRunning = true
    self._queueIdx = 0

    task.spawn(function()
        for i, name in ipairs(self._queue) do
            if not self._queueRunning then break end
            self._queueIdx = i

            if notifyFn then
                notifyFn("Waypoint Queue", string.format("[%d/%d] → %s", i, #self._queue, name))
            end

            local ok = self:Teleport(name, flyModule)
            if not ok and notifyFn then
                notifyFn("Waypoint Queue", "Failed to teleport to: " .. name)
            end

            -- Wait before next teleport (unless last)
            if i < #self._queue and self._queueRunning then
                task.wait(self._queueDelay)
            end
        end

        self._queueRunning = false
        self._queueIdx = 0
        if notifyFn then
            notifyFn("Waypoint Queue", "Complete — reached last waypoint")
        end
    end)

    return true
end

function Waypoint:StopQueue()
    self._queueRunning = false
    self._queueIdx = 0
end

return Waypoint
