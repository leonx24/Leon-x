-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Leon X  |  CyberNoir UI Library v5                               ║
-- ║  "Unique Floating Sidebar with High-Contrast Icon Architecture"  ║
-- ╚══════════════════════════════════════════════════════════════════╝

print("[LeonX-LIB] CYBERNOIR-UI-V5")

local Library = {}
Library.Registry = {}
Library._allComponents = {}
Library._windows = {}
Library._icons = nil

-- ════════════════════════════════════════════════════════════════════════════
-- ICON ENGINE (Lucide Remote Asset Loader)
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
	size = size or 20
	color = color or Color3.fromRGB(255, 255, 255)
	zindex = zindex or 1
	
	local img = Instance.new("ImageLabel")
	img.Name = "Ico_" .. tostring(name)
	img.Size = UDim2.fromOffset(size, size)
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Image = assetId
	img.ImageColor3 = color
	img.ScaleType = Enum.ScaleType.Fit
	img.ZIndex = zindex
	if parent then img.Parent = parent end
	return img
end

-- ════════════════════════════════════════════════════════════════════════════
-- THEME ENGINE — Curated Vibrant Accent Palettes
-- ════════════════════════════════════════════════════════════════════════════
local function mkTheme(accent, accentDim, glowTint)
	return {
		BG        = Color3.fromRGB(10, 10, 14),
		Sidebar   = Color3.fromRGB(15, 15, 22),
		Surface   = Color3.fromRGB(18, 18, 26),
		Card      = Color3.fromRGB(22, 22, 32),
		Elevated  = Color3.fromRGB(28, 28, 40),
		Border    = Color3.fromRGB(38, 38, 54),
		BorderSub = Color3.fromRGB(28, 28, 40),
		Text      = Color3.fromRGB(240, 242, 250),
		TextSub   = Color3.fromRGB(140, 145, 165),
		TextDim   = Color3.fromRGB(80, 85, 105),
		Accent    = Color3.fromRGB(table.unpack(accent)),
		AccentDim = Color3.fromRGB(table.unpack(accentDim)),
		Glow      = Color3.fromRGB(table.unpack(glowTint or accent)),
	}
end

Library.Themes = {
	Default = mkTheme({100, 140, 255}, {55, 85, 180},  {80, 120, 240}),  -- Cyber Cobalt
	Gold    = mkTheme({245, 195, 70},  {180, 140, 40}, {230, 180, 50}),  -- Luxe Gold
	Emerald = mkTheme({60, 225, 140},  {35, 155, 90},  {50, 210, 125}),  -- Neon Emerald
	Rose    = mkTheme({245, 95, 140},  {180, 60, 95},  {230, 80, 125}),  -- Hot Crimson
	Violet  = mkTheme({165, 110, 255}, {110, 65, 190}, {150, 95, 240}),  -- Royal Violet
	Amber   = mkTheme({255, 160, 50},  {190, 110, 30}, {240, 145, 40}),  -- Sunset Amber
	Neon    = mkTheme({50, 240, 210},  {30, 175, 150}, {40, 225, 195}),  -- Electric Cyan
}

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITIES & ANIMATIONS
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
	local info = TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	local t = TS:Create(obj, info, props)
	t:Play()
	return t
end

