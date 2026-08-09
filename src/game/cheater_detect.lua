-- Heuristic cheater flag for player ESP (young accounts / impossible vertical speed).
local ep = April.require("core.entity_props")
local env = April.require("core.env")

local M = {}

local AGE_THRESHOLD_DAYS = 60
local VERT_SPEED_ABS = 1000
local RESCAN_MS = 3000

local cache = {} -- [user_id or name] = { flagged = bool, at = ms }
local last_scan_ms = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function cache_key(player)
    local uid = ep.user_id(player)
    if uid and uid ~= 0 then
        return "u:" .. tostring(uid)
    end
    local name = ep.name(player)
    if name and name ~= "" then
        return "n:" .. name
    end
    return nil
end

local function read_account_age(player)
    local age = tonumber(ep.get(player, "AccountAge", "account_age"))
    if age then return age end

    local pl = ep.player_inst(player)
    if not pl then return nil end
    local ok, v = pcall(function()
        return pl.AccountAge or pl.account_age
    end)
    if ok then
        return tonumber(v)
    end
    return nil
end

local function vertical_speed(player)
    local vel = ep.velocity(player)
    if vel then
        local y = tonumber(vel.Y or vel.y)
        if y then return y end
    end

    local char = ep.character(player)
    if not char or not env.is_valid(char) then return nil end
    local root = env.safe_call(function()
        return char:FindFirstChild("HumanoidRootPart")
            or char:find_first_child("HumanoidRootPart")
    end)
    if not root or not env.is_valid(root) then return nil end
    local v = root.AssemblyLinearVelocity or root.Velocity or root.velocity
    if not v then return nil end
    return tonumber(v.Y or v.y)
end

local function evaluate(player)
    local age = read_account_age(player)
    if age ~= nil and age <= AGE_THRESHOLD_DAYS then
        return true
    end

    local vy = vertical_speed(player)
    if vy ~= nil and (vy <= -VERT_SPEED_ABS or vy >= VERT_SPEED_ABS) then
        return true
    end

    return false
end

-- Sticky once true for this join (age doesn't change; speed spikes get rechecked).
function M.is_cheater(player)
    if not player or ep.is_local(player) then return false end
    local key = cache_key(player)
    if not key then return false end

    local now = tick_ms()
    local entry = cache[key]
    if entry and entry.flagged then
        return true
    end
    if entry and now - (entry.at or 0) < RESCAN_MS then
        return entry.flagged == true
    end

    local flagged = evaluate(player)
    cache[key] = { flagged = flagged, at = now }
    return flagged
end

function M.tick()
    local now = tick_ms()
    if now - last_scan_ms < RESCAN_MS then return end
    last_scan_ms = now

    local players = entity and (entity.get_players or entity.GetPlayers)
    if not players then return end
    local ok, list = pcall(players)
    if not ok or type(list) ~= "table" then return end

    local live = {}
    for i = 1, #list do
        local p = list[i]
        if p and not ep.is_local(p) then
            local key = cache_key(p)
            if key then live[key] = true end
            M.is_cheater(p)
        end
    end
    for key in pairs(cache) do
        if not live[key] then cache[key] = nil end
    end
end

function M.clear()
    cache = {}
    last_scan_ms = 0
end

return M
