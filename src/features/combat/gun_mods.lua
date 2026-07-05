local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local profiles = April.require("game.gun_mod_profiles")
local gc = April.require("game.gc_weapon_mods")
local env = April.require("core.env")

local M = {}
local P = "april_gunmods_enabled"
local REJOIN_GC_DELAY_MS = 20000

M._apply_dirty = false
M._last_hash = ""
M._defer_until = 0
M._session_id = nil
M._was_in_match = false
M._gc_redo_at = 0

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
end

local function schedule_session_gc_refresh()
    if not settings.bool(P, false) then return end
    M._last_hash = ""
    M._apply_dirty = true
    M._gc_redo_at = tick_ms() + REJOIN_GC_DELAY_MS
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

    menu_util.section(T, G.COMBAT, "Target Filters")
    menu.add_checkbox(T, G.COMBAT, "april_combat_skip_downed", "Ignore Downed Players", true, root)

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

    settings.on_change(P, function()
        if settings.bool(P, false) then
            schedule_apply(500)
        else
            M._apply_dirty = false
            M._last_hash = ""
            M._defer_until = 0
            M._gc_redo_at = 0
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

    local ok = gc.apply_weapon(mods)
    if ok then
        M._last_hash = hash
        M._apply_dirty = false
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

    if not settings.bool(P, false) then return end

    local now = tick_ms()

    if M._gc_redo_at > 0 and now >= M._gc_redo_at then
        M._gc_redo_at = 0
        if in_match() then
            gc.refresh_cache()
            M._apply_dirty = true
            M._defer_until = now
        end
    end

    if not M._apply_dirty then return end
    if now < M._defer_until then return end

    M.try_apply()
end

function M.on_weapon_changed(_name) end

function M.on_modules_ready()
    if settings.bool(P, false) then
        schedule_apply(500)
    end
end

function M.draw() end

return M
