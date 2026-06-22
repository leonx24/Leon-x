-- Leon X | Noir UI Library v3
-- "Quiet luxury" — dark elegant minimalism with disciplined motion.
--
-- CUSTOMIZATION:
--   Library:SetTheme("Gold")     -- or Emerald, Rose, Violet, Amber, Neon
--   Library.Themes["MyTheme"] = { Accent = Color3.fromRGB(r,g,b), AccentDim = ... }

print("[LeonX-LIB] ████ VERSION: UI-POLISH-V3-FINAL ████")

local Library = {}
Library.Registry = {}
Library._allComponents = {}
Library._themeConns = {}
Library._windows = {}

-- ════════════════════════════════════════════════════════════════════════════
-- THEMES
-- ════════════════════════════════════════════════════════════════════════════

local function baseTh(accent, accentDim)
	return {
		BG = Color3.fromRGB(14,14,16); Surface = Color3.fromRGB(22,22,26);
		Elevated = Color3.fromRGB(30,30,36); Border = Color3.fromRGB(42,42,48);
		BorderSub = Color3.fromRGB(34,34,40);
		Text = Color3.fromRGB(230,230,235); TextSub = Color3.fromRGB(130,130,140);
		Accent = Color3.fromRGB(table.unpack(accent));
		AccentDim = Color3.fromRGB(table.unpack(accentDim));
	}
end

