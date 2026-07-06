--[[ Silent raycast hook helper — augments Vector's built-in silent aim with custom direction ]]

local M = {}

local hook_ready = false
M._last_origin = nil
M._last_target = nil

local function vec3(x, y, z)
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
    if not raycast.enable_silent_hook then
        hook_ready = true
        return true
    end
    if hook_ready or (raycast.is_silent_hook_active and raycast.is_silent_hook_active()) then
        hook_ready = true
        return true
    end
    local ok = raycast.enable_silent_hook()
    hook_ready = ok == true
    return hook_ready
end

function M.stop()
    M._last_origin = nil
    M._last_target = nil
    if not M.available() then return end
    pcall(raycast.stop_silent_tracking)
    if raycast.clear_silent_target then
        pcall(raycast.clear_silent_target)
    end
end

function M.last_segment()
    return M._last_origin, M._last_target
end

--[[ Direction length matters — pass full offset to predicted target. ]]
function M.track(origin, target, shoot_vk)
    if not origin or not target then
        M.stop()
        return false
    end
    if not M.ensure_hook() then return false end

    local ox = origin.x or origin.X or 0
    local oy = origin.y or origin.Y or 0
    local oz = origin.z or origin.Z or 0
    local tx = target.x or target.X or 0
    local ty = target.y or target.Y or 0
    local tz = target.z or target.Z or 0

    M._last_origin = { x = ox, y = oy, z = oz }
    M._last_target = { x = tx, y = ty, z = tz }

    local dir = vec3(tx - ox, ty - oy, tz - oz)
    local origin_v = vec3(ox, oy, oz)
    local key = shoot_vk or 0x01

    return raycast.track_silent_target(origin_v, dir, key) == true
end

return M
