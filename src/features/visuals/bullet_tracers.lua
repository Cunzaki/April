-- Draw-based bullet tracers (no instance.New).
-- Detection: accumulated live entity.Health drop (Min Damage), focus/MB1 gate.

local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local env = April.require("core.env")
local ep = April.require("core.entity_props")
local esp_util = April.require("core.esp_util")
local draw_util = April.require("core.draw_util")
local cache = April.require("core.cache")
local combat_origin = April.require("game.combat_origin")
local player_state = April.require("game.player_state")

local M = {}

local P = "april_tracers_enabled"
local P_COLOR = "april_tracers_color"
local P_COLOR2 = "april_tracers_color2"
local P_LIFE = "april_tracers_lifetime"
local P_THICK = "april_tracers_thickness"
local P_TRANS = "april_tracers_transparency"
local P_STYLE = "april_tracers_style"
local P_ANIM = "april_tracers_anim"
local P_ANIM_SPD = "april_tracers_anim_speed"
local P_SEGS = "april_tracers_segments"
local P_GLOW = "april_tracers_glow"
local P_DMG = "april_tracers_damage"
local P_OUTLINE = "april_tracers_outline"
local P_IMPACT = "april_tracers_impact"
local P_RAINBOW = "april_tracers_rainbow"

local ACCUM_WINDOW_MS = 350
local MAX_TRACERS = 28
local SHOOT_VK = 0x01
local POLL_IDLE_MS = 50
local last_poll_ms = 0
local cached_active_target = nil
local cached_silent = nil
local cached_aim = nil
local DEFAULT_COLOR = { 1.0, 0.55, 0.18, 1.0 }
local DEFAULT_COLOR2 = { 1.0, 0.2, 0.35, 1.0 }

local STYLE_NAMES = { "Beam", "Glow", "Gradient", "Dashed", "Ribbon" }
local ANIM_NAMES = { "Fade", "Sweep", "Shrink", "Pulse", "Travel", "Bloom" }

local tracers = {}
local hp_cache = {}
local focus_ms = {}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function tick_s()
    return tick_ms() * 0.001
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function smoothstep(t)
    t = clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function ease_out_cubic(t)
    t = clamp(t, 0, 1)
    local u = 1 - t
    return 1 - u * u * u
end

local function col_mul_a(c, a)
    return { c[1], c[2], c[3], (c[4] or 1) * a }
end

local function col_lerp(a, b, t)
    return {
        lerp(a[1], b[1], t),
        lerp(a[2], b[2], t),
        lerp(a[3], b[3], t),
        lerp(a[4] or 1, b[4] or 1, t),
    }
end

local function rainbow_color(offset)
    local speed = settings.num(P_ANIM_SPD, 1) * 1.6
    local t = tick_s() * speed + (offset or 0)
    return {
        (math.sin(t) + 1) * 0.5,
        (math.sin(t + 2.094) + 1) * 0.5,
        (math.sin(t + 4.189) + 1) * 0.5,
        1,
    }
end

local function tracer_colors()
    local c1 = settings.color(P_COLOR, DEFAULT_COLOR)
    local c2 = settings.color(P_COLOR2, DEFAULT_COLOR2)
    if type(c1) ~= "table" then c1 = DEFAULT_COLOR end
    if type(c2) ~= "table" then c2 = DEFAULT_COLOR2 end
    c1 = {
        tonumber(c1[1]) or DEFAULT_COLOR[1],
        tonumber(c1[2]) or DEFAULT_COLOR[2],
        tonumber(c1[3]) or DEFAULT_COLOR[3],
        tonumber(c1[4]) or 1,
    }
    c2 = {
        tonumber(c2[1]) or DEFAULT_COLOR2[1],
        tonumber(c2[2]) or DEFAULT_COLOR2[2],
        tonumber(c2[3]) or DEFAULT_COLOR2[3],
        tonumber(c2[4]) or 1,
    }
    if settings.bool(P_RAINBOW, false) then
        c1 = rainbow_color(0)
        c2 = rainbow_color(1.2)
    end
    return c1, c2
end

