local env = April.require("core.env")
local armor_map = April.require("game.armor_map")
local items = April.require("game.items")
local weapons = April.require("game.weapons")

local M = {}

local function parse_armor_child(name)
    if not name or not name:find("Armor_", 1, true) then return nil end
    local model_key, variant = name:match("^(Armor_%d+)[%/]?(%w*)")
    if not model_key then
        model_key = name:match("^(Armor_%d+)")
    end
    if variant == "" then variant = nil end
    return model_key, variant
end

function M.scan_player(player)
    local out = {
        held = nil,
        armor = {},
    }

    if not player then return out end

    if player.tool_name and player.tool_name ~= "" then
        out.held = player.tool_name
    end

    local char = player.character
    if not char or not env.is_valid(char) then return out end

    local children = env.safe_call(function() return char:get_children() end) or {}
    local seen = {}

    for _, child in ipairs(children) do
        if not env.is_valid(child) then goto continue end
        local name = child.Name or child.name
        if not name then goto continue end

        if not out.held and weapons.is_weapon_name(name) then
            out.held = name
        end

        local model_key, variant = parse_armor_child(name)
        if model_key then
            local item_name = armor_map.item_name(model_key)
            if item_name and not seen[item_name] then
                seen[item_name] = true
                local asset_id = items.get_image_asset_id(item_name, variant)
                table.insert(out.armor, {
                    name = item_name,
                    variant = variant,
                    asset_id = asset_id,
                    model_key = model_key,
                })
            end
        end

        ::continue::
    end

    return out
end

return M
