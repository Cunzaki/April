-- Deterministic resource farmer: stable body navigation, mandatory body prime,
-- optional weak points, and bounded recovery.
-- Packed into D to stay under Lua's 60-upvalue limit per function.
local M = {}
local D = {}
D.settings = April.require("core.settings")
D.env = April.require("core.env")
D.farm_tools = April.require("game.farm_tools")
D.farm_targets = April.require("game.farm_targets")
D.silent_ray = April.require("core.silent_ray")
D.move = April.require("core.cframe_move")
D.menu_util = April.require("core.menu_util")
D.esp_util = April.require("core.esp_util")
D.draw_util = April.require("core.draw_util")
D.theme = April.require("core.ui_theme")
D.debug_log = April.require("core.debug")


D.P = "april_autofarm"
D.P_RESOURCES = D.P .. "_resources"
D.P_SEARCH = D.P .. "_search_range"
D.P_DEBUG = D.P .. "_debug_path"
D.VK = {
    LMB = 0x01,
    SHIFT = 0x10,
    SPACE = 0x20,
    W = 0x57,
    A = 0x41,
    S = 0x53,
    C = 0x43,
    D = 0x44,
}

D.SCAN_MS = 250
D.TOOL_MS = 150
D.MOVE_SAMPLE_MS = 900
D.RECOVER_MS = 650
D.SKIP_MS = 10000
D.NO_PROGRESS_MS = 20000
D.AIM_DOT = { approach = 0.78, body = 0.90, weak = 0.96 }

D.PHASE = {
    IDLE = "Idle",
    SCAN = "Scan",
    APPROACH = "Approach",
    PRIME = "Prime",
    HARVEST = "Harvest",
    RECOVER = "Recover",
    DONE = "Done",
}

D.phase = D.PHASE.IDLE
D.phase_reason = nil
D.target = nil
D.target_tool = nil
D.held_tool = nil
D.tool_until = 0
D.next_scan = 0
D.next_swing = 0
D.skipped = {}
D.injected = {}
D.custom_menu_ref = nil
D.active_aim = nil
D.distance = nil
D.target_started = false
D.harvest_confirmed = false
D.body_only = false
D.weak_retry_at = 0
D.recover_attempts = 0
D.recover_until = 0
D.recover_side = D.VK.A
D.move_sample_at = 0
D.move_sample_pos = nil
D.align_since = 0
D.last_progress_at = 0
D.last_health = nil
D.last_state = nil
D.last_weak_key = nil
D.last_weak_pos = nil
D.weak_mode_since = 0
D.weak_swings = 0
D.total_swings = 0
D.input_failures = 0
D.input_failure_at = 0
D.was_enabled = false

function D.event(message)
    D.debug_log.force_event(tostring(message))
end

function D.set_phase(next_phase, reason)
    if D.phase ~= next_phase or D.phase_reason ~= reason then
        D.phase = next_phase
        D.phase_reason = reason
        D.event("phase=" .. tostring(next_phase) .. " reason=" .. tostring(reason or "none"))
    end
end

function D.now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

function D.xyz(value)
    if not value then return nil end
    local x, y, z = value.x or value.X, value.y or value.Y, value.z or value.Z
    if x == nil or y == nil or z == nil then return nil end
    return { x = x, y = y, z = z }
end

function D.body_origin()
    local player = D.env.get_local_player()
    local direct = player and D.xyz(player.Position or player.position)
    if direct then return direct end
    local character = player and (player.Character or player.character)
    if not character or not D.env.is_valid(character) then return nil end
    local root = D.env.safe_call(function()
        if character.FindFirstChild then return character:FindFirstChild("HumanoidRootPart") end
        if character.find_first_child then return character:find_first_child("HumanoidRootPart") end
    end)
    return root and D.xyz(root.Position or root.position) or nil
end

function D.flat_distance(a, b)
    if not a or not b then return math.huge end
    local dx, dz = a.x - b.x, a.z - b.z
    return math.sqrt(dx * dx + dz * dz)
end

function D.distance3(a, b)
    if not a or not b then return math.huge end
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function D.part_surface_distance3(point, part, center)
    if not point or not center then return math.huge end
    local size
    if part then
        pcall(function() size = part.Size or part.size end)
    end
    size = D.xyz(size)
    if not size then return D.distance3(point, center) end
    local dx = math.max(0, math.abs(point.x - center.x) - size.x * 0.5)
    local dy = math.max(0, math.abs(point.y - center.y) - size.y * 0.5)
    local dz = math.max(0, math.abs(point.z - center.z) - size.z * 0.5)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function D.movement_api(name, pascal)
    return utility and (utility[name] or utility[pascal]) or nil
end

function D.set_key(vk, down)
    if D.injected[vk] == down then return true end
    local fn = down and D.movement_api("key_down", "KeyDown") or D.movement_api("key_up", "KeyUp")
    if type(fn) ~= "function" then return false end
    local ok = pcall(fn, vk)
    if ok then D.injected[vk] = down end
    return ok
end

function D.release_movement_keys()
    D.set_key(D.VK.SHIFT, false)
    D.set_key(D.VK.SPACE, false)
    D.set_key(D.VK.W, false)
    D.set_key(D.VK.A, false)
    D.set_key(D.VK.S, false)
    D.set_key(D.VK.D, false)
end

function D.release_keys()
    D.release_movement_keys()
    D.set_key(D.VK.C, false)
end

function D.has_injected_key()
    return D.injected[D.VK.SHIFT] == true or D.injected[D.VK.SPACE] == true
        or D.injected[D.VK.W] == true or D.injected[D.VK.A] == true
        or D.injected[D.VK.S] == true or D.injected[D.VK.C] == true
        or D.injected[D.VK.D] == true
end

function D.stop_silent()
    D.silent_ray.stop()
end

