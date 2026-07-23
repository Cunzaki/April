local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_ray = April.require("core.silent_ray")
local silent_resolve = April.require("features.combat.silent_resolve")
local silent_whitelist = April.require("features.combat.silent_whitelist")
local bullet_hud = April.require("features.combat.bullet_hud")
local body_peek = April.require("features.combat.body_peek")
local theme = April.require("core.ui_theme")

local M = {}
local locked_target = nil
local PREFIX = "april_silent_"
local P_MASTER = "april_silent_aim"
local SHOOT_VK = 0x01
local TARGET_SCAN_MS = 33

local cached_track = { origin = nil, aim = nil, manip = { state = "off" }, tracking = false }
local last_target_scan = 0
local fire_was_down = false
local shot_allowed = true

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

local function holding_weapon()
    if weapons.holding_ranged_weapon() then return true end
    if weapons.get_held_ranged_weapon_name() then return true end
    local lp = entity and entity.get_local_player and entity.get_local_player()
    if lp and lp.tool_name and lp.tool_name ~= "" then
        return weapons.is_ranged_weapon_name(lp.tool_name)
    end
    return false
end

local P_BULLET = "april_bullet_enabled"

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)

    menu_util.register_keybind(T, G.SILENT_AIM, P_MASTER, "Enable Silent Aim", false)

    combat_menu.register_silent_aim(T, G.SILENT_AIM, PREFIX, P_MASTER, {
        fov_default = 150,
        fov_color = theme.CYAN,
        line_color = theme.RED,
    })

    menu.add_checkbox(T, G.SILENT_AIM, P_BULLET, "Enable Bullet", false)
    combat_menu.register_bullet(T, G.SILENT_AIM, PREFIX, P_BULLET)

    menu_util.bind_children(P_MASTER, {
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filters",
        PREFIX .. "whitelist_ids", PREFIX .. "whitelist_clear",
        PREFIX .. "targets", PREFIX .. "options",
        PREFIX .. "draw_fov", PREFIX .. "fov_style", PREFIX .. "target_line",
        PREFIX .. "hit_chance", PREFIX .. "max_dist", PREFIX .. "fov",
    })

    menu_util.bind_children(P_BULLET, {
        PREFIX .. "hitscan",
        PREFIX .. "bullet_tp",
        PREFIX .. "bullet_manip", PREFIX .. "manip_dist", PREFIX .. "manip_extend", PREFIX .. "manip_extend_dist",
        "april_bullet_body_peek",
        PREFIX .. "manip_status", PREFIX .. "manip_peek_vis",
    })

    menu_util.bind_children(PREFIX .. "bullet_manip", {
        PREFIX .. "manip_dist", PREFIX .. "manip_extend", PREFIX .. "manip_extend_dist",
        "april_bullet_body_peek",
    })

    menu_util.bind_children(PREFIX .. "manip_extend", {
        PREFIX .. "manip_extend_dist",
    })

    menu_util.bind_children(PREFIX .. "draw_fov", {
        PREFIX .. "fov_style",
    })
end

local function silent_active()
    return settings.enabled(P_MASTER) and silent_ray.available()
end

local function bullet_track_active()
    return settings.bool(P_BULLET, false)
        and silent_resolve.any_bullet_feature()
        and silent_ray.available()
end

local function active()
    return silent_active() or bullet_track_active()
end

local function update_target(cx, cy, fov, find_opts)
    local sticky = settings.multi(PREFIX .. "options", 1, false)
    local now = tick_ms()
    find_opts = find_opts or {}

    if locked_target and targeting.is_npc_target(locked_target) then
        locked_target = targeting.refresh_npc_target(locked_target)
    end

    if locked_target and not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov, find_opts) then
        locked_target = nil
    end

    if locked_target and sticky then
        return
    end

    if sticky and now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX, find_opts)
end

