-- Runtime dark-glass palette for April's draw-only UI.
-- Vector exposes alpha + rounded primitives, but no backdrop blur or custom fonts.
local M = {}

M.PRESET_NAMES = { "Violet Glass", "Midnight Blue", "Graphite", "Emerald Glass" }
M.DENSITY_NAMES = { "Compact", "Balanced", "Comfortable" }
M.CORNER_NAMES = { "Sharp", "Soft", "Rounded" }

local PRESETS = {
    {
        bg = { 0.030, 0.032, 0.045 }, panel = { 0.070, 0.065, 0.095 },
        raised = { 0.105, 0.090, 0.135 }, accent = { 0.78, 0.20, 0.92 },
    },
    {
        bg = { 0.025, 0.040, 0.060 }, panel = { 0.055, 0.085, 0.120 },
        raised = { 0.075, 0.120, 0.165 }, accent = { 0.20, 0.68, 1.00 },
    },
    {
        bg = { 0.035, 0.037, 0.043 }, panel = { 0.075, 0.078, 0.088 },
        raised = { 0.115, 0.118, 0.130 }, accent = { 0.73, 0.76, 0.84 },
    },
    {
        bg = { 0.020, 0.045, 0.040 }, panel = { 0.045, 0.095, 0.080 },
        raised = { 0.065, 0.135, 0.110 }, accent = { 0.20, 0.92, 0.62 },
    },
}

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
    local ok, value = pcall(function()
        return April.require("core.settings").get(id, fallback)
    end)
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

function M.sync()
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

    M.SCALE = scale
    M.DENSITY = density
    M.GLOBAL_ALPHA = 1
    M.WINDOW_ALPHA = window_alpha
    M.PANEL_ALPHA = panel_alpha
    M.PRESET_ACCENT = rgb(p.accent, 1)

    M.BG = rgb(p.bg, window_alpha)
    M.BG_INNER = mix_rgb(p.bg, p.panel, 0.28, math.min(1, window_alpha + 0.04))
    M.PANEL = rgb(p.panel, panel_alpha)
    M.PANEL_ALT = mix_rgb(p.panel, p.raised, 0.35, math.min(1, panel_alpha + 0.06))
    M.PANEL_RAISED = rgb(p.raised, math.min(1, panel_alpha + 0.12))
    M.OVERLAY = mix_rgb(p.panel, p.raised, 0.50, math.min(1, panel_alpha + 0.17))
    M.SHADOW = { 0, 0, 0, 0.32 * window_alpha }
    M.SHADOW_DEEP = { 0, 0, 0, 0.20 * window_alpha }
    M.GLASS_HIGHLIGHT = { 1, 1, 1, 0.045 * border_alpha }
    M.BORDER = { 0.34, 0.35, 0.42, 0.60 * border_alpha }
    M.BORDER_SOFT = { 0.28, 0.29, 0.36, 0.40 * border_alpha }
    M.BORDER_HOT = mix_rgb(p.raised, p.accent, 0.55, 0.72 * border_alpha)
    M.SIDEBAR = mix_rgb(p.bg, p.panel, 0.18, math.min(1, window_alpha + 0.02))
    M.SIDEBAR_ACTIVE = mix_rgb(p.panel, p.accent, 0.20, math.min(1, panel_alpha + 0.08))

    M.TEXT = { 0.78, 0.80, 0.87, 1 }
    M.TEXT_DIM = { 0.47, 0.49, 0.57, 1 }
    M.TEXT_ACTIVE = { 0.96, 0.97, 1.00, 1 }
    M.TEXT_TITLE = { 0.84, 0.86, 0.92, 1 }

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

    M.WINDOW_W = scaled(820, scale)
    M.WINDOW_H = scaled(560, scale)
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
    M.SLIDER_H = scaled(6, scale)
    M.STACKED_ROW_H = M.LABEL_H + M.LABEL_GAP + M.CTRL_H + M.CTRL_PAD
    M.SLIDER_ROW_H = M.LABEL_H + M.LABEL_GAP + M.SLIDER_H + scaled(10, scale) + M.CTRL_PAD
    M.CORNER = scaled(corner_base, scale)
    M.CORNER_SMALL = math.max(2, scaled(corner_base * 0.60, scale))
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
    local keys = {
        "BG", "BG_INNER", "PANEL", "PANEL_ALT", "PANEL_RAISED", "OVERLAY",
        "SHADOW", "SHADOW_DEEP", "GLASS_HIGHLIGHT", "BORDER", "BORDER_SOFT",
        "BORDER_HOT", "SIDEBAR", "SIDEBAR_ACTIVE", "TEXT", "TEXT_DIM",
        "TEXT_ACTIVE", "TEXT_TITLE", "ACCENT", "ACCENT_DIM", "CHECK_OFF",
        "SLIDER_BG", "BUTTON", "BUTTON_HOVER", "HOVER", "FOCUS",
    }
    for _, key in ipairs(keys) do
        local c = M[key]
        if c then
            M[key] = { c[1], c[2], c[3], (c[4] or 1) * a }
        end
    end
end

M.sync()

return M
