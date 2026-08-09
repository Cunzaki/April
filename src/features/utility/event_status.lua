local settings = April.require("core.settings")
local cache = April.require("core.cache")
local env = April.require("core.env")
local folders = April.require("game.folders")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local panel_drag = April.require("core.panel_drag")
local overlay_theme = April.require("core.overlay_theme")
local theme = April.require("core.ui_theme")
local notify = April.require("core.notify")
local esp_util = April.require("core.esp_util")

local M = {}
local P = "april_event_status_enabled"
local X_ID = "april_event_status_x"
local Y_ID = "april_event_status_y"
local PANEL_W = 350
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

-- Guide + BTR Crate FIRE/Locked dump: loot burns for 13 minutes after destroy.
local BTR_LOOT_CD_MS = 13 * 60 * 1000

local rows = {}
local first_seen = {}
local last_refresh = -REFRESH_MS
local session_token = nil
local btr_was_destroyed = false
local btr_loot_until = nil
local btr_crate_seen_at = nil
local known_active = {}
local initial_event_scan = true

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function local_position()
    local me = cache.local_player
    if not me then return nil end
    local x, y, z = esp_util.vec3_pos(
        me.Position or me.position or me.HeadPosition or me.head_position
    )
    if not x then return nil end
    return x, y, z
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
    btr_was_destroyed = false
    btr_loot_until = nil
    btr_crate_seen_at = nil
    known_active = {}
    initial_event_scan = true
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
    local local_x, local_y, local_z = local_position()
    for _, entry in ipairs(cache.npcs or {}) do
        local id = entry and entry.kind
        if id == "heli" then id = "attack_heli" end
        if id == "btr" or id == "attack_heli" or id == "bruno"
            or id == "boris" or id == "brutus"
        then
            local item = state[id] or { count = 0 }
            item.count = item.count + 1
            local dist = nil
            if local_x and entry.lx and entry.ly and entry.lz then
                local dx, dy, dz = entry.lx - local_x, entry.ly - local_y, entry.lz - local_z
                dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            end
            if not item.distance or (dist and dist < item.distance) then
                item.distance = dist or item.distance
                item.location = entry.location or item.location
                item.x, item.y, item.z = entry.lx, entry.ly, entry.lz
            end
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

local function model_name(inst)
    return inst and (inst.Name or inst.name) or ""
end

local function is_btr_crate(inst)
    local name = model_name(inst)
    return name == "BTR Crate" or (name:find("BTR Crate", 1, true) ~= nil)
end

local function crate_locked(model)
    if env.get_attribute(model, "Locked") == true then return true end
    if env.get_attribute(model, "BreakLocked") == true then return true end
    local main = find_child(model, "Main")
    local fire = find_child(main, "FIRE")
    if fire then
        local enabled = env.safe_call(function()
            if fire.Enabled ~= nil then return fire.Enabled end
            return fire.enabled
        end)
        if enabled == true then return true end
    end
    return false
end

-- Runtime BTR crates land under Bases/Loners or Drops depending on server path.
local function scan_btr_crates(now)
    local count, locked_count = 0, 0
    local buckets = {
        find_child(folders.from_key("loners"), "BTR Crate"),
        folders.from_key("drops"),
        folders.from_key("bases"),
        folders.from_key("events"),
    }
    for _, bucket in ipairs(buckets) do
        for _, child in ipairs(children(bucket)) do
            local model = child
            local name = model_name(child)
            if name == "BTR Crate" then
                -- folder of crates
                for _, nested in ipairs(children(child)) do
                    if is_btr_crate(nested) or model_name(nested) == "Default" or find_child(nested, "Main") then
                        count = count + 1
                        if crate_locked(nested) then locked_count = locked_count + 1 end
                    end
                end
            elseif is_btr_crate(child) or (find_child(child, "Main") and name:find("BTR", 1, true)) then
                count = count + 1
                if crate_locked(child) then locked_count = locked_count + 1 end
            end
        end
    end

    if count > 0 then
        btr_crate_seen_at = btr_crate_seen_at or now
    else
        btr_crate_seen_at = nil
    end
    return count, locked_count
end

local function update_btr_loot_timer(now, btr_item, crate_count, locked_count)
    local destroyed = btr_item and btr_item.destroyed == true
    local live = btr_item and (btr_item.count or 0) > 0 and not destroyed

    if live then
        btr_was_destroyed = false
        btr_loot_until = nil
        return
    end

    if destroyed and not btr_was_destroyed then
        btr_loot_until = now + BTR_LOOT_CD_MS
    end
    btr_was_destroyed = destroyed

    -- Joined mid-burn or missed Destroyed edge: infer from locked BTR crates.
    if (not btr_loot_until or btr_loot_until <= now)
        and crate_count > 0
        and locked_count > 0
        and btr_crate_seen_at
    then
        btr_loot_until = btr_crate_seen_at + BTR_LOOT_CD_MS
    end

    if btr_loot_until and btr_loot_until <= now and locked_count == 0 and crate_count == 0 and not destroyed then
        btr_loot_until = nil
    end
end

