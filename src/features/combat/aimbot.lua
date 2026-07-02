local settings = April.require("core.settings")
local cache = April.require("core.cache")
local env = April.require("core.env")
local draw_util = April.require("core.draw_util")
local math_util = April.require("core.math_util")

local M = {}
local locked_target = nil
local BONES = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }

function M.register_menu()
    menu.add_group(April.TAB, "Aimbot")
    menu.add_checkbox(April.TAB, "Aimbot", "april_aimbot_enabled", "Enable Aimbot", false)
    menu.add_hotkey(April.TAB, "Aimbot", "april_aimbot_key", "Aim Key", 0x02)
    menu.add_slider_int(April.TAB, "Aimbot", "april_aimbot_fov", "FOV", 10, 600, 120)
    menu.add_combo(April.TAB, "Aimbot", "april_aimbot_bone", "Bone", { "Head", "UpperTorso", "LowerTorso" }, 0)
    menu.add_checkbox(April.TAB, "Aimbot", "april_aimbot_sticky", "Sticky Aim", true)
    menu.add_checkbox(April.TAB, "Aimbot", "april_aimbot_visible", "Visibility Check", true)
    menu.add_checkbox(April.TAB, "Aimbot", "april_aimbot_draw_fov", "Draw FOV", true)
    menu.add_colorpicker(April.TAB, "Aimbot", "april_aimbot_fov_color", "FOV Color", { 1, 1, 1, 0.35 })
end

local function get_bone_name()
    local idx = settings.num("april_aimbot_bone", 0)
    return BONES[(idx or 0) + 1] or "Head"
end

local function key_active()
    local vk = settings.num("april_aimbot_key", 0x02)
    if input and input.is_key_down then return input.is_key_down(vk) end
    return false
end

local function find_target(cx, cy, fov)
    if not entity or not entity.get_players then return nil end
    local bone = get_bone_name()
    local best, best_dist = nil, fov
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
        local d = math_util.screen_fov_dist(sx, sy, cx, cy)
        if d < best_dist then
            best_dist = d
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
    local fov = settings.num("april_aimbot_fov", 120)

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
                camera.look_at(pos.x, pos.y, pos.z, 8)
            end
        end
    end
end

function M.draw()
    if not settings.bool("april_aimbot_draw_fov", true) then return end
    local sw, sh = draw_util.screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local fov = settings.num("april_aimbot_fov", 120)
    local col = settings.color("april_aimbot_fov_color", { 1, 1, 1, 0.35 })
    draw_util.circle(cx, cy, fov, col, false)

    if locked_target and locked_target.is_alive then
        local b = locked_target:get_bounds()
        if b and b.valid then
            draw_util.box_esp(b.x, b.y, b.w, b.h, { 1, 0.2, 0.2, 1 }, 1)
        end
    end
end

return M