function M.update(dt)
    bullet_hud.update(dt)
    cached_track.origin = nil
    cached_track.aim = nil
    cached_track.manip = { state = "off" }
    cached_track.tracking = false

    -- Ragebot owns the silent hook while active.
    local rage_on = settings.enabled("april_rage_enabled")
    if rage_on then
        locked_target = nil
        fire_was_down = false
        shot_allowed = true
        body_peek.tick(nil, nil)
        return
    end

    if not active() then
        locked_target = nil
        fire_was_down = false
        shot_allowed = true
        silent_ray.stop()
        body_peek.tick(nil, nil)
        return
    end

    silent_ray.ensure_hook()

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local use_silent_fov = silent_active()
    local fov = use_silent_fov and settings.num(PREFIX .. "fov", 150) or 99999
    local find_opts = use_silent_fov and {} or { ignore_fov = true }
    if silent_resolve.bypass_visibility() then
        find_opts.ignore_visible = true
    end

    if not holding_weapon() then
        silent_ray.stop()
        if use_silent_fov then
            update_target(cx, cy, fov, find_opts)
        end
        return
    end

    combat_origin.sync_weapon(weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name())

    update_target(cx, cy, fov, find_opts)

    local wl_target = locked_target
    if not wl_target or not targeting.is_aim_target(wl_target) then
        wl_target = targeting.find_target(cx, cy, fov, PREFIX, {
            ignore_whitelist = true,
            ignore_fov = find_opts.ignore_fov,
            ignore_visible = find_opts.ignore_visible,
        })
    end
    silent_whitelist.tick(wl_target, PREFIX)

    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        body_peek.tick(nil, nil)
        return
    end

    -- Hit chance only for silent aim mouse-fire (not bullet-only).
    if use_silent_fov then
        local firing = input and input.is_key_down and input.is_key_down(SHOOT_VK)
        if firing and not fire_was_down then
            local hit_chance = settings.num(PREFIX .. "hit_chance", 100)
            if hit_chance >= 100 then
                shot_allowed = true
            else
                local roll = math.random(1, 100)
                shot_allowed = roll <= hit_chance
            end
        elseif not firing then
            shot_allowed = true
        end
        fire_was_down = firing and true or false

        if not shot_allowed then
            silent_ray.stop()
            return
        end
    else
        shot_allowed = true
        fire_was_down = false
    end

    local ok_resolve, origin, aim, manip_info = pcall(silent_resolve.resolve_track, locked_target, PREFIX, cx, cy)
    if not ok_resolve or not aim or not origin then
        silent_ray.stop()
        if manip_info then
            cached_track.manip = manip_info
        end
        return
    end

    cached_track.origin = origin
    cached_track.aim = aim
    cached_track.manip = manip_info or { state = "off" }

    local info = cached_track.manip
    local ok_track = false
    local hit = info.hitpart or aim
    local track_aim = aim
    if use_silent_fov then
        if info.use_curve and silent_ray.track_curve then
            ok_track = silent_ray.track_curve(
                origin, hit, info.weapon, SHOOT_VK, hit
            ) == true
            if not info.curve_path and silent_ray.last_curve then
                local curve = silent_ray.last_curve()
                if curve and curve.path then
                    info.curve_path = curve.path
                end
            end
        else
            ok_track = silent_ray.track(origin, track_aim, SHOOT_VK, hit) == true
        end
    else
        -- Bullet-only: per-frame set (works without holding LMB).
        ok_track = silent_ray.set_target(origin, track_aim, hit) == true
    end
    cached_track.aim = track_aim
    cached_track.tracking = ok_track
    body_peek.tick(locked_target, hit)
end

function M.get_target()
    return locked_target
end

-- Gear / tracers: FOV target while silent aim is on (even without a gun out).
function M.get_scoped_target()
    if locked_target then return locked_target end
    if not settings.enabled(P_MASTER) then return nil end

    local sw, sh = targeting.screen_center()
    local fov = settings.num(PREFIX .. "fov", 150)
    return targeting.find_target(sw * 0.5, sh * 0.5, fov, PREFIX)
end

local function snapline_aim_point(cx, cy)
    if cached_track.aim then
        return cached_track.aim
    end
    if not locked_target then
        return nil
    end
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    return targeting.get_aim_point(locked_target, PREFIX, nil, origin, cx, cy, false)
end

function M.draw()
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)

    if silent_active() and settings.bool(PREFIX .. "draw_fov", false) then
        local col = settings.color(PREFIX .. "draw_fov", { 0.4, 0.9, 1, 1 })
        local filled = settings.num(PREFIX .. "fov_style", 1) == 1

        if filled and draw and draw.circle_filled then
            local fill = settings.color(PREFIX .. "draw_fov", { 0.4, 0.9, 1, 0.12 })
            local c = { fill[1], fill[2], fill[3], (fill[4] or 1) * 0.25 }
            draw.circle_filled(cx, cy, fov, c, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end

    if settings.bool(P_BULLET, false) then
        bullet_hud.draw(cx, cy, fov, cached_track)
    end

    if silent_active() and locked_target and settings.bool(PREFIX .. "target_line", false) then
        local col = settings.color(PREFIX .. "target_line", { 1, 0.25, 0.25, 1 })
        local aim = snapline_aim_point(cx, cy)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                -- Same as camera aimbot: from screen center, not bottom.
                local a = col[4] or 1
                draw_util.line(cx, cy, tx, ty, { 0, 0, 0, a * 0.9 }, 3)
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end
end

return M
