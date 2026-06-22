-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Leon X  |  Noir UI Library v4                                 ║
-- ║  "Cinematic darkness — where light is earned, not given."      ║
-- ╚══════════════════════════════════════════════════════════════════╝

print("[LeonX-LIB] ████ NOIR-UI-V4 ████")

local Library = {}
Library.Registry = {}
Library._allComponents = {}
Library._windows = {}

-- ════════════════════════════════════════════════════════════════════════════
-- THEMES — deep, cinematic palettes (NOT just accent color swaps)
-- ════════════════════════════════════════════════════════════════════════════

local function mkTheme(accent, accentDim, glowTint)
	return {
		BG        = Color3.fromRGB(10, 10, 12),
		Surface   = Color3.fromRGB(18, 18, 22),
		Elevated  = Color3.fromRGB(26, 26, 32),
		Border    = Color3.fromRGB(38, 38, 44),
		BorderSub = Color3.fromRGB(28, 28, 34),
		Text      = Color3.fromRGB(232, 232, 238),
		TextSub   = Color3.fromRGB(110, 110, 125),
		TextDim   = Color3.fromRGB(70, 70, 82),
		Accent    = Color3.fromRGB(table.unpack(accent)),
		AccentDim = Color3.fromRGB(table.unpack(accentDim)),
		Glow      = Color3.fromRGB(table.unpack(glowTint or accent)),
	}
end

Library.Themes = {
	Default = mkTheme({130,155,210}, {80,100,150}, {100,130,200}),
	Gold    = mkTheme({210,185,110}, {155,130,75},  {200,170,90}),
	Emerald = mkTheme({100,195,135}, {60,140,90},   {80,180,120}),
	Rose    = mkTheme({215,125,148}, {160,80,100},  {200,110,135}),
	Violet  = mkTheme({155,125,225}, {105,80,165},  {140,110,210}),
	Amber   = mkTheme({225,175,75},  {170,125,45},  {210,160,60}),
	Neon    = mkTheme({80,225,185},  {50,170,135},  {70,210,170}),
}

-- Glassmorphism transparency settings (subtle blur effect)
local GLASS_TRANSPARENCY = {
	Window = 0.15,      -- Main window background
	Sidebar = 0.25,     -- Sidebar panel
	Surface = 0.15,     -- Component surfaces (toggles, sliders, etc)
	Elevated = 0.25,    -- Elevated elements (buttons, inputs)
}

-- ════════════════════════════════════════════════════════════════════════════
-- CORE UTILITIES
-- ════════════════════════════════════════════════════════════════════════════

local TS      = game:GetService("TweenService")
local UIS     = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

