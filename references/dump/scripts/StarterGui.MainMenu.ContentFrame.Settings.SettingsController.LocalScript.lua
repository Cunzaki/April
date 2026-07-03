-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local SettingRemotes = ReplicatedStorage:WaitForChild("SettingRemotes");
local v1 = nil;
local v2, v3, u4, u5, v6, u7, u8, v9, u10, v11, u12, u13, u14, u15, v16, u17, u18, u19, u20, u21, u22, u23, u24, u25, u26, u27, u28, u29, u30, v31, v32, v33, v34, v35, u36, v37, u38, u39, u40, u41, u42, u43, u44, u45;

while true do
    v2 = Modules:FindFirstChild("Shared");
    v3 = nil;

    if not v2 then
        break;
    end;

    local Client = Modules:FindFirstChild("Client");

    if Client then
        v1 = require(Client:WaitForChild("ButtonClass"));

        if v2 then
            u4 = require(v2:WaitForChild("SettingsModule"));
            u5 = require(v2:WaitForChild("NumberUtil"));
            v6 = Players.LocalPlayer;
            u7 = v6:GetMouse();
            u8 = v6:WaitForChild("PlayerScripts"):FindFirstChild("PreferredInputController") or v6:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController", 5);
            v9 = script.Parent;
            u10 = v9:WaitForChild("Menus");
            v11 = v9:WaitForChild("TopButtons");
            u12 = v9:WaitForChild("ChangeHotkey");
            u13 = v9:WaitForChild("ConfirmReset");
            u14 = v9:WaitForChild("Reset");
            u15, v16 = SettingRemotes:WaitForChild("Fetch"):InvokeServer();
            u17 = nil;
            u18 = nil;
            u19 = "General";
            u20 = nil;
            u21 = {};
            u22 = nil;
            u23 = nil;
            u24 = nil;

            for _, v in u4.Config.Gamepad do
                if v.Type == "Keybind" and (v.Id and u15[v.Id] ~= v.DefaultValue) then
                    u15[v.Id] = v.DefaultValue;
                    SettingRemotes.Update:FireServer("Settings", v.Id, v.DefaultValue);
                end;
            end;

            u4.ApplySettings(u15, v16);
            u25 = nil;

            u26 = function(p46, p47) -- Line: 76
                -- upvalues: u19 (ref), u21 (copy), u10 (copy), u25 (ref)
                if u19 == p46 then
                    if not p47 then
                        return;
                    end;
                else
                    local v48 = u21[u19];

                    if v48 and v48:IsToggled() then
                        task.defer(v48.ToggleButton, v48, false);
                    end;

                    u19 = p46;
                end;

                local v49 = u21[p46];

                if v49 and not v49:IsToggled() then
                    task.defer(v49.ToggleButton, v49, true, p47);
                end;

                for _, child in pairs(u10:GetChildren()) do
                    child.Visible = child.Name == p46;
                end;

                u25();
            end;

            u27 = function(p50, p51, p52, p53, p54) -- Line: 96
                -- upvalues: u5 (ref)
                local v55 = p52.Range[1];
                local v56 = p52.Range[2];
                local v57 = math.clamp(p51, v55, v56);
                local v58 = math.max(v57 - v55, 0) / (v56 - v55);

                if v55 > 0 then
                    v58 = 0.02 + v58 * 0.98;
                end;

                local v59 = UDim2.new(v58, 0, 1, 0);

                if p54 then
                    p50.Holder.ColorImage.Size = v59;
                else
                    p50.Holder.ColorImage:TweenSize(v59, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.12, true);
                end;

                if not p53 then
                    p50.Frame.NumberDisplay.Text = tostring(u5:RoundNumber(v57, 3));
                end;

                return v57;
            end;

            u28 = function(p60, p61, p62) -- Line: 114
                local v63 = UDim2.new(p61 and 0.94 or 0.155, 0, 0.88, 0);
                local v64 = UDim2.new(p61 and 1 or 0.215, 0, 0.5, 0);

                if p62 then
                    p60.ColorImage.Size = v63;
                    p60.CircleSlider.Position = v64;

                    return;
                end;

                p60.ColorImage:TweenSize(v63, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true);
                p60.CircleSlider:TweenPosition(v64, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true);
            end;

            u29 = function(p65, u66, p67) -- Line: 126
                -- upvalues: u12 (copy), u4 (ref), u15 (copy), u17 (ref), UserInputService (copy)
                local v68 = false;
                local v69;

                if type(u66) == "string" then
                    if u66 == "MB2" or u66:find("M.Wheel") then
                        v69 = u66;
                        v68 = true;
                    else
                        local v70;
                        v70, v69 = pcall(function() -- Line: 135
                            -- upvalues: u66 (copy)
                            return Enum.KeyCode[u66];
                        end);

                        if not (v70 and v69) then
                            return false;
                        end;

                        u66 = v69.Name;
                    end;
                else
                    v69 = u66;
                    u66 = u66.Name;
                end;

                if p65:IsDescendantOf(u12) then
                    local v71 = u4.CheckKeybind(u15, u66, p67 or u17);
                    u12.Frame.Description.Text = not v71 and "Press a key on your keyboard to adjust this hotkey" or `KEYBIND CANNOT BE SET - CONFLICTING WITH [{v71.Text:upper()}]`;
                    u12.Frame.Save.Visible = v71 == nil;
                end;

                local v72;

                if v68 then
                    v72 = nil;
                else
                    v72 = UserInputService:GetImageForKeyCode(v69);
                end;

                if v72 and v72 ~= "" then
                    p65.KeyImage.Image = v72;
                    p65.KeyImage.Visible = true;
                    p65.KeyText.Visible = false;
                else
                    local v73;

                    if v68 then
                        v73 = u66;
                    else
                        v73 = UserInputService:GetStringForKeyCode(v69);
                    end;

                    if v73 and (v73 ~= "" and v73 ~= " ") then
                        u66 = v73;
                    end;

                    p65.KeyText.Text = u66;
                    p65.KeyImage.Visible = false;
                    p65.KeyText.Visible = true;
                end;

                return true;
            end;

            u30 = function(p74, p75, p76, p77, p78) -- Line: 165
                -- upvalues: u4 (ref), u10 (copy), u15 (copy), u28 (copy), u27 (copy), u29 (copy)
                local v79 = p77 or u4.GetSettingFromId(p75);
                local Type = v79.Type;
                local v80 = p76 or u10[p74].Frame:FindFirstChild((tostring(p75)));

                if not v80 then
                    return;
                end;

                local v81 = u15[p75];

                if Type == "Checkbox" then
                    u28(v80.ClickButton, v81, p78);

                    return;
                end;

                if Type == "Slider" then
                    u27(v80.DragSlider, v81, v79, false, p78);

                    return;
                end;

                if Type == "Keybind" then
                    u29(v80.ClickButton, v81, p75);
                end;
            end;

            u25 = function() -- Line: 184
                -- upvalues: u14 (copy), u4 (ref), u15 (copy), u19 (ref)
                u14.Visible = u4.ResetSettings(u15, u19, false);
            end;

            v31 = function(p82, p83, p84) -- Line: 188
                -- upvalues: u15 (copy), u25 (ref), SettingRemotes (copy), ReplicatedStorage (copy)
                u15[p82] = p83;
                u25();

                if not p84 then
                    return;
                end;

                SettingRemotes.Update:FireServer("Settings", p82, p83);
                ReplicatedStorage:SetAttribute("Settings", true);
            end;

            UserInputService.InputBegan:Connect(function(p85) -- Line: 197
                -- upvalues: u12 (copy), u4 (ref), u17 (ref), u18 (ref), u29 (copy)
                if not u12.Visible then
                    return;
                end;

                local UserInputType = p85.UserInputType;
                local KeyCode = p85.KeyCode;
                local v86 = not KeyCode or KeyCode == Enum.KeyCode.Unknown;

                if v86 and UserInputType ~= Enum.UserInputType.MouseButton2 then
                    return;
                end;

                if v86 then
                    local v87 = u4.GetSettingFromId(u17);

                    if not (v87 and v87.AllowMouse) then
                        return;
                    end;
                end;

                if v86 then
                    KeyCode = UserInputType == Enum.UserInputType.MouseButton2 and "MB2" or UserInputType.Name;
                end;

                u18 = KeyCode;
                u29(u12.Frame.Frame, u18);
            end);
            UserInputService.InputChanged:Connect(function(p88) -- Line: 211
                -- upvalues: u12 (copy), u4 (ref), u17 (ref), u18 (ref), u29 (copy)
                if not u12.Visible then
                    return;
                end;

                if p88.UserInputType ~= Enum.UserInputType.MouseWheel then
                    return;
                end;

                local v89 = u4.GetSettingFromId(u17);

                if not (v89 and v89.AllowMouse) then
                    return;
                end;

                u18 = p88.Position.Z > 0 and "M.WheelUp" or "M.WheelDown";
                u29(u12.Frame.Frame, u18);
            end);
            UserInputService.InputEnded:Connect(function(p90) -- Line: 221
                -- upvalues: u20 (ref), u15 (copy), u22 (ref), SettingRemotes (copy), ReplicatedStorage (copy)
                local UserInputType = p90.UserInputType;
                local v91;

                if UserInputType == Enum.UserInputType.MouseButton1 then
                    v91 = true;
                elseif UserInputType == Enum.UserInputType.Gamepad1 then
                    v91 = p90.KeyCode == Enum.KeyCode.ButtonA;
                else
                    v91 = false;
                end;

                if v91 and u20 then
                    local v92 = u15[u20];

                    if v92 ~= u22 then
                        SettingRemotes.Update:FireServer("Settings", u20, v92);
                        ReplicatedStorage:SetAttribute("Settings", true);
                    end;

                    u20 = nil;
                end;
            end);
            v1.new(u12:WaitForChild("Frame"):WaitForChild("Cancel"), "BackgroundColor3", function() -- Line: 234
                -- upvalues: u12 (copy)
                u12.Visible = false;
            end, 1.3, 1);
            v1.new(u12.Frame.Save, "BackgroundColor3", function() -- Line: 237
                -- upvalues: u18 (ref), u12 (copy), u15 (copy), u17 (ref), u25 (ref), SettingRemotes (copy), ReplicatedStorage (copy), u29 (copy), u23 (ref)
                if not u18 then
                    return;
                end;

                u12.Visible = false;
                local v93;

                if type(u18) == "string" then
                    v93 = u18;
                else
                    v93 = u18.Name;
                end;

                if v93 == u15[u17] then
                    return;
                end;

                local v94 = u17;
                u15[v94] = v93;
                u25();
                SettingRemotes.Update:FireServer("Settings", v94, v93);
                ReplicatedStorage:SetAttribute("Settings", true);
                u29(u23, v93);
            end, 1.3, 1);
            v1.new(u14, "BackgroundColor3", function() -- Line: 246
                -- upvalues: u13 (copy), u24 (ref), u19 (ref)
                if u13.Visible then
                    return;
                end;

                u24 = u19;
                u13.Frame.Category.Text = u24;
                u13.Visible = true;
            end, 1.3, 1);
            v1.new(u13:WaitForChild("Frame"):WaitForChild("Cancel"), "BackgroundColor3", function() -- Line: 252
                -- upvalues: u13 (copy), u24 (ref)
                u13.Visible = false;
                u24 = nil;
            end, 1.3, 1);
            v1.new(u13.Frame.Reset, "BackgroundColor3", function() -- Line: 256
                -- upvalues: u24 (ref), SettingRemotes (copy), u4 (ref), u15 (copy), u30 (copy), u25 (ref), u13 (copy)
                if not u24 then
                    return;
                end;

                if SettingRemotes.Reset:InvokeServer(u24) then
                    u4.ResetSettings(u15, u24, function(p95, p96) -- Line: 260
                        -- upvalues: u30 (ref), u24 (ref)
                        u30(u24, p95, nil, p96, false);
                    end);
                    u25();
                end;

                u13.Visible = false;
                u24 = nil;
            end, 1.3, 1);

            for _, v in u4.Categories do
                v32 = u10:WaitForChild(v):WaitForChild("Frame");
                v33 = v11:WaitForChild(v);
                u21[v] = v1.new(v33, "TextColor3", function() -- Line: 275
                    -- upvalues: u26 (copy), v (copy)
                    u26(v);
                end, 0.8, Color3.fromRGB(255, 225, 0), nil, v33.TextLabel);
                v34 = u4.Config[v];

                if v34 then
                    for _, v4 in v34 do
                        v35 = v4.Type;
                        u36 = v4.Id;
                        v37 = script[v35]:Clone();

                        if v35 == "Checkbox" then
                            u38 = v37.ClickButton;
                            u38.Activated:Connect(function() -- Line: 286
                                -- upvalues: u15 (copy), u36 (copy), u25 (ref), SettingRemotes (copy), ReplicatedStorage (copy), u28 (copy), u38 (copy)
                                local v97 = not u15[u36];
                                local v98 = u36;
                                u15[v98] = v97;
                                u25();
                                SettingRemotes.Update:FireServer("Settings", v98, v97);
                                ReplicatedStorage:SetAttribute("Settings", true);
                                u28(u38, v97);
                            end);
                        elseif v35 == "Slider" then
                            u39 = v37.DragSlider;
                            u40 = u39.Frame.NumberDisplay;
                            u41 = v4.Range[1];
                            u42 = v4.Range[2];
                            u43 = v4.SliderStep;
                            u44 = v4.InputStep;
                            u39.MouseButton1Down:Connect(function() -- Line: 298
                                -- upvalues: u20 (ref), u36 (copy), u22 (ref), u15 (copy), u39 (copy), u7 (copy), u5 (ref), u41 (copy), u42 (copy), u43 (copy), u27 (copy), v4 (copy), u25 (ref)
                                if u20 then
                                    return;
                                end;

                                u20 = u36;
                                u22 = u15[u36];

                                while u20 and u39.Parent do
                                    local X = u39.AbsoluteSize.X;
                                    local v99 = math.max(u7.X - u39.AbsolutePosition.X, 0) / X;
                                    local v100 = u5:Lerp(u41, u42, (math.min(v99, 1))) / u43;
                                    local v101 = math.round(v100) * u43;
                                    local v102 = math.max(v101, u41);

                                    if v102 ~= u15[u36] then
                                        u15[u36] = u27(u39, v102, v4, false);
                                        u25();
                                    end;

                                    task.wait();
                                end;
                            end);
                            u40:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 315
                                -- upvalues: u39 (copy), u40 (copy), u27 (copy), v4 (copy)
                                if not u39.Parent then
                                    return;
                                end;

                                local v103 = tonumber(u40.Text);

                                if not v103 then
                                    return;
                                end;

                                u27(u39, v103, v4, true);
                            end);
                            u40.FocusLost:Connect(function() -- Line: 321
                                -- upvalues: u39 (copy), u15 (copy), u36 (copy), u40 (copy), u27 (copy), v4 (copy), u44 (copy), u41 (copy), u25 (ref), SettingRemotes (copy), ReplicatedStorage (copy)
                                if not u39.Parent then
                                    return;
                                end;

                                local v104 = u15[u36];
                                local v105 = tonumber(u40.Text);

                                if not v105 then
                                    u27(u39, v104, v4, false);

                                    return;
                                end;

                                local v106 = math.round(v105 / u44) * u44;
                                local v107 = u27(u39, math.max(v106, u41), v4, false);

                                if v107 == u15[u36] then
                                    return;
                                end;

                                local v108 = u36;
                                u15[v108] = v107;
                                u25();
                                SettingRemotes.Update:FireServer("Settings", v108, v107);
                                ReplicatedStorage:SetAttribute("Settings", true);
                            end);
                        elseif v35 == "Keybind" then
                            u45 = v37.ClickButton;
                            u45.Activated:Connect(function() -- Line: 336
                                -- upvalues: v (copy), u8 (copy), u15 (copy), u36 (copy), u29 (copy), u12 (copy), u17 (ref), u18 (ref), u23 (ref), u45 (copy), v4 (copy)
                                if v == "Gamepad" and (u8 and u8:GetAttribute("PreferredInput") == "Gamepad") then
                                    return;
                                end;

                                local v109 = u15[u36];

                                if not u29(u12.Frame.Frame, v109, u36) then
                                    return;
                                end;

                                u17 = u36;

                                if v109 ~= "MB2" and not v109:find("M.Wheel") then
                                    v109 = Enum.KeyCode[v109];
                                end;

                                u18 = v109;
                                u23 = u45;
                                u12.Frame.HotkeyName.Text = v4.Text;
                                u12.Visible = true;
                            end);
                        end;

                        if u36 then
                            u30(v, u36, v37, v4, true);
                        end;

                        v37.Name = not u36 and "Header" or tostring(u36);
                        v37.Size = UDim2.new(v37.Size.X.Scale, v37.Size.X.Offset, v37.Size.Y.Scale * (v == "Controls" and 0.8 or 1), v37.Size.Y.Offset);
                        v37.Description.Text = v4.Text;
                        v37.Parent = v32;
                        v37.Visible = true;
                    end;
                end;
            end;

            u26(u19, true);

            return;
        end;

        task.wait();
    end;
