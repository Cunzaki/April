-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_upv_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local UserInputService_upv_1 = game:GetService("UserInputService");
local _ = game:GetService("TweenService");
local v42 = game:GetService("StarterGui");
local v43 = game:GetService("SoundService");
local TextChatService_1 = game:GetService("TextChatService");
local LocalPlayer_upv_1 = Players_upv_1.LocalPlayer;
local v44 = ReplicatedStorage_1:WaitForChild("Values");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local SystemMessage_1 = ReplicatedStorage_1:WaitForChild("ClientSignals"):WaitForChild("SystemMessage");
local CustomCommands_upv_1 = TextChatService_1:WaitForChild("CustomCommands");
local v45 = script:WaitForChild("UpdateChannel");
local UpdateFontSize_1 = script:WaitForChild("UpdateFontSize");
local ClearChat_1 = CustomCommands_upv_1:WaitForChild("ClearChat");
local Help_1 = CustomCommands_upv_1:WaitForChild("Help");
local Whisper_1 = CustomCommands_upv_1:WaitForChild("Whisper");
local TextChannels_upv_1 = TextChatService_1:WaitForChild("TextChannels");
local v46 = TextChannels_upv_1:WaitForChild("RBXGeneral");
local v1 = TextChannels_upv_1:WaitForChild("WHISPER/" .. tostring(LocalPlayer_upv_1.UserId));
local PlayerGui_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui");
local v2 = nil;
local CustomChat_upv_1 = nil;
v2 = v2;
if (v2 and CustomChat_upv_1) then
    local GiveBed_upv_1 = v2:WaitForChild("GiveBed");
    local v47 = v2:WaitForChild("RenameBed");
    local ChatFrame_upv_1 = CustomChat_upv_1:WaitForChild("ChatFrame");
    local MessagesFrame_1 = ChatFrame_upv_1:WaitForChild("MessagesFrame");
    local TextboxFrame_upv_1 = ChatFrame_upv_1:WaitForChild("TextboxFrame");
    local TextBox_upv_1 = TextboxFrame_upv_1:WaitForChild("TextBox");
    local Channel_upv_1 = TextboxFrame_upv_1:WaitForChild("Channel");
    local Messages_upv_1 = MessagesFrame_1:WaitForChild("Messages");
    local TemplateScrollFrame_upv_1 = MessagesFrame_1:WaitForChild("TemplateScrollFrame");
    local t_upv_1 = Messages_upv_1:WaitForChild("t");
    local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
    local GamepadService_upv_1 = game:GetService("GamepadService");
    local RunService_upv_1 = game:GetService("RunService");
    local GamepadIconModule_1 = require(Modules_1:WaitForChild("GamepadIconModule"));
    local PreferredInputController_upv_1 = LocalPlayer_upv_1:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
    local GamepadControls_upv_1 = ChatFrame_upv_1:WaitForChild("GamepadControls");
    local ToolTip_1 = GamepadControls_upv_1:WaitForChild("ToolTip");
    local SendMessage_1 = ToolTip_1:WaitForChild("SendMessage");
    local CloseChat_1 = ToolTip_1:WaitForChild("CloseChat");
    GamepadIconModule_1.Register(SendMessage_1:FindFirstChildWhichIsA("ImageLabel"), "ButtonA");
    GamepadIconModule_1.Register(CloseChat_1:FindFirstChildWhichIsA("ImageLabel"), "ButtonB");
    GamepadControls_upv_1.Visible = false;
    local tbl_upv_1 = {};
    tbl_upv_1.Clan = true;
    tbl_upv_1.Team = true;
    tbl_upv_1.Global = true;
    local u1 = "Global";
    local u2 = "Default";
    local v48 = false;
    local v3 = os.clock();
    local v4 = os.clock();
    local u3 = false;
    local tbl_upv_2 = {};
    local tbl_upv_3 = {};
    local u4 = nil;
    if (shared.YourTeam ~= nil) then
        local v49 = TextChannels_upv_1:FindFirstChild("TEAM/" .. tostring(shared.YourTeam));
    end;
    local u5, u5;
    if (shared.ClanInfo ~= nil) then
        local v50 = TextChannels_upv_1:FindFirstChild("CLAN/" .. shared.ClanInfo.ClanTag);
    end;
    local u6;
    local u6 = function(a1)
        --[[
          line: 160
          upvalues:
            CustomChat_upv_1 (ref, index: 1)
        ]]
        local v5 = ((a1:find("RBXGeneral")) and "Global") or (((a1:find("CLAN/")) and "Clan") or (((a1:find("TEAM/")) and "Team") or ((a1:find("WHISPER/") and "Whisper") or a1)));
        local v6 = CustomChat_upv_1:GetAttribute("Color" .. v5):split(", ");
        local v7 = (v6 and (Color3.fromRGB(v6[1], v6[2], v6[3]))) or (Color3.fromRGB(153, 153, 153));
        return v7;
    end;
    local u7;
    local u7 = function()
        --[[
          line: 210
          upvalues:
            TemplateScrollFrame_upv_1 (copy, index: 1)
            Messages_upv_1 (copy, index: 2)
            u2 (ref,  index: 3)
            tbl_upv_2 (copy, index: 4)
            u5 (ref,  index: 5)
        ]]
        local AbsoluteSize_1 = TemplateScrollFrame_upv_1:FindFirstChild("t").AbsoluteSize;
        for _, value_1 in Messages_upv_1:GetChildren() do
            if (not (value_1:IsA("TextLabel"))) then
                continue;
            end;
            if (value_1.Name == "m") then
                value_1.Size = UDim2.new(0, AbsoluteSize_1.X, 0, AbsoluteSize_1.Y);
            end;
        end;
        if (u2 ~= "Default") then
            local Offset_1 = Messages_upv_1:FindFirstChild("UIListLayout").Padding.Offset;
            local v8 = #tbl_upv_2 * AbsoluteSize_1.Y + ((#tbl_upv_2 * Offset_1) - Offset_1);
            Messages_upv_1.CanvasSize = UDim2.new(0, 0, 0, v8);
            Messages_upv_1.ScrollBarImageTransparency = 0.6;
            if (u5) then
                u5 = false;
                Messages_upv_1.CanvasPosition = Vector2.new(0, v8);
            end;
        else
            Messages_upv_1.CanvasSize = UDim2.new(0, 0, 1, 0);
            Messages_upv_1.ScrollBarImageTransparency = 1;
            Messages_upv_1.CanvasPosition = Vector2.new(0, 0);
        end;
    end;
    local u8;
    local u8 = function()
        --[[
          line: 238
          upvalues:
            tbl_upv_2 (copy, index: 1)
            u2 (ref,  index: 2)
        ]]
        for _, value_2 in tbl_upv_2 do
            if (not (value_2.Time) or not (value_2.Gui)) then
                continue;
            end;
            if (u2 ~= "Default") then
                value_2.Gui.Visible = true;
            else
                local Gui_1 = value_2.Gui;
                Gui_1.Visible = os.clock() - value_2.Time < 15;
            end;
        end;
    end;
    local u9;
    local u9 = function()
        --[[
          line: 272
          upvalues:
            tbl_upv_2 (copy, index: 1)
        ]]
        if (#tbl_upv_2 < 26) then
            return;
        end;
        for n_1 = 26, #tbl_upv_2 do
            local v10;
            v10 = tbl_upv_2[n_1];
            if ((v10) and v10.Gui ~= nil) then
                v10.Gui:Destroy();
            end;
            table.remove(tbl_upv_2, n_1);
        end;
    end;
    local u10;
    local u10 = function()
        --[[
          line: 250
          upvalues:
            tbl_upv_2 (copy, index: 1)
        ]]
        local v11 = 1;
        for n_2 = 25, 1, -1 do
            local v12;
            v12 = tbl_upv_2[n_2];
            if (not (v12)) then
                continue;
            end;
            if (v12.Gui) then
                v12.Gui.LayoutOrder = v11;
                v11 = v11 + 1;
            end;
        end;
    end;
    local u11;
    local u11 = function(a1, a2)
        --[[
          line: 309
          upvalues:
            Players_upv_1 (copy, index: 1)
            u6 (copy, index: 2)
            tbl_upv_3 (copy, index: 3)
            t_upv_1 (copy, index: 4)
            Messages_upv_1 (copy, index: 5)
            tbl_upv_2 (copy, index: 6)
            u9 (copy, index: 7)
            u8 (copy, index: 8)
            u7 (copy, index: 9)
            u10 (copy, index: 10)
        ]]
        if (a1.TextSource) then
            local u12;
            if (a1.Text:sub(1, 1) ~= "/") then
                a1.Text = a1.Text:sub(1, 120);
                local UserId_1 = a1.TextSource.UserId;
                u12 = Players_upv_1:GetPlayerByUserId(UserId_1);
                local v13 = nil;
                if (u12) then
                    local v14 = "";
                    local v15 = nil;
                    local v18 = nil;
                    if (UserId_1) then
                        v18 = not u12:GetAttribute("HideTag");
                        if ((u12:GetAttribute("Owner")) and (v18)) then
                            v14 = "<font color=\"rgb(0,157,255)\">[\240\159\155\160\239\184\143OWNER]</font> ";
                        elseif ((u12:GetAttribute("Admin")) and (v18)) then
                            v14 = "<font color=\"rgb(255,102,0)\">[\240\159\148\167ADMIN]</font> ";
                        elseif ((u12:GetAttribute("Mod")) and (v18)) then
                            v14 = "<font color=\"rgb(255,84,84)\">[\240\159\148\168MOD]</font> ";
                        else
                            v14 = (u12:GetAttribute("VIP") and "<font color=\"rgb(255,200,0)\">[VIP]</font> ") or v14;
                        end;
                        v15 = u12:GetAttribute("ClanTag");
                        if (v15) then
                            local v17 = u12:GetAttribute("ClanColor") or Color3.new(1, 1, 1);
                            v14 = ("<font color=\"rgb(%*,%*,%*)\">[%*]</font> "):format(math.round(v17.R * 255), math.round(v17.G * 255), math.round(v17.B * 255), u12:GetAttribute("ClanTag")) .. v14;
                        end;
                    end;
                    if (u12.Team) then
                        v18 = u12.Team.TeamColor.Color;
                    else
                        v18 = u6(a1.TextChannel.Name);
                    end;
                    local v19 = "<font color=\"rgb(" .. math.ceil(v18.R * 255) .. ", " .. math.ceil(v18.G * 255) .. ", " .. math.ceil(v18.B * 255) .. ")\"><b>";
                    local u13 = tbl_upv_3[u12.UserId];
                    pcall(
                        function()
                            --[[
                              line: 339
                              upvalues:
                                u13 (ref,  index: 1)
                                Players_upv_1 (copy, index: 2)
                                u12 (copy, index: 3)
                                tbl_upv_3 (copy, index: 4)
                            ]]
                            if (u13) then
                                local _ = u13.Thumbnail;
                            else
                                u13 = Players_upv_1:GetUserThumbnailAsync(u12.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
                                tbl_upv_3[u12.UserId] = {Thumbnail = u13, Time = os.clock()};
                            end;
                        end
                    );
                    local v20 = t_upv_1:Clone();
                    v13 = v20:FindFirstChild("ImageLabel");
                    local v21 = nil;
                    if (v13) then
                        v21 = v13:FindFirstChild("UIStroke");
                        local v22 = nil;
                        if (v21) then
                            v22 = a1.TextChannel.Name:find("RBXGeneral");
                            local v23 = u12:GetAttribute("ClanColor");
                            local v24;
                            if ((v22) and v23 ~= nil) then
                                v24 = v23;
                            else
                                v24 = v18;
                            end;
                            v21.Color = v24;
                        end;
                        u13 = (u13) and typeof(u13) == "string" or "";
                        v13.Image = u13;
                        v13.Visible = true;
                        v20.Name = "m";
                        v20.Text = v14 .. v19 .. u12.DisplayName .. "</b></font>: " .. a1.Text;
                        v20.Visible = true;
                        v20.Parent = Messages_upv_1;
                        table.insert(tbl_upv_2, 1, {Gui = v20, Time = os.clock()});
                        u9();
                        u8();
                        u7();
                        u10();
                    end;
                else
                    warn("[ChatController] - Insert message failed, no sending player?");
                end;
            end;
        end;
    end;
    local u14;
    local u14 = function(a1)
        --[[
          line: 137
          upvalues:
            ChatFrame_upv_1 (copy, index: 1)
        ]]
        local value_3 = nil;
        for _, value_3 in ChatFrame_upv_1:GetChildren() do
            if (value_3.Name:find("Button")) then
                value_3.Visible = a1;
            end;
        end;
    end;
    local u15;
    local u15 = function(a1)
        --[[
          line: 372
          upvalues:
            u2 (ref,  index: 1)
            u5 (ref,  index: 2)
            u8 (copy, index: 3)
            u7 (copy, index: 4)
            u10 (copy, index: 5)
            TextBox_upv_1 (copy, index: 6)
            u14 (copy, index: 7)
            TextboxFrame_upv_1 (copy, index: 8)
            UserInputService_upv_1 (copy, index: 9)
        ]]
        script:SetAttribute("Typing", true);
        u2 = "Expanded";
        u5 = true;
        u8();
        u7();
        u10();
        TextBox_upv_1.Text = ((a1 ~= "Command") and "") or "/";
        task.wait();
        u14(true);
        TextboxFrame_upv_1.Visible = true;
        TextBox_upv_1:CaptureFocus();
        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService_upv_1.MouseIconEnabled = true;
    end;
    local u16;
    local u16 = function(a1)
        --[[
          line: 284
          upvalues:
            u6 (copy, index: 1)
            t_upv_1 (copy, index: 2)
            Messages_upv_1 (copy, index: 3)
            tbl_upv_2 (copy, index: 4)
            u9 (copy, index: 5)
            u8 (copy, index: 6)
            u7 (copy, index: 7)
            u10 (copy, index: 8)
        ]]
        local v25 = u6("System");
        local v26 = "<font color=\"rgb(" .. math.ceil(v25.R * 255) .. ", " .. math.ceil(v25.G * 255) .. ", " .. math.ceil(v25.B * 255) .. ")\"><b>";
        local v27 = t_upv_1:Clone();
        v27.Name = "m";
        v27.Text = v26 .. "SYSTEM" .. "</b></font>: " .. a1;
        if (not v27:FindFirstChild("ImageLabel")) then
            return;
        end;
        v27.ImageLabel.Visible = false;
        v27.Visible = true;
        v27.Parent = Messages_upv_1;
        table.insert(tbl_upv_2, 1, {Gui = v27, Time = os.clock()});
        u9();
        u8();
        u7();
        u10();
    end;
    local u17;
    local u17 = function()
        --[[
          line: 411
          upvalues:
            u2 (ref,  index: 1)
            TextBox_upv_1 (copy, index: 2)
            u14 (copy, index: 3)
            TextboxFrame_upv_1 (copy, index: 4)
            UserInputService_upv_1 (copy, index: 5)
            u8 (copy, index: 6)
            u7 (copy, index: 7)
            u10 (copy, index: 8)
            GamepadService_upv_1 (copy, index: 9)
            GamepadControls_upv_1 (copy, index: 10)
            u3 (ref,  index: 11)
            TextChannels_upv_1 (copy, index: 12)
            LocalPlayer_upv_1 (copy, index: 13)
            u1 (ref,  index: 14)
            u16 (copy, index: 15)
        ]]
        u2 = "Default";
        local v28 = true;
        for _, value_4 in TextBox_upv_1.Text:split("") do
            if (value_4 ~= " ") then
                v28 = false;
                break;
            end;
        end;
        if (not (v28) and TextBox_upv_1.Text ~= "") then
            local v29 = nil;
            local v30 = TextBox_upv_1.Text:sub(1, 120);
            TextBox_upv_1.Text = v30;
            local v31;
            if (u3) then
                local v32 = TextChannels_upv_1:FindFirstChild("WHISPER/" .. LocalPlayer_upv_1.UserId);
                script:SetAttribute("Typing", false);
                u14(false);
                u2 = "Default";
                TextboxFrame_upv_1.Visible = false;
                TextBox_upv_1:ReleaseFocus();
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                UserInputService_upv_1.MouseIconEnabled = false;
                u8();
                u7();
                u10();
                pcall(
                    function()
                        --[[
                          line: 407
                          upvalues:
                            GamepadService_upv_1 (copy, index: 1)
                        ]]
                        GamepadService_upv_1:DisableGamepadCursor();
                    end
                );
                GamepadControls_upv_1.Visible = false;
                v31 = v32;
            elseif (u1 ~= "Global") then
                local v33 = nil;
                if (u1 == "Team") then
                    v33 = shared.YourTeam;
                    if (v33) then
                        v31 = TextChannels_upv_1:FindFirstChild("TEAM/" .. v33);
                    else
                        u16("Failed to send message. You are not currently in a team");
                        v31 = v29;
                    end;
                elseif (u1 ~= "Clan") then
                    v31 = v29;
                else
                    v33 = LocalPlayer_upv_1:GetAttribute("ClanTag");
                    if (v33) then
                        v31 = TextChannels_upv_1:FindFirstChild("CLAN/" .. v33);
                    else
                        u16("Failed to send message. You are not currently in a clan");
                        v31 = v29;
                    end;
                end;
            else
                v31 = TextChannels_upv_1:FindFirstChild("RBXGeneral");
            end;
            if (v31) then
                v31:SendAsync(v30);
                script:SetAttribute("Typing", false);
                u14(false);
                u2 = "Default";
                TextboxFrame_upv_1.Visible = false;
                TextBox_upv_1:ReleaseFocus();
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                UserInputService_upv_1.MouseIconEnabled = false;
                u8();
                u7();
                u10();
                pcall(
                    function()
                        --[[
                          line: 407
                          upvalues:
                            GamepadService_upv_1 (copy, index: 1)
                        ]]
                        GamepadService_upv_1:DisableGamepadCursor();
                    end
                );
            else
                warn("[ChatController] - Failed to send message, no text channel found?");
                script:SetAttribute("Typing", false);
                u14(false);
                u2 = "Default";
                TextboxFrame_upv_1.Visible = false;
                TextBox_upv_1:ReleaseFocus();
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                UserInputService_upv_1.MouseIconEnabled = false;
                u8();
                u7();
                u10();
                pcall(
                    function()
                        --[[
                          line: 407
                          upvalues:
                            GamepadService_upv_1 (copy, index: 1)
                        ]]
                        GamepadService_upv_1:DisableGamepadCursor();
                    end
                );
            end;
            GamepadControls_upv_1.Visible = false;
            return;
        end;
        script:SetAttribute("Typing", false);
        u14(false);
        u2 = "Default";
        TextboxFrame_upv_1.Visible = false;
        TextBox_upv_1:ReleaseFocus();
        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService_upv_1.MouseIconEnabled = false;
        u8();
        u7();
        u10();
        pcall(
            function()
                --[[
                  line: 407
                  upvalues:
                    GamepadService_upv_1 (copy, index: 1)
                ]]
                GamepadService_upv_1:DisableGamepadCursor();
            end
        );
        GamepadControls_upv_1.Visible = false;
    end;
    local u18;
    local u18 = function()
        --[[
          line: 176
          upvalues:
            t_upv_1 (copy, index: 1)
            tbl_upv_2 (copy, index: 2)
            TextBox_upv_1 (copy, index: 3)
        ]]
        local v34 = 1;
        for n_3 = 18, 1, -1 do
            t_upv_1.TextSize = n_3;
            if (t_upv_1.TextFits) then
                v34 = n_3;
                break;
            else
                task.wait();
            end;
        end;
        local v36 = 1;
        local v37 = nil;
        local v38 = nil;
        for _, value_5 in tbl_upv_2 do
            v37 = v36 + 1;
            if (v37 < 5) then
                v36 = v37;
            else
                task.wait();
                v36 = 1;
            end;
            v38 = value_5.Gui;
            if (v38) then
                v38.TextSize = v34;
                print("assigned font size " .. v34);
            end;
        end;
        TextBox_upv_1.TextSize = v34;
    end;
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(
        function()
            --[[
              line: 458
              upvalues:
                u18 (copy, index: 1)
            ]]
            u18();
        end
    );
    TextBox_upv_1:GetPropertyChangedSignal("Text"):Connect(
        function()
            --[[
              line: 462
              upvalues:
                u3 (ref,  index: 1)
                TextBox_upv_1 (copy, index: 2)
                Channel_upv_1 (copy, index: 3)
                u1 (ref,  index: 4)
                u6 (copy, index: 5)
            ]]
            local v39 = TextBox_upv_1.Text:sub(1, 1) == "/";
            u3 = v39;
            local v40 = (u3 and "COMMAND") or (string.upper(u1));
            Channel_upv_1.Text = v40;
            if (v39) then
                v40 = u6("System");
            else
                v40 = u6(u1);
            end;
            Channel_upv_1.TextColor3 = v40;
            TextBox_upv_1.Text = TextBox_upv_1.Text:sub(1, 120);
        end
    );
    local v41 = nil;
    for v51, value_upv_6 in ChatFrame_upv_1:GetChildren() do
        v41 = value_upv_6.Name:find("Button");
        if (v41) then
            value_upv_6.MouseButton1Click:Connect(
                function()
                    --[[
                      line: 474
                      upvalues:
                        value_upv_6 (copy, index: 1)
                        tbl_upv_1 (copy, index: 2)
                        ChatFrame_upv_1 (copy, index: 3)
                    ]]
                    local v42 = value_upv_6.Name:gsub("Button", "");
                    local v43 = nil;
                    if (tbl_upv_1[v42] ~= nil) then
                        v43 = tbl_upv_1[v42];
                        local v44;
                        if (v43 == nil) then
                            return;
                        end;
                        v44 = ChatFrame_upv_1:FindFirstChild("Button" .. v42);
                        if (not v44) then
                            return;
                        end;
                        tbl_upv_1[v42] = not v43;
                        v44.Text = ((tbl_upv_1[v42]) and "X") or "";
                    end;
                end
            );
        end;
    end;
    TextChatService_1.MessageReceived:Connect(
        function(a1)
            --[[
              line: 483
              upvalues:
                u11 (copy, index: 1)
            ]]
            u11(a1);
        end
    );
    v1.OnIncomingMessage = function(a1)
        --[[
          line: 488
          upvalues:
            u11 (copy, index: 1)
        ]]
        if (a1.Status == Enum.TextChatMessageStatus.Success) then
            return;
        end;
        u11(a1);
    end;
    UpdateFontSize_1.Event:Connect(
        function()
            --[[
              line: 493
              upvalues:
                u18 (copy, index: 1)
            ]]
            u18();
        end
    );
    SystemMessage_1.OnClientEvent:Connect(
        function(a1)
            --[[
              line: 552
              upvalues:
                u16 (copy, index: 1)
            ]]
            if (not a1) then
                return;
            end;
            u16(a1);
        end
    );
    UserInputService_upv_1.InputBegan:Connect(
        function(a1, a2)
            --[[
              line: 557
              upvalues:
                SettingsModule_upv_1 (copy, index: 1)
                CustomChat_upv_1 (ref,  index: 2)
                u17 (copy, index: 3)
                u15 (copy, index: 4)
                u1 (ref,  index: 5)
                GiveBed_upv_1 (copy, index: 6)
                UserInputService_upv_1 (copy, index: 7)
                u14 (copy, index: 8)
                u2 (ref,  index: 9)
                TextboxFrame_upv_1 (copy, index: 10)
                TextBox_upv_1 (copy, index: 11)
                u8 (copy, index: 12)
                u7 (copy, index: 13)
                u10 (copy, index: 14)
                GamepadService_upv_1 (copy, index: 15)
                GamepadControls_upv_1 (copy, index: 16)
                u4 (ref,  index: 17)
                RunService_upv_1 (copy, index: 18)
                PreferredInputController_upv_1 (copy, index: 19)
            ]]
            if (not (SettingsModule_upv_1.MainMenuOpen())) then
                local v45;
                if (not CustomChat_upv_1.Enabled) then
                    return;
                end;
                v45 = a1.UserInputType;
                if (v45 ~= Enum.UserInputType.Keyboard) then
                    local v46 = nil;
                    if (v45 == Enum.UserInputType.Gamepad1) then
                        v46 = a1.KeyCode.Name;
                        if (v46 == "ButtonB" and script:GetAttribute("Typing")) then
                            script:SetAttribute("Typing", false);
                            u14(false);
                            u2 = "Default";
                            TextboxFrame_upv_1.Visible = false;
                            TextBox_upv_1:ReleaseFocus();
                            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                            UserInputService_upv_1.MouseIconEnabled = false;
                            u8();
                            u7();
                            u10();
                            pcall(
                                function()
                                    --[[
                                      line: 407
                                      upvalues:
                                        GamepadService_upv_1 (copy, index: 1)
                                    ]]
                                    GamepadService_upv_1:DisableGamepadCursor();
                                end
                            );
                            GamepadControls_upv_1.Visible = false;
                            return;
                        end;
                        if (v46 == "ButtonA" and script:GetAttribute("Typing")) then
                            u17();
                            return;
                        end;
                        if (v46 == SettingsModule_upv_1.GetSetting("Gamepad", "Open Map") and not (script:GetAttribute("Typing"))) then
                            u4 = tick();
                            task.spawn(
                                function()
                                    --[[
                                      line: 593
                                      upvalues:
                                        u4 (ref,  index: 1)
                                        RunService_upv_1 (copy, index: 2)
                                        u15 (copy, index: 3)
                                        u1 (ref,  index: 4)
                                        PreferredInputController_upv_1 (copy, index: 5)
                                        GamepadService_upv_1 (copy, index: 6)
                                        GamepadControls_upv_1 (copy, index: 7)
                                    ]]
                                    while (u4 and tick() - u4 < 1.2) do
                                        RunService_upv_1.Heartbeat:Wait();
                                    end;
                                    if (not u4) then
                                        return;
                                    end;
                                    if (tick() - u4 >= 1.2) then
                                        u4 = nil;
                                        u15(u1);
                                        local v47 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                                        if (not v47) then
                                            return;
                                        end;
                                        pcall(
                                            function()
                                                --[[
                                                  line: 400
                                                  upvalues:
                                                    GamepadService_upv_1 (copy, index: 1)
                                                ]]
                                                GamepadService_upv_1:EnableGamepadCursor(nil);
                                            end
                                        );
                                        GamepadControls_upv_1.Visible = true;
                                    end;
                                end
                            );
                        end;
                    end;
                else
                    local v48 = SettingsModule_upv_1.GetSetting("Controls", "Start Typing");
                    local _;
                    if (a1.KeyCode == Enum.KeyCode.Return and script:GetAttribute("Typing")) then
                        u17();
                        return;
                    end;
                    if (a1.KeyCode.Name ~= SettingsModule_upv_1.GetSetting("Controls", "Switch Channels")) then
                        if (a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Controls", "Start Command") and not (script:GetAttribute("Typing"))) then
                            u15("Command");
                            return;
                        end;
                        if (a1.KeyCode.Name == v48) then
                            if (not (GiveBed_upv_1.Visible) and tick() - (shared.LastTextBoxFocused or 0) > 0.1) then
                                if (not script:GetAttribute("Typing")) then
                                    local v49 = nil;
                                    if (a1.KeyCode.Name == v48) then
                                        _, v49 = pcall(
                                            function()
                                                --[[
                                                  line: 578
                                                  upvalues:
                                                    UserInputService_upv_1 (copy, index: 1)
                                                    CustomChat_upv_1 (ref,  index: 2)
                                                ]]
                                                local v50 = UserInputService_upv_1:GetFocusedTextBox();
                                                if (v50 and not (v50:IsDescendantOf(CustomChat_upv_1))) then
                                                    return true;
                                                end;
                                            end
                                        );
                                        if (not v49) then
                                            u15(u1);
                                        end;
                                    end;
                                end;
                                return;
                            end;
                            return;
                        end;
                    else
                        if (script:GetAttribute("Typing")) then
                            task.wait();
                            local v51 = "Global";
                            if (u1 == "Global") then
                                v51 = "Team";
                            elseif (u1 == "Team") then
                                v51 = "Clan";
                            elseif (u1 == "Clan") then
                                v51 = "Global";
                            end;
                            u1 = v51;
                            u15(u1);
                        end;
                        return;
                    end;
                end;
            end;
        end
    );
    UserInputService_upv_1.InputEnded:Connect(
        function(a1)
            --[[
              line: 606
              upvalues:
                SettingsModule_upv_1 (copy, index: 1)
                u4 (ref,  index: 2)
            ]]
            if (a1.UserInputType ~= Enum.UserInputType.Gamepad1 or a1.KeyCode.Name ~= SettingsModule_upv_1.GetSetting("Gamepad", "Open Map")) then
                return;
            end;
            u4 = nil;
        end
    );
    PreferredInputController_upv_1:GetAttributeChangedSignal("PreferredInput"):Connect(
        function()
            --[[
              line: 613
              upvalues:
                PreferredInputController_upv_1 (copy, index: 1)
                GamepadService_upv_1 (copy, index: 2)
                GamepadControls_upv_1 (copy, index: 3)
            ]]
            if (script:GetAttribute("Typing")) then
                local v52 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                if (v52) then
                    pcall(
                        function()
                            --[[
                              line: 616
                              upvalues:
                                GamepadService_upv_1 (copy, index: 1)
                            ]]
                            GamepadService_upv_1:EnableGamepadCursor(nil);
                        end
                    );
                    GamepadControls_upv_1.Visible = true;
                else
                    pcall(
                        function()
                            --[[
                              line: 619
                              upvalues:
                                GamepadService_upv_1 (copy, index: 1)
                            ]]
                            GamepadService_upv_1:DisableGamepadCursor();
                        end
                    );
                    GamepadControls_upv_1.Visible = false;
                end;
            end;
        end
    );
    ClearChat_1.Triggered:Connect(
        function()
            --[[
              line: 626
              upvalues:
                tbl_upv_2 (copy, index: 1)
                u8 (copy, index: 2)
                u7 (copy, index: 3)
                u10 (copy, index: 4)
            ]]
            for _, value_7 in tbl_upv_2 do
                if (value_7.Gui) then
                    value_7.Gui:Destroy();
                end;
            end;
            table.clear(tbl_upv_2);
            u8();
            u7();
            u10();
        end
    );
    Help_1.Triggered:Connect(
        function()
            --[[
              line: 637
              upvalues:
                CustomCommands_upv_1 (copy, index: 1)
                u16 (copy, index: 2)
            ]]
            local v53 = nil;
            local v54 = nil;
            local PrimaryAlias_1 = nil;
            for _, value_8 in CustomCommands_upv_1:GetChildren() do
                if (value_8:GetAttribute("Help") == "Hide") then
                    continue;
                end;
                v54 = value_8.SecondaryAlias ~= "";
                PrimaryAlias_1 = value_8.PrimaryAlias;
                if (not (v54)) then
                    v53 = "";
                    u16("" .. PrimaryAlias_1 .. v53 .. " - " .. value_8:GetAttribute("Help"));
                    continue;
                end;
                v53 = " or " .. value_8.SecondaryAlias or "";
                u16("" .. PrimaryAlias_1 .. v53 .. " - " .. value_8:GetAttribute("Help"));
            end;
            u16("/help Success, all commands listed above");
        end
    );
    Whisper_1.Triggered:Connect(
        function(a1, a2)
            --[[
              line: 648
              upvalues:
                Players_upv_1 (copy, index: 1)
                TextChannels_upv_1 (copy, index: 2)
            ]]
            local v55 = a2:split(" ");
            local v56 = v55[2];
            local v57;
            v57 = nil;
            for _, value_9 in Players_upv_1:GetChildren() do
                if (value_9.Name == v56 or value_9.DisplayName == v56) then
                    v57 = value_9;
                else
                    v57 = nil;
                end;
                break;
            end;
            local v58 = nil;
            if (v57) then
                v58 = "";
                for n_4 = 3, #v55 do
                    v58 = v58 .. v55[n_4] .. " ";
                end;
                v58 = TextChannels_upv_1:FindFirstChild("WHISPER/" .. v57.UserId);
                if (not v58) then
                    return;
                end;
                print(v58);
                v58:SendAsync(v58);
            end;
        end
    );
    u18();
    v3, v4 = v3, v4;
    CustomChat_upv_1.Enabled = not SettingsModule_upv_1.GetSetting("General", "Hide Chat");
    if (os.clock() - v3 >= 20) then
        v3 = os.clock();
        for key_1, value_10 in pairs(tbl_upv_3) do
            if (os.clock() - value_10.Time >= 240) then
                table.remove(tbl_upv_3, key_1);
            end;
        end;
    end;
    if (os.clock() - v4 >= 0.8) then
        v4 = os.clock();
        u8();
        u7();
        u10();
    end;
    task.wait(0.2);
else
    v2 = PlayerGui_1:FindFirstChild("Main");
    CustomChat_upv_1 = PlayerGui_1:FindFirstChild("CustomChat");
    if (v2 and CustomChat_upv_1) then
        local GiveBed_upv_1 = v2:WaitForChild("GiveBed");
        local v47 = v2:WaitForChild("RenameBed");
        local ChatFrame_upv_1 = CustomChat_upv_1:WaitForChild("ChatFrame");
        local MessagesFrame_1 = ChatFrame_upv_1:WaitForChild("MessagesFrame");
        local TextboxFrame_upv_1 = ChatFrame_upv_1:WaitForChild("TextboxFrame");
        local TextBox_upv_1 = TextboxFrame_upv_1:WaitForChild("TextBox");
        local Channel_upv_1 = TextboxFrame_upv_1:WaitForChild("Channel");
        local Messages_upv_1 = MessagesFrame_1:WaitForChild("Messages");
        local TemplateScrollFrame_upv_1 = MessagesFrame_1:WaitForChild("TemplateScrollFrame");
        local t_upv_1 = Messages_upv_1:WaitForChild("t");
        local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
        local GamepadService_upv_1 = game:GetService("GamepadService");
        local RunService_upv_1 = game:GetService("RunService");
        local GamepadIconModule_1 = require(Modules_1:WaitForChild("GamepadIconModule"));
        local PreferredInputController_upv_1 = LocalPlayer_upv_1:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
        local GamepadControls_upv_1 = ChatFrame_upv_1:WaitForChild("GamepadControls");
        local ToolTip_1 = GamepadControls_upv_1:WaitForChild("ToolTip");
        local SendMessage_1 = ToolTip_1:WaitForChild("SendMessage");
        local CloseChat_1 = ToolTip_1:WaitForChild("CloseChat");
        GamepadIconModule_1.Register(SendMessage_1:FindFirstChildWhichIsA("ImageLabel"), "ButtonA");
        GamepadIconModule_1.Register(CloseChat_1:FindFirstChildWhichIsA("ImageLabel"), "ButtonB");
        GamepadControls_upv_1.Visible = false;
        local tbl_upv_1 = {};
        tbl_upv_1.Clan = true;
        tbl_upv_1.Team = true;
        tbl_upv_1.Global = true;
        local u1 = "Global";
        local u2 = "Default";
        local v48 = false;
        local v3 = os.clock();
        local v4 = os.clock();
        local u3 = false;
        local tbl_upv_2 = {};
        local tbl_upv_3 = {};
        local u4 = nil;
        if (shared.YourTeam ~= nil) then
            local v49 = TextChannels_upv_1:FindFirstChild("TEAM/" .. tostring(shared.YourTeam));
        end;
        local u5, u5;
        if (shared.ClanInfo ~= nil) then
            local v50 = TextChannels_upv_1:FindFirstChild("CLAN/" .. shared.ClanInfo.ClanTag);
        end;
        local function u6(a1)
            --[[
              line: 160
              upvalues:
                CustomChat_upv_1 (ref, index: 1)
            ]]
            local v5 = ((a1:find("RBXGeneral")) and "Global") or (((a1:find("CLAN/")) and "Clan") or (((a1:find("TEAM/")) and "Team") or ((a1:find("WHISPER/") and "Whisper") or a1)));
            local v6 = CustomChat_upv_1:GetAttribute("Color" .. v5):split(", ");
            local v7 = (v6 and (Color3.fromRGB(v6[1], v6[2], v6[3]))) or (Color3.fromRGB(153, 153, 153));
            return v7;
        end;
        local function u7()
            --[[
              line: 210
              upvalues:
                TemplateScrollFrame_upv_1 (copy, index: 1)
                Messages_upv_1 (copy, index: 2)
                u2 (ref,  index: 3)
                tbl_upv_2 (copy, index: 4)
                u5 (ref,  index: 5)
            ]]
            local AbsoluteSize_1 = TemplateScrollFrame_upv_1:FindFirstChild("t").AbsoluteSize;
            for _, value_1 in Messages_upv_1:GetChildren() do
                if (not (value_1:IsA("TextLabel"))) then
                    continue;
                end;
                if (value_1.Name == "m") then
                    value_1.Size = UDim2.new(0, AbsoluteSize_1.X, 0, AbsoluteSize_1.Y);
                end;
            end;
            if (u2 ~= "Default") then
                local Offset_1 = Messages_upv_1:FindFirstChild("UIListLayout").Padding.Offset;
                local v8 = #tbl_upv_2 * AbsoluteSize_1.Y + ((#tbl_upv_2 * Offset_1) - Offset_1);
                Messages_upv_1.CanvasSize = UDim2.new(0, 0, 0, v8);
                Messages_upv_1.ScrollBarImageTransparency = 0.6;
                if (u5) then
                    u5 = false;
                    Messages_upv_1.CanvasPosition = Vector2.new(0, v8);
                end;
            else
                Messages_upv_1.CanvasSize = UDim2.new(0, 0, 1, 0);
                Messages_upv_1.ScrollBarImageTransparency = 1;
                Messages_upv_1.CanvasPosition = Vector2.new(0, 0);
            end;
        end;
        local function u8()
            --[[
              line: 238
              upvalues:
                tbl_upv_2 (copy, index: 1)
                u2 (ref,  index: 2)
            ]]
            for _, value_2 in tbl_upv_2 do
                if (not (value_2.Time) or not (value_2.Gui)) then
                    continue;
                end;
                if (u2 ~= "Default") then
                    value_2.Gui.Visible = true;
                else
                    local Gui_1 = value_2.Gui;
                    Gui_1.Visible = os.clock() - value_2.Time < 15;
                end;
            end;
        end;
        local function u10()
            --[[
              line: 250
              upvalues:
                tbl_upv_2 (copy, index: 1)
            ]]
            local v11 = 1;
            for n_2 = 25, 1, -1 do
                local v12;
                v12 = tbl_upv_2[n_2];
                if (not (v12)) then
                    continue;
                end;
                if (v12.Gui) then
                    v12.Gui.LayoutOrder = v11;
                    v11 = v11 + 1;
                end;
            end;
        end;
        local function u9()
            --[[
              line: 272
              upvalues:
                tbl_upv_2 (copy, index: 1)
            ]]
            if (#tbl_upv_2 < 26) then
                return;
            end;
            for n_1 = 26, #tbl_upv_2 do
                local v10;
                v10 = tbl_upv_2[n_1];
                if ((v10) and v10.Gui ~= nil) then
                    v10.Gui:Destroy();
                end;
                table.remove(tbl_upv_2, n_1);
            end;
        end;
        local function u14(a1)
            --[[
              line: 137
              upvalues:
                ChatFrame_upv_1 (copy, index: 1)
            ]]
            local value_3 = nil;
            for _, value_3 in ChatFrame_upv_1:GetChildren() do
                if (value_3.Name:find("Button")) then
                    value_3.Visible = a1;
                end;
            end;
        end;
        local function u15(a1)
            --[[
              line: 372
              upvalues:
                u2 (ref,  index: 1)
                u5 (ref,  index: 2)
                u8 (copy, index: 3)
                u7 (copy, index: 4)
                u10 (copy, index: 5)
                TextBox_upv_1 (copy, index: 6)
                u14 (copy, index: 7)
                TextboxFrame_upv_1 (copy, index: 8)
                UserInputService_upv_1 (copy, index: 9)
            ]]
            script:SetAttribute("Typing", true);
            u2 = "Expanded";
            u5 = true;
            u8();
            u7();
            u10();
            TextBox_upv_1.Text = ((a1 ~= "Command") and "") or "/";
            task.wait();
            u14(true);
            TextboxFrame_upv_1.Visible = true;
            TextBox_upv_1:CaptureFocus();
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
            UserInputService_upv_1.MouseIconEnabled = true;
        end;
        local function u16(a1)
            --[[
              line: 284
              upvalues:
                u6 (copy, index: 1)
                t_upv_1 (copy, index: 2)
                Messages_upv_1 (copy, index: 3)
                tbl_upv_2 (copy, index: 4)
                u9 (copy, index: 5)
                u8 (copy, index: 6)
                u7 (copy, index: 7)
                u10 (copy, index: 8)
            ]]
            local v25 = u6("System");
            local v26 = "<font color=\"rgb(" .. math.ceil(v25.R * 255) .. ", " .. math.ceil(v25.G * 255) .. ", " .. math.ceil(v25.B * 255) .. ")\"><b>";
            local v27 = t_upv_1:Clone();
            v27.Name = "m";
            v27.Text = v26 .. "SYSTEM" .. "</b></font>: " .. a1;
            if (not v27:FindFirstChild("ImageLabel")) then
                return;
            end;
            v27.ImageLabel.Visible = false;
            v27.Visible = true;
            v27.Parent = Messages_upv_1;
            table.insert(tbl_upv_2, 1, {Gui = v27, Time = os.clock()});
            u9();
            u8();
            u7();
            u10();
        end;
        local function u17()
            --[[
              line: 411
              upvalues:
                u2 (ref,  index: 1)
                TextBox_upv_1 (copy, index: 2)
                u14 (copy, index: 3)
                TextboxFrame_upv_1 (copy, index: 4)
                UserInputService_upv_1 (copy, index: 5)
                u8 (copy, index: 6)
                u7 (copy, index: 7)
                u10 (copy, index: 8)
                GamepadService_upv_1 (copy, index: 9)
                GamepadControls_upv_1 (copy, index: 10)
                u3 (ref,  index: 11)
                TextChannels_upv_1 (copy, index: 12)
                LocalPlayer_upv_1 (copy, index: 13)
                u1 (ref,  index: 14)
                u16 (copy, index: 15)
            ]]
            u2 = "Default";
            local v28 = true;
            for _, value_4 in TextBox_upv_1.Text:split("") do
                if (value_4 ~= " ") then
                    v28 = false;
                    break;
                end;
            end;
            if (not (v28) and TextBox_upv_1.Text ~= "") then
                local v29 = nil;
                local v30 = TextBox_upv_1.Text:sub(1, 120);
                TextBox_upv_1.Text = v30;
                local v31;
                if (u3) then
                    local v32 = TextChannels_upv_1:FindFirstChild("WHISPER/" .. LocalPlayer_upv_1.UserId);
                    script:SetAttribute("Typing", false);
                    u14(false);
                    u2 = "Default";
                    TextboxFrame_upv_1.Visible = false;
                    TextBox_upv_1:ReleaseFocus();
                    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                    UserInputService_upv_1.MouseIconEnabled = false;
                    u8();
                    u7();
                    u10();
                    pcall(
                        function()
                            --[[
                              line: 407
                              upvalues:
                                GamepadService_upv_1 (copy, index: 1)
                            ]]
                            GamepadService_upv_1:DisableGamepadCursor();
                        end
                    );
                    GamepadControls_upv_1.Visible = false;
                    v31 = v32;
                elseif (u1 ~= "Global") then
                    local v33 = nil;
                    if (u1 == "Team") then
                        v33 = shared.YourTeam;
                        if (v33) then
                            v31 = TextChannels_upv_1:FindFirstChild("TEAM/" .. v33);
                        else
                            u16("Failed to send message. You are not currently in a team");
                            v31 = v29;
                        end;
                    elseif (u1 ~= "Clan") then
                        v31 = v29;
                    else
                        v33 = LocalPlayer_upv_1:GetAttribute("ClanTag");
                        if (v33) then
                            v31 = TextChannels_upv_1:FindFirstChild("CLAN/" .. v33);
                        else
                            u16("Failed to send message. You are not currently in a clan");
                            v31 = v29;
                        end;
                    end;
                else
                    v31 = TextChannels_upv_1:FindFirstChild("RBXGeneral");
                end;
                if (v31) then
                    v31:SendAsync(v30);
                    script:SetAttribute("Typing", false);
                    u14(false);
                    u2 = "Default";
                    TextboxFrame_upv_1.Visible = false;
                    TextBox_upv_1:ReleaseFocus();
                    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                    UserInputService_upv_1.MouseIconEnabled = false;
                    u8();
                    u7();
                    u10();
                    pcall(
                        function()
                            --[[
                              line: 407
                              upvalues:
                                GamepadService_upv_1 (copy, index: 1)
                            ]]
                            GamepadService_upv_1:DisableGamepadCursor();
                        end
                    );
                else
                    warn("[ChatController] - Failed to send message, no text channel found?");
                    script:SetAttribute("Typing", false);
                    u14(false);
                    u2 = "Default";
                    TextboxFrame_upv_1.Visible = false;
                    TextBox_upv_1:ReleaseFocus();
                    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                    UserInputService_upv_1.MouseIconEnabled = false;
                    u8();
                    u7();
                    u10();
                    pcall(
                        function()
                            --[[
                              line: 407
                              upvalues:
                                GamepadService_upv_1 (copy, index: 1)
                            ]]
                            GamepadService_upv_1:DisableGamepadCursor();
                        end
                    );
                end;
                GamepadControls_upv_1.Visible = false;
                return;
            end;
            script:SetAttribute("Typing", false);
            u14(false);
            u2 = "Default";
            TextboxFrame_upv_1.Visible = false;
            TextBox_upv_1:ReleaseFocus();
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService_upv_1.MouseIconEnabled = false;
            u8();
            u7();
            u10();
            pcall(
                function()
                    --[[
                      line: 407
                      upvalues:
                        GamepadService_upv_1 (copy, index: 1)
                    ]]
                    GamepadService_upv_1:DisableGamepadCursor();
                end
            );
            GamepadControls_upv_1.Visible = false;
        end;
        local function u18()
            --[[
              line: 176
              upvalues:
                t_upv_1 (copy, index: 1)
                tbl_upv_2 (copy, index: 2)
                TextBox_upv_1 (copy, index: 3)
            ]]
            local v34 = 1;
            for n_3 = 18, 1, -1 do
                t_upv_1.TextSize = n_3;
                if (t_upv_1.TextFits) then
                    v34 = n_3;
                    break;
                else
                    task.wait();
                end;
            end;
            local v36 = 1;
            local v37 = nil;
            local v38 = nil;
            for _, value_5 in tbl_upv_2 do
                v37 = v36 + 1;
                if (v37 < 5) then
                    v36 = v37;
                else
                    task.wait();
                    v36 = 1;
                end;
                v38 = value_5.Gui;
                if (v38) then
                    v38.TextSize = v34;
                    print("assigned font size " .. v34);
                end;
            end;
            TextBox_upv_1.TextSize = v34;
        end;
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(
            function()
                --[[
                  line: 458
                  upvalues:
                    u18 (copy, index: 1)
                ]]
                u18();
            end
        );
        TextBox_upv_1:GetPropertyChangedSignal("Text"):Connect(
            function()
                --[[
                  line: 462
                  upvalues:
                    u3 (ref,  index: 1)
                    TextBox_upv_1 (copy, index: 2)
                    Channel_upv_1 (copy, index: 3)
                    u1 (ref,  index: 4)
                    u6 (copy, index: 5)
                ]]
                local v39 = TextBox_upv_1.Text:sub(1, 1) == "/";
                u3 = v39;
                local v40 = (u3 and "COMMAND") or (string.upper(u1));
                Channel_upv_1.Text = v40;
                if (v39) then
                    v40 = u6("System");
                else
                    v40 = u6(u1);
                end;
                Channel_upv_1.TextColor3 = v40;
                TextBox_upv_1.Text = TextBox_upv_1.Text:sub(1, 120);
            end
        );
        local v41 = nil;
        for v51, value_upv_6 in ChatFrame_upv_1:GetChildren() do
            v41 = value_upv_6.Name:find("Button");
            if (v41) then
                value_upv_6.MouseButton1Click:Connect(
                    function()
                        --[[
                          line: 474
                          upvalues:
                            value_upv_6 (copy, index: 1)
                            tbl_upv_1 (copy, index: 2)
                            ChatFrame_upv_1 (copy, index: 3)
                        ]]
                        local v42 = value_upv_6.Name:gsub("Button", "");
                        local v43 = nil;
                        if (tbl_upv_1[v42] ~= nil) then
                            v43 = tbl_upv_1[v42];
                            local v44;
                            if (v43 == nil) then
                                return;
                            end;
                            v44 = ChatFrame_upv_1:FindFirstChild("Button" .. v42);
                            if (not v44) then
                                return;
                            end;
                            tbl_upv_1[v42] = not v43;
                            v44.Text = ((tbl_upv_1[v42]) and "X") or "";
                        end;
                    end
                );
            end;
        end;
        local function u11(a1, a2)
            --[[
              line: 309
              upvalues:
                Players_upv_1 (copy, index: 1)
                u6 (copy, index: 2)
                tbl_upv_3 (copy, index: 3)
                t_upv_1 (copy, index: 4)
                Messages_upv_1 (copy, index: 5)
                tbl_upv_2 (copy, index: 6)
                u9 (copy, index: 7)
                u8 (copy, index: 8)
                u7 (copy, index: 9)
                u10 (copy, index: 10)
            ]]
            if (a1.TextSource) then
                local u12;
                if (a1.Text:sub(1, 1) ~= "/") then
                    a1.Text = a1.Text:sub(1, 120);
                    local UserId_1 = a1.TextSource.UserId;
                    u12 = Players_upv_1:GetPlayerByUserId(UserId_1);
                    local v13 = nil;
                    if (u12) then
                        local v14 = "";
                        local v15 = nil;
                        local v18 = nil;
                        if (UserId_1) then
                            v18 = not u12:GetAttribute("HideTag");
                            if ((u12:GetAttribute("Owner")) and (v18)) then
                                v14 = "<font color=\"rgb(0,157,255)\">[\240\159\155\160\239\184\143OWNER]</font> ";
                            elseif ((u12:GetAttribute("Admin")) and (v18)) then
                                v14 = "<font color=\"rgb(255,102,0)\">[\240\159\148\167ADMIN]</font> ";
                            elseif ((u12:GetAttribute("Mod")) and (v18)) then
                                v14 = "<font color=\"rgb(255,84,84)\">[\240\159\148\168MOD]</font> ";
                            else
                                v14 = (u12:GetAttribute("VIP") and "<font color=\"rgb(255,200,0)\">[VIP]</font> ") or v14;
                            end;
                            v15 = u12:GetAttribute("ClanTag");
                            if (v15) then
                                local v17 = u12:GetAttribute("ClanColor") or Color3.new(1, 1, 1);
                                v14 = ("<font color=\"rgb(%*,%*,%*)\">[%*]</font> "):format(math.round(v17.R * 255), math.round(v17.G * 255), math.round(v17.B * 255), u12:GetAttribute("ClanTag")) .. v14;
                            end;
                        end;
                        if (u12.Team) then
                            v18 = u12.Team.TeamColor.Color;
                        else
                            v18 = u6(a1.TextChannel.Name);
                        end;
                        local v19 = "<font color=\"rgb(" .. math.ceil(v18.R * 255) .. ", " .. math.ceil(v18.G * 255) .. ", " .. math.ceil(v18.B * 255) .. ")\"><b>";
                        local u13 = tbl_upv_3[u12.UserId];
                        pcall(
                            function()
                                --[[
                                  line: 339
                                  upvalues:
                                    u13 (ref,  index: 1)
                                    Players_upv_1 (copy, index: 2)
                                    u12 (copy, index: 3)
                                    tbl_upv_3 (copy, index: 4)
                                ]]
                                if (u13) then
                                    local _ = u13.Thumbnail;
                                else
                                    u13 = Players_upv_1:GetUserThumbnailAsync(u12.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
                                    tbl_upv_3[u12.UserId] = {Thumbnail = u13, Time = os.clock()};
                                end;
                            end
                        );
                        local v20 = t_upv_1:Clone();
                        v13 = v20:FindFirstChild("ImageLabel");
                        local v21 = nil;
                        if (v13) then
                            v21 = v13:FindFirstChild("UIStroke");
                            local v22 = nil;
                            if (v21) then
                                v22 = a1.TextChannel.Name:find("RBXGeneral");
                                local v23 = u12:GetAttribute("ClanColor");
                                local v24;
                                if ((v22) and v23 ~= nil) then
                                    v24 = v23;
                                else
                                    v24 = v18;
                                end;
                                v21.Color = v24;
                            end;
                            u13 = (u13) and typeof(u13) == "string" or "";
                            v13.Image = u13;
                            v13.Visible = true;
                            v20.Name = "m";
                            v20.Text = v14 .. v19 .. u12.DisplayName .. "</b></font>: " .. a1.Text;
                            v20.Visible = true;
                            v20.Parent = Messages_upv_1;
                            table.insert(tbl_upv_2, 1, {Gui = v20, Time = os.clock()});
                            u9();
                            u8();
                            u7();
                            u10();
                        end;
                    else
                        warn("[ChatController] - Insert message failed, no sending player?");
                    end;
                end;
            end;
        end;
        TextChatService_1.MessageReceived:Connect(
            function(a1)
                --[[
                  line: 483
                  upvalues:
                    u11 (copy, index: 1)
                ]]
                u11(a1);
            end
        );
        v1.OnIncomingMessage = function(a1)
            --[[
              line: 488
              upvalues:
                u11 (copy, index: 1)
            ]]
            if (a1.Status == Enum.TextChatMessageStatus.Success) then
                return;
            end;
            u11(a1);
        end;
        UpdateFontSize_1.Event:Connect(
            function()
                --[[
                  line: 493
                  upvalues:
                    u18 (copy, index: 1)
                ]]
                u18();
            end
        );
        SystemMessage_1.OnClientEvent:Connect(
            function(a1)
                --[[
                  line: 552
                  upvalues:
                    u16 (copy, index: 1)
                ]]
                if (not a1) then
                    return;
                end;
                u16(a1);
            end
        );
        UserInputService_upv_1.InputBegan:Connect(
            function(a1, a2)
                --[[
                  line: 557
                  upvalues:
                    SettingsModule_upv_1 (copy, index: 1)
                    CustomChat_upv_1 (ref,  index: 2)
                    u17 (copy, index: 3)
                    u15 (copy, index: 4)
                    u1 (ref,  index: 5)
                    GiveBed_upv_1 (copy, index: 6)
                    UserInputService_upv_1 (copy, index: 7)
                    u14 (copy, index: 8)
                    u2 (ref,  index: 9)
                    TextboxFrame_upv_1 (copy, index: 10)
                    TextBox_upv_1 (copy, index: 11)
                    u8 (copy, index: 12)
                    u7 (copy, index: 13)
                    u10 (copy, index: 14)
                    GamepadService_upv_1 (copy, index: 15)
                    GamepadControls_upv_1 (copy, index: 16)
                    u4 (ref,  index: 17)
                    RunService_upv_1 (copy, index: 18)
                    PreferredInputController_upv_1 (copy, index: 19)
                ]]
                if (not (SettingsModule_upv_1.MainMenuOpen())) then
                    local v45;
                    if (not CustomChat_upv_1.Enabled) then
                        return;
                    end;
                    v45 = a1.UserInputType;
                    if (v45 ~= Enum.UserInputType.Keyboard) then
                        local v46 = nil;
                        if (v45 == Enum.UserInputType.Gamepad1) then
                            v46 = a1.KeyCode.Name;
                            if (v46 == "ButtonB" and script:GetAttribute("Typing")) then
                                script:SetAttribute("Typing", false);
                                u14(false);
                                u2 = "Default";
                                TextboxFrame_upv_1.Visible = false;
                                TextBox_upv_1:ReleaseFocus();
                                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                                UserInputService_upv_1.MouseIconEnabled = false;
                                u8();
                                u7();
                                u10();
                                pcall(
                                    function()
                                        --[[
                                          line: 407
                                          upvalues:
                                            GamepadService_upv_1 (copy, index: 1)
                                        ]]
                                        GamepadService_upv_1:DisableGamepadCursor();
                                    end
                                );
                                GamepadControls_upv_1.Visible = false;
                                return;
                            end;
                            if (v46 == "ButtonA" and script:GetAttribute("Typing")) then
                                u17();
                                return;
                            end;
                            if (v46 == SettingsModule_upv_1.GetSetting("Gamepad", "Open Map") and not (script:GetAttribute("Typing"))) then
                                u4 = tick();
                                task.spawn(
                                    function()
                                        --[[
                                          line: 593
                                          upvalues:
                                            u4 (ref,  index: 1)
                                            RunService_upv_1 (copy, index: 2)
                                            u15 (copy, index: 3)
                                            u1 (ref,  index: 4)
                                            PreferredInputController_upv_1 (copy, index: 5)
                                            GamepadService_upv_1 (copy, index: 6)
                                            GamepadControls_upv_1 (copy, index: 7)
                                        ]]
                                        while (u4 and tick() - u4 < 1.2) do
                                            RunService_upv_1.Heartbeat:Wait();
                                        end;
                                        if (not u4) then
                                            return;
                                        end;
                                        if (tick() - u4 >= 1.2) then
                                            u4 = nil;
                                            u15(u1);
                                            local v47 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                                            if (not v47) then
                                                return;
                                            end;
                                            pcall(
                                                function()
                                                    --[[
                                                      line: 400
                                                      upvalues:
                                                        GamepadService_upv_1 (copy, index: 1)
                                                    ]]
                                                    GamepadService_upv_1:EnableGamepadCursor(nil);
                                                end
                                            );
                                            GamepadControls_upv_1.Visible = true;
                                        end;
                                    end
                                );
                            end;
                        end;
                    else
                        local v48 = SettingsModule_upv_1.GetSetting("Controls", "Start Typing");
                        local _;
                        if (a1.KeyCode == Enum.KeyCode.Return and script:GetAttribute("Typing")) then
                            u17();
                            return;
                        end;
                        if (a1.KeyCode.Name ~= SettingsModule_upv_1.GetSetting("Controls", "Switch Channels")) then
                            if (a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Controls", "Start Command") and not (script:GetAttribute("Typing"))) then
                                u15("Command");
                                return;
                            end;
                            if (a1.KeyCode.Name == v48) then
                                if (not (GiveBed_upv_1.Visible) and tick() - (shared.LastTextBoxFocused or 0) > 0.1) then
                                    if (not script:GetAttribute("Typing")) then
                                        local v49 = nil;
                                        if (a1.KeyCode.Name == v48) then
                                            _, v49 = pcall(
                                                function()
                                                    --[[
                                                      line: 578
                                                      upvalues:
                                                        UserInputService_upv_1 (copy, index: 1)
                                                        CustomChat_upv_1 (ref,  index: 2)
                                                    ]]
                                                    local v50 = UserInputService_upv_1:GetFocusedTextBox();
                                                    if (v50 and not (v50:IsDescendantOf(CustomChat_upv_1))) then
                                                        return true;
                                                    end;
                                                end
                                            );
                                            if (not v49) then
                                                u15(u1);
                                            end;
                                        end;
                                    end;
                                    return;
                                end;
                                return;
                            end;
                        else
                            if (script:GetAttribute("Typing")) then
                                task.wait();
                                local v51 = "Global";
                                if (u1 == "Global") then
                                    v51 = "Team";
                                elseif (u1 == "Team") then
                                    v51 = "Clan";
                                elseif (u1 == "Clan") then
                                    v51 = "Global";
                                end;
                                u1 = v51;
                                u15(u1);
                            end;
                            return;
                        end;
                    end;
                end;
            end
        );
        UserInputService_upv_1.InputEnded:Connect(
            function(a1)
                --[[
                  line: 606
                  upvalues:
                    SettingsModule_upv_1 (copy, index: 1)
                    u4 (ref,  index: 2)
                ]]
                if (a1.UserInputType ~= Enum.UserInputType.Gamepad1 or a1.KeyCode.Name ~= SettingsModule_upv_1.GetSetting("Gamepad", "Open Map")) then
                    return;
                end;
                u4 = nil;
            end
        );
        PreferredInputController_upv_1:GetAttributeChangedSignal("PreferredInput"):Connect(
            function()
                --[[
                  line: 613
                  upvalues:
                    PreferredInputController_upv_1 (copy, index: 1)
                    GamepadService_upv_1 (copy, index: 2)
                    GamepadControls_upv_1 (copy, index: 3)
                ]]
                if (script:GetAttribute("Typing")) then
                    local v52 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                    if (v52) then
                        pcall(
                            function()
                                --[[
                                  line: 616
                                  upvalues:
                                    GamepadService_upv_1 (copy, index: 1)
                                ]]
                                GamepadService_upv_1:EnableGamepadCursor(nil);
                            end
                        );
                        GamepadControls_upv_1.Visible = true;
                    else
                        pcall(
                            function()
                                --[[
                                  line: 619
                                  upvalues:
                                    GamepadService_upv_1 (copy, index: 1)
                                ]]
                                GamepadService_upv_1:DisableGamepadCursor();
                            end
                        );
                        GamepadControls_upv_1.Visible = false;
                    end;
                end;
            end
        );
        ClearChat_1.Triggered:Connect(
            function()
                --[[
                  line: 626
                  upvalues:
                    tbl_upv_2 (copy, index: 1)
                    u8 (copy, index: 2)
                    u7 (copy, index: 3)
                    u10 (copy, index: 4)
                ]]
                for _, value_7 in tbl_upv_2 do
                    if (value_7.Gui) then
                        value_7.Gui:Destroy();
                    end;
                end;
                table.clear(tbl_upv_2);
                u8();
                u7();
                u10();
            end
        );
        Help_1.Triggered:Connect(
            function()
                --[[
                  line: 637
                  upvalues:
                    CustomCommands_upv_1 (copy, index: 1)
                    u16 (copy, index: 2)
                ]]
                local v53 = nil;
                local v54 = nil;
                local PrimaryAlias_1 = nil;
                for _, value_8 in CustomCommands_upv_1:GetChildren() do
                    if (value_8:GetAttribute("Help") == "Hide") then
                        continue;
                    end;
                    v54 = value_8.SecondaryAlias ~= "";
                    PrimaryAlias_1 = value_8.PrimaryAlias;
                    if (not (v54)) then
                        v53 = "";
                        u16("" .. PrimaryAlias_1 .. v53 .. " - " .. value_8:GetAttribute("Help"));
                        continue;
                    end;
                    v53 = " or " .. value_8.SecondaryAlias or "";
                    u16("" .. PrimaryAlias_1 .. v53 .. " - " .. value_8:GetAttribute("Help"));
                end;
                u16("/help Success, all commands listed above");
            end
        );
        Whisper_1.Triggered:Connect(
            function(a1, a2)
                --[[
                  line: 648
                  upvalues:
                    Players_upv_1 (copy, index: 1)
                    TextChannels_upv_1 (copy, index: 2)
                ]]
                local v55 = a2:split(" ");
                local v56 = v55[2];
                local v57;
                v57 = nil;
                for _, value_9 in Players_upv_1:GetChildren() do
                    if (value_9.Name == v56 or value_9.DisplayName == v56) then
                        v57 = value_9;
                    else
                        v57 = nil;
                    end;
                    break;
                end;
                local v58 = nil;
                if (v57) then
                    v58 = "";
                    for n_4 = 3, #v55 do
                        v58 = v58 .. v55[n_4] .. " ";
                    end;
                    v58 = TextChannels_upv_1:FindFirstChild("WHISPER/" .. v57.UserId);
                    if (not v58) then
                        return;
                    end;
                    print(v58);
                    v58:SendAsync(v58);
                end;
            end
        );
        u18();
        v3, v4 = v3, v4;
        CustomChat_upv_1.Enabled = not SettingsModule_upv_1.GetSetting("General", "Hide Chat");
        while (true) do
            if (os.clock() - v3 >= 20) then
                v3 = os.clock();
                for key_1, value_10 in pairs(tbl_upv_3) do
                    if (os.clock() - value_10.Time >= 240) then
                        table.remove(tbl_upv_3, key_1);
                    end;
                end;
            end;
            if (os.clock() - v4 >= 0.8) then
                v4 = os.clock();
                u8();
                u7();
                u10();
            end;
            break;
        end;
    else
        task.wait(0.2);
    end;
end;