local tabs = April.require("menu.tabs")

local M = {}
local initialized = false
local last_frame = 0

function M.init()
    if initialized then return true end
    initialized = tabs.init()
    return initialized
end

function M.on_frame()
    if not initialized then return end
    local dt = 0.016
    if utility and utility.get_delta_time then
        dt = utility.get_delta_time()
    end
    tabs.update(dt)
    tabs.draw()
end

return M
