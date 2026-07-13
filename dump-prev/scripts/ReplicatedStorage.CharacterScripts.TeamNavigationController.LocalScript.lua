-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_upv_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local UserInputService_upv_1 = game:GetService("UserInputService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Values_upv_1 = ReplicatedStorage_1:WaitForChild("Values");
local GuiUtil_upv_1 = require(Modules_1:WaitForChild("GuiUtil"));
local RaycastUtil_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local TweenUtil_upv_1 = require(Modules_1:WaitForChild("TweenUtil"));
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
local ActiveBenchModule_upv_1 = require(Modules_1:WaitForChild("ActiveBenchModule"));
local u1 = require(Modules_1:WaitForChild("AssetContainer"))();
local LocalPlayer_upv_1 = Players_upv_1.LocalPlayer;
local PlayerScripts_1 = LocalPlayer_upv_1.PlayerScripts;
local v1 = LocalPlayer_upv_1.Character or (script.Parent);
local Humanoid_upv_1 = v1:WaitForChild("Humanoid");
local HumanoidRootPart_upv_1 = v1:WaitForChild("HumanoidRootPart");
local CurrentCamera_upv_1 = workspace.CurrentCamera;
local PlayerGui_upv_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui");
local Main_1 = PlayerGui_upv_1:WaitForChild("Main");
local Compass_upv_1 = Main_1:WaitForChild("Compass");
local Map_upv_1 = Main_1:WaitForChild("Map");
local Map_upv_2 = Map_upv_1:WaitForChild("Frame"):WaitForChild("Map");
local PlayerCursor_upv_1 = Map_upv_2:WaitForChild("PlayerCursor");
local Team_1 = Main_1:WaitForChild("Team");
local tbl_upv_1 = {Team_1:WaitForChild("Accept"), Team_1:WaitForChild("Decline"), Team_1:WaitForChild("Inviter")};
local CreateLeaveTeam_upv_1 = Team_1:WaitForChild("CreateLeaveTeam");
local TeamList_upv_1 = Team_1:WaitForChild("TeamList");
local c_upv_1 = TeamList_upv_1:WaitForChild("c");
local TeamHighlight_1 = script:WaitForChild("TeamHighlight");
local InventoryController_upv_1 = v1:WaitForChild("InventoryController");
local ChatController_upv_1 = PlayerScripts_1:WaitForChild("ChatController");
local PreferredInputController_upv_1 = PlayerScripts_1:WaitForChild("PreferredInputController");
local UpdateChannel_upv_1 = ChatController_upv_1:WaitForChild("UpdateChannel");
local u2 = Vector2.new(0, 0);
local v2 = tick();
local v3 = tick();
local v4 = tick();
local u3 = nil;
local tbl_upv_2 = {0, -360, 360};
u3 = false;
local u4 = InventoryController_upv_1:GetAttribute("CurOpen");
local u5 = false;
local v5 = {};
shared.cachedTeamModels = {};
shared.YourTeam = nil;
local tbl_3 = {};
tbl_3[0] = "N";
tbl_3[45] = "NE";
tbl_3[90] = "E";
tbl_3[135] = "SE";
tbl_3[180] = "S";
tbl_3[225] = "SW";
tbl_3[270] = "W";
tbl_3[315] = "NW";
local tbl_4 = {};
tbl_4.MaxDistance = {};
tbl_4.TextColor3 = {Default = Color3.fromRGB(255, 255, 255), Team = Color3.fromRGB(30, 158, 255)};
local tbl_upv_5 = {};
local v6 = RaycastUtil_1:FilterFunction("View");
local tbl_upv_6 = {};
local u6, u7 = v5, nil;
local v7, v7, u8 = nil, nil, nil;
local u11;
for n_1 = 0, 355, 5 do
    u11 = tbl_3[n_1];
    v7 = nil;
    if (u11) then
        local v9 = ((u11:len() <= 1) and "TemplateLarge") or "TemplateMedium";
        v7 = v9;
        if (v7) then
            local v10;
            if (not (v7)) then
                continue;
            end;
            v9 = Compass_upv_1:FindFirstChild(v7):Clone();
            v10 = v9:FindFirstChildOfClass("TextLabel");
            if (not (v10)) then
                v9.Name = "Angle" .. (n_1 - 90) - (((n_1 - 90 <= 180) and 0) or 360);
                v9.BackgroundTransparency = (u11 and 0) or (v9.BackgroundTransparency);
                u8 = (u11 and (v9.BorderColor3)) or (Color3.fromRGB(132, 132, 132));
                v9.BorderColor3 = u8;
                v9.Parent = Compass_upv_1;
                table.insert(tbl_upv_6, v9);
                continue;
            end;
            if (not (u11)) then
                u8 = tostring(n_1);
                v10.Text = u8;
                v10.TextTransparency = (u11 and 0) or (v10.TextTransparency);
                v10.TextStrokeTransparency = (u11 and 0.7) or (v10.TextStrokeTransparency);
                v9.Name = "Angle" .. (n_1 - 90) - (((n_1 - 90 <= 180) and 0) or 360);
                v9.BackgroundTransparency = (u11 and 0) or (v9.BackgroundTransparency);
                u8 = (u11 and (v9.BorderColor3)) or (Color3.fromRGB(132, 132, 132));
                v9.BorderColor3 = u8;
                v9.Parent = Compass_upv_1;
                table.insert(tbl_upv_6, v9);
                continue;
            end;
            u8 = u11 or tostring(n_1) or tostring(n_1) or tostring(n_1) or tostring(n_1);
            v10.Text = u8;
            v10.TextTransparency = (u11 and 0) or (v10.TextTransparency);
            v10.TextStrokeTransparency = (u11 and 0.7) or (v10.TextStrokeTransparency);
            v9.Name = "Angle" .. (n_1 - 90) - (((n_1 - 90 <= 180) and 0) or 360);
            v9.BackgroundTransparency = (u11 and 0) or (v9.BackgroundTransparency);
            u8 = (u11 and (v9.BorderColor3)) or (Color3.fromRGB(132, 132, 132));
            v9.BorderColor3 = u8;
            v9.Parent = Compass_upv_1;
            table.insert(tbl_upv_6, v9);
        else
            v9 = n_1 % 10 == 0 and "TemplateMedium" or n_1 % 5 == 0 and "TemplateSmall";
            v7 = v9;
            local v10;
            if (not (v7)) then
                continue;
            end;
            v9 = Compass_upv_1:FindFirstChild(v7):Clone();
            v10 = v9:FindFirstChildOfClass("TextLabel");
            if (not (v10)) then
                v9.Name = "Angle" .. (n_1 - 90) - (((n_1 - 90 <= 180) and 0) or 360);
                v9.BackgroundTransparency = (u11 and 0) or (v9.BackgroundTransparency);
                u8 = (u11 and (v9.BorderColor3)) or (Color3.fromRGB(132, 132, 132));
                v9.BorderColor3 = u8;
                v9.Parent = Compass_upv_1;
                table.insert(tbl_upv_6, v9);
                continue;
            end;
            if (not (u11)) then
                u8 = tostring(n_1);
                v10.Text = u8;
                v10.TextTransparency = (u11 and 0) or (v10.TextTransparency);
                v10.TextStrokeTransparency = (u11 and 0.7) or (v10.TextStrokeTransparency);
                v9.Name = "Angle" .. (n_1 - 90) - (((n_1 - 90 <= 180) and 0) or 360);
                v9.BackgroundTransparency = (u11 and 0) or (v9.BackgroundTransparency);
                u8 = (u11 and (v9.BorderColor3)) or (Color3.fromRGB(132, 132, 132));
                v9.BorderColor3 = u8;
                v9.Parent = Compass_upv_1;
                table.insert(tbl_upv_6, v9);
                continue;
            end;
            u8 = u11 or tostring(n_1) or tostring(n_1) or tostring(n_1) or tostring(n_1);
            v10.Text = u8;
            v10.TextTransparency = (u11 and 0) or (v10.TextTransparency);
            v10.TextStrokeTransparency = (u11 and 0.7) or (v10.TextStrokeTransparency);
            v9.Name = "Angle" .. (n_1 - 90) - (((n_1 - 90 <= 180) and 0) or 360);
            v9.BackgroundTransparency = (u11 and 0) or (v9.BackgroundTransparency);
            u8 = (u11 and (v9.BorderColor3)) or (Color3.fromRGB(132, 132, 132));
            v9.BorderColor3 = u8;
            v9.Parent = Compass_upv_1;
            table.insert(tbl_upv_6, v9);
        end;
    else
        if (v7) then
            local v10;
        else
            local v9;
            v9 = n_1 % 10 == 0 and "TemplateMedium" or n_1 % 5 == 0 and "TemplateSmall";
            v7 = v9;
            local v10;
        end;
        if (not (v7)) then
            continue;
        end;
        local v9;
        v9 = Compass_upv_1:FindFirstChild(v7):Clone();
        local v10;
        v10 = v9:FindFirstChildOfClass("TextLabel");
        if (not (v10)) then
            v9.Name = "Angle" .. (n_1 - 90) - (((n_1 - 90 <= 180) and 0) or 360);
            v9.BackgroundTransparency = (u11 and 0) or (v9.BackgroundTransparency);
            u8 = (u11 and (v9.BorderColor3)) or (Color3.fromRGB(132, 132, 132));
            v9.BorderColor3 = u8;
            v9.Parent = Compass_upv_1;
            table.insert(tbl_upv_6, v9);
            continue;
        end;
        if (not (u11)) then
            u8 = tostring(n_1);
            v10.Text = u8;
            v10.TextTransparency = (u11 and 0) or (v10.TextTransparency);
            v10.TextStrokeTransparency = (u11 and 0.7) or (v10.TextStrokeTransparency);
            v9.Name = "Angle" .. (n_1 - 90) - (((n_1 - 90 <= 180) and 0) or 360);
            v9.BackgroundTransparency = (u11 and 0) or (v9.BackgroundTransparency);
            u8 = (u11 and (v9.BorderColor3)) or (Color3.fromRGB(132, 132, 132));
            v9.BorderColor3 = u8;
            v9.Parent = Compass_upv_1;
            table.insert(tbl_upv_6, v9);
            continue;
        end;
        u8 = u11 or tostring(n_1) or tostring(n_1) or tostring(n_1) or tostring(n_1);
    end;
end;
local u9 = #tbl_upv_6 - 18;
local function u10()
    --[[
      line: 163
      upvalues:
        CurrentCamera_upv_1 (copy, index: 1)
        PlayerGui_upv_1 (copy, index: 2)
        u3 (ref,  index: 3)
        tbl_upv_2 (copy, index: 4)
        Compass_upv_1 (copy, index: 5)
        tbl_upv_6 (copy, index: 6)
        u9 (copy, index: 7)
    ]]
    local CFrame_1 = CurrentCamera_upv_1.CFrame;
    local Position_1 = CFrame_1.Position;
    local LookVector_1 = CFrame_1.LookVector;
    local v11 = CFrame.new(Position_1, Position_1 + Vector3.new(LookVector_1.X, 0, LookVector_1.Z));
    local LookVector_2 = v11.LookVector;
    local v12 = PlayerGui_upv_1:GetAttribute("PlayerMapPin");
    local v13 = u3 == LookVector_2;
    if (v13 and not (v12)) then
        return;
    end;
    local v14 = math.deg(math.atan2(LookVector_2.Z, LookVector_2.X));
    if (v12) then
        local v15 = Vector2.new(Position_1.X, Position_1.Z) - v12;
        local _ = math.deg(({CFrame_1:ToOrientation()})[2]);
        local v16 = -math.deg(math.atan2(v15.X, v15.Y)) - 90;
        local v17 = ((v16 >= 0) and 0) or 360;
        local v26 = false;
        for v27, value_1 in pairs(tbl_upv_2) do
            local v18;
            v18 = v16 + v17 + value_1 - v14;
            if (math.abs(v18) <= 45) then
                Compass_upv_1.Pin.Position = UDim2.new(0.5 + (v18 / 90), 0, 0.04, 0);
                v17 = true;
            end;
        end;
        Compass_upv_1.Pin.Visible = v17;
    end;
    if (not v13) then
        u3 = LookVector_2;
        local v19 = 0;
        u3 = false;
        local v20 = nil;
        local v16 = nil;
        local v21;
        for key_1, value_2 in pairs(tbl_upv_6) do
            if (v19 >= 18) then
                value_2.Visible = false;
                if (v21) then
                    v20 = v20 or (u9 - 1);
                end;
            elseif (v20) then
                if (v20 > 0) then
                    v20 = v20 - 1;
                    value_2.Visible = false;
                    continue;
                end;
                local num_1 = tonumber(value_2.Name:sub(6));
                for _, value_3 in pairs(tbl_upv_2) do
                    local v22;
                    if (v16 ~= false) then
                        value_2.Visible = true;
                        local LookVector_3 = (v11 * CFrame.Angles(0, math.rad(num_1), 0)).LookVector;
                        local v23;
                        v23 = math.deg(math.atan2(LookVector_3.Z, LookVector_3.X)) * -1;
                        local v24;
                        v24 = ((value_2:FindFirstChild("Label")) and 0.25) or 0.125;
                        value_2.Position = UDim2.new((v23 / 90) + 0.5, 0, v24, 0);
                        v22 = true;
                        v19 = v19 + 1;
                    else
                        local v23, v24 = nil, nil;
                        if (math.abs((v14 + value_3) - num_1) > 45) then
                            continue;
                        else
                            value_2.Visible = true;
                            local LookVector_3 = (v11 * CFrame.Angles(0, math.rad(num_1), 0)).LookVector;
                            v23 = math.deg(math.atan2(LookVector_3.Z, LookVector_3.X)) * -1;
                            v24 = ((value_2:FindFirstChild("Label")) and 0.25) or 0.125;
                            value_2.Position = UDim2.new((v23 / 90) + 0.5, 0, v24, 0);
                            v22 = true;
                            v19 = v19 + 1;
                        end;
                    end;
                end;
                if (v22) then
                    if (key_1 == 1) then
                        local v25 = true;
                        continue;
                    end;
                    if (not (v21)) then
                        v16 = true;
                    end;
                else
                    value_2.Visible = false;
                    if (v21) then
                        v20 = v20 or (u9 - 1);
                    end;
                end;
            else
                local num_1 = tonumber(value_2.Name:sub(6));
                for _, value_3 in pairs(tbl_upv_2) do
                    local v22;
                    if (v16 ~= false) then
                        value_2.Visible = true;
                        local LookVector_3 = (v11 * CFrame.Angles(0, math.rad(num_1), 0)).LookVector;
                        local v23;
                        v23 = math.deg(math.atan2(LookVector_3.Z, LookVector_3.X)) * -1;
                        local v24;
                        v24 = ((value_2:FindFirstChild("Label")) and 0.25) or 0.125;
                        value_2.Position = UDim2.new((v23 / 90) + 0.5, 0, v24, 0);
                        v22 = true;
                        v19 = v19 + 1;
                    else
                        local v23, v24 = nil, nil;
                        if (math.abs((v14 + value_3) - num_1) > 45) then
                            continue;
                        else
                            value_2.Visible = true;
                            local LookVector_3 = (v11 * CFrame.Angles(0, math.rad(num_1), 0)).LookVector;
                            v23 = math.deg(math.atan2(LookVector_3.Z, LookVector_3.X)) * -1;
                            v24 = ((value_2:FindFirstChild("Label")) and 0.25) or 0.125;
                            value_2.Position = UDim2.new((v23 / 90) + 0.5, 0, v24, 0);
                            v22 = true;
                            v19 = v19 + 1;
                        end;
                    end;
                end;
                if (v22) then
                    if (key_1 == 1) then
                        local v25 = true;
                        continue;
                    end;
                    if (not (v21)) then
                        v16 = true;
                    end;
                else
                    value_2.Visible = false;
                    if (v21) then
                        v20 = v20 or (u9 - 1);
                    end;
                end;
            end;
        end;
    end;
end;
u11 = function(a1, a2)
    --[[
      line: 233
      upvalues:
        u6 (ref,  index: 1)
        Values_upv_1 (copy, index: 2)
        TeamList_upv_1 (copy, index: 3)
        Players_upv_1 (copy, index: 4)
        c_upv_1 (copy, index: 5)
        LocalPlayer_upv_1 (copy, index: 6)
        InventoryController_upv_1 (copy, index: 7)
    ]]
    local v26 = false;
    if (#a1 == #u6) then
        for key_2, value_4 in pairs(a1) do
            if (u6[key_2] ~= value_4) then
                v26 = true;
                break;
            end;
        end;
    else
        v26 = true;
    end;
    u6 = a1;
    if (not (v26) and not (a2)) then
        return;
    end;
    local v27 = #u6 > 0;
    script:SetAttribute("InTeam", v27);
    local key_3 = false;
    if (#a1 < Values_upv_1.TeamSize.Value) then
        key_3 = a1[1] ~= "CantLeave";
    end;
    script:SetAttribute("CanInvite", key_3);
    for key_3, value_5 in pairs(TeamList_upv_1:GetChildren()) do
        if (value_5.Name:find("Member")) then
            value_5:Destroy();
        end;
    end;
    local v29 = 0;
    local v30 = nil;
    local v31 = nil;
    local v32 = nil;
    local value_upv_6 = nil;
    local u12 = nil;
    local v33 = nil;
    local v34 = nil;
    for _, value_upv_6 in pairs(a1) do
        if (value_upv_6 == "CantLeave") then
            continue;
        end;
        v31 = v29 + 1;
        v32 = v31 == 9;
        v30 = false;
        u12 = typeof(value_upv_6);
        if (u12 == "string") then
            v30 = not v32;
        end;
        u12 = nil;
        if (v32) then
            u12 = "...";
        else
            value_upv_6 = tonumber(value_upv_6);
            pcall(
                function()
                    --[[
                      line: 268
                      upvalues:
                        u12 (ref,  index: 1)
                        Players_upv_1 (copy, index: 2)
                        value_upv_6 (ref,  index: 3)
                    ]]
                    u12 = Players_upv_1:GetNameFromUserIdAsync(value_upv_6);
                end
            );
            u12 = u12 or (value_upv_6 .. "_ERROR");
        end;
        v33 = c_upv_1:Clone();
        v33.Name = "Member" .. v31;
        v33.Position = UDim2.new(v33.Position.X.Scale, 0, v33.Position.Y.Scale + ((v31 - 1) * 0.03));
        v33.Text = u12;
        if (v30) then
            v34 = v33.TextColor3;
        elseif (value_upv_6 ~= LocalPlayer_upv_1.UserId) then
            v34 = Color3.fromRGB(255, 255, 255);
        else
            v34 = Color3.fromRGB(119, 255, 221);
        end;
        v33.TextColor3 = v34;
        v33.Parent = TeamList_upv_1;
        v33.Visible = true;
        if (v32) then
            break;
        end;
    end;
    local v35 = v27;
    if (v35) then
        value_upv_6 = "CurOpen";
        v35 = InventoryController_upv_1:GetAttribute("CurOpen") ~= "Crafting";
    end;
    TeamList_upv_1.Visible = v35;
end;
local tbl_upv_7 = {};
u8 = function(a1, a2)
    --[[
      line: 301
      upvalues:
        Players_upv_1 (copy, index: 1)
        tbl_upv_7 (copy, index: 2)
        Map_upv_2 (copy, index: 3)
        u2 (copy, index: 4)
        HumanoidRootPart_upv_1 (copy, index: 5)
        PlayerCursor_upv_1 (copy, index: 6)
        Humanoid_upv_1 (copy, index: 7)
    ]]
    if (a1) then
        local tbl_8 = {};
        local v36 = nil;
        local v37 = nil;
        local v38 = nil;
        local v39 = nil;
        local v40 = nil;
        local value_7 = nil;
        for key_4, value_7 in pairs(a2) do
            value_7 = tonumber(value_7);
            if (not (value_7)) then
                continue;
            end;
            v37 = Players_upv_1:GetPlayerByUserId(value_7);
            if (not (v37)) then
                continue;
            end;
            tbl_8[value_7] = true;
            v38 = v37.Name;
            v36 = tbl_upv_7[value_7];
            v39 = a1[tostring(key_4)];
            if (v39 and not (v36)) then
                v36 = Map_upv_2.TeamCursor:Clone();
                v36.Name = v38;
                v36.Parent = Map_upv_2;
                v36.Visible = true;
                tbl_upv_7[value_7] = v36;
            end;
            if (not (v36)) then
                continue;
            end;
            v36.PlayerName.Text = v38;
            if (v39) then
                v40 = ((typeof(v39) == "Vector3") and (v39.Z)) or (v39.Y);
                v36.Position = UDim2.new(0.5 + ((v39.X - u2.X) / 12800), 0, 0.5 + ((v40 - u2.Y) / 12800), 0);
            end;
        end;
        for key_5, value_8 in pairs(tbl_upv_7) do
            if (not (tbl_8[key_5])) then
                value_8:Destroy();
                tbl_upv_7[key_5] = nil;
            end;
        end;
    end;
    if (HumanoidRootPart_upv_1 and HumanoidRootPart_upv_1.Parent) then
        local CFrame_2 = HumanoidRootPart_upv_1.CFrame;
        local LookVector_4 = CFrame_2.LookVector;
        local v41 = math.deg(math.atan2(-LookVector_4.Z, LookVector_4.X)) * -1;
        local Position_2 = CFrame_2.Position;
        local v42 = ((typeof(Position_2) == "Vector3") and (Position_2.Z)) or (Position_2.Y);
        PlayerCursor_upv_1.Position = UDim2.new(0.5 + ((Position_2.X - u2.X) / 12800), 0, 0.5 + ((v42 - u2.Y) / 12800), 0);
        PlayerCursor_upv_1.Rotator.Rotation = v41;
    end;
    PlayerCursor_upv_1.Visible = Humanoid_upv_1;
end;
local RunService_upv_1 = game:GetService("RunService");
local u13 = false;
local u14 = false;
local GamepadService_upv_1 = game:GetService("GamepadService");
local MapToolTip_upv_1 = Map_upv_1:WaitForChild("MapToolTip");
local PlaceMarker_1 = MapToolTip_upv_1:WaitForChild("PlaceMarker");
require(Modules_1:WaitForChild("GamepadIconModule")).Register(PlaceMarker_1.ImageLabel, "ButtonA");
local function u15()
    --[[
      line: 389
      upvalues:
        u14 (ref,  index: 1)
        GuiUtil_upv_1 (copy, index: 2)
        Map_upv_1 (copy, index: 3)
        u13 (ref,  index: 4)
        RunService_upv_1 (copy, index: 5)
        UserInputService_upv_1 (copy, index: 6)
        MapToolTip_upv_1 (copy, index: 7)
    ]]
    local v43 = nil;
    if (not u14) then
        u14 = true;
        v43 = GuiUtil_upv_1:GetZoomInfo(Map_upv_1);
        local v44, v45 = nil, nil;
        if (v43) then
            while (u13 and (v43)) do
                local v46 = RunService_upv_1.Heartbeat:Wait();
                local u16, v47;
                if (not (u13)) then
                    break;
                end;
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                UserInputService_upv_1.MouseIconEnabled = true;
                u16 = 0;
                local u17 = 0;
                local u18 = 0;
                pcall(
                    function()
                        --[[
                          line: 406
                          upvalues:
                            UserInputService_upv_1 (copy, index: 1)
                            u16 (ref,  index: 2)
                            u17 (ref,  index: 3)
                            u18 (ref,  index: 4)
                        ]]
                        for _, value_9 in UserInputService_upv_1:GetGamepadState(Enum.UserInputType.Gamepad1) do
                            if (value_9.KeyCode == Enum.KeyCode.Thumbstick1) then
                                u16 = value_9.Position.X;
                                u17 = value_9.Position.Y;
                                continue;
                            end;
                            if (value_9.KeyCode ~= Enum.KeyCode.ButtonR2) then
                                if (value_9.KeyCode ~= Enum.KeyCode.ButtonL2) then
                                    continue;
                                end;
                                if (value_9.Position.Z > 0.1) then
                                    u18 = u18 - value_9.Position.Z;
                                end;
                            elseif (value_9.Position.Z > 0.1) then
                                u18 = u18 + value_9.Position.Z;
                            end;
                        end;
                    end
                );
                if (math.abs(u16) < 0.2) then
                    u16 = 0;
                end;
                if (math.abs(u17) < 0.2) then
                    u17 = 0;
                end;
                v47 = v43.Frame;
                if (not (v47)) then
                    break;
                end;
                local v48;
                if (not (v47.Parent)) then
                    break;
                end;
                if (math.abs(u18) > 0) then
                    v43.TargetScale = math.clamp(v43.TargetScale + ((u18 * 4) * v46), 1, 4);
                end;
                if (math.abs(v43.Scale - v43.TargetScale) > 0.001) then
                    v43.Scale = v43.Scale + ((v43.TargetScale - v43.Scale) * math.min(v46 * 12, 1));
                    if (math.abs(v43.Scale - v43.TargetScale) <= 0.001) then
                        v43.Scale = v43.TargetScale;
                    end;
                    v47.Size = UDim2.new(v43.Scale, 0, v43.Scale, 0);
                end;
                local v49 = math.max((v43.Scale * 0.5) - 0.5, 0);
                local v50 = 0.5 - v49;
                local v51 = v49 + 0.5;
                local Position_3 = v47.Position;
                local AbsoluteSize_1 = Map_upv_1.AbsoluteSize;
                v44 = Position_3.X.Scale;
                v45 = Position_3.Y.Scale;
                if (math.abs(u16) > 0 or math.abs(u17) > 0) then
                    v44, v45 = v44 + ((-u16 * 300) * v46) / AbsoluteSize_1.X, v45 + ((u17 * 300) * v46) / AbsoluteSize_1.Y;
                end;
                v48 = math.clamp(v44, v50, v51);
                local v52 = math.clamp(v45, v50, v51);
                if (v48 ~= Position_3.X.Scale) then
                    v47.Position = UDim2.new(v48, 0, v52, 0);
                    local v53 = UserInputService_upv_1:GetMouseLocation();
                    local AbsolutePosition_1 = Map_upv_1.AbsolutePosition;
                    local AbsoluteSize_2 = Map_upv_1.AbsoluteSize;
                    MapToolTip_upv_1.Position = UDim2.new(math.clamp((v53.X - AbsolutePosition_1.X) / AbsoluteSize_2.X, 0, 1), 0, math.clamp((v53.Y - AbsolutePosition_1.Y) / AbsoluteSize_2.Y, 0, 1), 0);
                    continue;
                end;
                if (v52 ~= Position_3.Y.Scale) then
                    v47.Position = UDim2.new(v48, 0, v52, 0);
                end;
                local v53 = UserInputService_upv_1:GetMouseLocation();
                local AbsolutePosition_1 = Map_upv_1.AbsolutePosition;
                local AbsoluteSize_2 = Map_upv_1.AbsoluteSize;
                MapToolTip_upv_1.Position = UDim2.new(math.clamp((v53.X - AbsolutePosition_1.X) / AbsoluteSize_2.X, 0, 1), 0, math.clamp((v53.Y - AbsolutePosition_1.Y) / AbsoluteSize_2.Y, 0, 1), 0);
            end;
        end;
        u14 = false;
    end;
end;
GuiUtil_upv_1:AddScrollToFrame(Map_upv_1, 1, 4, 0.15, 1.15);
Map_upv_1.MouseButton2Down:Connect(
    function()
        --[[
          line: 484
          upvalues:
            Map_upv_1 (copy, index: 1)
            UserInputService_upv_1 (copy, index: 2)
            u2 (copy, index: 3)
            PlayerGui_upv_1 (copy, index: 4)
            u10 (copy, index: 5)
        ]]
        if (script:GetAttribute("MapOpen")) then
            local Map_3 = Map_upv_1.Frame.Map;
            local v54 = UserInputService_upv_1:GetMouseLocation() - (Map_3.AbsolutePosition + Vector2.new(0, 36));
            local v55 = UDim2.new(v54.X / Map_3.AbsoluteSize.X, 0, v54.Y / Map_3.AbsoluteSize.Y, 0);
            local v56 = Vector2.new((v55.X.Scale - 0.5) * 12800, (v55.Y.Scale - 0.5) * 12800) + u2;
            Map_3.Pin.Position = v55;
            Map_3.Pin.Visible = true;
            PlayerGui_upv_1:SetAttribute("PlayerMapPin", v56);
            u10();
        end;
    end
);
Humanoid_upv_1:GetAttributeChangedSignal("AttemptRespawn"):Connect(
    function()
        --[[
          line: 496
          upvalues:
            GuiUtil_upv_1 (copy, index: 1)
            Map_upv_1 (copy, index: 2)
        ]]
        GuiUtil_upv_1:ClearScrollFrame(Map_upv_1);
    end
);
local function u19(a1)
    --[[
      line: 365
      upvalues:
        Map_upv_1 (copy, index: 1)
        Values_upv_1 (copy, index: 2)
        InventoryController_upv_1 (copy, index: 3)
        UserInputService_upv_1 (copy, index: 4)
        GamepadService_upv_1 (copy, index: 5)
        PreferredInputController_upv_1 (copy, index: 6)
        MapToolTip_upv_1 (copy, index: 7)
    ]]
    if (Map_upv_1:GetAttribute("Locked") or a1 and not (Values_upv_1.MapEnabled.Value)) then
        return;
    end;
    Map_upv_1.Visible = a1;
    if (not (InventoryController_upv_1:GetAttribute("Open")) or a1) then
        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior[(a1 and "Default") or "LockCenter"];
        UserInputService_upv_1.MouseIconEnabled = a1;
    end;
    if (a1) then
        pcall(
            function()
                --[[
                  line: 374
                  upvalues:
                    GamepadService_upv_1 (copy, index: 1)
                ]]
                GamepadService_upv_1:EnableGamepadCursor(nil);
            end
        );
    elseif (not (InventoryController_upv_1:GetAttribute("Open"))) then
        pcall(
            function()
                --[[
                  line: 377
                  upvalues:
                    GamepadService_upv_1 (copy, index: 1)
                ]]
                GamepadService_upv_1:DisableGamepadCursor();
            end
        );
    end;
    local v57 = PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad";
    MapToolTip_upv_1.Visible = a1 and v57;
    script:SetAttribute("MapOpen", a1);
    if ((a1)) then
        return;
    end;
    script:SetAttribute("MapClosedTick", tick());
end;
Humanoid_upv_1:GetAttributeChangedSignal("Downed"):Connect(
    function()
        --[[
          line: 499
          upvalues:
            u19 (copy, index: 1)
            u13 (ref,  index: 2)
        ]]
        u19(false);
        u13 = false;
    end
);
Humanoid_upv_1.Died:Connect(
    function()
        --[[
          line: 503
          upvalues:
            u13 (ref,  index: 1)
            HumanoidRootPart_upv_1 (copy, index: 2)
            PlayerGui_upv_1 (copy, index: 3)
            Map_upv_1 (copy, index: 4)
            u2 (copy, index: 5)
        ]]
        u13 = false;
        if (HumanoidRootPart_upv_1.Parent) then
            local Position_4 = HumanoidRootPart_upv_1.Position;
            local v58 = Vector2.new(Position_4.X, Position_4.Z);
            PlayerGui_upv_1:SetAttribute("LastDeathPin", v58);
            local DeathMarker_1 = Map_upv_1.Frame.Map.DeathMarker;
            local v59 = ((typeof(v58) == "Vector3") and (v58.Z)) or (v58.Y);
            DeathMarker_1.Position = UDim2.new(0.5 + ((v58.X - u2.X) / 12800), 0, 0.5 + ((v59 - u2.Y) / 12800), 0);
            DeathMarker_1.Visible = true;
        end;
    end
);
UserInputService_upv_1.InputBegan:Connect(
    function(a1, a2)
        --[[
          line: 514
          upvalues:
            SettingsModule_upv_1 (copy, index: 1)
            UserInputService_upv_1 (copy, index: 2)
            Humanoid_upv_1 (copy, index: 3)
            u13 (ref,  index: 4)
            u19 (copy, index: 5)
            Map_upv_1 (copy, index: 6)
            u2 (copy, index: 7)
            PlayerGui_upv_1 (copy, index: 8)
            u10 (copy, index: 9)
        ]]
        local v60;
        if (SettingsModule_upv_1.MainMenuOpen()) then
            return;
        end;
        v60 = a1.UserInputType;
        if (v60 == Enum.UserInputType.Gamepad1) then
            if (not (UserInputService_upv_1:GetFocusedTextBox()) and not (Humanoid_upv_1:GetAttribute("Downed"))) then
                local v61 = nil;
                if (Humanoid_upv_1 and (Humanoid_upv_1.Parent and (Humanoid_upv_1.Health > 0))) then
                    v61 = a1.KeyCode.Name;
                    if (v61 == "ButtonB" and u13) then
                        return;
                    end;
                    if (v61 == "ButtonB" and u13) then
                        u13 = false;
                        u19(false);
                        return;
                    end;
                    if (v61 == "ButtonA" and u13) then
                        local Map_4 = Map_upv_1.Frame.Map;
                        local v62 = UserInputService_upv_1:GetMouseLocation() - (Map_4.AbsolutePosition + Vector2.new(0, 36));
                        local v63 = UDim2.new(v62.X / Map_4.AbsoluteSize.X, 0, v62.Y / Map_4.AbsoluteSize.Y, 0);
                        local v64 = Vector2.new((v63.X.Scale - 0.5) * 12800, (v63.Y.Scale - 0.5) * 12800) + u2;
                        Map_4.Pin.Position = v63;
                        Map_4.Pin.Visible = true;
                        PlayerGui_upv_1:SetAttribute("PlayerMapPin", v64);
                        u10();
                    end;
                    return;
                end;
            end;
            return;
        elseif (not (a2)) then
            if (not (UserInputService_upv_1:GetFocusedTextBox()) and not (Humanoid_upv_1:GetAttribute("Downed")) and Humanoid_upv_1 and (Humanoid_upv_1.Parent and (Humanoid_upv_1.Health > 0))) then
                if (v60 == Enum.UserInputType.Keyboard and a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Controls", "Open Map")) then
                    u19(true);
                end;
                return;
            end;
            return;
        end;
    end
);
UserInputService_upv_1.InputEnded:Connect(
    function(a1, a2)
        --[[
          line: 544
          upvalues:
            UserInputService_upv_1 (copy, index: 1)
            SettingsModule_upv_1 (copy, index: 2)
            u19 (copy, index: 3)
            ChatController_upv_1 (copy, index: 4)
            u13 (ref,  index: 5)
            u15 (copy, index: 6)
        ]]
        local UserInputType_1 = a1.UserInputType;
        if (UserInputService_upv_1:GetFocusedTextBox()) then
            return;
        end;
        if (UserInputType_1 ~= Enum.UserInputType.Keyboard) then
            if (UserInputType_1 == Enum.UserInputType.Gamepad1 and a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Gamepad", "Open Map") and not (ChatController_upv_1:GetAttribute("Typing"))) then
                u13 = not u13;
                u19(u13);
                if (u13) then
                    task.spawn(u15);
                end;
            end;
        elseif (a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Controls", "Open Map")) then
            u19(false);
            return;
        end;
    end
);
u19(false);
InventoryController_upv_1:GetAttributeChangedSignal("CurOpen"):Connect(
    function()
        --[[
          line: 566
          upvalues:
            InventoryController_upv_1 (copy, index: 1)
            u4 (ref,  index: 2)
            TeamList_upv_1 (copy, index: 3)
            CreateLeaveTeam_upv_1 (copy, index: 4)
            u7 (ref,  index: 5)
            u5 (ref,  index: 6)
            tbl_upv_1 (copy, index: 7)
        ]]
        local v65 = InventoryController_upv_1:GetAttribute("CurOpen");
        if (v65 ~= u4) then
            u4 = v65;
            local v66 = v65 == "Inventory";
            local v67 = script:GetAttribute("InTeam");
            TeamList_upv_1.Visible = v67 and (v65 ~= "Crafting");
            TeamList_upv_1.Position = UDim2.new(0, 0, (v66 and 0.04) or 0, 0);
            CreateLeaveTeam_upv_1.Label.Text = (v67 and "LEAVE TEAM") or "CREATE TEAM";
            CreateLeaveTeam_upv_1.Visible = not u7 and v66;
            if ((u5) or not v66) then
                for _, value_10 in pairs(tbl_upv_1) do
                    value_10.Visible = v66;
                end;
                return;
            end;
        end;
    end
);
script:WaitForChild("FetchTeam").OnInvoke = function()
    --[[
      line: 583
      upvalues:
        u6 (ref, index: 1)
    ]]
    return u6;
end;
local u20 = 0;
u1(
    "Setup",
    "\001\1401\200\176V\254\208\146<o*\1271=\030D\166cI",
    "\b6X\151o\242\018+\245J\208\246\243\136\196K)T\148\001",
    function(a1, a2, a3, a4, a5)
        --[[
          line: 589
          upvalues:
            u11 (copy, index: 1)
            u8 (copy, index: 2)
            UpdateChannel_upv_1 (copy, index: 3)
            u5 (ref,  index: 4)
            Players_upv_1 (copy, index: 5)
            u20 (ref,  index: 6)
            tbl_upv_1 (copy, index: 7)
            InventoryController_upv_1 (copy, index: 8)
        ]]
        if (a1 == "Update") then
            u11(a2, a4);
            if (a3) then
                u8(a3, a2);
            end;
            shared.YourTeam = a5;
            UpdateChannel_upv_1:Fire("Team");
        elseif (a1 == "Invite") then
            u5 = a2[1];
            local u21 = nil;
            pcall(
                function()
                    --[[
                      line: 602
                      upvalues:
                        u21 (ref,  index: 1)
                        Players_upv_1 (copy, index: 2)
                        u5 (ref,  index: 3)
                    ]]
                    u21 = Players_upv_1:GetNameFromUserIdAsync(u5);
                end
            );
            u21 = u21 or (u5 .. "_ERROR");
            local v68 = "Join " .. u21 .. "'s Team";
            local v69 = os.clock() - u20;
            if ((((v68 ~= tbl_upv_1[3].Text) and 8) or 30) <= v69) then
                u20 = os.clock();
                script.InviteNotification:Play();
            end;
            tbl_upv_1[3].Text = v68;
            if (InventoryController_upv_1:GetAttribute("CurOpen") ~= "Inventory") then
                return;
            end;
            for _, value_11 in pairs(tbl_upv_1) do
                value_11.Visible = true;
            end;
        end;
    end
);
tbl_upv_1[1].MouseButton1Click:Connect(
    function()
        --[[
          line: 619
          upvalues:
            u5 (ref,  index: 1)
            tbl_upv_1 (copy, index: 2)
            u1 (copy, index: 3)
        ]]
        if (not u5) then
            return;
        end;
        for _, value_12 in pairs(tbl_upv_1) do
            value_12.Visible = false;
        end;
        u1("Fire", "\001\1401\200\176V\254\208\146<o*\1271=\030D\166cI", "\b6X\151o\242\018+\245J\208\246\243\136\196K)T\148\001", "Join", u5);
        u5 = false;
    end
);
tbl_upv_1[2].MouseButton1Click:Connect(
    function()
        --[[
          line: 631
          upvalues:
            u5 (ref,  index: 1)
            tbl_upv_1 (copy, index: 2)
        ]]
        u5 = false;
        for _, value_13 in pairs(tbl_upv_1) do
            value_13.Visible = false;
        end;
    end
);
CreateLeaveTeam_upv_1.MouseButton1Click:Connect(
    function()
        --[[
          line: 637
          upvalues:
            u7 (ref,  index: 1)
            CreateLeaveTeam_upv_1 (copy, index: 2)
            u1 (copy, index: 3)
            InventoryController_upv_1 (copy, index: 4)
            u6 (ref,  index: 5)
        ]]
        u7 = true;
        CreateLeaveTeam_upv_1.Visible = false;
        u1("Fire", "\001\1401\200\176V\254\208\146<o*\1271=\030D\166cI", "\b6X\151o\242\018+\245J\208\246\243\136\196K)T\148\001", "Create/Leave");
        task.delay(
            2,
            function()
                --[[
                  line: 645
                  upvalues:
                    u7 (ref,  index: 1)
                    InventoryController_upv_1 (copy, index: 2)
                    CreateLeaveTeam_upv_1 (copy, index: 3)
                    u6 (ref,  index: 4)
                ]]
                u7 = false;
                if (InventoryController_upv_1:GetAttribute("CurOpen") ~= "Inventory") then
                    return;
                end;
                CreateLeaveTeam_upv_1.Label.Text = ((#u6 <= 0) and "CREATE TEAM") or "LEAVE TEAM";
                CreateLeaveTeam_upv_1.Visible = true;
            end
        );
    end
);
local v70 = PlayerGui_upv_1:GetAttribute("PlayerMapPin");
local v73 = nil;
local v72 = nil;
if (v70) then
    v72 = Map_upv_1.Frame.Map.Pin;
    v73 = ((typeof(v70) == "Vector3") and (v70.Z)) or (v70.Y);
    v73 = 0.5 + ((v73 - u2.Y) / 12800);
    v72.Position = UDim2.new(0.5 + ((v70.X - u2.X) / 12800), 0, v73, 0);
    v72.Visible = true;
end;
v72 = PlayerGui_upv_1:GetAttribute("LastDeathPin");
if (v72) then
    local DeathMarker_2 = Map_upv_1.Frame.Map.DeathMarker;
    local v74 = ((typeof(v72) == "Vector3") and (v72.Z)) or (v72.Y);
    v73 = 0;
    DeathMarker_2.Position = UDim2.new(0.5 + ((v72.X - u2.X) / 12800), v73, 0.5 + ((v74 - u2.Y) / 12800), 0);
    DeathMarker_2.Visible = true;
end;
CurrentCamera_upv_1:GetPropertyChangedSignal("CFrame"):Connect(u10);
u10();
PlayerCursor_upv_1.PlayerName.Text = LocalPlayer_upv_1.Name;
local TradingPost_upv_1 = Map_upv_1.Frame.Map:WaitForChild("TradingPost");
local function u22(a1)
    --[[
      line: 674
    ]]
    for n_2 = 1, 5 do
        local v75;
        v75 = a1.Offers[(n_2 * 2) - 1];
        local v76 = a1.Offers[n_2 * 2];
        if (type(v75) ~= "table" or v75[1] == 0 or type(v76) ~= "table" or v76[1] == 0) then
            continue;
        end;
        return true;
    end;
    return false;
end;
task.defer(
    function()
        --[[
          line: 683
          upvalues:
            ActiveBenchModule_upv_1 (copy, index: 1)
            u22 (copy, index: 2)
            tbl_upv_5 (copy, index: 3)
            Map_upv_1 (copy, index: 4)
            TradingPost_upv_1 (copy, index: 5)
            u2 (copy, index: 6)
            TweenUtil_upv_1 (copy, index: 7)
            Items_upv_1 (copy, index: 8)
            NumberUtil_upv_1 (copy, index: 9)
        ]]
        local v77 = 0;
        for key_upv_6, value_14 in ActiveBenchModule_upv_1.GetAllRawClientInfos() do
            if (value_14 and value_14.Offers and u22(value_14)) then
                local u23 = tbl_upv_5[key_upv_6];
                if (u23 and u23.Parent) then
                    v77 = v77 + 1;
                    if (v77 % 100 == 0) then
                        task.wait();
                    end;
                elseif (u23) then
                    u23:Destroy();
                    u23 = Map_upv_1.Frame.Map.ShopTemplate:Clone();
                    u23.Name = "ShopMarker";
                    u23.Parent = Map_upv_1.Frame.Map;
                    u23.Visible = true;
                    u23.MouseEnter:Connect(
                        function()
                            --[[
                              line: 699
                              upvalues:
                                u23 (ref, index: 1)
                            ]]
                            u23.ZIndex = 7;
                        end
                    );
                    u23.MouseLeave:Connect(
                        function()
                            --[[
                              line: 702
                              upvalues:
                                u23 (ref, index: 1)
                            ]]
                            u23.ZIndex = 4;
                        end
                    );
                    u23.Activated:Connect(
                        function()
                            --[[
                              line: 705
                              upvalues:
                                TradingPost_upv_1 (copy, index: 1)
                                ActiveBenchModule_upv_1 (copy, index: 2)
                                key_upv_6 (copy, index: 3)
                                u23 (ref,  index: 4)
                                Map_upv_1 (copy, index: 5)
                                tbl_upv_5 (copy, index: 6)
                                u2 (copy, index: 7)
                                TweenUtil_upv_1 (copy, index: 8)
                                Items_upv_1 (copy, index: 9)
                                NumberUtil_upv_1 (copy, index: 10)
                            ]]
                            local v78 = nil;
                            if (TradingPost_upv_1.Parent) then
                                v78 = ActiveBenchModule_upv_1.GetClientInfoFromTag(key_upv_6);
                                local v79 = nil;
                                if (v78) then
                                    v79 = v78.Offers;
                                end;
                                if (not v78 or not v79) then
                                    return;
                                end;
                                if (TradingPost_upv_1.Parent ~= u23) then
                                    local tbl_upv_9 = {};
                                    if (u23.LayoutOrder ~= 1) then
                                        local v80 = nil;
                                        local v81 = nil;
                                        for key_7, value_15 in tbl_upv_5 do
                                            if (not (value_15) or not (value_15.Parent) or value_15.LayoutOrder == 1) then
                                                continue;
                                            end;
                                            v80 = ActiveBenchModule_upv_1.GetClientInfoFromTag(key_7);
                                            if (not (v80)) then
                                                continue;
                                            end;
                                            v81 = v80.Pos;
                                            if (not (v81)) then
                                                continue;
                                            end;
                                            if ((v78.Pos - v81).Magnitude <= 150) then
                                                table.insert(tbl_upv_9, {value_15, key_7, v80});
                                            end;
                                        end;
                                    end;
                                    if (#tbl_upv_9 <= 1) then
                                        TradingPost_upv_1.Position = UDim2.new(-3.61, 0, ((u23.Position.Y.Scale < 0.725) and 1.3) or -12.7, 0);
                                        TradingPost_upv_1.Visible = true;
                                        TradingPost_upv_1.Parent = u23;
                                        TradingPost_upv_1.Frame.Position = UDim2.new();
                                        for n_3 = 1, 5 do
                                            local v82;
                                            v82 = v79[(n_3 * 2) - 1];
                                            local v83 = v79[n_3 * 2];
                                            local v84 = TradingPost_upv_1.Frame[("Give%*"):format(n_3)];
                                            local v85 = TradingPost_upv_1.Frame[("Receive%*"):format(n_3)];
                                            if (type(v82) == "table" and v82[1] ~= 0 and Items_upv_1[v82[1]]) then
                                                local v86 = Items_upv_1[v82[1]];
                                                v84.Empty.Visible = false;
                                                local ItemImage_1 = v84.ItemImage;
                                                local v87 = ((type(v86.Image) == "table") and (v86.Image.Default)) or (v86.Image);
                                                ItemImage_1.Image = v87;
                                                v84.ItemAmount.Text = ("x%*"):format(NumberUtil_upv_1:FormatNumber(v82[2]));
                                            else
                                                v84.Empty.Visible = true;
                                                v84.ItemImage.Image = "";
                                                v84.ItemAmount.Text = "";
                                            end;
                                            if (type(v83) ~= "table" or v83[1] == 0) then
                                                v85.Empty.Visible = true;
                                                v85.ItemImage.Image = "";
                                                v85.ItemAmount.Text = "";
                                                continue;
                                            end;
                                            if (Items_upv_1[v83[1]]) then
                                                local v88 = Items_upv_1[v83[1]];
                                                v85.Empty.Visible = false;
                                                local ItemImage_2 = v85.ItemImage;
                                                local v87 = ((type(v88.Image) == "table") and (v88.Image.Default)) or (v88.Image);
                                                ItemImage_2.Image = v87;
                                                v85.ItemAmount.Text = ("x%*"):format(NumberUtil_upv_1:FormatNumber(v83[2]));
                                            else
                                                v85.Empty.Visible = true;
                                                v85.ItemImage.Image = "";
                                                v85.ItemAmount.Text = "";
                                            end;
                                        end;
                                        TweenUtil_upv_1:Tween(TradingPost_upv_1.Frame, "Position", UDim2.new(0, 0, 1, 0), 0.5, "Quart", "Out");
                                    else
                                        print((("found %* shop icons in a cluster"):format(#tbl_upv_9)));
                                        local Pos_1 = v78.Pos;
                                        local v89 = ((typeof(Pos_1) == "Vector3") and (Pos_1.Z)) or (Pos_1.Y);
                                        local v90 = UDim2.new(0.5 + ((Pos_1.X - u2.X) / 12800), 0, 0.5 + ((v89 - u2.Y) / 12800), 0);
                                        local v91 = nil;
                                        for key_8, value_16 in tbl_upv_9 do
                                            v91 = value_16[1];
                                            v91.LayoutOrder = 1;
                                            TweenUtil_upv_1:Tween(v91, "Position", v90 + UDim2.new(0.02 * (key_8 - 1), 0, 0, 0), 0.5, "Quart", "Out");
                                        end;
                                        task.delay(
                                            5,
                                            function()
                                                --[[
                                                  line: 737
                                                  upvalues:
                                                    tbl_upv_9 (copy, index: 1)
                                                    TweenUtil_upv_1 (copy, index: 2)
                                                    u2 (copy, index: 3)
                                                ]]
                                                local v92 = nil;
                                                local v93 = nil;
                                                local v94 = nil;
                                                for _, value_17 in tbl_upv_9 do
                                                    v94 = value_17[1];
                                                    if (not (v94)) then
                                                        continue;
                                                    end;
                                                    if (v94.Parent) then
                                                        v92 = value_17[3].Pos;
                                                        v93 = ((typeof(v92) == "Vector3") and (v92.Z)) or (v92.Y);
                                                        TweenUtil_upv_1:Tween(v94, "Position", UDim2.new(0.5 + ((v92.X - u2.X) / 12800), 0, 0.5 + ((v93 - u2.Y) / 12800), 0), 0.5, "Quart", "Out");
                                                        v94.LayoutOrder = 0;
                                                    end;
                                                end;
                                            end
                                        );
                                    end;
                                else
                                    TradingPost_upv_1.Visible = false;
                                    TradingPost_upv_1.Parent = Map_upv_1.Frame.Map;
                                end;
                            end;
                        end
                    );
                    tbl_upv_5[key_upv_6] = u23;
                    v77 = v77 + 1;
                    if (v77 % 100 == 0) then
                        task.wait();
                    end;
                else
                    u23 = Map_upv_1.Frame.Map.ShopTemplate:Clone();
                    u23.Name = "ShopMarker";
                    u23.Parent = Map_upv_1.Frame.Map;
                    u23.Visible = true;
                    u23.MouseEnter:Connect(
                        function()
                            --[[
                              line: 699
                              upvalues:
                                u23 (ref, index: 1)
                            ]]
                            u23.ZIndex = 7;
                        end
                    );
                    u23.MouseLeave:Connect(
                        function()
                            --[[
                              line: 702
                              upvalues:
                                u23 (ref, index: 1)
                            ]]
                            u23.ZIndex = 4;
                        end
                    );
                    u23.Activated:Connect(
                        function()
                            --[[
                              line: 705
                              upvalues:
                                TradingPost_upv_1 (copy, index: 1)
                                ActiveBenchModule_upv_1 (copy, index: 2)
                                key_upv_6 (copy, index: 3)
                                u23 (ref,  index: 4)
                                Map_upv_1 (copy, index: 5)
                                tbl_upv_5 (copy, index: 6)
                                u2 (copy, index: 7)
                                TweenUtil_upv_1 (copy, index: 8)
                                Items_upv_1 (copy, index: 9)
                                NumberUtil_upv_1 (copy, index: 10)
                            ]]
                            local v78 = nil;
                            if (TradingPost_upv_1.Parent) then
                                v78 = ActiveBenchModule_upv_1.GetClientInfoFromTag(key_upv_6);
                                local v79 = nil;
                                if (v78) then
                                    v79 = v78.Offers;
                                end;
                                if (not v78 or not v79) then
                                    return;
                                end;
                                if (TradingPost_upv_1.Parent ~= u23) then
                                    local tbl_upv_9 = {};
                                    if (u23.LayoutOrder ~= 1) then
                                        local v80 = nil;
                                        local v81 = nil;
                                        for key_7, value_15 in tbl_upv_5 do
                                            if (not (value_15) or not (value_15.Parent) or value_15.LayoutOrder == 1) then
                                                continue;
                                            end;
                                            v80 = ActiveBenchModule_upv_1.GetClientInfoFromTag(key_7);
                                            if (not (v80)) then
                                                continue;
                                            end;
                                            v81 = v80.Pos;
                                            if (not (v81)) then
                                                continue;
                                            end;
                                            if ((v78.Pos - v81).Magnitude <= 150) then
                                                table.insert(tbl_upv_9, {value_15, key_7, v80});
                                            end;
                                        end;
                                    end;
                                    if (#tbl_upv_9 <= 1) then
                                        TradingPost_upv_1.Position = UDim2.new(-3.61, 0, ((u23.Position.Y.Scale < 0.725) and 1.3) or -12.7, 0);
                                        TradingPost_upv_1.Visible = true;
                                        TradingPost_upv_1.Parent = u23;
                                        TradingPost_upv_1.Frame.Position = UDim2.new();
                                        for n_3 = 1, 5 do
                                            local v82;
                                            v82 = v79[(n_3 * 2) - 1];
                                            local v83 = v79[n_3 * 2];
                                            local v84 = TradingPost_upv_1.Frame[("Give%*"):format(n_3)];
                                            local v85 = TradingPost_upv_1.Frame[("Receive%*"):format(n_3)];
                                            if (type(v82) == "table" and v82[1] ~= 0 and Items_upv_1[v82[1]]) then
                                                local v86 = Items_upv_1[v82[1]];
                                                v84.Empty.Visible = false;
                                                local ItemImage_1 = v84.ItemImage;
                                                local v87 = ((type(v86.Image) == "table") and (v86.Image.Default)) or (v86.Image);
                                                ItemImage_1.Image = v87;
                                                v84.ItemAmount.Text = ("x%*"):format(NumberUtil_upv_1:FormatNumber(v82[2]));
                                            else
                                                v84.Empty.Visible = true;
                                                v84.ItemImage.Image = "";
                                                v84.ItemAmount.Text = "";
                                            end;
                                            if (type(v83) ~= "table" or v83[1] == 0) then
                                                v85.Empty.Visible = true;
                                                v85.ItemImage.Image = "";
                                                v85.ItemAmount.Text = "";
                                                continue;
                                            end;
                                            if (Items_upv_1[v83[1]]) then
                                                local v88 = Items_upv_1[v83[1]];
                                                v85.Empty.Visible = false;
                                                local ItemImage_2 = v85.ItemImage;
                                                local v87 = ((type(v88.Image) == "table") and (v88.Image.Default)) or (v88.Image);
                                                ItemImage_2.Image = v87;
                                                v85.ItemAmount.Text = ("x%*"):format(NumberUtil_upv_1:FormatNumber(v83[2]));
                                            else
                                                v85.Empty.Visible = true;
                                                v85.ItemImage.Image = "";
                                                v85.ItemAmount.Text = "";
                                            end;
                                        end;
                                        TweenUtil_upv_1:Tween(TradingPost_upv_1.Frame, "Position", UDim2.new(0, 0, 1, 0), 0.5, "Quart", "Out");
                                    else
                                        print((("found %* shop icons in a cluster"):format(#tbl_upv_9)));
                                        local Pos_1 = v78.Pos;
                                        local v89 = ((typeof(Pos_1) == "Vector3") and (Pos_1.Z)) or (Pos_1.Y);
                                        local v90 = UDim2.new(0.5 + ((Pos_1.X - u2.X) / 12800), 0, 0.5 + ((v89 - u2.Y) / 12800), 0);
                                        local v91 = nil;
                                        for key_8, value_16 in tbl_upv_9 do
                                            v91 = value_16[1];
                                            v91.LayoutOrder = 1;
                                            TweenUtil_upv_1:Tween(v91, "Position", v90 + UDim2.new(0.02 * (key_8 - 1), 0, 0, 0), 0.5, "Quart", "Out");
                                        end;
                                        task.delay(
                                            5,
                                            function()
                                                --[[
                                                  line: 737
                                                  upvalues:
                                                    tbl_upv_9 (copy, index: 1)
                                                    TweenUtil_upv_1 (copy, index: 2)
                                                    u2 (copy, index: 3)
                                                ]]
                                                local v92 = nil;
                                                local v93 = nil;
                                                local v94 = nil;
                                                for _, value_17 in tbl_upv_9 do
                                                    v94 = value_17[1];
                                                    if (not (v94)) then
                                                        continue;
                                                    end;
                                                    if (v94.Parent) then
                                                        v92 = value_17[3].Pos;
                                                        v93 = ((typeof(v92) == "Vector3") and (v92.Z)) or (v92.Y);
                                                        TweenUtil_upv_1:Tween(v94, "Position", UDim2.new(0.5 + ((v92.X - u2.X) / 12800), 0, 0.5 + ((v93 - u2.Y) / 12800), 0), 0.5, "Quart", "Out");
                                                        v94.LayoutOrder = 0;
                                                    end;
                                                end;
                                            end
                                        );
                                    end;
                                else
                                    TradingPost_upv_1.Visible = false;
                                    TradingPost_upv_1.Parent = Map_upv_1.Frame.Map;
                                end;
                            end;
                        end
                    );
                    tbl_upv_5[key_upv_6] = u23;
                    v77 = v77 + 1;
                    if (v77 % 100 == 0) then
                        task.wait();
                    end;
                end;
            else
                v77 = v77 + 1;
                if (v77 % 100 == 0) then
                    task.wait();
                end;
            end;
        end;
        local v95 = 0;
        v77 = v95;
        for key_9, value_18 in tbl_upv_5 do
            v77 = v77 + 1;
            if (v77 % 50 ~= 0) then
                local v96 = ActiveBenchModule_upv_1.GetClientInfoFromTag(key_9);
                if (v96 and v96.Offers) then
                    if (v96.Pos) then
                        if (not (value_18) or not (value_18.Parent)) then
                            tbl_upv_5[key_9] = nil;
                            continue;
                        end;
                        if (not (u22(v96))) then
                            value_18:Destroy();
                            tbl_upv_5[key_9] = nil;
                            continue;
                        end;
                        local v97, v98 = nil, nil;
                        if (value_18.LayoutOrder ~= 1) then
                            v97 = v96.Pos;
                            v98 = ((typeof(v97) == "Vector3") and (v97.Z)) or (v97.Y);
                            value_18.Position = UDim2.new(0.5 + ((v97.X - u2.X) / 12800), 0, 0.5 + ((v98 - u2.Y) / 12800), 0);
                        end;
                    else
                        if (value_18) then
                            value_18:Destroy();
                        end;
                        tbl_upv_5[key_9] = nil;
                    end;
                elseif (value_18) then
                    value_18:Destroy();
                end;
            else
                task.wait();
                local v96 = ActiveBenchModule_upv_1.GetClientInfoFromTag(key_9);
                if (v96 and v96.Offers) then
                    if (v96.Pos) then
                        if (not (value_18) or not (value_18.Parent)) then
                            tbl_upv_5[key_9] = nil;
                            continue;
                        end;
                        if (not (u22(v96))) then
                            value_18:Destroy();
                            tbl_upv_5[key_9] = nil;
                            continue;
                        end;
                        local v97, v98 = nil, nil;
                        if (value_18.LayoutOrder ~= 1) then
                            v97 = v96.Pos;
                            v98 = ((typeof(v97) == "Vector3") and (v97.Z)) or (v97.Y);
                            value_18.Position = UDim2.new(0.5 + ((v97.X - u2.X) / 12800), 0, 0.5 + ((v98 - u2.Y) / 12800), 0);
                        end;
                    else
                        if (value_18) then
                            value_18:Destroy();
                        end;
                        tbl_upv_5[key_9] = nil;
                    end;
                elseif (value_18) then
                    value_18:Destroy();
                end;
            end;
        end;
        task.wait(20);
    end
);
v5 = u6;
local v99 = nil;
if (tick() - v3 < 0.2) then
    if (tick() - v4 >= 1) then
        v4 = tick();
        local v100 = nil;
        for key_10, v73 in pairs(shared.cachedTeamModels) do
            if (v73.Parent == nil) then
                shared.cachedTeamModels[key_10] = nil;
                continue;
            end;
            for _, value_19 in pairs(v5) do
                if (key_10 == tonumber(value_19)) then
                    break;
                end;
            end;
            if (false) then
                continue;
            end;
            shared.cachedTeamModels[key_10] = nil;
            v100 = v73:FindFirstChild("NameTag");
            if (v100) then
                v100.MaxDistance = tbl_4.MaxDistance.Default;
                v100.AlwaysOnTop = false;
            end;
            if (v100 and v100:FindFirstChild("Label")) then
                v100.Label.TextColor3 = tbl_4.TextColor3.Default;
                local TeamHighlight_2 = v73:FindFirstChild("TeamHighlight");
                if (TeamHighlight_2) then
                    TeamHighlight_2:Destroy();
                end;
            else
                local TeamHighlight_2 = v73:FindFirstChild("TeamHighlight");
                if (TeamHighlight_2) then
                    TeamHighlight_2:Destroy();
                end;
            end;
        end;
    end;
    u8();
    task.wait(0.1);
else
    v3 = tick();
    checkRay = tick() - v2 >= 0.4;
    local DetailLabel_1 = TeamList_upv_1.DetailLabel;
    if (LocalPlayer_upv_1.Team) then
        v99 = LocalPlayer_upv_1.Team.TeamColor.Color;
        if (v99) then
            DetailLabel_1.TextColor3 = v99;
            local v102 = nil;
            v73 = nil;
            local v103 = nil;
            local v100 = nil;
            local v104 = nil;
            for _, v73 in pairs(v5) do
                if (v73 == "CantLeave") then
                    continue;
                end;
                v73 = tonumber(v73);
                if (v73 == LocalPlayer_upv_1.UserId) then
                    continue;
                end;
                v103 = Players_upv_1:GetPlayerByUserId(v73);
                v100 = v103;
                v100 = v100 and (v103.Character);
                v104 = shared.cachedTeamModels[v73];
                if (v104 and v104.Parent ~= nil) then
                    local NameTag_1 = v100:FindFirstChild("NameTag");
                    v102 = v100:FindFirstChild("TeamHighlight");
                    if (v102) then
                        local v105 = v103 and (v103.Team);
                        local v106 = v105 and (v105.TeamColor.Color);
                        if (v106) then
                            v102.FillColor = v106;
                            v102.OutlineColor = v106;
                        end;
                        if (NameTag_1 and NameTag_1:FindFirstChild("Label")) then
                            NameTag_1.MaxDistance = tbl_4.MaxDistance.Team;
                            NameTag_1.AlwaysOnTop = true;
                            NameTag_1.Label.TextColor3 = v105 or (tbl_4.TextColor3.Team);
                            local v107, v108;
                            if (not (checkRay)) then
                                continue;
                            end;
                            v2 = tick();
                            v107 = v1:FindFirstChild("Head");
                            v108 = v103:FindFirstChild("Head");
                            if (not (v107)) then
                                continue;
                            end;
                            local v109 = nil;
                            if (v108) then
                                v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                                v102.FillTransparency = (v109 and 0.5) or 1;
                                v102.OutlineTransparency = (v109 and 0) or 0.5;
                                v102.Enabled = true;
                            end;
                        else
                            local v107, v108;
                            if (not (checkRay)) then
                                continue;
                            end;
                            v2 = tick();
                            v107 = v1:FindFirstChild("Head");
                            v108 = v103:FindFirstChild("Head");
                            if (not (v107)) then
                                continue;
                            end;
                            local v109 = nil;
                            if (v108) then
                                v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                                v102.FillTransparency = (v109 and 0.5) or 1;
                                v102.OutlineTransparency = (v109 and 0) or 0.5;
                                v102.Enabled = true;
                            end;
                        end;
                    else
                        v102 = TeamHighlight_1:Clone();
                        v102.Parent = v100;
                        local v105 = v103 and (v103.Team);
                        local v106 = v105 and (v105.TeamColor.Color);
                        if (v106) then
                            v102.FillColor = v106;
                            v102.OutlineColor = v106;
                        end;
                        if (NameTag_1 and NameTag_1:FindFirstChild("Label")) then
                            NameTag_1.MaxDistance = tbl_4.MaxDistance.Team;
                            NameTag_1.AlwaysOnTop = true;
                            NameTag_1.Label.TextColor3 = v105 or (tbl_4.TextColor3.Team);
                            local v107, v108;
                            if (not (checkRay)) then
                                continue;
                            end;
                            v2 = tick();
                            v107 = v1:FindFirstChild("Head");
                            v108 = v103:FindFirstChild("Head");
                            if (not (v107)) then
                                continue;
                            end;
                            local v109 = nil;
                            if (v108) then
                                v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                                v102.FillTransparency = (v109 and 0.5) or 1;
                                v102.OutlineTransparency = (v109 and 0) or 0.5;
                                v102.Enabled = true;
                            end;
                        else
                            local v107, v108;
                            if (not (checkRay)) then
                                continue;
                            end;
                            v2 = tick();
                            v107 = v1:FindFirstChild("Head");
                            v108 = v103:FindFirstChild("Head");
                            if (not (v107)) then
                                continue;
                            end;
                            local v109 = nil;
                            if (v108) then
                                v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                                v102.FillTransparency = (v109 and 0.5) or 1;
                                v102.OutlineTransparency = (v109 and 0) or 0.5;
                                v102.Enabled = true;
                            end;
                        end;
                    end;
                else
                    if (not (v103) or not (v103) or not (v103) or not (v103)) then
                        continue;
                    end;
                    shared.cachedTeamModels[v73] = v103;
                    local NameTag_1 = v100:FindFirstChild("NameTag");
                    v102 = v100:FindFirstChild("TeamHighlight");
                    if (v102) then
                        local v105 = v103 and (v103.Team);
                        local v106 = v105 and (v105.TeamColor.Color);
                        if (v106) then
                            v102.FillColor = v106;
                            v102.OutlineColor = v106;
                        end;
                    else
                        v102 = TeamHighlight_1:Clone();
                        v102.Parent = v100;
                        local v105 = v103 and (v103.Team);
                        local v106 = v105 and (v105.TeamColor.Color);
                        if (v106) then
                            v102.FillColor = v106;
                            v102.OutlineColor = v106;
                        end;
                    end;
                end;
            end;
            if (tick() - v4 >= 1) then
                v4 = tick();
                for key_10, v73 in pairs(shared.cachedTeamModels) do
                    if (v73.Parent == nil) then
                        shared.cachedTeamModels[key_10] = nil;
                        continue;
                    end;
                    for _, value_19 in pairs(v5) do
                        if (key_10 == tonumber(value_19)) then
                            break;
                        end;
                    end;
                    if (false) then
                        continue;
                    end;
                    shared.cachedTeamModels[key_10] = nil;
                    v100 = v73:FindFirstChild("NameTag");
                    if (v100) then
                        v100.MaxDistance = tbl_4.MaxDistance.Default;
                        v100.AlwaysOnTop = false;
                    end;
                    if (v100 and v100:FindFirstChild("Label")) then
                        v100.Label.TextColor3 = tbl_4.TextColor3.Default;
                        local TeamHighlight_2 = v73:FindFirstChild("TeamHighlight");
                        if (TeamHighlight_2) then
                            TeamHighlight_2:Destroy();
                        end;
                    else
                        local TeamHighlight_2 = v73:FindFirstChild("TeamHighlight");
                        if (TeamHighlight_2) then
                            TeamHighlight_2:Destroy();
                        end;
                    end;
                end;
            end;
            u8();
            task.wait(0.1);
        else
            v73 = 1;
            v99 = Color3.new(1, 1, v73);
            DetailLabel_1.TextColor3 = v99;
            local v102 = nil;
            v73 = nil;
            local v103 = nil;
            local v100 = nil;
            local v104 = nil;
            for _, v73 in pairs(v5) do
                if (v73 == "CantLeave") then
                    continue;
                end;
                v73 = tonumber(v73);
                if (v73 == LocalPlayer_upv_1.UserId) then
                    continue;
                end;
                v103 = Players_upv_1:GetPlayerByUserId(v73);
                v100 = v103;
                v100 = v100 and (v103.Character);
                v104 = shared.cachedTeamModels[v73];
                if (v104 and v104.Parent ~= nil) then
                    local NameTag_1 = v100:FindFirstChild("NameTag");
                    v102 = v100:FindFirstChild("TeamHighlight");
                    if (v102) then
                        local v105 = v103 and (v103.Team);
                        local v106 = v105 and (v105.TeamColor.Color);
                        if (v106) then
                            v102.FillColor = v106;
                            v102.OutlineColor = v106;
                        end;
                        if (NameTag_1 and NameTag_1:FindFirstChild("Label")) then
                            NameTag_1.MaxDistance = tbl_4.MaxDistance.Team;
                            NameTag_1.AlwaysOnTop = true;
                            NameTag_1.Label.TextColor3 = v105 or (tbl_4.TextColor3.Team);
                            local v107, v108;
                            if (not (checkRay)) then
                                continue;
                            end;
                            v2 = tick();
                            v107 = v1:FindFirstChild("Head");
                            v108 = v103:FindFirstChild("Head");
                            if (not (v107)) then
                                continue;
                            end;
                            local v109 = nil;
                            if (v108) then
                                v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                                v102.FillTransparency = (v109 and 0.5) or 1;
                                v102.OutlineTransparency = (v109 and 0) or 0.5;
                                v102.Enabled = true;
                            end;
                        else
                            local v107, v108;
                            if (not (checkRay)) then
                                continue;
                            end;
                            v2 = tick();
                            v107 = v1:FindFirstChild("Head");
                            v108 = v103:FindFirstChild("Head");
                            if (not (v107)) then
                                continue;
                            end;
                            local v109 = nil;
                            if (v108) then
                                v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                                v102.FillTransparency = (v109 and 0.5) or 1;
                                v102.OutlineTransparency = (v109 and 0) or 0.5;
                                v102.Enabled = true;
                            end;
                        end;
                    else
                        v102 = TeamHighlight_1:Clone();
                        v102.Parent = v100;
                        local v105 = v103 and (v103.Team);
                        local v106 = v105 and (v105.TeamColor.Color);
                        if (v106) then
                            v102.FillColor = v106;
                            v102.OutlineColor = v106;
                        end;
                        if (NameTag_1 and NameTag_1:FindFirstChild("Label")) then
                            NameTag_1.MaxDistance = tbl_4.MaxDistance.Team;
                            NameTag_1.AlwaysOnTop = true;
                            NameTag_1.Label.TextColor3 = v105 or (tbl_4.TextColor3.Team);
                            local v107, v108;
                            if (not (checkRay)) then
                                continue;
                            end;
                            v2 = tick();
                            v107 = v1:FindFirstChild("Head");
                            v108 = v103:FindFirstChild("Head");
                            if (not (v107)) then
                                continue;
                            end;
                            local v109 = nil;
                            if (v108) then
                                v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                                v102.FillTransparency = (v109 and 0.5) or 1;
                                v102.OutlineTransparency = (v109 and 0) or 0.5;
                                v102.Enabled = true;
                            end;
                        else
                            local v107, v108;
                            if (not (checkRay)) then
                                continue;
                            end;
                            v2 = tick();
                            v107 = v1:FindFirstChild("Head");
                            v108 = v103:FindFirstChild("Head");
                            if (not (v107)) then
                                continue;
                            end;
                            local v109 = nil;
                            if (v108) then
                                v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                                v102.FillTransparency = (v109 and 0.5) or 1;
                                v102.OutlineTransparency = (v109 and 0) or 0.5;
                                v102.Enabled = true;
                            end;
                        end;
                    end;
                else
                    if (not (v103) or not (v103) or not (v103) or not (v103)) then
                        continue;
                    end;
                    shared.cachedTeamModels[v73] = v103;
                    local NameTag_1 = v100:FindFirstChild("NameTag");
                    v102 = v100:FindFirstChild("TeamHighlight");
                    if (v102) then
                        local v105 = v103 and (v103.Team);
                        local v106 = v105 and (v105.TeamColor.Color);
                        if (v106) then
                            v102.FillColor = v106;
                            v102.OutlineColor = v106;
                        end;
                    else
                        v102 = TeamHighlight_1:Clone();
                        v102.Parent = v100;
                        local v105 = v103 and (v103.Team);
                        local v106 = v105 and (v105.TeamColor.Color);
                        if (v106) then
                            v102.FillColor = v106;
                            v102.OutlineColor = v106;
                        end;
                    end;
                end;
            end;
            if (tick() - v4 >= 1) then
                v4 = tick();
                for key_10, v73 in pairs(shared.cachedTeamModels) do
                    if (v73.Parent == nil) then
                        shared.cachedTeamModels[key_10] = nil;
                        continue;
                    end;
                    for _, value_19 in pairs(v5) do
                        if (key_10 == tonumber(value_19)) then
                            break;
                        end;
                    end;
                    if (false) then
                        continue;
                    end;
                    shared.cachedTeamModels[key_10] = nil;
                    v100 = v73:FindFirstChild("NameTag");
                    if (v100) then
                        v100.MaxDistance = tbl_4.MaxDistance.Default;
                        v100.AlwaysOnTop = false;
                    end;
                    if (v100 and v100:FindFirstChild("Label")) then
                        v100.Label.TextColor3 = tbl_4.TextColor3.Default;
                        local TeamHighlight_2 = v73:FindFirstChild("TeamHighlight");
                        if (TeamHighlight_2) then
                            TeamHighlight_2:Destroy();
                        end;
                    else
                        local TeamHighlight_2 = v73:FindFirstChild("TeamHighlight");
                        if (TeamHighlight_2) then
                            TeamHighlight_2:Destroy();
                        end;
                    end;
                end;
            end;
            u8();
            task.wait(0.1);
        end;
    else
        v73 = 1;
        v99 = Color3.new(1, 1, v73);
        DetailLabel_1.TextColor3 = v99;
        local v102 = nil;
        v73 = nil;
        local v103 = nil;
        local v100 = nil;
        local v104 = nil;
        for _, v73 in pairs(v5) do
            if (v73 == "CantLeave") then
                continue;
            end;
            v73 = tonumber(v73);
            if (v73 == LocalPlayer_upv_1.UserId) then
                continue;
            end;
            v103 = Players_upv_1:GetPlayerByUserId(v73);
            v100 = v103;
            v100 = v100 and (v103.Character);
            v104 = shared.cachedTeamModels[v73];
            if (v104 and v104.Parent ~= nil) then
                local NameTag_1 = v100:FindFirstChild("NameTag");
                v102 = v100:FindFirstChild("TeamHighlight");
                if (v102) then
                    local v105 = v103 and (v103.Team);
                    local v106 = v105 and (v105.TeamColor.Color);
                    if (v106) then
                        v102.FillColor = v106;
                        v102.OutlineColor = v106;
                    end;
                    if (NameTag_1 and NameTag_1:FindFirstChild("Label")) then
                        NameTag_1.MaxDistance = tbl_4.MaxDistance.Team;
                        NameTag_1.AlwaysOnTop = true;
                        NameTag_1.Label.TextColor3 = v105 or (tbl_4.TextColor3.Team);
                        local v107, v108;
                        if (not (checkRay)) then
                            continue;
                        end;
                        v2 = tick();
                        v107 = v1:FindFirstChild("Head");
                        v108 = v103:FindFirstChild("Head");
                        if (not (v107)) then
                            continue;
                        end;
                        local v109 = nil;
                        if (v108) then
                            v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                            v102.FillTransparency = (v109 and 0.5) or 1;
                            v102.OutlineTransparency = (v109 and 0) or 0.5;
                            v102.Enabled = true;
                        end;
                    else
                        local v107, v108;
                        if (not (checkRay)) then
                            continue;
                        end;
                        v2 = tick();
                        v107 = v1:FindFirstChild("Head");
                        v108 = v103:FindFirstChild("Head");
                        if (not (v107)) then
                            continue;
                        end;
                        local v109 = nil;
                        if (v108) then
                            v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                            v102.FillTransparency = (v109 and 0.5) or 1;
                            v102.OutlineTransparency = (v109 and 0) or 0.5;
                            v102.Enabled = true;
                        end;
                    end;
                else
                    v102 = TeamHighlight_1:Clone();
                    v102.Parent = v100;
                    local v105 = v103 and (v103.Team);
                    local v106 = v105 and (v105.TeamColor.Color);
                    if (v106) then
                        v102.FillColor = v106;
                        v102.OutlineColor = v106;
                    end;
                    if (NameTag_1 and NameTag_1:FindFirstChild("Label")) then
                        NameTag_1.MaxDistance = tbl_4.MaxDistance.Team;
                        NameTag_1.AlwaysOnTop = true;
                        NameTag_1.Label.TextColor3 = v105 or (tbl_4.TextColor3.Team);
                        local v107, v108;
                        if (not (checkRay)) then
                            continue;
                        end;
                        v2 = tick();
                        v107 = v1:FindFirstChild("Head");
                        v108 = v103:FindFirstChild("Head");
                        if (not (v107)) then
                            continue;
                        end;
                        local v109 = nil;
                        if (v108) then
                            v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                            v102.FillTransparency = (v109 and 0.5) or 1;
                            v102.OutlineTransparency = (v109 and 0) or 0.5;
                            v102.Enabled = true;
                        end;
                    else
                        local v107, v108;
                        if (not (checkRay)) then
                            continue;
                        end;
                        v2 = tick();
                        v107 = v1:FindFirstChild("Head");
                        v108 = v103:FindFirstChild("Head");
                        if (not (v107)) then
                            continue;
                        end;
                        local v109 = nil;
                        if (v108) then
                            v109 = RaycastUtil_1:Raycast(v107.Position, v108.Position - v107.Position, "Blacklist", {v1, v103, workspace.VFX, workspace.Animals, workspace.Drops, workspace.Plants}, false, v6, true);
                            v102.FillTransparency = (v109 and 0.5) or 1;
                            v102.OutlineTransparency = (v109 and 0) or 0.5;
                            v102.Enabled = true;
                        end;
                    end;
                end;
            else
                if (not (v103) or not (v103) or not (v103) or not (v103)) then
                    continue;
                end;
                shared.cachedTeamModels[v73] = v103;
                local NameTag_1 = v100:FindFirstChild("NameTag");
                v102 = v100:FindFirstChild("TeamHighlight");
                if (v102) then
                    local v105 = v103 and (v103.Team);
                    local v106 = v105 and (v105.TeamColor.Color);
                    if (v106) then
                        v102.FillColor = v106;
                        v102.OutlineColor = v106;
                    end;
                else
                    v102 = TeamHighlight_1:Clone();
                    v102.Parent = v100;
                    local v105 = v103 and (v103.Team);
                    local v106 = v105 and (v105.TeamColor.Color);
                    if (v106) then
                        v102.FillColor = v106;
                        v102.OutlineColor = v106;
                    end;
                end;
            end;
        end;
        if (tick() - v4 < 1) then
            return;
        end;
        v4 = tick();
        for key_10, v73 in pairs(shared.cachedTeamModels) do
            if (v73.Parent == nil) then
                shared.cachedTeamModels[key_10] = nil;
                continue;
            end;
            for _, value_19 in pairs(v5) do
                if (key_10 == tonumber(value_19)) then
                    break;
                end;
            end;
            if (false) then
                continue;
            end;
            shared.cachedTeamModels[key_10] = nil;
            v100 = v73:FindFirstChild("NameTag");
            if (v100) then
                v100.MaxDistance = tbl_4.MaxDistance.Default;
                v100.AlwaysOnTop = false;
            end;
            if (v100 and v100:FindFirstChild("Label")) then
                v100.Label.TextColor3 = tbl_4.TextColor3.Default;
                local TeamHighlight_2 = v73:FindFirstChild("TeamHighlight");
                if (TeamHighlight_2) then
                    TeamHighlight_2:Destroy();
                end;
            else
                local TeamHighlight_2 = v73:FindFirstChild("TeamHighlight");
                if (TeamHighlight_2) then
                    TeamHighlight_2:Destroy();
                end;
            end;
        end;
    end;
end;