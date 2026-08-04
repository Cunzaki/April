-- Silent farm helper. Selects a resource model, then resolves its live
-- TreeX.Main / NodeSpark.Main every frame while LMB is held.
local settings = April.require("core.settings")
local env = April.require("core.env")
local farm_tools = April.require("game.farm_tools")
local farm_targets = April.require("game.farm_targets")
local menu_util = April.require("core.menu_util")
local silent_ray = April.require("core.silent_ray")

local M = {}

local P = "april_farm_helper"
local P_RADIUS = "april_farm_radius"
local SHOOT_VK = 0x01

local TARGET_SCAN_MS = 75
local TOOL_CACHE_MS = 150
local SWITCH_MARGIN = 0.35

local locked_target = nil
local locked_tool = nil
local next_target_scan = 0
local cached_tool = nil
local cached_tool_until = 0
local was_enabled = false

M._tracking = false

local function now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

local function held_tool()
    local now = now_ms()
    if now < cached_tool_until then return cached_tool end
    farm_tools.load()
    cached_tool = farm_tools.get_held_farm_tool_name()
    cached_tool_until = now + TOOL_CACHE_MS
    return cached_tool
end

local function position_of(value)
    if not value then return nil end
    local x, y, z = value.x or value.X, value.y or value.Y, value.z or value.Z
    if x == nil or y == nil or z == nil then return nil end
    return { x = x, y = y, z = z }
end

local function body_origin()
    local player = env.get_local_player()
    local direct = player and position_of(player.position or player.Position)
    if direct then return direct end
    local character = player and (player.character or player.Character)
    if character and env.is_valid(character) then
        local root = env.safe_call(function()
            if character.FindFirstChild then
                return character:FindFirstChild("HumanoidRootPart")
            end
            if character.find_first_child then
                return character:find_first_child("HumanoidRootPart")
            end
        end)
        if root and env.is_valid(root) then
            local pos = position_of(root.Position or root.position)
            if pos then return pos end
        end
    end
    return silent_ray.get_camera_origin()
end

local function radius_for(tool_name)
    local configured = settings.num(P_RADIUS, 7)
    if configured <= 0 then return 0 end
    return math.min(configured, farm_tools.melee_range(tool_name))
end

local function tool_caps(tool_name)
    return farm_tools.tool_caps(tool_name)
        or { Trees = true, Nodes = true, Logs = true, Cactus = true }
end

local function stop_tracking()
    if M._tracking then silent_ray.stop() end
    M._tracking = false
end

local function clear_lock(invalidate_index, reset_tool_cache)
    locked_target = nil
    locked_tool = nil
    next_target_scan = 0
    if reset_tool_cache then
        cached_tool = nil
        cached_tool_until = 0
    end
    stop_tracking()
    if invalidate_index then farm_targets.invalidate() end
end

local function in_range(target, origin, radius)
    if not target or not target.pos or not origin then return false end
    return farm_targets.distance2(target.pos, origin) <= radius * radius
end

local function choose_target(origin, radius, caps)
    local candidate = farm_targets.find_target(origin, radius, caps)
    local current = farm_targets.resolve(locked_target)

    if current and not in_range(current, origin, radius) then
        current = nil
    end
    if not candidate then return current end
    if not current or candidate.model == current.model or candidate.key == current.key then
        return candidate
    end

    local current_d = math.sqrt(farm_targets.distance2(current.pos, origin))
    local candidate_d = math.sqrt(farm_targets.distance2(candidate.pos, origin))
    if candidate_d + SWITCH_MARGIN < current_d then
        return candidate
    end
    return current
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Farm")
    menu_util.register_keybind(T, G.MISC, P, "Farm Helper", false)
    menu.add_slider_int(T, G.MISC, P_RADIUS, "Farm Range (studs)", 1, 10, 7, root)
    menu_util.bind_children(P, { P_RADIUS })
end

function M.update(_dt)
    -- Autofarm owns movement, clicks, and the silent ray while enabled.
    if settings.enabled("april_autofarm") then
        if was_enabled then clear_lock(true, true) end
        was_enabled = false
        return
    end
    if not settings.enabled(P) then
        if was_enabled then clear_lock(true, true) end
        was_enabled = false
        return
    end
    was_enabled = true

    local tool_name = held_tool()
    if not tool_name then
        clear_lock(false)
        return
    end
    if locked_tool and locked_tool ~= tool_name then
        locked_target = nil
        next_target_scan = 0
        stop_tracking()
    end
    locked_tool = tool_name

    if not silent_ray.available() then
        clear_lock(false)
        return
    end

    local origin = body_origin()
    local camera_origin = silent_ray.get_camera_origin()
    local radius = radius_for(tool_name)
    if not origin or not camera_origin or radius <= 0 then
        clear_lock(false)
        return
    end

    -- Marker instances can move or be replaced after every successful weak hit.
    -- Resolve the current model every frame; only the nearby-model query is throttled.
    locked_target = farm_targets.resolve(locked_target)
    local now = now_ms()
    if now >= next_target_scan or not locked_target then
        next_target_scan = now + TARGET_SCAN_MS
        locked_target = choose_target(origin, radius, tool_caps(tool_name))
    end

    if not locked_target or not in_range(locked_target, origin, radius) then
        locked_target = nil
        stop_tracking()
        return
    end

    M._tracking = silent_ray.track(
        camera_origin,
        locked_target.pos,
        SHOOT_VK,
        locked_target.pos
    ) == true
    if not M._tracking then silent_ray.stop() end
end

function M.get_target()
    return locked_target
end

return M
