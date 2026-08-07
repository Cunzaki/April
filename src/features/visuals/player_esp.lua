local settings = April.require("core.settings")
local cache = April.require("core.cache")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local text_util = April.require("core.text_util")
local player_state = April.require("game.player_state")
local player_gear = April.require("game.player_gear")
local mod_checker = April.require("features.utility.mod_checker")
local mod_ids = April.require("game.mod_ids")
local ep = April.require("core.entity_props")
local cheater_detect = April.require("game.cheater_detect")
local thick_bullet = April.require("features.combat.thick_bullet")

local M = {}
local P = "april_player_enabled"
local FILTERS = "april_player_esp_filters"
local FLAGS = "april_player_esp_flags"

local ID_HEALTH = "april_player_health"
local ID_SKELETON = "april_player_skeleton"
local ID_NAME = "april_player_show_name"
local ID_DIST = "april_player_show_distance"
local ID_HELD = "april_player_show_held"
local ID_CLAN = "april_player_clan_tag"
local ID_BOX = "april_player_box_mode"
local ID_BOX_COLOR = "april_player_box_color"
local ID_RANGE = "april_player_range"
local ID_FLAG_DOWN = "april_player_flag_downed"
local ID_FLAG_SZ = "april_player_flag_safezone"
local ID_FLAG_STAFF = "april_player_flag_staff"
local ID_FLAG_REVIVE = "april_player_flag_reviving"
local ID_FLAG_MOVE = "april_player_flag_movement"
local ID_FLAG_VIP = "april_player_flag_vip"
local ID_FLAG_CHEATER = "april_player_flag_cheater"

local F_TEAM, F_SAFEZONE, F_SKIP_DOWNED = 1, 2, 3
local FL_DOWNED, FL_SAFEZONE, FL_STAFF, FL_REVIVING = 1, 2, 3, 4
local FL_MOVEMENT, FL_VIP, FL_CHEATER = 5, 6, 7

local DEFAULT_BOX = { 1, 0.35, 0.35, 1 }
local DEFAULT_TEXT = { 1, 0.35, 0.35, 1 }
local DEFAULT_CLAN = { 0.84, 0.31, 0.80, 1 }
local DEFAULT_MUTED = { 0.82, 0.84, 0.88, 0.92 }
local DEFAULT_HELD = { 0.95, 0.9, 0.55, 0.95 }
local DEFAULT_FLAG = {
    DOWN = { 1, 0.35, 0.35, 1 },
    SZ = { 0.35, 0.85, 1, 1 },
    STAFF = { 1, 0.33, 0.33, 1 },
    REVIVE = { 0.45, 1, 0.55, 1 },
    MOVE = { 0.75, 0.85, 1, 1 },
    VIP = { 1, 0.82, 0.2, 1 },
    CHEATER = { 1, 0.05, 0.05, 1 },
}
local held_cache = {}
local last_held_prune_ms = 0
local HELD_TTL_MS = 300
local HELD_PRUNE_MS = 2000

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function set_multi_defaults(id, values)
    if menu and menu.set then
        pcall(menu.set, id, values)
    end
end

