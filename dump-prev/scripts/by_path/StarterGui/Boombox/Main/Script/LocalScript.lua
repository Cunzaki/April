-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

script.Parent.Visible = false;
local function isNumeric_1(a1)
    --[[
      name: isNumeric
      line: 4
    ]]
    local v1 = a1:match("^%d+$") ~= nil;
    return v1;
end;
local function tableIsEmpty_1(a1)
    --[[
      name: tableIsEmpty
      line: 8
    ]]
    for _, v2 in pairs(a1) do
        return false;
    end;
    return true;
end;
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local MarketplaceService_upv_1 = game:GetService("MarketplaceService");
local FavoriteStatusFunction_upv_1 = ReplicatedStorage_1:WaitForChild("FavoriteStatusFunction");
local FavoriteTrackFunction_upv_1 = ReplicatedStorage_1:WaitForChild("FavoriteTrackFunction");
local _ = ReplicatedStorage_1:WaitForChild("FavoriteIdsFunction");
local FavoriteChangedEvent_upv_1 = ReplicatedStorage_1:WaitForChild("FavoriteChangedEvent");
local PlayerOwnershipUpdated_1 = ReplicatedStorage_1:WaitForChild("PlayerOwnershipUpdated");
local LocalPlayer_upv_1 = game.Players.LocalPlayer;
local Parent_1 = script.Parent.Parent;
local RelicsXYZ_1 = Parent_1:WaitForChild("RelicsXYZ");
local Tracks_upv_1 = require(RelicsXYZ_1.Tracks);
local Sound_upv_1 = require(RelicsXYZ_1.Sound);
local Playlists_upv_1 = require(RelicsXYZ_1.Playlists);
local Favorites_upv_1 = require(RelicsXYZ_1.Favorites);
local Constants_1 = require(RelicsXYZ_1.Constants);
local AudioPlayer_upv_1 = require(RelicsXYZ_1.AudioPlayer);
local u1 = Constants_1.GetColors();
local u2 = Constants_1.GetImages();
local u3 = Constants_1.GetElements();
local u4 = Constants_1.GetOptions();
local Parent_upv_2 = script.Parent;
local PlaylistFrame_upv_1 = Parent_upv_2.PlaylistFrame;
local Main_1 = Parent_upv_2.PlayingFrame.Main;
local Volume_1 = Parent_upv_2.PlayingFrame.Volume;
local HeaderFrame_upv_1 = Parent_upv_2.HeaderFrame;
local TracksFrame_upv_1 = Parent_upv_2.TracksFrame;
local MessageFrame_upv_1 = Parent_upv_2.MessageFrame;
local Title_upv_1 = Main_1.Playing.Title;
local Artist_upv_1 = Main_1.Playing.Artist;
local PlayingImage_upv_1 = Main_1.PlayingImage;
local NoImageFrame_upv_1 = Main_1.NoImageFrame;
local PlaybackControl_upv_1 = Main_1.Controls.PlaybackControl;
local NextControl_upv_1 = Main_1.Controls.NextControl;
local ExpandControl_upv_1 = Main_1.Controls.ExpandControl;
local FavoriteControl_upv_1 = Main_1.Controls.FavoriteControl;
local VolumeBar_upv_1 = Volume_1.VolumeBar;
local UIGridLayout_upv_1 = PlaylistFrame_upv_1.UIGridLayout;
local HeaderTitle_upv_1 = HeaderFrame_upv_1.HeaderTitle;
local SearchText_upv_1 = HeaderFrame_upv_1.SearchText;
local SearchButton_upv_1 = HeaderFrame_upv_1.SearchButton;
local ExpandCollapseButton_upv_1 = HeaderFrame_upv_1.ExpandCollapseButton;
local ToggleFavoritesButton_upv_1 = HeaderFrame_upv_1.ToggleFavoritesButton;
local v3 = Instance.new("UICorner");
v3.CornerRadius = UDim.new(0, u3.cornerRadiusLarge);
v3.Parent = Parent_upv_2;
Parent_upv_2.BackgroundColor3 = Color3.fromHex(u1.primary);
local v4 = Instance.new("UICorner");
v4.CornerRadius = UDim.new(0, u3.cornerRadiusLarge);
v4.Parent = Parent_upv_2.PlayingFrame;
Parent_upv_2.PlayingFrame.BackgroundColor3 = Color3.fromHex(u1.secondary);
Parent_1.ResetOnSpawn = false;
local function canPlayAudio_1()
    --[[
      name: canPlayAudio
      line: 96
      upvalues:
        Sound_upv_1 (copy, index: 1)
    ]]
    if (Sound_upv_1.IsOwner()) then
        return true;
    end;
    return false;
end;
local function updateParentFrameHeight_1()
    --[[
      name: updateParentFrameHeight
      line: 102
      upvalues:
        Parent_upv_2 (copy, index: 1)
    ]]
    Parent_upv_2.Size = UDim2.new(Parent_upv_2.Size.X.Scale, Parent_upv_2.Size.X.Offset, 0, Parent_upv_2.UIListLayout.AbsoluteContentSize.Y);
