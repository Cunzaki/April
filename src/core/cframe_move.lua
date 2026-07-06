--[[ CFrame movement — position writes, zero velocity (no velocity exploits). ]]

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
    local list = env.safe_call(function() return char:get_children() end)
        or env.safe_call(function() return char:GetChildren() end)
        or {}
    for _, inst in ipairs(list) do
        if M.is_base_part(inst) then
            out[#out + 1] = inst
        end
    end
    return out
end

function M.set_velocity(inst, x, y, z)
    if not inst then return end
    if part and part.set_velocity then
        pcall(part.set_velocity, inst, x, y, z)
    else
        pcall(function() inst.Velocity = Vector3.new(x, y, z) end)
    end
end

function M.zero_part(inst)
    if not inst then return end
    M.set_velocity(inst, 0, 0, 0)
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, inst, 0, 0, 0)
    end
end

function M.set_position(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function() inst.Position = Vector3.new(x, y, z) end)
    end
    M.zero_part(inst)
end

function M.zero_character(char, root)
    if root then M.zero_part(root) end
    for _, inst in ipairs(M.iter_parts(char)) do
        if inst ~= root then
            M.zero_part(inst)
        end
    end
end

function M.humanoid_suspend(hum)
    if not hum then return end
    pcall(function() hum.platform_stand = false end)
    pcall(function() hum.auto_rotate = false end)
    pcall(function() hum.evaluate_state_machine = false end)
    pcall(function() hum.sit = false end)
end

function M.humanoid_release(hum)
    if not hum then return end
    pcall(function() hum.platform_stand = false end)
    pcall(function() hum.auto_rotate = true end)
    pcall(function() hum.evaluate_state_machine = true end)
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

    local rx, rz = -lz, lx
    return lx, lz, rx, rz
end

--[[ WASD = flat XZ only. Space / Ctrl = vertical. ]]
function M.read_fly_input()
    local lx, lz, rx, rz = M.camera_flat_axes()
    local mx, mz, my = 0, 0, 0

    if lx then
        if M.key_down(0x57) then mx, mz = mx + lx, mz + lz end
        if M.key_down(0x53) then mx, mz = mx - lx, mz - lz end
        if M.key_down(0x41) then mx, mz = mx - rx, mz - rz end
        if M.key_down(0x44) then mx, mz = mx + rx, mz + rz end
    end

    if M.key_down(0x20) then my = 1 end
    if M.key_down(0x11) then my = -1 end

    local hm = math.sqrt(mx * mx + mz * mz)
    if hm > 0.001 then
        mx, mz = mx / hm, mz / hm
    else
        mx, mz = 0, 0
    end

    return mx, my, mz
end

return M
