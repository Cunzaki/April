-- Deterministic resource farmer: stable body navigation, mandatory body prime,
-- optional weak points, and bounded recovery.
local settings = April.require("core.settings")
local env = April.require("core.env")
local farm_tools = April.require("game.farm_tools")
local farm_targets = April.require("game.farm_targets")
local silent_ray = April.require("core.silent_ray")
local menu_util = April.require("core.menu_util")
local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local debug_log = April.require("core.debug")

local M = {}

local P = "april_autofarm"
local P_RESOURCES = P .. "_resources"
local P_SEARCH = P .. "_search_range"
local P_DEBUG = P .. "_debug_path"
local VK = {
    LMB = 0x01,
    SHIFT = 0x10,
    SPACE = 0x20,
    W = 0x57,
    A = 0x41,
    C = 0x43,
    D = 0x44,
}

local SCAN_MS = 250
local TOOL_MS = 150
local MOVE_SAMPLE_MS = 900
local RECOVER_MS = 650
local SKIP_MS = 10000
local NO_PROGRESS_MS = 20000
local AIM_DOT = { approach = 0.78, body = 0.90, weak = 0.96 }

local PHASE = {
    IDLE = "Idle",
    SCAN = "Scan",
    APPROACH = "Approach",
    PRIME = "Prime",
    HARVEST = "Harvest",
    RECOVER = "Recover",
    DONE = "Done",
}

local phase = PHASE.IDLE
local phase_reason = nil
local target = nil
local target_tool = nil
local held_tool = nil
local tool_until = 0
local next_scan = 0
local next_swing = 0
local skipped = {}
local injected = {}
local custom_menu_ref = nil
local active_aim = nil
local distance = nil
local target_started = false
local harvest_confirmed = false
local body_only = false
local weak_retry_at = 0
local recover_attempts = 0
local recover_until = 0
local recover_side = VK.A
local move_sample_at = 0
local move_sample_pos = nil
local align_since = 0
local last_progress_at = 0
local last_health = nil
local last_state = nil
local last_weak_key = nil
local last_weak_pos = nil
local weak_mode_since = 0
local weak_swings = 0
local total_swings = 0
local input_failures = 0
local input_failure_at = 0
local was_enabled = false

local function event(message)
    debug_log.force_event(tostring(message))
end

local function set_phase(next_phase, reason)
    if phase ~= next_phase or phase_reason ~= reason then
        phase = next_phase
        phase_reason = reason
        event("phase=" .. tostring(next_phase) .. " reason=" .. tostring(reason or "none"))
    end
end

local function now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

local function xyz(value)
    if not value then return nil end
    local x, y, z = value.x or value.X, value.y or value.Y, value.z or value.Z
    if x == nil or y == nil or z == nil then return nil end
    return { x = x, y = y, z = z }
end

local function body_origin()
    local player = env.get_local_player()
    local direct = player and xyz(player.Position or player.position)
    if direct then return direct end
    local character = player and (player.Character or player.character)
    if not character or not env.is_valid(character) then return nil end
    local root = env.safe_call(function()
        if character.FindFirstChild then return character:FindFirstChild("HumanoidRootPart") end
        if character.find_first_child then return character:find_first_child("HumanoidRootPart") end
    end)
    return root and xyz(root.Position or root.position) or nil
end

local function flat_distance(a, b)
    if not a or not b then return math.huge end
    local dx, dz = a.x - b.x, a.z - b.z
    return math.sqrt(dx * dx + dz * dz)
end

local function distance3(a, b)
    if not a or not b then return math.huge end
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function part_surface_distance3(point, part, center)
    if not point or not center then return math.huge end
    local size
    if part then
        pcall(function() size = part.Size or part.size end)
    end
    size = xyz(size)
    if not size then return distance3(point, center) end
    local dx = math.max(0, math.abs(point.x - center.x) - size.x * 0.5)
    local dy = math.max(0, math.abs(point.y - center.y) - size.y * 0.5)
    local dz = math.max(0, math.abs(point.z - center.z) - size.z * 0.5)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function movement_api(name, pascal)
    return utility and (utility[name] or utility[pascal]) or nil
end

