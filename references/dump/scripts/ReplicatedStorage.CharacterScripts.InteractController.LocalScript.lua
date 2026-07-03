-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local UserInputService = game:GetService("UserInputService");
local UserService = game:GetService("UserService");
local MarketplaceService = game:GetService("MarketplaceService");
local Drops = workspace:WaitForChild("Drops");
local Bases = workspace:WaitForChild("Bases");
local Animals = workspace:WaitForChild("Animals");
local Plants = workspace:WaitForChild("Plants");
local Vegetation = workspace:WaitForChild("Vegetation");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local VFX = workspace:WaitForChild("VFX");
local VFX2 = ReplicatedStorage:WaitForChild("VFX");
local Values = ReplicatedStorage:WaitForChild("Values");
local GamepadIconModule = require(Modules:WaitForChild("GamepadIconModule"));
local Items = require(Modules:WaitForChild("Items"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local TweenUtil = require(Modules:WaitForChild("TweenUtil"));
local BenchInfo = require(Modules:WaitForChild("BenchInfo"));
local ButtonClass = require(Modules:WaitForChild("ButtonClass"));
local VFXModule = require(Modules:WaitForChild("VFXModule"));
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local AssetContainer = require(Modules:WaitForChild("AssetContainer"));
local ActiveBenchModule = require(Modules:WaitForChild("ActiveBenchModule"));
local u1 = AssetContainer();
local LocalPlayer = Players.LocalPlayer;
local Parent = script.Parent;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local Humanoid = Parent:WaitForChild("Humanoid");
local HumanoidRootPart = Parent:WaitForChild("HumanoidRootPart");
LocalPlayer:GetMouse();
local CurrentCamera = workspace.CurrentCamera;
local InventoryController = Parent:WaitForChild("InventoryController");
local EquipController = Parent:WaitForChild("EquipController");
local WheelController = Parent:WaitForChild("WheelController");
local CameraController = Parent:WaitForChild("CameraController");
local TeamNavigationController = Parent:WaitForChild("TeamNavigationController");
local WaterController = Parent:WaitForChild("WaterController");
local ClanLeaderboardController = Parent:WaitForChild("ClanLeaderboardController");
local ElectricityController = Parent:WaitForChild("ElectricityController");
local PreferredInputController = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local GetSelected = script:WaitForChild("GetSelected");
local Update = ClanLeaderboardController:WaitForChild("Update");
local FetchTeam = TeamNavigationController:WaitForChild("FetchTeam");
local OpenBench = ElectricityController:WaitForChild("OpenBench");
local Main = PlayerGui:WaitForChild("Main");
local Hover = Main:WaitForChild("Hover");
local Codelock = Main:WaitForChild("Codelock");
local Controls = Codelock:WaitForChild("Controls");
local Info = VFX2:WaitForChild("Info");
local Interaction = Main:WaitForChild("GamepadControls"):WaitForChild("Interaction");
local RenameBed = Main:WaitForChild("RenameBed");
local TextBox = RenameBed:WaitForChild("TextBox");
local GiveBed = Main:WaitForChild("GiveBed");
local TextBox2 = GiveBed:WaitForChild("TextBox");
local FoundUser = GiveBed:WaitForChild("FoundUser");
local EditSign = Main:WaitForChild("EditSign");
local Dialogue = Main:WaitForChild("Dialogue");
local PowerThroughput = Main:WaitForChild("WireCutterInfo"):WaitForChild("PowerThroughput");
local u2 = nil;
local u3 = nil;
local v4 = nil;
local u5 = nil;
local u6 = tick();
local u7 = false;
local v8 = {};
local u9 = "";
local u10 = {
    One = "1",
    Two = "2",
    Three = "3",
    Four = "4",
    Five = "5",
    Six = "6",
    Seven = "7",
    Eight = "8",
    Nine = "9",
    Zero = "0"
};
local u11 = "";
local u12 = 0;
local u13 = 0;
local u14 = nil;
local u15 = nil;
local u16 = 1;
local u17 = 1;
local u18 = false;
local u19 = 0;
local u20 = { { "1", "2", "3" }, { "4", "5", "6" }, { "7", "8", "9" }, { "Last", "0", "Clear" } };
local u21 = nil;
local u22 = nil;
local u23 = {};
local u24 = 0;
local u25 = 0;
local u26 = 0;
local u27 = 0;
local u28 = 0;
local u29 = 0;
local u30 = nil;
local u31 = nil;

local function _(p32) -- Line: 161
    -- upvalues: InventoryController (copy), EquipController (copy)
    local v33 = InventoryController.Fetch:Invoke();

    if not v33 then
        return;
    end;

    local Toolbar = v33.Toolbar;

    if Toolbar then
        local v34 = Toolbar[p32 or EquipController:GetAttribute("Equipped")];

        if v34 == nil then
            v34 = false;
        elseif v34 == 0 then
            v34 = false;
        end;

        return v34;
    end;
end;

local u35 = nil;

local function UpdateCodelockHighlight() -- Line: 172
    -- upvalues: u21 (ref), u20 (copy), u16 (ref), u17 (ref), Controls (copy), GamepadIconModule (copy)
    if not u21 then
        return;
    end;

    local v36 = u20[u16] and u20[u16][u17];

    if not v36 then
        return;
    end;

    local v37 = Controls.Keys:FindFirstChild(v36);

    if v37 then
        u21.Parent = v37;
        u21.Visible = true;
        u21.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
    end;
end;

local function ClearCodelockHighlight() -- Line: 184
    -- upvalues: u21 (ref)
    if u21 then
        u21.Visible = false;
    end;
end;

local function u40() -- Line: 190
    -- upvalues: u9 (ref), Controls (copy), ReplicatedStorage (copy), u35 (ref)
    local v38 = u9:len();
    local v39 = string.rep("* ", (math.min(v38, 5)));
    Controls.Display.Code.Text = v39:sub(1, v39:len() - 1);

    if v38 >= 5 then
        ReplicatedStorage:SetAttribute("LastCode", u9:sub(1, 5));
        task.delay(0.1, u35, false);
    end;
end;

u35 = function(p41) -- Line: 200
    -- upvalues: u9 (ref), u40 (ref), u16 (ref), u17 (ref), u18 (ref), u21 (ref), Controls (copy), GamepadIconModule (copy), Codelock (copy), PreferredInputController (copy), u20 (copy), UserInputService (copy), u15 (ref)
    if p41 then
        u9 = "";
        u40();
        u16 = 1;
        u17 = 1;
        u18 = false;

        if not u21 then
            local v42 = Controls.Keys:FindFirstChild("0") and Controls.Keys["0"]:FindFirstChild("GamepadSelected");
            u21 = v42;

            if u21 then
                GamepadIconModule.Register(u21.ImageLabel, "ButtonA");
            end;

            GamepadIconModule.Register(Codelock.GamepadControls.CloseButton, "ButtonB");
        end;

        local v43 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v43 and u21 then
            local v44 = u20[u16] and u20[u16][u17];
            local v45 = v44 and Controls.Keys:FindFirstChild(v44);

            if v45 then
                u21.Parent = v45;
                u21.Visible = true;
                u21.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
            end;
        end;

        Codelock.GamepadControls.Visible = v43;
    else
        if u21 then
            u21.Visible = false;
        end;

        Codelock.GamepadControls.Visible = false;
    end;

    UserInputService.MouseBehavior = Enum.MouseBehavior[p41 and "Default" or "LockCenter"];
    UserInputService.MouseIconEnabled = p41;
    Codelock.Visible = p41;

    if u15 then
        task.cancel(u15);
    end;
end;

local function u48(p46) -- Line: 231
    -- upvalues: u15 (ref), u9 (ref), ReplicatedStorage (copy), u40 (ref)
    if p46 == "Clear" then
        if u15 then
            task.cancel(u15);
        end;

        u9 = "";
    elseif p46 == "Last" then
        local u47 = ReplicatedStorage:GetAttribute("LastCode");

        if u47 then
            if u15 then
                task.cancel(u15);
            end;

            u9 = "";
            u15 = task.spawn(function() -- Line: 244
                -- upvalues: u9 (ref), u47 (copy), u40 (ref), u15 (ref)
                for i = 1, 5 do
                    u9 = u47:sub(1, i);
                    u40();
                    task.wait(0.4);
                end;

                u15 = nil;
            end);
        end;
    else
        if u15 then
            task.cancel(u15);
        end;

        if u9:len() < 5 then
            u9 = u9 .. p46;
        end;
    end;

    u40();
end;

local function u53() -- Line: 267
    -- upvalues: ReplicatedStorage (copy), MarketplaceService (copy), LocalPlayer (copy), EditSign (copy)
    local v49 = ReplicatedStorage:GetAttribute("LabelsOwned");
    local v50 = false;
    local v51;

    if v49 and os.time() - v49 < 30 then
        v51 = true;
    else
        local v52;
        v52, v51 = pcall(function() -- Line: 274
            -- upvalues: MarketplaceService (ref), LocalPlayer (ref)
            return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, 667425168);
        end);

        if not v52 then
            v51 = v50;
        end;
    end;

    EditSign.Locked.Visible = not v51;
    EditSign.Unlocked.Visible = v51;
    EditSign.ConfirmImage.Visible = v51;
end;

local function u90(p54) -- Line: 286
    -- upvalues: Codelock (copy), u2 (ref), InventoryController (copy), u30 (ref), Vegetation (copy), u13 (ref), u1 (copy), u14 (ref), Bases (copy), BenchInfo (copy), u28 (ref), Update (copy), u7 (ref), u26 (ref), u3 (ref), EquipController (copy), Items (copy), Parent (copy), RunService (copy), Humanoid (copy), NumberUtil (copy), Hover (copy), TweenUtil (copy), VFXModule (copy), Values (copy), RaycastUtil (copy), ActiveBenchModule (copy), WheelController (copy), u35 (ref), u9 (ref), u5 (ref), RenameBed (copy), u11 (ref), TextBox (copy), UserInputService (copy), FoundUser (copy), GiveBed (copy), TextBox2 (copy), u22 (ref), EditSign (copy), u53 (copy), Players (copy), u25 (ref), u6 (ref), u24 (ref)
    if Codelock.Visible or (not u2 or (not u2.Parent or (InventoryController:GetAttribute("Open") or script:GetAttribute("Dialog") and u30 == u2))) then
        return;
    end;

    local v55;

    if u2.Name == "DigPile" then
        v55 = u2.Parent == Vegetation;
    else
        v55 = false;
    end;

    if u2:IsA("Terrain") then
        if tick() - u13 < 2 then
            return;
        end;

        u13 = tick();
        u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\1e,\145\144\129\202\146\160i\135\184\226_\22\229u\156d\30", u2, u14);

        return;
    end;

    if v55 or u2:IsDescendantOf(Bases) then
        local v56 = BenchInfo[u2.Name];

        if v56 and (v56.Type == "ClanTable" and os.clock() - u28 >= 6) then
            u28 = os.clock();
            Update:Fire(u2);
        end;

        if u7 or not (v56 or v55) then
            return;
        end;

        local v57 = tick();

        if v57 - u26 < 0.125 then
            return;
        end;

        u26 = v57;
        local u58 = v55 and 10 or (v56.InteractDistance or script:GetAttribute("DefaultDistance"));
        u7 = true;
        local u59 = u2;
        u3 = u59;
        local v60;

        if v55 then
            v60 = u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "I6&\250\193\1455\135\18V\146\1\218\236\215\148v\248\235\147", "Start", u59);

            if not v60 then
                u7 = false;
                u3 = nil;

                return;
            end;
        else
            v60 = nil;
        end;

        local v61 = 0;
        local v62 = true;
        local v63 = nil;
        local v64 = InventoryController.Fetch:Invoke();
        local v65;

        if v64 then
            local Toolbar = v64.Toolbar;

            if Toolbar then
                v65 = Toolbar[EquipController:GetAttribute("Equipped")];

                if v65 == nil then
                    v65 = false;
                elseif v65 == 0 then
                    v65 = false;
                end;
            else
                v65 = nil;
            end;
        else
            v65 = nil;
        end;

        local v66 = false;

        if v65 and v65 ~= 0 then
            local v67 = Items[v65.ID];

            if v67 and (v67.MaxDurability == nil or v65.Durability and v65.Durability > 0) then
                local Name = v67.Name;

                if Name == "Steel Shovel" or Name == "Salvaged Shovel" then
                    v66 = Parent:FindFirstChild(Name);
                end;
            end;
        end;

        local v68 = nil;
        local v69 = 0;

        while v61 < (v60 or 0.4) do
            local v70 = RunService.Heartbeat:Wait();
            local v71 = u7 and (Parent and Parent.Parent and (Parent.PrimaryPart and Humanoid));

            if v71 then
                if Humanoid.Health > 0 then
                    v71 = u59 and u59.Parent and (v66 and v66.Parent or v66 == false);
                else
                    v71 = false;
                end;
            end;

            v68 = not v71;

            if v68 then
                break;
            end;

            local PrimaryPart = Parent.PrimaryPart;
            local PrimaryPart2 = u59.PrimaryPart;

            if InventoryController:GetAttribute("Open") or not NumberUtil:IsWithin(PrimaryPart.Position, PrimaryPart2.Position, u58) then
                v61 = 0;

                if v55 then
                    break;
                end;
            else
                v61 = v61 + v70;
            end;

            if v55 then
                if v62 then
                    Hover.Bar.Fill.Size = UDim2.new(0, 0, 1, 0);
                    TweenUtil:Tween(Hover.Bar.Fill, "Size", UDim2.new(1, 0, 1, 0), v60, "Sine", "In");
                    local v72 = u59:GetPivot();
                    script.Value.Value = v72;
                    v63 = TweenUtil:Tween(script.Value, "Value", v72 * CFrame.new(0, -0.75, 0), v60, "Quart", "In");
                    Hover.Bar.Visible = true;
                    PrimaryPart2.Smoke.Enabled = true;
                    script:SetAttribute("Digging", true);
                elseif v63 then
                    local Value = script.Value.Value;
                    u59:PivotTo(Value * CFrame.new(math.random(-10, 10) / 7 * v70, 0, math.random(-10, 10) / 7 * v70));

                    if v69 <= v61 then
                        v69 = v69 + 0.25;
                        task.defer(VFXModule.CreateGibs, VFXModule, "DigGibs", Value * CFrame.Angles(1.5707963267948966, 0, 0), 3, 3, 0.25, 60, 60, 60, 20, 25, true);
                    end;
                end;
            end;

            v62 = false;
        end;

        if v55 then
            u7 = false;
            u3 = nil;
            Hover.Bar.Visible = false;
            script:SetAttribute("Digging", false);

            if u59.Parent then
                u59.Dirt.Smoke.Enabled = false;

                if v63 then
                    v63:Cancel();
                end;

                if v68 or v61 == 0 then
                    u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "I6&\250\193\1455\135\18V\146\1\218\236\215\148v\248\235\147", "Cancel", u59);
                end;
            end;

            return;
        end;

        local v73 = u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u59, v61 >= 0.4 and 0 or 1);
        local v74 = v73 == "Rename Bed";
        local v75 = v73 == "Give To Friend";
        local v76 = v73 == "Edit Sign";
        local DemolishTimerMult = v56.DemolishTimerMult;

        if DemolishTimerMult and (u2 and (u2.PrimaryPart and v61 >= 0.4)) then
            local Value = Values.ServerTick.Value;
            local v77 = RaycastUtil:GetBaseCabinetUnder(u2.PrimaryPart.Position);

            if not (v77 and v77:GetAttribute("Monument")) then
                local v78 = ActiveBenchModule.GetClientInfo(v77);

                if not v78 or v78.Access ~= false then
                    v73 = v73 or {};
                    local v79;

                    if Value - (u2:GetAttribute("Placed") or Value - 0.01) < Values.DemolishTimer.Value * DemolishTimerMult then
                        v79 = Values.SimpleDemolish.Value;

                        if not v79 then
                            if v78 == nil then
                                v79 = false;
                            else
                                v79 = v78.Access;
                            end;
                        end;
                    else
                        v79 = false;
                    end;

                    local v80 = v79 and true or false;

                    if v79 then
                        for _, v in v73 do
                            if type(v) == "table" and v.SelectFirst then
                                v80 = false;
                                break;
                            end;
                        end;
                    end;

                    table.insert(v73, {
                        Image = "rbxassetid://13002666332",
                        Name = "Demolish",
                        Description = "Get rid of selected deployable.",
                        Selectable = v79,
                        SelectFirst = v80
                    });
                end;
            end;
        end;

        if type(v73) == "table" then
            task.defer(function() -- Line: 438
                -- upvalues: u7 (ref), Codelock (ref), u59 (copy), Parent (ref), Humanoid (ref), NumberUtil (ref), u58 (copy), WheelController (ref), u3 (ref), u35 (ref)
                while u7 or Codelock.Visible do
                    if not u59 or (not u59.Parent or (not Parent or (not Parent.Parent or (not Parent.PrimaryPart or (not Humanoid or (Humanoid.Health <= 0 or not NumberUtil:IsWithin(Parent.PrimaryPart.Position, u59.PrimaryPart.Position, u58))))))) then
                        WheelController.Close:Invoke("Bench");
                        u3 = nil;
                        break;
                    end;

                    task.wait();
                end;

                u35(false);
            end);
            local u81 = WheelController.Open:Invoke(v73, "Bench", true);
            local u82 = v73[u81];

            if u82 and u82.Name == "Rename Bed" then
                v74 = true;
                u7 = false;
                u3 = nil;
            elseif u82 and u82.Name == "Give To Friend" then
                v75 = true;
                u7 = false;
                u3 = nil;
            elseif u82 and u82.Name == "Edit Sign" then
                v76 = true;
                u7 = false;
                u3 = nil;
            elseif u82 and u82.Name == "Demolish" then
                u7 = false;
                u3 = nil;
                u1("Fire", "NM\182\1\154\155j\149\231\163\4\179F\180\232\247\208\7\221\217", "\223\155\187BG2\179\190\204\146\219\194<\1c\152\5\141:?", u59, 6);
            else
                task.defer(function() -- Line: 475
                    -- upvalues: u82 (copy), u59 (copy), u35 (ref), Codelock (ref), u7 (ref), u3 (ref), u81 (copy), u9 (ref), u1 (ref)
                    local v83;

                    if u82 and u82.Name:find("Combination") then
                        if not (u59 and u59.Parent) then
                            return;
                        end;

                        u35(true);
                        v83 = true;

                        while Codelock.Visible do
                            task.wait();
                        end;
                    else
                        v83 = false;
                    end;

                    local v84 = u7;
                    u7 = false;
                    u3 = nil;

                    if not (u81 and (u59 and u59.Parent)) then
                        return;
                    end;

                    if v83 and u9:len() == 5 then
                        u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u59, u81, u9);

                        return;
                    end;

                    if v84 then
                        u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u59, u81);
                    end;
                end);
            end;
        else
            u7 = false;
            u3 = nil;
        end;

        if v74 then
            u5 = u59;
            RenameBed.Rename.Visible = false;
            u11 = u59:GetAttribute("BedName") or "";
            TextBox.Text = u11;
            RenameBed.Visible = true;

            while UserInputService:IsKeyDown(p54) and RenameBed.Visible do
                task.wait();
            end;

            UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
            UserInputService.MouseIconEnabled = true;
            TextBox:CaptureFocus();

            return;
        end;

        if v75 then
            u5 = u59;
            FoundUser.Visible = false;
            GiveBed.Give.Visible = false;
            GiveBed.TextBox.Text = "";
            GiveBed.Visible = true;

            while UserInputService:IsKeyDown(p54) and GiveBed.Visible do
                task.wait();
            end;

            UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
            UserInputService.MouseIconEnabled = true;
            TextBox2:CaptureFocus();

            return;
        end;

        if v76 then
            local GuiReference = u59:FindFirstChild("GuiReference");
            local v85;

            if GuiReference == nil then
                v85 = false;
            else
                v85 = GuiReference.Value;
            end;

            u22 = u59:GetAttribute("MaxCharacters");

            if typeof(v85) == "Instance" and (v85.Parent and u22) then
                u5 = u59;

                if v85.TextLabel.Visible then
                    EditSign.TextBox.Text = v85.TextLabel.Text;
                    EditSign.Unlocked.Selected.Image = "";
                    EditSign.Unlocked.TextBox.Text = "";
                else
                    EditSign.TextBox.Text = "";
                    local v86 = v85.ImageLabel.Image:gsub("%D", "");
                    local v87 = tonumber(v86);
                    EditSign.Unlocked.Selected.Image = v87 and ("rbxassetid://" .. v87 or "") or "";
                    EditSign.Unlocked.TextBox.Text = v87 and tostring(v87) or "";
                end;

                u53();
                EditSign.Visible = true;

                while UserInputService:IsKeyDown(p54) and EditSign.Visible do
                    task.wait();
                end;

                UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
                UserInputService.MouseIconEnabled = true;
            end;
        end;
    else
        if Players:FindFirstChild(u2.Name) then
            local Character = Players[u2.Name].Character;

            if not Character and (not Character.Humanoid and Character.Humanoid.Health <= 0) then
                return;
            end;

            if not Character.Humanoid:GetAttribute("Downed") then
                if tick() - u6 <= 2 then
                    return;
                end;

                u6 = tick();
                u1("Fire", "\1\1401\200\176V\254\208\146<o*\1271=\30D\166cI", "\0086X\151o\242\18+\245J\208\246\243\136\196K)T\148\1", "Invite", Players[u2.Name].UserId);

                return;
            end;

            local v88 = tick();

            if v88 - u25 < 0.2 then
                return;
            end;

            u25 = v88;
            script:SetAttribute("Reviving", true);
            script:SetAttribute("ReviveStart", v88);
            u1("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "1.@\193\221\240|\153W;/\151m\14\\smV\1\182", Character);
            task.delay(4, function() -- Line: 576
                if script:GetAttribute("Reviving") then
                    if tick() - script:GetAttribute("ReviveStart") < 4 then
                        return;
                    end;

                    script:SetAttribute("Reviving", false);
                end;
            end);

            return;
        end;

        local v89 = tick();

        if v89 - u24 < 0.15 then
            return;
        end;

        u24 = v89;
        u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "c\\\180\217\177\1\135\237\3\5e\206\252\26\212}+ZBT", u2);
    end;
