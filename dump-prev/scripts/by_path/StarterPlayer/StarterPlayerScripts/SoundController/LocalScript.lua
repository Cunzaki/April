-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_upv_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local SoundService_upv_1 = game:GetService("SoundService");
local _ = ReplicatedStorage_1:WaitForChild("Remotes");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local LocalSounds_upv_1 = ReplicatedStorage_1:WaitForChild("LocalSounds");
local SoundRemotes_1 = ReplicatedStorage_1:WaitForChild("SoundRemotes");
local Play_1 = SoundRemotes_1:WaitForChild("Play");
local Footsteps_1 = SoundRemotes_1:WaitForChild("Footsteps");
local SoundModule_upv_1 = require(Modules_1:WaitForChild("SoundModule"));
Footsteps_1.OnClientEvent:Connect(
    function(a1, a2, a3)
        --[[
          line: 38
          upvalues:
            SoundModule_upv_1 (copy, index: 1)
            Players_upv_1 (copy, index: 2)
        ]]
        if (a2) then
            local v1;
            if (not a2.Parent) then
                return;
            end;
            v1 = a2.PrimaryPart;
            if (v1) then
                local _, v2 = nil, nil;
                local v3 = nil;
                local value_1 = nil;
                local v4 = nil;
                local v5 = nil;
                local v6 = nil;
                for v7, value_1 in pairs(v1:GetChildren()) do
                    v3 = value_1:IsA("Sound");
                    if (not (v3)) then
                        continue;
                    end;
                    v3 = string.match(value_1.Name, "^Footsteps(.+)$");
                    if (not (v3)) then
                        continue;
                    end;
                    if (v3 ~= a1) then
                        v4 = 0;
                    else
                        v4 = SoundModule_upv_1.FootstepMaxVolumes[v3];
                        if (not (v4)) then
                            v4 = value_1:GetAttribute("MaxVolume");
                            v4 = v4 or 0;
                        end;
                    end;
                    value_1.Volume = v4;
                    if (v3 ~= a1) then
                        continue;
                    end;
                    v4 = Players_upv_1:GetPlayerFromCharacter(a2);
                    v2 = false;
                    if (v4) then
                        v2 = v4:GetAttribute("Armor_SilentSteps");
                    end;
                    if (not (a3) or type(a3) ~= "number" or not (value_1)) then
                        continue;
                    end;
                    if (value_1.Parent) then
                        value_1.PlaybackSpeed = a3;
                        value_1.RollOffMaxDistance = (((a3 < 1.48) and 80) or 140) * ((v2 and 0.75) or 1);
                    end;
                end;
            end;
        end;
    end
);
Play_1.OnClientEvent:Connect(
    function(a1, a2, ...)
        --[[
          line: 58
          upvalues:
            SoundModule_upv_1 (copy, index: 1)
            LocalSounds_upv_1 (copy, index: 2)
            SoundService_upv_1 (copy, index: 3)
        ]]
        local tbl_1 = {...};
        if (a2 == "PlayDuplicate") then
            SoundModule_upv_1:PlayDuplicateSound(a1, ...);
        elseif (a2 == "ItemSound") then
            SoundModule_upv_1:PlayItemSound(a1, tbl_1[1]);
        elseif (a2 ~= "LocalSound") then
            local time_1 = tick();
            while (a1 and not a1.Parent and tick() - time_1 < 0.5) do
                task.wait(0.03333333333333333);
            end;
            if (a1 and a1.Parent) then
                local v5 = nil;
                if (a2 == "Play") then
                    a1.Volume = a1.Volume * (a1:GetAttribute("ClientReplicationMultiplier") or 1);
                    v5 = tbl_1[3];
                    if (v5 and type(v5) == "number" and a1 and a1.Parent) then
                        a1.PlaybackSpeed = v5;
                        a1.RollOffMaxDistance = (((v5 < 1.48) and 80) or 140) * 1;
                    end;
                    a1:Play();
                elseif (a2 == "Stop") then
                    a1:Stop();
                elseif (a2 == "ChangeSpeed") then
                    v5 = tbl_1[3];
                    if (v5 and type(v5) == "number" and a1) then
                        if (not a1.Parent) then
                            return;
                        end;
                        a1.PlaybackSpeed = v5;
                        a1.RollOffMaxDistance = (((v5 < 1.48) and 80) or 140) * 1;
                    end;
                end;
                return;
            end;
        else
            SoundService_upv_1:PlayLocalSound(LocalSounds_upv_1[a1]);
        end;
    end
);