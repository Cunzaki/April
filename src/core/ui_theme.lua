local draw_util = April.require("core.draw_util")
local text_util = April.require("core.text_util")
local mod_ids = April.require("game.mod_ids")

local M = {}

M.BG          = { 13 / 255, 13 / 255, 13 / 255, 0.94 }
M.PANEL       = { 18 / 255, 18 / 255, 20 / 255, 0.92 }
M.PANEL_DEEP  = { 10 / 255, 10 / 255, 12 / 255, 0.90 }
M.SLOT        = { 22 / 255, 22 / 255, 24 / 255, 0.82 }
M.SLOT_HELD   = { 28 / 255, 28 / 255, 30 / 255, 0.90 }
M.SLOT_EMPTY  = { 14 / 255, 14 / 255, 16 / 255, 0.55 }

M.CYAN        = { 0, 195 / 255, 227 / 255, 1 }
M.CYAN_SOFT   = { 0, 195 / 255, 227 / 255, 0.35 }
M.CYAN_GLOW   = { 0, 195 / 255, 227 / 255, 0.18 }

M.TEXT        = { 1, 1, 1, 0.96 }
M.TEXT_DIM    = { 128 / 255, 128 / 255, 128 / 255, 0.95 }
M.TEXT_MUTED  = { 0.62, 0.64, 0.68, 0.88 }

M.BORDER      = { 1, 1, 1, 0.08 }
M.BORDER_CYAN = { 0, 195 / 255, 227 / 255, 0.45 }

M.RED         = { 1, 0.35, 0.35, 1 }
M.ORANGE      = { 1, 0.55, 0.22, 1 }
M.PURPLE      = { 0.92, 0.45, 1, 1 }
M.GREEN       = { 0.35, 0.85, 0.55, 1 }

M.ROUND       = 4
M.MAP_BG      = { 13 / 255, 13 / 255, 13 / 255, 0.95 }
M.MAP_GRID    = { 0, 195 / 255, 227 / 255, 0.06 }
M.ACCENT      = M.CYAN
M.HEADER      = M.PANEL_DEEP
M.GLASS_HIGHLIGHT = { 1, 1, 1, 0.04 }

local function copy_alpha(col, alpha)
    return { col[1], col[2], col[3], alpha == nil and (col[4] or 1) or alpha }
end

local function mix(a, b, t, alpha)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        alpha == nil and 1 or alpha,
    }
end

-- Synchronize every draw HUD token with the active custom-menu theme.
-- Called before feature drawing, so it also works while the menu is closed.
function M.sync()
    local ok_anim, anim = pcall(function()
        return April.require("ui.gs_anim")
    end)
    if ok_anim and anim and anim.sync_theme then
        pcall(anim.sync_theme)
    end

    local ok, gs = pcall(function()
        return April.require("ui.gs_theme")
    end)
    if not ok or not gs then return false end

    local accent = gs.ACCENT or M.CYAN
    M.ACCENT = copy_alpha(accent, 1)
    M.CYAN = copy_alpha(accent, 1) -- compatibility: legacy chrome now follows accent
    M.CYAN_SOFT = copy_alpha(accent, 0.35)
    M.CYAN_GLOW = copy_alpha(accent, 0.18)

    M.BG = copy_alpha(gs.BG or M.BG, math.min(0.96, (gs.WINDOW_ALPHA or 0.86) + 0.04))
    M.PANEL = copy_alpha(gs.PANEL or M.PANEL, math.min(0.96, (gs.PANEL_ALPHA or 0.72) + 0.10))
    M.PANEL_DEEP = copy_alpha(gs.BG_INNER or M.PANEL_DEEP, math.min(0.94, (gs.PANEL_ALPHA or 0.72) + 0.08))
    M.HEADER = copy_alpha(gs.PANEL_ALT or M.PANEL_DEEP, math.min(0.98, (gs.PANEL_ALPHA or 0.72) + 0.16))
    M.SLOT = copy_alpha(gs.BUTTON or M.SLOT, math.min(0.92, (gs.PANEL_ALPHA or 0.72) + 0.08))
    M.SLOT_HELD = mix(M.SLOT, accent, 0.28, 0.94)
    M.SLOT_EMPTY = copy_alpha(gs.CHECK_OFF or M.SLOT_EMPTY, 0.58)

    M.TEXT = copy_alpha(gs.TEXT_ACTIVE or M.TEXT, 0.97)
    M.TEXT_DIM = copy_alpha(gs.TEXT_DIM or M.TEXT_DIM, 0.96)
    M.TEXT_MUTED = copy_alpha(gs.TEXT or M.TEXT_MUTED, 0.78)
    M.BORDER = copy_alpha(gs.BORDER_SOFT or M.BORDER, (gs.BORDER_SOFT and gs.BORDER_SOFT[4]) or 0.35)
    M.BORDER_CYAN = copy_alpha(gs.BORDER_HOT or accent, 0.72)
    M.GLASS_HIGHLIGHT = copy_alpha(gs.GLASS_HIGHLIGHT or M.GLASS_HIGHLIGHT)

    -- Panel chrome is always square; small semantic glyphs can remain circular.
    M.ROUND = 0
    M.MAP_BG = copy_alpha(gs.BG_INNER or M.BG, 0.90)
    M.MAP_GRID = copy_alpha(accent, 0.10)
    return true
