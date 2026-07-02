local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")

local M = {}
local last_hit_time = 0

function M.register_menu()
    menu.add_group(April.TAB, "Feedback")
    menu.add_checkbox(April.TAB, "Feedback", "april_hitmarker_enabled", "Hitmarkers", true)
    menu.add_colorpicker(April.TAB, "Feedback", "april_hitmarker_color", "Hit Color", { 1, 0.3, 0.3, 1 })
end

function M.notify_hit()
    last_hit_time = utility and utility.get_time and utility.get_time() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_hitmarker_enabled", true) then return end
    local now = utility and utility.get_time and utility.get_time() or 0
    if now - last_hit_time > 0.35 then return end

    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local col = settings.color("april_hitmarker_color", { 1, 0.3, 0.3, 1 })
    local s = 8
    draw_util.line(cx - s, cy - s, cx - 3, cy - 3, col, 2)
    draw_util.line(cx + s, cy - s, cx + 3, cy - 3, col, 2)
    draw_util.line(cx - s, cy + s, cx - 3, cy + 3, col, 2)
    draw_util.line(cx + s, cy + s, cx + 3, cy + 3, col, 2)
end

return M
