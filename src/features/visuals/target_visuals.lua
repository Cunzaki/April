-- Target visuals: custom crosshair, smooth follow-target, and motion effects.
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local active_target = April.require("features.combat.active_target")
local overlay_theme = April.require("core.overlay_theme")

local M = {}

local P = "april_crosshair_enabled"

local CROSS_STYLES = { "Cross", "Circle", "Dot", "T-Shape", "Diamond", "Plus", "Brackets", "X" }

-- Smoothed follow position (screen space).
local follow = { x = nil, y = nil, ready = false }

local function tick_s()
    return (utility and utility.get_tick_count and utility.get_tick_count() or 0) * 0.001
end

local function screen_center()
    local sw, sh = draw_util.screen_size()
    return sw * 0.5, sh * 0.5
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function follow_alpha(dt)
    dt = dt or (1 / 60)
    -- Small lag — higher = snappier, lower = floatier.
    local rate = settings.num("april_crosshair_follow_smooth", 18) * 0.045
    return 1 - math.exp(-rate * dt * 60)
end

local function crosshair_color()
    if settings.bool("april_crosshair_rainbow", false) then
        local t = tick_s()
        local speed = settings.num("april_crosshair_rainbow_speed", 10) * 0.1
        return {
            (math.sin(t * speed) + 1) * 0.5,
            (math.sin(t * speed + 2) + 1) * 0.5,
            (math.sin(t * speed + 4) + 1) * 0.5,
            1,
        }
    end
    return settings.color("april_crosshair_color", { 0, 1, 0, 1 })
end

local function motion_scale(base_size)
    if not settings.bool("april_crosshair_pulse", false) then
        return base_size
    end
    local speed = settings.num("april_crosshair_pulse_speed", 40) * 0.05
    local wave = 0.82 + 0.18 * math.sin(tick_s() * speed * 3.2)
    return base_size * wave
end

local function spin_angle()
    if not settings.bool("april_crosshair_spin", false) then
        return 0
    end
    local speed = settings.num("april_crosshair_spin_speed", 35) * 0.04
    return tick_s() * speed * 6.283
end

local function rot_point(cx, cy, x, y, angle)
    local dx, dy = x - cx, y - cy
    local c, s = math.cos(angle), math.sin(angle)
    return cx + dx * c - dy * s, cy + dx * s + dy * c
end

local function draw_line(x1, y1, x2, y2, col, thick, outline)
    if outline and settings.bool("april_crosshair_outline", true) then
        local oc = settings.color("april_crosshair_outline", { 0, 0, 0, 1 })
        local oa = { oc[1], oc[2], oc[3], (col[4] or 1) * (oc[4] or 1) }
        draw_util.line(x1, y1, x2, y2, oa, (thick or 1) + 1.5)
    end
    draw_util.line(x1, y1, x2, y2, col, thick or 1)
end

local function draw_spoke(cx, cy, angle, inner, outer, col, thick, outline)
    local x1, y1 = rot_point(cx, cy, cx, cy - inner, angle)
    local x2, y2 = rot_point(cx, cy, cx, cy - outer, angle)
    draw_line(x1, y1, x2, y2, col, thick, outline)
end

local function draw_cross(cx, cy, size, gap, thick, col, outline, spin)
    spin = spin or 0
    for i = 0, 3 do
        local a = spin + i * 1.5707963
        draw_spoke(cx, cy, a, gap, gap + size, col, thick, outline)
    end
end

local function draw_plus(cx, cy, size, thick, col, outline, spin)
    spin = spin or 0
    for i = 0, 3 do
        local a = spin + i * 1.5707963
        draw_spoke(cx, cy, a, 0, size, col, thick, outline)
    end
end

local function draw_x(cx, cy, size, thick, col, outline, spin)
    spin = spin or 0
    for _, base in ipairs({ 0.785398, 2.35619 }) do
        draw_spoke(cx, cy, spin + base, 0, size, col, thick, outline)
    end
end

local function draw_brackets(cx, cy, size, thick, col, outline)
    local w = size * 0.55
    local h = size
    draw_line(cx - w, cy - h, cx - w * 0.35, cy - h, col, thick, outline)
    draw_line(cx - w, cy - h, cx - w, cy - h * 0.35, col, thick, outline)
    draw_line(cx - w, cy + h, cx - w * 0.35, cy + h, col, thick, outline)
    draw_line(cx - w, cy + h, cx - w, cy + h * 0.35, col, thick, outline)
    draw_line(cx + w, cy - h, cx + w * 0.35, cy - h, col, thick, outline)
    draw_line(cx + w, cy - h, cx + w, cy - h * 0.35, col, thick, outline)
    draw_line(cx + w, cy + h, cx + w * 0.35, cy + h, col, thick, outline)
    draw_line(cx + w, cy + h, cx + w, cy + h * 0.35, col, thick, outline)
end

local function draw_diamond(cx, cy, size, col)
    if draw and draw.line then
        draw.line(cx, cy - size, cx + size, cy, col, 2)
        draw.line(cx + size, cy, cx, cy + size, col, 2)
        draw.line(cx, cy + size, cx - size, cy, col, 2)
        draw.line(cx - size, cy, cx, cy - size, col, 2)
    else
        draw_util.line(cx, cy - size, cx + size, cy, col, 2)
        draw_util.line(cx + size, cy, cx, cy + size, col, 2)
        draw_util.line(cx, cy + size, cx - size, cy, col, 2)
        draw_util.line(cx - size, cy, cx, cy - size, col, 2)
    end
