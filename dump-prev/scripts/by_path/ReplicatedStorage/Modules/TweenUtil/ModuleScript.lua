-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local TweenService_upv_1 = game:GetService("TweenService");
local tbl_1 = {};
tbl_1.Tween = function(a1, a2, a3, a4, a5, a6, a7, a8)
    --[[
      name: Tween
      line: 13
      upvalues:
        TweenService_upv_1 (copy, index: 1)
    ]]
    local v1 = TweenInfo.new(a5, Enum.EasingStyle[a6 or "Quad"], Enum.EasingDirection[a7 or "Out"]);
    local tbl_2 = {};
    local v2 = ((type(a4) == "table") and a4) or {a4};
    local v3 = ((type(a3) == "table") and a3) or {a3};
    for key_1, value_1 in pairs(v3) do
        tbl_2[value_1] = v2[key_1];
    end;
    local v4 = TweenService_upv_1:Create(a2, v1, tbl_2);
    if (not (a8)) then
        v4:Play();
    end;
    return v4;
end;
return tbl_1;