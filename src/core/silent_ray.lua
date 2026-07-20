local ballistic = April.require("core.ballistic")

local M = {}

local hook_ready = false
local tracking = false

local MOUSE_RAY_LEN = 1024

M._last_origin = nil
M._last_target = nil
M._last_ok = false
M._last_curve = nil

local function unpack_pos(v)
    if not v then return nil end
    if v.x ~= nil then return v.x, v.y, v.z end
    if v.X ~= nil then return v.X, v.Y, v.Z end
    return nil
end

local function make_vec3(x, y, z)
    if Vector3 and Vector3.new then
        return Vector3.new(x, y, z)
    end
    return { x = x, y = y, z = z }
end

function M.available()
    return raycast
        and raycast.track_silent_target
        and raycast.stop_silent_tracking
end

function M.ensure_hook()
    if not M.available() then return false end
    if hook_ready or (raycast.is_silent_hook_active and raycast.is_silent_hook_active()) then
        hook_ready = true
        return true
    end
    if not raycast.enable_silent_hook then
        hook_ready = true
        return true
    end
    local ok = raycast.enable_silent_hook()
    hook_ready = ok == true
    return hook_ready
end

function M.is_tracking()
    return tracking
end

function M.last_ok()
    return M._last_ok
end

function M.get_camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if not ok or not pos then return nil end
    local x, y, z = unpack_pos(pos)
    if not x then return nil end
    return { x = x, y = y, z = z }
end

function M.stop()
    M._last_origin = nil
    M._last_target = nil
    M._last_curve = nil

    local was_active = tracking or M._last_ok
    M._last_ok = false
    tracking = false

    -- Avoid spamming native stop while already idle (hitchance miss / no target).
    if not was_active then return end
    if not M.available() then return end
    pcall(raycast.stop_silent_tracking)
    if raycast.clear_silent_target then
        pcall(raycast.clear_silent_target)
    end
end

function M.last_segment()
    return M._last_origin, M._last_target
end

function M.last_curve()
    return M._last_curve
end

-- Direct ray to aim (legacy / bullet TP).
function M.track(origin, aim_point, shoot_vk, hitpart)
    M._last_ok = false
    M._last_curve = nil

    if not aim_point then
        return false
    end

    origin = origin or M.get_camera_origin()
    if not origin then
        return false
    end

    if not M.ensure_hook() then
        return false
    end

    local ox, oy, oz = unpack_pos(origin)
    local ax, ay, az = unpack_pos(aim_point)
    if not ox or not ax then
        return false
    end

    local dx, dy, dz = ax - ox, ay - oy, az - oz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local dir

    if dist < 0.001 then
        local cam = M.get_camera_origin()
        if cam then
            dx, dy, dz = cam.x - ox, cam.y - oy, cam.z - oz
            dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        end
        if not dist or dist < 0.001 then
            dir = make_vec3(0, 1, 0)
        else
            dir = make_vec3(dx, dy, dz)
        end
    else
        -- API example: direction = target - origin (not pre-normalized).
        dir = make_vec3(dx, dy, dz)
    end
    local origin_v = make_vec3(ox, oy, oz)
    local key = shoot_vk or 0x01

    M._last_origin = { x = ox, y = oy, z = oz }
    if hitpart and hitpart.x then
        M._last_target = { x = hitpart.x, y = hitpart.y, z = hitpart.z }
    else
        M._last_target = { x = ax, y = ay, z = az }
    end

    local ok_call, ok = pcall(raycast.track_silent_target, origin_v, dir, key)
    ok = ok_call and ok == true
    M._last_ok = ok
    tracking = ok
    return ok
end

-- Silent track straight to hitpart (API projectiles are near-hitscan speed).
-- Still builds a muzzle->hitpart drop curve for visuals / target line.
function M.track_curve(origin, aim_point, weapon_name, shoot_vk, hitpart)
    origin = origin or M.get_camera_origin()
    if not origin or not aim_point then
        M._last_ok = false
        M._last_curve = nil
        return false
    end

    local hit = hitpart or aim_point
    local curve = ballistic.curve_for_weapon(origin, hit, weapon_name, 24)

    -- Never aim above the hitpart - direction is always origin -> selected hitpart.
    local ok = M.track(origin, hit, shoot_vk, hit)
    M._last_curve = curve
    M._last_target = { x = hit.x, y = hit.y, z = hit.z }
    return ok
end

return M
