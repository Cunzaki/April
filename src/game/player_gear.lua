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
    table.insert(out.armor, piece)
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
        add_armor_piece(out, seen, items.resolve_armor_model(name))
        return
    end

    if name:sub(1, 6) == "Armor:" then
        add_armor_piece(out, seen, items.resolve_item_label(name:sub(7)))
    end
end

local function try_armor_attribute(out, seen, attr_key)
    if not attr_key or attr_key:sub(1, 6) ~= "Armor_" then return end

    local tail = attr_key:match("^Armor_(.+)$")
    if not tail then return end

    local piece = items.resolve_armor_model(attr_key)
    if piece then
        add_armor_piece(out, seen, piece)
        return
    end

    local row = item_catalog.get_by_attribute(tail)
    if row and row.name then
        if tail == "ResistWet" and (seen["Hazmat Suit"] or seen["Wetsuit"]) then
            return
        end
        add_armor_piece(out, seen, items.make_piece(row.name, nil))
    end
end

local function scan_armor_attributes(inst, out, seen)
    for _, attr in ipairs(ARMOR_ATTRIBUTES) do
        local key = "Armor_" .. attr
        if read_attribute(inst, key) then
            try_armor_attribute(out, seen, key)
        end
    end

    local attrs = env.safe_call(function()
        if inst.get_attributes then return inst:get_attributes() end
        if inst.GetAttributes then return inst:GetAttributes() end
    end)

    if type(attrs) == "table" then
        for key in pairs(attrs) do
            if type(key) == "string" then
                try_armor_attribute(out, seen, key)
            end
        end
    end
end

local function scan_sleeves_string(out, seen, sleeves)
    if not sleeves or sleeves == "" then return end
    for entry in sleeves:gmatch("[^%^]+") do
        entry = entry:match("^%s*(.-)%s*$")
        if entry and entry ~= "" then
            add_armor_piece(out, seen, items.resolve_item_label(entry))
        end
    end
end

local function resolve_character(player)
    if player.character and env.is_valid(player.character) then
        return player.character
    end

    if player.player and env.is_valid(player.player) then
        local char = env.safe_call(function()
            local pl = player.player
            if pl.Character then return pl.Character end
            if pl.character then return pl.character end
        end)
        if char and env.is_valid(char) then return char end
    end

    if player.name and game and game.workspace then
        local char = env.safe_call(function()
            if game.workspace.find_first_child then
                return game.workspace:find_first_child(player.name)
            end
        end)
        if char and env.is_valid(char) then return char end
    end

    return nil
end

local function resolve_player_inst(player)
    if player.player and env.is_valid(player.player) then
        return player.player
    end
    if not player.name or not game or not game.players then return nil end
    return env.safe_call(function()
        if game.players.find_first_child then
            return game.players:find_first_child(player.name)
        end
    end)
end

local function scan_instance_tree(inst, out, seen, depth)
    if not inst or not env.is_valid(inst) or depth > 8 then return end

    local name = inst.Name or inst.name
    if name and name ~= "" then
        if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then
            try_armor_model(out, seen, name)
        end

        if not out.held then
            local cn = (inst.ClassName or inst.class_name or ""):lower()
            if cn == "tool" then
                add_held_piece(out, name)
            elseif items.is_held_display(name) or weapons.is_weapon_name(name) then
                add_held_piece(out, name)
            end
        end
    end

    local children = env.safe_call(function()
        if inst.get_children then return inst:get_children() end
        if inst.GetChildren then return inst:GetChildren() end
    end) or {}

    for _, child in ipairs(children) do
        scan_instance_tree(child, out, seen, depth + 1)
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

    local char = resolve_character(player)
    local seen = {}

    if char then
        scan_instance_tree(char, out, seen, 0)
        scan_armor_attributes(char, out, seen)
    end

    local pl = resolve_player_inst(player)
    if pl then
        scan_armor_attributes(pl, out, seen)
        scan_sleeves_string(out, seen, read_attribute(pl, "ArmorSleeves"))
    end

    return out
end

return M