Library.Themes = {
	Default = baseTh({140,160,210}, {90,105,140}),
	Gold    = baseTh({200,175,110}, {140,120,70}),
	Emerald = baseTh({110,190,140}, {70,130,95}),
	Rose    = baseTh({210,130,150}, {150,85,100}),
	Violet  = baseTh({160,130,220}, {110,85,160}),
	Amber   = baseTh({220,170,80},  {160,120,50}),
	Neon    = baseTh({100,220,180}, {60,160,130}),
}

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITIES
-- ════════════════════════════════════════════════════════════════════════════

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local function mk(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	return inst
end

local function tw(obj, dur, props)
	local t = TS:Create(obj, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play(); return t
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

-- ════════════════════════════════════════════════════════════════════════════
-- NOTIFICATION GUI
-- ════════════════════════════════════════════════════════════════════════════

local notifGui = mk("ScreenGui", {
	Name = "LeonXNotif"; ResetOnSpawn = false;
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	DisplayOrder = 9999; IgnoreGuiInset = true;
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
	local size      = cfg.Size or UDim2.new(0, 600, 0, 560)
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.U
	local themeName = cfg.Theme or "Default"
	local theme     = Library.Themes[themeName] or Library.Themes.Default

	local win = { _tabs = {}; _active = nil; _visible = true; _theme = theme; _toggleKey = toggleKey; _themeName = themeName }
	Library._windows[#Library._windows + 1] = win
	Library._lastTheme = themeName

	local sg = mk("ScreenGui", {
		Name = "LeonXNoir"; ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		DisplayOrder = 999; IgnoreGuiInset = true;
		Parent = lp:WaitForChild("PlayerGui");
	})

	local main = mk("Frame", {
		Size = size; Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2);
		BackgroundColor3 = theme.BG; BorderSizePixel = 0;
		ClipsDescendants = true; ZIndex = 1; Parent = sg;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })

	local mainStroke = mk("UIStroke", { Color = theme.Border; Thickness = 1; Parent = main })

	-- ── Sidebar ──
	local SIDEBAR_W = 130
	local sidebar = mk("Frame", {
		Size = UDim2.new(0, SIDEBAR_W, 1, 0); Position = UDim2.fromOffset(0, 0);
		BackgroundColor3 = theme.BG; BorderSizePixel = 0; ZIndex = 2; Parent = main;
	})
	mk("Frame", {
		Size = UDim2.new(0, 1, 1, 0); Position = UDim2.new(1, 0, 0, 0);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; ZIndex = 2; Parent = sidebar;
	})
	local logo = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 48); Position = UDim2.fromOffset(0, 0);
		BackgroundTransparency = 1; Text = "⚡ Leon X";
		Font = Enum.Font.GothamBold; TextSize = 17;
		TextColor3 = theme.Accent; ZIndex = 3; Parent = sidebar;
	})

	-- ── Header ──
	local header = mk("Frame", {
		Size = UDim2.new(1, -SIDEBAR_W, 0, 44); Position = UDim2.fromOffset(SIDEBAR_W, 0);
		BackgroundColor3 = theme.Surface; BorderSizePixel = 0; ZIndex = 2; Parent = main;
	})
	mk("Frame", {
		Size = UDim2.new(1, 0, 0, 1); Position = UDim2.new(0, 0, 1, -1);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; ZIndex = 2; Parent = header;
	})
	mk("TextLabel", {
		Size = UDim2.new(1, -100, 1, 0); Position = UDim2.fromOffset(16, 0);
		BackgroundTransparency = 1; Text = title;
		Font = Enum.Font.GothamBold; TextSize = 15; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 3; Parent = header;
	})
	if author ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(0, 110, 1, 0); Position = UDim2.new(1, -130, 0, 0);
			BackgroundTransparency = 1; Text = author;
			Font = Enum.Font.Gotham; TextSize = 11; TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Right; ZIndex = 3; Parent = header;
		})
	end

	local minBtn = mk("TextButton", {
		Size = UDim2.fromOffset(30, 30); Position = UDim2.new(1, -68, 0.5, -15);
		BackgroundTransparency = 1; Text = "—";
		Font = Enum.Font.GothamBold; TextSize = 16; TextColor3 = theme.TextSub;
		AutoButtonColor = false; ZIndex = 10; Parent = header;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 6) }) })

	local closeBtn = mk("TextButton", {
		Size = UDim2.fromOffset(30, 30); Position = UDim2.new(1, -36, 0.5, -15);
		BackgroundTransparency = 1; Text = "✕";
		Font = Enum.Font.GothamBold; TextSize = 14; TextColor3 = theme.TextSub;
		AutoButtonColor = false; ZIndex = 10; Parent = header;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 6) }) })

	-- Hover effects for header buttons
	for _, btn in ipairs({minBtn, closeBtn}) do
		btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0; btn.BackgroundColor3 = theme.Elevated end)
		btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 1 end)
	end

	local minContentVisible = true
	minBtn.MouseButton1Click:Connect(function()
		minContentVisible = not minContentVisible
		tw(main, 0.2, { Size = minContentVisible and size or UDim2.new(0, size.X.Offset, 0, 44) })
	end)

	local content = mk("ScrollingFrame", {
		Size = UDim2.new(1, -SIDEBAR_W, 1, -44); Position = UDim2.fromOffset(SIDEBAR_W, 44);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 4; ScrollBarImageColor3 = theme.AccentDim;
		CanvasSize = UDim2.fromOffset(0, 0);
		ClipsDescendants = true; ZIndex = 2; Parent = main;
	})
	local contentLayout = mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder; Padding = UDim.new(0, 6); Parent = content })
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

	-- ── Floating open button ──
	local floatGui = mk("ScreenGui", {
		Name = "LeonXFloat"; ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		DisplayOrder = 998; IgnoreGuiInset = true;
		Parent = lp:WaitForChild("PlayerGui");
	})
	local floatBtn = mk("TextButton", {
		Size = UDim2.fromOffset(52, 52); Position = UDim2.new(0, 16, 0.5, -26);
		BackgroundColor3 = theme.Surface; Text = "X";
		Font = Enum.Font.GothamBold; TextSize = 16; TextColor3 = theme.Accent;
		AutoButtonColor = false; Visible = false; ZIndex = 10; Parent = floatGui;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1.5 }),
	})
	do
		local fDragging, fDragStart, fStartPos, fDidMove = false, nil, nil, false
		local function isTap(i)
			return i.UserInputType == Enum.UserInputType.MouseButton1
				or i.UserInputType == Enum.UserInputType.Touch
		end
		floatBtn.InputBegan:Connect(function(i)
			if isTap(i) then
				fDragging = true; fDidMove = false
				fDragStart = i.Position; fStartPos = floatBtn.Position
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if fDragging and (i.UserInputType == Enum.UserInputType.MouseMovement
					or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - fDragStart
				if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then fDidMove = true end
				floatBtn.Position = UDim2.new(
					fStartPos.X.Scale, fStartPos.X.Offset + d.X,
					fStartPos.Y.Scale, fStartPos.Y.Offset + d.Y
				)
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if isTap(i) and fDragging then
				fDragging = false
				if not fDidMove then win:Open() end
			end
		end)
	end

	-- ── Close / Open ──
	function win:Close()
		win._visible = false
		main.Visible = false
		floatBtn.Visible = true
	end
	function win:Open()
		floatBtn.Visible = false
		main.Visible = true
		win._visible = true
	end
	closeBtn.MouseButton1Click:Connect(function() win:Close() end)

	-- ── Drag ──
	local dragging, dragStart, startPos
	header.InputBegan:Connect(function(i)
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

	-- ── Public API ──
	function win:SetToggleKey(k) win._toggleKey = k end
	function win:SetTheme(name)
		local t = Library.Themes[name]
		if not t then return end
		win._theme = t; win._themeName = name
		Library._lastTheme = name
		main.BackgroundColor3 = t.BG; mainStroke.Color = t.Border
		sidebar.BackgroundColor3 = t.BG; header.BackgroundColor3 = t.Surface
		logo.TextColor3 = t.Accent; floatBtn.TextColor3 = t.Accent
		floatBtn.BackgroundColor3 = t.Surface
		for _, conn in ipairs(Library._themeConns) do pcall(function() conn(t) end) end
	end

	-- FIX: use `win` not `self` (self = Library here, not win)
	UIS.InputBegan:Connect(function(i, gp)
		if gp or i.KeyCode ~= win._toggleKey then return end
		if win._visible then win:Close() else win:Open() end
	end)

	-- ── WELCOME SCREEN ─────────────────────────────────────────────────────
	local welcomeFrame = mk("Frame", {
		Size = UDim2.fromScale(1, 1);
		BackgroundColor3 = theme.BG; BorderSizePixel = 0;
		ZIndex = 50; Parent = main;
	})
	-- Center card
	local welcomeCard = mk("Frame", {
		Size = UDim2.new(0, 420, 0, 400);
		AnchorPoint = Vector2.new(0.5, 0.5);
		Position = UDim2.fromScale(0.5, 0.5);
		BackgroundColor3 = theme.Surface; BorderSizePixel = 0;
		ZIndex = 51; Parent = welcomeFrame;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 12) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1; ZIndex = 51 }),
	})

	-- Accent glow animation on card border
	task.spawn(function()
		local stroke = welcomeCard:FindFirstChildWhichIsA("UIStroke")
		while stroke and stroke.Parent do
			tw(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Color = theme.Accent})
			task.wait(1.5)
			tw(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Color = theme.Border})
			task.wait(1.5)
		end
	end)

	-- Logo
	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 36); Position = UDim2.fromOffset(0, 24);
		BackgroundTransparency = 1; Text = "⚡ Leon X";
		Font = Enum.Font.GothamBold; TextSize = 28;
		TextColor3 = theme.Accent; ZIndex = 52; Parent = welcomeCard;
	})
	-- Version badge
	mk("TextLabel", {
		Size = UDim2.new(0, 60, 0, 20); Position = UDim2.new(0.5, -30, 0, 62);
		BackgroundColor3 = theme.Accent; BackgroundTransparency = 0.7;
		Text = "v1.6"; Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.Text; ZIndex = 52; Parent = welcomeCard;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	-- Description
	mk("TextLabel", {
		Size = UDim2.new(1, -48, 0, 36); Position = UDim2.fromOffset(24, 90);
		BackgroundTransparency = 1;
		Text = "Universal Roblox Enhancement Script\nA powerful, modular framework for any game.";
		Font = Enum.Font.Gotham; TextSize = 12; TextColor3 = theme.TextSub;
		TextWrapped = true; ZIndex = 52; Parent = welcomeCard;
	})

	-- ── Info table ──
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
	local tableY = 138
	local tableFrame = mk("Frame", {
		Size = UDim2.new(1, -48, 0, #infoData * 26 + 8);
		Position = UDim2.fromOffset(24, tableY);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		ZIndex = 52; Parent = welcomeCard;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })

	for i, row in ipairs(infoData) do
		local rowBg = (i % 2 == 0) and theme.Elevated or theme.BG
		local rowFrame = mk("Frame", {
			Size = UDim2.new(1, -4, 0, 24);
			Position = UDim2.fromOffset(2, 2 + (i-1) * 26);
			BackgroundColor3 = rowBg; BackgroundTransparency = 0.5;
			BorderSizePixel = 0; ZIndex = 53; Parent = tableFrame;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 4) }) })

		mk("TextLabel", {
			Size = UDim2.new(0.4, -8, 1, 0); Position = UDim2.fromOffset(10, 0);
			BackgroundTransparency = 1; Text = row[1];
			Font = Enum.Font.GothamBold; TextSize = 11;
			TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 54; Parent = rowFrame;
		})
		local valColor = theme.Text
		if row[1] == "Status" then valColor = Color3.fromRGB(80, 220, 120) end
		mk("TextLabel", {
			Size = UDim2.new(0.6, -8, 1, 0); Position = UDim2.new(0.4, 0, 0, 0);
			BackgroundTransparency = 1; Text = row[2];
			Font = Enum.Font.GothamMedium; TextSize = 12;
			TextColor3 = valColor;
			TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 54; Parent = rowFrame;
		})
	end

	-- Keybinds hint
	mk("TextLabel", {
		Size = UDim2.new(1, -48, 0, 20);
		Position = UDim2.fromOffset(24, tableY + #infoData * 26 + 20);
		BackgroundTransparency = 1;
		Text = "Press  U  to toggle UI  ·  Press  Delete  for panic mode";
		Font = Enum.Font.Gotham; TextSize = 11;
		TextColor3 = theme.TextSub; ZIndex = 52; Parent = welcomeCard;
	})

	-- Enter button
	local enterBtn = mk("TextButton", {
		Size = UDim2.new(1, -48, 0, 42);
		Position = UDim2.fromOffset(24, tableY + #infoData * 26 + 48);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0;
		Text = "Enter Leon X";
		Font = Enum.Font.GothamBold; TextSize = 14;
		TextColor3 = Color3.fromRGB(10,10,12);
		AutoButtonColor = false; ZIndex = 52; Parent = welcomeCard;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	enterBtn.MouseEnter:Connect(function()
		tw(enterBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(
			math.min(theme.Accent.R * 255 + 20, 255),
			math.min(theme.Accent.G * 255 + 20, 255),
			math.min(theme.Accent.B * 255 + 20, 255)
		)})
	end)
	enterBtn.MouseLeave:Connect(function()
		tw(enterBtn, 0.1, { BackgroundColor3 = theme.Accent })
	end)

	function win:DismissWelcome()
		tw(welcomeFrame, 0.25, { BackgroundTransparency = 1 })
		task.wait(0.25)
		welcomeFrame.Visible = false
	end

	enterBtn.MouseButton1Click:Connect(function()
		win:DismissWelcome()
	end)

	-- ── TAB ────────────────────────────────────────────────────────────────
	local tabList = mk("Frame", {
		Size = UDim2.new(1, 0, 1, -48); Position = UDim2.fromOffset(0, 48);
		BackgroundTransparency = 1; ZIndex = 3; Parent = sidebar;
	})

	function win:Tab(cfg)
		cfg = cfg or {}
		local tabName = cfg.Title or cfg.Name or "Tab"
		local tab = { Name = tabName; _layoutOrder = 0; _page = content; _win = win }
		local idx = #win._tabs + 1

		local btn = mk("TextButton", {
			Size = UDim2.new(1, -10, 0, 38);
			Position = UDim2.fromOffset(5, (idx - 1) * 42);
			BackgroundTransparency = 1; Text = tabName;
			Font = Enum.Font.GothamBold; TextSize = 13;
			TextColor3 = win._theme.TextSub; AutoButtonColor = false;
			TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 4; Parent = tabList;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 6) }) })
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 14)
		pad.Parent = btn
		local indicator = mk("Frame", {
			Size = UDim2.new(0, 3, 0, 22); Position = UDim2.new(0, 2, 0.5, -11);
			BackgroundColor3 = win._theme.Accent; BorderSizePixel = 0;
			Visible = false; ZIndex = 5; Parent = btn;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 2) }) })

		local isActive = false
		local function setActive(active)
			isActive = active
			indicator.Visible = active
			if active then
				btn.TextColor3 = win._theme.Text
				btn.BackgroundColor3 = win._theme.Surface
				btn.BackgroundTransparency = 0.3
			else
				btn.TextColor3 = win._theme.TextSub
				btn.BackgroundTransparency = 1
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
		btn.MouseEnter:Connect(function()
			if not isActive then
				btn.BackgroundColor3 = win._theme.Surface
				btn.BackgroundTransparency = 0.7
			end
		end)
		btn.MouseLeave:Connect(function()
			if not isActive then btn.BackgroundTransparency = 1 end
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

	win._sg = sg; win._main = main; win._header = header
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
		Size = UDim2.new(1, 0, 0, 32); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	if tab._layoutOrder > 1 then
		mk("Frame", {
			Size = UDim2.new(1, 0, 0, 1); BackgroundColor3 = theme.BorderSub;
			BorderSizePixel = 0; Position = UDim2.fromOffset(0, 0); Parent = f;
		})
	end
	mk("Frame", {
		Size = UDim2.new(0, 4, 0, 16); Position = UDim2.fromOffset(0, 10);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 2) }) })
	mk("TextLabel", {
		Size = UDim2.new(1, -14, 0, 18); Position = UDim2.fromOffset(12, 9);
		BackgroundTransparency = 1;
		Text = label:upper();
		Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	return { Frame = f }
end

-- ── Paragraph ──────────────────────────────────────────────────────────────
function Paragraph(tab, data)
	local theme = th(tab)
	local label = getLabel(data)
	local hasTitle = data.Title and data.Title ~= ""
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, hasTitle and 46 or 34); BackgroundColor3 = theme.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	local innerPad = Instance.new("UIPadding")
	innerPad.PaddingLeft = UDim.new(0, 14); innerPad.PaddingRight = UDim.new(0, 14)
	innerPad.PaddingTop = UDim.new(0, 8); innerPad.PaddingBottom = UDim.new(0, 8)
	innerPad.Parent = f
	if hasTitle then
		mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14);
			BackgroundTransparency = 1;
			Text = label; Font = Enum.Font.GothamBold; TextSize = 11;
			TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
		})
	end
	local cl = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18); Position = UDim2.fromOffset(0, hasTitle and 18 or 0);
		BackgroundTransparency = 1; Text = data.Content or "";
		Font = Enum.Font.Gotham; TextSize = 13;
		TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; TextWrapped = true; Parent = f;
	})
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
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 42); BackgroundColor3 = theme.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	mk("TextLabel", {
		Size = UDim2.new(1, -62, 1, 0); Position = UDim2.fromOffset(14, 0);
		BackgroundTransparency = 1;
		Text = label; Font = Enum.Font.GothamMedium; TextSize = 13;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	local track = mk("Frame", {
		Size = UDim2.fromOffset(42, 22); Position = UDim2.new(1, -52, 0.5, -11);
		BackgroundColor3 = val and theme.Accent or theme.Border; BorderSizePixel = 0; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 11) }) })
	local knob = mk("Frame", {
		Size = UDim2.fromOffset(16, 16);
		Position = val and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8);
		BackgroundColor3 = Color3.fromRGB(255,255,255); BorderSizePixel = 0; Parent = track;
	}, { mk("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local api = { Value = val; Frame = f; Name = data.Title or data.Name or "Toggle"; Callback = data.Callback }
	function api:Set(v)
		v = not not v
		if self.Value == v then return end
		self.Value = v
		tw(track, 0.18, { BackgroundColor3 = v and theme.Accent or theme.Border })
		tw(knob, 0.18, { Position = v and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
		if self.Callback then pcall(self.Callback, v) end
	end
	function api:Get() return self.Value end

	local btn = mk("TextButton", { Size = UDim2.new(1, 0, 1, 0); BackgroundTransparency = 1; Text = ""; Parent = f })
	btn.MouseButton1Click:Connect(function() api:Set(not api.Value) end)
	reg(data, api)
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

	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 56); BackgroundColor3 = theme.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	mk("TextLabel", {
		Size = UDim2.new(1, -72, 0, 16); Position = UDim2.fromOffset(14, 10);
		BackgroundTransparency = 1;
		Text = getLabel(data); Font = Enum.Font.GothamMedium; TextSize = 13;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	local valLbl = mk("TextLabel", {
		Size = UDim2.new(0, 50, 0, 16); Position = UDim2.new(1, -62, 0, 10);
		BackgroundTransparency = 1; Text = tostring(df);
		Font = Enum.Font.GothamBold; TextSize = 12; TextColor3 = theme.Accent;
		TextXAlignment = Enum.TextXAlignment.Right; Parent = f;
	})
	local trk = mk("Frame", {
		Size = UDim2.new(1, -28, 0, 6); Position = UDim2.new(0, 14, 0, 36);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 3) }) })
	local fill = mk("Frame", {
		Size = UDim2.new((df - mn) / math.max(mx - mn, 1), 0, 1, 0);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; Parent = trk;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 3) }) })
	local knob = mk("Frame", {
		Size = UDim2.fromOffset(16, 16);
		Position = UDim2.new((df - mn) / math.max(mx - mn, 1), -8, 0.5, -8);
		BackgroundColor3 = Color3.fromRGB(255,255,255); BorderSizePixel = 0; Parent = trk;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }),
		mk("UIStroke", { Color = theme.AccentDim; Thickness = 2 }),
	})

	local function upd(v)
		local pct = math.clamp((v - mn) / math.max(mx - mn, 1), 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, -8, 0.5, -8)
		valLbl.Text = tostring(math.floor(v + 0.5))
	end

	local dragging = false
	trk.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = true
		local pos = (i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X
		local nv = mn + math.clamp(pos, 0, 1) * (mx - mn)
		nv = math.floor(nv / step + 0.5) * step; nv = math.clamp(nv, mn, mx)
		if nv ~= cur then cur = nv; upd(nv); if data.Callback then pcall(data.Callback, nv) end end
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end)
	UIS.InputChanged:Connect(function(i)
		if not dragging then return end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
		local pos = (i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X
		local nv = mn + math.clamp(pos, 0, 1) * (mx - mn)
		nv = math.floor(nv / step + 0.5) * step; nv = math.clamp(nv, mn, mx)
		if nv ~= cur then cur = nv; upd(nv); if data.Callback then pcall(data.Callback, nv) end end
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
	return api
end

-- ── Dropdown (with search, expanded frame to avoid ClipsDescendants) ────────
function Dropdown(tab, data)
	local theme = th(tab)
	local vals = data.Values or {}
	local cur = data.Value or (vals[1] or "")
	if type(cur) == "number" and vals[cur] then cur = vals[cur] end
	local open = false
	local searchTerm = ""
	local CLOSED_H = 58
	local ITEM_H = 30
	local SEARCH_H = 34
	local MAX_VISIBLE = 6

	local function calcOpenH()
		local count = 0
		for _, v in ipairs(vals) do
			if searchTerm == "" or tostring(v):lower():find(searchTerm, 1, true) then
				count = count + 1
			end
		end
		return CLOSED_H + math.min(count, MAX_VISIBLE) * ITEM_H + SEARCH_H + 8
	end

	-- Frame expands when open (avoids ClipsDescendants clipping)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, CLOSED_H); BackgroundColor3 = theme.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })

	-- Label
	mk("TextLabel", {
		Size = UDim2.new(1, -28, 0, 14); Position = UDim2.fromOffset(14, 6);
		BackgroundTransparency = 1;
		Text = getLabel(data); Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})

	-- Selection box
	local box = mk("TextButton", {
		Size = UDim2.new(1, -28, 0, 30); Position = UDim2.fromOffset(14, 22);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = ""; AutoButtonColor = false; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1 }),
	})
	local valTxt = mk("TextLabel", {
		Size = UDim2.new(1, -32, 1, 0); Position = UDim2.fromOffset(10, 0);
		BackgroundTransparency = 1; Text = tostring(cur);
		Font = Enum.Font.GothamMedium; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = box;
	})
	mk("TextLabel", {
		Size = UDim2.new(0, 24, 1, 0); Position = UDim2.new(1, -26, 0, 0);
		BackgroundTransparency = 1; Text = "▾";
		Font = Enum.Font.GothamBold; TextSize = 14; TextColor3 = theme.TextSub; Parent = box;
	})

	-- Search input (visible when open)
	local searchBox = mk("TextBox", {
		Size = UDim2.new(1, -28, 0, 28); Position = UDim2.fromOffset(14, 56);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		PlaceholderText = "🔍  Search..."; PlaceholderColor3 = theme.TextSub;
		Text = ""; Font = Enum.Font.GothamMedium; TextSize = 12;
		TextColor3 = theme.Text; ClearTextOnFocus = true;
		TextXAlignment = Enum.TextXAlignment.Left;
		Visible = false; ZIndex = 2; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 5) }),
		mk("UIStroke", { Color = theme.BorderSub; Thickness = 1 }),
	})
	local searchPad = Instance.new("UIPadding")
	searchPad.PaddingLeft = UDim.new(0, 10)
	searchPad.Parent = searchBox

	-- Scroll area for items (visible when open)
	local scroll = mk("ScrollingFrame", {
		Size = UDim2.new(1, -28, 0, 0); Position = UDim2.fromOffset(14, 88);
		BackgroundTransparency = 1;
		BorderSizePixel = 0; ScrollBarThickness = 3;
		ScrollBarImageColor3 = theme.AccentDim;
		Visible = false; ZIndex = 2; Parent = f;
	})
	local scrollLayout = mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder; Padding = UDim.new(0, 2); Parent = scroll })

	local api = { Value = cur; Frame = f; Name = data.Title or data.Name or "Dropdown"; Callback = data.Callback }

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
				ZIndex = 3; Parent = scroll;
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
				open = false
				searchBox.Visible = false; scroll.Visible = false
				tw(f, 0.15, { Size = UDim2.new(1, 0, 0, CLOSED_H) })
				if data.Callback then pcall(data.Callback, v) end
			end)
		end
		scroll.CanvasSize = UDim2.fromOffset(0, #filtered * (ITEM_H + 2))
		-- Adjust frame height
		if open then
			local h = CLOSED_H + math.min(#filtered, MAX_VISIBLE) * (ITEM_H + 2) + SEARCH_H + 4
			tw(f, 0.1, { Size = UDim2.new(1, 0, 0, h) })
			scroll.Size = UDim2.new(1, -28, 0, math.min(#filtered, MAX_VISIBLE) * (ITEM_H + 2))
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		searchTerm = searchBox.Text:lower()
		rebuildItems()
	end)

	rebuildItems()

	box.MouseButton1Click:Connect(function()
		if open then
			open = false
			searchBox.Visible = false; scroll.Visible = false
			searchTerm = ""; searchBox.Text = ""
			tw(f, 0.15, { Size = UDim2.new(1, 0, 0, CLOSED_H) })
		else
			open = true
			searchBox.Visible = true; scroll.Visible = true
			searchBox.Text = ""
			rebuildItems()
			local h = calcOpenH()
			tw(f, 0.15, { Size = UDim2.new(1, 0, 0, h) })
			scroll.Size = UDim2.new(1, -28, 0, math.min(#vals, MAX_VISIBLE) * (ITEM_H + 2))
			task.wait(0.05)
			pcall(function() searchBox:CaptureFocus() end)
		end
	end)

	function api:Refresh(v)
		vals = v or {}; searchTerm = ""; searchBox.Text = ""
		rebuildItems()
		-- Auto-select first item if current not in list
		local found = false
		for _, item in ipairs(vals) do
			if tostring(item) == tostring(cur) then found = true; break end
		end
		if not found and #vals > 0 then
			cur = vals[1]; valTxt.Text = tostring(vals[1]); api.Value = vals[1]
		end
	end
	function api:Select(v)
		cur = v; valTxt.Text = tostring(v); api.Value = v
	end
	function api:Set(v) self:Select(v); if self.Callback then pcall(self.Callback, v) end end
	function api:Get() return self.Value end
	reg(data, api)
	return api
end

-- ── Button ─────────────────────────────────────────────────────────────────
function Button(tab, data)
	local theme = th(tab)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 38); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 1, 0); BackgroundColor3 = theme.Surface;
		BorderSizePixel = 0; Text = getLabel(data);
		Font = Enum.Font.GothamMedium; TextSize = 13; TextColor3 = theme.Text;
		AutoButtonColor = false; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 8) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1 }),
	})
	btn.MouseEnter:Connect(function() tw(btn, 0.12, { BackgroundColor3 = theme.Elevated }); btn.UIStroke.Color = theme.AccentDim end)
	btn.MouseLeave:Connect(function() tw(btn, 0.12, { BackgroundColor3 = theme.Surface }); btn.UIStroke.Color = theme.Border end)
	btn.MouseButton1Down:Connect(function() tw(btn, 0.06, { TextColor3 = theme.Accent }) end)
	btn.MouseButton1Up:Connect(function() tw(btn, 0.06, { TextColor3 = theme.Text }) end)
	btn.MouseButton1Click:Connect(function() if data.Callback then pcall(data.Callback) end end)
	return { Frame = f; Name = data.Title or data.Name or "Button" }
