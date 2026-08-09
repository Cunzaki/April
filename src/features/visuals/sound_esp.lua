--[[
  Audio Radar (Sound ESP) — full sound classification + volume / range readout.
  Adapted from n0v3l3w/external-sound-esp. Credit: @n0v3l3w / UI @n0v313w.
  Theo offsets are loaded at script boot (core.rbx_offsets), not on toggle.
]]

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local math_util = April.require("core.math_util")
local cache = April.require("core.cache")
local ep = April.require("core.entity_props")
local rbx_offsets = April.require("core.rbx_offsets")
local player_state = April.require("game.player_state")

local M = {}
local draw_cells = {}
local touched_cells = {}
local gather_seen = {}

local P = "april_sound_esp"
local ID_FADE_IN = P .. "_fade_in"
local ID_FADE_OUT = P .. "_fade_out"
local ID_SIZE = P .. "_size"
local ID_COLOR = P .. "_color"
local ID_MAX_DIST = P .. "_max_dist"
local ID_UNDER = P .. "_under"
local ID_SCREEN_Y = P .. "_screen_y"
local ID_CHIP = P .. "_chip"
local ID_DETAIL = P .. "_detail"
local ID_CAT_COLOR = P .. "_cat_color"
local ID_FILTERS = P .. "_filters"
local ID_MAX_PER = P .. "_max_per"

local PLAYER_FILTERS = "april_player_esp_filters"
local F_TEAM, F_SAFEZONE, F_SKIP_DOWNED = 1, 2, 3
local PLAYER_RANGE = "april_player_range"

local CF_FOOT, CF_COMBAT, CF_UTIL, CF_WORLD, CF_OTHER = 1, 2, 3, 4, 5

local SCAN_MS = 110
local HRP_CACHE_MS = 1000
local MAX_SOUNDS_PER_PLAYER = 24
local MAX_GATHER_PER_SCAN = 4
local CLASSIFY_MAX = 1024
local VOL_DEADBAND = 0.025
local SPD_DEADBAND = 0.02
local DEFAULT_MAX_DIST = 450
local DEFAULT_UNDER = 2.8
local DEFAULT_SCREEN_Y = 2
local DEFAULT_SIZE = 10
local DEFAULT_MAX_PER = 4

local CAT_PRIORITY = {
    GUN = 100, EXPL = 95, HIT = 90, RELOAD = 85, HEAL = 80, MELEE = 75,
    INTER = 55, VEH = 45, VOICE = 30, FOOT = 20, OTHER = 10,
}

local CAT = {
    FOOT = {
        key = "FOOT", filter = CF_FOOT,
        color = { 0.72, 0.86, 1.0, 0.95 },
        rules = { "foot", "step", "run", "walk", "land", "jump", "sprint", "crawl" },
    },
    GUN = {
        key = "GUN", filter = CF_COMBAT,
        color = { 1.0, 0.45, 0.38, 0.95 },
        rules = { "gun", "fire", "shot", "shoot", "bullet", "rifle", "pistol", "smg", "shotgun", "sniper", "ak", "m4", "ar15" },
    },
    RELOAD = {
        key = "RELOAD", filter = CF_COMBAT,
        color = { 1.0, 0.72, 0.35, 0.95 },
        rules = { "reload", "mag", "chamber", "bolt" },
    },
    HIT = {
        key = "HIT", filter = CF_COMBAT,
        color = { 1.0, 0.28, 0.28, 0.95 },
        rules = { "hit", "impact", "flesh", "hurt", "damage", "headshot" },
    },
    EXPL = {
        key = "EXPL", filter = CF_COMBAT,
        color = { 1.0, 0.55, 0.15, 0.95 },
        rules = { "explod", "grenade", "boom", "rpg", "rocket", "c4" },
    },
    HEAL = {
        key = "HEAL", filter = CF_UTIL,
        color = { 0.45, 1.0, 0.62, 0.95 },
        rules = { "heal", "bandage", "med", "syringe", "stim", "revive", "cpr" },
    },
    MELEE = {
        key = "MELEE", filter = CF_COMBAT,
        color = { 0.95, 0.8, 0.4, 0.95 },
        rules = { "melee", "swing", "slash", "punch", "knife", "axe" },
    },
    VEH = {
        key = "VEH", filter = CF_WORLD,
        color = { 0.55, 0.75, 1.0, 0.95 },
        rules = { "car", "engine", "vehicle", "heli", "bike", "tire", "horn" },
    },
    INTER = {
        key = "INTER", filter = CF_UTIL,
        color = { 0.85, 0.78, 1.0, 0.95 },
        rules = { "door", "open", "close", "loot", "pickup", "item", "craft", "build", "place" },
    },
    VOICE = {
        key = "VOICE", filter = CF_OTHER,
        color = { 0.95, 0.7, 0.95, 0.95 },
        rules = { "voice", "talk", "radio", "mic", "chat" },
    },
    OTHER = {
        key = "OTHER", filter = CF_OTHER,
        color = { 0.78, 0.9, 1.0, 0.92 },
        rules = {},
    },
}

