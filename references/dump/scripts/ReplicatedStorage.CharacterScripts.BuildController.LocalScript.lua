-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local Players = game:GetService("Players");
local UserInputService = game:GetService("UserInputService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Benches = ReplicatedStorage:WaitForChild("Benches");
local Values = ReplicatedStorage:WaitForChild("Values");
local Bases = workspace:WaitForChild("Bases");
local VFX = workspace:WaitForChild("VFX");
local Benches2 = VFX:WaitForChild("Benches");
local LocalPlayer = Players.LocalPlayer;
local Parent = script.Parent;
local Humanoid = Parent:WaitForChild("Humanoid");
local CurrentCamera = workspace.CurrentCamera;
local InventoryController = Parent:WaitForChild("InventoryController");
local WheelController = Parent:WaitForChild("WheelController");
local CameraController = Parent:WaitForChild("CameraController");
local InteractController = Parent:WaitForChild("InteractController");
local EquipController = Parent:WaitForChild("EquipController");
local PreferredInputController = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");

local function _() -- Line: 38
    -- upvalues: PreferredInputController (copy)
    local v1 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    return v1;
end;

local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local Items = require(Modules:WaitForChild("Items"));
local BenchInfo = require(Modules:WaitForChild("BenchInfo"));
local RecipeModule = require(Modules:WaitForChild("RecipeModule"));
local BasePartInfo = require(Modules:WaitForChild("BasePartInfo"));
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local AssetContainer = require(Modules:WaitForChild("AssetContainer"));
local ActiveBenchModule = require(Modules:WaitForChild("ActiveBenchModule"));
local u2 = AssetContainer();
local EquipBench = script:WaitForChild("EquipBench");
local Build = ReplicatedStorage:WaitForChild("ClientSignals"):WaitForChild("Build");
local u3 = {
    Twig = { "Wood", "Stone", "Metal", "Steel" },
    Wood = { "Stone", "Metal", "Steel" },
    Stone = { "Metal", "Steel" },
    Metal = { "Steel" },
    Steel = {}
};
local u4 = nil;
local u5 = nil;
local u6 = nil;
local u7 = nil;
local u8 = nil;
local u9 = nil;
local u10 = nil;
local u11 = nil;
local u12 = false;
local u13 = 0;
local u14 = CFrame.new();
local u15 = 0;
local u16 = "Foundation";
local u17 = nil;
local u18 = nil;
local u19 = {};
local u20 = nil;
local u21 = nil;
local u22 = {};
local u23 = false;
local u24 = true;
local u25 = 0;
local u26 = nil;
local u27 = {};
local u28 = false;

local function _(p29) -- Line: 97
    -- upvalues: InventoryController (copy)
    local v30 = InventoryController.Fetch:Invoke();

    if not v30 then
        return;
    end;

    local Toolbar = v30.Toolbar;

    if Toolbar then
        local v31 = Toolbar[p29 or script:GetAttribute("Equipped")];

        if v31 == nil then
            v31 = false;
        elseif v31 == 0 then
            v31 = false;
        end;

        return v31;
    end;
end;

local function u36() -- Line: 106
    -- upvalues: u12 (ref), u4 (ref), u10 (ref), InventoryController (copy), u11 (ref), u21 (ref), u9 (ref), u23 (ref), u22 (ref), u15 (ref), u25 (ref), u2 (copy), u16 (ref)
    if not (u12 and (u4 and (u4.Parent and u10))) then
        return;
    end;

    local v32 = InventoryController.Fetch:Invoke();
    local v33;

    if v32 then
        local Toolbar = v32.Toolbar;

        if Toolbar then
            v33 = Toolbar[script:GetAttribute("Equipped")];

            if v33 == nil then
                v33 = false;
            elseif v33 == 0 then
                v33 = false;
            end;
        else
            v33 = nil;
        end;
    else
        v33 = nil;
    end;

    if not (v33 and v33.ID) then
        return;
    end;

    if u11 == false then
        return;
    end;

    local v34;

    if v33.ID == 30 then
        v34 = u21 or "none";
    else
        v34 = u21 or (u9 or "none");
    end;

    local v35 = u23;

    if u22.Index and u15 % 2 == 1 then
        v35 = not v35;
    end;

    if v33.ID == 190 then
        u15 = u15 % 3 == 2 and 1 or (u15 % 3 == 1 and 2 or u15 % 3);
    end;

    if tick() - u25 < 0.05 then
        return;
    end;

    u25 = tick();
    u2("Fire", "NM\182\1\154\155j\149\231\163\4\179F\180\232\247\208\7\221\217", "\1\22J?\191\138\fxF.L\183\223x)\198\198\168\188^", v34, u4.PrimaryPart.CFrame, u15, u16, u22.Index or 0, v35);
end;

local function _(p37, p38, p39, p40) -- Line: 135
    -- upvalues: u19 (ref)
    local v41 = u19[p37];

    if not (v41 and v41[p39]) then
        if not v41 then
            v41 = {};
            u19[p37] = v41;
        end;

        v41[p39] = p38.CFrame * p40.Offset;

        return true;
    end;
end;

local u42 = {};

local function u58(p43) -- Line: 154
    -- upvalues: Humanoid (copy), Parent (copy), u20 (ref), u19 (ref), u42 (copy), u17 (ref), BenchInfo (copy), Bases (copy), NumberUtil (copy)
    if not (Humanoid and (Humanoid.Parent and (Parent and (Parent.Parent and Parent.PrimaryPart)))) then
        return;
    end;

    local Position = Parent.PrimaryPart.Position;
    u20 = Position;

    if not p43 then
        u19 = {};
    end;

    local v44 = u42[u17];

    if not v44 then
        local v45 = BenchInfo[u17];

        if not v45 then
            return;
        end;

        local SnapPoints = v45.SnapPoints;

        if not SnapPoints then
            return;
        end;

        v44 = {};

        for i, v in pairs(SnapPoints) do
            if not v.Unsnappable then
                local AttachmentIndex = v.AttachmentIndex;

                for _, v2 in pairs(v.BenchNames) do
                    local v46 = v44[v2];

                    if not v46 then
                        v46 = {};
                        v44[v2] = v46;
                    end;

                    local v47 = v46[AttachmentIndex];

                    if not v47 then
                        v47 = {};
                        v46[AttachmentIndex] = v47;
                    end;

                    table.insert(v47, {
                        Index = i,
                        SnapTable = v
                    });
                end;
            end;
        end;

        u42[u17] = v44;
    end;

    tick();
    local v48 = 0;
    local v49 = 0;

    for _, child in pairs(Bases:GetChildren()) do
        if child.Name ~= "Loners" and child.Parent then
            local v50 = child:FindFirstChild("Base Cabinet");
            local v51, v52, v53, v54, v55, v56;

            if v50 then
                local v57 = v50:FindFirstChild("Base Cabinet");

                if v57 and not NumberUtil:IsWithin(v57:GetPivot().Position, Position, 750) then
                    v48 = v48 + 1;

                    if v48 % 120 == 0 then
                        task.wait();
                    end;
                else
                    for i, v in pairs(v44) do
                        v51 = child:FindFirstChild(i);

                        if v51 then
                            for _, child2 in pairs(v51:GetChildren()) do
                                if child2.Parent then
                                    v52 = child2.PrimaryPart;

                                    if v52 then
                                        if NumberUtil:IsWithin(v52.CFrame.Position, Position, 100) then
                                            for i2, v2 in pairs(v) do
                                                v53 = v52:FindFirstChild("Connection" .. i2);

                                                if v53 and (v53.Value and v53.Value.Parent) then
                                                    v48 = v48 + 1;

                                                    if v48 % 120 == 0 then
                                                        task.wait();
                                                    end;
                                                else
                                                    for _, v3 in pairs(v2) do
                                                        v54 = v3.Index;
                                                        v55 = v3.SnapTable;
                                                        v56 = u19[child2];

                                                        if not (v56 and v56[v54]) then
                                                            if not v56 then
                                                                v56 = {};
                                                                u19[child2] = v56;
                                                            end;

                                                            v56[v54] = v52.CFrame * v55.Offset;
                                                        end;
                                                    end;
                                                end;
                                            end;
                                        end;

                                        v49 = v49 + 1;

                                        if v49 % 80 == 0 then
                                            task.wait();
                                        end;
                                    else
                                        v48 = v48 + 1;

                                        if v48 % 120 == 0 then
                                            task.wait();
                                        end;
                                    end;
                                end;
                            end;
                        else
                            v48 = v48 + 1;

                            if v48 % 120 == 0 then
                                task.wait();
                            end;
                        end;
                    end;
                end;
            else
                for i, v in pairs(v44) do
                    v51 = child:FindFirstChild(i);

                    if v51 then
                        for _, child2 in pairs(v51:GetChildren()) do
                            if child2.Parent then
                                v52 = child2.PrimaryPart;

                                if v52 then
                                    if NumberUtil:IsWithin(v52.CFrame.Position, Position, 100) then
                                        for i2, v2 in pairs(v) do
                                            v53 = v52:FindFirstChild("Connection" .. i2);

                                            if v53 and (v53.Value and v53.Value.Parent) then
                                                v48 = v48 + 1;

                                                if v48 % 120 == 0 then
                                                    task.wait();
                                                end;
                                            else
                                                for _, v3 in pairs(v2) do
                                                    v54 = v3.Index;
                                                    v55 = v3.SnapTable;
                                                    v56 = u19[child2];

                                                    if not (v56 and v56[v54]) then
                                                        if not v56 then
                                                            v56 = {};
                                                            u19[child2] = v56;
                                                        end;

                                                        v56[v54] = v52.CFrame * v55.Offset;
                                                    end;
                                                end;
                                            end;
                                        end;
                                    end;

                                    v49 = v49 + 1;

                                    if v49 % 80 == 0 then
                                        task.wait();
                                    end;
                                else
                                    v48 = v48 + 1;

                                    if v48 % 120 == 0 then
                                        task.wait();
                                    end;
                                end;
                            end;
                        end;
                    else
                        v48 = v48 + 1;

                        if v48 % 120 == 0 then
                            task.wait();
                        end;
                    end;
                end;
            end;
        end;
    end;
end;

local function u60(p59, ...) -- Line: 287
    -- upvalues: u26 (ref), u4 (ref), u28 (ref), u58 (copy)
    if u26 then
        coroutine.close(u26);
        u26 = nil;
    end;

    if not (u4 and u4.Parent) then
        u28 = true;

        return;
    end;

    u26 = coroutine.create(u58, ...);
    coroutine.resume(u26);
end;

local function u61() -- Line: 306
    -- upvalues: u10 (ref), u12 (ref), u6 (ref), u4 (ref), u5 (ref)
    u10 = nil;
    u12 = false;
    script:SetAttribute("Equipped", 0);

    if u6 then
        u6:Disconnect();
        u6 = nil;
    end;

    if u4 and u4.Parent then
        u4:Destroy();
        u4 = nil;
    end;

    if u5 and u5.Parent then
        u5:Destroy();
        u5 = nil;
    end;
end;

local function u119(p62) -- Line: 325
    -- upvalues: InventoryController (copy), Items (copy), u12 (ref), u4 (ref), u61 (copy), u16 (ref), Benches (copy), u10 (ref), BenchInfo (copy), u18 (ref), u14 (ref), u15 (ref), u7 (ref), u8 (ref), u9 (ref), u13 (ref), u21 (ref), u22 (ref), Benches2 (copy), u5 (ref), u17 (ref), u28 (ref), u60 (copy), u6 (ref), RunService (copy), Parent (copy), Humanoid (copy), CameraController (copy), CurrentCamera (copy), RaycastUtil (copy), VFX (copy), u19 (ref), NumberUtil (copy), u23 (ref), u24 (ref), u11 (ref), ActiveBenchModule (copy), u20 (ref)
    local v63 = InventoryController.Fetch:Invoke();
    local v64;

    if v63 then
        local Toolbar = v63.Toolbar;

        if Toolbar then
            v64 = Toolbar[p62 or script:GetAttribute("Equipped")];

            if v64 == nil then
                v64 = false;
            elseif v64 == 0 then
                v64 = false;
            end;
        else
            v64 = nil;
        end;
    else
        v64 = nil;
    end;

    local v65;

    if v64 then
        v65 = Items[v64.ID];
    else
        v65 = v64;
    end;

    local v66 = script:GetAttribute("Equipped");

    if v66 > 0 and (u4 and (v66 ~= p62 or v65 and u4.Name ~= v65.Name)) then
        u61();
    end;

    if not v64 then
        return;
    end;

    local v67 = v64.ID == 30;
    local u68 = v67 and u16 or v65.Name;
    local v69 = Benches:FindFirstChild(u68);
    u10 = BenchInfo[u68];

    if not (u10 and v69) then
        return;
    end;

    script:SetAttribute("Equipped", p62);

    if u18 ~= u68 or not u12 then
        u14 = CFrame.new();
        u15 = 0;
        u7 = nil;
        u8 = nil;
        u9 = nil;
        u13 = 0;
        u12 = false;
        u21 = nil;
        u22 = {};
    end;

    local v70 = v67 and v69 and v69 or (v69:FindFirstChild(v64.Skin) or v69:FindFirstChild("Default"));
    local u71 = v70:Clone();
    u71.Name = u68;
    u71.PrimaryPart = u71:FindFirstChild("Main");

    for _, descendant in pairs(u71:GetDescendants()) do
        if descendant and descendant.Parent then
            if descendant:IsA("BasePart") and descendant.Parent:IsA("Model") then
                descendant.Anchored = true;
                descendant.CanCollide = false;
                descendant.CastShadow = false;
                descendant.Color = script:GetAttribute("PlaceUnavailableColor");
                descendant.Material = Enum.Material.ForceField;

                if descendant:IsA("MeshPart") then
                    descendant.TextureID = "";
                end;
            elseif descendant:IsA("Highlight") or (descendant.Name == "NonBaseCollisionParts" or (descendant:IsA("Decal") or (descendant:IsA("Texture") or (descendant:IsA("SurfaceAppearance") or descendant.Name == "DetailDeleter")))) then
                descendant:Destroy();
            elseif descendant:IsA("Folder") then
                for _, child in pairs(descendant:GetChildren()) do
                    if child:IsA("BasePart") then
                        child.Transparency = 1;
                        child.CanCollide = false;
                        child.Anchored = true;
                    end;
                end;
            end;
        end;
    end;

    u71.Parent = Benches2;
    u4 = u71;
    u5 = v70:Clone();
    u5.Name = u68;
    u5.PrimaryPart = u5:FindFirstChild("Main");

    for _, child in pairs(u5:GetChildren()) do
        if child == u5.PrimaryPart then
            if child:IsA("BasePart") then
                child.Transparency = 1;
                child.CanCollide = false;
            end;
        else
            if child.Name == "CollisionParts" or (child.Name == "RayParts" or (child.Name == "BaseCollisionParts" or child.Name == "NonBaseCollisionParts")) then
                for _, child2 in pairs(child:GetChildren()) do
                    if child2:IsA("BasePart") then
                        child2.Transparency = 1;
                        child2.CanCollide = false;
                        child2.Anchored = true;
                    end;
                end;

                if child:IsA("BasePart") then
                    child.Transparency = 1;
                    child.CanCollide = false;
                end;
            end;

            if child.Name == "Pole" then
                if child:IsA("BasePart") then
                    child.Transparency = 1;
                    child.CanCollide = false;
                end;
            end;

            child:Destroy();
        end;
    end;

    u5.Parent = Benches2;
    local SnapPoints = u10.SnapPoints;
    local SnapOnly = u10.SnapOnly;
    local v72 = u17;
    u17 = u68;

    if u28 or (u18 ~= u17 or not v72) then
        u60();
    end;

    u18 = u68;
    local OffsetSnappedFacingAway = u10.OffsetSnappedFacingAway;
    local MaxPerBase = u10.MaxPerBase;

    if u6 then
        u6:Disconnect();
    end;

    u6 = RunService.Heartbeat:Connect(function(p73) -- Line: 414
        -- upvalues: u4 (ref), u71 (copy), u5 (ref), Parent (ref), Humanoid (ref), u61 (ref), u13 (ref), CameraController (ref), CurrentCamera (ref), u10 (ref), RaycastUtil (ref), VFX (ref), SnapPoints (copy), SnapOnly (copy), u19 (ref), NumberUtil (ref), u21 (ref), u22 (ref), u8 (ref), u14 (ref), u23 (ref), OffsetSnappedFacingAway (copy), u24 (ref), u68 (copy), u12 (ref), u7 (ref), u9 (ref), MaxPerBase (copy), u11 (ref), ActiveBenchModule (ref), u20 (ref), u60 (ref)
        if u4 ~= u71 or (not u5 or (not Parent or (not Parent.PrimaryPart or (not Humanoid or Humanoid.Health <= 0)))) then
            u61();

            return;
        end;

        local v74 = tick() - u13 >= 0.1;
        local v75 = Parent.PrimaryPart.Position + Vector3.new(0, 1.5, 0);
        local v76 = CameraController:GetAttribute("ViewmodelCFrame") or CurrentCamera.CFrame;
        local v77 = u10.PlaceExtraDistance or 0;
        local v78, v79, v80, v81 = RaycastUtil:Raycast(v75, v76.LookVector * (8 + v77), "Blacklist", { Parent, VFX }, false, RaycastUtil:FilterFunction("View"), true);
        local v82 = v80 or Vector3.new(0, 1, 0);
        local v83 = math.acos(v82.Y);
        local v84 = math.deg(v83);
        local v85 = nil;

        for i = 14, 8, -1.5 do
            if SnapPoints and SnapOnly ~= nil then
                v85 = CFrame.new((v76 * CFrame.new(0, 0, -(i + v77))).Position);
            elseif u10.RotateOnSurface then
                local v86 = CFrame.new(v79, v79 + Vector3.new(0, 1, 0));
                v85 = (((function(p87, p88, p89) -- Line: 431
                    local v90 = p87:Dot(p88);
                    local v91 = p87:Cross(p88);

                    if v90 < -0.99999 then
                        return CFrame.fromAxisAngle(p89, 3.141592653589793);
                    end;

                    return CFrame.new(0, 0, 0, v91.x, v91.y, v91.z, 1 + v90);
                end)(v86.UpVector, v82, Vector3.new(1, 0, 0)) * v86).Rotation + v86.Position) * CFrame.Angles(1.5707963267948966, 0, 0);
            else
                v85 = CFrame.new(v79, v79 + Vector3.new(0, 1, 0));
            end;

            if not (v74 and SnapPoints) then
                break;
            end;

            local v92 = nil;
            local v93 = nil;
            local v94 = nil;

            for i2, v in pairs(u19) do
                for i3, v2 in pairs(v) do
                    local v95, v96 = NumberUtil:IsWithin(v85.Position, v2.Position, 4);

                    if v95 then
                        local v97 = math.sqrt(v96);

                        if not v92 or v92 >= v97 then
                            v93 = i2;
                            v92 = v97;
                            v94 = {
                                Index = i3,
                                Offset = v2
                            };
                        end;
                    end;
                end;
            end;

            if v93 then
                u21 = v93;
                u22 = v94;
                break;
            end;

            u21 = nil;
            u22 = {};

            if i == 8 and SnapOnly ~= nil then
                v85 = CFrame.new((v76 * CFrame.new(0, 0, -(14 + v77))).Position);
            end;
        end;

        local v98;

        if u21 and (u21.Parent and u22.Offset) then
            v85 = u22.Offset;
            v98 = true;
        else
            v98 = false;
        end;

        local v99 = v85 * u10.Offset;
        local v100, v101, v102 = (u10.FaceCamera and not v98 and CFrame.new(v99.Position, (Vector3.new(v75.X, v99.Position.Y, v75.Z))) or CFrame.new()):ToEulerAnglesXYZ();
        local v103 = v99 * (CFrame.Angles(v100, v101, v102) * (((SnapPoints ~= nil and not v98 or SnapPoints == nil and not v78) and true or false) and u10.UnsnappedOffset or CFrame.new()));
        local v104 = u8;
        local v105 = u14:Lerp(CFrame.new(), v98 and u10.RotateOffset == CFrame.Angles(0, 1.5707963267948966, 0) and 0.5 or 0);
        local v106 = v103 * v105;

        if not v104 then
            u23 = false;
            local v107;

            if v98 and (OffsetSnappedFacingAway and (v75 - v106.Position).Unit:Dot(v106.LookVector) < 0) then
                v107 = v106 * OffsetSnappedFacingAway;
                u23 = true;
            else
                v107 = v106;
            end;

            v104 = v107 * (v98 and v105 and v105 or CFrame.new());
        end;

        local CFrame2 = u5.PrimaryPart.CFrame;
        local v108 = false;
        u5:SetPrimaryPartCFrame(v104);

        if v74 then
            u24 = true;
            local Beds = shared.Beds;

            if Beds and u10.Type == "Bed" then
                for _, v in pairs(Beds) do
                    local v109 = Vector3.new(v.Position.X, v104.Position.Y, v.Position.Z);

                    if NumberUtil:IsWithin(v104.Position, v109, 150) then
                        u24 = false;
                        break;
                    end;
                end;
            end;

            local v110 = (v98 and u10.SnappedPlacingFunc or u10.PlacingFunc)(u68, v78, v84, v78, v81);
            local v111;

            if u68 == "Foundation" or u68 == "Triangle Foundation" then
                v111 = not v98;
            else
                v111 = false;
            end;

            u13 = tick();
            local v112 = u10.CollisionFunc(u5, v111, nil, u10.Type, u10.LenientCollision, v98);
            u12 = v110 and v112;

            if u12 then
                u7 = v106;
                u9 = v78;
            end;

            if u12 == false and (u7 and (u9 and u9.Parent)) then
                if not u8 then
                    u13 = 0;
                end;

                u8 = u7;

                if not NumberUtil:IsWithin(u8.Position, v106.Position, 0.4) then
                    u7 = nil;
                    u9 = nil;
                    u8 = nil;
                end;
            end;

            if u8 then
                v108 = true;
                u5:SetPrimaryPartCFrame(v106);

                if v110 then
                    v110 = u10.CollisionFunc(u5, v111, nil, u10.Type, u10.LenientCollision, v98);
                end;

                if v110 then
                    u7 = v106;
                    u9 = v78;
                    u8 = nil;
                    u12 = true;
                elseif v112 then
                    u12 = true;
                    v106 = v104;
                else
                    v106 = v104;
                end;
            else
                v106 = v104;
            end;

            if SnapOnly and u12 then
                u12 = v98;
            end;

            local v113 = u12 and (MaxPerBase and (u9 and not v98)) and u9:FindFirstAncestor("Base");

            if v113 then
                local v114 = v113:FindFirstChild(u68);
                u12 = v114 == nil and true or #v114:GetChildren() < MaxPerBase;
            end;

            u11 = nil;

            if u12 then
                if u68 == "Base Cabinet" then
                    local v115 = { VFX };
                    u12 = RaycastUtil:Raycast(Vector3.new(v106.Position.X, 225.6, v106.Position.Z), Vector3.new(0, -0.2, 0), "Blacklist", v115, false, RaycastUtil:FilterFunction("BuildingPrivCheck")) == nil;
                else
                    local IgnoreBuildBlock = u10.IgnoreBuildBlock;
                    local v116, v117 = RaycastUtil:GetBaseCabinetUnder(v106.Position, IgnoreBuildBlock);

                    if v116 and (v116:GetAttribute("Monument") and (IgnoreBuildBlock ~= "All" and (IgnoreBuildBlock ~= "Monument" or v117))) then
                        u11 = false;
                    elseif IgnoreBuildBlock and IgnoreBuildBlock ~= "Monument" then
                        u11 = nil;
                    else
                        local v118 = ActiveBenchModule.GetClientInfo(v116);

                        if v118 then
                            u11 = v118.Access;
                        end;
                    end;

                    u12 = u11 ~= false;
                end;
            end;
        else
            v106 = v104;
        end;

        u4:SetPrimaryPartCFrame(v106);

        for _, descendant in pairs(u4:GetDescendants()) do
            if descendant:IsA("BasePart") and descendant.Parent:IsA("Model") then
                descendant.Color = script:GetAttribute(u12 and ((u11 == false or not u24) and "PlaceBlockedColor" or "PlaceAvailableColor") or "PlaceUnavailableColor");
            end;
        end;

        if not v108 then
            u5:SetPrimaryPartCFrame(CFrame2);
        end;

        if u20 and not NumberUtil:IsWithin(v75, u20, 75) then
            u60();
        end;
    end);
end;

local function _() -- Line: 600
    -- upvalues: u10 (ref), u14 (ref), u15 (ref)
    if not u10 then
        return;
    end;

    u14 = u14 * u10.RotateOffset;
    u15 = u15 + 1;
end;

local function u144() -- Line: 608
    -- upvalues: InventoryController (copy), EquipController (copy), BasePartInfo (copy), RecipeModule (copy), Items (copy), u16 (ref), NumberUtil (copy), WheelController (copy), u119 (copy), InteractController (copy), BenchInfo (copy), Values (copy), RaycastUtil (copy), ActiveBenchModule (copy), u3 (copy), u2 (copy), u10 (ref), u14 (ref), u15 (ref)
    if InventoryController:GetAttribute("Open") then
        return;
    end;

    local v120 = EquipController:GetAttribute("Equipped");
    local v121 = InventoryController.Fetch:Invoke();
    local v122;

    if v121 then
        local Toolbar = v121.Toolbar;

        if Toolbar then
            v122 = Toolbar[v120 or script:GetAttribute("Equipped")];

            if v122 == nil then
                v122 = false;
            elseif v122 == 0 then
                v122 = false;
            end;
        else
            v122 = nil;
        end;
    else
        v122 = nil;
    end;

    if v122 then
        local v123 = InventoryController.Fetch:Invoke();
        local v124 = {};

        for _, v in pairs({ "Inventory", "Toolbar" }) do
            for _, v2 in pairs(v123[v]) do
                if v2 ~= 0 then
                    if not v124[v2.ID] then
                        v124[v2.ID] = 0;
                    end;

                    local ID = v2.ID;
                    v124[ID] = v124[ID] + v2.Amount;
                end;
            end;
        end;

        if v122.ID == 30 then
            local v125 = BasePartInfo:Fetch();

            for _, v in pairs(v125) do
                local v126 = v.Name:gsub(" ", "_"):gsub("-", "_");
                v.Image = script:GetAttribute("Build" .. v126);
                local v127 = RecipeModule:FetchRecipe("Twig", v.Name);

                if v127 then
                    local v128 = v127.Costs[1];

                    if v128 then
                        local v129 = Items[v128.ID];
                        v.Selectable = true;
                        v.SelectFirst = u16 == v.Name;
                        v.Cost = NumberUtil:FormatNumber(v128.Amount) .. " " .. v129.Name .. " (" .. NumberUtil:FormatNumber(v124[v128.ID] or 0) .. " Left)";
                    end;
                end;
            end;

            local v130 = WheelController.Open:Invoke(v125, "Blueprint", false);

            if not v130 then
                return;
            end;

            local v131 = v125[v130];

            if not v131 then
                return;
            end;

            u16 = v131.Name;
            u119(script:GetAttribute("Equipped"));

            return;
        end;

        if v122.ID == 31 then
            local v132 = InteractController.GetSelected:Invoke();

            if not (v132 and v132.Parent) then
                return;
            end;

            local Name = v132.Name;

            if Name == "Wall Block" then
                return;
            end;

            local v133 = BenchInfo[Name];
            local PrimaryPart = v132.PrimaryPart;

            if not v133 or (not PrimaryPart or v133.Type ~= "BasePart") then
                return;
            end;

            local RotateOffset = v133.RotateOffset;
            local Value = Values.ServerTick.Value;
            local v134 = v132:GetAttribute("DamageType");

            if Value - (v132:GetAttribute("LastDamaged") or 0) < 60 then
                return;
            end;

            local v135 = RaycastUtil:GetBaseCabinetUnder(PrimaryPart.Position);

            if v135 and v135:GetAttribute("Monument") then
                return;
            end;

            local v136 = ActiveBenchModule.GetClientInfo(v135);

            if v136 and v136.Access == false then
                return;
            end;

            local v137 = {
                {
                    Name = "Upgrade to Wood",
                    Description = "Cheap way to fortify your base. Vulnerable to fire attacks.",
                    Image = script:GetAttribute("HammerWoodIcon")
                },
                {
                    Name = "Upgrade to Stone",
                    Description = "Hard and durable. Stronger than Wood.",
                    Image = script:GetAttribute("HammerStoneIcon")
                },
                {
                    Name = "Upgrade to Metal",
                    Description = "Resistant to explosive attacks. Stronger than Stone.",
                    Image = script:GetAttribute("HammerMetalIcon")
                },
                {
                    Name = "Upgrade to Steel",
                    Description = "Expensive but resilient material. Stronger than Metal.",
                    Image = script:GetAttribute("HammerSteelIcon")
                },
                {
                    Name = "Rotate",
                    Description = "Flip any misplaced parts.",
                    Image = script:GetAttribute("HammerRotateIcon")
                },
                {
                    Name = "Demolish",
                    Description = "Get rid of selected base part.",
                    Image = script:GetAttribute("HammerDemolishIcon")
                }
            };

            for _, v in pairs(v137) do
                local Name2 = v.Name;

                if Name2:sub(1, 7) == "Upgrade" then
                    local v138 = Name2:sub(12);
                    local v139 = RecipeModule:FetchRecipe(v138, Name);

                    if v139 then
                        local v140 = v139.Costs[1];
                        local v141 = Items[v140.ID];
                        v.Cost = NumberUtil:FormatNumber(v140.Amount) .. " " .. v141.Name .. " (" .. NumberUtil:FormatNumber(v124[v140.ID] or 0) .. " Left)";
                    end;

                    v.Selectable = table.find(u3[v134 or "Twig"], v138) ~= nil;
                else
                    local v142;

                    if Value - (v132:GetAttribute(Name2 == "Demolish" and "Placed" or "Upgraded") or Value - 0.01) < Values.DemolishTimer.Value then
                        v142 = Values.SimpleDemolish.Value or Name2 == "Demolish" and v136 ~= nil and v136.Access;

                        if not v142 then
                            if Name2 == "Rotate" then
                                if RotateOffset then
                                    v142 = RotateOffset ~= CFrame.new();
                                else
                                    v142 = RotateOffset;
                                end;
                            else
                                v142 = false;
                            end;
                        end;
                    else
                        v142 = false;
                    end;

                    v.Selectable = v142;
                end;

                v.SelectFirst = false;
            end;

            local v143 = WheelController.Open:Invoke(v137, "Hammer", true);

            if not v143 then
                return;
            end;

            if not v137[v143] then
                return;
            end;

            u2("Fire", "NM\182\1\154\155j\149\231\163\4\179F\180\232\247\208\7\221\217", "\223\155\187BG2\179\190\204\146\219\194<\1c\152\5\141:?", v132 or "none", v143);
        end;
    else
        if not u10 then
            return;
        end;

        u14 = u14 * u10.RotateOffset;
        u15 = u15 + 1;
    end;
end;

local function _() -- Line: 723
    -- upvalues: WheelController (copy)
    WheelController.Close:Invoke("Blueprint");
    WheelController.Close:Invoke("Hammer");
end;

local function u150(u145) -- Line: 728
    -- upvalues: LocalPlayer (copy), u60 (copy)
    if not (u145 and (u145.Parent and u145:IsA("Model"))) then
        return;
    end;

    u145:GetPropertyChangedSignal("PrimaryPart"):Connect(function() -- Line: 731
        -- upvalues: u145 (copy), LocalPlayer (ref), u60 (ref)
        if not u145.PrimaryPart then
            return;
        end;

        local v146 = LocalPlayer:GetAttribute("ArenaIndex");
        local v147 = u145:GetAttribute("ArenaIndex");

        if v146 ~= nil and (v147 ~= nil and v146 ~= v147) then
            return;
        end;

        u60();
    end);

    if not u145.PrimaryPart then
        return;
    end;

    local v148 = LocalPlayer:GetAttribute("ArenaIndex");
    local v149 = u145:GetAttribute("ArenaIndex");

    if v148 ~= nil and (v149 ~= nil and v148 ~= v149) then
        return;
    end;

    u60();
end;

local function u152(p151) -- Line: 754
    -- upvalues: u27 (copy), u150 (copy)
    if not (p151:IsA("Folder") and u27[p151.Name]) then
        return;
    end;

    p151.ChildAdded:Connect(u150);

    for _, child in pairs(p151:GetChildren()) do
        u150(child);
    end;
end;

local function v154(p153) -- Line: 763
    -- upvalues: u152 (copy)
    if not p153:IsA("Folder") or p153.Name ~= "Base" then
        return;
    end;

    p153.ChildAdded:Connect(u152);

    for _, child in pairs(p153:GetChildren()) do
        u152(child);
    end;
end;

UserInputService.InputBegan:Connect(function(p155, p156) -- Line: 774
    -- upvalues: SettingsModule (copy), UserInputService (copy), u10 (ref), PreferredInputController (copy), u36 (copy), u14 (ref), u15 (ref), InteractController (copy), u144 (copy), EquipController (copy), InventoryController (copy)
    if SettingsModule.MainMenuOpen() then
        return;
    end;

    local UserInputType = p155.UserInputType;
    local v157 = UserInputService:GetFocusedTextBox();

    if u10 then
        local v158 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v158 and UserInputType == Enum.UserInputType.Gamepad1 then
            local Name = p155.KeyCode.Name;

            if Name == SettingsModule.GetSetting("Gamepad", "Place Building") then
                u36();

                return;
            end;

            if Name == SettingsModule.GetSetting("Gamepad", "Rotate Building") then
                if not u10 then
                    return;
                end;

                u14 = u14 * u10.RotateOffset;
                u15 = u15 + 1;

                return;
            end;

            if Name == SettingsModule.GetSetting("Gamepad", "Change Building") then
                if not InteractController.GetSelected:Invoke() then
                    u144();
                end;

                return;
            end;
        elseif UserInputType == Enum.UserInputType.Keyboard and not v157 then
            local Name = p155.KeyCode.Name;

            if Name == SettingsModule.GetSetting("Controls", "Rotate Building") then
                if not u10 then
                    return;
                end;

                u14 = u14 * u10.RotateOffset;
                u15 = u15 + 1;

                return;
            end;

            if Name == SettingsModule.GetSetting("Controls", "Change Building") then
                if not InteractController.GetSelected:Invoke() then
                    u144();
                end;

                return;
            end;
        end;
    end;

    local v159 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    if v159 and (UserInputType == Enum.UserInputType.Gamepad1 and p155.KeyCode.Name == "ButtonL2") then
        local v160 = EquipController:GetAttribute("Equipped");
        local v161 = InventoryController.Fetch:Invoke();
        local v162;

        if v161 then
            local Toolbar = v161.Toolbar;

            if Toolbar then
                v162 = Toolbar[v160 or script:GetAttribute("Equipped")];

                if v162 == nil then
                    v162 = false;
                elseif v162 == 0 then
                    v162 = false;
                end;
            else
                v162 = nil;
            end;
        else
            v162 = nil;
        end;

        if v162 and v162.ID == 31 then
            u144();

            return;
        end;
    end;

    if v157 or p156 then
        return;
    end;

    if UserInputType == Enum.UserInputType.MouseButton1 then
        u36();

        return;
    end;

    if UserInputType == Enum.UserInputType.MouseButton2 and SettingsModule.GetSetting("Controls", "Change Building") == "MB2" then
        u144();

        return;
    end;

    if UserInputType == Enum.UserInputType.Keyboard and p155.KeyCode.Name == SettingsModule.GetSetting("Controls", "Change Building") then
        u144();
    end;
end);
UserInputService.InputEnded:Connect(function(p163, p164) -- Line: 826
    -- upvalues: SettingsModule (copy), WheelController (copy)
    local UserInputType = p163.UserInputType;

    if UserInputType ~= Enum.UserInputType.MouseButton2 or SettingsModule.GetSetting("Controls", "Change Building") ~= "MB2" then
        if UserInputType == Enum.UserInputType.Keyboard then
            if p163.KeyCode.Name == SettingsModule.GetSetting("Controls", "Change Building") then
                WheelController.Close:Invoke("Blueprint");
                WheelController.Close:Invoke("Hammer");

                return;
            end;
        elseif UserInputType == Enum.UserInputType.Gamepad1 and p163.KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Change Building") then
            WheelController.Close:Invoke("Blueprint");
            WheelController.Close:Invoke("Hammer");
        end;

        return;
    end;

    WheelController.Close:Invoke("Blueprint");
    WheelController.Close:Invoke("Hammer");
end);
Bases.ChildAdded:Connect(v154);

for _, child in pairs(Bases:GetChildren()) do
    v154(child);
end;

EquipBench.Event:Connect(function(...) -- Line: 849
    -- upvalues: u119 (copy), WheelController (copy), u16 (ref), u17 (ref), u61 (copy)
    local v165 = ({ ... })[1];

    if v165 and v165 > 0 then
        u119(...);

        return;
    end;

    WheelController.Close:Invoke("Blueprint");
    WheelController.Close:Invoke("Hammer");

    if u16 ~= u17 then
        u17 = nil;
    end;

    u61();
end);
Build.OnClientEvent:Connect(function(p166, ...) -- Line: 867
    -- upvalues: u60 (copy)
    local v167 = { ... };

    if p166 == "UpdateSnaps" then
        local _ = v167[1];
        local _ = v167[2];
        u60(true);
    end;
end);

for _, v in pairs(BenchInfo) do
    local SnapPoints = v.SnapPoints;

    if SnapPoints then
        for _, v2 in pairs(SnapPoints) do
            local BenchNames = v2.BenchNames;

            if BenchNames then
                for _, v3 in pairs(BenchNames) do
                    u27[v3] = true;
                end;
            end;
        end;
    end;
end;

Benches2:ClearAllChildren();