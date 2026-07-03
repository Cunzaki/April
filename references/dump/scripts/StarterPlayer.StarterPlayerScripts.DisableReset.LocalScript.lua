-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local StarterGui = game:GetService("StarterGui");
local RunService = game:GetService("RunService");
(function(p1, ...) -- Line: 12
    -- upvalues: StarterGui (copy), RunService (copy)
    local v2 = {};

    for _ = 1, 60 do
        v2 = { pcall(StarterGui[p1], StarterGui, ...) };

        if v2[1] then
            break;
        end;

        RunService.Stepped:Wait();
    end;

    return unpack(v2);
end)("SetCore", "ResetButtonCallback", false);