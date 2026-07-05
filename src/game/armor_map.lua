--[[ Armor model names on character -> Items module display names (legacy ARMOR_MAP). ]]

local M = {}

M.BY_MODEL = {
    ["Armor_153"] = "Cloth Headwrap",
    ["Armor_115"] = "Cloth Shirt",
    ["Armor_116"] = "Cloth Pants",
    ["Armor_156"] = "Cloth Handwraps",
    ["Armor_117"] = "Cloth Footwraps",
    ["Armor_124"] = "Wooden Chestplate",
    ["Armor_125"] = "Wooden Leggings",
    ["Armor_123"] = "Wooden Helmet",
    ["Armor_145"] = "Salvaged Helmet",
    ["Armor_146"] = "Salvaged Chestplate",
    ["Armor_147"] = "Salvaged Leggings",
    ["Armor_155"] = "Salvaged Gloves",
    ["Armor_148"] = "Military Helmet",
    ["Armor_149"] = "Military Chestplate",
    ["Armor_150"] = "Military Leggings",
    ["Armor_157"] = "Military Gloves",
    ["Armor_271"] = "Altyn Helmet",
    ["Armor_272"] = "Boris Chestplate",
    ["Armor_141"] = "Steel Helmet",
    ["Armor_142"] = "Steel Chestplate",
    ["Armor_143"] = "Steel Leggings",
    ["Armor_158"] = "Leather Gloves",
    ["Armor_113"] = "Shorts",
    ["Armor_59"] = "Hoodie",
    ["Armor_63"] = "Pants",
    ["Armor_60"] = "Hazmat Suit",
    ["Armor_111"] = "Boots",
    ["Armor_121"] = "Boots",
    ["Armor_112"] = "Collared Shirt",
    ["Armor_122"] = "Flannel Jacket",
    ["Armor_114"] = "Tank Top",
    ["Armor_159"] = "Wetsuit",
    ["Armor_154"] = "Baseball Cap",
    ["Armor_152"] = "Balaclava",
    ["Armor_223"] = "Bruno's Helmet",
    ["Armor_222"] = "Bruno's Chestplate",
    ["Armor_298"] = "Bone Armor",
    ["Armor_308"] = "Military Backpack",
    ["Armor_309"] = "Salvaged Backpack",
}

function M.item_name(model_key)
    return model_key and M.BY_MODEL[model_key]
end

return M
