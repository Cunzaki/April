-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ServerBuild_upv_1 = game:GetService("ReplicatedStorage"):WaitForChild("Values"):WaitForChild("ServerBuild");
local Parent_upv_1 = script.Parent;
Parent_upv_1.Text = ("Fallen Build %*"):format(ServerBuild_upv_1.Value);
ServerBuild_upv_1:GetPropertyChangedSignal("Value"):Connect(
    function()
        --[[
          line: 19
          upvalues:
            Parent_upv_1 (copy, index: 1)
            ServerBuild_upv_1 (copy, index: 2)
        ]]
        Parent_upv_1.Text = ("Fallen Build %*"):format(ServerBuild_upv_1.Value);
    end
);