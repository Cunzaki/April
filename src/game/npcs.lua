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
}

function M.is_hostile_name(name)
    return name and M.HOSTILE_NAMES[name] == true
end

function M.kind(name)
    if name == "Soldier" then return "soldier" end
    if name == "Bruno" or name == "Boris" or name == "Brutus" then return "boss" end
    if name == "AttackHeli" then return "heli" end
    return nil
end

function M.display_name(name, kind)
    if kind == "heli" or name == "AttackHeli" then
        return "Attack Heli"
    end
    return name
end

local function read_humanoid(model)
    return env.safe_call(function()
        if model.find_first_child_of_class then
            return model:find_first_child_of_class("Humanoid")
        end
        if model.FindFirstChildOfClass then
            return model:FindFirstChildOfClass("Humanoid")
        end
        for _, child in ipairs(model:get_children()) do
            if child.ClassName == "Humanoid" then return child end
        end
        return nil
    end)
end

-- Soldiers/bosses: Humanoid.Health. AttackHeli: model attributes Health/MaxHealth (Bench).
function M.read_health(model)
    if not env.is_valid(model) then return nil end

    local hum = read_humanoid(model)
    if hum then
        local hp = tonumber(hum.Health or hum.health)
        if hp and hp <= 0 then return nil end
        local max_hp = tonumber(hum.MaxHealth or hum.max_health)
        return {
            source = "humanoid",
            humanoid = hum,
            hp = hp,
            max_hp = max_hp,
        }
    end

    local hp = tonumber(env.get_attribute(model, "Health"))
    local max_hp = tonumber(env.get_attribute(model, "MaxHealth"))
    if hp == nil and max_hp == nil then return nil end
    if hp and hp <= 0 then return nil end
    return {
        source = "attribute",
        hp = hp,
        max_hp = max_hp,
    }
end

local function find_anchor(model, kind)
    if kind == "heli" then
        local main = esp_scan.find_main_part(model)
        if main then return main end
    end

    local head = env.safe_call(function()
        return model:find_first_child("Head") or model:FindFirstChild("Head")
    end)
    if head and env.is_valid(head) then return head end

    return esp_scan.find_main_part(model)
end

local function try_add_npc(out, model, seen)
    if not env.is_valid(model) then return end
    local cn = model.ClassName or model.class_name
    if cn ~= "Model" then return end

    local name = model.Name or model.name
    if not M.is_hostile_name(name) then return end

    local kind = M.kind(name)
    local addr = model.Address or model.address or tostring(model)
    if seen[addr] then return end

    local health = M.read_health(model)
    -- Soldiers/bosses need a living Humanoid. AttackHeli may exist before Health
    -- attributes replicate — still ESP once an anchor part exists.
    if not health and kind ~= "heli" then return end

    local anchor = find_anchor(model, kind)
    if not anchor or not env.is_valid(anchor) then return end

    seen[addr] = true

    local pos = anchor.Position or anchor.position
    local entry = {
        inst = model,
        name = M.display_name(name, kind),
        raw_name = name,
        kind = kind,
        head = kind ~= "heli" and anchor or nil,
        anchor = anchor,
        health_source = health and health.source or nil,
    }
    if pos and (pos.x or pos.X) then
        entry.lx = pos.x or pos.X
        entry.ly = pos.y or pos.Y
        entry.lz = pos.z or pos.Z
    end
    table.insert(out, entry)
end

local function enqueue_folder_children(state, folder)
    if not env.is_valid(folder) then return end
    local children = env.safe_call(function() return folder:get_children() end) or {}
    for _, child in ipairs(children) do
        if env.is_valid(child) then
            table.insert(state.queue, { inst = child, depth = 0 })
        end
    end
end

function M.begin_scan()
    return {
        phase = "military",
        monuments = nil,
        mi = 1,
        queue = {},
        qi = 1,
        events_done = false,
        workspace_done = false,
        out = {},
        seen = {},
    }
end

function M.step_scan(state, batch)
    local processed = 0

    -- Phase 1: Military monuments (soldiers / bosses)
    if state.phase == "military" then
        if not state.monuments then
            state.monuments = env.safe_call(function()
                local military = folders.from_key("military")
                if not env.is_valid(military) then return {} end
                return military:get_children()
            end) or {}
            state.mi = 1
            state.queue = {}
            state.qi = 1
        end

        while processed < batch do
            if state.qi > #state.queue then
                if state.mi > #state.monuments then
                    state.phase = "events"
                    break
                end

                local monument = state.monuments[state.mi]
                state.mi = state.mi + 1
                processed = processed + 1

                if env.is_valid(monument) then
                    table.insert(state.queue, { inst = monument, depth = 0 })
                end
                goto continue
            end

            local item = state.queue[state.qi]
            state.qi = state.qi + 1
            processed = processed + 1

            local container = item.inst
            if not env.is_valid(container) or item.depth > 4 then goto continue end

            try_add_npc(state.out, container, state.seen)

            local children = env.safe_call(function() return container:get_children() end) or {}
            for _, child in ipairs(children) do
                try_add_npc(state.out, child, state.seen)
                if item.depth < 4 and env.is_valid(child) then
                    table.insert(state.queue, { inst = child, depth = item.depth + 1 })
                end
            end

            ::continue::
        end

        if state.phase == "military" then
            return false
        end
    end

    -- Phase 2: Workspace.Events (AttackHeli / event vehicles live here, like BTR)
    if state.phase == "events" then
        if not state.events_done then
            state.events_done = true
            state.queue = {}
            state.qi = 1
            local events = folders.from_key("events")
            enqueue_folder_children(state, events)
            -- Also walk one level deeper (monument-scoped event folders).
            local kids = env.safe_call(function()
                if not env.is_valid(events) then return {} end
                return events:get_children()
            end) or {}
            for _, child in ipairs(kids) do
                if env.is_valid(child) then
                    local cn = child.ClassName or child.class_name
                    if cn == "Folder" or cn == "Model" then
                        enqueue_folder_children(state, child)
                    end
                end
            end
        end

        while processed < batch and state.qi <= #state.queue do
            local item = state.queue[state.qi]
            state.qi = state.qi + 1
            processed = processed + 1
            try_add_npc(state.out, item.inst, state.seen)
            if item.depth < 2 and env.is_valid(item.inst) then
                local children = env.safe_call(function() return item.inst:get_children() end) or {}
                for _, child in ipairs(children) do
                    try_add_npc(state.out, child, state.seen)
                    if env.is_valid(child) then
                        table.insert(state.queue, { inst = child, depth = item.depth + 1 })
                    end
                end
            end
        end

        if state.qi > #state.queue then
            state.phase = "workspace_root"
        else
            return false
        end
    end

    -- Phase 3: Workspace root Models named AttackHeli (server may parent directly)
    if state.phase == "workspace_root" then
        if not state.workspace_done then
            state.workspace_done = true
            local ws = env.get_workspace()
            local kids = env.safe_call(function()
                if not ws then return {} end
                return ws:get_children()
            end) or {}
            for _, child in ipairs(kids) do
                try_add_npc(state.out, child, state.seen)
            end
        end
        return true
    end

    return true
end

function M.complete_scan(state)
    return state.out or {}
end

function M.scan()
    local state = M.begin_scan()
    while not M.step_scan(state, 9999) do end
    return M.complete_scan(state)
end

return M
