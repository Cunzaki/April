local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")
local store = April.require("game.weapon_profile_store")
local gc = April.require("game.gc_weapon_mods")
local env = April.require("core.env")
local notify = April.require("core.notify")

local M = {}
local P = "april_gunmods_enabled"
local HELD_ID = "april_gm_held_weapon"
local REJOIN_GC_DELAY_MS = 20000
local RETRY_MS = 750
local RETRY_MAX_MS = 30000

M._apply_dirty = false
M._force_apply = false
M._defer_until = 0
M._retry_until = 0
M._session_id = nil
M._was_in_match = false
M._gc_redo_at = 0
M._notify_next = false
M._last_held_apply = nil
M._held_display = "—"
M._combo_registered = false
M._combo_ctx = nil
M._had_applied_mods = false

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function in_match()
    return env.get_local_player() ~= nil
end

local function session_id()
    if not game then return "none" end
    local pid = game.place_id or 0
    local gid = game.game_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    return pid .. ":" .. gid .. ":" .. ws_addr
end

local function schedule_apply(delay_ms)
    M._apply_dirty = true
    M._force_apply = true
    local now = tick_ms()
    local until_ms = now + (delay_ms or 400)
    if until_ms > M._defer_until then
        M._defer_until = until_ms
    end
    if M._retry_until <= now then
        M._retry_until = now + RETRY_MAX_MS
    end
end

local function clear_apply_state()
    M._apply_dirty = false
    M._force_apply = false
    M._defer_until = 0
    M._retry_until = 0
    M._gc_redo_at = 0
    M._last_held_apply = nil
    M._had_applied_mods = false
end

local function schedule_session_gc_refresh()
    if not settings.enabled(P) then return end
    M._apply_dirty = true
    M._force_apply = true
    M._gc_redo_at = tick_ms() + REJOIN_GC_DELAY_MS
    M._retry_until = tick_ms() + RETRY_MAX_MS
end

local function weapon_names()
    return profiles.weapon_combo_names()
end

local function selected_weapon_key()
    return profiles.selected_editor_weapon_key()
end

local function sync_held_display(held)
    held = held or profiles.held_weapon_name()
    local text = held or "—"
    if held then
        if profiles.is_global_mode() and store.has_saved(profiles.GLOBAL_PROFILE_KEY) then
            text = held .. " (global profile)"
        elseif store.has_saved(held) then
            text = held .. " (saved)"
        else
            text = held .. " (no profile)"
        end
    end
    if text ~= M._held_display then
        M._held_display = text
        if menu and menu.set then
            pcall(menu.set, HELD_ID, text)
        end
    end
end

local function load_selected_editor()
    local key = selected_weapon_key()
    if key then
        store.load_editor_weapon(key)
    end
end

local function ensure_weapon_combo()
    if M._combo_registered or not M._combo_ctx then return end

    local weapons = April.require("game.weapons")
    weapons.load()
    local names = weapon_names()
    if #names == 0 then return end

    local ctx = M._combo_ctx
    menu.add_combo(ctx.T, ctx.G, "april_gm_weapon_select", "Edit Weapon", names, 0, ctx.root)
    M._combo_registered = true
    M._combo_weapon_count = #names
    load_selected_editor()
end

