local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")
local gc = April.require("game.gc_weapon_mods")
local env = April.require("core.env")
local notify = April.require("core.notify")

local M = {}
local P = "april_gunmods_enabled"
local REJOIN_GC_DELAY_MS = 20000
local RETRY_MS = 750
local RETRY_MAX_MS = 30000

M._apply_dirty = false
M._last_hash = ""
M._defer_until = 0
M._retry_until = 0
M._session_id = nil
M._was_in_match = false
M._gc_redo_at = 0
M._persist_id = nil
M._notify_next = false

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
    if M._retry_until <= now then
        M._retry_until = now + RETRY_MAX_MS
    end
end

local function clear_apply_state()
    M._apply_dirty = false
    M._last_hash = ""
    M._defer_until = 0
    M._retry_until = 0
    M._gc_redo_at = 0
end

local function stop_persist()
    if M._persist_id and thread and thread.stop then
        pcall(thread.stop, M._persist_id)
    end
    M._persist_id = nil
end

local function start_persist()
    if M._persist_id or not thread or not thread.create then return end
    M._persist_id = thread.create(function()
        if not settings.enabled(P) then return end
        if not profiles.has_gc_mods() then return end
        gc.apply_weapon(profiles.build_mods())
    end, 150)
end

local function schedule_session_gc_refresh()
    if not settings.enabled(P) then return end
    M._last_hash = ""
    M._apply_dirty = true
    M._gc_redo_at = tick_ms() + REJOIN_GC_DELAY_MS
    M._retry_until = tick_ms() + RETRY_MAX_MS
end

function M.on_session_changed()
    schedule_session_gc_refresh()
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.COMBAT)
    local root = menu_util.parent(P)

    menu_util.section(T, G.COMBAT, "Gun Mods")
    menu.add_checkbox(T, G.COMBAT, P, "Enable Gun Mods", false, { key = 0 })

    menu.add_checkbox(T, G.COMBAT, "april_gm_recoil", "Gun Recoil Mod", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_spread", "Gun Spread Mod", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_sway", "Gun No Sway", false, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_fire_rate", "Gun Fire Rate Mod", false, root)
    menu.add_slider_float(T, G.COMBAT, "april_gm_fire_rate_mult", "Fire Rate Multiplier", 1.0, 3.0, 1.5, "%.2f", root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_speed", "Gun Bullet Speed Mod", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_speed_mult", "SpeedMult (100 = instant)", 0, 100, 100, root)

    menu.add_checkbox(T, G.COMBAT, "april_gm_range", "Gun Range Mod", false, root)
    menu.add_slider_int(T, G.COMBAT, "april_gm_range_mult", "RangeMult", 1, 20, 10, root)

    menu_util.bind_master(P, {
        "april_gm_recoil", "april_gm_recoil_pct",
        "april_gm_spread", "april_gm_spread_pct",
        "april_gm_sway",
        "april_gm_fire_rate", "april_gm_fire_rate_mult",
        "april_gm_speed", "april_gm_speed_mult",
        "april_gm_range", "april_gm_range_mult",
    })

    settings.on_change(P, function()
        if settings.enabled(P) then
            M._notify_next = true
            schedule_apply(500)
            start_persist()
        else
            stop_persist()
            clear_apply_state()
            M.reset_mods()
        end
    end)
end

function M.reset_mods()
    if not gc.available() then
        notify.info("Gun mods disabled", 3000)
        return true
    end

    local mods = profiles.build_reset_mods()
    local ok, count, msg = gc.apply_weapon(mods)
    if ok then
        M._last_hash = mods_hash(mods)
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

    if not profiles.has_gc_mods() then
        M._apply_dirty = false
        if not silent then
            notify.warning("Gun mods: enable at least one mod option below master toggle", 4500)
        end
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
        M._retry_until = 0
        if M._notify_next or not silent then
            M._notify_next = false
            notify.success("Gun mods applied: " .. tostring(msg or (count .. " nodes")), 3500)
        end
    else
        M._apply_dirty = true
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

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then return end

    local now = tick_ms()

    if M._gc_redo_at > 0 and now >= M._gc_redo_at then
        M._gc_redo_at = 0
        if in_match() then
            gc.refresh_cache()
            M._apply_dirty = true
            M._defer_until = now
            M._retry_until = now + RETRY_MAX_MS
            notify.info("Re-applying gun mods after session change…", 2500)
        end
    end

    if not M._apply_dirty then return end
    if now < M._defer_until then return end
    if M._retry_until > 0 and now > M._retry_until then
        M._apply_dirty = false
        notify.warning("Gun mods: could not patch — equip gun in match and toggle again", 5000)
        return
    end

    M.try_apply(true)
end

function M.on_weapon_changed(_name) end

function M.on_modules_ready()
    if settings.enabled(P) then
        schedule_apply(500)
        start_persist()
    end
end

function M.draw() end

return M
