-- Leon X | Quick Switch Macro
-- Automatically performs a fast double-switch ("qq") when shooting (left-clicking)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer

local QuickSwitch = {}
QuickSwitch.Name = "QuickSwitch"
QuickSwitch.Enabled = false
QuickSwitch.DelayAfterShot = 0.05 -- seconds to wait after shot before switching (converted from ms in UI)
QuickSwitch.DelayBetweenSwitches = 0.05 -- seconds to wait between switching to knife and back (converted from ms in UI)
QuickSwitch.SwitchType = "Q-Q" -- "Q-Q", "3-1", or "Custom"
QuickSwitch.FirstKey = "Q"
QuickSwitch.SecondKey = "Q"

local inputConnection = nil
local isRunning = false

local function pressKey(keyName)
    local keyCode = Enum.KeyCode[keyName]
    if not keyCode then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

local function runMacro()
    if isRunning then return end
    isRunning = true
    
    task.wait(QuickSwitch.DelayAfterShot)
    
    if QuickSwitch.SwitchType == "Q-Q" then
        pressKey("Q")
        task.wait(QuickSwitch.DelayBetweenSwitches)
        pressKey("Q")
    elseif QuickSwitch.SwitchType == "3-1" then
        pressKey("Three")
        task.wait(QuickSwitch.DelayBetweenSwitches)
        pressKey("One")
    else
        -- Custom keys
        pressKey(QuickSwitch.FirstKey)
        task.wait(QuickSwitch.DelayBetweenSwitches)
        pressKey(QuickSwitch.SecondKey)
    end
    
    isRunning = false
end

function QuickSwitch:Enable()
    if self.Enabled then return end
    self.Enabled = true
    
    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end
    
    inputConnection = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if not self.Enabled then return end
        if UserInputService:GetFocusedTextBox() then return end
        
        -- Detect left click / shooting
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            task.spawn(runMacro)
        end
    end)
end

function QuickSwitch:Disable()
    self.Enabled = false
    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end
end

function QuickSwitch:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function QuickSwitch:SetDelayAfterShot(v)
    -- Input is in milliseconds, convert to seconds
    self.DelayAfterShot = (tonumber(v) or 50) / 1000
end

function QuickSwitch:SetDelayBetweenSwitches(v)
    -- Input is in milliseconds, convert to seconds
    self.DelayBetweenSwitches = (tonumber(v) or 50) / 1000
end

function QuickSwitch:SetSwitchType(v)
    if v == "Q-Q" or v == "3-1" or v == "Custom" then
        self.SwitchType = v
    end
end

function QuickSwitch:SetFirstKey(v)
    self.FirstKey = tostring(v)
end

function QuickSwitch:SetSecondKey(v)
    self.SecondKey = tostring(v)
end

return QuickSwitch