end;
function minimizedView()
    --[[
      name: minimizedView
      line: 106
      upvalues:
        ExpandCollapseButton_upv_1 (copy, index: 1)
        u2 (copy, index: 2)
        HeaderFrame_upv_1 (copy, index: 3)
        TracksFrame_upv_1 (copy, index: 4)
        PlaylistFrame_upv_1 (copy, index: 5)
        ExpandControl_upv_1 (copy, index: 6)
    ]]
    ExpandCollapseButton_upv_1.Image = u2.expand;
    HeaderFrame_upv_1.Visible = false;
    TracksFrame_upv_1.Visible = false;
    PlaylistFrame_upv_1.Visible = false;
    ExpandControl_upv_1.Visible = true;
end;
function playlistView()
    --[[
      name: playlistView
      line: 115
      upvalues:
        ExpandCollapseButton_upv_1 (copy, index: 1)
        u2 (copy, index: 2)
        HeaderFrame_upv_1 (copy, index: 3)
        TracksFrame_upv_1 (copy, index: 4)
        PlaylistFrame_upv_1 (copy, index: 5)
        ExpandControl_upv_1 (copy, index: 6)
    ]]
    ExpandCollapseButton_upv_1.Image = u2.collapse;
    HeaderFrame_upv_1.Visible = true;
    TracksFrame_upv_1.Visible = false;
    PlaylistFrame_upv_1.Visible = true;
    ExpandControl_upv_1.Visible = false;
end;
function fullView()
    --[[
      name: fullView
      line: 124
      upvalues:
        ExpandCollapseButton_upv_1 (copy, index: 1)
        u2 (copy, index: 2)
        HeaderFrame_upv_1 (copy, index: 3)
        TracksFrame_upv_1 (copy, index: 4)
        PlaylistFrame_upv_1 (copy, index: 5)
        ExpandControl_upv_1 (copy, index: 6)
    ]]
    ExpandCollapseButton_upv_1.Image = u2.collapse;
    HeaderFrame_upv_1.Visible = true;
    TracksFrame_upv_1.Visible = true;
    PlaylistFrame_upv_1.Visible = true;
    ExpandControl_upv_1.Visible = false;
end;
function searchView()
    --[[
      name: searchView
      line: 133
      upvalues:
        HeaderFrame_upv_1 (copy, index: 1)
        TracksFrame_upv_1 (copy, index: 2)
        PlaylistFrame_upv_1 (copy, index: 3)
        ExpandControl_upv_1 (copy, index: 4)
    ]]
    HeaderFrame_upv_1.Visible = true;
    TracksFrame_upv_1.Visible = true;
    PlaylistFrame_upv_1.Visible = false;
    ExpandControl_upv_1.Visible = false;
end;
function favoritesView()
    --[[
      name: favoritesView
      line: 140
      upvalues:
        HeaderFrame_upv_1 (copy, index: 1)
        TracksFrame_upv_1 (copy, index: 2)
        PlaylistFrame_upv_1 (copy, index: 3)
        ExpandControl_upv_1 (copy, index: 4)
    ]]
    HeaderFrame_upv_1.Visible = true;
    TracksFrame_upv_1.Visible = true;
    PlaylistFrame_upv_1.Visible = false;
    ExpandControl_upv_1.Visible = false;
end;
AudioPlayer_upv_1.SizeUpdate:Connect(
    function(a1)
        --[[
          line: 147
          upvalues:
            Parent_upv_2 (copy, index: 1)
        ]]
        if (a1 == "minimized") then
            minimizedView();
        elseif (a1 == "playlist") then
            playlistView();
        elseif (a1 == "full") then
            fullView();
        end;
        Parent_upv_2.Size = UDim2.new(Parent_upv_2.Size.X.Scale, Parent_upv_2.Size.X.Offset, 0, Parent_upv_2.UIListLayout.AbsoluteContentSize.Y);
    end
);
local function clearActiveFrameFromPlaylist_upv_1()
    --[[
      name: clearActiveFrameFromPlaylist
      line: 171
      upvalues:
        PlaylistFrame_upv_1 (copy, index: 1)
    ]]
    local v5 = nil;
    for _, value_1 in ipairs(PlaylistFrame_upv_1:GetChildren()) do
        if (not (value_1:IsA("Frame"))) then
            continue;
        end;
        v5 = value_1:FindFirstChild("ImageButton");
        if (v5) then
            local ImageLabel_1 = v5:FindFirstChild("ImageLabel");
            v5.Size = UDim2.new(1, 0, 1, 0);
            ImageLabel_1.Position = UDim2.new(0, 0, 0, 0);
        end;
    end;
