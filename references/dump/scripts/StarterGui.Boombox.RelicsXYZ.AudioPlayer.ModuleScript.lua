-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Parent = script.Parent;
local Favorites = require(Parent.Favorites);
local Playlists = require(Parent.Playlists);
local Sound = require(Parent.Sound);
local Tracks = require(Parent.Tracks);
local Constants = require(Parent.Constants);
local PlayerOwnershipUpdated = ReplicatedStorage:WaitForChild("PlayerOwnershipUpdated");
local u1 = {};
local u2 = false;
local u3 = false;
local u4 = true;
local BindableEvent = Instance.new("BindableEvent");
local u5 = { "minimized", "playlist", "full" };
local defaultPlayerSize = Constants.GetOptions().defaultPlayerSize;
local Main = script.Parent.Parent.Main;
local _ = Main.TracksFrame;
local _ = Main.HeaderFrame;
Main.Visible = false;
PlayerOwnershipUpdated.OnClientEvent:Connect(function(p6) -- Line: 34
    -- upvalues: Sound (copy), Constants (copy), Playlists (copy)
    if p6 then
        Sound.ToggleSoundMode(Constants.GetOptions().defaultSoundModeForOwners);
        Playlists.UnlockPlaylists();
    end;
end);
Sound.TrackEnded:Connect(function(p7) -- Line: 41
    -- upvalues: u1 (copy), Tracks (copy), Sound (copy)
    local v8 = u1.NextTrack(p7);

    if v8 then
        local v9 = Tracks.GetTrackById(v8);
        Sound.Play(v9);
    end;
end);

function u1.NextTrack(p10) -- Line: 49
    -- upvalues: u2 (ref), Favorites (copy), Playlists (copy)
    if u2 then
        return Favorites.GetNextTrack(p10);
    end;

    return Playlists.GetNextTrack(p10);
end;

function u1.IsShowingFavorites() -- Line: 57
    -- upvalues: u3 (ref)
    return u3;
end;

function u1.IsSearchActive() -- Line: 61
    -- upvalues: u4 (ref)
    return u4;
end;

function u1.IsPlayingFavorites() -- Line: 65
    -- upvalues: u2 (ref)
    return u2;
end;

function u1.SetVisibility(p11) -- Line: 69
    -- upvalues: Main (copy)
    Main.Visible = p11;
end;

function u1.ToggleVisibility() -- Line: 73
    -- upvalues: Main (copy)
    Main.Visible = not Main.Visible;
end;

function u1.ToggleFavorites() -- Line: 83
    -- upvalues: u3 (ref)
    u3 = not u3;
end;

function u1.ToggleSearch() -- Line: 89
    -- upvalues: u4 (ref)
    u4 = not u4;
end;

function u1.SetPlayingFavorites(p12) -- Line: 94
    -- upvalues: u2 (ref), Playlists (copy)
    u2 = p12;

    if p12 then
        Playlists.ClearActivePlaylist();
    end;
end;

local function GetNextAudioPlayerSize() -- Line: 102
    -- upvalues: defaultPlayerSize (ref), u5 (copy)
    return defaultPlayerSize % #u5 + 1;
end;

function u1.AudioPlayerSize() -- Line: 106
    -- upvalues: u5 (copy), defaultPlayerSize (ref)
    return u5[defaultPlayerSize];
end;

function u1.SetAudioPlayerState(p13) -- Line: 110
    -- upvalues: u5 (copy), defaultPlayerSize (ref), BindableEvent (copy)
    for i, v in ipairs(u5) do
        if v == p13 then
            defaultPlayerSize = i;
            BindableEvent:Fire(p13);
        end;
    end;
end;

function u1.SetNextAudioPlayerState() -- Line: 119
    -- upvalues: defaultPlayerSize (ref), u5 (copy), BindableEvent (copy)
    defaultPlayerSize = defaultPlayerSize % #u5 + 1;
    BindableEvent:Fire(u5[defaultPlayerSize]);
end;

u1.SizeUpdate = BindableEvent.Event;

return u1;