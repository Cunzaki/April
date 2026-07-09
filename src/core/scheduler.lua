local debug = April.require("core.debug")

local M = {}
local jobs = {}

function M.register(id, interval_ms, fn, when)
    jobs[id] = {
        id = id,
        interval = interval_ms,
        fn = fn,
        last = 0,
        when = when,
    }
end

function M.tick()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    for id, job in pairs(jobs) do
        if job.when then
            local ok, pass = pcall(job.when)
            if not ok or not pass then
                goto continue
            end
        end
        if now - job.last >= job.interval then
            job.last = now
            debug.guard("scan:" .. id, job.fn)
        end
        ::continue::
    end
end

function M.start_all()

end

function M.stop_all()
    jobs = {}
end

return M
