local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local npcs = April.require("game.npcs")

local M = {}
local P = "april_npc_enabled"
local HP_TTL_MS = 250

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function migrate_legacy_types()
    if M._legacy_migrated then return end
    M._legacy_migrated = true
    if not menu or not menu.set then return end

    if settings.bool("april_npc_soldiers", false) then
        menu.set("april_npc_soldier", true)
        if menu.set_color then
            menu.set_color("april_npc_soldier", settings.color("april_npc_soldiers", { 1, 0.3, 0.3, 1 }))
        end
    end
    if settings.bool("april_npc_bosses", false) then
        local color = settings.color("april_npc_bosses", { 1, 0.5, 0.1, 1 })
        for _, id in ipairs({ "april_npc_bruno", "april_npc_boris", "april_npc_brutus" }) do
            menu.set(id, true)
            if menu.set_color then menu.set_color(id, color) end
        end
    end
    if settings.bool("april_npc_heli", false) then
        menu.set("april_npc_attack_heli", true)
        if menu.set_color then
            menu.set_color("april_npc_attack_heli", settings.color("april_npc_heli", { 0.85, 0.2, 0.25, 1 }))
        end
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)

    menu_util.section(T, G.WORLD, "NPCs")
    menu_util.register_keybind(T, G.WORLD, P, "NPC ESP", false)
    menu.add_checkbox(T, G.WORLD, "april_npc_soldier", "Soldier", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_bruno", "Bruno", false, menu_util.parent(P, { colorpicker = { 1, 0.65, 0.2, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_boris", "Boris", false, menu_util.parent(P, { colorpicker = { 0.78, 0.42, 1, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_brutus", "Brutus", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.48, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_attack_heli", "Attack Heli", false, menu_util.parent(P, { colorpicker = { 0.85, 0.2, 0.25, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_btr", "BTR", false, menu_util.parent(P, { colorpicker = { 0.95, 0.25, 0.15, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_diver_dave", "Diver Dave", false, menu_util.parent(P, { colorpicker = { 0.2, 0.75, 1, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_pilot_pete", "Pilot Pete", false, menu_util.parent(P, { colorpicker = { 0.35, 1, 0.65, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box", { "None", "2D", "Corner" }, 1, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "NPC Health Bar", true, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_show_name", "NPC Show Name", true,
        menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_distance", "NPC Show Distance", true,
        menu_util.parent(P, { colorpicker = { 0.82, 0.84, 0.88, 0.92 } }))

    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)

    menu_util.bind_children(P, {
        "april_npc_soldier", "april_npc_bruno", "april_npc_boris", "april_npc_brutus",
        "april_npc_attack_heli", "april_npc_btr", "april_npc_diver_dave", "april_npc_pilot_pete",
        "april_npc_box_mode", "april_npc_health",
        "april_npc_show_name", "april_npc_show_distance",
        "april_npc_range",
    })
end

local function entity_bounds(player)
    if not player then return nil end
    local fn = player.GetBounds or player.get_bounds
    if not fn then return nil end
    return fn(player)
end

local function event_health(entry)
    local now = tick_ms()
    if entry.hp_t and now - entry.hp_t < HP_TTL_MS then
        return entry.hp, entry.max_hp
    end
    local health = npcs.read_health(entry.inst, entry.humanoid)
    entry.hp_t = now
    entry.hp = health and health.hp or nil
    entry.max_hp = health and (health.max_hp or health.hp) or nil
    return entry.hp, entry.max_hp
end

local function event_bounds(entry, dist)
    if not entry.root or not env.is_valid(entry.root) then return nil end
    local x, y, z = esp_util.vec3_pos(entry.root.Position or entry.root.position)
    if not x then return nil end
    entry.lx, entry.ly, entry.lz = x, y, z
    local vehicle = entry.vehicle == true
    return esp_util.head_body_screen_bounds(x, y, z, {
        dist = dist,
        body_h = vehicle and 8.0 or 5.0,
        width_mul = vehicle and 1.15 or 0.52,
        top_pad = vehicle and 2.0 or 0.35,
        bot_pad = vehicle and 2.0 or 0.15,
    })
end

function M.draw()
    migrate_legacy_types()
    if not settings.enabled(P) then return end

    local list = cache.npcs
    if not list or #list == 0 then return end

    local range = settings.num("april_npc_range", 500)
    local range_sq = range * range
    local box_mode = settings.num("april_npc_box_mode", 1)
    local show_health = settings.bool("april_npc_health", true)
    local show_name = settings.bool("april_npc_show_name", true)
    local show_dist = settings.bool("april_npc_show_distance", true)
    local enabled = {
        soldier = settings.bool("april_npc_soldier", false),
        bruno = settings.bool("april_npc_bruno", false),
        boris = settings.bool("april_npc_boris", false),
        brutus = settings.bool("april_npc_brutus", false),
        heli = settings.bool("april_npc_attack_heli", false),
        btr = settings.bool("april_npc_btr", false),
        diver_dave = settings.bool("april_npc_diver_dave", false),
        pilot_pete = settings.bool("april_npc_pilot_pete", false),
    }
    if not (enabled.soldier or enabled.bruno or enabled.boris or enabled.brutus
        or enabled.heli or enabled.btr or enabled.diver_dave or enabled.pilot_pete)
    then
        return
    end

    local colors = {
        soldier = settings.color("april_npc_soldier", { 1, 0.3, 0.3, 1 }),
        bruno = settings.color("april_npc_bruno", { 1, 0.65, 0.2, 1 }),
        boris = settings.color("april_npc_boris", { 0.78, 0.42, 1, 1 }),
        brutus = settings.color("april_npc_brutus", { 1, 0.3, 0.48, 1 }),
        heli = settings.color("april_npc_attack_heli", { 0.85, 0.2, 0.25, 1 }),
        btr = settings.color("april_npc_btr", { 0.95, 0.25, 0.15, 1 }),
        diver_dave = settings.color("april_npc_diver_dave", { 0.2, 0.75, 1, 1 }),
        pilot_pete = settings.color("april_npc_pilot_pete", { 0.35, 1, 0.65, 1 }),
    }
    local col_name = settings.color("april_npc_show_name", { 1, 0.3, 0.3, 1 })
    local col_dist = settings.color("april_npc_show_distance", { 0.82, 0.84, 0.88, 0.92 })

    local text_size = esp_util.text_size()
    local me = cache.local_player or env.get_local_player()
    local mx, my, mz = nil, nil, nil
    if me then
        mx, my, mz = esp_util.vec3_pos(me.Position or me.position)
    end

    for i = 1, #list do
        local entry = list[i]
        if not entry then goto continue end
        if not enabled[entry.kind] then goto continue end

        local col = colors[entry.kind] or colors.soldier

        local player = entry.entity
        if player and (player.IsAlive == false or player.is_alive == false) then goto continue end
        if not player and (not entry.inst or not env.is_valid(entry.inst)) then goto continue end

        local lx, ly, lz
        if player then
            lx, ly, lz = esp_util.vec3_pos(
                player.HeadPosition or player.head_position or player.Position or player.position
            )
            if lx then entry.lx, entry.ly, entry.lz = lx, ly, lz end
        else
            lx, ly, lz = entry.lx, entry.ly, entry.lz
        end
        if not lx then goto continue end

        local dist = 0
        if mx then
            local dx = lx - mx
            local dy = ly - my
            local dz = lz - mz
            local dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
            dist = math.sqrt(dist_sq)
        end

        local bounds = player and entity_bounds(player) or event_bounds(entry, dist)
        if not esp_util.bounds_usable(bounds) then goto continue end

        local ts = text_size
        if dist > 200 then ts = math.max(9, ts - 1) end
        if dist > 400 then ts = math.max(8, ts - 1) end

        local cx = bounds.x + bounds.w * 0.5
        local label = entry.name or "NPC"

        if show_name then
            draw_util.text_centered(cx, bounds.y - ts - 5, label, col_name, ts)
        end

        if box_mode == 1 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 0)
        elseif box_mode == 2 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 1)
        end

        if show_health then
            local hp, max_hp
            if player then
                hp = tonumber(player.Health or player.health)
                max_hp = tonumber(player.MaxHealth or player.max_health)
            else
                hp, max_hp = event_health(entry)
            end
            if hp and max_hp then
                draw_util.health_bar_on_box(bounds, hp, max_hp)
            end
        end

        if show_dist and mx then
            draw_util.text_centered(
                cx,
                bounds.y + bounds.h + 3,
                string.format("%dm", math.floor(dist + 0.5)),
                col_dist,
                ts
            )
        end

        ::continue::
    end
end

return M
