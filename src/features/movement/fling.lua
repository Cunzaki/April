--[[ Fling — noclip TP spin: far-range entity lock, approach warmup, return to origin. ]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local math_util = April.require("core.math_util")
local esp_util = April.require("core.esp_util")
local player_state = April.require("game.player_state")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P = "april_fling_enabled"
local P_FOV = "april_fling_fov"
local P_KEY = "april_fling_key"
local P_KEY_MODE = "april_fling_key_mode"
local P_DURATION = "april_fling_duration"
local KEY_MODES = { "Toggle", "Hold" }

local MAX_DIST = 300.0
local FAR_RANGE = 40.0
local SPIN_Y_START = 48000.0
local SPIN_Y_MAX = 70000.0
local SPIN_RAMP_SEC = 0.35
local BASE_PREDICT = 0.05

local function fling_duration()
    return settings.num(P_DURATION, 2)
end

local function key_is_hold()
    return settings.combo_index(P_KEY_MODE, KEY_MODES, 0) == 1
end

local STATE_IDLE = 0
local STATE_APPROACH = 1
local STATE_FLING = 2

local _installed = false
local state = STATE_IDLE
local fling_t0 = 0
local approach_left = 0
local start_range = 0
local saved_pos = nil
local target_root = nil
local target_player = nil
local last_attach = nil
local key_was_down = false

local function now()
    if utility and utility.get_time then return utility.get_time() end
    return os.clock()
end

local function screen_center()
    if input and input.get_screen_center then
        local cx, cy = input.get_screen_center()
        if cx and cy then return cx, cy end
    end
    if draw and draw.get_screen_size then
        local w, h = draw.get_screen_size()
        return w * 0.5, h * 0.5
    end
    return 960, 540
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
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
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

local function player_root(p)
    if not p or not p.character then return nil end
    local char = p.character
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end

local function refresh_target_root()
    if not target_player then return false end
    local root = player_root(target_player)
    if root and env.is_valid(root) then
        target_root = root
        return true
    end
    return target_root ~= nil and env.is_valid(target_root)
end

local function target_still_valid()
    if not target_player then return false end
    if target_player.character and env.is_valid(target_player.character) then
        return true
    end
    if target_player.position then
        return true
    end
    return refresh_target_root()
end

local function player_aim_pos(p)
    if p.position then
        return p.position.x, p.position.y, p.position.z
    end
    if p.head_position then
        local h = p.head_position
        return h.x, h.y, h.z
    end
    local root = player_root(p)
    if root then
        local pos = move.read_pos(root)
        if pos then
            return pos.x, pos.y, pos.z
        end
    end
    return nil
end

local function world_dist_to_player(p, from)
    if not p or not from then return math.huge end
    if p.distance_to then
        return p:distance_to(from)
    end
    local ax, ay, az = player_aim_pos(p)
    if not ax or not from.x then return math.huge end
    return math_util.distance3(ax - from.x, ay - from.y, az - from.z)
end

local function find_target(fov_px)
    if not entity or not entity.get_players then return nil, nil end

    local cx, cy = screen_center()
    local cam = camera and camera.get_position and camera.get_position()
    local best, best_dist = nil, fov_px

    for _, p in ipairs(entity.get_players()) do
        if not player_state.is_combat_target(p) then goto continue end
        if cam and world_dist_to_player(p, cam) > MAX_DIST then goto continue end

        local ax, ay, az = player_aim_pos(p)
        if not ax then goto continue end

        local sx, sy, on_screen = esp_util.w2s(ax, ay, az)
        if not on_screen then goto continue end

        local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if fov_dist > fov_px or fov_dist >= best_dist then goto continue end

        local root = player_root(p)
        if not root or not env.is_valid(root) then goto continue end

        best_dist = fov_dist
        best = p
        ::continue::
    end

    if not best then return nil, nil end
    return best, player_root(best)
end

local function read_part_velocity(inst)
    if not inst then return 0, 0, 0 end
    local vel = inst.Velocity or inst.velocity
    if vel then
        return vel.x or vel.X or 0, vel.y or vel.Y or 0, vel.z or vel.Z or 0
    end
    local assembly = inst.AssemblyLinearVelocity
    if assembly then
        return assembly.x or assembly.X or 0, assembly.y or assembly.Y or 0, assembly.z or assembly.Z or 0
    end
    return 0, 0, 0
end

local function read_target_velocity(tgt_root, far_lock)
    local ex, ey, ez = 0, 0, 0
    local px, py, pz = 0, 0, 0
    local has_entity = false
    local has_part = false

    if target_player and target_player.velocity then
        local v = target_player.velocity
        ex, ey, ez = v.x or 0, v.y or 0, v.z or 0
        has_entity = true
    end

    if tgt_root and env.is_valid(tgt_root) then
        px, py, pz = read_part_velocity(tgt_root)
        has_part = true
    end

    if far_lock and has_entity then
        return ex, ey, ez
    end
    if has_entity and has_part then
        local entity_speed = math_util.distance3(ex, ey, ez)
        local part_speed = math_util.distance3(px, py, pz)
        if part_speed > entity_speed then
            return px, py, pz
        end
        return ex, ey, ez
    end
    if has_entity then return ex, ey, ez end
    if has_part then return px, py, pz end
    return 0, 0, 0
end

local function read_attach_pos_raw(tgt_root)
    local entity_x, entity_y, entity_z
    local has_entity = false

    if target_player and target_player.position then
        local p = target_player.position
        entity_x, entity_y, entity_z = p.x, p.y, p.z
        has_entity = true
    end

    local part_x, part_y, part_z
    local has_part = false
    if tgt_root and env.is_valid(tgt_root) then
        local tpos = move.read_pos(tgt_root)
        if tpos then
            part_x, part_y, part_z = tpos.x, tpos.y, tpos.z
            has_part = true
        end
    end

    if has_entity and has_part then
        local spread = math_util.distance3(part_x - entity_x, part_y - entity_y, part_z - entity_z)
        if spread > FAR_RANGE or start_range > FAR_RANGE or spread > 8 then
            return entity_x, entity_y, entity_z
        end
        return part_x, part_y, part_z
    end
    if has_entity then return entity_x, entity_y, entity_z end
    if has_part then return part_x, part_y, part_z end
    if last_attach then
        return last_attach.x, last_attach.y, last_attach.z
    end
    return nil
end

local function read_attach_pos(tgt_root, lpos)
    local tx, ty, tz = read_attach_pos_raw(tgt_root)
    if not tx then return nil end

    local far_lock = start_range > FAR_RANGE
    if lpos then
        local live_range = math_util.distance3(tx - lpos.x, ty - lpos.y, tz - lpos.z)
        if live_range > FAR_RANGE then
            far_lock = true
        end
    end

    local vx, vy, vz = read_target_velocity(tgt_root, far_lock)
    local horiz_speed = math_util.distance3(vx, 0, vz)
    local predict = BASE_PREDICT + horiz_speed * 0.003
    if far_lock then
        predict = predict + 0.02
    end

    tx = tx + vx * predict
    ty = ty + vy * predict * 0.12
    tz = tz + vz * predict

    last_attach = { x = tx, y = ty, z = tz }
    return tx, ty, tz
end

local function snap_passes(range, drift)
    local base = 5
    if range > 220 then base = 22
    elseif range > 150 then base = 18
    elseif range > 100 then base = 14
    elseif range > 60 then base = 10
    elseif range > 30 then base = 7
    end

    if drift > 12 then base = base + 8
    elseif drift > 6 then base = base + 5
    elseif drift > 2 then base = base + 3
    end

    return base
end

local function approach_ticks_for(dist)
    if dist <= FAR_RANGE then return 0 end
    return math.min(12, math.floor(dist / 22) + 3)
end

local function prep_fling(char, root, hum)
    move.set_character_noclip(char, root, true)
    move.humanoid_suspend(hum)
    pcall(function() hum.platform_stand = true end)
    pcall(function() hum.auto_rotate = false end)
    pcall(function() hum.evaluate_state_machine = false end)
    pcall(function() hum.sit = false end)
    pcall(function() hum.state = 14 end)
end

local function release_fling(char, root, hum)
    if root then
        move.set_velocity(root, 0, 0, 0)
        if part and part.set_angular_velocity then
            pcall(part.set_angular_velocity, root, 0, 0, 0)
        end
    end
    move.zero_character(char, root)
    move.set_character_noclip(char, root, false)
    pcall(function() hum.platform_stand = false end)
    move.humanoid_running(hum)
    move.humanoid_thaw(hum)
end

local function write_pos(inst, x, y, z)
    if not inst then return end
    if part and part.set_position then
        pcall(part.set_position, inst, x, y, z)
    else
        pcall(function() inst.Position = Vector3.new(x, y, z) end)
    end
end

local function freeze_body(char, root)
    if root then
        move.set_velocity(root, 0, 0, 0)
    end
    for _, inst in ipairs(move.iter_parts(char)) do
        move.set_velocity(inst, 0, 0, 0)
        if inst ~= root and part and part.set_angular_velocity then
            pcall(part.set_angular_velocity, inst, 0, 0, 0)
        end
    end
end

local function pin_to_target(char, root, tgt_root, from_pos)
    local lpos = move.read_pos(root)
    local tx, ty, tz = read_attach_pos(tgt_root, lpos)
    if not tx then return false end

    local drift = 0
    local range = start_range
    if lpos then
        drift = math_util.distance3(tx - lpos.x, ty - lpos.y, tz - lpos.z)
        range = math.max(range, drift)
    elseif from_pos then
        drift = math_util.distance3(tx - from_pos.x, ty - from_pos.y, tz - from_pos.z)
        range = math.max(range, drift)
    end

    local passes = snap_passes(range, drift)
    for _ = 1, passes do
        write_pos(root, tx, ty, tz)
    end

    freeze_body(char, root)
    return true, tx, ty, tz
end

local function spin_strength(elapsed)
    local t = math.min(1, elapsed / SPIN_RAMP_SEC)
    return SPIN_Y_START + (SPIN_Y_MAX - SPIN_Y_START) * t
end

local function apply_spin(root, elapsed)
    move.set_velocity(root, 0, 0, 0)
    if part and part.set_angular_velocity then
        pcall(part.set_angular_velocity, root, 0, spin_strength(elapsed), 0)
    end
end

local function stop_fling(root, char, hum)
    if saved_pos and root then
        write_pos(root, saved_pos.x, saved_pos.y, saved_pos.z)
        move.set_velocity(root, 0, 0, 0)
    end
    release_fling(char, root, hum)
    state = STATE_IDLE
    fling_t0 = 0
    approach_left = 0
    start_range = 0
    saved_pos = nil
    target_root = nil
    target_player = nil
    last_attach = nil
end

local function begin_fling(root, char, hum, tgt_player, tgt_root)
    local pos = move.read_pos(root)
    if not pos then return false end

    target_player = tgt_player
    target_root = tgt_root
    last_attach = nil

    local raw_x, raw_y, raw_z = read_attach_pos_raw(tgt_root)
    if not raw_x then return false end

    start_range = math_util.distance3(raw_x - pos.x, raw_y - pos.y, raw_z - pos.z)

    local tx, ty, tz = read_attach_pos(tgt_root, pos)
    if not tx then return false end
    saved_pos = { x = pos.x, y = pos.y, z = pos.z }
    fling_t0 = now()
    approach_left = approach_ticks_for(start_range)

    if approach_left > 0 then
        state = STATE_APPROACH
    else
        state = STATE_FLING
    end

    prep_fling(char, root, hum)
    pin_to_target(char, root, tgt_root, pos)

    if state == STATE_FLING then
        apply_spin(root, 0)
    end

    return true
end

local function tick_approach(root, char, hum)
    prep_fling(char, root, hum)

    if not pin_to_target(char, root, target_root, nil) then
        return
    end

    approach_left = approach_left - 1
    if approach_left <= 0 then
        state = STATE_FLING
        apply_spin(root, now() - fling_t0)
    end
end

local function tick_fling(root, char, hum)
    local elapsed = now() - fling_t0
    if elapsed >= fling_duration() then
        stop_fling(root, char, hum)
        return
    end

    if not target_still_valid() then
        stop_fling(root, char, hum)
        return
    end

    refresh_target_root()
    prep_fling(char, root, hum)

    local ok, tx, ty, tz = pin_to_target(char, root, target_root, nil)
    if not ok then
        return
    end

    apply_spin(root, elapsed)
    write_pos(root, tx, ty, tz)
end

local function tick_active(root, char, hum)
    if state == STATE_APPROACH then
        tick_approach(root, char, hum)
        return
    end
    tick_fling(root, char, hum)
end

local function try_trigger()
    if state ~= STATE_IDLE then return end
    if not settings.enabled(P) then return end

    local lp = env.get_local_player()
    if not lp then return end

    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not char or not root or not hum then return end

    local fov = settings.num(P_FOV, 150)
    local tgt_player, tgt_root = find_target(fov)
    if not tgt_root then return end

    begin_fling(root, char, hum, tgt_player, tgt_root)
end

local function poll_key()
    if not settings.enabled(P) then
        key_was_down = false
        return
    end
    if state ~= STATE_IDLE then return end
    if not menu or not menu.get_key then return end

    local key = menu.get_key(P_KEY) or 0
    if key <= 0 then
        key_was_down = false
        return
    end
    if not input or not input.is_key_down then return end

    local down = input.is_key_down(key)
    if key_is_hold() then
        if down then
            try_trigger()
        end
    elseif down and not key_was_down then
        try_trigger()
    end
    key_was_down = down
end

local function tick(_dt)
    if not misc_gate.movement_allowed() then return end

    poll_key()
    if state == STATE_IDLE then return end

    local lp = env.get_local_player()
    if not lp then
        state = STATE_IDLE
        approach_left = 0
        start_range = 0
        target_root = nil
        target_player = nil
        saved_pos = nil
        last_attach = nil
        return
    end

    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not char or not root or not hum then
        stop_fling(root, char, hum)
        return
    end

    tick_active(root, char, hum)
end

function M.is_active()
    return state == STATE_APPROACH or state == STATE_FLING
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu.add_checkbox(T, G.MISC, P, "Fling", false)
    menu.add_slider_int(T, G.MISC, P_FOV, "Fling FOV", 20, 600, 150, root)
    menu.add_slider_int(T, G.MISC, P_DURATION, "Fling Duration", 2, 10, 2, root)
    menu.add_combo(T, G.MISC, P_KEY_MODE, "Fling Key Mode", KEY_MODES, 0, root)
    if menu.add_hotkey then
        menu.add_hotkey(T, G.MISC, P_KEY, "Fling Key", 0, root)
    end
    menu_util.bind_children(P, { P_FOV, P_DURATION, P_KEY_MODE, P_KEY })
end

function M.install()
    if _installed then return end
    _installed = true
    local runservice = April.require("core.runservice")
    runservice.on_sim(function(dt)
        tick(dt)
    end)
end

function M.update(_dt) end

function M.draw() end

return M
