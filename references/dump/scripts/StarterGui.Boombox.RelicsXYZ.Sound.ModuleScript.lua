-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local _ = game:GetService("Players").LocalPlayer;
local MarketplaceService = game:GetService("MarketplaceService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local SoundService = game:GetService("SoundService");
local Sound = ReplicatedStorage:WaitForChild("Sound");
local RelicsServerSoundAdded = ReplicatedStorage:WaitForChild("RelicsServerSoundAdded");
local v1 = require(script.Parent.Constants).GetOptions();
local u2 = Sound:InvokeServer("MaxVolume");
local u3 = Sound:InvokeServer("StepVolume");
local u4 = Sound:InvokeServer("DefaultVolume");
local u5 = Sound:InvokeServer("UgcItemId");
local Jukebox = SoundService:WaitForChild("Jukebox");
local Main = script.Parent.Parent:WaitForChild("Main");
local VolumeGreen = Main.PlayingFrame.Volume.VolumeBar.VolumeGreen;
VolumeGreen.Size = UDim2.new(u4 / u2, 0, 1, 0);

local function getSoundProperty(p6) -- Line: 28
    -- upvalues: Sound (copy)
    return Sound:InvokeServer(p6, nil, shared.LastJukebox);
end;

local Tracks = require(script.Parent.Tracks);

local function ValidateSong(u7) -- Line: 35
    -- upvalues: MarketplaceService (copy)
    if not (u7 and tonumber(u7)) then
        return false;
    end;

    local success, result = pcall(function() -- Line: 38
        -- upvalues: MarketplaceService (ref), u7 (copy)
        return MarketplaceService:GetProductInfo(u7);
    end);

    return success and (result and (result.AssetTypeId == 3 and result.Name ~= "(Removed for copyright)")) and true or false;
end;

local u8 = {};
local u9 = nil;
local u10 = nil;
local defaultSoundMode = v1.defaultSoundMode;
local BindableEvent = Instance.new("BindableEvent");
local BindableEvent2 = Instance.new("BindableEvent");
local BindableEvent3 = Instance.new("BindableEvent");
local BindableEvent4 = Instance.new("BindableEvent");
local BindableEvent5 = Instance.new("BindableEvent");
local BindableEvent6 = Instance.new("BindableEvent");

local function getOrCreateSound() -- Line: 63
    -- upvalues: u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy)
    if u9 then
        return u9;
    end;

    u9 = Instance.new("Sound");
    u9.SoundGroup = Jukebox;
    u9.RollOffMaxDistance = 60;
    u9.RollOffMinDistance = 0;
    u9.Parent = Main;
    u9.Ended:Connect(function() -- Line: 74
        -- upvalues: BindableEvent5 (ref), u9 (ref)
        BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
    end);

    return u9;
end;

function u8.ToggleSoundMode(p11) -- Line: 81
    -- upvalues: defaultSoundMode (ref), u9 (ref), Sound (copy), u10 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), BindableEvent6 (copy)
    defaultSoundMode = p11;

    if u9 then
        local _ = u9.Playing;
    end;

    local v12 = u9 and u9.IsPaused;
    local v13 = Sound:InvokeServer("IsPlaying", nil, shared.LastJukebox);

    if defaultSoundMode == "global" and u9 then
        local v14 = u9.SoundId:match("rbxassetid://(%d+)");
        local TimePosition = u9.TimePosition;
        u9:Stop();
        u9:Destroy();
        u9 = nil;

        if TimePosition > 0 then
            Sound:InvokeServer("Play", v14, shared.LastJukebox);
            Sound:InvokeServer("SetPosition", TimePosition, shared.LastJukebox);

            if v12 then
                Sound:InvokeServer("Pause", nil, shared.LastJukebox);
            end;
        end;
    end;

    if defaultSoundMode == "local" then
        local TimePosition = u10.TimePosition;
        local v15 = Sound:InvokeServer("Stop", nil, shared.LastJukebox);
        local v16;

        if u9 then
            v16 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v16 = u9;
        end;

        u9 = v16;

        if TimePosition > 0 then
            u9.SoundId = "rbxassetid://" .. v15;
            u9.TimePosition = TimePosition;

            if v13 then
                u9:Play();
            end;
        end;
    end;

    BindableEvent6:Fire(defaultSoundMode);
end;

RelicsServerSoundAdded.OnClientEvent:Connect(function(p17) -- Line: 123
    -- upvalues: u10 (ref), BindableEvent5 (copy)
    u10 = p17;

    if not (u10 and u10.Parent) then
        return;
    end;

    u10.Ended:Connect(function() -- Line: 126
        -- upvalues: BindableEvent5 (ref), u10 (ref)
        BindableEvent5:Fire(u10.SoundId:match("rbxassetid://(%d+)"));
    end);
end);