end

-- ── Keybind ────────────────────────────────────────────────────────────────
function Keybind(tab, data)
	local theme = th(tab)
	local cur = data.Value or data.Default or "None"
	local capturing = false
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 42); BackgroundColor3 = theme.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	mk("TextLabel", {
		Size = UDim2.new(1, -104, 1, 0); Position = UDim2.fromOffset(14, 0);
		BackgroundTransparency = 1;
		Text = getLabel(data); Font = Enum.Font.GothamMedium; TextSize = 13;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	local kbtn = mk("TextButton", {
		Size = UDim2.fromOffset(84, 28); Position = UDim2.new(1, -96, 0.5, -14);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Text = tostring(cur); Font = Enum.Font.GothamBold; TextSize = 12;
		TextColor3 = theme.Accent; AutoButtonColor = false; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1 }),
	})
	kbtn.MouseButton1Click:Connect(function()
		if capturing then return end
		capturing = true; kbtn.Text = "..."; kbtn.TextColor3 = theme.Accent
		kbtn.UIStroke.Color = theme.AccentDim
	end)
	UIS.InputBegan:Connect(function(i, gp)
		if not capturing then return end
		if gp then return end
		if i.UserInputType == Enum.UserInputType.Keyboard then
			if i.KeyCode == Enum.KeyCode.Escape then
				capturing = false; kbtn.Text = tostring(cur); kbtn.TextColor3 = theme.Accent
				kbtn.UIStroke.Color = theme.Border
			else
				cur = i.KeyCode.Name; capturing = false
				kbtn.Text = cur; kbtn.TextColor3 = theme.Accent
				kbtn.UIStroke.Color = theme.Border
				if data.Callback then pcall(data.Callback, cur) end
			end
		end
	end)
	local api = { Value = cur; Frame = f; Name = data.Title or data.Name or "Keybind"; Callback = data.Callback }
	function api:Set(v) cur = tostring(v); kbtn.Text = cur end
	function api:Get() return cur end
	reg(data, api)
	return api
