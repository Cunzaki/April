local settings = April.require("core.settings")
local weapons = April.require("game.weapons")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")
local math_util = April.require("core.math_util")
local menu_util = April.require("core.menu_util")
local G = menu_util.G
local T = menu_util.tab()

local M = {}
local locked_target = nil
local BONES = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }
local P = "april_aimbot_enabled"

local function screen_center()
    if draw and draw.get_screen_size then
        return draw.get_screen_size()
    end
    return draw_util.screen_size()
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

local function get_bone_name()
    local idx = settings.num("april_aimbot_bone", 0)
    return BONES[(idx or 0) + 1] or "Head"
end

local function get_aim_point(target, bone)
    if not target or not target.is_alive then return nil end
    local sx, sy, vis = target:get_bone_screen(bone)
    if not vis then return nil end

    local pos = target.head_position or target.position
    if not pos then return nil end

    local ax, ay, az = pos.x, pos.y, pos.z

    if settings.bool("april_aimbot_prediction", true) and target.velocity then
        local cam = camera and camera.get_position and camera.get_position()
        if cam then
            local stats = weapons.get_weapon_stats()
            if settings.bool("april_aimbot_auto_weapon", true) then
                stats = weapons.get_weapon_stats()
            end
            if not stats or not settings.bool("april_aimbot_auto_weapon", true) then
                stats = {
                    speed = settings.num("april_aimbot_bullet_speed", 1000),
                    gravity = settings.num("april_aimbot_gravity", 35),
                }
            end
            local speed = (stats and stats.speed) or 1000
            local dx = ax - cam.x
            local dy = ay - cam.y
            local dz = az - cam.z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
            local t = dist / math.max(speed, 1)
            local lead = settings.num("april_aimbot_lead_scale", 1.0)
            ax = ax + target.velocity.x * t * lead
            ay = ay + target.velocity.y * t * lead
            az = az + target.velocity.z * t * lead
        end
    end

    if settings.bool("april_aimbot_drop_prediction", false) then
        local stats = weapons.get_weapon_stats()
        local grav = (stats and stats.gravity) or settings.num("april_aimbot_gravity", 35)
        local cam = camera and camera.get_position and camera.get_position()
        if cam and stats then
            local dist = math_util.distance3(ax - cam.x, ay - cam.y, az - cam.z)
            local t = dist / math.max(stats.speed, 1)
            ay = ay + 0.5 * grav * t * t
        end
    end

    return { x = ax, y = ay, z = az }
end

local function find_target(cx, cy, fov_px)
    if not entity or not entity.get_players then return nil end
    if not settings.bool("april_aimbot_players", true) then return nil end

    local bone = get_bone_name()
    local use_fov_priority = settings.num("april_aimbot_priority", 1) == 1
    local best, best_score = nil, use_fov_priority and fov_px or math.huge
    local cam = camera and camera.get_position and camera.get_position()

    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        local aim = get_aim_point(p, bone)
        if not aim then goto continue end

        if settings.bool("april_aimbot_visible", true) and raycast and raycast.is_visible and cam then
            if not raycast.is_visible(cam.x, cam.y, cam.z, aim.x, aim.y, aim.z) then
                goto continue
            end
        end

        local sx, sy, on_screen = w2s(aim.x, aim.y, aim.z)
        if not on_screen then goto continue end

        local fov_dist = math_util.screen_fov_dist(sx, sy, cx, cy)
        if fov_dist > fov_px then goto continue end

        local score = use_fov_priority and fov_dist or (p.distance_to and cam and p:distance_to(cam) or fov_dist)
        if score < best_score then
            best_score = score
            best = p
        end
        ::continue::
    end
    return best
end

