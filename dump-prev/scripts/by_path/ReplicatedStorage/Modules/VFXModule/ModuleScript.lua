-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_upv_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local RunService_upv_1 = game:GetService("RunService");
local Debris_upv_1 = game:GetService("Debris");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local VFX_upv_1 = ReplicatedStorage_1:WaitForChild("VFX");
local VFX_upv_2 = workspace:WaitForChild("VFX");
local Terrain_upv_1 = workspace:WaitForChild("Terrain");
local Nodes_upv_1 = workspace:WaitForChild("Nodes");
local Animals_upv_1 = workspace:WaitForChild("Animals");
local RaycastUtil_upv_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local WeldModule_upv_1 = require(Modules_1:WaitForChild("WeldModule"));
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local ToolInfo_upv_1 = require(Modules_1:WaitForChild("ToolInfo"));
local CameraShakeModule_1 = require(Modules_1:WaitForChild("CameraShakeModule"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
local u1 = RunService_upv_1:IsClient() and (Players_upv_1.LocalPlayer);
local u2 = (not u1) or (require(Modules_1:WaitForChild("SoundModule")));
local CurrentCamera_upv_1 = workspace.CurrentCamera;
local tbl_upv_1 = {};
local tbl_upv_2 = {};
local tbl_upv_3 = {};
local u3 = 0;
local tbl_upv_4 = {};
local tbl_upv_5 = {};
local u4 = CameraShakeModule_1.new(
    Enum.RenderPriority.Camera.Value,
    function(a1)
        --[[
          line: 68
          upvalues:
            CurrentCamera_upv_1 (copy, index: 1)
        ]]
        CurrentCamera_upv_1.CFrame = CurrentCamera_upv_1.CFrame * a1;
    end
);
u4:Start();
local _ = RaycastUtil_upv_1:FilterFunction("HitIgnore");
local tbl_upv_6 = {};
tbl_upv_6.Lasers = tbl_upv_2;
tbl_upv_6.TracerSkins = {"Frosty", "Cherry Blossom", "Cyber", "Cryo", "Black Ice", "Nutcracker", "Red Relic", "Glitch", "Oni", "Vaporwave", "Anime Bloss", "Elite Bunny", "Phantom", "VIP", "Gingerbread", "Diablo", "CyberPop", "Stellark", "Medusa", "Stellark Dragon", "High Tide", "Valentine", "Blue Gem", "Monster", "Crimson Glitched", "Arcane", "Hot Rod", "Tyrant", "Independence", "Tempest", "Turbo", "Anime Waifu", "Dune"};
local tbl_upv_7 = {};
tbl_upv_7.FakeHitFunc = function(...)
    --[[
      name: FakeHitFunc
      line: 116
      upvalues:
        tbl_upv_6 (copy, index: 1)
    ]]
    tbl_upv_6:HitVFX(...);
end;
tbl_upv_7.FakeStepFunc = function(a1, a2, a3)
    --[[
      name: FakeStepFunc
      line: 119
      upvalues:
        Players_upv_1 (copy, index: 1)
        tbl_upv_3 (copy, index: 2)
        RaycastUtil_upv_1 (copy, index: 3)
        NumberUtil_upv_1 (copy, index: 4)
        VFX_upv_1 (copy, index: 5)
        VFX_upv_2 (copy, index: 6)
        Debris_upv_1 (copy, index: 7)
    ]]
    local LocalPlayer_1 = Players_upv_1.LocalPlayer;
    if (LocalPlayer_1) then
        local v1 = nil;
        if (not (tbl_upv_3[a3])) then
            v1 = LocalPlayer_1.Character;
            local v2 = nil;
            if (v1) then
                v2 = v1:FindFirstChild("Head");
                local v3;
                if (not v2) then
                    return;
                end;
                v3 = RaycastUtil_upv_1:GetClosestPointFromRay(a1, a2, v2.Position);
                if (NumberUtil_upv_1:IsWithin(v2.Position, v3, 10)) then
                    tbl_upv_3[a3] = true;
                    local v4 = VFX_upv_1.WhizzPart:Clone();
                    v4.CFrame = CFrame.new(v3);
                    v4.Parent = VFX_upv_2;
                    local v5 = v4:GetChildren();
                    v5[math.random(1, #v5)]:Play();
                    Debris_upv_1:AddItem(v4, 0.5);
                end;
            end;
        end;
    end;
end;
tbl_upv_6.HitVFX = function(a1, ...)
    --[[
      name: HitVFX
      line: 139
      upvalues:
        Players_upv_1 (copy, index: 1)
        tbl_upv_6 (copy, index: 2)
    ]]
    local tbl_8 = {...};
    local v6 = tbl_8[1];
    local time_1 = tick();
    while (v6 and not v6.Parent and tick() - time_1 < 1) do
        task.wait();
    end;
    if (not v6 or not v6.Parent) then
        return;
    end;
    if (v6.Parent.Parent) then
        local v7 = v6.Parent:FindFirstChild("Humanoid") or (v6.Parent.Parent:FindFirstChild("Humanoid"));
        local LocalPlayer_2 = Players_upv_1.LocalPlayer;
        if (v7 and LocalPlayer_2) then
            if (v7.Parent ~= LocalPlayer_2.Character and v7.Parent.Name ~= "BTR") then
                local v8 = ((typeof(tbl_8[2]) == "CFrame") and ((v6.CFrame * tbl_8[2]).Position)) or (tbl_8[2]);
                tbl_8[2] = v8;
                tbl_upv_6[(v7 and "CreateBlood") or "CreateHole"](tbl_upv_6, unpack(tbl_8));
                return;
            end;
            return;
        end;
        local v8 = ((typeof(tbl_8[2]) == "CFrame") and ((v6.CFrame * tbl_8[2]).Position)) or (tbl_8[2]);
        tbl_8[2] = v8;
        tbl_upv_6[(v7 and "CreateBlood") or "CreateHole"](tbl_upv_6, unpack(tbl_8));
    end;
end;
tbl_upv_6.FlashPart = function(a1, a2)
    --[[
      name: FlashPart
      line: 157
      upvalues:
        tbl_upv_1 (copy, index: 1)
        RunService_upv_1 (copy, index: 2)
    ]]
    local time_2 = tick();
    while (a2 and not a2.Parent and tick() - time_2 < 1) do
        task.wait();
    end;
    if (not a2 or not a2:IsDescendantOf(workspace) or a1:CheckCameraDistance(a2.Position, 1000)) then
        return;
    end;
    if (not tbl_upv_1[a2] or tick() - tbl_upv_1[a2] >= 0.08) then
        for _, value_1 in pairs(a2:GetChildren()) do
            if (value_1:IsA("Attachment")) then
                continue;
            end;
            if (not (value_1:IsA("Sound"))) then
                value_1.Enabled = true;
            end;
        end;
        task.defer(
            function()
                --[[
                  line: 170
                  upvalues:
                    a2 (copy, index: 1)
                    tbl_upv_1 (copy, index: 2)
                    RunService_upv_1 (copy, index: 3)
                ]]
                while (a2 and (a2:IsDescendantOf(workspace))) do
                    if (tick() - tbl_upv_1[a2] < 0.08) then
                        RunService_upv_1.RenderStepped:Wait();
                        continue;
                    end;
                    for _, value_2 in pairs(a2:GetChildren()) do
                        if (value_2:IsA("Attachment")) then
                            continue;
                        end;
                        if (not (value_2:IsA("Sound"))) then
                            value_2.Enabled = false;
                        end;
                    end;
                    return;
                end;
            end
        );
    end;
    tbl_upv_1[a2] = tick();
end;
tbl_upv_6.InitializeLaser = function(a1, a2)
    --[[
      name: InitializeLaser
      line: 186
      upvalues:
        u1 (copy, index: 1)
        tbl_upv_2 (copy, index: 2)
    ]]
    assert(u1, "VFXModule.InitializeLaser can currently only be called from the Client.");
    if (a2 and a2.Parent and a2.Parent.Name:find(" Lasersight")) then
        if (not (table.find(tbl_upv_2, a2))) then
            table.insert(tbl_upv_2, a2);
        end;
        return;
    else
        local time_3 = tick();
    end;
    while (a2 and not a2.Parent and tick() - time_3 < 3) do
        task.wait();
    end;
    if (a2) then
        local v9;
        if (not a2.Parent) then
            return;
        end;
        v9 = a2:WaitForChild("Attachments", 3);
        if (not v9) then
            return;
        end;
        if (v9.Parent) then
            local v10 = os.clock();
            local v11;
            v11 = nil;
            while (os.clock() - v10 < 3) do
                if (not v9.Parent) then
                    return;
                end;
                v11 = v9:FindFirstChild("Salvaged Lasersight");
                if (v11) then
                    break;
                end;
                v11 = v9:FindFirstChild("Military Lasersight");
                if (v11) then
                    break;
                else
                    task.wait();
                end;
            end;
            if (v11) then
                local v12 = nil;
                if (v11.Parent) then
                    v12 = v11:WaitForChild("Laser", 3);
                    if (v12 and v12.Parent and not (table.find(tbl_upv_2, v12))) then
                        table.insert(tbl_upv_2, v12);
                        return;
                    end;
                    return;
                end;
            end;
        end;
    end;
end;
tbl_upv_6.CreateGib = function(a1, a2, a3, a4, a5, a6)
    --[[
      name: CreateGib
      line: 219
      upvalues:
        tbl_upv_5 (copy, index: 1)
        SettingsModule_upv_1 (copy, index: 2)
        VFX_upv_2 (copy, index: 3)
    ]]
    local v13 = 0;
    local v14 = 0;
    local v15 = 0;
    local Priority_1 = nil;
    local v16 = nil;
    for key_1, value_3 in pairs(tbl_upv_5) do
        v16 = value_3.Gib;
        Priority_1 = value_3.Priority;
        if (not (v16) or not (v16.Parent)) then
            table.remove(tbl_upv_5, key_1);
            v14 = v14 + 1;
            continue;
        end;
        v13 = v13 + 1;
        if (v15 > 0) then
            continue;
        end;
        if (Priority_1 == "High") then
            v15 = key_1 - v14;
        end;
    end;
    local v17 = SettingsModule_upv_1.GetSetting("Graphics", "Max Gib Count") <= v13;
    if (v17 and v15 <= 0) then
        return;
    end;
    local u5 = a2:Clone();
    u5.Anchored = true;
    u5.Size = u5.Size * (a6 or 1);
    local v18 = Instance.new("BodyForce");
    v18.Force = Vector3.new(0, (workspace.Gravity * u5:GetMass()) * a5, 0);
    v18.Name = "AntiGravity";
    v18.Parent = u5;
    u5.Parent = VFX_upv_2;
    task.delay(
        0.1,
        function()
            --[[
              line: 246
              upvalues:
                u5 (copy, index: 1)
                a3 (copy, index: 2)
            ]]
            if (not u5 or not u5.Parent) then
                return;
            end;
            u5.CFrame = a3;
            u5.Anchored = false;
        end
    );
    local tbl_9 = {};
    tbl_9.Gib = u5;
    tbl_9.Priority = a4;
    if (v17) then
        v16 = tbl_upv_5[v15].Gib;
        if (v16 and v16.Parent) then
            v16:Destroy();
        end;
        tbl_upv_5[v15] = tbl_9;
    else
        table.insert(tbl_upv_5, tbl_9);
    end;
    return tbl_9;
end;
tbl_upv_6.HandleGibs = function(a1, a2, a3, a4, a5)
    --[[
      name: HandleGibs
      line: 271
    ]]
    a4 = a4 or 0.001;
    local time_4 = tick();
    while (true) do
        local v19, v20 = nil, nil;
        if (#a2 <= 0) then
            break;
        end;
        local v21 = tick() - time_4;
        v19 = math.clamp(v21 - (a3 - a4), 0, a4) * (1 / a4);
        for key_2, value_4 in pairs(a2) do
            v20 = value_4.Gib;
            if (not (v20) or not (v20.Parent)) then
                table.remove(a2, key_2);
                continue;
            end;
            v20.Transparency = v19;
            if (v19 >= 1) then
                v20:Destroy();
            end;
            if (not (a5)) then
                continue;
            end;
            if (a5 <= v21) then
                value_4.Priority = "High";
            end;
        end;
        if (v19 >= 1) then
            break;
        else
            task.wait();
        end;
    end;
end;
tbl_upv_6.CreateGibs = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12)
    --[[
      name: CreateGibs
      line: 297
      upvalues:
        VFX_upv_1 (copy, index: 1)
    ]]
    local v22 = VFX_upv_1[a2];
    local tbl_10 = {};
    if (v22) then
        local v23 = v22:GetChildren();
        for _ = 1, math.random(a4, a5) do
            local v24 = a3 * CFrame.Angles(math.rad(math.random(-a9, a9)), math.rad(math.random(-a7, a8)), 0);
            local v25 = (a12 and (CFrame.new(0, 0, math.random(-20, 20) / 10))) or (CFrame.new());
            local v26 = v24 * v25;
            local v27;
            v27 = a1:CreateGib(v23[math.random(1, #v23)], v26, "High", 0.5, a6);
            if (not (v27)) then
                continue;
            end;
            v25 = v27.Gib;
            v25.AssemblyLinearVelocity = (v26.LookVector * math.random(a10 * 10, a11 * 10)) / 10;
            if (a2 ~= "DigGibs" or a2 == "DigGibs") then
                v25.CanCollide = true;
                table.insert(tbl_10, v27);
            end;
        end;
    end;
    if (a12 and #tbl_10 > 0) then
        if (a1:CheckCameraDistance(a3.Position, 200)) then
            return;
        end;
        a1:HandleGibs(tbl_10, 3, 0.5);
    end;
    return tbl_10;
end;
tbl_upv_6.CreateBenchGibs = function(a1, a2, a3)
    --[[
      name: CreateBenchGibs
      line: 319
      upvalues:
        VFX_upv_1 (copy, index: 1)
        u2 (ref,  index: 2)
    ]]
    if (a3) then
        local v28;
        if (a1:CheckCameraDistance(a3.Position, 700)) then
            return;
        end;
        v28 = VFX_upv_1.BenchGibs:FindFirstChild(a2);
        if (v28) then
            local v29 = v28:Clone();
            v29:PivotTo(a3);
            local tbl_11 = {};
            local v30 = nil;
            for _, value_5 in pairs(v29:GetChildren()) do
                if (value_5:IsA("Sound")) then
                    value_5.PlaybackSpeed = value_5.PlaybackSpeed + (math.random(-50, 50) / 1000);
                    u2:PlayDuplicateSound(nil, value_5, a3.Position);
                    continue;
                end;
                if (not (value_5:IsA("BasePart"))) then
                    continue;
                end;
                v30 = a1:CreateGib(value_5, value_5.CFrame, "Low", 0.5, 0.8);
                if (v30) then
                    v30.Gib.AssemblyLinearVelocity = Vector3.new(math.random(-50, 50) / 10, math.random(-50, 50) / 10, math.random(-50, 50) / 10);
                    table.insert(tbl_11, v30);
                end;
            end;
            v29:Destroy();
            if (#tbl_11 <= 0) then
                return;
            end;
            a1:HandleGibs(tbl_11, 5, 0.25, 1);
        end;
    end;
end;
tbl_upv_6.CreateHole = function(a1, a2, a3, a4, a5, a6, a7)
    --[[
      name: CreateHole
      line: 344
      upvalues:
        Items_upv_1 (copy, index: 1)
        ToolInfo_upv_1 (copy, index: 2)
        Terrain_upv_1 (copy, index: 3)
        Nodes_upv_1 (copy, index: 4)
        Animals_upv_1 (copy, index: 5)
        VFX_upv_1 (copy, index: 6)
        VFX_upv_2 (copy, index: 7)
        SettingsModule_upv_1 (copy, index: 8)
        WeldModule_upv_1 (copy, index: 9)
        Debris_upv_1 (copy, index: 10)
    ]]
    if (a5 ~= Enum.Material.Water) then
        local v31, v31;
        if (type(a6) ~= "table") then
            v31 = false;
            if (type(a6) == "number") then
                v31 = Items_upv_1[a6];
            end;
        else
            v31 = Items_upv_1[a6.ID];
            if (not (v31)) then
                v31 = false;
                if (type(a6) == "number") then
                    v31 = Items_upv_1[a6];
                end;
            end;
        end;
        local v32 = v31 and (ToolInfo_upv_1[v31.Name]);
        local time_5 = tick();
        while (a2 and not a2.Parent and tick() - time_5 < 1) do
            task.wait();
        end;
        if (not a2 or not a2.Parent) then
            return;
        end;
        if (a3) then
            local v33 = nil;
            if (a4) then
                local v34 = a2 == Terrain_upv_1;
                v33 = CFrame.new(a3, a3 + a4);
                if (not a1:CheckCameraDistance(v33.Position, 100)) then
                    local _ = v32 and (v32.Nodes and (a2:IsDescendantOf(Nodes_upv_1)));
                    local v35 = true;
                    if (a5 ~= Enum.Material.Rock) then
                        v35 = true;
                        if (a5 ~= Enum.Material.Brick) then
                            v35 = true;
                            if (a5 ~= Enum.Material.Slate) then
                                v35 = true;
                                if (a5 ~= Enum.Material.Basalt) then
                                    v35 = true;
                                    if (a5 ~= Enum.Material.Concrete) then
                                        v35 = a5 == Enum.Material.Asphalt;
                                    end;
                                end;
                            end;
                        end;
                    end;
                    local v36 = true;
                    if (a5 ~= Enum.Material.Metal) then
                        v36 = true;
                        if (a5 ~= Enum.Material.DiamondPlate) then
                            v36 = a5 == Enum.Material.CorrodedMetal;
                        end;
                    end;
                    local v37 = true;
                    if (a5 ~= Enum.Material.Wood) then
                        v37 = a5 == Enum.Material.WoodPlanks;
                    end;
                    local v38 = true;
                    if (a5 ~= Enum.Material.Glass) then
                        v38 = a2.Name == "GlassPart";
                    end;
                    local v39 = a2:IsDescendantOf(Animals_upv_1) or (a2.Parent.Name == "Sleeper");
                    local v40 = v31 and (v31.Type == "Tool");
                    local v41 = true;
                    if (a2.Parent.Name ~= "Trash Can") then
                        v41 = a2.Parent.Name == "Oil Barrel";
                    end;
                    local v42;
                    if (v32) then
                        v42 = "Node2";
                    elseif ((v41) and (v40)) then
                        v42 = "Barrel";
                    else
                        v42 = (v36 and "Metal") or ((v37 and "Wood") or ((v38 and "Glass") or ((v34 and "Terrain") or ((v39 and "Animal") or "Default"))));
                    end;
                    local u6 = VFX_upv_1["Impact" .. v42]:Clone();
                    u6.CFrame = v33;
                    u6.Anchored = a2.Anchored;
                    u6.Parent = VFX_upv_2;
                    local v43 = nil;
                    local v44 = v33 * CFrame.Angles(0, 0, math.rad(math.random(0, 359)));
                    if (SettingsModule_upv_1.GetSetting("Graphics", "Impacts") == true) then
                        v43 = VFX_upv_1[((v36 and "Metal") or ((v38 and "Glass") or (((not v40) and "") or ((v35 and "Stone") or ((v37 and "Wood") or ((v39 and "Blood") or "Melee")))))) .. "Hole"]:Clone();
                        v43.CFrame = v44;
                        local v45 = math.random(20, 30);
                        local v46;
                        if (v40) then
                            v46 = 2;
                        elseif (v36 or v38) then
                            v46 = 1.5;
                        else
                            v46 = 1;
                        end;
                        local v47 = v45 * v46 / 100;
                        v43.Size = Vector3.new(v47, v47, v43.Size.Z);
                        v43.Anchored = a2.Anchored;
                        if (a7) then
                            v43.Decal.Transparency = 1;
                        end;
                        v43.Parent = VFX_upv_2;
                    end;
                    if (not (a2.Anchored)) then
                        WeldModule_upv_1:WeldParts(u6, a2);
                        if (v43) then
                            WeldModule_upv_1:WeldParts(v43, a2);
                        end;
                    end;
                    local v48 = nil;
                    local v49, v50 = nil, nil;
                    local v51 = nil;
                    for v53, value_6 in pairs(u6:GetChildren()) do
                        if (value_6:IsA("Sound")) then
                            value_6.PlaybackSpeed = value_6.PlaybackSpeed + (math.random(-50, 50) / 1000);
                            value_6:Play();
                            continue;
                        end;
                        value_6.Enabled = true;
                        if (value_6.Name ~= "Dirt") then
                            continue;
                        end;
                        if (not (v34) or a5) then
                            local v52 = nil;
                            if (v48) then
                                v52 = v48;
                                value_6.Color = v52;
                                v48 = v52;
                                continue;
                            end;
                            v52 = ColorSequence.new;
                            if (not (v34)) then
                                v50 = a2.Color;
                                v52 = v52(v50);
                                value_6.Color = v52;
                                v48 = v52;
                                continue;
                            end;
                            v49 = a5.Name:find("Grass") and Enum.Material.Mud or a5;
                            v50 = Terrain_upv_1:GetMaterialColor(v49);
                            if (v50) then
                                v52 = v52(v50);
                                value_6.Color = v52;
                                v48 = v52;
                                continue;
                            end;
                            v51 = Color3.fromRGB(100, 100, 100);
                            v50 = v51 or a2.Color;
                            v52 = v52(v50);
                            value_6.Color = v52;
                            v48 = v52;
                        end;
                    end;
                    local Parent_1 = a2.Parent;
                    local u7 = (v32 and (a1:CreateGibs((((Parent_1.Name == "NodeSpark") and (Parent_1.Parent)) or Parent_1).Name .. "Gibs", v44, 4, 6, 0.25, 60, 60, 60, 12.5, 17.5, false))) or {};
                    Debris_upv_1:AddItem(u6, 5);
                    if (v43) then
                        Debris_upv_1:AddItem(v43, 10);
                    end;
                    task.delay(
                        0.16,
                        function()
                            --[[
                              line: 435
                              upvalues:
                                u6 (ref, index: 1)
                                u7 (ref, index: 2)
                            ]]
                            if (u6 and u6.Parent) then
                                for _, value_7 in pairs(u6:GetChildren()) do
                                    if (not (value_7:IsA("Sound"))) then
                                        value_7.Enabled = false;
                                    end;
                                end;
                            end;
                            local time_6 = tick();
                            local _ = false;
                            while (true) do
                                local v53 = tick() - time_6;
                                local v54 = math.clamp(v53 - 2.5, 0, 0.5) * 2;
                                for v55, value_8 in pairs(u7) do
                                    local Gib_1 = value_8.Gib;
                                    if (Gib_1 and Gib_1.Parent) then
                                        Gib_1.Transparency = v54;
                                        if (v54 >= 1) then
                                            Gib_1:Destroy();
                                        end;
                                    end;
                                end;
                            end;
                        end
                    );
                end;
            end;
        end;
    end;
end;
tbl_upv_6.CreateBlood = function(a1, a2, a3)
    --[[
      name: CreateBlood
      line: 477
      upvalues:
        SettingsModule_upv_1 (copy, index: 1)
        VFX_upv_1 (copy, index: 2)
        VFX_upv_2 (copy, index: 3)
        WeldModule_upv_1 (copy, index: 4)
        Debris_upv_1 (copy, index: 5)
    ]]
    if (SettingsModule_upv_1.GetSetting("Graphics", "Blood")) then
        local time_7 = tick();
        while (a2 and not a2.Parent and tick() - time_7 < 1) do
            task.wait();
        end;
        if (not a2 or not a2.Parent) then
            return;
        end;
        if (not a1:CheckCameraDistance(a3, 500)) then
            local u8 = VFX_upv_1.BloodPart:Clone();
            u8.CFrame = CFrame.new(a3);
            u8.Anchored = false;
            u8.Parent = VFX_upv_2;
            local _ = WeldModule_upv_1:WeldParts(u8, a2);
            for v1, value_9 in pairs(u8:GetChildren()) do
                value_9.Enabled = true;
            end;
            Debris_upv_1:AddItem(u8, 2);
            task.delay(
                0.15,
                function()
                    --[[
                      line: 495
                      upvalues:
                        u8 (copy, index: 1)
                    ]]
                    if (not u8 or not u8.Parent) then
                        return;
                    end;
                    for _, value_10 in pairs(u8:GetChildren()) do
                        value_10.Enabled = false;
                    end;
                end
            );
        end;
    end;
end;
tbl_upv_6.CreateExplosion = function(a1, a2, a3, a4, a5, a6)
    --[[
      name: CreateExplosion
      line: 503
      upvalues:
        u4 (copy, index: 1)
        SettingsModule_upv_1 (copy, index: 2)
        VFX_upv_1 (copy, index: 3)
        VFX_upv_2 (copy, index: 4)
        u2 (ref,  index: 5)
        Debris_upv_1 (copy, index: 6)
    ]]
    local Position_1 = a2.Position;
    local v55, v56 = a1:CheckCameraDistance(Position_1, 1000, true);
    if (v56) then
        local v57 = math.clamp(1 - (v56 / 150), 0, 1);
        if (v57 > 0) then
            local v58 = ((SettingsModule_upv_1.GetSetting("General", "Decrease Camera Shake")) and 0.5) or 1;
            u4:ShakeOnce((v57 * 10) * (a3 or 1) * v58, 30, 0, 1.5);
        end;
    end;
    local v59 = VFX_upv_1[("Explosion%*"):format(a6 or "")];
    if (v55) then
        if (a5) then
            local v60 = v59[a5]:Clone();
            local v61 = Instance.new("Part");
            v61.Name = "ExplosionPart";
            v61.CanCollide = false;
            v61.CanQuery = false;
            v61.CanTouch = false;
            v61.Anchored = true;
            v61.Transparency = 1;
            v61.CFrame = a2;
            v61.Parent = VFX_upv_2;
            v60.Parent = v61;
            u2:ReverbSound(v60, 600, 1000);
            v60:Play();
            v60.Ended:Wait();
            v61:Destroy();
        end;
    else
        if (a6 ~= "Cursed") then
            local v62 = Instance.new("Explosion");
            v62.Name = "ExplosionEffect";
            v62.Position = Position_1;
            v62.BlastRadius = 0;
            v62.BlastPressure = 0;
            v62.Parent = VFX_upv_2;
            Debris_upv_1:AddItem(v62, 5);
        end;
        local u9 = v59:Clone();
        u9.CFrame = a2;
        u9.Parent = VFX_upv_2;
        local tbl_12 = {};
        for _, value_11 in pairs(u9:GetChildren()) do
            if (value_11:IsA("Sound")) then
                if (value_11.Name == a5) then
                    u2:ReverbSound(value_11, 600, 1000);
                    value_11:Play();
                end;
            else
                value_11.Enabled = true;
                if (value_11:IsA("ParticleEmitter")) then
                    table.insert(tbl_12, value_11);
                end;
            end;
        end;
        task.delay(
            0.15,
            function()
                --[[
                  line: 560
                  upvalues:
                    u9 (copy, index: 1)
                ]]
                if (not u9 or not u9.Parent) then
                    return;
                end;
                u9.Light.Enabled = false;
            end
        );
        task.wait(a4 or 0.45);
        if (not u9 or not u9.Parent) then
            return;
        end;
        for _, value_12 in pairs(tbl_12) do
            value_12.Enabled = false;
        end;
        task.wait(5);
        if (u9 and u9.Parent) then
            u9:Destroy();
        end;
    end;
end;
local function CreateProjectile(a1, a2)
    --[[
      name: CreateProjectile
      line: 575
      upvalues:
        RaycastUtil_upv_1 (copy, index: 1)
        tbl_upv_7 (copy, index: 2)
        VFX_upv_1 (copy, index: 3)
        VFX_upv_2 (copy, index: 4)
        u3 (ref,  index: 5)
        Debris_upv_1 (copy, index: 6)
        tbl_upv_6 (copy, index: 7)
        tbl_upv_3 (copy, index: 8)
        tbl_upv_4 (copy, index: 9)
        CreateProjectile (ref,  index: 10)
        RunService_upv_1 (copy, index: 11)
    ]]
    local u10;
    if (not a1:CheckCameraDistance(a2.Position, a2.MaxRange * 1.5)) then
        local u11 = ((type(a2.FilterFunction) == "string") and (RaycastUtil_upv_1:FilterFunction(a2.FilterFunction))) or (a2.FilterFunction);
        local u12 = ((type(a2.HitFunction) == "string") and (tbl_upv_7[a2.HitFunction])) or (a2.HitFunction);
        local u13 = ((type(a2.MissFunction) == "string") and (tbl_upv_7[a2.MissFunction])) or (a2.MissFunction);
        local u14 = ((type(a2.StepFunction) == "string") and (tbl_upv_7[a2.StepFunction])) or (a2.StepFunction);
        local u15 = ((a2.SavedVariables) and (a2.SavedVariables[1])) or (a2.Direction * a2.Speed);
        local u16 = ((a2.SavedVariables) and (a2.SavedVariables[2])) or (a2.Position);
        local u17 = ((a2.SavedVariables) and (a2.SavedVariables[3])) or 0;
        local u18 = (a2.SavedVariables and (a2.SavedVariables[4])) == true;
        local u19 = ((a2.SavedVariables) and (a2.SavedVariables[5])) or (a2.Speed);
        local u20 = ((a2.SavedVariables) and (a2.SavedVariables[6])) or (a2.Gravity);
        local u21 = ((a2.SavedVariables) and (a2.SavedVariables[7])) or (a2.MaxRange);
        local u22 = ((a2.SavedVariables) and (a2.SavedVariables[8])) or 0;
        u10 = VFX_upv_1:FindFirstChild(a2.TracerName or "");
        local u23 = nil;
        local TracerBoard_upv_1 = nil;
        local u24 = nil;
        local u25 = false;
        local u26 = false;
        local v63 = false;
        local u27 = nil;
        local u28 = nil;
        if (u10) then
            u25 = u10.Name:find("Rocket") ~= nil;
            u26 = u10.Name:find("Arrow") ~= nil;
            v63 = u10.Name == "NailBullet";
            local v64 = (u25 and (CFrame.Angles(0, -1.5707963267948966, 0))) or ((u26 and (CFrame.Angles(0, math.pi, 0))) or ((v63 and (CFrame.Angles(1.5707963267948966, 0, 0))) or (CFrame.new())));
            u10 = u10:Clone();
            if (u10.Name ~= "RifleBullet") then
                v64 = u10.Name:find("Pumpkin");
                if (v64) then
                    u27 = CFrame.Angles(math.rad(math.random(0, 359)), math.rad(math.random(0, 359)), math.rad(math.random(0, 359)));
                    u28 = CFrame.Angles(math.rad(math.random(30, 40) / 10) * ((math.random(1, 2) * 2) - 3), math.rad(math.random(30, 40) / 10) * ((math.random(1, 2) * 2) - 3), math.rad(math.random(30, 40) / 10) * ((math.random(1, 2) * 2) - 3));
                end;
            else
                u10:PivotTo((CFrame.new(a2.Position, a2.Position + a2.Direction) * CFrame.new(0, 0, -2)) * v64);
            end;
            u10.Parent = VFX_upv_2;
            u23 = u10.PrimaryPart:FindFirstChildOfClass("Trail");
            TracerBoard_upv_1 = u10.PrimaryPart:FindFirstChild("TracerBoard");
            if (u25) then
                u10.PrimaryPart.RocketFly:Play();
            end;
            u24 = v64;
        end;
        local u29 = false;
        local Magnitude_upv_1 = nil;
        local u30 = nil;
        u3 = ((u3 < 10000) and (u3 + 1)) or 1;
        local u31 = u3;
        local SaveVariables_upv_1 = a2.SaveVariables;
        local v65 = function(a3)
            --[[
              line: 626
              upvalues:
                a2 (copy, index: 1)
                u29 (ref,  index: 2)
                u22 (ref,  index: 3)
                SaveVariables_upv_1 (copy, index: 4)
                Magnitude_upv_1 (ref,  index: 5)
                u19 (ref,  index: 6)
                u17 (ref,  index: 7)
                u21 (ref,  index: 8)
                u15 (ref,  index: 9)
                u16 (ref,  index: 10)
                RaycastUtil_upv_1 (copy, index: 11)
                u11 (copy, index: 12)
                u18 (ref,  index: 13)
                u10 (ref,  index: 14)
                u24 (ref,  index: 15)
                u27 (ref,  index: 16)
                u28 (ref,  index: 17)
                u23 (ref,  index: 18)
                TracerBoard_upv_1 (ref,  index: 19)
                Debris_upv_1 (copy, index: 20)
                u14 (copy, index: 21)
                u31 (copy, index: 22)
                u20 (ref,  index: 23)
                u30 (ref,  index: 24)
                u12 (copy, index: 25)
                u26 (ref,  index: 26)
                u25 (ref,  index: 28)
                tbl_upv_6 (copy, index: 29)
            ]]
            a3 = a2.Instant or a3;
            local v66 = nil;
            local v67, v68 = nil, nil;
            while (true) do
                local v69, v70, v71 = nil, nil, nil;
                if (u29) then
                    break;
                end;
                u22 = u22 + 1;
                if (SaveVariables_upv_1) then
                    SaveVariables_upv_1[8] = u22;
                end;
                v67 = false;
                if (u22 == 1) then
                    v67 = a2.PositionFirst ~= nil;
                end;
                if (v67) then
                    Magnitude_upv_1 = (a2.Position - a2.PositionFirst).Magnitude;
                end;
                local v72 = math.min(u17 + ((v67 and Magnitude_upv_1) or (u19 * a3)), u21) - u17;
                local v73 = (v67 and (a2.DirectionFirst)) or (u15.Unit);
                if (v67) then
                    v69 = a2.PositionFirst;
                end;
                if (a2.Size) then
                    v68 = {};
                    v68.Position = v69;
                    v68.Size = a2.Size;
                    if (not (v68)) then
                        v68 = v69;
                    end;
                else
                    v68 = v69;
                end;
                local v74, v75, v76, v77, v78 = RaycastUtil_upv_1:Raycast(v68, v73 * v72, a2.FilterType, a2.Filters, a2.VisualizeRay, u11, u18);
                local Magnitude_2 = (v75 - v69).Magnitude;
                if (u10 and not (v67)) then
                    local v79 = CFrame.new(v75, v69) * CFrame.new(0, 0, Magnitude_2 / -1.2);
                    local v80 = u27 or (CFrame.new());
                    v66 = v79 * u24 * v80;
                end;
                u27 = u27 and (u27:Lerp(u27 * u28, a3 / 0.016666666666666666));
                if (u23) then
                    u23.Enabled = not v67;
                end;
                u17 = math.min(u17 + Magnitude_2, u21);
                if (SaveVariables_upv_1) then
                    SaveVariables_upv_1[3] = u17;
                end;
                if (TracerBoard_upv_1) then
                    TracerBoard_upv_1.Circle.ImageTransparency = math.clamp((u17 - (a2.MaxRange * 0.6)) / (a2.MaxRange * 0.4), 0, 1);
                end;
                if (v78) then
                    Debris_upv_1:AddItem(v78, 5);
                end;
                if (u14 and type(u14) == "function") then
                    v70 = u14(v69, v75, u31);
                    if (v70) then
                        u29 = true;
                    end;
                end;
                if (v74) then
                    if (v77 ~= Enum.Material.Water or u18) then
                        u30 = true;
                        u29 = true;
                        if (u12) then
                            v71 = u26;
                            u12(v74, v75, v76, v77, nil, v71);
                        end;
                    else
                        u18 = true;
                        u17 = 0;
                        u20 = math.max(u20 + 0.25, 1);
                        u19 = u19 * 0.08;
                        u21 = math.clamp(a2.MaxRange / 50, 10, 25);
                        if (SaveVariables_upv_1) then
                            SaveVariables_upv_1[3] = u17;
                            SaveVariables_upv_1[4] = u18;
                            SaveVariables_upv_1[5] = u19;
                            SaveVariables_upv_1[6] = u20;
                            SaveVariables_upv_1[7] = u21;
                        end;
                    end;
                elseif (not (v67) and u22 > 1) then
                    u15 = u15 - (Vector3.new(0, 196.2 * u20, 0) * a3);
                    u16 = v75;
                    if (SaveVariables_upv_1) then
                        SaveVariables_upv_1[1] = u15;
                        SaveVariables_upv_1[2] = u16;
                    end;
                end;
                if (math.abs(u21 - u17) <= 1) then
                    u29 = true;
                end;
                if (u29 and u10) then
                    if (u25 or u10.Name == "PumpkinCursed") then
                        u10.PrimaryPart.Transparency = 1;
                        for _, value_13 in pairs(u10.PrimaryPart:GetChildren()) do
                            if (value_13:IsA("Sound")) then
                                value_13:Stop();
                            else
                                value_13.Enabled = false;
                            end;
                        end;
                        Debris_upv_1:AddItem(u10, 3);
                    elseif (u10.Name ~= "PumpkinRegular") then
                        u10:Destroy();
                    else
                        task.defer(tbl_upv_6.CreateBenchGibs, tbl_upv_6, "Pumpkin", v66);
                    end;
                    v66 = nil;
                end;
                if (not (a2.Instant)) then
                    break;
                end;
            end;
            if (v66) then
                return u29, u10.PrimaryPart, v66;
            end;
            return u29;
        end;
        if (a2.Instant) then
            v65();
            tbl_upv_3[u31] = nil;
            if (not (u30) and u13) then
                u13();
            end;
        else
            table.insert(
                tbl_upv_4,
                {
                    StepFunction = v65,
                    FinishFunction = function()
                        --[[
                          line: 766
                          upvalues:
                            tbl_upv_3 (copy, index: 1)
                            u31 (copy, index: 2)
                            u30 (ref,  index: 3)
                            u13 (copy, index: 4)
                        ]]
                        tbl_upv_3[u31] = nil;
                        if ((u30) or not u13) then
                            return;
                        end;
                        u13();
                    end,
                    Parameters = a2
                }
            );
            if (not (CreateProjectile) or not (CreateProjectile.Connected)) then
                CreateProjectile = RunService_upv_1.Heartbeat:Connect(
                    function(a4)
                        --[[
                          line: 783
                          upvalues:
                            tbl_upv_4 (copy, index: 1)
                            CreateProjectile (ref,  index: 2)
                        ]]
                        local tbl_upv_13 = {};
                        local tbl_upv_14 = {};
                        local u32 = nil;
                        local success_1 = nil;
                        local v81 = nil;
                        for key_3, value_upv_14 in pairs(tbl_upv_4) do
                            u32 = false;
                            success_1, v81 = pcall(
                                function()
                                    --[[
                                      line: 787
                                      upvalues:
                                        value_upv_14 (copy, index: 1)
                                        u32 (ref,  index: 2)
                                        a4 (copy, index: 3)
                                        tbl_upv_13 (copy, index: 4)
                                        tbl_upv_14 (copy, index: 5)
                                    ]]
                                    local v82 = nil;
                                    if (value_upv_14.Parameters.Terminate) then
                                        u32 = true;
                                    else
                                        local v83, v82, v84 = value_upv_14.StepFunction(a4);
                                        if (v82) then
                                            table.insert(tbl_upv_13, v82);
                                            table.insert(tbl_upv_14, v84);
                                        end;
                                        if (not v83) then
                                            return;
                                        end;
                                        value_upv_14.FinishFunction();
                                        u32 = true;
                                    end;
                                end
                            );
                            if (not (success_1) or u32) then
                                if (not (success_1)) then
                                    warn(v81, " - BULLET CALCULATION ERROR");
                                end;
                                table.remove(tbl_upv_4, key_3);
                            end;
                        end;
                        if (#tbl_upv_13 > 0) then
                            workspace:BulkMoveTo(tbl_upv_13, tbl_upv_14, Enum.BulkMoveMode.FireCFrameChanged);
                        end;
                        if (#tbl_upv_4 > 0) then
                            return;
                        end;
                        CreateProjectile:Disconnect();
                        CreateProjectile = nil;
                    end
                );
            end;
        end;
    end;
end;
tbl_upv_6.CreateProjectile = CreateProjectile;
tbl_upv_6.CheckCameraDistance = function(a1, a2, a3, a4)
    --[[
      name: CheckCameraDistance
      line: 820
      upvalues:
        Players_upv_1 (copy, index: 1)
        CurrentCamera_upv_1 (copy, index: 2)
        NumberUtil_upv_1 (copy, index: 3)
    ]]
    if (not Players_upv_1.LocalPlayer) then
        return;
    end;
    if (CurrentCamera_upv_1) then
        local Position_2 = CurrentCamera_upv_1.CFrame.Position;
        if (a4) then
            local Magnitude_3 = (Position_2 - a2).Magnitude;
            return a3 < Magnitude_3, Magnitude_3;
        else
            local v85, v86 = NumberUtil_upv_1:IsWithin(Position_2, a2, a3);
            return not v85, v86;
        end;
    else
        return true;
    end;
end;
return tbl_upv_6;