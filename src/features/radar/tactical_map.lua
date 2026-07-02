local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local math_util = April.require("core.math_util")
local env = April.require("core.env")
local G = April.require("core.menu_util").G
local T = April.require("core.menu_util").tab()

local M = {}
local P = "april_map_enabled"

function M.register_menu()
    menu.add_checkbox(T, G.MAP, "april_map_enabled", "Enable Tactical Map", false, { key = 0x28 })
    menu.add_slider_float(T, G.MAP, "april_map_zoom", "Zoom Level", 0.05, 5.0, 1.0, "%.2f", { parent = P })
    menu.add_colorpicker(T, G.MAP, "april_map_bg", "Background Color", { 0.05, 0.05, 0.08, 0.95 }, { parent = P })
    menu.add_colorpicker(T, G.MAP, "april_map_grid", "Grid Color", { 1, 1, 1, 0.04 }, { parent = P })
    menu.add_colorpicker(T, G.MAP, "april_map_local", "Local Player Color", { 0.2, 0.8, 1, 1 }, { parent = P })
    menu.add_checkbox(T, G.MAP, "april_map_labels", "Show Labels", false, { parent = P })
    menu.add_checkbox(T, G.MAP, "april_map_coords", "Show Coordinates", true, { parent = P })
    menu.add_checkbox(T, G.MAP, "april_map_compass", "Compass Overlay", true, { parent = P, colorpicker = { 0.2, 0.8, 1, 0.8 } })
    menu.add_slider_int(T, G.MAP, "april_map_size", "Map Size", 120, 500, 220, { parent = P })
end

local function key_active()
    local vk = settings.num("april_map_key", 0x28)
    if input and input.is_key_down then return input.is_key_down(vk) end
    return settings.bool("april_map_enabled", false)
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_map_enabled", false) and not key_active() then return end

    local size = settings.num("april_map_size", 220)
    local sw, sh = draw_util.screen_size()
    local x, y = sw - size - 20, 20
    local bg = settings.color("april_map_bg", { 0.05, 0.05, 0.08, 0.95 })
    local grid = settings.color("april_map_grid", { 1, 1, 1, 0.04 })
    local local_col = settings.color("april_map_local", { 0.2, 0.8, 1, 1 })

    if draw and draw.rect_filled then
        draw.rect_filled(x, y, size, size, bg)
        draw.rect(x, y, size, size, { 1, 1, 1, 0.15 }, 1)
    end

    local step = size / 8
    for i = 1, 7 do
        draw_util.line(x + step * i, y, x + step * i, y + size, grid, 1)
        draw_util.line(x, y + step * i, x + size, y + step * i, grid, 1)
    end

    local lp = env.get_local_player()
    if lp and lp.position then
        local cx, cy = x + size * 0.5, y + size * 0.5
        draw_util.circle(cx, cy, 4, local_col, true)
        if settings.bool("april_map_coords", true) then
            local px, py, pz = lp.position.x, lp.position.y, lp.position.z
            draw_util.text(x + 6, y + size + 4, string.format("%.0f, %.0f, %.0f", px, py, pz), { 1, 1, 1, 0.8 }, 11)
        end
        if settings.bool("april_map_labels", false) then
            draw_util.text(x + 6, y + 4, "Tactical Map", { 1, 1, 1, 0.9 }, 12)
        end
    end

    if settings.bool("april_map_compass", true) then
        local cc = settings.color("april_map_compass", { 0.2, 0.8, 1, 0.8 })
        draw_util.text_centered(x + size * 0.5, y - 14, "N", cc, 12)
    end
end

return M
