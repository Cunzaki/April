-- Themed on-screen HUD for bullet features (hitscan / TP / manip).
local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local desync_vis = April.require("core.desync_vis")
local combat_origin = April.require("game.combat_origin")
local manip_math = April.require("core.manip_math")

local M = {}

local PREFIX = "april_silent_"
local P_BULLET = "april_bullet_enabled"

local scan_anim = 0

local FIRE_LABELS = {
    tp = "Bullet TP",
    hitscan = "Hitscan",
    ready = "Manip Peek",
    direct = "Clear LOS",
    curve = "Ballistic",
    blocked = "Blocked",
    scanning = "Scanning",
    off = "Idle",
}

local MANIP_LABELS = {
    direct = "Clear LOS",
    ready = "Peek Ready",
    scanning = "Scanning",
    blocked = "No Peek",
    off = "Off",
}

local function bullet_flag(name, default)
    if not settings.bool(P_BULLET, false) then
        return false
    end
    return settings.bool(PREFIX .. name, default == true)
end

function M.update(dt)
    scan_anim = scan_anim + (dt or 0.016) * 0.85
    if scan_anim > 1 then scan_anim = scan_anim - 1 end
end

local function row_color(active, ok, warn)
    if active and ok then return theme.GREEN end
    if active and warn then return theme.ORANGE end
    if active then return theme.RED end
    return overlay_theme.text_muted()
end

local function draw_status_panel(cx, cy, fov, info)
    if not settings.bool(PREFIX .. "manip_status", false) then return end
    if not info then return end

    overlay_theme.sync()

    local hitscan_on = info.hitscan_on == true
    local tp_on = info.tp_on == true
    local manip_on = info.manip_on == true
    if not hitscan_on and not tp_on and not manip_on then return end

    local manip_state = info.manip_state or "off"
    local fire_mode = info.state or "off"
    local fire_label = FIRE_LABELS[fire_mode] or fire_mode
    local manip_label = MANIP_LABELS[manip_state] or manip_state

    local pad_x, pad_y = 10, 6
    local row_h = 14
    local bar_h = 5
    local title = "BULLET STATUS"
    local title_w = theme.text_w(title, 11)
    local w1 = theme.text_w("Hitscan", 10) + theme.text_w("ON", 10) + 24
    local w2 = theme.text_w("Bullet TP", 10) + theme.text_w("ON", 10) + 24
    local w3 = theme.text_w("Manip", 10) + theme.text_w(manip_label, 10) + 24
    local w4 = theme.text_w("Fire", 10) + theme.text_w(fire_label, 10) + 24
    local panel_w = math.max(title_w, w1, w2, w3, w4) + pad_x * 2 + 8
    panel_w = math.max(panel_w, 168)

    local rows = 4
    local has_bar = manip_on and (manip_state == "scanning" or manip_state == "ready" or manip_state == "direct")
    local panel_h = 22 + rows * row_h + pad_y + (has_bar and (bar_h + 6) or 0)
    local x = cx - panel_w * 0.5
    local y = cy + fov + 10

    overlay_theme.draw_panel(x, y, panel_w, panel_h, title)

    local tx = x + pad_x
    local ry = y + 24

    local function draw_row(label, value, col)
        draw_util.text(tx, ry, label, overlay_theme.text_muted(), 10)
        local vw = theme.text_w(value, 10)
        draw_util.text(x + panel_w - pad_x - vw, ry, value, col, 10)
        ry = ry + row_h
    end

    draw_row("Hitscan", hitscan_on and "ON" or "OFF", row_color(hitscan_on, true, false))
    draw_row("Bullet TP", tp_on and "ON" or "OFF", row_color(tp_on, true, false))

    local manip_ok = manip_state == "ready" or manip_state == "direct"
    local manip_warn = manip_state == "scanning"
    draw_row("Manip", manip_on and manip_label or "OFF",
        row_color(manip_on, manip_ok, manip_warn))

    local fire_col = theme.CYAN
    if fire_mode == "tp" then
        fire_col = { 0.82, 0.5, 1, 1 }
    elseif fire_mode == "hitscan" then
        fire_col = theme.CYAN
    elseif fire_mode == "ready" or fire_mode == "direct" then
        fire_col = theme.GREEN
    elseif fire_mode == "scanning" or fire_mode == "blocked" then
        fire_col = theme.ORANGE
    end
    draw_row("Fire", fire_label, fire_col)

    if has_bar then
        local bar_w = panel_w - pad_x * 2
        local bar_x = x + pad_x
        local bar_y = ry + 2
        local ready = manip_state == "ready" or manip_state == "direct"
        local prog
        if ready then
            prog = 1
        elseif manip_state == "scanning" then
            prog = 0.25 + scan_anim * 0.65
        else
            prog = math.max(0, math.min(1, info.scan_progress or 0))
        end

        local bg = theme.alpha(overlay_theme.panel_bg(), 0.95)
        local border = overlay_theme.border(0.5)
        local fill = ready and theme.GREEN or theme.alpha(overlay_theme.accent(), 0.9)

        if draw and draw.rect_filled then
            draw.rect_filled(bar_x, bar_y, bar_w, bar_h, bg, 0)
            if prog > 0.01 then
                draw.rect_filled(bar_x, bar_y, bar_w * prog, bar_h, fill, 0)
            end
            if draw.rect then
                draw.rect(bar_x, bar_y, bar_w, bar_h, border, 0, 1)
            end
        end
    end
end

local function draw_peek_visual(info, track)
    if not settings.bool(PREFIX .. "manip_peek_vis", false) then return end
    if not info or not info.peek then return end
    if info.manip_state ~= "ready" and info.manip_state ~= "direct" and not info.body_peek then return end

    local body = combat_origin.get_server_origin()
    if not body then return end

    local peek = info.peek
    local col_peek = { 1, 0.85, 0.2, 0.95 }
    local eye_y = peek.y + manip_math.eye_offset_y()

    desync_vis.draw_cross(peek.x, eye_y, peek.z, 0.85, col_peek, 2)
    desync_vis.draw_link(body, peek, { col_peek[1], col_peek[2], col_peek[3], 0.35 }, 1)

    local aim = info.hitpart or (track and track.aim)
    local ray_from = manip_math.peek_track_origin(peek, track and track.origin, body)
    if ray_from and aim then
        desync_vis.draw_link(ray_from, aim, { 1, 0.45, 0.2, 0.55 }, 1.5)
        desync_vis.draw_cross(ray_from.x, ray_from.y, ray_from.z, 0.4, col_peek, 2)
    end
end

function M.draw(cx, cy, fov, track)
    if not settings.bool(P_BULLET, false) then return end
    if not draw then return end

    local info = track and track.manip
    if not info then return end

    local show_hud = settings.bool(PREFIX .. "manip_status", false)
    local show_peek = settings.bool(PREFIX .. "manip_peek_vis", false)
    if not show_hud and not show_peek then return end

    draw_peek_visual(info, track)
    draw_status_panel(cx, cy, fov, info)
end

return M