-- ── Attribute Theme Tagging ──
local ROLE_COLORS = {
	bg = "BG", sidebar = "Sidebar", surface = "Surface", card = "Card", elevated = "Elevated",
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
			Name = "Tooltip"; Size = UDim2.fromOffset(220, 36);
			BackgroundColor3 = Color3.fromRGB(15, 15, 24);
			BorderSizePixel = 0; ZIndex = 300; Visible = false;
			Parent = game:GetService("CoreGui");
		})
		mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = tooltip })
		mk("UIStroke", { Color = Color3.fromRGB(45, 45, 65); Thickness = 1; Parent = tooltip })
		tooltipLabel = mk("TextLabel", {
			Size = UDim2.new(1, -16, 1, 0); Position = UDim2.fromOffset(8, 0);
			BackgroundTransparency = 1; Text = text;
			TextColor3 = Color3.fromRGB(210, 215, 230); TextSize = 11;
			Font = Enum.Font.GothamMedium; TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center; TextWrapped = true;
			ZIndex = 301; Parent = tooltip;
		})
	end
	local frame = component.Frame
	if not frame then return end
	frame.MouseEnter:Connect(function() createTooltip(); if tooltip then tooltip.Visible = true end end)
	frame.MouseMoved:Connect(function(x, y) if tooltip then tooltip.Position = UDim2.fromOffset(x + 14, y + 14) end end)
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
-- CREATE WINDOW — UNIQUE FLOATING SIDEBAR + BOLD ICON DISPLAY
-- ════════════════════════════════════════════════════════════════════════════
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title     = cfg.Title or "Leon X"
	local author    = cfg.Author or ""
	local size      = cfg.Size or UDim2.new(0, 680, 0, 540)
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

	-- ── Main ScreenGui ──
	local sg = mk("ScreenGui", {
		Name = "LeonXNoir"; ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		DisplayOrder = 999; IgnoreGuiInset = true;
		Parent = lp:WaitForChild("PlayerGui");
	})

	-- ── Main Frame ──
	local scale = isMobile and 0.8 or 1.0
	local main = mk("Frame", {
		Size = size;
		Position = UDim2.new(0.5, -(size.X.Offset * scale) / 2, 0.5, -(size.Y.Offset * scale) / 2);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ClipsDescendants = false; Active = false; Parent = sg;
	})
	if isMobile then mk("UIScale", { Scale = scale; Parent = main }) end

	-- ── Outer Shadow & Glow Frame ──
	local bgFrame = tagBg(mk("Frame", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = theme.BG;
		BorderSizePixel = 0; ZIndex = 1; Active = false; Parent = main;
	}), "bg")
	mk("UICorner", { CornerRadius = UDim.new(0, 16); Parent = bgFrame })
	tagBorder(mk("UIStroke", { Color = theme.Border; Thickness = 1.2; Parent = bgFrame }), "border")

	-- Ambient background gradient
	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.BG),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 10)),
		}); Rotation = 45; Parent = bgFrame;
	})

	-- ════════════════════════════════════════════════════════════════════════
	-- UNIQUE SIDEBAR — Floating Left Panel with Icon Tiles
	-- ════════════════════════════════════════════════════════════════════════
	local SIDEBAR_W = 200
	local sidebar = tagBg(mk("Frame", {
		Size = UDim2.new(0, SIDEBAR_W - 12, 1, -24);
		Position = UDim2.fromOffset(12, 12);
		BackgroundColor3 = theme.Sidebar;
		BorderSizePixel = 0; ZIndex = 10; Parent = main;
	}), "sidebar")
	mk("UICorner", { CornerRadius = UDim.new(0, 14); Parent = sidebar })
	tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = sidebar }), "bordersub")

	-- ── Brand Badge (Top of Sidebar) ──
	local brandBox = mk("Frame", {
		Size = UDim2.new(1, -20, 0, 52);
		Position = UDim2.fromOffset(10, 12);
		BackgroundColor3 = theme.Card; BorderSizePixel = 0;
		ZIndex = 11; Parent = sidebar;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	tagBg(brandBox, "card")
	tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = brandBox }), "bordersub")

	-- Logo Icon Badge (32x32 rounded tile)
	local logoTile = tagBg(mk("Frame", {
		Size = UDim2.fromOffset(34, 34); Position = UDim2.fromOffset(8, 9);
		BackgroundColor3 = theme.Accent; BackgroundTransparency = 0.85;
		BorderSizePixel = 0; ZIndex = 12; Parent = brandBox;
	}), "accent")
	mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = logoTile })
	
	local logoIco = mkIcon(logoTile, "zap", 20, theme.Accent, 13)
	if logoIco then
		logoIco.AnchorPoint = Vector2.new(0.5, 0.5)
		logoIco.Position = UDim2.fromScale(0.5, 0.5)
		tagIcon(logoIco, "accent")
	end

	-- Title & Subtitle
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -54, 0, 18); Position = UDim2.fromOffset(48, 10);
		BackgroundTransparency = 1; Text = "Leon X";
		Font = Enum.Font.GothamBold; TextSize = 15;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 12; Parent = brandBox;
	}), "text")

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -54, 0, 14); Position = UDim2.fromOffset(48, 28);
		BackgroundTransparency = 1; Text = "CyberNoir v5";
		Font = Enum.Font.GothamMedium; TextSize = 10;
		TextColor3 = theme.TextDim; TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 12; Parent = brandBox;
	}), "textdim")

	-- ── Sidebar Divider ──
	tagBg(mk("Frame", {
		Size = UDim2.new(1, -24, 0, 1); Position = UDim2.fromOffset(12, 74);
		BackgroundColor3 = theme.BorderSub; BorderSizePixel = 0;
		ZIndex = 11; Parent = sidebar;
	}), "bordersub")

	-- ── Tab List Scroll ──
	local tabList = mk("ScrollingFrame", {
		Size = UDim2.new(1, -16, 1, -92); Position = UDim2.fromOffset(8, 82);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 0; CanvasSize = UDim2.fromOffset(0, 0);
		ClipsDescendants = true; ZIndex = 11; Parent = sidebar;
	})
	local tabListLayout = mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = UDim.new(0, 6); Parent = tabList;
	})
	tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabList.CanvasSize = UDim2.fromOffset(0, tabListLayout.AbsoluteContentSize.Y + 10)
	end)

	-- ════════════════════════════════════════════════════════════════════════
	-- RIGHT CONTENT CONTAINER — Header + Dynamic Page Content
	-- ════════════════════════════════════════════════════════════════════════
	local CONTENT_X = SIDEBAR_W + 6
	local CONTENT_W = size.X.Offset - CONTENT_X - 14

	-- ── Top Header Bar ──
	local headerBg = mk("Frame", {
		Size = UDim2.new(1, -CONTENT_X - 12, 0, 52);
		Position = UDim2.fromOffset(CONTENT_X, 12);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ZIndex = 10; Active = true; Parent = main;
	})

	-- Active Tab Big Title Display
	local headerTabIconContainer = tagBg(mk("Frame", {
		Size = UDim2.fromOffset(36, 36); Position = UDim2.fromOffset(0, 8);
		BackgroundColor3 = theme.Card; BorderSizePixel = 0;
		ZIndex = 11; Parent = headerBg;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = headerTabIconContainer })
	tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = headerTabIconContainer }), "bordersub")

	local headerTabIcon = mkIcon(headerTabIconContainer, "sparkles", 20, theme.Accent, 12)
	if headerTabIcon then
		headerTabIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		headerTabIcon.Position = UDim2.fromScale(0.5, 0.5)
		tagIcon(headerTabIcon, "accent")
	end

	local headerTitleLabel = tagText(mk("TextLabel", {
		Size = UDim2.new(1, -160, 0, 22); Position = UDim2.fromOffset(46, 6);
		BackgroundTransparency = 1; Text = "Dashboard";
		Font = Enum.Font.GothamBold; TextSize = 17;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 11; Parent = headerBg;
	}), "text")

	local headerSubLabel = tagText(mk("TextLabel", {
		Size = UDim2.new(1, -160, 0, 14); Position = UDim2.fromOffset(46, 28);
		BackgroundTransparency = 1; Text = author ~= "" and author or "Universal Mode";
		Font = Enum.Font.GothamMedium; TextSize = 10;
		TextColor3 = theme.TextDim; TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 11; Parent = headerBg;
	}), "textdim")

	-- Header Controls (Minimize & Close)
	local function hdrIconBtn(xOff, iconName)
		local b = mk("TextButton", {
			Size = UDim2.fromOffset(32, 32);
			Position = UDim2.new(1, xOff, 0.5, -16);
			BackgroundColor3 = theme.Sidebar; BackgroundTransparency = 0;
			Text = ""; AutoButtonColor = false; ZIndex = 15; Parent = headerBg;
		}, {
			mk("UICorner", { CornerRadius = UDim.new(0, 9) }),
		})
		tagBg(b, "sidebar")
		tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = b }), "bordersub")
		
		local ico = mkIcon(b, iconName, 16, theme.TextSub, 16)
		if ico then
			ico.AnchorPoint = Vector2.new(0.5, 0.5)
			ico.Position = UDim2.fromScale(0.5, 0.5)
		end
		b.MouseEnter:Connect(function()
			tw(b, 0.12, { BackgroundColor3 = theme.Card })
			if ico then tw(ico, 0.12, { ImageColor3 = theme.Text }) end
		end)
		b.MouseLeave:Connect(function()
			tw(b, 0.12, { BackgroundColor3 = theme.Sidebar })
			if ico then tw(ico, 0.12, { ImageColor3 = theme.TextSub }) end
		end)
		return b
	end

	local minBtn = hdrIconBtn(-70, "minus")
	local closeBtn = hdrIconBtn(-34, "x")

	-- ── Content Scrolling Canvas ──
	local CONTENT_Y = 70
	local content = mk("ScrollingFrame", {
		Size = UDim2.new(1, -CONTENT_X - 12, 1, -CONTENT_Y - 12);
		Position = UDim2.fromOffset(CONTENT_X, CONTENT_Y);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 3; ScrollBarImageColor3 = theme.AccentDim;
		CanvasSize = UDim2.fromOffset(0, 0);
		ClipsDescendants = true; ZIndex = 5; Parent = main;
	})
	local contentLayout = mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder; Padding = UDim.new(0, 8); Parent = content;
	})
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 2); PaddingBottom = UDim.new(0, 16);
		PaddingLeft = UDim.new(0, 2); PaddingRight = UDim.new(0, 8);
		Parent = content;
	})
	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		content.CanvasSize = UDim2.fromOffset(0, contentLayout.AbsoluteContentSize.Y + 30)
	end)
	pcall(function() content.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
	win._allComps = {}

	-- ════════════════════════════════════════════════════════════════════════
	-- FLOATING MOBILE TOGGLE BUTTON
	-- ════════════════════════════════════════════════════════════════════════
	local floatGui = mk("ScreenGui", {
		Name = "LeonXFloat"; ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		DisplayOrder = 998; IgnoreGuiInset = true;
		Parent = lp:WaitForChild("PlayerGui");
	})
	local floatBtn = mk("TextButton", {
		Size = UDim2.fromOffset(50, 50); Position = UDim2.new(0, 14, 0.5, -25);
		BackgroundColor3 = theme.Sidebar; Text = "";
		AutoButtonColor = false; Visible = false; ZIndex = 10; Parent = floatGui;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 14) }),
		mk("UIStroke", { Color = theme.Accent; Thickness = 1.5 }),
	})
	tagBg(floatBtn, "sidebar")
	local floatIco = mkIcon(floatBtn, "menu", 22, theme.Accent, 11)
	if floatIco then
		floatIco.AnchorPoint = Vector2.new(0.5, 0.5)
		floatIco.Position = UDim2.fromScale(0.5, 0.5)
		tagIcon(floatIco, "accent")
	end

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
	-- WINDOW CONTROLS & DRAG
	-- ════════════════════════════════════════════════════════════════════════
	function win:Close()
		if not win._visible then return end
		win._visible = false
		sg.Enabled = false
		if isMobile then floatBtn.Visible = true end
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

	-- Window Dragging via Header & Brand Box
	local dragging, dragStart, startPos
	local function bindDrag(frame)
		frame.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; dragStart = i.Position; startPos = main.Position
				i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
			end
		end)
	end
	bindDrag(headerBg)
	bindDrag(brandBox)

	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	-- Resize Handle
	local resizing, rStart, rSize = false, nil, nil
	local rHandle = mk("TextButton", {
		Size = UDim2.fromOffset(18, 18); Position = UDim2.new(1, -18, 1, -18);
		BackgroundTransparency = 1; Text = ""; AutoButtonColor = false;
		ZIndex = 10; Parent = bgFrame;
	})
	for i = 0, 2 do
		mk("Frame", {
			Size = UDim2.fromOffset(6, 1.5);
			Position = UDim2.new(1, -3-(i*3.5), 1, -3-(i*3.5));
			BackgroundColor3 = theme.TextDim; BackgroundTransparency = 0.4;
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
			local nw = math.max(540, rSize.X.Offset + d.X/cs)
			local nh = math.max(380, rSize.Y.Offset + d.Y/cs)
			main.Size = UDim2.new(0, nw, 0, nh)
			content.Size = UDim2.new(1, -(SIDEBAR_W + 6) - 12, 1, -CONTENT_Y - 12)
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
	-- WELCOME MODAL (REMOVED - DIRECT MAIN UI ACCESS)
	-- ════════════════════════════════════════════════════════════════════════
	function win:DismissWelcome() end

	-- ════════════════════════════════════════════════════════════════════════
	-- TABS — UNIQUE SIDEBAR TABS WITH PROMINENT ICON TILES
	-- ════════════════════════════════════════════════════════════════════════
	function win:Tab(cfg)
		cfg = cfg or {}
		local tabName = cfg.Title or cfg.Name or "Tab"
		local tabIconName = cfg.Icon or "folder"
		local tab = { Name = tabName; _layoutOrder = 0; _page = content; _win = win }
		local idx = #win._tabs + 1

		-- Sidebar Tab Button (Sleek Item Card)
		local btn = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 42);
			BackgroundColor3 = theme.Card;
			BackgroundTransparency = 1;
			Text = ""; AutoButtonColor = false;
			LayoutOrder = idx; ZIndex = 12; Parent = tabList;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })

		-- Active Indicator Pill (Left edge)
		local indicator = tagBg(mk("Frame", {
			Size = UDim2.new(0, 3.5, 0, 22); Position = UDim2.new(0, 0, 0.5, -11);
			BackgroundColor3 = theme.Accent; BorderSizePixel = 0;
			BackgroundTransparency = 1; ZIndex = 14; Parent = btn;
		}), "accent")
		mk("UICorner", { CornerRadius = UDim.new(0, 2); Parent = indicator })

		-- Icon Tile Box (Bold 30x30 container)
		local iconBox = tagBg(mk("Frame", {
			Size = UDim2.fromOffset(30, 30); Position = UDim2.new(0, 8, 0.5, -15);
			BackgroundColor3 = theme.Elevated;
			BorderSizePixel = 0; ZIndex = 13; Parent = btn;
		}), "elevated")
		mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = iconBox })

		-- Clear Icon (20px size)
		local tIco = mkIcon(iconBox, tabIconName, 18, theme.TextSub, 14)
		if tIco then
			tIco.AnchorPoint = Vector2.new(0.5, 0.5)
			tIco.Position = UDim2.fromScale(0.5, 0.5)
			tagIcon(tIco, "textsub")
		end

		-- Tab Title
		local tLabel = tagText(mk("TextLabel", {
			Size = UDim2.new(1, -78, 1, 0); Position = UDim2.fromOffset(46, 0);
			BackgroundTransparency = 1; Text = tabName;
			Font = Enum.Font.GothamMedium; TextSize = 12;
			TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 13; Parent = btn;
		}), "textsub")

		-- Badge Counter Pill
		local countBadge = mk("TextLabel", {
			Size = UDim2.fromOffset(20, 16); Position = UDim2.new(1, -26, 0.5, -8);
			BackgroundColor3 = theme.Elevated; BackgroundTransparency = 0.5;
			BorderSizePixel = 0; Text = "0"; Font = Enum.Font.GothamBold; TextSize = 9;
			TextColor3 = theme.TextDim; ZIndex = 13; Parent = btn;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 6) }) })

		local isActive = false
		local function setActive(active)
			isActive = active
			if active then
				tw(btn, 0.2, { BackgroundTransparency = 0, BackgroundColor3 = win._theme.Card })
				tw(indicator, 0.2, { BackgroundTransparency = 0 })
				tw(iconBox, 0.2, { BackgroundColor3 = win._theme.Accent, BackgroundTransparency = 0 })
				tw(tLabel, 0.15, { TextColor3 = win._theme.Text, Font = Enum.Font.GothamBold })
				if tIco then tw(tIco, 0.15, { ImageColor3 = Color3.fromRGB(10, 10, 14) }) end
				
				-- Update Header Display
				headerTitleLabel.Text = tabName
				if headerTabIcon then
					local asset = getIcon(tabIconName)
					if asset then headerTabIcon.Image = asset end
				end
			else
				tw(btn, 0.2, { BackgroundTransparency = 1 })
				tw(indicator, 0.2, { BackgroundTransparency = 1 })
				tw(iconBox, 0.2, { BackgroundColor3 = win._theme.Elevated, BackgroundTransparency = 0 })
				tw(tLabel, 0.15, { TextColor3 = win._theme.TextSub, Font = Enum.Font.GothamMedium })
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
				tw(btn, 0.12, { BackgroundTransparency = 0.5, BackgroundColor3 = win._theme.Card })
				tw(iconBox, 0.12, { BackgroundColor3 = win._theme.Border })
			end
		end)
		btn.MouseLeave:Connect(function()
			if not isActive then
				tw(btn, 0.12, { BackgroundTransparency = 1 })
				tw(iconBox, 0.12, { BackgroundColor3 = win._theme.Elevated })
			end
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
					local cCount = 0
					for _, entry in ipairs(win._allComps) do
						if entry._tab == tab then cCount = cCount + 1 end
					end
					countBadge.Text = tostring(cCount)
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

local function th(tab)
	if tab._win then return tab._win._theme end
	return Library.Themes[Library._lastTheme or "Default"] or Library.Themes.Default
end

local function nextOrder(tab)
	tab._layoutOrder = (tab._layoutOrder or 0) + 1
	return tab._layoutOrder
end

-- ════════════════════════════════════════════════════════════════════════════
-- COMPONENTS — CARD CONTAINERS WITH BOLD ICON ACCENTS
-- ════════════════════════════════════════════════════════════════════════════

-- ── Section ──
function Section(tab, data)
	local label = getLabel(data)
	local theme = th(tab)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 32); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})

	-- Glowing Dot / Icon Accent
	local sIcoName = data.SectionIcon or "layers"
	local sIco = mkIcon(f, sIcoName, 14, theme.Accent, 2)
	local lx = 0
	if sIco then
		sIco.Position = UDim2.fromOffset(2, 8)
		tagIcon(sIco, "accent")
		lx = 22
	end

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -lx, 0, 16); Position = UDim2.fromOffset(lx, 6);
		BackgroundTransparency = 1; Text = label:upper();
		Font = Enum.Font.GothamBold; TextSize = 11; TextColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "textsub")
	
	-- Horizontal underline
	tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 1); Position = UDim2.new(0, 0, 1, -2);
		BackgroundColor3 = theme.BorderSub; BorderSizePixel = 0; Parent = f;
	}), "bordersub")

	return { Frame = f }
