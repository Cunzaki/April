local env = April.require("core.env")
local folders = April.require("game.folders")
local esp_scan = April.require("game.esp_scan")

local M = {}

M.HOSTILE_NAMES = {
    Soldier = true,
    Bruno = true,
    Boris = true,
    Brutus = true,
    AttackHeli = true,
    BTR = true,
}
M.NPC_NAMES = {
    Soldier = true,
    Bruno = true,
    Boris = true,
    Brutus = true,
    AttackHeli = true,
    BTR = true,
    ["Diver Dave"] = true,
    ["Pilot Pete"] = true,
}

local EVENT_REFRESH_MS = 750

local entity_entries = {}
local event_entries = {}
local last_event_refresh = -EVENT_REFRESH_MS

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function clear_array(list)
    for i = #list, 1, -1 do list[i] = nil end
end

local function find_child(parent, name)
    if not parent then return nil end
    return env.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

local function children(parent)
    if not parent then return {} end
    return env.safe_call(function()
        if parent.GetChildren then return parent:GetChildren() end
        if parent.get_children then return parent:get_children() end
        return {}
    end) or {}
end

local function vec3(v)
    if not v then return nil end
    return v.X or v.x, v.Y or v.y, v.Z or v.z
end

local function address(value)
    if not value then return nil end
    return tostring(value.Address or value.address or value)
end

function M.is_hostile_name(name)
    return name and M.HOSTILE_NAMES[name] == true
end

function M.is_hostile_kind(kind)
    return kind == "soldier" or kind == "bruno" or kind == "boris"
        or kind == "brutus" or kind == "heli" or kind == "btr"
end

function M.is_boss_kind(kind)
    return kind == "bruno" or kind == "boris" or kind == "brutus"
        or kind == "heli" or kind == "btr"
end

function M.is_boss_name(name)
    return M.is_boss_kind(M.kind(name))
end

function M.kind(name)
    name = tostring(name or ""):lower():gsub("[%s_%-]", "")
    if name == "soldier" or name:find("soldier", 1, true) == 1 then return "soldier" end
    if name == "bruno" then return "bruno" end
    if name == "boris" then return "boris" end
    if name == "brutus" then return "brutus" end
    if name == "attackheli" or name:find("attackheli", 1, true) == 1 then return "heli" end
    if name == "btr" then return "btr" end
    if name == "diverdave" then return "diver_dave" end
    if name == "pilotpete" then return "pilot_pete" end
    return nil
end

function M.display_name(name, kind)
    if kind == "heli" then return "Attack Heli" end
    if kind == "btr" then return "BTR" end
    if kind == "diver_dave" then return "Diver Dave" end
    if kind == "pilot_pete" then return "Pilot Pete" end
    return name
end

local function part_pos(part)
    if not part then return nil end
    return vec3(part.Position or part.position)
end

local function part_name_lower(part)
    return tostring(part and (part.Name or part.name) or ""):lower()
end

-- Dump: ViewmodelController treats AttackHeli parts with RotorBonus > 0 as weak points
-- ("HitHead"). Rotor part names are not in the static place dump — scan live attributes
-- and common rotor-ish names from the player Flycopter as fallbacks.
function M.collect_heli_weak_points(model)
    if not model or not env.is_valid(model) then return {} end
    local out = {}
    local seen = {}

    local function add(part, score)
        if not part or not env.is_valid(part) then return end
        local key = address(part)
        if not key or seen[key] then return end
        local x, y, z = part_pos(part)
        if not x then return end
        seen[key] = true
        out[#out + 1] = {
            part = part,
            x = x, y = y, z = z,
            score = score or 1,
            name = part.Name or part.name,
        }
    end

    local desc = env.safe_call(function()
        if model.GetDescendants then return model:GetDescendants() end
        if model.get_descendants then return model:get_descendants() end
        return nil
    end)

    if type(desc) == "table" then
        for i = 1, #desc do
            local part = desc[i]
            if not part then goto cont end
            local cn = part.ClassName or part.class_name or ""
            if cn ~= "Part" and cn ~= "MeshPart" and cn ~= "BasePart"
                and cn ~= "WedgePart" and cn ~= "UnionOperation" then
                goto cont
            end
            local bonus = tonumber(env.get_attribute(part, "RotorBonus")) or 0
            if bonus > 0 then
                add(part, 100 + bonus)
            else
                local n = part_name_lower(part)
                if n:find("rotor", 1, true) or n:find("blade", 1, true)
                    or n == "spinner" or n:find("tailrotor", 1, true)
                    or n:find("mainrotor", 1, true) then
                    add(part, 40)
                end
            end
            ::cont::
        end
    else
        -- Shallow fallback when GetDescendants is unavailable.
        for _, name in ipairs({ "MainRotor", "TailRotor", "Blades", "Spinner" }) do
            local part = find_child(model, name)
            if part then add(part, 40) end
            for _, child in ipairs(children(part)) do
                local n = part_name_lower(child)
                if n:find("rotor", 1, true) or n:find("blade", 1, true) or n == "spinner" then
                    add(child, 40)
                end
            end
        end
    end

    table.sort(out, function(a, b)
        return (a.score or 0) > (b.score or 0)
    end)
    return out