local function damage_threshold()
    return clamp(tonumber(settings.num(P_DMG, 10)) or 10, 1, 100)
end

local function player_key(player)
    if not player then return nil end
    local uid = ep.user_id(player)
    if uid and uid ~= 0 then return "u:" .. tostring(uid) end
    local addr = player.Address or player.address
    if addr then return "a:" .. tostring(addr) end
    return "p:" .. tostring(player)
end

local function read_hp(player)
    if not player then return nil end
    local ok, hp = pcall(function()
        return player.Health or player.health
    end)
    if ok and tonumber(hp) then return tonumber(hp) end
    return ep.health(player)
end

local function local_origin()
    return combat_origin.get_muzzle_origin()
        or combat_origin.get_fire_origin()
        or combat_origin.get_camera_origin()
        or combat_origin.get_server_origin()
end

local function target_point(player)
    local head = ep.head_position(player)
    if head then
        local x, y, z = esp_util.vec3_pos(head)
        if x then return { x = x, y = y, z = z } end
    end
    local pos = ep.position(player)
    if pos then
        local x, y, z = esp_util.vec3_pos(pos)
        if x then return { x = x, y = y, z = z } end
    end
    return nil
end

local function clear_tracers()
    tracers = {}
end

local function spawn_tracer(from, to)
    if not from or not to then return end
    local ox, oy, oz = from.x, from.y, from.z
    local ex, ey, ez = to.x, to.y, to.z
    if type(ox) ~= "number" or type(ex) ~= "number" then return end
    local dx, dy, dz = ex - ox, ey - oy, ez - oz
    local seg = math.sqrt(dx * dx + dy * dy + dz * dz)
    if seg < 0.35 then return end

    local life = clamp(tonumber(settings.num(P_LIFE, 550)) or 550, 80, 3000)
    local c1, c2 = tracer_colors()

    while #tracers >= MAX_TRACERS do
        table.remove(tracers, 1)
    end

    tracers[#tracers + 1] = {
        ox = ox, oy = oy, oz = oz,
        ex = ex, ey = ey, ez = ez,
        born = tick_ms(),
        life = life,
        c1 = { c1[1], c1[2], c1[3], c1[4] },
        c2 = { c2[1], c2[2], c2[3], c2[4] },
        seed = (ox * 12.9898 + oz * 78.233) % 1,
    }
end

local function on_hit(player)
    local from = local_origin()
    local to = target_point(player)
    if from and to then
        spawn_tracer(from, to)
    end
end

local function mark_focus(player, now)
    local key = player_key(player)
    if key then focus_ms[key] = now end
end

local function is_focus(key, now)
    local t = focus_ms[key]
    return t and (now - t) <= 2500
end

local function ensure_combat_mods()
    if not cached_active_target then
        pcall(function()
            cached_active_target = April.require("features.combat.active_target")
        end)
    end
    if not cached_silent then
        pcall(function()
            cached_silent = April.require("features.combat.aimbot")
        end)
    end
    if not cached_aim then
        pcall(function()
            cached_aim = April.require("features.combat.camera_aimbot")
        end)
    end
end

local function refresh_focus(now)
    local function add(player)
        if player and not ep.is_local(player) then
            mark_focus(player, now)
        end
    end

    ensure_combat_mods()
    if cached_active_target and cached_active_target.get_target then
        add(cached_active_target.get_target())
    end
    if cached_silent and cached_silent.get_target then
        add(cached_silent.get_target())
    end
    if cached_aim and cached_aim.get_target then
        add(cached_aim.get_target())
    end
end

