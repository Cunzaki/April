-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local RunService = game:GetService("RunService");
local ContextActionService = game:GetService("ContextActionService");
game:GetService("Workspace");
local UserInputService = game:GetService("UserInputService");
local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local LocalPlayer = Players.LocalPlayer;
local CurrentCamera = workspace.CurrentCamera;
assert(LocalPlayer and CurrentCamera, "This script must run as a LocalScript on the client (accesses camera and input).");
local Plane = script:FindFirstChild("Plane");
assert(Plane, "Missing ObjectValue \'Plane\' under script. Set it to the engine BasePart.");
local Value = Plane.Value;
local v1;

if Value then
    v1 = Value:IsA("BasePart");
else
    v1 = Value;
end;

assert(v1, "Plane.Value must be a BasePart (the helicopter’s main body/engine part).");
local Parent = Value.Parent;
local VehicleSeat = Parent:FindFirstChild("VehicleSeat");
local PassengerSeat1 = Parent:FindFirstChild("PassengerSeat1");
local Gear = Parent:FindFirstChild("Gear");
local Colliders = Parent:FindFirstChild("Colliders");
local MainRotor = Parent:FindFirstChild("MainRotor");
local Spinner = MainRotor:FindFirstChild("Spinner");
local Blades = MainRotor:FindFirstChild("Blades");
local RotorMotor = Spinner:FindFirstChild("RotorMotor");
local TailRotor = Parent:FindFirstChild("TailRotor");
local Spinner2 = TailRotor:FindFirstChild("Spinner");
local Blades2 = TailRotor:FindFirstChild("Blades");
local RotorMotor2 = Spinner2:FindFirstChild("RotorMotor");
local u2 = nil;
RotorMotor.AngularVelocity = 0;
RotorMotor2.AngularVelocity = 0;
local Events = Parent:FindFirstChild("Events");
local ReplicateEffect = Events:FindFirstChild("ReplicateEffect");
local ReplicateHealth = Events:FindFirstChild("ReplicateHealth");
local RotorWash = Parent:FindFirstChild("VFX"):FindFirstChild("RotorWash");
local VFX = workspace:WaitForChild("VFX");
local Trees = workspace:WaitForChild("Trees");
local Nodes = workspace:WaitForChild("Nodes");
local Plants = workspace:WaitForChild("Plants");
local Animals = workspace:WaitForChild("Animals");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));

local function getOrCreateAttachment(p3, p4) -- Line: 63
    local v5 = p3:FindFirstChild(p4);

    if v5 and v5:IsA("Attachment") then
        return v5;
    end;

    local Attachment = Instance.new("Attachment");
    Attachment.Name = p4;
    Attachment.Parent = p3;

    return Attachment;
end;

local function getOrCreateVectorForce(p6, p7) -- Line: 72
    for _, child in ipairs(p6:GetChildren()) do
        if child:IsA("VectorForce") then
            child.Name = p7;

            return child;
        end;
    end;

    local VectorForce = Instance.new("VectorForce");
    VectorForce.Name = p7;
    VectorForce.Parent = p6;

    return VectorForce;
end;

local function getOrCreateAngularVelocity(p8, p9) -- Line: 85
    for _, child in ipairs(p8:GetChildren()) do
        if child:IsA("AngularVelocity") then
            child.Name = p9;

            return child;
        end;
    end;

    local AngularVelocity = Instance.new("AngularVelocity");
    AngularVelocity.Name = p9;
    AngularVelocity.Parent = p8;

    return AngularVelocity;
end;

local EngineAttachment = Value:FindFirstChild("EngineAttachment");

if not (EngineAttachment and EngineAttachment:IsA("Attachment")) then
    EngineAttachment = Instance.new("Attachment");
    EngineAttachment.Name = "EngineAttachment";
    EngineAttachment.Parent = Value;
end;

