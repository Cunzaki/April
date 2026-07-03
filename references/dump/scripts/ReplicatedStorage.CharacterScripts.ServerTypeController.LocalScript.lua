-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local Values = ReplicatedStorage:WaitForChild("Values");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local ButtonClass = require(Modules:WaitForChild("ButtonClass"));
local TableUtil = require(Modules:WaitForChild("TableUtil"));
local Items = require(Modules:WaitForChild("Items"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local LocalPlayer = Players.LocalPlayer;
local Parent = script.Parent;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
Parent:WaitForChild("Humanoid");
local Main = PlayerGui:WaitForChild("Main");
local CombatServer = Main:WaitForChild("CombatServer");
local u1 = nil;
local u2 = nil;
local u3 = nil;
local u4 = nil;
local u5 = nil;
local u6 = nil;
local BuildServer = Main:WaitForChild("BuildServer");
local Value = Values:WaitForChild("ServerType").Value;
local u7 = os.clock();
local u8 = false;
local u9 = false;
local u10 = {};
local u11 = {};
local u12 = {};
local u13 = { "Weapon", "Armor" };
local u14 = { "Red", "Blue" };
local u15 = "";
local u16 = {};

local function _() -- Line: 58
    -- upvalues: UserInputService (copy), u2 (ref), u3 (ref)
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    u2.Visible = false;

    if u3:IsFocused() then
        u3:ReleaseFocus();
    end;
end;

local function u29(p17) -- Line: 67
    -- upvalues: u13 (copy), u5 (ref), u10 (copy), u11 (ref), u12 (ref), u4 (ref), TableUtil (copy)
    for i, v in pairs(u13) do
        local v18 = p17[i];
        local v19 = u5[`{v}Kits`];
        local v20 = v19:FindFirstChild((`Kit{v18}`));

        if v20 then
            local v21 = u10[v20];

            if v21 and not v21:IsToggled() then
                task.defer(v21.ToggleButton, v21, true);
            end;
        end;

        local v22 = u11[i];

        if v22 and p17[i] ~= v22 then
            local v23 = v19:FindFirstChild((`Kit{v22}`));

            if v23 then
                local v24 = u10[v23];

                if v24 and v24:IsToggled() then
                    task.defer(v24.ToggleButton, v24, false);
                end;
            end;
        end;
    end;

    local v25 = p17[3];
    u5.WallInput.Text = tostring(v25);
    local v26 = p17[4];

    if not v26 and u11[4] then
        u5.PasswordInput.Text = "";
    end;

    if u12[4] == false then
        u5.PasswordExtra.Visible = true;
        u5.PasswordInput.Visible = false;
    else
        u5.PasswordExtra.Visible = false;
        u5.PasswordInput.Visible = not v26;
    end;

    u5.Public.Text = `Arena Status: <font color="{v26 and "rgb(0, 255, 0)\">PUBLIC" or "rgb(255, 0, 0)\">PRIVATE"}</font>`;
    u5.AutoStart.Text = `Auto Start: <font color="{p17[5] and "rgb(0, 255, 0)\">ON" or "rgb(255, 0, 0)\">OFF"}</font>`;
    u5.HealthRegen.Text = `Health Regen on Kill: <font color="{p17[6] and "rgb(0, 255, 0)\">ON" or "rgb(255, 0, 0)\">OFF"}</font>`;

    if type(v25) == "number" and (v25 >= 0 and (v25 <= 10 and (v26 or (u12[4] == v26 or u5.PasswordInput.Text ~= "")))) then
        u4.Apply.Visible = not TableUtil:CompareTables(u12, p17);
    else
        u4.Apply.Visible = false;
    end;

    local v27 = p17[7];
    u5.AmmoType.Text = `Bullet Ammo Type: <font color="rgb(255, 255, 0)">{v27 == 1 and "DEFAULT" or (v27 == 2 and "SWIFT" or (v27 == 3 and "PIERCING" or "COMBUSTIVE"))}</font>`;
    local v28 = p17[8];
    u5.WallType.Text = `Cover Type: <font color="rgb(255, 123, 0)">{v28 == 1 and "WOODEN WALLS" or (v28 == 2 and "STONE WALLS" or "BARRICADES")}</font>`;
    u11 = p17;
end;

local function u32(p30) -- Line: 118
    -- upvalues: u11 (ref), u5 (ref), u12 (ref), u4 (ref), TableUtil (copy)
    local v31 = p30[1];

    if not v31 and u11[1] then
        u5.PasswordInput.Text = "";
    end;

    if u12[1] == false then
        u5.PasswordExtra.Visible = true;
        u5.PasswordInput.Visible = false;
    else
        u5.PasswordExtra.Visible = false;
        u5.PasswordInput.Visible = not v31;
    end;

    u5.Public.Text = `Arena Status: <font color="{v31 and "rgb(0, 255, 0)\">PUBLIC" or "rgb(255, 0, 0)\">PRIVATE"}</font>`;

    if v31 or (u12[1] == v31 or u5.PasswordInput.Text ~= "") then
        u4.Apply.Visible = not TableUtil:CompareTables(u12, p30);
    else
        u4.Apply.Visible = false;
    end;

    u5.CostBaseParts.Text = `/cost Calculate Base Parts: <font color="{p30[2] and "rgb(0, 255, 0)\">ON" or "rgb(255, 0, 0)\">OFF"}</font>`;
    u5.CostDeployables.Text = `/cost Calculate Deployables: <font color="{p30[3] and "rgb(0, 255, 0)\">ON" or "rgb(255, 0, 0)\">OFF"}</font>`;
    u11 = p30;
end;

local function u38(...) -- Line: 143
    -- upvalues: u16 (ref), u6 (ref), u14 (copy), ButtonClass (copy), u7 (ref), ReplicatedStorage (copy)
    local v33 = { ... };

    for _, v in pairs(u16) do
        v:Destroy();
    end;

    u16 = {};

    for _, child in pairs(u6:GetChildren()) do
        if child.Name ~= "Red" and child.Name ~= "Blue" then
            child:Destroy();
        end;
    end;

    for i, v in pairs(u14) do
        local v34 = 0;

        for _, v2 in pairs(v33[i]) do
            if v2 and v2.Parent then
                v34 = v34 + 1;
                local v35 = u6[v]:Clone();
                v35.Name = `{v}{v34}`;
                v35.Label.Text = v2.Name;
                v35.Label.TextColor3 = v2:GetAttribute("CombatReady") and Color3.fromRGB(0, 255, 0) or Color3.new(1, 1, 1);
                v35.Position = UDim2.new(i == 1 and 0 or 0.5, 0, (v34 - 1) * 0.1, 0);
                v35.Parent = u6;
                v35.Visible = true;
                table.insert(u16, ButtonClass.new(v35.Kick, "BackgroundColor3", function() -- Line: 166
                    -- upvalues: u7 (ref), ReplicatedStorage (ref), v2 (copy)
                    local v36 = os.clock();

                    if v36 - u7 < 2 then
                        return;
                    end;

                    u7 = v36;
                    ReplicatedStorage.CombatServerRemote:FireServer("PlayerList", v2, "Kick");
                end, 1.3, 1.5));

                if v35:FindFirstChild("Swap") then
                    table.insert(u16, ButtonClass.new(v35.Swap, "BackgroundColor3", function() -- Line: 173
                        -- upvalues: u7 (ref), ReplicatedStorage (ref), v2 (copy)
                        local v37 = os.clock();

                        if v37 - u7 < 2 then
                            return;
                        end;

                        u7 = v37;
                        ReplicatedStorage.CombatServerRemote:FireServer("PlayerList", v2, "Swap");
                    end, 1.3, 1.5));
                end;
            end;
        end;
    end;
end;

local function _(p39) -- Line: 184
    -- upvalues: u9 (ref), u4 (ref), UserInputService (copy)
    u9 = p39;
    u4.Visible = p39;

    if p39 then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;

        return;
    end;

    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
end;

local function v41() -- Line: 196
    -- upvalues: LocalPlayer (copy), CombatServer (copy)
    local v40 = LocalPlayer:GetAttribute("CombatReady");
    CombatServer.Ready.Text = v40 and "Ready: YES" or (v40 == false and "Ready: NO" or "");
    CombatServer.Ready.TextColor3 = v40 and Color3.fromRGB(0, 255, 64) or Color3.fromRGB(255, 82, 82);
end;

local function v43() -- Line: 202
    -- upvalues: LocalPlayer (copy), u1 (ref)
    local v42 = LocalPlayer:GetAttribute("IsArenaOwner");
    u1.IsOwner.Visible = v42 == true;
end;

local function v44() -- Line: 207
    -- upvalues: u1 (ref), LocalPlayer (copy)
    u1.ArenaName.Text = LocalPlayer:GetAttribute("ArenaName") or "";
end;

if Value == "Combat" then
    u1 = CombatServer;
    u2 = u1:WaitForChild("Private");
    u3 = u2:WaitForChild("Password");
    u4 = u1:WaitForChild("Settings");
    u5 = u4:WaitForChild("MainFrame");
    u6 = u5:WaitForChild("PlayerList");
    local WallInput = u5:WaitForChild("WallInput");
    local CombatServerRemote = ReplicatedStorage:WaitForChild("CombatServerRemote");
    u3.FocusLost:Connect(function() -- Line: 222
        -- upvalues: u2 (ref), UserInputService (copy)
        shared.LastTextBoxFocused = tick();

        if not u2.Visible then
            return;
        end;

        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;
    end);
    u3:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 228
        -- upvalues: u3 (ref), u2 (ref)
        local v45 = u3.Text:sub(1, 20);
        u3.Text = v45;
        u2.Enter.Visible = v45:len() > 0;
    end);
    ButtonClass.new(u2.Enter, "BackgroundColor3", function() -- Line: 234
        -- upvalues: u3 (ref), u7 (ref), u2 (ref), CombatServerRemote (copy)
        local Text = u3.Text;
        local v46 = os.clock();

        if Text:len() <= 0 or (Text:len() > 20 or v46 - u7 < 2) then
            return;
        end;

        u7 = v46;
        u2.Detail.Text = "...";
        CombatServerRemote:FireServer("EnterPass", Text);
    end, 1.3, 1.5);
    ButtonClass.new(u2.Cancel, "BackgroundColor3", function() -- Line: 242
        -- upvalues: CombatServerRemote (copy), UserInputService (copy), u2 (ref), u3 (ref)
        CombatServerRemote:FireServer("CancelPass");
        task.wait();
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
        u2.Visible = false;

        if u3:IsFocused() then
            u3:ReleaseFocus();
        end;
    end, 1.3, 1.5);
    ButtonClass.new(u4.Close, "BackgroundColor3", function() -- Line: 248
        -- upvalues: u9 (ref), u4 (ref), UserInputService (copy)
        u9 = false;
        u4.Visible = false;
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
    end, 1.3, 1.5);
    ButtonClass.new(u4.Apply, "BackgroundColor3", function() -- Line: 252
        -- upvalues: u11 (ref), u7 (ref), CombatServerRemote (copy), u5 (ref)
        if #u11 == 0 then
            return;
        end;

        local v47 = os.clock();

        if v47 - u7 < 2 then
            return;
        end;

        u7 = v47;
        CombatServerRemote:FireServer("UpdateSettings", u11, u5.PasswordInput.Text);
    end, 1.3, 1.5);
    u5:WaitForChild("PasswordInput"):GetPropertyChangedSignal("Text"):Connect(function() -- Line: 260
        -- upvalues: u5 (ref)
        local v48 = u5.PasswordInput.Text:sub(1, 20);
        u5.PasswordInput.Text = v48;
    end);
    u5.PasswordInput.FocusLost:Connect(function() -- Line: 264
        -- upvalues: u9 (ref), UserInputService (copy), u29 (copy), u11 (ref)
        shared.LastTextBoxFocused = tick();

        if not u9 then
            return;
        end;

        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;
        u29(u11);
    end);
    ButtonClass.new(u5.Public, "BackgroundColor3", function() -- Line: 272
        -- upvalues: u11 (ref), u29 (copy)
        local v49 = table.clone(u11);
        v49[4] = not v49[4];
        u29(v49);
    end, 1.3, 1.5);
    ButtonClass.new(u5.ClearWalls, "BackgroundColor3", function() -- Line: 280
        -- upvalues: u7 (ref), CombatServerRemote (copy)
        local v50 = os.clock();

        if v50 - u7 < 2 then
            return;
        end;

        u7 = v50;
        CombatServerRemote:FireServer("ClearWalls");
    end, 1.3, 1.5);
    ButtonClass.new(u5.ForceStart, "BackgroundColor3", function() -- Line: 287
        -- upvalues: CombatServerRemote (copy)
        CombatServerRemote:FireServer("ForceStart");
    end, 1.3, 1.5);
    ButtonClass.new(u5.ShuffleTeams, "BackgroundColor3", function() -- Line: 291
        -- upvalues: u7 (ref), CombatServerRemote (copy)
        local v51 = os.clock();

        if v51 - u7 < 2 then
            return;
        end;

        u7 = v51;
        CombatServerRemote:FireServer("ShuffleTeams");
    end, 1.3, 1.5);
    ButtonClass.new(u5.AutoStart, "BackgroundColor3", function() -- Line: 298
        -- upvalues: u11 (ref), u29 (copy)
        local v52 = table.clone(u11);
        v52[5] = not v52[5];
        u29(v52);
    end, 1.3, 1.5);
    ButtonClass.new(u5.HealthRegen, "BackgroundColor3", function() -- Line: 303
        -- upvalues: u11 (ref), u29 (copy)
        local v53 = table.clone(u11);
        v53[6] = not v53[6];
        u29(v53);
    end, 1.3, 1.5);
    ButtonClass.new(u5.AmmoType, "BackgroundColor3", function() -- Line: 309
        -- upvalues: u11 (ref), u29 (copy)
        local v54 = table.clone(u11);
        local v55 = v54[7];
        v54[7] = v55 >= 4 and 1 or v55 + 1;
        u29(v54);
    end, 1.3, 1.5);
    ButtonClass.new(u5.WallType, "BackgroundColor3", function() -- Line: 315
        -- upvalues: u11 (ref), u29 (copy)
        local v56 = table.clone(u11);
        local v57 = v56[8];
        v56[8] = v57 >= 3 and 1 or v57 + 1;
        u29(v56);
    end, 1.3, 1.5);
    WallInput:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 322
        -- upvalues: WallInput (ref), u15 (ref)
        local Text = WallInput.Text;

        if Text == "" then
            u15 = Text;

            return;
        end;

        local v58 = tonumber(Text);

        if not v58 then
            WallInput.Text = u15;

            return;
        end;

        local v59 = math.floor(v58);
        local v60 = math.clamp(v59, 0, 10);
        local v61 = tostring(v60);
        WallInput.Text = v61;
        u15 = v61;
    end);
    WallInput.FocusLost:Connect(function() -- Line: 337
        -- upvalues: u9 (ref), UserInputService (copy), WallInput (ref), u11 (ref), u29 (copy)
        shared.LastTextBoxFocused = tick();

        if not u9 then
            return;
        end;

        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;
        local v62 = tonumber(WallInput.Text);

        if not v62 then
            return;
        end;

        local v63 = table.clone(u11);
        v63[3] = v62;
        u29(v63);
    end);
    CombatServerRemote.OnClientEvent:Connect(function(p64, ...) -- Line: 349
        -- upvalues: u2 (ref), UserInputService (copy), u3 (ref), u8 (ref), u13 (copy), u5 (ref), u10 (copy), ButtonClass (copy), u11 (ref), u29 (copy), u12 (ref), u9 (ref), u4 (ref), u38 (copy)
        if p64 ~= "ShowPrivate" then
            if p64 == "HidePrivate" then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
                UserInputService.MouseIconEnabled = false;
                u2.Visible = false;

                if u3:IsFocused() then
                    u3:ReleaseFocus();

                    return;
                end;
            else
                if p64 == "ChangeTextPrivate" then
                    u2.Detail.Text = ...;

                    return;
                end;

                if p64 == "ShowSettings" then
                    local v65, v66 = ...;

                    if type(v66) == "table" and not u8 then
                        u8 = true;

                        for i, v in pairs(u13) do
                            local v67 = u5[`{v}Kits`];

                            for i2 = 1, #v66[i] do
                                local v68;

                                if i2 == 1 then
                                    v68 = v67.Kit1;
                                else
                                    v68 = false;
                                end;

                                if not v68 then
                                    v68 = v67.Kit1:Clone();
                                    v68.Name = `Kit{i2}`;
                                    v68.Parent = v67;
                                    v68.Visible = true;
                                end;

                                v68.Text = v66[i][i2];
                                u10[v68] = ButtonClass.new(v68, "BackgroundColor3", function() -- Line: 377
                                    -- upvalues: u11 (ref), i (copy), i2 (copy), u29 (ref)
                                    if #u11 == 0 then
                                        return;
                                    end;

                                    local v69 = table.clone(u11);
                                    v69[i] = i2;
                                    u29(v69);
                                end, 1.3, Color3.fromRGB(0, 83, 127));
                            end;
                        end;
                    end;

                    if u8 and (v65 and #u11 == 0) then
                        u12 = table.clone(v65);
                        u29(v65);
                    end;

                    local v70 = not u9;
                    u9 = v70;
                    u4.Visible = v70;

                    if v70 then
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
                        UserInputService.MouseIconEnabled = true;

                        return;
                    end;

                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
                    UserInputService.MouseIconEnabled = false;

                    return;
                end;

                if p64 == "UpdateSettings" then
                    local v71 = ...;

                    if type(v71) ~= "table" then
                        return;
                    end;

                    u12 = table.clone(v71);
                    u29(v71);

                    return;
                end;

                if p64 == "PlayerList" then
                    local v72, v73 = ...;

                    if not (v72 and v73) then
                        return;
                    end;

                    u38(v72, v73);
                end;
            end;

            return;
        end;

        u2.Detail.Text = "THIS ARENA IS PRIVATED WITH A PASSWORD. PLEASE ENTER IT TO JOIN:";
        u2.Password.Text = "";
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;
        u2.Visible = true;
    end);
    LocalPlayer:GetAttributeChangedSignal("CombatReady"):Connect(v41);
    LocalPlayer:GetAttributeChangedSignal("IsArenaOwner"):Connect(v43);
    LocalPlayer:GetAttributeChangedSignal("ArenaName"):Connect(v44);
    CombatServerRemote:FireServer("FetchPlayerList");
    v41();
    local v74 = LocalPlayer:GetAttribute("IsArenaOwner");
    u1.IsOwner.Visible = v74 == true;
    u1.ArenaName.Text = LocalPlayer:GetAttribute("ArenaName") or "";
    u9 = false;
    u4.Visible = false;
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    CombatServer.Visible = true;
elseif Value == "Build" then
    u1 = BuildServer;
    u2 = u1:WaitForChild("Private");
    u3 = u2:WaitForChild("Password");
    u4 = u1:WaitForChild("Settings");
    u5 = u4:WaitForChild("MainFrame");
    u6 = u5:WaitForChild("PlayerList");
    BuildCost = u1:WaitForChild("BuildCost");
    BuildMats = BuildCost:WaitForChild("Materials");
    local CombatServerRemote = ReplicatedStorage:WaitForChild("CombatServerRemote");
    u3.FocusLost:Connect(function() -- Line: 426
        -- upvalues: u2 (ref), UserInputService (copy)
        shared.LastTextBoxFocused = tick();

        if not u2.Visible then
            return;
        end;

        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;
    end);
    u3:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 432
        -- upvalues: u3 (ref), u2 (ref)
        local v75 = u3.Text:sub(1, 20);
        u3.Text = v75;
        u2.Enter.Visible = v75:len() > 0;
    end);
    ButtonClass.new(u2.Enter, "BackgroundColor3", function() -- Line: 438
        -- upvalues: u3 (ref), u7 (ref), u2 (ref), CombatServerRemote (copy)
        local Text = u3.Text;
        local v76 = os.clock();

        if Text:len() <= 0 or (Text:len() > 20 or v76 - u7 < 2) then
            return;
        end;

        u7 = v76;
        u2.Detail.Text = "...";
        CombatServerRemote:FireServer("EnterPass", Text);
    end, 1.3, 1.5);
    ButtonClass.new(u2.Cancel, "BackgroundColor3", function() -- Line: 446
        -- upvalues: CombatServerRemote (copy), UserInputService (copy), u2 (ref), u3 (ref)
        CombatServerRemote:FireServer("CancelPass");
        task.wait();
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
        u2.Visible = false;

        if u3:IsFocused() then
            u3:ReleaseFocus();
        end;
    end, 1.3, 1.5);
    ButtonClass.new(u4.Close, "BackgroundColor3", function() -- Line: 452
        -- upvalues: u9 (ref), u4 (ref), UserInputService (copy)
        u9 = false;
        u4.Visible = false;
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
    end, 1.3, 1.5);
    ButtonClass.new(u4.Apply, "BackgroundColor3", function() -- Line: 456
        -- upvalues: u11 (ref), u7 (ref), CombatServerRemote (copy), u5 (ref)
        if #u11 == 0 then
            return;
        end;

        local v77 = os.clock();

        if v77 - u7 < 2 then
            return;
        end;

        u7 = v77;
        CombatServerRemote:FireServer("UpdateSettings", u11, u5.PasswordInput.Text);
    end, 1.3, 1.5);
    u5:WaitForChild("PasswordInput"):GetPropertyChangedSignal("Text"):Connect(function() -- Line: 464
        -- upvalues: u5 (ref)
        local v78 = u5.PasswordInput.Text:sub(1, 20);
        u5.PasswordInput.Text = v78;
    end);
    u5.PasswordInput.FocusLost:Connect(function() -- Line: 468
        -- upvalues: u9 (ref), UserInputService (copy), u32 (copy), u11 (ref)
        shared.LastTextBoxFocused = tick();

        if not u9 then
            return;
        end;

        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;
        u32(u11);
    end);
    ButtonClass.new(u5.Public, "BackgroundColor3", function() -- Line: 476
        -- upvalues: u11 (ref), u32 (copy)
        local v79 = table.clone(u11);
        v79[1] = not v79[1];
        u32(v79);
    end, 1.3, 1.5);
    ButtonClass.new(u5.CostBaseParts, "BackgroundColor3", function() -- Line: 482
        -- upvalues: u11 (ref), u32 (copy)
        local v80 = table.clone(u11);
        v80[2] = not v80[2];
        u32(v80);
    end, 1.3, 1.5);
    ButtonClass.new(u5.CostDeployables, "BackgroundColor3", function() -- Line: 487
        -- upvalues: u11 (ref), u32 (copy)
        local v81 = table.clone(u11);
        v81[3] = not v81[3];
        u32(v81);
    end, 1.3, 1.5);
    ButtonClass.new(BuildCost.Close, "BackgroundColor3", function() -- Line: 492
        -- upvalues: UserInputService (copy)
        BuildCost.Visible = false;
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
    end, 1.3, 1.5);
    CombatServerRemote.OnClientEvent:Connect(function(p82, ...) -- Line: 499
        -- upvalues: u2 (ref), UserInputService (copy), u3 (ref), u11 (ref), u12 (ref), u32 (copy), u9 (ref), u4 (ref), u38 (copy), Items (copy), NumberUtil (copy)
        if p82 ~= "ShowPrivate" then
            if p82 == "HidePrivate" then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
                UserInputService.MouseIconEnabled = false;
                u2.Visible = false;

                if u3:IsFocused() then
                    u3:ReleaseFocus();

                    return;
                end;
            else
                if p82 == "ChangeTextPrivate" then
                    u2.Detail.Text = ...;

                    return;
                end;

                if p82 == "ShowSettings" then
                    local v83 = ...;

                    if v83 and #u11 == 0 then
                        u12 = table.clone(v83);
                        u32(v83);
                    end;

                    local v84 = not u9;
                    u9 = v84;
                    u4.Visible = v84;

                    if v84 then
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
                        UserInputService.MouseIconEnabled = true;

                        return;
                    end;

                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
                    UserInputService.MouseIconEnabled = false;

                    return;
                end;

                if p82 == "UpdateSettings" then
                    local v85 = ...;

                    if type(v85) ~= "table" then
                        return;
                    end;

                    u12 = table.clone(v85);
                    u32(v85);

                    return;
                end;

                if p82 == "PlayerList" then
                    local v86, v87 = ...;

                    if not (v86 and v87) then
                        return;
                    end;

                    u38(v86, v87);

                    return;
                end;

                if p82 == "BuildCost" then
                    local v88 = ...;

                    if type(v88) ~= "table" then
                        return;
                    end;

                    for _, child in BuildMats:GetChildren() do
                        if child.Name ~= "C" then
                            child:Destroy();
                        end;
                    end;

                    local v89 = math.max(#v88 * 0.08, 1);
                    BuildMats.C.Size = UDim2.new(1, 0, 0.08 / v89, 0);
                    BuildMats.CanvasSize = UDim2.new(0, 0, v89 * 0.94 - 0.001, 0);
                    local v90 = -1;

                    for _, v in v88 do
                        local Amount = v.Amount;
                        local v91 = Items[v.ID];

                        if v91 then
                            v90 = v90 + 1;
                            local v92 = BuildMats.C:Clone();
                            v92.ItemName.Text = v91.Name;
                            v92.Amount.Text = NumberUtil:FormatNumber(Amount);
                            local ItemImage = v92.ItemImage;
                            local v93;

                            if type(v91.Image) == "table" then
                                v93 = v91.Image.Default;
                            else
                                v93 = v91.Image;
                            end;

                            ItemImage.Image = v93;
                            v92.Position = UDim2.new(0, 0, v90 * 0.08 / v89, 0);
                            v92.Name = `Cost{v90 + 1}`;
                            v92.Parent = BuildMats;
                            v92.Visible = true;
                        end;
                    end;

                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
                    UserInputService.MouseIconEnabled = true;
                    BuildCost.Visible = true;
                end;
            end;

            return;
        end;

        u2.Detail.Text = "THIS ARENA IS PRIVATED WITH A PASSWORD. PLEASE ENTER IT TO JOIN:";
        u2.Password.Text = "";
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;
        u2.Visible = true;
    end);
    LocalPlayer:GetAttributeChangedSignal("IsArenaOwner"):Connect(v43);
    LocalPlayer:GetAttributeChangedSignal("ArenaName"):Connect(v44);
    CombatServerRemote:FireServer("FetchPlayerList");
    local v94 = LocalPlayer:GetAttribute("IsArenaOwner");
    u1.IsOwner.Visible = v94 == true;
    u1.ArenaName.Text = LocalPlayer:GetAttribute("ArenaName") or "";
    u9 = false;
    u4.Visible = false;
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    BuildServer.Visible = true;
end;