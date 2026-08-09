--[[
  Playing action labels for Player ESP → Animation flag.

  AnimationTracks are NOT instance children — walk Animator.ActiveAnimations
  (Theo linked list). Sound / held fallbacks are cheap paths only (no full
  character GetDescendants) and refreshes are budgeted to avoid frame spikes.
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

-- Label TTL; soft stale window serves last label when refresh budget is spent.
local CACHE_MS = 120
local STALE_OK_MS = 450
local ANIMATOR_TTL_MS = 1500
local MAX_TRACKS = 16
local MAX_HRP_SOUNDS = 24
local MAX_REFRESH_PER_TICK = 3
local EARLY_PRI = 85

local TRACK_IN_NODE = 0x10

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

local CLASSIFY_MAX = 768
local cache = {}
local animator_cache = {}
local classify_cache = {}
local classify_n = 0
local mem_fn = nil
local name_off = 112
local refresh_budget = 0
local refresh_budget_tick = -1

local function tick_ms()
    local fn = utility and (utility.get_tick_count or utility.GetTickCount)
    if type(fn) ~= "function" then return 0 end
    local ok, v = pcall(fn)
    return (ok and tonumber(v)) or 0
end

local function mem_read()
    if mem_fn then return mem_fn end
    if not memory then return nil end
    local fn = memory.Read or memory.read
    if type(fn) == "function" then
        mem_fn = fn
        return mem_fn
    end
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

local function read_string_at(addr)
    if not addr or not memory or not memory.ReadString then return nil end
    local ok, s = pcall(memory.ReadString, addr, 96)
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

local function character_key(character)
    if not character then return nil end
    return tonumber(character.Address or character.address)
end

local function ptr_ok(addr)
    addr = tonumber(addr)
    return addr and addr >= 0x10000
end

local function classify(raw)
    if type(raw) ~= "string" or raw == "" then return nil end
    local hit = classify_cache[raw]
    if hit ~= nil then
        if hit == false then return nil end
        return hit
    end
    if classify_n >= CLASSIFY_MAX then
        classify_cache = {}
        classify_n = 0
    end
    local low = raw:lower()
    for i = 1, #RULES do
        local rule = RULES[i]
        if low:find(rule[1], 1, true) then
            classify_cache[raw] = rule[2]
            classify_n = classify_n + 1
            return rule[2]
        end
    end
    classify_cache[raw] = false
    classify_n = classify_n + 1
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
    local s = read_string_at(addr + name_off)
    if s then return s end
    local ptr = read_ptr(addr + name_off)
    if ptr then
        s = read_string_at(ptr)
        if s then return s end
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
    return classify(raw)
end

-- ActiveAnimations membership is the source of truth; avoid extra float probes.
local function track_is_active(track_addr)
    if not track_addr then return false end
    local play_off = rbx_offsets.anim_track("IsPlaying")
    if play_off then
        local fn = mem_read()
        if fn then
            local ok, value = pcall(fn, track_addr + play_off, "bool")
            if ok and value == false then return false end
        end
    end
    return true
end

local function resolve_animator_addr(character, key, now)
    local char_addr = character_key(character)
    local ac = key and animator_cache[key]
    if ac and (now - (ac.t or 0)) < ANIMATOR_TTL_MS and ac.char == char_addr and ptr_ok(ac.addr) then
        return ac.addr
    end

    local animator = nil
    pcall(function()
        local hum = character.FindFirstChildOfClass and character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FindFirstChildOfClass then
            animator = hum:FindFirstChildOfClass("Animator")
        end
        if not animator and character.FindFirstChild then
            local hum2 = character:FindFirstChild("Humanoid")
            if hum2 and hum2.FindFirstChild then
                animator = hum2:FindFirstChild("Animator")
            end
        end
        if not animator and character.FindFirstChildOfClass then
            animator = character:FindFirstChildOfClass("Animator")
        end
    end)

    local addr = animator and tonumber(animator.Address or animator.address) or nil
    if key then
        animator_cache[key] = { t = now, addr = addr, char = char_addr }
    end
    return addr
end

-- Walk ActiveAnimations in-place; stop once we have a strong label.
local function scan_tracks(animator_addr)
    local best_label, best_pri = nil, -1
    local saw_use = false
    if not ptr_ok(animator_addr) or not mem_read() then
        return best_label, best_pri, saw_use
    end

    local active_off = rbx_offsets.animator("ActiveAnimations") or 2944
    local head = read_ptr(animator_addr + active_off)
    if not ptr_ok(head) then
        return best_label, best_pri, saw_use
    end

    local node = read_ptr(head)
    local guard = 0
    while ptr_ok(node) and node ~= head and guard < MAX_TRACKS do
        guard = guard + 1
        local track = read_ptr(node + TRACK_IN_NODE)
        if ptr_ok(track) and track_is_active(track) then
            local label = track_label(track)
            if label == "USE" then saw_use = true end
            best_label, best_pri = consider(best_label, best_pri, label)
            if best_pri >= EARLY_PRI then
                break
            end
        end
        local next_node = read_ptr(node)
        if not next_node or next_node == node then break end
        node = next_node
    end
    return best_label, best_pri, saw_use
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

-- Cheap sound path only: HRP children. Full GetDescendants was the lag spike.
local function sound_action(character)
    if not character then return nil end
    local off_play = rbx_offsets.sound_is_playing()
    if not off_play or not mem_read() then return nil end

    local hrp = nil
    pcall(function()
        hrp = character:FindFirstChild("HumanoidRootPart")
    end)
    if not hrp or not hrp.GetChildren then return nil end

    local ok, kids = pcall(function() return hrp:GetChildren() end)
    if not ok or type(kids) ~= "table" then return nil end

    local best, best_pri = nil, -1
    local n = math.min(#kids, MAX_HRP_SOUNDS)
    for i = 1, n do
        local child = kids[i]
        if child and (child.ClassName or child.class_name) == "Sound" then
            local addr = tonumber(child.Address or child.address)
            if addr and addr > 0 and mem_bool(addr, off_play) then
                local label = classify(child.Name or child.name)
                best, best_pri = consider(best, best_pri, label)
                if best_pri >= EARLY_PRI then break end
            end
        end
    end
    return best
end

local function take_refresh_budget(now)
    if refresh_budget_tick ~= now then
        refresh_budget_tick = now
        refresh_budget = MAX_REFRESH_PER_TICK
    end
    if refresh_budget <= 0 then return false end
    refresh_budget = refresh_budget - 1
    return true
end

function M.label_for(player)
    if not player then return nil end
    local key = player_key(player)
    local now = tick_ms()
    local hit = key and cache[key]
    if hit and (now - (hit.t or 0)) < CACHE_MS then
        return hit.label
    end

    -- Serve slightly stale labels when many players expire in the same frame.
    if hit and (now - (hit.t or 0)) < STALE_OK_MS then
        if not take_refresh_budget(now) then
            return hit.label
        end
    elseif hit and not take_refresh_budget(now) then
        return hit.label
    elseif not hit and not take_refresh_budget(now) then
        return nil
    end

    local character = player.Character
    if not character then
        if key then cache[key] = { t = now, label = nil } end
        return nil
    end

    local best_label, best_pri = nil, -1
    local saw_use = false

    local animator_addr = resolve_animator_addr(character, key, now)
    if animator_addr then
        best_label, best_pri, saw_use = scan_tracks(animator_addr)
    end

    local sound_label = nil
    if best_pri < EARLY_PRI then
        sound_label = sound_action(character)
        best_label, best_pri = consider(best_label, best_pri, sound_label)
    end

    local held_label, held_name = nil, nil
    if best_pri < EARLY_PRI or best_label == "USE" or saw_use then
        held_label, held_name = held_action(player)
        if held_label then
            if saw_use or sound_label == held_label or sound_label == "USE" then
                best_label, best_pri = consider(best_label, best_pri, held_label)
            elseif best_label == "USE" or best_label == nil then
                if saw_use or best_label == "USE" then
                    best_label, best_pri = consider(best_label, best_pri, held_label)
                end
            end
        end
    end

    if best_label == "USE" and held_name then
        local mapped = classify(held_name)
        if mapped and mapped ~= "USE" then
            best_label = mapped
        end
    end

    if best_label == "USE" then
        best_label = nil
    end

    if key then cache[key] = { t = now, label = best_label } end
    return best_label
end

function M.prune(live_keys)
    if type(live_keys) ~= "table" then
        cache = {}
        animator_cache = {}
        classify_cache = {}
        classify_n = 0
        return
    end
    for key in pairs(cache) do
        if not live_keys[key] then cache[key] = nil end
    end
    for key in pairs(animator_cache) do
        if not live_keys[key] then animator_cache[key] = nil end
    end
end

return M
