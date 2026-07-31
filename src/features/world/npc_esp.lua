local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local ep = April.require("core.entity_props")
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
        return "e:" .. tostring(ep.user_id(p) or 0) .. ":" .. tostring(ep.name(p) or "")
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
    menu.add_checkbox(T, G.WORLD, "april_npc_heli", "Helicopters (Attack Heli)", false, menu_util.parent(P, { colorpicker = { 0.85, 0.2, 0.25, 1 } }))
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
        "april_npc_soldiers", "april_npc_bosses", "april_npc_heli", "april_npc_box_mode", "april_npc_health",
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
    if kind == "heli" then return settings.bool("april_npc_heli", false) end
    return false
end

local function kind_color(kind)
    if kind == "boss" then return settings.color("april_npc_bosses", { 1, 0.5, 0.1, 1 }) end
    if kind == "heli" then return settings.color("april_npc_heli", { 0.85, 0.2, 0.25, 1 }) end
    return settings.color("april_npc_soldiers", { 1, 0.3, 0.3, 1 })
end

local function entity_addr(p)
    if not p then return nil end
    local char = ep.character(p)
    if char then
        local addr = char.Address or char.address
        if addr then return tostring(addr) end
    end
    return (ep.name(p) or "?") .. ":" .. tostring(ep.user_id(p) or 0)
end

local function instance_addr(entry)
    if not entry or not entry.inst then return nil end
    return tostring(entry.inst.Address or entry.inst.address or entry.inst)
end

local function refresh_npc_position(entry)
    if entry.entity then
        local p = entry.entity
        if ep.is_alive(p) == false then return false end
        local x, y, z = esp_util.vec3_pos(ep.head_position(p) or ep.position(p))
        if x then
            entry.lx, entry.ly, entry.lz = x, y, z
            return true
        end
        return false
    end

    if not entry or not env.is_valid(entry.inst) then return false end

    local anchor = entry.anchor or entry.head
    if (not anchor or not env.is_valid(anchor)) and entry.inst then
        local esp_scan = April.require("game.esp_scan")
        anchor = esp_scan.find_main_part(entry.inst)
        entry.anchor = anchor
        if entry.kind ~= "heli" then
            entry.head = anchor
        end
    end

    if anchor and env.is_valid(anchor) then
        local pos = anchor.Position or anchor.position
        if pos then
            local x = pos.x or pos.X
            local y = pos.y or pos.Y
            local z = pos.z or pos.Z
            if x and y and z then
                entry.lx = x
                entry.ly = y
                entry.lz = z
                return true
            end
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

    for _, p in ipairs(ep.get_players()) do
        if ep.is_local(p) or ep.is_alive(p) == false then goto continue end

        local pname = ep.name(p)
        local kind = npcs.kind(pname)
        if not kind then goto continue end
        -- Workspace NPCs: IsWorkspaceEntity, or UserId == 0
        local uid = ep.user_id(p) or 0
        if not ep.is_workspace_entity(p) and uid ~= 0 then goto continue end

        local addr = entity_addr(p)
        if addr and seen[addr] then goto continue end
        if addr then seen[addr] = true end

        out[#out + 1] = {
            entity = p,
            name = npcs.display_name(pname, kind),
            raw_name = pname,
            kind = kind,
        }

        ::continue::
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
        local health = npcs.read_health(entry.inst)
        if health and health.hp and health.max_hp and health.max_hp > 0 then
            return health.hp, health.max_hp
        end
        if health and health.hp and health.max_hp == nil then
            -- Attribute Health without MaxHealth — still draw a filled bar.
            return health.hp, health.hp
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
    local mx, my, mz = nil, nil, nil
    if me then
        mx, my, mz = esp_util.vec3_pos(me.position)
    end
    local now = tick_ms()

    for key, ent in pairs(M._bounds_cache) do
        if not ent or (now - (ent.t or 0)) > BOUNDS_TTL_MS * 3 then
            M._bounds_cache[key] = nil
        end
    end

    for _, entry in ipairs(frame_draw_targets()) do
        local ok, err = pcall(function()
            if not kind_enabled(entry.kind) then return end

            if entry.entity then
                if ep.is_alive(entry.entity) == false then return end
            elseif not env.is_valid(entry.inst) then
                return
            end

            local col = kind_color(entry.kind)

            local lx, ly, lz = entry.lx, entry.ly, entry.lz
            if not lx then
                refresh_npc_position(entry)
                lx, ly, lz = entry.lx, entry.ly, entry.lz
            end

            if not lx and entry.entity then
                lx, ly, lz = esp_util.vec3_pos(ep.head_position(entry.entity) or ep.position(entry.entity))
                if lx then
                    entry.lx, entry.ly, entry.lz = lx, ly, lz
                end
            end
            if not lx then return end

            local dist = 0
            if mx then
                local dx = lx - mx
                local dy = ly - my
                local dz = lz - mz
                local dist_sq = dx * dx + dy * dy + dz * dz
                if dist_sq > range_sq then return end
                dist = math.sqrt(dist_sq)
            end

            local _, _, head_vis = esp_util.w2s(lx, ly, lz)

            if entry.kind ~= "heli" and settings.bool("april_npc_skeleton", false) then
                local sk = settings.color("april_npc_skeleton", { 1, 1, 1, 0.85 })
                if entry.entity and ep.get_bones_screen(entry.entity) then
                    esp_util.draw_player_skeleton(entry.entity, sk, 1)
                elseif entry.inst then
                    esp_util.draw_model_skeleton(entry.inst, sk, 1)
                end
            end

            local bounds = resolve_npc_bounds(entry, dist)
            if not esp_util.bounds_usable(bounds) then
                if not head_vis then return end
                local size = esp_util.dist_point_size(dist)
                bounds = esp_util.guard_tiny_bounds(
                    esp_util.point_screen_bounds(lx, ly, lz, size),
                    dist
                )
                if not esp_util.bounds_usable(bounds) then return end
            elseif not head_vis then
                local sw, sh = draw_util.screen_size()
                local bcx = bounds.x + bounds.w * 0.5
                local bcy = bounds.y + bounds.h * 0.5
                local margin = 120
                if bcx < -margin or bcy < -margin or bcx > sw + margin or bcy > sh + margin then
                    return
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

            if show_dist and mx then
                draw_util.text_centered(
                    cx,
                    bounds.y + bounds.h + 3,
                    string.format("%dm", math.floor(dist + 0.5)),
                    settings.color("april_npc_show_distance", { 0.82, 0.84, 0.88, 0.92 }),
                    ts
                )
            end
        end)
        if not ok then
            April.require("core.debug").error_once("npc_esp:" .. tostring(entry and entry.name), err)
        end
    end
end

return M
