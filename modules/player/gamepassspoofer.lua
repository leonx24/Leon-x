-- Leon X | GamepassSpoofer
-- Hooks MarketplaceService to spoof gamepass/asset ownership and inject custom purchase elements
-- Works on games with weak security/client-side checks

local GamepassSpoofer = {}
GamepassSpoofer.Name    = "GamepassSpoofer"
GamepassSpoofer.Enabled = false

-- Sub-settings owned by this module (synchronized with main UI settings/config)
GamepassSpoofer.InstantPurchase = false
GamepassSpoofer.InjectButtons   = false
GamepassSpoofer.AutoInterval    = 0.3
GamepassSpoofer.AutoMassPurchaseActive = false

local CoreGui            = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local Players            = game:GetService("Players")
local GuiService         = game:GetService("GuiService")
local UIS                = game:GetService("UserInputService")
local HttpService        = game:GetService("HttpService")

local lp = Players.LocalPlayer
while not lp do
    task.wait()
    lp = Players.LocalPlayer
end

local originalOwnsGP    = nil
local originalOwnsAsset = nil
local originalPromptGP  = nil
local hookSupported     = true

local COLORS = {
    IDLE = Color3.fromRGB(34, 214, 78),
    HOVER = Color3.fromRGB(42, 232, 90),
}
local COPY_COLORS = {
    IDLE = Color3.fromRGB(255, 154, 46),
    HOVER = Color3.fromRGB(255, 176, 84),
}
local AUTO_COLORS = {
    IDLE = Color3.fromRGB(210, 72, 72),
    HOVER = Color3.fromRGB(232, 98, 98),
}
local TWEEN_SPEED = TweenInfo.new(0.045, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SECONDARY_BUTTON_DELAY = 0.03
local NEW_OVERLAY_BUTTON_INJECT_DELAY = 0
local INSTANT_STATE_WATCH_INTERVAL = 0.03
local OVERLAY_RESCAN_INTERVAL = 0.03

local LastPrompt = { Id = nil, Type = nil, Nonce = 0 }
local LastInstant = { PromptNonce = -1 }

local AutoLoopState = { Running = false, ThreadId = 0, StopGui = nil }
local ParentButtonState = setmetatable({}, { __mode = "k" })
local Connections = {}
local HiddenOverlays = setmetatable({}, { __mode = "k" })
local ProcessedOverlays = setmetatable({}, { __mode = "k" })

-- Check if executor supports required functions
local function checkExecutorSupport()
    if not hookfunction then
        warn("[Leon X] GamepassSpoofer: hookfunction not available")
        return false
    end
    if not newcclosure then
        warn("[Leon X] GamepassSpoofer: newcclosure not available")
        return false
    end
    return true
end

local function trackConnection(conn)
    if conn then
        table.insert(Connections, conn)
    end
    return conn
end

local function toggleRobloxMenu()
    pcall(function()
        local foundOverlay = false
        for _, child in ipairs(CoreGui:GetChildren()) do
            if child:IsA("ScreenGui") and child.Name == "FoundationOverlay" and child.Enabled then
                local saf = child:FindFirstChild("SafeAreaFrame")
                local portal = saf and saf:FindFirstChild("OverlayPortal")
                local backdrop = portal and portal:FindFirstChild("Backdrop")
                local sheet = portal and portal:FindFirstChild("SheetContainer")

                if backdrop and sheet then
                    foundOverlay = true
                    local info = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
                    TweenService:Create(backdrop, info, {BackgroundTransparency = 1}):Play()
                    local t = TweenService:Create(sheet, info, {Position = UDim2.new(0.5, 0, 0.5, 32)})
                    t:Play()
                    t.Completed:Connect(function()
                        GuiService:SetMenuIsOpen(true)
                        GuiService:SetMenuIsOpen(false)
                    end)
                    break
                end
            end
        end

        if not foundOverlay then
            GuiService:SetMenuIsOpen(true)
            GuiService:SetMenuIsOpen(false)
        end
    end)
end

local function trySet(obj, prop, value)
    pcall(function()
        obj[prop] = value
    end)
end

local function tweenColor(target, color)
    if not target or not target.Parent then return end

    local props = {}
    if target:IsA("GuiObject") then
        props.BackgroundColor3 = color
    end
    if target:IsA("ImageButton") or target:IsA("ImageLabel") then
        props.ImageColor3 = color
    end
    if next(props) then
        TweenService:Create(target, TWEEN_SPEED, props):Play()
    end
end

local function applyVisualState(root, color)
    tweenColor(root, color)
    for _, desc in ipairs(root:GetDescendants()) do
        if desc:IsA("ImageLabel") or desc:IsA("ImageButton") or desc:IsA("Frame") then
            tweenColor(desc, color)
        end
    end
end

local function fireEventFallback(event, ...)
    if type(firesignal) == "function" then
        pcall(firesignal, event, ...)
    end
end

local function finishPurchase(id)
    if LastPrompt.Type == "GamePass" then
        local success = pcall(function()
            MarketplaceService:SignalPromptGamePassPurchaseFinished(lp.UserId, id, true)
        end)
        if not success then
            fireEventFallback(MarketplaceService.PromptGamePassPurchaseFinished, lp, id, true)
        end
    elseif LastPrompt.Type == "Product" then
        local success = pcall(function()
            MarketplaceService:SignalPromptProductPurchaseFinished(lp.UserId, id, true)
        end)
        if not success then
            fireEventFallback(MarketplaceService.PromptProductPurchaseFinished, lp.UserId, id, true)
        end
    elseif LastPrompt.Type == "Asset" then
        local success = pcall(function()
            MarketplaceService:SignalPromptPurchaseFinished(lp.UserId, id, true)
        end)
        if not success then
            fireEventFallback(MarketplaceService.PromptPurchaseFinished, lp, id, true)
        end
    elseif LastPrompt.Type == "Bundle" then
        local success = pcall(function()
            MarketplaceService:SignalPromptBundlePurchaseFinished(lp.UserId, id, true)
        end)
        if not success then
            fireEventFallback(MarketplaceService.PromptBundlePurchaseFinished, lp, id, true)
        end
    elseif LastPrompt.Type == "Premium" then
        local success = pcall(function()
            MarketplaceService:SignalPromptPremiumPurchaseFinished(true)
        end)
        if not success then
            fireEventFallback(MarketplaceService.PromptPremiumPurchaseFinished, true)
        end
    end
end

local function restoreHiddenOverlays()
    for overlay in pairs(HiddenOverlays) do
        pcall(function()
            if overlay and overlay.Parent and overlay:IsA("ScreenGui") then
                overlay.Enabled = true
            end
        end)
        HiddenOverlays[overlay] = nil
    end
end

local function restoreFoundationOverlayVisibility()
    for _, child in ipairs(CoreGui:GetDescendants()) do
        if child:IsA("ScreenGui") and child.Name == "FoundationOverlay" then
            pcall(function()
                child.Enabled = true
            end)
        end
    end
end

local function runInstantPurchase(id, options)
    if not GamepassSpoofer.Enabled or not GamepassSpoofer.InstantPurchase then return end

    local opts = options or {}
    if opts.hideOverlay and opts.overlay then
        pcall(function()
            if opts.overlay:IsA("ScreenGui") then
                opts.overlay.Enabled = false
                HiddenOverlays[opts.overlay] = true
            end
        end)
    end

    if opts.forceMenuToggle then
        toggleRobloxMenu()
    end

    if not id then return end
    if id ~= LastPrompt.Id then return end
    local promptNonce = LastPrompt.Nonce or 0
    if LastInstant.PromptNonce == promptNonce then
        return
    end
    LastInstant.PromptNonce = promptNonce

    finishPurchase(id)
end

local function capturePrompt(player, id, promptType)
    if not GamepassSpoofer.Enabled then return end
    if player == lp then
        LastPrompt.Nonce = (LastPrompt.Nonce or 0) + 1
        LastPrompt.Id = id
        LastPrompt.Type = promptType

        if GamepassSpoofer.InstantPurchase then
            task.spawn(function()
                runInstantPurchase(id, { forceMenuToggle = false })
            end)
        end
    end
end

local function buildPurchaseOperation(id)
    local code = "local MarketplaceService = game:GetService(\"MarketplaceService\")\n\n"

    if LastPrompt.Type == "GamePass" then
        return code .. string.format("MarketplaceService:SignalPromptGamePassPurchaseFinished(%d, %d, true)", lp.UserId, id)
    elseif LastPrompt.Type == "Product" then
        return code .. string.format("MarketplaceService:SignalPromptProductPurchaseFinished(%d, %d, true)", lp.UserId, id)
    elseif LastPrompt.Type == "Asset" then
        return code .. string.format("MarketplaceService:SignalPromptPurchaseFinished(%d, %d, true)", lp.UserId, id)
    elseif LastPrompt.Type == "Bundle" then
        return code .. string.format("MarketplaceService:SignalPromptBundlePurchaseFinished(%d, %d, true)", lp.UserId, id)
    elseif LastPrompt.Type == "Premium" then
        return code .. "MarketplaceService:SignalPromptPremiumPurchaseFinished(true)"
    end
    return ""
end

local function settleButtonPosition(anchorBtn, btn, parent, offsetY)
    if not anchorBtn or not btn or not parent then return end
    local hasListLayout = parent:FindFirstChildOfClass("UIListLayout") ~= nil
    if hasListLayout then
        btn.LayoutOrder = (anchorBtn.LayoutOrder or 0) + 1
        return
    end

    btn.Position = anchorBtn.Position + UDim2.fromOffset(0, offsetY or 0)
    task.defer(function()
        if btn.Parent ~= parent or anchorBtn.Parent ~= parent then return end
        btn.Position = anchorBtn.Position + UDim2.fromOffset(0, offsetY or 0)
        task.defer(function()
            if btn.Parent ~= parent or anchorBtn.Parent ~= parent then return end
            btn.Position = anchorBtn.Position + UDim2.fromOffset(0, offsetY or 0)
        end)
    end)
end

local function settleFreeButtonPosition(originalBtn, freeBtn, parent)
    if not originalBtn or not freeBtn or not parent then return end
    local hasListLayout = parent:FindFirstChildOfClass("UIListLayout") ~= nil
    if hasListLayout then
        freeBtn.LayoutOrder = (originalBtn.LayoutOrder or 0) + 1
        return
    end

    freeBtn.Position = originalBtn.Position
    task.defer(function()
        if freeBtn.Parent ~= parent or originalBtn.Parent ~= parent then return end
        freeBtn.Position = originalBtn.Position
        task.defer(function()
            if freeBtn.Parent ~= parent or originalBtn.Parent ~= parent then return end
            freeBtn.Position = originalBtn.Position
        end)
    end)
end

local function getInjectedButtonsBaseOrder(parent)
    local maxOrder = 0
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "FreeButton" and child.Name ~= "CopyButton" and child.Name ~= "AutoButton" then
            local order = child.LayoutOrder or 0
            if order > maxOrder then
                maxOrder = order
            end
        end
    end
    return maxOrder
end

local function getParentState(parent)
    local state = ParentButtonState[parent]
    if not state then
        state = {}
        ParentButtonState[parent] = state
    end
    return state
end

local function layoutInjectedButtons(parent)
    if not parent then return end

    local state = getParentState(parent)
    local template = state.TemplateButton
    if not (template and template.Parent == parent) then
        template = nil
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ImageButton") and child.Name ~= "FreeButton" and child.Name ~= "CopyButton" and child.Name ~= "AutoButton" then
                template = child
                break
            end
        end
        state.TemplateButton = template
    end

    local freeBtn = parent:FindFirstChild("FreeButton")
    local copyBtn = parent:FindFirstChild("CopyButton")
    local autoBtn = parent:FindFirstChild("AutoButton")
    local hasListLayout = parent:FindFirstChildOfClass("UIListLayout") ~= nil

    if hasListLayout then
        local baseOrder = getInjectedButtonsBaseOrder(parent)
        if freeBtn then freeBtn.LayoutOrder = baseOrder + 1 end
        if copyBtn then copyBtn.LayoutOrder = baseOrder + 2 end
        if autoBtn then autoBtn.LayoutOrder = baseOrder + 3 end
        return
    end

    if freeBtn and template then
        settleFreeButtonPosition(template, freeBtn, parent)
    end
    if copyBtn and freeBtn then
        settleButtonPosition(freeBtn, copyBtn, parent, 42)
    end
    if autoBtn then
        local anchorBtn = copyBtn or freeBtn
        if anchorBtn then
            settleButtonPosition(anchorBtn, autoBtn, parent, 42)
        end
    end
end

local function stopAutoLoop()
    AutoLoopState.Running = false
    AutoLoopState.ThreadId = AutoLoopState.ThreadId + 1
end

local function destroyAutoStopButton()
    if AutoLoopState.StopGui and AutoLoopState.StopGui.Parent then
        AutoLoopState.StopGui:Destroy()
    end
    AutoLoopState.StopGui = nil
end

local function startAutoLoop()
    if AutoLoopState.Running then return end
    AutoLoopState.Running = true
    AutoLoopState.ThreadId = AutoLoopState.ThreadId + 1
    local myThreadId = AutoLoopState.ThreadId
    task.spawn(function()
        while AutoLoopState.Running and AutoLoopState.ThreadId == myThreadId and GamepassSpoofer.Enabled do
            local id = LastPrompt.Id
            if id then
                finishPurchase(id)
                toggleRobloxMenu()
            end
            local interval = GamepassSpoofer.AutoInterval
            if type(interval) ~= "number" or interval <= 0 then
                interval = 0.3
            end
            task.wait(interval)
        end
    end)
end

local function makeDraggable(frame)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    local didDrag = false
    local DRAG_THRESHOLD = 6

    local function update(input)
        local delta = input.Position - dragStart
        if math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD then
            didDrag = true
        end
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            didDrag = false
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)

    return function()
        local wasDragged = didDrag
        didDrag = false
        return wasDragged
    end
