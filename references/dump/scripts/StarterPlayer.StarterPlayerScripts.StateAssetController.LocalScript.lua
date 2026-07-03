-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");
local UserService = game:GetService("UserService");
local RunService = game:GetService("RunService");
local LocalPlayer = Players.LocalPlayer;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local u1 = nil;
local u2 = nil;
local u3 = nil;
local u4 = nil;
local u5 = nil;
local u6 = nil;
local u7 = nil;
local u8 = nil;
local u9 = nil;
local PreferredInputController = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");

local function _() -- Line: 19
    -- upvalues: PreferredInputController (copy)
    local v10 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    return v10;
end;

local u11 = {};
local u12 = nil;
local u13 = nil;
local u14 = nil;
local u15 = nil;
local u16 = nil;
local u17 = nil;
local u18 = nil;
local u19 = nil;
local u20 = nil;
local u21 = nil;
local u22 = nil;
local u23 = nil;
local u24 = nil;
local u25 = nil;
local u26 = nil;
local u27 = nil;
local u28 = nil;
local u29 = nil;
local u30 = nil;
local u31 = nil;
local u32 = false;
local CharacterScripts = ReplicatedStorage:WaitForChild("CharacterScripts");
local UIs = ReplicatedStorage:WaitForChild("UIs");
local CurrentCamera = workspace.CurrentCamera;
local Modules = ReplicatedStorage:WaitForChild("Modules");
local SoundModule = require(Modules:WaitForChild("SoundModule"));
local Items = require(Modules:WaitForChild("Items"));
local GamepadIconModule = require(Modules:WaitForChild("GamepadIconModule"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local TweenUtil = require(Modules:WaitForChild("TweenUtil"));
local Values = ReplicatedStorage:WaitForChild("Values");
local u33 = require(Modules:WaitForChild("AssetContainer"))();
local u34 = script:WaitForChild("Animations"):GetChildren();
local u35 = Vector2.new(0, 0);
local u36 = nil;
local u37 = nil;
local u38 = nil;
local u39 = {};
local u40 = os.clock();
local u41 = 0;
local u42 = nil;
local u43 = 0;
local u44 = nil;
local u45 = {
    Grass = 0.85,
    Sand = 1.8,
    Wood = 0.8,
    Metal = 1,
    Rock = 0.85,
    Water = 0.9,
    Mud = 1
};

local function u48(p46, p47) -- Line: 82
    -- upvalues: u17 (ref), TweenService (copy)
    if not (u17 and u17.Parent) then
        return;
    end;

    TweenService:Create(u17, TweenInfo.new(p47, Enum.EasingStyle.Quad), {
        Transparency = p46 and 0 or 1
    }):Play();
end;

local function u52(p49, p50) -- Line: 93
    -- upvalues: TweenService (copy)
    local v51 = TweenInfo.new(p50 or 1, Enum.EasingStyle.Bounce);
    TweenService:Create(workspace.CurrentCamera, v51, {
        CFrame = p49
    }):Play();
end;

local function u56(p53) -- Line: 102
    -- upvalues: u23 (ref), u12 (ref), TweenService (copy)
    if not (u23 and u23.Parent) then
        return;
    end;

    local u54 = u23:Clone();
    u54.Name = "bloodTemp";
    u54.Parent = u12;
    u54.Visible = true;
    local v55 = TweenService:Create(u54, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, true), {
        ImageTransparency = p53
    });
    v55.Completed:Connect(function() -- Line: 114
        -- upvalues: u54 (copy)
        u54:Destroy();
    end);
    v55:Play();
end;

local function u60(p57, p58) -- Line: 120
    -- upvalues: TweenService (copy)
    if not p57.Parent then
        return;
    end;

    local v59 = TweenInfo.new(p58 and 0.08 or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false);
    TweenService:Create(p57.Img, v59, {
        ImageTransparency = p58 and 0.5 or 1
    }):Play();
end;

local function u61() -- Line: 130
    -- upvalues: u3 (ref)
    local FloorMaterial = u3.FloorMaterial;

    if FloorMaterial then
        return (FloorMaterial == Enum.Material.Grass or FloorMaterial == Enum.Material.LeafyGrass) and "Grass" or ((FloorMaterial == Enum.Material.Snow or (FloorMaterial == Enum.Material.Sand or FloorMaterial == Enum.Material.Glacier)) and "Sand" or ((FloorMaterial == Enum.Material.Wood or FloorMaterial == Enum.Material.WoodPlanks) and "Wood" or ((FloorMaterial == Enum.Material.Metal or (FloorMaterial == Enum.Material.CorrodedMetal or FloorMaterial == Enum.Material.DiamondPlate)) and "Metal" or (FloorMaterial == Enum.Material.Mud and "Mud" or (FloorMaterial == Enum.Material.Rock and "Rock" or (FloorMaterial == Enum.Material.Air and "" or "Rock"))))));
    end;
end;

local function u76(p62) -- Line: 154
    -- upvalues: u3 (ref), u6 (ref), u5 (ref), u37 (ref), SoundModule (copy), u1 (ref), u61 (copy), u45 (copy), u44 (ref), u43 (ref)
    if not (u3 and (u3.Parent and (u6 and (u6.Parent and (u5 and u5.Parent))))) then
        return;
    end;

    if u3:GetAttribute("Downed") or u3.Health <= 0 then
        if u37 then
            SoundModule:ToggleFootstep(u1);
            u37 = nil;
        end;

        return;
    end;

    if u3.Health <= 0 then
        return;
    end;

    local HumanoidRootPart = u1:FindFirstChild("HumanoidRootPart");

    if not HumanoidRootPart then
        return;
    end;

    local v63 = u6:GetAttribute("IsSprint");
    local v64 = u6:GetAttribute("IsCrouch");
    local v65 = u5:GetAttribute("InWater");
    local v66 = u5:GetAttribute("IsUnder");
    local v67 = u61();
    local v68 = "";

    if v67 and (p62 ~= "Idle" and not (v64 or v66)) then
        if p62 == "Sit" then
            v67 = v68;
        end;
    else
        v67 = v68;
    end;

    local v69 = nil;
    local v70 = HumanoidRootPart:FindFirstChild("Footsteps" .. v67);
    local v71 = u37 ~= v70;

    if v70 then
        local v72 = u45[v67] * (v63 and 1.75 or 1);

        if math.abs(v70.PlaybackSpeed - v72) > 0.0001 then
            v69 = v72;
        end;
    end;

    if v69 and (not v71 and (u44 and u44 == u43)) then
        return;
    end;

    u44 = u43;

    if v71 and v69 then
        SoundModule:ToggleFootstep(u1, v70, v69);
    elseif v71 then
        SoundModule:ToggleFootstep(u1, v70);
    elseif v69 then
        SoundModule:ChangeSoundSpeed(v70, v69);
    end;

    local WalkWater = HumanoidRootPart:FindFirstChild("WalkWater");

    if WalkWater then
        if v65 and (p62 ~= "Idle" and p62 ~= "Sit") then
            local v73 = not WalkWater.IsPlaying;
            local v74 = 0.9 * (v63 and 1.75 or 1);
            local v75 = math.abs(WalkWater.PlaybackSpeed - v74) > 0.0001 and true or false;

            if v73 and v75 then
                SoundModule:PlaySound(WalkWater, nil, v74);
            elseif v73 then
                SoundModule:PlaySound(WalkWater);
            elseif v75 then
                SoundModule:ChangeSoundSpeed(WalkWater, v74);
            end;
        elseif WalkWater.IsPlaying then
            SoundModule:StopSound(WalkWater);
        end;
    end;

    u37 = v70;
end;

local function _(p77) -- Line: 232
    -- upvalues: u11 (ref), u36 (ref)
    local v78 = u11[p77];

    if v78 and v78.IsPlaying == false then
        v78:Play();
        u36 = p77;
    end;
end;

local function _(p79) -- Line: 241
    -- upvalues: u11 (ref), u36 (ref)
    local v80 = u11[p79];

    if v80 then
        u36 = "";
        v80:Stop();
    end;
end;

local function u93() -- Line: 250
    -- upvalues: u3 (ref), u6 (ref), u5 (ref), PreferredInputController (copy), u7 (ref), u8 (ref), u9 (ref), u36 (ref), u11 (ref), u76 (copy)
    if not (u3 and (u3.Parent and (u6 and (u6.Parent and (u5 and u5.Parent))))) then
        return;
    end;

    if u3:GetAttribute("Downed") then
        return "Down";
    end;

    local v81 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" and (u7 and u7:GetAttribute("Open") or u8 and u8:GetAttribute("Open") or u9 and u9:GetAttribute("MapOpen"));

    if v81 then
        local v82 = u36 and (u36 ~= "Idle" and u11[u36]);

        if v82 then
            u36 = "";
            v82:Stop();
        end;

        local Idle = u11.Idle;

        if Idle and Idle.IsPlaying == false then
            Idle:Play();
            u36 = "Idle";
        end;

        u76("Idle");

        return;
    end;

    local v83 = u6:GetAttributes();
    local v84 = (v83.IsCrouch and "Crouch" or "") .. (v83.IsSprint and "Sprint" or "") .. v83.Direction;
    local SeatPart = u3.SeatPart;
    local v85;

    if SeatPart == nil then
        local v86 = v84 == "Crouch" and "CrouchIdle" or v84;
        local v87 = string.find(v86, "Left");
        local v88 = string.find(v86, "Right");
        local v89;

        if v86 == "" then
            v89 = "Idle";
        elseif string.find(v86, "Sprint") then
            v89 = "Sprint" .. (v87 and "Left" or (v88 and "Right" or ""));
        else
            v89 = v87 and "Left" or (v88 and "Right" or v86);
        end;

        v85 = u5:GetAttribute("IsSwim") and (v89 == "Idle" and "SwimIdle" or "Swim") or v89;
    else
        v85 = "Sit";
    end;

    local v90 = u36 ~= v85 and u11[u36];

    if v90 then
        u36 = "";
        v90:Stop();
    end;

    local v91 = u11[v85];

    if v91 and v91.IsPlaying == false then
        v91:Play();
        u36 = v85;
    end;

    if v85 == "Sit" and (SeatPart ~= nil and (SeatPart.Name == "VehicleSeat" and SeatPart:FindFirstAncestor("Salvaged Flycopter"))) then
        local SitPilot = u11.SitPilot;

        if SitPilot and SitPilot.IsPlaying == false then
            SitPilot:Play();
            u36 = "SitPilot";
        end;
    else
        local v92 = u36 == "Sit" and v85 ~= "Sit" and u11.SitPilot;

        if v92 then
            u36 = "";
            v92:Stop();
        end;
    end;

    u76(v85);
end;

local u94 = false;

local function v118(u95) -- Line: 310
    -- upvalues: u36 (ref), u37 (ref), u38 (ref), u1 (ref), UIs (copy), PlayerGui (copy), CharacterScripts (copy), u39 (ref), u3 (ref), CurrentCamera (copy), u12 (ref), SoundModule (copy), u11 (ref), u15 (ref), u13 (ref), u20 (ref), u52 (copy), u2 (ref), u76 (copy), u94 (ref), RunService (copy), u93 (copy), u4 (ref), u24 (ref), u25 (ref), TweenService (copy), u5 (ref), u6 (ref), u7 (ref), u8 (ref), u9 (ref), u34 (copy)
    u36 = "";
    u37 = nil;
    u38 = false;
    u1 = u95;

    while not (UIs:FindFirstChild("Main") and UIs:FindFirstChild("Loading")) do
        task.wait();
    end;

    for _, child in pairs(UIs:GetChildren()) do
        child:Clone().Parent = PlayerGui;
    end;

    local v96;

    while true do
        v96 = CharacterScripts:GetChildren();

        if #v96 >= 14 then
            break;
        end;

        task.wait();
    end;

    for _, v in pairs(v96) do
        v:Clone().Parent = u95;
    end;

    for _, v in pairs(u39) do
        v:Disconnect();
    end;

    u39 = {};
    u3 = u95:WaitForChild("Humanoid");
    CurrentCamera.CameraType = Enum.CameraType.Custom;
    CurrentCamera.CameraSubject = u3;
    local v97 = u3:GetAttributeChangedSignal("Downed");
    table.insert(u39, v97:Connect(function() -- Line: 348
        -- upvalues: u12 (ref), u3 (ref), u37 (ref), SoundModule (ref), u36 (ref), u11 (ref), u15 (ref), u13 (ref), u20 (ref), CurrentCamera (ref), u52 (ref), u2 (ref)
        if not (u12 and u12.Parent) then
            return;
        end;

        local v98 = u3:GetAttribute("Downed");

        if v98 then
            if u37 then
                SoundModule:StopSound(u37);
                u37 = nil;
            end;

            local v99 = u36 and u11[u36];

            if v99 then
                u36 = "";
                v99:Stop();
            end;
        end;

        u15.Visible = v98;
        u13.Visible = not v98;
        u20.Visible = not v98;
        CurrentCamera.CameraType = v98 and Enum.CameraType.Scriptable or Enum.CameraType.Custom;
        CurrentCamera.CameraSubject = u3;

        if v98 then
            u52(u2.CFrame * CFrame.new(0, -2.5, 0), 1.2);
            local DownFall = u11.DownFall;

            if DownFall and DownFall.IsPlaying == false then
                DownFall:Play();
                u36 = "DownFall";
            end;

            task.wait(u11.DownFall.Length);
            local Down = u11.Down;

            if Down and Down.IsPlaying == false then
                Down:Play();
                u36 = "Down";
            end;
        else
            local DownFall = u11.DownFall;

            if DownFall then
                u36 = "";
                DownFall:Stop();
            end;

            local Down = u11.Down;

            if Down then
                u36 = "";
                Down:Stop();
            end;
        end;
    end));
    local v100 = u3:GetPropertyChangedSignal("FloorMaterial");
    table.insert(u39, v100:Connect(function() -- Line: 378
        -- upvalues: u76 (ref), u36 (ref)
        u76(u36);
    end));
    local v101 = u3:GetPropertyChangedSignal("SeatPart");
    table.insert(u39, v101:Connect(function() -- Line: 381
        -- upvalues: u3 (ref), u94 (ref), RunService (ref), u95 (copy), u93 (ref)
        local SeatPart = u3.SeatPart;

        if SeatPart and SeatPart.Parent then
            local u102 = nil;
            local u103 = 0;
            u94 = true;
            RunService:BindToRenderStep("VehicleHideLocalParts", Enum.RenderPriority.Last.Value, function(p104) -- Line: 387
                -- upvalues: u95 (ref), u94 (ref), RunService (ref), u102 (ref), u103 (ref)
                if not u95.Parent then
                    if u94 then
                        u94 = false;
                        RunService:UnbindFromRenderStep("VehicleHideLocalParts");
                    end;

                    return;
                end;

                if not u102 or u103 > 5 then
                    u103 = 0;
                    u102 = u95:GetDescendants();
                end;

                u103 = u103 + p104;

                for _, v in u102 do
                    if v:IsA("BasePart") and v.Parent then
                        v.LocalTransparencyModifier = 1;
                    end;
                end;
            end);
        elseif u94 then
            RunService:UnbindFromRenderStep("VehicleHideLocalParts");
            u94 = false;
        end;

        u93();
    end));

    if u94 then
        RunService:UnbindFromRenderStep("VehicleHideLocalParts");
        u94 = false;
    end;

    u11 = {};
    u2 = u95:WaitForChild("HumanoidRootPart");
    u4 = u95:WaitForChild("InteractController");
    local v105 = u4:GetAttributeChangedSignal("Reviving");
    table.insert(u39, v105:Connect(function() -- Line: 423
        -- upvalues: u12 (ref), u4 (ref), u38 (ref), u24 (ref), u25 (ref), TweenService (ref)
        if not (u12 and u12.Parent) then
            return;
        end;

        local v106 = u4:GetAttribute("Reviving");
        u4:GetAttribute("ReviveStart");

        if not u38 or v106 then
            if v106 and not u38 then
                u38 = true;
                u25.Size = UDim2.new(0, 0, 1, 0);
                local v107 = TweenService:Create(u25, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                    Size = UDim2.new(1, 0, 1, 0)
                });
                v107:Play();
                u24.Visible = true;

                repeat
                    wait();
                until not u38 and tick() - u4:GetAttribute("ReviveStart") < 4;

                v107:Cancel();
            end;

            return;
        end;

        u38 = false;
        u24.Visible = false;
    end));
    u5 = u95:WaitForChild("WaterController");
    local v108 = u5:GetAttributeChangedSignal("IsSwim");
    table.insert(u39, v108:Connect(u93));
    local v109 = u5:GetAttributeChangedSignal("InWater");
    table.insert(u39, v109:Connect(function() -- Line: 449
        -- upvalues: u76 (ref), u36 (ref)
        u76(u36);
    end));
    local v110 = u5:GetAttributeChangedSignal("IsUnder");
    table.insert(u39, v110:Connect(function() -- Line: 452
    end));
    u6 = u95:WaitForChild("StateController");
    local v111 = u6:GetAttributeChangedSignal("Direction");
    table.insert(u39, v111:Connect(u93));
    local v112 = u6:GetAttributeChangedSignal("IsSprint");
    table.insert(u39, v112:Connect(u93));
    local v113 = u6:GetAttributeChangedSignal("IsCrouch");
    table.insert(u39, v113:Connect(u93));
    u7 = u95:WaitForChild("WheelController");
    local v114 = u7:GetAttributeChangedSignal("Open");
    table.insert(u39, v114:Connect(u93));
    u8 = u95:WaitForChild("InventoryController");
    local v115 = u8:GetAttributeChangedSignal("Open");
    table.insert(u39, v115:Connect(u93));
    u9 = u95:WaitForChild("TeamNavigationController");
    local v116 = u9:GetAttributeChangedSignal("MapOpen");
    table.insert(u39, v116:Connect(u93));
    RunService.Stepped:Wait();

    if u3 and u3.Parent then
        for _, v in pairs(u34) do
            local v117 = os.clock();

            while true do
                local success, result = pcall(function() -- Line: 473
                    -- upvalues: u11 (ref), v (copy), u3 (ref)
                    u11[v.Name] = u3:LoadAnimation(v);
                end);

                if success then
                    break;
                end;

                if os.clock() - v117 >= 0.5 then
                    warn("Failed to load animation", v, result);
                    break;
                end;

                RunService.Stepped:Wait();
            end;
        end;

        local Idle = u11.Idle;

        if Idle and Idle.IsPlaying == false then
            Idle:Play();
            u36 = "Idle";
        end;
    end;
