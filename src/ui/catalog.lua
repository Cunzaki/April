--[[
  Layout catalog for the custom Gamesense UI.
  Values / callbacks come from feature register_menu() via ui.menu_shim.
  Nested options use `gate` so they only appear under their parent toggle.
]]

local maps = April.require("game.esp_maps")
local combat_menu = April.require("ui.combat_labels")
local gpu_chams = April.require("core.gpu_chams")

local M = {}

local function cb(id, label, default, color, gate)
    return { type = "checkbox", id = id, label = label, default = default == true, color = color, gate = gate }
end

local function kb(id, label, default, gate)
    return { type = "keybind", id = id, label = label, default = default == true, gate = gate }
end

local function sl(id, label, minv, maxv, default, float, gate, extra)
    local item = {
        type = "slider",
        id = id,
        label = label,
        min = minv,
        max = maxv,
        default = default,
        float = float == true,
        fmt = float and "%.2f" or "%d",
        gate = gate,
    }
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            item[k] = v
        end
    end
    return item
end

local function combo(id, label, options, default, gate, extra)
    local item = { type = "combo", id = id, label = label, options = options, default = default or 0, gate = gate }
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            item[k] = v
        end
    end
    return item
end

local function multi(id, label, options, defaults, gate, extra)
    local item = { type = "multi", id = id, label = label, options = options, defaults = defaults, gate = gate }
    if type(extra) == "table" then
        for k, v in pairs(extra) do item[k] = v end
    end
    return item
end

local function btn(id, label, gate)
    return { type = "button", id = id, label = label, gate = gate }
end

local function sep(gate)
    return { type = "separator", gate = gate }
end

local function label(text, dim, gate)
    return { type = "label", label = text, dim = dim, gate = gate }
end

local function color(id, label_text, default, gate, override_idx)
    return {
        type = "color",
        id = id,
        label = label_text,
        default = default,
        gate = gate,
        color_override_idx = override_idx,
    }
end

local function input(id, label_text, default, gate)
    return { type = "input", id = id, label = label_text, default = default or "", gate = gate }
end

local function ak(key_id, label, gate)
    return { type = "aim_key", id = key_id, mode_id = key_id .. "_mode", label = label, gate = gate }
end

local function hk(id, label, gate, default_vk)
    return { type = "hotkey", id = id, label = label, gate = gate, default = default_vk or 0x2D }
end

