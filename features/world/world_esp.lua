local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

local RESOURCE_NAMES = {
    "Stone", "Metal", "Phosphate", "Hemp", "Corn", "Pumpkin", "Wheat",
    "Deer", "Boar", "Wolf", "Node",
}

function M.register_menu()
    menu.add_group("World", "Resources")
    menu.add_checkbox("World", "Resources", "april_world_enabled", "Resource ESP", true)
    menu.add_slider_int("World", "Resources", "april_world_range", "Range", 50, 1500, 400)
    menu.add_colorpicker("World", "Resources", "april_world_color", "Color", { 0.8, 0.8, 0.2, 1 })
end

function M.scan()
    cache.world = {}
    local max = 300
    folders.iter_workspace_folders({ "drops", "plants", "vegetation", "nodes", "animals" }, function(key, folder)
        local children = folders.scan_descendants(folder, RESOURCE_NAMES, max)
        for _, inst in ipairs(children) do
            table.insert(cache.world, {
                inst = inst,
                name = inst.Name,
                class = inst.ClassName,
                category = key,
            })
        end
        local direct = folders.scan_children(folder, nil, 80)
        for _, inst in ipairs(direct) do
            table.insert(cache.world, {
                inst = inst,
                name = inst.Name,
                class = inst.ClassName,
                category = key,
            })
        end
    end)
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_world_enabled", true) then return end
    local range = settings.num("april_world_range", 400)
    local col = settings.color("april_world_color", { 0.8, 0.8, 0.2, 1 })
    for _, entry in ipairs(cache.world) do
        if env.is_valid(entry.inst) then
            local label = entry.name or entry.class
            draw_util.world_label(entry.inst, label, col, range)
        end
    end
end

return M
