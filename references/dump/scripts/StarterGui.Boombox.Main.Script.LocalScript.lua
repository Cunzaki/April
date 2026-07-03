-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

script.Parent.Visible = false;

local function isNumeric(p1) -- Line: 4
    return p1:match("^%d+$") ~= nil;
end;

local function tableIsEmpty(p2) -- Line: 8
    local v3, v4, v5;
    v3, v4, v5 = pairs(p2);
    local v6, v7, v8;

    if type(v3) == "function" then
        v6, v7 = v3(v4, v8);
    else
        v6, v7 = next(v3, v8);
    end;

    v8 = v6;

    return false;
end;

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local MarketplaceService = game:GetService("MarketplaceService");
local FavoriteStatusFunction = ReplicatedStorage:WaitForChild("FavoriteStatusFunction");
local FavoriteTrackFunction = ReplicatedStorage:WaitForChild("FavoriteTrackFunction");
ReplicatedStorage:WaitForChild("FavoriteIdsFunction");
local FavoriteChangedEvent = ReplicatedStorage:WaitForChild("FavoriteChangedEvent");
local PlayerOwnershipUpdated = ReplicatedStorage:WaitForChild("PlayerOwnershipUpdated");
local LocalPlayer = game.Players.LocalPlayer;
local Parent = script.Parent.Parent;
local RelicsXYZ = Parent:WaitForChild("RelicsXYZ");
local Tracks = require(RelicsXYZ.Tracks);
local Sound = require(RelicsXYZ.Sound);
local Playlists = require(RelicsXYZ.Playlists);
local Favorites = require(RelicsXYZ.Favorites);
local Constants = require(RelicsXYZ.Constants);
local AudioPlayer = require(RelicsXYZ.AudioPlayer);
local u9 = Constants.GetColors();
local u10 = Constants.GetImages();
local u11 = Constants.GetElements();
local u12 = Constants.GetOptions();
local Parent2 = script.Parent;
local PlaylistFrame = Parent2.PlaylistFrame;
local Main = Parent2.PlayingFrame.Main;
local Volume = Parent2.PlayingFrame.Volume;
local HeaderFrame = Parent2.HeaderFrame;
local TracksFrame = Parent2.TracksFrame;
local MessageFrame = Parent2.MessageFrame;
local Title = Main.Playing.Title;
local Artist = Main.Playing.Artist;
local PlayingImage = Main.PlayingImage;
local NoImageFrame = Main.NoImageFrame;
local PlaybackControl = Main.Controls.PlaybackControl;
local NextControl = Main.Controls.NextControl;
local ExpandControl = Main.Controls.ExpandControl;
local FavoriteControl = Main.Controls.FavoriteControl;
local VolumeBar = Volume.VolumeBar;
local _ = Volume.VolumeBar.VolumeGreen;
local VolumeUp = Volume.VolumeUp;
local VolumeDown = Volume.VolumeDown;
local UIGridLayout = PlaylistFrame.UIGridLayout;
local HeaderTitle = HeaderFrame.HeaderTitle;
local SearchText = HeaderFrame.SearchText;
local SearchButton = HeaderFrame.SearchButton;
local ExpandCollapseButton = HeaderFrame.ExpandCollapseButton;
local ToggleFavoritesButton = HeaderFrame.ToggleFavoritesButton;
local UICorner = Instance.new("UICorner");
UICorner.CornerRadius = UDim.new(0, u11.cornerRadiusLarge);
UICorner.Parent = Parent2;
Parent2.BackgroundColor3 = Color3.fromHex(u9.primary);
local UICorner2 = Instance.new("UICorner");
UICorner2.CornerRadius = UDim.new(0, u11.cornerRadiusLarge);
UICorner2.Parent = Parent2.PlayingFrame;
Parent2.PlayingFrame.BackgroundColor3 = Color3.fromHex(u9.secondary);
Parent.ResetOnSpawn = false;

local function canPlayAudio() -- Line: 96
    -- upvalues: Sound (copy)
    return Sound.IsOwner() and true or false;
end;

local function updateParentFrameHeight() -- Line: 102
    -- upvalues: Parent2 (copy)
    Parent2.Size = UDim2.new(Parent2.Size.X.Scale, Parent2.Size.X.Offset, 0, Parent2.UIListLayout.AbsoluteContentSize.Y);
