local settings = April.require("core.settings")
local cache = April.require("core.cache")
local env = April.require("core.env")
local folders = April.require("game.folders")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")
local theme = April.require("core.ui_theme")

local M = {}
local P = "april_event_status_enabled"
local X_ID = "april_event_status_x"
local Y_ID = "april_event_status_y"
local PANEL_W = 314
local TITLE_H = 30
local ROW_H = 36
-- The crate countdown only changes once per second, while NPC presence is
-- already refreshed by game.npcs every 750 ms.
local REFRESH_MS = 1000

-- Raids are Raid-ESP only — never listed in the event viewer.
local DEFINITIONS = {
    { id = "timed_crate", label = "Timed Crate", color = { 0.42, 0.95, 0.48, 1 } },
    { id = "btr", label = "BTR", color = { 0.95, 0.25, 0.15, 1 } },
    { id = "attack_heli", label = "Attack Heli", color = { 0.95, 0.48, 0.18, 1 } },
    { id = "bruno", label = "Bruno", color = { 0.95, 0.66, 0.20, 1 } },
    { id = "boris", label = "Boris", color = { 0.78, 0.42, 1.00, 1 } },
    { id = "brutus", label = "Brutus", color = { 1.00, 0.30, 0.48, 1 } },
}

local rows = {}
local first_seen = {}
local last_refresh = -REFRESH_MS
local session_token = nil

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function session_id()
    if not game then return "none" end
    local pid = game.place_id or game.PlaceId or 0
    local ws = game.workspace
    local ws_addr = (ws and (ws.Address or ws.address)) or 0
    local job = (game.job_id or game.JobId or "")
    return tostring(pid) .. ":" .. tostring(ws_addr) .. ":" .. tostring(job)
end

local function reset_session_state()
    rows = {}
    first_seen = {}
    last_refresh = -REFRESH_MS
end

local function tick_session()
    local sid = session_id()
    if session_token == nil then
        session_token = sid
        return
    end
    if sid ~= session_token then
        session_token = sid
        reset_session_state()
    end
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

local function children(parent)
    if not parent then return {} end
    return env.safe_call(function()
        if parent.GetChildren then return parent:GetChildren() end
        if parent.get_children then return parent:get_children() end
        return {}
    end) or {}
end

local function format_elapsed(ms)
    local seconds = math.max(0, math.floor((ms or 0) / 1000))
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    if minutes < 60 then return string.format("%02d:%02d", minutes, seconds) end
    local hours = math.floor(minutes / 60)
    minutes = minutes % 60
    return string.format("%dh %02dm", hours, minutes)
end

local function crate_timer(model)
    local timer = find_child(model, "Timer")
    local holder = find_child(timer, "GuiHolder")
    local label = find_child(holder, "Label")
    local text_label = find_child(label, "TextLabel")
    local value = text_label and env.safe_call(function()
        return text_label.Text or text_label.text
    end)
    if value ~= nil and tostring(value) ~= "" then return tostring(value) end
    return nil
end

local function timed_crates()
    local bucket = find_child(folders.from_key("loners"), "Timed Crate")
    local count, timer = 0, nil
    for _, model in ipairs(children(bucket)) do
        if (model.Name or model.name) == "Timed Crate" then
            count = count + 1
            timer = timer or crate_timer(model)
        end
    end
    return count, timer
end

local function npc_event_state()
    local state = {}
    for _, entry in ipairs(cache.npcs or {}) do
        local id = entry and entry.kind
        if id == "heli" then id = "attack_heli" end
        if id == "btr" or id == "attack_heli" or id == "bruno"
            or id == "boris" or id == "brutus"
        then
            local item = state[id] or { count = 0 }
            item.count = item.count + 1
            item.location = item.location or entry.location
            if entry.entity then
                item.hp = tonumber(entry.entity.Health or entry.entity.health) or item.hp
                item.max_hp = tonumber(entry.entity.MaxHealth or entry.entity.max_health) or item.max_hp
            elseif entry.inst then
                local health = April.require("game.npcs").read_health(entry.inst, entry.humanoid)
                if health then
                    item.hp = health.hp or item.hp
                    item.max_hp = health.max_hp or item.max_hp
                end
            end
            if id == "btr" and entry.inst then
                item.destroyed = env.get_attribute(entry.inst, "Destroyed") == true
            end
            state[id] = item
        end
    end
    return state