end;

local function u91() -- Line: 603
    -- upvalues: u7 (ref), WheelController (copy), u1 (copy)
    u7 = false;
    WheelController.Close:Invoke("Bench");

    if script:GetAttribute("Reviving") then
        script:SetAttribute("Reviving", false);
        u1(
            "Fire",
            "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145",
            "1.@\193\221\240|\153W;/\151m\14\\smV\1\182",
            false
        );
    end;
end;

local function u96() -- Line: 615
    -- upvalues: EquipController (copy), InventoryController (copy), u2 (ref), Items (copy), u1 (copy), OpenBench (copy)
    local v92 = EquipController:GetAttribute("Equipped");
    local v93 = InventoryController.Fetch:Invoke();
    local v94;

    if v93 then
        local Toolbar = v93.Toolbar;

        if Toolbar then
            v94 = Toolbar[v92 or EquipController:GetAttribute("Equipped")];

            if v94 == nil then
                v94 = false;
            elseif v94 == 0 then
                v94 = false;
            end;
        else
            v94 = nil;
        end;
    else
        v94 = nil;
    end;

    if not u2 or (not u2.Parent or (not v94 or v94.Amount <= 0)) then
        return;
    end;

    local v95 = Items[v94.ID];

    if not v95 then
        return;
    end;

    local Type = v95.Type;

    if Type == "Lock" then
        u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\236\136\167\229\28\236\1\218\17\222\134\26\214\187\152\"\217\147\186\16", u2, v92);

        return;
    end;

    if Type == "Tool" and (v94.ID == 326 and shared.CachedConnections[u2] ~= nil) then
        OpenBench:Fire(u2);
    end;