end;
local function applyActiveFrameToPlaylist_upv_1(a1)
    --[[
      name: applyActiveFrameToPlaylist
      line: 157
      upvalues:
        PlaylistFrame_upv_1 (copy, index: 1)
    ]]
    local v6 = PlaylistFrame_upv_1:FindFirstChild(a1);
    local v7 = nil;
    if (v6) then
        v7 = v6:FindFirstChild("ImageButton");
        local v8 = v7 and (v7:FindFirstChild("ImageLabel"));
        if (not v7 or not v8) then
            return;
        end;
        v7.Size = UDim2.new(1, -4, 1, -4);
        v8.Position = UDim2.new(0, 2, 0, 2);
    end;
end;
local function isTrackFavorited_1(a1)
    --[[
      name: isTrackFavorited
      line: 266
      upvalues:
        FavoriteStatusFunction_upv_1 (copy, index: 1)
    ]]
    return FavoriteStatusFunction_upv_1:InvokeServer(a1);
end;
UIGridLayout_upv_1:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
    function()
        --[[
          line: 429
          upvalues:
            PlaylistFrame_upv_1 (copy, index: 1)
            UIGridLayout_upv_1 (copy, index: 2)
        ]]
        PlaylistFrame_upv_1.CanvasSize = UDim2.new(0, UIGridLayout_upv_1.AbsoluteContentSize.X, 0, UIGridLayout_upv_1.AbsoluteContentSize.Y);
    end
);
TracksFrame_upv_1.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
    function()
        --[[
          line: 433
          upvalues:
            TracksFrame_upv_1 (copy, index: 1)
        ]]
        TracksFrame_upv_1.CanvasSize = UDim2.new(0, TracksFrame_upv_1.UIListLayout.AbsoluteContentSize.X, 0, TracksFrame_upv_1.UIListLayout.AbsoluteContentSize.Y);
    end
);
Title_upv_1.Text = "Select a Mood to listen";
Artist_upv_1.Text = "Start with a playlist";
SearchButton_upv_1.Image = u2.search;
NextControl_upv_1.Image = u2.forward;
ExpandControl_upv_1.Image = u2.expand;
ExpandCollapseButton_upv_1.Image = u2.collapse;
ToggleFavoritesButton_upv_1.Image = u2.favoriteOutline;
FavoriteControl_upv_1.Image = u2.favoriteOutline;
FavoriteControl_upv_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 446
          upvalues:
            Sound_upv_1 (copy, index: 1)
            FavoriteTrackFunction_upv_1 (copy, index: 2)
            FavoriteControl_upv_1 (copy, index: 3)
            u2 (copy, index: 4)
        ]]
        FavoriteControl_upv_1.Image = FavoriteTrackFunction_upv_1:InvokeServer(Sound_upv_1.GetActive().id) and u2.favoriteSolid or u2.favoriteOutline;
    end
);
FavoriteChangedEvent_upv_1.OnClientEvent:Connect(
    function(a1, a2)
        --[[
          line: 452
          upvalues:
            Sound_upv_1 (copy, index: 1)
            FavoriteControl_upv_1 (copy, index: 2)
            u2 (copy, index: 3)
        ]]
        if (Sound_upv_1.GetActive().id ~= a1) then
            return;
        end;
        FavoriteControl_upv_1.Image = (a2 and (u2.favoriteSolid)) or (u2.favoriteOutline);
    end
);
Sound_upv_1.Played:Connect(
    function()
        --[[
          line: 461
          upvalues:
            Sound_upv_1 (copy, index: 1)
            Playlists_upv_1 (copy, index: 2)
            PlaybackControl_upv_1 (copy, index: 3)
            u2 (copy, index: 4)
            NextControl_upv_1 (copy, index: 5)
            FavoriteControl_upv_1 (copy, index: 6)
            Title_upv_1 (copy, index: 7)
            Artist_upv_1 (copy, index: 8)
            PlayingImage_upv_1 (copy, index: 9)
            NoImageFrame_upv_1 (copy, index: 10)
            FavoriteStatusFunction_upv_1 (copy, index: 11)
            AudioPlayer_upv_1 (copy, index: 12)
        ]]
        local v10 = Sound_upv_1.GetActive();
        local v11 = Playlists_upv_1.GetActive();
        PlaybackControl_upv_1.Image = u2.pause;
        NextControl_upv_1.Visible = true;
        FavoriteControl_upv_1.Visible = true;
        Title_upv_1.Text = v10.title or "[unknown title]";
        Artist_upv_1.Text = v10.artist or "[unknown artist]";
        PlayingImage_upv_1.Visible = false;
        NoImageFrame_upv_1.Visible = true;
        PlayingImage_upv_1.Image = "";
        FavoriteControl_upv_1.Image = FavoriteStatusFunction_upv_1:InvokeServer(v10.id) and u2.favoriteSolid or u2.favoriteOutline;
        if (not v11 or not v11.image or AudioPlayer_upv_1.IsShowingFavorites() ~= false) then
            return;
        end;
        PlayingImage_upv_1.Visible = true;
        NoImageFrame_upv_1.Visible = false;
        PlayingImage_upv_1.Image = "rbxassetid://" .. v11.image;
    end
);
Sound_upv_1.Resumed:Connect(
    function()
        --[[
          line: 485
          upvalues:
            PlaybackControl_upv_1 (copy, index: 1)
            u2 (copy, index: 2)
        ]]
        PlaybackControl_upv_1.Image = u2.pause;
    end
);
Sound_upv_1.Paused:Connect(
    function()
        --[[
          line: 489
          upvalues:
            PlaybackControl_upv_1 (copy, index: 1)
            u2 (copy, index: 2)
        ]]
        PlaybackControl_upv_1.Image = u2.play;
    end
);
Sound_upv_1.Stopped:Connect(
    function()
        --[[
          line: 493
          upvalues:
            NextControl_upv_1 (copy, index: 1)
            PlaybackControl_upv_1 (copy, index: 2)
            u2 (copy, index: 3)
            Title_upv_1 (copy, index: 4)
            Artist_upv_1 (copy, index: 5)
            clearActiveFrameFromPlaylist_upv_1 (copy, index: 6)
        ]]
        NextControl_upv_1.Visible = false;
        PlaybackControl_upv_1.Image = u2.play;
        Title_upv_1.Text = "Select a Mood to listen";
        Artist_upv_1.Text = "Start with a playlist";
        clearActiveFrameFromPlaylist_upv_1();
    end
);
ExpandCollapseButton_upv_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 503
          upvalues:
            AudioPlayer_upv_1 (copy, index: 1)
        ]]
        AudioPlayer_upv_1.SetNextAudioPlayerState();
    end
);
ExpandControl_upv_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 508
          upvalues:
            AudioPlayer_upv_1 (copy, index: 1)
        ]]
        AudioPlayer_upv_1.SetNextAudioPlayerState();
    end
);
local function UpdateTracksV2_upv_1(a1, a2)
    --[[
      name: UpdateTracksV2
      line: 270
      upvalues:
        TracksFrame_upv_1 (copy, index: 1)
        u1 (copy, index: 2)
        u2 (copy, index: 3)
        FavoriteStatusFunction_upv_1 (copy, index: 4)
        FavoriteTrackFunction_upv_1 (copy, index: 5)
        FavoriteChangedEvent_upv_1 (copy, index: 6)
        Sound_upv_1 (copy, index: 7)
        AudioPlayer_upv_1 (copy, index: 8)
    ]]
    for _, value_2 in ipairs(TracksFrame_upv_1:GetChildren()) do
        if (value_2:IsA("Frame")) then
            value_2:Destroy();
        end;
    end;
    local v13 = nil;
    local v14 = nil;
    local v15 = nil;
    local v16 = nil;
    local v17 = nil;
    local v18 = nil;
    local u5 = nil;
    local v19 = nil;
    local v20 = nil;
    local v21 = nil;
    local v22 = nil;
    local u6 = nil;
    local v23 = nil;
    local updatePlaybackControlImage_1 = nil;
    for key_1, value_upv_3 in pairs(a1) do
        v13 = Instance.new("Frame");
        v13.Parent = TracksFrame_upv_1;
        v13.Name = value_upv_3.id;
        v13.Size = UDim2.new(1, 0, 0, 40);
        v13.BackgroundColor3 = Color3.fromHex(u1.secondary);
        v13.BorderSizePixel = 0;
        v14 = ((key_1 % 2 == 0) and (Color3.fromHex(u1.primary))) or (Color3.fromHex(u1.secondary));
        v13.BackgroundColor3 = v14;
        v15 = Instance.new("UIPadding");
        v15.Parent = v13;
        v15.PaddingBottom = UDim.new(0, 5);
        v15.PaddingLeft = UDim.new(0, 5);
        v15.PaddingRight = UDim.new(0, 5);
        v15.PaddingTop = UDim.new(0, 5);
        v16 = Instance.new("UIListLayout");
        v16.Parent = v13;
        v16.Padding = UDim.new(0, 15);
        v16.FillDirection = Enum.FillDirection.Horizontal;
        v16.SortOrder = Enum.SortOrder.LayoutOrder;
        v16.VerticalAlignment = Enum.VerticalAlignment.Center;
        v17 = Instance.new("Frame");
        v17.Parent = v13;
        v17.BackgroundTransparency = 1;
        v17.BorderSizePixel = 0;
        v17.Size = UDim2.new(0, 30, 0, 30);
        v18 = Instance.new("UIListLayout");
        v18.Parent = v17;
        v18.FillDirection = Enum.FillDirection.Horizontal;
        v18.HorizontalAlignment = Enum.HorizontalAlignment.Right;
        v18.SortOrder = Enum.SortOrder.LayoutOrder;
        v18.VerticalAlignment = Enum.VerticalAlignment.Center;
        u5 = Instance.new("ImageButton");
        u5.Name = "PlaybackControl";
        u5.Parent = v17;
        u5.BackgroundTransparency = 1;
        u5.BorderSizePixel = 0;
        u5.Size = UDim2.new(0, 30, 0, 30);
        u5.Image = u2.play;
        v19 = Instance.new("Frame");
        v19.Name = "Info";
        v19.Parent = v13;
        v19.Size = UDim2.new(0, 260, 0, 38);
        v19.BackgroundTransparency = 1;
        v19.BorderSizePixel = 0;
        v20 = Instance.new("UIListLayout");
        v20.Parent = v19;
        v20.Padding = UDim.new(0, 0);
        v20.SortOrder = Enum.SortOrder.LayoutOrder;
        v21 = Instance.new("TextLabel");
        v21.Name = "Title";
        v21.Parent = v19;
        v21.Size = UDim2.new(0, 214, 0, 20);
        v21.BackgroundTransparency = 1;
        v21.BorderSizePixel = 0;
        v21.TextSize = 14;
        v21.FontFace.Bold = true;
        v21.TextColor3 = Color3.fromHex(u1.textPrimary);
        v21.FontFace = Font.fromId(12187365364);
        v21.FontFace.Weight = Enum.FontWeight.Bold;
        v21.TextXAlignment = Enum.TextXAlignment.Left;
        v21.Text = value_upv_3.title;
        v22 = Instance.new("TextLabel");
        v22.Name = "Artist";
        v22.Parent = v19;
        v22.BackgroundTransparency = 1;
        v22.BorderSizePixel = 0;
        v22.Size = UDim2.new(0, 191, 0, 15);
        v22.TextSize = 12;
        v22.TextColor3 = Color3.fromHex(u1.textSecondary);
        v22.FontFace = Font.fromId(12187365364);
        v22.FontFace.Weight = Enum.FontWeight.Regular;
        v22.TextXAlignment = Enum.TextXAlignment.Left;
        v22.Text = value_upv_3.artist;
        u6 = Instance.new("ImageButton");
        u6.Name = "Favorite";
        u6.Parent = v13;
        u6.BackgroundTransparency = 1;
        u6.BorderSizePixel = 0;
        u6.LayoutOrder = 3;
        u6.Size = UDim2.new(0, 30, 0, 30);
        u6.Image = u2.favoriteOutline;
        v23 = ((FavoriteStatusFunction_upv_1:InvokeServer(value_upv_3.id)) and (u2.favoriteSolid)) or (u2.favoriteOutline);
        u6.Image = v23;
        u6.MouseButton1Click:Connect(
            function()
                --[[
                  line: 375
                  upvalues:
                    FavoriteTrackFunction_upv_1 (copy, index: 1)
                    value_upv_3 (copy, index: 2)
                    u6 (copy, index: 3)
                    u2 (copy, index: 4)
                ]]
                u6.Image = FavoriteTrackFunction_upv_1:InvokeServer(value_upv_3.id) and u2.favoriteSolid or u2.favoriteOutline;
            end
        );
        FavoriteChangedEvent_upv_1.OnClientEvent:Connect(
            function(a3, a4)
                --[[
                  line: 381
                  upvalues:
                    value_upv_3 (copy, index: 1)
                    u6 (copy, index: 2)
                    u2 (copy, index: 3)
                ]]
                if (a3 ~= value_upv_3.id) then
                    return;
                end;
                u6.Image = (a4 and (u2.favoriteSolid)) or (u2.favoriteOutline);
            end
        );
        u5.MouseButton1Click:Connect(
            function()
                --[[
                  line: 396
                  upvalues:
                    Sound_upv_1 (copy, index: 1)
                    AudioPlayer_upv_1 (copy, index: 2)
                    a2 (copy, index: 3)
                    value_upv_3 (copy, index: 4)
                ]]
                local v25 = Sound_upv_1.GetActive();
                AudioPlayer_upv_1.ToggleSearch(a2);
                local v26 = nil;
                if (v25.id ~= value_upv_3.id) then
                    v26 = Sound_upv_1.IsOwner();
                    if (v26) then
                        Sound_upv_1.PlayBySoundId(value_upv_3.id);
                        return;
                    end;
                end;
                if ((not Sound_upv_1.IsPlaying() or v25.id ~= value_upv_3.id) and Sound_upv_1.IsPaused() and v25.id == value_upv_3.id) then
                    Sound_upv_1.Resume();
                end;
                Sound_upv_1.Pause();
            end
        );
        if ((Sound_upv_1.IsPlaying()) and Sound_upv_1.GetActive().id == value_upv_3.id) then
            u5.Image = u2.pause;
        else
            u5.Image = u2.play;
        end;
        updatePlaybackControlImage_1 = function()
            --[[
              name: updatePlaybackControlImage
              line: 388
              upvalues:
                Sound_upv_1 (copy, index: 1)
                value_upv_3 (copy, index: 2)
                u5 (copy, index: 3)
                u2 (copy, index: 4)
            ]]
            if (Sound_upv_1.IsPlaying() and Sound_upv_1.GetActive().id == value_upv_3.id) then
                u5.Image = u2.pause;
            else
                u5.Image = u2.play;
            end;
        end;
        Sound_upv_1.Played:Connect(updatePlaybackControlImage_1);
        Sound_upv_1.Resumed:Connect(updatePlaybackControlImage_1);
        Sound_upv_1.Paused:Connect(
            function()
                --[[
                  line: 423
                  upvalues:
                    u5 (copy, index: 1)
                    u2 (copy, index: 2)
                ]]
                u5.Image = u2.play;
            end
        );
    end;
