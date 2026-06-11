# Leon X UI v2.0 - Modern Glassmorphism + Neon Theme

## Changelog - UI Improvements

### 🎨 New Theme: "Neon"
- **Deep dark blue backgrounds** (RGB 8,8,12 base)
- **Neon cyan accent** (RGB 0,217,255)
- **Modern glassmorphism** aesthetic
- **Default theme** changed to Neon for better visual appeal

### ✨ Visual Enhancements

#### 1. Glow Effects
- **Animated glow** on window border (pulses between 0.4-0.7 transparency)
- **Pulsing dot** in topbar with cyan glow
- **Search box glow** that intensifies on focus
- **Toggle glow** when active (cyan neon effect)
- **Button glow** on all interactive elements
- **Close button glow** with red accent

#### 2. Improved Animations
- **Bounce animations** (Back easing) for scale effects
- **Smooth hover** with 2px scale up on mouse enter
- **Press animation** with 1px scale down on click
- **Quint easing** for all color transitions (smoother)
- **Pulsing dot** animation (7px ↔ 9px loop)

#### 3. Better Corner Radius
- Increased from **8px → 12px** (rounder, more modern)
- Window border: **14px** radius
- Consistent rounding across all components

#### 4. Enhanced Strokes & Borders
- **30% transparency** on all strokes (softer appearance)
- Animated glow strokes on active elements
- Better visual hierarchy

#### 5. Typography Improvements
- **Text stroke** on titles (0.5 transparency) for depth
- Better readability with improved contrast
- GothamBold font for headers

#### 6. Component Upgrades
- **Toggles**: Glow effect when ON, cyan knob color
- **Buttons**: Subtle glow, better hover feedback
- **Search box**: Focus glow effect
- **Window buttons**: Semi-transparent background (0.2)

### 🎯 How to Use

1. Load Leon X script
2. Go to **Settings Tab**
3. Select **Theme → Neon**
4. Enjoy the modern glassmorphism UI!

### 📊 Performance
- All animations optimized
- Glow effects use task.spawn (non-blocking)
- Minimal performance impact

### 🔧 Technical Details

**New Functions:**
- `twBounce()` - Bounce easing animations
- `glow()` - Animated glow stroke creator
- Enhanced `hvr()` - Scale animations on hover

**Modified Components:**
- mkToggle - Added glow on active state
- mkButton - Added glow effect
- SearchBox - Focus glow animation
- Window border - Animated pulsing glow

### 🎨 Color Palette (Neon Theme)

```lua
BG       = RGB(8, 8, 12)     -- Deep dark
Surface  = RGB(15, 15, 22)   -- Cards
Elevated = RGB(22, 22, 32)   -- Interactive
Border   = RGB(45, 45, 65)   -- Dividers
Accent   = RGB(0, 217, 255)  -- Neon Cyan
Text     = RGB(255, 255, 255) -- Pure White
```

### 🚀 Result

**Before:** Plain, flat, dark theme
**After:** Modern, glowing, neon cyberpunk aesthetic with smooth animations!

---

Created by: Claude Code
Date: June 11, 2026