function M.on_session_changed()
    schedule_session_gc_refresh()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.GUN_MODS)
    local root = menu_util.parent(P)

    store.load()

    menu_util.register_keybind(T, G.GUN_MODS, P, "Enable Gun Mods", false)

    menu_util.gap(T, G.GUN_MODS)
    menu_util.input(T, G.GUN_MODS, HELD_ID, "Held Weapon", "—")

    menu.add_combo(T, G.GUN_MODS, profiles.MODE_ID, "Apply Mode", profiles.MODES, 0, root)

    M._combo_ctx = { T = T, G = G.GUN_MODS, root = root }
    ensure_weapon_combo()

    menu_util.gap(T, G.GUN_MODS)
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_recoil", "No Recoil", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_spread", "No Spread", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_sway", "No Sway", false, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_fire_rate", "Fire Rate", false, root)
    menu.add_slider_float(T, G.GUN_MODS, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f", root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_speed", "Bullet Speed", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_speed_mult", "Speed Mult (100 = instant)", 0, 100, 100, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_range", "Range", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_range_mult", "Range Mult", 1, 20, 10, root)

    menu_util.gap(T, G.GUN_MODS)
    menu_util.button(T, G.GUN_MODS, "april_gm_save", "Save Profile", function()
        local key = selected_weapon_key()
        if not key then
            notify.warning("Select a weapon to save", 3500)
            return
        end
        store.save_editor_weapon(key)
        sync_held_display()
        local label = key == profiles.GLOBAL_PROFILE_KEY and "Global" or key
        notify.success("Saved profile: " .. label, 3500)
    end, P)

    menu_util.button(T, G.GUN_MODS, "april_gm_clear", "Clear Saved Profile", function()
        local key = selected_weapon_key()
        if not key then
            notify.warning("Select a weapon to clear", 3500)
            return
        end
        if not store.remove(key) then
            local label = key == profiles.GLOBAL_PROFILE_KEY and "Global" or key
            notify.info("No saved profile for " .. label, 3000)
            return
        end
        store.load_editor_weapon(key)
        sync_held_display()
        local label = key == profiles.GLOBAL_PROFILE_KEY and "Global" or key
        notify.info("Cleared profile: " .. label, 3500)
    end, P)

    menu_util.bind_children(P, {
        HELD_ID, profiles.MODE_ID, "april_gm_weapon_select",
        "april_gm_recoil", "april_gm_recoil_pct",
        "april_gm_spread", "april_gm_spread_pct",
        "april_gm_sway",
        "april_gm_fire_rate", "april_gm_fire_rate_mult",
        "april_gm_speed", "april_gm_speed_mult",
        "april_gm_range", "april_gm_range_mult",
        "april_gm_save", "april_gm_clear",
    })

    settings.on_change("april_gm_weapon_select", function()
        load_selected_editor()
    end)

    settings.on_change(profiles.MODE_ID, function()
        sync_held_display()
    end)

    settings.on_change(P, function()
        if settings.enabled(P) then
            M._notify_next = true
            schedule_apply(500)
        else
            clear_apply_state()
            M.reset_mods()
        end
    end)

    load_selected_editor()
    sync_held_display()
end

function M.reset_mods()
    if not gc.available() then
        notify.info("Gun mods disabled", 3000)
        return true
    end

    local mods = profiles.build_reset_mods()
    local ok, count, msg = gc.apply_weapon(mods)
    if ok then
        M._had_applied_mods = false
        notify.info("Gun mods reset (" .. tostring(count) .. " nodes)", 3500)
    else
        notify.warning("Gun mods reset: " .. tostring(msg or "failed"), 4000)
    end
    return ok
end

function M.try_apply(silent)
    if not settings.enabled(P) then
        return false
    end

    local held = profiles.held_weapon_name()
    if not held then
        if M._had_applied_mods then
            gc.apply_weapon(profiles.build_reset_mods())
            M._had_applied_mods = false
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    local mods = profiles.build_mods_for_apply(held)
    if not mods or not profiles.should_apply_for_held(held) then
        if M._had_applied_mods then
            gc.apply_weapon(profiles.build_reset_mods())
            M._had_applied_mods = false
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    if not M._force_apply and not M._apply_dirty then
        return true
    end

    local ok, count, msg = gc.apply_weapon(mods)
    if ok then
        M._had_applied_mods = true
        M._apply_dirty = false
        M._force_apply = false
        M._retry_until = 0
        if M._notify_next or not silent then
            M._notify_next = false
            local suffix = profiles.is_global_mode() and " (global)" or (" (" .. held .. ")")
            notify.success("Gun mods applied" .. suffix .. ": " .. tostring(msg or (count .. " nodes")), 3500)
        end
    else
        M._apply_dirty = true
        M._force_apply = true
        M._defer_until = tick_ms() + RETRY_MS
    end

    return ok
end

function M.tick_session()
    local sid = session_id()
    local match = in_match()

    if M._session_id == nil then
        M._session_id = sid
        M._was_in_match = match
        return
    end

    if sid ~= M._session_id then
        M._session_id = sid
        M.on_session_changed()
    elseif not M._was_in_match and match then
        M.on_session_changed()
    end

    M._was_in_match = match
end

function M.on_weapon_equip_changed(held)
    if held == M._last_held_apply then return end
    M._last_held_apply = held
    sync_held_display(held)
    if settings.enabled(P) then
        schedule_apply(150)
    end
end

function M.update(_dt)
    M.tick_session()

    local held = profiles.held_weapon_name()
    if held ~= M._last_held_apply then
        M.on_weapon_equip_changed(held)
    end

    if not settings.enabled(P) then return end

    local now = tick_ms()

    if M._gc_redo_at > 0 and now >= M._gc_redo_at then
        M._gc_redo_at = 0
        if in_match() then
            gc.refresh_cache()
            M._apply_dirty = true
            M._force_apply = true
            M._defer_until = now
            M._retry_until = now + RETRY_MAX_MS
            notify.info("Re-applying gun mods after session change…", 2500)
        end
    end

    if not M._apply_dirty then return end
    if now < M._defer_until then return end
    if M._retry_until > 0 and now > M._retry_until then
        M._apply_dirty = false
        M._force_apply = false
        notify.warning("Gun mods: could not patch — equip gun in match and switch weapons", 5000)
        return
    end

    M.try_apply(true)
end

function M.on_weapon_changed(name)
    M.on_weapon_equip_changed(name)
end

function M.on_modules_ready()
    store.load()
    ensure_weapon_combo()
    load_selected_editor()
    sync_held_display()
end

function M.draw() end

return M
