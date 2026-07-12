local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local turret_stats = April.require("game.turret_stats")
local desync_vis = April.require("core.desync_vis")
local esp_scan = April.require("game.esp_scan")
local gpu_chams = April.require("core.gpu_chams")

local M = {}
local P = "april_base_enabled"
local CHAMS_ID = "april_base_chams"
local CHAMS_MODE = "april_base_chams_mode"
local CHAMS_COLOR = "april_base_chams_color"

local function base_chams_labels()
    local labels = {}
    for i, t in ipairs(maps.BASE_TOGGLES) do
        labels[i] = t.label
    end
    return labels
end

local function base_chams_index_for(toggle_id)
    for i, t in ipairs(maps.BASE_TOGGLES) do
        if t.id == toggle_id then return i end
    end
    return nil
end

local function base_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    for i = 1, #maps.BASE_TOGGLES do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end

local function collect_base_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    if not me_pos then return end

    local range = settings.num("april_base_range", 150)
    local range_sq = range * range

    for _, entry in ipairs(cache.base) do
        if not env.is_valid(entry.inst) then goto continue end
        local idx = base_chams_index_for(entry.toggle_id)
        if not idx or not gpu_chams.multicombo_selected(CHAMS_ID, idx) then goto continue end
        if not settings.enabled(entry.toggle_id) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        local dx = lx - me_pos.x
        local dy = ly - me_pos.y
        local dz = lz - me_pos.z
        if (dx * dx + dy * dy + dz * dz) > range_sq then goto continue end

        gpu_chams.cham_entry_part(entry, applied)
        ::continue::
    end
end

local function append_base_entry(state, model, type_name, toggle_id)
    if not model or not env.is_valid(model) then return end
    if not esp_scan.find_main_part(model) and not esp_scan.is_part(model) then return end

    state.seen = state.seen or {}
    local key = tostring(model.Address or model) .. ":" .. toggle_id
    if state.seen[key] then return end
    state.seen[key] = true

    table.insert(state.out, esp_scan.make_entry(model, type_name, toggle_id))
end

