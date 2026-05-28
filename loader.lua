-- Leon X | loader.lua
-- Load dari file lokal jika ada, fallback ke GitHub

local ok = pcall(function()
    loadstring(readfile("Leon X/main.lua"))()
end)

if not ok then
    loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/affaririzkyf/Leon-X/main/main.lua"
    ))()
end
