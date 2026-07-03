--[[
    April debug — always on by default.
    Errors are deduplicated so the console is readable; re-enable spam with April.debug_verbose = true.
]]

local M = {}

local seen_errors = {}
local frame_count = 0
local last_heartbeat = 0

function M.enabled()
    return not (April and April.debug == false)
end

function M.verbose()
    return April and April.debug_verbose == true
end

function M.log(msg)
    print("[April] " .. tostring(msg))
end

function M.warn(msg)
    print("[April WARN] " .. tostring(msg))
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

function M.audit_apis()
    local required = { "menu", "draw", "utility", "entity", "game" }
    local recommended = { "camera", "input", "raycast", "callbacks" }
    local missing = {}
    local warn = {}

    for _, name in ipairs(required) do
        if _G[name] == nil then table.insert(missing, name) end
    end
    for _, name in ipairs(recommended) do
        if _G[name] == nil then table.insert(warn, name) end
    end

    if #missing > 0 then
        M.warn("Missing required APIs: " .. table.concat(missing, ", "))
        return false, missing
    end
    if #warn > 0 then
        M.warn("Optional APIs missing (some features limited): " .. table.concat(warn, ", "))
    end
    return true
end

function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        M.error_once("frame_hook", "on_frame handler is not a function")
        return false
    end

    -- Vector engine invokes global on_frame() every frame (primary hook).
    _G.on_frame = fn
    M.log("Frame hook: global on_frame()")

    if callbacks and callbacks.add then
        callbacks.add("on_frame", fn)
        M.log("Frame hook: callbacks.add('on_frame')")
    end

    if draw then
        draw.callback = fn
        M.log("Frame hook: draw.callback")
    end

    return true
end

function M.tick_frame()
    frame_count = frame_count + 1
    if not M.enabled() then return end

    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if frame_count == 1 then
        M.log("First frame running (#" .. frame_count .. ")")
    end
    if now - last_heartbeat > 30000 then
        last_heartbeat = now
        local players = entity and entity.get_players and #entity.get_players() or 0
        M.log(string.format("Heartbeat — frames=%d players=%d", frame_count, players))
    end
end

function M.reset_errors()
    seen_errors = {}
end

function M.stats()
    return { frames = frame_count, errors = seen_errors }
end

return M