local function set_key(vk, down)
    if injected[vk] == down then return true end
    local fn = down and movement_api("key_down", "KeyDown") or movement_api("key_up", "KeyUp")
    if type(fn) ~= "function" then return false end
    local ok = pcall(fn, vk)
    if ok then injected[vk] = down end
    return ok
end

local function release_movement_keys()
    set_key(VK.SHIFT, false)
    set_key(VK.SPACE, false)
    set_key(VK.W, false)
    set_key(VK.A, false)
    set_key(VK.D, false)
end

local function release_keys()
    release_movement_keys()
    set_key(VK.C, false)
end

local function has_injected_key()
    return injected[VK.SHIFT] == true or injected[VK.SPACE] == true
        or injected[VK.W] == true or injected[VK.A] == true
        or injected[VK.C] == true or injected[VK.D] == true
end

local function stop_silent()
    silent_ray.stop()
end

local function track_silent_farm(camera_pos, aim_pos)
    local set_ok = silent_ray.set_target(camera_pos, aim_pos, aim_pos)
    local track_ok = silent_ray.track(camera_pos, aim_pos, VK.LMB, aim_pos)
    return set_ok or track_ok
end

local function reset_lock()
    target = nil
    target_tool = nil
    active_aim = nil
    distance = nil
    target_started = false
    harvest_confirmed = false
    body_only = false
    weak_retry_at = 0
    recover_attempts = 0
    recover_until = 0
    move_sample_at = 0
    move_sample_pos = nil
    align_since = 0
    last_progress_at = 0
    last_health = nil
    last_state = nil
    last_weak_key = nil
    last_weak_pos = nil
    weak_mode_since = 0
    weak_swings = 0
    total_swings = 0
    input_failures = 0
    input_failure_at = 0
    next_swing = 0
    release_keys()
    stop_silent()
end

local function cleanup(reason)
    reset_lock()
    set_phase(PHASE.IDLE, reason)
end

local function ensure_idle(reason)
    if target or phase ~= PHASE.IDLE or has_injected_key() then
        cleanup(reason)
    else
        set_phase(PHASE.IDLE, reason)
    end
end

local function finish_target(now, reason, should_skip)
    local key = target and target.key
    if should_skip == "permanent" and key then
        skipped[key] = math.huge
    elseif should_skip and key then
        skipped[key] = now + SKIP_MS
    end
    event("target_done reason=" .. tostring(reason) .. " key=" .. tostring(key))
    reset_lock()
    set_phase(PHASE.DONE, reason)
end

local function menu_open()
    return custom_menu_ref and custom_menu_ref.is_open and custom_menu_ref.is_open() == true
end

local function selected_resources()
    return {
        Trees = settings.multi(P_RESOURCES, 1, true),
        Stone = settings.multi(P_RESOURCES, 2, true),
        Metal = settings.multi(P_RESOURCES, 3, true),
        Phosphate = settings.multi(P_RESOURCES, 4, true),
    }
end

local function any_selected(allowed)
    return allowed.Trees or allowed.Stone or allowed.Metal or allowed.Phosphate
end

local function current_tool(now)
    if now < tool_until then return held_tool end
    farm_tools.load()
    held_tool = farm_tools.get_held_farm_tool_name()
    tool_until = now + TOOL_MS
    return held_tool
end

local function clean_skips(now)
    for key, expires in pairs(skipped) do
        if now >= expires then skipped[key] = nil end
    end
end

local function acquire(now, origin, tool_name, allowed)
    if now < next_scan then return nil end
    next_scan = now + SCAN_MS
    clean_skips(now)
    return farm_targets.find_target(
        origin,
        math.max(25, settings.num(P_SEARCH, 500)),
        farm_tools.tool_caps(tool_name),
        { allowed = allowed, skip_keys = skipped, check_visibility = false }
    )
end

