local cache = April.require("core.cache")

local M = {}

-- Waypoint slots (unrelated to named configs).
M.SLOT_MIN = 1
M.SLOT_MAX = 5
M.FILE_VERSION = 3

local CONFIG_DIR = "April_configs"
local INDEX_FILE = "index.txt"
local META_FILE = "meta.txt"
local LEGACY_META_FILE = "April_meta.txt"
local EXT = ".cfg"

local EXCLUDE = {
    version = true,
    april_cfg_slot = true,
    april_cfg_selected = true,
    april_cfg_profile_name = true,
    april_cfg_autoload = true,
    april_cfg_autoload_slot = true,
    april_cfg_autoload_profile = true,
    april_cfg_autoload_config = true,
    april_ui_bg_dim = true,
    april_noclip_enabled = true,
    april_noclip_enabled_mode = true,
    april_noclip_speed = true,
    april_slowfall_enabled = true,
    april_slowfall_enabled_mode = true,
    april_slowfall_speed = true,
    april_speed_enabled = true,
    april_speed_enabled_mode = true,
    april_speed_speed = true,
}

local MENU_KEYS = {
    "april_ui_russian",
    "april_ui_theme_preset", "april_ui_window_opacity", "april_ui_panel_opacity",
    "april_ui_border_strength", "april_ui_corner_style", "april_ui_scale", "april_ui_density",
    "april_ui_menu_overlay", "april_ui_overlay_strength",
    "april_ui_snow", "april_ui_snow_amount", "april_ui_snow_speed",
    "april_ui_snow_size", "april_ui_snow_opacity",
    "april_ui_startup_intro", "april_ui_motion_profile", "april_ui_reduce_motion",
    "april_ui_custom_colors", "april_ui_custom_anim", "april_ui_show_cursor_dot",
    "april_ui_accent_anim", "april_ui_anim_speed", "april_ui_menu_fade",
    "april_ui_anim_targets", "april_ui_color_overrides", "april_ui_per_element",
    "april_ui_style_title", "april_ui_style_section", "april_ui_style_slider",
    "april_ui_style_scroll", "april_ui_style_sidebar", "april_ui_style_checkbox",
    "april_ui_style_overlay", "april_ui_window_x", "april_ui_window_y",
    "april_anime_baddie_enabled", "april_anime_baddie_character",
    "april_anime_baddie_personality", "april_anime_baddie_events",
    "april_anime_baddie_scale", "april_anime_baddie_opacity",
    "april_anime_baddie_duration", "april_anime_baddie_cooldown",
    "april_anime_baddie_stay", "april_anime_baddie_x", "april_anime_baddie_y",
    "april_esp_text_size",
    "april_player_enabled", "april_player_enabled_mode",
    "april_player_box_mode", "april_player_box_color",
    "april_player_health", "april_player_skeleton",
    "april_player_show_name", "april_player_show_held", "april_player_show_distance",
    "april_player_clan_tag",
    "april_player_flag_downed", "april_player_flag_safezone",
    "april_player_flag_staff", "april_player_flag_reviving",
    "april_player_flag_movement", "april_player_flag_vip",
    "april_player_flag_cheater",
    "april_player_esp_filters", "april_player_esp_flags",
    "april_player_range",
    "april_sound_esp", "april_sound_esp_fade_in", "april_sound_esp_fade_out",
    "april_sound_esp_size", "april_sound_esp_max_dist", "april_sound_esp_color",
    "april_target_overlay", "april_target_overlay_fov", "april_target_overlay_max_dist",
    "april_target_overlay_gear_size", "april_target_overlay_top",
    "april_crosshair_source",
    "april_crosshair_enabled", "april_crosshair_type", "april_crosshair_size", "april_crosshair_gap",
    "april_crosshair_thickness", "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_crosshair_rainbow", "april_crosshair_rainbow_speed",
    "april_crosshair_follow", "april_crosshair_follow_smooth",
    "april_crosshair_spin", "april_crosshair_spin_speed",
    "april_crosshair_pulse", "april_crosshair_pulse_speed",
    "april_aimbot", "april_aimbot_mode", "april_aim_key", "april_aim_key_mode",
    "april_aim_target_type", "april_aim_bone",
    "april_aim_filters", "april_aim_whitelist_ids",
    "april_aim_targets", "april_aim_options", "april_aim_sticky",
    "april_aim_auto_pred",
    "april_aim_draw_fov", "april_aim_fov_style", "april_aim_target_line",
    "april_aim_max_dist", "april_aim_fov", "april_aim_smooth",
    "april_aim_smooth_type", "april_aim_humanize", "april_aim_humanize_str",
    "april_fov_flags_enabled", "april_fov_flags_visible", "april_fov_flags_distance",
    "april_silent_aim", "april_silent_aim_mode",
    "april_silent_target_type", "april_silent_bone",
    "april_silent_filters", "april_silent_whitelist_ids",
    "april_silent_targets", "april_silent_options", "april_silent_sticky",
    "april_bullet_enabled", "april_bullet_enabled_mode", "april_bullet_body_peek",
    "april_bullet_ug_resolver",
    "april_thick_bullet", "april_thick_bullet_mult",
    "april_silent_bullet_tp",
    "april_silent_bullet_manip",
    "april_silent_manip_dist", "april_silent_manip_extend", "april_silent_manip_extend_dist",
    "april_silent_manip_status", "april_silent_manip_peek_vis",
    "april_silent_draw_fov", "april_silent_fov_style", "april_silent_target_line",
    "april_silent_hit_chance", "april_silent_max_dist", "april_silent_fov", "april_silent_hitscan",
    "april_gunmods_enabled", "april_gunmods_enabled_mode",
    "april_gm_recoil", "april_gm_recoil_pct", "april_gm_spread", "april_gm_spread_pct",
    "april_gm_sway", "april_gm_fire_rate", "april_gm_fire_rate_mult",
    "april_gm_speed", "april_gm_speed_mult",
    "april_gm_range", "april_gm_range_mult",
    "april_gm_double_tap",
    "april_tracers_enabled", "april_tracers_enabled_mode",
    "april_tracers_color", "april_tracers_color2",
    "april_tracers_style", "april_tracers_anim", "april_tracers_anim_speed",
    "april_tracers_lifetime", "april_tracers_thickness", "april_tracers_transparency",
    "april_tracers_segments", "april_tracers_glow", "april_tracers_damage",
    "april_tracers_outline", "april_tracers_impact", "april_tracers_rainbow",
    "april_autofarm", "april_autofarm_mode", "april_autofarm_resources",
    "april_autofarm_search_range", "april_autofarm_debug_path",
    "april_farm_helper", "april_farm_helper_mode", "april_farm_radius",
    "april_world_enabled", "april_world_enabled_mode", "april_stone_node", "april_metal_node", "april_phosphate_node",
    "april_corn_plant", "april_tomato_plant", "april_pumpkin_plant", "april_lemon_plant",
    "april_raspberry_plant", "april_blueberry_plant", "april_wool_plant",
    "april_deer", "april_boar", "april_wolf",
    "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range",
    "april_world_chams", "april_world_chams_mode", "april_world_chams_color",
    "april_loot_enabled", "april_loot_enabled_mode", "april_dropped_item", "april_wooden_crate", "april_metal_crate",
    "april_steel_crate", "april_food_crate", "april_timed_crate", "april_care_package", "april_btr_crate",
    "april_body_bag", "april_sleeper", "april_trash_can", "april_oil_barrel",
    "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter", "april_heli_crate",
    "april_loot_boxes", "april_loot_show_name", "april_loot_show_distance", "april_loot_range",
    "april_loot_chams", "april_loot_chams_mode", "april_loot_chams_color",
    "april_npc_enabled", "april_npc_enabled_mode",
    "april_npc_soldier", "april_npc_bruno", "april_npc_boris", "april_npc_brutus",
    "april_npc_attack_heli", "april_npc_btr", "april_npc_diver_dave", "april_npc_pilot_pete",
    -- Legacy grouped keys remain loadable for older profiles.
    "april_npc_soldiers", "april_npc_bosses", "april_npc_heli",
    "april_npc_box_mode",
    "april_npc_health",
    "april_npc_show_name", "april_npc_show_distance", "april_npc_range",
    "april_raid_enabled", "april_raid_enabled_mode", "april_raid_notifications", "april_raid_range",
    "april_anti_afk",
    "april_base_enabled", "april_base_enabled_mode", "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_auto_turret_ring", "april_shotgun_turret", "april_shotgun_turret_ring",
    "april_wooden_door", "april_wooden_double_door", "april_salvaged_door", "april_metal_door",
    "april_metal_double_door", "april_steel_door", "april_steel_double_door",
    "april_garage_door", "april_trap_door", "april_triangle_trap_door",
    "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range",
    "april_base_chams", "april_base_chams_mode", "april_base_chams_color",
    "april_base_xray_enabled", "april_base_xray_enabled_mode", "april_base_xray_range",
    "april_waypoints_enabled", "april_waypoints_enabled_mode", "april_wp_dist", "april_wp_beacon", "april_wp_beacon_h",
    "april_wp_draw", "april_wp_slot",
    "april_map_enabled", "april_map_enabled_mode", "april_map_zoom", "april_map_size",
    "april_map_opacity", "april_map_icon_scale",
    "april_map_show_players", "april_map_show_npcs", "april_map_show_loot", "april_map_show_world",
    "april_map_show_base", "april_map_show_waypoints", "april_map_show_raids",
    "april_map_labels", "april_map_x", "april_map_y",
    "april_fly_enabled", "april_fly_enabled_mode", "april_fly_speed", "april_fly_noclip",
    "april_bhop_enabled", "april_bhop_enabled_mode",
    "april_spider_enabled", "april_spider_enabled_mode", "april_spider_speed",
    "april_antifling_enabled", "april_antifling_enabled_mode",
    "april_fling_enabled", "april_fling_enabled_mode", "april_fling_fov", "april_fling_duration",
    "april_desync_enabled", "april_desync_enabled_mode",
    "april_desync_visualizer",
    "april_antiaim_enabled", "april_antiaim_enabled_mode",
    "april_antiaim_yaw_mode",
    "april_antiaim_yaw_manual",
    "april_antiaim_spin_speed",
    "april_antiaim_jitter_step", "april_antiaim_jitter_ms",
    "april_fakeduck_enabled", "april_fakeduck_enabled_mode",
    "april_fakeduck_height",
    "april_fakeduck_spam", "april_fakeduck_spam_mode",
    "april_fakeduck_spam_min", "april_fakeduck_spam_max", "april_fakeduck_spam_ms",
    "april_keybinds_enabled", "april_keybinds_active_only", "april_keybinds_show_unbound", "april_keybinds_show_mode",
    "april_keybinds_x", "april_keybinds_y",
    "april_mod_checker_enabled", "april_mod_checker_interval",
    "april_mod_checker_x", "april_mod_checker_y",
    "april_event_status_enabled", "april_event_status_active_only",
    "april_event_status_x", "april_event_status_y",
}

