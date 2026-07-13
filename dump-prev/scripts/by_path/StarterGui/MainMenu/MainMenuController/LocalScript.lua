-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local UserInputService_upv_1 = game:GetService("UserInputService");
local GamepadService_upv_1 = game:GetService("GamepadService");
local Players_upv_1 = game:GetService("Players");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local SettingRemotes_upv_1 = ReplicatedStorage_1:WaitForChild("SettingRemotes");
local ButtonClass_1 = require(Modules_1:WaitForChild("ButtonClass"));
local PreferredInputController_upv_1 = Players_upv_1.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local Parent_upv_1 = script.Parent;
local TeleportBack_upv_1 = Parent_upv_1:WaitForChild("TeleportBack");
local u1 = false;
local u2 = false;
local u3 = nil;
local function u4(a1)
    --[[
      line: 40
      upvalues:
        Parent_upv_1 (copy, index: 1)
        UserInputService_upv_1 (copy, index: 2)
        PreferredInputController_upv_1 (copy, index: 3)
        GamepadService_upv_1 (copy, index: 4)
    ]]
    Parent_upv_1.Enabled = a1;
    local v1;
    if (a1) then
        v1 = Enum.MouseBehavior.Default;
    else
        v1 = Enum.MouseBehavior.LockCenter;
    end;
    UserInputService_upv_1.MouseBehavior = v1;
    UserInputService_upv_1.MouseIconEnabled = a1;
    local v2 = nil;
    if (a1) then
        v2 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
        if (not v2) then
            return;
        end;
        pcall(
            function()
                --[[
                  line: 46
                  upvalues:
                    GamepadService_upv_1 (copy, index: 1)
                ]]
                GamepadService_upv_1:EnableGamepadCursor(nil);
            end
        );
    else
        pcall(
            function()
                --[[
                  line: 49
                  upvalues:
                    GamepadService_upv_1 (copy, index: 1)
                ]]
                GamepadService_upv_1:DisableGamepadCursor();
            end
        );
    end;
