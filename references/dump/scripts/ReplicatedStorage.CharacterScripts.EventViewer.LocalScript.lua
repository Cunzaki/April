-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local TweenService = game:GetService("TweenService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local LocalPlayer = Players.LocalPlayer;
local Main = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Main");
local Notification = Main:WaitForChild("Notification");
local Map = Main:WaitForChild("Map"):WaitForChild("Frame"):WaitForChild("Map");
local TimedCrateTemplate = Map:WaitForChild("TimedCrateTemplate");
local BTRTemplate = Map:WaitForChild("BTRTemplate");
local BorisTemplate = Map:WaitForChild("BorisTemplate");
local BrutusTemplate = Map:WaitForChild("BrutusTemplate");
local BrunoTemplate = Map:WaitForChild("BrunoTemplate");
local Events = workspace:WaitForChild("Events");
local Military = workspace:WaitForChild("Military");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local Notification2 = script:WaitForChild("Notification");
local Loners = workspace:WaitForChild("Bases"):WaitForChild("Loners");
local u1 = nil;
local u2 = Vector2.new(0, 0);
local u3 = {
    BTR = "rbxassetid://16270992443",
    BTRfire = "rbxassetid://16270991717",
    ["Timed Crate"] = "rbxassetid://16018005011",
    Boris = "rbxassetid://18312187080",
    Bruno = "rbxassetid://16652579167",
    Brutus = "rbxassetid://134265072222654"
};
local u4 = {};

local function _(p5) -- Line: 58
    -- upvalues: u2 (copy)
    local v6 = 0.5 + (p5.X - u2.X) / 12800;
    local v7 = typeof(p5) == "Vector3" and p5.Z or p5.Y;

    return UDim2.new(v6, 0, 0.5 + (v7 - u2.Y) / 12800, 0);
end;

local function u25(p8) -- Line: 65
    -- upvalues: u4 (copy), u1 (ref), TimedCrateTemplate (copy), u2 (copy), Map (copy), Events (copy), BTRTemplate (copy), Military (copy), BrunoTemplate (copy), BorisTemplate (copy), BrutusTemplate (copy)
    for i, v in pairs(u4) do
        if not p8 or v.Name == "BTR" then
            v:Destroy();
            u4[i] = nil;
        end;
    end;

    if u1 and (u1.Parent and not p8) then
        for _, child in pairs(u1:GetChildren()) do
            local u9 = TimedCrateTemplate:Clone();
            local Position = child.Main.Position;
            local v10 = 0.5 + (Position.X - u2.X) / 12800;
            local v11 = typeof(Position) == "Vector3" and Position.Z or Position.Y;
            u9.Position = UDim2.new(v10, 0, 0.5 + (v11 - u2.Y) / 12800, 0);
            u9.Parent = Map;
            u9.Visible = true;
            u4[child] = u9;
            u9.MouseEnter:Connect(function() -- Line: 83
                -- upvalues: u9 (copy)
                u9.TextLabel.Visible = true;
            end);
            u9.MouseLeave:Connect(function() -- Line: 86
                -- upvalues: u9 (copy)
                u9.TextLabel.Visible = false;
            end);
        end;
    end;

    local BTR = Events:FindFirstChild("BTR");

    if BTR then
        local v12 = BTRTemplate:Clone();
        v12.BTRImage.Image = BTR:GetAttribute("Destroyed") and "rbxassetid://16270991717" or "rbxassetid://16270992443";
        local Position = BTR.HumanoidRootPart.Position;
        local v13 = 0.5 + (Position.X - u2.X) / 12800;
        local v14 = typeof(Position) == "Vector3" and Position.Z or Position.Y;
        v12.Position = UDim2.new(v13, 0, 0.5 + (v14 - u2.Y) / 12800, 0);
        v12.Name = "BTR";
        v12.Parent = Map;
        v12.Visible = true;
        u4[BTR] = v12;
    end;

    local v15 = Military:WaitForChild("Military Barracks"):FindFirstChild("Bruno") or Military:WaitForChild("Rocket Factory"):FindFirstChild("Bruno");

    if v15 then
        local v16 = BrunoTemplate:Clone();
        local Position = v15.HumanoidRootPart.Position;
        local v17 = 0.5 + (Position.X - u2.X) / 12800;
        local v18 = typeof(Position) == "Vector3" and Position.Z or Position.Y;
        v16.Position = UDim2.new(v17, 0, 0.5 + (v18 - u2.Y) / 12800, 0);
        v16.Name = "Boris";
        v16.Parent = Map;
        v16.Visible = true;
        u4[v15] = v16;
    end;

    local Boris = Military:WaitForChild("Labs"):FindFirstChild("Boris");

    if Boris then
        local v19 = BorisTemplate:Clone();
        local Position = Boris.HumanoidRootPart.Position;
        local v20 = 0.5 + (Position.X - u2.X) / 12800;
        local v21 = typeof(Position) == "Vector3" and Position.Z or Position.Y;
        v19.Position = UDim2.new(v20, 0, 0.5 + (v21 - u2.Y) / 12800, 0);
        v19.Name = "Boris";
        v19.Parent = Map;
        v19.Visible = true;
        u4[Boris] = v19;
    end;

    local Brutus = Military:WaitForChild("Industrial Port"):FindFirstChild("Brutus");

    if Brutus then
        local v22 = BrutusTemplate:Clone();
        local Position = Brutus.HumanoidRootPart.Position;
        local v23 = 0.5 + (Position.X - u2.X) / 12800;
        local v24 = typeof(Position) == "Vector3" and Position.Z or Position.Y;
        v22.Position = UDim2.new(v23, 0, 0.5 + (v24 - u2.Y) / 12800, 0);
        v22.Name = "Brutus";
        v22.Parent = Map;
        v22.Visible = true;
        u4[Brutus] = v22;
    end;
end;

local function u32(p26) -- Line: 141
    -- upvalues: Notification (copy), u3 (copy), TweenService (copy), Notification2 (copy)
    Notification.Bottom.Event.Text = string.upper(p26) .. " AVAILABLE";
    Notification.Image.Image = u3[p26];
    local v27 = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0);
    local v28 = {
        Position = Notification:GetAttribute("PositionOpen")
    };
    local v29 = {
        Position = Notification:GetAttribute("PositionClosed")
    };
    local v30 = TweenService:Create(Notification, v27, v28);
    local v31 = TweenService:Create(Notification, v27, v29);
    v30:Play();
    Notification2:Play();
    task.wait(8);
    v31:Play();