function D.track_silent_farm(camera_pos, aim_pos)
    local set_ok = D.silent_ray.set_target(camera_pos, aim_pos, aim_pos)
    local track_ok = D.silent_ray.track(camera_pos, aim_pos, D.VK.LMB, aim_pos)
    return set_ok or track_ok
end

function D.local_character()
    local player = D.env.get_local_player()
    local character = player and (player.Character or player.character)
    return character and D.env.is_valid(character) and character or nil
end

function D.set_farm_noclip(enabled)
    D.move.set_noclip_parts_owned(
        enabled and D.local_character() or nil,
        enabled == true,
        "autofarm"
    )
end

function D.reset_lock()
    D.target = nil
    D.target_tool = nil
    D.active_aim = nil
    D.distance = nil
    D.target_started = false
    D.harvest_confirmed = false
    D.body_only = false
    D.weak_retry_at = 0
    D.recover_attempts = 0
    D.recover_until = 0
    D.move_sample_at = 0
    D.move_sample_pos = nil
    D.align_since = 0
    D.last_progress_at = 0
    D.last_health = nil
    D.last_state = nil
    D.last_weak_key = nil
    D.last_weak_pos = nil
    D.weak_mode_since = 0
    D.weak_swings = 0
    D.total_swings = 0
    D.input_failures = 0
    D.input_failure_at = 0
    D.next_swing = 0
    D.release_keys()
    D.stop_silent()
    D.set_farm_noclip(false)
end

function D.cleanup(reason)
    D.reset_lock()
    D.set_phase(D.PHASE.IDLE, reason)
end

function D.ensure_idle(reason)
    if D.target or D.phase ~= D.PHASE.IDLE or D.has_injected_key() then
        D.cleanup(reason)
    else
        D.set_phase(D.PHASE.IDLE, reason)
    end
end

function D.finish_target(now, reason, should_skip)
    local key = D.target and D.target.key
    if should_skip == "permanent" and key then
        D.skipped[key] = math.huge
    elseif should_skip and key then
        D.skipped[key] = now + D.SKIP_MS
    end
    D.event("target_done reason=" .. tostring(reason) .. " key=" .. tostring(key))
    D.reset_lock()
    D.set_phase(D.PHASE.DONE, reason)
end

function D.menu_open()
    return D.custom_menu_ref and D.custom_menu_ref.is_open and D.custom_menu_ref.is_open() == true
end

function D.selected_resources()
    return {
        Trees = D.settings.multi(D.P_RESOURCES, 1, true),
        Stone = D.settings.multi(D.P_RESOURCES, 2, true),
        Metal = D.settings.multi(D.P_RESOURCES, 3, true),
        Phosphate = D.settings.multi(D.P_RESOURCES, 4, true),
    }
end

function D.any_selected(allowed)
    return allowed.Trees or allowed.Stone or allowed.Metal or allowed.Phosphate
end

function D.current_tool(now)
    if now < D.tool_until then return D.held_tool end
    D.farm_tools.load()
    D.held_tool = D.farm_tools.get_held_farm_tool_name()
    D.tool_until = now + D.TOOL_MS
    return D.held_tool
end

function D.clean_skips(now)
    for key, expires in pairs(D.skipped) do
        if now >= expires then D.skipped[key] = nil end
    end
end

function D.acquire(now, origin, tool_name, allowed)
    if now < D.next_scan then return nil end
    D.next_scan = now + D.SCAN_MS
    D.clean_skips(now)
    return D.farm_targets.find_target(
        origin,
        math.max(25, D.settings.num(D.P_SEARCH, 500)),
        D.farm_tools.tool_caps(tool_name),
        { allowed = allowed, skip_keys = D.skipped, check_visibility = false }
    )
end

function D.lock_target(record, now, origin, tool_name, reason)
    D.release_keys()
    D.stop_silent()
    D.target = record
    D.set_farm_noclip(true)
    D.target_tool = tool_name
    D.active_aim = nil
    D.distance = nil
    D.target_started = false
    D.harvest_confirmed = false
    D.body_only = false
    D.weak_retry_at = 0
    record.autofarm_locked_at = now
    record.autofarm_settle_until = 0
    record.autofarm_range_penalty = 0
    record.autofarm_body_retries = 0
    record.autofarm_prime_attempts = 0
    record.autofarm_prime_swing_at = 0
    record.autofarm_fallback_state = nil
    record.autofarm_fallback_weak_key = nil
    record.autofarm_fallback_weak_pos = nil
    record.autofarm_spark_repositions = 0
    record.autofarm_waiting_spark_since = 0
    record.autofarm_consumed_weak_key = nil
    record.autofarm_consumed_weak_pos = nil
    D.recover_attempts = 0
    D.recover_until = 0
    D.align_since = 0
    D.last_health = record.health
    D.last_state = record.resource_state
    D.last_weak_key = record.weak_key
    D.last_weak_pos = record.weak_pos
    D.last_progress_at = now
    D.weak_mode_since = 0
    D.weak_swings = 0
    D.total_swings = 0
    D.input_failures = 0
    D.input_failure_at = 0
    D.next_swing = 0
    D.move_sample_at, D.move_sample_pos = now, origin
    D.event("target_lock key=" .. tostring(record.key)
        .. " resource=" .. tostring(record.resource_type)
        .. " reason=" .. tostring(reason))
    D.set_phase(D.PHASE.APPROACH, reason)
end

function D.look_at(point, smooth)
    local fn = camera and (camera.look_at or camera.LookAt)
    if type(fn) ~= "function" or not point then return false end
    return pcall(fn, point.x, point.y, point.z, smooth or 1)
end

