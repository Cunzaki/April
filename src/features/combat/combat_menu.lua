local menu_util = April.require("core.menu_util")
local settings = April.require("core.settings")

local M = {}

M.TP_METHODS = {
    "Center",
    "Random Ring",
    "Random Sphere",
    "Offset Grid",
    "Camera Face",
    "Away From Cam",
    "Shuffle Valid",
    "Dense Shuffle",
}

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

-- april_silent_filters indices (1-based)
M.FILTER_HEALTH = 1
M.FILTER_VISIBLE = 2
M.FILTER_TEAM = 3
M.FILTER_SAFEZONE = 4
M.FILTER_WHITELIST = 5
M.FILTER_SKIP_DOWNED = 6

-- april_silent_targets / april_aim_targets (Players, NPCs)
M.TARGET_PLAYERS = 1
M.TARGET_NPCS = 2

-- april_silent_options / april_aim_options indices (1-based)
M.OPT_STICKY = 1

function M.bone_from_index(idx)
    local label = M.SILENT_BONES[(idx or 0) + 1] or "Head"
    return M.BONE_MAP[label] or label
end

function M.downed_mode_from_filters(prefix)
    local filters = (prefix or "april_silent_") .. "filters"
    if settings.multi(filters, M.FILTER_SKIP_DOWNED, true) then
        return 0
    end
    return 1
end

function M.register_silent_aim(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix

    menu_util.section(T, G, "Targeting")
    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0,
        { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Hitbox", M.SILENT_BONES, 0, { parent = parent_id })
    menu.add_multicombo(T, G, p .. "targets", "Aim At", {
        "Players", "NPCs",
    }, { false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "targets", { true, false })
    end
    menu.add_multicombo(T, G, p .. "filters", "Filters", {
        "Health Check",
        "Visible Only",
        "Team Check",
        "Skip Safezone",
        "Whitelist",
        "Skip Downed",
    }, { false, false, false, false, false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "filters", { true, false, true, true, false, true })
    end
    menu.add_input(T, G, p .. "whitelist_ids", "Whitelist IDs", "")
    if menu and menu.set_visible then
        pcall(menu.set_visible, p .. "whitelist_ids", false)
    end
    menu.add_button(T, G, p .. "whitelist_clear", "Clear Whitelist", function()
        local wl = April.require("features.combat.silent_whitelist")
        if wl and wl.clear then wl.clear(p) end
    end)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = parent_id })

    menu_util.section(T, G, "Aim")
    menu.add_multicombo(T, G, p .. "options", "Options", {
        "Sticky Target",
    }, { false }, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "hit_chance", "Hit Chance %", 1, 100, 100, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 20, 600, opts.fov_default or 150, { parent = parent_id })
    menu.add_checkbox(T, G, p .. "hitscan", "Hitscan", false, { parent = parent_id })

    menu_util.section(T, G, "Bullet TP")
    local tp_root = menu_util.parent(p .. "bullet_tp")
    menu.add_checkbox(T, G, p .. "bullet_tp", "Bullet TP", false, { parent = parent_id })
    menu.add_combo(T, G, p .. "tp_method", "TP Method", M.TP_METHODS, 0, tp_root)
    menu.add_checkbox(T, G, p .. "tp_ray_vis", "Visualize Ray Path", false, menu_util.parent(p .. "bullet_tp", {
        colorpicker = { 0.95, 0.45, 1, 0.9 },
    }))

    menu_util.section(T, G, "Bullet Manip")
    local manip_root = menu_util.parent(p .. "bullet_manip")
    menu.add_checkbox(T, G, p .. "bullet_manip", "Silent Bullet Manip", false, { parent = parent_id })
    menu.add_slider_float(T, G, p .. "manip_dist", "Manip Distance", 0.1, 1, 1, "%.2f", manip_root)
    menu.add_checkbox(T, G, p .. "manip_extend", "Extend", false, manip_root)
    menu.add_slider_float(T, G, p .. "manip_extend_dist", "Extra Scan Distance", 1, 7, 7, "%.1f",
        menu_util.parent(p .. "manip_extend"))
    menu.add_checkbox(T, G, p .. "manip_status", "Manip Status Bar", false, manip_root)
    menu.add_checkbox(T, G, p .. "manip_peek_vis", "Manip Peek Visual", false, manip_root)

    menu_util.section(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "FOV Circle", false,
        menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.55, 0.2, 1, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1,
        menu_util.parent(p .. "draw_fov"))
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false,
        menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.25, 0.25, 1 } }))
end

--- Camera aimbot: same targeting/filters as silent, without bullet TP/manip/hitscan.
function M.register_aimbot(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix

    menu_util.section(T, G, "Targeting")
    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0,
        { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Hitbox", M.SILENT_BONES, 0, { parent = parent_id })
    menu.add_multicombo(T, G, p .. "targets", "Aim At", {
        "Players", "NPCs",
    }, { false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "targets", { true, false })
    end
    menu.add_multicombo(T, G, p .. "filters", "Filters", {
        "Health Check",
        "Visible Only",
        "Team Check",
        "Skip Safezone",
        "Whitelist",
        "Skip Downed",
    }, { false, false, false, false, false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "filters", { true, false, true, true, false, true })
    end
    menu.add_input(T, G, p .. "whitelist_ids", "Whitelist IDs", "")
    if menu and menu.set_visible then
        pcall(menu.set_visible, p .. "whitelist_ids", false)
    end
    menu.add_button(T, G, p .. "whitelist_clear", "Clear Whitelist", function()
        local wl = April.require("features.combat.silent_whitelist")
        if wl and wl.clear then wl.clear(p) end
    end)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = parent_id })

    menu_util.section(T, G, "Aim")
    menu.add_multicombo(T, G, p .. "options", "Options", {
        "Sticky Target",
    }, { false }, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "smooth", "Smoothness", 1, 25, 10, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 20, 600, opts.fov_default or 120, { parent = parent_id })

    menu_util.section(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "FOV Circle", false,
        menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.2, 1, 0.45, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1,
        menu_util.parent(p .. "draw_fov"))
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false,
        menu_util.parent(parent_id, { colorpicker = opts.line_color or { 0.2, 1, 0.45, 1 } }))
end

return M
