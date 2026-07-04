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

--[[ One-time startup probe: refreshgc + getgc(keys) only — no applygc. ]]
function M.probe_on_load()
    if M._probed then return M._last_node_count end
    M._probed = true

    if not has_api() then
        return 0
    end

    local count = 0
    pcall(function()
        refreshgc()
    end)
    pcall(function()
        local n = getgc(M.GC_KEYS)
        if type(n) == "number" then
            count = n
        end
    end)

    M._last_node_count = count
    return count
end

function M.apply_once(mods)
    if not has_api() then
        return false, 0, "GC API unavailable (refreshgc/getgc/applygc)"
    end
    if type(mods) ~= "table" or not next(mods) then
        return false, 0, "No modifiers selected"
    end

    local count = 0
    pcall(function()
        refreshgc()
    end)
    pcall(function()
        local n = getgc(M.GC_KEYS)
        if type(n) == "number" then
            count = n
        end
    end)

    M._last_node_count = count
    if count <= 0 then
        return false, 0, "No tables found — enter a match with a gun equipped"
    end

    local ok, err = pcall(applygc, mods)
    if not ok then
        april_debug.error_once("gun_mods:applygc", err)
        return false, count, "applygc failed: " .. tostring(err)
    end

    return true, count, string.format("%d node(s) cached — mods active", count)
end

function M.status_text()
    if not has_api() then return "GC: unavailable" end
    return string.format("GC nodes: %d", M._last_node_count)
end

return M
