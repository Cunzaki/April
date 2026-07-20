--[[
  Fake Duck — look crouched (IsCrouch / hip) while moving at stand/sprint speed.

  Fallen StateController sets WalkSpeed=6.5 when crouched. Writing WalkSpeed
  kicks — so we leave WalkSpeed alone and boost HRP velocity to walk(11)/sprint(18).
]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local menu_util = April.require("core.menu_util")
local move = April.require("core.cframe_move")
local misc_gate = April.require("core.misc_gate")
local runservice = April.require("core.runservice")

local M = {}

local P = "april_fakeduck_enabled"
local P_HEIGHT = "april_fakeduck_height"

-- Fallen stand hip = 1.6, normal crouch = 1.1. Lower values push further down.
local DEFAULT_DUCK_HIP = 1.1
local STAND_HIP = 1.6
local SPEED_WALK = 11
local SPEED_SPRINT = 18
local SPEED_AIM_MUL = 0.8
local SPEED_SLOW_MUL = 0.3
local MOVE_EPS = 0.05

local state = {
    was_active = false,
    hooks_installed = false,
    state_ctrl = nil,
    viewmodel = nil,
    root = nil,
    hum = nil,
}

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

local function get_attr(inst, name)
    if not inst then return nil end
    return env.safe_call(function()
        if inst.GetAttribute then return inst:GetAttribute(name) end
        if inst.get_attribute then return inst:get_attribute(name) end
        return nil
    end)
end

local function set_attr(inst, name, value)
    if not inst then return end
    pcall(function()
        if inst.SetAttribute then
            inst:SetAttribute(name, value)
        elseif inst.set_attribute then
            inst:set_attribute(name, value)
        end
    end)
end

local function set_hip_height(hum, value)
    if not hum then return end
    pcall(function() hum.HipHeight = value end)
    local lp = env.get_local_player()
    if lp then
        pcall(function() lp.HipHeight = value end)
    end
end

local function duck_hip()
    local h = settings.num(P_HEIGHT, DEFAULT_DUCK_HIP)
    -- Sub-zero HipHeight is AC-flagged. Keep a tiny floor above 0.
    if h > 1.5 then h = 1.5 end
    if h < 0.01 then h = 0.01 end
    return h
end

-- Slightly squash HRP as we go lower than normal crouch.
local function set_root_size(root, crouch, hip)
    if not root or not Vector3 then return end
    local y = 2.5
    if crouch then
        hip = hip or DEFAULT_DUCK_HIP
        -- 1.1 → 2.1, lower hips → smaller Y (floor ~1.4)
        y = 2.1 - (DEFAULT_DUCK_HIP - hip) * 0.35
        if y < 1.4 then y = 1.4 end
        if y > 2.4 then y = 2.4 end
    end
    pcall(function()
        root.Size = Vector3.new(2, y, 2)
    end)
end

local function resolve_parts()
    local lp = env.get_local_player()
    local char = get_character(lp)
    if not char then
        state.state_ctrl, state.viewmodel, state.root, state.hum = nil, nil, nil, nil
        return false
    end

    state.state_ctrl = find_child(char, "StateController")
    state.viewmodel = find_child(char, "ViewmodelController")
    state.root = move.find_part(char, "HumanoidRootPart") or find_child(char, "HumanoidRootPart")
    state.hum = (lp and (lp.Humanoid or lp.humanoid))
        or move.find_part(char, "Humanoid")
        or find_child(char, "Humanoid")
    return state.root ~= nil
end

local function desired_speed()
    local sc = state.state_ctrl
    local vm = state.viewmodel
    local hum = state.hum

    local sprint = get_attr(sc, "IsSprint") == true
    local aiming = get_attr(vm, "Aiming") == true
    local slowed = false
    if hum then
        local dc = get_attr(hum, "DamageConnections")
        slowed = type(dc) == "number" and dc > 0
    end
    if get_attr(hum, "Downed") == true then return 0 end

    local base = sprint and SPEED_SPRINT or SPEED_WALK
    if aiming then base = base * SPEED_AIM_MUL end
    if slowed then base = base * SPEED_SLOW_MUL end
    return base
end

-- Scale / drive horizontal velocity to stand/sprint speed. Never touch WalkSpeed.
local function boost_velocity(root, target)
    if not root or not target or target <= 0 then return end

    local mx, mz = move.read_flat_input()
    local vx, vy, vz = move.read_velocity(root)
    local input_mag = math.sqrt(mx * mx + mz * mz)

    if input_mag >= MOVE_EPS then
        move.set_velocity(root, mx * target, vy, mz * target)
        return
    end

    -- No WASD: if humanoid still sliding, stretch existing horiz vel up to target.
    local hmag = math.sqrt(vx * vx + vz * vz)
    if hmag < 1.0 then return end
    if hmag >= target * 0.95 then return end
    local s = target / hmag
    move.set_velocity(root, vx * s, vy, vz * s)
end

local function apply_duck()
    if not resolve_parts() then return end

    if state.state_ctrl then
        set_attr(state.state_ctrl, "IsCrouch", true)
    end

    local hip = duck_hip()
    set_hip_height(state.hum, hip)
    set_root_size(state.root, true, hip)

    boost_velocity(state.root, desired_speed())
end

local function restore_duck()
    resolve_parts()
    if state.state_ctrl then
        set_attr(state.state_ctrl, "IsCrouch", false)
    end
    set_hip_height(state.hum, STAND_HIP)
    set_root_size(state.root, false)
end

local function on_sim(_dt)
    if not misc_gate.movement_allowed() then return end
    local on = active()

    if state.was_active and not on then
        restore_duck()
    end
    state.was_active = on

    if not on then return end
    apply_duck()
end

local function ensure_hooks()
    if state.hooks_installed then return end
    state.hooks_installed = true
    runservice.on_sim(on_sim)
end

function M.register_menu()
    local G = menu_util.G
    local T, _ = menu_util.group(G.MISC)
    local root = menu_util.parent(P)

    menu_util.section(T, G.MISC, "Movement")
    menu_util.register_keybind(T, G.MISC, P, "Fake Duck", false)
    menu.add_slider_float(T, G.MISC, P_HEIGHT, "Duck Height", 0.01, 1.5, DEFAULT_DUCK_HIP, "%.2f", root)
    menu_util.bind_children(P, { P_HEIGHT })
end

function M.install()
    ensure_hooks()
end

function M.update(_dt)
    ensure_hooks()
    if not runservice.uses_heartbeat() and misc_gate.movement_allowed() then
        on_sim(_dt)
    elseif state.was_active and not active() then
        restore_duck()
        state.was_active = false
    end
end

function M.draw() end

return M
