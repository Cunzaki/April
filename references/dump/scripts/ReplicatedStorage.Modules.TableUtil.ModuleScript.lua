-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

return {
    TableRandom = function(p1, p2, p3, p4) -- Line: 12, Name: TableRandom
        local v5 = p3 or 1;
        local v6 = 10 ^ (p4 or 2);

        return type(p2) == "number" and p2 * v5 or math.random(p2[1] * v5 * v6, p2[2] * v5 * v6) / v6;
    end,

    CloneTable = function(p7, p8, p9) -- Line: 19, Name: CloneTable
        local v10 = {};

        for i, v in pairs(p8) do
            if type(v) == "table" and not p9 then
                local v = p7:CloneTable(v) or v;
            end;

            v10[i] = v;
        end;

        return v10;
    end,

    RandomizeTable = function(p11, p12, p13) -- Line: 27, Name: RandomizeTable
        local v14 = p13 and p12 and p12 or p11:CloneTable(p12);
        local v15 = {};

        for _ = 1, #v14 do
            local v16 = math.random(1, #v14);
            table.insert(v15, v14[v16]);
            table.remove(v14, v16);
        end;

        return v15;
    end,

    CompareTables = function(p17, p18, p19) -- Line: 38, Name: CompareTables
        if #p18 ~= #p19 then
            return false;
        end;

        for i, v in pairs(p18) do
            if v ~= p19[i] then
                return false;
            end;
        end;

        return true;
    end
};