local CAT_ORDER = { "FOOT", "GUN", "RELOAD", "HIT", "EXPL", "HEAL", "MELEE", "VEH", "INTER", "VOICE", "OTHER" }

local indicators = {}
local sound_prev = {}
local player_cache = {}
local classify_cache = {}
local classify_n = 0
local last_scan_ms = 0
local mem_read_fn = nil
local cached_off = nil
local gather_budget = 0

local function tick_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, v = pcall(fn)
    return (ok and tonumber(v)) or 0
end

local function ensure_mem()
    if mem_read_fn then return mem_read_fn end
    if not memory then return nil end
    mem_read_fn = memory.read or memory.Read
    if type(mem_read_fn) ~= "function" then
        mem_read_fn = nil
    end
    return mem_read_fn
end

local function mem_bool(addr, off)
    local fn = ensure_mem()
    if not fn or not addr or not off then return false end
    local ok, value = pcall(fn, addr + off, "bool")
    return ok and value == true
end

local function mem_float(addr, off)
    local fn = ensure_mem()
    if not fn or not addr or not off then return nil end
    local ok, value = pcall(fn, addr + off, "float")
    if ok then return tonumber(value) end
    return nil
end

local function sound_offs()
    if cached_off then return cached_off end
    cached_off = {
        is_playing = rbx_offsets.sound_is_playing(),
        volume = rbx_offsets.sound("Volume"),
        speed = rbx_offsets.sound("PlaybackSpeed"),
        looped = rbx_offsets.sound("Looped"),
        rolloff = rbx_offsets.sound("RollOffMaxDistance"),
        rolloff_min = rbx_offsets.sound("RollOffMinDistance"),
        sound_id = rbx_offsets.sound("SoundId"),
    }
    return cached_off
end

local function camera_pos()
    if not camera then return nil end
    local fn = camera.get_position or camera.GetPosition
    if type(fn) ~= "function" then return nil end
    local ok, pos = pcall(fn)
    if not ok or not pos then return nil end
    local x, y, z = esp_util.vec3_pos(pos)
    if not x then return nil end
    return x, y, z
end

local function player_alive(p)
    if not p or p.IsAlive == false then return false end
    local hp = ep.health(p)
    if hp ~= nil and hp <= 0 then return false end
    return true
end

local function passes_player_esp_filters(p)
    if settings.multi(PLAYER_FILTERS, F_TEAM, true) then
        if not player_state.passes_team_check(p) then
            return false
        end
    end

    local need_snap = settings.multi(PLAYER_FILTERS, F_SAFEZONE, false)
        or settings.multi(PLAYER_FILTERS, F_SKIP_DOWNED, false)
    if need_snap then
        local snap = player_state.esp_state(p)
        if settings.multi(PLAYER_FILTERS, F_SKIP_DOWNED, false) and snap and snap.downed then
            return false
        end
        if settings.multi(PLAYER_FILTERS, F_SAFEZONE, false) and snap and snap.safezone then
            return false
        end
    end
    return true
end

local function player_key(p)
    local uid = ep.user_id(p)
    if uid and uid ~= 0 then return uid end
    local addr = p.Address or p.address
    if addr then return tostring(addr) end
    return tostring(p)
end