end;
ToggleFavoritesButton_upv_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 515
          upvalues:
            ToggleFavoritesButton_upv_1 (copy, index: 1)
            AudioPlayer_upv_1 (copy, index: 2)
            u2 (copy, index: 3)
            Playlists_upv_1 (copy, index: 4)
            UpdateTracksV2_upv_1 (copy, index: 5)
            Favorites_upv_1 (copy, index: 6)
            clearActiveFrameFromPlaylist_upv_1 (copy, index: 7)
            Parent_upv_2 (copy, index: 8)
        ]]
        ToggleFavoritesButton_upv_1.Image = not AudioPlayer_upv_1.IsShowingFavorites() and u2.playlist or u2.favoriteOutline;
        local v28 = AudioPlayer_upv_1.IsShowingFavorites();
        AudioPlayer_upv_1.ToggleFavorites();
        if ((v28) and AudioPlayer_upv_1.IsPlayingFavorites() == false) then
            local v29 = Playlists_upv_1.GetTracks();
            if (v29) then
                AudioPlayer_upv_1.SetAudioPlayerState(AudioPlayer_upv_1.AudioPlayerSize());
                UpdateTracksV2_upv_1(v29, false);
            end;
        else
            UpdateTracksV2_upv_1(Favorites_upv_1.GetTracks(), true);
            favoritesView();
        end;
        if (AudioPlayer_upv_1.IsPlayingFavorites()) then
            clearActiveFrameFromPlaylist_upv_1();
        end;
        Parent_upv_2.Size = UDim2.new(Parent_upv_2.Size.X.Scale, Parent_upv_2.Size.X.Offset, 0, Parent_upv_2.UIListLayout.AbsoluteContentSize.Y);
    end
);
SearchText_upv_1.FocusLost:Connect(
    function(a1)
        --[[
          line: 542
          upvalues:
            SearchText_upv_1 (copy, index: 1)
            Sound_upv_1 (copy, index: 2)
            Tracks_upv_1 (copy, index: 3)
            UpdateTracksV2_upv_1 (copy, index: 4)
            PlaylistFrame_upv_1 (copy, index: 5)
            Parent_upv_2 (copy, index: 6)
        ]]
        if (a1) then
            local v30 = SearchText_upv_1.Text:match("^%d+$") ~= nil;
            local v31, v31;
            v31 = v30 and Sound_upv_1.Search(SearchText_upv_1.Text) or Tracks_upv_1.search(SearchText_upv_1.Text);
            v30 = true;
            for _, v32 in pairs(v31) do
                v30 = false;
                break;
            end;
            if ((v30)) then
                return;
            end;
            UpdateTracksV2_upv_1(v31, false);
            PlaylistFrame_upv_1.Visible = false;
            Parent_upv_2.Size = UDim2.new(Parent_upv_2.Size.X.Scale, Parent_upv_2.Size.X.Offset, 0, Parent_upv_2.UIListLayout.AbsoluteContentSize.Y);
        end;
    end
);
SearchButton_upv_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 554
          upvalues:
            Sound_upv_1 (copy, index: 1)
            MarketplaceService_upv_1 (copy, index: 2)
            LocalPlayer_upv_1 (copy, index: 3)
            AudioPlayer_upv_1 (copy, index: 4)
            SearchText_upv_1 (copy, index: 5)
            HeaderTitle_upv_1 (copy, index: 6)
            ExpandCollapseButton_upv_1 (copy, index: 7)
            ToggleFavoritesButton_upv_1 (copy, index: 8)
            SearchButton_upv_1 (copy, index: 9)
            u2 (copy, index: 10)
            Parent_upv_2 (copy, index: 11)
        ]]
        if (Sound_upv_1.IsOwner()) then
            AudioPlayer_upv_1.ToggleSearch();
            local v33 = AudioPlayer_upv_1.IsSearchActive();
            SearchText_upv_1.Visible = v33;
            HeaderTitle_upv_1.Visible = not v33;
            ExpandCollapseButton_upv_1.Visible = not v33;
            ToggleFavoritesButton_upv_1.Visible = not v33;
            SearchButton_upv_1.Image = (v33 and (u2.close)) or (u2.search);
            if (AudioPlayer_upv_1.IsSearchActive()) then
                searchView();
                Parent_upv_2.Size = UDim2.new(Parent_upv_2.Size.X.Scale, Parent_upv_2.Size.X.Offset, 0, Parent_upv_2.UIListLayout.AbsoluteContentSize.Y);
            else
                AudioPlayer_upv_1.SetAudioPlayerState(AudioPlayer_upv_1.AudioPlayerSize());
            end;
        else
            MarketplaceService_upv_1:PromptPurchase(LocalPlayer_upv_1, Sound_upv_1.UgcItemId());
        end;
    end
);
Playlists_upv_1.Selected:Connect(
    function(a1)
        --[[
          line: 583
          upvalues:
            AudioPlayer_upv_1 (copy, index: 1)
            Playlists_upv_1 (copy, index: 2)
            UpdateTracksV2_upv_1 (copy, index: 3)
        ]]
        AudioPlayer_upv_1.ToggleSearch(false);
        UpdateTracksV2_upv_1(Playlists_upv_1.GetTracks(a1), false);
    end
);
NextControl_upv_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 589
          upvalues:
            Sound_upv_1 (copy, index: 1)
            AudioPlayer_upv_1 (copy, index: 2)
        ]]
        Sound_upv_1.PlayBySoundId((AudioPlayer_upv_1.NextTrack(Sound_upv_1.GetActive().id)));
    end
);
PlaybackControl_upv_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 595
          upvalues:
            Sound_upv_1 (copy, index: 1)
        ]]
        local v34 = Sound_upv_1.IsOwner();
        if (not v34) then
            return;
        end;
        if (Sound_upv_1.IsPlaying()) then
            Sound_upv_1.Pause();
        elseif (Sound_upv_1.IsPaused()) then
            Sound_upv_1.Resume();
        end;
    end
);
function ToggleSoundModeControl()
    --[[
      name: ToggleSoundModeControl
      line: 610
      upvalues:
        u4 (copy, index: 1)
        VolumeBar_upv_1 (copy, index: 2)
    ]]
    if (not u4.enableSoundModeToggle) then
        return;
    end;
    VolumeBar_upv_1.Size = UDim2.new(0, 240, 0, 3);
