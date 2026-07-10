local math_util = April.require("core.math_util")

local M = {}

local ROBLOX_GRAV = 196.2

local function vec3(v)
    if not v then return 0, 0, 0 end
    return v.x or v.X or 0, v.y or v.Y or 0, v.z or v.Z or 0
end

local function combat_stats_mod()
    return April.require("game.combat_stats")
end

function M.gravity_accel(gravity_mult)
    -- Fallen CreateProjectile: v -= (0, 196.2 * Gravity, 0) * dt
    if not gravity_mult or gravity_mult <= 0 then
        return ROBLOX_GRAV * 0.55
    end
    if gravity_mult <= 2 then
        return ROBLOX_GRAV * gravity_mult
    end
    return gravity_mult
end

function M.calculate_drop(bullet_speed, bullet_gravity, position, origin)
    local px, py, pz = vec3(position)
    local ox, oy, oz = vec3(origin)
    local speed = math.max(bullet_speed or 950, 1)
    local dist = math_util.distance3(px - ox, py - oy, pz - oz)
    local time = dist / speed
    local g = M.gravity_accel(bullet_gravity)
    return 0.5 * g * time * time
end

-- Legacy lead+drop solver (movement prediction). Prefer hitpart_only + curve for silent.
function M.calculate_target_position(bullet_speed, bullet_gravity, velocity, position, origin)
    local px, py, pz = vec3(position)
    local ox, oy, oz = vec3(origin)
    local vx, vy, vz = vec3(velocity)

    local speed = math.max(bullet_speed or 950, 1)
    local g = M.gravity_accel(bullet_gravity)

    local horiz_speed = math.sqrt(vx * vx + vz * vz)
    if horiz_speed < 1.5 then
        vx, vy, vz = 0, vy, 0
    end
    vy = math.max(-80, math.min(80, vy))

    local time = math_util.distance3(px - ox, py - oy, pz - oz) / speed
    for _ = 1, 6 do
        local tx = px + vx * time
        local ty = py + vy * time
        local tz = pz + vz * time
        time = math_util.distance3(tx - ox, ty - oy, tz - oz) / speed
    end

    local drop = 0.5 * g * time * time
    return {
        x = px + vx * time,
        y = py + vy * time + drop,
        z = pz + vz * time,
    }
end

function M.predict_for_weapon(origin, position, velocity, weapon_name)
    local stats = combat_stats_mod().get_effective_stats(weapon_name)
    return M.calculate_target_position(stats.speed, stats.gravity, velocity, position, origin)
end

-- Solve flight time so |v0| == speed with v0 = (hit - origin + 0.5*g*t^2*up) / t.
-- Matches CreateProjectile: Direction.Unit * Speed, then gravity 196.2*Gravity per second.
local function solve_flight_time(dx, dy, dz, speed, g)
    local dist = math_util.distance3(dx, dy, dz)
    if dist < 0.05 then return 0.001 end

    local s2 = speed * speed
    local horiz2 = dx * dx + dz * dz

    -- |offset/t + (0, 0.5*g*t, 0)|^2 = s^2
    -- → (g^2/4)*t^4 + (g*dy - s^2)*t^2 + (horiz2+dy^2) = 0
    local a = (g * g) * 0.25
    local b = g * dy - s2
    local c = horiz2 + dy * dy

    local t = nil
    if a > 1e-8 then
        local disc = b * b - 4 * a * c
        if disc >= 0 then
            local sq = math.sqrt(disc)
            local u1 = (-b - sq) / (2 * a)
            local u2 = (-b + sq) / (2 * a)
            local best = nil
            for _, u in ipairs({ u1, u2 }) do
                if u and u > 1e-6 then
                    local cand = math.sqrt(u)
                    if not best or cand < best then
                        best = cand
                    end
                end
            end
            t = best
        end
    end

    -- Fallback: flat-time iterate (always works, slightly less exact |v0|).
    if not t then
        t = dist / speed
        for _ = 1, 10 do
            local vx = dx / t
            local vy = (dy + 0.5 * g * t * t) / t
            local vz = dz / t
            local sp = math.sqrt(vx * vx + vy * vy + vz * vz)
            if sp < 1e-6 then break end
            t = t * (sp / speed)
            if t < 0.001 then t = 0.001 end
        end
    end

    return math.max(t, 0.001)
