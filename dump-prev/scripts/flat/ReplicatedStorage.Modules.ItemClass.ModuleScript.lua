-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Items_upv_1 = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Items"));
local tbl_upv_1 = {};
tbl_upv_1.__index = tbl_upv_1;
tbl_upv_1.new = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
    --[[
      name: new
      line: 22
      upvalues:
        tbl_upv_1 (copy, index: 1)
        Items_upv_1 (copy, index: 2)
    ]]
    local v1, v2 = nil, nil;
    if (type(a1) ~= "table") then
        local v3 = Items_upv_1[a1];
        local MaxDurability_1 = v3.MaxDurability;
        local num_1 = tonumber(a4);
        if (not (a10) and v3.SlotSize) then
            a10 = table.create(v3.SlotSize, 0);
        end;
        if (type(a6) == "table") then
            a6 = tbl_upv_1.new(a6);
        end;
        local v4 = a7 or (v3.Attachments and {});
        if (v4) then
            for key_1, value_1 in v4 do
                if (type(value_1) == "table") then
                    v4[key_1] = tbl_upv_1.new(value_1);
                end;
            end;
        end;
        if (a10) then
            for key_2, value_2 in a10 do
                if (type(value_2) == "table") then
                    a10[key_2] = tbl_upv_1.new(value_2);
                end;
            end;
        end;
        local tbl_2 = {};
        tbl_2.ID = a1;
        tbl_2.Amount = a2;
        tbl_2.Skin = a3 or "Default";
        local v5;
        if (type(a4) ~= "string") then
            v5 = a4 or (MaxDurability_1 or 0);
        else
            v5 = num_1 and MaxDurability_1 and MaxDurability_1 * num_1 or a4 or (MaxDurability_1 or 0);
        end;
        tbl_2.Durability = v5;
        tbl_2.Repair = a5 or 0;
        tbl_2.Ammo = a6;
        tbl_2.Attachments = v4;
        tbl_2.CookTimes = a8;
        tbl_2.Owner = a9;
        tbl_2.Container = a10;
        v1 = setmetatable(tbl_2, tbl_upv_1);
    else
        v1 = setmetatable(a1, tbl_upv_1);
        if (a2) then
            a2(v1);
        end;
        if (v1.Ammo) then
            if (a2) then
                a2(v1.Ammo);
            end;
            v1.Ammo = tbl_upv_1.new(v1.Ammo, a2);
        end;
        local tbl_3 = {};
        if (v1.Attachments) then
            for _, value_3 in pairs(v1.Attachments) do
                if (type(value_3) ~= "table") then
                    continue;
                end;
                if (a2) then
                    a2(value_3);
                end;
                table.insert(tbl_3, (tbl_upv_1.new(value_3, a2)));
            end;
            v1.Attachments = tbl_3;
        end;
        v2 = v1.Container;
        if (v2) then
            local v6 = table.create(Items_upv_1[a1.ID].SlotSize, 0);
            local v7 = nil;
            local key_3 = nil;
            local num_2 = nil;
            local v8 = nil;
            for key_3, value_4 in pairs(v2) do
                v7 = type(value_4) == "table";
                if (a2 and v7) then
                    a2(value_4);
                end;
                if (v7) then
                    value_4 = tbl_upv_1.new(value_4, a2);
                end;
                num_2 = tonumber(key_3);
                if (type(value_4) ~= "string") then
                    v8 = value_4;
                else
                    v8 = 0;
                end;
                v6[num_2] = v8;
            end;
            v1.Container = v6;
        end;
    end;
    return v1;
end;
tbl_upv_1.SetAmount = function(a1, a2)
    --[[
      name: SetAmount
      line: 106
    ]]
    a1.Amount = a2;
end;
tbl_upv_1.ChangeAmount = function(a1, a2, a3, a4, a5)
    --[[
      name: ChangeAmount
      line: 110
      upvalues:
        Items_upv_1 (copy, index: 1)
    ]]
    local MaxStack_1 = Items_upv_1[a1.ID].MaxStack;
    local v9 = a1.Amount + a2;
    local v10 = 0;
    local v11 = nil;
    if (a4) then
        v11 = math.huge;
    else
        local v12 = nil;
        if ((MaxStack_1 ~= 1 or a5) and a3) then
            v12 = a3;
            v11 = math.round(MaxStack_1 * v12);
            a1.Amount = math.clamp(v9, v10, v11);
            return;
        end;
        v12 = 1;
        v11 = math.round(MaxStack_1 * v12);
    end;
    a1.Amount = math.clamp(v9, v10, v11);
end;
tbl_upv_1.AddAttachment = function(a1, a2)
    --[[
      name: AddAttachment
      line: 115
    ]]
    table.insert(a1.Attachments, a2);
end;
tbl_upv_1.RemoveAttachment = function(a1, a2)
    --[[
      name: RemoveAttachment
      line: 119
    ]]
    local Attachments_1 = a1.Attachments;
    if (type(a2) ~= "table") then
        table.remove(Attachments_1, a2);
        return Attachments_1[a2];
    end;
    for key_4, value_5 in pairs(Attachments_1) do
        if (value_5 ~= a2) then
            continue;
        end;
        table.remove(Attachments_1, key_4);
        return;
    end;
