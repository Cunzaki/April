local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")
local weapons = April.require("game.weapons")

local M = {}

local ARMOR_ATTRIBUTES = {
    "ResistWet",
    "HasFlippers",
    "HasTank",
    "HasGoggles",
    "NVG",
    "SilentSteps",
    "WaterFilter",
    "SteelToes",
    "Snorkle",
}

local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then
        return base, variant
    end
    return name, nil
end

local function read_attribute(inst, key)
    if not inst or not key then return nil end
    if inst.GetAttribute then
        return inst:GetAttribute(key)
    end
    if inst.get_attribute then
        return inst:get_attribute(key)
    end
    return nil
end

local function add_armor_piece(out, seen, piece)
    if not piece or not piece.name then return end
    if seen[piece.name] then return end
    seen[piece.name] = true
    table.insert(out, piece)
end

local function add_held_piece(out, label)
    if not label or label == "" then return false end

    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end

    out.held = piece
    return true
end

local function try_armor_model(out, seen, name)
    if not name then return end

    if name:sub(1, 6) == "Armor_" then
        local piece = items.resolve_armor_model(name)
        add_armor_piece(out, seen, piece)
        return
    end

    if name:sub(1, 6) == "Armor:" then
        local piece = items.resolve_item_label(name:sub(7))
        add_armor_piece(out, seen, piece)
    end
end

local function try_held_from_name(out, name)
    if not name or name == "" or out.held then return end

    if add_held_piece(out, name) then return end

    local base, variant = parse_variant_name(name)
    if weapons.is_weapon_name(base or name) or items.is_held_display(base or name) then
        add_held_piece(out, name)
    end
end

local function scan_armor_attributes(char, out, seen)
    for _, attr in ipairs(ARMOR_ATTRIBUTES) do
        local key = "Armor_" .. attr
        local val = read_attribute(char, key)
        if val then
            if attr == "ResistWet" then
                if seen["Hazmat Suit"] or seen["Wetsuit"] then
                    goto continue_attr
                end
            end

            local row = item_catalog.get_by_attribute(attr)
            if row and row.name then
                add_armor_piece(out, seen, items.make_piece(row.name, nil))
            end
        end

        ::continue_attr::
    end
end

local function scan_character_tree(char, out, seen, depth)
    if not env.is_valid(char) or depth > 3 then return end

    local children = env.safe_call(function() return char:get_children() end) or {}
    for _, child in ipairs(children) do
        if not env.is_valid(child) then goto continue end

        local name = child.Name or child.name
        if not name or name == "" then goto continue end

        local cn = child.ClassName or child.class_name

        if cn == "Model" then
            if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then
                try_armor_model(out, seen, name)
            end
        end

        if not out.held then
            if cn == "Tool" then
                add_held_piece(out, name)
            elseif items.is_held_display(name) or weapons.is_weapon_name(name) then
                try_held_from_name(out, name)
            end
        end

        if cn == "Model" or cn == "Folder" then
            scan_character_tree(child, out, seen, depth + 1)
        end

        ::continue::
    end
end

function M.scan_player(player)
    local out = {
        held = nil,
        armor = {},
    }

    if not player then return out end

    if player.tool_name and player.tool_name ~= "" then
        add_held_piece(out, player.tool_name)
    end

    local char = player.character
    if not char or not env.is_valid(char) then return out end

    local seen = {}
    scan_character_tree(char, out, seen, 0)
    scan_armor_attributes(char, out, seen)

    return out
end

return M
