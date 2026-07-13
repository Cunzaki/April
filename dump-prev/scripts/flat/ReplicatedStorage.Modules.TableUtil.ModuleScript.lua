-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_1 = {};
tbl_1.TableRandom = function(a1, a2, a3, a4)
    --[[
      name: TableRandom
      line: 12
    ]]
    a3 = a3 or 1;
    local v1 = 10 ^ (a4 or 2);
    local v2 = ((type(a2) == "number") and (a2 * a3)) or (math.random((a2[1] * a3) * v1, (a2[2] * a3) * v1) / v1);
    return v2;
end;
tbl_1.CloneTable = function(a1, a2, a3)
    --[[
      name: CloneTable
      line: 19
    ]]
    local tbl_2 = {};
    local v3 = nil;
    for key_1, value_1 in pairs(a2) do
        if (type(value_1) ~= "table" or a3) then
            v3 = value_1;
            tbl_2[key_1] = v3;
            continue;
        end;
        v3 = a1:CloneTable(value_1) or value_1;
        tbl_2[key_1] = v3;
    end;
    return tbl_2;
end;
tbl_1.RandomizeTable = function(a1, a2, a3)
    --[[
      name: RandomizeTable
      line: 27
    ]]
    local tbl_3 = {};
    local v4 = (a3 and a2) or (a1:CloneTable(a2));
    for _ = 1, #v4 do
        local v5 = math.random(1, #v4);
        table.insert(tbl_3, v4[v5]);
        table.remove(v4, v5);
    end;
    return tbl_3;
end;
tbl_1.CompareTables = function(a1, a2, a3)
    --[[
      name: CompareTables
      line: 38
    ]]
    if (#a2 == #a3) then
        for key_2, value_2 in pairs(a2) do
            if (value_2 == a3[key_2]) then
                continue;
            end;
            return false;
        end;
        return true;
    end;
    return false;
end;
return tbl_1;