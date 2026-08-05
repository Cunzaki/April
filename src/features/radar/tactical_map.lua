local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local cache = April.require("core.cache")
local env = April.require("core.env")
local ep = April.require("core.entity_props")
local player_state = April.require("game.player_state")
local menu_util = April.require("core.menu_util")
local esp_scan = April.require("game.esp_scan")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local panel_drag = April.require("core.panel_drag")
local map_image = April.require("game.map_image")
local math_util = April.require("core.math_util")
local npcs = April.require("game.npcs")

local M = {}
local P = "april_map_enabled"
local X_ID = "april_map_x"
local Y_ID = "april_map_y"
-- Compact chrome: thin title band above the map (not over it).
local TITLE_H = 16
local EDGE = 2
-- Studs visible across the radar diameter at zoom = 1 (north-up texture mode).
local BASE_VISIBLE_STUDS = 3200

-- Relative blip sizes vs april_map_icon_scale. Players/bosses read larger.
local SIZE_MULT = {
    player = 1.65,
    boss = 1.55,
    raid = 1.35,
    waypoint = 1.2,
    npc = 1.1,
    loot = 0.95,
    world = 0.85,
    base = 0.9,
    self = 1.7,
}

local function position_xyz(pos)
    if not pos then return nil, nil, nil end
    return pos.x or pos.X, pos.y or pos.Y, pos.z or pos.Z
end

local function ensure_draw_api()
    pcall(function()
        April.require("core.api_aliases").apply()
    end)
end

local function radar_opacity()
    local pct = tonumber(settings.num("april_map_opacity", 100)) or 100
    if pct < 15 then pct = 15 end
    if pct > 100 then pct = 100 end
    return pct / 100
end

-- Scale alpha only. Keep RGB intact — Vector shadows every primitive, and
-- darkening RGB toward zero makes the auto-shadow read as a milky wash.
local function fade_col(col, opacity)
    if type(col) ~= "table" then return col end
    opacity = tonumber(opacity) or 1
    if opacity < 0 then opacity = 0 end
    if opacity > 1 then opacity = 1 end
    return {
        col[1] or 1,
        col[2] or 1,
        col[3] or 1,
        (col[4] or 1) * opacity,
    }
end

-- Local atan2 so a missing math_util.atan2 never kills the radar frame.
local function atan2(y, x)
    if math_util and type(math_util.atan2) == "function" then
        return math_util.atan2(y, x)
    end
    y, x = y or 0, x or 0
    if type(math.atan2) == "function" then
        return math.atan2(y, x)
    end
    local ok, result = pcall(math.atan, y, x)
    if ok and type(result) == "number" then
        return result
    end
    return 0
end