end;

function minimizedView()
    -- upvalues: ExpandCollapseButton (copy), u10 (copy), HeaderFrame (copy), TracksFrame (copy), PlaylistFrame (copy), ExpandControl (copy)
    ExpandCollapseButton.Image = u10.expand;
    HeaderFrame.Visible = false;
    TracksFrame.Visible = false;
    PlaylistFrame.Visible = false;
    ExpandControl.Visible = true;
end;

function playlistView()
    -- upvalues: ExpandCollapseButton (copy), u10 (copy), HeaderFrame (copy), TracksFrame (copy), PlaylistFrame (copy), ExpandControl (copy)
    ExpandCollapseButton.Image = u10.collapse;
    HeaderFrame.Visible = true;
    TracksFrame.Visible = false;
    PlaylistFrame.Visible = true;
    ExpandControl.Visible = false;
end;

function fullView()
    -- upvalues: ExpandCollapseButton (copy), u10 (copy), HeaderFrame (copy), TracksFrame (copy), PlaylistFrame (copy), ExpandControl (copy)
    ExpandCollapseButton.Image = u10.collapse;
    HeaderFrame.Visible = true;
    TracksFrame.Visible = true;
    PlaylistFrame.Visible = true;
    ExpandControl.Visible = false;
end;

function searchView()
    -- upvalues: HeaderFrame (copy), TracksFrame (copy), PlaylistFrame (copy), ExpandControl (copy)
    HeaderFrame.Visible = true;
    TracksFrame.Visible = true;
    PlaylistFrame.Visible = false;
    ExpandControl.Visible = false;
end;

function favoritesView()
    -- upvalues: HeaderFrame (copy), TracksFrame (copy), PlaylistFrame (copy), ExpandControl (copy)
    HeaderFrame.Visible = true;
    TracksFrame.Visible = true;
    PlaylistFrame.Visible = false;
    ExpandControl.Visible = false;
end;

AudioPlayer.SizeUpdate:Connect(function(p13) -- Line: 147
    -- upvalues: Parent2 (copy)
    if p13 == "minimized" then
        minimizedView();
    elseif p13 == "playlist" then
        playlistView();
    elseif p13 == "full" then
        fullView();
    end;

    Parent2.Size = UDim2.new(Parent2.Size.X.Scale, Parent2.Size.X.Offset, 0, Parent2.UIListLayout.AbsoluteContentSize.Y);
end);

local function applyActiveFrameToPlaylist(p14) -- Line: 157
    -- upvalues: PlaylistFrame (copy)
    local v15 = PlaylistFrame:FindFirstChild(p14);

    if v15 then
        local ImageButton = v15:FindFirstChild("ImageButton");
        local v16;

        if ImageButton then
            v16 = ImageButton:FindFirstChild("ImageLabel");
        else
            v16 = ImageButton;
        end;

        if ImageButton and v16 then
            ImageButton.Size = UDim2.new(1, -4, 1, -4);
            v16.Position = UDim2.new(0, 2, 0, 2);
        end;
    end;
end;

local function clearActiveFrameFromPlaylist() -- Line: 171
    -- upvalues: PlaylistFrame (copy)
    for _, child in ipairs(PlaylistFrame:GetChildren()) do
        if child:IsA("Frame") then
            local ImageButton = child:FindFirstChild("ImageButton");

            if ImageButton then
                local ImageLabel = ImageButton:FindFirstChild("ImageLabel");
                ImageButton.Size = UDim2.new(1, 0, 1, 0);
                ImageLabel.Position = UDim2.new(0, 0, 0, 0);
            end;
        end;
    end;
end;

