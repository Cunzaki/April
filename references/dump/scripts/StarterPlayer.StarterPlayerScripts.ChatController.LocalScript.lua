-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local CurrentCamera = workspace.CurrentCamera;
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
game:GetService("TweenService");
game:GetService("StarterGui");
game:GetService("SoundService");
local TextChatService = game:GetService("TextChatService");
local LocalPlayer = Players.LocalPlayer;
ReplicatedStorage:WaitForChild("Values");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local SystemMessage = ReplicatedStorage:WaitForChild("ClientSignals"):WaitForChild("SystemMessage");
local CustomCommands = TextChatService:WaitForChild("CustomCommands");
script:WaitForChild("UpdateChannel");
local UpdateFontSize = script:WaitForChild("UpdateFontSize");
local ClearChat = CustomCommands:WaitForChild("ClearChat");
local Help = CustomCommands:WaitForChild("Help");
local Whisper = CustomCommands:WaitForChild("Whisper");
local TextChannels = TextChatService:WaitForChild("TextChannels");
TextChannels:WaitForChild("RBXGeneral");
local v1 = TextChannels:WaitForChild("WHISPER/" .. tostring(LocalPlayer.UserId));
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local v2 = nil;
local u3 = nil;

while not (v2 and u3) do
    v2 = PlayerGui:FindFirstChild("Main");
    u3 = PlayerGui:FindFirstChild("CustomChat");

    if v2 and u3 then
        break;
    end;

    task.wait(0.2);
end;

local GiveBed = v2:WaitForChild("GiveBed");
v2:WaitForChild("RenameBed");
local ChatFrame = u3:WaitForChild("ChatFrame");
local MessagesFrame = ChatFrame:WaitForChild("MessagesFrame");
local TextboxFrame = ChatFrame:WaitForChild("TextboxFrame");
local TextBox = TextboxFrame:WaitForChild("TextBox");
local Channel = TextboxFrame:WaitForChild("Channel");
local Messages = MessagesFrame:WaitForChild("Messages");
local TemplateScrollFrame = MessagesFrame:WaitForChild("TemplateScrollFrame");
local t = Messages:WaitForChild("t");
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local GamepadService = game:GetService("GamepadService");
local RunService = game:GetService("RunService");
local GamepadIconModule = require(Modules:WaitForChild("GamepadIconModule"));
local PreferredInputController = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");

local function _() -- Line: 79
    -- upvalues: PreferredInputController (copy)
    local v4 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    return v4;
end;

local GamepadControls = ChatFrame:WaitForChild("GamepadControls");
local ToolTip = GamepadControls:WaitForChild("ToolTip");
local SendMessage = ToolTip:WaitForChild("SendMessage");
local CloseChat = ToolTip:WaitForChild("CloseChat");
GamepadIconModule.Register(SendMessage:FindFirstChildWhichIsA("ImageLabel"), "ButtonA");
GamepadIconModule.Register(CloseChat:FindFirstChildWhichIsA("ImageLabel"), "ButtonB");
GamepadControls.Visible = false;
local u5 = {
    Clan = true,
    Team = true,
    Global = true
};
local u6 = "Global";
local u7 = "Default";
local u8 = false;
local v9 = os.clock();
local v10 = os.clock();
local u11 = false;
local u12 = {};
local u13 = {};
local u14 = nil;

if shared.YourTeam ~= nil then
    TextChannels:FindFirstChild("TEAM/" .. tostring(shared.YourTeam));
end;

if shared.ClanInfo ~= nil then
    TextChannels:FindFirstChild("CLAN/" .. shared.ClanInfo.ClanTag);
end;

local function _(p15) -- Line: 128
    -- upvalues: u5 (copy), ChatFrame (copy)
    local v16 = u5[p15];

    if v16 == nil then
        return;
    end;

    local v17 = ChatFrame:FindFirstChild("Button" .. p15);

    if not v17 then
        return;
    end;

    u5[p15] = not v16;
    v17.Text = u5[p15] and "X" or "";
end;

local function u19(p18) -- Line: 137
    -- upvalues: ChatFrame (copy)
    for _, child in ChatFrame:GetChildren() do
        if child.Name:find("Button") then
            child.Visible = p18;
        end;
    end;
end;

local function _() -- Line: 145
    -- upvalues: u6 (ref)
    u6 = u6 == "Global" and "Team" or (u6 == "Team" and "Clan" or (u6 == "Clan" and "Global" or "Global"));

    return u6;
