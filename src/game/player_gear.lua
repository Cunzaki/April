local env = April.require("core.env")
local items = April.require("game.items")
local item_catalog = April.require("game.item_catalog")
local inventory = April.require("game.inventory")
local weapons = April.require("game.weapons")
local attachment_images = April.require("game.attachment_images")

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

local ATTACHMENT_SLOT_HINTS = {
    ["p1"] = true, ["p2"] = true, ["p3"] = true, ["p4"] = true,
    ["slot1"] = true, ["slot2"] = true, ["slot3"] = true,
    ["sight"] = true, ["muzzle"] = true, ["underbarrel"] = true,
    ["barrel"] = true, ["magazine"] = true,
}

local EMPTY_HELD_NAMES = {
    ["hand"] = true, ["hands"] = true, ["fist"] = true, ["fists"] = true,
    ["unarmed"] = true, ["nothing"] = true, ["none"] = true, ["empty"] = true,
    ["hair"] = true,
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

local function is_tool(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    return cn == "Tool"
end

local function is_empty_held_name(name)
    if not name or name == "" then return true end
    return EMPTY_HELD_NAMES[name:lower()] == true
end

local function is_attachment_slot_name(name)
    if not name or name == "" then return true end
    local lower = name:lower()
    if ATTACHMENT_SLOT_HINTS[lower] then return true end
    if lower:match("^p%d+$") then return true end
    if lower:match("^slot%d+$") then return true end
    return false
end

local function is_armor_child_name(name)
    if not name or name == "" then return true end
    if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then return true end
    if name:find("Armor", 1, true) and name:find("/", 1, true) then return true end
    return false
end

local function is_attachment_name(name)
    if not name or name == "" then return false end
    if is_attachment_slot_name(name) then return false end

    local base = select(1, parse_variant_name(name))
    local row = item_catalog.get_by_name(base)
    if row and row.type == "Attachment" then return true end

    local t = items.get_type(base)
    return t == "Attachment"
end

local function is_valid_held_label(name)
    if is_empty_held_name(name) then return false end
    if not name or name == "" then return false end
    if is_attachment_slot_name(name) then return false end
    if is_armor_child_name(name) then return false end
    if is_attachment_name(name) then return false end
    return true
end

local function looks_like_held_item(name)
    if not is_valid_held_label(name) then return false end
    if weapons.is_weapon_name(name) then return true end
    if items.is_held_display(name) then return true end
    return true
end

local function add_armor_piece(out, seen, piece)
    if not piece or not piece.name then return end
    if seen[piece.name] then return end
    seen[piece.name] = true
    table.insert(out.armor, piece)
end

local function add_held_piece(out, label)
    if is_empty_held_name(label) then
        out.held = nil
        return false
    end
    if not is_valid_held_label(label) then return false end

    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end

    out.held = piece
    return true
end

local function add_attachment_piece(out, seen, label)
    if not label or label == "" then return end
    if is_attachment_slot_name(label) then return end
    if not is_attachment_name(label) then return end
    if seen[label] then return end

    seen[label] = true
    local piece = items.resolve_item_label(label)
    if not piece then
        local base, variant = parse_variant_name(label)
        piece = items.make_piece(base or label, variant)
    end
    table.insert(out.attachments, piece)
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

local function find_inst_by_name(char, name)
    if not char or not name then return nil end

    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local child_name = child.Name or child.name
        if child_name == name then
            return child
        end
    end

    return nil
end

local function find_held_on_character(char)
    if not char then return nil, nil end

    local fallback = nil
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        local name = child.Name or child.name
        if not name or name == "" or is_armor_child_name(name) then goto continue end
        if not is_valid_held_label(name) then goto continue end

        if is_tool(child) then
            return name, child
        end

        local cn = child.ClassName or child.class_name
        if cn == "Model" and looks_like_held_item(name) then
            if weapons.is_weapon_name(name) or items.is_held_display(name) then
                return name, child
            end
            fallback = fallback or { name = name, inst = child }
        end

        ::continue::
    end

    if fallback then
        return fallback.name, fallback.inst
    end

    return nil, nil
end

local function resolve_held_weapon(player, char)
    if player.tool_name and player.tool_name ~= "" and is_valid_held_label(player.tool_name) then
        local inst = char and find_inst_by_name(char, player.tool_name) or nil
        return player.tool_name, inst
    end

    if char then
        local toolbar_name = inventory.get_toolbar_held_name(char)
        if toolbar_name and is_valid_held_label(toolbar_name) then
            local inst = find_inst_by_name(char, toolbar_name) or select(2, find_held_on_character(char))
            return toolbar_name, inst
        end

        local name, inst = find_held_on_character(char)
        if name then
            return name, inst
        end
    end

    if player.is_local then
        local name = weapons.get_held_weapon_name()
        if name and is_valid_held_label(name) then
            local inst = char and (find_inst_by_name(char, name) or select(2, find_held_on_character(char))) or nil
            return name, inst
        end
    end

    return nil, nil
end

local function find_attachments_folder(parent)
    if not parent or not env.is_valid(parent) then return nil end
    return env.safe_call(function()
        if parent.find_first_child then
            return parent:find_first_child("Attachments") or parent:find_first_child("attachments")
        end
        return parent:FindFirstChild("Attachments") or parent:FindFirstChild("attachments")
    end)
end

-- Fallen Ultimate pattern: Attachments:GetChildren() → attachment item names only.
-- Do not recurse into attachment model internals (Vignette, Sight mesh parts, etc.).
local function scan_weapon_attachments_folder(folder, out, seen, depth)
    depth = depth or 0
    if not folder or not env.is_valid(folder) or depth > 4 then return end

    local children = env.safe_call(function()
        if folder.get_children then return folder:get_children() end
        if folder.GetChildren then return folder:GetChildren() end
    end) or {}

    for _, child in ipairs(children) do
        local name = child.Name or child.name
        if not name or name == "" then goto continue end

        local cn = child.ClassName or child.class_name
        if cn == "StringValue" or cn == "stringvalue" then
            local val = child.Value or child.value
            if val and val ~= "" then
                add_attachment_piece(out, seen, val)
            end
            goto continue
        end

        if is_attachment_slot_name(name) then
            scan_weapon_attachments_folder(child, out, seen, depth + 1)
            goto continue
        end

        add_attachment_piece(out, seen, name)

        ::continue::
    end
end

local function scan_weapon_attachments(char, tool_inst, out, seen)
    if tool_inst and env.is_valid(tool_inst) then
        scan_weapon_attachments_folder(find_attachments_folder(tool_inst), out, seen)

        local weapon = env.safe_call(function()
            if tool_inst.find_first_child then return tool_inst:find_first_child("Weapon") end
            return tool_inst:FindFirstChild("Weapon")
        end)
        if weapon and env.is_valid(weapon) then
            scan_weapon_attachments_folder(find_attachments_folder(weapon), out, seen)
        end
        return
    end

    if not char then return end
    for _, child in ipairs(env.safe_call(function() return char:get_children() end) or {}) do
        if is_tool(child) or (child.ClassName or child.class_name) == "Model" then
            scan_weapon_attachments(char, child, out, seen)
        end
    end
end

local function scan_armor_tree(inst, out, seen, depth)
    if not inst or not env.is_valid(inst) or depth > 8 then return end

    local name = inst.Name or inst.name
    if name and name ~= "" then
        if name:sub(1, 6) == "Armor_" or name:sub(1, 6) == "Armor:" then
            try_armor_model(out, seen, name)
        end
    end

    local children = env.safe_call(function()
        if inst.get_children then return inst:get_children() end
        if inst.GetChildren then return inst:GetChildren() end
    end) or {}

    for _, child in ipairs(children) do
        scan_armor_tree(child, out, seen, depth + 1)
    end
end

function M.is_empty_held_name(name)
    return is_empty_held_name(name)
end

function M.held_name(player)
    if not player then return nil end
    local char = resolve_character(player)
    local name = select(1, resolve_held_weapon(player, char))
    if name and is_valid_held_label(name) then return name end
    return nil
end

function M.held_name_from_character(char)
    if not char or not env.is_valid(char) then return nil end
    local name = select(1, find_held_on_character(char))
    if name and is_valid_held_label(name) then return name end
    return nil
end

function M.scan_player(player)
    local out = {
        held = nil,
        attachments = {},
        armor = {},
    }

    if not player then return out end

    local char = resolve_character(player)
    local held_name, tool_inst = resolve_held_weapon(player, char)

    if held_name then
        add_held_piece(out, held_name)
    end

    local att_seen = {}
    scan_weapon_attachments(char, tool_inst, out, att_seen)

    local seen = {}
    if char then
        scan_armor_tree(char, out, seen, 0)
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
