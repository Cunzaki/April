-- Themed on-screen HUD for bullet features (hitscan / TP / manip / hitbox).
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
local i18n_mod = nil

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

local function i18n()
    if i18n_mod then return i18n_mod end
    local ok, mod = pcall(function()
        return April.require("ui.i18n")
    end)
    if ok and mod then
        i18n_mod = mod
        return mod
    end
    return {
        t = function(s) return s end,
    }
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

local function fmt_radius(info)
    local r = tonumber(info and info.radius) or 0
    local base = tonumber(info and info.base_radius) or r
    if info and info.extend_active and r > base + 0.04 then
        return string.format("%.2f (ext)", r)
    end
    return string.format("%.2f", r)
end

local function draw_status_panel(cx, cy, fov, info)
    if not settings.bool(PREFIX .. "manip_status", false) then return end
    if not info then return end

    local hitscan_on = info.hitscan_on == true
    local tp_on = info.tp_on == true
    local manip_on = info.manip_on == true
    local hitbox_on = info.hitbox_on == true
    if not hitscan_on and not tp_on and not manip_on and not hitbox_on then return end

    local t = i18n()
    local manip_state = info.manip_state or "off"
    local fire_mode = info.state or "off"
    local fire_label = t.t(FIRE_LABELS[fire_mode] or fire_mode)
    if fire_mode == "tp" and hitbox_on then
        local mult = tonumber(info.hitbox_mult) or tonumber(info.head_scale) or 1
        fire_label = fire_label .. string.format(" x%.1f", mult)
    end
    local manip_label = t.t(MANIP_LABELS[manip_state] or manip_state)
    if info.scan_cached and (manip_state == "ready" or manip_state == "blocked") then
        manip_label = manip_label .. " *"
    end

    local pad_x, pad_y = 10, 6
    local row_h = 14
    local bar_h = 5
    local title = t.t("BULLET STATUS")
    local title_w = theme.text_w(title, 11)
    local on_txt = t.t("ON")
    local off_txt = t.t("OFF")
    local hitscan_l = t.t("Hitscan")
    local tp_l = t.t("Bullet TP")
    local manip_l = t.t("Manip")
    local hitbox_l = t.t("Hitbox")
    local fire_l = t.t("Fire")
    local peek_l = t.t("Peek R")
    local ring_l = t.t("Ring")
    local scan_l = t.t("TP Scan")

    local hitbox_mult = tonumber(info.hitbox_mult) or 1
    local hitbox_txt = hitbox_on and string.format("%s x%.1f", on_txt, hitbox_mult) or off_txt

    local radius_text = fmt_radius(info)
    local ring_text = "-"
    if manip_on and info.radii_total and info.radius_idx then
        ring_text = string.format("%d/%d", info.radius_idx, info.radii_total)
    elseif manip_on and manip_state == "ready" then
        ring_text = "hit"
    elseif manip_on and manip_state == "direct" then
        ring_text = "los"
    end

    local tp_scan_txt = "-"
    if tp_on then
        if info.tp_scan_visible then
            tp_scan_txt = t.t("Visible")
        else
            local prog = math.max(0, math.min(1, info.tp_scan_progress or 0))
            tp_scan_txt = string.format("%d%%", math.floor(prog * 100 + 0.5))
        end
    end

    local w1 = theme.text_w(hitscan_l, 10) + theme.text_w(on_txt, 10) + 24
    local w2 = theme.text_w(tp_l, 10) + theme.text_w(on_txt, 10) + 24
    local w3 = theme.text_w(hitbox_l, 10) + theme.text_w(hitbox_txt, 10) + 24
    local w4 = theme.text_w(manip_l, 10) + theme.text_w(manip_label, 10) + 24
    local w5 = theme.text_w(fire_l, 10) + theme.text_w(fire_label, 10) + 24
    local w6 = theme.text_w(peek_l, 10) + theme.text_w(radius_text, 10) + 24
    local w7 = theme.text_w(ring_l, 10) + theme.text_w(ring_text, 10) + 24
    local w8 = theme.text_w(scan_l, 10) + theme.text_w(tp_scan_txt, 10) + 24
    local panel_w = math.max(title_w, w1, w2, w3, w4, w5, w6, w7, w8) + pad_x * 2 + 8
    panel_w = math.max(panel_w, 188)

    local rows = 5 -- hitscan, tp, hitbox, manip, fire
    if tp_on then rows = rows + 1 end
    if manip_on then rows = rows + 2 end

    local has_bar = (manip_on and (
        manip_state == "scanning" or manip_state == "ready" or manip_state == "direct"
    )) or (tp_on and fire_mode == "tp")
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

    draw_row(hitscan_l, hitscan_on and on_txt or off_txt, row_color(hitscan_on, true, false))
    draw_row(tp_l, tp_on and on_txt or off_txt, row_color(tp_on, true, false))
    draw_row(hitbox_l, hitbox_txt, row_color(hitbox_on, true, false))

    local manip_ok = manip_state == "ready" or manip_state == "direct"
    local manip_warn = manip_state == "scanning"
    draw_row(manip_l, manip_on and manip_label or off_txt,
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
    elseif fire_mode == "off" and hitbox_on and not hitscan_on and not tp_on and not manip_on then
        fire_label = t.t("Override")
        fire_col = theme.GREEN
    end
    draw_row(fire_l, fire_label, fire_col)

    if tp_on then
        draw_row(scan_l, tp_scan_txt, info.tp_scan_visible and theme.GREEN or overlay_theme.text())
    end

    if manip_on then
        draw_row(peek_l, radius_text, overlay_theme.text())
        draw_row(ring_l, ring_text, overlay_theme.text())
    end

    if has_bar then
        local bar_w = panel_w - pad_x * 2
        local bar_x = x + pad_x
        local bar_y = ry + 2
        local ready = manip_state == "ready" or manip_state == "direct" or info.tp_scan_visible == true
        local prog
        if ready and not (tp_on and fire_mode == "tp" and manip_state == "scanning") then
            if tp_on and fire_mode == "tp" then
                prog = info.tp_scan_visible and 1 or math.max(0, math.min(1, info.tp_scan_progress or 0))
            else
                prog = 1
            end
        elseif manip_state == "scanning" then
            local real = math.max(0, math.min(1, info.scan_progress or 0))
            prog = math.max(0.08, real * 0.85 + scan_anim * 0.12)
        elseif tp_on and fire_mode == "tp" then
            local real = math.max(0, math.min(1, info.tp_scan_progress or 0))
            prog = math.max(0.08, real * 0.9 + scan_anim * 0.08)
        else
            prog = math.max(0, math.min(1, info.scan_progress or info.tp_scan_progress or 0))
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
    if not info then return end

    local body = combat_origin.get_server_origin()
    if not body then return end

    -- While scanning, show a soft range ring so the search feels alive.
    if info.manip_on and info.manip_state == "scanning" then
        local r = tonumber(info.radius) or tonumber(info.base_radius) or 1
        local col = { 1, 0.75, 0.2, 0.35 + scan_anim * 0.25 }
        desync_vis.draw_cross(body.x, body.y + manip_math.eye_offset_y(), body.z, 0.45, col, 1)
        desync_vis.draw_sphere_ring(body.x, body.y, body.z, r, col, 1)
    end

    if not info.peek then return end
    if info.manip_state ~= "ready" and info.manip_state ~= "direct" and not info.body_peek then
        return
    end

    local peek = info.peek
    local col_peek = info.body_peek and { 0.45, 1, 0.55, 0.95 } or { 1, 0.85, 0.2, 0.95 }
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
    if not settings.enabled(P_BULLET) then return end
    if not draw then return end

    local info = track and track.manip
    -- Hitbox-only: synthesize a minimal info blob so Status HUD still renders.
    if not info then
        local hitbox_on = settings.bool("april_thick_bullet", false)
        if not hitbox_on then return end
        local mult = tonumber(settings.num("april_thick_bullet_mult", 2)) or 2
        info = {
            state = "off",
            manip_state = "off",
            hitscan_on = false,
            tp_on = false,
            manip_on = false,
            hitbox_on = true,
            hitbox_mult = mult,
        }
    elseif info.hitbox_on == nil then
        info.hitbox_on = settings.bool("april_thick_bullet", false)
        info.hitbox_mult = tonumber(settings.num("april_thick_bullet_mult", 2)) or 2
    end

    local show_hud = settings.bool(PREFIX .. "manip_status", false)
    local show_peek = settings.bool(PREFIX .. "manip_peek_vis", false)
    if not show_hud and not show_peek then return end

    draw_peek_visual(info, track)
    draw_status_panel(cx, cy, fov, info)
end

return M
