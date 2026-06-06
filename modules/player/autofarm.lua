-- Leon X | AutoFarm
-- Auto-clicks/interacts with the nearest interactable object every interval
-- Works by firing ProximityPrompts and clicking via VirtualUser

local AutoFarm = {}
AutoFarm.Name     = "AutoFarm"
AutoFarm.Enabled  = false
AutoFarm.Range    = 20    -- stud radius to search
AutoFarm.Interval = 0.3   -- seconds between interactions

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

local conn = nil

-- Find all ProximityPrompts within range
local function getNearbyPrompts(hrp, range)
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local dist = (hrp.Position - part.Position).Magnitude
                if dist <= range then
                    table.insert(found, {prompt=obj, dist=dist})
                end
            end
        end
    end
    -- sort by distance
    table.sort(found, function(a,b) return a.dist < b.dist end)
    return found
end

-- Fire a ProximityPrompt programmatically
local function firePrompt(prompt)
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        -- try built-in method first (works in most games)
        fireproximityprompt(prompt)
    end)
end

local function loop()
    local lastFire = 0
    conn = RunService.Heartbeat:Connect(function()
        if not AutoFarm.Enabled then return end
        if tick() - lastFire < AutoFarm.Interval then return end
        lastFire = tick()

        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local prompts = getNearbyPrompts(hrp, AutoFarm.Range)
        if #prompts > 0 then
            firePrompt(prompts[1].prompt)
        end
    end)
end

function AutoFarm:Enable()
    self.Enabled = true
    loop()
end

function AutoFarm:Disable()
    self.Enabled = false
    if conn then conn:Disconnect(); conn = nil end
end

function AutoFarm:SetRange(r)    self.Range    = r end
function AutoFarm:SetInterval(i) self.Interval = i end

function AutoFarm:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return AutoFarm
