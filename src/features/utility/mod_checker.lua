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
local ep = April.require("core.entity_props")

local M = {}
local P = "april_mod_checker_enabled"
local X_ID = "april_mod_checker_x"
local Y_ID = "april_mod_checker_y"
local PANEL_W = 282
local HEAD_OFFSET = 3.5
local TITLE_H = 30
local SCAN_MS = 2500
local META_REFRESH_MS = 1000
local LOOKUP_BUDGET = 2
local ROLE_MISS_TTL_MS = 3000

local seen = {}
local active = {}
local role_misses = {}
-- Progressive skip: UserIds already resolved as non-staff (static/tag). Cleared on
-- full interval scan so live group lookups can still catch late staff.
local settled_nonstaff = {}
local panel_rows = {}
local last_scan = -1
local last_meta_refresh = 0
local last_progressive = 0
local PROGRESSIVE_MS = 100
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
    local uid = ep.user_id(p)
    if uid and uid ~= 0 then return uid end
    return p.name or p.display_name
end

function M.reset_state()
    seen = {}
    active = {}
    role_misses = {}
    settled_nonstaff = {}
    panel_rows = {}
    last_scan = -1
    last_meta_refresh = 0
    last_progressive = 0
end

function M.on_session_changed()
    M.reset_state()
    mod_ids.reset_session()
    M._group_started = false
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

    -- Hidden persisted panel position (drag writes these; define so get/set stick).
    pcall(function()
        local gs = April.require("ui.gs_state")
        gs.define(X_ID, -1)
        gs.define(Y_ID, -1)
    end)

    menu_util.bind_master(P, { "april_mod_checker_interval" })
end

function M.init()
    M.on_session_changed()
    M._session = session_id()
    -- Static staff IDs + in-game staff tags are safe and sufficient here.
    -- Avoid Vector's background Roblox group crawl, which can hard-crash after
    -- repeated HttpGet rate limits during startup.
    M._group_started = false
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

local function numeric_uid(p)
    return ep.user_id(p)
end

function M.check_player(p, lookup_budget)
    if not settings.enabled(P) then return lookup_budget end
    if not p or p.is_local then return lookup_budget end

    local uid_num = numeric_uid(p)
    if uid_num and settled_nonstaff[uid_num] then
        return lookup_budget
    end

    local role = mod_ids.role_for_player(p, {
        queue_lookup = true,
        mark_unknown = false,
        live_lookup = true,
    })
    if not role then
        -- Only settle when we have a real UserId. Nameless/streaming players stay
        -- open so the next progressive tick can catch staff as soon as id/tag lands.
        if uid_num then
            settled_nonstaff[uid_num] = true
        end
        return lookup_budget
    end

    local uid = player_uid(p)
    if not uid or uid == "" then return lookup_budget end

    if uid_num then settled_nonstaff[uid_num] = nil end
    M.track_player(p, role)

    if seen[uid] then return lookup_budget end
    seen[uid] = true
    notify.warning(string.format("%s: %s (%s)", mod_ids.short_label(role), player_label(p), p.name or "?"), 6000)
    rebuild_panel_rows(tick_ms())
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

local function player_body_alive(p)
    if not p or p.is_local then return false end
    -- Hide badge when dead / no character (stale head_position can linger).
    if p.is_alive == false then return false end
    local char = p.character
    if not char or not env.is_valid(char) then return false end
    local hum = p.humanoid
    if hum ~= nil and not env.is_valid(hum) then return false end
    if p.health ~= nil and p.health <= 0 then return false end
    return true
end

function M.reconcile_active(players)
    local present = {}

    for _, p in ipairs(players) do
        if p.is_local then goto continue end

        local role = mod_ids.role_for_player(p, { live_lookup = true })
        if not role then goto continue end

        local uid = player_uid(p)
        if not uid or uid == "" then goto continue end

        -- Keep lobby list entry, but only attach live body for world badge.
        present[uid] = true
        if player_body_alive(p) then
            M.track_player(p, role)
        elseif active[uid] then
            active[uid].player = nil
            active[uid].role = role
        else
            M.track_player(p, role)
            if active[uid] then active[uid].player = nil end
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

-- Immediate pass over whoever is already in cache (does not wait for a "full" list).
function M.scan_progressive()
    if not settings.enabled(P) then return end

    local players = April.require("core.cache").players
    local lookup_budget = LOOKUP_BUDGET

    for _, p in ipairs(players) do
        local uid = player_uid(p)
        if uid and seen[uid] then
            goto continue
        end
        lookup_budget = M.check_player(p, lookup_budget)
        ::continue::
    end

    last_meta_refresh = tick_ms()
end

