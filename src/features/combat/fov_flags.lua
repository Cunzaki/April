-- FOV Flags: status text drawn under the active / larger Aimbot or Silent FOV.
local settings = April.require("core.settings")
local menu_util = April.require("core.menu_util")
local draw_util = April.require("core.draw_util")
local theme = April.require("core.ui_theme")
local targeting = April.require("features.combat.targeting")
local combat_origin = April.require("game.combat_origin")
local ep = April.require("core.entity_props")
local esp_util = April.require("core.esp_util")
local cache = April.require("core.cache")

local M = {}

local P = "april_fov_flags_enabled"
local P_VISIBLE = "april_fov_flags_visible"
local P_DIST = "april_fov_flags_distance"

local FLAG_GAP = 3
local FLAG_SIZE = 12
local VIS_CACHE_MS = 200
local DIST_CACHE_MS = 100
local RESOLVE_MS = 50

local vis_cache = { t = 0, key = nil, visible = false }
local dist_cache = { t = 0, key = nil, dist = nil }
local resolve_cache = { t = 0, target = nil, prefix = nil }
local silent_mod = nil
local aim_mod = nil
local i18n_mod = nil
local i18n_tried = false

local function aimbot_on()
    return settings.enabled("april_aimbot")
end

local function silent_on()
    return settings.enabled("april_silent_aim")
end

local function ensure_mods()
    if not silent_mod then
        pcall(function()
            silent_mod = April.require("features.combat.aimbot")
        end)
    end
    if not aim_mod then
        pcall(function()
            aim_mod = April.require("features.combat.camera_aimbot")
        end)
    end
end

-- Radius to hang flags under: larger of the two enabled FOVs.
local function flag_fov_radius()
    local aim_on = aimbot_on()
    local sil_on = silent_on()
    if not aim_on and not sil_on then
        return nil
    end
    local aim_fov = tonumber(settings.num("april_aim_fov", 120)) or 120
    local sil_fov = tonumber(settings.num("april_silent_fov", 150)) or 150
    if aim_on and sil_on then
        return math.max(aim_fov, sil_fov)
    end
    if aim_on then return aim_fov end
    return sil_fov
end

local function tick_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, v = pcall(fn)
    return (ok and tonumber(v)) or 0
end

-- Prefer locked targets only. Scoped find_target is cached inside aimbots;
-- never force a full rescan from this draw path beyond that cache.
local function resolve_target()
    local now = tick_ms()
    if resolve_cache.target and (now - (resolve_cache.t or 0)) < RESOLVE_MS then
        return resolve_cache.target, resolve_cache.prefix
    end

    ensure_mods()
    local target, prefix = nil, nil

    if silent_on() and silent_mod then
        if silent_mod.get_target then
            target = silent_mod.get_target()
        end
        if not target and silent_mod.get_scoped_target then
            target = silent_mod.get_scoped_target()
        end
        if target then prefix = "april_silent_" end
    end

    if not target and aimbot_on() and aim_mod then
        if aim_mod.get_target then
            target = aim_mod.get_target()
        end
        if not target and aim_mod.get_scoped_target then
            target = aim_mod.get_scoped_target()
        end
        if target then prefix = "april_aim_" end
    end

    resolve_cache.t = now
    resolve_cache.target = target
    resolve_cache.prefix = prefix
    return target, prefix
end

local function local_origin()
    local me = cache.local_player
    if me then
        local x, y, z = esp_util.vec3_pos(
            me.Position or me.position or me.HeadPosition or me.head_position
        )
        if x then return { x = x, y = y, z = z } end
    end
    return combat_origin.get_camera_origin() or combat_origin.get_server_origin()
end

local function target_cache_key(target)
    if not target then return nil end
    local uid = ep.user_id(target)
    if uid and uid ~= 0 then return uid end
    return target.Address or target.address or tostring(target)
end

