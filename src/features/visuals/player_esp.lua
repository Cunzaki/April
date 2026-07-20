local settings = April.require("core.settings")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local gpu_chams = April.require("core.gpu_chams")
local player_state = April.require("game.player_state")
local player_gear = April.require("game.player_gear")
local npcs = April.require("game.npcs")
local mod_checker = April.require("features.utility.mod_checker")
local mod_ids = April.require("game.mod_ids")

local M = {}
local P = "april_player_enabled"
local CHAMS = "april_player_chams"
local CHAMS_MODE = "april_player_chams_mode"
local CHAMS_COLOR = "april_player_chams_color"
local FILTERS = "april_player_esp_filters"
local FLAGS = "april_player_esp_flags"

local ID_HEALTH = "april_player_health"
local ID_SKELETON = "april_player_skeleton"
local ID_NAME = "april_player_show_name"
local ID_DIST = "april_player_show_distance"
local ID_WEAPON = "april_player_show_weapon"
local ID_CLAN = "april_player_clan_tag"
local ID_BOX = "april_player_box_mode"
local ID_RANGE = "april_player_range"
local ID_FLAG_DOWN = "april_player_flag_downed"
local ID_FLAG_SZ = "april_player_flag_safezone"
local ID_FLAG_VIP = "april_player_flag_vip"
local ID_FLAG_STAFF = "april_player_flag_staff"
local ID_FLAG_REVIVE = "april_player_flag_reviving"

local F_TEAM, F_SAFEZONE, F_SKIP_DOWNED = 1, 2, 3
local FL_DOWNED, FL_SAFEZONE, FL_VIP, FL_STAFF, FL_REVIVING = 1, 2, 3, 4, 5

local DEFAULT_BOX = { 1, 0.35, 0.35, 1 }
local DEFAULT_TEXT = { 1, 0.35, 0.35, 1 }
local DEFAULT_CLAN = { 0.84, 0.31, 0.80, 1 }
local DEFAULT_MUTED = { 0.82, 0.84, 0.88, 0.92 }
local DEFAULT_FLAG = {
    DOWN = { 1, 0.35, 0.35, 1 },
    SZ = { 0.35, 0.85, 1, 1 },
    VIP = { 1, 0.78, 0.15, 1 },
    STAFF = { 1, 0.33, 0.33, 1 },
    REVIVE = { 0.45, 1, 0.55, 1 },
}

local _wpn_cache = {}
local _bounds_cache = {}
local WPN_TTL_MS = 220
local BOUNDS_TTL_MS = 600

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function cache_key(p)
    return tostring(p.user_id or 0) .. ":" .. tostring(p.name or "")
end

local function held_weapon_name(p)
    local key = cache_key(p)
    local now = tick_ms()
    local ent = _wpn_cache[key]
    if ent and (now - ent.t) < WPN_TTL_MS then
        return ent.name
    end
    local name = nil
    pcall(function()
        name = player_gear.held_name(p)
    end)
    if name and player_gear.is_empty_held_name and player_gear.is_empty_held_name(name) then
        name = nil
    end
    _wpn_cache[key] = { t = now, name = name }
    return name
end

local function box_color()
    return settings.color(P, DEFAULT_BOX)
end

local function resolve_color(_p)
    return box_color()
end

local function players_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    return settings.bool(CHAMS, false)
end

local function filter_opts()
    local downed = 1
    if settings.multi(FILTERS, F_SKIP_DOWNED, false) then
        downed = 0
    end
    return {
        team = settings.multi(FILTERS, F_TEAM, true),
        skip_sz = settings.multi(FILTERS, F_SAFEZONE, false),
        downed = downed,
    }
end

local function passes_player_filters(p, opts)
    if not p or p.is_local then return false end
    if p.is_workspace_entity or (p.user_id or 0) == 0 then return false end
    if npcs.kind(p.name) then return false end
    if not player_state.is_combat_target(p) then return false end
    if opts.team and not player_state.passes_team_check(p) then return false end
    if opts.downed ~= 1 and not player_state.passes_downed_check(p, opts.downed) then
        return false
    end
    if opts.skip_sz and not player_state.passes_safezone_check(p, true) then
        return false
    end
    return true
