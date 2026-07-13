-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local _ = game:GetService("Debris");
local v50 = game:GetService("Players");
local v51 = game:GetService("StarterGui");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Benches_upv_1 = ReplicatedStorage_1:WaitForChild("Benches");
local v52 = ReplicatedStorage_1:WaitForChild("Values");
local VFX_upv_1 = workspace:WaitForChild("VFX");
local RaycastUtil_upv_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local ActiveBenchModule_upv_1 = require(Modules_1:WaitForChild("ActiveBenchModule"));
local u1 = nil;
local u2 = RaycastUtil_upv_1:FilterFunction("HitPlace");
local function v1(a1, a2, a3, a4, a5)
    --[[
      line: 208
      upvalues:
        u1 (ref, index: 1)
    ]]
    local v2 = u1[a1];
    if (v2) then
        local PlaceableAngles_1 = v2.PlaceableAngles;
        local PlaceBlacklist_1 = v2.PlaceBlacklist;
        local PlaceWhitelist_1 = v2.PlaceWhitelist;
        local TerrainMaterialWhitelist_1 = v2.TerrainMaterialWhitelist;
        local v3 = false;
        if (a2 ~= nil) then
            v3 = false;
            if (PlaceableAngles_1.Min <= a3) then
                v3 = false;
                if (a3 <= PlaceableAngles_1.Max) then
                    v3 = false;
                    if (a4 ~= nil) then
                        v3 = false;
                        if (a4 == a2) then
                            v3 = false;
                            if (a4.Parent:GetAttribute("Open") == nil) then
                                v3 = a4.Parent.Parent:GetAttribute("Open") == nil;
                            end;
                        end;
                    end;
                end;
            end;
        end;
        local v4, v5 = nil, nil;
        if (v3) then
            if (not (PlaceBlacklist_1) and not (PlaceWhitelist_1) and not (TerrainMaterialWhitelist_1)) then
                return v3;
            end;
            v4 = a4.Name == "Terrain";
            if (v4 and TerrainMaterialWhitelist_1) then
                if (a5 and table.find(TerrainMaterialWhitelist_1, a5.Name)) then
                    v5 = a4.Parent;
                    local v6;
                    if (v5:IsA("Model") and v5.Parent ~= game and v5.Parent:IsA("Model")) then
                        if (v5.Name == "_Floor") then
                            v6 = v5;
                        else
                            v6 = v5.Parent or v5;
                        end;
                    else
                        v6 = v5;
                    end;
                    if (PlaceWhitelist_1 and (v4 and not (table.find(PlaceWhitelist_1, "Terrain")) or v4 == false and not (table.find(PlaceWhitelist_1, v6.Name))) or PlaceBlacklist_1 and (v4 and table.find(PlaceBlacklist_1, "Terrain") or v4 == false and table.find(PlaceBlacklist_1, v6.Name))) then
                        return false;
                    end;
                    return v3;
                end;
                return false;
            else
                v5 = a4.Parent;
                local v6;
                if (v5:IsA("Model") and v5.Parent ~= game and v5.Parent:IsA("Model")) then
                    if (v5.Name == "_Floor") then
                        v6 = v5;
                    else
                        v6 = v5.Parent or v5;
                    end;
                else
                    v6 = v5;
                end;
            end;
            if (PlaceWhitelist_1 and (v4 and not (table.find(PlaceWhitelist_1, "Terrain")) or v4 == false and not (table.find(PlaceWhitelist_1, v6.Name))) or PlaceBlacklist_1 and (v4 and table.find(PlaceBlacklist_1, "Terrain") or v4 == false and table.find(PlaceBlacklist_1, v6.Name))) then
                return false;
            end;
        end;
        return v3;
    end;
end;
local function u3(a1, a2, a3)
    --[[
      line: 237
      upvalues:
        Benches_upv_1 (copy, index: 1)
        VFX_upv_1 (copy, index: 2)
    ]]
    local PrimaryPart_1 = a1.PrimaryPart;
    local v7 = Benches_upv_1:FindFirstChild(a1.Name);
    if (v7 and v7:IsA("Model")) then
        local v8, v9 = nil, nil;
        if (PrimaryPart_1) then
            v8 = v7:FindFirstChild("Main");
            v9 = ((a3 and v7) or a1):FindFirstChild("NonBaseCollisionParts");
            if (v9 and v8) then
                local _ = a2 and (a2:FindFirstAncestor("Base"));
                local v10 = OverlapParams.new();
                v10.FilterType = Enum.RaycastFilterType.Exclude;
                v10.FilterDescendantsInstances = {VFX_upv_1, a1};
                local v14;
                local v11 = nil;
                local value_1 = nil;
                local v12 = nil;
                local v13 = nil;
                for v15, value_1 in pairs(v9:GetChildren()) do
                    v11 = value_1:IsA("BasePart");
                    if (not (v11)) then
                        continue;
                    end;
                    v11 = nil;
                    if (a3) then
                        v11 = value_1:Clone();
                        v11.Name = "CollisionPart";
                        v11.Transparency = 1;
                        v11.CanCollide = false;
                        v11.CanQuery = false;
                        v11.Parent = VFX_upv_1;
                        v11.CFrame = PrimaryPart_1.CFrame * v8.CFrame:ToObjectSpace(value_1.CFrame);
                    end;
                    v12 = workspace:GetPartsInPart(v11 or value_1, v10);
                    if (v11) then
                        v11:Destroy();
                    end;
                    for v16, value_2 in pairs(v12) do
                        v13 = value_2:FindFirstAncestor("Base");
                        if (not (v13) or v13 == a2 or a2 and v13:GetAttribute("BaseId") == a2:GetAttribute("BaseId") and value_1.Name == "CollisionNonFoundy") then
                            continue;
                        end;
                        return false;
                    end;
                end;
            end;
        end;
    end;
    return true;
end;
local function u4(a1, a2, a3, a4, a5, a6)
    --[[
      line: 289
      upvalues:
        u3 (copy, index: 1)
        RaycastUtil_upv_1 (copy, index: 2)
        VFX_upv_1 (copy, index: 3)
        u1 (ref,  index: 4)
        u2 (copy, index: 5)
    ]]
    if (a2 and not (u3(a1, a3))) then
        return false;
    end;
    local RayParts_1 = a1:FindFirstChild("RayParts");
    if (RayParts_1) then
        local CFrame_1 = nil;
        local Size_1 = nil;
        local v14 = nil;
        for _, value_3 in pairs(RayParts_1:GetChildren()) do
            CFrame_1 = value_3.CFrame;
            Size_1 = value_3.Size;
            for n_1 = -1, 1, 2 do
                local Position_1 = (CFrame_1 * CFrame.new(0, 0, (-Size_1.Z / 2) * n_1)).Position;
                v14 = RaycastUtil_upv_1:Raycast(Position_1, (CFrame_1 * CFrame.new(0, 0, (Size_1.Z / 2) * n_1)).Position - Position_1, "Whitelist", workspace.Terrain);
                if (not (v14)) then
                    continue;
                end;
                return false;
            end;
        end;
        local v15 = OverlapParams.new();
        v15.FilterType = Enum.RaycastFilterType.Exclude;
        v15.FilterDescendantsInstances = {VFX_upv_1};
        local BaseCollisionParts_1 = a1:FindFirstChild("BaseCollisionParts");
        if (BaseCollisionParts_1) then
            local _ = nil;
            local v18 = nil;
            local v16 = nil;
            local v17 = nil;
            for v19, value_4 in pairs(BaseCollisionParts_1:GetChildren()) do
                if (not (value_4:IsA("BasePart"))) then
                    continue;
                end;
                for v20, value_5 in pairs(workspace:GetPartsInPart(value_4, v15)) do
                    v17 = value_5.Parent;
                    if (v17.Name ~= "CollisionParts" or not (value_5:FindFirstAncestor("Base"))) then
                        continue;
                    end;
                    v16 = u1[v17.Parent.Name];
                    if (not (v16) or v16.Type ~= "BasePart") then
                        continue;
                    end;
                    return false;
                end;
            end;
            local CollisionParts_1 = a1:FindFirstChild("CollisionParts");
            if (CollisionParts_1) then
                local v21 = nil;
                local v14;
                for v22, value_6 in pairs(CollisionParts_1:GetChildren()) do
                    if (not (value_6:IsA("BasePart"))) then
                        continue;
                    end;
                    for v23, value_7 in pairs(workspace:GetPartsInPart(value_6, v15)) do
                        if (a5 ~= false and (a4 == "BasePart" or a4 == "Door" or a5)) then
                            if (value_7.Name == "BoulderPart"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly") then
                                continue;
                            end;
                        elseif (value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7) or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly"
                            or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly") then
                            continue;
                        end;
                        return false;
                    end;
                end;
            end;
            return true;
        else
            local CollisionParts_1 = a1:FindFirstChild("CollisionParts");
            if (CollisionParts_1) then
                local v21 = nil;
                local v14;
                for v22, value_6 in pairs(CollisionParts_1:GetChildren()) do
                    if (not (value_6:IsA("BasePart"))) then
                        continue;
                    end;
                    for v23, value_7 in pairs(workspace:GetPartsInPart(value_6, v15)) do
                        if (a5 ~= false and (a4 == "BasePart" or a4 == "Door" or a5)) then
                            if (value_7.Name == "BoulderPart"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly") then
                                continue;
                            end;
                        elseif (value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7) or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly"
                            or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly") then
                            continue;
                        end;
                        return false;
                    end;
                end;
            end;
            return true;
        end;
    else
        local v15 = OverlapParams.new();
        v15.FilterType = Enum.RaycastFilterType.Exclude;
        v15.FilterDescendantsInstances = {VFX_upv_1};
        local BaseCollisionParts_1 = a1:FindFirstChild("BaseCollisionParts");
        if (BaseCollisionParts_1) then
            local _ = nil;
            local v18 = nil;
            local v16 = nil;
            local v17 = nil;
            for v19, value_4 in pairs(BaseCollisionParts_1:GetChildren()) do
                if (not (value_4:IsA("BasePart"))) then
                    continue;
                end;
                for v20, value_5 in pairs(workspace:GetPartsInPart(value_4, v15)) do
                    v17 = value_5.Parent;
                    if (v17.Name ~= "CollisionParts" or not (value_5:FindFirstAncestor("Base"))) then
                        continue;
                    end;
                    v16 = u1[v17.Parent.Name];
                    if (not (v16) or v16.Type ~= "BasePart") then
                        continue;
                    end;
                    return false;
                end;
            end;
            local CollisionParts_1 = a1:FindFirstChild("CollisionParts");
            if (CollisionParts_1) then
                local v21 = nil;
                local v14;
                for v22, value_6 in pairs(CollisionParts_1:GetChildren()) do
                    if (not (value_6:IsA("BasePart"))) then
                        continue;
                    end;
                    for v23, value_7 in pairs(workspace:GetPartsInPart(value_6, v15)) do
                        if (a5 ~= false and (a4 == "BasePart" or a4 == "Door" or a5)) then
                            if (value_7.Name == "BoulderPart"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly") then
                                continue;
                            end;
                        elseif (value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7) or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly"
                            or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly") then
                            continue;
                        end;
                        return false;
                    end;
                end;
            end;
        else
            local CollisionParts_1 = a1:FindFirstChild("CollisionParts");
            if (CollisionParts_1) then
                local v21 = nil;
                local v14;
                for v22, value_6 in pairs(CollisionParts_1:GetChildren()) do
                    if (not (value_6:IsA("BasePart"))) then
                        continue;
                    end;
                    for v23, value_7 in pairs(workspace:GetPartsInPart(value_6, v15)) do
                        if (a5 ~= false and (a4 == "BasePart" or a4 == "Door" or a5)) then
                            if (value_7.Name == "BoulderPart"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly"
                                or value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7)
                                    or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly" or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly") then
                                continue;
                            end;
                        elseif (value_7.Name == "CollisionRug" and value_6.Name ~= "CollisionRug" or value_6.Name == "CollisionIgnoreSame" and value_7.Name == "CollisionIgnoreSame" or value_6.Name == "CollisionFloorFrame" and value_7.Name == "CollisionLargeFurnace" or value_7.Name == "CollisionFloorFrame" and value_6.Name == "CollisionLargeFurnace" or value_7.Parent and value_7.Parent.Name == "_Floor" or u2(value_7) or value_6.Name == "CollisionSameOnly" and value_7.Name ~= "CollisionSameOnly"
                            or value_7.Name == "CollisionSameOnly" and value_6.Name ~= "CollisionSameOnly") then
                            continue;
                        end;
                        return false;
                    end;
                end;
            end;
        end;
    end;
end;
local tbl_1 = {};
do
    local tbl_2 = {};
    tbl_2.BenchNames = {"Foundation", "Floor", "Floor Frame"};
    tbl_2.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 5, 5);
    local tbl_3 = {};
    tbl_3.BenchNames = {"Foundation", "Floor", "Floor Frame"};
    tbl_3.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0, 5, 5);
    local tbl_4 = {};
    tbl_4.BenchNames = {"Foundation", "Floor", "Floor Frame"};
    tbl_4.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(0, 5, 5);
    local tbl_5 = {};
    tbl_5.BenchNames = {"Triangle Foundation", "Triangle Floor", "Triangle Floor Frame"};
    tbl_5.Offset = CFrame.new(-5, 0, 4.333, 0, -1, 0, 1, 0, 0, 0, 0, 1);
    local tbl_6 = {};
    tbl_6.BenchNames = {"Triangle Foundation", "Triangle Floor", "Triangle Floor Frame"};
    tbl_6.Offset = CFrame.new(-5, 2.5, 0, 0, -1, 0, -0.5, 0, 0.866, -0.866, 0, -0.5);
    local tbl_7 = {};
    tbl_7.BenchNames = {"Triangle Foundation", "Triangle Floor", "Triangle Floor Frame"};
    tbl_7.Offset = CFrame.new(-5, -2.5, 0, 0, -1, 0, -0.5, 0, -0.866, 0.866, 0, -0.5);
    local tbl_8 = {};
    tbl_8.BenchNames = {"Wall", "Wall Frame", "Doorway", "Window"};
    tbl_8.Offset = CFrame.new(0, 10, 0);
    local tbl_9 = {};
    tbl_9.BenchNames = {"Half Wall"};
    tbl_9.Offset = CFrame.new(0, 7.5, 0);
    tbl_1.SnapPoints = {{BenchNames = {"Foundation", "Floor", "Floor Frame"}, Offset = CFrame.Angles(0, 0, 0) * CFrame.new(0, 5, 5)}, tbl_2, tbl_3, tbl_4, tbl_5, tbl_6, tbl_7, tbl_8, tbl_9};
