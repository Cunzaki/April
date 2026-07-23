--[[
  Base ESP — same cache / incremental-scan system as world + loot.

  - M._static + rebuild → cache.base
  - iscan begin/step/complete (shared thread budget)
  - prune_invalid on cache.should_prune()
  - draw filters by range on_frame (no custom per-frame hydrate)
]]

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

M._static = {}

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

local function rebuild_cache()
    cache.base = {}
    for _, entry in ipairs(M._static) do
        table.insert(cache.base, entry)
    end
end

local function append_base_model(out, model, type_name, toggle_id)
    if not env.is_valid(model) then return end
    if not esp_scan.find_main_part(model) and not esp_scan.is_part(model) then return end
    table.insert(out, esp_scan.make_entry(model, type_name, toggle_id, { dynamic = false }))
end

-- Mirror loot collect_loot_container, but sleep-bag aware.
local function collect_base_container(container, type_name, toggle_id, out)
    if not env.is_valid(container) then return end

    if type_name == "Sleeping Bag" then
        local bag = env.safe_call(function()
            return container:find_first_child("SleepingBag")
                or container:FindFirstChild("SleepingBag")
                or container:find_first_child("Sleeping_Bag")
                or container:FindFirstChild("Sleeping_Bag")
        end)
        if bag and env.is_valid(bag) then
            append_base_model(out, bag, type_name, toggle_id)
            return
        end
    end

    local cn = container.ClassName or container.class_name
    if cn == "Model" or esp_scan.is_part(container) then
        append_base_model(out, container, type_name, toggle_id)
        return
    end

    local subs = env.safe_call(function() return container:get_children() end) or {}
    for _, model in ipairs(subs) do
        local mc = model.ClassName or model.class_name
        if mc == "Model" or esp_scan.is_part(model) or esp_scan.find_main_part(model) then
            append_base_model(out, model, type_name, toggle_id)
        end
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    menu_util.section(T, G.WORLD, "Bases")
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
    local toggle_ids = {}
    for _, t in ipairs(maps.BASE_TOGGLES) do
        child_ids[#child_ids + 1] = t.id
        toggle_ids[#toggle_ids + 1] = t.id
        if t.ring_id then
            child_ids[#child_ids + 1] = t.ring_id
        end
    end

    local chams_ids = {}
    if gpu_chams.available() then
        menu_util.section(T, G.WORLD, "Base Mesh Chams")
        chams_ids = gpu_chams.wire_esp_chams({
            tab = T,
            group = G.WORLD,
            parent = P,
            chams_id = CHAMS_ID,
            mode_id = CHAMS_MODE,
            color_id = CHAMS_COLOR,
            labels = base_chams_labels(),
            owner_id = "base",
            master_id = P,
            is_active = base_chams_active,
            collect = collect_base_chams,
            rescan_ms = 900,
            toggle_ids = toggle_ids,
        })
    end
    for _, id in ipairs(chams_ids) do
        child_ids[#child_ids + 1] = id
    end

    menu_util.bind_children(P, child_ids)
end

-- Same shape as loot begin/step/complete (nested folder walk, one child per batch unit).
function M.begin_static_scan()
    return {
        ai = 1,
        phase = "top",
        ci = 1,
        sub_ci = 1,
        areas = nil,
        children = nil,
        subs = nil,
        out = {},
    }
end

function M.step_static_scan(state, batch)
    if not state.areas then
        state.areas = env.safe_call(function()
            local bases = folders.from_key("bases")
            if not env.is_valid(bases) then return {} end
            return bases:get_children()
        end) or {}
        state.ai = 1
    end

    local processed = 0

    while processed < batch do
        if state.ai > #state.areas then
            return true
        end

        local area = state.areas[state.ai]

        if not state.children then
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

            state.phase = "top"
            state.ci = 1
            state.sub_ci = 1
            state.subs = nil

            -- Same as loot nested: area children are type folders (or the area itself is typed).
            if maps.BASE_MAP[area_name] then
                state.children = { area }
            else
                state.children = env.safe_call(function() return area:get_children() end) or {}
            end
        end

        if state.ci > #state.children then
            state.ai = state.ai + 1
            state.children = nil
            state.subs = nil
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
            local toggle_id = name and maps.BASE_MAP[name]

            if toggle_id then
                -- Emit models one-at-a-time (base folders are denser than loot crates).
                state.subs = env.safe_call(function()
                    local cn = child.ClassName or child.class_name
                    if cn == "Model" or esp_scan.is_part(child) then
                        return { child }
                    end
                    if name == "Sleeping Bag" then
                        local bag = child:find_first_child("SleepingBag")
                            or child:FindFirstChild("SleepingBag")
                            or child:find_first_child("Sleeping_Bag")
                            or child:FindFirstChild("Sleeping_Bag")
                        if bag then return { bag } end
                    end
                    return child:get_children()
                end) or {}
                state.sub_ci = 1
                state.phase = "models"
                state._type_name = name
                state._toggle_id = toggle_id
            else
                state.ci = state.ci + 1
                processed = processed + 1
            end
        else
            if not state.subs or state.sub_ci > #state.subs then
                state.phase = "top"
                state.ci = state.ci + 1
                state.subs = nil
                state._type_name = nil
                state._toggle_id = nil
                goto continue
            end

            local model = state.subs[state.sub_ci]
            state.sub_ci = state.sub_ci + 1
            processed = processed + 1

            if env.is_valid(model) then
                append_base_model(state.out, model, state._type_name, state._toggle_id)
            end
        end

        ::continue::
    end

    return false
end

function M.complete_static_scan(state)
    M._static = esp_scan.merge_entries(M._static, state.out)
    rebuild_cache()
    cache.stats.last_base_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

-- Aliases so older call sites / map code keep working.
M.begin_scan = M.begin_static_scan
M.step_scan = M.step_static_scan
M.complete_scan = M.complete_static_scan

function M.scan()
    local state = M.begin_static_scan()
    while not M.step_static_scan(state, 9999) do end
    M.complete_static_scan(state)
end

function M.update(_dt)
    local map_base = settings.enabled("april_map_enabled") and settings.enabled("april_map_show_base")
    local base_on = settings.enabled(P)

    if base_on or map_base then
        if cache.should_prune() then
            cache.prune_invalid(M._static)
            rebuild_cache()
        end
    end

    if gpu_chams.available() then
        local owner = gpu_chams.get_owner("base")
        if base_chams_active() or (owner and (owner.was_active or next(owner.applied))) then
            gpu_chams.sync_owner("base")
        end
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
                desync_vis.draw_sphere_ring(lx, ly, lz, activation, { col[1], col[2], col[3], 0.35 }, 1.5)
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
                    draw_util.text_centered(sx, sy, label, col, text_size)
                end
            end
        end

        ::continue::
    end
end

return M
