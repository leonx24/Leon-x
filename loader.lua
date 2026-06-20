-- Leon X Loader
print("[Leon X] Loader starting...")

local ok, src = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/leonx24/Leon-x/main/main.lua?t="..os.time())
end)

if not ok then
    warn("[Leon X] FAILED to fetch main.lua: "..tostring(src))
    return
end

print("[Leon X] Fetched main.lua ("..#src.." bytes)")

local fn, err = loadstring(src)
if not fn then
    warn("[Leon X] LOADSTRING ERROR: "..tostring(err))
    return
end

print("[Leon X] Executing main.lua...")

local ok2, runErr = pcall(fn)
if not ok2 then
    warn("[Leon X] RUNTIME ERROR: "..tostring(runErr))
end
