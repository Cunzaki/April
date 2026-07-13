-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_upv_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local RunService_1 = game:GetService("RunService");
local CollectionService_1 = game:GetService("CollectionService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local _ = ReplicatedStorage_1:WaitForChild("Remotes");
local VFX_upv_1 = workspace:WaitForChild("VFX");
local VFXModule_upv_1 = require(Modules_1:WaitForChild("VFXModule"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local RaycastUtil_upv_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local ClientSignals_1 = ReplicatedStorage_1:WaitForChild("ClientSignals");
local VFX_2 = ClientSignals_1:WaitForChild("VFX");
local VFXOrdered_1 = ClientSignals_1:WaitForChild("VFXOrdered");
local LocalPlayer_upv_1 = Players_upv_1.LocalPlayer;
local u1 = RaycastUtil_upv_1:FilterFunction("HitIgnore");
local function v1(a1, ...)
    --[[
      line: 71
      upvalues:
        VFXModule_upv_1 (copy, index: 1)
    ]]
    local tbl_1 = {...};
    local v2 = nil;
    if (a1 ~= "CreateProjectile") then
        v2 = VFXModule_upv_1[a1];
        if (v2) then
            v2(VFXModule_upv_1, ...);
        end;
    else
        for _, value_1 in pairs(tbl_1[1]) do
            VFXModule_upv_1:CreateProjectile(value_1);
        end;
    end;
end;
local function v3(a1)
    --[[
      line: 86
      upvalues:
        LocalPlayer_upv_1 (copy, index: 1)
    ]]
    if (not a1:IsDescendantOf(LocalPlayer_upv_1.Character)) then
        return;
    end;
    for _, value_2 in a1:GetChildren() do
        if (value_2:IsA("ParticleEmitter")) then
            value_2.Enabled = false;
        end;
    end;
end;
for v17, value_3 in CollectionService_1:GetTagged("HideEffects") do
    v3(value_3);
end;
CollectionService_1:GetInstanceAddedSignal("HideEffects"):Connect(v3);
VFX_2.OnClientEvent:Connect(v1);
VFXOrdered_1.OnClientEvent:Connect(v1);
RunService_1.Heartbeat:Connect(
    function()
        --[[
          line: 106
          upvalues:
            VFXModule_upv_1 (copy, index: 1)
            Players_upv_1 (copy, index: 2)
            NumberUtil_upv_1 (copy, index: 3)
            RaycastUtil_upv_1 (copy, index: 4)
            VFX_upv_1 (copy, index: 5)
            u1 (copy, index: 6)
        ]]
        local Lasers_1 = VFXModule_upv_1.Lasers;
        local v4 = nil;
        for n_1 = #Lasers_1, 1, -1 do
            local v5;
            v5 = Lasers_1[n_1];
            if (not (v5) or not (v5.Parent) or not (v5:FindFirstChild("Laser")) or not (v5.Laser.Enabled)) then
                table.remove(Lasers_1, n_1);
                continue;
            end;
            local WorldCFrame_1 = v5.Start.WorldCFrame;
            v4 = false;
            local v6;
            v6 = Players_upv_1.LocalPlayer;
            if (v6) then
                local v7;
                v7 = v6.Character;
                if (v7) then
                    local v8;
                    v8 = v7.PrimaryPart;
                    if (v8) then
                        v4 = not NumberUtil_upv_1:IsWithin(v8.Position, WorldCFrame_1.Position, 1000);
                    end;
                end;
            end;
            if (v4) then
                v5.End.WorldPosition = WorldCFrame_1.Position;
            else
                local _, v9 = RaycastUtil_upv_1:Raycast(WorldCFrame_1.Position, WorldCFrame_1.RightVector * 1000, "Blacklist", {VFX_upv_1, v5.Parent}, nil, u1);
                v5.End.WorldPosition = v9;
            end;
        end;
    end
);
local function v10(a1)
    --[[
      line: 36
    ]]
    local v11 = nil;
    local v12 = nil;
    v12 = v12;
    while (true) do
        if (not (v12)) then
            v12 = a1:FindFirstChild("LeftLowerArm");
        end;
        v11 = v11 or (a1:FindFirstChild("RightLowerArm"));
        if (not (v12)) then
            task.wait(0.1);
            continue;
        end;
        if (v11) then
            break;
        end;
        task.wait(0.1);
    end;
    if (v11) then
        local RightWristRigAttachment_1 = v11:WaitForChild("RightWristRigAttachment");
        if (RightWristRigAttachment_1) then
            RightWristRigAttachment_1.ChildAdded:Connect(
                function(a2)
                    --[[
                      line: 51
                    ]]
                    if (not a2:IsA("ParticleEmitter")) then
                        return;
                    end;
                    a2.Enabled = false;
                end
            );
        end;
    end;
    local LeftLowerArm_1 = a1:WaitForChild("LeftLowerArm");
    if (LeftLowerArm_1) then
        local LeftWristRigAttachment_1 = LeftLowerArm_1:WaitForChild("LeftWristRigAttachment");
        if (not LeftWristRigAttachment_1) then
            return;
        end;
        LeftWristRigAttachment_1.ChildAdded:Connect(
            function(a3)
                --[[
                  line: 62
                ]]
                if (not a3:IsA("ParticleEmitter")) then
                    return;
                end;
                a3.Enabled = false;
            end
        );
    end;
end;
LocalPlayer_upv_1.CharacterAdded:Connect(v10);
local Character_1 = LocalPlayer_upv_1.Character;
if (Character_1) then
    v10(Character_1);
end;
local v18 = task.wait(15);
local Lasers_2 = VFXModule_upv_1.Lasers;
local v13 = nil;
local v19 = nil;
local v20 = nil;
local v14 = nil;
local v15 = nil;
local v16 = nil;
for v21, value_4 in Players_upv_1:GetPlayers() do
    if (value_4 == LocalPlayer_upv_1 or not (value_4) or not (value_4.Parent)) then
        continue;
    end;
    v13 = value_4.Character;
    if (not (v13)) then
        continue;
    end;
    v14 = nil;
    v15 = nil;
    for v22, value_5 in v13:GetChildren() do
        if (not (value_5:IsA("Model")) or value_5.Name == "HolsterModel") then
            continue;
        end;
        v14 = value_5:FindFirstChild("Attachments");
        if (not (v14)) then
            continue;
        end;
        v15 = v14:FindFirstChild("Salvaged Lasersight") or (v14:FindFirstChild("Military Lasersight"));
        if (not (v15)) then
            continue;
        end;
        v16 = v15:FindFirstChild("Laser");
        if (not (v16)) then
            continue;
        end;
        if (not (table.find(Lasers_2, v16))) then
            table.insert(Lasers_2, v16);
        end;
    end;
end;