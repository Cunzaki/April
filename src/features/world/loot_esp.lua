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

local TOGGLES = {
    { id = "april_dropped_item", label = "Dropped Items", color = { 1, 0.8, 0, 1 } },
    { id = "april_wooden_crate", label = "Wooden Crate", color = { 0.6, 0.4, 0.2, 1 } },
    { id = "april_metal_crate", label = "Metal Crate", color = { 0.5, 0.5, 0.6, 1 } },
    { id = "april_steel_crate", label = "Steel Crate", color = { 0.7, 0.7, 0.8, 1 } },
    { id = "april_food_crate", label = "Food Crate", color = { 0.2, 0.8, 0.2, 1 } },
    { id = "april_timed_crate", label = "Timed Crate", color = { 1, 0.5, 0, 1 } },
    { id = "april_care_package", label = "Care Package", color = { 1, 0.2, 0.2, 1 } },
    { id = "april_body_bag", label = "Body Bag", color = { 0.3, 0.3, 0.3, 1 } },
    { id = "april_sleeper", label = "Sleepers", color = { 0.8, 0.4, 0.8, 1 } },
    { id = "april_trash_can", label = "Trash Can", color = { 0.45, 0.45, 0.45, 1 } },
    { id = "april_oil_barrel", label = "Oil Barrel", color = { 0.2, 0.2, 0.2, 1 } },
}

local function toggle_color(toggle_id)
    for _, t in ipairs(TOGGLES) do
        if t.id == toggle_id then
            return settings.color(toggle_id, t.color)
        end
    end
    return settings.color(toggle_id, { 1, 1, 1, 1 })
end

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

local function scan_named_loot_folder(folder, out)
    if not env.is_valid(folder) then return end
    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, model in ipairs(children) do
        if not env.is_valid(model) then goto continue end
        local name = model.Name or model.name
        local toggle_id = name and maps.LOOT_MAP[name]
        if toggle_id then
            append_loot_model(out, model, name, toggle_id, false)
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

local function collect_loners(out)
    local loners = folders.from_key("loners")
    if not env.is_valid(loners) then return end
    local children = env.safe_call(function() return loners:get_children() end) or {}
    for _, child in ipairs(children) do
        if not env.is_valid(child) then goto continue end
        local name = child.Name or child.name
        local toggle_id = name and maps.LOOT_MAP[name]
        if not toggle_id then goto continue end

        local cn = child.ClassName or child.class_name
        if cn == "Model" then
            append_loot_model(out, child, name, toggle_id, false)
        else
            local subs = env.safe_call(function() return child:get_children() end) or {}
            for _, model in ipairs(subs) do
                append_loot_model(out, model, name, toggle_id, false)
            end
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
    for _, t in ipairs(TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_loot_boxes", "3D Boxes", false, { parent = P })
    menu.add_slider_int(T, G.WORLD, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })
end

function M.scan_drops()
    M._drops = {}
    collect_drops(M._drops)
    rebuild_cache()
end

function M.scan_static()
    M._static = {}
    collect_loners(M._static)
    scan_named_loot_folder(folders.from_key("vegetation"), M._static)
    scan_named_loot_folder(folders.from_key("military"), M._static)
    scan_named_loot_folder(folders.from_key("events"), M._static)
    rebuild_cache()
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan()
    M.scan_static()
    M.scan_drops()
end

function M.update(dt) end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_loot_range", 300)
    local draw_boxes = settings.enabled("april_loot_boxes")
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
            local unlimited = entry.toggle_id == "april_timed_crate"
                or entry.toggle_id == "april_care_package"
            if not unlimited and dist > range then goto continue end
        end

        local col = toggle_color(entry.toggle_id)
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        local sx, sy, vis = esp_util.w2s(lx, ly, lz)
        if vis then
            local label = entry.name or "Loot"
            if me and me.position then
                label = string.format("%s [%dm]", label, math.floor(dist))
            end
            draw_util.text_centered(sx, sy, label, col, text_size)
        end

        ::continue::
    end
end

return M
