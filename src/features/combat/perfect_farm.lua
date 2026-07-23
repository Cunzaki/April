--[[
  Farm helper — only scans / aims when a gather target is inside tool range.

  Idle  (always-on OK): rare cheap discovery scan, silent OFF
  Active (in range):    aim at TreeX / NodeSpark; no world scan each frame
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local farm_tools = April.require("game.farm_tools")
local farm_targets = April.require("game.farm_targets")
local menu_util = April.require("core.menu_util")
local silent_ray = April.require("core.silent_ray")

local M = {}

local P = "april_farm_helper"
local P_RADIUS = "april_farm_radius"
local P_SMOOTH = "april_farm_smooth"
local P_SILENT = "april_farm_silent"
local SHOOT_VK = 0x01

-- Idle = far from anything (slow scan). Active = locked in range (validate only).
local IDLE_SCAN_MS = 900
local ACTIVE_RESERVE_MS = 700 -- occasional upgrade TreeX/spark while farming
local TOOL_CACHE_MS = 250
local LOCK_PAD = 1.15

local locked_part = nil
local active = false
local next_scan_ms = 0
local cached_tool = nil
local cached_tool_until = 0
local silent_on = false

M._tracking = false

local function now_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function part_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local p = part.Position or part.position
    if not p or p.x == nil then return nil end
    return p
end

local function dist2(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function body_origin()
    local lp = env.get_local_player()
    if lp then
        local pos = lp.position or lp.Position
        if pos and pos.x ~= nil then return pos end
        local char = lp.character
        if char and env.is_valid(char) then
            local hrp = env.safe_call(function()
                return char:find_first_child("HumanoidRootPart") or char:FindFirstChild("HumanoidRootPart")
            end)
            local p = part_pos(hrp)
            if p then return p end
        end
    end
    return silent_ray.get_camera_origin()
end

local function held_tool()
    local t = now_ms()
    if cached_tool and t < cached_tool_until then
        return cached_tool
    end
    farm_tools.load()
    cached_tool = farm_tools.get_held_farm_tool_name()
    cached_tool_until = t + TOOL_CACHE_MS
    return cached_tool
end

-- Strict: only tool melee reach, capped by slider (never search the whole forest).
local function radius_for(tool_name)
    local tool_range = farm_tools.melee_range(tool_name)
    local slider = settings.num(P_RADIUS, 7)
    if slider <= 0 then return 0 end
    return math.min(slider, tool_range + 0.35)
end

local function tool_caps(tool_name)
    local caps = farm_tools.tool_caps(tool_name)
    if caps then return caps end
    return { Trees = true, Nodes = true, Logs = true, Cactus = true }
end

local function in_range(part, origin, radius)
    local pos = part_pos(part)
    if not pos or not origin then return false end
    local lim = radius * LOCK_PAD
    return dist2(pos, origin) <= lim * lim
end

local function stop_silent()
    if not silent_on and not M._tracking then return end
    silent_ray.stop()
    silent_on = false
    M._tracking = false
end

local function deactivate()
    locked_part = nil
    active = false
    stop_silent()
end

local function clear_all()
    deactivate()
    next_scan_ms = 0
    cached_tool = nil
    cached_tool_until = 0
end

local function try_discover(origin, radius, tool_name)
    local t = now_ms()
    if t < next_scan_ms then return nil end
    next_scan_ms = t + (active and ACTIVE_RESERVE_MS or IDLE_SCAN_MS)

    return farm_targets.find_nearest(origin, radius, tool_caps(tool_name))
end

local function aim_at(cam, aim)
    local use_silent = settings.bool(P_SILENT, false) and silent_ray.available()
    if use_silent then
        silent_ray.ensure_hook()
        silent_ray.track(cam, aim, SHOOT_VK, aim)
        silent_on = true
        M._tracking = true
        return
    end
    stop_silent()
    if camera and camera.look_at then
        local smooth = math.max(1, settings.num(P_SMOOTH, 8))
        pcall(camera.look_at, aim.x, aim.y, aim.z, smooth)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Farm")
    menu_util.register_keybind(T, G.MISC, P, "Farm Helper", false)
    menu.add_checkbox(T, G.MISC, P_SILENT, "Silent Farm", false, root)
    menu_util.gap(T, G.MISC)
    menu.add_slider_int(T, G.MISC, P_RADIUS, "Farm Range (studs)", 1, 10, 7, root)
    menu.add_slider_int(T, G.MISC, P_SMOOTH, "Camera Smoothness", 1, 30, 8, root)
    menu_util.bind_children(P, { P_SILENT, P_RADIUS, P_SMOOTH })
end

function M.update(_dt)
    if not settings.enabled(P) then
        clear_all()
        return
    end

    local tool_name = held_tool()
    if not tool_name then
        clear_all()
        return
    end

    local body = body_origin()
    local cam = silent_ray.get_camera_origin()
    if not body or not cam then
        deactivate()
        return
    end

    local radius = radius_for(tool_name)
    if radius <= 0 then
        clear_all()
        return
    end

    -- Active: stay on current spark/X while it remains in tool range.
    if active and locked_part and in_range(locked_part, body, radius) then
        -- Rare refresh for better marker; otherwise zero world scanning.
        local refreshed = try_discover(body, radius, tool_name)
        if refreshed then
            locked_part = refreshed
        end
        local aim = part_pos(locked_part)
        if aim then
            aim_at(cam, aim)
            return
        end
        deactivate()
    elseif active then
        -- Walked out of range — shut off aim/silent immediately.
        deactivate()
        next_scan_ms = 0 -- allow quick rediscover if still near something else
    end

    -- Idle: only occasional discovery. No silent / camera until something is in range.
    local found = try_discover(body, radius, tool_name)
    if found and in_range(found, body, radius) then
        locked_part = found
        active = true
        local aim = part_pos(found)
        if aim then
            aim_at(cam, aim)
        end
        return
    end

    -- Nothing in tool range — stay cold.
    stop_silent()
end

return M