end;

local function v36(p33) -- Line: 161
    -- upvalues: u1 (ref), u25 (copy), u32 (copy)
    if not p33 or (not p33.Parent or p33.Name ~= "Timed Crate") then
        return;
    end;

    u1 = p33;
    u1.ChildAdded:Connect(function(p34) -- Line: 164
        -- upvalues: u25 (ref), u32 (ref)
        if p34.Name == "Timed Crate" then
            u25();
            u32("Timed Crate");
        end;
    end);
    u1.ChildRemoved:Connect(function(p35) -- Line: 170
        -- upvalues: u25 (ref)
        if p35.Name == "Timed Crate" then
            u25();
        end;
    end);
    task.wait();
    u25();
end;

local function v57(u37) -- Line: 180
    -- upvalues: u32 (copy), LocalPlayer (copy), NumberUtil (copy)
    if u37.Name == "BTR" then
        if not u37:GetAttribute("Marked") then
            u37:SetAttribute("Marked", true);
            u32("BTR");
        end;

        local u38 = nil;
        local u39 = false;
        local u40 = 0;
        u37:GetAttributeChangedSignal("GunPosition"):Connect(function() -- Line: 189
            -- upvalues: LocalPlayer (ref), u37 (copy), NumberUtil (ref), u39 (ref), u38 (ref), u40 (ref)
            local Character = LocalPlayer.Character;

            if not Character then
                return;
            end;

            local PrimaryPart = Character.PrimaryPart;

            if not (PrimaryPart and (u37:FindFirstChild("HumanoidRootPart") and NumberUtil:IsWithin(PrimaryPart.Position, u37.HumanoidRootPart.Position, 1000))) then
                return;
            end;

            local v41 = u37:GetAttribute("GunPosition");
            local GunBase = u37.Detail:FindFirstChild("GunBase");

            if not GunBase then
                return;
            end;

            if u39 and (not u38 or NumberUtil:IsWithin(u38, v41, 3)) then
                u38 = v41;
                u40 = os.clock();

                return;
            end;

            local GunPivot = GunBase:FindFirstChild("GunPivot");
            local HumanoidRootPart = u37:FindFirstChild("HumanoidRootPart");

            if not (GunPivot and HumanoidRootPart) then
                return;
            end;

            local GunBase2 = HumanoidRootPart:FindFirstChild("GunBase");

            if not GunBase2 then
                return;
            end;

            u39 = true;
            local v42 = u38;
            u38 = v41;
            local v43 = v42 or v41;
            u40 = os.clock();

            while os.clock() - u40 < 1 do
                local v44 = task.wait(0.016666666666666666);

                if not (GunBase2.Parent and GunPivot.Parent) then
                    return;
                end;

                v43 = v43:Lerp(u38, (math.clamp(v44 * 6, 0, 1)));
                local Position = GunBase.Position;
                local v45 = Vector3.new(Position.X, 0, Position.Z);
                local v46 = Vector3.new(v43.X, 0, v43.Z);
                GunBase2.C1 = CFrame.new(0, 0.3, 0) * HumanoidRootPart.CFrame.Rotation * CFrame.new(v45, v46).Rotation:Inverse();
                local v47 = math.atan2(v43.Y - Position.Y, (v46 - v45).Magnitude);
                local v48 = math.clamp(v47, -0.25, 1.1);
                GunPivot.C1 = CFrame.Angles(0, 0, -v48);
            end;

            u39 = false;
        end);
        local Humanoid = u37:WaitForChild("Humanoid");

        if not Humanoid then
            return;
        end;

        local HumanoidRootPart = u37:WaitForChild("HumanoidRootPart");

        if not HumanoidRootPart then
            return;
        end;

        local WheelJoints = HumanoidRootPart:WaitForChild("WheelJoints");

        if not WheelJoints then
            return;
        end;

        local u49 = false;
        local u50 = 0;
        local u51 = 1;
        local u52 = 0;
        Humanoid.Running:Connect(function(p53) -- Line: 289
            -- upvalues: LocalPlayer (ref), u37 (copy), NumberUtil (ref), u49 (ref), u50 (ref), WheelJoints (copy), u51 (ref), u52 (ref)
            local Character = LocalPlayer.Character;

            if not Character then
                return;
            end;

            local PrimaryPart = Character.PrimaryPart;

            if not (PrimaryPart and (u37:FindFirstChild("HumanoidRootPart") and NumberUtil:IsWithin(PrimaryPart.Position, u37.HumanoidRootPart.Position, 750))) then
                return;
            end;

            if u49 or p53 <= 0.01 then
                u50 = p53;
                u51 = p53 <= 0.01 and 4 or 1;

                return;
            end;

            u49 = true;
            u50 = p53;
            local v54 = u50;
            local v55 = WheelJoints:GetChildren();

            while true do
                local v56 = task.wait(0.016666666666666666);

                if not WheelJoints.Parent then
                    break;
                end;

                v54 = NumberUtil:Lerp(v54, u50, (math.clamp(v56 * u51 * 8, 0, 1)));
                u52 = u52 + math.rad(v54 * 12.5 * v56);

                for _, v in pairs(v55) do
                    v.C1 = CFrame.Angles(u52, 0, 0);
                end;

                if v54 <= 0.01 and u50 <= 0.01 then
                    u49 = false;

                    return;
                end;
            end;
        end);
    end;
