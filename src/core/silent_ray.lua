
local M = {}

local hook_ready = false
local tracking = false

M._last_origin = nil
M._last_target = nil
M._last_ok = false

local function unpack_pos(v)
    if not v then return nil end
    if v.x ~= nil then return v.x, v.y, v.z end
    if v.X ~= nil then return v.X, v.Y, v.Z end
    return nil
end

-- Docs: Set/TrackSilentTarget accept Vector3 only. Prefer Vector3.New.
local function make_vec3(x, y, z)
    if Vector3 then
        local ctor = Vector3.New or Vector3.new
        if type(ctor) == "function" then
            local ok, v = pcall(ctor, x, y, z)
            if ok and v ~= nil then return v end
        end
    end
    return { x = x, y = y, z = z }
end

local function ray_fn(snake, pascal)
    if not raycast then return nil end
    pcall(function()
        April.require("core.api_aliases").apply()
    end)
    local fn = raycast[snake] or raycast[pascal]
    if type(fn) == "function" then return fn end
    return nil
end

local function cam_fn(snake, pascal)
    if not camera then return nil end
    pcall(function()
        April.require("core.api_aliases").apply()
    end)
    local fn = camera[snake] or camera[pascal]
    if type(fn) == "function" then return fn end
    return nil
end

function M.available()
    if not raycast then return false end
    local track = ray_fn("track_silent_target", "TrackSilentTarget")
    local set = ray_fn("set_silent_target", "SetSilentTarget")
    local stop = ray_fn("stop_silent_tracking", "StopSilentTracking")
    return (track or set) and stop ~= nil
end

function M.ensure_hook()
    if not M.available() then return false end
    local is_active = ray_fn("is_silent_hook_active", "IsSilentHookActive")
    if is_active then
        local ok_status, active = pcall(is_active)
        if ok_status and active == true then
            hook_ready = true
            return true
        end
    elseif hook_ready then
        return true
    end

    local enable = ray_fn("enable_silent_hook", "EnableSilentHook")
    if not enable then
        hook_ready = true
        return true
    end

    local ok_call, ok = pcall(enable)
    hook_ready = ok_call and ok == true
    return hook_ready
end

function M.is_tracking()
    return tracking
end

function M.last_ok()
    return M._last_ok
end

function M.get_camera_origin()
    local get_pos = cam_fn("get_position", "GetPosition")
    if not get_pos then return nil end
    local ok, pos = pcall(get_pos)
    if not ok or not pos then return nil end
    local x, y, z = unpack_pos(pos)
    if not x then return nil end
    return { x = x, y = y, z = z }
end

function M.stop()
    M._last_origin = nil
    M._last_target = nil

    local was_active = tracking or M._last_ok
    M._last_ok = false
    tracking = false

    if not was_active then return end
    if not M.available() then return end
    local stop = ray_fn("stop_silent_tracking", "StopSilentTracking")
    if stop then pcall(stop) end
    local clear = ray_fn("clear_silent_target", "ClearSilentTarget")
    if clear then pcall(clear) end
end

function M.last_segment()
    return M._last_origin, M._last_target
end

local function build_dir(origin, aim_point)
    local ox, oy, oz = unpack_pos(origin)
    local ax, ay, az = unpack_pos(aim_point)
    if not ox or not ax then
        return nil, nil
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
        dir = make_vec3(dx, dy, dz)
    end

    return make_vec3(ox, oy, oz), dir
end

-- Docs primary path: SetSilentTarget every OnFrame with Vector3 origin/dir.
function M.set_target(origin, aim_point, hitpart)
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

    local set_target = ray_fn("set_silent_target", "SetSilentTarget")
    if not set_target then
        return false
    end

    local origin_v, dir = build_dir(origin, aim_point)
    if not origin_v or not dir then
        return false
    end

    local ox, oy, oz = unpack_pos(origin)
    local ax, ay, az = unpack_pos(aim_point)
    M._last_origin = { x = ox, y = oy, z = oz }
    if hitpart and (hitpart.x or hitpart.X) then
        local hx, hy, hz = unpack_pos(hitpart)
        M._last_target = { x = hx, y = hy, z = hz }
    else
        M._last_target = { x = ax, y = ay, z = az }
    end

    local ok_call, ok = pcall(set_target, origin_v, dir)
    ok = ok_call and (ok == true or ok == nil)
    M._last_ok = ok
    tracking = ok
    return ok
end

-- Docs secondary path: TrackSilentTarget while key held.
function M.track(origin, aim_point, shoot_vk, hitpart)
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

    local track_target = ray_fn("track_silent_target", "TrackSilentTarget")
    if not track_target then
        return M.set_target(origin, aim_point, hitpart)
    end

    local origin_v, dir = build_dir(origin, aim_point)
    if not origin_v or not dir then
        return false
    end

    local ox, oy, oz = unpack_pos(origin)
    local ax, ay, az = unpack_pos(aim_point)
    local key = shoot_vk or 0x01

    M._last_origin = { x = ox, y = oy, z = oz }
    if hitpart and (hitpart.x or hitpart.X) then
        local hx, hy, hz = unpack_pos(hitpart)
        M._last_target = { x = hx, y = hy, z = hz }
    else
        M._last_target = { x = ax, y = ay, z = az }
    end

    local ok_call, ok = pcall(track_target, origin_v, dir, key)
    ok = ok_call and ok == true
    M._last_ok = ok
    tracking = ok
    return ok
end

return M