local function mk(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	return inst
end

local function tw(obj, dur, props, style, dir)
	local info = TweenInfo.new(
		dur,
		style or Enum.EasingStyle.Quad,
		dir or Enum.EasingDirection.Out
	)
	local t = TS:Create(obj, info, props)
	t:Play(); return t
end

-- ── Theme-aware instance tagging ──
-- Every visual element gets a "_role" attribute so theme changes
-- can find and update them without tracking each one manually.
local ROLE_COLORS = {
	bg        = "BG",
	surface   = "Surface",
	elevated  = "Elevated",
	border    = "Border",
	bordersub = "BorderSub",
	text      = "Text",
	textsub   = "TextSub",
	textdim   = "TextDim",
	accent    = "Accent",
	accentdim = "AccentDim",
	glow      = "Glow",
}

local function tag(inst, role, accentSub)
	if not role then return inst end
	inst:SetAttribute("_role", role)
	if accentSub then
		inst:SetAttribute("_accentSub", accentSub)
	end
	return inst
end

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

-- Apply theme colors to a tagged instance
local function applyTheme(inst, theme)
	local role = inst:GetAttribute("_role")
	if not role then return end
	local color = ROLE_COLORS[role] and theme[ROLE_COLORS[role]]
	if not color then return end
	if inst:GetAttribute("_isText") then
		inst.TextColor3 = color
	elseif inst:GetAttribute("_isStroke") then
		inst.Color = color
	elseif inst:GetAttribute("_isBg") then
		inst.BackgroundColor3 = color
	end
end

-- Update ALL tagged descendants of a frame
local function retagAll(frame, theme)
	for _, inst in ipairs(frame:GetDescendants()) do
		if inst:GetAttribute("_role") then
			applyTheme(inst, theme)
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- LABEL / REGISTRY HELPERS
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

-- ════════════════════════════════════════════════════════════════════════════
-- TOOLTIP SYSTEM
-- ════════════════════════════════════════════════════════════════════════════

local function attachTooltip(component, text)
	if not text or text == "" then return end

	local tooltip = nil
	local tooltipLabel = nil

	local function createTooltip()
		if tooltip then return end

		tooltip = mk("Frame", {
			Name = "Tooltip";
			Size = UDim2.fromOffset(200, 40);
			BackgroundColor3 = Color3.fromRGB(20, 20, 20);
			BorderSizePixel = 0;
			ZIndex = 100;
			Visible = false;
			Parent = game:GetService("CoreGui");
		})
		mk("UICorner", { CornerRadius = UDim.new(0, 6); Parent = tooltip })

		tooltipLabel = mk("TextLabel", {
			Name = "Label";
			Size = UDim2.new(1, -16, 1, 0);
			Position = UDim2.new(0, 8, 0, 0);
			BackgroundTransparency = 1;
			Text = text;
			TextColor3 = Color3.fromRGB(220, 220, 220);
			TextSize = 12;
			Font = Enum.Font.Gotham;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextWrapped = true;
			ZIndex = 101;
			Parent = tooltip;
		})
	end

	local frame = component.Frame
	if not frame then return end

	frame.MouseEnter:Connect(function()
		createTooltip()
		if tooltip then
			tooltip.Visible = true
		end
	end)

	frame.MouseMoved:Connect(function(x, y)
		if tooltip then
			tooltip.Position = UDim2.fromOffset(x + 15, y + 15)
		end
	end)

	frame.MouseLeave:Connect(function()
		if tooltip then
			tooltip.Visible = false
		end
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM (separate ScreenGui, always on top)
-- ════════════════════════════════════════════════════════════════════════════

local notifGui = mk("ScreenGui", {
	Name = "LeonXNotif"; ResetOnSpawn = false;
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	DisplayOrder = 10000; IgnoreGuiInset = true;
})
pcall(function() notifGui.Parent = lp:WaitForChild("PlayerGui") end)
local activeNotifs = {}

-- ════════════════════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ════════════════════════════════════════════════════════════════════════════

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title     = cfg.Title or "Leon X"
	local author    = cfg.Author or ""
	local size      = cfg.Size or UDim2.new(0, 660, 0, 580)
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.U
	local themeName = cfg.Theme or "Default"
	local theme     = Library.Themes[themeName] or Library.Themes.Default

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

	-- ── Main frame ──
	local main = mk("Frame", {
		Size = size;
		Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2);
		BackgroundTransparency = 1;
		BorderSizePixel = 0; ClipsDescendants = true;
		Active = false; -- Don't block input, let children handle it
		Parent = sg;
	})

	-- ── Background layer (glassmorphism bg, tagged for theme) ──
	local bgFrame = tagBg(mk("Frame", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = theme.BG;
		BackgroundTransparency = GLASS_TRANSPARENCY.Window;
		BorderSizePixel = 0; ZIndex = 1; Active = false; Parent = main;
	}), "bg")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = bgFrame })

	-- ── Main border stroke ──
	local mainStroke = tagBorder(mk("UIStroke", {
		Color = theme.Border; Thickness = 1; Parent = bgFrame;
	}), "border")

	-- ── Signature: Ambient glow frame (pulses subtly) ──
	local glowFrame = tagBg(mk("Frame", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = theme.Glow;
		BackgroundTransparency = 0.97; BorderSizePixel = 0;
		ZIndex = 2; Active = false; Parent = main;
	}), "glow")
	mk("UICorner", { CornerRadius = UDim.new(0, 10); Parent = glowFrame })


	-- ── Noir vignette (subtle darkening at edges) ──
	-- Top vignette
	local vigTop = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 60); Position = UDim2.fromOffset(0, 0);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ZIndex = 3; Active = false; Parent = main;
	})
	local vigTopGrad = mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 90;
		Parent = vigTop;
	})
	-- Bottom vignette
	local vigBot = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 60); Position = UDim2.new(0, 0, 1, -60);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ZIndex = 3; Active = false; Parent = main;
	})
	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0.6),
		}),
		Rotation = 90;
		Parent = vigBot;
	})

	-- ══════════════════════════════════════════════════════════════
	-- SIDEBAR — dark glass with accent glow edge
	-- ══════════════════════════════════════════════════════════════
	local SIDEBAR_W = 148
	local sidebarBg = mk("Frame", {
		Size = UDim2.new(0, SIDEBAR_W, 1, 0); Position = UDim2.fromOffset(0, 0);
		BackgroundColor3 = Color3.fromRGB(8, 8, 10);
		BackgroundTransparency = GLASS_TRANSPARENCY.Sidebar;
		BorderSizePixel = 0; ZIndex = 5;
		ClipsDescendants = true; Active = false; Parent = main;
	})

	-- Sidebar gradient overlay (top-to-bottom dark wash)
	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.Surface),
			ColorSequenceKeypoint.new(0.4, theme.BG),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 8)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(0.4, 0.3),
			NumberSequenceKeypoint.new(1, 0.1),
		}),
		Rotation = 180;
		Parent = sidebarBg;
	})

	-- Sidebar border line (subtle)
	tagBg(mk("Frame", {
		Size = UDim2.new(0, 1, 1, 0); Position = UDim2.new(1, 0, 0, 0);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; ZIndex = 6; Parent = sidebarBg;
	}), "border")

	-- ── Logo area ──
	-- Logo accent dot (static circle before text)
	local logoDot = tagBg(mk("Frame", {
		Size = UDim2.fromOffset(8, 8); Position = UDim2.fromOffset(16, 22);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0;
		ZIndex = 7; Parent = sidebarBg;
	}), "accent")
	mk("UICorner", { CornerRadius = UDim.new(1, 0); Parent = logoDot })

	-- Logo text
	local logo = tagText(mk("TextLabel", {
		Size = UDim2.new(1, -34, 0, 52); Position = UDim2.fromOffset(30, 0);
		BackgroundTransparency = 1; Text = "Leon X";
		Font = Enum.Font.GothamBold; TextSize = 18;
		TextColor3 = theme.Accent; TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 7; Parent = sidebarBg;
	}), "accent")

	-- Version label under logo
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -34, 0, 14); Position = UDim2.fromOffset(30, 32);
		BackgroundTransparency = 1; Text = "v1.6";
		Font = Enum.Font.Gotham; TextSize = 10;
		TextColor3 = theme.TextDim; TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 7; Parent = sidebarBg;
	}), "textdim")

	-- Thin divider line under logo area
	tagBg(mk("Frame", {
		Size = UDim2.new(1, -28, 0, 1); Position = UDim2.fromOffset(14, 52);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0;
		BackgroundTransparency = 0.5; ZIndex = 6; Parent = sidebarBg;
	}), "border")

	-- ══════════════════════════════════════════════════════════════
	-- HEADER
	-- ══════════════════════════════════════════════════════════════
	local headerBg = tagBg(mk("Frame", {
		Size = UDim2.new(1, -SIDEBAR_W, 0, 44); Position = UDim2.fromOffset(SIDEBAR_W, 0);
		BackgroundColor3 = theme.Surface; BorderSizePixel = 0; ZIndex = 5;
		Active = true; Parent = main; -- Header needs Active=true for dragging
	}), "surface")

	-- Header bottom border
	tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 1); Position = UDim2.new(0, 0, 1, -1);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; ZIndex = 6; Parent = headerBg;
	}), "border")

	-- ── Signature: Accent beam under header (animated shimmer) ──
	local beamTrack = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 2); Position = UDim2.new(0, 0, 1, -2);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; ZIndex = 7; Parent = headerBg;
	}), "border")

	local beamFill = tagBg(mk("Frame", {
		Size = UDim2.new(0, 60, 1, 0); Position = UDim2.fromOffset(-60, 0);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; ZIndex = 8; Parent = beamTrack;
	}), "accent")

	-- Beam shimmer animation
	task.spawn(function()
		while beamFill and beamFill.Parent do
			beamFill.Position = UDim2.fromOffset(-60, 0)
			beamFill.BackgroundTransparency = 0
			tw(beamFill, 4, { Position = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Linear)
			task.wait(4.2)
			tw(beamFill, 0, { BackgroundTransparency = 1 })
			task.wait(2)
			tw(beamFill, 0, { BackgroundTransparency = 0 })
			task.wait(0.5)
		end
	end)

	-- Header title
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -110, 1, 0); Position = UDim2.fromOffset(18, 0);
		BackgroundTransparency = 1; Text = title;
		Font = Enum.Font.GothamBold; TextSize = 15;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 7; Parent = headerBg;
	}), "text")

	if author ~= "" then
		tagText(mk("TextLabel", {
			Size = UDim2.new(0, 120, 1, 0); Position = UDim2.new(1, -140, 0, 0);
			BackgroundTransparency = 1; Text = author;
			Font = Enum.Font.Gotham; TextSize = 11;
			TextColor3 = theme.TextDim; TextXAlignment = Enum.TextXAlignment.Right;
			ZIndex = 7; Parent = headerBg;
		}), "textdim")
	end

	-- ── Header buttons (icon-based, no unicode) ──
	local function headerBtn(xPos)
		local b = mk("TextButton", {
			Size = UDim2.fromOffset(34, 34); Position = UDim2.new(1, xPos, 0.5, -17);
			BackgroundColor3 = theme.Surface; BackgroundTransparency = 1;
			Text = ""; AutoButtonColor = false;
			ZIndex = 15; Parent = headerBg;
		}, {
			mk("UICorner", { CornerRadius = UDim.new(0, 7) }),
			mk("UIStroke", { Color = theme.Border; Thickness = 1; ZIndex = 15 }),
		})
		tagBorder(b:FindFirstChildWhichIsA("UIStroke"), "border")
		b.MouseEnter:Connect(function()
			b.BackgroundTransparency = 0
			b.BackgroundColor3 = theme.Elevated
		end)
		b.MouseLeave:Connect(function()
			b.BackgroundTransparency = 1
		end)
		return b
	end

	-- Minimize button (horizontal line icon)
	local minBtn = headerBtn(-78)
	mk("Frame", {
		Size = UDim2.fromOffset(14, 2); Position = UDim2.new(0.5, -7, 0.5, -1);
		BackgroundColor3 = theme.TextSub; BorderSizePixel = 0;
		ZIndex = 16; Active = false; Parent = minBtn;
	})

	-- Close button (X icon from 2 diagonal bars)
	local closeBtn = headerBtn(-40)
	mk("Frame", {
		Size = UDim2.fromOffset(14, 2); Position = UDim2.new(0.5, -7, 0.5, -1);
		BackgroundColor3 = theme.TextSub; BorderSizePixel = 0;
		Rotation = 45; ZIndex = 16; Active = false; Parent = closeBtn;
	})
	mk("Frame", {
		Size = UDim2.fromOffset(14, 2); Position = UDim2.new(0.5, -7, 0.5, -1);
		BackgroundColor3 = theme.TextSub; BorderSizePixel = 0;
		Rotation = -45; ZIndex = 16; Active = false; Parent = closeBtn;
	})

	local minContentVisible = true
	minBtn.MouseButton1Click:Connect(function()
		minContentVisible = not minContentVisible
		if minContentVisible then
			win:Open()
		else
			win:Close()
		end
	end)

	-- ══════════════════════════════════════════════════════════════
	-- CONTENT AREA
	-- ══════════════════════════════════════════════════════════════
	local content = mk("ScrollingFrame", {
		Size = UDim2.new(1, -SIDEBAR_W, 1, -44); Position = UDim2.fromOffset(SIDEBAR_W, 44);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 4; ScrollBarImageColor3 = theme.AccentDim;
		CanvasSize = UDim2.fromOffset(0, 0);
		ClipsDescendants = true; ZIndex = 5; Parent = main;
	})
	local contentLayout = mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder; Padding = UDim.new(0, 6); Parent = content;
	})
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 14); PaddingBottom = UDim.new(0, 14);
		PaddingLeft = UDim.new(0, 16); PaddingRight = UDim.new(0, 16);
		Parent = content;
	})
	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		content.CanvasSize = UDim2.fromOffset(0, contentLayout.AbsoluteContentSize.Y + 28)
	end)
	pcall(function() content.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
	win._allComps = {}

	-- ══════════════════════════════════════════════════════════════
	-- FLOATING BUTTON
	-- ══════════════════════════════════════════════════════════════
	local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
	local floatGui = mk("ScreenGui", {
		Name = "LeonXFloat"; ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		DisplayOrder = 998; IgnoreGuiInset = true;
		Parent = lp:WaitForChild("PlayerGui");
	})
	local floatBtn = mk("TextButton", {
		Size = UDim2.fromOffset(56, 56); Position = UDim2.new(0, 16, 0.5, -28);
		BackgroundColor3 = theme.Surface; Text = "";
		AutoButtonColor = false; Visible = false; ZIndex = 10; Parent = floatGui;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1.5 }),
	})
	-- Float button text (simple, no asset loading)
	floatBtn.Text = "⚡"
	floatBtn.Font = Enum.Font.GothamBold
	floatBtn.TextSize = 20
	floatBtn.TextColor3 = theme.Accent
	-- Float button: pulse animation
	task.spawn(function()
		while floatBtn and floatBtn.Parent do
			if floatBtn.Visible then
				tw(floatBtn, 1.5, { Size = UDim2.fromOffset(52, 52) }, Enum.EasingStyle.Sine)
				task.wait(1.5)
				tw(floatBtn, 1.5, { Size = UDim2.fromOffset(48, 48) }, Enum.EasingStyle.Sine)
				task.wait(1.5)
			else
				task.wait(0.5)
			end
		end
	end)

	-- Float button drag + click
	do
		local fDragging, fDragStart, fStartPos, fDidMove = false, nil, nil, false
		local function isTap(i)
			return i.UserInputType == Enum.UserInputType.MouseButton1
				or i.UserInputType == Enum.UserInputType.Touch
		end
		floatBtn.InputBegan:Connect(function(i)
			if isTap(i) then fDragging = true; fDidMove = false; fDragStart = i.Position; fStartPos = floatBtn.Position end
		end)
		UIS.InputChanged:Connect(function(i)
			if fDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - fDragStart
				if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then fDidMove = true end
				floatBtn.Position = UDim2.new(fStartPos.X.Scale, fStartPos.X.Offset + d.X, fStartPos.Y.Scale, fStartPos.Y.Offset + d.Y)
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if isTap(i) and fDragging then fDragging = false; if not fDidMove then win:Open() end end
		end)
	end

	-- ══════════════════════════════════════════════════════════════
	-- CLOSE / OPEN — smooth transitions
	-- ══════════════════════════════════════════════════════════════
	function win:Close()
		if not win._visible then return end
		win._visible = false
		sg.Enabled = false

		-- Show float button only on mobile
		if isMobile then
			floatBtn.Visible = true

			-- Bounce animation on float button
			floatBtn.Size = UDim2.fromOffset(40, 40)
			TS:Create(floatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(56, 56)
			}):Play()
		end
	end

	function win:Open()
		if win._visible then return end
		floatBtn.Visible = false
		sg.Enabled = true
		win._visible = true
	end
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

	-- ── Resize Handle (bottom-right corner) ──
	local resizing, resizeStart, resizeStartSize = false, nil, nil
	local resizeHandle = mk("TextButton", {
		Size = UDim2.fromOffset(20, 20);
		Position = UDim2.new(1, -20, 1, -20);
		BackgroundTransparency = 1;
		Text = "";
		AutoButtonColor = false;
		ZIndex = 10;
		Parent = bgFrame;
	})

	-- Draw diagonal grip lines
	for i = 0, 2 do
		mk("Frame", {
			Size = UDim2.fromOffset(8, 2);
			Position = UDim2.new(1, -3 - (i * 4), 1, -3 - (i * 4));
			BackgroundColor3 = theme.TextDim;
			BackgroundTransparency = 0.4;
			BorderSizePixel = 0;
			Rotation = 45;
			AnchorPoint = Vector2.new(1, 1);
			ZIndex = 11;
			Parent = resizeHandle;
		})
	end

	resizeHandle.MouseEnter:Connect(function()
		for _, line in ipairs(resizeHandle:GetChildren()) do
			if line:IsA("Frame") then
				line.BackgroundTransparency = 0.2
			end
		end
	end)
	resizeHandle.MouseLeave:Connect(function()
		for _, line in ipairs(resizeHandle:GetChildren()) do
			if line:IsA("Frame") then
				line.BackgroundTransparency = 0.4
			end
		end
	end)

	resizeHandle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = i.Position
			resizeStartSize = main.Size
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(i)
		if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - resizeStart
			local newSizeX = math.max(400, resizeStartSize.X.Offset + d.X)
			local newSizeY = math.max(300, resizeStartSize.Y.Offset + d.Y)
			main.Size = UDim2.new(0, newSizeX, 0, newSizeY)
		end
	end)

	-- ══════════════════════════════════════════════════════════════
	-- PUBLIC API
	-- ══════════════════════════════════════════════════════════════
	function win:SetToggleKey(k) win._toggleKey = k end

	function win:SetTheme(name)
		local t = Library.Themes[name]
		if not t then return end
		win._theme = t; win._themeName = name
		Library._lastTheme = name
		-- Update ALL tagged instances across the entire window
		retagAll(main, t)
		retagAll(floatBtn, t)
	end

	-- Toggle key handler — uses `win` not `self`
	UIS.InputBegan:Connect(function(i, gp)
		if gp or i.KeyCode ~= win._toggleKey then return end
		if win._visible then win:Close() else win:Open() end
	end)

	-- ══════════════════════════════════════════════════════════════
	-- WELCOME SCREEN
	-- ══════════════════════════════════════════════════════════════
	local welcomeFrame = mk("Frame", {
		Size = UDim2.fromScale(1, 1); BackgroundColor3 = theme.BG;
		BackgroundTransparency = 0; BorderSizePixel = 0;
		ZIndex = 50; Active = false; Parent = main;
	})
	tagBg(welcomeFrame, "bg")

	local welcomeCard = mk("Frame", {
		Size = UDim2.new(0, 440, 0, 420);
		AnchorPoint = Vector2.new(0.5, 0.5);
		Position = UDim2.fromScale(0.5, 0.5);
		BackgroundColor3 = theme.Surface; BorderSizePixel = 0;
		ZIndex = 51; Parent = welcomeFrame;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 12) }),
	})
	tagBg(welcomeCard, "surface")

	local cardStroke = tagBorder(mk("UIStroke", {
		Color = theme.Border; Thickness = 1; ZIndex = 51; Parent = welcomeCard;
	}), "border")

	-- Card accent glow
	task.spawn(function()
		while cardStroke and cardStroke.Parent do
			tw(cardStroke, 2, { Color = theme.Accent }, Enum.EasingStyle.Sine)
			task.wait(2)
			tw(cardStroke, 2, { Color = theme.Border }, Enum.EasingStyle.Sine)
			task.wait(2)
		end
	end)

	-- Logo
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 40); Position = UDim2.fromOffset(0, 26);
		BackgroundTransparency = 1; Text = "⚡ Leon X";
		Font = Enum.Font.GothamBold; TextSize = 30;
		TextColor3 = theme.Accent; ZIndex = 52; Parent = welcomeCard;
	}), "accent")

	-- Version pill
	local vPill = mk("Frame", {
		Size = UDim2.new(0, 56, 0, 22); Position = UDim2.new(0.5, -28, 0, 68);
		BackgroundColor3 = theme.Accent; BackgroundTransparency = 0.8;
		BorderSizePixel = 0; ZIndex = 52; Parent = welcomeCard;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 11) }) })
	tagBg(vPill, "accent")
	tagText(mk("TextLabel", {
		Size = UDim2.fromScale(1, 1); BackgroundTransparency = 1;
		Text = "v1.6"; Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.Text; ZIndex = 53; Parent = vPill;
	}), "text")

	-- Tagline
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -48, 0, 40); Position = UDim2.fromOffset(24, 98);
		BackgroundTransparency = 1;
		Text = "Welcome to " .. game.Name .. "\nA powerful, modular framework for any game.";
		Font = Enum.Font.Gotham; TextSize = 12; TextColor3 = theme.TextSub;
		TextWrapped = true; ZIndex = 52; Parent = welcomeCard;
	}), "textsub")

	-- Info table
	local infoData = {
		{"Author",      "leonx24"},
		{"Platform",    "Roblox (Universal)"},
		{"Features",    "30+ Modules"},
		{"Categories",  "Movement · Combat · Visual · Auto"},
		{"Executor",    "Any modern executor"},
		{"Config",      "Auto-save & load"},
		{"Mobile",      "Full touch support"},
		{"Status",      "● Active"},
	}
	local tableY = 148
	local tableFrame = mk("Frame", {
		Size = UDim2.new(1, -48, 0, #infoData * 28 + 8);
		Position = UDim2.fromOffset(24, tableY);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		ZIndex = 52; Parent = welcomeCard;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	tagBg(tableFrame, "elevated")

	for i, row in ipairs(infoData) do
		local rowFrame = mk("Frame", {
			Size = UDim2.new(1, -4, 0, 26);
			Position = UDim2.fromOffset(2, 2 + (i-1) * 28);
			BackgroundColor3 = (i % 2 == 0) and theme.Elevated or theme.BG;
			BackgroundTransparency = 0.5;
			BorderSizePixel = 0; ZIndex = 53; Parent = tableFrame;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 4) }) })
		tagBg(rowFrame, (i % 2 == 0) and "elevated" or "bg")

		tagText(mk("TextLabel", {
			Size = UDim2.new(0.38, -8, 1, 0); Position = UDim2.fromOffset(12, 0);
			BackgroundTransparency = 1; Text = row[1];
			Font = Enum.Font.GothamBold; TextSize = 11;
			TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 54; Parent = rowFrame;
		}), "textsub")

		local valColor = (row[1] == "Status") and Color3.fromRGB(80, 220, 120) or theme.Text
		local valLabel = tagText(mk("TextLabel", {
			Size = UDim2.new(0.62, -8, 1, 0); Position = UDim2.new(0.38, 0, 0, 0);
			BackgroundTransparency = 1; Text = row[2];
			Font = Enum.Font.GothamMedium; TextSize = 12;
			TextColor3 = valColor; TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 54; Parent = rowFrame;
		}), "text")

		-- Override green for status
		if row[1] == "Status" then
			valLabel:SetAttribute("_role", nil) -- don't let theme override this
		end
	end

	-- Keybind hints
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -48, 0, 18);
		Position = UDim2.fromOffset(24, tableY + #infoData * 28 + 18);
		BackgroundTransparency = 1;
		Text = "[ U ] toggle UI    [ Delete ] panic mode";
		Font = Enum.Font.GothamMedium; TextSize = 11;
		TextColor3 = theme.TextDim; ZIndex = 52; Parent = welcomeCard;
	}), "textdim")

	-- Enter button
	local enterBtn = mk("TextButton", {
		Size = UDim2.new(1, -48, 0, 44);
		Position = UDim2.fromOffset(24, tableY + #infoData * 28 + 44);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0;
		Text = "Enter Leon X  →";
		Font = Enum.Font.GothamBold; TextSize = 14;
		TextColor3 = Color3.fromRGB(8, 8, 10);
		AutoButtonColor = false; ZIndex = 52; Parent = welcomeCard;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	tagBg(enterBtn, "accent")

	enterBtn.MouseEnter:Connect(function()
		tw(enterBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(
			math.min(theme.Accent.R * 255 + 30, 255),
			math.min(theme.Accent.G * 255 + 30, 255),
			math.min(theme.Accent.B * 255 + 30, 255)
		)})
	end)
	enterBtn.MouseLeave:Connect(function()
		tw(enterBtn, 0.12, { BackgroundColor3 = theme.Accent })
	end)

	function win:DismissWelcome()
		tw(welcomeFrame, 0.3, { BackgroundTransparency = 1 })
		for _, child in ipairs(welcomeCard:GetDescendants()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				pcall(function() tw(child, 0.25, { TextTransparency = 1 }) end)
			elseif child:IsA("Frame") and child ~= welcomeCard then
				pcall(function() tw(child, 0.25, { BackgroundTransparency = 1 }) end)
			end
		end
		tw(welcomeCard, 0.3, { BackgroundTransparency = 1 })
		task.wait(0.4)
		welcomeFrame.Visible = false
		welcomeFrame.ZIndex = 0 -- Move behind everything
		welcomeFrame.BackgroundTransparency = 1
	end

	enterBtn.MouseButton1Click:Connect(function() win:DismissWelcome() end)

	-- ══════════════════════════════════════════════════════════════
	-- TABS — interactive with count badges + staggered reveal
	-- ══════════════════════════════════════════════════════════════
	local tabList = mk("Frame", {
		Size = UDim2.new(1, 0, 1, -60); Position = UDim2.fromOffset(0, 60);
		BackgroundTransparency = 1; ZIndex = 6; Parent = sidebarBg;
	})

	-- Tab count label at top of sidebar
	local tabCountLabel = tagText(mk("TextLabel", {
		Size = UDim2.new(1, -20, 0, 14); Position = UDim2.fromOffset(14, 56);
		BackgroundTransparency = 1; Text = "";
		Font = Enum.Font.Gotham; TextSize = 9;
		TextColor3 = theme.TextDim; TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 7; Parent = sidebarBg;
	}), "textdim")

	function win:Tab(cfg)
		cfg = cfg or {}
		local tabName = cfg.Title or cfg.Name or "Tab"
		local tabIcon = cfg.Icon or ""
		local tabDisplayName = (tabIcon ~= "" and tabIcon .. " " or "") .. tabName
		local tab = { Name = tabName; _layoutOrder = 0; _page = content; _win = win }
		local idx = #win._tabs + 1

		-- Staggered entry animation — slide in from left
		local btn = mk("TextButton", {
			Size = UDim2.new(1, -10, 0, 38);
			Position = UDim2.fromOffset(-SIDEBAR_W, (idx - 1) * 42);
			BackgroundTransparency = 1; Text = tabDisplayName;
			Font = Enum.Font.GothamBold; TextSize = 13;
			TextColor3 = win._theme.TextSub; AutoButtonColor = false;
			TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 7; Parent = tabList;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 6) }) })
		tagText(btn, "textsub")

		-- Staggered slide-in animation
		task.delay(idx * 0.06, function()
			tw(btn, 0.35, { Position = UDim2.fromOffset(5, (idx - 1) * 42) },
				Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 18)
		pad.Parent = btn

		-- Full highlight fill indicator (replaces left vertical bar)
		local indicator = tagBg(mk("Frame", {
			Size = UDim2.new(1, 0, 1, -4); Position = UDim2.fromOffset(0, 2);
			BackgroundColor3 = win._theme.Accent; BorderSizePixel = 0;
			BackgroundTransparency = 1; Visible = false; ZIndex = 6; Parent = btn;
		}), "accent")
		mk("UICorner", { CornerRadius = UDim.new(0, 6); Parent = indicator })

		-- Feature count badge (right side, shows how many items in this tab)
		local countBadge = mk("TextLabel", {
			Size = UDim2.fromOffset(24, 18); Position = UDim2.new(1, -32, 0.5, -9);
			BackgroundColor3 = theme.Elevated; BackgroundTransparency = 0.3;
			BorderSizePixel = 0; Text = "0";
			Font = Enum.Font.GothamBold; TextSize = 10;
			TextColor3 = theme.TextSub; ZIndex = 8; Parent = btn;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 9) }) })
		tagBg(countBadge, "elevated")
		tagText(countBadge, "textsub")
		tab._countBadge = countBadge

		local isActive = false
		local function setActive(active)
			isActive = active
			indicator.Visible = active
			if active then
				tw(indicator, 0.15, { BackgroundTransparency = 0.85 })
				tw(btn, 0.15, {
					TextColor3 = win._theme.Text,
					BackgroundTransparency = 1,
				})
				-- Glow on badge when active
				countBadge.BackgroundColor3 = win._theme.Accent
				countBadge.BackgroundTransparency = 0.7
				countBadge.TextColor3 = win._theme.Accent
			else
				tw(indicator, 0.15, { BackgroundTransparency = 1 })
				tw(btn, 0.15, {
					TextColor3 = win._theme.TextSub,
					BackgroundTransparency = 1,
				})
				countBadge.BackgroundColor3 = theme.Elevated
				countBadge.BackgroundTransparency = 0.3
				countBadge.TextColor3 = theme.TextSub
			end
			for _, entry in ipairs(win._allComps) do
				if entry._tab == tab then
					entry.Frame.Visible = active
				end
			end
		end

		btn.MouseButton1Click:Connect(function()
			for _, t in ipairs(win._tabs) do t._setActive(false) end
			setActive(true); win._active = tab
		end)
		-- Enhanced hover: subtle surface reveal + slight indent
		btn.MouseEnter:Connect(function()
			if not isActive then
				tw(btn, 0.12, {
					BackgroundColor3 = win._theme.Surface,
					BackgroundTransparency = 0.6,
					Position = UDim2.fromOffset(8, (idx - 1) * 42),
				})
			end
		end)
		btn.MouseLeave:Connect(function()
			if not isActive then
				tw(btn, 0.12, {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(5, (idx - 1) * 42),
				})
			end
		end)

		tab._setActive = setActive
		win._tabs[#win._tabs + 1] = tab
		if idx == 1 then setActive(true) end

		-- Update tab count label
		tabCountLabel.Text = tostring(#win._tabs) .. " tabs"

		local function wrap(fn)
			return function(selfOrData, maybeData)
				local d = maybeData or selfOrData
				local r = fn(tab, d)
				if r and r.Frame then
					win._allComps[#win._allComps + 1] = { _tab = tab; Frame = r.Frame }
					-- Update badge count (skip Sections)
					local compCount = 0
					for _, entry in ipairs(win._allComps) do
						if entry._tab == tab then
							compCount = compCount + 1
						end
					end
					countBadge.Text = tostring(compCount)
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

-- ════════════════════════════════════════════════════════════════════════════
-- COMPONENTS
-- ════════════════════════════════════════════════════════════════════════════

local function nextOrder(tab)
	tab._layoutOrder = (tab._layoutOrder or 0) + 1
	return tab._layoutOrder
end

-- ── Section ────────────────────────────────────────────────────────────────
function Section(tab, data)
	local label = getLabel(data)
	local theme = th(tab)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 34); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	if tab._layoutOrder > 1 then
		tagBg(mk("Frame", {
			Size = UDim2.new(1, 0, 0, 1); BackgroundColor3 = theme.BorderSub;
			BorderSizePixel = 0; Position = UDim2.fromOffset(0, 0); Parent = f;
		}), "bordersub")
	end
	-- Accent dot + bar
	tagBg(mk("Frame", {
		Size = UDim2.new(0, 4, 0, 18); Position = UDim2.fromOffset(0, 10);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; Parent = f;
	}), "accent")
	mk("UICorner", { CornerRadius = UDim.new(0, 2); Parent = f:GetChildren()[#f:GetChildren()] })

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -16, 0, 18); Position = UDim2.fromOffset(12, 10);
		BackgroundTransparency = 1;
		Text = label:upper();
		Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "textsub")
	return { Frame = f }
end

-- ── Paragraph ──────────────────────────────────────────────────────────────
function Paragraph(tab, data)
	local theme = th(tab)
	local label = getLabel(data)
	local hasTitle = data.Title and data.Title ~= ""
	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, hasTitle and 48 or 36);
		BackgroundColor3 = theme.Surface; BorderSizePixel = 0;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "surface")
	mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = f })

	local innerPad = Instance.new("UIPadding")
	innerPad.PaddingLeft = UDim.new(0, 14); innerPad.PaddingRight = UDim.new(0, 14)
	innerPad.PaddingTop = UDim.new(0, 10); innerPad.PaddingBottom = UDim.new(0, 10)
	innerPad.Parent = f

	if hasTitle then
		tagText(mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14); BackgroundTransparency = 1;
			Text = label; Font = Enum.Font.GothamBold; TextSize = 11;
			TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
		}), "textsub")
	end
	local cl = tagText(mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18); Position = UDim2.fromOffset(0, hasTitle and 18 or 0);
		BackgroundTransparency = 1; Text = data.Content or "";
		Font = Enum.Font.Gotham; TextSize = 13; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; TextWrapped = true; Parent = f;
	}), "text")
	local api = { Frame = f; Name = data.Title or "Paragraph" }
	function api:Set(t) cl.Text = t end
	function api:Get() return cl.Text end
	return api
