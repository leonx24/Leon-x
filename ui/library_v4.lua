-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Leon X  |  Prism UI Library v5                                  ║
-- ║  "Light bends through obsidian."                                 ║
-- ║                                                                  ║
-- ║  LAYOUT: Horizontal top tabs, full-width card grid,              ║
-- ║  floating glassmorphism panels, no sidebar.                      ║
-- ╚══════════════════════════════════════════════════════════════════╝

print("[LeonX-LIB] PRISM-UI-V5")

local Library = {}
Library.Registry = {}
Library._allComponents = {}
Library._windows = {}
Library._icons = nil

-- ════════════════════════════════════════════════════════════════════════════
-- ICON SYSTEM
-- ════════════════════════════════════════════════════════════════════════════
local ICON_URL = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"

local function loadIcons()
	if Library._icons then return Library._icons end
	local ok, result = pcall(function()
		local src = game:HttpGet(ICON_URL .. "?t=" .. tostring(os.time()), true)
		if not src or #src < 10 then error("empty") end
		local fn, e = loadstring(src)
		if not fn then error(e) end
		return fn()
	end)
	Library._icons = ok and type(result) == "table" and result or {}
	return Library._icons
end

local function getIcon(name)
	if not name or name == "" then return nil end
	if not Library._icons then loadIcons() end
	return Library._icons[name]
end

local function mkIcon(parent, name, size, color, zindex)
	local assetId = getIcon(name)
	if not assetId then return nil end
	size = size or 18; color = color or Color3.fromRGB(255,255,255); zindex = zindex or 1
	local img = Instance.new("ImageLabel")
	img.Name = "Ico"; img.Size = UDim2.fromOffset(size, size)
	img.BackgroundTransparency = 1; img.BorderSizePixel = 0
	img.Image = assetId; img.ImageColor3 = color
	img.ScaleType = Enum.ScaleType.Fit; img.ZIndex = zindex
	img.Parent = parent
	return img
end

-- ════════════════════════════════════════════════════════════════════════════
-- THEMES
-- ════════════════════════════════════════════════════════════════════════════
local function mkTheme(accent, accentDim, glowTint)
	return {
		BG        = Color3.fromRGB(6, 6, 10),
		Surface   = Color3.fromRGB(12, 12, 18),
		Elevated  = Color3.fromRGB(20, 20, 28),
		Card      = Color3.fromRGB(16, 16, 24),
		Border    = Color3.fromRGB(30, 30, 40),
		BorderSub = Color3.fromRGB(22, 22, 30),
		Text      = Color3.fromRGB(228, 228, 236),
		TextSub   = Color3.fromRGB(100, 100, 118),
		TextDim   = Color3.fromRGB(55, 55, 68),
		Accent    = Color3.fromRGB(table.unpack(accent)),
		AccentDim = Color3.fromRGB(table.unpack(accentDim)),
		Glow      = Color3.fromRGB(table.unpack(glowTint or accent)),
	}
end

Library.Themes = {
	Default = mkTheme({100,130,230}, {55,80,170}, {80,110,210}),
	Gold    = mkTheme({225,195,90},  {170,140,55}, {215,180,70}),
	Emerald = mkTheme({75,210,125},  {40,150,80},  {60,195,105}),
	Rose    = mkTheme({225,100,130}, {170,60,88},  {210,85,115}),
	Violet  = mkTheme({145,105,235}, {95,65,175},  {130,90,220}),
	Amber   = mkTheme({235,185,55},  {180,135,35}, {220,170,45}),
	Neon    = mkTheme({60,235,175},  {30,180,125}, {50,220,160}),
}

