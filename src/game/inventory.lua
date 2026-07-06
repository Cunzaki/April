local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")

local M = {}

function M.get_local_inventory()
    local lp = env.get_local_player()
    if not lp or not lp.character then return nil end
    local char = lp.character
    if not env.is_valid(char) then return nil end
    local ic = env.safe_call(function() return char:find_first_child("InventoryController") end)
    if not ic then return nil end
    local fetch = env.safe_call(function() return ic:find_first_child("Fetch") end)
    if not fetch or not fetch.Invoke then return nil end
    local ok, inv, toolbar, armor = pcall(function() return fetch:Invoke() end)
    if not ok or not inv then return nil end
    return { inventory = inv, toolbar = toolbar, armor = armor }
end

function M.resolve_item_name(id)
    if type(id) ~= "number" then return tostring(id) end

    local row = item_catalog.get(id)
    if row and row.name then return row.name end

    local rep = env.get_replicated_storage()
    if not rep then return "Item#" .. id end
    local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
    local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
    if items_mod then
        local ok, data = pcall(function() return require(items_mod) end)
        if ok and data and data[id] and data[id].Name then
            return data[id].Name
        end
    end
    return "Item#" .. id
end

local function read_attribute(inst, key)
    if not inst or not key then return nil end
    if inst.GetAttribute then return inst:GetAttribute(key) end
    if inst.get_attribute then return inst:get_attribute(key) end
    return nil
end

local function find_child(char, name)
    if not char then return nil end
    return env.safe_call(function()
        if char.find_first_child then return char:find_first_child(name) end
        return char:FindFirstChild(name)
    end)
end

function M.get_toolbar_entry(char)
    if not char or not env.is_valid(char) then return nil, nil end

    local ic = find_child(char, "InventoryController")
    if not ic then return nil, nil end

    local fetch = env.safe_call(function()
        if ic.find_first_child then return ic:find_first_child("Fetch") end
        return ic:FindFirstChild("Fetch")
    end)
    if not fetch or not fetch.Invoke then return nil, nil end

    local slot = read_attribute(find_child(char, "EquipController"), "Equipped")
    if type(slot) ~= "number" or slot <= 0 then
        slot = read_attribute(find_child(char, "ViewmodelController"), "Equipped")
    end
    if type(slot) ~= "number" or slot <= 0 then return nil, nil end

    local ok, data = pcall(function() return fetch:Invoke() end)
    if not ok or type(data) ~= "table" then return nil, nil end

    local toolbar = data.Toolbar or data.toolbar
    if type(toolbar) ~= "table" then return nil, nil end

    local entry = toolbar[slot]
    if not entry or entry == 0 then return nil, nil end
    if type(entry) == "table" and entry.Amount and entry.Amount <= 0 then return nil, nil end

    return entry, slot
end

function M.get_equipped_ammo_stats()
    local lp = env.get_local_player()
    local char = lp and lp.character
    if not char or not env.is_valid(char) then return nil end

    local entry = M.get_toolbar_entry(char)
    if not entry or type(entry) ~= "table" then return nil end

    local ammo = entry.Ammo
    if not ammo or type(ammo) ~= "table" then return nil end

    local ammo_id = ammo.ID
    if type(ammo_id) ~= "number" then return nil end

    items.load()
    local row = items.get_by_id and items.get_by_id(ammo_id)
    if row and row.AmmoStats then return row.AmmoStats end

    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and data and data[ammo_id] and data[ammo_id].AmmoStats then
                return data[ammo_id].AmmoStats
            end
        end
    end

    return nil
end

function M.get_toolbar_held_name(char)
    local entry = M.get_toolbar_entry(char)
    if not entry then return nil end

    local id = type(entry) == "table" and entry.ID or entry
    if type(id) ~= "number" then return nil end

    return M.resolve_item_name(id)
end

function M.get_held_tool_name()
    local lp = env.get_local_player()
    if not lp then return nil end
    if lp.tool_name and lp.tool_name ~= "" then return lp.tool_name end

    local char = lp.character
    if not char or not env.is_valid(char) then return nil end

    local toolbar_name = M.get_toolbar_held_name(char)
    if toolbar_name and toolbar_name ~= "" then return toolbar_name end

    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if child.ClassName == "Tool" then return child.Name end
    end
    return nil
end

return M
