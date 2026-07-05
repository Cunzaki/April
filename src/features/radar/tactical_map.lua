local settings = April.require("core.settings")
local draw_util = April.require("core.draw_util")
local cache = April.require("core.cache")
local env = April.require("core.env")
local player_state = April.require("game.player_state")
local menu_util = April.require("core.menu_util")
local esp_scan = April.require("game.esp_scan")
local theme = April.require("core.ui_theme")

local M = {}
local P = "april_map_enabled"

M._offset_x = 0
M._offset_y = 0
M._dragging = false
M._drag_mx = 0
M._drag_my = 0
M._old_off_x = 0
M._old_off_y = 0
M._hover_items = {}

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)

    menu_util.section(T, G.RADAR, "Tactical Map")
    menu.add_checkbox(T, G.RADAR, P, "Enable Tactical Map", false, { key = 0x28 })
    menu.add_combo(T, G.RADAR, "april_map_mode", "Display Mode", { "Corner Widget", "Fullscreen Overlay" }, 0, root)
    menu.add_slider_float(T, G.RADAR, "april_map_zoom", "Zoom Level", 0.05, 5.0, 1.0, "%.2f", root)
    menu.add_slider_int(T, G.RADAR, "april_map_size", "Corner Size", 120, 500, 220, root)
    menu.add_slider_int(T, G.RADAR, "april_map_icon_scale", "Icon Scale", 1, 8, 3, root)

    menu.add_separator(T, G.RADAR)
    menu.add_checkbox(T, G.RADAR, "april_map_show_players", "Players", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_npcs", "NPCs", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_loot", "Loot", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_world", "World Resources", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_base", "Base Parts", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_waypoints", "Waypoints", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_local", "Local Player", true, root)

    menu.add_separator(T, G.RADAR)
    menu.add_colorpicker(T, G.RADAR, "april_map_bg", "Background Color", theme.MAP_BG, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_grid", "Grid Color", theme.MAP_GRID, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_player_col", "Player Color", theme.RED, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_npc_col", "NPC Color", theme.ORANGE, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_loot_col", "Loot Color", { 1, 0.85, 0.35, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_world_col", "World Color", theme.GREEN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_base_col", "Base Color", { 0.55, 0.55, 1, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_wp_col", "Waypoint Color", theme.CYAN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_local", "Local Player Color", theme.CYAN, root)

    menu.add_separator(T, G.RADAR)
    menu.add_checkbox(T, G.RADAR, "april_map_labels", "Show Labels", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_coords", "Show Coordinates", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_compass", "Compass Overlay", false, menu_util.parent(P, { colorpicker = theme.CYAN }))
    menu.add_checkbox(T, G.RADAR, "april_map_tooltips", "Hover Tooltips (Fullscreen)", false, root)

    menu_util.button(T, G.RADAR, "april_map_recenter", "Recenter Map", function()
        M._offset_x = 0
        M._offset_y = 0
    end)

    menu_util.bind_when(function()
        return settings.enabled(P) and settings.num("april_map_mode", 0) == 1
    end, { "april_map_tooltips", "april_map_recenter" }, { P, "april_map_mode" })

    menu_util.bind_when(function()
        return settings.enabled(P) and settings.num("april_map_mode", 0) == 0
    end, { "april_map_size" }, { P, "april_map_mode" })

    menu_util.bind_master(P, {
        "april_map_mode", "april_map_zoom", "april_map_size", "april_map_icon_scale",
        "april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
        "april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
        "april_map_show_local",
        "april_map_bg", "april_map_grid", "april_map_player_col", "april_map_npc_col",
        "april_map_loot_col", "april_map_world_col", "april_map_base_col",
        "april_map_wp_col", "april_map_local",
        "april_map_labels", "april_map_coords", "april_map_compass", "april_map_tooltips",
    })
end

local function key_active()
    if settings.enabled(P) then return true end
    if not menu or not menu.get_key then return false end
    local vk = menu.get_key(P)
    return vk and vk > 0 and input and input.is_key_down and input.is_key_down(vk)
end

local function get_mouse()
    if not utility or not utility.get_mouse_pos then return 0, 0 end
    local ok, a, b = pcall(utility.get_mouse_pos)
    if not ok then return 0, 0 end
    if type(a) == "table" then
        return a.x or a.X or 0, a.y or a.Y or 0
    end
    if type(a) == "number" then
        return a, b or 0
    end
    return 0, 0
end

local function vec_xz(v)
    if not v then return 0, 0 end
    return v.x or v.X or 0, v.z or v.Z or 0
end

local function get_look_vector()
    if camera and camera.get_look_vector then
        local ok, lv = pcall(camera.get_look_vector)
        if ok and lv then return lv end
    end
    return nil
end

local function get_camera_yaw()
    if camera and camera.get_angles then
        local ok, a = pcall(camera.get_angles)
        if ok and a then
            local deg = a.Y or a.y
            if deg then return math.rad(deg) end
        end
    end
    if utility and utility.get_camera_angles then
        local ok, pitch, yaw = pcall(utility.get_camera_angles)
        if ok and yaw then return math.rad(yaw) end
        if ok and pitch and not yaw then return math.rad(pitch) end
    end
    local lv = get_look_vector()
    if lv then
        local lx, lz = vec_xz(lv)
        if math.abs(lx) > 0.001 or math.abs(lz) > 0.001 then
            return math.atan2(lx, lz)
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

    if not cx then
        cx, cy, cz = px, py, pz
    end

    return cx or 0, cy or 0, cz or 0, px, py, pz
end

local function map_layout(sw, sh, fullscreen)
    if fullscreen then
        return 0, 0, sw, sh, sw * 0.5, sh * 0.5
    end
    local size = settings.num("april_map_size", 220)
    local x, y = sw - size - 20, 20
    return x, y, size, size, x + size * 0.5, y + size * 0.5
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

local function world_dir_to_screen(dx, dz, yaw, radius)
    local fx, fz, rx, rz = map_basis(yaw)
    local local_fwd = dx * fx + dz * fz
    local local_right = dx * rx + dz * rz
    return local_right * radius, -local_fwd * radius
end

local function draw_dot(mx, my, scale, col)
    if draw and draw.circle_filled then
        draw.circle_filled(mx, my, scale, col, 10)
    else
        draw_util.circle(mx, my, scale, col, true)
    end
end

local function entry_world_xz(entry)
    if not entry then return nil, nil end

    local lx, ly, lz = esp_scan.entry_coords(entry)
    if lx and lz then return lx, lz end

    if entry.lx and entry.lz then return entry.lx, entry.lz end

    if entry.pos then
        return entry.pos.x, entry.pos.z
    end

    local inst = entry.inst
    if inst and env.is_valid(inst) then
        local pos = inst.Position or inst.position
        if pos and pos.x then return pos.x, pos.z end
    end

    return nil, nil
end

local function register_hover(mx, my, scale, label, extra)
    if not label or label == "" then return end
    M._hover_items[#M._hover_items + 1] = {
        mx = mx,
        my = my,
        r = scale + 8,
        label = label,
        extra = extra,
    }
end

local function draw_map_item(wx, wz, col, label, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, hover_extra)
    if not wx or not wz then return end
    local mx, my = world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    if mx < x - 8 or mx > x + w + 8 or my < y - 8 or my > y + h + 8 then return end
    draw_dot(mx, my, scale, col)
    if settings.bool("april_map_labels", false) and label and label ~= "" then
        draw_util.text(mx + scale + 2, my - 6, label, col, 10)
    end
    if track_hover then
        register_hover(mx, my, scale, label, hover_extra)
        M._hover_items[#M._hover_items].wx = wx
        M._hover_items[#M._hover_items].wz = wz
    end
end

local function draw_grid(x, y, w, h, grid, map_cx, map_cy, zoom)
    local step = math.max(12, (w / 8))
    for i = -4, 4 do
        if i ~= 0 then
            draw_util.line(map_cx + i * step, y + 4, map_cx + i * step, y + h - 4, grid, 1)
            draw_util.line(x + 4, map_cy + i * step, x + w - 4, map_cy + i * step, grid, 1)
        end
    end
end

local function draw_compass_rose(cx, cy, radius, yaw, cmp_col)
    if draw and draw.circle_filled then
        draw.circle_filled(cx, cy, radius, theme.alpha(theme.PANEL_DEEP, 0.82), 24)
    end
    if draw and draw.circle then
        draw.circle(cx, cy, radius, theme.alpha(theme.CYAN, 0.55), 24, 1.5)
    end

    local function marker(lbl, wdx, wdz, col)
        local sx, sy = world_dir_to_screen(wdx, wdz, yaw, radius - 10)
        draw_util.text(cx + sx - 4, cy + sy - 6, lbl, col, 11)
    end

    marker("N", 0, -1, theme.RED)
    marker("S", 0, 1, cmp_col)
    marker("E", 1, 0, cmp_col)
    marker("W", -1, 0, cmp_col)

    if draw and draw.line then
        local nx, ny = world_dir_to_screen(0, -1, yaw, radius - 4)
        draw.line(cx, cy, cx + nx, cy + ny, theme.alpha(theme.CYAN, 0.9), 2)
    end
end

local function handle_fullscreen_pan(zoom, mx, my, yaw)
    if not input or not input.is_key_down then return end

    if input.is_key_down(0x04) then
        M._offset_x = 0
        M._offset_y = 0
        return
    end

    if input.is_key_down(0x01) then
        if not M._dragging then
            M._dragging = true
            M._drag_mx = mx
            M._drag_my = my
            M._old_off_x = M._offset_x
            M._old_off_y = M._offset_y
        elseif zoom > 0 then
            local dx = (mx - M._drag_mx) / zoom
            local dy = (my - M._drag_my) / zoom
            local fx, fz, rx, rz = map_basis(yaw)
            M._offset_x = M._old_off_x - (dx * rx + dy * rz)
            M._offset_y = M._old_off_y - (-dx * fx + dy * fz)
        end
    else
        M._dragging = false
    end
end

local function draw_hover_tooltip(mx, my, me)
    local best = nil
    local best_d = 9999

    for _, item in ipairs(M._hover_items) do
        local dx = mx - item.mx
        local dy = my - item.my
        local d = math.sqrt(dx * dx + dy * dy)
        if d <= item.r and d < best_d then
            best = item
            best_d = d
        end
    end

    if not best then return end

    local lines = { best.label or "?" }
    if best.extra then
        lines[#lines + 1] = best.extra
    elseif me and me.position and best.wx and best.wz then
        local dx = best.wx - me.position.x
        local dz = best.wz - me.position.z
        lines[#lines + 1] = string.format("%.0fm away", math.sqrt(dx * dx + dz * dz))
    end

    theme.draw_tooltip_box(mx + 14, my + 14, lines)
end

function M.update(_dt) end

function M.draw()
    if not key_active() then return end
    if not draw then return end

    M._hover_items = {}

    local sw, sh = draw_util.screen_size()
    local fullscreen = settings.num("april_map_mode", 0) == 1
    local x, y, w, h, map_cx, map_cy = map_layout(sw, sh, fullscreen)
    local zoom = settings.num("april_map_zoom", 1.0)
    local scale = settings.num("april_map_icon_scale", 3)
    local bg = settings.color("april_map_bg", theme.MAP_BG)
    local grid = settings.color("april_map_grid", theme.MAP_GRID)
    local track_hover = fullscreen and settings.bool("april_map_tooltips", false)
    local me = env.get_local_player()

    local cam_x, cam_y, cam_z, body_x, body_y, body_z = get_view_origin()
    local yaw = get_camera_yaw()

    local mx, my = get_mouse()

    if fullscreen then
        handle_fullscreen_pan(zoom, mx, my, yaw)
    else
        M._offset_x = 0
        M._offset_y = 0
        M._dragging = false
    end

    local view_x = cam_x + M._offset_x
    local view_z = cam_z + M._offset_y

    if draw.rect_filled then
        draw.rect_filled(x, y, w, h, bg, fullscreen and 0 or theme.ROUND)
        if draw.rect then
            draw.rect(x, y, w, h, theme.BORDER_CYAN, fullscreen and 0 or theme.ROUND, 1)
        end
    end

    draw_grid(x, y, w, h, grid, map_cx, map_cy, zoom)

    if settings.bool("april_map_show_world", false) then
        local col = settings.color("april_map_world_col", { 0.4, 0.9, 0.5, 1 })
        for _, item in ipairs(cache.world) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, item.name)
                end
            end
        end
    end

    if settings.bool("april_map_show_loot", false) then
        local col = settings.color("april_map_loot_col", { 1, 0.85, 0.2, 1 })
        for _, item in ipairs(cache.loot) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, item.name)
                end
            end
        end
    end

    if settings.bool("april_map_show_base", false) then
        local col = settings.color("april_map_base_col", { 0.5, 0.5, 1, 1 })
        for _, item in ipairs(cache.base) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, item.name)
                end
            end
        end
    end

    if settings.bool("april_map_show_npcs", false) then
        local col = settings.color("april_map_npc_col", { 1, 0.6, 0.2, 1 })
        for _, entry in ipairs(cache.npcs) do
            if env.is_valid(entry.inst) then
                local wx, wz = entry_world_xz(entry)
                if not wx and entry.lx and entry.lz then wx, wz = entry.lx, entry.lz end
                if wx then
                    draw_map_item(wx, wz, col, entry.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, entry.name)
                end
            end
        end
    end

    if settings.bool("april_map_show_waypoints", false) then
        local col = settings.color("april_map_wp_col", { 0.2, 1, 0.8, 1 })
        for i, wp in pairs(cache.waypoints) do
            if wp and wp.pos then
                local wx, wz = wp.pos.x, wp.pos.z
                draw_map_item(wx, wz, col, wp.name or ("WP" .. i), view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, wp.name)
            end
        end
    end

    if settings.bool("april_map_show_players", false) and entity and entity.get_players then
        local col = settings.color("april_map_player_col", { 1, 0.35, 0.35, 1 })
        for _, p in ipairs(entity.get_players()) do
            if player_state.is_combat_target(p) and p.position then
                local wx, wz = p.position.x, p.position.z
                local extra = p.display_name and p.display_name ~= "" and p.display_name or p.name
                draw_map_item(wx, wz, col, p.name, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, x, y, w, h, track_hover, extra)
            end
        end
    end

    local show_local = settings.bool("april_map_show_local", true)
    if not fullscreen then
        show_local = true
    end

    if show_local then
        local col = settings.color("april_map_local", theme.CYAN)
        local dot_x, dot_y = map_cx, map_cy

        if body_x and body_z then
            dot_x, dot_y = world_to_map(body_x, body_z, view_x, view_z, map_cx, map_cy, zoom, yaw)
        end

        draw_dot(dot_x, dot_y, scale + 1, col)
        if draw and draw.circle then
            draw.circle(dot_x, dot_y, scale + 4, { col[1], col[2], col[3], (col[4] or 1) * 0.35 }, 16, 1)
        end

        if draw and draw.line then
            local tip_x, tip_y = map_cx, map_cy - (scale + 10)
            draw.line(map_cx, map_cy, tip_x, tip_y, { col[1], col[2], col[3], 0.85 }, 2)
            draw.line(tip_x, tip_y - 5, tip_x - 4, tip_y + 2, { col[1], col[2], col[3], 0.85 }, 2)
            draw.line(tip_x, tip_y - 5, tip_x + 4, tip_y + 2, { col[1], col[2], col[3], 0.85 }, 2)
        end
    end

    if settings.bool("april_map_compass", false) then
        local cmp_col = settings.color("april_map_compass", theme.CYAN)
        if fullscreen then
            draw_compass_rose(sw - 60, sh - 60, 42, yaw, cmp_col)
        else
            draw_compass_rose(map_cx, map_cy, math.min(w, h) * 0.42, yaw, cmp_col)
        end
    end

    if settings.bool("april_map_coords", false) then
        local coord_y = fullscreen and (sh - 22) or (y + h + 4)
        draw_util.text(x + 6, coord_y, string.format("Cam: %.0f, %.0f, %.0f", cam_x, cam_y, cam_z), theme.TEXT, 11)
        if body_x then
            draw_util.text(x + 6, coord_y + 13, string.format("Body: %.0f, %.0f, %.0f", body_x, body_y or 0, body_z or 0), theme.TEXT_MUTED, 10)
        end
    end

    if track_hover then
        draw_hover_tooltip(mx, my, me)
        draw_util.text(10, sh - 18, "Drag: LMB pan  |  Recenter: MMB  |  Hover icons for info", theme.TEXT_DIM, 10)
    elseif fullscreen then
        draw_util.text(10, sh - 18, "Drag: LMB pan  |  Recenter: MMB  |  Forward = up", theme.TEXT_DIM, 10)
    end
end

return M
