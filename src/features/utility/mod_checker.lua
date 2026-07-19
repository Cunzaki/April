local settings = April.require("core.settings")
local notify = April.require("core.notify")
local mod_ids = April.require("game.mod_ids")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local esp_util = April.require("core.esp_util")
local theme = April.require("core.ui_theme")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")

local M = {}
local P = "april_mod_checker_enabled"
local X_ID = "april_mod_checker_x"
local Y_ID = "april_mod_checker_y"
local PANEL_W = 260
local HEAD_OFFSET = 3.5
local TITLE_H = 24
local SCAN_MS = 2500
local META_REFRESH_MS = 1000
local LOOKUP_BUDGET = 2

local seen = {}
local active = {}
local panel_rows = {}
local last_scan = -1
local last_meta_refresh = 0
M._session = nil
M._was_enabled = false
M._group_started = false

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function session_id()
    if not game then return "none" end
    local pid = game.place_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    local job = (game.job_id or game.JobId or "")
    return tostring(pid) .. ":" .. tostring(ws_addr) .. ":" .. tostring(job)
end

local function player_uid(p)
    local uid = tonumber(p.user_id)
    if uid and uid ~= 0 then return uid end
    return p.name or p.display_name
end

function M.reset_state()
    seen = {}
    active = {}
    panel_rows = {}
    last_scan = -1
    last_meta_refresh = 0
end

function M.on_session_changed()
    M.reset_state()
    mod_ids.reset_session()
end

function M.tick_session()
    local sid = session_id()
    if M._session == nil then
        M._session = sid
        last_scan = -1
        return
    end
    if sid ~= M._session then
        M._session = sid
        M.on_session_changed()
    end
end

local function player_label(p)
    if not p then return "Unknown" end
    if p.display_name and p.display_name ~= "" then return p.display_name end
    return p.name or "Unknown"
end

local function format_duration(ms)
    ms = math.max(0, ms or 0)
    local sec = math.floor(ms / 1000)
    if sec < 60 then return sec .. "s" end
    local min = math.floor(sec / 60)
    sec = sec % 60
    if min < 60 then return string.format("%dm %02ds", min, sec) end
    local hr = math.floor(min / 60)
    min = min % 60
    return string.format("%dh %02dm", hr, min)
end

local function head_world_pos(p)
    if p.head_position then
        local hp = p.head_position
        if type(hp) == "table" then
            if hp.x then return hp.x, hp.y + HEAD_OFFSET, hp.z end
            return hp[1], (hp[2] or 0) + HEAD_OFFSET, hp[3]
        end
    end
    if p.position then
        local pos = p.position
        return pos.x, pos.y + HEAD_OFFSET + 1.5, pos.z
    end
    return nil
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Utility")
    menu.add_checkbox(T, G.MISC, P, "Mod Checker", false)

    menu_util.section(T, G.MISC, "Mod Checker Scan")
    menu.add_slider_int(T, G.MISC, "april_mod_checker_interval", "Scan Interval (ms)", 1000, 10000, 2500, root)

    menu_util.bind_master(P, { "april_mod_checker_interval" })
end

function M.init()
    M.on_session_changed()
    M._session = session_id()
    mod_ids.ensure_started()
    M._group_started = true
end

function M.track_player(p, role)
    local uid = player_uid(p)
    if not uid or uid == "" then return end

    local now = tick_ms()
    if not active[uid] then
        active[uid] = {
            uid = uid,
            label = player_label(p),
            username = p.name or "?",
            role = role,
            first_seen = now,
            player = p,
        }
    else
        local entry = active[uid]
        entry.label = player_label(p)
        entry.username = p.name or entry.username
        entry.role = role
        entry.player = p
    end
end

function M.check_player(p, lookup_budget)
    if not settings.enabled(P) then return lookup_budget end
    if not p or p.is_local then return lookup_budget end

    local queue = lookup_budget and lookup_budget > 0
    local role = mod_ids.role_for_player(p, {
        queue_lookup = queue,
        mark_unknown = not queue,
    })
    if queue and role == nil then
        local uid = tonumber(p.user_id)
        if uid and uid ~= 0 then
            lookup_budget = lookup_budget - 1
        end
    end
    if not role then return lookup_budget end

    local uid = player_uid(p)
    if not uid or uid == "" then return lookup_budget end

    M.track_player(p, role)

    if seen[uid] then return lookup_budget end
    seen[uid] = true
    notify.warning(string.format("%s: %s (%s)", mod_ids.short_label(role), player_label(p), p.name or "?"), 6000)
    return lookup_budget
end

local function rebuild_panel_rows(now)
    local rows = {}
    local me = env.get_local_player()

    for uid, entry in pairs(active) do
        local p = entry.player
        local dist = nil
        if p and me and me.position and p.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            dist = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
        end

        local meta = format_duration(now - (entry.first_seen or now))
        if dist then
            meta = meta .. "  |  " .. dist .. "m"
        end

        rows[#rows + 1] = {
            name = entry.label or entry.username or "Unknown",
            role = mod_ids.short_label(entry.role),
            meta = meta,
            first_seen = entry.first_seen or now,
            accent = theme.role_accent(entry.role),
        }
    end

    table.sort(rows, function(a, b)
        return (a.first_seen or 0) < (b.first_seen or 0)
    end)

    panel_rows = rows
