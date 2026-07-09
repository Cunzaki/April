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

local function find_flash_in(model)
    if not model then return nil end
    local flash = find_child(model, "FlashPart") or find_child(model, "Flash")
    if flash then return part_pos(flash) end
    local weapon = find_child(model, "Weapon")
    if weapon then
        flash = find_child(weapon, "FlashPart") or find_child(weapon, "Flash")
        if flash then return part_pos(flash) end
    end
    local desc = env.safe_call(function()
        if model.get_descendants then return model:get_descendants() end
        return model:GetDescendants()
    end) or {}
    for _, d in ipairs(desc) do
        local n = d.Name or d.name
        if n == "FlashPart" or n == "Flash" then
            return part_pos(d)
        end
    end
    return nil
end

local function camera_viewmodel()
    local ws = env.get_workspace()
    if not ws then return nil end
    local cam = env.safe_call(function()
        return ws.CurrentCamera or ws.currentCamera
            or (ws.FindFirstChild and ws:FindFirstChild("CurrentCamera"))
    end)
    if not cam then return nil end
    local kids = env.safe_call(function()
        if cam.get_children then return cam:get_children() end
        return cam:GetChildren()
    end) or {}
    for _, child in ipairs(kids) do
        local cn = child.ClassName or child.class_name
        if cn == "Model" then
            if find_child(child, "Weapon") or find_child(child, "Arms") then
                return child
            end
        end
    end
    return nil
end

local function flashpart_origin()
    -- Live VM is parented to CurrentCamera (ViewmodelController), not workspace.Viewmodels
    local live = camera_viewmodel()
    local pos = find_flash_in(live)
    if pos then return pos end

    local ws = env.get_workspace()
    if not ws then return nil end

    local vfx = find_child(ws, "VFX")
    local vms = vfx and find_child(vfx, "VMs")
    if vms then
        local kids = env.safe_call(function()
            if vms.get_children then return vms:get_children() end
            return vms:GetChildren()
        end) or {}
        for _, child in ipairs(kids) do
            pos = find_flash_in(child)
            if pos then return pos end
        end
    end

    -- Legacy fallback
    local legacy = find_child(ws, "Viewmodels")
    if legacy then
        local vm = find_child(legacy, "Viewmodel") or find_child(legacy, "ViewModel")
        pos = find_flash_in(vm)
        if pos then return pos end
    end

    return nil
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
