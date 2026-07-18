-- RunService sim hooks. Prefer Heartbeat:Connect; fall back to on_frame dispatch.
local env = April.require("core.env")

local M = {}

local _svc = nil
local _svc_checked = false
local _sim_hooks = {}
local _heartbeat_conn = nil
local _uses_heartbeat = false
local _last_hb_ms = 0
local _dispatched_this_frame = false

local function delta_time(fallback)
    if utility and utility.get_delta_time then
        local dt = utility.get_delta_time()
        if dt and dt > 0 then return math.min(dt, 0.1) end
    end
    return fallback or 0.016
end

local function run_sim_hooks(dt)
    for i = 1, #_sim_hooks do
        local hook = _sim_hooks[i]
        if hook then
            env.safe_call(hook, dt)
        end
    end
end

local function try_connect_heartbeat(svc)
    if not svc then return false end

    local hb = svc.Heartbeat or svc.heartbeat
    if not hb then return false end

    local connect = hb.Connect or hb.connect
    if type(connect) ~= "function" then
        -- Some mirrors expose the signal as callable / method on service
        connect = svc.Heartbeat and (svc.Heartbeat.Connect or svc.Heartbeat.connect)
    end
    if type(connect) ~= "function" then return false end

    local ok, conn = pcall(function()
        return connect(hb, function(dt)
            _uses_heartbeat = true
            _last_hb_ms = utility and utility.get_tick_count and utility.get_tick_count() or 0
            run_sim_hooks(tonumber(dt) or delta_time())
        end)
    end)
    if ok and conn then
        _heartbeat_conn = conn
        _uses_heartbeat = true
        return true
    end
    return false
end

function M.get()
    if _svc_checked then return _svc end
    _svc_checked = true

    if not game or not game.get_service then return nil end

    local ok, svc = pcall(function()
        return game.get_service("RunService")
    end)

    if ok and svc then
        _svc = svc
        try_connect_heartbeat(svc)
    end
    return _svc
end

function M.available()
    return M.get() ~= nil
end

function M.uses_heartbeat()
    M.get()
    return _uses_heartbeat == true
end

function M.movement_allowed()
    if not game then return false end
    return env.get_local_player() ~= nil
end

function M.on_sim(fn)
    if type(fn) ~= "function" then return false end
    _sim_hooks[#_sim_hooks + 1] = fn
    -- Ensure Heartbeat probe runs even if install happens before first get()
    M.get()
    return true
end

function M.dispatch(dt)
    -- Heartbeat is preferred, but keep on_frame dispatch as fallback if HB stalls.
    if _uses_heartbeat then
        local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
        if _last_hb_ms > 0 and (now - _last_hb_ms) < 40 then
            return
        end
    end
    run_sim_hooks(dt or delta_time())
end

return M
