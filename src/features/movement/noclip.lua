--[[ Regular noclip — walk through walls, stay on the ground (raycast floor clamp). ]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P = "april_walk_noclip_enabled"
local P_SPEED = "april_walk_noclip_speed"

local HIP_OFFSET = 3.0
local RAY_UP = 6.0
local RAY_DOWN = 512.0

local _installed = false
local was_active = false

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

local function ground_y_at(x, y, z)
    if not raycast or not raycast.cast then return nil end
    if raycast.is_ready and not raycast.is_ready() then return nil end

    local start_y = y + RAY_UP
    local hit, hit_pos, dist = raycast.cast(x, start_y, z, x, start_y - RAY_DOWN, z)
    if not hit then return nil end

    if hit_pos then
        local hy = hit_pos.y or hit_pos.Y
        if hy then return hy + HIP_OFFSET end
    end
    if dist then
        return start_y - dist + HIP_OFFSET
    end
    return nil
end

local function read_walk_input()
    local lx, lz, rx, rz = move.camera_flat_axes()
    if not lx then return 0, 0 end

    local mx, mz = 0, 0
    if move.key_down(0x57) then mx, mz = mx + lx, mz + lz end
    if move.key_down(0x53) then mx, mz = mx - lx, mz - lz end
    if move.key_down(0x41) then mx, mz = mx - rx, mz - rz end
    if move.key_down(0x44) then mx, mz = mx + rx, mz + rz end

    local mag = math.sqrt(mx * mx + mz * mz)
    if mag < 0.001 then return 0, 0 end
    return mx / mag, mz / mag
end

local function enter(char, root, hum)
    move.set_character_noclip(char, root, true)
    move.humanoid_suspend(hum)
    pcall(function() hum.state = 8 end)
    move.zero_character(char, root)
end

local function leave(char, root, hum)
    move.set_character_noclip(char, root, false)
    move.humanoid_release(hum)
    move.humanoid_running(hum)
    move.zero_character(char, root)
end

local function tick_move(char, root, hum, speed)
    move.set_character_noclip(char, root, true)
    pcall(function() hum.state = 8 end)

    local pos = move.read_pos(root)
    if not pos then return end

    local mx, mz = read_walk_input()
    local step = speed * move.delta_time()
    local nx, nz = pos.x, pos.z

    if mx ~= 0 or mz ~= 0 then
        nx = pos.x + mx * step
        nz = pos.z + mz * step
    end

    local ny = ground_y_at(nx, pos.y, nz) or ground_y_at(pos.x, pos.y, pos.z) or pos.y
    if ny < pos.y - 0.25 then
        ny = ground_y_at(pos.x, pos.y, pos.z) or pos.y
    end

    move.set_position(root, nx, ny, nz)
    move.zero_character(char, root)
end

local function tick(_dt)
    if not misc_gate.movement_allowed() then return end

    local fling = April.require("features.movement.fling")
    if fling.is_active and fling.is_active() then return end

    local on = settings.enabled(P)
    local lp = env.get_local_player()

    if was_active and not on then
        local char = lp and get_character(lp)
        local root = lp and get_root(lp)
        local hum = lp and get_humanoid(lp)
        if char and root and hum then
            leave(char, root, hum)
        end
        was_active = false
        return
    end

    if not on then
        was_active = false
        return
    end

    if not lp then return end
    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not char or not root or not hum then return end

    if not was_active then
        enter(char, root, hum)
        was_active = true
    end

    tick_move(char, root, hum, settings.num(P_SPEED, 32))
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.MISC, P, "Noclip", false)
    menu.add_slider_int(T, G.MISC, P_SPEED, "Noclip Speed", 8, 80, 32, root)
    menu_util.bind_children(P, { P_SPEED })
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
