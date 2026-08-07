local menu_util = April.require("core.menu_util")
local settings = April.require("core.settings")
local combat_labels = April.require("ui.combat_labels")

local M = {}

M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
    "Randomized Part",
}

M.BONE_MAP = {
    ["Head"] = "Head",
    ["Torso"] = "UpperTorso",
    ["Left Arm"] = "LeftUpperArm",
    ["Right Arm"] = "RightUpperArm",
    ["Left Leg"] = "LeftUpperLeg",
    ["Right Leg"] = "RightUpperLeg",
    ["Closest"] = "Closest",
    ["Randomized Part"] = "Random",
}

-- Pool for Randomized Part (R15 part names).
M.RANDOM_BONE_POOL = {
    "Head",
    "UpperTorso",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftUpperLeg",
    "RightUpperLeg",
}

-- april_silent_filters indices (1-based)
M.FILTER_HEALTH = 1
M.FILTER_VISIBLE = 2
M.FILTER_TEAM = 3
M.FILTER_SAFEZONE = 4
M.FILTER_WHITELIST = 5
M.FILTER_SKIP_DOWNED = 6

-- april_silent_targets / april_aim_targets
-- 1 = Players, 2..9 = Soldier..Pilot Pete (see AIM_AT_OPTIONS).
M.TARGET_PLAYERS = 1
M.AIM_AT_OPTIONS = combat_labels.AIM_AT_OPTIONS
M.AIM_AT_DEFAULTS = combat_labels.AIM_AT_DEFAULTS

M.AIM_AT_KIND_INDEX = {
    soldier = 2,
    bruno = 3,
    boris = 4,
    brutus = 5,
    heli = 6,
    btr = 7,
    diver_dave = 8,
    pilot_pete = 9,
}

-- Legacy april_*_options multicombo slot (kept for old configs).
M.OPT_STICKY = 1

function M.bone_from_index(idx)
    local label = M.SILENT_BONES[(idx or 0) + 1] or "Head"
    return M.BONE_MAP[label] or label
end

-- Sticky Target checkbox (+ legacy Options multi slot 1).
function M.sticky_enabled(prefix)
    prefix = prefix or "april_silent_"
    if settings.bool(prefix .. "sticky", false) then
        return true
    end
    return settings.multi(prefix .. "options", M.OPT_STICKY, false)
end

local function migrate_sticky_checkbox(prefix)
    local sticky_id = prefix .. "sticky"
    if settings.get(sticky_id) ~= nil then
        return
    end
    if not settings.multi(prefix .. "options", M.OPT_STICKY, false) then
        return
    end
    if menu and menu.set then
        pcall(menu.set, sticky_id, true)
    end
    pcall(function()
        April.require("ui.gs_state").set(sticky_id, true)
    end)
end

function M.downed_mode_from_filters(prefix)
    local filters = (prefix or "april_silent_") .. "filters"
    if settings.multi(filters, M.FILTER_SKIP_DOWNED, true) then
        return 0
    end
    return 1
end

local function targets_table_len(t)
    if type(t) ~= "table" then return 0 end
    local max_i = 0
    for k in pairs(t) do
        local n = tonumber(k)
        if n and n > max_i then max_i = n end
    end
    return max_i
end

-- Old Aim At was { Players, NPCs }. Expand NPC=on into every NPC type slot.
function M.expand_legacy_targets(prefix)
    local id = (prefix or "april_silent_") .. "targets"
    local t = settings.get(id)
    if targets_table_len(t) > 2 then return end
    local players = settings.multi(id, 1, true)
    local npcs = settings.multi(id, 2, false)
    local expanded = { players }
    for i = 2, #M.AIM_AT_OPTIONS do
        expanded[i] = npcs
    end
    if menu and menu.set then
        pcall(menu.set, id, expanded)
    end
    pcall(function()
        April.require("ui.gs_state").set(id, expanded)
    end)
end

function M.players_enabled(prefix)
    M.expand_legacy_targets(prefix)
    return settings.multi((prefix or "april_silent_") .. "targets", M.TARGET_PLAYERS, true)
end

function M.npc_kind_enabled(kind, prefix)
    if not kind then return false end
    M.expand_legacy_targets(prefix)
    local idx = M.AIM_AT_KIND_INDEX[kind]
    if not idx then return false end
    return settings.multi((prefix or "april_silent_") .. "targets", idx, false)
end

function M.any_npc_enabled(prefix)
    M.expand_legacy_targets(prefix)
    for _, idx in pairs(M.AIM_AT_KIND_INDEX) do
        if settings.multi((prefix or "april_silent_") .. "targets", idx, false) then
            return true
        end
    end
    return false
end

