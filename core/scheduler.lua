local cache = April.require("core.cache")

local M = {}
local jobs = {}
local threads = {}

function M.register(id, interval_ms, fn)
    jobs[id] = {
        id = id,
        interval = interval_ms,
        fn = fn,
        last = 0,
        thread_id = nil,
        running = false,
    }
end

function M.start_all()
    if not thread or not thread.create then return end
    for id, job in pairs(jobs) do
        if not job.thread_id then
            job.running = true
            job.thread_id = thread.create(function()
                local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
                if now - job.last < job.interval then return end
                job.last = now
                local ok, err = pcall(job.fn)
                if not ok and April.debug then
                    print("[April] scan error " .. id .. ": " .. tostring(err))
                end
            end, job.interval)
            threads[id] = job.thread_id
        end
    end
end

function M.stop_all()
    if not thread then return end
    for id, tid in pairs(threads) do
        if thread.is_running and thread.is_running(tid) then
            thread.stop(tid)
        end
        if jobs[id] then
            jobs[id].thread_id = nil
            jobs[id].running = false
        end
    end
    threads = {}
end

function M.tick_fallback()
    if thread and thread.create then return end
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    for _, job in pairs(jobs) do
        if now - job.last >= job.interval then
            job.last = now
            pcall(job.fn)
        end
    end
end

return M