end

local function createAutoStopButton()
    destroyAutoStopButton()

    local gui = Instance.new("ScreenGui")
    local button = Instance.new("TextButton")
    local corner = Instance.new("UICorner")
    local icon = Instance.new("ImageLabel")
    local aspect = Instance.new("UIAspectRatioConstraint")

    gui.Name = "AutoStopButton"
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    button.Name = "Button"
    button.Parent = gui
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Position = UDim2.new(0.5, 0, 0, 34)
    button.Size = UDim2.new(0.039, 0, 0.069, 0)
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.BackgroundTransparency = 0.4
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.ZIndex = 99999999
    button.Text = ""

    corner.CornerRadius = UDim.new(0, 99999)
    corner.Parent = button

    icon.Parent = button
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(0.1, 0, 0.1, 0)
    icon.Size = UDim2.new(0.8, 0, 0.8, 0)
    icon.Image = "rbxassetid://98003862321782"
    icon.ImageColor3 = Color3.fromRGB(255, 90, 90)

    aspect.Parent = button
    aspect.AspectRatio = 1

    local wasDragged = makeDraggable(button)

    button.Activated:Connect(function()
        if wasDragged() then
            return
        end
        stopAutoLoop()
        destroyAutoStopButton()
    end)

    AutoLoopState.StopGui = gui
