local env = April.require("core.env")
local item_images = April.require("game.item_images")
local item_catalog = April.require("game.item_catalog")
local asset_urls = April.require("game.asset_urls")

local M = {}
local loaded = false
local by_name = {}

local FALLBACK = {
    ["Wood Log"] = { Type = "Resource" },
    ["Bandage"] = { Type = "Tool" },
    ["Salvaged M14"] = { Type = "Tool" },
}

local NAME_ALIASES = {
    ["Cloth Head Wrap"] = "Cloth Headwrap",
}

local HELD_TYPES = {
    Gun = true,
    Tool = true,
    Bench = true,
}

local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then
        return base, variant
    end
    return name, nil
end

local function index_data(data)
    if data[1] and type(data[1]) == "table" then
        for _, entry in ipairs(data) do
            if entry.Name then by_name[entry.Name] = entry end
        end
    else
        for name, entry in pairs(data) do
            if type(entry) == "table" then
                entry.Name = entry.Name or name
                by_name[entry.Name] = entry
            end
        end
    end
end

function M.normalize_name(name)
    if not name then return nil end
    return NAME_ALIASES[name] or name
end

function M.load()
    if loaded then return true end

    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and type(data) == "table" then
                index_data(data)
                loaded = true
                return true
            end
        end
    end

    local module_scan = April.require("game.module_scan")
    local data = module_scan.find_items()
    if data then
        index_data(data)
        loaded = true
        return true
    end

    return false
end

function M.invalidate()
    loaded = false
    by_name = {}
end

function M.get(name)
    if not loaded then M.load() end
    return by_name[name] or FALLBACK[name]
end

function M.get_catalog(name)
    return item_catalog.get_by_name(M.normalize_name(name))
end

function M.get_type(name)
    local row = M.get_catalog(name)
    if row then return row.type end

    local item = M.get(name)
    return item and item.Type or "Unknown"
end

function M.is_held_display(name)
    if not name or name == "" then return false end

    local base = select(1, parse_variant_name(name))
    local row = M.get_catalog(base)
    if row and HELD_TYPES[row.type] then return true end

    local t = M.get_type(base)
    return HELD_TYPES[t] == true
end

local function rbx_id_from_image(img)
    if type(img) == "string" then
        return img:match("(%d+)")
    end
    if type(img) == "table" then
        local pick = img.Default or img.default
        if type(pick) == "string" then
            return pick:match("(%d+)")
        end
    end
    return nil
end

function M.get_by_id(id)
    if type(id) ~= "number" then return nil end
    if not loaded then M.load() end

    local cat = item_catalog.get(id)
    if cat and cat.name then
        local row = by_name[cat.name]
        if row then return row end
    end

    local rep = env.get_replicated_storage()
    if rep then
        local modules = env.safe_call(function() return rep:find_first_child("Modules") end)
        local items_mod = modules and env.safe_call(function() return modules:find_first_child("Items") end)
        if items_mod then
            local ok, data = pcall(function() return require(items_mod) end)
            if ok and data and data[id] then return data[id] end
        end
    end

    return nil
end

function M.get_image_asset_id(name, variant)
    if not name then return nil end

    name = M.normalize_name(name)

    local id = item_images.get_asset_id(name, variant)
    if id then return id end

    if variant and variant ~= "" and variant ~= "Default" then
        id = item_images.get_asset_id(name, "Default")
        if id then return id end
    end

    if not loaded then M.load() end
    local item = by_name[name]
    if not item or not item.Image then return nil end

    local img = item.Image
    if type(img) == "string" then
        return img:match("(%d+)")
    end
    if type(img) == "table" then
        if variant and img[variant] then
            return tostring(img[variant]):match("(%d+)")
        end
        return rbx_id_from_image(img)
    end
    return nil
end

function M.make_piece(name, variant)
    name = M.normalize_name(name)
    if not name or name == "" then return nil end
    return {
        name = name,
        variant = variant,
        asset_id = M.get_image_asset_id(name, variant),
    }
end

function M.resolve_armor_model(model_name)
    if not model_name then return nil end
    local item_name, variant = item_catalog.name_for_armor_model(model_name)
    if not item_name then return nil end
    return M.make_piece(item_name, variant)
end

function M.resolve_item_label(label)
    if not label or label == "" then return nil end

    local base, variant = parse_variant_name(label)
    base = M.normalize_name(base)

    local numeric = tonumber(base)
    if numeric then
        local row = item_catalog.get(numeric)
        if row then
            return M.make_piece(row.name, variant)
        end
    end

    if item_catalog.get_by_name(base) or item_images.get_asset_id(base, variant) then
        return M.make_piece(base, variant)
    end

    if not loaded then M.load() end
    if by_name[base] then
        return M.make_piece(base, variant)
    end

    return nil
end

function M.get_image_url(name, variant)
    local id = M.get_image_asset_id(name, variant)
    if id then return asset_urls.item_png(id) end
    return nil
end

return M
