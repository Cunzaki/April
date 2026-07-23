local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local cache = April.require("core.cache")
local env = April.require("core.env")
local player_state = April.require("game.player_state")
local menu_util = April.require("core.menu_util")
local esp_scan = April.require("game.esp_scan")
local theme = April.require("core.ui_theme")
local overlay_theme = April.require("core.overlay_theme")
local panel_drag = April.require("core.panel_drag")

local M = {}
local P = "april_map_enabled"
local X_ID = "april_map_x"
local Y_ID = "april_map_y"
local TITLE_H = 24

local function get_camera_yaw()
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local deg = a.Y or a.y
            if deg then return math.rad(deg) end
        end
    end
    if utility and utility.get_camera_angles then
        local ok, _, yaw = pcall(utility.get_camera_angles)
        if ok and yaw then return math.rad(yaw) end
    end
    if camera and camera.get_look_vector then
        local ok, lv = pcall(camera.get_look_vector)
        if ok and lv then
            local lx, lz = lv.x or lv.X or 0, lv.z or lv.Z or 0
            if math.abs(lx) > 0.001 or math.abs(lz) > 0.001 then
                return math.atan2(lx, lz)
            end
        end
    end
    return 0
end

local function get_view_origin()
    local cx, cy, cz = nil, nil, nil
    if camera and camera.get_position then
        local ok, pos = pcall(camera.get_position)
        if ok and pos and (pos.x or pos.X) then
            cx = pos.x or pos.X
            cy = pos.y or pos.Y
            cz = pos.z or pos.Z
        end
    end

    local lp = env.get_local_player()
    local px, py, pz = nil, nil, nil
    if lp and lp.position then
        px = lp.position.x
        py = lp.position.y
        pz = lp.position.z
    end

    if not cx then cx, cy, cz = px, py, pz end
    return cx or 0, cy or 0, cz or 0, px, py, pz
end

local function map_basis(yaw)
    local fx, fz = math.sin(yaw), math.cos(yaw)
    local rx, rz = -math.cos(yaw), math.sin(yaw)
    return fx, fz, rx, rz
end

local function world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    local wdx = wx - view_x
    local wdz = wz - view_z
    local fx, fz, rx, rz = map_basis(yaw)
    local local_fwd = wdx * fx + wdz * fz
    local local_right = wdx * rx + wdz * rz
    return map_cx + local_right * zoom, map_cy - local_fwd * zoom
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
    if not text or text == "" then return "" end
    text = text:gsub("%s*%(Sleeper%)", "")
    if #text > 10 then
        return text:sub(1, 9) .. ".."
    end
    return text
end

local function draw_radar_label(lx, ly, text, col, x, y, w, h, fs)
    if not text or text == "" or not draw or not draw.get_text_size then return end
    fs = fs or 9
    local tw = select(1, draw.get_text_size(text, fs))
    local th = fs + 2
    lx = lx - tw * 0.5
    ly = ly + 5
    if lx < x + 4 then lx = x + 4 end
    if lx + tw > x + w - 4 then lx = x + w - 4 - tw end
    if ly + th > y + h - 4 then ly = ly - th - 8 end
    if ly < y + 4 then return end

    if draw.rect_filled then
        draw.rect_filled(lx - 3, ly - 2, tw + 6, th + 2, theme.PANEL_DEEP, 0)
    end
    if draw.rect then
        draw.rect(lx - 3, ly - 2, tw + 6, th + 2, theme.BORDER, 0, 1)
    end
    draw_util.text(lx, ly, text, col, fs)
end

local function draw_blip(mx, my, scale, col, clamped, shape)
    local alpha = clamped and 0.72 or 1
    local c = { col[1], col[2], col[3], (col[4] or 1) * alpha }
    local r = math.max(2, scale - (clamped and 1 or 0))
    local edge = theme.alpha(theme.PANEL_DEEP, math.min(0.95, c[4]))
    shape = shape or "circle"

    if shape == "square" and draw and draw.rect_filled then
        draw.rect_filled(mx - r - 1, my - r - 1, (r + 1) * 2, (r + 1) * 2, edge, 0)
        draw.rect_filled(mx - r, my - r, r * 2, r * 2, c, 0)
    elseif shape == "diamond" and draw and draw.poly_filled then
        draw.poly_filled({
            { mx, my - r - 1 }, { mx + r + 1, my },
            { mx, my + r + 1 }, { mx - r - 1, my },
        }, edge)
        draw.poly_filled({
            { mx, my - r }, { mx + r, my },
            { mx, my + r }, { mx - r, my },
        }, c)
    elseif shape == "waypoint" and draw and draw.circle_filled then
        draw.circle_filled(mx, my, r + 2, edge, 12)
        draw.circle_filled(mx, my, r + 1, c, 12)
        draw.circle_filled(mx, my, math.max(1, r - 1), theme.PANEL_DEEP, 10)
    elseif draw and draw.circle_filled then
        draw.circle_filled(mx, my, r + 1, edge, 10)
        draw.circle_filled(mx, my, r, c, 10)
    else
        draw_util.circle(mx, my, r, c, true)
    end
