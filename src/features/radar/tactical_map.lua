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
        draw.rect_filled(lx - 2, ly - 1, tw + 4, th, { 0.04, 0.05, 0.07, 0.82 }, 3)
    end
    draw_util.text(lx, ly, text, col, fs)
end

local function draw_blip(mx, my, scale, col, clamped)
    local alpha = clamped and 0.72 or 1
    local c = { col[1], col[2], col[3], (col[4] or 1) * alpha }
    local r = math.max(2, scale - (clamped and 1 or 0))
    if draw and draw.circle_filled then
        draw.circle_filled(mx, my, r + 1, { c[1], c[2], c[3], c[4] * 0.25 }, 10)
        draw.circle_filled(mx, my, r, c, 10)
    else
        draw_util.circle(mx, my, r, c, true)
    end
end

local function draw_map_item(wx, wz, col, label, view_x, view_z, map_cx, map_cy, zoom, yaw, scale, layout)
    if not wx or not wz then return end

    local mx, my = world_to_map(wx, wz, view_x, view_z, map_cx, map_cy, zoom, yaw)
    mx, my, clamped = clamp_to_disc(mx, my, map_cx, map_cy, layout.radius)

    draw_blip(mx, my, scale, col, clamped)

    if settings.bool("april_map_labels", false) and not clamped then
        draw_radar_label(mx, my, short_label(label), col, layout.x, layout.y, layout.w, layout.h, 9)
    end
end

local function draw_radar_frame(layout, bg, border, grid)
    local x, y, w, h = layout.x, layout.y, layout.w, layout.h
    local cx, cy = layout.cx, layout.cy

    if draw.rect_filled then
        draw.rect_filled(x, y, w, h, bg, theme.ROUND)
        draw.rect_filled(x + 2, y + 2, w - 4, 18, { 0.06, 0.07, 0.09, 0.95 }, 4)
    end
    if draw.rect then
        draw.rect(x, y, w, h, border, theme.ROUND, 1)
    end

    draw_util.text(x + 8, y + 4, "RADAR", theme.TEXT, 10)

    if draw and draw.circle then
        draw.circle(cx, cy, layout.radius, grid, 48, 1)
        draw.circle(cx, cy, layout.radius * 0.66, grid, 48, 1)
        draw.circle(cx, cy, layout.radius * 0.33, grid, 48, 1)
    end

    local n_x, n_y = cx, cy - layout.radius + 10
    draw_util.text(n_x - 3, n_y - 6, "N", theme.alpha(theme.CYAN, 0.9), 10)
end

