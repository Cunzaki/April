--[[
  April UI — template catalog (no game features).

  HOW TO USE
  ----------
  1. Edit M.TABS to add/remove sidebar tabs (id + icon + title).
     Icon names: aim, visuals, world, guns, misc, radar, config
  2. Implement build_<tab>() that returns an array of "groups".
  3. Wire the tab in M.groups_for().
  4. Read live values from ui.gs_state (see standalone_app examples).

  ITEM HELPERS
  ------------
  cb(id, label, default, color?, gate?)     checkbox (+ optional color swatch)
  kb(id, label, default, gate?)             checkbox with keybind chip
  hk(id, label, gate?, default_vk?)         hotkey only
  ak(key_id, label, gate?)                  aim-key (key + mode combo)
  sl(id, label, min, max, default, float?, gate?)
  combo(id, label, options, default, gate?)
  multi(id, label, options, defaults, gate?)
  color(id, label, default, gate?)
  input(id, label, default, gate?)
  btn(id, label, gate?)
  sep(gate?)                                thin separator
  label(text, dim?, gate?)                  static text

  GATING
  ------
  gate = "parent_id"  -> item only shows while that checkbox is ON
  group.master = "id" -> whole group (except the master row) hides when off
]]

local M = {}

local function cb(id, label, default, color, gate)
    return { type = "checkbox", id = id, label = label, default = default == true, color = color, gate = gate }
end

local function kb(id, label, default, gate)
    return { type = "keybind", id = id, label = label, default = default == true, gate = gate }
end