end

-- ── Toggle ─────────────────────────────────────────────────────────────────
function Toggle(tab, data)
	local label = getLabel(data)
	local theme = th(tab)
	local val = data.Value ~= nil and data.Value or (data.Default ~= nil and data.Default or false)
	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 44); BackgroundColor3 = theme.Surface;
		BackgroundTransparency = GLASS_TRANSPARENCY.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "surface")
	mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = f })

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -64, 1, 0); Position = UDim2.fromOffset(14, 0);
		BackgroundTransparency = 1;
		Text = label; Font = Enum.Font.GothamMedium; TextSize = 13;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "text")

	local track = tagBg(mk("Frame", {
		Size = UDim2.fromOffset(44, 24); Position = UDim2.new(1, -54, 0.5, -12);
		BackgroundColor3 = val and theme.Accent or theme.Border; BorderSizePixel = 0; Parent = f;
	}), val and "accent" or "border")
	mk("UICorner", { CornerRadius = UDim.new(0, 12); Parent = track })

	local knob = mk("Frame", {
		Size = UDim2.fromOffset(18, 18);
		Position = val and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9);
		BackgroundColor3 = Color3.fromRGB(255,255,255); BorderSizePixel = 0; Parent = track;
	})
	mk("UICorner", { CornerRadius = UDim.new(1, 0); Parent = knob })

	local api = { Value = val; Frame = f; Name = data.Title or data.Name or "Toggle"; Callback = data.Callback }
	function api:Set(v)
		v = not not v
		if self.Value == v then return end
		self.Value = v
		tw(track, 0.2, { BackgroundColor3 = v and theme.Accent or theme.Border })
		track:SetAttribute("_role", v and "accent" or "border")
		tw(knob, 0.2, { Position = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) })
		if self.Callback then pcall(self.Callback, v) end
	end
	function api:Get() return self.Value end

	local btn = mk("TextButton", { Size = UDim2.new(1, 0, 1, 0); BackgroundTransparency = 1; Text = ""; Parent = f })
	btn.MouseButton1Click:Connect(function() api:Set(not api.Value) end)
	reg(data, api)
	attachTooltip(api, data.Tooltip)
	return api
