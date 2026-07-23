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

-- Drop invalid + out-of-range entries so on_frame draw never walks the whole map.
-- origin: {x,y,z}, max_dist in studs. Returns remaining count.
function M.prune_distance(list, origin, max_dist)
    if not list or #list == 0 then return 0 end
    if not origin or not max_dist or max_dist <= 0 then
        return M.prune_invalid(list)
    end

    local env = April.require("core.env")
    local esp_scan = April.require("game.esp_scan")
    local limit2 = max_dist * max_dist
    local ox, oy, oz = origin.x, origin.y, origin.z
    local write = 1

    for read = 1, #list do
        local entry = list[read]
        if entry and entry.inst and env.is_valid(entry.inst) then
            local lx, ly, lz = esp_scan.entry_coords(entry)
            if lx then
                local dx, dy, dz = lx - ox, ly - oy, lz - oz
                if (dx * dx + dy * dy + dz * dz) <= limit2 then
                    if write ~= read then
                        list[write] = entry
                    end
                    write = write + 1
                end
            end
        end
    end
    for i = write, #list do
        list[i] = nil
    end
    return write - 1
end

return M
