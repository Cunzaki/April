--[[ Movement sim — Inf Fly + Spider (CFrame position, one tick). ]]

local settings = April.require("core.settings")
local env = April.require("core.env")
local move = April.require("core.cframe_move")

local M = {}

local _installed = false

local MODE_NONE = "none"
local MODE_FLY = "fly"
local MODE_SPIDER = "spider"

local active_mode = MODE_NONE
local tracked_char_id = nil
local anchor_y = nil

local function char_id(char)
    if not char then return nil end
    return char.Address or char.address or tostring(char)
end

local function get_character(lp)
    if lp and lp.character then return lp.character end
    if game and game.local_player and game.local_player.character then
        return game.local_player.character
    end
    return nil
end

local function get_root(lp)
    local char = get_character(lp)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child("HumanoidRootPart") end
        return char:FindFirstChild("HumanoidRootPart")
    end)
end

local function get_humanoid(lp)
    if lp and lp.humanoid and env.is_valid(lp.humanoid) then
        return lp.humanoid
    end
    local char = get_character(lp)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child_of_class then return char:find_first_child_of_class("Humanoid") end
        return char:FindFirstChildOfClass("Humanoid")
    end)
end

local function resolve_mode()
    if settings.enabled("april_noclip_enabled") then return MODE_FLY end
    if settings.enabled("april_spider_enabled") then return MODE_SPIDER end
    return MODE_NONE
end

local function sync_anchor(root)
    local pos = move.read_pos(root)
    if pos then anchor_y = pos.y end
end

local function leave_mode(root, hum, char)
    move.humanoid_release(hum)
    move.zero_character(char, root)
    anchor_y = nil
end

local function enter_mode(root, hum, char)
    move.humanoid_suspend(hum)
    move.zero_character(char, root)
    sync_anchor(root)
    return anchor_y ~= nil
end

local function tick_fly(char, root, speed)
    local pos = move.read_pos(root)
    if not pos then return end
    if not anchor_y then anchor_y = pos.y end

    local mx, my, mz = move.read_fly_input()
    local step = speed * move.delta_time()

    if my ~= 0 then
        anchor_y = anchor_y + my * step
    end

    local nx, nz = pos.x, pos.z
    if mx ~= 0 or mz ~= 0 then
        nx = pos.x + mx * step
        nz = pos.z + mz * step
    end

    move.set_position(root, nx, anchor_y, nz)
    move.zero_character(char, root)
end

local function tick_spider(char, root, speed)
    local pos = move.read_pos(root)
    if not pos then return end
    if not anchor_y then anchor_y = pos.y end

    anchor_y = anchor_y + speed * move.delta_time()
    move.set_position(root, pos.x, anchor_y, pos.z)
    move.zero_character(char, root)
end

function M.tick(_dt)
    local misc_gate = April.require("core.misc_gate")
    if not misc_gate.movement_allowed() then return end

    local lp = env.get_local_player()
    if not lp then return end

    local char = get_character(lp)
    if not char or not env.is_valid(char) then return end

    local root = get_root(lp)
    local hum = get_humanoid(lp)
    if not root or not hum then return end

    local cid = char_id(char)
    if cid ~= tracked_char_id then
        active_mode = MODE_NONE
        anchor_y = nil
        tracked_char_id = cid
    end

    local mode = resolve_mode()

    if active_mode ~= mode then
        if active_mode ~= MODE_NONE then
            leave_mode(root, hum, char)
        end
        active_mode = mode
        if mode ~= MODE_NONE and not enter_mode(root, hum, char) then
            active_mode = MODE_NONE
            return
        end
    end

    if mode == MODE_NONE then return end

    if mode == MODE_FLY then
        tick_fly(char, root, settings.num("april_noclip_speed", 72))
    elseif mode == MODE_SPIDER then
        tick_spider(char, root, settings.num("april_spider_speed", 20))
    end
end

function M.install()
    if _installed then return end
    _installed = true
    local runservice = April.require("core.runservice")
    runservice.on_sim(function(dt)
        M.tick(dt)
    end)
end

return M
