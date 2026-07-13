-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_upv_1 = {};
tbl_upv_1.BCAccess = {};
tbl_upv_1.BCDenied = {};
tbl_upv_1.Safezone = {};
tbl_upv_1.Recipes = {};
tbl_upv_1.Craft = {};
tbl_upv_1.Decay = {};
tbl_upv_1.Bleed = {};
tbl_upv_1.Radiation = {};
tbl_upv_1.Wet = {};
tbl_upv_1.Temperature = {};
tbl_upv_1.Comfort = {};
tbl_upv_1.Drowning = {};
tbl_upv_1.Health_Buff = {};
tbl_upv_1.Node_Buff = {};
tbl_upv_1.Wood_Buff = {};
tbl_upv_1.Caps_Buff = {};
tbl_upv_1.Regen_Buff = {};
local tbl_upv_2 = {};
tbl_upv_2.__index = tbl_upv_2;
tbl_upv_2.new = function()
    --[[
      name: new
      line: 75
      upvalues:
        tbl_upv_2 (copy, index: 1)
    ]]
    local v1 = setmetatable({}, tbl_upv_2);
    v1.StatusEffects = {};
    v1.Pickups = {};
    return v1;
end;
tbl_upv_2.GetStatusEffects = function(a1)
    --[[
      name: GetStatusEffects
      line: 85
    ]]
    return a1.StatusEffects;
end;
tbl_upv_2.GetPickups = function(a1)
    --[[
      name: GetPickups
      line: 89
    ]]
    return a1.Pickups;
end;
tbl_upv_2.RemovePickup = function(a1, a2)
    --[[
      name: RemovePickup
      line: 93
    ]]
    for key_1, value_1 in pairs(a1:GetPickups()) do
        if (value_1[1] == a2) then
            table.remove(a1:GetPickups(), key_1);
        end;
    end;
end;
tbl_upv_2.GetPickupAmount = function(a1, a2)
    --[[
      name: GetPickupAmount
      line: 101
    ]]
    for _, value_2 in pairs(a1:GetPickups()) do
        if (value_2[1] ~= a2) then
            continue;
        end;
        return value_2[2];
    end;
end;
tbl_upv_2.GetStatsPickupTableCombined = function(a1)
    --[[
      name: GetStatsPickupTableCombined
      line: 109
    ]]
    local tbl_3 = {};
    tbl_3.Health_Buff = true;
    tbl_3.Node_Buff = true;
    tbl_3.Wood_Buff = true;
    tbl_3.Caps_Buff = true;
    tbl_3.Regen_Buff = true;
    local tbl_4 = {};
    local v1;
    for v2, value_3 in pairs(a1.StatusEffects) do
        if (value_3[1] ~= "Temperature" or value_3[2] >= 5 and value_3[2] <= 25) then
            if (value_3[1] ~= "Temperature" and value_3[2]) then
                if (typeof(value_3[2]) == "table" or value_3[2] <= 0 and value_3[2] ~= -1) then
                    if (typeof(value_3[2]) ~= "table" or value_3[2][2] == nil) then
                        continue;
                    end;
                    if (value_3[2][2] > 0) then
                        table.insert(tbl_4, value_3);
                        continue;
                    end;
                end;
                table.insert(tbl_4, value_3);
                continue;
            else
                if (typeof(value_3[2]) ~= "table" or value_3[2][2] == nil or value_3[2][2] == nil) then
                    continue;
                end;
                if (value_3[2][2] > 0) then
                    table.insert(tbl_4, value_3);
                    continue;
                end;
            end;
            continue;
        end;
        table.insert(tbl_4, value_3);
    end;
    for v3, value_4 in pairs(a1.Pickups) do
        if (not (value_4[2])) then
            continue;
        end;
        if (value_4[2] > 0 or value_4[2] == -1) then
            table.insert(tbl_4, value_4);
        end;
    end;
    return tbl_4;
end;
tbl_upv_2.GetIndexOfStat = function(a1, a2)
    --[[
      name: GetIndexOfStat
      line: 131
    ]]
    for key_2, value_5 in pairs(a1:GetStatusEffects()) do
        if (value_5[1] ~= a2) then
            continue;
        end;
        return key_2;
    end;