end

local function collect_player_chams(applied)
    local me = env.get_local_player()
    local me_pos = me and me.position
    if not me_pos then return end

    local range = settings.num(ID_RANGE, 500)
    local range_sq = range * range
    local opts = filter_opts()
    if not entity or not entity.get_players then return end

    for _, p in ipairs(entity.get_players()) do
        if not passes_player_filters(p, opts) then goto continue end

        local pos = p.position or p.head_position
        if pos then
            local dx = (pos.x or 0) - me_pos.x
            local dy = (pos.y or 0) - me_pos.y
            local dz = (pos.z or 0) - me_pos.z
            if (dx * dx + dy * dy + dz * dz) > range_sq then goto continue end
        end

        local char = p.character
        if not char or not env.is_valid(char) then goto continue end
        gpu_chams.cham_player_character(char, applied)

        ::continue::
    end
end

local function set_multi_defaults(id, values)
    if menu and menu.set then
        pcall(menu.set, id, values)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)

    menu_util.section(T, G.VISUALS, "Player ESP")
    menu_util.register_keybind(T, G.VISUALS, P, "Player ESP", false, {
        colorpicker = DEFAULT_BOX,
    })

    menu.add_combo(T, G.VISUALS, ID_BOX, "Player Box", { "None", "2D", "Corner" }, 1, { parent = P })

    menu.add_checkbox(T, G.VISUALS, ID_HEALTH, "Player Health Bar", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_SKELETON, "Player Skeleton", false,
        menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.92 } }))
    menu.add_checkbox(T, G.VISUALS, ID_NAME, "Player Name", true,
        menu_util.parent(P, { colorpicker = DEFAULT_TEXT }))
    menu.add_checkbox(T, G.VISUALS, ID_CLAN, "Player Clan Tag", true,
        menu_util.parent(P, { colorpicker = DEFAULT_CLAN }))
    menu.add_checkbox(T, G.VISUALS, ID_DIST, "Player Distance", true,
        menu_util.parent(P, { colorpicker = DEFAULT_MUTED }))
    menu.add_checkbox(T, G.VISUALS, ID_WEAPON, "Player Weapon", false,
        menu_util.parent(P, { colorpicker = DEFAULT_MUTED }))

    menu.add_multicombo(T, G.VISUALS, FILTERS, "ESP Filters", {
        "Team Check", "Skip Safezone", "Skip Downed",
    }, { false, false, false }, { parent = P })
    set_multi_defaults(FILTERS, { true, false, false })

    menu.add_multicombo(T, G.VISUALS, FLAGS, "ESP Flags", {
        "Downed", "Safezone", "VIP", "Staff", "Reviving",
    }, { false, false, false, false, false }, { parent = P })
    set_multi_defaults(FLAGS, { true, true, true, true, true })

    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_DOWN, "Flag Downed Color", DEFAULT_FLAG.DOWN, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_SZ, "Flag Safezone Color", DEFAULT_FLAG.SZ, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_VIP, "Flag VIP Color", DEFAULT_FLAG.VIP, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_STAFF, "Flag Staff Color", DEFAULT_FLAG.STAFF, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_REVIVE, "Flag Reviving Color", DEFAULT_FLAG.REVIVE, { parent = P })

    menu.add_slider_int(T, G.VISUALS, ID_RANGE, "Player Range", 50, 2000, 500, { parent = P })
    menu_util.gap(T, G.VISUALS)

    local children = {
        ID_BOX, ID_HEALTH, ID_SKELETON,
        ID_NAME, ID_CLAN, ID_DIST, ID_WEAPON,
        FILTERS, FLAGS,
        ID_FLAG_DOWN, ID_FLAG_SZ, ID_FLAG_VIP, ID_FLAG_STAFF, ID_FLAG_REVIVE,
        ID_RANGE,
    }
    menu_util.bind_children(P, children)

    if gpu_chams.available() then
        pcall(function() gpu_chams.clear_owner("players") end)
    end
end