end

local function decorateButton(btn, text, zIndex, palette)
    local colors = palette or COLORS
    btn.Visible = true
    btn.Active = true
    btn.Selectable = true
    btn.AutoButtonColor = false
    btn.ZIndex = zIndex
    btn.BackgroundColor3 = colors.IDLE
    btn.BackgroundTransparency = 0.1
    trySet(btn, "Interactable", true)
    if btn:IsA("ImageButton") then
        btn.ImageColor3 = colors.IDLE
    end

    for _, desc in ipairs(btn:GetDescendants()) do
        if desc:IsA("LocalScript") or desc:IsA("Script") or desc:IsA("ModuleScript") then
            desc:Destroy()
        elseif desc:IsA("GuiObject") then
            desc.ZIndex = math.max(desc.ZIndex, btn.ZIndex)
            desc.Active = true
            trySet(desc, "Interactable", true)
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                desc.Text = text
                desc.TextTransparency = 0
            end
        end
    end
end

local function wireHover(btn, palette)
    local colors = palette or COLORS
    btn.MouseEnter:Connect(function()
        applyVisualState(btn, colors.HOVER)
    end)

    btn.MouseLeave:Connect(function()
        applyVisualState(btn, colors.IDLE)
    end)
end

local function processParentButtons(parent)
    if not parent or not GamepassSpoofer.Enabled then return end
    local state = getParentState(parent)
    if state.Injecting then
        state.Dirty = true
        return
    end
    state.Injecting = true

    task.spawn(function()
        repeat
            state.Dirty = false
            local template = state.TemplateButton
            if not (template and template.Parent == parent) then
                state.Injecting = false
                return
            end

            if not parent:FindFirstChild("FreeButton") then
                local freeBtn = template:Clone()
                freeBtn.Name = "FreeButton"
                freeBtn.Parent = parent
                decorateButton(freeBtn, "Free", (template.ZIndex or 1) + 10)
                settleFreeButtonPosition(template, freeBtn, parent)
                wireHover(freeBtn, COLORS)
                freeBtn.Activated:Connect(function()
                    local id = LastPrompt.Id
                    if not id then return end
                    applyVisualState(freeBtn, COLORS.HOVER)
                    finishPurchase(id)
                    applyVisualState(freeBtn, COLORS.IDLE)
                    toggleRobloxMenu()
                end)
            end

            task.defer(function()
                task.wait(SECONDARY_BUTTON_DELAY)
                if not GamepassSpoofer.Enabled then return end
                if parent:FindFirstChild("CopyButton") then return end
                local templateBtn = state.TemplateButton
                if not (templateBtn and templateBtn.Parent == parent) then return end
                local copyBtn = templateBtn:Clone()
                copyBtn.Name = "CopyButton"
                copyBtn.Parent = parent
                local freeBtn = parent:FindFirstChild("FreeButton")
                decorateButton(copyBtn, "Copy", freeBtn and freeBtn.ZIndex or ((templateBtn.ZIndex or 1) + 10), COPY_COLORS)
                wireHover(copyBtn, COPY_COLORS)
                settleButtonPosition(freeBtn, copyBtn, parent, 42)
                copyBtn.Activated:Connect(function()
                    local id = LastPrompt.Id
                    if not id then return end
                    local operationText = buildPurchaseOperation(id)
                    local copied = pcall(function() setclipboard(operationText) end)
                    if copied then
                        applyVisualState(copyBtn, COPY_COLORS.HOVER)
                        task.wait(0.05)
                    end
                    applyVisualState(copyBtn, COPY_COLORS.IDLE)
                end)
            end)

            task.defer(function()
                task.wait(SECONDARY_BUTTON_DELAY)
                if not GamepassSpoofer.Enabled then
                    stopAutoLoop()
                    destroyAutoStopButton()
                    return
                end
                if parent:FindFirstChild("AutoButton") then return end
                local templateBtn = state.TemplateButton
                if not (templateBtn and templateBtn.Parent == parent) then return end
                local autoBtn = templateBtn:Clone()
                autoBtn.Name = "AutoButton"
                autoBtn.Parent = parent
                local anchorBtn = parent:FindFirstChild("CopyButton") or parent:FindFirstChild("FreeButton")
                decorateButton(autoBtn, "Auto", (anchorBtn and anchorBtn.ZIndex) or ((templateBtn.ZIndex or 1) + 10), AUTO_COLORS)
                wireHover(autoBtn, AUTO_COLORS)
                settleButtonPosition(anchorBtn, autoBtn, parent, 42)
                autoBtn.Activated:Connect(function()
                    toggleRobloxMenu()
                    if AutoLoopState.Running then
                        stopAutoLoop()
                        destroyAutoStopButton()
                        return
                    end
                    startAutoLoop()
                    createAutoStopButton()
                    applyVisualState(autoBtn, AUTO_COLORS.HOVER)
                end)
            end)

            task.wait()
            layoutInjectedButtons(parent)
        until not state.Dirty

        state.Injecting = false
    end)