local COLOR_KEYS = {
    "april_ui_accent", "april_ui_col_title", "april_ui_col_section",
    "april_ui_col_slider", "april_ui_col_scroll", "april_ui_col_sidebar",
    "april_ui_col_checkbox", "april_ui_col_overlay",
    "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_aim_draw_fov", "april_aim_target_line",
    "april_silent_draw_fov", "april_silent_target_line",
    "april_player_enabled", "april_player_skeleton", "april_player_show_name", "april_player_clan_tag",
    "april_player_show_held", "april_player_show_distance",
    "april_player_flag_downed", "april_player_flag_safezone",
    "april_player_flag_staff", "april_player_flag_reviving",
    "april_player_flag_movement", "april_player_flag_vip",
    "april_player_flag_cheater",
    "april_player_box_color",
    "april_raid_enabled",
    "april_stone_node", "april_metal_node", "april_phosphate_node", "april_corn_plant", "april_tomato_plant",
    "april_pumpkin_plant", "april_lemon_plant", "april_raspberry_plant", "april_blueberry_plant",
    "april_wool_plant", "april_deer", "april_boar", "april_wolf",
    "april_dropped_item", "april_wooden_crate", "april_metal_crate", "april_steel_crate", "april_food_crate",
    "april_timed_crate", "april_care_package", "april_btr_crate", "april_body_bag", "april_sleeper",
    "april_trash_can", "april_oil_barrel", "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter", "april_heli_crate",
    "april_npc_soldier", "april_npc_bruno", "april_npc_boris", "april_npc_brutus",
    "april_npc_attack_heli", "april_npc_btr", "april_npc_diver_dave", "april_npc_pilot_pete",
    "april_npc_soldiers", "april_npc_bosses", "april_npc_heli",
    "april_npc_show_name", "april_npc_show_distance",
    "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_auto_turret_ring", "april_shotgun_turret", "april_shotgun_turret_ring", "april_wooden_door",
    "april_wooden_double_door", "april_salvaged_door", "april_metal_door", "april_metal_double_door",
    "april_steel_door", "april_steel_double_door", "april_garage_door", "april_trap_door",
    "april_triangle_trap_door", "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_wp_draw", "april_map_player_col", "april_map_npc_col", "april_map_loot_col",
    "april_map_world_col", "april_map_base_col", "april_map_wp_col", "april_map_raid_col",
    "april_desync_visualizer",
}

