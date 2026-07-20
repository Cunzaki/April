-- RunService sim hooks. Prefer Heartbeat:Connect; fall back to on_frame dispatch.
local env = April.require("core.env")

local M = {}

local _svc = nil
local _svc_checked = false
local _sim_hooks = {}
local _render_hooks = {}
local _heartbeat_conn = nil
local _render_conn = nil
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

local function run_render_hooks(dt)
    for i = 1, #_render_hooks do
        local hook = _render_hooks[i]
        if hook then
            env.safe_call(hook, dt)
        end
    end
end

local function try_connect_render_stepped(svc)
    if not svc then return false end

    local rs = svc.RenderStepped or svc.renderStepped
    if not rs then return false end

    local connect = rs.Connect or rs.connect
    if type(connect) ~= "function" then return false end

    local ok, conn = pcall(function()
        return connect(rs, function(dt)
            run_render_hooks(tonumber(dt) or delta_time())
        end)
    end)
    if ok and conn then
        _render_conn = conn
        return true
    end
    return false
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
        try_connect_render_stepped(svc)
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
    M.get()
    return true
end

function M.on_render(fn)
    if type(fn) ~= "function" then return false end
    _render_hooks[#_render_hooks + 1] = fn
    M.get()
    return true
end

local _bind_names = {}

-- priority_offset: number added to Camera, or "Last" for RenderPriority.Last.
local function render_priority(priority_offset)
    if priority_offset == "Last" or priority_offset == "last" then
        if Enum and Enum.RenderPriority and Enum.RenderPriority.Last then
            local last = Enum.RenderPriority.Last.Value or Enum.RenderPriority.Last
            if type(last) == "number" then return last end
        end
        return 2000
    end

    local offset = tonumber(priority_offset) or 3
    if Enum and Enum.RenderPriority and Enum.RenderPriority.Camera then
        local base = Enum.RenderPriority.Camera.Value or Enum.RenderPriority.Camera
        if type(base) == "number" then return base + offset end
    end
    -- Roblox Camera priority is 200.
    return 200 + offset
end

function M.on_bind_render(name, fn, priority_offset)
    if type(fn) ~= "function" or not name then return false end
    local svc = M.get()
    if not svc then return false end

    local bind = svc.BindToRenderStep or svc.bind_to_render_step
    if type(bind) ~= "function" then return false end

    local prio = render_priority(priority_offset)

    local unbind = svc.UnbindFromRenderStep or svc.unbind_from_render_step
    if type(unbind) == "function" then
        pcall(unbind, svc, name)
    end

    local ok = pcall(function()
        bind(svc, name, prio, function(dt)
            env.safe_call(fn, tonumber(dt) or delta_time())
        end)
    end)

    if ok then _bind_names[name] = true end
    return ok
end

function M.unbind_render(name)
    if not name then return end
    local svc = M.get()
    if not svc then return end
    local unbind = svc.UnbindFromRenderStep or svc.unbind_from_render_step
    if type(unbind) == "function" then
        env.safe_call(unbind, svc, name)
    end
    _bind_names[name] = nil
end

function M.dispatch(dt)
    if _uses_heartbeat then
        local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
        if _last_hb_ms > 0 and (now - _last_hb_ms) < 40 then
            run_render_hooks(dt or delta_time())
            return
        end
    end
    run_sim_hooks(dt or delta_time())
    run_render_hooks(dt or delta_time())
end

return M