end

local function findTemplateButton(root)
    for _, desc in ipairs(root:GetDescendants()) do
        if (desc:IsA("ImageButton") or desc:IsA("TextButton")) 
            and desc.Visible 
            and desc.Name ~= "FreeButton" 
            and desc.Name ~= "CopyButton" 
            and desc.Name ~= "AutoButton" then
            
            local name = desc.Name:lower()
            local path = desc:GetFullName():lower()
            
            -- Exclude close buttons, back buttons, and other utility buttons
            if not name:find("close") and not name:find("back") and not name:find("dismiss")
               and not path:find("close") and not path:find("back") and not path:find("dismiss") then
                return desc
            end
        end
    end
    return nil
end

local function injectButtons(originalBtn)
    if not GamepassSpoofer.Enabled or not GamepassSpoofer.InjectButtons then return end
    if not originalBtn or originalBtn.Name == "FreeButton" or originalBtn.Name == "CopyButton" or originalBtn.Name == "AutoButton" then
        return
    end
    local parent = originalBtn.Parent
    if not parent then return end
    local state = getParentState(parent)
    if not (state.TemplateButton and state.TemplateButton.Parent == parent) then
        state.TemplateButton = originalBtn
    end
    processParentButtons(parent)
end

local function scanAndInject(overlay)
    if not GamepassSpoofer.Enabled or not GamepassSpoofer.InjectButtons then return end
    if GamepassSpoofer.InstantPurchase then return end

    local template = findTemplateButton(overlay)
    if template then
        injectButtons(template)
    end