end

-- Ballistic arc that lands exactly on hitpart.
-- launch_dir is the unit Direction the game should fire (aim-up under gravity).
-- aim_far is a far world point along that launch so MouseRaycast → muzzle LookVector matches.
function M.curve_to_hit(origin, hit, bullet_speed, bullet_gravity, steps)
    if not origin or not hit then return nil end
    steps = steps or 24

    local ox, oy, oz = vec3(origin)
    local hx, hy, hz = vec3(hit)
    local dx, dy, dz = hx - ox, hy - oy, hz - oz
    local dist = math_util.distance3(dx, dy, dz)
    if dist < 0.05 then
        return {
            path = { { x = ox, y = oy, z = oz }, { x = hx, y = hy, z = hz } },
            aim = { x = hx, y = hy, z = hz },
            aim_far = { x = hx, y = hy, z = hz },
            hit = { x = hx, y = hy, z = hz },
            launch_dir = { x = 0, y = 1, z = 0 },
            flight = 0,
        }
    end

    local speed = math.max(bullet_speed or 950, 1)
    local g = M.gravity_accel(bullet_gravity)
    local flight = solve_flight_time(dx, dy, dz, speed, g)

    local vx = dx / flight
    local vy = (dy + 0.5 * g * flight * flight) / flight
    local vz = dz / flight

    -- Game clamps to Direction.Unit * Speed — normalize then scale.
    local lm = math.sqrt(vx * vx + vy * vy + vz * vz)
    local launch_dir
    if lm > 0.001 then
        launch_dir = { x = vx / lm, y = vy / lm, z = vz / lm }
        vx, vy, vz = launch_dir.x * speed, launch_dir.y * speed, launch_dir.z * speed
    else
        launch_dir = { x = dx / dist, y = dy / dist, z = dz / dist }
        vx, vy, vz = launch_dir.x * speed, launch_dir.y * speed, launch_dir.z * speed
    end

    -- Re-solve flight with exact |v0|=speed so path endpoint stays on hitpart.
    flight = solve_flight_time(dx, dy, dz, speed, g)
    vx = dx / flight
    vy = (dy + 0.5 * g * flight * flight) / flight
    vz = dz / flight
    lm = math.sqrt(vx * vx + vy * vy + vz * vz)
    if lm > 0.001 then
        launch_dir = { x = vx / lm, y = vy / lm, z = vz / lm }
        vx, vy, vz = launch_dir.x * speed, launch_dir.y * speed, launch_dir.z * speed
    end

    local path = {}
    for i = 0, steps do
        local t = (i / steps) * flight
        path[#path + 1] = {
            x = ox + vx * t,
            y = oy + vy * t - 0.5 * g * t * t,
            z = oz + vz * t,
        }
    end
    path[#path + 1] = { x = hx, y = hy, z = hz }

    local far = math.max(dist * 2, 800)
    local aim_far = {
        x = ox + launch_dir.x * far,
        y = oy + launch_dir.y * far,
        z = oz + launch_dir.z * far,
    }

    return {
        path = path,
        aim = { x = hx, y = hy, z = hz },
        aim_far = aim_far,
        hit = { x = hx, y = hy, z = hz },
        launch_dir = launch_dir,
        flight = flight,
        speed = speed,
        gravity = g,
    }
end

function M.curve_for_weapon(origin, hit, weapon_name, steps)
    local stats = combat_stats_mod().get_effective_stats(weapon_name)
    return M.curve_to_hit(origin, hit, stats.speed, stats.gravity, steps)
end

-- Far aim point for silent MouseRaycast so muzzle→point LookVector == launch_dir.
function M.silent_aim_point(muzzle, hit, weapon_name)
    local curve = M.curve_for_weapon(muzzle, hit, weapon_name, 24)
    if not curve then return hit, nil end
    return curve.aim_far or hit, curve
end

return M
