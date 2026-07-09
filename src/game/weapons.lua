local bootstrap = April.require("game.bootstrap")
local env = April.require("core.env")

local M = {}
local loaded = false
local toolinfo = {}
local recoil_weapons = {}
local weapon_names = {}

local ROBLOX_GRAV = 196.2

local FALLBACK_STATS = {
    ["Military Barret"] = { speed = 2500, gravity = 0.55 },
    ["Military Barrett"] = { speed = 2500, gravity = 0.55 },
    ["Military M4A1"] = { speed = 2100, gravity = 0.55 },
    ["Military M39"] = { speed = 2400, gravity = 0.52 },
    ["Military MP7"] = { speed = 1900, gravity = 0.6 },
    ["Military PKM"] = { speed = 2400, gravity = 0.55 },
    ["Military USP"] = { speed = 1800, gravity = 0.6 },
    ["Military AA12"] = { speed = 400, gravity = 0.6 },
    ["Bruno's M4A1"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged AK47"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged AK74u"] = { speed = 1900, gravity = 0.6 },
    ["Salvaged AK4"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged Sniper"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged M14"] = { speed = 2100, gravity = 0.55 },
    ["Salvaged SMG"] = { speed = 1600, gravity = 0.6 },
    ["Salvaged Skorpion"] = { speed = 1400, gravity = 0.6 },
    ["Salvaged Python"] = { speed = 1500, gravity = 0.6 },
    ["Salvaged P250"] = { speed = 1400, gravity = 0.6 },
    ["Salvaged Pipe Rifle"] = { speed = 800, gravity = 0.55 },
    ["Salvaged Pump Action"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Shotgun"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Double Barrel"] = { speed = 400, gravity = 0.6 },
    ["Salvaged Break Action"] = { speed = 400, gravity = 0.6 },
    ["Crossbow"] = { speed = 420, gravity = 0.2 },
    ["Wooden Bow"] = { speed = 280, gravity = 0.2 },
    ["Nail Gun"] = { speed = 165, gravity = 0.25 },
    ["Pumpkin Launcher"] = { speed = 100, gravity = 0.12 },
    ["Salvaged RPG"] = { speed = 100, gravity = 0.12 },
    ["Military Grenade Launcher"] = { speed = 350, gravity = 0.55 },
    ["Salvaged Grenade Launcher"] = { speed = 350, gravity = 0.55 },
}

M._last_held = nil
M._last_held_ranged = nil
M._was_in_game = false
M._weapon_changed_at = 0

local function inst_name(inst)
    if not inst then return nil end
    return inst.name or inst.Name
end