end

-- ── Paragraph ──
function Paragraph(tab, data)
	local theme = th(tab)
	local label = getLabel(data)
	local hasTitle = data.Title and data.Title ~= ""
	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, hasTitle and 48 or 34);
		BackgroundColor3 = theme.Card; BorderSizePixel = 0;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })
	tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = f }), "bordersub")

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14)
	pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = f

	if hasTitle then
		tagText(mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14); BackgroundTransparency = 1;
			Text = label; Font = Enum.Font.GothamBold; TextSize = 11;
			TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
		}), "textsub")
	end
	local cl = tagText(mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16); Position = UDim2.fromOffset(0, hasTitle and 16 or 0);
		BackgroundTransparency = 1; Text = data.Content or "";
		Font = Enum.Font.GothamMedium; TextSize = 11; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; TextWrapped = true; Parent = f;
	}), "text")
	local api = { Frame = f; Name = data.Title or "Paragraph" }
	function api:Set(t) cl.Text = t end
	function api:Get() return cl.Text end
	return api
end

-- ── Toggle (Card with Left Icon & Pill Switch) ──
function Toggle(tab, data)
	local label = getLabel(data)
	local theme = th(tab)
	local val = data.Value ~= nil and data.Value or (data.Default ~= nil and data.Default or false)

	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 44); BackgroundColor3 = theme.Card;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })
	tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = f }), "bordersub")

	-- Optional Component Icon
	local tIco = nil; local lx = 14
	if data.Icon then
		tIco = mkIcon(f, data.Icon, 16, val and theme.Accent or theme.TextDim, 2)
		if tIco then tIco.Position = UDim2.new(0, 14, 0.5, -8); lx = 38 end
	end

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -(lx + 60), 1, 0); Position = UDim2.fromOffset(lx, 0);
		BackgroundTransparency = 1; Text = label;
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "text")

	-- Switch Pill
	local track = mk("Frame", {
		Size = UDim2.fromOffset(42, 22); Position = UDim2.new(1, -54, 0.5, -11);
		BackgroundColor3 = val and theme.Accent or theme.Border;
		BorderSizePixel = 0; Parent = f;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 11); Parent = track })

	local knob = mk("Frame", {
		Size = UDim2.fromOffset(16, 16);
		Position = val and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8);
		BackgroundColor3 = Color3.fromRGB(255,255,255); BorderSizePixel = 0; Parent = track;
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0); Parent = knob })

	local api = { Value = val; Frame = f; Name = data.Title or data.Name or "Toggle"; Callback = data.Callback }
	function api:Set(v)
		v = not not v
		if self.Value == v then return end
		self.Value = v
		tw(track, 0.2, { BackgroundColor3 = v and theme.Accent or theme.Border }, Enum.EasingStyle.Back)
		tw(knob, 0.2, { Position = v and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, Enum.EasingStyle.Back)
		if tIco then tw(tIco, 0.15, { ImageColor3 = v and theme.Accent or theme.TextDim }) end
		if self.Callback then pcall(self.Callback, v) end
	end
	function api:Get() return self.Value end

	local btn = mk("TextButton", { Size = UDim2.fromScale(1,1); BackgroundTransparency = 1; Text = ""; Parent = f })
	btn.MouseButton1Click:Connect(function() api:Set(not api.Value) end)
	btn.MouseEnter:Connect(function() tw(f, 0.1, { BackgroundColor3 = theme.Elevated }) end)
	btn.MouseLeave:Connect(function() tw(f, 0.1, { BackgroundColor3 = theme.Card }) end)

	reg(data, api); attachTooltip(api, data.Tooltip)
	return api
end

-- ── Slider ──
function Slider(tab, data)
	local theme = th(tab)
	local mn = (data.Value and data.Value.Min) or 0
	local mx = (data.Value and data.Value.Max) or 100
	local df = (data.Value and data.Value.Default) or mn
	local step = data.Step or 1
	local cur = df

	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 54); BackgroundColor3 = theme.Card;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })
	tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = f }), "bordersub")

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -84, 0, 14); Position = UDim2.fromOffset(14, 8);
		BackgroundTransparency = 1; Text = getLabel(data);
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "text")

	-- Value Numeric Box
	local valLbl = mk("TextBox", {
		Size = UDim2.new(0, 54, 0, 22); Position = UDim2.new(1, -68, 0, 4);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = tostring(df); Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.Accent; TextXAlignment = Enum.TextXAlignment.Center; Parent = f;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 6); Parent = valLbl })
	tagBg(valLbl, "elevated"); tagText(valLbl, "accent")

	-- Slider Track
	local trk = mk("Frame", {
		Size = UDim2.new(1, -28, 0, 8); Position = UDim2.new(0, 14, 0, 34);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; Parent = f;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 4); Parent = trk })
	tagBg(trk, "border")

	local fill = mk("Frame", {
		Size = UDim2.new((df-mn)/math.max(mx-mn,1), 0, 1, 0);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; Parent = trk;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 4); Parent = fill })
	tagBg(fill, "accent")

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

