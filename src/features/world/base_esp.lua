local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")

local M = {}
local P = "april_base_enabled"

local TOGGLES = {
    { id = "april_base_cabinet", label = "Base Cabinet", match = "Cabinet", color = { 1, 0.8, 0, 1 } },
    { id = "april_storage_cabinet", label = "Storage Cabinet", match = "Storage", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_sleeping_bag", label = "Sleeping Bag", match = "Sleeping", color = { 0.8, 0.2, 0.2, 1 } },
    { id = "april_auto_turret", label = "Auto Turret", match = "Turret", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_wooden_door", label = "Wooden Door", match = "Wooden Door", color = { 0.5, 0.3, 0.1, 1 } },
    { id = "april_metal_door", label = "Metal Door", match = "Metal Door", color = { 0.5, 0.5, 0.6, 1 } },
}

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Base ESP")
    menu.add_checkbox(T, G.WORLD, "april_base_enabled", "Enable Base ESP", false, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_base_distance", "Show Distance", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })
end

local function matches_toggle(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if settings.bool(t.id, false) and name:find(t.match) then
            return settings.color(t.id, t.color)
        end
    end
    return nil
end

function M.scan()
    cache.base = {}
    folders.iter_workspace_folders({ "bases", "deployables" }, function(key, folder)
        local found = folders.scan_descendants(folder, nil, 300)
        for _, inst in ipairs(found) do
            table.insert(cache.base, { inst = inst, name = inst.Name, category = key })
        end
    end)
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.bool("april_base_enabled", false) then return end
    local range = settings.num("april_base_range", 150)
    for _, entry in ipairs(cache.base) do
        if env.is_valid(entry.inst) then
            local col = matches_toggle(entry.name)
            if col then
                local label = entry.name or "Base"
                draw_util.world_label(entry.inst, label, col, range)
            end
        end
    end
end

return M