end;

Loners.ChildAdded:Connect(v36);
v36(Loners:FindFirstChild("Timed Crate"));
Events.ChildRemoved:Connect(function() -- Line: 342
    -- upvalues: u25 (copy)
    u25();
end);
Events.ChildAdded:Connect(v57);
Military:WaitForChild("Industrial Port").ChildAdded:Connect(function(p58) -- Line: 348
    -- upvalues: u32 (copy)
    if p58.Name == "Brutus" then
        u32("Brutus");
    end;
end);
Military:WaitForChild("Labs").ChildAdded:Connect(function(p59) -- Line: 354
    -- upvalues: u32 (copy)
    if p59.Name == "Boris" then
        u32("Boris");
    end;
end);
Military:WaitForChild("Military Barracks").ChildAdded:Connect(function(p60) -- Line: 360
    -- upvalues: u32 (copy)
    if p60.Name == "Bruno" then
        u32("Bruno");
    end;
end);
Military:WaitForChild("Rocket Factory").ChildAdded:Connect(function(p61) -- Line: 366
    -- upvalues: u32 (copy)
    if p61.Name == "Bruno" then
        u32("Bruno");
    end;
end);

for _, child in pairs(Events:GetChildren()) do
    v57(child);
end;

while true do
    u25();
    task.wait(2);
end;