end

local function draw_crosshair(cx, cy)
    local size = motion_scale(settings.num("april_crosshair_size", 10))
    local gap = settings.num("april_crosshair_gap", 5)
    local thick = settings.num("april_crosshair_thickness", 2)
    local col = crosshair_color()
    local outline = settings.bool("april_crosshair_outline", true)
    local kind = math.floor(settings.num("april_crosshair_type", 0) or 0)
    local spin = spin_angle()

    if kind == 1 then
        draw_util.circle(cx, cy, size, col, false)
    elseif kind == 2 then
        draw_util.circle(cx, cy, size * 0.5, col, true)
    elseif kind == 3 then
        draw_line(cx - size, cy - size * 0.45, cx + size, cy - size * 0.45, col, thick, outline)
        draw_line(cx, cy - size * 0.45, cx, cy + size, col, thick, outline)
    elseif kind == 4 then
        draw_diamond(cx, cy, size * 0.75, col)
    elseif kind == 5 then
        draw_plus(cx, cy, size, thick, col, outline, spin)
    elseif kind == 6 then
        draw_brackets(cx, cy, size, thick, col, outline)
    elseif kind == 7 then
        draw_x(cx, cy, size, thick, col, outline, spin)
    else
        draw_cross(cx, cy, size, gap, thick, col, outline, spin)
    end

    if settings.bool("april_crosshair_dot", false) then
        local dc = settings.color("april_crosshair_dot", { 1, 1, 1, 1 })
        draw_util.circle(cx, cy, math.max(1.5, thick), dc, true)
    end
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.VISUALS)
    local root = menu_util.parent(P)

    menu_util.section(T, G.VISUALS, "Crosshair")
    menu.add_checkbox(T, G.VISUALS, P, "Custom Crosshair", false)
    menu.add_combo(T, G.VISUALS, "april_crosshair_type", "Crosshair Style", CROSS_STYLES, 0, root)
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_follow", "Follow Target", false, root)
    menu.add_combo(T, G.VISUALS, active_target.SOURCE_CROSSHAIR, "Target From",
        active_target.SOURCE_NAMES, 0, menu_util.parent("april_crosshair_follow"))
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_follow_smooth", "Follow Smoothness", 4, 40, 18,
        menu_util.parent("april_crosshair_follow"))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_spin", "Spin", false, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_spin_speed", "Spin Speed", 1, 100, 35,
        menu_util.parent("april_crosshair_spin"))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_pulse", "Pulse Size", false, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_pulse_speed", "Pulse Speed", 1, 100, 40,
        menu_util.parent("april_crosshair_pulse"))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_color", "Crosshair Color", true,
        menu_util.parent(P, { colorpicker = { 0, 1, 0, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_dot", "Center Dot", false,
        menu_util.parent(P, { colorpicker = { 1, 1, 1, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_outline", "Outline", true,
        menu_util.parent(P, { colorpicker = { 0, 0, 0, 1 } }))
    menu.add_checkbox(T, G.VISUALS, "april_crosshair_rainbow", "Rainbow", false, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_rainbow_speed", "Rainbow Speed", 1, 100, 10,
        menu_util.parent("april_crosshair_rainbow"))
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_size", "Size", 1, 50, 10, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_gap", "Gap", 0, 20, 5, root)
    menu.add_slider_int(T, G.VISUALS, "april_crosshair_thickness", "Thickness", 1, 10, 2, root)

    menu_util.bind_children(P, {
        "april_crosshair_type", "april_crosshair_follow", "april_crosshair_spin", "april_crosshair_pulse",
        "april_crosshair_color", "april_crosshair_dot", "april_crosshair_outline",
        "april_crosshair_rainbow", "april_crosshair_rainbow_speed",
        "april_crosshair_size", "april_crosshair_gap", "april_crosshair_thickness",
    })
    menu_util.bind_children("april_crosshair_follow", {
        active_target.SOURCE_CROSSHAIR, "april_crosshair_follow_smooth",
    })
    menu_util.bind_children("april_crosshair_spin", { "april_crosshair_spin_speed" })
    menu_util.bind_children("april_crosshair_pulse", { "april_crosshair_pulse_speed" })
    menu_util.bind_children("april_crosshair_rainbow", { "april_crosshair_rainbow_speed" })
end

function M.update(dt)
    local cx, cy = screen_center()
    if not follow.ready then
        follow.x, follow.y = cx, cy
        follow.ready = true
    end

    local goal_x, goal_y = cx, cy
    if settings.bool("april_crosshair_follow", false) then
        -- Pass smoothed position so "Closest" hitbox tracks from the crosshair, not hard center.
        local pt = active_target.get_aim_screen(nil, follow.x, follow.y, active_target.SOURCE_CROSSHAIR)
        if pt then
            goal_x, goal_y = pt.x, pt.y
        end
    end

    local alpha = follow_alpha(dt)
    follow.x = lerp(follow.x, goal_x, alpha)
    follow.y = lerp(follow.y, goal_y, alpha)
end

function M.draw()
    overlay_theme.sync()

    local cx, cy = screen_center()
    if settings.bool("april_crosshair_follow", false) and follow.ready then
        cx, cy = follow.x, follow.y
    end

    if settings.enabled(P) then
        draw_crosshair(cx, cy)
    end
end

return M