local function lock_target(record, now, origin, tool_name, reason)
    release_keys()
    stop_silent()
    target = record
    target_tool = tool_name
    active_aim = nil
    distance = nil
    target_started = false
    harvest_confirmed = false
    body_only = false
    weak_retry_at = 0
    record.autofarm_locked_at = now
    record.autofarm_settle_until = 0
    record.autofarm_heading_x = nil
    record.autofarm_heading_z = nil
    record.autofarm_range_penalty = 0
    record.autofarm_body_retries = 0
    record.autofarm_prime_attempts = 0
    record.autofarm_prime_swing_at = 0
    recover_attempts = 0
    recover_until = 0
    align_since = 0
    last_health = record.health
    last_state = record.resource_state
    last_weak_key = record.weak_key
    last_weak_pos = record.weak_pos
    last_progress_at = now
    weak_mode_since = 0
    weak_swings = 0
    total_swings = 0
    input_failures = 0
    input_failure_at = 0
    next_swing = 0
    move_sample_at, move_sample_pos = now, origin
    event("target_lock key=" .. tostring(record.key)
        .. " resource=" .. tostring(record.resource_type)
        .. " reason=" .. tostring(reason))
    set_phase(PHASE.APPROACH, reason)
end

local function look_at(point, smooth)
    local fn = camera and (camera.look_at or camera.LookAt)
    if type(fn) ~= "function" or not point then return false end
    return pcall(fn, point.x, point.y, point.z, smooth or 1)
end

local function alignment(camera_pos, point)
    local fn = camera and (camera.get_look_vector or camera.GetLookVector)
    if type(fn) ~= "function" then return 0 end
    local ok, look = pcall(fn)
    look = ok and xyz(look) or nil
    if not look then return 0 end
    local dx, dy, dz = point.x - camera_pos.x, point.y - camera_pos.y, point.z - camera_pos.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    local llen = math.sqrt(look.x * look.x + look.y * look.y + look.z * look.z)
    if len < 0.001 or llen < 0.001 then return 0 end
    return (look.x * dx + look.y * dy + look.z * dz) / (len * llen)
end

local function body_aim(record, camera_pos)
    local center = record and record.body_pos
    local part = record and record.body_part
    if not center then return nil end
    local point = { x = center.x, y = center.y, z = center.z }
    if (record.kind == "Trees" or record.kind == "Nodes") and camera_pos then
        local size = part and (part.Size or part.size)
        local sy = size and tonumber(size.Y or size.y) or 0
        if sy > 0 then
            local low = center.y - sy * 0.5 + 0.2
            local high = center.y + sy * 0.5 - 0.2
            point.y = math.max(low, math.min(high, camera_pos.y))
        elseif record.kind == "Trees" then
            point.y = camera_pos.y
        end
    end
    return point
end

local function navigation_aim(record, camera_pos)
    local body = record and record.body_pos
    if not body then return nil end
    if record.kind == "Trees" then
        return { x = body.x, y = camera_pos.y, z = body.z }
    end
    return { x = body.x, y = body.y, z = body.z }
end

local function stable_node_aim(record, point, camera_pos, clamp_pitch)
    if not record or not point or not camera_pos then return point end
    local dx, dz = point.x - camera_pos.x, point.z - camera_pos.z
    local horizontal = math.sqrt(dx * dx + dz * dz)
    if horizontal > 0.75 then
        record.autofarm_heading_x = dx / horizontal
        record.autofarm_heading_z = dz / horizontal
    end
    local hx = record.autofarm_heading_x or 0
    local hz = record.autofarm_heading_z or 1
    local view_distance = math.max(horizontal, 2.5)
    local y = camera_pos.y
    if clamp_pitch then
        y = math.max(point.y, camera_pos.y - view_distance * 1.25)
    end
    return {
        x = camera_pos.x + hx * view_distance,
        y = y,
        z = camera_pos.z + hz * view_distance,
    }
end

local function approach_aim(record, camera_pos)
    if not body_only and record and record.weak_pos then
        if record.kind == "Nodes" and camera_pos then
            return stable_node_aim(record, record.weak_pos, camera_pos, false)
        end
        return record.weak_pos
    end
    return navigation_aim(record, camera_pos)
end

local function click_left()
    local fn = movement_api("mouse_click", "MouseClick")
    return type(fn) == "function" and pcall(fn, "left") or false
end

local function record_progress(now, reason)
    harvest_confirmed = true
    last_progress_at = now
    weak_mode_since = now
    weak_swings = 0
    if target then
        target.autofarm_range_penalty = 0
        target.autofarm_body_retries = 0
        target.autofarm_prime_attempts = 0
    end
    event("progress=" .. tostring(reason) .. " health=" .. tostring(target and target.health))
