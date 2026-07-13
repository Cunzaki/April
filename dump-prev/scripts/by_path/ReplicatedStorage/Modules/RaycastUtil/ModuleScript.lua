-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Players_1 = game:GetService("Players");
local Debris_upv_1 = game:GetService("Debris");
local VFX_upv_1 = ReplicatedStorage_1:WaitForChild("VFX");
local VFX_upv_2 = workspace:WaitForChild("VFX");
local Animals_upv_1 = workspace:WaitForChild("Animals");
local Events_upv_1 = workspace:WaitForChild("Events");
local Values_upv_1 = ReplicatedStorage_1:WaitForChild("Values");
local u1 = Players_1.LocalPlayer;
local tbl_1 = {};
tbl_1.FilterFunction = function(a1, a2)
    --[[
      name: FilterFunction
      line: 27
      upvalues:
        Animals_upv_1 (copy, index: 1)
        Events_upv_1 (copy, index: 2)
    ]]
    local v1 = nil;
    if (a2 == "Hit" or a2 == "HitIgnore" or a2 == "HitMelee" or a2 == "HitMeleeIgnore" or a2 == "HitNoMeleeMouse") then
        v1 = function(a3)
            --[[
              line: 28
              upvalues:
                Animals_upv_1 (copy, index: 1)
                Events_upv_1 (copy, index: 2)
                a2 (copy, index: 3)
            ]]
            local Parent_1 = a3.Parent;
            if (not Parent_1) then
                return;
            end;
            if (Parent_1.Parent:FindFirstChild("Humanoid") and not (Parent_1:IsDescendantOf(Animals_upv_1)) and not (Parent_1:IsDescendantOf(Events_upv_1)) or Parent_1.Parent.Name == "Attachments" and (Parent_1.Parent:IsA("Folder")) or (Parent_1.Name == "Jail Wall" or a3:FindFirstAncestor("Jail Door")) and a2 == "Hit") then
                return Parent_1;
            end;
            if (a3.CollisionGroup == "Items") then
                if (a2 ~= "Hit" or Parent_1.Name ~= "Body Bag" and Parent_1.Name ~= "Contents" and Parent_1.Name ~= "Salvaged Backpack" and Parent_1.Name ~= "Military Backpack") then
                    if (Parent_1:FindFirstChild("Humanoid") and (a3.Name == "HumanoidRootPart" or a3.Name == "CollisionPart") or a3.Transparency >= 1 and (a2 ~= "HitMelee" or Parent_1.Name ~= "NodeSpark" and Parent_1.Name ~= "TreeX") and not (a3.CanCollide) or a3.Name == "LeafPart"
                        or Parent_1:FindFirstChild("Humanoid") and (a3.Name == "HumanoidRootPart" or a3.Name == "CollisionPart") or a3.Transparency >= 1 and (a2 ~= "HitMelee" or Parent_1.Name ~= "NodeSpark" and Parent_1.Name ~= "TreeX") and not (a3.CanCollide) or a3.Name == "LeafPart" or a3.CollisionGroup == "VehicleFake" or a3.Name == "CactusPart" and a2 == "Hit" or a3.Name == "SignPart" and not (a2:find("Melee"))) then
                        return a3;
                    end;
                    return;
                end;
                return Parent_1;
            end;
            if (Parent_1:FindFirstChild("Humanoid") and (a3.Name == "HumanoidRootPart" or a3.Name == "CollisionPart") or a3.Transparency >= 1 and (a2 ~= "HitMelee" or Parent_1.Name ~= "NodeSpark" and Parent_1.Name ~= "TreeX") and not (a3.CanCollide) or a3.Name == "LeafPart"
                or Parent_1:FindFirstChild("Humanoid") and (a3.Name == "HumanoidRootPart" or a3.Name == "CollisionPart") or a3.Transparency >= 1 and (a2 ~= "HitMelee" or Parent_1.Name ~= "NodeSpark" and Parent_1.Name ~= "TreeX") and not (a3.CanCollide) or a3.Name == "LeafPart" or a3.CollisionGroup == "VehicleFake" or a3.Name == "CactusPart" and a2 == "Hit" or a3.Name == "SignPart" and not (a2:find("Melee"))) then
                return a3;
            end;
        end;
        if (not (v1)) then
            if (a2 == "HitPlace") then
                v1 = function(a4)
                    --[[
                      line: 36
                    ]]
                    local Parent_2 = a4.Parent;
                    if (Parent_2.Parent.Name == "Attachments" and Parent_2.Parent:IsA("Folder")) then
                        return Parent_2;
                    end;
                    if (a4.Transparency >= 1 and Parent_2.Name ~= "CollisionParts" and a4.Name ~= "SpawnPart" and not (a4.CanCollide)) then
                        return a4;
                    end;
                    if (not Parent_2:FindFirstChild("CollisionParts") and (not (Parent_2.Parent:FindFirstChild("CollisionParts")) or Parent_2.Name == "CollisionParts") and a4.Name ~= "LeafPart" and a4.CollisionGroup ~= "VehicleFake") then
                        if (Parent_2:FindFirstChild("Humanoid") and a4.Name ~= "HumanoidRootPart" and a4.Name ~= "CollisionPart") then
                            return a4;
                        elseif (Parent_2.Parent:FindFirstChild("Humanoid")) then
                            return Parent_2;
                        else
                            return;
                        end;
                    end;
                    return a4;
                end;
                if (not v1) then
                    if (a2 == "View" or a2 == "ViewBench" or a2 == "ViewExtra" or a2 == "ViewPlant") then
                        v1 = function(a5)
                            --[[
                              line: 53
                              upvalues:
                                a2 (copy, index: 1)
                            ]]
                            local Parent_3 = a5.Parent;
                            local v2 = Parent_3:FindFirstChild("Humanoid") or (Parent_3.Parent:FindFirstChild("Humanoid"));
                            if (v2) then
                                if (a2 ~= "View" and a2 ~= "ViewPlant" and v2.Parent.Name == "Sleeper" or a2 == "ViewBench" and v2.Parent.Name == "Contents") then
                                    if ((Parent_3.Parent.Name ~= "Attachments" or not (Parent_3.Parent:IsA("Folder"))) and (a2 ~= "ViewPlant" or Parent_3.Name ~= "Floor Grill" and Parent_3.Name ~= "Barrel Light") and (a2 ~= "ViewExtra" or Parent_3.Name ~= "Wooden Boat" and Parent_3.Name ~= "Military Boat" and Parent_3.Name ~= "Salvaged Flycopter")) then
                                        if ((a2 == "View" or a2 == "ViewPlant") and a5.Transparency >= 1) then
                                            if (a5.CanCollide and a5.Name ~= "LeafPart") then
                                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                                    return a5;
                                                end;
                                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                        if (Parent_3) then
                                                            local v3 = nil;
                                                            if (a2 == "ViewExtra") then
                                                                v3 = Parent_3.Parent;
                                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                                    return v3;
                                                                end;
                                                            end;
                                                        end;
                                                        return;
                                                    end;
                                                    return a5;
                                                end;
                                            end;
                                            return a5;
                                        end;
                                        if (a2 ~= "ViewBench") then
                                            if (a5.Name ~= "LeafPart") then
                                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                                    return a5;
                                                end;
                                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                        if (Parent_3) then
                                                            local v3 = nil;
                                                            if (a2 == "ViewExtra") then
                                                                v3 = Parent_3.Parent;
                                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                                    return v3;
                                                                end;
                                                            end;
                                                        end;
                                                        return;
                                                    end;
                                                    return a5;
                                                end;
                                            end;
                                            return a5;
                                        elseif (a5.Transparency ~= 1 or a5.CanCollide) then
                                            if (a5.Name ~= "LeafPart") then
                                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                                    return a5;
                                                end;
                                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                        if (Parent_3) then
                                                            local v3 = nil;
                                                            if (a2 == "ViewExtra") then
                                                                v3 = Parent_3.Parent;
                                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                                    return v3;
                                                                end;
                                                            end;
                                                        end;
                                                        return;
                                                    end;
                                                    return a5;
                                                end;
                                            end;
                                        else
                                            return a5;
                                        end;
                                    end;
                                    return Parent_3;
                                end;
                                return v2.Parent;
                            end;
                            if ((Parent_3.Parent.Name ~= "Attachments" or not (Parent_3.Parent:IsA("Folder"))) and (a2 ~= "ViewPlant" or Parent_3.Name ~= "Floor Grill" and Parent_3.Name ~= "Barrel Light") and (a2 ~= "ViewExtra" or Parent_3.Name ~= "Wooden Boat" and Parent_3.Name ~= "Military Boat" and Parent_3.Name ~= "Salvaged Flycopter")) then
                                if ((a2 == "View" or a2 == "ViewPlant") and a5.Transparency >= 1) then
                                    if (a5.CanCollide and a5.Name ~= "LeafPart") then
                                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                            return a5;
                                        end;
                                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                if (Parent_3) then
                                                    local v3 = nil;
                                                    if (a2 == "ViewExtra") then
                                                        v3 = Parent_3.Parent;
                                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                                            return v3;
                                                        end;
                                                    end;
                                                end;
                                                return;
                                            end;
                                            return a5;
                                        end;
                                    end;
                                    return a5;
                                end;
                                if (a2 ~= "ViewBench") then
                                    if (a5.Name ~= "LeafPart") then
                                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                            return a5;
                                        end;
                                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                if (Parent_3) then
                                                    local v3 = nil;
                                                    if (a2 == "ViewExtra") then
                                                        v3 = Parent_3.Parent;
                                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                                            return v3;
                                                        end;
                                                    end;
                                                end;
                                                return;
                                            end;
                                            return a5;
                                        end;
                                    end;
                                    return a5;
                                elseif (a5.Transparency ~= 1 or a5.CanCollide) then
                                    if (a5.Name ~= "LeafPart") then
                                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                            return a5;
                                        end;
                                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                if (Parent_3) then
                                                    local v3 = nil;
                                                    if (a2 == "ViewExtra") then
                                                        v3 = Parent_3.Parent;
                                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                                            return v3;
                                                        end;
                                                    end;
                                                end;
                                                return;
                                            end;
                                            return a5;
                                        end;
                                    end;
                                else
                                    return a5;
                                end;
                            end;
                            return Parent_3;
                        end;
                        if (not v1) then
                            if (a2 ~= "PlacementDefault") then
                                v1 = false;
                                if (a2 == "BuildingPrivCheck") then
                                    v1 = function(a6)
                                        --[[
                                          line: 90
                                        ]]
                                        local v4 = nil;
                                        if (a6.Name == "BuildingPriv") then
                                            v4 = a6:FindFirstAncestor("Base");
                                            local v5 = nil;
                                            if (v4) then
                                                v5 = v4:FindFirstChild("Base Cabinet");
                                                if (v5 and #v5:GetChildren() > 0) then
                                                    return;
                                                end;
                                            end;
                                        end;
                                        return a6;
                                    end;
                                end;
                            else
                                v1 = function(a7)
                                    --[[
                                      line: 70
                                    ]]
                                    local v6 = nil;
                                    if (a7) then
                                        v6 = a7.Parent;
                                    end;
                                    if (a7 and v6) then
                                        if (a7.Name ~= "LeafPart" and a7.CollisionGroup ~= "VehicleFake") then
                                            if (a7.Transparency ~= 1 or a7.Position.Y ~= 478 and a7.Position.Y ~= 578 and a7.Name ~= "RadiationPart") then
                                                if (v6.Parent.Name == "Attachments" and v6.Parent:IsA("Folder")) then
                                                    return a7.Parent;
                                                end;
                                                if (a7.Transparency == 1 and a7.Name == "BuildingPriv") then
                                                    return a7;
                                                end;
                                                local v7 = v6:FindFirstChild("Humanoid") or (v6.Parent:FindFirstChild("Humanoid"));
                                                if (v7) then
                                                    return v7.Parent;
                                                end;
                                                return;
                                            end;
                                            return a7.Parent;
                                        end;
                                        return a7;
                                    end;
                                end;
                                if (not v1) then
                                    v1 = false;
                                    if (a2 == "BuildingPrivCheck") then
                                        v1 = function(a6)
                                            --[[
                                              line: 90
                                            ]]
                                            local v4 = nil;
                                            if (a6.Name == "BuildingPriv") then
                                                v4 = a6:FindFirstAncestor("Base");
                                                local v5 = nil;
                                                if (v4) then
                                                    v5 = v4:FindFirstChild("Base Cabinet");
                                                    if (v5 and #v5:GetChildren() > 0) then
                                                        return;
                                                    end;
                                                end;
                                            end;
                                            return a6;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    elseif (a2 ~= "PlacementDefault") then
                        v1 = false;
                        if (a2 == "BuildingPrivCheck") then
                            v1 = function(a6)
                                --[[
                                  line: 90
                                ]]
                                local v4 = nil;
                                if (a6.Name == "BuildingPriv") then
                                    v4 = a6:FindFirstAncestor("Base");
                                    local v5 = nil;
                                    if (v4) then
                                        v5 = v4:FindFirstChild("Base Cabinet");
                                        if (v5 and #v5:GetChildren() > 0) then
                                            return;
                                        end;
                                    end;
                                end;
                                return a6;
                            end;
                        end;
                    else
                        v1 = function(a7)
                            --[[
                              line: 70
                            ]]
                            local v6 = nil;
                            if (a7) then
                                v6 = a7.Parent;
                            end;
                            if (a7 and v6) then
                                if (a7.Name ~= "LeafPart" and a7.CollisionGroup ~= "VehicleFake") then
                                    if (a7.Transparency ~= 1 or a7.Position.Y ~= 478 and a7.Position.Y ~= 578 and a7.Name ~= "RadiationPart") then
                                        if (v6.Parent.Name == "Attachments" and v6.Parent:IsA("Folder")) then
                                            return a7.Parent;
                                        end;
                                        if (a7.Transparency == 1 and a7.Name == "BuildingPriv") then
                                            return a7;
                                        end;
                                        local v7 = v6:FindFirstChild("Humanoid") or (v6.Parent:FindFirstChild("Humanoid"));
                                        if (v7) then
                                            return v7.Parent;
                                        end;
                                        return;
                                    end;
                                    return a7.Parent;
                                end;
                                return a7;
                            end;
                        end;
                        if (not v1) then
                            v1 = false;
                            if (a2 == "BuildingPrivCheck") then
                                v1 = function(a6)
                                    --[[
                                      line: 90
                                    ]]
                                    local v4 = nil;
                                    if (a6.Name == "BuildingPriv") then
                                        v4 = a6:FindFirstAncestor("Base");
                                        local v5 = nil;
                                        if (v4) then
                                            v5 = v4:FindFirstChild("Base Cabinet");
                                            if (v5 and #v5:GetChildren() > 0) then
                                                return;
                                            end;
                                        end;
                                    end;
                                    return a6;
                                end;
                            end;
                        end;
                    end;
                end;
            elseif (a2 == "View" or a2 == "ViewBench" or a2 == "ViewExtra" or a2 == "ViewPlant") then
                v1 = function(a5)
                    --[[
                      line: 53
                      upvalues:
                        a2 (copy, index: 1)
                    ]]
                    local Parent_3 = a5.Parent;
                    local v2 = Parent_3:FindFirstChild("Humanoid") or (Parent_3.Parent:FindFirstChild("Humanoid"));
                    if (v2) then
                        if (a2 ~= "View" and a2 ~= "ViewPlant" and v2.Parent.Name == "Sleeper" or a2 == "ViewBench" and v2.Parent.Name == "Contents") then
                            if ((Parent_3.Parent.Name ~= "Attachments" or not (Parent_3.Parent:IsA("Folder"))) and (a2 ~= "ViewPlant" or Parent_3.Name ~= "Floor Grill" and Parent_3.Name ~= "Barrel Light") and (a2 ~= "ViewExtra" or Parent_3.Name ~= "Wooden Boat" and Parent_3.Name ~= "Military Boat" and Parent_3.Name ~= "Salvaged Flycopter")) then
                                if ((a2 == "View" or a2 == "ViewPlant") and a5.Transparency >= 1) then
                                    if (a5.CanCollide and a5.Name ~= "LeafPart") then
                                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                            return a5;
                                        end;
                                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                if (Parent_3) then
                                                    local v3 = nil;
                                                    if (a2 == "ViewExtra") then
                                                        v3 = Parent_3.Parent;
                                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                                            return v3;
                                                        end;
                                                    end;
                                                end;
                                                return;
                                            end;
                                            return a5;
                                        end;
                                    end;
                                    return a5;
                                end;
                                if (a2 ~= "ViewBench") then
                                    if (a5.Name ~= "LeafPart") then
                                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                            return a5;
                                        end;
                                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                if (Parent_3) then
                                                    local v3 = nil;
                                                    if (a2 == "ViewExtra") then
                                                        v3 = Parent_3.Parent;
                                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                                            return v3;
                                                        end;
                                                    end;
                                                end;
                                                return;
                                            end;
                                            return a5;
                                        end;
                                    end;
                                    return a5;
                                elseif (a5.Transparency ~= 1 or a5.CanCollide) then
                                    if (a5.Name ~= "LeafPart") then
                                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                            return a5;
                                        end;
                                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                if (Parent_3) then
                                                    local v3 = nil;
                                                    if (a2 == "ViewExtra") then
                                                        v3 = Parent_3.Parent;
                                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                                            return v3;
                                                        end;
                                                    end;
                                                end;
                                                return;
                                            end;
                                            return a5;
                                        end;
                                    end;
                                else
                                    return a5;
                                end;
                            end;
                            return Parent_3;
                        end;
                        return v2.Parent;
                    end;
                    if ((Parent_3.Parent.Name ~= "Attachments" or not (Parent_3.Parent:IsA("Folder"))) and (a2 ~= "ViewPlant" or Parent_3.Name ~= "Floor Grill" and Parent_3.Name ~= "Barrel Light") and (a2 ~= "ViewExtra" or Parent_3.Name ~= "Wooden Boat" and Parent_3.Name ~= "Military Boat" and Parent_3.Name ~= "Salvaged Flycopter")) then
                        if ((a2 == "View" or a2 == "ViewPlant") and a5.Transparency >= 1) then
                            if (a5.CanCollide and a5.Name ~= "LeafPart") then
                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                    return a5;
                                end;
                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                        if (Parent_3) then
                                            local v3 = nil;
                                            if (a2 == "ViewExtra") then
                                                v3 = Parent_3.Parent;
                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                    return v3;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                    return a5;
                                end;
                            end;
                            return a5;
                        end;
                        if (a2 ~= "ViewBench") then
                            if (a5.Name ~= "LeafPart") then
                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                    return a5;
                                end;
                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                        if (Parent_3) then
                                            local v3 = nil;
                                            if (a2 == "ViewExtra") then
                                                v3 = Parent_3.Parent;
                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                    return v3;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                    return a5;
                                end;
                            end;
                            return a5;
                        elseif (a5.Transparency ~= 1 or a5.CanCollide) then
                            if (a5.Name ~= "LeafPart") then
                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                    return a5;
                                end;
                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                        if (Parent_3) then
                                            local v3 = nil;
                                            if (a2 == "ViewExtra") then
                                                v3 = Parent_3.Parent;
                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                    return v3;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                    return a5;
                                end;
                            end;
                        else
                            return a5;
                        end;
                    end;
                    return Parent_3;
                end;
                if (not v1) then
                    if (a2 ~= "PlacementDefault") then
                        v1 = false;
                        if (a2 == "BuildingPrivCheck") then
                            v1 = function(a6)
                                --[[
                                  line: 90
                                ]]
                                local v4 = nil;
                                if (a6.Name == "BuildingPriv") then
                                    v4 = a6:FindFirstAncestor("Base");
                                    local v5 = nil;
                                    if (v4) then
                                        v5 = v4:FindFirstChild("Base Cabinet");
                                        if (v5 and #v5:GetChildren() > 0) then
                                            return;
                                        end;
                                    end;
                                end;
                                return a6;
                            end;
                        end;
                    else
                        v1 = function(a7)
                            --[[
                              line: 70
                            ]]
                            local v6 = nil;
                            if (a7) then
                                v6 = a7.Parent;
                            end;
                            if (a7 and v6) then
                                if (a7.Name ~= "LeafPart" and a7.CollisionGroup ~= "VehicleFake") then
                                    if (a7.Transparency ~= 1 or a7.Position.Y ~= 478 and a7.Position.Y ~= 578 and a7.Name ~= "RadiationPart") then
                                        if (v6.Parent.Name == "Attachments" and v6.Parent:IsA("Folder")) then
                                            return a7.Parent;
                                        end;
                                        if (a7.Transparency == 1 and a7.Name == "BuildingPriv") then
                                            return a7;
                                        end;
                                        local v7 = v6:FindFirstChild("Humanoid") or (v6.Parent:FindFirstChild("Humanoid"));
                                        if (v7) then
                                            return v7.Parent;
                                        end;
                                        return;
                                    end;
                                    return a7.Parent;
                                end;
                                return a7;
                            end;
                        end;
                        if (not v1) then
                            v1 = false;
                            if (a2 == "BuildingPrivCheck") then
                                v1 = function(a6)
                                    --[[
                                      line: 90
                                    ]]
                                    local v4 = nil;
                                    if (a6.Name == "BuildingPriv") then
                                        v4 = a6:FindFirstAncestor("Base");
                                        local v5 = nil;
                                        if (v4) then
                                            v5 = v4:FindFirstChild("Base Cabinet");
                                            if (v5 and #v5:GetChildren() > 0) then
                                                return;
                                            end;
                                        end;
                                    end;
                                    return a6;
                                end;
                            end;
                        end;
                    end;
                end;
            elseif (a2 ~= "PlacementDefault") then
                v1 = false;
                if (a2 == "BuildingPrivCheck") then
                    v1 = function(a6)
                        --[[
                          line: 90
                        ]]
                        local v4 = nil;
                        if (a6.Name == "BuildingPriv") then
                            v4 = a6:FindFirstAncestor("Base");
                            local v5 = nil;
                            if (v4) then
                                v5 = v4:FindFirstChild("Base Cabinet");
                                if (v5 and #v5:GetChildren() > 0) then
                                    return;
                                end;
                            end;
                        end;
                        return a6;
                    end;
                end;
            else
                v1 = function(a7)
                    --[[
                      line: 70
                    ]]
                    local v6 = nil;
                    if (a7) then
                        v6 = a7.Parent;
                    end;
                    if (a7 and v6) then
                        if (a7.Name ~= "LeafPart" and a7.CollisionGroup ~= "VehicleFake") then
                            if (a7.Transparency ~= 1 or a7.Position.Y ~= 478 and a7.Position.Y ~= 578 and a7.Name ~= "RadiationPart") then
                                if (v6.Parent.Name == "Attachments" and v6.Parent:IsA("Folder")) then
                                    return a7.Parent;
                                end;
                                if (a7.Transparency == 1 and a7.Name == "BuildingPriv") then
                                    return a7;
                                end;
                                local v7 = v6:FindFirstChild("Humanoid") or (v6.Parent:FindFirstChild("Humanoid"));
                                if (v7) then
                                    return v7.Parent;
                                end;
                                return;
                            end;
                            return a7.Parent;
                        end;
                        return a7;
                    end;
                end;
                if (not v1) then
                    v1 = false;
                    if (a2 == "BuildingPrivCheck") then
                        v1 = function(a6)
                            --[[
                              line: 90
                            ]]
                            local v4 = nil;
                            if (a6.Name == "BuildingPriv") then
                                v4 = a6:FindFirstAncestor("Base");
                                local v5 = nil;
                                if (v4) then
                                    v5 = v4:FindFirstChild("Base Cabinet");
                                    if (v5 and #v5:GetChildren() > 0) then
                                        return;
                                    end;
                                end;
                            end;
                            return a6;
                        end;
                    end;
                end;
            end;
        end;
    elseif (a2 == "HitPlace") then
        v1 = function(a4)
            --[[
              line: 36
            ]]
            local Parent_2 = a4.Parent;
            if (Parent_2.Parent.Name == "Attachments" and Parent_2.Parent:IsA("Folder")) then
                return Parent_2;
            end;
            if (a4.Transparency >= 1 and Parent_2.Name ~= "CollisionParts" and a4.Name ~= "SpawnPart" and not (a4.CanCollide)) then
                return a4;
            end;
            if (not Parent_2:FindFirstChild("CollisionParts") and (not (Parent_2.Parent:FindFirstChild("CollisionParts")) or Parent_2.Name == "CollisionParts") and a4.Name ~= "LeafPart" and a4.CollisionGroup ~= "VehicleFake") then
                if (Parent_2:FindFirstChild("Humanoid") and a4.Name ~= "HumanoidRootPart" and a4.Name ~= "CollisionPart") then
                    return a4;
                elseif (Parent_2.Parent:FindFirstChild("Humanoid")) then
                    return Parent_2;
                else
                    return;
                end;
            end;
            return a4;
        end;
        if (not v1) then
            if (a2 == "View" or a2 == "ViewBench" or a2 == "ViewExtra" or a2 == "ViewPlant") then
                v1 = function(a5)
                    --[[
                      line: 53
                      upvalues:
                        a2 (copy, index: 1)
                    ]]
                    local Parent_3 = a5.Parent;
                    local v2 = Parent_3:FindFirstChild("Humanoid") or (Parent_3.Parent:FindFirstChild("Humanoid"));
                    if (v2) then
                        if (a2 ~= "View" and a2 ~= "ViewPlant" and v2.Parent.Name == "Sleeper" or a2 == "ViewBench" and v2.Parent.Name == "Contents") then
                            if ((Parent_3.Parent.Name ~= "Attachments" or not (Parent_3.Parent:IsA("Folder"))) and (a2 ~= "ViewPlant" or Parent_3.Name ~= "Floor Grill" and Parent_3.Name ~= "Barrel Light") and (a2 ~= "ViewExtra" or Parent_3.Name ~= "Wooden Boat" and Parent_3.Name ~= "Military Boat" and Parent_3.Name ~= "Salvaged Flycopter")) then
                                if ((a2 == "View" or a2 == "ViewPlant") and a5.Transparency >= 1) then
                                    if (a5.CanCollide and a5.Name ~= "LeafPart") then
                                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                            return a5;
                                        end;
                                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                if (Parent_3) then
                                                    local v3 = nil;
                                                    if (a2 == "ViewExtra") then
                                                        v3 = Parent_3.Parent;
                                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                                            return v3;
                                                        end;
                                                    end;
                                                end;
                                                return;
                                            end;
                                            return a5;
                                        end;
                                    end;
                                    return a5;
                                end;
                                if (a2 ~= "ViewBench") then
                                    if (a5.Name ~= "LeafPart") then
                                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                            return a5;
                                        end;
                                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                if (Parent_3) then
                                                    local v3 = nil;
                                                    if (a2 == "ViewExtra") then
                                                        v3 = Parent_3.Parent;
                                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                                            return v3;
                                                        end;
                                                    end;
                                                end;
                                                return;
                                            end;
                                            return a5;
                                        end;
                                    end;
                                    return a5;
                                elseif (a5.Transparency ~= 1 or a5.CanCollide) then
                                    if (a5.Name ~= "LeafPart") then
                                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                            return a5;
                                        end;
                                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                                if (Parent_3) then
                                                    local v3 = nil;
                                                    if (a2 == "ViewExtra") then
                                                        v3 = Parent_3.Parent;
                                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                                            return v3;
                                                        end;
                                                    end;
                                                end;
                                                return;
                                            end;
                                            return a5;
                                        end;
                                    end;
                                else
                                    return a5;
                                end;
                            end;
                            return Parent_3;
                        end;
                        return v2.Parent;
                    end;
                    if ((Parent_3.Parent.Name ~= "Attachments" or not (Parent_3.Parent:IsA("Folder"))) and (a2 ~= "ViewPlant" or Parent_3.Name ~= "Floor Grill" and Parent_3.Name ~= "Barrel Light") and (a2 ~= "ViewExtra" or Parent_3.Name ~= "Wooden Boat" and Parent_3.Name ~= "Military Boat" and Parent_3.Name ~= "Salvaged Flycopter")) then
                        if ((a2 == "View" or a2 == "ViewPlant") and a5.Transparency >= 1) then
                            if (a5.CanCollide and a5.Name ~= "LeafPart") then
                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                    return a5;
                                end;
                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                        if (Parent_3) then
                                            local v3 = nil;
                                            if (a2 == "ViewExtra") then
                                                v3 = Parent_3.Parent;
                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                    return v3;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                    return a5;
                                end;
                            end;
                            return a5;
                        end;
                        if (a2 ~= "ViewBench") then
                            if (a5.Name ~= "LeafPart") then
                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                    return a5;
                                end;
                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                        if (Parent_3) then
                                            local v3 = nil;
                                            if (a2 == "ViewExtra") then
                                                v3 = Parent_3.Parent;
                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                    return v3;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                    return a5;
                                end;
                            end;
                            return a5;
                        elseif (a5.Transparency ~= 1 or a5.CanCollide) then
                            if (a5.Name ~= "LeafPart") then
                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                    return a5;
                                end;
                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                        if (Parent_3) then
                                            local v3 = nil;
                                            if (a2 == "ViewExtra") then
                                                v3 = Parent_3.Parent;
                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                    return v3;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                    return a5;
                                end;
                            end;
                        else
                            return a5;
                        end;
                    end;
                    return Parent_3;
                end;
                if (not v1) then
                    if (a2 ~= "PlacementDefault") then
                        v1 = false;
                        if (a2 == "BuildingPrivCheck") then
                            v1 = function(a6)
                                --[[
                                  line: 90
                                ]]
                                local v4 = nil;
                                if (a6.Name == "BuildingPriv") then
                                    v4 = a6:FindFirstAncestor("Base");
                                    local v5 = nil;
                                    if (v4) then
                                        v5 = v4:FindFirstChild("Base Cabinet");
                                        if (v5 and #v5:GetChildren() > 0) then
                                            return;
                                        end;
                                    end;
                                end;
                                return a6;
                            end;
                        end;
                    else
                        v1 = function(a7)
                            --[[
                              line: 70
                            ]]
                            local v6 = nil;
                            if (a7) then
                                v6 = a7.Parent;
                            end;
                            if (a7 and v6) then
                                if (a7.Name ~= "LeafPart" and a7.CollisionGroup ~= "VehicleFake") then
                                    if (a7.Transparency ~= 1 or a7.Position.Y ~= 478 and a7.Position.Y ~= 578 and a7.Name ~= "RadiationPart") then
                                        if (v6.Parent.Name == "Attachments" and v6.Parent:IsA("Folder")) then
                                            return a7.Parent;
                                        end;
                                        if (a7.Transparency == 1 and a7.Name == "BuildingPriv") then
                                            return a7;
                                        end;
                                        local v7 = v6:FindFirstChild("Humanoid") or (v6.Parent:FindFirstChild("Humanoid"));
                                        if (v7) then
                                            return v7.Parent;
                                        end;
                                        return;
                                    end;
                                    return a7.Parent;
                                end;
                                return a7;
                            end;
                        end;
                        if (not v1) then
                            v1 = false;
                            if (a2 == "BuildingPrivCheck") then
                                v1 = function(a6)
                                    --[[
                                      line: 90
                                    ]]
                                    local v4 = nil;
                                    if (a6.Name == "BuildingPriv") then
                                        v4 = a6:FindFirstAncestor("Base");
                                        local v5 = nil;
                                        if (v4) then
                                            v5 = v4:FindFirstChild("Base Cabinet");
                                            if (v5 and #v5:GetChildren() > 0) then
                                                return;
                                            end;
                                        end;
                                    end;
                                    return a6;
                                end;
                            end;
                        end;
                    end;
                end;
            elseif (a2 ~= "PlacementDefault") then
                v1 = false;
                if (a2 == "BuildingPrivCheck") then
                    v1 = function(a6)
                        --[[
                          line: 90
                        ]]
                        local v4 = nil;
                        if (a6.Name == "BuildingPriv") then
                            v4 = a6:FindFirstAncestor("Base");
                            local v5 = nil;
                            if (v4) then
                                v5 = v4:FindFirstChild("Base Cabinet");
                                if (v5 and #v5:GetChildren() > 0) then
                                    return;
                                end;
                            end;
                        end;
                        return a6;
                    end;
                end;
            else
                v1 = function(a7)
                    --[[
                      line: 70
                    ]]
                    local v6 = nil;
                    if (a7) then
                        v6 = a7.Parent;
                    end;
                    if (a7 and v6) then
                        if (a7.Name ~= "LeafPart" and a7.CollisionGroup ~= "VehicleFake") then
                            if (a7.Transparency ~= 1 or a7.Position.Y ~= 478 and a7.Position.Y ~= 578 and a7.Name ~= "RadiationPart") then
                                if (v6.Parent.Name == "Attachments" and v6.Parent:IsA("Folder")) then
                                    return a7.Parent;
                                end;
                                if (a7.Transparency == 1 and a7.Name == "BuildingPriv") then
                                    return a7;
                                end;
                                local v7 = v6:FindFirstChild("Humanoid") or (v6.Parent:FindFirstChild("Humanoid"));
                                if (v7) then
                                    return v7.Parent;
                                end;
                                return;
                            end;
                            return a7.Parent;
                        end;
                        return a7;
                    end;
                end;
                if (not v1) then
                    v1 = false;
                    if (a2 == "BuildingPrivCheck") then
                        v1 = function(a6)
                            --[[
                              line: 90
                            ]]
                            local v4 = nil;
                            if (a6.Name == "BuildingPriv") then
                                v4 = a6:FindFirstAncestor("Base");
                                local v5 = nil;
                                if (v4) then
                                    v5 = v4:FindFirstChild("Base Cabinet");
                                    if (v5 and #v5:GetChildren() > 0) then
                                        return;
                                    end;
                                end;
                            end;
                            return a6;
                        end;
                    end;
                end;
            end;
        end;
    elseif (a2 == "View" or a2 == "ViewBench" or a2 == "ViewExtra" or a2 == "ViewPlant") then
        v1 = function(a5)
            --[[
              line: 53
              upvalues:
                a2 (copy, index: 1)
            ]]
            local Parent_3 = a5.Parent;
            local v2 = Parent_3:FindFirstChild("Humanoid") or (Parent_3.Parent:FindFirstChild("Humanoid"));
            if (v2) then
                if (a2 ~= "View" and a2 ~= "ViewPlant" and v2.Parent.Name == "Sleeper" or a2 == "ViewBench" and v2.Parent.Name == "Contents") then
                    if ((Parent_3.Parent.Name ~= "Attachments" or not (Parent_3.Parent:IsA("Folder"))) and (a2 ~= "ViewPlant" or Parent_3.Name ~= "Floor Grill" and Parent_3.Name ~= "Barrel Light") and (a2 ~= "ViewExtra" or Parent_3.Name ~= "Wooden Boat" and Parent_3.Name ~= "Military Boat" and Parent_3.Name ~= "Salvaged Flycopter")) then
                        if ((a2 == "View" or a2 == "ViewPlant") and a5.Transparency >= 1) then
                            if (a5.CanCollide and a5.Name ~= "LeafPart") then
                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                    return a5;
                                end;
                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                        if (Parent_3) then
                                            local v3 = nil;
                                            if (a2 == "ViewExtra") then
                                                v3 = Parent_3.Parent;
                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                    return v3;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                    return a5;
                                end;
                            end;
                            return a5;
                        end;
                        if (a2 ~= "ViewBench") then
                            if (a5.Name ~= "LeafPart") then
                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                    return a5;
                                end;
                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                        if (Parent_3) then
                                            local v3 = nil;
                                            if (a2 == "ViewExtra") then
                                                v3 = Parent_3.Parent;
                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                    return v3;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                    return a5;
                                end;
                            end;
                            return a5;
                        elseif (a5.Transparency ~= 1 or a5.CanCollide) then
                            if (a5.Name ~= "LeafPart") then
                                if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                                    return a5;
                                end;
                                if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                                    if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                        if (Parent_3) then
                                            local v3 = nil;
                                            if (a2 == "ViewExtra") then
                                                v3 = Parent_3.Parent;
                                                if (v3 and v3.Name == "Salvaged Flycopter") then
                                                    return v3;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                    return a5;
                                end;
                            end;
                        else
                            return a5;
                        end;
                    end;
                    return Parent_3;
                end;
                return v2.Parent;
            end;
            if ((Parent_3.Parent.Name ~= "Attachments" or not (Parent_3.Parent:IsA("Folder"))) and (a2 ~= "ViewPlant" or Parent_3.Name ~= "Floor Grill" and Parent_3.Name ~= "Barrel Light") and (a2 ~= "ViewExtra" or Parent_3.Name ~= "Wooden Boat" and Parent_3.Name ~= "Military Boat" and Parent_3.Name ~= "Salvaged Flycopter")) then
                if ((a2 == "View" or a2 == "ViewPlant") and a5.Transparency >= 1) then
                    if (a5.CanCollide and a5.Name ~= "LeafPart") then
                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                            return a5;
                        end;
                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                if (Parent_3) then
                                    local v3 = nil;
                                    if (a2 == "ViewExtra") then
                                        v3 = Parent_3.Parent;
                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                            return v3;
                                        end;
                                    end;
                                end;
                                return;
                            end;
                            return a5;
                        end;
                    end;
                    return a5;
                end;
                if (a2 ~= "ViewBench") then
                    if (a5.Name ~= "LeafPart") then
                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                            return a5;
                        end;
                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                if (Parent_3) then
                                    local v3 = nil;
                                    if (a2 == "ViewExtra") then
                                        v3 = Parent_3.Parent;
                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                            return v3;
                                        end;
                                    end;
                                end;
                                return;
                            end;
                            return a5;
                        end;
                    end;
                    return a5;
                elseif (a5.Transparency ~= 1 or a5.CanCollide) then
                    if (a5.Name ~= "LeafPart") then
                        if ((a2 == "View" or a2 == "ViewExtra") and a5.CollisionGroup == "VehicleFake") then
                            return a5;
                        end;
                        if (a5.Name ~= "CactusPart" and a5.Name ~= "SignPart" and (a2 ~= "View" and a2 ~= "ViewPlant" or a5.CollisionGroup ~= "Items")) then
                            if (a2 ~= "ViewExtra" or a5.CollisionGroup ~= "Items" and a5.CanCollide) then
                                if (Parent_3) then
                                    local v3 = nil;
                                    if (a2 == "ViewExtra") then
                                        v3 = Parent_3.Parent;
                                        if (v3 and v3.Name == "Salvaged Flycopter") then
                                            return v3;
                                        end;
                                    end;
                                end;
                                return;
                            end;
                            return a5;
                        end;
                    end;
                else
                    return a5;
                end;
            end;
            return Parent_3;
        end;
        if (not v1) then
            if (a2 ~= "PlacementDefault") then
                v1 = false;
                if (a2 == "BuildingPrivCheck") then
                    v1 = function(a6)
                        --[[
                          line: 90
                        ]]
                        local v4 = nil;
                        if (a6.Name == "BuildingPriv") then
                            v4 = a6:FindFirstAncestor("Base");
                            local v5 = nil;
                            if (v4) then
                                v5 = v4:FindFirstChild("Base Cabinet");
                                if (v5 and #v5:GetChildren() > 0) then
                                    return;
                                end;
                            end;
                        end;
                        return a6;
                    end;
                end;
            else
                v1 = function(a7)
                    --[[
                      line: 70
                    ]]
                    local v6 = nil;
                    if (a7) then
                        v6 = a7.Parent;
                    end;
                    if (a7 and v6) then
                        if (a7.Name ~= "LeafPart" and a7.CollisionGroup ~= "VehicleFake") then
                            if (a7.Transparency ~= 1 or a7.Position.Y ~= 478 and a7.Position.Y ~= 578 and a7.Name ~= "RadiationPart") then
                                if (v6.Parent.Name == "Attachments" and v6.Parent:IsA("Folder")) then
                                    return a7.Parent;
                                end;
                                if (a7.Transparency == 1 and a7.Name == "BuildingPriv") then
                                    return a7;
                                end;
                                local v7 = v6:FindFirstChild("Humanoid") or (v6.Parent:FindFirstChild("Humanoid"));
                                if (v7) then
                                    return v7.Parent;
                                end;
                                return;
                            end;
                            return a7.Parent;
                        end;
                        return a7;
                    end;
                end;
                if (not v1) then
                    v1 = false;
                    if (a2 == "BuildingPrivCheck") then
                        v1 = function(a6)
                            --[[
                              line: 90
                            ]]
                            local v4 = nil;
                            if (a6.Name == "BuildingPriv") then
                                v4 = a6:FindFirstAncestor("Base");
                                local v5 = nil;
                                if (v4) then
                                    v5 = v4:FindFirstChild("Base Cabinet");
                                    if (v5 and #v5:GetChildren() > 0) then
                                        return;
                                    end;
                                end;
                            end;
                            return a6;
                        end;
                    end;
                end;
            end;
        end;
    elseif (a2 ~= "PlacementDefault") then
        v1 = false;
        if (a2 == "BuildingPrivCheck") then
            v1 = function(a6)
                --[[
                  line: 90
                ]]
                local v4 = nil;
                if (a6.Name == "BuildingPriv") then
                    v4 = a6:FindFirstAncestor("Base");
                    local v5 = nil;
                    if (v4) then
                        v5 = v4:FindFirstChild("Base Cabinet");
                        if (v5 and #v5:GetChildren() > 0) then
                            return;
                        end;
                    end;
                end;
                return a6;
            end;
        end;
    else
        v1 = function(a7)
            --[[
              line: 70
            ]]
            local v6 = nil;
            if (a7) then
                v6 = a7.Parent;
            end;
            if (a7 and v6) then
                if (a7.Name ~= "LeafPart" and a7.CollisionGroup ~= "VehicleFake") then
                    if (a7.Transparency ~= 1 or a7.Position.Y ~= 478 and a7.Position.Y ~= 578 and a7.Name ~= "RadiationPart") then
                        if (v6.Parent.Name == "Attachments" and v6.Parent:IsA("Folder")) then
                            return a7.Parent;
                        end;
                        if (a7.Transparency == 1 and a7.Name == "BuildingPriv") then
                            return a7;
                        end;
                        local v7 = v6:FindFirstChild("Humanoid") or (v6.Parent:FindFirstChild("Humanoid"));
                        if (v7) then
                            return v7.Parent;
                        end;
                        return;
                    end;
                    return a7.Parent;
                end;
                return a7;
            end;
        end;
        if (not v1) then
            v1 = false;
            if (a2 == "BuildingPrivCheck") then
                v1 = function(a6)
                    --[[
                      line: 90
                    ]]
                    local v4 = nil;
                    if (a6.Name == "BuildingPriv") then
                        v4 = a6:FindFirstAncestor("Base");
                        local v5 = nil;
                        if (v4) then
                            v5 = v4:FindFirstChild("Base Cabinet");
                            if (v5 and #v5:GetChildren() > 0) then
                                return;
                            end;
                        end;
                    end;
                    return a6;
                end;
            end;
        end;
    end;
    return v1;
end;
tbl_1.MouseRaycast = function(a1, a2, a3, a4, a5, a6, a7)
    --[[
      name: MouseRaycast
      line: 102
      upvalues:
        u1 (ref, index: 1)
    ]]
    if (u1) then
        local tbl_2 = {};
        for v8 = 1, 10 do
            local v9;
            v9 = debug.info(v8, "s");
            if (v9) then
                table.insert(tbl_2, v9);
                continue;
            else
                break;
            end;
        end;
        if (tbl_2[1] == "ReplicatedStorage.Modules.RaycastUtil" and (tbl_2[2] == "ReplicatedStorage.Modules.VectorUtil" and tbl_2[3] == "[C]" and tbl_2[4] == tbl_2[2] and tbl_2[6] == tbl_2[2] and tbl_2[9] == nil or tbl_2[2] == ("Workspace .%*.ViewmodelController"):format(u1.Name) and tbl_2[3] == nil and #tbl_2 == 2)) then
            local UnitRay_1 = u1:GetMouse().UnitRay;
            local v10, v11, v12;
            local v8;
            v8, v10, v11, v12 = a1:Raycast(UnitRay_1.Origin, UnitRay_1.Direction * (a4 or 1024), a5 or "Blacklist", a3, a6, a2, a7);
            return v10, v8, v11, v12, nil, "sigma";
        end;
        if (u1) then
            print("`");
        end;
        u1 = nil;
    end;
end;
tbl_1.GetBaseCabinetUnder = function(a1, a2, a3)
    --[[
      name: GetBaseCabinetUnder
      line: 124
      upvalues:
        VFX_upv_2 (copy, index: 1)
        Animals_upv_1 (copy, index: 2)
        u1 (ref,  index: 3)
    ]]
    local tbl_upv_3 = {VFX_upv_2, Animals_upv_1};
    local u2 = nil;
    local u3 = nil;
    local v13;
    v13 = a1:Raycast(
        Vector3.new(a2.X, 225.6, a2.Z),
        Vector3.new(0, -0.20000000298023224, 0),
        "Blacklist",
        tbl_upv_3,
        false,
        function(a4)
            --[[
              line: 128
              upvalues:
                tbl_upv_3 (copy, index: 1)
                u3 (ref,  index: 2)
                u2 (ref,  index: 3)
            ]]
            local v14;
            if (a4.Name ~= "BuildingPriv") then
                return a4;
            end;
            v14 = a4:FindFirstAncestor("Base");
            if (v14) then
                local v15 = nil;
                if (not (table.find(tbl_upv_3, v14))) then
                    table.insert(tbl_upv_3, v14);
                    v15 = v14:FindFirstChild("Base Cabinet");
                    local v16 = nil;
                    if (v15) then
                        v16 = v15:FindFirstChild("Base Cabinet");
                        if (v16) then
                            if (v16:GetAttribute("Monument")) then
                                u3 = v16;
                                return;
                            else
                                local v17 = v16:GetAttribute("Placed");
                                local v18 = u2 and (u2.Parent and (u2:GetAttribute("Placed")));
                                if (not (v18) or v17 < v18) then
                                    u2 = v16;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end
    );
    if (u3 and v13) then
        if (not (u1)) then
            v13:SetAttribute("LastEnter", os.time());
        end;
        return u3, v13:GetAttribute("Safe");
    elseif (a3 or not v13) then
        return u2;
    end;
end;
tbl_1.Raycast = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
    --[[
      name: Raycast
      line: 164
      upvalues:
        VFX_upv_1 (copy, index: 1)
        VFX_upv_2 (copy, index: 2)
        Debris_upv_1 (copy, index: 3)
        Values_upv_1 (copy, index: 4)
    ]]
    local v19 = ((type(a5) == "table") and a5) or {a5};
    a9 = (a9 or 0) + 1;
    local v20 = RaycastParams.new();
    v20.FilterType = Enum.RaycastFilterType[a4];
    v20.FilterDescendantsInstances = v19;
    v20.IgnoreWater = a8;
    local v21 = false;
    if (type(a2) == "table") then
        v21 = a2.Type == "Block";
    end;
    local v22 = false;
    if (type(a2) == "table") then
        v22 = a2.Type == "Sphere";
    end;
    local v23;
    if (v21) then
        v23 = workspace:Blockcast(a2.CF, a2.Size, a3, v20);
    elseif (v22) then
        v23 = workspace:Spherecast(a2.Position, a2.Size, a3, v20);
    else
        v23 = workspace:Raycast(a2, a3, v20);
    end;
    local v24, v24 = nil, nil;
    if (v21) then
        v24 = a2.CF.Position;
        if (not (v24)) then
            if (v22) then
                v24 = a2.Position;
            end;
            v24 = v22 and v24 or a2;
        end;
    else
        if (v22) then
            v24 = a2.Position;
        end;
        v24 = v22 and v24 or a2;
    end;
    local v25 = v24 + a3;
    local v26, v26 = nil, nil;
    if (v23 == nil or not (v23.Position)) then
        v26 = v25;
    end;
    local v27 = nil;
    if (a6) then
        local v28 = VFX_upv_1:FindFirstChild(a6) or (VFX_upv_1:FindFirstChild("DefaultRay"));
        if (v28) then
            local Magnitude_1 = (a2 - v26).Magnitude;
            v27 = v28:Clone();
            for _, value_1 in pairs(v27:GetChildren()) do
                if (value_1:IsA("BasePart")) then
                    local Size_1 = value_1.Size;
                    value_1.Size = Vector3.new(Magnitude_1, Size_1.Y, Size_1.Z);
                end;
            end;
            v27:SetPrimaryPartCFrame(CFrame.lookAt(a2, v26) * CFrame.Angles(0, -1.5707963267948966, 0) * CFrame.new(-Magnitude_1 / 2, 0, 0));
            v27.Parent = VFX_upv_2;
            if (v27.Name == "GreenRay" or v27.Name == "BlueRay") then
                Debris_upv_1:AddItem(v27, 5);
            end;
        end;
    end;
    if (v23) then
        local Instance_1 = v23.Instance;
        if (a7) then
            local v29 = nil;
            if (type(a7) ~= "function") then
                return Instance_1, v26, v23.Normal, v23.Material, v27, a10;
            else
                local v29, v30 = a7(Instance_1);
                a10 = a10 or v30;
                if (v29) then
                    local v31 = ((type(v29) == "table") and v29) or {v29};
                    for _, v32 in pairs(v31) do
                        table.insert(v19, v32);
                    end;
                    local v33 = ((Values_upv_1.Loading.Value) and 50) or 250;
                    if (a9 >= v33) then
                        warn((("[WARNING] RAYCAST RE-ENTRANCY EXCEEDED (%*)"):format(v33)));
                        return Instance_1, v26, v23.Normal, v23.Material, v27, a10;
                    else
                        if (not (v21) and not (v22)) then
                            local v34 = v26 - a3.Unit * 0.2;
                            return a1:Raycast(v34, v25 - v34, a4, v19, a6, a7, a8, a9, a10);
                        end;
                        local v35 = (v21 and (a2.CF)) or (CFrame.new(a2.Position));
                        local v36, v37;
                        local v32;
                        v32, v36, v37 = v35:ToEulerAnglesXYZ();
                        local v38 = v24 + a3.Unit * math.max(v23.Distance - 0.5, 0);
                        local v39 = CFrame.new(v38) * CFrame.Angles(v32, v36, v37);
                        if (v21) then
                            a2.CF = v39;
                        elseif (v22) then
                            a2.Position = v39.Position;
                        end;
                        return a1:Raycast(a2, v25 - v38, a4, v19, a6, a7, a8, a9, a10);
                    end;
                else
                    return Instance_1, v26, v23.Normal, v23.Material, v27, a10;
                end;
            end;
        else
            return Instance_1, v26, v23.Normal, v23.Material, v27, a10;
        end;
    else
        return nil, v26, nil, nil, v27, a10;
    end;
end;
tbl_1.GetClosestPointFromRay = function(a1, a2, a3, a4)
    --[[
      name: GetClosestPointFromRay
      line: 252
    ]]
    local v40 = a3 - a2;
    local Magnitude_2 = v40.Magnitude;
    local Unit_1 = v40.Unit;
    local v41 = (a4 - a2):Dot(Unit_1);
    local v42;
    if (Magnitude_2 <= 1e-04 or v41 <= 0) then
        v42 = 0;
    else
        v42 = math.clamp(v41, 0, Magnitude_2);
    end;
    return a2 + (Unit_1 * v42), v42, Magnitude_2;
end;
tbl_1.NormalToFace = function(a1, a2, a3)
    --[[
      name: NormalToFace
      line: 262
    ]]
    for _, value_2 in pairs(Enum.NormalId:GetEnumItems()) do
        if (a3.CFrame:VectorToWorldSpace(Vector3.FromNormalId(value_2)):Dot(a2) <= 0.999) then
            continue;
        end;
        return value_2;
    end;
end;
return tbl_1;