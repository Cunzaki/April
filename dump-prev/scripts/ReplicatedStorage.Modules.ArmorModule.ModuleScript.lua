-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_upv_1 = {};
tbl_upv_1.All = {"Helmet", "Face", "Hat", "Chestplate", "Wetsuit", "Shirt", "Kilt", "Pants", "Boots", "Gloves"};
tbl_upv_1.Helmet = {"Face", "Hat", "All"};
tbl_upv_1.Hat = {"Helmet", "All"};
tbl_upv_1.Face = {"Helmet", "All"};
tbl_upv_1.Chestplate = {"All"};
tbl_upv_1.Wetsuit = {"Shirt", "Pants", "All"};
tbl_upv_1.Shirt = {"All", "Wetsuit"};
tbl_upv_1.Kilt = {"All"};
tbl_upv_1.Pants = {"All", "Wetsuit"};
tbl_upv_1.Boots = {"All"};
tbl_upv_1.Gloves = {"All"};
local tbl_upv_2 = {};
tbl_upv_2["Steel Helmet"] = {["Phantom Rider"] = true};
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Players_1 = game:GetService("Players");
local _ = game:GetService("RunService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Armors_upv_1 = ReplicatedStorage_1:WaitForChild("Armors");
local Sleeves_upv_1 = ReplicatedStorage_1:WaitForChild("Sleeves");
local WeldModule_upv_1 = require(Modules_1:WaitForChild("WeldModule"));
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local tbl_3 = {};
tbl_3.UpdateArmors = function(a1, a2, a3, a4)
    --[[
      name: UpdateArmors
      line: 51
      upvalues:
        Items_upv_1 (copy, index: 1)
        LocalPlayer_upv_1 (copy, index: 2)
        Sleeves_upv_1 (copy, index: 3)
        tbl_upv_2 (copy, index: 4)
        Armors_upv_1 (copy, index: 5)
        WeldModule_upv_1 (copy, index: 6)
    ]]
    if (not a2) then
        return;
    end;
    if (a2.Parent) then
        local tbl_4 = {};
        local v1 = nil;
        local Name_1 = nil;
        local v2 = nil;
        local v3 = nil;
        local v4 = nil;
        for _, value_1 in pairs(a2:GetChildren()) do
            Name_1 = value_1.Name;
            if (not (value_1:IsA("Model")) or Name_1:sub(1, 6) ~= "Armor_") then
                continue;
            end;
            v2 = string.find(Name_1, "/");
            if (not (v2)) then
                continue;
            end;
            v3 = tonumber(Name_1:sub(7, v2 - 1));
            if (not (v3)) then
                continue;
            end;
            v4 = Name_1:sub(v2 + 1);
            v1 = tbl_4[v3];
            if (not (v1)) then
                local tbl_5 = {Skin = v4, Models = {}};
                tbl_4[v3] = tbl_5;
                v1 = tbl_5;
            end;
            table.insert(v1.Models, value_1);
        end;
        local v5 = false;
        local v6 = a1:GetArmors(a3);
        local v7 = v5;
        local Skin_1 = nil;
        local v8 = nil;
        local _ = nil;
        local v28 = nil;
        for v9, value_2 in pairs(tbl_4) do
            Skin_1 = value_2.Skin;
            v4 = false;
            for v29, v10 in pairs(v6) do
                if (v10.ID ~= v9) then
                    continue;
                end;
                if (v10.Skin == Skin_1) then
                    v10.Found = true;
                    v4 = true;
                    break;
                end;
            end;
            if (v4) then
                continue;
            end;
            v8 = true;
            for v30, value_3 in pairs(value_2.Models) do
                value_3:Destroy();
            end;
            v7 = v8;
        end;
        local v11 = false;
        local v12 = false;
        local tbl_6 = {};
        local v9 = {};
        local value_2 = false;
        local tbl_7 = {};
        local v4, v31, v13, v14, tbl_6, v3, v7 = nil, nil, nil, nil, nil, nil, nil;
        v13, v14, v3 = v11, v12, tbl_7;
        local Skin_2 = nil;
        local v15 = nil;
        local v16 = nil;
        local v17 = nil;
        local value_4 = nil;
        local v18 = nil;
        local v19 = nil;
        local v32 = nil;
        local v33 = nil;
        local v10 = nil;
        local v20 = nil;
        local v21 = nil;
        local v22 = nil;
        local v23 = nil;
        local v24 = nil;
        for v34, value_4 in pairs(v6) do
            Skin_2 = value_4.Skin;
            v20 = Items_upv_1[value_4.ID];
            if (not (v20)) then
                continue;
            end;
            v15 = v20.ArmorType;
            v16 = v20.Name;
            if (LocalPlayer_upv_1) then
                v21 = Sleeves_upv_1:FindFirstChild(v16);
                if (v21 and v21:FindFirstChild(Skin_2)) then
                    if (v15 == "Chestplate") then
                        for n_1 = #tbl_6, 1, -1 do
                            if (v9[n_1] == "Shirt") then
                                table.remove(tbl_6, n_1);
                                table.remove(v9, n_1);
                            end;
                        end;
                        value_2 = true;
                        table.insert(tbl_6, v16 .. "/" .. Skin_2);
                        table.insert(v9, v15);
                    elseif (v15 ~= "Shirt" or not (value_2)) then
                        table.insert(tbl_6, v16 .. "/" .. Skin_2);
                        table.insert(v9, v15);
                    end;
                end;
            end;
            v13 = ((v20.HideHair) and true) or v13;
            if (tbl_upv_2[v16]) then
                v14 = tbl_upv_2[v16][Skin_2] ~= nil;
            end;
            v17 = v20.Attribute;
            if (a4 and v17 and not (table.find(v3, v17))) then
                table.insert(v3, "Armor_" .. v17);
            end;
            v22 = value_4.Attachments;
            if (v22) then
                local v25 = nil;
                for v35, value_5 in v22 do
                    v23 = Items_upv_1[value_5.ID];
                    if (not (v23)) then
                        continue;
                    end;
                    v25 = v23.Attribute;
                    if (not (a4) or not (v25)) then
                        continue;
                    end;
                    if (not (table.find(v3, v25))) then
                        table.insert(v3, "Armor_" .. v25);
                    end;
                end;
            end;
            if (value_4.Found) then
                value_4.Found = nil;
                continue;
            end;
            v18 = true;
            v24 = Armors_upv_1:FindFirstChild(v16);
            if (not (v24)) then
                v7 = v18;
                continue;
            end;
            v19 = v24:FindFirstChild(Skin_2);
            if (not (v19)) then
                v7 = v18;
                continue;
            end;
            for v36, value_6 in pairs(WeldModule_upv_1:FullyWeldModels(v19:Clone(), a2, true)) do
                value_6.Name = "Armor_" .. v10 .. "/" .. Skin_2;
            end;
            v7 = v18;
        end;
        local v26 = nil;
        for v37, value_7 in pairs(a2:GetChildren()) do
            if (value_7.Name ~= "Hair" or not (value_7:IsA("Model"))) then
                continue;
            end;
            v26 = value_7:FindFirstChild("HairPart");
            if (v26) then
                v26.Transparency = (v13 and 1) or 0;
            end;
        end;
        local v27 = nil;
        if (a2.Name ~= "Rig") then
            v27 = a2:FindFirstChild("Head");
            if (v27) then
                v27.Transparency = (v14 and 0.99) or 0;
                for v38, value_8 in v27:GetChildren() do
                    if (value_8:IsA("Decal")) then
                        value_8.Transparency = (v14 and 1) or 0;
                    end;
                end;
            end;
        end;
        if (LocalPlayer_upv_1) then
            LocalPlayer_upv_1:SetAttribute("ArmorSleeves", table.concat(tbl_6, "^"));
        end;
        if (a4) then
            for key_1, value_9 in pairs(a4:GetAttributes()) do
                if (key_1:sub(1, 6) ~= "Armor_") then
                    continue;
                end;
                if (not (value_9)) then
                    a4:SetAttribute(key_1, nil);
                    continue;
                end;
                v10 = table.find(v3, key_1);
                if (v10) then
                    table.remove(v3, v10);
                else
                    a4:SetAttribute(key_1, nil);
                end;
            end;
            for v39, value_10 in pairs(v3) do
                a4:SetAttribute(value_10, true);
            end;
        end;
        return v7;
    end;
end;
tbl_3.GetArmors = function(a1, a2, a3, a4)
    --[[
      name: GetArmors
      line: 208
      upvalues:
        Items_upv_1 (copy, index: 1)
    ]]
    if (a2) then
        local tbl_8 = {};
        local tbl_9 = {};
        local v28 = nil;
        local v29 = nil;
        for key_2, value_11 in pairs(a2) do
            if (not (value_11) or value_11 == 0 or value_11.Amount <= 0) then
                continue;
            end;
            v29 = Items_upv_1[value_11.ID];
            if (v29 == nil) then
                continue;
            end;
            if (v29.MaxDurability) then
                local v30;
                if ((value_11.Durability or 0) <= 0) then
                    continue;
                end;
            end;
            local v30;
            v30 = v29.Resistances;
            local v31 = nil;
            if (a3) then
                if (not (v30)) then
                    continue;
                end;
                v31 = v30[a3];
                if (not (v31)) then
                    continue;
                end;
                v28 = false;
                v31 = ((type(v31) == "table") and v31) or {v31};
                for _, value_12 in pairs(v31) do
                    if (value_12 > 0) then
                        v28 = true;
                        break;
                    end;
                end;
                if (not (v28)) then
                    continue;
                end;
            end;
            v31 = v29.Attribute;
            if (not (a4)) then
                table.insert(tbl_8, value_11);
                table.insert(tbl_9, key_2);
                continue;
            end;
            if (v31 == nil) then
                continue;
            end;
            if (v31:find(a4)) then
                table.insert(tbl_8, value_11);
                table.insert(tbl_9, key_2);
            end;
        end;
        return tbl_8, tbl_9;
    end;
end;
tbl_3.GetArmorTypes = function(a1)
    --[[
      name: GetArmorTypes
      line: 237
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    return tbl_upv_1;
end;
return tbl_3;