-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local Debris = game:GetService("Debris");
local VFX = ReplicatedStorage:WaitForChild("VFX");
local VFX2 = workspace:WaitForChild("VFX");
local Animals = workspace:WaitForChild("Animals");
local Events = workspace:WaitForChild("Events");
local Values = ReplicatedStorage:WaitForChild("Values");
local LocalPlayer = Players.LocalPlayer;

return {
    FilterFunction = function(p1, u2) -- Line: 27, Name: FilterFunction
        -- upvalues: Animals (copy), Events (copy)
        return (u2 == "Hit" or (u2 == "HitIgnore" or (u2 == "HitMelee" or (u2 == "HitMeleeIgnore" or u2 == "HitNoMeleeMouse")))) and function(p3) -- Line: 28
            -- upvalues: Animals (ref), Events (ref), u2 (copy)
            local Parent = p3.Parent;

            if not Parent then
                return;
            end;

            if Parent.Parent:FindFirstChild("Humanoid") and not (Parent:IsDescendantOf(Animals) or Parent:IsDescendantOf(Events)) or (Parent.Parent.Name == "Attachments" and Parent.Parent:IsA("Folder") or (Parent.Name == "Jail Wall" or p3:FindFirstAncestor("Jail Door")) and u2 == "Hit") or p3.CollisionGroup == "Items" and (u2 == "Hit" and (Parent.Name == "Body Bag" or (Parent.Name == "Contents" or (Parent.Name == "Salvaged Backpack" or Parent.Name == "Military Backpack")))) then
                return Parent;
            end;

            if Parent:FindFirstChild("Humanoid") and (p3.Name == "HumanoidRootPart" or p3.Name == "CollisionPart") or p3.Transparency >= 1 and (u2 ~= "HitMelee" or Parent.Name ~= "NodeSpark" and Parent.Name ~= "TreeX") and not p3.CanCollide or (p3.Name == "LeafPart" or (p3.CollisionGroup == "VehicleFake" or p3.Name == "CactusPart" and u2 == "Hit") or p3.Name == "SignPart" and not u2:find("Melee")) then
                return p3;
            end;
        end or (u2 == "HitPlace" and function(p4) -- Line: 36
            local Parent = p4.Parent;

            if Parent.Parent.Name == "Attachments" and Parent.Parent:IsA("Folder") then
                return Parent;
            end;

            if p4.Transparency >= 1 and (Parent.Name ~= "CollisionParts" and (p4.Name ~= "SpawnPart" and not p4.CanCollide)) or (Parent:FindFirstChild("CollisionParts") or Parent.Parent:FindFirstChild("CollisionParts") and Parent.Name ~= "CollisionParts" or (p4.Name == "LeafPart" or p4.CollisionGroup == "VehicleFake")) then
                return p4;
            end;

            if Parent:FindFirstChild("Humanoid") and (p4.Name ~= "HumanoidRootPart" and p4.Name ~= "CollisionPart") then
                return p4;
            end;

            if Parent.Parent:FindFirstChild("Humanoid") then
                return Parent;
            end;
        end or (u2 == "View" or (u2 == "ViewBench" or (u2 == "ViewExtra" or u2 == "ViewPlant"))) and function(p5) -- Line: 53
            -- upvalues: u2 (copy)
            local Parent = p5.Parent;
            local v6 = Parent:FindFirstChild("Humanoid") or Parent.Parent:FindFirstChild("Humanoid");

            if v6 and (u2 == "View" or (u2 == "ViewPlant" or v6.Parent.Name ~= "Sleeper")) and (u2 ~= "ViewBench" or v6.Parent.Name ~= "Contents") then
                return v6.Parent;
            end;

            if Parent.Parent.Name == "Attachments" and Parent.Parent:IsA("Folder") or (u2 == "ViewPlant" and (Parent.Name == "Floor Grill" or Parent.Name == "Barrel Light") or u2 == "ViewExtra" and (Parent.Name == "Wooden Boat" or (Parent.Name == "Military Boat" or Parent.Name == "Salvaged Flycopter"))) then
                return Parent;
            end;

            if ((u2 == "View" or u2 == "ViewPlant") and p5.Transparency >= 1 or u2 == "ViewBench" and p5.Transparency == 1) and not p5.CanCollide or (p5.Name == "LeafPart" or (u2 == "View" or u2 == "ViewExtra") and p5.CollisionGroup == "VehicleFake" or (p5.Name == "CactusPart" or p5.Name == "SignPart" or (u2 == "View" or u2 == "ViewPlant") and p5.CollisionGroup == "Items")) then
                return p5;
            end;

            if u2 == "ViewExtra" and (p5.CollisionGroup == "Items" or not p5.CanCollide) then
                return p5;
            end;

            if Parent and u2 == "ViewExtra" then
                local Parent2 = Parent.Parent;

                if Parent2 and Parent2.Name == "Salvaged Flycopter" then
                    return Parent2;
                end;
            end;
        end or (u2 == "PlacementDefault" and function(p7) -- Line: 70
            if not p7 then
                return;
            end;

            local Parent = p7.Parent;

            if not Parent then
                return;
            end;

            if p7.Name == "LeafPart" or p7.CollisionGroup == "VehicleFake" then
                return p7;
            end;

            if p7.Transparency == 1 and (p7.Position.Y == 478 or (p7.Position.Y == 578 or p7.Name == "RadiationPart")) or Parent.Parent.Name == "Attachments" and Parent.Parent:IsA("Folder") then
                return p7.Parent;
            end;

            if p7.Transparency == 1 and p7.Name == "BuildingPriv" then
                return p7;
            end;

            local v8 = Parent:FindFirstChild("Humanoid") or Parent.Parent:FindFirstChild("Humanoid");

            if v8 then
                return v8.Parent;
            end;
        end or (u2 == "BuildingPrivCheck" and function(p9) -- Line: 90
            local v10 = p9.Name == "BuildingPriv" and p9:FindFirstAncestor("Base");

            if v10 then
                local v11 = v10:FindFirstChild("Base Cabinet");

                if v11 and #v11:GetChildren() > 0 then
                    return;
                end;
            end;

            return p9;
        end or false)));
    end,

    MouseRaycast = function(p12, p13, p14, p15, p16, p17, p18) -- Line: 102, Name: MouseRaycast
        -- upvalues: LocalPlayer (ref)
        if not LocalPlayer then
            return;
        end;

        local v19 = {};

        for i = 1, 10 do
            local v20 = debug.info(i, "s");

            if not v20 then
                break;
            end;

            table.insert(v19, v20);
        end;

        if v19[1] == "ReplicatedStorage.Modules.RaycastUtil" and (v19[2] == "ReplicatedStorage.Modules.VectorUtil" and (v19[3] == "[C]" and (v19[4] == v19[2] and (v19[6] == v19[2] and v19[9] == nil))) or v19[2] == `Workspace .{LocalPlayer.Name}.ViewmodelController` and (v19[3] == nil and #v19 == 2)) then
            local UnitRay = LocalPlayer:GetMouse().UnitRay;
            local v21, v22, v23, v24 = p12:Raycast(UnitRay.Origin, UnitRay.Direction * (p15 or 1024), p16 or "Blacklist", p14, p17, p13, p18);

            return v22, v21, v23, v24, nil, "sigma";
        end;

        if LocalPlayer then
            print("`");
        end;

        LocalPlayer = nil;
    end,

    GetBaseCabinetUnder = function(p25, p26, p27) -- Line: 124, Name: GetBaseCabinetUnder
        -- upvalues: VFX2 (copy), Animals (copy), LocalPlayer (ref)
        local u28 = { VFX2, Animals };
        local u29 = nil;
        local u30 = nil;
        local v31;

        while true do
            v31 = p25:Raycast(Vector3.new(p26.X, 225.6, p26.Z), Vector3.new(0, -0.2, 0), "Blacklist", u28, false, function(p32) -- Line: 128
                -- upvalues: u28 (copy), u29 (ref), u30 (ref)
                if p32.Name ~= "BuildingPriv" then
                    return p32;
                end;

                local v33 = p32:FindFirstAncestor("Base");

                if v33 and not table.find(u28, v33) then
                    table.insert(u28, v33);
                    local v34 = v33:FindFirstChild("Base Cabinet");
                    local v35 = v34 and v34:FindFirstChild("Base Cabinet");

                    if v35 then
                        if v35:GetAttribute("Monument") then
                            u29 = v35;

                            return;
                        end;

                        local v36 = v35:GetAttribute("Placed");
                        local v37 = u30 and u30.Parent and u30:GetAttribute("Placed");

                        if not v37 or v36 < v37 then
                            u30 = v35;
                        end;
                    end;
                end;
            end);

            if u29 and v31 then
                break;
            end;

            if p27 or not v31 then
                return u30;
            end;
        end;

        if not LocalPlayer then
            v31:SetAttribute("LastEnter", os.time());
        end;

        return u29, v31:GetAttribute("Safe");
    end,

    Raycast = function(p38, p39, p40, p41, p42, p43, p44, p45, p46, p47) -- Line: 164, Name: Raycast
        -- upvalues: VFX (copy), VFX2 (copy), Debris (copy), Values (copy)
        local v48 = type(p42) == "table" and p42 and p42 or { p42 };
        local v49 = (p46 or 0) + 1;
        local v50 = RaycastParams.new();
        v50.FilterType = Enum.RaycastFilterType[p41];
        v50.FilterDescendantsInstances = v48;
        v50.IgnoreWater = p45;
        local v51;

        if type(p39) == "table" then
            v51 = p39.Type == "Block";
        else
            v51 = false;
        end;

        local v52;

        if type(p39) == "table" then
            v52 = p39.Type == "Sphere";
        else
            v52 = false;
        end;

        local v53;

        if v51 then
            v53 = workspace:Blockcast(p39.CF, p39.Size, p40, v50);
        elseif v52 then
            v53 = workspace:Spherecast(p39.Position, p39.Size, p40, v50);
        else
            v53 = workspace:Raycast(p39, p40, v50);
        end;

        local v54 = v51 and p39.CF.Position;

        if not v54 then
            if v52 then
                v54 = p39.Position or p39;
            else
                v54 = p39;
            end;
        end;

        local v55 = v54 + p40;
        local v56;

        if v53 == nil then
            v56 = v55;
        else
            v56 = v53.Position or v55;
        end;

        local v57 = nil;

        if p43 then
            local v58 = VFX:FindFirstChild(p43) or VFX:FindFirstChild("DefaultRay");

            if v58 then
                local Magnitude = (p39 - v56).Magnitude;
                v57 = v58:Clone();

                for _, child in pairs(v57:GetChildren()) do
                    if child:IsA("BasePart") then
                        local Size = child.Size;
                        child.Size = Vector3.new(Magnitude, Size.Y, Size.Z);
                    end;
                end;

                v57:SetPrimaryPartCFrame(CFrame.lookAt(p39, v56) * CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-Magnitude / 2, 0, 0));
                v57.Parent = VFX2;

                if v57.Name == "GreenRay" or v57.Name == "BlueRay" then
                    Debris:AddItem(v57, 5);
                end;
            end;
        end;

        if not v53 then
            return nil, v56, nil, nil, v57, p47;
        end;

        local Instance = v53.Instance;

        if p44 and type(p44) == "function" then
            local v59, v60 = p44(Instance);
            p47 = p47 or v60;

            if v59 then
                for _, v in pairs(type(v59) == "table" and v59 and v59 or { v59 }) do
                    table.insert(v48, v);
                end;

                local v61 = Values.Loading.Value and 50 or 250;

                if v49 < v61 then
                    if not (v51 or v52) then
                        local v62 = v56 - p40.Unit * 0.2;

                        return p38:Raycast(v62, v55 - v62, p41, v48, p43, p44, p45, v49, p47);
                    end;

                    local _ = p39.Size;
                    local v63 = v51 and p39.CF or CFrame.new(p39.Position);
                    local Distance = v53.Distance;
                    local v64, v65, v66 = v63:ToEulerAnglesXYZ();
                    local v67 = v54 + p40.Unit * math.max(Distance - 0.5, 0);
                    local v68 = CFrame.new(v67) * CFrame.Angles(v64, v65, v66);

                    if v51 then
                        p39.CF = v68;
                    elseif v52 then
                        p39.Position = v68.Position;
                    end;

                    return p38:Raycast(p39, v55 - v67, p41, v48, p43, p44, p45, v49, p47);
                end;

                warn((`[WARNING] RAYCAST RE-ENTRANCY EXCEEDED ({v61})`));
            end;
        end;

        return Instance, v56, v53.Normal, v53.Material, v57, p47;
    end,

    GetClosestPointFromRay = function(p69, p70, p71, p72) -- Line: 252, Name: GetClosestPointFromRay
        local v73 = p71 - p70;
        local Magnitude = v73.Magnitude;
        local Unit = v73.Unit;
        local v74 = (p72 - p70):Dot(Unit);
        local v75 = (Magnitude <= 0.0001 or v74 <= 0) and 0 or math.clamp(v74, 0, Magnitude);

        return p70 + Unit * v75, v75, Magnitude;
    end,

    NormalToFace = function(p76, p77, p78) -- Line: 262, Name: NormalToFace
        for _, v in pairs(Enum.NormalId:GetEnumItems()) do
            if p78.CFrame:VectorToWorldSpace(Vector3.FromNormalId(v)):Dot(p77) > 0.999 then
                return v;
            end;
        end;
    end
};