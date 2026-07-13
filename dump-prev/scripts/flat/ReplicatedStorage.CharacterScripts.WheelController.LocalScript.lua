-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local RunService_upv_1 = game:GetService("RunService");
local UserInputService_upv_1 = game:GetService("UserInputService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local TweenUtil_upv_1 = require(Modules_1:WaitForChild("TweenUtil"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local Open_1 = script:WaitForChild("Open");
local Close_1 = script:WaitForChild("Close");
local LocalPlayer_1 = Players_1.LocalPlayer;
local PlayerGui_1 = LocalPlayer_1:WaitForChild("PlayerGui");
local _ = script.Parent:WaitForChild("Humanoid");
local PreferredInputController_upv_1 = LocalPlayer_1:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local Wheel_upv_1 = PlayerGui_1:WaitForChild("Main"):WaitForChild("Wheel");
local function getDeadzone_1()
    --[[
      name: getDeadzone
      line: 41
      upvalues:
        PreferredInputController_upv_1 (copy, index: 1)
    ]]
    return PreferredInputController_upv_1:GetAttribute("JoystickDeadzone") or 0.225;
end;
local u1 = nil;
local Size_upv_1 = nil;
local u2 = nil;
local u3 = nil;
local u4 = 0;
local tbl_upv_1 = {};
local u5 = 1;
local u6 = nil;
local u7 = 1;
local function u8(a1, a2)
    --[[
      line: 81
      upvalues:
        u7 (ref,  index: 1)
        Wheel_upv_1 (copy, index: 2)
        u1 (ref,  index: 3)
        u4 (ref,  index: 4)
        NumberUtil_upv_1 (copy, index: 5)
    ]]
    u7 = a1;
    local v1 = nil;
    local v2 = nil;
    for _, value_1 in pairs(Wheel_upv_1:GetChildren()) do
        v1 = ((u1 == value_1) and {value_1.Red, unpack(value_1.Icon:GetChildren())}) or ((value_1:IsA("Frame") and {}) or {value_1});
        for v3, value_2 in pairs(v1) do
            if (value_2.Name ~= "Red" or u4 ~= 0) then
                v2 = ((value_2:IsA("TextLabel")) and "Text") or (((value_2:IsA("ImageLabel")) and "Image") or "Background");
                value_2[v2 .. "Transparency"] = NumberUtil_upv_1:Lerp(((value_2.Name ~= "BG") and 0) or 0.2, 1, a1);
                continue;
            end;
            if (a2) then
                continue;
            end;
            if (value_2.ImageTransparency ~= 1) then
                v2 = ((value_2:IsA("TextLabel")) and "Text") or (((value_2:IsA("ImageLabel")) and "Image") or "Background");
                value_2[v2 .. "Transparency"] = NumberUtil_upv_1:Lerp(((value_2.Name ~= "BG") and 0) or 0.2, 1, a1);
            end;
        end;
    end;
    Wheel_upv_1.Visible = a1 < 1;
end;
local function u9(a1)
    --[[
      line: 96
      upvalues:
        Wheel_upv_1 (copy, index: 1)
        NumberUtil_upv_1 (copy, index: 2)
        Size_upv_1 (ref,  index: 3)
        u2 (ref,  index: 4)
        u5 (ref,  index: 5)
        u8 (copy, index: 6)
        RunService_upv_1 (copy, index: 7)
    ]]
    if (a1) then
        Wheel_upv_1.Size = NumberUtil_upv_1:MultUDim2ByNum(Size_upv_1, 1.3);
    end;
    local v3 = NumberUtil_upv_1:MultUDim2ByNum(Size_upv_1, (a1 and 1) or 1.3);
    Wheel_upv_1:TweenSize(v3, (a1 and "Out") or "In", "Quart", 0.175, true);
    local time_1 = tick();
    local v4 = (a1 and 0) or 1;
    if (u2 and not (a1)) then
        u2:Cancel();
    end;
    local v5 = nil;
    if (u5 == v4) then
        return;
    end;
    u5 = v4;
    while (true) do
        v3 = tick() - time_1;
        local v6 = math.min(v3 / 0.1, 1);
        v5 = a1 and 1 - v6 or v6;
        u8(v5, a1);
        if (v3 >= 0.1) then
            break;
        end;
        RunService_upv_1.Heartbeat:Wait();
    end;
end;
local function u10(a1)
    --[[
      line: 123
      upvalues:
        Wheel_upv_1 (copy, index: 1)
        u1 (ref,  index: 2)
        u2 (ref,  index: 3)
        TweenUtil_upv_1 (copy, index: 4)
        u3 (ref,  index: 5)
        u4 (ref,  index: 6)
    ]]
    Wheel_upv_1.SelectedImage.Image = (a1 and (a1.Image)) or "";
    Wheel_upv_1.SelectedName.Text = (a1 and (a1.Name)) or "";
    Wheel_upv_1.SelectedDesc.Text = (a1 and (a1.Description)) or "";
    local SelectedCost_1 = Wheel_upv_1.SelectedCost;
    SelectedCost_1.Text = not a1 and "" or type(a1.Cost) == "function" and a1.Cost() or a1.Cost or "";
    if (u1) then
        if (a1) then
            u2 = TweenUtil_upv_1:Tween(u1.Red, "ImageTransparency", 0, 0.2, "Quart");
        else
            u1.Red.ImageTransparency = 1;
        end;
        local v8 = nil;
        local v9 = nil;
        local v10 = nil;
        for _, value_3 in pairs(u1.Icon:GetChildren()) do
            v10 = tonumber(value_3.Name:sub(2));
            v8 = u3[v10];
            if (v10 == u4) then
                v9 = "IconSelectedColor";
                value_3.ImageColor3 = script:GetAttribute(v9);
                continue;
            end;
            if (v8 == nil) then
                v9 = "IconUnavailableColor";
                value_3.ImageColor3 = script:GetAttribute(v9);
                continue;
            end;
            if (v8.Selectable) then
                v9 = "IconUnselectedColor";
            else
                v9 = "IconUnavailableColor";
            end;
            value_3.ImageColor3 = script:GetAttribute(v9);
        end;
    end;
end;
local function u11(a1, a2)
    --[[
      line: 141
      upvalues:
        u1 (ref,  index: 1)
        u4 (ref,  index: 2)
        TweenUtil_upv_1 (copy, index: 3)
        u10 (copy, index: 4)
    ]]
    if (not u1) then
        return;
    end;
    if (u4 ~= a1) then
        local num_1 = tonumber(u1.Name:sub(6));
        TweenUtil_upv_1:Tween(u1.Red, "Rotation", (360 / num_1) * (a1 - 1), ((u4 ~= 0) and 0.2) or 0, "Quart");
        u4 = a1;
        u10(a2);
    end;
end;
local function u12()
    --[[
      line: 149
      upvalues:
        tbl_upv_1 (ref,  index: 1)
        RunService_upv_1 (copy, index: 2)
    ]]
    for _, value_4 in pairs(tbl_upv_1) do
        value_4:Disconnect();
    end;
    tbl_upv_1 = {};
    pcall(
        function()
            --[[
              line: 154
              upvalues:
                RunService_upv_1 (copy, index: 1)
            ]]
            RunService_upv_1:UnbindFromRenderStep("WheelGamepadInput");
        end
    );
end;
Wheel_upv_1:GetPropertyChangedSignal("AbsoluteSize"):Connect(
    function()
        --[[
          line: 232
          upvalues:
            Wheel_upv_1 (copy, index: 1)
            u6 (ref,  index: 2)
            u7 (ref,  index: 3)
            Size_upv_1 (ref,  index: 4)
        ]]
        local Y_1 = Wheel_upv_1.AbsoluteSize.Y;
        if (Y_1 == u6 or u7 % 1 ~= 0) then
            return;
        end;
        u6 = Y_1;
        Size_upv_1 = UDim2.new(0, Y_1, 0.7, 0);
        Wheel_upv_1.Size = Size_upv_1;
    end
);
local function u13(a1)
    --[[
      line: 56
      upvalues:
        UserInputService_upv_1 (copy, index: 1)
        PreferredInputController_upv_1 (copy, index: 2)
    ]]
    local success_1, v11 = pcall(
        function()
            --[[
              line: 57
              upvalues:
                UserInputService_upv_1 (copy, index: 1)
            ]]
            return UserInputService_upv_1:GetGamepadState(Enum.UserInputType.Gamepad1);
        end
    );
    if (success_1 and v11) then
        for _, value_5 in pairs(v11) do
            local v12, v13 = nil, nil;
            if (value_5.KeyCode == Enum.KeyCode.Thumbstick1) then
                v12 = value_5.Position.X;
                v13 = value_5.Position.Y;
                local v14 = nil;
                if (math.sqrt((v12 * v12) + (v13 * v13)) > (PreferredInputController_upv_1:GetAttribute("JoystickDeadzone") or 0.225)) then
                    v14 = math.deg(math.atan2(v12, v13));
                    if (v14 < 0) then
                        v14 = v14 + 360;
                    end;
                    local v15 = 360 / a1;
                    return math.floor(((v14 + (v15 / 2)) % 360) / v15) + 1;
                end;
                return nil;
            end;
        end;
    else
        return nil;
    end;
    -- GenericForNext _, value_5 = v16(v17, [control]);
    local v12, v13 = nil, nil;
    while (true) do
        if (value_5.KeyCode ~= Enum.KeyCode.Thumbstick1) then
            continue;
        else
            v12 = value_5.Position.X;
            v13 = value_5.Position.Y;
            local v14 = nil;
            if (math.sqrt((v12 * v12) + (v13 * v13)) > (PreferredInputController_upv_1:GetAttribute("JoystickDeadzone") or 0.225)) then
                v14 = math.deg(math.atan2(v12, v13));
                if (v14 < 0) then
                    v14 = v14 + 360;
                end;
                local v15 = 360 / a1;
                return math.floor(((v14 + (v15 / 2)) % 360) / v15) + 1;
            end;
        end;
    end;
end;
Open_1.OnInvoke = function(a1, a2, a3)
    --[[
      line: 157
      upvalues:
        u12 (copy, index: 1)
        u1 (ref,  index: 2)
        Wheel_upv_1 (copy, index: 3)
        u4 (ref,  index: 4)
        u3 (ref,  index: 5)
        u10 (copy, index: 6)
        tbl_upv_1 (ref,  index: 7)
        u11 (copy, index: 8)
        PreferredInputController_upv_1 (copy, index: 9)
        UserInputService_upv_1 (copy, index: 10)
        RunService_upv_1 (copy, index: 11)
        u13 (copy, index: 12)
        u9 (copy, index: 13)
    ]]
    script:SetAttribute("Open", true);
    script:SetAttribute("WheelType", a2);
    u12();
    if (u1) then
        u1.Visible = false;
    end;
    u1 = Wheel_upv_1:FindFirstChild("Wheel" .. #a1);
    u4 = 0;
    u3 = a1;
    u10();
    local u14 = false;
    local v18 = false;
    local v19 = nil;
    for key_upv_1, value_upv_6 in pairs(a1) do
        v19 = u1.Hitbox["Q" .. key_upv_1];
        u1.Icon["Q" .. key_upv_1].Image = value_upv_6.Image;
        if (value_upv_6.Selectable) then
            table.insert(
                tbl_upv_1,
                v19.MouseEnter:Connect(
                    function()
                        --[[
                          line: 175
                          upvalues:
                            u11 (copy, index: 1)
                            key_upv_1 (copy, index: 2)
                            value_upv_6 (copy, index: 3)
                        ]]
                        u11(key_upv_1, value_upv_6);
                    end
                )
            );
        end;
        if (value_upv_6.SelectFirst) then
            v18 = true;
            u11(key_upv_1, value_upv_6);
        end;
    end;
    local v20 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
    if (v20 and not (v18) and a1[1]) then
        u11(1, a1[1]);
    end;
    table.insert(
        tbl_upv_1,
        UserInputService_upv_1.InputBegan:Connect(
            function(a4)
                --[[
                  line: 188
                  upvalues:
                    u14 (ref, index: 1)
                ]]
                if (a4.UserInputType ~= Enum.UserInputType.MouseButton1 and a4.KeyCode ~= Enum.KeyCode.ButtonR2) then
                    return;
                end;
                task.wait();
                u14 = true;
                script:SetAttribute("Open", false);
            end
        )
    );
    local u15 = #a1;
    RunService_upv_1:BindToRenderStep(
        "WheelGamepadInput",
        Enum.RenderPriority.Input.Value,
        function()
            --[[
              line: 198
              upvalues:
                u1 (ref,  index: 1)
                u3 (ref,  index: 2)
                u13 (copy, index: 3)
                u15 (copy, index: 4)
                u11 (copy, index: 5)
            ]]
            if (u1) then
                local v21 = nil;
                if (u3) then
                    v21 = u13(u15);
                    local v22;
                    if (not v21) then
                        return;
                    end;
                    v22 = u3[v21];
                    if (v22 and v22.Selectable) then
                        u11(v21, v22);
                    end;
                end;
            end;
        end
    );
    u1.Visible = true;
    local xtra_1 = Wheel_upv_1.xtra;
    local v23 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
    if (v23) then
        v23 = a2 ~= "Blueprint";
    end;
    xtra_1.Visible = v23;
    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
    UserInputService_upv_1.MouseIconEnabled = true;
    task.spawn(u9, true);
    while (script:GetAttribute("Open")) do
        RunService_upv_1.Heartbeat:Wait();
    end;
    if (script:GetAttribute("WheelType") == a2) then
        u12();
        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService_upv_1.MouseIconEnabled = false;
        task.spawn(u9, false);
        Wheel_upv_1.xtra.Visible = false;
    end;
    if (not a3 or (u14)) then
        return u4;
    end;
end;
Close_1.OnInvoke = function(a1)
    --[[
      line: 227
    ]]
    if (a1 and a1 ~= script:GetAttribute("WheelType")) then
        return;
    end;
    script:SetAttribute("Open", false);
end;
Size_upv_1 = Wheel_upv_1.Size;
u8(1);
Wheel_upv_1.Visible = false;
local Y_2 = Wheel_upv_1.AbsoluteSize.Y;
if (Y_2 == u6) then
    return;
end;
if (u7 % 1 == 0) then
    u6 = Y_2;
    Size_upv_1 = UDim2.new(0, Y_2, 0.7, 0);
    Wheel_upv_1.Size = Size_upv_1;
end;