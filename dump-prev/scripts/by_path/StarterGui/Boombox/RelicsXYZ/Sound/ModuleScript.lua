-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local _ = game:GetService("Players");
local MarketplaceService_upv_1 = game:GetService("MarketplaceService");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local SoundService_1 = game:GetService("SoundService");
local Sound_upv_1 = ReplicatedStorage_1:WaitForChild("Sound");
local RelicsServerSoundAdded_1 = ReplicatedStorage_1:WaitForChild("RelicsServerSoundAdded");
local v1 = require(script.Parent.Constants).GetOptions();
local u1 = Sound_upv_1:InvokeServer("MaxVolume");
local u2 = Sound_upv_1:InvokeServer("StepVolume");
local u3 = Sound_upv_1:InvokeServer("DefaultVolume");
local u4 = Sound_upv_1:InvokeServer("UgcItemId");
local Jukebox_upv_1 = SoundService_1:WaitForChild("Jukebox");
local Main_upv_1 = script.Parent.Parent:WaitForChild("Main");
local VolumeGreen_upv_1 = Main_upv_1.PlayingFrame.Volume.VolumeBar.VolumeGreen;
VolumeGreen_upv_1.Size = UDim2.new(u3 / u1, 0, 1, 0);
local Tracks_upv_1 = require(script.Parent.Tracks);
local tbl_upv_1 = {};
local u6 = nil;
local u7 = v1.defaultSoundMode;
local u8 = Instance.new("BindableEvent");
local u9 = Instance.new("BindableEvent");
local u10 = Instance.new("BindableEvent");
local u11 = Instance.new("BindableEvent");
local u12 = Instance.new("BindableEvent");
local u13 = Instance.new("BindableEvent");
local function u5()
    --[[
      name: getOrCreateSound
      line: 63
      upvalues:
        u5 (ref,  index: 1)
        Jukebox_upv_1 (copy, index: 2)
        Main_upv_1 (copy, index: 3)
        u12 (copy, index: 4)
    ]]
    if (not u5) then
        u5 = Instance.new("Sound");
        u5.SoundGroup = Jukebox_upv_1;
        u5.RollOffMaxDistance = 60;
        u5.RollOffMinDistance = 0;
        u5.Parent = Main_upv_1;
        u5.Ended:Connect(
            function()
                --[[
                  line: 74
                  upvalues:
                    u12 (copy, index: 1)
                    u5 (ref,  index: 2)
                ]]
                u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
            end
        );
    end;
    return u5;
end;
tbl_upv_1.ToggleSoundMode = function(a1)
    --[[
      name: ToggleSoundMode
      line: 81
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Sound_upv_1 (copy, index: 3)
        u6 (ref,  index: 4)
        Jukebox_upv_1 (copy, index: 5)
        Main_upv_1 (copy, index: 6)
        u12 (copy, index: 7)
        u13 (copy, index: 8)
    ]]
    u7 = a1;
    local v2 = u5 and (u5.IsPaused);
    local v3 = Sound_upv_1:InvokeServer("IsPlaying", nil, shared.LastJukebox);
    local v6 = nil;
    if (a1 == "global") then
        local v4 = nil;
        if (u5) then
            v6 = u5.SoundId:match("rbxassetid://(%d+)");
            v4 = u5.TimePosition;
            u5:Stop();
            u5:Destroy();
            u5 = nil;
            if (v4 > 0) then
                Sound_upv_1:InvokeServer("Play", v6, shared.LastJukebox);
                Sound_upv_1:InvokeServer("SetPosition", v4, shared.LastJukebox);
                if (v2) then
                    Sound_upv_1:InvokeServer("Pause", nil, shared.LastJukebox);
                end;
            end;
        end;
    end;
    if (a1 == "local") then
        v6 = u6.TimePosition;
        local v7 = Sound_upv_1:InvokeServer("Stop", nil, shared.LastJukebox);
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        u5 = nil;
        if (v6 > 0) then
            u5.SoundId = "rbxassetid://" .. v7;
            u5.TimePosition = v6;
            if (v3) then
                u5:Play();
            end;
        end;
    end;
    u13:Fire(a1);
