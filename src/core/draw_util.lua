local math_util = April.require("core.math_util")
local text_util = April.require("core.text_util")

local M = {}

function M.white(r, g, b, a)
    return { r or 1, g or 1, b or 1, a or 1 }
end

function M.text_centered(x, y, text, col, size)
    if not draw or not draw.text or not draw.get_text_size then return end
    text = text_util.sanitize(text)
    local tw, th = draw.get_text_size(text, size or 14)
    draw.text(x - tw * 0.5, y, text, col, size or 14)
end

-- Stronger silhouette for far ESP (extra soft shadow under auto outline).
function M.text_centered_strong(x, y, text, col, size)
    if not draw or not draw.text or not draw.get_text_size then return end
    text = text_util.sanitize(text)
    size = size or 14
    local tw = draw.get_text_size(text, size)
    local tx = x - tw * 0.5
    local a = (col and col[4]) or 1
    local shadow = { 0, 0, 0, a * 0.55 }
    draw.text(tx + 1, y + 1, text, shadow, size)
    draw.text(tx, y, text, col, size)
end

function M.text_outlined(x, y, text, col, size)
    if not draw or not draw.text then return end
    draw.text(x, y, text_util.sanitize(text), col, size or 14)
end

function M.text(x, y, text, col, size)
    M.text_outlined(x, y, text, col, size)
end

function M.box_esp(x, y, w, h, col, style)
    if not draw then return end
    if style == 1 and draw.corner_box then
        draw.corner_box(x, y, w, h, col)
        return
    end
    if draw.box then
        draw.box(x, y, w, h, col, 0, style or 0)
    end
end

-- Soft outer box + crisp inner for readability at any range.
function M.box_esp_nice(x, y, w, h, col, style)
    if not draw then return end
    local a = (col and col[4]) or 1
    local outer = { 0, 0, 0, a * 0.7 }
    if style == 1 and draw.corner_box then
        draw.corner_box(x - 1, y - 1, w + 2, h + 2, outer)
        draw.corner_box(x, y, w, h, col)
        return
    end
    if draw.box then
        draw.box(x - 1, y - 1, w + 2, h + 2, outer, 0, 0)
        draw.box(x, y, w, h, col, 0, style or 0)
    end
end

function M.health_bar(x, y, h, hp, max_hp)
    if not draw or not draw.health_bar then return end
    draw.health_bar(x, y, h, hp, max_hp)
end

-- Custom vertical HP bar that scales with box height (readable far away).
function M.health_bar_nice(x, y, h, hp, max_hp, bar_w)
    if not draw or not hp or not max_hp or max_hp <= 0 then return end
    h = math.max(8, h)
    bar_w = math.max(3, bar_w or math.floor(h * 0.07 + 0.5))
    local pct = math_util.clamp(hp / max_hp, 0, 1)
    local fill_h = math.max(1, h * pct)

    if draw.rect_filled then
        draw.rect_filled(x, y, bar_w, h, { 0, 0, 0, 0.55 }, 1)
        -- green → yellow → red
        local r, g, b
        if pct > 0.5 then
            local t = (pct - 0.5) * 2
            r, g, b = 1 - t, 1, 0.25
        else
            local t = pct * 2
            r, g, b = 1, t, 0.2
        end
        draw.rect_filled(x, y + (h - fill_h), bar_w, fill_h, { r, g, b, 0.95 }, 1)
    elseif draw.health_bar then
        draw.health_bar(x + bar_w, y, h, hp, max_hp)
        return bar_w
    end
    if draw.rect then
        draw.rect(x, y, bar_w, h, { 0, 0, 0, 0.85 }, 1, 1)
    end
    return bar_w
end

function M.line(x1, y1, x2, y2, col, thick)
    if not draw or not draw.line then return end
    draw.line(x1, y1, x2, y2, col, thick or 1)
end

--- Screen snapline from bottom-center to target (classic ESP style).
function M.snapline(tx, ty, col, thick, sw, sh)
    if not draw or not draw.line then return end
    if not sw or not sh then
        local dw, dh = M.screen_size()
        sw = sw or dw
        sh = sh or dh
    end
    col = col or { 1, 1, 1, 1 }
    thick = thick or 1.5
    local sx = sw * 0.5
    local sy = sh - 1
    local a = col[4] or 1
    M.line(sx, sy, tx, ty, { 0, 0, 0, a * 0.9 }, thick + 1.5)
    M.line(sx, sy, tx, ty, col, thick)
end

function M.circle(x, y, r, col, filled)
    if not draw then return end
    if filled and draw.circle_filled then
        draw.circle_filled(x, y, r, col, 24)
    elseif draw.circle then
        draw.circle(x, y, r, col, 24, 1)
    end
end

function M.screen_size()
    local w, h
    if draw and draw.get_screen_size then
        w, h = draw.get_screen_size()
    elseif utility and utility.get_screen_size then
        w, h = utility.get_screen_size()
    end
    if not w or w <= 0 then w = 1920 end
    if not h or h <= 0 then h = 1080 end
    return w, h
end

function M.world_label(inst, text, col, max_dist)
    if not utility or not utility.world_to_screen then return end
    local env = April.require("core.env")
    if not env.is_valid(inst) then return end
    local pos = inst.Position
    if not pos or pos.x == nil then return end

    local me = env.get_local_player()
    if me and me.position and max_dist then
        local dx = pos.x - me.position.x
        local dy = pos.y - me.position.y
        local dz = pos.z - me.position.z
        local dist = math_util.distance3(dx, dy, dz)
        if dist > max_dist then return end
        text = string.format("%s [%dm]", text, math.floor(dist))
    end

    local sx, sy, vis = utility.world_to_screen(pos.x, pos.y, pos.z)
    if vis then
        M.text_centered(sx, sy, text, col, 13)
    end
end

return M
