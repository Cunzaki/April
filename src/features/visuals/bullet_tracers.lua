local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local weapons = April.require("game.weapons")
local cache = April.require("core.cache")
local env = April.require("core.env")

local M = {}
local P = "april_bullet_tracer_enabled"

local tracers = {}
local health_history = {}
local last_shoot_tick = 0
local last_hit_notify = {}

local function tick()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerp_color(c1, c2, t)
    return {
        lerp(c1[1] or 1, c2[1] or 1, t),
        lerp(c1[2] or 1, c2[2] or 1, t),
        lerp(c1[3] or 1, c2[3] or 1, t),
        lerp(c1[4] or 1, c2[4] or 1, t),
    }
end

local function gradient_t(mode, speed, u)
    mode = mode or 0
    speed = speed or 1
    if mode == 1 then
        return 0.5 + 0.5 * math.sin(tick() * 0.001 * speed * 3)
    elseif mode == 2 then
        return (tick() * 0.001 * speed + u) % 1
    elseif mode == 3 then
        return math.abs(math.sin(tick() * 0.001 * speed * 2 + u * math.pi))
    end
    return u
end

local function shooting_recently(now)
    if input and input.is_key_down and input.is_key_down(0x01) then return true end
    return (now - last_shoot_tick) < 150
end

local function read_npc_health(npc)
    if not npc or not env.is_valid(npc.inst) then return nil end
    local hum = env.safe_call(function()
        if npc.inst.find_first_child_of_class then
            return npc.inst:find_first_child_of_class("Humanoid")
        end
        return nil
    end)
    if not hum then return nil end
    return hum.Health or hum.health
end

local function npc_hit_pos(npc)
    if npc.head and env.is_valid(npc.head) then
        local pos = npc.head.Position or npc.head.position
        if pos then
            return pos.x or pos.X, pos.y or pos.Y, pos.z or pos.Z
        end
    end
    local scan = April.require("game.esp_scan")
    return scan.label_position({ inst = npc.inst })
end

local function add_tracer(hit_x, hit_y, hit_z)
    if not camera or not camera.get_position then return end
    local cam = camera.get_position()
    if not cam then return end

    local cx = cam.x or cam.X or 0
    local cy = cam.y or cam.Y or 0
    local cz = cam.z or cam.Z or 0

    local stats = weapons.get_weapon_stats()
    local grav = 20
    local spd = 800
    if stats then
        spd = stats.speed or spd
        grav = stats.gravity or grav
        if grav < 5 then
            grav = weapons.drop_gravity(grav)
        end
    end

    local dx = hit_x - cx
    local dy = hit_y - cy
    local dz = hit_z - cz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local flight_time = dist / math.max(spd, 1)

    table.insert(tracers, {
        ox = cx, oy = cy, oz = cz,
        tx = hit_x, ty = hit_y, tz = hit_z,
        gravity = grav,
        flight_time = flight_time,
        created = tick(),
    })

    while #tracers > 30 do
        table.remove(tracers, 1)
    end
end

local function on_health_drop(target_id, hit_x, hit_y, hit_z, now)
    local last = last_hit_notify[target_id] or 0
    if now - last < 50 then return end
    last_hit_notify[target_id] = now

    if settings.enabled(P) then
        add_tracer(hit_x, hit_y, hit_z)
    end

    pcall(function()
        local feedback = April.require("features.visuals.feedback")
        if feedback.trigger_hit then feedback.trigger_hit() end
    end)
end

