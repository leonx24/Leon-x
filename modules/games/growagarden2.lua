-- Leon X | Grow a Garden 2
-- PlaceId: 97598239454123
-- Uses Cmdr command system + Replica data

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local GAG = {}
GAG.Name = "Grow a Garden 2"
GAG.PlaceIds = { 97598239454123 }
GAG.Enabled = false

-- ── Cmdr command helper ─────────────────────────────────────────────────────
local Cmdr
local function getCmdr()
    if Cmdr then return Cmdr end
    local ok, mod = pcall(function()
        return require(ReplicatedStorage:WaitForChild("CmdrClient", 5))
    end)
    if ok and mod then
        Cmdr = mod
        return Cmdr
    end
    return nil
end

local function runCmd(cmd)
    local c = getCmdr()
    if c and c.Run then
        pcall(function() c:Run(cmd) end)
    end
end

-- ── Replica data reader ─────────────────────────────────────────────────────
local function getReplicaData()
    local data = {}
    -- Scan player folders for value objects (inventory, coins, etc.)
    pcall(function()
        for _, folder in ipairs(lp:GetChildren()) do
            if folder:IsA("Folder") or folder:IsA("Configuration") then
                data[folder.Name] = {}
                for _, val in ipairs(folder:GetDescendants()) do
                    if val:IsA("ValueBase") then
                        data[folder.Name][val.Name] = val.Value
                    end
                end
            end
        end
    end)
    return data
end

-- ── Auto-collect: walk to nearby collectibles ───────────────────────────────
local collectConn = nil
local function startAutoCollect()
    if collectConn then collectConn:Disconnect() end
    collectConn = RunService.Heartbeat:Connect(function()
        if not GAG.Enabled then return end
        pcall(function()
            local char = lp.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- Find nearby collectible items in workspace
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Part") or obj:IsA("MeshPart") then
                    local name = obj.Name:lower()
                    if name:find("collect") or name:find("coin") or name:find("drop")
                       or name:find("pickup") or name:find("loot") then
                        local dist = (obj.Position - hrp.Position).Magnitude
                        if dist < 30 then
                            -- Try ProximityPrompt
                            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                pcall(function() prompt:Fire() end)
                            end
                            -- Try ClickDetector
                            local click = obj:FindFirstChildOfClass("ClickDetector")
                            if click then
                                pcall(function() click:FireServer() end)
                            end
                        end
                    end
                end
            end
        end)
    end)
end

local function stopAutoCollect()
    if collectConn then collectConn:Disconnect(); collectConn = nil end
end

-- ── Module interface ────────────────────────────────────────────────────────
function GAG:Init()
    -- Pre-load Cmdr reference
    getCmdr()
end

function GAG:Enable()
    self.Enabled = true
    startAutoCollect()
end

function GAG:Disable()
    self.Enabled = false
    stopAutoCollect()
end

-- ── Wire UI ─────────────────────────────────────────────────────────────────
function GAG:WireUI(tab)
    tab:Section({ Title = "Grow a Garden 2" })

    -- Auto Collect toggle
    tab:Toggle({
        Title    = "Auto Collect",
        Flag     = "GAG_AutoCollect",
        Default  = false,
        Callback = function(v)
            if v then
                GAG:Enable()
            else
                GAG:Disable()
            end
        end
    })

    tab:Section({ Title = "Quick Actions (Cmdr)" })

    tab:Button({
        Title    = "Give All Seeds",
        Callback = function() runCmd("giveallseeds") end
    })

    tab:Button({
        Title    = "Give Full Inventory",
        Callback = function() runCmd("givefullinventory") end
    })

    tab:Button({
        Title    = "Fill Garden",
        Callback = function() runCmd("fillgarden") end
    })

    tab:Button({
        Title    = "Force Restock",
        Callback = function() runCmd("forcerestock") end
    })

    tab:Button({
        Title    = "Clear Inventory",
        Callback = function() runCmd("clearinventory") end
    })

    tab:Button({
        Title    = "Expand Garden",
        Callback = function() runCmd("expandgarden") end
    })

    tab:Section({ Title = "Info" })

    tab:Button({
        Title    = "Scan Player Data",
        Callback = function()
            local data = getReplicaData()
            for folder, vals in pairs(data) do
                print("═══ " .. folder .. " ═══")
                for name, val in pairs(vals) do
                    print("  " .. name .. " = " .. tostring(val))
                end
            end
        end
    })

    tab:Paragraph({
        Title   = "Note",
        Content = "Cmdr commands may only work if you have admin/dev access. Auto Collect works by scanning nearby parts."
    })
end

return GAG
