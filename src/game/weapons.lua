local env = April.require("core.env")

local M = {}
local loaded = false
local toolinfo = {}
local recoil_weapons = {}
local originals = {}
local patched = {}

local FALLBACK_STATS = {
    ["Salvaged M14"] = { speed = 850, gravity = 18 },
    ["Salvaged AK47"] = { speed = 800, gravity = 15 },
    ["Military M4A1"] = { speed = 950, gravity = 18 },
    ["Military MP7"] = { speed = 750, gravity = 15 },
    ["Military PKM"] = { speed = 850, gravity = 18 },
    ["Bruno's M4A1"] = { speed = 1000, gravity = 18 },
    ["Salvaged Pump Action"] = { speed = 550, gravity = 15 },
    ["Salvaged Skorpion"] = { speed = 650, gravity = 12 },
    ["Salvaged SMG"] = { speed = 700, gravity = 12 },
    ["Salvaged AK74u"] = { speed = 750, gravity = 15 },
    ["Salvaged AK4"] = { speed = 800, gravity = 15 },
    ["Military Barrett"] = { speed = 1500, gravity = 25 },
    ["Military Barret"] = { speed = 1500, gravity = 25 },
    ["Crossbow"] = { speed = 400, gravity = 35 },
    ["Wooden Bow"] = { speed = 300, gravity = 40 },
}

function M.slug(name)
    return "april_rc_" .. (name or ""):gsub("[^%w]", "_")
end

function M.load()
    if loaded then return true end
    local rep = env.get_replicated_storage()
    if not rep then return false end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local tool_mod = modules and env.safe_call(function() return modules:find_first_child("ToolInfo") end)
    if not tool_mod then return false end
    local ok, data = pcall(function() return require(tool_mod) end)
    if not ok or type(data) ~= "table" then return false end

    toolinfo = data
    recoil_weapons = {}
    for name, entry in pairs(data) do
        if type(entry) == "table" and entry.Recoil and entry.Recoil.Camera then
            table.insert(recoil_weapons, name)
        end
    end
    table.sort(recoil_weapons)
    loaded = true
    return true
end

function M.get(name)
    if not loaded then M.load() end
    return toolinfo[name]
end

function M.recoil_weapon_names()
    if not loaded then M.load() end
    return recoil_weapons
end

function M.get_held_weapon_name()
    local lp = env.get_local_player()
    if not lp then return nil end

    local char = lp.character
    if char and env.is_valid(char) then
        for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
            if child and toolinfo[child.Name] and toolinfo[child.Name].Recoil then
                return child.Name
            end
            if child and child.ClassName == "Tool" and toolinfo[child.Name] then
                return child.Name
            end
        end
    end

    local ws = env.get_workspace()
    if ws then
        local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
        if vms then
            for _, vm in ipairs(env.safe_call(function() return vms:get_children() end) or {}) do
                if vm and vm.Name == "Viewmodel" then
                    for _, item in ipairs(env.safe_call(function() return vm:get_children() end) or {}) do
                        if item and item.ClassName == "Model" and toolinfo[item.Name] then
                            return item.Name
                        end
                    end
                end
            end
        end
    end

    if lp.tool_name and lp.tool_name ~= "" and toolinfo[lp.tool_name] then
        return lp.tool_name
    end
    return nil
end

function M.get_weapon_stats(name)
    name = name or M.get_held_weapon_name()
    if not name then return nil end

    local entry = M.get(name)
    if entry and entry.Bullet then
        return {
            speed = entry.Bullet.Speed or 1000,
            gravity = entry.Bullet.Gravity or 35,
            name = name,
        }
    end

    local fb = FALLBACK_STATS[name]
    if fb then
        return { speed = fb.speed, gravity = fb.gravity, name = name }
    end
    return { speed = 1000, gravity = 35, name = name }
end

local function copy_shake(shake)
    if not shake then return nil end
    local out = {}
    for k, v in pairs(shake) do out[k] = v end
    return out
end

local function scale_range(r, scale)
    if type(r) == "table" and r[1] and r[2] then
        return { r[1] * scale, r[2] * scale }
    end
    if type(r) == "number" then return r * scale end
    return r
end

local function store_original(name, entry)
    if originals[name] then return end
    local cam = entry.Recoil.Camera
    originals[name] = {
        RecoilStart = cam.RecoilStart,
        RecoilFinish = cam.RecoilFinish,
        Shake = copy_shake(cam.Shake),
        ScreenShake = entry.Shake and {
            sx = entry.Shake.Strength and (entry.Shake.Strength.x or entry.Shake.Strength.X),
            sy = entry.Shake.Strength and (entry.Shake.Strength.y or entry.Shake.Strength.Y),
            sz = entry.Shake.Strength and (entry.Shake.Strength.z or entry.Shake.Strength.Z),
            Speed = entry.Shake.Speed,
        } or nil,
        VM = entry.Recoil.VM and {
            Pos = entry.Recoil.VM.Pos and {
                X = entry.Recoil.VM.Pos.X,
                Y = entry.Recoil.VM.Pos.Y,
                Z = entry.Recoil.VM.Pos.Z,
            } or nil,
            Rot = entry.Recoil.VM.Rot and {
                X = entry.Recoil.VM.Rot.X,
                Y = entry.Recoil.VM.Rot.Y,
                Z = entry.Recoil.VM.Rot.Z,
            } or nil,
        } or nil,
    }