end;

local function u22(p20) -- Line: 160
    -- upvalues: u3 (ref)
    local v21 = u3:GetAttribute("Color" .. (p20:find("RBXGeneral") and "Global" or (p20:find("CLAN/") and "Clan" or (p20:find("TEAM/") and "Team" or (p20:find("WHISPER/") and "Whisper" or p20))))):split(", ");

    return v21 and Color3.fromRGB(v21[1], v21[2], v21[3]) or Color3.fromRGB(153, 153, 153);
end;

local function u25() -- Line: 176
    -- upvalues: t (copy), u12 (copy), TextBox (copy)
    local v23 = 1;

    for i = 18, 1, -1 do
        t.TextSize = i;

        if t.TextFits then
            v23 = i;
            break;
        end;

        task.wait();
    end;

    local v24 = 1;

    for _, v in u12 do
        v24 = v24 + 1;

        if v24 >= 5 then
            task.wait();
            v24 = 1;
        end;

        local Gui = v.Gui;

        if Gui then
            Gui.TextSize = v23;
            print("assigned font size " .. v23);
        end;
    end;

    TextBox.TextSize = v23;
end;

local function u27() -- Line: 210
    -- upvalues: TemplateScrollFrame (copy), Messages (copy), u7 (ref), u12 (copy), u11 (ref)
    local AbsoluteSize = TemplateScrollFrame:FindFirstChild("t").AbsoluteSize;

    for _, child in Messages:GetChildren() do
        if child:IsA("TextLabel") and child.Name == "m" then
            child.Size = UDim2.new(0, AbsoluteSize.X, 0, AbsoluteSize.Y);
        end;
    end;

    if u7 == "Default" then
        Messages.CanvasSize = UDim2.new(0, 0, 1, 0);
        Messages.ScrollBarImageTransparency = 1;
        Messages.CanvasPosition = Vector2.new(0, 0);

        return;
    end;

    local Offset = Messages:FindFirstChild("UIListLayout").Padding.Offset;
    local v26 = #u12 * AbsoluteSize.Y + (#u12 * Offset - Offset);
    Messages.CanvasSize = UDim2.new(0, 0, 0, v26);
    Messages.ScrollBarImageTransparency = 0.6;

    if u11 then
        u11 = false;
        Messages.CanvasPosition = Vector2.new(0, v26);
    end;
end;

local function u28() -- Line: 238
    -- upvalues: u12 (copy), u7 (ref)
    for _, v in u12 do
        if v.Time and v.Gui then
            if u7 == "Default" then
                v.Gui.Visible = os.clock() - v.Time < 15;
            else
                v.Gui.Visible = true;
            end;
        end;
    end;
end;

local function u31() -- Line: 250
    -- upvalues: u12 (copy)
    local v29 = 1;

    for i = 25, 1, -1 do
        local v30 = u12[i];

        if v30 and v30.Gui then
            v30.Gui.LayoutOrder = v29;
            v29 = v29 + 1;
        end;
    end;
end;

local function _() -- Line: 263
    -- upvalues: u28 (copy), u27 (copy), u31 (copy)
    u28();
    u27();
    u31();
end;

local function u33() -- Line: 272
    -- upvalues: u12 (copy)
    if #u12 >= 26 then
        for i = 26, #u12 do
            local v32 = u12[i];

            if v32 and v32.Gui ~= nil then
                v32.Gui:Destroy();
            end;

            table.remove(u12, i);
        end;
    end;
end;

local function u39(p34) -- Line: 284
    -- upvalues: u22 (copy), t (copy), Messages (copy), u12 (copy), u33 (copy), u28 (copy), u27 (copy), u31 (copy)
    local v35 = u22("System");
    local v36 = "<font color=\"rgb(" .. math.ceil(v35.R * 255) .. ", " .. math.ceil(v35.G * 255) .. ", " .. math.ceil(v35.B * 255) .. ")\"><b>";
    local v37 = t:Clone();
    v37.Name = "m";
    v37.Text = v36 .. "SYSTEM" .. "</b></font>: " .. p34;

    if not v37:FindFirstChild("ImageLabel") then
        return;
    end;

    v37.ImageLabel.Visible = false;
    v37.Visible = true;
    v37.Parent = Messages;
    local v38 = {
        Gui = v37,
        Time = os.clock()
    };
    table.insert(u12, 1, v38);
    u33();
    u28();
    u27();
    u31();