end;
do
    local tbl_10 = {};
    local tbl_11 = {};
    tbl_11.Offset = CFrame.new(-4, -4.3, 0.6) * CFrame.Angles(-1.5707963267948966, 0, 0);
    tbl_10.Rays = {{Offset = CFrame.new(4, -4.3, 0.6) * CFrame.Angles(-1.5707963267948966, 0, 0)}, tbl_11};
    local tbl_12 = {};
    local tbl_13 = {};
    tbl_13.Offset = CFrame.new(-4, -4.3, -0.6) * CFrame.Angles(-1.5707963267948966, 0, 0);
    tbl_12.Rays = {{Offset = CFrame.new(4, -4.3, -0.6) * CFrame.Angles(-1.5707963267948966, 0, 0)}, tbl_13};
    local tbl_14 = {};
    tbl_14.Rays = {{Offset = CFrame.new(0, 4.8, 0) * CFrame.Angles(1.5707963267948966, 0, 0)}};
    local tbl_15 = {};
    tbl_15.Rays = {{Offset = CFrame.new(0, -4.8, 0) * CFrame.Angles(-1.5707963267948966, 0, 0)}};
    local tbl_16 = {};
    local tbl_17 = {};
    tbl_17.Offset = CFrame.new(-5.6, -2.5, -0.6) * CFrame.Angles(math.pi, 0, 0);
    tbl_16.Rays = {{Offset = CFrame.new(-5.6, -2.5, 0.6) * CFrame.Angles(0, 0, 0)}, tbl_17};
    local tbl_18 = {};
    local tbl_19 = {};
    tbl_19.Offset = CFrame.new(-5.6, 2.5, -0.6) * CFrame.Angles(math.pi, 0, 0);
    tbl_18.Rays = {{Offset = CFrame.new(-5.6, 2.5, 0.6) * CFrame.Angles(0, 0, 0)}, tbl_19};
    local tbl_20 = {};
    local tbl_21 = {};
    tbl_21.Offset = CFrame.new(5.6, -2.5, -0.6) * CFrame.Angles(math.pi, 0, 0);
    tbl_20.Rays = {{Offset = CFrame.new(5.6, -2.5, 0.6) * CFrame.Angles(0, 0, 0)}, tbl_21};
    local tbl_22 = {};
    local tbl_23 = {};
    tbl_23.Offset = CFrame.new(5.6, 2.5, -0.6) * CFrame.Angles(math.pi, 0, 0);
    tbl_22.Rays = {{Offset = CFrame.new(5.6, 2.5, 0.6) * CFrame.Angles(0, 0, 0)}, tbl_23};
    local tbl_24 = {};
    local tbl_25 = {};
    tbl_25.Offset = CFrame.new(-4, 4.3, 0.6) * CFrame.Angles(1.5707963267948966, 0, 0);
    tbl_24.Rays = {{Offset = CFrame.new(4, 4.3, 0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}, tbl_25};
    local tbl_26 = {};
    tbl_26.Rays = {{Offset = CFrame.new(4, 4.3, -0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}, {Offset = CFrame.new(-4, 4.3, -0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}};
    local tbl_27 = {};
    tbl_27.Rays = {{Offset = CFrame.new(4, -0.7, 0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}, {Offset = CFrame.new(-4, -0.7, 0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}};
    local tbl_28 = {};
    tbl_28.Rays = {{Offset = CFrame.new(4, -0.7, -0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}, {Offset = CFrame.new(-4, -0.7, -0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}};
    tbl_1.AttachmentChecks = {{BenchNames = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Floor Frame", "Triangle Floor Frame"}, Checks = {tbl_10, tbl_12}}, {BenchNames = {"Wall", "Wall Frame", "Doorway", "Window", "Half Wall"}, Checks = {tbl_14, tbl_15, tbl_16, tbl_18, tbl_20, tbl_22}}, {BenchNames = {"Floor", "Triangle Floor", "Floor Frame", "Triangle Floor Frame"}, Checks = {tbl_24, tbl_26, tbl_27, tbl_28}}};
end;
tbl_1.StabilityInfo = {LossPerHeight = {}, Checks = {{Connections = {4}, StabilityLoss = {0}}, {Connections = {1, 2}, StabilityLoss = {0, 0}, BenchNames = {"Foundation", "Triangle Foundation"}}, {Connections = {1, 2}, StabilityLoss = {20, 10}}, {Connections = {5, 6, 7, 8}, StabilityLoss = {75, 60, 45, 40}}}};
tbl_1.NextConnections = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12};
local tbl_29 = {};
do
    local tbl_30 = {};
    tbl_30.BenchNames = {"Floor", "Floor Frame"};
    tbl_30.Offset = CFrame.new(10, 0, 0);
    local tbl_31 = {};
    tbl_31.BenchNames = {"Floor", "Floor Frame"};
    tbl_31.Offset = CFrame.new(-10, 0, 0);
    local tbl_32 = {};
    tbl_32.BenchNames = {"Triangle Floor", "Triangle Floor Frame"};
    tbl_32.Offset = CFrame.new(0, 0, 9.333, 0, -1, 0, 0, 0, 1, -1, 0, 0);
    local tbl_33 = {};
    tbl_33.BenchNames = {"Triangle Floor", "Triangle Floor Frame"};
    tbl_33.Offset = CFrame.new(0, 6.83, -2.497, 0, -1, 0, 0.5, 0, -0.866, 0.866, 0, 0.5);
    local tbl_34 = {};
    tbl_34.BenchNames = {"Triangle Floor", "Triangle Floor Frame"};
    tbl_34.Offset = CFrame.new(0, -6.83, -2.497, 0, -1, 0, 0.866, 0, -0.5, 0.5, 0, 0.866);
    local tbl_35 = {};
    tbl_35.BenchNames = {"Wall", "Wall Frame", "Doorway", "Window"};
    tbl_35.Offset = CFrame.new(0, 5, 5);
    local tbl_36 = {};
    tbl_36.BenchNames = {"Wall", "Wall Frame", "Doorway", "Window"};
    tbl_36.Offset = CFrame.new(0, 5, -5);
    local tbl_37 = {};
    tbl_37.BenchNames = {"Half Wall"};
    tbl_37.Offset = CFrame.new(0, 2.5, 5);
    local tbl_38 = {};
    tbl_38.BenchNames = {"Half Wall"};
    tbl_38.Offset = CFrame.new(0, 2.5, -5);
    tbl_29.SnapPoints = {{BenchNames = {"Floor", "Floor Frame"}, Offset = CFrame.new(0, 0, 10)}, {BenchNames = {"Floor", "Floor Frame"}, Offset = CFrame.new(0, 0, -10)}, tbl_30, tbl_31, tbl_32, tbl_33, tbl_34, tbl_35, tbl_36, tbl_37, tbl_38};
end;
do
    local tbl_39 = {};
    local tbl_40 = {};
    tbl_40.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, 0, -4.4);
    tbl_39.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, 0, -4.4)}, tbl_40};
    local tbl_41 = {};
    local tbl_42 = {};
    tbl_42.Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, 0, -4.4);
    tbl_41.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, 0, -4.4)}, tbl_42};
    local tbl_43 = {};
    local tbl_44 = {};
    tbl_44.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, 0, -4.4);
    tbl_43.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, 0, -4.4)}, tbl_44};
    local tbl_45 = {};
    local tbl_46 = {};
    tbl_46.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, 0, -4.4);
    tbl_45.Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, 0, -4.4)}, tbl_46};
    local tbl_47 = {};
    local tbl_48 = {};
    tbl_48.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, 0.6, -4.3);
    tbl_47.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, 0.6, -4.3)}, tbl_48};
    local tbl_49 = {};
    tbl_49.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, 0.6, -4.3)}, {Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, 0.6, -4.3)}};
    local tbl_50 = {};
    tbl_50.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, 0.6, -4.3)}, {Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, 0.6, -4.3)}};
    local tbl_51 = {};
    tbl_51.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, -0.6, -4.3)}, {Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, -0.6, -4.3)}};
    local tbl_52 = {};
    tbl_52.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, -0.6, -4.3)}, {Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, -0.6, -4.3)}};
    local tbl_53 = {};
    tbl_53.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, -0.6, -4.3)}, {Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, -0.6, -4.3)}};
    local tbl_54 = {};
    tbl_54.Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, -0.6, -4.3)}, {Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, -0.6, -4.3)}};
    tbl_29.AttachmentChecks = {{BenchNames = {"Floor", "Triangle Floor", "Floor Frame", "Triangle Floor Frame"}, Checks = {tbl_39, tbl_41, tbl_43, tbl_45}}, {BenchNames = {"Wall", "Wall Frame", "Doorway", "Window", "Half Wall", "Low Wall", "Wall Block"}, Checks = {tbl_47, tbl_49, tbl_50, {Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, 0.6, -4.3)}, {Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, 0.6, -4.3)}}}, tbl_51, tbl_52, tbl_53, tbl_54}}};
end;
tbl_29.StabilityInfo = {Checks = {{Connections = {9, 10, 11, 12}, StabilityLoss = {15, 8, 4, 0}}, {Connections = {1, 2, 3, 4}, StabilityLoss = {75, 25, 10, 5}}}};
tbl_29.NextConnections = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
local tbl_55 = {};
do
    local tbl_56 = {};
    tbl_56.BenchNames = {"Triangle Floor", "Triangle Floor Frame"};
    tbl_56.Offset = CFrame.new(0, -3.748, -2.167, 1, 0, 0, 0, 0.5, -0.866, 0, 0.866, 0.5);
    local tbl_57 = {};
    tbl_57.BenchNames = {"Floor", "Floor Frame"};
    tbl_57.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, -9.333, 0, 1, 0, -1, 0, 0, 0, 0, 1);
    local tbl_58 = {};
    tbl_58.BenchNames = {"Floor", "Floor Frame"};
    tbl_58.Offset = CFrame.Angles(0, 0, 0) * CFrame.new(0, 0, -9.333, 0, 1, 0, -1, 0, 0, 0, 0, 1);
    local tbl_59 = {};
    tbl_59.BenchNames = {"Floor", "Floor Frame"};
    tbl_59.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(0, 0, -9.333, 0, 1, 0, -1, 0, 0, 0, 0, 1);
    local tbl_60 = {};
    tbl_60.BenchNames = {"Floor", "Floor Frame"};
    tbl_60.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0, 0, -9.333, 0, 1, 0, -1, 0, 0, 0, 0, 1);
    local tbl_61 = {};
    tbl_61.BenchNames = {"Wall", "Wall Frame", "Doorway", "Window"};
    tbl_61.Offset = CFrame.new(0, 5, 4.333, 0, 1, 0, 1, 0, 0, 0, 0, -1) * CFrame.Angles(0, 0, math.pi);
    local tbl_62 = {};
    tbl_62.BenchNames = {"Wall", "Wall Frame", "Doorway", "Window"};
    tbl_62.Offset = CFrame.new(0, 5, -4.333, 0, -1, 0, 1, 0, 0, 0, 0, 1) * CFrame.Angles(0, 0, math.pi);
    local tbl_63 = {};
    tbl_63.BenchNames = {"Half Wall"};
    tbl_63.Offset = CFrame.new(0, 2.5, 4.333, 0, 1, 0, 1, 0, 0, 0, 0, -1) * CFrame.Angles(0, 0, math.pi);
    local tbl_64 = {};
    tbl_64.BenchNames = {"Half Wall"};
    tbl_64.Offset = CFrame.new(0, 2.5, -4.333, 0, -1, 0, 1, 0, 0, 0, 0, 1) * CFrame.Angles(0, 0, math.pi);
    tbl_55.SnapPoints = {{BenchNames = {"Triangle Floor", "Triangle Floor Frame"}, Offset = CFrame.new(0, 0, 8.666, 1, 0, 0, 0, -1, 0, 0, 0, -1)}, {BenchNames = {"Triangle Floor", "Triangle Floor Frame"}, Offset = CFrame.new(0, 3.748, -2.167, 1, 0, 0, 0, 0.5, 0.866, 0, -0.866, 0.5)}, tbl_56, tbl_57, tbl_58, tbl_59, tbl_60, tbl_61, tbl_62, tbl_63, tbl_64};
end;
do
    local tbl_65 = {};
    tbl_65.Rays = {{Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(0, -5, -1.9)}, {Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(0, 2.6, -1.9)}};
    local tbl_66 = {};
    do
        local tbl_67 = {};
        tbl_67.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0.6, -4, -3.6);
        tbl_66.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0.6, 4, -3.6)}, tbl_67};
    end;
    local tbl_68 = {};
    tbl_68.Rays = {{Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(-0.6, -5, -1.6)}, {Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(-0.6, 2.6, -1.6)}};
    local tbl_69 = {};
    tbl_69.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-0.6, 4, -3.6)}, {Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-0.6, -4, -3.6)}};
    local tbl_70 = {};
    tbl_70.Rays = {{Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(0.6, -5, -1.6)}, {Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(0.6, 2.6, -1.6)}};
    tbl_55.AttachmentChecks = {
        {BenchNames = {"Floor", "Triangle Floor", "Floor Frame", "Triangle Floor Frame"}, Checks = {{Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, -4, -4.1)}, {Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, -4, -4.1)}}}, {Rays = {{Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(0, 5, -1.9)}, {Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(0, -2.6, -1.9)}}}, tbl_65}},
        {BenchNames = {"Wall", "Wall Frame", "Doorway", "Window", "Half Wall", "Low Wall", "Wall Block"}, Checks = {tbl_66, {Rays = {{Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(-0.6, 5, -1.6)}, {Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(-0.6, -2.6, -1.6)}}}, tbl_68, tbl_69, {Rays = {{Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(0.6, 5, -1.6)}, {Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(0.6, -2.6, -1.6)}}}, tbl_70}}
    };