end

-- ── Slider ─────────────────────────────────────────────────────────────────
function Slider(tab, data)
	local theme = th(tab)
	local mn = (data.Value and data.Value.Min) or 0
	local mx = (data.Value and data.Value.Max) or 100
	local df = (data.Value and data.Value.Default) or mn
	local step = data.Step or 1
	local cur = df

	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 56); BackgroundColor3 = theme.Surface;
		BackgroundTransparency = GLASS_TRANSPARENCY.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "surface")
	mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = f })

	-- Label + value on same row
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -74, 0, 16); Position = UDim2.fromOffset(14, 8);
		BackgroundTransparency = 1;
		Text = getLabel(data); Font = Enum.Font.GothamMedium; TextSize = 13;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "text")

	local valLbl = mk("TextBox", {
		Size = UDim2.new(0, 60, 0, 24); Position = UDim2.new(1, -74, 0, 4);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = tostring(df); Font = Enum.Font.GothamBold; TextSize = 12;
		TextColor3 = theme.Accent; TextXAlignment = Enum.TextXAlignment.Center;
		Parent = f;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 4); Parent = valLbl })
	tagBg(valLbl, "elevated")
	tagText(valLbl, "accent")

	-- Progress bar track (thicker, more visible)
	local trk = tagBg(mk("Frame", {
		Size = UDim2.new(1, -28, 0, 10); Position = UDim2.new(0, 14, 0, 36);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; Parent = f;
	}), "border")
	mk("UICorner", { CornerRadius = UDim.new(0, 5); Parent = trk })

	-- Progress bar fill (gradient accent)
	local fill = tagBg(mk("Frame", {
		Size = UDim2.new((df - mn) / math.max(mx - mn, 1), 0, 1, 0);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; Parent = trk;
	}), "accent")
	mk("UICorner", { CornerRadius = UDim.new(0, 5); Parent = fill })

	-- Gradient overlay on fill for depth
	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
			ColorSequenceKeypoint.new(1, theme.Accent),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.85),
			NumberSequenceKeypoint.new(0.5, 0.95),
			NumberSequenceKeypoint.new(1, 0.9),
		}),
		Rotation = 90;
		Parent = fill;
	})

	-- Edge handle (thin vertical line at end of fill, no knob)
	local handle = mk("Frame", {
		Size = UDim2.new(0, 3, 1, 2);
		Position = UDim2.new(1, -2, 0, -1);
		BackgroundColor3 = Color3.fromRGB(255,255,255);
		BorderSizePixel = 0; Parent = fill;
	})
	mk("UICorner", { CornerRadius = UDim.new(0, 1); Parent = handle })

	local function upd(v)
		local pct = math.clamp((v - mn) / math.max(mx - mn, 1), 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		valLbl.Text = tostring(math.floor(v + 0.5))
	end

	local dragging = false
	trk.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = true
		-- Visual feedback: slight pulse on handle
		tw(handle, 0.1, { Size = UDim2.new(0, 4, 1, 4) })
		local pos = (i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X
		local nv = mn + math.clamp(pos, 0, 1) * (mx - mn)
		nv = math.floor(nv / step + 0.5) * step; nv = math.clamp(nv, mn, mx)
		if nv ~= cur then cur = nv; upd(nv); if data.Callback then pcall(data.Callback, nv) end end
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				dragging = false
				tw(handle, 0.1, { Size = UDim2.new(0, 3, 1, 2) })
			end
		end)
	end)
	UIS.InputChanged:Connect(function(i)
		if not dragging then return end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
		local pos = (i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X
		local nv = mn + math.clamp(pos, 0, 1) * (mx - mn)
		nv = math.floor(nv / step + 0.5) * step; nv = math.clamp(nv, mn, mx)
		if nv ~= cur then cur = nv; upd(nv); if data.Callback then pcall(data.Callback, nv) end end
	end)

	-- Text input handler
	valLbl.FocusLost:Connect(function(enterPressed)
		if not enterPressed then
			valLbl.Text = tostring(cur)
			return
		end
		local num = tonumber(valLbl.Text)
		if num then
			num = math.clamp(num, mn, mx)
			cur = num
			upd(cur)
			if data.Callback then pcall(data.Callback, cur) end
		end
		valLbl.Text = tostring(cur)
	end)

	local api = { Value = df; Frame = f; Name = data.Title or data.Name or "Slider"; Callback = data.Callback }
	function api:Set(v)
		v = math.clamp(v, mn, mx)
		if self.Value == v then return end
		self.Value = v; cur = v; upd(v)
		if self.Callback then pcall(self.Callback, v) end
	end
	function api:Get() return self.Value end
	reg(data, api)
	attachTooltip(api, data.Tooltip)
	return api
end

-- ── Dropdown (frame expands, search, no clipping issues) ──────────────────
function Dropdown(tab, data)
	local theme = th(tab)
	local vals = data.Values or {}
	local cur = data.Value or (vals[1] or "")
	if type(cur) == "number" and vals[cur] then cur = vals[cur] end
	local open = false
	local searchTerm = ""
	local CLOSED_H = 60
	local ITEM_H = 32
	local SEARCH_H = 36
	local MAX_VISIBLE = 6

	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, CLOSED_H); BackgroundColor3 = theme.Surface;
		BackgroundTransparency = GLASS_TRANSPARENCY.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "surface")
	mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = f })

	-- Label
	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -28, 0, 14); Position = UDim2.fromOffset(14, 6);
		BackgroundTransparency = 1;
		Text = getLabel(data); Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "textsub")

	-- Selection box
	local box = mk("TextButton", {
		Size = UDim2.new(1, -28, 0, 32); Position = UDim2.fromOffset(14, 22);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = ""; AutoButtonColor = false; ZIndex = 2; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }),
	})
	tagBg(box, "elevated")
	local boxStroke = tagBorder(mk("UIStroke", {
		Color = theme.Border; Thickness = 1; Parent = box;
	}), "border")

	local valTxt = tagText(mk("TextLabel", {
		Size = UDim2.new(1, -36, 1, 0); Position = UDim2.fromOffset(12, 0);
		BackgroundTransparency = 1; Text = tostring(cur);
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 3; Parent = box;
	}), "text")

	-- Arrow icon (chevron down)
	tagText(mk("TextLabel", {
		Size = UDim2.new(0, 32, 1, 0); Position = UDim2.new(1, -32, 0, 0);
		BackgroundTransparency = 1; Text = "▼";
		Font = Enum.Font.GothamBold; TextSize = 14; TextColor3 = theme.Accent;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 3; Parent = box;
	}), "accent")

	-- Search input
	local searchBox = mk("TextBox", {
		Size = UDim2.new(1, -28, 0, 28); Position = UDim2.fromOffset(14, 58);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		PlaceholderText = "Search..."; PlaceholderColor3 = theme.TextDim;
		Text = ""; Font = Enum.Font.GothamMedium; TextSize = 12;
		TextColor3 = theme.Text; ClearTextOnFocus = true;
		TextXAlignment = Enum.TextXAlignment.Left;
		Visible = false; ZIndex = 3; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 5) }) })
	tagBg(searchBox, "elevated")
	tagText(searchBox, "text")
	local searchStroke = tagBorder(mk("UIStroke", {
		Color = theme.BorderSub; Thickness = 1; Parent = searchBox;
	}), "bordersub")
	local searchPad = Instance.new("UIPadding")
	searchPad.PaddingLeft = UDim.new(0, 10)
	searchPad.Parent = searchBox

	-- Scroll
	local scroll = mk("ScrollingFrame", {
		Size = UDim2.new(1, -28, 0, 0); Position = UDim2.fromOffset(14, 90);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 3; ScrollBarImageColor3 = theme.AccentDim;
		Visible = false; ZIndex = 3; Parent = f;
	})
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder; Padding = UDim.new(0, 2); Parent = scroll })

	local api = { Value = cur; Frame = f; Name = data.Title or data.Name or "Dropdown"; Callback = data.Callback }

	local function countFiltered()
		local count = 0
		for _, v in ipairs(vals) do
			if searchTerm == "" or tostring(v):lower():find(searchTerm, 1, true) then
				count = count + 1
			end
		end
		return count
	end

	local function rebuildItems()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		local filtered = {}
		for _, v in ipairs(vals) do
			local vs = tostring(v):lower()
			if searchTerm == "" or vs:find(searchTerm, 1, true) then
				filtered[#filtered + 1] = v
			end
		end
		for _, v in ipairs(filtered) do
			local item = mk("TextButton", {
				Size = UDim2.new(1, -4, 0, ITEM_H);
				BackgroundTransparency = 1;
				Text = tostring(v); Font = Enum.Font.GothamMedium; TextSize = 12;
				TextColor3 = tostring(v) == tostring(cur) and theme.Accent or theme.Text;
				TextXAlignment = Enum.TextXAlignment.Left; AutoButtonColor = false;
				ZIndex = 4; Parent = scroll;
			}, { mk("UICorner", { CornerRadius = UDim.new(0, 5) }) })
			local itemPad = Instance.new("UIPadding")
			itemPad.PaddingLeft = UDim.new(0, 12)
			itemPad.Parent = item

			item.MouseEnter:Connect(function()
				item.BackgroundColor3 = theme.BG; item.BackgroundTransparency = 0.3
			end)
			item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
			item.MouseButton1Click:Connect(function()
				cur = v; valTxt.Text = tostring(v); api.Value = v
				searchTerm = ""; searchBox.Text = ""
				open = false; searchBox.Visible = false; scroll.Visible = false
				tw(f, 0.15, { Size = UDim2.new(1, 0, 0, CLOSED_H) })
				if data.Callback then pcall(data.Callback, v) end
			end)
		end
		scroll.CanvasSize = UDim2.fromOffset(0, #filtered * (ITEM_H + 2))
		if open then
			local visCount = math.min(#filtered, MAX_VISIBLE)
			local h = CLOSED_H + visCount * (ITEM_H + 2) + SEARCH_H + 6
			scroll.Size = UDim2.new(1, -28, 0, visCount * (ITEM_H + 2))
			tw(f, 0.1, { Size = UDim2.new(1, 0, 0, h) })
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		searchTerm = searchBox.Text:lower()
		rebuildItems()
	end)
	rebuildItems()

	box.MouseButton1Click:Connect(function()
		if open then
			open = false; searchBox.Visible = false; scroll.Visible = false
			searchTerm = ""; searchBox.Text = ""
			tw(f, 0.15, { Size = UDim2.new(1, 0, 0, CLOSED_H) })
		else
			open = true; searchBox.Visible = true; scroll.Visible = true
			searchBox.Text = ""; rebuildItems()
			local visCount = math.min(countFiltered(), MAX_VISIBLE)
			local h = CLOSED_H + visCount * (ITEM_H + 2) + SEARCH_H + 6
			scroll.Size = UDim2.new(1, -28, 0, visCount * (ITEM_H + 2))
			tw(f, 0.15, { Size = UDim2.new(1, 0, 0, h) })
			task.wait(0.05)
			pcall(function() searchBox:CaptureFocus() end)
		end
	end)

	function api:Refresh(v)
		vals = v or {}; searchTerm = ""; searchBox.Text = ""
		rebuildItems()
		local found = false
		for _, item in ipairs(vals) do
			if tostring(item) == tostring(cur) then found = true; break end
		end
		if not found and #vals > 0 then
			cur = vals[1]; valTxt.Text = tostring(vals[1]); api.Value = vals[1]
		end
	end
	function api:Select(v) cur = v; valTxt.Text = tostring(v); api.Value = v end
	function api:Set(v) self:Select(v); if self.Callback then pcall(self.Callback, v) end end
	function api:Get() return self.Value end
	reg(data, api)
	attachTooltip(api, data.Tooltip)
	return api
end

-- ── Button ─────────────────────────────────────────────────────────────────
-- Styles: "Primary" (accent fill), "Outline" (border only), "Danger" (red fill), "Ghost" (transparent)
function Button(tab, data)
	local theme = th(tab)
	local style = data.Style or "Surface"
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 40); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})

	local bgColor, textColor, borderColor, borderThickness
	if style == "Primary" then
		bgColor = theme.Accent
		textColor = Color3.fromRGB(255, 255, 255)
		borderColor = theme.Accent
		borderThickness = 0
	elseif style == "Outline" then
		bgColor = Color3.fromRGB(0, 0, 0)
		textColor = theme.Accent
		borderColor = theme.Accent
		borderThickness = 1
	elseif style == "Danger" then
		bgColor = Color3.fromRGB(220, 53, 69)
		textColor = Color3.fromRGB(255, 255, 255)
		borderColor = Color3.fromRGB(220, 53, 69)
		borderThickness = 0
	elseif style == "Ghost" then
		bgColor = Color3.fromRGB(0, 0, 0)
		textColor = theme.Text
		borderColor = Color3.fromRGB(0, 0, 0)
		borderThickness = 0
	else -- Surface (default)
		bgColor = theme.Surface
		textColor = theme.Text
		borderColor = theme.Border
		borderThickness = 1
	end

	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 1, 0); BackgroundColor3 = bgColor;
		BackgroundTransparency = (style == "Outline" or style == "Ghost") and 1 or 0;
		BorderSizePixel = 0; Text = getLabel(data);
		Font = Enum.Font.GothamMedium; TextSize = 13; TextColor3 = textColor;
		AutoButtonColor = false; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})

	local btnStroke = mk("UIStroke", {
		Color = borderColor; Thickness = borderThickness; Parent = btn;
	})

	btn.MouseEnter:Connect(function()
		if style == "Primary" then
			tw(btn, 0.12, { BackgroundColor3 = theme.Accent:Lerp(Color3.fromRGB(255,255,255), 0.15) })
		elseif style == "Outline" then
			tw(btn, 0.12, { BackgroundColor3 = theme.Accent, BackgroundTransparency = 0.9 })
		elseif style == "Danger" then
			tw(btn, 0.12, { BackgroundColor3 = Color3.fromRGB(255, 80, 90) })
		elseif style == "Ghost" then
			tw(btn, 0.12, { BackgroundColor3 = theme.Surface, BackgroundTransparency = 0 })
		else
			tw(btn, 0.12, { BackgroundColor3 = theme.Elevated })
			btnStroke.Color = theme.AccentDim
		end
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = bgColor
		btn.BackgroundTransparency = (style == "Outline" or style == "Ghost") and 1 or 0
		btnStroke.Color = borderColor
	end)

	btn.MouseButton1Down:Connect(function()
		tw(btn, 0.06, { TextColor3 = (style == "Outline") and Color3.fromRGB(255,255,255) or theme.Accent })
	end)

	btn.MouseButton1Up:Connect(function()
		tw(btn, 0.06, { TextColor3 = textColor })
	end)

	btn.MouseButton1Click:Connect(function() if data.Callback then pcall(data.Callback) end end)

	local api = { Frame = f; Name = data.Title or data.Name or "Button" }
	attachTooltip(api, data.Tooltip)
	return api