end;

local function u41(p40) -- Line: 372
    -- upvalues: u7 (ref), u11 (ref), u28 (copy), u27 (copy), u31 (copy), TextBox (copy), u19 (copy), TextboxFrame (copy), UserInputService (copy)
    script:SetAttribute("Typing", true);
    u7 = "Expanded";
    u11 = true;
    u28();
    u27();
    u31();
    TextBox.Text = p40 == "Command" and "/" or "";
    task.wait();
    u19(true);
    TextboxFrame.Visible = true;
    TextBox:CaptureFocus();
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
    UserInputService.MouseIconEnabled = true;
end;

local function _() -- Line: 386
    -- upvalues: u19 (copy), u7 (ref), TextboxFrame (copy), TextBox (copy), UserInputService (copy), u28 (copy), u27 (copy), u31 (copy)
    script:SetAttribute("Typing", false);
    u19(false);
    u7 = "Default";
    TextboxFrame.Visible = false;
    TextBox:ReleaseFocus();
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    u28();
    u27();
    u31();
end;

local function _() -- Line: 397
    -- upvalues: u41 (copy), u6 (ref), PreferredInputController (copy), GamepadService (copy), GamepadControls (copy)
    u41(u6);
    local v42 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    if v42 then
        pcall(function() -- Line: 400
            -- upvalues: GamepadService (ref)
            GamepadService:EnableGamepadCursor(nil);
        end);
        GamepadControls.Visible = true;
    end;
end;

local function _() -- Line: 405
    -- upvalues: u19 (copy), u7 (ref), TextboxFrame (copy), TextBox (copy), UserInputService (copy), u28 (copy), u27 (copy), u31 (copy), GamepadService (copy), GamepadControls (copy)
    script:SetAttribute("Typing", false);
    u19(false);
    u7 = "Default";
    TextboxFrame.Visible = false;
    TextBox:ReleaseFocus();
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    u28();
    u27();
    u31();
    pcall(function() -- Line: 407
        -- upvalues: GamepadService (ref)
        GamepadService:DisableGamepadCursor();
    end);
    GamepadControls.Visible = false;
end;

local function u47() -- Line: 411
    -- upvalues: u7 (ref), TextBox (copy), u19 (copy), TextboxFrame (copy), UserInputService (copy), u28 (copy), u27 (copy), u31 (copy), GamepadService (copy), GamepadControls (copy), u8 (ref), TextChannels (copy), LocalPlayer (copy), u6 (ref), u39 (copy)
    u7 = "Default";
    local v43 = true;

    for _, v in TextBox.Text:split("") do
        if v ~= " " then
            v43 = false;
            break;
        end;
    end;

    if v43 or TextBox.Text == "" then
        script:SetAttribute("Typing", false);
        u19(false);
        u7 = "Default";
        TextboxFrame.Visible = false;
        TextBox:ReleaseFocus();
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
        u28();
        u27();
        u31();
        pcall(function() -- Line: 407
            -- upvalues: GamepadService (ref)
            GamepadService:DisableGamepadCursor();
        end);
        GamepadControls.Visible = false;

        return;
    end;

    local v44 = nil;
    local v45 = TextBox.Text:sub(1, 120);
    TextBox.Text = v45;

    if u8 then
        v44 = TextChannels:FindFirstChild("WHISPER/" .. LocalPlayer.UserId);
        script:SetAttribute("Typing", false);
        u19(false);
        u7 = "Default";
        TextboxFrame.Visible = false;
        TextBox:ReleaseFocus();
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
        u28();
        u27();
        u31();
        pcall(function() -- Line: 407
            -- upvalues: GamepadService (ref)
            GamepadService:DisableGamepadCursor();
        end);
        GamepadControls.Visible = false;
    elseif u6 == "Global" then
        v44 = TextChannels:FindFirstChild("RBXGeneral");
    elseif u6 == "Team" then
        local YourTeam = shared.YourTeam;

        if YourTeam then
            v44 = TextChannels:FindFirstChild("TEAM/" .. YourTeam);
        else
            u39("Failed to send message. You are not currently in a team");
        end;
    elseif u6 == "Clan" then
        local v46 = LocalPlayer:GetAttribute("ClanTag");

        if v46 then
            v44 = TextChannels:FindFirstChild("CLAN/" .. v46);
        else
            u39("Failed to send message. You are not currently in a clan");
        end;
    end;

    if v44 then
        v44:SendAsync(v45);
        script:SetAttribute("Typing", false);
        u19(false);
        u7 = "Default";
        TextboxFrame.Visible = false;
        TextBox:ReleaseFocus();
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
        u28();
        u27();
        u31();
        pcall(function() -- Line: 407
            -- upvalues: GamepadService (ref)
            GamepadService:DisableGamepadCursor();
        end);
        GamepadControls.Visible = false;

        return;
    end;

    warn("[ChatController] - Failed to send message, no text channel found?");
    script:SetAttribute("Typing", false);
    u19(false);
    u7 = "Default";
    TextboxFrame.Visible = false;
    TextBox:ReleaseFocus();
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
    UserInputService.MouseIconEnabled = false;
    u28();
    u27();
    u31();
    pcall(function() -- Line: 407
        -- upvalues: GamepadService (ref)
        GamepadService:DisableGamepadCursor();
    end);
    GamepadControls.Visible = false;