end;
tbl_55.StabilityInfo = {Checks = {{Connections = {7, 8, 9}, StabilityLoss = {12, 5, 0}}, {Connections = {1, 2, 3}, StabilityLoss = {55, 16, 4}}}};
tbl_55.NextConnections = {1, 2, 3, 4, 5, 6, 7, 8, 9};
local tbl_71 = {};
tbl_71.SnapPoints = {{BenchNames = {"Foundation"}, Offset = CFrame.new(0, 5, 0)}, {BenchNames = {"Floor"}, Offset = CFrame.new(0, 5, 0)}};
tbl_71.AttachmentChecks = {{BenchNames = {"Foundation", "Floor"}, Checks = {{Rays = {{Offset = CFrame.new(0, -4.3, 0) * CFrame.Angles(-1.5707963267948966, 0, 0)}}}}}};
tbl_71.StabilityInfo = {Checks = {{Connections = {1}, StabilityLoss = {4}}}};
tbl_71.NextConnections = {};
local tbl_72 = {};
tbl_72.BenchNames = {"Small Planter Box"};
tbl_72.Offset = CFrame.new(2.95129395, -0.0810546875, 0.181518555, 0.000198172173, -0.999999166, -0.00133319281, 0.0485480651, 0.00134124164, -0.998820007, 0.998820901, 0.000133209614, 0.0485482886);
local tbl_73 = {};
tbl_73.BenchNames = {"Large Planter Box"};
tbl_73.Offset = CFrame.new(-3.04980469, -0.346435547, -2.7623291, 4.51527958e-05, -0.999999166, -0.00134708302, -0.065404892, 0.00134124537, -0.997857988, 0.997858882, 0.000133157082, -0.0654047728);
local tbl_74 = {};
tbl_74.BenchNames = {"Large Planter Box"};
tbl_74.Offset = CFrame.new(-0.0495605469, -0.140869141, -2.74920654, 4.51527958e-05, -0.999999166, -0.00134708302, -0.065404892, 0.00134124537, -0.997857988, 0.997858882, 0.000133157082, -0.0654047728);
local tbl_75 = {};
tbl_75.BenchNames = {"Large Planter Box"};
tbl_75.Offset = CFrame.new(2.95007324, -0.304443359, -2.7598877, 4.51901615e-05, -0.999999225, -0.00134708313, -0.0654048994, 0.00134124281, -0.997858107, 0.997858882, 0.000133202921, -0.0654047877);
local tbl_76 = {};
tbl_76.BenchNames = {"Large Planter Box"};
tbl_76.Offset = CFrame.new(-3.04907227, -0.1640625, 0.234375, 4.51527958e-05, -0.999999166, -0.00134708302, -0.065404892, 0.00134124537, -0.997857988, 0.997858882, 0.000133157082, -0.0654047728);
local tbl_77 = {};
tbl_77.BenchNames = {"Large Planter Box"};
tbl_77.Offset = CFrame.new(-0.0491943359, -0.138061523, 0.235839844, 4.51901615e-05, -0.999999225, -0.00134708313, -0.0654048994, 0.00134124281, -0.997858107, 0.997858882, 0.000133202921, -0.0654047877);
local tbl_78 = {};
tbl_78.BenchNames = {"Large Planter Box"};
tbl_78.Offset = CFrame.new(2.95056152, -0.252197266, 0.228271484, 4.51901615e-05, -0.999999225, -0.00134708313, -0.0654048994, 0.00134124281, -0.997858107, 0.997858882, 0.000133202921, -0.0654047877);
local tbl_79 = {};
tbl_79.BenchNames = {"Large Planter Box"};
tbl_79.Offset = CFrame.new(-3.04858398, -0.106323242, 2.89944458, 4.51527958e-05, -0.999999166, -0.00134708302, -0.065404892, 0.00134124537, -0.997857988, 0.997858882, 0.000133157082, -0.0654047728);
local tbl_80 = {};
tbl_80.BenchNames = {"Large Planter Box"};
tbl_80.Offset = CFrame.new(-0.0487060547, -0.0705566406, 2.90161133, 4.51527958e-05, -0.999999166, -0.00134708302, -0.065404892, 0.00134124537, -0.997857988, 0.997858882, 0.000133157082, -0.0654047728);
local tbl_81 = {};
tbl_81.BenchNames = {"Large Planter Box"};
tbl_81.Offset = CFrame.new(2.95080566, -0.274169922, 2.88803101, 4.51901615e-05, -0.999999225, -0.00134708313, -0.0654048994, 0.00134124281, -0.997858107, 0.997858882, 0.000133202921, -0.0654047877);
local v18, v20;
do
    local tbl_82 = {
        {BenchNames = {"Small Planter Box"}, Offset = CFrame.new(-3.04852295, -0.0426025391, 0.180847168, 0.000198172173, -0.999999166, -0.00133319281, 0.0485480651, 0.00134124164, -0.998820007, 0.998820901, 0.000133209614, 0.0485482886)},
        {BenchNames = {"Small Planter Box"}, Offset = CFrame.new(-0.0485839844, 0.00329589844, 0.178070068, 0.000198172173, -0.999999166, -0.00133319281, 0.0485480651, 0.00134124164, -0.998820007, 0.998820901, 0.000133209614, 0.0485482886)},
        tbl_72,
        tbl_73,
        tbl_74,
        tbl_75,
        tbl_76,
        tbl_77,
        tbl_78,
        tbl_79,
        tbl_80,
        tbl_81
    };
    v18 = {};
    do
        local tbl_83 = {};
        tbl_83.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1300
            ]]
            local tbl_84 = {};
            tbl_84.Slots = {"FuelWood", "InputCampfire", "Output", "Output"};
            tbl_84.LootTable = {"Benches", "Campfire"};
            return tbl_84;
        end;
        tbl_83.Offset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.4, 0);
        tbl_83.UnsnappedOffset = CFrame.new();
        tbl_83.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_83.PlaceableAngles = {};
        tbl_83.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
        tbl_83.PlacingFunc = v1;
        tbl_83.CollisionFunc = u4;
        v18.Campfire = tbl_83;
    end;
    local tbl_85 = {};
    tbl_85.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 1337
        ]]
        local tbl_86 = {};
        tbl_86.Slots = {"FuelWood", "InputCampfire", "InputCampfire", "Output", "Output", "Output"};
        tbl_86.LootTable = {"Benches", "Campfire"};
        return tbl_86;
    end;
    tbl_85.Offset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.4, 0);
    tbl_85.UnsnappedOffset = CFrame.new();
    tbl_85.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_85.PlaceableAngles = {};
    tbl_85.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
    tbl_85.PlacingFunc = v1;
    tbl_85.CollisionFunc = u4;
    tbl_85.Sounds = {};
    v18["Cooking Pot"] = tbl_85;
    local tbl_87 = {};
    tbl_87.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 1377
        ]]
        local tbl_88 = {};
        tbl_88.Slots = {"FuelWood", "InputFurnace", "InputFurnace", "Output", "Output", "Output"};
        return tbl_88;
    end;
    tbl_87.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 2.5, 0);
    tbl_87.UnsnappedOffset = CFrame.new();
    tbl_87.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_87.PlaceableAngles = {};
    tbl_87.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
    tbl_87.PlacingFunc = v1;
    tbl_87.CollisionFunc = u4;
    tbl_87.Sounds = {};
    v18.Furnace = tbl_87;
    do
        local tbl_89 = {};
        tbl_89.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1413
            ]]
            local tbl_90 = {};
            tbl_90.Slots = {"FuelWood", "FuelWood", "InputFurnace", "InputFurnace", "InputFurnace", "InputFurnace", "InputFurnace", "Output", "Output", "Output", "Output", "Output", "Output", "Output", "Output", "Output", "Output"};
            return tbl_90;
        end;
        tbl_89.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 8.8, 0);
        tbl_89.UnsnappedOffset = CFrame.new();
        tbl_89.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_89.PlaceableAngles = {};
        tbl_89.PlaceWhitelist = {"Terrain", "_Floor"};
        tbl_89.PlacingFunc = v1;
        tbl_89.CollisionFunc = u4;
        v18["Large Furnace"] = tbl_89;
    end;
    do
        local tbl_91 = {};
        tbl_91.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1448
            ]]
            local tbl_92 = {};
            tbl_92.Slots = {"FuelWood", "InputFurnace", "InputFurnace", "InputFurnace", "InputFurnace", "Output", "Output", "Output", "Output", "Output"};
            return tbl_92;
        end;
        tbl_91.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 3.2, 0);
        tbl_91.UnsnappedOffset = CFrame.new();
        tbl_91.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_91.PlaceableAngles = {};
        tbl_91.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
        tbl_91.PlacingFunc = v1;
        tbl_91.CollisionFunc = u4;
        v18["Blast Furnace"] = tbl_91;
    end;
    do
        local tbl_93 = {};
        tbl_93.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1483
            ]]
            local tbl_94 = {};
            tbl_94.Slots = {"FuelWood", "InputPetroleum", "Output", "Output", "Output"};
            return tbl_94;
        end;
        tbl_93.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 4.55, 0);
        tbl_93.UnsnappedOffset = CFrame.new();
        tbl_93.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_93.PlaceableAngles = {};
        tbl_93.PlaceWhitelist = {"Terrain", "_Floor"};
        tbl_93.PlacingFunc = v1;
        tbl_93.CollisionFunc = u4;
        v18["Petroleum Refinery"] = tbl_93;
    end;
    do
        local tbl_95 = {};
        tbl_95.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1519
            ]]
            local tbl_96 = {};
            tbl_96.Slots = {"InputLoom", "InputLoom", "Output", "Output", "Output"};
            return tbl_96;
        end;
        tbl_95.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 2.6, 0);
        tbl_95.UnsnappedOffset = CFrame.new();
        tbl_95.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_95.PlaceableAngles = {};
        tbl_95.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
        tbl_95.PlacingFunc = v1;
        tbl_95.CollisionFunc = u4;
        v18.Loom = tbl_95;
    end;
    do
        local tbl_97 = {};
        tbl_97.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1552
            ]]
            local tbl_98 = {};
            tbl_98.Slots = {"InputAnimal", "Output", "Output"};
            return tbl_98;
        end;
        tbl_97.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 2.7, 0);
        tbl_97.UnsnappedOffset = CFrame.new();
        tbl_97.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_97.PlaceableAngles = {};
        tbl_97.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
        tbl_97.PlacingFunc = v1;
        tbl_97.CollisionFunc = u4;
        v18["Cow Pasture"] = tbl_97;
    end;
    do
        local tbl_99 = {};
        tbl_99.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1586
            ]]
            local tbl_100 = {};
            tbl_100.Slots = {"InputAnimal", "Output", "Output"};
            return tbl_100;
        end;
        tbl_99.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 2, 0);
        tbl_99.UnsnappedOffset = CFrame.new();
        tbl_99.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_99.PlaceableAngles = {};
        tbl_99.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
        tbl_99.PlacingFunc = v1;
        tbl_99.CollisionFunc = u4;
        v18["Chicken House"] = tbl_99;
    end;
    local tbl_101 = {};
    tbl_101.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 1620
        ]]
        local tbl_102 = {};
        tbl_102.Slots = {"Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "Resources", "BuildingTools", "BuildingTools"};
        return tbl_102;
    end;
    tbl_101.ClientFunction = function(a1)
        --[[
          name: ClientFunction
          line: 1627
          upvalues:
            ActiveBenchModule_upv_1 (copy, index: 1)
        ]]
        local v21 = ActiveBenchModule_upv_1.GetClientInfo(a1);
        if (type(v21) ~= "table") then
            return;
        end;
        if (v21.Access) then
            return "OPEN", 3;
        end;
    end;
    tbl_101.FireDamageMults = {["Combustive Arrow"] = 7.5, ["Combustive Rocket"] = 2, Bullet = 2};
    tbl_101.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 3.2, 0);
    tbl_101.UnsnappedOffset = CFrame.new();
    tbl_101.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_101.PlaceableAngles = {};
    tbl_101.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
    tbl_101.PlacingFunc = v1;
    tbl_101.CollisionFunc = u4;
    tbl_101.Sounds = {};
    v18["Base Cabinet"] = tbl_101;
    local tbl_103 = {};
    tbl_103.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 1667
        ]]
        local tbl_104 = {};
        tbl_104.Slots = {};
        return tbl_104;
    end;
    tbl_103.ClientFunction = function(a1)
        --[[
          name: ClientFunction
          line: 1674
          upvalues:
            ActiveBenchModule_upv_1 (copy, index: 1)
        ]]
        local v22 = ActiveBenchModule_upv_1.GetClientInfo(a1);
        if (type(v22) ~= "table") then
            return;
        end;
        if (v22.Access) then
            return "OPEN", 3;
        end;
    end;
    tbl_103.FireDamageMults = {["Combustive Arrow"] = 7.5, ["Combustive Rocket"] = 2, Bullet = 2};
    tbl_103.Offset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 1.38, 0);
    tbl_103.UnsnappedOffset = CFrame.new();
    tbl_103.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_103.PlaceableAngles = {};
    tbl_103.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
    tbl_103.PlacingFunc = v1;
    tbl_103.CollisionFunc = u4;
    v18["Clan Table"] = tbl_103;
    do
        local tbl_105 = {};
        tbl_105.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1712
            ]]
            local tbl_106 = {};
            tbl_106.Slots = {};
            return tbl_106;
        end;
        tbl_105.Offset = CFrame.Angles(-1.5707963267948966, 1.5707963267948966, 0) * CFrame.new(0, 1.2, 0);
        tbl_105.UnsnappedOffset = CFrame.new();
        tbl_105.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_105.PlaceableAngles = {};
        tbl_105.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
        tbl_105.PlacingFunc = v1;
        tbl_105.CollisionFunc = u4;
        v18.Anvil = tbl_105;
    end;
    do
        local tbl_107 = {};
        tbl_107.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1741
            ]]
            local tbl_108 = {};
            tbl_108.Slots = {};
            return tbl_108;
        end;
        tbl_107.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 1.9, 0);
        tbl_107.UnsnappedOffset = CFrame.new();
        tbl_107.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_107.PlaceableAngles = {};
        tbl_107.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
        tbl_107.PlacingFunc = v1;
        tbl_107.CollisionFunc = u4;
        v18["Chemistry Lab"] = tbl_107;
    end;
    do
        local tbl_109 = {};
        tbl_109.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1770
            ]]
            local tbl_110 = {};
            tbl_110.Slots = {};
            return tbl_110;
        end;
        tbl_109.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 1.3, 0);
        tbl_109.UnsnappedOffset = CFrame.new();
        tbl_109.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_109.PlaceableAngles = {};
        tbl_109.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
        tbl_109.PlacingFunc = v1;
        tbl_109.CollisionFunc = u4;
        v18["Carpentry Table"] = tbl_109;
    end;
    do
        local tbl_111 = {};
        tbl_111.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1799
            ]]
            local tbl_112 = {};
            tbl_112.Slots = {};
            return tbl_112;
        end;
        tbl_111.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 1.3, 0);
        tbl_111.UnsnappedOffset = CFrame.new();
        tbl_111.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_111.PlaceableAngles = {};
        tbl_111.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
        tbl_111.PlacingFunc = v1;
        tbl_111.CollisionFunc = u4;
        v18["Sewing Table"] = tbl_111;
    end;
    do
        local tbl_113 = {};
        tbl_113.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1828
            ]]
            local tbl_114 = {};
            tbl_114.Slots = {};
            return tbl_114;
        end;
        tbl_113.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 0.9, 0);
        tbl_113.UnsnappedOffset = CFrame.new();
        tbl_113.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_113.PlaceableAngles = {};
        tbl_113.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
        tbl_113.PlacingFunc = v1;
        tbl_113.CollisionFunc = u4;
        v18["Ammo Press"] = tbl_113;
    end;
    do
        local tbl_115 = {};
        tbl_115.TypeArguments = function()
            --[[
              name: TypeArguments
              line: 1856
            ]]
            local tbl_116 = {};
            tbl_116.Slots = {};
            return tbl_116;
        end;
        tbl_115.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 1.25, 0);
        tbl_115.UnsnappedOffset = CFrame.new();
        tbl_115.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
        tbl_115.PlaceableAngles = {};
        tbl_115.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
        tbl_115.PlacingFunc = v1;
        tbl_115.CollisionFunc = u4;
        v18["Culinary Table"] = tbl_115;
    end;
    local tbl_117 = {};
    tbl_117.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 1885
        ]]
        return {};
    end;
    tbl_117.ClientFunction = function(a1)
        --[[
          name: ClientFunction
          line: 1890
          upvalues:
            ActiveBenchModule_upv_1 (copy, index: 1)
        ]]
        local v23 = ActiveBenchModule_upv_1.GetClientInfo(a1);
        if (type(v23) ~= "table") then
            return;
        end;
        if (v23.Owned) then
            return "RENAME BED", 2;
        end;
    end;
    tbl_117.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.26, 0);
    tbl_117.UnsnappedOffset = CFrame.new();
    tbl_117.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_117.PlaceableAngles = {};
    tbl_117.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
    tbl_117.PlacingFunc = v1;
    tbl_117.CollisionFunc = u4;
    v18["Sleeping Bag"] = tbl_117;
    local tbl_118 = {};
    tbl_118.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 1919
        ]]
        return {};
    end;
    tbl_118.ClientFunction = function(a1)
        --[[
          name: ClientFunction
          line: 1924
          upvalues:
            ActiveBenchModule_upv_1 (copy, index: 1)
        ]]
        local v24 = ActiveBenchModule_upv_1.GetClientInfo(a1);
        if (type(v24) ~= "table") then
            return;
        end;
        if (v24.Owned) then
            return "RENAME BED", 2;
        end;
    end;
    tbl_118.Offset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 1.8, 0);
    tbl_118.UnsnappedOffset = CFrame.new();
    tbl_118.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_118.PlaceableAngles = {};
    tbl_118.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
    tbl_118.PlacingFunc = v1;
    tbl_118.CollisionFunc = u4;
    v18.Bed = tbl_118;
    local tbl_119 = {};
    tbl_119.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 1956
        ]]
        return {};
    end;
    tbl_119.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.1, 0);
    tbl_119.UnsnappedOffset = CFrame.new();
    tbl_119.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_119.PlaceableAngles = {};
    tbl_119.PlaceWhitelist = {"Terrain"};
    tbl_119.TerrainMaterialWhitelist = {"Grass", "LeafyGrass"};
    tbl_119.PlacingFunc = v1;
    local function v19_1()
        --[[
          line: 233
        ]]
        return true;
    end;
    tbl_119.SnappedPlacingFunc = v19_1;
    tbl_119.CollisionFunc = u4;
    tbl_119.SnapPoints = tbl_82;
    v18["Wool Plant Seed"] = tbl_119;
    local tbl_120 = {};
    tbl_120.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 1983
        ]]
        return {};
    end;
    tbl_120.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.1, 0);
    tbl_120.UnsnappedOffset = CFrame.new();
    tbl_120.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_120.PlaceableAngles = {};
    tbl_120.PlaceWhitelist = {"Terrain"};
    tbl_120.TerrainMaterialWhitelist = {"Grass", "LeafyGrass"};
    tbl_120.PlacingFunc = v1;
    tbl_120.SnappedPlacingFunc = v19_1;
    tbl_120.CollisionFunc = u4;
    tbl_120.SnapPoints = tbl_82;
    v18["Tomato Plant Seed"] = tbl_120;
    local tbl_121 = {};
    tbl_121.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2010
        ]]
        return {};
    end;
    tbl_121.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.1, 0);
    tbl_121.UnsnappedOffset = CFrame.new();
    tbl_121.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_121.PlaceableAngles = {};
    tbl_121.PlaceWhitelist = {"Terrain"};
    tbl_121.TerrainMaterialWhitelist = {"Grass", "LeafyGrass"};
    tbl_121.PlacingFunc = v1;
    tbl_121.SnappedPlacingFunc = v19_1;
    tbl_121.CollisionFunc = u4;
    tbl_121.SnapPoints = tbl_82;
    v18["Corn Plant Seed"] = tbl_121;
    local tbl_122 = {};
    tbl_122.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2037
        ]]
        return {};
    end;
    tbl_122.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.1, 0);
    tbl_122.UnsnappedOffset = CFrame.new();
    tbl_122.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_122.PlaceableAngles = {};
    tbl_122.PlaceWhitelist = {"Terrain"};
    tbl_122.TerrainMaterialWhitelist = {"Grass", "LeafyGrass"};
    tbl_122.PlacingFunc = v1;
    tbl_122.SnappedPlacingFunc = v19_1;
    tbl_122.CollisionFunc = u4;
    tbl_122.SnapPoints = tbl_82;
    v18["Lemon Plant Seed"] = tbl_122;
    local tbl_123 = {};
    tbl_123.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2064
        ]]
        return {};
    end;
    tbl_123.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.1, 0);
    tbl_123.UnsnappedOffset = CFrame.new();
    tbl_123.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_123.PlaceableAngles = {};
    tbl_123.PlaceWhitelist = {"Terrain"};
    tbl_123.TerrainMaterialWhitelist = {"Grass", "LeafyGrass"};
    tbl_123.PlacingFunc = v1;
    tbl_123.SnappedPlacingFunc = v19_1;
    tbl_123.CollisionFunc = u4;
    tbl_123.SnapPoints = tbl_82;
    v18["Raspberry Plant Seed"] = tbl_123;
    local tbl_124 = {};
    tbl_124.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2091
        ]]
        return {};
    end;
    tbl_124.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.1, 0);
    tbl_124.UnsnappedOffset = CFrame.new();
    tbl_124.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_124.PlaceableAngles = {};
    tbl_124.PlaceWhitelist = {"Terrain"};
    tbl_124.TerrainMaterialWhitelist = {"Grass", "LeafyGrass"};
    tbl_124.PlacingFunc = v1;
    tbl_124.SnappedPlacingFunc = v19_1;
    tbl_124.CollisionFunc = u4;
    tbl_124.SnapPoints = tbl_82;
    v18["Blueberry Plant Seed"] = tbl_124;
    v20 = {};
    v20.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2118
        ]]
        return {};
    end;
    v20.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.1, 0);
    v20.UnsnappedOffset = CFrame.new();
    v20.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    v20.PlaceableAngles = {};
    v20.PlaceWhitelist = {"Terrain"};
    v20.TerrainMaterialWhitelist = {"Grass", "LeafyGrass"};
    v20.PlacingFunc = v1;
    v20.SnappedPlacingFunc = v19_1;
    v20.CollisionFunc = u4;
    v20.SnapPoints = tbl_82;
end;
v18["Pumpkin Plant Seed"] = v20;
do
    local tbl_125 = {};
    tbl_125.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2146
        ]]
        return {};
    end;
    tbl_125.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.76, 0);
    tbl_125.UnsnappedOffset = CFrame.new();
    tbl_125.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_125.PlaceableAngles = {};
    tbl_125.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
    tbl_125.PlacingFunc = v1;
    tbl_125.CollisionFunc = u4;
    v18["Small Planter Box"] = tbl_125;
end;
do
    local tbl_126 = {};
    tbl_126.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2172
        ]]
        return {};
    end;
    tbl_126.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.76, 0);
    tbl_126.UnsnappedOffset = CFrame.new();
    tbl_126.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_126.PlaceableAngles = {};
    tbl_126.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
    tbl_126.PlacingFunc = v1;
    tbl_126.CollisionFunc = u4;
    v18["Large Planter Box"] = tbl_126;
end;
local tbl_127 = {};
tbl_127.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 2199
    ]]
    local tbl_128 = {};
    tbl_128.Slots = table.create(12, "Default");
    return tbl_128;
end;
tbl_127.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.95, 0);
tbl_127.UnsnappedOffset = CFrame.new();
tbl_127.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_127.PlaceableAngles = {};
tbl_127.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_127.PlacingFunc = v1;
tbl_127.CollisionFunc = u4;
tbl_127.Sounds = {};
v18["Small Storage Box"] = tbl_127;
local tbl_129 = {};
tbl_129.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 2232
    ]]
    local tbl_130 = {};
    tbl_130.Slots = table.create(30, "Default");
    return tbl_130;
end;
tbl_129.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 1.3, 0);
tbl_129.UnsnappedOffset = CFrame.new();
tbl_129.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_129.PlaceableAngles = {};
tbl_129.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_129.PlacingFunc = v1;
tbl_129.CollisionFunc = u4;
tbl_129.Sounds = {};
v18["Large Storage Box"] = tbl_129;
local tbl_131 = {};
tbl_131.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 2267
    ]]
    local tbl_132 = {};
    tbl_132.Slots = table.create(13, "Output");
    return tbl_132;