function M.track_hits()
    if not settings.enabled(P)
        and not settings.enabled("april_hitmarker_enabled")
        and not settings.enabled("april_hit_notifier") then
        return
    end

    local now = tick()
    if input and input.is_key_down and input.is_key_down(0x01) then
        last_shoot_tick = now
    end

    if not shooting_recently(now) then
        if entity and entity.get_players then
            for _, p in ipairs(entity.get_players()) do
                if not p.is_local and p.is_alive then
                    local id = p.user_id or p.name or tostring(p)
                    health_history[id] = p.health
                end
            end
        end
        for _, npc in ipairs(cache.npcs or {}) do
            local id = "npc:" .. (npc.name or "") .. ":" .. tostring(npc.inst)
            health_history[id] = read_npc_health(npc)
        end
        return
    end

    if entity and entity.get_players then
        for _, p in ipairs(entity.get_players()) do
            if p.is_local or not p.is_alive then goto next_player end
            local id = p.user_id or p.name or tostring(p)
            local cur = p.health
            local last = health_history[id]
            if type(last) == "number" and type(cur) == "number" and cur < last and cur >= 0 then
                local hx, hy, hz
                if p.head_position then
                    hx, hy, hz = p.head_position.x, p.head_position.y, p.head_position.z
                elseif p.position then
                    hx, hy, hz = p.position.x, p.position.y, p.position.z
                end
                if hx then
                    on_health_drop(id, hx, hy, hz, now)
                end
            end
            health_history[id] = cur
            ::next_player::
        end
    end

    for _, npc in ipairs(cache.npcs or {}) do
        local id = "npc:" .. (npc.name or "") .. ":" .. tostring(npc.inst)
        local cur = read_npc_health(npc)
        local last = health_history[id]
        if type(last) == "number" and type(cur) == "number" and cur < last and cur >= 0 then
            local hx, hy, hz = npc_hit_pos(npc)
            if hx then
                on_health_drop(id, hx, hy, hz, now)
            end
        end
        health_history[id] = cur
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    menu_util.section(T, G.VISUALS, "Bullet Tracers")
    menu.add_checkbox(T, G.VISUALS, P, "Bullet Tracers", false, { colorpicker = { 1, 0.6, 0.2, 1 } })
    menu.add_slider_float(T, G.VISUALS, "april_bullet_tracer_lifetime", "Tracer Fade Time", 0.1, 3.0, 0.5, "%.1fs", { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_bullet_tracer_thickness", "Tracer Thickness", 1, 5, 2, { parent = P })
    menu.add_slider_int(T, G.VISUALS, "april_bullet_tracer_segments", "Tracer Smoothness", 5, 30, 15, { parent = P })
    menu.add_checkbox(T, G.VISUALS, "april_bullet_tracer_gradient", "Tracer Gradient", false, { parent = P, colorpicker = { 0, 0.8, 1, 1 } })
    menu.add_combo(T, G.VISUALS, "april_bullet_tracer_grad_anim", "Gradient Animation", { "Static", "Pulse", "Cycle", "Bounce" }, 0, { parent = "april_bullet_tracer_gradient" })
    menu.add_slider_float(T, G.VISUALS, "april_bullet_tracer_grad_speed", "Gradient Speed", 0.1, 10.0, 1.0, "%.1f", { parent = "april_bullet_tracer_gradient" })
end

function M.update(dt)
    if settings.enabled(P)
        or settings.enabled("april_hitmarker_enabled")
        or settings.enabled("april_hit_notifier") then
        M.track_hits()
    end

    if not settings.enabled(P) then
        if #tracers > 0 then tracers = {} end
        return
    end

    local now = tick()
    local lifetime_ms = settings.num("april_bullet_tracer_lifetime", 0.5) * 1000
    local i = 1
    while i <= #tracers do
        if now - tracers[i].created > lifetime_ms then
            table.remove(tracers, i)
        else
            i = i + 1
        end
    end
end

function M.draw()
    if not settings.enabled(P) or #tracers == 0 then return end

    local now = tick()
    local color = settings.color(P, { 1, 0.6, 0.2, 1 })
    local thickness = settings.num("april_bullet_tracer_thickness", 2)
    local num_segs = settings.num("april_bullet_tracer_segments", 15)
    local lifetime_ms = settings.num("april_bullet_tracer_lifetime", 0.5) * 1000
    local use_grad = settings.enabled("april_bullet_tracer_gradient")
    local color2 = settings.color("april_bullet_tracer_gradient", { 0, 0.8, 1, 1 })
    local grad_anim = settings.num("april_bullet_tracer_grad_anim", 0)
    local grad_speed = settings.num("april_bullet_tracer_grad_speed", 1)

    for _, tr in ipairs(tracers) do
        local elapsed_ms = now - tr.created
        local alpha = 1.0 - (elapsed_ms / lifetime_ms)
        if alpha <= 0 then goto next_tracer end

        local prev_sx, prev_sy, prev_vis = nil, nil, false
        local cr, cg, cb, ca = color[1], color[2], color[3], color[4] or 1
        local arc_peak = 0.5 * tr.gravity * tr.flight_time * tr.flight_time

        for seg = 0, num_segs do
            local u = seg / num_segs
            local px = tr.ox + (tr.tx - tr.ox) * u
            local py = tr.oy + (tr.ty - tr.oy) * u + arc_peak * u * (1 - u)
            local pz = tr.oz + (tr.tz - tr.oz) * u

            local sx, sy, vis = esp_util.w2s(px, py, pz)

            if seg > 0 and vis and prev_vis then
                local seg_alpha = (0.3 + 0.7 * u) * alpha * ca
                if use_grad then
                    local gt = gradient_t(grad_anim, grad_speed, u)
                    local gc = lerp_color(color, color2, gt)
                    draw_util.line(prev_sx, prev_sy, sx, sy, { gc[1], gc[2], gc[3], seg_alpha }, thickness)
                else
                    draw_util.line(prev_sx, prev_sy, sx, sy, { cr, cg, cb, seg_alpha }, thickness)
                end
            end

            prev_sx, prev_sy, prev_vis = sx, sy, vis
        end

        ::next_tracer::
    end
end

return M