function M.register_silent_aim(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix
    M.expand_legacy_targets(p)

    menu_util.section(T, G, "Targeting")
    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0,
        { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Hitbox", M.SILENT_BONES, 0, { parent = parent_id })
    menu.add_multicombo(T, G, p .. "targets", "Aim At", M.AIM_AT_OPTIONS, M.AIM_AT_DEFAULTS,
        { parent = parent_id })
    if menu and menu.set and targets_table_len(settings.get(p .. "targets")) <= 2 then
        pcall(menu.set, p .. "targets", {
            true, false, false, false, false, false, false, false, false,
        })
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
    menu.add_button(T, G, p .. "whitelist_clear", "Clear Whitelist", function()
        local wl = April.require("features.combat.silent_whitelist")
        if wl and wl.clear then wl.clear(p) end
    end)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = parent_id })

    menu_util.section(T, G, "Aim")
    migrate_sticky_checkbox(p)
    menu.add_checkbox(T, G, p .. "sticky", "Sticky Aim", false, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "hit_chance", "Hit Chance %", 1, 100, 100, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 5, 600, opts.fov_default or 150, { parent = parent_id })

    menu_util.section(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "FOV Circle", false,
        menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.55, 0.2, 1, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1,
        menu_util.parent(p .. "draw_fov"))
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false,
        menu_util.parent(parent_id, { colorpicker = opts.line_color or { 1, 0.25, 0.25, 1 } }))
end

-- Independent Bullet section (hitscan / TP / manip). Keys stay april_silent_* for config compat.
function M.register_bullet(T, G, prefix, parent_id)
    local p = prefix
    menu.add_checkbox(T, G, p .. "hitscan", "Hitscan", false, { parent = parent_id })

    menu.add_checkbox(T, G, p .. "bullet_tp", "Bullet TP", false, { parent = parent_id })

    local manip_root = menu_util.parent(p .. "bullet_manip")
    menu.add_checkbox(T, G, p .. "bullet_manip", "Silent Bullet Manip", false, { parent = parent_id })
    menu.add_slider_float(T, G, p .. "manip_dist", "Manip Distance", 0.1, 1, 1, "%.2f", manip_root)
    menu.add_checkbox(T, G, p .. "manip_extend", "Extend", false, manip_root)
    menu.add_slider_float(T, G, p .. "manip_extend_dist", "Extend Distance", 1, 7, 7, "%.1f",
        menu_util.parent(p .. "manip_extend"))
    menu.add_checkbox(T, G, "april_bullet_body_peek", "Body Peek (desync)", false, manip_root)

    menu.add_checkbox(T, G, "april_thick_bullet", "Hitbox Override", false, { parent = parent_id })
    menu.add_slider_float(T, G, "april_thick_bullet_mult", "Override Size", 1, 4, 2, "%.1f",
        menu_util.parent("april_thick_bullet"))

    local vis_root = menu_util.parent(parent_id)
    menu.add_checkbox(T, G, p .. "manip_status", "Status HUD", false, vis_root)
    menu.add_checkbox(T, G, p .. "manip_peek_vis", "Peek Visual", false, vis_root)
end

--- Camera aimbot: same targeting/filters as silent, without bullet TP/manip/hitscan.
function M.register_aimbot(T, G, prefix, parent_id, opts)
    opts = opts or {}
    local p = prefix
    M.expand_legacy_targets(p)

    menu_util.section(T, G, "Targeting")
    menu.add_combo(T, G, p .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0,
        { parent = parent_id })
    menu.add_combo(T, G, p .. "bone", "Hitbox", M.SILENT_BONES, 0, { parent = parent_id })
    menu.add_multicombo(T, G, p .. "targets", "Aim At", M.AIM_AT_OPTIONS, M.AIM_AT_DEFAULTS,
        { parent = parent_id })
    if menu and menu.set and targets_table_len(settings.get(p .. "targets")) <= 2 then
        pcall(menu.set, p .. "targets", {
            true, false, false, false, false, false, false, false, false,
        })
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
    menu.add_button(T, G, p .. "whitelist_clear", "Clear Whitelist", function()
        local wl = April.require("features.combat.silent_whitelist")
        if wl and wl.clear then wl.clear(p) end
    end)
    menu.add_slider_int(T, G, p .. "max_dist", "Max Distance (m)", 50, 2000, 500, { parent = parent_id })

    menu_util.section(T, G, "Aim")
    migrate_sticky_checkbox(p)
    menu.add_checkbox(T, G, p .. "sticky", "Sticky Aim", false, { parent = parent_id })
    menu.add_checkbox(T, G, p .. "auto_pred", "Auto Prediction", true, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "smooth", "Smoothness", 1, 25, 10, { parent = parent_id })
    menu.add_combo(T, G, p .. "smooth_type", "Smooth Type", {
        "Linear",
        "Ease Out",
        "Ease In-Out",
        "Exponential",
        "Adaptive",
    }, 0, { parent = parent_id })
    menu.add_checkbox(T, G, p .. "humanize", "Humanize", false, { parent = parent_id })
    menu.add_slider_int(T, G, p .. "humanize_str", "Humanize Strength", 1, 100, 35,
        menu_util.parent(p .. "humanize"))
    menu.add_slider_int(T, G, p .. "fov", "FOV Radius (px)", 5, 600, opts.fov_default or 120, { parent = parent_id })

    menu_util.section(T, G, "Visuals")
    menu.add_checkbox(T, G, p .. "draw_fov", "FOV Circle", false,
        menu_util.parent(parent_id, { colorpicker = opts.fov_color or { 0.2, 1, 0.45, 1 } }))
    menu.add_combo(T, G, p .. "fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1,
        menu_util.parent(p .. "draw_fov"))
    menu.add_checkbox(T, G, p .. "target_line", "Target Line", false,
        menu_util.parent(parent_id, { colorpicker = opts.line_color or { 0.2, 1, 0.45, 1 } }))
end

return M
