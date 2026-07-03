local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_esp_enabled"

function M.register_menu()
    local T, G = menu_util.group("Player ESP")
    menu.add_checkbox(T, G, "april_esp_enabled", "Player ESP", true, { key = 0 })
    menu.add_combo(T, G, "april_esp_box_mode", "Box Mode", { "None", "2D", "Corner" }, 1, { parent = P })
    menu.add_checkbox(T, G, "april_esp_name", "Name", true, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G, "april_esp_health", "Health Bar", true, { parent = P })
    menu.add_checkbox(T, G, "april_esp_distance", "Distance", true, { parent = P, colorpicker = { 0.7, 0.7, 0.7, 1 } })
    menu.add_checkbox(T, G, "april_esp_held_item", "Held Item", false, { parent = P, colorpicker = { 0.2, 0.8, 1, 1 } })
    menu.add_slider_int(T, G, "april_esp_max_dist", "Max Distance", 50, 5000, 1000, { parent = P })
    menu.add_checkbox(T, G, "april_esp_color", "Box Color", true, { parent = P, colorpicker = { 0.3, 1, 0.5, 1 } })
end

function M.scan()
    cache.players = {}
    if not entity or not entity.get_players then return end
    for _, p in ipairs(entity.get_players()) do
        if p.is_valid and not p.is_local then
            table.insert(cache.players, p)
        end
    end
    cache.stats.last_player_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.get_players()
    if entity and entity.get_players then
        return entity.get_players()
    end
    return cache.players
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_esp_enabled", true) then return end
    local max_dist = settings.num("april_esp_max_dist", 1000)
    local col = settings.color("april_esp_color", { 0.3, 1, 0.5, 1 })
    local box_mode = settings.num("april_esp_box_mode", 1)
    local me = entity and entity.get_local_player and entity.get_local_player()
    local text_size = settings.num("april_esp_text_size", 13)

    for _, p in ipairs(M.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        if me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            if dist > max_dist then goto continue end
        end

        local b = p:get_bounds()
        if not b or not b.valid then goto continue end

        if box_mode == 1 then
            draw_util.box_esp(b.x, b.y, b.w, b.h, col, 0)
        elseif box_mode == 2 then
            draw_util.box_esp(b.x, b.y, b.w, b.h, col, 1)
        end

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
            local nc = settings.color("april_esp_name", { 1, 1, 1, 1 })
            draw_util.text_centered(b.x + b.w * 0.5, b.y - 14, label, nc, text_size)
        end

        ::continue::
    end
end

return M
