--[[
    Fallen hostile NPCs — Soldiers + bosses under Workspace.Military monuments.
    Soldiers spawn at runtime (not in static dump); scan runs periodically.
]]

local env = April.require("core.env")
local folders = April.require("game.folders")

local M = {}

M.HOSTILE_NAMES = {
    Soldier = true,
    Bruno = true,
    Boris = true,
    Brutus = true,
}

function M.is_hostile_name(name)
    return name and M.HOSTILE_NAMES[name] == true
end

function M.kind(name)
    if name == "Soldier" then return "soldier" end
    if name == "Bruno" or name == "Boris" or name == "Brutus" then return "boss" end
    return nil
end

local function read_health(model)
    local hum = env.safe_call(function()
        if model.find_first_child_of_class then
            return model:find_first_child_of_class("Humanoid")
        end
        for _, child in ipairs(model:get_children()) do
            if child.ClassName == "Humanoid" then return child end
        end
        return nil
    end)
    if not hum then return nil end
    local hp = hum.Health or hum.health
    if hp and hp <= 0 then return nil end
    return hum
end

local function try_add_npc(out, model, seen)
    if not env.is_valid(model) then return end
    local cn = model.ClassName or model.class_name
    if cn ~= "Model" then return end

    local name = model.Name or model.name
    if not M.is_hostile_name(name) then return end

    local addr = model.Address or model.address or tostring(model)
    if seen[addr] then return end

    if not read_health(model) then return end

    local head = env.safe_call(function()
        return model:find_first_child("Head") or model:FindFirstChild("Head")
    end)
    if not head or not env.is_valid(head) then return end

    seen[addr] = true

    local pos = head.Position or head.position
    local entry = {
        inst = model,
        name = name,
        kind = M.kind(name),
        head = head,
    }
    if pos and pos.x then
        entry.lx = pos.x
        entry.ly = pos.y
        entry.lz = pos.z
    end
    table.insert(out, entry)
end

function M.begin_scan()
    return {
        monuments = nil,
        mi = 1,
        queue = {},
        qi = 1,
        out = {},
        seen = {},
    }
end

function M.step_scan(state, batch)
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

    local processed = 0

    while processed < batch do
        if state.qi > #state.queue then
            if state.mi > #state.monuments then
                return true
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

    return false
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