end

local function scanAllFoundationOverlays()
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child:IsA("ScreenGui") and child.Name == "FoundationOverlay" then
            scanAndInject(child)
        end
    end
end

local handleOverlay
local function startInstantStateWatcher()
    task.spawn(function()
        local wasEnabled = GamepassSpoofer.InstantPurchase
        if not wasEnabled and GamepassSpoofer.Enabled then
            restoreHiddenOverlays()
            restoreFoundationOverlayVisibility()
            scanAllFoundationOverlays()
        end
        while GamepassSpoofer.Enabled do
            local isEnabled = GamepassSpoofer.InstantPurchase
            if isEnabled ~= wasEnabled then
                if not isEnabled then
                    LastInstant.PromptNonce = -1
                    restoreHiddenOverlays()
                    restoreFoundationOverlayVisibility()
                    scanAllFoundationOverlays()
                end
                for _, child in ipairs(CoreGui:GetDescendants()) do
                    if child:IsA("ScreenGui") and child.Name == "FoundationOverlay" then
                        task.spawn(handleOverlay, child, true)
                    end
                end
                wasEnabled = isEnabled
            end
            task.wait(INSTANT_STATE_WATCH_INTERVAL)
        end
    end)
end

local function startOverlayRescanLoop()
    task.spawn(function()
        while GamepassSpoofer.Enabled do
            if not GamepassSpoofer.InstantPurchase and GamepassSpoofer.InjectButtons then
                scanAllFoundationOverlays()
            end
            task.wait(OVERLAY_RESCAN_INTERVAL)
        end
    end)
