-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local u1 = {
    All = { "Helmet", "Face", "Hat", "Chestplate", "Wetsuit", "Shirt", "Kilt", "Pants", "Boots", "Gloves" },
    Helmet = { "Face", "Hat", "All" },
    Hat = { "Helmet", "All" },
    Face = { "Helmet", "All" },
    Chestplate = { "All" },
    Wetsuit = { "Shirt", "Pants", "All" },
    Shirt = { "All", "Wetsuit" },
    Kilt = { "All" },
    Pants = { "All", "Wetsuit" },
    Boots = { "All" },
    Gloves = { "All" }
};
local u2 = {
    ["Steel Helmet"] = {
        ["Phantom Rider"] = true
    }
};
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
game:GetService("RunService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Armors = ReplicatedStorage:WaitForChild("Armors");
local Sleeves = ReplicatedStorage:WaitForChild("Sleeves");
local WeldModule = require(Modules:WaitForChild("WeldModule"));
local Items = require(Modules:WaitForChild("Items"));
local LocalPlayer = Players.LocalPlayer;

return {
    UpdateArmors = function(p3, p4, p5, p6) -- Line: 51, Name: UpdateArmors
        -- upvalues: Items (copy), LocalPlayer (copy), Sleeves (copy), u2 (copy), Armors (copy), WeldModule (copy)
        if not (p4 and p4.Parent) then
            return;
        end;

        local v7 = {};

        for _, child in pairs(p4:GetChildren()) do
            local Name = child.Name;

            if child:IsA("Model") and Name:sub(1, 6) == "Armor_" then
                local v8 = string.find(Name, "/");

                if v8 then
                    local v9 = tonumber(Name:sub(7, v8 - 1));

                    if v9 then
                        local v10 = Name:sub(v8 + 1);
                        local v11 = v7[v9];

                        if not v11 then
                            v11 = {
                                Skin = v10,
                                Models = {}
                            };
                            v7[v9] = v11;
                        end;

                        table.insert(v11.Models, child);
                    end;
                end;
            end;
        end;

        local v12 = p3:GetArmors(p5);
        local v13 = false;

        for i, v in pairs(v7) do
            local Skin = v.Skin;
            local v14 = false;

            for _, v2 in pairs(v12) do
                if v2.ID == i and v2.Skin == Skin then
                    v2.Found = true;
                    v14 = true;
                    break;
                end;
            end;

            if not v14 then
                v13 = true;

                for _, v2 in pairs(v.Models) do
                    v2:Destroy();
                end;
            end;
        end;

        local v15 = {};
        local v16 = false;
        local v17 = {};
        local v18 = {};
        local v19 = false;
        local v20 = false;

        for _, v in pairs(v12) do
            local ID = v.ID;
            local Skin = v.Skin;
            local v21 = Items[ID];

            if v21 then
                local ArmorType = v21.ArmorType;
                local Name = v21.Name;
                local v22, v23, v24, v25, v26, v27, v28;

                if LocalPlayer then
                    local v29 = Sleeves:FindFirstChild(Name);

                    if not (v29 and v29:FindFirstChild(Skin)) then
                        v19 = v21.HideHair and true or v19;

                        if u2[Name] then
                            v20 = u2[Name][Skin] ~= nil;
                        end;

                        v22 = v21.Attribute;

                        if p6 and (v22 and not table.find(v15, v22)) then
                            table.insert(v15, "Armor_" .. v22);
                        end;

                        v23 = v.Attachments;

                        if v23 then
                            for _, v2 in v23 do
                                v24 = Items[v2.ID];

                                if v24 then
                                    v25 = v24.Attribute;

                                    if p6 and (v25 and not table.find(v15, v25)) then
                                        table.insert(v15, "Armor_" .. v25);
                                    end;
                                end;
                            end;
                        end;

                        if v.Found then
                            v.Found = nil;
                        else
                            v13 = true;
                            v26 = Armors:FindFirstChild(Name);

                            if v26 then
                                v27 = v26:FindFirstChild(Skin);

                                if v27 then
                                    v28 = WeldModule:FullyWeldModels(v27:Clone(), p4, true);

                                    for _, v2 in pairs(v28) do
                                        v2.Name = "Armor_" .. ID .. "/" .. Skin;
                                    end;
                                end;
                            end;
                        end;
                    end;

                    if ArmorType == "Chestplate" then
                        for i = #v17, 1, -1 do
                            if v18[i] == "Shirt" then
                                table.remove(v17, i);
                                table.remove(v18, i);
                            end;
                        end;

                        v16 = true;
                        table.insert(v17, Name .. "/" .. Skin);
                        table.insert(v18, ArmorType);
                    elseif ArmorType ~= "Shirt" or not v16 then
                        table.insert(v17, Name .. "/" .. Skin);
                        table.insert(v18, ArmorType);
                    end;
                end;

                v19 = v21.HideHair and true or v19;

                if u2[Name] then
                    v20 = u2[Name][Skin] ~= nil;
                end;

                v22 = v21.Attribute;

                if p6 and (v22 and not table.find(v15, v22)) then
                    table.insert(v15, "Armor_" .. v22);
                end;

                v23 = v.Attachments;

                if v23 then
                    for _, v2 in v23 do
                        v24 = Items[v2.ID];

                        if v24 then
                            v25 = v24.Attribute;

                            if p6 and (v25 and not table.find(v15, v25)) then
                                table.insert(v15, "Armor_" .. v25);
                            end;
                        end;
                    end;
                end;

                if v.Found then
                    v.Found = nil;
                else
                    v13 = true;
                    v26 = Armors:FindFirstChild(Name);

                    if v26 then
                        v27 = v26:FindFirstChild(Skin);

                        if v27 then
                            v28 = WeldModule:FullyWeldModels(v27:Clone(), p4, true);

                            for _, v2 in pairs(v28) do
                                v2.Name = "Armor_" .. ID .. "/" .. Skin;
                            end;
                        end;
                    end;
                end;
            end;
        end;

        for _, child in pairs(p4:GetChildren()) do
            if child.Name == "Hair" and child:IsA("Model") then
                local HairPart = child:FindFirstChild("HairPart");

                if HairPart then
                    HairPart.Transparency = v19 and 1 or 0;
                end;
            end;
        end;

        if p4.Name ~= "Rig" then
            local Head = p4:FindFirstChild("Head");

            if Head then
                Head.Transparency = v20 and 0.99 or 0;

                for _, child in Head:GetChildren() do
                    if child:IsA("Decal") then
                        child.Transparency = v20 and 1 or 0;
                    end;
                end;
            end;
        end;

        if LocalPlayer then
            LocalPlayer:SetAttribute("ArmorSleeves", table.concat(v17, "^"));
        end;

        if p6 then
            for i, v in pairs(p6:GetAttributes()) do
                if i:sub(1, 6) == "Armor_" then
                    local v30 = v and table.find(v15, i);

                    if v30 then
                        table.remove(v15, v30);
                    else
                        p6:SetAttribute(i, nil);
                    end;
                end;
            end;

            for _, v in pairs(v15) do
                p6:SetAttribute(v, true);
            end;
        end;

        return v13;
    end,

    GetArmors = function(p31, p32, p33, p34) -- Line: 208, Name: GetArmors
        -- upvalues: Items (copy)
        if not p32 then
            return;
        end;

        local v35 = {};
        local v36 = {};

        for i, v in pairs(p32) do
            if v and (v ~= 0 and v.Amount > 0) then
                local v37 = Items[v.ID];

                if v37 ~= nil and (not v37.MaxDurability or (v.Durability or 0) > 0) then
                    local Resistances = v37.Resistances;
                    local v38;

                    if p33 then
                        if Resistances then
                            local v39 = Resistances[p33];

                            if v39 then
                                local v40 = false;

                                for _, v2 in pairs(type(v39) == "table" and v39 and v39 or { v39 }) do
                                    if v2 > 0 then
                                        v40 = true;
                                        break;
                                    end;
                                end;

                                if v40 then
                                    v38 = v37.Attribute;

                                    if not p34 or v38 ~= nil and v38:find(p34) then
                                        table.insert(v35, v);
                                        table.insert(v36, i);
                                    end;
                                end;
                            end;
                        end;
                    else
                        v38 = v37.Attribute;

                        if not p34 or v38 ~= nil and v38:find(p34) then
                            table.insert(v35, v);
                            table.insert(v36, i);
                        end;
                    end;
                end;
            end;
        end;

        return v35, v36;
    end,

    GetArmorTypes = function(p41) -- Line: 237, Name: GetArmorTypes
        -- upvalues: u1 (copy)
        return u1;
    end
};