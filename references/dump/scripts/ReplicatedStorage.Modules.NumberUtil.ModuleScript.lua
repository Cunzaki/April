-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local v5 = {
    Lerp = function(p1, p2, p3, p4) -- Line: 12, Name: Lerp
        return p2 * (1 - p4) + p3 * p4;
    end
};
local u6 = { { 604800, "Weeks" }, { 86400, "Days" }, { 3600, "Hours" }, { 60, "Minutes" }, { 1, "Seconds" } };

function v5.FormatTime(p7, p8, p9, p10, p11, p12) -- Line: 23
    -- upvalues: u6 (copy)
    local v13 = {};
    local v14 = 0;
    local v15 = false;
    local v16 = false;

    for i, v in pairs(u6) do
        if v[2] == p9 or v16 then
            local v17 = math.floor(p8 / v[1]);
            local v18 = u6[i - 1];
            v15 = v18 and v18[2] == p10 and true or v15;

            if not v15 then
                local v19 = {
                    Formatted = (v17 <= 9 and v16 and "0" or "") .. v17 .. (p11 and (v[2]:sub(1, 1):lower() or ":") or ":"),
                    Raw = v17
                };
                table.insert(v13, v19);
                v14 = v14 == 0 and (v17 > 0 and (#v13 or 0) or 0) or v14;
            end;

            p8 = p8 - v17 * v[1];
            v16 = true;
        end;
    end;

    if p12 then
        v14 = math.min(v14 == 0 and (1 / 0) or v14, #v13 - (p12 - 1));
    end;

    local v20 = "";

    for i, v in pairs(v13) do
        local Formatted = v.Formatted;
        local _ = v.Raw;

        if not p12 or i >= v14 then
            v20 = v20 .. Formatted;
        end;
    end;

    return v20:sub(1, v20:len() - (p11 and 0 or 1));
end;

function v5.MultUDim2ByNum(p21, p22, p23) -- Line: 60
    return UDim2.new(p22.X.Scale * p23, p22.X.Offset * p23, p22.Y.Scale * p23, p22.Y.Offset * p23);
end;

function v5.MultColor3ByNum(p24, p25, p26) -- Line: 64
    return Color3.new(p25.R * p26, p25.G * p26, p25.B * p26);
end;

function v5.NumberToInteger(p27, p28) -- Line: 68
    local v29 = math.floor(p28);

    if p28 == v29 and p28 then
        v29 = p28;
    elseif math.random(1, 10000) <= math.ceil((p28 - v29) * 10000) then
        v29 = math.ceil(p28) or v29;
    end;

    return v29;
end;

function v5.FormatNumber(p30, p31) -- Line: 73
    local v32, v33, v34 = string.match(p31, "^([^%d]*%d)(%d*)(.-)$");

    return v32 .. v33:reverse():gsub("(%d%d%d)", "%1,"):reverse() .. v34;
end;

function v5.RoundNumber(p35, p36, p37, p38) -- Line: 78
    local v39 = p37 or 3;

    return math[p38 and "round" or "floor"](p36 * 10 ^ v39) / 10 ^ v39;
end;

function v5.IsWithin(p40, p41, p42, p43) -- Line: 83
    local v44 = (p41.X - p42.X) ^ 2 + (p41.Y - p42.Y) ^ 2 + (typeof(p41) == "Vector3" and ((p41.Z - p42.Z) ^ 2 or 0) or 0);

    return v44 <= p43 ^ 2, v44;
end;

function v5.BytesToKB(p45, p46) -- Line: 88
    return p45:FormatNumber(p45:RoundNumber(p46 / 1024, 3));
end;

return v5;