end;

CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() -- Line: 458
    -- upvalues: u25 (copy)
    u25();
end);
TextBox:GetPropertyChangedSignal("Text"):Connect(function() -- Line: 462
    -- upvalues: u8 (ref), TextBox (copy), Channel (copy), u6 (ref), u22 (copy)
    u8 = TextBox.Text:sub(1, 1) == "/";
    Channel.Text = u8 and "COMMAND" or string.upper(u6);
    local v48;

    if u8 then
        v48 = u22("System");
    else
        v48 = u22(u6);
    end;

    Channel.TextColor3 = v48;
    TextBox.Text = TextBox.Text:sub(1, 120);
end);

local function u62(p49, p50) -- Line: 309
    -- upvalues: Players (copy), u22 (copy), u13 (copy), t (copy), Messages (copy), u12 (copy), u33 (copy), u28 (copy), u27 (copy), u31 (copy)
    if not p49.TextSource then
        return;
    end;

    if p49.Text:sub(1, 1) == "/" then
        return;
    end;

    p49.Text = p49.Text:sub(1, 120);
    local UserId = p49.TextSource.UserId;
    local u51 = Players:GetPlayerByUserId(UserId);

    if not u51 then
        warn("[ChatController] - Insert message failed, no sending player?");

        return;
    end;

    local v52 = "";

    if UserId then
        local v53 = not u51:GetAttribute("HideTag");
        v52 = u51:GetAttribute("Owner") and v53 and "<font color=\"rgb(0,157,255)\">[🛠️OWNER]</font> " or (u51:GetAttribute("Admin") and v53 and "<font color=\"rgb(255,102,0)\">[🔧ADMIN]</font> " or (u51:GetAttribute("Mod") and v53 and "<font color=\"rgb(255,84,84)\">[🔨MOD]</font> " or (u51:GetAttribute("VIP") and "<font color=\"rgb(255,200,0)\">[VIP]</font> " or v52)));

        if u51:GetAttribute("ClanTag") then
            local v54 = u51:GetAttribute("ClanColor") or Color3.new(1, 1, 1);
            v52 = `<font color="rgb({math.round(v54.R * 255)},{math.round(v54.G * 255)},{math.round(v54.B * 255)})">[{u51:GetAttribute("ClanTag")}]</font> ` .. v52;
        end;
    end;

    local v55;

    if u51.Team then
        v55 = u51.Team.TeamColor.Color;
    else
        v55 = u22(p49.TextChannel.Name);
    end;

    local v56 = "<font color=\"rgb(" .. math.ceil(v55.R * 255) .. ", " .. math.ceil(v55.G * 255) .. ", " .. math.ceil(v55.B * 255) .. ")\"><b>";
    local u57 = u13[u51.UserId];
    pcall(function() -- Line: 339
        -- upvalues: u57 (ref), Players (ref), u51 (copy), u13 (ref)
        if u57 then
            u57 = u57.Thumbnail;

            return;
        end;

        u57 = Players:GetUserThumbnailAsync(u51.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
        u13[u51.UserId] = {
            Thumbnail = u57,
            Time = os.clock()
        };
    end);
    local v58 = t:Clone();
    local ImageLabel = v58:FindFirstChild("ImageLabel");

    if not ImageLabel then
        return;
    end;

    local UIStroke = ImageLabel:FindFirstChild("UIStroke");

    if UIStroke then
        local v59 = p49.TextChannel.Name:find("RBXGeneral");
        local v60 = u51:GetAttribute("ClanColor");

        if v59 then
            if v60 == nil then
                v60 = v55;
            end;
        else
            v60 = v55;
        end;

        UIStroke.Color = v60;
    end;

    ImageLabel.Image = (not u57 or typeof(u57) ~= "string") and "" or u57;
    ImageLabel.Visible = u57 and true or false;
    v58.Name = "m";
    v58.Text = v52 .. v56 .. u51.DisplayName .. "</b></font>: " .. p49.Text;
    v58.Visible = true;
    v58.Parent = Messages;
    local v61 = {
        Gui = v58,
        Time = os.clock()
    };
    table.insert(u12, 1, v61);
    u33();
    u28();
    u27();
    u31();
end;

for _, child in ChatFrame:GetChildren() do
    if child.Name:find("Button") then
        child.MouseButton1Click:Connect(function() -- Line: 474
            -- upvalues: child (copy), u5 (copy), ChatFrame (copy)
            local v63 = child.Name:gsub("Button", "");

            if u5[v63] == nil then
                return;
            end;

            local v64 = u5[v63];

            if v64 == nil then
                return;
            end;

            local v65 = ChatFrame:FindFirstChild("Button" .. v63);

            if not v65 then
                return;
            end;

            u5[v63] = not v64;
            v65.Text = u5[v63] and "X" or "";
        end);
    end;
end;

TextChatService.MessageReceived:Connect(function(p66) -- Line: 483
    -- upvalues: u62 (copy)
    u62(p66);
end);

function v1.OnIncomingMessage(p67) -- Line: 488
    -- upvalues: u62 (copy)
    if p67.Status == Enum.TextChatMessageStatus.Success then
        return;
    end;

    u62(p67);
end;

UpdateFontSize.Event:Connect(function() -- Line: 493
    -- upvalues: u25 (copy)
    u25();
end);
SystemMessage.OnClientEvent:Connect(function(p68) -- Line: 552
    -- upvalues: u39 (copy)
    if not p68 then
        return;
    end;

    u39(p68);
end);
UserInputService.InputBegan:Connect(function(p69, p70) -- Line: 557
    -- upvalues: SettingsModule (copy), u3 (ref), u47 (copy), u41 (copy), u6 (ref), GiveBed (copy), UserInputService (copy), u19 (copy), u7 (ref), TextboxFrame (copy), TextBox (copy), u28 (copy), u27 (copy), u31 (copy), GamepadService (copy), GamepadControls (copy), u14 (ref), RunService (copy), PreferredInputController (copy)
    if SettingsModule.MainMenuOpen() or not u3.Enabled then
        return;
    end;

    local UserInputType = p69.UserInputType;

    if UserInputType == Enum.UserInputType.Keyboard then
        local v71 = SettingsModule.GetSetting("Controls", "Start Typing");

        if p69.KeyCode == Enum.KeyCode.Return and script:GetAttribute("Typing") then
            u47();

            return;
        end;

        if p69.KeyCode.Name == SettingsModule.GetSetting("Controls", "Switch Channels") then
            if not script:GetAttribute("Typing") then
                return;
            end;

            task.wait();
            u6 = u6 == "Global" and "Team" or (u6 == "Team" and "Clan" or (u6 == "Clan" and "Global" or "Global"));
            u41(u6);

            return;
        end;

        if p69.KeyCode.Name == SettingsModule.GetSetting("Controls", "Start Command") and not script:GetAttribute("Typing") then
            u41("Command");

            return;
        end;

        if p69.KeyCode.Name == v71 then
            if GiveBed.Visible or tick() - (shared.LastTextBoxFocused or 0) <= 0.1 then
                return;
            end;

            if script:GetAttribute("Typing") then
                return;
            end;

            if p69.KeyCode.Name ~= v71 then
                return;
            end;

            local _, result = pcall(function() -- Line: 578
                -- upvalues: UserInputService (ref), u3 (ref)
                local v72 = UserInputService:GetFocusedTextBox();

                if v72 and not v72:IsDescendantOf(u3) then
                    return true;
                end;
            end);

            if result then
                return;
            end;

            u41(u6);
        end;
    elseif UserInputType == Enum.UserInputType.Gamepad1 then
        local Name = p69.KeyCode.Name;

        if Name == "ButtonB" and script:GetAttribute("Typing") then
            script:SetAttribute("Typing", false);
            u19(false);
            u7 = "Default";
            TextboxFrame.Visible = false;
            TextBox:ReleaseFocus();
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService.MouseIconEnabled = false;
            u28();
            u27();
            u31();
            pcall(function() -- Line: 407
                -- upvalues: GamepadService (ref)
                GamepadService:DisableGamepadCursor();
            end);
            GamepadControls.Visible = false;

            return;
        end;

        if Name == "ButtonA" and script:GetAttribute("Typing") then
            u47();

            return;
        end;

        if Name == SettingsModule.GetSetting("Gamepad", "Open Map") and not script:GetAttribute("Typing") then
            u14 = tick();
            task.spawn(function() -- Line: 593
                -- upvalues: u14 (ref), RunService (ref), u41 (ref), u6 (ref), PreferredInputController (ref), GamepadService (ref), GamepadControls (ref)
                while u14 and tick() - u14 < 1.2 do
                    RunService.Heartbeat:Wait();
                end;

                if u14 and tick() - u14 >= 1.2 then
                    u14 = nil;
                    u41(u6);
                    local v73 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

                    if v73 then
                        pcall(function() -- Line: 400
                            -- upvalues: GamepadService (ref)
                            GamepadService:EnableGamepadCursor(nil);
                        end);
                        GamepadControls.Visible = true;
                    end;
                end;
            end);
        end;
    end;
end);
UserInputService.InputEnded:Connect(function(p74) -- Line: 606
    -- upvalues: SettingsModule (copy), u14 (ref)
    if p74.UserInputType == Enum.UserInputType.Gamepad1 and p74.KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Open Map") then
        u14 = nil;
    end;
end);
PreferredInputController:GetAttributeChangedSignal("PreferredInput"):Connect(function() -- Line: 613
    -- upvalues: PreferredInputController (copy), GamepadService (copy), GamepadControls (copy)
    if not script:GetAttribute("Typing") then
        return;
    end;

    local v75 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    if v75 then
        pcall(function() -- Line: 616
            -- upvalues: GamepadService (ref)
            GamepadService:EnableGamepadCursor(nil);
        end);
        GamepadControls.Visible = true;

        return;
    end;

    pcall(function() -- Line: 619
        -- upvalues: GamepadService (ref)
        GamepadService:DisableGamepadCursor();
    end);
    GamepadControls.Visible = false;
end);
ClearChat.Triggered:Connect(function() -- Line: 626
    -- upvalues: u12 (copy), u28 (copy), u27 (copy), u31 (copy)
    for _, v in u12 do
        if v.Gui then
            v.Gui:Destroy();
        end;
    end;

    table.clear(u12);
    u28();
    u27();
    u31();
end);
Help.Triggered:Connect(function() -- Line: 637
    -- upvalues: CustomCommands (copy), u39 (copy)
    for _, child in CustomCommands:GetChildren() do
        if child:GetAttribute("Help") ~= "Hide" then
            u39("" .. child.PrimaryAlias .. (child.SecondaryAlias ~= "" and (" or " .. child.SecondaryAlias or "") or "") .. " - " .. child:GetAttribute("Help"));
        end;
    end;

    u39("/help Success, all commands listed above");
end);
Whisper.Triggered:Connect(function(p76, p77) -- Line: 648
    -- upvalues: Players (copy), TextChannels (copy)
    local v78 = p77:split(" ");
    local v79 = v78[2];
    local v80;

    for _, v80 in Players:GetChildren() do
        if v80.Name ~= v79 and v80.DisplayName ~= v79 then
            v80 = nil;
        end;

        break;
    end;

    v80 = nil;

    if not v80 then
        return;
    end;

    local v81 = "";

    for i = 3, #v78 do
        v81 = v81 .. v78[i] .. " ";
    end;

    local v82 = TextChannels:FindFirstChild("WHISPER/" .. v80.UserId);

    if not v82 then
        return;
    end;

    print(v81);
    v82:SendAsync(v81);
end);
u25();

while true do
    u3.Enabled = not SettingsModule.GetSetting("General", "Hide Chat");

    if os.clock() - v9 >= 20 then
        v9 = os.clock();

        for i, v in pairs(u13) do
            if os.clock() - v.Time >= 240 then
                table.remove(u13, i);
            end;
        end;
    end;

    if os.clock() - v10 >= 0.8 then
        v10 = os.clock();
        u28();
        u27();
        u31();
    end;

    task.wait(0.2);
end;