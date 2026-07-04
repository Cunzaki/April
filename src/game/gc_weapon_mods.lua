--[[
    Fallen weapon mods — Vector globals:

        refreshgc()
        local n = getgc({ "RecoilMult", "RangeMult", ... })
        applygc({ ... })
]]

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

    local count = 0
    local ok_gc, gc_result = pcall(function()
        return getgc(M.WEAPON_FIND_KEYS)
    end)
    if not ok_gc then
        debug.error_once("gun_mods:getgc", gc_result)
        return false, 0, "getgc failed"
    end
    if type(gc_result) == "number" then
        count = gc_result
    end

    M._last_node_count = count
    if count <= 0 then
        debug.warn_once("gun_mods:nodes", "No tables found — enter a match with a gun equipped")
        return false, 0, "No tables found — enter a match first"
    end

    local ok_apply, err_apply = pcall(applygc, payload)
    if not ok_apply then
        debug.error_once("gun_mods:applygc", err_apply)
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
    local count = 0
    pcall(function()
        local n = getgc(M.WEAPON_FIND_KEYS)
        if type(n) == "number" then count = n end
    end)
    M._last_node_count = count
    return count
end

function M.probe_on_load()
    return 0
end

function M.status_text()
    if not has_api() then return "GC: unavailable" end
    return string.format("GC nodes: %d", M._last_node_count)
end

return M