local function poll_damage(now)
    local firing = input and input.is_key_down and input.is_key_down(SHOOT_VK)
    -- Idle: skip full HP scan most frames; focus refresh stays light.
    if not firing and (now - last_poll_ms) < POLL_IDLE_MS then
        refresh_focus(now)
        return
    end
    last_poll_ms = now
    refresh_focus(now)

    local threshold = damage_threshold()
    local players = cache.players
    if type(players) ~= "table" then
        players = {}
    end

    -- While firing, only poll focused combat targets (huge win on full servers).
    local live = {}
    for i = 1, #players do
        local player = players[i]
        if player and not ep.is_local(player)
            and player_state.is_combat_target(player)
            and player_state.passes_team_check(player)
        then
            local key = player_key(player)
            if key and ((not firing) or is_focus(key, now)) then
                local hp = read_hp(player)
                if hp then
                    live[key] = true
                    local prev = hp_cache[key]
                    if not prev then
                        hp_cache[key] = { hp = hp, accum = 0, accum_ms = now }
                    else
                        if hp > prev.hp + 5 then
                            hp_cache[key] = { hp = hp, accum = 0, accum_ms = now }
                        else
                            local delta = prev.hp - hp
                            local accum = prev.accum or 0
                            local accum_ms = prev.accum_ms or now
                            if (now - accum_ms) > ACCUM_WINDOW_MS then
                                accum = 0
                                accum_ms = now
                            end
                            if delta > 0 then
                                accum = accum + delta
                                accum_ms = now
                            end
                            hp_cache[key] = { hp = hp, accum = accum, accum_ms = accum_ms }

                            if accum >= threshold and firing and is_focus(key, now) then
                                hp_cache[key].accum = 0
                                hp_cache[key].accum_ms = now
                                on_hit(player)
                            end
                        end
                    end
                end
            end
        end
    end

    for key in pairs(hp_cache) do
        if not live[key] then hp_cache[key] = nil end
    end
    for key, t in pairs(focus_ms) do
        if (now - t) > 5000 then focus_ms[key] = nil end
    end
end

local function line(x1, y1, x2, y2, col, thick)
    if not x1 or not x2 then return end
    -- Reject (0,0) pairs — draw.Line silently ignores them.
    if (x1 == 0 and y1 == 0) or (x2 == 0 and y2 == 0) then return end
    draw_util.line(x1, y1, x2, y2, col, thick)
end

local function sample_world(t, tr)
    return {
        x = lerp(tr.ox, tr.ex, t),
        y = lerp(tr.oy, tr.ey, t),
        z = lerp(tr.oz, tr.ez, t),
    }
end

local function project(t, tr)
    local p = sample_world(t, tr)
    local sx, sy, ok = esp_util.w2s_visible(p.x, p.y, p.z, 120)
    if not ok then
        sx, sy, ok = esp_util.w2s(p.x, p.y, p.z)
    end
    return sx, sy, ok == true
end

local function anim_params(tr, now)
    local age = now - (tr.born or now)
    local life = tr.life or 500
    local u = clamp(age / life, 0, 1)
    local anim = settings.combo_index(P_ANIM, ANIM_NAMES, 0)
    local spd = clamp(tonumber(settings.num(P_ANIM_SPD, 1)) or 1, 0.25, 3)
    local base_a = 1 - clamp(tonumber(settings.num(P_TRANS, 0.05)) or 0.05, 0, 0.95)
    local thick = clamp(tonumber(settings.num(P_THICK, 2.2)) or 2.2, 0.5, 8)

    local alpha = base_a
    local reveal = 1
    local thick_mul = 1
    local travel = 0
    local bloom = 0

    if anim == 0 then -- Fade
        alpha = base_a * (1 - smoothstep(u))
    elseif anim == 1 then -- Sweep
        local grow = clamp(u * (1.15 + spd * 0.35), 0, 1)
        reveal = ease_out_cubic(grow)
        alpha = base_a * (1 - smoothstep(math.max(0, u - 0.55) / 0.45))
    elseif anim == 2 then -- Shrink
        thick_mul = 1 - smoothstep(u) * 0.85
        alpha = base_a * (1 - smoothstep(u))
    elseif anim == 3 then -- Pulse
        local wave = 0.72 + 0.28 * math.sin(tick_s() * (6 + spd * 4) + (tr.seed or 0) * 6.28)
        thick_mul = wave
        alpha = base_a * (0.55 + 0.45 * wave) * (1 - smoothstep(u) * 0.85)
    elseif anim == 4 then -- Travel
        travel = (u * spd * 1.35 + (tr.seed or 0)) % 1
        reveal = 1
        alpha = base_a * (1 - smoothstep(u))
    elseif anim == 5 then -- Bloom
        bloom = ease_out_cubic(clamp(u * 1.4, 0, 1))
        thick_mul = 1 + bloom * 1.8
        alpha = base_a * (1 - smoothstep(u))
        reveal = clamp(u * 3, 0, 1)
    else
        alpha = base_a * (1 - smoothstep(u))
    end

    return {
        u = u,
        alpha = clamp(alpha, 0, 1),
        reveal = clamp(reveal, 0, 1),
        thick = thick * thick_mul,
        travel = travel,
        bloom = bloom,
        anim = anim,
        done = u >= 1 or alpha < 0.02,
    }