function u8.PlayBySoundId(p18) -- Line: 131
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), BindableEvent (copy), Sound (copy)
    if defaultSoundMode ~= "local" then
        Sound:InvokeServer("Play", p18, shared.LastJukebox);
        BindableEvent:Fire(p18);

        return;
    end;

    local v19;

    if u9 then
        v19 = u9;
    else
        u9 = Instance.new("Sound");
        u9.SoundGroup = Jukebox;
        u9.RollOffMaxDistance = 60;
        u9.RollOffMinDistance = 0;
        u9.Parent = Main;
        u9.Ended:Connect(function() -- Line: 74
            -- upvalues: BindableEvent5 (ref), u9 (ref)
            BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
        end);
        v19 = u9;
    end;

    if v19.Playing then
        v19:Stop();
    end;

    v19.SoundId = "rbxassetid://" .. tostring(p18);
    v19:Play();
    BindableEvent:Fire(p18);
end;

function u8.Play(p20) -- Line: 149
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), Sound (copy), BindableEvent (copy)
    local id = p20.id;

    if defaultSoundMode == "local" then
        local v21;

        if u9 then
            v21 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v21 = u9;
        end;

        if v21.Playing then
            v21:Stop();
        end;

        v21.SoundId = "rbxassetid://" .. tostring(id);
        v21:Play();
    else
        Sound:InvokeServer("Play", id, shared.LastJukebox);
    end;

    BindableEvent:Fire(id);
end;

function u8.Stop() -- Line: 169
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), Sound (copy), BindableEvent4 (copy)
    local v22;

    if defaultSoundMode == "local" then
        local v23;

        if u9 then
            v23 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v23 = u9;
        end;

        v22 = v23.SoundId:match("rbxassetid://(%d+)");
        v23:Stop();
    else
        v22 = Sound:InvokeServer("Stop", nil, shared.LastJukebox);
    end;

    BindableEvent4:Fire(v22);
end;

function u8.Pause() -- Line: 186
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), Sound (copy), BindableEvent2 (copy)
    local v24;

    if defaultSoundMode == "local" then
        local v25;

        if u9 then
            v25 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v25 = u9;
        end;

        v24 = v25.SoundId:match("rbxassetid://(%d+)");
        v25:Pause();
    else
        v24 = Sound:InvokeServer("Pause", nil, shared.LastJukebox);
    end;

    BindableEvent2:Fire(v24);
end;

function u8.Resume() -- Line: 198
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), Sound (copy), BindableEvent3 (copy)
    local v26;

    if defaultSoundMode == "local" then
        local v27;

        if u9 then
            v27 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v27 = u9;
        end;

        v26 = v27.SoundId:match("rbxassetid://(%d+)");
        v27:Resume();
    else
        v26 = Sound:InvokeServer("Resume", nil, shared.LastJukebox);
    end;

    BindableEvent3:Fire(v26);
end;

function u8.VolumeUp() -- Line: 212
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), u3 (copy), u2 (copy), Sound (copy), VolumeGreen (copy), u8 (copy)
    if defaultSoundMode == "local" then
        local v28;

        if u9 then
            v28 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v28 = u9;
        end;

        v28.Volume = math.clamp(v28.Volume + u3, 0, u2);
    else
        Sound:InvokeServer("Up", nil, shared.LastJukebox);
    end;

    VolumeGreen.Size = UDim2.new(u8.Volume() / u8.MaxVolume(), 0, 1, 0);
end;

function u8.VolumeDown() -- Line: 222
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), u3 (copy), u2 (copy), Sound (copy), VolumeGreen (copy), u8 (copy)
    if defaultSoundMode == "local" then
        local v29;

        if u9 then
            v29 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v29 = u9;
        end;

        v29.Volume = math.clamp(v29.Volume - u3, 0, u2);
    else
        Sound:InvokeServer("Down", nil, shared.LastJukebox);
    end;

    VolumeGreen.Size = UDim2.new(u8.Volume() / u8.MaxVolume(), 0, 1, 0);
end;

function u8.SetVolume(p30) -- Line: 232
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), Sound (copy), VolumeGreen (copy), u8 (copy)
    if defaultSoundMode == "local" then
        local v31;

        if u9 then
            v31 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v31 = u9;
        end;

        v31.Volume = math.clamp(p30, 0, 1);
    else
        Sound:InvokeServer("SetVolume", p30, shared.LastJukebox);
    end;

    VolumeGreen.Size = UDim2.new(u8.Volume() / u8.MaxVolume(), 0, 1, 0);
end;