end;

if Modules:FindFirstChild("ButtonClass") then
    v1 = require(Modules:WaitForChild("ButtonClass"));
    v2 = Modules;
else
    v2 = v3;
end;

if v2 then
    u4 = require(v2:WaitForChild("SettingsModule"));
    u5 = require(v2:WaitForChild("NumberUtil"));
    v6 = Players.LocalPlayer;
    u7 = v6:GetMouse();
    u8 = v6:WaitForChild("PlayerScripts"):FindFirstChild("PreferredInputController") or v6:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController", 5);
    v9 = script.Parent;
    u10 = v9:WaitForChild("Menus");
    v11 = v9:WaitForChild("TopButtons");
    u12 = v9:WaitForChild("ChangeHotkey");
    u13 = v9:WaitForChild("ConfirmReset");
    u14 = v9:WaitForChild("Reset");
    u15, v16 = SettingRemotes:WaitForChild("Fetch"):InvokeServer();
    u17 = nil;
    u18 = nil;
    u19 = "General";
    u20 = nil;
    u21 = {};
    u22 = nil;
    u23 = nil;
    u24 = nil;

    for _, v in u4.Config.Gamepad do
        if v.Type == "Keybind" and (v.Id and u15[v.Id] ~= v.DefaultValue) then
            u15[v.Id] = v.DefaultValue;
            SettingRemotes.Update:FireServer("Settings", v.Id, v.DefaultValue);
        end;
    end;

    u4.ApplySettings(u15, v16);
    u25 = nil;

    u26 = function(p46, p47) -- Line: 76
        -- upvalues: u19 (ref), u21 (copy), u10 (copy), u25 (ref)
        if u19 == p46 then
            if not p47 then
                return;
            end;
        else
            local v48 = u21[u19];

            if v48 and v48:IsToggled() then
                task.defer(v48.ToggleButton, v48, false);
            end;

            u19 = p46;
        end;

        local v49 = u21[p46];

        if v49 and not v49:IsToggled() then
            task.defer(v49.ToggleButton, v49, true, p47);
        end;

        for _, child in pairs(u10:GetChildren()) do
            child.Visible = child.Name == p46;
        end;

        u25();
    end;

    u27 = function(p50, p51, p52, p53, p54) -- Line: 96
        -- upvalues: u5 (ref)
        local v55 = p52.Range[1];
        local v56 = p52.Range[2];
        local v57 = math.clamp(p51, v55, v56);
        local v58 = math.max(v57 - v55, 0) / (v56 - v55);

        if v55 > 0 then
            v58 = 0.02 + v58 * 0.98;
        end;

        local v59 = UDim2.new(v58, 0, 1, 0);

        if p54 then
            p50.Holder.ColorImage.Size = v59;
        else
            p50.Holder.ColorImage:TweenSize(v59, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.12, true);
        end;

        if not p53 then
            p50.Frame.NumberDisplay.Text = tostring(u5:RoundNumber(v57, 3));
        end;

        return v57;
    end;

    u28 = function(p60, p61, p62) -- Line: 114
        local v63 = UDim2.new(p61 and 0.94 or 0.155, 0, 0.88, 0);
        local v64 = UDim2.new(p61 and 1 or 0.215, 0, 0.5, 0);

        if p62 then
            p60.ColorImage.Size = v63;
            p60.CircleSlider.Position = v64;

            return;
        end;

        p60.ColorImage:TweenSize(v63, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true);
        p60.CircleSlider:TweenPosition(v64, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true);
    end;

    u29 = function(p65, u66, p67) -- Line: 126
        -- upvalues: u12 (copy), u4 (ref), u15 (copy), u17 (ref), UserInputService (copy)
        local v68 = false;
        local v69;

        if type(u66) == "string" then
            if u66 == "MB2" or u66:find("M.Wheel") then
                v69 = u66;
                v68 = true;
            else
                local v70;
                v70, v69 = pcall(function() -- Line: 135
                    -- upvalues: u66 (copy)
                    return Enum.KeyCode[u66];
                end);

                if not (v70 and v69) then
                    return false;
                end;

                u66 = v69.Name;
            end;
        else
            v69 = u66;
            u66 = u66.Name;
        end;

        if p65:IsDescendantOf(u12) then
            local v71 = u4.CheckKeybind(u15, u66, p67 or u17);
            u12.Frame.Description.Text = not v71 and "Press a key on your keyboard to adjust this hotkey" or `KEYBIND CANNOT BE SET - CONFLICTING WITH [{v71.Text:upper()}]`;
            u12.Frame.Save.Visible = v71 == nil;
        end;

        local v72;

        if v68 then
            v72 = nil;
        else
            v72 = UserInputService:GetImageForKeyCode(v69);
        end;

        if v72 and v72 ~= "" then
            p65.KeyImage.Image = v72;
            p65.KeyImage.Visible = true;
            p65.KeyText.Visible = false;
        else
            local v73;

            if v68 then
                v73 = u66;
            else
                v73 = UserInputService:GetStringForKeyCode(v69);
            end;

            if v73 and (v73 ~= "" and v73 ~= " ") then
                u66 = v73;
            end;

            p65.KeyText.Text = u66;
            p65.KeyImage.Visible = false;
            p65.KeyText.Visible = true;
        end;

        return true;
    end;

    u30 = function(p74, p75, p76, p77, p78) -- Line: 165
        -- upvalues: u4 (ref), u10 (copy), u15 (copy), u28 (copy), u27 (copy), u29 (copy)
        local v79 = p77 or u4.GetSettingFromId(p75);
        local Type = v79.Type;
        local v80 = p76 or u10[p74].Frame:FindFirstChild((tostring(p75)));

        if not v80 then
            return;
        end;

        local v81 = u15[p75];

        if Type == "Checkbox" then
            u28(v80.ClickButton, v81, p78);

            return;
        end;

        if Type == "Slider" then
            u27(v80.DragSlider, v81, v79, false, p78);

            return;
        end;

        if Type == "Keybind" then
            u29(v80.ClickButton, v81, p75);
        end;
    end;

    u25 = function() -- Line: 184
        -- upvalues: u14 (copy), u4 (ref), u15 (copy), u19 (ref)
        u14.Visible = u4.ResetSettings(u15, u19, false);
    end;

    v31 = function(p82, p83, p84) -- Line: 188
        -- upvalues: u15 (copy), u25 (ref), SettingRemotes (copy), ReplicatedStorage (copy)
        u15[p82] = p83;
        u25();

        if not p84 then
            return;
        end;

        SettingRemotes.Update:FireServer("Settings", p82, p83);
        ReplicatedStorage:SetAttribute("Settings", true);
    end;

    UserInputService.InputBegan:Connect(function(p85) -- Line: 197
        -- upvalues: u12 (copy), u4 (ref), u17 (ref), u18 (ref), u29 (copy)
        if not u12.Visible then
            return;
        end;

        local UserInputType = p85.UserInputType;
        local KeyCode = p85.KeyCode;
        local v86 = not KeyCode or KeyCode == Enum.KeyCode.Unknown;

        if v86 and UserInputType ~= Enum.UserInputType.MouseButton2 then
            return;
        end;

        if v86 then
            local v87 = u4.GetSettingFromId(u17);

            if not (v87 and v87.AllowMouse) then
                return;
            end;
        end;

        if v86 then
            KeyCode = UserInputType == Enum.UserInputType.MouseButton2 and "MB2" or UserInputType.Name;
        end;

        u18 = KeyCode;
        u29(u12.Frame.Frame, u18);
    end);
    UserInputService.InputChanged:Connect(function(p88) -- Line: 211
        -- upvalues: u12 (copy), u4 (ref), u17 (ref), u18 (ref), u29 (copy)
        if not u12.Visible then
            return;
        end;

        if p88.UserInputType ~= Enum.UserInputType.MouseWheel then
            return;
        end;

        local v89 = u4.GetSettingFromId(u17);

        if not (v89 and v89.AllowMouse) then
            return;
        end;

        u18 = p88.Position.Z > 0 and "M.WheelUp" or "M.WheelDown";
        u29(u12.Frame.Frame, u18);
    end);
    UserInputService.InputEnded:Connect(function(p90) -- Line: 221
        -- upvalues: u20 (ref), u15 (copy), u22 (ref), SettingRemotes (copy), ReplicatedStorage (copy)
        local UserInputType = p90.UserInputType;
        local v91;

        if UserInputType == Enum.UserInputType.MouseButton1 then
            v91 = true;
        elseif UserInputType == Enum.UserInputType.Gamepad1 then
            v91 = p90.KeyCode == Enum.KeyCode.ButtonA;
        else
            v91 = false;
        end;

        if v91 and u20 then
            local v92 = u15[u20];

            if v92 ~= u22 then
                SettingRemotes.Update:FireServer("Settings", u20, v92);
                ReplicatedStorage:SetAttribute("Settings", true);
            end;

            u20 = nil;
        end;
    end);
    v1.new(u12:WaitForChild("Frame"):WaitForChild("Cancel"), "BackgroundColor3", function() -- Line: 234
        -- upvalues: u12 (copy)
        u12.Visible = false;
    end, 1.3, 1);
    v1.new(u12.Frame.Save, "BackgroundColor3", function() -- Line: 237
        -- upvalues: u18 (ref), u12 (copy), u15 (copy), u17 (ref), u25 (ref), SettingRemotes (copy), ReplicatedStorage (copy), u29 (copy), u23 (ref)
        if not u18 then
            return;
        end;

        u12.Visible = false;
        local v93;

        if type(u18) == "string" then
            v93 = u18;
        else
            v93 = u18.Name;
        end;

        if v93 == u15[u17] then
            return;
        end;

        local v94 = u17;
        u15[v94] = v93;
        u25();
        SettingRemotes.Update:FireServer("Settings", v94, v93);
        ReplicatedStorage:SetAttribute("Settings", true);
        u29(u23, v93);
    end, 1.3, 1);
    v1.new(u14, "BackgroundColor3", function() -- Line: 246
        -- upvalues: u13 (copy), u24 (ref), u19 (ref)
        if u13.Visible then
            return;
        end;

        u24 = u19;
        u13.Frame.Category.Text = u24;
        u13.Visible = true;
    end, 1.3, 1);
    v1.new(u13:WaitForChild("Frame"):WaitForChild("Cancel"), "BackgroundColor3", function() -- Line: 252
        -- upvalues: u13 (copy), u24 (ref)
        u13.Visible = false;
        u24 = nil;
    end, 1.3, 1);
    v1.new(u13.Frame.Reset, "BackgroundColor3", function() -- Line: 256
        -- upvalues: u24 (ref), SettingRemotes (copy), u4 (ref), u15 (copy), u30 (copy), u25 (ref), u13 (copy)
        if not u24 then
            return;
        end;

        if SettingRemotes.Reset:InvokeServer(u24) then
            u4.ResetSettings(u15, u24, function(p95, p96) -- Line: 260
                -- upvalues: u30 (ref), u24 (ref)
                u30(u24, p95, nil, p96, false);
            end);
            u25();
        end;

        u13.Visible = false;
        u24 = nil;
    end, 1.3, 1);

    for _, v in u4.Categories do
        v32 = u10:WaitForChild(v):WaitForChild("Frame");
        v33 = v11:WaitForChild(v);
        u21[v] = v1.new(v33, "TextColor3", function() -- Line: 275
            -- upvalues: u26 (copy), v (copy)
            u26(v);
        end, 0.8, Color3.fromRGB(255, 225, 0), nil, v33.TextLabel);
        v34 = u4.Config[v];

        if v34 then
            for _, v4 in v34 do
                v35 = v4.Type;
                u36 = v4.Id;
                v37 = script[v35]:Clone();

                if v35 == "Checkbox" then
                    u38 = v37.ClickButton;
                    u38.Activated:Connect(function() -- Line: 286
                        -- upvalues: u15 (copy), u36 (copy), u25 (ref), SettingRemotes (copy), ReplicatedStorage (copy), u28 (copy), u38 (copy)
                        local v97 = not u15[u36];
                        local v98 = u36;
                        u15[v98] = v97;
                        u25();
                        SettingRemotes.Update:FireServer("Settings", v98, v97);
                        ReplicatedStorage:SetAttribute("Settings", true);
                        u28(u38, v97);
                    end);
                elseif v35 == "Slider" then
                    u39 = v37.DragSlider;
                    u40 = u39.Frame.NumberDisplay;
                    u41 = v4.Range[1];
                    u42 = v4.Range[2];
                    u43 = v4.SliderStep;
                    u44 = v4.InputStep;
                    u39.MouseButton1Down:Connect(function() -- Line: 298
                        -- upvalues: u20 (ref), u36 (copy), u22 (ref), u15 (copy), u39 (copy), u7 (copy), u5 (ref), u41 (copy), u42 (copy), u43 (copy), u27 (copy), v4 (copy), u25 (ref)
                        if u20 then
                            return;
                        end;

                        u20 = u36;
                        u22 = u15[u36];

                        while u20 and u39.Parent do
                            local X = u39.AbsoluteSize.X;
                            local v99 = math.max(u7.X - u39.AbsolutePosition.X, 0) / X;
                            local v100 = u5:Lerp(u41, u42, (math.min(v99, 1))) / u43;
                            local v101 = math.round(v100) * u43;
                            local v102 = math.max(v101, u41);

                            if v102 ~= u15[u36] then
                                u15[u36] = u27(u39, v102, v4, false);
                                u25();
                            end;

                            task.wait();
                        end;
                    end);
                    u40:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 315
                        -- upvalues: u39 (copy), u40 (copy), u27 (copy), v4 (copy)
                        if not u39.Parent then
                            return;
                        end;

                        local v103 = tonumber(u40.Text);

                        if not v103 then
                            return;
                        end;

                        u27(u39, v103, v4, true);
                    end);
                    u40.FocusLost:Connect(function() -- Line: 321
                        -- upvalues: u39 (copy), u15 (copy), u36 (copy), u40 (copy), u27 (copy), v4 (copy), u44 (copy), u41 (copy), u25 (ref), SettingRemotes (copy), ReplicatedStorage (copy)
                        if not u39.Parent then
                            return;
                        end;

                        local v104 = u15[u36];
                        local v105 = tonumber(u40.Text);

                        if not v105 then
                            u27(u39, v104, v4, false);

                            return;
                        end;

                        local v106 = math.round(v105 / u44) * u44;
                        local v107 = u27(u39, math.max(v106, u41), v4, false);

                        if v107 == u15[u36] then
                            return;
                        end;

                        local v108 = u36;
                        u15[v108] = v107;
                        u25();
                        SettingRemotes.Update:FireServer("Settings", v108, v107);
                        ReplicatedStorage:SetAttribute("Settings", true);
                    end);
                elseif v35 == "Keybind" then
                    u45 = v37.ClickButton;
                    u45.Activated:Connect(function() -- Line: 336
                        -- upvalues: v (copy), u8 (copy), u15 (copy), u36 (copy), u29 (copy), u12 (copy), u17 (ref), u18 (ref), u23 (ref), u45 (copy), v4 (copy)
                        if v == "Gamepad" and (u8 and u8:GetAttribute("PreferredInput") == "Gamepad") then
                            return;
                        end;

                        local v109 = u15[u36];

                        if not u29(u12.Frame.Frame, v109, u36) then
                            return;
                        end;

                        u17 = u36;

                        if v109 ~= "MB2" and not v109:find("M.Wheel") then
                            v109 = Enum.KeyCode[v109];
                        end;

                        u18 = v109;
                        u23 = u45;
                        u12.Frame.HotkeyName.Text = v4.Text;
                        u12.Visible = true;
                    end);
                end;

                if u36 then
                    u30(v, u36, v37, v4, true);
                end;

                v37.Name = not u36 and "Header" or tostring(u36);
                v37.Size = UDim2.new(v37.Size.X.Scale, v37.Size.X.Offset, v37.Size.Y.Scale * (v == "Controls" and 0.8 or 1), v37.Size.Y.Offset);
                v37.Description.Text = v4.Text;
                v37.Parent = v32;
                v37.Visible = true;
            end;
        end;
    end;

    u26(u19, true);

    return;
end;

task.wait();