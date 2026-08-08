-- Draggable, read-only anime announcer overlay.
-- It only reads April's local entity cache/attributes/GUI and draws HTTPS PNGs.
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local cache = April.require("core.cache")
local ep = April.require("core.entity_props")
local env = April.require("core.env")
local player_state = April.require("game.player_state")
local team_state = April.require("game.team_state")
local npcs = April.require("game.npcs")
local folders = April.require("game.folders")
local data = April.require("game.anime_announcer_data")
local image_cache = April.require("core.image_cache")
local draw_util = April.require("core.draw_util")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")

local M = {}

local P = "april_anime_baddie_enabled"
local CHARACTER_ID = "april_anime_baddie_character"
local PERSONALITY_ID = "april_anime_baddie_personality"
local EVENTS_ID = "april_anime_baddie_events"
local SCALE_ID = "april_anime_baddie_scale"
local OPACITY_ID = "april_anime_baddie_opacity"
local DURATION_ID = "april_anime_baddie_duration"
local COOLDOWN_ID = "april_anime_baddie_cooldown"
local STAY_ID = "april_anime_baddie_stay"
local X_ID = "april_anime_baddie_x"
local Y_ID = "april_anime_baddie_y"
local PREVIEW_ID = "april_anime_baddie_preview"
local RESET_ID = "april_anime_baddie_reset"

local PERSONALITIES = { "Mixed", "Roasty", "Supportive" }
local EVENT_LABELS = {
    "Death / Respawn",
    "Downed / Revived",
    "Low Health",
    "Safe Zone",
    "Combat / Bleed",
    "Survival Needs",
    "Nearby Threats",
    "World Events",
}
local EVENT_SLOT = {
    death = 1, respawn = 1,
    downed = 2, revived = 2,
    low_health = 3, recovered = 3,
    safe_enter = 4, safe_leave = 4,
    combat_enter = 5, combat_leave = 5, bleeding = 5, bleed_stopped = 5,
    hunger_low = 6, thirst_low = 6, radiation = 6, cold = 6, hot = 6, drowning = 6,
    staff_nearby = 7, enemy_nearby = 7, reviving = 7, party_join = 7, party_leave = 7,
    boss_spawn = 8, timed_crate = 8,
}
local PRIORITY = {
    greeting = 100, death = 100, drowning = 95, downed = 90,
    combat_enter = 85, bleeding = 82, respawn = 80, low_health = 75,
    radiation = 72, staff_nearby = 70, revived = 65, enemy_nearby = 62,
    hunger_low = 58, thirst_low = 58, recovered = 55, cold = 50, hot = 50,
    boss_spawn = 48, timed_crate = 46, reviving = 44, party_join = 42,
    party_leave = 40, combat_leave = 38, bleed_stopped = 36,
    safe_leave = 34, safe_enter = 32,
}

local installed = false
local was_enabled = false
local seeded = false
local ever_alive = false
local dead_since = false
local reset_pending = false
local visibility = 0
local current = nil
local queued = nil
local last_line = {}
local snapshot = {}
local last_emit_ms = -100000
local session_key = nil
local last_scan_ms = -100000
local nearby_cd = {}
local layout_entry
local stats_root = nil
local stats_refs = {}
local last_stats_root_ms = -100000
local last_stats_ms = -100000
local last_world_ms = -100000
local sensed = {}

local BUBBLE_W = 304
local BUBBLE_PAD = 14
local BUBBLE_FONT = 14
local BUBBLE_LINE_H = 18
local BUBBLE_HEADER_H = 24
local NEARBY_PLAYER_RANGE = 500

local function now_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, value = pcall(fn)
    return ok and (tonumber(value) or 0) or 0
end

local function as_bool(value)
    if value == true or value == 1 or value == "true" or value == "1" then return true end
    return false
end

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local function persist_num(id, value)
    value = math.floor(tonumber(value) or 0)
    if menu and menu.set then pcall(menu.set, id, value) end
    pcall(function() April.require("ui.gs_state").set(id, value) end)
end

local function session_id()
    local place = game and (game.PlaceId or game.place_id) or 0
    local job = game and (game.JobId or game.job_id) or ""
    return tostring(place) .. ":" .. tostring(job)
end

local function reset_runtime()
    seeded = false
    ever_alive = false
    dead_since = false
    snapshot = {}
    current = nil
    queued = nil
    visibility = 0
    last_emit_ms = -100000
    last_scan_ms = -100000
    last_stats_ms = -100000
    last_world_ms = -100000
    nearby_cd = {}
    stats_root = nil
    stats_refs = {}
    last_stats_root_ms = -100000
    sensed = {}
