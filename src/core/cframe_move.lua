-- Soft movement helpers. Prefer velocity writes on HRP only - avoid position
-- teleports, limb velocity spam, and insane pulse values (those ban).

local env = April.require("core.env")

local M = {}

local BASE_PARTS = {
    Part = true, MeshPart = true, UnionOperation = true,
    WedgePart = true, CornerWedgePart = true, TrussPart = true,
}

local NOCLIP_PARTS = {
    "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head",
}

-- Snapshot CanCollide before noclip so restore never force-enables Head/Torso
-- collision (Fallen keeps those off — forcing true blocks crouch gaps).
local collide_snap = {}

local function part_key(inst)
    if not inst then return nil end
    return inst.Address or inst.address or tostring(inst)
end

local function read_can_collide(inst)
    if not inst then return nil end
    local ok, v = pcall(function()
        if part and part.get_can_collide then
            return part.get_can_collide(inst)
        end
        if part and part.GetCanCollide then
            return part.GetCanCollide(inst)
        end
        return inst.CanCollide
    end)
    if ok and v ~= nil then return v == true end
    return nil
end

local function snapshot_collide(inst)
    local key = part_key(inst)
    if not key then return end
    if collide_snap[key] == nil then
        collide_snap[key] = read_can_collide(inst)
    end
end

local function restore_collide(inst)
    local key = part_key(inst)
    if not key then return end
    local prev = collide_snap[key]
    collide_snap[key] = nil
    if prev == nil then return end
    M.set_part_collide(inst, prev)
end

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

function M.clear_collide_snapshots()
    for k in pairs(collide_snap) do
        collide_snap[k] = nil
    end
end

-- Fallen keeps Head/Torso non-collidable. Older builds force-enabled them on
-- every fly-off tick and blocked crouch gaps; this restores sane defaults.
local FALLEN_PART_COLLIDE = {
    HumanoidRootPart = true,
    Torso = false,
    UpperTorso = false,
    LowerTorso = false,
    Head = false,
}

function M.reset_fallen_collision(char)
    if not char then return end
    M.clear_collide_snapshots()
    for name, collide in pairs(FALLEN_PART_COLLIDE) do
        local p = M.find_part(char, name)
        if p and M.is_base_part(p) then
            M.set_part_collide(p, collide)
        end
    end
end

function M.set_character_noclip(char, _root, enabled)
    if not char then return end
    if enabled then
        for _, inst in ipairs(M.iter_parts(char)) do
            snapshot_collide(inst)
            M.set_part_collide(inst, false)
        end
        return
    end
    for _, inst in ipairs(M.iter_parts(char)) do
        restore_collide(inst)
    end
end

function M.set_velocity(inst, x, y, z)
    if not inst then return end
    if part and part.set_velocity then
        pcall(part.set_velocity, inst, x, y, z)
    else
        pcall(function()
            if inst.set_velocity then
                inst:set_velocity(x, y, z)
            else
                inst.Velocity = Vector3.new(x, y, z)
            end
        end)
    end
end

function M.set_angular_velocity(inst, x, y, z)
    if not inst then return end
    x, y, z = x or 0, y or 0, z or 0
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, inst, x, y, z)
    else
        pcall(function()
            if inst.set_angular_velocity then
                inst:set_angular_velocity(x, y, z)
            else
                inst.AngularVelocity = Vector3.new(x, y, z)
            end
        end)
    end
end

function M.set_position_only(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function()
            if inst.set_position then
                inst:set_position(x, y, z)
            else
                inst.Position = Vector3.new(x, y, z)
            end
        end)
    end
end

function M.set_position(inst, x, y, z)
    M.set_position_only(inst, x, y, z)
end

