local settings = April.require("core.settings")
local cache = April.require("core.cache")
local folders = April.require("game.folders")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local maps = April.require("game.esp_maps")
local esp_scan = April.require("game.esp_scan")
local gpu_chams = April.require("core.gpu_chams")

local M = {}
local P = "april_loot_enabled"
local CHAMS_ID = "april_loot_chams"
local CHAMS_MODE = "april_loot_chams_mode"
local CHAMS_COLOR = "april_loot_chams_color"

M._static = {}
M._drops = {}

local UNLIMITED_RANGE = {
    april_timed_crate = true,
    april_care_package = true,
    april_btr_crate = true,
}

local function loot_chams_labels()
    local labels = {}
    for i, t in ipairs(maps.LOOT_TOGGLES) do
        labels[i] = t.label
    end
    return labels
end

local function loot_chams_index_for(toggle_id)
    for i, t in ipairs(maps.LOOT_TOGGLES) do
        if t.id == toggle_id then return i end
    end
    return nil
end

local function loot_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    for i = 1, #maps.LOOT_TOGGLES do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end

local function collect_loot_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    -- Fail closed: without local pos we must NOT cham the whole cache.
    if not me_pos then return end

    local range = settings.num("april_loot_range", 300) * 1.35
    local range_sq = range * range

    for _, entry in ipairs(cache.loot) do
        if not env.is_valid(entry.inst) then goto continue end
        local idx = loot_chams_index_for(entry.toggle_id)
        if not idx or not gpu_chams.multicombo_selected(CHAMS_ID, idx) then goto continue end
        if not settings.enabled(entry.toggle_id) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        if not UNLIMITED_RANGE[entry.toggle_id] then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            if (dx * dx + dy * dy + dz * dz) > range_sq then goto continue end
        end

        -- One visual part per entry (instance Address) - not every MeshPart in the world.
        gpu_chams.cham_entry_part(entry, applied)
        ::continue::
    end
end

local STATIC_SOURCES = {
    { kind = "root", key = "loners" },
    { kind = "root", key = "vegetation" },
    { kind = "root", key = "events" },
    { kind = "nested", key = "military" },
    { kind = "nested", key = "monuments" },
}

local function rebuild_cache()
    cache.loot = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.loot, entry)
    end
    for _, entry in ipairs(M._drops) do
        table.insert(cache.loot, entry)
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

local function loot_display_name(model, base_name)
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
        if label then return label end
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
        if extra then return base_name .. " (" .. extra .. ")" end
    end
    return base_name
end

local function append_loot_model(out, model, base_name, toggle_id, dynamic)
    if not env.is_valid(model) then return end
    local display = loot_display_name(model, base_name)
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

function M.begin_static_scan()
    return {
        si = 1,
        phase = "top",
        ci = 1,
        sub_ci = 1,
        children = nil,
        subs = nil,
        current = nil,
        out = {},
    }
end

function M.step_static_scan(state, batch)
    local processed = 0

    while processed < batch do
        if state.si > #STATIC_SOURCES then
            return true
        end

        local source = STATIC_SOURCES[state.si]
        if not state.children then
            state.phase = "top"
            state.ci = 1
            state.sub_ci = 1
            state.subs = nil
            state.current = nil
            state.children = env.safe_call(function()
                local folder = folders.from_key(source.key)
                if not env.is_valid(folder) then return {} end
                return folder:get_children()
            end) or {}
        end

        if state.ci > #state.children then
            state.si = state.si + 1
            state.children = nil
            goto continue
        end

        local child = state.children[state.ci]

        if state.phase == "top" then
            if not env.is_valid(child) then
                state.ci = state.ci + 1
                processed = processed + 1
                goto continue
            end

            local name = child.Name or child.name
            local toggle_id = name and maps.LOOT_MAP[name]

            if toggle_id then
                collect_loot_container(child, name, toggle_id, state.out, false)
                state.ci = state.ci + 1
                processed = processed + 1
            elseif source.kind == "nested" then
                state.current = child
                state.subs = env.safe_call(function() return child:get_children() end) or {}
                state.sub_ci = 1
                state.phase = "nested"
            else
                state.ci = state.ci + 1
                processed = processed + 1
            end
        else
            if not state.subs or state.sub_ci > #state.subs then
                state.phase = "top"
                state.ci = state.ci + 1
                state.current = nil
                state.subs = nil
                goto continue
            end

            local sub = state.subs[state.sub_ci]
            state.sub_ci = state.sub_ci + 1
            processed = processed + 1

            if not env.is_valid(sub) then goto continue end

            local sub_name = sub.Name or sub.name
            local sub_tid = sub_name and maps.LOOT_MAP[sub_name]
            if sub_tid then
                collect_loot_container(sub, sub_name, sub_tid, state.out, false)
            end
        end

        ::continue::
    end

    return false
