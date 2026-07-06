local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local movement_ctrl = April.require("core.movement_ctrl")
local desync_vis = April.require("core.desync_vis")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P = "april_freecam_enabled"

local function active()
    return settings.enabled(P)
end

local function get_root()
    local lp = env.get_local_player()
    if not lp then return nil end
    local char = lp.character or (game and game.local_player and game.local_player.character)
    if not char or not env.is_valid(char) then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.gap(T, G.MISC)
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

function M.update(_dt) end

function M.draw()
    if not misc_gate.movement_allowed() then return end
    if not active() or not settings.enabled("april_freecam_vis") then return end

    local server_pos = movement_ctrl.get_freecam_server_pos()
    if not server_pos then return end

    local root = get_root()
    local local_pos = root and move.read_pos(root)
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
