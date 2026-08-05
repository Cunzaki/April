-- Draggable, read-only anime announcer overlay.
-- It only reads April's local entity cache/attributes and draws HTTPS PNGs.
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local cache = April.require("core.cache")
local ep = April.require("core.entity_props")
local env = April.require("core.env")
local player_state = April.require("game.player_state")
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
local EVENT_LABELS = { "Death / Respawn", "Downed / Revived", "Low Health", "Safe Zone" }
local EVENT_SLOT = {
    death = 1,
    respawn = 1,
    downed = 2,
    revived = 2,
    low_health = 3,
    recovered = 3,
    safe_enter = 4,
    safe_leave = 4,
}
local PRIORITY = {
    greeting = 100,
    death = 100,
    downed = 90,
    respawn = 80,
    low_health = 70,
    revived = 65,
    recovered = 55,
    safe_leave = 40,
    safe_enter = 35,
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
    local event_pool = character.dialogue and character.dialogue[event_name]
    if not event_pool then return nil end
    local tone = personality_name()
    local pool = event_pool[tone] or event_pool.roasty or event_pool.supportive
    if type(pool) ~= "table" or #pool == 0 then return nil end

    local repeat_key = character.id .. ":" .. event_name .. ":" .. tone
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
    entry.started = now
    entry.expires = now + duration
    current = entry
    last_emit_ms = now
    local key = "anime_baddie:" .. entry.character.id .. ":" .. entry.expression
    image_cache.preload(key, entry.character.urls(entry.expression))
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
    local safe = as_bool(player_state.player_attr(local_player, "SafeZone"))
        or as_bool(player_state.player_attr(local_player, "InSafeZone"))

    return {
        alive = alive,
        hp = hp,
        max_hp = max_hp,
        ratio = ratio,
        low = alive and ratio ~= nil and ratio <= 0.30,
        downed = alive and downed,
        safe = safe,
    }
end

local function seed_state(state)
    snapshot = state
    seeded = true
    if state.alive then ever_alive = true end
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

local function draw_bubble(x, y, character_w, character_h, text, alpha, sw, sh, character)
    if not draw or not draw.rect_filled or alpha <= 0.01 then return end
    local font = 14
    local bubble_w = 286
    local pad = 14
    local lines = wrap_text(text, bubble_w - pad * 2, font)
    local line_h = 17
    local bubble_h = pad * 2 + #lines * line_h

    local mouth_x = x + character_w * (character.mouth_x or 0.56)
    local mouth_y = y + character_h * (character.mouth_y or 0.21)

    local bx = mouth_x + 52
    -- Put the bubble beside her face, with the tail entering at mouth height.
    local by = mouth_y - bubble_h * 0.45
    local tail_right = false
    if bx + bubble_w > sw - 8 then
        bx = mouth_x - bubble_w - 28
        tail_right = true
    end
    bx = clamp(bx, 8, math.max(8, sw - bubble_w - 8))
    by = clamp(by, 8, math.max(8, (sh or sw) - bubble_h - 8))

    local accent = overlay_theme.accent()
    draw.rect_filled(bx, by, bubble_w, bubble_h, { 0.055, 0.06, 0.075, 0.94 * alpha }, 9)
    if draw.rect then
        draw.rect(bx, by, bubble_w, bubble_h,
            { accent[1] or 0.8, accent[2] or 0.3, accent[3] or 1, 0.72 * alpha }, 9, 1)
    end

    if draw.poly_filled then
        local tail_y = clamp(mouth_y, by + 9, by + bubble_h - 9)
        local tail
        if tail_right then
            tail = {
                { bx + bubble_w - 3, tail_y - 7 },
                { mouth_x - 2, mouth_y },
                { bx + bubble_w - 3, tail_y + 7 },
            }
        else
            tail = {
                { bx + 3, tail_y - 7 },
                { mouth_x + 2, mouth_y },
                { bx + 3, tail_y + 7 },
            }
        end
        draw.poly_filled(tail, { 0.055, 0.06, 0.075, 0.94 * alpha })
    end

    for i = 1, #lines do
        local tx = bx + pad
        local ty = by + pad + (i - 1) * line_h
        -- Explicit shadow keeps dialogue readable over light game scenes.
        draw_util.text(tx + 1, ty + 1, lines[i], { 0, 0, 0, alpha * 0.75 }, font)
        draw_util.text(tx, ty, lines[i], { 1, 1, 1, alpha }, font)
    end
end

function M.install()
    if installed then return end
    installed = true
    session_key = session_id()
    pcall(data.load_remote)
    for _, character in ipairs(data.characters) do
        local expressions = {}
        for expression in pairs(character.expressions) do
            expressions[#expressions + 1] = expression
        end
        for _, expression in ipairs(expressions) do
            image_cache.preload(
                "anime_baddie:" .. character.id .. ":" .. expression,
                character.urls(expression)
            )
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
        { true, true, true, true }, menu_util.parent(P))
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
    overlay_theme.sync()

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

    local x, y = panel_drag.update(
        "anime_baddie", X_ID, Y_ID,
        character_w, character_h, sw, sh,
        16, default_y, true
    )
    if y < 0 then y = default_y end
    x, y = panel_drag.clamp(x, y, character_w, character_h, sw, sh, X_ID, Y_ID)

    local now = now_ms()
    local expression = current and current.expression or "neutral"
    local key = "anime_baddie:" .. character.id .. ":" .. expression
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
        draw_bubble(x, draw_y, character_w, character_h, current.text, bubble_alpha, sw, sh, character)
    end
end

return M