local function call_api(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
    return nil
end

local function camera_fn(snake, pascal)
    if not camera then return nil end
    local fn = camera[snake] or camera[pascal]
    if type(fn) == "function" then return fn end
    return nil
end

-- North-up facing: screen up = world -Z. atan2(look.X, -look.Z).
local function get_facing_angle()
    local lv = call_api(camera_fn("get_look_vector", "GetLookVector"))
    if lv then
        local lx = lv.x or lv.X or 0
        local lz = lv.z or lv.Z or 0
        if math.abs(lx) > 0.001 or math.abs(lz) > 0.001 then
            return atan2(lx, -lz)
        end
    end
    local a = call_api(camera_fn("get_angles", "GetAngles"))
    if a then
        local deg = a.Y or a.y
        if deg then return math.rad(deg) end
    end
    return 0
end

local function get_camera_yaw()
    local a = call_api(camera_fn("get_angles", "GetAngles"))
    if a then
        local deg = a.Y or a.y
        if deg then return math.rad(deg) end
    end
    local util_angles = utility and (utility.get_camera_angles or utility.GetCameraAngles)
    if type(util_angles) == "function" then
        local ok, _, yaw = pcall(util_angles)
        if ok and yaw then return math.rad(yaw) end
    end
    local lv = call_api(camera_fn("get_look_vector", "GetLookVector"))
    if lv then
        local lx, lz = lv.x or lv.X or 0, lv.z or lv.Z or 0
        if math.abs(lx) > 0.001 or math.abs(lz) > 0.001 then
            return atan2(lx, lz)
        end
    end
    return 0
end

local function get_view_origin()
    local cx, cy, cz = nil, nil, nil
    local pos = call_api(camera_fn("get_position", "GetPosition"))
    if pos and (pos.x or pos.X) then
        cx = pos.x or pos.X
        cy = pos.y or pos.Y
        cz = pos.z or pos.Z
    end

    local lp = cache.local_player or env.get_local_player()
    local px, py, pz = nil, nil, nil
    if lp then
        px, py, pz = position_xyz(ep.position(lp))
    end

    if not cx then cx, cy, cz = px, py, pz end
    return cx or 0, cy or 0, cz or 0, px, py, pz
end

local function map_basis(yaw)
    local fx, fz = math.sin(yaw), math.cos(yaw)
    local rx, rz = -math.cos(yaw), math.sin(yaw)
    return fx, fz, rx, rz
end

local function world_to_map_yaw(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    local wdx = wx - view_x
    local wdz = wz - view_z
    local fx, fz, rx, rz = map_basis(yaw)
    local local_fwd = wdx * fx + wdz * fz
    local local_right = wdx * rx + wdz * rz
    return map_cx + local_right * zoom, map_cy - local_fwd * zoom
end

-- Project world XZ onto the radar using the active north-up viewport crop.
local function world_to_map_north(wx, wz, view)
    if view.vp and view.map_rect then
        local su, sv = map_image.world_to_viewport(wx, wz, view.vp)
        if not su or not sv then return nil, nil end
        local r = view.map_rect
        return r.x + su * r.w, r.y + sv * r.h
    end
    local u, v = map_image.world_to_uv(wx, wz)
    return view.img_x + u * view.img_size, view.img_y + v * view.img_size
end

local function clamp_to_disc(mx, my, cx, cy, radius)
    local dx, dy = mx - cx, my - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= radius or dist < 0.001 then
        return mx, my, false
    end
    local s = radius / dist
    return cx + dx * s, cy + dy * s, true
end

local function in_map_rect(mx, my, view, margin)
    local r = view.map_rect
    if not r then return true end
    margin = margin or 2
    return mx >= r.x - margin and my >= r.y - margin
        and mx <= r.x + r.w + margin and my <= r.y + r.h + margin
end

local function entry_world_xz(entry)
    if not entry then return nil, nil end
    local lx, _, lz = esp_scan.entry_coords(entry)
    if lx and lz then return lx, lz end
    if entry.lx and entry.lz then return entry.lx, entry.lz end
    if entry.pos then return entry.pos.x, entry.pos.z end
    local inst = entry.inst
    if inst and env.is_valid(inst) then
        local pos = inst.Position or inst.position
        if pos and pos.x then return pos.x, pos.z end
    end
    return nil, nil
end

local function short_label(text)
    if text == nil then return "" end
    text = tostring(text)
    if text == "" then return "" end
    text = text:gsub("%s*%(Sleeper%)", "")
    if #text > 10 then
        return text:sub(1, 9) .. ".."
    end
    return text
end

local function blip_scale(base, kind)
    local mult = SIZE_MULT[kind or "npc"] or 1
    return math.max(2, (base or 3) * mult)
end

local function label_font_for_scale(scale)
    return math.max(8, math.min(16, math.floor((scale or 3) * 2.1 + 1.5)))
end

local function draw_radar_label(lx, ly, text, col, x, y, w, h, fs)
    if not text or text == "" or not draw then return end
    fs = fs or 9
    local tw = theme.text_w(text, fs)
    local th = fs + 2
    lx = lx - tw * 0.5
    ly = ly + math.max(4, fs * 0.45)
    if lx < x + 4 then lx = x + 4 end
    if lx + tw > x + w - 4 then lx = x + w - 4 - tw end
    if ly + th > y + h - 4 then ly = ly - th - 8 end
    if ly < y + 4 then return end
    draw_util.text(lx, ly, text, col, fs)
end

local function draw_fn(snake, pascal)
    if not draw then return nil end
    local fn = draw[snake] or draw[pascal]
    if type(fn) == "function" then return fn end
    return nil
end

local function draw_blip(mx, my, scale, col, clamped, shape)
    if type(col) ~= "table" then col = theme.CYAN end
    local alpha = clamped and 0.72 or 1
    local c = {
        col[1] or 1, col[2] or 1, col[3] or 1,
        (col[4] or 1) * alpha,
    }
    local r = math.max(2, scale - (clamped and 1 or 0))
    local edge = theme.alpha(theme.PANEL_DEEP, math.min(0.42, c[4] * 0.42))
    shape = shape or "circle"

    local rect_f = draw_fn("rect_filled", "RectFilled")
    local poly = draw_fn("poly_filled", "PolyFilled")
    local circ_f = draw_fn("circle_filled", "CircleFilled")

    if shape == "square" and rect_f then
        pcall(rect_f, mx - r - 1, my - r - 1, (r + 1) * 2, (r + 1) * 2, edge, 0)
        pcall(rect_f, mx - r, my - r, r * 2, r * 2, c, 0)
    elseif shape == "diamond" and poly then
        pcall(poly, {
            { mx, my - r - 1 }, { mx + r + 1, my },
            { mx, my + r + 1 }, { mx - r - 1, my },
        }, edge)
        pcall(poly, {
            { mx, my - r }, { mx + r, my },
            { mx, my + r }, { mx - r, my },
        }, c)
    elseif shape == "waypoint" and circ_f then
        pcall(circ_f, mx, my, r + 2, edge, 12)
        pcall(circ_f, mx, my, r + 1, c, 12)
        pcall(circ_f, mx, my, math.max(1, r - 1), theme.alpha(theme.PANEL_DEEP, c[4] or 1), 10)
    elseif circ_f then
        pcall(circ_f, mx, my, r + 1, edge, 10)
        pcall(circ_f, mx, my, r, c, 10)
    else
        draw_util.circle(mx, my, r, c, true)
    end
end

local function project_blip(wx, wz, view)
    if view.mode == "north" then
        return world_to_map_north(wx, wz, view)
    end
    return world_to_map_yaw(wx, wz, view.view_x, view.view_z, view.cx, view.cy, view.zoom, view.yaw)
end

local function draw_map_item(wx, wz, col, label, shape, view, scale, layout, size_kind)
    if not wx or not wz then return end

    local mx, my = project_blip(wx, wz, view)
    if not mx or not my then return end

    local clamped = false
    if view.mode == "north" and view.map_rect then
        if not in_map_rect(mx, my, view, 0) then
            mx, my, clamped = clamp_to_disc(mx, my, layout.cx, layout.cy, layout.radius)
            if not in_map_rect(mx, my, view, 4) then
                return
            end
        end
    else
        mx, my, clamped = clamp_to_disc(mx, my, layout.cx, layout.cy, layout.radius)
    end

    local opacity = layout and layout.opacity or 1
    col = fade_col(col, opacity)
    local size = blip_scale(scale, size_kind)
    draw_blip(mx, my, size, col, clamped, shape)

    if settings.bool("april_map_labels", false) and not clamped then
        draw_radar_label(
            mx, my, short_label(label), col,
            layout.x, layout.y, layout.w, layout.h,
            label_font_for_scale(size)
        )
    end
end

local function draw_radar_base(layout, bg, opacity, has_map)
    local x, y, w, h = layout.x, layout.y, layout.w, layout.h
    local map_rect = layout.map_rect
    opacity = opacity or 1
    -- Sharp corners so the frame matches the square map (no soft/notched edges).
    overlay_theme.draw_panel(x, y, w, h, nil, {
        opacity = opacity,
        rounding = 0,
        border = true,
        border_w = 1,
    })
    if not has_map and map_rect then
        local rect_f = draw_fn("rect_filled", "RectFilled")
        if rect_f then
            pcall(rect_f, map_rect.x, map_rect.y, map_rect.w, map_rect.h,
                fade_col(bg or theme.PANEL_DEEP, 0.55 * opacity), 0)
        end
    end
end

local function draw_radar_labels(layout, zoom, opacity)
    local x, y, w = layout.x, layout.y, layout.w
    opacity = opacity or 1
    local rect_f = draw_fn("rect_filled", "RectFilled")
    if rect_f then
        -- Solid title band above the map (does not cover map pixels).
        pcall(rect_f, x + 1, y + 1, w - 2, TITLE_H - 1,
            fade_col(overlay_theme.panel_bg(), opacity), 0)
    end
    local title_col = fade_col(overlay_theme.text(), opacity)
    local zoom_col = fade_col(theme.TEXT_DIM, opacity)
    draw_util.text(x + EDGE + 4, y + 3, "RADAR", title_col, 10)
    local zoom_text = string.format("x%.2f", tonumber(zoom) or 1)
    local zoom_w = theme.text_w(zoom_text, 9)
    draw_util.text(x + w - EDGE - 4 - zoom_w, y + 4, zoom_text, zoom_col, 9)
end

-- Facing arrow. tip points along `ang` (0 = screen up / north).
local function draw_facing_arrow(mx, my, col, scale, ang, opacity)
    if type(col) ~= "table" then col = theme.CYAN end
    col = fade_col(col, opacity or 1)
    local r = (scale or 3) + 2
    ang = ang or 0
    local function pt(dist, offset)
        local a = ang + (offset or 0)
        return mx + math.sin(a) * dist, my - math.cos(a) * dist
    end
    local tx, ty = pt(r + 2, 0)
    local lx, ly = pt(r * 0.85, 2.4)
    local rx, ry = pt(r * 0.85, -2.4)
    local bx, by = pt(r * 0.25, math.pi)

    local poly = draw_fn("poly_filled", "PolyFilled")
    if poly then
        local ok = pcall(poly, {
            { tx, ty }, { lx, ly }, { bx, by }, { rx, ry },
        }, col)
        if ok then
            local circle = draw_fn("circle", "Circle")
            if circle then
                pcall(circle, mx, my, r + 3, fade_col(col, 0.28), 20, 1)
            end
            return
        end
    end
    local line = draw_fn("line", "Line")
    if line then
        pcall(line, tx, ty, lx, ly, col, 2)
        pcall(line, lx, ly, bx, by, col, 2)
        pcall(line, bx, by, rx, ry, col, 2)
        pcall(line, rx, ry, tx, ty, col, 2)
    else
        local circ_f = draw_fn("circle_filled", "CircleFilled")
        if circ_f then
            pcall(circ_f, mx, my, r, col, 12)
        end
    end
end

-- Player-centered north-up view. Map pans under the local player.
-- Scale against the square panel span so chunks fill the radar body (not just the inscribed circle).
local function build_north_view(cx, cy, radius, zoom, body_x, body_z, map_rect)
    local visible = BASE_VISIBLE_STUDS / math.max(zoom, 0.05)
    local span = math.max(map_rect.w or 0, map_rect.h or 0, (radius or 0) * 2)
    local pixels_per_stud = span / visible
    local world = map_image.world_size()
    local img_size = world * pixels_per_stud
    local pu, pv = map_image.world_to_uv(body_x or 0, body_z or 0)
    return {
        mode = "north",
        centered = true,
        cx = cx,
        cy = cy,
        zoom = zoom,
        img_size = img_size,
        img_x = cx - pu * img_size,
        img_y = cy - pv * img_size,
        view_x = body_x or 0,
        view_z = body_z or 0,
        yaw = 0,
        map_rect = map_rect,
        vp = nil,
    }
end

local function build_yaw_view(cx, cy, zoom, yaw, view_x, view_z)
    return {
        mode = "yaw",
        cx = cx,
        cy = cy,
        zoom = zoom,
        yaw = yaw,
        view_x = view_x,
        view_z = view_z,
    }
end

local function attach_map_texture(view, opacity)
    if not view or not view.map_rect then
        return false
    end
    local map_a = 0.92 * (opacity or 1)
    local ok, mode = pcall(map_image.draw_centered, view, view.map_rect, map_a)
    if not ok or not mode then
        return false
    end
    if mode == "crop" then
        -- map_image supplies the exact crop viewport used by the displayed PNG.
        view.texture_mode = "crop"
    else
        -- Fit only when the full world is visible — UVs span the radar square.
        view.vp = { u0 = 0, v0 = 0, u1 = 1, v1 = 1, ready = true }
        view.texture_mode = "fit"
    end
    return true
end

-- Repaint panel padding/title and map guides after the bounded image.
-- Do NOT refill map_rect (draw_panel would wipe the map).
local function cover_map_overflow(layout, map_rect, zoom, _north_up, opacity)
    local rect_f = draw_fn("rect_filled", "RectFilled")
    if not rect_f then return end
    local x, y, w, h = layout.x, layout.y, layout.w, layout.h
    opacity = opacity or 1
    local fill = fade_col(overlay_theme.panel_bg(), opacity)

    -- Title bar strip (includes top padding above map_rect)
    local title_h = math.max(TITLE_H + 3, map_rect.y - y)
    pcall(rect_f, x, y, w, title_h, fill, 0)

    local left_w = math.max(0, map_rect.x - x)
    local right_x = map_rect.x + map_rect.w
    local right_w = math.max(0, x + w - right_x)
    local bottom_y = map_rect.y + map_rect.h
    local bottom_h = math.max(0, y + h - bottom_y)
    if left_w > 0 then
        pcall(rect_f, x, map_rect.y, left_w, map_rect.h + bottom_h, fill, 0)
    end
    if right_w > 0 then
        pcall(rect_f, right_x, map_rect.y, right_w, map_rect.h + bottom_h, fill, 0)
    end
    if bottom_h > 0 then
        pcall(rect_f, map_rect.x, bottom_y, map_rect.w, bottom_h, fill, 0)
    end

    -- Re-draw title / zoom on top of the covered strips.
    draw_util.text(x + 12, y + 8, "RADAR", fade_col(overlay_theme.text(), opacity), 11)
    local zoom_text = string.format("x%.2f", tonumber(zoom) or 1)
    local zoom_w = theme.text_w(zoom_text, 9)
    draw_util.text(x + w - zoom_w - 11, y + 8, zoom_text, fade_col(theme.TEXT_DIM, opacity), 9)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)

    menu_util.section(T, G.RADAR, "Tactical Map")
    menu_util.register_keybind(T, G.RADAR, P, "Enable Radar", false, { key = 0x28 })

    menu.add_checkbox(T, G.RADAR, "april_map_show_players", "Radar Show Players", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_npcs", "Radar Show NPCs", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_loot", "Radar Show Loot", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_world", "Radar Show Resources", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_base", "Radar Show Base Parts", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_waypoints", "Radar Show Waypoints", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_raids", "Radar Show Raids", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_labels", "Radar Show Labels", false, root)

    menu.add_colorpicker(T, G.RADAR, "april_map_player_col", "Radar Players Color", theme.RED, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_npc_col", "Radar NPCs Color", theme.ORANGE, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_loot_col", "Radar Loot Color", { 1, 0.85, 0.35, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_world_col", "Radar Resources Color", theme.GREEN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_base_col", "Radar Base Color", { 0.55, 0.55, 1, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_wp_col", "Radar Waypoints Color", theme.CYAN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_raid_col", "Radar Raids Color", { 1, 0.5, 0, 1 }, root)

    menu_util.gap(T, G.RADAR)
    menu.add_slider_int(T, G.RADAR, "april_map_zoom", "Radar Zoom Level", 0.05, 5.0, 1.0, "%.2f", root)
    menu.add_slider_int(T, G.RADAR, "april_map_size", "Radar Size", 140, 420, 250, root)
    menu.add_slider_int(T, G.RADAR, "april_map_opacity", "Radar Opacity", 15, 100, 100, root)
    menu.add_slider_int(T, G.RADAR, "april_map_icon_scale", "Radar Blip Size", 2, 6, 3, root)
    menu_util.button(T, G.RADAR, "april_map_reset_position", "Reset Radar Position", function()
        local sw = select(1, draw_util.screen_size())
        local size = settings.num("april_map_size", 250)
        local rx, ry = sw - size - 16, 16
        if menu and menu.set then
            pcall(menu.set, X_ID, rx)
            pcall(menu.set, Y_ID, ry)
        end
        pcall(function()
            local state = April.require("ui.gs_state")
            state.set(X_ID, rx)
            state.set(Y_ID, ry)
        end)
    end)

    menu_util.bind_children(P, {
        "april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
        "april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
        "april_map_show_raids", "april_map_labels",
        "april_map_player_col", "april_map_npc_col",
        "april_map_loot_col", "april_map_world_col", "april_map_base_col",
        "april_map_wp_col", "april_map_raid_col",
        "april_map_zoom", "april_map_size", "april_map_opacity",
        "april_map_icon_scale", "april_map_reset_position",
    })
end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw then return end
    local debug = April.require("core.debug")
    debug.guard("radar:draw", M.draw_inner)
end

function M.draw_inner()
    ensure_draw_api()

    local sw, sh = draw_util.screen_size()
    local size = settings.num("april_map_size", 250)
    local default_x, default_y = sw - size - 16, 16
    local x, y = panel_drag.update(
        "tactical_radar", X_ID, Y_ID, size, TITLE_H, sw, sh, default_x, default_y
    )
    x, y = panel_drag.clamp(x, y, size, size, sw, sh, X_ID, Y_ID)
    local w, h = size, size
    -- Title band sits above the map so labels never cover terrain.
    local map_y = y + TITLE_H
    local map_w = math.max(32, size - EDGE * 2)
    local map_h = math.max(32, size - TITLE_H - EDGE)
    local map_rect = {
        x = x + EDGE,
        y = map_y,
        w = map_w,
        h = map_h,
    }
    local cx = map_rect.x + map_rect.w * 0.5
    local cy = map_rect.y + map_rect.h * 0.5
    local radius = math.min(map_rect.w, map_rect.h) * 0.5 - 4
    local zoom = settings.num("april_map_zoom", 1.0)
    local scale = settings.num("april_map_icon_scale", 3)
    local opacity = radar_opacity()

    local layout = {
        x = x, y = y, w = w, h = h, cx = cx, cy = cy,
        radius = radius, label_radius = math.max(24, radius - 28), scale = scale,
        opacity = opacity,
        map_rect = map_rect,
    }

    local bg = theme.MAP_BG or theme.PANEL_DEEP
    local grid = theme.MAP_GRID or theme.BORDER

    local cam_x, _, cam_z, body_x, _, body_z = get_view_origin()
    local yaw = get_camera_yaw()
    local facing = get_facing_angle()
    local view_x, view_z = body_x or cam_x, body_z or cam_z

    -- World map is the default. Classic rotating radar only if the texture fails
    -- (map_image retries the download every 30s on its own).
    local north_up = false
    local view
    map_image.ensure()
    if map_image.ready() then
        north_up = true
        view = build_north_view(cx, cy, radius, zoom, view_x, view_z, map_rect)
    end
    if not view then
        view = build_yaw_view(cx, cy, zoom, yaw, view_x, view_z)
    end

    local will_draw_map = north_up and map_image.ready()
    draw_radar_base(layout, bg, opacity, will_draw_map)
    if north_up then
        attach_map_texture(view, opacity)
    end
    draw_radar_labels(layout, zoom, opacity)

    if settings.bool("april_map_show_world", false) then
        local col = settings.color("april_map_world_col", theme.GREEN)
        local items = cache.spatial.world and cache.spatial.world.all or cache.world or {}
        for _, item in ipairs(items) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "diamond", view, scale, layout, "world")
                end
            end
        end
    end

    if settings.bool("april_map_show_loot", false) then
        local col = settings.color("april_map_loot_col", { 1, 0.85, 0.35, 1 })
        local items = cache.spatial.loot and cache.spatial.loot.all or cache.loot or {}
        for _, item in ipairs(items) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "square", view, scale, layout, "loot")
                end
            end
        end
    end

    if settings.bool("april_map_show_base", false) then
        local col = settings.color("april_map_base_col", { 0.55, 0.55, 1, 1 })
        local items = cache.spatial.base and cache.spatial.base.all or cache.base or {}
        for _, item in ipairs(items) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "diamond", view, scale, layout, "base")
                end
            end
        end
    end

    if settings.bool("april_map_show_npcs", false) then
        local col = settings.color("april_map_npc_col", theme.ORANGE)
        for _, entry in ipairs(cache.npcs or {}) do
            if env.is_valid(entry.inst) then
                local wx, wz = entry_world_xz(entry)
                if wx then
                    local kind = entry.kind or npcs.kind(entry.name)
                    local size_kind = npcs.is_boss_kind(kind) and "boss" or "npc"
                    draw_map_item(wx, wz, col, entry.name, "circle", view, scale, layout, size_kind)
                end
            end
        end
    end

    if settings.bool("april_map_show_waypoints", false) then
        local col = settings.color("april_map_wp_col", theme.CYAN)
        for i, wp in pairs(cache.waypoints or {}) do
            if wp and wp.pos then
                draw_map_item(wp.pos.x, wp.pos.z, col, wp.name or ("WP" .. i), "waypoint", view, scale, layout, "waypoint")
            end
        end
    end

    if settings.bool("april_map_show_raids", false) then
        local col = settings.color("april_map_raid_col", { 1, 0.5, 0, 1 })
        for _, raid in ipairs(cache.raids or {}) do
            if raid and raid.x and raid.z then
                local label = "Raid"
                if raid.count and raid.count > 1 then
                    label = string.format("Raid (%d)", raid.count)
                end
                draw_map_item(raid.x, raid.z, col, label, "diamond", view, scale, layout, "raid")
            end
        end
    end

    if settings.bool("april_map_show_players", false) then
        local col = settings.color("april_map_player_col", theme.RED)
        for _, p in ipairs(cache.players or {}) do
            local px, _, pz = position_xyz(ep.position(p))
            if player_state.is_combat_target(p) and px and pz then
                local label = ep.display_name(p) or ep.name(p)
                draw_map_item(px, pz, col, label, "circle", view, scale, layout, "player")
            end
        end
    end

    -- Local player on the north-up map; arrow rotates with facing.
    local arrow_x, arrow_y = cx, cy
    if north_up and view_x and view_z then
        local ax, ay = world_to_map_north(view_x, view_z, view)
        if ax and ay then
            arrow_x, arrow_y = ax, ay
        end
    end
    local arrow_ang = north_up and facing or 0
    draw_facing_arrow(
        arrow_x, arrow_y, overlay_theme.accent(),
        blip_scale(scale, "self"), arrow_ang, opacity
    )
end

return M
