local settings = April.require("core.settings")
local store = April.require("game.weapon_profile_store")
local weapons = April.require("game.weapons")

local M = {}

M.GLOBAL_PROFILE_KEY = "__global__"
M.GLOBAL_DISPLAY_NAME = "Global"
M.MODE_ID = "april_gm_mode"
M.MODES = { "Profile Based", "Global" }

local function pct_to_neg_mult(pct)
    pct = math.max(0, math.min(100, pct or 0))
    if pct >= 100 then return -1 end
    return -(pct / 100)
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

function M.build_reset_mods()
    return {
        RecoilMult = 0,
        AimSpreadMult = 0,
        HipSpreadMult = 0,
        SwayMult = 0,
        FireRateMult = 1,
        SpeedMult = 1,
        RangeMult = 1,
    }
end

function M.held_weapon_name()
    return weapons.get_held_ranged_weapon_name()
end

function M.has_gc_mods_for_weapon(name)
    return store.has_active_mods(name)
end

function M.has_gc_mods()
    local held = M.held_weapon_name()
    return held and M.has_gc_mods_for_weapon(held)
end

function M.editor_weapon_key(name)
    if name == M.GLOBAL_DISPLAY_NAME then
        return M.GLOBAL_PROFILE_KEY
    end
    return name
end

function M.is_global_mode()
    return settings.combo_index(M.MODE_ID, M.MODES, 0) == 1
end

function M.build_mods_for_weapon(name)
    local mods = M.build_reset_mods()
    local profile = store.get(name)
    if not profile then return mods end
    local patched = M.build_mods_from_profile(profile)
    for k, v in pairs(patched) do
        mods[k] = v
    end
    return mods
end

function M.build_mods_for_apply(held)
    if M.is_global_mode() then
        if store.has_saved(M.GLOBAL_PROFILE_KEY) then
            return M.build_mods_for_weapon(M.GLOBAL_PROFILE_KEY)
        end
        return nil
    end

    if held and store.has_saved(held) then
        return M.build_mods_for_weapon(held)
    end
    return nil
end

function M.should_apply_for_held(held)
    if not held then return false end
    if M.is_global_mode() then
        return store.has_saved(M.GLOBAL_PROFILE_KEY) and store.has_active_mods(M.GLOBAL_PROFILE_KEY)
    end
    return store.has_saved(held) and store.has_active_mods(held)
end

function M.build_mods()
    local held = M.held_weapon_name()
    if not held then return {} end
    return M.build_mods_for_weapon(held)
end

function M.weapon_combo_names()
    local list = { M.GLOBAL_DISPLAY_NAME }
    for _, name in ipairs(weapons.profile_weapon_names()) do
        list[#list + 1] = name
    end
    return list
end

function M.selected_editor_weapon()
    local names = M.weapon_combo_names()
    if #names == 0 then return nil end
    local idx = settings.combo_index("april_gm_weapon_select", names, 0)
    return names[idx + 1]
end

function M.selected_editor_weapon_key()
    return M.editor_weapon_key(M.selected_editor_weapon())
end

return M
