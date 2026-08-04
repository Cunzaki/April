-- Safe live staff discovery. One scheduler, one HttpGet at most per tick.
local debug = April.require("core.debug")

local M = {}

M.GROUP_ID = 1154360
M.MIN_STAFF_RANK = 6
M._cache = {}
M._cache_ready = false
M._cache_at = 0
M._refresh_ms = 30 * 60 * 1000
M._started = false
M._thread_id = nil

local TICK_MS = 3500
local RATE_LIMIT_MS = 15 * 60 * 1000
local RETRY_BASE_MS = 30 * 1000
local RETRY_MAX_MS = 10 * 60 * 1000
local MAX_QUEUE = 64
local MAX_PAGES = 80
local MAX_ROLES = 32
local MAX_TOTAL_PAGES = 256
local MAX_STAFF_ENTRIES = 10000
local MAX_BODY_BYTES = 2 * 1024 * 1024

local lookup_queue = {}
local lookup_pending = {}
local lookup_seen = {}
local lookup_attempts = {}
local crawl = nil
local next_attempt_at = 0
local crawl_failure_count = 0
local lookup_failure_count = 0
local loaded_notified = false
local tick_busy = false

local function tick_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

local function log(message)
    debug.file("STAFF_CRAWLER " .. tostring(message))
end

local function normalize_uid(value)
    local uid = tonumber(value)
    return uid and uid ~= 0 and uid or nil
end

local function http_fn()
    return utility and (utility.http_get or utility.HttpGet) or nil
end

local function status_code(status)
    local code = tonumber(status)
    if code then return code end
    if type(status) == "string" then return tonumber(status:match("(%d%d%d)")) end
    return nil
end

local function request(url)
    local fn = http_fn()
    if type(fn) ~= "function" then return nil, "no HttpGet", nil end
    local ok, body, status = pcall(fn, url)
    if not ok then return nil, tostring(body), nil end
    local code = status_code(status)
    if type(body) == "string" and #body > MAX_BODY_BYTES then
        return nil, "response too large", code
    end
    if type(body) ~= "string" or body == "" then
        return nil, tostring(status or "empty response"), code
    end
    if code and (code < 200 or code >= 300) then
        return nil, "HTTP " .. tostring(code), code
    end
    return body, nil, code or 200
end

