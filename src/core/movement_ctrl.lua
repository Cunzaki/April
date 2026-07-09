-- Inf Fly / Slowfall — velocity-only, HRP-only.
-- Slowfall includes shoot-while-airborne bypass: force Humanoid Running so
-- ViewmodelController's v64 stays grounded (dump: StateChanged → v64 ≥ 1 freezes fire).

local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")

local M = {}

local P_FLY = "april_noclip_enabled"
local P_SPEED = "april_noclip_speed"
local P_SLOWFALL = "april_slowfall_enabled"

local _installed = false
local fly_active = false
local tracked_char_id = nil
local last_ground_ms = 0

-- Slider 2–4 → modest studs/s
local SPEED_SCALE = 16
local MAX_FLY_SPEED = 72
local VEL_BLEND = 0.28
local GROUND_STATE_MS = 45

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
    local raw = settings.num(P_SPEED, 3)
    if raw < 2 then raw = 2 end
    if raw > 4 then raw = 4 end
    local spd = raw * SPEED_SCALE
    if spd > MAX_FLY_SPEED then spd = MAX_FLY_SPEED end
    return spd
end

-- Soft grounded spoof: keep State = Running (8) so ViewmodelController v64 stays 0.
-- Dump: Humanoid.StateChanged sets v64=0 on Landed/Running; v64≥1 freezes fire cooldown.
-- Prefer ChangeState (fires the signal); fall back to memory state write.
local function keep_grounded_for_shoot(hum)
    if not hum or not hum_alive(hum) then return end
    local now = tick_ms()
    if now - last_ground_ms < GROUND_STATE_MS then return end
    last_ground_ms = now

    pcall(function() hum.Jump = false end)
    pcall(function() hum.jump = false end)

    -- ChangeState fires StateChanged → v64 = 0 in ViewmodelController
    local changed = false
    pcall(function()
        if hum.ChangeState then
            hum:ChangeState(8) -- Running
            changed = true
        elseif hum.change_state then
            hum:change_state(8)
            changed = true
        end
    end)

    if not changed then
        -- Memory write fallback (may not fire StateChanged on all builds)
        move.humanoid_state(hum, 8)
        -- Pulse Landed then Running to encourage a transition
        if (now % 200) < GROUND_STATE_MS then
            move.humanoid_state(hum, 7)
        end
    end

    pcall(function()
        local ws = hum.WalkSpeed or hum.walk_speed
        if ws and hum.WalkspeedCheck ~= nil then
            hum.WalkspeedCheck = ws
        end
    end)
end

local function clear_swim_block()
    -- WaterController.IsSwim also freezes fire (v127). Soft-clear when possible.
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

local function tick_fly(root, hum, dt)
    if not hum_alive(hum) then return end

    local mx, my, mz = move.read_fly_input()
    local speed = fly_speed()

    move.drive_root_velocity(root, mx, my, mz, speed, dt, {
        blend = VEL_BLEND,
        max_speed = speed * 1.08,
        cancel_gravity = true,
    })

    -- Built-in shoot-while-fly: same grounded spoof as slowfall
    keep_grounded_for_shoot(hum)
    clear_swim_block()
end

local function tick_slowfall(root, hum, dt)
    local raw = settings.num("april_slowfall_speed", 5)
    if raw < 1 then raw = 1 end
    local cap = -(1.5 + (raw * 0.28))

    local vx, vy, vz = move.read_velocity(root)
    if vy < cap then
        local next_y = vy + (cap - vy) * math.min(1, dt * 10)
        if next_y < cap then next_y = cap end
        move.set_velocity(root, vx, next_y, vz)
    end

    -- Shoot while jumping / falling bypass (core of this feature)
    keep_grounded_for_shoot(hum)
    clear_swim_block()
end

local function abort_active()
    fly_active = false
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
        fly_active = false
        tracked_char_id = cid
        last_ground_ms = 0
    end

    local want_fly = settings.enabled(P_FLY)

    if want_fly then
        fly_active = true
        tick_fly(root, hum, dt)
    else
        fly_active = false
        if settings.enabled(P_SLOWFALL) then
            tick_slowfall(root, hum, dt)
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
