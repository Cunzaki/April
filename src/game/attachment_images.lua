-- MeshId thumbnails from dump: ReplicatedStorage.Attachments (mesh_assets.tsv)
local M = {}

M.by_name = {
    ["Bruno's ACOG Sight"] = "15426865503",
    ["Compensator"] = "15347030703",
    ["Holo Sight"] = "14162017273",
    ["Military ACOG Sight"] = "15426865503",
    ["Military Lasersight"] = "15376726516",
    ["Military Sniper Scope"] = "14764545466",
    ["Muzzle Boost"] = "15347030553",
    ["Salvaged Lasersight"] = "15347030437",
    ["Salvaged Sight"] = "13816428922",
    ["Salvaged Sniper Scope"] = "14623616888",
    ["Silencer"] = "15347030257",
    ["Weapon Flashlight"] = "15360516663",
}

function M.get_asset_id(name)
    return name and M.by_name[name]
end

return M
