-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_upv_1 = game:GetService("ReplicatedStorage");
local UserInputService_upv_1 = game:GetService("UserInputService");
local Values_1 = ReplicatedStorage_upv_1:WaitForChild("Values");
local Modules_1 = ReplicatedStorage_upv_1:WaitForChild("Modules");
local ButtonClass_upv_1 = require(Modules_1:WaitForChild("ButtonClass"));
local TableUtil_upv_1 = require(Modules_1:WaitForChild("TableUtil"));
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local PlayerGui_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui");
local _ = script.Parent:WaitForChild("Humanoid");
local Main_1 = PlayerGui_1:WaitForChild("Main");
local CombatServer_upv_1 = Main_1:WaitForChild("CombatServer");
local u1 = nil;
local Private_upv_1 = nil;
local Password_upv_1 = nil;
local Settings_upv_1 = nil;
local MainFrame_upv_1 = nil;
local PlayerList_upv_1 = nil;
local BuildServer_1 = Main_1:WaitForChild("BuildServer");
local Value_1 = Values_1:WaitForChild("ServerType").Value;
local u2 = os.clock();
local u3 = false;
local u4 = false;
local tbl_upv_1 = {};
local u5 = {};
local u6 = {};
local tbl_upv_2 = {"Weapon", "Armor"};
local tbl_upv_3 = {"Red", "Blue"};
local u7 = "";
local tbl_upv_4 = {};
local function u8(a1)
    --[[
      line: 67
      upvalues:
        tbl_upv_2 (copy, index: 1)
        MainFrame_upv_1 (ref,  index: 2)
        tbl_upv_1 (copy, index: 3)
        u5 (ref,  index: 4)
        u6 (ref,  index: 5)
        Settings_upv_1 (ref,  index: 6)
        TableUtil_upv_1 (copy, index: 7)
    ]]
    local v1 = nil;
    local v2 = nil;
    local v3 = nil;
    local v4 = nil;
    local v5 = nil;
    for key_1, value_1 in pairs(tbl_upv_2) do
        v1 = MainFrame_upv_1[("%*Kits"):format(value_1)];
        v5 = v1:FindFirstChild(("Kit%*"):format(a1[key_1]));
        if (v5) then
            v2 = tbl_upv_1[v5];
            if (v2 and not (v2:IsToggled())) then
                task.defer(v2.ToggleButton, v2, true);
            end;
        end;
        v2 = u5[key_1];
        if (not (v2) or a1[key_1] == v2) then
            continue;
        end;
        v3 = v1:FindFirstChild(("Kit%*"):format(v2));
        if (not (v3)) then
            continue;
        end;
        v4 = tbl_upv_1[v3];
        if (not (v4)) then
            continue;
        end;
        if (v4:IsToggled()) then
            task.defer(v4.ToggleButton, v4, false);
        end;
    end;
    local v6 = a1[3];
    MainFrame_upv_1.WallInput.Text = tostring(v6);
    local v7 = a1[4];
    if (not (v7) and u5[4]) then
        MainFrame_upv_1.PasswordInput.Text = "";
    end;
    if (u6[4] ~= false) then
        MainFrame_upv_1.PasswordExtra.Visible = false;
        MainFrame_upv_1.PasswordInput.Visible = not v7;
    else
        MainFrame_upv_1.PasswordExtra.Visible = true;
        MainFrame_upv_1.PasswordInput.Visible = false;
    end;
    local Public_1 = MainFrame_upv_1.Public;
    Public_1.Text = ("Arena Status: <font color=\"%*</font>"):format((v7 and "rgb(0, 255, 0)\">PUBLIC") or "rgb(255, 0, 0)\">PRIVATE");
    local AutoStart_1 = MainFrame_upv_1.AutoStart;
    AutoStart_1.Text = ("Auto Start: <font color=\"%*</font>"):format(((a1[5]) and "rgb(0, 255, 0)\">ON") or "rgb(255, 0, 0)\">OFF");
    local HealthRegen_1 = MainFrame_upv_1.HealthRegen;
    HealthRegen_1.Text = ("Health Regen on Kill: <font color=\"%*</font>"):format(((a1[6]) and "rgb(0, 255, 0)\">ON") or "rgb(255, 0, 0)\">OFF");
    if (type(v6) ~= "number" or v6 < 0) then
        Settings_upv_1.Apply.Visible = false;
    else
        if (v6 > 10 or not (v7) and u6[4] ~= v7 and MainFrame_upv_1.PasswordInput.Text == "") then
            Settings_upv_1.Apply.Visible = false;
            local v8 = a1[7];
            local AmmoType_1 = MainFrame_upv_1.AmmoType;
            AmmoType_1.Text = ("Bullet Ammo Type: <font color=\"rgb(255, 255, 0)\">%*</font>"):format(((v8 == 1) and "DEFAULT") or (((v8 == 2) and "SWIFT") or (((v8 ~= 3) and "COMBUSTIVE") or "PIERCING")));
            local v9 = a1[8];
            local WallType_1 = MainFrame_upv_1.WallType;
            WallType_1.Text = ("Cover Type: <font color=\"rgb(255, 123, 0)\">%*</font>"):format(((v9 == 1) and "WOODEN WALLS") or (((v9 ~= 2) and "BARRICADES") or "STONE WALLS"));
            u5 = a1;
            return;
        end;
        Settings_upv_1.Apply.Visible = not TableUtil_upv_1:CompareTables(u6, a1);
    end;
    local v8 = a1[7];
    local AmmoType_1 = MainFrame_upv_1.AmmoType;
    AmmoType_1.Text = ("Bullet Ammo Type: <font color=\"rgb(255, 255, 0)\">%*</font>"):format(((v8 == 1) and "DEFAULT") or (((v8 == 2) and "SWIFT") or (((v8 ~= 3) and "COMBUSTIVE") or "PIERCING")));
    local v9 = a1[8];
    local WallType_1 = MainFrame_upv_1.WallType;
    WallType_1.Text = ("Cover Type: <font color=\"rgb(255, 123, 0)\">%*</font>"):format(((v9 == 1) and "WOODEN WALLS") or (((v9 ~= 2) and "BARRICADES") or "STONE WALLS"));
    u5 = a1;
