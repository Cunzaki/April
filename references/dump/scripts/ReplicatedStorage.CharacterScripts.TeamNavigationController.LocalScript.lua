-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Values = ReplicatedStorage:WaitForChild("Values");
local GuiUtil = require(Modules:WaitForChild("GuiUtil"));
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local TweenUtil = require(Modules:WaitForChild("TweenUtil"));
local Items = require(Modules:WaitForChild("Items"));
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local ActiveBenchModule = require(Modules:WaitForChild("ActiveBenchModule"));
local u1 = require(Modules:WaitForChild("AssetContainer"))();
local LocalPlayer = Players.LocalPlayer;
local PlayerScripts = LocalPlayer.PlayerScripts;
local v2 = LocalPlayer.Character or script.Parent;
local Humanoid = v2:WaitForChild("Humanoid");
local HumanoidRootPart = v2:WaitForChild("HumanoidRootPart");
local CurrentCamera = workspace.CurrentCamera;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local Main = PlayerGui:WaitForChild("Main");
local Compass = Main:WaitForChild("Compass");
local Map = Main:WaitForChild("Map");
local Map2 = Map:WaitForChild("Frame"):WaitForChild("Map");
local PlayerCursor = Map2:WaitForChild("PlayerCursor");
local Team = Main:WaitForChild("Team");
local u3 = { Team:WaitForChild("Accept"), Team:WaitForChild("Decline"), Team:WaitForChild("Inviter") };
local CreateLeaveTeam = Team:WaitForChild("CreateLeaveTeam");
local TeamList = Team:WaitForChild("TeamList");
local c = TeamList:WaitForChild("c");
local TeamHighlight = script:WaitForChild("TeamHighlight");
local InventoryController = v2:WaitForChild("InventoryController");
local ChatController = PlayerScripts:WaitForChild("ChatController");
local PreferredInputController = PlayerScripts:WaitForChild("PreferredInputController");
local UpdateChannel = ChatController:WaitForChild("UpdateChannel");
local u4 = Vector2.new(0, 0);
local v5 = tick();
local v6 = tick();
local v7 = tick();
local u8 = InventoryController:GetAttribute("CurOpen");
shared.cachedTeamModels = {};
shared.YourTeam = nil;
local v9 = {
    MaxDistance = {
        Default = 20,
        Team = 750
    },
    TextColor3 = {
        Default = Color3.fromRGB(255, 255, 255),
        Team = Color3.fromRGB(30, 158, 255)
    }
};
local v10 = RaycastUtil:FilterFunction("View");
local v11 = {
    [0] = "N",
    [45] = "NE",
    [90] = "E",
    [135] = "SE",
    [180] = "S",
    [225] = "SW",
    [270] = "W",
    [315] = "NW"
};
local u12 = {};
local u13 = { 0, -360, 360 };
local u14 = false;
local u15 = false;
local u16 = nil;
local u17 = {};
local u18 = {};

for i = 0, 355, 5 do
    local v19 = i - 90 - (i - 90 > 180 and 360 or 0);
    local v20 = v11[i];
    local v21 = v20 and (v20:len() > 1 and "TemplateMedium" or "TemplateLarge") or nil or (i % 10 == 0 and "TemplateMedium" or (i % 5 == 0 and "TemplateSmall" or false));

    if v21 then
        local v22 = Compass:FindFirstChild(v21):Clone();
        local v23 = v22:FindFirstChildOfClass("TextLabel");

        if v23 then
            v23.Text = v20 or tostring(i);
            v23.TextTransparency = v20 and 0 or v23.TextTransparency;
            v23.TextStrokeTransparency = v20 and 0.7 or v23.TextStrokeTransparency;
        end;

        v22.Name = "Angle" .. v19;
        v22.BackgroundTransparency = v20 and 0 or v22.BackgroundTransparency;
        v22.BorderColor3 = v20 and v22.BorderColor3 or Color3.fromRGB(132, 132, 132);
        v22.Parent = Compass;
        table.insert(u12, v22);
    end;
end;

local u24 = #u12 - 18;

local function _() -- Line: 159
    -- upvalues: Humanoid (copy)
    return Humanoid and Humanoid.Parent and Humanoid.Health > 0;
end;

