-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local VFX = ReplicatedStorage:WaitForChild("VFX");
local VFX2 = workspace:WaitForChild("VFX");
local Terrain = workspace:WaitForChild("Terrain");
local Nodes = workspace:WaitForChild("Nodes");
local Animals = workspace:WaitForChild("Animals");
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local WeldModule = require(Modules:WaitForChild("WeldModule"));
local Items = require(Modules:WaitForChild("Items"));
local ToolInfo = require(Modules:WaitForChild("ToolInfo"));
local CameraShakeModule = require(Modules:WaitForChild("CameraShakeModule"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local u1 = nil;
local u2 = RunService:IsClient() and Players.LocalPlayer;

if u2 then
    u1 = require(Modules:WaitForChild("SoundModule"));
end;

local CurrentCamera = workspace.CurrentCamera;
local u3 = {};
local u4 = {};
local u5 = {};
local u6 = 0;
local u7 = nil;
local u8 = {};
local u9 = {};
local u12 = CameraShakeModule.new(Enum.RenderPriority.Camera.Value, function(p10) -- Line: 68
    -- upvalues: CurrentCamera (copy)
    local v11 = CurrentCamera;
    v11.CFrame = v11.CFrame * p10;
end);
u12:Start();
RaycastUtil:FilterFunction("HitIgnore");
local u13 = {
    Lasers = u4,
    TracerSkins = { "Frosty", "Cherry Blossom", "Cyber", "Cryo", "Black Ice", "Nutcracker", "Red Relic", "Glitch", "Oni", "Vaporwave", "Anime Bloss", "Elite Bunny", "Phantom", "VIP", "Gingerbread", "Diablo", "CyberPop", "Stellark", "Medusa", "Stellark Dragon", "High Tide", "Valentine", "Blue Gem", "Monster", "Crimson Glitched", "Arcane", "Hot Rod", "Tyrant", "Independence", "Tempest", "Turbo", "Anime Waifu", "Dune" }
};
local u20 = {
    FakeHitFunc = function(...) -- Line: 116, Name: FakeHitFunc
        -- upvalues: u13 (copy)
        u13:HitVFX(...);
    end,

    FakeStepFunc = function(p14, p15, p16) -- Line: 119, Name: FakeStepFunc
        -- upvalues: Players (copy), u5 (copy), RaycastUtil (copy), NumberUtil (copy), VFX (copy), VFX2 (copy), Debris (copy)
        local LocalPlayer = Players.LocalPlayer;

        if not LocalPlayer or u5[p16] then
            return;
        end;

        local Character = LocalPlayer.Character;

        if not Character then
            return;
        end;

        local Head = Character:FindFirstChild("Head");

        if not Head then
            return;
        end;

        local v17 = RaycastUtil:GetClosestPointFromRay(p14, p15, Head.Position);

        if NumberUtil:IsWithin(Head.Position, v17, 10) then
            u5[p16] = true;
            local v18 = VFX.WhizzPart:Clone();
            v18.CFrame = CFrame.new(v17);
            v18.Parent = VFX2;
            local v19 = v18:GetChildren();
            v19[math.random(1, #v19)]:Play();
            Debris:AddItem(v18, 0.5);
        end;
    end
};

function u13.HitVFX(p21, ...) -- Line: 139
    -- upvalues: Players (copy), u13 (copy)
    local v22 = { ... };
    local v23 = v22[1];
    local v24 = tick();

    while v23 and (not v23.Parent and tick() - v24 < 1) do
        task.wait();
    end;

    if not (v23 and (v23.Parent and v23.Parent.Parent)) then
        return;
    end;

    local v25 = v23.Parent:FindFirstChild("Humanoid") or v23.Parent.Parent:FindFirstChild("Humanoid");
    local LocalPlayer = Players.LocalPlayer;

    if v25 and (LocalPlayer and (v25.Parent == LocalPlayer.Character or v25.Parent.Name == "BTR")) then
        return;
    end;

    v22[2] = typeof(v22[2]) == "CFrame" and (v23.CFrame * v22[2]).Position or v22[2];
    u13[v25 and "CreateBlood" or "CreateHole"](u13, unpack(v22));
end;

function u13.FlashPart(p26, u27) -- Line: 157
    -- upvalues: u3 (copy), RunService (copy)
    local v28 = tick();

    while u27 and (not u27.Parent and tick() - v28 < 1) do
        task.wait();
    end;

    if not (u27 and u27:IsDescendantOf(workspace)) then
        return;
    end;

    if p26:CheckCameraDistance(u27.Position, 1000) then
        return;
    end;

    if not u3[u27] or tick() - u3[u27] >= 0.08 then
        for _, child in pairs(u27:GetChildren()) do
            if not (child:IsA("Attachment") or child:IsA("Sound")) then
                child.Enabled = true;
            end;
        end;

        task.defer(function() -- Line: 170
            -- upvalues: u27 (copy), u3 (ref), RunService (ref)
            while u27 and u27:IsDescendantOf(workspace) do
                if tick() - u3[u27] >= 0.08 then
                    for _, child in pairs(u27:GetChildren()) do
                        if not (child:IsA("Attachment") or child:IsA("Sound")) then
                            child.Enabled = false;
                        end;
                    end;

                    return;
                end;

                RunService.RenderStepped:Wait();
            end;
        end);
    end;

    u3[u27] = tick();
end;

function u13.InitializeLaser(p29, p30) -- Line: 186
    -- upvalues: u2 (copy), u4 (copy)
    assert(u2, "VFXModule.InitializeLaser can currently only be called from the Client.");

    if p30 and (p30.Parent and p30.Parent.Name:find(" Lasersight")) then
        if not table.find(u4, p30) then
            table.insert(u4, p30);
        end;

        return;
    end;

    local v31 = tick();

    while p30 and (not p30.Parent and tick() - v31 < 3) do
        task.wait();
    end;

    if not (p30 and p30.Parent) then
        return;
    end;

    local Attachments = p30:WaitForChild("Attachments", 3);

    if not (Attachments and Attachments.Parent) then
        return;
    end;

    local v32 = os.clock();
    local v33 = nil;

    while os.clock() - v32 < 3 do
        if not Attachments.Parent then
            return;
        end;

        v33 = Attachments:FindFirstChild("Salvaged Lasersight") or Attachments:FindFirstChild("Military Lasersight");

        if v33 then
            break;
        end;

        task.wait();
    end;

    if not (v33 and v33.Parent) then
        return;
    end;

    local Laser = v33:WaitForChild("Laser", 3);

    if not Laser or (not Laser.Parent or table.find(u4, Laser)) then
        return;
    end;

    table.insert(u4, Laser);
end;

function u13.CreateGib(p34, p35, u36, p37, p38, p39) -- Line: 219
    -- upvalues: u9 (copy), SettingsModule (copy), VFX2 (copy)
    local v40 = 0;
    local v41 = 0;
    local v42 = 0;
    local v43 = p39 or 1;

    for i, v in pairs(u9) do
        local Gib = v.Gib;
        local Priority = v.Priority;

        if Gib and Gib.Parent then
            v40 = v40 + 1;

            if v41 <= 0 and Priority == "High" then
                v41 = i - v42;
            end;
        else
            table.remove(u9, i);
            v42 = v42 + 1;
        end;
    end;

    local v44 = SettingsModule.GetSetting("Graphics", "Max Gib Count") <= v40;

    if not v44 or v41 > 0 then
        local u45 = p35:Clone();
        u45.Anchored = true;
        u45.Size = u45.Size * v43;
        local BodyForce = Instance.new("BodyForce");
        local v46 = workspace.Gravity * u45:GetMass() * p38;
        BodyForce.Force = Vector3.new(0, v46, 0);
        BodyForce.Name = "AntiGravity";
        BodyForce.Parent = u45;
        u45.Parent = VFX2;
        task.delay(0.1, function() -- Line: 246
            -- upvalues: u45 (copy), u36 (copy)
            if not (u45 and u45.Parent) then
                return;
            end;

            u45.CFrame = u36;
            u45.Anchored = false;
        end);
        local v47 = {
            Gib = u45,
            Priority = p37
        };

        if not v44 then
            table.insert(u9, v47);

            return v47;
        end;

        local Gib = u9[v41].Gib;

        if Gib and Gib.Parent then
            Gib:Destroy();
        end;

        u9[v41] = v47;

        return v47;
    end;
end;

function u13.HandleGibs(p48, p49, p50, p51, p52) -- Line: 271
    local v53 = tick();
    local v54 = p51 or 0.001;

    while #p49 > 0 do
        local v55 = tick() - v53;
        local v56 = math.clamp(v55 - (p50 - v54), 0, v54) * (1 / v54);

        for i, v in pairs(p49) do
            local Gib = v.Gib;

            if Gib and Gib.Parent then
                Gib.Transparency = v56;

                if v56 >= 1 then
                    Gib:Destroy();
                end;

                if p52 and p52 <= v55 then
                    v.Priority = "High";
                end;
            else
                table.remove(p49, i);
            end;
        end;

        if v56 >= 1 then
            break;
        end;

        task.wait();
    end;
end;

function u13.CreateGibs(p57, p58, p59, p60, p61, p62, p63, p64, p65, p66, p67, p68) -- Line: 297
    -- upvalues: VFX (copy)
    local v69 = VFX[p58];
    local v70 = {};

    if v69 then
        local v71 = v69:GetChildren();

        for _ = 1, math.random(p60, p61) do
            local Angles = CFrame.Angles;
            local v72 = math.random(-p65, p65);
            local v73 = math.rad(v72);
            local v74 = math.random(-p63, p64);
            local v75 = p59 * Angles(v73, math.rad(v74), 0) * (p68 and CFrame.new(0, 0, math.random(-20, 20) / 10) or CFrame.new());
            local v76 = p57:CreateGib(v71[math.random(1, #v71)], v75, "High", 0.5, p62);

            if v76 then
                local Gib = v76.Gib;
                Gib.AssemblyLinearVelocity = v75.LookVector * math.random(p66 * 10, p67 * 10) / 10;
                Gib.CanCollide = p58 ~= "DigGibs";
                table.insert(v70, v76);
            end;
        end;
    end;

    if p68 and #v70 > 0 then
        if p57:CheckCameraDistance(p59.Position, 200) then
            return;
        end;

        p57:HandleGibs(v70, 3, 0.5);
    end;

    return v70;
end;

function u13.CreateBenchGibs(p77, p78, p79) -- Line: 319
    -- upvalues: VFX (copy), u1 (ref)
    if not p79 or p77:CheckCameraDistance(p79.Position, 700) then
        return;
    end;

    local v80 = VFX.BenchGibs:FindFirstChild(p78);

    if not v80 then
        return;
    end;

    local v81 = v80:Clone();
    v81:PivotTo(p79);
    local v82 = {};

    for _, child in pairs(v81:GetChildren()) do
        if child:IsA("Sound") then
            child.PlaybackSpeed = child.PlaybackSpeed + math.random(-50, 50) / 1000;
            u1:PlayDuplicateSound(nil, child, p79.Position);
        elseif child:IsA("BasePart") then
            local v83 = p77:CreateGib(child, child.CFrame, "Low", 0.5, 0.8);

            if v83 then
                local Gib = v83.Gib;
                local v84 = math.random(-50, 50) / 10;
                local v85 = math.random(-50, 50) / 10;
                local v86 = math.random(-50, 50) / 10;
                Gib.AssemblyLinearVelocity = Vector3.new(v84, v85, v86);
                table.insert(v82, v83);
            end;
        end;
    end;

    v81:Destroy();

    if #v82 <= 0 then
        return;
    end;

    p77:HandleGibs(v82, 5, 0.25, 1);
end;

function u13.CreateHole(p87, u88, p89, p90, p91, p92, p93) -- Line: 344
    -- upvalues: Items (copy), ToolInfo (copy), Terrain (copy), Nodes (copy), Animals (copy), VFX (copy), VFX2 (copy), SettingsModule (copy), WeldModule (copy), Debris (copy)
    if p91 == Enum.Material.Water then
        return;
    end;

    local v94 = type(p92) == "table" and Items[p92.ID];

    if not v94 then
        if type(p92) == "number" then
            v94 = Items[p92];
        else
            v94 = false;
        end;
    end;

    local v95;

    if v94 then
        v95 = ToolInfo[v94.Name];
    else
        v95 = v94;
    end;

    if v95 then
        v95 = v95.ObjectDamages;
    end;

    local v96 = tick();

    while u88 and (not u88.Parent and tick() - v96 < 1) do
        task.wait();
    end;

    if not (u88 and (u88.Parent and (p89 and p90))) then
        return;
    end;

    local v97 = u88 == Terrain;
    local v98 = CFrame.new(p89, p89 + p90);

    if p87:CheckCameraDistance(v98.Position, 100) then
        return;
    end;

    local v99 = v95 and v95.Nodes and u88:IsDescendantOf(Nodes);
    local v100 = (p91 == Enum.Material.Rock or (p91 == Enum.Material.Brick or (p91 == Enum.Material.Slate or (p91 == Enum.Material.Basalt or p91 == Enum.Material.Concrete)))) and true or p91 == Enum.Material.Asphalt;
    local v101 = (p91 == Enum.Material.Metal or p91 == Enum.Material.DiamondPlate) and true or p91 == Enum.Material.CorrodedMetal;
    local v102 = p91 == Enum.Material.Wood and true or p91 == Enum.Material.WoodPlanks;
    local v103 = p91 == Enum.Material.Glass and true or u88.Name == "GlassPart";
    local v104 = u88:IsDescendantOf(Animals) or u88.Parent.Name == "Sleeper";

    if v94 then
        v94 = v94.Type == "Tool";
    end;

    local u105 = VFX["Impact" .. (v99 and "Node2" or ((u88.Parent.Name == "Trash Can" and true or u88.Parent.Name == "Oil Barrel") and v94 and "Barrel" or (v101 and "Metal" or (v102 and "Wood" or (v103 and "Glass" or (v97 and "Terrain" or (v104 and "Animal" or "Default")))))))]:Clone();
    u105.CFrame = v98;
    u105.Anchored = u88.Anchored;
    u105.Parent = VFX2;
    local Angles = CFrame.Angles;
    local v106 = math.random(0, 359);
    local v107 = v98 * Angles(0, 0, (math.rad(v106)));
    local u108;

    if SettingsModule.GetSetting("Graphics", "Impacts") == true then
        u108 = VFX[(v101 and "Metal" or (v103 and "Glass" or (v94 and (v100 and "Stone" or (v102 and "Wood" or (v104 and "Blood" or "Melee"))) or ""))) .. "Hole"]:Clone();
        u108.CFrame = v107;
        local v109 = math.random(20, 30) * (v94 and 2 or ((v101 or v103) and 1.5 or 1)) / 100;
        u108.Size = Vector3.new(v109, v109, u108.Size.Z);
        u108.Anchored = u88.Anchored;

        if p93 then
            u108.Decal.Transparency = 1;
        end;

        u108.Parent = VFX2;
    else
        u108 = nil;
    end;

    if not u88.Anchored then
        WeldModule:WeldParts(u105, u88);

        if u108 then
            WeldModule:WeldParts(u108, u88);
        end;
    end;

    local v110 = nil;

    for _, child in pairs(u105:GetChildren()) do
        if child:IsA("Sound") then
            child.PlaybackSpeed = child.PlaybackSpeed + math.random(-50, 50) / 1000;
            child:Play();
        else
            child.Enabled = true;

            if child.Name == "Dirt" and (not v97 or p91) then
                if not v110 then
                    local new = ColorSequence.new;
                    local v111;

                    if v97 then
                        local v112;

                        if p91.Name:find("Grass") then
                            v112 = Enum.Material.Mud or p91;
                        else
                            v112 = p91;
                        end;

                        v111 = Terrain:GetMaterialColor(v112) or Color3.fromRGB(100, 100, 100) or u88.Color;
                    else
                        v111 = u88.Color;
                    end;

                    v110 = new(v111);
                end;

                child.Color = v110;
            end;
        end;
    end;

    local Parent = u88.Parent;

    if Parent.Name == "NodeSpark" then
        Parent = Parent.Parent or Parent;
    end;

    local u113 = v99 and p87:CreateGibs(Parent.Name .. "Gibs", v107, 4, 6, 0.25, 60, 60, 60, 12.5, 17.5, false) or {};
    Debris:AddItem(u105, 5);

    if u108 then
        Debris:AddItem(u108, 10);
    end;

    task.delay(0.16, function() -- Line: 435
        -- upvalues: u105 (ref), u113 (ref), u108 (ref), u88 (copy), VFX2 (ref)
        if u105 and u105.Parent then
            for _, child in pairs(u105:GetChildren()) do
                if not child:IsA("Sound") then
                    child.Enabled = false;
                end;
            end;
        end;

        local v114 = tick();
        local v115 = false;

        while true do
            local v116 = tick() - v114;
            local v117 = math.clamp(v116 - 2.5, 0, 0.5) * 2;

            for _, v in pairs(u113) do
                local Gib = v.Gib;

                if Gib and Gib.Parent then
                    Gib.Transparency = v117;

                    if v117 >= 1 then
                        Gib:Destroy();
                    end;
                end;
            end;

            if v117 >= 1 then
                u113 = {};
            end;

            v115 = not (u108 and u108.Parent) and true or v115;

            if not v115 and (v116 >= 10 or (u88 == nil or (u88.Parent == nil or (u88.Parent:IsDescendantOf(VFX2) or u88.Transparency >= 1 and not u88.CanCollide)))) then
                if u108 then
                    u108:Destroy();
                    v115 = true;
                else
                    v115 = true;
                end;
            end;

            if #u113 <= 0 and v115 then
                return;
            end;

            task.wait();
        end;
    end);
end;

function u13.CreateBlood(p118, p119, p120) -- Line: 477
    -- upvalues: SettingsModule (copy), VFX (copy), VFX2 (copy), WeldModule (copy), Debris (copy)
    if not SettingsModule.GetSetting("Graphics", "Blood") then
        return;
    end;

    local v121 = tick();

    while p119 and (not p119.Parent and tick() - v121 < 1) do
        task.wait();
    end;

    if not (p119 and p119.Parent) then
        return;
    end;

    if p118:CheckCameraDistance(p120, 500) then
        return;
    end;

    local u122 = VFX.BloodPart:Clone();
    u122.CFrame = CFrame.new(p120);
    u122.Anchored = false;
    u122.Parent = VFX2;
    WeldModule:WeldParts(u122, p119);

    for _, child in pairs(u122:GetChildren()) do
        child.Enabled = true;
    end;

    Debris:AddItem(u122, 2);
    task.delay(0.15, function() -- Line: 495
        -- upvalues: u122 (copy)
        if not (u122 and u122.Parent) then
            return;
        end;

        for _, child in pairs(u122:GetChildren()) do
            child.Enabled = false;
        end;
    end);
end;

function u13.CreateExplosion(p123, p124, p125, p126, p127, p128) -- Line: 503
    -- upvalues: u12 (copy), SettingsModule (copy), VFX (copy), VFX2 (copy), u1 (ref), Debris (copy)
    local v129 = p125 or 1;
    local Position = p124.Position;
    local v130, v131 = p123:CheckCameraDistance(Position, 1000, true);

    if v131 then
        local v132 = math.clamp(1 - v131 / 150, 0, 1);

        if v132 > 0 then
            u12:ShakeOnce(v132 * 10 * v129 * (SettingsModule.GetSetting("General", "Decrease Camera Shake") and 0.5 or 1), 30, 0, 1.5);
        end;
    end;

    local v133 = VFX[`Explosion{p128 or ""}`];

    if v130 then
        if p127 then
            local v134 = v133[p127]:Clone();
            local Part = Instance.new("Part");
            Part.Name = "ExplosionPart";
            Part.CanCollide = false;
            Part.CanQuery = false;
            Part.CanTouch = false;
            Part.Anchored = true;
            Part.Transparency = 1;
            Part.CFrame = p124;
            Part.Parent = VFX2;
            v134.Parent = Part;
            u1:ReverbSound(v134, 600, 1000);
            v134:Play();
            v134.Ended:Wait();
            Part:Destroy();
        end;

        return;
    end;

    if p128 ~= "Cursed" then
        local Explosion = Instance.new("Explosion");
        Explosion.Name = "ExplosionEffect";
        Explosion.Position = Position;
        Explosion.BlastRadius = 0;
        Explosion.BlastPressure = 0;
        Explosion.Parent = VFX2;
        Debris:AddItem(Explosion, 5);
    end;

    local u135 = v133:Clone();
    u135.CFrame = p124;
    u135.Parent = VFX2;
    local v136 = {};

    for _, child in pairs(u135:GetChildren()) do
        if child:IsA("Sound") then
            if child.Name == p127 then
                u1:ReverbSound(child, 600, 1000);
                child:Play();
            end;
        else
            child.Enabled = true;

            if child:IsA("ParticleEmitter") then
                table.insert(v136, child);
            end;
        end;
    end;

    task.delay(0.15, function() -- Line: 560
        -- upvalues: u135 (copy)
        if not (u135 and u135.Parent) then
            return;
        end;

        u135.Light.Enabled = false;
    end);
    task.wait(p126 or 0.45);

    if not (u135 and u135.Parent) then
        return;
    end;

    for _, v in pairs(v136) do
        v.Enabled = false;
    end;

    task.wait(5);

    if u135 and u135.Parent then
        u135:Destroy();
    end;
end;

function u13.CreateProjectile(p137, u138) -- Line: 575
    -- upvalues: RaycastUtil (copy), u20 (copy), VFX (copy), VFX2 (copy), u6 (ref), Debris (copy), u13 (copy), u5 (copy), u8 (copy), u7 (ref), RunService (copy)
    if p137:CheckCameraDistance(u138.Position, u138.MaxRange * 1.5) then
        return;
    end;

    local u139 = type(u138.FilterFunction) == "string" and RaycastUtil:FilterFunction(u138.FilterFunction) or u138.FilterFunction;
    local u140 = type(u138.HitFunction) == "string" and u20[u138.HitFunction] or u138.HitFunction;
    local u141 = type(u138.MissFunction) == "string" and u20[u138.MissFunction] or u138.MissFunction;
    local u142 = type(u138.StepFunction) == "string" and u20[u138.StepFunction] or u138.StepFunction;
    local u143 = u138.Direction * u138.Speed;

    if u138.SavedVariables then
        u143 = u138.SavedVariables[1] or u143;
    end;

    local u144 = u138.SavedVariables and u138.SavedVariables[2] or u138.Position;
    local u145 = u138.SavedVariables and (u138.SavedVariables[3] or 0) or 0;
    local u146 = (u138.SavedVariables and u138.SavedVariables[4]) == true;
    local u147 = u138.SavedVariables and u138.SavedVariables[5] or u138.Speed;
    local u148 = u138.SavedVariables and u138.SavedVariables[6] or u138.Gravity;
    local u149 = u138.SavedVariables and u138.SavedVariables[7] or u138.MaxRange;
    local u150 = u138.SavedVariables and (u138.SavedVariables[8] or 0) or 0;
    local u151 = VFX:FindFirstChild(u138.TracerName or "");
    local u152 = nil;
    local u153 = nil;
    local u154, u155, u156, u157, u158, u159;

    if u151 then
        u154 = u151.Name:find("Rocket") ~= nil;
        u155 = u151.Name:find("Arrow") ~= nil;
        u156 = u151.Name == "NailBullet";
        u157 = u154 and CFrame.Angles(0, -1.5707963267948966, 0) or u155 and CFrame.Angles(0, 3.141592653589793, 0) or (u156 and CFrame.Angles(1.5707963267948966, 0, 0) or CFrame.new());
        u151 = u151:Clone();

        if u151.Name == "RifleBullet" then
            u151:PivotTo(CFrame.new(u138.Position, u138.Position + u138.Direction) * CFrame.new(0, 0, -2) * u157);
        elseif u151.Name:find("Pumpkin") then
            local Angles = CFrame.Angles;
            local v160 = math.random(0, 359);
            local v161 = math.rad(v160);
            local v162 = math.random(0, 359);
            local v163 = math.rad(v162);
            local v164 = math.random(0, 359);
            u152 = Angles(v161, v163, (math.rad(v164)));
            local Angles2 = CFrame.Angles;
            local v165 = math.random(30, 40) / 10;
            local v166 = math.rad(v165) * (math.random(1, 2) * 2 - 3);
            local v167 = math.random(30, 40) / 10;
            local v168 = math.rad(v167) * (math.random(1, 2) * 2 - 3);
            local v169 = math.random(30, 40) / 10;
            u153 = Angles2(v166, v168, math.rad(v169) * (math.random(1, 2) * 2 - 3));
        end;

        u151.Parent = VFX2;
        u158 = u151.PrimaryPart:FindFirstChildOfClass("Trail");
        u159 = u151.PrimaryPart:FindFirstChild("TracerBoard");

        if u154 then
            u151.PrimaryPart.RocketFly:Play();
        end;
    else
        u156 = false;
        u158 = nil;
        u159 = nil;
        u155 = false;
        u157 = nil;
        u154 = false;
    end;

    local u170 = false;
    local u171 = false;
    local u172 = nil;
    u6 = u6 >= 10000 and 1 or u6 + 1;
    local u173 = u6;
    local SaveVariables = u138.SaveVariables;

    local function v187(p174) -- Line: 626
        -- upvalues: u138 (copy), u170 (ref), u150 (ref), SaveVariables (copy), u172 (ref), u147 (ref), u145 (ref), u149 (ref), u143 (ref), u144 (ref), RaycastUtil (ref), u139 (copy), u146 (ref), u151 (ref), u157 (ref), u152 (ref), u153 (ref), u158 (ref), u159 (ref), Debris (ref), u142 (copy), u173 (copy), u148 (ref), u171 (ref), u140 (copy), u155 (ref), u156 (ref), u154 (ref), u13 (ref)
        local v175 = u138.Instant or p174;
        local v176 = nil;

        while not u170 do
            local v177 = v175 / 0.016666666666666666;
            u150 = u150 + 1;

            if SaveVariables then
                SaveVariables[8] = u150;
            end;

            local v178;

            if u150 == 1 then
                v178 = u138.PositionFirst ~= nil;
            else
                v178 = false;
            end;

            if v178 then
                u172 = (u138.Position - u138.PositionFirst).Magnitude;
            end;

            local v179 = math.min(u145 + (v178 and u172 or u147 * v175), u149) - u145;
            local v180 = v178 and u138.PositionFirst or u144;
            local v181;

            if u138.Size then
                v181 = {
                    Type = "Sphere",
                    Position = v180,
                    Size = u138.Size
                } or v180;
            else
                v181 = v180;
            end;

            local v182, v183, v184, v185, v186 = RaycastUtil:Raycast(v181, (v178 and u138.DirectionFirst or u143.Unit) * v179, u138.FilterType, u138.Filters, u138.VisualizeRay, u139, u146);
            local Magnitude = (v183 - v180).Magnitude;

            if u151 and not v178 then
                v176 = CFrame.new(v183, v180) * CFrame.new(0, 0, Magnitude / -1.2) * u157 * (u152 or CFrame.new());
            end;

            if u152 then
                u152 = u152:Lerp(u152 * u153, v177);
            end;

            if u158 then
                u158.Enabled = not v178;
            end;

            u145 = math.min(u145 + Magnitude, u149);

            if SaveVariables then
                SaveVariables[3] = u145;
            end;

            if u159 then
                u159.Circle.ImageTransparency = math.clamp((u145 - u138.MaxRange * 0.6) / (u138.MaxRange * 0.4), 0, 1);
            end;

            if v186 then
                Debris:AddItem(v186, 5);
            end;

            if u142 and (type(u142) == "function" and u142(v180, v183, u173)) then
                u170 = true;
            end;

            if v182 then
                if v185 == Enum.Material.Water and not u146 then
                    u146 = true;
                    u145 = 0;
                    u148 = math.max(u148 + 0.25, 1);
                    u147 = u147 * 0.08;
                    u149 = math.clamp(u138.MaxRange / 50, 10, 25);

                    if SaveVariables then
                        SaveVariables[3] = u145;
                        SaveVariables[4] = u146;
                        SaveVariables[5] = u147;
                        SaveVariables[6] = u148;
                        SaveVariables[7] = u149;
                    end;
                else
                    u171 = true;
                    u170 = true;

                    if u140 then
                        u140(v182, v183, v184, v185, nil, u155 or u156);
                    end;
                end;
            elseif not v178 and u150 > 1 then
                u143 = u143 - Vector3.new(0, 196.2 * u148, 0) * v175;
                u144 = v183;

                if SaveVariables then
                    SaveVariables[1] = u143;
                    SaveVariables[2] = u144;
                end;
            end;

            if math.abs(u149 - u145) <= 1 then
                u170 = true;
            end;

            if u170 and u151 then
                if u154 or u151.Name == "PumpkinCursed" then
                    u151.PrimaryPart.Transparency = 1;

                    for _, child in pairs(u151.PrimaryPart:GetChildren()) do
                        if child:IsA("Sound") then
                            child:Stop();
                        else
                            child.Enabled = false;
                        end;
                    end;

                    Debris:AddItem(u151, 3);
                elseif u151.Name == "PumpkinRegular" then
                    task.defer(u13.CreateBenchGibs, u13, "Pumpkin", v176);
                else
                    u151:Destroy();
                end;

                v176 = nil;
            end;

            if not u138.Instant then
                break;
            end;
        end;

        if v176 then
            return u170, u151.PrimaryPart, v176;
        end;

        return u170;
    end;

    local function v188() -- Line: 766
        -- upvalues: u5 (ref), u173 (copy), u171 (ref), u141 (copy)
        u5[u173] = nil;

        if u171 or not u141 then
            return;
        end;

        u141();
    end;

    if u138.Instant then
        v187();
        u5[u173] = nil;

        if not u171 and u141 then
            u141();
        end;
    else
        table.insert(u8, {
            StepFunction = v187,
            FinishFunction = v188,
            Parameters = u138
        });

        if not (u7 and u7.Connected) then
            u7 = RunService.Heartbeat:Connect(function(u189) -- Line: 783
                -- upvalues: u8 (ref), u7 (ref)
                local u190 = {};
                local u191 = {};

                for i, v in pairs(u8) do
                    local u192 = false;
                    local success, result = pcall(function() -- Line: 787
                        -- upvalues: v (copy), u192 (ref), u189 (copy), u190 (copy), u191 (copy)
                        if v.Parameters.Terminate then
                            u192 = true;

                            return;
                        end;

                        local v193, v194, v195 = v.StepFunction(u189);

                        if v194 then
                            table.insert(u190, v194);
                            table.insert(u191, v195);
                        end;

                        if not v193 then
                            return;
                        end;

                        v.FinishFunction();
                        u192 = true;
                    end);

                    if not success or u192 then
                        if not success then
                            warn(result, " - BULLET CALCULATION ERROR");
                        end;

                        table.remove(u8, i);
                    end;
                end;

                if #u190 > 0 then
                    workspace:BulkMoveTo(u190, u191, Enum.BulkMoveMode.FireCFrameChanged);
                end;

                if #u8 > 0 then
                    return;
                end;

                u7:Disconnect();
                u7 = nil;
            end);
        end;
    end;
end;

function u13.CheckCameraDistance(p196, p197, p198, p199) -- Line: 820
    -- upvalues: Players (copy), CurrentCamera (copy), NumberUtil (copy)
    if Players.LocalPlayer then
        if not CurrentCamera then
            return true;
        end;

        local Position = CurrentCamera.CFrame.Position;

        if p199 then
            local Magnitude = (Position - p197).Magnitude;

            return p198 < Magnitude, Magnitude;
        end;

        local v200, v201 = NumberUtil:IsWithin(Position, p197, p198);

        return not v200, v201;
    end;
end;

return u13;