local function from_toggles(list, gate)
    local out = {}
    for _, t in ipairs(list) do
        out[#out + 1] = cb(t.id, t.label, false, t.color, gate)
        if t.ring_id then
            out[#out + 1] = cb(t.ring_id, t.label .. " Range Ring", false, nil, gate)
        end
    end
    return out
end

local function append(dst, src)
    for _, v in ipairs(src) do
        dst[#dst + 1] = v
    end
end

local function toggle_labels(list)
    local labels = {}
    for i, t in ipairs(list) do
        labels[i] = t.label
    end
    return labels
end

-- GPU mesh chams block (see docs/API.md §15 — preset mode + glow color indices).
local function mesh_chams_block(prefix, toggle_list, master)
    local chams_id = prefix .. "_chams"
    local mode_id = prefix .. "_chams_mode"
    local color_id = prefix .. "_chams_color"
    return {
        sep(master),
        label("Mesh Chams (GPU)", false, master),
        multi(chams_id, "Cham Types", toggle_labels(toggle_list), {}, master),
        combo(mode_id, "Chams Mode", gpu_chams.MODE_LABELS, 0, master),
        combo(color_id, "Glow Preset", gpu_chams.COLOR_LABELS, 0, master, {
            gate_any_combo = {
                { mode_id, { 2, 3 } },
            },
        }),
    }
end

M.TABS = {
    { id = "aim", icon = "aim", title = "Aimbot" },
    { id = "visuals", icon = "visuals", title = "Visuals" },
    { id = "world", icon = "world", title = "World" },
    { id = "guns", icon = "guns", title = "Gun Mods" },
    { id = "misc", icon = "misc", title = "Misc" },
    { id = "radar", icon = "radar", title = "Radar" },
    { id = "config", icon = "config", title = "Config" },
}

local function build_aim()
    local regular = {
        title = "Aimbot",
        master = "april_aimbot",
        items = {
            cb("april_aimbot", "Enable Aimbot", false),
            ak("april_aim_key", "Aim Key"),
            sep(),
            combo("april_aim_target_type", "Target Type", { "Crosshair", "Distance" }, 0),
            combo("april_aim_bone", "Hitbox", combat_menu.SILENT_BONES, 0),
            multi("april_aim_targets", "Aim At", { "Players", "NPCs" }, { true, false }),
            multi("april_aim_filters", "Filters", {
                "Health Check", "Visible Only", "Team Check",
                "Skip Safezone", "Whitelist", "Skip Downed",
            }, { true, false, true, true, false, true }),
            input("april_aim_whitelist_ids", "Whitelist IDs", ""),
            btn("april_aim_whitelist_clear", "Clear Whitelist"),
            sl("april_aim_max_dist", "Max Distance (m)", 50, 2000, 500),
            sep(),
            multi("april_aim_options", "Options", { "Sticky Target" }, { false }),
            sl("april_aim_smooth", "Smoothness", 1, 25, 10),
            sl("april_aim_fov", "FOV Radius (px)", 20, 600, 120),
            sep(),
            cb("april_aim_draw_fov", "FOV Circle", false, { 0.2, 1, 0.45, 1 }),
            combo("april_aim_fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1, "april_aim_draw_fov"),
            cb("april_aim_target_line", "Target Line", false, { 0.2, 1, 0.45, 1 }),
        },
    }

    local rage = {
        title = "Ragebot",
        master = "april_rage_enabled",
        items = {
            kb("april_rage_enabled", "Enable Ragebot", false),
            sep(),
            combo("april_rage_target_type", "Target Type", { "Crosshair", "Distance" }, 1),
            combo("april_rage_bone", "Hitbox", combat_menu.SILENT_BONES, 0),
            multi("april_rage_targets", "Aim At", { "Players", "NPCs" }, { true, false }),
            multi("april_rage_filters", "Filters", {
                "Health Check", "Visible Only", "Team Check",
                "Skip Safezone", "Whitelist", "Skip Downed",
            }, { true, false, true, true, false, true }),
            input("april_rage_whitelist_ids", "Whitelist IDs", ""),
            btn("april_rage_whitelist_clear", "Clear Whitelist"),
            sl("april_rage_max_dist", "Max Distance (m)", 50, 2000, 500),
            sep(),
            multi("april_rage_options", "Options", { "Sticky Target" }, { false }),
            cb("april_rage_autofire", "Autofire", true),
            sl("april_rage_fire_delay", "Fire Delay (ms)", 20, 400, 80),
        },
    }

    local silent = {
        title = "Silent Aim",
        master = "april_silent_aim",
        items = {
            kb("april_silent_aim", "Enable Silent Aim", false),
            sep(),
            combo("april_silent_target_type", "Target Type", { "Crosshair", "Distance" }, 0),
            combo("april_silent_bone", "Hitbox", combat_menu.SILENT_BONES, 0),
            multi("april_silent_targets", "Aim At", { "Players", "NPCs" }, { true, false }),
            multi("april_silent_filters", "Filters", {
                "Health Check", "Visible Only", "Team Check",
                "Skip Safezone", "Whitelist", "Skip Downed",
            }, { true, false, true, true, false, true }),
            input("april_silent_whitelist_ids", "Whitelist IDs", ""),
            btn("april_silent_whitelist_clear", "Clear Whitelist"),
            sl("april_silent_max_dist", "Max Distance (m)", 50, 2000, 500),
            sep(),
            multi("april_silent_options", "Options", { "Sticky Target" }, { false }),
            sl("april_silent_hit_chance", "Hit Chance %", 1, 100, 100),
            sl("april_silent_fov", "FOV Radius (px)", 20, 600, 150),
            sep(),
            cb("april_silent_draw_fov", "FOV Circle", false, { 0.55, 0.2, 1, 1 }),
            combo("april_silent_fov_style", "FOV Style", { "Outline", "Filled Circle" }, 1, "april_silent_draw_fov"),
            cb("april_silent_target_line", "Snapline", false, { 1, 0.25, 0.25, 1 }),
        },
    }

    local bullet = {
        title = "Bullet",
        master = "april_bullet_enabled",
        items = {
            cb("april_bullet_enabled", "Enable Bullet", false),
            sep(),
            cb("april_silent_hitscan", "Hitscan", false),
            sep(),
            cb("april_silent_bullet_tp", "Bullet TP", false),
            sep("april_silent_bullet_tp"),
            cb("april_silent_bullet_manip", "Silent Bullet Manip", false),
            sl("april_silent_manip_dist", "Manip Distance", 0.1, 1, 1, true, "april_silent_bullet_manip"),
            cb("april_silent_manip_extend", "Extend", false, nil, "april_silent_bullet_manip"),
            sl("april_silent_manip_extend_dist", "Extend Distance", 1, 7, 7, true, "april_silent_manip_extend"),
            cb("april_bullet_body_peek", "Body Peek (desync)", false, nil, "april_silent_bullet_manip"),
            sep("april_bullet_enabled"),
            cb("april_silent_manip_status", "Status HUD", false, nil, "april_bullet_enabled"),
            cb("april_silent_manip_peek_vis", "Peek Visual", false, nil, "april_bullet_enabled"),
        },
    }

    return { regular, rage, silent, bullet }
end

local function build_visuals()
    local left = {
        title = "Player ESP",
        master = "april_player_enabled",
        items = {
            kb("april_player_enabled", "Player ESP", false),
            combo("april_player_box_mode", "Player Box", { "None", "2D", "Corner" }, 1),
            multi("april_ui_player_elements", "Displayed Elements", {
                "Health Bar", "Skeleton", "Name", "Clan Tag", "Distance", "Weapon",
            }, { true, false, true, true, true, false }, nil, {
                sync_ids = {
                    "april_player_health", "april_player_skeleton", "april_player_show_name",
                    "april_player_clan_tag", "april_player_show_distance", "april_player_show_weapon",
                },
            }),
            multi("april_player_esp_filters", "ESP Filters", {
                "Team Check", "Skip Safezone", "Skip Downed",
            }, { true, false, false }),
            multi("april_player_esp_flags", "ESP Flags", {
                "Downed", "Safezone", "Staff", "Reviving",
            }, { true, true, true, true }),
            sl("april_player_range", "Player Range", 50, 2000, 500),
        },
    }

    local gear = {
        title = "Target Gear",
        master = "april_target_overlay",
        items = {
            kb("april_target_overlay", "Target Gear Overlay", false),
            combo("april_target_gear_source", "Target From", { "Auto", "Ragebot", "Silent Aim", "Aimbot" }, 0, "april_target_overlay"),
            sl("april_target_overlay_gear_size", "Gear Icon Size", 32, 64, 48, false, "april_target_overlay"),
            sl("april_target_overlay_top", "Top Offset", 48, 160, 88, false, "april_target_overlay"),
        },
    }

    local target_vis = {
        title = "Crosshair",
        items = {
            cb("april_crosshair_enabled", "Custom Crosshair", false),
            combo("april_crosshair_type", "Style", {
                "Cross", "Circle", "Dot", "T-Shape", "Diamond", "Plus", "Brackets", "X",
            }, 0, "april_crosshair_enabled"),
            cb("april_crosshair_follow", "Follow Target", false, nil, "april_crosshair_enabled"),
            combo("april_crosshair_source", "Target From", { "Auto", "Ragebot", "Silent Aim", "Aimbot" }, 0, "april_crosshair_follow"),
            sl("april_crosshair_follow_smooth", "Follow Smoothness", 4, 40, 18, false, "april_crosshair_follow"),
            multi("april_ui_crosshair_motion", "Motion", { "Spin", "Pulse Size" }, { false, false }, "april_crosshair_enabled", {
                sync_ids = { "april_crosshair_spin", "april_crosshair_pulse" },
            }),
            sl("april_crosshair_spin_speed", "Spin Speed", 1, 100, 35, false, "april_crosshair_spin"),
            sl("april_crosshair_pulse_speed", "Pulse Speed", 1, 100, 40, false, "april_crosshair_pulse"),
            multi("april_ui_crosshair_options", "Options", {
                "Center Dot", "Outline", "Rainbow",
            }, { false, true, false }, "april_crosshair_enabled", {
                sync_ids = {
                    "april_crosshair_dot", "april_crosshair_outline", "april_crosshair_rainbow",
                },
            }),
            color("april_crosshair_color", "Crosshair Color", { 0, 1, 0, 1 }, "april_crosshair_enabled"),
            color("april_crosshair_dot", "Center Dot Color", { 1, 1, 1, 1 }, "april_crosshair_dot"),
            sl("april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10, false, "april_crosshair_rainbow"),
            sl("april_crosshair_size", "Size", 1, 50, 10, false, "april_crosshair_enabled"),
            sl("april_crosshair_gap", "Gap", 0, 20, 5, false, "april_crosshair_enabled"),
            sl("april_crosshair_thickness", "Thickness", 1, 10, 2, false, "april_crosshair_enabled"),
        },
    }

    local colors = {
        title = "Player Colors",
        master = "april_player_enabled",
        items = {
            color("april_player_skeleton", "Skeleton", { 1, 1, 1, 0.92 }),
            color("april_player_show_name", "Name", { 1, 0.35, 0.35, 1 }),
            color("april_player_clan_tag", "Clan Tag", { 0.84, 0.31, 0.80, 1 }),
            color("april_player_show_distance", "Distance", { 0.82, 0.84, 0.88, 0.92 }),
            color("april_player_show_weapon", "Weapon", { 0.82, 0.84, 0.88, 0.92 }),
            sep(),
            color("april_player_flag_downed", "Downed", { 1, 0.35, 0.35, 1 }),
            color("april_player_flag_safezone", "Safezone", { 0.35, 0.85, 1, 1 }),
            color("april_player_flag_staff", "Staff", { 1, 0.33, 0.33, 1 }),
            color("april_player_flag_reviving", "Reviving", { 0.45, 1, 0.55, 1 }),
        },
    }
    return { left, gear, target_vis, colors }
end

local function build_world()
    local resources = {
        title = "Resources",
        master = "april_world_enabled",
        items = {
            kb("april_world_enabled", "Resource ESP", false),
        },
    }
    append(resources.items, from_toggles(maps.WORLD_TOGGLES))
    append(resources.items, {
        cb("april_world_boxes", "Resource 3D Boxes", false),
        cb("april_world_show_name", "Resource Show Name", true),
        cb("april_world_show_distance", "Resource Show Distance", true),
        sl("april_world_range", "Resource Range", 50, 2000, 500),
    })
    append(resources.items, mesh_chams_block("april_world", maps.WORLD_TOGGLES, "april_world_enabled"))

    local loot = {
        title = "Loot",
        master = "april_loot_enabled",
        items = {
            kb("april_loot_enabled", "Loot ESP", false),
        },
    }
    append(loot.items, from_toggles(maps.LOOT_TOGGLES))
    append(loot.items, {
        cb("april_loot_boxes", "Loot 3D Boxes", false),
        cb("april_loot_show_name", "Loot Show Name", true),
        cb("april_loot_show_distance", "Loot Show Distance", true),
        sl("april_loot_range", "Loot Range", 50, 2000, 300),
    })
    append(loot.items, mesh_chams_block("april_loot", maps.LOOT_TOGGLES, "april_loot_enabled"))

    local bases = {
        title = "Bases",
        master = "april_base_enabled",
        items = {
            kb("april_base_enabled", "Base ESP", false),
        },
    }
    append(bases.items, from_toggles(maps.BASE_TOGGLES))
    append(bases.items, {
        cb("april_base_boxes", "Base 3D Boxes", false),
        cb("april_base_show_name", "Base Show Name", true),
        cb("april_base_show_distance", "Base Show Distance", false),
        sl("april_base_range", "Base Range", 50, 500, 150),
    })
    append(bases.items, mesh_chams_block("april_base", maps.BASE_TOGGLES, "april_base_enabled"))

    local npcs = {
        title = "NPCs",
        master = "april_npc_enabled",
        items = {
            kb("april_npc_enabled", "NPC ESP", false),
            multi("april_ui_npc_types", "NPC Types", { "Soldiers", "Bosses" }, { false, false }, nil, {
                sync_ids = { "april_npc_soldiers", "april_npc_bosses" },
            }),
            combo("april_npc_box_mode", "NPC Box", { "None", "2D", "Corner" }, 1),
            multi("april_ui_npc_elements", "Displayed Elements", {
                "Health Bar", "Skeleton", "Name", "Distance", "Weapon",
            }, { true, false, true, true, false }, nil, {
                sync_ids = {
                    "april_npc_health", "april_npc_skeleton", "april_npc_show_name",
                    "april_npc_show_distance", "april_npc_show_weapon",
                },
            }),
            color("april_npc_soldiers", "Soldier Color", { 1, 0.3, 0.3, 1 }),
            color("april_npc_bosses", "Boss Color", { 1, 0.5, 0.1, 1 }),
            color("april_npc_skeleton", "Skeleton Color", { 1, 1, 1, 0.85 }),
            color("april_npc_show_name", "Name Color", { 1, 0.3, 0.3, 1 }),
            color("april_npc_show_distance", "Distance Color", { 0.82, 0.84, 0.88, 0.92 }),
            color("april_npc_show_weapon", "Weapon Color", { 0.82, 0.84, 0.88, 0.92 }),
            sl("april_npc_range", "NPC Range", 50, 2000, 500),
        },
    }

    return { resources, loot, npcs, bases }
end

local function build_guns()
    return {
        {
            title = "Gun Mods",
            master = "april_gunmods_enabled",
            items = {
                kb("april_gunmods_enabled", "Enable Gun Mods", false),
                sep(),
                cb("april_gm_recoil", "No Recoil", false),
                sl("april_gm_recoil_pct", "Recoil Reduction %", 0, 100, 100, false, "april_gm_recoil"),
                sep(),
                cb("april_gm_spread", "No Spread", false),
                sl("april_gm_spread_pct", "Spread Reduction %", 0, 100, 100, false, "april_gm_spread"),
                sep(),
                cb("april_gm_sway", "No Sway", false),
                sep(),
                cb("april_gm_fire_rate", "Fire Rate", false),
                sl("april_gm_fire_rate_mult", "Fire Rate Multiplier", 1, 3, 1.5, true, "april_gm_fire_rate"),
                sep(),
                cb("april_gm_speed", "Bullet Speed", false),
                sl("april_gm_speed_mult", "Speed Mult", 1, 100, 100, false, "april_gm_speed"),
                sep(),
                cb("april_gm_range", "Gun Range", false),
                sl("april_gm_range_mult", "Range Mult", 1, 20, 10, false, "april_gm_range"),
                sep(),
                cb("april_gm_double_tap", "Double Tap", false),
            },
        },
    }
end

local function build_misc()
    return {
        {
            title = "Movement",
            items = {
                kb("april_noclip_enabled", "Fly", false),
                sl("april_noclip_speed", "Fly Speed", 1, 20, 5, false, "april_noclip_enabled"),
                kb("april_slowfall_enabled", "Slowfall", false),
                sl("april_slowfall_speed", "Fall Speed", 1, 50, 5, false, "april_slowfall_enabled"),
                sep(),
                kb("april_desync_enabled", "Desync", false),
                cb("april_desync_visualizer", "Desync Visualize", false, { 0.2, 0.85, 1, 0.9 }, "april_desync_enabled"),
                sep(),
                kb("april_antiaim_enabled", "Anti-Aim", false),
                combo("april_antiaim_yaw_mode", "Yaw Mode", { "None", "Backwards", "Spin", "Jitter", "Random Jitter", "Sideways Left", "Sideways Right", "Manual" }, 1, "april_antiaim_enabled"),
                sl("april_antiaim_yaw_manual", "Manual Yaw", -180, 180, 90, false, "april_antiaim_enabled", {
                    gate_combo = "april_antiaim_yaw_mode",
                    gate_combo_value = 7,
                }),
                sl("april_antiaim_spin_speed", "Spin Speed", 30, 720, 180, false, "april_antiaim_enabled", {
                    gate_combo = "april_antiaim_yaw_mode",
                    gate_combo_value = 2,
                }),
                sl("april_antiaim_jitter_step", "Jitter Step", 15, 180, 90, false, "april_antiaim_enabled", {
                    gate_any_combo = {
                        { "april_antiaim_yaw_mode", { 3, 4 } },
                    },
                }),
                sl("april_antiaim_jitter_ms", "Jitter Interval (ms)", 40, 500, 120, false, "april_antiaim_enabled", {
                    gate_any_combo = {
                        { "april_antiaim_yaw_mode", { 3, 4 } },
                    },
                }),
                kb("april_fakeduck_enabled", "Fake Duck", false),
                sl("april_fakeduck_height", "Duck Height", 0.01, 1.5, 1.1, true, "april_fakeduck_enabled"),
                cb("april_fakeduck_spam", "Spam Height", false, nil, "april_fakeduck_enabled"),
                combo("april_fakeduck_spam_mode", "Spam Mode", { "Alternating", "Random" }, 0, "april_fakeduck_spam"),
                sl("april_fakeduck_spam_min", "Spam Min", 0.01, 1.5, 0.01, true, "april_fakeduck_spam"),
                sl("april_fakeduck_spam_max", "Spam Max", 0.01, 1.5, 1.5, true, "april_fakeduck_spam"),
                sl("april_fakeduck_spam_ms", "Spam Interval (ms)", 20, 400, 80, false, "april_fakeduck_spam"),
                sep(),
                kb("april_fling_enabled", "Fling", false),
                sl("april_fling_fov", "Fling FOV", 20, 600, 150, false, "april_fling_enabled"),
                sl("april_fling_duration", "Fling Duration", 2, 10, 2, false, "april_fling_enabled"),
            },
        },
        {
            title = "Utility",
            items = {
                kb("april_farm_helper", "Farm Helper", false),
                cb("april_farm_silent", "Silent Farm", false, nil, "april_farm_helper"),
                sl("april_farm_radius", "Farm Range (studs)", 1, 10, 7, false, "april_farm_helper"),
                sl("april_farm_smooth", "Camera Smoothness", 1, 30, 8, false, "april_farm_helper"),
                sep(),
                cb("april_anti_afk", "Anti AFK", false),
                cb("april_mod_checker_enabled", "Mod Checker", false),
                sl("april_mod_checker_interval", "Scan Interval (ms)", 1000, 10000, 2500, false, "april_mod_checker_enabled"),
                sep(),
                cb("april_keybinds_enabled", "Keybind Viewer", false),
                cb("april_keybinds_active_only", "Only Show Active", false, nil, "april_keybinds_enabled"),
                cb("april_keybinds_show_unbound", "Show Unbound", true, nil, "april_keybinds_enabled"),
                cb("april_keybinds_show_mode", "Show Bind Mode", true, nil, "april_keybinds_enabled"),
            },
        },
    }
end

local function build_radar()
    return {
        {
            title = "Tactical Map",
            master = "april_map_enabled",
            items = {
                kb("april_map_enabled", "Tactical Map", false),
                multi("april_ui_radar_layers", "Visible Layers", {
                    "Players", "NPCs", "Loot", "Resources", "Base Parts", "Waypoints", "Labels",
                }, { true, false, true, true, false, true, false }, nil, {
                    sync_ids = {
                        "april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
                        "april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
                        "april_map_labels",
                    },
                }),
                color("april_map_player_col", "Radar Players Color", { 1, 0.25, 0.25, 1 }),
                color("april_map_npc_col", "Radar NPCs Color", { 1, 0.55, 0.15, 1 }),
                color("april_map_loot_col", "Radar Loot Color", { 1, 0.85, 0.35, 1 }),
                color("april_map_world_col", "Radar Resources Color", { 0.35, 0.9, 0.35, 1 }),
                color("april_map_base_col", "Radar Base Color", { 0.55, 0.55, 1, 1 }),
                color("april_map_wp_col", "Radar Waypoints Color", { 0.3, 0.9, 1, 1 }),
                sl("april_map_zoom", "Radar Zoom Level", 0.05, 5, 1, true),
                sl("april_map_size", "Radar Size", 140, 420, 240),
                sl("april_map_icon_scale", "Radar Blip Size", 2, 6, 3),
                btn("april_map_reset_position", "Reset Radar Position"),
            },
        },
        {
            title = "Waypoints",
            master = "april_waypoints_enabled",
            items = {
                kb("april_waypoints_enabled", "Waypoints", false),
                cb("april_wp_dist", "Waypoint Show Distance", false),
                cb("april_wp_beacon", "Beacon Pillar", false),
                sl("april_wp_beacon_h", "Beacon Height", 20, 200, 90, false, "april_wp_beacon"),
                cb("april_wp_draw", "Draw Markers", false, { 0.2, 1, 0.8, 1 }),
                sl("april_wp_slot", "Waypoint Active Slot", 1, 5, 1),
                btn("april_wp_set", "Set Active Waypoint"),
                btn("april_wp_clear", "Clear Active Waypoint"),
                btn("april_wp_clear_all", "Clear All Waypoints"),
            },
        },
    }
end

local function build_config()
    local modes = { "Static", "Rainbow", "Pulse", "Wave", "Flow" }
    local elem_modes = { "Default", "Static", "Rainbow", "Pulse", "Wave", "Flow" }
    local COL = "april_ui_custom_colors"
    local ANM = "april_ui_custom_anim"
    local ELS = "april_ui_per_element"

    local appearance = {
        title = "Appearance",
        items = {
            hk("april_ui_menu_key", "Menu Toggle Key"),
            sep(),
            combo("april_ui_theme_preset", "Theme Preset", {
                "Violet Glass", "Midnight Blue", "Graphite", "Emerald Glass",
            }, 0),
            sl("april_ui_window_opacity", "Window Opacity %", 45, 100, 86),
            sl("april_ui_panel_opacity", "Panel Opacity %", 35, 100, 72),
            sl("april_ui_border_strength", "Border Strength %", 10, 100, 58),
            combo("april_ui_corner_style", "Control Corners", { "Sharp", "Soft", "Rounded" }, 2),
            sl("april_ui_scale", "UI Scale %", 80, 125, 100),
            combo("april_ui_density", "Density", { "Compact", "Balanced", "Comfortable" }, 1),
            sl("april_ui_bg_dim", "Backdrop Dim", 0, 40, 0),
            cb("april_ui_show_cursor_dot", "Show Cursor Dot", true),
        },
    }

    local motion = {
        title = "Motion",
        items = {
            combo("april_ui_motion_profile", "Motion Profile", {
                "Subtle", "Balanced", "Expressive",
            }, 1),
            cb("april_ui_reduce_motion", "Reduce Motion", false),
            cb("april_ui_custom_anim", "Advanced Animation", false),
            combo("april_ui_accent_anim", "Accent Style", modes, 1, ANM),
            sl("april_ui_anim_speed", "Accent Speed", 1, 100, 40, false, ANM),
            cb("april_ui_menu_fade", "Ambient Fade Pulse", false, nil, ANM),
            multi("april_ui_anim_targets", "Animate", {
                "Title Bar", "Section Tops", "Sliders", "Scrollbars", "Sidebar", "Checkboxes", "Hover", "Overlay Panels",
            }, { true, true, true, true, true, true, true, true }, ANM),
            cb("april_ui_per_element", "Individual Styles", false, nil, ANM),
            sep(ANM),
            { type = "combo", id = "april_ui_style_title", label = "Title Bar", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_section", label = "Section Tops", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_slider", label = "Sliders", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_scroll", label = "Scrollbars", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_sidebar", label = "Sidebar", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_checkbox", label = "Checkboxes", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
            { type = "combo", id = "april_ui_style_overlay", label = "Overlay Panels", options = elem_modes, default = 0, gate = ANM, gate2 = ELS },
        },
    }

    local accent = {
        title = "Accent Colors",
        items = {
            cb("april_ui_custom_colors", "Color Options", false),
            color("april_ui_accent", "Accent", { 0.78, 0.20, 0.92, 1 }, COL),
            multi("april_ui_color_overrides", "Override Colors For", {
                "Title Bar", "Section Tops", "Sliders", "Scrollbars", "Sidebar", "Checkboxes", "Overlay Panels",
            }, {}, COL),
            color("april_ui_col_title", "Title Bar Color", { 0.78, 0.20, 0.92, 1 }, COL, 1),
            color("april_ui_col_section", "Section Top Color", { 0.78, 0.20, 0.92, 1 }, COL, 2),
            color("april_ui_col_slider", "Slider Color", { 0.78, 0.20, 0.92, 1 }, COL, 3),
            color("april_ui_col_scroll", "Scrollbar Color", { 0.78, 0.20, 0.92, 1 }, COL, 4),
            color("april_ui_col_sidebar", "Sidebar Color", { 0.78, 0.20, 0.92, 1 }, COL, 5),
            color("april_ui_col_checkbox", "Checkbox Color", { 0.78, 0.20, 0.92, 1 }, COL, 6),
            color("april_ui_col_overlay", "Overlay Panel Color", { 0.78, 0.20, 0.92, 1 }, COL, 7),
        },
    }

    local config_group = {
        title = "Config",
        items = {
            input("april_cfg_profile_name", "Profile Name", "Default"),
            sl("april_cfg_slot", "Active Slot (1-5)", 1, 5, 1),
            btn("april_cfg_save", "Save to Active Slot"),
            btn("april_cfg_load", "Load Active Slot"),
            btn("april_cfg_delete", "Delete Active Slot"),
            sep(),
            cb("april_cfg_autoload", "Autoload on Start", false),
            input("april_cfg_autoload_profile", "Autoload Profile Name", "", "april_cfg_autoload"),
            sl("april_cfg_autoload_slot", "Autoload Slot", 1, 5, 1, false, "april_cfg_autoload"),
            sep(),
            sl("april_esp_text_size", "ESP Text Size", 8, 24, 13),
            btn("april_reload_modules", "Reload Game Modules"),
        },
    }

    return { appearance, motion, accent, config_group }
end

function M.groups_for(tab_id)
    if tab_id == "aim" then return build_aim() end
    if tab_id == "visuals" then return build_visuals() end
    if tab_id == "world" then return build_world() end
    if tab_id == "guns" then return build_guns() end
    if tab_id == "misc" then return build_misc() end
    if tab_id == "radar" then return build_radar() end
    if tab_id == "config" then return build_config() end
    return {}
end

return M