local function pretty_name(raw)
    raw = tostring(raw or "Sound")
    if raw == "" then return "Sound" end
    raw = raw:gsub("^rbxassetid://%d+", "Sound")
    raw = raw:gsub("%.ogg$", ""):gsub("%.mp3$", ""):gsub("%.wav$", "")
    raw = raw:gsub("_", " ")
    raw = raw:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if #raw > 22 then
        raw = raw:sub(1, 20) .. ".."
    end
    return raw
end

local function classify_blob(blob)
    local hit = classify_cache[blob]
    if hit then return hit end
    if classify_n >= CLASSIFY_MAX then
        classify_cache = {}
        classify_n = 0
    end
    for i = 1, #CAT_ORDER do
        local key = CAT_ORDER[i]
        if key ~= "OTHER" then
            local def = CAT[key]
            local rules = def.rules
            for ri = 1, #rules do
                if blob:find(rules[ri], 1, true) then
                    classify_cache[blob] = def
                    classify_n = classify_n + 1
                    return def
                end
            end
        end
    end
    classify_cache[blob] = CAT.OTHER
    classify_n = classify_n + 1
    return CAT.OTHER
end

local function classify_sound(name, sound_id)
    local n = tostring(name or "")
    local by_name = classify_blob(n:lower())
    if by_name.key ~= "OTHER" or not sound_id or sound_id == "" then
        return by_name
    end
    return classify_blob((n .. " " .. tostring(sound_id)):lower())
end

local function filter_allows(cat_def)
    local slot = cat_def and cat_def.filter or CF_OTHER
    return settings.multi(ID_FILTERS, slot, true)
end

local function under_studs()
    return math.max(0, settings.num(ID_UNDER, DEFAULT_UNDER))
end

local function anchor_world(px, py, pz)
    return px, py - under_studs(), pz
end

local function read_sound_id(child, addr, off)
    if child then
        local sid = child.SoundId or child.sound_id
        if type(sid) == "string" and sid ~= "" then return sid end
    end
    if memory and memory.ReadString and addr and off.sound_id then
        local ok, ptr = pcall(function()
            return (memory.Read or memory.read)(addr + off.sound_id, "ptr")
        end)
        if ok and ptr and ptr ~= 0 then
            local ok2, s = pcall(memory.ReadString, ptr, 96)
            if ok2 and type(s) == "string" and s ~= "" then return s end
        end
    end
    return nil
end