local function migrate_flags_table()
    if not menu or not menu.get or not menu.set then return end
    local ok, cur = pcall(menu.get, FLAGS)
    if not ok or type(cur) ~= "table" then return end
    local n = 0
    for i = 1, 16 do
        if cur[i] ~= nil then n = i end
    end
    if n <= 4 then
        -- Old 4-flag configs: keep first four, Movement/VIP/Cheater off until chosen.
        pcall(menu.set, FLAGS, {
            cur[1] == true, cur[2] == true, cur[3] == true, cur[4] == true,
            false, false, false,
        })
    elseif n == 6 then
        -- Pre-cheater 6-flag layout → append Cheater off.
        pcall(menu.set, FLAGS, {
            cur[1] == true, cur[2] == true, cur[3] == true, cur[4] == true,
            cur[5] == true, cur[6] == true, false,
        })
    elseif n >= 8 then
        -- Old Idle/Walk/Sprint/VIP layout → single Movement + VIP + Cheater.
        local move = cur[5] == true or cur[6] == true or cur[7] == true
        pcall(menu.set, FLAGS, {
            cur[1] == true, cur[2] == true, cur[3] == true, cur[4] == true,
            move, cur[8] == true, false,
        })
    elseif n ~= 7 then
        pcall(menu.set, FLAGS, {
            cur[1] == true, cur[2] == true, cur[3] == true, cur[4] == true,
            cur[5] == true, cur[6] == true, cur[7] == true,
        })
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)

    menu_util.section(T, G.VISUALS, "Player ESP")
    menu_util.register_keybind(T, G.VISUALS, P, "Player ESP", false)

    menu.add_combo(T, G.VISUALS, ID_BOX, "Player Box", { "None", "2D", "Corner" }, 1, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_BOX_COLOR, "Player Box Color", DEFAULT_BOX, { parent = P })

    menu.add_checkbox(T, G.VISUALS, ID_HEALTH, "Player Health Bar", true, { parent = P })
    menu.add_checkbox(T, G.VISUALS, ID_SKELETON, "Player Skeleton", false,
        menu_util.parent(P, { colorpicker = { 1, 1, 1, 0.92 } }))
    menu.add_checkbox(T, G.VISUALS, ID_NAME, "Player Name", true,
        menu_util.parent(P, { colorpicker = DEFAULT_TEXT }))
    menu.add_checkbox(T, G.VISUALS, ID_CLAN, "Player Clan Tag", true,
        menu_util.parent(P, { colorpicker = DEFAULT_CLAN }))
    menu.add_checkbox(T, G.VISUALS, ID_HELD, "Held Item", false,
        menu_util.parent(P, { colorpicker = DEFAULT_HELD }))
    menu.add_checkbox(T, G.VISUALS, ID_DIST, "Player Distance", true,
        menu_util.parent(P, { colorpicker = DEFAULT_MUTED }))

    menu.add_multicombo(T, G.VISUALS, FILTERS, "ESP Filters", {
        "Team Check", "Skip Safezone", "Skip Downed",
    }, { false, false, false }, { parent = P })
    set_multi_defaults(FILTERS, { true, false, false })

    menu.add_multicombo(T, G.VISUALS, FLAGS, "ESP Flags", {
        "Downed", "Safezone", "Staff", "Reviving", "Movement", "VIP", "Cheater",
    }, { false, false, false, false, false, false, false }, { parent = P })
    set_multi_defaults(FLAGS, { true, true, true, true, false, true, true })

    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_DOWN, "Flag Downed Color", DEFAULT_FLAG.DOWN, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_SZ, "Flag Safezone Color", DEFAULT_FLAG.SZ, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_STAFF, "Flag Staff Color", DEFAULT_FLAG.STAFF, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_REVIVE, "Flag Reviving Color", DEFAULT_FLAG.REVIVE, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_MOVE, "Flag Movement Color", DEFAULT_FLAG.MOVE, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_VIP, "Flag VIP Color", DEFAULT_FLAG.VIP, { parent = P })
    menu.add_colorpicker(T, G.VISUALS, ID_FLAG_CHEATER, "Flag Cheater Color", DEFAULT_FLAG.CHEATER, { parent = P })

    menu.add_slider_int(T, G.VISUALS, ID_RANGE, "Player Range", 50, 2000, 500, { parent = P })
    menu_util.gap(T, G.VISUALS)

    menu_util.bind_children(P, {
        ID_BOX, ID_BOX_COLOR, ID_HEALTH, ID_SKELETON,
        ID_NAME, ID_CLAN, ID_HELD, ID_DIST,
        FILTERS, FLAGS,
        ID_FLAG_DOWN, ID_FLAG_SZ, ID_FLAG_STAFF, ID_FLAG_REVIVE,
        ID_FLAG_MOVE, ID_FLAG_VIP, ID_FLAG_CHEATER,
        ID_RANGE,
    })
end

local function held_label(player)
    local uid = ep.user_id(player)
    local key = uid and uid ~= 0 and tostring(uid)
        or tostring(player.Address or player.address or player.name or player)
    local now = tick_ms()
    local cached = held_cache[key]
    if cached and now - cached.t < HELD_TTL_MS then
        return cached.value or nil
    end
    local name = player_gear.held_name(player)
    if not name or player_gear.is_empty_held_name(name) then
        held_cache[key] = { t = now, value = false }
        return nil
    end
    -- Match target gear display: drop skin/variant suffix after '/'.
    local base = name:match("^([^/]+)") or name
    base = text_util.sanitize(base)
    if base == "" then
        held_cache[key] = { t = now, value = false }
        return nil
    end
    held_cache[key] = { t = now, value = base }
    return base
end

local function horizontal_speed(p)
    local vel = p.Velocity or p.velocity
    if not vel then return 0 end
    local x = tonumber(vel.X or vel.x)
    local z = tonumber(vel.Z or vel.z)
    if not x or not z then return 0 end
    return math.sqrt(x * x + z * z)
end