end;
RelicsServerSoundAdded_1.OnClientEvent:Connect(
    function(a1)
        --[[
          line: 123
          upvalues:
            u6 (ref,  index: 1)
            u12 (copy, index: 2)
        ]]
        u6 = a1;
        if (not u6 or not u6.Parent) then
            return;
        end;
        u6.Ended:Connect(
            function()
                --[[
                  line: 126
                  upvalues:
                    u12 (copy, index: 1)
                    u6 (ref,  index: 2)
                ]]
                u12:Fire(u6.SoundId:match("rbxassetid://(%d+)"));
            end
        );
    end
);
u5 = function(a1)
    --[[
      name: PlayBySoundId
      line: 131
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        u8 (copy, index: 6)
        Sound_upv_1 (copy, index: 7)
    ]]
    if (u7 ~= "local") then
        Sound_upv_1:InvokeServer("Play", a1, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v8 = nil;
        if (v8.Playing) then
            v8:Stop();
        end;
        v8.SoundId = "rbxassetid://" .. tostring(a1);
        v8:Play();
    end;
    u8:Fire(a1);
end;
tbl_upv_1.PlayBySoundId = u5;
u5 = function(a1)
    --[[
      name: Play
      line: 149
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        Sound_upv_1 (copy, index: 6)
        u8 (copy, index: 7)
    ]]
    local id_1 = a1.id;
    if (u7 ~= "local") then
        Sound_upv_1:InvokeServer("Play", id_1, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v9 = nil;
        if (v9.Playing) then
            v9:Stop();
        end;
        v9.SoundId = "rbxassetid://" .. tostring(id_1);
        v9:Play();
    end;
    u8:Fire(id_1);
end;
tbl_upv_1.Play = u5;
u5 = function()
    --[[
      name: Stop
      line: 169
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        Sound_upv_1 (copy, index: 6)
        u11 (copy, index: 7)
    ]]
    local v10;
    if (u7 ~= "local") then
        v10 = Sound_upv_1:InvokeServer("Stop", nil, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v11 = nil;
        v10 = v11.SoundId:match("rbxassetid://(%d+)");
        v11:Stop();
    end;
    u11:Fire(v10);
end;
tbl_upv_1.Stop = u5;
u5 = function()
    --[[
      name: Pause
      line: 186
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        Sound_upv_1 (copy, index: 6)
        u9 (copy, index: 7)
    ]]
    local v12;
    if (u7 ~= "local") then
        v12 = Sound_upv_1:InvokeServer("Pause", nil, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v13 = nil;
        v12 = v13.SoundId:match("rbxassetid://(%d+)");
        v13:Pause();
    end;
    u9:Fire(v12);
end;
tbl_upv_1.Pause = u5;
u5 = function()
    --[[
      name: Resume
      line: 198
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        Sound_upv_1 (copy, index: 6)
        u10 (copy, index: 7)
    ]]
    local v14;
    if (u7 ~= "local") then
        v14 = Sound_upv_1:InvokeServer("Resume", nil, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v15 = nil;
        v14 = v15.SoundId:match("rbxassetid://(%d+)");
        v15:Resume();
    end;
    u10:Fire(v14);
end;
tbl_upv_1.Resume = u5;
u5 = function()
    --[[
      name: VolumeUp
      line: 212
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        u2 (copy, index: 6)
        u1 (copy, index: 7)
        Sound_upv_1 (copy, index: 8)
        VolumeGreen_upv_1 (copy, index: 9)
        tbl_upv_1 (copy, index: 10)
    ]]
    if (u7 ~= "local") then
        Sound_upv_1:InvokeServer("Up", nil, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v16 = nil;
        v16.Volume = math.clamp(v16.Volume + u2, 0, u1);
    end;
    VolumeGreen_upv_1.Size = UDim2.new(tbl_upv_1.Volume() / tbl_upv_1.MaxVolume(), 0, 1, 0);
end;
tbl_upv_1.VolumeUp = u5;
u5 = function()
    --[[
      name: VolumeDown
      line: 222
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        u2 (copy, index: 6)
        u1 (copy, index: 7)
        Sound_upv_1 (copy, index: 8)
        VolumeGreen_upv_1 (copy, index: 9)
        tbl_upv_1 (copy, index: 10)
    ]]
    if (u7 ~= "local") then
        Sound_upv_1:InvokeServer("Down", nil, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v17 = nil;
        v17.Volume = math.clamp(v17.Volume - u2, 0, u1);
    end;
    VolumeGreen_upv_1.Size = UDim2.new(tbl_upv_1.Volume() / tbl_upv_1.MaxVolume(), 0, 1, 0);
end;
tbl_upv_1.VolumeDown = u5;
u5 = function(a1)
    --[[
      name: SetVolume
      line: 232
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        Sound_upv_1 (copy, index: 6)
        VolumeGreen_upv_1 (copy, index: 7)
        tbl_upv_1 (copy, index: 8)
    ]]
    if (u7 ~= "local") then
        Sound_upv_1:InvokeServer("SetVolume", a1, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v18;
        v18.Volume = math.clamp(a1, 0, 1);
    end;
    VolumeGreen_upv_1.Size = UDim2.new(tbl_upv_1.Volume() / tbl_upv_1.MaxVolume(), 0, 1, 0);
end;
tbl_upv_1.SetVolume = u5;
u5 = function()
    --[[
      name: GetActive
      line: 242
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        Sound_upv_1 (copy, index: 6)
        Tracks_upv_1 (copy, index: 7)
    ]]
    local v19;
    if (u7 ~= "local") then
        v19 = Sound_upv_1:InvokeServer("Playing", nil, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v20 = nil;
        v19 = (not (v20.IsPlaying)) or (v20.SoundId:match("rbxassetid://(%d+)"));
    end;
    if (v19) then
        return Tracks_upv_1.GetTrackById(v19);
    else
        local tbl_2 = {};
        tbl_2.id = v19;
        return tbl_2;
    end;
end;
tbl_upv_1.GetActive = u5;
u5 = function()
    --[[
      name: Playing
      line: 263
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        Sound_upv_1 (copy, index: 6)
        Tracks_upv_1 (copy, index: 7)
    ]]
    local v21;
    if (u7 ~= "local") then
        v21 = Sound_upv_1:InvokeServer("Playing", nil, shared.LastJukebox);
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v22 = nil;
        v21 = (not (v22.IsPlaying)) or (v22.SoundId:match("rbxassetid://(%d+)"));
    end;
    if (v21) then
        return Tracks_upv_1.GetTrackById(v21);
    end;
    return nil;
end;
tbl_upv_1.Playing = u5;
local function getSoundProperty_upv_1(a1)
    --[[
      name: getSoundProperty
      line: 28
      upvalues:
        Sound_upv_1 (copy, index: 1)
    ]]
    return Sound_upv_1:InvokeServer(a1, nil, shared.LastJukebox);
end;
u5 = function()
    --[[
      name: IsPlaying
      line: 281
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        getSoundProperty_upv_1 (copy, index: 6)
    ]]
    if (u7 ~= "local") then
        return getSoundProperty_upv_1("IsPlaying");
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v23 = nil;
        return v23.Playing;
    end;
end;
tbl_upv_1.IsPlaying = u5;
u5 = function()
    --[[
      name: IsPaused
      line: 290
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        getSoundProperty_upv_1 (copy, index: 6)
    ]]
    if (u7 ~= "local") then
        return getSoundProperty_upv_1("IsPaused");
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v24 = nil;
        return v24.IsPaused;
    end;
end;
tbl_upv_1.IsPaused = u5;
u5 = function()
    --[[
      name: Volume
      line: 299
      upvalues:
        u7 (ref,  index: 1)
        u5 (ref,  index: 2)
        Jukebox_upv_1 (copy, index: 3)
        Main_upv_1 (copy, index: 4)
        u12 (copy, index: 5)
        getSoundProperty_upv_1 (copy, index: 6)
    ]]
    if (u7 ~= "local") then
        return getSoundProperty_upv_1("Volume");
    else
        if (not (u5)) then
            u5 = Instance.new("Sound");
            u5.SoundGroup = Jukebox_upv_1;
            u5.RollOffMaxDistance = 60;
            u5.RollOffMinDistance = 0;
            u5.Parent = Main_upv_1;
            u5.Ended:Connect(
                function()
                    --[[
                      line: 74
                      upvalues:
                        u12 (copy, index: 1)
                        u5 (ref,  index: 2)
                    ]]
                    u12:Fire(u5.SoundId:match("rbxassetid://(%d+)"));
                end
            );
        end;
        local v25 = nil;
        return v25.Volume;
    end;
end;
tbl_upv_1.Volume = u5;
local function ValidateSong_upv_1(a1)
    --[[
      name: ValidateSong
      line: 35
      upvalues:
        MarketplaceService_upv_1 (copy, index: 1)
    ]]
    if (a1) then
        local success_1;
        if (tonumber(a1)) then
            local success_1, v26 = pcall(
                function()
                    --[[
                      line: 38
                      upvalues:
                        MarketplaceService_upv_1 (copy, index: 1)
                        a1 (copy, index: 2)
                    ]]
                    return MarketplaceService_upv_1:GetProductInfo(a1);
                end
            );
            if (success_1 and v26 and v26.AssetTypeId == 3 and v26.Name ~= "(Removed for copyright)") then
                return true;
            end;
            return false;
        end;
    end;
    return false;
end;
tbl_upv_1.Search = function(a1)
    --[[
      name: Search
      line: 308
      upvalues:
        ValidateSong_upv_1 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    if (not a1) then
        return;
    end;
    if (ValidateSong_upv_1(a1)) then
        tbl_upv_1.PlayBySoundId(a1);
        return {tbl_upv_1.GetActive()};
    end;
end;
tbl_upv_1.DefaultVolume = function()
    --[[
      name: DefaultVolume
      line: 323
      upvalues:
        u3 (copy, index: 1)
    ]]
    return u3;
end;
tbl_upv_1.MaxVolume = function()
    --[[
      name: MaxVolume
      line: 327
      upvalues:
        u1 (copy, index: 1)
    ]]
    return u1;
end;
tbl_upv_1.UgcItemId = function()
    --[[
      name: UgcItemId
      line: 331
      upvalues:
        u4 (copy, index: 1)
    ]]
    return u4;
end;
tbl_upv_1.SoundMode = function()
    --[[
      name: SoundMode
      line: 335
      upvalues:
        u7 (ref, index: 1)
    ]]
    return u7;
end;
tbl_upv_1.IsOwner = function()
    --[[
      name: IsOwner
      line: 339
      upvalues:
        Sound_upv_1 (copy, index: 1)
    ]]
    return Sound_upv_1:InvokeServer("IsOwner");
end;
tbl_upv_1.Played = u8.Event;
tbl_upv_1.Paused = u9.Event;
tbl_upv_1.Resumed = u10.Event;
tbl_upv_1.Stopped = u11.Event;
tbl_upv_1.TrackEnded = u12.Event;
tbl_upv_1.ModeChanged = u13.Event;
return tbl_upv_1;