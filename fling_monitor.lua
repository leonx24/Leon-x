-- Leon X | Fling Monitor
-- Run this, then GET FLUNG by someone to capture the fling data
-- Output saved to: LeonX/fling_monitor_results.txt

local output = {}
local function log(text)
    table.insert(output, text)
    print(text)
end

local lp = game.Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChildOfClass("Humanoid")

log("=== LEON X FLING MONITOR ===")
log("Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
log("PlaceId: " .. game.PlaceId)
log("Time: " .. os.date())
log("")
log("INSTRUCTIONS:")
log("1. Keep this script running")
log("2. Have someone fling you (kick/hit you)")
log("3. Wait 5 seconds after being flung")
log("4. Check the output file for captured data")
log("")

-- Track velocity history
local velocityHistory = {}
local positionHistory = {}
local MAX_HISTORY = 100
local isRecording = false
local recordingStartTime = 0

-- Hook the suspicious remotes
log("=== HOOKING REMOTES ===")
local remotes = {
    game.ReplicatedStorage:FindFirstChild("01_server"),
    game.ReplicatedStorage:FindFirstChild("02_client"),
    game.ReplicatedStorage:FindFirstChild("03_client")
}

for _, remote in ipairs(remotes) do
    if remote then
        log("Hooking: " .. remote.Name .. " (" .. remote.ClassName .. ")")
        
        if remote:IsA("RemoteEvent") then
            local oldFire = remote.FireServer
            remote.FireServer = function(self, ...)
                local args = {...}
                log("  [FIRED] " .. remote.Name .. " with args:")
                for i, arg in ipairs(args) do
                    log("    [" .. i .. "] " .. tostring(arg))
                end
                return oldFire(self, ...)
            end
            
            -- Also hook OnClientEvent
            remote.OnClientEvent:Connect(function(...)
                local args = {...}
                log("  [RECEIVED] " .. remote.Name .. ":")
                for i, arg in ipairs(args) do
                    log("    [" .. i .. "] " .. tostring(arg))
                end
            end)
        elseif remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function(...)
                local args = {...}
                log("  [INVOKED] " .. remote.Name .. ":")
                for i, arg in ipairs(args) do
                    log("    [" .. i .. "] " .. tostring(arg))
                end
            end
        end
    end
end
log("")

-- Monitor velocity changes
log("=== VELOCITY MONITOR ACTIVE ===")
log("Waiting for fling event...")
log("")

local lastVelocity = hrp.AssemblyLinearVelocity
local lastPosition = hrp.Position
local lastTime = tick()
local flingDetected = false

game:GetService("RunService").RenderStepped:Connect(function()
    if not hrp or not hrp.Parent then return end
    
    local currentVel = hrp.AssemblyLinearVelocity
    local currentPos = hrp.Position
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
            log("Velocity Change: " .. velChange .. " studs/s")
            log("Current Speed: " .. speed .. " studs/s")
            log("")
        end
        
        -- Record velocity data
        if isRecording then
            table.insert(velocityHistory, {
                time = currentTime - recordingStartTime,
                velocity = currentVel,
                position = currentPos,
                magnitude = speed
            })
            
            -- Log every significant change
            if velChange > 20 then
                log(string.format("[%.2fs] Vel: %.1f | Change: %.1f | Pos: (%.1f, %.1f, %.1f)",
                    currentTime - recordingStartTime,
                    speed,
                    velChange,
                    currentPos.X, currentPos.Y, currentPos.Z))
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
            local maxVelChange = 0
            for _, v in ipairs(velocityHistory) do
                if v.magnitude > maxSpeed then maxSpeed = v.magnitude end
            end
            log("  Max Speed: " .. maxSpeed .. " studs/s")
            log("  Samples: " .. #velocityHistory)
            log("  Duration: ~5 seconds")
        end
        
        -- Save to file
        local filename = "LeonX/fling_monitor_results.txt"
        writefile(filename, table.concat(output, "\n"))
        log("")
        log("Results saved to: " .. filename)
        
        -- Reset for next fling
        flingDetected = false
        velocityHistory = {}
    end
    
    lastVelocity = currentVel
    lastPosition = currentPos
    lastTime = currentTime
end)

-- Handle character respawn
lp.CharacterAdded:Connect(function(newChar)
    char = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
    hum = newChar:WaitForChildOfClass("Humanoid")
    lastVelocity = hrp.AssemblyLinearVelocity
    lastPosition = hrp.Position
    flingDetected = false
    velocityHistory = {}
    log("")
    log("=== CHARACTER RESPAWNED ===")
    log("")
end)

-- Initial save
writefile("LeonX/fling_monitor_results.txt", table.concat(output, "\n"))
log("Monitor started. Get flung to capture data!")
