-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_upv_1 = game:GetService("ReplicatedStorage");
local Players_upv_1 = game:GetService("Players");
local RunService_1 = game:GetService("RunService");
local Values_1 = ReplicatedStorage_upv_1:WaitForChild("Values");
local NumberUtil_upv_1 = require(ReplicatedStorage_upv_1:WaitForChild("Modules"):WaitForChild("NumberUtil"));
local LoadingScreen_1 = ReplicatedStorage_upv_1:WaitForChild("LoadingScreen");
local Ping_upv_1 = ReplicatedStorage_upv_1:WaitForChild("Ping");
local LocalPlayer_upv_1 = Players_upv_1.LocalPlayer;
local PlayerGui_upv_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui");
local u1 = os.clock();
local u2 = 0;
local u3 = false;
local LoadingScreen_upv_2 = script:WaitForChild("LoadingScreen");
LoadingScreen_upv_2.Parent = PlayerGui_upv_1;
LoadingScreen_upv_2.Enabled = Values_1.Loading.Value;
local Load_upv_1 = LoadingScreen_upv_2:WaitForChild("Load");
LoadingScreen_1.OnClientEvent:Connect(
    function(a1, ...)
        --[[
          line: 41
          upvalues:
            Load_upv_1 (copy, index: 1)
            LoadingScreen_upv_2 (copy, index: 2)
            PlayerGui_upv_1 (copy, index: 3)
            Players_upv_1 (copy, index: 4)
            LocalPlayer_upv_1 (copy, index: 5)
            ReplicatedStorage_upv_1 (copy, index: 6)
            NumberUtil_upv_1 (copy, index: 7)
        ]]
        local tbl_1 = {...};
        if (a1 == "Update") then
            Load_upv_1.Text = "Loading " .. tbl_1[1] .. " (" .. tbl_1[2] .. "/" .. tbl_1[3] .. ")";
        elseif (a1 ~= "Toggle") then
            local v1 = nil;
            if (a1 ~= "Invalid") then
                local v2 = nil;
                if (a1 == "SetExtraText") then
                    v2 = PlayerGui_upv_1:FindFirstChild("Main");
                    if (not v2) then
                        return;
                    end;
                    v1 = v2:FindFirstChild("ClientInfo");
                    if (not v1) then
                        return;
                    end;
                    v1.Extra.Text = tbl_1[1] or "";
                elseif (a1 == "GunGameStats") then
                    v2 = PlayerGui_upv_1:FindFirstChild("Main");
                    if (not v2) then
                        return;
                    end;
                    v1 = v2:FindFirstChild("GUNGAME");
                    if (v1) then
                        local v3 = tbl_1[1] == true;
                        v1.Visible = v3;
                    end;
                    if (v1 and v3) then
                        local v4 = Players_upv_1:GetPlayers();
                        table.sort(
                            v4,
                            function(a2, a3)
                                --[[
                                  line: 71
                                ]]
                                local v5 = a2:GetAttribute("Points") or 0;
                                local v6 = (a3:GetAttribute("Points") or 0) < v5;
                                return v6;
                            end
                        );
                        local v7 = (v4[1] == LocalPlayer_upv_1) and true;
                        if (v4[2] == LocalPlayer_upv_1) then
                            v7 = true;
                        end;
                        if (v4[3] == LocalPlayer_upv_1) then
                            v7 = true;
                        end;
                        if (v4[4] == LocalPlayer_upv_1) then
                            v7 = true;
                        end;
                        if (v4[5] == LocalPlayer_upv_1) then
                            v7 = true;
                        end;
                        if (not (v7)) then
                            v4[math.min(#v4 + 1, 5)] = LocalPlayer_upv_1;
                        end;
                        for n_1 = 1, 5 do
                            local v8 = v1["Label" .. n_1];
                            local v9;
                            v9 = v4[n_1];
                            if (v9) then
                                v8.Text = ("%* - %*"):format(v9.DisplayName, v9:GetAttribute("Points") or 0);
                                v8.TextColor3 = v9 == LocalPlayer_upv_1 and Color3.fromRGB(0, 80, 255) or Color3.new(1, 1, 1);
                                v8.Visible = true;
                            else
                                v8.Visible = false;
                            end;
                        end;
                    end;
                elseif (a1 == "UpdateSign") then
                    ReplicatedStorage_upv_1:SetAttribute("LabelsOwned", tbl_1[1]);
                elseif (a1 == "CombatLog") then
                    v2 = tbl_1[1];
                    if (v2) then
                        warn("COMBAT LOG:");
                        local v11, v12, v13 = nil, nil, nil;
                        local v14 = nil;
                        local v15 = nil;
                        local v16 = nil;
                        local v17 = nil;
                        local v18 = nil;
                        local v19 = nil;
                        local v20 = nil;
                        local v21 = nil;
                        local v22 = nil;
                        local v23 = nil;
                        local v24 = nil;
                        local v25 = nil;
                        local v26 = nil;
                        local v27 = nil;
                        local v28 = nil;
                        local v29 = nil;
                        local v30 = nil;
                        local v31 = nil;
                        local Hour_1 = nil;
                        local Minute_1 = nil;
                        local Second_1 = nil;
                        local Millisecond_1 = nil;
                        local v32 = nil;
                        local v33 = nil;
                        local v34 = nil;
                        local v35 = nil;
                        local v36 = nil;
                        for _, value_1 in v2 do
                            v14 = value_1[1];
                            v35 = value_1[2];
                            v36 = value_1[3];
                            v15 = value_1[4];
                            v16 = value_1[5];
                            v17 = value_1[6];
                            v18 = value_1[7];
                            v19 = value_1[8];
                            v20 = value_1[9];
                            v21 = value_1[10];
                            v22 = value_1[11];
                            v23 = value_1[12];
                            v24 = value_1[13];
                            v25 = "%*(@%*):%*";
                            if (v35 ~= v36) then
                                v26 = v35;
                            else
                                v26 = "";
                            end;
                            v27 = v25:format(v26, v36, v15);
                            v28 = DateTime.fromUnixTimestampMillis(v16):ToLocalTime();
                            v26 = ((v22 == 0) and " DOWNED") or (((v22 ~= 1) and "") or " KILLED");
                            if (v19) then
                                v11 = NumberUtil_upv_1:RoundNumber(v19, 3, true);
                            else
                                v11 = nil;
                            end;
                            if (v21) then
                                v13 = NumberUtil_upv_1:RoundNumber(v21, 1, true);
                            else
                                v13 = nil;
                            end;
                            if (v20) then
                                v12 = NumberUtil_upv_1:RoundNumber(v20, 1, true);
                            else
                                v12 = not (v21) or not (v23) or v13;
                            end;
                            v29 = ("%*%*"):format(v17, ((v24 ~= 0) and "") or " (Thrown)");
                            if (v23) then
                                local v37 = type(v23) == "string" and ": " .. v23:upper() or "";
                                v30 = ("[INVALID%*] "):format(v37);
                            else
                                v30 = "";
                            end;
                            v31 = "[LOG] [%*:%*:%*:%*] %*%* HIT %* USING %* (LIMB: %*) (DISTANCE: %*) (OLD HEALTH: %*) (NEW HEALTH: %*%*)";
                            Hour_1 = v28.Hour;
                            Minute_1 = v28.Minute;
                            Second_1 = v28.Second;
                            Millisecond_1 = v28.Millisecond;
                            if (v14) then
                                v32 = v27;
                            else
                                v32 = "YOU";
                            end;
                            if (v14) then
                                v33 = "YOU";
                            else
                                v33 = v27;
                            end;
                            v34 = v31:format(Hour_1, Minute_1, Second_1, Millisecond_1, v30, v32, v33, v29, v18, v11, v12, v13, v26);
                            if (v23) then
                                warn(v34);
                            else
                                print(v34);
                            end;
                        end;
                    end;
                end;
            else
                local v38 = tbl_1[1];
                warn("INVALID:", v38);
                v1 = PlayerGui_upv_1:FindFirstChild("Main");
                if (not v1) then
                    return;
                end;
                v1.Invalids.Text = v38;
                task.wait(4);
                if (v1 and v1.Parent and v1.Invalids.Text == v38) then
                    v1.Invalids.Text = "";
                    return;
                end;
            end;
        else
            LoadingScreen_upv_2.Enabled = tbl_1[1] == true;
        end;
    end
);
RunService_1.Heartbeat:Connect(
    function()
        --[[
          line: 152
          upvalues:
            u2 (ref,  index: 1)
            u1 (ref,  index: 2)
            PlayerGui_upv_1 (copy, index: 3)
            NumberUtil_upv_1 (copy, index: 4)
            LocalPlayer_upv_1 (copy, index: 5)
            u3 (ref,  index: 6)
            Ping_upv_1 (copy, index: 7)
        ]]
        u2 = u2 + 1;
        local v39 = nil;
        if (os.clock() - u1 >= 1) then
            v39 = PlayerGui_upv_1:FindFirstChild("Main");
            local v40 = nil;
            if (v39) then
                v40 = v39.ClientInfo;
                local v41 = NumberUtil_upv_1:RoundNumber(u2 / (os.clock() - u1), 2);
                u2 = 0;
                v40.FPS.Text = "FPS: " .. v41;
                u1 = os.clock();
                if (v40 and v40.Parent) then
                    local v42 = nil;
                    if (v40:FindFirstChild("Ping")) then
                        v40.Ping.Text = "Ping: " .. math.floor(LocalPlayer_upv_1:GetNetworkPing() * 1000) .. "ms";
                        v42 = v40:FindFirstChild("ServerLoad");
                        if (v42) then
                            if (u3) then
                                v42.Text = "Server CPU Load: " .. Ping_upv_1:InvokeServer() .. "%";
                                return;
                            end;
                            v42.Text = "";
                        end;
                    end;
                end;
            end;
        end;
    end
);
PlayerGui_upv_1.ChildAdded:Connect(
    function(a1)
        --[[
          line: 184
          upvalues:
            u3 (ref, index: 1)
        ]]
        if (a1.Name ~= "AdminMenu") then
            return;
        end;
        u3 = true;
    end
);
u3 = PlayerGui_upv_1:FindFirstChild("AdminMenu") ~= nil;