--[[
  Remote Roblox offsets (https://offsets.imtheo.lol/Offsets.json).
  Used for fields Vector's Lua API does not expose (e.g. Sound.IsPlaying).
]]

local M = {}

local OFFSETS_URL = "https://offsets.imtheo.lol/Offsets.json"

-- Fallbacks from the public dump when HttpGet / parse fails.
local DEFAULT_SOUND = {
    SoundId = 200,
    RollOffMaxDistance = 288,
    RollOffMinDistance = 292,
    PlaybackSpeed = 284,
    Volume = 304,
    SoundGroup = 232,
    IsPlaying = 320,
    Looped = 317,
}

local sound = {}
for k, v in pairs(DEFAULT_SOUND) do
    sound[k] = v
end

local fetched = false
local fetch_ok = false
local roblox_version = nil

local function http_get(url)
    local fn = utility and (utility.http_get or utility.HttpGet)
    if type(fn) ~= "function" then return nil end
    local ok, body, status = pcall(fn, url)
    if not ok or type(body) ~= "string" or #body < 32 then return nil end
    if status ~= nil then
        local code = tonumber(status)
        if code and (code < 200 or code >= 300) then return nil end
    end
    return body
end

local function parse_object_block(body, key)
    if type(body) ~= "string" or type(key) ~= "string" then return nil end
    return body:match('"' .. key .. '"%s*:%s*{([^}]+)}')
end

local function parse_int_fields(block, into)
    if type(block) ~= "string" or type(into) ~= "table" then return end
    for name, num in block:gmatch('"([%w_]+)"%s*:%s*(%d+)') do
        into[name] = tonumber(num)
    end
end

function M.fetch(force)
    if fetched and not force then return fetch_ok end
    fetched = true
    fetch_ok = false

    local body = http_get(OFFSETS_URL)
    if not body then return false end

    roblox_version = body:match('"Roblox Version"%s*:%s*"(.-)"')

    local sound_block = parse_object_block(body, "Sound")
    if sound_block then
        local parsed = {}
        parse_int_fields(sound_block, parsed)
        if parsed.IsPlaying then
            for k, v in pairs(parsed) do
                sound[k] = v
            end
            fetch_ok = true
            return true
        end
    end

    -- Last-resort: first IsPlaying in the Sound-ish neighborhood of the file.
    local match = body:match('"IsPlaying"%s*:%s*(%d+)')
    if match then
        sound.IsPlaying = tonumber(match)
        fetch_ok = true
        return true
    end

    return false
end

function M.ensure()
    if not fetched then
        pcall(M.fetch)
    end
    return fetch_ok
end

function M.ready()
    return fetch_ok
end

function M.roblox_version()
    return roblox_version
end

function M.sound(field)
    M.ensure()
    if field == nil then return sound end
    return sound[field] or DEFAULT_SOUND[field]
end

function M.sound_is_playing()
    return M.sound("IsPlaying") or DEFAULT_SOUND.IsPlaying
end

return M
