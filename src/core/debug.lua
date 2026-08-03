-- Crash diagnostics: flushed file breadcrumbs survive native Vector crashes.
-- Log path: %LOCALAPPDATA%\Project Vector\Scripts\April_crash.log
-- Last line before a hard crash is the failing stage.

local M = {}

local seen_errors = {}
local frame_count = 0
local log_path = nil
local log_ready = false
local last_step = "boot"
local session_id = tostring(os.time and os.time() or 0)

local function resolve_log_path()
    if log_path then return log_path end
    local base = ""
    pcall(function()
        if os and os.getenv then
            base = os.getenv("LOCALAPPDATA") or ""
        end
    end)
    if base ~= "" then
        log_path = base .. "\\Project Vector\\Scripts\\April_crash.log"
    else
        log_path = "April_crash.log"
    end
    return log_path
end

local function now_stamp()
    local t = 0
    if utility and utility.get_tick_count then
        local ok, v = pcall(utility.get_tick_count)
        if ok and type(v) == "number" then t = v end
    elseif os and os.clock then
        t = math.floor(os.clock() * 1000)
    end
    return t
end

local function write_raw(line)
    local path = resolve_log_path()
    local open = io and io.open
    if not open then
        print(line)
        return false
    end
    local ok = pcall(function()
        local f = open(path, "a")
        if not f then return end
        f:write(line)
        f:write("\n")
        f:flush()
        f:close()
    end)
    return ok == true
end

function M.log_path()
    return resolve_log_path()
end

function M.last_step()
    return last_step
end

function M.begin_session(reason)
    resolve_log_path()
    local open = io and io.open
    if open then
        pcall(function()
            local f = open(log_path, "w")
            if not f then return end
            f:write("==== April crash log ====\n")
            f:write("session=" .. session_id .. "\n")
            f:write("reason=" .. tostring(reason or "start") .. "\n")
            f:write("version=" .. tostring(April and April.version or "?") .. "\n")
            f:write("path=" .. tostring(log_path) .. "\n")
            f:write("started=" .. tostring(os.date and os.date("%Y-%m-%d %H:%M:%S") or "?") .. "\n")
            f:write("note=Last STEP line before a hard crash is the failing stage.\n")
            f:write("====\n")
            f:flush()
            f:close()
        end)
    end
    log_ready = true
    last_step = "session_begin"
    if April and April.crash_trace == true then
        print("[April] crash log -> " .. tostring(log_path))
    end
    return log_path
end

function M.file(msg)
    if not log_ready then
        M.begin_session("lazy")
    end
    local line = string.format("[%d] %s", now_stamp(), tostring(msg))
    write_raw(line)
    if M.enabled() or M.verbose() then
        print("[April LOG] " .. line)
    end
end

-- Breadcrumb: write+flush BEFORE a risky call. Survives native crashes.
function M.step(name)
    last_step = tostring(name or "?")
    if not (April and April.crash_trace == true) and frame_count > 12 then
        return
    end
    if not log_ready then
        M.begin_session("lazy")
    end
    local line = string.format("[%d] STEP %s", now_stamp(), last_step)
    write_raw(line)
end

function M.step_done(name)
    if not (April and April.crash_trace == true) and frame_count > 12 then
        return
    end
    local n = tostring(name or last_step)
    if not log_ready then
        M.begin_session("lazy")
    end
    write_raw(string.format("[%d] DONE %s", now_stamp(), n))
end

function M.enabled()
    return April and April.debug == true
end

function M.verbose()
    return April and April.debug_verbose == true
end

function M.log(msg)
    if M.enabled() then
        M.file(msg)
    end
end

function M.warn(msg)
    M.file("WARN " .. tostring(msg))
end

function M.warn_once(key, msg)
    key = "warn:" .. tostring(key)
    if seen_errors[key] and not M.verbose() then return end
    seen_errors[key] = (seen_errors[key] or 0) + 1
    M.file("WARN[" .. key .. "] " .. tostring(msg))
end

local function traceback_msg(err)
    local ok, msg = pcall(function()
        local s = tostring(err)
        local dbg = rawget(_G, "debug")
        if type(dbg) == "table" and type(dbg.traceback) == "function" then
            local ok_tb, tb = pcall(dbg.traceback, s, 2)
            if ok_tb and type(tb) == "string" and tb ~= "" then
                return tb
            end
        end
        return s
    end)
    if ok and type(msg) == "string" and msg ~= "" then
        return msg
    end
    return "unknown error"
end

function M.error_once(key, err)
    key = tostring(key)
    if seen_errors[key] and not M.verbose() then
        return
    end
    seen_errors[key] = (seen_errors[key] or 0) + 1
    local count = seen_errors[key]
    local suffix = count > 1 and (" (x" .. count .. ")") or ""
    local text = tostring(err) .. suffix
    if not log_ready then
        M.begin_session("lazy")
    end
    write_raw(string.format("[%d] ERROR[%s] %s", now_stamp(), key, text))
    print("[April ERROR][" .. key .. "] " .. text)
end

local function dense_trace()
    if April and April.crash_trace == true then return true end
    return frame_count <= 45
end

function M.guard(key, fn, ...)
    if type(fn) ~= "function" then return nil end
    local dense = dense_trace()
    if dense then M.step(key) end
    local ok, a, b, c = xpcall(fn, traceback_msg, ...)
    if not ok then
        M.error_once(key, a)
        return nil
    end
    if dense then M.step_done(key) end
    return a, b, c
end

function M.guard_bool(key, fn, ...)
    if type(fn) ~= "function" then return false end
    local dense = dense_trace()
    if dense then M.step(key) end
    local ok, result = xpcall(fn, traceback_msg, ...)
    if not ok then
        M.error_once(key, result)
        return false
    end
    if dense then M.step_done(key) end
    return true, result
end

function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        M.error_once("frame_hook", "on_frame handler is not a function")
        return false
    end

    M.step("register_frame_hook")
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

    M.step_done("register_frame_hook")
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
    return { frames = frame_count, errors = seen_errors, last_step = last_step, path = resolve_log_path() }
end

return M