-- ════════════════════════════════════════════════════════════════════════════
-- CORE UTILITIES
-- ════════════════════════════════════════════════════════════════════════════
local TS      = game:GetService("TweenService")
local UIS     = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lp      = Players.LocalPlayer
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function mk(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	return inst
end

local function tw(obj, dur, props, style, dir)
	local info = TweenInfo.new(dur, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	local t = TS:Create(obj, info, props)
	t:Play(); return t
end

-- ── Theme tagging ──
local ROLE_COLORS = {
	bg = "BG", surface = "Surface", elevated = "Elevated", card = "Card",
	border = "Border", bordersub = "BorderSub",
	text = "Text", textsub = "TextSub", textdim = "TextDim",
	accent = "Accent", accentdim = "AccentDim", glow = "Glow",
}

local function tagText(inst, role)
	inst:SetAttribute("_role", role or "text")
	inst:SetAttribute("_isText", true)
	return inst
end
local function tagBorder(inst, role)
	inst:SetAttribute("_role", role or "border")
	inst:SetAttribute("_isStroke", true)
	return inst
end
local function tagBg(inst, role)
	inst:SetAttribute("_role", role or "bg")
	inst:SetAttribute("_isBg", true)
	return inst
end
local function tagIcon(inst, role)
	inst:SetAttribute("_role", role or "accent")
	inst:SetAttribute("_isIcon", true)
	return inst
end

local function applyTheme(inst, theme)
	local role = inst:GetAttribute("_role")
	if not role then return end
	local color = ROLE_COLORS[role] and theme[ROLE_COLORS[role]]
	if not color then return end
	if inst:GetAttribute("_isText") then inst.TextColor3 = color
	elseif inst:GetAttribute("_isStroke") then inst.Color = color
	elseif inst:GetAttribute("_isIcon") then inst.ImageColor3 = color
	elseif inst:GetAttribute("_isBg") then inst.BackgroundColor3 = color end
end

local function retagAll(frame, theme)
	for _, inst in ipairs(frame:GetDescendants()) do
		if inst:GetAttribute("_role") then applyTheme(inst, theme) end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════
local function getLabel(data)
	return data.Title or data.Name or data.Text or data.Label or ""
end

local function reg(data, api)
	if data and data.Flag then
		Library.Registry[data.Flag] = {
			Get = function() return api:Get() end,
			Set = function(v) api:Set(v) end,
			Callback = data.Callback
		}
	end
	Library._allComponents[#Library._allComponents + 1] = api
end

local function attachTooltip(component, text)
	if not text or text == "" then return end
	local tooltip, tooltipLabel = nil, nil
	local function createTooltip()
		if tooltip then return end
		tooltip = mk("Frame", {
			Name = "Tooltip"; Size = UDim2.fromOffset(220, 34);
			BackgroundColor3 = Color3.fromRGB(14, 14, 20);
			BorderSizePixel = 0; ZIndex = 200; Visible = false;
			Parent = game:GetService("CoreGui");
		})
		mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = tooltip })
		mk("UIStroke", { Color = Color3.fromRGB(35, 35, 45); Thickness = 1; Parent = tooltip })
		tooltipLabel = mk("TextLabel", {
			Size = UDim2.new(1, -14, 1, 0); Position = UDim2.fromOffset(7, 0);
			BackgroundTransparency = 1; Text = text;
			TextColor3 = Color3.fromRGB(190, 190, 200); TextSize = 11;
			Font = Enum.Font.Gotham; TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextWrapped = true; ZIndex = 201; Parent = tooltip;
		})
	end
	local frame = component.Frame
	if not frame then return end
	frame.MouseEnter:Connect(function() createTooltip(); if tooltip then tooltip.Visible = true end end)
	frame.MouseMoved:Connect(function(x, y) if tooltip then tooltip.Position = UDim2.fromOffset(x + 12, y + 12) end end)
	frame.MouseLeave:Connect(function() if tooltip then tooltip.Visible = false end end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ════════════════════════════════════════════════════════════════════════════
local notifGui = mk("ScreenGui", {
	Name = "LeonXNotif"; ResetOnSpawn = false;
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	DisplayOrder = 10000; IgnoreGuiInset = true;
})
pcall(function() notifGui.Parent = lp:WaitForChild("PlayerGui") end)
local activeNotifs = {}

-- ════════════════════════════════════════════════════════════════════════════
-- CREATE WINDOW  —  HORIZONTAL TAB LAYOUT (no sidebar!)
-- ════════════════════════════════════════════════════════════════════════════
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title     = cfg.Title or "Leon X"
	local author    = cfg.Author or ""
	local size      = cfg.Size or UDim2.new(0, 660, 0, 580)
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.U
	local themeName = cfg.Theme or "Default"
	local theme     = Library.Themes[themeName] or Library.Themes.Default

	loadIcons()

	local win = {
		_tabs = {}; _active = nil; _visible = true;
		_theme = theme; _toggleKey = toggleKey; _themeName = themeName;
	}
	Library._windows[#Library._windows + 1] = win
	Library._lastTheme = themeName

	-- ── ScreenGui ──
	local sg = mk("ScreenGui", {
		Name = "LeonXNoir"; ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		DisplayOrder = 999; IgnoreGuiInset = true;
		Parent = lp:WaitForChild("PlayerGui");
	})

	-- ── Main Frame ──
	local scale = isMobile and 0.78 or 1.0
	local main = mk("Frame", {
		Size = size;
		Position = UDim2.new(0.5, -(size.X.Offset * scale) / 2, 0.5, -(size.Y.Offset * scale) / 2);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ClipsDescendants = true; Active = false; Parent = sg;
	})
	if isMobile then mk("UIScale", { Scale = scale; Parent = main }) end

	-- ── Background ──
	local bgFrame = tagBg(mk("Frame", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = theme.BG;
		BackgroundTransparency = 0.04; BorderSizePixel = 0;
		ZIndex = 1; Active = false; Parent = main;
	}), "bg")
	mk("UICorner", { CornerRadius = UDim.new(0, 14); Parent = bgFrame })
	tagBorder(mk("UIStroke", { Color = theme.Border; Thickness = 1; Parent = bgFrame }), "border")

	-- ── Ambient glow gradient ──
	local glowOverlay = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 120); BackgroundColor3 = theme.Accent;
		BackgroundTransparency = 0.94; BorderSizePixel = 0;
		ZIndex = 2; Active = false; Parent = main;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 14); Parent = glowOverlay })
	mk("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		}); Rotation = 180; Parent = glowOverlay;
	})

	-- ════════════════════════════════════════════════════════════════════════
	-- HEADER — compact top bar (logo left, title center, buttons right)
	-- ════════════════════════════════════════════════════════════════════════
	local HEADER_H = 46
	local headerBg = mk("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER_H); BackgroundTransparency = 1;
		BorderSizePixel = 0; ZIndex = 10; Active = true; Parent = main;
	})

	-- Logo icon + brand
	local logoIco = mkIcon(headerBg, "zap", 18, theme.Accent, 11)
	if logoIco then
		logoIco.Position = UDim2.new(0, 16, 0.5, -9)
		tagIcon(logoIco, "accent")
	end
	tagText(mk("TextLabel", {
		Size = UDim2.new(0, 80, 0, 20);
		Position = UDim2.new(0, logoIco and 40 or 16, 0.5, -10);
		BackgroundTransparency = 1; Text = "Leon X";
		Font = Enum.Font.GothamBold; TextSize = 16;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 11; Parent = headerBg;
	}), "text")

	-- Title (center)
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -280, 1, 0); AnchorPoint = Vector2.new(0.5, 0);
		Position = UDim2.new(0.5, 0, 0, 0);
		BackgroundTransparency = 1; Text = title;
		Font = Enum.Font.GothamMedium; TextSize = 12;
		TextColor3 = theme.TextSub; ZIndex = 11; Parent = headerBg;
	}), "textsub")

	-- Header action buttons
	local function hdrBtn(xOff, iconName)
		local b = mk("TextButton", {
			Size = UDim2.fromOffset(28, 28);
			Position = UDim2.new(1, xOff, 0.5, -14);
			BackgroundColor3 = theme.Elevated; BackgroundTransparency = 1;
			Text = ""; AutoButtonColor = false; ZIndex = 12; Parent = headerBg;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
		local ico = mkIcon(b, iconName, 14, theme.TextSub, 13)
		if ico then
			ico.AnchorPoint = Vector2.new(0.5, 0.5)
			ico.Position = UDim2.fromScale(0.5, 0.5)
		end
		b.MouseEnter:Connect(function()
			tw(b, 0.12, { BackgroundTransparency = 0 })
			if ico then tw(ico, 0.12, { ImageColor3 = theme.Text }) end
		end)
		b.MouseLeave:Connect(function()
			tw(b, 0.12, { BackgroundTransparency = 1 })
			if ico then tw(ico, 0.12, { ImageColor3 = theme.TextSub }) end
		end)
		return b
	end

	local minBtn = hdrBtn(-64, "minus")
	local closeBtn = hdrBtn(-32, "x")

	-- Header bottom line
	tagBg(mk("Frame", {
		Size = UDim2.new(1, -28, 0, 1); Position = UDim2.new(0, 14, 1, -1);
		BackgroundColor3 = theme.Border; BackgroundTransparency = 0.5;
		BorderSizePixel = 0; ZIndex = 10; Parent = headerBg;
	}), "border")

	-- ════════════════════════════════════════════════════════════════════════
	-- TAB BAR — horizontal scrolling tab strip below header
	-- ════════════════════════════════════════════════════════════════════════
	local TAB_BAR_H = 40
	local tabBar = mk("ScrollingFrame", {
		Size = UDim2.new(1, -24, 0, TAB_BAR_H);
		Position = UDim2.fromOffset(12, HEADER_H);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 0; CanvasSize = UDim2.fromOffset(0, TAB_BAR_H);
		ScrollingDirection = Enum.ScrollingDirection.X;
		ClipsDescendants = true; ZIndex = 10; Parent = main;
	})
	local tabLayout = mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = UDim.new(0, 4); VerticalAlignment = Enum.VerticalAlignment.Center;
		Parent = tabBar;
	})
	mk("UIPadding", {
		PaddingLeft = UDim.new(0, 2); PaddingRight = UDim.new(0, 2);
		PaddingTop = UDim.new(0, 3); PaddingBottom = UDim.new(0, 3);
		Parent = tabBar;
	})

	-- Update tab bar canvas width when tabs added
	tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabBar.CanvasSize = UDim2.fromOffset(tabLayout.AbsoluteContentSize.X + 8, TAB_BAR_H)
	end)

	-- Accent underline that slides under active tab
	local tabIndicator = tagBg(mk("Frame", {
		Size = UDim2.new(0, 0, 0, 2);
		Position = UDim2.new(0, 0, 1, -1);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0;
		ZIndex = 11; Parent = tabBar;
	}), "accent")
	mk("UICorner", { CornerRadius = UDim.new(0, 1); Parent = tabIndicator })

	-- ════════════════════════════════════════════════════════════════════════
	-- CONTENT AREA — full width below tab bar
	-- ════════════════════════════════════════════════════════════════════════
	local CONTENT_Y = HEADER_H + TAB_BAR_H + 2
	local content = mk("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -CONTENT_Y);
		Position = UDim2.fromOffset(0, CONTENT_Y);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 3; ScrollBarImageColor3 = theme.AccentDim;
		CanvasSize = UDim2.fromOffset(0, 0);
		ClipsDescendants = true; ZIndex = 5; Parent = main;
	})
	local contentLayout = mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder; Padding = UDim.new(0, 6); Parent = content;
	})
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 10); PaddingBottom = UDim.new(0, 16);
		PaddingLeft = UDim.new(0, 16); PaddingRight = UDim.new(0, 16);
		Parent = content;
	})
	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		content.CanvasSize = UDim2.fromOffset(0, contentLayout.AbsoluteContentSize.Y + 30)
	end)
	pcall(function() content.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
	win._allComps = {}

	-- ════════════════════════════════════════════════════════════════════════
	-- FLOATING BUTTON
	-- ════════════════════════════════════════════════════════════════════════
	local floatGui = mk("ScreenGui", {
		Name = "LeonXFloat"; ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		DisplayOrder = 998; IgnoreGuiInset = true;
		Parent = lp:WaitForChild("PlayerGui");
	})
	local floatBtn = mk("TextButton", {
		Size = UDim2.fromOffset(48, 48); Position = UDim2.new(0, 12, 0.5, -24);
		BackgroundColor3 = theme.Surface; Text = "";
		AutoButtonColor = false; Visible = false; ZIndex = 10; Parent = floatGui;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1.5 }),
	})
	local floatIco = mkIcon(floatBtn, "menu", 18, theme.Accent, 11)
	if floatIco then
		floatIco.AnchorPoint = Vector2.new(0.5, 0.5)
		floatIco.Position = UDim2.fromScale(0.5, 0.5)
	end
	-- Float drag + click
	do
		local fD, fS, fP, fM = false, nil, nil, false
		local function isTap(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
		floatBtn.InputBegan:Connect(function(i) if isTap(i) then fD = true; fM = false; fS = i.Position; fP = floatBtn.Position end end)
		UIS.InputChanged:Connect(function(i)
			if fD and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - fS
				if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then fM = true end
				floatBtn.Position = UDim2.new(fP.X.Scale, fP.X.Offset + d.X, fP.Y.Scale, fP.Y.Offset + d.Y)
			end
		end)
		UIS.InputEnded:Connect(function(i) if isTap(i) and fD then fD = false; if not fM then win:Open() end end end)
	end

	-- ════════════════════════════════════════════════════════════════════════
	-- CLOSE / OPEN
	-- ════════════════════════════════════════════════════════════════════════
	function win:Close()
		if not win._visible then return end
		win._visible = false
		-- Animate out
		tw(main, 0.25, { Size = UDim2.new(0, size.X.Offset, 0, size.Y.Offset * 0.95) })
		tw(bgFrame, 0.2, { BackgroundTransparency = 1 })
		task.wait(0.25)
		sg.Enabled = false
		main.Size = size
		bgFrame.BackgroundTransparency = 0.04
		if isMobile then
			floatBtn.Visible = true
			floatBtn.Size = UDim2.fromOffset(32, 32)
			TS:Create(floatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(48, 48)
			}):Play()
		end
	end

	function win:Open()
		if win._visible then return end
		floatBtn.Visible = false
		sg.Enabled = true
		win._visible = true
	end

	local minVisible = true
	minBtn.MouseButton1Click:Connect(function()
		minVisible = not minVisible
		if minVisible then win:Open() else win:Close() end
	end)
	closeBtn.MouseButton1Click:Connect(function() win:Close() end)

	-- ── Drag ──
	local dragging, dragStart, startPos
	headerBg.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = i.Position; startPos = main.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	-- ── Resize ──
	local resizing, rStart, rSize = false, nil, nil
	local rHandle = mk("TextButton", {
		Size = UDim2.fromOffset(16, 16); Position = UDim2.new(1, -16, 1, -16);
		BackgroundTransparency = 1; Text = ""; AutoButtonColor = false;
		ZIndex = 10; Parent = bgFrame;
	})
	for i = 0, 2 do
		mk("Frame", {
			Size = UDim2.fromOffset(6, 1.5);
			Position = UDim2.new(1, -2-(i*3), 1, -2-(i*3));
			BackgroundColor3 = theme.TextDim; BackgroundTransparency = 0.5;
			BorderSizePixel = 0; Rotation = 45; AnchorPoint = Vector2.new(1,1);
			ZIndex = 11; Parent = rHandle;
		})
	end
	rHandle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			resizing = true; rStart = i.Position; rSize = main.Size
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then resizing = false end end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - rStart
			local cs = main:FindFirstChild("UIScale") and main.UIScale.Scale or 1.0
			main.Size = UDim2.new(0, math.max(440, rSize.X.Offset + d.X/cs), 0, math.max(340, rSize.Y.Offset + d.Y/cs))
		end
	end)

	-- ════════════════════════════════════════════════════════════════════════
	-- PUBLIC API
	-- ════════════════════════════════════════════════════════════════════════
	function win:SetToggleKey(k) win._toggleKey = k end
	function win:SetTheme(name)
		local t = Library.Themes[name]
		if not t then return end
		win._theme = t; win._themeName = name; Library._lastTheme = name
		retagAll(main, t); retagAll(floatBtn, t)
	end

	UIS.InputBegan:Connect(function(i, gp)
		if gp or i.KeyCode ~= win._toggleKey then return end
		if win._visible then win:Close() else win:Open() end
	end)

	-- ════════════════════════════════════════════════════════════════════════
	-- WELCOME SCREEN
	-- ════════════════════════════════════════════════════════════════════════
	local gameName = cfg.GameName or nil
	local isGameMode = cfg.GameMode or false

	local welcomeFrame = mk("Frame", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = theme.BG;
		BackgroundTransparency = 0; BorderSizePixel = 0;
		ZIndex = 50; Active = false; Parent = main;
	})
	tagBg(welcomeFrame, "bg")

	-- Welcome card — wide horizontal layout
	local welcomeCard = mk("Frame", {
		Size = UDim2.new(0, 480, 0, 380);
		AnchorPoint = Vector2.new(0.5, 0.5);
		Position = UDim2.fromScale(0.5, 0.5);
		BackgroundColor3 = theme.Card; BorderSizePixel = 0;
		ZIndex = 51; Parent = welcomeFrame;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 16) }) })
	tagBg(welcomeCard, "card")

	local cardStroke = tagBorder(mk("UIStroke", { Color = theme.Border; Thickness = 1; ZIndex = 51; Parent = welcomeCard }), "border")
	task.spawn(function()
		while cardStroke and cardStroke.Parent do
			tw(cardStroke, 2, { Color = theme.Accent }, Enum.EasingStyle.Sine); task.wait(2)
			tw(cardStroke, 2, { Color = theme.Border }, Enum.EasingStyle.Sine); task.wait(2)
		end
	end)

	-- Accent orb glow behind logo
	local orbGlow = mk("Frame", {
		Size = UDim2.fromOffset(80, 80); AnchorPoint = Vector2.new(0.5, 0);
		Position = UDim2.new(0.5, 0, 0, 10);
		BackgroundColor3 = theme.Accent; BackgroundTransparency = 0.88;
		BorderSizePixel = 0; ZIndex = 52; Parent = welcomeCard;
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0); Parent = orbGlow })
	tagBg(orbGlow, "accent")

	-- Logo icon
	local wLogo = mkIcon(welcomeCard, "zap", 32, theme.Accent, 54)
	if wLogo then wLogo.AnchorPoint = Vector2.new(0.5, 0); wLogo.Position = UDim2.new(0.5, 0, 0, 34); tagIcon(wLogo, "accent") end

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 28); Position = UDim2.fromOffset(0, 76);
		BackgroundTransparency = 1; Text = "Leon X";
		Font = Enum.Font.GothamBold; TextSize = 24;
		TextColor3 = theme.Text; ZIndex = 53; Parent = welcomeCard;
	}), "text")

	-- Version pill
	local vPill = mk("Frame", {
		Size = UDim2.new(0, 54, 0, 20); Position = UDim2.new(0.5, -27, 0, 108);
		BackgroundColor3 = theme.Accent; BackgroundTransparency = 0.84;
		BorderSizePixel = 0; ZIndex = 53; Parent = welcomeCard;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	tagBg(vPill, "accent")
	tagText(mk("TextLabel", {
		Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1;
		Text = "v5.0"; Font = Enum.Font.GothamBold; TextSize = 9;
		TextColor3 = theme.Text; ZIndex = 54; Parent = vPill;
	}), "text")

	-- Tagline
	local tlText = isGameMode and ("Specialized for " .. gameName) or "Modular framework for any game"
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -60, 0, 18); Position = UDim2.fromOffset(30, 134);
		BackgroundTransparency = 1; Text = tlText;
		Font = Enum.Font.Gotham; TextSize = 11; TextColor3 = theme.TextSub;
		ZIndex = 53; Parent = welcomeCard;
	}), "textsub")

	-- Info rows
	local platformText = isGameMode and ("Game: " .. gameName) or "Universal Mode"
	local infoData = {
		{"shield-check", "Author",   "leonx24"},
		{"layers",       "Mode",     platformText},
		{"package",      "Features", "30+ Modules"},
		{"smartphone",   "Mobile",   "Full touch support"},
		{"save",         "Config",   "Auto-save & load"},
		{"activity",     "Status",   "Active"},
	}
	local infoFrame = mk("Frame", {
		Size = UDim2.new(1, -48, 0, #infoData * 28 + 4);
		Position = UDim2.fromOffset(24, 160);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		ZIndex = 53; Parent = welcomeCard;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	tagBg(infoFrame, "elevated")

	for i, row in ipairs(infoData) do
		local ry = 2 + (i-1) * 28
		local rBg = mk("Frame", {
			Size = UDim2.new(1, -4, 0, 26); Position = UDim2.fromOffset(2, ry);
			BackgroundColor3 = (i % 2 == 0) and theme.Elevated or theme.BG;
			BackgroundTransparency = 0.5; BorderSizePixel = 0;
			ZIndex = 54; Parent = infoFrame;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 5) }) })
		tagBg(rBg, (i % 2 == 0) and "elevated" or "bg")

		-- Row icon
		local rIco = mkIcon(rBg, row[1], 12, theme.AccentDim, 55)
		if rIco then rIco.Position = UDim2.new(0, 10, 0.5, -6) end

		tagText(mk("TextLabel", {
			Size = UDim2.new(0.3, 0, 1, 0); Position = UDim2.fromOffset(rIco and 28 or 10, 0);
			BackgroundTransparency = 1; Text = row[2];
			Font = Enum.Font.GothamBold; TextSize = 10; TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 55; Parent = rBg;
		}), "textsub")

		local vc = (row[2] == "Status") and Color3.fromRGB(65, 220, 105) or theme.Text
		local vl = tagText(mk("TextLabel", {
			Size = UDim2.new(0.5, 0, 1, 0); Position = UDim2.new(0.42, 0, 0, 0);
			BackgroundTransparency = 1; Text = row[3];
			Font = Enum.Font.GothamMedium; TextSize = 11; TextColor3 = vc;
			TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 55; Parent = rBg;
		}), "text")
		if row[2] == "Status" then vl:SetAttribute("_role", nil) end
	end

	-- Enter button
	local enterBtn = mk("TextButton", {
		Size = UDim2.new(1, -48, 0, 40);
		Position = UDim2.fromOffset(24, 160 + #infoData * 28 + 16);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0;
		Text = ""; AutoButtonColor = false; ZIndex = 53; Parent = welcomeCard;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	tagBg(enterBtn, "accent")

	local eIco = mkIcon(enterBtn, "arrow-right", 16, Color3.fromRGB(6,6,10), 54)
	if eIco then eIco.AnchorPoint = Vector2.new(0, 0.5); eIco.Position = UDim2.new(0.5, 32, 0.5, 0) end
	mk("TextLabel", {
		Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1;
		Text = "Enter Leon X"; Font = Enum.Font.GothamBold; TextSize = 13;
		TextColor3 = Color3.fromRGB(6, 6, 10); ZIndex = 54; Parent = enterBtn;
	})

	enterBtn.MouseEnter:Connect(function()
		tw(enterBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(
			math.min(theme.Accent.R*255+20,255), math.min(theme.Accent.G*255+20,255), math.min(theme.Accent.B*255+20,255))
		})
	end)
	enterBtn.MouseLeave:Connect(function() tw(enterBtn, 0.12, { BackgroundColor3 = theme.Accent }) end)

	function win:DismissWelcome()
		tw(welcomeFrame, 0.3, { BackgroundTransparency = 1 })
		for _, child in ipairs(welcomeCard:GetDescendants()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				pcall(function() tw(child, 0.25, { TextTransparency = 1 }) end)
			elseif child:IsA("Frame") and child ~= welcomeCard then
				pcall(function() tw(child, 0.25, { BackgroundTransparency = 1 }) end)
			elseif child:IsA("ImageLabel") then
				pcall(function() tw(child, 0.25, { ImageTransparency = 1 }) end)
			end
		end
		tw(welcomeCard, 0.3, { BackgroundTransparency = 1 })
		task.wait(0.4)
		welcomeFrame.Visible = false; welcomeFrame.ZIndex = 0
	end

	enterBtn.MouseButton1Click:Connect(function() win:DismissWelcome() end)

	-- ════════════════════════════════════════════════════════════════════════
	-- TABS — horizontal pill-shaped tab buttons
	-- ════════════════════════════════════════════════════════════════════════
	function win:Tab(cfg)
		cfg = cfg or {}
		local tabName = cfg.Title or cfg.Name or "Tab"
		local tabIconName = cfg.Icon or ""
		local tab = { Name = tabName; _layoutOrder = 0; _page = content; _win = win }
		local idx = #win._tabs + 1

		-- Measure width: icon(20) + text + padding
		local estimatedW = 14 + (tabIconName ~= "" and 22 or 0) + (#tabName * 7) + 14
		estimatedW = math.max(estimatedW, 60)

		local btn = mk("TextButton", {
			Size = UDim2.new(0, estimatedW, 0, 32);
			BackgroundColor3 = theme.Elevated;
			BackgroundTransparency = 1;
			Text = ""; AutoButtonColor = false;
			LayoutOrder = idx; ZIndex = 11; Parent = tabBar;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })

		-- Tab icon
		local tIco = nil
		local icoOff = 10
		if tabIconName ~= "" then
			tIco = mkIcon(btn, tabIconName, 14, theme.TextSub, 12)
			if tIco then
				tIco.Position = UDim2.new(0, 10, 0.5, -7)
				tagIcon(tIco, "textsub")
				icoOff = 28
			end
		end

		-- Tab label
		local tLabel = tagText(mk("TextLabel", {
			Size = UDim2.new(1, -(icoOff + 10), 1, 0);
			Position = UDim2.fromOffset(icoOff, 0);
			BackgroundTransparency = 1; Text = tabName;
			Font = Enum.Font.GothamMedium; TextSize = 11;
			TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 12; Parent = btn;
		}), "textsub")

		-- Count badge
		local countBadge = mk("TextLabel", {
			Size = UDim2.fromOffset(0, 0); Visible = false;
			BackgroundTransparency = 1; Text = ""; Font = Enum.Font.GothamBold;
			TextSize = 0; TextColor3 = theme.TextSub; ZIndex = 12; Parent = btn;
		})
		tab._countBadge = countBadge

		local isActive = false
		local function setActive(active)
			isActive = active
			if active then
				tw(btn, 0.2, { BackgroundTransparency = 0, BackgroundColor3 = theme.Accent })
				tw(tLabel, 0.15, { TextColor3 = Color3.fromRGB(6, 6, 10) })
				if tIco then tw(tIco, 0.15, { ImageColor3 = Color3.fromRGB(6, 6, 10) }) end
			else
				tw(btn, 0.2, { BackgroundTransparency = 1 })
				tw(tLabel, 0.15, { TextColor3 = win._theme.TextSub })
				if tIco then tw(tIco, 0.15, { ImageColor3 = win._theme.TextSub }) end
			end
			for _, entry in ipairs(win._allComps) do
				if entry._tab == tab then entry.Frame.Visible = active end
			end
		end

		btn.MouseButton1Click:Connect(function()
			for _, t in ipairs(win._tabs) do t._setActive(false) end
			setActive(true); win._active = tab
		end)
		btn.MouseEnter:Connect(function()
			if not isActive then
				tw(btn, 0.12, { BackgroundTransparency = 0.6, BackgroundColor3 = win._theme.Elevated })
			end
		end)
		btn.MouseLeave:Connect(function()
			if not isActive then tw(btn, 0.12, { BackgroundTransparency = 1 }) end
		end)

		tab._setActive = setActive
		win._tabs[#win._tabs + 1] = tab
		if idx == 1 then setActive(true) end

		local function wrap(fn)
			return function(selfOrData, maybeData)
				local d = maybeData or selfOrData
				local r = fn(tab, d)
				if r and r.Frame then
					win._allComps[#win._allComps + 1] = { _tab = tab; Frame = r.Frame }
					-- badge is hidden in this layout (tabs too small)
				end
				return r
			end
		end
		tab.Section   = wrap(Section)
		tab.Paragraph = wrap(Paragraph)
		tab.Toggle    = wrap(Toggle)
		tab.Slider    = wrap(Slider)
		tab.Dropdown  = wrap(Dropdown)
		tab.Button    = wrap(Button)
		tab.Keybind   = wrap(Keybind)
		tab.Input     = wrap(Input)

		return tab
	end

	win._sg = sg; win._main = main; win._header = headerBg
	win._floatGui = floatGui; win._floatBtn = floatBtn
	win._welcomeFrame = welcomeFrame
	return win
end

-- ════════════════════════════════════════════════════════════════════════════
-- THEME HELPER
-- ════════════════════════════════════════════════════════════════════════════
local function th(tab)
	if tab._win then return tab._win._theme end
	return Library.Themes[Library._lastTheme or "Default"] or Library.Themes.Default
end

local function nextOrder(tab)
	tab._layoutOrder = (tab._layoutOrder or 0) + 1
	return tab._layoutOrder
end

-- ════════════════════════════════════════════════════════════════════════════
-- COMPONENTS — redesigned with card wrappers and accent highlights
-- ════════════════════════════════════════════════════════════════════════════

-- ── Section (accent line + icon) ──
function Section(tab, data)
	local label = getLabel(data)
	local theme = th(tab)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 30); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	if tab._layoutOrder > 1 then
		tagBg(mk("Frame", {
			Size = UDim2.new(1, 0, 0, 1); BackgroundColor3 = theme.BorderSub;
			BorderSizePixel = 0; Parent = f;
		}), "bordersub")
	end

	-- Accent underline
	tagBg(mk("Frame", {
		Size = UDim2.new(0, 24, 0, 2); Position = UDim2.fromOffset(0, 24);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; Parent = f;
	}), "accent")
	mk("UICorner", { CornerRadius = UDim.new(0, 1); Parent = f:GetChildren()[#f:GetChildren()] })

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -8, 0, 16); Position = UDim2.fromOffset(0, 6);
		BackgroundTransparency = 1; Text = label:upper();
		Font = Enum.Font.GothamBold; TextSize = 10; TextColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "textsub")
	return { Frame = f }
end

-- ── Paragraph ──
function Paragraph(tab, data)
	local theme = th(tab)
	local label = getLabel(data)
	local hasTitle = data.Title and data.Title ~= ""
	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, hasTitle and 44 or 32);
		BackgroundColor3 = theme.Card; BorderSizePixel = 0;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14)
	pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = f

	if hasTitle then
		tagText(mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 12); BackgroundTransparency = 1;
			Text = label; Font = Enum.Font.GothamBold; TextSize = 10;
			TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
		}), "textsub")
	end
	local cl = tagText(mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16); Position = UDim2.fromOffset(0, hasTitle and 14 or 0);
		BackgroundTransparency = 1; Text = data.Content or "";
		Font = Enum.Font.Gotham; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; TextWrapped = true; Parent = f;
	}), "text")
	local api = { Frame = f; Name = data.Title or "Paragraph" }
	function api:Set(t) cl.Text = t end
	function api:Get() return cl.Text end
	return api
