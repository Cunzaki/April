-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local CollectionService = game:GetService("CollectionService");
local u1 = {
    ActiveBenches = {}
};

function u1.SetServClientInfo(p2) -- Line: 31
    -- upvalues: u1 (copy)
    local BenchTag = p2.BenchTag;

    if not BenchTag then
        return;
    end;

    u1.ActiveBenches[BenchTag] = p2.Info;
end;

function u1.SetServClientInfos(p3) -- Line: 39
    -- upvalues: u1 (copy)
    for _, v in p3 do
        u1.SetServClientInfo(v);
    end;
end;

function u1.GetClientInfo(p4) -- Line: 46
    -- upvalues: u1 (copy)
    local v5 = u1.GetModelTag(p4);

    if v5 then
        return u1.GetClientInfoFromTag(v5);
    end;
end;

function u1.GetClientInfoFromTag(p6) -- Line: 54
    -- upvalues: u1 (copy)
    return u1.ActiveBenches[p6];
end;

function u1.GetModelTag(p7) -- Line: 61
    -- upvalues: CollectionService (copy)
    for _, v in CollectionService:GetTags(p7) do
        if #v == 36 then
            return v;
        end;
    end;
end;

function u1.GetModelFromTag(p8) -- Line: 70
    -- upvalues: CollectionService (copy)
    return CollectionService:GetTagged(p8)[1];
end;

function u1.GetAllClientInfos() -- Line: 76
    -- upvalues: u1 (copy)
    local v9 = {};

    for i, v in u1.ActiveBenches do
        local Model = v.Model;

        if not (Model and Model.Parent) then
            Model = u1.GetModelFromTag(i);
            v.Model = Model;
        end;

        if Model and Model.Parent then
            v9[Model] = v;
        end;
    end;

    return v9;
end;

function u1.GetAllRawClientInfos() -- Line: 92
    -- upvalues: u1 (copy)
    return u1.ActiveBenches;
end;

function u1.RemoveClientInfo(p10) -- Line: 97
    -- upvalues: u1 (copy)
    u1.ActiveBenches[p10] = nil;
end;

return u1;