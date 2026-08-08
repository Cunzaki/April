--[[
  Remote Roblox offsets (https://offsets.imtheo.lol/Offsets.json).
  Loaded once at script boot — features only read the cached tables.
]]

local M = {}

local OFFSETS_URL = "https://offsets.imtheo.lol/Offsets.json"
local TARGET_FPS = 999
local FPS_REFRESH_MS = 4000

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

local DEFAULT_ANIM_TRACK = {
    Animation = 184,
    Animator = 264,
    Speed = 212,
    TimePosition = 216,
    Looped = 229,
    IsPlaying = 2704,
}

local DEFAULT_ANIMATOR = {
    ActiveAnimations = 2944,
}

local DEFAULT_TASK = {
    Pointer = 142190312,
    MaxFPS = 176,
}

local DEFAULT_MISC = {
    AnimationId = 192,
}

local sound = {}
local anim_track = {}
local animator = {}
local task_sched = {}
local misc = {}

for k, v in pairs(DEFAULT_SOUND) do sound[k] = v end
for k, v in pairs(DEFAULT_ANIM_TRACK) do anim_track[k] = v end
for k, v in pairs(DEFAULT_ANIMATOR) do animator[k] = v end
for k, v in pairs(DEFAULT_TASK) do task_sched[k] = v end
for k, v in pairs(DEFAULT_MISC) do misc[k] = v end

local fetched = false
local fetch_ok = false
local booted = false
local roblox_version = nil
local last_fps_ms = 0
local fps_applied = false

local function tick_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, v = pcall(fn)
    return (ok and tonumber(v)) or 0
end

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

local function apply_block(body, key, into, required_field)
    local block = parse_object_block(body, key)
    if not block then return false end
    local parsed = {}
    parse_int_fields(block, parsed)
    if required_field and not parsed[required_field] then return false end
    for k, v in pairs(parsed) do
        into[k] = v
    end
    return true
end

function M.fetch(force)
    if fetched and not force then return fetch_ok end
    fetched = true
    fetch_ok = false

    local body = http_get(OFFSETS_URL)
    if not body then return false end

    roblox_version = body:match('"Roblox Version"%s*:%s*"(.-)"')

    local ok_sound = apply_block(body, "Sound", sound, "IsPlaying")
    apply_block(body, "AnimationTrack", anim_track, nil)
    apply_block(body, "Animator", animator, nil)
    apply_block(body, "TaskScheduler", task_sched, nil)
    apply_block(body, "Misc", misc, nil)

    if not ok_sound then
        local match = body:match('"IsPlaying"%s*:%s*(%d+)')
        if match then
            sound.IsPlaying = tonumber(match)
            ok_sound = true
        end
    end

    fetch_ok = ok_sound == true
    return fetch_ok
end

local function mem_fn(name_a, name_b)
    if not memory then return nil end
    local fn = memory[name_a] or memory[name_b]
    if type(fn) == "function" then return fn end
    return nil
end

function M.apply_max_fps(target)
    local write = mem_fn("Write", "write")
    local read = mem_fn("Read", "read")
    if not write or not read then return false end

    local base = tonumber(memory.base)
    if (not base or base == 0) and memory.GetBase then
        local ok, v = pcall(memory.GetBase)
        if ok then base = tonumber(v) end
    end
    if not base or base == 0 then return false end

    local ptr_rva = tonumber(task_sched.Pointer) or DEFAULT_TASK.Pointer
    local max_off = tonumber(task_sched.MaxFPS) or DEFAULT_TASK.MaxFPS
    local fps = tonumber(target) or TARGET_FPS
    if fps < 30 then fps = 30 end
    if fps > 9999 then fps = 9999 end

    local ok_ptr, ts = pcall(read, base + ptr_rva, "ptr")
    if not ok_ptr or not ts or ts == 0 then return false end

    local addr = ts + max_off
    local ok = pcall(write, addr, "double", fps)
    if not ok then
        ok = pcall(write, addr, "float", fps)
    end
    if ok then
        fps_applied = true
        last_fps_ms = tick_ms()
    end
    return ok == true
end

function M.boot()
    if booted then return fetch_ok end
    booted = true
    pcall(M.fetch)
    pcall(M.apply_max_fps, TARGET_FPS)
    return fetch_ok
end

function M.tick_fps()
    if not booted then return end
    local now = tick_ms()
    if now > 0 and (now - last_fps_ms) < FPS_REFRESH_MS then return end
    pcall(M.apply_max_fps, TARGET_FPS)
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

function M.fps_unlocked()
    return fps_applied
end

function M.roblox_version()
    return roblox_version
end

local function table_get(tbl, defaults, field)
    if field == nil then return tbl end
    return tbl[field] or defaults[field]
end

function M.sound(field)
    return table_get(sound, DEFAULT_SOUND, field)
end

function M.sound_is_playing()
    return M.sound("IsPlaying") or DEFAULT_SOUND.IsPlaying
end

function M.anim_track(field)
    return table_get(anim_track, DEFAULT_ANIM_TRACK, field)
end

function M.animator(field)
    return table_get(animator, DEFAULT_ANIMATOR, field)
end

function M.misc(field)
    return table_get(misc, DEFAULT_MISC, field)
end

function M.task_scheduler(field)
    return table_get(task_sched, DEFAULT_TASK, field)
end

return M