end

-- ── Input ──────────────────────────────────────────────────────────────────
function Input(tab, data)
	local theme = th(tab)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 58); BackgroundColor3 = theme.Surface;
		BorderSizePixel = 0; LayoutOrder = nextOrder(tab); Parent = tab._page;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	mk("TextLabel", {
		Size = UDim2.new(1, -28, 0, 14); Position = UDim2.fromOffset(14, 6);
		BackgroundTransparency = 1;
		Text = getLabel(data); Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	local stroke = mk("UIStroke", { Color = theme.Border; Thickness = 1 })
	local tb = mk("TextBox", {
		Size = UDim2.new(1, -28, 0, 30); Position = UDim2.fromOffset(14, 22);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		PlaceholderText = data.Placeholder or "";
		Text = data.Value or ""; Font = Enum.Font.GothamMedium; TextSize = 13;
		TextColor3 = theme.Text; PlaceholderColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; ClearTextOnFocus = false;
		Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }),
		stroke,
	})
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 10); pad.Parent = tb
	tb.FocusLost:Connect(function() if data.Callback then pcall(data.Callback, tb.Text) end end)
	tb.Focused:Connect(function() tw(stroke, 0.15, { Color = theme.AccentDim }) end)
	tb.FocusLost:Connect(function() tw(stroke, 0.15, { Color = theme.Border }) end)

	local api = { Value = data.Value or ""; Frame = f; Name = data.Title or data.Name or "Input"; Callback = data.Callback }
	function api:Set(v) self.Value = tostring(v or ""); tb.Text = self.Value end
	function api:Get() return tb.Text end
	reg(data, api)
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
		mk("UIStroke", { Color = theme.Border; Thickness = 1; ZIndex = 100 }),
	})
	mk("Frame", {
		Size = UDim2.new(0, 3, 1, 0); BackgroundColor3 = theme.Accent;
		BorderSizePixel = 0; ZIndex = 101; Parent = n;
	})
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
		tw(n, 0.15, { Position = UDim2.new(1, 300, 0, n.Position.Y.Offset), BackgroundTransparency = 1 })
		task.wait(0.2)
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
