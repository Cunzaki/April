local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local player_state = April.require("game.player_state")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_ray = April.require("core.silent_ray")
local silent_resolve = April.require("features.combat.silent_resolve")
local manip_math = April.require("core.manip_math")
local desync_vis = April.require("core.desync_vis")
local theme = April.require("core.ui_theme")
local esp_util = April.require("core.esp_util")

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

local MANIP_LABELS = {
    direct = "MANIP: CLEAR SHOT",
    ready = "MANIP: RAY READY",
    blocked = "MANIP: NO PEEK",
    off = "",
}

local function draw_manip_status(cx, cy, fov, info)
    if not info or info.state == "off" then return end
    if not settings.bool(PREFIX .. "manip_status", false) then return end

    local ready = info.state == "ready" or info.state == "direct"
    local text = MANIP_LABELS[info.state] or "MANIP: ..."
    local col = ready and theme.GREEN or theme.RED

    local tw = theme.text_w(text, 11)
    local pad_x, pad_y = 10, 4
    local w = tw + pad_x * 2
    local h = 18
    local x = cx - w * 0.5
    local y = cy + fov + 10

    theme.draw_panel(x, y, w, h, {
        bg = theme.alpha(theme.PANEL_DEEP, 0.9),
        border = theme.alpha(ready and theme.GREEN or theme.RED, 0.45),
        accent = theme.alpha(col, 0.85),
        accent_w = 2,
    })
    draw_util.text_centered(cx, y + pad_y, text, col, 11)
end

local function draw_manip_peek(info)
    if not settings.bool(PREFIX .. "manip_peek_vis", true) then return end
    if not info or not info.peek then return end
    if info.state ~= "ready" then return end

    local body = combat_origin.get_server_origin()
    if not body then return end

    local peek = info.peek
    local col_peek = { 1, 0.85, 0.2, 0.95 }
    local show_labels = settings.bool(PREFIX .. "manip_status", false)
    local eye_y = peek.y + manip_math.eye_offset_y()

    desync_vis.draw_cross(peek.x, eye_y, peek.z, 0.85, col_peek, 2)
    if show_labels then
        desync_vis.draw_labeled(peek.x, eye_y, peek.z, "PEEK", col_peek, 11)
    end
    desync_vis.draw_link(body, peek, { col_peek[1], col_peek[2], col_peek[3], 0.3 }, 1)

    local ray_from = manip_math.peek_track_origin(peek)
    if ray_from and cached_track.aim then
        desync_vis.draw_link(ray_from, cached_track.aim, { 1, 0.45, 0.2, 0.55 }, 1.5)
    end
end

