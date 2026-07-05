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
local P = "april_base_enabled"

local function resolve_model(container, type_name)
    if not env.is_valid(container) then return nil end

    if type_name == "Sleeping Bag" then
        local bag = env.safe_call(function()
            return container:find_first_child("SleepingBag")
                or container:FindFirstChild("SleepingBag")
                or container:find_first_child("Sleeping_Bag")
                or container:FindFirstChild("Sleeping_Bag")
        end)
        if bag and env.is_valid(bag) then return bag end

        local children = env.safe_call(function() return container:get_children() end) or {}
        for _, child in ipairs(children) do
            local cn = child.ClassName or child.class_name
            if cn == "Model" and env.is_valid(child) then
                return child
            end
        end
    end

    local cn = container.ClassName or container.class_name
    if cn == "Model" then return container end

    if esp_scan.find_main_part(container) then return container end

    local children = env.safe_call(function() return container:get_children() end) or {}
    for _, child in ipairs(children) do
        if env.is_valid(child) then
            local cc = child.ClassName or child.class_name
            if cc == "Model" then return child end
        end
    end

    return container
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Base ESP")
    menu.add_checkbox(T, G.WORLD, P, "Enable Base ESP", false, { key = 0 })
    for _, t in ipairs(maps.BASE_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_base_boxes", "Base 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_name", "Base Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_distance", "Base Show Distance", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })
end

function M.scan()
    cache.base = {}
    local bases = folders.from_key("bases")
    if not env.is_valid(bases) then return end

    local areas = env.safe_call(function() return bases:get_children() end) or {}
    for _, area in ipairs(areas) do
        if not env.is_valid(area) then goto continue_area end

        local area_name = area.Name or area.name or ""
        if maps.BASE_SKIP_AREAS[area_name] then goto continue_area end

        local items = {}
        if maps.BASE_MAP[area_name] then
            items[1] = area
        else
            items = env.safe_call(function() return area:get_children() end) or {}
        end

        for _, type_folder in ipairs(items) do
            if not env.is_valid(type_folder) then goto continue_item end

            local type_name = type_folder.Name or type_folder.name or ""
            local toggle_id = maps.BASE_MAP[type_name]
            if not toggle_id then goto continue_item end

            local model = resolve_model(type_folder, type_name)
            if not model or not env.is_valid(model) then goto continue_item end
            if not esp_scan.find_main_part(model) and not esp_scan.is_part(model) then goto continue_item end

            table.insert(cache.base, esp_scan.make_entry(model, type_name, toggle_id))
            ::continue_item::
        end

        ::continue_area::
    end

    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_base_range", 150)
    local draw_boxes = settings.enabled("april_base_boxes")
    local show_name = settings.bool("april_base_show_name", true)
    local show_dist = settings.bool("april_base_show_distance", false)
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

        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.BASE_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "Base") or ""
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
