--[[
    Shark — blink desync underground, return to origin, freeze until disabled.
    No noclip: one-shot TP down 6 studs, packet desync, TP back, then position lock.
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local packet_desync = April.require("core.packet_desync")
local misc_gate = April.require("core.misc_gate")
local desync_vis = April.require("core.desync_vis")

local M = {}

local P = "april_shark_enabled"
local P_VIS = "april_shark_visualize"
local BLINK_DEPTH = 6
local RING_RADIUS = 2.5

local _installed = false
local was_active = false
local desync_on = false
local saved_pos = nil
local desync_pos = nil

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

local function release()
    if desync_on then
        packet_desync.release()
        desync_on = false
    end
    saved_pos = nil
    desync_pos = nil
end

local function blink_underground(root, char, pos)
    move.set_position(root, pos.x, pos.y - BLINK_DEPTH, pos.z)
    move.zero_character(char, root)

    if not desync_on then
        packet_desync.apply_movement_only()
        desync_on = true
    end

    move.set_position(root, pos.x, pos.y, pos.z)
    move.zero_character(char, root)
end

local function activate(root, char, hum)
    local pos = move.read_pos(root)
    if not pos then return false end

    saved_pos = { x = pos.x, y = pos.y, z = pos.z }
    desync_pos = { x = pos.x, y = pos.y - BLINK_DEPTH, z = pos.z }
    blink_underground(root, char, saved_pos)
    move.humanoid_freeze(hum)
    return true
end

local function maintain(root, char, hum)
    if not saved_pos then return end
    move.set_position(root, saved_pos.x, saved_pos.y, saved_pos.z)
    move.zero_character(char, root)
    move.humanoid_freeze(hum)
end

local function tick(_dt)
    if not misc_gate.movement_allowed() then return end

    local on = settings.enabled(P)
    local lp = env.get_local_player()

    if was_active and not on then
        local hum = lp and get_humanoid(lp)
        if hum then move.humanoid_thaw(hum) end
        release()
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
        if not activate(root, char, hum) then return end
        was_active = true
    end

    maintain(root, char, hum)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.MISC, P, "Shark", false)
    menu.add_checkbox(T, G.MISC, P_VIS, "Shark Desync Visualize", false, menu_util.parent(P, {
        colorpicker = { 0.2, 0.85, 1, 0.9 },
    }))
    menu_util.bind_children(P, { P_VIS })
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

function M.draw()
    if not settings.enabled(P) then return end
    if not settings.bool(P_VIS, false) then return end
    if not desync_pos then return end

    local col = settings.color(P_VIS, { 0.2, 0.85, 1, 0.9 })
    desync_vis.draw_sphere_ring(desync_pos.x, desync_pos.y, desync_pos.z, RING_RADIUS, col, 2)
end

return M
