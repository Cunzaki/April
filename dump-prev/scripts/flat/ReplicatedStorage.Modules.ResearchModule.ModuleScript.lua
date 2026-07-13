-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_upv_1 = {};
tbl_upv_1[1] = {Tiers = {[1] = {}, [2] = {{}, {}}, [3] = {{}}, [4] = {{}, {}}, [5] = {{}, {}, {}}, [6] = {{}, {}, {}}, [7] = {{}, {}}, [8] = {{}, {}}, [9] = {{}, {}}}, Unlocks = {}};
tbl_upv_1[2] = {Tiers = {[1] = {}, [2] = {{}, {}}, [3] = {{}, {}}, [4] = {{}, {}}, [5] = {{}, {}}, [6] = {{}, {}}, [7] = {{}}}, Unlocks = {}};
tbl_upv_1[3] = {Tiers = {[1] = {}, [2] = {{}, {}}, [3] = {{}, {}}, [4] = {{}, {}}, [5] = {{}, {}}, [6] = {{}, {}, {}}, [7] = {{}, {}}}, Unlocks = {}};
tbl_upv_1[4] = {Tiers = {[1] = {}, [2] = {{}, {}}, [3] = {{}, {}}, [4] = {{}, {}}, [5] = {{}, {}}, [6] = {{}}}, Unlocks = {}};
tbl_upv_1[5] = {Tiers = {[1] = {}, [2] = {{}, {}}, [3] = {{}, {}}, [4] = {{}, {}, {}}, [5] = {{}}}, Unlocks = {}};
tbl_upv_1[6] = {Tiers = {[1] = {}, [2] = {{}}, [3] = {{}, {}}, [4] = {{}, {}}, [5] = {{}, {}}, [6] = {{}, {}}}, Unlocks = {}};
local tbl_upv_2 = {};
local RecipeModule_upv_1 = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RecipeModule"));
local tbl_3 = {};
tbl_3.GetInfoFromName = function(a1, a2)
    --[[
      name: GetInfoFromName
      line: 403
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    for key_1, value_1 in pairs(tbl_upv_1) do
        if (value_1.Name ~= a2) then
            continue;
        end;
        return value_1, key_1;
    end;
end;
tbl_3.GetInfoFromIndex = function(a1, a2)
    --[[
      name: GetInfoFromIndex
      line: 410
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    return tbl_upv_1[a2];
end;
tbl_3.CalculateUnlocks = function(a1)
    --[[
      name: CalculateUnlocks
      line: 414
      upvalues:
        RecipeModule_upv_1 (copy, index: 1)
        tbl_upv_2 (copy, index: 2)
    ]]
    local v1 = nil;
    local v2 = nil;
    local v3 = nil;
    local v4 = nil;
    local v5 = nil;
    local value_2 = nil;
    local v6 = nil;
    for _, value_3 in pairs(RecipeModule_upv_1:GetCraftingCategories()) do
        v1 = RecipeModule_upv_1:FetchRecipeList(value_3) or {};
        v3 = nil;
        v4 = nil;
        v5 = nil;
        value_2 = nil;
        for v7, value_2 in pairs(v1) do
            v6 = value_2.BenchNeeded;
            if (not (v6)) then
                continue;
            end;
            tbl_upv_2[v6] = true;
            v3 = value_2.TierNeeded;
            v4 = a1:GetInfoFromName(v6);
            if (not (v4)) then
                continue;
            end;
            v5 = v4.Unlocks;
            v2 = v5[v3];
            if (not (v2)) then
                v2 = {};
                v5[v3] = v2;
            end;
            if (not (table.find(v2, value_2))) then
                table.insert(v2, value_2);
            end;
        end;
    end;
end;
tbl_3.CalculateCraftTime = function(a1, a2, a3, a4)
    --[[
      name: CalculateCraftTime
      line: 439
    ]]
    local v7 = ((a3 < a2) and (0.75 - 0.5 / math.max(a4 - 1, 1) * math.max((a2 - a3) - 1, 0))) or 1;
    return v7;
end;
tbl_3.DebugGetCosts = function(a1)
    --[[
      name: DebugGetCosts
      line: 443
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v8 = 0;
    local tbl_4 = {};
    local _ = nil;
    local v9 = nil;
    for v10, value_4 in pairs(tbl_upv_1) do
        tbl_4[value_4.Name] = 0;
        _ = nil;
        for v11, value_5 in pairs(value_4.Tiers) do
            for v12, value_6 in pairs(value_5) do
                if (value_6.ID == 6) then
                    local Name_1 = value_4.Name;
                    tbl_4[Name_1] = tbl_4[Name_1] + value_6.Amount;
                    v8 = v8 + value_6.Amount;
                end;
            end;
        end;
    end;
    print(("TOTAL BOTTLE CAP COST OF %*"):format(v8), tbl_4);
end;
tbl_3.FetchResearchInfos = function(a1)
    --[[
      name: FetchResearchInfos
      line: 459
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    return tbl_upv_1;
end;
tbl_3.FetchAllWorkbenches = function(a1)
    --[[
      name: FetchAllWorkbenches
      line: 463
      upvalues:
        tbl_upv_2 (copy, index: 1)
    ]]
    return tbl_upv_2;
end;
tbl_3:CalculateUnlocks();
return tbl_3;