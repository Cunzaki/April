local settings = April.require("core.settings")
local weapons = April.require("game.weapons")

local M = {}

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
    double_tap = false,
}

local SETTING_KEYS = {
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
    double_tap = "april_gm_double_tap",
}

local function pct_to_neg_mult(pct)
    pct = math.max(0, math.min(100, pct or 0))
    if pct >= 100 then return -1 end
    return -(pct / 100)
end

function M.fire_rate_mult(slider)
    slider = math.max(1, math.min(3, tonumber(slider) or 1.5))
    local t = (slider - 1) / 2
    return 0.12 + t * (0.99 - 0.12)
end

function M.read_settings()
    local profile = {}
    for field, default in pairs(DEFAULT) do
        profile[field] = default
    end
    for field, id in pairs(SETTING_KEYS) do
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

function M.profile_has_active_mods(profile)
    if not profile then return false end
    return profile.recoil or profile.spread or profile.sway
        or profile.fire_rate or profile.speed or profile.range
        or profile.double_tap
end

function M.editor_has_active_mods()
    return M.profile_has_active_mods(M.read_settings())
end

function M.build_mods_from_profile(profile)
    local mods = {}
    if not profile then return mods end

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
        mods.FireRateMult = M.fire_rate_mult(profile.fire_rate_mult)
    end
    if profile.speed then
        mods.SpeedMult = profile.speed_mult or 100
    end
    if profile.range then
        mods.RangeMult = profile.range_mult or 10
    end

    return mods
end

function M.build_toolinfo_opts(profile)
    if not profile then
        return { double_tap = false }
    end
    return { double_tap = profile.double_tap == true }
end

function M.build_reset_mods()
    return {
        RecoilMult = 0,
        AimSpreadMult = 0,
        HipSpreadMult = 0,
        SwayMult = 0,
        FireRateMult = 0,
        SpeedMult = 0,
        RangeMult = 0,
    }
end

function M.held_weapon_name()
    return weapons.get_held_ranged_weapon_name()
end

function M.build_mods_for_apply(_held)
    if not M.editor_has_active_mods() then return nil end
    return M.build_mods_from_profile(M.read_settings())
end

function M.build_toolinfo_for_apply(held)
    if not M.editor_has_active_mods() then return nil, nil end
    return M.build_toolinfo_opts(M.read_settings()), held
end

function M.should_apply_for_held(held)
    if not held then return false end
    return M.editor_has_active_mods()
end

return M
