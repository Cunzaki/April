local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local npcs = April.require("game.npcs")

local M = {}
local P = "april_npc_enabled"

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)

    menu_util.section(T, G.WORLD, "NPC ESP")
    menu.add_checkbox(T, G.WORLD, P, "Enable NPC ESP", false, { key = 0, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G.WORLD, "april_npc_soldiers", "Soldiers", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_bosses", "Bosses (Bruno / Boris / Brutus)", false, menu_util.parent(P, { colorpicker = { 1, 0.5, 0.1, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box Mode", { "None", "2D", "Corner" }, 0, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "NPC Health Bar", false, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_skeleton", "NPC Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_offscreen", "NPC Offscreen Arrows", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_name", "NPC Show Name", true, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_show_distance", "NPC Show Distance", true, root)
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)
end

function M.scan()
    cache.npcs = npcs.scan()
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function kind_enabled(kind)
    if kind == "soldier" then return settings.bool("april_npc_soldiers", false) end
    if kind == "boss" then return settings.bool("april_npc_bosses", false) end
    return false
end

local function kind_color(kind)
    if kind == "boss" then return settings.color("april_npc_bosses", { 1, 0.5, 0.1, 1 }) end
    return settings.color("april_npc_soldiers", { 1, 0.3, 0.3, 1 })
end

function M.update(dt) end

function M.draw()
    if not settings.bool(P, false) then return end

    local range = settings.num("april_npc_range", 500)
    local box_mode = settings.num("april_npc_box_mode", 0)
    local text_size = esp_util.text_size()
    local me = env.get_local_player()
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5

    for _, entry in ipairs(cache.npcs) do
        if not kind_enabled(entry.kind) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local col = kind_color(entry.kind)
        local head = entry.head
        local pos = head and (head.Position or head.position)
        if not pos or pos.x == nil then
            pos = entry.inst.Position or entry.inst.position
        end
        if not pos or pos.x == nil then goto continue end

        if me and me.position then
            local dx = pos.x - me.position.x
            local dy = pos.y - me.position.y
            local dz = pos.z - me.position.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) > range then goto continue end
        end

        local sx, sy, vis = esp_util.w2s(pos.x, pos.y, pos.z)
        if not vis then
            if settings.bool("april_npc_offscreen", false) then
                esp_util.draw_offscreen_arrow(cx, cy, sx, sy, col, 12)
            end
            goto continue
        end

        local label = entry.name or "NPC"
        local show_name = settings.bool("april_npc_show_name", true)
        local show_dist = settings.bool("april_npc_show_distance", true)

        if show_name or show_dist then
            if show_dist and me and me.position then
                local dx = pos.x - me.position.x
                local dy = pos.y - me.position.y
                local dz = pos.z - me.position.z
                local dist_text = string.format("%dm", math.floor(math.sqrt(dx * dx + dy * dy + dz * dz)))
                if show_name then
                    label = label .. " [" .. dist_text .. "]"
                else
                    label = dist_text
                end
            elseif not show_name then
                label = nil
            end

            if label then
                draw_util.text_centered(sx, sy - 14, label, col, text_size)
            end
        end

        if settings.bool("april_npc_skeleton", false) then
            local sk = settings.color("april_npc_skeleton", { 1, 1, 1, 0.85 })
            esp_util.draw_model_skeleton(entry.inst, sk, 1.5)
        end

        if box_mode > 0 then
            local pad = 18
            if box_mode == 1 then
                draw_util.box_esp(sx - pad, sy - pad * 2, pad * 2, pad * 3, col, 0)
            else
                draw_util.box_esp(sx - pad, sy - pad * 2, pad * 2, pad * 3, col, 1)
            end
        end

        ::continue::
    end
end

return M
