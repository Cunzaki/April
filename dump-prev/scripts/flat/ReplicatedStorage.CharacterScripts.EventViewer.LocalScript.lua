-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local TweenService_upv_1 = game:GetService("TweenService");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local Main_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui"):WaitForChild("Main");
local Notification_upv_1 = Main_1:WaitForChild("Notification");
local Map_upv_1 = Main_1:WaitForChild("Map"):WaitForChild("Frame"):WaitForChild("Map");
local TimedCrateTemplate_upv_1 = Map_upv_1:WaitForChild("TimedCrateTemplate");
local BTRTemplate_upv_1 = Map_upv_1:WaitForChild("BTRTemplate");
local BorisTemplate_upv_1 = Map_upv_1:WaitForChild("BorisTemplate");
local BrutusTemplate_upv_1 = Map_upv_1:WaitForChild("BrutusTemplate");
local BrunoTemplate_upv_1 = Map_upv_1:WaitForChild("BrunoTemplate");
local Events_upv_1 = workspace:WaitForChild("Events");
local Military_upv_1 = workspace:WaitForChild("Military");
local NumberUtil_upv_1 = require(ReplicatedStorage_1:WaitForChild("Modules"):WaitForChild("NumberUtil"));
local Notification_upv_2 = script:WaitForChild("Notification");
local Loners_1 = workspace:WaitForChild("Bases"):WaitForChild("Loners");
local u1 = nil;
local u2 = Vector2.new(0, 0);
local tbl_upv_1 = {};
tbl_upv_1.BTR = "rbxassetid://16270992443";
tbl_upv_1.BTRfire = "rbxassetid://16270991717";
tbl_upv_1["Timed Crate"] = "rbxassetid://16018005011";
tbl_upv_1.Boris = "rbxassetid://18312187080";
tbl_upv_1.Bruno = "rbxassetid://16652579167";
tbl_upv_1.Brutus = "rbxassetid://134265072222654";
local tbl_upv_2 = {};
local function u3(a1)
    --[[
      line: 65
      upvalues:
        tbl_upv_2 (copy, index: 1)
        u1 (ref,  index: 2)
        TimedCrateTemplate_upv_1 (copy, index: 3)
        u2 (copy, index: 4)
        Map_upv_1 (copy, index: 5)
        Events_upv_1 (copy, index: 6)
        BTRTemplate_upv_1 (copy, index: 7)
        Military_upv_1 (copy, index: 8)
        BrunoTemplate_upv_1 (copy, index: 9)
        BorisTemplate_upv_1 (copy, index: 10)
        BrutusTemplate_upv_1 (copy, index: 11)
    ]]
    for v1, value_1 in pairs(tbl_upv_2) do
        if (not (a1) or value_1.Name == "BTR") then
            value_1:Destroy();
            tbl_upv_2[v1] = nil;
        end;
    end;
    if (u1 and u1.Parent and not (a1)) then
        local u4 = nil;
        local Position_1 = nil;
        local v2 = nil;
        for _, value_2 in pairs(u1:GetChildren()) do
            u4 = TimedCrateTemplate_upv_1:Clone();
            Position_1 = value_2.Main.Position;
            v2 = ((typeof(Position_1) == "Vector3") and (Position_1.Z)) or (Position_1.Y);
            u4.Position = UDim2.new(0.5 + ((Position_1.X - u2.X) / 12800), 0, 0.5 + ((v2 - u2.Y) / 12800), 0);
            u4.Parent = Map_upv_1;
            u4.Visible = true;
            tbl_upv_2[value_2] = u4;
            u4.MouseEnter:Connect(
                function()
                    --[[
                      line: 83
                      upvalues:
                        u4 (copy, index: 1)
                    ]]
                    u4.TextLabel.Visible = true;
                end
            );
            u4.MouseLeave:Connect(
                function()
                    --[[
                      line: 86
                      upvalues:
                        u4 (copy, index: 1)
                    ]]
                    u4.TextLabel.Visible = false;
                end
            );
        end;
    end;
    local BTR_1 = Events_upv_1:FindFirstChild("BTR");
    if (BTR_1) then
        local v3 = BTRTemplate_upv_1:Clone();
        local v4 = v3.BTRImage;
        local v1 = ((BTR_1:GetAttribute("Destroyed")) and "rbxassetid://16270991717") or "rbxassetid://16270992443";
        v4.Image = v1;
        local Position_2 = BTR_1.HumanoidRootPart.Position;
        local v5 = ((typeof(Position_2) == "Vector3") and (Position_2.Z)) or (Position_2.Y);
        v3.Position = UDim2.new(0.5 + ((Position_2.X - u2.X) / 12800), 0, 0.5 + ((v5 - u2.Y) / 12800), 0);
        v3.Name = "BTR";
        v3.Parent = Map_upv_1;
        v3.Visible = true;
        tbl_upv_2[BTR_1] = v3;
    end;
    local v6 = Military_upv_1:WaitForChild("Military Barracks"):FindFirstChild("Bruno") or (Military_upv_1:WaitForChild("Rocket Factory"):FindFirstChild("Bruno"));
    local v4 = nil;
    if (v6) then
        v4 = BrunoTemplate_upv_1:Clone();
        local Position_3 = v6.HumanoidRootPart.Position;
        local v8 = ((typeof(Position_3) == "Vector3") and (Position_3.Z)) or (Position_3.Y);
        v4.Position = UDim2.new(0.5 + ((Position_3.X - u2.X) / 12800), 0, 0.5 + ((v8 - u2.Y) / 12800), 0);
        v4.Name = "Boris";
        v4.Parent = Map_upv_1;
        v4.Visible = true;
        tbl_upv_2[v6] = v4;
    end;
    v4 = Military_upv_1:WaitForChild("Labs"):FindFirstChild("Boris");
    local v1 = nil;
    if (v4) then
        v1 = BorisTemplate_upv_1:Clone();
        local Position_4 = v4.HumanoidRootPart.Position;
        local v10 = ((typeof(Position_4) == "Vector3") and (Position_4.Z)) or (Position_4.Y);
        v1.Position = UDim2.new(0.5 + ((Position_4.X - u2.X) / 12800), 0, 0.5 + ((v10 - u2.Y) / 12800), 0);
        v1.Name = "Boris";
        v1.Parent = Map_upv_1;
        v1.Visible = true;
        tbl_upv_2[v4] = v1;
    end;
    v1 = Military_upv_1:WaitForChild("Industrial Port"):FindFirstChild("Brutus");
    if (v1) then
        local v11 = BrutusTemplate_upv_1:Clone();
        local Position_5 = v1.HumanoidRootPart.Position;
        local v12 = ((typeof(Position_5) == "Vector3") and (Position_5.Z)) or (Position_5.Y);
        v11.Position = UDim2.new(0.5 + ((Position_5.X - u2.X) / 12800), 0, 0.5 + ((v12 - u2.Y) / 12800), 0);
        v11.Name = "Brutus";
        v11.Parent = Map_upv_1;
        v11.Visible = true;
        tbl_upv_2[v1] = v11;
    end;
