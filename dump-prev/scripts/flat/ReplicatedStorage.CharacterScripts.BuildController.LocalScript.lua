-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local RunService_upv_1 = game:GetService("RunService");
local Players_1 = game:GetService("Players");
local UserInputService_upv_1 = game:GetService("UserInputService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Benches_upv_1 = ReplicatedStorage_1:WaitForChild("Benches");
local Values_upv_1 = ReplicatedStorage_1:WaitForChild("Values");
local Bases_upv_1 = workspace:WaitForChild("Bases");
local VFX_upv_1 = workspace:WaitForChild("VFX");
local Benches_upv_2 = VFX_upv_1:WaitForChild("Benches");
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local Parent_upv_1 = script.Parent;
local Humanoid_upv_1 = Parent_upv_1:WaitForChild("Humanoid");
local CurrentCamera_upv_1 = workspace.CurrentCamera;
local InventoryController_upv_1 = Parent_upv_1:WaitForChild("InventoryController");
local WheelController_upv_1 = Parent_upv_1:WaitForChild("WheelController");
local CameraController_upv_1 = Parent_upv_1:WaitForChild("CameraController");
local InteractController_upv_1 = Parent_upv_1:WaitForChild("InteractController");
local EquipController_upv_1 = Parent_upv_1:WaitForChild("EquipController");
local PreferredInputController_upv_1 = LocalPlayer_upv_1:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local RaycastUtil_upv_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local BenchInfo_upv_1 = require(Modules_1:WaitForChild("BenchInfo"));
local RecipeModule_upv_1 = require(Modules_1:WaitForChild("RecipeModule"));
local BasePartInfo_upv_1 = require(Modules_1:WaitForChild("BasePartInfo"));
local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
local AssetContainer_1 = require(Modules_1:WaitForChild("AssetContainer"));
local ActiveBenchModule_upv_1 = require(Modules_1:WaitForChild("ActiveBenchModule"));
local u1 = AssetContainer_1();
local EquipBench_1 = script:WaitForChild("EquipBench");
local Build_1 = ReplicatedStorage_1:WaitForChild("ClientSignals"):WaitForChild("Build");
local tbl_upv_1 = {};
tbl_upv_1.Twig = {"Wood", "Stone", "Metal", "Steel"};
tbl_upv_1.Wood = {"Stone", "Metal", "Steel"};
tbl_upv_1.Stone = {"Metal", "Steel"};
tbl_upv_1.Metal = {"Steel"};
tbl_upv_1.Steel = {};
local u2 = nil;
local u3 = nil;
local u4 = nil;
local u5 = nil;
local u6 = nil;
local u7 = nil;
local u8 = nil;
local u9 = nil;
local u10 = false;
local u11 = 0;
local u12 = CFrame.new();
local u13 = 0;
local Name_upv_1 = "Foundation";
local u14 = nil;
local u15 = nil;
local tbl_upv_2 = {};
local u16 = nil;
local u17 = nil;
local u18 = {};
local u19 = false;
local u20 = true;
local u21 = 0;
local u22 = nil;
local tbl_upv_3 = {};
local u23 = false;
local function u24()
    --[[
      line: 106
      upvalues:
        u10 (ref,  index: 1)
        u2 (ref,  index: 2)
        u8 (ref,  index: 3)
        InventoryController_upv_1 (copy, index: 4)
        u9 (ref,  index: 5)
        u17 (ref,  index: 6)
        u7 (ref,  index: 7)
        u19 (ref,  index: 8)
        u18 (ref,  index: 9)
        u13 (ref,  index: 10)
        u21 (ref,  index: 11)
        u1 (copy, index: 12)
        Name_upv_1 (ref,  index: 13)
    ]]
    if (not u10 or not u2) then
        return;
    end;
    if (u2.Parent) then
        local v1 = nil;
        if (u8) then
            v1 = InventoryController_upv_1.Fetch:Invoke();
            local v2, v3 = nil, nil;
            if (v1) then
                v2 = v1.Toolbar;
                local v4 = nil;
                if (v2) then
                    v4 = v2[script:GetAttribute("Equipped")];
                    local v5 = false;
                    if (v4 == nil) then
                        v3 = v5;
                    else
                        local v6 = false;
                        if (v4 == 0) then
                            v3 = v6;
                        else
                            v3 = v4;
                        end;
                    end;
                else
                    v3 = nil;
                end;
            else
                v3 = nil;
            end;
            if (v3 and v3.ID) then
                if (u9 ~= false) then
                    if (v3.ID == 30) then
                        v2 = u17 or "none";
                    else
                        v2 = u17 or (u7 or "none");
                    end;
                    local v7 = u19;
                    if (u18.Index and u13 % 2 == 1) then
                        v7 = not v7;
                    end;
                    if (v3.ID == 190) then
                        u13 = ((u13 % 3 == 2) and 1) or (((u13 % 3 ~= 1) and (u13 % 3)) or 2);
                    end;
                    if (tick() - u21 >= 0.05) then
                        u21 = tick();
                        u1("Fire", "NM\182\001\154\155j\149\231\163\004\179F\180\232\247\208\a\221\217", "\001\022J?\191\138\fxF.L\183\223x)\198\198\168\188^", v2, u2.PrimaryPart.CFrame, u13, Name_upv_1, u18.Index or 0, v7);
                    end;
                end;
                return;
            end;
        end;
    end;
end;
local tbl_upv_4 = {};
local function u25(a1)
    --[[
      line: 154
      upvalues:
        Humanoid_upv_1 (copy, index: 1)
        Parent_upv_1 (copy, index: 2)
        u16 (ref,  index: 3)
        tbl_upv_2 (ref,  index: 4)
        tbl_upv_4 (copy, index: 5)
        u14 (ref,  index: 6)
        BenchInfo_upv_1 (copy, index: 7)
        Bases_upv_1 (copy, index: 8)
        NumberUtil_upv_1 (copy, index: 9)
    ]]
    if (not Humanoid_upv_1 or not Humanoid_upv_1.Parent or not Parent_upv_1) then
        return;
    end;
    if (Parent_upv_1.Parent) then
        local v8 = nil;
        if (Parent_upv_1.PrimaryPart) then
            local Position_1 = Parent_upv_1.PrimaryPart.Position;
            u16 = Position_1;
            if (not (a1)) then
                tbl_upv_2 = {};
            end;
            v8 = tbl_upv_4[u14];
            local v9 = nil;
            if (v8) then
                local v34 = 0;
                local v10 = 0;
                local v27 = tick();
                local v11 = nil;
                local v28 = nil;
                local v12 = nil;
                local v13 = nil;
                local v14 = nil;
                local v15 = nil;
                local v16 = nil;
                local v17 = nil;
                local v18 = nil;
                for v29, value_1 in pairs(Bases_upv_1:GetChildren()) do
                    if (value_1.Name == "Loners" or not (value_1.Parent)) then
                        continue;
                    end;
                    v11 = value_1:FindFirstChild("Base Cabinet");
                    if (v11) then
                        v11 = v11:FindFirstChild("Base Cabinet");
                        if (v11) then
                            if (NumberUtil_upv_1:IsWithin(v11:GetPivot().Position, Position_1, 750)) then
                                local v19 = nil;
                                for key_1, value_2 in pairs(v8) do
                                    v19 = value_1:FindFirstChild(key_1);
                                    if (v19) then
                                        local v20 = nil;
                                        for v30, value_3 in pairs(v19:GetChildren()) do
                                            if (not (value_3.Parent)) then
                                                continue;
                                            end;
                                            v20 = value_3.PrimaryPart;
                                            if (v20) then
                                                v12 = NumberUtil_upv_1:IsWithin(v20.CFrame.Position, Position_1, 100);
                                                if (v12) then
                                                    for key_2, value_4 in pairs(value_2) do
                                                        v13 = v20:FindFirstChild("Connection" .. key_2);
                                                        if (v13 and v13.Value and v13.Value.Parent) then
                                                            v14 = v10 + 1;
                                                            if (v14 % 120 == 0) then
                                                                task.wait();
                                                            end;
                                                            v10 = v14;
                                                        else
                                                            local v21 = nil;
                                                            local v22 = nil;
                                                            local v23 = nil;
                                                            for v31, value_5 in pairs(value_4) do
                                                                v22 = value_5.Index;
                                                                v23 = value_5.SnapTable;
                                                                v21 = tbl_upv_2[value_3];
                                                                if (not (v21) or not (v21[v22])) then
                                                                    if (not (v21)) then
                                                                        local tbl_5 = {};
                                                                        tbl_upv_2[value_3] = tbl_5;
                                                                        v21 = tbl_5;
                                                                    end;
                                                                    v21[v22] = v20.CFrame * v23.Offset;
                                                                end;
                                                            end;
                                                        end;
                                                    end;
                                                end;
                                                v15 = v9 + 1;
                                                if (v15 % 80 == 0) then
                                                    task.wait();
                                                end;
                                                v9 = v15;
                                            else
                                                v16 = v10 + 1;
                                                if (v16 % 120 == 0) then
                                                    task.wait();
                                                end;
                                                v10 = v16;
                                            end;
                                        end;
                                    else
                                        v17 = v10 + 1;
                                        if (v17 % 120 == 0) then
                                            task.wait();
                                        end;
                                        v10 = v17;
                                    end;
                                end;
                            else
                                v18 = v10 + 1;
                                if (v18 % 120 == 0) then
                                    task.wait();
                                end;
                                v10 = v18;
                            end;
                        else
                            local v19 = nil;
                            for key_1, value_2 in pairs(v8) do
                                v19 = value_1:FindFirstChild(key_1);
                                if (v19) then
                                    local v20 = nil;
                                    for v30, value_3 in pairs(v19:GetChildren()) do
                                        if (not (value_3.Parent)) then
                                            continue;
                                        end;
                                        v20 = value_3.PrimaryPart;
                                        if (v20) then
                                            v12 = NumberUtil_upv_1:IsWithin(v20.CFrame.Position, Position_1, 100);
                                            if (v12) then
                                                for key_2, value_4 in pairs(value_2) do
                                                    v13 = v20:FindFirstChild("Connection" .. key_2);
                                                    if (v13 and v13.Value and v13.Value.Parent) then
                                                        v14 = v10 + 1;
                                                        if (v14 % 120 == 0) then
                                                            task.wait();
                                                        end;
                                                        v10 = v14;
                                                    else
                                                        local v21 = nil;
                                                        local v22 = nil;
                                                        local v23 = nil;
                                                        for v31, value_5 in pairs(value_4) do
                                                            v22 = value_5.Index;
                                                            v23 = value_5.SnapTable;
                                                            v21 = tbl_upv_2[value_3];
                                                            if (not (v21) or not (v21[v22])) then
                                                                if (not (v21)) then
                                                                    local tbl_5 = {};
                                                                    tbl_upv_2[value_3] = tbl_5;
                                                                    v21 = tbl_5;
                                                                end;
                                                                v21[v22] = v20.CFrame * v23.Offset;
                                                            end;
                                                        end;
                                                    end;
                                                end;
                                            end;
                                            v15 = v9 + 1;
                                            if (v15 % 80 == 0) then
                                                task.wait();
                                            end;
                                            v9 = v15;
                                        else
                                            v16 = v10 + 1;
                                            if (v16 % 120 == 0) then
                                                task.wait();
                                            end;
                                            v10 = v16;
                                        end;
                                    end;
                                else
                                    v17 = v10 + 1;
                                    if (v17 % 120 == 0) then
                                        task.wait();
                                    end;
                                    v10 = v17;
                                end;
                            end;
                        end;
                    else
                        local v19 = nil;
                        for key_1, value_2 in pairs(v8) do
                            v19 = value_1:FindFirstChild(key_1);
                            if (v19) then
                                local v20 = nil;
                                for v30, value_3 in pairs(v19:GetChildren()) do
                                    if (not (value_3.Parent)) then
                                        continue;
                                    end;
                                    v20 = value_3.PrimaryPart;
                                    if (v20) then
                                        v12 = NumberUtil_upv_1:IsWithin(v20.CFrame.Position, Position_1, 100);
                                        if (v12) then
                                            for key_2, value_4 in pairs(value_2) do
                                                v13 = v20:FindFirstChild("Connection" .. key_2);
                                                if (v13 and v13.Value and v13.Value.Parent) then
                                                    v14 = v10 + 1;
                                                    if (v14 % 120 == 0) then
                                                        task.wait();
                                                    end;
                                                    v10 = v14;
                                                else
                                                    local v21 = nil;
                                                    local v22 = nil;
                                                    local v23 = nil;
                                                    for v31, value_5 in pairs(value_4) do
                                                        v22 = value_5.Index;
                                                        v23 = value_5.SnapTable;
                                                        v21 = tbl_upv_2[value_3];
                                                        if (not (v21) or not (v21[v22])) then
                                                            if (not (v21)) then
                                                                local tbl_5 = {};
                                                                tbl_upv_2[value_3] = tbl_5;
                                                                v21 = tbl_5;
                                                            end;
                                                            v21[v22] = v20.CFrame * v23.Offset;
                                                        end;
                                                    end;
                                                end;
                                            end;
                                        end;
                                        v15 = v9 + 1;
                                        if (v15 % 80 == 0) then
                                            task.wait();
                                        end;
                                        v9 = v15;
                                    else
                                        v16 = v10 + 1;
                                        if (v16 % 120 == 0) then
                                            task.wait();
                                        end;
                                        v10 = v16;
                                    end;
                                end;
                            else
                                v17 = v10 + 1;
                                if (v17 % 120 == 0) then
                                    task.wait();
                                end;
                                v10 = v17;
                            end;
                        end;
                    end;
                end;
            else
                v9 = BenchInfo_upv_1[u14];
                local v24 = nil;
                if (v9) then
                    v24 = v9.SnapPoints;
                end;
                if (v9 and v24) then
                    v8 = {};
                    local v25 = nil;
                    local _ = nil;
                    local v32 = nil;
                    local key_3 = nil;
                    local value_6 = nil;
                    local v26 = nil;
                    local v19 = nil;
                    for key_3, value_6 in pairs(v24) do
                        if (value_6.Unsnappable) then
                            continue;
                        end;
                        v25 = value_6.AttachmentIndex;
                        for v33, value_7 in pairs(value_6.BenchNames) do
                            v26 = v8[value_7];
                            if (not (v26)) then
                                v26 = {};
                                v8[value_7] = v26;
                            end;
                            v19 = v26[v25];
                            if (not (v19)) then
                                v19 = {};
                                v26[v25] = v19;
                            end;
                            table.insert(v19, {Index = key_3, SnapTable = value_6});
                        end;
                    end;
                    tbl_upv_4[u14] = v8;
                    local v34 = 0;
                    local v10 = 0;
                    local v27 = tick();
                    local v11 = nil;
                    local v28 = nil;
                    local v12 = nil;
                    local v13 = nil;
                    local v14 = nil;
                    local v15 = nil;
                    local v16 = nil;
                    local v17 = nil;
                    local v18 = nil;
                    for v29, value_1 in pairs(Bases_upv_1:GetChildren()) do
                        if (value_1.Name == "Loners" or not (value_1.Parent)) then
                            continue;
                        end;
                        v11 = value_1:FindFirstChild("Base Cabinet");
                        if (v11) then
                            v11 = v11:FindFirstChild("Base Cabinet");
                            if (v11) then
                                if (NumberUtil_upv_1:IsWithin(v11:GetPivot().Position, Position_1, 750)) then
                                    local v19 = nil;
                                    for key_1, value_2 in pairs(v8) do
                                        v19 = value_1:FindFirstChild(key_1);
                                        if (v19) then
                                            local v20 = nil;
                                            for v30, value_3 in pairs(v19:GetChildren()) do
                                                if (not (value_3.Parent)) then
                                                    continue;
                                                end;
                                                v20 = value_3.PrimaryPart;
                                                if (v20) then
                                                    v12 = NumberUtil_upv_1:IsWithin(v20.CFrame.Position, Position_1, 100);
                                                    if (v12) then
                                                        for key_2, value_4 in pairs(value_2) do
                                                            v13 = v20:FindFirstChild("Connection" .. key_2);
                                                            if (v13 and v13.Value and v13.Value.Parent) then
                                                                v14 = v10 + 1;
                                                                if (v14 % 120 == 0) then
                                                                    task.wait();
                                                                end;
                                                                v10 = v14;
                                                            else
                                                                local v21 = nil;
                                                                local v22 = nil;
                                                                local v23 = nil;
                                                                for v31, value_5 in pairs(value_4) do
                                                                    v22 = value_5.Index;
                                                                    v23 = value_5.SnapTable;
                                                                    v21 = tbl_upv_2[value_3];
                                                                    if (not (v21) or not (v21[v22])) then
                                                                        if (not (v21)) then
                                                                            local tbl_5 = {};
                                                                            tbl_upv_2[value_3] = tbl_5;
                                                                            v21 = tbl_5;
                                                                        end;
                                                                        v21[v22] = v20.CFrame * v23.Offset;
                                                                    end;
                                                                end;
                                                            end;
                                                        end;
                                                    end;
                                                    v15 = v9 + 1;
                                                    if (v15 % 80 == 0) then
                                                        task.wait();
                                                    end;
                                                    v9 = v15;
                                                else
                                                    v16 = v10 + 1;
                                                    if (v16 % 120 == 0) then
                                                        task.wait();
                                                    end;
                                                    v10 = v16;
                                                end;
                                            end;
                                        else
                                            v17 = v10 + 1;
                                            if (v17 % 120 == 0) then
                                                task.wait();
                                            end;
                                            v10 = v17;
                                        end;
                                    end;
                                else
                                    v18 = v10 + 1;
                                    if (v18 % 120 == 0) then
                                        task.wait();
                                    end;
                                    v10 = v18;
                                end;
                            else
                                local v19 = nil;
                                for key_1, value_2 in pairs(v8) do
                                    v19 = value_1:FindFirstChild(key_1);
                                    if (v19) then
                                        local v20 = nil;
                                        for v30, value_3 in pairs(v19:GetChildren()) do
                                            if (not (value_3.Parent)) then
                                                continue;
                                            end;
                                            v20 = value_3.PrimaryPart;
                                            if (v20) then
                                                v12 = NumberUtil_upv_1:IsWithin(v20.CFrame.Position, Position_1, 100);
                                                if (v12) then
                                                    for key_2, value_4 in pairs(value_2) do
                                                        v13 = v20:FindFirstChild("Connection" .. key_2);
                                                        if (v13 and v13.Value and v13.Value.Parent) then
                                                            v14 = v10 + 1;
                                                            if (v14 % 120 == 0) then
                                                                task.wait();
                                                            end;
                                                            v10 = v14;
                                                        else
                                                            local v21 = nil;
                                                            local v22 = nil;
                                                            local v23 = nil;
                                                            for v31, value_5 in pairs(value_4) do
                                                                v22 = value_5.Index;
                                                                v23 = value_5.SnapTable;
                                                                v21 = tbl_upv_2[value_3];
                                                                if (not (v21) or not (v21[v22])) then
                                                                    if (not (v21)) then
                                                                        local tbl_5 = {};
                                                                        tbl_upv_2[value_3] = tbl_5;
                                                                        v21 = tbl_5;
                                                                    end;
                                                                    v21[v22] = v20.CFrame * v23.Offset;
                                                                end;
                                                            end;
                                                        end;
                                                    end;
                                                end;
                                                v15 = v9 + 1;
                                                if (v15 % 80 == 0) then
                                                    task.wait();
                                                end;
                                                v9 = v15;
                                            else
                                                v16 = v10 + 1;
                                                if (v16 % 120 == 0) then
                                                    task.wait();
                                                end;
                                                v10 = v16;
                                            end;
                                        end;
                                    else
                                        v17 = v10 + 1;
                                        if (v17 % 120 == 0) then
                                            task.wait();
                                        end;
                                        v10 = v17;
                                    end;
                                end;
                            end;
                        else
                            for key_1, value_2 in pairs(v8) do
                                v19 = value_1:FindFirstChild(key_1);
                                if (v19) then
                                    local v20 = nil;
                                    for v30, value_3 in pairs(v19:GetChildren()) do
                                        if (not (value_3.Parent)) then
                                            continue;
                                        end;
                                        v20 = value_3.PrimaryPart;
                                        if (v20) then
                                            v12 = NumberUtil_upv_1:IsWithin(v20.CFrame.Position, Position_1, 100);
                                            if (v12) then
                                                for key_2, value_4 in pairs(value_2) do
                                                    v13 = v20:FindFirstChild("Connection" .. key_2);
                                                    if (v13 and v13.Value and v13.Value.Parent) then
                                                        v14 = v10 + 1;
                                                        if (v14 % 120 == 0) then
                                                            task.wait();
                                                        end;
                                                        v10 = v14;
                                                    else
                                                        local v21 = nil;
                                                        local v22 = nil;
                                                        local v23 = nil;
                                                        for v31, value_5 in pairs(value_4) do
                                                            v22 = value_5.Index;
                                                            v23 = value_5.SnapTable;
                                                            v21 = tbl_upv_2[value_3];
                                                            if (not (v21) or not (v21[v22])) then
                                                                if (not (v21)) then
                                                                    local tbl_5 = {};
                                                                    tbl_upv_2[value_3] = tbl_5;
                                                                    v21 = tbl_5;
                                                                end;
                                                                v21[v22] = v20.CFrame * v23.Offset;
                                                            end;
                                                        end;
                                                    end;
                                                end;
                                            end;
                                            v15 = v9 + 1;
                                            if (v15 % 80 == 0) then
                                                task.wait();
                                            end;
                                            v9 = v15;
                                        else
                                            v16 = v10 + 1;
                                            if (v16 % 120 == 0) then
                                                task.wait();
                                            end;
                                            v10 = v16;
                                        end;
                                    end;
                                else
                                    v17 = v10 + 1;
                                    if (v17 % 120 == 0) then
                                        task.wait();
                                    end;
                                    v10 = v17;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;
local function u26(a1, ...)
    --[[
      line: 287
      upvalues:
        u22 (ref,  index: 1)
        u2 (ref,  index: 2)
        u23 (ref,  index: 3)
        u25 (copy, index: 4)
    ]]
    if (u22) then
        coroutine.close(u22);
        u22 = nil;
    end;
    if (u2 and u2.Parent) then
        u22 = coroutine.create(u25, ...);
        coroutine.resume(u22);
    else
        u23 = true;
    end;
end;
local function u27()
    --[[
      line: 306
      upvalues:
        u8 (ref, index: 1)
        u4 (ref, index: 3)
        u2 (ref, index: 4)
        u3 (ref, index: 5)
    ]]
    u8 = nil;
    u8 = false;
    script:SetAttribute("Equipped", 0);
    if (u4) then
        u4:Disconnect();
        u4 = nil;
    end;
    if (u2 and u2.Parent) then
        u2:Destroy();
        u2 = nil;
    end;
    if (not u3 or not u3.Parent) then
        return;
    end;
    u3:Destroy();
    u3 = nil;
end;
local function u28(a1)
    --[[
      line: 325
      upvalues:
        InventoryController_upv_1 (copy, index: 1)
        Items_upv_1 (copy, index: 2)
        u10 (ref,  index: 3)
        u2 (ref,  index: 4)
        u27 (copy, index: 5)
        Name_upv_1 (ref,  index: 6)
        Benches_upv_1 (copy, index: 7)
        u8 (ref,  index: 8)
        BenchInfo_upv_1 (copy, index: 9)
        u15 (ref,  index: 10)
        u12 (ref,  index: 11)
        u13 (ref,  index: 12)
        u5 (ref,  index: 13)
        u6 (ref,  index: 14)
        u7 (ref,  index: 15)
        u11 (ref,  index: 16)
        u17 (ref,  index: 17)
        u18 (ref,  index: 18)
        Benches_upv_2 (copy, index: 19)
        u3 (ref,  index: 20)
        u14 (ref,  index: 21)
        u23 (ref,  index: 22)
        u26 (copy, index: 23)
        u4 (ref,  index: 24)
        RunService_upv_1 (copy, index: 25)
        Parent_upv_1 (copy, index: 26)
        Humanoid_upv_1 (copy, index: 27)
        CameraController_upv_1 (copy, index: 28)
        CurrentCamera_upv_1 (copy, index: 29)
        RaycastUtil_upv_1 (copy, index: 30)
        VFX_upv_1 (copy, index: 31)
        tbl_upv_2 (ref,  index: 32)
        NumberUtil_upv_1 (copy, index: 33)
        u19 (ref,  index: 34)
        u20 (ref,  index: 35)
        u9 (ref,  index: 36)
        ActiveBenchModule_upv_1 (copy, index: 37)
        u16 (ref,  index: 38)
    ]]
    local v27 = InventoryController_upv_1.Fetch:Invoke();
    local v28, v29 = nil, nil;
    if (v27) then
        v28 = v27.Toolbar;
        local v30 = nil;
        if (v28) then
            local v31 = a1 or (script:GetAttribute("Equipped"));
            v30 = v28[v31];
            v29 = false;
            if (v30 ~= nil) then
                v29 = false;
                if (v30 ~= 0) then
                    v29 = v30;
                end;
            end;
        else
            v29 = nil;
        end;
    else
        v29 = nil;
    end;
    local v32 = v29;
    local v33 = v32 and (Items_upv_1[v29.ID]);
    local v34 = script:GetAttribute("Equipped");
    local v35 = u10;
    if (v34 > 0 and u2 and (v34 ~= a1 or v33 and u2.Name ~= v33.Name)) then
        u27();
    end;
    if (v29) then
        local v36 = v29.ID == 30;
        local u29, u29;
        u29 = v36 and Name_upv_1 or v32.Name;
        local v37 = Benches_upv_1:FindFirstChild(u29);
        u8 = BenchInfo_upv_1[u29];
        if (not u8) then
            return;
        end;
        if (v37) then
            script:SetAttribute("Equipped", a1);
            if (u15 ~= u29 or not (v35)) then
                u12 = CFrame.new();
                u13 = 0;
                u5 = nil;
                u6 = nil;
                u7 = nil;
                u11 = 0;
                u10 = false;
                u17 = nil;
                local _ = {};
            end;
            local v38 = (v36 and v37) or (v37:FindFirstChild(v29.Skin) or (v37:FindFirstChild("Default")));
            local u30 = v38:Clone();
            u30.Name = u29;
            u30.PrimaryPart = u30:FindFirstChild("Main");
            local v39 = nil;
            local v40 = nil;
            local v41 = nil;
            local v42 = nil;
            local v43 = nil;
            local v44 = nil;
            local v45 = nil;
            local _ = nil;
            local v46 = nil;
            for v50, value_8 in pairs(u30:GetDescendants()) do
                if (not (value_8) or not (value_8.Parent)) then
                    continue;
                end;
                v39 = value_8:IsA("BasePart");
                if (v39) then
                    v40 = value_8.Parent:IsA("Model");
                    if (v40) then
                        value_8.Anchored = true;
                        value_8.CanCollide = false;
                        value_8.CastShadow = false;
                        value_8.Color = script:GetAttribute("PlaceUnavailableColor");
                        value_8.Material = Enum.Material.ForceField;
                        v41 = value_8:IsA("MeshPart");
                        if (v41) then
                            value_8.TextureID = "";
                        end;
                    else
                        v42 = value_8:IsA("Highlight");
                        if (v42 or v42 or value_8.Name == "NonBaseCollisionParts") then
                            value_8:Destroy();
                            continue;
                        end;
                        v43 = value_8:IsA("Decal");
                        if (v43) then
                            value_8:Destroy();
                            continue;
                        end;
                        v44 = value_8:IsA("Texture");
                        if (v44) then
                            value_8:Destroy();
                            continue;
                        end;
                        v45 = value_8:IsA("SurfaceAppearance");
                        if (v45 or v45 or value_8.Name == "DetailDeleter") then
                            value_8:Destroy();
                            continue;
                        end;
                        v39 = value_8:IsA("Folder");
                        local v51;
                        if (not (v39)) then
                            continue;
                        end;
                        for v52, value_9 in pairs(value_8:GetChildren()) do
                            v46 = value_9:IsA("BasePart");
                            if (v46) then
                                value_9.Transparency = 1;
                                value_9.CanCollide = false;
                                value_9.Anchored = true;
                            end;
                        end;
                    end;
                else
                    v42 = value_8:IsA("Highlight");
                    if (v42 or v42 or value_8.Name == "NonBaseCollisionParts") then
                        value_8:Destroy();
                        continue;
                    end;
                    v43 = value_8:IsA("Decal");
                    if (v43) then
                        value_8:Destroy();
                        continue;
                    end;
                    v44 = value_8:IsA("Texture");
                    if (v44) then
                        value_8:Destroy();
                        continue;
                    end;
                    v45 = value_8:IsA("SurfaceAppearance");
                    if (v45 or v45 or value_8.Name == "DetailDeleter") then
                        value_8:Destroy();
                        continue;
                    end;
                    v39 = value_8:IsA("Folder");
                    local v51;
                    if (not (v39)) then
                        continue;
                    end;
                    for v52, value_9 in pairs(value_8:GetChildren()) do
                        v46 = value_9:IsA("BasePart");
                        if (v46) then
                            value_9.Transparency = 1;
                            value_9.CanCollide = false;
                            value_9.Anchored = true;
                        end;
                    end;
                end;
            end;
            u30.Parent = Benches_upv_2;
            u2 = u30;
            u3 = v38:Clone();
            u3.Name = u29;
            u3.PrimaryPart = u3:FindFirstChild("Main");
            local v47 = nil;
            local v48 = nil;
            for v53, value_10 in pairs(u3:GetChildren()) do
                if (value_10 ~= u3.PrimaryPart) then
                    if (value_10.Name == "CollisionParts" or value_10.Name == "RayParts" or value_10.Name == "BaseCollisionParts" or value_10.Name == "NonBaseCollisionParts") then
                        for v54, value_11 in pairs(value_10:GetChildren()) do
                            v48 = value_11:IsA("BasePart");
                            if (v48) then
                                value_11.Transparency = 1;
                                value_11.CanCollide = false;
                                value_11.Anchored = true;
                            end;
                        end;
                    elseif (value_10.Name ~= "Pole") then
                        value_10:Destroy();
                        continue;
                    end;
                end;
                v47 = value_10:IsA("BasePart");
                if (v47) then
                    value_10.Transparency = 1;
                    value_10.CanCollide = false;
                end;
            end;
            u3.Parent = Benches_upv_2;
            local SnapPoints_upv_1 = u8.SnapPoints;
            local SnapOnly_upv_1 = u8.SnapOnly;
            local v49 = u14;
            u14 = u29;
            if (u23 or u15 ~= u14 or not (v49)) then
                u26();
            end;
            u15 = u29;
            local OffsetSnappedFacingAway_upv_1 = u8.OffsetSnappedFacingAway;
            local MaxPerBase_upv_1 = u8.MaxPerBase;
            if (u4) then
                u4:Disconnect();
            end;
            u4 = RunService_upv_1.Heartbeat:Connect(
                function(a2)
                    --[[
                      line: 414
                      upvalues:
                        u2 (ref,  index: 1)
                        u30 (copy, index: 2)
                        u3 (ref,  index: 3)
                        Parent_upv_1 (copy, index: 4)
                        Humanoid_upv_1 (copy, index: 5)
                        u27 (copy, index: 6)
                        u11 (ref,  index: 7)
                        CameraController_upv_1 (copy, index: 8)
                        CurrentCamera_upv_1 (copy, index: 9)
                        u8 (ref,  index: 10)
                        RaycastUtil_upv_1 (copy, index: 11)
                        VFX_upv_1 (copy, index: 12)
                        SnapPoints_upv_1 (copy, index: 13)
                        SnapOnly_upv_1 (copy, index: 14)
                        tbl_upv_2 (ref,  index: 15)
                        NumberUtil_upv_1 (copy, index: 16)
                        u17 (ref,  index: 17)
                        u18 (ref,  index: 18)
                        u6 (ref,  index: 19)
                        u12 (ref,  index: 20)
                        u19 (ref,  index: 21)
                        OffsetSnappedFacingAway_upv_1 (copy, index: 22)
                        u20 (ref,  index: 23)
                        u29 (copy, index: 24)
                        u10 (ref,  index: 25)
                        u5 (ref,  index: 26)
                        u7 (ref,  index: 27)
                        MaxPerBase_upv_1 (copy, index: 28)
                        u9 (ref,  index: 29)
                        ActiveBenchModule_upv_1 (copy, index: 30)
                        u16 (ref,  index: 31)
                        u26 (copy, index: 32)
                    ]]
                    if (u2 == u30 and u3 and Parent_upv_1 and Parent_upv_1.PrimaryPart and Humanoid_upv_1) then
                        local v50 = nil;
                        if (Humanoid_upv_1.Health > 0) then
                            local v51 = tick() - u11 >= 0.1;
                            local v52 = CameraController_upv_1:GetAttribute("ViewmodelCFrame") or (CurrentCamera_upv_1.CFrame);
                            local v53 = u8.PlaceExtraDistance or 0;
                            local v54, v55, v56, v57 = RaycastUtil_upv_1:Raycast(Parent_upv_1.PrimaryPart.Position + Vector3.new(0, 1.5, 0), v52.LookVector * (8 + v53), "Blacklist", {Parent_upv_1, VFX_upv_1}, false, RaycastUtil_upv_1:FilterFunction("View"), true);
                            v56 = v56 or Vector3.new(0, 1, 0);
                            local v58 = math.deg(math.acos(v56.Y));
                            local v59 = nil;
                            local v73 = nil;
                            for n_1 = 14, 8, -1.5 do
                                if ((SnapPoints_upv_1) and SnapOnly_upv_1 ~= nil) then
                                    v59 = CFrame.new((v52 * CFrame.new(0, 0, -(n_1 + v53))).Position);
                                elseif (u8.RotateOnSurface) then
                                    local v60 = CFrame.new(v55, v55 + Vector3.new(0, 1, 0));
                                    v73 = function(a3, a4, a5)
                                        --[[
                                          line: 431
                                        ]]
                                        local v62 = a3:Dot(a4);
                                        local v63 = a3:Cross(a4);
                                        if (v62 >= -0.99999) then
                                            return CFrame.new(0, 0, 0, v63.x, v63.y, v63.z, 1 + v62);
                                        end;
                                        return CFrame.fromAxisAngle(a5, math.pi);
                                    end;
                                    v59 = ((v73(v60.UpVector, v56, Vector3.new(1, 0, 0)) * v60).Rotation + v60.Position) * CFrame.Angles(1.5707963267948966, 0, 0);
                                else
                                    v59 = CFrame.new(v55, v55 + Vector3.new(0, 1, 0));
                                end;
                                if (not (v51)) then
                                    break;
                                end;
                                if (not (SnapPoints_upv_1)) then
                                    break;
                                end;
                                local v65 = nil;
                                local v66 = nil;
                                local v67 = nil;
                                local v60 = v66;
                                local v68 = nil;
                                local v69 = nil;
                                for key_4, value_12 in pairs(tbl_upv_2) do
                                    v68 = nil;
                                    for key_5, v70 in pairs(value_12) do
                                        v73, v69 = NumberUtil_upv_1:IsWithin(v59.Position, v70.Position, 4);
                                        if (not (v73)) then
                                            continue;
                                        end;
                                        v68 = math.sqrt(v69);
                                        if (not (v60) or v60 >= v68) then
                                            local tbl_6 = {};
                                            tbl_6.Index = key_5;
                                            tbl_6.Offset = v70;
                                            v60, v65, v67 = v68, key_4, tbl_6;
                                        end;
                                    end;
                                end;
                                if (v65) then
                                    u17 = v65;
                                    u18 = v67;
                                    break;
                                end;
                                u17 = nil;
                                u18 = {};
                                if (n_1 == 8 and SnapOnly_upv_1 ~= nil) then
                                    v59 = CFrame.new((v52 * CFrame.new(0, 0, -(14 + v53))).Position);
                                end;
                                local v71 = n_1;
                            end;
                            local v72 = false;
                            if (u17 and u17.Parent and u18.Offset) then
                                local v74 = true;
                                v59, v73 = u18.Offset, v74;
                            else
                                v73 = v72;
                            end;
                            v59 = v59 * u8.Offset;
                            local v75, v76;
                            if (u8.FaceCamera) then
                                if (v73) then
                                    v75 = CFrame.new();
                                else
                                    v75 = CFrame.new(v59.Position, Vector3.new(v76.X, v59.Position.Y, v76.Z)) or CFrame.new();
                                end;
                            else
                                v75 = CFrame.new();
                            end;
                            local v77;
                            local v71;
                            v75, v71, v77 = v75:ToEulerAnglesXYZ();
                            local v78 = CFrame.Angles(v75, v71, v77);
                            if (SnapPoints_upv_1 == nil) then
                                if (SnapPoints_upv_1 ~= nil or v54) then
                                    v50 = CFrame.new();
                                else
                                    v50 = u8.UnsnappedOffset;
                                    v50 = v50 or CFrame.new();
                                end;
                            elseif (v72 and (SnapPoints_upv_1 ~= nil or v54)) then
                                v50 = CFrame.new();
                            else
                                v50 = u8.UnsnappedOffset;
                                v50 = v50 or CFrame.new();
                            end;
                            v59 = v59 * (v78 * v50);
                            local v79 = u6;
                            local v80 = CFrame.new();
                            local v81;
                            if ((v72) and u8.RotateOffset == CFrame.Angles(0, 1.5707963267948966, 0)) then
                                v81 = 0.5;
                            else
                                v81 = 0;
                            end;
                            local v82 = u12:Lerp(v80, v81);
                            v59 = v59 * v82;
                            if (not (u6)) then
                                u19 = false;
                                if (v72 and OffsetSnappedFacingAway_upv_1 and (v76 - v59.Position).Unit:Dot(v59.LookVector) < 0) then
                                    u19 = true;
                                end;
                                v80 = (v72 and v82) or (CFrame.new());
                                v79 = v59 * v80;
                            end;
                            v50 = u3.PrimaryPart.CFrame;
                            v80 = false;
                            u3:SetPrimaryPartCFrame(v79);
                            local v70 = nil;
                            if (v51) then
                                u20 = true;
                                v81 = shared.Beds;
                                if (v81 and u8.Type == "Bed") then
                                    for _, value_13 in pairs(v81) do
                                        if (NumberUtil_upv_1:IsWithin(v79.Position, Vector3.new(value_13.Position.X, v79.Position.Y, value_13.Position.Z), 150)) then
                                            u20 = false;
                                            break;
                                        end;
                                    end;
                                end;
                                local v83 = ((v72 and (u8.SnappedPlacingFunc)) or (u8.PlacingFunc))(u29, v54, v58, v54, v57);
                                local v84;
                                if (u29 == "Foundation") then
                                    v84 = not v72;
                                else
                                    v84 = false;
                                    if (u29 == "Triangle Foundation") then
                                        v84 = not v72;
                                    end;
                                end;
                                u11 = tick();
                                local v85 = u8.CollisionFunc(u3, v84, nil, u8.Type, u8.LenientCollision, v72);
                                u10 = v83 and v85;
                                if (u10) then
                                    u5 = v59;
                                    u7 = v54;
                                end;
                                if (u10 == false and u5 and u7) then
                                    local v86 = nil;
                                    if (u7.Parent) then
                                        if (not (u6)) then
                                            u11 = 0;
                                        end;
                                        u6 = u5;
                                        v86 = NumberUtil_upv_1:IsWithin(u6.Position, v59.Position, 0.4);
                                        if (not (v86)) then
                                            u5 = nil;
                                            u7 = nil;
                                            u6 = nil;
                                        end;
                                    end;
                                end;
                                if (u6) then
                                    v80 = true;
                                    u3:SetPrimaryPartCFrame(v59);
                                    local v87 = v83 and (u8.CollisionFunc(u3, v84, nil, u8.Type, u8.LenientCollision, v72));
                                    if (v87) then
                                        u5 = v59;
                                        u7 = v54;
                                        u6 = nil;
                                        u10 = true;
                                    else
                                        v80 = v85 and v80;
                                    end;
                                end;
                                if (SnapOnly_upv_1) then
                                    u10 = u10 and v72;
                                end;
                                if (u10 and MaxPerBase_upv_1 and u7) then
                                    local v88 = nil;
                                    if (not (v72)) then
                                        v88 = u7:FindFirstAncestor("Base");
                                        local v89 = nil;
                                        if (v88) then
                                            v89 = v88:FindFirstChild(u29);
                                            local v90 = true;
                                            if (v89 ~= nil) then
                                                v90 = #v89:GetChildren() < MaxPerBase_upv_1;
                                            end;
                                            u10 = v90;
                                        end;
                                    end;
                                end;
                                u9 = nil;
                                if (u10) then
                                    local v91 = nil;
                                    if (u29 ~= "Base Cabinet") then
                                        local IgnoreBuildBlock_1 = u8.IgnoreBuildBlock;
                                        local v91, v92 = RaycastUtil_upv_1:GetBaseCabinetUnder(v79.Position, IgnoreBuildBlock_1);
                                        if (v91 and v91:GetAttribute("Monument") and IgnoreBuildBlock_1 ~= "All" and (IgnoreBuildBlock_1 ~= "Monument" or v92)) then
                                            u9 = false;
                                        elseif ((IgnoreBuildBlock_1) and IgnoreBuildBlock_1 ~= "Monument") then
                                            u9 = nil;
                                        else
                                            v70 = ActiveBenchModule_upv_1.GetClientInfo(v91);
                                            u9 = (not v70) or (v70.Access);
                                        end;
                                        if (u9 ~= false) then
                                            v70 = true;
                                        else
                                            v70 = false;
                                        end;
                                        u10 = v70;
                                    else
                                        local tbl_7 = {VFX_upv_1};
                                        local value_13 = RaycastUtil_upv_1:Raycast(Vector3.new(v79.Position.X, 225.6, v79.Position.Z), Vector3.new(0, -0.20000000298023224, 0), "Blacklist", tbl_7, false, RaycastUtil_upv_1:FilterFunction("BuildingPrivCheck")) == nil;
                                        u10 = value_13;
                                    end;
                                end;
                            end;
                            u2:SetPrimaryPartCFrame(v79);
                            local v94 = nil;
                            for _, value_14 in pairs(u2:GetDescendants()) do
                                if (not (value_14:IsA("BasePart")) or not (value_14.Parent:IsA("Model"))) then
                                    continue;
                                end;
                                v94 = script;
                                if (not (u10)) then
                                    v70 = "PlaceUnavailableColor";
                                    value_14.Color = v94:GetAttribute(v70);
                                    continue;
                                end;
                                if (u9 == false) then
                                    v70 = "PlaceBlockedColor";
                                    value_14.Color = v94:GetAttribute(v70);
                                    continue;
                                end;
                                if (u20) then
                                    v70 = "PlaceAvailableColor";
                                else
                                    v70 = "PlaceBlockedColor";
                                end;
                                value_14.Color = v94:GetAttribute(v70);
                            end;
                            if (not (v80)) then
                                u3:SetPrimaryPartCFrame(v50);
                            end;
                            if (u16 and not (NumberUtil_upv_1:IsWithin(v76, u16, 75))) then
                                u26();
                            end;
                        else
                            u27();
                        end;
                    else
                        u27();
                    end;
                end
            );
        end;
    end;
end;
local function u31()
    --[[
      line: 608
      upvalues:
        InventoryController_upv_1 (copy, index: 1)
        EquipController_upv_1 (copy, index: 2)
        BasePartInfo_upv_1 (copy, index: 3)
        RecipeModule_upv_1 (copy, index: 4)
        Items_upv_1 (copy, index: 5)
        Name_upv_1 (ref,  index: 6)
        NumberUtil_upv_1 (copy, index: 7)
        WheelController_upv_1 (copy, index: 8)
        u28 (copy, index: 9)
        InteractController_upv_1 (copy, index: 10)
        BenchInfo_upv_1 (copy, index: 11)
        Values_upv_1 (copy, index: 12)
        RaycastUtil_upv_1 (copy, index: 13)
        ActiveBenchModule_upv_1 (copy, index: 14)
        tbl_upv_1 (copy, index: 15)
        u1 (copy, index: 16)
        u8 (ref,  index: 17)
        u12 (ref,  index: 18)
        u13 (ref,  index: 19)
    ]]
    local v95 = nil;
    if (not InventoryController_upv_1:GetAttribute("Open")) then
        local v96 = EquipController_upv_1:GetAttribute("Equipped");
        v95 = InventoryController_upv_1.Fetch:Invoke();
        local v97, v98 = nil, nil;
        if (v95) then
            v97 = v95.Toolbar;
            local v99 = nil;
            if (v97) then
                local v100 = v96 or (script:GetAttribute("Equipped"));
                v99 = v97[v100];
                v98 = false;
                if (v99 ~= nil) then
                    v98 = false;
                    if (v99 ~= 0) then
                        v98 = v99;
                    end;
                end;
            else
                v98 = nil;
            end;
        else
            v98 = nil;
        end;
        if (v98) then
            local v101 = InventoryController_upv_1.Fetch:Invoke();
            local tbl_8 = {};
            for _, v102 in pairs({"Inventory", "Toolbar"}) do
                for v122, value_15 in pairs(v101[v102]) do
                    if (value_15 == 0) then
                        continue;
                    end;
                    if (not (tbl_8[value_15.ID])) then
                        tbl_8[value_15.ID] = 0;
                    end;
                    local ID_1 = value_15.ID;
                    tbl_8[ID_1] = tbl_8[ID_1] + value_15.Amount;
                end;
            end;
            local v103 = nil;
            if (v98.ID == 30) then
                local v104 = BasePartInfo_upv_1:Fetch();
                local v105 = nil;
                local v106 = nil;
                local v107 = nil;
                for _, value_16 in pairs(v104) do
                    value_16.Image = script:GetAttribute("Build" .. value_16.Name:gsub(" ", "_"):gsub("-", "_"));
                    v107 = RecipeModule_upv_1:FetchRecipe("Twig", value_16.Name);
                    if (not (v107)) then
                        continue;
                    end;
                    v105 = v107.Costs[1];
                    if (v105) then
                        v106 = Items_upv_1[v105.ID];
                        value_16.Selectable = true;
                        value_16.SelectFirst = Name_upv_1 == value_16.Name;
                        value_16.Cost = NumberUtil_upv_1:FormatNumber(v105.Amount) .. " " .. v106.Name .. " (" .. NumberUtil_upv_1:FormatNumber(tbl_8[v105.ID] or 0) .. " Left)";
                    end;
                end;
                v103 = WheelController_upv_1.Open:Invoke(v104, "Blueprint", false);
                local v108 = nil;
                if (v103) then
                    v108 = v104[v103];
                end;
                if (not v103 or not v108) then
                    return;
                end;
                Name_upv_1 = v108.Name;
                u28(script:GetAttribute("Equipped"));
            elseif (v98.ID == 31) then
                v97 = InteractController_upv_1.GetSelected:Invoke();
                if (v97) then
                    local v109 = nil;
                    if (v97.Parent) then
                        v109 = v97.Name;
                        local v110 = nil;
                        if (v109 ~= "Wall Block") then
                            v110 = BenchInfo_upv_1[v109];
                            local PrimaryPart_1 = v97.PrimaryPart;
                            if (not v110) then
                                return;
                            end;
                            if (PrimaryPart_1) then
                                local v111 = nil;
                                if (v110.Type == "BasePart") then
                                    local v102 = v110.RotateOffset;
                                    v111 = Values_upv_1.ServerTick.Value;
                                    local v112 = v97:GetAttribute("DamageType");
                                    local v113, v114, v115 = nil, nil, nil;
                                    if (v111 - (v97:GetAttribute("LastDamaged") or 0) >= 60) then
                                        v113 = RaycastUtil_upv_1:GetBaseCabinetUnder(PrimaryPart_1.Position);
                                        if (v113 and v113:GetAttribute("Monument")) then
                                            return;
                                        end;
                                        v114 = ActiveBenchModule_upv_1.GetClientInfo(v113);
                                        if (v114 and v114.Access == false) then
                                            return;
                                        end;
                                        local tbl_9 = {};
                                        tbl_9[1] = {Image = script:GetAttribute("HammerWoodIcon")};
                                        tbl_9[2] = {Image = script:GetAttribute("HammerStoneIcon")};
                                        tbl_9[3] = {Image = script:GetAttribute("HammerMetalIcon")};
                                        tbl_9[4] = {Image = script:GetAttribute("HammerSteelIcon")};
                                        tbl_9[5] = {Image = script:GetAttribute("HammerRotateIcon")};
                                        tbl_9[6] = {Image = script:GetAttribute("HammerDemolishIcon")};
                                        local v116 = nil;
                                        local v117 = nil;
                                        local v123 = nil;
                                        local v118 = nil;
                                        for v124, value_17 in pairs(tbl_9) do
                                            v116 = value_17.Name;
                                            if (v116:sub(1, 7) ~= "Upgrade") then
                                                v117 = false;
                                                local v119 = v97:GetAttribute(((v116 ~= "Demolish") and "Upgraded") or "Placed") or (v111 - 0.01);
                                                if (v111 - v119 >= Values_upv_1.DemolishTimer.Value) then
                                                    local value_17;
                                                    value_17.Selectable = v117;
                                                    value_17.SelectFirst = false;
                                                    continue;
                                                end;
                                                v117 = Values_upv_1.SimpleDemolish.Value;
                                                if (v117) then
                                                    local value_17;
                                                    value_17.Selectable = v117;
                                                    value_17.SelectFirst = false;
                                                    continue;
                                                end;
                                                if (v116 ~= "Demolish") then
                                                    v117 = false;
                                                    if (v116 == "Rotate") then
                                                        v117 = v102 and (v102 ~= CFrame.new());
                                                    end;
                                                    local value_17;
                                                    value_17.Selectable = v117;
                                                    value_17.SelectFirst = false;
                                                elseif (v114 == nil) then
                                                    v117 = false;
                                                    if (v116 == "Rotate") then
                                                        v117 = v102 and (v102 ~= CFrame.new());
                                                    end;
                                                else
                                                    v117 = v114.Access;
                                                    if (v117) then
                                                        local value_17;
                                                        value_17.Selectable = v117;
                                                        value_17.SelectFirst = false;
                                                        continue;
                                                    end;
                                                    v117 = false;
                                                    if (v116 == "Rotate") then
                                                        v117 = v102 and (v102 ~= CFrame.new());
                                                    end;
                                                    local value_17;
                                                    value_17.Selectable = v117;
                                                    value_17.SelectFirst = false;
                                                end;
                                                local value_17;
                                                value_17.Selectable = v117;
                                                value_17.SelectFirst = false;
                                                continue;
                                            else
                                                local v120 = v116:sub(12);
                                                v118 = RecipeModule_upv_1:FetchRecipe(v120, v109);
                                                if (v118) then
                                                    local v121 = v118.Costs[1];
                                                    value_17.Cost = NumberUtil_upv_1:FormatNumber(v121.Amount) .. " " .. Items_upv_1[v121.ID].Name .. " (" .. NumberUtil_upv_1:FormatNumber(tbl_8[v121.ID] or 0) .. " Left)";
                                                end;
                                                local v121 = table.find(tbl_upv_1[v112 or "Twig"], v120) ~= nil;
                                                value_17.Selectable = v121;
                                            end;
                                            value_17.SelectFirst = false;
                                        end;
                                        v115 = WheelController_upv_1.Open:Invoke(tbl_9, "Hammer", true);
                                        if (not v115 or not tbl_9[v115]) then
                                            return;
                                        end;
                                        u1("Fire", "NM\182\001\154\155j\149\231\163\004\179F\180\232\247\208\a\221\217", "\223\155\187BG2\179\190\204\146\219\194<\001c\152\005\141:?", v97 or "none", v115);
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        elseif (u8) then
            u12 = u12 * u8.RotateOffset;
            u13 = u13 + 1;
        end;
    end;
end;
local function u32(a1)
    --[[
      line: 728
      upvalues:
        LocalPlayer_upv_1 (copy, index: 1)
        u26 (copy, index: 2)
    ]]
    if (not a1 or not a1.Parent) then
        return;
    end;
    if (a1:IsA("Model")) then
        a1:GetPropertyChangedSignal("PrimaryPart"):Connect(
            function()
                --[[
                  line: 731
                  upvalues:
                    a1 (copy, index: 1)
                    LocalPlayer_upv_1 (copy, index: 2)
                    u26 (copy, index: 3)
                ]]
                local v122 = nil;
                if (a1.PrimaryPart) then
                    v122 = LocalPlayer_upv_1:GetAttribute("ArenaIndex");
                    local v123 = a1:GetAttribute("ArenaIndex");
                    if (v122 ~= nil and v123 ~= nil and v122 ~= v123) then
                        return;
                    end;
                    u26();
                end;
            end
        );
        local v124 = nil;
        if (a1.PrimaryPart) then
            v124 = LocalPlayer_upv_1:GetAttribute("ArenaIndex");
            local v125 = a1:GetAttribute("ArenaIndex");
            if (v124 ~= nil and v125 ~= nil and v124 ~= v125) then
                return;
            end;
            u26();
        end;
    end;
end;
local function u33(a1)
    --[[
      line: 754
      upvalues:
        tbl_upv_3 (copy, index: 1)
        u32 (copy, index: 2)
    ]]
    if (not a1:IsA("Folder") or not tbl_upv_3[a1.Name]) then
        return;
    end;
    a1.ChildAdded:Connect(u32);
    for _, value_18 in pairs(a1:GetChildren()) do
        u32(value_18);
    end;
end;
UserInputService_upv_1.InputBegan:Connect(
    function(a1, a2)
        --[[
          line: 774
          upvalues:
            SettingsModule_upv_1 (copy, index: 1)
            UserInputService_upv_1 (copy, index: 2)
            u8 (ref,  index: 3)
            PreferredInputController_upv_1 (copy, index: 4)
            u24 (copy, index: 5)
            u12 (ref,  index: 6)
            u13 (ref,  index: 7)
            InteractController_upv_1 (copy, index: 8)
            u31 (copy, index: 9)
            EquipController_upv_1 (copy, index: 10)
            InventoryController_upv_1 (copy, index: 11)
        ]]
        if (not SettingsModule_upv_1.MainMenuOpen()) then
            local UserInputType_1 = a1.UserInputType;
            local v126 = UserInputService_upv_1:GetFocusedTextBox();
            if (u8) then
                local v127 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                if (v127 and UserInputType_1 == Enum.UserInputType.Gamepad1) then
                    v127 = a1.KeyCode.Name;
                    if (v127 == SettingsModule_upv_1.GetSetting("Gamepad", "Place Building")) then
                        u24();
                    elseif (v127 ~= SettingsModule_upv_1.GetSetting("Gamepad", "Rotate Building")) then
                        if (v127 == SettingsModule_upv_1.GetSetting("Gamepad", "Change Building")) then
                            if (not (InteractController_upv_1.GetSelected:Invoke())) then
                                u31();
                            end;
                            return;
                        end;
                        v127 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                        if (v127 and UserInputType_1 == Enum.UserInputType.Gamepad1) then
                            local v128 = nil;
                            if (a1.KeyCode.Name == "ButtonL2") then
                                local v129 = EquipController_upv_1:GetAttribute("Equipped");
                                v128 = InventoryController_upv_1.Fetch:Invoke();
                                local v130 = nil;
                                if (v128) then
                                    v130 = v128.Toolbar;
                                    local v131 = nil;
                                    if (v130) then
                                        local v132 = v129 or (script:GetAttribute("Equipped"));
                                        v131 = v130[v132];
                                        local v133 = false;
                                        if (v131 == nil) then
                                            v127 = v133;
                                        else
                                            local v134 = false;
                                            if (v131 == 0) then
                                                v127 = v134;
                                            else
                                                v127 = v131;
                                            end;
                                        end;
                                    else
                                        v127 = nil;
                                    end;
                                else
                                    v127 = nil;
                                end;
                                if (v127 and v127.ID == 31) then
                                    u31();
                                    return;
                                end;
                            end;
                        end;
                        if (not (v126) and not (a2)) then
                            if (UserInputType_1 ~= Enum.UserInputType.MouseButton1) then
                                if (UserInputType_1 == Enum.UserInputType.MouseButton2 and SettingsModule_upv_1.GetSetting("Controls", "Change Building") == "MB2") then
                                    u31();
                                    return;
                                end;
                                if (UserInputType_1 == Enum.UserInputType.Keyboard and a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Controls", "Change Building")) then
                                    u31();
                                end;
                            else
                                u24();
                            end;
                            return;
                        end;
                    elseif (u8) then
                        u12 = u12 * u8.RotateOffset;
                        u13 = u13 + 1;
                    end;
                    return;
                end;
                if (UserInputType_1 == Enum.UserInputType.Keyboard and not (v126)) then
                    v127 = a1.KeyCode.Name;
                    if (v127 == SettingsModule_upv_1.GetSetting("Controls", "Rotate Building")) then
                        if (u8) then
                            u12 = u12 * u8.RotateOffset;
                            u13 = u13 + 1;
                        end;
                        return;
                    elseif (v127 == SettingsModule_upv_1.GetSetting("Controls", "Change Building")) then
                        if (not (InteractController_upv_1.GetSelected:Invoke())) then
                            u31();
                        end;
                        return;
                    end;
                end;
            end;
            local v127;
            v127 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
            if (v127 and UserInputType_1 == Enum.UserInputType.Gamepad1) then
                local v128 = nil;
                if (a1.KeyCode.Name == "ButtonL2") then
                    local v129 = EquipController_upv_1:GetAttribute("Equipped");
                    v128 = InventoryController_upv_1.Fetch:Invoke();
                    local v130 = nil;
                    if (v128) then
                        v130 = v128.Toolbar;
                        local v131 = nil;
                        if (v130) then
                            local v132 = v129 or (script:GetAttribute("Equipped"));
                            v131 = v130[v132];
                            local v133 = false;
                            if (v131 == nil) then
                                v127 = v133;
                            else
                                local v134 = false;
                                if (v131 == 0) then
                                    v127 = v134;
                                else
                                    v127 = v131;
                                end;
                            end;
                        else
                            v127 = nil;
                        end;
                    else
                        v127 = nil;
                    end;
                    if (v127 and v127.ID == 31) then
                        u31();
                        return;
                    end;
                end;
            end;
            if (not (v126) and not (a2)) then
                if (UserInputType_1 ~= Enum.UserInputType.MouseButton1) then
                    if (UserInputType_1 == Enum.UserInputType.MouseButton2 and SettingsModule_upv_1.GetSetting("Controls", "Change Building") == "MB2") then
                        u31();
                        return;
                    end;
                    if (UserInputType_1 == Enum.UserInputType.Keyboard and a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Controls", "Change Building")) then
                        u31();
                    end;
                else
                    u24();
                end;
                return;
            end;
        end;
    end
);
UserInputService_upv_1.InputEnded:Connect(
    function(a1, a2)
        --[[
          line: 826
          upvalues:
            SettingsModule_upv_1 (copy, index: 1)
            WheelController_upv_1 (copy, index: 2)
        ]]
        local UserInputType_2 = a1.UserInputType;
        if (UserInputType_2 ~= Enum.UserInputType.MouseButton2 or SettingsModule_upv_1.GetSetting("Controls", "Change Building") ~= "MB2") then
            if (UserInputType_2 == Enum.UserInputType.Keyboard) then
                if (a1.KeyCode.Name ~= SettingsModule_upv_1.GetSetting("Controls", "Change Building")) then
                    return;
                end;
                WheelController_upv_1.Close:Invoke("Blueprint");
                WheelController_upv_1.Close:Invoke("Hammer");
            elseif (UserInputType_2 == Enum.UserInputType.Gamepad1 and a1.KeyCode.Name == SettingsModule_upv_1.GetSetting("Gamepad", "Change Building")) then
                WheelController_upv_1.Close:Invoke("Blueprint");
                WheelController_upv_1.Close:Invoke("Hammer");
            end;
        end;
        WheelController_upv_1.Close:Invoke("Blueprint");
        WheelController_upv_1.Close:Invoke("Hammer");
    end
);
local function v135(a1)
    --[[
      line: 763
      upvalues:
        u33 (copy, index: 1)
    ]]
    if (not a1:IsA("Folder") or a1.Name ~= "Base") then
        return;
    end;
    a1.ChildAdded:Connect(u33);
    for _, value_19 in pairs(a1:GetChildren()) do
        u33(value_19);
    end;
end;
Bases_upv_1.ChildAdded:Connect(v135);
for _, value_20 in pairs(Bases_upv_1:GetChildren()) do
    v135(value_20);
end;
EquipBench_1.Event:Connect(
    function(...)
        --[[
          line: 849
          upvalues:
            u28 (copy, index: 1)
            WheelController_upv_1 (copy, index: 2)
            Name_upv_1 (ref,  index: 3)
            u14 (ref,  index: 4)
            u27 (copy, index: 5)
        ]]
        local v136 = ({...})[1];
        if (not v136 or v136 <= 0) then
            WheelController_upv_1.Close:Invoke("Blueprint");
            WheelController_upv_1.Close:Invoke("Hammer");
            if (Name_upv_1 ~= u14) then
                u14 = nil;
            end;
            u27();
        end;
        u28(...);
    end
);
Build_1.OnClientEvent:Connect(
    function(a1, ...)
        --[[
          line: 867
          upvalues:
            u26 (copy, index: 1)
        ]]
        local _ = {...};
        if (a1 ~= "UpdateSnaps") then
            return;
        end;
        u26(true);
    end
);
local _ = nil;
local v139 = nil;
local v140 = nil;
local v141 = nil;
local v137 = nil;
local v138 = nil;
for v142, value_21 in pairs(BenchInfo_upv_1) do
    v138 = value_21.SnapPoints;
    if (not (v138)) then
        continue;
    end;
    v140 = nil;
    v141 = nil;
    for v143, value_22 in pairs(v138) do
        v137 = value_22.BenchNames;
        if (not (v137)) then
            continue;
        end;
        for v144, value_23 in pairs(v137) do
            tbl_upv_3[value_23] = true;
        end;
    end;
end;
Benches_upv_2:ClearAllChildren();