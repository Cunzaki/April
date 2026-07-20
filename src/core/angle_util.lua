-- Shared yaw / flat-direction helpers for movement features.

local env = April.require("core.env")

local M = {}

function M.normalize_yaw(y)
    while y > math.pi do y = y - math.pi * 2 end
    while y < -math.pi do y = y + math.pi * 2 end
    return y
end

function M.yaw_delta(from_yaw, to_yaw)
    return M.normalize_yaw((to_yaw or 0) - (from_yaw or 0))
end

function M.yaw_from_vector(lx, lz)
    if not lx and not lz then return 0 end
    lx, lz = lx or 0, lz or 0
    if math.abs(lx) < 1e-5 and math.abs(lz) < 1e-5 then return 0 end
    return math.atan2(lx, lz)
end

function M.flat_forward(yaw)
    return math.sin(yaw or 0), math.cos(yaw or 0)
end

function M.camera_yaw()
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local deg = a.Y or a.y
            if deg then return math.rad(deg) end
        end
    end
    if utility and utility.get_camera_angles then
        local ok, _, yaw = pcall(utility.get_camera_angles)
        if ok and yaw then return math.rad(yaw) end
    end
    if camera and camera.get_look_vector then
        local ok, lv = pcall(camera.get_look_vector)
        if ok and lv then
            return M.yaw_from_vector(lv.x or lv.X, lv.z or lv.Z)
        end
    end
    return 0
end

function M.normalize_pitch(p)
    local lim = math.rad(89)
    if p > lim then return lim end
    if p < -lim then return -lim end
    return p or 0
end

function M.camera_pitch()
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local deg = a.X or a.x
            if deg then return math.rad(deg) end
        end
    end
    if utility and utility.get_camera_angles then
        local ok, pitch = pcall(utility.get_camera_angles)
        if ok and pitch then return math.rad(pitch) end
    end
    if camera and camera.get_look_vector then
        local ok, lv = pcall(camera.get_look_vector)
        if ok and lv then
            local ly = lv.y or lv.Y or 0
            return M.normalize_pitch(math.asin(math.max(-1, math.min(1, -ly))))
        end
    end
    return 0
end

function M.body_pitch(lp, root)
    if lp and lp.LookVector then
        local lv = lp.LookVector
        local ly = lv.y or lv.Y
        if ly then
            return M.normalize_pitch(math.asin(math.max(-1, math.min(1, -ly))))
        end
    end
    if root then
        local lv = env.safe_call(function()
            local cf = root.CFrame or root.cframe
            return cf and (cf.LookVector or cf.lookVector)
        end)
        if lv then
            local ly = lv.Y or lv.y or 0
            return M.normalize_pitch(math.asin(math.max(-1, math.min(1, -ly))))
        end
    end
    return M.camera_pitch()
end

function M.body_yaw(lp, root)
    if lp and lp.LookVector then
        local lv = lp.LookVector
        local yaw = M.yaw_from_vector(lv.x or lv.X, lv.z or lv.Z)
        if yaw then return yaw end
    end
    if root then
        local lv = env.safe_call(function()
            local cf = root.CFrame or root.cframe
            return cf and (cf.LookVector or cf.lookVector)
        end)
        if lv then
            return M.yaw_from_vector(lv.X or lv.x, lv.Z or lv.z)
        end
    end
    return M.camera_yaw()
end

function M.point_ahead(x, y, z, yaw, dist, lift)
    dist = dist or 4
    lift = lift or 0
    local fx, fz = M.flat_forward(yaw)
    return x + fx * dist, (y or 0) + lift, z + fz * dist
end

return M
