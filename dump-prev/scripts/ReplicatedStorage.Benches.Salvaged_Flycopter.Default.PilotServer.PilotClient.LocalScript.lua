-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local RunService_upv_1 = game:GetService("RunService");
local ContextActionService_upv_1 = game:GetService("ContextActionService");
local _ = game:GetService("Workspace");
local UserInputService_upv_1 = game:GetService("UserInputService");
local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local TweenService_upv_1 = game:GetService("TweenService");
local LocalPlayer_1 = Players_1.LocalPlayer;
local CurrentCamera_upv_1 = workspace.CurrentCamera;
assert(LocalPlayer_1 and CurrentCamera_upv_1, "This script must run as a LocalScript on the client (accesses camera and input).");
local Plane_1 = script:FindFirstChild("Plane");
assert(Plane_1, "Missing ObjectValue 'Plane' under script. Set it to the engine BasePart.");
local Value_upv_1 = Plane_1.Value;
local v1 = Value_upv_1 and (Value_upv_1:IsA("BasePart"));
assert(v1, "Plane.Value must be a BasePart (the helicopter\226\128\153s main body/engine part).");
local Parent_upv_1 = Value_upv_1.Parent;
local VehicleSeat_upv_1 = Parent_upv_1:FindFirstChild("VehicleSeat");
local PassengerSeat1_upv_1 = Parent_upv_1:FindFirstChild("PassengerSeat1");
local Gear_upv_1 = Parent_upv_1:FindFirstChild("Gear");
local Colliders_upv_1 = Parent_upv_1:FindFirstChild("Colliders");
local MainRotor_1 = Parent_upv_1:FindFirstChild("MainRotor");
local Spinner_1 = MainRotor_1:FindFirstChild("Spinner");
local Blades_upv_1 = MainRotor_1:FindFirstChild("Blades");
local RotorMotor_upv_1 = Spinner_1:FindFirstChild("RotorMotor");
local TailRotor_1 = Parent_upv_1:FindFirstChild("TailRotor");
local Spinner_2 = TailRotor_1:FindFirstChild("Spinner");
local Blades_upv_2 = TailRotor_1:FindFirstChild("Blades");
local RotorMotor_upv_2 = Spinner_2:FindFirstChild("RotorMotor");
local u1 = nil;
RotorMotor_upv_1.AngularVelocity = 0;
RotorMotor_upv_2.AngularVelocity = 0;
local Events_1 = Parent_upv_1:FindFirstChild("Events");
local ReplicateEffect_upv_1 = Events_1:FindFirstChild("ReplicateEffect");
local ReplicateHealth_upv_1 = Events_1:FindFirstChild("ReplicateHealth");
local RotorWash_upv_1 = Parent_upv_1:FindFirstChild("VFX"):FindFirstChild("RotorWash");
local VFX_1 = workspace:WaitForChild("VFX");
local Trees_1 = workspace:WaitForChild("Trees");
local Nodes_1 = workspace:WaitForChild("Nodes");
local Plants_1 = workspace:WaitForChild("Plants");
local Animals_1 = workspace:WaitForChild("Animals");
local SettingsModule_upv_1 = require(ReplicatedStorage_1:WaitForChild("Modules"):WaitForChild("SettingsModule"));
local function getOrCreateAttachment_1(a1, a2)
    --[[
      name: getOrCreateAttachment
      line: 63
    ]]
    local v2 = a1:FindFirstChild(a2);
    if (v2 and v2:IsA("Attachment")) then
        return v2;
    else
        local v3 = Instance.new("Attachment");
        v3.Name = a2;
        v3.Parent = a1;
        return v3;
    end;
end;
local function getOrCreateAngularVelocity_1(a1, a2)
    --[[
      name: getOrCreateAngularVelocity
      line: 85
    ]]
    for _, value_1 in ipairs(a1:GetChildren()) do
        if (not (value_1:IsA("AngularVelocity"))) then
            continue;
        end;
        value_1.Name = a2;
        return value_1;
    end;
    local v4 = Instance.new("AngularVelocity");
    v4.Name = a2;
    v4.Parent = a1;
    return v4;
end;
local EngineAttachment_1 = Value_upv_1:FindFirstChild("EngineAttachment");
local v5;
if ((EngineAttachment_1) and (EngineAttachment_1:IsA("Attachment"))) then
    v5 = EngineAttachment_1;
else
    local v6 = Instance.new("Attachment");
    v6.Name = "EngineAttachment";
    v6.Parent = Value_upv_1;
    v5 = v6;
