local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")
local gc = April.require("game.gc_weapon_mods")
local toolinfo_mods = April.require("game.toolinfo_weapon_mods")
local env = April.require("core.env")
local notify = April.require("core.notify")

local M = {}
local P = "april_gunmods_enabled"
local REJOIN_GC_DELAY_MS = 25000
local RETRY_MS = 1200
local RETRY_MAX_MS = 15000
local MIN_SCHEDULE_MS = 450
local STARTUP_DELAY_MS = 3500

M._apply_dirty = false
M._force_apply = false
M._defer_until = 0
M._retry_until = 0
M._session_id = nil
M._was_in_match = false
M._gc_redo_at = 0
M._notify_next = false
M._last_held_apply = nil
M._had_applied_mods = false
M._last_applied_keys = nil
M._boot_ms = nil

local MODIFIER_TOGGLES = {
    "april_gm_recoil",
    "april_gm_spread",
    "april_gm_sway",
    "april_gm_fire_rate",
    "april_gm_speed",
    "april_gm_range",
    "april_gm_double_tap",
}

local function tick_ms()
    if M._boot_ms == nil then
        M._boot_ms = utility and utility.get_tick_count and utility.get_tick_count() or 0
    end
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

local function startup_ready()
    local now = tick_ms()
    return M._boot_ms and (now - M._boot_ms) >= STARTUP_DELAY_MS
end

local function can_apply_now()
    if not settings.enabled(P) then return false end
    if not startup_ready() then return false end
    if not gc.available() then return false end
    if gc.cooldown_remaining_ms() > 0 then return false end
    if not in_match() then return false end
    if not profiles.held_weapon_name() then return false end
    return true
end

local function schedule_apply(delay_ms)
    if not settings.enabled(P) then return end
    M._apply_dirty = true
    M._force_apply = true
    local now = tick_ms()
    local wait = math.max(MIN_SCHEDULE_MS, delay_ms or 500)
    local until_ms = now + wait
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
    M._last_applied_keys = nil
end

local function build_clear_payload()
    local keys = M._last_applied_keys
    if not keys or not next(keys) then
        return nil
    end
    local out = {}
    for k in pairs(keys) do
        out[k] = 0
    end
    return out
end

local function remember_applied(mods)
    local keys = {}
    if type(mods) == "table" then
        for k in pairs(mods) do
            keys[k] = true
        end
    end
    M._last_applied_keys = keys
end

local function schedule_session_gc_refresh()
    if not settings.enabled(P) then return end
    M._apply_dirty = true
    M._force_apply = true
    M._gc_redo_at = tick_ms() + REJOIN_GC_DELAY_MS
    M._retry_until = tick_ms() + RETRY_MAX_MS
    M._defer_until = tick_ms() + REJOIN_GC_DELAY_MS
    toolinfo_mods.invalidate()
end

local function clear_all_mods()
    pcall(function()
        local clear = build_clear_payload()
        if clear then gc.apply_weapon(clear) end
    end)
    pcall(toolinfo_mods.reset)
    M._had_applied_mods = false
    M._last_applied_keys = nil
end

function M.schedule_apply(delay_ms)
    schedule_apply(delay_ms)
end

