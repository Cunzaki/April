local tabs = April.require("menu.tabs")
local debug = April.require("core.debug")
local notify = April.require("core.notify")

local M = {}
local initialized = false

function M.init()
    if initialized then return true end
    initialized = tabs.init()
    return initialized
end

function M.on_frame()
    if not initialized then return end
    debug.tick_frame()

    pcall(function()
        April.require("core.feature_bind").tick()
    end)

    local dt = 0.016
    if utility and utility.get_delta_time then
        dt = utility.get_delta_time()
    end

    debug.guard("tabs.update", tabs.update, dt)
    debug.guard("tabs.draw", tabs.draw)
    debug.guard("notify.draw", notify.draw)
end

return M