local function is_tool(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return cn == "Tool"
end

local function rebuild_weapon_names()
    weapon_names = {}
    for name in pairs(FALLBACK_STATS) do
        weapon_names[name] = true
    end
    for name in pairs(toolinfo) do
        if type(name) == "string" then
            weapon_names[name] = true
        end
    end
end

function M.slug(name)
    return "april_rc_" .. (name or ""):gsub("[^%w]", "_")
end

function M.is_weapon_name(name)
    return name and weapon_names[name] == true
end

local MELEE_NAME_HINTS = {
    "hatchet", "pickaxe", "pick axe", " axe", "axe ",
    "spear", "machete", "knife", "sword",
    "bone tool", "hammer", "crowbar",
    "chainsaw", "mining drill", "shovel", "scythe",
    "candy cane", "carrot blade", "boulder", "saw bat",
}

local function name_looks_melee(name)
    local n = (name or ""):lower()
    for _, hint in ipairs(MELEE_NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

function M.is_ranged_weapon_name(name)
    if not name or name == "" then return false end
    local lower = name:lower()
    if lower:find("bow", 1, true) or lower:find("crossbow", 1, true) then return true end
    if name_looks_melee(name) then return false end

    if not loaded then M.load() end

    local entry = toolinfo[name]
    if entry then
        if entry.Bullet then return true end
        if entry.Melee and not entry.Bullet then return false end
        if entry.Weapon and (entry.Weapon.RPM or entry.Weapon.ActualRPM) then
            return true
        end
        if entry.Melee then return false end
    end

    if FALLBACK_STATS[name] then
        return true
    end

    return false
end

function M.get_held_ranged_weapon_name()
    if not loaded then M.load() end

    local lp = env.get_local_player()
    if not lp then return nil end

    local function pick(name)
        if name and M.is_ranged_weapon_name(name) then return name end
    end

    local char = lp.character
    if char and env.is_valid(char) then
        for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
            local hit = pick(inst_name(child))
            if hit then return hit end
        end
    end

    local ws = env.get_workspace()
    if ws then
        local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
            or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
        if vms then
            for _, vm in ipairs(env.safe_call(function() return vms:get_children() end) or {}) do
                if inst_name(vm) == "Viewmodel" then
                    for _, item in ipairs(env.safe_call(function() return vm:get_children() end) or {}) do
                        local hit = pick(inst_name(item))
                        if hit then return hit end
                    end
                end
            end
        end
    end

    return pick(lp.tool_name)
end

function M.holding_ranged_weapon()
    return M._last_held_ranged ~= nil
end

function M.cached_held_ranged()
    return M._last_held_ranged
end

function M.is_bow_weapon_name(name)
    if not name then return false end
    local n = name:lower()
    return n:find("bow", 1, true) ~= nil
end

function M.invalidate()
    loaded = false
    toolinfo = {}
    recoil_weapons = {}
    weapon_names = {}
    M._last_held = nil
    M._last_held_ranged = nil
    M._weapon_changed_at = 0
    pcall(function()
        local origin = April.require("game.combat_origin")
        if origin.invalidate then origin.invalidate() end
    end)
end

function M.in_game_ready()
    if env.get_local_player() then return true end
    if entity and entity.get_players and #entity.get_players() > 0 then return true end
    return false
end

function M.load()
    if loaded then return true end

    local data = bootstrap.get_module("ToolInfo")
    if type(data) ~= "table" then
        rebuild_weapon_names()
        return false
    end

    toolinfo = data
    recoil_weapons = {}
    for name, entry in pairs(data) do
        if type(entry) == "table" and (entry.Bullet or entry.Recoil or entry.Weapon) then
            table.insert(recoil_weapons, name)
        end
    end
    table.sort(recoil_weapons)
    rebuild_weapon_names()
    loaded = #recoil_weapons > 0
    return loaded
end

function M.get(name)
    if not loaded then M.load() end
    return toolinfo[name]
end

function M.recoil_weapon_names()
    if not loaded then M.load() end
    return recoil_weapons
end

function M.profile_weapon_names()
    if not loaded then M.load() end

    local farm = nil
    pcall(function()
        farm = April.require("game.farm_tools")
        if farm and farm.load then farm.load() end
    end)

    local seen = {}
    local list = {}

    local function add(name)
        if not name or name == "" or seen[name] then return end
        if not M.is_ranged_weapon_name(name) then return end
        if farm and farm.is_farm_tool_name and farm.is_farm_tool_name(name) then return end
        seen[name] = true
        list[#list + 1] = name
    end

    for name in pairs(toolinfo) do
        add(name)
    end
    for name in pairs(FALLBACK_STATS) do
        add(name)
    end

    table.sort(list)
    return list
end

local function read_tool_attributes(inst)
    if not inst then return nil end
    local speed, gravity
    pcall(function()
        if inst.GetAttribute then
            speed = inst:GetAttribute("BulletSpeed") or inst:GetAttribute("MuzzleVelocity")
            gravity = inst:GetAttribute("BulletGravity") or inst:GetAttribute("ProjectileGravity")
        elseif inst.get_attribute then
            speed = inst:get_attribute("BulletSpeed") or inst:get_attribute("MuzzleVelocity")
            gravity = inst:get_attribute("BulletGravity") or inst:get_attribute("ProjectileGravity")
        end
    end)
    if speed then
        local grav = gravity
        if not grav or grav <= 0 or grav > 2 then
            grav = 0.55
        end
        return {
            speed = speed,
            gravity = grav,
            name = inst_name(inst),
            from_attributes = true,
        }
    end
    return nil
end

local function find_held_in_character(lp)
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil, nil end

    local fallback_tool = nil
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local n = inst_name(child)
        if n and M.is_weapon_name(n) then
            return n, child
        end
        if is_tool(child) and n then
            fallback_tool = fallback_tool or { name = n, inst = child }
        end
    end

    if fallback_tool then
        return fallback_tool.name, fallback_tool.inst
    end
    return nil, nil
end

local function find_held_in_viewmodels()
    local ws = env.get_workspace()
    if not ws then return nil end

    local vms = env.safe_call(function() return ws:find_first_child("Viewmodels") end)
        or env.safe_call(function() return ws:FindFirstChild("Viewmodels") end)
    if not vms then return nil end

    for _, vm in ipairs(env.safe_call(function() return vms:get_children() end) or {}) do
        if inst_name(vm) == "Viewmodel" then
            for _, item in ipairs(env.safe_call(function() return vm:get_children() end) or {}) do
                local n = inst_name(item)
                if n and M.is_weapon_name(n) then
                    return n, item
                end
                local cn = item and (item.ClassName or item.class_name)
                if cn == "Model" and n and M.is_weapon_name(n) then
                    return n, item
                end
            end
        end
    end
    return nil, nil
end

function M.get_held_weapon_name()
    rebuild_weapon_names()

    local lp = env.get_local_player()
    if not lp then return nil end

    local name, inst = find_held_in_character(lp)
    if name then return name end

    name = find_held_in_viewmodels()
    if name then return name end

    if lp.tool_name and lp.tool_name ~= "" then
        if M.is_weapon_name(lp.tool_name) or loaded then
            return lp.tool_name
        end
    end

    return nil
end

function M.get_held_tool()
    local lp = env.get_local_player()
    if not lp then return nil, nil end
    local name, inst = find_held_in_character(lp)
    if name then return name, inst end
    name = find_held_in_viewmodels()
    return name, nil
end

function M.drop_gravity(grav)
    if not grav or grav <= 0 then return ROBLOX_GRAV * 0.55 end
    if grav <= 2 then return grav * ROBLOX_GRAV end
    return grav
end

function M.get_weapon_stats(name)
    name = name or M.get_held_weapon_name()
    if not name then return nil end

    local entry = M.get(name)
    if entry and entry.Bullet then
        return {
            speed = entry.Bullet.Speed or 950,
            gravity = entry.Bullet.Gravity or 0.55,
            name = name,
            from_toolinfo = true,
            is_bow = (entry.Weapon and entry.Weapon.IsBow)
                or name == "Wooden Bow"
                or name == "Crossbow",
        }
    end

    local fb = FALLBACK_STATS[name]
    if fb then
        return {
            speed = fb.speed,
            gravity = fb.gravity,
            name = name,
            from_fallback = true,
            is_bow = name == "Wooden Bow" or name == "Crossbow",
        }
    end

    local _, tool_inst = M.get_held_tool()
    if tool_inst then
        local from_attrs = read_tool_attributes(tool_inst)
        if from_attrs then
            from_attrs.name = name
            return from_attrs
        end
    end

    return { speed = 950, gravity = 0.55, name = name }
end

function M.tick()
    local in_game = M.in_game_ready()

    if not in_game then
        if M._was_in_game then
            M._last_held = nil
            M._last_held_ranged = nil
            M._weapon_changed_at = 0
        end
        M._was_in_game = false
        return nil
    end

    if not M._was_in_game then
        M._was_in_game = true
        M.load()
    end

    if not loaded and bootstrap.is_ready and bootstrap.is_ready() then
        M.load()
    end

    local held = M.get_held_ranged_weapon_name()
    if held ~= M._last_held_ranged then
        M._last_held = held
        M._last_held_ranged = held
        M._weapon_changed_at = utility and utility.get_tick_count and utility.get_tick_count() or 0
        pcall(function()
            local origin = April.require("game.combat_origin")
            if origin.invalidate then origin.invalidate() end
        end)
        pcall(function()
            local gun_mods = April.require("features.combat.gun_mods")
            if gun_mods.on_weapon_changed then
                gun_mods.on_weapon_changed(held)
            end
        end)
    end

    return held
end

function M.on_modules_ready()
    M.load()
    pcall(function()
        farm_tools = April.require("game.farm_tools")
        if farm_tools.invalidate then farm_tools.invalidate() end
        if farm_tools.load then farm_tools.load() end
    end)
    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        if gun_mods.on_modules_ready then
            gun_mods.on_modules_ready()
        end
    end)
end

return M
