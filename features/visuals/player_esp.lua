local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")

local M = {}

function M.register_menu()
    menu.add_group(April.TAB, "Players")
    menu.add_checkbox(April.TAB, "Players", "april_esp_enabled", "Player ESP", true)
    menu.add_checkbox(April.TAB, "Players", "april_esp_name", "Name", true)
    menu.add_checkbox(April.TAB, "Players", "april_esp_health", "Health Bar", true)
    menu.add_checkbox(April.TAB, "Players", "april_esp_distance", "Distance", true)
    menu.add_slider_int(April.TAB, "Players", "april_esp_max_dist", "Max Distance", 50, 2000, 800)
    menu.add_colorpicker(April.TAB, "Players", "april_esp_color", "ESP Color", { 0.3, 1, 0.5, 1 })
end

function M.scan()
    cache.players = {}
    if not entity or not entity.get_players then return end
    for _, p in ipairs(entity.get_players()) do
        if p.is_valid then table.insert(cache.players, p) end
    end
    cache.stats.last_player_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_esp_enabled", true) then return end
    local max_dist = settings.num("april_esp_max_dist", 800)
    local col = settings.color("april_esp_color", { 0.3, 1, 0.5, 1 })
    local me = entity and entity.get_local_player and entity.get_local_player()

    for _, p in ipairs(cache.players) do
        if p.is_local or not p.is_alive then goto continue end
        if me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist > max_dist then goto continue end
        end

        local b = p:get_bounds()
        if not b or not b.valid then goto continue end

        draw_util.box_esp(b.x, b.y, b.w, b.h, col, 0)

        if settings.bool("april_esp_health", true) then
            draw_util.health_bar(b.x - 4, b.y, b.h, p.health, p.max_health)
        end

        local label = ""
        if settings.bool("april_esp_name", true) then label = p.name or "?" end
        if settings.bool("april_esp_distance", true) and me and p.distance_to then
            local d = math.floor(p:distance_to(me.position))
            label = label .. (label ~= "" and " " or "") .. "[" .. d .. "m]"
        end
        if label ~= "" then
            draw_util.text_centered(b.x + b.w * 0.5, b.y - 14, label, { 1, 1, 1, 1 }, 13)
        end

        ::continue::
    end
end

return M