end

-- Best heli aim point: prefer RotorBonus weak parts, then named rotors, else body.
function M.heli_aim_world(entry, prefer_screen, cx, cy)
    if not entry then return nil end
    local model = entry.inst
    if (not model or not env.is_valid(model)) and entry.entity then
        model = entry.entity.Character or entry.entity.character
    end
    local weak = M.collect_heli_weak_points(model)
    if #weak == 0 then
        local body = entry.root or entry.anchor or entry.head
        if (not body or not env.is_valid(body)) and model and env.is_valid(model) then
            body = find_child(model, "Main") or find_child(model, "HumanoidRootPart")
                or model.PrimaryPart or model.primary_part or esp_scan.find_main_part(model)
        end
        local x, y, z = part_pos(body)
        if x then return { x = x, y = y, z = z } end
        if entry.lx ~= nil and entry.ly ~= nil and entry.lz ~= nil then
            return { x = entry.lx, y = entry.ly, z = entry.lz }
        end
        return nil
    end

    if prefer_screen and cx and cy then
        local esp_util = April.require("core.esp_util")
        local math_util = April.require("core.math_util")
        local best, best_d = nil, math.huge
        for i = 1, #weak do
            local w = weak[i]
            local sx, sy, on = esp_util.w2s(w.x, w.y, w.z)
            if on then
                local d = math_util.screen_fov_dist(sx, sy, cx, cy)
                -- Prefer true RotorBonus slightly over mere name matches when FOV-close.
                d = d - (w.score or 0) * 0.01
                if d < best_d then
                    best, best_d = w, d
                end
            end
        end
        if best then
            return { x = best.x, y = best.y, z = best.z }
        end
    end

    local top = weak[1]
    return { x = top.x, y = top.y, z = top.z }
end

local function read_humanoid(model)
    if not model then return nil end
    return env.safe_call(function()
        if model.FindFirstChildOfClass then return model:FindFirstChildOfClass("Humanoid") end
        if model.find_first_child_of_class then return model:find_first_child_of_class("Humanoid") end
        return find_child(model, "Humanoid")
    end)
end

-- Event vehicles only. Entity-backed NPCs use live Vector health fields.
function M.read_health(model, humanoid)
    if not model or not env.is_valid(model) then return nil end
    local hum = humanoid or read_humanoid(model)
    if hum then
        local hp = tonumber(hum.Health or hum.health)
        if hp and hp <= 0 then return nil end
        return {
            source = "humanoid",
            humanoid = hum,
            hp = hp,
            max_hp = tonumber(hum.MaxHealth or hum.max_health),
        }
    end

    local hp = tonumber(env.get_attribute(model, "Health"))
    local max_hp = tonumber(env.get_attribute(model, "MaxHealth"))
    if hp == nil and max_hp == nil then return nil end
    if hp and hp <= 0 then return nil end
    return { source = "attribute", hp = hp, max_hp = max_hp }
end

local function update_entity_entry(entry, player, name, kind)
    entry.entity = player
    entry.inst = player.Character or player.character
    entry.name = M.display_name(name, kind)
    entry.raw_name = name
    entry.kind = kind
    entry.event = false

    local x, y, z = vec3(player.HeadPosition or player.head_position or player.Position or player.position)
    if x then entry.lx, entry.ly, entry.lz = x, y, z end
    return entry
end

local function event_entry(model, name, kind)
    if not model or not env.is_valid(model) then return nil end
    local key = address(model)
    local entry = event_entries[key] or {}
    local root = entry.root
    if not root or not env.is_valid(root) then
        root = find_child(model, "HumanoidRootPart") or find_child(model, "Main")
            or esp_scan.find_main_part(model)
    end
    if not root or not env.is_valid(root) then return nil end

    entry.entity = nil
    entry.inst = model
    entry.name = M.display_name(name, kind)
    entry.raw_name = name
    entry.kind = kind
    entry.event = true
    entry.vehicle = kind == "heli" or kind == "btr"
    entry.root = root
    entry.anchor = root
    entry.humanoid = entry.humanoid or read_humanoid(model)
    entry.key = key
    entry.lx, entry.ly, entry.lz = vec3(root.Position or root.position)
    event_entries[key] = entry
    return entry
