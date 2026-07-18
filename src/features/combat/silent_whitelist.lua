-- Player whitelist for combat aim (middle-click toggle). Prefix-aware for silent + camera aim.

local settings = April.require("core.settings")
local notify = April.require("core.notify")

local M = {}

local FILTER_WHITELIST_IDX = 5
local MMB = 0x04
local DEFAULT_PREFIX = "april_silent_"

local was_down = {}
local cache = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function norm_prefix(prefix)
    return prefix or DEFAULT_PREFIX
end

local function ids_key(prefix)
    return norm_prefix(prefix) .. "whitelist_ids"
end

local function filters_key(prefix)
    return norm_prefix(prefix) .. "filters"
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

local function read_set(prefix)
    local p = norm_prefix(prefix)
    local now = tick_ms()
    local c = cache[p]
    if c and c.t == now then return c.set end

    local raw = ""
    local key = ids_key(p)
    if menu and menu.get then
        local ok, v = pcall(menu.get, key)
        if ok and type(v) == "string" then raw = v end
    end
    if raw == "" then
        raw = tostring(settings.get(key) or "")
    end
    local set = parse_ids(raw)
    cache[p] = { t = now, set = set }
    return set
end

local function write_set(prefix, set)
    local p = norm_prefix(prefix)
    cache[p] = { t = tick_ms(), set = set }
    local s = serialize_ids(set)
    local key = ids_key(p)
    if menu and menu.set then
        pcall(menu.set, key, s)
    end
end

function M.count(prefix)
    local n = 0
    for _ in pairs(read_set(prefix)) do
        n = n + 1
    end
    return n
end

function M.is_whitelisted(player, prefix)
    if not player then return false end
    local uid = tonumber(player.user_id)
    if not uid or uid == 0 then return false end
    return read_set(prefix)[uid] == true
end

function M.toggle_player(player, prefix)
    if not player or player.is_local then return false, nil end
    local uid = tonumber(player.user_id)
    if not uid or uid == 0 then return false, nil end

    local set = read_set(prefix)
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
    write_set(prefix, set)
    return true, added
end

function M.clear(prefix)
    write_set(prefix, {})
    notify.warning("Whitelist cleared", 2000)
end

function M.enabled(prefix)
    return settings.multi(filters_key(prefix), FILTER_WHITELIST_IDX, false)
end

function M.should_skip(player, prefix)
    if not M.enabled(prefix) then return false end
    return M.is_whitelisted(player, prefix)
end

function M.tick(current_target, prefix)
    prefix = norm_prefix(prefix)
    if not M.enabled(prefix) then
        was_down[prefix] = false
        return
    end

    local down = input and input.is_key_down and input.is_key_down(MMB) == true
    local pressed = down and not was_down[prefix]
    was_down[prefix] = down

    if not pressed then return end
    if not current_target then return end
    if current_target.is_npc or current_target._npc then return end

    M.toggle_player(current_target, prefix)
end

return M
