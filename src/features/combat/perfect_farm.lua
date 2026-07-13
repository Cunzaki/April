local settings = April.require("core.settings")
local env = April.require("core.env")
local debug = April.require("core.debug")
local folders = April.require("game.folders")
local farm_tools = April.require("game.farm_tools")
local math_util = April.require("core.math_util")
local menu_util = April.require("core.menu_util")
local silent_ray = April.require("core.silent_ray")

local M = {}

local P = "april_farm_helper"
local P_RADIUS = "april_farm_radius"
local P_SMOOTH = "april_farm_smooth"
local P_SILENT = "april_farm_silent"
local SHOOT_VK = 0x01

local spark_parts = {}
local next_scan_ms = 0
local SCAN_MS = 350
M._tracking = false

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        return parent:find_first_child(name) or parent:FindFirstChild(name)
    end)
end

local function part_position(part)
    if not part or not env.is_valid(part) then return nil end
    local pos = part.Position or part.position
    if not pos or pos.x == nil then return nil end
    return pos
end

local function vec3_position(value)
    if not value then return nil end
    if value.x ~= nil then
        return { x = value.x, y = value.y, z = value.z }
    end
    if value[1] then
        return { x = value[1], y = value[2], z = value[3] }
    end
    return nil
end

local function camera_controller()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end
    return find_child(char, "CameraController")
end

local function viewmodel_origin()
    local cc = camera_controller()
    if cc and env.is_valid(cc) then
        local cf = env.safe_call(function() return cc:GetAttribute("ViewmodelCFrame") end)
        local pos = vec3_position(cf and (cf.Position or cf.position))
        if pos then return pos end
    end

    if camera and camera.get_position then
        local cam = camera.get_position()
        return vec3_position(cam)
    end

    return nil
end

local function spark_part_from_model(model)
    if not env.is_valid(model) then return nil end

    local spark = find_child(model, "NodeSpark") or find_child(model, "TreeX")
    if not spark or not env.is_valid(spark) then return nil end

    local main = env.safe_call(function() return spark.PrimaryPart end)
    if main and env.is_valid(main) then return main end

    main = find_child(spark, "Main")
    if main and env.is_valid(main) then return main end

    return nil
end

local function scan_folder(folder, out)
    if not env.is_valid(folder) then return end
    for _, model in ipairs(folders.scan_children(folder, "Model", 250)) do
        local part = spark_part_from_model(model)
        if part then
            table.insert(out, part)
        end
    end
end

local function refresh_sparks()
    local now = tick_ms()
    if now < next_scan_ms then return end
    next_scan_ms = now + SCAN_MS

    local out = {}
    scan_folder(folders.from_key("nodes"), out)
    scan_folder(folders.from_key("plants"), out)
    scan_folder(folders.get_folder("Trees"), out)
    spark_parts = out
end

local function player_position(lp)
    if not lp then return nil end

    if lp.position and lp.position.x ~= nil then
        return lp.position
    end

    local char = lp.character
    if not char and game and game.local_player then
        char = game.local_player.character
    end
    if not char then return nil end

    local root = find_child(char, "HumanoidRootPart")
    return part_position(root)
end

local function nearest_spark(player_pos, radius)
    local best_part = nil
    local best_dist = radius

    for i = 1, #spark_parts do
        local part = spark_parts[i]
        if env.is_valid(part) then
            local pos = part_position(part)
            if pos then
                local dx = pos.x - player_pos.x
                local dy = pos.y - player_pos.y
                local dz = pos.z - player_pos.z
                local dist = math_util.distance3(dx, dy, dz)
                if dist < best_dist then
                    best_dist = dist
                    best_part = part
                end
            end
        end
    end

    return best_part
end

local function silent_mode()
    return settings.bool(P_SILENT, true) and silent_ray.available()
end

local function stop_silent()
    if not M._tracking then return end
    silent_ray.stop()
    M._tracking = false
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Farm")
    menu_util.register_keybind(T, G.MISC, P, "Farm Helper", false)
    menu.add_checkbox(T, G.MISC, P_SILENT, "Silent Farm", false, root)
    menu_util.gap(T, G.MISC)
    menu.add_slider_int(T, G.MISC, P_RADIUS, "Farm Range (studs)", 1, 15, 5, root)
    menu.add_slider_int(T, G.MISC, P_SMOOTH, "Camera Smoothness", 1, 30, 8, root)
    menu_util.bind_children(P, { P_SILENT, P_RADIUS, P_SMOOTH })
end

function M.update(_dt)
    if not settings.enabled(P) then
        stop_silent()
        return
    end

    farm_tools.load()
    if not farm_tools.holding_farm_tool() then
        stop_silent()
        return
    end

    local lp = env.get_local_player()
    local pos = player_position(lp)
    if not pos then
        stop_silent()
        return
    end

    refresh_sparks()

    local radius = settings.num(P_RADIUS, 5)
    if radius <= 0 then
        stop_silent()
        return
    end

    local target = nearest_spark(pos, radius)
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
        local origin = viewmodel_origin()
        if not origin then
            stop_silent()
            return
        end

        if silent_ray.track(origin, aim, SHOOT_VK) then
            M._tracking = true
        else
            debug.error_once("farm:silent", "Silent farm hook unavailable — toggle Silent Farm off for camera aim")
            stop_silent()
        end
        return
    end

    stop_silent()

    if not camera or not camera.look_at then return end

    local smooth = math.max(1, settings.num(P_SMOOTH, 8))
    pcall(camera.look_at, aim.x, aim.y, aim.z, smooth)
end

return M