local function target_distance(target)
    if not target then return nil end
    local now = tick_ms()
    local key = target_cache_key(target)
    if key and dist_cache.key == key and (now - (dist_cache.t or 0)) < DIST_CACHE_MS then
        return dist_cache.dist
    end

    local origin = local_origin()
    local dist = ep.distance_to(target, origin)
    if not dist and origin then
        local pos = ep.head_position(target) or ep.position(target)
        local x, y, z = esp_util.vec3_pos(pos)
        if x then
            local dx, dy, dz = x - origin.x, y - origin.y, z - origin.z
            dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        end
    end

    dist_cache.t = now
    dist_cache.key = key
    dist_cache.dist = dist
    return dist
end

-- Display-only visibility (not the Filters "Visible Only" gate).
-- Cheap path: player visibility API + head-point ray. No get_aim_point / bone solve.
local function target_is_visible(target)
    if not target or not raycast then return false end

    local now = tick_ms()
    local key = target_cache_key(target)
    if key and vis_cache.key == key and (now - (vis_cache.t or 0)) < VIS_CACHE_MS then
        return vis_cache.visible == true
    end

    local visible = false
    local char = target.Character or target.character
    if (not char) and ep.character then
        char = ep.character(target)
    end

    local is_player_vis = raycast.is_player_visible or raycast.IsPlayerVisible
    if char and type(is_player_vis) == "function" then
        local addr = char.Address or char.address
        local ok, vis = pcall(is_player_vis, addr or char)
        if ok then
            visible = vis == true
        end
    end

    if not visible then
        local origin = combat_origin.get_camera_origin()
        local pos = ep.head_position(target) or ep.position(target)
        local x, y, z = esp_util.vec3_pos(pos)
        local fn = raycast.is_visible or raycast.IsVisible
        if origin and x and type(fn) == "function" then
            local ok, vis = pcall(fn, origin.x, origin.y, origin.z, x, y, z)
            visible = ok and vis == true
        end
    end

    vis_cache.t = now
    vis_cache.key = key
    vis_cache.visible = visible
    return visible
end

local function draw_flag(cx, y, text, col)
    local tw = 0
    if theme.text_w then
        tw = theme.text_w(text, FLAG_SIZE) or 0
    elseif draw and (draw.get_text_size or draw.GetTextSize) then
        local fn = draw.get_text_size or draw.GetTextSize
        local ok, w = pcall(fn, text, FLAG_SIZE)
        if ok then tw = tonumber(w) or 0 end
    end
    draw_util.text(cx - tw * 0.5, y, text, col, FLAG_SIZE)
    return FLAG_SIZE + FLAG_GAP
end

function M.register_menu()
    local G = menu_util.G
    local T = menu_util.group(G.SILENT_AIM)
    local root = menu_util.parent(P)

    menu_util.section(T, G.SILENT_AIM, "FOV Flags")
    menu.add_checkbox(T, G.SILENT_AIM, P, "Enable FOV Flags", false)
    menu.add_checkbox(T, G.SILENT_AIM, P_VISIBLE, "Visible Flag", true, root)
    menu.add_checkbox(T, G.SILENT_AIM, P_DIST, "Distance Flag", true, root)

    menu_util.bind_children(P, {
        P_VISIBLE, P_DIST,
    })
end

function M.update(_dt) end

function M.draw()
    if not settings.bool(P, false) then return end
    if not draw then return end

    local fov = flag_fov_radius()
    if not fov then return end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local y = cy + fov + 8

    if not i18n_tried then
        i18n_tried = true
        pcall(function()
            i18n_mod = April.require("ui.i18n")
        end)
    end
    local function t(s)
        return (i18n_mod and i18n_mod.t and i18n_mod.t(s)) or s
    end

    local target = resolve_target()
    if target and settings.bool(P_VISIBLE, true) and target_is_visible(target) then
        y = y + draw_flag(cx, y, t("VISIBLE"), theme.GREEN or { 0.35, 1, 0.45, 1 })
    end

    if target and settings.bool(P_DIST, true) then
        local dist = target_distance(target)
        if dist then
            local col = theme.TEXT or { 0.9, 0.92, 0.95, 1 }
            y = y + draw_flag(cx, y, string.format("%dm", math.floor(dist + 0.5)), col)
        end
    end

end

return M