function M.set_cframe_position(inst, x, y, z)
    if not inst then return false end
    local ok = pcall(function()
        local cf = inst.CFrame or inst.cframe
        if cf and cf.Position and CFrame and CFrame.new then
            local rotation = cf - cf.Position
            inst.CFrame = CFrame.new(x, y, z) * rotation
        else
            error("CFrame unavailable")
        end
    end)
    -- Vector's direct CFrame assignment can be accepted but ignored by some
    -- live part handles. Its position primitive is the reliable movement write;
    -- retain the CFrame rotation attempt, then commit the translated position.
    M.set_position_only(inst, x, y, z)
    return ok
end

function M.set_part_collide(inst, collide)
    if not inst then return end
    if part and part.set_can_collide then
        pcall(part.set_can_collide, inst, collide)
    elseif part and part.SetCanCollide then
        pcall(part.SetCanCollide, inst, collide)
    else
        pcall(function() inst.CanCollide = collide end)
    end
end

function M.humanoid_state(hum, state)
    if not hum or state == nil then return end
    pcall(function()
        if hum.set_state then hum:set_state(state)
        else hum.state = state
        end
    end)
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
    M.set_angular_velocity(inst, 0, 0, 0)
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
    if not raycast then return nil end
    local cast = raycast.cast or raycast.Cast
    if type(cast) ~= "function" then return nil end
    local ready = raycast.is_ready or raycast.IsReady
    if type(ready) == "function" then
        local ok, value = pcall(ready)
        if ok and value == false then return nil end
    end
    local ok, hit, _, dist = pcall(cast, x, y + 2, z, x, y - 512, z)
    if not ok or not hit then return nil end
    return tonumber(dist)
end

function M.set_noclip_parts(char, enabled)
    if not char then return end
    if enabled then
        for i = 1, #NOCLIP_PARTS do
            local p = M.find_part(char, NOCLIP_PARTS[i])
            if p and M.is_base_part(p) then
                snapshot_collide(p)
                M.set_part_collide(p, false)
            end
        end
        return
    end
    for i = 1, #NOCLIP_PARTS do
        local p = M.find_part(char, NOCLIP_PARTS[i])
        if p and M.is_base_part(p) then
            restore_collide(p)
        end
    end
end

function M.drive_velocity_target(root, tx, ty, tz, dt, opts)
    if not root then return end
    opts = opts or {}
    dt = dt or M.delta_time()
    tx, ty, tz = tx or 0, ty or 0, tz or 0

    local cx, cy, cz = M.read_velocity(root)
    local blend = opts.blend
    if blend == nil then
        local response = math.max(1, tonumber(opts.response) or 16)
        blend = 1 - math.exp(-response * math.max(0.001, math.min(dt, 0.1)))
    end
    blend = math.max(0.05, math.min(1, blend))

    local nx = cx + (tx - cx) * blend
    local vertical_blend = tonumber(opts.vertical_blend) or blend
    vertical_blend = math.max(0.05, math.min(1, vertical_blend))
    local ny = cy + (ty - cy) * vertical_blend
    local nz = cz + (tz - cz) * blend

    local max_speed = tonumber(opts.max_speed)
    if max_speed and max_speed > 0 then
        local sm = math.sqrt(nx * nx + ny * ny + nz * nz)
        if sm > max_speed and sm > 0.001 then
            local scale = max_speed / sm
            nx, ny, nz = nx * scale, ny * scale, nz * scale
        end
    end

    M.set_velocity(root, nx, ny, nz)
    if opts.zero_angular then
        M.set_angular_velocity(root, 0, 0, 0)
    end
    return nx, ny, nz
end

function M.drive_root_velocity(root, dx, dy, dz, speed, dt, opts)
    opts = opts or {}
    local mag = math.sqrt(dx * dx + dy * dy + dz * dz)
    local tx, ty, tz = 0, 0, 0
    if mag >= 0.001 then
        tx = dx / mag * speed
        ty = dy / mag * speed
        tz = dz / mag * speed
    end
    opts.max_speed = opts.max_speed or (speed * 1.15)
    return M.drive_velocity_target(root, tx, ty, tz, dt, opts)
end

return M