end;
tbl_131.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 1.25, 0);
tbl_131.UnsnappedOffset = CFrame.new();
tbl_131.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_131.PlaceableAngles = {};
tbl_131.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
tbl_131.PlacingFunc = v1;
tbl_131.CollisionFunc = u4;
tbl_131.Sounds = {};
v18["Armor Stand"] = tbl_131;
local tbl_133 = {};
tbl_133.TypeArguments = function(a1)
    --[[
      name: TypeArguments
      line: 2304
    ]]
    local tbl_134 = {};
    tbl_134.Slots = table.create(30, "Default");
    return tbl_134;
end;
tbl_133.ClientFunction = function(a1)
    --[[
      name: ClientFunction
      line: 2317
      upvalues:
        ActiveBenchModule_upv_1 (copy, index: 1)
    ]]
    local v25 = ActiveBenchModule_upv_1.GetClientInfo(a1);
    if (type(v25) ~= "table") then
        return;
    end;
    if (not v25.CanEdit) then
        return "SHOP", 1;
    end;
end;
tbl_133.Offset = CFrame.Angles(0, math.pi, 0);
tbl_133.UnsnappedOffset = CFrame.new();
tbl_133.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_133.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_133.PlacingFunc = v19_1;
tbl_133.CollisionFunc = u4;
tbl_133.SnapPoints = {{BenchNames = {"Doorway"}, Offset = CFrame.new(0.04, -1.2, 0.4)}};
tbl_133.WallBlockOffset = CFrame.new(0, -2, 0);
tbl_133.Sounds = {};
v18["Shop Machine"] = tbl_133;
do
    local tbl_135 = {};
    tbl_135.TypeArguments = function(a1)
        --[[
          name: TypeArguments
          line: 2352
        ]]
        local tbl_136 = {};
        tbl_136.Slots = {"FuelCrude", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip"};
        tbl_136.LootTable = {"Benches", "Wooden Boat"};
        return tbl_136;
    end;
    tbl_135.Sounds = {};
    v18["Wooden Boat"] = tbl_135;
end;
do
    local tbl_137 = {};
    tbl_137.TypeArguments = function(a1)
        --[[
          name: TypeArguments
          line: 2376
        ]]
        local tbl_138 = {};
        tbl_138.Slots = {"FuelCrude", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip", "DefaultSkip"};
        tbl_138.LootTable = {"Benches", "Wooden Boat"};
        return tbl_138;
    end;
    tbl_137.Sounds = {};
    v18["Military Boat"] = tbl_137;
end;
do
    local tbl_139 = {};
    tbl_139.TypeArguments = function(a1)
        --[[
          name: TypeArguments
          line: 2400
        ]]
        local tbl_140 = {};
        tbl_140.Slots = {"FuelCrude"};
        tbl_140.LootTable = {"Benches", "Salvaged Flycopter"};
        return tbl_140;
    end;
    tbl_139.Explosive = {};
    tbl_139.Sounds = {};
    v18["Salvaged Flycopter"] = tbl_139;
end;
do
    local tbl_141 = {};
    tbl_141.TypeArguments = function(a1)
        --[[
          name: TypeArguments
          line: 2436
        ]]
        local tbl_142 = {};
        tbl_142.Dialog = {[1] = {Options = {[1] = {Action = {6, 150, "Wooden Boat"}}, [2] = {Action = {6, 350, "Military Boat"}}, [3] = {}}}, [2] = {Options = {[1] = {}}}, [3] = {Options = {[1] = {}}}};
        tbl_142.CooldownDialog = {[1] = {Options = {[1] = {}}}};
        return tbl_142;
    end;
    v18["Diver Dave"] = tbl_141;
end;
do
    local tbl_143 = {};
    tbl_143.TypeArguments = function(a1)
        --[[
          name: TypeArguments
          line: 2508
        ]]
        local tbl_144 = {};
        local tbl_145 = {};
        tbl_145.Options = {[1] = {}};
        local tbl_146 = {};
        tbl_146.Options = {[1] = {}};
        tbl_144.Dialog = {[1] = {Options = {[1] = {Action = {6, 750, "Salvaged Flycopter"}}, [2] = {}}}, [2] = tbl_145, [3] = tbl_146};
        tbl_144.CooldownDialog = {[1] = {Options = {[1] = {}}}};
        return tbl_144;
    end;
    v18["Pilot Pete"] = tbl_143;
end;
do
    local tbl_147 = {};
    tbl_147.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2574
        ]]
        local tbl_148 = {};
        tbl_148.Slots = {"Shotgun", "Shotgun"};
        tbl_148.DamageRange = {9, 25};
        return tbl_148;
    end;
    tbl_147.Offset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 1.21, 0);
    tbl_147.UnsnappedOffset = CFrame.new();
    tbl_147.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_147.PlaceableAngles = {};
    tbl_147.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Wall", "Half Wall", "Doorway", "Window"};
    tbl_147.PlacingFunc = v1;
    tbl_147.CollisionFunc = u4;
    v18["Shotgun Turret"] = tbl_147;
end;
do
    local tbl_149 = {};
    tbl_149.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2617
        ]]
        local tbl_150 = {};
        tbl_150.Slots = {"InputGun", "Ammo", "Ammo", "Ammo", "Ammo", "Ammo"};
        tbl_150.DamageRange = {85, 150};
        return tbl_150;
    end;
    tbl_149.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.925, 0);
    tbl_149.UnsnappedOffset = CFrame.new();
    tbl_149.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_149.PlaceableAngles = {};
    tbl_149.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
    tbl_149.PlacingFunc = v1;
    tbl_149.CollisionFunc = u4;
    v18["Auto Turret"] = tbl_149;
end;
do
    local tbl_151 = {};
    tbl_151.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2669
        ]]
        return {};
    end;
    tbl_151.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.15, 0);
    tbl_151.UnsnappedOffset = CFrame.new();
    tbl_151.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_151.PlaceableAngles = {};
    tbl_151.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Terrain", "_Floor"};
    tbl_151.PlacingFunc = v1;
    tbl_151.CollisionFunc = u4;
    v18["Bear Trap"] = tbl_151;
end;
do
    local tbl_152 = {};
    tbl_152.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2699
        ]]
        local tbl_153 = {};
        tbl_153.Explosive = {};
        return tbl_153;
    end;
    tbl_152.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.24, 0);
    tbl_152.UnsnappedOffset = CFrame.new();
    tbl_152.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_152.PlaceableAngles = {};
    tbl_152.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Terrain", "_Floor"};
    tbl_152.PlacingFunc = v1;
    tbl_152.CollisionFunc = u4;
    v18["Landmine Trap"] = tbl_152;
end;
do
    local tbl_154 = {};
    tbl_154.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2737
        ]]
        return {};
    end;
    tbl_154.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 0.015, 0);
    tbl_154.UnsnappedOffset = CFrame.new();
    tbl_154.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_154.PlaceableAngles = {};
    tbl_154.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Wall", "Half Wall", "Doorway", "Window"};
    tbl_154.PlacingFunc = v1;
    tbl_154.CollisionFunc = u4;
    v18.Rug = tbl_154;
end;
do
    local tbl_155 = {};
    tbl_155.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2768
        ]]
        return {};
    end;
    tbl_155.Offset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.015, 0);
    tbl_155.UnsnappedOffset = CFrame.new();
    tbl_155.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_155.PlaceableAngles = {};
    tbl_155.PlaceWhitelist = {"Wall", "Half Wall", "Doorway", "Window"};
    tbl_155.PlacingFunc = v1;
    tbl_155.CollisionFunc = u4;
    v18.Wreath = tbl_155;
end;
do
    local tbl_156 = {};
    tbl_156.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2798
        ]]
    end;
    tbl_156.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.18, 0);
    tbl_156.UnsnappedOffset = CFrame.new();
    tbl_156.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_156.PlaceableAngles = {};
    tbl_156.PlaceWhitelist = {"Wall", "Half Wall", "Doorway", "Window"};
    tbl_156.PlacingFunc = v1;
    tbl_156.CollisionFunc = u4;
    v18["Christmas Lights"] = tbl_156;
end;
local tbl_157 = {};
tbl_157.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 2826
    ]]
    local tbl_158 = {};
    tbl_158.Slots = {"FuelWood", "InputCampfire", "InputCampfire", "Output", "Output", "Output"};
    tbl_158.LootTable = {"Benches", "Campfire"};
    return tbl_158;
end;
tbl_157.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 4.48, 0);
tbl_157.UnsnappedOffset = CFrame.new();
tbl_157.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_157.PlaceableAngles = {};
tbl_157.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_157.PlacingFunc = v1;
tbl_157.CollisionFunc = u4;
tbl_157.Sounds = {};
v18.Fireplace = tbl_157;
do
    local tbl_159 = {};
    tbl_159.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2869
        ]]
        return {};
    end;
    tbl_159.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 0.9, 0) * CFrame.Angles(math.pi, 0, 0);
    tbl_159.UnsnappedOffset = CFrame.new();
    tbl_159.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_159.PlaceableAngles = {};
    tbl_159.PlaceWhitelist = {"Floor", "Triangle Floor"};
    tbl_159.PlacingFunc = v1;
    tbl_159.CollisionFunc = u4;
    v18["Barrel Light"] = tbl_159;
end;
do
    local tbl_160 = {};
    tbl_160.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2905
        ]]
        return {};
    end;
    tbl_160.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.49, 0);
    tbl_160.UnsnappedOffset = CFrame.new();
    tbl_160.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_160.PlaceableAngles = {};
    tbl_160.PlaceBlacklist = {"Terrain", "Ladder", "Candle", "Metal Barricade", "Wooden Spikes", "Metal Spikes", "Wooden Boat", "Military Boat", "Salvaged Flycopter"};
    tbl_160.PlacingFunc = v1;
    tbl_160.CollisionFunc = u4;
    v18.Candle = tbl_160;
end;
do
    local tbl_161 = {};
    tbl_161.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2930
        ]]
        return {};
    end;
    tbl_161.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 0.88, 0);
    tbl_161.UnsnappedOffset = CFrame.new();
    tbl_161.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_161.PlaceableAngles = {};
    tbl_161.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
    tbl_161.PlacingFunc = v1;
    tbl_161.CollisionFunc = u4;
    v18["Jack-O-Lantern"] = tbl_161;
end;
do
    local tbl_162 = {};
    tbl_162.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2957
        ]]
        return {};
    end;
    tbl_162.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 0.015, 0);
    tbl_162.UnsnappedOffset = CFrame.new();
    tbl_162.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_162.PlaceableAngles = {};
    tbl_162.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Wall", "Half Wall", "Doorway", "Window"};
    tbl_162.PlacingFunc = v1;
    tbl_162.CollisionFunc = u4;
    v18["Small Cobweb"] = tbl_162;
end;
do
    local tbl_163 = {};
    tbl_163.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 2983
        ]]
        return {};
    end;
    tbl_163.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 0.015, 0);
    tbl_163.UnsnappedOffset = CFrame.new();
    tbl_163.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_163.PlaceableAngles = {};
    tbl_163.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Wall", "Half Wall", "Doorway", "Window"};
    tbl_163.PlacingFunc = v1;
    tbl_163.CollisionFunc = u4;
    v18["Large Cobweb"] = tbl_163;
end;
do
    local tbl_164 = {};
    tbl_164.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3009
        ]]
        return {};
    end;
    tbl_164.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 2, 0);
    tbl_164.UnsnappedOffset = CFrame.new();
    tbl_164.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_164.PlaceableAngles = {};
    tbl_164.PlaceWhitelist = {"Terrain", "_Floor"};
    tbl_164.PlacingFunc = v1;
    tbl_164.CollisionFunc = u4;
    v18.Scarecrow = tbl_164;
end;
do
    local tbl_165 = {};
    tbl_165.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3034
        ]]
        return {};
    end;
    tbl_165.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 2.16, 0);
    tbl_165.UnsnappedOffset = CFrame.new();
    tbl_165.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_165.PlaceableAngles = {};
    tbl_165.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
    tbl_165.PlacingFunc = v1;
    tbl_165.CollisionFunc = u4;
    v18["%s's Trophy"] = tbl_165;
end;
local tbl_166 = {};
tbl_166.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3060
    ]]
    local tbl_167 = {};
    tbl_167.Slots = table.create(48, "Default");
    return tbl_167;
end;
tbl_166.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 4, 0);
tbl_166.UnsnappedOffset = CFrame.new();
tbl_166.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_166.PlaceableAngles = {};
tbl_166.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_166.PlacingFunc = v1;
tbl_166.CollisionFunc = u4;
tbl_166.Sounds = {};
v18["Storage Cabinet"] = tbl_166;
do
    local tbl_168 = {};
    tbl_168.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3096
        ]]
        local tbl_169 = {};
        tbl_169.Slots = {"Ornament", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default"};
        return tbl_169;
    end;
    tbl_168.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 4.6, 0);
    tbl_168.UnsnappedOffset = CFrame.new();
    tbl_168.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_168.PlaceableAngles = {};
    tbl_168.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
    tbl_168.PlacingFunc = v1;
    tbl_168.CollisionFunc = u4;
    v18["Christmas Tree"] = tbl_168;
end;
local tbl_170 = {};
tbl_170.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3129
    ]]
    local tbl_171 = {};
    tbl_171.Slots = {"InputRepair"};
    return tbl_171;
end;
tbl_170.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 2.35, 0);
tbl_170.UnsnappedOffset = CFrame.new();
tbl_170.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_170.PlaceableAngles = {};
tbl_170.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_170.PlacingFunc = v1;
tbl_170.CollisionFunc = u4;
v18["Repair Table"] = tbl_170;
local tbl_172 = {};
tbl_172.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3163
    ]]
    return {};
end;
tbl_172.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 7.5, 0);
tbl_172.UnsnappedOffset = CFrame.new();
tbl_172.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_172.PlaceableAngles = {};
tbl_172.PlaceWhitelist = {"Terrain", "_Floor"};
tbl_172.PlacingFunc = v1;
tbl_172.CollisionFunc = u4;
v18["External Wooden Wall"] = tbl_172;
local tbl_173 = {};
tbl_173.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3198
    ]]
    local tbl_174 = {};
    tbl_174.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 3201
        ]]
        return ((a1 < 0.5) and (4 * a1 ^ 3)) or (1 - (((-2 * a1) + 2) ^ 3) / 2);
    end;
    return tbl_174;
end;
tbl_173.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 7.5, 0);
tbl_173.UnsnappedOffset = CFrame.new();
tbl_173.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_173.PlaceableAngles = {};
tbl_173.PlaceWhitelist = {"Terrain", "_Floor"};
tbl_173.PlacingFunc = v1;
tbl_173.CollisionFunc = u4;
v18["External Wooden Gate"] = tbl_173;
local tbl_175 = {};
tbl_175.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3242
    ]]
    return {};
end;
tbl_175.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 7.5, 0);
tbl_175.UnsnappedOffset = CFrame.new();
tbl_175.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_175.PlaceableAngles = {};
tbl_175.PlaceWhitelist = {"Terrain", "_Floor"};
tbl_175.PlacingFunc = v1;
tbl_175.CollisionFunc = u4;
v18["External Stone Wall"] = tbl_175;
local tbl_176 = {};
tbl_176.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3277
    ]]
    local tbl_177 = {};
    tbl_177.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 3280
        ]]
        return ((a1 < 0.5) and (4 * a1 ^ 3)) or (1 - (((-2 * a1) + 2) ^ 3) / 2);
    end;
    return tbl_177;
end;
tbl_176.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 11, 0);
tbl_176.UnsnappedOffset = CFrame.new();
tbl_176.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_176.PlaceableAngles = {};
tbl_176.PlaceWhitelist = {"Terrain", "_Floor"};
tbl_176.PlacingFunc = v1;
tbl_176.CollisionFunc = u4;
v18["External Stone Gate"] = tbl_176;
v18.Ladder = {Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0.15, 0, 0), UnsnappedOffset = CFrame.Angles(0, 0, 1.5707963267948966), RotateOffset = CFrame.new(), PlaceableAngles = {}, PlaceBlacklist = {"Terrain", "Ladder", "Candle", "Metal Barricade", "Wooden Spikes", "Metal Spikes", "Wooden Boat", "Military Boat", "Salvaged Flycopter"}, PlacingFunc = v1, CollisionFunc = u4};
local tbl_178 = {};
tbl_178.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3347
    ]]
    return {};
end;
tbl_178.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 2.9, 0);
tbl_178.UnsnappedOffset = CFrame.new();
tbl_178.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_178.PlaceableAngles = {};
tbl_178.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
tbl_178.PlacingFunc = v1;
tbl_178.CollisionFunc = u4;
v18["Wooden Spikes"] = tbl_178;
local tbl_179 = {};
tbl_179.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3378
    ]]
    return {};
end;
tbl_179.Offset = CFrame.Angles(-1.5707963267948966, -1.5707963267948966, 0) * CFrame.new(0, 2.9, 0);
tbl_179.UnsnappedOffset = CFrame.new();
tbl_179.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_179.PlaceableAngles = {};
tbl_179.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
tbl_179.PlacingFunc = v1;
tbl_179.CollisionFunc = u4;
v18["Metal Spikes"] = tbl_179;
v18["Metal Barricade"] = {Offset = CFrame.Angles(-1.5707963267948966, 1.5707963267948966, 0) * CFrame.new(0, 3.4, 0), UnsnappedOffset = CFrame.new(), RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0), PlaceableAngles = {}, PlaceBlacklist = {"Ladder", "Candle", "Metal Barricade", "Wooden Spikes", "Metal Spikes", "Wooden Boat", "Military Boat", "Salvaged Flycopter"}, PlacingFunc = v1, CollisionFunc = u4};
local tbl_180 = {};
tbl_180.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3438
    ]]
    return {};
