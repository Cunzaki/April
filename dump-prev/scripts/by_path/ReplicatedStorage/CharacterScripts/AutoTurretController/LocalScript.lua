-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local Players_upv_1 = game:GetService("Players");
local Bases_1 = workspace:WaitForChild("Bases");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local LocalPlayer_1 = game.Players.LocalPlayer;
local v1 = LocalPlayer_1.Character or (LocalPlayer_1.CharacterAdded:Wait());
local HumanoidRootPart_1 = v1:WaitForChild("HumanoidRootPart");
local NumberUtil_1 = require(Modules_1:WaitForChild("NumberUtil"));
local tbl_upv_1 = {};
local tbl_upv_2 = {};
local function CalculateStepsWait_1(a1)
    --[[
      name: CalculateStepsWait
      line: 44
    ]]
    a1 = a1 + 1;
    if (a1 >= 5) then
        a1 = 1;
        task.wait();
    end;
    return a1;
end;
local function StartTurretTraceLoop_upv_1(a1)
    --[[
      name: StartTurretTraceLoop
      line: 53
      upvalues:
        tbl_upv_2 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
        Players_upv_1 (copy, index: 3)
    ]]
    if (tbl_upv_2[a1]) then
        return;
    end;
    if (tbl_upv_1[a1]) then
        tbl_upv_2[a1] = true;
        if (tbl_upv_1[a1][2] ~= nil) then
            tbl_upv_1[a1][2]:Stop();
        end;
        local MotorPart_1 = a1:FindFirstChild("MotorPart");
        local _ = MotorPart_1 and (MotorPart_1:FindFirstChild("Motor6D"));
        local Top_1 = a1:FindFirstChild("Top");
        while (a1 and (a1:FindFirstChild("Main")) and (MotorPart_1) and (MotorPart_1) and (Top_1) and a1:GetAttribute("S") ~= nil) do
            task.wait(0.2);
            local v2 = a1:GetAttribute("S") and (Players_upv_1:FindFirstChild(a1:GetAttribute("S")));
            local v3 = v2 and (v2.Character);
            local v4 = v3 and (v3:FindFirstChild("HumanoidRootPart"));
            if (not (v4) or not (Top_1)) then
                continue;
            end;
            local v5, v6;
            if (not (MotorPart_1)) then
                continue;
            end;
            v5 = MotorPart_1.Part0.CFrame * MotorPart_1.C0;
            v6 = v4.Position - v5.Position;
            if (v6.Magnitude < 0.01) then
                continue;
            end;
            if (math.abs(v6.Unit.Y) <= 0.999) then
                local v7 = CFrame.lookAt(v5.Position, v4.Position);
                MotorPart_1.C1 = (CFrame.new(0, -0.7, -0.1) * CFrame.Angles(0, -1.5707963267948966, 0)) * v7:Inverse().Rotation * v5.Rotation;
            end;
        end;
        tbl_upv_2[a1] = false;
        if (MotorPart_1) then
            MotorPart_1.C1 = CFrame.new(0, -0.7, -0.1);
        end;
    else
        warn("[AutoTurretController] - StartTurretTraceLoop ran without turret model in nearby turrets");
    end;
end;
while (v1) do
    local v8, v9, v10, _ = nil, nil, nil, nil;
    if (not (v1:FindFirstChild("HumanoidRootPart"))) then
        break;
    end;
    task.wait(6);
    local v11 = 1;
    local v14 = nil;
    local Main_1 = nil;
    local Animation_1 = nil;
    local AnimationController_1 = nil;
    for v15, value_1 in Bases_1:GetChildren() do
        v8 = value_1:FindFirstChild("Auto Turret");
        if (not (v8)) then
            continue;
        end;
        Main_1 = nil;
        Animation_1 = nil;
        for v16, value_upv_2 in value_1:FindFirstChild("Auto Turret"):GetChildren() do
            Main_1 = value_upv_2:FindFirstChild("Main");
            Animation_1 = value_upv_2:FindFirstChild("Animation");
            AnimationController_1 = value_upv_2:FindFirstChild("AnimationController");
            if (value_upv_2.Name == "Auto Turret" and Main_1 and Animation_1 and AnimationController_1 and NumberUtil_1:IsWithin(Main_1.Position, v1.HumanoidRootPart.Position, 300) and tbl_upv_1[value_upv_2] == nil) then
                tbl_upv_1[value_upv_2] = {
                    value_upv_2.AttributeChanged:Connect(
                        function(a1)
                            --[[
                              line: 111
                              upvalues:
                                value_upv_2 (copy, index: 1)
                                StartTurretTraceLoop_upv_1 (copy, index: 2)
                            ]]
                            if (not value_upv_2:GetAttribute("S")) then
                                return;
                            end;
                            StartTurretTraceLoop_upv_1(value_upv_2);
                        end
                    ),
                    AnimationController_1:LoadAnimation(Animation_1)
                };
            end;
            v9 = v11 + 1;
            if (v9 >= 5) then
                v9 = 1;
                task.wait();
            end;
            v11 = v9;
        end;
        v10 = v11 + 1;
        if (v10 < 5) then
            v8 = v10;
        else
            local v12 = 1;
            task.wait();
            v8 = v12;
        end;
        v11 = v8;
    end;
    for key_1, value_3 in tbl_upv_1 do
        if (key_1 and key_1:FindFirstChild("Main") and NumberUtil_1:IsWithin(key_1.Main.Position, HumanoidRootPart_1.Position, 300)) then
            if (key_1 and not (key_1:GetAttribute("S")) and value_3[2] and not (value_3[2].IsPlaying)) then
                v8 = key_1:FindFirstChild("Top");
                local v13 = v8 and (v8:FindFirstChild("Laser"));
                if (v13 and v13.Enabled) then
                    value_3[2]:Play();
                end;
            end;
        else
            tbl_upv_2[key_1] = nil;
            if (value_3[1]) then
                value_3[1]:Disconnect();
            end;
            if (value_3[2]) then
                value_3[2]:Stop();
            end;
            tbl_upv_1[key_1] = nil;
        end;
        v8 = v11 + 1;
        if (v8 >= 5) then
            v8 = 1;
            task.wait();
        end;
        v11 = v8;
    end;
end;