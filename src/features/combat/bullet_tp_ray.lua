local ballistic = April.require("core.ballistic")
local combat_origin = April.require("game.combat_origin")
local math_util = April.require("core.math_util")

local M = {}

-- Prefer Direct/Snap — most consistent valids. Deep/Curve/Arch kept for visuals.
M.RAY_MODES = { "Direct", "Snap", "Deep", "Curve", "Arch" }

-- Tighter back offsets for Direct/Snap = hook closer to target = more valids.
local BACK_STUDS = {
    Direct = 2.25,
    Snap = 1.15,
    Deep = 5.5,
    Curve = 2.75,
    Arch = 2.75,
}

local function unit(dx, dy, dz)
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return 0, 0, 0, 0 end
    local inv = 1 / len
    return dx * inv, dy * inv, dz * inv, len
end

local function copy_pos(p)
    if not p then return nil end
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

-- Exact hitpart — no velocity / drop lead (silent is instant).
function M.hitpart_aim(head)
    return copy_pos(head)
end

-- Kept for callers; intentionally ignores velocity (instant hook).
function M.predict_aim(_target, head, _camera, _weapon_name)
    return M.hitpart_aim(head)
end

function M.track_origin(camera, aim, mode_name)
    if not aim then return nil end
    if not camera then return copy_pos(aim) end

    local dx, dy, dz = aim.x - camera.x, aim.y - camera.y, aim.z - camera.z
    local ux, uy, uz, len = unit(dx, dy, dz)
    if len < 0.05 then return copy_pos(aim) end

    local back = M.back_studs(mode_name)

    -- Snap: pull slightly toward camera along LOS for cleaner server ray.
    if mode_name == "Snap" then
        back = math.min(back, math.max(0.55, len * 0.08))
    elseif mode_name == "Direct" then
        back = math.min(back, math.max(0.85, len * 0.12))
    end

    if back >= len - 0.35 then
        back = math.max(0.55, len * 0.28)
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
    local curve = ballistic.curve_for_weapon(muzzle, aim, weapon_name, steps or 20)
    if curve and curve.path then return curve.path end
    return sample_line(muzzle, aim, steps or 14)
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