end;

local function v101(p97, p98, p99) -- Line: 632
    local Lock = p98:FindFirstChild("Lock", true);

    if not Lock then
        return;
    end;

    local v100 = false;

    for _, child in pairs(Lock:GetChildren()) do
        if child:GetAttribute("On") then
            v100 = true;
            break;
        end;
    end;

    if v100 then
        return;
    end;

    for _, child in pairs(Lock:GetChildren()) do
        for _, child2 in pairs(child:GetChildren()) do
            if child2:IsA("BasePart") then
                child2.Color = Color3.fromRGB(0, 113, 165);
                child2.Transparency = child.Name == p99 and 0 or 1;
            end;
        end;
    end;
end;

local function u103(...) -- Line: 651
    -- upvalues: u27 (ref), u1 (copy)
    local v102 = tick();

    if v102 - u27 >= 0.2 then
        u27 = v102;
        u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", ...);

        return true;
    end;
end;

local function u115(p104, p105, p106, p107) -- Line: 659
    -- upvalues: u31 (ref), u29 (ref), u30 (ref), HumanoidRootPart (copy), NumberUtil (copy), u115 (ref), Dialogue (copy)
    u31 = p105;
    u29 = p106;
    u30 = p107;
    task.defer(function() -- Line: 663
        -- upvalues: u31 (ref), u30 (ref), HumanoidRootPart (ref), NumberUtil (ref), u115 (ref)
        script:SetAttribute("Dialog", u31 ~= nil);

        if not u30 then
            return;
        end;

        local v108 = u30;

        while v108.Parent and (v108 == u30 and (HumanoidRootPart.Parent and u30.PrimaryPart)) do
            if not NumberUtil:IsWithin(HumanoidRootPart.Position, u30.PrimaryPart.Position, 12) then
                u115();

                return;
            end;

            task.wait(0.1);
        end;
    end);

    if not u31 then
        Dialogue.Frame:TweenPosition(UDim2.new(0, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.1, true);
        task.wait(0.41);

        if Dialogue.Frame.Position ~= UDim2.new(0, 0, 1, 0) then
            return;
        end;

        Dialogue.Visible = false;

        return;
    end;

    local Text = p105.Text;
    local Options = p105.Options;

    if not u31 then
        Dialogue.Frame.Position = UDim2.new(0, 0, 1, 0);
    end;

    Dialogue.Frame.NPCName.Text = p104:upper();
    local v109 = 0;

    while true do
        v109 = v109 + 1;
        local v110 = Dialogue.Frame:FindFirstChild((`Option{v109}`));

        if not v110 then
            break;
        end;

        v110.Visible = false;
    end;

    for i, v in Options do
        local v111 = Dialogue.Frame[`Option{i}`];
        v111.Text = `[{i}] {v.Text}`;
        local v112;

        if v.Color == 1 then
            v112 = Color3.fromRGB(123, 255, 0);
        else
            v112 = Color3.fromRGB(255, 55, 55);
        end;

        v111.TextColor3 = v112;
        v111.Visible = true;
    end;

    Dialogue.Frame.Dialog.Text = "";
    Dialogue.Visible = true;
    Dialogue.Frame:TweenPosition(UDim2.new(0, 0, #Options == 1 and 0.31 or 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true);
    task.wait(0.3);
    local v113 = "";

    for i = 1, Text:len() do
        if Dialogue.Frame.Dialog.Text ~= v113 or not u31 then
            break;
        end;

        local v114 = Text:sub(i, i);
        v113 = v113 .. v114;
        Dialogue.Frame.Dialog.Text = v113;
        task.wait(v114 == "," and 0.2 or ((v114 == "!" or (v114 == "?" or v114 == ".")) and 0.25 or 0.016666666666666666));
    end;
end;

UserInputService.InputBegan:Connect(function(p116, p117) -- Line: 720
    -- upvalues: SettingsModule (copy), UserInputService (copy), u90 (copy), Codelock (copy), u35 (ref), u10 (copy), u48 (copy), u31 (ref), u30 (ref), u115 (ref), u1 (copy), u29 (ref), u96 (copy), InventoryController (copy), u20 (copy), u16 (ref), u17 (ref), u19 (ref), u21 (ref), Controls (copy), GamepadIconModule (copy)
    if SettingsModule.MainMenuOpen() then
        return;
    end;

    local UserInputType = p116.UserInputType;

    if UserInputService:GetFocusedTextBox() then
        return;
    end;

    if UserInputType == Enum.UserInputType.Keyboard then
        local KeyCode = p116.KeyCode;

        if KeyCode.Name == SettingsModule.GetSetting("Controls", "Interact") and not p117 then
            u90(KeyCode);

            return;
        end;

        if KeyCode.Name == SettingsModule.GetSetting("Controls", "Open Inventory") and Codelock.Visible then
            u35(false);

            return;
        end;

        if Codelock.Visible then
            local v118 = u10[KeyCode.Name];

            if not v118 then
                return;
            end;

            u48(v118);

            return;
        end;

        if KeyCode == Enum.KeyCode.One or (KeyCode == Enum.KeyCode.Two or KeyCode == Enum.KeyCode.Three) then
            if not (u31 and (u30 and u30.Parent)) then
                return;
            end;

            local v119 = KeyCode == Enum.KeyCode.One and 1 or (KeyCode == Enum.KeyCode.Two and 2 or 3);
            local v120 = u31.Options[v119];

            if not v120 then
                return;
            end;

            if v120.Action == "Close" then
                u115();

                return;
            end;

            u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "oG\231\173\0190n2\7\239\131\1w\215\1305\202\14\253\178", u30, u29, v119);
        end;
    else
        if UserInputType == Enum.UserInputType.MouseButton1 and not p117 then
            u96();

            return;
        end;

        if UserInputType == Enum.UserInputType.Gamepad1 then
            local KeyCode = p116.KeyCode;
            local v121 = InventoryController:GetAttribute("Open");

            if u31 and (u30 and u30.Parent) then
                local Options = u31.Options;
                local v122 = #Options;
                local v123 = nil;

                if v122 >= 3 then
                    v123 = KeyCode == Enum.KeyCode.ButtonY and 1 or (KeyCode == Enum.KeyCode.ButtonX and 2 or (KeyCode == Enum.KeyCode.ButtonB and 3 or nil));
                elseif v122 >= 2 then
                    v123 = KeyCode == Enum.KeyCode.ButtonX and 1 or (KeyCode == Enum.KeyCode.ButtonB and 2 or nil);
                end;

                if v123 then
                    local v124 = Options[v123];

                    if not v124 then
                        return;
                    end;

                    if v124.Action == "Close" then
                        u115();

                        return;
                    end;

                    u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "oG\231\173\0190n2\7\239\131\1w\215\1305\202\14\253\178", u30, u29, v123);

                    return;
                end;
            end;

            if Codelock.Visible then
                if KeyCode == Enum.KeyCode.ButtonB then
                    u35(false);

                    return;
                end;

                if KeyCode == Enum.KeyCode.ButtonA then
                    local v125 = u20[u16] and u20[u16][u17];

                    if v125 then
                        u48(v125);

                        return;
                    end;
                elseif KeyCode == Enum.KeyCode.DPadRight then
                    if os.clock() - u19 < 0.15 then
                        return;
                    end;

                    u19 = os.clock();
                    u17 = u17 % 3 + 1;

                    if not u21 then
                        return;
                    end;

                    local v126 = u20[u16] and u20[u16][u17];

                    if not v126 then
                        return;
                    end;

                    local v127 = Controls.Keys:FindFirstChild(v126);

                    if v127 then
                        u21.Parent = v127;
                        u21.Visible = true;
                        u21.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");

                        return;
                    end;
                elseif KeyCode == Enum.KeyCode.DPadLeft then
                    if os.clock() - u19 < 0.15 then
                        return;
                    end;

                    u19 = os.clock();
                    u17 = (u17 - 2) % 3 + 1;

                    if not u21 then
                        return;
                    end;

                    local v128 = u20[u16] and u20[u16][u17];

                    if not v128 then
                        return;
                    end;

                    local v129 = Controls.Keys:FindFirstChild(v128);

                    if v129 then
                        u21.Parent = v129;
                        u21.Visible = true;
                        u21.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");

                        return;
                    end;
                elseif KeyCode == Enum.KeyCode.DPadDown then
                    if os.clock() - u19 < 0.15 then
                        return;
                    end;

                    u19 = os.clock();
                    u16 = u16 % 4 + 1;

                    if not u21 then
                        return;
                    end;

                    local v130 = u20[u16] and u20[u16][u17];

                    if not v130 then
                        return;
                    end;

                    local v131 = Controls.Keys:FindFirstChild(v130);

                    if v131 then
                        u21.Parent = v131;
                        u21.Visible = true;
                        u21.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");

                        return;
                    end;
                elseif KeyCode == Enum.KeyCode.DPadUp then
                    if os.clock() - u19 < 0.15 then
                        return;
                    end;

                    u19 = os.clock();
                    u16 = (u16 - 2) % 4 + 1;

                    if not u21 then
                        return;
                    end;

                    local v132 = u20[u16] and u20[u16][u17];

                    if not v132 then
                        return;
                    end;

                    local v133 = Controls.Keys:FindFirstChild(v132);

                    if v133 then
                        u21.Parent = v133;
                        u21.Visible = true;
                        u21.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
                    end;
                end;

                return;
            end;

            if KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Interact/Reload") and not (p117 or v121) then
                u90(KeyCode);

                return;
            end;

            if KeyCode == Enum.KeyCode.ButtonR2 and not v121 then
                u96();
            end;
        end;
    end;
end);
UserInputService.InputChanged:Connect(function(p134) -- Line: 819
    -- upvalues: Codelock (copy), PreferredInputController (copy), u18 (ref), u17 (ref), u16 (ref), u21 (ref), u20 (copy), Controls (copy), GamepadIconModule (copy)
    if not Codelock.Visible then
        return;
    end;

    if p134.UserInputType ~= Enum.UserInputType.Gamepad1 then
        return;
    end;

    if p134.KeyCode ~= Enum.KeyCode.Thumbstick1 then
        return;
    end;

    local X = p134.Position.X;
    local Y = p134.Position.Y;
    local v135 = PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225;

    if v135 < math.abs(X) or v135 < math.abs(Y) then
        if not u18 then
            u18 = true;

            if v135 < X then
                u17 = u17 % 3 + 1;
            elseif X < -v135 then
                u17 = (u17 - 2) % 3 + 1;
            end;

            if Y < -v135 then
                u16 = u16 % 4 + 1;
            elseif v135 < Y then
                u16 = (u16 - 2) % 4 + 1;
            end;

            if not u21 then
                return;
            end;

            local v136 = u20[u16] and u20[u16][u17];

            if not v136 then
                return;
            end;

            local v137 = Controls.Keys:FindFirstChild(v136);

            if v137 then
                u21.Parent = v137;
                u21.Visible = true;
                u21.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
            end;
        end;
    else
        u18 = false;
    end;
end);
PreferredInputController:GetAttributeChangedSignal("PreferredInput"):Connect(function() -- Line: 849
    -- upvalues: Codelock (copy), PreferredInputController (copy), u21 (ref), u20 (copy), u16 (ref), u17 (ref), Controls (copy), GamepadIconModule (copy)
    if not Codelock.Visible then
        return;
    end;

    local v138 = PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
    Codelock.GamepadControls.Visible = v138;

    if v138 then
        if not u21 then
            return;
        end;

        local v139 = u20[u16] and u20[u16][u17];

        if not v139 then
            return;
        end;

        local v140 = Controls.Keys:FindFirstChild(v139);

        if v140 then
            u21.Parent = v140;
            u21.Visible = true;
            u21.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
        end;
    elseif u21 then
        u21.Visible = false;
    end;
end);
UserInputService.InputEnded:Connect(function(p141, p142) -- Line: 859
    -- upvalues: UserInputService (copy), SettingsModule (copy), u91 (copy), InventoryController (copy)
    local UserInputType = p141.UserInputType;

    if UserInputService:GetFocusedTextBox() or p142 then
        return;
    end;

    if UserInputType == Enum.UserInputType.Keyboard then
        if p141.KeyCode.Name == SettingsModule.GetSetting("Controls", "Interact") then
            u91();
        end;
    elseif UserInputType == Enum.UserInputType.Gamepad1 then
        local Name = p141.KeyCode.Name;
        local v143 = InventoryController:GetAttribute("Open");

        if Name == SettingsModule.GetSetting("Gamepad", "Interact/Reload") and not v143 then
            u91();
        end;
    end;
end);
TextBox.FocusLost:Connect(function() -- Line: 877
    -- upvalues: u1 (copy), TextBox (copy), u11 (ref), RenameBed (copy), UserInputService (copy)
    shared.LastTextBoxFocused = tick();
    local v144 = u1("Fire", "\156\2I=\144i\181\249\200\249\198Q\20\205\1431\142\1\1391", "\195\146\r\1\200W\130\240\0156\249P<\199\239U\252\177V\153", TextBox.Text:sub(1, 20)) or "";
    u11 = v144;
    TextBox.Text = v144;
    RenameBed.Rename.Visible = true;
    task.wait();

    if not RenameBed.Visible then
        return;
    end;

    UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
    UserInputService.MouseIconEnabled = true;
end);
TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 891
    -- upvalues: TextBox (copy), u11 (ref), RenameBed (copy)
    TextBox.Text = TextBox.Text:sub(1, 20):gsub("/", ""):gsub("`", ""):gsub("\\", "");
    local Text = TextBox.Text;

    if Text:len() <= 0 or Text ~= u11 then
        RenameBed.Rename.Visible = false;
        TextBox.Text = Text;
        u11 = Text;
    end;
end);
ButtonClass.new(RenameBed.Cancel, "BackgroundColor3", function() -- Line: 900
    -- upvalues: u5 (ref), UserInputService (copy), RenameBed (copy)
    task.wait();
    u5 = nil;
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    RenameBed.Visible = false;
end, 1.5);
ButtonClass.new(RenameBed.Rename, "BackgroundColor3", function() -- Line: 907
    -- upvalues: UserInputService (copy), RenameBed (copy), u5 (ref), u103 (copy), TextBox (copy)
    task.wait();
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    RenameBed.Visible = false;

    if u5 and u5.Parent then
        u103(u5, "Rename Bed", TextBox.Text);

        return;
    end;

    u5 = nil;
end, 1.5);
TextBox2.FocusLost:Connect(function() -- Line: 923
    -- upvalues: FoundUser (copy), GiveBed (copy), TextBox2 (copy), Players (copy), u12 (ref), UserService (copy), LocalPlayer (copy), UserInputService (copy)
    shared.LastTextBoxFocused = tick();
    FoundUser.Visible = false;
    GiveBed.Give.Visible = false;
    local Text = TextBox2.Text;
    local u145 = tonumber(Text);

    if not u145 then
        local success, _ = pcall(function() -- Line: 930
            -- upvalues: u145 (ref), Players (ref), Text (copy)
            u145 = Players:GetUserIdFromNameAsync(Text);
        end);

        if not (success and u145) then
            return;
        end;
    end;

    if u145 == u12 then
        FoundUser.Visible = true;
        GiveBed.Give.Visible = true;

        return;
    end;

    local success, result = pcall(function() -- Line: 941
        -- upvalues: UserService (ref), u145 (ref)
        return UserService:GetUserInfosByUserIdsAsync({ u145 });
    end);

    if not success then
        return;
    end;

    for _, v in pairs(result) do
        u12 = v.Id;
        FoundUser.DispName.Text = `{v.DisplayName}{not v.HasVerifiedBadge and "" or utf8.char(57344)}`;
        FoundUser.UserName.Text = "@" .. v.Username;
        FoundUser.UserID.Text = "ID: " .. v.Id;
        local v146 = LocalPlayer:IsFriendsWith(v.Id);
        FoundUser.IsFriend.Text = v146 and "YES" or "NO";
        FoundUser.IsFriend.TextColor3 = FoundUser.IsFriend:GetAttribute("Color" .. (v146 and "Yes" or "No"));
        FoundUser.Visible = true;
        GiveBed.Give.Visible = true;
        local success2, result2 = pcall(function() -- Line: 955
            -- upvalues: Players (ref), v (copy)
            return Players:GetUserThumbnailAsync(v.Id, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420);
        end);
        FoundUser.Avatar.Image = success2 and result2 and result2 or "";
        break;
    end;

    if not GiveBed.Visible then
        return;
    end;

    UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
    UserInputService.MouseIconEnabled = true;
end);
TextBox2:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 966
    -- upvalues: TextBox2 (copy)
    local Text = TextBox2.Text;
    local v147 = "";

    for i = 1, Text:len() do
        local v148 = Text:sub(i, i);
        local v149 = v148:byte();

        if v149 == 32 or v149 >= 48 and v149 <= 57 or (v149 >= 65 and v149 <= 90 or (v149 == 95 or v149 >= 97 and v149 <= 122)) then
            v147 = v147 .. v148;
        end;
    end;

    TextBox2.Text = v147;
