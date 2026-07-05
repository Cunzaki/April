--[[ Fallen weapon mods — Vector globals: refreshgc → getgc(keys) → applygc(keys, values) ]]

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

local function has_api()
    return type(refreshgc) == "function"
        and type(getgc) == "function"
        and type(applygc) == "function"
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
    if count <= 0 then
        ok, result = pcall(getgc, M.WEAPON_FIND_KEYS)
        if ok and type(result) == "number" then
            count = result
        end
    end
    return count
end

local function write_payload(keys, payload)
    -- API.md: applygc(keys, values) — two-arg form (required on current Vector)
    local ok, err = pcall(applygc, keys, payload)
    if ok then return true end

    ok, err = pcall(applygc, M.WEAPON_FIND_KEYS, payload)
    if ok then return true end

    debug.error_once("gun_mods:applygc", err)
    return false
end

function M.apply_weapon(mods)
    if not has_api() then
        return false, 0, "GC API unavailable"
    end

    local payload = sanitize_payload(mods)
    if not next(payload) then
        return false, 0, "No modifiers selected"
    end

    if not M.in_game() then
        return false, 0, "Enter a match first"
    end

    local ok_refresh, err_refresh = pcall(refreshgc)
    if not ok_refresh then
        debug.error_once("gun_mods:refreshgc", err_refresh)
        return false, 0, "refreshgc failed"
    end

    local patch_keys = keys_for_payload(payload)
    local count = warm_nodes(patch_keys)
    M._last_node_count = count

    if count <= 0 then
        debug.warn_once("gun_mods:nodes", "No GC nodes — equip a gun in-game, then toggle Gun Mods")
        return false, 0, "No nodes — equip a gun first"
    end

    if not write_payload(patch_keys, payload) then
        return false, count, "applygc failed"
    end

    return true, count, string.format("%d node(s) — mods active", count)
end

function M.apply(mods)
    return M.apply_weapon(mods)
end

function M.apply_once(mods)
    return M.apply_weapon(mods)
end

function M.apply_cached(mods)
    return M.apply_weapon(mods)
end

function M.refresh_cache()
    if not has_api() or not M.in_game() then
        M._last_node_count = 0
        return 0
    end

    pcall(refreshgc)
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
    return string.format("GC nodes: %d", M._last_node_count)
end

return M
