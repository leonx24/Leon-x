-- Leon X | Themes
-- Monochrome dark palette — clean, premium, minimal

local Themes = {}

Themes.Dark = {
    BG        = Color3.fromRGB(10,  10,  10),   -- main window background
    Surface   = Color3.fromRGB(16,  16,  16),   -- sidebar, cards
    Elevated  = Color3.fromRGB(22,  22,  22),   -- components (toggle, button)
    Hover     = Color3.fromRGB(28,  28,  28),   -- hover state
    Active    = Color3.fromRGB(34,  34,  34),   -- pressed state
    Border    = Color3.fromRGB(32,  32,  32),   -- primary borders
    BorderSub = Color3.fromRGB(26,  26,  26),   -- subtle borders
    Accent    = Color3.fromRGB(255, 255, 255),  -- white accent (active indicator, knob)
    AccentDim = Color3.fromRGB(160, 160, 160),  -- dimmed accent
    Text      = Color3.fromRGB(240, 240, 240),  -- primary text
    TextSub   = Color3.fromRGB(130, 130, 130),  -- secondary text
    SwitchOff = Color3.fromRGB(38,  38,  38),   -- toggle track off
    SwitchOn  = Color3.fromRGB(220, 220, 220),  -- toggle track on
}

-- Future theme slot (e.g. midnight blue tint)
Themes.Midnight = {
    BG        = Color3.fromRGB(8,   9,   14),
    Surface   = Color3.fromRGB(12,  13,  20),
    Elevated  = Color3.fromRGB(18,  20,  30),
    Hover     = Color3.fromRGB(24,  26,  38),
    Active    = Color3.fromRGB(30,  33,  48),
    Border    = Color3.fromRGB(30,  34,  52),
    BorderSub = Color3.fromRGB(22,  25,  38),
    Accent    = Color3.fromRGB(120, 160, 255),
    AccentDim = Color3.fromRGB(80,  110, 200),
    Text      = Color3.fromRGB(230, 235, 255),
    TextSub   = Color3.fromRGB(100, 110, 150),
    SwitchOff = Color3.fromRGB(30,  34,  52),
    SwitchOn  = Color3.fromRGB(120, 160, 255),
}

return Themes
