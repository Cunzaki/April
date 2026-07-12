local settings = April.require("core.settings")
local combat_origin = April.require("game.combat_origin")
local silent_ray = April.require("core.silent_ray")
local manip_math = April.require("core.manip_math")
local targeting = April.require("features.combat.targeting")
local bullet_tp_ray = April.require("features.combat.bullet_tp_ray")
local manip_extend = April.require("features.combat.manip_extend")
local weapons = April.require("game.weapons")
local ballistic = April.require("core.ballistic")

local M = {}

local OFF_INFO = { state = "off", peek = nil, radius = 1 }

local function fire_origin(camera)
    return combat_origin.get_muzzle_origin() or camera
end

local function apply_drop_aim(track_origin, hitpart, weapon, state, extra)
    local muzzle = fire_origin(track_origin)
    local aim_far, curve = ballistic.silent_aim_point(muzzle, hitpart, weapon)
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
        extend_burst = extra and extra.extend_burst or false,
    }
    return muzzle, aim_far or hitpart, info
end

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end

    local hitpart = targeting.resolve_bone_world(target, targeting.bone_name(prefix), cx, cy)
    if not hitpart then return nil, nil, OFF_INFO end

    local weapon = weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()

    if settings.bool(prefix .. "bullet_tp", false) then
        local head = targeting.bone_world(target, "Head") or hitpart
        hitpart = bullet_tp_ray.hitpart_aim(head) or head
        local track_origin = bullet_tp_ray.track_origin(camera, hitpart) or hitpart

        return track_origin, hitpart, {
            state = "tp",
            peek = nil,
            radius = 0,
            tp_path = bullet_tp_ray.build_path(track_origin, hitpart, weapon),
            use_curve = false,
            weapon = weapon,
            hitpart = hitpart,
        }
    end

    if settings.bool(prefix .. "bullet_manip", false) then
        local body = combat_origin.get_server_origin()
        local base_r = manip_math.clamp_radius(settings.num(prefix .. "manip_dist", 1))
        local extra = {
            radius = base_r,
            base_radius = base_r,
            extend_active = false,
            scan_progress = 0,
            extend_burst = false,
        }
        local fire = fire_origin(camera)

        if body then
            local ev
            if settings.bool(prefix .. "manip_extend", false) then
                local ext_extra = manip_math.clamp_extend_extra(settings.num(prefix .. "manip_extend_dist", 8))
                ev = manip_extend.evaluate_extend(body, hitpart, base_r, ext_extra)
            else
                ev = manip_math.evaluate_manipulation(body, hitpart, {
                    base_radius = base_r,
                })
            end
            extra.state = ev.state
            extra.peek = ev.peek
            extra.radius = ev.radius or base_r
            extra.base_radius = ev.base_radius or base_r
            extra.extend_active = ev.extend_active == true
            extra.scan_progress = ev.scan_progress or 0
            extra.extend_burst = ev.extend_burst == true
            if ev.state == "ready" and ev.peek then
                fire = manip_math.peek_track_origin(ev.peek) or fire
            elseif ev.state == "scanning" then
                extra.state = "scanning"
                return nil, nil, extra
            end
        else
            extra.state = "blocked"
        end

        local origin, aim_far, info = apply_drop_aim(fire, hitpart, weapon, extra.state or "blocked", extra)
        return origin, aim_far, info
    end

    local fire = fire_origin(camera)
    return apply_drop_aim(fire, hitpart, weapon, "curve", nil)
end

return M