end

local function position_changed(a, b)
    return a and b and distance3(a, b) > 0.08
end

local function refresh_progress(now)
    if not target then return end
    local health = target.health
    if health and last_health and health < last_health - 0.0001 then
        record_progress(now, "health")
    elseif last_health == nil and health ~= nil then
        last_health = health
    end
    if target.resource_state and last_state and target.resource_state ~= last_state then
        record_progress(now, "state")
    end
    if target.weak_key and not last_weak_key and target_started then
        record_progress(now, "marker_spawn")
    elseif target.weak_key and last_weak_key
        and target.weak_key ~= last_weak_key and target_started
    then
        record_progress(now, "marker_replace")
    elseif target.weak_key and target.weak_key == last_weak_key
        and position_changed(target.weak_pos, last_weak_pos)
    then
        record_progress(now, "marker_move")
    end
    last_health = health or last_health
    last_state = target.resource_state or last_state
    last_weak_key = target.weak_key
    last_weak_pos = target.weak_pos and {
        x = target.weak_pos.x, y = target.weak_pos.y, z = target.weak_pos.z,
    } or nil
end

local function begin_recovery(now, reason)
    recover_attempts = recover_attempts + 1
    local limit = harvest_confirmed and 5 or 3
    if recover_attempts > limit then
        if target_started then
            body_only = true
            weak_retry_at = now + 2500
            recover_attempts = 0
            release_movement_keys()
            stop_silent()
            set_phase(PHASE.HARVEST, "recovery_body_fallback")
        else
            finish_target(now, "recovery_exhausted", true)
        end
        return
    end
    body_only = target_started
    if body_only then weak_retry_at = now + 2500 end
    recover_side = recover_attempts % 2 == 1 and VK.A or VK.D
    recover_until = now + RECOVER_MS
    stop_silent()
    set_key(VK.W, true)
    set_key(VK.A, recover_side == VK.A)
    set_key(VK.D, recover_side == VK.D)
    set_phase(PHASE.RECOVER, reason)
end

local function update_movement_progress(now, origin)
    if move_sample_at == 0 then
        move_sample_at, move_sample_pos = now, origin
        return
    end
    if now - move_sample_at < MOVE_SAMPLE_MS then return end
    local moved = flat_distance(origin, move_sample_pos)
    move_sample_at, move_sample_pos = now, origin
    if moved < 0.35 then begin_recovery(now, "stuck") end
end

local function live_tool_matches(tool_name)
    return farm_tools.get_held_farm_tool_name() == tool_name
end

local function swing(now, tool_name, weak)
    if now < next_swing then return nil end
    if not live_tool_matches(tool_name) then
        tool_until = 0
        finish_target(now, "tool_changed", false)
        return false
    end
    if click_left() then
        input_failures = 0
        input_failure_at = 0
        target_started = true
        total_swings = total_swings + 1
        if weak then weak_swings = weak_swings + 1 end
        next_swing = now + math.floor(farm_tools.swing_cooldown(tool_name) * 1000 + 60)
        event(string.format(
            "swing=%d mode=%s resource=%s dist=%.2f",
            total_swings, weak and "weak" or "body",
            tostring(target and target.resource_type), distance or -1
        ))
        return true
    else
        input_failures = input_failures + 1
        if input_failure_at == 0 then input_failure_at = now end
        next_swing = now + 500
        event("swing_failed=input count=" .. tostring(input_failures))
        if input_failures >= 3 or now - input_failure_at >= 3000 then
            input_failures = 0
            input_failure_at = now
            next_swing = now + 1000
        end
        return false
    end
end

