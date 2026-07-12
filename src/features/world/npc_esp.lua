local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local npcs = April.require("game.npcs")

local M = {}
local P = "april_npc_enabled"
local POS_REFRESH_BATCH = 8

M._pos_idx = 0
M._draw_targets = {}
M._draw_frame = -1

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)

    menu_util.section(T, G.WORLD, "NPCs")
    menu_util.register_keybind(T, G.WORLD, P, "NPC ESP", false, { colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G.WORLD, "april_npc_soldiers", "Soldiers", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_bosses", "Bosses (Bruno / Boris / Brutus)", false, menu_util.parent(P, { colorpicker = { 1, 0.5, 0.1, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box Mode", { "None", "2D", "Corner" }, 0, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "NPC Health Bar", false, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_skeleton", "NPC Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_offscreen", "NPC Offscreen Arrows", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_name", "NPC Show Name", true, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_show_distance", "NPC Show Distance", true, root)

    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)

    menu_util.bind_children(P, {
        "april_npc_soldiers", "april_npc_bosses", "april_npc_box_mode", "april_npc_health",
        "april_npc_skeleton", "april_npc_offscreen", "april_npc_show_name", "april_npc_show_distance",
        "april_npc_range",
    })
end

function M.begin_scan()
    return npcs.begin_scan()
end

function M.step_scan(state, batch)
    return npcs.step_scan(state, batch)
end

function M.complete_scan(state)
    cache.npcs = npcs.complete_scan(state)
    cache.stats.last_npc_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.scan()
    local state = M.begin_scan()
    while not M.step_scan(state, 9999) do end
    M.complete_scan(state)
end

local function kind_enabled(kind)
    if kind == "soldier" then return settings.bool("april_npc_soldiers", false) end
    if kind == "boss" then return settings.bool("april_npc_bosses", false) end
    return false
end

local function kind_color(kind)
    if kind == "boss" then return settings.color("april_npc_bosses", { 1, 0.5, 0.1, 1 }) end
    return settings.color("april_npc_soldiers", { 1, 0.3, 0.3, 1 })
end

local function entity_addr(p)
    if not p then return nil end
    if p.character then
        local addr = p.character.Address or p.character.address
        if addr then return tostring(addr) end
    end
    return (p.name or "?") .. ":" .. tostring(p.user_id or 0)
end

local function instance_addr(entry)
    if not entry or not entry.inst then return nil end
    return tostring(entry.inst.Address or entry.inst.address or entry.inst)
end

local function refresh_npc_position(entry)
    if entry.entity then
        local p = entry.entity
        if not p.is_alive then return false end
        if p.head_position then
            local pos = p.head_position
            entry.lx = pos.x
            entry.ly = pos.y
            entry.lz = pos.z
            return true
        end
        if p.position then
            local pos = p.position
            entry.lx = pos.x
            entry.ly = pos.y
            entry.lz = pos.z
            return true
        end
        return false
    end

    if not entry or not env.is_valid(entry.inst) then return false end
    local head = entry.head
    if head and env.is_valid(head) then
        local pos = head.Position or head.position
        if pos and pos.x then
            entry.lx = pos.x
            entry.ly = pos.y
            entry.lz = pos.z
            return true
        end
    end
    return false
end

local function collect_draw_targets(into)
    local out = into or {}
    for i = #out, 1, -1 do
        out[i] = nil
    end
    local seen = {}

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_local or not p.is_alive then goto continue end

            local kind = npcs.kind(p.name)
            if not kind then goto continue end
            if not p.is_workspace_entity and p.user_id ~= 0 then goto continue end

            local addr = entity_addr(p)
            if addr and seen[addr] then goto continue end
            if addr then seen[addr] = true end

            out[#out + 1] = {
                entity = p,
                name = p.name,
                kind = kind,
            }

            ::continue::
        end
    end

    for _, entry in ipairs(cache.npcs or {}) do
        if not entry or not entry.inst or not env.is_valid(entry.inst) then goto continue_scan end
        local addr = instance_addr(entry)
        if addr and seen[addr] then goto continue_scan end
        if addr then seen[addr] = true end
        out[#out + 1] = entry
        ::continue_scan::
    end

    return out
end

local function frame_draw_targets()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if M._draw_frame == now then
        return M._draw_targets
    end
    M._draw_frame = now
    return collect_draw_targets(M._draw_targets)
end

local function screen_bounds(entry)
    if entry.entity and entry.entity.get_bounds then
        local b = entry.entity:get_bounds()
        if b and b.valid and b.w > 0 and b.h > 0 then
            return b
        end
    end

    if entry.inst then
        return esp_util.model_screen_bounds(entry.inst)
    end

    return nil
end

local function draw_npc_box(bounds, col, box_mode)
    if not bounds or not bounds.valid then return end
    local x, y, w, h = bounds.x, bounds.y, bounds.w, bounds.h
    if box_mode == 1 then
        draw_util.box_esp(x, y, w, h, col, 0)
    else
        draw_util.box_esp(x, y, w, h, col, 1)
    end
end

local function draw_npc_health(bounds, entry)
    if not settings.bool("april_npc_health", false) then return end
    if not bounds or not bounds.valid or not draw or not draw.health_bar then return end

    local hp, max_hp
    if entry.entity then
        hp = entry.entity.health
        max_hp = entry.entity.max_health
    elseif entry.inst then
        local hum = env.safe_call(function()
            if entry.inst.find_first_child_of_class then
                return entry.inst:find_first_child_of_class("Humanoid")
            end
            return entry.inst:FindFirstChild("Humanoid")
        end)
        if hum then
            hp = hum.Health or hum.health
            max_hp = hum.MaxHealth or hum.max_health
        end
    end

    if not hp or not max_hp or max_hp <= 0 then return end
    -- Flush against box left edge (was -6, left a visible gap).
    draw.health_bar(bounds.x - 1, bounds.y, bounds.h, hp, max_hp)
end

function M.update(_dt)
    if not settings.enabled(P) then
        M._draw_targets = {}
        M._draw_frame = -1
        return
    end

    if cache.should_refresh_positions() then
        cache.prune_invalid(cache.npcs)
    end

    local list = frame_draw_targets()
    local n = #list
    if n == 0 then return end

    for _ = 1, POS_REFRESH_BATCH do
        M._pos_idx = (M._pos_idx % n) + 1
        refresh_npc_position(list[M._pos_idx])
    end
end

function M.draw()
    if not settings.enabled(P) then return end

    local range = settings.num("april_npc_range", 500)
    local range_sq = range * range
    local box_mode = settings.num("april_npc_box_mode", 0)
    local text_size = esp_util.text_size()
    local me = env.get_local_player()
    local me_pos = me and me.position

    for _, entry in ipairs(frame_draw_targets()) do
        if not kind_enabled(entry.kind) then goto continue end

        if entry.entity then
            if not entry.entity.is_alive then goto continue end
        elseif not env.is_valid(entry.inst) then
            goto continue
        end

        local col = kind_color(entry.kind)

        local lx, ly, lz = entry.lx, entry.ly, entry.lz
        if not lx then
            refresh_npc_position(entry)
            lx, ly, lz = entry.lx, entry.ly, entry.lz
        end

        if not lx and entry.entity and entry.entity.position then
            local pos = entry.entity.position
            lx, ly, lz = pos.x, pos.y, pos.z
            entry.lx, entry.ly, entry.lz = lx, ly, lz
        end
        if not lx then goto continue end

        local dist_sq = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
        end

        local bounds = screen_bounds(entry)
        local label_y = ly

        if bounds and bounds.valid then
            label_y = bounds.y
        else
            local sx, sy, vis = esp_util.w2s(lx, ly, lz)
            if not vis then
                if settings.bool("april_npc_offscreen", false) then
                    esp_util.draw_offscreen_to(lx, ly, lz, col, 12)
                end
                goto continue
            end
            label_y = sy
        end

        local label = entry.name or "NPC"
        local show_name = settings.bool("april_npc_show_name", true)
        local show_dist = settings.bool("april_npc_show_distance", true)

        if show_name or show_dist then
            if show_dist and me_pos then
                local dist_text = string.format("%dm", math.floor(math.sqrt(dist_sq)))
                if show_name then
                    label = label .. " [" .. dist_text .. "]"
                else
                    label = dist_text
                end
            elseif not show_name then
                label = nil
            end

            if label then
                local tx = bounds and bounds.valid and (bounds.x + bounds.w * 0.5) or lx
                local ty = label_y - 14
                if bounds and bounds.valid then
                    draw_util.text_centered(tx, ty, label, col, text_size)
                else
                    local sx, sy, vis = esp_util.w2s(lx, ly, lz)
                    if vis then
                        draw_util.text_centered(sx, sy - 14, label, col, text_size)
                    end
                end
            end
        end

        if settings.bool("april_npc_skeleton", false) then
            local sk = settings.color("april_npc_skeleton", { 1, 1, 1, 0.85 })
            if entry.entity and entry.entity.get_bones_screen then
                esp_util.draw_player_skeleton(entry.entity, sk, 1.5)
            elseif entry.inst then
                esp_util.draw_model_skeleton(entry.inst, sk, 1.5)
            end
        end

        if box_mode > 0 then
            if not bounds or not bounds.valid then
                bounds = screen_bounds(entry)
            end
            if bounds and bounds.valid then
                draw_npc_box(bounds, col, box_mode)
            end
        end

        draw_npc_health(bounds, entry)

        ::continue::
    end
end

return M
