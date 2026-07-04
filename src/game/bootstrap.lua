--[[
    Lightweight ToolInfo loader for weapon stats / aimbot prediction.
    Uses GC scan only — no instance require (Fallen hides Modules from scripts).
]]

local env = April.require("core.env")
local debug = April.require("core.debug")
local module_scan = April.require("game.module_scan")

local M = {}

M._toolinfo = nil
M._ready = false
M._attempts = 0
M._last_try = 0
M._try_interval = 5000
M._logged_ready = false
M._scan_after = 0
M._defer_ms = 2500

local function in_game_ready()
    if env.get_local_player() then return true end
    if entity and entity.get_players and #entity.get_players() > 0 then return true end
    return false
end

local function try_load_toolinfo()
    local data, n = module_scan.find_toolinfo()
    if data then
        M._toolinfo = data
        M._ready = true
        return true, n or 0
    end
    return false, 0
end

function M.get_module(name)
    if name == "ToolInfo" then
        return M._toolinfo
    end
    return nil
end

function M.is_ready()
    return M._ready
end

local function on_toolinfo_ready(count)
    if M._logged_ready then return end
    M._logged_ready = true
    if April and April.debug then
        debug.log(string.format("ToolInfo ready (%d weapons)", count or 0))
    end

    local weapons = April.require("game.weapons")
    if weapons.on_modules_ready then
        weapons.on_modules_ready()
    else
        weapons.load()
    end
end

function M.try_load_all()
    if M._ready then return true end

    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0

    if not in_game_ready() then
        M._scan_after = 0
        return false
    end

    if M._scan_after == 0 then
        M._scan_after = now + M._defer_ms
    end
    if now < M._scan_after then
        return false
    end

    if M._attempts > 0 and now - M._last_try < M._try_interval then
        return false
    end
    M._last_try = now
    M._attempts = M._attempts + 1

    local ok, count = try_load_toolinfo()
    if ok then
        on_toolinfo_ready(count)
    end

    return M._ready
end

function M.get_status()
    if M._ready then
        return "ToolInfo+scan"
    end
    return "ToolInfo-wait"
end

function M.force_reload()
    M._toolinfo = nil
    M._ready = false
    M._last_try = 0
    M._attempts = 0
    M._logged_ready = false
    M._scan_after = 0
    module_scan.invalidate_cache()
    April.require("game.weapons").invalidate()
    return M.try_load_all()
end

function M.tick()
    if not M._ready then
        M.try_load_all()
    end
end

function M.start_background_retry()
    -- no-op: frame tick is enough; avoids slow startup thread spam
end

return M
