-- Leon X | Noir UI Library
-- "Quiet luxury" — dark elegant minimalism with disciplined motion.
-- Design: muted silver-blue accent (default), precision typography, no neon.
--
-- CUSTOMIZATION:
--   Library:SetTheme("Gold")     -- or Emerald, Rose, Violet, Amber, Neon
--   Library.Themes["MyTheme"] = { Accent = Color3.fromRGB(r,g,b), AccentDim = ... }

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

-- Icon name → Unicode symbol map (main.lua passes icon names, not symbols)
local ICONS = {
	["user"]            = "\u{F4FA}",
	["settings"]        = "\u{2699}",
	["eye"]             = "\u{F133}",
	["zap"]             = "\u{26A1}",
	["radio"]           = "\u{F4E3}",
	["map-pin"]         = "\u{F34E}",
	["swords"]          = "\u{2694}",
	["person-standing"] = "\u{F484}",
	["gamepad-2"]       = "\u{F472}",
	["shield"]          = "\u{F3ED}",
	["heart"]           = "\u{2665}",
	["star"]            = "\u{2605}",
	["home"]            = "\u{F47B}",
	["compass"]         = "\u{F3C5}",
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
-- NOTIFICATION GUI (created early, used by Library:Notify)
-- ════════════════════════════════════════════════════════════════════════════

local notifGui = mk("ScreenGui", {
	Name = "LeonXNotif"; ResetOnSpawn = false;
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	DisplayOrder = 9998; IgnoreGuiInset = true;
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
	local size      = cfg.Size or UDim2.new(0, 580, 0, 560)
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
		ClipsDescendants = true; Parent = sg;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 6) }) })

	local mainStroke = mk("UIStroke", { Color = theme.Border; Thickness = 1; Parent = main })

	-- ── Sidebar ──
	local sidebar = mk("Frame", {
		Size = UDim2.new(0, 44, 1, 0); Position = UDim2.fromOffset(0, 0);
		BackgroundColor3 = theme.BG; BorderSizePixel = 0; Parent = main;
	})
	mk("Frame", {
		Size = UDim2.new(0, 1, 1, 0); Position = UDim2.new(1, 0, 0, 0);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; Parent = sidebar;
	})
	local logo = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 44); Position = UDim2.fromOffset(0, 0);
		BackgroundTransparency = 1; Text = "X";
		Font = Enum.Font.GothamBold; TextSize = 18;
		TextColor3 = theme.Accent; Parent = sidebar;
	})

	-- ── Header ──
	local header = mk("Frame", {
		Size = UDim2.new(1, -44, 0, 40); Position = UDim2.fromOffset(44, 0);
		BackgroundColor3 = theme.Surface; BorderSizePixel = 0; Parent = main;
	})
	mk("Frame", {
		Size = UDim2.new(1, 0, 0, 1); Position = UDim2.new(0, 0, 1, -1);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; Parent = header;
	})
	mk("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0); Position = UDim2.fromOffset(14, 0);
		BackgroundTransparency = 1; Text = title;
		Font = Enum.Font.GothamBold; TextSize = 15; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = header;
	})
	if author ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(0, 100, 1, 0); Position = UDim2.new(1, -110, 0, 0);
			BackgroundTransparency = 1; Text = author;
			Font = Enum.Font.Gotham; TextSize = 11; TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Right; Parent = header;
		})
	end

	local minBtn = mk("TextButton", {
		Size = UDim2.fromOffset(24, 24); Position = UDim2.new(1, -56, 0.5, -12);
		BackgroundTransparency = 1; Text = "—";
		Font = Enum.Font.GothamBold; TextSize = 14; TextColor3 = theme.TextSub;
		AutoButtonColor = false; Parent = header;
	})
	local minContentVisible = true
	minBtn.MouseButton1Click:Connect(function()
		minContentVisible = not minContentVisible
		tw(main, 0.15, { Size = minContentVisible and size or UDim2.new(0, size.X.Offset, 0, 40) })
	end)

	local closeBtn = mk("TextButton", {
		Size = UDim2.fromOffset(24, 24); Position = UDim2.new(1, -30, 0.5, -12);
		BackgroundTransparency = 1; Text = "✕";
		Font = Enum.Font.GothamBold; TextSize = 13; TextColor3 = theme.TextSub;
		AutoButtonColor = false; Parent = header;
	})

	local content = mk("ScrollingFrame", {
		Size = UDim2.new(1, -44, 1, -40); Position = UDim2.fromOffset(44, 40);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 3; ScrollBarImageColor3 = theme.Border;
		CanvasSize = UDim2.fromOffset(0, 0);
		ClipsDescendants = true; Parent = main;
	})
	local contentLayout = mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder; Padding = UDim.new(0, 0); Parent = content })
	-- Fallback canvas size (AutomaticCanvasSize may not exist on all executors)
	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		content.CanvasSize = UDim2.fromOffset(0, contentLayout.AbsoluteContentSize.Y + 20)
	end)
	pcall(function() content.AutomaticCanvasSize = Enum.AutomaticSize.Y end)

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
	floatBtn.MouseButton1Click:Connect(function() win:Open() end)

	-- ── Close / Open ──
	function win:Close()
		self._visible = false
		tw(main, 0.15, { BackgroundTransparency = 1 })
		task.wait(0.15)
		main.Visible = false; floatBtn.Visible = true
	end
	function win:Open()
		main.Visible = true; floatBtn.Visible = false
		self._visible = true; main.BackgroundTransparency = 1
		tw(main, 0.2, { BackgroundTransparency = 0 })
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
	function win:SetToggleKey(k) self._toggleKey = k end
	function win:SetTheme(name)
		local t = Library.Themes[name]
		if not t then return end
		self._theme = t; self._themeName = name
		Library._lastTheme = name
		main.BackgroundColor3 = t.BG; mainStroke.Color = t.Border
		sidebar.BackgroundColor3 = t.BG; header.BackgroundColor3 = t.Surface
		logo.TextColor3 = t.Accent; floatBtn.TextColor3 = t.Accent
		floatBtn.BackgroundColor3 = t.Surface
		for _, conn in ipairs(Library._themeConns) do pcall(function() conn(t) end) end
	end

	UIS.InputBegan:Connect(function(i, gp)
		if gp or i.KeyCode ~= self._toggleKey then return end
		if self._visible then self:Close() else self:Open() end
	end)

	-- ── TAB ────────────────────────────────────────────────────────────────
	local tabList = mk("Frame", {
		Size = UDim2.new(1, 0, 1, -44); Position = UDim2.fromOffset(0, 44);
		BackgroundTransparency = 1; Parent = sidebar;
	})

	function win:Tab(cfg)
		cfg = cfg or {}
		local tabName = cfg.Title or cfg.Name or "Tab"
		local icon = ICONS[cfg.Icon] or cfg.Icon or "◆"
		local tab = { Name = tabName; _layoutOrder = 0; _components = {} }
		local idx = #self._tabs + 1

		local btn = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 38);
			Position = UDim2.fromOffset(0, (idx - 1) * 42);
			BackgroundTransparency = 1; Text = icon;
			Font = Enum.Font.Gotham; TextSize = 16;
			TextColor3 = self._theme.TextSub; AutoButtonColor = false;
			Parent = tabList;
		})
		local indicator = mk("Frame", {
			Size = UDim2.new(0, 2, 0, 20); Position = UDim2.new(0, 0, 0.5, -10);
			BackgroundColor3 = self._theme.Accent; BorderSizePixel = 0;
			Visible = false; Parent = btn;
		}, { mk("UICorner", { CornerRadius = UDim.new(0, 1) }) })

		-- Use a plain Frame (not ScrollingFrame) — parent content frame handles scroll
		local page = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0); BackgroundTransparency = 1;
			Visible = false; Parent = content;
		})
		local layout = mk("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder; Padding = UDim.new(0, 6); Parent = page;
		})
		mk("UIPadding", {
			PaddingTop = UDim.new(0, 10); PaddingBottom = UDim.new(0, 10);
			PaddingLeft = UDim.new(0, 12); PaddingRight = UDim.new(0, 12);
			Parent = page;
		})
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end)

		local isActive = false
		local function setActive(active)
			isActive = active
			indicator.Visible = active
			btn.TextColor3 = active and self._theme.Text or self._theme.TextSub
			if active then
				page.Visible = true; page.LayoutOrder = 0
				for _, c in ipairs(tab._components) do c.Visible = true end
			else
				page.Visible = false; page.LayoutOrder = 999
				for _, c in ipairs(tab._components) do c.Visible = false end
			end
		end

		btn.MouseButton1Click:Connect(function()
			for _, t in ipairs(self._tabs) do t._setActive(false) end
			setActive(true); self._active = tab
		end)
		btn.MouseEnter:Connect(function()
			if not isActive then btn.BackgroundTransparency = 0.9; btn.BackgroundColor3 = self._theme.Surface end
		end)
		btn.MouseLeave:Connect(function()
			if not isActive then btn.BackgroundTransparency = 1 end
		end)

		tab._setActive = setActive; tab._page = page; tab._win = win
		self._tabs[#self._tabs + 1] = tab
		if idx == 1 then setActive(true) end

		-- Attach component methods (auto-register frames for tab visibility)
		local function wrap(fn)
			return function(d)
				local r = fn(tab, d)
				if r and r.Frame then tab._components[#tab._components + 1] = r.Frame end
				return r
			end
		end
		tab.Section   = function(d)
			Section(tab, d)
			-- Section doesn't return an api, so we grab the last child of page
			local children = tab._page:GetChildren()
			tab._components[#tab._components + 1] = children[#children]
		end
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
	return win
end

-- ════════════════════════════════════════════════════════════════════════════
-- THEME HELPER (resolve theme from tab → window)
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
	local theme = th(tab)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 26); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	if tab._layoutOrder > 1 then
		mk("Frame", {
			Size = UDim2.new(1, 0, 0, 1); BackgroundColor3 = theme.BorderSub;
			BorderSizePixel = 0; Position = UDim2.fromOffset(0, 2); Parent = f;
		})
	end
	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16); Position = UDim2.fromOffset(0, 8);
		BackgroundTransparency = 1;
		Text = (data.Title or ""):upper();
		Font = Enum.Font.GothamBold; TextSize = 11;
		TextColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
end

-- ── Paragraph ──────────────────────────────────────────────────────────────
function Paragraph(tab, data)
	local theme = th(tab)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 40); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	if data.Title then
		mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14); BackgroundTransparency = 1;
			Text = data.Title; Font = Enum.Font.Gotham; TextSize = 12;
			TextColor3 = theme.TextSub;
			TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
		})
	end
	local cl = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18); Position = UDim2.fromOffset(0, data.Title and 16 or 0);
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
	local theme = th(tab)
	local val = data.Value ~= nil and data.Value or (data.Default ~= nil and data.Default or false)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 32); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	mk("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0); BackgroundTransparency = 1;
		Text = data.Title or data.Name or ""; Font = Enum.Font.Gotham; TextSize = 13;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	local track = mk("Frame", {
		Size = UDim2.fromOffset(38, 20); Position = UDim2.new(1, -38, 0.5, -10);
		BackgroundColor3 = val and theme.Accent or theme.Border; BorderSizePixel = 0; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	local knob = mk("Frame", {
		Size = UDim2.fromOffset(16, 16);
		Position = val and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8);
		BackgroundColor3 = theme.Text; BorderSizePixel = 0; Parent = track;
	}, { mk("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local api = { Value = val; Frame = f; Name = data.Title or data.Name or "Toggle"; Callback = data.Callback }
	function api:Set(v)
		v = not not v
		if self.Value == v then return end
		self.Value = v
		tw(track, 0.15, { BackgroundColor3 = v and theme.Accent or theme.Border })
		tw(knob, 0.15, { Position = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) })
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
		Size = UDim2.new(1, 0, 0, 46); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	mk("TextLabel", {
		Size = UDim2.new(1, -60, 0, 16); BackgroundTransparency = 1;
		Text = data.Title or data.Name or ""; Font = Enum.Font.Gotham; TextSize = 13;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	local valLbl = mk("TextLabel", {
		Size = UDim2.new(0, 50, 0, 16); Position = UDim2.new(1, -50, 0, 0);
		BackgroundTransparency = 1; Text = tostring(df);
		Font = Enum.Font.Code; TextSize = 12; TextColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Right; Parent = f;
	})
	local trk = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 4); Position = UDim2.new(0, 0, 0, 28);
		BackgroundColor3 = theme.Border; BorderSizePixel = 0; Parent = f;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 2) }) })
	local fill = mk("Frame", {
		Size = UDim2.new((df - mn) / math.max(mx - mn, 1), 0, 1, 0);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; Parent = trk;
	}, { mk("UICorner", { CornerRadius = UDim.new(0, 2) }) })
	local knob = mk("Frame", {
		Size = UDim2.fromOffset(14, 14);
		Position = UDim2.new((df - mn) / math.max(mx - mn, 1), -7, 0.5, -7);
		BackgroundColor3 = theme.Accent; BorderSizePixel = 0; Parent = trk;
	}, { mk("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local function upd(v)
		local pct = math.clamp((v - mn) / math.max(mx - mn, 1), 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, -7, 0.5, -7)
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

-- ── Dropdown ───────────────────────────────────────────────────────────────
function Dropdown(tab, data)
	local theme = th(tab)
	local vals = data.Values or {}
	local cur = data.Value or (vals[1] or "")
	if type(cur) == "number" and vals[cur] then cur = vals[cur] end
	local open = false

	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 52); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page; ClipsDescendants = false;
	})
	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14); BackgroundTransparency = 1;
		Text = data.Title or data.Name or ""; Font = Enum.Font.Gotham; TextSize = 12;
		TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	local box = mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 30); Position = UDim2.fromOffset(0, 16);
		BackgroundColor3 = theme.Surface; BorderSizePixel = 0;
		Text = ""; AutoButtonColor = false; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 4) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1 }),
	})
	local valTxt = mk("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0); Position = UDim2.fromOffset(8, 0);
		BackgroundTransparency = 1; Text = tostring(cur);
		Font = Enum.Font.Gotham; TextSize = 12; TextColor3 = theme.Text;
		TextXAlignment = Enum.TextXAlignment.Left; Parent = box;
	})
	mk("TextLabel", {
		Size = UDim2.new(0, 24, 1, 0); Position = UDim2.new(1, -24, 0, 0);
		BackgroundTransparency = 1; Text = "▾";
		Font = Enum.Font.Gotham; TextSize = 14; TextColor3 = theme.TextSub; Parent = box;
	})

	local list = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0); Position = UDim2.fromOffset(0, 48);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		Visible = false; ZIndex = 5; ClipsDescendants = true; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 4) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1 }),
	})
	local scroll = mk("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0); BackgroundTransparency = 1;
		BorderSizePixel = 0; ScrollBarThickness = 2;
		ScrollBarImageColor3 = theme.Border; ZIndex = 5; Parent = list;
	})
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder; Parent = scroll })

	local function refreshItems()
		for _, c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for i, v in ipairs(vals) do
			local item = mk("TextButton", {
				Size = UDim2.new(1, 0, 0, 32); BackgroundTransparency = 1;
				Text = "  " .. tostring(v); Font = Enum.Font.Gotham; TextSize = 12;
				TextColor3 = tostring(v) == tostring(cur) and theme.Accent or theme.Text;
				TextXAlignment = Enum.TextXAlignment.Left; AutoButtonColor = false;
				ZIndex = 5; LayoutOrder = i; Parent = scroll;
			})
			item.MouseEnter:Connect(function() item.BackgroundColor3 = theme.Elevated; item.BackgroundTransparency = 0.5 end)
			item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
			item.MouseButton1Click:Connect(function()
				cur = v; valTxt.Text = tostring(v)
				open = false; tw(list, 0.12, { Size = UDim2.new(1, 0, 0, 0) })
				task.delay(0.12, function() list.Visible = false end)
				if data.Callback then pcall(data.Callback, v) end
			end)
		end
		scroll.CanvasSize = UDim2.fromOffset(0, #vals * 32)
	end
	refreshItems()

	box.MouseButton1Click:Connect(function()
		if open then
			open = false; tw(list, 0.12, { Size = UDim2.new(1, 0, 0, 0) })
			task.delay(0.12, function() list.Visible = false end)
		else
			open = true; list.Visible = true
			local h = math.min(#vals, 6) * 32
			tw(list, 0.12, { Size = UDim2.new(1, 0, 0, h) })
		end
	end)

	local api = { Value = cur; Frame = f; Name = data.Title or data.Name or "Dropdown"; Callback = data.Callback }
	function api:Refresh(v) vals = v or {}; refreshItems() end
	function api:Select(v) cur = v; valTxt.Text = tostring(v) end
	function api:Set(v) self:Select(v); if self.Callback then pcall(self.Callback, v) end end
	function api:Get() return self.Value end
	reg(data, api)
	return api
end

-- ── Button ─────────────────────────────────────────────────────────────────
function Button(tab, data)
	local theme = th(tab)
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 34); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	local btn = mk("TextButton", {
		Size = UDim2.new(1, 0, 1, 0); BackgroundColor3 = theme.Surface;
		BorderSizePixel = 0; Text = data.Title or data.Name or "Button";
		Font = Enum.Font.Gotham; TextSize = 13; TextColor3 = theme.Text;
		AutoButtonColor = false; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1 }),
	})
	btn.MouseEnter:Connect(function() tw(btn, 0.1, { BackgroundColor3 = theme.Elevated }); btn.UIStroke.Color = theme.AccentDim end)
	btn.MouseLeave:Connect(function() tw(btn, 0.1, { BackgroundColor3 = theme.Surface }); btn.UIStroke.Color = theme.Border end)
	btn.MouseButton1Down:Connect(function() tw(btn, 0.05, { TextColor3 = theme.Accent }) end)
	btn.MouseButton1Up:Connect(function() tw(btn, 0.05, { TextColor3 = theme.Text }) end)
	btn.MouseButton1Click:Connect(function() if data.Callback then pcall(data.Callback) end end)
	return { Frame = f; Name = data.Title or data.Name or "Button" }
