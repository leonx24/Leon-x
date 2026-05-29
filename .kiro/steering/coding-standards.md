# Leon X — Coding Standards

## Language & Runtime

- **Language**: Lua 5.1 (Roblox Luau dialect)
- **Runtime**: Roblox executor environment — no `require()`, no file I/O, no standard Lua libs
- **Inter-file loading**: always `loadstring(game:HttpGet(RAW_GITHUB_URL))()`
- **Services**: always `game:GetService("ServiceName")` — never `game.ServiceName`

## Naming Conventions

### Variables & Functions
```lua
-- locals: camelCase
local flySpeed = 60
local function updateSlider(pct) end

-- module-level tables: PascalCase
local Fly = {}
local Library = {}

-- constants / palette keys: ALL_CAPS or short uppercase
local C = { BG = ..., Text = ... }
local KEYS = { [Enum.KeyCode.W] = ... }
```

### Module fields
```lua
Module.Name    = "Fly"     -- PascalCase string
Module.Enabled = false     -- boolean state flag
```

### UI helper functions (library.lua)
Short 2–3 char names are acceptable inside `library.lua` because they are local and used heavily:
```lua
local function tw(o,t,p)  end  -- tween
local function rnd(p,r)   end  -- corner
local function strk(p,c)  end  -- stroke
local function pdg(p,...) end  -- padding
local function mkF(p,bg)  end  -- make Frame
local function mkL(p,...) end  -- make Label
local function hvr(b,...) end  -- hover wiring
```
Outside `library.lua`, use descriptive names.

## Module Structure

Every module in `modules/` must follow this exact shape:

```lua
local Module = {}

Module.Name    = "ModuleName"
Module.Enabled = false

function Module:Enable()
    self.Enabled = true
    -- 1. validate character exists
    -- 2. create instances / connect events
    -- 3. store connections/instances as upvalues for cleanup
end

function Module:Disable()
    self.Enabled = false
    -- 1. disconnect all RBXScriptConnections
    -- 2. destroy all created Instances
    -- 3. restore any modified properties
end

function Module:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Module
```

**Cleanup is mandatory.** Every `Enable` must have a corresponding full cleanup in `Disable`. Store connections and instances as upvalues:

```lua
local conn   -- RBXScriptConnection
local bv     -- BodyVelocity instance

function Module:Enable()
    bv = Instance.new("BodyVelocity")
    conn = RunService.RenderStepped:Connect(function() ... end)
end

function Module:Disable()
    if conn then conn:Disconnect(); conn = nil end
    if bv   then bv:Destroy();     bv   = nil end
end
```

## Component Data Tables

UI component constructors take a single `data` table. All fields are optional with sensible defaults:

```lua
Tab:AddToggle({
    Name     = "string",           -- display label
    Default  = false,              -- initial state (boolean)
    Callback = function(v) end,    -- called with new value on change
})

Tab:AddSlider({
    Name     = "string",
    Min      = 0,
    Max      = 100,
    Default  = 0,
    Suffix   = "",                 -- appended to value display e.g. "%"
    Callback = function(v) end,    -- called with number
})

Tab:AddDropdown({
    Name     = "string",
    Options  = {},                 -- array of strings
    Default  = nil,                -- defaults to Options[1]
    Callback = function(v) end,    -- called with selected string
})

Tab:AddKeybind({
    Name     = "string",
    Default  = Enum.KeyCode.Unknown,
    Callback = function(key) end,  -- called with KeyCode on rebind
})

Tab:AddColorPicker({
    Name     = "string",
    Default  = Color3.fromRGB(255,255,255),
    Callback = function(c) end,    -- called with Color3
})

Tab:AddButton({
    Name     = "string",
    Callback = function() end,
})

Tab:AddLabel({
    Text  = "string",
    Color = Color3,                -- optional, defaults to C.Sub
    Align = Enum.TextXAlignment,   -- optional, defaults to Left
})
```

## Callback Safety

Always guard against missing character in movement callbacks:

```lua
-- correct
Callback = function(v)
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = v
end

-- wrong — will error if character not loaded
Callback = function(v)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
end
```

## Global State

Use `_G` only for state that must persist across module reloads or be accessible from multiple callbacks. Prefix with the feature name to avoid collisions:

```lua
_G.InfJump     = false
_G.AntiAFK     = false
_G.AntiAFKConn = nil    -- store connection for cleanup
```

Prefer upvalues over `_G` whenever the state is only needed within one module file.

## UI Rules

- **Never parent overflow elements to `Win`** — dropdown lists, window buttons, and resize handle must be parented to `Screen` (the ScreenGui)
- **Never use `UIStroke` on `Win`** — stroke renders outside `ClipsDescendants` boundary, causing rectangle artifacts at corners
- **Border effect**: use a separate frame behind `Win` with identical corner radius, sized 2px larger on each side
- **`BorderSizePixel = 0`** on every Frame and TextButton — always
- **`AutoButtonColor = false`** on every TextButton — always; handle hover/press manually via `hvr()`
- **Corner radius**: 10px for components (toggle, button, slider), 9px for tab buttons, 7px for small elements (keybind pill), 4px for tiny dots

## Animation Rules

- All tweens use `Enum.EasingStyle.Quint, Enum.EasingDirection.Out`
- Use the `tw(object, time, properties)` helper inside `library.lua`
- Never tween `Visible` — set it directly; tween `BackgroundTransparency` or `Size` instead
- Dropdown open/close: tween `Size` height, use `ClipsDescendants = true` on the list frame to clip items during animation

## Error Handling

Wrap destructive operations in `pcall`:

```lua
-- destroying old GUI on reload
pcall(function() gui:FindFirstChild("LeonX"):Destroy() end)
```

Do not use `pcall` around normal game logic — let errors surface during development.

## File Header

Every module file should start with a comment block:

```lua
-- Leon X | Module Name
-- Brief description of what this module does
```

## What to Avoid

- `require()` — not available in executor context
- `script.Parent` paths — not available when loaded via `loadstring`
- `wait()` — use `task.wait()` instead
- `spawn()` — use `task.spawn()` instead
- `delay()` — use `task.delay()` instead
- Hardcoded `game.Players.LocalPlayer.Character` without nil check
- Connecting to `RunService.RenderStepped` without storing the connection for cleanup
- Multiple `UIS.InputBegan` connections for the same feature — accumulates on each toggle
