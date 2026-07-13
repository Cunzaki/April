-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_upv_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local SoundService_upv_1 = game:GetService("SoundService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Attachments_upv_1 = ReplicatedStorage_1:WaitForChild("Attachments");
local _ = ReplicatedStorage_1:WaitForChild("Remotes");
local PlayerSounds_upv_1 = ReplicatedStorage_1:WaitForChild("PlayerSounds");
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local SoundModule_upv_1 = require(Modules_1:WaitForChild("SoundModule"));
local tbl_upv_1 = {};
tbl_upv_1.WeldParts = function(a1, a2, a3, a4)
    --[[
      name: WeldParts
      line: 27
    ]]
    local v1;
    v1 = nil;
    if (a4 ~= "All") then
        v1 = Instance.new("Weld");
        v1.Part0 = a3;
        v1.Part1 = a2;
        if (type(a4) ~= "string" and (a4)) then
            v1.C0 = a4;
        else
            local v2 = CFrame.new(v1.Part0.Position);
            v1.C0 = v1.Part0.CFrame:inverse() * v2;
            v1.C1 = v1.Part1.CFrame:inverse() * v2;
        end;
        v1.Parent = a2;
    end;
    a2.Anchored = false;
    a2.CanCollide = false;
    a2.Massless = true;
    return v1;
end;
tbl_upv_1.WeldModel = function(a1, a2, a3, a4)
    --[[
      name: WeldModel
      line: 49
    ]]
    for _, value_1 in pairs(a2:GetChildren()) do
        if (not (value_1:IsA("BasePart"))) then
            continue;
        end;
        if (a2.PrimaryPart ~= value_1) then
            a1:WeldParts(value_1, a2.PrimaryPart, a3);
        end;
        if (a4) then
            value_1.CanTouch = false;
            value_1.CanQuery = false;
        end;
    end;
end;
tbl_upv_1.WeldModelToPart = function(a1, a2, a3, a4, a5)
    --[[
      name: WeldModelToPart
      line: 61
    ]]
    a1:WeldModel(a2, (a5 and "") or "All");
    return a1:WeldParts(a2.PrimaryPart, a3, a4);
end;
tbl_upv_1.FullyWeldModels = function(a1, a2, a3, a4)
    --[[
      name: FullyWeldModels
      line: 66
    ]]
    local tbl_2 = {};
    local v3 = nil;
    for _, value_2 in pairs(a2:GetChildren()) do
        if (not (value_2:IsA("Model"))) then
            value_2.Parent = a3;
            continue;
        end;
        if (a3:FindFirstChild(value_2.Name)) then
            v3 = value_2.PrimaryPart or (value_2:FindFirstChild("Middle"));
            value_2.PrimaryPart = v3;
            v3 = value_2.PrimaryPart;
            a1:WeldModel(value_2, nil, a4);
            value_2.Parent = a3;
            a1:WeldParts(v3, a3[value_2.Name], CFrame.new());
            v3.Transparency = 1;
            v3.Name = value_2.Name;
            value_2.Name = a2.Name;
            table.insert(tbl_2, value_2);
        end;
    end;
    a2:Destroy();
    return tbl_2;
end;
tbl_upv_1.WeldAttachments = function(a1, a2, a3, a4, a5, a6, a7)
    --[[
      name: WeldAttachments
      line: 87
      upvalues:
        Items_upv_1 (copy, index: 1)
        Attachments_upv_1 (copy, index: 2)
        tbl_upv_1 (copy, index: 3)
        Players_upv_1 (copy, index: 4)
        PlayerSounds_upv_1 (copy, index: 5)
        SoundModule_upv_1 (copy, index: 6)
        SoundService_upv_1 (copy, index: 7)
    ]]
    local v4 = type(a3) == "table";
    local tbl_3 = {};
    local Attachments_2 = a2:FindFirstChild("Attachments");
    local v5, v5 = nil, nil;
    if (not (v4) or not (a3.Attachments)) then
        local tbl_4 = {};
        v5 = tbl_4;
    end;
    local v6 = a2:FindFirstChild("Arrow") or (a2:FindFirstChild("ArrowMain"));
    if (a2:FindFirstChild("RocketRoot") or v6) then
        local v7 = nil;
        if (v4) then
            v7 = a3.Ammo;
            if (v7 and v7.Amount > 0) then
                a6 = a6 or (v7.ID);
            end;
            local v8 = a6 and (Items_upv_1[a6]);
            local v9, v9 = nil, nil;
            if (not (v8) or not (v8.Name)) then
                v9 = "";
            end;
            local v10 = nil;
            for _, value_3 in pairs(a2:GetChildren()) do
                v10 = value_3.Name;
                if (v10 == "RocketRoot" or v10 == "Arrow" or v10 == "ArrowMain" or v6 and not (v10:find("Arrow"))) then
                    continue;
                end;
                if (v6) then
                    local v11;
                    v11 = v10 == v9;
                    local v12;
                    if (v11) then
                        v12 = 0;
                    else
                        v12 = 1;
                    end;
                    local value_3;
                    value_3.Transparency = v12;
                    if (v10 ~= "Combustive Arrow") then
                        continue;
                    end;
                    v12 = value_3:FindFirstChild("ParticleHolder");
                    local v37, v38;
                    if (not (v12)) then
                        continue;
                    end;
                    for v39, value_4 in pairs(v12:GetChildren()) do
                        value_4.Enabled = v11;
                    end;
                else
                    local v11;
                    if (not (v10:find("Rocket"))) then
                        continue;
                    end;
                    v11 = v10 == v9;
                    local v12;
                    if (v11) then
                        v12 = 0;
                    else
                        v12 = 1;
                    end;
                    local value_3;
                    value_3.Transparency = v12;
                    if (v10 ~= "Combustive Arrow") then
                        continue;
                    end;
                    v12 = value_3:FindFirstChild("ParticleHolder");
                    local v37, v38;
                    if (not (v12)) then
                        continue;
                    end;
                    for v39, value_4 in pairs(v12:GetChildren()) do
                        value_4.Enabled = v11;
                    end;
                end;
            end;
        end;
    end;
    if (Attachments_2) then
        local v13, v14 = nil, nil;
        if (v5) then
            local tbl_5 = {};
            local v15 = nil;
            local v16 = nil;
            for _, v15 in pairs(v5) do
                v16 = Items_upv_1[v15.ID];
                if (not (v16.MaxDurability) or v15.Durability > 0) then
                    tbl_5[v16.Name] = v15;
                end;
            end;
            for _, value_5 in pairs(Attachments_2:GetChildren()) do
                if (not (tbl_5[value_5.Name])) then
                    value_5:Destroy();
                end;
            end;
            local v17 = 0;
            local Attachments_2, v18 = nil, nil;
            v18 = v17;
            local v12, v19, v20, v21 = nil, nil, nil, nil;
            local v22 = nil;
            local v23 = nil;
            local v24 = nil;
            local v25 = nil;
            local v26 = nil;
            for key_1, value_6 in pairs(tbl_5) do
                v24 = Attachments_2:FindFirstChild(key_1);
                v23 = Items_upv_1[value_6.ID].AttachmentType;
                if (v23 == "Sight") then
                    v18 = 1;
                end;
                v22 = false;
                if (v23 ~= "Sight") then
                    v12 = v22;
                elseif (v4) then
                    local v27 = true;
                    if (a3.ID == 198) then
                        v12 = v27;
                    else
                        v12 = a3.ID == 221;
                    end;
                else
                    v12 = v4;
                end;
                if (v24) then
                    local value_7 = nil;
                    local v28 = nil;
                    for _, value_7 in pairs({"AimFront", "AimBack", "FlashPart"}) do
                        v28 = v24 and (v24:FindFirstChild(value_7));
                        if (v28) then
                            tbl_3[value_7] = v28;
                        end;
                    end;
                else
                    local v29 = a2:FindFirstChild(v23 .. "Main");
                    v24 = Attachments_upv_1:FindFirstChild(key_1);
                    if (not (v24) or not (v29)) then
                        continue;
                    end;
                    v24 = v24:Clone();
                    if (a7 and a7 ~= 1) then
                        v24:ScaleTo(a7);
                    end;
                    v24.PrimaryPart = v24:FindFirstChild("Main");
                    v25 = v24:FindFirstChild("Reticle");
                    if (v25 and a5) then
                        for v28, value_8 in pairs(v25:GetChildren()) do
                            value_8.Enabled = false;
                        end;
                    end;
                    v19 = false;
                    if (v12) then
                        v26 = v24:FindFirstChild("M4Riser");
                        if (v26) then
                            v19 = true;
                            v26.Transparency = 0;
                        end;
                    end;
                    v20 = v19 and CFrame.new(0, 0.08, 0) or CFrame.new();
                    tbl_upv_1:WeldModelToPart(v24, v29, v20);
                    v24.Parent = Attachments_2;
                    local value_7 = nil;
                    local v28 = nil;
                    for _, value_7 in pairs({"AimFront", "AimBack", "FlashPart"}) do
                        v28 = v24 and (v24:FindFirstChild(value_7));
                        if (v28) then
                            tbl_3[value_7] = v28;
                        end;
                    end;
                end;
            end;
            v13 = a2:FindFirstChild("SightHide");
            if (v13) then
                v13.Transparency = v18;
            end;
            v14 = a2:FindFirstChild("RailExtender");
            if (v14) then
                v14.Transparency = ((v18 ~= 0) and 0) or 1;
            end;
            local Silencer_1 = tbl_5.Silencer;
            if (v4 and not (a4)) then
                v15 = a2.Parent;
                local v30 = nil;
                if (Players_upv_1:GetPlayerFromCharacter(v15)) then
                    v21 = v15.PrimaryPart;
                    v30 = Items_upv_1[a3.ID];
                    if (v21 and v30) then
                        v23 = PlayerSounds_upv_1:FindFirstChild(v30.Name);
                        if (v23) then
                            local v31 = a3.Skin or "Default";
                            local v32 = SoundModule_upv_1.CustomSoundSkins[v31];
                            local v33 = (v32 and {"", ("_%*"):format(v31)}) or {""};
                            local v34, v34 = nil, nil;
                            local v35 = nil;
                            local v36 = nil;
                            local Volume_1 = nil;
                            local SilencedEffect_1 = nil;
                            for _, value_9 in v33 do
                                v35 = ("Shoot%*"):format(value_9);
                                v20 = v21:FindFirstChild(v30.Name .. v35);
                                v36 = v23:FindFirstChild(v35);
                                if (not (v20) or not (v36)) then
                                    continue;
                                end;
                                v20.RollOffMaxDistance = (Silencer_1 and 250) or (v36.RollOffMaxDistance);
                                Volume_1 = v36.Volume;
                                if (Silencer_1) then
                                    if (value_9 == "" or type(v32) ~= "number") then
                                        v34 = 0.95;
                                    else
                                        v34 = v32;
                                    end;
                                    if (not (v34)) then
                                        v34 = 1;
                                    end;
                                else
                                    v34 = 1;
                                end;
                                v20.Volume = Volume_1 * v34;
                                SilencedEffect_1 = v20:FindFirstChild("SilencedEffect");
                                if (not (Silencer_1) or SilencedEffect_1) then
                                    if (not (SilencedEffect_1)) then
                                        continue;
                                    end;
                                    if (not (Silencer_1)) then
                                        SilencedEffect_1:Destroy();
                                    end;
                                else
                                    SoundService_upv_1.SilencedEffect:Clone().Parent = v20;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
            return tbl_3.AimFront, tbl_3.AimBack, tbl_3.FlashPart;
        end;
    end;
end;
return tbl_upv_1;