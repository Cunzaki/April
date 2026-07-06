--[[ Per-weapon gun mod profiles — persisted separately from config slots. ]]

local settings = April.require("core.settings")
local config_store = April.require("core.config_store")

local M = {}

local FILE = "April_gun_profiles.txt"
local VERSION = 1

local DEFAULT = {
    recoil = false,
    recoil_pct = 100,
    spread = false,
    spread_pct = 100,
    sway = false,
    fire_rate = false,
    fire_rate_mult = 1.5,
    speed = false,
    speed_mult = 100,
    range = false,
    range_mult = 10,
}

local EDITOR_KEYS = {
    recoil = "april_gm_recoil",
    recoil_pct = "april_gm_recoil_pct",
    spread = "april_gm_spread",
    spread_pct = "april_gm_spread_pct",
    sway = "april_gm_sway",
    fire_rate = "april_gm_fire_rate",
    fire_rate_mult = "april_gm_fire_rate_mult",
    speed = "april_gm_speed",
    speed_mult = "april_gm_speed_mult",
    range = "april_gm_range",
    range_mult = "april_gm_range_mult",
}

M._profiles = {}
M._loaded = false

local function file_path()
    return config_store.get_config_path(FILE)
end

function M.default_profile()
    local out = {}
    for k, v in pairs(DEFAULT) do
        out[k] = v
    end
    return out
end

function M.normalize_profile(profile)
    local out = M.default_profile()
    if type(profile) ~= "table" then return out end
    for k in pairs(DEFAULT) do
        if profile[k] ~= nil then
            out[k] = profile[k]
        end
    end
    return out
end

function M.get(weapon_name)
    if not weapon_name or weapon_name == "" then return nil end
    local profile = M._profiles[weapon_name]
    if not profile then return nil end
    return M.normalize_profile(profile)
end

function M.set(weapon_name, profile)
    if not weapon_name or weapon_name == "" then return false end
    M._profiles[weapon_name] = M.normalize_profile(profile)
    M.save()
    return true
end

function M.remove(weapon_name)
    if not weapon_name or weapon_name == "" then return false end
    if not M._profiles[weapon_name] then return false end
    M._profiles[weapon_name] = nil
    M.save()
    return true
end

function M.has_saved(weapon_name)
    return weapon_name and M._profiles[weapon_name] ~= nil
end

function M.has_active_mods(weapon_name)
    local profile = M.get(weapon_name)
    if not profile then return false end
    return profile.recoil or profile.spread or profile.sway
        or profile.fire_rate or profile.speed or profile.range
end

function M.read_editor()
    local profile = M.default_profile()
    for field, id in pairs(EDITOR_KEYS) do
        local default = DEFAULT[field]
        if type(default) == "boolean" then
            profile[field] = settings.bool(id, default)
        elseif type(default) == "number" and math.floor(default) == default then
            profile[field] = settings.num(id, default)
        else
            profile[field] = tonumber(settings.get(id, default)) or default
        end
    end
    return profile
end

function M.write_editor(profile)
    if not menu or not menu.set then return end
    profile = M.normalize_profile(profile)
    for field, id in pairs(EDITOR_KEYS) do
        pcall(menu.set, id, profile[field])
    end
end

function M.save_editor_weapon(weapon_name)
    return M.set(weapon_name, M.read_editor())
end

function M.load_editor_weapon(weapon_name)
    M.write_editor(M.get(weapon_name) or M.default_profile())
end

function M.load_editor_weapon_key(weapon_key)
    M.load_editor_weapon(weapon_key)
end

local function serialize_profile(profile)
    local parts = {}
    for field in pairs(DEFAULT) do
        local val = profile[field]
        if type(val) == "boolean" then
            parts[#parts + 1] = field .. "=" .. (val and "1" or "0")
        else
            parts[#parts + 1] = field .. "=" .. tostring(val)
        end
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

local function parse_profile_line(raw)
    local profile = M.default_profile()
    for token in (raw or ""):gmatch("[^|]+") do
        local field, val = token:match("^([^=]+)=(.+)$")
        if field and DEFAULT[field] ~= nil then
            local default = DEFAULT[field]
            if type(default) == "boolean" then
                profile[field] = val == "1" or val == "true"
            elseif type(default) == "number" and math.floor(default) == default then
                profile[field] = tonumber(val) or default
            else
                profile[field] = tonumber(val) or default
            end
        end
    end
    return profile
end

function M.save()
    local lines = { "version=" .. VERSION }
    local names = {}
    for name in pairs(M._profiles) do
        names[#names + 1] = name
    end
    table.sort(names)
    for _, name in ipairs(names) do
        table.insert(lines, "weapon=" .. name:gsub("\r", " "):gsub("\n", " "))
        table.insert(lines, "data=" .. serialize_profile(M._profiles[name]))
    end

    local f = io.open(file_path(), "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    return true
end

function M.load()
    if M._loaded then return true end
    M._loaded = true
    M._profiles = {}

    local f = io.open(file_path(), "r")
    if not f then return false end

    local current_weapon
    for line in f:lines() do
        local key, val = line:match("^([^=]+)=(.*)$")
        if key == "weapon" then
            current_weapon = val
        elseif key == "data" and current_weapon and current_weapon ~= "" then
            M._profiles[current_weapon] = parse_profile_line(val)
            current_weapon = nil
        end
    end
    f:close()
    return true
end

return M
