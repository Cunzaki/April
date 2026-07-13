-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_upv_1 = game:GetService("ReplicatedStorage");
local _ = game:GetService("TweenService");
local UserInputService_upv_1 = game:GetService("UserInputService");
local Modules_1 = ReplicatedStorage_upv_1:WaitForChild("Modules");
local SettingRemotes_upv_1 = ReplicatedStorage_upv_1:WaitForChild("SettingRemotes");
local v1 = nil;
local v2 = nil;
while (true) do
    local Shared_1 = Modules_1:FindFirstChild("Shared");
    v2 = nil;
    if (Shared_1) then
        local Client_1 = Modules_1:FindFirstChild("Client");
        if (not (Client_1)) then
            continue;
        end;
        v2, v1 = Shared_1, require(Client_1:WaitForChild("ButtonClass"));
    else
        local ButtonClass_1 = Modules_1:FindFirstChild("ButtonClass");
        if (ButtonClass_1) then
            v2, v1 = Modules_1, require(Modules_1:WaitForChild("ButtonClass"));
        end;
    end;
    if (v2) then
        break;
    end;
    task.wait();
end;
local SettingsModule_upv_1 = require(v2:WaitForChild("SettingsModule"));
local NumberUtil_upv_1 = require(v2:WaitForChild("NumberUtil"));
local LocalPlayer_1 = Players_1.LocalPlayer;
local u1 = LocalPlayer_1:GetMouse();
local u2 = LocalPlayer_1:WaitForChild("PlayerScripts"):FindFirstChild("PreferredInputController") or (LocalPlayer_1:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController", 5));
local Parent_1 = script.Parent;
local Menus_upv_1 = Parent_1:WaitForChild("Menus");
local TopButtons_1 = Parent_1:WaitForChild("TopButtons");
local ChangeHotkey_upv_1 = Parent_1:WaitForChild("ChangeHotkey");
local ConfirmReset_upv_1 = Parent_1:WaitForChild("ConfirmReset");
local Reset_upv_1 = Parent_1:WaitForChild("Reset");
local tbl_upv_1 = {};
local u3 = "General";
local u4 = nil;
local u5 = nil;
local u6 = nil;
local u7 = nil;
local u8 = nil;
local u9 = nil;
local u10, v3 = SettingRemotes_upv_1:WaitForChild("Fetch"):InvokeServer();
local u11 = nil;
for key_upv_1, value_upv_1 in SettingsModule_upv_1.Config.Gamepad do
    if (value_upv_1.Type ~= "Keybind" or not (value_upv_1.Id)) then
        continue;
    end;
    if (u10[value_upv_1.Id] ~= value_upv_1.DefaultValue) then
        u10[value_upv_1.Id] = value_upv_1.DefaultValue;
        SettingRemotes_upv_1.Update:FireServer("Settings", value_upv_1.Id, value_upv_1.DefaultValue);
    end;
end;
SettingsModule_upv_1.ApplySettings(u10, v3);
u11 = nil;
local function u12(a1, a2)
    --[[
      line: 76
      upvalues:
        u3 (ref,  index: 1)
        tbl_upv_1 (copy, index: 2)
        Menus_upv_1 (copy, index: 3)
        u11 (ref,  index: 4)
    ]]
    local v4 = nil;
    if (u3 ~= a1) then
        v4 = tbl_upv_1[u3];
        if (v4 and v4:IsToggled()) then
            task.defer(v4.ToggleButton, v4, false);
        end;
        u3 = a1;
    elseif (not (a2)) then
        return;
    end;
    local v5 = tbl_upv_1[a1];
    if (v5 and not (v5:IsToggled())) then
        task.defer(v5.ToggleButton, v5, true, a2);
    end;
    for _, value_2 in pairs(Menus_upv_1:GetChildren()) do
        value_2.Visible = value_2.Name == a1;
    end;
    u11();
end;
local function u13(a1, a2, a3, a4, a5)
    --[[
      line: 96
      upvalues:
        NumberUtil_upv_1 (ref, index: 1)
    ]]
    local v6 = a3.Range[1];
    local v7 = a3.Range[2];
    local v8 = math.clamp(a2, v6, v7);
    local v9 = math.max(v8 - v6, 0) / (v7 - v6);
    local new_1 = UDim2.new;
    local v10;
    if (v6 > 0) then
        v10 = 0.02 + v9 * 0.98;
    else
        v10 = v9;
    end;
    new_1 = new_1(v10, 0, 1, 0);
    if (a5) then
        a1.Holder.ColorImage.Size = new_1;
    else
        a1.Holder.ColorImage:TweenSize(new_1, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.12, true);
    end;
    if (not (a4)) then
        a1.Frame.NumberDisplay.Text = tostring(NumberUtil_upv_1:RoundNumber(v8, 3));
    end;
    return v8;
end;
local function value_upv_1(a1, a2, a3)
    --[[
      line: 126
      upvalues:
        ChangeHotkey_upv_1 (copy, index: 1)
        SettingsModule_upv_1 (ref,  index: 2)
        u10 (copy, index: 3)
        UserInputService_upv_1 (copy, index: 5)
    ]]
    local v11 = a2;
    local v12 = false;
    local v13 = nil;
    local v16 = nil;
    local _;
    if (type(a2) ~= "string") then
        v13 = v11.Name;
    else
        if (a2 ~= "MB2") then
            if (not (a2:find("M.Wheel"))) then
                v16, _ = pcall(
                    function()
                        --[[
                          line: 135
                          upvalues:
                            a2 (copy, index: 1)
                        ]]
                        return Enum.KeyCode[a2];
                    end
                );
                if (v16 and _) then
                    v11 = _;
                    v13 = v11.Name;
                    if (a1:IsDescendantOf(ChangeHotkey_upv_1)) then
                        _ = SettingsModule_upv_1.CheckKeybind;
                        v16 = a3;
                        _ = _(u10, v13, v16);
                        local Description_1 = ChangeHotkey_upv_1.Frame.Description;
                        local v18 = ((not _) and "Press a key on your keyboard to adjust this hotkey") or (("KEYBIND CANNOT BE SET - CONFLICTING WITH [%*]"):format(_.Text:upper()));
                        Description_1.Text = v18;
                        ChangeHotkey_upv_1.Frame.Save.Visible = _ == nil;
                    end;
                    v16 = v12 or UserInputService_upv_1:GetImageForKeyCode(v11);
                    if ((v16) and v16 ~= "") then
                        a1.KeyImage.Image = v16;
                        a1.KeyImage.Visible = true;
                        a1.KeyText.Visible = false;
                    else
                        if (v12) then
                            _ = v13;
                        else
                            _ = UserInputService_upv_1:GetStringForKeyCode(v11);
                        end;
                        _ = (_) and _ ~= "" and _ ~= " " or v13;
                        a1.KeyText.Text = _;
                        a1.KeyImage.Visible = false;
                        a1.KeyText.Visible = true;
                    end;
                    return true;
                end;
                return false;
            end;
        end;
        v13, v12, v11 = a2, true, a2;
    end;
    if (a1:IsDescendantOf(ChangeHotkey_upv_1)) then
        _ = SettingsModule_upv_1.CheckKeybind;
        v16 = a3;
        _ = _(u10, v13, v16);
        local Description_1 = ChangeHotkey_upv_1.Frame.Description;
        local v18 = ((not _) and "Press a key on your keyboard to adjust this hotkey") or (("KEYBIND CANNOT BE SET - CONFLICTING WITH [%*]"):format(_.Text:upper()));
        Description_1.Text = v18;
        ChangeHotkey_upv_1.Frame.Save.Visible = _ == nil;
    end;
    v16 = v12 or UserInputService_upv_1:GetImageForKeyCode(v11);
    if ((v16) and v16 ~= "") then
        a1.KeyImage.Image = v16;
        a1.KeyImage.Visible = true;
        a1.KeyText.Visible = false;
    else
        local v19;
        if (v12) then
            _ = v13;
        else
            _ = UserInputService_upv_1:GetStringForKeyCode(v11);
        end;
        local v15;
        _ = (_) and _ ~= "" and _ ~= " " or v13;
        a1.KeyText.Text = _;
        a1.KeyImage.Visible = false;
        a1.KeyText.Visible = true;
    end;
    return true;
end;
local function key_upv_1(a1, a2, a3)
    --[[
      line: 114
    ]]
    local v19 = UDim2.new((a2 and 0.94) or 0.155, 0, 0.88, 0);
    local v20 = UDim2.new((a2 and 1) or 0.215, 0, 0.5, 0);
    if (a3) then
        a1.ColorImage.Size = v19;
        a1.CircleSlider.Position = v20;
    else
        a1.ColorImage:TweenSize(v19, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true);
        a1.CircleSlider:TweenPosition(v20, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true);
    end;
end;
local function u14(a1, a2, a3, a4, a5)
    --[[
      line: 165
      upvalues:
        SettingsModule_upv_1 (ref,  index: 1)
        Menus_upv_1 (copy, index: 2)
        u10 (copy, index: 3)
        key_upv_1 (copy, index: 4)
        u13 (copy, index: 5)
        value_upv_1 (copy, index: 6)
    ]]
    a4 = a4 or (SettingsModule_upv_1.GetSettingFromId(a2));
    local Type_1 = a4.Type;
    local v21 = nil;
    if (not (a3)) then
        v21 = Menus_upv_1[a1].Frame:FindFirstChild(tostring(a2));
        if (not v21) then
            return;
        end;
        a3 = v21;
    end;
    local v22 = u10[a2];
    if (Type_1 == "Checkbox") then
        key_upv_1(a3.ClickButton, v22, a5);
    elseif (Type_1 == "Slider") then
        u13(a3.DragSlider, v22, a4, false, a5);
    elseif (Type_1 == "Keybind") then
        value_upv_1(a3.ClickButton, v22, a2);
    end;
end;
u11 = function()
    --[[
      line: 184
      upvalues:
        Reset_upv_1 (copy, index: 1)
        SettingsModule_upv_1 (ref,  index: 2)
        u10 (copy, index: 3)
        u3 (ref,  index: 4)
    ]]
    Reset_upv_1.Visible = SettingsModule_upv_1.ResetSettings(u10, u3, false);
end;
UserInputService_upv_1.InputBegan:Connect(
    function(a1)
        --[[
          line: 197
          upvalues:
            ChangeHotkey_upv_1 (copy, index: 1)
            SettingsModule_upv_1 (ref,  index: 2)
            u5 (ref,  index: 3)
            u7 (ref,  index: 4)
            value_upv_1 (copy, index: 5)
        ]]
        if (ChangeHotkey_upv_1.Visible) then
            local UserInputType_1 = a1.UserInputType;
            local KeyCode_1 = a1.KeyCode;
            local v23 = not KeyCode_1 or (KeyCode_1 == Enum.KeyCode.Unknown);
            if (v23 and UserInputType_1 ~= Enum.UserInputType.MouseButton2) then
                return;
            end;
            local v24 = nil;
            if (v23) then
                v24 = SettingsModule_upv_1.GetSettingFromId(u5);
                if (v24 and v24.AllowMouse) then
                    if (v23) then
                        v24 = ((UserInputType_1 == Enum.UserInputType.MouseButton2) and "MB2") or (UserInputType_1.Name);
                    else
                        v24 = KeyCode_1;
                    end;
                    u7 = v24;
                    value_upv_1(ChangeHotkey_upv_1.Frame.Frame, u7);
                    return;
                end;
                return;
            end;
            if (v23) then
                v24 = ((UserInputType_1 == Enum.UserInputType.MouseButton2) and "MB2") or (UserInputType_1.Name);
            else
                v24 = KeyCode_1;
            end;
            u7 = v24;
            value_upv_1(ChangeHotkey_upv_1.Frame.Frame, u7);
        end;
    end
);
UserInputService_upv_1.InputChanged:Connect(
    function(a1)
        --[[
          line: 211
          upvalues:
            ChangeHotkey_upv_1 (copy, index: 1)
            SettingsModule_upv_1 (ref,  index: 2)
            u5 (ref,  index: 3)
            u7 (ref,  index: 4)
            value_upv_1 (copy, index: 5)
        ]]
        if (ChangeHotkey_upv_1.Visible) then
            local v25;
            if (a1.UserInputType ~= Enum.UserInputType.MouseWheel) then
                return;
            end;
            v25 = SettingsModule_upv_1.GetSettingFromId(u5);
            if (not v25 or not v25.AllowMouse) then
                return;
            end;
            u7 = ((a1.Position.Z <= 0) and "M.WheelDown") or "M.WheelUp";
            value_upv_1(ChangeHotkey_upv_1.Frame.Frame, u7);
        end;
    end
);
UserInputService_upv_1.InputEnded:Connect(
    function(a1)
        --[[
          line: 221
          upvalues:
            u4 (ref,  index: 1)
            u10 (copy, index: 2)
            u6 (ref,  index: 3)
            SettingRemotes_upv_1 (copy, index: 4)
            ReplicatedStorage_upv_1 (copy, index: 5)
        ]]
        local UserInputType_2 = a1.UserInputType;
        local v26 = true;
        if (UserInputType_2 ~= Enum.UserInputType.MouseButton1) then
            v26 = false;
            if (UserInputType_2 == Enum.UserInputType.Gamepad1) then
                v26 = a1.KeyCode == Enum.KeyCode.ButtonA;
            end;
        end;
        if (v26) then
            local v27;
            if (not u4) then
                return;
            end;
            v27 = u10[u4];
            if (v27 ~= u6) then
                SettingRemotes_upv_1.Update:FireServer("Settings", u4, v27);
                ReplicatedStorage_upv_1:SetAttribute("Settings", true);
            end;
            u4 = nil;
        end;
    end
);
v1.new(
    ChangeHotkey_upv_1:WaitForChild("Frame"):WaitForChild("Cancel"),
    "BackgroundColor3",
    function()
        --[[
          line: 234
          upvalues:
            ChangeHotkey_upv_1 (copy, index: 1)
        ]]
        ChangeHotkey_upv_1.Visible = false;
    end,
    1.3,
    1
);
v1.new(
    ChangeHotkey_upv_1.Frame.Save,
    "BackgroundColor3",
    function()
        --[[
          line: 237
          upvalues:
            u7 (ref,  index: 1)
            ChangeHotkey_upv_1 (copy, index: 2)
            u10 (copy, index: 3)
            u5 (ref,  index: 4)
            u11 (ref,  index: 5)
            SettingRemotes_upv_1 (copy, index: 6)
            ReplicatedStorage_upv_1 (copy, index: 7)
            value_upv_1 (copy, index: 8)
            u8 (ref,  index: 9)
        ]]
        if (u7) then
            ChangeHotkey_upv_1.Visible = false;
            if (type(u7) ~= "string") then
                local Name_1 = u7.Name;
            end;
            local Name_1;
            if (Name_1 ~= u10[u5]) then
                local v28 = u5;
                u10[v28] = Name_1;
                u11();
                SettingRemotes_upv_1.Update:FireServer("Settings", v28, Name_1);
                ReplicatedStorage_upv_1:SetAttribute("Settings", true);
                value_upv_1(u8, Name_1);
            end;
        end;
    end,
    1.3,
    1
);
v1.new(
    Reset_upv_1,
    "BackgroundColor3",
    function()
        --[[
          line: 246
          upvalues:
            ConfirmReset_upv_1 (copy, index: 1)
            u9 (ref,  index: 2)
            u3 (ref,  index: 3)
        ]]
        if (ConfirmReset_upv_1.Visible) then
            return;
        end;
        u9 = u3;
        ConfirmReset_upv_1.Frame.Category.Text = u9;
        ConfirmReset_upv_1.Visible = true;
    end,
    1.3,
    1
);
v1.new(
    ConfirmReset_upv_1:WaitForChild("Frame"):WaitForChild("Cancel"),
    "BackgroundColor3",
    function()
        --[[
          line: 252
          upvalues:
            ConfirmReset_upv_1 (copy, index: 1)
            u9 (ref,  index: 2)
        ]]
        ConfirmReset_upv_1.Visible = false;
        u9 = nil;
    end,
    1.3,
    1
);
v1.new(
    ConfirmReset_upv_1.Frame.Reset,
    "BackgroundColor3",
    function()
        --[[
          line: 256
          upvalues:
            u9 (ref,  index: 1)
            SettingRemotes_upv_1 (copy, index: 2)
            SettingsModule_upv_1 (ref,  index: 3)
            u10 (copy, index: 4)
            u14 (copy, index: 5)
            u11 (ref,  index: 6)
            ConfirmReset_upv_1 (copy, index: 7)
        ]]
        if (not u9) then
            return;
        end;
        if (SettingRemotes_upv_1.Reset:InvokeServer(u9)) then
            SettingsModule_upv_1.ResetSettings(
                u10,
                u9,
                function(a1, a2)
                    --[[
                      line: 260
                      upvalues:
                        u14 (copy, index: 1)
                        u9 (ref,  index: 2)
                    ]]
                    u14(u9, a1, nil, a2, false);
                end
            );
            u11();
        end;
        ConfirmReset_upv_1.Visible = false;
        u9 = nil;
    end,
    1.3,
    1
);
local Frame_1 = nil;
local v29 = nil;
local v44 = nil;
local v45 = nil;
local v30 = nil;
local Id_upv_1 = nil;
local v31 = nil;
local v32 = nil;
for v46, value_upv_3 in SettingsModule_upv_1.Categories do
    Frame_1 = Menus_upv_1:WaitForChild(value_upv_3):WaitForChild("Frame");
    v29 = TopButtons_1:WaitForChild(value_upv_3);
    tbl_upv_1[value_upv_3] = v1.new(
        v29,
        "TextColor3",
        function()
            --[[
              line: 275
              upvalues:
                u12 (copy, index: 1)
                value_upv_3 (copy, index: 2)
            ]]
            u12(value_upv_3);
        end,
        0.8,
        Color3.fromRGB(255, 225, 0),
        nil,
        v29.TextLabel
    );
    v32 = SettingsModule_upv_1.Config[value_upv_3];
    if (not (v32)) then
        continue;
    end;
    v30 = nil;
    Id_upv_1 = nil;
    for v47, value_upv_4 in v32 do
        v30 = value_upv_4.Type;
        Id_upv_1 = value_upv_4.Id;
        v31 = script[v30]:Clone();
        if (v30 == "Checkbox") then
            local ClickButton_upv_1 = v31.ClickButton;
            ClickButton_upv_1.Activated:Connect(
                function()
                    --[[
                      line: 286
                      upvalues:
                        u10 (copy, index: 1)
                        Id_upv_1 (copy, index: 2)
                        u11 (ref,  index: 3)
                        SettingRemotes_upv_1 (copy, index: 4)
                        ReplicatedStorage_upv_1 (copy, index: 5)
                        key_upv_1 (copy, index: 6)
                        ClickButton_upv_1 (copy, index: 7)
                    ]]
                    local v33 = not u10[Id_upv_1];
                    local v34 = Id_upv_1;
                    u10[v34] = v33;
                    u11();
                    SettingRemotes_upv_1.Update:FireServer("Settings", v34, v33);
                    ReplicatedStorage_upv_1:SetAttribute("Settings", true);
                    key_upv_1(ClickButton_upv_1, v33);
                end
            );
        elseif (v30 == "Slider") then
            local DragSlider_upv_1 = v31.DragSlider;
            local NumberDisplay_upv_1 = DragSlider_upv_1.Frame.NumberDisplay;
            local u15 = value_upv_4.Range[1];
            local u16 = value_upv_4.Range[2];
            local SliderStep_upv_1 = value_upv_4.SliderStep;
            local InputStep_upv_1 = value_upv_4.InputStep;
            DragSlider_upv_1.MouseButton1Down:Connect(
                function()
                    --[[
                      line: 298
                      upvalues:
                        u4 (ref,  index: 1)
                        Id_upv_1 (copy, index: 2)
                        u6 (ref,  index: 3)
                        u10 (copy, index: 4)
                        DragSlider_upv_1 (copy, index: 5)
                        u1 (copy, index: 6)
                        NumberUtil_upv_1 (ref,  index: 7)
                        u15 (copy, index: 8)
                        u16 (copy, index: 9)
                        SliderStep_upv_1 (copy, index: 10)
                        u13 (copy, index: 11)
                        value_upv_4 (copy, index: 12)
                        u11 (ref,  index: 13)
                    ]]
                    if (u4) then
                        return;
                    end;
                    u4 = Id_upv_1;
                    u6 = u10[Id_upv_1];
                    while (Id_upv_1) do
                        local v35;
                        if (not (DragSlider_upv_1.Parent)) then
                            break;
                        end;
                        v35 = math.max(math.round(NumberUtil_upv_1:Lerp(u15, u16, math.min(math.max(u1.X - DragSlider_upv_1.AbsolutePosition.X, 0) / DragSlider_upv_1.AbsoluteSize.X, 1)) / SliderStep_upv_1) * SliderStep_upv_1, u15);
                        if (v35 ~= u10[Id_upv_1]) then
                            u10[Id_upv_1] = u13(DragSlider_upv_1, v35, value_upv_4, false);
                            u11();
                        end;
                        task.wait();
                    end;
                end
            );
            NumberDisplay_upv_1:GetPropertyChangedSignal("Text"):Connect(
                function()
                    --[[
                      line: 315
                      upvalues:
                        DragSlider_upv_1 (copy, index: 1)
                        NumberDisplay_upv_1 (copy, index: 2)
                        u13 (copy, index: 3)
                        value_upv_4 (copy, index: 4)
                    ]]
                    local v36;
                    if (not DragSlider_upv_1.Parent) then
                        return;
                    end;
                    v36 = tonumber(NumberDisplay_upv_1.Text);
                    if (not v36) then
                        return;
                    end;
                    u13(DragSlider_upv_1, v36, value_upv_4, true);
                end
            );
            NumberDisplay_upv_1.FocusLost:Connect(
                function()
                    --[[
                      line: 321
                      upvalues:
                        DragSlider_upv_1 (copy, index: 1)
                        u10 (copy, index: 2)
                        Id_upv_1 (copy, index: 3)
                        NumberDisplay_upv_1 (copy, index: 4)
                        u13 (copy, index: 5)
                        value_upv_4 (copy, index: 6)
                        InputStep_upv_1 (copy, index: 7)
                        u15 (copy, index: 8)
                        u11 (ref,  index: 9)
                        SettingRemotes_upv_1 (copy, index: 10)
                        ReplicatedStorage_upv_1 (copy, index: 11)
                    ]]
                    local v37 = nil;
                    if (DragSlider_upv_1.Parent) then
                        local v38 = u10[Id_upv_1];
                        v37 = tonumber(NumberDisplay_upv_1.Text);
                        local v39 = nil;
                        if (v37) then
                            v39 = u13(DragSlider_upv_1, math.max(math.round(v37 / InputStep_upv_1) * InputStep_upv_1, u15), value_upv_4, false);
                            if (v39 ~= u10[Id_upv_1]) then
                                local v40 = Id_upv_1;
                                u10[v40] = v39;
                                u11();
                                SettingRemotes_upv_1.Update:FireServer("Settings", v40, v39);
                                ReplicatedStorage_upv_1:SetAttribute("Settings", true);
                            end;
                        else
                            u13(DragSlider_upv_1, v38, value_upv_4, false);
                        end;
                    end;
                end
            );
        elseif (v30 == "Keybind") then
            local ClickButton_upv_2 = v31.ClickButton;
            ClickButton_upv_2.Activated:Connect(
                function()
                    --[[
                      line: 336
                      upvalues:
                        value_upv_3 (copy, index: 1)
                        u2 (copy, index: 2)
                        u10 (copy, index: 3)
                        Id_upv_1 (copy, index: 4)
                        value_upv_1 (copy, index: 5)
                        ChangeHotkey_upv_1 (copy, index: 6)
                        u5 (ref,  index: 7)
                        u7 (ref,  index: 8)
                        u8 (ref,  index: 9)
                        ClickButton_upv_2 (copy, index: 10)
                        value_upv_4 (copy, index: 11)
                    ]]
                    if (value_upv_3 == "Gamepad" and u2 and u2:GetAttribute("PreferredInput") == "Gamepad") then
                        return;
                    end;
                    local v41 = u10[Id_upv_1];
                    if (value_upv_1(ChangeHotkey_upv_1.Frame.Frame, v41, Id_upv_1)) then
                        u5 = Id_upv_1;
                        local v42;
                        if (v41 == "MB2" or v41:find("M.Wheel")) then
                            v42 = v41;
                        else
                            v42 = Enum.KeyCode[v41];
                        end;
                        u7 = v42;
                        u8 = ClickButton_upv_2;
                        ChangeHotkey_upv_1.Frame.HotkeyName.Text = value_upv_4.Text;
                        ChangeHotkey_upv_1.Visible = true;
                    end;
                end
            );
        end;
        if (Id_upv_1) then
            u14(value_upv_3, Id_upv_1, v31, value_upv_4, true);
        end;
        v31.Name = not Id_upv_1 and "Header" or tostring(Id_upv_1);
        v31.Size = UDim2.new(v31.Size.X.Scale, v31.Size.X.Offset, v31.Size.Y.Scale * (((value_upv_3 ~= "Controls") and 1) or 0.8), v31.Size.Y.Offset);
        v31.Description.Text = value_upv_4.Text;
        v31.Parent = Frame_1;
        v31.Visible = true;
    end;
end;
u12(u3, true);