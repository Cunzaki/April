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
    -- Fallen: Gravity field is a multiplier on workspace gravity (CreateProjectile).
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

-- Ballistic arc that still lands exactly on hitpart (no target velocity lead).
-- Returns sample points + initial launch direction for silent ray faking.
function M.curve_to_hit(origin, hit, bullet_speed, bullet_gravity, steps)
    if not origin or not hit then return nil end
    steps = steps or 18

    local ox, oy, oz = vec3(origin)
    local hx, hy, hz = vec3(hit)
    local dx, dy, dz = hx - ox, hy - oy, hz - oz
    local dist = math_util.distance3(dx, dy, dz)
    if dist < 0.05 then
        return {
            path = { { x = ox, y = oy, z = oz }, { x = hx, y = hy, z = hz } },
            aim = { x = hx, y = hy, z = hz },
            launch_dir = { x = 0, y = 1, z = 0 },
            flight = 0,
        }
    end

    local speed = math.max(bullet_speed or 950, 1)
    local g = M.gravity_accel(bullet_gravity)
    local flight = dist / speed
    if flight < 0.001 then flight = 0.001 end

    -- Launch velocity that reaches hit under gravity (classic ballistic aim-up).
    local vx = dx / flight
    local vy = (dy + 0.5 * g * flight * flight) / flight
    local vz = dz / flight

    local path = {}
    for i = 0, steps do
        local t = (i / steps) * flight
        path[#path + 1] = {
            x = ox + vx * t,
            y = oy + vy * t - 0.5 * g * t * t,
            z = oz + vz * t,
        }
    end
    -- Guarantee exact endpoint on hitpart
    path[#path + 1] = { x = hx, y = hy, z = hz }

    local lm = math.sqrt(vx * vx + vy * vy + vz * vz)
    local launch_dir = lm > 0.001
        and { x = vx / lm, y = vy / lm, z = vz / lm }
        or { x = dx / dist, y = dy / dist, z = dz / dist }

    return {
        path = path,
        aim = { x = hx, y = hy, z = hz },
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

return M
