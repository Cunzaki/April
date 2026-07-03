-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local UserInputService = game:GetService("UserInputService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local SettingsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SettingsModule"));
script:SetAttribute("JoystickDeadzone", SettingsModule.GetSetting("Gamepad", "Joystick Deadzone") or 0.225);
ReplicatedStorage:GetAttributeChangedSignal("Settings"):Connect(function() -- Line: 13
    -- upvalues: SettingsModule (copy)
    script:SetAttribute("JoystickDeadzone", SettingsModule.GetSetting("Gamepad", "Joystick Deadzone") or 0.225);
end);
local u1 = "KeyboardAndMouse";
script:SetAttribute("PreferredInput", "KeyboardAndMouse");
script:SetAttribute("IsPlayStation", false);
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function() -- Line: 23
    -- upvalues: u1 (ref)
    u1 = "KeyboardAndMouse";
    script:SetAttribute("PreferredInput", "KeyboardAndMouse");
    script:SetAttribute("IsPlayStation", false);
end);
UserInputService.InputBegan:Connect(function(p2) -- Line: 29
    -- upvalues: UserInputService (copy), u1 (ref)
    if p2.UserInputType == Enum.UserInputType.Gamepad1 and (p2.KeyCode == Enum.KeyCode.Thumbstick1 or p2.KeyCode == Enum.KeyCode.Thumbstick2) then
        local Position = p2.Position;
        local v3 = script:GetAttribute("JoystickDeadzone") or 0.225;

        if math.abs(Position.X) < v3 and math.abs(Position.Y) < v3 then
            return;
        end;
    end;

    local PreferredInput = UserInputService.PreferredInput;
    local v4 = PreferredInput == Enum.PreferredInput.Gamepad and "Gamepad" or (PreferredInput == Enum.PreferredInput.KeyboardAndMouse and "KeyboardAndMouse" or nil);

    if v4 == u1 then
        return;
    end;

    u1 = v4;
    script:SetAttribute("PreferredInput", v4);

    if v4 ~= "Gamepad" then
        script:SetAttribute("IsPlayStation", false);

        return;
    end;

    local v5 = UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA) == "ButtonCross";
    script:SetAttribute("IsPlayStation", v5);
    UserInputService.MouseIconEnabled = false;
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
end);
UserInputService.InputChanged:Connect(function(p6) -- Line: 65
    -- upvalues: u1 (ref)
    if p6.UserInputType ~= Enum.UserInputType.Gamepad1 then
        return;
    end;

    if p6.KeyCode ~= Enum.KeyCode.Thumbstick1 and p6.KeyCode ~= Enum.KeyCode.Thumbstick2 then
        return;
    end;

    local Position = p6.Position;
    local X = Position.X;
    local Y = Position.Y;
    local v7 = script:GetAttribute("JoystickDeadzone") or 0.225;

    if v7 < X or (X < -v7 or (v7 < Y or Y < -v7)) then
        u1 = "Gamepad";
        script:SetAttribute("PreferredInput", "Gamepad");
    end;
end);