end

handleOverlay = function(child, force)
    if not GamepassSpoofer.Enabled or child.Name ~= "FoundationOverlay" then return end
    local modeKey = GamepassSpoofer.InstantPurchase and "instant" or "buttons"
    if not force and ProcessedOverlays[child] == modeKey then return end
    ProcessedOverlays[child] = modeKey

    if GamepassSpoofer.InstantPurchase then
        local function executeInstant()
            local id = LastPrompt.Id
            runInstantPurchase(id, { hideOverlay = true, overlay = child, forceMenuToggle = true })
        end

        task.spawn(function()
            local function check()
                if not (child and child.Parent and GamepassSpoofer.InstantPurchase and GamepassSpoofer.Enabled) then return true end
                local safeArea = child:FindFirstChild("SafeAreaFrame")
                local portal = safeArea and safeArea:FindFirstChild("OverlayPortal")
                if portal then
                    executeInstant()
                    return true
                end
                return false
            end

            if not check() then
                local conn
                conn = trackConnection(child.DescendantAdded:Connect(function()
                    if check() then
                        if conn then conn:Disconnect() end
                    end
                end))
            end
        end)
        return
    end

    local function scanAndInjectWithDelay()
        if not (child and child.Parent and GamepassSpoofer.Enabled and not GamepassSpoofer.InstantPurchase) then return false end
        if not force then
            task.wait(NEW_OVERLAY_BUTTON_INJECT_DELAY)
        end
        if not (child and child.Parent and GamepassSpoofer.Enabled and not GamepassSpoofer.InstantPurchase) then return false end
        
        local template = findTemplateButton(child)
        if not template then return false end
        injectButtons(template)
        return true
    end

    if scanAndInjectWithDelay() then
        return
    end

    local conn
    conn = trackConnection(child.DescendantAdded:Connect(function()
        if scanAndInjectWithDelay() then
            if conn then conn:Disconnect() end
        end
    end))
    task.delay(10, function()
        if conn then conn:Disconnect() end
    end)