end;

local function u159(p119) -- Line: 488
    -- upvalues: u12 (ref), u16 (ref), u19 (ref), u3 (ref), u40 (ref), u33 (copy), u42 (ref), GamepadIconModule (copy), PreferredInputController (copy), u41 (ref), UserInputService (copy), u30 (ref), u26 (ref), u27 (ref), u28 (ref), u29 (ref), u31 (ref), u32 (ref), TweenUtil (copy), LocalPlayer (copy), u13 (ref), u14 (ref), u15 (ref), u17 (ref), u18 (ref), u20 (ref), u21 (ref), u22 (ref), u23 (ref), u24 (ref), u25 (ref)
    if not p119:IsA("ScreenGui") or p119.Name ~= "Main" then
        return;
    end;

    u12 = p119;
    u16 = u12:WaitForChild("Death");
    u19 = u16:WaitForChild("Footer");

    for _, child in pairs(u19:GetChildren()) do
        if child:IsA("TextButton") then
            child.MouseButton1Click:Connect(function() -- Line: 499
                -- upvalues: u3 (ref), u40 (ref), u33 (ref), child (copy)
                if u3.Health > 0 then
                    return;
                end;

                if os.clock() - u40 <= 0.2 then
                    return;
                end;

                u40 = os.clock();
                u3:SetAttribute("AttemptRespawn", true);
                u33("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "1\237\127\136\235\21i\148\247&\252\249\1\151\30Q}\144\6\250", child:GetAttribute("Index") or tonumber(child.Name));
            end);
        end;
    end;

    u42 = u19:WaitForChild("00"):WaitForChild("GamepadSelected");
    u42.Visible = false;
    GamepadIconModule.Register(u42.ImageLabel, "ButtonA");

    local function getDeadzone() -- Line: 516
        -- upvalues: PreferredInputController (ref)
        return PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225;
    end;

    local u120 = 0;
    local u121 = false;

    local function GetVisibleDeathButtons() -- Line: 520
        -- upvalues: u19 (ref)
        local v122 = {};

        for _, child in u19:GetChildren() do
            if child:IsA("TextButton") and child.Visible then
                table.insert(v122, child);
            end;
        end;

        table.sort(v122, function(p123, p124) -- Line: 527
            return p123.Name < p124.Name;
        end);

        return v122;
    end;

    local function UpdateGamepadDeathSelection(p125) -- Line: 531
        -- upvalues: u42 (ref), u41 (ref), PreferredInputController (ref), GamepadIconModule (ref)
        if not u42 then
            return;
        end;

        local v126 = p125[u41 + 1];

        if not v126 then
            return;
        end;

        u42.Parent = v126;
        local v127 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
        u42.Visible = v127;
        u42.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
    end;

    UserInputService.InputBegan:Connect(function(p128) -- Line: 539
        -- upvalues: u16 (ref), GetVisibleDeathButtons (copy), u120 (ref), u41 (ref), u42 (ref), PreferredInputController (ref), GamepadIconModule (ref), u3 (ref), u40 (ref), u33 (ref)
        if not (u16 and u16.Visible) then
            return;
        end;

        if p128.UserInputType ~= Enum.UserInputType.Gamepad1 then
            return;
        end;

        local KeyCode = p128.KeyCode;
        local v129 = GetVisibleDeathButtons();

        if #v129 == 0 then
            return;
        end;

        if KeyCode == Enum.KeyCode.DPadRight or KeyCode == Enum.KeyCode.DPadDown then
            if os.clock() - u120 < 0.15 then
                return;
            end;

            u120 = os.clock();
            u41 = (u41 - 1) % #v129;

            if not u42 then
                return;
            end;

            local v130 = v129[u41 + 1];

            if not v130 then
                return;
            end;

            u42.Parent = v130;
            local v131 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
            u42.Visible = v131;
            u42.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");

            return;
        end;

        if KeyCode ~= Enum.KeyCode.DPadLeft and KeyCode ~= Enum.KeyCode.DPadUp then
            local v132 = KeyCode == Enum.KeyCode.ButtonA and v129[u41 + 1];

            if v132 then
                if u3.Health > 0 then
                    return;
                end;

                if os.clock() - u40 <= 0.2 then
                    return;
                end;

                u40 = os.clock();
                u3:SetAttribute("AttemptRespawn", true);
                u33("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "1\237\127\136\235\21i\148\247&\252\249\1\151\30Q}\144\6\250", v132:GetAttribute("Index") or tonumber(v132.Name));
            end;

            return;
        end;

        if os.clock() - u120 < 0.15 then
            return;
        end;

        u120 = os.clock();
        u41 = (u41 + 1) % #v129;

        if not u42 then
            return;
        end;

        local v133 = v129[u41 + 1];

        if not v133 then
            return;
        end;

        u42.Parent = v133;
        local v134 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
        u42.Visible = v134;
        u42.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
    end);
    UserInputService.InputChanged:Connect(function(p135) -- Line: 570
        -- upvalues: u16 (ref), GetVisibleDeathButtons (copy), PreferredInputController (ref), u121 (ref), u41 (ref), u42 (ref), GamepadIconModule (ref)
        if not (u16 and u16.Visible) then
            return;
        end;

        if p135.UserInputType ~= Enum.UserInputType.Gamepad1 then
            return;
        end;

        if p135.KeyCode ~= Enum.KeyCode.Thumbstick1 then
            return;
        end;

        local X = p135.Position.X;
        local Y = p135.Position.Y;
        local v136 = GetVisibleDeathButtons();

        if #v136 == 0 then
            return;
        end;

        local v137 = PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225;

        if v137 < math.abs(X) or v137 < math.abs(Y) then
            if not u121 then
                u121 = true;

                if v137 < X or Y < -v137 then
                    u41 = (u41 - 1) % #v136;
                else
                    u41 = (u41 + 1) % #v136;
                end;

                if not u42 then
                    return;
                end;

                local v138 = v136[u41 + 1];

                if not v138 then
                    return;
                end;

                u42.Parent = v138;
                local v139 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
                u42.Visible = v139;
                u42.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
            end;
        else
            u121 = false;
        end;
    end);
    PreferredInputController:GetAttributeChangedSignal("PreferredInput"):Connect(function() -- Line: 596
        -- upvalues: u16 (ref), GetVisibleDeathButtons (copy), u42 (ref), u41 (ref), PreferredInputController (ref), GamepadIconModule (ref)
        if not (u16 and u16.Visible) then
            return;
        end;

        local v140 = GetVisibleDeathButtons();

        if not u42 then
            return;
        end;

        local v141 = v140[u41 + 1];

        if not v141 then
            return;
        end;

        u42.Parent = v141;
        local v142 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
        u42.Visible = v142;
        u42.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
    end);
    u30 = u12:WaitForChild("GamepadControls");
    u26 = u30:WaitForChild("DeathBar");
    u27 = u26:WaitForChild("Bar"):WaitForChild("Fill");
    u28 = u26:WaitForChild("ImageLabel");
    u29 = u30:WaitForChild("RespawnLabel");
    local u143 = UDim2.new(0.153, 0, 2.03, 0);
    local u144 = UDim2.new(0.13, 0, 1.73, 0);
    local u145 = UDim2.new(0.18, 0, 2.4, 0);
    local u146 = UDim2.new(0.236, 0, 0.0275, 0);
    local u147 = UDim2.new(0.21, 0, 0.025, 0);
    local u148 = 0;

    u31 = function() -- Line: 616
        -- upvalues: u32 (ref), u26 (ref), u27 (ref), u28 (ref), u143 (copy), u29 (ref), u3 (ref), PreferredInputController (ref)
        u32 = false;
        u26.Visible = false;
        u27.Size = UDim2.new(0, 0, 1, 0);
        u28.Size = u143;
        local v149 = u3:GetAttribute("Downed") and PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
        u29.Visible = v149;
    end;

    u3:GetAttributeChangedSignal("Downed"):Connect(function() -- Line: 625
        -- upvalues: u3 (ref), u29 (ref), PreferredInputController (ref), u32 (ref), u31 (ref)
        local v150 = u3:GetAttribute("Downed");
        local v151;

        if v150 then
            v151 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" and not u32;
        else
            v151 = v150;
        end;

        u29.Visible = v151;

        if not v150 then
            u31();
        end;
    end);
    PreferredInputController:GetAttributeChangedSignal("PreferredInput"):Connect(function() -- Line: 632
        -- upvalues: u3 (ref), u32 (ref), u29 (ref), PreferredInputController (ref)
        if u3:GetAttribute("Downed") and not u32 then
            local v152 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
            u29.Visible = v152;
        end;
    end);
    UserInputService.InputBegan:Connect(function(p153) -- Line: 639
        -- upvalues: PreferredInputController (ref), u16 (ref), u32 (ref), u29 (ref), u148 (ref), u26 (ref), u147 (copy), TweenUtil (ref), u146 (copy), u27 (ref), u28 (ref), u144 (copy), u3 (ref), u31 (ref), u143 (copy), u145 (copy), LocalPlayer (ref)
        if p153.UserInputType ~= Enum.UserInputType.Gamepad1 then
            return;
        end;

        if p153.KeyCode ~= Enum.KeyCode.ButtonR3 then
            return;
        end;

        local v154 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if not v154 then
            return;
        end;

        if u16 and u16.Visible then
            return;
        end;

        if u32 then
            return;
        end;

        u32 = true;
        u29.Visible = true;
        u148 = os.clock();
        u26.Size = u147;
        u26.Visible = true;
        TweenUtil:Tween(u26, "Size", u146, 0.3, "Back", "Out");
        u27.Size = UDim2.new(0, 0, 1, 0);
        u28.Size = u144;
        task.spawn(function() -- Line: 655
            -- upvalues: u32 (ref), u3 (ref), u31 (ref), u148 (ref), u27 (ref), u144 (ref), u143 (ref), u28 (ref), TweenUtil (ref), u145 (ref), LocalPlayer (ref)
            while u32 do
                if u3.Health <= 0 and not u3:GetAttribute("Downed") then
                    u31();

                    return;
                end;

                local v155 = (os.clock() - u148) / 3;
                local v156 = math.clamp(v155, 0, 1);
                u27.Size = UDim2.new(v156, 0, 1, 0);
                u28.Size = UDim2.new(u144.X.Scale + (u143.X.Scale - u144.X.Scale) * v156, 0, u144.Y.Scale + (u143.Y.Scale - u144.Y.Scale) * v156, 0);

                if v156 >= 1 then
                    TweenUtil:Tween(u28, "Size", u145, 0.15, "Back", "Out");
                    task.wait(0.15);
                    TweenUtil:Tween(u28, "Size", u143, 0.1, "Quad", "In");
                    task.wait(0.1);
                    local TextChatService = game:GetService("TextChatService");
                    local u157 = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("WHISPER/" .. LocalPlayer.UserId);

                    if u157 then
                        pcall(function() -- Line: 677
                            -- upvalues: u157 (copy)
                            u157:SendAsync("/kill");
                        end);
                    end;

                    u31();

                    return;
                end;

                task.wait();
            end;
        end);
    end);
    UserInputService.InputEnded:Connect(function(p158) -- Line: 689
        -- upvalues: u32 (ref), u31 (ref)
        if p158.UserInputType ~= Enum.UserInputType.Gamepad1 then
            return;
        end;

        if p158.KeyCode ~= Enum.KeyCode.ButtonR3 then
            return;
        end;

        if u32 then
            u31();
        end;
    end);
    u13 = u12:WaitForChild("Inventory");
    u14 = u12:WaitForChild("Toolbar");
    u15 = u12:WaitForChild("Down");
    u17 = u16:WaitForChild("Background");
    u18 = u16:WaitForChild("Header");
    u20 = u12:WaitForChild("Compass");
    u21 = u12:WaitForChild("Stats");
    u22 = u12:WaitForChild("Map");
    u23 = u12:WaitForChild("Blood");
    u24 = u12:WaitForChild("Revive");
    u25 = u24:WaitForChild("Fill");