local function movement_label(p)
    local speed = horizontal_speed(p)
    if speed < 1.0 then return "IDLE" end
    if speed > 15.0 then return "SPRINTING" end
    return "WALKING"
end

local function native_bounds(player)
    -- Hitbox Override inflates Head.Size; use the thick_bullet helper so boxes
    -- stay on natural proportions while the hitbox remains expanded.
    if thick_bullet and thick_bullet.esp_bounds then
        return thick_bullet.esp_bounds(player)
    end
    local fn = player and (player.GetBounds or player.get_bounds)
    if not fn then return nil end
    local ok, bounds = pcall(fn, player)
    if ok then return bounds end
    return nil
end

local function native_bones(player)
    local fn = player and (player.GetBonesScreen or player.get_bones_screen)
    if not fn then return nil end
    return fn(player)
end

local function emit_side_tag(x, y, ts, row, text, col)
    draw_util.text(x, y + row * (ts + 1), text, col, ts)
    return row + 1
end

local function draw_side_tags(p, snap, show_clan, clan_menu_col, flag_cols, flags, x, y, ts)
    local row = 0

    if show_clan and snap and snap.clan_tag then
        local cc = snap.clan_color
        row = emit_side_tag(x, y, ts, row, "[" .. snap.clan_tag .. "]", (cc and cc[1]) and cc or clan_menu_col)
    end

    if flags[FL_CHEATER] and cheater_detect.is_cheater(p) then
        row = emit_side_tag(x, y, ts, row, "[CHEATER]", flag_cols.cheater)
    end
    if flags[FL_SAFEZONE] and snap and snap.safezone then
        row = emit_side_tag(x, y, ts, row, "[SZ]", flag_cols.sz)
    end
    if flags[FL_DOWNED] and snap and snap.downed then
        row = emit_side_tag(x, y, ts, row, "[DOWN]", flag_cols.down)
    end
    if flags[FL_STAFF] then
        if snap and snap.staff then
            row = emit_side_tag(x, y, ts, row, "[" .. snap.staff .. "]", flag_cols.staff)
        else
            local role = mod_checker.staff_role(p)
            if role then
                row = emit_side_tag(x, y, ts, row, "[" .. mod_ids.short_label(role) .. "]", flag_cols.staff)
            end
        end
    end
    if flags[FL_REVIVING] and snap and snap.reviving then
        row = emit_side_tag(x, y, ts, row, "[REVIVE]", flag_cols.revive)
    end
    if flags[FL_VIP] and snap and snap.vip then
        row = emit_side_tag(x, y, ts, row, "[VIP]", flag_cols.vip)
    end
    if flags[FL_MOVEMENT] then
        emit_side_tag(x, y, ts, row, "[" .. movement_label(p) .. "]", flag_cols.move)
    end
end

