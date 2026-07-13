-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local _ = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local SoundService_upv_1 = game:GetService("SoundService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local LocalSounds_upv_1 = ReplicatedStorage_1:WaitForChild("LocalSounds");
local v1 = workspace:WaitForChild("VFX");
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local BenchInfo_upv_1 = require(Modules_1:WaitForChild("BenchInfo"));
local CurrentCamera_upv_1 = workspace.CurrentCamera;
local SoundRemotes_1 = ReplicatedStorage_1:WaitForChild("SoundRemotes");
local Footsteps_upv_1 = SoundRemotes_1:WaitForChild("Footsteps");
local Play_upv_1 = SoundRemotes_1:WaitForChild("Play");
local tbl_upv_1 = {};
tbl_upv_1.FootstepMaxVolumes = {};
tbl_upv_1.CustomSoundSkins = {CyberPop = 1.15};
local function GetLocalCustomSound_1(a1, a2, a3)
    --[[
      name: GetLocalCustomSound
      line: 51
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v1;
    if (a2 and tbl_upv_1.CustomSoundSkins[a2] and a1) then
        local v2 = nil;
        if (a1.Parent) then
            v2 = a1.Parent:FindFirstChild(("%*_%*"):format(a1.Name, a2));
            if (v2) then
                if (a3) then
                    v2.PlaybackSpeed = a3;
                end;
                v1 = v2;
            else
                v1 = a1;
            end;
        else
            v1 = a1;
        end;
    else
        v1 = a1;
    end;
    return v1;
end;
tbl_upv_1.PlaySound = function(a1, a2, a3, a4, a5)
    --[[
      name: PlaySound
      line: 65
      upvalues:
        tbl_upv_1 (copy, index: 1)
        Play_upv_1 (copy, index: 2)
    ]]
    if (a4) then
        a2.PlaybackSpeed = a4;
    end;
    local v3;
    if (a5 and tbl_upv_1.CustomSoundSkins[a5] and a2) then
        local v4 = nil;
        if (a2.Parent) then
            v4 = a2.Parent:FindFirstChild(("%*_%*"):format(a2.Name, a5));
            if (v4) then
                if (a4) then
                    v4.PlaybackSpeed = a4;
                end;
                v3 = v4;
            else
                v3 = a2;
            end;
        else
            v3 = a2;
        end;
    else
        v3 = a2;
    end;
    v3:Play();
    Play_upv_1:FireServer(a2, "Play" .. ((a3 and "Duplicate") or ""), a4);
end;
tbl_upv_1.StopSound = function(a1, a2)
    --[[
      name: StopSound
      line: 74
      upvalues:
        Play_upv_1 (copy, index: 1)
    ]]
    a2:Stop();
    Play_upv_1:FireServer(a2, "Stop");
end;
tbl_upv_1.ChangeSoundSpeed = function(a1, a2, a3)
    --[[
      name: ChangeSoundSpeed
      line: 79
      upvalues:
        Play_upv_1 (copy, index: 1)
    ]]
    a2.PlaybackSpeed = a3;
    Play_upv_1:FireServer(a2, "ChangeSpeed", a3);
end;
tbl_upv_1.ToggleFootstep = function(a1, a2, a3, a4)
    --[[
      name: ToggleFootstep
      line: 84
      upvalues:
        tbl_upv_1 (copy, index: 1)
        Footsteps_upv_1 (copy, index: 2)
    ]]
    local PrimaryPart_1 = a2.PrimaryPart;
    if (PrimaryPart_1) then
        local v5 = nil;
        local v6 = nil;
        for v7, value_1 in pairs(PrimaryPart_1:GetChildren()) do
            v6 = value_1.Name;
            if (v6:sub(1, 9) ~= "Footsteps" or not (value_1:IsA("Sound"))) then
                continue;
            end;
            if (value_1 ~= a3) then
                v5 = 0;
                value_1.Volume = v5;
                continue;
            end;
            v5 = tbl_upv_1.FootstepMaxVolumes[v6:sub(10)];
            if (v5) then
                value_1.Volume = v5;
                continue;
            end;
            v5 = a3:GetAttribute("MaxVolume");
            v5 = v5 or 0;
            value_1.Volume = v5;
        end;
        if (a3) then
            if (a4) then
                a3.PlaybackSpeed = a4;
            end;
            Footsteps_upv_1:FireServer(a3.Name:sub(10), a4);
        else
            Footsteps_upv_1:FireServer(nil);
        end;
    end;
end;
local function PlayDuplicateSound(a1, a2, a3, a4, a5, a6)
    --[[
      name: PlayDuplicateSound
      line: 102
      upvalues:
        PlayDuplicateSound (ref,  index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    if (a2) then
        local v7 = nil;
        if (a2.Parent) then
            v7 = a2.Name;
            local v8 = false;
            if (v7:sub(v7:len() - 4) == "Shoot") then
                v8 = v7 ~= "Shoot";
            end;
            local v9;
            if (a6 and tbl_upv_1.CustomSoundSkins[a6] and a2) then
                v9 = a2.Parent and a2.Parent:FindFirstChild(("%*_%*"):format(a2.Name, a6)) or a2;
            else
                v9 = a2;
            end;
            if (v8 == false and not (v9.IsPlaying)) then
                v9:Play();
                return;
            end;
            local u1 = v9:Clone();
            u1:Stop();
            u1.Parent = v9.Parent;
            if (v8) then
                a1:ReverbSound(u1, 600, 1000);
            end;
            if (u1.PlayOnRemove) then
                u1:Destroy();
            else
                u1:Play();
                task.defer(
                    function()
                        --[[
                          line: 157
                          upvalues:
                            u1 (copy, index: 1)
                        ]]
                        if (not u1 or not u1.Parent) then
                            return;
                        end;
                        if (u1.IsPlaying) then
                            u1.Ended:Wait();
                        end;
                        u1:Destroy();
                    end
                );
            end;
            return;
        end;
    end;
    if (not a3 or not a3.Parent) then
        return;
    end;
    if (a4) then
        if (not (PlayDuplicateSound) or not (PlayDuplicateSound.Parent)) then
            PlayDuplicateSound = workspace:FindFirstChild("CameraRoot");
        end;
        local v10 = nil;
        if (PlayDuplicateSound) then
            local u2 = Instance.new("Attachment");
            u2.Parent = PlayDuplicateSound.PrimaryPart;
            u2.WorldCFrame = CFrame.new(a4);
            local u3 = a3:Clone();
            u3.Parent = u2;
            v10 = u3.Name;
            if (v10:sub(v10:len() - 4) == "Shoot" and v10 ~= "Shoot") then
                a1:ReverbSound(u3, 600, 1000);
            end;
            u3:Play();
            task.defer(
                function()
                    --[[
                      line: 121
                      upvalues:
                        u2 (copy, index: 1)
                        u3 (copy, index: 2)
                    ]]
                    if (not u2 or not u2.Parent) then
                        return;
                    end;
                    if (u3.IsPlaying) then
                        u3.Ended:Wait();
                    end;
                    u2:Destroy();
                end
            );
        end;
    end;
end;
tbl_upv_1.PlayDuplicateSound = PlayDuplicateSound;
tbl_upv_1.ReverbSound = function(a1, a2, a3, a4)
    --[[
      name: ReverbSound
      line: 211
      upvalues:
        CurrentCamera_upv_1 (copy, index: 1)
        NumberUtil_upv_1 (copy, index: 2)
        SoundService_upv_1 (copy, index: 3)
    ]]
    local v11, v12 = NumberUtil_upv_1:IsWithin(a2.Parent.Position, CurrentCamera_upv_1.CFrame.Position, a3);
    if (not (v11)) then
        a2.PlayOnRemove = false;
        a2.Volume = a2.Volume * 8;
        local v13 = math.min((math.sqrt(v12) - a3) / (a4 - a3), 1);
        local v14 = SoundService_upv_1.GunshotReverb:Clone();
        local Chorus_1 = v14.Chorus;
        Chorus_1.Mix = Chorus_1.Mix * v13;
        v14.Parent = a2;
        a2.SoundGroup = v14;
    end;
end;
tbl_upv_1.PlayItemSound = function(a1, a2, a3)
    --[[
      name: PlayItemSound
      line: 230
      upvalues:
        Items_upv_1 (copy, index: 1)
        LocalSounds_upv_1 (copy, index: 2)
        SoundService_upv_1 (copy, index: 3)
    ]]
    if (a2) then
        local v15 = ((type(a2) == "number") and (Items_upv_1[a2])) or a2;
        local v16 = nil;
        if (v15) then
            v16 = v15.Sounds;
            local v17 = nil;
            if (v16) then
                v17 = v16[a3];
            end;
            if (v16 and v17) then
                local v18 = LocalSounds_upv_1[v17];
                local PlaybackSpeed_1 = v18.PlaybackSpeed;
                v18.PlaybackSpeed = v18.PlaybackSpeed + (math.random(-20, 20) / 400);
                SoundService_upv_1:PlayLocalSound(v18);
                v18.PlaybackSpeed = PlaybackSpeed_1;
            end;
        end;
    end;
end;
tbl_upv_1.PlayBenchSound = function(a1, a2, a3, a4)
    --[[
      name: PlayBenchSound
      line: 245
      upvalues:
        BenchInfo_upv_1 (copy, index: 1)
        LocalSounds_upv_1 (copy, index: 2)
        SoundService_upv_1 (copy, index: 3)
    ]]
    local v19 = BenchInfo_upv_1[a2];
    local v20 = nil;
    if (v19) then
        v20 = v19.Sounds;
        local v21 = nil;
        if (v20) then
            local v22 = "%*%*";
            local v23;
            if ((a4) and a4 ~= "Default") then
                v23 = a4;
            else
                v23 = "";
            end;
            v21 = v20[v22:format(a3, v23)];
            if (v21) then
                local v24 = LocalSounds_upv_1.BenchSounds[v21];
                local PlaybackSpeed_2 = v24.PlaybackSpeed;
                v24.PlaybackSpeed = v24.PlaybackSpeed + (math.random(-20, 20) / 400);
                SoundService_upv_1:PlayLocalSound(v24);
                v24.PlaybackSpeed = PlaybackSpeed_2;
            end;
        end;
    end;
end;
return tbl_upv_1;