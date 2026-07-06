--[[ Ray origins — cheap per-frame viewmodel muzzle / server body (no tree scans). ]]

local env = April.require("core.env")
local weapons = April.require("game.weapons")

local M = {}

local frame = { t = 0, weapon = nil, muzzle = nil, server = nil }

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function part_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if p and p.x ~= nil then
        return { x = p.x, y = p.y, z = p.z }
    end
    return nil
end

local function vec3_from_cf(cf)
    if not cf then return nil end
    local pos = cf.Position or cf.position
    if pos and pos.x ~= nil then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

local function camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if ok and pos and pos.x then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

local function viewmodel_cframe_origin()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end

    local cc = find_child(char, "CameraController")
    if not cc then return nil end

    local cf = env.safe_call(function() return cc:GetAttribute("ViewmodelCFrame") end)
    if not cf then return nil end

    local pos = vec3_from_cf(cf)
    if not pos then return nil end

    local look = cf.LookVector or cf.lookVector
    if look and look.x then
        return {
            x = pos.x + look.x * 0.5,
            y = pos.y + look.y * 0.5,
            z = pos.z + look.z * 0.5,
        }
    end
    return pos
end

local function flashpart_origin()
    local ws = env.get_workspace()
    if not ws then return nil end

    local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
        or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
    if not vms then return nil end

    local vm = env.safe_call(function() return vms:find_first_child("Viewmodel") end)
        or env.safe_call(function() return vms:FindFirstChild("Viewmodel") end)
    if not vm then return nil end

    local flash = find_child(vm, "FlashPart") or find_child(vm, "Flash")
    return part_pos(flash)
end

local function compute_muzzle(weapon)
    local flash = flashpart_origin()
    if flash then return flash end

    local cframe = viewmodel_cframe_origin()
    if cframe then return cframe end

    if weapon and weapons.is_bow_weapon_name(weapon) then
        return camera_origin()
    end

    return camera_origin()
end

local function compute_server()
    local lp = env.get_local_player()
    if not lp then return nil end

    if lp.position then
        return { x = lp.position.x, y = lp.position.y, z = lp.position.z }
    end

    local char = lp.character
    if char and env.is_valid(char) then
        return part_pos(find_child(char, "HumanoidRootPart"))
    end

    return nil
end

function M.invalidate()
    frame.t = 0
    frame.weapon = nil
    frame.muzzle = nil
    frame.server = nil
end

function M.sync_weapon(weapon)
    weapon = weapon or weapons.cached_held_ranged()
    local now = tick_ms()
    if frame.t == now and frame.weapon == weapon and frame.muzzle then
        return
    end
    frame.t = now
    frame.weapon = weapon
    frame.muzzle = compute_muzzle(weapon)
    frame.server = compute_server()
end

function M.get_muzzle_origin()
    M.sync_weapon()
    return frame.muzzle
end

function M.get_server_origin()
    M.sync_weapon()
    return frame.server
end

function M.get_camera_origin()
    if not camera or not camera.get_position then return nil end
    local ok, pos = pcall(camera.get_position)
    if ok and pos and pos.x then
        return { x = pos.x, y = pos.y, z = pos.z }
    end
    return nil
end

function M.get_fire_origin()
    M.sync_weapon()
    return frame.muzzle or frame.server
end

return M