end;
local function u5(a1)
    --[[
      line: 141
      upvalues:
        Notification_upv_1 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
        TweenService_upv_1 (copy, index: 3)
        Notification_upv_2 (copy, index: 4)
    ]]
    Notification_upv_1.Bottom.Event.Text = string.upper(a1) .. " AVAILABLE";
    Notification_upv_1.Image.Image = tbl_upv_1[a1];
    local v13 = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0);
    local v14 = TweenService_upv_1:Create(Notification_upv_1, v13, {Position = Notification_upv_1:GetAttribute("PositionOpen")});
    local v15 = TweenService_upv_1:Create(Notification_upv_1, v13, {Position = Notification_upv_1:GetAttribute("PositionClosed")});
    v14:Play();
    Notification_upv_2:Play();
    task.wait(8);
    v15:Play();
end;
local function v16(a1)
    --[[
      line: 161
      upvalues:
        u1 (ref,  index: 1)
        u3 (copy, index: 2)
        u5 (copy, index: 3)
    ]]
    if (not a1 or not a1.Parent or a1.Name ~= "Timed Crate") then
        return;
    end;
    u1 = a1;
    u1.ChildAdded:Connect(
        function(a2)
            --[[
              line: 164
              upvalues:
                u3 (copy, index: 1)
                u5 (copy, index: 2)
            ]]
            if (a2.Name ~= "Timed Crate") then
                return;
            end;
            u3();
            u5("Timed Crate");
        end
    );
    u1.ChildRemoved:Connect(
        function(a3)
            --[[
              line: 170
              upvalues:
                u3 (copy, index: 1)
            ]]
            if (a3.Name ~= "Timed Crate") then
                return;
            end;
            u3();
        end
    );
    task.wait();
    u3();