end;
UserInputService_upv_1.InputBegan:Connect(
    function(a1)
        --[[
          line: 53
          upvalues:
            UserInputService_upv_1 (copy, index: 1)
            u4 (copy, index: 2)
            Parent_upv_1 (copy, index: 3)
            Players_upv_1 (copy, index: 4)
            GamepadService_upv_1 (copy, index: 5)
            u3 (ref,  index: 6)
            PreferredInputController_upv_1 (copy, index: 7)
        ]]
        local v3;
        if (UserInputService_upv_1:GetFocusedTextBox()) then
            return;
        end;
        v3 = a1.UserInputType;
        if (v3 ~= Enum.UserInputType.Keyboard) then
            local v4;
            if (v3 ~= Enum.UserInputType.Gamepad1) then
                return;
            end;
            v4 = a1.KeyCode;
            if (v4 == Enum.KeyCode.DPadUp) then
                local v5 = Players_upv_1.LocalPlayer.Character and (Players_upv_1.LocalPlayer.Character:FindFirstChild("Humanoid"));
                if (not v5 or v5.Health > 0) then
                    if (Parent_upv_1.Enabled) then
                        Parent_upv_1.Enabled = false;
                        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                        UserInputService_upv_1.MouseIconEnabled = false;
                        pcall(
                            function()
                                --[[
                                  line: 49
                                  upvalues:
                                    GamepadService_upv_1 (copy, index: 1)
                                ]]
                                GamepadService_upv_1:DisableGamepadCursor();
                            end
                        );
                    else
                        u3 = tick();
                        task.delay(
                            0.9,
                            function()
                                --[[
                                  line: 75
                                  upvalues:
                                    u3 (ref,  index: 1)
                                    Parent_upv_1 (copy, index: 2)
                                    UserInputService_upv_1 (copy, index: 3)
                                    PreferredInputController_upv_1 (copy, index: 4)
                                    GamepadService_upv_1 (copy, index: 5)
                                ]]
                                if (not u3) then
                                    return;
                                end;
                                if (tick() - u3 >= 0.85) then
                                    Parent_upv_1.Enabled = true;
                                    UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                                    UserInputService_upv_1.MouseIconEnabled = true;
                                    local v6 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                                    if (v6) then
                                        pcall(
                                            function()
                                                --[[
                                                  line: 46
                                                  upvalues:
                                                    GamepadService_upv_1 (copy, index: 1)
                                                ]]
                                                GamepadService_upv_1:EnableGamepadCursor(nil);
                                            end
                                        );
                                    end;
                                    u3 = nil;
                                    while (Parent_upv_1.Enabled) do
                                        UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                                        UserInputService_upv_1.MouseIconEnabled = true;
                                        task.wait();
                                    end;
                                end;
                            end
                        );
                    end;
                end;
            elseif (v4 == Enum.KeyCode.ButtonB and Parent_upv_1.Enabled) then
                Parent_upv_1.Enabled = false;
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
                UserInputService_upv_1.MouseIconEnabled = false;
                pcall(
                    function()
                        --[[
                          line: 49
                          upvalues:
                            GamepadService_upv_1 (copy, index: 1)
                        ]]
                        GamepadService_upv_1:DisableGamepadCursor();
                    end
                );
            end;
        elseif (a1.KeyCode == Enum.KeyCode.P) then
            u4(not Parent_upv_1.Enabled);
            while (Parent_upv_1.Enabled) do
                UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.Default;
                UserInputService_upv_1.MouseIconEnabled = true;
                task.wait();
            end;
        end;
    end
);
UserInputService_upv_1.InputEnded:Connect(
    function(a1)
        --[[
          line: 93
          upvalues:
            u3 (ref, index: 1)
        ]]
        if (a1.UserInputType ~= Enum.UserInputType.Gamepad1) then
            return;
        end;
        if (a1.KeyCode == Enum.KeyCode.DPadUp) then
            u3 = nil;
        end;
    end
);
Parent_upv_1.Enabled = false;
UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior.LockCenter;
UserInputService_upv_1.MouseIconEnabled = false;
pcall(
    function()
        --[[
          line: 49
          upvalues:
            GamepadService_upv_1 (copy, index: 1)
        ]]
        GamepadService_upv_1:DisableGamepadCursor();
    end
);
PreferredInputController_upv_1:GetAttributeChangedSignal("PreferredInput"):Connect(
    function()
        --[[
          line: 102
          upvalues:
            Parent_upv_1 (copy, index: 1)
            PreferredInputController_upv_1 (copy, index: 2)
            GamepadService_upv_1 (copy, index: 3)
        ]]
        if (Parent_upv_1.Enabled) then
            local v7 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
            if (v7) then
                pcall(
                    function()
                        --[[
                          line: 105
                          upvalues:
                            GamepadService_upv_1 (copy, index: 1)
                        ]]
                        GamepadService_upv_1:EnableGamepadCursor(nil);
                    end
                );
            else
                pcall(
                    function()
                        --[[
                          line: 107
                          upvalues:
                            GamepadService_upv_1 (copy, index: 1)
                        ]]
                        GamepadService_upv_1:DisableGamepadCursor();
                    end
                );
            end;
        end;
    end
);
ButtonClass_1.new(
    TeleportBack_upv_1,
    "BackgroundColor3",
    function()
        --[[
          line: 111
          upvalues:
            u2 (ref,  index: 1)
            u1 (ref,  index: 2)
            TeleportBack_upv_1 (copy, index: 3)
            SettingRemotes_upv_1 (copy, index: 4)
        ]]
        if (u2) then
            return;
        end;
        if (u1) then
            u2 = true;
            TeleportBack_upv_1.TextLabel.Text = "TELEPORTING...";
            SettingRemotes_upv_1.Teleport:FireServer();
            task.wait(30);
            TeleportBack_upv_1.TextLabel.Text = "TELEPORT BACK TO MAIN MENU";
            u2 = false;
        else
            u1 = true;
            for n_1 = 3, 1, -1 do
                if (u2) then
                    break;
                else
                    TeleportBack_upv_1.TextLabel.Text = ("ARE YOU SURE? (%*)"):format(n_1);
                    task.wait(1);
                end;
            end;
            u1 = false;
            if (u2) then
                return;
            end;
            TeleportBack_upv_1.TextLabel.Text = "TELEPORT BACK TO MAIN MENU";
        end;
    end
);