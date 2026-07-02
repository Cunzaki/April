local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local G = April.require("core.menu_util").G
local T = April.require("core.menu_util").tab()

local M = {}
local P = "april_npc_enabled"

function M.register_menu()
    menu.add_checkbox(T, G.NPCS, "april_npc_enabled", "Enable NPC ESP", true, { key = 0, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G.NPCS, "april_npc_soldiers", "Soldiers", true, { parent = P, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_combo(T, G.NPCS, "april_npc_box_mode", "NPC Box Mode", { "None", "2D", "Corner" }, 1, { parent = P })
    menu.add_checkbox(T, G.NPCS, "april_npc_health", "Health Bar", true, { parent = P })
    menu.add_checkbox(T, G.NPCS, "april_npc_name", "Name", true, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G.NPCS, "april_npc_distance", "Distance", true, { parent = P, colorpicker = { 0.7, 0.7, 0.7, 1 } })
    menu.add_checkbox(T, G.NPCS, "april_npc_skeleton", "Skeleton", false, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G.NPCS, "april_npc_offscreen", "Offscreen Arrows", false, { parent = P, colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_slider_int(T, G.NPCS, "april_npc_range", "NPC Range", 50, 2000, 500, { parent = P })
end

function M.scan()
    cache.npcs = {}
    folders.iter_workspace_folders({ "animals", "military", "npcs" }, function(key, folder)
        local found = folders.scan_descendants(folder, { "Soldier", "NPC", "Zombie", "BTR" }, 200)
        for _, inst in ipairs(found) do
            table.insert(cache.npcs, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_npc_enabled", true) then return end
    if not settings.bool("april_npc_soldiers", true) then return end
    local range = settings.num("april_npc_range", 500)
    local col = settings.color("april_npc_enabled", { 1, 0.3, 0.3, 1 })
    local box_mode = settings.num("april_npc_box_mode", 1)

    for _, entry in ipairs(cache.npcs) do
        if env.is_valid(entry.inst) then
            draw_util.world_label(entry.inst, entry.name or "NPC", col, range)
        end
    end
end

return M
