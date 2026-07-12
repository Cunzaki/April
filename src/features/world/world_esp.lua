local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local esp_scan = April.require("game.esp_scan")
local gpu_chams = April.require("core.gpu_chams")

local M = {}
local P = "april_world_enabled"
local CHAMS_ID = "april_world_chams"
local CHAMS_MODE = "april_world_chams_mode"
local CHAMS_COLOR = "april_world_chams_color"

local function world_chams_labels()
    local labels = {}
    for i, t in ipairs(maps.WORLD_TOGGLES) do
        labels[i] = t.label
    end
    return labels
end

local function world_chams_index_for(toggle_id)
    for i, t in ipairs(maps.WORLD_TOGGLES) do
        if t.id == toggle_id then return i end
    end
    return nil
end

local function world_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    for i = 1, #maps.WORLD_TOGGLES do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end

local function collect_world_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    if not me_pos then return end

    local range = settings.num("april_world_range", 500)
    local range_sq = range * range

    for _, entry in ipairs(cache.world) do
        if not env.is_valid(entry.inst) then goto continue end
        local idx = world_chams_index_for(entry.toggle_id)
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

local function refresh_dynamic_positions(list)
    if not list or #list == 0 then return end
    for _, entry in ipairs(list) do
        if entry and env.is_valid(entry.inst) then
            esp_scan.refresh_entry_position(entry)
        end
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Resources")
    menu_util.register_keybind(T, G.WORLD, P, "Resource ESP", false)
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_world_boxes", "Resource 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_name", "Resource Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_world_show_distance", "Resource Show Distance", true, { parent = P })
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_world_range", "Resource Range", 50, 2000, 500, { parent = P })

    local child_ids = { "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range" }
    for _, t in ipairs(maps.WORLD_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
    end

    if gpu_chams.available() then
        local labels = world_chams_labels()
        menu.add_multicombo(T, G.WORLD, CHAMS_ID, "Resource Chams", labels,
            gpu_chams.multicombo_defaults(#labels), { parent = P })
        gpu_chams.add_mode_color_menu(T, G.WORLD, P, CHAMS_MODE, CHAMS_COLOR,
            "Resource Chams Mode", "Resource Chams Color")
        child_ids[#child_ids + 1] = CHAMS_ID
        child_ids[#child_ids + 1] = CHAMS_MODE
        child_ids[#child_ids + 1] = CHAMS_COLOR

        gpu_chams.register_owner("world", {
            rescan_ms = 500,
            is_active = world_chams_active,
            style = function()
                return gpu_chams.mode_index(CHAMS_MODE, 0), gpu_chams.color_index(CHAMS_COLOR, 0)
            end,
            collect = collect_world_chams,
        })
        gpu_chams.wire_style_controls("world", CHAMS_MODE, CHAMS_COLOR)
        settings.on_change(CHAMS_ID, function()
            gpu_chams.sync_owner("world", true)
        end)
        settings.on_change(P, function(v)
            if v == true or v == 1 then
                gpu_chams.sync_owner("world", true)
            else
                gpu_chams.clear_owner("world")
            end
        end)
        for _, t in ipairs(maps.WORLD_TOGGLES) do
            settings.on_change(t.id, function()
                gpu_chams.sync_owner("world", true)
            end)
        end
    end

    menu_util.bind_children(P, child_ids)
end

function M.begin_static_scan()
    return {
        phase = 1,
        node_state = esp_scan.create_folder_scan(maps.NODE_FOLDERS, maps.NODE_MAP, maps.NODE_LABELS, false),
        plant_state = esp_scan.create_folder_scan(maps.PLANT_FOLDERS, maps.PLANT_MAP, maps.PLANT_LABELS, false),
        out = {},
    }
end

function M.step_static_scan(state, batch)
    if state.phase == 1 then
        local done = esp_scan.folder_scan_step(state.node_state, batch)
        if done then
            state.phase = 2
        end
        return false
    end

    local done = esp_scan.folder_scan_step(state.plant_state, batch)
    if done then
        state.out = {}
        for _, entry in ipairs(state.node_state.out) do
            table.insert(state.out, entry)
        end
        for _, entry in ipairs(state.plant_state.out) do
            table.insert(state.out, entry)
        end
    end
    return done
end

function M.complete_static_scan(state)
    M._static = state.out or {}
    rebuild_cache()
    cache.stats.last_world_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.begin_dynamic_scan()
    return esp_scan.create_folder_scan(maps.ANIMAL_FOLDERS, maps.ANIMAL_MAP, maps.ANIMAL_LABELS, true)
end

function M.step_dynamic_scan(state, batch)
    return esp_scan.folder_scan_step(state, batch)
end

function M.complete_dynamic_scan(state)
    M._dynamic = state.out or {}
    rebuild_cache()
end

function M.scan_static()
    local state = M.begin_static_scan()
    while not M.step_static_scan(state, 9999) do end
    M.complete_static_scan(state)
end

function M.scan_dynamic()
    local state = M.begin_dynamic_scan()
    while not M.step_dynamic_scan(state, 9999) do end
    M.complete_dynamic_scan(state)
end

function M.scan()
    M.scan_static()
    M.scan_dynamic()
end

function M.update(_dt)
    local world_on = settings.enabled(P)

    if world_on then
        if cache.should_refresh_positions() then
            cache.prune_invalid(M._static)
            cache.prune_invalid(M._dynamic)
            rebuild_cache()
            if #M._dynamic > 0 then
                refresh_dynamic_positions(M._dynamic)
            end
        end
    end

    if gpu_chams.available() then
        gpu_chams.sync_owner("world")
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_world_range", 500)
    local range_sq = range * range
    local draw_boxes = settings.enabled("april_world_boxes")
    local show_name = settings.bool("april_world_show_name", true)
    local show_dist = settings.bool("april_world_show_distance", true)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.world) do
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

        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.WORLD_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "?") or ""
                if show_dist and me_pos then
                    local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
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
