local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local G = April.require("core.menu_util").G
local T = April.require("core.menu_util").tab()

local M = {}
local P = "april_world_enabled"

local TOGGLES = {
    { id = "april_stone_node", label = "Stone Node", match = "Stone", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_metal_node", label = "Metal Node", match = "Metal", color = { 0.7, 0.5, 0.3, 1 } },
    { id = "april_phosphate_node", label = "Phosphate Node", match = "Phosphate", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_corn_plant", label = "Corn Plant", match = "Corn", color = { 1, 0.9, 0.3, 1 } },
    { id = "april_deer", label = "Deer", match = "Deer", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_boar", label = "Wild Boar", match = "Boar", color = { 0.4, 0.3, 0.2, 1 } },
    { id = "april_wolf", label = "Wolf", match = "Wolf", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_dropped_item", label = "Dropped Items", match = "Drop", color = { 1, 0.8, 0, 1 } },
}

function M.register_menu()
    menu.add_checkbox(T, G.WORLD, "april_world_enabled", "Enable World ESP", true, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, true, { parent = P, colorpicker = t.color })
    end
    menu.add_slider_int(T, G.WORLD, "april_world_range", "World Range", 50, 2000, 500, { parent = P })
end

local function matches_toggle(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if settings.bool(t.id, true) and name:find(t.match) then
            return settings.color(t.id, t.color)
        end
    end
    return nil
end

function M.scan()
    cache.world = {}
    folders.iter_workspace_folders({ "drops", "plants", "vegetation", "nodes", "animals" }, function(key, folder)
        local found = folders.scan_descendants(folder, nil, 400)
        for _, inst in ipairs(found) do
            table.insert(cache.world, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_world_enabled", true) then return end
    local range = settings.num("april_world_range", 500)
    for _, entry in ipairs(cache.world) do
        if env.is_valid(entry.inst) then
            local col = matches_toggle(entry.name)
            if col then
                draw_util.world_label(entry.inst, entry.name or "?", col, range)
            end
        end
    end
end

return M
