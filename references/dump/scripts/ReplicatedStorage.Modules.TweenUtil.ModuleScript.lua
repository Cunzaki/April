-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local TweenService = game:GetService("TweenService");

return {
    Tween = function(p1, p2, p3, p4, p5, p6, p7, p8) -- Line: 13, Name: Tween
        -- upvalues: TweenService (copy)
        local v9 = TweenInfo.new(p5, Enum.EasingStyle[p6 or "Quad"], Enum.EasingDirection[p7 or "Out"]);
        local v10 = type(p4) == "table" and p4 and p4 or { p4 };
        local v11 = {};

        for i, v in pairs(type(p3) == "table" and p3 and p3 or { p3 }) do
            v11[v] = v10[i];
        end;

        local v12 = TweenService:Create(p2, v9, v11);

        if not p8 then
            v12:Play();
        end;

        return v12;
    end
};