end;
tbl_upv_1.GetComponents = function(a1, a2)
    --[[
      name: GetComponents
      line: 135
    ]]
    local tbl_4 = {a1.ID, a1.Amount, a1.Skin, a1.Durability, a1.Repair, a1.Ammo, a1.Attachments, a1.CookTimes, a1.Owner, a1.Container};
    return unpack(tbl_4, 1, a2 or (#tbl_4));
end;
tbl_upv_1.AttachmentStats = function(a1, a2)
    --[[
      name: AttachmentStats
      line: 140
      upvalues:
        Items_upv_1 (copy, index: 1)
    ]]
    local v13 = a1.Attachments or {};
    local tbl_5 = {};
    local v14 = nil;
    local v15 = nil;
    for _, value_6 in pairs(v13) do
        v14 = Items_upv_1[value_6.ID];
        if (v14 and v14.MaxDurability == nil) then
            local v16;
            v16 = v14.AttachmentStats;
            local v17;
            if (not (v16)) then
                continue;
            end;
            v17 = v16.AimForRecoilMult;
            if (v16.Toggle) then
                local v19, v20;
                if (not (value_6.On)) then
                    continue;
                end;
                for key_5, value_7 in pairs(v16) do
                    if (key_5 ~= "RecoilMult") then
                        local v18;
                        v18 = tbl_5[key_5];
                        if (not (v18) or not (v18) or not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                        tbl_5[key_5] = v15;
                    elseif (v17) then
                        local v18;
                        if (not (a2)) then
                            continue;
                        end;
                        v18 = tbl_5[key_5];
                        if (not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                        tbl_5[key_5] = v15;
                    else
                        local v18;
                        v18 = tbl_5[key_5];
                        if (not (v18) or not (v18) or not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                    end;
                end;
            else
                for key_5, value_7 in pairs(v16) do
                    if (key_5 == "RecoilMult" and v17) then
                        local v18;
                        if (not (a2)) then
                            continue;
                        end;
                        v18 = tbl_5[key_5];
                        if (not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                        tbl_5[key_5] = v15;
                    else
                        local v18;
                        v18 = tbl_5[key_5];
                        if (not (v18) or not (v18) or not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                    end;
                end;
            end;
        else
            local v16;
            if (value_6.Durability <= 0) then
                continue;
            end;
            v16 = v14.AttachmentStats;
            local v17;
            if (not (v16)) then
                continue;
            end;
            v17 = v16.AimForRecoilMult;
            if (v16.Toggle) then
                local v19, v20;
                if (not (value_6.On)) then
                    continue;
                end;
                for key_5, value_7 in pairs(v16) do
                    if (key_5 ~= "RecoilMult") then
                        local v18;
                        v18 = tbl_5[key_5];
                        if (not (v18) or not (v18) or not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                        tbl_5[key_5] = v15;
                    elseif (v17) then
                        local v18;
                        if (not (a2)) then
                            continue;
                        end;
                        v18 = tbl_5[key_5];
                        if (not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                        tbl_5[key_5] = v15;
                    else
                        local v18;
                        v18 = tbl_5[key_5];
                        if (not (v18) or not (v18) or not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                    end;
                end;
            else
                for key_5, value_7 in pairs(v16) do
                    if (key_5 == "RecoilMult" and v17) then
                        local v18;
                        if (not (a2)) then
                            continue;
                        end;
                        v18 = tbl_5[key_5];
                        if (not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                        tbl_5[key_5] = v15;
                    else
                        local v18;
                        v18 = tbl_5[key_5];
                        if (not (v18) or not (v18) or not (v18) or type(v18) ~= "number") then
                            v15 = value_7;
                            tbl_5[key_5] = v15;
                            continue;
                        end;
                        v15 = v18 + value_7 or value_7 or value_7 or value_7 or value_7;
                    end;
                end;
            end;
        end;
    end;
    return tbl_5;
end;
tbl_upv_1.HasAttachment = function(a1, a2)
    --[[
      name: HasAttachment
      line: 160
    ]]
    for _, value_8 in pairs(a1.Attachments or {}) do
        if (value_8.ID ~= a2) then
            continue;
        end;
        return value_8;
    end;
end;
tbl_upv_1.GetAttachments = function(a1)
    --[[
      name: GetAttachments
      line: 167
    ]]
    local tbl_6 = {};
    local v19 = nil;
    for _, value_9 in pairs(a1.Attachments or {}) do
        if (type(value_9) ~= "table" or value_9 == 0) then
            continue;
        end;
        v19 = value_9.ID;
        if (not (v19)) then
            continue;
        end;
        if (v19 ~= 0) then
            table.insert(tbl_6, v19);
        end;
    end;
    return tbl_6;
end;
tbl_upv_1.HasItems = function(a1)
    --[[
      name: HasItems
      line: 178
    ]]
    local Container_1 = a1.Container;
    if (Container_1) then
        for _, value_10 in Container_1 do
            if (type(value_10) ~= "table" or value_10.Amount <= 0) then
                continue;
            end;
            return true;
        end;
        return false;
    end;
end;
tbl_upv_1.IsToolbar = function(a1)
    --[[
      name: IsToolbar
      line: 187
      upvalues:
        Items_upv_1 (copy, index: 1)
    ]]
    local v20 = Items_upv_1[a1.ID];
    local v21 = true;
    if (v20.Type ~= "Gun") then
        local v22 = true;
        if (v20.Type == "Tool") then
            v21 = v22;
        else
            local v23 = true;
            if (v20.Type:find("Consumable") ~= nil) then
                v21 = v23;
            else
                local v24 = true;
                if (v20.Type == "Bench") then
                    v21 = v24;
                else
                    v21 = v20.Type == "Lock";
                end;
            end;
        end;
    end;
    return v21;
end;
return tbl_upv_1;