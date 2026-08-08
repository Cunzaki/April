--[[
  Playing action labels for Player ESP → Animation flag.

  AnimationTracks are NOT instance children — walk Animator.ActiveAnimations
  (Theo linked list). Also fall back to playing character Sounds + held tool,
  which reliably catches Bandage / Medkit / Reload on Fallen.
]]

local rbx_offsets = April.require("core.rbx_offsets")
local text_util = April.require("core.text_util")

local M = {}
local player_gear = nil

local function gear()
    if player_gear then return player_gear end
    local ok, mod = pcall(April.require, "game.player_gear")
    if ok then player_gear = mod end
    return player_gear
end

local CACHE_MS = 70
local cache = {}

-- ActiveAnimations node → AnimationTrack pointer (Roblox stdlist layout).
local TRACK_IN_NODE = 0x10
local MAX_TRACKS = 24
local MAX_SOUNDS = 40

local RULES = {
    { "reload", "RELOAD" },
    { "chamber", "RELOAD" },
    { "bandage", "BANDAGE" },
    { "medkit", "HEAL" },
    { "health pen", "HEAL" },
    { "healthpen", "HEAL" },
    { "heal", "HEAL" },
    { "syringe", "HEAL" },
    { "stim", "HEAL" },
    { "revive", "REVIVE" },
    { "cpr", "REVIVE" },
    { "eat", "EAT" },
    { "drink", "DRINK" },
    { "swing", "MELEE" },
    { "melee", "MELEE" },
    { "slash", "MELEE" },
    { "punch", "MELEE" },
    { "aim", "AIM" },
    { "ads", "AIM" },
    { "shoot", "FIRE" },
    { "fire", "FIRE" },
    { "throw", "THROW" },
    { "grenade", "THROW" },
    { "climb", "CLIMB" },
    { "vault", "VAULT" },
    { "crawl", "CRAWL" },
    { "prone", "PRONE" },
    { "crouch", "CROUCH" },
    { "inspect", "INSPECT" },
    { "emote", "EMOTE" },
    { "dance", "EMOTE" },
    { "equip", "EQUIP" },
    { "unequip", "UNEQUIP" },
    { "sprint", "SPRINT" },
    { "use", "USE" },
    { "idle", "IDLE" },
}

local PRIORITY = {
    RELOAD = 100, FIRE = 95, AIM = 90, HEAL = 88, BANDAGE = 88, REVIVE = 85,
    THROW = 75, MELEE = 70, USE = 65, EQUIP = 55, UNEQUIP = 50, INSPECT = 45,
    EAT = 42, DRINK = 42, CLIMB = 40, VAULT = 40, CRAWL = 35, PRONE = 35,
    CROUCH = 30, SPRINT = 18, EMOTE = 6, IDLE = 1, ANIM = 2,
}

local HELD_ACTIONS = {
    BANDAGE = true, HEAL = true, REVIVE = true, EAT = true, DRINK = true, MELEE = true,
}

local function tick_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, v = pcall(fn)
    return (ok and tonumber(v)) or 0
end

local function mem_read()
    if not memory then return nil end
    local fn = memory.Read or memory.read
    if type(fn) == "function" then return fn end
    return nil
end

local function read_ptr(addr)
    local fn = mem_read()
    if not fn or not addr then return nil end
    local ok, value = pcall(fn, addr, "ptr")
    if not ok then return nil end
    value = tonumber(value)
    if not value or value == 0 then return nil end
    return value
end

local function mem_bool(addr, off)
    local fn = mem_read()
    if not fn or not addr or not off then return false end
    local ok, value = pcall(fn, addr + off, "bool")
    return ok and value == true
end

local function mem_float(addr, off)
    local fn = mem_read()
    if not fn or not addr or not off then return nil end
    local ok, value = pcall(fn, addr + off, "float")
    if ok then return tonumber(value) end
    return nil
end

local function read_string_at(addr)
    if not addr or not memory or not memory.ReadString then return nil end
    local ok, s = pcall(memory.ReadString, addr, 128)
    if ok and type(s) == "string" and s ~= "" then return s end
    return nil
end

local function player_key(p)
    if not p then return nil end
    local uid = p.UserId or p.user_id
    if uid and uid ~= 0 then return uid end
    local addr = p.Address or p.address
    if addr then return tostring(addr) end
    return tostring(p)
end

local function classify(raw)
    if type(raw) ~= "string" or raw == "" then return nil end
    local low = raw:lower()
    for i = 1, #RULES do
        local rule = RULES[i]
        if low:find(rule[1], 1, true) then
            return rule[2]
        end
    end
    return nil
end

local function consider(best_label, best_pri, label)
    if not label or label == "IDLE" then return best_label, best_pri end
    local pri = PRIORITY[label] or 3
    if pri > best_pri then
        return label, pri
    end
    return best_label, best_pri
end

local function instance_name(addr)
    if not addr then return nil end
    -- Theo Instance.NameContainer / Name
    local name_off = 112
    local s = read_string_at(addr + name_off)
    if s then return s end
    local ptr = read_ptr(addr + name_off)
    if ptr then
        s = read_string_at(ptr)
        if s then return s end
        -- Name field offset inside string container
        s = read_string_at(ptr + 8)
        if s then return s end
    end
    return nil
end

local function animation_id(anim_addr)
    if not anim_addr then return nil end
    local off = rbx_offsets.misc("AnimationId") or 192
    local s = read_string_at(anim_addr + off)
    if s then return s end
    local ptr = read_ptr(anim_addr + off)
    if ptr then
        s = read_string_at(ptr)
        if s then return s end
    end
    return instance_name(anim_addr)
end

