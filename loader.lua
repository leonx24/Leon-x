
local userKey = _G.Key

if not userKey or userKey == "" then
    game:GetService("Players").LocalPlayer:Kick("Key tidak ditemukan! Silakan dapatkan key via /script di Discord.")
    return
end


local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local robloxId = tostring(localPlayer.UserId)

local hwid = "unknown"
if gethwid then
    hwid = gethwid()
elseif ext and ext.gethwid then
    hwid = ext.gethwid()
end


local botDomain = "https://elbot-production.up.railway.app" -- Ganti dengan domain Railway Anda!

local url = string.format("%s/api/validate-key?key=%s&roblox_id=%s&hwid=%s", 
    botDomain, HttpService:UrlEncode(userKey), HttpService:UrlEncode(robloxId), HttpService:UrlEncode(hwid))

local success, response = pcall(function()
    return game:HttpGet(url)
end)

if not success then
    localPlayer:Kick("Gagal terhubung ke server verifikasi LeonX Hub!")
    return
end


local data
local parseSuccess, parseErr = pcall(function()
    data = HttpService:JSONDecode(response)
end)

if not parseSuccess or not data then
    localPlayer:Kick("Gagal memproses respon verifikasi!")
    return
end


if not data.valid then
    localPlayer:Kick("Verifikasi Gagal: " .. tostring(data.error or "Key tidak valid!"))
    return
end


print("Verifikasi Berhasil: " .. tostring(data.message))


local mainScriptUrl = "https://raw.githubusercontent.com/leonx24/Leon-x/main/main.lua?t=" .. os.time()
local loadSuccess, loadErr = pcall(function()
    loadstring(game:HttpGet(mainScriptUrl))()
end)

if not loadSuccess then
    warn("Gagal memuat main.lua: " .. tostring(loadErr))
    localPlayer:Kick("Gagal memuat script utama!")
end