function M.draw()
    if not M._flags_migrated then
        M._flags_migrated = true
        migrate_flags_table()
    end

    if not settings.enabled(P) then return end

    local now = tick_ms()
    if now - last_held_prune_ms >= HELD_PRUNE_MS then
        last_held_prune_ms = now
        for key, entry in pairs(held_cache) do
            if now - (entry.t or 0) > HELD_PRUNE_MS then held_cache[key] = nil end
        end
    end

    local players = cache.players
    if type(players) ~= "table" or #players == 0 then return end

    local range = settings.num(ID_RANGE, 500)
    local range_sq = range * range
    local box_mode = settings.num(ID_BOX, 1)
    local show_health = settings.bool(ID_HEALTH, true)
    local show_skel = settings.bool(ID_SKELETON, false)
    local show_name = settings.bool(ID_NAME, true)
    local show_clan = settings.bool(ID_CLAN, true)
    local show_held = settings.bool(ID_HELD, false)
    local show_dist = settings.bool(ID_DIST, true)

    local filter_team = settings.multi(FILTERS, F_TEAM, true)
    local filter_sz = settings.multi(FILTERS, F_SAFEZONE, false)
    local skip_downed = settings.multi(FILTERS, F_SKIP_DOWNED, false)

    -- Defaults must be false for optional flags so missing multi slots stay off.
    local flags = {
        [FL_DOWNED] = settings.multi(FLAGS, FL_DOWNED, false),
        [FL_SAFEZONE] = settings.multi(FLAGS, FL_SAFEZONE, false),
        [FL_STAFF] = settings.multi(FLAGS, FL_STAFF, false),
        [FL_REVIVING] = settings.multi(FLAGS, FL_REVIVING, false),
        [FL_MOVEMENT] = settings.multi(FLAGS, FL_MOVEMENT, false),
        [FL_VIP] = settings.multi(FLAGS, FL_VIP, false),
        [FL_CHEATER] = settings.multi(FLAGS, FL_CHEATER, false),
    }

    if flags[FL_CHEATER] then
        cheater_detect.tick()
    end

    local need_snap = show_clan or filter_sz or skip_downed
        or flags[FL_DOWNED] or flags[FL_SAFEZONE]
        or flags[FL_STAFF] or flags[FL_REVIVING] or flags[FL_VIP]
    local need_side = need_snap or flags[FL_MOVEMENT] or flags[FL_CHEATER]

    local skel_col = settings.color(ID_SKELETON, { 1, 1, 1, 0.92 })
    local name_col = settings.color(ID_NAME, DEFAULT_TEXT)
    local clan_menu_col = settings.color(ID_CLAN, DEFAULT_CLAN)
    local held_col = settings.color(ID_HELD, DEFAULT_HELD)
    local dist_col = settings.color(ID_DIST, DEFAULT_MUTED)
    local box_col = settings.color(ID_BOX_COLOR, DEFAULT_BOX)
    local flag_cols = {
        down = settings.color(ID_FLAG_DOWN, DEFAULT_FLAG.DOWN),
        sz = settings.color(ID_FLAG_SZ, DEFAULT_FLAG.SZ),
        staff = settings.color(ID_FLAG_STAFF, DEFAULT_FLAG.STAFF),
        revive = settings.color(ID_FLAG_REVIVE, DEFAULT_FLAG.REVIVE),
        move = settings.color(ID_FLAG_MOVE, DEFAULT_FLAG.MOVE),
        vip = settings.color(ID_FLAG_VIP, DEFAULT_FLAG.VIP),
        cheater = settings.color(ID_FLAG_CHEATER, DEFAULT_FLAG.CHEATER),
    }
    local base_ts = esp_util.text_size()

    local me = cache.local_player
    local mx, my, mz = nil, nil, nil
    if me then
        mx, my, mz = esp_util.vec3_pos(me.Position or me.position or me.HeadPosition or me.head_position)
    end

    for i = 1, #players do
        local p = players[i]
        if not p then goto continue end
        if p.IsAlive == false or p.is_alive == false then goto continue end

        local pname = p.Name or p.name or p.DisplayName or p.display_name
        local hx, hy, hz = esp_util.vec3_pos(
            p.HeadPosition or p.head_position or p.Position or p.position
        )
        if not hx then goto continue end

        local dist = 0
        if mx then
            local dx, dy, dz = hx - mx, hy - my, hz - mz
            local dist_sq = dx * dx + dy * dy + dz * dz
            if dist_sq > range_sq then goto continue end
            dist = math.sqrt(dist_sq)
        end

        if filter_team and not player_state.passes_team_check(p) then goto continue end

        local snap = nil
        if need_snap then
            snap = player_state.esp_state(p)
            if skip_downed and snap and snap.downed then goto continue end
            if filter_sz and snap and snap.safezone then goto continue end
        end

        -- Vector documents GetBounds.valid as the strict on-screen result.
        local bounds = native_bounds(p)
        if not esp_util.bounds_usable(bounds) then goto continue end

        if show_skel then
            local bones = native_bones(p)
            if bones then
                esp_util.draw_skeleton_bones(bones, skel_col, 1)
            end
        end

        local ts = base_ts
        if dist > 200 then ts = math.max(9, ts - 1) end
        if dist > 400 then ts = math.max(8, ts - 1) end

        local cx = bounds.x + bounds.w * 0.5
        if show_name then
            draw_util.text_centered(cx, bounds.y - ts - 5, pname or "?", name_col, ts)
        end

        if need_side then
            draw_side_tags(
                p, snap, show_clan, clan_menu_col, flag_cols, flags,
                bounds.x + bounds.w + 4, bounds.y, ts
            )
        end

        if box_mode == 1 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, box_col, 0)
        elseif box_mode == 2 then
            draw_util.box_esp(bounds.x, bounds.y, bounds.w, bounds.h, box_col, 1)
        end

        if show_health then
            draw_util.health_bar_on_box(bounds, p.Health or p.health, p.MaxHealth or p.max_health)
        end

        local below_y = bounds.y + bounds.h + 3
        if show_held then
            local held = held_label(p)
            if held then
                draw_util.text_centered(cx, below_y, held, held_col, ts)
                below_y = below_y + ts + 2
            end
        end

        if show_dist then
            draw_util.text_centered(
                cx,
                below_y,
                string.format("%dm", math.floor(dist + 0.5)),
                dist_col,
                ts
            )
        end

        ::continue::
    end
end

return M
