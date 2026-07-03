-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local SoundService = game:GetService("SoundService");
ReplicatedStorage:WaitForChild("Remotes");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local LocalSounds = ReplicatedStorage:WaitForChild("LocalSounds");
local SoundRemotes = ReplicatedStorage:WaitForChild("SoundRemotes");
local Play = SoundRemotes:WaitForChild("Play");
local Footsteps = SoundRemotes:WaitForChild("Footsteps");
local SoundModule = require(Modules:WaitForChild("SoundModule"));
local _ = Players.LocalPlayer;

local function _(p1, p2, p3) -- Line: 31
    if not p2 or (type(p2) ~= "number" or not (p1 and p1.Parent)) then
        return;
    end;

    p1.PlaybackSpeed = p2;
    p1.RollOffMaxDistance = (p2 >= 1.48 and 140 or 80) * (p3 and 0.75 or 1);
end;

Footsteps.OnClientEvent:Connect(function(p4, p5, p6) -- Line: 38
    -- upvalues: SoundModule (copy), Players (copy)
    if not (p5 and p5.Parent) then
        return;
    end;

    local PrimaryPart = p5.PrimaryPart;

    if not PrimaryPart then
        return;
    end;

    for _, child in pairs(PrimaryPart:GetChildren()) do
        if child:IsA("Sound") then
            local v7 = string.match(child.Name, "^Footsteps(.+)$");

            if v7 then
                child.Volume = v7 == p4 and (SoundModule.FootstepMaxVolumes[v7] or (child:GetAttribute("MaxVolume") or 0)) or 0;

                if v7 == p4 then
                    local v8 = Players:GetPlayerFromCharacter(p5);
                    local v9;

                    if v8 then
                        v9 = v8:GetAttribute("Armor_SilentSteps");
                    else
                        v9 = false;
                    end;

                    if p6 and (type(p6) == "number" and child) then
                        if child.Parent then
                            child.PlaybackSpeed = p6;
                            child.RollOffMaxDistance = (p6 >= 1.48 and 140 or 80) * (v9 and 0.75 or 1);
                        end;
                    end;
                end;
            end;
        end;
    end;
end);
Play.OnClientEvent:Connect(function(p10, p11, ...) -- Line: 58
    -- upvalues: SoundModule (copy), LocalSounds (copy), SoundService (copy)
    local v12 = { ... };

    if p11 == "PlayDuplicate" then
        SoundModule:PlayDuplicateSound(p10, ...);

        return;
    end;

    if p11 == "ItemSound" then
        SoundModule:PlayItemSound(p10, v12[1]);

        return;
    end;

    if p11 == "LocalSound" then
        SoundService:PlayLocalSound(LocalSounds[p10]);

        return;
    end;

    local v13 = tick();

    while p10 and (not p10.Parent and tick() - v13 < 0.5) do
        task.wait(0.03333333333333333);
    end;

    if not (p10 and p10.Parent) then
        return;
    end;

    if p11 ~= "Play" then
        if p11 == "Stop" then
            p10:Stop();

            return;
        end;

        if p11 == "ChangeSpeed" then
            local v14 = v12[3];

            if v14 and (type(v14) == "number" and p10) then
                if not p10.Parent then
                    return;
                end;

                p10.PlaybackSpeed = v14;
                p10.RollOffMaxDistance = (v14 >= 1.48 and 140 or 80) * 1;
            end;
        end;

        return;
    end;

    p10.Volume = p10.Volume * (p10:GetAttribute("ClientReplicationMultiplier") or 1);
    local v15 = v12[3];

    if v15 and (type(v15) == "number" and (p10 and p10.Parent)) then
        p10.PlaybackSpeed = v15;
        p10.RollOffMaxDistance = (v15 >= 1.48 and 140 or 80) * 1;
    end;

    p10:Play();
end);