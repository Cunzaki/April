--[[
    Fallen Survival weapon mods — Vector globals (undocumented in GitBook):

        refreshgc()
        local n = getgc({ "RecoilMult", ... })
        applygc({ RecoilMult = -1, ... })
]]

local april_debug = April.require("core.debug")

local M = {}

M.GC_KEYS = {
    "RecoilMult",
    "RangeMult",
    "SpeedMult",
    "AimSpreadMult",
    "HipSpreadMult",
    "SwayMult",
    "FireRateMult",
}

M._last_node_count = 0
M._probed = false
M._last_refresh_at = 0
M._refresh_cooldown_ms = 2500

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

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

local function refresh_nodes(force)
    if not has_api() then return 0 end

    local now = tick_ms()
    if not force and M._last_node_count > 0 and now - M._last_refresh_at < M._refresh_cooldown_ms then
        return M._last_node_count
    end

    pcall(function()
        refreshgc()
    end)
    pcall(function()
        local n = getgc(M.GC_KEYS)
        if type(n) == "number" then
            M._last_node_count = n
        end
    end)

    M._last_refresh_at = now
    return M._last_node_count
end

--[[ One-time startup probe: refreshgc + getgc(keys) only — no applygc. ]]
function M.probe_on_load()
    if M._probed then return M._last_node_count end
    M._probed = true

    if not has_api() then
        return 0
    end

    return refresh_nodes(true)
end

function M.refresh_cache(force)
    return refresh_nodes(force)
end

function M.apply_cached(mods)
    if not has_api() then
        return false, 0, "GC API unavailable (refreshgc/getgc/applygc)"
    end
    if type(mods) ~= "table" or not next(mods) then
        return false, 0, "No modifiers selected"
    end
    if M._last_node_count <= 0 then
        return false, 0, "No GC nodes cached"
    end

    local ok, err = pcall(applygc, mods)
    if not ok then
        april_debug.error_once("gun_mods:applygc", err)
        return false, M._last_node_count, "applygc failed: " .. tostring(err)
    end

    return true, M._last_node_count, string.format("%d node(s) — mods active", M._last_node_count)
end

function M.apply_once(mods)
    if not has_api() then
        return false, 0, "GC API unavailable (refreshgc/getgc/applygc)"
    end
    if type(mods) ~= "table" or not next(mods) then
        return false, 0, "No modifiers selected"
    end

    local count = refresh_nodes(true)
    if count <= 0 then
        return false, 0, "No tables found — enter a match with a gun equipped"
    end

    return M.apply_cached(mods)
end

function M.status_text()
    if not has_api() then return "GC: unavailable" end
    return string.format("GC nodes: %d", M._last_node_count)
end

return M
