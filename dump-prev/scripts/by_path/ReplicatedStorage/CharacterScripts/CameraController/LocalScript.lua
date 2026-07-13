-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local UserInputService_upv_1 = game:GetService("UserInputService");
local RunService_upv_1 = game:GetService("RunService");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Values_1 = ReplicatedStorage_1:WaitForChild("Values");
local _ = require(Modules_1:WaitForChild("NumberUtil"));
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local NumberUtil_1 = require(Modules_1:WaitForChild("NumberUtil"));
local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
local PlayerGui_1 = Players_1.LocalPlayer:WaitForChild("PlayerGui");
local Parent_upv_1 = script.Parent;
local Humanoid_upv_1 = Parent_upv_1:WaitForChild("Humanoid");
local CurrentCamera_upv_1 = workspace.CurrentCamera;
local ViewmodelController_upv_1 = Parent_upv_1:WaitForChild("ViewmodelController");
local InventoryController_upv_1 = Parent_upv_1:WaitForChild("InventoryController");
local Main_upv_1 = PlayerGui_1:WaitForChild("Main");
local CustomChat_upv_1 = PlayerGui_1:WaitForChild("CustomChat");
local Loading_1 = PlayerGui_1:WaitForChild("Loading");
local u1 = Main_upv_1:WaitForChild("ServerName ");
local u2 = Vector2.new();
local u3 = Vector2.new();
local v24 = Vector3.new();
local u4 = false;
local u5 = 0;
local function u6()
    --[[
      line: 69
      upvalues:
        Parent_upv_1 (copy, index: 1)
        Humanoid_upv_1 (copy, index: 2)
        InventoryController_upv_1 (copy, index: 3)
        ViewmodelController_upv_1 (copy, index: 4)
        Items_upv_1 (copy, index: 5)
        CurrentCamera_upv_1 (copy, index: 6)
        u4 (ref,  index: 7)
        RunService_upv_1 (copy, index: 8)
        u3 (ref,  index: 9)
        u2 (ref,  index: 10)
        u5 (ref,  index: 11)
    ]]
    if ((script:GetAttribute("FreeLooking")) or not Parent_upv_1 or not Humanoid_upv_1) then
        return;
    end;
    if (Humanoid_upv_1.Health > 0) then
        local v1, u7, _ = nil, nil, nil;
        if (not (Humanoid_upv_1:GetAttribute("Downed"))) then
            v1 = InventoryController_upv_1.Fetch:Invoke();
            local v2;
            if (v1) then
                u7 = v1.Toolbar;
                local v3 = nil;
                if (u7) then
                    v3 = u7[ViewmodelController_upv_1:GetAttribute("Equipped")];
                    local v4 = false;
                    if (v3 == nil) then
                        v2 = v4;
                    else
                        local v5 = false;
                        if (v3 == 0) then
                            v2 = v5;
                        else
                            v2 = v3;
                        end;
                    end;
                else
                    v2 = nil;
                end;
            else
                v2 = nil;
            end;
            local v6 = v2 and (Items_upv_1[v2.ID]);
            u7 = ViewmodelController_upv_1:GetAttribute("Using");
            if (u7 and v6 and v6.Type == "Gun") then
                return;
            end;
            u7 = Parent_upv_1.PrimaryPart;
            if (u7) then
                local CFrame_1 = CurrentCamera_upv_1.CFrame;
                script:SetAttribute("FreeLooking", true);
                script:SetAttribute("ActualCFrame", CFrame_1);
                local v7 = nil;
                if (not u4) then
                    u4 = true;
                    Humanoid_upv_1.AutoRotate = false;
                    CurrentCamera_upv_1.CameraType = Enum.CameraType.Scriptable;
                    local u8 = CFrame_1.Position - u7.Position;
                    v7 = Humanoid_upv_1.SeatPart;
                    local v8;
                    if (v7 and v7.Parent) then
                        if (v7.Name ~= "VehicleSeat") then
                            v8 = 1;
                        else
                            v8 = 2;
                        end;
                    else
                        v8 = 1;
                    end;
                    RunService_upv_1:BindToRenderStep(
                        "FreeLook",
                        Enum.RenderPriority.Camera.Value + v8,
                        function(a1)
                            --[[
                              line: 87
                              upvalues:
                                u7 (copy, index: 1)
                                u3 (ref,  index: 2)
                                u2 (ref,  index: 3)
                                u5 (ref,  index: 4)
                                u8 (copy, index: 5)
                                CurrentCamera_upv_1 (copy, index: 6)
                                u4 (ref,  index: 7)
                                RunService_upv_1 (copy, index: 8)
                                Humanoid_upv_1 (copy, index: 9)
                            ]]
                            local v9 = script:GetAttribute("ActualCFrame");
                            local v10 = script:GetAttribute("FreeLooking");
                            local v11 = false;
                            if (u7 and u7.Parent) then
                                local v12 = v10 and u2 or u3:Lerp(Vector2.new(), math.clamp(u5, 0, 1));
                                u3 = v12;
                                if (v10) then
                                    u5 = 0;
                                else
                                    u2 = Vector2.new();
                                    u5 = u5 + (a1 * 10);
                                end;
                                local v13, v14, v15 = v9:ToEulerAnglesXYZ();
                                local v16 = CFrame.Angles(v13, v14, v15);
                                local v17 = CFrame.new(u7.Position + u8) * v16;
                                script:SetAttribute("ViewmodelCFrame", v17);
                                CurrentCamera_upv_1.CFrame = v17 * (CFrame.Angles(0, -math.rad(v12.X), 0) * CFrame.Angles(-math.rad(v12.Y), 0, 0));
                                v11 = v10 or u5 < 1;
                            end;
                            if (v11) then
                                return;
                            end;
                            u4 = false;
                            CurrentCamera_upv_1.CameraType = Enum.CameraType.Custom;
                            script:SetAttribute("ViewmodelCFrame", nil);
                            RunService_upv_1:UnbindFromRenderStep("FreeLook");
                            if (Humanoid_upv_1 and Humanoid_upv_1.Parent) then
                                Humanoid_upv_1.AutoRotate = true;
                            end;
                        end
                    );
                end;
            end;
        end;
    end;
