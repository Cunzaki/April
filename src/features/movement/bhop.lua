-- Auto-jump while Space is held on the ground (bunny hop).
local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")
local misc_gate = April.require("core.misc_gate")
local ep = April.require("core.entity_props")

local M = {}

local P = "april_bhop_enabled"
local SPACE = 0x20
local GROUND_DIST = 4.0
local JUMP_COOLDOWN_MS = 45

local last_jump_ms = 0

local function tick_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, v = pcall(fn)
    return ok and (tonumber(v) or 0) or 0
end

local function menu_open()
    local ok, ui = pcall(function()
        return April.require("ui.custom_menu")
    end)
    if ok and ui and ui.is_open then
        return ui.is_open() == true
    end
    return false
end

local function on_ground(root, hum)
    if root then
        local pos = move.read_pos(root)
        if pos then
            local dist = move.ground_distance(pos.x, pos.y, pos.z)
            if dist ~= nil then
                return dist <= GROUND_DIST
            end
        end
    end
    if hum then
        local mat = hum.FloorMaterial or hum.floor_material
        if mat ~= nil then
            local n = tonumber(mat)
            -- Air material enum commonly 1792 / 2561 depending on build; treat nil-ish air as airborne.
            if type(mat) == "string" and mat:lower() == "air" then
                return false
            end
            if n == 1792 or n == 2561 or n == 0 then
                return false
            end
            return true
        end
    end
    return false
end

local function pulse_jump(lp, hum)
    if lp then
        pcall(function() lp.Jump = true end)
        pcall(function() lp.IsJumping = true end)
    end
    if hum then
        pcall(function() hum.Jump = true end)
        move.humanoid_state(hum, 3)
    end
end

function M.update(_dt)
    if not settings.enabled(P) then return end
    if not misc_gate.movement_allowed() then return end
    if menu_open() then return end
    if not move.key_down(SPACE) then return end

    local lp = ep.get_local_player() or env.get_local_player()
    if not lp then return end

    local char = ep.character(lp)
    if not char or not env.is_valid(char) then
        local game_lp = game and (game.LocalPlayer or game.local_player)
        char = game_lp and (game_lp.Character or game_lp.character)
    end
    if not char or not env.is_valid(char) then return end

    local hum = ep.humanoid(lp) or env.safe_call(function()
        return char:FindFirstChildOfClass("Humanoid") or char:find_first_child_of_class("Humanoid")
    end)
    if not hum or not env.is_valid(hum) then return end

    local hp = tonumber(hum.Health or hum.health)
    if hp ~= nil and hp <= 0 then return end

    local root = env.safe_call(function()
        return char:FindFirstChild("HumanoidRootPart") or char:find_first_child("HumanoidRootPart")
    end)
    if not on_ground(root, hum) then return end

    local now = tick_ms()
    if now - last_jump_ms < JUMP_COOLDOWN_MS then return end
    last_jump_ms = now
    pulse_jump(lp, hum)
end

function M.draw() end

return M
