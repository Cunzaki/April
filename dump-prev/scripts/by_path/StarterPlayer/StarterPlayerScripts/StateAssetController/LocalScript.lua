-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_upv_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local TweenService_upv_1 = game:GetService("TweenService");
local UserInputService_upv_1 = game:GetService("UserInputService");
local UserService_upv_1 = game:GetService("UserService");
local RunService_upv_1 = game:GetService("RunService");
local LocalPlayer_upv_1 = Players_upv_1.LocalPlayer;
local PlayerGui_upv_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui");
local u1 = nil;
local HumanoidRootPart_upv_1 = nil;
local Humanoid_upv_1 = nil;
local InteractController_upv_1 = nil;
local WaterController_upv_1 = nil;
local StateController_upv_1 = nil;
local WheelController_upv_1 = nil;
local InventoryController_upv_1 = nil;
local TeamNavigationController_upv_1 = nil;
local PreferredInputController_upv_1 = LocalPlayer_upv_1:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local tbl_upv_1 = {};
local u2 = nil;
local Inventory_upv_1 = nil;
local Toolbar_upv_1 = nil;
local Down_upv_1 = nil;
local Death_upv_1 = nil;
local Background_upv_1 = nil;
local Header_upv_1 = nil;
local Footer_upv_1 = nil;
local Compass_upv_1 = nil;
local Stats_upv_1 = nil;
local Map_upv_1 = nil;
local Blood_upv_1 = nil;
local Revive_upv_1 = nil;
local Fill_upv_1 = nil;
local DeathBar_upv_1 = nil;
local Fill_upv_2 = nil;
local ImageLabel_upv_1 = nil;
local RespawnLabel_upv_1 = nil;
local GamepadControls_upv_1 = nil;
local u3 = nil;
local u4 = false;
local CharacterScripts_upv_1 = ReplicatedStorage_1:WaitForChild("CharacterScripts");
local UIs_upv_1 = ReplicatedStorage_1:WaitForChild("UIs");
local CurrentCamera_upv_1 = workspace.CurrentCamera;
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local SoundModule_upv_1 = require(Modules_1:WaitForChild("SoundModule"));
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local GamepadIconModule_upv_1 = require(Modules_1:WaitForChild("GamepadIconModule"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local TweenUtil_upv_1 = require(Modules_1:WaitForChild("TweenUtil"));
local Values_upv_1 = ReplicatedStorage_1:WaitForChild("Values");
local u5 = require(Modules_1:WaitForChild("AssetContainer"))();
local u6 = script:WaitForChild("Animations"):GetChildren();
local u7 = Vector2.new(0, 0);
local u8 = nil;
local u9 = nil;
local u10 = nil;
local tbl_upv_2 = {};
local u11 = os.clock();
local u12 = 0;
local GamepadSelected_upv_1 = nil;
local u13 = 0;
local u14 = nil;
local tbl_upv_3 = {};
tbl_upv_3.Grass = 0.85;
tbl_upv_3.Sand = 1.8;
tbl_upv_3.Wood = 0.8;
tbl_upv_3.Metal = 1;
tbl_upv_3.Rock = 0.85;
tbl_upv_3.Water = 0.9;
tbl_upv_3.Mud = 1;
local function u15(a1, a2)
    --[[
      line: 82
      upvalues:
        Background_upv_1 (ref,  index: 1)
        TweenService_upv_1 (copy, index: 2)
    ]]
    if (not Background_upv_1) then
        return;
    end;
    if (Background_upv_1.Parent) then
        local v1 = TweenInfo.new(a2, Enum.EasingStyle.Quad);
        local tbl_4 = {};
        tbl_4.Transparency = (a1 and 0) or 1;
        TweenService_upv_1:Create(Background_upv_1, v1, tbl_4):Play();
    end;
end;
local function u16(a1)
    --[[
      line: 102
      upvalues:
        Blood_upv_1 (ref,  index: 1)
        u2 (ref,  index: 2)
        TweenService_upv_1 (copy, index: 3)
    ]]
    if (Blood_upv_1 and Blood_upv_1.Parent) then
        local u17 = Blood_upv_1:Clone();
        u17.Name = "bloodTemp";
        u17.Parent = u2;
        u17.Visible = true;
        local v2 = TweenService_upv_1:Create(u17, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, true), {ImageTransparency = a1});
        v2.Completed:Connect(
            function()
                --[[
                  line: 114
                  upvalues:
                    u17 (copy, index: 1)
                ]]
                u17:Destroy();
            end
        );
        v2:Play();
    end;
end;
local function u18()
    --[[
      line: 130
      upvalues:
        Humanoid_upv_1 (ref, index: 1)
    ]]
    local FloorMaterial_1 = Humanoid_upv_1.FloorMaterial;
    if (FloorMaterial_1) then
        if (FloorMaterial_1 ~= Enum.Material.Grass and FloorMaterial_1 ~= Enum.Material.LeafyGrass) then
            if (FloorMaterial_1 ~= Enum.Material.Snow and FloorMaterial_1 ~= Enum.Material.Sand and FloorMaterial_1 ~= Enum.Material.Glacier) then
                if (FloorMaterial_1 ~= Enum.Material.Wood and FloorMaterial_1 ~= Enum.Material.WoodPlanks) then
                    if (FloorMaterial_1 ~= Enum.Material.Metal and FloorMaterial_1 ~= Enum.Material.CorrodedMetal and FloorMaterial_1 ~= Enum.Material.DiamondPlate) then
                        if (FloorMaterial_1 ~= Enum.Material.Mud) then
                            if (FloorMaterial_1 ~= Enum.Material.Rock) then
                                if (FloorMaterial_1 ~= Enum.Material.Air) then
                                    return "Rock";
                                end;
                                return "";
                            end;
                            return "Rock";
                        end;
                        return "Mud";
                    end;
                    return "Metal";
                end;
                return "Wood";
            end;
            return "Sand";
        end;
        return "Grass";
    end;
end;
local function u19(a1)
    --[[
      line: 154
      upvalues:
        Humanoid_upv_1 (ref,  index: 1)
        StateController_upv_1 (ref,  index: 2)
        WaterController_upv_1 (ref,  index: 3)
        u9 (ref,  index: 4)
        SoundModule_upv_1 (copy, index: 5)
        u1 (ref,  index: 6)
        u18 (copy, index: 7)
        tbl_upv_3 (copy, index: 8)
        u14 (ref,  index: 9)
        u13 (ref,  index: 10)
    ]]
    if (not Humanoid_upv_1 or not Humanoid_upv_1.Parent or not StateController_upv_1 or not StateController_upv_1.Parent or not WaterController_upv_1 or not WaterController_upv_1.Parent) then
        return;
    end;
    if (not (Humanoid_upv_1:GetAttribute("Downed")) and Humanoid_upv_1.Health > 0) then
        local v3 = nil;
        if (Humanoid_upv_1.Health > 0) then
            v3 = u1:FindFirstChild("HumanoidRootPart");
            local v4, v5 = nil, nil;
            if (v3) then
                local v6 = StateController_upv_1:GetAttribute("IsSprint");
                local v7 = StateController_upv_1:GetAttribute("IsCrouch");
                local v8 = WaterController_upv_1:GetAttribute("InWater");
                local v9 = WaterController_upv_1:GetAttribute("IsUnder");
                v4 = u18();
                local v10 = "";
                if (v4 and a1 ~= "Idle" and not (v7) and not (v9) and a1 ~= "Sit") then
                    v10 = v4;
                end;
                local v11;
                v11 = nil;
                local v12 = v3:FindFirstChild("Footsteps" .. v10);
                local v13 = (u9 ~= v12) and true;
                if (v12) then
                    v5 = tbl_upv_3[v10] * ((v6 and 1.75) or 1);
                    if (math.abs(v12.PlaybackSpeed - v5) > 1e-04) then
                        v11 = v5;
                    end;
                end;
                if (v11 and not (v13) and u14 and u14 == u13) then
                    return;
                end;
                u14 = u13;
                if ((v13) and (v11)) then
                    SoundModule_upv_1:ToggleFootstep(u1, v12, v11);
                elseif (v13) then
                    SoundModule_upv_1:ToggleFootstep(u1, v12);
                elseif (v11) then
                    SoundModule_upv_1:ChangeSoundSpeed(v12, v11);
                end;
                v5 = v3:FindFirstChild("WalkWater");
                if (v5) then
                    if (v8) then
                        if (a1 == "Idle" or a1 == "Sit") then
                            if (v5.IsPlaying) then
                                SoundModule_upv_1:StopSound(v5);
                            end;
                        else
                            local v14 = false;
                            if (not (v5.IsPlaying)) then
                                v14 = true;
                            end;
                            local v15 = 0.9 * ((v6 and 1.75) or 1);
                            local v16 = (math.abs(v5.PlaybackSpeed - v15) > 1e-04) and true;
                            if ((v14) and (v16)) then
                                SoundModule_upv_1:PlaySound(v5, nil, v15);
                            elseif (v14) then
                                SoundModule_upv_1:PlaySound(v5);
                            elseif (v16) then
                                SoundModule_upv_1:ChangeSoundSpeed(v5, v15);
                            end;
                        end;
                    elseif (v5.IsPlaying) then
                        SoundModule_upv_1:StopSound(v5);
                    end;
                end;
                u9 = v12;
            end;
        end;
        return;
    end;
    if (u9) then
        SoundModule_upv_1:ToggleFootstep(u1);
        u9 = nil;
    end;
end;
local function u20()
    --[[
      line: 250
      upvalues:
        Humanoid_upv_1 (ref,  index: 1)
        StateController_upv_1 (ref,  index: 2)
        WaterController_upv_1 (ref,  index: 3)
        PreferredInputController_upv_1 (copy, index: 4)
        WheelController_upv_1 (ref,  index: 5)
        InventoryController_upv_1 (ref,  index: 6)
        TeamNavigationController_upv_1 (ref,  index: 7)
        u8 (ref,  index: 8)
        tbl_upv_1 (ref,  index: 9)
        u19 (copy, index: 10)
    ]]
    if (not Humanoid_upv_1 or not Humanoid_upv_1.Parent or not StateController_upv_1 or not StateController_upv_1.Parent or not WaterController_upv_1 or not WaterController_upv_1.Parent) then
        return;
    end;
    if (Humanoid_upv_1:GetAttribute("Downed")) then
        return "Down";
    else
        local v17 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
        if (v17) then
            v17 = (WheelController_upv_1 and (WheelController_upv_1:GetAttribute("Open"))) or ((InventoryController_upv_1 and (InventoryController_upv_1:GetAttribute("Open"))) or (TeamNavigationController_upv_1 and (TeamNavigationController_upv_1:GetAttribute("MapOpen"))));
        end;
        local v18, v19, v20, v21, v22 = nil, nil, nil, nil, nil;
        if (v17) then
            if (u8 and u8 ~= "Idle") then
                v19 = tbl_upv_1[u8];
                if (v19) then
                    u8 = "";
                    v19:Stop();
                end;
            end;
            v18 = tbl_upv_1.Idle;
            if (v18 and v18.IsPlaying == false) then
                v18:Play();
                u8 = "Idle";
            end;
            u19("Idle");
        else
            local v23 = StateController_upv_1:GetAttributes();
            local v24 = ((v23.IsCrouch) and "Crouch") or "";
            v19 = v24 .. (((v23.IsSprint) and "Sprint") or "") .. v23.Direction;
            v20 = Humanoid_upv_1.SeatPart;
            local v25 = nil;
            if (v20 == nil) then
                if (v19 == "Crouch") then
                    v19 = "CrouchIdle";
                end;
                local v26 = string.find(v19, "Left");
                local v27 = string.find(v19, "Right");
                if (v19 == "") then
                    v19 = "Idle";
                elseif (string.find(v19, "Sprint")) then
                    v19 = "Sprint" .. ((v26 and "Left") or ((v27 and "Right") or ""));
                else
                    v19 = (v26 and "Left") or ((v27 and "Right") or v19);
                end;
                v25 = WaterController_upv_1:GetAttribute("IsSwim");
                if (v25) then
                    v19 = ((v19 ~= "Idle") and "Swim") or "SwimIdle";
                end;
            else
                v19 = "Sit";
            end;
            if (u8 ~= v19) then
                v21 = tbl_upv_1[u8];
                if (v21) then
                    u8 = "";
                    v21:Stop();
                end;
            end;
            v21 = tbl_upv_1[v19];
            if (v21 and v21.IsPlaying == false) then
                v21:Play();
                u8 = v19;
            end;
            if (v19 == "Sit" and v20 ~= nil and v20.Name == "VehicleSeat" and v20:FindFirstAncestor("Salvaged Flycopter")) then
                v22 = tbl_upv_1.SitPilot;
                if (v22 and v22.IsPlaying == false) then
                    v22:Play();
                    u8 = "SitPilot";
                end;
            elseif (u8 == "Sit" and v19 ~= "Sit") then
                v22 = tbl_upv_1.SitPilot;
                if (v22) then
                    u8 = "";
                    v22:Stop();
                end;
            end;
            u19(v19);
        end;
    end;
end;
local u21 = false;
local function u22(a1, a2)
    --[[
      line: 93
      upvalues:
        TweenService_upv_1 (copy, index: 1)
    ]]
    local tbl_5 = {};
    tbl_5.CFrame = a1;
    TweenService_upv_1:Create(workspace.CurrentCamera, TweenInfo.new(a2 or 1, Enum.EasingStyle.Bounce), tbl_5):Play();
end;
local function v28(a1)
    --[[
      line: 310
      upvalues:
        u8 (ref,  index: 1)
        u9 (ref,  index: 2)
        u10 (ref,  index: 3)
        u1 (ref,  index: 4)
        UIs_upv_1 (copy, index: 5)
        PlayerGui_upv_1 (copy, index: 6)
        CharacterScripts_upv_1 (copy, index: 7)
        tbl_upv_2 (ref,  index: 8)
        Humanoid_upv_1 (ref,  index: 9)
        CurrentCamera_upv_1 (copy, index: 10)
        u2 (ref,  index: 11)
        SoundModule_upv_1 (copy, index: 12)
        tbl_upv_1 (ref,  index: 13)
        Down_upv_1 (ref,  index: 14)
        Inventory_upv_1 (ref,  index: 15)
        Compass_upv_1 (ref,  index: 16)
        u22 (copy, index: 17)
        HumanoidRootPart_upv_1 (ref,  index: 18)
        u19 (copy, index: 19)
        u21 (ref,  index: 20)
        RunService_upv_1 (copy, index: 21)
        u20 (copy, index: 22)
        InteractController_upv_1 (ref,  index: 23)
        Revive_upv_1 (ref,  index: 24)
        Fill_upv_1 (ref,  index: 25)
        TweenService_upv_1 (copy, index: 26)
        WaterController_upv_1 (ref,  index: 27)
        StateController_upv_1 (ref,  index: 28)
        WheelController_upv_1 (ref,  index: 29)
        InventoryController_upv_1 (ref,  index: 30)
        TeamNavigationController_upv_1 (ref,  index: 31)
        u6 (copy, index: 32)
    ]]
    u8 = "";
    u9 = nil;
    u10 = false;
    u1 = a1;
    while (true) do
        local Main_1 = UIs_upv_1:FindFirstChild("Main");
        if (not (Main_1)) then
            task.wait();
            continue;
        end;
        local Loading_1 = UIs_upv_1:FindFirstChild("Loading");
        if (Loading_1) then
            break;
        end;
        task.wait();
    end;
    for _, value_1 in pairs(UIs_upv_1:GetChildren()) do
        value_1:Clone().Parent = PlayerGui_upv_1;
    end;
    while (true) do
        local v29;
        v29 = CharacterScripts_upv_1:GetChildren();
        if (#v29 >= 14) then
            break;
        end;
        task.wait();
    end;
    local v30 = nil;
    local _ = nil;
    for v41, value_2 in pairs(v29) do
        value_2:Clone().Parent = a1;
    end;
    for v42, value_3 in pairs(tbl_upv_2) do
        value_3:Disconnect();
    end;
    tbl_upv_2 = {};
    Humanoid_upv_1 = a1:WaitForChild("Humanoid");
    CurrentCamera_upv_1.CameraType = Enum.CameraType.Custom;
    CurrentCamera_upv_1.CameraSubject = Humanoid_upv_1;
    table.insert(
        tbl_upv_2,
        Humanoid_upv_1:GetAttributeChangedSignal("Downed"):Connect(
            function()
                --[[
                  line: 348
                  upvalues:
                    u2 (ref,  index: 1)
                    Humanoid_upv_1 (ref,  index: 2)
                    u9 (ref,  index: 3)
                    SoundModule_upv_1 (copy, index: 4)
                    u8 (ref,  index: 5)
                    tbl_upv_1 (ref,  index: 6)
                    Down_upv_1 (ref,  index: 7)
                    Inventory_upv_1 (ref,  index: 8)
                    Compass_upv_1 (ref,  index: 9)
                    CurrentCamera_upv_1 (copy, index: 10)
                    u22 (copy, index: 11)
                    HumanoidRootPart_upv_1 (ref,  index: 12)
                ]]
                if (u2) then
                    local v31, v32 = nil, nil;
                    if (u2.Parent) then
                        v31 = Humanoid_upv_1:GetAttribute("Downed");
                        if (v31) then
                            if (u9) then
                                SoundModule_upv_1:StopSound(u9);
                                u9 = nil;
                            end;
                            if (u8) then
                                v32 = tbl_upv_1[u8];
                                if (v32) then
                                    u8 = "";
                                    v32:Stop();
                                end;
                            end;
                        end;
                        Down_upv_1.Visible = v31;
                        Inventory_upv_1.Visible = not v31;
                        Compass_upv_1.Visible = not v31;
                        CurrentCamera_upv_1.CameraType = (v31 and (Enum.CameraType.Scriptable)) or (Enum.CameraType.Custom);
                        CurrentCamera_upv_1.CameraSubject = Humanoid_upv_1;
                        local v33, v34, v35, v36 = nil, nil, nil, nil;
                        if (v31) then
                            u22(HumanoidRootPart_upv_1.CFrame * CFrame.new(0, -2.5, 0), 1.2);
                            v33 = tbl_upv_1.DownFall;
                            if (v33 and v33.IsPlaying == false) then
                                v33:Play();
                                u8 = "DownFall";
                            end;
                            task.wait(tbl_upv_1.DownFall.Length);
                            v34 = tbl_upv_1.Down;
                            if (v34 and v34.IsPlaying == false) then
                                v34:Play();
                                u8 = "Down";
                                return;
                            end;
                        else
                            v35 = tbl_upv_1.DownFall;
                            if (v35) then
                                u8 = "";
                                v35:Stop();
                            end;
                            v36 = tbl_upv_1.Down;
                            if (v36) then
                                u8 = "";
                                v36:Stop();
                            end;
                        end;
                    end;
                end;
            end
        )
    );
    table.insert(
        tbl_upv_2,
        Humanoid_upv_1:GetPropertyChangedSignal("FloorMaterial"):Connect(
            function()
                --[[
                  line: 378
                  upvalues:
                    u19 (copy, index: 1)
                    u8 (ref,  index: 2)
                ]]
                u19(u8);
            end
        )
    );
    table.insert(
        tbl_upv_2,
        Humanoid_upv_1:GetPropertyChangedSignal("SeatPart"):Connect(
            function()
                --[[
                  line: 381
                  upvalues:
                    Humanoid_upv_1 (ref,  index: 1)
                    u21 (ref,  index: 2)
                    RunService_upv_1 (copy, index: 3)
                    a1 (copy, index: 4)
                    u20 (copy, index: 5)
                ]]
                local SeatPart_1 = Humanoid_upv_1.SeatPart;
                if ((SeatPart_1) and (SeatPart_1.Parent)) then
                    local u23 = nil;
                    local u24 = 0;
                    u21 = true;
                    RunService_upv_1:BindToRenderStep(
                        "VehicleHideLocalParts",
                        Enum.RenderPriority.Last.Value,
                        function(a2)
                            --[[
                              line: 387
                              upvalues:
                                a1 (copy, index: 1)
                                u21 (ref,  index: 2)
                                RunService_upv_1 (copy, index: 3)
                                u23 (ref,  index: 4)
                                u24 (ref,  index: 5)
                            ]]
                            if (a1.Parent) then
                                if (not (u23) or u24 > 5) then
                                    u24 = 0;
                                    u23 = a1:GetDescendants();
                                end;
                                u24 = u24 + a2;
                                for _, value_4 in u23 do
                                    if (not (value_4:IsA("BasePart"))) then
                                        continue;
                                    end;
                                    if (value_4.Parent) then
                                        value_4.LocalTransparencyModifier = 1;
                                    end;
                                end;
                            elseif (u21) then
                                u21 = false;
                                RunService_upv_1:UnbindFromRenderStep("VehicleHideLocalParts");
                            end;
                        end
                    );
                elseif (u21) then
                    RunService_upv_1:UnbindFromRenderStep("VehicleHideLocalParts");
                    u21 = false;
                end;
                u20();
            end
        )
    );
    if (u21) then
        RunService_upv_1:UnbindFromRenderStep("VehicleHideLocalParts");
        u21 = false;
    end;
    local v43 = {};
    HumanoidRootPart_upv_1 = a1:WaitForChild("HumanoidRootPart");
    InteractController_upv_1 = a1:WaitForChild("InteractController");
    table.insert(
        tbl_upv_2,
        InteractController_upv_1:GetAttributeChangedSignal("Reviving"):Connect(
            function()
                --[[
                  line: 423
                  upvalues:
                    u2 (ref,  index: 1)
                    InteractController_upv_1 (ref,  index: 2)
                    u10 (ref,  index: 3)
                    Revive_upv_1 (ref,  index: 4)
                    Fill_upv_1 (ref,  index: 5)
                    TweenService_upv_1 (copy, index: 6)
                ]]
                if (not u2) then
                    return;
                end;
                if (u2.Parent) then
                    local v37 = InteractController_upv_1:GetAttribute("Reviving");
                    local _ = InteractController_upv_1:GetAttribute("ReviveStart");
                    if (u10 and not (v37)) then
                        u10 = false;
                        Revive_upv_1.Visible = false;
                        return;
                    end;
                    if (v37 and not (u10)) then
                        u10 = true;
                        Fill_upv_1.Size = UDim2.new(0, 0, 1, 0);
                        local v38 = TweenService_upv_1:Create(Fill_upv_1, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 1, 0)});
                        v38:Play();
                        Revive_upv_1.Visible = true;
                        repeat
                            repeat
                                wait();
                            until (not (u10));
                        until (tick() - InteractController_upv_1:GetAttribute("ReviveStart") < 4);
                        v38:Cancel();
                    end;
                end;
            end
        )
    );
    WaterController_upv_1 = a1:WaitForChild("WaterController");
    table.insert(tbl_upv_2, WaterController_upv_1:GetAttributeChangedSignal("IsSwim"):Connect(u20));
    table.insert(
        tbl_upv_2,
        WaterController_upv_1:GetAttributeChangedSignal("InWater"):Connect(
            function()
                --[[
                  line: 449
                  upvalues:
                    u19 (copy, index: 1)
                    u8 (ref,  index: 2)
                ]]
                u19(u8);
            end
        )
    );
    table.insert(tbl_upv_2, WaterController_upv_1:GetAttributeChangedSignal("IsUnder"):Connect(function()
        --[[
          line: 452
        ]]
    end));
    StateController_upv_1 = a1:WaitForChild("StateController");
    table.insert(tbl_upv_2, StateController_upv_1:GetAttributeChangedSignal("Direction"):Connect(u20));
    table.insert(tbl_upv_2, StateController_upv_1:GetAttributeChangedSignal("IsSprint"):Connect(u20));
    table.insert(tbl_upv_2, StateController_upv_1:GetAttributeChangedSignal("IsCrouch"):Connect(u20));
    WheelController_upv_1 = a1:WaitForChild("WheelController");
    table.insert(tbl_upv_2, WheelController_upv_1:GetAttributeChangedSignal("Open"):Connect(u20));
    InventoryController_upv_1 = a1:WaitForChild("InventoryController");
    table.insert(tbl_upv_2, InventoryController_upv_1:GetAttributeChangedSignal("Open"):Connect(u20));
    TeamNavigationController_upv_1 = a1:WaitForChild("TeamNavigationController");
    table.insert(tbl_upv_2, TeamNavigationController_upv_1:GetAttributeChangedSignal("MapOpen"):Connect(u20));
    RunService_upv_1.Stepped:Wait();
    if (not Humanoid_upv_1) then
        return;
    end;
    if (Humanoid_upv_1.Parent) then
        local v39 = nil;
        local v44 = nil;
        for v45, value_upv_5 in pairs(u6) do
            v39 = os.clock();
            while (true) do
                local success_1, v40 = pcall(
                    function()
                        --[[
                          line: 473
                          upvalues:
                            tbl_upv_1 (ref,  index: 1)
                            value_upv_5 (copy, index: 2)
                            Humanoid_upv_1 (ref,  index: 3)
                        ]]
                        tbl_upv_1[value_upv_5.Name] = Humanoid_upv_1:LoadAnimation(value_upv_5);
                    end
                );
                if (success_1) then
                    break;
                end;
                if (os.clock() - v39 < 0.5) then
                    RunService_upv_1.Stepped:Wait();
                    continue;
                else
                    warn("Failed to load animation", value_upv_5, v40);
                    break;
                end;
            end;
        end;
        v30 = tbl_upv_1.Idle;
        if (not v30 or v30.IsPlaying ~= false) then
            return;
        end;
        v30:Play();
        u8 = "Idle";
    end;
