# Leon X - Feature Priority Roadmap

> Last Updated: 2026-06-10

---

## 🔴 **HIGH PRIORITY** (Do Next Week)

### **1. Config Import/Export** ⭐⭐⭐
**Impact:** HIGH | **Effort:** LOW (1-2 hours) | **Viral:** YES

- Export current settings as base64 string
- Import from string → restore all settings
- Users can share configs in Discord/YouTube comments
- One-click copy/paste workflow

**Implementation:**
```lua
Set:AddButton({ Name="📋 Export Config", Callback=function()
    local encoded = ConfigMgr:ExportBase64()
    setclipboard(encoded)
    N("Exported", "Config copied!", "success")
end})

Set:AddButton({ Name="📥 Import Config", Callback=function()
    local encoded = getclipboard()
    if ConfigMgr:ImportBase64(encoded) then
        N("Imported", "Config loaded!", "success")
    end
end})
```

**Why:** Community engagement, easy sharing

---

### **2. FOV Changer** ⭐⭐
**Impact:** MEDIUM | **Effort:** LOW (1 hour) | **Common:** YES

- Slider for Camera.FieldOfView (60-120)
- Persistent setting
- Real-time preview

**Implementation:**
```lua
Vis:AddSlider({ Name="Camera FOV", Flag="FOV", Min=60, Max=120, Default=70,
    Callback=function(v)
        workspace.CurrentCamera.FieldOfView = v
    end })
```

**Why:** Common request, simple feature, high UX

---

### **3. Hitbox Expander** ⭐⭐
**Impact:** HIGH | **Effort:** LOW (1.5 hours) | **Combat:** YES

- Expand HumanoidRootPart size for easier hits
- Slider: 1x - 5x multiplier
- Can toggle on/off instantly

**Implementation:**
```lua
-- modules/combat/hitbox.lua
local originalSize = char:FindFirstChild("HumanoidRootPart").Size
hrp.Size = originalSize * multiplier
```

**Why:** Combat viability, easy to implement

---

### **4. Waypoint System** ⭐⭐
**Impact:** MEDIUM | **Effort:** MEDIUM (3 hours) | **QoL:** HIGH

- Save multiple named waypoints
- List of saved waypoints with delete
- Teleport to any waypoint via button
- Shows distance to waypoint in real-time

**Implementation:**
```lua
-- modules/player/waypoints.lua
Waypoints = {
    spawn = Vector3.new(0, 50, 0),
    farm = Vector3.new(100, 50, 0),
    safe = Vector3.new(-50, 100, 0)
}

Ply:AddButton({ Name="💾 Save Waypoint", ... })
Ply:AddDropdown({ Name="Teleport to", Options={"spawn","farm","safe"}, ... })
```

**Why:** Better teleport UX, QoL improvement

---

## 🟡 **MEDIUM PRIORITY** (Do in 2 Weeks)

### **5. Aimbot / Silent Aim** ⭐⭐⭐
**Impact:** HIGH | **Effort:** HIGH (4-6 hours) | **Game-Dependent:** YES

