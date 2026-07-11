-- Silent-aim player whitelist (middle-click toggle). Persists via menu input string.

local settings = April.require("core.settings")
local notify = April.require("core.notify")

local M = {}

local IDS_KEY = "april_silent_whitelist_ids"
local FILTERS_KEY = "april_silent_filters"
local FILTER_WHITELIST_IDX = 5
local MMB = 0x04

local was_down = false
local cache = { t = -1, set = {} }

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function parse_ids(raw)
    local set = {}
    if type(raw) ~= "string" or raw == "" then return set end
    for part in raw:gmatch("[^,]+") do
        local id = tonumber((part:match("^%s*(.-)%s*$")))
        if id and id > 0 then
            set[id] = true
        end
    end
    return set
end

local function serialize_ids(set)
    local list = {}
    for id in pairs(set) do
        list[#list + 1] = id
    end
    table.sort(list)
    local parts = {}
    for i = 1, #list do
        parts[i] = tostring(list[i])
    end
    return table.concat(parts, ",")
end

local function read_set()
    local now = tick_ms()
    if cache.t == now then return cache.set end
    cache.t = now
    local raw = ""
    if menu and menu.get then
        local ok, v = pcall(menu.get, IDS_KEY)
        if ok and type(v) == "string" then raw = v end
    end
    if raw == "" then
        raw = tostring(settings.get(IDS_KEY) or "")
    end
    cache.set = parse_ids(raw)
    return cache.set
end

local function write_set(set)
    cache.set = set
    cache.t = tick_ms()
    local s = serialize_ids(set)
    if menu and menu.set then
        pcall(menu.set, IDS_KEY, s)
    end
end

function M.count()
    local n = 0
    for _ in pairs(read_set()) do
        n = n + 1
    end
    return n
end

function M.is_whitelisted(player)
    if not player then return false end
    local uid = tonumber(player.user_id)
    if not uid or uid == 0 then return false end
    return read_set()[uid] == true
end

function M.toggle_player(player)
    if not player or player.is_local then return false, nil end
    local uid = tonumber(player.user_id)
    if not uid or uid == 0 then return false, nil end

    local set = read_set()
    local name = player.display_name or player.name or tostring(uid)
    local added
    if set[uid] then
        set[uid] = nil
        added = false
        notify.warning("WL − " .. name, 2500)
    else
        set[uid] = true
        added = true
        notify.success("WL + " .. name, 2500)
    end
    write_set(set)
    return true, added
end

function M.clear()
    write_set({})
    notify.warning("Whitelist cleared", 2000)
end

function M.enabled()
    return settings.multi(FILTERS_KEY, FILTER_WHITELIST_IDX, false)
end

-- Skip target when whitelist filter is on and they are listed.
function M.should_skip(player)
    if not M.enabled() then return false end
    return M.is_whitelisted(player)
end

function M.tick(current_target)
    if not M.enabled() then
        was_down = false
        return
    end

    local down = input and input.is_key_down and input.is_key_down(MMB) == true
    local pressed = down and not was_down
    was_down = down

    if not pressed then return end
    if not current_target then return end
    if current_target.is_npc or current_target._npc then return end

    M.toggle_player(current_target)
end

return M
