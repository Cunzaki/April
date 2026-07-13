-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local CollectionService_upv_1 = game:GetService("CollectionService");
local tbl_upv_1 = {};
tbl_upv_1.ActiveBenches = {};
tbl_upv_1.SetServClientInfo = function(a1)
    --[[
      name: SetServClientInfo
      line: 31
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local ActiveBenches_1 = tbl_upv_1.ActiveBenches;
    local BenchTag_1 = a1.BenchTag;
    if (not BenchTag_1) then
        return;
    end;
    ActiveBenches_1[BenchTag_1] = a1.Info;
end;
tbl_upv_1.SetServClientInfos = function(a1)
    --[[
      name: SetServClientInfos
      line: 39
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    for _, value_1 in a1 do
        tbl_upv_1.SetServClientInfo(value_1);
    end;
end;
tbl_upv_1.GetClientInfo = function(a1)
    --[[
      name: GetClientInfo
      line: 46
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v1 = tbl_upv_1.GetModelTag(a1);
    if (v1) then
        return (tbl_upv_1.GetClientInfoFromTag(v1));
    end;
end;
tbl_upv_1.GetClientInfoFromTag = function(a1)
    --[[
      name: GetClientInfoFromTag
      line: 54
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    return tbl_upv_1.ActiveBenches[a1];
end;
tbl_upv_1.GetModelTag = function(a1)
    --[[
      name: GetModelTag
      line: 61
      upvalues:
        CollectionService_upv_1 (copy, index: 1)
    ]]
    for _, value_2 in CollectionService_upv_1:GetTags(a1) do
        if (#value_2 ~= 36) then
            continue;
        end;
        return value_2;
    end;
end;
tbl_upv_1.GetModelFromTag = function(a1)
    --[[
      name: GetModelFromTag
      line: 70
      upvalues:
        CollectionService_upv_1 (copy, index: 1)
    ]]
    return CollectionService_upv_1:GetTagged(a1)[1];
end;
tbl_upv_1.GetAllClientInfos = function()
    --[[
      name: GetAllClientInfos
      line: 76
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local tbl_2 = {};
    local v2 = nil;
    local key_1 = nil;
    local value_3 = nil;
    for key_1, value_3 in tbl_upv_1.ActiveBenches do
        v2 = value_3.Model;
        if (not (v2) or not (v2.Parent)) then
            v2 = tbl_upv_1.GetModelFromTag(key_1);
            value_3.Model = v2;
        end;
        if (not (v2)) then
            continue;
        end;
        if (v2.Parent) then
            tbl_2[v2] = value_3;
        end;
    end;
    return tbl_2;
end;
tbl_upv_1.GetAllRawClientInfos = function()
    --[[
      name: GetAllRawClientInfos
      line: 92
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    return tbl_upv_1.ActiveBenches;
end;
tbl_upv_1.RemoveClientInfo = function(a1)
    --[[
      name: RemoveClientInfo
      line: 97
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    tbl_upv_1.ActiveBenches[a1] = nil;
end;
return tbl_upv_1;