local function rebuild_rows(now)
    local active = npc_event_state()
    local crate_count, crate_time = timed_crates()
    if crate_count > 0 then
        active.timed_crate = { count = crate_count, timer = crate_time }
    end

    local btr_crates, btr_locked = scan_btr_crates(now)
    update_btr_loot_timer(now, active.btr, btr_crates, btr_locked)

    local active_only = settings.bool("april_event_status_active_only", false)
    local next_rows = {}
    for _, definition in ipairs(DEFINITIONS) do
        local item = active[definition.id]
        local is_active = item ~= nil and (item.count or 0) > 0
        if not initial_event_scan and known_active[definition.id] ~= is_active and settings.bool("april_event_status_notify", true) then
            local detail = ""
            if is_active and item then
                if item.location and item.location ~= "" then detail = " at " .. tostring(item.location) end
                if settings.bool("april_event_status_distance", true) and item.distance then
                    detail = detail .. string.format(" (%dm)", math.floor(item.distance + 0.5))
                end
            end
            notify.info(definition.label .. (is_active and " event active" or " event ended") .. detail, 3500)
        end
        known_active[definition.id] = is_active
        local loot_left = nil
        if definition.id == "btr" and btr_loot_until then
            loot_left = btr_loot_until - now
        end
        local loot_cooling = definition.id == "btr" and loot_left ~= nil and loot_left > 0
        local loot_ready = definition.id == "btr"
            and btr_loot_until ~= nil
            and loot_left ~= nil
            and loot_left <= 0
            and (btr_crates > 0 or (item and item.destroyed))

        if is_active then
            first_seen[definition.id] = first_seen[definition.id] or now
        elseif not loot_cooling and not loot_ready then
            first_seen[definition.id] = nil
        end

        local show = is_active or loot_cooling or loot_ready or not active_only
        if show then
            local status = is_active and "ACTIVE" or "INACTIVE"
            if definition.id == "timed_crate" and is_active then status = "AVAILABLE" end
            if item and item.destroyed then status = "DESTROYED" end
            if loot_cooling then status = "LOOT CD" end
            if loot_ready then status = "LOOT READY" end

            local elapsed = is_active and format_elapsed(now - (first_seen[definition.id] or now)) or "--:--"
            local meta = elapsed
            if item and item.timer then
                meta = item.timer
            elseif settings.bool("april_event_status_health", true)
                and item and item.hp and item.max_hp and item.max_hp > 0 and not loot_cooling
            then
                meta = string.format(
                    "%d / %d HP  |  %s",
                    math.floor(item.hp + 0.5),
                    math.floor(item.max_hp + 0.5),
                    elapsed
                )
            end
            if loot_cooling then
                meta = "Loot fire  " .. format_elapsed(loot_left)
                if btr_crates > 0 then
                    meta = meta .. "  |  " .. tostring(btr_crates) .. " crate" .. (btr_crates > 1 and "s" or "")
                end
            elseif loot_ready then
                meta = "Loot unlocked"
                if btr_crates > 0 then
                    meta = tostring(btr_crates) .. " crate" .. (btr_crates > 1 and "s" or "") .. "  |  " .. meta
                end
            end
            if item and item.location and not loot_cooling then
                meta = tostring(item.location) .. "  |  " .. meta
            end
            if settings.bool("april_event_status_distance", true) and item and item.distance and not loot_cooling then
                meta = string.format("%dm  |  %s", math.floor(item.distance + 0.5), meta)
            end
            if item and (item.count or 0) > 1 then
                meta = tostring(item.count) .. " active  |  " .. meta
            end

            next_rows[#next_rows + 1] = {
                label = definition.label,
                color = definition.color,
                active = is_active or loot_cooling or loot_ready,
                status = status,
                meta = meta,
                distance = item and item.distance or nil,
                order = #next_rows + 1,
            }
        end
    end
    local sort_mode = math.floor(settings.num("april_event_status_sort", 1))
    if sort_mode ~= 0 then
        table.sort(next_rows, function(a, b)
            if sort_mode == 1 and a.active ~= b.active then return a.active end
            local ad, bd = a.distance or math.huge, b.distance or math.huge
            if ad ~= bd then return ad < bd end
            if a.active ~= b.active then return a.active end
            return a.order < b.order
        end)
    end
    rows = next_rows
    initial_event_scan = false
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.MISC)
    local root = menu_util.parent(P)
    menu.add_checkbox(T, G.MISC, P, "Event Status", false)
    menu.add_checkbox(T, G.MISC, "april_event_status_active_only", "Only Show Active Events", false, root)
    menu.add_checkbox(T, G.MISC, "april_event_status_notify", "Event Notifications", true, root)
    menu.add_checkbox(T, G.MISC, "april_event_status_distance", "Show Event Distance", true, root)
    menu.add_checkbox(T, G.MISC, "april_event_status_health", "Show Event Health", true, root)
    menu.add_combo(T, G.MISC, "april_event_status_sort", "Event Sorting",
        { "Game Order", "Active First", "Nearest First" }, 1, root)
    menu_util.bind_master(P, {
        "april_event_status_active_only", "april_event_status_notify",
        "april_event_status_distance", "april_event_status_health", "april_event_status_sort",
    })
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

    local sw, sh = draw_util.screen_size()
    local count = math.max(#rows, 1)
    local height = TITLE_H + count * ROW_H + 8
    local x, y = panel_drag.update(
        "event_status", X_ID, Y_ID,
        PANEL_W, TITLE_H, sw, sh,
        sw - PANEL_W - 16, 300
    )
    x, y = panel_drag.clamp(x, y, PANEL_W, height, sw, sh)
    local i18n = April.require("ui.i18n")
    overlay_theme.draw_panel(x, y, PANEL_W, height, i18n.t("EVENT STATUS"))

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
        if #meta > 48 then meta = meta:sub(1, 46) .. ".." end
        draw_util.text(x + 26, ry + 17, meta, theme.TEXT_MUTED, 10)

        local status_w = theme.text_w(row.status, 9)
        draw_util.text(x + PANEL_W - 12 - status_w, ry + 2, row.status, col, 9)
        ry = ry + ROW_H
    end
end

return M