function M.scan_all()
    if not settings.enabled(P) then return end

    local players = April.require("core.cache").players
    local lookup_budget = LOOKUP_BUDGET

    -- Allow live group / late tag resolution to re-evaluate non-staff.
    settled_nonstaff = {}

    M.reconcile_active(players)

    for _, p in ipairs(players) do
        lookup_budget = M.check_player(p, lookup_budget)
    end

    rebuild_panel_rows(tick_ms())
    last_meta_refresh = tick_ms()
end

function M.on_player_added(p)
    -- Fire as soon as Vector streams the player — do not wait for lobby-complete.
    local uid_num = numeric_uid(p)
    if uid_num then settled_nonstaff[uid_num] = nil end
    M.check_player(p, LOOKUP_BUDGET)
    rebuild_panel_rows(tick_ms())
end

function M.on_player_removed(p)
    if not p then return end
    local uid = player_uid(p)
    local uid_num = numeric_uid(p)
    if uid_num then settled_nonstaff[uid_num] = nil end
    if uid and uid ~= "" then
        seen[uid] = nil
        active[uid] = nil
        role_misses[uid] = nil
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
    local now = tick_ms()
    if uid and now < (role_misses[uid] or 0) then return nil end
    local role = mod_ids.role_for_player(player, { live_lookup = true })
    if uid and not role then role_misses[uid] = now + ROLE_MISS_TTL_MS end
    return role
end

function M.is_staff(player)
    return M.staff_role(player) ~= nil
end

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then
        if M._was_enabled then
            M.reset_state()
            mod_ids.stop("mod_checker_disabled")
            M._group_started = false
        end
        M._was_enabled = false
        return
    end

    local just_enabled = not M._was_enabled
    M._was_enabled = true

    if not M._group_started then
        M._group_started = mod_ids.ensure_started() == true
    end

    local now = tick_ms()

    -- Progressive: check whoever is in cache already (and re-check pending UserIds)
    -- instead of waiting for the full lobby + scan interval before first notifies.
    if just_enabled or last_progressive < 0 or (now - last_progressive) >= PROGRESSIVE_MS then
        last_progressive = now
        M.scan_progressive()
    end

    local interval = settings.num("april_mod_checker_interval", SCAN_MS)
    if last_scan < 0 or (now - last_scan) >= interval then
        last_scan = now
        M.scan_all()
    end
end

function M.draw_mod_markers()
    if not settings.enabled(P) then return end

    for uid, entry in pairs(active) do
        local p = entry.player
        if not player_body_alive(p) then
            -- Drop dead / despawned bodies from marker set (panel clears on next scan).
            if p and (p.is_alive == false or not p.character or not env.is_valid(p.character)) then
                entry.player = nil
            end
            goto continue
        end

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

    local pad = 12
    local row_h = 38
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * row_h + 6

    local i18n = April.require("ui.i18n")
    local title = i18n.t("STAFF IN LOBBY")
    if #rows > 1 then
        title = title .. " (" .. #rows .. ")"
    end
    overlay_theme.draw_panel(x, y, width, height, title)

    local ry = y + TITLE_H + 5
    if #rows == 0 then
        draw.text(x + pad, ry + 2, i18n.t("No staff detected"), theme.TEXT_MUTED, 11)
        return height
    end

    local max_name = math.max(10, math.floor((width - pad * 2 - 12) / 7))

    for i = 1, #rows do
        local row = rows[i]
        local row_accent = row.accent or theme.role_accent(row.role)

        local name = row.name or "?"
        if #name > max_name then name = name:sub(1, math.max(1, max_name - 2)) .. ".." end
        draw.text(x + pad, ry + 1, name, theme.TEXT, 12)

        local role = row.role or "Staff"
        if #role > max_name then role = role:sub(1, math.max(1, max_name - 2)) .. ".." end
        local role_w = theme.text_w(role, 10)
        draw.text(x + width - pad - role_w, ry + 2, role, row_accent, 10)

        if row.meta and row.meta ~= "" then
            draw.text(x + pad, ry + 18, row.meta, theme.TEXT_MUTED, 10)
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
    local row_h = 38
    local count = math.max(#panel_rows, 1)
    local height = TITLE_H + count * row_h + 6

    local default_x = sw - PANEL_W - 16
    local default_y = 72
    -- Seed defaults when unset (-1) so drag has a real stored position.
    local stored_x = settings.num(X_ID, -1)
    local stored_y = settings.num(Y_ID, -1)
    if stored_x < 0 then
        if menu and menu.set then pcall(menu.set, X_ID, default_x) end
    end
    if stored_y < 0 then
        if menu and menu.set then pcall(menu.set, Y_ID, default_y) end
    end

    local x, y = panel_drag.update(
        "mod_checker",
        X_ID, Y_ID,
        PANEL_W, TITLE_H,
        sw, sh,
        default_x, default_y,
        true -- keep draggable while April menu is open
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh, X_ID, Y_ID)

    draw_staff_panel(x, y, PANEL_W, panel_rows)
end

return M