function D.alignment(camera_pos, point)
    local fn = camera and (camera.get_look_vector or camera.GetLookVector)
    if type(fn) ~= "function" then return 0 end
    local ok, look = pcall(fn)
    look = ok and D.xyz(look) or nil
    if not look then return 0 end
    local dx, dy, dz = point.x - camera_pos.x, point.y - camera_pos.y, point.z - camera_pos.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    local llen = math.sqrt(look.x * look.x + look.y * look.y + look.z * look.z)
    if len < 0.001 or llen < 0.001 then return 0 end
    return (look.x * dx + look.y * dy + look.z * dz) / (len * llen)
end

function D.body_aim(record, camera_pos)
    local center = record and record.body_pos
    local part = record and record.body_part
    if not center then return nil end
    local point = { x = center.x, y = center.y, z = center.z }
    -- Nodes must use the true center of their current Main mesh. Main shrinks
    -- and moves down each tier; clamping to camera height aims over late tiers.
    if record.kind == "Trees" and camera_pos then
        local size = part and (part.Size or part.size)
        local sy = size and tonumber(size.Y or size.y) or 0
        if sy > 0 then
            local low = center.y - sy * 0.5 + 0.2
            local high = center.y + sy * 0.5 - 0.2
            point.y = math.max(low, math.min(high, camera_pos.y))
        else
            point.y = camera_pos.y
        end
    end
    return point
end

-- Keep feet short of sparks/weak points so sprint does not walk over them.
D.SPARK_STAND_OFF = 2.25
D.SPARK_TOO_CLOSE = 1.35

function D.spark_standoff_target(record, tool_name)
    if not record then return false end
    return record.kind == "Nodes" or tool_name == "Boulder"
end

function D.navigation_aim(record, camera_pos)
    local body = record and record.body_pos
    if not body then return nil end
    if record.kind == "Trees" then
        return { x = body.x, y = camera_pos.y, z = body.z }
    end
    return { x = body.x, y = body.y, z = body.z }
end

function D.hit_aim(record, camera_pos)
    if not record then return nil end
    -- Mandatory center hit first, even when a stale/pre-existing NodeSpark is
    -- already present. Only switch to the live spark after that body swing.
    if record.kind == "Nodes" then
        if D.target_started and not D.body_only and record.weak_pos then
            return record.weak_pos
        end
        return D.body_aim(record, camera_pos)
    end
    if not D.body_only and record.weak_pos then
        return record.weak_pos
    end
    return D.navigation_aim(record, camera_pos)
end

function D.click_left()
    local fn = D.movement_api("mouse_click", "MouseClick")
    return type(fn) == "function" and pcall(fn, "left") or false
end

function D.record_progress(now, reason)
    D.harvest_confirmed = true
    D.last_progress_at = now
    D.weak_mode_since = now
    D.weak_swings = 0
    if D.target then
        D.target.autofarm_range_penalty = 0
        D.target.autofarm_body_retries = 0
        D.target.autofarm_prime_attempts = 0
        D.target.autofarm_spark_repositions = 0
        -- Node Main geometry/State changes as each tier breaks. Let its new
        -- body/spark position settle before the next aim, never re-navigate.
        if D.target.kind == "Nodes" then
            D.target.autofarm_settle_until = now + 180
        end
    end
    D.event("progress=" .. tostring(reason) .. " health=" .. tostring(D.target and D.target.health))
end

function D.position_changed(a, b)
    return a and b and D.distance3(a, b) > 0.08
end

function D.refresh_progress(now)
    if not D.target then return end
    local health = D.target.health
    local health_progress = health and D.last_health and health < D.last_health - 0.0001
    local state_progress = D.target.resource_state and D.last_state
        and D.target.resource_state ~= D.last_state
    local marker_changed = D.target.weak_key and (
        (D.last_weak_key and D.target.weak_key ~= D.last_weak_key)
        or (D.last_weak_key and D.target.weak_key == D.last_weak_key
            and D.position_changed(D.target.weak_pos, D.last_weak_pos))
        or not D.last_weak_key
    )
    local moving_weak = D.target.kind == "Nodes" or D.target.kind == "Trees"
    if moving_weak and (health_progress or state_progress) and not marker_changed then
        -- The hit was accepted, but replication has not exposed its replacement
        -- spark yet. Never aim or swing at the body during this gap.
        D.target.autofarm_waiting_spark_since = now
        D.target.autofarm_consumed_weak_key = D.last_weak_key
        D.target.autofarm_consumed_weak_pos = D.last_weak_pos
    elseif moving_weak and marker_changed then
        D.target.autofarm_waiting_spark_since = 0
        D.target.autofarm_consumed_weak_key = nil
        D.target.autofarm_consumed_weak_pos = nil
    end
    if health_progress then
        D.record_progress(now, "health")
    elseif D.last_health == nil and health ~= nil then
        D.last_health = health
    end
    if state_progress then
        D.record_progress(now, "state")
    end
    if D.target.weak_key and not D.last_weak_key and D.target_started then
        D.record_progress(now, "marker_spawn")
    elseif D.target.weak_key and D.last_weak_key
        and D.target.weak_key ~= D.last_weak_key and D.target_started
    then
        D.record_progress(now, "marker_replace")
    elseif D.target.weak_key and D.target.weak_key == D.last_weak_key
        and D.position_changed(D.target.weak_pos, D.last_weak_pos)
    then
        D.record_progress(now, "marker_move")
    end
    D.last_health = health or D.last_health
    D.last_state = D.target.resource_state or D.last_state
    D.last_weak_key = D.target.weak_key
    D.last_weak_pos = D.target.weak_pos and {
        x = D.target.weak_pos.x, y = D.target.weak_pos.y, z = D.target.weak_pos.z,
    } or nil
end