local LEGACY_HOTKEY_TO_CHECKBOX = {
    april_crosshair_enabled_key = "april_crosshair_enabled",
    april_gunmods_enabled_key = "april_gunmods_enabled",
    april_farm_helper_key = "april_farm_helper",
    april_world_enabled_key = "april_world_enabled",
    april_loot_enabled_key = "april_loot_enabled",
    april_npc_enabled_key = "april_npc_enabled",
    april_raid_enabled_key = "april_raid_enabled",
    april_base_enabled_key = "april_base_enabled",
    april_waypoints_enabled_key = "april_waypoints_enabled",
    april_map_enabled_key = "april_map_enabled",
    april_desync_enabled_key = "april_desync_enabled",
    april_mod_checker_enabled_key = "april_mod_checker_enabled",
}

local HOTKEY_KEYS = {
    "april_gunmods_enabled",
    "april_autofarm",
    "april_farm_helper",
    "april_world_enabled",
    "april_loot_enabled",
    "april_npc_enabled",
    "april_raid_enabled",
    "april_base_enabled",
    "april_base_xray_enabled",
    "april_waypoints_enabled",
    "april_map_enabled",
    "april_fly_enabled",
    "april_spider_enabled",
    "april_bhop_enabled",
    "april_antifling_enabled",
    "april_fling_enabled",
    "april_desync_enabled",
    "april_antiaim_enabled",
    "april_fakeduck_enabled",
    "april_silent_aim",
    "april_bullet_enabled",
    "april_player_enabled",
    "april_aim_key",
    "april_ui_menu_key",
}

