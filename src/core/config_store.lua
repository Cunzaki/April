--[[
    Config persistence — multi-slot save/load, colors, hotkeys, waypoints, autoload meta.
]]

local cache = April.require("core.cache")

local M = {}

M.SLOT_MIN = 1
M.SLOT_MAX = 5
M.FILE_VERSION = 2

local META_FILE = "April_meta.txt"

local EXCLUDE = {
    april_cfg_slot = true,
    april_cfg_profile_name = true,
    april_cfg_autoload = true,
    april_cfg_autoload_slot = true,
    april_cfg_autoload_profile = true,
    april_debug_overlay = true,
    april_gm_held_weapon = true,
}

local MENU_KEYS = {
    "april_esp_text_size",
    "april_tung_esp_enabled", "april_tung_esp_max_dist",
        "april_target_overlay", "april_target_overlay_fov", "april_target_overlay_gear_size", "april_target_overlay_top",
    "april_crosshair_enabled", "april_crosshair_type", "april_crosshair_size", "april_crosshair_gap",
    "april_crosshair_thickness", "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_crosshair_rainbow", "april_crosshair_rainbow_speed",
    "april_brainrot_enabled", "april_brainrot_enabled_mode", "april_brainrot_style", "april_brainrot_size",
    "april_aimbot_fov", "april_aimbot_bone", "april_aimbot_priority",
    "april_aimbot_sticky", "april_aimbot_visible", "april_aimbot_prediction", "april_aimbot_vis_ray",
    "april_aimbot_draw_fov", "april_aimbot_fov_fill", "april_aimbot_target_line",
    "april_gunmods_enabled", "april_gunmods_enabled_mode", "april_gm_mode", "april_gm_weapon_select", "april_gm_recoil", "april_gm_recoil_pct", "april_gm_spread", "april_gm_spread_pct",
    "april_gm_sway", "april_gm_fire_rate", "april_gm_fire_rate_mult",
    "april_gm_speed", "april_gm_speed_mult", "april_gm_range", "april_gm_range_mult",
    "april_farm_helper", "april_farm_helper_mode", "april_farm_radius", "april_farm_smooth",
    "april_world_enabled", "april_world_enabled_mode", "april_stone_node", "april_metal_node", "april_phosphate_node",
    "april_corn_plant", "april_tomato_plant", "april_pumpkin_plant", "april_lemon_plant",
    "april_raspberry_plant", "april_blueberry_plant", "april_wool_plant", "april_hemp_plant",
    "april_deer", "april_boar", "april_wolf",
    "april_world_boxes", "april_world_show_name", "april_world_show_distance", "april_world_range",
    "april_loot_enabled", "april_loot_enabled_mode", "april_dropped_item", "april_wooden_crate", "april_metal_crate",
    "april_steel_crate", "april_food_crate", "april_timed_crate", "april_care_package", "april_btr_crate",
    "april_body_bag", "april_sleeper", "april_trash_can", "april_oil_barrel",
    "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter",
    "april_loot_boxes", "april_loot_show_name", "april_loot_show_distance", "april_loot_range",
    "april_npc_enabled", "april_npc_enabled_mode", "april_npc_soldiers", "april_npc_bosses", "april_npc_box_mode",
    "april_npc_health", "april_npc_skeleton",
    "april_npc_offscreen", "april_npc_show_name", "april_npc_show_distance", "april_npc_range",
    "april_base_enabled", "april_base_enabled_mode", "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_auto_turret_ring", "april_shotgun_turret", "april_shotgun_turret_ring",
    "april_wooden_door", "april_wooden_double_door", "april_salvaged_door", "april_metal_door",
    "april_metal_double_door", "april_steel_door", "april_steel_double_door",
    "april_garage_door", "april_trap_door", "april_triangle_trap_door",
    "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_base_boxes", "april_base_show_name", "april_base_show_distance", "april_base_range",
    "april_waypoints_enabled", "april_waypoints_enabled_mode", "april_wp_dist", "april_wp_beacon", "april_wp_beacon_h",
    "april_wp_draw", "april_wp_slot",
    "april_map_enabled", "april_map_enabled_mode", "april_map_zoom", "april_map_size", "april_map_icon_scale",
    "april_map_show_players", "april_map_show_npcs", "april_map_show_loot", "april_map_show_world",
    "april_map_show_base", "april_map_show_waypoints",
    "april_map_labels",
    "april_noclip_enabled", "april_noclip_enabled_mode", "april_noclip_speed",
    "april_spider_enabled", "april_spider_enabled_mode", "april_spider_speed",
    "april_shark_enabled", "april_shark_enabled_mode", "april_shark_visualize",
    "april_desync_enabled", "april_desync_enabled_mode", "april_desync_autosend", "april_desync_autosend_len",
    "april_desync_visualizer", "april_desync_vis_style", "april_desync_vis_size",
    "april_desync_vis_show_local", "april_desync_vis_link", "april_desync_vis_labels",
    "april_desync_vis_custom_color", "april_desync_vis_color",
    "april_bullet_manip_enabled", "april_bullet_manip_enabled_mode", "april_bullet_manip_range", "april_bullet_manip_speed",
    "april_bullet_manip_debug", "april_bullet_manip_console", "april_bullet_manip_vis",
    "april_bullet_manip_vis_style", "april_bullet_manip_vis_size",
    "april_bullet_manip_vis_link", "april_bullet_manip_vis_labels", "april_bullet_manip_vis_peek",
    "april_mod_checker_enabled", "april_mod_checker_interval",
}

