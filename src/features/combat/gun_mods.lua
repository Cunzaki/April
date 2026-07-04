local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local weapons = April.require("game.weapons")
local profiles = April.require("game.gun_mod_profiles")
local gc = April.require("game.gc_weapon_mods")

local M = {}
local P = "april_gunmods_enabled"

M._editing = profiles.GLOBAL
M._last_applied_weapon = nil
M._last_applied_profile = nil
M._apply_dirty = false
M._needs_refresh = false
M._last_retry = 0
M._retry_ms = 2500

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function request_apply(refresh)
    M._apply_dirty = true
    if refresh then
        M._needs_refresh = true
    end
end

local function switch_profile(idx)
    profiles.sync_editor_to_profile(M._editing)
    M._editing = profiles.name_at_index(idx)
    profiles.sync_profile_to_editor(M._editing)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.AIMBOT)
    local root = menu_util.parent(P)

    local combo_items = profiles.combo_items()

    menu_util.section(T, G.AIMBOT, "Gun Mods")
    menu.add_checkbox(T, G.AIMBOT, P, "Enable Gun Mods", false, { key = 0 })
    menu.add_checkbox(T, G.AIMBOT, "april_gm_auto_detect", "Auto Weapon Detection", true, root)
    menu.add_checkbox(T, G.AIMBOT, "april_gm_per_weapon", "Per-Weapon Profiles", false, root)
    menu.add_combo(T, G.AIMBOT, "april_gm_profile", "Edit Profile", combo_items, 0, root)
    menu.add_button(T, G.AIMBOT, "april_gm_save", "Save Profile", function()
        profiles.sync_editor_to_profile(M._editing)
        print("[April Gun Mods] Saved profile: " .. M._editing)
    end)
    menu.add_label(T, G.AIMBOT, "Save stores settings only. Auto-apply runs on weapon swap.", root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_recoil", "Recoil Modifier", false, root)
    menu.add_slider_int(T, G.AIMBOT, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_spread", "Spread Modifier", false, root)
    menu.add_slider_int(T, G.AIMBOT, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_sway", "No Weapon Sway", false, root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_fire_rate", "Fire Rate Modifier", false, root)
    menu.add_slider_float(T, G.AIMBOT, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f", root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_speed", "Bullet Speed Modifier", false, root)
    menu.add_slider_int(T, G.AIMBOT, "april_gm_speed_mult", "SpeedMult (100 = instant)", 0, 100, 100, root)

    menu.add_checkbox(T, G.AIMBOT, "april_gm_range", "Range Modifier", false, root)
    menu.add_slider_int(T, G.AIMBOT, "april_gm_range_mult", "RangeMult", 1, 20, 10, root)

    settings.on_change("april_gm_profile", switch_profile)
    settings.on_change(P, function() request_apply(true) end)
    settings.on_change("april_gm_auto_detect", function() request_apply(false) end)
    settings.on_change("april_gm_per_weapon", function() request_apply(false) end)

    profiles.sync_profile_to_editor(M._editing)
end

function M.try_apply(held)
    if not settings.bool(P, false) then
        M._last_applied_weapon = nil
        M._last_applied_profile = nil
        M._apply_dirty = false
        M._needs_refresh = false
        return false
    end

    local auto_detect = settings.bool("april_gm_auto_detect", true)
    local per_weapon = settings.bool("april_gm_per_weapon", false)

    local apply_held = held
    if not auto_detect then
        apply_held = nil
    end

    local mods, profile_name = profiles.mods_for_weapon(apply_held, per_weapon)
    if not next(mods) then
        M._apply_dirty = false
        return false
    end

    local weapon_key = apply_held or "__global__"
    if weapon_key == M._last_applied_weapon
        and profile_name == M._last_applied_profile
        and not M._apply_dirty then
        return true
    end

    local ok
    if M._needs_refresh or gc.last_node_count() <= 0 then
        ok = gc.apply_once(mods)
        M._needs_refresh = false
    else
        ok = gc.apply_cached(mods)
        if not ok and gc.last_node_count() <= 0 then
            ok = gc.apply_once(mods)
            M._needs_refresh = false
        end
    end

    if ok then
        M._last_applied_weapon = weapon_key
        M._last_applied_profile = profile_name
        M._apply_dirty = false
    end

    return ok
end

function M.update(dt)
    if not settings.bool(P, false) then return end

    local held = weapons._last_held
    local now = tick_ms()

    if M._apply_dirty or held ~= M._last_applied_weapon then
        M.try_apply(held)
    elseif held and now - M._last_retry >= M._retry_ms and M._apply_dirty then
        M._last_retry = now
        M._needs_refresh = true
        M.try_apply(held)
    end
end

function M.on_weapon_changed(name)
    request_apply(true)
end

function M.on_modules_ready()
    profiles.merge_toolinfo_weapons()
end

function M.draw() end

return M
