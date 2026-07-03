-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local ArmorModule = require(Modules:WaitForChild("ArmorModule"));
local TweenUtil = require(Modules:WaitForChild("TweenUtil"));
local Idle = script:WaitForChild("Idle");
local Selected = script:WaitForChild("Selected");
local LocalPlayer = Players.LocalPlayer;
local u1 = {};
local u52 = {
    ShowCharacter = function(p2, p3, p4, p5, p6) -- Line: 37, Name: ShowCharacter
        -- upvalues: Idle (copy), u1 (copy)
        if not (p3 and p3.Parent) then
            return;
        end;

        p2:ClearViewport(p3);
        local Camera = Instance.new("Camera");
        Camera.Parent = p3;
        p3.CurrentCamera = Camera;
        local WorldModel = Instance.new("WorldModel");
        WorldModel.Parent = p3;
        p4.Archivable = true;
        local v7 = tick();
        print("waiting on character children");
        local v8 = {
            Humanoid = false,
            HumanoidRootPart = false,
            Head = false,
            UpperTorso = false,
            LowerTorso = false,
            RightUpperArm = false,
            RightLowerArm = false,
            RightHand = false,
            RightUpperLeg = false,
            RightLowerLeg = false,
            RightFoot = false,
            LeftUpperArm = false,
            LeftLowerArm = false,
            LeftHand = false,
            LeftUpperLeg = false,
            LeftLowerLeg = false,
            LeftFoot = false
        };

        while tick() - v7 < 60 and p4.Parent do
            local v9 = true;

            for i, v in v8 do
                if not v then
                    if p4:FindFirstChild(i) then
                        v8[i] = true;
                    else
                        v9 = false;
                    end;
                end;
            end;

            if v9 then
                break;
            end;

            task.wait();
        end;

        print("character children found in", tick() - v7);
        local v10 = p4:Clone();
        p4.Archivable = false;

        for _, child in pairs(v10:GetChildren()) do
            if child:IsA("BasePart") or (child:IsA("Shirt") or (child:IsA("Pants") or (child:IsA("Humanoid") or (child.Name:sub(1, 6) == "Armor_" or child.Name == "Hair")))) then
                for _, child2 in pairs(child:GetChildren()) do
                    if child2:IsA("BillboardGui") then
                        child2:Destroy();
                    end;
                end;
            else
                child:Destroy();
            end;
        end;

        v10.Parent = WorldModel;
        local HumanoidRootPart = v10:WaitForChild("HumanoidRootPart");
        HumanoidRootPart.Anchored = false;
        v10:WaitForChild("Humanoid"):LoadAnimation(Idle):Play();
        local u11 = {};
        local v12 = {};
        local v13 = {
            Delta = Vector3.new(0, 0, 0),
            Held = false,
            Camera = Camera,
            Object = v10,
            Anims = {
                Idle = nil
            },
            Char = p4,
            Hitboxes = p5,
            Connections = v12,
            FaceFeatures = u11
        };
        u1[p3] = v13;
        local Head = p4:FindFirstChild("Head");

        if Head then
            local Head2 = v10:FindFirstChild("Head");
            table.insert(v12, Head.ChildAdded:Connect(function(p14) -- Line: 119
                -- upvalues: Head2 (copy), u11 (copy)
                if not (p14:IsA("Decal") and (Head2 and Head2.Parent)) then
                    return;
                end;

                local v15 = p14:Clone();
                v15.Parent = Head2;
                u11[p14] = v15;
            end));
            table.insert(v12, Head.ChildRemoved:Connect(function(p16) -- Line: 125
                -- upvalues: u11 (copy)
                if not p16:IsA("Decal") then
                    return;
                end;

                local v17 = u11[p16];

                if not (v17 and v17.Parent) then
                    return;
                end;

                v17:Destroy();
            end));

            if Head2 then
                Head2.Transparency = 0.9;

                for _, child in pairs(Head:GetChildren()) do
                    if child:IsA("Decal") then
                        local u18 = Head2:FindFirstChild(child.Name);

                        if u18 then
                            table.insert(v12, child.Changed:Connect(function(u19) -- Line: 137
                                -- upvalues: u18 (copy), child (copy)
                                if not (u18 and u18.Parent) then
                                    return;
                                end;

                                local success, result = pcall(function() -- Line: 139
                                    -- upvalues: child (ref), u19 (copy)
                                    return child[u19];
                                end);

                                if not success then
                                    return;
                                end;

                                u18[u19] = result;
                            end));
                        end;
                    end;
                end;
            end;
        end;

        p2:AddSpin(p3);
        v10:PivotTo(CFrame.new());
        local v20 = CFrame.new((HumanoidRootPart.CFrame * CFrame.new(0, 1, -5)).Position, HumanoidRootPart.Position + Vector3.new(0, 0.1, 0));
        Camera.CFrame = v20;
        v13.OrigCamCF = v20;

        if p6 then
            p2:UpdateArmors(p3, p6);
        end;

        return v13;
    end,

    TweenCamera = function(p21, p22, p23) -- Line: 160, Name: TweenCamera
        -- upvalues: u1 (copy), TweenUtil (copy)
        local v24 = u1[p22];

        if not v24 then
            return;
        end;

        TweenUtil:Tween(v24.Camera, "CFrame", v24.OrigCamCF * p23, 0.5, "Quart", "Out");
    end,

    UpdateArmors = function(p25, p26, p27) -- Line: 166, Name: UpdateArmors
        -- upvalues: u1 (copy), ArmorModule (copy)
        local v28 = u1[p26];

        if not v28 then
            return;
        end;

        ArmorModule:UpdateArmors(v28.Object, p27);
    end,

    ClearViewport = function(p29, p30) -- Line: 172, Name: ClearViewport
        -- upvalues: u1 (copy)
        p30:ClearAllChildren();
        local v31 = u1[p30];

        if v31 and v31.Connections then
            for _, v in pairs(v31.Connections) do
                v:Disconnect();
            end;
        end;

        u1[p30] = nil;
    end,

    AddSpin = function(u32, u33) -- Line: 183, Name: AddSpin
        -- upvalues: u1 (copy), UserInputService (copy), RunService (copy)
        local u34 = u1[u33];
        local v35 = { u33, unpack(u34.Hitboxes or {}) };
        local u36 = nil;

        for _, v in pairs(v35) do
            table.insert(u34.Connections, v.InputBegan:Connect(function(p37) -- Line: 188
                -- upvalues: u36 (ref), u34 (copy)
                if p37.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return;
                end;

                u36 = p37.Position;
                u34.Held = true;
            end));
        end;

        table.insert(u34.Connections, UserInputService.InputChanged:Connect(function(p38) -- Line: 194
            -- upvalues: u34 (copy), u36 (ref), u32 (copy), u33 (copy)
            if p38.UserInputType ~= Enum.UserInputType.MouseMovement or not u34.Held then
                return;
            end;

            local Position = p38.Position;
            u34.Delta = (Position - u36) * 0.8;
            u32:SpinViewport(u33);
            u36 = Position;
        end));
        table.insert(u34.Connections, UserInputService.InputEnded:Connect(function(p39) -- Line: 201
            -- upvalues: u34 (copy), u36 (ref), RunService (ref)
            if p39.UserInputType ~= Enum.UserInputType.MouseButton1 or not u34.Held then
                return;
            end;

            u34.Held = false;

            if p39.Position == u36 then
                u34.Delta = Vector3.new();
            end;

            while not u34.Held do
                u34.Delta = u34.Delta:Lerp(Vector3.new(0, 0, 0), 0.1);
                RunService.Heartbeat:Wait();
            end;
        end));
    end,

    SpinViewport = function(p40, p41) -- Line: 214, Name: SpinViewport
        -- upvalues: u1 (copy)
        local v42 = u1[p41];

        if not v42 then
            return;
        end;

        local Object = v42.Object;

        if not Object then
            return;
        end;

        local PrimaryPart = Object.PrimaryPart;

        if PrimaryPart then
            Object:SetPrimaryPartCFrame(PrimaryPart.CFrame * CFrame.Angles(0, math.rad(v42.Delta.X), 0));

            return true;
        end;
    end,

    HighlightCharArea = function(p43, p44, p45) -- Line: 225, Name: HighlightCharArea
        -- upvalues: u1 (copy), Selected (copy)
        local v46 = u1[p44];

        if not v46 then
            return;
        end;

        local v47 = p45 == "Head" and { "Head" } or p45 == "Legs" and { "RightUpperLeg", "RightLowerLeg", "RightFoot", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" } or (p45 == "Chest" and { "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand", "UpperTorso", "LowerTorso" } or {});

        for _, child in pairs(v46.Object:GetChildren()) do
            local Name = child.Name;
            local v48;

            if Name:sub(1, 6) == "Armor_" or Name == "Hair" then
                v48 = child:IsA("Model");
            else
                v48 = false;
            end;

            if child.Name ~= "HumanoidRootPart" and (child.Name ~= "CollisionPart" and (child:IsA("BasePart") or v48)) then
                local v49 = {};

                if v48 then
                    for _, child2 in pairs(child:GetChildren()) do
                        if child2 == child.PrimaryPart then
                            Name = child2.Name;
                        end;

                        if child2:IsA("BasePart") and child2.Transparency < 1 then
                            table.insert(v49, child2);
                        end;
                    end;
                else
                    v49[1] = child;
                end;

                local v50 = table.find(v47, Name);

                for _, v in pairs(v49) do
                    local Selected2 = v:FindFirstChild("Selected");

                    if v50 then
                        if Selected2 then
                            for i, child2 in pairs(v:GetChildren()) do
                                if child2.Name == "Selected" and child2:IsA("Decal") then
                                    child2.Transparency = v50 and Selected.Transparency or 1;
                                end;
                            end;
                        else
                            for _, v2 in pairs(Enum.NormalId:GetEnumItems()) do
                                local v51 = Selected:Clone();
                                v51.Face = v2;
                                v51.Parent = v;
                            end;
                        end;
                    elseif Selected2 then
                        for i, child2 in pairs(v:GetChildren()) do
                            if child2.Name == "Selected" and child2:IsA("Decal") then
                                child2.Transparency = v50 and Selected.Transparency or 1;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end
};

function u52.Initialize(p53) -- Line: 309
    -- upvalues: u1 (copy), LocalPlayer (copy), u52 (copy)
    for i, v in pairs(u1) do
        local Object = v.Object;

        if Object and Object:IsDescendantOf(LocalPlayer) then
            if not (v.Held or u52:SpinViewport(i)) then
                if Object then
                    Object:Destroy();
                end;

                u1[i] = nil;
            end;
        else
            u1[i] = nil;
        end;
    end;
end;

return u52;