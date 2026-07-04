--[[
    Fallen Survival hostile NPCs — from workspace.Military monument children.
    Dump confirms: Soldier, Bruno, Boris, Brutus (no zombies; VM "Zombie" skins are viewmodels only).
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

function M.scan()
    local out = {}
    local military = folders.from_key("military")
    if not env.is_valid(military) then return out end

    local monuments = env.safe_call(function() return military:get_children() end) or {}
    for _, monument in ipairs(monuments) do
        if not env.is_valid(monument) then goto next_monument end
        local children = env.safe_call(function() return monument:get_children() end) or {}
        for _, model in ipairs(children) do
            if not env.is_valid(model) then goto next_npc end
            local name = model.Name or model.name
            if not M.is_hostile_name(name) then goto next_npc end
            if not read_health(model) then goto next_npc end
            local head = env.safe_call(function()
                return model:find_first_child("Head") or model:FindFirstChild("Head")
            end)
            if not head or not env.is_valid(head) then goto next_npc end

            table.insert(out, {
                inst = model,
                name = name,
                kind = M.kind(name),
                head = head,
            })
            ::next_npc::
        end
        ::next_monument::
    end

    return out
end

return M