end

function M.alpha(col, a)
    return { col[1], col[2], col[3], a }
end

function M.text_w(text, size)
    if draw and draw.get_text_size then
        return draw.get_text_size(text, size or 13)
    end
    return (#text * (size or 13) * 0.55), size or 13
end

function M.draw_panel(x, y, w, h, opts)
    if not draw then return end
    opts = opts or {}

    local bg = opts.bg or M.PANEL
    local border = opts.border or M.BORDER
    local rounding = opts.rounding ~= nil and opts.rounding or M.ROUND

    if draw.rect_filled then
        draw.rect_filled(x, y, w, h, bg, rounding)
    end
    if draw.rect then
        draw.rect(x, y, w, h, border, rounding, opts.border_w or 1)
    end

    if opts.accent and draw.line then
        local ax = x + (rounding > 0 and 1 or 0)
        local aw = w - (rounding > 0 and 2 or 0)
        draw.line(ax, y, ax + aw, y, opts.accent, opts.accent_w or 2)
    end

    if opts.accent_left and draw.line then
        draw.line(x, y + 1, x, y + h - 1, opts.accent_left, opts.accent_w or 2)
    end
end

function M.draw_section_title(x, y, title, col)
    col = col or M.CYAN
    draw_util.text(x, y, title, col, 13)
end

function M.draw_tooltip_box(x, y, lines)
    if not draw or not lines or #lines == 0 then return end
    lines = type(lines) == "table" and lines or { tostring(lines) }

    local fs = 12
    local pad = 8
    local tw = 0
    for i = 1, #lines do
        local w = select(1, M.text_w(lines[i], fs))
        if w > tw then tw = w end
    end

    local box_w = tw + pad * 2
    local box_h = #lines * 14 + pad * 2
    local sw = select(1, draw_util.screen_size())
    x = math.min(x, sw - box_w - 12)
    y = math.max(y, 8)

    M.draw_panel(x, y, box_w, box_h, {
        bg = M.alpha(M.PANEL, 0.96),
        accent = M.CYAN,
        rounding = M.ROUND,
    })

    for i = 1, #lines do
        local col = (i == 1) and M.TEXT or M.TEXT_MUTED
        draw_util.text(x + pad, y + pad + (i - 1) * 14, lines[i], col, fs)
    end
end

function M.toast_accent(ntype)
    if ntype == "danger" then return M.RED end
    if ntype == "warning" then return M.ORANGE end
    if ntype == "success" then return M.CYAN end
    return M.CYAN
end

function M.role_accent(role)
    if not role then return M.CYAN end
    local r = role:lower()
    if r:find("founder") or r:find("developer") then return M.PURPLE end
    if r:find("moderator") then return M.RED end
    if r:find("tester") then return M.ORANGE end
    if r == "og" or r:find("contribution") then return M.CYAN end
    return M.CYAN
end

function M.draw_role_glyph(x, y, size, kind, accent)
    if not draw then return end
    local cx = x + size * 0.5
    local cy = y + size * 0.5
    local r, g, b, a = accent[1] or 1, accent[2] or 1, accent[3] or 1, accent[4] or 1

    if kind == "mod" then
        local h = size * 0.82
        local half = h * 0.46
        if draw.poly_filled then
            draw.poly_filled({
                { cx, y + 1 },
                { cx - half, y + h },
                { cx + half, y + h },
            }, r, g, b, a)
        end
        if draw.text then
            draw.text(cx - 2, y + size * 0.34, "!", { 1, 1, 1, 0.95 }, math.max(8, math.floor(size * 0.62)))
        end
    elseif kind == "tester" then
        if draw.rect_filled then
            draw.rect_filled(x + 1, y + 2, size - 2, size - 3, { r, g, b, a * 0.9 }, 3)
        end
        if draw.text then
            local fs = math.max(8, math.floor(size * 0.58))
            local tw = select(1, M.text_w("T", fs))
            draw.text(cx - tw * 0.5, y + size * 0.22, "T", { 1, 1, 1, 0.95 }, fs)
        end
    elseif kind == "dev" then
        if draw.rect_filled then
            draw.rect_filled(x + 1, y + 2, size - 2, size - 3, { r, g, b, a * 0.35 }, 3)
        end
        if draw.text then
            local fs = math.max(7, math.floor(size * 0.42))
            draw.text(x + 2, y + size * 0.18, "</>", { r, g, b, a }, fs)
        end
    elseif kind == "og" or kind == "contrib" then
        if draw.circle_filled then
            draw.circle_filled(cx, cy, size * 0.34, { r, g, b, a }, 12)
        end
        if draw.text then
            local ch = kind == "og" and "O" or "C"
            local fs = math.max(8, math.floor(size * 0.5))
            local tw = select(1, M.text_w(ch, fs))
            draw.text(cx - tw * 0.5, y + size * 0.24, ch, { 1, 1, 1, 0.95 }, fs)
        end
    else
        if draw.circle_filled then
            draw.circle_filled(cx, cy, size * 0.3, { r, g, b, a }, 10)
        end
    end
end

function M.draw_staff_badge(sx, sy, role)
    if not draw or not draw.text then return end

    local label = mod_ids.short_label(role)
    local accent = M.role_accent(role)
    local glyph = mod_ids.glyph_kind(role)
    local fs = 11
    local icon_size = 14
    local gap = 4
    local pad_x, pad_y = 6, 4
    local tw = select(1, M.text_w(label, fs))
    local w = pad_x * 2 + icon_size + gap + tw
    local h = pad_y * 2 + math.max(icon_size, fs + 2)
    local x = math.floor(sx - w * 0.5)
    local y = math.floor(sy - h - 8)

    M.draw_panel(x, y, w, h, {
        bg = M.alpha(M.BG, 0.86),
        border = M.alpha(M.BORDER, 0.35),
        accent = accent,
        accent_w = 2,
        rounding = 3,
    })

    M.draw_role_glyph(x + pad_x, y + pad_y, icon_size, glyph, accent)
    draw.text(x + pad_x + icon_size + gap, y + pad_y + 1, label, accent, fs)
end

function M.draw_mod_marker(sx, sy, _image_cache, _icon_key, role)
    M.draw_staff_badge(sx, sy, role or "Game Moderator")
end

function M.draw_staff_list(x, y, width, rows, max_rows)
    if not draw or not draw.text or not rows or #rows == 0 then return end

    max_rows = max_rows or 4
    local pad = 10
    local title_h = 24
    local row_h = 44
    local count = math.min(#rows, max_rows)
    local height = title_h + count * row_h + 6

    M.draw_panel(x, y, width, height, {
        bg = M.alpha(M.BG, 0.90),
        border = M.alpha(M.BORDER, 0.45),
        accent = M.RED,
        accent_w = 2,
        rounding = M.ROUND,
    })

    draw_util.text(x + pad, y + 6, "Staff In Lobby", M.TEXT, 12)

    local div_y = y + title_h
    if draw.line then
        draw.line(x + pad, div_y, x + width - pad, div_y, M.alpha(M.BORDER, 0.55), 1)
    end

    local ry = div_y + 6
    for i = 1, count do
        local row = rows[i]
        local accent = row.accent or M.role_accent(row.role)

        if i > 1 and draw.line then
            draw.line(x + pad, ry - 4, x + width - pad, ry - 4, M.alpha(M.BORDER, 0.22), 1)
        end

        if draw.circle_filled then
            draw.circle_filled(x + pad + 3, ry + 7, 3, accent, 8)
        end

        local name = text_util.sanitize(row.name or "?")
        if #name > 20 then name = name:sub(1, 18) .. ".." end
        draw.text(x + pad + 12, ry, name, M.TEXT, 13)

        local role = text_util.sanitize(row.role or "Staff")
        if #role > 24 then role = role:sub(1, 22) .. ".." end
        draw.text(x + pad + 12, ry + 15, role, accent, 11)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad + 12, ry + 28, text_util.sanitize(row.meta), M.TEXT_MUTED, 10)
        end

        ry = ry + row_h
    end
end

return M
