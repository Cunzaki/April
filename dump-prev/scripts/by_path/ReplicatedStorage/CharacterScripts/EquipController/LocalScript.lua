-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local UserInputService_upv_1 = game:GetService("UserInputService");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Players_1 = game:GetService("Players");
local _ = game:GetService("RunService");
local Values_1 = ReplicatedStorage_1:WaitForChild("Values");
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local Parent_1 = script.Parent;
local Humanoid_upv_1 = Parent_1:WaitForChild("Humanoid");
local InventoryController_upv_1 = Parent_1:WaitForChild("InventoryController");
local ViewmodelController_upv_1 = Parent_1:WaitForChild("ViewmodelController");
local BuildController_upv_1 = Parent_1:WaitForChild("BuildController");
local CameraController_upv_1 = Parent_1:WaitForChild("CameraController");
local InteractController_upv_1 = Parent_1:WaitForChild("InteractController");
local ElectricityController_1 = Parent_1:WaitForChild("ElectricityController");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
local u1 = require(Modules_1:WaitForChild("AssetContainer"))();
local tbl_upv_1 = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six};
local Main_1 = LocalPlayer_upv_1.PlayerGui:WaitForChild("Main");
local Toolbar_upv_1 = Main_1:WaitForChild("Toolbar");
local Codelock_upv_1 = Main_1:WaitForChild("Codelock");
local Fetch_upv_1 = InventoryController_upv_1:WaitForChild("Fetch");
local EquipWires_upv_1 = ElectricityController_1:WaitForChild("EquipWires");
local PreferredInputController_upv_1 = LocalPlayer_upv_1:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local tbl_upv_2 = {};
local u2 = false;
local u3 = 0;
local function u4(a1)
    --[[
      line: 92
      upvalues:
        Toolbar_upv_1 (copy, index: 1)
        InventoryController_upv_1 (copy, index: 2)
        Fetch_upv_1 (copy, index: 3)
        Items_upv_1 (copy, index: 4)
        ViewmodelController_upv_1 (copy, index: 5)
        BuildController_upv_1 (copy, index: 6)
        EquipWires_upv_1 (copy, index: 7)
    ]]
    local v1 = script:GetAttribute("Equipped");
    script:SetAttribute("Equipped", a1);
    local v2 = nil;
    if (v1 ~= a1) then
        local v3 = script:GetAttribute("Equipped");
        v2 = Toolbar_upv_1:FindFirstChild("Slot" .. v1);
        if (v2) then
            v2.BackgroundColor3 = InventoryController_upv_1:GetAttribute((((v3 ~= v1) and "Default") or "Selected") .. "SlotColor");
        end;
    end;
    local v4 = script:GetAttribute("Equipped");
    local v5 = Toolbar_upv_1:FindFirstChild("Slot" .. a1);
    if (v5) then
        v5.BackgroundColor3 = InventoryController_upv_1:GetAttribute((((v4 ~= a1) and "Default") or "Selected") .. "SlotColor");
    end;
    local v6 = Fetch_upv_1:Invoke().Toolbar[a1];
    local v7;
    if (v6) then
        v7 = false;
        if (v6 ~= 0) then
            v7 = false;
            if (v6.Amount > 0) then
                v7 = Items_upv_1[v6.ID];
            end;
        end;
    else
        v7 = v6;
    end;
    if (v7 and v7.Type ~= "Gun" and v7.Type ~= "Tool" and v7.Type ~= "Bench" or v7 and v7.MaxDurability and v6.Durability <= 0) then
        v5 = 0;
        ViewmodelController_upv_1.EquipVM:Fire(v5);
        BuildController_upv_1.EquipBench:Fire(v5);
        local v8 = false;
        if (v5 ~= 0) then
            if (v6) then
                v8 = false;
                if (typeof(v6) ~= "number") then
                    v8 = v6.ID == 326;
                end;
            else
                v8 = v6;
            end;
        end;
        EquipWires_upv_1:Fire(v8);
        return true;
    end;
    v5 = a1;
    ViewmodelController_upv_1.EquipVM:Fire(v5);
    BuildController_upv_1.EquipBench:Fire(v5);
    local v8 = false;
    if (v5 ~= 0) then
        if (v6) then
            v8 = false;
            if (typeof(v6) ~= "number") then
                v8 = v6.ID == 326;
            end;
        else
            v8 = v6;
        end;
    end;
    EquipWires_upv_1:Fire(v8);
    return true;