end;
tbl_180.Offset = CFrame.Angles(math.pi, 1.5707963267948966, 0) * CFrame.new(0, 0, 0);
tbl_180.UnsnappedOffset = CFrame.Angles(0, 0, 1.5707963267948966);
tbl_180.RotateOffset = CFrame.new();
tbl_180.PlaceableAngles = {};
tbl_180.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Wall", "Half Wall", "Low Wall", "Doorway", "Window", "Foundation"};
tbl_180.PlacingFunc = v1;
tbl_180.CollisionFunc = u4;
v18["Small Wooden Sign"] = tbl_180;
local tbl_181 = {};
tbl_181.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3470
    ]]
    return {};
end;
tbl_181.Offset = CFrame.Angles(math.pi, 1.5707963267948966, 0) * CFrame.new(-0.1, 0, 0);
tbl_181.UnsnappedOffset = CFrame.Angles(0, 0, 1.5707963267948966);
tbl_181.RotateOffset = CFrame.new();
tbl_181.PlaceableAngles = {};
tbl_181.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Wall", "Half Wall", "Low Wall", "Doorway", "Window", "Foundation"};
tbl_181.PlacingFunc = v1;
tbl_181.CollisionFunc = u4;
v18["Large Wooden Sign"] = tbl_181;
do
    local tbl_182 = {};
    tbl_182.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3502
        ]]
        local tbl_183 = {};
        tbl_183.Slots = table.create(12, "Default");
        return tbl_183;
    end;
    tbl_182.Sounds = {};
    v18["Salvaged Backpack"] = tbl_182;
end;
do
    local tbl_184 = {};
    tbl_184.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3522
        ]]
        local tbl_185 = {};
        tbl_185.Slots = table.create(24, "Default");
        return tbl_185;
    end;
    tbl_184.Sounds = {};
    v18["Military Backpack"] = tbl_184;
end;
do
    local tbl_186 = {};
    tbl_186.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3542
        ]]
        local tbl_187 = {};
        tbl_187.Slots = table.create(12, "Output");
        tbl_187.LootTable = {"Benches", "Food Crate"};
        return tbl_187;
    end;
    v18["Food Crate"] = tbl_186;
end;
do
    local tbl_188 = {};
    tbl_188.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3559
        ]]
        local tbl_189 = {};
        tbl_189.Slots = table.create(30, "Output");
        tbl_189.LootTable = {"Benches", "Wooden Crate"};
        return tbl_189;
    end;
    v18["Wooden Crate"] = tbl_188;
end;
do
    local tbl_190 = {};
    tbl_190.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3576
        ]]
        local tbl_191 = {};
        tbl_191.Slots = table.create(30, "Output");
        tbl_191.LootTable = {"Benches", "Locked Wooden Crate"};
        return tbl_191;
    end;
    v18["Locked Wooden Crate"] = tbl_190;
end;
do
    local tbl_192 = {};
    tbl_192.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3595
        ]]
        local tbl_193 = {};
        tbl_193.Slots = table.create(30, "Output");
        tbl_193.LootTable = {"Benches", "Locked Metal Crate"};
        return tbl_193;
    end;
    v18["Locked Metal Crate"] = tbl_192;
end;
do
    local tbl_194 = {};
    tbl_194.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3614
        ]]
        local tbl_195 = {};
        tbl_195.Slots = table.create(30, "Output");
        tbl_195.LootTable = {"Benches", "Locked Steel Crate"};
        return tbl_195;
    end;
    v18["Locked Steel Crate"] = tbl_194;
end;
do
    local tbl_196 = {};
    tbl_196.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3633
        ]]
        local tbl_197 = {};
        tbl_197.Slots = table.create(30, "Output");
        tbl_197.LootTable = {"Benches", "Boris's Locker"};
        return tbl_197;
    end;
    v18["Boris's Locker"] = tbl_196;
end;
do
    local tbl_198 = {};
    tbl_198.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3651
        ]]
        local tbl_199 = {};
        tbl_199.Slots = table.create(30, "Output");
        tbl_199.LootTable = {"Benches", "Brutus Locker"};
        return tbl_199;
    end;
    v18["Brutus Locker"] = tbl_198;
end;
do
    local tbl_200 = {};
    tbl_200.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3669
        ]]
        local tbl_201 = {};
        tbl_201.Slots = table.create(30, "Output");
        tbl_201.LootTable = {"Benches", "Care Package"};
        return tbl_201;
    end;
    v18["Care Package"] = tbl_200;
end;
do
    local tbl_202 = {};
    tbl_202.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3689
        ]]
        local tbl_203 = {};
        tbl_203.Slots = table.create(30, "Output");
        tbl_203.LootTable = {"Benches", "Timed Crate"};
        return tbl_203;
    end;
    v18["Timed Crate"] = tbl_202;
end;
do
    local tbl_204 = {};
    tbl_204.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3709
        ]]
        local tbl_205 = {};
        tbl_205.Slots = table.create(30, "Output");
        tbl_205.LootTable = {"Benches", "BTR Crate"};
        return tbl_205;
    end;
    v18["BTR Crate"] = tbl_204;
end;
do
    local tbl_206 = {};
    tbl_206.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3729
        ]]
        local tbl_207 = {};
        tbl_207.LootTable = {"Benches", "Oil Barrel"};
        return tbl_207;
    end;
    v18["Oil Barrel"] = tbl_206;
end;
do
    local tbl_208 = {};
    tbl_208.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3743
        ]]
        local tbl_209 = {};
        tbl_209.LootTable = {"Benches", "Trash Can"};
        tbl_209.Health = 15 + (math.random(0, 1) * 5);
        return tbl_209;
    end;
    v18["Trash Can"] = tbl_208;
end;
do
    local tbl_210 = {};
    tbl_210.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3758
        ]]
        local tbl_211 = {};
        tbl_211.LootTable = {"Benches", "Small Gift"};
        tbl_211.Health = 15 + (math.random(0, 1) * 5);
        return tbl_211;
    end;
    v18["Small Gift"] = tbl_210;
end;
do
    local tbl_212 = {};
    tbl_212.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3773
        ]]
        local tbl_213 = {};
        tbl_213.LootTable = {"Benches", "Medium Gift"};
        tbl_213.Health = 20 + (math.random(0, 1) * 5);
        return tbl_213;
    end;
    v18["Medium Gift"] = tbl_212;
end;
do
    local tbl_214 = {};
    tbl_214.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3788
        ]]
        local tbl_215 = {};
        tbl_215.LootTable = {"Benches", "Large Gift"};
        tbl_215.Health = 25 + (math.random(0, 1) * 5);
        return tbl_215;
    end;
    v18["Large Gift"] = tbl_214;
end;
do
    local tbl_216 = {};
    tbl_216.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3803
        ]]
        local tbl_217 = {};
        tbl_217.LootTable = {"Benches", "Small Gift"};
        tbl_217.Health = 15 + (math.random(0, 1) * 5);
        return tbl_217;
    end;
    v18["Small Egg"] = tbl_216;
end;
do
    local tbl_218 = {};
    tbl_218.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3818
        ]]
        local tbl_219 = {};
        tbl_219.LootTable = {"Benches", "Medium Gift"};
        tbl_219.Health = 20 + (math.random(0, 1) * 5);
        return tbl_219;
    end;
    v18["Medium Egg"] = tbl_218;
end;
do
    local tbl_220 = {};
    tbl_220.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3833
        ]]
        local tbl_221 = {};
        tbl_221.LootTable = {"Benches", "Large Gift"};
        tbl_221.Health = 25 + (math.random(0, 1) * 5);
        return tbl_221;
    end;
    v18["Large Egg"] = tbl_220;
end;
do
    local tbl_222 = {};
    tbl_222.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3848
        ]]
        local tbl_223 = {};
        tbl_223.Slots = {"FuelWood", "InputCampfire", "Output", "Output"};
        tbl_223.LootTable = {"Benches", "Campfire"};
        return tbl_223;
    end;
    v18["Fire Barrel"] = tbl_222;
end;
do
    local tbl_224 = {};
    tbl_224.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3869
        ]]
        local tbl_225 = {};
        tbl_225.Slots = {"InputShredder", "InputShredder", "InputShredder", "InputShredder", "InputShredder", "Output", "Output", "Output", "Output", "Output"};
        return tbl_225;
    end;
    v18.Shredder = tbl_224;
end;
local tbl_226 = {};
tbl_226.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 3886
    ]]
    return {};
end;
tbl_226.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 2.55, 0);
tbl_226.UnsnappedOffset = CFrame.new();
tbl_226.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_226.PlaceableAngles = {};
tbl_226.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor"};
tbl_226.PlacingFunc = v1;
tbl_226.CollisionFunc = u4;
v18.Jukebox = tbl_226;
do
    local tbl_227 = {};
    tbl_227.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3917
        ]]
        local tbl_228 = {};
        tbl_228.Slots = {"InputCaps", "InputCaps", "InputCaps", "InputCaps", "Output"};
        return tbl_228;
    end;
    v18["Plinko Machine"] = tbl_227;
end;
do
    local tbl_229 = {};
    tbl_229.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3934
        ]]
        local tbl_230 = {};
        tbl_230.Slots = {"InputPowerCell"};
        return tbl_230;
    end;
    v18["Power Cell Box"] = tbl_229;
end;
do
    local tbl_231 = {};
    tbl_231.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3951
        ]]
        return {};
    end;
    v18["Power Button"] = tbl_231;
end;
do
    local tbl_232 = {};
    tbl_232.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3963
        ]]
        return {};
    end;
    v18["Door Button"] = tbl_232;
end;
do
    local tbl_233 = {};
    tbl_233.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3975
        ]]
        local tbl_234 = {};
        tbl_234.Slots = table.create(38, "Output");
        return tbl_234;
    end;
    tbl_233.Sounds = {};
    v18["Body Bag"] = tbl_233;
end;
do
    local tbl_235 = {};
    tbl_235.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 3995
        ]]
        local tbl_236 = {};
        tbl_236.Slots = {"Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Default", "Output", "Output", "Output", "Output", "Output", "Output", "Output", "Output"};
        return tbl_236;
    end;
    tbl_235.Sounds = {};
    v18.Sleeper = tbl_235;
end;
do
    local tbl_237 = {};
    tbl_237.TypeArguments = function(a1)
        --[[
          name: TypeArguments
          line: 4012
        ]]
        local v26 = nil;
        if (a1) then
            local v27 = nil;
            v26 = a1:GetAttribute("BenchName");
            local v28 = false;
            if (v26) then
                if (v26:find("Scav Body") or v26 == "Body of Bruno" or v26 == "Body of Boris") then
                    local tbl_238 = {"AI", v26};
                    v27, v28 = tbl_238, true;
                else
                    local v29 = nil;
                    if (v26 == "Body of Brutus") then
                        local tbl_238 = {"AI", v26};
                        v27, v28 = tbl_238, true;
                    else
                        v29 = v26:find("Zombie");
                        if (v29) then
                            local tbl_238 = {"AI", v26};
                            v27, v28 = tbl_238, true;
                        end;
                    end;
                end;
            end;
            local tbl_239 = {};
            tbl_239.Slots = table.create(48, "Output");
            tbl_239.LootTable = v27;
            tbl_239.ResizeDynamically = v28;
            return tbl_239;
        end;
        return {};
    end;
    tbl_237.Sounds = {};
    v18.Contents = tbl_237;
end;
do
    local tbl_240 = {};
    tbl_240.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 4041
        ]]
        local tbl_241 = {};
        tbl_241.MoveFunction = function(a1)
            --[[
              name: MoveFunction
              line: 4044
            ]]
            return 1 - ((1 - a1) ^ 3);
        end;
        return tbl_241;
    end;
    v18.Door = tbl_240;
end;
do
    local tbl_242 = {};
    tbl_242.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 4060
        ]]
        local tbl_243 = {};
        tbl_243.MoveFunction = function(a1)
            --[[
              name: MoveFunction
              line: 4063
            ]]
            return 1 - ((1 - a1) ^ 3);
        end;
        return tbl_243;
    end;
    v18["Yellow Keycard Door"] = tbl_242;
end;
do
    local tbl_244 = {};
    tbl_244.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 4079
        ]]
        local tbl_245 = {};
        tbl_245.MoveFunction = function(a1)
            --[[
              name: MoveFunction
              line: 4082
            ]]
            return 1 - ((1 - a1) ^ 3);
        end;
        return tbl_245;
    end;
    v18["Purple Keycard Door"] = tbl_244;
end;
do
    local tbl_246 = {};
    tbl_246.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 4098
        ]]
        local tbl_247 = {};
        tbl_247.MoveFunction = function(a1)
            --[[
              name: MoveFunction
              line: 4101
            ]]
            return 1 - ((1 - a1) ^ 3);
        end;
        return tbl_247;
    end;
    v18["Pink Keycard Door"] = tbl_246;
end;
do
    local tbl_248 = {};
    tbl_248.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 4117
        ]]
        local tbl_249 = {};
        tbl_249.MoveFunction = function(a1)
            --[[
              name: MoveFunction
              line: 4120
            ]]
            return 1 - ((1 - a1) ^ 3);
        end;
        return tbl_249;
    end;
    v18["Red Keycard Door"] = tbl_248;
end;
do
    local tbl_250 = {};
    tbl_250.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 4136
        ]]
        local tbl_251 = {};
        tbl_251.MoveFunction = function(a1)
            --[[
              name: MoveFunction
              line: 4139
            ]]
            return 1 - ((1 - a1) ^ 3);
        end;
        return tbl_251;
    end;
    v18["Black Keycard Door"] = tbl_250;
end;
local tbl_252 = {};
tbl_252.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4155
    ]]
    local tbl_253 = {};
    tbl_253.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 4158
        ]]
        return 1 - ((1 - a1) ^ 3);
    end;
    return tbl_253;
end;
tbl_252.Offset = CFrame.new();
tbl_252.UnsnappedOffset = CFrame.new();
tbl_252.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_252.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_252.PlacingFunc = v19_1;
tbl_252.CollisionFunc = u4;
tbl_252.SnapPoints = {{BenchNames = {"Doorway"}, Offset = CFrame.new(0, -1.75, 0)}};
tbl_252.WallBlockOffset = CFrame.new(0, -2, 0);
v18["Wooden Door"] = tbl_252;
local tbl_254 = {};
tbl_254.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4191
    ]]
    local tbl_255 = {};
    tbl_255.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 4194
        ]]
        return 1 - ((1 - a1) ^ 3);
    end;
    return tbl_255;
end;
tbl_254.Offset = CFrame.new();
tbl_254.UnsnappedOffset = CFrame.new();
tbl_254.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_254.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_254.PlacingFunc = v19_1;
tbl_254.CollisionFunc = u4;
tbl_254.SnapPoints = {{BenchNames = {"Doorway"}, Offset = CFrame.new(0, -1.75, 0)}};
tbl_254.WallBlockOffset = CFrame.new(0, -2, 0);
v18["Salvaged Metal Door"] = tbl_254;
local tbl_256 = {};
tbl_256.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4228
    ]]
    local tbl_257 = {};
    tbl_257.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 4231
        ]]
        return 1 - ((1 - a1) ^ 3);
    end;
    return tbl_257;
end;
tbl_256.Offset = CFrame.new();
tbl_256.UnsnappedOffset = CFrame.new();
tbl_256.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_256.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_256.PlacingFunc = v19_1;
tbl_256.CollisionFunc = u4;
tbl_256.SnapPoints = {{BenchNames = {"Doorway"}, Offset = CFrame.new(0, -1.75, 0)}};
tbl_256.WallBlockOffset = CFrame.new(0, -2, 0);
v18["Metal Door"] = tbl_256;
local tbl_258 = {};
tbl_258.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4265
    ]]
    local tbl_259 = {};
    tbl_259.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 4268
        ]]
        return 1 - ((1 - a1) ^ 3);
    end;
    return tbl_259;
end;
tbl_258.Offset = CFrame.new();
tbl_258.UnsnappedOffset = CFrame.new();
tbl_258.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_258.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_258.PlacingFunc = v19_1;
tbl_258.CollisionFunc = u4;
tbl_258.SnapPoints = {{BenchNames = {"Doorway"}, Offset = CFrame.new(0, -1.75, 0)}};
tbl_258.WallBlockOffset = CFrame.new(0, -2, 0);
v18["Steel Door"] = tbl_258;
local tbl_260 = {};
tbl_260.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4302
    ]]
    local tbl_261 = {};
    tbl_261.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 4305
        ]]
        return 1 - ((1 - a1) ^ 3);
    end;
    return tbl_261;
end;
tbl_260.Offset = CFrame.new();
tbl_260.UnsnappedOffset = CFrame.new();
tbl_260.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_260.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_260.PlacingFunc = v19_1;
tbl_260.CollisionFunc = u4;
tbl_260.SnapPoints = {{BenchNames = {"Wall Frame"}, Offset = CFrame.new(0, 0, 0)}};
tbl_260.WallBlockOffset = CFrame.new(0, -3.75, 0);
v18["Wooden Double Door"] = tbl_260;
local tbl_262 = {};
tbl_262.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4339
    ]]
    local tbl_263 = {};
    tbl_263.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 4342
        ]]
        return 1 - ((1 - a1) ^ 3);
    end;
    return tbl_263;
