local M = {}

M.players = {}
M.world = {}
M.loot = {}
M.base = {}
M.npcs = {}
M.waypoints = {}
M.stats = {
    last_player_scan = 0,
    last_world_scan = 0,
    last_loot_scan = 0,
    last_base_scan = 0,
    last_npc_scan = 0,
}

M.WORKSPACE_SCAN_MS = 1000
M.DROPS_SCAN_MS = 3500
M.POS_CACHE_MS = 1000
M.PRUNE_MS = 2000
M._last_pos_cache = 0
M._last_prune = 0

function M.should_refresh_positions()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if now - M._last_pos_cache >= M.POS_CACHE_MS then
        M._last_pos_cache = now
        return true
    end
    return false
end

function M.should_prune()
    local now = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if now - M._last_prune >= M.PRUNE_MS then
        M._last_prune = now
        return true
    end
    return false
end

function M.clear_bucket(bucket)
    for k in pairs(bucket) do bucket[k] = nil end
end

-- Compact an array of ESP entries, dropping invalid instances. Keeps draw loops tight
-- between workspace rescans without changing scan interval.
function M.prune_invalid(list)
    if not list or #list == 0 then return 0 end
    local env = April.require("core.env")
    local write = 1
    for read = 1, #list do
        local entry = list[read]
        if entry and entry.inst and env.is_valid(entry.inst) then
            if write ~= read then
                list[write] = entry
            end
            write = write + 1
        end
    end
    for i = write, #list do
        list[i] = nil
    end
    return write - 1
end

return M