end;
local function u9(a1)
    --[[
      line: 118
      upvalues:
        u5 (ref,  index: 1)
        MainFrame_upv_1 (ref,  index: 2)
        u6 (ref,  index: 3)
        Settings_upv_1 (ref,  index: 4)
        TableUtil_upv_1 (copy, index: 5)
    ]]
    local v10 = a1[1];
    if (not (v10) and u5[1]) then
        MainFrame_upv_1.PasswordInput.Text = "";
    end;
    if (u6[1] ~= false) then
        MainFrame_upv_1.PasswordExtra.Visible = false;
        MainFrame_upv_1.PasswordInput.Visible = not v10;
    else
        MainFrame_upv_1.PasswordExtra.Visible = true;
        MainFrame_upv_1.PasswordInput.Visible = false;
    end;
    local Public_2 = MainFrame_upv_1.Public;
    Public_2.Text = ("Arena Status: <font color=\"%*</font>"):format((v10 and "rgb(0, 255, 0)\">PUBLIC") or "rgb(255, 0, 0)\">PRIVATE");
    if (not v10 and u6[1] ~= v10 and MainFrame_upv_1.PasswordInput.Text == "") then
        Settings_upv_1.Apply.Visible = false;
    else
        Settings_upv_1.Apply.Visible = not TableUtil_upv_1:CompareTables(u6, a1);
    end;
    local CostBaseParts_1 = MainFrame_upv_1.CostBaseParts;
    CostBaseParts_1.Text = ("/cost Calculate Base Parts: <font color=\"%*</font>"):format(((a1[2]) and "rgb(0, 255, 0)\">ON") or "rgb(255, 0, 0)\">OFF");
    local CostDeployables_1 = MainFrame_upv_1.CostDeployables;
    CostDeployables_1.Text = ("/cost Calculate Deployables: <font color=\"%*</font>"):format(((a1[3]) and "rgb(0, 255, 0)\">ON") or "rgb(255, 0, 0)\">OFF");
    u5 = a1;