end

function M.restore_recoil(name)
    local entry = toolinfo[name]
    local orig = originals[name]
    if not entry or not orig or not entry.Recoil then return end
    local cam = entry.Recoil.Camera
    cam.RecoilStart = orig.RecoilStart
    cam.RecoilFinish = orig.RecoilFinish
    cam.Shake = copy_shake(orig.Shake)
    if orig.ScreenShake and entry.Shake and orig.ScreenShake.sx then
        if Vector3 then
            entry.Shake.Strength = Vector3.new(orig.ScreenShake.sx, orig.ScreenShake.sy, orig.ScreenShake.sz)
        end
        entry.Shake.Speed = orig.ScreenShake.Speed
    end
    if orig.VM and entry.Recoil.VM then
        if orig.VM.Pos and entry.Recoil.VM.Pos then
            entry.Recoil.VM.Pos.X = orig.VM.Pos.X
            entry.Recoil.VM.Pos.Y = orig.VM.Pos.Y
            entry.Recoil.VM.Pos.Z = orig.VM.Pos.Z
        end
        if orig.VM.Rot and entry.Recoil.VM.Rot then
            entry.Recoil.VM.Rot.X = orig.VM.Rot.X
            entry.Recoil.VM.Rot.Y = orig.VM.Rot.Y
            entry.Recoil.VM.Rot.Z = orig.VM.Rot.Z
        end
    end
    patched[name] = nil
end

-- reduction_percent: 0 = stock recoil, 100 = no recoil (client ToolInfo only — server spread unchanged)
function M.set_recoil_reduction(name, reduction_percent)
    if not loaded then M.load() end
    local entry = toolinfo[name]
    if not entry or not entry.Recoil or not entry.Recoil.Camera then return false end

    reduction_percent = math.max(0, math.min(100, reduction_percent or 0))
    if reduction_percent <= 0 then
        M.restore_recoil(name)
        return true
    end

    store_original(name, entry)
    local scale = 1 - (reduction_percent / 100)
    local cam = entry.Recoil.Camera
    local orig = originals[name]

    cam.RecoilStart = function(...)
        local pitch, yaw = orig.RecoilStart(...)
        return (pitch or 0) * scale, (yaw or 0) * scale
    end
    cam.RecoilFinish = function(...)
        local pitch, yaw = orig.RecoilFinish(...)
        return (pitch or 0) * scale, (yaw or 0) * scale
    end

    if cam.Shake and orig.Shake then
        cam.Shake = {
            X = scale_range(orig.Shake.X, scale),
            Y = scale_range(orig.Shake.Y, scale),
        }
    end

    if entry.Shake and orig.ScreenShake and orig.ScreenShake.Strength then
        local s = orig.ScreenShake.Strength
        local sx = s.x or s.X or 0
        local sy = s.y or s.Y or 0
        local sz = s.z or s.Z or 0
        if Vector3 then
            entry.Shake.Strength = Vector3.new(sx * scale, sy * scale, sz * scale)
        end
    end

    if entry.Recoil.VM and orig.VM then
        local vm = entry.Recoil.VM
        if vm.Pos and orig.VM.Pos then
            if type(vm.Pos.X) == "number" then vm.Pos.X = (orig.VM.Pos.X or 0) * scale end
            if type(vm.Pos.Y) == "number" then vm.Pos.Y = (orig.VM.Pos.Y or 0) * scale end
            if type(vm.Pos.Z) == "number" then vm.Pos.Z = (orig.VM.Pos.Z or 0) * scale end
        end
        if vm.Rot and orig.VM.Rot then
            vm.Rot.Y = (type(orig.VM.Rot.Y) == "number" and orig.VM.Rot.Y or 0) * scale
            vm.Rot.X = scale_range(orig.VM.Rot.X, scale)
            vm.Rot.Z = scale_range(orig.VM.Rot.Z, scale)
        end
    end

    patched[name] = reduction_percent
    return true
end

function M.apply_all_recoil_from_menu()
    if not menu or not menu.get then return end
    for _, name in ipairs(recoil_weapons) do
        local id = M.slug(name)
        local val = menu.get(id)
        if val == nil then val = 0 end
        M.set_recoil_reduction(name, tonumber(val) or 0)
    end
end

return M