end

-- ── Keybind ────────────────────────────────────────────────────────────────
function Keybind(tab, data)
	local theme = th(tab)
	local cur = data.Value or data.Default or "None"
	local capturing = false
	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 44); BackgroundColor3 = theme.Surface;
		BackgroundTransparency = GLASS_TRANSPARENCY.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "surface")
	mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = f })

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -106, 1, 0); Position = UDim2.fromOffset(14, 0);
		BackgroundTransparency = 1;
		Text = getLabel(data); Font = Enum.Font.GothamMedium; TextSize = 13;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "text")

	local kbtn = tagBg(mk("TextButton", {
		Size = UDim2.fromOffset(86, 28); Position = UDim2.new(1, -98, 0.5, -14);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = tostring(cur); Font = Enum.Font.GothamBold; TextSize = 12;
		TextColor3 = theme.Accent; AutoButtonColor = false; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }),
	}), "elevated")
	tagText(kbtn, "accent")
	local kbStroke = tagBorder(mk("UIStroke", {
		Color = theme.Border; Thickness = 1; Parent = kbtn;
	}), "border")

	kbtn.MouseButton1Click:Connect(function()
		if capturing then return end
		capturing = true; kbtn.Text = "..."; kbStroke.Color = theme.AccentDim
	end)
	UIS.InputBegan:Connect(function(i, gp)
		if not capturing then return end
		if gp then return end
		if i.UserInputType == Enum.UserInputType.Keyboard then
			if i.KeyCode == Enum.KeyCode.Escape then
				capturing = false; kbtn.Text = tostring(cur); kbStroke.Color = theme.Border
			else
				cur = i.KeyCode.Name; capturing = false
				kbtn.Text = cur; kbStroke.Color = theme.Border
				if data.Callback then pcall(data.Callback, cur) end
			end
		end
	end)
	local api = { Value = cur; Frame = f; Name = data.Title or data.Name or "Keybind"; Callback = data.Callback }
	function api:Set(v) cur = tostring(v); kbtn.Text = cur end
	function api:Get() return cur end
	reg(data, api)
	attachTooltip(api, data.Tooltip)
	return api
