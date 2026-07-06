--[[ Global gun mod values — map menu sliders to applygc keys. ]]

local settings = April.require("core.settings")

local M = {}

local function pct_to_neg_mult(pct)
    pct = math.max(0, math.min(100, pct or 0))
    if pct >= 100 then return -1 end
    return -(pct / 100)
end

function M.has_gc_mods()
    return settings.bool("april_gm_recoil", false)
        or settings.bool("april_gm_spread", false)
        or settings.bool("april_gm_sway", false)
        or settings.bool("april_gm_fire_rate", false)
        or settings.bool("april_gm_speed", false)
        or settings.bool("april_gm_range", false)
end

function M.build_mods()
    local mods = {}

    if settings.bool("april_gm_recoil", false) then
        mods.RecoilMult = pct_to_neg_mult(settings.num("april_gm_recoil_pct", 100))
    end
    if settings.bool("april_gm_spread", false) then
        local m = pct_to_neg_mult(settings.num("april_gm_spread_pct", 100))
        mods.AimSpreadMult = m
        mods.HipSpreadMult = m
    end
    if settings.bool("april_gm_sway", false) then
        mods.SwayMult = -1
    end
    if settings.bool("april_gm_fire_rate", false) then
        mods.FireRateMult = settings.num("april_gm_fire_rate_mult", 1.5)
    end
    if settings.bool("april_gm_speed", false) then
        mods.SpeedMult = settings.num("april_gm_speed_mult", 100)
    end
    if settings.bool("april_gm_range", false) then
        mods.RangeMult = settings.num("april_gm_range_mult", 10)
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

return M