end

local function rebuild_rows(now)
    local active = npc_event_state()
    local crate_count, crate_time = timed_crates()
    if crate_count > 0 then
        active.timed_crate = { count = crate_count, timer = crate_time }
    end

    local active_only = settings.bool("april_event_status_active_only", false)
    local next_rows = {}
    for _, definition in ipairs(DEFINITIONS) do
        local item = active[definition.id]
        local is_active = item ~= nil and (item.count or 0) > 0
        if is_active then
            first_seen[definition.id] = first_seen[definition.id] or now
        else
            first_seen[definition.id] = nil
        end

        if is_active or not active_only then
            local status = is_active and "ACTIVE" or "INACTIVE"
            if definition.id == "timed_crate" and is_active then status = "AVAILABLE" end
            if item and item.destroyed then status = "DESTROYED" end

            local elapsed = is_active and format_elapsed(now - (first_seen[definition.id] or now)) or "--:--"
            local meta = elapsed
            if item and item.timer then
                meta = item.timer
            elseif item and item.hp and item.max_hp and item.max_hp > 0 then
                meta = string.format(
                    "%d / %d HP  |  %s",
                    math.floor(item.hp + 0.5),
                    math.floor(item.max_hp + 0.5),
                    elapsed
                )
            end
            if item and item.location then
                meta = tostring(item.location) .. "  |  " .. meta
            end
            if item and (item.count or 0) > 1 then
                meta = tostring(item.count) .. " active  |  " .. meta
            end

            next_rows[#next_rows + 1] = {
                label = definition.label,
                color = definition.color,
                active = is_active,
                status = status,
                meta = meta,
            }
        end
    end
    rows = next_rows
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu.add_checkbox(T, G.MISC, P, "Event Status", false)
    menu.add_checkbox(T, G.MISC, "april_event_status_active_only", "Only Show Active Events", false, root)
    menu_util.bind_master(P, { "april_event_status_active_only" })
end

function M.update(_dt)
    tick_session()
    if not settings.enabled(P) then return end
    local now = tick_ms()
    if now - last_refresh < REFRESH_MS then return end
    last_refresh = now
    rebuild_rows(now)
end

function M.draw()
    tick_session()
    if not settings.enabled(P) then return end
    if not draw or not draw.text then return end

    overlay_theme.sync()
    local sw, sh = draw_util.screen_size()
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * ROW_H + 8
    local x, y = panel_drag.update(
        "event_status", X_ID, Y_ID,
        PANEL_W, TITLE_H, sw, sh,
        sw - PANEL_W - 16, 300
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh)
    overlay_theme.draw_panel(x, y, PANEL_W, height, "EVENT STATUS")

    local ry = y + TITLE_H + 5
    if #rows == 0 then
        draw_util.text(x + 12, ry + 4, "No active events", theme.TEXT_MUTED, 11)
        return
    end

    for _, row in ipairs(rows) do
        local col = row.active and row.color or theme.TEXT_DIM
        if draw.circle_filled then
            draw.circle_filled(x + 16, ry + 8, 3, col, 12)
        end
        draw_util.text(x + 26, ry + 1, row.label, row.active and theme.TEXT or theme.TEXT_MUTED, 11)
        local meta = tostring(row.meta or "")
        if #meta > 42 then meta = meta:sub(1, 40) .. ".." end
        draw_util.text(x + 26, ry + 17, meta, theme.TEXT_MUTED, 10)

        local status_w = theme.text_w(row.status, 9)
        draw_util.text(x + PANEL_W - 12 - status_w, ry + 2, row.status, col, 9)
        ry = ry + ROW_H
    end
end

return M
