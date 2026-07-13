-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_1 = {};
tbl_1.Lerp = function(a1, a2, a3, a4)
    --[[
      name: Lerp
      line: 12
    ]]
    return (a2 * (1 - a4)) + (a3 * a4);
end;
local tbl_upv_2 = {{604800, "Weeks"}, {86400, "Days"}, {3600, "Hours"}, {60, "Minutes"}, {1, "Seconds"}};
tbl_1.FormatTime = function(a1, a2, a3, a4, a5, a6)
    --[[
      name: FormatTime
      line: 23
      upvalues:
        tbl_upv_2 (copy, index: 1)
    ]]
    local v1 = false;
    local v2 = false;
    local tbl_3 = {};
    local v3 = 0;
    local v4 = nil;
    for key_1, value_1 in pairs(tbl_upv_2) do
        if (value_1[2] == a3) then
            local v5;
            v5 = math.floor(a2 / value_1[1]);
            local v6;
            v6 = tbl_upv_2[key_1 - 1];
            if (v6 and v6[2] == a4) then
                v2 = true;
            end;
            if (v2) then
                a2 = a2 - v5 * value_1[1];
                v1 = true;
                continue;
            end;
            local tbl_4 = {};
            local v7;
            if (v5 > 9 or not (v1)) then
                v7 = "";
            else
                v7 = "0";
            end;
            local v8 = (a5 and (value_1[2]:sub(1, 1):lower())) or ":";
            tbl_4.Formatted = v7 .. v5 .. v8;
            tbl_4.Raw = v5;
            table.insert(tbl_3, tbl_4);
            if (v3 ~= 0) then
                v4 = v3;
            else
                v4 = ((v5 > 0) and (#tbl_3)) or 0;
            end;
            v3 = v4;
            a2 = a2 - v5 * value_1[1];
            v1 = true;
        else
            local v5, v6;
            if (not (v1)) then
                continue;
            end;
            v5 = math.floor(a2 / value_1[1]);
            v6 = tbl_upv_2[key_1 - 1];
            if (v6 and v6[2] == a4) then
                v2 = true;
            end;
            if (v2) then
                a2 = a2 - v5 * value_1[1];
                v1 = true;
                continue;
            end;
            local tbl_4 = {};
            local v7;
            if (v5 > 9 or not (v1)) then
                v7 = "";
            else
                v7 = "0";
            end;
            local v8 = (a5 and (value_1[2]:sub(1, 1):lower())) or ":";
            tbl_4.Formatted = v7 .. v5 .. v8;
            tbl_4.Raw = v5;
            table.insert(tbl_3, tbl_4);
            if (v3 ~= 0) then
                v4 = v3;
            else
                v4 = ((v5 > 0) and (#tbl_3)) or 0;
            end;
            v3 = v4;
            a2 = a2 - v5 * value_1[1];
            v1 = true;
        end;
    end;
    if (a6) then
        local v9;
        if (v3 ~= 0) then
            v9 = v3;
        else
            v9 = math.huge;
        end;
        v3 = math.min(v9, #tbl_3 - (a6 - 1));
    end;
    local v11 = "";
    local Formatted_1 = nil;
    for key_2, value_2 in pairs(tbl_3) do
        Formatted_1 = value_2.Formatted;
        if (not (a6) or key_2 >= v3) then
            v11 = v11 .. Formatted_1;
        end;
    end;
    local value_2 = v11:len();
    return v11:sub(1, value_2 - ((a5 and 0) or 1));
end;
tbl_1.MultUDim2ByNum = function(a1, a2, a3)
    --[[
      name: MultUDim2ByNum
      line: 60
    ]]
    return UDim2.new(a2.X.Scale * a3, a2.X.Offset * a3, a2.Y.Scale * a3, a2.Y.Offset * a3);
end;
tbl_1.MultColor3ByNum = function(a1, a2, a3)
    --[[
      name: MultColor3ByNum
      line: 64
    ]]
    return Color3.new(a2.R * a3, a2.G * a3, a2.B * a3);
end;
tbl_1.NumberToInteger = function(a1, a2)
    --[[
      name: NumberToInteger
      line: 68
    ]]
    local v12 = math.floor(a2);
    local v13 = ((a2 == v12) and a2) or (((math.random(1, 10000) <= math.ceil((a2 - v12) * 10000)) and (math.ceil(a2))) or v12);
    return v13;
end;
tbl_1.FormatNumber = function(a1, a2)
    --[[
      name: FormatNumber
      line: 73
    ]]
    local v14, v15, v16 = string.match(a2, "^([^%d]*%d)(%d*)(.-)$");
    return v14 .. v15:reverse():gsub("(%d%d%d)", "%1,"):reverse() .. v16;
end;
tbl_1.RoundNumber = function(a1, a2, a3, a4)
    --[[
      name: RoundNumber
      line: 78
    ]]
    a3 = a3 or 3;
    return math[(a4 and "round") or "floor"](a2 * (10 ^ a3)) / (10 ^ a3);
end;
tbl_1.IsWithin = function(a1, a2, a3, a4)
    --[[
      name: IsWithin
      line: 83
    ]]
    local v17 = ((typeof(a2) == "Vector3") and ((a2.Z - a3.Z) ^ 2)) or 0;
    local v18 = ((a2.X - a3.X) ^ 2) + ((a2.Y - a3.Y) ^ 2) + v17;
    return v18 <= (a4 ^ 2), v18;
end;
tbl_1.BytesToKB = function(a1, a2)
    --[[
      name: BytesToKB
      line: 88
    ]]
    return a1:FormatNumber(a1:RoundNumber(a2 / 1024, 3));
end;
return tbl_1;