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
local theme = April.require("core.ui_theme")

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
local ID_CLAN_COLOR = "april_player_clan_color"
local ID_BOX = "april_player_box_mode"
local ID_RANGE = "april_player_range"

local F_TEAM, F_SAFEZONE, F_SKIP_DOWNED = 1, 2, 3
local FL_DOWNED, FL_SAFEZONE, FL_VIP, FL_STAFF, FL_REVIVING = 1, 2, 3, 4, 5

local MUTED = { 0.82, 0.84, 0.88, 0.92 }
local FLAG_COLS = {
    VIP = { 1, 0.78, 0.15, 1 },
    SZ = { 0.35, 0.85, 1, 1 },
    DOWN = { 1, 0.35, 0.35, 1 },
    OWNER = { 0, 0.62, 1, 1 },
    ADMIN = { 1, 0.4, 0.05, 1 },
    MOD = { 1, 0.33, 0.33, 1 },
    STAFF = { 1, 0.33, 0.33, 1 },
    REVIVE = { 0.45, 1, 0.55, 1 },
}

local _wpn_cache = {}
local WPN_TTL_MS = 220

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
    _wpn_cache[key] = { t = now, name = name }
    return name
end

local function default_color()
    return settings.color(P, { 1, 0.35, 0.35, 1 })
end

local function resolve_color(p)
    if mod_checker.is_staff(p) then
        return theme.role_accent(mod_ids.role_for(p.user_id))
    end
    if settings.bool(ID_CLAN_COLOR, false) then
        local cc = player_state.clan_color(p)
        if cc then return cc end
    end
    return default_color()
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
    if not player_state.is_combat_target(p) then return false end
    if npcs.kind(p.name) then return false end
    if p.is_workspace_entity or (p.user_id or 0) == 0 then return false end
    if opts.team and not player_state.passes_team_check(p) then return false end
    if not player_state.passes_downed_check(p, opts.downed) then return false end
    if not player_state.passes_safezone_check(p, opts.skip_sz) then return false end
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
        colorpicker = { 1, 0.35, 0.35, 1 },
    })

    menu.add_combo(T, G.VISUALS, ID_BOX, "Player Box", { "None", "2D", "Corner" }, 1, { parent = P })

    menu.add_checkbox(T, G.VISUALS, ID_HEALTH, "Player Health Bar", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_SKELETON, "Player Skeleton", false,
        menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.92 } }))
    menu.add_checkbox(T, G.VISUALS, ID_NAME, "Player Name", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_CLAN, "Player Clan Tag", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_CLAN_COLOR, "Player Color By Clan", false, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_DIST, "Player Distance", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_WEAPON, "Player Weapon", false, { parent = P })

    menu.add_multicombo(T, G.VISUALS, FILTERS, "ESP Filters", {
        "Team Check", "Skip Safezone", "Skip Downed",
    }, { false, false, false }, { parent = P })
    -- Default: team check only — Skip SZ/Downed hide the players those flags describe
    set_multi_defaults(FILTERS, { true, false, false })

    menu.add_multicombo(T, G.VISUALS, FLAGS, "ESP Flags", {
        "Downed", "Safezone", "VIP", "Staff", "Reviving",
    }, { false, false, false, false, false }, { parent = P })
    set_multi_defaults(FLAGS, { true, true, true, true, true })

    menu.add_slider_int(T, G.VISUALS, ID_RANGE, "Player Range", 50, 2000, 500, { parent = P })
    menu_util.gap(T, G.VISUALS)

    local children = {
        ID_BOX, ID_HEALTH, ID_SKELETON,
        ID_NAME, ID_CLAN, ID_CLAN_COLOR, ID_DIST, ID_WEAPON,
        FILTERS, FLAGS, ID_RANGE,
    }
    menu_util.bind_children(P, children)

    -- Clear any previous player chams owner from older builds
    if gpu_chams.available() then
        pcall(function() gpu_chams.clear_owner("players") end)
    end
end