function D.begin_recovery(now, reason)
    D.recover_attempts = D.recover_attempts + 1
    local limit = D.harvest_confirmed and 5 or 3
    if D.recover_attempts > limit then
        if D.target_started then
            D.body_only = true
            D.weak_retry_at = now + 2500
            D.target.autofarm_fallback_state = D.target.resource_state
            D.target.autofarm_fallback_weak_key = D.target.weak_key
            D.target.autofarm_fallback_weak_pos = D.target.weak_pos
            D.recover_attempts = 0
            D.release_movement_keys()
            D.stop_silent()
            D.set_phase(D.PHASE.HARVEST, "recovery_body_fallback")
        else
            D.finish_target(now, "recovery_exhausted", true)
        end
        return
    end
    D.body_only = D.target_started
    if D.body_only then
        D.weak_retry_at = now + 2500
        D.target.autofarm_fallback_state = D.target.resource_state
        D.target.autofarm_fallback_weak_key = D.target.weak_key
        D.target.autofarm_fallback_weak_pos = D.target.weak_pos
    end
    D.recover_side = D.recover_attempts % 2 == 1 and D.VK.A or D.VK.D
    D.recover_until = now + D.RECOVER_MS
    D.stop_silent()
    D.set_key(D.VK.W, true)
    D.set_key(D.VK.A, D.recover_side == D.VK.A)
    D.set_key(D.VK.D, D.recover_side == D.VK.D)
    D.set_phase(D.PHASE.RECOVER, reason)
end

function D.begin_spark_reposition(now, reason)
    if not D.target or not D.target.weak_pos then
        D.begin_recovery(now, reason)
        return
    end
    local attempts = (tonumber(D.target.autofarm_spark_repositions) or 0) + 1
    D.target.autofarm_spark_repositions = attempts
    D.body_only = false
    D.weak_retry_at = 0
    D.weak_swings = 0
    D.weak_mode_since = now
    local origin = D.body_origin()
    local spark_flat = D.flat_distance(origin, D.target.weak_pos)
    local mode
    if D.target.kind == "Trees" then
        local melee_range = D.farm_tools.melee_range(D.target_tool)
        if spark_flat > math.max(2, melee_range - 0.35) then
            -- Repositioning is only for changing the ray angle at melee range.
            -- Never strafe/backpedal when TreeX actually needs an approach.
            D.release_movement_keys()
            D.stop_silent()
            D.move_sample_at, D.move_sample_pos = now, origin
            D.set_phase(D.PHASE.APPROACH, "tree_reposition_outside_range")
            return
        end
        -- TreeX sits on the trunk circumference. Orbit around the trunk toward
        -- its side instead of walking through the tree or falling back to bark.
        local body = D.target.body_pos
        local cross = 0
        if origin and body then
            local px, pz = origin.x - body.x, origin.z - body.z
            local wx = D.target.weak_pos.x - body.x
            local wz = D.target.weak_pos.z - body.z
            cross = px * wz - pz * wx
        end
        local preferred = cross >= 0 and "right" or "left"
        local opposite = preferred == "left" and "right" or "left"
        local cycle = (attempts - 1) % 4
        mode = cycle == 0 and ("arc_" .. preferred)
            or cycle == 1 and ("arc_" .. opposite)
            or cycle == 2 and preferred
            or opposite
    elseif spark_flat < D.SPARK_TOO_CLOSE + 0.15 then
        mode = "back"
    elseif spark_flat > D.SPARK_STAND_OFF + 1.0 then
        mode = "forward"
    else
        local cycle = (attempts - 1) % 4
        mode = cycle == 0 and "left"
            or cycle == 1 and "right"
            or cycle == 2 and "back_left"
            or "back_right"
    end
    D.target.autofarm_reposition_mode = mode
    local tree_mode = D.target.kind == "Trees"
    local left_mode = mode == "left" or mode == "back_left" or mode == "arc_left"
    local right_mode = mode == "right" or mode == "back_right" or mode == "arc_right"
    D.recover_side = left_mode and D.VK.A or D.VK.D
    D.recover_until = now + (tree_mode
        and math.min(520, 300 + attempts * 40)
        or math.min(850, 380 + attempts * 65))
    D.release_movement_keys()
    D.stop_silent()
    D.set_key(D.VK.SHIFT, false)
    D.set_key(D.VK.W, mode == "forward" or mode == "arc_left" or mode == "arc_right")
    D.set_key(D.VK.S, mode == "back" or mode == "back_left" or mode == "back_right")
    D.set_key(D.VK.A, left_mode)
    D.set_key(D.VK.D, right_mode)
    local label = D.target.kind == "Trees" and "tree_reposition_" or "spark_reposition_"
    D.set_phase(D.PHASE.RECOVER, label .. mode .. "_" .. tostring(reason))
end

function D.update_movement_progress(now, origin)
    if D.move_sample_at == 0 then
        D.move_sample_at, D.move_sample_pos = now, origin
        return
    end
    if now - D.move_sample_at < D.MOVE_SAMPLE_MS then return end
    local moved = D.flat_distance(origin, D.move_sample_pos)
    D.move_sample_at, D.move_sample_pos = now, origin
    if moved < 0.35 then
        if D.target and (D.target.kind == "Nodes" or D.target.kind == "Trees")
            and D.target.weak_pos
        then
            D.begin_spark_reposition(now, "stuck")
        else
            D.begin_recovery(now, "stuck")
        end
    end
end

function D.live_tool_matches(tool_name)
    return D.farm_tools.get_held_farm_tool_name() == tool_name
end

function D.swing(now, tool_name, weak)
    if now < D.next_swing then return nil end
    if not D.live_tool_matches(tool_name) then
        D.tool_until = 0
        D.finish_target(now, "tool_changed", false)
        return false
    end
    if D.click_left() then
        D.input_failures = 0
        D.input_failure_at = 0
        D.target_started = true
        D.total_swings = D.total_swings + 1
        if weak then D.weak_swings = D.weak_swings + 1 end
        D.next_swing = now + math.floor(D.farm_tools.swing_cooldown(tool_name) * 1000 + 60)
        D.event(string.format(
            "swing=%d mode=%s resource=%s dist=%.2f",
            D.total_swings, weak and "weak" or "body",
            tostring(D.target and D.target.resource_type), D.distance or -1
        ))
        return true
    else
        D.input_failures = D.input_failures + 1
        if D.input_failure_at == 0 then D.input_failure_at = now end
        D.next_swing = now + 500
        D.event("swing_failed=input count=" .. tostring(D.input_failures))
        if D.input_failures >= 3 or now - D.input_failure_at >= 3000 then
            D.input_failures = 0
            D.input_failure_at = now
            D.next_swing = now + 1000
        end
        return false
    end