local u10 = getOrCreateVectorForce(Value, "EngineVectorForce");
u10.Attachment0 = EngineAttachment;
u10.ApplyAtCenterOfMass = true;
u10.RelativeTo = Enum.ActuatorRelativeTo.Attachment0;
local u11 = getOrCreateAngularVelocity(Value, "EngineAngularVelocity");
u11.Attachment0 = EngineAttachment;
u11.RelativeTo = Enum.ActuatorRelativeTo.Attachment0;
u11.ReactionTorqueEnabled = false;
local u12 = false;
local u13 = false;
local u14 = 0;
local u15 = 0;
local u16 = 0;
local u17 = 0;
local u18 = 0;
local u19 = LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("PreferredInputController") or LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController", 5);

local function getDeadzone() -- Line: 119
    -- upvalues: u19 (copy)
    return u19 and u19:GetAttribute("JoystickDeadzone") or 0.225;
end;

local function handleAction(p20, p21) -- Line: 132
    -- upvalues: u18 (ref), u17 (ref), u16 (ref), u15 (ref)
    local v22 = p21 == Enum.UserInputState.Begin;
    local v23 = p21 == Enum.UserInputState.End;

    if p20 == "ThrottleUp" then
        if v22 then
            u18 = 1;

            return;
        end;

        if v23 and u18 == 1 then
            u18 = 0;
        end;
    elseif p20 == "ThrottleDown" then
        if v22 then
            u18 = -1;

            return;
        end;

        if v23 and u18 == -1 then
            u18 = 0;
        end;
    elseif p20 == "YawRight" then
        if v22 then
            u17 = 1;

            return;
        end;

        if v23 and u17 == 1 then
            u17 = 0;
        end;
    elseif p20 == "YawLeft" then
        if v22 then
            u17 = -1;

            return;
        end;

        if v23 and u17 == -1 then
            u17 = 0;
        end;
    elseif p20 == "PitchUp" then
        if v22 then
            u16 = 1;

            return;
        end;

        if v23 and u16 == 1 then
            u16 = 0;
        end;
    elseif p20 == "PitchDown" then
        if v22 then
            u16 = -1;

            return;
        end;

        if v23 and u16 == -1 then
            u16 = 0;
        end;
    elseif p20 == "RollRight" then
        if v22 then
            u15 = 1;

            return;
        end;

        if v23 and u15 == 1 then
            u15 = 0;
        end;
    elseif p20 == "RollLeft" then
        if v22 then
            u15 = -1;

            return;
        end;

        if v23 and u15 == -1 then
            u15 = 0;
        end;
    end;
end;

ContextActionService:BindAction("ThrottleUp", handleAction, false, Enum.KeyCode.W);
ContextActionService:BindAction("ThrottleDown", handleAction, false, Enum.KeyCode.S);
ContextActionService:BindAction("YawRight", handleAction, false, Enum.KeyCode.D);
ContextActionService:BindAction("YawLeft", handleAction, false, Enum.KeyCode.A);
local Gravity = workspace.Gravity;
local u26 = {
    cmdRate = Vector3.new(0.7853982, 0.6981317, 1.0471976),
    cmdSmoothingTau = 1,
    autoLevelRoll = false,
    rollLevelRateGain = 0.5235987755982988,
    rollLevelOnlyWhenNoInput = true,
    maxTorquePerMass = Vector3.new(250, 220, 260),
    collectiveAuthority = 0.08,
    pitchTiltCompensation = false,
    tiltCompMinCos = 0.3,
    planarDragPerMass = 1.8,
    verticalDragPerMass = 0.8,
    yawRelativeToWorld = true,
    engineStartupTime = 5,
    engineShutoffTime = 6,
    maxAltitude = 400,
    maxAltEnginePowerMul = 0.9,
    rotorWashMaxDist = 60,
    gearSoundLandMinVelocity = 5,
    mouse = {
        sensitivity = 0.3,
        invertPitch = true,
        deadzone = 0.0015,
        maxAbs = 1
    },
    camera = {
        enableFirstPerson = true,
        offsetLocal = Vector3.new(0, 1.1, -2.6),
        mouseLockCenter = true
    },
    rotors = {
        main = {
            fallVelocity = 20,
            baseVelocity = 30,
            climbVelocity = 40,
            startupAccel = 3,
            runningAccel = 6
        },
        tail = {
            yawRightVelocity = -40,
            baseVelocity = -15,
            yawLeftVelocity = 15,
            startupAccel = 2,
            runningAccel = 12
        }
    },
    healthPenalties = {
        {
            enginePowerMul = 0.98,
            healthRange = NumberRange.new(0, 50)
        },
        {
            enginePowerMul = 0.98,
            healthRange = NumberRange.new(0, 25)
        }
    },
    collisionDamage = {
        takeDamageCooldown = 1,
        takeDamageRange = NumberRange.new(10, 50),
        takeDamageRangeGear = NumberRange.new(30, 120),

        takeDamageFormula = function(p24) -- Line: 275, Name: takeDamageFormula
            if p24 == 0 or p24 == 1 then
                return p24;
            end;

            local v25 = (math.exp(4 * p24) - 1) / 53.598150033144236;

            return math.clamp(v25, 0, 1);
        end
    }
};
local u27 = Vector3.new(0, 0, 0);

