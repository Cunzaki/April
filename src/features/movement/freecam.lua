local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local fly = April.require("core.cframe_move")
local packet_desync = April.require("core.packet_desync")
local desync_vis = April.require("core.desync_vis")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P = "april_freecam_enabled"

local was_active = false
local server_pos = nil
local desync_on = false

local function active()
    return settings.enabled(P)
end

local function get_character()
    local lp = env.get_local_player()
    if not lp then return lp, nil, nil, nil end
    local char = lp.character or (game and game.local_player and game.local_player.character)
    if not char or not env.is_valid(char) then return lp, nil, nil, nil end

    local hum = env.safe_call(function()
        if char.find_first_child_of_class then return char:find_first_child_of_class("Humanoid") end
        return char:FindFirstChildOfClass("Humanoid")
    end)
    local root = env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
    return lp, char, hum, root
end

local function set_root_anchored(root, anchored)
    if not root then return end
    if part and part.set_anchored then
        pcall(part.set_anchored, root, anchored)
    else
        pcall(function() root.Anchored = anchored end)
    end
end

local function enable_debug_cam(char, root, hum)
    local pos = fly.read_pos(root)
    if not pos then return false end

    server_pos = { x = pos.x, y = pos.y, z = pos.z }
    fly.apply_fly_humanoid(hum, 6)
    fly.zero_character(char)
    set_root_anchored(root, true)
    fly.set_position(root, pos.x, pos.y, pos.z)
    packet_desync.apply_movement_only()
    desync_on = true
    return true
end

local function disable_debug_cam(root, hum)
    if desync_on then
        packet_desync.release()
        desync_on = false
    end

    if server_pos and root and env.is_valid(root) then
        fly.set_position(root, server_pos.x, server_pos.y, server_pos.z)
    end

    set_root_anchored(root, false)
    fly.restore_humanoid(hum)
    server_pos = nil
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Debug Camera")
    menu.add_checkbox(T, G.MISC, P, "Debug Camera", false, { key = 0 })
    menu.add_slider_int(T, G.MISC, "april_freecam_speed", "Fly Speed", 16, 250, 120, root)
    menu.add_checkbox(T, G.MISC, "april_freecam_vis", "Visualizer", true, root)
    menu.add_combo(T, G.MISC, "april_freecam_vis_style", "Vis Style", { "Box", "Cross", "Ring" }, 0, root)
    menu.add_slider_float(T, G.MISC, "april_freecam_vis_size", "Vis Size", 0.5, 4, 1.2, root)

    menu_util.bind_master(P, {
        "april_freecam_speed",
        "april_freecam_vis", "april_freecam_vis_style", "april_freecam_vis_size",
    })

    menu_util.bind_when(function()
        return settings.enabled(P) and settings.enabled("april_freecam_vis")
    end, { "april_freecam_vis_style", "april_freecam_vis_size" }, { P, "april_freecam_vis" })
end

function M.update(_dt)
    if not misc_gate.movement_allowed() then return end
    local on = active()
    local _, char, hum, root = get_character()

    if was_active and not on then
        if root then
            disable_debug_cam(root, hum)
        elseif desync_on then
            packet_desync.release()
            desync_on = false
            server_pos = nil
        end
    end

    if on and not was_active then
        if char and root and hum then
            enable_debug_cam(char, root, hum)
        end
    end

    was_active = on
    if not on or not char or not root or not hum or not server_pos then return end

    fly.run_cframe_fly(root, hum, settings.num("april_freecam_speed", 120))
end

function M.draw()
    if not misc_gate.movement_allowed() then return end
    if not active() or not settings.enabled("april_freecam_vis") then return end
    if not server_pos then return end

    local _, _, _, root = get_character()
    local local_pos = root and fly.read_pos(root)
    if not local_pos then return end

    desync_vis.draw_server_local(server_pos, local_pos, {
        mode = settings.num("april_freecam_vis_style", 0),
        size = settings.num("april_freecam_vis_size", 1.2),
        col_server = settings.color("april_freecam_vis_server", { 0.2, 0.85, 1, 0.9 }),
        col_local = settings.color("april_freecam_vis_local", { 1, 0.35, 0.35, 0.9 }),
        col_link = { 1, 1, 1, 0.4 },
        link = true,
        labels = true,
        server_label = "SERVER",
        local_label = "LOCAL",
    })
end

return M
