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
    combo = true,
    input = true,
    slider = true,
}

-- Visual / tuning controls — no hover tips.
M.SKIP_IDS = {
    april_aim_draw_fov = true,
    april_aim_fov_style = true,
    april_aim_target_line = true,
    april_silent_draw_fov = true,
    april_silent_fov_style = true,
    april_silent_target_line = true,
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
    april_ui_menu_overlay = true,
    april_ui_snow = true,
    april_fakeduck_spam = true,
}

M.BY_ID = {
    -- Aimbot
    april_aimbot = "Smooth camera aim assist on your current target.",
    april_aim_key = "Hold or toggle this key to activate aimbot.",
    april_silent_aim = "Redirects shots to your locked target without moving the camera.",

    -- Bullet
    april_bullet_enabled = "Master toggle for advanced bullet routing (hitscan, bullet TP, silent manip). Bind Always / Hold / Toggle from the key chip.",
    april_silent_hitscan = "Registers hits instantly on your locked target. Server may reject invalid shots.",
    april_silent_bullet_tp = "Scans the head for the closest visible point to your crosshair (manip-style math), spawns the ray on the target, and shoots through that point. Cycles offsets every frame.",
    april_silent_bullet_manip = "Finds a shootable angle around cover. Server may reject invalid shots.",
    april_silent_manip_extend = "Searches farther from your body when no close peek is found.",
    april_bullet_body_peek = "Moves you to the peek with desync for server-valid shots. Can cause invalids or kicks.",
    april_thick_bullet = "Expands other players' head hitboxes on your client and fades them. Helps local hit tests; the server can still reject shots that only clip the inflated shell.",
    april_thick_bullet_mult = "How large enemy heads become (1x = normal size, up to 4x).",

    -- Aimbot options
    april_aim_targets = "Choose whether aimbot targets players, NPCs, or both.",
    april_aim_filters = "Filters which targets aimbot will consider.",
    april_aim_options = "Extra aimbot behavior options.",
    april_aim_auto_pred = "Leads moving targets using weapon bullet speed and drop. Off = aim the bone only. Also skips prediction when you are not holding a gun.",
    april_aim_smooth = "Higher values move the camera slower toward the target.",
    april_aim_smooth_type = "How smoothing accelerates: Linear, Ease Out, Ease In-Out, Exponential, or Adaptive.",
    april_aim_humanize = "Adds light drift and overshoot so mouse aim feels less robotic.",
    april_aim_humanize_str = "How strong humanize drift and overshoot are.",
    april_aim_whitelist_ids = "Comma-separated Roblox user IDs that Aimbot must ignore. Enable Whitelist inside Filters first. You can also middle-click the current player target to add or remove them.",

    -- Silent aim options
    april_silent_targets = "Choose whether silent aim targets players, NPCs, or both.",
    april_silent_filters = "Filters which targets silent aim will consider.",
    april_silent_options = "Extra silent aim behavior options.",
    april_silent_whitelist_ids = "Comma-separated Roblox user IDs that Silent Aim must ignore. Enable Whitelist inside Filters first. You can also middle-click the current player target to add or remove them.",

    -- Visuals
    april_player_enabled = "Shows boxes and info on other players.",
    april_ui_player_elements = "Choose which info to show on player ESP.",
    april_player_show_held = "Shows the item a player is holding (same read path as Target Gear).",
    april_player_esp_filters = "Filter which players appear on ESP.",
    april_player_esp_flags = "Show status flags (downed, SZ, staff, revive, movement state, VIP, cheater).",
    april_target_overlay = "Shows held weapon and gear for the player closest to your crosshair.",
    april_target_overlay_fov = "Independent FOV (pixels from crosshair) used only by Target Gear Overlay.",
    april_target_overlay_max_dist = "Maximum world distance (studs) for Target Gear Overlay selection.",
    april_crosshair_enabled = "Draws a custom crosshair on screen.",
    april_crosshair_follow = "Moves the crosshair toward your active combat target.",
    april_ui_crosshair_motion = "Adds spin or pulse animation to the crosshair.",
    april_ui_crosshair_options = "Extra crosshair drawing options.",

    -- World masters
    april_world_enabled = "Highlights harvestable resources and animals in the world.",
    april_loot_enabled = "Highlights crates, bags, and other loot in the world.",
    april_base_enabled = "Highlights base parts like doors, turrets, and storage.",
    april_npc_enabled = "Highlights NPC soldiers, bosses, helis, and BTR.",
    april_ui_npc_types = "Choose which NPC types appear on ESP.",
    april_ui_npc_elements = "Choose which info to show on NPC ESP.",
    april_npc_btr = "Shows the BTR event vehicle on NPC ESP.",
    april_raid_enabled = "Marks explosion clusters as potential raids.",
    april_raid_notifications = "Toast when a raid explosion is detected.",

    april_world_boxes = "Draws 3D boxes around visible resources.",
    april_world_show_name = "Shows names on resource ESP.",
    april_world_show_distance = "Shows distance on resource ESP.",
    april_loot_boxes = "Draws 3D boxes around visible loot.",
    april_loot_show_name = "Shows names on loot ESP.",
    april_loot_show_distance = "Shows distance on loot ESP.",
    april_base_boxes = "Draws 3D boxes around visible base parts.",
    april_base_show_name = "Shows names on base ESP.",
    april_base_show_distance = "Shows distance on base ESP.",
    april_npc_soldier = "Shows military Soldier NPCs on ESP.",
    april_npc_bruno = "Shows Bruno boss NPCs on ESP.",
    april_npc_boris = "Shows Boris boss NPCs on ESP.",
    april_npc_brutus = "Shows Brutus boss NPCs on ESP.",
    april_npc_attack_heli = "Shows the Attack Heli event NPC on ESP.",
    april_npc_btr = "Shows the BTR event vehicle on ESP.",
    april_npc_diver_dave = "Shows the Diver Dave vendor NPC on ESP.",
    april_npc_pilot_pete = "Shows the Pilot Pete vendor NPC on ESP.",

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
    april_fly_enabled = "Camera-relative HRP velocity fly (WASD + Space/Ctrl). Built-in duck (HipHeight 0.01) and jump state while airborne — does not toggle Fake Duck. Never changes WalkSpeed or JumpPower.",
    april_fly_noclip = "Disables collision on your key character parts while flying. Collision is restored when you land or turn Fly off.",
    april_spider_enabled = "Climbs upward while you press into a nearby wall. It pulses the jump state only after multi-height wall checks, reducing wall snap-back.",
    april_bhop_enabled = "Auto-jumps while you hold Space on the ground for smoother bunny hops.",
    april_antifling_enabled = "Makes other players' character parts non-collidable on your client. Their original collision values are restored when disabled.",
    april_desync_enabled = "Desyncs your network position from where you appear.",
    april_antiaim_enabled = "Spoofs your look direction to other players.",
    april_fakeduck_enabled = "Rapidly ducks your hitbox height.",
    april_fling_enabled = "Launches nearby entities upward.",

    -- Utility
    april_autofarm = "Automatically turns and runs to selected resources, verifies the live weak point is visible and centered, then swings using the equipped compatible tool. Vector must be the foreground window because movement and clicks use OS input.",
    april_autofarm_resources = "Select every resource type Autofarm may visit. Your held tool must support that type: axes for trees, pickaxes for nodes, or a compatible hybrid tool.",
    april_autofarm_search_range = "Maximum distance in studs used when searching for the next resource. Larger ranges cover more area but can produce longer direct routes.",
    april_autofarm_debug_path = "Draws a tracer to the exact TreeX or NodeSpark point plus the current state, distance, and held tool.",
    april_farm_helper = "Manual alternative to Autofarm. It redirects your held melee swings to the nearest compatible weak point, but you move and hold attack yourself.",
    april_anti_afk = "Prevents idle kick by simulating activity.",
    april_mod_checker_enabled = "Alerts you when staff or mods join the server.",
    april_keybinds_enabled = "Shows an on-screen list of your keybinds.",
    april_event_status_enabled = "Shows live timed crates, event NPCs, and bosses. BTR tracks the 13-minute loot-fire cooldown after destroy (raids use Raid ESP only).",
    april_event_status_active_only = "Hides inactive event rows from the event status panel.",

    -- Radar
    april_map_enabled = "Shows a draggable tactical minimap overlay.",
    april_ui_radar_layers = "Choose what appears on the tactical map.",
    april_map_opacity = "Panel and map transparency for the tactical radar overlay.",
    april_waypoints_enabled = "Place and navigate to saved world waypoints.",

    -- GPU mesh chams (exploits preset indices — see docs/API.md §15)
    april_world_chams = "GPU mesh chams on selected resource types (in-range only).",
    april_world_chams_mode = "Fill, Wireframe, Fill Glow, or Wireframe Glow.",
    april_world_chams_color = "Glow preset color (Fill Glow / Wireframe Glow only).",
    april_loot_chams = "GPU mesh chams on selected loot types (in-range only).",
    april_loot_chams_mode = "Fill, Wireframe, Fill Glow, or Wireframe Glow.",
    april_loot_chams_color = "Glow preset color (Fill Glow / Wireframe Glow only).",
    april_base_chams = "GPU mesh chams on selected base structures (in-range only).",
    april_base_chams_mode = "Fill, Wireframe, Fill Glow, or Wireframe Glow.",
    april_base_chams_color = "Glow preset color (Fill Glow / Wireframe Glow only).",
    april_base_xray_enabled = "Wireframe mesh chams on structural walls/floors/foundations (Detail meshes). ApplyChams only — no Material/Texture/Transparency writes, no new instances. Skips Base ESP targets (doors, boxes, turrets, cabinets).",
    april_base_xray_range = "Only structural pieces within this distance get wireframe chams.",

    -- Config / actions
    april_ui_startup_intro = "Plays the April.lua intro whenever the script executes. Save it in your autoload profile.",
    april_ui_menu_key = "Key used to open and close this menu.",
    april_ui_menu_overlay = "Darkens the whole screen behind the menu with a smooth fade. Does not cover menu controls.",
    april_ui_snow = "Soft falling snow behind the menu. Hidden when Reduce Motion is on.",
    april_anime_baddie_enabled = "Shows a draggable transparent anime announcer that reacts to local survival events. Draw-only: it creates no Roblox instances and writes nothing to Workspace.",
    april_anime_baddie_character = "Selects the announcer. More characters can be added through the character registry.",
    april_anime_baddie_personality = "Mixed alternates between teasing and supportive lines; Roasty and Supportive lock the tone.",
    april_anime_baddie_events = "Choose which read-only local state transitions can trigger dialogue: survival, combat status, nearby threats, and world events.",
    april_anime_baddie_scale = "Changes the waist-up character size.",
    april_anime_baddie_opacity = "Changes character transparency. The speech bubble stays nearly opaque for readability.",
    april_anime_baddie_duration = "How long each speech bubble remains visible.",
    april_anime_baddie_cooldown = "Minimum delay between non-urgent comments. Death, downed, drowning, and combat can interrupt.",
    april_anime_baddie_stay = "Keeps the character visible between comments. Disable for event-only popups.",
    april_anime_baddie_preview = "Plays a random greeting so you can test appearance and dialogue.",
    april_anime_baddie_reset = "Moves the announcer back to the lower-left corner.",
    april_cfg_autoload = "Loads your saved profile automatically on inject.",
    april_aim_whitelist_clear = "Clears the aim whitelist player list.",
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

local FILTER_TIPS = {
    "Rejects dead or zero-health targets. Leave this on unless you specifically need stale targets.",
    "Only selects targets with a clear line of sight. Turning it off allows locking through walls, but shots may still be blocked.",
    "Ignores players on your team. This applies to players only, not NPC types.",
    "Ignores players protected by a safezone so the aim system does not lock onto targets you cannot damage.",
    "Skips whitelisted players. Enter comma-separated Roblox user IDs below, or middle-click the current player target to toggle them. Aimbot and Silent Aim keep separate lists.",
    "Ignores downed players and looks for a target that is still standing.",
}

local TARGET_TIPS = {
    "Targets other players that pass the selected Filters.",
    "Targets standard Soldier NPCs.",
    "Targets the Bruno boss NPC.",
    "Targets the Boris boss NPC.",
    "Targets the Brutus boss NPC.",
    "Targets the Attack Helicopter NPC.",
    "Targets the BTR armored vehicle NPC.",
    "Targets the Diver Dave NPC.",
    "Targets the Pilot Pete NPC.",
}

local HITBOX_TIPS = {
    "Aims at the head for the highest usual damage.",
    "Aims at the torso for a larger, steadier target.",
    "Aims at the target's left arm.",
    "Aims at the target's right arm.",
    "Aims at the target's left leg.",
    "Aims at the target's right leg.",
    "Automatically uses the valid body part closest to your crosshair.",
}

local TARGET_TYPE_TIPS = {
    "Prefers the valid target closest to the center of your screen.",
    "Prefers the valid target closest to your character in world distance.",
}

local STICKY_TIPS = {
    "Keeps the current valid target instead of constantly switching to a slightly better one. The lock is released when that target becomes invalid.",
}

local SMOOTH_TIPS = {
    "Moves toward the target at a consistent smoothing rate.",
    "Moves faster while far away and settles softly near the target.",
    "Uses a gradual acceleration and deceleration curve.",
    "Uses an exponential curve for a responsive but smooth correction.",
    "Automatically moves faster on large misses and slows down for small corrections.",
}

M.OPTION_TIPS = {
    april_aim_target_type = TARGET_TYPE_TIPS,
    april_silent_target_type = TARGET_TYPE_TIPS,
    april_aim_bone = HITBOX_TIPS,
    april_silent_bone = HITBOX_TIPS,
    april_aim_targets = TARGET_TIPS,
    april_silent_targets = TARGET_TIPS,
    april_aim_filters = FILTER_TIPS,
    april_silent_filters = FILTER_TIPS,
    april_aim_options = STICKY_TIPS,
    april_silent_options = STICKY_TIPS,
    april_aim_smooth_type = SMOOTH_TIPS,
    april_crosshair_source = {
        "Uses the first enabled combat system with a valid target.",
        "Follows Silent Aim's current target.",
        "Follows the regular camera Aimbot's current target.",
    },
    april_autofarm_resources = {
        "Allows Autofarm to harvest tree models. Equip an axe, hatchet, chainsaw, or compatible hybrid tool.",
        "Allows Autofarm to mine Stone_Node models. Equip a pickaxe, mining drill, or compatible hybrid tool.",
        "Allows Autofarm to mine Metal_Node models. Equip a pickaxe, mining drill, or compatible hybrid tool.",
        "Allows Autofarm to mine Phosphate_Node models. Equip a pickaxe, mining drill, or compatible hybrid tool.",
    },
}

M.OPTION_BY_LABEL = {
    ["Outline"] = "Draws only the outside edge.",
    ["Filled Circle"] = "Draws a translucent filled circle with an outline.",
    ["Team Check"] = FILTER_TIPS[3],
    ["Skip Safezone"] = FILTER_TIPS[4],
    ["Skip Downed"] = FILTER_TIPS[6],
    ["Visible Only"] = FILTER_TIPS[2],
    ["Health Check"] = FILTER_TIPS[1],
    ["Whitelist"] = FILTER_TIPS[5],
    ["Sticky Target"] = STICKY_TIPS[1],
    ["None"] = "Disables this visual or selection.",
    ["Health Bar"] = "Shows the target's current health as a bar.",
    ["Skeleton"] = "Draws lines between the target's body joints.",
    ["Name"] = "Shows the target's display name.",
    ["Clan Tag"] = "Shows the target's clan tag when available.",
    ["Held Item"] = "Shows the item or weapon the target currently has equipped.",
    ["Distance"] = "Shows how far away the target is.",
    ["Downed"] = "Shows when a player is knocked down.",
    ["Safezone"] = "Shows when a player is protected by a safezone.",
    ["Staff"] = "Shows the staff/moderator status detected for a player.",
    ["Reviving"] = "Shows when a player is reviving someone.",
    ["Movement"] = "Shows useful movement-state information.",
    ["VIP"] = "Shows the player's VIP status when available.",
    ["Spin"] = "Continuously rotates the visual while enabled.",
    ["Pulse Size"] = "Smoothly grows and shrinks the visual.",
    ["Center Dot"] = "Adds a small dot at the exact screen center.",
    ["Rainbow"] = "Cycles the visual through rainbow colors.",
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
    local tip = nil
    if item.tip and item.tip ~= "" then
        tip = item.tip
    elseif item.id and M.BY_ID[item.id] then
        tip = M.BY_ID[item.id]
    else
        tip = fallback_tip(item)
    end
    if not tip then return nil end
    if item.type == "keybind" then
        return tip .. " Left-click the key chip to bind (Mouse 1 works after you release); right-click it for Always, Hold, or Toggle. Hold mode also requires the feature switch enabled. Escape, Backspace, or Delete clears the bind."
    end
    if item.type == "aim_key" then
        return tip .. " Left-click the key chip to bind (Mouse 1 works after you release); right-click it for Always, Hold, or Toggle. Escape, Backspace, or Delete clears the bind."
    end
    if item.type == "hotkey" then
        return tip .. " Left-click the key chip to bind (Mouse 1 works after you release). Escape, Backspace, or Delete clears the bind."
    end
    return tip
end

function M.for_option(id, index, label)
    local by_id = M.OPTION_TIPS[id]
    local tip = by_id and by_id[index] or nil
    if tip then return tip end
    return M.OPTION_BY_LABEL[tostring(label or "")]
end

return M