end

local function draw_segment(x1, y1, x2, y2, col, thick, style, glow)
    if not x1 or not x2 then return end
    if settings.bool(P_OUTLINE, true) then
        line(x1, y1, x2, y2, col_mul_a({ 0, 0, 0, 1 }, (col[4] or 1) * 0.75), thick + 1.6)
    end

    if style == 1 then -- Glow layers (2 soft + core; keep cheap)
        local g = clamp(tonumber(settings.num(P_GLOW, 1)) or 1, 0.2, 3)
        line(x1, y1, x2, y2, col_mul_a(col, 0.18 * g), thick * (2.6 + g * 0.5))
        line(x1, y1, x2, y2, col_mul_a(col, 0.45), thick * 1.25)
        line(x1, y1, x2, y2, col, thick)
    else
        line(x1, y1, x2, y2, col, thick)
    end
end

local function draw_ribbon_segment(x1, y1, x2, y2, col, half_w)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.5 then return end
    local nx, ny = -dy / len * half_w, dx / len * half_w
    local poly = draw.PolyFilled or draw.poly_filled
    if type(poly) == "function" then
        pcall(poly, {
            { x = x1 + nx, y = y1 + ny },
            { x = x2 + nx, y = y2 + ny },
            { x = x2 - nx, y = y2 - ny },
            { x = x1 - nx, y = y1 - ny },
        }, col)
        return
    end
    line(x1, y1, x2, y2, col, half_w * 2)
end

local function draw_impact(tr, ap)
    if not settings.bool(P_IMPACT, true) then return end
    local sx, sy, ok = project(1, tr)
    if not ok then return end
    local r = (4 + ap.bloom * 18 + (1 - ap.u) * 10) * (0.7 + settings.num(P_GLOW, 1) * 0.3)
    local a = ap.alpha * (0.35 + 0.65 * (1 - ap.u))
    local c = col_mul_a(tr.c2 or tr.c1, a)
    draw_util.circle(sx, sy, r, c, false)
    draw_util.circle(sx, sy, r * 0.45, col_mul_a(c, 0.85), true)
end