function M.on_session_changed()
    schedule_session_gc_refresh()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.GUN_MODS)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.GUN_MODS, P, "Enable Gun Mods", false)

    menu_util.section(T, G.GUN_MODS, "Modifiers")
    menu.add_checkbox(T, G.GUN_MODS, "april_gm_recoil", "No Recoil", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100,
        menu_util.parent("april_gm_recoil"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_spread", "No Spread", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100,
        menu_util.parent("april_gm_spread"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_sway", "No Sway", false, root)

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_fire_rate", "Fire Rate", false, root)
    menu.add_slider_float(T, G.GUN_MODS, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f",
        menu_util.parent("april_gm_fire_rate"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_speed", "Bullet Speed", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_speed_mult", "Speed Mult", 1, 100, 100,
        menu_util.parent("april_gm_speed"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_range", "Gun Range", false, root)
    menu.add_slider_int(T, G.GUN_MODS, "april_gm_range_mult", "Range Mult", 1, 20, 10,
        menu_util.parent("april_gm_range"))

    menu.add_checkbox(T, G.GUN_MODS, "april_gm_double_tap", "Double Tap", false, root)

    menu_util.bind_children(P, {
        "april_gm_recoil", "april_gm_recoil_pct",
        "april_gm_spread", "april_gm_spread_pct",
        "april_gm_sway",
        "april_gm_fire_rate", "april_gm_fire_rate_mult",
        "april_gm_speed", "april_gm_speed_mult",
        "april_gm_range", "april_gm_range_mult",
        "april_gm_double_tap",
    })

    menu_util.bind_children("april_gm_recoil", { "april_gm_recoil_pct" })
    menu_util.bind_children("april_gm_spread", { "april_gm_spread_pct" })
    menu_util.bind_children("april_gm_fire_rate", { "april_gm_fire_rate_mult" })
    menu_util.bind_children("april_gm_speed", { "april_gm_speed_mult" })
    menu_util.bind_children("april_gm_range", { "april_gm_range_mult" })

    settings.on_change(P, function()
        if settings.enabled(P) then
            M._notify_next = true
            schedule_apply(800)
        else
            clear_apply_state()
            M.reset_mods()
        end
    end)

    for _, id in ipairs(MODIFIER_TOGGLES) do
        settings.on_change(id, function()
            if settings.enabled(P) then
                M._notify_next = true
                schedule_apply(500)
            end
        end)
    end

    local slider_ids = {
        "april_gm_recoil_pct", "april_gm_spread_pct",
        "april_gm_fire_rate_mult", "april_gm_speed_mult", "april_gm_range_mult",
    }
    for _, id in ipairs(slider_ids) do
        settings.on_change(id, function()
            if settings.enabled(P) then
                schedule_apply(1000)
            end
        end)
    end
end

function M.reset_mods()
    pcall(toolinfo_mods.reset)

    if not gc.available() then
        notify.info("Gun mods disabled", 3000)
        return true
    end

    local mods = build_clear_payload()
    if not mods then
        M._had_applied_mods = false
        notify.info("Gun mods cleared", 3000)
        return true
    end

    local ok, count, msg = gc.apply_weapon(mods)
    if ok then
        M._had_applied_mods = false
        M._last_applied_keys = nil
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

    if not can_apply_now() then
        if M._had_applied_mods and not in_match() then
            clear_all_mods()
        end
        return false
    end

    local held = profiles.held_weapon_name()
    if not held then
        if M._had_applied_mods then
            clear_all_mods()
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    if not profiles.should_apply_for_held(held) then
        if M._had_applied_mods then
            clear_all_mods()
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    local mods = profiles.build_mods_for_apply(held)
    local ti_opts, ti_weapon = profiles.build_toolinfo_for_apply(held)
    local has_gc = mods and next(mods)
    local has_ti = ti_opts and ti_opts.double_tap == true

    if not has_gc and not has_ti then
        if M._had_applied_mods then
            clear_all_mods()
        end
        M._apply_dirty = false
        M._force_apply = false
        return false
    end

    if not M._force_apply and not M._apply_dirty then
        return true
    end

    local ok_gc, count, msg = true, 0, nil
    if has_gc then
        ok_gc, count, msg = gc.apply_weapon(mods)
        if ok_gc then
            remember_applied(mods)
        end
    else
        local clear = build_clear_payload()
        if clear then
            pcall(gc.apply_weapon, clear)
        end
        M._last_applied_keys = nil
    end

    local ok_ti = true
    local ti_count, ti_msg
    if has_ti then
        ok_ti, ti_count, ti_msg = toolinfo_mods.apply(ti_opts, ti_weapon or held)
    else
        pcall(toolinfo_mods.reset)
    end

    local ok = (not has_gc or ok_gc) and ok_ti
    if ok then
        M._had_applied_mods = true
        M._apply_dirty = false
        M._force_apply = false
        M._retry_until = 0
        if M._notify_next or not silent then
            M._notify_next = false
            local parts = {}
            if has_gc then
                parts[#parts + 1] = tostring(msg or (tostring(count) .. " nodes"))
            end
            if has_ti and ti_count and ti_count > 0 then
                parts[#parts + 1] = tostring(ti_msg or (tostring(ti_count) .. " burst"))
            end
            notify.success("Gun mods applied: " .. table.concat(parts, ", "), 3500)
        end
    else
        M._apply_dirty = true
        M._force_apply = true
        M._defer_until = tick_ms() + RETRY_MS
        if gc.cooldown_remaining_ms() > 0 then
            M._apply_dirty = false
            M._force_apply = false
        end
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
    if settings.enabled(P) then
        schedule_apply(600)
    end
end

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then return end

    local held = profiles.held_weapon_name()
    if held ~= M._last_held_apply then
        M.on_weapon_equip_changed(held)
    end

    local now = tick_ms()

    if M._gc_redo_at > 0 and now >= M._gc_redo_at then
        M._gc_redo_at = 0
        if in_match() then
            pcall(gc.refresh_cache)
            toolinfo_mods.invalidate()
            M._apply_dirty = true
            M._force_apply = true
            M._defer_until = now + 800
            M._retry_until = now + RETRY_MAX_MS
            notify.info("Re-applying gun mods after session change...", 2500)
        end
    end

    if not M._apply_dirty then return end
    if now < M._defer_until then return end
    if not can_apply_now() then return end
    if M._retry_until > 0 and now > M._retry_until then
        M._apply_dirty = false
        M._force_apply = false
        notify.warning("Gun mods: equip a gun in match, then toggle a mod option", 5000)
        return
    end

    M.try_apply(true)
end

function M.on_weapon_changed(name)
    M.on_weapon_equip_changed(name)
end

function M.on_modules_ready()
    toolinfo_mods.invalidate()
    if settings.enabled(P) then
        schedule_apply(1200)
    end
end

function M.draw() end

return M