local function collect_hotkey_keys()
    local out, seen = {}, {}
    local function add(id)
        if not id or seen[id] then return end
        seen[id] = true
        out[#out + 1] = id
    end
    for _, id in ipairs(HOTKEY_KEYS) do add(id) end
    pcall(function()
        local binds = April.require("core.feature_bind")
        for _, entry in ipairs(binds.list_entries()) do
            add(entry.key_id or entry.id)
        end
    end)
    table.sort(out)
    return out
end

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name or "" end
    local scripts = base .. "\\Project Vector\\Scripts"
    if not name or name == "" then return scripts end
    return scripts .. "\\" .. name
end

function M.scripts_dir()
    return M.get_config_path("")
end

-- Vector often blocks os.execute. Prefer folder storage, but always keep a
-- flat Scripts\ fallback that only needs io.open (same as old April_Slot_N).
local storage_mode = nil -- "dir" | "flat"

local function dir_writable(dir)
    if not dir or dir == "" or not io or not io.open then return false end
    local probe = dir .. "\\.april_dir"
    local f = io.open(probe, "w")
    if not f then return false end
    f:close()
    if os and os.remove then pcall(os.remove, probe) end
    return true
end

local function try_mkdir(dir)
    if dir_writable(dir) then return true end
    if os and os.execute then
        pcall(os.execute, 'cmd /c if not exist "' .. dir .. '" mkdir "' .. dir .. '"')
        pcall(os.execute, 'mkdir "' .. dir .. '"')
    end
    return dir_writable(dir)
end

function M.configs_dir()
    return M.get_config_path(CONFIG_DIR)
end

local function resolve_storage()
    if storage_mode then return storage_mode end
    if try_mkdir(M.configs_dir()) then
        storage_mode = "dir"
    else
        storage_mode = "flat"
    end
    return storage_mode
end

function M.ensure_configs_dir()
    return resolve_storage() == "dir"
end

function M.storage_mode()
    return resolve_storage()
end

-- Safe on-disk stem: "My Rage Config!" -> "My_Rage_Config"
function M.sanitize_stem(name)
    name = tostring(name or "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("[\r\n\t]", " ")
    name = name:gsub('[<>:"/\\|%?%*]', "")
    name = name:gsub("%s+", "_")
    name = name:gsub("_+", "_")
    name = name:gsub("^_+", ""):gsub("_+$", "")
    name = name:gsub("%.+$", "")
    if name == "" then name = "Default" end
    if #name > 48 then name = name:sub(1, 48) end
    return name
end

function M.display_name(stem)
    stem = tostring(stem or "Default")
    return stem:gsub("_", " ")
end

function M.config_filename(name_or_stem)
    local stem = M.sanitize_stem(name_or_stem)
    if resolve_storage() == "dir" then
        return stem .. EXT
    end
    return "April_Config_" .. stem .. EXT
end

-- Preferred write/read path for a named config (dir or flat).
function M.config_path(name_or_stem)
    local stem = M.sanitize_stem(name_or_stem)
    if resolve_storage() == "dir" then
        return M.configs_dir() .. "\\" .. stem .. EXT
    end
    return M.get_config_path("April_Config_" .. stem .. EXT)
end

-- Every location a named config might live (for load/exists/migration).
local function config_path_candidates(name_or_stem)
    local stem = M.sanitize_stem(name_or_stem)
    return {
        M.configs_dir() .. "\\" .. stem .. EXT,
        M.get_config_path("April_Config_" .. stem .. EXT),
        M.get_config_path(stem .. EXT),
    }
end

local function index_path()
    if resolve_storage() == "dir" then
        return M.configs_dir() .. "\\" .. INDEX_FILE
    end
    return M.get_config_path("April_config_index.txt")
end

local function meta_path()
    if resolve_storage() == "dir" then
        return M.configs_dir() .. "\\" .. META_FILE
    end
    -- Flat mode reuses the legacy meta file so autoload keeps working.
    return M.get_config_path(LEGACY_META_FILE)
end

local function legacy_slot_path(slot)
    return M.get_config_path("April_Slot_" .. tostring(slot) .. ".txt")
end

local function file_exists(path)
    if not path then return false end
    local f = io.open(path, "r")
    if not f then return false end
    f:close()
    return true
end

local function read_profile_name_from_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local name
    for line in f:lines() do
        if line:sub(1, 1) ~= "#" then
            local key, val = line:match("^([^=]+)=(.+)$")
            if key == "profile_name" then
                name = val
                break
            end
        end
    end
    f:close()
    return name
end

local function open_writable(path)
    if not path then return nil end
    return io.open(path, "w")
end

local function write_text_file(path, body)
    local f = open_writable(path)
    if not f then return false end
    f:write(body)
    f:close()
    return true
end

local function read_index_stems()
    local stems, seen = {}, {}
    local f = io.open(index_path(), "r")
    if f then
        for line in f:lines() do
            if line:sub(1, 1) ~= "#" then
                local stem = line:match("^%s*(.-)%s*$")
                if stem and stem ~= "" and not seen[stem:lower()] then
                    seen[stem:lower()] = true
                    stems[#stems + 1] = stem
                end
            end
        end
        f:close()
    end
    return stems, seen
end

local function write_index_stems(stems)
    local f = open_writable(index_path())
    if not f then return false end
    f:write("# April config index\n")
    for i = 1, #stems do
        f:write(stems[i] .. "\n")
    end
    f:close()
    return true
end

local function scan_named_cfg_stems()
    local stems, seen = {}, {}
    local function add(stem)
        if not stem or stem == "" then return end
        local key = stem:lower()
        if seen[key] then return end
        seen[key] = true
        stems[#stems + 1] = stem
    end

    local function scan_dir(dir, pattern)
        if not io or not io.popen or not dir then return end
        local ok, pipe = pcall(io.popen, 'dir /b "' .. dir .. '\\' .. pattern .. '" 2>nul')
        if not ok or not pipe then return end
        for line in pipe:lines() do
            local stem = line:match("^April_Config_(.+)%.cfg$")
            if stem then
                add(stem)
            else
                stem = line:match("^(.+)%.cfg$")
                if stem and stem:sub(1, 6) ~= "April_" then
                    add(stem)
                elseif stem and not line:find("^April_Config_", 1, true)
                    and not line:find("^April_Slot_", 1, true)
                then
                    -- Files inside April_configs\Name.cfg
                    if dir:find("April_configs", 1, true) then
                        add(stem)
                    end
                end
            end
        end
        pipe:close()
    end

    scan_dir(M.configs_dir(), "*.cfg")
    scan_dir(M.scripts_dir(), "April_Config_*.cfg")

    -- Probe known stems from index + common defaults without relying on dir.
    local indexed = read_index_stems()
    for i = 1, #indexed do
        local stem = indexed[i]
        for _, path in ipairs(config_path_candidates(stem)) do
            if file_exists(path) then
                add(stem)
                break
            end
        end
    end

    return stems, seen
end

local function collect_legacy_slot_stems(seen)
    local stems = {}
    seen = seen or {}
    for slot = 1, 5 do
        local path = legacy_slot_path(slot)
        if file_exists(path) then
            local pname = read_profile_name_from_file(path) or ("Slot_" .. slot)
            local stem = M.sanitize_stem(pname)
            if stem:lower() == "default" and slot ~= 1 then
                stem = "Slot_" .. slot
            end
            -- Prefer a unique stem if Default already taken by another source.
            if seen[stem:lower()] then
                local alt = M.sanitize_stem(pname .. "_" .. slot)
                if not seen[alt:lower()] then stem = alt end
            end
            if not seen[stem:lower()] then
                seen[stem:lower()] = true
                stems[#stems + 1] = stem
            end
        end
    end
    return stems, seen
end

local cached_stems = nil

local function resolve_existing_path(name_or_stem)
    local stem = M.sanitize_stem(name_or_stem)
    for _, path in ipairs(config_path_candidates(stem)) do
        if file_exists(path) then return path, stem end
    end
    -- Legacy slots by profile name / Slot_N
    for slot = 1, 5 do
        local path = legacy_slot_path(slot)
        if file_exists(path) then
            local pname = read_profile_name_from_file(path) or ("Slot_" .. slot)
            local slot_stem = M.sanitize_stem(pname)
            if slot_stem:lower() == stem:lower()
                or stem:lower() == ("slot_" .. slot)
                or (stem:lower() == "default" and slot == 1 and slot_stem:lower() == "default")
            then
                return path, stem
            end
        end
    end
    return nil, stem
end

function M.refresh_index()
    resolve_storage()
    local stems, seen = {}, {}
    local indexed = read_index_stems()
    for i = 1, #indexed do
        local stem = indexed[i]
        if not seen[stem:lower()] then
            seen[stem:lower()] = true
            stems[#stems + 1] = stem
        end
    end
    local scanned = scan_named_cfg_stems()
    for i = 1, #scanned do
        local stem = scanned[i]
        if not seen[stem:lower()] then
            seen[stem:lower()] = true
            stems[#stems + 1] = stem
        end
    end
    local legacy = collect_legacy_slot_stems(seen)
    for i = 1, #legacy do
        stems[#stems + 1] = legacy[i]
    end

    local alive = {}
    for i = 1, #stems do
        local stem = stems[i]
        if resolve_existing_path(stem) then
            alive[#alive + 1] = stem
        end
    end
    table.sort(alive, function(a, b) return a:lower() < b:lower() end)
    write_index_stems(alive)
    cached_stems = alive
    return alive
end

function M.list_configs()
    if cached_stems then return cached_stems end
    return M.refresh_index()
end

function M.list_config_labels()
    local stems = M.list_configs()
    local labels = {}
    for i = 1, #stems do
        labels[i] = M.display_name(stems[i])
    end
    return labels, stems
end

local function profile_name_from_menu()
    if not menu or not menu.get then return "Default" end
    local name = menu.get("april_cfg_profile_name")
    if type(name) ~= "string" or name:gsub("%s", "") == "" then
        return "Default"
    end
    return name:gsub("[\r\n=]", " "):sub(1, 48)
end

function M.active_stem()
    local _, stems = M.list_config_labels()
    if #stems == 0 then
        return M.sanitize_stem(profile_name_from_menu())
    end
    local idx = 0
    if menu and menu.get then
        idx = math.floor(tonumber(menu.get("april_cfg_selected")) or 0)
    end
    if idx < 0 then idx = 0 end
    if idx >= #stems then idx = #stems - 1 end
    return stems[idx + 1] or M.sanitize_stem(profile_name_from_menu())
end

function M.set_selected_stem(stem)
    if not menu or not menu.set then return end
    local stems = M.list_configs()
    stem = M.sanitize_stem(stem)
    for i = 1, #stems do
        if stems[i]:lower() == stem:lower() then
            menu.set("april_cfg_selected", i - 1)
            menu.set("april_cfg_profile_name", M.display_name(stems[i]))
            return
        end
    end
    menu.set("april_cfg_profile_name", M.display_name(stem))
end

function M.config_exists(name_or_stem)
    return resolve_existing_path(name_or_stem) ~= nil
end

local function index_add(stem)
    stem = M.sanitize_stem(stem)
    local stems = M.list_configs()
    for i = 1, #stems do
        if stems[i]:lower() == stem:lower() then
            return
        end
    end
    local next_list = {}
    for i = 1, #stems do next_list[i] = stems[i] end
    next_list[#next_list + 1] = stem
    table.sort(next_list, function(a, b) return a:lower() < b:lower() end)
    write_index_stems(next_list)
    cached_stems = next_list
end

local function index_remove(stem)
    stem = M.sanitize_stem(stem)
    local stems = M.list_configs()
    local out = {}
    for i = 1, #stems do
        if stems[i]:lower() ~= stem:lower() then
            out[#out + 1] = stems[i]
        end
    end
    write_index_stems(out)
    cached_stems = out
end

local function serialize_value(v)
    local t = type(v)
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then return tostring(v) end
    if t == "string" then return v end
    if t == "table" then
        local parts = {}
        local n = #v
        -- 0-based arrays from some menu builds
        if n == 0 and v[0] ~= nil then
            local i = 0
            while v[i] ~= nil do
                local item = v[i]
                if type(item) == "boolean" then
                    parts[#parts + 1] = item and "1" or "0"
                elseif item == 1 or item == "1" or item == true then
                    parts[#parts + 1] = "1"
                else
                    parts[#parts + 1] = "0"
                end
                i = i + 1
            end
            return table.concat(parts, ",")
        end
        for i = 1, n do
            local item = v[i]
            if type(item) == "boolean" then
                parts[i] = item and "1" or "0"
            elseif item == 1 or item == "1" or item == true or item == "true" then
                parts[i] = "1"
            elseif type(item) == "number" then
                parts[i] = tostring(item)
            else
                parts[i] = "0"
            end
        end
        return table.concat(parts, ",")
    end
    return nil
end

local function parse_value(raw)
    if raw == "true" then return true end
    if raw == "false" then return false end
    local n = tonumber(raw)
    if n and not raw:find(",") then return n end
    if raw:find(",") then
        local out = {}
        for part in raw:gmatch("[^,]+") do
            part = part:match("^%s*(.-)%s*$") or part
            if part == "true" or part == "1" then
                out[#out + 1] = true
            elseif part == "false" or part == "0" then
                out[#out + 1] = false
            else
                out[#out + 1] = tonumber(part) or part
            end
        end
        return out
    end
    return raw
end

local function color_line(id, c)
    if not c then return nil end
    return string.format("@color:%s=%s,%s,%s,%s", id, c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1)
end

local function collect_menu_keys()
    local seen = {}
    local out = {}

    local function add(id)
        if not id or EXCLUDE[id] or seen[id] then return end
        seen[id] = true
        table.insert(out, id)
    end

    for _, id in ipairs(MENU_KEYS) do add(id) end

    pcall(function()
        local fb = April.require("core.feature_bind")
        for _, entry in ipairs(fb.list_entries()) do
            add(entry.mode_id)
            add(fb.hide_key_id(entry.id))
        end
    end)

    return out
end

local function write_waypoints(lines)
    for i = M.SLOT_MIN, M.SLOT_MAX do
        local wp = cache.waypoints[i]
        if wp and wp.pos then
            table.insert(lines, string.format("wp:%d:name=%s", i, wp.name or ("Waypoint " .. i)))
            table.insert(lines, string.format("wp:%d:x=%s", i, wp.pos.x))
            table.insert(lines, string.format("wp:%d:y=%s", i, wp.pos.y))
            table.insert(lines, string.format("wp:%d:z=%s", i, wp.pos.z))
        end
    end
end

local function read_waypoints(id, field, val)
    local slot = tonumber(id)
    if not slot then return end
    cache.waypoints[slot] = cache.waypoints[slot] or { name = "Waypoint " .. slot, pos = {} }
    local wp = cache.waypoints[slot]
    if field == "name" then
        wp.name = val
    elseif field == "x" or field == "y" or field == "z" then
        wp.pos = wp.pos or {}
        wp.pos[field] = tonumber(val) or 0
    end
end

local function build_snapshot_lines(display_name)
    local lines = {
        "# April config v" .. M.FILE_VERSION,
        "version=" .. M.FILE_VERSION,
        "profile_name=" .. tostring(display_name or "Default"),
    }

    for _, id in ipairs(collect_menu_keys()) do
        local v = menu.get(id)
        local s = serialize_value(v)
        if s ~= nil then
            table.insert(lines, id .. "=" .. s)
        end
    end

    for _, id in ipairs(COLOR_KEYS) do
        if menu.get_color then
            local line = color_line(id, menu.get_color(id))
            if line then table.insert(lines, line) end
        end
    end

    for _, id in ipairs(collect_hotkey_keys()) do
        if menu.get_key then
            local vk = menu.get_key(id)
            if vk ~= nil then
                table.insert(lines, string.format("@key:%s=%d", id, tonumber(vk) or 0))
            end
        end
    end

    write_waypoints(lines)
    return lines
end

local function apply_config_file(path, opts)
    opts = opts or {}
    if not menu or not menu.set then return false end

    local f = io.open(path, "r")
    if not f then return false end

    -- Complete snapshots: clear binds first so missing keys cannot inherit.
    if menu.set_key then
        for _, id in ipairs(collect_hotkey_keys()) do
            menu.set_key(id, 0)
        end
    end

    for i = M.SLOT_MIN, M.SLOT_MAX do
        cache.waypoints[i] = nil
    end

    local loaded_keys = {}
    local profile_name
    for line in f:lines() do
        if line:sub(1, 1) ~= "#" and line:find("=") then
            local key, val = line:match("^([^=]+)=(.+)$")
            if key and val then
                if key == "profile_name" then
                    profile_name = val
                    menu.set("april_cfg_profile_name", val)
                elseif key:sub(1, 7) == "@color:" then
                    local id = key:sub(8)
                    local r, g, b, a = val:match("([^,]+),([^,]+),([^,]+),([^,]+)")
                    if id and menu.set_color then
                        menu.set_color(id, {
                            tonumber(r) or 0,
                            tonumber(g) or 0,
                            tonumber(b) or 0,
                            tonumber(a) or 1,
                        })
                    end
                elseif key:sub(1, 5) == "@key:" then
                    local id = key:sub(6)
                    local vk = tonumber(val)
                    if id and vk and menu.set_key then
                        local target = LEGACY_HOTKEY_TO_CHECKBOX[id] or id
                        menu.set_key(target, vk)
                    end
                elseif key:sub(1, 3) == "wp:" then
                    local slot_id, field = key:match("^wp:(%d+):(%w+)$")
                    read_waypoints(slot_id, field, val)
                elseif not EXCLUDE[key] then
                    menu.set(key, parse_value(val))
                    loaded_keys[key] = true
                end
            end
        end
    end

    if loaded_keys.april_target_gear_source
        and not loaded_keys.april_crosshair_source
        and menu.get
    then
        menu.set("april_crosshair_source", menu.get("april_target_gear_source"))
    end

    f:close()

    if opts.stem then
        M.set_selected_stem(opts.stem)
    elseif profile_name then
        M.set_selected_stem(profile_name)
    end

    April.require("core.settings").invalidate()
    April.require("core.menu_util").sync_masters()

    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        if gun_mods.schedule_apply then
            gun_mods.schedule_apply(1500)
        else
            gun_mods._apply_dirty = true
            gun_mods._defer_until = (utility and utility.get_tick_count and utility.get_tick_count() or 0) + 1500
        end
    end)

    return true
end

function M.save_config(name)
    if not menu or not menu.get then return false, nil end
    resolve_storage()

    local display = name
    if type(display) ~= "string" or display:gsub("%s", "") == "" then
        display = profile_name_from_menu()
    end
    display = display:gsub("[\r\n=]", " "):sub(1, 48)
    local stem = M.sanitize_stem(display)
    local body = table.concat(build_snapshot_lines(display), "\n")

    -- Prefer active storage, then every candidate path until one writes.
    local paths = { M.config_path(stem) }
    for _, p in ipairs(config_path_candidates(stem)) do
        paths[#paths + 1] = p
    end
    -- Last-resort: classic slot 1 path so save never hard-fails for users.
    paths[#paths + 1] = legacy_slot_path(1)

    local path
    for i = 1, #paths do
        if write_text_file(paths[i], body) then
            path = paths[i]
            break
        end
    end
    if not path then return false, nil end

    index_add(stem)
    cached_stems = nil
    if menu.set then
        menu.set("april_cfg_profile_name", display)
    end
    M.set_selected_stem(stem)
    return true, stem, path
end

function M.load_config(name_or_stem, opts)
    opts = opts or {}
    local stem = M.sanitize_stem(name_or_stem or M.active_stem())
    local path = resolve_existing_path(stem)
    if path and apply_config_file(path, { stem = stem, silent = opts.silent }) then
        return true, stem, path
    end
    return false, stem, path
end

function M.delete_config(name_or_stem)
    local stem = M.sanitize_stem(name_or_stem or M.active_stem())
    local ok = false
    -- Only remove named config files. Never delete April_Slot_N.txt backups.
    for _, path in ipairs(config_path_candidates(stem)) do
        if file_exists(path) and path:find("April_Slot_", 1, true) == nil and os and os.remove then
            if os.remove(path) == true then ok = true end
        end
    end
    index_remove(stem)
    cached_stems = nil
    M.refresh_index()
    return ok, stem
end

-- Import April_Slot_N.txt + April_meta.txt into named configs. Safe to re-run.
local migrated = false
function M.migrate_legacy()
    if migrated then return true end
    migrated = true
    resolve_storage()

    for slot = 1, 5 do
        local legacy = legacy_slot_path(slot)
        local f = io.open(legacy, "r")
        if f then
            local body = f:read("*a")
            f:close()
            if type(body) == "string" and body ~= "" then
                local pname = body:match("profile_name=([^\r\n]+)") or ("Slot_" .. slot)
                local stem = M.sanitize_stem(pname)
                if stem:lower() == "default" and slot ~= 1 then
                    stem = "Slot_" .. slot
                end
                -- Copy into named storage when missing; leave legacy file intact.
                local existing = resolve_existing_path(stem)
                local only_legacy = existing and existing:find("April_Slot_", 1, true)
                if (not existing) or only_legacy then
                    local dest = M.config_path(stem)
                    if not write_text_file(dest, body) then
                        write_text_file(M.get_config_path("April_Config_" .. stem .. EXT), body)
                    end
                end
                index_add(stem)
            end
        end
    end

    -- Merge legacy meta keys into current meta without wiping autoload.
    local legacy_meta = M.get_config_path(LEGACY_META_FILE)
    local lf = io.open(legacy_meta, "r")
    if lf then
        local autoload, autoload_profile, autoload_slot, active_slot
        for line in lf:lines() do
            local key, val = line:match("^([^=]+)=(.+)$")
            if key == "autoload" then autoload = val == "true"
            elseif key == "autoload_profile" or key == "autoload_config" then
                autoload_profile = val
            elseif key == "autoload_slot" then autoload_slot = tonumber(val)
            elseif key == "active_slot" then active_slot = tonumber(val)
            elseif key == "active_config" and (not autoload_profile or autoload_profile == "") then
                autoload_profile = val
            end
        end
        lf:close()

        local active_name = autoload_profile
        local slot = active_slot or autoload_slot
        if (not active_name or active_name == "") and slot then
            active_name = read_profile_name_from_file(legacy_slot_path(slot))
        end

        -- Write/merge meta to whatever storage is writable.
        local existing = {}
        local mf_in = io.open(meta_path(), "r")
        if mf_in then
            for line in mf_in:lines() do
                local key, val = line:match("^([^=]+)=(.+)$")
                if key then existing[key] = val end
            end
            mf_in:close()
        end
        if autoload ~= nil then existing.autoload = autoload and "true" or "false" end
        if autoload_profile and autoload_profile ~= "" then
            existing.autoload_config = autoload_profile
        end
        if active_name and active_name ~= "" then
            existing.active_config = active_name
        end
        if autoload_slot then
            existing.autoload_slot = tostring(autoload_slot)
        end
        existing.version = tostring(M.FILE_VERSION)

        local lines = {
            "version=" .. existing.version,
            "autoload=" .. tostring(existing.autoload or "false"),
            "autoload_config=" .. tostring(existing.autoload_config or ""),
            "active_config=" .. tostring(existing.active_config or ""),
            "autoload_slot=" .. tostring(existing.autoload_slot or "1"),
        }
        write_text_file(meta_path(), table.concat(lines, "\n"))
        -- Also keep Scripts\April_meta.txt updated for older builds / flat mode.
        if meta_path() ~= legacy_meta then
            write_text_file(legacy_meta, table.concat(lines, "\n"))
        end
    end

    cached_stems = nil
    M.refresh_index()
    return true
end

function M.save_meta()
    if not menu or not menu.get then return false end
    resolve_storage()
    local active = M.active_stem()
    local autoload_name = menu.get("april_cfg_autoload_config")
    if type(autoload_name) ~= "string" or autoload_name:gsub("%s", "") == "" then
        autoload_name = menu.get("april_cfg_autoload_profile") or ""
    end
    local autoload_slot = math.floor(tonumber(menu.get("april_cfg_autoload_slot")) or 1)
    local lines = {
        "version=" .. M.FILE_VERSION,
        "autoload=" .. (menu.get("april_cfg_autoload") and "true" or "false"),
        "autoload_config=" .. tostring(autoload_name or ""),
        "autoload_profile=" .. tostring(autoload_name or ""),
        "autoload_slot=" .. tostring(autoload_slot),
        "active_config=" .. tostring(active or ""),
        "active_slot=" .. tostring(autoload_slot),
    }
    local body = table.concat(lines, "\n")
    local ok = write_text_file(meta_path(), body)
    -- Always mirror to legacy path so older loaders / flat mode keep working.
    local legacy = M.get_config_path(LEGACY_META_FILE)
    if meta_path() ~= legacy then
        write_text_file(legacy, body)
    end
    return ok
end

function M.load_meta()
    M.migrate_legacy()
    if not menu or not menu.set then return false end

    local f = io.open(meta_path(), "r")
    if not f then
        f = io.open(M.get_config_path(LEGACY_META_FILE), "r")
    end
    if not f then return false end

    local active_config, autoload_config, autoload_slot
    for line in f:lines() do
        local key, val = line:match("^([^=]+)=(.+)$")
        if key == "autoload" then
            menu.set("april_cfg_autoload", val == "true")
        elseif key == "autoload_config" or key == "autoload_profile" then
            autoload_config = val or ""
            menu.set("april_cfg_autoload_config", autoload_config)
            menu.set("april_cfg_autoload_profile", autoload_config)
        elseif key == "autoload_slot" or key == "active_slot" then
            autoload_slot = tonumber(val) or autoload_slot
            if key == "autoload_slot" then
                menu.set("april_cfg_autoload_slot", autoload_slot or 1)
            end
        elseif key == "active_config" then
            active_config = val or ""
        end
    end
    f:close()

    if active_config and active_config ~= "" then
        M.set_selected_stem(active_config)
    elseif autoload_config and autoload_config ~= "" then
        M.set_selected_stem(autoload_config)
    end

    April.require("core.settings").invalidate()
    return true
end

function M.try_autoload()
    M.migrate_legacy()
    M.load_meta()
    if not menu or not menu.get then return false end

    local autoload = menu.get("april_cfg_autoload")
    if autoload ~= true and autoload ~= 1 then return false end

    -- 1) Named config / profile
    local name = menu.get("april_cfg_autoload_config")
    if type(name) ~= "string" or name:gsub("%s", "") == "" then
        name = menu.get("april_cfg_autoload_profile")
    end
    if type(name) == "string" and name:gsub("%s", "") ~= "" then
        if M.load_config(name, { silent = true }) then
            return true
        end
    end

    -- 2) Legacy slot fallback (April_Slot_N.txt) — critical for existing users
    local slot = math.floor(tonumber(menu.get("april_cfg_autoload_slot")) or 1)
    if slot < 1 then slot = 1 end
    if slot > 5 then slot = 5 end
    local legacy = legacy_slot_path(slot)
    if file_exists(legacy) and apply_config_file(legacy, { silent = true }) then
        local pname = read_profile_name_from_file(legacy) or ("Slot_" .. slot)
        M.set_selected_stem(pname)
        return true
    end

    -- 3) Any first available config
    local stems = M.list_configs()
    if stems[1] and M.load_config(stems[1], { silent = true }) then
        return true
    end
    return false
end

-- Back-compat wrappers (old slot API -> named configs).
function M.save_slot(_slot)
    return M.save_config(profile_name_from_menu())
end

function M.load_slot(_slot, opts)
    return M.load_config(M.active_stem(), opts)
end

function M.delete_slot(_slot)
    return M.delete_config(M.active_stem())
end

function M.slot_exists(_slot)
    return M.config_exists(M.active_stem())
end

return M