local function draw_one(tr, now)
    local ap = anim_params(tr, now)
    if ap.done then return false end

    local style = settings.combo_index(P_STYLE, STYLE_NAMES, 1)
    local segs = math.floor(clamp(tonumber(settings.num(P_SEGS, 12)) or 12, 4, 48))
    local c1 = tr.c1 or DEFAULT_COLOR
    local c2 = tr.c2 or DEFAULT_COLOR2

    local prev_sx, prev_sy, prev_ok = nil, nil, false
    local t_end = ap.reveal
    if t_end < 0.02 then
        draw_impact(tr, ap)
        return true
    end

    for i = 0, segs do
        local t = (i / segs) * t_end
        local sx, sy, ok = project(t, tr)
        if prev_ok and ok then
            local col
            if style == 2 then -- Gradient
                col = col_lerp(c1, c2, t)
            else
                col = col_lerp(c1, c2, t * 0.65)
            end
            col = col_mul_a(col, ap.alpha)

            local draw_it = true
            if style == 3 then -- Dashed (animated)
                local dash_t = (t * 10 + tick_s() * (3 + settings.num(P_ANIM_SPD, 1) * 4)) % 1
                draw_it = dash_t < 0.58
            end

            if ap.anim == 4 then -- Travel highlight boost near head
                local dist = math.abs(t - ap.travel)
                if dist > 0.5 then dist = 1 - dist end
                local boost = clamp(1 - dist * 6, 0, 1)
                col = col_mul_a(col, 0.35 + 0.65 * (0.4 + boost))
                if boost > 0.55 then
                    draw_segment(prev_sx, prev_sy, sx, sy, col_mul_a(c2, ap.alpha * boost), ap.thick * 1.8, 1, true)
                end
            end

            if draw_it then
                if style == 4 then -- Ribbon
                    draw_ribbon_segment(prev_sx, prev_sy, sx, sy, col, ap.thick * 0.9)
                    if settings.bool(P_OUTLINE, true) then
                        line(prev_sx, prev_sy, sx, sy, col_mul_a({ 0, 0, 0, 1 }, ap.alpha * 0.5), 1)
                    end
                else
                    draw_segment(prev_sx, prev_sy, sx, sy, col, ap.thick, style, true)
                end
            end
        end
        prev_sx, prev_sy, prev_ok = sx, sy, ok
    end

    draw_impact(tr, ap)
    return true
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.GUN_MODS)
    local root = menu_util.parent(P)

    menu_util.section(T, G.GUN_MODS, "Bullet Tracers")
    menu_util.register_keybind(T, G.GUN_MODS, P, "Enable Tracers", false)
    menu.add_colorpicker(T, G.GUN_MODS, P_COLOR, "Tracer Color", DEFAULT_COLOR, root)
    menu.add_colorpicker(T, G.GUN_MODS, P_COLOR2, "Tracer End Color", DEFAULT_COLOR2, root)
    menu.add_combo(T, G.GUN_MODS, P_STYLE, "Tracer Style", STYLE_NAMES, 1, root)
    menu.add_combo(T, G.GUN_MODS, P_ANIM, "Tracer Animation", ANIM_NAMES, 1, root)
    menu.add_slider_float(T, G.GUN_MODS, P_ANIM_SPD, "Anim Speed", 0.25, 3, 1, "%.2f", root)
    menu.add_slider_int(T, G.GUN_MODS, P_LIFE, "Lifetime (ms)", 100, 1500, 550, root)
    menu.add_slider_float(T, G.GUN_MODS, P_THICK, "Tracer Thickness", 0.5, 8, 2.2, "%.1f", root)
    menu.add_slider_float(T, G.GUN_MODS, P_TRANS, "Tracer Fade", 0, 0.9, 0.05, "%.2f", root)
    menu.add_slider_int(T, G.GUN_MODS, P_SEGS, "Tracer Segments", 4, 48, 12, root)
    menu.add_slider_float(T, G.GUN_MODS, P_GLOW, "Glow Strength", 0.2, 3, 1, "%.2f", root)
    menu.add_slider_int(T, G.GUN_MODS, P_DMG, "Min Damage", 1, 50, 10, root)
    menu.add_checkbox(T, G.GUN_MODS, P_OUTLINE, "Tracer Outline", true, root)
    menu.add_checkbox(T, G.GUN_MODS, P_IMPACT, "Impact Flash", true, root)
    menu.add_checkbox(T, G.GUN_MODS, P_RAINBOW, "Tracer Rainbow", false, root)

    menu_util.bind_children(P, {
        P_COLOR, P_COLOR2, P_STYLE, P_ANIM, P_ANIM_SPD, P_LIFE, P_THICK, P_TRANS,
        P_SEGS, P_GLOW, P_DMG, P_OUTLINE, P_IMPACT, P_RAINBOW,
    })

    settings.on_change(P, function(v)
        if not (v == true or v == 1) then
            clear_tracers()
        end
    end)
end

function M.update(_dt)
    if not settings.enabled(P) then
        if #tracers > 0 then clear_tracers() end
        hp_cache = {}
        return
    end
    poll_damage(tick_ms())
end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw then return end

    local now = tick_ms()
    local keep = {}
    for i = 1, #tracers do
        local tr = tracers[i]
        if tr and draw_one(tr, now) then
            keep[#keep + 1] = tr
        end
    end
    tracers = keep
end

M.STYLE_NAMES = STYLE_NAMES
M.ANIM_NAMES = ANIM_NAMES

return M
