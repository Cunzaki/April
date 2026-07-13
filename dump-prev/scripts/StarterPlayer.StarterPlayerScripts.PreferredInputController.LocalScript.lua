-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local UserInputService_upv_1 = game:GetService("UserInputService");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local SettingsModule_upv_1 = require(ReplicatedStorage_1:WaitForChild("Modules"):WaitForChild("SettingsModule"));
script:SetAttribute("JoystickDeadzone", SettingsModule_upv_1.GetSetting("Gamepad", "Joystick Deadzone") or 0.225);
ReplicatedStorage_1:GetAttributeChangedSignal("Settings"):Connect(
    function()
        --[[
          line: 13
          upvalues:
            SettingsModule_upv_1 (copy, index: 1)
        ]]
        script:SetAttribute("JoystickDeadzone", SettingsModule_upv_1.GetSetting("Gamepad", "Joystick Deadzone") or 0.225);
    end
);
local u1 = "KeyboardAndMouse";
script:SetAttribute("PreferredInput", "KeyboardAndMouse");
script:SetAttribute("IsPlayStation", false);
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(
    function()
        --[[
          line: 23
          upvalues:
            u1 (ref, index: 1)
        ]]
        u1 = "KeyboardAndMouse";
        script:SetAttribute("PreferredInput", "KeyboardAndMouse");
        script:SetAttribute("IsPlayStation", false);
    end
);
UserInputService_upv_1.InputBegan:Connect(
    function(a1)
        --[[
          line: 29
          upvalues:
            UserInputService_upv_1 (copy, index: 1)
            u1 (ref,  index: 2)
        ]]
        local v1, v2 = nil, nil;
        if (a1.UserInputType ~= Enum.UserInputType.Gamepad1 or a1.KeyCode ~= Enum.KeyCode.Thumbstick1 and a1.KeyCode ~= Enum.KeyCode.Thumbstick2) then
            local PreferredInput_1 = UserInputService_upv_1.PreferredInput;
            v2 = nil;
            if (PreferredInput_1 == Enum.PreferredInput.Gamepad) then
                v2 = "Gamepad";
            elseif (PreferredInput_1 == Enum.PreferredInput.KeyboardAndMouse) then
                v2 = "KeyboardAndMouse";
            end;
            if (v2 ~= u1) then
                u1 = v2;
                script:SetAttribute("PreferredInput", v2);
                if (v2 ~= "Gamepad") then
                    script:SetAttribute("IsPlayStation", false);
                else
                    local v3 = UserInputService_upv_1:GetStringForKeyCode(Enum.KeyCode.ButtonA) == "ButtonCross";
                    script:SetAttribute("IsPlayStation", v3);
                    UserInputService_upv_1.MouseIconEnabled = false;
                    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                end;
            end;
            return;
        end;
        v1 = a1.Position;
        v2 = script:GetAttribute("JoystickDeadzone") or 0.225;
        if (math.abs(v1.X) >= v2 or math.abs(v1.Y) >= v2) then
            local PreferredInput_1 = UserInputService_upv_1.PreferredInput;
            v2 = nil;
            if (PreferredInput_1 == Enum.PreferredInput.Gamepad) then
                v2 = "Gamepad";
            elseif (PreferredInput_1 == Enum.PreferredInput.KeyboardAndMouse) then
                v2 = "KeyboardAndMouse";
            end;
            if (v2 == u1) then
                return;
            end;
            u1 = v2;
            script:SetAttribute("PreferredInput", v2);
            if (v2 ~= "Gamepad") then
                script:SetAttribute("IsPlayStation", false);
            else
                local v3 = UserInputService_upv_1:GetStringForKeyCode(Enum.KeyCode.ButtonA) == "ButtonCross";
                script:SetAttribute("IsPlayStation", v3);
                UserInputService_upv_1.MouseIconEnabled = false;
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
            end;
        end;
    end
);
UserInputService_upv_1.InputChanged:Connect(
    function(a1)
        --[[
          line: 65
          upvalues:
            u1 (ref, index: 1)
        ]]
        local v4, v5 = nil, nil;
        if (a1.UserInputType == Enum.UserInputType.Gamepad1 and (a1.KeyCode == Enum.KeyCode.Thumbstick1 or a1.KeyCode == Enum.KeyCode.Thumbstick2)) then
            local Position_1 = a1.Position;
            v4 = Position_1.X;
            local Y_1 = Position_1.Y;
            v5 = script:GetAttribute("JoystickDeadzone") or 0.225;
            if (v5 < v4 or v4 < -v5 or v5 < Y_1 or Y_1 < -v5) then
                u1 = "Gamepad";
                script:SetAttribute("PreferredInput", "Gamepad");
            end;
        end;
    end
);