local function alphaFromTau(p28, p29) -- Line: 303
    return p29 <= 0 and 1 or 1 - math.exp(-p28 / p29);
end;

local function applyMouseLockSettings(p30) -- Line: 309
    -- upvalues: u26 (copy), UserInputService (copy)
    if not u26.camera.mouseLockCenter then
        return;
    end;

    if p30 then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;

        return;
    end;

    UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
    UserInputService.MouseIconEnabled = true;
end;

local u31 = {
    camType = nil,
    fov = nil
};

local function lerp(p32, p33, p34) -- Line: 371
    return p32 + (p33 - p32) * p34;
end;

local u35 = false;
local u36 = RaycastParams.new();
u36.FilterDescendantsInstances = {
    Parent,
    VFX,
    Trees,
    Nodes,
    Plants,
    Animals
};
u36.FilterType = Enum.RaycastFilterType.Exclude;
u36.RespectCanCollide = true;
local u37 = 0;

local function updateRotors(p38) -- Line: 382
    -- upvalues: u26 (copy), u12 (ref), u13 (ref), RotorMotor (copy), RotorMotor2 (copy), u18 (ref), u17 (ref), RotorWash (copy), u36 (copy), u35 (ref), ReplicateEffect (copy), u37 (ref)
    local main = u26.rotors.main;
    local tail = u26.rotors.tail;

    if u12 then
        if u13 then
            RotorMotor.AngularVelocity = main.baseVelocity * p38;
            RotorMotor.MotorMaxAcceleration = main.startupAccel;
            RotorMotor2.AngularVelocity = tail.baseVelocity * p38;
            RotorMotor2.MotorMaxAcceleration = tail.startupAccel;
        else
            RotorMotor.MotorMaxAcceleration = main.runningAccel;
            RotorMotor2.MotorMaxAcceleration = tail.runningAccel;

            if u18 == 0 then
                RotorMotor.AngularVelocity = main.baseVelocity * p38;
            elseif u18 > 0 then
                local baseVelocity = main.baseVelocity;
                RotorMotor.AngularVelocity = baseVelocity + (main.climbVelocity - baseVelocity) * u18;
            elseif u18 < 0 then
                local baseVelocity = main.baseVelocity;
                RotorMotor.AngularVelocity = baseVelocity + (main.fallVelocity - baseVelocity) * -u18;
            end;

            if u17 == 0 then
                RotorMotor2.AngularVelocity = tail.baseVelocity * p38;
            elseif u17 > 0 then
                local baseVelocity = tail.baseVelocity;
                RotorMotor2.AngularVelocity = baseVelocity + (tail.yawRightVelocity - baseVelocity) * u17;
            elseif u17 < 0 then
                local baseVelocity = tail.baseVelocity;
                RotorMotor2.AngularVelocity = baseVelocity + (tail.yawLeftVelocity - baseVelocity) * -u17;
            end;
        end;
    else
        RotorMotor.AngularVelocity = 0;
        RotorMotor.MotorMaxAcceleration = main.startupAccel;
        RotorMotor2.AngularVelocity = 0;
        RotorMotor2.MotorMaxAcceleration = tail.startupAccel;
    end;

    local v39 = false;
    local v40;

    if p38 > 0.75 then
        v40 = workspace:Raycast(RotorWash.CFrame.Position, Vector3.new(0, -u26.rotorWashMaxDist, 0), u36);

        if v40 then
            local Instance2 = v40.Instance;

            if Instance2:IsA("BasePart") and Instance2.Anchored or Instance2:IsA("Terrain") then
                if v40.Distance <= u26.rotorWashMaxDist then
                    v39 = true;
                end;
            end;
        end;
    else
        v40 = nil;
    end;

    if u35 and not v39 then
        ReplicateEffect:FireServer("RotorWash", false);
    elseif v39 and v40 then
        local Position = v40.Position;
        local Normal = v40.Normal;
        ReplicateEffect:FireServer("RotorWash", true, { Position.X, Position.Y, Position.Z }, { Normal.X, Normal.Y, Normal.Z });
    end;

    u35 = v39;
    local v41 = os.clock() - u37 <= 3 and 1 or p38;
    ReplicateEffect:FireServer("EngineSound", v41 + u18 * 0.05, (v41 + u18 * 0.1) * 2.25);
