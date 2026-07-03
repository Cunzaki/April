local env = April.require("core.env")

local M = {}
local loaded = false
local toolinfo = {}
local recoil_weapons = {}

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

return M