end

-- Hook installation and removal helpers
local function setupHooks()
    if not checkExecutorSupport() then
        hookSupported = false
        print("[Leon X] GamepassSpoofer: Executor doesn't support required hooks")
        return
    end

    -- Hook UserOwnsGamePassAsync — always return true
    pcall(function()
        originalOwnsGP = hookfunction(
            MarketplaceService.UserOwnsGamePassAsync,
            newcclosure(function(self, userId, gamePassId)
                -- Only spoof for local player
                if userId == lp.UserId then
                    return true
                end
                -- Pass through for other players
                return originalOwnsGP(self, userId, gamePassId)
            end)
        )
    end)

    -- Hook PlayerOwnsAsset — always return true for local player
    pcall(function()
        originalOwnsAsset = hookfunction(
            MarketplaceService.PlayerOwnsAsset,
            newcclosure(function(self, player, assetId)
                if player == lp then
                    return true
                end
                return originalOwnsAsset(self, player, assetId)
            end)
        )
    end)

    -- Hook PromptGamePassPurchase to silently ignore purchase prompts if instant purchase is enabled,
    -- or let it through if we want to show custom overlay button injector
    pcall(function()
        originalPromptGP = hookfunction(
            MarketplaceService.PromptGamePassPurchase,
            newcclosure(function(self, player, gamePassId)
                if player == lp and GamepassSpoofer.InstantPurchase then
                    return  -- silently ignore since we fulfill instantly
                end
                return originalPromptGP(self, player, gamePassId)
            end)
        )
    end)
end

local function removeHooks()
    pcall(function()
        if originalOwnsGP then
            hookfunction(MarketplaceService.UserOwnsGamePassAsync, originalOwnsGP)
            originalOwnsGP = nil
        end
    end)

    pcall(function()
        if originalOwnsAsset then
            hookfunction(MarketplaceService.PlayerOwnsAsset, originalOwnsAsset)
            originalOwnsAsset = nil
        end
    end)

    pcall(function()
        if originalPromptGP then
            hookfunction(MarketplaceService.PromptGamePassPurchase, originalPromptGP)
            originalPromptGP = nil
        end
    end)
end

function GamepassSpoofer:Enable()
    if self.Enabled then return end
    self.Enabled = true

    setupHooks()

    -- Wire Marketplace Purchase Request events
    trackConnection(MarketplaceService.PromptGamePassPurchaseRequested:Connect(function(player, id)
        capturePrompt(player, id, "GamePass")
    end))

    trackConnection(MarketplaceService.PromptProductPurchaseRequested:Connect(function(player, id)
        capturePrompt(player, id, "Product")
    end))

    trackConnection(MarketplaceService.PromptPurchaseRequested:Connect(function(player, id)
        capturePrompt(player, id, "Asset")
    end))

    trackConnection(MarketplaceService.PromptBundlePurchaseRequested:Connect(function(player, id)
        capturePrompt(player, id, "Bundle")
    end))

    trackConnection(MarketplaceService.PromptPremiumPurchaseRequested:Connect(function(player)
        capturePrompt(player, 0, "Premium")
    end))

    -- CoreGui Overlay observers
    trackConnection(CoreGui.DescendantAdded:Connect(handleOverlay))
    for _, child in ipairs(CoreGui:GetDescendants()) do
        task.spawn(handleOverlay, child)
    end

    startInstantStateWatcher()
    startOverlayRescanLoop()

    print("[Leon X] GamepassSpoofer: Enabled — advanced spoofing & injection active")
end

