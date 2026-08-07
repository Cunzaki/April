-- Client-side head hitbox size override for other players (Size + near-invisible).
local settings = April.require("core.settings")
local env = April.require("core.env")
local cache = April.require("core.cache")
local move = April.require("core.cframe_move")
local ep = April.require("core.entity_props")

local M = {}

local P = "april_thick_bullet"
local P_MULT = "april_thick_bullet_mult"
local P_BULLET = "april_bullet_enabled"

local BASE = { x = 1.15, y = 1.16, z = 1.16 }
local TRANSP = 0.99

-- [head_addr] = { sx, sy, sz, transp }
local tracked = {}
local was_on = false

local function vec3(x, y, z)
    if Vector3 then
        local ctor = Vector3.new or Vector3.New
        if type(ctor) == "function" then
            local ok, v = pcall(ctor, x, y, z)
            if ok then return v end
        end
    end
    return nil
end

local function head_key(head)
    return head.Address or head.address or tostring(head)
end

local function read_size(head)
    local ok, s = pcall(function()
        return head.Size or head.size
    end)
    if not ok or not s then return nil end
    local x = tonumber(s.X or s.x)
    local y = tonumber(s.Y or s.y)
    local z = tonumber(s.Z or s.z)
    if not x or not y or not z then return nil end
    return x, y, z
end

local function write_size(head, x, y, z)
    local v = vec3(x, y, z)
    if not v then return false end
    return pcall(function()
        head.Size = v
    end)
end

local function restore_one(head, entry)
    if not head or not env.is_valid(head) or not entry then return end
    write_size(head, entry.sx, entry.sy, entry.sz)
    if entry.transp ~= nil then
        move.set_part_transparency(head, entry.transp)
    end
end

local function restore_all()
    for _, player in ipairs(cache.players or {}) do
        local char = ep.character(player)
        if char and env.is_valid(char) then
            local head = env.safe_call(function()
                return char:FindFirstChild("Head") or char:find_first_child("Head")
            end)
            if head and env.is_valid(head) then
                local entry = tracked[head_key(head)]
                if entry then
                    restore_one(head, entry)
                else
                    write_size(head, BASE.x, BASE.y, BASE.z)
                end
            end
        end
    end
    tracked = {}
end

local function active()
    return settings.enabled(P_BULLET) and settings.bool(P, false)
end

local function thickness()
    local t = tonumber(settings.num(P_MULT, 2)) or 2
    if t < 1 then t = 1 end
    if t > 4 then t = 4 end
    return t
end

local function find_head(player)
    local char = ep.character(player)
    if not char or not env.is_valid(char) then return nil end
    return env.safe_call(function()
        return char:FindFirstChild("Head") or char:find_first_child("Head")
    end)
end

function M.is_active()
    return was_on == true and active()
end

-- GetBounds includes inflated Head.Size. Temporarily restore the natural size for
-- this player only so ESP/boxes do not reveal Override Size, then re-apply.
function M.esp_bounds(player)
    local fn = player and (player.GetBounds or player.get_bounds)
    if not fn then return nil end

    if not M.is_active() then
        local ok, bounds = pcall(fn, player)
        if ok then return bounds end
        return nil
    end

    local head = find_head(player)
    if not head or not env.is_valid(head) then
        local ok, bounds = pcall(fn, player)
        if ok then return bounds end
        return nil
    end

    local entry = tracked[head_key(head)]
    if not entry then
        local ok, bounds = pcall(fn, player)
        if ok then return bounds end
        return nil
    end

    local mult = thickness()
    write_size(head, entry.sx, entry.sy, entry.sz)
    local ok, bounds = pcall(fn, player)
    write_size(head, entry.sx * mult, entry.sy * mult, entry.sz * mult)
    if ok then return bounds end
    return nil
end

function M.update(_dt)
    local on = active()
    if not on then
        if was_on then
            restore_all()
            was_on = false
        end
        return
    end
    was_on = true

    local mult = thickness()
    local players = cache.players
    if type(players) ~= "table" then return end

    local seen = {}
    for i = 1, #players do
        local p = players[i]
        if not p or ep.is_local(p) then goto continue end
        if p.IsAlive == false or p.is_alive == false then goto continue end

        local head = find_head(p)
        if not head or not env.is_valid(head) then goto continue end

        local hum = ep.humanoid(p) or env.safe_call(function()
            local char = ep.character(p)
            if not char then return nil end
            return char:FindFirstChildOfClass("Humanoid") or char:find_first_child_of_class("Humanoid")
        end)
        local hp = hum and tonumber(hum.Health or hum.health)
        local dead = hp ~= nil and hp <= 0

        local key = head_key(head)
        seen[key] = true
        local entry = tracked[key]
        if not entry then
            local sx, sy, sz = read_size(head)
            if not sx then
                sx, sy, sz = BASE.x, BASE.y, BASE.z
            end
            -- If we first see an already-inflated head, store the natural base.
            if sx > BASE.x * 1.35 or sy > BASE.y * 1.35 or sz > BASE.z * 1.35 then
                sx, sy, sz = BASE.x, BASE.y, BASE.z
            end
            entry = {
                sx = sx,
                sy = sy,
                sz = sz,
                transp = move.get_part_transparency(head),
            }
            tracked[key] = entry
        end

        if dead then
            write_size(head, entry.sx, entry.sy, entry.sz)
        else
            write_size(head, entry.sx * mult, entry.sy * mult, entry.sz * mult)
            move.set_part_transparency(head, TRANSP)
        end

        ::continue::
    end

    for key in pairs(tracked) do
        if not seen[key] then
            tracked[key] = nil
        end
    end
end

function M.draw() end

return M