-- ── Dropdown ──
function Dropdown(tab, data)
	local theme = th(tab)
	local vals = data.Values or {}
	local cur = data.Value or (vals[1] or "")
	if type(cur) == "number" and vals[cur] then cur = vals[cur] end
	local open = false; local searchTerm = ""
	local CLOSED_H = 56; local ITEM_H = 28; local SEARCH_H = 32; local MAX_VIS = 6

	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, CLOSED_H); BackgroundColor3 = theme.Card;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })
	tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = f }), "bordersub")

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -28, 0, 12); Position = UDim2.fromOffset(14, 6);
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

	local chev = mkIcon(box, "chevron-down", 14, theme.Accent, 3)
	if chev then chev.AnchorPoint = Vector2.new(1, 0.5); chev.Position = UDim2.new(1, -8, 0.5, 0); tagIcon(chev, "accent") end

	local sFrame = mk("Frame", {
		Size = UDim2.new(1, -28, 0, 26); Position = UDim2.fromOffset(14, 54);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Visible = false; ZIndex = 3; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 6) }) })
	tagBg(sFrame, "elevated")
	local sIco = mkIcon(sFrame, "search", 12, theme.TextDim, 4)
	if sIco then sIco.Position = UDim2.new(0, 7, 0.5, -6) end
	local searchBox = mk("TextBox", {
		Size = UDim2.new(1, -(sIco and 26 or 10), 1, 0);
		Position = UDim2.fromOffset(sIco and 24 or 6, 0);
		BackgroundTransparency = 1; PlaceholderText = "Search..."; PlaceholderColor3 = theme.TextDim;
		Text = ""; Font = Enum.Font.GothamMedium; TextSize = 10;
		TextColor3 = theme.Text; ClearTextOnFocus = true;
		TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 4; Parent = sFrame;
	})
	tagText(searchBox, "text")

	local scroll = mk("ScrollingFrame", {
		Size = UDim2.new(1, -28, 0, 0); Position = UDim2.fromOffset(14, 84);
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
				local ck = mkIcon(item, "check", 12, theme.Accent, 5)
				if ck then ck.AnchorPoint = Vector2.new(1, 0.5); ck.Position = UDim2.new(1, -6, 0.5, 0); tagIcon(ck, "accent") end
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
		Size = UDim2.new(1, 0, 0, 38); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	local bgC, txC, brC, brT
	if style == "Primary" then bgC = theme.Accent; txC = Color3.fromRGB(10,10,14); brC = theme.Accent; brT = 0
	elseif style == "Outline" then bgC = Color3.new(); txC = theme.Accent; brC = theme.Accent; brT = 1
	elseif style == "Danger" then bgC = Color3.fromRGB(235,65,80); txC = Color3.fromRGB(255,255,255); brC = bgC; brT = 0
	elseif style == "Ghost" then bgC = Color3.new(); txC = theme.Text; brC = Color3.new(); brT = 0
	else bgC = theme.Card; txC = theme.Text; brC = theme.BorderSub; brT = 1 end

	local btn = mk("TextButton", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = bgC;
		BackgroundTransparency = (style == "Outline" or style == "Ghost") and 1 or 0;
		BorderSizePixel = 0; Text = getLabel(data);
		Font = Enum.Font.GothamBold; TextSize = 12; TextColor3 = txC;
		AutoButtonColor = false; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	mk("UIStroke", { Color = brC; Thickness = brT; Parent = btn })

	btn.MouseEnter:Connect(function()
		if style == "Primary" then tw(btn, 0.1, { BackgroundColor3 = theme.Accent:Lerp(Color3.fromRGB(255,255,255), 0.15) })
		elseif style == "Outline" then tw(btn, 0.1, { BackgroundColor3 = theme.Accent; BackgroundTransparency = 0.88 })
		elseif style == "Danger" then tw(btn, 0.1, { BackgroundColor3 = Color3.fromRGB(255,90,100) })
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
		Size = UDim2.new(1, 0, 0, 42); BackgroundColor3 = theme.Card;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = f })
	tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = f }), "bordersub")

	local kIco = mkIcon(f, "keyboard", 16, theme.Accent, 1)
	if kIco then kIco.Position = UDim2.new(0, 14, 0.5, -8); tagIcon(kIco, "accent") end

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -114, 1, 0); Position = UDim2.fromOffset(38, 0);
		BackgroundTransparency = 1; Text = getLabel(data);
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "text")

	local kbtn = tagBg(mk("TextButton", {
		Size = UDim2.fromOffset(78, 26); Position = UDim2.new(1, -90, 0.5, -13);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = tostring(cur); Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.Accent; AutoButtonColor = false; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 7) }) }), "elevated")
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
	tagBorder(mk("UIStroke", { Color = theme.BorderSub; Thickness = 1; Parent = f }), "bordersub")

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -28, 0, 12); Position = UDim2.fromOffset(14, 6);
		BackgroundTransparency = 1; Text = getLabel(data);
		Font = Enum.Font.GothamBold; TextSize = 10; TextColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "textsub")

	local stroke = tagBorder(mk("UIStroke", { Color = theme.Border; Thickness = 1 }), "border")
	local tb = tagBg(mk("TextBox", {
		Size = UDim2.new(1, -28, 0, 26); Position = UDim2.fromOffset(14, 22);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		PlaceholderText = data.Placeholder or ""; Text = data.Value or "";
		Font = Enum.Font.GothamMedium; TextSize = 11; TextColor3 = theme.Text;
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
-- NOTIFICATION TOASTS
-- ════════════════════════════════════════════════════════════════════════════
function Library:Notify(cfg)
	cfg = cfg or {}
	local title = cfg.Title or ""; local text = cfg.Content or cfg.Text or ""
	local dur = cfg.Duration or 2; local nIcon = cfg.Icon or "bell"
	local theme = self.Themes[self._lastTheme or "Default"] or self.Themes.Default

	local n = mk("Frame", {
		Size = UDim2.new(0, 310, 0, 68);
		Position = UDim2.new(1, 330, 0, 16 + #activeNotifs * 76);
		BackgroundColor3 = theme.Sidebar; BorderSizePixel = 0;
		ClipsDescendants = true; ZIndex = 1000; Parent = notifGui;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	tagBorder(mk("UIStroke", { Color = theme.Border; Thickness = 1; ZIndex = 1000; Parent = n }), "border")

	-- Icon Tile Box
	local nIcoTile = tagBg(mk("Frame", {
		Size = UDim2.fromOffset(36, 36); Position = UDim2.fromOffset(12, 16);
		BackgroundColor3 = theme.Card; BorderSizePixel = 0;
		ZIndex = 1001; Parent = n;
	}), "card")
	mk("UICorner", { CornerRadius = UDim.new(0, 9); Parent = nIcoTile })

	local nIco = mkIcon(nIcoTile, nIcon, 20, theme.Accent, 1002)
	if nIco then
		nIco.AnchorPoint = Vector2.new(0.5, 0.5)
		nIco.Position = UDim2.fromScale(0.5, 0.5)
		tagIcon(nIco, "accent")
	end

	local cx = 58
	if title ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(1, -(cx + 12), 0, 18); Position = UDim2.fromOffset(cx, 14);
			BackgroundTransparency = 1; Text = title;
			Font = Enum.Font.GothamBold; TextSize = 13; TextColor3 = theme.Text;
			TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 1001; Parent = n;
		})
	end
	if text ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(1, -(cx + 12), 0, 16); Position = UDim2.fromOffset(cx, title ~= "" and 34 or 18);
			BackgroundTransparency = 1; Text = text;
			Font = Enum.Font.GothamMedium; TextSize = 11; TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Left; TextWrapped = true; ZIndex = 1001; Parent = n;
		})
	end

	-- Countdown Bar
	local pBar = mk("Frame", {
		Size = UDim2.new(1, -16, 0, 2.5); Position = UDim2.new(0, 8, 1, -6);
		BackgroundColor3 = theme.BorderSub; BorderSizePixel = 0; ZIndex = 1001; Parent = n;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 1) }) })
	local pFill = tagBg(mk("Frame", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = theme.Accent;
		BorderSizePixel = 0; ZIndex = 1002; Parent = pBar;
	}), "accent")
	mk("UICorner", { CornerRadius = UDim.new(0, 1); Parent = pFill })

	activeNotifs[#activeNotifs + 1] = n
	tw(n, 0.25, { Position = UDim2.new(1, -326, 0, 16 + (#activeNotifs-1) * 76) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tw(pFill, dur, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)

	task.delay(dur, function()
		tw(n, 0.2, { Position = UDim2.new(1, 330, 0, n.Position.Y.Offset); BackgroundTransparency = 1 })
		task.wait(0.25)
		for i, v in ipairs(activeNotifs) do if v == n then table.remove(activeNotifs, i); break end end
		for i, v in ipairs(activeNotifs) do tw(v, 0.15, { Position = UDim2.new(1, -326, 0, 16 + (i-1) * 76) }) end
		task.wait(0.15); pcall(function() n:Destroy() end)
	end)
end

return Library