end

-- ── Toggle (card-wrapped with accent left bar when active) ──
function Toggle(tab, data)
	local label = getLabel(data)
	local theme = th(tab)
	local val = data.Value ~= nil and data.Value or (data.Default ~= nil and data.Default or false)

	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 40); BackgroundColor3 = theme.Card;
		BackgroundTransparency = 0; BorderSizePixel = 0;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })

	-- Accent left bar (visible when enabled)
	local accentBar = tagBg(mk("Frame", {
		Size = UDim2.new(0, 3, 0, 20); Position = UDim2.new(0, 0, 0.5, -10);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0;
		BackgroundTransparency = val and 0 or 1; Parent = f;
	}), "accent")
	mk("UICorner", { CornerRadius = UDim.new(0, 2); Parent = accentBar })

	-- Optional icon
	local tIco = nil; local lx = 14
	if data.Icon then
		tIco = mkIcon(f, data.Icon, 15, val and theme.Accent or theme.TextDim, 2)
		if tIco then tIco.Position = UDim2.new(0, 14, 0.5, -7); lx = 36 end
	end

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -(lx + 56), 1, 0); Position = UDim2.fromOffset(lx, 0);
		BackgroundTransparency = 1; Text = label;
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "text")

	-- Switch track
	local track = mk("Frame", {
		Size = UDim2.fromOffset(38, 20); Position = UDim2.new(1, -50, 0.5, -10);
		BackgroundColor3 = val and theme.Accent or theme.Border;
		BorderSizePixel = 0; Parent = f;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = track })

	local knob = mk("Frame", {
		Size = UDim2.fromOffset(14, 14);
		Position = val and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7);
		BackgroundColor3 = Color3.fromRGB(255,255,255); BorderSizePixel = 0; Parent = track;
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0); Parent = knob })

	local api = { Value = val; Frame = f; Name = data.Title or data.Name or "Toggle"; Callback = data.Callback }
	function api:Set(v)
		v = not not v
		if self.Value == v then return end
		self.Value = v
		tw(track, 0.2, { BackgroundColor3 = v and theme.Accent or theme.Border }, Enum.EasingStyle.Back)
		tw(knob, 0.2, { Position = v and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) }, Enum.EasingStyle.Back)
		tw(accentBar, 0.15, { BackgroundTransparency = v and 0 or 1 })
		if tIco then tw(tIco, 0.15, { ImageColor3 = v and theme.Accent or theme.TextDim }) end
		if self.Callback then pcall(self.Callback, v) end
	end
	function api:Get() return self.Value end

	local btn = mk("TextButton", { Size = UDim2.fromScale(1,1); BackgroundTransparency = 1; Text = ""; Parent = f })
	btn.MouseButton1Click:Connect(function() api:Set(not api.Value) end)

	-- Hover effect
	btn.MouseEnter:Connect(function()
		tw(f, 0.1, { BackgroundColor3 = theme.Elevated })
	end)
	btn.MouseLeave:Connect(function()
		tw(f, 0.1, { BackgroundColor3 = theme.Card })
	end)

	reg(data, api)
	attachTooltip(api, data.Tooltip)
	return api