end;
tbl_262.Offset = CFrame.new();
tbl_262.UnsnappedOffset = CFrame.new();
tbl_262.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_262.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_262.PlacingFunc = v19_1;
tbl_262.CollisionFunc = u4;
tbl_262.SnapPoints = {{BenchNames = {"Wall Frame"}, Offset = CFrame.new(0, 0, 0)}};
tbl_262.WallBlockOffset = CFrame.new(0, -3.75, 0);
v18["Metal Double Door"] = tbl_262;
local tbl_264 = {};
tbl_264.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4376
    ]]
    local tbl_265 = {};
    tbl_265.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 4379
        ]]
        return 1 - ((1 - a1) ^ 3);
    end;
    return tbl_265;
end;
tbl_264.Offset = CFrame.new();
tbl_264.UnsnappedOffset = CFrame.new();
tbl_264.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_264.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_264.PlacingFunc = v19_1;
tbl_264.CollisionFunc = u4;
tbl_264.SnapPoints = {{BenchNames = {"Wall Frame"}, Offset = CFrame.new(0, 0, 0)}};
tbl_264.WallBlockOffset = CFrame.new(0, -3.75, 0);
v18["Steel Double Door"] = tbl_264;
do
    local tbl_266 = {};
    tbl_266.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 4413
        ]]
        local tbl_267 = {};
        tbl_267.MoveFunction = function(a1)
            --[[
              name: MoveFunction
              line: 4416
            ]]
            return 1 - ((1 - a1) ^ 3);
        end;
        return tbl_267;
    end;
    tbl_266.Offset = CFrame.new();
    tbl_266.UnsnappedOffset = CFrame.new();
    tbl_266.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
    tbl_266.PlacingFunc = v19_1;
    tbl_266.CollisionFunc = u4;
    tbl_266.SnapPoints = {{BenchNames = {"Floor Frame"}, Offset = CFrame.new(0, 0, 0)}};
    v18["Trap Door"] = tbl_266;
end;
do
    local tbl_268 = {};
    tbl_268.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 4447
        ]]
        local tbl_269 = {};
        tbl_269.MoveFunction = function(a1)
            --[[
              name: MoveFunction
              line: 4450
            ]]
            return 1 - ((1 - a1) ^ 3);
        end;
        return tbl_269;
    end;
    tbl_268.Offset = CFrame.Angles(0, 0, 1.5707963267948966);
    tbl_268.UnsnappedOffset = CFrame.Angles(0, 0, -1.5707963267948966);
    tbl_268.RotateOffset = CFrame.Angles(0, 2.0943951023931953, 0);
    tbl_268.PlacingFunc = v19_1;
    tbl_268.CollisionFunc = u4;
    tbl_268.SnapPoints = {{BenchNames = {"Triangle Floor Frame"}, Offset = CFrame.new(0.02, 0, 1.45)}};
    v18["Triangle Trap Door"] = tbl_268;
end;
do
    local tbl_270 = {};
    tbl_270.BenchNames = {"Floor Frame"};
    tbl_270.Offset = CFrame.new(0, 0, 0);
    v18["Floor Grill"] = {Offset = CFrame.new(), UnsnappedOffset = CFrame.new(), RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0), PlacingFunc = v19_1, CollisionFunc = u4, SnapPoints = {tbl_270}};
end;
local tbl_271 = {};
tbl_271.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4503
    ]]
    local tbl_272 = {};
    tbl_272.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 4507
        ]]
        return (-(math.cos(math.pi * a1) - 1) / 2) * 8.672;
    end;
    return tbl_272;
end;
tbl_271.Offset = CFrame.new();
tbl_271.UnsnappedOffset = CFrame.new();
tbl_271.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_271.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_271.PlacingFunc = v19_1;
tbl_271.CollisionFunc = u4;
tbl_271.SnapPoints = {{BenchNames = {"Wall Frame"}, Offset = CFrame.new(0, 0, 0)}};
tbl_271.WallBlockOffset = CFrame.new(0, -3.75, 0);
v18["Garage Door"] = tbl_271;
local tbl_273 = {};
tbl_273.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4538
    ]]
    local tbl_274 = {};
    tbl_274.MoveFunction = function(a1)
        --[[
          name: MoveFunction
          line: 4541
        ]]
        return 1 - ((1 - a1) ^ 3);
    end;
    return tbl_274;
end;
tbl_273.Offset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_273.UnsnappedOffset = CFrame.new();
tbl_273.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_273.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_273.PlacingFunc = v19_1;
tbl_273.CollisionFunc = u4;
tbl_273.SnapPoints = {{BenchNames = {"Wall Frame"}, Offset = CFrame.new(0, 0, 0)}};
tbl_273.WallBlockOffset = CFrame.new(0, -3.75, 0);
v18["Jail Door"] = tbl_273;
do
    local tbl_275 = {};
    tbl_275.BenchNames = {"Wall Frame"};
    tbl_275.Offset = CFrame.new(0, 0, 0);
    v18["Jail Wall"] = {Offset = CFrame.Angles(0, 1.5707963267948966, 0), UnsnappedOffset = CFrame.new(), RotateOffset = CFrame.new(), PlacingFunc = v19_1, CollisionFunc = u4, SnapPoints = {tbl_275}, WallBlockOffset = CFrame.new(0, -3.75, 0)};
end;
v18["Wooden Window Bars"] = {Offset = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 1.5707963267948966, 0), UnsnappedOffset = CFrame.new(), RotateOffset = CFrame.new(), PlacingFunc = v19_1, CollisionFunc = u4, SnapPoints = {{BenchNames = {"Window"}, Offset = CFrame.new(0, 0, 0)}}};
v18["Metal Window Bars"] = {Offset = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 1.5707963267948966, 0), UnsnappedOffset = CFrame.new(), RotateOffset = CFrame.new(), PlacingFunc = v19_1, CollisionFunc = u4, SnapPoints = {{BenchNames = {"Window"}, Offset = CFrame.new(0, 0, 0)}}};
v18["Glass Window"] = {Offset = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 1.5707963267948966, 0), UnsnappedOffset = CFrame.new(), RotateOffset = CFrame.new(), PlacingFunc = v19_1, CollisionFunc = u4, SnapPoints = {{BenchNames = {"Window"}, Offset = CFrame.new(0, 0, 0)}}};
v18["Steel Glass Window"] = {Offset = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 1.5707963267948966, 0), UnsnappedOffset = CFrame.new(), RotateOffset = CFrame.new(), PlacingFunc = v19_1, CollisionFunc = u4, SnapPoints = {{BenchNames = {"Window"}, Offset = CFrame.new(0, 0, 0)}}};
v18["Vertical Window Cover"] = {Offset = CFrame.new(), UnsnappedOffset = CFrame.new(), RotateOffset = CFrame.Angles(0, math.pi, 0), OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0), PlacingFunc = v19_1, CollisionFunc = u4, SnapPoints = {{BenchNames = {"Window"}, Offset = CFrame.new(0, 0, 0)}}};
v18["Horizontal Window Cover"] = {Offset = CFrame.new(), UnsnappedOffset = CFrame.new(), RotateOffset = CFrame.Angles(0, math.pi, 0), OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0), PlacingFunc = v19_1, CollisionFunc = u4, SnapPoints = {{BenchNames = {"Window"}, Offset = CFrame.new(0, 0, 0)}}};
do
    local tbl_276 = {};
    tbl_276.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 4739
        ]]
        return {};
    end;
    local tbl_277 = {};
    local tbl_278 = {};
    tbl_278.Offset = CFrame.new(-4, -0.55, 0.6) * CFrame.Angles(-1.5707963267948966, 0, 0);
    tbl_277.Rays = {{Offset = CFrame.new(4, -0.55, 0.6) * CFrame.Angles(-1.5707963267948966, 0, 0)}, tbl_278};
    local tbl_279 = {};
    local tbl_280 = {};
    tbl_280.Offset = CFrame.new(-4, -0.55, -0.6) * CFrame.Angles(-1.5707963267948966, 0, 0);
    tbl_279.Rays = {{Offset = CFrame.new(4, -0.55, -0.6) * CFrame.Angles(-1.5707963267948966, 0, 0)}, tbl_280};
    tbl_276.AttachmentChecks = {{BenchNames = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Floor Frame", "Triangle Floor Frame"}, Checks = {tbl_277, tbl_279}}, {BenchNames = {"Wall", "Wall Frame", "Doorway", "Window", "Half Wall"}, Checks = {{Rays = {{Offset = CFrame.new(0, -1.05, 0) * CFrame.Angles(-1.5707963267948966, 0, 0)}}}}}};
    tbl_276.StabilityInfo = {Checks = {{Connections = {3}, StabilityLoss = {0}}, {Connections = {1, 2}, StabilityLoss = {0, 0}}}};
    tbl_276.NextConnections = {};
    v18["Wall Block"] = tbl_276;
end;
v18.BTR = {GuiOffset = Vector3.new()};
local tbl_281 = {};
tbl_281.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4817
    ]]
    return {};
end;
tbl_281.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 0.82, 0);
tbl_281.UnsnappedOffset = CFrame.new();
tbl_281.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_281.PlaceableAngles = {};
tbl_281.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_281.PlacingFunc = v1;
tbl_281.CollisionFunc = u4;
v18["Small Battery"] = tbl_281;
local tbl_282 = {};
tbl_282.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4853
    ]]
    return {};
end;
tbl_282.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 3.61, 0);
tbl_282.UnsnappedOffset = CFrame.new();
tbl_282.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_282.PlaceableAngles = {};
tbl_282.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_282.PlacingFunc = v1;
tbl_282.CollisionFunc = u4;
v18["Medium Battery"] = tbl_282;
local tbl_283 = {};
tbl_283.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4891
    ]]
    return {};
end;
tbl_283.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 4.23, 0);
tbl_283.UnsnappedOffset = CFrame.new();
tbl_283.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_283.PlaceableAngles = {};
tbl_283.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_283.PlacingFunc = v1;
tbl_283.CollisionFunc = u4;
v18["Large Battery"] = tbl_283;
local tbl_284 = {};
tbl_284.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4929
    ]]
    return {};
end;
tbl_284.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 1.1, 0);
tbl_284.UnsnappedOffset = CFrame.new();
tbl_284.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_284.PlaceableAngles = {};
tbl_284.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_284.PlacingFunc = v1;
tbl_284.CollisionFunc = u4;
v18["Solar Panel"] = tbl_284;
local tbl_285 = {};
tbl_285.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 4963
    ]]
    local tbl_286 = {};
    tbl_286.Slots = {"FuelCrude"};
    return tbl_286;
end;
tbl_285.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 2.3, 0);
tbl_285.UnsnappedOffset = CFrame.new();
tbl_285.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_285.PlaceableAngles = {};
tbl_285.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_285.PlacingFunc = v1;
tbl_285.CollisionFunc = u4;
v18["Crude Fuel Generator"] = tbl_285;
local tbl_287 = {};
tbl_287.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 5001
    ]]
    return {};
end;
tbl_287.Offset = CFrame.Angles(math.pi, 1.5707963267948966, 0) * CFrame.new(0, 0, 0);
tbl_287.UnsnappedOffset = CFrame.Angles(0, 0, 1.5707963267948966);
tbl_287.RotateOffset = CFrame.new();
tbl_287.PlaceableAngles = {};
tbl_287.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Wall", "Half Wall", "Low Wall", "Doorway", "Window"};
tbl_287.PlacingFunc = v1;
tbl_287.CollisionFunc = u4;
v18.Splitter = tbl_287;
local tbl_288 = {};
tbl_288.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 5035
    ]]
    return {};
end;
tbl_288.Offset = CFrame.Angles(math.pi, 1.5707963267948966, 0) * CFrame.new(0, 0, 0);
tbl_288.UnsnappedOffset = CFrame.Angles(0, 0, 1.5707963267948966);
tbl_288.RotateOffset = CFrame.new();
tbl_288.PlaceableAngles = {};
tbl_288.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Wall", "Half Wall", "Low Wall", "Doorway", "Window"};
tbl_288.PlacingFunc = v1;
tbl_288.CollisionFunc = u4;
v18.Button = tbl_288;
local tbl_289 = {};
tbl_289.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 5070
    ]]
    return {};
end;
tbl_289.Offset = CFrame.Angles(math.pi, 1.5707963267948966, 0) * CFrame.new(0, 0, 0);
tbl_289.UnsnappedOffset = CFrame.Angles(0, 0, 1.5707963267948966);
tbl_289.RotateOffset = CFrame.new();
tbl_289.PlaceableAngles = {};
tbl_289.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Wall", "Half Wall", "Low Wall", "Doorway", "Window"};
tbl_289.PlacingFunc = v1;
tbl_289.CollisionFunc = u4;
v18.Switch = tbl_289;
local tbl_290 = {};
tbl_290.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 5104
    ]]
    local tbl_291 = {};
    tbl_291.Slots = {"InputFurnace", "InputFurnace", "Output", "Output", "Output"};
    return tbl_291;
end;
tbl_290.Offset = CFrame.Angles(-1.5707963267948966, math.pi, 0) * CFrame.new(0, 2.1, 0);
tbl_290.UnsnappedOffset = CFrame.new();
tbl_290.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_290.PlaceableAngles = {};
tbl_290.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_290.PlacingFunc = v1;
tbl_290.CollisionFunc = u4;
tbl_290.Sounds = {};
v18["Electric Furnace"] = tbl_290;
local tbl_292 = {};
tbl_292.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 5160
    ]]
    return {};
end;
tbl_292.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.Angles(math.pi, 0, 0) * CFrame.new(-0.51, 0, 0);
tbl_292.UnsnappedOffset = CFrame.new();
tbl_292.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_292.PlaceableAngles = {};
tbl_292.PlaceWhitelist = {"Foundation", "Triangle Foundation", "Wall", "Half Wall", "Low Wall", "Doorway", "Window"};
tbl_292.PlacingFunc = v1;
tbl_292.CollisionFunc = u4;
tbl_292.Sounds = {};
v18["Electric Heater"] = tbl_292;
local tbl_293 = {};
tbl_293.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 5198
    ]]
    return {};
end;
tbl_293.Offset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 1.85, 0);
tbl_293.UnsnappedOffset = CFrame.new();
tbl_293.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_293.PlaceableAngles = {};
tbl_293.PlaceWhitelist = {"Terrain", "_Floor", "Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "U-Shaped Stairs", "L-Shaped Stairs"};
tbl_293.PlacingFunc = v1;
tbl_293.CollisionFunc = u4;
v18.Windmill = tbl_293;
local tbl_294 = {};
tbl_294.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 5233
    ]]
    return {};
end;
tbl_294.Offset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 8, 0);
tbl_294.UnsnappedOffset = CFrame.new();
tbl_294.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_294.PlaceableAngles = {};
tbl_294.PlaceWhitelist = {"Terrain"};
tbl_294.PlacingFunc = v1;
tbl_294.CollisionFunc = u4;
v18["Water Turbine"] = tbl_294;
local tbl_295 = {};
tbl_295.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 5270
    ]]
    return {};
end;
tbl_295.Offset = CFrame.new();
tbl_295.UnsnappedOffset = CFrame.new();
tbl_295.RotateOffset = CFrame.new();
tbl_295.PlacingFunc = v19_1;
local function v30(...)
    --[[
      line: 367
      upvalues:
        RaycastUtil_upv_1 (copy, index: 1)
        VFX_upv_1 (copy, index: 2)
        u2 (copy, index: 3)
        u4 (copy, index: 4)
    ]]
    local tbl_296 = {...};
    local v31 = tbl_296[1];
    local v32 = tbl_296[6];
    if (tbl_296[5] == false and v32) then
        tbl_296[5] = true;
    end;
    local v33 = 0;
    local v34 = 0;
    local v35, v36 = nil, nil;
    local v37 = nil;
    local v38 = nil;
    local CFrame_2 = nil;
    local Size_2 = nil;
    local tbl_297 = nil;
    local v39 = nil;
    local _ = nil;
    for v43, value_8 in pairs(v31:GetChildren()) do
        if (value_8.Name ~= "Pole") then
            continue;
        end;
        v33 = v33 + 1;
        CFrame_2 = value_8.CFrame;
        Size_2 = value_8.Size;
        v37 = (CFrame_2 * CFrame.new(0, (Size_2.Y / 2.4) + 0.3, 0)).Position;
        tbl_297 = {VFX_upv_1};
        v38 = RaycastUtil_upv_1:Raycast(v37, (CFrame_2 * CFrame.new(0, -Size_2.Y / 2.1, 0)).Position - v37, "Blacklist", tbl_297, false, u2, true);
        if (v38) then
            if (v38 == workspace.Terrain or v38.Name == "BoulderPart" or v38.Parent and v38.Parent.Name == "_Floor") then
                if (tbl_296[5] or not (v38) or not (v38)) then
                    continue;
                end;
                if (v38.Name == "BoulderPart") then
                    tbl_296[5] = true;
                    continue;
                end;
            end;
            return false;
        else
            v36 = false;
            local v40 = v37 + Vector3.new(0, 199, 0);
            local v41 = nil;
            for n_2 = 1, 3 do
                local v42;
                v39, v42 = RaycastUtil_upv_1:Raycast(v40, v37 - Vector3.new(0, 1, 0) - v40, "Whitelist", {workspace.Terrain}, false, nil, true);
                if (v39 == workspace.Terrain) then
                    v40, v41 = v42 - Vector3.new(0, 0.009999999776482582, 0), v40;
                    continue;
                elseif (n_2 ~= 2 or not (RaycastUtil_upv_1:Raycast(v42, v41 - v42, "Whitelist", {workspace.Terrain}, false, nil, true))) then
                    v35 = false;
                    if (n_2 > 1) then
                        v35 = v40.Y - v42.Y >= 10;
                    end;
                    v36 = v35;
                    break;
                else
                    break;
                end;
            end;
            if (v36) then
                v34 = v34 + 1;
            else
                return false;
            end;
            if (tbl_296[5] or not (v38)) then
                continue;
            end;
            if (v38.Name == "BoulderPart") then
                tbl_296[5] = true;
            end;
        end;
    end;
    if (v33 <= v34 and v33 > 0) then
        return false;
    end;
    return (u4(unpack(tbl_296)));
