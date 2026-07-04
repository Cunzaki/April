local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local esp_scan = April.require("game.esp_scan")

local M = {}
local P = "april_world_enabled"

M._static = {}
M._dynamic = {}

local TOGGLES = {
    { id = "april_stone_node", label = "Stone Node", color = { 0.5, 0.5, 0.5, 1 } },
    { id = "april_metal_node", label = "Metal Node", color = { 0.7, 0.5, 0.3, 1 } },
    { id = "april_phosphate_node", label = "Phosphate Node", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_corn_plant", label = "Corn Plant", color = { 1, 0.9, 0.3, 1 } },
    { id = "april_tomato_plant", label = "Tomato Plant", color = { 1, 0.4, 0.3, 1 } },
    { id = "april_pumpkin_plant", label = "Pumpkin Plant", color = { 1, 0.5, 0.1, 1 } },
    { id = "april_deer", label = "Deer", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_boar", label = "Wild Boar", color = { 0.4, 0.3, 0.2, 1 } },
    { id = "april_wolf", label = "Wolf", color = { 0.5, 0.5, 0.5, 1 } },
}

local function scan_folder(map, label_map, dynamic)
    local out = {}
    local key = map == maps.NODE_MAP and "nodes" or (map == maps.PLANT_MAP and "plants" or "animals")
    local folder = folders.from_key(key)
    if not env.is_valid(folder) then return out end

    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, model in ipairs(children) do
        if not env.is_valid(model) then goto continue end
        local name = model.Name or model.name
        local toggle_id = name and map[name]
        if toggle_id then
            local label = (label_map and label_map[name]) or name
            table.insert(out, esp_scan.make_entry(model, label, toggle_id, { dynamic = dynamic }))
        end
        ::continue::
    end
    return out
end

local function rebuild_cache()
    cache.world = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.world, entry)
    end
    for _, entry in ipairs(M._dynamic) do
        table.insert(cache.world, entry)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu.add_label(T, G.WORLD, "Resources & Nodes")
    menu.add_checkbox(T, G.WORLD, P, "Enable World ESP", false, { key = 0 })
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_world_boxes", "3D Boxes", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_world_range", "World Range", 50, 2000, 500, { parent = P })
end

local function toggle_color(toggle_id)
    for _, t in ipairs(TOGGLES) do
        if t.id == toggle_id then
            return settings.color(toggle_id, t.color)
        end
    end
    return settings.color(toggle_id, { 1, 1, 1, 1 })
end

function M.scan_static()
    M._static = {}
    for _, entry in ipairs(scan_folder(maps.NODE_MAP, maps.NODE_LABELS, false)) do
        table.insert(M._static, entry)
    end
    for _, entry in ipairs(scan_folder(maps.PLANT_MAP, maps.PLANT_LABELS, false)) do
        table.insert(M._static, entry)
    end
    rebuild_cache()
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan_dynamic()
    M._dynamic = scan_folder(maps.ANIMAL_MAP, maps.ANIMAL_LABELS, true)
    rebuild_cache()
end

function M.scan()
    M.scan_static()
    M.scan_dynamic()
end

function M.update(dt) end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_world_range", 500)
    local draw_boxes = settings.enabled("april_world_boxes")
    local me = env.get_local_player()
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.world) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local lx, ly, lz = esp_scan.label_position(entry)
        if not lx then goto continue end

        if me and me.position then
            local dx = lx - me.position.x
            local dy = ly - me.position.y
            local dz = lz - me.position.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) > range then goto continue end
        end

        local col = toggle_color(entry.toggle_id)
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        local sx, sy, vis = esp_util.w2s(lx, ly, lz)
        if vis then
            local label = entry.name or "?"
            if me and me.position then
                local dx = lx - me.position.x
                local dy = ly - me.position.y
                local dz = lz - me.position.z
                label = string.format("%s [%dm]", label, math.floor(math.sqrt(dx * dx + dy * dy + dz * dz)))
            end
            draw_util.text_centered(sx, sy, label, col, text_size)
        end

        ::continue::
    end
end

return M
