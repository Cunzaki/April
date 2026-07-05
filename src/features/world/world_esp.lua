local settings = April.require("core.settings")
local cache = April.require("core.cache")
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
    menu.add_checkbox(T, G.WORLD, P, "Enable World ESP", false, { key = 0 })
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_world_boxes", "World 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_name", "World Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_distance", "World Show Distance", true, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_world_range", "World Range", 50, 2000, 500, { parent = P })
end

function M.scan_static()
    M._static = {}

    for _, entry in ipairs(esp_scan.scan_folders(maps.NODE_FOLDERS, maps.NODE_MAP, maps.NODE_LABELS, false)) do
        table.insert(M._static, entry)
    end
    for _, entry in ipairs(esp_scan.scan_folders(maps.PLANT_FOLDERS, maps.PLANT_MAP, maps.PLANT_LABELS, false)) do
        table.insert(M._static, entry)
    end

    rebuild_cache()
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan_dynamic()
    M._dynamic = esp_scan.scan_folders(maps.ANIMAL_FOLDERS, maps.ANIMAL_MAP, maps.ANIMAL_LABELS, true)
    rebuild_cache()
end

function M.scan()
    M.scan_static()
    M.scan_dynamic()
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_world_range", 500)
    local draw_boxes = settings.enabled("april_world_boxes")
    local show_name = settings.bool("april_world_show_name", true)
    local show_dist = settings.bool("april_world_show_distance", true)
    local me = env.get_local_player()
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.world) do
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

        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.WORLD_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "?") or ""
                if show_dist and me and me.position then
                    local dist_text = string.format("%dm", math.floor(dist))
                    if label ~= "" then
                        label = label .. " [" .. dist_text .. "]"
                    else
                        label = dist_text
                    end
                end
                if label ~= "" then
                    draw_util.text_centered(sx, sy, label, col, text_size)
                end
            end
        end

        ::continue::
    end
end

return M
