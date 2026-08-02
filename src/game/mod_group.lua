local debug = April.require("core.debug")

local M = {}

M.GROUP_ID = 1154360
M.MIN_STAFF_RANK = 6 -- above Fan (rank 5)

M._cache = {}
M._cache_ready = false
M._cache_at = 0
M._refresh_ms = 30 * 60 * 1000
M._retry_ms = 20 * 1000
M._next_attempt_at = 0
M._refreshing = false
M._started = false
M._thread_id = nil
M._loaded_notified = false
M._last_complete_count = 0
M._staff_role_count = 0

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
    if type(body) ~= "string" or body == "" then return false end
    if status == nil then return true end
    return status >= 200 and status < 300
end

local function normalize_uid(user_id)
    local uid = tonumber(user_id)
    if not uid or uid == 0 then return nil end
    return uid
end

local function cache_count(tbl)
    local n = 0
    for _ in pairs(tbl or M._cache) do
        n = n + 1
    end
    return n
end

local function url_encode(value)
    return (tostring(value or ""):gsub("([^%w%-_%.%~])", function(ch)
        return string.format("%%%02X", string.byte(ch))
    end))
end

local function notify_loaded(count, role_count)
    if M._loaded_notified then return end
    M._loaded_notified = true
    M._last_complete_count = count or 0
    pcall(function()
        local notify = April.require("core.notify")
        notify.success(string.format(
            "Staff detector loaded (%d people, %d roles)",
            count or 0,
            role_count or 0
        ), 5500)
    end)
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
    return M._cache_ready == true
end

function M.reset_session()
    M._lookup_queue = {}
    M._lookup_pending = {}
    M._lookup_seen = {}
    M._cache_at = 0
    M._next_attempt_at = 0
end

local function parse_next_cursor(body)
    if not body then return nil end
    -- Explicit null means done.
    if body:find('"nextPageCursor"%s*:%s*null', 1) then
        return nil
    end
    local cursor = body:match('"nextPageCursor"%s*:%s*"([^"]+)"')
    if not cursor or cursor == "" or cursor == "null" then
        return nil
    end
    return cursor
end

local function parse_role_users(body, role_name, out)
    if not body or not role_name or not out then return 0 end
    local added = 0
    for user_id in body:gmatch('"userId"%s*:%s*(%d+)') do
        local uid = tonumber(user_id)
        if uid and not out[uid] then
            out[uid] = role_name
            added = added + 1
        elseif uid then
            out[uid] = role_name
        end
    end
    return added
end

local function count_for_role(out, role_name)
    local n = 0
    for _, name in pairs(out) do
        if name == role_name then n = n + 1 end
    end
    return n
end

-- Roles payload includes memberCount; use it to know when a role is fully fetched.
local function parse_staff_roles(body)
    local roles = {}
    if not body then return roles end

    local roles_json = body:match('"roles"%s*:%s*(%b[])') or body
    for block in roles_json:gmatch("%b{}") do
        local id = tonumber(block:match('"id"%s*:%s*(%d+)'))
        local name = block:match('"name"%s*:%s*"([^"]+)"')
        local rank = tonumber(block:match('"rank"%s*:%s*(%d+)'))
        local member_count = tonumber(block:match('"memberCount"%s*:%s*(%d+)')) or 0
        if id and name and rank and rank >= M.MIN_STAFF_RANK then
            roles[id] = {
                id = id,
                name = name,
                rank = rank,
                member_count = member_count,
            }
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
        url = url .. "&cursor=" .. url_encode(cursor)
    end

    local body, status = utility.http_get(url)
    if not http_ok(body, status) then
        return false, out, nil, 0
    end

    local added = parse_role_users(body, role_name, out)
    return true, out, parse_next_cursor(body), added
end

-- Fetch every page for one role. Succeeds only when pagination finishes AND
-- loaded count meets the API memberCount (when known).
local function fetch_all_role_users(role_id, role_name, expected_count, out)
    local cursor = nil
    local pages = 0
    local empty_pages = 0

    repeat
        local ok, next_cursor, added = false, nil, 0
        for attempt = 1, 4 do
            ok, out, next_cursor, added = fetch_role_page(role_id, role_name, cursor, out)
            if ok then break end
        end
        if not ok then
            return false, ("request failed for " .. tostring(role_name))
        end

        pages = pages + 1
        if (added or 0) == 0 and next_cursor then
            empty_pages = empty_pages + 1
            if empty_pages >= 3 then
                return false, ("empty pages for " .. tostring(role_name))
            end
        else
            empty_pages = 0
        end

        cursor = next_cursor
        if pages > 80 then
            return false, ("too many pages for " .. tostring(role_name))
        end
    until not cursor

    local got = count_for_role(out, role_name)
    expected_count = tonumber(expected_count) or 0
    if expected_count > 0 and got < expected_count then
        return false, string.format(
            "%s incomplete (%d/%d)",
            tostring(role_name), got, expected_count
        )
    end

    return true, nil
