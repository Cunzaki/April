local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local G = menu_util.G
local T = April.require("core.menu_util").tab()

local M = {}
local hit_time = 0
local P = "april_hitmarker_enabled"

function M.register_menu()
    menu_util.ensure_group(G.VISUALS)
    menu.add_checkbox(T, G.VISUALS, "april_hitmarker_enabled", "Hitmarker", true, { colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G.VISUALS, "april_hitmarker_glow", "Hitmarker Glow", false, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_hitmarker_size", "Hitmarker Size", 1, 20, 5, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_hitmarker_duration", "Duration (ms)", 100, 2000, 500, { parent = P })
    menu.add_checkbox(T, G.VISUALS, "april_hit_notifier", "Hit Notifier", true)
end

function M.trigger_hit()
    hit_time = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_hitmarker_enabled", true) then return end
    if hit_time == 0 then return end
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    local dur = settings.num("april_hitmarker_duration", 500)
    if now - hit_time > dur then return end

    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local size = settings.num("april_hitmarker_size", 5)
    local col = settings.color("april_hitmarker_enabled", { 1, 1, 1, 1 })
    local alpha = 1 - (now - hit_time) / dur
    col = { col[1], col[2], col[3], (col[4] or 1) * alpha }

    draw_util.line(cx - size, cy - size, cx - size * 0.3, cy - size * 0.3, col, 2)
    draw_util.line(cx + size, cy - size, cx + size * 0.3, cy - size * 0.3, col, 2)
    draw_util.line(cx - size, cy + size, cx - size * 0.3, cy + size * 0.3, col, 2)
    draw_util.line(cx + size, cy + size, cx + size * 0.3, cy + size * 0.3, col, 2)

    if settings.bool("april_hitmarker_glow", false) then
        draw_util.circle(cx, cy, size * 1.5, { col[1], col[2], col[3], col[4] * 0.3 }, false)
    end
end

return M
