local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local fflag_mem = April.require("core.fflag_mem")
local desync_vis = April.require("core.desync_vis")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P = "april_desync_enabled"
local VIS_MODES = { "Box", "Cross", "Ring" }

local LOOP_MS = 30
local last_tick = 0
local last_flag_apply = 0
local old_phys, old_send = nil, nil
local was_active = false
local was_sending = false
local visual_pos = nil

local function now()
    if utility and utility.get_time then return utility.get_time() end
    return os.clock()
end

local function get_root()
    local lp = env.get_local_player()
    if not lp then return nil end
    local char = lp.character or (game and game.local_player and game.local_player.character)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end

local function capture_pos(root)
    if not root then return nil end
    local pos = root.Position or root.position
    if not pos then return nil end
    return {
        x = pos.X or pos.x or 0,
        y = pos.Y or pos.y or 0,
        z = pos.Z or pos.z or 0,
    }
end

local function apply_rates(physics_rate, sender_rate)
    local phys = tonumber(physics_rate) or 0
    local send = tonumber(sender_rate) or 60
    local bw = phys == 0 and 0 or 38760

    fflag_mem.set_int("S2PhysicsSenderRate", phys)
    fflag_mem.set_int("PhysicsSenderMaxBandwidthBps", bw)
    fflag_mem.set_int("DataSenderRate", send)
end

local function restore_rates()
    fflag_mem.reset_defaults()
    old_phys, old_send = nil, nil
    last_flag_apply = 0
end

local function active()
    return settings.enabled(P)
end

local function compute_rates(t)
    local phys, send = 0, 60

    if settings.enabled("april_desync_autosend") then
        local window = settings.num("april_desync_autosend_len", 0.3)
        local cycle = window + 0.1
        if (t % cycle) > window then
            phys, send = 15, 60
        end
    end

    return phys, send
end

local function visual_color()
    if settings.enabled("april_desync_vis_custom_color") then
        return settings.color("april_desync_vis_color", { 0.2, 0.85, 1, 0.9 })
    end
    return settings.color("april_desync_visualizer", { 0.2, 0.85, 1, 0.9 })
end

local function update_visual_pos(root, sending_now)
    if not root or not settings.enabled("april_desync_visualizer") then return end

    local pos = capture_pos(root)
    if not pos then return end

    if not settings.enabled("april_desync_autosend") then
        visual_pos = visual_pos or pos
    elseif sending_now and not was_sending then
        visual_pos = pos
    elseif sending_now then
        visual_pos = pos
    elseif was_sending and not sending_now then
        visual_pos = visual_pos or pos
    end
end

local function draw_visualizer()
    if not settings.enabled("april_desync_visualizer") then return end
    if not visual_pos then return end

    local col = visual_color()
    local mode = settings.num("april_desync_vis_style", 0)
    local size = settings.num("april_desync_vis_size", 1.2)
    local x, y, z = visual_pos.x, visual_pos.y, visual_pos.z

    desync_vis.draw_mode(mode, x, y, z, size, col, 2)

    if settings.enabled("april_desync_vis_show_local") then
        local root = get_root()
        local pos = root and (root.Position or root.position)
        if pos then
            local lx = pos.X or pos.x or 0
            local ly = pos.Y or pos.y or 0
            local lz = pos.Z or pos.z or 0
            local lcol = settings.color("april_desync_vis_local_col", { 1, 0.35, 0.35, 0.9 })
            desync_vis.draw_mode(mode, lx, ly, lz, size * 0.85, lcol, 2)
            if settings.enabled("april_desync_vis_link") then
                desync_vis.draw_link(visual_pos, { x = lx, y = ly, z = lz }, { 1, 1, 1, 0.4 }, 2)
            end
            if settings.enabled("april_desync_vis_labels") then
                desync_vis.draw_labeled(lx, ly, lz, "LOCAL", lcol, 12)
            end
        end
    end

    if settings.enabled("april_desync_vis_labels") then
        desync_vis.draw_labeled(x, y, z, "SERVER", col, 12)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Desync")
    menu.add_checkbox(T, G.MISC, P, "Desync", false, { key = 0 })
    menu.add_checkbox(T, G.MISC, "april_desync_autosend", "Auto Send", false, root)
    menu.add_slider_float(T, G.MISC, "april_desync_autosend_len", "Send Threshold", 0, 1, 0.3, root)
    menu.add_checkbox(T, G.MISC, "april_desync_visualizer", "Visualizer", false, root)
    menu.add_combo(T, G.MISC, "april_desync_vis_style", "Vis Style", VIS_MODES, 0, root)
    menu.add_slider_float(T, G.MISC, "april_desync_vis_size", "Vis Size", 0.5, 4, 1.2, root)
    menu.add_checkbox(T, G.MISC, "april_desync_vis_show_local", "Show Local Position", true, root)
    menu.add_checkbox(T, G.MISC, "april_desync_vis_link", "Show Link Line", true, root)
    menu.add_checkbox(T, G.MISC, "april_desync_vis_labels", "Show Labels", false, root)
    menu.add_checkbox(T, G.MISC, "april_desync_vis_custom_color", "Custom Color", false, root)
    menu.add_checkbox(T, G.MISC, "april_desync_vis_color", "Visualizer Color", false, menu_util.parent(P, {
        parent = "april_desync_vis_custom_color",
        colorpicker = { 0.2, 0.85, 1, 0.9 },
    }))

    menu_util.bind_master(P, {
        "april_desync_autosend", "april_desync_autosend_len",
        "april_desync_visualizer", "april_desync_vis_style", "april_desync_vis_size",
        "april_desync_vis_show_local", "april_desync_vis_link", "april_desync_vis_labels",
        "april_desync_vis_custom_color", "april_desync_vis_color",
    })

    menu_util.bind_when(function()
        return settings.enabled(P) and settings.enabled("april_desync_autosend")
    end, { "april_desync_autosend_len" }, { P, "april_desync_autosend" })

    menu_util.bind_when(function()
        return settings.enabled(P) and settings.enabled("april_desync_visualizer")
    end, {
        "april_desync_vis_style", "april_desync_vis_size",
        "april_desync_vis_show_local", "april_desync_vis_link", "april_desync_vis_labels",
        "april_desync_vis_custom_color",
    }, { P, "april_desync_visualizer" })

    menu_util.bind_when(function()
        return settings.enabled(P)
            and settings.enabled("april_desync_visualizer")
            and settings.enabled("april_desync_vis_custom_color")
    end, { "april_desync_vis_color" }, { P, "april_desync_visualizer", "april_desync_vis_custom_color" })
end

function M.update(_dt)
    if not misc_gate.movement_allowed() then return end
    local on = active()
    local t = now()

    if was_active and not on then
        restore_rates()
        visual_pos = nil
        was_sending = false
    end

    if on and not was_active then
        pcall(fflag_mem.refresh)
        visual_pos = nil
    end

    was_active = on
    if not on then return end

    if (t - last_tick) * 1000 < LOOP_MS then return end
    last_tick = t

    local phys, send = compute_rates(t)
    local sending_now = phys ~= 0
    local root = get_root()

    update_visual_pos(root, sending_now)
    was_sending = sending_now

    if phys ~= old_phys or send ~= old_send or (t - last_flag_apply) > 0.35 then
        apply_rates(phys, send)
        old_phys, old_send = phys, send
        last_flag_apply = t
    end
end

function M.draw()
    if not misc_gate.movement_allowed() then return end
    if not active() then return end
    draw_visualizer()
end

return M
