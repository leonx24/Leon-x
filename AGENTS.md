# AGENTS.md

This file provides guidance to Qoder (qoder.com) when working with code in this repository.

## Project Overview

Leon X is a Roblox game enhancement script written in Lua. It is loaded remotely via `loadstring(game:HttpGet(...))` from GitHub — there is no build step, compiler, or test runner. All code runs inside the Roblox executor environment.

**Deployment**: Push changes to the `main` branch on GitHub. Users run `loader.lua` which fetches `main.lua` with a cache-busting timestamp. Live updates take effect immediately on next load.

## Entry Point & Load Sequence

`loader.lua` → fetches `main.lua` → `main.lua` loads all modules via HTTP with `?t=os.time()` cache busting → wires UI → boots.

All modules are fetched from `https://raw.githubusercontent.com/leonx24/Leon-x/main/` at runtime. The `load(path)` helper in `main.lua` is the standard way to fetch and execute a remote file.

Splash screen progress is advanced by calling `setSplashProgress(0.0–1.0)` (local function in main.lua) after each module load. When adding a new module, redistribute splash values so they still span 0→1.

## Module Pattern

Every feature module follows this exact interface:

```lua
local Module = {}
Module.Name    = "ModuleName"
Module.Enabled = false
-- optional state: Module.Speed, Module.Color, etc.

function Module:Enable()  -- activate, create connections/instances end
function Module:Disable() -- cleanup, nil all connections/instances end
function Module:Toggle()  -- if self.Enabled then self:Disable() else self:Enable() end
-- setters: Module:SetSpeed(v), Module:SetColor(c), etc.

return Module
```

All modules use `pcall()` defensively around every Roblox API call. Cleanup must nil every connection and destroy every instance to prevent leaks.

## UI System (`ui/library.lua`)

- `Library.Registry[Flag]` maps Flag strings to component APIs `{ Get, Set, Callback }`. This is how ConfigManager saves/loads all settings.
- `Library._allComponents` powers the global search.
- Adding a component: create a function (e.g. `function MyComp(tab, data)`), call `reg(data, api)` to register, attach via `tab.MyComp = function(d) return MyComp(tab, d) end` inside `win:Tab()`.
- Themes are defined in the `Library.Themes` table inside `library.lua`. Each theme has keys: `BG, Surface, Elevated, Border, BorderSub, Accent, AccentDim, Text, TextSub`.
- Available built-in themes: Default, Gold, Emerald, Rose, Violet, Amber, Neon.
- All components accept `Title` as the label parameter (not `Name`).

## Wiring a Module into `main.lua`

```lua
-- 1. Load the module (with splash progress increment)
local NewMod = load("modules/<category>/<name>.lua"); setSplashProgress(0.XX)

-- 2. Add a toggle on the relevant tab
local newToggle = Tab:Toggle({ Title="Feature", Flag="FeatureFlag", Value=false,
    Callback=function(v) if v then NewMod:Enable() else NewMod:Disable() end end })

-- 3. For a keybind that must stay in sync with the toggle:
local featureKey = Enum.KeyCode.X
UIS.InputBegan:Connect(function(i, gp)
    if gp or i.KeyCode ~= featureKey then return end
    local s = not NewMod.Enabled
    newToggle:Set(s)  -- MUST call :Set() to keep UI state in sync
    if s then NewMod:Enable() else NewMod:Disable() end
end)
```

## Config System (`modules/core/configmanager.lua`)

- Saves named snapshots of all `Library.Registry` values to `Leon X/configs/<name>.json` using executor filesystem APIs (`writefile`, `readfile`, `isfolder`, `makefolder`, `listfiles`, `delfile`).
- `ConfigManager:AutoLoad()` runs at boot; loads `.default` pointer file or `"default"` config.
- `api:Set(val)` is silent — ConfigManager explicitly fires `api.Callback` after loading so modules actually activate.
- Keybinds are serialized as `EnumItem.Name` strings and deserialized back via `Enum.KeyCode[val]`.

## Key Architecture Notes

- **No local execution**: scripts cannot be run locally with `lua main.lua`. All testing must be done inside a Roblox executor.
- **Mobile detection**: `local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled` — used in fly.lua and should be used in any new module with platform-specific behavior.
- **Anti-detection in ESP**: instance names use `HttpService:GenerateGUID()` — maintain this pattern in visual modules.
- **Version**: `version.txt` is the single source of truth. Both `main.lua` and `library.lua` fetch it on boot. Bump it when releasing.
- **Panic key** (default: `Delete`): disables all active toggles and hides the window — must not interfere with module cleanup logic.
- **Notification helper** in `main.lua`: `local function N(t,m,d) Library:Notify({Title=t,Content=m,Duration=d or 2}) end`

## Adding a New Module (checklist)

1. Create `modules/<category>/<name>.lua` following the module pattern above.
2. In `main.lua`, add a `load(...)` call with a `setSplashProgress(...)` call immediately after; redistribute progress values from the last module to 1.0.
3. Add the corresponding `Tab:Toggle(...)` (and sliders/dropdowns as needed) in the appropriate tab section.
4. If a keybind is needed, add `UIS.InputBegan:Connect(...)` and call `toggle:Set(s)` inside it.

## Adding a New UI Component Type

1. In `ui/library.lua`, create `function NewComponent(tab, data)` following the pattern of `Toggle`, `Slider`, etc.
2. Inside `win:Tab()`, attach `tab.NewComponent = function(d) return NewComponent(tab, d) end`.
3. Call `reg(data, api)` inside the function if `d.Flag` exists.
