-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local _ = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Items"));
local tbl_upv_1 = {};
local tbl_upv_2 = {};
local tbl_upv_3 = {"Weapons", "Tools", "Build", "Attire", "Ammo", "Resources", "Medical", "Other"};
local tbl_4 = {};
tbl_4.CalculateTotalCost = function(a1, a2, a3, a4, a5)
    --[[
      name: CalculateTotalCost
      line: 28
    ]]
    a3 = a3 or 1;
    local tbl_5 = {};
    local ID_1 = nil;
    local v1 = nil;
    for _, value_1 in pairs(a2.Costs or {}) do
        ID_1 = value_1.ID;
        if (a5) then
            local v2;
            if (table.find(a5, ID_1)) then
                continue;
            end;
        end;
        local v2;
        v2 = value_1.Amount;
        if (not (a4) or type(a4) == "table" and table.find(a4, ID_1)) then
            a1:CombineCost(tbl_5, ID_1, v2, a3);
            continue;
        end;
        v1 = a1:GetRecipesForItem(ID_1);
        if (#v1 <= 0) then
            a1:CombineCost(tbl_5, ID_1, v2, a3);
            continue;
        end;
        if (#v1 > 1) then
            warn("MULTIPLE RECIPES FOUND FOR ID OF " .. ID_1 .. "; DEFAULTING TO FIRST", v1[1]);
        end;
        for v3, value_2 in pairs(a1:CalculateTotalCost(v1[1], a3, a4, a5)) do
            a1:CombineCost(tbl_5, value_2.ID, value_2.Amount, 1);
        end;
    end;
    return tbl_5;
end;
tbl_4.GetCostDifferences = function(a1, a2, a3, a4, a5, a6, a7)
    --[[
      name: GetCostDifferences
      line: 58
    ]]
    a5 = a5 or 1;
    local v3;
    v3 = nil;
    local v4 = nil;
    for _, value_3 in pairs(a1:CalculateTotalCost(a2, a5, a6, a7)) do
        v4 = 1 / value_3.Amount;
        if (not (v3) or v3 >= v4) then
            v3 = v4;
        end;
    end;
    if (not (v3)) then
        error("RECIPE USED FOR REPAIRING RETURNED NO VALID COSTS", a2);
    end;
    local v5 = math.min(a3 + math.max(a4, v3), 1);
    local v6 = a1:CalculateTotalCost(a2, a3 * a5, a6, a7);
    local tbl_6 = {};
    local v7 = nil;
    local value_4 = nil;
    for _, value_4 in pairs(a1:CalculateTotalCost(a2, v5 * a5, a6, a7)) do
        v7 = 0;
        for v9, value_5 in pairs(v6) do
            if (value_5.ID == value_4.ID) then
                v7 = value_5.Amount;
                break;
            end;
        end;
        value_4 = nil;
        local v8 = value_4.Amount - v7;
        if (v8 > 0) then
            value_4.Amount = v8;
            table.insert(tbl_6, value_4);
        end;
    end;
    return tbl_6, v5 - a3;
end;
tbl_4.CombineCost = function(a1, a2, a3, a4, a5)
    --[[
      name: CombineCost
      line: 94
    ]]
    local v9 = {};
    local v10 = false;
    for _, value_6 in pairs(a2) do
        if (value_6.ID == a3) then
            v9, v10 = value_6, true;
            break;
        end;
    end;
    local v11 = (v9.Amount or 0) + a4 * a5;
    if (v11 > 0) then
        v9.ID = a3;
        v9.Amount = v11;
        if (not (v10)) then
            table.insert(a2, v9);
        end;
        return v9;
    end;
end;
tbl_4.GetRecipesForItem = function(a1, a2)
    --[[
      name: GetRecipesForItem
      line: 115
      upvalues:
        tbl_upv_2 (ref,  index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    local v12 = tbl_upv_2[a2];
    if (v12) then
        return v12;
    else
        local tbl_7 = {};
        for _, value_7 in pairs(tbl_upv_1) do
            for v13, value_8 in pairs(value_7.Recipes) do
                if (value_8.ID == a2) then
                    value_8.Category = value_7.Type;
                    table.insert(tbl_7, value_8);
                end;
            end;
        end;
        tbl_upv_2[a2] = tbl_7;
        return tbl_7;
    end;
end;
tbl_4.FetchRecipe = function(a1, a2, a3)
    --[[
      name: FetchRecipe
      line: 132
    ]]
    local v13 = a1:FetchRecipeList(a2);
    if (v13) then
        return a1:FindRecipe(v13, a3);
    end;
end;
tbl_4.FetchRecipeList = function(a1, a2)
    --[[
      name: FetchRecipeList
      line: 138
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    for _, value_9 in pairs(tbl_upv_1) do
        if (value_9.Type ~= a2) then
            continue;
        end;
        return value_9.Recipes;
    end;
end;
tbl_4.FindRecipe = function(a1, a2, a3)
    --[[
      name: FindRecipe
      line: 145
    ]]
    for _, value_10 in pairs(a2) do
        if (value_10.ID ~= a3) then
            continue;
        end;
        return value_10;
    end;
end;
tbl_4.RefreshCache = function(a1)
    --[[
      name: RefreshCache
      line: 152
      upvalues:
        tbl_upv_2 (ref, index: 1)
    ]]
    tbl_upv_2 = {};
end;
tbl_4.GetAllRecipes = function(a1)
    --[[
      name: GetAllRecipes
      line: 156
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    return tbl_upv_1;
end;
tbl_4.GetCraftingCategories = function(a1)
    --[[
      name: GetCraftingCategories
      line: 160
      upvalues:
        tbl_upv_3 (copy, index: 1)
    ]]
    return tbl_upv_3;
end;
for v1, value_11 in pairs(script:GetChildren()) do
    for v2, value_12 in pairs(require(value_11)) do
        table.insert(tbl_upv_1, value_12);
    end;
end;
return tbl_4;