end

-- ── Slider (card-wrapped, gradient fill, round handle) ──
function Slider(tab, data)
	local theme = th(tab)
	local mn = (data.Value and data.Value.Min) or 0
	local mx = (data.Value and data.Value.Max) or 100
	local df = (data.Value and data.Value.Default) or mn
	local step = data.Step or 1
	local cur = df

	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 52); BackgroundColor3 = theme.Card;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -80, 0, 14); Position = UDim2.fromOffset(14, 6);
		BackgroundTransparency = 1; Text = getLabel(data);
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "text")

	-- Value box
	local valLbl = mk("TextBox", {
		Size = UDim2.new(0, 50, 0, 20); Position = UDim2.new(1, -64, 0, 4);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = tostring(df); Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.Accent; TextXAlignment = Enum.TextXAlignment.Center; Parent = f;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 6); Parent = valLbl })
	tagBg(valLbl, "elevated"); tagText(valLbl, "accent")

	-- Track
	local trk = mk("Frame", {
		Size = UDim2.new(1, -28, 0, 6); Position = UDim2.new(0, 14, 0, 34);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; Parent = f;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 3); Parent = trk })
	tagBg(trk, "border")

	-- Fill
	local fill = mk("Frame", {
		Size = UDim2.new((df-mn)/math.max(mx-mn,1), 0, 1, 0);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; Parent = trk;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 3); Parent = fill })
	tagBg(fill, "accent")
	mk("UIGradient", {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1, theme.Accent) });
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0.85) });
		Rotation = 0; Parent = fill;
	})

	-- Handle
	local handle = mk("Frame", {
		Size = UDim2.new(0, 14, 0, 14); Position = UDim2.new(1, -7, 0.5, -7);
		BackgroundColor3 = Color3.fromRGB(255,255,255); BorderSizePixel = 0; Parent = fill;
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0); Parent = handle })
	local hGlow = mk("UIStroke", { Color = theme.Accent; Thickness = 0; Transparency = 0.4; Parent = handle })

	local function upd(v)
		local pct = math.clamp((v - mn) / math.max(mx - mn, 1), 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		valLbl.Text = tostring(math.floor(v + 0.5))
	end

	local sDrag = false
	trk.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		sDrag = true
		tw(handle, 0.1, { Size = UDim2.new(0, 16, 0, 16) }); tw(hGlow, 0.1, { Thickness = 3 })
		local pos = (i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X
		local nv = mn + math.clamp(pos, 0, 1) * (mx - mn)
		nv = math.floor(nv / step + 0.5) * step; nv = math.clamp(nv, mn, mx)
		if nv ~= cur then cur = nv; upd(nv); if data.Callback then pcall(data.Callback, nv) end end
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				sDrag = false; tw(handle, 0.1, { Size = UDim2.new(0, 14, 0, 14) }); tw(hGlow, 0.1, { Thickness = 0 })
			end
		end)
	end)
	UIS.InputChanged:Connect(function(i)
		if not sDrag then return end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
		local pos = (i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X
		local nv = mn + math.clamp(pos, 0, 1) * (mx - mn)
		nv = math.floor(nv / step + 0.5) * step; nv = math.clamp(nv, mn, mx)
		if nv ~= cur then cur = nv; upd(nv); if data.Callback then pcall(data.Callback, nv) end end
	end)

	valLbl.FocusLost:Connect(function(enter)
		if not enter then valLbl.Text = tostring(cur); return end
		local num = tonumber(valLbl.Text)
		if num then num = math.clamp(num, mn, mx); cur = num; upd(cur); if data.Callback then pcall(data.Callback, cur) end end
		valLbl.Text = tostring(cur)
	end)

	local api = { Value = df; Frame = f; Name = data.Title or data.Name or "Slider"; Callback = data.Callback }
	function api:Set(v) v = math.clamp(v, mn, mx); if self.Value == v then return end; self.Value = v; cur = v; upd(v); if self.Callback then pcall(self.Callback, v) end end
	function api:Get() return self.Value end
	reg(data, api); attachTooltip(api, data.Tooltip)
	return api
end

-- ── Dropdown (card-wrapped, search, check icons) ──
function Dropdown(tab, data)
	local theme = th(tab)
	local vals = data.Values or {}
	local cur = data.Value or (vals[1] or "")
	if type(cur) == "number" and vals[cur] then cur = vals[cur] end
	local open = false; local searchTerm = ""
	local CLOSED_H = 54; local ITEM_H = 28; local SEARCH_H = 32; local MAX_VIS = 6

	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, CLOSED_H); BackgroundColor3 = theme.Card;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -28, 0, 12); Position = UDim2.fromOffset(14, 5);
		BackgroundTransparency = 1; Text = getLabel(data);
		Font = Enum.Font.GothamBold; TextSize = 10; TextColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "textsub")

	local box = mk("TextButton", {
		Size = UDim2.new(1, -28, 0, 28); Position = UDim2.fromOffset(14, 20);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = ""; AutoButtonColor = false; ZIndex = 2; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	tagBg(box, "elevated")
	tagBorder(mk("UIStroke", { Color = theme.Border; Thickness = 1; Parent = box }), "border")

	local valTxt = tagText(mk("TextLabel", {
		Size = UDim2.new(1, -36, 1, 0); Position = UDim2.fromOffset(10, 0);
		BackgroundTransparency = 1; Text = tostring(cur);
		Font = Enum.Font.GothamMedium; TextSize = 11; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 3; Parent = box;
	}), "text")

	local chev = mkIcon(box, "chevron-down", 12, theme.Accent, 3)
	if chev then chev.AnchorPoint = Vector2.new(1, 0.5); chev.Position = UDim2.new(1, -8, 0.5, 0); tagIcon(chev, "accent") end

	-- Search
	local sFrame = mk("Frame", {
		Size = UDim2.new(1, -28, 0, 26); Position = UDim2.fromOffset(14, 52);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Visible = false; ZIndex = 3; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 6) }) })
	tagBg(sFrame, "elevated")
	local sIco = mkIcon(sFrame, "search", 11, theme.TextDim, 4)
	if sIco then sIco.Position = UDim2.new(0, 7, 0.5, -5) end
	local searchBox = mk("TextBox", {
		Size = UDim2.new(1, -(sIco and 26 or 10), 1, 0);
		Position = UDim2.fromOffset(sIco and 22 or 6, 0);
		BackgroundTransparency = 1; PlaceholderText = "Search..."; PlaceholderColor3 = theme.TextDim;
		Text = ""; Font = Enum.Font.GothamMedium; TextSize = 10;
		TextColor3 = theme.Text; ClearTextOnFocus = true;
		TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 4; Parent = sFrame;
	})
	tagText(searchBox, "text")

	local scroll = mk("ScrollingFrame", {
		Size = UDim2.new(1, -28, 0, 0); Position = UDim2.fromOffset(14, 82);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 2; ScrollBarImageColor3 = theme.AccentDim;
		Visible = false; ZIndex = 3; Parent = f;
	})
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder; Padding = UDim.new(0, 2); Parent = scroll })

	local api = { Value = cur; Frame = f; Name = data.Title or data.Name or "Dropdown"; Callback = data.Callback }

	local function cntFilt()
		local c = 0; for _, v in ipairs(vals) do if searchTerm == "" or tostring(v):lower():find(searchTerm, 1, true) then c = c + 1 end end; return c
	end

	local function rebuild()
		for _, c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local flt = {}
		for _, v in ipairs(vals) do if searchTerm == "" or tostring(v):lower():find(searchTerm, 1, true) then flt[#flt+1] = v end end
		for _, v in ipairs(flt) do
			local sel = tostring(v) == tostring(cur)
			local item = mk("TextButton", {
				Size = UDim2.new(1, -4, 0, ITEM_H); BackgroundTransparency = 1;
				Text = ""; AutoButtonColor = false; ZIndex = 4; Parent = scroll;
			}, { mk("UICorner", { CornerRadius = UDim.new(0, 6) }) })
			if sel then
				local ck = mkIcon(item, "check", 11, theme.Accent, 5)
				if ck then ck.AnchorPoint = Vector2.new(1, 0.5); ck.Position = UDim2.new(1, -6, 0.5, 0) end
			end
			mk("TextLabel", {
				Size = UDim2.new(1, -24, 1, 0); Position = UDim2.fromOffset(10, 0);
				BackgroundTransparency = 1; Text = tostring(v);
				Font = Enum.Font.GothamMedium; TextSize = 11;
				TextColor3 = sel and theme.Accent or theme.Text;
				TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 5; Parent = item;
			})
			item.MouseEnter:Connect(function() item.BackgroundColor3 = theme.Elevated; item.BackgroundTransparency = 0.3 end)
			item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
			item.MouseButton1Click:Connect(function()
				cur = v; valTxt.Text = tostring(v); api.Value = v
				searchTerm = ""; searchBox.Text = ""
				open = false; sFrame.Visible = false; scroll.Visible = false
				tw(f, 0.15, { Size = UDim2.new(1, 0, 0, CLOSED_H) })
				if chev then tw(chev, 0.15, { Rotation = 0 }) end
				if data.Callback then pcall(data.Callback, v) end
			end)
		end
		scroll.CanvasSize = UDim2.fromOffset(0, #flt * (ITEM_H + 2))
		if open then
			local vc = math.min(#flt, MAX_VIS)
			scroll.Size = UDim2.new(1, -28, 0, vc * (ITEM_H + 2))
			tw(f, 0.1, { Size = UDim2.new(1, 0, 0, CLOSED_H + vc * (ITEM_H + 2) + SEARCH_H + 6) })
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function() searchTerm = searchBox.Text:lower(); rebuild() end)
	rebuild()

	box.MouseButton1Click:Connect(function()
		if open then
			open = false; sFrame.Visible = false; scroll.Visible = false
			searchTerm = ""; searchBox.Text = ""
			tw(f, 0.15, { Size = UDim2.new(1, 0, 0, CLOSED_H) })
			if chev then tw(chev, 0.15, { Rotation = 0 }) end
		else
			open = true; sFrame.Visible = true; scroll.Visible = true
			searchBox.Text = ""; rebuild()
			local vc = math.min(cntFilt(), MAX_VIS)
			scroll.Size = UDim2.new(1, -28, 0, vc * (ITEM_H + 2))
			tw(f, 0.15, { Size = UDim2.new(1, 0, 0, CLOSED_H + vc * (ITEM_H + 2) + SEARCH_H + 6) })
			if chev then tw(chev, 0.15, { Rotation = 180 }) end
			task.wait(0.05); pcall(function() searchBox:CaptureFocus() end)
		end
	end)

	function api:Refresh(v)
		vals = v or {}; searchTerm = ""; searchBox.Text = ""; rebuild()
		local found = false
		for _, item in ipairs(vals) do if tostring(item) == tostring(cur) then found = true; break end end
		if not found and #vals > 0 then cur = vals[1]; valTxt.Text = tostring(vals[1]); api.Value = vals[1] end
	end
	function api:Select(v) cur = v; valTxt.Text = tostring(v); api.Value = v end
	function api:Set(v) self:Select(v); if self.Callback then pcall(self.Callback, v) end end
	function api:Get() return self.Value end
	reg(data, api); attachTooltip(api, data.Tooltip)
	return api
end

-- ── Button ──
function Button(tab, data)
	local theme = th(tab)
	local style = data.Style or "Surface"
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 36); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	local bgC, txC, brC, brT
	if style == "Primary" then bgC = theme.Accent; txC = Color3.fromRGB(255,255,255); brC = theme.Accent; brT = 0
	elseif style == "Outline" then bgC = Color3.new(); txC = theme.Accent; brC = theme.Accent; brT = 1
	elseif style == "Danger" then bgC = Color3.fromRGB(220,53,69); txC = Color3.fromRGB(255,255,255); brC = bgC; brT = 0
	elseif style == "Ghost" then bgC = Color3.new(); txC = theme.Text; brC = Color3.new(); brT = 0
	else bgC = theme.Card; txC = theme.Text; brC = theme.Border; brT = 1 end

	local btn = mk("TextButton", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = bgC;
		BackgroundTransparency = (style == "Outline" or style == "Ghost") and 1 or 0;
		BorderSizePixel = 0; Text = getLabel(data);
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = txC;
		AutoButtonColor = false; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	mk("UIStroke", { Color = brC; Thickness = brT; Parent = btn })

	btn.MouseEnter:Connect(function()
		if style == "Primary" then tw(btn, 0.1, { BackgroundColor3 = theme.Accent:Lerp(Color3.fromRGB(255,255,255), 0.12) })
		elseif style == "Outline" then tw(btn, 0.1, { BackgroundColor3 = theme.Accent; BackgroundTransparency = 0.9 })
		elseif style == "Danger" then tw(btn, 0.1, { BackgroundColor3 = Color3.fromRGB(255,80,90) })
		elseif style == "Ghost" then tw(btn, 0.1, { BackgroundColor3 = theme.Card; BackgroundTransparency = 0 })
		else tw(btn, 0.1, { BackgroundColor3 = theme.Elevated }) end
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = bgC; btn.BackgroundTransparency = (style == "Outline" or style == "Ghost") and 1 or 0
	end)
	btn.MouseButton1Click:Connect(function() if data.Callback then pcall(data.Callback) end end)
	local api = { Frame = f; Name = data.Title or data.Name or "Button" }
	attachTooltip(api, data.Tooltip); return api
end

-- ── Keybind ──
function Keybind(tab, data)
	local theme = th(tab)
	local cur = data.Value or data.Default or "None"; local capturing = false
	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 40); BackgroundColor3 = theme.Card;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })

	local kIco = mkIcon(f, "keyboard", 13, theme.TextDim, 1)
	if kIco then kIco.Position = UDim2.new(0, 14, 0.5, -6) end

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -108, 1, 0); Position = UDim2.fromOffset(kIco and 34 or 14, 0);
		BackgroundTransparency = 1; Text = getLabel(data);
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "text")

	local kbtn = tagBg(mk("TextButton", {
		Size = UDim2.fromOffset(76, 24); Position = UDim2.new(1, -88, 0.5, -12);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = tostring(cur); Font = Enum.Font.GothamBold; TextSize = 10;
		TextColor3 = theme.Accent; AutoButtonColor = false; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) }), "elevated")
	tagText(kbtn, "accent")
	local kS = tagBorder(mk("UIStroke", { Color = theme.Border; Thickness = 1; Parent = kbtn }), "border")

	kbtn.MouseButton1Click:Connect(function()
		if capturing then return end; capturing = true; kbtn.Text = "..."; kS.Color = theme.AccentDim
	end)
	UIS.InputBegan:Connect(function(i, gp)
		if not capturing or gp then return end
		if i.UserInputType == Enum.UserInputType.Keyboard then
			if i.KeyCode == Enum.KeyCode.Escape then
				capturing = false; kbtn.Text = tostring(cur); kS.Color = theme.Border
			else
				cur = i.KeyCode.Name; capturing = false; kbtn.Text = cur; kS.Color = theme.Border
				if data.Callback then pcall(data.Callback, cur) end
			end
		end
	end)
	local api = { Value = cur; Frame = f; Name = data.Title or data.Name or "Keybind"; Callback = data.Callback }
	function api:Set(v) cur = tostring(v); kbtn.Text = cur; if self.Callback then pcall(self.Callback, cur) end end
	function api:Get() return cur end
	reg(data, api); attachTooltip(api, data.Tooltip); return api
