-- Leon X | Fling Monitor v2
-- Run this, then GET FLUNG by someone to capture the fling data
-- Output saved to: LeonX/fling_monitor_results.txt

local output = {}
local function log(text)
    table.insert(output, text)
    print(text)
end

local function saveFile()
    pcall(function()
        writefile("LeonX/fling_monitor_results.txt", table.concat(output, "\n"))
    end)
end

log("=== LEON X FLING MONITOR v2 ===")
log("Time: " .. os.date())
log("")

local lp = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

-- Wait for character
log("Waiting for character...")
local char = lp.Character
if not char then
    char = lp.CharacterAdded:Wait()
end
log("Character loaded: " .. char.Name)

local hrp = char:WaitForChild("HumanoidRootPart", 10)
if not hrp then
    log("ERROR: Could not find HumanoidRootPart")
    saveFile()
    return
end
log("HRP found: " .. tostring(hrp))
log("")

-- Track velocity history
local velocityHistory = {}
local isRecording = false
local recordingStartTime = 0

-- Monitor velocity changes
log("=== VELOCITY MONITOR ACTIVE ===")
log("Waiting for fling event...")
log("(Have someone kick/hit you)")
log("")

local lastVelocity = hrp.AssemblyLinearVelocity
local lastTime = tick()
local flingDetected = false

-- Start monitoring
local connection = RunService.RenderStepped:Connect(function()
    if not hrp or not hrp.Parent then return end
    
    local currentVel = hrp.AssemblyLinearVelocity
    local currentTime = tick()
    local dt = currentTime - lastTime
    
    -- Calculate velocity change
    local velChange = (currentVel - lastVelocity).Magnitude
    local speed = currentVel.Magnitude
    
    -- Detect sudden velocity spike (fling)
    if velChange > 50 or speed > 100 then
        if not flingDetected then
            flingDetected = true
            isRecording = true
            recordingStartTime = currentTime
            log("!!! FLING DETECTED !!!")
            log("Time: " .. os.date())
            log("Velocity Change: " .. string.format("%.1f", velChange) .. " studs/s")
            log("Current Speed: " .. string.format("%.1f", speed) .. " studs/s")
            log("")
            saveFile()
        end
        
        -- Record velocity data
        if isRecording then
            table.insert(velocityHistory, {
                time = currentTime - recordingStartTime,
                velocity = currentVel,
                magnitude = speed
            })
            
            -- Log every significant change
            if velChange > 20 then
                log(string.format("[%.2fs] Vel: %.1f | Change: %.1f",
                    currentTime - recordingStartTime,
                    speed,
                    velChange))
            end
        end
    end
    
    -- Stop recording after 5 seconds of fling
    if isRecording and (currentTime - recordingStartTime) > 5 then
        isRecording = false
        log("")
        log("=== RECORDING COMPLETE ===")
        
        -- Save velocity history
        log("")
        log("=== VELOCITY HISTORY (first 20 samples) ===")
        for i = 1, math.min(20, #velocityHistory) do
            local v = velocityHistory[i]
            log(string.format("  [%.2fs] Speed: %.1f | Vel: (%.1f, %.1f, %.1f)",
                v.time, v.magnitude, v.velocity.X, v.velocity.Y, v.velocity.Z))
        end
        
        -- Summary
        log("")
        log("=== SUMMARY ===")
        if #velocityHistory > 0 then
            local maxSpeed = 0
            for _, v in ipairs(velocityHistory) do
                if v.magnitude > maxSpeed then maxSpeed = v.magnitude end
            end
            log("  Max Speed: " .. string.format("%.1f", maxSpeed) .. " studs/s")
            log("  Samples: " .. #velocityHistory)
        end
        
        -- Save to file
        log("")
        log("Results saved to: LeonX/fling_monitor_results.txt")
        saveFile()
        
        -- Reset for next fling
        flingDetected = false
        velocityHistory = {}
    end
    
    lastVelocity = currentVel
    lastTime = currentTime
end)

-- Handle character respawn
lp.CharacterAdded:Connect(function(newChar)
    log("")
    log("=== CHARACTER RESPAWNED ===")
    char = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart", 10)
    if hrp then
        lastVelocity = hrp.AssemblyLinearVelocity
        flingDetected = false
        velocityHistory = {}
        log("New HRP found")
    end
    log("")
    saveFile()
end)

-- Save initial state
saveFile()
log("Monitor started. Get flung to capture data!")