end

-- ── Input ──────────────────────────────────────────────────────────────────
function Input(tab, data)
	local theme = th(tab)
	local f = tagBg(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 60); BackgroundColor3 = theme.Surface;
		BackgroundTransparency = GLASS_TRANSPARENCY.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}), "surface")
	mk("UICorner", { CornerRadius = UDim.new(0, 8); Parent = f })

	tagText(mk("TextLabel", {
		Size = UDim2.new(1, -28, 0, 14); Position = UDim2.fromOffset(14, 6);
		BackgroundTransparency = 1;
		Text = getLabel(data); Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	}), "textsub")

	local stroke = tagBorder(mk("UIStroke", { Color = theme.Border; Thickness = 1 }), "border")
	local tb = tagBg(mk("TextBox", {
		Size = UDim2.new(1, -28, 0, 30); Position = UDim2.fromOffset(14, 22);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		PlaceholderText = data.Placeholder or "";
		Text = data.Value or ""; Font = Enum.Font.GothamMedium; TextSize = 13;
		TextColor3 = theme.Text; PlaceholderColor3 = theme.TextDim;
		TextXAlignment = Enum.TextXAlignment.Left; ClearTextOnFocus = false;
		Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }),
		stroke,
	}), "elevated")
	tagText(tb, "text")

	local api = { Value = data.Value or ""; Frame = f; Name = data.Title or data.Name or "Input"; Callback = data.Callback }

	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 10); pad.Parent = tb
	tb.FocusLost:Connect(function()
		api.Value = tb.Text
		if data.Callback then pcall(data.Callback, tb.Text) end
	end)
	tb.Focused:Connect(function() stroke.Color = theme.AccentDim end)
	tb.FocusLost:Connect(function() stroke.Color = theme.Border end)

	function api:Set(v) self.Value = tostring(v or ""); tb.Text = self.Value end
	function api:Get() return tb.Text end
	reg(data, api)
	attachTooltip(api, data.Tooltip)
	return api
