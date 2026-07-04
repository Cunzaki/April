local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")
local gc = April.require("game.gc_weapon_mods")
local debug = April.require("core.debug")

local M = {}
local P = "april_gunmods_enabled"

M._apply_dirty = false
M._last_hash = ""
M._defer_until = 0

local GM_KEYS = {
    "april_gm_recoil", "april_gm_recoil_pct",
    "april_gm_spread", "april_gm_spread_pct",
    "april_gm_sway",
    "april_gm_fire_rate", "april_gm_fire_rate_mult",
    "april_gm_speed", "april_gm_speed_mult",
    "april_gm_range", "april_gm_range_mult",
}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function mods_hash(mods)
    local parts = {}
    for k, v in pairs(mods) do
        table.insert(parts, k .. "=" .. tostring(v))
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

local function schedule_apply(delay_ms)
    M._apply_dirty = true
    local now = tick_ms()
    local until_ms = now + (delay_ms or 400)
    if until_ms > M._defer_until then
        M._defer_until = until_ms
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.COMBAT)
    local root = menu_util.parent(P)

    menu_util.section(T, G.COMBAT, "Gun Mods")
    menu.add_checkbox(T, G.COMBAT, P, "Enable Gun Mods", false, { key = 0 })
    menu.add_label(T, G.COMBAT, "GC mods apply on toggle only (not weapon swap).", root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_recoil", "Recoil Modifier", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_spread", "Spread Modifier", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_sway", "No Weapon Sway", false, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_fire_rate", "Fire Rate Modifier", false, root)
    menu.add_slider_float(T, G.COMBAT, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f", root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_speed", "Bullet Speed Modifier", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_speed_mult", "SpeedMult (100 = instant)", 0, 100, 100, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_range", "Range Modifier", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_range_mult", "RangeMult", 1, 20, 10, root)

    settings.on_change(P, function()
        if settings.bool(P, false) then
            schedule_apply(500)
        else
            M._apply_dirty = false
            M._last_hash = ""
            M._defer_until = 0
        end
    end)

    for _, id in ipairs(GM_KEYS) do
        settings.on_change(id, function()
            if settings.bool(P, false) then
                schedule_apply(250)
            end
        end)
    end
end

function M.try_apply()
    if not settings.bool(P, false) then
        return false
    end

    if not profiles.has_gc_mods() then
        M._apply_dirty = false
        return false
    end

    local mods = profiles.build_mods()
    if not next(mods) then
        M._apply_dirty = false
        return false
    end

    local hash = mods_hash(mods)
    if not M._apply_dirty and hash == M._last_hash then
        return true
    end

    local ok, count, msg = gc.apply_weapon(mods)
    if ok then
        M._last_hash = hash
        M._apply_dirty = false
        debug.log(msg or ("Gun mods active (" .. tostring(count) .. " nodes)"))
    end

    return ok
end

function M.update(_dt)
    if not settings.bool(P, false) then return end
    if not M._apply_dirty then return end

    local now = tick_ms()
    if now < M._defer_until then return end

    M.try_apply()
end

function M.on_weapon_changed(_name) end

function M.on_modules_ready() end

function M.draw() end

return M
