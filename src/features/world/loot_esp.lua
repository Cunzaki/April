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
local P = "april_loot_enabled"

M._static = {}
M._drops = {}

local UNLIMITED_RANGE = {
    april_timed_crate = true,
    april_care_package = true,
    april_btr_crate = true,
}

local function append_loot_model(out, model, base_name, toggle_id, dynamic)
    if not env.is_valid(model) then return end

    local display = base_name
    if base_name == "Sleeper" then
        local label = env.safe_call(function()
            local desc = model:get_descendants()
            for _, d in ipairs(desc or {}) do
                if (d.ClassName or d.class_name) == "TextLabel" then
                    local text = d.Text or d.text
                    if text and text ~= "" then return text .. " (Sleeper)" end
                end
            end
            return nil
        end)
        if label then display = label end
    elseif base_name == "Timed Crate" then
        local extra = env.safe_call(function()
            local desc = model:get_descendants()
            for _, d in ipairs(desc or {}) do
                if (d.ClassName or d.class_name) == "TextLabel" then
                    local text = d.Text or d.text
                    if text and text ~= "" then return text end
                end
            end
            return nil
        end)
        if extra then display = base_name .. " (" .. extra .. ")" end
    end

    table.insert(out, esp_scan.make_entry(model, display, toggle_id, { dynamic = dynamic }))
end

local function collect_loot_container(container, type_name, toggle_id, out, dynamic)
    if not env.is_valid(container) then return end
    local cn = container.ClassName or container.class_name
    if cn == "Model" then
        append_loot_model(out, container, type_name, toggle_id, dynamic)
        return
    end

    local subs = env.safe_call(function() return container:get_children() end) or {}
    for _, model in ipairs(subs) do
        append_loot_model(out, model, type_name, toggle_id, dynamic)
    end
end

local function scan_loot_root(folder, out, dynamic)
    if not env.is_valid(folder) then return end
    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, child in ipairs(children) do
        if not env.is_valid(child) then goto continue end
        local name = child.Name or child.name
        local toggle_id = name and maps.LOOT_MAP[name]
        if toggle_id then
            collect_loot_container(child, name, toggle_id, out, dynamic)
        end
        ::continue::
    end
end

local function scan_loot_nested(folder, out, dynamic)
    if not env.is_valid(folder) then return end
    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, child in ipairs(children) do
        if not env.is_valid(child) then goto continue end
        local name = child.Name or child.name
        local toggle_id = name and maps.LOOT_MAP[name]
        if toggle_id then
            collect_loot_container(child, name, toggle_id, out, dynamic)
        else
            local subs = env.safe_call(function() return child:get_children() end) or {}
            for _, sub in ipairs(subs) do
                local sub_name = sub.Name or sub.name
                local sub_tid = sub_name and maps.LOOT_MAP[sub_name]
                if sub_tid then
                    collect_loot_container(sub, sub_name, sub_tid, out, dynamic)
                end
            end
        end
        ::continue::
    end
end

local function collect_drops(out)
    local drops = folders.from_key("drops")
    if not env.is_valid(drops) then return end
    local children = env.safe_call(function() return drops:get_children() end) or {}
    for _, model in ipairs(children) do
        if not env.is_valid(model) then goto continue end
        local name = model.Name or model.name
        if name and name ~= "" then
            append_loot_model(out, model, name, "april_dropped_item", true)
        end
        ::continue::
    end
end

local function rebuild_cache()
    cache.loot = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.loot, entry)
    end
    for _, entry in ipairs(M._drops) do
        table.insert(cache.loot, entry)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Loot ESP")
    menu.add_checkbox(T, G.WORLD, P, "Enable Loot ESP", false, { key = 0 })
    for _, t in ipairs(maps.LOOT_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_loot_boxes", "Loot 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_name", "Loot Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_distance", "Loot Show Distance", true, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })
end

function M.scan_drops()
    M._drops = {}
    collect_drops(M._drops)
    rebuild_cache()
end

function M.scan_static()
    M._static = {}

    scan_loot_root(folders.from_key("loners"), M._static, false)
    scan_loot_root(folders.from_key("vegetation"), M._static, false)
    scan_loot_root(folders.from_key("events"), M._static, false)
    scan_loot_nested(folders.from_key("military"), M._static, false)
    scan_loot_nested(folders.from_key("monuments"), M._static, false)

    rebuild_cache()
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan()
    M.scan_static()
    M.scan_drops()
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_loot_range", 300)
    local draw_boxes = settings.enabled("april_loot_boxes")
    local show_name = settings.bool("april_loot_show_name", true)
    local show_dist = settings.bool("april_loot_show_distance", true)
    local me = env.get_local_player()
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.loot) do
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
            if not UNLIMITED_RANGE[entry.toggle_id] and dist > range then goto continue end
        end

        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.LOOT_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "Loot") or ""
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