end;
tbl_295.CollisionFunc = v30;
tbl_295.NonBaseCollisionFunc = u3;
local function v43(a1, a2)
    --[[
      line: 433
    ]]
    local tbl_298 = {};
    for n_3 = 1, a1 do
        local v44, v45, v46, v47 = a2(n_3);
        table.insert(tbl_298, {BenchNames = v45, Offset = v44, AttachmentIndex = v46, Unsnappable = v47});
    end;
    return tbl_298;
end;
tbl_295.SnapPoints = {
    v43(
        5,
        function(a1)
            --[[
              line: 5290
            ]]
            local tbl_299 = {"Foundation"};
            return CFrame.new(0, (a1 - 3) * 5, 10), tbl_299, 1;
        end
    ),
    v43(
        5,
        function(a1)
            --[[
              line: 5294
            ]]
            local tbl_300 = {"Foundation"};
            return CFrame.new(0, (a1 - 3) * 5, -10), tbl_300, 2;
        end
    ),
    v43(
        5,
        function(a1)
            --[[
              line: 5298
            ]]
            local tbl_301 = {"Foundation"};
            return CFrame.new(10, (a1 - 3) * 5, 0), tbl_301, 3;
        end
    ),
    v43(
        5,
        function(a1)
            --[[
              line: 5302
            ]]
            local tbl_302 = {"Foundation"};
            return CFrame.new(-10, (a1 - 3) * 5, 0), tbl_302, 4;
        end
    ),
    v43(
        5,
        function(a1)
            --[[
              line: 5308
            ]]
            local tbl_303 = {"Triangle Foundation"};
            return CFrame.new((a1 - 3) * 5, 0, 9.333, 0, -1, 0, 0, 0, 1, -1, 0, 0), tbl_303, 1;
        end
    ),
    v43(
        5,
        function(a1)
            --[[
              line: 5312
            ]]
            local tbl_304 = {"Triangle Foundation"};
            return CFrame.new((a1 - 3) * 5, 6.83, -2.497, 0, -1, 0, 0.5, 0, -0.866, 0.866, 0, 0.5), tbl_304, 2;
        end
    ),
    v43(
        5,
        function(a1)
            --[[
              line: 5316
            ]]
            local tbl_305 = {"Triangle Foundation"};
            return CFrame.new((a1 - 3) * 5, -6.83, -2.497, 0, -1, 0, 0.866, 0, -0.5, 0.5, 0, 0.866), tbl_305, 3;
        end
    ),
    {BenchNames = {"Foundation Steps"}, Offset = CFrame.new(0, -2.5, -10)}
};
do
    local tbl_306 = {};
    local tbl_307 = {};
    tbl_307.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, 0, -4.4);
    tbl_306.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, 0, -4.4)}, tbl_307};
    local tbl_308 = {};
    local tbl_309 = {};
    tbl_309.Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, 0, -4.4);
    tbl_308.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, 0, -4.4)}, tbl_309};
    local tbl_310 = {};
    local tbl_311 = {};
    tbl_311.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, 0, -4.4);
    tbl_310.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, 0, -4.4)}, tbl_311};
    local tbl_312 = {};
    local tbl_313 = {};
    tbl_313.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, 0, -4.4);
    tbl_312.Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, 0, -4.4)}, tbl_313};
    local tbl_314 = {};
    local tbl_315 = {};
    tbl_315.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, -10, -4.4);
    tbl_314.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, -10, -4.4)}, tbl_315};
    local tbl_316 = {};
    local tbl_317 = {};
    tbl_317.Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, -10, -4.4);
    tbl_316.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, -10, -4.4)}, tbl_317};
    local tbl_318 = {};
    local tbl_319 = {};
    tbl_319.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, -10, -4.4);
    tbl_318.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, -10, -4.4)}, tbl_319};
    local tbl_320 = {};
    local tbl_321 = {};
    tbl_321.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, -10, -4.4);
    tbl_320.Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, -10, -4.4)}, tbl_321};
    local tbl_322 = {};
    local tbl_323 = {};
    tbl_323.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, 10, -4.4);
    tbl_322.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, 10, -4.4)}, tbl_323};
    local tbl_324 = {};
    local tbl_325 = {};
    tbl_325.Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, 10, -4.4);
    tbl_324.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, 10, -4.4)}, tbl_325};
    local tbl_326 = {};
    local tbl_327 = {};
    tbl_327.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, 10, -4.4);
    tbl_326.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, 10, -4.4)}, tbl_327};
    local tbl_328 = {};
    local tbl_329 = {};
    tbl_329.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, 10, -4.4);
    tbl_328.Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, 10, -4.4)}, tbl_329};
    local tbl_330 = {};
    local tbl_331 = {};
    tbl_331.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, 0.6, -4.3);
    tbl_330.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, 0.6, -4.3)}, tbl_331};
    local tbl_332 = {};
    tbl_332.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, 0.6, -4.3)}, {Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, 0.6, -4.3)}};
    local tbl_333 = {};
    tbl_333.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, 0.6, -4.3)}, {Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, 0.6, -4.3)}};
    local tbl_334 = {};
    tbl_334.Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, 0.6, -4.3)}, {Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, 0.6, -4.3)}};
    tbl_295.AttachmentChecks = {{BenchNames = {"Foundation", "Triangle Foundation", "Foundation Steps"}, Checks = {tbl_306, tbl_308, tbl_310, tbl_312, tbl_314, tbl_316, tbl_318, tbl_320, tbl_322, tbl_324, tbl_326, tbl_328}}, {BenchNames = {"Wall", "Wall Frame", "Doorway", "Window", "Half Wall", "Low Wall", "Wall Block"}, Checks = {tbl_330, tbl_332, tbl_333, tbl_334}}};
end;
tbl_295.NextConnections = {1, 2, 3, 4, 5, 6, 7, 8};
v18.Foundation = tbl_295;
do
    local tbl_335 = {};
    tbl_335.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 5556
        ]]
        return {};
    end;
    tbl_335.Offset = CFrame.new();
    tbl_335.UnsnappedOffset = CFrame.Angles(0, math.pi, -1.5707963267948966);
    tbl_335.RotateOffset = CFrame.new();
    tbl_335.PlacingFunc = v19_1;
    tbl_335.CollisionFunc = v30;
    tbl_335.NonBaseCollisionFunc = u3;
    tbl_335.SnapPoints = {
        v43(
            5,
            function(a1)
                --[[
                  line: 5576
                ]]
                local tbl_336 = {"Triangle Foundation"};
                return CFrame.new((a1 - 3) * 5, 0, 8.666, 1, 0, 0, 0, -1, 0, 0, 0, -1), tbl_336, 1;
            end
        ),
        v43(
            5,
            function(a1)
                --[[
                  line: 5580
                ]]
                local tbl_337 = {"Triangle Foundation"};
                return CFrame.new((a1 - 3) * 5, 3.748, -2.167, 1, 0, 0, 0, 0.5, 0.866, 0, -0.866, 0.5), tbl_337, 2;
            end
        ),
        v43(
            5,
            function(a1)
                --[[
                  line: 5584
                ]]
                local tbl_338 = {"Triangle Foundation"};
                return CFrame.new((a1 - 3) * 5, -3.748, -2.167, 1, 0, 0, 0, 0.5, -0.866, 0, 0.866, 0.5), tbl_338, 3;
            end
        ),
        v43(
            5,
            function(a1)
                --[[
                  line: 5590
                ]]
                local tbl_339 = {"Foundation"};
                return CFrame.Angles(0, math.pi, 0) * CFrame.new(0, (a1 - 3) * 5, -9.333, 0, 1, 0, -1, 0, 0, 0, 0, 1), tbl_339, 1;
            end
        ),
        v43(
            5,
            function(a1)
                --[[
                  line: 5594
                ]]
                local tbl_340 = {"Foundation"};
                return CFrame.Angles(0, 0, 0) * CFrame.new(0, (a1 - 3) * 5, -9.333, 0, 1, 0, -1, 0, 0, 0, 0, 1), tbl_340, 2;
            end
        ),
        v43(
            5,
            function(a1)
                --[[
                  line: 5598
                ]]
                local tbl_341 = {"Foundation"};
                return CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(0, (a1 - 3) * 5, -9.333, 0, 1, 0, -1, 0, 0, 0, 0, 1), tbl_341, 3;
            end
        ),
        v43(
            5,
            function(a1)
                --[[
                  line: 5602
                ]]
                local tbl_342 = {"Foundation"};
                return CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0, (a1 - 3) * 5, -9.333, 0, 1, 0, -1, 0, 0, 0, 0, 1), tbl_342, 4;
            end
        ),
        {BenchNames = {"Foundation Steps"}, Offset = CFrame.Angles(0, 0, 0) * CFrame.new(0, -2.5, -9.333, 0, 1, 0, -1, 0, 0, 0, 0, 1)}
    };
    local tbl_343 = {};
    local tbl_344 = {};
    tbl_344.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, -4, -4.1);
    tbl_343.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, -4, -4.1)}, tbl_344};
    local tbl_345 = {};
    local tbl_346 = {};
    tbl_346.Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(0, -2.6, -1.9);
    tbl_345.Rays = {{Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(0, 5, -1.9)}, tbl_346};
    local tbl_347 = {};
    local tbl_348 = {};
    tbl_348.Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(0, 2.6, -1.9);
    tbl_347.Rays = {{Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(0, -5, -1.9)}, tbl_348};
    local tbl_349 = {};
    local tbl_350 = {};
    tbl_350.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-10, -4, -4.1);
    tbl_349.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-10, -4, -4.1)}, tbl_350};
    local tbl_351 = {};
    local tbl_352 = {};
    tbl_352.Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(-10, -2.6, -1.9);
    tbl_351.Rays = {{Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(-10, 5, -1.9)}, tbl_352};
    local tbl_353 = {};
    local tbl_354 = {};
    tbl_354.Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(10, 2.6, -1.9);
    tbl_353.Rays = {{Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(10, -5, -1.9)}, tbl_354};
    local tbl_355 = {};
    local tbl_356 = {};
    tbl_356.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(10, -4, -4.1);
    tbl_355.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(10, -4, -4.1)}, tbl_356};
    local tbl_357 = {};
    local tbl_358 = {};
    tbl_358.Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(10, -2.6, -1.9);
    tbl_357.Rays = {{Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(10, 5, -1.9)}, tbl_358};
    local tbl_359 = {};
    local tbl_360 = {};
    tbl_360.Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(10, 2.6, -1.9);
    tbl_359.Rays = {{Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(10, -5, -1.9)}, tbl_360};
    local tbl_361 = {};
    local tbl_362 = {};
    tbl_362.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0.6, -4, -3.6);
    tbl_361.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0.6, 4, -3.6)}, tbl_362};
    local tbl_363 = {};
    tbl_363.Rays = {{Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(-0.6, 5, -1.6)}, {Offset = CFrame.Angles(1.0471975511965976, 0, 0) * CFrame.new(-0.6, -2.6, -1.6)}};
    local tbl_364 = {};
    tbl_364.Rays = {{Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(-0.6, -5, -1.6)}, {Offset = CFrame.Angles(-1.0471975511965976, 0, 0) * CFrame.new(-0.6, 2.6, -1.6)}};
    tbl_335.AttachmentChecks = {{BenchNames = {"Foundation", "Triangle Foundation", "Foundation Steps"}, Checks = {tbl_343, tbl_345, tbl_347, tbl_349, tbl_351, tbl_353, tbl_355, tbl_357, tbl_359}}, {BenchNames = {"Wall", "Wall Frame", "Doorway", "Window", "Half Wall", "Low Wall", "Wall Block"}, Checks = {tbl_361, tbl_363, tbl_364}}};
    tbl_335.NextConnections = {1, 2, 3, 4, 5, 6};
    v18["Triangle Foundation"] = tbl_335;
end;
do
    local tbl_365 = {};
    tbl_365.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 5790
        ]]
        return {};
    end;
    tbl_365.Offset = CFrame.new();
    tbl_365.UnsnappedOffset = CFrame.new();
    tbl_365.RotateOffset = CFrame.new();
    tbl_365.PlacingFunc = v19_1;
    tbl_365.CollisionFunc = v30;
    tbl_365.NonBaseCollisionFunc = u3;
    local tbl_366 = {};
    tbl_366.BenchNames = {"Foundation"};
    tbl_366.Offset = CFrame.Angles(0, 0, 0) * CFrame.new(0, -2.5, -10);
    local tbl_367 = {};
    tbl_367.BenchNames = {"Foundation"};
    tbl_367.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0, -2.5, -10);
    local tbl_368 = {};
    tbl_368.BenchNames = {"Triangle Foundation"};
    tbl_368.Offset = CFrame.new(2.5, 0, 9.333, 0, -1, 0, 0, 0, 1, -1, 0, 0) * CFrame.Angles(0, 1.5707963267948966, 0);
    local tbl_369 = {};
    tbl_369.BenchNames = {"Triangle Foundation"};
    tbl_369.Offset = CFrame.new(2.5, 6.83, -2.497, 0, -1, 0, 0.5, 0, -0.866, 0.866, 0, 0.5);
    local tbl_370 = {};
    tbl_370.BenchNames = {"Triangle Foundation"};
    tbl_370.Offset = CFrame.new(2.5, -6.83, -2.497, 0, -1, 0, 0.866, 0, -0.5, 0.5, 0, 0.866) * CFrame.Angles(0, 1.5707963267948966, 0);
    local tbl_371 = {};
    tbl_371.BenchNames = {"Foundation Steps"};
    tbl_371.Offset = CFrame.new(0, -5, -10);
    local tbl_372 = {};
    tbl_372.BenchNames = {"Foundation Steps"};
    tbl_372.Offset = CFrame.new(0, 5, 10);
    tbl_365.SnapPoints = {{BenchNames = {"Foundation"}, Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, -2.5, -10)}, tbl_366, {BenchNames = {"Foundation"}, Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(0, -2.5, -10)}, tbl_367, tbl_368, tbl_369, tbl_370, tbl_371, tbl_372};
    local tbl_373 = {};
    local tbl_374 = {};
    tbl_374.Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, 0, -4.4);
    tbl_373.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, 0, -4.4)}, tbl_374};
    local tbl_375 = {};
    local tbl_376 = {};
    tbl_376.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, 0, -4.4);
    tbl_375.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, 0, -4.4)}, tbl_376};
    local tbl_377 = {};
    local tbl_378 = {};
    tbl_378.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, 0, -4.4);
    tbl_377.Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, 0, -4.4)}, tbl_378};
    local tbl_379 = {};
    local tbl_380 = {};
    tbl_380.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, 0, -4.4);
    tbl_379.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, 0, -4.4)}, tbl_380};
    local tbl_381 = {};
    local tbl_382 = {};
    tbl_382.Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, -10, -4.4);
    tbl_381.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, -10, -4.4)}, tbl_382};
    local tbl_383 = {};
    local tbl_384 = {};
    tbl_384.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, -10, -4.4);
    tbl_383.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, -10, -4.4)}, tbl_384};
    local tbl_385 = {};
    local tbl_386 = {};
    tbl_386.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, -10, -4.4);
    tbl_385.Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, -10, -4.4)}, tbl_386};
    local tbl_387 = {};
    local tbl_388 = {};
    tbl_388.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, -10, -4.4);
    tbl_387.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, -10, -4.4)}, tbl_388};
    local tbl_389 = {};
    local tbl_390 = {};
    tbl_390.Offset = CFrame.Angles(0, 0, 0) * CFrame.new(-4, 10, -4.4);
    tbl_389.Rays = {{Offset = CFrame.Angles(0, 0, 0) * CFrame.new(4, 10, -4.4)}, tbl_390};
    local tbl_391 = {};
    local tbl_392 = {};
    tbl_392.Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(-4, 10, -4.4);
    tbl_391.Rays = {{Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(4, 10, -4.4)}, tbl_392};
    local tbl_393 = {};
    local tbl_394 = {};
    tbl_394.Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(-4, 10, -4.4);
    tbl_393.Rays = {{Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(4, 10, -4.4)}, tbl_394};
    local tbl_395 = {};
    local tbl_396 = {};
    tbl_396.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-4, 10, -4.4);
    tbl_395.Rays = {{Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(4, 10, -4.4)}, tbl_396};
    tbl_365.AttachmentChecks = {{BenchNames = {"Foundation", "Triangle Foundation", "Foundation Steps"}, Checks = {tbl_373, tbl_375, tbl_377, tbl_379, tbl_381, tbl_383, tbl_385, tbl_387, tbl_389, tbl_391, tbl_393, tbl_395}}};
    tbl_365.StabilityInfo = {Checks = {{Connections = {2}, StabilityLoss = {0}}}};
    tbl_365.NextConnections = {1, 2, 3, 4};
    v18["Foundation Steps"] = tbl_365;
end;
local tbl_397 = {};
tbl_397.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6038
    ]]
    return {};
end;
tbl_397.Offset = CFrame.new();
tbl_397.UnsnappedOffset = CFrame.new();
tbl_397.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_397.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_397.PlacingFunc = v19_1;
tbl_397.CollisionFunc = u4;
tbl_397.NonBaseCollisionFunc = u3;
tbl_397.SnapPoints = tbl_1.SnapPoints;
tbl_397.AttachmentChecks = tbl_1.AttachmentChecks;
tbl_397.StabilityInfo = tbl_1.StabilityInfo;
tbl_397.NextConnections = tbl_1.NextConnections;
tbl_397.WallBlockOffset = CFrame.new(0, -3.75, 0);
v18.Wall = tbl_397;
local tbl_398 = {};
tbl_398.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6064
    ]]
    return {};
