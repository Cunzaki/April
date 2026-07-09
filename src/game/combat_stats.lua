local settings = April.require("core.settings")
local weapons = April.require("game.weapons")

local M = {}

local function profiles_mod()
    return April.require("game.gun_mod_profiles")
end

local function store_mod()
    return April.require("game.weapon_profile_store")
end

local function inventory_mod()
    return April.require("game.inventory")
end

local function profile_speed_mult(held)
    if not settings.enabled("april_gunmods_enabled") then return 0 end

    if settings.enabled("april_gm_speed") then
        return settings.num("april_gm_speed_mult", 100)
    end

    if not held then return 0 end

    local profiles = profiles_mod()
    local store = store_mod()

    if profiles.is_global_mode() then
        if not store.has_saved(profiles.GLOBAL_PROFILE_KEY) then return 0 end
        local p = store.get(profiles.GLOBAL_PROFILE_KEY)
        if not p or not p.speed then return 0 end
        return p.speed_mult or 0
    end

    if store.has_saved(held) then
        local p = store.get(held)
        if p and p.speed then return p.speed_mult or 0 end
    end

    return 0
end

local function ammo_modifiers()
    local inv = inventory_mod()
    if not inv or not inv.get_equipped_ammo_stats then
        return 1, 1
    end
    local ammo = inv.get_equipped_ammo_stats()
    if not ammo then return 1, 1 end
    return ammo.speed_mult or 1, ammo.gravity_mult or 1
end

function M.get_effective_stats(weapon_name)
    weapon_name = weapon_name or weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name()
    local base = weapons.get_weapon_stats(weapon_name)
    if not base then
        base = { speed = 950, gravity = 0.55, name = weapon_name or "Unknown" }
    end

    local speed = base.speed or 950
    local gravity = base.gravity or 0.55
    local is_bow = base.is_bow
        or (weapon_name and (weapon_name:find("Bow", 1, true) or weapon_name:find("Crossbow", 1, true)))

    local sm = profile_speed_mult(weapon_name)
    if sm ~= 0 then
        speed = speed * (1 + sm)
    end

    local ammo_speed, ammo_grav = ammo_modifiers()
    speed = speed * ammo_speed
    gravity = gravity * ammo_grav

    return {
        speed = speed,
        gravity = gravity,
        name = weapon_name or base.name,
        is_bow = is_bow == true,
        base_speed = base.speed,
        speed_mult = sm,
        ammo_speed_mult = ammo_speed,
        ammo_gravity_mult = ammo_grav,
    }
end

return M
