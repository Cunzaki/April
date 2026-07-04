--[[
    Per-weapon gun mod profiles (Global + each projectile weapon).
    Editor widgets sync to the active profile; auto-apply reads profiles by weapon name.
]]

local weapons = April.require("game.weapons")

local M = {}

M.GLOBAL = "Global"

-- Every Fallen projectile weapon (guns, bows, crossbows, launchers, spears, nail gun).
M.PROJECTILE_WEAPONS = {
    "Bruno's M4A1",
    "Crossbow",
    "Military AA12",
    "Military Barret",
    "Military Barrett",
    "Military Grenade Launcher",
    "Military M39",
    "Military M4A1",
    "Military MP7",
    "Military PKM",
    "Military USP",
    "Nail Gun",
    "Pumpkin Launcher",
    "Salvaged AK4",
    "Salvaged AK47",
    "Salvaged AK74u",
    "Salvaged Break Action",
    "Salvaged Double Barrel",
    "Salvaged Grenade Launcher",
    "Salvaged M14",
    "Salvaged P250",
    "Salvaged Pipe Rifle",
    "Salvaged Pump Action",
    "Salvaged Python",
    "Salvaged RPG",
    "Salvaged Shotgun",
    "Salvaged Skorpion",
    "Salvaged SMG",
    "Salvaged Sniper",
    "Stone Spear",
    "Wooden Bow",
    "Wooden Spear",
}

M.FIELDS = {
    { key = "recoil", menu = "april_gm_recoil", kind = "bool", default = false },
    { key = "recoil_pct", menu = "april_gm_recoil_pct", kind = "num", default = 100 },
    { key = "spread", menu = "april_gm_spread", kind = "bool", default = false },
    { key = "spread_pct", menu = "april_gm_spread_pct", kind = "num", default = 100 },
    { key = "sway", menu = "april_gm_sway", kind = "bool", default = false },
    { key = "fire_rate", menu = "april_gm_fire_rate", kind = "bool", default = false },
    { key = "fire_rate_mult", menu = "april_gm_fire_rate_mult", kind = "num", default = 1.5 },
    { key = "speed", menu = "april_gm_speed", kind = "bool", default = false },
    { key = "speed_mult", menu = "april_gm_speed_mult", kind = "num", default = 100 },
    { key = "range", menu = "april_gm_range", kind = "bool", default = false },
    { key = "range_mult", menu = "april_gm_range_mult", kind = "num", default = 10 },
}

M._profiles = {}
M._combo_items = nil
M._name_by_index = nil

local function pct_to_neg_mult(pct)
    pct = math.max(0, math.min(100, pct or 0))
    if pct >= 100 then return -1 end
    return -(pct / 100)
end

function M.default_profile()
    local p = {}
    for _, f in ipairs(M.FIELDS) do
        p[f.key] = f.default
    end
    return p
end

function M.weapon_slug(name)
    if not name or name == M.GLOBAL then return "Global" end
    return name:gsub("[^%w]", "_")
end

function M.ensure_profile(name)
    name = name or M.GLOBAL
    if not M._profiles[name] then
        M._profiles[name] = M.default_profile()
    end
    return M._profiles[name]
end

function M.get_profile(name)
    return M.ensure_profile(name)
end

function M.set_profile(name, data)
    M._profiles[name] = data or M.default_profile()
end

function M.merge_toolinfo_weapons()
    weapons.load()
    local names = weapons.recoil_weapon_names()
    local seen = {}
    for _, n in ipairs(M.PROJECTILE_WEAPONS) do
        seen[n] = true
    end
    for _, n in ipairs(names) do
        if not seen[n] then
            seen[n] = true
            table.insert(M.PROJECTILE_WEAPONS, n)
        end
    end
    table.sort(M.PROJECTILE_WEAPONS)
end

function M.combo_items()
    if M._combo_items then return M._combo_items, M._name_by_index end

    M.merge_toolinfo_weapons()

    local items = { M.GLOBAL }
    local name_by_index = { [0] = M.GLOBAL }

    for i, name in ipairs(M.PROJECTILE_WEAPONS) do
        table.insert(items, name)
        name_by_index[i] = name
    end

    M._combo_items = items
    M._name_by_index = name_by_index
    return items, name_by_index
