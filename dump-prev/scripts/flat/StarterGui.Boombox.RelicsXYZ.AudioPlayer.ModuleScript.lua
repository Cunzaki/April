-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Parent_1 = script.Parent;
local Favorites_upv_1 = require(Parent_1.Favorites);
local Playlists_upv_1 = require(Parent_1.Playlists);
local Sound_upv_1 = require(Parent_1.Sound);
local Tracks_upv_1 = require(Parent_1.Tracks);
local Constants_upv_1 = require(Parent_1.Constants);
local PlayerOwnershipUpdated_1 = ReplicatedStorage_1:WaitForChild("PlayerOwnershipUpdated");
local tbl_upv_1 = {};
local u1 = false;
local u2 = false;
local u3 = true;
local u4 = Instance.new("BindableEvent");
local tbl_upv_2 = {"minimized", "playlist", "full"};
local u5 = Constants_upv_1.GetOptions().defaultPlayerSize;
local Main_upv_1 = script.Parent.Parent.Main;
Main_upv_1.Visible = false;
PlayerOwnershipUpdated_1.OnClientEvent:Connect(
    function(a1)
        --[[
          line: 34
          upvalues:
            Sound_upv_1 (copy, index: 1)
            Constants_upv_1 (copy, index: 2)
            Playlists_upv_1 (copy, index: 3)
        ]]
        if (not a1) then
            return;
        end;
        Sound_upv_1.ToggleSoundMode(Constants_upv_1.GetOptions().defaultSoundModeForOwners);
        Playlists_upv_1.UnlockPlaylists();
    end
);
Sound_upv_1.TrackEnded:Connect(
    function(a1)
        --[[
          line: 41
          upvalues:
            tbl_upv_1 (copy, index: 1)
            Tracks_upv_1 (copy, index: 2)
            Sound_upv_1 (copy, index: 3)
        ]]
        local v1 = tbl_upv_1.NextTrack(a1);
        if (not v1) then
            return;
        end;
        Sound_upv_1.Play((Tracks_upv_1.GetTrackById(v1)));
    end
);
tbl_upv_1.NextTrack = function(a1)
    --[[
      name: NextTrack
      line: 49
      upvalues:
        u1 (ref,  index: 1)
        Favorites_upv_1 (copy, index: 2)
        Playlists_upv_1 (copy, index: 3)
    ]]
    if (u1) then
        return Favorites_upv_1.GetNextTrack(a1);
    end;
    return Playlists_upv_1.GetNextTrack(a1);
end;
tbl_upv_1.IsShowingFavorites = function()
    --[[
      name: IsShowingFavorites
      line: 57
      upvalues:
        u2 (ref, index: 1)
    ]]
    return u2;
end;
tbl_upv_1.IsSearchActive = function()
    --[[
      name: IsSearchActive
      line: 61
      upvalues:
        u3 (ref, index: 1)
    ]]
    return u3;
end;
tbl_upv_1.IsPlayingFavorites = function()
    --[[
      name: IsPlayingFavorites
      line: 65
      upvalues:
        u1 (ref, index: 1)
    ]]
    return u1;
end;
tbl_upv_1.SetVisibility = function(a1)
    --[[
      name: SetVisibility
      line: 69
      upvalues:
        Main_upv_1 (copy, index: 1)
    ]]
    Main_upv_1.Visible = a1;
end;
tbl_upv_1.ToggleVisibility = function()
    --[[
      name: ToggleVisibility
      line: 73
      upvalues:
        Main_upv_1 (copy, index: 1)
    ]]
    Main_upv_1.Visible = not Main_upv_1.Visible;
end;
tbl_upv_1.ToggleFavorites = function()
    --[[
      name: ToggleFavorites
      line: 83
      upvalues:
        u2 (ref, index: 1)
    ]]
    u2 = not u2;
end;
tbl_upv_1.ToggleSearch = function()
    --[[
      name: ToggleSearch
      line: 89
      upvalues:
        u3 (ref, index: 1)
    ]]
    u3 = not u3;
end;
tbl_upv_1.SetPlayingFavorites = function(a1)
    --[[
      name: SetPlayingFavorites
      line: 94
      upvalues:
        u1 (ref,  index: 1)
        Playlists_upv_1 (copy, index: 2)
    ]]
    u1 = a1;
    if (not a1) then
        return;
    end;
    Playlists_upv_1.ClearActivePlaylist();
end;
local function GetNextAudioPlayerSize_1()
    --[[
      name: GetNextAudioPlayerSize
      line: 102
      upvalues:
        u5 (ref,  index: 1)
        tbl_upv_2 (copy, index: 2)
    ]]
    return (u5 % #tbl_upv_2) + 1;
end;
tbl_upv_1.AudioPlayerSize = function()
    --[[
      name: AudioPlayerSize
      line: 106
      upvalues:
        tbl_upv_2 (copy, index: 1)
        u5 (ref,  index: 2)
    ]]
    return tbl_upv_2[u5];
end;
tbl_upv_1.SetAudioPlayerState = function(a1)
    --[[
      name: SetAudioPlayerState
      line: 110
      upvalues:
        tbl_upv_2 (copy, index: 1)
        u5 (ref,  index: 2)
        u4 (copy, index: 3)
    ]]
    for key_1, value_1 in ipairs(tbl_upv_2) do
        if (value_1 == a1) then
            u5 = key_1;
            u4:Fire(a1);
        end;
    end;
end;
tbl_upv_1.SetNextAudioPlayerState = function()
    --[[
      name: SetNextAudioPlayerState
      line: 119
      upvalues:
        u5 (ref,  index: 1)
        tbl_upv_2 (copy, index: 2)
        u4 (copy, index: 3)
    ]]
    u5 = (u5 % #tbl_upv_2) + 1;
    u4:Fire(tbl_upv_2[u5]);
end;
tbl_upv_1.SizeUpdate = u4.Event;
return tbl_upv_1;