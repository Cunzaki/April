local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local player_state = April.require("game.player_state")
local weapons = April.require("game.weapons")
local draw_util = April.require("core.draw_util")
local esp_util = April.require("core.esp_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")
local silent_ray = April.require("core.silent_ray")
local theme = April.require("core.ui_theme")

local M = {}
local locked_target = nil
local PREFIX = "april_aimbot_"
local P_PRED = PREFIX .. "prediction"
local P_VIS = PREFIX .. "vis_ray"
local SHOOT_VK = 0x01

local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.COMBAT)

    menu_util.section(T, G.COMBAT, "Silent Aim")
    menu.add_checkbox(T, G.COMBAT, P_PRED, "Bullet Prediction", false)
    menu.add_checkbox(T, G.COMBAT, P_VIS, "Visualize Silent Ray", false, menu_util.parent(P_PRED))

    combat_menu.register_targeting(T, G.COMBAT, PREFIX, P_PRED, {
        fov_default = 150,
        smooth = false,
        fov_color = theme.CYAN,
        fill_color = theme.alpha(theme.CYAN, 0.12),
        line_color = theme.RED,
    })

    menu_util.bind_master(P_PRED, {
        P_VIS,
        PREFIX .. "fov", PREFIX .. "bone", PREFIX .. "priority", PREFIX .. "sticky", PREFIX .. "visible",
        PREFIX .. "draw_fov", PREFIX .. "fov_fill", PREFIX .. "target_line",
    })
end

local function prediction_active()
    return settings.enabled(P_PRED)
end

local function update_target(cx, cy, fov)
    local sticky = settings.bool(PREFIX .. "sticky", false)

    if sticky and locked_target then
        local ok = targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov)
        if not ok then locked_target = nil end
    end

    if not locked_target or not sticky then
        locked_target = targeting.find_target(cx, cy, fov, PREFIX)
    end
end

function M.update(_dt)
    if not prediction_active() then
        locked_target = nil
        silent_ray.stop()
        return
    end

    if not weapons.holding_ranged_weapon() then
        silent_ray.stop()
        return
    end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)

    update_target(cx, cy, fov)

    if not locked_target or not player_state.is_combat_target(locked_target) then
        silent_ray.stop()
        return
    end

    local cam = camera and camera.get_position and camera.get_position()
    if not cam then
        silent_ray.stop()
        return
    end

    local aim = targeting.get_aim_point(locked_target, PREFIX, nil, cam, cx, cy, true)
    if not aim then
        silent_ray.stop()
        return
    end

    silent_ray.track(cam, aim, SHOOT_VK)
end

function M.get_target()
    return locked_target
end

function M.draw()
    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5

    if prediction_active() and settings.bool(PREFIX .. "draw_fov", false) then
        local fov = settings.num(PREFIX .. "fov", 150)
        local col = settings.color(PREFIX .. "draw_fov", { 0.4, 0.9, 1, 1 })
        if settings.bool(PREFIX .. "fov_fill", false) and draw and draw.circle_filled then
            local fill = settings.color(PREFIX .. "fov_fill", { 0.4, 0.9, 1, 0.12 })
            draw.circle_filled(cx, cy, fov, fill, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end

    if prediction_active() and locked_target and settings.bool(PREFIX .. "target_line", false) then
        local cam = camera and camera.get_position and camera.get_position()
        local aim = targeting.get_aim_point(locked_target, PREFIX, nil, cam, cx, cy, true)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color(PREFIX .. "target_line", { 1, 0.25, 0.25, 1 })
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end

    if not prediction_active() or not settings.bool(P_VIS, false) then return end

    local origin, target = silent_ray.last_segment()
    if not origin or not target then return end

    local col = settings.color(P_VIS, { 0.2, 1, 0.85, 0.95 })
    esp_util.draw_world_line(origin.x, origin.y, origin.z, target.x, target.y, target.z, col, 2)
end

return M
