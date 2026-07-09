local runservice = April.require("core.runservice")

local M = {}

function M.movement_allowed()
    return runservice.movement_allowed()
end

return M