local function clan_tag_color(snap, menu_col)
    local cc = snap and snap.clan_color
    if cc and cc[1] then return cc end
    return menu_col
end

local function flag_on(index)
    return settings.multi(FLAGS, index, true)
end

local function collect_side_tags(p, snap, show_clan, clan_menu_col, flag_cols)
    local out = {}
    snap = snap or player_state.esp_state(p)
    if not snap then return out end

    if show_clan and snap.clan_tag then
        out[#out + 1] = {
            text = "[" .. snap.clan_tag .. "]",
            col = clan_tag_color(snap, clan_menu_col),
        }
    end

    if flag_on(FL_VIP) and snap.vip then
        out[#out + 1] = { text = "[VIP]", col = flag_cols.vip }
    end
    if flag_on(FL_SAFEZONE) and snap.safezone then
        out[#out + 1] = { text = "[SZ]", col = flag_cols.sz }
    end
    if flag_on(FL_DOWNED) and snap.downed then
        out[#out + 1] = { text = "[DOWN]", col = flag_cols.down }
    end
    if flag_on(FL_STAFF) then
        if snap.staff then
            out[#out + 1] = { text = "[" .. snap.staff .. "]", col = flag_cols.staff }
        else
            local role = mod_checker.staff_role(p)
            if role then
                out[#out + 1] = {
                    text = "[" .. mod_ids.short_label(role) .. "]",
                    col = flag_cols.staff,
                }
            end
        end
    end
    if flag_on(FL_REVIVING) and snap.reviving then
        out[#out + 1] = { text = "[REVIVE]", col = flag_cols.revive }
    end

    return out
end

local function prune_bounds_cache(now)
    for key, ent in pairs(_bounds_cache) do
        if not ent or (now - (ent.t or 0)) > BOUNDS_TTL_MS * 3 then
            _bounds_cache[key] = nil
        end
    end
end

local function resolve_bounds(p, pos, dist)
    local key = cache_key(p)
    local now = tick_ms()

    local bounds = esp_util.player_screen_bounds(p, {
        dist = dist,
        point_size = esp_util.dist_point_size(dist),
    })

    if bounds and bounds.valid then
        _bounds_cache[key] = { bounds = bounds, t = now, dist = dist }
        return bounds
    end

    local cached = _bounds_cache[key]
    if cached and cached.bounds and (now - cached.t) < BOUNDS_TTL_MS then
        local cd = cached.dist or dist
        if not dist or not cd or math.abs(dist - cd) < 40 then
            return cached.bounds
        end
    end

    if pos then
        local size = esp_util.dist_point_size(dist)
        bounds = esp_util.point_screen_bounds(pos.x, pos.y, pos.z, size)
        if bounds and bounds.valid then
            _bounds_cache[key] = { bounds = bounds, t = now, dist = dist }
            return bounds
        end
    end

    return nil
end

local function is_on_screen(bounds, pos)
    if bounds and bounds.valid then
        local sw, sh = draw_util.screen_size()
        local cx = bounds.x + bounds.w * 0.5
        local cy = bounds.y + bounds.h * 0.5
        local margin = 80
        return cx > -margin and cy > -margin and cx < sw + margin and cy < sh + margin
    end
    if not pos then return false end
    local _, _, on = esp_util.w2s(pos.x, pos.y, pos.z)
    return on == true
end

function M.update(_dt)
end

function M.draw()
    if not settings.enabled(P) then return end
    if not entity or not entity.get_players then return end

    local now = tick_ms()
    prune_bounds_cache(now)

    local range = settings.num(ID_RANGE, 500)
    local range_sq = range * range
    local box_mode = settings.num(ID_BOX, 1)
    local me = env.get_local_player()
    local me_pos = me and me.position
    local opts = filter_opts()

    local show_health = settings.bool(ID_HEALTH, true)
    local show_skel = settings.bool(ID_SKELETON, false)
    local show_name = settings.bool(ID_NAME, true)
    local show_clan = settings.bool(ID_CLAN, true)
    local show_dist = settings.bool(ID_DIST, true)
    local show_wpn = settings.bool(ID_WEAPON, false)

    local skel_col = settings.color(ID_SKELETON, { 1, 1, 1, 0.92 })
    local name_col = settings.color(ID_NAME, DEFAULT_TEXT)
    local clan_menu_col = settings.color(ID_CLAN, DEFAULT_CLAN)
    local dist_col = settings.color(ID_DIST, DEFAULT_MUTED)
    local wpn_col = settings.color(ID_WEAPON, DEFAULT_MUTED)
    local flag_cols = {
        down = settings.color(ID_FLAG_DOWN, DEFAULT_FLAG.DOWN),
        sz = settings.color(ID_FLAG_SZ, DEFAULT_FLAG.SZ),
        vip = settings.color(ID_FLAG_VIP, DEFAULT_FLAG.VIP),
        staff = settings.color(ID_FLAG_STAFF, DEFAULT_FLAG.STAFF),
        revive = settings.color(ID_FLAG_REVIVE, DEFAULT_FLAG.REVIVE),
    }

    for _, p in ipairs(entity.get_players()) do
        if not passes_player_filters(p, opts) then goto continue end

        local pos = p.head_position or p.position
        if not pos then goto continue end

        local dist = 0
        if me_pos then
            local dx = (pos.x or 0) - me_pos.x
            local dy = (pos.y or 0) - me_pos.y
            local dz = (pos.z or 0) - me_pos.z
            local dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
            dist = math.sqrt(dist_sq)
        end

        local snap = player_state.esp_state(p)
        local col = resolve_color(p)
        local bounds = resolve_bounds(p, pos, dist)
        if not bounds or not bounds.valid or not is_on_screen(bounds, pos) then
            goto continue
        end

        local ts = esp_util.text_size()
        if dist > 250 then
            ts = math.max(11, ts - 1)
        end

        local cx = bounds.x + bounds.w * 0.5
        local box_ok = bounds.w >= 4 and bounds.h >= 8

        -- Top: name + weapon only (never clan - clan is on the right with tags)
        local top = {}
        if show_name then
            top[#top + 1] = { text = p.name or "?", col = name_col }
        end
        if show_wpn then
            local wpn = held_weapon_name(p)
            if wpn and wpn ~= "" then
                top[#top + 1] = { text = tostring(wpn), col = wpn_col }
            end
        end

        if #top > 0 then
            local ty = bounds.y - 4 - (#top * (ts + 1))
            for i = 1, #top do
                draw_util.text_centered(cx, ty + (i - 1) * (ts + 1), top[i].text, top[i].col, ts)
            end
        end

        -- Right: clan tag + attribute flags (VIP / SZ / DOWN / staff / revive)
        local side = collect_side_tags(p, snap, show_clan, clan_menu_col, flag_cols)
        if #side > 0 then
            local rx = bounds.x + bounds.w + 4
            local ry = bounds.y
            for i = 1, #side do
                draw_util.text(
                    rx,
                    ry + (i - 1) * (ts + 1),
                    side[i].text,
                    side[i].col,
                    ts
                )
            end
        end

        if box_ok then
            if box_mode == 1 then
                draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 0)
            elseif box_mode == 2 then
                draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, col, 1)
            end

            if show_health then
                local hp, max_hp = p.health, p.max_health
                if hp and max_hp and max_hp > 0 then
                    if draw and draw.health_bar then
                        draw.health_bar(bounds.x - 5, bounds.y, bounds.h, hp, max_hp)
                    else
                        draw_util.health_bar_nice(bounds.x - 5, bounds.y, bounds.h, hp, max_hp, 3)
                    end
                end
            end
        end

        if show_skel then
            if p.get_bones_screen then
                esp_util.draw_player_skeleton(p, skel_col, 1)
            elseif p.character then
                esp_util.draw_model_skeleton(p.character, skel_col, 1)
            end
        end

        if show_dist then
            draw_util.text_centered(
                cx,
                bounds.y + bounds.h + 3,
                string.format("%dm", math.floor(dist + 0.5)),
                dist_col,
                ts
            )
        end

        ::continue::
    end
end

return M
