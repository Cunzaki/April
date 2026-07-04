local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local esp_scan = April.require("game.esp_scan")

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
    menu.add_checkbox(T, G.WORLD, P, "Enable Base ESP", false, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_base_boxes", "3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_distance", "Show Distance", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })
end

local function match_toggle_id(name)
    name = name or ""
    for _, t in ipairs(TOGGLES) do
        if name:find(t.match, 1, true) then
            return t.id
        end
    end
    return nil
end

function M.scan()
    cache.base = {}
    folders.iter_workspace_folders({ "bases", "deployables" }, function(key, folder)
        local found = folders.scan_descendants(folder, nil, 300)
        for _, inst in ipairs(found) do
            local toggle_id = match_toggle_id(inst.Name)
            if toggle_id then
                table.insert(cache.base, esp_scan.make_entry(inst, inst.Name, toggle_id))
            end
        end
    end)
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(dt) end

function M.draw()
    if not settings.enabled(P) then return end
    local range = settings.num("april_base_range", 150)
    local draw_boxes = settings.enabled("april_base_boxes")
    local me = env.get_local_player()
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.base) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local lx, ly, lz = esp_scan.label_position(entry)
        if not lx then goto continue end

        local dist = 0
        if me and me.position then
            local dx = lx - me.position.x
            local dy = ly - me.position.y
            local dz = lz - me.position.z
            dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            if dist > range then goto continue end
        end

        local col = settings.color(entry.toggle_id, { 1, 1, 1, 1 })
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        local sx, sy, vis = esp_util.w2s(lx, ly, lz)
        if vis then
            local label = entry.name or "Base"
            if settings.bool("april_base_distance", false) and me and me.position then
                label = string.format("%s [%dm]", label, math.floor(dist))
            end
            draw_util.text_centered(sx, sy, label, col, text_size)
        end

        ::continue::
    end
end

return M
