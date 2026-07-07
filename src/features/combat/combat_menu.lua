--[[ Aimbot / silent aim menu helpers ]]

local menu_util = April.require("core.menu_util")
local esp_util = April.require("core.esp_util")

local M = {}

M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
}

M.BONE_MAP = {
    ["Head"] = "Head",
    ["Torso"] = "UpperTorso",
    ["Left Arm"] = "LeftUpperArm",
    ["Right Arm"] = "RightUpperArm",
    ["Left Leg"] = "LeftUpperLeg",
    ["Right Leg"] = "RightUpperLeg",
    ["Closest"] = "Closest",
}

function M.bone_from_index(idx)
    local label = M.SILENT_BONES[(idx or 0) + 1] or "Head"
    return M.BONE_MAP[label] or label
end

function M.register_targeting(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix
    local root = menu_util.parent(parent_id)

    menu.add_slider_int(T, G, p .. "fov", opts.fov_label or "FOV Radius (px)", 20, 600, opts.fov_default or 150, root)
    menu.add_combo(T, G, p .. "bone", "Target Bone", esp_util.AIM_BONES, 0, root)
    menu.add_combo(T, G, p .. "priority", "Priority", { "Distance", "Crosshair (FOV)" }, 1, root)
    menu.add_checkbox(T, G, p .. "sticky", "Sticky Target", false, root)
    menu.add_checkbox(T, G, p .. "visible", "Visibility Check", false, root)

    if opts.smooth then
        menu.add_slider_int(T, G, p .. "smooth", "Smoothing (frames)", 1, 100, 5, root)
    end

    menu.add_checkbox(T, G, p .. "draw_fov", "Draw FOV Circle", false, menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G, p .. "fov_fill", "Fill FOV", false, root)
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false, menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.2, 0.2, 1 } }))
end

function M.register_silent_aim(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix
    local root = menu_util.parent(parent_id)

    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0, root)
    menu.add_combo(T, G, p .. "bone", "Target Hitbox", M.SILENT_BONES, 0, root)

    menu_util.gap(T, G)
    menu_util.label(T, G, "Filters")
    menu.add_checkbox(T, G, p .. "filter_health", "Health Check", true, root)
    menu.add_checkbox(T, G, p .. "filter_visible", "Visible Only", false, root)
    menu.add_checkbox(T, G, p .. "filter_team", "Team Check", true, root)

    menu_util.gap(T, G)
    menu_util.label(T, G, "Targets")
    menu.add_checkbox(T, G, p .. "target_players", "Target Players", true, root)
    local npc_root = menu_util.parent(p .. "target_npcs")
    menu.add_checkbox(T, G, p .. "target_npcs", "Target NPCs", false, root)
    menu.add_checkbox(T, G, p .. "target_npc_soldiers", "NPC Soldiers", true, npc_root)
    menu.add_checkbox(T, G, p .. "target_npc_bosses", "NPC Bosses", true, npc_root)

    menu_util.gap(T, G)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, root)
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 20, 600, opts.fov_default or 150, root)
    menu.add_checkbox(T, G, p .. "sticky", "Sticky Target", false, root)
    menu.add_checkbox(T, G, p .. "wallbang", "Wallbang", false, root)
    menu_util.label(T, G, "Wallbang: likely invalid until target is visible to you (server checks).")
    local tp_root = menu_util.parent(p .. "bullet_tp")
    menu.add_checkbox(T, G, p .. "bullet_tp", "Bullet TP", false, root)
    menu_util.label(T, G, "Bullet TP: likely invalid until target is visible to you (server checks).")
    menu.add_combo(T, G, p .. "tp_ray_mode", "TP Ray Mode", { "Direct", "Snap", "Deep", "Curve", "Arch" }, 0, tp_root)
    menu.add_checkbox(T, G, p .. "tp_ray_vis", "Visualize Ray Path", false, menu_util.parent(p .. "bullet_tp", {
        colorpicker = { 0.95, 0.45, 1, 0.9 },
    }))
    menu.add_checkbox(T, G, p .. "bullet_manip", "Bullet Manipulation", false, root)
    menu.add_slider_float(T, G, p .. "manip_dist", "Manip Distance", 0.1, 1, 1, "%.2f", root)
    menu.add_checkbox(T, G, p .. "manip_status", "Manip Status Bar", false, root)
    menu.add_checkbox(T, G, p .. "manip_ring", "Manip Ring Visual", false, root)
    menu.add_checkbox(T, G, p .. "manip_peek_vis", "Manip Peek Visual", true, root)

    menu_util.gap(T, G)
    menu_util.label(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "Field Of View Circle", false, menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.55, 0.2, 1, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1, root)
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false, menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.25, 0.25, 1 } }))
end

return M
