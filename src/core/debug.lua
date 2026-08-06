-- Lightweight fault isolation only. No file logging, no console spam.
local M = {}

local seen_errors = {}
local frame_count = 0

function M.log_path()
    return nil
end

function M.last_step()
    return ""
end

function M.begin_session(_reason)
    return nil
end

function M.file(_msg) end
function M.step(_name) end
function M.step_done(_name) end
function M.force_step(_name) end
function M.force_event(_message) end

function M.enabled()
    return false
end

function M.verbose()
    return false
end

function M.log(_msg) end
function M.warn(_msg) end
function M.warn_once(_key, _msg) end

function M.error_once(_key, _err)
    -- Swallow: no prints / no disk writes in production.
end

function M.guard(key, fn, ...)
    return M.guard_fast(key, fn, ...)
end

function M.guard_fast(_key, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        return nil
    end
    return a, b, c
end

function M.guard_bool(_key, fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, result = pcall(fn, ...)
    if not ok then
        return false
    end
    return true, result
end

function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        return false
    end
    _G.OnFrame = fn
    _G.onFrame = fn
    _G.on_frame = fn
    if callbacks and callbacks.add then
        pcall(callbacks.add, "on_frame", fn)
        pcall(callbacks.add, "OnFrame", fn)
    end
    if draw then
        draw.callback = fn
    end
    return true
end

function M.tick_frame()
    frame_count = frame_count + 1
end

function M.frame_count()
    return frame_count
end

function M.reset_errors()
    seen_errors = {}
end

function M.stats()
    return { frames = frame_count, errors = seen_errors }
end

return M
