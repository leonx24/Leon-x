-- Leon X | Macro Recorder
-- Records player inputs (keyboard, mouse, jumps) and movement paths
-- Replays using VirtualInputManager for realistic input simulation
-- Includes anti-fall protection
-- Per-map macro storage + Sequential queue playback

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer

local MacroRecorder = {}
MacroRecorder.Name = "MacroRecorder"
MacroRecorder.Enabled = false
MacroRecorder.Recording = false
MacroRecorder.Playing = false
MacroRecorder.Paused = false

-- Settings
MacroRecorder.PlaybackSpeed = 1.0 -- multiplier
MacroRecorder.Loop = false -- loop single macro
MacroRecorder.RecordInterval = 0.05 -- seconds between captures (faster for input accuracy)
MacroRecorder.SmoothPlayback = true -- interpolate between points
MacroRecorder.AntiFall = true -- auto-recover if falling
MacroRecorder.FallThreshold = 5 -- studs below last safe Y = falling
MacroRecorder.RecordInputs = true -- record keyboard/mouse inputs

-- Per-map settings
MacroRecorder.PerMapEnabled = true -- save/load macros per game
MacroRecorder.CurrentPlaceId = tostring(game.PlaceId) -- current game ID

-- Queue system for sequential macro playback
MacroRecorder.QueueEnabled = false -- play macros in sequence
MacroRecorder.QueueLoop = true -- loop entire queue when finished
MacroRecorder.MacroQueue = {} -- { {name="macro1"}, {name="macro2"}, ... }
MacroRecorder.CurrentQueueIndex = 1

-- Data
MacroRecorder.CurrentMacro = nil -- { name = "", points = { {pos, time, cf, inputs}, ... } }
MacroRecorder.SavedMacros = {} -- { [name] = { points = {...}, created = time } }
MacroRecorder.RecordedPoints = {}

local playbackConnection = nil
local recordConnection = nil
local inputConnection = nil
local lastRecordTime = 0
local playbackIndex = 1
local playbackStartTime = 0

-- Input tracking
local pressedKeys = {} -- currently pressed keys
local mouseDown = false
local lastSafePosition = nil -- for anti-fall
local lastSafeY = 0

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function getHRP()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function getWalkSpeed()
    local char = lp.Character
    if not char then return 16 end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.WalkSpeed or 16
end

-- ── File I/O (executor environment) ─────────────────────────────────────────

local MACRO_BASE_DIR = "LeonX/Macros"

-- Get per-map macro directory
local function getMacroDir()
    if MacroRecorder.PerMapEnabled and MacroRecorder.CurrentPlaceId then
        return MACRO_BASE_DIR .. "/" .. MacroRecorder.CurrentPlaceId
    end
    return MACRO_BASE_DIR
end

local function ensureDir()
    -- Ensure base directory exists
    if isfolder and not isfolder(MACRO_BASE_DIR) then
        makefolder(MACRO_BASE_DIR)
    end
    -- Ensure per-map directory exists
    local dir = getMacroDir()
    if isfolder and not isfolder(dir) then
        makefolder(dir)
    end
end

local function saveToFile(name, data)
    ensureDir()
    local path = getMacroDir() .. "/" .. name .. ".json"
    local json = game:GetService("HttpService"):JSONEncode(data)
    if writefile then
        pcall(function() writefile(path, json) end)
        return true
    end
    return false
end

local function loadFromFile(name)
    local path = getMacroDir() .. "/" .. name .. ".json"
    if readfile and isfile and isfile(path) then
        local ok, result = pcall(function() return readfile(path) end)
        if ok and result then
            local ok2, data = pcall(function() 
                return game:GetService("HttpService"):JSONDecode(result) 
            end)
            if ok2 then return data end
        end
    end
    return nil
end

local function deleteFile(name)
    local path = getMacroDir() .. "/" .. name .. ".json"
    if delfile and isfile and isfile(path) then
        pcall(function() delfile(path) end)
        return true
    end
    return false
end

