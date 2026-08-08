--[[
  Sound ESP — adapted from n0v3l3w/external-sound-esp (vector_sound_esp.lua).
  Credit: @n0v3l3w / UI credit @n0v313w under the toggle.
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

local P = "april_sound_esp"
local ID_FADE_IN = P .. "_fade_in"
local ID_FADE_OUT = P .. "_fade_out"
local ID_SIZE = P .. "_size"
local ID_COLOR = P .. "_color"
local ID_MAX_DIST = P .. "_max_dist"
local ID_UNDER = P .. "_under"
local ID_SCREEN_Y = P .. "_screen_y"
local ID_CHIP = P .. "_chip"

-- Same multicombo as Player ESP → ESP Filters.
local PLAYER_FILTERS = "april_player_esp_filters"
local F_TEAM, F_SAFEZONE, F_SKIP_DOWNED = 1, 2, 3
local PLAYER_RANGE = "april_player_range"

local SCAN_MS = 70
local HRP_CACHE_MS = 450
local DEFAULT_MAX_DIST = 450
local DEFAULT_UNDER = 2.8
local DEFAULT_SCREEN_Y = 2
local DEFAULT_SIZE = 10

local indicators = {}
local sound_prev = {}
local player_cache = {}
local last_scan_ms = 0
local offsets_ready = false
local cached_off = nil
local mem_read_fn = nil

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

local function ensure_offsets()
    if cached_off then return cached_off end
    if not offsets_ready then
        offsets_ready = true
        pcall(rbx_offsets.fetch)
    end
    cached_off = {
        is_playing = rbx_offsets.sound_is_playing(),
        volume = rbx_offsets.sound("Volume"),
        speed = rbx_offsets.sound("PlaybackSpeed"),
        looped = rbx_offsets.sound("Looped"),
        rolloff = rbx_offsets.sound("RollOffMaxDistance"),
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

-- Honor Player ESP → ESP Filters (+ Player Range as a visual gate).
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

local function under_studs()
    return math.max(0, settings.num(ID_UNDER, DEFAULT_UNDER))
end

local function anchor_world(px, py, pz)
    return px, py - under_studs(), pz
end

local function refresh_player_sounds(p, now)
    local key = player_key(p)
    local entry = player_cache[key]
    if entry and (now - (entry.t or 0)) < HRP_CACHE_MS and entry.hrp then
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

    local sounds = {}
    local ok_kids, kids = pcall(function()
        return hrp:GetChildren()
    end)
    if ok_kids and type(kids) == "table" then
        for i = 1, #kids do
            local child = kids[i]
            if child and child.ClassName == "Sound" then
                local addr = tonumber(child.Address)
                if addr and addr > 0 then
                    sounds[#sounds + 1] = {
                        addr = addr,
                        name = pretty_name(child.Name),
                        child = child,
                    }
                end
            end
        end
    end

    local px, py, pz = esp_util.vec3_pos(p.Position or hrp.Position)
    entry = {
        hrp = hrp,
        sounds = sounds,
        t = now,
        px = px, py = py, pz = pz,
    }
    player_cache[key] = entry
    return entry
end

local function read_sound_state(child, addr, off)
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

    return vol, spd, looped, rolloff
end

local function bump_indicator(addr, name, px, py, pz)
    local ax, ay, az = anchor_world(px, py, pz)
    local ind = indicators[addr]
    if not ind then
        indicators[addr] = {
            name = name,
            alpha = 0,
            state = "fade_in",
            timer = 0,
            x = ax, y = ay, z = az,
            seen = true,
        }
        return
    end
    ind.x, ind.y, ind.z = ax, ay, az
    ind.name = name or ind.name
    ind.seen = true
    if ind.state == "fade_out" then
        ind.state = "fade_in"
        ind.timer = 0
    end
end

local function scan_sounds(now)
    local cam_x, cam_y, cam_z = camera_pos()
    if not cam_x then return end

    local off = ensure_offsets()
    if not ensure_mem() or not off.is_playing then return end

    local sound_range = math.max(50, settings.num(ID_MAX_DIST, DEFAULT_MAX_DIST))
    local player_range = math.max(50, settings.num(PLAYER_RANGE, 500))
    local max_dist = math.min(sound_range, player_range)

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
                            local vol, spd, looped, rolloff = read_sound_state(child, addr, off)
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

                                if vol > prev.vol then started = true end
                                if vol < prev.vol then stopped = true end
                                if spd > prev.spd then started = true end
                                if spd < prev.spd then stopped = true end
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

                                if started and not stopped and is_audible then
                                    bump_indicator(addr, s.name, px, py, pz)
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
                                        ind.seen = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

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

    menu_util.section(T, G.VISUALS, "Sound ESP")
    menu.add_checkbox(T, G.VISUALS, P, "Sound ESP", false)
    menu.add_slider_float(T, G.VISUALS, ID_FADE_IN, "Sound Fade In", 0.05, 2.0, 0.25, "%.2f", root)
    menu.add_slider_float(T, G.VISUALS, ID_FADE_OUT, "Sound Fade Out", 0.5, 15.0, 5.0, "%.2f", root)
    menu.add_slider_int(T, G.VISUALS, ID_SIZE, "Sound Text Size", 8, 20, DEFAULT_SIZE, root)
    menu.add_slider_float(T, G.VISUALS, ID_UNDER, "Under Offset", 0, 6, DEFAULT_UNDER, "%.1f", root)
    menu.add_slider_int(T, G.VISUALS, ID_SCREEN_Y, "Screen Offset", -20, 40, DEFAULT_SCREEN_Y, root)
    menu.add_slider_int(T, G.VISUALS, ID_MAX_DIST, "Sound Range", 50, 2000, DEFAULT_MAX_DIST, root)
    menu.add_checkbox(T, G.VISUALS, ID_CHIP, "Sound Chip", false, root)
    menu.add_colorpicker(T, G.VISUALS, ID_COLOR, "Sound Color", { 0.78, 0.9, 1.0, 0.92 }, root)
    menu_util.bind_children(P, {
        ID_FADE_IN, ID_FADE_OUT, ID_SIZE, ID_UNDER, ID_SCREEN_Y, ID_MAX_DIST, ID_CHIP, ID_COLOR,
    })
end

function M.update(dt)
    if not settings.enabled(P) then
        if next(indicators) then indicators = {} end
        if next(sound_prev) then sound_prev = {} end
        if next(player_cache) then player_cache = {} end
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

    local drawn = {}
    for _, ind in pairs(indicators) do
        local a = (ind.alpha or 0) * ba
        if a > 0.02 and ind.x then
            local sx, sy, vis = esp_util.w2s(ind.x, ind.y, ind.z)
            if vis and esp_util.screen_point_ok(sx, sy, 64) then
                local key = math.floor(sx / 10) .. ":" .. math.floor(sy / 10)
                local slot = drawn[key] or 0
                drawn[key] = slot + 1
                -- Below the player; stack further down when multiple sounds.
                local y = sy + screen_y + slot * (size + 2)
                draw_label(sx, y, ind.name or "Sound", { br, bg, bb, a }, size, chip)
            end
        end
    end
end

return M