end

local function role_count(roles)
    local n = 0
    for _ in pairs(roles or {}) do n = n + 1 end
    return n
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
        local expected_roles = role_count(staff_roles)
        if expected_roles < 1 then
            error("no staff roles parsed from group roles response")
        end

        -- Staging map only — never mark ready / notify until every role is complete.
        local merged = {}
        local failed = {}

        for role_id, info in pairs(staff_roles) do
            local role_ok, role_err = fetch_all_role_users(
                role_id,
                info.name,
                info.member_count,
                merged
            )
            if not role_ok then
                failed[#failed + 1] = role_err or tostring(info.name)
            end
        end

        -- One more pass on failures within this refresh (rate-limit recovery).
        if #failed > 0 then
            failed = {}
            for role_id, info in pairs(staff_roles) do
                local have = count_for_role(merged, info.name)
                local need = tonumber(info.member_count) or 0
                if need > 0 and have >= need then
                    -- already complete for this role
                else
                    -- Clear this role's partials and refetch cleanly.
                    for uid, rname in pairs(merged) do
                        if rname == info.name then merged[uid] = nil end
                    end
                    local role_ok, role_err = fetch_all_role_users(
                        role_id,
                        info.name,
                        info.member_count,
                        merged
                    )
                    if not role_ok then
                        failed[#failed + 1] = role_err or tostring(info.name)
                    end
                end
            end
        end

        if #failed > 0 then
            M._cache_ready = false
            error("staff scan incomplete: " .. table.concat(failed, "; ")
                .. string.format(" (%d people so far)", cache_count(merged)))
        end

        -- Final integrity check: every role must meet memberCount.
        for _, info in pairs(staff_roles) do
            local got = count_for_role(merged, info.name)
            local need = tonumber(info.member_count) or 0
            if need > 0 and got < need then
                M._cache_ready = false
                error(string.format(
                    "staff scan incomplete: %s %d/%d",
                    tostring(info.name), got, need
                ))
            end
        end

        local n = cache_count(merged)
        if n < 1 then
            M._cache_ready = false
            error("staff scan produced zero users")
        end

        M._cache = merged
        M._cache_ready = true
        M._cache_at = tick_ms()
        M._staff_role_count = expected_roles

        pcall(function()
            local ids = April.require("game.mod_ids")
            if ids.clear_role_cache then ids.clear_role_cache() end
        end)

        if April and April.debug then
            debug.log(string.format(
                "Mod group cache complete (%d staff across %d roles)",
                n, expected_roles
            ))
        end
        notify_loaded(n, expected_roles)
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
        local group_id = chunk:match('"id"%s*:%s*(%d+)')
        if group_id == gid then
            local role_chunk = chunk:match('"role"%s*:%s*{(.-)}')
            if role_chunk then
                local rank = tonumber(role_chunk:match('"rank"%s*:%s*(%d+)'))
                local name = role_chunk:match('"name"%s*:%s*"([^"]+)"')
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
        -- Opportunistic single-user fill only. Never mark the full scan ready here.
        M._cache[uid] = role
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

local function refresh_tick()
    local now = tick_ms()
    if M._cache_ready then
        if (now - M._cache_at) >= M._refresh_ms then
            -- Background revalidate; keep serving the last complete cache until
            -- the new scan finishes cleanly.
            M.refresh_all()
        end
        return
    end

    if now < (M._next_attempt_at or 0) then
        return
    end
    if M.refresh_all() then
        M._next_attempt_at = 0
    else
        M._next_attempt_at = now + M._retry_ms
    end
end

function M.ensure_started()
    if M._started then return end
    M._started = true

    if not http_ready() then return end

    if thread and thread.create then
        M._thread_id = thread.create(function()
            refresh_tick()
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
    M._cache_ready = false
    M._next_attempt_at = 0
    M._loaded_notified = false
    return M.refresh_all()
end

return M
