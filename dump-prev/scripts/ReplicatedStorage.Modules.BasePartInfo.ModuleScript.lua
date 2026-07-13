-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_1 = {};
tbl_1.Fetch = function(a1)
    --[[
      name: Fetch
      line: 11
    ]]
    local tbl_2 = {};
    tbl_2[1] = {};
    tbl_2[2] = {};
    tbl_2[3] = {};
    tbl_2[4] = {};
    tbl_2[5] = {};
    tbl_2[6] = {};
    tbl_2[7] = {};
    tbl_2[8] = {};
    tbl_2[9] = {};
    tbl_2[10] = {};
    tbl_2[11] = {};
    tbl_2[12] = {};
    tbl_2[13] = {};
    tbl_2[14] = {};
    tbl_2[15] = {};
    tbl_2[16] = {};
    return tbl_2;
end;
local u1 = tbl_1:Fetch();
tbl_1.GetIndexFromName = function(a1, a2)
    --[[
      name: GetIndexFromName
      line: 81
      upvalues:
        u1 (copy, index: 1)
    ]]
    for key_1, value_1 in pairs(u1) do
        if (value_1.Name ~= a2) then
            continue;
        end;
        return key_1;
    end;
    return "";
end;
tbl_1.GetNameFromIndex = function(a1, a2)
    --[[
      name: GetNameFromIndex
      line: 89
      upvalues:
        u1 (copy, index: 1)
    ]]
    local v1 = u1[a2];
    return v1 and (v1.Name);
end;
return tbl_1;