end

function M.name_at_index(idx)
    local _, map = M.combo_items()
    return map[idx or 0] or M.GLOBAL
end

function M.index_for_name(name)
    local items = M.combo_items()
    for i, n in ipairs(items) do
        if n == name then return i - 1 end
    end
    return 0
end

function M.read_editor()
    local p = {}
    for _, f in ipairs(M.FIELDS) do
        if menu and menu.get then
            local v = menu.get(f.menu)
            if v ~= nil then
                p[f.key] = v
            else
                p[f.key] = f.default
            end
        else
            p[f.key] = f.default
        end
    end
    return p
end

function M.write_editor(profile)
    profile = profile or M.default_profile()
    if not menu or not menu.set then return end
    for _, f in ipairs(M.FIELDS) do
        local v = profile[f.key]
        if v == nil then v = f.default end
        menu.set(f.menu, v)
    end
end

function M.sync_editor_to_profile(name)
    M._profiles[name or M.GLOBAL] = M.read_editor()
end

function M.sync_profile_to_editor(name)
    M.write_editor(M.ensure_profile(name))
end

function M.build_mods(profile)
    profile = profile or M.default_profile()
    local mods = {}

    if profile.recoil then
        mods.RecoilMult = pct_to_neg_mult(profile.recoil_pct)
    end
    if profile.spread then
        local m = pct_to_neg_mult(profile.spread_pct)
        mods.AimSpreadMult = m
        mods.HipSpreadMult = m
    end
    if profile.sway then
        mods.SwayMult = -1
    end
    if profile.fire_rate then
        mods.FireRateMult = profile.fire_rate_mult or 1.5
    end
    if profile.speed then
        mods.SpeedMult = profile.speed_mult or 100
    end
    if profile.range then
        mods.RangeMult = profile.range_mult or 10
    end

    return mods
end

function M.mods_for_weapon(held_name, per_weapon)
    local profile_name = M.GLOBAL
    if per_weapon and held_name and held_name ~= "" then
        profile_name = held_name
    end

    local profile = M.ensure_profile(profile_name)
    local mods = M.build_mods(profile)

    if per_weapon and held_name and not next(mods) then
        mods = M.build_mods(M.ensure_profile(M.GLOBAL))
    end

    return mods, profile_name
end

function M.config_prefix()
    return "april_gm_p_"
end

function M.config_key(profile_name, field_key)
    return M.config_prefix() .. M.weapon_slug(profile_name) .. "_" .. field_key
end

local function all_profile_names()
    local names = { M.GLOBAL }
    for _, w in ipairs(M.PROJECTILE_WEAPONS) do
        table.insert(names, w)
    end
    return names
end

function M.import_config_value(id, val)
    local prefix = M.config_prefix()
    if id:sub(1, #prefix) ~= prefix then return false end

    local rest = id:sub(#prefix + 1)
    local field_key = rest:match("_(recoil_pct|recoil|spread_pct|spread|sway|fire_rate_mult|fire_rate|speed_mult|speed|range_mult|range)$")
    if not field_key then return false end

    local slug = rest:sub(1, #rest - #field_key - 1)
    local profile_name = M.GLOBAL
    if slug ~= "Global" then
        for _, w in ipairs(M.PROJECTILE_WEAPONS) do
            if M.weapon_slug(w) == slug then
                profile_name = w
                break
            end
        end
        if profile_name == M.GLOBAL and slug ~= "Global" then
            profile_name = slug:gsub("_", " ")
        end
    end

    local profile = M.ensure_profile(profile_name)
    if val == "true" then profile[field_key] = true
    elseif val == "false" then profile[field_key] = false
    else
        local n = tonumber(val)
        profile[field_key] = n or val
    end
    return true
end

function M.export_config_values()
    local lines = {}
    M.merge_toolinfo_weapons()
    for _, weapon in ipairs(all_profile_names()) do
        local profile = M.ensure_profile(weapon)
        for _, f in ipairs(M.FIELDS) do
            local v = profile[f.key]
            if v ~= nil then
                table.insert(lines, { M.config_key(weapon, f.key), tostring(v) })
            end
        end
    end
    return lines
end

return M
