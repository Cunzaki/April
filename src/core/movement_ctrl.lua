-- Fly / Slowfall - HRP velocity on RunService Heartbeat (falls back to on_frame).

local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")

local M = {}

local P_FLY = "april_noclip_enabled"
local P_SPEED = "april_noclip_speed"
local P_SLOWFALL = "april_slowfall_enabled"

local _installed = false
local fly_active = false
local fly_noclip = false
local tracked_char_id = nil
local last_fly_zero_ms = 0

-- Slider 1-20 studs/s
local MIN_FLY_SPEED = 1
local MAX_FLY_SPEED = 20
local GROUND_DIST = 4.5

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

local function hum_alive(hum)
    if not hum then return false end
    local hp = hum.Health or hum.health
    if hp == nil then return true end
    return hp > 0
end

local function fly_speed()
    local spd = settings.num(P_SPEED, 5)
    if spd < MIN_FLY_SPEED then spd = MIN_FLY_SPEED end
    if spd > MAX_FLY_SPEED then spd = MAX_FLY_SPEED end
    return spd
end

local function is_on_ground(root)
    local pos = move.read_pos(root)
    if not pos then return false end
    local dist = move.ground_distance(pos.x, pos.y, pos.z)
    if dist == nil then return false end
    return dist <= GROUND_DIST
end

local function has_move_input(mx, my, mz)
    return mx ~= 0 or my ~= 0 or mz ~= 0
end

local function set_fly_noclip(char, enabled)
    fly_noclip = enabled
    if not char then return end
    move.set_noclip_parts(char, enabled)
end

local function clear_swim_block()
    local lp = env.get_local_player()
    local char = get_character(lp)
    if not char then return end
    local water = env.safe_call(function()
        return char:FindFirstChild("WaterController")
            or (char.find_first_child and char:find_first_child("WaterController"))
    end)
    if not water then return end
    pcall(function()
        if water.set_attribute then water:set_attribute("IsSwim", false)
        elseif water.SetAttribute then water:SetAttribute("IsSwim", false)
        end
    end)
end

local function apply_fly_velocity(root, mx, my, mz, speed)
    local tx, ty, tz = 0, 0, 0
    local mag = math.sqrt(mx * mx + my * my + mz * mz)
    if mag >= 0.001 then
        tx = mx / mag * speed
        ty = my / mag * speed
        tz = mz / mag * speed
    end
    move.set_velocity(root, tx, ty, tz)
    move.set_angular_velocity(root, 0, 0, 0)
end

local function tick_fly(root, hum, char)
    if not hum_alive(hum) then return end

    local mx, my, mz = move.read_fly_input()
    local on_ground = is_on_ground(root)
    local moving = has_move_input(mx, my, mz)

    -- On ground with no input: normal walk/jump.
    if on_ground and not moving then
        set_fly_noclip(char, false)
        return
    end

    local speed = fly_speed()
    apply_fly_velocity(root, mx, my, mz, speed)
    set_fly_noclip(char, not on_ground or moving)
    clear_swim_block()
end

local function tick_slowfall(root, hum, _dt)
    local raw = settings.num("april_slowfall_speed", 5)
    if raw < 1 then raw = 1 end
    local cap = -(0.8 + (raw * 0.22))

    local vx, vy, vz = move.read_velocity(root)
    if vy < cap then
        move.set_velocity(root, vx, cap, vz)
    end

    clear_swim_block()
end

local function abort_active(root, char)
    set_fly_noclip(char, false)
    if fly_active and root then
        local now = tick_ms()
        if now - last_fly_zero_ms > 80 then
            local vx, _, vz = move.read_velocity(root)
            move.set_velocity(root, vx, 0, vz)
            last_fly_zero_ms = now
        end
    end
    fly_active = false
end

function M.tick(_dt)
    local misc_gate = April.require("core.misc_gate")
    if not misc_gate.movement_allowed() then
        abort_active(nil, nil)
        return
    end

    local fling = April.require("features.movement.fling")
    if fling.is_active and fling.is_active() then
        abort_active(nil, nil)
        return
    end

    local lp = env.get_local_player()
    if not lp then return end

    local char = get_character(lp)
    if not char or not env.is_valid(char) then return end

    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not root or not hum then return end

    local cid = char_id(char)
    if cid ~= tracked_char_id then
        fly_active = false
        fly_noclip = false
        tracked_char_id = cid
    end

    local want_fly = settings.enabled(P_FLY)

    if want_fly then
        fly_active = true
        tick_fly(root, hum, char)
    else
        if fly_active then
            abort_active(root, char)
        else
            set_fly_noclip(char, false)
        end
        if settings.enabled(P_SLOWFALL) then
            tick_slowfall(root, hum, _dt)
        end
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
