local debug = April.require("core.debug")

local M = {}

M.GROUP_ID = 1154360
M.MIN_STAFF_RANK = 6 -- above Fan (rank 5)

M._cache = {}
M._cache_ready = false
M._cache_at = 0
M._refresh_ms = 30 * 60 * 1000
M._refreshing = false
M._started = false
M._thread_id = nil

M._lookup_queue = {}
M._lookup_seen = {}
M._lookup_pending = {}
M._lookup_interval_ms = 1500
M._lookup_thread_id = nil

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function http_ready()
    return utility and type(utility.http_get) == "function"
end

local function http_ok(body, status)
    if not body or body == "" then return false end
    if status == nil then return true end
    return status >= 200 and status < 300
end

local function normalize_uid(user_id)
    local uid = tonumber(user_id)
    if not uid or uid == 0 then return nil end
    return uid
end

function M.available()
    return http_ready()
end

function M.role_for(user_id)
    local uid = normalize_uid(user_id)
    if not uid then return nil end
    return M._cache[uid]
end

function M.is_ready()
    return M._cache_ready
end

function M.reset_session()
    M._lookup_queue = {}
    M._lookup_pending = {}
    M._lookup_seen = {}
    M._cache_at = 0
end

local function parse_next_cursor(body)
    if not body then return nil end
    local cursor = body:match('"nextPageCursor":"([^"]+)"')
    if not cursor or cursor == "" or cursor == "null" then return nil end
    return cursor
end

local function parse_role_users(body, role_name, out)
    if not body or not role_name or not out then return out end
    for user_id in body:gmatch('"userId":%s*(%d+)') do
        local uid = tonumber(user_id)
        if uid then out[uid] = role_name end
    end
    return out
end

local function parse_staff_roles(body)
    local roles = {}
    if not body then return roles end

    for id, name, rank in body:gmatch('"id":%s*(%d+)%s*,%s*"name":%s*"([^"]+)"%s*,%s*"rank":%s*(%d+)') do
        local r = tonumber(rank)
        if r and r >= M.MIN_STAFF_RANK then
            roles[tonumber(id)] = name
        end
    end

    return roles
end

local function fetch_role_page(role_id, role_name, cursor, out)
    local url = string.format(
        "https://groups.roblox.com/v1/groups/%d/roles/%d/users?limit=100&sortOrder=Asc",
        M.GROUP_ID,
        role_id
    )
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. cursor
    end

    local body, status = utility.http_get(url)
    if not http_ok(body, status) then
        return false, out, nil
    end

    parse_role_users(body, role_name, out)
    return true, out, parse_next_cursor(body)
end

local function fetch_all_role_users(role_id, role_name, out)
    local cursor = nil
    repeat
        local ok
        ok, out, cursor = fetch_role_page(role_id, role_name, cursor, out)
        if not ok then return false end
    until not cursor
    return true
end

function M.refresh_all()
    if not http_ready() then return false end
    if M._refreshing then return false end

    M._refreshing = true
    local ok, err = pcall(function()
        local body, status = utility.http_get(string.format(
            "https://groups.roblox.com/v1/groups/%d/roles",
            M.GROUP_ID
        ))
        if not http_ok(body, status) then
            error("roles request failed: " .. tostring(status))
        end

        local staff_roles = parse_staff_roles(body)
        local merged = {}
        local role_count = 0

        for role_id, role_name in pairs(staff_roles) do
            role_count = role_count + 1
            if not fetch_all_role_users(role_id, role_name, merged) then
                error("role users request failed for " .. tostring(role_name))
            end
        end

        M._cache = merged
        M._cache_ready = true
        M._cache_at = tick_ms()

        pcall(function()
            local ids = April.require("game.mod_ids")
            if ids.clear_role_cache then ids.clear_role_cache() end
        end)

        if April and April.debug then
            local n = 0
            for _ in pairs(merged) do n = n + 1 end
            debug.log(string.format("Mod group cache refreshed (%d staff, %d roles)", n, role_count))
        end
    end)

    M._refreshing = false

    if not ok then
        debug.error_once("mod_group:refresh", err)
        return false
    end

    return true
end

local function parse_user_group_role(body)
    if not body or body == "" then return nil end

    local gid = tostring(M.GROUP_ID)
    local pos = 1

    while true do
        local gs = body:find('"group"', pos, true)
        if not gs then break end

        local chunk = body:sub(gs, math.min(#body, gs + 420))
        local group_id = chunk:match('"id":%s*(%d+)')
        if group_id == gid then
            local role_chunk = chunk:match('"role":%s*{(.-)%}')
            if role_chunk then
                local rank = tonumber(role_chunk:match('"rank":%s*(%d+)'))
                local name = role_chunk:match('"name":%s*"([^"]+)"')
                if rank and name then
                    if rank >= M.MIN_STAFF_RANK then
                        return name
                    end
                    return false
                end
            end
            return nil
        end

        pos = gs + 7
    end

    return nil
end

function M.lookup_user(user_id)
    local uid = normalize_uid(user_id)
    if not uid or not http_ready() then return nil end

    if M._cache[uid] then return M._cache[uid] end

    local body, status = utility.http_get(string.format(
        "https://groups.roblox.com/v2/users/%d/groups/roles",
        uid
    ))
    if not http_ok(body, status) then return nil end

    local role = parse_user_group_role(body)
    if role == false then
        M._lookup_seen[uid] = true
        return nil
    end
    if role then
        M._cache[uid] = role
        M._cache_ready = true
        M._lookup_seen[uid] = true
        pcall(function()
            local ids = April.require("game.mod_ids")
            if ids.invalidate_uid then ids.invalidate_uid(uid) end
        end)
        return role
    end

    M._lookup_seen[uid] = true
    return nil
end

function M.queue_lookup(user_id)
    local uid = normalize_uid(user_id)
    if not uid then return end
    if M._cache[uid] or M._lookup_seen[uid] or M._lookup_pending[uid] then return end

    M._lookup_pending[uid] = true
    M._lookup_queue[#M._lookup_queue + 1] = uid
end

local function process_lookup_queue()
    if #M._lookup_queue == 0 then return end

    local uid = table.remove(M._lookup_queue, 1)
    M._lookup_pending[uid] = nil
    local ok, err = pcall(M.lookup_user, uid)
    if not ok then
        debug.error_once("mod_group:lookup", err)
    end
end

function M.ensure_started()
    if M._started then return end
    M._started = true

    if not http_ready() then return end

    if thread and thread.create then
        M._thread_id = thread.create(function()
            local now = tick_ms()
            if not M._cache_ready or (now - M._cache_at) >= M._refresh_ms then
                M.refresh_all()
            end
        end, 5000)

        M._lookup_thread_id = thread.create(function()
            process_lookup_queue()
        end, M._lookup_interval_ms)
    else
        M.refresh_all()
    end
end

function M.tick()
    M.ensure_started()
end

function M.force_refresh()
    M._cache_at = 0
    return M.refresh_all()
end

return M
