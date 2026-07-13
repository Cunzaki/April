local combat_origin = April.require("game.combat_origin")

local M = {}

local RAY_LEN = 1024
local GRID_STEP = 0.28

-- Direct TP: spawn ray origin on / around hitpart center, aim into center.
M.METHODS = {
    "Center",
    "Random Ring",
    "Random Sphere",
    "Offset Grid",
    "Camera Face",
    "Away From Cam",
    "Shuffle Valid",
    "Dense Shuffle",
}

local BONE_CENTER_Y = {
    Head = -0.62,
    UpperTorso = 0,
    LowerTorso = 0,
    HumanoidRootPart = 0,
    LeftUpperArm = 0,
    RightUpperArm = 0,
    LeftUpperLeg = -0.15,
    RightUpperLeg = -0.15,
}

local GRID_OFFS = {}
do
    for y = -0.56, 0.56, GRID_STEP do
        for x = -0.56, 0.56, GRID_STEP do
            for z = -0.56, 0.56, GRID_STEP do
                GRID_OFFS[#GRID_OFFS + 1] = { x = x, y = y, z = z }
            end
        end
    end
end

local scan = { key = nil, idx = 0 }

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

local function add_off(base, off)
    return {
        x = base.x + (off.x or 0),
        y = base.y + (off.y or 0),
        z = base.z + (off.z or 0),
    }
end

function M.target_center(hitpart, bone)
    if not hitpart then return nil end
    local c = copy_pos(hitpart)
    local yoff = BONE_CENTER_Y[bone or "Head"] or -0.35
    c.y = c.y + yoff
    return c
end

local function toward_camera(origin, camera)
    if not camera then return 0, 0, 1, 1 end
    return unit(camera.x - origin.x, camera.y - origin.y, camera.z - origin.z)
end

local function aim_through(center, from, camera)
    local ux, uy, uz, len = unit(center.x - from.x, center.y - from.y, center.z - from.z)
    if len > 0.02 then
        return {
            x = center.x + ux * 0.08,
            y = center.y + uy * 0.08,
            z = center.z + uz * 0.08,
        }
    end
    local lx, ly, lz = toward_camera(center, camera)
    return {
        x = center.x + lx * 0.08,
        y = center.y + ly * 0.08,
        z = center.z + lz * 0.08,
    }
end

local function los_clear(from, to)
    if not from or not to then return false end
    if raycast and raycast.is_visible then
        return raycast.is_visible(from.x, from.y, from.z, to.x, to.y, to.z) == true
    end
    return true
end

local function scan_key(center, method_idx)
    return string.format("%d|%.2f,%.2f,%.2f", method_idx, center.x, center.y, center.z)
end

local function next_grid_offset(center, method_idx)
    local key = scan_key(center, method_idx)
    if scan.key ~= key then
        scan.key = key
        scan.idx = 1
    end
    local off = GRID_OFFS[scan.idx] or GRID_OFFS[1]
    scan.idx = scan.idx + 1
    if scan.idx > #GRID_OFFS then scan.idx = 1 end
    return off
end

local function rand_unit()
    local u = math.random() * 2 - 1
    local v = math.random() * 2 - 1
    local s = u * u + v * v
    while s >= 1 or s < 0.0001 do
        u = math.random() * 2 - 1
        v = math.random() * 2 - 1
        s = u * u + v * v
    end
    local w = math.sqrt((1 - s) / s)
    return u * w, v * w, math.sqrt(1 - s)
end

local function origin_center(_center, _camera)
    return copy_pos(_center)
end

local function origin_random_ring(center, _camera)
    local ang = math.random() * math.pi * 2
    local r = 0.18 + math.random() * 0.55
    return {
        x = center.x + math.cos(ang) * r,
        y = center.y + (math.random() - 0.5) * 0.35,
        z = center.z + math.sin(ang) * r,
    }
end

local function origin_random_sphere(center, _camera)
    local ux, uy, uz = rand_unit()
    local r = 0.12 + math.random() * 0.65
    return {
        x = center.x + ux * r,
        y = center.y + uy * r,
        z = center.z + uz * r,
    }
end

local function origin_offset_grid(center, camera, method_idx)
    return add_off(center, next_grid_offset(center, method_idx))
end

local function origin_camera_face(center, camera)
    local lx, ly, lz = toward_camera(center, camera)
    local d = 0.22 + math.random() * 0.75
    return {
        x = center.x + lx * d,
        y = center.y + ly * d,
        z = center.z + lz * d,
    }
end

local function origin_away_from_cam(center, camera)
    local lx, ly, lz = toward_camera(center, camera)
    local d = 0.22 + math.random() * 0.75
    return {
        x = center.x - lx * d,
        y = center.y - ly * d + (math.random() - 0.5) * 0.25,
        z = center.z - lz * d,
    }
end

local function origin_shuffle_valid(center, camera, tries)
    tries = tries or 14
    local best = copy_pos(center)
    for _ = 1, tries do
        local cand = origin_random_sphere(center, camera)
        if los_clear(cand, center) then
            return cand
        end
    end
    return best
end

local ORIGIN_FN = {
    origin_center,
    origin_random_ring,
    origin_random_sphere,
    origin_offset_grid,
    origin_camera_face,
    origin_away_from_cam,
    origin_shuffle_valid,
    function(c, cam) return origin_shuffle_valid(c, cam, 28) end,
}

function M.hitpart_aim(hit, bone)
    return M.target_center(hit, bone)
end

function M.resolve(opts)
    opts = opts or {}
    local camera = opts.camera or combat_origin.get_camera_origin()
    local hitpart = opts.hitpart
    if not hitpart or not camera then return nil end

    local method_idx = math.floor(tonumber(opts.method) or 0)
    if method_idx < 0 then method_idx = 0 end
    if method_idx >= #M.METHODS then method_idx = 0 end

    local center = M.target_center(hitpart, opts.bone)
    if not center then return nil end

    local muzzle = opts.muzzle or combat_origin.get_muzzle_origin() or camera
    local pick = ORIGIN_FN[method_idx + 1] or origin_center
    local origin = pick(center, camera, method_idx)
    if not origin then return nil end

    local aim = aim_through(center, origin, camera)

    return {
        origin = origin,
        aim = aim,
        hitpart = center,
        visual = false,
        method = M.METHODS[method_idx + 1],
        tp_path = M.build_path(origin, center, muzzle),
    }
end

function M.build_path(tp_origin, center, muzzle)
    if not tp_origin or not center then return {} end
    local out = {}
    if muzzle then out[#out + 1] = copy_pos(muzzle) end
    out[#out + 1] = copy_pos(tp_origin)
    out[#out + 1] = copy_pos(center)
    return out
end

return M
