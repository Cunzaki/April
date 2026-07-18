-- Refined dark-purple palette for the draw-only April UI.
local M = {}

M.BG = { 0.045, 0.047, 0.057, 0.985 }
M.BG_INNER = { 0.063, 0.066, 0.080, 1 }
M.PANEL = { 0.075, 0.079, 0.096, 0.985 }
M.PANEL_ALT = { 0.092, 0.097, 0.118, 1 }
M.PANEL_RAISED = { 0.105, 0.111, 0.136, 1 }
M.OVERLAY = { 0.075, 0.078, 0.098, 0.995 }
M.SHADOW = { 0, 0, 0, 0.34 }
M.BORDER = { 0.20, 0.207, 0.245, 1 }
M.BORDER_SOFT = { 0.145, 0.151, 0.185, 1 }
M.BORDER_HOT = { 0.36, 0.29, 0.45, 1 }
M.SIDEBAR = { 0.055, 0.058, 0.071, 1 }
M.SIDEBAR_ACTIVE = { 0.13, 0.103, 0.16, 1 }

M.TEXT = { 0.76, 0.775, 0.835, 1 }
M.TEXT_DIM = { 0.43, 0.45, 0.52, 1 }
M.TEXT_ACTIVE = { 0.94, 0.945, 0.98, 1 }
M.TEXT_TITLE = { 0.80, 0.805, 0.87, 1 }

-- Accent matches the reference (purple / magenta)
M.ACCENT = { 0.78, 0.20, 0.92, 1 }
M.ACCENT_DIM = { 0.36, 0.12, 0.48, 1 }
M.CHECK_OFF = { 0.105, 0.11, 0.135, 1 }
M.SLIDER_BG = { 0.115, 0.12, 0.15, 1 }
M.BUTTON = { 0.105, 0.11, 0.135, 1 }
M.BUTTON_HOVER = { 0.15, 0.145, 0.185, 1 }
M.HOVER = { 0.12, 0.115, 0.15, 0.8 }
M.FOCUS = { 0.78, 0.20, 0.92, 0.72 }

M.RAINBOW = {
    { 0.20, 0.90, 0.95, 1 },
    { 0.55, 0.35, 0.95, 1 },
    { 0.95, 0.85, 0.20, 1 },
    { 0.95, 0.35, 0.55, 1 },
    { 0.35, 0.95, 0.45, 1 },
}

M.FONT = 13
M.FONT_SMALL = 12
M.FONT_TITLE = 12
M.FONT_CAPTION = 11

M.WINDOW_W = 820
M.WINDOW_H = 560
M.SIDEBAR_W = 58
M.TAB_H = 48
M.GROUP_PAD = 12
M.GROUP_GAP = 12
M.GROUP_HEADER_H = 30
M.ROW_H = 26
M.ITEM_GAP = 8
M.LABEL_H = 16
M.LABEL_GAP = 8
M.CTRL_H = 20
M.CTRL_PAD = 4
M.CHECK_SIZE = 13
M.SLIDER_H = 6
M.STACKED_ROW_H = M.LABEL_H + M.LABEL_GAP + M.CTRL_H + M.CTRL_PAD
M.SLIDER_ROW_H = M.LABEL_H + M.LABEL_GAP + M.SLIDER_H + 10 + M.CTRL_PAD
M.CORNER = 4
M.CORNER_SMALL = 3

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

return M