end;
local function u10(...)
    --[[
      line: 143
      upvalues:
        tbl_upv_4 (ref,  index: 1)
        PlayerList_upv_1 (ref,  index: 2)
        tbl_upv_3 (copy, index: 3)
        ButtonClass_upv_1 (copy, index: 4)
        u2 (ref,  index: 5)
        ReplicatedStorage_upv_1 (copy, index: 6)
    ]]
    local tbl_5 = {...};
    for _, value_2 in pairs(tbl_upv_4) do
        value_2:Destroy();
    end;
    tbl_upv_4 = {};
    for _, value_3 in pairs(PlayerList_upv_1:GetChildren()) do
        if (value_3.Name == "Red") then
            continue;
        end;
        if (value_3.Name ~= "Blue") then
            value_3:Destroy();
        end;
    end;
    local v11 = nil;
    local v12 = nil;
    local v13 = nil;
    local v14 = nil;
    local _ = nil;
    for key_2, value_4 in pairs(tbl_upv_3) do
        v11 = 0;
        v12 = nil;
        v13 = nil;
        for v15, value_upv_5 in pairs(tbl_5[key_2]) do
            if (not (value_upv_5) or not (value_upv_5.Parent)) then
                continue;
            end;
            v11 = v11 + 1;
            v12 = PlayerList_upv_1[value_4]:Clone();
            v12.Name = ("%*%*"):format(value_4, v11);
            v12.Label.Text = value_upv_5.Name;
            v13 = v12.Label;
            v14 = (value_upv_5:GetAttribute("CombatReady") and (Color3.fromRGB(0, 255, 0))) or (Color3.new(1, 1, 1));
            v13.TextColor3 = v14;
            v12.Position = UDim2.new(((key_2 ~= 1) and 0.5) or 0, 0, (v11 - 1) * 0.1, 0);
            v12.Parent = PlayerList_upv_1;
            v12.Visible = true;
            table.insert(
                tbl_upv_4,
                ButtonClass_upv_1.new(
                    v12.Kick,
                    "BackgroundColor3",
                    function()
                        --[[
                          line: 166
                          upvalues:
                            u2 (ref,  index: 1)
                            ReplicatedStorage_upv_1 (copy, index: 2)
                            value_upv_5 (copy, index: 3)
                        ]]
                        local v15 = os.clock();
                        if (v15 - u2 < 2) then
                            return;
                        end;
                        u2 = v15;
                        ReplicatedStorage_upv_1.CombatServerRemote:FireServer("PlayerList", value_upv_5, "Kick");
                    end,
                    1.3,
                    1.5
                )
            );
            v13 = v12:FindFirstChild("Swap");
            if (v13) then
                table.insert(
                    tbl_upv_4,
                    ButtonClass_upv_1.new(
                        v12.Swap,
                        "BackgroundColor3",
                        function()
                            --[[
                              line: 173
                              upvalues:
                                u2 (ref,  index: 1)
                                ReplicatedStorage_upv_1 (copy, index: 2)
                                value_upv_5 (copy, index: 3)
                            ]]
                            local v16 = os.clock();
                            if (v16 - u2 < 2) then
                                return;
                            end;
                            u2 = v16;
                            ReplicatedStorage_upv_1.CombatServerRemote:FireServer("PlayerList", value_upv_5, "Swap");
                        end,
                        1.3,
                        1.5
                    )
                );
            end;
        end;
    end;
end;
local function v17()
    --[[
      line: 202
      upvalues:
        LocalPlayer_upv_1 (copy, index: 1)
        u1 (ref,  index: 2)
    ]]
    u1.IsOwner.Visible = LocalPlayer_upv_1:GetAttribute("IsArenaOwner") == true;
end;
local function v19()
    --[[
      line: 207
      upvalues:
        u1 (ref,  index: 1)
        LocalPlayer_upv_1 (copy, index: 2)
    ]]
    u1.ArenaName.Text = LocalPlayer_upv_1:GetAttribute("ArenaName") or "";
end;
local function v20()
    --[[
      line: 196
      upvalues:
        LocalPlayer_upv_1 (copy, index: 1)
        CombatServer_upv_1 (copy, index: 2)
    ]]
    local v21 = LocalPlayer_upv_1:GetAttribute("CombatReady");
    CombatServer_upv_1.Ready.Text = (v21 and "Ready: YES") or (((v21 ~= false) and "") or "Ready: NO");
    local Ready_1 = CombatServer_upv_1.Ready;
    Ready_1.TextColor3 = v21 and Color3.fromRGB(0, 255, 64) or Color3.fromRGB(255, 82, 82);
