-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local UserInputService_upv_1 = game:GetService("UserInputService");
local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local RunService_upv_1 = game:GetService("RunService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Drops_1 = workspace:WaitForChild("Drops");
local VFX_1 = workspace:WaitForChild("VFX");
local Animals_1 = workspace:WaitForChild("Animals");
local Plants_1 = workspace:WaitForChild("Plants");
local RaycastUtil_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
local GamepadIconModule_1 = require(Modules_1:WaitForChild("GamepadIconModule"));
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local PlayerScripts_1 = LocalPlayer_upv_1:WaitForChild("PlayerScripts");
local PlayerGui_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui");
local Parent_1 = script.Parent;
local Humanoid_upv_1 = nil;
local u1 = nil;
local v1 = nil;
while (true) do
    if (not (Humanoid_upv_1)) then
        Humanoid_upv_1 = Parent_1:FindFirstChild("Humanoid");
    end;
    u1 = u1 or (Parent_1:FindFirstChild("HumanoidRootPart"));
    v1 = v1 or (Parent_1:FindFirstChild("Head"));
    if (not (Humanoid_upv_1) or not (u1)) then
        task.wait(0.1);
        continue;
    end;
    if (v1) then
        break;
    end;
    task.wait(0.1);
end;
local ViewmodelController_upv_1 = Parent_1:WaitForChild("ViewmodelController");
local InventoryController_upv_1 = Parent_1:WaitForChild("InventoryController");
local WaterController_upv_1 = Parent_1:WaitForChild("WaterController");
local WheelController_upv_1 = Parent_1:WaitForChild("WheelController");
local TeamNavigationController_upv_1 = Parent_1:WaitForChild("TeamNavigationController");
local WeatherController_1 = PlayerScripts_1:WaitForChild("WeatherController");
local PreferredInputController_upv_1 = PlayerScripts_1:WaitForChild("PreferredInputController");
local ChatController_upv_1 = PlayerScripts_1:WaitForChild("ChatController");
local _ = require(PlayerScripts_1:WaitForChild("PlayerModule"):WaitForChild("ControlModule"));
local function getDeadzone_1()
    --[[
      name: getDeadzone
      line: 65
      upvalues:
        PreferredInputController_upv_1 (copy, index: 1)
    ]]
    return PreferredInputController_upv_1:GetAttribute("JoystickDeadzone") or 0.225;
end;
local Main_1 = PlayerGui_1:WaitForChild("Main");
local GamepadControls_upv_1 = Main_1:WaitForChild("GamepadControls");
local Codelock_upv_1 = Main_1:WaitForChild("Codelock");
local GamepadImage_1 = ReplicatedStorage_1:WaitForChild("VFX"):WaitForChild("Info"):WaitForChild("Action"):WaitForChild("GamepadImage");
local TopControls_1 = GamepadControls_upv_1:WaitForChild("TopControls");
local ToolTip_1 = GamepadControls_upv_1:WaitForChild("ToolTip");
local Interaction_1 = GamepadControls_upv_1:WaitForChild("Interaction");
local tbl_1 = {};
local u2 = nil;
for v2, v3 in pairs(ToolTip_1:GetChildren()) do
    if (v3:IsA("TextLabel")) then
        table.insert(tbl_1, v3);
    end;
end;
local u3 = false;
u2 = false;
local v4;
v4 = tick();
local v2 = false;
local v3 = RaycastUtil_1:FilterFunction("View");
local tbl_upv_2 = {};
GamepadIconModule_1.Register(TopControls_1.Inventory.ImageLabel, "ButtonY");
GamepadIconModule_1.Register(TopControls_1.Interact.ImageLabel, "ButtonA");
GamepadIconModule_1.Register(TopControls_1.ToggleUINavigation.ImageLabel, "ButtonB");
if (tbl_1[1]) then
    GamepadIconModule_1.Register(tbl_1[1].ImageLabel, "ButtonA");
end;
if (tbl_1[2]) then
    GamepadIconModule_1.Register(tbl_1[2].ImageLabel, "ButtonX");
end;
GamepadIconModule_1.Register(Interaction_1.xtra.ImageLabel, "ButtonX");
GamepadIconModule_1.Register(GamepadImage_1, "ButtonX");
local function u4()
    --[[
      line: 113
      upvalues:
        tbl_upv_2 (copy, index: 1)
        PreferredInputController_upv_1 (copy, index: 2)
        InventoryController_upv_1 (copy, index: 3)
        WheelController_upv_1 (copy, index: 4)
        TeamNavigationController_upv_1 (copy, index: 5)
        Codelock_upv_1 (copy, index: 6)
        SettingsModule_upv_1 (copy, index: 7)
        ChatController_upv_1 (copy, index: 8)
        u3 (ref,  index: 9)
        ViewmodelController_upv_1 (copy, index: 10)
        WaterController_upv_1 (copy, index: 11)
        u2 (ref,  index: 12)
        Humanoid_upv_1 (ref,  index: 13)
        LocalPlayer_upv_1 (copy, index: 14)
        u1 (ref,  index: 15)
    ]]
    local v5 = "";
    local Forward_1 = tbl_upv_2.Forward;
    local Backward_1 = tbl_upv_2.Backward;
    if (not (Forward_1) or Backward_1) then
        if (Backward_1 and not (Forward_1)) then
            v5 = v5 .. "Backward";
        end;
    else
        v5 = v5 .. "Forward";
    end;
    if (not (tbl_upv_2.Left) or tbl_upv_2.Right) then
        if (tbl_upv_2.Right and not (tbl_upv_2.Left)) then
            v5 = v5 .. "Right";
        end;
    else
        v5 = v5 .. "Left";
    end;
    local v6 = PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad";
    local v7 = InventoryController_upv_1:GetAttribute("Open") and v6;
    local v8 = WheelController_upv_1:GetAttribute("Open") and v6;
    local v9 = TeamNavigationController_upv_1:GetAttribute("MapOpen") and v6;
    local v10 = SettingsModule_upv_1.MainMenuOpen() and v6;
    local v11 = ChatController_upv_1:GetAttribute("Typing") and v6;
    local v12 = v5 == "Forward";
    if (tbl_upv_2.Sprint) then
        u3 = true;
    elseif (not (v12)) then
        u3 = false;
    end;
    local v13 = ViewmodelController_upv_1:GetAttribute("Aiming");
    local v14 = ViewmodelController_upv_1:GetAttribute("Using");
    local v15 = WaterController_upv_1:GetAttribute("IsSwim");
    local v16 = u2 or (tbl_upv_2.Crouch);
    if (u3 and v12) then
        local _ = v16 or (v13 or ((v14 and (not ViewmodelController_upv_1:GetAttribute("CanUse"))) or (v15 or (script:GetAttribute("IsClimbing")))));
    end;
    local v17 = (Humanoid_upv_1:GetAttribute("DamageConnections") or 0) > 0;
    script:SetAttribute("Direction", v5);
    script:SetAttribute("IsSprint", u3);
    script:SetAttribute("IsCrouch", v16);
    script:SetAttribute("IsSlowed", v17);
    local v18;
    if (v7 or v8 or v9 or Codelock_upv_1.Visible and v6 or v10 or v11) then
        v18 = 0;
    else
        local v19;
        if (Humanoid_upv_1:GetAttribute("Downed")) then
            v19 = 0;
        else
            local _ = v16 and 6.5 or u3 and 18 or 11;
            local v21 = v13 and 0.8 or 1;
            v19 = (v16 and 6.5 or u3 and 18 or 11) * (v13 and 0.8 or 1) * (v17 and 0.3 or 1);
        end;
        local v20 = v19 * (ViewmodelController_upv_1:GetAttribute("SReduction") or 1);
        v19 = ((not (LocalPlayer_upv_1:GetAttribute("Armor_HasFlippers"))) and 1) or ((v15 and 1.5) or 0.5);
        v18 = v20 * v19;
    end;
    Humanoid_upv_1.WalkSpeed = v18;
    Humanoid_upv_1.HipHeight = (v16 and 1.1) or 1.6;
    Humanoid_upv_1.MaxSlopeAngle = (v15 and 80) or 60;
    Humanoid_upv_1.JumpHeight = (v17 and 0) or 3.25;
    u1.Size = Vector3.new(2, (v16 and 2.1) or 2.5, 2);
end;
UserInputService_upv_1.InputChanged:Connect(
    function(a1)
        --[[
          line: 161
          upvalues:
            PreferredInputController_upv_1 (copy, index: 1)
            tbl_upv_2 (copy, index: 2)
            u4 (copy, index: 3)
        ]]
        if (PreferredInputController_upv_1:GetAttribute("PreferredInput") ~= "Gamepad" or a1.UserInputType ~= Enum.UserInputType.Gamepad1) then
            return;
        end;
        if (a1.KeyCode == Enum.KeyCode.Thumbstick1) then
            local Position_1 = a1.Position;
            local X_1 = Position_1.X;
            local Y_1 = Position_1.Y;
            local v21 = PreferredInputController_upv_1:GetAttribute("JoystickDeadzone") or 0.225;
            local tbl_3 = {};
            tbl_3.Forward = v21 < Y_1;
            tbl_3.Backward = Y_1 < -v21;
            tbl_3.Right = v21 < X_1;
            tbl_3.Left = X_1 < -v21;
            local v22 = false;
            for key_1, value_1 in tbl_3 do
                if (tbl_upv_2[key_1] ~= value_1) then
                    tbl_upv_2[key_1] = value_1;
                    v22 = true;
                end;
            end;
            if (v22) then
                u4();
            end;
        end;
    end
);
UserInputService_upv_1.InputBegan:Connect(
    function(a1)
        --[[
          line: 197
          upvalues:
            SettingsModule_upv_1 (copy, index: 1)
            PreferredInputController_upv_1 (copy, index: 2)
            TeamNavigationController_upv_1 (copy, index: 3)
            Codelock_upv_1 (copy, index: 4)
            InventoryController_upv_1 (copy, index: 5)
            UserInputService_upv_1 (copy, index: 6)
            tbl_upv_2 (copy, index: 7)
            ChatController_upv_1 (copy, index: 8)
            u4 (copy, index: 9)
        ]]
        local v23 = nil;
        if (not SettingsModule_upv_1.MainMenuOpen()) then
            if (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad") then
                v23 = TeamNavigationController_upv_1:GetAttribute("MapOpen") or (tick() - (TeamNavigationController_upv_1:GetAttribute("MapClosedTick") or 0) < 0.15);
                if (not (InventoryController_upv_1:GetAttribute("Open")) and not (v23) and not (Codelock_upv_1) and tick() - (InventoryController_upv_1:GetAttribute("ClosedTick") or 0) >= 0.15) then
                    v23 = a1.UserInputType;
                    local v24 = UserInputService_upv_1:GetFocusedTextBox();
                    if (v23 == Enum.UserInputType.Keyboard or v23 == Enum.UserInputType.Gamepad1) then
                        local v25 = nil;
                        if (not (v24)) then
                            v25 = a1.KeyCode.Name;
                            local v26 = false;
                            if (v25 == SettingsModule_upv_1.GetSetting("Controls", "Move Forward")) then
                                tbl_upv_2.Forward = true;
                                v26 = true;
                            elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Move Backward")) then
                                tbl_upv_2.Backward = true;
                                v26 = true;
                            elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Move Right")) then
                                tbl_upv_2.Right = true;
                                v26 = true;
                            elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Move Left")) then
                                tbl_upv_2.Left = true;
                                v26 = true;
                            elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Sprint")) then
                                local v27 = not SettingsModule_upv_1.GetSetting("Controls", "Toggle Sprint") and true or not tbl_upv_2.Sprint;
                                tbl_upv_2.Sprint = v27;
                                v26 = true;
                            elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Crouch")) then
                                local v28 = not SettingsModule_upv_1.GetSetting("Controls", "Toggle Crouch") and true or not tbl_upv_2.Crouch;
                                tbl_upv_2.Crouch = v28;
                                v26 = true;
                            elseif (v25 ~= SettingsModule_upv_1.GetSetting("Gamepad", "Sprint")) then
                                local v29 = nil;
                                if (v25 == SettingsModule_upv_1.GetSetting("Gamepad", "Crouch")) then
                                    v29 = ChatController_upv_1:GetAttribute("Typing");
                                    if (not (v29)) then
                                        local v30 = not SettingsModule_upv_1.GetSetting("Gamepad", "Toggle Crouch") and true or not tbl_upv_2.Crouch;
                                        tbl_upv_2.Crouch = v30;
                                        v26 = true;
                                    else
                                        v26 = v29;
                                    end;
                                end;
                            else
                                local v31 = not SettingsModule_upv_1.GetSetting("Gamepad", "Toggle Sprint") and true or not tbl_upv_2.Sprint;
                                tbl_upv_2.Sprint = v31;
                                v26 = true;
                            end;
                            if (not v26) then
                                return;
                            end;
                            u4();
                        end;
                    end;
                    return;
                end;
                return;
            end;
            v23 = a1.UserInputType;
            local v24 = UserInputService_upv_1:GetFocusedTextBox();
            if (v23 == Enum.UserInputType.Keyboard or v23 == Enum.UserInputType.Gamepad1) then
                local v25 = nil;
                if (not (v24)) then
                    v25 = a1.KeyCode.Name;
                    local v26 = false;
                    if (v25 == SettingsModule_upv_1.GetSetting("Controls", "Move Forward")) then
                        tbl_upv_2.Forward = true;
                        v26 = true;
                    elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Move Backward")) then
                        tbl_upv_2.Backward = true;
                        v26 = true;
                    elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Move Right")) then
                        tbl_upv_2.Right = true;
                        v26 = true;
                    elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Move Left")) then
                        tbl_upv_2.Left = true;
                        v26 = true;
                    elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Sprint")) then
                        local v27 = not SettingsModule_upv_1.GetSetting("Controls", "Toggle Sprint") and true or not tbl_upv_2.Sprint;
                        tbl_upv_2.Sprint = v27;
                        v26 = true;
                    elseif (v25 == SettingsModule_upv_1.GetSetting("Controls", "Crouch")) then
                        local v28 = not SettingsModule_upv_1.GetSetting("Controls", "Toggle Crouch") and true or not tbl_upv_2.Crouch;
                        tbl_upv_2.Crouch = v28;
                        v26 = true;
                    elseif (v25 ~= SettingsModule_upv_1.GetSetting("Gamepad", "Sprint")) then
                        local v29 = nil;
                        if (v25 == SettingsModule_upv_1.GetSetting("Gamepad", "Crouch")) then
                            v29 = ChatController_upv_1:GetAttribute("Typing");
                            if (not (v29)) then
                                local v30 = not SettingsModule_upv_1.GetSetting("Gamepad", "Toggle Crouch") and true or not tbl_upv_2.Crouch;
                                tbl_upv_2.Crouch = v30;
                                v26 = true;
                            else
                                v26 = v29;
                            end;
                        end;
                    else
                        local v31 = not SettingsModule_upv_1.GetSetting("Gamepad", "Toggle Sprint") and true or not tbl_upv_2.Sprint;
                        tbl_upv_2.Sprint = v31;
                        v26 = true;
                    end;
                    if (not v26) then
                        return;
                    end;
                    u4();
                end;
            end;
        end;
    end
);
UserInputService_upv_1.InputEnded:Connect(
    function(a1)
        --[[
          line: 238
          upvalues:
            PreferredInputController_upv_1 (copy, index: 1)
            TeamNavigationController_upv_1 (copy, index: 2)
            Codelock_upv_1 (copy, index: 3)
            InventoryController_upv_1 (copy, index: 4)
            UserInputService_upv_1 (copy, index: 5)
            SettingsModule_upv_1 (copy, index: 6)
            tbl_upv_2 (copy, index: 7)
            u4 (copy, index: 8)
        ]]
        if (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad") then
            local v32 = TeamNavigationController_upv_1:GetAttribute("MapOpen") or (tick() - (TeamNavigationController_upv_1:GetAttribute("MapClosedTick") or 0) < 0.15);
            if (not (InventoryController_upv_1:GetAttribute("Open")) and not (v32) and not (Codelock_upv_1) and tick() - (InventoryController_upv_1:GetAttribute("ClosedTick") or 0) >= 0.15) then
                local UserInputType_1 = a1.UserInputType;
                local v33 = UserInputService_upv_1:GetFocusedTextBox();
                if (UserInputType_1 == Enum.UserInputType.Keyboard or UserInputType_1 == Enum.UserInputType.Gamepad1) then
                    local v34 = nil;
                    if (not (v33)) then
                        v34 = a1.KeyCode.Name;
                        local v35 = false;
                        if (v34 == SettingsModule_upv_1.GetSetting("Controls", "Move Forward")) then
                            tbl_upv_2.Forward = false;
                            v35 = true;
                        elseif (v34 == SettingsModule_upv_1.GetSetting("Controls", "Move Backward")) then
                            tbl_upv_2.Backward = false;
                            v35 = true;
                        elseif (v34 == SettingsModule_upv_1.GetSetting("Controls", "Move Right")) then
                            tbl_upv_2.Right = false;
                            v35 = true;
                        elseif (v34 == SettingsModule_upv_1.GetSetting("Controls", "Move Left")) then
                            tbl_upv_2.Left = false;
                            v35 = true;
                        elseif (v34 ~= SettingsModule_upv_1.GetSetting("Controls", "Sprint") or SettingsModule_upv_1.GetSetting("Controls", "Toggle Sprint")) then
                            if (v34 ~= SettingsModule_upv_1.GetSetting("Controls", "Crouch") or SettingsModule_upv_1.GetSetting("Controls", "Toggle Crouch")) then
                                if (v34 ~= SettingsModule_upv_1.GetSetting("Gamepad", "Sprint") or SettingsModule_upv_1.GetSetting("Gamepad", "Toggle Sprint")) then
                                    local v36 = nil;
                                    if (v34 == SettingsModule_upv_1.GetSetting("Gamepad", "Crouch")) then
                                        v36 = SettingsModule_upv_1.GetSetting("Gamepad", "Toggle Crouch");
                                        if (not (v36)) then
                                            tbl_upv_2.Crouch = false;
                                            v35 = true;
                                        else
                                            v35 = v36;
                                        end;
                                    end;
                                else
                                    tbl_upv_2.Sprint = false;
                                    v35 = true;
                                end;
                            else
                                tbl_upv_2.Crouch = false;
                                v35 = true;
                            end;
                        else
                            tbl_upv_2.Sprint = false;
                            v35 = true;
                        end;
                        if (v35) then
                            u4();
                        end;
                    end;
                end;
                return;
            end;
            return;
        end;
        local UserInputType_1 = a1.UserInputType;
        local v33 = UserInputService_upv_1:GetFocusedTextBox();
        if (UserInputType_1 == Enum.UserInputType.Keyboard or UserInputType_1 == Enum.UserInputType.Gamepad1) then
            local v34 = nil;
            if (not (v33)) then
                v34 = a1.KeyCode.Name;
                local v35 = false;
                if (v34 == SettingsModule_upv_1.GetSetting("Controls", "Move Forward")) then
                    tbl_upv_2.Forward = false;
                    v35 = true;
                elseif (v34 == SettingsModule_upv_1.GetSetting("Controls", "Move Backward")) then
                    tbl_upv_2.Backward = false;
                    v35 = true;
                elseif (v34 == SettingsModule_upv_1.GetSetting("Controls", "Move Right")) then
                    tbl_upv_2.Right = false;
                    v35 = true;
                elseif (v34 == SettingsModule_upv_1.GetSetting("Controls", "Move Left")) then
                    tbl_upv_2.Left = false;
                    v35 = true;
                elseif (v34 ~= SettingsModule_upv_1.GetSetting("Controls", "Sprint") or SettingsModule_upv_1.GetSetting("Controls", "Toggle Sprint")) then
                    if (v34 ~= SettingsModule_upv_1.GetSetting("Controls", "Crouch") or SettingsModule_upv_1.GetSetting("Controls", "Toggle Crouch")) then
                        if (v34 ~= SettingsModule_upv_1.GetSetting("Gamepad", "Sprint") or SettingsModule_upv_1.GetSetting("Gamepad", "Toggle Sprint")) then
                            local v36 = nil;
                            if (v34 == SettingsModule_upv_1.GetSetting("Gamepad", "Crouch")) then
                                v36 = SettingsModule_upv_1.GetSetting("Gamepad", "Toggle Crouch");
                                if (not (v36)) then
                                    tbl_upv_2.Crouch = false;
                                    v35 = true;
                                else
                                    v35 = v36;
                                end;
                            end;
                        else
                            tbl_upv_2.Sprint = false;
                            v35 = true;
                        end;
                    else
                        tbl_upv_2.Crouch = false;
                        v35 = true;
                    end;
                else
                    tbl_upv_2.Sprint = false;
                    v35 = true;
                end;
                if (v35) then
                    u4();
                end;
            end;
        end;
    end
);
ViewmodelController_upv_1.AttributeChanged:Connect(
    function(a1)
        --[[
          line: 280
          upvalues:
            u4 (copy, index: 1)
        ]]
        if (a1 ~= "Aiming" and a1 ~= "Using" and a1 ~= "SReduction" and a1 ~= "CanUse") then
            return;
        end;
        u4();
    end
);
Humanoid_upv_1.AttributeChanged:Connect(
    function(a1)
        --[[
          line: 286
          upvalues:
            u4 (copy, index: 1)
        ]]
        if (a1 ~= "DamageConnections") then
            return;
        end;
        u4();
    end
);
Humanoid_upv_1.StateChanged:Connect(
    function(a1, a2)
        --[[
          line: 290
          upvalues:
            u4 (copy, index: 1)
        ]]
        local v37 = script:GetAttribute("IsClimbing");
        if (a1 ~= Enum.HumanoidStateType.Climbing and a2 == Enum.HumanoidStateType.Climbing) then
            script:SetAttribute("IsClimbing", true);
            if (not (v37)) then
                u4();
            end;
            return;
        end;
        script:SetAttribute("IsClimbing", false);
        if (not v37) then
            return;
        end;
        u4();
    end
);
UserInputService_upv_1.TextBoxFocusReleased:Connect(
    function(a1)
        --[[
          line: 304
          upvalues:
            tbl_upv_2 (copy, index: 1)
            SettingsModule_upv_1 (copy, index: 2)
            u4 (copy, index: 3)
        ]]
        task.wait();
        tbl_upv_2.Forward = false;
        tbl_upv_2.Backward = false;
        tbl_upv_2.Right = false;
        tbl_upv_2.Left = false;
        if (not (SettingsModule_upv_1.GetSetting("Controls", "Toggle Sprint"))) then
            tbl_upv_2.Sprint = false;
        end;
        if (not (SettingsModule_upv_1.GetSetting("Controls", "Toggle Crouch"))) then
            tbl_upv_2.Crouch = false;
        end;
        u4();
    end
);
local function v38()
    --[[
      line: 107
      upvalues:
        PreferredInputController_upv_1 (copy, index: 1)
        GamepadControls_upv_1 (copy, index: 2)
        TeamNavigationController_upv_1 (copy, index: 3)
    ]]
    local v39 = false;
    if (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad") then
        v39 = not TeamNavigationController_upv_1:GetAttribute("MapOpen");
    end;
    GamepadControls_upv_1.Visible = v39;
end;
PreferredInputController_upv_1.AttributeChanged:Connect(v38);
TeamNavigationController_upv_1:GetAttributeChangedSignal("MapOpen"):Connect(v38);
local u5 = nil;
Humanoid_upv_1.Seated:Connect(
    function(a1, a2)
        --[[
          line: 325
          upvalues:
            u5 (ref,  index: 1)
            RunService_upv_1 (copy, index: 2)
            UserInputService_upv_1 (copy, index: 3)
            PreferredInputController_upv_1 (copy, index: 4)
        ]]
        if (u5) then
            u5:Disconnect();
            u5 = nil;
        end;
        if (not a1 or not a2) then
            return;
        end;
        if (a2:IsA("VehicleSeat")) then
            local v40 = a2.Parent and (a2.Parent:FindFirstChild("BoatController"));
            if (not v40) then
                return;
            end;
            u5 = RunService_upv_1.Heartbeat:Connect(
                function()
                    --[[
                      line: 330
                      upvalues:
                        a2 (copy, index: 1)
                        u5 (ref,  index: 2)
                        UserInputService_upv_1 (copy, index: 3)
                        PreferredInputController_upv_1 (copy, index: 4)
                    ]]
                    if (a2 and a2.Parent and a2.Occupant) then
                        local u6 = 0;
                        local u7 = 0;
                        pcall(
                            function()
                                --[[
                                  line: 338
                                  upvalues:
                                    UserInputService_upv_1 (copy, index: 1)
                                    PreferredInputController_upv_1 (copy, index: 2)
                                    u6 (ref,  index: 3)
                                    u7 (ref,  index: 4)
                                ]]
                                for _, value_2 in UserInputService_upv_1:GetGamepadState(Enum.UserInputType.Gamepad1) do
                                    local v41, v42 = nil, nil;
                                    local v43, v44 = nil, nil;
                                    if (value_2.KeyCode == Enum.KeyCode.Thumbstick1) then
                                        v43 = value_2.Position.X;
                                        v44 = value_2.Position.Y;
                                        v41 = math.abs(v43);
                                        if ((PreferredInputController_upv_1:GetAttribute("JoystickDeadzone") or 0.225) < v41) then
                                            u6 = v43;
                                        end;
                                        v42 = math.abs(v44);
                                        if ((PreferredInputController_upv_1:GetAttribute("JoystickDeadzone") or 0.225) < v42) then
                                            u7 = v44;
                                        end;
                                        return;
                                    end;
                                end;
                            end
                        );
                        a2:SetAttribute("GamepadSteer", u6);
                        a2:SetAttribute("GamepadThrottle", u7);
                    else
                        a2:SetAttribute("GamepadSteer", nil);
                        a2:SetAttribute("GamepadThrottle", nil);
                        if (not u5) then
                            return;
                        end;
                        u5:Disconnect();
                        u5 = nil;
                    end;
                end
            );
        end;
    end
);
local v45 = nil;
while (task.wait(0.03333333333333333) and (u1)) do
    local v46, v47 = nil, nil;
    if (not (u1.Parent)) then
        break;
    end;
    local tbl_4 = {Parent_1, VFX_1, Drops_1, Animals_1, Plants_1};
    local v48 = ((script:GetAttribute("IsCrouch")) and 2.6) or 1.7;
    local Position_2 = u1.Position;
    local v46, v49 = RaycastUtil_1:Raycast(Position_2, Vector3.new(0, 100, 0), "Exclude", tbl_4, false, v3, true);
    v45 = false;
    if (v46 ~= nil) then
        v45 = false;
        if (v46.Parent ~= nil) then
            v45 = v46.CanCollide or (v46.Transparency < 1);
        end;
    end;
    if (v45 ~= v2) then
        WeatherController_1:SetAttribute("BelowCeiling", v45);
        v2 = v45;
    end;
    local v50 = v45 and (v49.Y - Position_2.Y <= v48);
    if (v50 ~= u2) then
        u4();
        u2 = v50;
    end;
    if (tick() - v4 < 0.4 or not (v1) or not (v1.Parent)) then
        u4 = nil;
        continue;
    end;
    v4 = tick();
    local v51;
    v47, v51 = workspace.Terrain:ReadVoxels(Region3.new((v1.Position - (0.5 * v1.Size)) - Vector3.new(0, 3, 0), (v1.Position + (0.5 * v1.Size)) - Vector3.new(0, 3, 0)):ExpandToGrid(4), 4);
    if (v47[1][1][1] ~= Enum.Material.Water) then
        script:SetAttribute("IsWater", false);
    else
        script:SetAttribute("IsWater", true);
    end;
    u4 = nil;
end;