local function update_impl()
    local enabled = settings.enabled(P)
    if not enabled then
        if was_enabled or has_injected_key() then cleanup("disabled") end
        was_enabled = false
        return
    end
    was_enabled = true
    if menu_open() then
        ensure_idle("menu_open")
        return
    end
    if phase == PHASE.IDLE and has_injected_key() then
        release_keys()
        if has_injected_key() then return end
    end

    local now = now_ms()
    local origin = body_origin()
    if not origin then
        ensure_idle("no_character")
        return
    end
    local tool_name = current_tool(now)
    if not tool_name then
        ensure_idle("no_tool")
        return
    end
    local allowed = selected_resources()
    if not any_selected(allowed) then
        ensure_idle("no_resource_types")
        return
    end

    if phase == PHASE.IDLE or phase == PHASE.DONE then
        set_phase(PHASE.SCAN, "ready")
    end
    if phase == PHASE.SCAN then
        stop_silent()
        local candidate = acquire(now, origin, tool_name, allowed)
        if not candidate then return end
        lock_target(candidate, now, origin, tool_name, "target_locked")
    end

    if target_tool ~= tool_name then
        finish_target(now, "tool_changed", false)
        return
    end
    target = farm_targets.resolve(target)
    if not target then
        farm_targets.invalidate()
        finish_target(now, "depleted_or_removed", false)
        return
    end
    refresh_progress(now)
    if target.weak_pos and (not body_only or now >= weak_retry_at) then
        body_only = false
        weak_retry_at = 0
    end
    if phase == PHASE.PRIME and target_started and harvest_confirmed then
        set_phase(PHASE.HARVEST, "prime_confirmed")
    end
    if (target.autofarm_locked_at or 0) > 0
        and now - target.autofarm_locked_at >= 120000
    then
        finish_target(now, "target_timeout", "permanent")
        return
    end

    if phase == PHASE.APPROACH and not target_started then
        local candidate = acquire(now, origin, tool_name, allowed)
        if candidate and candidate.key ~= target.key then
            local current_d = math.sqrt(farm_targets.surface_distance2(target, origin))
            local candidate_d = math.sqrt(farm_targets.surface_distance2(candidate, origin))
            if candidate_d + 0.15 < current_d then
                lock_target(candidate, now, origin, tool_name, "closer_target")
            end
        end
    end

    local range = farm_tools.melee_range(tool_name)
    local body_surface_distance = math.sqrt(farm_targets.surface_distance2(target, origin))
    local should_crouch = target.kind == "Nodes"
        and (target_started or body_surface_distance <= range + 4)
    set_key(VK.C, should_crouch)
    local should_jump = (phase == PHASE.APPROACH or phase == PHASE.RECOVER)
        and target.body_pos ~= nil
        and target.body_pos.y > origin.y + 1.5
    set_key(VK.SPACE, should_jump)

    local camera_pos = silent_ray.get_camera_origin()
    if not camera_pos then
        cleanup("no_camera")
        return
    end
    local pursuing_weak = not body_only and target.weak_pos ~= nil
    local boulder = tool_name == "Boulder"
    local ray_budget = math.max(2, range - 0.55)
    local range_penalty = tonumber(target.autofarm_range_penalty) or 0
    local initial_close = harvest_confirmed and 0 or 0.3
    local enter_range
    local exit_range
    if pursuing_weak then
        if boulder then
            enter_range = math.max(1.25, range - 0.2 - range_penalty - initial_close)
            exit_range = enter_range + 0.4
            distance = distance3(camera_pos, target.weak_pos)
        else
            enter_range = math.max(1.25, ray_budget - range_penalty - initial_close)
            exit_range = enter_range + 0.45
            distance = distance3(camera_pos, target.weak_pos)
        end
    else
        local range_aim = body_aim(target, camera_pos)
        enter_range = math.max(1.25, ray_budget - range_penalty - initial_close)
        exit_range = enter_range + 0.45
        distance = part_surface_distance3(camera_pos, target.body_part, range_aim)
    end

    if phase == PHASE.RECOVER then
        stop_silent()
        active_aim = approach_aim(target, camera_pos)
        look_at(active_aim, 3)
        if now < recover_until then return end
        release_movement_keys()
        move_sample_at, move_sample_pos = now, origin
        set_phase(PHASE.APPROACH, "recovery_complete")
    end

    if phase == PHASE.APPROACH then
        stop_silent()
        set_key(VK.SHIFT, true)
        active_aim = approach_aim(target, camera_pos)
        if distance <= enter_range then
            release_movement_keys()
            stop_silent()
            align_since = 0
            target.autofarm_settle_until = target.kind == "Nodes" and now + 300 or now
            set_phase(target_started and target.weak_pos and PHASE.HARVEST or PHASE.PRIME, "in_range")
            return
        else
            if not look_at(active_aim, 3) then
                begin_recovery(now, "approach_look_failed")
                return
            end
            if alignment(camera_pos, active_aim) >= AIM_DOT.approach then
                align_since = 0
                set_key(VK.A, false)
                set_key(VK.D, false)
                if not set_key(VK.W, true) then
                    finish_target(now, "movement_api_unavailable", true)
                    return
                end
                update_movement_progress(now, origin)
            else
                set_key(VK.W, false)
                if align_since == 0 then align_since = now end
                if now - align_since > 1500 then
                    align_since = 0
                    begin_recovery(now, "approach_alignment")
                end
            end
            return
        end
    end

    if phase == PHASE.PRIME then
        if now < (target.autofarm_settle_until or 0) then return end
        if target_started and not target.weak_pos
            and (target.autofarm_prime_swing_at or 0) > 0
        then
            -- Give the server a brief chance to spawn the first spark. If it
            -- does not appear, the first body swing was likely just outside
            -- real melee reach: close the gap before trying again.
            if now - target.autofarm_prime_swing_at < 350 then
                return
            end
            target.autofarm_prime_swing_at = 0
            target.autofarm_range_penalty = math.min(
                math.max(0, range - 1.25),
                (tonumber(target.autofarm_range_penalty) or 0) + 0.3
            )
            stop_silent()
            move_sample_at, move_sample_pos = now, origin
            set_phase(PHASE.APPROACH, "prime_no_marker_close")
            return
        end
        local prime_weak = target.weak_pos ~= nil
        active_aim = prime_weak and target.weak_pos or body_aim(target, camera_pos)
        local prime_view = prime_weak and target.kind == "Nodes"
            and stable_node_aim(target, active_aim, camera_pos, true) or active_aim
        release_movement_keys()
        if not look_at(prime_view, 1) then
            begin_recovery(now, "prime_look_failed")
            return
        end
        if alignment(camera_pos, prime_view) < (prime_weak and AIM_DOT.weak or AIM_DOT.body) then
            if align_since == 0 then align_since = now end
            if now - align_since > 1200 then
                align_since = 0
                begin_recovery(now, "prime_alignment")
            end
            return
        end
        align_since = 0
        if not track_silent_farm(camera_pos, active_aim) then
            finish_target(now, "silent_unavailable", true)
            return
        end
        if now >= next_swing then
            local clicked = swing(now, tool_name, prime_weak)
            if clicked and target then
                weak_mode_since = now
                if prime_weak then
                    set_phase(PHASE.HARVEST, "weak_primed")
                else
                    local attempts = (tonumber(target.autofarm_prime_attempts) or 0) + 1
                    target.autofarm_prime_attempts = attempts
                    target.autofarm_prime_swing_at = now
                    if attempts >= 2 then
                        target.autofarm_prime_attempts = 0
                        target.autofarm_range_penalty = math.min(
                            math.max(0, range - 1.25),
                            (tonumber(target.autofarm_range_penalty) or 0) + 0.3
                        )
                        stop_silent()
                        move_sample_at, move_sample_pos = now, origin
                        set_phase(PHASE.APPROACH, "prime_unconfirmed_close")
                    else
                        set_phase(PHASE.PRIME, "body_prime_wait")
                    end
                end
            end
        end
        return
    end

    if phase ~= PHASE.HARVEST then return end
    if now < (target.autofarm_settle_until or 0) then return end
    if distance > exit_range then
        release_movement_keys()
        stop_silent()
        move_sample_at, move_sample_pos = now, origin
        set_phase(PHASE.APPROACH, "outside_range")
        return
    end
    if total_swings >= 8 and now - last_progress_at > NO_PROGRESS_MS then
        body_only = target.weak_pos == nil
        weak_retry_at = now + 2500
        weak_swings = 0
        weak_mode_since = now
        last_progress_at = now
    end

    if body_only and target.weak_pos and now >= weak_retry_at then
        body_only = false
        weak_swings = 0
        weak_mode_since = now
    end
    local use_weak = not body_only and target.weak_pos ~= nil
    if not use_weak and total_swings >= 2
        and now - last_progress_at > (boulder and 2400 or 4000)
    then
        local retries = (tonumber(target.autofarm_body_retries) or 0) + 1
        target.autofarm_body_retries = retries
        if retries >= 4 then
            finish_target(now, "body_no_progress", true)
            return
        end
        local step = boulder and 0.55 or 0.35
        target.autofarm_range_penalty = math.min(
            math.max(0, range - 1.25),
            (tonumber(target.autofarm_range_penalty) or 0) + step
        )
        last_progress_at = now
        stop_silent()
        move_sample_at, move_sample_pos = now, origin
        set_phase(PHASE.APPROACH, "body_no_progress_close")
        return
    end
    local weak_fail_swings = boulder and 3 or 2
    local weak_fail_ms = boulder and 4000 or 2500
    if use_weak and weak_swings >= weak_fail_swings
        and now - weak_mode_since > weak_fail_ms
    then
        weak_swings = 0
        weak_mode_since = now
        begin_recovery(now, "weak_no_progress")
        return
    end

    active_aim = use_weak and target.weak_pos or body_aim(target, camera_pos)
    local view_aim = use_weak and target.kind == "Nodes"
        and stable_node_aim(target, active_aim, camera_pos, true) or active_aim
    release_movement_keys()
    if not look_at(view_aim, 1) then
        stop_silent()
        if use_weak then
            begin_recovery(now, "weak_look_failed")
        else
            begin_recovery(now, "body_look_failed")
        end
        return
    end
    local required_dot = use_weak and AIM_DOT.weak or AIM_DOT.body
    if alignment(camera_pos, view_aim) < required_dot then
        stop_silent()
        if align_since == 0 then align_since = now end
        if use_weak and now - align_since > 1200 then
            align_since = 0
            begin_recovery(now, "weak_alignment")
        elseif not use_weak and now - align_since > 1200 then
            align_since = 0
            begin_recovery(now, "body_alignment")
        end
        return
    end
    align_since = 0

    if not track_silent_farm(camera_pos, active_aim) then
        finish_target(now, "silent_unavailable", true)
        return
    end
    swing(now, tool_name, use_weak)