local function collect_base_container(state, container, type_name, toggle_id)
    if not env.is_valid(container) then return end

    if type_name == "Sleeping Bag" then
        local bag = env.safe_call(function()
            return container:find_first_child("SleepingBag")
                or container:FindFirstChild("SleepingBag")
                or container:find_first_child("Sleeping_Bag")
                or container:FindFirstChild("Sleeping_Bag")
        end)
        if bag and env.is_valid(bag) then
            append_base_entry(state, bag, type_name, toggle_id)
            return
        end
    end

    local cn = container.ClassName or container.class_name
    if cn == "Model" then
        append_base_entry(state, container, type_name, toggle_id)
        return
    end

    if esp_scan.find_main_part(container) or esp_scan.is_part(container) then
        append_base_entry(state, container, type_name, toggle_id)
    end

    local subs = env.safe_call(function() return container:get_children() end) or {}
    for _, child in ipairs(subs) do
        if not env.is_valid(child) then goto child_continue end
        local cc = child.ClassName or child.class_name
        if cc == "Model" then
            append_base_entry(state, child, type_name, toggle_id)
        elseif esp_scan.find_main_part(child) or esp_scan.is_part(child) then
            append_base_entry(state, child, type_name, toggle_id)
        end
        ::child_continue::
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G, "Bases")
    menu_util.register_keybind(T, G.WORLD, P, "Base ESP", false)
    for _, t in ipairs(maps.BASE_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
        if t.ring_id then
            menu.add_checkbox(T, G.WORLD, t.ring_id, t.label .. " Range Ring", false, { parent = t.id })
        end
    end
    menu.add_checkbox(T, G.WORLD, "april_base_boxes", "Base 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_name", "Base Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_base_show_distance", "Base Show Distance", false, { parent = P })
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_base_range", "Base Range", 50, 500, 150, { parent = P })

    local child_ids = { "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range" }
    for _, t in ipairs(maps.BASE_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
        if t.ring_id then
            child_ids[#child_ids + 1] = t.ring_id
        end
    end

    if gpu_chams.available() then
        local labels = base_chams_labels()
        menu.add_multicombo(T, G.WORLD, CHAMS_ID, "Base Chams", labels,
            gpu_chams.multicombo_defaults(#labels), { parent = P })
        gpu_chams.add_mode_color_menu(T, G.WORLD, P, CHAMS_MODE, CHAMS_COLOR,
            "Base Chams Mode", "Base Chams Color")
        child_ids[#child_ids + 1] = CHAMS_ID
        child_ids[#child_ids + 1] = CHAMS_MODE
        child_ids[#child_ids + 1] = CHAMS_COLOR

        gpu_chams.register_owner("base", {
            rescan_ms = 500,
            is_active = base_chams_active,
            style = function()
                return gpu_chams.mode_index(CHAMS_MODE, 0), gpu_chams.color_index(CHAMS_COLOR, 0)
            end,
            collect = collect_base_chams,
        })
        gpu_chams.wire_style_controls("base", CHAMS_MODE, CHAMS_COLOR)
        settings.on_change(CHAMS_ID, function()
            gpu_chams.sync_owner("base", true)
        end)
        settings.on_change(P, function(v)
            if v == true or v == 1 then
                gpu_chams.sync_owner("base", true)
            else
                gpu_chams.clear_owner("base")
            end
        end)
        for _, t in ipairs(maps.BASE_TOGGLES) do
            settings.on_change(t.id, function()
                gpu_chams.sync_owner("base", true)
            end)
        end
    end

    menu_util.bind_children(P, child_ids)
end

function M.begin_scan()
    return {
        areas = nil,
        ai = 1,
        items = nil,
        ii = 1,
        out = {},
        seen = {},
    }
end

function M.step_scan(state, batch)
    if not state.areas then
        state.areas = env.safe_call(function()
            local bases = folders.from_key("bases")
            if not env.is_valid(bases) then return {} end
            return bases:get_children()
        end) or {}
        state.ai = 1
        state.items = nil
        state.ii = 1
    end

    local processed = 0

    while processed < batch do
        if state.ai > #state.areas then
            return true
        end

        if not state.items then
            local area = state.areas[state.ai]
            if not env.is_valid(area) then
                state.ai = state.ai + 1
                processed = processed + 1
                goto continue
            end

            local area_name = area.Name or area.name or ""
            if maps.BASE_SKIP_AREAS[area_name] then
                state.ai = state.ai + 1
                processed = processed + 1
                goto continue
            end

            if maps.BASE_MAP[area_name] then
                state.items = { area }
                local children = env.safe_call(function() return area:get_children() end) or {}
                for _, child in ipairs(children) do
                    state.items[#state.items + 1] = child
                end
            else
                state.items = env.safe_call(function() return area:get_children() end) or {}
            end
            state.ii = 1
        end

        if state.ii > #state.items then
            state.ai = state.ai + 1
            state.items = nil
            goto continue
        end

        local type_folder = state.items[state.ii]
        state.ii = state.ii + 1
        processed = processed + 1

        if not env.is_valid(type_folder) then goto continue end

        local type_name = type_folder.Name or type_folder.name or ""
        local toggle_id = maps.BASE_MAP[type_name]
        if not toggle_id then goto continue end

        collect_base_container(state, type_folder, type_name, toggle_id)

        ::continue::
    end

    return false
end

function M.complete_scan(state)
    cache.base = state.out or {}
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan()
    local state = M.begin_scan()
    while not M.step_scan(state, 9999) do end
    M.complete_scan(state)
end

function M.update(_dt)
    if settings.enabled(P) and cache.should_refresh_positions() then
        cache.prune_invalid(cache.base)
    end

    if gpu_chams.available() then
        gpu_chams.sync_owner("base")
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_base_range", 150)
    local range_sq = range * range
    local draw_boxes = settings.enabled("april_base_boxes")
    local show_name = settings.bool("april_base_show_name", true)
    local show_dist = settings.bool("april_base_show_distance", false)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local text_size = esp_util.text_size()
    local label_groups = {}

    for _, entry in ipairs(cache.base) do
        if not settings.enabled(entry.toggle_id) then goto continue end
        if not env.is_valid(entry.inst) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end

        local dist_sq = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
        end

        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.BASE_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        local ring_id = maps.turret_ring_toggle(entry.toggle_id)
        if ring_id and settings.enabled(ring_id) then
            local activation = turret_stats.activation_range(entry.name)
            if activation then
                local ring_col = { col[1], col[2], col[3], 0.35 }
                desync_vis.draw_sphere_ring(lx, ly, lz, activation, ring_col, 1.5)
            end
        end

        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "Base") or ""
                if show_dist and me_pos then
                    local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
                    if label ~= "" then
                        label = label .. " [" .. dist_text .. "]"
                    else
                        label = dist_text
                    end
                end
                if label ~= "" then
                    local gk = string.format("%d:%d:%d",
                        math.floor(lx * 2), math.floor(ly * 2), math.floor(lz * 2))
                    local group = label_groups[gk]
                    if not group then
                        group = { sx = sx, sy = sy, lines = {} }
                        label_groups[gk] = group
                    end
                    group.lines[#group.lines + 1] = { label = label, col = col }
                end
            end
        end

        ::continue::
    end

    for _, group in pairs(label_groups) do
        for i, line in ipairs(group.lines) do
            local offset = (i - 1) * (text_size + 2)
            draw_util.text_centered(group.sx, group.sy - offset, line.label, line.col, text_size)
        end
    end
end

return M