local function u45() -- Line: 163
    -- upvalues: CurrentCamera (copy), PlayerGui (copy), u16 (ref), u13 (copy), Compass (copy), u12 (copy), u24 (copy)
    local CFrame2 = CurrentCamera.CFrame;
    local Position = CFrame2.Position;
    local LookVector = CFrame2.LookVector;
    local v25 = CFrame.new(Position, Position + Vector3.new(LookVector.X, 0, LookVector.Z));
    local LookVector2 = v25.LookVector;
    local v26 = PlayerGui:GetAttribute("PlayerMapPin");
    local v27 = u16 == LookVector2;

    if v27 and not v26 then
        return;
    end;

    local v28 = math.atan2(LookVector2.Z, LookVector2.X);
    local v29 = math.deg(v28);

    if v26 then
        local v30 = Vector2.new(Position.X, Position.Z) - v26;
        local v31 = { CFrame2:ToOrientation() };
        math.deg(v31[2]);
        local v32 = math.atan2(v30.X, v30.Y);
        local v33 = -math.deg(v32) - 90;
        local v34 = v33 + (v33 < 0 and 360 or 0);
        local v35 = false;

        for _, v in pairs(u13) do
            local v36 = v34 + v - v29;

            if math.abs(v36) <= 45 then
                Compass.Pin.Position = UDim2.new(0.5 + v36 / 90, 0, 0.04, 0);
                v35 = true;
                break;
            end;
        end;

        Compass.Pin.Visible = v35;
    end;

    if v27 then
        return;
    end;

    u16 = LookVector2;
    local v37 = 0;
    local v38 = nil;
    local v39 = false;
    local v40 = false;

    for i, v in pairs(u12) do
        local v41;

        if v37 < 18 then
            if v38 and v38 > 0 then
                v38 = v38 - 1;
                v.Visible = false;
            else
                local v42 = tonumber(v.Name:sub(6));
                v41 = v39;

                for _, v3 in pairs(u13) do
                    if v39 ~= false or math.abs(v29 + v3 - v42) <= 45 then
                        v.Visible = true;
                        local LookVector3 = (v25 * CFrame.Angles(0, math.rad(v42), 0)).LookVector;
                        local v43 = math.atan2(LookVector3.Z, LookVector3.X);
                        local v44 = math.deg(v43) * -1;
                        v.Position = UDim2.new(v44 / 90 + 0.5, 0, v:FindFirstChild("Label") and 0.25 or 0.125, 0);
                        v37 = v37 + 1;
                        v39 = true;
                        break;
                    end;
                end;

                if not v39 then
                    v.Visible = false;

                    if v40 and not v38 then
                        v38 = u24 - 1;
                        v39 = v41;
                    else
                        v39 = v41;
                    end;
                end;

                if i == 1 then
                    v39 = v41;
                    v40 = true;
                elseif v40 then
                    v39 = v41;
                else
                    v39 = true;
                end;
            end;
        else
            v41 = v39;
            v.Visible = false;

            if v40 and not v38 then
                v38 = u24 - 1;
                v39 = v41;
            else
                v39 = v41;
            end;
        end;
    end;
end;

local function u57(p46, p47) -- Line: 233
    -- upvalues: u17 (ref), Values (copy), TeamList (copy), Players (copy), c (copy), LocalPlayer (copy), InventoryController (copy)
    local v48 = false;

    if #p46 == #u17 then
        for i, v in pairs(p46) do
            if u17[i] ~= v then
                v48 = true;
                break;
            end;
        end;
    else
        v48 = true;
    end;

    u17 = p46;

    if not (v48 or p47) then
        return;
    end;

    local v49 = #u17 > 0;
    script:SetAttribute("InTeam", v49);
    local v50;

    if #u17 < Values.TeamSize.Value then
        v50 = u17[1] ~= "CantLeave";
    else
        v50 = false;
    end;

    script:SetAttribute("CanInvite", v50);

    for _, child in pairs(TeamList:GetChildren()) do
        if child.Name:find("Member") then
            child:Destroy();
        end;
    end;

    local v51 = 0;

    for _, v in pairs(u17) do
        if v ~= "CantLeave" then
            v51 = v51 + 1;
            local v52 = v51 == 9;
            local v53;

            if typeof(v) == "string" then
                v53 = not v52;
            else
                v53 = false;
            end;

            local u54 = nil;

            if v52 then
                u54 = "...";
            else
                local v = tonumber(v);
                pcall(function() -- Line: 268
                    -- upvalues: u54 (ref), Players (ref), v (ref)
                    u54 = Players:GetNameFromUserIdAsync(v);
                end);
                u54 = u54 or v .. "_ERROR";
            end;

            local v55 = c:Clone();
            v55.Name = "Member" .. v51;
            v55.Position = UDim2.new(v55.Position.X.Scale, 0, v55.Position.Y.Scale + (v51 - 1) * 0.03);
            v55.Text = u54;
            local v56;

            if v53 then
                v56 = v55.TextColor3;
            elseif v == LocalPlayer.UserId then
                v56 = Color3.fromRGB(119, 255, 221);
            else
                v56 = Color3.fromRGB(255, 255, 255);
            end;

            v55.TextColor3 = v56;
            v55.Parent = TeamList;
            v55.Visible = true;

            if v52 then
                break;
            end;
        end;
    end;

    if v49 then
        v49 = InventoryController:GetAttribute("CurOpen") ~= "Crafting";
    end;

    TeamList.Visible = v49;
end;

local function _(p58) -- Line: 287
    -- upvalues: u4 (copy)
    local v59 = 0.5 + (p58.X - u4.X) / 12800;
    local v60 = typeof(p58) == "Vector3" and p58.Z or p58.Y;

    return UDim2.new(v59, 0, 0.5 + (v60 - u4.Y) / 12800, 0);
end;

local function _(p61) -- Line: 294
    -- upvalues: u4 (copy)
    return Vector2.new((p61.X.Scale - 0.5) * 12800, (p61.Y.Scale - 0.5) * 12800) + u4;
end;

local u62 = {};

