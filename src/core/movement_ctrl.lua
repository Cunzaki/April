-- Velocity Fly restored from the pre-Spider movement controller.
-- HRP velocity only — never writes WalkSpeed, JumpPower, Gravity, or HipHeight.
local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")
local runservice = April.require("core.runservice")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P_FLY = "april_fly_enabled"
local P_SPEED = "april_fly_speed"
local P_NOCLIP = "april_fly_noclip"

local MIN_SPEED = 1
local MAX_SPEED = 20
local GROUND_DIST = 4.5

local installed = false
local fly_active = false
local fly_noclip = false
local tracked_char_id = nil
local collision_healed_id = nil
local last_fly_zero_ms = 0

local function tick_ms()
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
    local hum = lp and (lp.Humanoid or lp.humanoid)
    if hum and env.is_valid(hum) then return hum end
    if not char then return nil end
    return env.safe_call(function()
        if char.FindFirstChildOfClass then return char:FindFirstChildOfClass("Humanoid") end
        if char.find_first_child_of_class then return char:find_first_child_of_class("Humanoid") end
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
    if spd < MIN_SPEED then spd = MIN_SPEED end
    if spd > MAX_SPEED then spd = MAX_SPEED end
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
    enabled = enabled == true
    if enabled == fly_noclip then
        if enabled and char then
            move.set_noclip_parts(char, true)
        end
        return
    end
    fly_noclip = enabled
    if not char then return end
    move.set_noclip_parts(char, enabled)
end

local function clear_swim_block()
    local lp = env.get_local_player()
    local char = get_character(lp)
    if not char then return end
    local water = env.safe_call(function()
        if char.FindFirstChild then return char:FindFirstChild("WaterController") end
        if char.find_first_child then return char:find_first_child("WaterController") end
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

    -- On ground with no input: leave walking/jumping alone.
    if on_ground and not moving then
        set_fly_noclip(char, false)
        return
    end

    local speed = fly_speed()
    apply_fly_velocity(root, mx, my, mz, speed)
    if settings.bool(P_NOCLIP, true) then
        set_fly_noclip(char, not on_ground or moving)
    else
        set_fly_noclip(char, false)
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

function M.is_fly_active()
    return fly_active
end

function M.tick(_dt)
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

    local root = move.find_part(char, "HumanoidRootPart")
    local hum = get_humanoid(lp, char)
    if not root or not hum then return end

    local cid = char_id(char)
    if cid ~= tracked_char_id then
        if fly_noclip then
            move.set_noclip_parts(char, false)
        end
        fly_active = false
        fly_noclip = false
        move.clear_collide_snapshots()
        tracked_char_id = cid
        collision_healed_id = nil
    end

    if settings.enabled(P_FLY) then
        fly_active = true
        tick_fly(root, hum, char)
    else
        if fly_active or fly_noclip then
            abort_active(root, char)
        elseif collision_healed_id ~= cid then
            move.reset_fallen_collision(char)
            collision_healed_id = cid
        end
    end
end

function M.install()
    if installed then return end
    installed = true
    runservice.on_sim(function(dt)
        M.tick(dt)
    end)
end

return M
