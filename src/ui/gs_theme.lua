-- Runtime dark-glass palette for April's draw-only UI.
-- Vector exposes alpha + rounded primitives, but no backdrop blur or custom fonts.
local M = {}
local settings_ref = April.require("core.settings")
local last_sync_frame = -1

M.DENSITY_NAMES = { "Compact", "Balanced", "Comfortable" }
M.CORNER_NAMES = { "Sharp", "Soft", "Rounded" }

-- Each preset: bg / panel / raised surfaces + accent, with optional text tints.
local PRESETS = {
    {
        name = "Violet Glass",
        bg = { 0.028, 0.026, 0.042 }, panel = { 0.068, 0.058, 0.098 },
        raised = { 0.108, 0.088, 0.148 }, accent = { 0.76, 0.28, 0.98 },
        text = { 0.86, 0.82, 0.96 }, text_dim = { 0.52, 0.48, 0.62 },
    },
    {
        name = "Midnight Blue",
        bg = { 0.018, 0.032, 0.058 }, panel = { 0.042, 0.072, 0.118 },
        raised = { 0.062, 0.108, 0.168 }, accent = { 0.28, 0.72, 1.00 },
        text = { 0.78, 0.88, 0.98 }, text_dim = { 0.42, 0.54, 0.68 },
    },
    {
        name = "Graphite",
        bg = { 0.032, 0.033, 0.038 }, panel = { 0.072, 0.074, 0.082 },
        raised = { 0.112, 0.116, 0.126 }, accent = { 0.78, 0.80, 0.86 },
        text = { 0.90, 0.91, 0.93 }, text_dim = { 0.50, 0.52, 0.56 },
    },
    {
        name = "Emerald Glass",
        bg = { 0.016, 0.038, 0.034 }, panel = { 0.038, 0.088, 0.072 },
        raised = { 0.055, 0.128, 0.102 }, accent = { 0.22, 0.94, 0.64 },
        text = { 0.78, 0.96, 0.88 }, text_dim = { 0.40, 0.58, 0.50 },
    },
    {
        name = "Crimson Ember",
        bg = { 0.048, 0.018, 0.020 }, panel = { 0.095, 0.040, 0.042 },
        raised = { 0.145, 0.062, 0.055 }, accent = { 1.00, 0.32, 0.28 },
        text = { 0.98, 0.84, 0.82 }, text_dim = { 0.62, 0.42, 0.40 },
    },
    {
        name = "Arctic Frost",
        bg = { 0.020, 0.028, 0.040 }, panel = { 0.048, 0.062, 0.082 },
        raised = { 0.078, 0.098, 0.122 }, accent = { 0.55, 0.88, 1.00 },
        text = { 0.88, 0.94, 1.00 }, text_dim = { 0.48, 0.58, 0.68 },
    },
    {
        name = "Amber Noir",
        bg = { 0.042, 0.028, 0.016 }, panel = { 0.088, 0.062, 0.036 },
        raised = { 0.132, 0.098, 0.055 }, accent = { 1.00, 0.72, 0.28 },
        text = { 0.98, 0.92, 0.78 }, text_dim = { 0.62, 0.52, 0.34 },
    },
    {
        name = "Sakura Night",
        bg = { 0.036, 0.020, 0.036 }, panel = { 0.082, 0.048, 0.078 },
        raised = { 0.128, 0.078, 0.118 }, accent = { 1.00, 0.48, 0.72 },
        text = { 0.98, 0.86, 0.92 }, text_dim = { 0.62, 0.46, 0.56 },
    },
    {
        name = "Ocean Abyss",
        bg = { 0.012, 0.036, 0.048 }, panel = { 0.032, 0.078, 0.098 },
        raised = { 0.048, 0.118, 0.142 }, accent = { 0.18, 0.92, 0.88 },
        text = { 0.76, 0.96, 0.96 }, text_dim = { 0.36, 0.58, 0.60 },
    },
    {
        name = "Copper Dust",
        bg = { 0.038, 0.030, 0.026 }, panel = { 0.082, 0.066, 0.054 },
        raised = { 0.124, 0.100, 0.078 }, accent = { 0.92, 0.55, 0.32 },
        text = { 0.96, 0.88, 0.78 }, text_dim = { 0.58, 0.48, 0.38 },
    },
    {
        name = "Neon Lime",
        bg = { 0.018, 0.028, 0.016 }, panel = { 0.040, 0.068, 0.038 },
        raised = { 0.062, 0.105, 0.055 }, accent = { 0.62, 1.00, 0.18 },
        text = { 0.88, 0.98, 0.78 }, text_dim = { 0.46, 0.60, 0.36 },
    },
    {
        name = "Royal Indigo",
        bg = { 0.022, 0.022, 0.055 }, panel = { 0.050, 0.052, 0.112 },
        raised = { 0.078, 0.080, 0.165 }, accent = { 0.48, 0.52, 1.00 },
        text = { 0.84, 0.86, 1.00 }, text_dim = { 0.46, 0.48, 0.68 },
    },
}