end

-- ════════════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ════════════════════════════════════════════════════════════════════════════

function Library:Notify(cfg)
	cfg = cfg or {}
	local title = cfg.Title or ""
	local text = cfg.Content or cfg.Text or ""
	local dur = cfg.Duration or 2
	local theme = self.Themes[self._lastTheme or "Default"] or self.Themes.Default

	local n = mk("Frame", {
		Size = UDim2.new(0, 280, 0, 64);
		Position = UDim2.new(1, 300, 0, 16 + #activeNotifs * 72);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		ClipsDescendants = true; ZIndex = 100; Parent = notifGui;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})
	-- Accent bar
	mk("Frame", {
		Size = UDim2.new(0, 3, 1, 0); BackgroundColor3 = theme.Accent;
		BorderSizePixel = 0; ZIndex = 101; Parent = n;
	})
	mk("UIStroke", { Color = theme.Border; Thickness = 1; ZIndex = 100; Parent = n })

	if title ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(1, -16, 0, 20); Position = UDim2.fromOffset(14, 8);
			BackgroundTransparency = 1; Text = title;
			Font = Enum.Font.GothamBold; TextSize = 13;
			TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 101; Parent = n;
		})
	end
	if text ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(1, -16, 0, 18);
			Position = UDim2.fromOffset(14, title ~= "" and 28 or 10);
			BackgroundTransparency = 1; Text = text;
			Font = Enum.Font.Gotham; TextSize = 12;
			TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left;
			TextWrapped = true; ZIndex = 101; Parent = n;
		})
	end

	activeNotifs[#activeNotifs + 1] = n
	tw(n, 0.2, { Position = UDim2.new(1, -296, 0, 16 + (#activeNotifs - 1) * 72) })

	task.delay(dur, function()
		tw(n, 0.2, { Position = UDim2.new(1, 300, 0, n.Position.Y.Offset), BackgroundTransparency = 1 })
		task.wait(0.25)
		for i, v in ipairs(activeNotifs) do
			if v == n then table.remove(activeNotifs, i) break end
		end
		for i, v in ipairs(activeNotifs) do
			tw(v, 0.15, { Position = UDim2.new(1, -296, 0, 16 + (i - 1) * 72) })
		end
		task.wait(0.15)
		pcall(function() n:Destroy() end)
	end)
end

return Library
