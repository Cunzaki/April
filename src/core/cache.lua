local M = {}

M.all_entities = {}
M.players = {}
M.workspace_entities = {}
M.local_player = nil
M.world = {}
M.loot = {}
M.base = {}
M.npcs = {}
M.raids = {}
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
M._entity_frame = 0

local function clear_array(list)
    for i = #list, 1, -1 do
        list[i] = nil
    end
end

-- Capture Vector's entity cache once per April frame. Consumers reuse these
-- stable arrays instead of each calling entity.GetPlayers independently.
function M.refresh_entities()
    M._entity_frame = M._entity_frame + 1

    local get_players = entity and (entity.GetPlayers or entity.get_players)
    local list = nil
    if get_players then
        local ok, result = pcall(get_players)
        if ok and type(result) == "table" then
            list = result
        end
    end
    list = list or {}

    M.all_entities = list
    clear_array(M.players)
    clear_array(M.workspace_entities)

    local local_player = nil
    for i = 1, #list do
        local player = list[i]
        if player then
            if player.IsLocal == true or player.is_local == true then
                local_player = player
            elseif player.IsWorkspaceEntity == true or player.is_workspace_entity == true then
                M.workspace_entities[#M.workspace_entities + 1] = player
            else
                M.players[#M.players + 1] = player
            end
        end
    end

    if not local_player then
        local get_local = entity and (entity.GetLocalPlayer or entity.get_local_player)
        if get_local then
            local ok, result = pcall(get_local)
            if ok then local_player = result end
        end
    end
    M.local_player = local_player
    return list
end

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