end

local function add_event(out, seen, model, expected_name)
    if not model then return end
    local name = model.Name or model.name or expected_name
    local kind = M.kind(name)
    if not kind and expected_name then
        name = expected_name
        kind = M.kind(name)
    end
    if not kind then return end
    local entry = event_entry(model, name, kind)
    if not entry or seen[entry.key] then return end
    seen[entry.key] = true
    out[#out + 1] = entry
end

local function refresh_events()
    local out, seen = {}, {}
    local events = folders.from_key("events")

    -- Place 806 dump verifies this exact path.
    add_event(out, seen, find_child(events, "BTR"), "BTR")

    -- AttackHeli is runtime-spawned; inspect only direct event/root children.
    for _, child in ipairs(children(events)) do
        local name = child.Name or child.name
        if name == "AttackHeli" then add_event(out, seen, child, name) end
    end
    local ws = env.get_workspace()
    for _, child in ipairs(children(ws)) do
        local name = child.Name or child.name
        if name == "AttackHeli" or name == "BTR" then
            add_event(out, seen, child, name)
        end
    end

    -- EventViewer.lua verifies bosses as direct monument children. The dump
    -- contains soldier PresetSpawns but no live soldier model/name, so direct
    -- Military Humanoid children provide the name-independent fallback. This
    -- stays shallow; PresetSpawns/geometry are never traversed.
    local military = folders.from_key("military")
    for _, monument in ipairs(children(military)) do
        local location = monument.Name or monument.name
        for _, model in ipairs(children(monument)) do
            local kind = M.kind(model.Name or model.name)
            if kind == "soldier" or kind == "bruno" or kind == "boris" or kind == "brutus" then
                add_event(out, seen, model)
                local entry = event_entries[address(model)]
                if entry then entry.location = location end
            elseif (model.ClassName or model.class_name) == "Model" and read_humanoid(model) then
                -- Runtime military humanoids not carrying a canonical wrapper
                -- name are regular soldiers. Spawn markers have no Humanoid.
                add_event(out, seen, model, "Soldier")
                local entry = event_entries[address(model)]
                if entry then entry.location = location end
            end
        end
    end

    -- BenchInfo identifies both vendor NPCs; their runtime models are direct
    -- children of their Loners buckets.
    local loners = folders.from_key("loners")
    for _, npc_name in ipairs({ "Diver Dave", "Pilot Pete" }) do
        local bucket = find_child(loners, npc_name)
        for _, model in ipairs(children(bucket)) do
            if M.kind(model.Name or model.name) then
                add_event(out, seen, model, npc_name)
            end
        end
    end

    for key in pairs(event_entries) do
        if not seen[key] then event_entries[key] = nil end
    end
    return out
end

-- Build cache.npcs from Vector's per-frame workspace entities plus a tiny,
-- throttled set of direct event lookups. Entries are reused to avoid GC churn.
function M.refresh_cache(workspace_entities)
    local cache = April.require("core.cache")
    local out = cache.npcs
    clear_array(out)

    local seen = {}
    for i = 1, #(workspace_entities or {}) do
        local player = workspace_entities[i]
        local character = player and (player.Character or player.character)
        local name = player and (player.Name or player.name)
        if not M.kind(name) and character then
            name = character.Name or character.name or name
        end
        local kind = M.kind(name)
        if kind then
            local key = address(character or player)
            local entry = entity_entries[key] or {}
            entity_entries[key] = update_entity_entry(entry, player, name, kind)
            seen[key] = true
            out[#out + 1] = entry
        end
    end
    for key in pairs(entity_entries) do
        if not seen[key] then entity_entries[key] = nil end
    end

    local now = tick_ms()
    if now - last_event_refresh >= EVENT_REFRESH_MS then
        M._events = refresh_events()
        last_event_refresh = now
    end
    for i = 1, #(M._events or {}) do
        local entry = M._events[i]
        local duplicate = entry.key and seen[entry.key]
        if not duplicate and entry.inst and env.is_valid(entry.inst) then
            local x, y, z = vec3(entry.root and (entry.root.Position or entry.root.position))
            if x then entry.lx, entry.ly, entry.lz = x, y, z end
            out[#out + 1] = entry
        end
    end

    cache.stats.last_npc_scan = now
    return out
end

return M
