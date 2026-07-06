--[[ Vector fly helpers — position-only writes (API: BasePart.CFrame is position only). ]]

local env = April.require("core.env")

local M = {}

local BASE_PARTS = {
    Part = true, MeshPart = true, UnionOperation = true,
    WedgePart = true, CornerWedgePart = true, TrussPart = true,
}

function M.delta_time()
    if utility and utility.get_delta_time then
        local dt = utility.get_delta_time()
        if dt and dt > 0 and dt <= 0.1 then return dt end
    end
    return 0.016
end

function M.key_down(code)
    return input and input.is_key_down and input.is_key_down(code)
end

function M.read_pos(inst)
    if not inst then return nil end
    local pos = inst.Position or inst.position
    if not pos then return nil end
    return {
        x = pos.X or pos.x or 0,
        y = pos.Y or pos.y or 0,
        z = pos.Z or pos.z or 0,
    }
end

function M.is_base_part(inst)
    if not inst then return false end
    if inst.is_a then
        local ok, yes = pcall(function() return inst:is_a("BasePart") end)
        if ok and yes then return true end
    end
    local cn = inst.ClassName or inst.class_name
    return BASE_PARTS[cn] == true
end

function M.iter_parts(char)
    local out = {}
    if not char then return out end
    local list = env.safe_call(function() return char:get_descendants() end)
        or env.safe_call(function() return char:GetDescendants() end)
        or env.safe_call(function() return char:get_children() end)
        or {}
    for _, inst in ipairs(list) do
        if M.is_base_part(inst) then
            out[#out + 1] = inst
        end
    end
    return out
end

function M.read_velocity(inst)
    if not inst then return 0, 0, 0 end
    local vel = inst.Velocity or inst.velocity
    if not vel then return 0, 0, 0 end
    return vel.x or vel.X or 0, vel.y or vel.Y or 0, vel.z or vel.Z or 0
end

function M.set_velocity(inst, x, y, z)
    if not inst then return end
    if part and part.set_velocity then
        pcall(part.set_velocity, inst, x, y, z)
    else
        pcall(function()
            inst.Velocity = Vector3.new(x, y, z)
        end)
    end
end

function M.zero_part(inst)
    if not inst then return end
    if part and part.set_velocity then
        pcall(part.set_velocity, inst, 0, 0, 0)
    end
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, inst, 0, 0, 0)
    end
end

function M.set_position(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function()
            inst.Position = Vector3.new(x, y, z)
        end)
    end
    M.zero_part(inst)
end

function M.set_noclip(char, enabled)
    if not char then return end
    for _, inst in ipairs(M.iter_parts(char)) do
        if part and part.set_can_collide then
            pcall(part.set_can_collide, inst, enabled)
        else
            pcall(function() inst.CanCollide = enabled end)
        end
    end
end

function M.zero_character(char)
    if not char then return end
    for _, inst in ipairs(M.iter_parts(char)) do
        M.zero_part(inst)
    end
end

function M.apply_fly_humanoid(hum, state_id)
    if not hum then return end
    state_id = state_id or 6
    pcall(function() hum.state = state_id end)
    pcall(function() hum.platform_stand = true end)
    pcall(function() hum.auto_rotate = false end)
    pcall(function() hum.evaluate_state_machine = false end)
    pcall(function() hum.sit = false end)
end

function M.restore_humanoid(hum)
    if not hum then return end
    pcall(function() hum.platform_stand = false end)
    pcall(function() hum.auto_rotate = true end)
    pcall(function() hum.evaluate_state_machine = true end)
    pcall(function() hum.state = 8 end)
end

function M.camera_vectors()
    if not camera or not camera.get_look_vector then return nil end
    local ok, look = pcall(camera.get_look_vector)
    if not ok or not look then return nil end

    local fx = look.x or look.X or 0
    local fy = look.y or look.Y or 0
    local fz = look.z or look.Z or 0
    local mag = math.sqrt(fx * fx + fy * fy + fz * fz)
    if mag < 0.001 then return nil end
    fx, fy, fz = fx / mag, fy / mag, fz / mag

    local hx, hz = fx, fz
    local hm = math.sqrt(hx * hx + hz * hz)
    if hm > 0.001 then
        hx, hz = hx / hm, hz / hm
    else
        hx, hz = 0, 1
    end

    local rx, rz = -hz, hx
    return fx, fy, fz, hx, hz, rx, rz
