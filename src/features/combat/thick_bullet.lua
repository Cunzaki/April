-- Client-side hitbox size override for other players (Size + near-invisible).
local settings = April.require("core.settings")
local env = April.require("core.env")
local cache = April.require("core.cache")
local move = April.require("core.cframe_move")
local ep = April.require("core.entity_props")

local M = {}

-- Keep legacy setting ids so existing configs keep working.
local P = "april_thick_bullet"
local P_MULT = "april_thick_bullet_mult"
local P_PART = "april_thick_bullet_part"
local P_BULLET = "april_bullet_enabled"

M.PART_OPTIONS = {
    "Head",
    "Torso",
    "HumanoidRootPart",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
}

-- Prefer R15 names, fall back to R6.
local PART_ALIASES = {
    ["Head"] = { "Head" },
    ["Torso"] = { "UpperTorso", "Torso", "LowerTorso" },
    ["HumanoidRootPart"] = { "HumanoidRootPart" },
    ["Left Arm"] = { "LeftUpperArm", "Left Arm", "LeftLowerArm", "LeftHand" },
    ["Right Arm"] = { "RightUpperArm", "Right Arm", "RightLowerArm", "RightHand" },
    ["Left Leg"] = { "LeftUpperLeg", "Left Leg", "LeftLowerLeg", "LeftFoot" },
    ["Right Leg"] = { "RightUpperLeg", "Right Leg", "RightLowerLeg", "RightFoot" },
}

local DEFAULT_SIZE = {
    Head = { 1.15, 1.16, 1.16 },
    Torso = { 2.0, 2.0, 1.0 },
    HumanoidRootPart = { 2.0, 2.0, 1.0 },
    ["Left Arm"] = { 1.0, 2.0, 1.0 },
    ["Right Arm"] = { 1.0, 2.0, 1.0 },
    ["Left Leg"] = { 1.0, 2.0, 1.0 },
    ["Right Leg"] = { 1.0, 2.0, 1.0 },
}

local TRANSP = 0.99

-- [part_addr] = { sx, sy, sz, transp, part_label }
local tracked = {}
local was_on = false
local last_part_label = nil

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

local function part_key(part)
    return part.Address or part.address or tostring(part)
end

local function selected_part_label()
    local idx = math.floor(tonumber(settings.num(P_PART, 0)) or 0)
    if idx < 0 then idx = 0 end
    if idx >= #M.PART_OPTIONS then idx = #M.PART_OPTIONS - 1 end
    return M.PART_OPTIONS[idx + 1] or "Head"
end

local function find_part(char, label)
    local names = PART_ALIASES[label] or { label }
    for i = 1, #names do
        local name = names[i]
        local part = env.safe_call(function()
            return char:FindFirstChild(name) or char:find_first_child(name)
        end)
        if part and env.is_valid(part) then
            return part
        end
    end
    return nil
end

local function read_size(part)
    local ok, s = pcall(function()
        return part.Size or part.size
    end)
    if not ok or not s then return nil end
    local x = tonumber(s.X or s.x)
    local y = tonumber(s.Y or s.y)
    local z = tonumber(s.Z or s.z)
    if not x or not y or not z then return nil end
    return x, y, z
end

local function write_size(part, x, y, z)
    local v = vec3(x, y, z)
    if not v then return false end
    return pcall(function()
        part.Size = v
    end)
end

local function default_size_for(label)
    local d = DEFAULT_SIZE[label] or DEFAULT_SIZE.Head
    return d[1], d[2], d[3]
end

local function restore_one(part, entry)
    if not part or not env.is_valid(part) or not entry then return end
    write_size(part, entry.sx, entry.sy, entry.sz)
    if entry.transp ~= nil then
        move.set_part_transparency(part, entry.transp)
    end
end

local function restore_all()
    for _, player in ipairs(cache.players or {}) do
        local char = ep.character(player)
        if char and env.is_valid(char) then
            for _, names in pairs(PART_ALIASES) do
                for i = 1, #names do
                    local part = env.safe_call(function()
                        return char:FindFirstChild(names[i]) or char:find_first_child(names[i])
                    end)
                    if part and env.is_valid(part) then
                        local entry = tracked[part_key(part)]
                        if entry then
                            restore_one(part, entry)
                        end
                    end
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

function M.update(_dt)
    local on = active()
    if not on then
        if was_on then
            restore_all()
            was_on = false
            last_part_label = nil
        end
        return
    end

    local part_label = selected_part_label()
    if was_on and last_part_label and last_part_label ~= part_label then
        restore_all()
    end
    was_on = true
    last_part_label = part_label

    local mult = thickness()
    local players = cache.players
    if type(players) ~= "table" then return end

    local seen = {}
    for i = 1, #players do
        local p = players[i]
        if not p or ep.is_local(p) then goto continue end
        if p.IsAlive == false or p.is_alive == false then goto continue end

        local char = ep.character(p)
        if not char or not env.is_valid(char) then goto continue end

        local part = find_part(char, part_label)
        if not part then goto continue end

        local hum = ep.humanoid(p) or env.safe_call(function()
            return char:FindFirstChildOfClass("Humanoid") or char:find_first_child_of_class("Humanoid")
        end)
        local hp = hum and tonumber(hum.Health or hum.health)
        local dead = hp ~= nil and hp <= 0

        local key = part_key(part)
        seen[key] = true
        local entry = tracked[key]
        if not entry then
            local sx, sy, sz = read_size(part)
            if not sx then
                sx, sy, sz = default_size_for(part_label)
            end
            entry = {
                sx = sx,
                sy = sy,
                sz = sz,
                transp = move.get_part_transparency(part),
                part_label = part_label,
            }
            tracked[key] = entry
        end

        if dead then
            write_size(part, entry.sx, entry.sy, entry.sz)
        else
            write_size(part, entry.sx * mult, entry.sy * mult, entry.sz * mult)
            move.set_part_transparency(part, TRANSP)
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
