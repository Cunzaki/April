local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_loot_enabled"

local TOGGLES = {
    { id = "april_wooden_crate", label = "Wooden Crate", match = "Wooden", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_metal_crate", label = "Metal Crate", match = "Metal", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_steel_crate", label = "Steel Crate", match = "Steel", color = { 0.7, 0.7, 0.8, 1 } },
    { id = "april_food_crate", label = "Food Crate", match = "Food", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_timed_crate", label = "Timed Crate", match = "Timed", color = { 1, 0.5, 0, 1 } },
    { id = "april_care_package", label = "Care Package", match = "Care", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_body_bag", label = "Body Bag", match = "Body", color = { 0.3, 0.3, 0.3, 1 } },
    { id = "april_sleeper", label = "Sleepers", match = "Sleeper", color = { 0.8, 0.4, 0.8, 1 } },
}

function M.register_menu()
    local T, G = menu_util.bind("loot")
    menu.add_checkbox(T, G, "april_loot_enabled", "Enable Loot ESP", true, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G, t.id, t.label, true, { parent = P, colorpicker = t.color })
    end
    menu.add_slider_int(T, G, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })
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
    cache.loot = {}
    folders.iter_workspace_folders({ "loners", "military", "events", "drops" }, function(key, folder)
        local found = folders.scan_descendants(folder, nil, 400)
        for _, inst in ipairs(found) do
            table.insert(cache.loot, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_loot_enabled", true) then return end
    local range = settings.num("april_loot_range", 300)
    for _, entry in ipairs(cache.loot) do
        if env.is_valid(entry.inst) then
            local col = matches_toggle(entry.name)
            if col then
                draw_util.world_label(entry.inst, entry.name or "Loot", col, range)
            end
        end
    end
end

return M