end;
Loners_1.ChildAdded:Connect(v16);
v16(Loners_1:FindFirstChild("Timed Crate"));
Events_upv_1.ChildRemoved:Connect(
    function()
        --[[
          line: 342
          upvalues:
            u3 (copy, index: 1)
        ]]
        u3();
    end
);
local function v17(a1)
    --[[
      line: 180
      upvalues:
        u5 (copy, index: 1)
        LocalPlayer_upv_1 (copy, index: 2)
        NumberUtil_upv_1 (copy, index: 3)
    ]]
    local v18 = nil;
    if (a1.Name == "BTR") then
        if (not (a1:GetAttribute("Marked"))) then
            a1:SetAttribute("Marked", true);
            u5("BTR");
        end;
        local u6 = nil;
        local u7 = false;
        local u8 = 0;
        a1:GetAttributeChangedSignal("GunPosition"):Connect(
            function()
                --[[
                  line: 189
                  upvalues:
                    LocalPlayer_upv_1 (copy, index: 1)
                    a1 (copy, index: 2)
                    NumberUtil_upv_1 (copy, index: 3)
                    u7 (ref,  index: 4)
                    u6 (ref,  index: 5)
                    u8 (ref,  index: 6)
                ]]
                local Character_1 = LocalPlayer_upv_1.Character;
                local v19 = nil;
                if (Character_1) then
                    v19 = Character_1.PrimaryPart;
                end;
                if (not Character_1 or not v19) then
                    return;
                end;
                if (a1:FindFirstChild("HumanoidRootPart")) then
                    local v20 = nil;
                    if (NumberUtil_upv_1:IsWithin(v19.Position, a1.HumanoidRootPart.Position, 1000)) then
                        local v21 = a1:GetAttribute("GunPosition");
                        v20 = a1.Detail:FindFirstChild("GunBase");
                        local v22 = nil;
                        if (v20) then
                            if (u7 and (not u6 or NumberUtil_upv_1:IsWithin(u6, v21, 3))) then
                                u6 = v21;
                                u8 = os.clock();
                                return;
                            end;
                            v22 = v20:FindFirstChild("GunPivot");
                            local HumanoidRootPart_1 = a1:FindFirstChild("HumanoidRootPart");
                            if (v22) then
                                local v23 = nil;
                                if (HumanoidRootPart_1) then
                                    v23 = HumanoidRootPart_1:FindFirstChild("GunBase");
                                    local v24;
                                    if (not v23) then
                                        return;
                                    end;
                                    u7 = true;
                                    v24 = u6;
                                    u6 = v21;
                                    if (not (v24)) then
                                        v24 = v21;
                                    end;
                                    u8 = os.clock();
                                    while (os.clock() - u8 < 1) do
                                        local v25 = task.wait(0.016666666666666666);
                                        if (v23.Parent and v22.Parent) then
                                            v24 = v24:Lerp(v21, math.clamp(v25 * 6, 0, 1));
                                            local Position_6 = v20.Position;
                                            local v26 = Vector3.new(Position_6.X, 0, Position_6.Z);
                                            local v27 = Vector3.new(v24.X, 0, v24.Z);
                                            v23.C1 = (CFrame.new(0, 0.3, 0) * HumanoidRootPart_1.CFrame.Rotation) * CFrame.new(v26, v27).Rotation:Inverse();
                                            v22.C1 = CFrame.Angles(0, 0, -math.clamp(math.atan2(v24.Y - Position_6.Y, (v27 - v26).Magnitude), -0.25, 1.1));
                                            continue;
                                        end;
                                        return;
                                    end;
                                    u7 = false;
                                end;
                            end;
                        end;
                    end;
                end;
            end
        );
        v18 = a1:WaitForChild("Humanoid");
        local v28 = nil;
        if (v18) then
            v28 = a1:WaitForChild("HumanoidRootPart");
            local WheelJoints_upv_1;
            if (not v28) then
                return;
            end;
            WheelJoints_upv_1 = v28:WaitForChild("WheelJoints");
            if (WheelJoints_upv_1) then
                local u9 = false;
                local u10 = 0;
                local u11 = 1;
                local u12 = 0;
                v18.Running:Connect(
                    function(a2)
                        --[[
                          line: 289
                          upvalues:
                            LocalPlayer_upv_1 (copy, index: 1)
                            a1 (copy, index: 2)
                            NumberUtil_upv_1 (copy, index: 3)
                            u9 (ref,  index: 4)
                            u10 (ref,  index: 5)
                            WheelJoints_upv_1 (copy, index: 6)
                            u11 (ref,  index: 7)
                            u12 (ref,  index: 8)
                        ]]
                        local Character_2 = LocalPlayer_upv_1.Character;
                        local v29 = nil;
                        if (Character_2) then
                            v29 = Character_2.PrimaryPart;
                        end;
                        if (not Character_2 or not v29 or not a1:FindFirstChild("HumanoidRootPart") or not NumberUtil_upv_1:IsWithin(v29.Position, a1.HumanoidRootPart.Position, 750)) then
                            return;
                        end;
                        if (u9 or a2 <= 0.01) then
                            u10 = a2;
                            u11 = ((a2 > 0.01) and 1) or 4;
                        else
                            u9 = true;
                            u10 = a2;
                            local v30 = WheelJoints_upv_1:GetChildren();
                            while (true) do
                                local v31 = task.wait(0.016666666666666666);
                                if (not (WheelJoints_upv_1.Parent)) then
                                    break;
                                end;
                                local v32 = nil;
                                local v33 = NumberUtil_upv_1:Lerp(v32, a2, math.clamp((v31 * u11) * 8, 0, 1));
                                u12 = u12 + math.rad((v33 * 12.5) * v31);
                                for _, value_3 in pairs(v30) do
                                    value_3.C1 = CFrame.Angles(u12, 0, 0);
                                end;
                                if (v33 > 0.01 or a2 > 0.01) then
                                    v32 = v33;
                                    continue;
                                end;
                                u9 = false;
                                return;
                            end;
                        end;
                    end
                );
            end;
        end;
    end;