end;
tbl_upv_2.GetStatValueFromIndex = function(a1, a2)
    --[[
      name: GetStatValueFromIndex
      line: 139
    ]]
    local v2 = a1:GetStatusEffects();
    if (v2[a2] == nil) then
        return v2[a2][2];
    end;
end;
tbl_upv_2.GetStatValueFromName = function(a1, a2)
    --[[
      name: GetStatValueFromName
      line: 145
    ]]
    if (not (string.find(a2, "Pickup")) and not (string.find(a2, "Drop"))) then
        return a1:GetStatValueFromIndex(a1:GetIndexOfStat(a2));
    end;
    for _, value_6 in pairs(a1:GetPickups()) do
        if (a2 ~= value_6[1]) then
            continue;
        end;
        return value_6[2];
    end;
    return a1:GetStatValueFromIndex(a1:GetIndexOfStat(a2));
end;
tbl_upv_2.OrderStats = function(a1)
    --[[
      name: OrderStats
      line: 156
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    table.sort(
        a1.StatusEffects,
        function(a2, a3)
            --[[
              line: 157
              upvalues:
                tbl_upv_1 (copy, index: 1)
            ]]
            local v3 = tbl_upv_1[a2[1]];
            local v4 = tbl_upv_1[a3[1]];
            if ((v3) or (v4)) then
                return v3.Priority < v4.Priority;
            end;
        end
    );
end;
tbl_upv_2.InsertStat = function(a1, a2, a3)
    --[[
      name: InsertStat
      line: 167
    ]]
    if (not (string.find(a2, "Pickup")) and not (string.find(a2, "Drop"))) then
        if (a1:GetIndexOfStat(a2) == nil) then
            local v5 = #a1:GetStatusEffects();
            local v6 = a1:GetStatusEffects();
            v6[v5 + 1] = {a2, a3, tick()};
        else
            a1:UpdateStat(a2, a3, tick());
        end;
        a1:OrderStats();
        return;
    end;
    local v7 = false;
    for _, value_7 in pairs(a1.Pickups) do
        if (value_7[1] == a2) then
            local v8 = true;
            value_7[2] = value_7[2] + a3;
            value_7[3] = tick();
            v7 = v8;
        end;
    end;
    if ((v7)) then
        return;
    end;
    table.insert(a1.Pickups, {a2, a3, tick()});
end;
tbl_upv_2.RemoveStat = function(a1, a2)
    --[[
      name: RemoveStat
      line: 195
    ]]
    for key_3, value_8 in pairs(a1:GetStatusEffects()) do
        if (value_8[1] == a2) then
            table.remove(a1:GetStatusEffects(), key_3);
        end;
    end;
    a1:OrderStats();
end;
tbl_upv_2.UpdateStat = function(a1, a2, a3)
    --[[
      name: UpdateStat
      line: 204
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    for _, value_9 in pairs(a1:GetStatusEffects()) do
        if (value_9[1] ~= a2) then
            continue;
        end;
        if (tbl_upv_1.Max ~= nil) then
            a3 = math.clamp(a3, 0, tbl_upv_1.Max);
        end;
        value_9[2] = a3;
        value_9[3] = tick();
    end;
    a1:OrderStats();
end;
tbl_upv_2.CompareServerTable = function(a1, a2)
    --[[
      name: CompareServerTable
      line: 218
    ]]
    local v9 = nil;
    local _ = nil;
    local v10 = nil;
    for key_4, value_10 in pairs(a2) do
        if (key_4 == "HQueue" or key_4 == "Health" or key_4 == "Hunger" or key_4 == "Thirst") then
            continue;
        end;
        v9 = false;
        for key_5, value_11 in pairs(a1:GetStatusEffects()) do
            if (value_11[1] == key_4) then
                v9 = key_5;
                break;
            end;
        end;
        if (v9) then
            a1:GetStatusEffects()[v9][2] = value_10;
        else
            a1:InsertStat(key_4, value_10);
        end;
    end;
    a1:OrderStats();
end;
return tbl_upv_2;