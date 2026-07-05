--[[ Project Vector — shared overlay / HUD theme (matches main cheat menu). ]]

local draw_util = April.require("core.draw_util")

local M = {}

-- #0D0D0D base, #00C3E3 cyan accent
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
    return M.CYAN
end

function M.draw_mod_marker(sx, sy, image_cache, icon_key)
    if not draw or not draw.text then return end

    local label = "MOD"
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
        accent = M.RED,
        accent_w = 2,
        rounding = 3,
    })

    if image_cache and icon_key then
        image_cache.begin_load(icon_key)
        image_cache.draw_fit(icon_key, x + pad_x, y + pad_y, icon_size, icon_size)
    end

    draw.text(
        x + pad_x + icon_size + gap,
        y + pad_y + 1,
        label,
        M.RED,
        fs
    )
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

        local name = row.name or "?"
        if #name > 20 then name = name:sub(1, 18) .. ".." end
        draw.text(x + pad + 12, ry, name, M.TEXT, 13)

        local role = row.role or "Staff"
        if #role > 24 then role = role:sub(1, 22) .. ".." end
        draw.text(x + pad + 12, ry + 15, role, accent, 11)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad + 12, ry + 28, row.meta, M.TEXT_MUTED, 10)
        end

        ry = ry + row_h
    end
end

return M
