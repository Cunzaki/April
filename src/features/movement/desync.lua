local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local fflag_mem = April.require("core.fflag_mem")
local desync_vis = April.require("core.desync_vis")
local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")
local misc_gate = April.require("core.misc_gate")

local M = {}

local P = "april_desync_enabled"
local P_VIS = "april_desync_visualizer"

local RANGE_RADIUS = 8

local LOOP_MS = 30
local last_tick = 0
local last_flag_apply = 0
local old_phys, old_send = nil, nil
local was_active = false
local anchor_pos = nil

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

local function dist_from_anchor(pos)
    if not anchor_pos or not pos then return 0 end
    local dx = pos.x - anchor_pos.x
    local dy = pos.y - anchor_pos.y
    local dz = pos.z - anchor_pos.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
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

local function disable_desync()
    if menu and menu.set then
        pcall(menu.set, P, false)
    end
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

local function draw_center_dot(wx, wy, wz, col)
    local sx, sy, vis = esp_util.w2s(wx, wy, wz)
    if vis then
        draw_util.circle(sx, sy, 5, col, true)
        draw_util.circle(sx, sy, 5, { 0, 0, 0, col[4] or 1 }, false)
    end
end

local function draw_visualizer()
    if not anchor_pos then return end

    local col = settings.color(P_VIS, { 0.2, 0.85, 1, 0.9 })
    local ring_col = { col[1], col[2], col[3], 0.55 }
    desync_vis.draw_sphere_ring(anchor_pos.x, anchor_pos.y, anchor_pos.z, RANGE_RADIUS, ring_col, 2)

    if settings.bool(P_VIS, false) then
        draw_center_dot(anchor_pos.x, anchor_pos.y, anchor_pos.z, col)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.gap(T, G.MISC)
    menu_util.register_keybind(T, G.MISC, P, "Desync", false)
    menu.add_checkbox(T, G.MISC, "april_desync_autosend", "Desync Auto Send", false, root)
    menu.add_slider_float(T, G.MISC, "april_desync_autosend_len", "Desync Send Threshold", 0, 1, 0.3,
        menu_util.parent("april_desync_autosend"))
    menu.add_checkbox(T, G.MISC, P_VIS, "Desync Visualize", false, menu_util.parent(P, {
        colorpicker = { 0.2, 0.85, 1, 0.9 },
    }))

    menu_util.bind_children(P, {
        "april_desync_autosend", "april_desync_autosend_len", P_VIS,
    })
    menu_util.bind_children("april_desync_autosend", { "april_desync_autosend_len" })
end

function M.update(_dt)
    if not misc_gate.movement_allowed() then return end
    local on = active()
    local t = now()

    if was_active and not on then
        restore_rates()
        anchor_pos = nil
    end

    if on and not was_active then
        pcall(fflag_mem.refresh)
        local root = get_root()
        anchor_pos = capture_pos(root)
    end

    was_active = on
    if not on then return end

    if (t - last_tick) * 1000 < LOOP_MS then return end
    last_tick = t

    local phys, send = compute_rates(t)
    local root = get_root()

    if root and anchor_pos then
        local pos = capture_pos(root)
        if pos and dist_from_anchor(pos) > RANGE_RADIUS then
            restore_rates()
            anchor_pos = nil
            was_active = false
            disable_desync()
            return
        end
    end

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