end);
ButtonClass.new(GiveBed.Cancel, "BackgroundColor3", function() -- Line: 978
    -- upvalues: u5 (ref), UserInputService (copy), GiveBed (copy)
    task.wait();
    u5 = nil;
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    GiveBed.Visible = false;
end, 1.5);
ButtonClass.new(GiveBed.Give, "BackgroundColor3", function() -- Line: 985
    -- upvalues: UserInputService (copy), GiveBed (copy), u5 (ref), u103 (copy), u12 (ref)
    task.wait();
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    GiveBed.Visible = false;

    if u5 and u5.Parent then
        u103(u5, "Give To Friend", u12);

        return;
    end;

    u5 = nil;
end, 1.5);
ButtonClass.new(EditSign.Cancel, "BackgroundColor3", function() -- Line: 1001
    -- upvalues: u5 (ref), UserInputService (copy), EditSign (copy)
    u5 = nil;
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    EditSign.Visible = false;
end, 1.5);
EditSign.TextBox.FocusLost:Connect(function() -- Line: 1008
    -- upvalues: u1 (copy), EditSign (copy), u22 (ref)
    shared.LastTextBoxFocused = tick();
    local v150 = u1("Fire", "\156\2I=\144i\181\249\200\249\198Q\20\205\1431\142\1\1391", "\195\146\r\1\200W\130\240\0156\249P<\199\239U\252\177V\153", EditSign.TextBox.Text:sub(1, u22));
    EditSign.TextBox.Text = v150 or "";
end);
EditSign.TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 1015
    -- upvalues: u22 (ref), EditSign (copy)
    if not u22 then
        return;
    end;

    local v151 = EditSign.TextBox.Text:sub(1, u22):gsub("`", "");
    EditSign.TextBox.Text = v151;
    EditSign.CharLimit.Text = #v151 .. "/" .. u22;
