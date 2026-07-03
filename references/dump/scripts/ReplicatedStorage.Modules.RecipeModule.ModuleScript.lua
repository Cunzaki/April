-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules");
require(Modules:WaitForChild("Items"));
local u1 = {};
local u2 = {};
local u3 = { "Weapons", "Tools", "Build", "Attire", "Ammo", "Resources", "Medical", "Other" };
local v55 = {
    CalculateTotalCost = function(p4, p5, p6, p7, p8) -- Line: 28, Name: CalculateTotalCost
        local v9 = p6 or 1;
        local v10 = {};

        for _, v in pairs(p5.Costs or {}) do
            local ID = v.ID;

            if not (p8 and table.find(p8, ID)) then
                local Amount = v.Amount;

                if p7 and (type(p7) ~= "table" or not table.find(p7, ID)) then
                    local v11 = p4:GetRecipesForItem(ID);

                    if #v11 > 0 then
                        if #v11 > 1 then
                            warn("MULTIPLE RECIPES FOUND FOR ID OF " .. ID .. "; DEFAULTING TO FIRST", v11[1]);
                        end;

                        local v12 = p4:CalculateTotalCost(v11[1], v9, p7, p8);

                        for _, v2 in pairs(v12) do
                            p4:CombineCost(v10, v2.ID, v2.Amount, 1);
                        end;
                    else
                        p4:CombineCost(v10, ID, Amount, v9);
                    end;
                else
                    p4:CombineCost(v10, ID, Amount, v9);
                end;
            end;
        end;

        return v10;
    end,

    GetCostDifferences = function(p13, p14, p15, p16, p17, p18, p19) -- Line: 58, Name: GetCostDifferences
        local v20 = p17 or 1;
        local v21 = p13:CalculateTotalCost(p14, v20, p18, p19);
        local v22 = nil;

        for _, v in pairs(v21) do
            local v23 = 1 / v.Amount;

            if not v22 or v22 >= v23 then
                v22 = v23;
            end;
        end;

        if not v22 then
            error("RECIPE USED FOR REPAIRING RETURNED NO VALID COSTS", p14);
        end;

        local v24 = p15 + math.max(p16, v22);
        local v25 = math.min(v24, 1);
        local v26 = p13:CalculateTotalCost(p14, p15 * v20, p18, p19);
        local v27 = p13:CalculateTotalCost(p14, v25 * v20, p18, p19);
        local v28 = {};

        for _, v in pairs(v27) do
            local v29 = 0;

            for _, v2 in pairs(v26) do
                if v2.ID == v.ID then
                    v29 = v2.Amount;
                    break;
                end;
            end;

            local v30 = v.Amount - v29;

            if v30 > 0 then
                v.Amount = v30;
                table.insert(v28, v);
            end;
        end;

        return v28, v25 - p15;
    end,

    CombineCost = function(p31, p32, p33, p34, p35) -- Line: 94, Name: CombineCost
        local v36 = {};
        local v37 = false;

        for _, v in pairs(p32) do
            if v.ID == p33 then
                v36 = v;
                v37 = true;
                break;
            end;
        end;

        local v38 = (v36.Amount or 0) + p34 * p35;

        if v38 > 0 then
            v36.ID = p33;
            v36.Amount = v38;

            if not v37 then
                table.insert(p32, v36);
            end;

            return v36;
        end;
    end,

    GetRecipesForItem = function(p39, p40) -- Line: 115, Name: GetRecipesForItem
        -- upvalues: u2 (ref), u1 (copy)
        local v41 = u2[p40];

        if v41 then
            return v41;
        end;

        local v42 = {};

        for _, v in pairs(u1) do
            for _, v2 in pairs(v.Recipes) do
                if v2.ID == p40 then
                    v2.Category = v.Type;
                    table.insert(v42, v2);
                end;
            end;
        end;

        u2[p40] = v42;

        return v42;
    end,

    FetchRecipe = function(p43, p44, p45) -- Line: 132, Name: FetchRecipe
        local v46 = p43:FetchRecipeList(p44);

        if v46 then
            return p43:FindRecipe(v46, p45);
        end;
    end,

    FetchRecipeList = function(p47, p48) -- Line: 138, Name: FetchRecipeList
        -- upvalues: u1 (copy)
        for _, v in pairs(u1) do
            if v.Type == p48 then
                return v.Recipes;
            end;
        end;
    end,

    FindRecipe = function(p49, p50, p51) -- Line: 145, Name: FindRecipe
        for _, v in pairs(p50) do
            if v.ID == p51 then
                return v;
            end;
        end;
    end,

    RefreshCache = function(p52) -- Line: 152, Name: RefreshCache
        -- upvalues: u2 (ref)
        u2 = {};
    end,

    GetAllRecipes = function(p53) -- Line: 156, Name: GetAllRecipes
        -- upvalues: u1 (copy)
        return u1;
    end,

    GetCraftingCategories = function(p54) -- Line: 160, Name: GetCraftingCategories
        -- upvalues: u3 (copy)
        return u3;
    end
};

for _, child in pairs(script:GetChildren()) do
    for _, v in pairs(require(child)) do
        table.insert(u1, v);
    end;
end;

return v55;