end;
UserInputService_upv_1.InputBegan:Connect(
    function(a1, a2)
        --[[
          line: 118
          upvalues:
            SettingsModule_upv_1 (copy, index: 1)
            UserInputService_upv_1 (copy, index: 2)
            u6 (copy, index: 3)
            Main_upv_1 (copy, index: 4)
            u1 (copy, index: 5)
            CustomChat_upv_1 (copy, index: 6)
        ]]
        if (SettingsModule_upv_1.MainMenuOpen()) then
            return;
        end;
        if (not (UserInputService_upv_1:GetFocusedTextBox()) and not (a2)) then
            local v19 = nil;
            if (a1.UserInputType == Enum.UserInputType.Keyboard) then
                v19 = a1.KeyCode.Name;
                if (v19 == SettingsModule_upv_1.GetSetting("Controls", "Free Look")) then
                    u6();
                    return;
                elseif (v19 == SettingsModule_upv_1.GetSetting("Controls", "Hide UI")) then
                    local v20 = not script:GetAttribute("UI");
                    script:SetAttribute("UI", v20);
                    Main_upv_1.Toolbar.Visible = v20;
                    Main_upv_1.Stats.Visible = v20;
                    Main_upv_1.Compass.Visible = v20;
                    Main_upv_1.Invalids.Visible = v20;
                    Main_upv_1.ClientInfo.Visible = v20;
                    Main_upv_1.Team.Visible = v20;
                    u1.Visible = v20;
                    local CombatServer_1 = Main_upv_1.CombatServer;
                    CombatServer_1.Position = UDim2.new(0, 0, (v20 and 0) or -1, 0);
                    local BuildServer_1 = Main_upv_1.BuildServer;
                    BuildServer_1.Position = UDim2.new(0, 0, (v20 and 0) or -1, 0);
                    CustomChat_upv_1.Enabled = v20;
                end;
            end;
            return;
        end;
    end
);
UserInputService_upv_1.InputChanged:Connect(
    function(a1)
        --[[
          line: 144
          upvalues:
            u2 (ref, index: 1)
        ]]
        if (not script:GetAttribute("FreeLooking")) then
            return;
        end;
        if (a1.UserInputType == Enum.UserInputType.MouseMovement) then
            local v21 = a1.Delta / 2;
            u2 = Vector2.new(math.clamp(u2.X + v21.X, -140, 140), math.clamp(u2.Y + v21.Y, -50, 50));
        end;
    end
);
UserInputService_upv_1.InputEnded:Connect(
    function(a1, a2)
        --[[
          line: 153
          upvalues:
            UserInputService_upv_1 (copy, index: 1)
            SettingsModule_upv_1 (copy, index: 2)
        ]]
        if ((UserInputService_upv_1:GetFocusedTextBox()) or (a2)) then
            return;
        end;
        if (a1.UserInputType == Enum.UserInputType.Keyboard and a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Controls", "Free Look")) then
            script:SetAttribute("FreeLooking", false);
        end;
    end
);
local function v22()
    --[[
      line: 113
    ]]
    script:SetAttribute("FreeLooking", false);
end;
Humanoid_upv_1.Died:Connect(v22);
Humanoid_upv_1:GetAttributeChangedSignal("Downed"):Connect(
    function()
        --[[
          line: 166
          upvalues:
            Humanoid_upv_1 (copy, index: 1)
        ]]
        if (not Humanoid_upv_1:GetAttribute("Downed")) then
            return;
        end;
        script:SetAttribute("FreeLooking", false);
    end
);
u4 = false;
CurrentCamera_upv_1.CameraType = Enum.CameraType.Custom;
script:SetAttribute("ViewmodelCFrame", nil);
RunService_upv_1:UnbindFromRenderStep("FreeLook");
if (Humanoid_upv_1 and Humanoid_upv_1.Parent) then
    Humanoid_upv_1.AutoRotate = true;
end;
u1.Text = Values_1.ServerName.Value;
Loading_1.Enabled = true;
while (true) do
    local PreSpawns_1 = workspace:FindFirstChild("PreSpawns");
    if (not (PreSpawns_1)) then
        task.wait();
        continue;
    end;
    local v23;
    if (not (Parent_upv_1.Parent)) then
        break;
    end;
    v23 = Parent_upv_1.PrimaryPart;
    if (not (v23)) then
        task.wait();
        continue;
    end;
    if (not (NumberUtil_1:IsWithin(PreSpawns_1:GetPivot().Position, v23.Position, 50))) then
        break;
    end;
    task.wait();
end;
if (not Loading_1.Parent) then
    return;
end;
Loading_1.Enabled = false;