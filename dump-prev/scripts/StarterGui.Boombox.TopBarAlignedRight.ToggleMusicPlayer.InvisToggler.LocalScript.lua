-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local RelicsXYZ_1 = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Boombox"):WaitForChild("RelicsXYZ");
local AudioPlayer_upv_1 = require(RelicsXYZ_1:WaitForChild("AudioPlayer"));
local _ = require(RelicsXYZ_1:WaitForChild("Playlists"));
script.Parent.Activated:Connect(
    function()
        --[[
          line: 7
          upvalues:
            AudioPlayer_upv_1 (copy, index: 1)
        ]]
        AudioPlayer_upv_1.ToggleVisibility();
    end
);