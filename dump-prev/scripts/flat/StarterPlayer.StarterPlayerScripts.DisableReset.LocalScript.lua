-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local StarterGui_upv_1 = game:GetService("StarterGui");
local RunService_upv_1 = game:GetService("RunService");
(function(a1, ...)
    --[[
      line: 12
      upvalues:
        StarterGui_upv_1 (copy, index: 1)
        RunService_upv_1 (copy, index: 2)
    ]]
    local tbl_1 = {};
    for _ = 1, 60 do
        local v1;
        v1 = {pcall(StarterGui_upv_1[a1], StarterGui_upv_1, ...)};
        if (v1[1]) then
            tbl_1 = v1;
            break;
        else
            RunService_upv_1.Stepped:Wait();
            tbl_1 = v1;
        end;
    end;
    return unpack(tbl_1);
end)("SetCore", "ResetButtonCallback", false);