end;

local function getDmgAtVelDiff(p42, p43) -- Line: 454
    -- upvalues: u26 (copy)
    if p42 ~= p42 then
        return 0;
    end;

    local collisionDamage = u26.collisionDamage;
    local v44 = p43 and collisionDamage.takeDamageRangeGear or collisionDamage.takeDamageRange;
    local Min = v44.Min;
    local Max = v44.Max;
    local v45 = Max - Min;

    return v45 == 0 and (Max <= p42 and 1 or 0) or collisionDamage.takeDamageFormula((math.clamp((p42 - Min) / v45, 0, 1)));
end;

local u46 = {};

local function calculateCollisions(p47) -- Line: 474
    -- upvalues: VehicleSeat (copy), PassengerSeat1 (copy), Parent (copy), u26 (copy), u46 (copy), Colliders (copy), Gear (copy), ReplicateEffect (copy), ReplicateHealth (copy)
    local v48 = VehicleSeat and VehicleSeat.Occupant and VehicleSeat.Occupant.Parent;
    local v49 = PassengerSeat1 and PassengerSeat1.Occupant and PassengerSeat1.Occupant.Parent;
    local v50 = OverlapParams.new();
    v50.FilterDescendantsInstances = { Parent, v48, v49 };
    v50.FilterType = Enum.RaycastFilterType.Exclude;
    v50.RespectCanCollide = true;
    local takeDamageCooldown = u26.collisionDamage.takeDamageCooldown;

    for i, v in u46 do
        local v51 = v + p47;

        if takeDamageCooldown <= v51 then
            u46[i] = nil;
        else
            u46[i] = v51;
        end;
    end;

    local v52 = {};

    if os.clock() - 0 >= 10 then
        table.clear(v52);

        for _, descendant in Parent:GetDescendants() do
            if descendant:IsA("BasePart") and (descendant.CanCollide or descendant:IsDescendantOf(Colliders)) then
                table.insert(v52, descendant);
            end;
        end;
    end;

    local v53 = false;

    for _, v in v52 do
        if v.Parent and not u46[v] then
            local AssemblyLinearVelocity = v.AssemblyLinearVelocity;
            local AssemblyMass = v.AssemblyMass;
            local v54 = workspace:GetPartsInPart(v, v50);
            local v55 = v:GetTouchingParts();

            if table.find(v55, workspace.Terrain) then
                table.insert(v54, workspace.Terrain);
            end;

            for _, v2 in v54 do
                local v56 = Vector3.new();
                local v57 = 0;

                if v2:IsA("BasePart") and v2.CanCollide then
                    v56 = v2.AssemblyLinearVelocity;
                    v57 = v2.AssemblyMass;
                elseif v2:IsA("Terrain") then
                    v56 = Vector3.new();
                    v57 = (1 / 0);
                end;

                local v58 = (AssemblyLinearVelocity - v56).Magnitude * math.min(v57 / AssemblyMass / 2, 1);
                local v59 = v:IsDescendantOf(Gear);

                if v59 and (u26.gearSoundLandMinVelocity <= v58 and not u46.GearSound) then
                    u46.GearSound = 0;
                    ReplicateEffect:FireServer("GearSound");
                end;

                local v60;

                if v58 == v58 then
                    local collisionDamage = u26.collisionDamage;
                    local takeDamageFormula = collisionDamage.takeDamageFormula;
                    local v61 = v59 and collisionDamage.takeDamageRangeGear or collisionDamage.takeDamageRange;
                    local Min = v61.Min;
                    local Max = v61.Max;
                    local v62 = Max - Min;

                    if v62 == 0 then
                        v60 = Max <= v58 and 1 or 0;
                    else
                        v60 = takeDamageFormula((math.clamp((v58 - Min) / v62, 0, 1)));
                    end;
                else
                    v60 = 0;
                end;

                if v60 > 0 then
                    u46[v] = 0;

                    if not v53 then
                        ReplicateEffect:FireServer("CrashSound");
                        v53 = true;
                    end;

                    ReplicateHealth:FireServer("TakeDamage", v60 * Parent:GetAttribute("MaxHealth"));
                end;
            end;
        end;
    end;
