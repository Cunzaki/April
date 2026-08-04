local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")

local M = {}

local P_SPIDER = "april_spider_enabled"
local P_SPEED = "april_spider_speed"
local WALL_REACH = 3.0
local WALL_GRACE_MS = 280
local MIN_SPEED = 18
local MAX_SPEED = 30
local JUMP_PULSE_MS = 280

local installed = false
local active = false
local tracked_char_id = nil
local last_wall_at = 0
local last_wall_x = 0
local last_wall_z = 0
local last_jump_at = 0

local function now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

local function char_id(char)
    if not char then return nil end
    return char.Address or char.address or tostring(char)
end

local function get_character(lp)
    if lp and (lp.Character or lp.character) then
        return lp.Character or lp.character
    end
    local game_lp = game and (game.LocalPlayer or game.local_player)
    return game_lp and (game_lp.Character or game_lp.character) or nil
end

local function get_humanoid(lp, char)
    local direct = lp and (lp.Humanoid or lp.humanoid)
    if direct and env.is_valid(direct) then return direct end
    if not char then return nil end
    return env.safe_call(function()
        if char.FindFirstChildOfClass then return char:FindFirstChildOfClass("Humanoid") end
        if char.find_first_child_of_class then return char:find_first_child_of_class("Humanoid") end
    end)
end

local function alive(hum)
    if not hum then return false end
    local health = hum.Health or hum.health
    return health == nil or health > 0
end

local function spider_speed()
    local speed = settings.num(P_SPEED, 18)
    return math.max(MIN_SPEED, math.min(MAX_SPEED, speed))
end

local function cast_wall(pos, dx, dz, y_offset)
    if not raycast then return false, nil end
    local ready = raycast.is_ready or raycast.IsReady
    if type(ready) == "function" then
        local ok, value = pcall(ready)
        if ok and value == false then return false, nil end
    end
    local cast = raycast.cast or raycast.Cast
    if type(cast) ~= "function" then return false, nil end

    local from_x = pos.x + dx * 0.35
    local from_y = pos.y + y_offset
    local from_z = pos.z + dz * 0.35
    local ok, hit, _, distance = pcall(
        cast,
        from_x, from_y, from_z,
        pos.x + dx * WALL_REACH, from_y, pos.z + dz * WALL_REACH
    )
    if not ok or hit ~= true then return false, nil end
    distance = tonumber(distance)
    return distance ~= nil and distance <= WALL_REACH, distance
end

local function wall_ahead(root)
    local pos = move.read_pos(root)
    if not pos then return false end
    local dx, dz = move.read_flat_input()
    if dx == 0 and dz == 0 then return false end

    local low, low_dist = cast_wall(pos, dx, dz, -1.0)
    local middle, middle_dist = cast_wall(pos, dx, dz, 0)
    local high, high_dist = cast_wall(pos, dx, dz, 1.15)
    local hits = (low and 1 or 0) + (middle and 1 or 0) + (high and 1 or 0)
    if hits < 2 then return false, dx, dz end

    local nearest, farthest
    for _, value in ipairs({ low_dist, middle_dist, high_dist }) do
        if value then
            nearest = nearest and math.min(nearest, value) or value
            farthest = farthest and math.max(farthest, value) or value
        end
    end
    if nearest and farthest and farthest - nearest > 1.5 then
        return false, dx, dz
    end
    return true, dx, dz, hits
end

local function stop()
    active = false
    last_wall_at = 0
    last_jump_at = 0
end

function M.tick(dt)
    local misc_gate = April.require("core.misc_gate")
    if not misc_gate.movement_allowed() then
        stop()
        return
    end

    local fling = April.require("features.movement.fling")
    if fling.is_active and fling.is_active() then
        stop()
        return
    end
    local movement = April.require("core.movement_ctrl")
    if movement.is_fly_active() then
        stop()
        return
    end

    local lp = env.get_local_player()
    local char = get_character(lp)
    if not lp or not char or not env.is_valid(char) then
        stop()
        return
    end

    local cid = char_id(char)
    if cid ~= tracked_char_id then
        move.clear_collide_snapshots()
        move.reset_fallen_collision(char)
        tracked_char_id = cid
        active = false
    end

    if not settings.enabled(P_SPIDER) then
        stop()
        return
    end

    local root = move.find_part(char, "HumanoidRootPart")
    local hum = get_humanoid(lp, char)
    if not root or not alive(hum) then
        stop()
        return
    end

    local touching_wall, dx, dz, wall_hits = wall_ahead(root)
    local now = now_ms()
    if touching_wall then
        last_wall_at = now
        last_wall_x, last_wall_z = dx, dz
    elseif dx ~= 0 or dz ~= 0 then
        touching_wall = last_wall_at > 0 and now - last_wall_at <= WALL_GRACE_MS
        if touching_wall then
            dx, dz = last_wall_x, last_wall_z
            wall_hits = 3
        end
    end
    if not touching_wall then
        stop()
        return
    end

    local speed = spider_speed()
    local push = wall_hits and wall_hits < 3 and 4.5 or 2.5
    local vertical = speed
    if now - last_jump_at >= JUMP_PULSE_MS then
        -- Jumping state keeps the local humanoid animation/state machine in
        -- sync with the wall boost and reduces visible snap-back on walls.
        move.humanoid_state(hum, 3)
        last_jump_at = now
        vertical = math.min(speed, 22)
    end
    move.drive_velocity_target(root, dx * push, vertical, dz * push, dt, {
        response = 32,
        vertical_blend = 1,
        zero_angular = true,
    })
    active = true
end

function M.is_active()
    return active
end

function M.install()
    if installed then return end
    installed = true
    April.require("core.runservice").on_sim(function(dt)
        M.tick(dt)
    end)
end

return M
