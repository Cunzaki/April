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

local function aimbot_on()
    return settings.enabled("april_aimbot")
end

local function silent_on()
    return settings.enabled("april_silent_aim")
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

local function resolve_target()
    local silent_mod = April.require("features.combat.aimbot")
    local aim_mod = April.require("features.combat.camera_aimbot")

    if silent_on() and silent_mod then
        local t = silent_mod.get_target and silent_mod.get_target()
        if t then return t, "april_silent_" end
        if silent_mod.get_scoped_target then
            t = silent_mod.get_scoped_target()
            if t then return t, "april_silent_" end
        end
    end

    if aimbot_on() and aim_mod then
        local t = aim_mod.get_target and aim_mod.get_target()
        if t then return t, "april_aim_" end
        if aim_mod.get_scoped_target then
            t = aim_mod.get_scoped_target()
            if t then return t, "april_aim_" end
        end
    end

    return nil, nil
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

local function target_distance(target)
    if not target then return nil end
    local origin = local_origin()
    local dist = ep.distance_to(target, origin)
    if dist then return dist end
    if not origin then return nil end
    local pos = ep.head_position(target) or ep.position(target)
    local x, y, z = esp_util.vec3_pos(pos)
    if not x then return nil end
    local dx, dy, dz = x - origin.x, y - origin.y, z - origin.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Display-only visibility (not the Filters "Visible Only" gate).
local function target_is_visible(target, prefix)
    if not target or not raycast then return false end

    pcall(function()
        April.require("core.api_aliases").apply()
    end)

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local origin = combat_origin.get_camera_origin() or combat_origin.get_fire_origin()
    local aim = targeting.get_aim_point(
        target, prefix or "april_silent_", nil, origin, cx, cy, false
    )

    if targeting.is_npc_target and targeting.is_npc_target(target) then
        if origin and aim and (raycast.is_visible or raycast.IsVisible) then
            local fn = raycast.is_visible or raycast.IsVisible
            local ok, vis = pcall(fn, origin.x, origin.y, origin.z, aim.x, aim.y, aim.z)
            return ok and vis == true
        end
        return false
    end

    local char = target.Character or target.character
    if (not char) and ep.character then
        char = ep.character(target)
    end

    local is_player_vis = raycast.is_player_visible or raycast.IsPlayerVisible
    if char and type(is_player_vis) == "function" then
        local addr = char.Address or char.address
        local ok, vis = pcall(is_player_vis, addr or char)
        if ok then
            return vis == true
        end
    end

    if origin and aim and (raycast.is_visible or raycast.IsVisible) then
        local fn = raycast.is_visible or raycast.IsVisible
        local ok, vis = pcall(fn, origin.x, origin.y, origin.z, aim.x, aim.y, aim.z)
        return ok and vis == true
    end

    return false
end

local function draw_flag(cx, y, text, col)
    local tw = theme.text_w(text, FLAG_SIZE)
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

    local target, prefix = resolve_target()
    if not target then return end

    local i18n = April.require("ui.i18n")
    local t = function(s)
        return (i18n and i18n.t and i18n.t(s)) or s
    end

    if settings.bool(P_VISIBLE, true) and target_is_visible(target, prefix) then
        y = y + draw_flag(cx, y, t("VISIBLE"), theme.GREEN or { 0.35, 1, 0.45, 1 })
    end

    if settings.bool(P_DIST, true) then
        local dist = target_distance(target)
        if dist then
            local col = theme.TEXT or { 0.9, 0.92, 0.95, 1 }
            y = y + draw_flag(cx, y, string.format("%dm", math.floor(dist + 0.5)), col)
        end
    end
end

return M
