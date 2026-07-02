local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")

local M = {}

function M.register_menu()
    menu.add_group(April.TAB, "Crosshair")
    menu.add_checkbox(April.TAB, "Crosshair", "april_crosshair_enabled", "Crosshair", true)
    menu.add_slider_int(April.TAB, "Crosshair", "april_crosshair_size", "Size", 2, 40, 8)
    menu.add_slider_int(April.TAB, "Crosshair", "april_crosshair_gap", "Gap", 0, 20, 4)
    menu.add_colorpicker(April.TAB, "Crosshair", "april_crosshair_color", "Color", { 1, 1, 1, 1 })
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_crosshair_enabled", true) then return end
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local size = settings.num("april_crosshair_size", 8)
    local gap = settings.num("april_crosshair_gap", 4)
    local col = settings.color("april_crosshair_color", { 1, 1, 1, 1 })

    draw_util.line(cx - gap - size, cy, cx - gap, cy, col, 1)
    draw_util.line(cx + gap, cy, cx + gap + size, cy, col, 1)
    draw_util.line(cx, cy - gap - size, cx, cy - gap, col, 1)
    draw_util.line(cx, cy + gap, cx, cy + gap + size, col, 1)
end

return M
