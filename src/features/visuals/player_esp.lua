local settings = April.require("core.settings")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local gpu_chams = April.require("core.gpu_chams")
local player_state = April.require("game.player_state")
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
local ID_OFFSCREEN = "april_player_offscreen"
local ID_NAME = "april_player_show_name"
local ID_DIST = "april_player_show_distance"
local ID_WEAPON = "april_player_show_weapon"
local ID_HP_TEXT = "april_player_health_text"
local ID_CLAN = "april_player_clan_tag"
local ID_CLAN_COLOR = "april_player_clan_color"
local ID_BOX = "april_player_box_mode"
local ID_RANGE = "april_player_range"

-- Filters
local F_TEAM, F_SAFEZONE, F_SKIP_DOWNED = 1, 2, 3
-- Status flags (draw-only tags — not clan)
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
    local downed = 1 -- allow
    if settings.multi(FILTERS, F_SKIP_DOWNED, true) then
        downed = 0
    end
    return {
        team = settings.multi(FILTERS, F_TEAM, true),
        skip_sz = settings.multi(FILTERS, F_SAFEZONE, true),
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
    menu.add_checkbox(T, G.VISUALS, ID_OFFSCREEN, "Player Offscreen Arrows", false,
        menu_util.parent(P, { colorpicker = { 1, 0.35, 0.35, 1 } }))
    menu.add_checkbox(T, G.VISUALS, ID_NAME, "Player Name", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_CLAN, "Player Clan Tag", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_CLAN_COLOR, "Player Color By Clan", false, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_DIST, "Player Distance", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_WEAPON, "Player Weapon", false, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_HP_TEXT, "Player Health Text", false, { parent = P })

    menu.add_multicombo(T, G.VISUALS, FILTERS, "ESP Filters", {
        "Team Check", "Skip Safezone", "Skip Downed",
    }, { false, false, false }, { parent = P })
    set_multi_defaults(FILTERS, { true, true, true })

    -- Dump-backed status tags (ChatController + StateAssetController).
    menu.add_multicombo(T, G.VISUALS, FLAGS, "ESP Flags", {
        "Downed", "Safezone", "VIP", "Staff", "Reviving",
    }, { false, false, false, false, false }, { parent = P })
    set_multi_defaults(FLAGS, { true, true, true, true, true })

    if gpu_chams.available() then
        menu.add_checkbox(T, G.VISUALS, CHAMS, "Player Engine Chams", false, { parent = P })
        gpu_chams.add_mode_color_menu(T, G.VISUALS, P, CHAMS_MODE, CHAMS_COLOR,
            "Player Chams Mode", "Player Chams Color")
    end

    menu.add_slider_int(T, G.VISUALS, ID_RANGE, "Player Range", 50, 2000, 500, { parent = P })
    menu_util.gap(T, G.VISUALS)

    local children = {
        ID_BOX, ID_HEALTH, ID_SKELETON, ID_OFFSCREEN,
        ID_NAME, ID_CLAN, ID_CLAN_COLOR, ID_DIST, ID_WEAPON, ID_HP_TEXT,
        FILTERS, FLAGS, ID_RANGE,
    }
    if gpu_chams.available() then
        children[#children + 1] = CHAMS
        children[#children + 1] = CHAMS_MODE
        children[#children + 1] = CHAMS_COLOR
    end
    menu_util.bind_children(P, children)

    if gpu_chams.available() then
        gpu_chams.register_owner("players", {
            rescan_ms = 450,
            is_active = players_chams_active,
            style = function()
                return gpu_chams.mode_index(CHAMS_MODE, 0), gpu_chams.color_index(CHAMS_COLOR, 0)
            end,
            collect = collect_player_chams,
        })
        gpu_chams.wire_style_controls("players", CHAMS_MODE, CHAMS_COLOR)
        local function resync()
            if players_chams_active() then
                gpu_chams.sync_owner("players", true)
            else
                gpu_chams.clear_owner("players")
            end
        end
        settings.on_change(CHAMS, resync)
        settings.on_change(P, resync)
        settings.on_change(FILTERS, resync)
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
            out[#out + 1] = { text = "STAFF", col = FLAG_COLS.STAFF }
        end
    end
    if settings.multi(FLAGS, FL_REVIVING, true) and player_state.is_reviving(p) then
        out[#out + 1] = { text = "REVIVE", col = FLAG_COLS.REVIVE }
    end
    return out
end

local function screen_bounds(p)
    -- Prefer engine bounds when they look like a real body (not a speck / not inflated).
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

function M.update(_dt)
    if not settings.enabled(P) then
        if gpu_chams.available() then
            gpu_chams.sync_owner("players")
        end
        return
    end
    if gpu_chams.available() then
        gpu_chams.sync_owner("players")
    end
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
    local show_off = settings.bool(ID_OFFSCREEN, false)
    local show_name = settings.bool(ID_NAME, true)
    local show_clan = settings.bool(ID_CLAN, true)
    local show_dist = settings.bool(ID_DIST, true)
    local show_wpn = settings.bool(ID_WEAPON, false)
    local show_hp_text = settings.bool(ID_HP_TEXT, false)

    local skel_col = settings.color(ID_SKELETON, { 1, 1, 1, 0.92 })
    local off_col = settings.color(ID_OFFSCREEN, { 1, 0.35, 0.35, 1 })

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

        if not bounds or not bounds.valid then
            if show_off then
                local arrow_col = settings.bool(ID_CLAN_COLOR, false) and (player_state.clan_color(p) or off_col) or off_col
                esp_util.draw_offscreen_to(pos.x, pos.y, pos.z, arrow_col, 12)
            end
            goto continue
        end

        local ts = esp_util.text_size()
        if dist > 250 then
            ts = math.max(11, ts - 1)
        end

        local cx = bounds.x + bounds.w * 0.5
        local box_ok = bounds.w >= 6 and bounds.h >= 10

        -- Top (above box): clan → name → flags → weapon/hp
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
            local wpn = p.tool_name or p.weapon
            if wpn and wpn ~= "" then
                top[#top + 1] = { text = tostring(wpn), col = MUTED }
            end
        end
        if show_hp_text and p.health and p.max_health then
            top[#top + 1] = {
                text = string.format("%d/%d", math.floor(p.health + 0.5), math.floor(p.max_health + 0.5)),
                col = MUTED,
            }
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

        -- Bottom (under box): distance
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
