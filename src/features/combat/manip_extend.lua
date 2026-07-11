-- Physical manip extend: keep 1-stud silent peek math, but when Extend is on
-- search up to 8 studs, desync (bandwidth choke), move local HRP to peek, then
-- restore + undesync when manip ends — same pattern as divine rbxcli.

local settings = April.require("core.settings")
local env = April.require("core.env")
local manip_math = April.require("core.manip_math")
local packet_desync = April.require("core.packet_desync")
local cframe_move = April.require("core.cframe_move")
local combat_origin = April.require("game.combat_origin")
local targeting = April.require("features.combat.targeting")
local misc_gate = April.require("core.misc_gate")

local M = {}

local PREFIX = "april_silent_"
local active = false
local og_pos = nil
local peek_pos = nil
local desync_on = false

local function get_root()
    local lp = env.get_local_player()
    if not lp then return nil end
    local char = lp.character or (game and game.local_player and game.local_player.character)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end

local function set_root(root, pos)
    if not root or not pos then return end
    cframe_move.set_position(root, pos.x, pos.y, pos.z)
    if part and part.set_velocity then
        pcall(part.set_velocity, root, 0, 0, 0)
    end
end

local function apply_desync(on)
    if on and not desync_on then
        packet_desync.apply_extend()
        desync_on = true
    elseif not on and desync_on then
        packet_desync.release()
        desync_on = false
    end
end

function M.reset()
    if active and og_pos then
        local root = get_root()
        if root then set_root(root, og_pos) end
    end
    apply_desync(false)
    active = false
    og_pos = nil
    peek_pos = nil
end

function M.is_active()
    return active
end

function M.update(target, prefix)
    prefix = prefix or PREFIX

    if not misc_gate.movement_allowed() then
        M.reset()
        return
    end

    local manip_on = settings.bool(prefix .. "bullet_manip", false)
    local extend_on = settings.bool(prefix .. "manip_extend", false)
    if not manip_on or not extend_on or not target then
        M.reset()
        return
    end

    local root = get_root()
    if not root then
        M.reset()
        return
    end

    local body = combat_origin.get_server_origin()
    if not body then
        -- Fall back to current root while not yet desynced.
        body = cframe_move.read_pos(root)
    end
    if not body then
        M.reset()
        return
    end

    local hitpart = targeting.bone_world(target, targeting.bone_name(prefix))
        or (target.head_position and {
            x = target.head_position.x,
            y = target.head_position.y,
            z = target.head_position.z,
        })
    if not hitpart then
        M.reset()
        return
    end

    local max_r = manip_math.clamp_extend_radius(settings.num(prefix .. "manip_extend_dist", 8))
    local origin = og_pos or body
    local ev = manip_math.evaluate_manipulation(origin, hitpart, {
        max_radius = max_r,
        extend = true,
    })

    if ev.state == "direct" then
        -- Already have LOS from origin — no need to stay extended.
        M.reset()
        return
    end

    if ev.state ~= "ready" or not ev.peek then
        M.reset()
        return
    end

    if not active then
        og_pos = { x = body.x, y = body.y, z = body.z }
        apply_desync(true)
        active = true
    end

    peek_pos = ev.peek
    set_root(root, peek_pos)
end

return M
