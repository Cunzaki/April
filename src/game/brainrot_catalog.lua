--[[ Brainrot character catalog — PNGs hosted on GitHub CDN. ]]

local asset_urls = April.require("game.asset_urls")

local M = {}

M.ENTRIES = {
    { file = "tung_tung_sahur", name = "Tung Tung Sahur" },
    { file = "tralalero_tralala", name = "Tralalero Tralala" },
    { file = "brr_brr_patapim", name = "Brr Brr Patapim" },
    { file = "orangutini", name = "Orangutini Ananasini" },
    { file = "cappuccino_assassino", name = "Cappuccino Assassino" },
    { file = "lirili_larila", name = "Lirili Larila" },
    { file = "boneca_ambalabu", name = "Boneca Ambalabu" },
    { file = "bombardiro_crocodilo", name = "Bombardiro Crocodilo" },
    { file = "chimpanzini", name = "Chimpanzini Bananini" },
    { file = "ta_ta_sahur", name = "Ta Ta Ta Sahur" },
    { file = "tung_head", name = "Tung Tung Head" },
    { file = "tung_clipart", name = "Tung Clipart" },
    { file = "trippi_troppi", name = "Trippi Troppi" },
    { file = "frigo_camelo", name = "Frigo Camelo" },
    { file = "ballerina_cappuccina", name = "Ballerina Cappuccina" },
    { file = "udin_din_din", name = "Udin Din Din Dun" },
}

function M.image_key(file)
    return "brainrot_" .. (file or "")
end

function M.url(file)
    return asset_urls.brainrot_png(file)
end

function M.combo_labels()
    local out = {}
    for _, entry in ipairs(M.ENTRIES) do
        out[#out + 1] = entry.name
    end
    return out
end

function M.entry_at_index(idx)
    return M.ENTRIES[(idx or 0) + 1]
end

return M