local function u76(p63, p64) -- Line: 301
    -- upvalues: Players (copy), u62 (copy), Map2 (copy), u4 (copy), HumanoidRootPart (copy), PlayerCursor (copy), Humanoid (copy)
    if p63 then
        local v65 = {};

        for i, v in pairs(p64) do
            local v66 = tonumber(v);

            if v66 then
                local v67 = Players:GetPlayerByUserId(v66);

                if v67 then
                    v65[v66] = true;
                    local Name = v67.Name;
                    local v68 = u62[v66];
                    local v69 = p63[tostring(i)];

                    if v69 and not v68 then
                        v68 = Map2.TeamCursor:Clone();
                        v68.Name = Name;
                        v68.Parent = Map2;
                        v68.Visible = true;
                        u62[v66] = v68;
                    end;

                    if v68 then
                        v68.PlayerName.Text = Name;

                        if v69 then
                            local v70 = 0.5 + (v69.X - u4.X) / 12800;
                            local v71 = typeof(v69) == "Vector3" and v69.Z or v69.Y;
                            v68.Position = UDim2.new(v70, 0, 0.5 + (v71 - u4.Y) / 12800, 0);
                        end;
                    end;
                end;
            end;
        end;

        for i, v in pairs(u62) do
            if not v65[i] then
                v:Destroy();
                u62[i] = nil;
            end;
        end;
    end;

    if HumanoidRootPart and HumanoidRootPart.Parent then
        local CFrame2 = HumanoidRootPart.CFrame;
        local LookVector = CFrame2.LookVector;
        local v72 = math.atan2(-LookVector.Z, LookVector.X);
        local v73 = math.deg(v72) * -1;
        local Position = CFrame2.Position;
        local v74 = 0.5 + (Position.X - u4.X) / 12800;
        local v75 = typeof(Position) == "Vector3" and Position.Z or Position.Y;
        PlayerCursor.Position = UDim2.new(v74, 0, 0.5 + (v75 - u4.Y) / 12800, 0);
        PlayerCursor.Rotator.Rotation = v73;
    end;

    PlayerCursor.Visible = Humanoid and Humanoid.Parent and Humanoid.Health > 0;
end;

local function _(p77) -- Line: 345
    -- upvalues: u3 (copy)
    for _, v in pairs(u3) do
        v.Visible = p77;
    end;
end;

local RunService = game:GetService("RunService");
local u78 = false;
local u79 = false;
local GamepadService = game:GetService("GamepadService");
local MapToolTip = Map:WaitForChild("MapToolTip");
local PlaceMarker = MapToolTip:WaitForChild("PlaceMarker");
require(Modules:WaitForChild("GamepadIconModule")).Register(PlaceMarker.ImageLabel, "ButtonA");

local function u81(p80) -- Line: 365
    -- upvalues: Map (copy), Values (copy), InventoryController (copy), UserInputService (copy), GamepadService (copy), PreferredInputController (copy), MapToolTip (copy)
    if Map:GetAttribute("Locked") or p80 and not Values.MapEnabled.Value then
        return;
    end;

    Map.Visible = p80;

    if not InventoryController:GetAttribute("Open") or p80 then
        UserInputService.MouseBehavior = Enum.MouseBehavior[p80 and "Default" or "LockCenter"];
        UserInputService.MouseIconEnabled = p80;
    end;

    if p80 then
        pcall(function() -- Line: 374
            -- upvalues: GamepadService (ref)
            GamepadService:EnableGamepadCursor(nil);
        end);
    elseif not InventoryController:GetAttribute("Open") then
        pcall(function() -- Line: 377
            -- upvalues: GamepadService (ref)
            GamepadService:DisableGamepadCursor();
        end);
    end;

    MapToolTip.Visible = p80 and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
    script:SetAttribute("MapOpen", p80);

    if not p80 then
        script:SetAttribute("MapClosedTick", tick());
    end;
end;

