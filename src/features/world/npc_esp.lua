local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local npcs = April.require("game.npcs")
local player_gear = April.require("game.player_gear")

local M = {}
local P = "april_npc_enabled"
local POS_REFRESH_BATCH = 8
local BOUNDS_TTL_MS = 1200

M._pos_idx = 0
M._draw_targets = {}
M._draw_frame = -1
M._bounds_cache = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function bounds_key(entry)
    if entry.entity then
        local p = entry.entity
        return "e:" .. tostring(p.user_id or 0) .. ":" .. tostring(p.name or "")
    end
    if entry.inst then
        return "i:" .. tostring(entry.inst.Address or entry.inst.address or entry.inst)
    end
    return "n:" .. tostring(entry.name or "?")
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.WORLD)
    local root = menu_util.parent(P)

    menu_util.section(T, G.WORLD, "NPCs")
    menu_util.register_keybind(T, G.WORLD, P, "NPC ESP", false, { colorpicker = { 1, 0.3, 0.3, 1 } })
    menu.add_checkbox(T, G.WORLD, "april_npc_soldiers", "Soldiers", false, menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_bosses", "Bosses (Bruno / Boris / Brutus)", false, menu_util.parent(P, { colorpicker = { 1, 0.5, 0.1, 1 } }))
    menu.add_combo(T, G.WORLD, "april_npc_box_mode", "NPC Box", { "None", "2D", "Corner" }, 1, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_health", "NPC Health Bar", true, root)
    menu.add_checkbox(T, G.WORLD, "april_npc_skeleton", "NPC Skeleton", false, menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.85 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_name", "NPC Show Name", true,
        menu_util.parent(P, { colorpicker = { 1, 0.3, 0.3, 1 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_distance", "NPC Show Distance", true,
        menu_util.parent(P, { colorpicker = { 0.82, 0.84, 0.88, 0.92 } }))
    menu.add_checkbox(T, G.WORLD, "april_npc_show_weapon", "NPC Weapon", false,
        menu_util.parent(P, { colorpicker = { 0.82, 0.84, 0.88, 0.92 } }))

    menu_util.gap(T, G.WORLD)
    menu.add_slider_int(T, G.WORLD, "april_npc_range", "NPC Range", 50, 2000, 500, root)

    menu_util.bind_children(P, {
        "april_npc_soldiers", "april_npc_bosses", "april_npc_box_mode", "april_npc_health",
        "april_npc_skeleton", "april_npc_show_name", "april_npc_show_distance",
        "april_npc_show_weapon", "april_npc_range",
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

local function resolve_npc_bounds(entry, dist)
    local key = bounds_key(entry)
    local now = tick_ms()
    local fresh = esp_util.npc_screen_bounds(entry, {
        dist = dist,
        point_size = esp_util.dist_point_size(dist),
    })
    return esp_util.hold_bounds(M._bounds_cache, key, fresh, now, BOUNDS_TTL_MS)
end

local function read_npc_hp(entry)
    if entry.entity then
        local hp = tonumber(entry.entity.health)
        local max_hp = tonumber(entry.entity.max_health)
        if hp and max_hp and max_hp > 0 then
            return hp, max_hp
        end
    end
    if entry.inst and env.is_valid(entry.inst) then
        local hum = env.safe_call(function()
            if entry.inst.find_first_child_of_class then
                return entry.inst:find_first_child_of_class("Humanoid")
            end
            return entry.inst:FindFirstChild("Humanoid")
        end)
        if hum then
            local hp = tonumber(hum.Health or hum.health)
            local max_hp = tonumber(hum.MaxHealth or hum.max_health)
            if hp and max_hp and max_hp > 0 then
                return hp, max_hp
            end
        end
    end
    return nil, nil
end

function M.update(_dt)
    if not settings.enabled(P) then
        M._draw_targets = {}
        M._draw_frame = -1
        M._bounds_cache = {}
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
    local box_mode = settings.num("april_npc_box_mode", 1)
    local show_health = settings.bool("april_npc_health", true)
    local text_size = esp_util.text_size()
    local me = env.get_local_player()
    local me_pos = me and me.position
    local now = tick_ms()

    -- Prune stale hold cache
    for key, ent in pairs(M._bounds_cache) do
        if not ent or (now - (ent.t or 0)) > BOUNDS_TTL_MS * 3 then
            M._bounds_cache[key] = nil
        end
    end

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

        local dist = 0
        if me_pos then
            local dx = lx - me_pos.x
            local dy = ly - me_pos.y
            local dz = lz - me_pos.z
            local dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
            dist = math.sqrt(dist_sq)
        end

        local _, _, head_vis = esp_util.w2s(lx, ly, lz)

        -- Skeleton is independent of box bounds (same as player ESP).
        if settings.bool("april_npc_skeleton", false) then
            local sk = settings.color("april_npc_skeleton", { 1, 1, 1, 0.85 })
            if entry.entity and entry.entity.get_bones_screen then
                esp_util.draw_player_skeleton(entry.entity, sk, 1)
            elseif entry.inst then
                esp_util.draw_model_skeleton(entry.inst, sk, 1)
            end
        end

        local bounds = resolve_npc_bounds(entry, dist)
        if not esp_util.bounds_usable(bounds) then
            if not head_vis then goto continue end
            local size = esp_util.dist_point_size(dist)
            bounds = esp_util.guard_tiny_bounds(
                esp_util.point_screen_bounds(lx, ly, lz, size),
                dist
            )
            if not esp_util.bounds_usable(bounds) then goto continue end
        elseif not head_vis then
            local sw, sh = draw_util.screen_size()
            local cx = bounds.x + bounds.w * 0.5
            local cy = bounds.y + bounds.h * 0.5
            local margin = 120
            if cx < -margin or cy < -margin or cx > sw + margin or cy > sh + margin then
                goto continue
            end
        end

        local ts = text_size
        if dist > 250 then
            ts = math.max(11, ts - 1)
        end

        local cx = bounds.x + bounds.w * 0.5
        local label = entry.name or "NPC"
        local show_name = settings.bool("april_npc_show_name", true)
        local show_dist = settings.bool("april_npc_show_distance", true)
        local show_wpn = settings.bool("april_npc_show_weapon", false)

        -- Top labels match player ESP (name / weapon above, distance below).
        local top = {}
        if show_name then
            top[#top + 1] = {
                text = label,
                col = settings.color("april_npc_show_name", col),
            }
        end
        if show_wpn then
            local wpn = nil
            if entry.entity then
                pcall(function() wpn = player_gear.held_name(entry.entity) end)
            end
            if (not wpn or wpn == "") and entry.inst then
                pcall(function() wpn = player_gear.held_name_from_character(entry.inst) end)
            end
            if wpn and wpn ~= "" then
                top[#top + 1] = {
                    text = tostring(wpn),
                    col = settings.color("april_npc_show_weapon", { 0.82, 0.84, 0.88, 0.92 }),
                }
            end
        end

        if #top > 0 then
            local ty = bounds.y - 4 - (#top * (ts + 1))
            for i = 1, #top do
                draw_util.text_centered(cx, ty + (i - 1) * (ts + 1), top[i].text, top[i].col, ts)
            end
        end

        -- Same box + health path as player ESP (1px-gap custom bar via health_bar_on_box).
        if box_mode == 1 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 0)
        elseif box_mode == 2 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 1)
        end

        if show_health then
            local hp, max_hp = read_npc_hp(entry)
            if hp and max_hp then
                draw_util.health_bar_on_box(bounds, hp, max_hp)
            end
        end

        if show_dist and me_pos then
            draw_util.text_centered(
                cx,
                bounds.y + bounds.h + 3,
                string.format("%dm", math.floor(dist + 0.5)),
                settings.color("april_npc_show_distance", { 0.82, 0.84, 0.88, 0.92 }),
                ts
            )
        end

        ::continue::
    end
end

return M