end;
VolumeBar_upv_1.Size = UDim2.new(0, 265, 0, 3);
Volume_1.VolumeUp.MouseButton1Click:Connect(
    function()
        --[[
          line: 620
          upvalues:
            Sound_upv_1 (copy, index: 1)
        ]]
        Sound_upv_1.VolumeUp();
    end
);
Volume_1.VolumeDown.MouseButton1Click:Connect(
    function()
        --[[
          line: 624
          upvalues:
            Sound_upv_1 (copy, index: 1)
        ]]
        Sound_upv_1.VolumeDown();
    end
);
PlayerOwnershipUpdated_1.OnClientEvent:Connect(
    function(a1)
        --[[
          line: 639
          upvalues:
            u4 (copy, index: 1)
            Parent_upv_2 (copy, index: 2)
            MessageFrame_upv_1 (copy, index: 3)
        ]]
        if (not a1) then
            return;
        end;
        if (u4.enableSoundModeToggle) then
            ToggleSoundModeControl();
        end;
        Parent_upv_2.PlayingFrame.Visible = true;
        MessageFrame_upv_1.Visible = false;
    end
);
MessageFrame_upv_1.Promo.PromoButton.MouseButton1Click:Connect(
    function()
        --[[
          line: 646
          upvalues:
            Sound_upv_1 (copy, index: 1)
            MarketplaceService_upv_1 (copy, index: 2)
            LocalPlayer_upv_1 (copy, index: 3)
        ]]
        if (Sound_upv_1.IsOwner()) then
            return;
        end;
        MarketplaceService_upv_1:PromptPurchase(LocalPlayer_upv_1, Sound_upv_1.UgcItemId());
    end
);
local function UpdatePlaylists_upv_1(a1)
    --[[
      name: UpdatePlaylists
      line: 184
      upvalues:
        PlaylistFrame_upv_1 (copy, index: 1)
        u1 (copy, index: 2)
        u2 (copy, index: 3)
        u3 (copy, index: 4)
        u4 (copy, index: 5)
        Sound_upv_1 (copy, index: 6)
        clearActiveFrameFromPlaylist_upv_1 (copy, index: 7)
        applyActiveFrameToPlaylist_upv_1 (copy, index: 8)
        Playlists_upv_1 (copy, index: 9)
        MarketplaceService_upv_1 (copy, index: 10)
        LocalPlayer_upv_1 (copy, index: 11)
    ]]
    for _, value_4 in ipairs(PlaylistFrame_upv_1:GetChildren()) do
        if (value_4:IsA("Frame")) then
            value_4:Destroy();
        end;
    end;
    if (#a1 ~= 0) then
        local v35 = nil;
        local v36 = nil;
        local v37 = nil;
        local v38 = nil;
        local v39 = nil;
        for key_2, value_upv_5 in pairs(a1) do
            v35 = Instance.new("Frame");
            v35.Parent = PlaylistFrame_upv_1;
            v35.Name = value_upv_5.id;
            v35.Size = UDim2.new(1, 0, 0, 80);
            v36 = Instance.new("ImageButton");
            v36.Parent = v35;
            v36.BackgroundTransparency = 1;
            v37 = Instance.new("ImageLabel");
            v37.Parent = v36;
            v37.BackgroundTransparency = 0;
            if (value_upv_5.unlocked) then
                v37.Image = "rbxassetid://" .. value_upv_5.image;
            else
                v37.Image = u2.lockedPlaylist;
            end;
            v37.Size = UDim2.new(1, 0, 1, 0);
            v35.BackgroundColor3 = Color3.fromHex(u1.highlight);
            v36.Size = UDim2.new(1, 0, 1, 0);
            v37.Position = UDim2.new(0, 0, 0, 0);
            v38 = Instance.new("UICorner");
            v38.CornerRadius = UDim.new(0, u3.cornerRadiusSmall);
            v38.Parent = v35;
            v39 = Instance.new("UICorner");
            v39.CornerRadius = UDim.new(0, u3.cornerRadiusSmall);
            v39.Parent = v37;
            if (not (value_upv_5.unlocked)) then
                v36.MouseButton1Click:Connect(
                    function()
                        --[[
                          line: 259
                          upvalues:
                            MarketplaceService_upv_1 (copy, index: 1)
                            LocalPlayer_upv_1 (copy, index: 2)
                            Sound_upv_1 (copy, index: 3)
                        ]]
                        MarketplaceService_upv_1:PromptPurchase(LocalPlayer_upv_1, Sound_upv_1.UgcItemId());
                    end
                );
                continue;
            end;
            if ((u4.autoPlay) and key_2 == 1 and not Sound_upv_1.Playing()) then
                clearActiveFrameFromPlaylist_upv_1();
                applyActiveFrameToPlaylist_upv_1(value_upv_5.id);
                Playlists_upv_1.Play(value_upv_5.id);
            end;
            v36.MouseButton1Click:Connect(
                function()
                    --[[
                      line: 251
                      upvalues:
                        Sound_upv_1 (copy, index: 1)
                        clearActiveFrameFromPlaylist_upv_1 (copy, index: 2)
                        applyActiveFrameToPlaylist_upv_1 (copy, index: 3)
                        value_upv_5 (copy, index: 4)
                        Playlists_upv_1 (copy, index: 5)
                    ]]
                    local v40 = Sound_upv_1.IsOwner();
                    if (not v40) then
                        return;
                    end;
                    clearActiveFrameFromPlaylist_upv_1();
                    applyActiveFrameToPlaylist_upv_1(value_upv_5.id);
                    Playlists_upv_1.Play(value_upv_5.id);
                end
            );
        end;
    else
        local v41 = Instance.new("Frame");
        v41.Parent = PlaylistFrame_upv_1;
        v41.Size = UDim2.new(1, 0, 0, 80);
        v41.BackgroundTransparency = 1;
        local v42 = Instance.new("TextLabel");
        v42.Parent = v41;
        v42.Text = "No Results";
        v42.BackgroundTransparency = 1;
        v42.TextColor3 = Color3.fromHex(u1.white);
    end;
end;
UpdatePlaylists_upv_1(Playlists_upv_1.GetPlaylists());
AudioPlayer_upv_1.SetAudioPlayerState(AudioPlayer_upv_1.AudioPlayerSize());
script.Parent.Visible = u4.visibleOnLoad;
Playlists_upv_1.Unlocked:Connect(
    function()
        --[[
          line: 658
          upvalues:
            UpdatePlaylists_upv_1 (copy, index: 1)
            Playlists_upv_1 (copy, index: 2)
            applyActiveFrameToPlaylist_upv_1 (copy, index: 3)
            Sound_upv_1 (copy, index: 4)
        ]]
        UpdatePlaylists_upv_1(Playlists_upv_1.GetPlaylists());
        local v43 = Playlists_upv_1.GetActive();
        if (not v43) then
            return;
        end;
        if (v43.unlocked) then
            applyActiveFrameToPlaylist_upv_1(v43.id);
        else
            Playlists_upv_1.ClearActivePlaylist();
            Sound_upv_1.Stop();
        end;
    end
);
if (Sound_upv_1.IsOwner()) then
    Parent_upv_2.PlayingFrame.Visible = true;
    MessageFrame_upv_1.Visible = false;
else
    Parent_upv_2.PlayingFrame.Visible = false;
    MessageFrame_upv_1.Visible = true;
    MessageFrame_upv_1.Promo.Visible = true;
end;