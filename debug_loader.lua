-- Leon X Debug Script
-- Run this in your executor to diagnose loading issues

print("=== Leon X Debug ===")

-- Test 1: Basic executor functionality
print("[1] Testing basic print... OK")

-- Test 2: HttpGet
local httpOk, httpErr = pcall(function()
    local result = game:HttpGet("https://raw.githubusercontent.com/leonx24/Leon-x/main/version.txt")
    print("[2] HttpGet works, version:", result)
end)
if not httpOk then
    warn("[2] HttpGet FAILED:", httpErr)
    return
end

-- Test 3: Load WindUI
local windOk, windErr = pcall(function()
    local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    print("[3] WindUI loaded:", WindUI ~= nil)
end)
if not windOk then
    warn("[3] WindUI FAILED:", windErr)
    return
end

-- Test 4: Load main.lua
print("[4] Loading main.lua...")
local mainOk, mainErr = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/leonx24/Leon-x/main/main.lua?t="..os.time()))()
end)
if not mainOk then
    warn("[4] main.lua FAILED:", mainErr)
else
    print("[4] main.lua loaded successfully!")
end

print("=== Debug Complete ===")
