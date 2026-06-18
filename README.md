<div align="center">

# ⚡ Leon X

### Universal Roblox Enhancement Script

*A powerful, modular script framework for Roblox games*

![Version](https://img.shields.io/badge/version-1.6-blue)
![Platform](https://img.shields.io/badge/platform-Roblox-red)
![Language](https://img.shields.io/badge/language-Lua-purple)

</div>

---

## 📖 About

**Leon X** is a universal Roblox script that works across any game. It provides a comprehensive set of features including movement mods, combat enhancements, visual overlays, and automation tools — all organized in a clean, tabbed UI.

No build step, no compiler needed. Just load and play.

---

## ✨ Features

### 🏃 Movement
| Feature | Description |
|---------|-------------|
| **Fly** | Free flight with adjustable speed |
| **Speed Hack** | Customizable walk speed multiplier |
| **Infinite Jump** | Jump mid-air indefinitely |
| **Noclip** | Walk through walls and objects |
| **Anti-Ragdoll** | Prevent ragdoll physics |
| **Invisible** | Become invisible to other players |
| **Free Cam** | Detach camera for cinematic views |
| **Click Teleport** | Teleport to clicked locations |
| **Walk on Water** | Walk on water surfaces |
| **Macro Recorder** | Record and playback movement sequences |

### ⚔️ Combat
| Feature | Description |
|---------|-------------|
| **Kill Aura** | Auto-attack nearby enemies |
| **Hitbox Expander** | Visualize and expand hitboxes |
| **Instant Kill** | One-hit elimination (game-dependent) |

### 🛡️ Player
| Feature | Description |
|---------|-------------|
| **Anti-AFK** | Prevent idle kick (always on) |
| **Anti-Fling** | Enhanced protection against being flung |
| **Anti-Void** | Teleport back when falling into void |
| **God Mode** | Damage immunity (game-dependent) |
| **No Fall Damage** | Immune to fall damage |
| **Infinite Stamina** | Never get tired |
| **Rejoin** | Quick rejoin to same server |
| **Server Hop** | Jump to a different server |
| **Waypoints** | Save and teleport to locations |

### 👁️ Visual
| Feature | Description |
|---------|-------------|
| **ESP** | See players through walls |
| **Tracer** | Draw lines to players |
| **Fullbright** | Remove all darkness/shadows |
| **Remove Fog** | Clear fog for better visibility |
| **Perf Stats** | Real-time performance overlay |

### 🤖 Automation
| Feature | Description |
|---------|-------------|
| **Auto Clicker** | Configurable CPS with anti-detection |
| **Auto Redeem Codes** | Auto-detect and redeem game codes |

### 🎮 Macro System
| Feature | Description |
|---------|-------------|
| **Per-Map Storage** | Macros saved per game/map |
| **Queue Playback** | Sequential macro playback with looping |
| **Smooth Playback** | CFrame interpolation for natural movement |
| **Walking Animation** | Triggers proper walk/run animations |

---

## 🚀 Installation

### Method 1: Direct Load
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/leonx24/Leon-x/main/loader.lua"))()
```

### Method 2: With Cache Busting
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/leonx24/Leon-x/main/loader.lua?t=" .. os.time()))()
```

---

## 🎮 Usage

1. **Execute** the loader script in your executor
2. **Wait** for the splash screen to finish loading
3. **Toggle UI** with `U` key (or minimize button on mobile)
4. **Navigate** through tabs to find features
5. **Configure** settings via sliders and toggles

### Keybinds
| Key | Action |
|-----|--------|
| `U` | Toggle UI visibility |
| `End` | Panic key (disable all + hide UI) |

---

## 📁 Project Structure

```
Leon X/
├── loader.lua              # Entry point (loads main.lua)
├── main.lua                # Core script (UI + module loading)
├── version.txt             # Version number
│
├── modules/                # Feature modules
│   ├── movements/          # Fly, speed, noclip, macro, etc.
│   ├── combat/             # Kill aura, hitbox expander
│   ├── player/             # Anti-fling, god mode, waypoints
│   ├── visuals/            # ESP, tracer, fullbright
│   ├── auto/               # Auto clicker, redeem codes
│   ├── core/               # Config manager
│   └── games/              # Game-specific modules
│
└── tools/                  # Diagnostic utilities
    ├── fling_scanner.lua   # Scan game for fling mechanics
    └── fling_monitor.lua   # Monitor velocity during flings
```

---

## ⚙️ Configuration

### Saving Configs
All settings are automatically saved via `ConfigManager`. Configs are stored in:
```
Leon X/configs/<config_name>.json
```

### Auto-Load
The script automatically loads your default config on startup.

---

## 🎯 Supported Executors

Leon X works with most modern executors that support:
- `loadstring`
- `game:HttpGet`
- `writefile` / `readfile`
- `isfolder` / `makefolder`

---

## 📱 Mobile Support

The UI is fully responsive with:
- Touch-friendly controls
- Minimize/float button for small screens
- Auto-detection of mobile devices

---

## 🛠️ Development

### Adding a New Module

1. Create `modules/<category>/<name>.lua`:
```lua
local Module = {}
Module.Name = "MyModule"
Module.Enabled = false

function Module:Enable()
    -- activate feature
end

function Module:Disable()
    -- cleanup
end

function Module:Toggle()
    if self.Enabled then self:Disable() else self:Enable() end
end

return Module
```

2. Wire it in `main.lua`:
```lua
local MyModule = load("modules/<category>/<name>.lua")

local toggle = Tab:AddToggle({
    Title = "My Feature",
    Callback = function(v)
        if v then MyModule:Enable() else MyModule:Disable() end
    end
})
```

---

## 📝 Changelog

### v1.6 (Current)
- ✅ Added Auto Clicker with configurable CPS
- ✅ Added Anti-Void protection
- ✅ Enhanced Anti-Fling with mass manipulation
- ✅ Per-map macro storage
- ✅ Macro queue system with sequential playback
- ✅ Reorganized UI into 8 focused tabs

### v1.5
- ✅ Macro Recorder with smooth playback
- ✅ Kill Aura and Auto Redeem Codes
- ✅ Walk on Water feature
- ✅ Server Hop support

---

## ⚠️ Disclaimer

This script is for **educational purposes only**. Use at your own risk. We are not responsible for any bans or consequences from using this script.

---

## 📄 License

This project is provided as-is for educational and research purposes.

---

<div align="center">

**Made with ⚡ by the Leon X Team**

*If you found this useful, consider giving a star!*

</div>
