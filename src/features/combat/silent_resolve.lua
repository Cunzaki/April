local settings = April.require("core.settings")
local combat_origin = April.require("game.combat_origin")
local silent_ray = April.require("core.silent_ray")
local manip_math = April.require("core.manip_math")
local targeting = April.require("features.combat.targeting")
local bullet_tp_ray = April.require("features.combat.bullet_tp_ray")

local M = {}

local OFF_INFO = {
    state = "off",
    manip_state = "off",
    peek = nil,
    radius = 1,
    hitscan_on = false,
    tp_on = false,
    manip_on = false,
    hitbox_on = false,
    hitbox_mult = 1,
}
local BULLET_PREFIX = "april_silent_"
local SHOOT_VK = 0x01

function M.bullet_enabled()
    return settings.enabled("april_bullet_enabled")
end

local function bullet_flag(name, default)
    if not M.bullet_enabled() then
        return false
    end
    return settings.bool(BULLET_PREFIX .. name, default == true)
end

local function thick_mod()
    local ok, mod = pcall(function()
        return April.require("features.combat.thick_bullet")
    end)
    if ok then return mod end
    return nil
end

local function hitbox_state()
    local thick = thick_mod()
    if not thick or not thick.is_active or not thick.is_active() then
        return false, 1
    end
    local mult = 1
    if thick.thickness then
        mult = tonumber(thick.thickness()) or 1
    end
    if mult < 1 then mult = 1 end
    if mult > 4 then mult = 4 end
    return true, mult
end

local function mb1_held()
    local key_down = input and (input.is_key_down or input.IsKeyDown)
    return key_down and key_down(SHOOT_VK) == true
end

local function fire_origin(camera)
    return combat_origin.get_muzzle_origin() or camera
end

local function feature_flags()
    local hitbox_on, hitbox_mult = hitbox_state()
    return {
        hitscan_on = bullet_flag("hitscan", false),
        tp_on = bullet_flag("bullet_tp", false),
        manip_on = bullet_flag("bullet_manip", false),
        hitbox_on = hitbox_on,
        hitbox_mult = hitbox_mult,
    }
end

local function merge_info(base, manip_extra, flags)
    local info = base or {}
    flags = flags or feature_flags()
    info.hitscan_on = flags.hitscan_on
    info.tp_on = flags.tp_on
    info.manip_on = flags.manip_on
    info.hitbox_on = flags.hitbox_on == true
    info.hitbox_mult = tonumber(flags.hitbox_mult) or 1

    if manip_extra then
        info.manip_state = manip_extra.state or "off"
        info.peek = manip_extra.peek or info.peek
        info.radius = manip_extra.radius or info.radius
        info.base_radius = manip_extra.base_radius
        info.extend_active = manip_extra.extend_active
        info.scan_progress = manip_extra.scan_progress or info.scan_progress
        info.body_peek = manip_extra.body_peek
        info.scan_cached = manip_extra.cached == true
        info.scan_rays = manip_extra.rays
        info.radius_idx = manip_extra.radius_idx
        info.radii_total = manip_extra.radii_total
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
    extra.cached = ev.cached == true
    extra.rays = ev.rays
    extra.radius_idx = ev.radius_idx
    extra.radii_total = ev.radii_total

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

    -- Only ask body_peek to search after manip finished blocked — never while
    -- the amortized scanner is still working (avoids a second full ray storm).
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

local function apply_ray_aim(origin, aim, hitpart, state, manip_extra, meta, flags)
    meta = meta or {}
    local info = merge_info({
        state = state,
        peek = manip_extra and manip_extra.peek or nil,
        radius = manip_extra and manip_extra.radius or 0,
        use_curve = false,
        hitpart = hitpart,
        tp_path = meta.tp_path,
        tp_method = meta.method,
        tp_scan_visible = meta.tp_scan_visible,
        tp_scan_progress = meta.tp_scan_progress,
        head_scale = meta.head_scale,
    }, manip_extra, flags)
    return origin, aim, info
end

local function override_aim_point(target, bone, hitpart, flags)
    if not flags.hitbox_on or not target or not hitpart then
        return hitpart
    end
    local name = tostring(bone or "")
    if name ~= "Head" and name ~= "head" then
        return hitpart
    end
    local thick = thick_mod()
    if thick and thick.head_face_world then
        local face = thick.head_face_world(target, 0)
        if face then return face end
    end
    return hitpart
end

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end

    local flags = feature_flags()
    local bone = targeting.bone_name(prefix)
    local hitpart = targeting.resolve_bone_world(target, bone, cx, cy, { prefix = prefix })
    if not hitpart then return nil, nil, OFF_INFO end
    hitpart = override_aim_point(target, bone, hitpart, flags)
    local muzzle = fire_origin(camera)
    local body = combat_origin.get_server_origin()

    local manip_fire, manip_extra = resolve_manip(body, hitpart, muzzle, target)
    local fire = manip_fire or muzzle

    local hitscan_on = flags.hitscan_on
    local tp_on = flags.tp_on
    local firing = mb1_held()

    if tp_on then
        local head = targeting.resolve_bone_world(target, "Head", cx, cy, { prefix = prefix }) or hitpart
        local seed = nil
        if flags.hitbox_on then
            local thick = thick_mod()
            if thick and thick.head_face_world then
                seed = thick.head_face_world(target, 0)
            end
        end
        local tp = bullet_tp_ray.resolve({
            method = bullet_tp_ray.METHOD_UNDER_TP,
            camera = camera,
            hitpart = head,
            bone = "Head",
            muzzle = muzzle,
            body = body,
            head_scale = flags.hitbox_on and flags.hitbox_mult or 1,
            lite = not firing,
            seed = seed,
        })
        if tp and tp.origin and tp.aim then
            local path = tp.tp_path or bullet_tp_ray.build_path(tp.origin, tp.aim, muzzle)
            if manip_extra.peek and manip_fire then
                path = bullet_tp_ray.build_path(manip_fire, head, muzzle) or path
            end
            return apply_ray_aim(tp.origin, tp.aim, tp.hitpart or head, "tp", manip_extra, {
                tp_path = path,
                method = tp.method,
                tp_scan_visible = tp.tp_scan_visible,
                tp_scan_progress = tp.tp_scan_progress,
                head_scale = tp.head_scale or flags.hitbox_mult,
            }, flags)
        end
    end

    if manip_extra.state == "ready" and manip_fire then
        return apply_ray_aim(manip_fire, hitpart, hitpart, "ready", manip_extra, {
            tp_path = bullet_tp_ray.build_path(manip_fire, hitpart, muzzle),
            method = "Manip",
        }, flags)
    end

    if hitscan_on then
        return apply_ray_aim(muzzle or fire, hitpart, hitpart, "hitscan", manip_extra, {
            head_scale = flags.hitbox_on and flags.hitbox_mult or 1,
        }, flags)
    end

    -- Vector's silent-target hook redirects the ray directly to this point;
    -- do not apply projectile gravity, target velocity, or weapon ballistics.
    return apply_ray_aim(muzzle or fire, hitpart, hitpart, "direct", manip_extra, nil, flags)
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
