-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local Values = ReplicatedStorage:WaitForChild("Values");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local LoadingScreen = ReplicatedStorage:WaitForChild("LoadingScreen");
local Ping = ReplicatedStorage:WaitForChild("Ping");
local LocalPlayer = Players.LocalPlayer;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local u1 = os.clock();
local u2 = 0;
local u3 = false;
local LoadingScreen2 = script:WaitForChild("LoadingScreen");
LoadingScreen2.Parent = PlayerGui;
LoadingScreen2.Enabled = Values.Loading.Value;
local Load = LoadingScreen2:WaitForChild("Load");
LoadingScreen.OnClientEvent:Connect(function(p4, ...) -- Line: 41
    -- upvalues: Load (copy), LoadingScreen2 (copy), PlayerGui (copy), Players (copy), LocalPlayer (copy), ReplicatedStorage (copy), NumberUtil (copy)
    local v5 = { ... };

    if p4 == "Update" then
        Load.Text = "Loading " .. v5[1] .. " (" .. v5[2] .. "/" .. v5[3] .. ")";

        return;
    end;

    if p4 == "Toggle" then
        LoadingScreen2.Enabled = v5[1] == true;

        return;
    end;

    if p4 == "Invalid" then
        local v6 = v5[1];
        warn("INVALID:", v6);
        local Main = PlayerGui:FindFirstChild("Main");

        if not Main then
            return;
        end;

        Main.Invalids.Text = v6;
        task.wait(4);

        if not Main or (not Main.Parent or Main.Invalids.Text ~= v6) then
            return;
        end;

        Main.Invalids.Text = "";

        return;
    end;

    if p4 == "SetExtraText" then
        local Main = PlayerGui:FindFirstChild("Main");

        if not Main then
            return;
        end;

        local ClientInfo = Main:FindFirstChild("ClientInfo");

        if not ClientInfo then
            return;
        end;

        ClientInfo.Extra.Text = v5[1] or "";

        return;
    end;

    if p4 ~= "GunGameStats" then
        if p4 == "UpdateSign" then
            ReplicatedStorage:SetAttribute("LabelsOwned", v5[1]);

            return;
        end;

        if p4 == "CombatLog" then
            local v7 = v5[1];

            if not v7 then
                return;
            end;

            warn("COMBAT LOG:");

            for _, v in v7 do
                local v8 = v[1];
                local v9 = v[2];
                local v10 = v[3];
                local v11 = v[5];
                local v12 = v[6];
                local v13 = v[7];
                local v14 = v[8];
                local v15 = v[9];
                local v16 = v[10];
                local v17 = v[11];
                local v18 = v[12];
                local v19 = v[13];
                local v20 = `{v9 == v10 and "" or v9}(@{v10}):{v[4]}`;
                local v21 = DateTime.fromUnixTimestampMillis(v11):ToLocalTime();
                local v22;

                if v14 then
                    v22 = NumberUtil:RoundNumber(v14, 3, true);
                else
                    v22 = nil;
                end;

                local v23;

                if v16 then
                    v23 = NumberUtil:RoundNumber(v16, 1, true);
                else
                    v23 = nil;
                end;

                local v24;

                if v15 then
                    v24 = NumberUtil:RoundNumber(v15, 1, true);
                elseif v16 and v18 then
                    v24 = v23;
                else
                    v24 = nil;
                end;

                local v25 = `{v12}{v19 == 0 and " (Thrown)" or ""}`;
                local v26 = not v18 and "" or `[INVALID{type(v18) ~= "string" and "" or ": " .. v18:upper()}] `;
                local v27 = `[LOG] [{v21.Hour}:{v21.Minute}:{v21.Second}:{v21.Millisecond}] {v26}{not v8 and "YOU" or v20} HIT {v8 and "YOU" or v20} USING {v25} (LIMB: {v13}) (DISTANCE: {v22}) (OLD HEALTH: {v24}) (NEW HEALTH: {v23}{v17 == 0 and " DOWNED" or (v17 == 1 and " KILLED" or "")})`;

                if v18 then
                    warn(v27);
                else
                    print(v27);
                end;
            end;
        end;

        return;
    end;

    local Main = PlayerGui:FindFirstChild("Main");

    if not Main then
        return;
    end;

    local GUNGAME = Main:FindFirstChild("GUNGAME");

    if not GUNGAME then
        return;
    end;

    local v28 = v5[1] == true;
    GUNGAME.Visible = v28;

    if not v28 then
        return;
    end;

    local v29 = Players:GetPlayers();
    table.sort(v29, function(p30, p31) -- Line: 71
        return (p30:GetAttribute("Points") or 0) > (p31:GetAttribute("Points") or 0);
    end);

    if v29[5] ~= LocalPlayer and (v29[4] ~= LocalPlayer and (v29[3] ~= LocalPlayer and (v29[2] ~= LocalPlayer and v29[1] ~= LocalPlayer))) then
        v29[math.min(#v29 + 1, 5)] = LocalPlayer;
    end;

    for i = 1, 5 do
        local v32 = GUNGAME["Label" .. i];
        local v33 = v29[i];

        if v33 then
            local v34 = v33:GetAttribute("Points") or 0;
            v32.Text = `{v33.DisplayName} - {v34}`;
            v32.TextColor3 = v33 == LocalPlayer and Color3.fromRGB(0, 80, 255) or Color3.new(1, 1, 1);
            v32.Visible = true;
        else
            v32.Visible = false;
        end;
    end;
end);
RunService.Heartbeat:Connect(function() -- Line: 152
    -- upvalues: u2 (ref), u1 (ref), PlayerGui (copy), NumberUtil (copy), LocalPlayer (copy), u3 (ref), Ping (copy)
    u2 = u2 + 1;

    if os.clock() - u1 < 1 then
        return;
    end;

    local Main = PlayerGui:FindFirstChild("Main");

    if not Main then
        return;
    end;

    local ClientInfo = Main.ClientInfo;
    local v35 = NumberUtil:RoundNumber(u2 / (os.clock() - u1), 2);
    u2 = 0;
    ClientInfo.FPS.Text = "FPS: " .. v35;
    u1 = os.clock();

    if ClientInfo and (ClientInfo.Parent and ClientInfo:FindFirstChild("Ping")) then
        local Ping2 = ClientInfo.Ping;
        local v36 = LocalPlayer:GetNetworkPing() * 1000;
        Ping2.Text = "Ping: " .. math.floor(v36) .. "ms";
        local ServerLoad = ClientInfo:FindFirstChild("ServerLoad");

        if ServerLoad then
            if u3 then
                ServerLoad.Text = "Server CPU Load: " .. Ping:InvokeServer() .. "%";

                return;
            end;

            ServerLoad.Text = "";
        end;
    end;
end);
PlayerGui.ChildAdded:Connect(function(p37) -- Line: 184
    -- upvalues: u3 (ref)
    if p37.Name ~= "AdminMenu" then
        return;
    end;

    u3 = true;
end);

if PlayerGui:FindFirstChild("AdminMenu") == nil then
    u3 = false;
else
    u3 = true;
end;