local COLOR_KEYS = {
    "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
    "april_aimbot_prediction", "april_aimbot_vis_ray", "april_aimbot_draw_fov", "april_aimbot_target_line",
    "april_stone_node", "april_metal_node", "april_phosphate_node", "april_corn_plant", "april_tomato_plant",
    "april_pumpkin_plant", "april_lemon_plant", "april_raspberry_plant", "april_blueberry_plant",
    "april_wool_plant", "april_hemp_plant", "april_deer", "april_boar", "april_wolf",
    "april_dropped_item", "april_wooden_crate", "april_metal_crate", "april_steel_crate", "april_food_crate",
    "april_timed_crate", "april_care_package", "april_btr_crate", "april_body_bag", "april_sleeper",
    "april_trash_can", "april_oil_barrel", "april_small_egg", "april_medium_egg", "april_large_egg",
    "april_wooden_boat", "april_military_boat", "april_flycopter",
    "april_npc_soldiers", "april_npc_bosses", "april_npc_skeleton", "april_npc_offscreen",
    "april_base_cabinet", "april_storage_cabinet", "april_small_box", "april_large_box",
    "april_sleeping_bag", "april_auto_turret", "april_auto_turret_ring", "april_shotgun_turret", "april_shotgun_turret_ring", "april_wooden_door",
    "april_wooden_double_door", "april_salvaged_door", "april_metal_door", "april_metal_double_door",
    "april_steel_door", "april_steel_double_door", "april_garage_door", "april_trap_door",
    "april_triangle_trap_door", "april_small_battery", "april_medium_battery", "april_large_battery",
    "april_solar_panel", "april_windmill",
    "april_wp_draw", "april_map_bg", "april_map_grid", "april_map_player_col", "april_map_npc_col", "april_map_loot_col",
    "april_map_world_col", "april_map_base_col", "april_map_wp_col", "april_map_local",
    "april_desync_visualizer", "april_desync_vis_color", "april_desync_vis_local_col",
    "april_bullet_manip_vis_server", "april_bullet_manip_vis_local", "april_bullet_manip_vis_peek", "april_bullet_manip_vis_link",
    "april_shark_visualize",
}