function M.register_menu()
    menu_util.ensure_group(G.AIMBOT)
    menu.add_checkbox(T, G.AIMBOT, P, "Enable Aimbot", false, { key = 0x02 })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_players", "Target Players", true, { parent = P })
    menu.add_slider_int(T, G.AIMBOT, "april_aimbot_fov", "FOV Radius (px)", 50, 500, 150, { parent = P })
    menu.add_slider_int(T, G.AIMBOT, "april_aimbot_smooth", "Smoothing (frames)", 1, 100, 5, { parent = P })
    menu.add_combo(T, G.AIMBOT, "april_aimbot_bone", "Target Bone", { "Head", "UpperTorso", "LowerTorso" }, 0, { parent = P })
    menu.add_combo(T, G.AIMBOT, "april_aimbot_priority", "Target Priority", { "Distance", "Crosshair (FOV)" }, 1, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_sticky", "Sticky Aim", true, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_visible", "Visibility Check", true, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_prediction", "Velocity Prediction", true, { parent = P })
    menu.add_slider_float(T, G.AIMBOT, "april_aimbot_lead_scale", "Lead Scale", 0.5, 2.0, 1.0, "%.2f", { parent = "april_aimbot_prediction" })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_drop_prediction", "Bullet Drop Prediction", false, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_auto_weapon", "Automatic Weapon Stats", true, { parent = P })
    menu.add_slider_int(T, G.AIMBOT, "april_aimbot_bullet_speed", "Manual Bullet Speed", 100, 5000, 1000, { parent = P })
    menu.add_slider_int(T, G.AIMBOT, "april_aimbot_gravity", "Manual Bullet Gravity", 0, 200, 35, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_draw_fov", "Show FOV Circle", true, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_fov_fill", "Fill FOV Circle", false, { parent = "april_aimbot_draw_fov", colorpicker = { 1, 1, 1, 0.2 } })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_target_line", "Target Line", false, { parent = P, colorpicker = { 1, 0, 0, 1 } })
end

function M.update(dt)
    if not settings.bool(P, false) then
        locked_target = nil
        return
    end
    if not aim_key_down() then
        if not settings.bool("april_aimbot_sticky", true) then locked_target = nil end
        return
    end

    local sw, sh = screen_center()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num("april_aimbot_fov", 150)

    if settings.bool("april_aimbot_sticky", true) and locked_target and locked_target.is_alive then
        -- keep
    else
        locked_target = find_target(cx, cy, fov)
    end

    if locked_target and camera and camera.look_at then
        local aim = get_aim_point(locked_target, get_bone_name())
        if aim then
            local smooth = math.max(1, settings.num("april_aimbot_smooth", 5))
            camera.look_at(aim.x, aim.y, aim.z, smooth)
        end
    end
end

function M.draw()
    local sw, sh = screen_center()
    local cx, cy = sw * 0.5, sh * 0.5

    if settings.bool("april_aimbot_draw_fov", true) and settings.bool(P, false) then
        local fov = settings.num("april_aimbot_fov", 150)
        local col = settings.color("april_aimbot_draw_fov", { 1, 1, 1, 1 })
        if settings.bool("april_aimbot_fov_fill", false) and draw and draw.circle_filled then
            local fill = settings.color("april_aimbot_fov_fill", { 1, 1, 1, 0.2 })
            draw.circle_filled(cx, cy, fov, fill, 64)
        end
        if draw and draw.circle then
            draw.circle(cx, cy, fov, col, 64, 1)
        else
            draw_util.circle(cx, cy, fov, col, false)
        end
    end

    if not settings.bool(P, false) or not locked_target or not locked_target.is_alive then return end

    if settings.bool("april_aimbot_target_line", false) then
        local aim = get_aim_point(locked_target, get_bone_name())
        if aim then
            local tx, ty, vis = w2s(aim.x, aim.y, aim.z)
            if vis then
                local col = settings.color("april_aimbot_target_line", { 1, 0, 0, 1 })
                draw_util.line(cx, cy, tx, ty, col, 1.5)
            end
        end
    end

    local b = locked_target:get_bounds()
    if b and b.valid then
        draw_util.box_esp(b.x, b.y, b.w, b.h, { 1, 0.2, 0.2, 1 }, 1)
    end
end

return M
