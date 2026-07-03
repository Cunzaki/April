-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local PolicyService = game:GetService("PolicyService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
ReplicatedStorage:WaitForChild("Values");
local Loners = workspace:WaitForChild("Bases"):WaitForChild("Loners");
local Signs = ReplicatedStorage:WaitForChild("Signs");
local ClientSignals = ReplicatedStorage:WaitForChild("ClientSignals");
local LocalPlayer = Players.LocalPlayer;
LocalPlayer:WaitForChild("PlayerScripts");
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local v1 = require(Modules:WaitForChild("AssetContainer"))();
local ActiveBenchModule = require(Modules:WaitForChild("ActiveBenchModule"));
shared.Beds = {};
v1("Setup", "\156\2I=\144i\181\249\200\249\198Q\20\205\1431\142\1\1391", "s \181\192\27xL\1\209\202\224\220\179\19XW;\19\221k", function(p2) -- Line: 45
    -- upvalues: ActiveBenchModule (copy)
    ActiveBenchModule.SetServClientInfos(p2);
end);
v1("Setup", "\156\2I=\144i\181\249\200\249\198Q\20\205\1431\142\1\1391", "n\202\166F\26\222[7\255\183L\138r\248_I\137\160\210\1", function(p3) -- Line: 49
    if type(p3) ~= "table" then
        return;
    end;

    shared.Beds = p3;
end);

local function _(p4, p5) -- Line: 55
    local Toggle = p4.Toggle;
    p4.Hidden.Visible = p5;
    Toggle.BackgroundColor3 = p5 and Color3.fromRGB(255, 30, 0) or Color3.fromRGB(60, 255, 0);
    Toggle.Text = p5 and "SHOW" or "HIDE";
end;

local function v9(u6) -- Line: 62
    -- upvalues: PlayerGui (copy), Signs (copy)
    if not (u6:IsA("SurfaceGui") and u6.Parent) then
        return;
    end;

    local Toggle = u6:WaitForChild("Toggle", 1);

    if not (Toggle and u6.Parent) then
        return;
    end;

    task.defer(function() -- Line: 66
        -- upvalues: u6 (copy), PlayerGui (ref), Toggle (copy)
        if not u6.Parent then
            return;
        end;

        u6.Parent = PlayerGui;
        Toggle.Activated:Connect(function() -- Line: 70
            -- upvalues: u6 (ref)
            local v7 = u6;
            local v8 = not u6.Hidden.Visible;
            local Toggle2 = v7.Toggle;
            v7.Hidden.Visible = v8;
            Toggle2.BackgroundColor3 = v8 and Color3.fromRGB(255, 30, 0) or Color3.fromRGB(60, 255, 0);
            Toggle2.Text = v8 and "SHOW" or "HIDE";
        end);
    end);

    if Signs:GetAttribute("ToggleSigns") then
        local Toggle2 = u6.Toggle;
        u6.Hidden.Visible = true;
        Toggle2.BackgroundColor3 = Color3.fromRGB(255, 30, 0) or Color3.fromRGB(60, 255, 0);
        Toggle2.Text = "SHOW";
    end;
end;

Signs.ChildAdded:Connect(v9);

for i, child in pairs(Signs:GetChildren()) do
    v9(child);

    if i % 100 == 0 then
        task.wait();
    end;
end;

Signs:GetAttributeChangedSignal("ToggleSigns"):Connect(function() -- Line: 85
    -- upvalues: Signs (copy), PlayerGui (copy)
    local v10 = Signs:GetAttribute("ToggleSigns");

    if v10 == nil then
        return;
    end;

    local v11 = 0;

    for _, child in pairs(PlayerGui:GetChildren()) do
        if child.Parent and child:IsA("SurfaceGui") then
            local Toggle = child.Toggle;
            child.Hidden.Visible = v10;
            Toggle.BackgroundColor3 = v10 and Color3.fromRGB(255, 30, 0) or Color3.fromRGB(60, 255, 0);
            Toggle.Text = v10 and "SHOW" or "HIDE";
            v11 = v11 + 1;

            if v11 % 100 == 0 then
                task.wait();
            end;
        end;
    end;

    print("successfully updated", v11, "signs");
end);
ClientSignals:WaitForChild("BenchCleanup").OnClientEvent:Connect(function(p12) -- Line: 99
    -- upvalues: ActiveBenchModule (copy)
    local v13 = os.clock();
    local v14 = 0;
    local v15 = {};

    for _, v in p12 do
        v14 = v14 + 1;

        if v14 % 100 == 0 then
            task.wait();
        end;

        v15[`{v:sub(1, 8)}-{v:sub(9, 12)}-{v:sub(13, 16)}-{v:sub(17, 20)}-{v:sub(21)}`] = true;
    end;

    for i, _ in ActiveBenchModule.GetAllRawClientInfos() do
        v14 = v14 + 1;

        if v14 % 100 == 0 then
            task.wait();
        end;

        if not v15[i] then
            ActiveBenchModule.RemoveClientInfo(i);
        end;
    end;

    print("cleaned up old active benches in", os.clock() - v13);
end);
local v16;

while true do
    local v17;
    v17, v16 = pcall(function() -- Line: 121
        -- upvalues: PolicyService (copy), LocalPlayer (copy)
        return PolicyService:GetPolicyInfoForPlayerAsync(LocalPlayer);
    end);

    if v17 then
        break;
    end;

    warn("Error fetching from PolicyService - ", v16);
    task.wait(3);
end;

if v16.ArePaidRandomItemsRestricted then
    local function u20(p18) -- Line: 126
        p18.ChildAdded:Connect(function(p19) -- Line: 127
            task.wait();

            if not p19.Parent then
                return;
            end;

            p19.PrimaryPart = nil;
        end);

        for _, child in pairs(p18:GetChildren()) do
            child.PrimaryPart = nil;
        end;
    end;

    Loners.ChildAdded:Connect(function(p21) -- Line: 137
        -- upvalues: u20 (copy)
        if p21.Name ~= "Plinko Machine" then
            return;
        end;

        u20(p21);
    end);
    local v22 = Loners:FindFirstChild("Plinko Machine");

    if v22 then
        u20(v22);
    end;
end;