end;
tbl_398.Offset = CFrame.new();
tbl_398.UnsnappedOffset = CFrame.new();
tbl_398.RotateOffset = CFrame.new();
tbl_398.PlacingFunc = v19_1;
tbl_398.CollisionFunc = u4;
tbl_398.NonBaseCollisionFunc = u3;
tbl_398.SnapPoints = tbl_1.SnapPoints;
tbl_398.AttachmentChecks = tbl_1.AttachmentChecks;
tbl_398.StabilityInfo = tbl_1.StabilityInfo;
tbl_398.NextConnections = tbl_1.NextConnections;
tbl_398.WallBlockOffset = CFrame.new(0, -3.75, 0);
v18["Wall Frame"] = tbl_398;
local tbl_399 = {};
tbl_399.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6088
    ]]
    return {};
end;
tbl_399.Offset = CFrame.new();
tbl_399.UnsnappedOffset = CFrame.new();
tbl_399.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_399.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_399.PlacingFunc = v19_1;
tbl_399.CollisionFunc = u4;
tbl_399.NonBaseCollisionFunc = u3;
tbl_399.SnapPoints = tbl_1.SnapPoints;
tbl_399.AttachmentChecks = tbl_1.AttachmentChecks;
tbl_399.StabilityInfo = tbl_1.StabilityInfo;
tbl_399.NextConnections = tbl_1.NextConnections;
tbl_399.RotateIgnores = {13};
tbl_399.WallBlockOffset = CFrame.new(0, -3.75, 0);
v18.Doorway = tbl_399;
local tbl_400 = {};
tbl_400.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6115
    ]]
    return {};
end;
tbl_400.Offset = CFrame.new();
tbl_400.UnsnappedOffset = CFrame.new();
tbl_400.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_400.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_400.PlacingFunc = v19_1;
tbl_400.CollisionFunc = u4;
tbl_400.NonBaseCollisionFunc = u3;
tbl_400.SnapPoints = tbl_1.SnapPoints;
tbl_400.AttachmentChecks = tbl_1.AttachmentChecks;
tbl_400.StabilityInfo = tbl_1.StabilityInfo;
tbl_400.NextConnections = tbl_1.NextConnections;
tbl_400.RotateIgnores = {13};
tbl_400.WallBlockOffset = CFrame.new(0, -3.75, 0);
v18.Window = tbl_400;
do
    local tbl_401 = {};
    tbl_401.TypeArguments = function()
        --[[
          name: TypeArguments
          line: 6142
        ]]
        return {};
    end;
    tbl_401.Offset = CFrame.new();
    tbl_401.UnsnappedOffset = CFrame.new();
    tbl_401.RotateOffset = CFrame.Angles(0, math.pi, 0);
    tbl_401.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
    tbl_401.PlacingFunc = v19_1;
    tbl_401.CollisionFunc = u4;
    tbl_401.NonBaseCollisionFunc = u3;
    local tbl_402 = {};
    tbl_402.BenchNames = {"Foundation", "Floor", "Floor Frame"};
    tbl_402.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(0, 2.5, 5);
    local tbl_403 = {};
    tbl_403.BenchNames = {"Triangle Foundation", "Triangle Floor", "Triangle Floor Frame"};
    tbl_403.Offset = CFrame.new(-2.5, 0, 4.333, 0, -1, 0, 1, 0, 0, 0, 0, 1);
    local tbl_404 = {};
    tbl_404.BenchNames = {"Triangle Foundation", "Triangle Floor", "Triangle Floor Frame"};
    tbl_404.Offset = CFrame.new(-2.5, 2.5, 0, 0, -1, 0, -0.5, 0, 0.866, -0.866, 0, -0.5);
    local tbl_405 = {};
    tbl_405.BenchNames = {"Triangle Foundation", "Triangle Floor", "Triangle Floor Frame"};
    tbl_405.Offset = CFrame.new(-2.5, -2.5, 0, 0, -1, 0, -0.5, 0, -0.866, 0.866, 0, -0.5);
    local tbl_406 = {};
    tbl_406.BenchNames = {"Wall", "Wall Frame", "Doorway", "Window"};
    tbl_406.Offset = CFrame.new(0, 7.5, 0);
    local tbl_407 = {};
    tbl_407.BenchNames = {"Half Wall"};
    tbl_407.Offset = CFrame.new(0, 5, 0);
    tbl_401.SnapPoints = {{BenchNames = {"Foundation", "Floor", "Floor Frame"}, Offset = CFrame.Angles(0, 0, 0) * CFrame.new(0, 2.5, 5)}, {BenchNames = {"Foundation", "Floor", "Floor Frame"}, Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 2.5, 5)}, {BenchNames = {"Foundation", "Floor", "Floor Frame"}, Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0, 2.5, 5)}, tbl_402, tbl_403, tbl_404, tbl_405, tbl_406, tbl_407};
    local tbl_408 = {};
    local tbl_409 = {};
    tbl_409.Offset = CFrame.new(-4, -1.8, 0.6) * CFrame.Angles(-1.5707963267948966, 0, 0);
    tbl_408.Rays = {{Offset = CFrame.new(4, -1.8, 0.6) * CFrame.Angles(-1.5707963267948966, 0, 0)}, tbl_409};
    local tbl_410 = {};
    local tbl_411 = {};
    tbl_411.Offset = CFrame.new(-4, -1.8, -0.6) * CFrame.Angles(-1.5707963267948966, 0, 0);
    tbl_410.Rays = {{Offset = CFrame.new(4, -1.8, -0.6) * CFrame.Angles(-1.5707963267948966, 0, 0)}, tbl_411};
    local tbl_412 = {tbl_408, tbl_410};
    local tbl_413 = {};
    tbl_413.BenchNames = {"Wall", "Wall Frame", "Doorway", "Window", "Half Wall"};
    local tbl_414 = {};
    tbl_414.Rays = {{Offset = CFrame.new(0, -2.3, 0) * CFrame.Angles(-1.5707963267948966, 0, 0)}};
    local tbl_415 = {};
    local tbl_416 = {};
    tbl_416.Offset = CFrame.new(-5.6, 0, -0.6) * CFrame.Angles(math.pi, 0, 0);
    tbl_415.Rays = {{Offset = CFrame.new(-5.6, 0, 0.6) * CFrame.Angles(0, 0, 0)}, tbl_416};
    local tbl_417 = {};
    local tbl_418 = {};
    tbl_418.Offset = CFrame.new(5.6, 0, -0.6) * CFrame.Angles(math.pi, 0, 0);
    tbl_417.Rays = {{Offset = CFrame.new(5.6, 0, 0.6) * CFrame.Angles(0, 0, 0)}, tbl_418};
    tbl_413.Checks = {{Rays = {{Offset = CFrame.new(0, 2.3, 0) * CFrame.Angles(1.5707963267948966, 0, 0)}}}, tbl_414, tbl_415, tbl_417};
    local tbl_419 = {};
    local tbl_420 = {};
    tbl_420.Offset = CFrame.new(-4, 1.8, 0.6) * CFrame.Angles(1.5707963267948966, 0, 0);
    tbl_419.Rays = {{Offset = CFrame.new(4, 1.8, 0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}, tbl_420};
    tbl_401.AttachmentChecks = {{BenchNames = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Floor Frame", "Triangle Floor Frame"}, Checks = tbl_412}, tbl_413, {BenchNames = {"Floor", "Triangle Floor", "Floor Frame", "Triangle Floor Frame"}, Checks = {tbl_419, {Rays = {{Offset = CFrame.new(4, 1.8, -0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}, {Offset = CFrame.new(-4, 1.8, -0.6) * CFrame.Angles(1.5707963267948966, 0, 0)}}}}}};
    tbl_401.StabilityInfo = {LossPerHeight = {}, Checks = {{Connections = {4}, StabilityLoss = {0}}, {Connections = {1, 2}, StabilityLoss = {0, 0}, BenchNames = {"Foundation", "Triangle Foundation"}}, {Connections = {1, 2}, StabilityLoss = {20, 10}}, {Connections = {5, 6}, StabilityLoss = {60, 40}}, {Connections = {7, 8}, StabilityLoss = {40, 40}}}};
    tbl_401.NextConnections = {3, 5, 6, 7, 8};
    tbl_401.WallBlockOffset = CFrame.new(0, -1.25, 0);
    v18["Half Wall"] = tbl_401;
end;
local tbl_421 = {};
tbl_421.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6362
    ]]
    return {};
end;
tbl_421.Offset = CFrame.new();
tbl_421.UnsnappedOffset = CFrame.new();
tbl_421.RotateOffset = CFrame.Angles(0, math.pi, 0);
tbl_421.OffsetSnappedFacingAway = CFrame.Angles(0, math.pi, 0);
tbl_421.PlacingFunc = v19_1;
tbl_421.CollisionFunc = u4;
tbl_421.NonBaseCollisionFunc = u3;
local tbl_422 = {};
tbl_422.BenchNames = {"Foundation", "Floor", "Floor Frame"};
tbl_422.Offset = CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(0, 1.25, 5);
local tbl_423 = {};
tbl_423.BenchNames = {"Triangle Foundation", "Triangle Floor", "Triangle Floor Frame"};
tbl_423.Offset = CFrame.new(-1.25, 0, 4.333, 0, -1, 0, 1, 0, 0, 0, 0, 1);
local tbl_424 = {};
tbl_424.BenchNames = {"Triangle Foundation", "Triangle Floor", "Triangle Floor Frame"};
tbl_424.Offset = CFrame.new(-1.25, -2.5, 0, 0, -1, 0, -0.5, 0, -0.866, 0.866, 0, -0.5);
local tbl_425 = {};
tbl_425.BenchNames = {"Wall", "Wall Frame", "Doorway", "Window"};
tbl_425.Offset = CFrame.new(0, 6.25, 0);
local tbl_426 = {};
tbl_426.BenchNames = {"Half Wall"};
tbl_426.Offset = CFrame.new(0, 3.75, 0);
tbl_421.SnapPoints = {
    {BenchNames = {"Foundation", "Floor", "Floor Frame"}, Offset = CFrame.Angles(0, 0, 0) * CFrame.new(0, 1.25, 5)},
    {BenchNames = {"Foundation", "Floor", "Floor Frame"}, Offset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 1.25, 5)},
    {BenchNames = {"Foundation", "Floor", "Floor Frame"}, Offset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0, 1.25, 5)},
    tbl_422,
    tbl_423,
    {BenchNames = {"Triangle Foundation", "Triangle Floor", "Triangle Floor Frame"}, Offset = CFrame.new(-1.25, 2.5, 0, 0, -1, 0, -0.5, 0, 0.866, -0.866, 0, -0.5)},
    tbl_424,
    tbl_425,
    tbl_426
};
local tbl_427 = {};
local tbl_428 = {};
tbl_428.Offset = CFrame.new(-4, -0.55, 0.6) * CFrame.Angles(-1.5707963267948966, 0, 0);
tbl_427.Rays = {{Offset = CFrame.new(4, -0.55, 0.6) * CFrame.Angles(-1.5707963267948966, 0, 0)}, tbl_428};
local tbl_430 = {};
tbl_430.Rays = {{Offset = CFrame.new(4, -0.55, -0.6) * CFrame.Angles(-1.5707963267948966, 0, 0)}, {Offset = CFrame.new(-4, -0.55, -0.6) * CFrame.Angles(-1.5707963267948966, 0, 0)}};
local tbl_432 = {};
tbl_432.Rays = {{Offset = CFrame.new(0, -1.05, 0) * CFrame.Angles(-1.5707963267948966, 0, 0)}};
tbl_421.AttachmentChecks = {{BenchNames = {"Foundation", "Triangle Foundation", "Floor", "Triangle Floor", "Floor Frame", "Triangle Floor Frame"}, Checks = {tbl_427, tbl_430}}, {BenchNames = {"Wall", "Wall Frame", "Doorway", "Window", "Half Wall"}, Checks = {tbl_432}}};
tbl_421.StabilityInfo = {LossPerHeight = {}, Checks = {{Connections = {3}, StabilityLoss = {0}}, {Connections = {1, 2}, StabilityLoss = {0, 0}, BenchNames = {"Foundation", "Triangle Foundation"}}, {Connections = {1, 2}, StabilityLoss = {5, 5}}}};
tbl_421.NextConnections = {};
tbl_421.WallBlockOffset = CFrame.new(0, 0, 0);
v18["Low Wall"] = tbl_421;
local tbl_434 = {};
tbl_434.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6505
    ]]
    return {};
end;
tbl_434.Offset = CFrame.new();
tbl_434.UnsnappedOffset = CFrame.new();
tbl_434.RotateOffset = CFrame.new();
tbl_434.PlacingFunc = v19_1;
tbl_434.CollisionFunc = u4;
tbl_434.NonBaseCollisionFunc = u3;
tbl_434.SnapPoints = tbl_29.SnapPoints;
tbl_434.AttachmentChecks = tbl_29.AttachmentChecks;
tbl_434.StabilityInfo = tbl_29.StabilityInfo;
tbl_434.NextConnections = tbl_29.NextConnections;
v18.Floor = tbl_434;
local tbl_435 = {};
tbl_435.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6530
    ]]
    return {};
end;
tbl_435.Offset = CFrame.new();
tbl_435.UnsnappedOffset = CFrame.new();
tbl_435.RotateOffset = CFrame.new();
tbl_435.PlacingFunc = v19_1;
tbl_435.CollisionFunc = u4;
tbl_435.NonBaseCollisionFunc = u3;
tbl_435.SnapPoints = tbl_29.SnapPoints;
tbl_435.AttachmentChecks = tbl_29.AttachmentChecks;
tbl_435.StabilityInfo = tbl_29.StabilityInfo;
tbl_435.NextConnections = tbl_29.NextConnections;
v18["Floor Frame"] = tbl_435;
local tbl_436 = {};
tbl_436.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6554
    ]]
    return {};
end;
tbl_436.Offset = CFrame.new();
tbl_436.UnsnappedOffset = CFrame.Angles(0, math.pi, -1.5707963267948966);
tbl_436.RotateOffset = CFrame.new();
tbl_436.PlacingFunc = v19_1;
tbl_436.CollisionFunc = v30;
tbl_436.NonBaseCollisionFunc = u3;
tbl_436.SnapPoints = tbl_55.SnapPoints;
tbl_436.AttachmentChecks = tbl_55.AttachmentChecks;
tbl_436.StabilityInfo = tbl_55.StabilityInfo;
tbl_436.NextConnections = tbl_55.NextConnections;
v18["Triangle Floor"] = tbl_436;
local tbl_437 = {};
tbl_437.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6579
    ]]
    return {};
end;
tbl_437.Offset = CFrame.new();
tbl_437.UnsnappedOffset = CFrame.Angles(0, math.pi, -1.5707963267948966);
tbl_437.RotateOffset = CFrame.new();
tbl_437.PlacingFunc = v19_1;
tbl_437.CollisionFunc = v30;
tbl_437.NonBaseCollisionFunc = u3;
tbl_437.SnapPoints = tbl_55.SnapPoints;
tbl_437.AttachmentChecks = tbl_55.AttachmentChecks;
tbl_437.StabilityInfo = tbl_55.StabilityInfo;
tbl_437.NextConnections = tbl_55.NextConnections;
v18["Triangle Floor Frame"] = tbl_437;
local tbl_438 = {};
tbl_438.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6603
    ]]
    return {};
end;
tbl_438.Offset = CFrame.new();
tbl_438.UnsnappedOffset = CFrame.new();
tbl_438.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_438.PlacingFunc = v19_1;
tbl_438.CollisionFunc = u4;
tbl_438.NonBaseCollisionFunc = u3;
tbl_438.SnapPoints = tbl_71.SnapPoints;
tbl_438.AttachmentChecks = tbl_71.AttachmentChecks;
tbl_438.StabilityInfo = tbl_71.StabilityInfo;
tbl_438.NextConnections = tbl_71.NextConnections;
v18["L-Shaped Stairs"] = tbl_438;
local tbl_439 = {};
tbl_439.TypeArguments = function()
    --[[
      name: TypeArguments
      line: 6628
    ]]
    return {};
end;
tbl_439.Offset = CFrame.new();
tbl_439.UnsnappedOffset = CFrame.new();
tbl_439.RotateOffset = CFrame.Angles(0, 1.5707963267948966, 0);
tbl_439.PlacingFunc = v19_1;
tbl_439.CollisionFunc = u4;
tbl_439.NonBaseCollisionFunc = u3;
tbl_439.SnapPoints = tbl_71.SnapPoints;
tbl_439.AttachmentChecks = tbl_71.AttachmentChecks;
tbl_439.StabilityInfo = tbl_71.StabilityInfo;
tbl_439.NextConnections = tbl_71.NextConnections;
v18["U-Shaped Stairs"] = tbl_439;
u1 = v18;
local v48 = nil;
local v53 = nil;
local v54 = nil;
local v49 = nil;
for v55, value_9 in pairs(u1) do
    v49 = value_9.SnapPoints;
    if (not (v49)) then
        continue;
    end;
    v48 = {};
    for v56, value_10 in pairs(v49) do
        for v57, value_11 in pairs(((value_10[1]) and value_10) or {value_10}) do
            table.insert(v48, value_11);
        end;
    end;
    value_9.SnapPoints = v48;
end;
return u1;