local function UpdatePlaylists(p17) -- Line: 184
    -- upvalues: PlaylistFrame (copy), u9 (copy), u10 (copy), u11 (copy), u12 (copy), Sound (copy), clearActiveFrameFromPlaylist (copy), applyActiveFrameToPlaylist (copy), Playlists (copy), MarketplaceService (copy), LocalPlayer (copy)
    for _, child in ipairs(PlaylistFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy();
        end;
    end;

    if #p17 ~= 0 then
        for i, v in pairs(p17) do
            local Frame = Instance.new("Frame");
            Frame.Parent = PlaylistFrame;
            Frame.Name = v.id;
            Frame.Size = UDim2.new(1, 0, 0, 80);
            local ImageButton = Instance.new("ImageButton");
            ImageButton.Parent = Frame;
            ImageButton.BackgroundTransparency = 1;
            local ImageLabel = Instance.new("ImageLabel");
            ImageLabel.Parent = ImageButton;
            ImageLabel.BackgroundTransparency = 0;

            if v.unlocked then
                ImageLabel.Image = "rbxassetid://" .. v.image;
            else
                ImageLabel.Image = u10.lockedPlaylist;
            end;

            ImageLabel.Size = UDim2.new(1, 0, 1, 0);
            Frame.BackgroundColor3 = Color3.fromHex(u9.highlight);
            ImageButton.Size = UDim2.new(1, 0, 1, 0);
            ImageLabel.Position = UDim2.new(0, 0, 0, 0);
            local UICorner3 = Instance.new("UICorner");
            UICorner3.CornerRadius = UDim.new(0, u11.cornerRadiusSmall);
            UICorner3.Parent = Frame;
            local UICorner4 = Instance.new("UICorner");
            UICorner4.CornerRadius = UDim.new(0, u11.cornerRadiusSmall);
            UICorner4.Parent = ImageLabel;

            if v.unlocked then
                if u12.autoPlay and (i == 1 and not Sound.Playing()) then
                    clearActiveFrameFromPlaylist();
                    applyActiveFrameToPlaylist(v.id);
                    Playlists.Play(v.id);
                end;

                ImageButton.MouseButton1Click:Connect(function() -- Line: 251
                    -- upvalues: Sound (ref), clearActiveFrameFromPlaylist (ref), applyActiveFrameToPlaylist (ref), v (copy), Playlists (ref)
                    if Sound.IsOwner() and true or false then
                        clearActiveFrameFromPlaylist();
                        applyActiveFrameToPlaylist(v.id);
                        Playlists.Play(v.id);
                    end;
                end);
            else
                ImageButton.MouseButton1Click:Connect(function() -- Line: 259
                    -- upvalues: MarketplaceService (ref), LocalPlayer (ref), Sound (ref)
                    MarketplaceService:PromptPurchase(LocalPlayer, Sound.UgcItemId());
                end);
            end;
        end;

        return;
    end;

    local Frame = Instance.new("Frame");
    Frame.Parent = PlaylistFrame;
    Frame.Size = UDim2.new(1, 0, 0, 80);
    Frame.BackgroundTransparency = 1;
    local TextLabel = Instance.new("TextLabel");
    TextLabel.Parent = Frame;
    TextLabel.Text = "No Results";
    TextLabel.BackgroundTransparency = 1;
    TextLabel.TextColor3 = Color3.fromHex(u9.white);
end;

local function isTrackFavorited(p18) -- Line: 266
    -- upvalues: FavoriteStatusFunction (copy)
    return FavoriteStatusFunction:InvokeServer(p18);
end;

local function UpdateTracksV2(p19, u20) -- Line: 270
    -- upvalues: TracksFrame (copy), u9 (copy), u10 (copy), FavoriteStatusFunction (copy), FavoriteTrackFunction (copy), FavoriteChangedEvent (copy), Sound (copy), AudioPlayer (copy)
    for _, child in ipairs(TracksFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy();
        end;
    end;

    for i, v in pairs(p19) do
        local Frame = Instance.new("Frame");
        Frame.Parent = TracksFrame;
        Frame.Name = v.id;
        Frame.Size = UDim2.new(1, 0, 0, 40);
        Frame.BackgroundColor3 = Color3.fromHex(u9.secondary);
        Frame.BorderSizePixel = 0;
        Frame.BackgroundColor3 = i % 2 == 0 and Color3.fromHex(u9.primary) or Color3.fromHex(u9.secondary);
        local UIPadding = Instance.new("UIPadding");
        UIPadding.Parent = Frame;
        UIPadding.PaddingBottom = UDim.new(0, 5);
        UIPadding.PaddingLeft = UDim.new(0, 5);
        UIPadding.PaddingRight = UDim.new(0, 5);
        UIPadding.PaddingTop = UDim.new(0, 5);
        local UIListLayout = Instance.new("UIListLayout");
        UIListLayout.Parent = Frame;
        UIListLayout.Padding = UDim.new(0, 15);
        UIListLayout.FillDirection = Enum.FillDirection.Horizontal;
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
        UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
        local Frame2 = Instance.new("Frame");
        Frame2.Parent = Frame;
        Frame2.BackgroundTransparency = 1;
        Frame2.BorderSizePixel = 0;
        Frame2.Size = UDim2.new(0, 30, 0, 30);
        local UIListLayout2 = Instance.new("UIListLayout");
        UIListLayout2.Parent = Frame2;
        UIListLayout2.FillDirection = Enum.FillDirection.Horizontal;
        UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Right;
        UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder;
        UIListLayout2.VerticalAlignment = Enum.VerticalAlignment.Center;
        local ImageButton = Instance.new("ImageButton");
        ImageButton.Name = "PlaybackControl";
        ImageButton.Parent = Frame2;
        ImageButton.BackgroundTransparency = 1;
        ImageButton.BorderSizePixel = 0;
        ImageButton.Size = UDim2.new(0, 30, 0, 30);
        ImageButton.Image = u10.play;
        local Frame3 = Instance.new("Frame");
        Frame3.Name = "Info";
        Frame3.Parent = Frame;
        Frame3.Size = UDim2.new(0, 260, 0, 38);
        Frame3.BackgroundTransparency = 1;
        Frame3.BorderSizePixel = 0;
        local UIListLayout3 = Instance.new("UIListLayout");
        UIListLayout3.Parent = Frame3;
        UIListLayout3.Padding = UDim.new(0, 0);
        UIListLayout3.SortOrder = Enum.SortOrder.LayoutOrder;
        local TextLabel = Instance.new("TextLabel");
        TextLabel.Name = "Title";
        TextLabel.Parent = Frame3;
        TextLabel.Size = UDim2.new(0, 214, 0, 20);
        TextLabel.BackgroundTransparency = 1;
        TextLabel.BorderSizePixel = 0;
        TextLabel.TextSize = 14;
        TextLabel.FontFace.Bold = true;
        TextLabel.TextColor3 = Color3.fromHex(u9.textPrimary);
        TextLabel.FontFace = Font.fromId(12187365364);
        TextLabel.FontFace.Weight = Enum.FontWeight.Bold;
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left;
        TextLabel.Text = v.title;
        local TextLabel2 = Instance.new("TextLabel");
        TextLabel2.Name = "Artist";
        TextLabel2.Parent = Frame3;
        TextLabel2.BackgroundTransparency = 1;
        TextLabel2.BorderSizePixel = 0;
        TextLabel2.Size = UDim2.new(0, 191, 0, 15);
        TextLabel2.TextSize = 12;
        TextLabel2.TextColor3 = Color3.fromHex(u9.textSecondary);
        TextLabel2.FontFace = Font.fromId(12187365364);
        TextLabel2.FontFace.Weight = Enum.FontWeight.Regular;
        TextLabel2.TextXAlignment = Enum.TextXAlignment.Left;
        TextLabel2.Text = v.artist;
        local ImageButton2 = Instance.new("ImageButton");
        ImageButton2.Name = "Favorite";
        ImageButton2.Parent = Frame;
        ImageButton2.BackgroundTransparency = 1;
        ImageButton2.BorderSizePixel = 0;
        ImageButton2.LayoutOrder = 3;
        ImageButton2.Size = UDim2.new(0, 30, 0, 30);
        ImageButton2.Image = u10.favoriteOutline;
        ImageButton2.Image = FavoriteStatusFunction:InvokeServer(v.id) and u10.favoriteSolid or u10.favoriteOutline;
        ImageButton2.MouseButton1Click:Connect(function() -- Line: 375
            -- upvalues: FavoriteTrackFunction (ref), v (copy), ImageButton2 (copy), u10 (ref)
            ImageButton2.Image = FavoriteTrackFunction:InvokeServer(v.id) and u10.favoriteSolid or u10.favoriteOutline;
        end);
        FavoriteChangedEvent.OnClientEvent:Connect(function(p21, p22) -- Line: 381
            -- upvalues: v (copy), ImageButton2 (copy), u10 (ref)
            if p21 == v.id then
                ImageButton2.Image = p22 and u10.favoriteSolid or u10.favoriteOutline;
            end;
        end);

        local function updatePlaybackControlImage() -- Line: 388
            -- upvalues: Sound (ref), v (copy), ImageButton (copy), u10 (ref)
            if Sound.IsPlaying() and Sound.GetActive().id == v.id then
                ImageButton.Image = u10.pause;

                return;
            end;

            ImageButton.Image = u10.play;
        end;

        ImageButton.MouseButton1Click:Connect(function() -- Line: 396
            -- upvalues: Sound (ref), AudioPlayer (ref), u20 (copy), v (copy)
            local v23 = Sound.GetActive();
            AudioPlayer.ToggleSearch(u20);

            if v23.id ~= v.id and Sound.IsOwner() then
                Sound.PlayBySoundId(v.id);

                return;
            end;

            if Sound.IsPlaying() and v23.id == v.id then
                Sound.Pause();

                return;
            end;

            if not Sound.IsPaused() or v23.id ~= v.id then
                return;
            end;

            Sound.Resume();
        end);

        if Sound.IsPlaying() and Sound.GetActive().id == v.id then
            ImageButton.Image = u10.pause;
        else
            ImageButton.Image = u10.play;
        end;

        Sound.Played:Connect(updatePlaybackControlImage);
        Sound.Resumed:Connect(updatePlaybackControlImage);
        Sound.Paused:Connect(function() -- Line: 423
            -- upvalues: ImageButton (copy), u10 (ref)
            ImageButton.Image = u10.play;
        end);
    end;
end;

UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() -- Line: 429
    -- upvalues: PlaylistFrame (copy), UIGridLayout (copy)
    PlaylistFrame.CanvasSize = UDim2.new(0, UIGridLayout.AbsoluteContentSize.X, 0, UIGridLayout.AbsoluteContentSize.Y);
end);
TracksFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() -- Line: 433
    -- upvalues: TracksFrame (copy)
    TracksFrame.CanvasSize = UDim2.new(0, TracksFrame.UIListLayout.AbsoluteContentSize.X, 0, TracksFrame.UIListLayout.AbsoluteContentSize.Y);
end);
Title.Text = "Select a Mood to listen";
Artist.Text = "Start with a playlist";
SearchButton.Image = u10.search;
NextControl.Image = u10.forward;
ExpandControl.Image = u10.expand;
ExpandCollapseButton.Image = u10.collapse;
ToggleFavoritesButton.Image = u10.favoriteOutline;
FavoriteControl.Image = u10.favoriteOutline;
FavoriteControl.MouseButton1Click:Connect(function() -- Line: 446
    -- upvalues: Sound (copy), FavoriteTrackFunction (copy), FavoriteControl (copy), u10 (copy)
    FavoriteControl.Image = FavoriteTrackFunction:InvokeServer(Sound.GetActive().id) and u10.favoriteSolid or u10.favoriteOutline;
end);
FavoriteChangedEvent.OnClientEvent:Connect(function(p24, p25) -- Line: 452
    -- upvalues: Sound (copy), FavoriteControl (copy), u10 (copy)
    if Sound.GetActive().id == p24 then
        FavoriteControl.Image = p25 and u10.favoriteSolid or u10.favoriteOutline;
    end;
end);
Sound.Played:Connect(function() -- Line: 461
    -- upvalues: Sound (copy), Playlists (copy), PlaybackControl (copy), u10 (copy), NextControl (copy), FavoriteControl (copy), Title (copy), Artist (copy), PlayingImage (copy), NoImageFrame (copy), FavoriteStatusFunction (copy), AudioPlayer (copy)
    local v26 = Sound.GetActive();
    local v27 = Playlists.GetActive();
    PlaybackControl.Image = u10.pause;
    NextControl.Visible = true;
    FavoriteControl.Visible = true;
    Title.Text = v26.title or "[unknown title]";
    Artist.Text = v26.artist or "[unknown artist]";
    PlayingImage.Visible = false;
    NoImageFrame.Visible = true;
    PlayingImage.Image = "";
    FavoriteControl.Image = FavoriteStatusFunction:InvokeServer(v26.id) and u10.favoriteSolid or u10.favoriteOutline;

    if v27 and (v27.image and AudioPlayer.IsShowingFavorites() == false) then
        PlayingImage.Visible = true;
        NoImageFrame.Visible = false;
        PlayingImage.Image = "rbxassetid://" .. v27.image;
    end;
end);
Sound.Resumed:Connect(function() -- Line: 485
    -- upvalues: PlaybackControl (copy), u10 (copy)
    PlaybackControl.Image = u10.pause;
end);
Sound.Paused:Connect(function() -- Line: 489
    -- upvalues: PlaybackControl (copy), u10 (copy)
    PlaybackControl.Image = u10.play;
end);
Sound.Stopped:Connect(function() -- Line: 493
    -- upvalues: NextControl (copy), PlaybackControl (copy), u10 (copy), Title (copy), Artist (copy), clearActiveFrameFromPlaylist (copy)
    NextControl.Visible = false;
    PlaybackControl.Image = u10.play;
    Title.Text = "Select a Mood to listen";
    Artist.Text = "Start with a playlist";
    clearActiveFrameFromPlaylist();
end);
ExpandCollapseButton.MouseButton1Click:Connect(function() -- Line: 503
    -- upvalues: AudioPlayer (copy)
    AudioPlayer.SetNextAudioPlayerState();
end);
ExpandControl.MouseButton1Click:Connect(function() -- Line: 508
    -- upvalues: AudioPlayer (copy)
    AudioPlayer.SetNextAudioPlayerState();
end);
ToggleFavoritesButton.MouseButton1Click:Connect(function() -- Line: 515
    -- upvalues: ToggleFavoritesButton (copy), AudioPlayer (copy), u10 (copy), Playlists (copy), UpdateTracksV2 (copy), Favorites (copy), clearActiveFrameFromPlaylist (copy), Parent2 (copy)
    ToggleFavoritesButton.Image = not AudioPlayer.IsShowingFavorites() and u10.playlist or u10.favoriteOutline;
    local v28 = AudioPlayer.IsShowingFavorites();
    AudioPlayer.ToggleFavorites();

    if v28 and AudioPlayer.IsPlayingFavorites() == false then
        local v29 = Playlists.GetTracks();

        if v29 then
            AudioPlayer.SetAudioPlayerState(AudioPlayer.AudioPlayerSize());
            UpdateTracksV2(v29, false);
        end;
    else
        UpdateTracksV2(Favorites.GetTracks(), true);
        favoritesView();
    end;

    if AudioPlayer.IsPlayingFavorites() then
        clearActiveFrameFromPlaylist();
    end;

    Parent2.Size = UDim2.new(Parent2.Size.X.Scale, Parent2.Size.X.Offset, 0, Parent2.UIListLayout.AbsoluteContentSize.Y);
end);
SearchText.FocusLost:Connect(function(p30) -- Line: 542
    -- upvalues: SearchText (copy), Sound (copy), Tracks (copy), UpdateTracksV2 (copy), PlaylistFrame (copy), Parent2 (copy)
    if p30 then
        local v31 = SearchText.Text:match("^%d+$") ~= nil and Sound.Search(SearchText.Text) or Tracks.search(SearchText.Text);
        local v32;

        for _, _ in pairs(v31) do
            v32 = false;
            break;
        end;

        v32 = true;

        if not v32 then
            UpdateTracksV2(v31, false);
            PlaylistFrame.Visible = false;
            Parent2.Size = UDim2.new(Parent2.Size.X.Scale, Parent2.Size.X.Offset, 0, Parent2.UIListLayout.AbsoluteContentSize.Y);
        end;
    end;
end);
SearchButton.MouseButton1Click:Connect(function() -- Line: 554
    -- upvalues: Sound (copy), MarketplaceService (copy), LocalPlayer (copy), AudioPlayer (copy), SearchText (copy), HeaderTitle (copy), ExpandCollapseButton (copy), ToggleFavoritesButton (copy), SearchButton (copy), u10 (copy), Parent2 (copy)
    if not Sound.IsOwner() then
        MarketplaceService:PromptPurchase(LocalPlayer, Sound.UgcItemId());

        return;
    end;

    AudioPlayer.ToggleSearch();
    local v33 = AudioPlayer.IsSearchActive();
    SearchText.Visible = v33;
    HeaderTitle.Visible = not v33;
    ExpandCollapseButton.Visible = not v33;
    ToggleFavoritesButton.Visible = not v33;
    SearchButton.Image = v33 and u10.close or u10.search;

    if not AudioPlayer.IsSearchActive() then
        AudioPlayer.SetAudioPlayerState(AudioPlayer.AudioPlayerSize());

        return;
    end;

    searchView();
    Parent2.Size = UDim2.new(Parent2.Size.X.Scale, Parent2.Size.X.Offset, 0, Parent2.UIListLayout.AbsoluteContentSize.Y);
end);
Playlists.Selected:Connect(function(p34) -- Line: 583
    -- upvalues: AudioPlayer (copy), Playlists (copy), UpdateTracksV2 (copy)
    AudioPlayer.ToggleSearch(false);
    UpdateTracksV2(Playlists.GetTracks(p34), false);
end);
NextControl.MouseButton1Click:Connect(function() -- Line: 589
    -- upvalues: Sound (copy), AudioPlayer (copy)
    local v35 = Sound.GetActive();
    local v36 = AudioPlayer.NextTrack(v35.id);
    Sound.PlayBySoundId(v36);
end);
PlaybackControl.MouseButton1Click:Connect(function() -- Line: 595
    -- upvalues: Sound (copy)
    if not Sound.IsOwner() then
        return;
    end;

    if Sound.IsPlaying() then
        Sound.Pause();

        return;
    end;

    if not Sound.IsPaused() then
        return;
    end;

    Sound.Resume();
end);