local function collect_flags(p)
    local out = {}
    if settings.multi(FLAGS, FL_VIP, true) and player_state.is_vip(p) then
        out[#out + 1] = { text = "VIP", col = FLAG_COLS.VIP }
    end
    if settings.multi(FLAGS, FL_SAFEZONE, true) and player_state.is_safezone(p) then
        out[#out + 1] = { text = "SZ", col = FLAG_COLS.SZ }
    end
    if settings.multi(FLAGS, FL_DOWNED, true) and player_state.is_downed(p) then
        out[#out + 1] = { text = "DOWN", col = FLAG_COLS.DOWN }
    end
    if settings.multi(FLAGS, FL_STAFF, true) then
        local tag = player_state.staff_tag(p)
        if tag then
            out[#out + 1] = { text = tag, col = FLAG_COLS[tag] or FLAG_COLS.STAFF }
        elseif mod_checker.is_staff(p) then
            local role = mod_ids.role_for(p.user_id)
            out[#out + 1] = {
                text = mod_ids.short_label(role),
                col = theme.role_accent(role),
            }
        end
    end
    if settings.multi(FLAGS, FL_REVIVING, true) and player_state.is_reviving(p) then
        out[#out + 1] = { text = "REVIVE", col = FLAG_COLS.REVIVE }
    end
    return out
end

local function screen_bounds(p)
    if p.get_bounds then
        local gb = p:get_bounds()
        if gb and gb.valid and gb.w >= 4 and gb.h >= 8 then
            return { x = gb.x, y = gb.y, w = gb.w, h = gb.h, valid = true }
        end
    end

    local b = esp_util.bones_screen_bounds(p)
    if b and b.valid and b.w >= 3 and b.h >= 6 then
        return b
    end

    if p.character then
        return esp_util.model_screen_bounds(p.character)
    end
    return nil
end

local function is_on_screen(bounds, pos)
    if bounds and bounds.valid then
        local sw, sh = draw_util.screen_size()
        local cx = bounds.x + bounds.w * 0.5
        local cy = bounds.y + bounds.h * 0.5
        return cx > -20 and cy > -20 and cx < sw + 20 and cy < sh + 20
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

        local col = resolve_color(p)
        local bounds = screen_bounds(p)
        local on_screen = is_on_screen(bounds, pos)

        if not bounds or not bounds.valid or not on_screen then
            goto continue
        end

        local ts = esp_util.text_size()
        if dist > 250 then
            ts = math.max(11, ts - 1)
        end

        local cx = bounds.x + bounds.w * 0.5
        local box_ok = bounds.w >= 6 and bounds.h >= 10

        local top = {}
        if show_clan then
            local tag = player_state.clan_tag(p)
            if tag then
                top[#top + 1] = { text = "[" .. tag .. "]", col = player_state.clan_color(p) or col }
            end
        end
        if show_name then
            top[#top + 1] = { text = p.name or "?", col = col }
        end
        local flags = collect_flags(p)
        if #flags > 0 then
            local parts = {}
            for i = 1, #flags do
                parts[#parts + 1] = flags[i].text
            end
            top[#top + 1] = {
                text = "[" .. table.concat(parts, "][") .. "]",
                col = (#flags == 1) and flags[1].col or MUTED,
            }
        end
        if show_wpn then
            local wpn = held_weapon_name(p)
            if wpn and wpn ~= "" then
                top[#top + 1] = { text = tostring(wpn), col = MUTED }
            end
        end

        if #top > 0 then
            local ty = bounds.y - 4 - (#top * (ts + 1))
            for i = 1, #top do
                draw_util.text_centered(cx, ty + (i - 1) * (ts + 1), top[i].text, top[i].col, ts)
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
            local sc = settings.bool(ID_CLAN_COLOR, false) and (player_state.clan_color(p) or skel_col) or skel_col
            if p.get_bones_screen then
                esp_util.draw_player_skeleton(p, sc, 1)
            elseif p.character then
                esp_util.draw_model_skeleton(p.character, sc, 1)
            end
        end

        if show_dist then
            draw_util.text_centered(
                cx,
                bounds.y + bounds.h + 3,
                string.format("%dm", math.floor(dist + 0.5)),
                MUTED,
                ts
            )
        end

        ::continue::
    end
end

return M