local function track_label(track_addr)
    if not track_addr then return nil end
    local anim_off = rbx_offsets.anim_track("Animation") or 184
    local anim = read_ptr(track_addr + anim_off)
    local raw = animation_id(anim) or instance_name(track_addr)
    return classify(raw), raw
end

local function track_is_active(track_addr)
    if not track_addr then return false end
    local play_off = rbx_offsets.anim_track("IsPlaying")
    if play_off and mem_bool(track_addr, play_off) then return true end

    local spd = mem_float(track_addr, rbx_offsets.anim_track("Speed"))
    local tp = mem_float(track_addr, rbx_offsets.anim_track("TimePosition"))
    -- ActiveAnimations entries are usually live; accept mild signals too.
    if spd and spd > 0.01 then return true end
    if tp and tp > 0.02 then return true end
    -- Linked-list membership is enough when IsPlaying offset is stale.
    return true
end

local function walk_active_tracks(animator_addr)
    local out = {}
    if not animator_addr then return out end
    local active_off = rbx_offsets.animator("ActiveAnimations") or 2944
    local head = read_ptr(animator_addr + active_off)
    if not head then return out end

    local node = read_ptr(head)
    local guard = 0
    while node and node ~= 0 and node ~= head and guard < MAX_TRACKS do
        guard = guard + 1
        local track = read_ptr(node + TRACK_IN_NODE)
        if track then
            out[#out + 1] = track
        end
        node = read_ptr(node)
    end
    return out
end

local function find_animator(character)
    if not character then return nil, nil end
    local animator = nil
    pcall(function()
        local hum = character.FindFirstChildOfClass and character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FindFirstChildOfClass then
            animator = hum:FindFirstChildOfClass("Animator")
        end
        if not animator and character.FindFirstChildOfClass then
            animator = character:FindFirstChildOfClass("Animator")
        end
        if not animator and character.FindFirstChild then
            local hum2 = character:FindFirstChild("Humanoid")
            if hum2 and hum2.FindFirstChild then
                animator = hum2:FindFirstChild("Animator")
            end
        end
    end)
    if not animator then return nil, nil end
    local addr = tonumber(animator.Address or animator.address)
    return animator, addr
end

local function held_action(player)
    local pg = gear()
    if not pg or not pg.held_name then return nil, nil end
    local name = pg.held_name(player)
    if not name then return nil, nil end
    if pg.is_empty_held_name and pg.is_empty_held_name(name) then return nil, nil end
    local base = name:match("^([^/]+)") or name
    if text_util and text_util.sanitize then
        base = text_util.sanitize(base)
    end
    local label = classify(base)
    if label and HELD_ACTIONS[label] then
        return label, base
    end
    return nil, base
end

local function sound_action(character)
    if not character then return nil end
    local off_play = rbx_offsets.sound_is_playing()
    local best, best_pri = nil, -1

    local function consider_sound(child)
        if not child or (child.ClassName or child.class_name) ~= "Sound" then return end
        local addr = tonumber(child.Address or child.address)
        if not addr or addr <= 0 then return end
        if not mem_bool(addr, off_play) then return end
        local label = classify(child.Name or child.name)
        best, best_pri = consider(best, best_pri, label)
    end

    local hrp = nil
    pcall(function()
        hrp = character:FindFirstChild("HumanoidRootPart")
    end)
    if hrp and hrp.GetChildren then
        local ok, kids = pcall(function() return hrp:GetChildren() end)
        if ok and type(kids) == "table" then
            for i = 1, #kids do consider_sound(kids[i]) end
        end
    end

    if character.GetDescendantsOfClass then
        local ok, list = pcall(function()
            return character:GetDescendantsOfClass("Sound")
        end)
        if ok and type(list) == "table" then
            local n = math.min(#list, MAX_SOUNDS)
            for i = 1, n do consider_sound(list[i]) end
        end
    end

    return best
end

function M.label_for(player)
    if not player then return nil end
    local key = player_key(player)
    local now = tick_ms()
    local hit = key and cache[key]
    if hit and (now - (hit.t or 0)) < CACHE_MS then
        return hit.label
    end

    local character = player.Character
    if not character then
        if key then cache[key] = { t = now, label = nil } end
        return nil
    end

    local best_label, best_pri = nil, -1
    local saw_use = false

    local _, animator_addr = find_animator(character)
    if animator_addr and mem_read() then
        local tracks = walk_active_tracks(animator_addr)
        for i = 1, #tracks do
            local track = tracks[i]
            if track_is_active(track) then
                local label = track_label(track)
                if label == "USE" then saw_use = true end
                best_label, best_pri = consider(best_label, best_pri, label)
            end
        end
    end

    local sound_label = sound_action(character)
    best_label, best_pri = consider(best_label, best_pri, sound_label)

    local held_label, held_name = held_action(player)
    if held_label then
        -- Bandage/Medkit "Use" anims are named Use — bind them to the held item.
        if saw_use or sound_label == held_label or sound_label == "USE" then
            best_label, best_pri = consider(best_label, best_pri, held_label)
        elseif best_label == "USE" or best_label == nil then
            -- Holding a consumable with an active Use-like track / no better label.
            if saw_use or best_label == "USE" then
                best_label, best_pri = consider(best_label, best_pri, held_label)
            end
        end
    end

    -- Final: if we only saw USE, map via held name keywords.
    if best_label == "USE" and held_name then
        local mapped = classify(held_name)
        if mapped and mapped ~= "USE" then
            best_label = mapped
        end
    end

    -- Never show bare USE — not useful without an item context.
    if best_label == "USE" then
        best_label = nil
    end

    if key then cache[key] = { t = now, label = best_label } end
    return best_label
end

function M.prune(live_keys)
    if type(live_keys) ~= "table" then
        cache = {}
        return
    end
    for key in pairs(cache) do
        if not live_keys[key] then cache[key] = nil end
    end
end

return M
