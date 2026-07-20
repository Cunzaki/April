-- Workspace camera helpers for third-person and other view overrides.

local env = April.require("core.env")
local angle_util = April.require("core.angle_util")

local M = {}

function M.get_workspace()
    return env.get_workspace()
end

function M.get_current()
    local ws = M.get_workspace()
    if not ws then return nil end
    return env.safe_call(function()
        return ws.CurrentCamera or ws.currentCamera
            or (ws.find_first_child and ws:find_first_child("CurrentCamera"))
            or (ws.FindFirstChild and ws:FindFirstChild("CurrentCamera"))
    end)
end

function M.vec3(x, y, z)
    if Vector3 and Vector3.new then return Vector3.new(x, y, z) end
    if Vector3 and Vector3.New then return Vector3.New(x, y, z) end
    return { x = x, y = y, z = z, X = x, Y = y, Z = z }
end

function M.read_vector3(v)
    if not v then return nil end
    return v.x or v.X, v.y or v.Y, v.z or v.Z
end

function M.normalize3(x, y, z)
    local m = math.sqrt(x * x + y * y + z * z)
    if m < 1e-6 then return 0, 0, 1 end
    return x / m, y / m, z / m
end

function M.cross(ax, ay, az, bx, by, bz)
    return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

function M.read_cframe(cam)
    if not cam then return nil end
    local cf = env.safe_call(function() return cam.CFrame or cam.cframe end)
    if not cf then return nil end

    local px, py, pz = M.read_vector3(cf.Position or cf.position)
    if not px then return nil end

    local look = cf.LookVector or cf.lookVector
    local right = cf.RightVector or cf.rightVector
    local up = cf.UpVector or cf.upVector

    if look then
        local lx, ly, lz = M.read_vector3(look)
        lx, ly, lz = M.normalize3(lx or 0, ly or 0, lz or 1)
        local rx, ry, rz, ux, uy, uz
        if right then
            rx, ry, rz = M.read_vector3(right)
        else
            rx, ry, rz = M.cross(lx, ly, lz, 0, 1, 0)
            rx, ry, rz = M.normalize3(rx, ry, rz)
        end
        if up then
            ux, uy, uz = M.read_vector3(up)
        else
            ux, uy, uz = M.cross(rx, ry, rz, lx, ly, lz)
        end
        return {
            px = px, py = py, pz = pz,
            lx = lx, ly = ly, lz = lz,
            rx = rx, ry = ry, rz = rz,
            ux = ux, uy = uy, uz = uz,
        }
    end

    return { px = px, py = py, pz = pz }
end

function M.read_from_api()
    if not camera or not camera.get_position or not camera.get_look_vector then return nil end
    local okp, pos = pcall(camera.get_position)
    local okl, look = pcall(camera.get_look_vector)
    if not okp or not pos or not okl or not look then return nil end
    local px, py, pz = M.read_vector3(pos)
    local lx, ly, lz = M.normalize3(M.read_vector3(look))
    local rx, ry, rz = M.cross(lx, ly, lz, 0, 1, 0)
    rx, ry, rz = M.normalize3(rx, ry, rz)
    local ux, uy, uz = M.cross(rx, ry, rz, lx, ly, lz)
    return {
        px = px, py = py, pz = pz,
        lx = lx, ly = ly, lz = lz,
        rx = rx, ry = ry, rz = rz,
        ux = ux, uy = uy, uz = uz,
    }
end

function M.cframe_look_at(px, py, pz, lx, ly, lz)
    lx, ly, lz = M.normalize3(lx, ly, lz)
    if CFrame and CFrame.lookAt then
        return CFrame.lookAt(M.vec3(px, py, pz), M.vec3(px + lx, py + ly, pz + lz))
    end
    if CFrame and CFrame.new and CFrame.Angles then
        local yaw = math.atan2(lx, lz)
        local pitch = math.asin(math.max(-1, math.min(1, -ly)))
        return CFrame.new(px, py, pz) * CFrame.Angles(pitch, yaw, 0)
    end
    return nil
end

function M.write_cframe(cam, cf)
    if not cam or not cf then return false end
    return env.safe_call(function()
        cam.CFrame = cf
        return true
    end) == true
end

function M.set_look(cam, px, py, pz, lx, ly, lz)
    local cf = M.cframe_look_at(px, py, pz, lx, ly, lz)
    if cf then return M.write_cframe(cam, cf) end
    return false
end

function M.lerp(a, b, t)
    return a + (b - a) * t
end

function M.lerp_pos(a, b, t)
    return {
        x = M.lerp(a.x, b.x, t),
        y = M.lerp(a.y, b.y, t),
        z = M.lerp(a.z, b.z, t),
    }
end

function M.camera_type_value(name)
    if not Enum or not Enum.CameraType then return nil end
    local ct = Enum.CameraType
    if name == "Scriptable" then return ct.Scriptable or ct.scriptable end
    if name == "Custom" then return ct.Custom or ct.custom end
    return ct.Custom or ct.custom
end

function M.read_camera_type(cam)
    if not cam then return nil end
    local t = env.safe_call(function() return cam.CameraType or cam.camera_type end)
    return t
end

function M.look_from_angles(yaw, pitch)
    pitch = pitch or 0
    local cp = math.cos(pitch)
    local lx = cp * math.sin(yaw)
    local ly = -math.sin(pitch)
    local lz = cp * math.cos(yaw)
    local rx, ry, rz = M.cross(lx, ly, lz, 0, 1, 0)
    rx, ry, rz = M.normalize3(rx, ry, rz)
    local ux, uy, uz = M.cross(rx, ry, rz, lx, ly, lz)
    return lx, ly, lz, rx, ry, rz, ux, uy, uz
end

function M.read_angles_from_api()
    if utility and utility.get_camera_angles then
        local ok, pitch, yaw = pcall(utility.get_camera_angles)
        if ok and yaw then
            return math.rad(yaw), math.rad(pitch or 0)
        end
    end
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local yaw = a.Y or a.y
            local pitch = a.X or a.x
            if yaw then
                return math.rad(yaw), math.rad(pitch or 0)
            end
        end
    end
    if camera and camera.get_look_vector then
        local ok, look = pcall(camera.get_look_vector)
        if ok and look then
            local lx, ly, lz = M.normalize3(M.read_vector3(look))
            local yaw = math.atan2(lx, lz)
            local pitch = math.asin(math.max(-1, math.min(1, -ly)))
            return yaw, pitch
        end
    end
    return nil, nil
end

function M.read_look_from_api()
    local yaw, pitch = M.read_angles_from_api()
    if yaw then
        return M.look_from_angles(yaw, pitch)
    end
    if camera and camera.get_look_vector then
        local ok, look = pcall(camera.get_look_vector)
        if ok and look then
            local lx, ly, lz = M.normalize3(M.read_vector3(look))
            local rx, ry, rz = M.cross(lx, ly, lz, 0, 1, 0)
            rx, ry, rz = M.normalize3(rx, ry, rz)
            return lx, ly, lz, rx, ry, rz
        end
    end
    return nil, nil, nil
end

function M.set_camera_type(cam, value)
    if not cam or value == nil then return false end
    return env.safe_call(function()
        cam.CameraType = value
        return true
    end) == true
end

return M
