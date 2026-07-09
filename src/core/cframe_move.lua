local env = April.require("core.env")

local M = {}

local BASE_PARTS = {
    Part = true, MeshPart = true, UnionOperation = true,
    WedgePart = true, CornerWedgePart = true, TrussPart = true,
}

local NOCLIP_PARTS = {
    "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head",
}

local HIP_OFFSET = 3.0

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

function M.read_velocity(inst)
    if not inst then return 0, 0, 0 end
    local vel = inst.AssemblyLinearVelocity or inst.Velocity or inst.velocity
    if not vel then return 0, 0, 0 end
    return vel.X or vel.x or 0, vel.Y or vel.y or 0, vel.Z or vel.z or 0
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

function M.find_part(char, name)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child(name) end
        return char:FindFirstChild(name)
    end)
end

function M.iter_parts(char)
    local out = {}
    if not char then return out end

    local desc = env.safe_call(function() return char:get_descendants() end)
        or env.safe_call(function() return char:GetDescendants() end)
    if desc then
        for _, inst in ipairs(desc) do
            if M.is_base_part(inst) then
                out[#out + 1] = inst
            end
        end
    end

    return out
end

function M.set_character_noclip(char, _root, enabled)
    local collide = not enabled
    for _, inst in ipairs(M.iter_parts(char)) do
        M.set_part_collide(inst, collide)
    end
end

function M.set_velocity(inst, x, y, z)
    if not inst then return end
    if part and part.set_velocity then
        pcall(part.set_velocity, inst, x, y, z)
    else
        pcall(function() inst.Velocity = Vector3.new(x, y, z) end)
    end
end

function M.set_position_only(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function() inst.Position = Vector3.new(x, y, z) end)
    end
end

function M.set_position(inst, x, y, z)
    M.set_position_only(inst, x, y, z)
end

function M.set_part_collide(inst, collide)
    if not inst then return end
    if part and part.set_can_collide then
        pcall(part.set_can_collide, inst, collide)
    else
        pcall(function() inst.CanCollide = collide end)
    end
end

function M.set_noclip_parts(char, enabled)
    if not char then return end
    local collide = not enabled
    for i = 1, #NOCLIP_PARTS do
        local p = M.find_part(char, NOCLIP_PARTS[i])
        if p and M.is_base_part(p) then
            M.set_part_collide(p, collide)
        end
    end
end

function M.humanoid_state(hum, state)
    if not hum or state == nil then return end
    pcall(function() hum.state = state end)
end

function M.humanoid_suspend(hum)
    if not hum then return end
    pcall(function() hum.platform_stand = false end)
    pcall(function() hum.auto_rotate = false end)
    pcall(function() hum.evaluate_state_machine = false end)
    pcall(function() hum.sit = false end)
end

function M.humanoid_running(hum)
    M.humanoid_state(hum, 8)
end

function M.zero_part(inst)
    if not inst then return end
    M.set_velocity(inst, 0, 0, 0)
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, inst, 0, 0, 0)
    end
end

function M.zero_character(char, root)
    if root then M.zero_part(root) end
    for i = 1, #NOCLIP_PARTS do
        local p = char and M.find_part(char, NOCLIP_PARTS[i])
        if p and p ~= root then
            M.zero_part(p)
        end
    end
end

function M.camera_flat_axes()
    if not camera or not camera.get_look_vector then return nil end
    local ok, look = pcall(camera.get_look_vector)
    if not ok or not look then return nil end

    local lx = look.x or look.X or 0
    local lz = look.z or look.Z or 0
    local lm = math.sqrt(lx * lx + lz * lz)
    if lm < 0.001 then return nil end
    lx, lz = lx / lm, lz / lm

    return lx, lz, -lz, lx
end

function M.read_flat_input()
    local lx, lz, rx, rz = M.camera_flat_axes()
    if not lx then return 0, 0 end

    local mx, mz = 0, 0
    if M.key_down(0x57) then mx, mz = mx + lx, mz + lz end
    if M.key_down(0x53) then mx, mz = mx - lx, mz - lz end
    if M.key_down(0x41) then mx, mz = mx - rx, mz - rz end
    if M.key_down(0x44) then mx, mz = mx + rx, mz + rz end

    local mag = math.sqrt(mx * mx + mz * mz)
    if mag < 0.001 then return 0, 0 end
    return mx / mag, mz / mag
end

function M.read_fly_input()
    local mx, mz = M.read_flat_input()
    local my = 0
    if M.key_down(0x20) then my = 1 end
    if M.key_down(0x11) then my = -1 end
    return mx, my, mz
end

function M.ground_distance(x, y, z)
    if not raycast or not raycast.cast then return nil end
    if raycast.is_ready and not raycast.is_ready() then return nil end

    local hit, _, dist = raycast.cast(x, y + 2, z, x, y - 512, z)
    if not hit then return nil end
    return dist
end

function M.floor_y_at(x, y, z)
    local dist = M.ground_distance(x, y, z)
    if not dist then return nil end
    return y + 2 - dist + HIP_OFFSET
end

function M.clamp_above_floor(x, y, z)
    local floor_y = M.floor_y_at(x, y, z)
    if floor_y and y < floor_y then return floor_y end
    return y
end

function M.drive_root(root, pos, dx, dy, dz, speed, dt)
    if not root or not pos then return pos end

    dt = dt or M.delta_time()
    local mag = math.sqrt(dx * dx + dy * dy + dz * dz)

    if mag < 0.001 then
        M.set_velocity(root, 0, -0.1, 0)
        return pos
    end

    dx, dy, dz = dx / mag, dy / mag, dz / mag
    local step = speed * dt
    local nx = pos.x + dx * step
    local ny = pos.y + dy * step
    local nz = pos.z + dz * step

    M.set_position_only(root, nx, ny, nz)
    M.set_velocity(root, dx * speed, dy * speed, dz * speed)

    return { x = nx, y = ny, z = nz }
end

return M
