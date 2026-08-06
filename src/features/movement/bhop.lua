-- Auto-jump while Space is held on the ground (bunny hop).
-- Pulse Humanoid/entity Jump every frame while grounded — same idea as a
-- Jump-request write each Heartbeat, not ChangeState spam.
local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")
local misc_gate = April.require("core.misc_gate")
local ep = April.require("core.entity_props")

local M = {}

local P = "april_bhop_enabled"
local SPACE = 0x20
-- ground_distance casts from (y + 2); height above floor ≈ dist - 2.
local MAX_GROUND_HEIGHT = 3.5
local RAY_ORIGIN_LIFT = 2

local function menu_open()
    local ok, ui = pcall(function()
        return April.require("ui.custom_menu")
    end)
    if ok and ui and ui.is_open then
        return ui.is_open() == true
    end
    return false
end

local function read_vy(root, lp)
    if root then
        local _, vy = move.read_velocity(root)
        if vy ~= nil then return vy end
    end
    if lp then
        local vel = lp.Velocity or lp.velocity
        if vel then
            return tonumber(vel.Y or vel.y)
        end
    end
    return nil
end

local function floor_is_air(hum)
    if not hum then return nil end
    local ok, mat = pcall(function()
        return hum.FloorMaterial or hum.floor_material
    end)
    if not ok or mat == nil then return nil end
    if type(mat) == "string" then
        local lower = mat:lower()
        if lower == "air" or lower == "enum.material.air" then
            return true
        end
        return false
    end
    local n = tonumber(mat)
    -- Common Air enum ints seen across Roblox / external dumps.
    if n == 1792 or n == 2561 or n == 0 then
        return true
    end
    return false
end

local function on_ground(root, hum, lp)
    local air = floor_is_air(hum)
    if air == true then return false end
    if air == false then return true end

    local vy = read_vy(root, lp)

    -- Rising hard or freefalling → air.
    if vy ~= nil then
        if vy > 12 then return false end
        if vy < -35 then return false end
    end

    if root then
        local pos = move.read_pos(root)
        if pos then
            local dist = move.ground_distance(pos.x, pos.y, pos.z)
            if dist ~= nil then
                local height = dist - RAY_ORIGIN_LIFT
                if height <= MAX_GROUND_HEIGHT then
                    return true
                end
                if height > MAX_GROUND_HEIGHT + 2 then
                    return false
                end
            end
        end
    end

    -- Soft fallback when raycast is unavailable: near-zero vertical speed.
    if vy ~= nil and math.abs(vy) <= 4 then
        return true
    end
    return false
end

local function request_jump(lp, hum)
    -- Vector docs: entity local player Jump is writable.
    if lp then
        pcall(function() lp.Jump = true end)
    end
    local elp_fn = entity and (entity.get_local_player or entity.GetLocalPlayer)
    if type(elp_fn) == "function" then
        local ok, elp = pcall(elp_fn)
        if ok and elp then
            pcall(function() elp.Jump = true end)
        end
    end
    if hum then
        pcall(function() hum.Jump = true end)
        pcall(function()
            if hum.ChangeState then
                hum:ChangeState(3)
            elseif hum.change_state then
                hum:change_state(3)
            end
        end)
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

    local hum = ep.humanoid(lp)
    if not hum or not env.is_valid(hum) then
        hum = env.safe_call(function()
            return char:FindFirstChildOfClass("Humanoid") or char:find_first_child_of_class("Humanoid")
        end)
    end
    if not hum or not env.is_valid(hum) then return end

    local hp = tonumber(hum.Health or hum.health)
    if hp ~= nil and hp <= 0 then return end

    local root = env.safe_call(function()
        return char:FindFirstChild("HumanoidRootPart") or char:find_first_child("HumanoidRootPart")
    end)

    -- Only request jump while grounded so we don't fight mid-air state.
    if not on_ground(root, hum, lp) then return end
    request_jump(lp, hum)
end

function M.draw() end

return M
