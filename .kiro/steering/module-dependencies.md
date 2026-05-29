# Leon X — Module Dependencies

## Dependency Graph

```
loader.lua
  └── HttpGet ──► main.lua
                    ├── HttpGet ──► ui/library.lua
                    │                 (no external deps, self-contained)
                    │
                    └── HttpGet ──► modules/movements/fly.lua
                                      ├── Players (Roblox service)
                                      ├── UserInputService (Roblox service)
                                      └── RunService (Roblox service)
```

No file uses `require()`. All inter-file dependencies are resolved via `loadstring(game:HttpGet(...))()` at runtime.

## File Status

| File | Status | Notes |
|---|---|---|
| `loader.lua` | ✅ Complete | One-liner bootstrap |
| `main.lua` | ✅ Complete | All features wired inline |
| `ui/library.lua` | ✅ Complete | Full UI engine v4.1 |
| `ui/themes.lua` | ✅ Defined | Not imported by library.lua |
| `modules/movements/fly.lua` | ✅ Complete | BodyVelocity + BodyGyro |
| `modules/movements/speed.lua` | ⚠️ Stub | Empty module shell |
| `modules/movements/infinitejump.lua` | ⚠️ Stub | Empty module shell |
| `modules/player/antiafk.lua` | ⚠️ Stub | Empty module shell |
| `modules/player/rejoin.lua` | ⚠️ Stub | Empty module shell |
| `modules/visuals/esp.lua` | ⚠️ Stub | Empty module shell |
| `modules/visuals/fullbright.lua` | ⚠️ Stub | Empty module shell |
| `core/modulemanager.lua` | ✅ Defined | Not wired to main.lua |
| `core/animations.lua` | ✅ Defined | Not used by library.lua |
| `core/services.lua` | ✅ Defined | Not imported anywhere |
| `core/state.lua` | ✅ Defined | Not imported anywhere |
| `core/notifications.lua` | ⚠️ Skeleton | print-only stub |
| `core/notify.lua` | ❌ Empty | — |
| `core/init.lua` | ❌ Empty | — |
| `core/module.lua` | ❌ Empty | — |
| `core/utils.lua` | ❌ Empty | — |
| `core/config.lua` | ❌ Empty | — |
| `config/settings.lua` | ❌ Empty | — |
| `ui/components/*.lua` | ⚠️ Legacy | Old component files, superseded by library.lua |
| `ui/pages/*.lua` | ❌ Empty | — |

## Module Contract

Every module file must follow this interface so `core/modulemanager.lua` can manage it:

```lua
local Module = {}

Module.Name    = "ModuleName"   -- string key for ModuleManager
Module.Enabled = false          -- current state

function Module:Enable()
    self.Enabled = true
    -- setup logic
end

function Module:Disable()
    self.Enabled = false
    -- cleanup logic (disconnect events, destroy instances)
end

function Module:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Module
```

Optional methods modules can expose:
- `Module:SetSpeed(n)` — for movement modules with configurable speed
- `Module:SetColor(c)` — for visual modules with configurable color
- `Module:SetOpacity(n)` — for visual modules with configurable opacity

## Roblox Services Used

| Service | Used In |
|---|---|
| `Players` | library.lua, fly.lua, main.lua |
| `UserInputService` | library.lua, fly.lua, main.lua |
| `TweenService` | library.lua |
| `RunService` | fly.lua |
| `Lighting` | main.lua (FullBright inline) |
| `TeleportService` | main.lua (Rejoin inline) |
| `VirtualUser` | main.lua (Anti AFK inline) |

`core/services.lua` pre-caches all of these but is not currently imported anywhere.

## What Needs Wiring

To connect the existing `core/modulemanager.lua` to `main.lua`:

```lua
-- in main.lua, after loading modules:
local ModuleManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/leonx24/Leon-x/main/core/modulemanager.lua"
))()

ModuleManager:Register(Fly)

-- then in callbacks:
Callback = function(v) ModuleManager:Toggle("Fly") end
```

To connect `core/services.lua`:

```lua
local Services = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/leonx24/Leon-x/main/core/services.lua"
))()
-- use Services.Players instead of game:GetService("Players")
```
