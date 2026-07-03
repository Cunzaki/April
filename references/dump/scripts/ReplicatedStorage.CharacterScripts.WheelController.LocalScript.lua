-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local TweenUtil = require(Modules:WaitForChild("TweenUtil"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local Open = script:WaitForChild("Open");
local Close = script:WaitForChild("Close");
local LocalPlayer = Players.LocalPlayer;
local Parent = script.Parent;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
Parent:WaitForChild("Humanoid");
local PreferredInputController = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local Wheel = PlayerGui:WaitForChild("Main"):WaitForChild("Wheel");

local function getDeadzone() -- Line: 41
    -- upvalues: PreferredInputController (copy)
    return PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225;
end;

local u1 = nil;
local u2 = nil;
local u3 = nil;
local u4 = nil;
local u5 = 0;
local u6 = {};
local u7 = 1;
local u8 = nil;
local u9 = 1;

local function _() -- Line: 52
    -- upvalues: PreferredInputController (copy)
    local v10 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    return v10;
end;

local function u15(p11) -- Line: 56
    -- upvalues: UserInputService (copy), PreferredInputController (copy)
    local success, result = pcall(function() -- Line: 57
        -- upvalues: UserInputService (ref)
        return UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1);
    end);

    if not (success and result) then
        return nil;
    end;

    for _, v in pairs(result) do
        if v.KeyCode == Enum.KeyCode.Thumbstick1 then
            local X = v.Position.X;
            local Y = v.Position.Y;

            if math.sqrt(X * X + Y * Y) <= (PreferredInputController:GetAttribute("JoystickDeadzone") or 0.225) then
                return nil;
            end;

            local v12 = math.atan2(X, Y);
            local v13 = math.deg(v12);

            if v13 < 0 then
                v13 = v13 + 360;
            end;

            local v14 = 360 / p11;

            return math.floor((v13 + v14 / 2) % 360 / v14) + 1;
        end;
    end;

    return nil;
end;

local function u18(p16, p17) -- Line: 81
    -- upvalues: u9 (ref), Wheel (copy), u1 (ref), u5 (ref), NumberUtil (copy)
    u9 = p16;

    for _, child in pairs(Wheel:GetChildren()) do
        for _, v in pairs(u1 == child and { child.Red, unpack(child.Icon:GetChildren()) } or (child:IsA("Frame") and {} or { child })) do
            if v.Name ~= "Red" or (u5 ~= 0 or not p17 and v.ImageTransparency ~= 1) then
                v[(v:IsA("TextLabel") and "Text" or (v:IsA("ImageLabel") and "Image" or "Background")) .. "Transparency"] = NumberUtil:Lerp(v.Name == "BG" and 0.2 or 0, 1, p16);
            end;
        end;
    end;

    Wheel.Visible = p16 < 1;
end;

local function u24(p19) -- Line: 96
    -- upvalues: Wheel (copy), NumberUtil (copy), u2 (ref), u3 (ref), u7 (ref), u18 (copy), RunService (copy)
    if p19 then
        Wheel.Size = NumberUtil:MultUDim2ByNum(u2, 1.3);
    end;

    Wheel:TweenSize(NumberUtil:MultUDim2ByNum(u2, p19 and 1 or 1.3), p19 and "Out" or "In", "Quart", 0.175, true);
    local v20 = tick();
    local v21 = p19 and 0 or 1;

    if u3 and not p19 then
        u3:Cancel();
    end;

    if u7 ~= v21 then
        u7 = v21;

        while true do
            local v22 = tick() - v20;
            local v23 = math.min(v22 / 0.1, 1);

            if p19 then
                v23 = 1 - v23 or v23;
            end;

            u18(v23, p19);

            if v22 >= 0.1 then
                break;
            end;

            RunService.Heartbeat:Wait();
        end;
    end;
end;

local function u28(p25) -- Line: 123
    -- upvalues: Wheel (copy), u1 (ref), u3 (ref), TweenUtil (copy), u4 (ref), u5 (ref)
    Wheel.SelectedImage.Image = p25 and (p25.Image or "") or "";
    Wheel.SelectedName.Text = p25 and (p25.Name or "") or "";
    Wheel.SelectedDesc.Text = p25 and (p25.Description or "") or "";
    Wheel.SelectedCost.Text = p25 and (type(p25.Cost) == "function" and p25.Cost() or (p25.Cost or "")) or "";

    if not u1 then
        return;
    end;

    if p25 then
        u3 = TweenUtil:Tween(u1.Red, "ImageTransparency", 0, 0.2, "Quart");
    else
        u1.Red.ImageTransparency = 1;
    end;

    for _, child in pairs(u1.Icon:GetChildren()) do
        local v26 = tonumber(child.Name:sub(2));
        local v27 = u4[v26];
        child.ImageColor3 = script:GetAttribute(v26 == u5 and "IconSelectedColor" or ((v27 == nil or not v27.Selectable) and "IconUnavailableColor" or "IconUnselectedColor"));
    end;
end;

local function u32(p29, p30) -- Line: 141
    -- upvalues: u1 (ref), u5 (ref), TweenUtil (copy), u28 (copy)
    if not u1 or u5 == p29 then
        return;
    end;

    local v31 = tonumber(u1.Name:sub(6));
    TweenUtil:Tween(u1.Red, "Rotation", 360 / v31 * (p29 - 1), u5 == 0 and 0 or 0.2, "Quart");
    u5 = p29;
    u28(p30);
end;

local function u33() -- Line: 149
    -- upvalues: u6 (ref), RunService (copy)
    for _, v in pairs(u6) do
        v:Disconnect();
    end;

    u6 = {};
    pcall(function() -- Line: 154
        -- upvalues: RunService (ref)
        RunService:UnbindFromRenderStep("WheelGamepadInput");
    end);
end;

local function v46(p34, p35, p36) -- Line: 157
    -- upvalues: u33 (copy), u1 (ref), Wheel (copy), u5 (ref), u4 (ref), u28 (copy), u6 (ref), u32 (copy), PreferredInputController (copy), UserInputService (copy), RunService (copy), u15 (copy), u24 (copy)
    script:SetAttribute("Open", true);
    script:SetAttribute("WheelType", p35);
    u33();

    if u1 then
        u1.Visible = false;
    end;

    u1 = Wheel:FindFirstChild("Wheel" .. #p34);
    u5 = 0;
    u4 = p34;
    u28();
    local v37 = false;
    local u38 = false;

    for i, v in pairs(p34) do
        local v39 = u1.Hitbox["Q" .. i];
        u1.Icon["Q" .. i].Image = v.Image;

        if v.Selectable then
            table.insert(u6, v39.MouseEnter:Connect(function() -- Line: 175
                -- upvalues: u32 (ref), i (copy), v (copy)
                u32(i, v);
            end));
        end;

        if v.SelectFirst then
            u32(i, v);
            v37 = true;
        end;
    end;

    local v40 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    if v40 and (not v37 and p34[1]) then
        u32(1, p34[1]);
    end;

    table.insert(u6, UserInputService.InputBegan:Connect(function(p41) -- Line: 188
        -- upvalues: u38 (ref)
        if p41.UserInputType == Enum.UserInputType.MouseButton1 or p41.KeyCode == Enum.KeyCode.ButtonR2 then
            task.wait();
            u38 = true;
            script:SetAttribute("Open", false);
        end;
    end));
    local u42 = #p34;
    RunService:BindToRenderStep("WheelGamepadInput", Enum.RenderPriority.Input.Value, function() -- Line: 198
        -- upvalues: u1 (ref), u4 (ref), u15 (ref), u42 (copy), u32 (ref)
        if not (u1 and u4) then
            return;
        end;

        local v43 = u15(u42);

        if not v43 then
            return;
        end;

        local v44 = u4[v43];

        if v44 and v44.Selectable then
            u32(v43, v44);
        end;
    end);
    u1.Visible = true;
    local xtra = Wheel.xtra;
    local v45 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad" and p35 ~= "Blueprint";
    xtra.Visible = v45;
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
    UserInputService.MouseIconEnabled = true;
    task.spawn(u24, true);

    while script:GetAttribute("Open") do
        RunService.Heartbeat:Wait();
    end;

    if script:GetAttribute("WheelType") == p35 then
        u33();
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
        UserInputService.MouseIconEnabled = false;
        task.spawn(u24, false);
        Wheel.xtra.Visible = false;
    end;

    if not p36 or u38 then
        return u5;
    end;
end;

local function v47() -- Line: 232
    -- upvalues: Wheel (copy), u8 (ref), u9 (ref), u2 (ref)
    local Y = Wheel.AbsoluteSize.Y;

    if Y == u8 or u9 % 1 ~= 0 then
        return;
    end;

    u8 = Y;
    u2 = UDim2.new(0, Y, 0.7, 0);
    Wheel.Size = u2;
end;

Wheel:GetPropertyChangedSignal("AbsoluteSize"):Connect(v47);
Open.OnInvoke = v46;

function Close.OnInvoke(p48) -- Line: 227
    if p48 and p48 ~= script:GetAttribute("WheelType") then
        return;
    end;

    script:SetAttribute("Open", false);
end;

u2 = Wheel.Size;
u18(1);
Wheel.Visible = false;
local Y = Wheel.AbsoluteSize.Y;

if Y ~= u8 and u9 % 1 == 0 then
    u8 = Y;
    u2 = UDim2.new(0, Y, 0.7, 0);
    Wheel.Size = u2;
end;