end);
EditSign.Unlocked.TextBox.FocusLost:Connect(function() -- Line: 1021
    -- upvalues: EditSign (copy), u23 (copy), ReplicatedStorage (copy)
    shared.LastTextBoxFocused = tick();

    if EditSign.Unlocked.Applying.Visible then
        return;
    end;

    EditSign.Unlocked.Applying.Visible = true;
    local Text = EditSign.Unlocked.TextBox.Text;
    local v152 = u23[Text];

    if not v152 then
        local v153 = ReplicatedStorage.Ping:InvokeServer("Image", Text);
        v152 = (v153 == 0 or v153 == "0") and "nil" or v153;

        if v152 then
            if v152 == "nil" then
                u23[Text] = Text;
                v152 = Text;
            else
                u23[Text] = tostring(v152);
            end;
        end;
    end;

    if v152 then
        local v154 = tostring(v152);
        Text = v154 == "0" and "" or v154;
        EditSign.Unlocked.TextBox.Text = Text;
    end;

    EditSign.Unlocked.Selected.Image = Text == "" and "" or ("rbxassetid://" .. Text or "");
    EditSign.Unlocked.Applying.Visible = false;
end);
EditSign.Unlocked.TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 1050
    -- upvalues: u22 (ref), EditSign (copy)
    if not u22 then
        return;
    end;

    EditSign.Unlocked.TextBox.Text = EditSign.Unlocked.TextBox.Text:sub(1, 30):gsub("%D", "");