local function cache_count(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function url_encode(value)
    return (tostring(value or ""):gsub("([^%w%-_%.%~])", function(ch)
        return string.format("%%%02X", string.byte(ch))
    end))
end

local function parse_cursor(body)
    if not body or body:find('"nextPageCursor"%s*:%s*null') then return nil end
    local cursor = body:match('"nextPageCursor"%s*:%s*"([^"]+)"')
    return cursor ~= "" and cursor ~= "null" and cursor or nil
end

local function parse_roles(body)
    local roles = {}
    local overflow = false
    local payload = body and (body:match('"roles"%s*:%s*(%b[])') or body) or ""
    for block in payload:gmatch("%b{}") do
        local id = tonumber(block:match('"id"%s*:%s*(%d+)'))
        local name = block:match('"name"%s*:%s*"([^"]+)"')
        local rank = tonumber(block:match('"rank"%s*:%s*(%d+)'))
        local members = tonumber(block:match('"memberCount"%s*:%s*(%d+)')) or 0
        if id and name and rank and rank >= M.MIN_STAFF_RANK then
            if #roles >= MAX_ROLES then
                overflow = true
            else
                roles[#roles + 1] = {
                    id = id,
                    name = name,
                    rank = rank,
                    members = members,
                    loaded = 0,
                    pages = 0,
                }
            end
        end
    end
    table.sort(roles, function(a, b) return a.rank > b.rank end)
    return roles, overflow
end

local function parse_role_users(body, role_name, out, max_new)
    local added = 0
    for uid_text in tostring(body or ""):gmatch('"userId"%s*:%s*(%d+)') do
        local uid = tonumber(uid_text)
        if uid then
            if out[uid] == nil then
                if added >= max_new then return added, true end
                added = added + 1
            end
            out[uid] = role_name
        end
    end
    return added, false
end

local function parse_user_role(body)
    local gid = tostring(M.GROUP_ID)
    local pos = 1
    while true do
        local start_at = body:find('"group"', pos, true)
        if not start_at then return nil end
        local chunk = body:sub(start_at, math.min(#body, start_at + 500))
        if chunk:match('"id"%s*:%s*(%d+)') == gid then
            local role = chunk:match('"role"%s*:%s*{(.-)}')
            local rank = role and tonumber(role:match('"rank"%s*:%s*(%d+)'))
            local name = role and role:match('"name"%s*:%s*"([^"]+)"')
            if rank and name then return rank >= M.MIN_STAFF_RANK and name or false end
            return nil
        end
        pos = start_at + 7
    end
end

local function invalidate_role_cache(uid)
    pcall(function()
        local ids = April.require("game.mod_ids")
        if uid and ids.invalidate_uid then
            ids.invalidate_uid(uid)
        elseif ids.clear_role_cache then
            ids.clear_role_cache()
        end
    end)
end

local function notify_loaded(count, roles)
    if loaded_notified then return end
    loaded_notified = true
    pcall(function()
        April.require("core.notify").success(string.format(
            "Live staff crawler ready (%d people, %d roles)", count, roles
        ), 5500)
    end)
end

local function abort_crawl()
    crawl = nil
end

local function backoff(reason, code, uid)
    if uid then
        lookup_failure_count = lookup_failure_count + 1
    else
        crawl_failure_count = crawl_failure_count + 1
    end
    local failures = uid and lookup_failure_count or crawl_failure_count
    local now = tick_ms()
    local delay
    if code == 429 then
        delay = RATE_LIMIT_MS
    else
        delay = math.min(RETRY_BASE_MS * (2 ^ math.min(failures - 1, 5)), RETRY_MAX_MS)
    end
    next_attempt_at = now + delay
    abort_crawl()
    if uid and (lookup_attempts[uid] or 0) < 3 and not lookup_pending[uid] then
        lookup_pending[uid] = true
        lookup_queue[#lookup_queue + 1] = uid
    end
    log(string.format(
        "backoff reason=%s status=%s delay_ms=%d",
        tostring(reason), tostring(code or "none"), delay
    ))
end

local function begin_crawl()
    crawl = {
        phase = "roles",
        roles = nil,
        role_index = 1,
        cursor = nil,
        staging = {},
        entry_count = 0,
        total_pages = 0,
    }
    log("state=roles")
end

local function commit_crawl()
    local count = cache_count(crawl.staging)
    if count < 1 then
        backoff("empty roster", nil)
        return
    end
    M._cache = crawl.staging
    M._cache_ready = true
    M._cache_at = tick_ms()
    local role_count = #crawl.roles
    crawl = nil
    crawl_failure_count = 0
    next_attempt_at = 0
    invalidate_role_cache()
    log(string.format("commit people=%d roles=%d", count, role_count))
    notify_loaded(count, role_count)
end

local function step_lookup()
    local uid = table.remove(lookup_queue, 1)
    if not uid then return false end
    lookup_pending[uid] = nil
    lookup_attempts[uid] = (lookup_attempts[uid] or 0) + 1
    local body, err, code = request(string.format(
        "https://groups.roblox.com/v2/users/%d/groups/roles", uid
    ))
    if not body then
        backoff("user " .. tostring(uid) .. ": " .. tostring(err), code, uid)
        return true
    end
    local role = parse_user_role(body)
    lookup_seen[uid] = true
    lookup_attempts[uid] = nil
    lookup_failure_count = 0
    if role then
        M._cache[uid] = role
        invalidate_role_cache(uid)
        log("user_match uid=" .. tostring(uid) .. " role=" .. tostring(role))
    end
    return true
end

local function step_roles()
    local body, err, code = request(string.format(
        "https://groups.roblox.com/v1/groups/%d/roles", M.GROUP_ID
    ))
    if not body then
        backoff("roles: " .. tostring(err), code)
        return
    end
    local roles, overflow = parse_roles(body)
    if overflow then
        backoff("role limit", code)
        return
    end
    if #roles < 1 then
        backoff("roles: empty response", code)
        return
    end
    crawl.roles = roles
    crawl.role_index = 1
    crawl.cursor = nil
    crawl.phase = "pages"
    log("state=pages roles=" .. tostring(#roles))
end

local function advance_role()
    crawl.role_index = crawl.role_index + 1
    crawl.cursor = nil
    if crawl.role_index > #crawl.roles then commit_crawl() end
end

local function step_page()
    local role = crawl.roles[crawl.role_index]
    if not role then
        commit_crawl()
        return
    end
    role.pages = role.pages + 1
    crawl.total_pages = crawl.total_pages + 1
    if role.pages > MAX_PAGES or crawl.total_pages > MAX_TOTAL_PAGES then
        backoff("page limit for " .. tostring(role.name), nil)
        return
    end
    local url = string.format(
        "https://groups.roblox.com/v1/groups/%d/roles/%d/users?limit=100&sortOrder=Asc",
        M.GROUP_ID, role.id
    )
    if crawl.cursor then url = url .. "&cursor=" .. url_encode(crawl.cursor) end
    local body, err, code = request(url)
    if not body then
        backoff("role " .. tostring(role.name) .. ": " .. tostring(err), code)
        return
    end
    local added, overflow = parse_role_users(
        body, role.name, crawl.staging, MAX_STAFF_ENTRIES - crawl.entry_count
    )
    role.loaded = role.loaded + added
    crawl.entry_count = crawl.entry_count + added
    if overflow then
        backoff("staff entry limit", nil)
        return
    end
    crawl.cursor = parse_cursor(body)
    if not crawl.cursor then
        if role.members > 0 and role.loaded < role.members then
            backoff(string.format(
                "incomplete %s %d/%d", role.name, role.loaded, role.members
            ), nil)
            return
        end
        log(string.format(
            "role_complete name=%s members=%d pages=%d",
            role.name, role.loaded, role.pages
        ))
        advance_role()
    end
end

local function scheduler_tick()
    if not M._started then return end
    local now = tick_ms()
    if now < next_attempt_at then return end
    if step_lookup() then return end
    if not crawl then
        if M._cache_ready and now - M._cache_at < M._refresh_ms then return end
        begin_crawl()
    end
    if crawl.phase == "roles" then
        step_roles()
    elseif crawl.phase == "pages" then
        step_page()
    end
end

local function guarded_tick()
    if tick_busy then return end
    tick_busy = true
    local ok, err = pcall(scheduler_tick)
    tick_busy = false
    if not ok then backoff("scheduler error: " .. tostring(err), nil) end
end

function M.available()
    return type(http_fn()) == "function"
end

function M.is_started()
    return M._started == true
end

function M.role_for(user_id)
    local uid = normalize_uid(user_id)
    return uid and M._cache[uid] or nil
end

function M.is_ready()
    return M._cache_ready == true
end

function M.queue_lookup(user_id)
    local uid = normalize_uid(user_id)
    if not uid or M._cache[uid] or lookup_seen[uid] or lookup_pending[uid] then return end
    if #lookup_queue >= MAX_QUEUE or (lookup_attempts[uid] or 0) >= 3 then return end
    lookup_pending[uid] = true
    lookup_queue[#lookup_queue + 1] = uid
end

-- Compatibility: asynchronous only; never performs HttpGet on the caller.
function M.lookup_user(user_id)
    M.queue_lookup(user_id)
    return M.role_for(user_id)
end

function M.refresh_all()
    if tick_ms() < next_attempt_at then return false end
    M._cache_at = 0
    abort_crawl()
    return M._started
end

function M.force_refresh()
    loaded_notified = false
    return M.refresh_all()
end

function M.ensure_started()
    if M._started or not M.available() then return M._started end
    local create = thread and (thread.create or thread.Create)
    if type(create) ~= "function" then
        debug.warn_once("mod_group:nothread", "Live staff crawler unavailable: no thread API")
        return false
    end
    M._started = true
    local ok, id = pcall(create, guarded_tick, TICK_MS)
    if not ok or not id then
        M._started = false
        M._thread_id = nil
        debug.error_once("mod_group:start", id or "thread.Create failed")
        return false
    end
    M._thread_id = id
    local first_tick = tick_ms() + TICK_MS
    if next_attempt_at < first_tick then next_attempt_at = first_tick end
    log("started interval_ms=" .. tostring(TICK_MS))
    return true
end

function M.stop(reason)
    if M._thread_id then
        local stop = thread and (thread.stop or thread.Stop)
        if type(stop) == "function" then pcall(stop, M._thread_id) end
    end
    M._thread_id = nil
    M._started = false
    tick_busy = false
    abort_crawl()
    lookup_queue = {}
    lookup_pending = {}
    log("stopped reason=" .. tostring(reason or "disabled"))
end

function M.reset_session()
    M.stop("session_changed")
    lookup_seen = {}
    lookup_attempts = {}
    M._cache_at = 0
end

function M.tick()
    return M.ensure_started()
end

return M
