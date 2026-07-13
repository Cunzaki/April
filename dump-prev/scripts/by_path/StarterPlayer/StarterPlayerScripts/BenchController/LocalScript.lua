-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Players_1 = game:GetService("Players");
local PolicyService_upv_1 = game:GetService("PolicyService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local _ = ReplicatedStorage_1:WaitForChild("Values");
local Loners_1 = workspace:WaitForChild("Bases"):WaitForChild("Loners");
local Signs_upv_1 = ReplicatedStorage_1:WaitForChild("Signs");
local ClientSignals_1 = ReplicatedStorage_1:WaitForChild("ClientSignals");
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local v15 = LocalPlayer_upv_1:WaitForChild("PlayerScripts");
local PlayerGui_upv_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui");
local v1 = require(Modules_1:WaitForChild("AssetContainer"))();
local ActiveBenchModule_upv_1 = require(Modules_1:WaitForChild("ActiveBenchModule"));
shared.Beds = {};
v1(
    "Setup",
    "\156\002I=\144i\181\249\200\249\198Q\020\205\1431\142\001\1391",
    "s \181\192\027xL\001\209\202\224\220\179\019XW;\019\221k",
    function(a1)
        --[[
          line: 45
          upvalues:
            ActiveBenchModule_upv_1 (copy, index: 1)
        ]]
        ActiveBenchModule_upv_1.SetServClientInfos(a1);
    end
);
v1(
    "Setup",
    "\156\002I=\144i\181\249\200\249\198Q\020\205\1431\142\001\1391",
    "n\202\166F\026\222[7\255\183L\138r\248_I\137\160\210\001",
    function(a1)
        --[[
          line: 49
        ]]
        if (type(a1) ~= "table") then
            return;
        end;
        shared.Beds = a1;
    end
);
local function v2(a1)
    --[[
      line: 62
      upvalues:
        PlayerGui_upv_1 (copy, index: 1)
        Signs_upv_1 (copy, index: 2)
    ]]
    if (a1:IsA("SurfaceGui")) then
        local u1;
        if (not a1.Parent) then
            return;
        end;
        u1 = a1:WaitForChild("Toggle", 1);
        if (u1 and a1.Parent) then
            task.defer(
                function()
                    --[[
                      line: 66
                      upvalues:
                        a1 (copy, index: 1)
                        PlayerGui_upv_1 (copy, index: 2)
                        u1 (copy, index: 3)
                    ]]
                    if (not a1.Parent) then
                        return;
                    end;
                    a1.Parent = PlayerGui_upv_1;
                    u1.Activated:Connect(
                        function()
                            --[[
                              line: 70
                              upvalues:
                                a1 (copy, index: 1)
                            ]]
                            local v3 = not a1.Hidden.Visible;
                            local Toggle_1 = a1.Toggle;
                            a1.Hidden.Visible = v3;
                            Toggle_1.BackgroundColor3 = v3 and Color3.fromRGB(255, 30, 0) or Color3.fromRGB(60, 255, 0);
                            Toggle_1.Text = (v3 and "SHOW") or "HIDE";
                        end
                    );
                end
            );
            local v5 = nil;
            if (Signs_upv_1:GetAttribute("ToggleSigns")) then
                local Toggle_2 = a1.Toggle;
                a1.Hidden.Visible = true;
                v5 = Color3.fromRGB(255, 30, 0) or Color3.fromRGB(60, 255, 0);
                Toggle_2.BackgroundColor3 = v5;
                Toggle_2.Text = "SHOW";
            end;
            return;
        end;
    end;
end;
Signs_upv_1.ChildAdded:Connect(v2);
for v6, value_1 in pairs(Signs_upv_1:GetChildren()) do
    v2(value_1);
    if (v6 % 100 == 0) then
        task.wait();
    end;
end;
Signs_upv_1:GetAttributeChangedSignal("ToggleSigns"):Connect(
    function()
        --[[
          line: 85
          upvalues:
            Signs_upv_1 (copy, index: 1)
            PlayerGui_upv_1 (copy, index: 2)
        ]]
        local v7 = Signs_upv_1:GetAttribute("ToggleSigns");
        if (v7 ~= nil) then
            local v8 = 0;
            local v9 = nil;
            local v10 = nil;
            local _ = nil;
            for v11, value_2 in pairs(PlayerGui_upv_1:GetChildren()) do
                if (not (value_2.Parent)) then
                    continue;
                end;
                v9 = value_2:IsA("SurfaceGui");
                if (not (v9)) then
                    continue;
                end;
                v9 = value_2.Toggle;
                value_2.Hidden.Visible = v7;
                v10 = (v7 and (Color3.fromRGB(255, 30, 0))) or (Color3.fromRGB(60, 255, 0));
                v9.BackgroundColor3 = v10;
                v9.Text = (v7 and "SHOW") or "HIDE";
                v8 = v8 + 1;
                if (v8 % 100 == 0) then
                    task.wait();
                end;
            end;
            print("successfully updated", v8, "signs");
        end;
    end
);
ClientSignals_1:WaitForChild("BenchCleanup").OnClientEvent:Connect(
    function(a1)
        --[[
          line: 99
          upvalues:
            ActiveBenchModule_upv_1 (copy, index: 1)
        ]]
        local v11 = os.clock();
        local v12 = 0;
        local tbl_1 = {};
        for _, value_3 in a1 do
            v12 = v12 + 1;
            if (v12 % 100 == 0) then
                task.wait();
            end;
            tbl_1[("%*-%*-%*-%*-%*"):format(value_3:sub(1, 8), value_3:sub(9, 12), value_3:sub(13, 16), value_3:sub(17, 20), value_3:sub(21))] = true;
        end;
        for key_1, _ in ActiveBenchModule_upv_1.GetAllRawClientInfos() do
            v12 = v12 + 1;
            if (v12 % 100 == 0) then
                task.wait();
            end;
            if (not (tbl_1[key_1])) then
                ActiveBenchModule_upv_1.RemoveClientInfo(key_1);
            end;
        end;
        print("cleaned up old active benches in", os.clock() - v11);
    end
);
while (true) do
    local v13, v14;
    v13, v14 = pcall(
        function()
            --[[
              line: 121
              upvalues:
                PolicyService_upv_1 (copy, index: 1)
                LocalPlayer_upv_1 (copy, index: 2)
            ]]
            return PolicyService_upv_1:GetPolicyInfoForPlayerAsync(LocalPlayer_upv_1);
        end
    );
    if (v13) then
        break;
    end;
    warn("Error fetching from PolicyService - ", v14);
    task.wait(3);
end;
local v6 = nil;
if (v14.ArePaidRandomItemsRestricted) then
    local function u2(a1)
        --[[
          line: 126
        ]]
        a1.ChildAdded:Connect(
            function(a2)
                --[[
                  line: 127
                ]]
                task.wait();
                if (not a2.Parent) then
                    return;
                end;
                a2.PrimaryPart = nil;
            end
        );
        for _, value_4 in pairs(a1:GetChildren()) do
            value_4.PrimaryPart = nil;
        end;
    end;
    Loners_1.ChildAdded:Connect(
        function(a1)
            --[[
              line: 137
              upvalues:
                u2 (copy, index: 1)
            ]]
            if (a1.Name ~= "Plinko Machine") then
                return;
            end;
            u2(a1);
        end
    );
    v6 = Loners_1:FindFirstChild("Plinko Machine");
    if (not v6) then
        return;
    end;
    u2(v6);
end;