local LEGACY_HOTKEY_TO_CHECKBOX = {
    april_crosshair_enabled_key = "april_crosshair_enabled",
    april_brainrot_enabled_key = "april_brainrot_enabled",
    april_gunmods_enabled_key = "april_gunmods_enabled",
    april_farm_helper_key = "april_farm_helper",
    april_world_enabled_key = "april_world_enabled",
    april_loot_enabled_key = "april_loot_enabled",
    april_npc_enabled_key = "april_npc_enabled",
    april_base_enabled_key = "april_base_enabled",
    april_waypoints_enabled_key = "april_waypoints_enabled",
    april_map_enabled_key = "april_map_enabled",
    april_noclip_enabled_key = "april_noclip_enabled",
    april_spider_enabled_key = "april_spider_enabled",
    april_desync_enabled_key = "april_desync_enabled",
    april_bullet_manip_enabled_key = "april_bullet_manip_enabled",
    april_mod_checker_enabled_key = "april_mod_checker_enabled",
}

local HOTKEY_KEYS = {
    "april_brainrot_enabled",
    "april_gunmods_enabled",
    "april_farm_helper",
    "april_world_enabled",
    "april_loot_enabled",
    "april_npc_enabled",
    "april_base_enabled",
    "april_waypoints_enabled",
    "april_map_enabled",
    "april_noclip_enabled",
    "april_spider_enabled",
    "april_shark_enabled",
    "april_desync_enabled",
    "april_bullet_manip_enabled",
    "april_tung_esp_enabled",
    "april_aimbot_prediction",
}

function M.get_config_path(name)
    local base = os.getenv and os.getenv("LOCALAPPDATA") or ""
    if base == "" then return name end
    return base .. "\\Project Vector\\Scripts\\" .. name
end

local function slot_path(slot)
    return M.get_config_path("April_Slot_" .. tostring(slot) .. ".txt")
end

local function serialize_value(v)
    local t = type(v)
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then return tostring(v) end
    if t == "string" then return v end
    if t == "table" then
        local parts = {}
        for i = 1, #v do
            parts[i] = tostring(v[i])
        end
        return table.concat(parts, ",")
    end
    return nil
end

local function parse_value(raw)
    if raw == "true" then return true end
    if raw == "false" then return false end
    local n = tonumber(raw)
    if n then return n end
    if raw:find(",") then
        local out = {}
        for part in raw:gmatch("[^,]+") do
            table.insert(out, tonumber(part) or part)
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
        local weapons = April.require("game.weapons")
        for _, name in ipairs(weapons.recoil_weapon_names()) do
            add(weapons.slug(name))
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

local function profile_name_from_menu()
    if not menu or not menu.get then return "Default" end
    local name = menu.get("april_cfg_profile_name")
    if type(name) ~= "string" or name:gsub("%s", "") == "" then
        return "Default"
    end
    return name:gsub("[\r\n=]", " "):sub(1, 48)
end

local function read_slot_meta(slot)
    local path = slot_path(slot)
    local f = io.open(path, "r")
    if not f then return nil end

    local meta = {}
    for line in f:lines() do
        if line:sub(1, 1) == "#" then goto continue end
        local key, val = line:match("^([^=]+)=(.+)$")
        if key == "profile_name" then
            meta.profile_name = val
        end
        ::continue::
    end
    f:close()
    return meta
end

function M.find_slot_by_profile_name(name)
    if not name or name == "" then return nil end
    local target = name:lower()
    for slot = M.SLOT_MIN, M.SLOT_MAX do
        local meta = read_slot_meta(slot)
        if meta and meta.profile_name and meta.profile_name:lower() == target then
            return slot
        end
    end
    return nil
end

function M.get_slot_profile_name(slot)
    local meta = read_slot_meta(slot)
    return meta and meta.profile_name or nil
end

function M.slot_exists(slot)
    local f = io.open(slot_path(slot), "r")
    if not f then return false end
    f:close()
    return true
end

