-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local u1 = {
    BCAccess = {
        Priority = 1
    },
    BCDenied = {
        Priority = 1
    },
    Safezone = {
        Priority = 2
    },
    Recipes = {
        Priority = 3
    },
    Craft = {
        Priority = 4
    },
    Decay = {
        Priority = 5
    },
    Bleed = {
        Priority = 6
    },
    Radiation = {
        Priority = 7,
        Max = 499
    },
    Wet = {
        Priority = 8
    },
    Temperature = {
        Priority = 9
    },
    Comfort = {
        Priority = 11
    },
    Drowning = {
        Priority = 12
    },
    Health_Buff = {
        Priority = 13
    },
    Node_Buff = {
        Priority = 14
    },
    Wood_Buff = {
        Priority = 15
    },
    Caps_Buff = {
        Priority = 16
    },
    Regen_Buff = {
        Priority = 17
    }
};
local u2 = {};
u2.__index = u2;

function u2.new() -- Line: 75
    -- upvalues: u2 (copy)
    local v3 = setmetatable({}, u2);
    v3.StatusEffects = {};
    v3.Pickups = {};

    return v3;
end;

function u2.GetStatusEffects(p4) -- Line: 85
    return p4.StatusEffects;
end;

function u2.GetPickups(p5) -- Line: 89
    return p5.Pickups;
end;

function u2.RemovePickup(p6, p7) -- Line: 93
    for i, v in pairs(p6:GetPickups()) do
        if v[1] == p7 then
            table.remove(p6:GetPickups(), i);
        end;
    end;
end;

function u2.GetPickupAmount(p8, p9) -- Line: 101
    for _, v in pairs(p8:GetPickups()) do
        if v[1] == p9 then
            return v[2];
        end;
    end;
end;

function u2.GetStatsPickupTableCombined(p10) -- Line: 109
    local v11 = {};

    for _, v in pairs(p10.StatusEffects) do
        if v[1] == "Temperature" and (v[2] < 5 or v[2] > 25) or (v[1] ~= "Temperature" and (v[2] and (typeof(v[2]) ~= "table" and (v[2] > 0 or v[2] == -1))) or typeof(v[2]) == "table" and (v[2][2] ~= nil and v[2][2] > 0)) then
            table.insert(v11, v);
        end;
    end;

    for _, v in pairs(p10.Pickups) do
        if v[2] and (v[2] > 0 or v[2] == -1) then
            table.insert(v11, v);
        end;
    end;

    return v11;
end;

function u2.GetIndexOfStat(p12, p13) -- Line: 131
    for i, v in pairs(p12:GetStatusEffects()) do
        if v[1] == p13 then
            return i;
        end;
    end;
end;

function u2.GetStatValueFromIndex(p14, p15) -- Line: 139
    local v16 = p14:GetStatusEffects();

    if v16[p15] == nil then
        return v16[p15][2];
    end;
end;

function u2.GetStatValueFromName(p17, p18) -- Line: 145
    if string.find(p18, "Pickup") or string.find(p18, "Drop") then
        for _, v in pairs(p17:GetPickups()) do
            if p18 == v[1] then
                return v[2];
            end;
        end;
    end;

    return p17:GetStatValueFromIndex(p17:GetIndexOfStat(p18));
end;

function u2.OrderStats(p19) -- Line: 156
    -- upvalues: u1 (copy)
    table.sort(p19.StatusEffects, function(p20, p21) -- Line: 157
        -- upvalues: u1 (ref)
        local v22 = u1[p20[1]];
        local v23 = u1[p21[1]];

        if v22 or v23 then
            return v22.Priority < v23.Priority;
        end;
    end);
end;

function u2.InsertStat(p24, p25, p26) -- Line: 167
    if not (string.find(p25, "Pickup") or string.find(p25, "Drop")) then
        if p24:GetIndexOfStat(p25) == nil then
            local v27 = #p24:GetStatusEffects();
            p24:GetStatusEffects()[v27 + 1] = { p25, p26, tick() };
        else
            p24:UpdateStat(p25, p26, tick());
        end;

        p24:OrderStats();

        return;
    end;

    local v28 = false;

    for _, v in pairs(p24.Pickups) do
        if v[1] == p25 then
            v[2] = v[2] + p26;
            v[3] = tick();
            v28 = true;
        end;
    end;

    if not v28 then
        local Pickups = p24.Pickups;
        local v29 = { p25, p26, tick() };
        table.insert(Pickups, v29);
    end;
end;

function u2.RemoveStat(p30, p31) -- Line: 195
    for i, v in pairs(p30:GetStatusEffects()) do
        if v[1] == p31 then
            table.remove(p30:GetStatusEffects(), i);
        end;
    end;

    p30:OrderStats();
end;

function u2.UpdateStat(p32, p33, p34) -- Line: 204
    -- upvalues: u1 (copy)
    for _, v in pairs(p32:GetStatusEffects()) do
        if v[1] == p33 then
            if u1.Max ~= nil then
                p34 = math.clamp(p34, 0, u1.Max);
            end;

            v[2] = p34;
            v[3] = tick();
        end;
    end;

    p32:OrderStats();
end;

function u2.CompareServerTable(p35, p36) -- Line: 218
    for i, v in pairs(p36) do
        if i ~= "HQueue" and (i ~= "Health" and (i ~= "Hunger" and i ~= "Thirst")) then
            local v37 = false;

            for i2, v2 in pairs(p35:GetStatusEffects()) do
                if v2[1] == i then
                    v37 = i2;
                    break;
                end;
            end;

            if v37 then
                p35:GetStatusEffects()[v37][2] = v;
            else
                p35:InsertStat(i, v);
            end;
        end;
    end;

    p35:OrderStats();
end;

return u2;