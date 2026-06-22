-- Leon X | Auto Clicker
-- Automatically clicks at configurable CPS (clicks per second)
-- Works with mouse button 1 (left click) or tool activation
-- Useful for clicker games, grinding, and AFK farming

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer

local AutoClicker = {}
AutoClicker.Name = "AutoClicker"
AutoClicker.Enabled = false
AutoClicker.CPS = 10 -- clicks per second
AutoClicker.ClickType = "mouse" -- "mouse" (VirtualInputManager) or "tool" (Tool:Activate)
AutoClicker.HoldDown = false -- hold mouse button down instead of clicking
AutoClicker.RandomDelay = true -- add slight randomization to avoid detection

local connection = nil
local lastClickTime = 0
local holdConnection = nil

local function getEquippedTool()
    local char = lp.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
    end
    return nil
end

local function doClick()
    pcall(function()
        if AutoClicker.ClickType == "tool" then
            -- Use equipped tool
            local tool = getEquippedTool()
            if tool then
                tool:Activate()
            end
        else
            -- Use VirtualInputManager mouse click
            VirtualInputManager:SetMouseButtonDown(0) -- left click down
            task.wait(0.01) -- brief hold
            VirtualInputManager:SetMouseButtonUp(0) -- left click up
        end
    end)
end

function AutoClicker:Enable()
    if self.Enabled then return end
    self.Enabled = true
    
    -- Calculate interval from CPS
    local baseInterval = 1 / math.max(1, self.CPS)
    
    connection = RunService.Heartbeat:Connect(function(dt)
        if not self.Enabled then return end
        
        local now = tick()
        local interval = baseInterval
        
        -- Add randomization (±10%) to avoid detection patterns
        if self.RandomDelay then
            interval = interval * (0.9 + math.random() * 0.2)
        end
        
        if now - lastClickTime >= interval then
            lastClickTime = now
            
            if self.HoldDown and self.ClickType == "mouse" then
                -- Hold mode: press down, release on disable
                if not holdConnection then
                    pcall(function()
                        VirtualInputManager:SetMouseButtonDown(0)
                    end)
                    holdConnection = true
                end
            else
                -- Click mode: click and release
                doClick()
            end
        end
    end)
    
    print("[Leon X] AutoClicker: Enabled (" .. self.CPS .. " CPS, " .. self.ClickType .. " mode)")
end

function AutoClicker:Disable()
    self.Enabled = false
    
    -- Release held mouse button
    if holdConnection then
        pcall(function()
            VirtualInputManager:SetMouseButtonUp(0)
        end)
        holdConnection = nil
    end
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    print("[Leon X] AutoClicker: Disabled")
end

function AutoClicker:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

-- Setters
function AutoClicker:SetCPS(cps)
    self.CPS = math.max(1, math.min(100, tonumber(cps) or 10))
end

function AutoClicker:SetClickType(clickType)
    if clickType == "mouse" or clickType == "tool" then
        self.ClickType = clickType
    end
end

function AutoClicker:SetHoldDown(hold)
    -- Check condition BEFORE assignment
    if hold and not self.HoldDown then
        self.HoldDown = hold
        if holdConnection then
            pcall(function() VirtualInputManager:SetMouseButtonUp(0) end)
            holdConnection = nil
        end
    else
        self.HoldDown = hold
    end
end

function AutoClicker:SetRandomDelay(enabled)
    self.RandomDelay = enabled
end

return AutoClicker