end

function M.complete_static_scan(state)
    M._static = esp_scan.merge_entries(M._static, state.out)
    rebuild_cache()
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.begin_drops_scan()
    return { ci = 1, children = nil, out = {} }
end

function M.step_drops_scan(state, batch)
    if not state.children then
        state.children = env.safe_call(function()
            local drops = folders.from_key("drops")
            if not env.is_valid(drops) then return {} end
            return drops:get_children()
        end) or {}
        state.ci = 1
    end

    local processed = 0
    while processed < batch and state.ci <= #state.children do
        local model = state.children[state.ci]
        state.ci = state.ci + 1
        processed = processed + 1

        if not env.is_valid(model) then goto continue end
        local name = model.Name or model.name
        if name and name ~= "" then
            append_loot_model(state.out, model, name, "april_dropped_item", true)
        end

        ::continue::
    end

    return state.ci > #state.children
end

function M.complete_drops_scan(state)
    M._drops = esp_scan.merge_entries(M._drops, state.out)
    rebuild_cache()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Loot")
    menu_util.register_keybind(T, G.WORLD, P, "Loot ESP", false)
    for _, t in ipairs(maps.LOOT_TOGGLES) do
        menu.add_checkbox(T, G.WORLD, t.id, t.label, false, { parent = P, colorpicker = t.color })
    end
    menu.add_checkbox(T, G.WORLD, "april_loot_boxes", "Loot 3D Boxes", false, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_name", "Loot Show Name", true, { parent = P })
    menu.add_checkbox(T, G.WORLD, "april_loot_show_distance", "Loot Show Distance", true, { parent = P })
    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_loot_range", "Loot Range", 50, 2000, 300, { parent = P })

    local child_ids = { "april_loot_boxes", "april_loot_show_name", "april_loot_show_distance", "april_loot_range" }
    local toggle_ids = {}
    for _, t in ipairs(maps.LOOT_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
        toggle_ids[#toggle_ids + 1] = t.id
    end

    local chams_ids = {}
    if gpu_chams.available() then
        menu_util.section(T, G.WORLD, "Loot Mesh Chams")
        chams_ids = gpu_chams.wire_esp_chams({
            tab = T,
            group = G.WORLD,
            parent = P,
            chams_id = CHAMS_ID,
            mode_id = CHAMS_MODE,
            color_id = CHAMS_COLOR,
            labels = loot_chams_labels(),
            owner_id = "loot",
            master_id = P,
            is_active = loot_chams_active,
            collect = collect_loot_chams,
            rescan_ms = 2000,
            toggle_ids = toggle_ids,
        })
    end
    for _, id in ipairs(chams_ids) do
        child_ids[#child_ids + 1] = id
    end

    menu_util.bind_children(P, child_ids)
end

function M.scan_drops()
    local state = M.begin_drops_scan()
    while not M.step_drops_scan(state, 9999) do end
    M.complete_drops_scan(state)
end

function M.scan_static()
    local state = M.begin_static_scan()
    while not M.step_static_scan(state, 9999) do end
    M.complete_static_scan(state)
end

function M.scan()
    M.scan_static()
    M.scan_drops()
end

function M.update(_dt)
    local map_loot = settings.enabled("april_map_enabled") and settings.enabled("april_map_show_loot")
    local loot_on = settings.enabled(P)

    if loot_on or map_loot then
        if cache.should_prune() then
            cache.prune_invalid(M._static)
            cache.prune_invalid(M._drops)
            rebuild_cache()
        end
        if cache.should_refresh_positions() then
            if #M._drops > 0 then
                refresh_dynamic_positions(M._drops)
            end
        end
    end

    -- Always sync when active so disable / empty multicombo actually RevertChams.
    if gpu_chams.available() then
        local owner = gpu_chams.get_owner("loot")
        if loot_chams_active() or (owner and (owner.was_active or next(owner.applied))) then
            gpu_chams.sync_owner("loot")
        end
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_loot_range", 300)
    local range_sq = range * range
    local draw_boxes = settings.enabled("april_loot_boxes")
    local show_name = settings.bool("april_loot_show_name", true)
    local show_dist = settings.bool("april_loot_show_distance", true)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local text_size = esp_util.text_size()

    for _, entry in ipairs(cache.loot) do
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
            if not UNLIMITED_RANGE[entry.toggle_id] and dist_sq > range_sq then goto continue end
        end

        local col = settings.color(entry.toggle_id, maps.toggle_color(maps.LOOT_TOGGLES, entry.toggle_id))
        if draw_boxes then
            esp_util.draw_entry_boxes(entry, col, 1)
        end

        if show_name or show_dist then
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if vis then
                local label = show_name and (entry.name or "Loot") or ""
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
