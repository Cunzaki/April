local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_waypoints_enabled"

function M.register_menu()
    local T, G = menu_util.group("Waypoints")
    menu.add_checkbox(T, G, "april_waypoints_enabled", "Enable Waypoints", true, { key = 0 })
    menu.add_checkbox(T, G, "april_wp_dist", "Show Distance", true, { parent = P })
    menu.add_checkbox(T, G, "april_wp_line", "Draw Line", true, { parent = P })
    menu.add_checkbox(T, G, "april_wp_draw", "Draw Markers", true, { parent = P, colorpicker = { 0.2, 1, 0.8, 1 } })

    for i = 1, 5 do
        menu.add_button(T, G, "april_wp_set_" .. i, "Set Waypoint " .. i, function()
            local lp = env.get_local_player()
            if lp and lp.position then
                cache.waypoints[i] = {
                    name = "Waypoint " .. i,
                    pos = { x = lp.position.x, y = lp.position.y, z = lp.position.z },
                }
                print("[April] Waypoint " .. i .. " set")
            end
        end)
        menu.add_button(T, G, "april_wp_clear_" .. i, "Clear Waypoint " .. i, function()
            cache.waypoints[i] = nil
            print("[April] Waypoint " .. i .. " cleared")
        end)
    end
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_waypoints_enabled", true) then return end
    if not settings.bool("april_wp_draw", true) then return end
    if not utility or not utility.world_to_screen then return end

    local col = settings.color("april_wp_draw", { 0.2, 1, 0.8, 1 })
    local sw, sh = draw_util.screen_size()
    local me = env.get_local_player()

    for i, wp in pairs(cache.waypoints) do
        if wp and wp.pos then
            local sx, sy, vis = utility.world_to_screen(wp.pos.x, wp.pos.y, wp.pos.z)
            if vis then
                draw_util.circle(sx, sy, 6, col, true)
                local label = wp.name or ("WP" .. i)
                if settings.bool("april_wp_dist", true) and me and me.position then
                    local dx = wp.pos.x - me.position.x
                    local dy = wp.pos.y - me.position.y
                    local dz = wp.pos.z - me.position.z
                    local d = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
                    label = label .. " [" .. d .. "m]"
                end
                draw_util.text_centered(sx, sy - 16, label, col, 12)
                if settings.bool("april_wp_line", true) then
                    draw_util.line(sw * 0.5, sh, sx, sy, { col[1], col[2], col[3], 0.25 }, 1)
                end
            end
        end
    end
end

return M
