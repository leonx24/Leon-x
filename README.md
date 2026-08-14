<div align="center">

# ⚡ Leon X

### Universal Roblox Enhancement Script

*A powerful, modular script framework for Roblox games — works across any game*

![Version](https://img.shields.io/badge/version-0.0.2-blue)
![Platform](https://img.shields.io/badge/platform-Roblox-red)
![Language](https://img.shields.io/badge/language-Lua-purple)
![Modules](https://img.shields.io/badge/modules-35+-green)

</div>

---

## 📖 About

**Leon X** is a universal Roblox enhancement script that works across any game. It provides a comprehensive set of features including movement mods, combat tools, visual overlays, automation, and game-specific modules — all organized in a clean, themed CyberNoir UI with floating sidebar navigation.

- 🔄 **Live updates** — push to `main` branch, changes take effect immediately
- 📱 **Mobile support** — auto-detects touch devices with optimized controls
- 💾 **Config system** — save, load, and auto-load named config snapshots
- ⭐ **Favorites** — star any toggle to pin it to your Quick Access tab
- 🎨 **7 built-in themes** — Default, Gold, Emerald, Rose, Violet, Amber, Neon

No build step, no compiler needed. Just load and play.

---

## ✨ Features

### 🏃 Movement
| Feature | Description |
|---------|-------------|
| **Fly** | Free flight with adjustable speed (10–300), PC & mobile |
| **Speed Hack** | Customizable WalkSpeed (16–250) with continuous enforcement |
| **Jump Power** | Customizable JumpPower (50–500) that persists through state changes |
| **Infinite Jump** | Jump mid-air indefinitely |
| **Noclip** | Walk through walls and objects |
| **Anti-Ragdoll** | Prevent ragdoll physics |
| **Invisible** | Server-side invisibility (CFrame void method) |
| **Free Cam** | Detach camera with adjustable speed |
| **Click Teleport** | Teleport to clicked/tapped locations |
| **Walk on Water** | Walk on water surfaces |
| **Macro Recorder** | Record, save, and playback movement sequences per-map |

### ⚔️ Combat
| Feature | Description |
|---------|-------------|
| **Kill Aura** | Auto-attack nearby enemies with configurable range & CPS |
| **Hitbox Expander** | Visualize and expand hitboxes |
| **Instant Kill** | One-hit elimination (game-dependent) |
| **Quick Switch** | Rapid weapon switching |

### 🛡️ Player
| Feature | Description |
|---------|-------------|
| **Anti-AFK** | Multi-layer idle prevention (VirtualUser + camera + movement) |
| **Anti-Fling** | Protection against velocity-based flinging |
| **Anti-Void** | Teleport back when falling into void |
| **Anti-Detect** | Script destruction defense |
| **God Mode** | Damage immunity (game-dependent) |
| **No Fall Damage** | Immune to fall damage |
| **Infinite Stamina** | Never get tired while running |
| **Avatar Spoofer** | Change your avatar appearance |
| **Gamepass Spoofer** | Spoof gamepass ownership |
| **Rejoin** | Quick rejoin to same server |
| **Server Hop** | Jump to a different server |

### 📍 Teleport
| Feature | Description |
|---------|-------------|
| **Waypoints** | Save, name, and teleport to locations |
| **Waypoint Queue** | Sequential waypoint playback with looping |
| **Teleport to Player** | Robust player lookup with DisplayName support |
| **Save/Load Position** | Quick position save with clipboard copy |

### 👁️ Visual
| Feature | Description |
|---------|-------------|
| **ESP** | See players through walls with health/distance info |
| **Tracer** | Draw lines to players |
| **Fullbright** | Remove all darkness/shadows |
| **Remove Fog** | Clear fog for better visibility |
| **Perf Stats** | Real-time FPS, ping, and memory overlay |
| **Perf Booster** | Reduce lag with potato mode (remove effects, particles, etc.) |

### 🤖 Automation
| Feature | Description |
|---------|-------------|
| **Auto Clicker** | Configurable CPS with random delay anti-detection |
| **Auto Redeem Codes** | Auto-detect and redeem game codes |

### 🎮 Game-Specific
| Game | Features |
|------|----------|
| **Grow a Garden 2** | Auto-farm, auto-water, auto-harvest, and more |
| **Fish and Monsters** | Auto-fish, auto-sell, auto-upgrade |

### 🎬 Macro System
| Feature | Description |
|---------|-------------|
| **Per-Map Storage** | Macros saved per game/map |
| **Queue Playback** | Sequential macro playback with looping |
| **Smooth Playback** | CFrame interpolation for natural movement |
| **Walking Animation** | Triggers proper walk/run animations |

---


## 🎮 Usage

1. **Execute** the loader script in your executor
2. **Wait** for the splash screen to finish loading modules
3. **Toggle UI** with `U` key (or floating button on mobile)
4. **Navigate** through sidebar tabs to find features
5. **Star ⭐** any toggle to pin it to the Favorites tab
6. **Configure** settings via sliders, dropdowns, and keybinds

### Default Keybinds
| Key | Action |
|-----|--------|
| `U` | Toggle UI visibility |
| `Delete` | Panic key — disable all features + hide UI |
| `N` | Toggle Noclip |
| `G` | Teleport to selected waypoint |
| `C` | Toggle Auto Clicker |
| `X` | Start/stop waypoint queue |
| `H` | Toggle Hitbox Expander |

---



## ⚙️ Configuration

### Saving & Loading Configs
All settings are saved via the built-in **Config Manager**. Configs are stored at:
```
Leon X/configs/<config_name>.json
```

Features:
- **Save** — snapshot all current toggle/slider/keybind values
- **Load** — restore a saved configuration
- **Auto-Load** — set a default config that loads on startup
- **Delete** — remove old configs

### Favorites Persistence
Starred features are saved to `Leon X/favorites.json` and restored on next load.

---

## 🎯 Supported Executors

Leon X works with most modern executors that support:
- `loadstring` / `game:HttpGet`
- `writefile` / `readfile` / `isfile`
- `isfolder` / `makefolder` / `listfiles` / `delfile`
- `getcustomasset` (for custom logo)
- `VirtualUser` (for anti-AFK)

---

## 📱 Mobile Support

The UI is fully responsive with:
- Touch-friendly toggle buttons and sliders
- Floating minimize/maximize button
- Auto-detection of mobile devices (`TouchEnabled and not KeyboardEnabled`)
- Mobile-specific fly controls (on-screen D-pad)

---

## 🛠️ Development

### Adding a New Module

1. Create `modules/<category>/<name>.lua`:
```lua
local Module = {}
Module.Name = "MyModule"
Module.Enabled = false

function Module:Enable()
    if self.Enabled then return end
    self.Enabled = true
    -- activate feature
end

function Module:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    -- cleanup: disconnect connections, destroy instances
end

function Module:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Module
```

2. Wire it in `main.lua`:
```lua
-- Load with splash progress
local MyModule = load("modules/<category>/<name>.lua"); setSplashProgress(0.XX)

-- Add toggle in the appropriate tab
local myToggle = Tab:Toggle({
    Title    = "My Feature",
    Value    = false,
    Callback = function(v)
        if v then MyModule:Enable() else MyModule:Disable() end
    end
})
```

### Module Guidelines
- All modules use `pcall()` defensively around Roblox API calls
- Cleanup must nil every connection and destroy every instance
- Anti-detection: use `HttpService:GenerateGUID()` for instance names in visual modules
- Mobile detection: `UIS.TouchEnabled and not UIS.KeyboardEnabled`

---

## 📝 Changelog

### v0.0.2 (Current)
- 🔧 Fixed Anti-AFK connection leak — Idled connection now properly disconnected
- 🔧 Fixed Anti-AFK reliability — reduced interval, added character movement nudge
- 🔧 Fixed Invisible — rewritten with server-side CFrame void method (truly invisible to other players)
- 🔧 Fixed Speed/JumpPower resetting on sit/crouch/cutscene — continuous Heartbeat enforcement + StateChanged listener
- 🔧 Fixed Favorites star not showing in sidebar — dynamic favorites system with persistence
- 🔧 Fixed Teleport to Player "not found" — robust lookup matching both Name and DisplayName, auto-refresh player list
- ✅ Dropdown now shows "DisplayName (@Username)" for clarity
- ✅ Favorites saved to file (`Leon X/favorites.json`) and restored on boot
- ✅ Player list auto-refreshes when players join/leave

### v0.0.1
- ✅ Initial release with 35+ modules
- ✅ CyberNoir UI with floating sidebar navigation
- ✅ 7 built-in color themes
- ✅ Config save/load system
- ✅ Game-specific modules (Grow a Garden 2, Fish and Monsters)
- ✅ Macro recorder with per-map storage and queue playback
- ✅ Mobile support with touch-optimized UI

---

## ⚠️ Disclaimer

This script is for **educational purposes only**. Use at your own risk. We are not responsible for any bans or consequences from using this script.

---

## 📄 License

This project is provided as-is for educational and research purposes.

---

<div align="center">

**Made with ⚡ by the Leon X Team**

*If you found this useful, consider giving a ⭐ star!*

</div>