end;

local function _(p160) -- Line: 712
    -- upvalues: u35 (copy)
    local v161 = 0.5 + (p160.X - u35.X) / 12800;
    local v162 = typeof(p160) == "Vector3" and p160.Z or p160.Y;

    return UDim2.new(v161, 0, 0.5 + (v162 - u35.Y) / 12800, 0);
end;

u33("Setup", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "\223\f\217\134\22\160\235-\184\154%)\166\202\182\1X\253{\23", function(p163, p164, u165) -- Line: 720
    -- upvalues: Values (copy), u33 (copy), NumberUtil (copy), Items (copy), u18 (ref), UserService (copy), Players (copy), u19 (ref), u22 (ref), u35 (copy), TweenUtil (copy), u40 (ref), u3 (ref), UserInputService (copy), CurrentCamera (copy), u2 (ref), u52 (copy), u16 (ref), u30 (ref), u29 (ref), u31 (ref), u41 (ref), u42 (ref), PreferredInputController (copy), GamepadIconModule (copy), u15 (ref), u13 (ref), u14 (ref), u20 (ref), u21 (ref), u17 (ref), u48 (copy)
    if Values.InstantRespawn.Value then
        task.wait(2);
        u33(
            "Fire",
            "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145",
            "1\237\127\136\235\21i\148\247&\252\249\1\151\30Q}\144\6\250",
            0
        );

        return;
    end;

    local v166 = NumberUtil:FormatTime(p163 or 0, "Days", "Minutes", true);
    local v167 = nil;

    if type(p164) == "number" then
        local v168 = Items[p164];

        if v168 then
            v167 = v168.Name;
            u18.KillerWeapon.Image = type(v168.Image) == "table" and v168.Image.Default or v168.Image;
            u18.KillerWeapon.Visible = true;
            u18.KillerDetail.Visible = true;
        end;
    end;

    local v169 = nil;

    if type(u165) == "number" then
        local success, result = pcall(function() -- Line: 746
            -- upvalues: UserService (ref), u165 (copy)
            return UserService:GetUserInfosByUserIdsAsync({ u165 });
        end);

        if success and result then
            local v170 = result[1];

            if v170 then
                task.defer(function() -- Line: 752
                    -- upvalues: Players (ref), u165 (copy), u18 (ref)
                    local v171 = Players:GetUserThumbnailAsync(u165, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size352x352);
                    u18.KillerCharacter.Image = v171;
                    u18.Visible = v171 ~= nil;
                end);
                local v172 = not v170.HasVerifiedBadge and "" or utf8.char(57344);

                if v170.DisplayName == v170.Username then
                    v169 = `@{v170.Username}{v172}`;
                else
                    v169 = `{v170.DisplayName}{v172}(@{v170.Username})`;
                end;
            end;
        end;
    end;

    u18.KillerName.Text = v169 or (v167 or (p164 or "Unknown"));
    u18.AliveFor.Text = v166;
    local Beds = shared.Beds;
    local v173 = 0;

    for i, v in pairs(Beds) do
        local v174 = Items[v.ID];
        local u175 = (i <= 9 and "0" or "") .. i;
        local v176 = u19:FindFirstChild(u175);

        if v176 then
            local Name = v.Name;

            if not Name then
                warn("BED NAME NOT FOUND FOR", i);
                Name = "Unnamed Bag";
            end;

            local Default = v174.Image.Default;
            v176.ImageLabel.Image = Default;
            v176.TextLabel.Text = Name;
            v176:SetAttribute("Index", v.Index);
            v176.Visible = true;
            local Position = v.Position;

            if Position then
                local u177 = u22.Frame.Map.BedTemplate:Clone();
                u177.Name = "Bed" .. u175;
                local v178 = 0.5 + (Position.X - u35.X) / 12800;
                local v179 = typeof(Position) == "Vector3" and Position.Z or Position.Y;
                u177.Position = UDim2.new(v178, 0, 0.5 + (v179 - u35.Y) / 12800, 0);
                u177.Image = Default;
                u177.BedImage.Image = Default;
                u177.BedName.Text = Name;
                u177.Parent = u22.Frame.Map;
                u177.Visible = true;
                u177.MouseEnter:Connect(function() -- Line: 794
                    -- upvalues: u177 (copy), TweenUtil (ref)
                    u177.ZIndex = 7;
                    TweenUtil:Tween(u177.BedName, { "TextTransparency", "Position" }, { 0, UDim2.new(0.5, 0, 0, 0) }, 0.25, "Quart", "Out");
                end);
                u177.MouseLeave:Connect(function() -- Line: 798
                    -- upvalues: u177 (copy), TweenUtil (ref)
                    u177.ZIndex = 3;
                    TweenUtil:Tween(u177.BedName, { "TextTransparency", "Position" }, { 1, UDim2.new(0.5, 0, 0.25, 0) }, 0.25, "Quart", "In");
                end);
                u177.Activated:Connect(function() -- Line: 802
                    -- upvalues: u40 (ref), u3 (ref), u33 (ref), v (copy), u175 (copy)
                    if os.clock() - u40 <= 0.2 then
                        return;
                    end;

                    u40 = os.clock();
                    u3:SetAttribute("AttemptRespawn", true);
                    u33("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "1\237\127\136\235\21i\148\247&\252\249\1\151\30Q}\144\6\250", v.Index or tonumber(u175));
                end);
            end;

            v173 = v173 + 1;
        end;
    end;

    u19.Grid.CellSize = UDim2.new(0.19, 0, v173 > 4 and 0.4 or 0.6, 0);
    u19.Size = UDim2.new(1, 0, v173 > 4 and 0.12 or 0.08, 0);
    local u180 = false;
    task.defer(function() -- Line: 816
        -- upvalues: u19 (ref), Beds (copy), Values (ref), u22 (ref), u180 (ref), UserInputService (ref)
        local v181 = u19;

        while v181 and (v181.Parent and u19 == v181) do
            for i, v in pairs(Beds) do
                local v182 = (i <= 9 and "0" or "") .. i;
                local v183 = math.max(v.BedTimer - (Values.ServerOS.Value - (v.LastRespawn or 0)), 0);
                local v184 = u19:FindFirstChild(v182);
                local v185 = v183 == 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(107, 107, 107);

                if v184 then
                    v184.ImageLabel.ImageColor3 = v185;
                    v184.Timer.Visible = v183 ~= 0;
                    v184.Timer.Text = v183;
                end;

                local v186 = u22.Frame.Map:FindFirstChild("Bed" .. v182);

                if v186 then
                    v186.BedImage.ImageColor3 = v185;
                    v186.Timer.Visible = v183 ~= 0;
                    v186.Timer.Text = v183;
                end;
            end;

            if u180 then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
                UserInputService.MouseIconEnabled = true;
            end;

            task.wait(0.1);
        end;

        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
    end);
    CurrentCamera.CameraType = Enum.CameraType.Scriptable;

    if u2 and u2.Parent then
        u52(u2.CFrame * CFrame.new(0, -2.5, 0), 1.2);
    end;

    u16.Visible = true;

    if u30 then
        local ToolbarLeft = u30:FindFirstChild("ToolbarLeft");
        local ToolbarRight = u30:FindFirstChild("ToolbarRight");
        local ToolTip = u30:FindFirstChild("ToolTip");

        if ToolbarLeft then
            ToolbarLeft.Visible = false;
        end;

        if ToolbarRight then
            ToolbarRight.Visible = false;
        end;

        if ToolTip then
            ToolTip.Visible = false;
        end;
    end;

    u29.Visible = false;
    u31();
    u41 = 0;

    if u42 and u19 then
        local v187 = {};

        for _, child in u19:GetChildren() do
            if child:IsA("TextButton") and child.Visible then
                table.insert(v187, child);
            end;
        end;

        table.sort(v187, function(p188, p189) -- Line: 867
            return p188.Name < p189.Name;
        end);

        if #v187 > 0 and u42 then
            u42.Parent = v187[1];
            local v190 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
            u42.Visible = v190;
            u42.ImageLabel.Image = GamepadIconModule.GetIcon("ButtonA");
        end;
    end;

    u15.Visible = false;
    u13.Visible = false;
    u14.Visible = false;
    u20.Visible = false;
    u21.Visible = false;
    task.delay(0.5, function() -- Line: 879
        -- upvalues: u2 (ref), u52 (ref)
        if not (u2 and u2.Parent) then
            return;
        end;

        u52(u2.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, -0.4363323129985824), 1);
    end);
    task.wait(1);

    if not u17.Parent then
        return;
    end;

    u48(true, 2.5);
    task.wait(2.5);

    if not u17.Parent then
        return;
    end;

    u22:SetAttribute("Locked", true);
    u22.Visible = true;
    u18.Visible = true;
    u19.Visible = true;
    u48(false, 2.5);
    CurrentCamera.CameraType = Enum.CameraType.Custom;
    u180 = true;
