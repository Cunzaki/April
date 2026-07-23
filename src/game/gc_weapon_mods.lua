-- GC weapon multipliers. Skip refreshgc when warm; rate-limit applygc.
local debug = April.require("core.debug")
local env = April.require("core.env")

local M = {}

M.WEAPON_FIND_KEYS = {
    "RecoilMult",
    "RangeMult",
    "SpeedMult",
    "AimSpreadMult",
    "HipSpreadMult",
    "SwayMult",
    "FireRateMult",
}

M.ALLOWED = {
    RecoilMult = true,
    RangeMult = true,
    SpeedMult = true,
    AimSpreadMult = true,
    HipSpreadMult = true,
    SwayMult = true,
    FireRateMult = true,
}

M._last_node_count = 0
M._last_apply_ms = 0
M._last_refresh_ms = 0
M._fail_streak = 0
M._session_token = nil
M._disabled_until = 0

local MIN_APPLY_GAP_MS = 450
local MIN_REFRESH_GAP_MS = 5000
local FAIL_BACKOFF_MS = 1500
local MAX_FAIL_STREAK = 8
local COOLDOWN_MS = 15000

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function has_api()
    return type(refreshgc) == "function"
        and type(getgc) == "function"
        and type(applygc) == "function"
end

local function session_token()
    if not game then return "none" end
    local pid = game.place_id or 0
    local gid = game.game_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    return tostring(pid) .. ":" .. tostring(gid) .. ":" .. tostring(ws_addr)
end

function M.available()
    return has_api()
end

function M.last_node_count()
    return M._last_node_count
end

function M.in_game()
    return env.get_local_player() ~= nil
end

function M.cooldown_remaining_ms()
    local now = tick_ms()
    if M._disabled_until <= now then return 0 end
    return M._disabled_until - now
end

local function note_failure(reason)
    M._fail_streak = M._fail_streak + 1
    if M._fail_streak >= MAX_FAIL_STREAK then
        M._disabled_until = tick_ms() + COOLDOWN_MS
        M._fail_streak = 0
        M._last_node_count = 0
        debug.warn_once("gun_mods:cooldown", "Gun mods paused after repeated GC failures: " .. tostring(reason))
    end
end

local function note_success(patched)
    M._fail_streak = 0
    M._disabled_until = 0
    if patched and patched > 0 then
        M._last_node_count = math.max(M._last_node_count, patched)
    end
end

local function sanitize_payload(mods)
    local out = {}
    for k, v in pairs(mods) do
        if M.ALLOWED[k] and v ~= nil then
            out[k] = tonumber(v) or v
        end
    end
    return out
end

local function keys_for_payload(payload)
    local keys = {}
    for k in pairs(payload) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

local function warm_nodes(keys)
    local count = 0
    local ok, result = pcall(getgc, keys)
    if ok and type(result) == "number" then
        count = result
    end
    return count
end

local function maybe_refresh(force)
    local now = tick_ms()
    local tok = session_token()
    if tok ~= M._session_token then
        M._session_token = tok
        M._last_node_count = 0
        force = true
    end

    if not force and M._last_node_count > 0 then
        return
    end
    if not force and (now - M._last_refresh_ms) < MIN_REFRESH_GAP_MS then
        return
    end

    pcall(refreshgc)
    M._last_refresh_ms = now
end

function M.apply_weapon(mods, opts)
    opts = opts or {}
    if not has_api() then
        return false, 0, "GC API unavailable"
    end

    local now = tick_ms()
    if M._disabled_until > now then
        return false, 0, "GC cooling down"
    end

    local payload = sanitize_payload(mods)
    if not next(payload) then
        return false, 0, "No modifiers selected"
    end

    if not M.in_game() then
        return false, 0, "Enter a match first"
    end

    local gap = MIN_APPLY_GAP_MS
    if M._fail_streak > 2 then
        gap = FAIL_BACKOFF_MS
    end
    if not opts.force and (now - M._last_apply_ms) < gap then
        return false, 0, "throttled"
    end

    maybe_refresh(opts.force_refresh == true or M._last_node_count <= 0)

    local patch_keys = keys_for_payload(payload)
    local warm = warm_nodes(patch_keys)
    M._last_node_count = math.max(M._last_node_count, warm)

    if warm <= 0 then
        note_failure("no nodes")
        debug.warn_once("gun_mods:nodes", "GC still warming - equip a gun, enable a mod option, keep master on")
        return false, 0, "GC warming - equip gun and wait a moment"
    end

    local patched = 0
    local ok, result = pcall(applygc, patch_keys, payload)
    if ok and type(result) == "number" then
        patched = result
    elseif not ok then
        note_failure(result)
        return false, 0, "GC apply failed"
    end

    M._last_apply_ms = tick_ms()

    if patched > 0 then
        note_success(patched)
        return true, patched, string.format("%d node(s) patched", patched)
    end

    note_failure("zero patch")
    if M._fail_streak == 1 then
        M._last_node_count = 0
    end
    return false, 0, "GC warming - equip gun and wait a moment"
end

function M.apply(mods)
    return M.apply_weapon(mods)
end

function M.apply_once(mods)
    return M.apply_weapon(mods, { force = true })
end

function M.apply_cached(mods)
    return M.apply_weapon(mods)
end

function M.refresh_cache()
    if not has_api() or not M.in_game() then
        M._last_node_count = 0
        return 0
    end

    maybe_refresh(true)
    local count = warm_nodes(M.WEAPON_FIND_KEYS)
    M._last_node_count = count
    return count
end

function M.probe_on_load()
    if not has_api() then return 0 end
    if not M.in_game() then return 0 end
    return M.refresh_cache()
end

function M.status_text()
    if not has_api() then return "GC: unavailable" end
    local cd = M.cooldown_remaining_ms()
    if cd > 0 then
        return string.format("GC cooling down (%ds)", math.ceil(cd / 1000))
    end
    return string.format("GC nodes: %d", M._last_node_count)
end

return M
