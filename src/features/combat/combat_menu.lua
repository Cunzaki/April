local menu_util = April.require("core.menu_util")
local settings = April.require("core.settings")

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

-- april_silent_filters indices (1-based)
M.FILTER_HEALTH = 1
M.FILTER_VISIBLE = 2
M.FILTER_TEAM = 3
M.FILTER_SAFEZONE = 4
M.FILTER_WHITELIST = 5
M.FILTER_SKIP_DOWNED = 6

-- april_silent_targets
M.TARGET_PLAYERS = 1
M.TARGET_NPCS = 2
M.TARGET_NPC_SOLDIERS = 3
M.TARGET_NPC_BOSSES = 4

-- april_silent_options
M.OPT_STICKY = 1

function M.bone_from_index(idx)
    local label = M.SILENT_BONES[(idx or 0) + 1] or "Head"
    return M.BONE_MAP[label] or label
end

-- 0 = skip, 1 = allow, 2 = only (matches player_state.passes_downed_check)
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
    -- Fresh { parent = ... } per widget — sharing one opts table blanks multicombo lists.

    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0,
        { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Hitbox", M.SILENT_BONES, 0, { parent = parent_id })

    -- All toggle filters in one multicombo (API: menu.get → {bool,...})
    menu.add_multicombo(T, G, p .. "filters", "Aim Filters", {
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
        if wl and wl.clear then wl.clear() end
    end)

    menu.add_multicombo(T, G, p .. "targets", "Aim Targets", {
        "Players", "NPCs", "NPC Soldiers", "NPC Bosses",
    }, { false, false, false, false }, { parent = parent_id })
    if menu and menu.set then
        pcall(menu.set, p .. "targets", { true, false, true, true })
    end

    menu.add_multicombo(T, G, p .. "options", "Aim Options", {
        "Sticky Target",
    }, { false }, { parent = parent_id })

    local tp_root = menu_util.parent(p .. "bullet_tp")
    menu.add_checkbox(T, G, p .. "bullet_tp", "Bullet TP", false, { parent = parent_id })
    menu.add_checkbox(T, G, p .. "tp_ray_vis", "Visualize Ray Path", false, menu_util.parent(p .. "bullet_tp", {
        colorpicker = { 0.95, 0.45, 1, 0.9 },
    }))

    local manip_root = menu_util.parent(p .. "bullet_manip")
    menu.add_checkbox(T, G, p .. "bullet_manip", "Silent Bullet Manip", false, { parent = parent_id })
    menu.add_slider_float(T, G, p .. "manip_dist", "Manip Distance", 0.1, 1, 1, "%.2f", manip_root)
    menu.add_checkbox(T, G, p .. "manip_extend", "Extend", false, manip_root)
    menu.add_slider_float(T, G, p .. "manip_extend_dist", "Extra Scan Distance", 1, 8, 8, "%.1f",
        menu_util.parent(p .. "manip_extend"))
    menu.add_checkbox(T, G, p .. "manip_status", "Manip Status Bar", false, manip_root)
    menu.add_checkbox(T, G, p .. "manip_peek_vis", "Manip Peek Visual", true, manip_root)

    menu.add_checkbox(T, G, p .. "draw_fov", "FOV Circle", false,
        menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.55, 0.2, 1, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1,
        menu_util.parent(p .. "draw_fov"))
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false,
        menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.25, 0.25, 1 } }))

    menu.add_slider_int(T, G, p .. "hit_chance", "Hit Chance %", 1, 100, 100, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 20, 600, opts.fov_default or 150, { parent = parent_id })
end

return M