end;
local u2 = (function(a1, a2)
    --[[
      name: getOrCreateVectorForce
      line: 72
    ]]
    for _, value_2 in ipairs(a1:GetChildren()) do
        if (not (value_2:IsA("VectorForce"))) then
            continue;
        end;
        value_2.Name = a2;
        return value_2;
    end;
    local v7 = Instance.new("VectorForce");
    v7.Name = a2;
    v7.Parent = a1;
    return v7;
end)(Value_upv_1, "EngineVectorForce");
u2.Attachment0 = v5;
u2.ApplyAtCenterOfMass = true;
u2.RelativeTo = Enum.ActuatorRelativeTo.Attachment0;
local u3 = getOrCreateAngularVelocity_1(Value_upv_1, "EngineAngularVelocity");
u3.Attachment0 = v5;
u3.RelativeTo = Enum.ActuatorRelativeTo.Attachment0;
u3.ReactionTorqueEnabled = false;
local u4 = false;
local u5 = 0;
local u6 = 0;
local u7 = 0;
local u8 = 0;
local u9 = 0;
local u10 = LocalPlayer_1:WaitForChild("PlayerScripts"):FindFirstChild("PreferredInputController") or (LocalPlayer_1:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController", 5));
local u11 = nil;
local function getDeadzone_1()
    --[[
      name: getDeadzone
      line: 119
      upvalues:
        u10 (copy, index: 1)
    ]]
    local v8 = (u10 and (u10:GetAttribute("JoystickDeadzone"))) or 0.225;
    return v8;
end;
local function handleAction_1(a1, a2)
    --[[
      name: handleAction
      line: 132
      upvalues:
        u9 (ref, index: 1)
        u8 (ref, index: 2)
        u7 (ref, index: 3)
        u6 (ref, index: 4)
    ]]
    local v9 = a2 == Enum.UserInputState.Begin;
    local v10 = a2 == Enum.UserInputState.End;
    if (a1 ~= "ThrottleUp") then
        if (a1 ~= "ThrottleDown") then
            if (a1 ~= "YawRight") then
                if (a1 ~= "YawLeft") then
                    if (a1 ~= "PitchUp") then
                        if (a1 ~= "PitchDown") then
                            if (a1 ~= "RollRight") then
                                if (a1 ~= "RollLeft") then
                                    return;
                                end;
                                if (v9) then
                                    u6 = -1;
                                elseif (v10 and u6 == -1) then
                                    u6 = 0;
                                end;
                            elseif (v9) then
                                u6 = 1;
                            elseif (v10 and u6 == 1) then
                                u6 = 0;
                            end;
                        elseif (v9) then
                            u7 = -1;
                        elseif (v10 and u7 == -1) then
                            u7 = 0;
                        end;
                    elseif (v9) then
                        u7 = 1;
                    elseif (v10 and u7 == 1) then
                        u7 = 0;
                    end;
                elseif (v9) then
                    u8 = -1;
                elseif (v10 and u8 == -1) then
                    u8 = 0;
                end;
            elseif (v9) then
                u8 = 1;
            elseif (v10 and u8 == 1) then
                u8 = 0;
            end;
        elseif (v9) then
            u9 = -1;
        elseif (v10 and u9 == -1) then
            u9 = 0;
        end;
    elseif (v9) then
        u9 = 1;
    elseif (v10 and u9 == 1) then
        u9 = 0;
    end;
end;
ContextActionService_upv_1:BindAction("ThrottleUp", handleAction_1, false, Enum.KeyCode.W);
ContextActionService_upv_1:BindAction("ThrottleDown", handleAction_1, false, Enum.KeyCode.S);
ContextActionService_upv_1:BindAction("YawRight", handleAction_1, false, Enum.KeyCode.D);
ContextActionService_upv_1:BindAction("YawLeft", handleAction_1, false, Enum.KeyCode.A);
local Gravity_upv_1 = workspace.Gravity;
local tbl_upv_1 = {};
tbl_upv_1.mouse = {};
tbl_upv_1.camera = {};
tbl_upv_1.rotors = {main = {}, tail = {}};
local tbl_2 = {};
tbl_2.healthRange = NumberRange.new(0, 25);
tbl_upv_1.healthPenalties = {{healthRange = NumberRange.new(0, 50)}, tbl_2};
local tbl_3 = {};
tbl_3.takeDamageRange = NumberRange.new(10, 50);
tbl_3.takeDamageRangeGear = NumberRange.new(30, 120);
tbl_3.takeDamageFormula = function(a1)
    --[[
      name: takeDamageFormula
      line: 275
    ]]
    if (a1 ~= 0 and a1 ~= 1) then
        return (math.clamp((math.exp(4 * a1) - 1) / 53.598150033144236, 0, 1));
    end;
    return a1;
end;
tbl_upv_1.collisionDamage = tbl_3;
local u12 = Vector3.new(0, 0, 0);
local function alphaFromTau_1(a1, a2)
    --[[
      name: alphaFromTau
      line: 303
    ]]
    if (a2 > 0) then
        return 1 - math.exp(-a1 / a2);
    end;
    return 1;
end;
local function applyMouseLockSettings_1(a1)
    --[[
      name: applyMouseLockSettings
      line: 309
      upvalues:
        tbl_upv_1 (copy, index: 1)
        UserInputService_upv_1 (copy, index: 2)
    ]]
    if (not tbl_upv_1.camera.mouseLockCenter) then
        return;
    end;
    if (a1) then
        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService_upv_1.MouseIconEnabled = false;
    else
        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
        UserInputService_upv_1.MouseIconEnabled = true;
    end;
end;
local tbl_upv_4 = {};
local function lerp_1(a1, a2, a3)
    --[[
      name: lerp
      line: 371
    ]]
    return a1 + ((a2 - a1) * a3);
end;
local u13 = false;
local u14 = RaycastParams.new();
u14.FilterDescendantsInstances = {Parent_upv_1, VFX_1, Trees_1, Nodes_1, Plants_1, Animals_1};
u14.FilterType = Enum.RaycastFilterType.Exclude;
u14.RespectCanCollide = true;
local u15 = 0;
local function updateRotors_upv_1(a1)
    --[[
      name: updateRotors
      line: 382
      upvalues:
        tbl_upv_1 (copy, index: 1)
        u4 (ref,  index: 2)
        u11 (ref,  index: 3)
        RotorMotor_upv_1 (copy, index: 4)
        RotorMotor_upv_2 (copy, index: 5)
        u9 (ref,  index: 6)
        u8 (ref,  index: 7)
        RotorWash_upv_1 (copy, index: 8)
        u14 (copy, index: 9)
        u13 (ref,  index: 10)
        ReplicateEffect_upv_1 (copy, index: 11)
        u15 (ref,  index: 12)
    ]]
    local main_1 = tbl_upv_1.rotors.main;
    local tail_1 = tbl_upv_1.rotors.tail;
    local _;
    if (u4) then
        if (u11) then
            RotorMotor_upv_1.AngularVelocity = main_1.baseVelocity * a1;
            RotorMotor_upv_1.MotorMaxAcceleration = main_1.startupAccel;
            RotorMotor_upv_2.AngularVelocity = tail_1.baseVelocity * a1;
            RotorMotor_upv_2.MotorMaxAcceleration = tail_1.startupAccel;
        else
            RotorMotor_upv_1.MotorMaxAcceleration = main_1.runningAccel;
            RotorMotor_upv_2.MotorMaxAcceleration = tail_1.runningAccel;
            if (u9 == 0) then
                RotorMotor_upv_1.AngularVelocity = main_1.baseVelocity * a1;
            elseif (u9 <= 0) then
                if (u9 < 0) then
                    _ = main_1.baseVelocity;
                    RotorMotor_upv_1.AngularVelocity = _ + ((main_1.fallVelocity - _) * -u9);
                end;
            else
                _ = main_1.baseVelocity;
                RotorMotor_upv_1.AngularVelocity = _ + ((main_1.climbVelocity - _) * u9);
            end;
            if (u8 == 0) then
                RotorMotor_upv_2.AngularVelocity = tail_1.baseVelocity * a1;
            elseif (u8 <= 0) then
                if (u8 < 0) then
                    _ = tail_1.baseVelocity;
                    RotorMotor_upv_2.AngularVelocity = _ + ((tail_1.yawLeftVelocity - _) * -u8);
                end;
            else
                _ = tail_1.baseVelocity;
                RotorMotor_upv_2.AngularVelocity = _ + ((tail_1.yawRightVelocity - _) * u8);
            end;
        end;
    else
        RotorMotor_upv_1.AngularVelocity = 0;
        RotorMotor_upv_1.MotorMaxAcceleration = main_1.startupAccel;
        RotorMotor_upv_2.AngularVelocity = 0;
        RotorMotor_upv_2.MotorMaxAcceleration = tail_1.startupAccel;
    end;
    local v11 = false;
    local v12;
    v12 = nil;
    if (a1 > 0.75) then
        v12 = workspace:Raycast(RotorWash_upv_1.CFrame.Position, Vector3.new(0, -tbl_upv_1.rotorWashMaxDist, 0), u14);
        local v14 = nil;
        if (v12) then
            _ = v12.Instance;
            if (not (_:IsA("BasePart")) or not (_.Anchored)) then
                v14 = _:IsA("Terrain");
                if (not (v14)) then
                    if (not (u13) or v11) then
                        if (v11 and v12) then
                            _ = v12.Position;
                            local Normal_1 = v12.Normal;
                            ReplicateEffect_upv_1:FireServer("RotorWash", true, {_.X, _.Y, _.Z}, {Normal_1.X, Normal_1.Y, Normal_1.Z});
                        end;
                    else
                        ReplicateEffect_upv_1:FireServer("RotorWash", false);
                    end;
                    u13 = v11;
                    if (os.clock() - u15 > 3) then
                        _ = a1;
                    else
                        _ = 1;
                    end;
                    ReplicateEffect_upv_1:FireServer("EngineSound", _ + (u9 * 0.05), (_ + (u9 * 0.1)) * 2.25);
                    return;
                end;
            end;
            v11 = (v12.Distance <= tbl_upv_1.rotorWashMaxDist) and true;
        end;
    end;
    if (not (u13) or v11) then
        if (v11 and v12) then
            _ = v12.Position;
            local Normal_1 = v12.Normal;
            ReplicateEffect_upv_1:FireServer("RotorWash", true, {_.X, _.Y, _.Z}, {Normal_1.X, Normal_1.Y, Normal_1.Z});
        end;
    else
        ReplicateEffect_upv_1:FireServer("RotorWash", false);
    end;
    u13 = v11;
    if (os.clock() - u15 > 3) then
        local v13;
        _ = a1;
    else
        local v13;
        _ = 1;
    end;
    ReplicateEffect_upv_1:FireServer("EngineSound", _ + (u9 * 0.05), (_ + (u9 * 0.1)) * 2.25);
end;
local function getDmgAtVelDiff_1(a1, a2)
    --[[
      name: getDmgAtVelDiff
      line: 454
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v15 = nil;
    if (a1 == a1) then
        local collisionDamage_1 = tbl_upv_1.collisionDamage;
        local takeDamageFormula_1 = collisionDamage_1.takeDamageFormula;
        local v16 = (a2 and (collisionDamage_1.takeDamageRangeGear)) or (collisionDamage_1.takeDamageRange);
        local Min_1 = v16.Min;
        local Max_1 = v16.Max;
        v15 = Max_1 - Min_1;
        if (v15 ~= 0) then
            return (takeDamageFormula_1(math.clamp((a1 - Min_1) / v15, 0, 1)));
        elseif (Max_1 > a1) then
            return 0;
        else
            return 1;
        end;
    end;
    return 0;
end;
local tbl_upv_5 = {};
local function applyDeadzone_1(a1, a2)
    --[[
      name: applyDeadzone
      line: 579
    ]]
    if (math.abs(a1) > a2) then
        return a1;
    end;
    return 0;
end;
local u16 = nil;
local u17 = os.clock();
local function stepController_upv_1(a1)
    --[[
      name: stepController
      line: 587
      upvalues:
        Value_upv_1 (copy, index: 1)
        u3 (copy, index: 2)
        u2 (copy, index: 3)
        UserInputService_upv_1 (copy, index: 4)
        u10 (copy, index: 5)
        u8 (ref,  index: 6)
        u9 (ref,  index: 7)
        Parent_upv_1 (copy, index: 8)
        tbl_upv_1 (copy, index: 9)
        u4 (ref,  index: 10)
        u11 (ref,  index: 11)
        ReplicateEffect_upv_1 (copy, index: 12)
        u5 (ref,  index: 13)
        u15 (ref,  index: 14)
        u16 (ref,  index: 15)
        u17 (ref,  index: 16)
        TweenService_upv_1 (copy, index: 17)
        updateRotors_upv_1 (copy, index: 18)
        Blades_upv_1 (copy, index: 19)
        Blades_upv_2 (copy, index: 20)
        u1 (ref,  index: 21)
        SettingsModule_upv_1 (copy, index: 22)
        u6 (ref,  index: 23)
        u7 (ref,  index: 24)
        u12 (ref,  index: 25)
        Gravity_upv_1 (copy, index: 26)
    ]]
    if (not Value_upv_1 or not Value_upv_1.Parent) then
        return;
    end;
    if (u3.Parent) then
        local v17, v18 = nil, nil;
        if (u2.Parent) then
            pcall(
                function()
                    --[[
                      line: 591
                      upvalues:
                        UserInputService_upv_1 (copy, index: 1)
                        u10 (copy, index: 2)
                        u8 (ref,  index: 3)
                        u9 (ref,  index: 4)
                    ]]
                    for _, value_3 in UserInputService_upv_1:GetGamepadState(Enum.UserInputType.Gamepad1) do
                        local v19, v20 = nil, nil;
                        local v21, v22 = nil, nil;
                        if (value_3.KeyCode == Enum.KeyCode.Thumbstick1) then
                            v21 = value_3.Position.X;
                            v22 = value_3.Position.Y;
                            v19 = math.abs(v21);
                            v20 = (u10 and (u10:GetAttribute("JoystickDeadzone"))) or 0.225;
                            if (v20 < v19) then
                                u8 = v21;
                            end;
                            v19 = math.abs(v22);
                            v20 = (u10 and (u10:GetAttribute("JoystickDeadzone"))) or 0.225;
                            if (v20 < v19) then
                                u9 = ((v22 <= 0) and -1) or 1;
                            end;
                            return;
                        end;
                    end;
                end
            );
            v17 = Parent_upv_1:GetAttribute("HasFuel");
            local engineStartupTime_1 = tbl_upv_1.engineStartupTime;
            local v23 = 1;
            if (v17) then
                if (u4) then
                    if (u11) then
                        u5 = u5 + a1;
                        v23 = math.clamp(u5 / engineStartupTime_1, 0, 1);
                        if (engineStartupTime_1 <= u5) then
                            u11 = false;
                            u5 = 0;
                        end;
                    end;
                    if (tbl_upv_1.maxAltitude < Value_upv_1.CFrame.Position.Y) then
                        v23 = v23 * tbl_upv_1.maxAltEnginePowerMul;
                        u15 = os.clock();
                    end;
                else
                    if (u9 > 0.5) then
                        u4 = true;
                        u11 = true;
                        ReplicateEffect_upv_1:FireServer("StartupSound");
                    end;
                    return;
                end;
            elseif (tbl_upv_1.maxAltitude < Value_upv_1.CFrame.Position.Y) then
                v23 = v23 * tbl_upv_1.maxAltEnginePowerMul;
                u15 = os.clock();
            end;
            v18 = Parent_upv_1:GetAttribute("Health");
            if (v18 == 0) then
                v23 = 0;
            elseif (v17) then
                u16 = nil;
                local v24 = nil;
                for _, value_4 in pairs(tbl_upv_1.healthPenalties) do
                    v24 = value_4.healthRange;
                    if (v24.Min > v18) then
                        continue;
                    end;
                    if (v18 <= v24.Max) then
                        v23 = v23 * value_4.enginePowerMul;
                    end;
                end;
            else
                if (not (u16)) then
                    ReplicateEffect_upv_1:FireServer("Shutoff");
                    u17 = os.clock();
                    local v25;
                    if ((u4) and (u11)) then
                        v25 = math.clamp(u5 / engineStartupTime_1, 0, 1);
                    else
                        v25 = (u4 and 1) or 0;
                    end;
                    u16 = v25;
                end;
                v23 = math.clamp(u16 - TweenService_upv_1:GetValue((os.clock() - (u17 or 0)) / tbl_upv_1.engineShutoffTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 0, 1);
                u4 = false;
                u5 = 0;
            end;
            updateRotors_upv_1(v23);
            local v26 = math.clamp(a1, 0.004166666666666667, 0.03333333333333333);
            local v27 = Value_upv_1.AssemblyMass + (Blades_upv_1.Mass + Blades_upv_2.Mass);
            local CFrame_1 = Value_upv_1.CFrame;
            local v28 = 0;
            local v29 = 0;
            if (UserInputService_upv_1.MouseEnabled and u1) then
                local v30 = nil;
                if (u1.Parent) then
                    local Parent_2 = u1.Parent;
                    v30 = Parent_2:FindFirstChild("CameraController");
                    if (v30) then
                        v30 = Parent_2.CameraController:GetAttribute("ViewmodelCFrame");
                        if (not v30) then
                            v30 = UserInputService_upv_1:GetMouseDelta();
                            v28, v29 = v30.X, v30.Y;
                        end;
                    end;
                end;
            end;
            local v31 = SettingsModule_upv_1.GetSetting("Controls", "Vehicle Sensitivity");
            local v32 = v28 * v31;
            local v33, v33;
            v33 = tbl_upv_1.mouse.invertPitch and -v29 or v29;
            local v34 = v33 * v31;
            if (math.abs(v32) <= tbl_upv_1.mouse.deadzone) then
                local u18 = 0;
            end;
            local u18;
            local v35 = math.clamp(u18, -tbl_upv_1.mouse.maxAbs, tbl_upv_1.mouse.maxAbs);
            if (math.abs(v34) > tbl_upv_1.mouse.deadzone) then
                u18 = v34;
            else
                u18 = 0;
            end;
            local v36 = math.clamp(u18, -tbl_upv_1.mouse.maxAbs, tbl_upv_1.mouse.maxAbs);
            local u19 = 0;
            u18 = 0;
            pcall(
                function()
                    --[[
                      line: 701
                      upvalues:
                        UserInputService_upv_1 (copy, index: 1)
                        u10 (copy, index: 2)
                        u19 (ref,  index: 3)
                        u18 (ref,  index: 4)
                    ]]
                    for _, value_5 in UserInputService_upv_1:GetGamepadState(Enum.UserInputType.Gamepad1) do
                        local v37, v38 = nil, nil;
                        local v39, v40 = nil, nil;
                        if (value_5.KeyCode == Enum.KeyCode.Thumbstick2) then
                            v39 = value_5.Position.X;
                            v40 = value_5.Position.Y;
                            v37 = math.abs(v39);
                            v38 = (u10 and (u10:GetAttribute("JoystickDeadzone"))) or 0.225;
                            if (v38 < v37) then
                                u19 = v39;
                            end;
                            v37 = math.abs(v40);
                            v38 = (u10 and (u10:GetAttribute("JoystickDeadzone"))) or 0.225;
                            if (v38 < v37) then
                                u18 = -v40;
                            end;
                            return;
                        end;
                    end;
                end
            );
            local v41 = SettingsModule_upv_1.GetSetting("Gamepad", "Mouse Sensitivity");
            u19 = u19 * v41;
            u18 = u18 * v41;
            local v42 = math.clamp(v35 + u19, -1, 1);
            local v43 = math.clamp(v36 + u18, -1, 1);
            local v44 = math.clamp(u6 + v42, -1, 1);
            local v45 = Vector3.new(-math.clamp(u7 + v43, -1, 1) * tbl_upv_1.cmdRate.X, 0, -v44 * tbl_upv_1.cmdRate.Z);
            if (tbl_upv_1.autoLevelRoll and (not (tbl_upv_1.rollLevelOnlyWhenNoInput) or v44 == 0)) then
                local _, v58, v46 = CFrame_1:ToOrientation();
                v45 = v45 + Vector3.new(0, 0, -tbl_upv_1.rollLevelRateGain * v46);
            end;
            local v47 = ((not (tbl_upv_1.yawRelativeToWorld)) and (v45 + Vector3.new(0, -u8 * tbl_upv_1.cmdRate.Y, 0))) or (CFrame_1:VectorToObjectSpace(CFrame_1:VectorToWorldSpace(v45) + ((-u8 * tbl_upv_1.cmdRate.Y) * Vector3.new(0, 1, 0))));
            local cmdSmoothingTau_1 = tbl_upv_1.cmdSmoothingTau;
            local v48 = ((cmdSmoothingTau_1 > 0) and (1 - math.exp(-v26 / cmdSmoothingTau_1))) or 1;
            local v49 = u12:Lerp(v47, v48);
            local v50 = Vector3.new(tbl_upv_1.maxTorquePerMass.X * v27, tbl_upv_1.maxTorquePerMass.Y * v27, tbl_upv_1.maxTorquePerMass.Z * v27);
            local v51 = math.max(v50.X, v50.Y, v50.Z);
            u3.AngularVelocity = v49 * v23;
            u3.MaxTorque = math.max(1, v51 * v23);
            local v52 = CFrame_1:VectorToObjectSpace(Value_upv_1.AssemblyLinearVelocity);
            local v53 = v27 * Gravity_upv_1;
            local v54 = ((tbl_upv_1.pitchTiltCompensation) and (v53 / math.max(math.abs(math.cos(({CFrame_1:ToOrientation()})[1])), tbl_upv_1.tiltCompMinCos))) or v53;
            local v55 = math.max(0, v54 + (((v27 * Gravity_upv_1) * tbl_upv_1.collectiveAuthority) * u9)) * v23;
            local v56 = tbl_upv_1.planarDragPerMass * v27;
            local v57 = Vector3.new(-v52.X * v56, -v52.Y * (tbl_upv_1.verticalDragPerMass * v27), -v52.Z * v56) * v23;
            u2.Force = Vector3.new(0, v55, 0) + v57;
        end;
    end;
end;
local function enableFirstPersonCamera_1(a1)
    --[[
      name: enableFirstPersonCamera
      line: 326
      upvalues:
        CurrentCamera_upv_1 (copy, index: 1)
        tbl_upv_4 (copy, index: 2)
        tbl_upv_1 (copy, index: 3)
        UserInputService_upv_1 (copy, index: 4)
        RunService_upv_1 (copy, index: 5)
        Value_upv_1 (copy, index: 6)
    ]]
    if (not CurrentCamera_upv_1) then
        return;
    end;
    if (a1) then
        tbl_upv_4.camType = CurrentCamera_upv_1.CameraType;
        tbl_upv_4.fov = CurrentCamera_upv_1.FieldOfView;
        CurrentCamera_upv_1.CameraType = Enum.CameraType.Scriptable;
        if (tbl_upv_1.camera.mouseLockCenter) then
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
            UserInputService_upv_1.MouseIconEnabled = false;
        end;
        RunService_upv_1:UnbindFromRenderStep("FlycopterCam");
        RunService_upv_1:BindToRenderStep(
            "FlycopterCam",
            Enum.RenderPriority.Camera.Value + 1,
            function(a2)
                --[[
                  line: 341
                  upvalues:
                    Value_upv_1 (copy, index: 1)
                    RunService_upv_1 (copy, index: 2)
                    tbl_upv_1 (copy, index: 3)
                    CurrentCamera_upv_1 (copy, index: 4)
                ]]
                if (Value_upv_1 and Value_upv_1.Parent) then
                    CurrentCamera_upv_1.CFrame = Value_upv_1.CFrame * CFrame.new(tbl_upv_1.camera.offsetLocal);
                else
                    RunService_upv_1:UnbindFromRenderStep("FlycopterCam");
                end;
            end
        );
    else
        CurrentCamera_upv_1.CameraType = tbl_upv_4.camType or (Enum.CameraType.Custom);
        RunService_upv_1:UnbindFromRenderStep("FlycopterCam");
    end;
end;
enableFirstPersonCamera_1(tbl_upv_1.camera.enableFirstPerson);
local function calculateCollisions_upv_1(a1)
    --[[
      name: calculateCollisions
      line: 474
      upvalues:
        VehicleSeat_upv_1 (copy, index: 1)
        PassengerSeat1_upv_1 (copy, index: 2)
        Parent_upv_1 (copy, index: 3)
        tbl_upv_1 (copy, index: 4)
        tbl_upv_5 (copy, index: 5)
        Colliders_upv_1 (copy, index: 6)
        Gear_upv_1 (copy, index: 7)
        ReplicateEffect_upv_1 (copy, index: 8)
        ReplicateHealth_upv_1 (copy, index: 9)
    ]]
    local v58 = OverlapParams.new();
    v58.FilterDescendantsInstances = {Parent_upv_1, VehicleSeat_upv_1, PassengerSeat1_upv_1};
    v58.FilterType = Enum.RaycastFilterType.Exclude;
    v58.RespectCanCollide = true;
    local takeDamageCooldown_1 = tbl_upv_1.collisionDamage.takeDamageCooldown;
    local value_6 = nil;
    for key_1, value_6 in tbl_upv_5 do
        value_6 = value_6 + a1;
        if (takeDamageCooldown_1 > value_6) then
            tbl_upv_5[key_1] = value_6;
        else
            tbl_upv_5[key_1] = nil;
        end;
    end;
    local tbl_6 = {};
    if (os.clock() - 0 >= 10) then
        table.clear(tbl_6);
        for _, value_7 in Parent_upv_1:GetDescendants() do
            if (not (value_7:IsA("BasePart"))) then
                continue;
            end;
            if (value_7.CanCollide or value_7:IsDescendantOf(Colliders_upv_1)) then
                table.insert(tbl_6, value_7);
            end;
        end;
    end;
    local key_1 = false;
    key_1 = nil;
    local v59 = nil;
    local v60 = nil;
    local v61 = nil;
    local value_8 = nil;
    local v62 = nil;
    local v63 = nil;
    local v64 = nil;
    local v65 = nil;
    local v66 = nil;
    local v67 = nil;
    local v68 = nil;
    for _, value_8 in tbl_6 do
        if (not (value_8.Parent) or tbl_upv_5[value_8]) then
            continue;
        end;
        v59 = value_8.AssemblyLinearVelocity;
        v60 = value_8.AssemblyMass;
        v61 = workspace:GetPartsInPart(value_8, v58);
        if (table.find(value_8:GetTouchingParts(), workspace.Terrain)) then
            table.insert(v61, workspace.Terrain);
        end;
        v64 = nil;
        for v70, value_9 in v61 do
            v62 = Vector3.new();
            v63 = 0;
            if ((value_9:IsA("BasePart")) and (value_9.CanCollide)) then
                v62, v63 = value_9.AssemblyLinearVelocity, value_9.AssemblyMass;
            else
                v68 = value_9:IsA("Terrain");
                if (v68) then
                    v62, v63 = Vector3.new(), math.huge;
                end;
            end;
            v64 = (v59 - v62).Magnitude * math.min((v63 / v60) / 2, 1);
            v66 = value_8:IsDescendantOf(Gear_upv_1);
            if (v66 and tbl_upv_1.gearSoundLandMinVelocity <= v64 and not (tbl_upv_5.GearSound)) then
                tbl_upv_5.GearSound = 0;
                ReplicateEffect_upv_1:FireServer("GearSound");
            end;
            if (v64 == v64) then
                local collisionDamage_2 = tbl_upv_1.collisionDamage;
                local takeDamageFormula_2 = collisionDamage_2.takeDamageFormula;
                local v69 = (v66 and (collisionDamage_2.takeDamageRangeGear)) or (collisionDamage_2.takeDamageRange);
                local Min_2 = v69.Min;
                local Max_2 = v69.Max;
                v67 = Max_2 - Min_2;
                if (v67 ~= 0) then
                    v65 = takeDamageFormula_2(math.clamp((v64 - Min_2) / v67, 0, 1));
                else
                    v65 = ((Max_2 > v64) and 0) or 1;
                end;
            else
                v65 = 0;
            end;
            if (v65 <= 0) then
                continue;
            end;
            tbl_upv_5[value_8] = 0;
            if (not (key_1)) then
                ReplicateEffect_upv_1:FireServer("CrashSound");
                key_1 = true;
            end;
            ReplicateHealth_upv_1:FireServer("TakeDamage", v65 * Parent_upv_1:GetAttribute("MaxHealth"));
        end;
    end;
end;
local u20 = RunService_upv_1.Stepped:Connect(
    function(a1, a2)
        --[[
          line: 802
          upvalues:
            stepController_upv_1 (copy, index: 1)
            calculateCollisions_upv_1 (copy, index: 2)
        ]]
        stepController_upv_1(a2);
        calculateCollisions_upv_1(a2);
    end
);
local v71 = RunService_upv_1.RenderStepped:Connect(
    function(a1)
        --[[
          line: 807
          upvalues:
            calculateCollisions_upv_1 (copy, index: 1)
        ]]
        calculateCollisions_upv_1(a1);
    end
);
local function cleanup_upv_1()
    --[[
      name: cleanup
      line: 812
      upvalues:
        u20 (ref,  index: 1)
        CurrentCamera_upv_1 (copy, index: 2)
        tbl_upv_4 (copy, index: 3)
        RunService_upv_1 (copy, index: 4)
        ContextActionService_upv_1 (copy, index: 5)
        u3 (copy, index: 6)
        u2 (copy, index: 7)
    ]]
    if (u20) then
        u20:Disconnect();
        u20 = nil;
    end;
    if (CurrentCamera_upv_1) then
        CurrentCamera_upv_1.CameraType = tbl_upv_4.camType or (Enum.CameraType.Custom);
        RunService_upv_1:UnbindFromRenderStep("FlycopterCam");
    end;
    ContextActionService_upv_1:UnbindAction("ThrottleUp");
    ContextActionService_upv_1:UnbindAction("ThrottleDown");
    ContextActionService_upv_1:UnbindAction("YawRight");
    ContextActionService_upv_1:UnbindAction("YawLeft");
    if (u3) then
        u3:Destroy();
    end;
    if (u2) then
        u2:Destroy();
    end;
    script:Destroy();
end;
VehicleSeat_upv_1:GetPropertyChangedSignal("Occupant"):Connect(
    function()
        --[[
          line: 838
          upvalues:
            VehicleSeat_upv_1 (copy, index: 1)
            cleanup_upv_1 (copy, index: 2)
        ]]
        if (VehicleSeat_upv_1.Occupant ~= nil) then
            return;
        end;
        cleanup_upv_1();
    end
);
local Character_1 = Players_1.LocalPlayer.Character;
if (Character_1) then
    local v70 = Character_1:FindFirstChildOfClass("Humanoid");
    if (v70) then
        v70.Died:Connect(
            function()
                --[[
                  line: 851
                  upvalues:
                    cleanup_upv_1 (copy, index: 1)
                ]]
                cleanup_upv_1();
            end
        );
    end;
end;
Value_upv_1.AncestryChanged:Connect(
    function(a1, a2)
        --[[
          line: 858
          upvalues:
            cleanup_upv_1 (copy, index: 1)
        ]]
        if (a2 ~= nil) then
            return;
        end;
        cleanup_upv_1();
    end
);