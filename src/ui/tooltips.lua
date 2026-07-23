-- Hover tooltip copy keyed by setting id (what it does, not how).
local esp_maps = April.require("game.esp_maps")

local M = {}

M.ALLOW_TYPES = {
    checkbox = true,
    keybind = true,
    aim_key = true,
    hotkey = true,
    button = true,
    multi = true,
}

-- Visual / tuning controls — no hover tips.
M.SKIP_IDS = {
    april_aim_draw_fov = true,
    april_aim_fov_style = true,
    april_aim_target_line = true,
    april_silent_draw_fov = true,
    april_silent_fov_style = true,
    april_silent_target_line = true,
    april_silent_tp_ray_vis = true,
    april_silent_tp_method = true,
    april_silent_manip_status = true,
    april_silent_manip_peek_vis = true,
    april_desync_visualizer = true,
    april_keybinds_active_only = true,
    april_keybinds_show_unbound = true,
    april_keybinds_show_mode = true,
    april_wp_dist = true,
    april_wp_beacon = true,
    april_wp_draw = true,
    april_ui_show_cursor_dot = true,
    april_ui_custom_colors = true,
    april_ui_custom_anim = true,
    april_ui_reduce_motion = true,
    april_ui_menu_fade = true,
    april_ui_per_element = true,
    april_fakeduck_spam = true,
}

M.BY_ID = {
    -- Aimbot
    april_aimbot = "Smooth camera aim assist on your current target.",
    april_aim_key = "Hold or toggle this key to activate aimbot.",
    april_rage_enabled = "Aggressive no-FOV aim with autofire on valid targets.",
    april_silent_aim = "Redirects shots to your locked target without moving the camera.",
    april_rage_autofire = "Automatically clicks when ragebot has a valid shot.",

    -- Bullet
    april_bullet_enabled = "Turns on advanced bullet routing for silent aim.",
    april_silent_hitscan = "Registers hits instantly on your locked target. Server may reject invalid shots.",
    april_silent_bullet_tp = "Scans the head for the closest visible point to your crosshair (manip-style math), spawns the ray on the target, and shoots through that point. Cycles offsets every frame.",
    april_silent_bullet_manip = "Finds a shootable angle around cover. Server may reject invalid shots.",
    april_silent_manip_extend = "Searches farther from your body when no close peek is found.",
    april_bullet_body_peek = "Moves you to the peek with desync for server-valid shots. Can cause invalids or kicks.",

    -- Aimbot options
    april_aim_targets = "Choose whether aimbot targets players, NPCs, or both.",
    april_aim_filters = "Filters which targets aimbot will consider.",
    april_aim_options = "Extra aimbot behavior options.",

    -- Ragebot options
    april_rage_targets = "Choose whether ragebot targets players, NPCs, or both.",
    april_rage_filters = "Filters which targets ragebot will consider.",
    april_rage_options = "Extra ragebot behavior options.",

    -- Silent aim options
    april_silent_targets = "Choose whether silent aim targets players, NPCs, or both.",
    april_silent_filters = "Filters which targets silent aim will consider.",
    april_silent_options = "Extra silent aim behavior options.",

    -- Visuals
    april_player_enabled = "Shows boxes and info on other players.",
    april_ui_player_elements = "Choose which info to show on player ESP.",
    april_player_esp_filters = "Filter which players appear on ESP.",
    april_player_esp_flags = "Show status flags on player ESP.",
    april_target_overlay = "Shows your target's held weapon and gear loadout.",
    april_crosshair_enabled = "Draws a custom crosshair on screen.",
    april_crosshair_follow = "Moves the crosshair toward your active combat target.",
    april_ui_crosshair_motion = "Adds spin or pulse animation to the crosshair.",
    april_ui_crosshair_options = "Extra crosshair drawing options.",

    -- World masters
    april_world_enabled = "Highlights harvestable resources and animals in the world.",
    april_loot_enabled = "Highlights crates, bags, and other loot in the world.",
    april_base_enabled = "Highlights base parts like doors, turrets, and storage.",
    april_npc_enabled = "Highlights NPC soldiers and bosses.",
    april_ui_npc_types = "Choose which NPC types appear on ESP.",
    april_ui_npc_elements = "Choose which info to show on NPC ESP.",

    april_world_boxes = "Draws 3D boxes around visible resources.",
    april_world_show_name = "Shows names on resource ESP.",
    april_world_show_distance = "Shows distance on resource ESP.",
    april_loot_boxes = "Draws 3D boxes around visible loot.",
    april_loot_show_name = "Shows names on loot ESP.",
    april_loot_show_distance = "Shows distance on loot ESP.",
    april_base_boxes = "Draws 3D boxes around visible base parts.",
    april_base_show_name = "Shows names on base ESP.",
    april_base_show_distance = "Shows distance on base ESP.",
    april_npc_soldiers = "Shows soldier NPCs on ESP.",
    april_npc_bosses = "Shows boss NPCs on ESP.",

    -- Gun mods
    april_gunmods_enabled = "Applies weapon stat changes globally to your held gun.",
    april_gm_recoil = "Lowers recoil. Works on any gun — no attachment required.",
    april_gm_spread = "Tightens aim and hip spread. Sights (Holo, ACOG, scopes) also add spread mults that this stacks with.",
    april_gm_sway = "Removes scope sway while aiming. Only affects guns with a scope or sight equipped.",
    april_gm_fire_rate = "Boosts RPM via FireRateMult. Usually needs Muzzle Boost on the gun — without it the game often ignores fire-rate mults.",
    april_gm_speed = "Boosts bullet speed via SpeedMult on live weapon tables. Not an attachment stat — Swift Heavy Ammo also adds speed; equip a gun before enabling.",
    april_gm_range = "Extends max range via RangeMult. Silencer and Compensator reduce range; this patches whatever range mults exist on your gun.",
    april_gm_double_tap = "Forces a 2-round burst on your held gun. Patches ToolInfo directly — does not use GC mults.",

    -- Movement
    april_noclip_enabled = "Lets you fly through the world.",
    april_slowfall_enabled = "Slows your fall speed.",
    april_desync_enabled = "Desyncs your network position from where you appear.",
    april_antiaim_enabled = "Spoofs your look direction to other players.",
    april_fakeduck_enabled = "Rapidly ducks your hitbox height.",
    april_fling_enabled = "Launches nearby entities upward.",

    -- Utility
    april_farm_helper = "Automatically farms nearby nodes and plants.",
    april_farm_silent = "Uses silent aim while farm helper is active.",
    april_anti_afk = "Prevents idle kick by simulating activity.",
    april_mod_checker_enabled = "Alerts you when staff or mods join the server.",
    april_keybinds_enabled = "Shows an on-screen list of your keybinds.",

    -- Radar
    april_map_enabled = "Shows a draggable tactical minimap overlay.",
    april_ui_radar_layers = "Choose what appears on the tactical map.",
    april_waypoints_enabled = "Place and navigate to saved world waypoints.",

    -- Config / actions
    april_ui_menu_key = "Key used to open and close this menu.",
    april_cfg_autoload = "Loads your saved profile automatically on inject.",
    april_aim_whitelist_clear = "Clears the aim whitelist player list.",
    april_rage_whitelist_clear = "Clears the ragebot whitelist player list.",
    april_silent_whitelist_clear = "Clears the silent aim whitelist player list.",
    april_map_reset_position = "Moves the tactical map back to its default spot.",
    april_wp_set = "Saves your current position to the active waypoint slot.",
    april_wp_clear = "Clears the active waypoint slot.",
    april_wp_clear_all = "Clears every saved waypoint.",
    april_cfg_save = "Saves your settings to the active config slot.",
    april_cfg_load = "Loads settings from the active config slot.",
    april_cfg_delete = "Deletes the active config slot.",
    april_reload_modules = "Reloads game module offsets and caches.",
}