end);
ButtonClass.new(EditSign.Locked.Buy, "BackgroundColor3", function() -- Line: 1054
    -- upvalues: MarketplaceService (copy), LocalPlayer (copy)
    local success, result = pcall(function() -- Line: 1055
        -- upvalues: MarketplaceService (ref), LocalPlayer (ref)
        MarketplaceService:PromptGamePassPurchase(LocalPlayer, 667425168);
    end);

    if not success then
        warn(result);
    end;
end, 1.5);
ButtonClass.new(EditSign.ConfirmText, "BackgroundColor3", function() -- Line: 1062
    -- upvalues: UserInputService (copy), EditSign (copy), u5 (ref), u103 (copy)
    task.wait();
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    EditSign.Visible = false;

    if u5 and u5.Parent then
        u103(u5, "Edit Sign", EditSign.TextBox.Text);

        return;
    end;

    u5 = nil;
end, 1.5);
ButtonClass.new(EditSign.ConfirmImage, "BackgroundColor3", function() -- Line: 1077
    -- upvalues: UserInputService (copy), EditSign (copy), u5 (ref), u103 (copy)
    task.wait();
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    EditSign.Visible = false;

    if u5 and u5.Parent then
        u103(u5, "Edit Sign", tonumber(EditSign.Unlocked.TextBox.Text) or 0);

        return;
    end;

    u5 = nil;
end, 1.5);
ReplicatedStorage:GetAttributeChangedSignal("LabelsOwned"):Connect(u53);
u1("Setup", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "oG\231\173\0190n2\7\239\131\1w\215\1305\202\14\253\178", u115);

function GetSelected.OnInvoke() -- Line: 1098
    -- upvalues: u2 (ref)
    return u2;
end;

for _, descendant in pairs(Info:GetDescendants()) do
    if descendant:IsA("GuiObject") then
        local v155 = descendant:IsA("Frame") and { "BackgroundTransparency" } or (descendant:IsA("ImageLabel") and { "ImageTransparency" } or { "TextTransparency", "TextStrokeTransparency" });
        local v156 = {};

        for i, v in pairs(v155) do
            v156[i] = descendant[v];
        end;

        v8[descendant.Name] = {
            Properties = v155,
            Values = v156
        };
    end;
end;

for _, child in pairs(Controls.Keys:GetChildren()) do
    local Name = child.Name;
    ButtonClass.new(child, "BackgroundColor3", function() -- Line: 1118
        -- upvalues: u48 (copy), Name (copy)
        u48(Name);
    end, 1.3, 1.3);
end;

local v157 = "E";
local v158 = "MB2";
local v159 = 0;

