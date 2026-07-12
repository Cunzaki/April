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

function M.build_toolinfo_opts(profile)
    if not profile then
        return { double_tap = false }
    end
    return { double_tap = profile.double_tap == true }
end

-- Neutral attachment-style mults (game uses 1 + Mult for speed/range/sway/spread/recoil,
-- and delay *= 1 - FireRateMult). Only used when disabling gun mods / clearing apply.
-- Do NOT merge these into active apply payloads — that stomps attachment FireRateMult etc.
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
    -- Only keys the profile actually enables. Writing FireRateMult=1 (or any default)
    -- onto every GC table that has FireRateMult overwrites attachment FireRateMult
    -- (Items.AttachmentStats) and breaks RPM when attachments are equipped.
    local profile = store.get(name)
    if not profile then return {} end
    return M.build_mods_from_profile(profile)
end

-- Live menu toggles/sliders — no saved profile required.
function M.editor_profile()
    return store.read_editor()
end

function M.build_mods_for_apply(_held)
    if not store.editor_has_active_mods() then return nil end
    return M.build_mods_from_profile(M.editor_profile())
end

function M.build_toolinfo_for_apply(held)
    if not store.editor_has_active_mods() then return nil, nil end
    local profile = M.editor_profile()
    local opts = M.build_toolinfo_opts(profile)
    if M.is_global_mode() then
        return opts, nil
    end
    return opts, held
end

function M.should_apply_for_held(held)
    if not held then return false end
    return store.editor_has_active_mods()
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
