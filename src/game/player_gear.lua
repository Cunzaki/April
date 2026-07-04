local env = April.require("core.env")
local armor_map = April.require("game.armor_map")
local items = April.require("game.items")
local weapons = April.require("game.weapons")
local inventory = April.require("game.inventory")

local M = {}

local HOTBAR_SLOTS = 7

local function parse_armor_child(name)
    if not name or not name:find("Armor_", 1, true) then return nil end
    local model_key, variant = name:match("^(Armor_%d+)[%/]?(%w*)")
    if not model_key then
        model_key = name:match("^(Armor_%d+)")
    end
    if variant == "" then variant = nil end
    return model_key, variant
end

local function parse_toolbar_entry(entry)
    if not entry or entry == 0 then return nil end
    if type(entry) ~= "table" then return nil end

    local amount = entry.Amount or entry.amount or 0
    local id = entry.ID or entry.id
    if not id or amount <= 0 then return nil end

    local name = inventory.resolve_item_name(id)
    if not name or name:find("^Item#") then return nil end

    return {
        name = name,
        item_id = id,
        amount = amount,
    }
end

local function scan_toolbar(char)
    local ic = env.safe_call(function()
        return char:find_first_child("InventoryController") or char:FindFirstChild("InventoryController")
    end)
    if not ic then return nil end

    local fetch = env.safe_call(function()
        return ic:find_first_child("Fetch") or ic:FindFirstChild("Fetch")
    end)
    if not fetch or not fetch.Invoke then return nil end

    local ok, inv, toolbar, armor = pcall(function() return fetch:Invoke() end)
    if not ok then return nil end

    if type(toolbar) ~= "table" then
        if type(inv) == "table" and inv.Toolbar then
            toolbar = inv.Toolbar
        else
            return nil
        end
    end

    local slots = {}
    for i = 1, HOTBAR_SLOTS do
        slots[i] = parse_toolbar_entry(toolbar[i])
    end

    return slots, armor
end

local function scan_armor_on_character(char)
    local out = {}
    local seen = {}
    local children = env.safe_call(function() return char:get_children() end) or {}

    for _, child in ipairs(children) do
        if not env.is_valid(child) then goto continue end
        local name = child.Name or child.name
        if not name then goto continue end

        local model_key, variant = parse_armor_child(name)
        if model_key then
            local item_name = armor_map.item_name(model_key)
            if item_name and not seen[item_name] then
                seen[item_name] = true
                table.insert(out, {
                    name = item_name,
                    variant = variant,
                    asset_id = items.get_image_asset_id(item_name, variant),
                    model_key = model_key,
                })
            end
        end

        ::continue::
    end

    return out
end

local function left_pack(entries)
    local packed = {}
    for _, entry in ipairs(entries or {}) do
        if entry then
            table.insert(packed, entry)
            if #packed >= HOTBAR_SLOTS then break end
        end
    end
    return packed
end

local function find_held_tool(char, player)
    if player.tool_name and player.tool_name ~= "" then
        return player.tool_name
    end

    if not char or not env.is_valid(char) then return nil end

    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if not env.is_valid(child) then goto continue end
        local name = child.Name or child.name
        if not name then goto continue end

        if weapons.is_weapon_name(name) then
            return name
        end

        local is_tool = env.safe_call(function()
            return child:is_a("Tool") or child.ClassName == "Tool"
        end)
        if is_tool then
            return name
        end

        ::continue::
    end

    return nil
end

function M.scan_player(player)
    local out = {
        held = nil,
        slots = {},
        armor = {},
    }

    if not player then return out end

    local char = player.character
    out.held = find_held_tool(char, player)

    if char and env.is_valid(char) then
        local toolbar_slots = scan_toolbar(char)
        if toolbar_slots then
            out.slots = left_pack(toolbar_slots)
        else
            out.armor = scan_armor_on_character(char)
            out.slots = left_pack(out.armor)
        end
    end

    return out
end

return M