function GamepassSpoofer:Disable()
    if not self.Enabled then return end
    self.Enabled = false

    -- Stop auto loops & stop buttons
    stopAutoLoop()
    destroyAutoStopButton()

    -- Disconnect all events
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    -- Restore core GUI overlays visibility and remove injected buttons
    restoreHiddenOverlays()
    restoreFoundationOverlayVisibility()

    -- Find and destroy custom injected buttons
    for _, child in ipairs(CoreGui:GetDescendants()) do
        if child:IsA("GuiObject") and (child.Name == "FreeButton" or child.Name == "CopyButton" or child.Name == "AutoButton") then
            pcall(function() child:Destroy() end)
        end
    end

    -- Clear state caches
    table.clear(ProcessedOverlays)
    table.clear(ParentButtonState)

    -- Remove hooked functions
    removeHooks()

    print("[Leon X] GamepassSpoofer: Disabled — restored original environment")
end

function GamepassSpoofer:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

function GamepassSpoofer:IsSupported()
    return hookSupported
end

-- Perform safe Auto Mass Purchase without infinite loop on error/rate limit
function GamepassSpoofer:PerformAutoMassPurchase(notifyCallback)
    if self.AutoMassPurchaseActive then return end
    self.AutoMassPurchaseActive = true

    task.spawn(function()
        local function status(msg)
            if notifyCallback then
                pcall(notifyCallback, "Mass Purchase", msg)
            end
        end

        status("Starting developer products scan...")
        local success, productsPage = pcall(function()
            return MarketplaceService:GetDeveloperProductsAsync()
        end)

        if success and productsPage then
            while true do
                local products = productsPage:GetCurrentPage()
                for _, info in ipairs(products) do
                    if not self.Enabled or not self.AutoMassPurchaseActive then break end
                    local id = info.ProductId
                    
                    local successSig = pcall(function()
                        MarketplaceService:SignalPromptProductPurchaseFinished(lp.UserId, id, true)
                    end)
                    if not successSig then
                        fireEventFallback(MarketplaceService.PromptProductPurchaseFinished, lp.UserId, id, true)
                    end
                    task.wait(0.1)
                end
                
                if productsPage.IsFinished or not self.Enabled or not self.AutoMassPurchaseActive then
                    break
                end

                -- BUG FIX: If next page advancement fails, break the loop to avoid infinite loop
                local advanceSuccess = pcall(function() productsPage:AdvanceToNextPageAsync() end)
                if not advanceSuccess then
                    warn("[Leon X] GamepassSpoofer: AdvanceToNextPageAsync failed. Stopping.")
                    break
                end
            end
        end

        status("Scanning gamepasses...")
        local universeId = game.GameId
        if universeId == 0 then
            pcall(function()
                local res = game:HttpGet("https://apis.roblox.com/universes/v1/places/" .. tostring(game.PlaceId) .. "/universe")
                local data = HttpService:JSONDecode(res)
                if data and data.universeId then
                    universeId = data.universeId
                end
            end)
        end

        if universeId and universeId > 0 and self.Enabled and self.AutoMassPurchaseActive then
            pcall(function()
                local cursor = ""
                while cursor and self.Enabled and self.AutoMassPurchaseActive do
                    local url = "https://games.roblox.com/v1/games/" .. tostring(universeId) .. "/game-passes?limit=100"
                    if cursor ~= "" then
                        url = url .. "&cursor=" .. cursor
                    end
                    local res = game:HttpGet(url)
                    local data = HttpService:JSONDecode(res)
                    if data and data.data then
                        for _, gp in ipairs(data.data) do
                            if not self.Enabled or not self.AutoMassPurchaseActive then break end
                            local id = gp.id
                            
                            local successSig = pcall(function()
                                MarketplaceService:SignalPromptGamePassPurchaseFinished(lp.UserId, id, true)
                            end)
                            if not successSig then
                                fireEventFallback(MarketplaceService.PromptGamePassPurchaseFinished, lp, id, true)
                            end
                            task.wait(0.1)
                        end
                        cursor = data.nextPageCursor
                    else
                        cursor = nil
                    end
                end
            end)
        end

        self.AutoMassPurchaseActive = false
        status("Finished purchase emulation!")
    end)
end

return GamepassSpoofer
