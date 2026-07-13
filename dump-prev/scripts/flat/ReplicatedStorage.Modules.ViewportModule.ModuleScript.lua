-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local RunService_upv_1 = game:GetService("RunService");
local UserInputService_upv_1 = game:GetService("UserInputService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local ArmorModule_upv_1 = require(Modules_1:WaitForChild("ArmorModule"));
local TweenUtil_upv_1 = require(Modules_1:WaitForChild("TweenUtil"));
local Idle_upv_1 = script:WaitForChild("Idle");
local Selected_upv_1 = script:WaitForChild("Selected");
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local tbl_upv_1 = {};
local tbl_upv_2 = {};
tbl_upv_2.ShowCharacter = function(a1, a2, a3, a4, a5)
    --[[
      name: ShowCharacter
      line: 37
      upvalues:
        Idle_upv_1 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    if (a2) then
        local v1 = nil;
        if (a2.Parent) then
            a1:ClearViewport(a2);
            local v2 = Instance.new("Camera");
            v2.Parent = a2;
            a2.CurrentCamera = v2;
            local v3 = Instance.new("WorldModel");
            v3.Parent = a2;
            a3.Archivable = true;
            local time_1 = tick();
            local tbl_3 = {};
            print("waiting on character children");
            while (tick() - time_1 < 60 and (a3.Parent)) do
                local v4 = true;
                for key_1, value_1 in tbl_3 do
                    if (value_1) then
                        continue;
                    end;
                    if (a3:FindFirstChild(key_1)) then
                        tbl_3[key_1] = true;
                    else
                        v4 = false;
                    end;
                end;
                if (v4) then
                    break;
                else
                    task.wait();
                end;
            end;
            print("character children found in", tick() - time_1);
            local v5 = a3:Clone();
            a3.Archivable = false;
            for u1, value_2 in pairs(v5:GetChildren()) do
                if (not value_2:IsA("BasePart") and not value_2:IsA("Shirt") and not value_2:IsA("Pants") and not value_2:IsA("Humanoid") and value_2.Name:sub(1, 6) ~= "Armor_" and value_2.Name ~= "Hair") then
                    value_2:Destroy();
                    continue;
                end;
                for _, value_3 in pairs(value_2:GetChildren()) do
                    if (value_3:IsA("BillboardGui")) then
                        value_3:Destroy();
                    end;
                end;
            end;
            v5.Parent = v3;
            local HumanoidRootPart_1 = v5:WaitForChild("HumanoidRootPart");
            HumanoidRootPart_1.Anchored = false;
            v5:WaitForChild("Humanoid"):LoadAnimation(Idle_upv_1):Play();
            local u1 = {};
            local tbl_4 = {};
            local tbl_5 = {};
            tbl_5.Camera = v2;
            tbl_5.Object = v5;
            tbl_5.Anims = {};
            tbl_5.Char = a3;
            tbl_5.Hitboxes = a4;
            tbl_5.Connections = tbl_4;
            tbl_5.FaceFeatures = u1;
            tbl_upv_1[a2] = tbl_5;
            v1 = a3:FindFirstChild("Head");
            local Head_upv_1;
            if (v1) then
                Head_upv_1 = v5:FindFirstChild("Head");
                table.insert(
                    tbl_4,
                    v1.ChildAdded:Connect(
                        function(a6)
                            --[[
                              line: 119
                              upvalues:
                                Head_upv_1 (copy, index: 1)
                                u1 (copy, index: 2)
                            ]]
                            if (not a6:IsA("Decal") or not Head_upv_1) then
                                return;
                            end;
                            if (Head_upv_1.Parent) then
                                local v6 = a6:Clone();
                                v6.Parent = Head_upv_1;
                                u1[a6] = v6;
                            end;
                        end
                    )
                );
                table.insert(
                    tbl_4,
                    v1.ChildRemoved:Connect(
                        function(a7)
                            --[[
                              line: 125
                              upvalues:
                                u1 (copy, index: 1)
                            ]]
                            local v7;
                            if (not a7:IsA("Decal")) then
                                return;
                            end;
                            v7 = u1[a7];
                            if (not v7 or not v7.Parent) then
                                return;
                            end;
                            v7:Destroy();
                        end
                    )
                );
                if (Head_upv_1) then
                    Head_upv_1.Transparency = 0.9;
                    local u2 = nil;
                    for _, value_upv_4 in pairs(v1:GetChildren()) do
                        if (not (value_upv_4:IsA("Decal"))) then
                            continue;
                        end;
                        u2 = Head_upv_1:FindFirstChild(value_upv_4.Name);
                        if (u2) then
                            table.insert(
                                tbl_4,
                                value_upv_4.Changed:Connect(
                                    function(a8)
                                        --[[
                                          line: 137
                                          upvalues:
                                            u2 (copy, index: 1)
                                            value_upv_4 (copy, index: 2)
                                        ]]
                                        if (u2) then
                                            local success_1;
                                            if (u2.Parent) then
                                                local success_1, v8 = pcall(
                                                    function()
                                                        --[[
                                                          line: 139
                                                          upvalues:
                                                            value_upv_4 (copy, index: 1)
                                                            a8 (copy, index: 2)
                                                        ]]
                                                        return value_upv_4[a8];
                                                    end
                                                );
                                                if (not success_1) then
                                                    return;
                                                end;
                                                u2[a8] = v8;
                                            end;
                                        end;
                                    end
                                )
                            );
                        end;
                    end;
                end;
            end;
            a1:AddSpin(a2);
            v5:PivotTo(CFrame.new());
            local v9 = CFrame.new((HumanoidRootPart_1.CFrame * CFrame.new(0, 1, -5)).Position, HumanoidRootPart_1.Position + Vector3.new(0, 0.10000000149011612, 0));
            v2.CFrame = v9;
            tbl_5.OrigCamCF = v9;
            if (a5) then
                a1:UpdateArmors(a2, a5);
            end;
            return tbl_5;
        end;
    end;
end;
tbl_upv_2.TweenCamera = function(a1, a2, a3)
    --[[
      name: TweenCamera
      line: 160
      upvalues:
        tbl_upv_1 (copy, index: 1)
        TweenUtil_upv_1 (copy, index: 2)
    ]]
    local v10 = tbl_upv_1[a2];
    if (not v10) then
        return;
    end;
    TweenUtil_upv_1:Tween(v10.Camera, "CFrame", v10.OrigCamCF * a3, 0.5, "Quart", "Out");
end;
tbl_upv_2.UpdateArmors = function(a1, a2, a3)
    --[[
      name: UpdateArmors
      line: 166
      upvalues:
        tbl_upv_1 (copy, index: 1)
        ArmorModule_upv_1 (copy, index: 2)
    ]]
    local v11 = tbl_upv_1[a2];
    if (not v11) then
        return;
    end;
    ArmorModule_upv_1:UpdateArmors(v11.Object, a3);
end;
tbl_upv_2.ClearViewport = function(a1, a2)
    --[[
      name: ClearViewport
      line: 172
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    a2:ClearAllChildren();
    local v12 = tbl_upv_1[a2];
    if (v12 and v12.Connections) then
        for _, value_5 in pairs(v12.Connections) do
            value_5:Disconnect();
        end;
    end;
    tbl_upv_1[a2] = nil;
end;
tbl_upv_2.AddSpin = function(a1, a2)
    --[[
      name: AddSpin
      line: 183
      upvalues:
        tbl_upv_1 (copy, index: 1)
        UserInputService_upv_1 (copy, index: 2)
        RunService_upv_1 (copy, index: 3)
    ]]
    local u3 = tbl_upv_1[a2];
    local u4 = nil;
    for _, value_6 in pairs({a2, unpack(u3.Hitboxes or {})}) do
        table.insert(
            u3.Connections,
            value_6.InputBegan:Connect(
                function(a3)
                    --[[
                      line: 188
                      upvalues:
                        u4 (ref,  index: 1)
                        u3 (copy, index: 2)
                    ]]
                    if (a3.UserInputType ~= Enum.UserInputType.MouseButton1) then
                        return;
                    end;
                    u4 = a3.Position;
                    u3.Held = true;
                end
            )
        );
    end;
    table.insert(
        u3.Connections,
        UserInputService_upv_1.InputChanged:Connect(
            function(a4)
                --[[
                  line: 194
                  upvalues:
                    u3 (copy, index: 1)
                    u4 (ref,  index: 2)
                    a1 (copy, index: 3)
                    a2 (copy, index: 4)
                ]]
                if (a4.UserInputType == Enum.UserInputType.MouseMovement and u3.Held) then
                    local Position_1 = a4.Position;
                    u3.Delta = (Position_1 - u4) * 0.8;
                    a1:SpinViewport(a2);
                    u4 = Position_1;
                end;
            end
        )
    );
    table.insert(
        u3.Connections,
        UserInputService_upv_1.InputEnded:Connect(
            function(a5)
                --[[
                  line: 201
                  upvalues:
                    u3 (copy, index: 1)
                    u4 (ref,  index: 2)
                    RunService_upv_1 (copy, index: 3)
                ]]
                if (a5.UserInputType ~= Enum.UserInputType.MouseButton1 or not u3.Held) then
                    return;
                end;
                u3.Held = false;
                if (a5.Position == u4) then
                    u3.Delta = Vector3.new();
                end;
                while (not (u3.Held)) do
                    u3.Delta = u3.Delta:Lerp(Vector3.new(0, 0, 0), 0.1);
                    RunService_upv_1.Heartbeat:Wait();
                end;
            end
        )
    );
end;
tbl_upv_2.SpinViewport = function(a1, a2)
    --[[
      name: SpinViewport
      line: 214
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v13 = tbl_upv_1[a2];
    local v14 = nil;
    if (v13) then
        v14 = v13.Object;
        local v15 = nil;
        if (v14) then
            v15 = v14.PrimaryPart;
        end;
        if (v14 and v15) then
            v14:SetPrimaryPartCFrame(v15.CFrame * CFrame.Angles(0, math.rad(v13.Delta.X), 0));
            return true;
        end;
    end;
end;
tbl_upv_2.HighlightCharArea = function(a1, a2, a3)
    --[[
      name: HighlightCharArea
      line: 225
      upvalues:
        tbl_upv_1 (copy, index: 1)
        Selected_upv_1 (copy, index: 2)
    ]]
    local v16 = tbl_upv_1[a2];
    if (v16) then
        local v17 = ((a3 == "Head") and {"Head"}) or (((a3 == "Legs") and {"RightUpperLeg", "RightLowerLeg", "RightFoot", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"}) or (((a3 == "Chest") and {"RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand", "UpperTorso", "LowerTorso"}) or {}));
        local _, v25;
        local v18 = nil;
        local v19 = nil;
        local v20 = nil;
        for v26, value_7 in pairs(v16.Object:GetChildren()) do
            v19 = value_7.Name;
            if (v19:sub(1, 6) == "Armor_") then
                v18 = value_7:IsA("Model");
            else
                v18 = false;
                if (v19 == "Hair") then
                    v18 = value_7:IsA("Model");
                end;
            end;
            if (value_7.Name == "HumanoidRootPart" or value_7.Name == "CollisionPart") then
                continue;
            end;
            if (value_7:IsA("BasePart")) then
                local v21;
                v21 = {};
                if (v18) then
                    for v27, value_8 in pairs(value_7:GetChildren()) do
                        if (value_8 == value_7.PrimaryPart) then
                            v19 = value_8.Name;
                        end;
                        v20 = value_8:IsA("BasePart");
                        if (not (v20)) then
                            continue;
                        end;
                        if (value_8.Transparency < 1) then
                            table.insert(v21, value_8);
                        end;
                    end;
                else
                    v21[1] = value_7;
                end;
                local v22 = table.find(v17, v19);
                local v28, v29, v22, _, v25 = nil, nil, nil, nil, nil;
                local v23 = nil;
                for v30, value_9 in pairs(v21) do
                    v23 = value_9:FindFirstChild("Selected");
                    if (v22) then
                        if (v23) then
                            for v31, value_10 in pairs(v20:GetChildren()) do
                                if (value_10.Name ~= "Selected") then
                                    continue;
                                end;
                                if (value_10:IsA("Decal")) then
                                    value_10.Transparency = (v22 and (Selected_upv_1.Transparency)) or 1;
                                end;
                            end;
                            v28, v29, _, v25 = nil, nil, nil, nil;
                            continue;
                        else
                            local v24 = nil;
                            for v32, value_11 in pairs(Enum.NormalId:GetEnumItems()) do
                                v24 = Selected_upv_1:Clone();
                                v24.Face = value_11;
                                v24.Parent = value_9;
                            end;
                        end;
                    else
                        local v33, v34;
                        if (not (v23)) then
                            continue;
                        end;
                        for v31, value_10 in pairs(v20:GetChildren()) do
                            if (value_10.Name ~= "Selected") then
                                continue;
                            end;
                            if (value_10:IsA("Decal")) then
                                value_10.Transparency = (v22 and (Selected_upv_1.Transparency)) or 1;
                            end;
                        end;
                        v28, v29, _, v25 = nil, nil, nil, nil;
                    end;
                end;
            else
                local v21;
                if (not (v18)) then
                    continue;
                end;
                v21 = {};
                if (v18) then
                    for v27, value_8 in pairs(value_7:GetChildren()) do
                        if (value_8 == value_7.PrimaryPart) then
                            v19 = value_8.Name;
                        end;
                        v20 = value_8:IsA("BasePart");
                        if (not (v20)) then
                            continue;
                        end;
                        if (value_8.Transparency < 1) then
                            table.insert(v21, value_8);
                        end;
                    end;
                else
                    v21[1] = value_7;
                end;
                local v22 = table.find(v17, v19);
                local v28, v29, v22, _, v25 = nil, nil, nil, nil, nil;
                local v23 = nil;
                for v30, value_9 in pairs(v21) do
                    v23 = value_9:FindFirstChild("Selected");
                    if (v22) then
                        if (v23) then
                            for v31, value_10 in pairs(v20:GetChildren()) do
                                if (value_10.Name ~= "Selected") then
                                    continue;
                                end;
                                if (value_10:IsA("Decal")) then
                                    value_10.Transparency = (v22 and (Selected_upv_1.Transparency)) or 1;
                                end;
                            end;
                            v28, v29, _, v25 = nil, nil, nil, nil;
                            continue;
                        else
                            local v24 = nil;
                            for v32, value_11 in pairs(Enum.NormalId:GetEnumItems()) do
                                v24 = Selected_upv_1:Clone();
                                v24.Face = value_11;
                                v24.Parent = value_9;
                            end;
                        end;
                    else
                        local v33, v34;
                        if (not (v23)) then
                            continue;
                        end;
                        for v31, value_10 in pairs(v20:GetChildren()) do
                            if (value_10.Name ~= "Selected") then
                                continue;
                            end;
                            if (value_10:IsA("Decal")) then
                                value_10.Transparency = (v22 and (Selected_upv_1.Transparency)) or 1;
                            end;
                        end;
                        v28, v29, _, v25 = nil, nil, nil, nil;
                    end;
                end;
            end;
        end;
    end;
end;
tbl_upv_2.Initialize = function(a1)
    --[[
      name: Initialize
      line: 309
      upvalues:
        tbl_upv_1 (copy, index: 1)
        LocalPlayer_upv_1 (copy, index: 2)
        tbl_upv_2 (copy, index: 3)
    ]]
    local v25 = nil;
    for key_2, value_12 in pairs(tbl_upv_1) do
        v25 = value_12.Object;
        if (not (v25) or not (v25:IsDescendantOf(LocalPlayer_upv_1))) then
            tbl_upv_1[key_2] = nil;
            continue;
        end;
        if (value_12.Held or tbl_upv_2:SpinViewport(key_2)) then
            continue;
        end;
        if (v25) then
            v25:Destroy();
        end;
        tbl_upv_1[key_2] = nil;
    end;
end;
return tbl_upv_2;