end;

local function applyDeadzone(p63, p64) -- Line: 579
    return math.abs(p63) <= p64 and 0 or p63;
end;

local u65 = nil;
local u66 = os.clock();

local function stepController(p67) -- Line: 587
    -- upvalues: Value (copy), u11 (copy), u10 (copy), UserInputService (copy), u19 (copy), u17 (ref), u18 (ref), Parent (copy), u26 (copy), u12 (ref), u13 (ref), ReplicateEffect (copy), u14 (ref), u37 (ref), u65 (ref), u66 (ref), TweenService (copy), updateRotors (copy), Blades (copy), Blades2 (copy), u2 (ref), SettingsModule (copy), u15 (ref), u16 (ref), u27 (ref), Gravity (copy)
    if not (Value and (Value.Parent and (u11.Parent and u10.Parent))) then
        return;
    end;

    pcall(function() -- Line: 591
        -- upvalues: UserInputService (ref), u19 (ref), u17 (ref), u18 (ref)
        for _, v in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
            if v.KeyCode == Enum.KeyCode.Thumbstick1 then
                local X = v.Position.X;
                local Y = v.Position.Y;

                if math.abs(X) > (u19 and u19:GetAttribute("JoystickDeadzone") or 0.225) then
                    u17 = X;
                end;

                if math.abs(Y) > (u19 and u19:GetAttribute("JoystickDeadzone") or 0.225) then
                    u18 = Y > 0 and 1 or -1;

                    return;
                end;

                break;
            end;
        end;
    end);
    local v68 = Parent:GetAttribute("HasFuel");
    local engineStartupTime = u26.engineStartupTime;
    local v69 = 1;

    if v68 then
        if not u12 then
            if u18 > 0.5 then
                u12 = true;
                u13 = true;
                ReplicateEffect:FireServer("StartupSound");
            end;

            return;
        end;

        if u13 then
            u14 = u14 + p67;
            v69 = math.clamp(u14 / engineStartupTime, 0, 1);

            if engineStartupTime <= u14 then
                u13 = false;
                u14 = 0;
            end;
        end;
    end;

    if Value.CFrame.Position.Y > u26.maxAltitude then
        v69 = v69 * u26.maxAltEnginePowerMul;
        u37 = os.clock();
    end;

    local v70 = Parent:GetAttribute("Health");

    if v70 == 0 then
        v69 = 0;
    elseif v68 then
        u65 = nil;

        for _, v in pairs(u26.healthPenalties) do
            local healthRange = v.healthRange;

            if healthRange.Min <= v70 and v70 <= healthRange.Max then
                v69 = v69 * v.enginePowerMul;
            end;
        end;
    else
        if not u65 then
            ReplicateEffect:FireServer("Shutoff");
            u66 = os.clock();
            local v71;

            if u12 and u13 then
                v71 = math.clamp(u14 / engineStartupTime, 0, 1);
            else
                v71 = u12 and 1 or 0;
            end;

            u65 = v71;
        end;

        local v72 = u65 - TweenService:GetValue((os.clock() - (u66 or 0)) / u26.engineShutoffTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In);
        v69 = math.clamp(v72, 0, 1);
        u12 = false;
        u13 = false;
        u14 = 0;
    end;

    updateRotors(v69);
    local v73 = math.clamp(p67, 0.004166666666666667, 0.03333333333333333);
    local v74 = Value.AssemblyMass + (Blades.Mass + Blades2.Mass);
    local CFrame2 = Value.CFrame;
    local v75 = 0;
    local v76 = 0;

    if UserInputService.MouseEnabled and (u2 and u2.Parent) then
        local Parent2 = u2.Parent;

        if Parent2:FindFirstChild("CameraController") and not Parent2.CameraController:GetAttribute("ViewmodelCFrame") then
            local v77 = UserInputService:GetMouseDelta();
            v75 = v77.X;
            v76 = v77.Y;
        end;
    end;

    local v78 = SettingsModule.GetSetting("Controls", "Vehicle Sensitivity");
    local v79 = v75 * v78;

    if u26.mouse.invertPitch then
        v76 = -v76 or v76;
    end;

    local v80 = v76 * v78;
    local v81 = u26.mouse.deadzone >= math.abs(v79) and 0 or v79;
    local v82 = math.clamp(v81, -u26.mouse.maxAbs, u26.mouse.maxAbs);
    local v83 = u26.mouse.deadzone >= math.abs(v80) and 0 or v80;
    local v84 = math.clamp(v83, -u26.mouse.maxAbs, u26.mouse.maxAbs);
    local u85 = 0;
    local u86 = 0;
    pcall(function() -- Line: 701
        -- upvalues: UserInputService (ref), u19 (ref), u85 (ref), u86 (ref)
        for _, v in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
            if v.KeyCode == Enum.KeyCode.Thumbstick2 then
                local X = v.Position.X;
                local Y = v.Position.Y;

                if math.abs(X) > (u19 and u19:GetAttribute("JoystickDeadzone") or 0.225) then
                    u85 = X;
                end;

                if math.abs(Y) > (u19 and u19:GetAttribute("JoystickDeadzone") or 0.225) then
                    u86 = -Y;

                    return;
                end;

                break;
            end;
        end;
    end);
    local v87 = SettingsModule.GetSetting("Gamepad", "Mouse Sensitivity");
    u85 = u85 * v87;
    u86 = u86 * v87;
    local v88 = math.clamp(v82 + u85, -1, 1);
    local v89 = math.clamp(v84 + u86, -1, 1);
    local v90 = math.clamp(u15 + v88, -1, 1);
    local v91 = -math.clamp(u16 + v89, -1, 1) * u26.cmdRate.X;
    local v92 = Vector3.new(v91, 0, -v90 * u26.cmdRate.Z);

    if u26.autoLevelRoll and (not u26.rollLevelOnlyWhenNoInput or v90 == 0) then
        local _, _, v93 = CFrame2:ToOrientation();
        v92 = v92 + Vector3.new(0, 0, -u26.rollLevelRateGain * v93);
    end;

    local v94;

    if u26.yawRelativeToWorld then
        local v95 = -u17 * u26.cmdRate.Y * Vector3.new(0, 1, 0);
        v94 = CFrame2:VectorToObjectSpace(CFrame2:VectorToWorldSpace(v92) + v95);
    else
        v94 = v92 + Vector3.new(0, -u17 * u26.cmdRate.Y, 0);
    end;

    local cmdSmoothingTau = u26.cmdSmoothingTau;
    u27 = u27:Lerp(v94, cmdSmoothingTau <= 0 and 1 or 1 - math.exp(-v73 / cmdSmoothingTau));
    local v96 = Vector3.new(u26.maxTorquePerMass.X * v74, u26.maxTorquePerMass.Y * v74, u26.maxTorquePerMass.Z * v74);
    local v97 = math.max(v96.X, v96.Y, v96.Z);
    u11.AngularVelocity = u27 * v69;
    u11.MaxTorque = math.max(1, v97 * v69);
    local v98 = CFrame2:VectorToObjectSpace(Value.AssemblyLinearVelocity);
    local v99 = v74 * Gravity;

    if u26.pitchTiltCompensation then
        local v100 = { CFrame2:ToOrientation() };
        local v101 = math.cos(v100[1]);
        local v102 = math.abs(v101);
        v99 = v99 / math.max(v102, u26.tiltCompMinCos);
    end;

    local v103 = math.max(0, v99 + v74 * Gravity * u26.collectiveAuthority * u18) * v69;
    local v104 = u26.planarDragPerMass * v74;
    local v105 = Vector3.new(-v98.X * v104, -v98.Y * (u26.verticalDragPerMass * v74), -v98.Z * v104) * v69;
    u10.Force = Vector3.new(0, v103, 0) + v105;
