--[[
  Anti-Aim — continuous body yaw (AutoRotate off + CFrame / angular velocity).

  Same drive as the working yaw AA; pauses while firing (LMB) and snaps
  back to camera yaw so flashpoint / shots stay valid.
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local misc_gate = April.require("core.misc_gate")
local angle_util = April.require("core.angle_util")

local M = {}

local P = "april_antiaim_enabled"
local P_YAW = "april_antiaim_yaw_mode"
local P_YAW_MANUAL = "april_antiaim_yaw_manual"
local P_SPIN = "april_antiaim_spin_speed"
local P_JITTER = "april_antiaim_jitter_step"
local P_JITTER_MS = "april_antiaim_jitter_ms"

local YAW_LABELS = {
    "None", "Backwards", "Spin", "Jitter", "Random Jitter",
    "Sideways Left", "Sideways Right", "Manual",
}
local YAW_MANUAL_IDX = 7
local YAW_SPIN, YAW_JITTER, YAW_RAND = 2, 3, 4

local YAW_GAIN = 22
local YAW_AV_MAX = 40
local YAW_SNAP_EPS = 0.02
local SHOOT_VK = 0x01

local state = {
    fake_yaw = 0,
    yaw_jitter_idx = 0,
    jitter_t = 0,
    random_yaw = 0,
    spin_yaw = 0,
    was_active = false,
    was_firing = false,
}

M.YAW_LABELS = YAW_LABELS

local function active()
    return settings.enabled(P)
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

local function get_character(lp)
    if not lp then lp = env.get_local_player() end
    if lp then
        local char = lp.Character or lp.character
        if char then return char end
    end
    local rp = game and (game.LocalPlayer or game.local_player)
    if rp then return rp.Character or rp.character end
    return nil
end

local function get_humanoid(lp)
    if lp then
        local hum = lp.Humanoid or lp.humanoid
        if hum then return hum end
    end
    local char = get_character(lp)
    return char and (move.find_part(char, "Humanoid") or find_child(char, "Humanoid"))
end

local function get_root(lp)
    local char = get_character(lp)
    if not char then return nil end
    return move.find_part(char, "HumanoidRootPart")
        or find_child(char, "HumanoidRootPart")
        or env.safe_call(function() return char.PrimaryPart or char.primary_part end)
end

local function get_attr(inst, name)
    if not inst then return nil end
    return env.safe_call(function()
        if inst.GetAttribute then return inst:GetAttribute(name) end
        if inst.get_attribute then return inst:get_attribute(name) end
        return nil
    end)
end

-- LMB or Fallen ViewmodelController Using / Aiming fire path.
local function is_firing(char)
    if input and input.is_key_down and input.is_key_down(SHOOT_VK) then
        return true
    end
    local vm = char and find_child(char, "ViewmodelController")
    if vm then
        if get_attr(vm, "Using") == true then return true end
    end
    return false
end

local function compute_fake_yaw(real_yaw, dt)
    local mode = settings.combo_index(P_YAW, YAW_LABELS, 0)
    if mode == 0 then return nil end
    dt = dt or 0.016
    if mode == 1 then return angle_util.normalize_yaw(real_yaw + math.pi) end
    if mode == 2 then
        state.spin_yaw = angle_util.normalize_yaw(state.spin_yaw + math.rad(settings.num(P_SPIN, 180)) * dt)
        return angle_util.normalize_yaw(real_yaw + state.spin_yaw)
    end
    if mode == 3 then
        local step = math.max(15, settings.num(P_JITTER, 90))
        return angle_util.normalize_yaw(real_yaw + math.rad(state.yaw_jitter_idx * step))
    end
    if mode == 4 then return angle_util.normalize_yaw(real_yaw + state.random_yaw) end
    if mode == 5 then return angle_util.normalize_yaw(real_yaw + math.pi * 0.5) end
    if mode == 6 then return angle_util.normalize_yaw(real_yaw - math.pi * 0.5) end
    return angle_util.normalize_yaw(real_yaw + math.rad(settings.num(P_YAW_MANUAL, 90)))
end

local function advance_jitter(dt)
    local yaw_m = settings.combo_index(P_YAW, YAW_LABELS, 0)
    if yaw_m ~= YAW_JITTER and yaw_m ~= YAW_RAND then return end

    local interval = math.max(0.04, settings.num(P_JITTER_MS, 120) / 1000)
    state.jitter_t = state.jitter_t + dt
    if state.jitter_t < interval then return end
    state.jitter_t = 0

    local step = math.max(15, settings.num(P_JITTER, 90))
    if yaw_m == YAW_JITTER then
        state.yaw_jitter_idx = (state.yaw_jitter_idx + 1) % math.max(1, math.floor(360 / step))
    end
    if yaw_m == YAW_RAND then
        state.random_yaw = math.random() * math.pi * 2
    end
end

local function disable_auto_rotate(lp, hum)
    if lp then pcall(function() lp.AutoRotate = false end) end
    if hum then
        pcall(function() hum.AutoRotate = false end)
        pcall(function() hum.auto_rotate = false end)
    end
end

local function restore_auto_rotate(lp, hum)
    if lp then pcall(function() lp.AutoRotate = true end) end
    if hum then
        pcall(function() hum.AutoRotate = true end)
        pcall(function() hum.auto_rotate = true end)
    end
end

local function write_yaw(char, root, yaw)
    if yaw == nil or not root or not CFrame then return end
    local pos = move.read_pos(root)
    if not pos then return end
    local cf = CFrame.new(pos.x, pos.y, pos.z) * CFrame.Angles(0, yaw, 0)
    pcall(function() root.CFrame = cf end)
    if char then
        pcall(function()
            if char.PivotTo then char:PivotTo(cf) end
        end)
    end
end

local function steer_yaw(root, body_yaw, target_yaw)
    if target_yaw == nil or not root then return end
    local mode = settings.combo_index(P_YAW, YAW_LABELS, 0)
    if mode == YAW_SPIN then
        move.set_angular_velocity(root, 0, math.rad(settings.num(P_SPIN, 180)), 0)
        return
    end
    local diff = angle_util.yaw_delta(body_yaw, target_yaw)
    if math.abs(diff) < YAW_SNAP_EPS then
        move.set_angular_velocity(root, 0, 0, 0)
        return
    end
    local av = diff * YAW_GAIN
    if av > YAW_AV_MAX then av = YAW_AV_MAX elseif av < -YAW_AV_MAX then av = -YAW_AV_MAX end
    move.set_angular_velocity(root, 0, av, 0)
end

local function face_camera(lp, char, root, hum)
    local yaw = angle_util.camera_yaw()
    write_yaw(char, root, yaw)
    if root then move.set_angular_velocity(root, 0, 0, 0) end
    restore_auto_rotate(lp, hum)
end

local function tick_aa(dt)
    local lp = env.get_local_player()
    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not root then return end

    disable_auto_rotate(lp, hum)
    advance_jitter(dt)

    local real_yaw = angle_util.camera_yaw()
    local fake_yaw = compute_fake_yaw(real_yaw, dt)
    if fake_yaw == nil then
        move.set_angular_velocity(root, 0, 0, 0)
        return
    end

    state.fake_yaw = fake_yaw
    local body_yaw = angle_util.body_yaw(lp, root)
    write_yaw(char, root, fake_yaw)
    steer_yaw(root, body_yaw, fake_yaw)
end

local function sync_option_visibility()
    if not menu or not menu.set_visible then return end
    local on = active()
    local yaw_m = settings.combo_index(P_YAW, YAW_LABELS, 0)
    pcall(menu.set_visible, P_YAW_MANUAL, on and yaw_m == YAW_MANUAL_IDX)
    pcall(menu.set_visible, P_SPIN, on and yaw_m == YAW_SPIN)
    pcall(menu.set_visible, P_JITTER, on and (yaw_m == YAW_JITTER or yaw_m == YAW_RAND))
    pcall(menu.set_visible, P_JITTER_MS, on and (yaw_m == YAW_JITTER or yaw_m == YAW_RAND))
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Movement")
    menu_util.register_keybind(T, G.MISC, P, "Anti-Aim", false)
    menu.add_combo(T, G.MISC, P_YAW, "Yaw Mode", YAW_LABELS, 1, root)
    menu.add_slider_int(T, G.MISC, P_YAW_MANUAL, "Manual Yaw", -180, 180, 90,
        menu_util.parent(P_YAW, { parent_value = YAW_MANUAL_IDX }))
    menu.add_slider_int(T, G.MISC, P_SPIN, "Spin Speed", 30, 720, 180, root)
    menu.add_slider_int(T, G.MISC, P_JITTER, "Jitter Step", 15, 180, 90, root)
    menu.add_slider_int(T, G.MISC, P_JITTER_MS, "Jitter Interval (ms)", 40, 500, 120, root)

    menu_util.bind_children(P, {
        P_YAW, P_YAW_MANUAL, P_SPIN, P_JITTER, P_JITTER_MS,
    })

    if menu and menu.set_callback then
        pcall(menu.set_callback, P, sync_option_visibility)
        pcall(menu.set_callback, P_YAW, sync_option_visibility)
    end
    sync_option_visibility()
end

function M.install() end

function M.update(dt)
    sync_option_visibility()
    dt = dt or 0.016

    local lp = env.get_local_player()
    local char = get_character(lp)
    local root = get_root(lp)
    local hum = get_humanoid(lp)
    local on = active() and misc_gate.movement_allowed()
    local firing = on and is_firing(char)

    if state.was_active and (not on or firing) then
        if root then move.set_angular_velocity(root, 0, 0, 0) end
        if firing and on then
            face_camera(lp, char, root, hum)
        else
            restore_auto_rotate(lp, hum)
            state.spin_yaw = 0
            state.jitter_t = 0
        end
    end

    -- Leaving fire: re-engage AA next tick.
    if state.was_firing and on and not firing then
        disable_auto_rotate(lp, hum)
    end

    state.was_active = on and not firing
    state.was_firing = firing

    if not on or firing then return end
    if settings.combo_index(P_YAW, YAW_LABELS, 0) == 0 then return end
    tick_aa(dt)
end

function M.draw() end

return M
