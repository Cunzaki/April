--[[ Silent raycast hook — matches Fallen MouseRaycast (UnitRay * 1024). ]]

local M = {}

local hook_ready = false
local tracking = false

-- Fallen RaycastUtil:MouseRaycast uses UnitRay.Direction * (p15 or 1024)
local MOUSE_RAY_LEN = 1024

M._last_origin = nil
M._last_target = nil
M._last_ok = false

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
    M._last_ok = false
    tracking = false
    if not M.available() then return end
    pcall(raycast.stop_silent_tracking)
    if raycast.clear_silent_target then
        pcall(raycast.clear_silent_target)
    end
end

function M.last_segment()
    return M._last_origin, M._last_target
end

--[[
    Fallen: MouseRaycast -> hit, muzzle fires toward hit.
    Silent hook replaces engine ray — peek manip uses peek eye as track origin.
]]
function M.track(origin, aim_point, shoot_vk)
    M._last_ok = false

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
    if dist < 0.001 then
        return false
    end

    local inv = 1 / dist
    local dir = make_vec3(dx * inv * MOUSE_RAY_LEN, dy * inv * MOUSE_RAY_LEN, dz * inv * MOUSE_RAY_LEN)
    local origin_v = make_vec3(ox, oy, oz)
    local key = shoot_vk or 0x01

    M._last_origin = { x = ox, y = oy, z = oz }
    M._last_target = { x = ax, y = ay, z = az }

    local ok = raycast.track_silent_target(origin_v, dir, key) == true
    M._last_ok = ok
    tracking = ok
    return ok
end

return M