end;

(function(p106) -- Line: 326, Name: enableFirstPersonCamera
    -- upvalues: CurrentCamera (copy), u31 (copy), u26 (copy), UserInputService (copy), RunService (copy), Value (copy)
    if not CurrentCamera then
        return;
    end;

    if not p106 then
        CurrentCamera.CameraType = u31.camType or Enum.CameraType.Custom;
        RunService:UnbindFromRenderStep("FlycopterCam");

        return;
    end;

    u31.camType = CurrentCamera.CameraType;
    u31.fov = CurrentCamera.FieldOfView;
    CurrentCamera.CameraType = Enum.CameraType.Scriptable;

    if u26.camera.mouseLockCenter then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
    end;

    RunService:UnbindFromRenderStep("FlycopterCam");
    RunService:BindToRenderStep("FlycopterCam", Enum.RenderPriority.Camera.Value + 1, function(p107) -- Line: 341
        -- upvalues: Value (ref), RunService (ref), u26 (ref), CurrentCamera (ref)
        if Value and Value.Parent then
            CurrentCamera.CFrame = Value.CFrame * CFrame.new(u26.camera.offsetLocal);

            return;
        end;

        RunService:UnbindFromRenderStep("FlycopterCam");
    end);
end)(u26.camera.enableFirstPerson);
local u110 = RunService.Stepped:Connect(function(p108, p109) -- Line: 802
    -- upvalues: stepController (copy), calculateCollisions (copy)
    stepController(p109);
    calculateCollisions(p109);
end);
RunService.RenderStepped:Connect(function(p111) -- Line: 807
    -- upvalues: calculateCollisions (copy)
    calculateCollisions(p111);
end);