M.PRESET_NAMES = {}
for i = 1, #PRESETS do
    M.PRESET_NAMES[i] = PRESETS[i].name
end

local function clamp(v, a, b)
    v = tonumber(v) or a
    if v < a then return a end
    if v > b then return b end
    return v
end

local function rgb(c, alpha)
    return { c[1], c[2], c[3], alpha == nil and 1 or alpha }
end

local function mix_rgb(a, b, t, alpha)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        alpha == nil and 1 or alpha,
    }
end

local function setting(id, fallback)
    local ok, value = pcall(settings_ref.get, id, fallback)
    if ok and value ~= nil then return value end
    return fallback
end

local function scaled(v, scale)
    return math.max(1, math.floor(v * scale + 0.5))
end

M.RAINBOW = {
    { 0.20, 0.90, 0.95, 1 },
    { 0.55, 0.35, 0.95, 1 },
    { 0.95, 0.85, 0.20, 1 },
    { 0.95, 0.35, 0.55, 1 },
    { 0.35, 0.95, 0.45, 1 },
}

local ALPHA_KEYS = {
    "BG", "BG_INNER", "PANEL", "PANEL_ALT", "PANEL_RAISED", "OVERLAY",
    "SHADOW", "SHADOW_DEEP", "GLASS_HIGHLIGHT", "BORDER", "BORDER_SOFT",
    "BORDER_HOT", "SIDEBAR", "SIDEBAR_ACTIVE", "TEXT", "TEXT_DIM",
    "TEXT_ACTIVE", "TEXT_TITLE", "ACCENT", "ACCENT_DIM", "CHECK_OFF",
    "SLIDER_BG", "BUTTON", "BUTTON_HOVER", "HOVER", "FOCUS", "HEADER_BG",
    "NAV_BG", "NAV_IDLE", "NAV_HOVER", "NAV_ACTIVE", "NAV_INDICATOR", "DOCK_BG",
    "DOCK_HOVER", "DOCK_ACTIVE", "DOCK_BORDER", "DOCK_BADGE",
}
local base_alpha = {}
local last_sync = {}

local function restore_base_alpha()
    for i = 1, #ALPHA_KEYS do
        local key = ALPHA_KEYS[i]
        local c = M[key]
        local a = base_alpha[key]
        if c and a ~= nil then c[4] = a end
    end
    M.GLOBAL_ALPHA = 1
end