end

function M.reconcile_active(players)
    local present = {}

    for _, p in ipairs(players) do
        if p.is_local then goto continue end

        local role = mod_ids.role_for_player(p)
        if not role then goto continue end

        local uid = player_uid(p)
        if not uid or uid == "" then goto continue end

        present[uid] = true
        M.track_player(p, role)

        ::continue::
    end

    for uid in pairs(active) do
        if not present[uid] then
            active[uid] = nil
            seen[uid] = nil
        end
    end
end

function M.scan_all()
    if not settings.enabled(P) then return end
    if not entity or not entity.get_players then return end

    local players = entity.get_players()
    local lookup_budget = LOOKUP_BUDGET

    M.reconcile_active(players)

    for _, p in ipairs(players) do
        lookup_budget = M.check_player(p, lookup_budget)
    end

    rebuild_panel_rows(tick_ms())
    last_meta_refresh = tick_ms()
end

function M.on_player_added(p)
    M.check_player(p, LOOKUP_BUDGET)
    rebuild_panel_rows(tick_ms())
end

function M.on_player_removed(p)
    if not p then return end
    local uid = player_uid(p)
    if uid and uid ~= "" then
        seen[uid] = nil
        active[uid] = nil
        mod_ids.invalidate_player(p)
        rebuild_panel_rows(tick_ms())
    end
end

function M.staff_role(player)
    if not player then return nil end
    local uid = player_uid(player)
    if uid and active[uid] then
        return active[uid].role
    end
    return mod_ids.role_for_player(player)
end

function M.is_staff(player)
    return M.staff_role(player) ~= nil
end

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then
        if M._was_enabled then
            M.reset_state()
            M._group_started = false
        end
        M._was_enabled = false
        return
    end
    M._was_enabled = true

    if not M._group_started then
        mod_ids.ensure_started()
        M._group_started = true
    end

    local now = tick_ms()
    local interval = settings.num("april_mod_checker_interval", SCAN_MS)
    if last_scan < 0 or (now - last_scan) >= interval then
        last_scan = now
        M.scan_all()
    end
end

function M.draw_mod_markers()
    if not settings.enabled(P) then return end

    for _, entry in pairs(active) do
        local p = entry.player
        if not p or p.is_local then goto continue end

        local wx, wy, wz = head_world_pos(p)
        if not wx then goto continue end

        local sx, sy, vis = esp_util.w2s(wx, wy, wz)
        if not vis then goto continue end

        theme.draw_staff_badge(sx, sy, entry.role)

        ::continue::
    end
end

local function draw_staff_panel(x, y, width, rows)
    if not draw or not draw.text then return end

    overlay_theme.sync()
    local pad = 10
    local row_h = 44
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * row_h + 6

    theme.draw_panel(x, y, width, height, overlay_theme.panel_opts())
    overlay_theme.draw_accent_bar(x + 1, y, width - 2, 2)

    local title = "Staff In Lobby"
    if #rows > 1 then
        title = title .. " (" .. #rows .. ")"
    end
    draw_util.text(x + pad, y + 6, title, theme.TEXT, 12)

    local div_y = y + TITLE_H
    if draw.line then
        draw.line(x + pad, div_y, x + width - pad, div_y, theme.alpha(theme.BORDER, 0.55), 1)
    end

    local ry = div_y + 6
    if #rows == 0 then
        draw.text(x + pad + 12, ry, "No staff detected", theme.TEXT_MUTED, 11)
        return height
    end

    local max_name = math.max(10, math.floor((width - pad * 2 - 12) / 7))

    for i = 1, #rows do
        local row = rows[i]
        local row_accent = row.accent or theme.role_accent(row.role)

        if i > 1 and draw.line then
            draw.line(x + pad, ry - 4, x + width - pad, ry - 4, theme.alpha(theme.BORDER, 0.22), 1)
        end

        if draw.circle_filled then
            draw.circle_filled(x + pad + 3, ry + 7, 3, row_accent, 8)
        end

        local name = row.name or "?"
        if #name > max_name then name = name:sub(1, math.max(1, max_name - 2)) .. ".." end
        draw.text(x + pad + 12, ry, name, theme.TEXT, 13)

        local role = row.role or "Staff"
        if #role > max_name then role = role:sub(1, math.max(1, max_name - 2)) .. ".." end
        draw.text(x + pad + 12, ry + 15, role, row_accent, 11)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad + 12, ry + 28, row.meta, theme.TEXT_MUTED, 10)
        end

        ry = ry + row_h
    end

    return height
end

function M.draw()
    M.draw_mod_markers()

    if not settings.enabled(P) then return end

    local now = tick_ms()
    if now - last_meta_refresh >= META_REFRESH_MS then
        rebuild_panel_rows(now)
        last_meta_refresh = now
    end

    local sw, sh = draw_util.screen_size()
    local row_h = 44
    local count = math.max(#panel_rows, 1)
    local height = TITLE_H + count * row_h + 6

    local x, y = panel_drag.update(
        "mod_checker",
        X_ID, Y_ID,
        PANEL_W, TITLE_H,
        sw, sh,
        sw - PANEL_W - 16, 72
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh)

    draw_staff_panel(x, y, PANEL_W, panel_rows)
end

return M
