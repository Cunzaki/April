local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")

local M = {}

local BASE_PATTERNS = {
    "Cabinet", "Door", "Turret", "Battery", "Solar", "Windmill", "Sleeping", "Box",
}

function M.register_menu()
    menu.add_group(April.TAB, "Base")
    menu.add_checkbox(April.TAB, "Base", "april_base_enabled", "Base ESP", true)
    menu.add_slider_int(April.TAB, "Base", "april_base_range", "Range", 50, 2000, 800)
    menu.add_colorpicker(April.TAB, "Base", "april_base_color", "Color", { 0.4, 0.7, 1, 1 })
end

function M.scan()
    cache.base = {}
    folders.iter_workspace_folders({ "bases" }, function(key, folder)
        local found = folders.scan_descendants(folder, BASE_PATTERNS, 500)
        for _, inst in ipairs(found) do
            table.insert(cache.base, { inst = inst, name = inst.Name })
        end
    end)
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_base_enabled", true) then return end
    local range = settings.num("april_base_range", 800)
    local col = settings.color("april_base_color", { 0.4, 0.7, 1, 1 })
    for _, entry in ipairs(cache.base) do
        if env.is_valid(entry.inst) then
            draw_util.world_label(entry.inst, entry.name or "Base", col, range)
        end
    end
end

return M