end

local function draw_map_item(wx, wz, col, label, shape, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, layout)
    if not wx or not wz then return end

    local mx, my = world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    local clamped
    mx, my, clamped = clamp_to_disc(mx, my, map_cx, map_cy, layout.radius)

    draw_blip(mx, my, scale, col, clamped, shape)

    if settings.bool("april_map_labels", false) and not clamped then
        draw_radar_label(mx, my, short_label(label), col, layout.x, layout.y, layout.w, layout.h, 9)
    end
end

local function draw_radar_frame(layout, bg, grid, zoom)
    local x, y, w, h = layout.x, layout.y, layout.w, layout.h
    local cx, cy = layout.cx, layout.cy

    overlay_theme.draw_panel(x, y, w, h, "TACTICAL RADAR")

    if draw.rect_filled then
        draw.rect_filled(x + 7, y + TITLE_H + 5, w - 14, h - TITLE_H - 12, bg, 0)
    end
    if draw.rect then
        draw.rect(x + 7, y + TITLE_H + 5, w - 14, h - TITLE_H - 12, theme.BORDER, 0, 1)
    end

    local zoom_text = string.format("x%.2f", zoom)
    local zoom_w = theme.text_w(zoom_text, 9)
    draw_util.text(x + w - zoom_w - 8, y + 7, zoom_text, theme.TEXT_DIM, 9)

    if draw and draw.circle then
        draw.circle(cx, cy, layout.radius, theme.alpha(grid, 0.42), 24, 1)
        draw.circle(cx, cy, layout.radius * 0.66, grid, 24, 1)
        draw.circle(cx, cy, layout.radius * 0.33, grid, 24, 1)
    end
    if draw and draw.line then
        draw.line(cx - layout.radius, cy, cx + layout.radius, cy, theme.alpha(grid, 0.72), 1)
        draw.line(cx, cy - layout.radius, cx, cy + layout.radius, theme.alpha(grid, 0.72), 1)
    end

    local card = theme.alpha(overlay_theme.accent(), 0.92)
    draw_util.text(cx - 3, cy - layout.radius + 5, "N", card, 9)
    draw_util.text(cx + layout.radius - 10, cy - 5, "E", theme.TEXT_DIM, 9)
    draw_util.text(cx - 3, cy + layout.radius - 14, "S", theme.TEXT_DIM, 9)
    draw_util.text(cx - layout.radius + 5, cy - 5, "W", theme.TEXT_DIM, 9)
end

