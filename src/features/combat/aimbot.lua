local settings = April.require("core.settings")
local cache = April.require("core.cache")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")
local math_util = April.require("core.math_util")
local G = April.require("core.menu_util").G
local T = April.require("core.menu_util").tab()

local M = {}
local locked_target = nil
local BONES = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }
local P = "april_aimbot_enabled"

function M.register_menu()
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_enabled", "Enable Aimbot", false, { key = 0 })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_players", "Target Players", true, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_npcs", "Target NPCs", false, { parent = P })
    menu.add_slider_int(T, G.AIMBOT, "april_aimbot_fov", "FOV Radius", 50, 500, 150, { parent = P })
    menu.add_slider_int(T, G.AIMBOT, "april_aimbot_smooth", "Smoothing", 1, 100, 5, { parent = P })
    menu.add_combo(T, G.AIMBOT, "april_aimbot_bone", "Target Bone", { "Head", "UpperTorso", "LowerTorso" }, 0, { parent = P })
    menu.add_combo(T, G.AIMBOT, "april_aimbot_priority", "Target Priority", { "Distance", "Crosshair (FOV)" }, 1, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_sticky", "Sticky Aim", true, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_visible", "Visibility Check", true, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_prediction", "Velocity Prediction", true, { parent = P })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_draw_fov", "Show FOV Circle", true, { parent = P, colorpicker = { 1, 1, 1, 1 } })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_fov_fill", "Fill FOV Circle", false, { parent = "april_aimbot_draw_fov", colorpicker = { 1, 1, 1, 0.2 } })
    menu.add_checkbox(T, G.AIMBOT, "april_aimbot_target_line", "Target Line", false, { parent = P, colorpicker = { 1, 0, 0, 1 } })
end

local function get_bone_name()
    local idx = settings.num("april_aimbot_bone", 0)
    return BONES[(idx or 0) + 1] or "Head"
end

local function key_active()
    if input and input.is_key_down then
        return input.is_key_down(0x02)
    end
    return false
end

local function find_target(cx, cy, fov)
    if not entity or not entity.get_players then return nil end
    if not settings.bool("april_aimbot_players", true) then return nil end
    local bone = get_bone_name()
    local priority_fov = settings.num("april_aimbot_priority", 1) == 1
    local best, best_score = nil, priority_fov and fov or math.huge
    local me = entity.get_local_player()

    for _, p in ipairs(entity.get_players()) do
        if p.is_local or not p.is_alive then goto continue end
        local sx, sy, vis = p:get_bone_screen(bone)
        if not vis then goto continue end
        if settings.bool("april_aimbot_visible", true) and raycast and raycast.is_visible then
            local cam = camera and camera.get_position and camera.get_position()
            local head = p.head_position
            if cam and head and not raycast.is_visible(cam.x, cam.y, cam.z, head.x, head.y, head.z) then
                goto continue
            end
        end
        local score
        if priority_fov then
            score = math_util.screen_fov_dist(sx, sy, cx, cy)
        elseif me and p.position and me.position then
            local dx = p.position.x - me.position.x
            local dy = p.position.y - me.position.y
            local dz = p.position.z - me.position.z
            score = math.sqrt(dx * dx + dy * dy + dz * dz)
        else
            score = math_util.screen_fov_dist(sx, sy, cx, cy)
        end
        if score < best_score then
            best_score = score
            best = p
        end
        ::continue::
    end
    return best
end

function M.update(dt)
    if not settings.bool("april_aimbot_enabled", false) then
        locked_target = nil
        return
    end
    if not key_active() then
        if not settings.bool("april_aimbot_sticky", true) then locked_target = nil end
        return
    end

    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num("april_aimbot_fov", 150)

    if settings.bool("april_aimbot_sticky", true) and locked_target and locked_target.is_alive then
        -- keep lock
    else
        locked_target = find_target(cx, cy, fov)
    end

    if locked_target and camera and camera.look_at then
        local bone = get_bone_name()
        local sx, sy, vis = locked_target:get_bone_screen(bone)
        if vis then
            local pos = locked_target.head_position or locked_target.position
            if pos then
                local smooth = math.max(1, settings.num("april_aimbot_smooth", 5))
                camera.look_at(pos.x, pos.y, pos.z, smooth)
            end
        end
    end
end

function M.draw()
    if not settings.bool("april_aimbot_enabled", false) then return end
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num("april_aimbot_fov", 150)

    if settings.bool("april_aimbot_draw_fov", true) then
        local col = settings.color("april_aimbot_draw_fov", { 1, 1, 1, 1 })
        if menu and menu.get_color then
            local c = menu.get_color("april_aimbot_draw_fov")
            if c then col = c end
        end
        draw_util.circle(cx, cy, fov, col, settings.bool("april_aimbot_fov_fill", false))
    end

    if locked_target and locked_target.is_alive then
        local b = locked_target:get_bounds()
        if b and b.valid then
            draw_util.box_esp(b.x, b.y, b.w, b.h, { 1, 0.2, 0.2, 1 }, 1)
        end
        if settings.bool("april_aimbot_target_line", false) and utility and utility.world_to_screen then
            local pos = locked_target.head_position or locked_target.position
            if pos then
                local tx, ty, vis = utility.world_to_screen(pos.x, pos.y, pos.z)
                if vis then
                    local col = settings.color("april_aimbot_target_line", { 1, 0, 0, 1 })
                    draw_util.line(cx, cy, tx, ty, col, 1.5)
                end
            end
        end
    end
end

return M