local function gather_sounds(character, hrp, prev_entry)
    local sounds = {}
    local seen = gather_seen
    for addr in pairs(seen) do seen[addr] = nil end
    local deep_done = prev_entry and prev_entry.deep_done == true
    local char_addr = character and tonumber(character.Address or character.address) or nil

    local function push(child)
        if not child then return end
        local class_name = child.ClassName or child.class_name
        if class_name ~= "Sound" then return end
        if #sounds >= MAX_SOUNDS_PER_PLAYER then return end
        local addr = tonumber(child.Address or child.address)
        if not addr or addr <= 0 or seen[addr] then return end
        seen[addr] = true
        sounds[#sounds + 1] = {
            addr = addr,
            name = pretty_name(child.Name or child.name),
            child = child,
        }
    end

    local function push_children(inst)
        if not inst or not inst.GetChildren then return end
        local ok, kids = pcall(function() return inst:GetChildren() end)
        if not ok or type(kids) ~= "table" then return end
        for i = 1, #kids do
            push(kids[i])
            if #sounds >= MAX_SOUNDS_PER_PLAYER then return end
        end
    end

    -- HRP-local sounds cover footsteps / gunfire / most combat cues.
    push_children(hrp)

    -- Held tool sounds before any full-character walk.
    if #sounds == 0 and character and character.FindFirstChildOfClass then
        local ok_tool, tool = pcall(function()
            return character:FindFirstChildOfClass("Tool")
        end)
        if ok_tool and tool then
            push_children(tool)
            local handle = tool.FindFirstChild and tool:FindFirstChild("Handle")
            if handle then push_children(handle) end
        end
    end

    -- Deep-scan at most once per character instance; reuse until respawn.
    if #sounds == 0 then
        if prev_entry and prev_entry.char_addr == char_addr and prev_entry.deep_done and prev_entry.sounds then
            return prev_entry.sounds, char_addr, true
        end
        if character and character.GetDescendantsOfClass then
            local ok, list = pcall(function()
                return character:GetDescendantsOfClass("Sound")
            end)
            if ok and type(list) == "table" then
                local n = math.min(#list, MAX_SOUNDS_PER_PLAYER)
                for i = 1, n do push(list[i]) end
            end
            deep_done = true
        end
    end

    return sounds, char_addr, deep_done
end

local function refresh_player_sounds(p, now)
    local key = player_key(p)
    local entry = player_cache[key]
    if entry and entry.sounds and (now - (entry.t or 0)) < HRP_CACHE_MS then
        local px, py, pz = esp_util.vec3_pos(p.Position)
        if px then
            entry.px, entry.py, entry.pz = px, py, pz
        end
        return entry
    end

    -- Reuse the previous sound list when gather budget is spent (position only).
    if entry and entry.sounds and gather_budget <= 0 then
        local px, py, pz = esp_util.vec3_pos(p.Position)
        if px then
            entry.px, entry.py, entry.pz = px, py, pz
        end
        return entry
    end

    local character = p.Character
    if not character then
        player_cache[key] = nil
        return nil
    end

    local ok_hrp, hrp = pcall(function()
        return character:FindFirstChild("HumanoidRootPart")
    end)
    if not ok_hrp or not hrp then
        player_cache[key] = nil
        return nil
    end

    gather_budget = gather_budget - 1
    local px, py, pz = esp_util.vec3_pos(p.Position or hrp.Position)
    local sounds, char_addr, deep_done = gather_sounds(character, hrp, entry)
    entry = {
        hrp = hrp,
        sounds = sounds,
        t = now,
        px = px, py = py, pz = pz,
        char_addr = char_addr,
        deep_done = deep_done == true,
    }
    player_cache[key] = entry
    return entry
end

local function read_sound_state(child, addr, off, want_sid)
    local vol = tonumber(child and child.Volume)
    if vol == nil then vol = mem_float(addr, off.volume) or 0 end

    local spd = tonumber(child and child.PlaybackSpeed)
    if spd == nil then spd = mem_float(addr, off.speed) or 0 end

    local looped
    if child and child.Looped ~= nil then
        looped = child.Looped == true
    else
        looped = mem_bool(addr, off.looped)
    end

    local rolloff = tonumber(child and child.RollOffMaxDistance)
    if rolloff == nil then rolloff = mem_float(addr, off.rolloff) or 0 end

    local sid = nil
    if want_sid then
        sid = read_sound_id(child, addr, off)
    end
    return vol, spd, looped, rolloff, sid
end

local function format_label(cat_key, name, vol, dist, detail)
    if detail then
        local v = math.floor((tonumber(vol) or 0) * 100 + 0.5)
        local d = math.floor((tonumber(dist) or 0) + 0.5)
        return string.format("%s · %dm · %d%%", cat_key, d, v)
    end
    return cat_key
end

local function bump_indicator(addr, payload)
    local ax, ay, az = anchor_world(payload.px, payload.py, payload.pz)
    local ind = indicators[addr]
    if not ind then
        indicators[addr] = {
            name = payload.name,
            cat = payload.cat,
            text = payload.text,
            color = payload.color,
            pkey = payload.pkey,
            pri = payload.pri or 0,
            alpha = 0,
            state = "fade_in",
            timer = 0,
            x = ax, y = ay, z = az,
            seen = true,
        }
        return
    end
    ind.x, ind.y, ind.z = ax, ay, az
    ind.name = payload.name or ind.name
    ind.cat = payload.cat or ind.cat
    ind.text = payload.text or ind.text
    ind.color = payload.color or ind.color
    ind.pkey = payload.pkey or ind.pkey
    ind.pri = payload.pri or ind.pri or 0
    ind.seen = true
    if ind.state == "fade_out" then
        ind.state = "fade_in"
        ind.timer = 0
    end
end

-- Keep only the top N active labels per player (by category priority).
local function enforce_max_per_player(max_per)
    max_per = math.floor(tonumber(max_per) or DEFAULT_MAX_PER)
    if max_per < 1 then max_per = 1 end
    if max_per > 10 then max_per = 10 end

    local by_player = {}
    for addr, ind in pairs(indicators) do
        if ind and ind.state ~= "fade_out" and ind.pkey ~= nil then
            local list = by_player[ind.pkey]
            if not list then
                list = {}
                by_player[ind.pkey] = list
            end
            list[#list + 1] = {
                addr = addr,
                pri = tonumber(ind.pri) or 0,
                age = tonumber(ind.timer) or 0,
            }
        end
    end

    for _, list in pairs(by_player) do
        if #list > max_per then
            table.sort(list, function(a, b)
                if a.pri ~= b.pri then return a.pri > b.pri end
                return a.age < b.age
            end)
            for i = max_per + 1, #list do
                local ind = indicators[list[i].addr]
                if ind then
                    ind.state = "fade_out"
                    ind.timer = 0
                    ind.seen = false
                end
            end
        end
    end
end

local function scan_sounds(now)
    local cam_x, cam_y, cam_z = camera_pos()
    if not cam_x then return end

    local off = sound_offs()
    if not ensure_mem() or not off.is_playing then return end

    local sound_range = math.max(50, settings.num(ID_MAX_DIST, DEFAULT_MAX_DIST))
    local player_range = math.max(50, settings.num(PLAYER_RANGE, 500))
    local max_dist = math.min(sound_range, player_range)
    local detail = settings.bool(ID_DETAIL, true)
    local use_cat_color = settings.bool(ID_CAT_COLOR, true)
    local max_per = settings.num(ID_MAX_PER, DEFAULT_MAX_PER)
    gather_budget = MAX_GATHER_PER_SCAN

    for _, prev in pairs(sound_prev) do
        prev.seen = false
    end
    for _, ind in pairs(indicators) do
        ind.seen = false
    end

    local players = cache.players or {}
    local live_keys = {}

    for i = 1, #players do
        local p = players[i]
        if p and p.IsLocal ~= true and player_alive(p) and passes_player_esp_filters(p) then
            local px0, py0, pz0 = esp_util.vec3_pos(p.Position)
            if px0 then
                local dist = math_util.distance3(px0 - cam_x, py0 - cam_y, pz0 - cam_z)
                if dist <= max_dist then
                    local key = player_key(p)
                    live_keys[key] = true
                    local entry = refresh_player_sounds(p, now)
                    if entry and entry.sounds then
                        local px = entry.px or px0
                        local py = entry.py or py0
                        local pz = entry.pz or pz0
                        local sounds = entry.sounds
                        for si = 1, #sounds do
                            local s = sounds[si]
                            local addr = s.addr
                            local child = s.child
                            local cat = classify_sound(s.name, nil)
                            if not filter_allows(cat) then
                                goto next_sound
                            end
                            local need_sid = cat.key == "OTHER"
                            local vol, spd, looped, rolloff, sid = read_sound_state(child, addr, off, need_sid)
                            if need_sid and sid then
                                cat = classify_sound(s.name, sid)
                                if not filter_allows(cat) then
                                    goto next_sound
                                end
                            end
                            local is_playing = mem_bool(addr, off.is_playing)
                            local is_audible = rolloff <= 0 or dist <= rolloff

                            local prev = sound_prev[addr]
                            if not prev then
                                sound_prev[addr] = {
                                    vol = vol, spd = spd, looped = looped,
                                    playing = is_playing, audible = is_audible,
                                    seen = true,
                                }
                            else
                                prev.seen = true
                                local started = false
                                local stopped = false

                                if vol > (prev.vol + VOL_DEADBAND) then started = true end
                                if vol < (prev.vol - VOL_DEADBAND) then stopped = true end
                                if spd > (prev.spd + SPD_DEADBAND) then started = true end
                                if spd < (prev.spd - SPD_DEADBAND) then stopped = true end
                                if looped and not prev.looped then started = true end
                                if (not looped) and prev.looped then stopped = true end
                                if is_playing and not prev.playing then started = true end
                                if (not is_playing) and prev.playing then stopped = true end

                                local emitting = vol > 0 and spd > 0 and is_playing
                                if emitting and is_audible and not prev.audible then
                                    started = true
                                end
                                if (not is_audible) and prev.audible then
                                    stopped = true
                                end

                                prev.vol, prev.spd, prev.looped = vol, spd, looped
                                prev.playing, prev.audible = is_playing, is_audible

                                local text = format_label(cat.key, s.name, vol, dist, detail)
                                local col = use_cat_color and cat.color or nil
                                local payload = {
                                    name = s.name,
                                    cat = cat.key,
                                    text = text,
                                    color = col,
                                    px = px, py = py, pz = pz,
                                    pkey = key,
                                    pri = CAT_PRIORITY[cat.key] or 10,
                                }

                                if started and not stopped and is_audible then
                                    bump_indicator(addr, payload)
                                elseif stopped then
                                    local ind = indicators[addr]
                                    if ind and ind.state ~= "fade_out" then
                                        ind.state = "fade_out"
                                        ind.timer = 0
                                    end
                                else
                                    local ind = indicators[addr]
                                    if ind and ind.state ~= "fade_out" and is_audible then
                                        local ax, ay, az = anchor_world(px, py, pz)
                                        ind.x, ind.y, ind.z = ax, ay, az
                                        ind.text = text
                                        ind.cat = cat.key
                                        ind.color = col or ind.color
                                        ind.pkey = key
                                        ind.pri = CAT_PRIORITY[cat.key] or ind.pri or 10
                                        ind.seen = true
                                    elseif emitting and is_audible and not indicators[addr] then
                                        bump_indicator(addr, payload)
                                    end
                                end
                            end
                            ::next_sound::
                        end
                    end
                end
            end
        end
    end

    enforce_max_per_player(max_per)

    for key in pairs(player_cache) do
        if not live_keys[key] then
            player_cache[key] = nil
        end
    end
    for addr, prev in pairs(sound_prev) do
        if not prev.seen then
            sound_prev[addr] = nil
        end
    end
end

local function tick_indicators(dt)
    local fade_in = math.max(0.05, settings.num(ID_FADE_IN, 0.25))
    local fade_out = math.max(0.05, settings.num(ID_FADE_OUT, 5.0))

    for addr, ind in pairs(indicators) do
        if not ind.seen and ind.state ~= "fade_out" then
            ind.state = "fade_out"
            ind.timer = 0
        end

        ind.timer = (ind.timer or 0) + dt

        if ind.state == "fade_in" then
            ind.alpha = math.min(1, ind.timer / fade_in)
            if ind.alpha >= 1 then
                ind.state = "visible"
                ind.timer = 0
            end
        elseif ind.state == "visible" then
            ind.alpha = 1
        elseif ind.state == "fade_out" then
            ind.alpha = math.max(0, 1 - ind.timer / fade_out)
            if ind.alpha <= 0 then
                indicators[addr] = nil
            end
        end
    end
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu_util.section(T, G.VISUALS, "Audio Radar")
    menu.add_checkbox(T, G.VISUALS, P, "Sound ESP", false)
    menu.add_slider_float(T, G.VISUALS, ID_FADE_IN, "Sound Fade In", 0.05, 2.0, 0.25, "%.2f", root)
    menu.add_slider_float(T, G.VISUALS, ID_FADE_OUT, "Sound Fade Out", 0.5, 15.0, 5.0, "%.2f", root)
    menu.add_slider_int(T, G.VISUALS, ID_SIZE, "Sound Text Size", 8, 20, DEFAULT_SIZE, root)
    menu.add_slider_float(T, G.VISUALS, ID_UNDER, "Under Offset", 0, 6, DEFAULT_UNDER, "%.1f", root)
    menu.add_slider_int(T, G.VISUALS, ID_SCREEN_Y, "Screen Offset", -20, 40, DEFAULT_SCREEN_Y, root)
    menu.add_slider_int(T, G.VISUALS, ID_MAX_DIST, "Sound Range", 50, 2000, DEFAULT_MAX_DIST, root)
    menu.add_slider_int(T, G.VISUALS, ID_MAX_PER, "Max Per Player", 1, 10, DEFAULT_MAX_PER, root)
    menu.add_multicombo(T, G.VISUALS, ID_FILTERS, "Radar Filters", {
        "Footsteps", "Combat", "Utility", "World", "Other",
    }, { true, true, true, true, true }, root)
    menu.add_checkbox(T, G.VISUALS, ID_DETAIL, "Radar Detail", true, root)
    menu.add_checkbox(T, G.VISUALS, ID_CAT_COLOR, "Category Colors", true, root)
    menu.add_checkbox(T, G.VISUALS, ID_CHIP, "Sound Chip", false, root)
    menu.add_colorpicker(T, G.VISUALS, ID_COLOR, "Sound Color", { 0.78, 0.9, 1.0, 0.92 }, root)
    menu_util.bind_children(P, {
        ID_FADE_IN, ID_FADE_OUT, ID_SIZE, ID_UNDER, ID_SCREEN_Y, ID_MAX_DIST, ID_MAX_PER,
        ID_FILTERS, ID_DETAIL, ID_CAT_COLOR, ID_CHIP, ID_COLOR,
    })
end

function M.update(dt)
    if not settings.enabled(P) then
        if next(indicators) then indicators = {} end
        if next(sound_prev) then sound_prev = {} end
        if next(player_cache) then player_cache = {} end
        if next(classify_cache) then
            classify_cache = {}
            classify_n = 0
        end
        return
    end

    dt = tonumber(dt) or 0
    if dt <= 0 then dt = 1 / 60 end

    local now = tick_ms()
    if (now - last_scan_ms) >= SCAN_MS then
        last_scan_ms = now
        scan_sounds(now)
    else
        for _, ind in pairs(indicators) do
            ind.seen = ind.state ~= "fade_out"
        end
    end

    tick_indicators(dt)
end

local function draw_label(sx, sy, text, col, size, chip)
    local size_fn = draw.get_text_size or draw.GetTextSize
    local tw, th = 0, size
    if size_fn then
        local ok, w, h = pcall(size_fn, text, size)
        if ok then
            tw = tonumber(w) or 0
            th = tonumber(h) or size
        end
    end

    local a = col[4] or 1
    if chip and draw.rect_filled then
        local pad_x, pad_y = 4, 1
        local bw = tw + pad_x * 2
        local bh = th + pad_y * 2
        local bx = sx - bw * 0.5
        local by = sy
        draw.rect_filled(bx, by, bw, bh, { 0.04, 0.05, 0.07, a * 0.45 }, 3)
        draw_util.text(bx + pad_x + 1, by + pad_y + 1, text, { 0, 0, 0, a * 0.5 }, size)
        draw_util.text(bx + pad_x, by + pad_y, text, col, size)
        return
    end

    local tx = sx - tw * 0.5
    draw_util.text(tx + 1, sy + 1, text, { 0, 0, 0, a * 0.55 }, size)
    draw_util.text(tx, sy, text, col, size)
end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw then return end

    local size = math.floor(settings.num(ID_SIZE, DEFAULT_SIZE))
    local screen_y = math.floor(settings.num(ID_SCREEN_Y, DEFAULT_SCREEN_Y))
    local chip = settings.bool(ID_CHIP, false)
    local base = settings.color(ID_COLOR, { 0.78, 0.9, 1.0, 0.92 })
    local br, bg, bb, ba = base[1] or 0.78, base[2] or 0.9, base[3] or 1, base[4] or 0.92

    for i = 1, #touched_cells do
        draw_cells[touched_cells[i]] = nil
        touched_cells[i] = nil
    end
    for _, ind in pairs(indicators) do
        local a = (ind.alpha or 0) * ba
        if a > 0.02 and ind.x then
            local sx, sy, vis = esp_util.w2s(ind.x, ind.y, ind.z)
            if vis and esp_util.screen_point_ok(sx, sy, 64) then
                local key = math.floor(sx / 10) .. ":" .. math.floor(sy / 10)
                local slot = draw_cells[key] or 0
                if slot == 0 then touched_cells[#touched_cells + 1] = key end
                draw_cells[key] = slot + 1
                local y = sy + screen_y + slot * (size + 2)
                local source = ind.color
                local col = ind._draw_color
                if not col then
                    col = {}
                    ind._draw_color = col
                end
                if type(source) ~= "table" then
                    col[1], col[2], col[3], col[4] = br, bg, bb, a
                else
                    col[1], col[2], col[3], col[4] = source[1] or br, source[2] or bg, source[3] or bb, a
                end
                draw_label(sx, y, ind.text or ind.cat or ind.name or "Sound", col, size, chip)
            end
        end
    end
end

return M
