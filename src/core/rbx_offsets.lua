--[[
  Remote Roblox offsets (https://offsets.imtheo.lol/Offsets.json).
  Fetch at boot; MaxFPS write is deferred until the place is actually loaded
  and the TaskScheduler pointer/value looks sane. Bad memory.Write hard-crashes
  Roblox — pcall does not protect native AVs.
]]

local M = {}

local OFFSETS_URL = "https://offsets.imtheo.lol/Offsets.json"
local TARGET_FPS = 999
local FPS_REFRESH_MS = 8000
local FPS_READY_DELAY_MS = 2500
local FPS_FAIL_COOLDOWN_MS = 15000

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
    JobStart = 200,
    JobEnd = 208,
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
local fps_notified = false
local fps_disabled = false
local fps_ready_at = 0
local fps_fail_streak = 0

local function notify_fps_unlocked(fps)
    if fps_notified then return end
    fps_notified = true
    pcall(function()
        local notify = April.require("core.notify")
        if notify and notify.success then
            notify.success(string.format("FPS unlocked (%d)", tonumber(fps) or TARGET_FPS), 3500)
        end
    end)
end

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

local function module_base()
    local base = tonumber(memory and memory.base)
    if (not base or base == 0) and memory and memory.GetBase then
        local ok, v = pcall(memory.GetBase)
        if ok then base = tonumber(v) end
    end
    if not base or base == 0 then return nil end
    return base
end

-- Reject null / low / clearly non-userland pointers before any Write.
local function ptr_sane(addr)
    addr = tonumber(addr)
    if not addr then return false end
    if addr < 0x10000 then return false end
    -- Reject common poisoned patterns.
    if addr == 0xFFFFFFFF or addr == 0xFFFFFFFFFFFFFFFF then return false end
    return true
end

local function looks_like_fps(v)
    v = tonumber(v)
    if not v then return false end
    if v ~= v then return false end -- NaN
    if v == math.huge or v == -math.huge then return false end
    return v >= 1 and v <= 10000
end

-- Only touch MaxFPS once we are in a real place with a local player.
local function in_place_ready()
    if not game then return false end

    local pid = tonumber(game.PlaceId or game.place_id)
    if not pid or pid == 0 then return false end

    local lp = game.LocalPlayer or game.local_player
    if lp ~= nil then return true end

    if entity then
        local fn = entity.GetLocalPlayer or entity.get_local_player
        if type(fn) == "function" then
            local ok, p = pcall(fn)
            if ok and p ~= nil then return true end
        end
    end

    return false
end

local function scheduler_looks_valid(read, ts)
    if not ptr_sane(ts) then return false end

    local job_start_off = tonumber(task_sched.JobStart) or DEFAULT_TASK.JobStart
    local job_end_off = tonumber(task_sched.JobEnd) or DEFAULT_TASK.JobEnd

    local ok_a, a = pcall(read, ts + job_start_off, "ptr")
    local ok_b, b = pcall(read, ts + job_end_off, "ptr")
    if not ok_a or not ok_b then return false end
    a, b = tonumber(a), tonumber(b)
    if not a or not b then return false end
    -- Job list end should be >= start on a live TaskScheduler.
    if b < a then return false end
    -- Empty list (a == b) is still valid; huge inverted gaps are not.
    if (b - a) > 0x10000000 then return false end
    return true
end

local function read_fps_slot(read, addr)
    local ok_d, as_double = pcall(read, addr, "double")
    if ok_d and looks_like_fps(as_double) then
        return "double", tonumber(as_double)
    end
    local ok_f, as_float = pcall(read, addr, "float")
    if ok_f and looks_like_fps(as_float) then
        return "float", tonumber(as_float)
    end
    return nil, nil
end

function M.apply_max_fps(target)
    if fps_disabled then return false end
    if not in_place_ready() then return false end

    local write = mem_fn("Write", "write")
    local read = mem_fn("Read", "read")
    if not write or not read then return false end

    local base = module_base()
    if not base then return false end

    local ptr_rva = tonumber(task_sched.Pointer) or DEFAULT_TASK.Pointer
    local max_off = tonumber(task_sched.MaxFPS) or DEFAULT_TASK.MaxFPS
    if not ptr_rva or ptr_rva <= 0 or not max_off or max_off < 0 or max_off > 0x4000 then
        fps_disabled = true
        return false
    end

    local fps = tonumber(target) or TARGET_FPS
    if fps < 30 then fps = 30 end
    if fps > 999 then fps = 999 end

    local ok_ptr, ts = pcall(read, base + ptr_rva, "ptr")
    if not ok_ptr or not ptr_sane(ts) then
        fps_fail_streak = fps_fail_streak + 1
        if fps_fail_streak >= 5 then fps_disabled = true end
        return false
    end
    ts = tonumber(ts)

    if not scheduler_looks_valid(read, ts) then
        fps_fail_streak = fps_fail_streak + 1
        if fps_fail_streak >= 5 then fps_disabled = true end
        return false
    end

    local addr = ts + max_off
    if not ptr_sane(addr) then
        fps_disabled = true
        return false
    end

    -- Never Write unless the current slot already looks like an FPS value.
    local kind, cur = read_fps_slot(read, addr)
    if not kind then
        fps_fail_streak = fps_fail_streak + 1
        if fps_fail_streak >= 5 then fps_disabled = true end
        return false
    end

    if cur and math.abs(cur - fps) < 0.5 then
        fps_applied = true
        fps_fail_streak = 0
        last_fps_ms = tick_ms()
        notify_fps_unlocked(fps)
        return true
    end

    local ok, result = pcall(write, addr, kind, fps)
    if ok and result ~= false then
        -- Confirm we didn't corrupt something that no longer reads as FPS.
        local kind2, cur2 = read_fps_slot(read, addr)
        if kind2 and cur2 and math.abs(cur2 - fps) < 1.0 then
            fps_applied = true
            fps_fail_streak = 0
            last_fps_ms = tick_ms()
            notify_fps_unlocked(fps)
            return true
        end
        -- Restore previous value if verify failed.
        pcall(write, addr, kind, cur)
        fps_fail_streak = fps_fail_streak + 1
        if fps_fail_streak >= 3 then fps_disabled = true end
        return false
    end

    fps_fail_streak = fps_fail_streak + 1
    if fps_fail_streak >= 5 then fps_disabled = true end
    return false
end

function M.boot()
    if booted then return fetch_ok end
    booted = true
    -- Fetch offsets only. Never Write here — menu / loading / pre-place
    -- TaskScheduler layouts will hard-crash Roblox on a bad Write.
    pcall(M.fetch)
    fps_ready_at = 0
    last_fps_ms = 0
    return fetch_ok
end

function M.tick_fps()
    if not booted or fps_disabled then return end
    if not in_place_ready() then
        fps_ready_at = 0
        return
    end

    local now = tick_ms()
    if fps_ready_at == 0 then
        fps_ready_at = now + FPS_READY_DELAY_MS
        return
    end
    if now > 0 and now < fps_ready_at then return end

    local wait = fps_applied and FPS_REFRESH_MS or 1000
    if fps_fail_streak > 0 then
        wait = FPS_FAIL_COOLDOWN_MS
    end
    if now > 0 and last_fps_ms > 0 and (now - last_fps_ms) < wait then return end

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

function M.fps_disabled_unsafe()
    return fps_disabled
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
