# Leon X — Architecture

## Execution Flow

```
loader.lua
  └─ HttpGet → main.lua
       ├─ HttpGet → ui/library.lua   (UI engine, returns Library table)
       ├─ HttpGet → modules/movements/fly.lua  (returns Fly table)
       └─ inline feature wiring (callbacks, game service calls)
```

Everything runs as a Roblox LocalScript executed by an exploit executor. There is no `require()` — all files are fetched from GitHub via `game:HttpGet()` and executed with `loadstring()`.

## Deployment Model

- **Source of truth**: GitHub repo `leonx24/Leon-x` (main branch)
- **Entry point for users**: paste `loader.lua` content into executor
- **loader.lua** is a one-liner that fetches and runs `main.lua`
- **main.lua** fetches and runs `library.lua` and individual module files
- Any local file change must be pushed to GitHub to take effect in Roblox

## Layer Responsibilities

| Layer | Files | Responsibility |
|---|---|---|
| Entry | `loader.lua` | Bootstrap — single HttpGet call |
| App | `main.lua` | Tab/feature wiring, game logic callbacks |
| UI Engine | `ui/library.lua` | Window, sidebar, all components |
| Modules | `modules/**/*.lua` | Self-contained feature logic |
| Core (partial) | `core/*.lua` | Shared utilities (mostly stubs) |
| Config | `ui/themes.lua`, `config/settings.lua` | Palette and settings data |

## Current Architecture Gap

`main.lua` currently wires features **inline** (game service calls directly in callbacks) rather than delegating to module files. The `core/modulemanager.lua` system exists and is well-designed but is not yet connected to `main.lua`. The intended architecture is:

```
main.lua
  └─ Library:CreateTab(...)
       └─ Tab:AddToggle({ Callback = function(v) ModuleManager:Toggle("Fly") end })

ModuleManager
  └─ Modules["Fly"] = Fly  (registered on load)
       └─ Fly:Enable() / Fly:Disable()
```

## Instance Hierarchy (Runtime)

```
PlayerGui
  └─ ScreenGui "LeonX"
       ├─ Frame "BG"          (border layer, behind Win)
       ├─ Frame "Win"         (main window, ClipsDescendants=true)
       │    ├─ Frame (Topbar)
       │    ├─ Frame (Sidebar)
       │    │    └─ ScrollingFrame (tab buttons)
       │    └─ Frame (Content)
       │         └─ ScrollingFrame (page, one per tab)
       ├─ TextButton (BtnX)   (close, on Screen not Win)
       ├─ TextButton (BtnM)   (minimize, on Screen not Win)
       ├─ TextButton (ResBtn) (resize handle, on Screen not Win)
       ├─ TextButton (Float)  (minimized pill)
       └─ Frame (dropdown List, one per dropdown, on Screen)
```

Window controls and dropdown lists are parented directly to `ScreenGui` (not inside `Win`) to avoid being clipped by `Win.ClipsDescendants = true`.
