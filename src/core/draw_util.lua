local math_util = April.require("core.math_util")

local M = {}

function M.white(r, g, b, a)
    return { r or 1, g or 1, b or 1, a or 1 }
end

function M.text_centered(x, y, text, col, size)
    if not draw or not draw.text or not draw.get_text_size then return end
    local tw, th = draw.get_text_size(text, size or 14)
    draw.text(x - tw * 0.5, y, text, col, size or 14)
end

function M.text_outlined(x, y, text, col, size)
    if not draw or not draw.text then return end
    draw.text(x, y, text, col, size or 14)
end

function M.text(x, y, text, col, size)
    M.text_outlined(x, y, text, col, size)
end

function M.box_esp(x, y, w, h, col, style)
    if not draw or not draw.box then return end
    draw.box(x, y, w, h, col, 0, style or 0)
end

function M.health_bar(x, y, h, hp, max_hp)
    if not draw or not draw.health_bar then return end
    draw.health_bar(x, y, h, hp, max_hp)
end

function M.line(x1, y1, x2, y2, col, thick)
    if not draw or not draw.line then return end
    draw.line(x1, y1, x2, y2, col, thick or 1)
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
    if draw and draw.get_screen_size then
        return draw.get_screen_size()
    end
    if utility and utility.get_screen_size then
        return utility.get_screen_size()
    end
    return 1920, 1080
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
