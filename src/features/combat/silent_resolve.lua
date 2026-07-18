local settings = April.require("core.settings")
local combat_origin = April.require("game.combat_origin")
local silent_ray = April.require("core.silent_ray")
local manip_math = April.require("core.manip_math")
local targeting = April.require("features.combat.targeting")
local bullet_tp_ray = April.require("features.combat.bullet_tp_ray")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")

local M = {}

local OFF_INFO = { state = "off", peek = nil, radius = 1 }

local function fire_origin(camera)
    return combat_origin.get_muzzle_origin() or camera
end

local function resolve_manip(body, hitpart, muzzle, prefix)
    local extra = {
        state = "off",
        peek = nil,
        radius = 0,
        base_radius = 0,
        extend_active = false,
        scan_progress = 0,
    }
    if not settings.bool(prefix .. "bullet_manip", false) or not body then
        return nil, extra
    end

    local base_r = manip_math.clamp_radius(settings.num(prefix .. "manip_dist", 1))
    local extend_on = settings.bool(prefix .. "manip_extend", false)
    local ext_extra = extend_on
        and manip_math.clamp_extend_extra(settings.num(prefix .. "manip_extend_dist", 7))
        or 0
    local ev = manip_math.evaluate_manipulation(body, hitpart, {
        base_radius = base_r,
        extend = extend_on,
        extend_extra = ext_extra,
    })

    extra.state = ev.state
    extra.peek = ev.peek
    extra.radius = ev.radius or base_r
    extra.base_radius = base_r
    extra.extend_active = ev.extend_active == true
    extra.scan_progress = ev.scan_progress or 0

    if ev.state == "ready" and ev.peek then
        return manip_math.peek_track_origin(ev.peek, muzzle, body), extra
    end
    return nil, extra
end

local function apply_drop_aim(origin, hitpart, weapon, state, extra)
    local muzzle = origin or combat_origin.get_muzzle_origin()
    -- Visual drop arc only (path ends on hitpart). Silent API aims at hitpart —
    -- hook projectiles are effectively hitscan-speed, so aim-up misses.
    local curve = ballistic.curve_for_weapon(muzzle, hitpart, weapon, 24)
    local info = {
        state = state or "curve",
        peek = extra and extra.peek or nil,
        radius = extra and extra.radius or 0,
        use_curve = true,
        weapon = weapon,
        hitpart = hitpart,
        curve_path = curve and curve.path or nil,
        launch_dir = curve and curve.launch_dir or nil,
        base_radius = extra and extra.base_radius or nil,
        extend_active = extra and extra.extend_active or false,
        scan_progress = extra and extra.scan_progress or 0,
    }
    return muzzle, hitpart, info
end

local function apply_ray_aim(origin, aim, hitpart, weapon, state, extra, meta)
    meta = meta or {}
    local info = {
        state = state,
        peek = extra and extra.peek or nil,
        radius = extra and extra.radius or 0,
        use_curve = false,
        weapon = weapon,
        hitpart = hitpart,
        base_radius = extra and extra.base_radius or nil,
        extend_active = extra and extra.extend_active or false,
        scan_progress = extra and extra.scan_progress or 0,
        tp_path = meta.tp_path,
        tp_method = meta.method,
        tp_visual = meta.visual == true,
    }
    return origin, aim, info
end

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end

    local bone = targeting.bone_name(prefix)
    local hitpart = targeting.resolve_bone_world(target, bone, cx, cy)
    if not hitpart then return nil, nil, OFF_INFO end
    local center = bullet_tp_ray.target_center(hitpart, bone) or hitpart

    local weapon = weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()
    local muzzle = fire_origin(camera)
    local body = combat_origin.get_server_origin()

    local manip_fire, manip_extra = resolve_manip(body, hitpart, muzzle, prefix)
    local fire = manip_fire or muzzle

    local hitscan_on = settings.bool(prefix .. "hitscan", false)
    local tp_on = settings.bool(prefix .. "bullet_tp", false)

    if tp_on then
        local tp = bullet_tp_ray.resolve({
            method = settings.num(prefix .. "tp_method", 0),
            camera = camera,
            hitpart = hitpart,
            bone = bone,
            muzzle = muzzle,
        })
        if tp and tp.origin and tp.aim then
            return apply_ray_aim(tp.origin, tp.aim, tp.hitpart or center, weapon, "tp", manip_extra, tp)
        end
    end

    if hitscan_on then
        return apply_ray_aim(fire, center, center, weapon, "hitscan", manip_extra)
    end

    if manip_extra.state == "ready" and manip_fire then
        return apply_ray_aim(manip_fire, center, center, weapon, "ready", manip_extra, {
            tp_path = bullet_tp_ray.build_path(manip_fire, center, muzzle),
            method = "Manip",
            visual = false,
        })
    end

    if manip_extra.state == "direct" then
        return apply_drop_aim(muzzle, center, weapon, "direct", manip_extra)
    end

    return apply_drop_aim(muzzle, center, weapon, "curve", manip_extra)
end

return M