end

-- ── Input ──
function Input(tab, data)
	local theme = th(tab)
	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 56); BackgroundColor3 = theme.Card;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -28, 0, 12); Position = UDim2.fromOffset(14, 5);
		BackgroundTransparency = 1; Text = getLabel(data);
		Font = Enum.Font.GothamBold; TextSize = 10; TextColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "textsub")

	local stroke = tagBorder(mk("UIStroke", { Color = theme.Border; Thickness = 1 }), "border")
	local tb = tagBg(mk("TextBox", {
		Size = UDim2.new(1, -28, 0, 26); Position = UDim2.fromOffset(14, 22);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		PlaceholderText = data.Placeholder or ""; Text = data.Value or "";
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = theme.Text;
		PlaceholderColor3 = theme.TextDim; TextXAlignment = Enum.TextXAlignment.Left;
		ClearTextOnFocus = false; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }), stroke }), "elevated")
	tagText(tb, "text")
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 10); pad.Parent = tb

	local api = { Value = data.Value or ""; Frame = f; Name = data.Title or data.Name or "Input"; Callback = data.Callback }
	tb.FocusLost:Connect(function() api.Value = tb.Text; if data.Callback then pcall(data.Callback, tb.Text) end end)
	tb.Focused:Connect(function() stroke.Color = theme.AccentDim end)
	tb.FocusLost:Connect(function() stroke.Color = theme.Border end)
	function api:Set(v) self.Value = tostring(v or ""); tb.Text = self.Value; if self.Callback then pcall(self.Callback, self.Value) end end
	function api:Get() return tb.Text end
	reg(data, api); attachTooltip(api, data.Tooltip); return api