function M.sync()
    local frame = settings_ref.frame and settings_ref.frame() or 0
    if frame > 0 and frame == last_sync_frame then return false end
    last_sync_frame = frame
    local preset_idx = math.floor(clamp(setting("april_ui_theme_preset", 0), 0, #PRESETS - 1)) + 1
    local p = PRESETS[preset_idx] or PRESETS[1]
    local scale = clamp(setting("april_ui_scale", 100), 80, 125) * 0.01
    local density = math.floor(clamp(setting("april_ui_density", 1), 0, 2))
    local density_mul = ({ 0.88, 1.0, 1.12 })[density + 1]
    local window_alpha = clamp(setting("april_ui_window_opacity", 86), 45, 100) * 0.01
    local panel_alpha = clamp(setting("april_ui_panel_opacity", 72), 35, 100) * 0.01
    local border_alpha = clamp(setting("april_ui_border_strength", 58), 10, 100) * 0.01
    local corner_style = math.floor(clamp(setting("april_ui_corner_style", 2), 0, 2))
    local corner_base = ({ 2, 6, 10 })[corner_style + 1]

    if last_sync.preset == preset_idx
        and last_sync.scale == scale
        and last_sync.density == density
        and last_sync.window_alpha == window_alpha
        and last_sync.panel_alpha == panel_alpha
        and last_sync.border_alpha == border_alpha
        and last_sync.corner_style == corner_style
    then
        restore_base_alpha()
        return false
    end
    last_sync.preset = preset_idx
    last_sync.scale = scale
    last_sync.density = density
    last_sync.window_alpha = window_alpha
    last_sync.panel_alpha = panel_alpha
    last_sync.border_alpha = border_alpha
    last_sync.corner_style = corner_style

    M.SCALE = scale
    M.DENSITY = density
    M.GLOBAL_ALPHA = 1
    M.WINDOW_ALPHA = window_alpha
    M.PANEL_ALPHA = panel_alpha
    M.PRESET_ACCENT = rgb(p.accent, 1)

    M.BG = rgb(p.bg, window_alpha)
    M.BG_INNER = mix_rgb(p.bg, p.panel, 0.28, math.min(1, panel_alpha + 0.08))
    M.PANEL = rgb(p.panel, panel_alpha)
    M.PANEL_ALT = mix_rgb(p.panel, p.raised, 0.35, math.min(1, panel_alpha + 0.06))
    M.PANEL_RAISED = rgb(p.raised, math.min(1, panel_alpha + 0.12))
    M.OVERLAY = mix_rgb(p.panel, p.raised, 0.50, math.min(1, panel_alpha + 0.17))
    -- Flat UI: Vector already adds primitive shadows, so manual depth is disabled.
    M.SHADOW = { 0, 0, 0, 0 }
    M.SHADOW_DEEP = { 0, 0, 0, 0 }
    M.GLASS_HIGHLIGHT = { 1, 1, 1, 0 }
    M.BORDER = mix_rgb(p.raised, p.accent, 0.12, 0.36 * border_alpha)
    M.BORDER_SOFT = mix_rgb(p.panel, p.raised, 0.40, 0.24 * border_alpha)
    M.BORDER_HOT = mix_rgb(p.raised, p.accent, 0.55, 0.72 * border_alpha)
    M.SIDEBAR = mix_rgb(p.bg, p.panel, 0.18, math.min(1, window_alpha + 0.02))
    M.SIDEBAR_ACTIVE = mix_rgb(p.panel, p.accent, 0.20, math.min(1, panel_alpha + 0.08))
    -- Two-level top shell: primary section navigation plus compact HUD controls.
    M.HEADER_BG = mix_rgb(p.bg, p.panel, 0.12, math.min(1, window_alpha + 0.03))
    M.NAV_BG = mix_rgb(p.bg, p.panel, 0.26, math.min(1, panel_alpha + 0.02))
    M.NAV_IDLE = mix_rgb(p.bg, p.panel, 0.50, math.min(1, panel_alpha + 0.06))
    M.NAV_HOVER = mix_rgb(p.panel, p.raised, 0.48, math.min(1, panel_alpha + 0.08))
    M.NAV_ACTIVE = mix_rgb(p.panel, p.accent, 0.16, math.min(1, panel_alpha + 0.10))
    M.NAV_INDICATOR = rgb(p.accent, 1)
    M.DOCK_BG = mix_rgb(p.bg, p.panel, 0.44, math.min(1, panel_alpha + 0.08))
    M.DOCK_HOVER = mix_rgb(p.panel, p.raised, 0.66, math.min(1, panel_alpha + 0.12))
    M.DOCK_ACTIVE = mix_rgb(p.panel, p.accent, 0.22, math.min(1, panel_alpha + 0.14))
    M.DOCK_BORDER = mix_rgb(p.raised, p.accent, 0.18, 0.56 * border_alpha)
    M.DOCK_BADGE = rgb(p.accent, 1)

    local text = p.text or { 0.78, 0.80, 0.87 }
    local text_dim = p.text_dim or { 0.47, 0.49, 0.57 }
    M.TEXT = rgb(text, 1)
    M.TEXT_DIM = rgb(text_dim, 1)
    M.TEXT_ACTIVE = mix_rgb(text, { 1, 1, 1 }, 0.55, 1)
    M.TEXT_TITLE = mix_rgb(text, { 1, 1, 1 }, 0.28, 1)

    M.ACCENT = M.ACCENT or rgb(p.accent, 1)
    M.ACCENT_DIM = mix_rgb(p.bg, p.accent, 0.42, 0.85)
    M.CHECK_OFF = mix_rgb(p.bg, p.panel, 0.55, math.min(1, panel_alpha + 0.10))
    M.SLIDER_BG = mix_rgb(p.bg, p.panel, 0.62, math.min(1, panel_alpha + 0.06))
    M.BUTTON = mix_rgb(p.bg, p.panel, 0.72, math.min(1, panel_alpha + 0.10))
    M.BUTTON_HOVER = mix_rgb(p.panel, p.raised, 0.68, math.min(1, panel_alpha + 0.14))
    M.HOVER = mix_rgb(p.panel, p.raised, 0.48, 0.68)
    M.FOCUS = rgb(p.accent, 0.72)

    M.FONT = scaled(13, scale)
    M.FONT_SMALL = scaled(12, scale)
    M.FONT_TITLE = scaled(12, scale)
    M.FONT_CAPTION = scaled(11, scale)
    M.FONT_BRAND = scaled(15, scale)

    M.WINDOW_W = scaled(820, scale)
    M.WINDOW_H = scaled(560, scale)
    M.TITLEBAR_H = scaled(30 * density_mul, scale)
    M.NAV_H = scaled(42 * density_mul, scale)
    M.NAVBAR_H = M.NAV_H
    M.NAV_ITEM_H = scaled(34 * density_mul, scale)
    M.NAV_ITEM_MIN_W = scaled(78, scale)
    M.NAV_ITEM_GAP = scaled(4, scale)
    M.NAV_GAP = M.NAV_ITEM_GAP
    M.NAV_PAD_X = scaled(12, scale)
    M.NAV_ICON_GAP = scaled(7, scale)
    M.NAV_INDICATOR_H = scaled(2, scale)
    M.DOCK_H = scaled(30 * density_mul, scale)
    M.DOCK_ITEM_W = scaled(30, scale)
    M.DOCK_ITEM_H = scaled(26 * density_mul, scale)
    M.DOCK_ITEM_GAP = scaled(4, scale)
    M.DOCK_PAD = scaled(4, scale)
    M.DOCK_ICON_SIZE = scaled(16, scale)
    M.DOCK_GAP = M.DOCK_ITEM_GAP
    M.DOCK_CHIP_H = M.DOCK_ITEM_H
    M.DOCK_PAD_X = scaled(10, scale)
    M.DOCK_POPUP_W = scaled(270, scale)
    M.DOCK_POPUP_H = scaled(250 * density_mul, scale)
    M.HEADER_H = M.TITLEBAR_H + M.NAV_H
    M.CONTENT_PAD = scaled(12, scale)
    -- Compatibility constants retained for the previous sidebar renderer.
    M.SIDEBAR_W = scaled(58, scale)
    M.TAB_H = scaled(48 * density_mul, scale)
    M.GROUP_PAD = scaled(12, scale)
    M.GROUP_GAP = scaled(12 * density_mul, scale)
    M.GROUP_HEADER_H = scaled(30 * density_mul, scale)
    M.ROW_H = scaled(26 * density_mul, scale)
    M.ITEM_GAP = scaled(8 * density_mul, scale)
    M.LABEL_H = scaled(16 * density_mul, scale)
    M.LABEL_GAP = scaled(8 * density_mul, scale)
    M.CTRL_H = scaled(20 * density_mul, scale)
    M.CTRL_PAD = scaled(4, scale)
    M.CHECK_SIZE = scaled(13, scale)
    M.SWITCH_W = scaled(29, scale)
    M.SWITCH_H = scaled(15, scale)
    M.SLIDER_H = scaled(6, scale)
    M.STACKED_ROW_H = M.LABEL_H + M.LABEL_GAP + M.CTRL_H + M.CTRL_PAD
    M.SLIDER_ROW_H = M.LABEL_H + M.LABEL_GAP + M.SLIDER_H + scaled(10, scale) + M.CTRL_PAD
    M.CORNER = scaled(corner_base, scale)
    M.CORNER_SMALL = math.max(2, scaled(corner_base * 0.60, scale))
    for i = 1, #ALPHA_KEYS do
        local key = ALPHA_KEYS[i]
        local c = M[key]
        if c then base_alpha[key] = c[4] or 1 end
    end
    return true
end

function M.alpha(col, a)
    return { col[1], col[2], col[3], a }
end

function M.lerp_color(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        a[4] + (b[4] - a[4]) * t,
    }
end

function M.rainbow_at(t)
    local n = #M.RAINBOW
    local x = (t % 1) * n
    local i = math.floor(x) + 1
    local j = (i % n) + 1
    local f = x - math.floor(x)
    return M.lerp_color(M.RAINBOW[i], M.RAINBOW[j], f)
end

function M.apply_global_alpha(a)
    a = clamp(a, 0, 1)
    M.GLOBAL_ALPHA = a
    for i = 1, #ALPHA_KEYS do
        local key = ALPHA_KEYS[i]
        local c = M[key]
        if c then
            c[4] = (base_alpha[key] or c[4] or 1) * a
        end
    end
end

function M.restore_global_alpha()
    restore_base_alpha()
end

function M.capture_alpha(key)
    local c = M[key]
    if c then base_alpha[key] = c[4] or 1 end
end

M.sync()

return M
