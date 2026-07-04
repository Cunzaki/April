--[[
    April debug — always on by default.
    Errors are deduplicated so the console is readable; re-enable spam with April.debug_verbose = true.
]]

local M = {}

local seen_errors = {}
local frame_count = 0
local last_heartbeat = nil

function M.enabled()
    return not (April and April.debug == false)
end

function M.verbose()
    return April and April.debug_verbose == true
end

function M.log(msg)
    if not M.enabled() then return end
    print("[April] " .. tostring(msg))
end

function M.warn(msg)
    if not M.enabled() then return end
    print("[April WARN] " .. tostring(msg))
end

function M.warn_once(key, msg)
    M.error_once("warn:" .. key, msg)
end

function M.error_once(key, err)
    key = tostring(key)
    if seen_errors[key] and not M.verbose() then return end
    seen_errors[key] = (seen_errors[key] or 0) + 1
    local count = seen_errors[key]
    local suffix = count > 1 and (" (x" .. count .. ")") or ""
    print("[April ERROR][" .. key .. "] " .. tostring(err) .. suffix)
    if debug and debug.traceback then
        print(debug.traceback(err, 2))
    end
end

function M.guard(key, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        M.error_once(key, a)
        return nil
    end
    return a, b, c
end

function M.guard_bool(key, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        M.error_once(key, result)
        return false
    end
    return true, result
end

function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        M.error_once("frame_hook", "on_frame handler is not a function")
        return false
    end

    -- Vector engine invokes global on_frame() every frame (primary hook).
    _G.on_frame = fn

    if callbacks and callbacks.add then
        callbacks.add("on_frame", fn)
    end

    if draw then
        draw.callback = fn
    end

    return true
end

function M.tick_frame()
    frame_count = frame_count + 1
    if not M.enabled() then return end

    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if last_heartbeat == nil then
        last_heartbeat = now
    end
    if now - last_heartbeat > 30000 then
        last_heartbeat = now
        local players = entity and entity.get_players and #entity.get_players() or 0
        local bootstrap = April.require("game.bootstrap")
        M.log(string.format("Heartbeat — frames=%d players=%d modules=%s %s",
            frame_count, players,
            bootstrap.is_ready() and "OK" or "wait",
            bootstrap.get_status and bootstrap.get_status() or ""))
    end
end

function M.reset_errors()
    seen_errors = {}
end

function M.stats()
    return { frames = frame_count, errors = seen_errors }
end

return M