local function sl(id, label, minv, maxv, default, float, gate)
    return {
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
end

local function combo(id, label, options, default, gate)
    return { type = "combo", id = id, label = label, options = options, default = default or 0, gate = gate }
end

local function multi(id, label, options, defaults, gate)
    return { type = "multi", id = id, label = label, options = options, defaults = defaults, gate = gate }
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

local function color(id, label_text, default, gate)
    return { type = "color", id = id, label = label_text, default = default, gate = gate }
end

local function input(id, label_text, default, gate)
    return { type = "input", id = id, label = label_text, default = default or "", gate = gate }
end

local function hk(id, label, gate, default_vk)
    return { type = "hotkey", id = id, label = label, gate = gate, default = default_vk or 0x2D }
end

local function ak(key_id, label, gate)
    return { type = "aim_key", id = key_id, mode_id = key_id .. "_mode", label = label, gate = gate }
end

-- Sidebar tabs (icon must exist in ui.gs_icons).
M.TABS = {
    { id = "aim", icon = "aim", title = "Aimbot" },
    { id = "visuals", icon = "visuals", title = "Visuals" },
    { id = "world", icon = "world", title = "World" },
    { id = "misc", icon = "misc", title = "Misc" },
    { id = "config", icon = "config", title = "Config" },
}

local function build_aim()
    return {
        {
            title = "Example Aimbot",
            master = "demo_aim_enabled",
            items = {
                cb("demo_aim_enabled", "Enable Aimbot", false),
                ak("demo_aim_key", "Aim Key"),
                sep(),
                label("Targeting", false),
                combo("demo_aim_priority", "Priority", { "Crosshair", "Distance" }, 0),
                combo("demo_aim_hitbox", "Hitbox", { "Head", "Chest", "Closest" }, 0),
                multi("demo_aim_filters", "Filters", { "Visible", "Knocked", "Team" }, { true, false, true }),
                sep(),
                sl("demo_aim_fov", "FOV", 10, 360, 90),
                sl("demo_aim_smooth", "Smooth", 1, 25, 8),
                cb("demo_aim_draw_fov", "Draw FOV", false, { 0.2, 1, 0.45, 1 }),
            },
        },
        {
            title = "Silent Aim (example)",
            master = "demo_silent_enabled",
            items = {
                cb("demo_silent_enabled", "Enable Silent", false),
                sl("demo_silent_hitchance", "Hit Chance", 1, 100, 100, false, "demo_silent_enabled"),
                cb("demo_silent_wallbang", "Ignore Walls", false, nil, "demo_silent_enabled"),
            },
        },
    }
end

local function build_visuals()
    return {
        {
            title = "Player ESP (example)",
            master = "demo_esp_enabled",
            items = {
                kb("demo_esp_enabled", "Player ESP", false),
                combo("demo_esp_box", "Box", { "None", "2D", "Corner" }, 1, "demo_esp_enabled"),
                cb("demo_esp_health", "Health Bar", true, nil, "demo_esp_enabled"),
                cb("demo_esp_name", "Name", true, { 1, 0.35, 0.35, 1 }, "demo_esp_enabled"),
                cb("demo_esp_distance", "Distance", true, nil, "demo_esp_enabled"),
                sl("demo_esp_range", "Range", 50, 2000, 500, false, "demo_esp_enabled"),
            },
        },
        {
            title = "Colors",
            items = {
                label("Standalone color pickers", true),
                color("demo_esp_box_color", "Box Color", { 1, 0.3, 0.3, 1 }),
                color("demo_esp_skel_color", "Skeleton Color", { 1, 1, 1, 0.9 }),
            },
        },
    }
end

local function build_world()
    return {
        {
            title = "World ESP (example)",
            master = "demo_world_enabled",
            items = {
                kb("demo_world_enabled", "World ESP", false),
                cb("demo_world_crates", "Crates", false, { 1, 0.85, 0.2, 1 }, "demo_world_enabled"),
                cb("demo_world_vehicles", "Vehicles", false, { 0.3, 0.8, 1, 1 }, "demo_world_enabled"),
                sl("demo_world_range", "Range", 50, 2000, 800, false, "demo_world_enabled"),
            },
        },
    }
end

local function build_misc()
    return {
        {
            title = "Movement (example)",
            items = {
                kb("demo_speed_enabled", "Speed Hack", false),
                sl("demo_speed_amount", "Speed Amount", 1, 10, 2, true, "demo_speed_enabled"),
                kb("demo_fly_enabled", "Fly", false),
            },
        },
        {
            title = "Actions",
            items = {
                label("Buttons fire callbacks via gs_state.on / set_button", true),
                btn("demo_misc_reload", "Reload Script"),
                btn("demo_misc_panic", "Panic Disable"),
                input("demo_misc_note", "Note", "hello"),
            },
        },
    }
end

local function build_config()
    return {
        {
            title = "Appearance",
            items = {
                hk("april_ui_menu_key", "Menu Key", nil, 0x2D),
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
        },
        {
            title = "Motion & Accent",
            items = {
                combo("april_ui_motion_profile", "Motion Profile", {
                    "Subtle", "Balanced", "Expressive",
                }, 1),
                cb("april_ui_reduce_motion", "Reduce Motion", false),
                cb("april_ui_custom_anim", "Animated Accents", false),
                combo("april_ui_accent_anim", "Accent Style", {
                    "Static", "Rainbow", "Pulse", "Wave", "Flow",
                }, 1, "april_ui_custom_anim"),
                sl("april_ui_anim_speed", "Accent Speed", 1, 100, 40, false, "april_ui_custom_anim"),
                sep(),
                cb("april_ui_custom_colors", "Custom Accent", false),
                color("april_ui_accent", "Accent Color", { 0.78, 0.20, 0.92, 1 }, "april_ui_custom_colors"),
                sep(),
                label("Replace this tab with save/load if you want configs.", true),
                btn("demo_config_reset", "Reset Demo Values"),
            },
        },
    }
end

function M.groups_for(tab_id)
    if tab_id == "aim" then return build_aim() end
    if tab_id == "visuals" then return build_visuals() end
    if tab_id == "world" then return build_world() end
    if tab_id == "misc" then return build_misc() end
    if tab_id == "config" then return build_config() end
    return {}
end

return M
