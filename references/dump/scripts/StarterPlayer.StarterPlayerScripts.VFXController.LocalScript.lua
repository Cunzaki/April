-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
ReplicatedStorage:WaitForChild("Remotes");
local VFX = workspace:WaitForChild("VFX");
local VFXModule = require(Modules:WaitForChild("VFXModule"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local RaycastUtil = require(Modules:WaitForChild("RaycastUtil"));
local ClientSignals = ReplicatedStorage:WaitForChild("ClientSignals");
local VFX2 = ClientSignals:WaitForChild("VFX");
local VFXOrdered = ClientSignals:WaitForChild("VFXOrdered");
local LocalPlayer = Players.LocalPlayer;
local u1 = RaycastUtil:FilterFunction("HitIgnore");

local function v3(p2) -- Line: 86
    -- upvalues: LocalPlayer (copy)
    if not p2:IsDescendantOf(LocalPlayer.Character) then
        return;
    end;

    for _, child in p2:GetChildren() do
        if child:IsA("ParticleEmitter") then
            child.Enabled = false;
        end;
    end;
end;

local function v11(p4) -- Line: 36
    local v5 = nil;
    local v6 = nil;

    while true do
        v5 = v5 or p4:FindFirstChild("LeftLowerArm");
        v6 = v6 or p4:FindFirstChild("RightLowerArm");

        if v5 and v6 then
            break;
        end;

        task.wait(0.1);
    end;

    local v7 = v6 and v6:WaitForChild("RightWristRigAttachment");

    if v7 then
        v7.ChildAdded:Connect(function(p8) -- Line: 51
            if p8:IsA("ParticleEmitter") then
                p8.Enabled = false;
            end;
        end);
    end;

    local LeftLowerArm = p4:WaitForChild("LeftLowerArm");
    local v9 = LeftLowerArm and LeftLowerArm:WaitForChild("LeftWristRigAttachment");

    if v9 then
        v9.ChildAdded:Connect(function(p10) -- Line: 62
            if p10:IsA("ParticleEmitter") then
                p10.Enabled = false;
            end;
        end);
    end;
end;

local function v15(p12, ...) -- Line: 71
    -- upvalues: VFXModule (copy)
    local v13 = { ... };

    if p12 == "CreateProjectile" then
        for _, v in pairs(v13[1]) do
            VFXModule:CreateProjectile(v);
        end;

        return;
    end;

    local v14 = VFXModule[p12];

    if v14 then
        v14(VFXModule, ...);
    end;
end;

for _, v in CollectionService:GetTagged("HideEffects") do
    v3(v);
end;

CollectionService:GetInstanceAddedSignal("HideEffects"):Connect(v3);
VFX2.OnClientEvent:Connect(v15);
VFXOrdered.OnClientEvent:Connect(v15);
RunService.Heartbeat:Connect(function() -- Line: 106
    -- upvalues: VFXModule (copy), Players (copy), NumberUtil (copy), RaycastUtil (copy), VFX (copy), u1 (copy)
    local Lasers = VFXModule.Lasers;

    for i = #Lasers, 1, -1 do
        local v16 = Lasers[i];

        if v16 and (v16.Parent and (v16:FindFirstChild("Laser") and v16.Laser.Enabled)) then
            local WorldCFrame = v16.Start.WorldCFrame;
            local v17 = false;
            local LocalPlayer2 = Players.LocalPlayer;

            if LocalPlayer2 then
                local Character = LocalPlayer2.Character;

                if Character then
                    local PrimaryPart = Character.PrimaryPart;

                    if PrimaryPart then
                        v17 = not NumberUtil:IsWithin(PrimaryPart.Position, WorldCFrame.Position, 1000);
                    end;
                end;
            end;

            if v17 then
                v16.End.WorldPosition = WorldCFrame.Position;
            else
                local _, v18 = RaycastUtil:Raycast(WorldCFrame.Position, WorldCFrame.RightVector * 1000, "Blacklist", { VFX, v16.Parent }, nil, u1);
                v16.End.WorldPosition = v18;
            end;
        else
            table.remove(Lasers, i);
        end;
    end;
end);
LocalPlayer.CharacterAdded:Connect(v11);
local Character = LocalPlayer.Character;

if Character then
    v11(Character);
end;

while true do
    task.wait(15);
    local Lasers = VFXModule.Lasers;

    for _, v in Players:GetPlayers() do
        if v ~= LocalPlayer and (v and v.Parent) then
            local Character2 = v.Character;

            if Character2 then
                for _, child in Character2:GetChildren() do
                    if child:IsA("Model") and child.Name ~= "HolsterModel" then
                        local Attachments = child:FindFirstChild("Attachments");

                        if Attachments then
                            local v19 = Attachments:FindFirstChild("Salvaged Lasersight") or Attachments:FindFirstChild("Military Lasersight");

                            if v19 then
                                local Laser = v19:FindFirstChild("Laser");

                                if Laser and not table.find(Lasers, Laser) then
                                    table.insert(Lasers, Laser);
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;