end

-- ── Keybind ────────────────────────────────────────────────────────────────
function Keybind(tab, data)
	local theme = th(tab)
	local cur = data.Value or data.Default or "None"
	local capturing = false
	local f = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 32); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	mk("TextLabel", {
		Size = UDim2.new(1, -90, 1, 0); BackgroundTransparency = 1;
		Text = data.Title or data.Name or ""; Font = Enum.Font.Gotham; TextSize = 13;
		TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	local kbtn = mk("TextButton", {
		Size = UDim2.fromOffset(80, 26); Position = UDim2.new(1, -80, 0.5, -13);
		BackgroundColor3 = theme.Surface; BorderSizePixel = 0;
		Text = tostring(cur); Font = Enum.Font.Code; TextSize = 12;
		TextColor3 = theme.TextSub; AutoButtonColor = false; Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 4) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1 }),
	})
	kbtn.MouseButton1Click:Connect(function()
		if capturing then return end
		capturing = true; kbtn.Text = "..."; kbtn.TextColor3 = theme.Accent
	end)
	UIS.InputBegan:Connect(function(i, gp)
		if not capturing then return end
		if gp then return end
		if i.UserInputType == Enum.UserInputType.Keyboard then
			if i.KeyCode == Enum.KeyCode.Escape then
				capturing = false; kbtn.Text = tostring(cur); kbtn.TextColor3 = theme.TextSub
			else
				cur = i.KeyCode.Name; capturing = false
				kbtn.Text = cur; kbtn.TextColor3 = theme.TextSub
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
		Size = UDim2.new(1, 0, 0, 50); BackgroundTransparency = 1;
		LayoutOrder = nextOrder(tab); Parent = tab._page;
	})
	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14); BackgroundTransparency = 1;
		Text = data.Title or data.Name or ""; Font = Enum.Font.Gotham; TextSize = 12;
		TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left; Parent = f;
	})
	local stroke = mk("UIStroke", { Color = theme.Border; Thickness = 1 })
	local tb = mk("TextBox", {
		Size = UDim2.new(1, 0, 0, 30); Position = UDim2.fromOffset(0, 16);
		BackgroundColor3 = theme.Surface; BorderSizePixel = 0;
		PlaceholderText = data.Placeholder or "";
		Text = data.Value or ""; Font = Enum.Font.Gotham; TextSize = 13;
		TextColor3 = theme.Text; PlaceholderColor3 = theme.TextSub;
		TextXAlignment = Enum.TextXAlignment.Left; ClearTextOnFocus = false;
		Parent = f;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 4) }),
		stroke,
	})
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 8); pad.Parent = tb
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
		Size = UDim2.new(0, 280, 0, 60);
		Position = UDim2.new(1, 300, 0, 16 + #activeNotifs * 68);
		BackgroundColor3 = theme.Elevated; BorderSizePixel = 0;
		ClipsDescendants = true; Parent = notifGui;
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }),
		mk("UIStroke", { Color = theme.Border; Thickness = 1 }),
	})
	mk("Frame", {
		Size = UDim2.new(0, 3, 1, 0); BackgroundColor3 = theme.Accent;
		BorderSizePixel = 0; Parent = n;
	})
	if title ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(1, -16, 0, 18); Position = UDim2.fromOffset(12, 6);
			BackgroundTransparency = 1; Text = title;
			Font = Enum.Font.GothamBold; TextSize = 13;
			TextColor3 = theme.Text; TextXAlignment = Enum.TextXAlignment.Left; Parent = n;
		})
	end
	if text ~= "" then
		mk("TextLabel", {
			Size = UDim2.new(1, -16, 0, 18);
			Position = UDim2.fromOffset(12, title ~= "" and 24 or 6);
			BackgroundTransparency = 1; Text = text;
			Font = Enum.Font.Gotham; TextSize = 12;
			TextColor3 = theme.TextSub; TextXAlignment = Enum.TextXAlignment.Left;
			TextWrapped = true; Parent = n;
		})
	end

	activeNotifs[#activeNotifs + 1] = n
	tw(n, 0.2, { Position = UDim2.new(1, -296, 0, 16 + (#activeNotifs - 1) * 68) })

	task.delay(dur, function()
		tw(n, 0.15, { BackgroundTransparency = 1 })
		task.wait(0.15)
		for i, v in ipairs(activeNotifs) do
			if v == n then table.remove(activeNotifs, i) break end
		end
		for i, v in ipairs(activeNotifs) do
			tw(v, 0.15, { Position = UDim2.new(1, -296, 0, 16 + (i - 1) * 68) })
		end
		task.wait(0.15)
		n:Destroy()
	end)
end

return Library
