local settings = April.require("core.settings")
local notify = April.require("core.notify")
local mod_ids = April.require("game.mod_ids")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local env = April.require("core.env")
local esp_util = April.require("core.esp_util")
local image_cache = April.require("core.image_cache")
local asset_urls = April.require("game.asset_urls")
local theme = April.require("core.ui_theme")

local M = {}
local P = "april_mod_checker_enabled"
local X_ID = "april_mod_checker_x"
local Y_ID = "april_mod_checker_y"
local W_ID = "april_mod_checker_w"
local MOD_ICON_KEY = "mod_warning"
local HEAD_OFFSET = 3.5
local TITLE_H = 24

local seen = {}
local active = {}
local last_scan = -1
local SCAN_MS = 2500
M._session = nil
M._was_enabled = false

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function session_id()
    if not game then return "none" end
    local pid = game.place_id or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    return pid .. ":" .. ws_addr
end

function M.reset_state()
    seen = {}
    active = {}
    last_scan = -1
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
        M.reset_state()
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

    menu_util.section(T, G.MISC, "Mod Panel Layout")
    menu.add_slider_int(T, G.MISC, X_ID, "Mod Panel Pos X", 0, 1920, 1600, root)
    menu.add_slider_int(T, G.MISC, Y_ID, "Mod Panel Pos Y", 0, 1080, 72, root)
    menu.add_slider_int(T, G.MISC, W_ID, "Mod Panel Width", 180, 420, 260, root)

    menu_util.bind_master(P, {
        "april_mod_checker_interval", X_ID, Y_ID, W_ID,
    })
end

function M.init()
    image_cache.ensure(MOD_ICON_KEY, asset_urls.mod_warning_png())
    last_scan = -1
end

function M.track_player(p, role)
    local uid = p.user_id
    if not uid or uid == 0 then return end

    local now = tick_ms()
    if not active[uid] then
        active[uid] = {
            uid = uid,
            label = player_label(p),
            username = p.name or "?",
            role = role,
            first_seen = now,
        }
    else
        local entry = active[uid]
        entry.label = player_label(p)
        entry.username = p.name or entry.username
        entry.role = role
    end
end

function M.check_player(p)
    if not settings.enabled(P) then return end
    if not p or p.is_local then return end

    local uid = p.user_id
    if not uid or uid == 0 then return end

    local role = mod_ids.role_for(uid)
    if not role then return end

    M.track_player(p, role)

    if seen[uid] then return end
    seen[uid] = true
    local label = player_label(p)
    notify.warning(string.format("MOD: %s (%s) - %s", label, p.name or "?", role), 6000)
end

function M.reconcile_active()
    if not entity or not entity.get_players then return end

    local players = entity.get_players()
    if #players == 0 then return end

    local present = {}
    for _, p in ipairs(players) do
        if p.is_local then goto continue end
        local uid = p.user_id
        if not uid or uid == 0 then goto continue end

        local role = mod_ids.role_for(uid)
        if role then
            present[uid] = true
            M.track_player(p, role)
        end

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
    M.reconcile_active()

    for _, p in ipairs(entity and entity.get_players and entity.get_players() or {}) do
        M.check_player(p)
    end
end

function M.on_player_added(p)
    M.check_player(p)
end

function M.on_player_removed(p)
    if not p then return end
    local uid = p.user_id
    if uid and uid ~= 0 then
        seen[uid] = nil
        active[uid] = nil
    end
end

function M.is_staff(player)
    if not player then return false end
    local uid = player.user_id
    if not uid or uid == 0 then return false end
    if active[uid] then return true end
    return mod_ids.role_for(uid) ~= nil
end

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then
        if M._was_enabled then M.reset_state() end
        M._was_enabled = false
        return
    end
    M._was_enabled = true

    local now = tick_ms()
    local interval = settings.num("april_mod_checker_interval", SCAN_MS)
    if last_scan < 0 or (now - last_scan) >= interval then
        last_scan = now
        M.scan_all()
    end
end

function M.draw_mod_markers()
    if not settings.enabled(P) then return end
    if not entity or not entity.get_players then return end

    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local uid = p.user_id
        if not uid or uid == 0 then goto continue end
        if not mod_ids.role_for(uid) then goto continue end

        local wx, wy, wz = head_world_pos(p)
        if not wx then goto continue end

        local sx, sy, vis = esp_util.w2s(wx, wy, wz)
        if not vis then goto continue end

        theme.draw_mod_marker(sx, sy, image_cache, MOD_ICON_KEY)

        ::continue::
    end
end

local function build_staff_rows()
    local rows = {}
    local me = env.get_local_player()
    local now = tick_ms()

    if not entity or not entity.get_players then return rows end

    for _, p in ipairs(entity.get_players()) do
        if p.is_local then goto continue end

        local uid = p.user_id
        if not uid or uid == 0 then goto continue end

        local role = mod_ids.role_for(uid)
        if not role then goto continue end

        M.track_player(p, role)
        local entry = active[uid]
        if not entry then goto continue end

        local dist = nil
        if me and me.position and p.position then
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
            role = role,
            meta = meta,
            first_seen = entry.first_seen or now,
        }

        ::continue::
    end

    table.sort(rows, function(a, b)
        return (a.first_seen or 0) < (b.first_seen or 0)
    end)

    return rows
end

local function clamp_layout(x, y, w, sw, sh)
    w = math.max(180, math.min(420, math.floor(w or 260)))
    x = math.max(0, math.min(math.max(0, sw - w), math.floor(x or 0)))
    y = math.max(0, math.min(math.max(0, sh - 40), math.floor(y or 0)))
    return x, y, w
end

local function draw_staff_panel(x, y, width, rows)
    if not draw or not draw.text then return end

    local pad = 10
    local row_h = 44
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * row_h + 6

    theme.draw_panel(x, y, width, height, {
        bg = theme.alpha(theme.BG, 0.90),
        border = theme.alpha(theme.BORDER, 0.45),
        accent = theme.RED,
        accent_w = 2,
        rounding = theme.ROUND,
    })

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
        return
    end

    local max_name = math.max(10, math.floor((width - pad * 2 - 12) / 7))

    for i = 1, #rows do
        local row = rows[i]
        local accent = row.accent or theme.role_accent(row.role)

        if i > 1 and draw.line then
            draw.line(x + pad, ry - 4, x + width - pad, ry - 4, theme.alpha(theme.BORDER, 0.22), 1)
        end

        if draw.circle_filled then
            draw.circle_filled(x + pad + 3, ry + 7, 3, accent, 8)
        end

        local name = row.name or "?"
        if #name > max_name then name = name:sub(1, math.max(1, max_name - 2)) .. ".." end
        draw.text(x + pad + 12, ry, name, theme.TEXT, 13)

        local role = row.role or "Staff"
        if #role > max_name then role = role:sub(1, math.max(1, max_name - 2)) .. ".." end
        draw.text(x + pad + 12, ry + 15, role, accent, 11)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad + 12, ry + 28, row.meta, theme.TEXT_MUTED, 10)
        end

        ry = ry + row_h
    end
end

function M.draw()
    M.draw_mod_markers()

    if not settings.enabled(P) then return end

    M.reconcile_active()

    local sw, sh = draw_util.screen_size()
    local x, y, panel_w = clamp_layout(
        settings.num(X_ID, 1600),
        settings.num(Y_ID, 72),
        settings.num(W_ID, 260),
        sw, sh
    )

    draw_staff_panel(x, y, panel_w, build_staff_rows())
end

return M