function M.save_slot(slot)
    slot = math.floor(tonumber(slot) or 1)
    if slot < M.SLOT_MIN or slot > M.SLOT_MAX then return false end
    if not menu or not menu.get then return false end

    local lines = {
        "# April config v" .. M.FILE_VERSION,
        "version=" .. M.FILE_VERSION,
        "profile_name=" .. profile_name_from_menu(),
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

    for _, id in ipairs(HOTKEY_KEYS) do
        if menu.get_key then
            local vk = menu.get_key(id)
            if vk and vk > 0 then
                table.insert(lines, string.format("@key:%s=%d", id, vk))
            end
        end
    end

    write_waypoints(lines)

    local f = io.open(slot_path(slot), "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    return true
end

function M.load_slot(slot, opts)
    opts = opts or {}
    slot = math.floor(tonumber(slot) or 1)
    if slot < M.SLOT_MIN or slot > M.SLOT_MAX then return false end
    if not menu or not menu.set then return false end

    local path = slot_path(slot)
    local f = io.open(path, "r")
    if not f then return false end

    for i = M.SLOT_MIN, M.SLOT_MAX do
        cache.waypoints[i] = nil
    end

    for line in f:lines() do
        if line:sub(1, 1) ~= "#" and line:find("=") then
            local key, val = line:match("^([^=]+)=(.+)$")
            if key and val then
                if key == "profile_name" then
                    if menu.set then menu.set("april_cfg_profile_name", val) end
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
                end
            end
        end
    end

    f:close()
    April.require("core.settings").invalidate()
    April.require("core.menu_util").sync_masters()

    pcall(function()
        local gun_mods = April.require("features.combat.gun_mods")
        gun_mods._apply_dirty = true
    end)

    return true
end

function M.delete_slot(slot)
    slot = math.floor(tonumber(slot) or 1)
    local path = slot_path(slot)
    if os.remove then
        return os.remove(path) == true
    end
    return false
end

function M.save_meta()
    if not menu or not menu.get then return false end
    local lines = {
        "version=" .. M.FILE_VERSION,
        "autoload=" .. (menu.get("april_cfg_autoload") and "true" or "false"),
        "autoload_slot=" .. tostring(menu.get("april_cfg_autoload_slot") or 1),
        "autoload_profile=" .. tostring(menu.get("april_cfg_autoload_profile") or ""),
        "active_slot=" .. tostring(menu.get("april_cfg_slot") or 1),
    }
    local f = io.open(M.get_config_path(META_FILE), "w")
    if not f then return false end
    f:write(table.concat(lines, "\n"))
    f:close()
    return true
end

function M.load_meta()
    local f = io.open(M.get_config_path(META_FILE), "r")
    if not f or not menu or not menu.set then return false end

    for line in f:lines() do
        local key, val = line:match("^([^=]+)=(.+)$")
        if key == "autoload" then
            menu.set("april_cfg_autoload", val == "true")
        elseif key == "autoload_slot" then
            menu.set("april_cfg_autoload_slot", tonumber(val) or 1)
        elseif key == "autoload_profile" then
            menu.set("april_cfg_autoload_profile", val or "")
        elseif key == "active_slot" then
            menu.set("april_cfg_slot", tonumber(val) or 1)
        end
    end

    f:close()
    April.require("core.settings").invalidate()
    return true
end

function M.try_autoload()
    M.load_meta()
    if not menu or not menu.get then return false end

    local autoload = menu.get("april_cfg_autoload")
    if autoload ~= true and autoload ~= 1 then return false end

    local profile = menu.get("april_cfg_autoload_profile")
    local slot

    if type(profile) == "string" and profile:gsub("%s", "") ~= "" then
        slot = M.find_slot_by_profile_name(profile)
    end

    if not slot then
        slot = math.floor(tonumber(menu.get("april_cfg_autoload_slot")) or 1)
    end

    if slot < M.SLOT_MIN then slot = M.SLOT_MIN end
    if slot > M.SLOT_MAX then slot = M.SLOT_MAX end

    if not M.slot_exists(slot) then
        return false
    end

    if M.load_slot(slot, { silent = true }) then
        return true
    end
    return false
end

return M