end

function D.update_impl()
    local enabled = D.settings.enabled(D.P)
    if not enabled then
        if D.was_enabled or D.has_injected_key() then D.cleanup("disabled") end
        D.was_enabled = false
        return
    end
    D.was_enabled = true
    if D.menu_open() then
        D.ensure_idle("menu_open")
        return
    end
    if D.phase == D.PHASE.IDLE and D.has_injected_key() then
        D.release_keys()
        if D.has_injected_key() then return end
    end

    local now = D.now_ms()
    local origin = D.body_origin()
    if not origin then
        D.ensure_idle("no_character")
        return
    end
    local tool_name = D.current_tool(now)
    if not tool_name then
        D.ensure_idle("no_tool")
        return
    end
    local allowed = D.selected_resources()
    if not D.any_selected(allowed) then
        D.ensure_idle("no_resource_types")
        return
    end

    if D.phase == D.PHASE.IDLE or D.phase == D.PHASE.DONE then
        D.set_phase(D.PHASE.SCAN, "ready")
    end
    if D.phase == D.PHASE.SCAN then
        D.stop_silent()
        local candidate = D.acquire(now, origin, tool_name, allowed)
        if not candidate then return end
        D.lock_target(candidate, now, origin, tool_name, "target_locked")
    end

    if D.target_tool ~= tool_name then
        D.finish_target(now, "tool_changed", false)
        return
    end
    D.target = D.farm_targets.resolve(D.target)
    if not D.target then
        D.farm_targets.invalidate()
        D.finish_target(now, "depleted_or_removed", false)
        return
    end
    D.set_farm_noclip(true)
    D.refresh_progress(now)
    if D.phase == D.PHASE.PRIME and D.target_started and D.harvest_confirmed then
        D.set_phase(D.PHASE.HARVEST, "prime_confirmed")
    end
    if (D.target.autofarm_locked_at or 0) > 0
        and now - D.target.autofarm_locked_at >= 120000
    then
        D.finish_target(now, "target_timeout", "permanent")
        return
    end

    if D.phase == D.PHASE.APPROACH and not D.target_started then
        local candidate = D.acquire(now, origin, tool_name, allowed)
        if candidate and candidate.key ~= D.target.key then
            local current_d = math.sqrt(D.farm_targets.surface_distance2(D.target, origin))
            local candidate_d = math.sqrt(D.farm_targets.surface_distance2(candidate, origin))
            if candidate_d + 0.15 < current_d then
                D.lock_target(candidate, now, origin, tool_name, "closer_target")
            end
        end
    end

    local range = D.farm_tools.melee_range(tool_name)
    local body_surface_distance = math.sqrt(D.farm_targets.surface_distance2(D.target, origin))
    local should_crouch = D.target.kind == "Nodes"
        and (D.target_started or body_surface_distance <= range + 4)
    D.set_key(D.VK.C, should_crouch)
    local should_jump = (D.phase == D.PHASE.APPROACH or D.phase == D.PHASE.RECOVER)
        and D.target.body_pos ~= nil
        and D.target.body_pos.y > origin.y + 1.5
    D.set_key(D.VK.SPACE, should_jump)

    local camera_pos = D.silent_ray.get_camera_origin()
    if not camera_pos then
        D.cleanup("no_camera")
        return
    end
    local pursuing_weak = not D.body_only and D.target.weak_pos ~= nil
    local boulder = tool_name == "Boulder"
    local standoff = D.spark_standoff_target(D.target, tool_name)
    local spark_flat = (pursuing_weak and D.target.weak_pos)
        and D.flat_distance(origin, D.target.weak_pos) or nil
    local ray_budget = math.max(2, range - 0.55)
    local range_penalty = tonumber(D.target.autofarm_range_penalty) or 0
    -- First hit must be close on every resource (nodes were starting ~4+ studs out).
    local INITIAL_HIT_RANGE = 2.0
    local enter_range
    local exit_range
    -- Nodes/Boulder: drive off body surface so spark chase does not walk over it.
    if standoff then
        -- Movement range is horizontal body-surface distance. Camera height
        -- must never block a center swing when the player is physically close.
        D.distance = body_surface_distance
    elseif pursuing_weak then
        D.distance = D.distance3(camera_pos, D.target.weak_pos)
    else
        local range_aim = D.body_aim(D.target, camera_pos)
        D.distance = D.part_surface_distance3(camera_pos, D.target.body_part, range_aim)
    end
    if not D.harvest_confirmed then
        enter_range = math.max(0.85, INITIAL_HIT_RANGE - range_penalty)
        exit_range = enter_range + 0.55
    elseif standoff then
        enter_range = math.max(1.35, math.min(ray_budget, D.SPARK_STAND_OFF) - range_penalty)
        exit_range = enter_range + 0.55
    else
        enter_range = math.max(1.25, ray_budget - range_penalty)
        exit_range = enter_range + 0.45
    end

    local waiting_spark = tonumber(D.target.autofarm_waiting_spark_since) or 0
    if waiting_spark > 0 then
        local consumed_key = D.target.autofarm_consumed_weak_key
        local consumed_pos = D.target.autofarm_consumed_weak_pos
        local fresh_spark = D.target.weak_pos and (
            not consumed_key
            or D.target.weak_key ~= consumed_key
            or D.position_changed(D.target.weak_pos, consumed_pos)
        )
        if fresh_spark then
            D.target.autofarm_waiting_spark_since = 0
            D.target.autofarm_consumed_weak_key = nil
            D.target.autofarm_consumed_weak_pos = nil
            D.body_only = false
            D.release_movement_keys()
            D.set_phase(D.PHASE.HARVEST, "next_spark_ready")
        else
            D.release_movement_keys()
            D.stop_silent()
            D.active_aim = D.target.weak_pos or consumed_pos
            if D.active_aim then D.look_at(D.active_aim, 1) end
            if now - waiting_spark > 4500 then
                D.finish_target(now, "next_spark_missing", true)
            else
                D.set_phase(D.PHASE.HARVEST, "waiting_next_spark")
            end
            return
        end
    end

    if D.phase == D.PHASE.RECOVER then
        D.stop_silent()
        D.active_aim = D.hit_aim(D.target, camera_pos)
        D.look_at(D.active_aim, 3)
        if now < D.recover_until then return end
        D.release_movement_keys()
        D.move_sample_at, D.move_sample_pos = now, origin
        local weak_in_reposition_range = D.target.weak_pos
            and (D.target.kind ~= "Trees"
                or D.flat_distance(origin, D.target.weak_pos) <= math.max(2, range - 0.35))
        if D.target_started and weak_in_reposition_range and not D.body_only then
            -- The adaptive offset is complete; retry this spark directly.
            -- Re-entering approach here caused the recovery/approach loop.
            D.weak_mode_since = now
            D.set_phase(D.PHASE.HARVEST, "spark_reposition_complete")
        else
            D.set_phase(D.PHASE.APPROACH,
                D.target.kind == "Trees" and "tree_reposition_needs_approach" or "recovery_complete")
        end
    end

    if D.phase == D.PHASE.APPROACH then
        D.stop_silent()
        local nav_aim = D.navigation_aim(D.target, camera_pos)
        D.active_aim = D.hit_aim(D.target, camera_pos)
        local near_spark = standoff and spark_flat ~= nil
            and spark_flat <= D.SPARK_STAND_OFF
        local over_spark = standoff and spark_flat ~= nil
            and spark_flat <= D.SPARK_TOO_CLOSE
        -- Drop sprint once close so momentum does not carry over the spark.
        local allow_sprint = not standoff
            or (body_surface_distance > 4.0 and not near_spark)
        D.set_key(D.VK.SHIFT, allow_sprint)

        local close_enough = D.distance <= enter_range
        if not D.harvest_confirmed then
            close_enough = close_enough
                and body_surface_distance <= enter_range + 0.2
        end
        if standoff and pursuing_weak and spark_flat then
            close_enough = (body_surface_distance <= enter_range + 0.35 and near_spark)
                or over_spark
                or (body_surface_distance <= enter_range and spark_flat <= D.SPARK_STAND_OFF + 0.85)
        end

        if close_enough or over_spark then
            D.release_movement_keys()
            D.stop_silent()
            D.align_since = 0
            D.target.autofarm_settle_until = D.target.kind == "Nodes" and now + 300 or now
            D.set_phase(D.target_started and D.target.weak_pos and D.PHASE.HARVEST or D.PHASE.PRIME,
                over_spark and "spark_standoff" or "in_range")
            return
        else
            if not D.look_at(D.active_aim or nav_aim, 3) then
                if pursuing_weak and (D.target.kind == "Nodes" or D.target.kind == "Trees") then
                    D.begin_spark_reposition(now, "approach_look")
                else
                    D.begin_recovery(now, "approach_look_failed")
                end
                return
            end
            local look_target = D.active_aim or nav_aim
            if D.alignment(camera_pos, look_target) >= D.AIM_DOT.approach then
                D.align_since = 0
                D.set_key(D.VK.A, false)
                D.set_key(D.VK.D, false)
                -- Stop only based on spark proximity; body distance alone
                -- cannot tell whether the spark is reachable yet.
                local walk = not near_spark
                if walk then
                    if not D.set_key(D.VK.W, true) then
                        D.finish_target(now, "movement_api_unavailable", true)
                        return
                    end
                    D.update_movement_progress(now, origin)
                else
                    D.set_key(D.VK.W, false)
                    D.release_movement_keys()
                    D.set_phase(D.target_started and D.target.weak_pos and D.PHASE.HARVEST or D.PHASE.PRIME, "spark_hold")
                end
            else
                D.set_key(D.VK.W, false)
                if D.align_since == 0 then D.align_since = now end
                if now - D.align_since > 1500 then
                    D.align_since = 0
                    if pursuing_weak and (D.target.kind == "Nodes" or D.target.kind == "Trees") then
                        D.begin_spark_reposition(now, "approach_alignment")
                    else
                        D.begin_recovery(now, "approach_alignment")
                    end
                end
            end
            return
        end
    end

    if D.phase == D.PHASE.PRIME then
        if now < (D.target.autofarm_settle_until or 0) then return end
        -- Already inside spark standoff: stay put and D.swing, do not walk closer.
        if standoff and spark_flat and spark_flat <= D.SPARK_STAND_OFF then
            -- keep priming in place
        elseif not D.harvest_confirmed and not D.target_started
            and (D.distance > enter_range or body_surface_distance > enter_range + 0.2)
        then
            D.stop_silent()
            D.move_sample_at, D.move_sample_pos = now, origin
            D.set_phase(D.PHASE.APPROACH, "prime_too_far")
            return
        end
        if D.target_started and not D.target.weak_pos
            and (D.target.autofarm_prime_swing_at or 0) > 0
        then
            -- Give the server a brief chance to spawn the first spark. If it
            -- does not appear, the first body D.swing was likely just outside
            -- real melee reach: close the gap before trying again.
            if now - D.target.autofarm_prime_swing_at < 350 then
                return
            end
            D.target.autofarm_prime_swing_at = 0
            if standoff then
                local attempts = tonumber(D.target.autofarm_prime_attempts) or 0
                if attempts >= 3 and not D.harvest_confirmed then
                    -- Camera was centered but the body ray did not register.
                    -- Step in by 0.25 studs, bounded by the 0.85 surface floor.
                    D.target.autofarm_prime_attempts = 0
                    D.target.autofarm_range_penalty = math.min(
                        math.max(0, range - 1.25),
                        (tonumber(D.target.autofarm_range_penalty) or 0) + 0.25
                    )
                    D.target_started = false
                    D.stop_silent()
                    D.move_sample_at, D.move_sample_pos = now, origin
                    D.set_phase(D.PHASE.APPROACH, "node_prime_step_in")
                else
                    D.target.autofarm_settle_until = now + 120
                    D.set_phase(D.PHASE.PRIME, "node_prime_center_retry")
                end
            else
                D.target.autofarm_range_penalty = math.min(
                    math.max(0, range - 1.25),
                    (tonumber(D.target.autofarm_range_penalty) or 0) + 0.3
                )
                D.stop_silent()
                D.move_sample_at, D.move_sample_pos = now, origin
                D.set_phase(D.PHASE.APPROACH, "prime_no_marker_close")
            end
            return
        end
        local prime_weak = D.target_started
            and not D.body_only
            and D.target.weak_pos ~= nil
        D.active_aim = D.hit_aim(D.target, camera_pos)
        local prime_view = D.active_aim
        D.release_movement_keys()
        if not D.look_at(prime_view, 1) then
            if prime_weak and (D.target.kind == "Nodes" or D.target.kind == "Trees") then
                D.begin_spark_reposition(now, "prime_look")
            else
                D.begin_recovery(now, "prime_look_failed")
            end
            return
        end
        if D.alignment(camera_pos, prime_view) < (prime_weak and D.AIM_DOT.weak or D.AIM_DOT.body) then
            if D.align_since == 0 then D.align_since = now end
            if now - D.align_since > 1200 then
                D.align_since = 0
                if prime_weak and (D.target.kind == "Nodes" or D.target.kind == "Trees") then
                    D.begin_spark_reposition(now, "prime_alignment")
                else
                    D.begin_recovery(now, "prime_alignment")
                end
            end
            return
        end
        D.align_since = 0
        if not D.track_silent_farm(camera_pos, D.active_aim) then
            D.finish_target(now, "silent_unavailable", true)
            return
        end
        if now >= D.next_swing then
            local clicked = D.swing(now, tool_name, prime_weak)
            if clicked and D.target then
                D.weak_mode_since = now
                if prime_weak then
                    D.set_phase(D.PHASE.HARVEST, "weak_primed")
                else
                    local attempts = (tonumber(D.target.autofarm_prime_attempts) or 0) + 1
                    D.target.autofarm_prime_attempts = attempts
                    D.target.autofarm_prime_swing_at = now
                    if standoff then
                        -- Keep direct-center priming; the bounded step-in above
                        -- handles genuine misses without a phase ping-pong.
                        D.set_phase(D.PHASE.PRIME, "node_body_prime_wait")
                    elseif attempts >= 2 then
                        D.target.autofarm_prime_attempts = 0
                        D.target.autofarm_range_penalty = math.min(
                            math.max(0, range - 1.25),
                            (tonumber(D.target.autofarm_range_penalty) or 0) + 0.3
                        )
                        D.stop_silent()
                        D.move_sample_at, D.move_sample_pos = now, origin
                        D.set_phase(D.PHASE.APPROACH, "prime_unconfirmed_close")
                    else
                        D.set_phase(D.PHASE.PRIME, "body_prime_wait")
                    end
                end
            end
        end
        return
    end

    if D.phase ~= D.PHASE.HARVEST then return end
    if now < (D.target.autofarm_settle_until or 0) then return end
    -- Standoff harvest: only re-approach if we drifted away from the body,
    -- never because the spark is "far" while standing on the node.
    local too_far = D.distance > exit_range
    if standoff then
        -- Live node meshes shrink after each tier. The current body/spark is
        -- still hit-valid from this position, so do not oscillate back into
        -- APPROACH just because an old surface measurement changed.
        too_far = not D.target_started
            and body_surface_distance > exit_range + 0.75
            and (not spark_flat or spark_flat > D.SPARK_STAND_OFF + 1.25)
    end
    if too_far then
        D.release_movement_keys()
        D.stop_silent()
        D.move_sample_at, D.move_sample_pos = now, origin
        D.set_phase(D.PHASE.APPROACH, "outside_range")
        return
    end
    if D.total_swings >= 8 and now - D.last_progress_at > D.NO_PROGRESS_MS then
        D.last_progress_at = now
        if (D.target.kind == "Nodes" or D.target.kind == "Trees") and D.target.weak_pos then
            -- Never abandon a valid resource weak point for body fallback.
            D.begin_spark_reposition(now, "node_no_progress")
            return
        end
        D.body_only = D.target.weak_pos == nil
        D.weak_retry_at = now + 2500
        D.target.autofarm_fallback_state = D.target.resource_state
        D.target.autofarm_fallback_weak_key = D.target.weak_key
        D.target.autofarm_fallback_weak_pos = D.target.weak_pos
        D.weak_swings = 0
        D.weak_mode_since = now
    end

    -- A fallback only retries after a *new* node tier/spark. Reusing the old
    -- marker is what sent us back into the approach/in-range loop.
    local fresh_weak = D.target.weak_pos and (
        D.target.resource_state ~= D.target.autofarm_fallback_state
        or D.target.weak_key ~= D.target.autofarm_fallback_weak_key
        or D.position_changed(D.target.weak_pos, D.target.autofarm_fallback_weak_pos)
    )
    if D.body_only and fresh_weak and now >= D.weak_retry_at then
        D.body_only = false
        D.target.autofarm_fallback_state = nil
        D.target.autofarm_fallback_weak_key = nil
        D.target.autofarm_fallback_weak_pos = nil
        D.weak_swings = 0
        D.weak_mode_since = now
    end
    local use_weak = not D.body_only and D.target.weak_pos ~= nil
    if not use_weak and D.total_swings >= 2
        and now - D.last_progress_at > (boulder and 2400 or 4000)
    then
        local retries = (tonumber(D.target.autofarm_body_retries) or 0) + 1
        D.target.autofarm_body_retries = retries
        if retries >= 4 then
            D.finish_target(now, "body_no_progress", true)
            return
        end
        local step = boulder and 0.55 or 0.35
        D.target.autofarm_range_penalty = math.min(
            math.max(0, range - 1.25),
            (tonumber(D.target.autofarm_range_penalty) or 0) + step
        )
        D.last_progress_at = now
        if standoff then
            D.body_only = true
            D.weak_retry_at = now + 2500
            D.target.autofarm_fallback_state = D.target.resource_state
            D.target.autofarm_fallback_weak_key = D.target.weak_key
            D.target.autofarm_fallback_weak_pos = D.target.weak_pos
            D.target.autofarm_settle_until = now + 180
            D.set_phase(D.PHASE.HARVEST, "body_retry_live_node")
        else
            D.stop_silent()
            D.move_sample_at, D.move_sample_pos = now, origin
            D.set_phase(D.PHASE.APPROACH, "body_no_progress_close")
        end
        return
    end
    local weak_fail_swings = boulder and 3 or 2
    local weak_fail_ms = boulder and 4000 or 2500
    if use_weak and D.weak_swings >= weak_fail_swings
        and now - D.weak_mode_since > weak_fail_ms
    then
        D.weak_swings = 0
        D.weak_mode_since = now
        if D.target.kind == "Nodes" or D.target.kind == "Trees" then
            D.begin_spark_reposition(now, "weak_no_progress")
        else
            D.begin_recovery(now, "weak_no_progress")
        end
        return
    end

    D.active_aim = D.hit_aim(D.target, camera_pos)
    local view_aim = D.active_aim
    D.release_movement_keys()
    if not D.look_at(view_aim, 1) then
        D.stop_silent()
        if use_weak then
            if D.target.kind == "Nodes" or D.target.kind == "Trees" then
                D.begin_spark_reposition(now, "weak_look")
            else
                D.begin_recovery(now, "weak_look_failed")
            end
        else
            D.begin_recovery(now, "body_look_failed")
        end
        return
    end
    local required_dot = use_weak and D.AIM_DOT.weak or D.AIM_DOT.body
    if D.alignment(camera_pos, view_aim) < required_dot then
        D.stop_silent()
        if D.align_since == 0 then D.align_since = now end
        if use_weak and now - D.align_since > 1200 then
            D.align_since = 0
            if D.target.kind == "Nodes" or D.target.kind == "Trees" then
                D.begin_spark_reposition(now, "weak_alignment")
            else
                D.begin_recovery(now, "weak_alignment")
            end
        elseif not use_weak and now - D.align_since > 1200 then
            D.align_since = 0
            D.begin_recovery(now, "body_alignment")
        end
        return
    end
    D.align_since = 0

    if not D.track_silent_farm(camera_pos, D.active_aim) then
        D.finish_target(now, "silent_unavailable", true)
        return
    end
    D.swing(now, tool_name, use_weak)
