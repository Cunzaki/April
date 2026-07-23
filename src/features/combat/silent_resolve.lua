local settings = April.require("core.settings")
local combat_origin = April.require("game.combat_origin")
local silent_ray = April.require("core.silent_ray")
local manip_math = April.require("core.manip_math")
local targeting = April.require("features.combat.targeting")
local bullet_tp_ray = April.require("features.combat.bullet_tp_ray")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")

local M = {}

local OFF_INFO = {
    state = "off",
    manip_state = "off",
    peek = nil,
    radius = 1,
    hitscan_on = false,
    tp_on = false,
    manip_on = false,
}
local BULLET_PREFIX = "april_silent_"

function M.bullet_enabled()
    return settings.bool("april_bullet_enabled", false)
end

local function bullet_flag(name, default)
    if not M.bullet_enabled() then
        return false
    end
    return settings.bool(BULLET_PREFIX .. name, default == true)
end

local function fire_origin(camera)
    return combat_origin.get_muzzle_origin() or camera
end

local function feature_flags()
    return {
        hitscan_on = bullet_flag("hitscan", false),
        tp_on = bullet_flag("bullet_tp", false),
        manip_on = bullet_flag("bullet_manip", false),
    }
end

local function merge_info(base, manip_extra, flags)
    local info = base or {}
    flags = flags or feature_flags()
    info.hitscan_on = flags.hitscan_on
    info.tp_on = flags.tp_on
    info.manip_on = flags.manip_on

    if manip_extra then
        info.manip_state = manip_extra.state or "off"
        info.peek = manip_extra.peek or info.peek
        info.radius = manip_extra.radius or info.radius
        info.base_radius = manip_extra.base_radius
        info.extend_active = manip_extra.extend_active
        info.scan_progress = manip_extra.scan_progress or info.scan_progress
        info.body_peek = manip_extra.body_peek
    else
        info.manip_state = info.manip_state or "off"
    end

    return info
end

local function body_peek_mod()
    local ok, mod = pcall(function()
        return April.require("features.combat.body_peek")
    end)
    if ok then return mod end
    return nil
end

local function resolve_manip(body, hitpart, muzzle, target)
    local extra = {
        state = "off",
        peek = nil,
        radius = 0,
        base_radius = 0,
        extend_active = false,
        scan_progress = 0,
        body_peek = false,
    }
    if not bullet_flag("bullet_manip", false) or not body then
        return nil, extra
    end

    local base_r = manip_math.clamp_radius(settings.num(BULLET_PREFIX .. "manip_dist", 1))
    local extend_on = settings.bool(BULLET_PREFIX .. "manip_extend", false)
    local ext_extra = extend_on
        and manip_math.clamp_extend_extra(settings.num(BULLET_PREFIX .. "manip_extend_dist", 7))
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

    local max_r = extend_on and (base_r + ext_extra) or base_r
    local body_peek = body_peek_mod()
    local use_body_peek = settings.bool("april_bullet_body_peek", false) and body_peek

    if ev.state == "ready" and ev.peek then
        local peek = ev.peek
        if use_body_peek and body_peek.ensure_peek then
            local moved = body_peek.ensure_peek(peek, hitpart, target, max_r)
            if moved then
                extra.body_peek = true
                peek = moved
            end
        end
        return manip_math.peek_track_origin(peek, muzzle, body), extra
    end

    if ev.state == "blocked" and use_body_peek and body_peek.try_peek then
        local peek = body_peek.try_peek(body, hitpart, max_r, target)
        if peek then
            extra.state = "ready"
            extra.peek = peek
            extra.body_peek = true
            extra.scan_progress = 1
            local track = manip_math.peek_track_origin(peek, muzzle, body)
            return track, extra
        end
    end

    return nil, extra
end

local function apply_drop_aim(origin, hitpart, weapon, state, manip_extra, flags)
    local muzzle = origin or combat_origin.get_muzzle_origin()
    local curve = ballistic.curve_for_weapon(muzzle, hitpart, weapon, 24)
    local info = merge_info({
        state = state or "curve",
        peek = nil,
        radius = manip_extra and manip_extra.radius or 0,
        use_curve = true,
        weapon = weapon,
        hitpart = hitpart,
        curve_path = curve and curve.path or nil,
        launch_dir = curve and curve.launch_dir or nil,
    }, manip_extra, flags)
    return muzzle, hitpart, info
end

local function apply_ray_aim(origin, aim, hitpart, weapon, state, manip_extra, meta, flags)
    meta = meta or {}
    local info = merge_info({
        state = state,
        peek = manip_extra and manip_extra.peek or nil,
        radius = manip_extra and manip_extra.radius or 0,
        use_curve = false,
        weapon = weapon,
        hitpart = hitpart,
        tp_path = meta.tp_path,
        tp_method = meta.method,
        tp_scan_visible = meta.tp_scan_visible,
        tp_scan_progress = meta.tp_scan_progress,
    }, manip_extra, flags)
    return origin, aim, info
end

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end

    local flags = feature_flags()
    local weapon = weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()
    local bone = targeting.bone_name(prefix)
    local hitpart = targeting.resolve_bone_world(target, bone, cx, cy)
    if not hitpart then return nil, nil, OFF_INFO end
    local muzzle = fire_origin(camera)
    local body = combat_origin.get_server_origin()

    local manip_fire, manip_extra = resolve_manip(body, hitpart, muzzle, target)
    local fire = manip_fire or muzzle

    local hitscan_on = flags.hitscan_on
    local tp_on = flags.tp_on

    if tp_on then
        local head = targeting.resolve_bone_world(target, "Head", cx, cy) or hitpart
        local tp = bullet_tp_ray.resolve({
            method = bullet_tp_ray.METHOD_UNDER_TP,
            camera = camera,
            hitpart = head,
            bone = "Head",
            muzzle = muzzle,
            body = body,
        })
        if tp and tp.origin and tp.aim then
            local path = tp.tp_path or bullet_tp_ray.build_path(tp.origin, tp.aim, muzzle)
            if manip_extra.peek and manip_fire then
                path = bullet_tp_ray.build_path(manip_fire, head, muzzle) or path
            end
            return apply_ray_aim(tp.origin, tp.aim, tp.hitpart or head, weapon, "tp", manip_extra, {
                tp_path = path,
                method = tp.method,
                tp_scan_visible = tp.tp_scan_visible,
                tp_scan_progress = tp.tp_scan_progress,
            }, flags)
        end
    end

    if manip_extra.state == "ready" and manip_fire then
        return apply_ray_aim(manip_fire, hitpart, hitpart, weapon, "ready", manip_extra, {
            tp_path = bullet_tp_ray.build_path(manip_fire, hitpart, muzzle),
            method = "Manip",
        }, flags)
    end

    if hitscan_on then
        return apply_ray_aim(muzzle or fire, hitpart, hitpart, weapon, "hitscan", manip_extra, nil, flags)
    end

    if manip_extra.state == "direct" then
        return apply_drop_aim(muzzle, hitpart, weapon, "direct", manip_extra, flags)
    end

    return apply_drop_aim(muzzle, hitpart, weapon, "curve", manip_extra, flags)
end

function M.any_bullet_feature()
    return bullet_flag("hitscan", false)
        or bullet_flag("bullet_tp", false)
        or bullet_flag("bullet_manip", false)
end

function M.bypass_visibility()
    return bullet_flag("bullet_tp", false) or bullet_flag("hitscan", false)
end

return M
