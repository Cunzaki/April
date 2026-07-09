local ballistic = April.require("core.ballistic")
local combat_origin = April.require("game.combat_origin")
local math_util = April.require("core.math_util")
local weapons = April.require("game.weapons")

local M = {}

M.RAY_MODES = { "Direct", "Snap", "Deep", "Curve", "Arch" }

local BACK_STUDS = {
    Direct = 3.5,
    Snap = 1.75,
    Deep = 6.0,
    Curve = 3.5,
    Arch = 3.5,
}

local function unit(dx, dy, dz)
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return 0, 0, 0, 0 end
    local inv = 1 / len
    return dx * inv, dy * inv, dz * inv, len
end

local function copy_pos(p)
    return { x = p.x, y = p.y, z = p.z }
end

local function lerp(a, b, t)
    return {
        x = a.x + (b.x - a.x) * t,
        y = a.y + (b.y - a.y) * t,
        z = a.z + (b.z - a.z) * t,
    }
end

function M.mode_name(idx)
    return M.RAY_MODES[(idx or 0) + 1] or "Direct"
end

function M.back_studs(mode_name)
    return BACK_STUDS[mode_name] or BACK_STUDS.Direct
end

function M.predict_aim(target, head, camera, weapon_name)
    if not head then return nil end
    local muzzle = combat_origin.get_muzzle_origin() or camera
    if not muzzle then return copy_pos(head) end

    local vel = { x = 0, y = 0, z = 0 }
    if target and target.velocity and target.velocity.x ~= nil then
        vel = target.velocity
    end

    return ballistic.predict_for_weapon(muzzle, head, vel, weapon_name)
        or copy_pos(head)
end

function M.track_origin(camera, aim, mode_name)
    if not aim then return nil end
    if not camera then return copy_pos(aim) end

    local dx, dy, dz = aim.x - camera.x, aim.y - camera.y, aim.z - camera.z
    local ux, uy, uz, len = unit(dx, dy, dz)
    if len < 0.05 then return copy_pos(aim) end

    local back = M.back_studs(mode_name)
    if back >= len - 0.35 then
        back = math.max(0.75, len * 0.35)
    end

    return {
        x = aim.x - ux * back,
        y = aim.y - uy * back,
        z = aim.z - uz * back,
    }
end

local function sample_line(a, b, steps)
    steps = steps or 12
    local out = {}
    for i = 0, steps do
        out[#out + 1] = lerp(a, b, i / steps)
    end
    return out
end

local function sample_curve(from, to, steps)
    steps = steps or 16
    local mid = lerp(from, to, 0.5)
    local dx, dy, dz = to.x - from.x, to.y - from.y, to.z - from.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return sample_line(from, to, steps) end

    local bend = math.min(4.5, len * 0.12)
    local px, py, pz = -dz / len * bend, 0, dx / len * bend
    mid = { x = mid.x + px, y = mid.y + py, z = mid.z + pz }

    local out = {}
    for i = 0, steps do
        local t = i / steps
        local u = 1 - t
        out[#out + 1] = {
            x = u * u * from.x + 2 * u * t * mid.x + t * t * to.x,
            y = u * u * from.y + 2 * u * t * mid.y + t * t * to.y,
            z = u * u * from.z + 2 * u * t * mid.z + t * t * to.z,
        }
    end
    return out
end

local function sample_arch(muzzle, aim, weapon_name, steps)
    steps = steps or 20
    if not muzzle or not aim then return {} end

    local stats = April.require("game.combat_stats").get_effective_stats(weapon_name)
    local speed = math.max(stats.speed or 950, 1)
    local g = ballistic.gravity_accel(stats.gravity)

    local dx, dy, dz = aim.x - muzzle.x, aim.y - muzzle.y, aim.z - muzzle.z
    local horiz = math.sqrt(dx * dx + dz * dz)
    local dist = math_util.distance3(dx, dy, dz)
    local flight = dist / speed

    local vx = dx / flight
    local vy = (dy + 0.5 * g * flight * flight) / flight
    local vz = dz / flight

    local out = {}
    for i = 0, steps do
        local t = (i / steps) * flight
        out[#out + 1] = {
            x = muzzle.x + vx * t,
            y = muzzle.y + vy * t - 0.5 * g * t * t,
            z = muzzle.z + vz * t,
        }
    end
    out[#out + 1] = copy_pos(aim)
    return out
end

function M.build_path(mode_name, hook_origin, aim, weapon_name)
    if not hook_origin or not aim then return {} end

    local muzzle = combat_origin.get_muzzle_origin() or hook_origin
    local start = muzzle

    if mode_name == "Curve" then
        return sample_curve(start, aim, 18)
    end
    if mode_name == "Arch" then
        return sample_arch(start, aim, weapon_name, 22)
    end
    return sample_line(start, aim, 14)
end

return M
