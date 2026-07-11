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
local PIERCE_PAD = 1.25

local function pierce_origin(from, to)
    if not from or not to then return from end
    if not raycast or not raycast.cast then return from end
    if raycast.is_ready and not raycast.is_ready() then return from end

    local fx, fy, fz = from.x, from.y, from.z
    local tx, ty, tz = to.x, to.y, to.z
    local dx, dy, dz = tx - fx, ty - fy, tz - fz
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return from end

    local hit, _, dist = raycast.cast(fx, fy, fz, tx, ty, tz)
    if not hit or not dist or dist <= 0.05 then return from end

    local travel = dist + PIERCE_PAD
    if travel >= len - 0.5 then
        travel = len * 0.65
    end

    local t = travel / len
    return {
        x = fx + dx * t,
        y = fy + dy * t,
        z = fz + dz * t,
    }
end

-- Fire origin for ballistic solve (muzzle preferred). Silent hook still uses camera.
local function fire_origin(camera)
    return combat_origin.get_muzzle_origin() or camera
end

-- Ballistic launch aim: MouseRaycast point so muzzle LookVector = launch_dir,
-- projectile arc (Speed/Gravity) lands on hitpart.
-- Track origin must be the fire/muzzle point so (aim_far - origin).Unit == launch_dir.
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
    }
    return muzzle, aim_far or hitpart, info
end

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end

    local hitpart = targeting.resolve_bone_world(target, targeting.bone_name(prefix), cx, cy)
    if not hitpart then return nil, nil, OFF_INFO end

    local track_origin = camera
    local wallbang = settings.multi(prefix .. "options", 2, false)
    local weapon = weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()

    if settings.bool(prefix .. "bullet_tp", false) then
        local head = targeting.bone_world(target, "Head") or hitpart
        local mode_idx = settings.num(prefix .. "tp_ray_mode", 0)
        local mode_name = bullet_tp_ray.mode_name(mode_idx)

        hitpart = bullet_tp_ray.hitpart_aim(head) or head
        track_origin = bullet_tp_ray.track_origin(camera, hitpart, mode_name) or hitpart

        return track_origin, hitpart, {
            state = "tp",
            peek = nil,
            radius = 0,
            tp_mode = mode_name,
            tp_path = bullet_tp_ray.build_path(mode_name, track_origin, hitpart, weapon),
            use_curve = false,
            weapon = weapon,
            hitpart = hitpart,
        }
    end

    if settings.bool(prefix .. "bullet_manip", false) then
        local body = combat_origin.get_server_origin()
        local max_r = manip_math.clamp_radius(settings.num(prefix .. "manip_dist", 1))
        local extra = { radius = max_r }
        local fire = fire_origin(camera)

        if body then
            local ev
            if settings.bool(prefix .. "manip_extend", false) then
                -- Extend: search up to 8 studs for physical/desync peek; keep 1-stud as fallback.
                local ext_r = manip_math.clamp_extend_radius(settings.num(prefix .. "manip_extend_dist", 8))
                ev = manip_math.evaluate_manipulation(body, hitpart, { max_radius = ext_r, extend = true })
                if ev.state ~= "ready" then
                    ev = manip_math.evaluate_manipulation(body, hitpart, { max_radius = max_r })
                else
                    extra.extend = true
                end
            else
                ev = manip_math.evaluate_manipulation(body, hitpart, { max_radius = max_r })
            end
            extra.state = ev.state
            extra.peek = ev.peek
            extra.radius = ev.radius or max_r
            if ev.state == "ready" and ev.peek then
                fire = manip_math.peek_track_origin(ev.peek) or fire
            end
        else
            extra.state = "blocked"
        end

        if wallbang then
            fire = pierce_origin(fire, hitpart) or fire
        end

        local origin, aim_far, info = apply_drop_aim(fire, hitpart, weapon, extra.state or "blocked", extra)
        return origin, aim_far, info
    end

    -- Default silent: muzzle → ballistic launch (arc lands on hitpart).
    local fire = fire_origin(camera)
    if wallbang then
        fire = pierce_origin(fire, hitpart) or fire
    end
    return apply_drop_aim(fire, hitpart, weapon, "curve", nil)
end

return M