end;
local function u5(a1, a2, a3)
    --[[
      line: 108
      upvalues:
        Fetch_upv_1 (copy, index: 1)
        Items_upv_1 (copy, index: 2)
        InventoryController_upv_1 (copy, index: 3)
        u4 (copy, index: 4)
        u3 (ref,  index: 5)
        u1 (copy, index: 6)
        LocalPlayer_upv_1 (copy, index: 7)
    ]]
    local v9 = Fetch_upv_1:Invoke().Toolbar[a1];
    local v10;
    if (v9) then
        v10 = false;
        if (v9 ~= 0) then
            local v11 = false;
            if (v9.Amount <= 0) then
                v10 = v11;
            else
                v10 = Items_upv_1[v9.ID];
            end;
        end;
    else
        v10 = v9;
    end;
    if (a1 ~= 0 and type(v10) == "table" and v10.Type:find("Armor") and not (v10.Type:find("Consumable"))) then
        InventoryController_upv_1.EquipArmor:Fire(a1);
    end;
    local v13 = nil;
    if (v10 and v10.Type:find("Consumable")) then
        if (a3) then
            u4(a1);
            return true;
        else
            if (not a2) then
                v13 = tick();
                if (v13 - u3 >= 0.2) then
                    u3 = v13;
                    u1("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "\245A\150x@\231Er*\173\173b\191\178\001\138|\178\150\187", "Toolbar", a1);
                end;
            end;
            return;
        end;
    end;
    if (type(v9) == "table" and v9.Amount <= 0) then
        return;
    end;
    if (script:GetAttribute("Equipped") ~= a1) then
        v13 = a1;
    else
        v13 = 0;
    end;
    if (v13 ~= 0) then
        local v14 = nil;
        if (LocalPlayer_upv_1:GetAttribute("SafeZone")) then
            v14 = Fetch_upv_1:Invoke().Toolbar[v13];
            local v15;
            if (v14) then
                v15 = false;
                if (v14 ~= 0) then
                    v15 = false;
                    if (v14.Amount > 0) then
                        v15 = Items_upv_1[v14.ID];
                    end;
                end;
            else
                v15 = v14;
            end;
            if (type(v15) == "table" and v15.Type == "Gun") then
                return;
            end;
        end;
    end;
    local v16 = u4(v13);
    if (v16) then
        u1("Fire", "fD\021[\243Hg\020\166i%\2156N#\225\001\228\150\253", "\001\234\217\168\252\254\020,E\028\230\015\240\130>\029\157Q\026\244", v13);
        return v16;
    end;
end;
local function u6(a1)
    --[[
      line: 167
      upvalues:
        tbl_upv_2 (copy, index: 1)
        u2 (ref,  index: 2)
    ]]
    if (#tbl_upv_2 > 3) then
        return;
    end;
    table.insert(tbl_upv_2, a1);
    if (not (u2)) then
        u2 = true;
        local v17 = os.clock();
        while (true) do
            local v18, v19 = nil, nil;
            if (#tbl_upv_2 <= 0) then
                break;
            end;
            v18 = os.clock();
            if (v18 - v17 < 0.1) then
                task.wait();
                continue;
            end;
            while (v18 - v17 >= 0.1) do
                v18 = v18 - 0.1;
                v19 = tbl_upv_2[1];
                if (not (v19)) then
                    break;
                end;
                v19();
                table.remove(tbl_upv_2, 1);
                if (#tbl_upv_2 <= 0) then
                    u2 = false;
                    break;
                end;
            end;
            v17 = os.clock();
            task.wait();
        end;
    end;
end;
local function u7(a1)
    --[[
      line: 145
      upvalues:
        tbl_upv_1 (copy, index: 1)
        PreferredInputController_upv_1 (copy, index: 2)
        u5 (copy, index: 3)
    ]]
    local v20 = script:GetAttribute("Equipped");
    local v21 = v20 + a1;
    if (v21 >= 0) then
        if (#tbl_upv_1 < v21) then
            v21 = 0;
        end;
    else
        v21 = #tbl_upv_1;
    end;
    local v22 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
    local v23 = true;
    if (v21 ~= v20) then
        v23 = u5(v21, true, v22);
    end;
    return v23;
end;
while (Fetch_upv_1) do
    local v24;
    if (not (Fetch_upv_1.Parent)) then
        break;
    end;
    v24 = Fetch_upv_1:Invoke();
    if (type(v24) ~= "table" or type(v24.Toolbar) ~= "table") then
        task.wait();
        continue;
    end;
    UserInputService_upv_1.InputBegan:Connect(
        function(a1)
            --[[
              line: 206
              upvalues:
                SettingsModule_upv_1 (copy, index: 1)
                UserInputService_upv_1 (copy, index: 2)
                Codelock_upv_1 (copy, index: 3)
                Humanoid_upv_1 (copy, index: 4)
                CameraController_upv_1 (copy, index: 5)
                tbl_upv_1 (copy, index: 6)
                InteractController_upv_1 (copy, index: 7)
                u6 (copy, index: 8)
                u5 (copy, index: 9)
                u7 (copy, index: 10)
                Fetch_upv_1 (copy, index: 11)
                Items_upv_1 (copy, index: 12)
                u3 (ref,  index: 13)
                u1 (copy, index: 14)
            ]]
            if (SettingsModule_upv_1.MainMenuOpen()) then
                return;
            else
                local UserInputType_1 = a1.UserInputType;
                if (UserInputService_upv_1:GetFocusedTextBox() or Codelock_upv_1.Visible) then
                    return;
                else
                    local v25 = nil;
                    if (Humanoid_upv_1:GetAttribute("Downed")) then
                        return;
                    else
                        v25 = Humanoid_upv_1;
                        local v26 = nil;
                        if (v25) then
                            v26 = Humanoid_upv_1.Parent;
                            if (v26) then
                                local v27 = false;
                                if (Humanoid_upv_1.Health <= 0) then
                                    v25 = v27;
                                else
                                    v25 = not CameraController_upv_1:GetAttribute("ViewmodelCFrame");
                                end;
                            else
                                v25 = v26;
                            end;
                        end;
                        if (not v25) then
                            return;
                        end;
                        if (UserInputType_1 ~= Enum.UserInputType.Keyboard) then
                            local v28 = nil;
                            if (UserInputType_1 == Enum.UserInputType.Gamepad1) then
                                v28 = a1.KeyCode;
                                local v29 = nil;
                                if (v28.Name == "ButtonR2") then
                                    local v30 = script:GetAttribute("Equipped");
                                    v29 = Fetch_upv_1:Invoke().Toolbar[v30];
                                    local v31;
                                    if (v29) then
                                        v31 = false;
                                        if (v29 ~= 0) then
                                            v31 = false;
                                            if (v29.Amount > 0) then
                                                v31 = Items_upv_1[v29.ID];
                                            end;
                                        end;
                                    else
                                        v31 = v29;
                                    end;
                                    if (v31) then
                                        local v32 = nil;
                                        if (v31.Type:find("Consumable")) then
                                            v32 = tick();
                                            if (v32 - u3 >= 0.2) then
                                                u3 = v32;
                                                u1("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "\245A\150x@\231Er*\173\173b\191\178\001\138|\178\150\187", "Toolbar", v30);
                                            end;
                                        end;
                                    end;
                                elseif (v28.Name == SettingsModule_upv_1.GetSetting("Gamepad", "Toolbar Left")) then
                                    u7(-1);
                                elseif (v28.Name == SettingsModule_upv_1.GetSetting("Gamepad", "Toolbar Right")) then
                                    u7(1);
                                end;
                            end;
                            return;
                        end;
                        v25 = a1.KeyCode;
                        for key_upv_1, value_1 in pairs(tbl_upv_1) do
                            if (value_1 == v25) then
                                if (key_upv_1 > 2 or not InteractController_upv_1:GetAttribute("Dialog")) then
                                    u6(
                                        function()
                                            --[[
                                              line: 216
                                              upvalues:
                                                CameraController_upv_1 (copy, index: 1)
                                                u5 (copy, index: 2)
                                                key_upv_1 (copy, index: 3)
                                            ]]
                                            if (CameraController_upv_1:GetAttribute("ViewmodelCFrame")) then
                                                return;
                                            end;
                                            u5(key_upv_1);
                                        end
                                    );
                                end;
                                return;
                            end;
                        end;
                    end;
                end;
            end;
            -- GenericForNext key_upv_1, value_1 = v33(v34, [control]);
            while (true) do
                if (value_1 ~= v25) then
                    continue;
                elseif (key_upv_1 > 2 or not InteractController_upv_1:GetAttribute("Dialog")) then
                    u6(
                        function()
                            --[[
                              line: 216
                              upvalues:
                                CameraController_upv_1 (copy, index: 1)
                                u5 (copy, index: 2)
                                key_upv_1 (copy, index: 3)
                            ]]
                            if (CameraController_upv_1:GetAttribute("ViewmodelCFrame")) then
                                return;
                            end;
                            u5(key_upv_1);
                        end
                    );
                end;
            end;
        end
    );
    UserInputService_upv_1.InputChanged:Connect(
        function(a1, a2)
            --[[
              line: 247
              upvalues:
                SettingsModule_upv_1 (copy, index: 1)
                UserInputService_upv_1 (copy, index: 2)
                Codelock_upv_1 (copy, index: 3)
                Humanoid_upv_1 (copy, index: 4)
                LocalPlayer_upv_1 (copy, index: 5)
                CameraController_upv_1 (copy, index: 6)
                u6 (copy, index: 7)
                u7 (copy, index: 8)
            ]]
            if (not SettingsModule_upv_1.MainMenuOpen()) then
                local v35 = UserInputService_upv_1:GetFocusedTextBox();
                if (a1.UserInputType == Enum.UserInputType.MouseWheel and not (v35) and not (a2) and not (Codelock_upv_1.Visible) and not (Humanoid_upv_1:GetAttribute("Downed"))) then
                    local Z_upv_1;
                    if (not (LocalPlayer_upv_1:GetAttribute("SafeZone"))) then
                        Z_upv_1 = Humanoid_upv_1;
                        local v36 = nil;
                        if (Z_upv_1) then
                            v36 = Humanoid_upv_1.Parent;
                            if (v36) then
                                local v37 = false;
                                if (Humanoid_upv_1.Health <= 0) then
                                    Z_upv_1 = v37;
                                else
                                    Z_upv_1 = not CameraController_upv_1:GetAttribute("ViewmodelCFrame");
                                end;
                            else
                                Z_upv_1 = v36;
                            end;
                        end;
                        if (Z_upv_1) then
                            Z_upv_1 = a1.Position.Z;
                            if (Z_upv_1 >= 0.5 and SettingsModule_upv_1.GetSetting("Controls", "Toolbar Right") ~= "M.WheelDown" or Z_upv_1 <= -0.5 and SettingsModule_upv_1.GetSetting("Controls", "Toolbar Left") ~= "M.WheelUp") then
                                return;
                            end;
                            if (math.abs(Z_upv_1) >= 0.5) then
                                u6(
                                    function()
                                        --[[
                                          line: 256
                                          upvalues:
                                            u7 (copy, index: 1)
                                            Z_upv_1 (copy, index: 2)
                                        ]]
                                        u7(((Z_upv_1 <= 0) and 1) or -1);
                                    end
                                );
                            end;
                            return;
                        end;
                    end;
                end;
            end;
        end
    );
    u1("Setup", "fD\021[\243Hg\020\166i%\2156N#\225\001\228\150\253", "\001\234\217\168\252\254\020,E\028\230\015\240\130>\029\157Q\026\244", u4);
    if (Values_1.ServerType.Value == "GunGame") then
        u5(1);
    end;
    return;
end;