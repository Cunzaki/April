local settings = April.require("core.settings")
local targeting = April.require("features.combat.targeting")
local draw_util = April.require("core.draw_util")
local menu_util = April.require("core.menu_util")
local combat_menu = April.require("features.combat.combat_menu")

local M = {}
local locked_target = nil
local P = "april_aimbot_enabled"
local PREFIX = "april_aimbot_"

local function w2s(x, y, z)
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    if utility and utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

local function aim_key_down()
    if not menu or not menu.get_key then return false end
    local vk = menu.get_key(P)
    if vk and vk > 0 and input and input.is_key_down then
        return input.is_key_down(vk)
    end
    if input and input.is_key_down then
        return input.is_key_down(0x02)
    end
    return false
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.AIMBOT)
    menu.add_checkbox(T, G.AIMBOT, P, "Enable Aimbot", false, { key = 0x02 })
    menu.add_label(T, G.AIMBOT, "Auto weapon drop + velocity prediction (always on).")
    combat_menu.register_targeting(T, G.AIMBOT, PREFIX, P, {
        fov_default = 150,
        smooth = true,
        fov_color = { 0.4, 0.9, 1, 1 },
        fill_color = { 0.4, 0.9, 1, 0.12 },
        line_color = { 1, 0.25, 0.25, 1 },
    })
end

function M.update(dt)
    if not settings.bool(P, false) then
        locked_target = nil
        return
    end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num(PREFIX .. "fov", 150)
    local sticky = settings.bool(PREFIX .. "sticky", false)

    if not aim_key_down() then
        if not sticky then locked_target = nil end
        return
    end

    if sticky and locked_target then
        local ok = targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov)
        if not ok then locked_target = nil end
    end

    if not locked_target or not sticky then
        locked_target = targeting.find_target(cx, cy, fov, PREFIX)
    end

    if locked_target and camera and camera.look_at then
        local cam = camera.get_position and camera.get_position()
        local aim = targeting.get_aim_point(locked_target, PREFIX, nil, cam, cx, cy)
        if aim then
            local smooth = math.max(1, settings.num(PREFIX .. "smooth", 5))
            camera.look_at(aim.x, aim.y, aim.z, smooth)
        else
            locked_target = nil
        end
    end
end

function M.draw()
    if not settings.bool(P, false) then return end

    local sw, sh = targeting.screen_center()
    local cx, cy = sw * 0.5, sh * 0.5

    if settings.bool(PREFIX .. "draw_fov", false) then
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

    if not locked_target or not locked_target.is_alive then return end

    if settings.bool(PREFIX .. "target_line", false) then
        local cam = camera and camera.get_position and camera.get_position()
        local aim = targeting.get_aim_point(locked_target, PREFIX, nil, cam, cx, cy)
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color(PREFIX .. "target_line", { 1, 0.25, 0.25, 1 })
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end
end

return M
