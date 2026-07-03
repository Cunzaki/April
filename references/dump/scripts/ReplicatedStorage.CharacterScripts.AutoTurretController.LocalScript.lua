-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local Bases = workspace:WaitForChild("Bases");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local LocalPlayer = game.Players.LocalPlayer;
local v1 = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local HumanoidRootPart = v1:WaitForChild("HumanoidRootPart");
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local u2 = {};
local u3 = {};

local function CalculateStepsWait(p4) -- Line: 44
    local v5 = p4 + 1;

    if v5 >= 5 then
        task.wait();
        v5 = 1;
    end;

    return v5;
end;

local function StartTurretTraceLoop(p6) -- Line: 53
    -- upvalues: u3 (copy), u2 (copy), Players (copy)
    if u3[p6] then
        return;
    end;

    if not u2[p6] then
        warn("[AutoTurretController] - StartTurretTraceLoop ran without turret model in nearby turrets");

        return;
    end;

    u3[p6] = true;

    if u2[p6][2] ~= nil then
        u2[p6][2]:Stop();
    end;

    local MotorPart = p6:FindFirstChild("MotorPart");
    local v7;

    if MotorPart then
        v7 = MotorPart:FindFirstChild("Motor6D");
    else
        v7 = MotorPart;
    end;

    local Top = p6:FindFirstChild("Top");

    while p6 and (p6:FindFirstChild("Main") and (MotorPart and (v7 and (Top and p6:GetAttribute("S") ~= nil)))) do
        task.wait(0.2);
        local v8 = p6:GetAttribute("S") and Players:FindFirstChild(p6:GetAttribute("S")) and v8.Character and v8:FindFirstChild("HumanoidRootPart");

        if v8 and (Top and v7) then
            local Position = v7.Part1.CFrame:ToWorldSpace(v7.C1).Position;
            local Position2 = v8.Position;
            local v9 = CFrame.new(Position, (Vector3.new(Position2.X, Position.Y, Position2.Z))):Inverse();
            v7.C1 = CFrame.new(0, -0.7, -0.1) * v9.Rotation * CFrame.Angles(0, -1.5707963267948966, 0);
        end;
    end;

    u3[p6] = false;

    if v7 then
        v7.C1 = CFrame.new(0, -0.7, -0.1);
    end;
end;

while v1 and v1:FindFirstChild("HumanoidRootPart") do
    task.wait(6);
    local v10 = 1;

    for _, child in Bases:GetChildren() do
        if child:FindFirstChild("Auto Turret") then
            for _, child2 in child:FindFirstChild("Auto Turret"):GetChildren() do
                local Main = child2:FindFirstChild("Main");
                local Animation = child2:FindFirstChild("Animation");
                local AnimationController = child2:FindFirstChild("AnimationController");

                if child2.Name == "Auto Turret" and (Main and (Animation and (AnimationController and NumberUtil:IsWithin(Main.Position, v1.HumanoidRootPart.Position, 300)))) then
                    if u2[child2] == nil then
                        u2[child2] = { 1, AnimationController:LoadAnimation(Animation) };
                    end;

                    u2[child2][1] = child2.AttributeChanged:Connect(function(p11) -- Line: 111
                        -- upvalues: child2 (copy), StartTurretTraceLoop (copy)
                        if child2:GetAttribute("S") then
                            StartTurretTraceLoop(child2);
                        end;
                    end);
                end;

                v10 = v10 + 1;

                if v10 >= 5 then
                    task.wait();
                    v10 = 1;
                end;
            end;

            v10 = v10 + 1;

            if v10 >= 5 then
                task.wait();
                v10 = 1;
            end;
        end;
    end;

    for i, v in u2 do
        if i and (i:FindFirstChild("Main") and NumberUtil:IsWithin(i.Main.Position, HumanoidRootPart.Position, 300)) then
            if i and (not i:GetAttribute("S") and (v[2] and not v[2].IsPlaying)) then
                local v12 = i:FindFirstChild("Top") and v12:FindFirstChild("Laser");

                if v12 and v12.Enabled then
                    v[2]:Play();
                end;
            end;
        else
            u3[i] = nil;

            if v[1] then
                v[1]:Disconnect();
            end;

            if v[2] then
                v[2]:Stop();
            end;

            u2[i] = nil;
        end;

        v10 = v10 + 1;

        if v10 >= 5 then
            task.wait();
            v10 = 1;
        end;
    end;
end;