local function draw_tp_ray_path(info)
    if not info then return end

    local path = info.tp_path or info.curve_path
    if not path or #path < 2 then return end

    if info.state == "tp" then
        if not settings.bool(PREFIX .. "bullet_tp", false) then return end
        if not settings.bool(PREFIX .. "tp_ray_vis", false) then return end
    elseif info.state ~= "curve" then
        return
    end

    local col = settings.color(PREFIX .. "tp_ray_vis", { 0.95, 0.45, 1, 0.9 })
    if info.state == "curve" then
        col = { 0.45, 0.85, 1, 0.45 }
    end
    for i = 1, #path - 1 do
        local a, b = path[i], path[i + 1]
        esp_util.draw_world_line(a.x, a.y, a.z, b.x, b.y, b.z, col, 1.5)
    end

    local hook = cached_track.origin
    local aim = cached_track.aim
    if hook and aim and info.state == "tp" then
        desync_vis.draw_cross(hook.x, hook.y, hook.z, 0.45, { 1, 0.85, 0.2, 0.95 }, 2)
        desync_vis.draw_link(hook, aim, { col[1], col[2], col[3], 0.35 }, 1)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)

    menu_util.register_keybind(T, G.SILENT_AIM, P_MASTER, "Enable Silent Aim", false)

    combat_menu.register_silent_aim(T, G.SILENT_AIM, PREFIX, P_MASTER, {
        fov_default = 150,
        fov_color = theme.CYAN,
        line_color = theme.RED,
    })

    menu_util.bind_children(P_MASTER, {
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filter_health", PREFIX .. "filter_visible", PREFIX .. "filter_team",
        PREFIX .. "target_players", PREFIX .. "target_npcs", PREFIX .. "target_npc_soldiers", PREFIX .. "target_npc_bosses",
        PREFIX .. "sticky", PREFIX .. "wallbang",
        PREFIX .. "bullet_tp", PREFIX .. "tp_ray_mode", PREFIX .. "tp_ray_vis",
        PREFIX .. "bullet_manip", PREFIX .. "manip_dist", PREFIX .. "manip_status", PREFIX .. "manip_peek_vis",
        PREFIX .. "draw_fov", PREFIX .. "fov_style", PREFIX .. "target_line",
        PREFIX .. "hit_chance", PREFIX .. "max_dist", PREFIX .. "fov",
    })

    menu_util.bind_children(PREFIX .. "bullet_tp", {
        PREFIX .. "tp_ray_mode", PREFIX .. "tp_ray_vis",
    })

    menu_util.bind_children(PREFIX .. "bullet_manip", {
        PREFIX .. "manip_dist", PREFIX .. "manip_status", PREFIX .. "manip_peek_vis",
    })

    menu_util.bind_children(PREFIX .. "draw_fov", {
        PREFIX .. "fov_style",
    })

    menu_util.bind_children(PREFIX .. "target_npcs", {
        PREFIX .. "target_npc_soldiers", PREFIX .. "target_npc_bosses",
    })
end

local function active()
    return settings.enabled(P_MASTER) and silent_ray.available()
end

local function update_target(cx, cy, fov)
    local sticky = settings.bool(PREFIX .. "sticky", false)
    local now = tick_ms()

    if sticky and locked_target then
        if not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
            locked_target = nil
        end
    end

    if locked_target and sticky then
        return
    end

    if now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end

function M.update(_dt)
    cached_track.origin = nil
    cached_track.aim = nil
    cached_track.manip = { state = "off" }
    cached_track.tracking = false

    if not active() then
        locked_target = nil
        fire_was_down = false
        shot_allowed = true
        silent_ray.stop()
        return
    end

    silent_ray.ensure_hook()

    if not holding_weapon() then
        silent_ray.stop()
        return
    end

    combat_origin.sync_weapon(weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name())

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)

    update_target(cx, cy, fov)

    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        return
    end

    -- Hit chance rolls once per mouse-down (not every frame).
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
        -- Miss this click: stop tracking once, do not re-call native stop every frame.
        silent_ray.stop()
        return
    end

    local ok_resolve, origin, aim, manip_info = pcall(silent_resolve.resolve_track, locked_target, PREFIX, cx, cy)
    if not ok_resolve or not aim or not origin then
        silent_ray.stop()
        return
    end

    cached_track.origin = origin
    cached_track.aim = aim
    cached_track.manip = manip_info or { state = "off" }

    local info = cached_track.manip
    local ok_track = false
    if info.use_curve and silent_ray.track_curve then
        ok_track = silent_ray.track_curve(origin, aim, info.weapon, SHOOT_VK) == true
        if silent_ray.last_curve then
            local curve = silent_ray.last_curve()
            if curve and curve.path then
                info.curve_path = curve.path
            end
        end
    else
        ok_track = silent_ray.track(origin, aim, SHOOT_VK) == true
    end
    cached_track.tracking = ok_track
end

function M.get_target()
    return locked_target
end

function M.draw()
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)

    if active() and settings.bool(PREFIX .. "draw_fov", false) then
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

    if active() and settings.bool(PREFIX .. "bullet_manip", false) then
        draw_manip_status(cx, cy, fov, cached_track.manip)
        draw_manip_peek(cached_track.manip)
    end

    if active() then
        draw_tp_ray_path(cached_track.manip)
    end

    if active() and locked_target and settings.bool(PREFIX .. "target_line", false) then
        local aim = cached_track.aim
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color(PREFIX .. "target_line", { 1, 0.25, 0.25, 1 })
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end
end

return M