local function draw_local_blip(layout, col, body_x, body_z, view_x, view_z, zoom, yaw)
    local cx, cy = layout.cx, layout.cy
    local mx, my = cx, cy
    if body_x and body_z then
        mx, my = world_to_map(body_x, body_z, view_x, view_z, cx, cy, zoom, yaw)
        mx, my = clamp_to_disc(mx, my, cx, cy, layout.radius)
    end

    local r = layout.scale + 2
    if draw and draw.poly_filled then
        draw.poly_filled({
            { mx, my - r - 2 },
            { mx + r, my + r },
            { mx, my + math.max(1, r - 2) },
            { mx - r, my + r },
        }, col)
    elseif draw and draw.line then
        draw.line(mx, my - r, mx - r, my + r, col, 2)
        draw.line(mx - r, my + r, mx + r, my + r, col, 2)
        draw.line(mx + r, my + r, mx, my - r, col, 2)
    end
    if draw and draw.circle then
        draw.circle(mx, my, r + 2, theme.alpha(col, 0.32), 16, 1)
    end
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
    menu.add_checkbox(T, G.RADAR, "april_map_labels", "Radar Show Labels", false, root)

    menu.add_colorpicker(T, G.RADAR, "april_map_player_col", "Radar Players Color", theme.RED, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_npc_col", "Radar NPCs Color", theme.ORANGE, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_loot_col", "Radar Loot Color", { 1, 0.85, 0.35, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_world_col", "Radar Resources Color", theme.GREEN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_base_col", "Radar Base Color", { 0.55, 0.55, 1, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_wp_col", "Radar Waypoints Color", theme.CYAN, root)

    menu_util.gap(T, G.RADAR)
    menu.add_slider_int(T, G.RADAR, "april_map_zoom", "Radar Zoom Level", 0.05, 5.0, 1.0, "%.2f", root)
    menu.add_slider_int(T, G.RADAR, "april_map_size", "Radar Size", 140, 420, 240, root)
    menu.add_slider_int(T, G.RADAR, "april_map_icon_scale", "Radar Blip Size", 2, 6, 3, root)
    menu_util.button(T, G.RADAR, "april_map_reset_position", "Reset Radar Position", function()
        local sw = select(1, draw_util.screen_size())
        local size = settings.num("april_map_size", 240)
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
        "april_map_labels",
        "april_map_player_col", "april_map_npc_col",
        "april_map_loot_col", "april_map_world_col", "april_map_base_col",
        "april_map_wp_col",
        "april_map_zoom", "april_map_size", "april_map_icon_scale", "april_map_reset_position",
    })
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw then return end

    overlay_theme.sync()
    local sw, sh = draw_util.screen_size()
    local size = settings.num("april_map_size", 240)
    local default_x, default_y = sw - size - 16, 16
    local x, y = panel_drag.update(
        "tactical_radar", X_ID, Y_ID, size, TITLE_H, sw, sh, default_x, default_y
    )
    x, y = panel_drag.clamp(x, y, size, size, sw, sh, X_ID, Y_ID)
    local w, h = size, size
    local body_y, body_h = y + TITLE_H, h - TITLE_H
    local cx, cy = x + w * 0.5, body_y + body_h * 0.5
    local radius = math.min(w, body_h) * 0.5 - 12
    local zoom = settings.num("april_map_zoom", 1.0)
    local scale = settings.num("april_map_icon_scale", 3)

    local layout = {
        x = x, y = y, w = w, h = h, cx = cx, cy = cy,
        radius = radius, label_radius = math.max(24, radius - 28), scale = scale,
    }

    local bg = theme.MAP_BG
    local grid = theme.MAP_GRID

    local cam_x, _, cam_z, body_x, _, body_z = get_view_origin()
    local yaw = get_camera_yaw()
    local view_x, view_z = cam_x, cam_z

    draw_radar_frame(layout, bg, grid, zoom)

    if settings.bool("april_map_show_world", false) then
        local col = settings.color("april_map_world_col", theme.GREEN)
        for _, item in ipairs(cache.world) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "diamond", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_loot", false) then
        local col = settings.color("april_map_loot_col", { 1, 0.85, 0.35, 1 })
        for _, item in ipairs(cache.loot) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "square", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_base", false) then
        local col = settings.color("april_map_base_col", { 0.55, 0.55, 1, 1 })
        for _, item in ipairs(cache.base) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, "diamond", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_npcs", false) then
        local col = settings.color("april_map_npc_col", theme.ORANGE)
        for _, entry in ipairs(cache.npcs) do
            if env.is_valid(entry.inst) then
                local wx, wz = entry_world_xz(entry)
                if wx then
                    draw_map_item(wx, wz, col, entry.name, "circle", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_waypoints", false) then
        local col = settings.color("april_map_wp_col", theme.CYAN)
        for i, wp in pairs(cache.waypoints) do
            if wp and wp.pos then
                draw_map_item(wp.pos.x, wp.pos.z, col, wp.name or ("WP" .. i), "waypoint", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
            end
        end
    end

    if settings.bool("april_map_show_players", false) and entity and entity.get_players then
        local col = settings.color("april_map_player_col", theme.RED)
        for _, p in ipairs(entity.get_players()) do
            if player_state.is_combat_target(p) and p.position then
                local label = (p.display_name and p.display_name ~= "" and p.display_name) or p.name
                draw_map_item(p.position.x, p.position.z, col, label, "circle", view_x, view_z, cx, cy, zoom, yaw, scale, layout)
            end
        end
    end

    local local_col = overlay_theme.accent()
    draw_local_blip(layout, local_col, body_x, body_z, view_x, view_z, zoom, yaw)
end

return M