local function draw_local_blip(layout, col, body_x, body_z, view_x, view_z, zoom, yaw)
    local cx, cy = layout.cx, layout.cy
    local mx, my = cx, cy
    if body_x and body_z then
        mx, my = world_to_map(body_x, body_z, view_x, view_z, cx, cy, zoom, yaw)
        mx, my = clamp_to_disc(mx, my, cx, cy, layout.radius)
    end

    if draw and draw.line then
        local tip_x, tip_y = cx, cy - 10
        draw.line(mx, my, tip_x, tip_y, theme.alpha(col, 0.85), 2)
        draw.line(tip_x, tip_y - 4, tip_x - 3, tip_y + 2, theme.alpha(col, 0.85), 2)
        draw.line(tip_x, tip_y - 4, tip_x + 3, tip_y + 2, theme.alpha(col, 0.85), 2)
    end

    draw_blip(mx, my, layout.scale + 1, col, false)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.RADAR)
    local root = menu_util.parent(P)

    menu_util.register_keybind(T, G.RADAR, P, "Enable Radar", false, { key = 0x28 })

    menu.add_checkbox(T, G.RADAR, "april_map_show_players", "Radar Show Players", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_npcs", "Radar Show NPCs", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_loot", "Radar Show Loot", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_world", "Radar Show Resources", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_base", "Radar Show Base Parts", false, root)
    menu.add_checkbox(T, G.RADAR, "april_map_show_waypoints", "Radar Show Waypoints", true, root)
    menu.add_checkbox(T, G.RADAR, "april_map_labels", "Radar Show Labels", false, root)

    menu.add_colorpicker(T, G.RADAR, "april_map_bg", "Radar Background", theme.MAP_BG, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_grid", "Radar Grid", theme.MAP_GRID, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_player_col", "Radar Players Color", theme.RED, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_npc_col", "Radar NPCs Color", theme.ORANGE, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_loot_col", "Radar Loot Color", { 1, 0.85, 0.35, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_world_col", "Radar Resources Color", theme.GREEN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_base_col", "Radar Base Color", { 0.55, 0.55, 1, 1 }, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_wp_col", "Radar Waypoints Color", theme.CYAN, root)
    menu.add_colorpicker(T, G.RADAR, "april_map_local", "Radar You Color", theme.CYAN, root)

    menu_util.gap(T, G.RADAR)
    menu.add_slider_int(T, G.RADAR, "april_map_zoom", "Radar Zoom Level", 0.05, 5.0, 1.0, "%.2f", root)
    menu.add_slider_int(T, G.RADAR, "april_map_size", "Radar Size", 140, 420, 240, root)
    menu.add_slider_int(T, G.RADAR, "april_map_icon_scale", "Radar Blip Size", 2, 6, 3, root)

    menu_util.bind_children(P, {
        "april_map_show_players", "april_map_show_npcs", "april_map_show_loot",
        "april_map_show_world", "april_map_show_base", "april_map_show_waypoints",
        "april_map_labels",
        "april_map_bg", "april_map_grid", "april_map_player_col", "april_map_npc_col",
        "april_map_loot_col", "april_map_world_col", "april_map_base_col",
        "april_map_wp_col", "april_map_local",
        "april_map_zoom", "april_map_size", "april_map_icon_scale",
    })
end

function M.update(_dt) end

function M.draw()
    if not settings.enabled(P) then return end
    if not draw then return end

    local sw, sh = draw_util.screen_size()
    local size = settings.num("april_map_size", 240)
    local x, y = sw - size - 16, 16
    local w, h = size, size
    local cx, cy = x + w * 0.5, y + h * 0.5
    local radius = math.min(w, h) * 0.5 - 14
    local zoom = settings.num("april_map_zoom", 1.0)
    local scale = settings.num("april_map_icon_scale", 3)

    local layout = { x = x, y = y, w = w, h = h, cx = cx, cy = cy, radius = radius, scale = scale }

    local bg = settings.color("april_map_bg", theme.MAP_BG)
    local grid = settings.color("april_map_grid", theme.MAP_GRID)
    local border = theme.BORDER_CYAN

    local cam_x, _, cam_z, body_x, _, body_z = get_view_origin()
    local yaw = get_camera_yaw()
    local view_x, view_z = cam_x, cam_z

    draw_radar_frame(layout, bg, border, grid)

    if settings.bool("april_map_show_world", false) then
        local col = settings.color("april_map_world_col", theme.GREEN)
        for _, item in ipairs(cache.world) do
            if env.is_valid(item.inst) then
                local wx, wz = entry_world_xz(item)
                if wx then
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
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
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
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
                    draw_map_item(wx, wz, col, item.name, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
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
                    draw_map_item(wx, wz, col, entry.name, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
                end
            end
        end
    end

    if settings.bool("april_map_show_waypoints", false) then
        local col = settings.color("april_map_wp_col", theme.CYAN)
        for i, wp in pairs(cache.waypoints) do
            if wp and wp.pos then
                draw_map_item(wp.pos.x, wp.pos.z, col, wp.name or ("WP" .. i), view_x, view_z, cx, cy, zoom, yaw, scale, layout)
            end
        end
    end

    if settings.bool("april_map_show_players", false) and entity and entity.get_players then
        local col = settings.color("april_map_player_col", theme.RED)
        for _, p in ipairs(entity.get_players()) do
            if player_state.is_combat_target(p) and p.position then
                local label = (p.display_name and p.display_name ~= "" and p.display_name) or p.name
                draw_map_item(p.position.x, p.position.z, col, label, view_x, view_z, cx, cy, zoom, yaw, scale, layout)
            end
        end
    end

    local local_col = settings.color("april_map_local", theme.CYAN)
    draw_local_blip(layout, local_col, body_x, body_z, view_x, view_z, zoom, yaw)
end

return M
