local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")

local M = {}

local P_FLY = "april_noclip_enabled"
local P_SPIDER = "april_spider_enabled"
local P_NOCLIP = "april_walk_noclip_enabled"
local P_SLOWFALL = "april_slowfall_enabled"

local MODE_NONE = "none"
local MODE_FLY = "fly"
local MODE_SPIDER = "spider"
local MODE_NOCLIP = "noclip"

local _installed = false
local active_mode = MODE_NONE
local tracked_char_id = nil
local noclip_on = false
local last_state_ms = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function char_id(char)
    if not char then return nil end
    return char.Address or char.address or tostring(char)
end

local function get_character(lp)
    if lp and lp.character then return lp.character end
    if game and game.local_player and game.local_player.character then
        return game.local_player.character
    end
    return nil
end

local function get_root(lp)
    local char = get_character(lp)
    if not char then return nil end
    return move.find_part(char, "HumanoidRootPart")
end

local function get_humanoid(lp)
    if lp and lp.humanoid and env.is_valid(lp.humanoid) then
        return lp.humanoid
    end
    local char = get_character(lp)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child_of_class then return char:find_first_child_of_class("Humanoid") end
        return char:FindFirstChildOfClass("Humanoid")
    end)
end

local function resolve_mode()
    if settings.enabled(P_NOCLIP) then return MODE_NOCLIP end
    if settings.enabled(P_FLY) then return MODE_FLY end
    if settings.enabled(P_SPIDER) then return MODE_SPIDER end
    return MODE_NONE
end

local function maybe_state(hum, state)
    local now = tick_ms()
    if now - last_state_ms < 150 then return end
    last_state_ms = now
    move.humanoid_state(hum, state)
end

local function set_noclip(char, on)
    if noclip_on == on then return end
    noclip_on = on
    move.set_noclip_parts(char, on)
end

local function leave_mode(char, hum)
    set_noclip(char, false)
    if hum then move.humanoid_running(hum) end
    last_state_ms = 0
end

local function tick_noclip(root, hum, speed, dt)
    maybe_state(hum, 8)

    local pos = move.read_pos(root)
    if not pos then return end

    local mx, my, mz = move.read_fly_input()
    local next_pos = move.drive_root(root, pos, mx, my, mz, speed, dt)
    if not next_pos then return end

    local ny = move.clamp_above_floor(next_pos.x, next_pos.y, next_pos.z)
    if ny ~= next_pos.y then
        move.set_position_only(root, next_pos.x, ny, next_pos.z)
        local vx, _, vz = move.read_velocity(root)
        move.set_velocity(root, vx, 0, vz)
    end
end

local function tick_fly(root, hum, speed, dt)
    maybe_state(hum, 6)

    local pos = move.read_pos(root)
    if not pos then return end

    local mx, my, mz = move.read_fly_input()
    local next_pos = move.drive_root(root, pos, mx, my, mz, speed, dt)
    if not next_pos then return end

    if my <= 0 then
        local ny = move.clamp_above_floor(next_pos.x, next_pos.y, next_pos.z)
        if ny > next_pos.y then
            move.set_position_only(root, next_pos.x, ny, next_pos.z)
            local vx, _, vz = move.read_velocity(root)
            move.set_velocity(root, vx, 0, vz)
        end
    end
end

local function tick_spider(root, hum, speed, dt)
    maybe_state(hum, 12)

    local pos = move.read_pos(root)
    if not pos then return end

    local mx, my, mz = move.read_fly_input()
    if my == 0 then my = 1 end

    move.drive_root(root, pos, mx, my, mz, speed, dt)
end

local function tick_slowfall(root, dt)
    local pos = move.read_pos(root)
    if not pos then return end

    local cap = settings.num("april_slowfall_speed", -5)
    if cap > 0 then cap = -cap end

    local vx, vy, vz = move.read_velocity(root)
    if vy >= cap then return end

    move.set_velocity(root, vx, cap, vz)
    move.set_position_only(root, pos.x, pos.y + cap * dt * 0.05, pos.z)
end

local function abort_active()
    if active_mode == MODE_NONE then return end

    local lp = env.get_local_player()
    if lp then
        local char = get_character(lp)
        local hum = get_humanoid(lp)
        if char and hum then
            leave_mode(char, hum)
        end
    end

    active_mode = MODE_NONE
end

function M.tick(_dt)
    local misc_gate = April.require("core.misc_gate")
    if not misc_gate.movement_allowed() then
        abort_active()
        return
    end

    local fling = April.require("features.movement.fling")
    if fling.is_active and fling.is_active() then
        abort_active()
        return
    end

    local dt = move.delta_time()
    local lp = env.get_local_player()
    if not lp then return end

    local char = get_character(lp)
    if not char or not env.is_valid(char) then return end

    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not root or not hum then return end

    local cid = char_id(char)
    if cid ~= tracked_char_id then
        if active_mode ~= MODE_NONE then
            leave_mode(char, hum)
        end
        active_mode = MODE_NONE
        tracked_char_id = cid
    end

    local mode = resolve_mode()

    if active_mode ~= mode then
        if active_mode ~= MODE_NONE then
            leave_mode(char, hum)
        end
        active_mode = mode
        if mode == MODE_NOCLIP then
            set_noclip(char, true)
        end
    end

    if mode == MODE_NOCLIP then
        tick_noclip(root, hum, settings.num("april_walk_noclip_speed", 32), dt)
    elseif mode == MODE_FLY then
        tick_fly(root, hum, settings.num("april_noclip_speed", 72), dt)
    elseif mode == MODE_SPIDER then
        tick_spider(root, hum, settings.num("april_spider_speed", 20), dt)
    elseif noclip_on then
        set_noclip(char, false)
    end

    if mode == MODE_NONE and settings.enabled(P_SLOWFALL) then
        tick_slowfall(root, dt)
    end
end

function M.install()
    if _installed then return end
    _installed = true
    April.require("core.runservice").on_sim(function(dt)
        M.tick(dt)
    end)
end

return M