local function listFiles()
    ensureDir()
    local files = {}
    local dir = getMacroDir()
    if listfiles then
        pcall(function()
            local raw = listfiles(dir)
            for _, filepath in ipairs(raw or {}) do
                local name = filepath:match("([^/\\]+)%.json$")
                if name then
                    files[#files + 1] = name
                end
            end
        end)
    end
    return files
end

-- Get list of all map folders (for browsing saved macros from other maps)
function MacroRecorder:GetMapFolders()
    local folders = {}
    if listfiles and isfolder and isfolder(MACRO_BASE_DIR) then
        pcall(function()
            local raw = listfiles(MACRO_BASE_DIR)
            for _, path in ipairs(raw or {}) do
                if isfolder(path) then
                    local name = path:match("([^/\\]+)$")
                    if name then
                        folders[#folders + 1] = name
                    end
                end
            end
        end)
    end
    return folders
end

-- List macros from a specific map/placeId
function MacroRecorder:ListMacrosFromMap(placeId)
    local dir = MACRO_BASE_DIR .. "/" .. placeId
    local files = {}
    if listfiles and isfolder and isfolder(dir) then
        pcall(function()
            local raw = listfiles(dir)
            for _, filepath in ipairs(raw or {}) do
                local name = filepath:match("([^/\\]+)%.json$")
                if name then
                    files[#files + 1] = name
                end
            end
        end)
    end
    table.sort(files)
    return files
end

-- ── Recording ────────────────────────────────────────────────────────────────

-- Get current pressed keys state
local function getCurrentInputs()
    local inputs = {}
    
    -- Movement keys (WASD)
    if UIS:IsKeyDown(Enum.KeyCode.W) then inputs.W = true end
    if UIS:IsKeyDown(Enum.KeyCode.A) then inputs.A = true end
    if UIS:IsKeyDown(Enum.KeyCode.S) then inputs.S = true end
    if UIS:IsKeyDown(Enum.KeyCode.D) then inputs.D = true end
    
    -- Jump
    if UIS:IsKeyDown(Enum.KeyCode.Space) then inputs.Space = true end
    
    -- Sprint/Shift
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then inputs.LShift = true end
    if UIS:IsKeyDown(Enum.KeyCode.RightShift) then inputs.RShift = true end
    
    -- Crouch
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then inputs.LCtrl = true end
    
    -- Mouse buttons
    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then inputs.MB1 = true end
    if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then inputs.MB2 = true end
    
    -- Check if any input is active
    local hasInput = false
    for _ in pairs(inputs) do hasInput = true; break end
    
    return hasInput and inputs or nil
end

function MacroRecorder:StartRecording(name)
    if self.Recording then return false end
    if self.Playing then self:StopPlayback() end
    
    self.Recording = true
    self.RecordedPoints = {}
    self.CurrentMacro = {
        name = name or "macro_" .. os.time(),
        points = {},
        created = os.time()
    }
    
    -- Reset tracking
    pressedKeys = {}
    mouseDown = false
    lastSafePosition = nil
    lastSafeY = 0
    lastRecordTime = 0
    local startTime = tick()
    
    -- Connect input tracking
    inputConnection = UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            pressedKeys[input.KeyCode.Name] = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            mouseDown = true
        end
    end)
    
    local inputEndConn = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            pressedKeys[input.KeyCode.Name] = nil
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            mouseDown = false
        end
    end)
    
    recordConnection = RunService.Heartbeat:Connect(function(dt)
        if not self.Recording then return end
        
        local now = tick() - startTime
        if now - lastRecordTime < self.RecordInterval then return end
        lastRecordTime = now
        
        local hrp = getHRP()
        if not hrp then return end
        
        local pos = hrp.Position
        
        -- Update safe position (only when not falling fast)
        local velocity = hrp.AssemblyLinearVelocity
        if velocity.Y > -10 then -- not falling fast
            lastSafePosition = pos
            lastSafeY = pos.Y
        end
        
        -- Get current inputs
        local inputs = self.RecordInputs and getCurrentInputs() or nil
        
        self.RecordedPoints[#self.RecordedPoints + 1] = {
            pos = { pos.X, pos.Y, pos.Z },
            cf = { hrp.CFrame:GetComponents() },
            time = now,
            look = { hrp.CFrame.LookVector.X, hrp.CFrame.LookVector.Y, hrp.CFrame.LookVector.Z },
            inputs = inputs, -- keyboard/mouse state
            jumping = inputs and inputs.Space or false,
            moving = inputs and (inputs.W or inputs.A or inputs.S or inputs.D) or false
        }
    end)
    
    print("[Leon X] MacroRecorder: Recording started - " .. (name or "unnamed"))
    return true
end

function MacroRecorder:StopRecording()
    if not self.Recording then return nil end
    
    self.Recording = false
    if recordConnection then
        recordConnection:Disconnect()
        recordConnection = nil
    end
    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end
    
    if self.CurrentMacro then
        self.CurrentMacro.points = self.RecordedPoints
        self.CurrentMacro.duration = #self.RecordedPoints > 0 
            and self.RecordedPoints[#self.RecordedPoints].time 
            or 0
        
        -- Count input events
        local jumpCount = 0
        local moveCount = 0
        for _, p in ipairs(self.RecordedPoints) do
            if p.jumping then jumpCount = jumpCount + 1 end
            if p.moving then moveCount = moveCount + 1 end
        end
        
        print("[Leon X] MacroRecorder: Stopped. Captured " .. #self.RecordedPoints .. " points (" .. 
            string.format("%.1f", self.CurrentMacro.duration) .. "s, " .. jumpCount .. " jumps, " .. moveCount .. " moves)")
        
        return self.CurrentMacro
    end
    
    return nil
end

-- ── Playback ─────────────────────────────────────────────────────────────────

-- Simulate keyboard/mouse inputs using VirtualInputManager + Humanoid
local function simulateInputs(inputs)
    if not inputs then return end
    
    local hum = getHumanoid()
    
    -- Movement keys via VirtualInputManager
    local keyMap = {
        W = Enum.KeyCode.W,
        A = Enum.KeyCode.A,
        S = Enum.KeyCode.S,
        D = Enum.KeyCode.D,
        LShift = Enum.KeyCode.LeftShift,
        RShift = Enum.KeyCode.RightShift,
        LCtrl = Enum.KeyCode.LeftControl
    }
    
    for keyName, pressed in pairs(inputs) do
        if keyMap[keyName] then
            pcall(function()
                VirtualInputManager:SetKeyDown(keyMap[keyName])
            end)
        end
    end
    
    -- Jump via Humanoid (more reliable than VirtualInputManager for jump)
    if inputs.Space and hum then
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
    
    -- Mouse buttons
    if inputs.MB1 then
        pcall(function()
            VirtualInputManager:SetMouseButtonDown(0)
        end)
    end
    if inputs.MB2 then
        pcall(function()
            VirtualInputManager:SetMouseButtonDown(1)
        end)
    end
end

-- Release all simulated inputs
local function releaseAllInputs()
    pcall(function()
        -- Release all movement keys
        VirtualInputManager:SetKeyUp(Enum.KeyCode.W)
        VirtualInputManager:SetKeyUp(Enum.KeyCode.A)
        VirtualInputManager:SetKeyUp(Enum.KeyCode.S)
        VirtualInputManager:SetKeyUp(Enum.KeyCode.D)
        VirtualInputManager:SetKeyUp(Enum.KeyCode.Space)
        VirtualInputManager:SetKeyUp(Enum.KeyCode.LeftShift)
        VirtualInputManager:SetKeyUp(Enum.KeyCode.RightShift)
        VirtualInputManager:SetKeyUp(Enum.KeyCode.LeftControl)
        
        -- Release mouse buttons
        VirtualInputManager:SetMouseButtonUp(0)
        VirtualInputManager:SetMouseButtonUp(1)
    end)
end

-- Check if player is falling and recover
local function checkAndRecoverFromFall(hrp)
    if not hrp or not MacroRecorder.AntiFall then return false end
    
    local pos = hrp.Position
    local velocity = hrp.AssemblyLinearVelocity
    
    -- Check if falling (high negative Y velocity)
    if velocity.Y < -20 then -- falling fast
        -- Teleport back to last safe position
        if lastSafePosition then
            hrp.CFrame = CFrame.new(lastSafePosition)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) -- reset velocity
            print("[Leon X] MacroRecorder: Anti-fall activated! Recovered to safe position")
            return true
        end
    end
    
    return false
end

function MacroRecorder:StartPlayback(macro)
    if not macro or not macro.points or #macro.points == 0 then
        print("[Leon X] MacroRecorder: No macro to play")
        return false
    end
    if self.Recording then self:StopRecording() end
    if self.Playing then self:StopPlayback() end
    
    self.Playing = true
    self.Paused = false
    self.CurrentMacro = macro
    playbackIndex = 1
    playbackStartTime = tick()
    lastSafePosition = nil
    lastSafeY = 0
    
    local points = macro.points
    local speed = self.PlaybackSpeed
    local smooth = self.SmoothPlayback
    local useInputs = self.RecordInputs
    
    -- Initialize safe position from first point
    if points[1] and points[1].pos then
        lastSafePosition = Vector3.new(points[1].pos[1], points[1].pos[2], points[1].pos[3])
        lastSafeY = points[1].pos[2]
    end
    
    -- Track playback timing
    local playbackElapsed = 0
    local lastJumpState = false
    local lastAppliedPos = nil -- track last position for velocity calculation
    
    playbackConnection = RunService.Heartbeat:Connect(function(dt)
        if not self.Playing or self.Paused then return end
        
        -- Advance playback time (scaled by speed)
        playbackElapsed = playbackElapsed + dt * speed
        
        -- Find surrounding points for interpolation
        -- points are sorted by time, find where playbackElapsed falls
        local idxA = playbackIndex
        local idxB = playbackIndex + 1
        
        -- Advance index if we've passed current segment
        while idxB <= #points do
            local timeB = points[idxB].time or 0
            if playbackElapsed >= timeB then
                idxA = idxB
                idxB = idxA + 1
                playbackIndex = idxA
            else
                break
            end
        end
        
        -- Check if we've finished all points
        if idxA > #points or (idxB > #points and playbackElapsed > (points[#points].time or 0)) then
            -- Check if queue mode is active
            if self.QueueEnabled then
                -- Stop current macro playback first
                self.Playing = false
                if playbackConnection then
                    playbackConnection:Disconnect()
                    playbackConnection = nil
                end
                releaseAllInputs()
                -- Advance to next macro in queue
                self:AdvanceQueue()
                return
            elseif self.Loop then
                playbackIndex = 1
                playbackElapsed = 0
                lastJumpState = false
                lastAppliedPos = nil
                releaseAllInputs()
                return
            else
                self:StopPlayback()
                return
            end
        end
        
        local hrp = getHRP()
        if not hrp then return end
        
        local pointA = points[idxA]
        local pointB = points[idxB]
        
        if not pointA then return end
        
        -- Anti-fall check
        if checkAndRecoverFromFall(hrp) then
            return
        end
        
        -- Calculate interpolation factor (alpha) between pointA and pointB
        local timeA = pointA.time or 0
        local timeB = pointB and (pointB.time or timeA + 0.05) or timeA + 0.05
        local segmentDuration = timeB - timeA
        local alpha = 0
        if segmentDuration > 0 then
            alpha = math.clamp((playbackElapsed - timeA) / segmentDuration, 0, 1)
        end
        
        -- Get positions
        local posA = Vector3.new(pointA.pos[1], pointA.pos[2], pointA.pos[3])
        local posB = pointB and Vector3.new(pointB.pos[1], pointB.pos[2], pointB.pos[3]) or posA
        
        -- Interpolate position smoothly
        local targetPos = posA:Lerp(posB, alpha)
        
        -- Get or build CFrame
        local targetCF
        if pointA.cf and #pointA.cf == 12 and pointB and pointB.cf and #pointB.cf == 12 then
            local cfA = CFrame.new(unpack(pointA.cf))
            local cfB = CFrame.new(unpack(pointB.cf))
            targetCF = cfA:Lerp(cfB, alpha)
        elseif pointA.cf and #pointA.cf == 12 then
            targetCF = CFrame.new(unpack(pointA.cf))
        else
            targetCF = CFrame.new(targetPos)
        end
        
        -- Apply smooth interpolated CFrame (frame-perfect playback)
        hrp.CFrame = targetCF
        
        -- Calculate movement velocity so Humanoid detects walking and plays animation
        local moveVelocity = Vector3.zero
        if lastAppliedPos and dt > 0 then
            local delta = targetPos - lastAppliedPos
            moveVelocity = Vector3.new(delta.X / dt, 0, delta.Z / dt)
        end
        lastAppliedPos = targetPos
        
        -- Set velocity so Humanoid plays walking animation
        pcall(function()
            hrp.AssemblyLinearVelocity = moveVelocity
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
        
        -- Force Humanoid to recognize movement state for animation
        local hum = getHumanoid()
        if hum then
            local moveSpeed = Vector3.new(moveVelocity.X, 0, moveVelocity.Z).Magnitude
            if moveSpeed > 1 then
                pcall(function()
                    hum.AutoRotate = true
                end)
            end
        end
        
        -- Handle jumping: detect if character jumped between points
        if useInputs and pointA.inputs and pointA.inputs.Space and not lastJumpState then
            -- Jump was pressed at this point - apply jump force
            local hum = getHumanoid()
            if hum then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
            end
            lastJumpState = true
        elseif not (useInputs and pointA.inputs and pointA.inputs.Space) then
            lastJumpState = false
        end
        
        -- Update safe position
        local currentY = hrp.Position.Y
        if currentY >= lastSafeY - 2 then
            lastSafePosition = hrp.Position
            lastSafeY = currentY
        end
        
        -- Simulate mouse clicks if recorded
        if useInputs and pointA.inputs then
            if pointA.inputs.MB1 then
                pcall(function() VirtualInputManager:SetMouseButtonDown(0) end)
            else
                pcall(function() VirtualInputManager:SetMouseButtonUp(0) end)
            end
            if pointA.inputs.MB2 then
                pcall(function() VirtualInputManager:SetMouseButtonDown(1) end)
            else
                pcall(function() VirtualInputManager:SetMouseButtonUp(1) end)
            end
        end
    end)
    
    print("[Leon X] MacroRecorder: Playing - " .. (macro.name or "unnamed") .. 
        " (" .. #points .. " points, " .. speed .. "x speed" .. (useInputs and ", inputs" or "") .. ")")
    return true
end

function MacroRecorder:StopPlayback()
    self.Playing = false
    self.Paused = false
    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end
    
    -- Release all simulated inputs
    releaseAllInputs()
    
    playbackIndex = 1
    print("[Leon X] MacroRecorder: Playback stopped")
end

function MacroRecorder:PausePlayback()
    if self.Playing then
        self.Paused = not self.Paused
        print("[Leon X] MacroRecorder: " .. (self.Paused and "Paused" or "Resumed"))
    end
end

-- ── Save/Load ────────────────────────────────────────────────────────────────

function MacroRecorder:SaveMacro(name, macro)
    if not macro then macro = self.CurrentMacro end
    if not macro or not macro.points or #macro.points == 0 then
        return false, "No macro to save"
    end
    
    macro.name = name or macro.name or "macro_" .. os.time()
    macro.saved = os.time()
    
    -- Save to file
    local data = {
        name = macro.name,
        points = macro.points,
        duration = macro.duration,
        created = macro.created,
        saved = macro.saved,
        version = 1
    }
    
    local ok = saveToFile(macro.name, data)
    if ok then
        self.SavedMacros[macro.name] = macro
        print("[Leon X] MacroRecorder: Saved - " .. macro.name)
        return true
    end
    return false, "Failed to save"
end

function MacroRecorder:LoadMacro(name)
    local data = loadFromFile(name)
    if data and data.points then
        local macro = {
            name = data.name or name,
            points = data.points,
            duration = data.duration or 0,
            created = data.created or 0,
            saved = data.saved or 0
        }
        self.SavedMacros[name] = macro
        self.CurrentMacro = macro
        print("[Leon X] MacroRecorder: Loaded - " .. name .. 
            " (" .. #macro.points .. " points)")
        return macro
    end
    return nil
end

function MacroRecorder:DeleteMacro(name)
    local ok = deleteFile(name)
    if ok then
        self.SavedMacros[name] = nil
        if self.CurrentMacro and self.CurrentMacro.name == name then
            self.CurrentMacro = nil
        end
        print("[Leon X] MacroRecorder: Deleted - " .. name)
    end
    return ok
end

function MacroRecorder:ListMacros()
    local files = listFiles()
    -- Also load metadata for each
    for _, name in ipairs(files) do
        if not self.SavedMacros[name] then
            local data = loadFromFile(name)
            if data then
                self.SavedMacros[name] = {
                    name = data.name or name,
                    points = data.points,
                    duration = data.duration or 0,
                    created = data.created or 0
                }
            end
        end
    end
    
    local names = {}
    for name, _ in pairs(self.SavedMacros) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

-- ── Export/Import ────────────────────────────────────────────────────────────

function MacroRecorder:ExportMacro(name)
    local macro = self.SavedMacros[name]
    if not macro then
        macro = self:LoadMacro(name)
    end
    if not macro then return nil, "Macro not found" end
    
    local data = {
        name = macro.name,
        points = macro.points,
        duration = macro.duration,
        created = macro.created,
        version = 1,
        exported = os.time(),
        exportedBy = lp.Name
    }
    
    local json = game:GetService("HttpService"):JSONEncode(data)
    
    -- Copy to clipboard if available
    if setclipboard then
        pcall(function() setclipboard(json) end)
        print("[Leon X] MacroRecorder: Exported to clipboard - " .. name)
    end
    
    return json
end

function MacroRecorder:ImportMacro(jsonStr)
    local ok, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(jsonStr)
    end)
    
    if not ok or not data or not data.points then
        return nil, "Invalid macro data"
    end
    
    local name = data.name or "imported_" .. os.time()
    
    -- Avoid overwriting
    local files = listFiles()
    for _, f in ipairs(files) do
        if f == name then
            name = name .. "_" .. math.random(1000, 9999)
            break
        end
    end
    
    data.name = name
    local saved = saveToFile(name, data)
    if saved then
        self.SavedMacros[name] = {
            name = name,
            points = data.points,
            duration = data.duration or 0,
            created = data.created or 0
        }
        print("[Leon X] MacroRecorder: Imported - " .. name)
        return name
    end
    return nil, "Failed to import"
end

-- ── Settings ─────────────────────────────────────────────────────────────────

function MacroRecorder:SetPlaybackSpeed(speed)
    self.PlaybackSpeed = tonumber(speed) or 1.0
end

function MacroRecorder:SetLoop(loop)
    self.Loop = loop
end

function MacroRecorder:SetRecordInterval(interval)
    self.RecordInterval = tonumber(interval) or 0.1
end

function MacroRecorder:SetSmoothPlayback(smooth)
    self.SmoothPlayback = smooth
end

function MacroRecorder:SetAntiFall(enabled)
    self.AntiFall = enabled
end

function MacroRecorder:SetRecordInputs(enabled)
    self.RecordInputs = enabled
end

function MacroRecorder:SetFallThreshold(threshold)
    self.FallThreshold = tonumber(threshold) or 5
end

-- ── Queue System ─────────────────────────────────────────────────────────────

-- Add a macro to the playback queue
function MacroRecorder:AddToQueue(macroName)
    if not macroName or macroName == "" then return false end
    for _, item in ipairs(self.MacroQueue) do
        if item.name == macroName then
            print("[Leon X] MacroRecorder: Already in queue - " .. macroName)
            return false
        end
    end
    self.MacroQueue[#self.MacroQueue + 1] = { name = macroName }
    print("[Leon X] MacroRecorder: Added to queue - " .. macroName)
    return true
end

-- Remove a macro from the queue
function MacroRecorder:RemoveFromQueue(macroName)
    for i, item in ipairs(self.MacroQueue) do
        if item.name == macroName then
            table.remove(self.MacroQueue, i)
            print("[Leon X] MacroRecorder: Removed from queue - " .. macroName)
            return true
        end
    end
    return false
end

-- Clear the entire queue
function MacroRecorder:ClearQueue()
    self.MacroQueue = {}
    self.CurrentQueueIndex = 1
    self.QueueEnabled = false
    print("[Leon X] MacroRecorder: Queue cleared")
end

-- Get queue list
function MacroRecorder:GetQueue()
    return self.MacroQueue
end

-- Set queue loop mode
function MacroRecorder:SetQueueLoop(loop)
    self.QueueLoop = loop
end

-- Start queue playback
function MacroRecorder:StartQueuePlayback()
    if #self.MacroQueue == 0 then
        print("[Leon X] MacroRecorder: Queue is empty")
        return false
    end
    
    self.QueueEnabled = true
    self.CurrentQueueIndex = 1
    
    -- Load and play first macro in queue
    local firstMacro = self.MacroQueue[1]
    if firstMacro then
        local loaded = self:LoadMacro(firstMacro.name)
        if loaded then
            self:StartPlayback(loaded)
            print("[Leon X] MacroRecorder: Queue playback started - " .. firstMacro.name)
            return true
        end
    end
    return false
end

-- Stop queue playback
function MacroRecorder:StopQueuePlayback()
    self.QueueEnabled = false
    self.CurrentQueueIndex = 1
    self:StopPlayback()
    print("[Leon X] MacroRecorder: Queue playback stopped")
end

-- Advance to next macro in queue (called automatically when current finishes)
function MacroRecorder:AdvanceQueue()
    if not self.QueueEnabled then return false end
    
    self.CurrentQueueIndex = self.CurrentQueueIndex + 1
    
    -- Check if we've finished all macros in queue
    if self.CurrentQueueIndex > #self.MacroQueue then
        if self.QueueLoop then
            -- Loop back to first macro
            self.CurrentQueueIndex = 1
            print("[Leon X] MacroRecorder: Queue loop - back to first macro")
        else
            -- Queue finished
            self.QueueEnabled = false
            self.CurrentQueueIndex = 1
            print("[Leon X] MacroRecorder: Queue finished")
            return false
        end
    end
    
    -- Load and play next macro
    local nextMacro = self.MacroQueue[self.CurrentQueueIndex]
    if nextMacro then
        task.spawn(function()
            task.wait(0.5) -- Brief pause between macros
            local loaded = self:LoadMacro(nextMacro.name)
            if loaded then
                self:StartPlayback(loaded)
                print("[Leon X] MacroRecorder: Queue playing - " .. nextMacro.name .. 
                    " (" .. self.CurrentQueueIndex .. "/" .. #self.MacroQueue .. ")")
            end
        end)
        return true
    end
    return false
end

-- Get queue status string
function MacroRecorder:GetQueueStatus()
    if not self.QueueEnabled then return "Queue: Inactive" end
    return "Queue: " .. self.CurrentQueueIndex .. "/" .. #self.MacroQueue .. 
        (self.QueueLoop and " (looping)" or "")
end

-- ── Status ───────────────────────────────────────────────────────────────────

function MacroRecorder:GetStatus()
    local status = ""
    if self.Recording then
        status = "Recording (" .. #self.RecordedPoints .. " points)"
    elseif self.Playing then
        status = "Playing" .. (self.Paused and " (Paused)" or "") .. 
            " [" .. playbackIndex .. "/" .. #(self.CurrentMacro and self.CurrentMacro.points or {}) .. "]"
    else
        status = "Idle"
    end
    
    -- Add queue info if active
    if self.QueueEnabled then
        status = status .. " | Queue: " .. self.CurrentQueueIndex .. "/" .. #self.MacroQueue
    end
    
    return status
end

function MacroRecorder:GetCurrentMacro()
    return self.CurrentMacro
end

-- ── Cleanup ──────────────────────────────────────────────────────────────────

function MacroRecorder:Disable()
    self:StopRecording()
    self:StopPlayback()
    self.Enabled = false
end

return MacroRecorder
