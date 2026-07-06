--[[
    RunService helper — API 1.4 game.get_service("RunService").
    Vector documents service retrieval; sim hooks always run from on_frame dispatch.
]]

local env = April.require("core.env")

local M = {}

local _svc = nil
local _svc_checked = false
local _sim_hooks = {}

local function delta_time(fallback)
    if utility and utility.get_delta_time then
        return utility.get_delta_time()
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

function M.get()
    if _svc_checked then return _svc end
    _svc_checked = true

    if not game or not game.get_service then return nil end

    local ok, svc = pcall(function()
        return game.get_service("RunService")
    end)

    if ok and svc then
        _svc = svc
    end
    return _svc
end

function M.available()
    return M.get() ~= nil
end

--[[ Movement uses part/camera APIs — only needs game + local player, not RunService events. ]]
function M.movement_allowed()
    if not game then return false end
    return env.get_local_player() ~= nil
end

function M.on_sim(fn)
    if type(fn) ~= "function" then return false end
    _sim_hooks[#_sim_hooks + 1] = fn
    return true
end

function M.dispatch(dt)
    run_sim_hooks(dt or delta_time())
end

return M
