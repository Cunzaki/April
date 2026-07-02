local env = April.require("core.env")

local M = {}
local loaded = false
local weapons = {}

local FALLBACK = {
    ["Salvaged M14"] = {
        Weapon = { RPM = 370, Auto = false },
        Bullet = { Speed = 2100, Gravity = 0.55, MaxRange = 1100 },
    },
}

function M.load()
    if loaded then return true end
    local rep = env.get_replicated_storage()
    if not rep then return false end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local tool_mod = modules and env.safe_call(function() return modules:find_first_child("ToolInfo") end)
    if not tool_mod then return false end
    local ok, data = pcall(function() return require(tool_mod) end)
    if ok and type(data) == "table" then
        weapons = data
        loaded = true
        return true
    end
    return false
end

function M.get(weapon_name)
    if not loaded then M.load() end
    return weapons[weapon_name] or FALLBACK[weapon_name]
end

function M.bullet_speed(weapon_name)
    local w = M.get(weapon_name)
    if w and w.Bullet and w.Bullet.Speed then return w.Bullet.Speed end
    return 1000
end

function M.bullet_gravity(weapon_name)
    local w = M.get(weapon_name)
    if w and w.Bullet and w.Bullet.Gravity then return w.Bullet.Gravity end
    return 0.5
end

return M
