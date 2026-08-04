local settings = April.require("core.settings")
local env = April.require("core.env")
local cache = April.require("core.cache")
local move = April.require("core.cframe_move")
local runservice = April.require("core.runservice")

local M = {}

local P = "april_antifling_enabled"
local REAPPLY_MS = 125

local installed = false
local was_enabled = false
local tracked = {}
local snapshots = {}

local function now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

local function key_of(inst)
    return inst and (inst.Address or inst.address or tostring(inst)) or nil
end

local function player_key(player)
    return player and (player.UserId or player.user_id or player.Name or player.name or tostring(player)) or nil
end

local function read_collide(inst)
    local ok, value = pcall(function()
        if part and part.get_can_collide then return part.get_can_collide(inst) end
        if part and part.GetCanCollide then return part.GetCanCollide(inst) end
        return inst.CanCollide
    end)
    return ok and value == true or false
end

local function restore_snapshot(key)
    local item = snapshots[key]
    if not item then return end
    snapshots[key] = nil
    if item.inst and env.is_valid(item.inst) then
        move.set_part_collide(item.inst, item.collide)
    end
end

local function restore_track(track)
    if not track then return end
    for i = 1, #track.part_keys do
        restore_snapshot(track.part_keys[i])
    end
end

local function restore_all()
    for key in pairs(snapshots) do restore_snapshot(key) end
    tracked = {}
end

local function resolve_character(player)
    if not player then return nil end
    return player.Character or player.character
end

local function apply_track(track)
    for i = 1, #track.parts do
        local inst = track.parts[i]
        if inst and env.is_valid(inst) then
            move.set_part_collide(inst, false)
        end
    end
end

local function build_track(player, char)
    local out = { char_id = key_of(char), parts = {}, part_keys = {}, last_apply = 0 }
    for _, inst in ipairs(move.iter_parts(char)) do
        local key = key_of(inst)
        if key then
            if not snapshots[key] then
                snapshots[key] = { inst = inst, collide = read_collide(inst) }
            end
            out.parts[#out.parts + 1] = inst
            out.part_keys[#out.part_keys + 1] = key
        end
    end
    return out
end

local function tick()
    local enabled = settings.enabled(P)
    if not enabled then
        if was_enabled then restore_all() end
        was_enabled = false
        return
    end
    was_enabled = true

    local now = now_ms()
    local seen = {}
    for i = 1, #cache.players do
        local player = cache.players[i]
        local id = player_key(player)
        local char = resolve_character(player)
        if id and char and env.is_valid(char) then
            seen[id] = true
            local track = tracked[id]
            local cid = key_of(char)
            if not track or track.char_id ~= cid then
                if track then restore_track(track) end
                track = build_track(player, char)
                tracked[id] = track
            end
            if now - track.last_apply >= REAPPLY_MS then
                apply_track(track)
                track.last_apply = now
            end
        end
    end
    for id, track in pairs(tracked) do
        if not seen[id] then
            restore_track(track)
            tracked[id] = nil
        end
    end
end

function M.install()
    if installed then return end
    installed = true
    runservice.on_sim(tick)
end

function M.update()
    if not runservice.uses_heartbeat() then tick() end
end

function M.register_menu() end
function M.draw() end

return M
