# Leon X — UI System

## Overview

The entire UI is built inside `ui/library.lua` — a self-contained engine that constructs a `ScreenGui` on load and exposes a `Library` table. No external dependencies. No `require()`.

## Window Structure

The window uses two overlapping frames to achieve a clean rounded border without `UIStroke` artifacts:

```
BG  (C.Border color, radius R, size 662×422)   ← border layer
Win (C.BG color,     radius R, size 660×420)   ← actual window, ClipsDescendants=true
```

`Win.ClipsDescendants = true` clips the square corners of Sidebar and Content to the rounded window shape. `UIStroke` is NOT used on `Win` because stroke renders outside the clip boundary and creates rectangle artifacts at corners.

**Critical rule**: any element that must overflow `Win` (dropdown lists, window buttons, resize handle) must be parented to `Screen` (the ScreenGui), not to `Win`.

## Layout Zones

```
Win (660×420)
├── Top      (full width, 46px tall)     — topbar
├── Side     (152px wide, height-46)     — sidebar
│    └── SideScroll                      — scrollable tab list
└── Content  (width-153, height-46)      — page area
     └── page (ScrollingFrame per tab)   — scrollable content
```

## Color Palette (C table in library.lua)

| Key | RGB | Usage |
|---|---|---|
| `BG` | 11,11,11 | Window background |
| `Surface` | 17,17,17 | Sidebar, card backgrounds |
| `Elevated` | 23,23,23 | Component backgrounds (toggle, button, slider) |
| `Border` | 36,36,36 | Strokes, dividers |
| `Accent` | 255,255,255 | Active indicator bar, slider fill, knob |
| `Dim` | 130,130,130 | Secondary values, dimmed icons |
| `Text` | 228,228,228 | Primary text |
| `Sub` | 95,95,95 | Inactive tab labels, section text |
| `OffTrack` | 44,44,44 | Toggle track off state |
| `OnTrack` | 195,195,195 | Toggle track on state |
| `Hover` | 29,29,29 | Mouse hover state |
| `Press` | 38,38,38 | Mouse press state |
| `Red` | 170,40,40 | Close button |
| `RedH` | 205,58,58 | Close button hover |

`ui/themes.lua` defines a separate `Themes` table (Dark + Midnight) but is **not currently imported** by `library.lua`. The library uses its own inline `C` table.

## Component API

Every component constructor returns an `api` table with at minimum a `Frame` field pointing to the root instance. Components that hold state also expose `Set` and `Get`.

```lua
-- Toggle
local t = Tab:AddToggle({ Name="Fly", Default=false, Callback=fn })
t:Set(true)   -- programmatic set (silent, no callback)
t:Get()       -- returns current boolean

-- Slider
local s = Tab:AddSlider({ Name="Speed", Min=0, Max=100, Default=50, Suffix="%" })
s:Set(75)
s:Get()       -- returns current number

-- Dropdown
local d = Tab:AddDropdown({ Name="Color", Options={"Red","Blue"}, Default="Red" })
d:Set("Blue")
d:Get()       -- returns current string

-- Button (no state)
local b = Tab:AddButton({ Name="Rejoin", Callback=fn })
b:SetText("New Label")

-- Keybind
local k = Tab:AddKeybind({ Name="Fly Key", Default=Enum.KeyCode.F, Callback=fn })
k:Get()       -- returns current KeyCode

-- ColorPicker
local cp = Tab:AddColorPicker({ Name="Color", Default=Color3.fromRGB(255,0,0) })
cp:Set(Color3.fromRGB(0,255,0))
cp:Get()      -- returns current Color3

-- Label (display only)
local l = Tab:AddLabel({ Text="Info", Color=Color3.fromRGB(100,100,100) })
l:Set("Updated text")

-- Section (no api, just visual divider)
Tab:AddSection("Section Name")
```

## Tab System

`Library:CreateTab(name)` creates a sidebar button + a `ScrollingFrame` page inside `Content`. Returns a `Tab` table with all `Add*` methods.

The first tab created is activated immediately (no tween, no defer) via the `Library._first` flag. Subsequent tabs start hidden. Clicking a tab button runs `activate()` which hides all pages and shows the selected one with a 0.15s tween.

## Dropdown Floating List

Dropdown lists are parented to `Screen` (ZIndex 20) and positioned using `w.AbsolutePosition` at open time. They animate height from 0 to `fullH` via tween. `ClipsDescendants = true` on the list itself clips items cleanly during the height animation. An `UIS.InputBegan` listener closes the list on outside click.

## Animation Conventions

All animations use `TweenService` with `Enum.EasingStyle.Quint, Enum.EasingDirection.Out` via the local `tw(object, time, properties)` helper. Standard durations:

| Interaction | Duration |
|---|---|
| Hover in | 0.12s |
| Hover out | 0.15s |
| Press | 0.06s |
| Toggle switch | 0.18s |
| Tab switch | 0.15s |
| Dropdown open | 0.20s |
| Dropdown close | 0.15s |
| Slider knob | 0.05s |

## Helper Functions (library-internal)

| Function | Purpose |
|---|---|
| `tw(o, t, p)` | TweenService wrapper |
| `rnd(p, r)` | Add UICorner to parent |
| `strk(p, col)` | Add UIStroke to parent |
| `pdg(p, t, l, r, b)` | Add UIPadding to parent |
| `mkF(parent, bg)` | Create Frame |
| `mkL(parent, txt, sz, col, font, xa)` | Create TextLabel |
| `hvr(b, normal, hover, press)` | Wire hover/press color tweens |
