local fflag_mem = April.require("core.fflag_mem")

local M = {}

local active_count = 0

function M.apply_movement_only()
    active_count = active_count + 1
    pcall(fflag_mem.refresh)
    fflag_mem.set_int("S2PhysicsSenderRate", 0)
    fflag_mem.set_int("PhysicsSenderMaxBandwidthBps", 0)
    fflag_mem.set_int("DataSenderRate", 60)
end

function M.release()
    active_count = math.max(0, active_count - 1)
    if active_count == 0 then
        fflag_mem.reset_defaults()
    end
end

function M.force_reset()
    active_count = 0
    fflag_mem.reset_defaults()
end

function M.is_active()
    return active_count > 0
end

return M
