-- Micro HRP autopeek for bullet manip: desync, move to peek, undesync when target lost/hidden.
local settings = April.require("core.settings")
local env = April.require("core.env")
local cframe_move = April.require("core.cframe_move")
local manip_math = April.require("core.manip_math")
local misc_gate = April.require("core.misc_gate")
local targeting = April.require("features.combat.targeting")

local M = {}

local MAX_OFFSET = 7
local SAME_PEEK_EPS = 0.35
local TICK_TIMEOUT_MS = 180

local active = false
local peek_pos = nil
local ctx = nil
local last_tick_ms = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function desync_mod()
    local ok, mod = pcall(function()
        return April.require("features.movement.desync")
    end)
    if ok then return mod end
    return nil
end

local function hrp()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end
    return cframe_move.find_part(char, "HumanoidRootPart")
end

local function same_pos(a, b)
    if not a or not b then return false end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return (dx * dx + dy * dy + dz * dz) <= SAME_PEEK_EPS * SAME_PEEK_EPS
end

local function clamp_peek_to_body(peek, cur, max_radius)
    local max_y = manip_math.max_y_offset and manip_math.max_y_offset() or 2.5
    local dy = peek.y - cur.y
    if dy > max_y then
        peek.y = cur.y + max_y
    elseif dy < -max_y then
        peek.y = cur.y - max_y
    end

    local dx = peek.x - cur.x
    dy = peek.y - cur.y
    local dz = peek.z - cur.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    max_radius = math.min(MAX_OFFSET, tonumber(max_radius) or 1)
    if dist < 0.05 or dist > max_radius + 0.5 then
        return nil
    end
    return peek
end

function M.enabled()
    return settings.bool("april_bullet_enabled", false)
        and settings.bool("april_silent_bullet_manip", false)
        and settings.bool("april_bullet_body_peek", false)
end

function M.is_active()
    return active
end

function M.get_peek_pos()
    return peek_pos
end

function M.release()
    if not active then return end

    local desync = desync_mod()
    if desync and desync.peek_end then
        pcall(desync.peek_end)
    end

    active = false
    peek_pos = nil
    ctx = nil
end

local function begin_desync()
    local desync = desync_mod()
    if desync and desync.peek_begin then
        pcall(desync.peek_begin)
    end
end

local function move_to_peek(peek, target, hitpart)
    local root = hrp()
    if not root then return nil end

    local cur = cframe_move.read_pos(root)
    if not cur then return nil end

    if not manip_math.is_visible_from_pos(peek, hitpart) then
        return nil
    end

    if not same_pos(cur, peek) then
        begin_desync()
        cframe_move.set_position_only(root, peek.x, peek.y, peek.z)
    elseif not active then
        begin_desync()
    end

    peek_pos = { x = peek.x, y = peek.y, z = peek.z }
    ctx = { target = target, hitpart = hitpart }
    active = true
    last_tick_ms = tick_ms()
    return peek_pos
end

-- Apply a known manip peek: desync, move body, hold until tick() releases.
function M.ensure_peek(peek, hitpart, target, max_radius)
    if not M.enabled() then return nil end
    if not misc_gate.movement_allowed() then return nil end
    if not peek or not hitpart then return nil end

    local root = hrp()
    if not root then return nil end

    local cur = cframe_move.read_pos(root)
    if not cur then return nil end

    peek = clamp_peek_to_body({ x = peek.x, y = peek.y, z = peek.z }, cur, max_radius)
    if not peek then return nil end

    if active and peek_pos and same_pos(peek_pos, peek) then
        ctx = { target = target, hitpart = hitpart }
        last_tick_ms = tick_ms()
        return peek_pos
    end

    return move_to_peek(peek, target, hitpart)
end

-- Find a peek when silent ring fails, then desync + move.
function M.try_peek(body, hitpart, max_radius, target)
    if not M.enabled() then return nil end
    if not misc_gate.movement_allowed() then return nil end
    if not body or not hitpart then return nil end

    max_radius = math.min(MAX_OFFSET, tonumber(max_radius) or 1)
    if max_radius < 0.15 then return nil end

    local root = hrp()
    if not root then return nil end

    local cur = cframe_move.read_pos(root)
    if not cur then return nil end

    local peek = manip_math.find_manipulation_position(body, hitpart, {
        base_radius = math.min(1, max_radius),
        extend = max_radius > 1.05,
        extend_extra = math.max(0, max_radius - 1),
    })
    if not peek then return nil end

    peek = clamp_peek_to_body(peek, cur, max_radius)
    if not peek then return nil end

    return M.ensure_peek(peek, hitpart, target, max_radius)
end

local function target_alive(target)
    if not target then return false end
    if targeting.is_npc_target(target) then
        target = targeting.refresh_npc_target(target)
        return target ~= nil and targeting.is_aim_target(target)
    end
    return targeting.is_aim_target(target)
end

-- Called each combat frame with the current target + aim bone.
function M.tick(target, hitpart)
    last_tick_ms = tick_ms()

    if not active then return end

    if not M.enabled() then
        M.release()
        return
    end

    if hitpart then
        if ctx then ctx.hitpart = hitpart end
    end

    if target then
        if ctx then ctx.target = target end
    end

    if not ctx or not peek_pos or not ctx.hitpart then
        M.release()
        return
    end

    if not target_alive(ctx.target) then
        M.release()
        return
    end

    if not manip_math.is_visible_from_pos(peek_pos, ctx.hitpart) then
        M.release()
        return
    end
end

function M.update(_dt)
    if not active then return end
    if tick_ms() - last_tick_ms > TICK_TIMEOUT_MS then
        M.release()
    end
end

function M.register_menu()
end

function M.draw()
end

return M