function u8.GetActive() -- Line: 242
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), Sound (copy), Tracks (copy)
    local v32 = nil;

    if defaultSoundMode == "local" then
        local v33;

        if u9 then
            v33 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v33 = u9;
        end;

        if v33.IsPlaying then
            v32 = v33.SoundId:match("rbxassetid://(%d+)");
        end;
    else
        v32 = Sound:InvokeServer("Playing", nil, shared.LastJukebox);
    end;

    return not v32 and {
        id = v32
    } or Tracks.GetTrackById(v32);
end;

function u8.Playing() -- Line: 263
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), Sound (copy), Tracks (copy)
    local v34 = nil;

    if defaultSoundMode == "local" then
        local v35;

        if u9 then
            v35 = u9;
        else
            u9 = Instance.new("Sound");
            u9.SoundGroup = Jukebox;
            u9.RollOffMaxDistance = 60;
            u9.RollOffMinDistance = 0;
            u9.Parent = Main;
            u9.Ended:Connect(function() -- Line: 74
                -- upvalues: BindableEvent5 (ref), u9 (ref)
                BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
            end);
            v35 = u9;
        end;

        if v35.IsPlaying then
            v34 = v35.SoundId:match("rbxassetid://(%d+)");
        end;
    else
        v34 = Sound:InvokeServer("Playing", nil, shared.LastJukebox);
    end;

    if v34 then
        return Tracks.GetTrackById(v34);
    end;

    return nil;
end;

function u8.IsPlaying() -- Line: 281
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), getSoundProperty (copy)
    if defaultSoundMode ~= "local" then
        return getSoundProperty("IsPlaying");
    end;

    local v36;

    if u9 then
        v36 = u9;
    else
        u9 = Instance.new("Sound");
        u9.SoundGroup = Jukebox;
        u9.RollOffMaxDistance = 60;
        u9.RollOffMinDistance = 0;
        u9.Parent = Main;
        u9.Ended:Connect(function() -- Line: 74
            -- upvalues: BindableEvent5 (ref), u9 (ref)
            BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
        end);
        v36 = u9;
    end;

    return v36.Playing;
end;

function u8.IsPaused() -- Line: 290
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), getSoundProperty (copy)
    if defaultSoundMode ~= "local" then
        return getSoundProperty("IsPaused");
    end;

    local v37;

    if u9 then
        v37 = u9;
    else
        u9 = Instance.new("Sound");
        u9.SoundGroup = Jukebox;
        u9.RollOffMaxDistance = 60;
        u9.RollOffMinDistance = 0;
        u9.Parent = Main;
        u9.Ended:Connect(function() -- Line: 74
            -- upvalues: BindableEvent5 (ref), u9 (ref)
            BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
        end);
        v37 = u9;
    end;

    return v37.IsPaused;
end;

function u8.Volume() -- Line: 299
    -- upvalues: defaultSoundMode (ref), u9 (ref), Jukebox (copy), Main (copy), BindableEvent5 (copy), getSoundProperty (copy)
    if defaultSoundMode ~= "local" then
        return getSoundProperty("Volume");
    end;

    local v38;

    if u9 then
        v38 = u9;
    else
        u9 = Instance.new("Sound");
        u9.SoundGroup = Jukebox;
        u9.RollOffMaxDistance = 60;
        u9.RollOffMinDistance = 0;
        u9.Parent = Main;
        u9.Ended:Connect(function() -- Line: 74
            -- upvalues: BindableEvent5 (ref), u9 (ref)
            BindableEvent5:Fire(u9.SoundId:match("rbxassetid://(%d+)"));
        end);
        v38 = u9;
    end;

    return v38.Volume;
end;

function u8.Search(p39) -- Line: 308
    -- upvalues: ValidateSong (copy), u8 (copy)
    if not p39 then
        return;
    end;

    if ValidateSong(p39) then
        u8.PlayBySoundId(p39);

        return { u8.GetActive() };
    end;
end;

function u8.DefaultVolume() -- Line: 323
    -- upvalues: u4 (copy)
    return u4;
end;

function u8.MaxVolume() -- Line: 327
    -- upvalues: u2 (copy)
    return u2;
end;

function u8.UgcItemId() -- Line: 331
    -- upvalues: u5 (copy)
    return u5;
end;

function u8.SoundMode() -- Line: 335
    -- upvalues: defaultSoundMode (ref)
    return defaultSoundMode;
end;

function u8.IsOwner() -- Line: 339
    -- upvalues: Sound (copy)
    return Sound:InvokeServer("IsOwner");
end;

u8.Played = BindableEvent.Event;
u8.Paused = BindableEvent2.Event;
u8.Resumed = BindableEvent3.Event;
u8.Stopped = BindableEvent4.Event;
u8.TrackEnded = BindableEvent5.Event;
u8.ModeChanged = BindableEvent6.Event;

return u8;