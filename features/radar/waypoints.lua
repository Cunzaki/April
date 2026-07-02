local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

function M.register_menu()
    menu.add_group("Radar", "Waypoints")
    menu.add_button("Radar", "Waypoints", "april_wp_set", "Set Waypoint 1", function()
        local lp = env.get_local_player()
        if lp and lp.position then
            cache.waypoints[1] = { name = "Waypoint 1", pos = { x = lp.position.x, y = lp.position.y, z = lp.position.z } }
            print("[April] Waypoint 1 set")
        end
    end)
    menu.add_button("Radar", "Waypoints", "april_wp_clear", "Clear Waypoint 1", function()
        cache.waypoints[1] = nil
        print("[April] Waypoint 1 cleared")
    end)
    menu.add_checkbox("Radar", "Waypoints", "april_wp_draw", "Draw Waypoints", true)
    menu.add_colorpicker("Radar", "Waypoints", "april_wp_color", "Color", { 0.2, 1, 0.8, 1 })
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_wp_draw", true) then return end
    if not utility or not utility.world_to_screen then return end
    local col = settings.color("april_wp_color", { 0.2, 1, 0.8, 1 })
    local sw, sh = draw_util.screen_size()

    for i, wp in pairs(cache.waypoints) do
        if wp and wp.pos then
            local sx, sy, vis = utility.world_to_screen(wp.pos.x, wp.pos.y, wp.pos.z)
            if vis then
                draw_util.circle(sx, sy, 6, col, true)
                draw_util.text_centered(sx, sy - 16, wp.name or ("WP" .. i), col, 12)
                draw_util.line(sw * 0.5, sh, sx, sy, { col[1], col[2], col[3], 0.25 }, 1)
            end
        end
    end
end

return M
