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
local MOD_ICON_KEY = "mod_warning"
local HEAD_OFFSET = 3.5

local seen = {}
local active = {}
local last_scan = 0
local SCAN_MS = 2500
M._session = nil

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
    last_scan = 0
end

function M.tick_session()
    local sid = session_id()
    if M._session == nil then
        M._session = sid
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
    menu_util.section(T, G.MISC, "Mod Checker")
    menu.add_checkbox(T, G.MISC, P, "Mod Checker", false, { key = 0 })
    menu.add_slider_int(T, G.MISC, "april_mod_checker_interval", "Mod Scan Interval (ms)", 1000, 10000, 2500, { parent = P })
    menu_util.bind_master(P, { "april_mod_checker_interval" })
end

function M.init()
    image_cache.ensure(MOD_ICON_KEY, asset_urls.mod_warning_png())
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
    notify.warning(string.format("MOD: %s (%s) — %s", label, p.name or "?", role), 6000)
end

function M.reconcile_active()
    if not entity or not entity.get_players then
        M.reset_state()
        return
    end

    local players = entity.get_players()
    if #players == 0 then
        M.reset_state()
        return
    end

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

function M.update(_dt)
    M.tick_session()

    if not settings.enabled(P) then
        M.reset_state()
        return
    end

    local now = tick_ms()
    local interval = settings.num("april_mod_checker_interval", SCAN_MS)
    if now - last_scan >= interval then
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

function M.draw()
    M.draw_mod_markers()

    if not settings.enabled(P) then return end
    if not draw or not draw.text then return end

    local rows = {}
    local me = env.get_local_player()
    local now = tick_ms()

    for uid, entry in pairs(active) do
        local still_here = false
        local dist = nil

        for _, p in ipairs(entity and entity.get_players and entity.get_players() or {}) do
            if p.user_id == uid then
                still_here = true
                if me and me.position and p.position then
                    local dx = p.position.x - me.position.x
                    local dy = p.position.y - me.position.y
                    local dz = p.position.z - me.position.z
                    dist = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
                end
                break
            end
        end

        if not still_here then
            active[uid] = nil
            seen[uid] = nil
            goto continue
        end

        rows[#rows + 1] = {
            entry = entry,
            dist = dist,
            duration = format_duration(now - (entry.first_seen or now)),
        }

        ::continue::
    end

    if #rows == 0 then return end

    table.sort(rows, function(a, b)
        return (a.entry.first_seen or 0) < (b.entry.first_seen or 0)
    end)

    if not draw.window then return end

    local sw, _ = draw_util.screen_size()
    local panel_w = 260
    local x = sw - panel_w - 16
    local items = {}

    for i = 1, #rows do
        local row = rows[i]
        local entry = row.entry
        local meta = row.duration
        if row.dist then
            meta = meta .. "  ·  " .. row.dist .. "m"
        end

        local name = entry.label or entry.username or "Unknown"
        if #name > 18 then name = name:sub(1, 16) .. ".." end

        local role = entry.role or "Staff"
        items[#items + 1] = { name .. "  ·  " .. role, meta }
    end

    local title = "Staff In Lobby"
    if #items > 1 then
        title = title .. " (" .. #items .. ")"
    end

    draw.window(x, 72, "april_staff_lobby", title, items)
end

return M
