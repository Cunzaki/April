-- Camera aimbot: velocity + automatic bullet-drop prediction (weapon stats from dump/toolinfo).
local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local weapons = April.require("game.weapons")
local combat_origin = April.require("game.combat_origin")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_whitelist = April.require("features.combat.silent_whitelist")
local aim_key = April.require("core.aim_key")
local theme = April.require("core.ui_theme")

local M = {}

local locked_target = nil
local PREFIX = "april_aim_"
local P_MASTER = "april_aimbot"
local P_AIM_KEY = "april_aim_key"
local P_AIM_KEY_MODE = "april_aim_key_mode"
local TARGET_SCAN_MS = 33

local cached_aim = nil
local smoothed_aim = nil
local last_target_scan = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

local function holding_weapon()
    if weapons.holding_ranged_weapon() then return true end
    if weapons.get_held_ranged_weapon_name() then return true end
    local lp = entity and entity.get_local_player and entity.get_local_player()
    if lp and lp.tool_name and lp.tool_name ~= "" then
        return weapons.is_ranged_weapon_name(lp.tool_name)
    end
    return false
end

local function enabled()
    return settings.bool(P_MASTER, false)
end

local function aiming()
    if not enabled() then return false end
    aim_key.tick(P_AIM_KEY, P_AIM_KEY_MODE)
    return aim_key.active(P_AIM_KEY, P_AIM_KEY_MODE)
end

local function smooth_alpha()
    local n = settings.num(PREFIX .. "smooth", 10)
    n = math.max(1, math.min(25, n))
    return math.max(0.08, math.min(0.95, 1.25 / n))
end

local function blend_aim(prev, nxt)
    if not nxt then return prev end
    if not prev then return { x = nxt.x, y = nxt.y, z = nxt.z } end
    local a = smooth_alpha()
    return {
        x = prev.x + (nxt.x - prev.x) * a,
        y = prev.y + (nxt.y - prev.y) * a,
        z = prev.z + (nxt.z - prev.z) * a,
    }
end

local function update_target(cx, cy, fov)
    local sticky = settings.multi(PREFIX .. "options", combat_menu.OPT_STICKY, false)
    local now = tick_ms()

    -- NPCs: refresh live head every frame (stale lx/ly/lz + look_at = glued lock).
    if locked_target and targeting.is_npc_target(locked_target) then
        locked_target = targeting.refresh_npc_target(locked_target)
    end

    -- Always drop invalid locks (silent parity). Sticky only skips reacquire.
    if locked_target and not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
        locked_target = nil
        smoothed_aim = nil
    end

    if locked_target and sticky then
        return
    end

    -- Non-sticky: rescan every frame so FOV pick matches where you look (like silent).
    if sticky and now - last_target_scan < TARGET_SCAN_MS then
        return
    end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end

local function resolve_aim_point(target, cx, cy)
    local predict_origin = combat_origin.get_muzzle_origin()
        or combat_origin.get_fire_origin()
        or combat_origin.get_camera_origin()
    return targeting.get_aim_point(target, PREFIX, nil, predict_origin, cx, cy, true)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.SILENT_AIM)

    menu.add_checkbox(T, G, P_MASTER, "Enable Aimbot", false)

    menu.add_combo(T, G, P_AIM_KEY_MODE, "Aim Key Mode", { "Always", "Hold", "Toggle" }, 1,
        { parent = P_MASTER })
    if menu.add_hotkey then
        menu.add_hotkey(T, G, P_AIM_KEY, "Aim Key", 0, { parent = P_MASTER, default_mode = 1 })
    end
    if menu and menu.set_visible then
        pcall(menu.set_visible, P_AIM_KEY_MODE, false)
    end

    combat_menu.register_aimbot(T, G.SILENT_AIM, PREFIX, P_MASTER, {
        fov_default = 120,
        fov_color = theme.GREEN or { 0.2, 1, 0.45, 1 },
        line_color = { 0.2, 1, 0.45, 1 },
    })

    menu_util.bind_children(P_MASTER, {
        P_AIM_KEY, P_AIM_KEY_MODE,
        PREFIX .. "target_type", PREFIX .. "bone",
        PREFIX .. "filters",
        PREFIX .. "whitelist_ids", PREFIX .. "whitelist_clear",
        PREFIX .. "targets", PREFIX .. "options",
        PREFIX .. "smooth",
        PREFIX .. "draw_fov", PREFIX .. "fov_style", PREFIX .. "target_line",
        PREFIX .. "max_dist", PREFIX .. "fov",
    })

    menu_util.bind_children(PREFIX .. "draw_fov", {
        PREFIX .. "fov_style",
    })
end

function M.update(_dt)
    cached_aim = nil

    if not enabled() then
        locked_target = nil
        smoothed_aim = nil
        return
    end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 120)

    update_target(cx, cy, fov)

    if holding_weapon() then
        combat_origin.sync_weapon(weapons.cached_held_ranged() or weapons.get_held_ranged_weapon_name())

        local wl_target = locked_target
        if not wl_target or not targeting.is_aim_target(wl_target) then
            wl_target = targeting.find_target(cx, cy, fov, PREFIX, { ignore_whitelist = true })
        end
        silent_whitelist.tick(wl_target, PREFIX)
    end

    if not locked_target or not targeting.is_aim_target(locked_target) then
        smoothed_aim = nil
        return
    end

    local aim = resolve_aim_point(locked_target, cx, cy)
    if not aim then
        smoothed_aim = nil
        return
    end

    if aiming() and holding_weapon() then
        smoothed_aim = blend_aim(smoothed_aim, aim)
        cached_aim = smoothed_aim

        if camera and camera.look_at then
            local smooth_frames = math.max(1, math.floor(settings.num(PREFIX .. "smooth", 10)))
            pcall(camera.look_at, smoothed_aim.x, smoothed_aim.y, smoothed_aim.z, smooth_frames)
        end
    else
        -- Visuals (target line) use live aim point; camera only moves when aim key is active.
        cached_aim = aim
    end
end

function M.get_target()
    return locked_target
end

function M.get_scoped_target()
    if locked_target then return locked_target end
    if not enabled() then return nil end
    local sw, sh = targeting.screen_center()
    local fov = settings.num(PREFIX .. "fov", 120)
    return targeting.find_target(sw * 0.5, sh * 0.5, fov, PREFIX)
end

function M.draw()
    if not enabled() then return end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 120)

    if settings.bool(PREFIX .. "draw_fov", false) then
        local col = settings.color(PREFIX .. "draw_fov", { 0.2, 1, 0.45, 1 })
        local filled = settings.num(PREFIX .. "fov_style", 1) == 1

        if filled and draw and draw.circle_filled then
            local fill = settings.color(PREFIX .. "draw_fov", { 0.2, 1, 0.45, 0.12 })
            local c = { fill[1], fill[2], fill[3], (fill[4] or 1) * 0.25 }
            draw.circle_filled(cx, cy, fov, c, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end

    if locked_target and settings.bool(PREFIX .. "target_line", false) then
        local aim = cached_aim or smoothed_aim or resolve_aim_point(locked_target, cx, cy)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color(PREFIX .. "target_line", { 0.2, 1, 0.45, 1 })
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end
end

return M