end

-- ════════════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS (slide in from top-right with icon + progress)
-- ════════════════════════════════════════════════════════════════════════════
function Library:Notify(cfg)
	cfg = cfg or {}
	local title = cfg.Title or ""; local text = cfg.Content or cfg.Text or ""
	local dur = cfg.Duration or 2; local nIcon = cfg.Icon or "bell"
	local theme = self.Themes[self._lastTheme or "Default"] or self.Themes.Default

	local n = mk("Frame", {
		Size = UDim2.new(0, 300, 0, 64);
		Position = UDim2.new(1, 320, 0, 14 + #activeNotifs * 72);
		BackgroundColor3 = theme.Card; BorderSizePixel = 0;
		ClipsDescendants = true; ZIndex = 100; Parent = notifGui;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	mk("UIStroke", { Color = theme.Border; Thickness = 1; ZIndex = 100; Parent = n })

	-- Accent top line
	tagBg(mk("Frame", {
		Size = UDim2.new(1, -16, 0, 2); Position = UDim2.new(0, 8, 0, 0);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; ZIndex = 101; Parent = n;
	}), "accent")
	mk("UICorner", { CornerRadius = UDim.new(0, 1); Parent = n:GetChildren()[#n:GetChildren()] })

	local nIco = mkIcon(n, nIcon, 16, theme.Accent, 102)
	local cx = 14
	if nIco then nIco.Position = UDim2.fromOffset(12, 14); cx = 34 end

	if title ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(1, -(cx+8), 0, 16); Position = UDim2.fromOffset(cx, 10);
			BackgroundTransparency = 1; Text = title;
			Font = Enum.Font.GothamBold; TextSize = 12; TextColor3 = theme.Text;
			TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 101; Parent = n;
		})
	end
	if text ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(1, -(cx+8), 0, 14); Position = UDim2.fromOffset(cx, title ~= "" and 28 or 12);
			BackgroundTransparency = 1; Text = text;
			Font = Enum.Font.Gotham; TextSize = 11; TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Left; TextWrapped = true; ZIndex = 101; Parent = n;
		})
	end

	-- Progress
	local pBar = mk("Frame", {
		Size = UDim2.new(1, -12, 0, 2); Position = UDim2.new(0, 6, 1, -6);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; ZIndex = 101; ClipsDescendants = true; Parent = n;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 1) }) })
	local pFill = mk("Frame", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = theme.Accent;
		BorderSizePixel = 0; ZIndex = 102; Parent = pBar;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 1) }) })

	activeNotifs[#activeNotifs + 1] = n
	tw(n, 0.25, { Position = UDim2.new(1, -314, 0, 14 + (#activeNotifs-1) * 72) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tw(pFill, dur, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)

	task.delay(dur, function()
		tw(n, 0.2, { Position = UDim2.new(1, 320, 0, n.Position.Y.Offset); BackgroundTransparency = 1 })
		task.wait(0.25)
		for i, v in ipairs(activeNotifs) do if v == n then table.remove(activeNotifs, i); break end end
		for i, v in ipairs(activeNotifs) do tw(v, 0.15, { Position = UDim2.new(1, -314, 0, 14 + (i-1) * 72) }) end
		task.wait(0.15); pcall(function() n:Destroy() end)
	end)
end

return Library