- Lock onto nearest player
- Smooth aim assist (lerp to target)
- Silent aim (don't rotate camera)
- Configurable: detection range, smoothness
- Whitelist/blacklist players

**Why:** Major combat feature, but highly game-specific

---

### **6. Chat Spammer** ⭐
**Impact:** MEDIUM | **Effort:** LOW (1 hour) | **Utility:** YES

- Spam message with delay
- Message templates
- Stop button

```lua
-- modules/player/chatspammer.lua
Ply:AddTextInput({ Name="Message", ... })
Ply:AddSlider({ Name="Delay", Min=1, Max=60, Default=5, Suffix="s" })
Ply:AddButton({ Name="Start Spam", ... })
Ply:AddButton({ Name="Stop Spam", ... })
```

**Why:** Trolling/utility, simple to add

---

### **7. Server Hop Automation** ⭐
**Impact:** MEDIUM | **Effort:** MEDIUM (2-3 hours) | **Utility:** YES

- Auto-join new server when server full
- Find player across servers
- Auto-rejoin when kicked

**Why:** Multiplayer experience, useful for farming

---

### **8. Performance Tracker Detail** ⭐
**Impact:** LOW | **Effort:** MEDIUM (2-3 hours) | **Debug:** YES

- Memory usage per module
- FPS impact of each feature
- Network ping display
- Connection quality indicator

**Why:** Help users optimize their setup

---

## 🟢 **LOW PRIORITY** (Nice to Have)

### **9. Macro Recorder** ⭐
**Impact:** MEDIUM | **Effort:** HIGH (5+ hours) | **Advanced:** YES

- Record mouse/keyboard inputs
- Replay action sequences
- Save/load macros

**Why:** Power users only, complex implementation

---

### **10. Script Hub** ⭐⭐
**Impact:** HIGH | **Effort:** VERY HIGH (8+ hours) | **Extensibility:** YES

- Execute custom Lua scripts
- Community script library
- Script permissions system
- Auto-update scripts

**Why:** Long-term extensibility, but major undertaking

---

### **11. Command Console** ⭐
**Impact:** MEDIUM | **Effort:** MEDIUM (3-4 hours) | **UX:** YES

- Chat command system: `/fly`, `/tp @player`, `/speed 100`
- Command history (up/down arrows)
- Auto-complete suggestions

**Why:** Alternative control method, power users

---

### **12. Player Manager** ⭐
**Impact:** MEDIUM | **Effort:** LOW (2 hours) | **QoL:** YES

- List all players with roles
- Friend/enemy marking
- Block player (ignore ESP/Tracer)
- Quick teleport/attack buttons

**Why:** Better multiplayer experience

---

### **13. Keybind Conflict Detection** ⭐
**Impact:** LOW | **Effort:** LOW (1 hour) | **QoL:** YES

- Warn when two features use same keybind
- Auto-suggest alternative binds
- Keybind profiles

**Why:** Quality of life, prevent user errors

---

### **14. Custom Themes** ⭐
**Impact:** LOW | **Effort:** MEDIUM (2-3 hours) | **Cosmetic:** YES

- Theme editor (colors, transparency, fonts)
- Save/load custom themes
- Import themes from code

**Why:** Customization, cosmetic feature

---

---

## 📊 **Priority Matrix**

```
HIGH EFFORT, HIGH IMPACT:
  - Script Hub
  - Aimbot/Silent Aim

LOW EFFORT, HIGH IMPACT:
  ✅ Config Import/Export (1-2 hrs)
  ✅ FOV Changer (1 hr)
  ✅ Hitbox Expander (1.5 hrs)
  ✅ Chat Spammer (1 hr)
  ✅ Player Manager (2 hrs)

LOW EFFORT, MEDIUM IMPACT:
  - Waypoint System (3 hrs)
  - Server Hop (2-3 hrs)
  - Keybind Conflicts (1 hr)

MEDIUM EFFORT, MEDIUM IMPACT:
  - Performance Tracker (2-3 hrs)
  - Command Console (3-4 hrs)
  - Custom Themes (2-3 hrs)

HIGH EFFORT, MEDIUM IMPACT:
  - Macro Recorder (5+ hrs)
```

---

## 🎯 **Recommended Implementation Order**

### **Week 1 (Next 5 days)** - Quick Wins
1. ✅ **Config Import/Export** (1-2 hrs)
2. ✅ **FOV Changer** (1 hr)
3. ✅ **Hitbox Expander** (1.5 hrs)
4. ✅ **Chat Spammer** (1 hr)
5. ✅ **Player Manager** (2 hrs)

**Total:** ~6.5 hours | **Impact:** 5 new features

---

### **Week 2** - Medium Complexity
1. **Waypoint System** (3 hrs)
2. **Performance Tracker** (2-3 hrs)
3. **Server Hop Automation** (2-3 hrs)

**Total:** ~7-9 hours | **Impact:** 3 medium features

---

### **Week 3+** - Advanced
1. **Aimbot/Silent Aim** (4-6 hrs, game-specific)
2. **Command Console** (3-4 hrs)
3. **Script Hub** (8+ hrs, long-term)

---

## 📈 **Expected Growth**

| After Week 1 | Features | Estimated Users |
|---|---|---|
| Now | 15 features | ~500 users |
| Week 1 | +5 features (20 total) | ~1,000 users |
| Week 2 | +3 features (23 total) | ~2,000 users |
| Week 3+ | +3+ features (26+ total) | ~5,000+ users |

---

## ✅ **Completed (v1.1)**
- ✅ Anti-detection hardening
- ✅ Error handling & safety
- ✅ Respawn cleanup
- ✅ Auto-update checker
- ✅ Mobile virtual controls

**Total effort:** ~10 hours | **Quality:** Production-ready

---

**Last Updated:** 2026-06-10  
**Suggested Next Action:** Start Week 1 quick wins
