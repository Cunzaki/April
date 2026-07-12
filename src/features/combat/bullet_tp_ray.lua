local combat_origin = April.require("game.combat_origin")

local M = {}

local EYE_Y = 2.5
local BACK_MIN = 0.35
local BACK_MAX = 6
local BACK_STEP = 0.2
local RING_STEPS = 12
local RING_FRACTIONS = { 0.15, 0.35, 0.55 }

local function copy_pos(p)
    if not p then return nil end
    return { x = p.x, y = p.y, z = p.z }
end

local function unit(dx, dy, dz)
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return 0, 0, 0, 0 end
    local inv = 1 / len
    return dx * inv, dy * inv, dz * inv, len
end

local function eye_pos(base)
    return { x = base.x, y = base.y + EYE_Y, z = base.z }
end

local function los_visible(from, to)
    if not from or not to then return false end
    if raycast and raycast.is_visible then
        return raycast.is_visible(from.x, from.y, from.z, to.x, to.y, to.z) == true
    end
    return true
end

local function score_candidate(origin, aim, camera, back)
    if not los_visible(origin, aim) then return nil end
    local dx = origin.x - (camera and camera.x or origin.x)
    local dy = origin.y - (camera and camera.y or origin.y)
    local dz = origin.z - (camera and camera.z or origin.z)
    local cam_dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    -- ponytail: greedy score — prefer shorter back-offset + nearer camera (most natural valid)
    return 1000 - back * 40 - cam_dist * 0.15
end

function M.hitpart_aim(head)
    return copy_pos(head)
end

function M.predict_aim(_target, head, _camera, _weapon_name)
    return M.hitpart_aim(head)
end

-- Scan LOS back-offsets + small rings for the most likely server-valid origin.
function M.find_best_origin(camera, aim, muzzle)
    if not aim then return nil end
    camera = camera or aim
    muzzle = muzzle or combat_origin.get_muzzle_origin() or camera

    local dx, dy, dz = aim.x - camera.x, aim.y - camera.y, aim.z - camera.z
    local ux, uy, uz, len = unit(dx, dy, dz)
    if len < 0.05 then return copy_pos(aim) end

    local best, best_score = nil, -math.huge
    local function try(base, back)
        local cand = eye_pos(base)
        local sc = score_candidate(cand, aim, camera, back or 0)
        if sc and sc > best_score then
            best, best_score = { x = base.x, y = base.y, z = base.z }, sc
        end
    end

    local back_limit = math.min(BACK_MAX, math.max(BACK_MIN, len * 0.45))
    local back = BACK_MIN
    while back <= back_limit + 0.001 do
        try({
            x = aim.x - ux * back,
            y = aim.y - uy * back,
            z = aim.z - uz * back,
        }, back)
        back = back + BACK_STEP
    end

    for _, frac in ipairs(RING_FRACTIONS) do
        local ring_r = math.min(1.2, len * frac * 0.08)
        local center_back = math.min(back_limit * 0.5, len * frac * 0.35)
        local cx = aim.x - ux * center_back
        local cy = aim.y - uy * center_back
        local cz = aim.z - uz * center_back
        for i = 0, RING_STEPS - 1 do
            local ang = (i / RING_STEPS) * math.pi * 2
            local px = -uz
            local pz = ux
            local ring_x = cx + math.cos(ang) * ring_r * px
            local ring_z = cz + math.sin(ang) * ring_r * pz
            try({ x = ring_x, y = cy, z = ring_z }, center_back)
        end
    end

    if best then
        return eye_pos(best)
    end

    -- Fallback: muzzle or camera eye along LOS
    if muzzle and los_visible(eye_pos(muzzle), aim) then
        return eye_pos(muzzle)
    end
    return eye_pos({
        x = aim.x - ux * math.min(1.5, len * 0.12),
        y = aim.y - uy * math.min(1.5, len * 0.12),
        z = aim.z - uz * math.min(1.5, len * 0.12),
    })
end

function M.track_origin(camera, aim, _mode_name)
    local muzzle = combat_origin.get_muzzle_origin()
    return M.find_best_origin(camera, aim, muzzle)
end

function M.build_path(hook_origin, aim, _weapon_name)
    if not hook_origin or not aim then return {} end
    local muzzle = combat_origin.get_muzzle_origin() or hook_origin
    local steps = 14
    local out = {}
    for i = 0, steps do
        local t = i / steps
        out[#out + 1] = {
            x = muzzle.x + (aim.x - muzzle.x) * t,
            y = muzzle.y + (aim.y - muzzle.y) * t,
            z = muzzle.z + (aim.z - muzzle.z) * t,
        }
    end
    return out
end

return M