end;
if (Value_1 == "Combat") then
    u1 = CombatServer_upv_1;
    Private_upv_1 = u1:WaitForChild("Private");
    Password_upv_1 = Private_upv_1:WaitForChild("Password");
    Settings_upv_1 = u1:WaitForChild("Settings");
    MainFrame_upv_1 = Settings_upv_1:WaitForChild("MainFrame");
    PlayerList_upv_1 = MainFrame_upv_1:WaitForChild("PlayerList");
    local WallInput_upv_1 = MainFrame_upv_1:WaitForChild("WallInput");
    local CombatServerRemote_upv_1 = ReplicatedStorage_upv_1:WaitForChild("CombatServerRemote");
    Password_upv_1.FocusLost:Connect(
        function()
            --[[
              line: 222
              upvalues:
                Private_upv_1 (ref,  index: 1)
                UserInputService_upv_1 (copy, index: 2)
            ]]
            shared.LastTextBoxFocused = tick();
            if (not Private_upv_1.Visible) then
                return;
            end;
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
            UserInputService_upv_1.MouseIconEnabled = true;
        end
    );
    Password_upv_1:GetPropertyChangedSignal("Text"):Connect(
        function()
            --[[
              line: 228
              upvalues:
                Password_upv_1 (ref, index: 1)
                Private_upv_1 (ref, index: 2)
            ]]
            local v23 = Password_upv_1.Text:sub(1, 20);
            Password_upv_1.Text = v23;
            local Enter_1 = Private_upv_1.Enter;
            Enter_1.Visible = v23:len() > 0;
        end
    );
    ButtonClass_upv_1.new(
        Private_upv_1.Enter,
        "BackgroundColor3",
        function()
            --[[
              line: 234
              upvalues:
                Password_upv_1 (ref,  index: 1)
                u2 (ref,  index: 2)
                Private_upv_1 (ref,  index: 3)
                CombatServerRemote_upv_1 (copy, index: 4)
            ]]
            local Text_1 = Password_upv_1.Text;
            local v25 = os.clock();
            if (Text_1:len() <= 0 or Text_1:len() > 20 or v25 - u2 < 2) then
                return;
            end;
            u2 = v25;
            Private_upv_1.Detail.Text = "...";
            CombatServerRemote_upv_1:FireServer("EnterPass", Text_1);
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        Private_upv_1.Cancel,
        "BackgroundColor3",
        function()
            --[[
              line: 242
              upvalues:
                CombatServerRemote_upv_1 (copy, index: 1)
                UserInputService_upv_1 (copy, index: 2)
                Private_upv_1 (ref,  index: 3)
                Password_upv_1 (ref,  index: 4)
            ]]
            CombatServerRemote_upv_1:FireServer("CancelPass");
            task.wait();
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService_upv_1.MouseIconEnabled = false;
            Private_upv_1.Visible = false;
            if (not Password_upv_1:IsFocused()) then
                return;
            end;
            Password_upv_1:ReleaseFocus();
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        Settings_upv_1.Close,
        "BackgroundColor3",
        function()
            --[[
              line: 248
              upvalues:
                u4 (ref,  index: 1)
                Settings_upv_1 (ref,  index: 2)
                UserInputService_upv_1 (copy, index: 3)
            ]]
            u4 = false;
            Settings_upv_1.Visible = false;
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService_upv_1.MouseIconEnabled = false;
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        Settings_upv_1.Apply,
        "BackgroundColor3",
        function()
            --[[
              line: 252
              upvalues:
                u5 (ref,  index: 1)
                u2 (ref,  index: 2)
                CombatServerRemote_upv_1 (copy, index: 3)
                MainFrame_upv_1 (ref,  index: 4)
            ]]
            local v26;
            if (#u5 == 0) then
                return;
            end;
            v26 = os.clock();
            if (v26 - u2 < 2) then
                return;
            end;
            u2 = v26;
            CombatServerRemote_upv_1:FireServer("UpdateSettings", u5, MainFrame_upv_1.PasswordInput.Text);
        end,
        1.3,
        1.5
    );
    MainFrame_upv_1:WaitForChild("PasswordInput"):GetPropertyChangedSignal("Text"):Connect(
        function()
            --[[
              line: 260
              upvalues:
                MainFrame_upv_1 (ref, index: 1)
            ]]
            MainFrame_upv_1.PasswordInput.Text = MainFrame_upv_1.PasswordInput.Text:sub(1, 20);
        end
    );
    MainFrame_upv_1.PasswordInput.FocusLost:Connect(
        function()
            --[[
              line: 264
              upvalues:
                u4 (ref,  index: 1)
                UserInputService_upv_1 (copy, index: 2)
                u8 (copy, index: 3)
                u5 (ref,  index: 4)
            ]]
            shared.LastTextBoxFocused = tick();
            if (not u4) then
                return;
            end;
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
            UserInputService_upv_1.MouseIconEnabled = true;
            u8(u5);
        end
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.Public,
        "BackgroundColor3",
        function()
            --[[
              line: 272
              upvalues:
                u5 (ref,  index: 1)
                u8 (copy, index: 2)
            ]]
            local v27 = table.clone(u5);
            v27[4] = not v27[4];
            u8(v27);
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.ClearWalls,
        "BackgroundColor3",
        function()
            --[[
              line: 280
              upvalues:
                u2 (ref,  index: 1)
                CombatServerRemote_upv_1 (copy, index: 2)
            ]]
            local v28 = os.clock();
            if (v28 - u2 < 2) then
                return;
            end;
            u2 = v28;
            CombatServerRemote_upv_1:FireServer("ClearWalls");
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.ForceStart,
        "BackgroundColor3",
        function()
            --[[
              line: 287
              upvalues:
                CombatServerRemote_upv_1 (copy, index: 1)
            ]]
            CombatServerRemote_upv_1:FireServer("ForceStart");
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.ShuffleTeams,
        "BackgroundColor3",
        function()
            --[[
              line: 291
              upvalues:
                u2 (ref,  index: 1)
                CombatServerRemote_upv_1 (copy, index: 2)
            ]]
            local v29 = os.clock();
            if (v29 - u2 < 2) then
                return;
            end;
            u2 = v29;
            CombatServerRemote_upv_1:FireServer("ShuffleTeams");
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.AutoStart,
        "BackgroundColor3",
        function()
            --[[
              line: 298
              upvalues:
                u5 (ref,  index: 1)
                u8 (copy, index: 2)
            ]]
            local v30 = table.clone(u5);
            v30[5] = not v30[5];
            u8(v30);
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.HealthRegen,
        "BackgroundColor3",
        function()
            --[[
              line: 303
              upvalues:
                u5 (ref,  index: 1)
                u8 (copy, index: 2)
            ]]
            local v31 = table.clone(u5);
            v31[6] = not v31[6];
            u8(v31);
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.AmmoType,
        "BackgroundColor3",
        function()
            --[[
              line: 309
              upvalues:
                u5 (ref,  index: 1)
                u8 (copy, index: 2)
            ]]
            local v32 = table.clone(u5);
            local v33 = v32[7];
            v32[7] = ((v33 < 4) and (v33 + 1)) or 1;
            u8(v32);
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.WallType,
        "BackgroundColor3",
        function()
            --[[
              line: 315
              upvalues:
                u5 (ref,  index: 1)
                u8 (copy, index: 2)
            ]]
            local v34 = table.clone(u5);
            local v35 = v34[8];
            v34[8] = ((v35 < 3) and (v35 + 1)) or 1;
            u8(v34);
        end,
        1.3,
        1.5
    );
    WallInput_upv_1:GetPropertyChangedSignal("Text"):Connect(
        function()
            --[[
              line: 322
              upvalues:
                WallInput_upv_1 (ref, index: 1)
                u7 (ref, index: 2)
            ]]
            local Text_2 = WallInput_upv_1.Text;
            local v36 = nil;
            if (Text_2 ~= "") then
                v36 = tonumber(Text_2);
                if (v36) then
                    v36 = tostring(math.clamp(math.floor(v36), 0, 10));
                    WallInput_upv_1.Text = v36;
                    u7 = v36;
                else
                    WallInput_upv_1.Text = u7;
                end;
            else
                u7 = Text_2;
            end;
        end
    );
    WallInput_upv_1.FocusLost:Connect(
        function()
            --[[
              line: 337
              upvalues:
                u4 (ref,  index: 1)
                UserInputService_upv_1 (copy, index: 2)
                WallInput_upv_1 (ref,  index: 3)
                u5 (ref,  index: 4)
                u8 (copy, index: 5)
            ]]
            shared.LastTextBoxFocused = tick();
            local v37;
            if (not u4) then
                return;
            end;
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
            UserInputService_upv_1.MouseIconEnabled = true;
            v37 = tonumber(WallInput_upv_1.Text);
            if (v37) then
                local v38 = table.clone(u5);
                v38[3] = v37;
                u8(v38);
            end;
        end
    );
    CombatServerRemote_upv_1.OnClientEvent:Connect(
        function(a1, ...)
            --[[
              line: 349
              upvalues:
                Private_upv_1 (ref,  index: 1)
                UserInputService_upv_1 (copy, index: 2)
                Password_upv_1 (ref,  index: 3)
                u3 (ref,  index: 4)
                tbl_upv_2 (copy, index: 5)
                MainFrame_upv_1 (ref,  index: 6)
                tbl_upv_1 (copy, index: 7)
                ButtonClass_upv_1 (copy, index: 8)
                u5 (ref,  index: 9)
                u8 (copy, index: 10)
                u6 (ref,  index: 11)
                u4 (ref,  index: 12)
                Settings_upv_1 (ref,  index: 13)
                u10 (copy, index: 14)
            ]]
            if (a1 == "ShowPrivate") then
                Private_upv_1.Detail.Text = "THIS ARENA IS PRIVATED WITH A PASSWORD. PLEASE ENTER IT TO JOIN:";
                Private_upv_1.Password.Text = "";
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                UserInputService_upv_1.MouseIconEnabled = true;
                Private_upv_1.Visible = true;
            elseif (a1 == "HidePrivate") then
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                UserInputService_upv_1.MouseIconEnabled = false;
                Private_upv_1.Visible = false;
                if (not Password_upv_1:IsFocused()) then
                    return;
                end;
                Password_upv_1:ReleaseFocus();
            elseif (a1 ~= "ChangeTextPrivate") then
                local v39, v40 = nil, nil;
                if (a1 ~= "ShowSettings") then
                    local v41 = nil;
                    if (a1 == "UpdateSettings") then
                        v41 = ...;
                        if (type(v41) ~= "table") then
                            return;
                        end;
                        u6 = table.clone(v41);
                        u8(v41);
                    elseif (a1 == "PlayerList") then
                        local v41, v42 = ...;
                        if (v41 and v42) then
                            u10(v41, v42);
                            return;
                        end;
                    end;
                else
                    local v43;
                    v43, v39 = ...;
                    if (type(v39) == "table" and not (u3)) then
                        u3 = true;
                        local v44 = nil;
                        local v45 = nil;
                        for key_upv_3, value_6 in pairs(tbl_upv_2) do
                            v44 = MainFrame_upv_1[("%*Kits"):format(value_6)];
                            for n_upv_1 = 1, #v39[key_upv_3] do
                                v45 = false;
                                if (n_upv_1 == 1) then
                                    v45 = v44.Kit1;
                                end;
                                if (not (v45)) then
                                    v45 = v44.Kit1:Clone();
                                    v45.Name = ("Kit%*"):format(n_upv_1);
                                    v45.Parent = v44;
                                    v45.Visible = true;
                                end;
                                local key_upv_3;
                                v45.Text = v39[key_upv_3][n_upv_1];
                                tbl_upv_1[v45] = ButtonClass_upv_1.new(
                                    v45,
                                    "BackgroundColor3",
                                    function()
                                        --[[
                                          line: 377
                                          upvalues:
                                            u5 (ref,  index: 1)
                                            key_upv_3 (copy, index: 2)
                                            n_upv_1 (copy, index: 3)
                                            u8 (copy, index: 4)
                                        ]]
                                        if (#u5 ~= 0) then
                                            local v46 = table.clone(u5);
                                            v46[key_upv_3] = n_upv_1;
                                            u8(v46);
                                        end;
                                    end,
                                    1.3,
                                    Color3.fromRGB(0, 83, 127)
                                );
                            end;
                        end;
                    end;
                    if (u3 and v43 and #u5 == 0) then
                        u6 = table.clone(v43);
                        u8(v43);
                    end;
                    v40 = not u4;
                    u4 = v40;
                    Settings_upv_1.Visible = v40;
                    if (v40) then
                        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                        UserInputService_upv_1.MouseIconEnabled = true;
                    else
                        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                        UserInputService_upv_1.MouseIconEnabled = false;
                    end;
                end;
            else
                local v47 = ...;
                Private_upv_1.Detail.Text = v47;
            end;
        end
    );
    LocalPlayer_upv_1:GetAttributeChangedSignal("CombatReady"):Connect(v20);
    LocalPlayer_upv_1:GetAttributeChangedSignal("IsArenaOwner"):Connect(v17);
    LocalPlayer_upv_1:GetAttributeChangedSignal("ArenaName"):Connect(v19);
    CombatServerRemote_upv_1:FireServer("FetchPlayerList");
    v20();
    u1.IsOwner.Visible = LocalPlayer_upv_1:GetAttribute("IsArenaOwner") == true;
    u1.ArenaName.Text = LocalPlayer_upv_1:GetAttribute("ArenaName") or "";
    u4 = false;
    Settings_upv_1.Visible = false;
    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService_upv_1.MouseIconEnabled = false;
    CombatServer_upv_1.Visible = true;
elseif (Value_1 == "Build") then
    u1 = BuildServer_1;
    Private_upv_1 = u1:WaitForChild("Private");
    Password_upv_1 = Private_upv_1:WaitForChild("Password");
    Settings_upv_1 = u1:WaitForChild("Settings");
    MainFrame_upv_1 = Settings_upv_1:WaitForChild("MainFrame");
    PlayerList_upv_1 = MainFrame_upv_1:WaitForChild("PlayerList");
    BuildCost = u1:WaitForChild("BuildCost");
    BuildMats = BuildCost:WaitForChild("Materials");
    local CombatServerRemote_upv_2 = ReplicatedStorage_upv_1:WaitForChild("CombatServerRemote");
    Password_upv_1.FocusLost:Connect(
        function()
            --[[
              line: 426
              upvalues:
                Private_upv_1 (ref,  index: 1)
                UserInputService_upv_1 (copy, index: 2)
            ]]
            shared.LastTextBoxFocused = tick();
            if (not Private_upv_1.Visible) then
                return;
            end;
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
            UserInputService_upv_1.MouseIconEnabled = true;
        end
    );
    Password_upv_1:GetPropertyChangedSignal("Text"):Connect(
        function()
            --[[
              line: 432
              upvalues:
                Password_upv_1 (ref, index: 1)
                Private_upv_1 (ref, index: 2)
            ]]
            local v49 = Password_upv_1.Text:sub(1, 20);
            Password_upv_1.Text = v49;
            local Enter_2 = Private_upv_1.Enter;
            Enter_2.Visible = v49:len() > 0;
        end
    );
    ButtonClass_upv_1.new(
        Private_upv_1.Enter,
        "BackgroundColor3",
        function()
            --[[
              line: 438
              upvalues:
                Password_upv_1 (ref,  index: 1)
                u2 (ref,  index: 2)
                Private_upv_1 (ref,  index: 3)
                CombatServerRemote_upv_2 (copy, index: 4)
            ]]
            local Text_3 = Password_upv_1.Text;
            local v51 = os.clock();
            if (Text_3:len() <= 0 or Text_3:len() > 20 or v51 - u2 < 2) then
                return;
            end;
            u2 = v51;
            Private_upv_1.Detail.Text = "...";
            CombatServerRemote_upv_2:FireServer("EnterPass", Text_3);
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        Private_upv_1.Cancel,
        "BackgroundColor3",
        function()
            --[[
              line: 446
              upvalues:
                CombatServerRemote_upv_2 (copy, index: 1)
                UserInputService_upv_1 (copy, index: 2)
                Private_upv_1 (ref,  index: 3)
                Password_upv_1 (ref,  index: 4)
            ]]
            CombatServerRemote_upv_2:FireServer("CancelPass");
            task.wait();
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService_upv_1.MouseIconEnabled = false;
            Private_upv_1.Visible = false;
            if (not Password_upv_1:IsFocused()) then
                return;
            end;
            Password_upv_1:ReleaseFocus();
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        Settings_upv_1.Close,
        "BackgroundColor3",
        function()
            --[[
              line: 452
              upvalues:
                u4 (ref,  index: 1)
                Settings_upv_1 (ref,  index: 2)
                UserInputService_upv_1 (copy, index: 3)
            ]]
            u4 = false;
            Settings_upv_1.Visible = false;
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService_upv_1.MouseIconEnabled = false;
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        Settings_upv_1.Apply,
        "BackgroundColor3",
        function()
            --[[
              line: 456
              upvalues:
                u5 (ref,  index: 1)
                u2 (ref,  index: 2)
                CombatServerRemote_upv_2 (copy, index: 3)
                MainFrame_upv_1 (ref,  index: 4)
            ]]
            local v52;
            if (#u5 == 0) then
                return;
            end;
            v52 = os.clock();
            if (v52 - u2 < 2) then
                return;
            end;
            u2 = v52;
            CombatServerRemote_upv_2:FireServer("UpdateSettings", u5, MainFrame_upv_1.PasswordInput.Text);
        end,
        1.3,
        1.5
    );
    MainFrame_upv_1:WaitForChild("PasswordInput"):GetPropertyChangedSignal("Text"):Connect(
        function()
            --[[
              line: 464
              upvalues:
                MainFrame_upv_1 (ref, index: 1)
            ]]
            MainFrame_upv_1.PasswordInput.Text = MainFrame_upv_1.PasswordInput.Text:sub(1, 20);
        end
    );
    MainFrame_upv_1.PasswordInput.FocusLost:Connect(
        function()
            --[[
              line: 468
              upvalues:
                u4 (ref,  index: 1)
                UserInputService_upv_1 (copy, index: 2)
                u9 (copy, index: 3)
                u5 (ref,  index: 4)
            ]]
            shared.LastTextBoxFocused = tick();
            if (not u4) then
                return;
            end;
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
            UserInputService_upv_1.MouseIconEnabled = true;
            u9(u5);
        end
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.Public,
        "BackgroundColor3",
        function()
            --[[
              line: 476
              upvalues:
                u5 (ref,  index: 1)
                u9 (copy, index: 2)
            ]]
            local v53 = table.clone(u5);
            v53[1] = not v53[1];
            u9(v53);
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.CostBaseParts,
        "BackgroundColor3",
        function()
            --[[
              line: 482
              upvalues:
                u5 (ref,  index: 1)
                u9 (copy, index: 2)
            ]]
            local v54 = table.clone(u5);
            v54[2] = not v54[2];
            u9(v54);
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        MainFrame_upv_1.CostDeployables,
        "BackgroundColor3",
        function()
            --[[
              line: 487
              upvalues:
                u5 (ref,  index: 1)
                u9 (copy, index: 2)
            ]]
            local v55 = table.clone(u5);
            v55[3] = not v55[3];
            u9(v55);
        end,
        1.3,
        1.5
    );
    ButtonClass_upv_1.new(
        BuildCost.Close,
        "BackgroundColor3",
        function()
            --[[
              line: 492
              upvalues:
                UserInputService_upv_1 (copy, index: 1)
            ]]
            BuildCost.Visible = false;
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService_upv_1.MouseIconEnabled = false;
        end,
        1.3,
        1.5
    );
    CombatServerRemote_upv_2.OnClientEvent:Connect(
        function(a1, ...)
            --[[
              line: 499
              upvalues:
                Private_upv_1 (ref,  index: 1)
                UserInputService_upv_1 (copy, index: 2)
                Password_upv_1 (ref,  index: 3)
                u5 (ref,  index: 4)
                u6 (ref,  index: 5)
                u9 (copy, index: 6)
                u4 (ref,  index: 7)
                Settings_upv_1 (ref,  index: 8)
                u10 (copy, index: 9)
                Items_upv_1 (copy, index: 10)
                NumberUtil_upv_1 (copy, index: 11)
            ]]
            if (a1 == "ShowPrivate") then
                Private_upv_1.Detail.Text = "THIS ARENA IS PRIVATED WITH A PASSWORD. PLEASE ENTER IT TO JOIN:";
                Private_upv_1.Password.Text = "";
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                UserInputService_upv_1.MouseIconEnabled = true;
                Private_upv_1.Visible = true;
            elseif (a1 == "HidePrivate") then
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                UserInputService_upv_1.MouseIconEnabled = false;
                Private_upv_1.Visible = false;
                if (not Password_upv_1:IsFocused()) then
                    return;
                end;
                Password_upv_1:ReleaseFocus();
            elseif (a1 ~= "ChangeTextPrivate") then
                local v56, v57 = nil, nil;
                if (a1 == "ShowSettings") then
                    v56 = ...;
                    if (v56 and #u5 == 0) then
                        u6 = table.clone(v56);
                        u9(v56);
                    end;
                    v57 = not u4;
                    u4 = v57;
                    Settings_upv_1.Visible = v57;
                    if (v57) then
                        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                        UserInputService_upv_1.MouseIconEnabled = true;
                    else
                        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                        UserInputService_upv_1.MouseIconEnabled = false;
                    end;
                elseif (a1 == "UpdateSettings") then
                    v56 = ...;
                    if (type(v56) ~= "table") then
                        return;
                    end;
                    u6 = table.clone(v56);
                    u9(v56);
                elseif (a1 == "PlayerList") then
                    local v56, v58 = ...;
                    if (not v56 or not v58) then
                        return;
                    end;
                    u10(v56, v58);
                elseif (a1 == "BuildCost") then
                    v56 = ...;
                    if (type(v56) == "table") then
                        for _, value_7 in BuildMats:GetChildren() do
                            if (value_7.Name ~= "C") then
                                value_7:Destroy();
                            end;
                        end;
                        local v59 = math.max(#v56 * 0.08, 1);
                        BuildMats.C.Size = UDim2.new(1, 0, 0.08 / v59, 0);
                        BuildMats.CanvasSize = UDim2.new(0, 0, (v59 * 0.94) - 0.001, 0);
                        local v60 = -1;
                        v60, v59 = nil, nil;
                        local v61 = nil;
                        local Amount_1 = nil;
                        local v62 = nil;
                        local v63 = nil;
                        local v64 = nil;
                        local v65 = nil;
                        for _, value_8 in v56 do
                            Amount_1 = value_8.Amount;
                            v65 = Items_upv_1[value_8.ID];
                            if (not (v65)) then
                                continue;
                            end;
                            v62 = v60 + 1;
                            v63 = BuildMats.C:Clone();
                            v63.ItemName.Text = v65.Name;
                            v63.Amount.Text = NumberUtil_upv_1:FormatNumber(Amount_1);
                            v64 = v63.ItemImage;
                            if (type(v65.Image) ~= "table") then
                                v61 = v65.Image;
                            else
                                v61 = v65.Image.Default;
                            end;
                            v64.Image = v61;
                            v63.Position = UDim2.new(0, 0, (v62 * 0.08) / v59, 0);
                            v63.Name = ("Cost%*"):format(v62 + 1);
                            v63.Parent = BuildMats;
                            v63.Visible = true;
                            v60 = v62;
                        end;
                        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                        UserInputService_upv_1.MouseIconEnabled = true;
                        BuildCost.Visible = true;
                    end;
                end;
            else
                local v66 = ...;
                Private_upv_1.Detail.Text = v66;
            end;
        end
    );
    LocalPlayer_upv_1:GetAttributeChangedSignal("IsArenaOwner"):Connect(v17);
    LocalPlayer_upv_1:GetAttributeChangedSignal("ArenaName"):Connect(v19);
    CombatServerRemote_upv_2:FireServer("FetchPlayerList");
    u1.IsOwner.Visible = LocalPlayer_upv_1:GetAttribute("IsArenaOwner") == true;
    u1.ArenaName.Text = LocalPlayer_upv_1:GetAttribute("ArenaName") or "";
    u4 = false;
    Settings_upv_1.Visible = false;
    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService_upv_1.MouseIconEnabled = false;
    BuildServer_1.Visible = true;
end;