local function register_esp_toggles(list, scope)
    for _, t in ipairs(list or {}) do
        if t.id and not M.BY_ID[t.id] then
            M.BY_ID[t.id] = "Highlights " .. t.label .. " on " .. scope .. "."
        end
        if t.ring_id and not M.BY_ID[t.ring_id] then
            M.BY_ID[t.ring_id] = "Shows a range ring around nearby " .. t.label .. "."
        end
    end
end

register_esp_toggles(esp_maps.WORLD_TOGGLES, "resource ESP")
register_esp_toggles(esp_maps.LOOT_TOGGLES, "loot ESP")
register_esp_toggles(esp_maps.BASE_TOGGLES, "base ESP")

local function clean_label(label)
    label = tostring(label or "")
    label = label:gsub("^Enable ", "")
    return label
end

local function fallback_tip(item)
    local label = clean_label(item.label)
    if label == "" then return nil end

    if item.type == "button" then
        return label .. "."
    end
    if item.type == "aim_key" or item.type == "hotkey" then
        return "Keybind for " .. label:lower() .. "."
    end
    if item.type == "keybind" then
        return "Toggle " .. label:lower() .. "."
    end
    if item.type == "checkbox" or item.type == "multi" then
        return "Enables " .. label:lower() .. "."
    end
    return nil
end

function M.should_tooltip(item)
    if not item or not item.id then return false end
    if not M.ALLOW_TYPES[item.type] then return false end
    if M.SKIP_IDS[item.id] then return false end
    return true
end

function M.for_item(item)
    if not M.should_tooltip(item) then return nil end
    if item.tip and item.tip ~= "" then
        return item.tip
    end
    if item.id and M.BY_ID[item.id] then
        return M.BY_ID[item.id]
    end
    return fallback_tip(item)
end

return M
