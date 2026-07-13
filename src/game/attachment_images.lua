-- Texture IDs from dump: ReplicatedStorage.Attachments (mesh_assets.tsv)
local M = {}

M.by_name = {
    ["Bruno's ACOG Sight"] = "15377519371",
    ["Compensator"] = "15347037651",
    ["Holo Sight"] = "14162081421",
    ["Military ACOG Sight"] = "15426936393",
    ["Military Lasersight"] = "15376730097",
    ["Military Sniper Scope"] = "14764547464",
    ["Muzzle Boost"] = "15347039048",
    ["Salvaged Lasersight"] = "15347036306",
    ["Salvaged Sight"] = "13816433453",
    ["Salvaged Sniper Scope"] = "14623628473",
    ["Silencer"] = "15347040421",
    ["Weapon Flashlight"] = "15360516663",
}

function M.get_asset_id(name)
    return name and M.by_name[name]
end

return M
