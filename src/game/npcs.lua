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
    table.insert(out, {
        inst = model,
        name = name,
        kind = M.kind(name),
        head = head,
    })
end

local function scan_container(out, container, seen, depth)
    if not env.is_valid(container) or depth > 2 then return end
    try_add_npc(out, container, seen)

    local children = env.safe_call(function() return container:get_children() end) or {}
    for _, child in ipairs(children) do
        try_add_npc(out, child, seen)
        if depth < 2 then
            scan_container(out, child, seen, depth + 1)
        end
    end
end

function M.scan()
    local out = {}
    local seen = {}
    local military = folders.from_key("military")
    if not env.is_valid(military) then return out end

    local monuments = env.safe_call(function() return military:get_children() end) or {}
    for _, monument in ipairs(monuments) do
        scan_container(out, monument, seen, 0)
    end

    return out
end

return M