while true do
    local v160, v161;

    if true then
        v160 = task.wait(0.05);

        if PreferredInputController then
            v161 = PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
        else
            v161 = PreferredInputController;
        end;
    end;

    v159 = v159 - v160;

    if v159 <= 0 then
        v157 = SettingsModule.GetSetting("Controls", "Interact");
        v158 = SettingsModule.GetSetting("Controls", "Change Building");
        v159 = 5;
    end;

    local v162 = InventoryController.Fetch:Invoke();
    local v163;

    if v162 then
        local Toolbar = v162.Toolbar;

        if Toolbar then
            v163 = Toolbar[EquipController:GetAttribute("Equipped")];

            if v163 == nil then
                v163 = false;
            elseif v163 == 0 then
                v163 = false;
            end;
        else
            v163 = nil;
        end;
    else
        v163 = nil;
    end;

    local v164;

    if v163 then
        v164 = Items[v163.ID];
    else
        v164 = v163;
    end;

    local v165;

    if v164 then
        v165 = v164.Name;
    else
        v165 = v164;
    end;

    if v164 then
        v164 = v164.Type;
    end;

    if v163 then
        v163 = v163.ID == 31;
    end;

    local v166 = false;
    local v167 = u2;
    local v168 = nil;
    local v169 = false;
    local v170 = false;
    local v171;

    if Parent and (Parent.Parent and (Parent.PrimaryPart and (Humanoid and (Humanoid.Parent and Humanoid.Health > 0)))) then
        local SeatPart = Humanoid.SeatPart;

        if SeatPart and (SeatPart.Parent and (SeatPart.Name == "VehicleSeat" and (not CameraController:GetAttribute("ViewmodelCFrame") and SeatPart:FindFirstAncestor("Salvaged Flycopter")))) then
            v171 = v168;
        else
            local CFrame2 = CurrentCamera.CFrame;
            local v172, v173, _, _ = RaycastUtil:Raycast(CFrame2.Position, CFrame2.LookVector * 30, "Blacklist", { VFX, Parent }, false, RaycastUtil:FilterFunction("HitNoMeleeMouse"), true);
            u14 = v173;
            local v174 = nil;

            if v172 and v172.Parent then
                local Parent2 = v172.Parent;
                local v175 = (Parent2.Parent == Drops or (Parent2.Parent == Plants or Parent2.Parent == game)) and Parent2 and Parent2 or Parent2.Parent;
                local v176 = Parent2:GetAttribute("Health");

                if (v175.Parent == Drops or v175.Parent == Plants) and (v175:IsA("Model") and v175.PrimaryPart) then
                    v174 = v175.PrimaryPart;
                elseif Parent2:IsDescendantOf(Bases) then
                    if not v176 then
                        Parent2 = Parent2.Parent;
                    end;

                    local v177 = Parent2:GetAttribute("Health");
                    local v178 = Parent2:GetAttribute("MaxHealth");
                    local v179 = BenchInfo[Parent2.Name];

                    if v177 and (v178 and (v179 == nil or (v179.Type == "Vehicle" or (v179.DisplayHealthOnly == false or (v163 or v177 <= v178 * 0.75))))) then
                        v174 = Parent2.PrimaryPart;
                    end;
                elseif Parent2:IsDescendantOf(Animals) then
                    if v176 then
                        v174 = Parent2.PrimaryPart;
                    else
                        local Parent3 = Parent2.Parent;

                        if Parent3:GetAttribute("Health") then
                            v174 = Parent3.PrimaryPart;
                        end;
                    end;
                elseif Parent2.Name == "DigPile" and Parent2.Parent == Vegetation then
                    v174 = Parent2.PrimaryPart;
                    v170 = true;
                elseif Parent2:FindFirstChild("Humanoid") and (Parent2.Humanoid.Health > 0 and Parent2.Humanoid:GetAttribute("Downed")) then
                    v174 = Parent2.PrimaryPart;
                elseif TeamNavigationController:GetAttribute("InTeam") and TeamNavigationController:GetAttribute("CanInvite") then
                    local v180 = Players:GetPlayerFromCharacter(Parent2);

                    if v180 and v180 ~= LocalPlayer then
                        local v181 = false;

                        for _, v in FetchTeam:Invoke() or {} do
                            if v == v180.UserId or tonumber(v) == v180.UserId then
                                v181 = true;
                            end;
                        end;

                        if not v181 then
                            v174 = Parent2.PrimaryPart;
                        end;
                    end;
                end;
            end;

            if v174 then
                v171 = v168;
            else
                local v182, v183, v184;
                v171, v182, v183, v184 = RaycastUtil:Raycast(CFrame2.Position, CFrame2.LookVector * 8, "Blacklist", { VFX, Parent }, false, RaycastUtil:FilterFunction("HitNoMeleeMouse"));
                u14 = v182;

                if v171 and (v171:IsA("Terrain") and (v184 == Enum.Material.Water and not WaterController:GetAttribute("IsSwim"))) then
                    if u14.Y <= 0.01 then
                        v169 = true;
                    else
                        v169 = false;
                    end;
                else
                    v171 = v168;
                end;
            end;

            if v174 then
                v171 = v174.Parent;
            end;
        end;
    else
        v171 = v168;
    end;

    local v185 = InventoryController.GetBench:Invoke();

    if v185 and v185.Parent then
        v171 = v185;
    else
        if v4 ~= v185 then
            u3 = nil;
        end;

        if InventoryController:GetAttribute("Open") then
            if v167 and v167.Parent then
                v171 = v167;
            else
                v171 = nil;
            end;
        elseif u3 and u3.Parent then
            v171 = u3;
        end;
    end;

    if v171 then
        local PrimaryPart = Parent.PrimaryPart;

        if PrimaryPart and (not v171:IsA("Model") or v171.PrimaryPart) then
            local v186 = BenchInfo[v171.Name];
            local v187 = v170 and 10 or (v186 and v171.Parent ~= Drops and v186.InteractDistance or script:GetAttribute((v171:IsDescendantOf(Animals) and "Animal" or "Default") .. "Distance"));
            v166 = NumberUtil:IsWithin(v171:IsA("Terrain") and u14 or v171.PrimaryPart.Position, PrimaryPart.Position, v187);
        end;
    end;

    if v166 then
        u2 = v171;
    else
        u2 = nil;
    end;

    if u2 ~= v167 then
        TweenUtil:Tween(Hover, "ImageTransparency", 1, 0.3, "Quart", "In");
        TweenUtil:Tween(Hover.Action, "TextTransparency", 1, 0.3, "Quart", "In");
        Interaction.Visible = false;

        if v167 and v167.Parent then
            local SelectedHighlight = v167:FindFirstChild("SelectedHighlight");
            v167:GetAttribute("Stability");

            if SelectedHighlight then
                SelectedHighlight.DepthMode = Enum.HighlightDepthMode.Occluded;
                SelectedHighlight:SetAttribute("Vis", false);
                TweenUtil:Tween(SelectedHighlight, { "FillTransparency", "OutlineTransparency" }, { 1, 1 }, 0.3, "Quart", "In");
                task.delay(0.31, function() -- Line: 1281
                    -- upvalues: SelectedHighlight (copy)
                    if not SelectedHighlight or (not SelectedHighlight.Parent or SelectedHighlight:GetAttribute("Vis")) then
                        return;
                    end;

                    SelectedHighlight:Destroy();
                end);
            end;

            local Info2 = v167:FindFirstChild("Info");

            if Info2 then
                for i, v in pairs(v8) do
                    local v188 = Info2:FindFirstChild(i, true);

                    if v188 then
                        TweenUtil:Tween(v188, v.Properties, table.create(#v.Values, 1), 0.3, "Quart", "In");
                    end;
                end;

                TweenUtil:Tween(Info2, "StudsOffset", Info2:GetAttribute("OrigOffset") or Vector3.new(), 0.3, "Quart", "In");
                task.delay(0.31, function() -- Line: 1294
                    -- upvalues: Info2 (copy)
                    if not Info2 or (not Info2.Parent or (not Info2:FindFirstChild("NameLabel") or Info2.NameLabel.TextTransparency < 0.99)) then
                        return;
                    end;

                    Info2:Destroy();
                end);
            end;

            v101(v164, v167);
        end;

        if not u2 then
            PowerThroughput.Visible = false;
        end;
    end;

    if u2 then
        if u2:IsA("Terrain") or v170 then
            local v189 = v170 and "DIG UP PILE" or "DRINK WATER";
            Hover.Action.Text = v169 and "SALT WATER" or (v161 and "   " or "[E] ") .. v189;
            Hover.Image = script:GetAttribute((v169 and "Unavailable" or "Default") .. "DotImage");
            local v190 = v161 and not v169 and not (InventoryController:GetAttribute("Open") or WheelController:GetAttribute("Open")) and not Codelock.Visible;
            Interaction.Visible = v190;

            if v190 then
                Interaction.xtra.ImageLabel.Image = UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonX);
                Interaction.xtra.Text = " - " .. v189;
            end;

            if v167 ~= u2 then
                TweenUtil:Tween(Hover, "ImageTransparency", 0, 0.2, "Quart", "Out");
                TweenUtil:Tween(Hover.Action, "TextTransparency", 0, 0.2, "Quart", "Out");
            end;
        else
            local v191 = BenchInfo[u2.Name];
            local v192;

            if u2 == nil then
                v192 = false;
            else
                v192 = u2.Parent == Drops;
            end;

            local v193;

            if u2 == nil then
                v193 = false;
            else
                v193 = u2.Parent == Plants;
            end;

            local v194;

            if u2 == nil then
                v194 = false;
            else
                v194 = u2.Parent == Animals;
            end;

            local v195;

            if u2 == nil then
                v195 = false;
            else
                v195 = Players:GetPlayerFromCharacter(u2) and not v194;
            end;

            local v196;

            if u2 == nil then
                v196 = false;
            else
                v196 = v192 and Vector3.new() or (v191 and v191.GuiOffset or Vector3.new());
            end;

            local Info2 = u2:FindFirstChild("Info");
            local v197 = u2:GetAttribute("Health");
            local v198 = u2:GetAttribute("MaxHealth");
            local v199 = u2:GetAttribute("Stability");
            local v200 = u2:GetAttribute("StabilityLoss");
            local SelectedHighlight = u2:FindFirstChild("SelectedHighlight");
            local Humanoid2 = u2:FindFirstChild("Humanoid");
            local v201 = not v195 and Humanoid2;
            local v202 = RaycastUtil:GetBaseCabinetUnder(u2.PrimaryPart.Position);
            local v203;

            if v202 then
                v203 = v202:GetAttribute("Monument");

                if not v203 then
                    local v204 = ActiveBenchModule.GetClientInfo(v202);

                    if v204 == nil then
                        v203 = false;
                    else
                        v203 = v204.Access == false;
                    end;
                end;
            else
                v203 = nil;
            end;

            if not v194 then
                if u2.Name == "Wall Block" then
                    v194 = true;
                elseif v191 then
                    v194 = v191.DisplayHealthOnly and not (v163 or v192);
                else
                    v194 = v191;
                end;
            end;

            local v205;

            if v199 then
                if v163 then
                    if u2.Name == "Wall Block" then
                        v205 = false;
                    else
                        v205 = not v203;
                    end;
                else
                    v205 = v163;
                end;
            else
                v205 = v199;
            end;

            local v206;

            if v191 then
                v206 = v191.Type == "BasePart";
            else
                v206 = v191;
            end;

            local v207;

            if v206 then
                if v205 then
                    v207 = u2:GetAttribute("DamageType") ~= "Steel";
                else
                    v207 = v205;
                end;
            else
                v207 = v206;
            end;

            if v167 ~= u2 then
                TweenUtil:Tween(Hover, "ImageTransparency", 0, 0.2, "Quart", "Out");
                TweenUtil:Tween(Hover.Action, "TextTransparency", 1, 0.3, "Quart", "In");

                if not SelectedHighlight then
                    SelectedHighlight = VFX2.Highlight:Clone();
                    SelectedHighlight.Name = "SelectedHighlight";
                    SelectedHighlight.OutlineColor = Color3.new(1, 1, 1);
                    SelectedHighlight.OutlineTransparency = 1;
                    SelectedHighlight.Parent = u2;
                end;

                if not Info2 then
                    Info2 = Info:Clone();

                    for i, v in pairs(v8) do
                        local v208 = Info2:FindFirstChild(i, true);

                        if v208 then
                            for _, v2 in pairs(v.Properties) do
                                v208[v2] = 1;
                            end;
                        end;
                    end;

                    Info2.StudsOffset = v196 - Vector3.new(0, 2, 0);
                    Info2:SetAttribute("OrigOffset", Info2.StudsOffset);
                    Info2.Parent = u2;
                end;

                if Info2 then
                    for i, v in pairs(v8) do
                        local v209 = Info2:FindFirstChild(i, true);

                        if v209 then
                            TweenUtil:Tween(v209, v.Properties, v.Values, 0.3, "Quart", "Out");
                        end;
                    end;

                    TweenUtil:Tween(Info2, "StudsOffset", v196, 0.2, "Quart", "Out");
                end;
            end;

            if SelectedHighlight then
                SelectedHighlight.Adornee = u2;
                SelectedHighlight.DepthMode = Enum.HighlightDepthMode[v192 and "AlwaysOnTop" or "Occluded"];
                local v210 = SelectedHighlight:GetAttribute("Vis");

                if v194 or v195 then
                    if v210 then
                        SelectedHighlight:SetAttribute("Vis", false);
                        TweenUtil:Tween(SelectedHighlight, { "FillTransparency", "OutlineTransparency" }, { 1, 1 }, 0.3, "Quart", "In");
                    end;
                elseif not v210 then
                    SelectedHighlight:SetAttribute("Vis", true);
                    TweenUtil:Tween(SelectedHighlight, { "FillTransparency", "OutlineTransparency" }, { 0.7, 0 }, 0.2, "Quart", "Out");
                end;

                local v211 = u2:GetAttribute("LastDamaged");
                local v212 = (Values.ServerTick.Value - (v211 or 0) >= 60 or not v163) and Color3.new(1, 1, 1) or script:GetAttribute("DamagedBenchOutlineColor");

                if ElectricityController:GetAttribute("Placing") then
                    if shared.CachedElectricalBenchNames[u2.Name] then
                        v212 = Color3.fromRGB(63, 194, 46);
                    else
                        v212 = Color3.fromRGB(194, 40, 50);
                    end;
                end;

                SelectedHighlight.FillColor = v212;
                SelectedHighlight.OutlineColor = v212;
            end;

            if Info2 then
                Hover.Image = script:GetAttribute((u2:GetAttribute("Occupied") and "Unavailable" or "Default") .. "DotImage");
                local v213 = u2:GetAttribute("BreakLocked");
                local v214, v215 = (v191 and (v191.ClientFunction or function() -- Line: 1417
                end) or function() -- Line: 1417
                end)(u2);
                local v216 = v214 or u2:GetAttribute("FirstAction");
                local v217 = v215 or (u2:GetAttribute("TotalActions") or 0);

                if v191 then
                    if v217 <= 0 and v191.Type ~= "BasePart" then
                        if v191.PickupBehavior == true then
                            v163 = true;
                        elseif v191.PickupBehavior ~= "HammerOnly" then
                            v163 = false;
                        end;
                    else
                        v163 = false;
                    end;
                else
                    v163 = v191;
                end;

                local v218 = v192 and u2:FindFirstChild("Item") and HttpService:JSONDecode(u2.Item.Value);
                local v219;

                if u2:GetAttribute("Armed") == true then
                    v219 = "";
                elseif v195 then
                    v219 = Humanoid2 and Humanoid2:GetAttribute("Downed") and "REVIVE" or "INVITE TO TEAM";
                else
                    v219 = v205 and "REPAIR" or ((v192 or v163) and "PICK UP" or (v193 and "HARVEST" or (v216 or ""):upper()));
                end;

                Info2.NameLabel.Text = (v194 or v195) and "" or (u2.Name:find(" Trophy") and "BONE TROPHY" or u2.Name:gsub("Locked ", v213 == false and "Unlocked " or "Locked "):upper()) .. (v218 and (v218.Amount or 0) > 1 and (" x" .. NumberUtil:FormatNumber(v218.Amount) or "") or "");
                local v220 = v161 and v207 and "UPGRADE" or v219;
                Info2.Action.Text = (v161 and "   " or "<font color=\"rgb(176, 176, 176)\">" .. "[" .. (v213 and "BREAK OPEN TO VIEW CONTENTS" or (v199 and "MB1" or v157)) .. "]</font>") .. (v213 and "" or " " .. v220);
                local GamepadImage = Info2.Action:FindFirstChild("GamepadImage");

                if GamepadImage then
                    if v206 and v161 then
                        GamepadImage.Visible = v207;

                        if v207 then
                            GamepadImage.Image = UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonL2);
                        end;
                    else
                        GamepadImage.Visible = v161;
                    end;
                end;

                local v221;

                if v220 == "" then
                    v221 = false;
                else
                    local v222;

                    if v206 then
                        if v161 then
                            v222 = not v207;
                        else
                            v222 = v161;
                        end;
                    else
                        v222 = v206;
                    end;

                    v221 = not v222;
                end;

                Info2.Action.Visible = v221;

                if v161 then
                    Info2.Options.Text = v205 and not v206 and "HOLD FOR MORE OPTIONS" or (v217 > 1 and "HOLD FOR MORE OPTIONS" or "");
                else
                    Info2.Options.Text = v205 and `HOLD [{v158}] FOR MORE OPTIONS` or (v217 > 1 and (`HOLD [{v157}] FOR MORE OPTIONS` or "") or "");
                end;

                local v223 = v161 and not (InventoryController:GetAttribute("Open") or WheelController:GetAttribute("Open") or (script:GetAttribute("Dialog") or Codelock.Visible));

                if v223 then
                    if not (v206 and v207) then
                        v207 = not v206 and v219 ~= "";
                    end;
                else
                    v207 = v223;
                end;

                Interaction.Visible = v207;

                if v207 then
                    Interaction.xtra.ImageLabel.Image = UserInputService:GetImageForKeyCode(v206 and Enum.KeyCode.ButtonL2 or Enum.KeyCode.ButtonX);
                    Interaction.xtra.Text = " - " .. (v206 and "UPGRADE" or v219);
                end;

                local Bar = Info2.Bar;
                local v224;

                if (v201 == nil or (v201 == false or u2:GetAttribute("BenchName"))) and (v197 == nil or (v198 == nil or v198 <= 0)) then
                    v224 = false;
                else
                    v224 = u2.Name ~= "Sleeper";
                end;

                Bar.Visible = v224;
                Info2.Adornee = u2:FindFirstChild("Door") and u2.Door.PrimaryPart or u2.PrimaryPart;

                if Info2.Bar.Visible then
                    local v225 = v197 or (v201 and (v201.Health or 0) or 0);
                    local v226 = v198 or (v201 and v201.MaxHealth or 0);

                    if v226 ~= 0 then
                        Info2.Bar.StatLabel.Text = NumberUtil:FormatNumber((math.ceil(v225))) .. "/" .. NumberUtil:FormatNumber((math.floor(v226)));
                        Info2.Bar.Fill.Size = UDim2.new(v225 / v226, 0, 1, 0);
                        local StabilityLabel = Info2.Bar.StabilityLabel;
                        local v227;

                        if v199 and v200 then
                            local v228 = math.clamp(v199 - v200, 0, 1) * 100;
                            v227 = math.ceil(v228) .. "% STABLE" or "";
                        else
                            v227 = "";
                        end;

                        StabilityLabel.Text = v227;
                    end;
                end;
            end;

            v101(v164, u2, not v203 and v165);

            if shared.CachedConnections[u2] and shared.CachedConnections[u2].PowerThroughput then
                PowerThroughput.Text = "POWER THROUGHPUT: " .. shared.CachedConnections[u2].PowerThroughput .. (not (v191 and v191.RequiredPower) and "" or "/" .. tostring(v191.RequiredPower));
                PowerThroughput.Visible = true;
            end;
        end;
    end;

    v4 = v185;
end;