end

function M.move_input_flat(hx, hz, rx, rz)
    local dx, dz = 0, 0

    if M.key_down(0x57) then dx, dz = dx + hx, dz + hz end
    if M.key_down(0x53) then dx, dz = dx - hx, dz - hz end
    if M.key_down(0x41) then dx, dz = dx - rx, dz - rz end
    if M.key_down(0x44) then dx, dz = dx + rx, dz + rz end

    local mag = math.sqrt(dx * dx + dz * dz)
    if mag < 0.001 then return 0, 0, 0 end
    return dx / mag, dz / mag, mag
end

function M.apply_flat_delta(root, px, py, pz, dx, dz, speed, dt, lock_y)
    local step = speed * dt
    local nx = px + dx * step
    local ny = lock_y or py
    local nz = pz + dz * step
    M.set_position(root, nx, ny, nz)
    return nx, ny, nz
end

function M.suspend(char, hum, root, lock_y)
    M.apply_fly_humanoid(hum, 6)
    M.zero_character(char)
    if root and lock_y then
        local pos = M.read_pos(root)
        if pos then
            M.set_position(root, pos.x, lock_y, pos.z)
        end
    end
end

function M.run_cframe_fly(root, hum, speed)
    if not root or not hum then return end

    local fx, fy, fz, hx, hz, rx, rz = M.camera_vectors()
    if not fx then return end

    local dx, dy, dz, mag = M.move_input(fx, fy, fz, hx, hz, rx, rz)
    local pos = M.read_pos(root)
    if not pos then return end

    if mag > 0.001 then
        M.apply_delta(root, pos.x, pos.y, pos.z, dx, dy, dz, speed * 3, M.delta_time())
    else
        M.zero_part(root)
    end

    pcall(function() hum.platform_stand = false end)
end

function M.run_flat_fly(root, char, hum, lock_y, speed)
    if not root or not char or not hum or not lock_y then return end

    M.suspend(char, hum, root, lock_y)

    local _, _, _, hx, hz, rx, rz = M.camera_vectors()
    if not hx then return end

    local pos = M.read_pos(root)
    if not pos then return end

    local dx, dz, mag = M.move_input_flat(hx, hz, rx, rz)
    if mag > 0.001 then
        M.apply_flat_delta(root, pos.x, pos.y, pos.z, dx, dz, speed, M.delta_time(), lock_y)
    else
        M.set_position(root, pos.x, lock_y, pos.z)
    end
end

function M.move_input(fx, fy, fz, hx, hz, rx, rz)
    local dx, dy, dz = 0, 0, 0

    if M.key_down(0x57) then dx, dy, dz = dx + fx, dy + fy, dz + fz end
    if M.key_down(0x53) then dx, dy, dz = dx - fx, dy - fy, dz - fz end
    if M.key_down(0x41) then dx, dz = dx - rx, dz - rz end
    if M.key_down(0x44) then dx, dz = dx + rx, dz + rz end
    if M.key_down(0x20) then dy = dy + 1 end
    if M.key_down(0x11) then dy = dy - 1 end

    local mag = math.sqrt(dx * dx + dy * dy + dz * dz)
    if mag < 0.001 then return 0, 0, 0, 0 end
    return dx / mag, dy / mag, dz / mag, mag
end

function M.apply_delta(root, px, py, pz, dx, dy, dz, speed, dt)
    local step = speed * dt
    local nx = px + dx * step
    local ny = py + dy * step
    local nz = pz + dz * step
    M.set_position(root, nx, ny, nz)
    return nx, ny, nz
end

function M.read_camera_pos()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if not ok or not pos then return nil end
    return {
        x = pos.x or pos.X or 0,
        y = pos.y or pos.Y or 0,
        z = pos.z or pos.Z or 0,
    }
end

function M.set_camera_offset(hum, ox, oy, oz)
    if not hum then return end
    pcall(function()
        hum.camera_offset = { x = ox, y = oy, z = oz }
    end)
end

function M.read_camera_offset(hum)
    if not hum then return { x = 0, y = 0, z = 0 } end
    local off = hum.camera_offset or hum.CameraOffset
    if not off then return { x = 0, y = 0, z = 0 } end
    return {
        x = off.x or off.X or 0,
        y = off.y or off.Y or 0,
        z = off.z or off.Z or 0,
    }
end

return M
