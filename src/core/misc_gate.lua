--[[ Misc tab — movement features need RunService from Game API 1.4+ ]]

local runservice = April.require("core.runservice")

local M = {}

function M.movement_allowed()
    return runservice.movement_allowed()
end

return M