end);
u33("Setup", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "1\237\127\136\235\21i\148\247&\252\249\1\151\30Q}\144\6\250", function(p191, p192, p193) -- Line: 897
    -- upvalues: u56 (copy), u12 (ref), u60 (copy), CurrentCamera (copy), RunService (copy)
    u56(p191 >= 2 and (p191 <= 6 and 0.8 or (p191 <= 10 and 0.75 or (p191 <= 20 and 0.65 or (p191 <= 30 and 0.5 or 0.3)))) or nil);

    if p193 then
        if not (u12 and u12.Parent) then
            return;
        end;

        local v194 = u12.BloodMarker:Clone();
        v194.Parent = u12;

        if p192 == "Fire" then
            v194.Img.ImageColor3 = Color3.fromRGB(255, 141, 48);
        end;

        v194.Visible = true;
        u60(v194, true);
        local v195 = tick();
        local v196 = true;

        while v196 or tick() - v195 <= 0.8 do
            local CFrame2 = CurrentCamera.CFrame;
            local LookVector = CFrame2.LookVector;
            local v197 = CFrame.new(CFrame2.Position, CFrame2.Position + Vector3.new(LookVector.X, 0, LookVector.Z));
            local LookVector2 = v197.LookVector;
            local Unit = (v197.Position - p193).Unit;
            local v198 = LookVector2:Dot(Unit);
            local v199 = math.acos(v198);
            local v200 = -math.deg(v199);
            local Y = LookVector2:Cross(Unit).Y;
            v194.Rotation = v200 * math.sign(Y) + 180;

            if v196 and tick() - v195 >= 0.5 then
                u60(v194, false);
                v196 = false;
            end;

            RunService.RenderStepped:Wait();
        end;
    end;
end);
PlayerGui.ChildAdded:Connect(u159);
task.defer(function() -- Line: 947
    -- upvalues: PlayerGui (copy), u159 (copy)
    for _, child in pairs(PlayerGui:GetChildren()) do
        u159(child);
    end;
end);
local v201 = false;

while task.wait() do
    u43 = math.random(1, 1000000000);

    if not v201 then
        local Character = LocalPlayer.Character;

        if Character and Character.Parent == workspace then
            v118(Character);
            LocalPlayer.CharacterAdded:Connect(v118);
            v201 = true;
        end;
    end;
end;