local function u95() -- Line: 389
    -- upvalues: u79 (ref), GuiUtil (copy), Map (copy), u78 (ref), RunService (copy), UserInputService (copy), MapToolTip (copy)
    if u79 then
        return;
    end;

    u79 = true;
    local v82 = GuiUtil:GetZoomInfo(Map);

    if not v82 then
        u79 = false;

        return;
    end;

    while u78 and v82 do
        local v83 = RunService.Heartbeat:Wait();

        if not u78 then
            break;
        end;

        UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService.MouseIconEnabled = true;
        local u84 = 0;
        local u85 = 0;
        local u86 = 0;
        pcall(function() -- Line: 406
            -- upvalues: UserInputService (ref), u84 (ref), u85 (ref), u86 (ref)
            for _, v in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
                if v.KeyCode == Enum.KeyCode.Thumbstick1 then
                    u84 = v.Position.X;
                    u85 = v.Position.Y;
                elseif v.KeyCode == Enum.KeyCode.ButtonR2 then
                    if v.Position.Z > 0.1 then
                        u86 = u86 + v.Position.Z;
                    end;
                elseif v.KeyCode == Enum.KeyCode.ButtonL2 and v.Position.Z > 0.1 then
                    u86 = u86 - v.Position.Z;
                end;
            end;
        end);
        u84 = math.abs(u84) < 0.2 and 0 or u84;
        u85 = math.abs(u85) < 0.2 and 0 or u85;
        local Frame = v82.Frame;

        if not (Frame and Frame.Parent) then
            break;
        end;

        if math.abs(u86) > 0 then
            v82.TargetScale = math.clamp(v82.TargetScale + u86 * 4 * v83, 1, 4);
        end;

        if math.abs(v82.Scale - v82.TargetScale) > 0.001 then
            v82.Scale = v82.Scale + (v82.TargetScale - v82.Scale) * math.min(v83 * 12, 1);

            if math.abs(v82.Scale - v82.TargetScale) <= 0.001 then
                v82.Scale = v82.TargetScale;
            end;

            Frame.Size = UDim2.new(v82.Scale, 0, v82.Scale, 0);
        end;

        local v87 = math.max(v82.Scale * 0.5 - 0.5, 0);
        local v88 = 0.5 - v87;
        local v89 = v87 + 0.5;
        local Position = Frame.Position;
        local AbsoluteSize = Map.AbsoluteSize;
        local Scale = Position.X.Scale;
        local Scale2 = Position.Y.Scale;

        if math.abs(u84) > 0 or math.abs(u85) > 0 then
            Scale = Scale + -u84 * 300 * v83 / AbsoluteSize.X;
            Scale2 = Scale2 + u85 * 300 * v83 / AbsoluteSize.Y;
        end;

        local v90 = math.clamp(Scale, v88, v89);
        local v91 = math.clamp(Scale2, v88, v89);

        if v90 ~= Position.X.Scale or v91 ~= Position.Y.Scale then
            Frame.Position = UDim2.new(v90, 0, v91, 0);
        end;

        local v92 = UserInputService:GetMouseLocation();
        local AbsolutePosition = Map.AbsolutePosition;
        local AbsoluteSize2 = Map.AbsoluteSize;
        local v93 = math.clamp((v92.X - AbsolutePosition.X) / AbsoluteSize2.X, 0, 1);
        local v94 = math.clamp((v92.Y - AbsolutePosition.Y) / AbsoluteSize2.Y, 0, 1);
        MapToolTip.Position = UDim2.new(v93, 0, v94, 0);
    end;

    u79 = false;
end;

