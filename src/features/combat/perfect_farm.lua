--[[
  Farm helper - silent or camera aim at gather hit parts.
  Melee uses camera / mouse unit-ray origin (RaycastUtil.MouseRaycast).

  Perf: spatial index in farm_targets (budgeted); no full Trees/Nodes walks
  on the ESP frame. Tool name + near list are rate-limited.
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local debug = April.require("core.debug")
local farm_tools = April.require("game.farm_tools")
local farm_targets = April.require("game.farm_targets")
local math_util = April.require("core.math_util")
local menu_util = April.require("core.menu_util")
local silent_ray = April.require("core.silent_ray")
local esp_util = April.require("core.esp_util")

local M = {}

local P = "april_farm_helper"
local P_RADIUS = "april_farm_radius"
local P_SMOOTH = "april_farm_smooth"
local P_SILENT = "april_farm_silent"

local gather_parts = {}
local locked_part = nil
local lock_grace_until = 0
local next_scan_ms = 0
local next_pick_ms = 0
local last_tool = nil
local cached_tool = nil
local cached_tool_ms = 0
local TOOL_CACHE_MS = 120

-- Unlocked: scan often enough to acquire. Locked: rarely (index still ticks).
local SCAN_MS_UNLOCKED = 350
local SCAN_MS_LOCKED = 900
local PICK_MS = 50
local LOCK_GRACE_MS = 500
local PICK_FOV = 240
local MAX_NEAR = 14

M._tracking = false

local cx, cy = 960, 540
local cx_init = false

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function ensure_screen_center()
    if cx_init then return end
    if draw and draw.get_screen_size then
        cx, cy = draw.get_screen_size()
        cx, cy = cx * 0.5, cy * 0.5
    elseif utility and utility.get_screen_size then
        cx, cy = utility.get_screen_size()
        cx, cy = cx * 0.5, cy * 0.5
    end
    cx_init = true
end

local function part_position(part)
    if not part or not env.is_valid(part) then return nil end
    local pos = part.Position or part.position
    if not pos or pos.x == nil then return nil end
    return pos
end

local function unpack_pos(v)
    if not v then return nil end
    if v.x ~= nil then return v.x, v.y, v.z end
    if v.X ~= nil then return v.X, v.Y, v.Z end
    return nil
end

local function dist2(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function character_origin()
    local lp = env.get_local_player()
    if not lp then return nil end
    local char = lp.character
    if char and env.is_valid(char) then
        local hrp = env.safe_call(function()
            return char:find_first_child("HumanoidRootPart") or char:FindFirstChild("HumanoidRootPart")
        end)
        local pos = part_position(hrp)
        if pos then return pos end
    end
    local px, py, pz = unpack_pos(lp.position or lp.Position)
    if px then return { x = px, y = py, z = pz } end
    return nil
end

local function held_tool_cached()
    local now = tick_ms()
    if cached_tool and (now - cached_tool_ms) < TOOL_CACHE_MS then
        return cached_tool
    end
    farm_tools.load()
    cached_tool = farm_tools.get_held_farm_tool_name()
    cached_tool_ms = now
    return cached_tool
end

local function refresh_near(scan_origin, radius, allow, locked)
    local now = tick_ms()
    local interval = locked and SCAN_MS_LOCKED or SCAN_MS_UNLOCKED
    if now < next_scan_ms then
        -- Still advance spatial index cheaply so new trees appear.
        farm_targets.tick_index(#gather_parts == 0)
        return
    end
    next_scan_ms = now + interval
    if #gather_parts == 0 then
        farm_targets.tick_index(true)
    end
    farm_targets.collect_near(scan_origin, radius, gather_parts, MAX_NEAR, allow)
end

local function ray_origin()
    return silent_ray.get_camera_origin()
end

local function effective_radius(tool_name)
    local tool_range = farm_tools.melee_range(tool_name)
    local slider = settings.num(P_RADIUS, 7)
    if slider <= 0 then return 0 end
    return math.min(slider, tool_range + 0.5)
end

local function target_valid(part, origin, radius, loose)
    if not env.is_valid(part) then return false end
    local pos = part_position(part)
    if not pos or not origin then return false end
    local limit = loose and (radius * 1.4) or radius
    return dist2(pos, origin) <= limit * limit
end

local function pick_target(origin, radius)
    ensure_screen_center()

    local best_part = nil
    local best_score = math.huge
    local best_fov = math.huge
    local nearest_part = nil
    local nearest_d2 = math.huge
    local r2 = radius * radius

    for i = 1, #gather_parts do
        local part = gather_parts[i]
        if env.is_valid(part) then
            local pos = part_position(part)
            if pos then
                local d2 = dist2(pos, origin)
                if d2 <= r2 then
                    if d2 < nearest_d2 then
                        nearest_d2 = d2
                        nearest_part = part
                    end

                    local sx, sy, on_screen = esp_util.w2s(pos.x, pos.y, pos.z)
                    if on_screen then
                        local fov = math_util.screen_fov_dist(sx, sy, cx, cy)
                        local score = fov * 0.85 + d2 * 2.0e-4
                        if score < best_score then
                            best_score = score
                            best_fov = fov
                            best_part = part
                        end
                    end
                end
            end
        end
    end

    if best_part and best_fov <= PICK_FOV then
        return best_part
    end
    return nearest_part
end

local function resolve_target(origin, radius, force_pick)
    local now = tick_ms()

    if locked_part and target_valid(locked_part, origin, radius, true) then
        lock_grace_until = now + LOCK_GRACE_MS
        return locked_part
    end

    if locked_part and now < lock_grace_until and env.is_valid(locked_part) and part_position(locked_part) then
        return locked_part
    end

    if not force_pick and now < next_pick_ms then
        return locked_part
    end
    next_pick_ms = now + PICK_MS

    local picked = pick_target(origin, radius)
    if picked then
        locked_part = picked
        lock_grace_until = now + LOCK_GRACE_MS
        return picked
    end

    locked_part = nil
    lock_grace_until = 0
    return nil
end

local function silent_mode()
    return settings.bool(P_SILENT, true) and silent_ray.available()
end

local function stop_silent()
    if not M._tracking then return end
    silent_ray.stop()
    M._tracking = false
end

local function clear_lock()
    locked_part = nil
    lock_grace_until = 0
    gather_parts = {}
    next_scan_ms = 0
    next_pick_ms = 0
    last_tool = nil
    cached_tool = nil
    cached_tool_ms = 0
end

local function apply_silent(origin, aim)
    if not silent_ray.ensure_hook() then
        debug.error_once("farm:silent", "Silent farm hook unavailable - toggle Silent Farm off for camera aim")
        return false
    end

    -- Continuous set_target only — track(key) fails between LMB presses and used to tear down aim.
    local ok = false
    if silent_ray.set_target then
        ok = silent_ray.set_target(origin, aim, aim) == true
    elseif silent_ray.track then
        ok = silent_ray.track(origin, aim, 0x01, aim) == true
    end

    if ok then
        M._tracking = true
        return true
    end

    if M._tracking then
        return true
    end

    debug.error_once("farm:silent", "Silent farm hook unavailable - toggle Silent Farm off for camera aim")
    return false
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Farm")
    menu_util.register_keybind(T, G.MISC, P, "Farm Helper", false)
    menu.add_checkbox(T, G.MISC, P_SILENT, "Silent Farm", true, root)
    menu_util.gap(T, G.MISC)
    menu.add_slider_int(T, G.MISC, P_RADIUS, "Farm Range (studs)", 1, 10, 7, root)
    menu.add_slider_int(T, G.MISC, P_SMOOTH, "Camera Smoothness", 1, 30, 8, root)
    menu_util.bind_children(P, { P_SILENT, P_RADIUS, P_SMOOTH })
end

function M.update(_dt)
    if not settings.enabled(P) then
        stop_silent()
        clear_lock()
        return
    end

    local tool_name = held_tool_cached()
    if not tool_name then
        stop_silent()
        clear_lock()
        return
    end

    if tool_name ~= last_tool then
        last_tool = tool_name
        next_scan_ms = 0
        locked_part = nil
    end

    local cam_origin = ray_origin()
    if not cam_origin then
        stop_silent()
        return
    end

    local radius = effective_radius(tool_name)
    if radius <= 0 then
        stop_silent()
        return
    end

    local allow = farm_tools.gather_kinds(tool_name)
    local scan_origin = character_origin() or cam_origin
    local locked_ok = locked_part and target_valid(locked_part, scan_origin, radius, true)

    refresh_near(scan_origin, radius, allow, locked_ok == true)

    local target = resolve_target(scan_origin, radius, locked_ok ~= true)
    if not target then
        stop_silent()
        return
    end

    local aim = part_position(target)
    if not aim then
        stop_silent()
        return
    end

    if silent_mode() then
        if not apply_silent(cam_origin, aim) then
            -- Fall back to camera so farming still works without silent hook.
            if camera and camera.look_at then
                local smooth = math.max(1, settings.num(P_SMOOTH, 8))
                pcall(camera.look_at, aim.x, aim.y, aim.z, smooth)
            end
        end
        return
    end

    stop_silent()
    if not camera or not camera.look_at then return end
    local smooth = math.max(1, settings.num(P_SMOOTH, 8))
    pcall(camera.look_at, aim.x, aim.y, aim.z, smooth)
end

return M