end

function M.register_menu()
    pcall(function() custom_menu_ref = April.require("ui.custom_menu") end)
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu_util.section(T, G.MISC, "Autofarm")
    menu_util.register_keybind(T, G.MISC, P, "Autofarm", false)
    menu.add_multicombo(T, G.MISC, P_RESOURCES, "Farm Resources", {
        "Trees", "Stone", "Metal", "Phosphate",
    }, { true, true, true, true }, root)
    menu.add_slider_int(T, G.MISC, P_SEARCH, "Search Range", 50, 2000, 500, root)
    menu.add_checkbox(T, G.MISC, P_DEBUG, "Debug Target Path", false, root)
    menu_util.bind_children(P, { P_RESOURCES, P_SEARCH, P_DEBUG })
end

function M.update()
    local ok, err = pcall(update_impl)
    if ok then return end
    event("ERROR " .. tostring(err))
    cleanup("lua_error")
    error(err)
end

function M.draw()
    if not settings.bool(P_DEBUG, false) or not settings.enabled(P) then return end
    local sw, sh = draw_util.screen_size()
    local col = theme.CYAN or { 0.25, 0.9, 1, 1 }
    if active_aim then
        local tx, ty, on_screen = esp_util.w2s(active_aim.x, active_aim.y, active_aim.z)
        if on_screen then
            draw_util.snapline(tx, ty, col, 1.5, sw, sh)
            draw_util.circle(tx, ty, 7, col, false)
        end
    end
    local text = tostring(phase)
    if phase_reason then text = text .. " (" .. tostring(phase_reason) .. ")" end
    if target then text = text .. " | " .. tostring(target.resource_type) end
    if body_only then text = text .. " | body fallback" end
    if distance then text = text .. string.format(" | %.1f studs", distance) end
    if held_tool then text = text .. " | " .. tostring(held_tool) end
    draw_util.text_centered(sw * 0.5, sh - 72, text, col, 12)
end

function M.get_target()
    return target
end

function M.is_active()
    return settings.enabled(P)
end

return M