local function cleanup() -- Line: 812
    -- upvalues: u110 (ref), CurrentCamera (copy), u31 (copy), RunService (copy), ContextActionService (copy), u11 (copy), u10 (copy)
    if u110 then
        u110:Disconnect();
        u110 = nil;
    end;

    if CurrentCamera then
        CurrentCamera.CameraType = u31.camType or Enum.CameraType.Custom;
        RunService:UnbindFromRenderStep("FlycopterCam");
    end;

    ContextActionService:UnbindAction("ThrottleUp");
    ContextActionService:UnbindAction("ThrottleDown");
    ContextActionService:UnbindAction("YawRight");
    ContextActionService:UnbindAction("YawLeft");

    if u11 then
        u11:Destroy();
    end;

    if u10 then
        u10:Destroy();
    end;

    script:Destroy();
end;

VehicleSeat:GetPropertyChangedSignal("Occupant"):Connect(function() -- Line: 838
    -- upvalues: VehicleSeat (copy), cleanup (copy)
    if VehicleSeat.Occupant == nil then
        cleanup();
    end;
end);
local Character = Players.LocalPlayer.Character;
local v112 = Character and Character:FindFirstChildOfClass("Humanoid");

if v112 then
    u2 = v112;
    v112.Died:Connect(function() -- Line: 851
        -- upvalues: cleanup (copy)
        cleanup();
    end);
end;

Value.AncestryChanged:Connect(function(p113, p114) -- Line: 858
    -- upvalues: cleanup (copy)
    if p114 == nil then
        cleanup();
    end;
end);