end;
local function u25(a1)
    --[[
      line: 488
      upvalues:
        u2 (ref,  index: 1)
        Death_upv_1 (ref,  index: 2)
        Footer_upv_1 (ref,  index: 3)
        Humanoid_upv_1 (ref,  index: 4)
        u11 (ref,  index: 5)
        u5 (copy, index: 6)
        GamepadSelected_upv_1 (ref,  index: 7)
        GamepadIconModule_upv_1 (copy, index: 8)
        PreferredInputController_upv_1 (copy, index: 9)
        u12 (ref,  index: 10)
        UserInputService_upv_1 (copy, index: 11)
        GamepadControls_upv_1 (ref,  index: 12)
        DeathBar_upv_1 (ref,  index: 13)
        Fill_upv_2 (ref,  index: 14)
        ImageLabel_upv_1 (ref,  index: 15)
        RespawnLabel_upv_1 (ref,  index: 16)
        u3 (ref,  index: 17)
        u4 (ref,  index: 18)
        TweenUtil_upv_1 (copy, index: 19)
        LocalPlayer_upv_1 (copy, index: 20)
        Inventory_upv_1 (ref,  index: 21)
        Toolbar_upv_1 (ref,  index: 22)
        Down_upv_1 (ref,  index: 23)
        Background_upv_1 (ref,  index: 24)
        Header_upv_1 (ref,  index: 25)
        Compass_upv_1 (ref,  index: 26)
        Stats_upv_1 (ref,  index: 27)
        Map_upv_1 (ref,  index: 28)
        Blood_upv_1 (ref,  index: 29)
        Revive_upv_1 (ref,  index: 30)
        Fill_upv_1 (ref,  index: 31)
    ]]
    if (not a1:IsA("ScreenGui")) then
        return;
    end;
    if (a1.Name == "Main") then
        u2 = a1;
        Death_upv_1 = u2:WaitForChild("Death");
        Footer_upv_1 = Death_upv_1:WaitForChild("Footer");
        local v41 = nil;
        for GetVisibleDeathButtons_upv_1, UpdateGamepadDeathSelection_upv_1 in pairs(Footer_upv_1:GetChildren()) do
            v41 = UpdateGamepadDeathSelection_upv_1:IsA("TextButton");
            if (v41) then
                UpdateGamepadDeathSelection_upv_1.MouseButton1Click:Connect(
                    function()
                        --[[
                          line: 499
                          upvalues:
                            Humanoid_upv_1 (ref,  index: 1)
                            u11 (ref,  index: 2)
                            u5 (copy, index: 3)
                            UpdateGamepadDeathSelection_upv_1 (copy, index: 4)
                        ]]
                        if (Humanoid_upv_1.Health > 0) then
                            return;
                        end;
                        if (os.clock() - u11 > 0.2) then
                            u11 = os.clock();
                            Humanoid_upv_1:SetAttribute("AttemptRespawn", true);
                            local v42 = UpdateGamepadDeathSelection_upv_1:GetAttribute("Index") or (tonumber(UpdateGamepadDeathSelection_upv_1.Name));
                            u5("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "1\237\127\136\235\021i\148\247&\252\249\001\151\030Q}\144\006\250", v42);
                        end;
                    end
                );
            end;
        end;
        GamepadSelected_upv_1 = Footer_upv_1:WaitForChild("00"):WaitForChild("GamepadSelected");
        GamepadSelected_upv_1.Visible = false;
        GamepadIconModule_upv_1.Register(GamepadSelected_upv_1.ImageLabel, "ButtonA");
        local function getDeadzone_1()
            --[[
              name: getDeadzone
              line: 516
              upvalues:
                PreferredInputController_upv_1 (copy, index: 1)
            ]]
            return PreferredInputController_upv_1:GetAttribute("JoystickDeadzone") or 0.225;
        end;
        local u26 = 0;
        local u27 = false;
        local function GetVisibleDeathButtons_upv_1()
            --[[
              name: GetVisibleDeathButtons
              line: 520
              upvalues:
                Footer_upv_1 (ref, index: 1)
            ]]
            local tbl_6 = {};
            for _, value_6 in Footer_upv_1:GetChildren() do
                if (not (value_6:IsA("TextButton"))) then
                    continue;
                end;
                if (value_6.Visible) then
                    table.insert(tbl_6, value_6);
                end;
            end;
            table.sort(
                tbl_6,
                function(a2, a3)
                    --[[
                      line: 527
                    ]]
                    return a2.Name < a3.Name;
                end
            );
            return tbl_6;
        end;
        local function UpdateGamepadDeathSelection_upv_1(a4)
            --[[
              name: UpdateGamepadDeathSelection
              line: 531
              upvalues:
                GamepadSelected_upv_1 (ref,  index: 1)
                u12 (ref,  index: 2)
                PreferredInputController_upv_1 (copy, index: 3)
                GamepadIconModule_upv_1 (copy, index: 4)
            ]]
            local v43 = nil;
            if (GamepadSelected_upv_1) then
                v43 = a4[u12 + 1];
            end;
            if (GamepadSelected_upv_1 and v43) then
                GamepadSelected_upv_1.Parent = v43;
                GamepadSelected_upv_1.Visible = PreferredInputController_upv_1 and PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad";
                GamepadSelected_upv_1.ImageLabel.Image = GamepadIconModule_upv_1.GetIcon("ButtonA");
            end;
        end;
        UserInputService_upv_1.InputBegan:Connect(
            function(a5)
                --[[
                  line: 539
                  upvalues:
                    Death_upv_1 (ref,  index: 1)
                    GetVisibleDeathButtons_upv_1 (copy, index: 2)
                    u26 (ref,  index: 3)
                    u12 (ref,  index: 4)
                    GamepadSelected_upv_1 (ref,  index: 5)
                    PreferredInputController_upv_1 (copy, index: 6)
                    GamepadIconModule_upv_1 (copy, index: 7)
                    Humanoid_upv_1 (ref,  index: 8)
                    u11 (ref,  index: 9)
                    u5 (copy, index: 10)
                ]]
                if (not Death_upv_1) then
                    return;
                end;
                if (Death_upv_1.Visible) then
                    local v45 = nil;
                    if (a5.UserInputType == Enum.UserInputType.Gamepad1) then
                        local KeyCode_1 = a5.KeyCode;
                        v45 = GetVisibleDeathButtons_upv_1();
                        if (#v45 == 0) then
                            return;
                        end;
                        if (KeyCode_1 ~= Enum.KeyCode.DPadRight and KeyCode_1 ~= Enum.KeyCode.DPadDown) then
                            if (KeyCode_1 ~= Enum.KeyCode.DPadLeft and KeyCode_1 ~= Enum.KeyCode.DPadUp) then
                                local v46 = nil;
                                if (KeyCode_1 == Enum.KeyCode.ButtonA) then
                                    v46 = v45[u12 + 1];
                                    if (v46) then
                                        if (Humanoid_upv_1.Health > 0) then
                                            return;
                                        end;
                                        if (os.clock() - u11 > 0.2) then
                                            u11 = os.clock();
                                            Humanoid_upv_1:SetAttribute("AttemptRespawn", true);
                                            local v47 = v46:GetAttribute("Index") or (tonumber(v46.Name));
                                            u5("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "1\237\127\136\235\021i\148\247&\252\249\001\151\030Q}\144\006\250", v47);
                                        else
                                            return;
                                        end;
                                    end;
                                end;
                                return;
                            end;
                            if (os.clock() - u26 >= 0.15) then
                                u26 = os.clock();
                                u12 = (u12 + 1) % #v45;
                                local v48 = nil;
                                if (GamepadSelected_upv_1) then
                                    v48 = v45[u12 + 1];
                                end;
                                if (GamepadSelected_upv_1 and v48) then
                                    GamepadSelected_upv_1.Parent = v48;
                                    GamepadSelected_upv_1.Visible = PreferredInputController_upv_1 and PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad";
                                    GamepadSelected_upv_1.ImageLabel.Image = GamepadIconModule_upv_1.GetIcon("ButtonA");
                                end;
                            end;
                            return;
                        end;
                        if (os.clock() - u26 >= 0.15) then
                            u26 = os.clock();
                            u12 = (u12 - 1) % #v45;
                            local v50 = nil;
                            if (GamepadSelected_upv_1) then
                                v50 = v45[u12 + 1];
                            end;
                            if (GamepadSelected_upv_1 and v50) then
                                GamepadSelected_upv_1.Parent = v50;
                                GamepadSelected_upv_1.Visible = PreferredInputController_upv_1 and PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad";
                                GamepadSelected_upv_1.ImageLabel.Image = GamepadIconModule_upv_1.GetIcon("ButtonA");
                            end;
                        end;
                    end;
                end;
            end
        );
        UserInputService_upv_1.InputChanged:Connect(
            function(a6)
                --[[
                  line: 570
                  upvalues:
                    Death_upv_1 (ref,  index: 1)
                    GetVisibleDeathButtons_upv_1 (copy, index: 2)
                    PreferredInputController_upv_1 (copy, index: 3)
                    u27 (ref,  index: 4)
                    u12 (ref,  index: 5)
                    GamepadSelected_upv_1 (ref,  index: 6)
                    GamepadIconModule_upv_1 (copy, index: 7)
                ]]
                if (not Death_upv_1 or not Death_upv_1.Visible) then
                    return;
                end;
                if (a6.UserInputType == Enum.UserInputType.Gamepad1) then
                    local v52 = nil;
                    if (a6.KeyCode == Enum.KeyCode.Thumbstick1) then
                        local X_1 = a6.Position.X;
                        local Y_1 = a6.Position.Y;
                        v52 = GetVisibleDeathButtons_upv_1();
                        local v53;
                        if (#v52 == 0) then
                            return;
                        end;
                        v53 = PreferredInputController_upv_1:GetAttribute("JoystickDeadzone") or 0.225;
                        if (v53 >= math.abs(X_1) and v53 >= math.abs(Y_1)) then
                            u27 = false;
                            return;
                        end;
                        if (not u27) then
                            u27 = true;
                            if (v53 < X_1 or Y_1 < -v53) then
                                u12 = (u12 - 1) % #v52;
                            else
                                u12 = (u12 + 1) % #v52;
                            end;
                            local v54 = nil;
                            if (GamepadSelected_upv_1) then
                                v54 = v52[u12 + 1];
                            end;
                            if (GamepadSelected_upv_1 and v54) then
                                GamepadSelected_upv_1.Parent = v54;
                                GamepadSelected_upv_1.Visible = PreferredInputController_upv_1 and PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad";
                                GamepadSelected_upv_1.ImageLabel.Image = GamepadIconModule_upv_1.GetIcon("ButtonA");
                            end;
                        end;
                    end;
                end;
            end
        );
        PreferredInputController_upv_1:GetAttributeChangedSignal("PreferredInput"):Connect(
            function()
                --[[
                  line: 596
                  upvalues:
                    Death_upv_1 (ref,  index: 1)
                    GetVisibleDeathButtons_upv_1 (copy, index: 2)
                    GamepadSelected_upv_1 (ref,  index: 3)
                    u12 (ref,  index: 4)
                    PreferredInputController_upv_1 (copy, index: 5)
                    GamepadIconModule_upv_1 (copy, index: 6)
                ]]
                if (not Death_upv_1) then
                    return;
                end;
                if (Death_upv_1.Visible) then
                    local v56 = GetVisibleDeathButtons_upv_1();
                    local v57 = nil;
                    if (GamepadSelected_upv_1) then
                        v57 = v56[u12 + 1];
                    end;
                    if (GamepadSelected_upv_1 and v57) then
                        GamepadSelected_upv_1.Parent = v57;
                        GamepadSelected_upv_1.Visible = PreferredInputController_upv_1 and PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad";
                        GamepadSelected_upv_1.ImageLabel.Image = GamepadIconModule_upv_1.GetIcon("ButtonA");
                    end;
                end;
            end
        );
        GamepadControls_upv_1 = a1:WaitForChild("GamepadControls");
        DeathBar_upv_1 = GamepadControls_upv_1:WaitForChild("DeathBar");
        Fill_upv_2 = DeathBar_upv_1:WaitForChild("Bar"):WaitForChild("Fill");
        ImageLabel_upv_1 = DeathBar_upv_1:WaitForChild("ImageLabel");
        RespawnLabel_upv_1 = GamepadControls_upv_1:WaitForChild("RespawnLabel");
        local u28 = UDim2.new(0.153, 0, 2.03, 0);
        local u29 = UDim2.new(0.13, 0, 1.73, 0);
        local u30 = UDim2.new(0.18, 0, 2.4, 0);
        local u31 = UDim2.new(0.236, 0, 0.0275, 0);
        local u32 = UDim2.new(0.21, 0, 0.025, 0);
        local u33 = 0;
        u3 = function()
            --[[
              line: 616
              upvalues:
                u4 (ref,  index: 1)
                DeathBar_upv_1 (ref,  index: 2)
                Fill_upv_2 (ref,  index: 3)
                ImageLabel_upv_1 (ref,  index: 4)
                u28 (copy, index: 5)
                RespawnLabel_upv_1 (ref,  index: 6)
                Humanoid_upv_1 (ref,  index: 7)
                PreferredInputController_upv_1 (copy, index: 8)
            ]]
            u4 = false;
            DeathBar_upv_1.Visible = false;
            Fill_upv_2.Size = UDim2.new(0, 0, 1, 0);
            ImageLabel_upv_1.Size = u28;
            RespawnLabel_upv_1.Visible = Humanoid_upv_1:GetAttribute("Downed") and PreferredInputController_upv_1 and PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad";
        end;
        Humanoid_upv_1:GetAttributeChangedSignal("Downed"):Connect(
            function()
                --[[
                  line: 625
                  upvalues:
                    Humanoid_upv_1 (ref,  index: 1)
                    RespawnLabel_upv_1 (ref,  index: 2)
                    PreferredInputController_upv_1 (copy, index: 3)
                    u4 (ref,  index: 4)
                    u3 (ref,  index: 5)
                ]]
                local v60 = Humanoid_upv_1:GetAttribute("Downed");
                local v61;
                if (v60) then
                    v61 = PreferredInputController_upv_1;
                    if (v61) then
                        if (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad") then
                            local v62 = true;
                            v61, v61 = v62, v62;
                        else
                            local v63 = false;
                            v61, v61 = v63, v63;
                        end;
                    end;
                    if (v61) then
                        v61 = not u4;
                    end;
                else
                    v61 = v60;
                end;
                RespawnLabel_upv_1.Visible = v61;
                if ((v60)) then
                    return;
                end;
                u3();
            end
        );
        PreferredInputController_upv_1:GetAttributeChangedSignal("PreferredInput"):Connect(
            function()
                --[[
                  line: 632
                  upvalues:
                    Humanoid_upv_1 (ref,  index: 1)
                    u4 (ref,  index: 2)
                    RespawnLabel_upv_1 (ref,  index: 3)
                    PreferredInputController_upv_1 (copy, index: 4)
                ]]
                if (not Humanoid_upv_1:GetAttribute("Downed") or (u4)) then
                    return;
                end;
                RespawnLabel_upv_1.Visible = PreferredInputController_upv_1;
            end
        );
        UserInputService_upv_1.InputBegan:Connect(
            function(a7)
                --[[
                  line: 639
                  upvalues:
                    PreferredInputController_upv_1 (copy, index: 1)
                    Death_upv_1 (ref,  index: 2)
                    u4 (ref,  index: 3)
                    RespawnLabel_upv_1 (ref,  index: 4)
                    u33 (ref,  index: 5)
                    DeathBar_upv_1 (ref,  index: 6)
                    u32 (copy, index: 7)
                    TweenUtil_upv_1 (copy, index: 8)
                    u31 (copy, index: 9)
                    Fill_upv_2 (ref,  index: 10)
                    ImageLabel_upv_1 (ref,  index: 11)
                    u29 (copy, index: 12)
                    Humanoid_upv_1 (ref,  index: 13)
                    u3 (ref,  index: 14)
                    u28 (copy, index: 15)
                    u30 (copy, index: 16)
                    LocalPlayer_upv_1 (copy, index: 17)
                ]]
                if (a7.UserInputType ~= Enum.UserInputType.Gamepad1) then
                    return;
                end;
                if (a7.KeyCode == Enum.KeyCode.ButtonR3) then
                    local v64 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                    if (not v64) then
                        return;
                    end;
                    if ((not Death_upv_1 or not Death_upv_1.Visible) and not u4) then
                        u4 = true;
                        RespawnLabel_upv_1.Visible = true;
                        u33 = os.clock();
                        DeathBar_upv_1.Size = u32;
                        DeathBar_upv_1.Visible = true;
                        TweenUtil_upv_1:Tween(DeathBar_upv_1, "Size", u31, 0.3, "Back", "Out");
                        Fill_upv_2.Size = UDim2.new(0, 0, 1, 0);
                        ImageLabel_upv_1.Size = u29;
                        task.spawn(
                            function()
                                --[[
                                  line: 655
                                  upvalues:
                                    u4 (ref,  index: 1)
                                    Humanoid_upv_1 (ref,  index: 2)
                                    u3 (ref,  index: 3)
                                    u33 (ref,  index: 4)
                                    Fill_upv_2 (ref,  index: 5)
                                    u29 (copy, index: 6)
                                    u28 (copy, index: 7)
                                    ImageLabel_upv_1 (ref,  index: 8)
                                    TweenUtil_upv_1 (copy, index: 9)
                                    u30 (copy, index: 10)
                                    LocalPlayer_upv_1 (copy, index: 11)
                                ]]
                                while (true) do
                                    local _, v65 = nil, nil;
                                    if (not (u4)) then
                                        break;
                                    end;
                                    if (Humanoid_upv_1.Health > 0 or Humanoid_upv_1:GetAttribute("Downed")) then
                                        v65 = math.clamp((os.clock() - u33) / 3, 0, 1);
                                        Fill_upv_2.Size = UDim2.new(v65, 0, 1, 0);
                                        ImageLabel_upv_1.Size = UDim2.new(u29.X.Scale + ((u28.X.Scale - u29.X.Scale) * v65), 0, u29.Y.Scale + ((u28.Y.Scale - u29.Y.Scale) * v65), 0);
                                        if (v65 < 1) then
                                            task.wait();
                                            continue;
                                        end;
                                        TweenUtil_upv_1:Tween(ImageLabel_upv_1, "Size", u30, 0.15, "Back", "Out");
                                        task.wait(0.15);
                                        TweenUtil_upv_1:Tween(ImageLabel_upv_1, "Size", u28, 0.1, "Quad", "In");
                                        task.wait(0.1);
                                        local TextChatService_1 = game:GetService("TextChatService");
                                        local u34 = TextChatService_1:FindFirstChild("TextChannels") and (TextChatService_1.TextChannels:FindFirstChild("WHISPER/" .. LocalPlayer_upv_1.UserId));
                                        if (u34) then
                                            pcall(
                                                function()
                                                    --[[
                                                      line: 677
                                                      upvalues:
                                                        u34 (copy, index: 1)
                                                    ]]
                                                    u34:SendAsync("/kill");
                                                end
                                            );
                                        end;
                                        u3();
                                        return;
                                    end;
                                    u3();
                                    return;
                                end;
                            end
                        );
                    end;
                end;
            end
        );
        UserInputService_upv_1.InputEnded:Connect(
            function(a8)
                --[[
                  line: 689
                  upvalues:
                    u4 (ref, index: 1)
                    u3 (ref, index: 2)
                ]]
                if (a8.UserInputType ~= Enum.UserInputType.Gamepad1 or a8.KeyCode ~= Enum.KeyCode.ButtonR3) then
                    return;
                end;
                if (u4) then
                    u3();
                end;
            end
        );
        Inventory_upv_1 = a1:WaitForChild("Inventory");
        Toolbar_upv_1 = a1:WaitForChild("Toolbar");
        Down_upv_1 = a1:WaitForChild("Down");
        Background_upv_1 = Death_upv_1:WaitForChild("Background");
        Header_upv_1 = Death_upv_1:WaitForChild("Header");
        Compass_upv_1 = a1:WaitForChild("Compass");
        Stats_upv_1 = a1:WaitForChild("Stats");
        Map_upv_1 = a1:WaitForChild("Map");
        Blood_upv_1 = a1:WaitForChild("Blood");
        Revive_upv_1 = a1:WaitForChild("Revive");
        Fill_upv_1 = Revive_upv_1:WaitForChild("Fill");
    end;
end;
u5(
    "Setup",
    "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145",
    "\223\f\217\134\022\160\235-\184\154%)\166\202\182\001X\253{\023",
    function(a1, a2, a3)
        --[[
          line: 720
          upvalues:
            Values_upv_1 (copy, index: 1)
            u5 (copy, index: 2)
            NumberUtil_upv_1 (copy, index: 3)
            Items_upv_1 (copy, index: 4)
            Header_upv_1 (ref,  index: 5)
            UserService_upv_1 (copy, index: 6)
            Players_upv_1 (copy, index: 7)
            Footer_upv_1 (ref,  index: 8)
            Map_upv_1 (ref,  index: 9)
            u7 (copy, index: 10)
            TweenUtil_upv_1 (copy, index: 11)
            u11 (ref,  index: 12)
            Humanoid_upv_1 (ref,  index: 13)
            UserInputService_upv_1 (copy, index: 14)
            CurrentCamera_upv_1 (copy, index: 15)
            HumanoidRootPart_upv_1 (ref,  index: 16)
            u22 (copy, index: 17)
            Death_upv_1 (ref,  index: 18)
            GamepadControls_upv_1 (ref,  index: 19)
            RespawnLabel_upv_1 (ref,  index: 20)
            u3 (ref,  index: 21)
            u12 (ref,  index: 22)
            GamepadSelected_upv_1 (ref,  index: 23)
            PreferredInputController_upv_1 (copy, index: 24)
            GamepadIconModule_upv_1 (copy, index: 25)
            Down_upv_1 (ref,  index: 26)
            Inventory_upv_1 (ref,  index: 27)
            Toolbar_upv_1 (ref,  index: 28)
            Compass_upv_1 (ref,  index: 29)
            Stats_upv_1 (ref,  index: 30)
            Background_upv_1 (ref,  index: 31)
            u15 (copy, index: 32)
        ]]
        if (Values_upv_1.InstantRespawn.Value) then
            task.wait(2);
            u5("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "1\237\127\136\235\021i\148\247&\252\249\001\151\030Q}\144\006\250", 0);
        else
            local v66 = NumberUtil_upv_1:FormatTime(a1 or 0, "Days", "Minutes", true);
            local v67;
            v67 = nil;
            local v68 = nil;
            if (type(a2) == "number") then
                v68 = Items_upv_1[a2];
                if (v68) then
                    v67 = v68.Name;
                    local KillerWeapon_1 = Header_upv_1.KillerWeapon;
                    local v69 = type(v68.Image) == "table" and v68.Image.Default or v68.Image;
                    KillerWeapon_1.Image = v69;
                    Header_upv_1.KillerWeapon.Visible = true;
                    Header_upv_1.KillerDetail.Visible = true;
                end;
            end;
            local v70 = v67 or (a2 or "Unknown");
            local v71 = nil;
            local success_2, v72;
            if (type(a3) ~= "number") then
                v72 = v71;
            else
                local success_2, v73 = pcall(
                    function()
                        --[[
                          line: 746
                          upvalues:
                            UserService_upv_1 (copy, index: 1)
                            a3 (copy, index: 2)
                        ]]
                        return UserService_upv_1:GetUserInfosByUserIdsAsync({a3});
                    end
                );
                if (success_2) then
                    local v74 = nil;
                    if (v73) then
                        v74 = v73[1];
                    end;
                    if (v73 and v74) then
                        task.defer(
                            function()
                                --[[
                                  line: 752
                                  upvalues:
                                    Players_upv_1 (copy, index: 1)
                                    a3 (copy, index: 2)
                                    Header_upv_1 (ref,  index: 3)
                                ]]
                                local v75 = Players_upv_1:GetUserThumbnailAsync(a3, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size352x352);
                                Header_upv_1.KillerCharacter.Image = v75;
                                Header_upv_1.Visible = v75 ~= nil;
                            end
                        );
                        local v76 = ((not (v74.HasVerifiedBadge)) and "") or (utf8.char(57344));
                        if (v74.DisplayName ~= v74.Username) then
                            v72 = ("%*%*(@%*)"):format(v74.DisplayName, v76, v74.Username);
                        else
                            v72 = ("@%*%*"):format(v74.Username, v76);
                        end;
                    else
                        v72 = v71;
                    end;
                else
                    v72 = v71;
                end;
            end;
            Header_upv_1.KillerName.Text = v72 or v70;
            Header_upv_1.AliveFor.Text = v66;
            local Beds_upv_1 = shared.Beds;
            local v69 = 0;
            local v78 = nil;
            local v79 = nil;
            local u35 = nil;
            local Default_1 = nil;
            local value_upv_7 = nil;
            local v80 = nil;
            local v81 = nil;
            for key_1, value_upv_7 in pairs(Beds_upv_1) do
                v79 = Items_upv_1[value_upv_7.ID];
                u35 = (((key_1 > 9) and "") or "0") .. key_1;
                v80 = Footer_upv_1:FindFirstChild(u35);
                if (not (v80)) then
                    continue;
                end;
                v78 = value_upv_7.Name;
                if (not (v78)) then
                    warn("BED NAME NOT FOUND FOR", key_1);
                    v78 = "Unnamed Bag";
                end;
                Default_1 = v79.Image.Default;
                v80.ImageLabel.Image = Default_1;
                v80.TextLabel.Text = v78;
                v80:SetAttribute("Index", value_upv_7.Index);
                v80.Visible = true;
                v81 = value_upv_7.Position;
                if (v81) then
                    local u36 = Map_upv_1.Frame.Map.BedTemplate:Clone();
                    u36.Name = "Bed" .. u35;
                    local v82 = ((typeof(v81) == "Vector3") and (v81.Z)) or (v81.Y);
                    u36.Position = UDim2.new(0.5 + ((v81.X - u7.X) / 12800), 0, 0.5 + ((v82 - u7.Y) / 12800), 0);
                    u36.Image = Default_1;
                    u36.BedImage.Image = Default_1;
                    u36.BedName.Text = v78;
                    u36.Parent = Map_upv_1.Frame.Map;
                    u36.Visible = true;
                    u36.MouseEnter:Connect(
                        function()
                            --[[
                              line: 794
                              upvalues:
                                u36 (copy, index: 1)
                                TweenUtil_upv_1 (copy, index: 2)
                            ]]
                            u36.ZIndex = 7;
                            TweenUtil_upv_1:Tween(u36.BedName, {"TextTransparency", "Position"}, {0, UDim2.new(0.5, 0, 0, 0)}, 0.25, "Quart", "Out");
                        end
                    );
                    u36.MouseLeave:Connect(
                        function()
                            --[[
                              line: 798
                              upvalues:
                                u36 (copy, index: 1)
                                TweenUtil_upv_1 (copy, index: 2)
                            ]]
                            u36.ZIndex = 3;
                            TweenUtil_upv_1:Tween(u36.BedName, {"TextTransparency", "Position"}, {1, UDim2.new(0.5, 0, 0.25, 0)}, 0.25, "Quart", "In");
                        end
                    );
                    u36.Activated:Connect(
                        function()
                            --[[
                              line: 802
                              upvalues:
                                u11 (ref,  index: 1)
                                Humanoid_upv_1 (ref,  index: 2)
                                u5 (copy, index: 3)
                                value_upv_7 (copy, index: 4)
                                u35 (copy, index: 5)
                            ]]
                            if (os.clock() - u11 > 0.2) then
                                u11 = os.clock();
                                Humanoid_upv_1:SetAttribute("AttemptRespawn", true);
                                local v83 = value_upv_7.Index or (tonumber(u35));
                                u5("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "1\237\127\136\235\021i\148\247&\252\249\001\151\030Q}\144\006\250", v83);
                            end;
                        end
                    );
                end;
                v69 = v69 + 1;
            end;
            local Grid_1 = Footer_upv_1.Grid;
            Grid_1.CellSize = UDim2.new(0.19, 0, ((v69 <= 4) and 0.6) or 0.4, 0);
            Footer_upv_1.Size = UDim2.new(1, 0, ((v69 <= 4) and 0.08) or 0.12, 0);
            local u37 = false;
            task.defer(
                function()
                    --[[
                      line: 816
                      upvalues:
                        Footer_upv_1 (ref,  index: 1)
                        Beds_upv_1 (copy, index: 2)
                        Values_upv_1 (copy, index: 3)
                        Map_upv_1 (ref,  index: 4)
                        u37 (ref,  index: 5)
                        UserInputService_upv_1 (copy, index: 6)
                    ]]
                    while (Footer_upv_1 and (Footer_upv_1.Parent)) do
                        local v84, v85, v86 = nil, nil, nil;
                        if (Footer_upv_1 ~= Footer_upv_1) then
                            break;
                        end;
                        local v87 = nil;
                        local v88 = nil;
                        for key_2, value_8 in pairs(Beds_upv_1) do
                            v87 = (((key_2 > 9) and "") or "0") .. key_2;
                            v84 = math.max(value_8.BedTimer - (Values_upv_1.ServerOS.Value - (value_8.LastRespawn or 0)), 0);
                            v88 = Footer_upv_1:FindFirstChild(v87);
                            if (v84 ~= 0) then
                                v86 = Color3.fromRGB(107, 107, 107);
                            else
                                v86 = Color3.fromRGB(255, 255, 255) or Color3.fromRGB(107, 107, 107);
                            end;
                            if (v88) then
                                v88.ImageLabel.ImageColor3 = v86;
                                v88.Timer.Visible = v84 ~= 0;
                                v88.Timer.Text = v84;
                            end;
                            v85 = Map_upv_1.Frame.Map:FindFirstChild("Bed" .. v87);
                            if (v85) then
                                v85.BedImage.ImageColor3 = v86;
                                v85.Timer.Visible = v84 ~= 0;
                                v85.Timer.Text = v84;
                            end;
                        end;
                        if (u37) then
                            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                            UserInputService_upv_1.MouseIconEnabled = true;
                        end;
                        task.wait(0.1);
                    end;
                    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                    UserInputService_upv_1.MouseIconEnabled = false;
                end
            );
            CurrentCamera_upv_1.CameraType = Enum.CameraType.Scriptable;
            if (HumanoidRootPart_upv_1 and HumanoidRootPart_upv_1.Parent) then
                u22(HumanoidRootPart_upv_1.CFrame * CFrame.new(0, -2.5, 0), 1.2);
            end;
            Death_upv_1.Visible = true;
            local v89 = nil;
            if (GamepadControls_upv_1) then
                v89 = GamepadControls_upv_1:FindFirstChild("ToolbarLeft");
                local ToolbarRight_1 = GamepadControls_upv_1:FindFirstChild("ToolbarRight");
                local ToolTip_1 = GamepadControls_upv_1:FindFirstChild("ToolTip");
                if (v89) then
                    v89.Visible = false;
                end;
                if (ToolbarRight_1) then
                    ToolbarRight_1.Visible = false;
                end;
                if (ToolTip_1) then
                    ToolTip_1.Visible = false;
                end;
            end;
            RespawnLabel_upv_1.Visible = false;
            u3();
            u12 = 0;
            if (GamepadSelected_upv_1 and Footer_upv_1) then
                local tbl_7 = {};
                for _, value_9 in Footer_upv_1:GetChildren() do
                    v80 = value_9:IsA("TextButton");
                    if (not (v80)) then
                        continue;
                    end;
                    if (value_9.Visible) then
                        table.insert(tbl_7, value_9);
                    end;
                end;
                table.sort(
                    tbl_7,
                    function(a4, a5)
                        --[[
                          line: 867
                        ]]
                        return a4.Name < a5.Name;
                    end
                );
                if (#tbl_7 > 0 and GamepadSelected_upv_1) then
                    GamepadSelected_upv_1.Parent = tbl_7[1];
                    GamepadSelected_upv_1.Visible = PreferredInputController_upv_1 and PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad";
                    GamepadSelected_upv_1.ImageLabel.Image = GamepadIconModule_upv_1.GetIcon("ButtonA");
                end;
            end;
            Down_upv_1.Visible = false;
            Inventory_upv_1.Visible = false;
            Toolbar_upv_1.Visible = false;
            Compass_upv_1.Visible = false;
            Stats_upv_1.Visible = false;
            task.delay(
                0.5,
                function()
                    --[[
                      line: 879
                      upvalues:
                        HumanoidRootPart_upv_1 (ref,  index: 1)
                        u22 (copy, index: 2)
                    ]]
                    if (not HumanoidRootPart_upv_1 or not HumanoidRootPart_upv_1.Parent) then
                        return;
                    end;
                    u22((HumanoidRootPart_upv_1.CFrame * CFrame.new(0, -2.5, 0)) * CFrame.Angles(0, 0, -0.4363323129985824), 1);
                end
            );
            task.wait(1);
            if (not Background_upv_1.Parent) then
                return;
            end;
            u15(true, 2.5);
            task.wait(2.5);
            if (not Background_upv_1.Parent) then
                return;
            end;
            Map_upv_1:SetAttribute("Locked", true);
            Map_upv_1.Visible = true;
            Header_upv_1.Visible = true;
            Footer_upv_1.Visible = true;
            u15(false, 2.5);
            CurrentCamera_upv_1.CameraType = Enum.CameraType.Custom;
            u37 = true;
        end;
    end
);
local function u38(a1, a2)
    --[[
      line: 120
      upvalues:
        TweenService_upv_1 (copy, index: 1)
    ]]
    if (a1.Parent) then
        local v91 = TweenInfo.new((a2 and 0.08) or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false);
        local tbl_8 = {};
        tbl_8.ImageTransparency = (a2 and 0.5) or 1;
        TweenService_upv_1:Create(a1.Img, v91, tbl_8):Play();
    end;
end;
u5(
    "Setup",
    "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145",
    "1\237\127\136\235\021i\148\247&\252\249\001\151\030Q}\144\006\250",
    function(a1, a2, a3)
        --[[
          line: 897
          upvalues:
            u16 (copy, index: 1)
            u2 (ref,  index: 2)
            u38 (copy, index: 3)
            CurrentCamera_upv_1 (copy, index: 4)
            RunService_upv_1 (copy, index: 5)
        ]]
        local v92;
        v92 = nil;
        if (a1 >= 2) then
            v92 = ((a1 <= 6) and 0.8) or (((a1 <= 10) and 0.75) or (((a1 <= 20) and 0.65) or (((a1 > 30) and 0.3) or 0.5)));
        end;
        u16(v92);
        local v93 = nil;
        if (not a3 or not u2) then
            return;
        end;
        if (u2.Parent) then
            local v94 = u2.BloodMarker:Clone();
            v94.Parent = u2;
            if (a2 == "Fire") then
                v94.Img.ImageColor3 = Color3.fromRGB(255, 141, 48);
            end;
            v94.Visible = true;
            u38(v94, true);
            v93 = tick();
            local v95 = true;
            while (v95) do
                local CFrame_1;
                CFrame_1 = CurrentCamera_upv_1.CFrame;
                local LookVector_1;
                LookVector_1 = CFrame_1.LookVector;
                local v96;
                v96 = CFrame.new(CFrame_1.Position, CFrame_1.Position + Vector3.new(LookVector_1.X, 0, LookVector_1.Z));
                local LookVector_2;
                LookVector_2 = v96.LookVector;
                local Unit_1;
                Unit_1 = (v96.Position - a3).Unit;
                v94.Rotation = (-math.deg(math.acos(LookVector_2:Dot(Unit_1))) * math.sign(LookVector_2:Cross(Unit_1).Y)) + 180;
                if (v95 and tick() - v93 >= 0.5) then
                    local v97 = false;
                    u38(v94, false);
                    v95 = v97;
                end;
                RunService_upv_1.RenderStepped:Wait();
            end;
            if (tick() - v93 <= 0.8) then
                local CFrame_1;
                CFrame_1 = CurrentCamera_upv_1.CFrame;
                local LookVector_1;
                LookVector_1 = CFrame_1.LookVector;
                local v96;
                v96 = CFrame.new(CFrame_1.Position, CFrame_1.Position + Vector3.new(LookVector_1.X, 0, LookVector_1.Z));
                local LookVector_2;
                LookVector_2 = v96.LookVector;
                local Unit_1;
                Unit_1 = (v96.Position - a3).Unit;
                v94.Rotation = (-math.deg(math.acos(LookVector_2:Dot(Unit_1))) * math.sign(LookVector_2:Cross(Unit_1).Y)) + 180;
                if (v95 and tick() - v93 >= 0.5) then
                    local v97 = false;
                    u38(v94, false);
                    v95 = v97;
                end;
                RunService_upv_1.RenderStepped:Wait();
                while (true) do
                    if (v95) then
                        CFrame_1 = CurrentCamera_upv_1.CFrame;
                        LookVector_1 = CFrame_1.LookVector;
                        v96 = CFrame.new(CFrame_1.Position, CFrame_1.Position + Vector3.new(LookVector_1.X, 0, LookVector_1.Z));
                        LookVector_2 = v96.LookVector;
                        Unit_1 = (v96.Position - a3).Unit;
                        v94.Rotation = (-math.deg(math.acos(LookVector_2:Dot(Unit_1))) * math.sign(LookVector_2:Cross(Unit_1).Y)) + 180;
                        if (v95 and tick() - v93 >= 0.5) then
                            local v97 = false;
                            u38(v94, false);
                            v95 = v97;
                        end;
                        RunService_upv_1.RenderStepped:Wait();
                        continue;
                    end;
                    break;
                end;
            end;
        end;
    end
);
PlayerGui_upv_1.ChildAdded:Connect(u25);
task.defer(
    function()
        --[[
          line: 947
          upvalues:
            PlayerGui_upv_1 (copy, index: 1)
            u25 (copy, index: 2)
        ]]
        for _, value_10 in pairs(PlayerGui_upv_1:GetChildren()) do
            u25(value_10);
        end;
    end
);
local v98 = false;
while (task.wait()) do
    u13 = math.random(1, 1e+09);
    local v99;
    if (v98) then
        continue;
    end;
    v99 = LocalPlayer_upv_1.Character;
    if (not (v99)) then
        continue;
    end;
    if (v99.Parent == workspace) then
        local v100 = true;
        v28(v99);
        LocalPlayer_upv_1.CharacterAdded:Connect(v28);
        v98 = v100;
    end;
end;