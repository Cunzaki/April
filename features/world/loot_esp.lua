local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

local LOOT_PATTERNS = {
    "Crate", "Barrel", "Egg", "Care", "Boat", "Flycopter", "Loner", "Loot",
}

function M.register_menu()
    menu.add_group(April.TAB, "Loot")
    menu.add_checkbox(April.TAB, "Loot", "april_loot_enabled", "Loot ESP", true)
    menu.add_slider_int(April.TAB, "Loot", "april_loot_range", "Range", 50, 2000, 600)
    menu.add_colorpicker(April.TAB, "Loot", "april_loot_color", "Color", { 1, 0.6, 0.2, 1 })
end

function M.scan()
    cache.loot = {}
    folders.iter_workspace_folders({ "loners", "military", "events" }, function(key, folder)
        local found = folders.scan_descendants(folder, LOOT_PATTERNS, 400)
        for _, inst in ipairs(found) do
            table.insert(cache.loot, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_loot_enabled", true) then return end
    local range = settings.num("april_loot_range", 600)
    local col = settings.color("april_loot_color", { 1, 0.6, 0.2, 1 })
    for _, entry in ipairs(cache.loot) do
        if env.is_valid(entry.inst) then
            draw_util.world_label(entry.inst, entry.name or "Loot", col, range)
        end
    end
end

return M
