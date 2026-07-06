--[[
    Shark — noclip underground blink + packet desync, return to origin, freeze.
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
local P_DEPTH = "april_shark_depth"
local P_VIS = "april_shark_visualize"
local RING_RADIUS = 2.5
local UNDER_HOLD_TICKS = 3

local PHASE_IDLE = 0
local PHASE_UNDER = 1
local PHASE_FROZEN = 2

local _installed = false
local was_active = false
local phase = PHASE_IDLE
local under_ticks = 0
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

local function blink_depth()
    return settings.num(P_DEPTH, 6)
end

local function underground_pos(pos)
    local depth = blink_depth()
    return {
        x = pos.x,
        y = pos.y - depth,
        z = pos.z,
    }
end

local function apply_desync()
    if desync_on then return end
    packet_desync.apply_movement_only()
    desync_on = true
end

local function release(char, root, hum)
    move.set_character_noclip(char, root, false)
    if hum then
        move.humanoid_running(hum)
        move.humanoid_thaw(hum)
    end
    if desync_on then
        packet_desync.release()
        desync_on = false
    end
    phase = PHASE_IDLE
    under_ticks = 0
    saved_pos = nil
    desync_pos = nil
end

local function begin_blink(root, char)
    local pos = move.read_pos(root)
    if not pos then return false end

    saved_pos = { x = pos.x, y = pos.y, z = pos.z }
    desync_pos = underground_pos(saved_pos)
    phase = PHASE_UNDER
    under_ticks = 0
    return true
end

local function tick_underground(root, char, hum)
    if not saved_pos or not desync_pos then return end

    move.set_character_noclip(char, root, true)
    move.humanoid_flying(hum)
    move.set_position(root, desync_pos.x, desync_pos.y, desync_pos.z)
    move.zero_character(char, root)
    apply_desync()

    under_ticks = under_ticks + 1
    if under_ticks < UNDER_HOLD_TICKS then return end

    move.set_position(root, saved_pos.x, saved_pos.y, saved_pos.z)
    move.zero_character(char, root)
    move.set_character_noclip(char, root, false)
    move.humanoid_freeze(hum)
    phase = PHASE_FROZEN
end

local function tick_frozen(root, char, hum)
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
        local char = lp and get_character(lp)
        local root = lp and get_root(lp)
        local hum = lp and get_humanoid(lp)
        release(char, root, hum)
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
        if not begin_blink(root, char) then return end
        was_active = true
    end

    if phase == PHASE_UNDER then
        tick_underground(root, char, hum)
    elseif phase == PHASE_FROZEN then
        tick_frozen(root, char, hum)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.MISC, P, "Shark", false)
    menu.add_slider_int(T, G.MISC, P_DEPTH, "Shark Underground Depth", 1, 15, 6, root)
    menu.add_checkbox(T, G.MISC, P_VIS, "Shark Desync Visualize", false, menu_util.parent(P, {
        colorpicker = { 0.2, 0.85, 1, 0.9 },
    }))
    menu_util.bind_children(P, { P_DEPTH, P_VIS })
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