GuiUtil:AddScrollToFrame(Map, 1, 4, 0.15, 1.15);
Map.MouseButton2Down:Connect(function() -- Line: 484
    -- upvalues: Map (copy), UserInputService (copy), u4 (copy), PlayerGui (copy), u45 (copy)
    if not script:GetAttribute("MapOpen") then
        return;
    end;

    local Map3 = Map.Frame.Map;
    local v96 = UserInputService:GetMouseLocation() - (Map3.AbsolutePosition + Vector2.new(0, 36));
    local v97 = UDim2.new(v96.X / Map3.AbsoluteSize.X, 0, v96.Y / Map3.AbsoluteSize.Y, 0);
    local v98 = Vector2.new((v97.X.Scale - 0.5) * 12800, (v97.Y.Scale - 0.5) * 12800) + u4;
    Map3.Pin.Position = v97;
    Map3.Pin.Visible = true;
    PlayerGui:SetAttribute("PlayerMapPin", v98);
    u45();
end);
Humanoid:GetAttributeChangedSignal("AttemptRespawn"):Connect(function() -- Line: 496
    -- upvalues: GuiUtil (copy), Map (copy)
    GuiUtil:ClearScrollFrame(Map);
end);
Humanoid:GetAttributeChangedSignal("Downed"):Connect(function() -- Line: 499
    -- upvalues: u81 (copy), u78 (ref)
    u81(false);
    u78 = false;
end);
Humanoid.Died:Connect(function() -- Line: 503
    -- upvalues: u78 (ref), HumanoidRootPart (copy), PlayerGui (copy), Map (copy), u4 (copy)
    u78 = false;

    if not HumanoidRootPart.Parent then
        return;
    end;

    local Position = HumanoidRootPart.Position;
    local v99 = Vector2.new(Position.X, Position.Z);
    PlayerGui:SetAttribute("LastDeathPin", v99);
    local DeathMarker = Map.Frame.Map.DeathMarker;
    local v100 = 0.5 + (v99.X - u4.X) / 12800;
    local v101 = typeof(v99) == "Vector3" and v99.Z or v99.Y;
    DeathMarker.Position = UDim2.new(v100, 0, 0.5 + (v101 - u4.Y) / 12800, 0);
    DeathMarker.Visible = true;
end);
UserInputService.InputBegan:Connect(function(p102, p103) -- Line: 514
    -- upvalues: SettingsModule (copy), UserInputService (copy), Humanoid (copy), u78 (ref), u81 (copy), Map (copy), u4 (copy), PlayerGui (copy), u45 (copy)
    if SettingsModule.MainMenuOpen() then
        return;
    end;

    local UserInputType = p102.UserInputType;

    if UserInputType == Enum.UserInputType.Gamepad1 then
        if UserInputService:GetFocusedTextBox() or Humanoid:GetAttribute("Downed") then
            return;
        end;

        if not (Humanoid and Humanoid.Parent and Humanoid.Health > 0) then
            return;
        end;

        local Name = p102.KeyCode.Name;

        if Name == "ButtonB" and u78 then
            return;
        end;

        if Name == "ButtonB" and u78 then
            u78 = false;
            u81(false);

            return;
        end;

        if Name == "ButtonA" and u78 then
            local Map3 = Map.Frame.Map;
            local v104 = UserInputService:GetMouseLocation() - (Map3.AbsolutePosition + Vector2.new(0, 36));
            local v105 = UDim2.new(v104.X / Map3.AbsoluteSize.X, 0, v104.Y / Map3.AbsoluteSize.Y, 0);
            local v106 = Vector2.new((v105.X.Scale - 0.5) * 12800, (v105.Y.Scale - 0.5) * 12800) + u4;
            Map3.Pin.Position = v105;
            Map3.Pin.Visible = true;
            PlayerGui:SetAttribute("PlayerMapPin", v106);
            u45();
        end;
    elseif not p103 then
        if UserInputService:GetFocusedTextBox() or Humanoid:GetAttribute("Downed") then
            return;
        end;

        if not (Humanoid and Humanoid.Parent and Humanoid.Health > 0) then
            return;
        end;

        if UserInputType == Enum.UserInputType.Keyboard and p102.KeyCode.Name == SettingsModule.GetSetting("Controls", "Open Map") then
            u81(true);
        end;
    end;
end);
UserInputService.InputEnded:Connect(function(p107, p108) -- Line: 544
    -- upvalues: UserInputService (copy), SettingsModule (copy), u81 (copy), ChatController (copy), u78 (ref), u95 (copy)
    local UserInputType = p107.UserInputType;

    if UserInputService:GetFocusedTextBox() then
        return;
    end;

    if UserInputType == Enum.UserInputType.Keyboard then
        if p107.KeyCode.Name == SettingsModule.GetSetting("Controls", "Open Map") then
            u81(false);
        end;
    elseif UserInputType == Enum.UserInputType.Gamepad1 and (p107.KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Open Map") and not ChatController:GetAttribute("Typing")) then
        u78 = not u78;
        u81(u78);

        if u78 then
            task.spawn(u95);
        end;
    end;
end);
u81(false);
InventoryController:GetAttributeChangedSignal("CurOpen"):Connect(function() -- Line: 566
    -- upvalues: InventoryController (copy), u8 (ref), TeamList (copy), CreateLeaveTeam (copy), u14 (ref), u15 (ref), u3 (copy)
    local v109 = InventoryController:GetAttribute("CurOpen");

    if v109 == u8 then
        return;
    end;

    u8 = v109;
    local v110 = v109 == "Inventory";
    local v111 = script:GetAttribute("InTeam");
    local v112;

    if v111 then
        v112 = v109 ~= "Crafting";
    else
        v112 = v111;
    end;

    TeamList.Visible = v112;
    TeamList.Position = UDim2.new(0, 0, v110 and 0.04 or 0, 0);
    CreateLeaveTeam.Label.Text = v111 and "LEAVE TEAM" or "CREATE TEAM";
    CreateLeaveTeam.Visible = not u14 and v110;

    if not u15 and v110 then
        return;
    end;

    for _, v in pairs(u3) do
        v.Visible = v110;
    end;
end);

script:WaitForChild("FetchTeam").OnInvoke = function() -- Line: 583
    -- upvalues: u17 (ref)
    return u17;
end;

local u113 = 0;
u1("Setup", "\1\1401\200\176V\254\208\146<o*\1271=\30D\166cI", "\0086X\151o\242\18+\245J\208\246\243\136\196K)T\148\1", function(p114, p115, p116, p117, p118) -- Line: 589
    -- upvalues: u57 (copy), u76 (copy), UpdateChannel (copy), u15 (ref), Players (copy), u113 (ref), u3 (copy), InventoryController (copy)
    if p114 ~= "Update" then
        if p114 == "Invite" then
            u15 = p115[1];
            local u119 = nil;
            pcall(function() -- Line: 602
                -- upvalues: u119 (ref), Players (ref), u15 (ref)
                u119 = Players:GetNameFromUserIdAsync(u15);
            end);
            u119 = u119 or u15 .. "_ERROR";
            local v120 = "Join " .. u119 .. "\'s Team";

            if os.clock() - u113 >= (v120 == u3[3].Text and 30 or 8) then
                u113 = os.clock();
                script.InviteNotification:Play();
            end;

            u3[3].Text = v120;

            if InventoryController:GetAttribute("CurOpen") ~= "Inventory" then
                return;
            end;

            for _, v in pairs(u3) do
                v.Visible = true;
            end;
        end;

        return;
    end;

    u57(p115, p117);

    if p116 then
        u76(p116, p115);
    end;

    shared.YourTeam = p118;
    UpdateChannel:Fire("Team");
end);
u3[1].MouseButton1Click:Connect(function() -- Line: 619
    -- upvalues: u15 (ref), u3 (copy), u1 (copy)
    if not u15 then
        return;
    end;

    for _, v in pairs(u3) do
        v.Visible = false;
    end;

    u1("Fire", "\1\1401\200\176V\254\208\146<o*\1271=\30D\166cI", "\0086X\151o\242\18+\245J\208\246\243\136\196K)T\148\1", "Join", u15);
    u15 = false;
end);
u3[2].MouseButton1Click:Connect(function() -- Line: 631
    -- upvalues: u15 (ref), u3 (copy)
    u15 = false;

    for _, v in pairs(u3) do
        v.Visible = false;
    end;
end);
CreateLeaveTeam.MouseButton1Click:Connect(function() -- Line: 637
    -- upvalues: u14 (ref), CreateLeaveTeam (copy), u1 (copy), InventoryController (copy), u17 (ref)
    u14 = true;
    CreateLeaveTeam.Visible = false;
    u1(
        "Fire",
        "\1\1401\200\176V\254\208\146<o*\1271=\30D\166cI",
        "\0086X\151o\242\18+\245J\208\246\243\136\196K)T\148\1",
        "Create/Leave"
    );
    task.delay(2, function() -- Line: 645
        -- upvalues: u14 (ref), InventoryController (ref), CreateLeaveTeam (ref), u17 (ref)
        u14 = false;

        if InventoryController:GetAttribute("CurOpen") ~= "Inventory" then
            return;
        end;

        CreateLeaveTeam.Label.Text = #u17 > 0 and "LEAVE TEAM" or "CREATE TEAM";
        CreateLeaveTeam.Visible = true;
    end);
end);
local v121 = PlayerGui:GetAttribute("PlayerMapPin");

if v121 then
    local Pin = Map.Frame.Map.Pin;
    local v122 = 0.5 + (v121.X - u4.X) / 12800;
    local v123 = typeof(v121) == "Vector3" and v121.Z or v121.Y;
    Pin.Position = UDim2.new(v122, 0, 0.5 + (v123 - u4.Y) / 12800, 0);
    Pin.Visible = true;
end;

local v124 = PlayerGui:GetAttribute("LastDeathPin");

if v124 then
    local DeathMarker = Map.Frame.Map.DeathMarker;
    local v125 = 0.5 + (v124.X - u4.X) / 12800;
    local v126 = typeof(v124) == "Vector3" and v124.Z or v124.Y;
    DeathMarker.Position = UDim2.new(v125, 0, 0.5 + (v126 - u4.Y) / 12800, 0);
    DeathMarker.Visible = true;
end;

CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(u45);
u45();
PlayerCursor.PlayerName.Text = LocalPlayer.Name;
local TradingPost = Map.Frame.Map:WaitForChild("TradingPost");

local function u130(p127) -- Line: 674
    for i = 1, 5 do
        local v128 = p127.Offers[i * 2 - 1];
        local v129 = p127.Offers[i * 2];

        if type(v128) == "table" and (v128[1] ~= 0 and (type(v129) == "table" and v129[1] ~= 0)) then
            return true;
        end;
    end;

    return false;
end;

task.defer(function() -- Line: 683
    -- upvalues: ActiveBenchModule (copy), u130 (copy), u18 (copy), Map (copy), TradingPost (copy), u4 (copy), TweenUtil (copy), Items (copy), NumberUtil (copy)
    while true do
        local v131 = 0;

        for i, v in ActiveBenchModule.GetAllRawClientInfos() do
            if v and (v.Offers and u130(v)) then
                local v132 = u18[i];

                if not (v132 and v132.Parent) then
                    if v132 then
                        v132:Destroy();
                    end;

                    local u133 = Map.Frame.Map.ShopTemplate:Clone();
                    u133.Name = "ShopMarker";
                    u133.Parent = Map.Frame.Map;
                    u133.Visible = true;
                    u133.MouseEnter:Connect(function() -- Line: 699
                        -- upvalues: u133 (ref)
                        u133.ZIndex = 7;
                    end);
                    u133.MouseLeave:Connect(function() -- Line: 702
                        -- upvalues: u133 (ref)
                        u133.ZIndex = 4;
                    end);
                    u133.Activated:Connect(function() -- Line: 705
                        -- upvalues: TradingPost (ref), ActiveBenchModule (ref), i (copy), u133 (ref), Map (ref), u18 (ref), u4 (ref), TweenUtil (ref), Items (ref), NumberUtil (ref)
                        if not TradingPost.Parent then
                            return;
                        end;

                        local v134 = ActiveBenchModule.GetClientInfoFromTag(i);

                        if not v134 then
                            return;
                        end;

                        local Offers = v134.Offers;

                        if not Offers then
                            return;
                        end;

                        if TradingPost.Parent == u133 then
                            TradingPost.Visible = false;
                            TradingPost.Parent = Map.Frame.Map;

                            return;
                        end;

                        local u135 = {};

                        if u133.LayoutOrder ~= 1 then
                            for i2, v3 in u18 do
                                if v3 and (v3.Parent and v3.LayoutOrder ~= 1) then
                                    local v136 = ActiveBenchModule.GetClientInfoFromTag(i2);

                                    if v136 then
                                        local Pos = v136.Pos;

                                        if Pos and (v134.Pos - Pos).Magnitude <= 150 then
                                            table.insert(u135, { v3, i2, v136 });
                                        end;
                                    end;
                                end;
                            end;
                        end;

                        if #u135 <= 1 then
                            TradingPost.Position = UDim2.new(-3.61, 0, u133.Position.Y.Scale >= 0.725 and -12.7 or 1.3, 0);
                            TradingPost.Visible = true;
                            TradingPost.Parent = u133;
                            TradingPost.Frame.Position = UDim2.new();

                            for i2 = 1, 5 do
                                local v137 = Offers[i2 * 2 - 1];
                                local v138 = Offers[i2 * 2];
                                local v139 = TradingPost.Frame[`Give{i2}`];
                                local v140 = TradingPost.Frame[`Receive{i2}`];

                                if type(v137) == "table" and (v137[1] ~= 0 and Items[v137[1]]) then
                                    local v141 = Items[v137[1]];
                                    v139.Empty.Visible = false;
                                    v139.ItemImage.Image = type(v141.Image) == "table" and v141.Image.Default or v141.Image;
                                    v139.ItemAmount.Text = `x{NumberUtil:FormatNumber(v137[2])}`;
                                else
                                    v139.Empty.Visible = true;
                                    v139.ItemImage.Image = "";
                                    v139.ItemAmount.Text = "";
                                end;

                                if type(v138) == "table" and (v138[1] ~= 0 and Items[v138[1]]) then
                                    local v142 = Items[v138[1]];
                                    v140.Empty.Visible = false;
                                    v140.ItemImage.Image = type(v142.Image) == "table" and v142.Image.Default or v142.Image;
                                    v140.ItemAmount.Text = `x{NumberUtil:FormatNumber(v138[2])}`;
                                else
                                    v140.Empty.Visible = true;
                                    v140.ItemImage.Image = "";
                                    v140.ItemAmount.Text = "";
                                end;
                            end;

                            TweenUtil:Tween(TradingPost.Frame, "Position", UDim2.new(0, 0, 1, 0), 0.5, "Quart", "Out");

                            return;
                        end;

                        print((`found {#u135} shop icons in a cluster`));
                        local Pos = v134.Pos;
                        local v143 = 0.5 + (Pos.X - u4.X) / 12800;
                        local v144 = typeof(Pos) == "Vector3" and Pos.Z or Pos.Y;
                        local v145 = UDim2.new(v143, 0, 0.5 + (v144 - u4.Y) / 12800, 0);

                        for i2, v3 in u135 do
                            local v146 = v3[1];
                            v146.LayoutOrder = 1;
                            TweenUtil:Tween(v146, "Position", v145 + UDim2.new(0.02 * (i2 - 1), 0, 0, 0), 0.5, "Quart", "Out");
                        end;

                        task.delay(5, function() -- Line: 737
                            -- upvalues: u135 (copy), TweenUtil (ref), u4 (ref)
                            for _, v3 in u135 do
                                local v147 = v3[1];

                                if v147 and v147.Parent then
                                    local Pos2 = v3[3].Pos;
                                    local v148 = 0.5 + (Pos2.X - u4.X) / 12800;
                                    local v149 = typeof(Pos2) == "Vector3" and Pos2.Z or Pos2.Y;
                                    TweenUtil:Tween(v147, "Position", UDim2.new(v148, 0, 0.5 + (v149 - u4.Y) / 12800, 0), 0.5, "Quart", "Out");
                                    v147.LayoutOrder = 0;
                                end;
                            end;
                        end);
                    end);
                    u18[i] = u133;
                end;
            end;

            v131 = v131 + 1;

            if v131 % 100 == 0 then
                task.wait();
            end;
        end;

        local v150 = 0;

        for i, v in u18 do
            v150 = v150 + 1;

            if v150 % 50 == 0 then
                task.wait();
            end;

            local v151 = ActiveBenchModule.GetClientInfoFromTag(i);

            if v151 and (v151.Offers and v151.Pos) then
                if v and v.Parent then
                    if u130(v151) then
                        if v.LayoutOrder ~= 1 then
                            local Pos = v151.Pos;
                            local v152 = 0.5 + (Pos.X - u4.X) / 12800;
                            local v153 = typeof(Pos) == "Vector3" and Pos.Z or Pos.Y;
                            v.Position = UDim2.new(v152, 0, 0.5 + (v153 - u4.Y) / 12800, 0);
                        end;
                    else
                        v:Destroy();
                        u18[i] = nil;
                    end;
                else
                    u18[i] = nil;
                end;
            else
                if v then
                    v:Destroy();
                end;

                u18[i] = nil;
            end;
        end;

        task.wait(20);
    end;
end);

while true do
    local v154, v155, v156;
    local v157 = 0;

    while true do
        if v157 == 0 then
            v157 = -1;

            while true do
                if tick() - v6 >= 0.2 then
                    v6 = tick();
                    checkRay = tick() - v5 >= 0.4;
                    TeamList.DetailLabel.TextColor3 = LocalPlayer.Team and LocalPlayer.Team.TeamColor.Color or Color3.new(1, 1, 1);

                    for _, v in pairs(u17) do
                        if v ~= "CantLeave" then
                            local v158 = tonumber(v);

                            if v158 ~= LocalPlayer.UserId then
                                local v159 = Players:GetPlayerByUserId(v158);
                                local v160;

                                if v159 then
                                    v160 = v159.Character;
                                else
                                    v160 = v159;
                                end;

                                local v161 = shared.cachedTeamModels[v158];
                                local v162, v163, v164, v165, v166;

                                if v161 and v161.Parent ~= nil then
                                    v162 = v160:FindFirstChild("NameTag");
                                    v163 = v160:FindFirstChild("TeamHighlight");

                                    if not v163 then
                                        v163 = TeamHighlight:Clone();
                                        v163.Parent = v160;
                                    end;

                                    if v159 then
                                        v159 = v159.Team;
                                    end;

                                    if v159 then
                                        v159 = v159.TeamColor.Color;
                                    end;

                                    if v159 then
                                        v163.FillColor = v159;
                                        v163.OutlineColor = v159;
                                    end;

                                    if v162 and v162:FindFirstChild("Label") then
                                        v162.MaxDistance = v9.MaxDistance.Team;
                                        v162.AlwaysOnTop = true;
                                        v162.Label.TextColor3 = v159 or v9.TextColor3.Team;
                                    end;

                                    if checkRay then
                                        v5 = tick();
                                        v164 = v2:FindFirstChild("Head");
                                        v165 = v160:FindFirstChild("Head");

                                        if v164 and v165 then
                                            v166 = RaycastUtil:Raycast(v164.Position, v165.Position - v164.Position, "Blacklist", {
                                                v2,
                                                v160,
                                                workspace.VFX,
                                                workspace.Animals,
                                                workspace.Drops,
                                                workspace.Plants
                                            }, false, v10, true);
                                            v163.FillTransparency = v166 and 0.5 or 1;
                                            v163.OutlineTransparency = v166 and 0 or 0.5;
                                            v163.Enabled = true;
                                        end;
                                    end;
                                elseif v159 and v160 then
                                    shared.cachedTeamModels[v158] = v160;
                                    v162 = v160:FindFirstChild("NameTag");
                                    v163 = v160:FindFirstChild("TeamHighlight");

                                    if not v163 then
                                        v163 = TeamHighlight:Clone();
                                        v163.Parent = v160;
                                    end;

                                    if v159 then
                                        v159 = v159.Team;
                                    end;

                                    if v159 then
                                        v159 = v159.TeamColor.Color;
                                    end;

                                    if v159 then
                                        v163.FillColor = v159;
                                        v163.OutlineColor = v159;
                                    end;

                                    if v162 and v162:FindFirstChild("Label") then
                                        v162.MaxDistance = v9.MaxDistance.Team;
                                        v162.AlwaysOnTop = true;
                                        v162.Label.TextColor3 = v159 or v9.TextColor3.Team;
                                    end;

                                    if checkRay then
                                        v5 = tick();
                                        v164 = v2:FindFirstChild("Head");
                                        v165 = v160:FindFirstChild("Head");

                                        if v164 and v165 then
                                            v166 = RaycastUtil:Raycast(v164.Position, v165.Position - v164.Position, "Blacklist", {
                                                v2,
                                                v160,
                                                workspace.VFX,
                                                workspace.Animals,
                                                workspace.Drops,
                                                workspace.Plants
                                            }, false, v10, true);
                                            v163.FillTransparency = v166 and 0.5 or 1;
                                            v163.OutlineTransparency = v166 and 0 or 0.5;
                                            v163.Enabled = true;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;

                    if tick() - v7 >= 1 then
                        v7 = tick();
                        v155, v156, v154 = pairs(shared.cachedTeamModels);
                        break;
                    end;

                    u76();
                    task.wait(0.1);
                else
                    if tick() - v7 >= 1 then
                        v7 = tick();
                        v155, v156, v154 = pairs(shared.cachedTeamModels);
                        break;
                    end;

                    u76();
                    task.wait(0.1);
                end;
            end;

            v157 = 1;
            continue;
        elseif v157 == 1 then
            v157 = -1;
            local v167, v168;

            if type(v155) == "function" then
                v167, v168 = v155(v156, v154);
            else
                v167, v168 = next(v155, v154);
            end;

            if v167 ~= nil then
                v154 = v167;
                local v169;

                if v167 == tonumber(v169) then
                    if false then
                        shared.cachedTeamModels[v167] = nil;
                        local NameTag = v168:FindFirstChild("NameTag");

                        if NameTag then
                            NameTag.MaxDistance = v9.MaxDistance.Default;
                            NameTag.AlwaysOnTop = false;

                            if NameTag:FindFirstChild("Label") then
                                NameTag.Label.TextColor3 = v9.TextColor3.Default;
                            end;
                        end;

                        local TeamHighlight2 = v168:FindFirstChild("TeamHighlight");

                        if TeamHighlight2 then
                            TeamHighlight2:Destroy();
                        end;
                    end;

                    v157 = 1;
                    continue;
                end;

                local v170, v171, v172;

                if type(v170) == "function" then
                    local v173;
                    v171, v169 = v170(v173, v172);
                else
                    v171, v169 = next(v170, v172);
                end;

                v172 = v171;
                u76();
                task.wait(0.1);
                break;
            else
                break;
            end;
        else
            break;
        end;
    end;
end;