end

local function event_enabled(event_name)
    local slot = EVENT_SLOT[event_name]
    if not slot then return true end
    return settings.multi(EVENTS_ID, slot, true)
end

local function active_character()
    return data.character(settings.combo_index(CHARACTER_ID, data.character_labels, 0))
end

local function personality_name()
    local index = settings.combo_index(PERSONALITY_ID, PERSONALITIES, 0)
    if index == 1 then return "roasty" end
    if index == 2 then return "supportive" end
    return math.random(1, 100) <= 58 and "roasty" or "supportive"
end

local function choose_line(event_name)
    local character = active_character()
    local dialogue = data.dialogue_for(character)
    local event_pool = dialogue and dialogue[event_name]
    if not event_pool then return nil end
    local tone = personality_name()
    local pool = event_pool[tone] or event_pool.roasty or event_pool.supportive
    if type(pool) ~= "table" or #pool == 0 then return nil end

    local lang = "en"
    pcall(function()
        if April.require("ui.i18n").is_ru() then lang = "ru" end
    end)
    local repeat_key = character.id .. ":" .. lang .. ":" .. event_name .. ":" .. tone
    local index = math.random(1, #pool)
    if #pool > 1 and index == last_line[repeat_key] then
        index = (index % #pool) + 1
    end
    last_line[repeat_key] = index
    local entry = pool[index]
    return {
        character = character,
        event = event_name,
        expression = entry[1] or "neutral",
        text = entry[2] or "",
        priority = PRIORITY[event_name] or 1,
    }
end

local function activate(entry, now)
    if not entry then return end
    local duration = clamp(settings.num(DURATION_ID, 5), 2, 10) * 1000
    if layout_entry then layout_entry(entry) end
    entry.started = now
    entry.expires = now + duration
    current = entry
    last_emit_ms = now
    local ch = entry.character
    local sprite = ch.sprite_file and ch.sprite_file(entry.expression) or (entry.expression .. ".png")
    local key = "anime_baddie:" .. ch.id .. ":" .. tostring(sprite):gsub("%.png$", "")
    image_cache.preload(key, ch.urls(entry.expression))
end

local function emit(event_name, force)
    if not settings.bool(P, false) or not event_enabled(event_name) then return end
    local entry = choose_line(event_name)
    if not entry then return end
    local now = now_ms()
    local cooldown = clamp(settings.num(COOLDOWN_ID, 8), 2, 30) * 1000
    local urgent = entry.priority >= 80

    if force or urgent or (not current and now - last_emit_ms >= cooldown) then
        if current and not force and entry.priority <= (current.priority or 0) then
            if not queued or entry.priority > (queued.priority or 0) then queued = entry end
            return
        end
        activate(entry, now)
        return
    end

    if not queued or entry.priority > (queued.priority or 0) then
        queued = entry
    end
end

local function emit_gated(event_name, gate_ms)
    local now = now_ms()
    local until_ms = nearby_cd[event_name] or 0
    if now < until_ms then return end
    nearby_cd[event_name] = now + (gate_ms or 20000)
    emit(event_name)
end

local function find_child(parent, name)
    if not parent or not name then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

local function read_attr(inst, key)
    if not inst or not key then return nil end
    local ok, value = pcall(function()
        if inst.get_attribute then return inst:get_attribute(key) end
        if inst.GetAttribute then return inst:GetAttribute(key) end
        return nil
    end)
    if ok then return value end
    return nil
end

local function status_active(stats, name)
    local child = stats_refs[name]
    if not child then
        child = find_child(stats, name)
        stats_refs[name] = child
    end
    if not child then return false end
    local reach = tonumber(read_attr(child, "Reach"))
    if reach ~= nil then return reach > 0 end
    return true
end

local function parse_stat_value(stats, name)
    local root_key = name .. ":root"
    local root = stats_refs[root_key]
    if not root then
        root = find_child(stats, name)
        stats_refs[root_key] = root
    end
    if not root then return nil end
    local label_key = name .. ":label"
    local label = stats_refs[label_key]
    if not label then
        local bar = find_child(root, "Bar")
        label = find_child(bar, "StatLabel") or find_child(root, "StatLabel")
        stats_refs[label_key] = label
    end
    local text = label and env.safe_call(function()
        return label.Text or label.text
    end)
    if text == nil then return nil end
    return tonumber(tostring(text):match("(%d+)"))
end

local function local_stats()
    local player = cache.local_player or ep.get_local_player()
    if not player then return {} end
    local stats = stats_root
    local now = now_ms()
    if not stats or now - last_stats_root_ms >= 1000 then
        last_stats_root_ms = now
        local pgui = find_child(player, "PlayerGui")
        local main = find_child(pgui, "Main")
        local resolved = find_child(main, "Stats")
        if resolved ~= stats_root then
            stats_root = resolved
            stats_refs = {}
        end
        stats = stats_root
    end
    if not stats then return {} end

    local temp = find_child(stats, "Temperature")
    local temp_reach = temp and tonumber(read_attr(temp, "Reach")) or 0
    local hunger = parse_stat_value(stats, "Hunger")
    local thirst = parse_stat_value(stats, "Thirst")

    return {
        combat = status_active(stats, "InCombat"),
        bleed = status_active(stats, "Bleed"),
        radiation = status_active(stats, "Radiation"),
        drowning = status_active(stats, "Drowning"),
        cold = temp_reach <= -8 or status_active(stats, "Cold"),
        hot = temp_reach >= 29 or status_active(stats, "Hot"),
        hunger = hunger,
        thirst = thirst,
        hunger_low = hunger ~= nil and hunger <= 25,
        thirst_low = thirst ~= nil and thirst <= 25,
    }
end

local function boss_present()
    for _, entry in ipairs(cache.npcs or {}) do
        if entry and npcs.is_boss_kind(entry.kind) then
            return true
        end
    end
    return false
end

local function timed_crate_present()
    local bucket = find_child(folders.from_key("loners"), "Timed Crate")
    if not bucket then return false end
    local kids = env.safe_call(function()
        if bucket.GetChildren then return bucket:GetChildren() end
        if bucket.get_children then return bucket:get_children() end
        return {}
    end) or {}
    for _, model in ipairs(kids) do
        local name = model and (model.Name or model.name)
        if name == "Timed Crate" then return true end
    end
    return false
end

local function nearby_flags(local_player)
    local me_pos = ep.position(local_player)
    local staff = false
    local enemy = false
    if not me_pos then return staff, enemy end

    for _, player in ipairs(cache.players or {}) do
        if player and not ep.is_local(player) and player_state.is_combat_target(player) then
            local dist = ep.distance_to(player, me_pos)
            if dist and dist <= NEARBY_PLAYER_RANGE then
                if player_state.staff_tag(player) then staff = true end
                if not team_state.is_teammate(player) then enemy = true end
            end
            if staff and enemy then break end
        end
    end
    return staff, enemy
end

local function local_state()
    local local_player = cache.local_player or ep.get_local_player()
    if not local_player then return nil end

    local hp = ep.health(local_player)
    local max_hp = ep.max_health(local_player)
    local character = ep.character(local_player)
    local valid_character = character and env.is_valid(character)
    local alive_flag = ep.is_alive(local_player)
    local alive = valid_character and alive_flag ~= false and (hp == nil or hp > 0)
    local ratio = nil
    if hp and max_hp and max_hp > 0 then ratio = hp / max_hp end

    local downed = as_bool(player_state.humanoid_attr(local_player, "Downed"))
    local now = now_ms()
    if now - last_stats_ms >= 180 then
        last_stats_ms = now
        local stats = local_stats()
        sensed.combat = stats.combat == true
        sensed.bleed = stats.bleed == true
        sensed.radiation = stats.radiation == true
        sensed.drowning = stats.drowning == true
        sensed.cold = stats.cold == true
        sensed.hot = stats.hot == true
        sensed.hunger_low = stats.hunger_low == true
        sensed.thirst_low = stats.thirst_low == true
        sensed.safe = as_bool(player_state.player_attr(local_player, "SafeZone"))
            or as_bool(player_state.player_attr(local_player, "InSafeZone"))
    end

    if alive and now - last_scan_ms >= 450 then
        last_scan_ms = now
        sensed.staff_nearby, sensed.enemy_nearby = nearby_flags(local_player)
        sensed.party = team_state.in_party() == true
        sensed.reviving = not downed and player_state.is_reviving(local_player) == true
    end

    if now - last_world_ms >= 900 then
        last_world_ms = now
        sensed.boss = boss_present()
        sensed.timed_crate = timed_crate_present()
    end

    return {
        alive = alive,
        hp = hp,
        max_hp = max_hp,
        ratio = ratio,
        low = alive and ratio ~= nil and ratio <= 0.30,
        downed = alive and downed,
        safe = sensed.safe == true,
        combat = sensed.combat == true,
        bleed = sensed.bleed == true,
        radiation = sensed.radiation == true,
        drowning = sensed.drowning == true,
        cold = sensed.cold == true,
        hot = sensed.hot == true,
        hunger_low = alive and sensed.hunger_low == true,
        thirst_low = alive and sensed.thirst_low == true,
        party = sensed.party == true,
        reviving = alive and sensed.reviving == true,
        staff_nearby = alive and sensed.staff_nearby == true,
        enemy_nearby = alive and sensed.enemy_nearby == true,
        boss = sensed.boss == true,
        timed_crate = sensed.timed_crate == true,
    }
end

local function seed_state(state)
    snapshot = state
    seeded = true
    if state.alive then ever_alive = true end
end

local function edge_bool(prev, next_value, on_event, off_event)
    if prev ~= next_value then
        if next_value then
            if on_event then emit(on_event) end
        elseif off_event then
            emit(off_event)
        end
    end
end

local function detect_edges(state)
    if not seeded then
        seed_state(state)
        return
    end

    if snapshot.alive and not state.alive and ever_alive then
        dead_since = true
        emit("death")
    elseif not snapshot.alive and state.alive then
        if dead_since then emit("respawn") end
        ever_alive = true
        dead_since = false
    end

    if state.alive then
        if not snapshot.downed and state.downed then
            emit("downed")
        elseif snapshot.downed and not state.downed then
            emit("revived")
        end

        if not snapshot.low and state.low and not state.downed then
            emit("low_health")
        elseif snapshot.low and not state.low and state.ratio and state.ratio >= 0.55 then
            emit("recovered")
        end

        if snapshot.safe ~= state.safe then
            emit(state.safe and "safe_enter" or "safe_leave")
        end

        edge_bool(snapshot.combat, state.combat, "combat_enter", "combat_leave")
        edge_bool(snapshot.bleed, state.bleed, "bleeding", "bleed_stopped")
        edge_bool(snapshot.radiation, state.radiation, "radiation", nil)
        edge_bool(snapshot.drowning, state.drowning, "drowning", nil)
        edge_bool(snapshot.cold, state.cold, "cold", nil)
        edge_bool(snapshot.hot, state.hot, "hot", nil)
        edge_bool(snapshot.hunger_low, state.hunger_low, "hunger_low", nil)
        edge_bool(snapshot.thirst_low, state.thirst_low, "thirst_low", nil)
        edge_bool(snapshot.party, state.party, "party_join", "party_leave")
        edge_bool(snapshot.reviving, state.reviving, "reviving", nil)

        if not snapshot.staff_nearby and state.staff_nearby then
            emit_gated("staff_nearby", 45000)
        end
        if not snapshot.enemy_nearby and state.enemy_nearby then
            emit_gated("enemy_nearby", 18000)
        end
        if not snapshot.boss and state.boss then
            emit_gated("boss_spawn", 30000)
        end
        if not snapshot.timed_crate and state.timed_crate then
            emit_gated("timed_crate", 30000)
        end
    end

    snapshot = state
end

local function ease_out_back(t)
    t = clamp(t, 0, 1)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * ((t - 1) ^ 3) + c1 * ((t - 1) ^ 2)
end

local function text_width(text, size)
    local fn = draw and (draw.get_text_size or draw.GetTextSize)
    if type(fn) == "function" then
        local ok, width = pcall(fn, text, size)
        if ok and type(width) == "number" then return width end
    end
    return #tostring(text or "") * (size * 0.55)
end

local function wrap_text(text, max_width, size)
    local lines = {}
    local line = ""
    for word in tostring(text or ""):gmatch("%S+") do
        local candidate = line == "" and word or (line .. " " .. word)
        if line ~= "" and text_width(candidate, size) > max_width then
            lines[#lines + 1] = line
            line = word
        else
            line = candidate
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    if #lines == 0 then lines[1] = "" end
    return lines
end

layout_entry = function(entry)
    entry.lines = wrap_text(
        entry.text,
        BUBBLE_W - BUBBLE_PAD * 2,
        BUBBLE_FONT
    )
    entry.bubble_w = BUBBLE_W
    entry.bubble_h = BUBBLE_HEADER_H + BUBBLE_PAD
        + #entry.lines * BUBBLE_LINE_H
end

local function draw_bubble(x, y, character_w, character_h, entry, alpha, sw, sh, character)
    if not draw or not draw.rect_filled or alpha <= 0.01 then return end
    if not entry.lines then layout_entry(entry) end
    local bubble_w = entry.bubble_w
    local bubble_h = entry.bubble_h

    local mouth_x = x + character_w * (character.mouth_x or 0.56)
    local mouth_y = y + character_h * (character.mouth_y or 0.30)

    -- Keep the panel entirely outside April's body; only the tail reaches her.
    local bx = x + character_w + 18
    local by = mouth_y - BUBBLE_HEADER_H
    local tail_right = false
    if bx + bubble_w > sw - 8 then
        bx = x - bubble_w - 18
        tail_right = true
    end
    bx = clamp(bx, 8, math.max(8, sw - bubble_w - 8))
    by = clamp(by, 8, math.max(8, (sh or sw) - bubble_h - 8))

    -- Panel stays see-through by default; text stays stronger for readability.
    local fill_a = clamp(alpha * 0.55, 0, 0.55)
    local text_a = clamp(alpha * 0.92, 0, 0.92)
    local accent = overlay_theme.accent()
    local panel = { 0.035, 0.032, 0.045, fill_a }
    local accent_col = {
        accent[1] or 0.8, accent[2] or 0.3, accent[3] or 1, text_a,
    }

    draw.rect_filled(bx, by, bubble_w, bubble_h, panel, 8)
    draw.rect_filled(bx + 8, by, bubble_w - 16, 2, accent_col, 0)

    if draw.poly_filled then
        local tail_y = clamp(mouth_y, by + 9, by + bubble_h - 9)
        local tip_x = mouth_x + (tail_right and -2 or 2)
        local base_x = tail_right and (bx + bubble_w - 2) or (bx + 2)
        local tail = {
            { base_x, tail_y - 7 },
            { tip_x, mouth_y },
            { base_x, tail_y + 7 },
        }
        draw.poly_filled(tail, panel)
    end

    local title = string.upper(tostring(character and character.name or "April"))
    draw_util.text(bx + BUBBLE_PAD, by + 7, title, accent_col, 11)
    for i = 1, #entry.lines do
        local tx = bx + BUBBLE_PAD
        local ty = by + BUBBLE_HEADER_H + (i - 1) * BUBBLE_LINE_H
        draw_util.text(tx, ty, entry.lines[i], { 1, 1, 1, text_a }, BUBBLE_FONT)
    end
end

function M.install()
    if installed then return end
    installed = true
    session_key = session_id()
    pcall(data.load_remote)
    for _, character in ipairs(data.characters) do
        local seen = {}
        for expression, file in pairs(character.expressions or {}) do
            if not seen[file] then
                seen[file] = true
                image_cache.preload(
                    "anime_baddie:" .. character.id .. ":" .. tostring(file),
                    character.urls(expression)
                )
            end
        end
    end
end

function M.register_menu()
    M.install()
    local G = menu_util.G
    local T = menu_util.group(G.CONFIG)
    menu.add_checkbox(T, G.CONFIG, P, "Anime Baddie", false)
    menu.add_combo(T, G.CONFIG, CHARACTER_ID, "Character", data.character_labels, 0, menu_util.parent(P))
    menu.add_combo(T, G.CONFIG, PERSONALITY_ID, "Personality", PERSONALITIES, 0, menu_util.parent(P))
    menu.add_multicombo(T, G.CONFIG, EVENTS_ID, "React To", EVENT_LABELS,
        { true, true, true, true, true, true, true, true }, menu_util.parent(P))
    menu.add_slider_int(T, G.CONFIG, SCALE_ID, "Scale", 60, 150, 100, menu_util.parent(P))
    menu.add_slider_int(T, G.CONFIG, OPACITY_ID, "Opacity", 30, 100, 100, menu_util.parent(P))
    menu.add_slider_int(T, G.CONFIG, DURATION_ID, "Bubble Duration", 2, 10, 5, menu_util.parent(P))
    menu.add_slider_int(T, G.CONFIG, COOLDOWN_ID, "Chatter Cooldown", 2, 30, 8, menu_util.parent(P))
    menu.add_checkbox(T, G.CONFIG, STAY_ID, "Stay Visible", true, menu_util.parent(P))
    menu.add_slider_int(T, G.CONFIG, X_ID, "Anime X", -5000, 5000, 16)
    menu.add_slider_int(T, G.CONFIG, Y_ID, "Anime Y", -5000, 5000, -1)
    menu.add_button(T, G.CONFIG, PREVIEW_ID, "Preview Line", function()
        emit("greeting", true)
    end)
    menu.add_button(T, G.CONFIG, RESET_ID, "Reset Position", function()
        reset_pending = true
    end)
    menu_util.bind_master(P, {
        CHARACTER_ID, PERSONALITY_ID, EVENTS_ID, SCALE_ID, OPACITY_ID,
        DURATION_ID, COOLDOWN_ID, STAY_ID, PREVIEW_ID, RESET_ID,
    })
    settings.on_change(P, function(enabled)
        if enabled then
            seeded = false
            emit("greeting", true)
        else
            current = nil
            queued = nil
        end
    end)
end

function M.update(dt)
    local current_session = session_id()
    if current_session ~= session_key then
        session_key = current_session
        reset_runtime()
    end

    local enabled = settings.bool(P, false)
    if enabled and not was_enabled then
        seeded = false
        emit("greeting", true)
    elseif not enabled and was_enabled then
        current = nil
        queued = nil
    end
    was_enabled = enabled

    local target = enabled and 1 or 0
    local speed = settings.bool("april_ui_reduce_motion", false) and 1000 or 10
    local frame_dt = clamp(tonumber(dt) or 0.016, 0.0001, 0.1)
    visibility = visibility + (target - visibility) * (1 - math.exp(-speed * frame_dt))

    if not enabled then return end

    local state = local_state()
    if state then detect_edges(state) end

    local now = now_ms()
    if current and now >= current.expires then current = nil end
    if not current and queued then
        local cooldown = clamp(settings.num(COOLDOWN_ID, 8), 2, 30) * 1000
        if now - last_emit_ms >= cooldown then
            local next_entry = queued
            queued = nil
            activate(next_entry, now)
        end
    end
end

function M.draw()
    if visibility <= 0.01 or not draw or not draw.image then return end
    local character = active_character()
    local scale = clamp(settings.num(SCALE_ID, 100), 60, 150) / 100
    local opacity = clamp(settings.num(OPACITY_ID, 100), 30, 100) / 100
    local sw, sh = draw_util.screen_size()
    local character_h = math.floor(330 * scale)
    local character_w = math.floor(character_h * character.aspect)
    local default_y = sh - character_h

    if reset_pending then
        persist_num(X_ID, 16)
        persist_num(Y_ID, default_y)
        reset_pending = false
    end

    -- Y default -1 is a "flush to bottom" sentinel. Resolve it before drag
    -- hit-testing or the grab box sits at the top while she draws at the bottom.
    local stored_y = settings.num(Y_ID, -1)
    if stored_y < 0 then
        persist_num(Y_ID, default_y)
    end

    local x, y = panel_drag.update(
        "anime_baddie", X_ID, Y_ID,
        character_w, character_h, sw, sh,
        16, default_y, true
    )
    if y < 0 then
        y = default_y
        persist_num(Y_ID, y)
    end
    x, y = panel_drag.clamp(x, y, character_w, character_h, sw, sh, X_ID, Y_ID)

    local now = now_ms()
    local expression = current and current.expression or "neutral"
    local sprite = character.sprite_file and character.sprite_file(expression)
        or (expression .. ".png")
    local key = "anime_baddie:" .. character.id .. ":" .. tostring(sprite):gsub("%.png$", "")
    image_cache.ensure(key, character.urls(expression))

    local pop = 1
    if current and not settings.bool("april_ui_reduce_motion", false) then
        pop = ease_out_back((now - current.started) / 420)
    end
    local draw_y = y + (1 - pop) * 44
    local alpha = opacity * visibility
    local stay_visible = settings.bool(STAY_ID, true)
    if not current and not stay_visible then alpha = 0 end

    if alpha > 0.01 then
        image_cache.draw_fit(key, x, draw_y, character_w, character_h, { 1, 1, 1, alpha })
    end

    if current then
        local bubble_alpha = alpha
        local remaining = current.expires - now
        if remaining < 350 then bubble_alpha = bubble_alpha * clamp(remaining / 350, 0, 1) end
        draw_bubble(x, draw_y, character_w, character_h, current, bubble_alpha, sw, sh, character)
    end
end

return M