end;
Events_upv_1.ChildAdded:Connect(v17);
Military_upv_1:WaitForChild("Industrial Port").ChildAdded:Connect(
    function(a1)
        --[[
          line: 348
          upvalues:
            u5 (copy, index: 1)
        ]]
        if (a1.Name ~= "Brutus") then
            return;
        end;
        u5("Brutus");
    end
);
Military_upv_1:WaitForChild("Labs").ChildAdded:Connect(
    function(a1)
        --[[
          line: 354
          upvalues:
            u5 (copy, index: 1)
        ]]
        if (a1.Name ~= "Boris") then
            return;
        end;
        u5("Boris");
    end
);
Military_upv_1:WaitForChild("Military Barracks").ChildAdded:Connect(
    function(a1)
        --[[
          line: 360
          upvalues:
            u5 (copy, index: 1)
        ]]
        if (a1.Name ~= "Bruno") then
            return;
        end;
        u5("Bruno");
    end
);
Military_upv_1:WaitForChild("Rocket Factory").ChildAdded:Connect(
    function(a1)
        --[[
          line: 366
          upvalues:
            u5 (copy, index: 1)
        ]]
        if (a1.Name ~= "Bruno") then
            return;
        end;
        u5("Bruno");
    end
);
for _, value_4 in pairs(Events_upv_1:GetChildren()) do
    v17(value_4);
end;
u3();
task.wait(2);