end

function M.register_menu()
    pcall(function() D.custom_menu_ref = April.require("ui.custom_menu") end)
    local G = D.menu_util.G
    local T = D.menu_util.group(G.MISC)
    local root = D.menu_util.parent(D.P)
    D.menu_util.section(T, G.MISC, "Autofarm")
    D.menu_util.register_keybind(T, G.MISC, D.P, "Autofarm", false)
    menu.add_multicombo(T, G.MISC, D.P_RESOURCES, "Farm Resources", {
        "Trees", "Stone", "Metal", "Phosphate",
    }, { true, true, true, true }, root)
    menu.add_slider_int(T, G.MISC, D.P_SEARCH, "Search Range", 50, 2000, 500, root)
    menu.add_checkbox(T, G.MISC, D.P_DEBUG, "Debug Target Path", false, root)
    D.menu_util.bind_children(D.P, { D.P_RESOURCES, D.P_SEARCH, D.P_DEBUG })
end

function M.update()
    local ok, err = pcall(D.update_impl)
    if ok then return end
    D.event("ERROR " .. tostring(err))
    D.cleanup("lua_error")
    error(err)
end

function M.draw()
    if not D.settings.bool(D.P_DEBUG, false) or not D.settings.enabled(D.P) then return end
    local sw, sh = D.draw_util.screen_size()
    local col = D.theme.CYAN or { 0.25, 0.9, 1, 1 }
    if D.active_aim then
        local tx, ty, on_screen = D.esp_util.w2s(D.active_aim.x, D.active_aim.y, D.active_aim.z)
        if on_screen then
            D.draw_util.snapline(tx, ty, col, 1.5, sw, sh)
            D.draw_util.circle(tx, ty, 7, col, false)
        end
    end
    local text = tostring(D.phase)
    if D.phase_reason then text = text .. " (" .. tostring(D.phase_reason) .. ")" end
    if D.target then text = text .. " | " .. tostring(D.target.resource_type) end
    if D.body_only then text = text .. " | body fallback" end
    if D.distance then text = text .. string.format(" | %.1f studs", D.distance) end
    if D.held_tool then text = text .. " | " .. tostring(D.held_tool) end
    D.draw_util.text_centered(sw * 0.5, sh - 72, text, col, 12)
end

function M.get_target()
    return D.target
end

function M.is_active()
    return D.settings.enabled(D.P)
end

return M