function ToggleSoundModeControl()
    -- upvalues: u12 (copy), VolumeBar (copy)
    if u12.enableSoundModeToggle then
        VolumeBar.Size = UDim2.new(0, 240, 0, 3);
    end;
end;

VolumeBar.Size = UDim2.new(0, 265, 0, 3);
VolumeUp.MouseButton1Click:Connect(function() -- Line: 620
    -- upvalues: Sound (copy)
    Sound.VolumeUp();
end);
VolumeDown.MouseButton1Click:Connect(function() -- Line: 624
    -- upvalues: Sound (copy)
    Sound.VolumeDown();
end);
PlayerOwnershipUpdated.OnClientEvent:Connect(function(p37) -- Line: 639
    -- upvalues: u12 (copy), Parent2 (copy), MessageFrame (copy)
    if not p37 then
        return;
    end;

    if u12.enableSoundModeToggle then
        ToggleSoundModeControl();
    end;

    Parent2.PlayingFrame.Visible = true;
    MessageFrame.Visible = false;
end);
MessageFrame.Promo.PromoButton.MouseButton1Click:Connect(function() -- Line: 646
    -- upvalues: Sound (copy), MarketplaceService (copy), LocalPlayer (copy)
    if Sound.IsOwner() then
        return;
    end;

    MarketplaceService:PromptPurchase(LocalPlayer, Sound.UgcItemId());
end);
UpdatePlaylists(Playlists.GetPlaylists());
AudioPlayer.SetAudioPlayerState(AudioPlayer.AudioPlayerSize());
script.Parent.Visible = u12.visibleOnLoad;
Playlists.Unlocked:Connect(function() -- Line: 658
    -- upvalues: UpdatePlaylists (copy), Playlists (copy), applyActiveFrameToPlaylist (copy), Sound (copy)
    UpdatePlaylists(Playlists.GetPlaylists());
    local v38 = Playlists.GetActive();

    if v38 then
        if v38.unlocked then
            applyActiveFrameToPlaylist(v38.id);

            return;
        end;

        Playlists.ClearActivePlaylist();
        Sound.Stop();
    end;
end);

if Sound.IsOwner() then
    Parent2.PlayingFrame.Visible = true;
    MessageFrame.Visible = false;

    return;
end;

Parent2.PlayingFrame.Visible = false;
MessageFrame.Visible = true;
MessageFrame.Promo.Visible = true;