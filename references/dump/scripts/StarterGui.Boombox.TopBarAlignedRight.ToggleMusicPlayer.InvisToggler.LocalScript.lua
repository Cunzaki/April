-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local RelicsXYZ = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Boombox"):WaitForChild("RelicsXYZ");
local AudioPlayer = require(RelicsXYZ:WaitForChild("AudioPlayer"));
require(RelicsXYZ:WaitForChild("Playlists"));
script.Parent.Activated:Connect(function() -- Line: 7
    -- upvalues: AudioPlayer (copy)
    AudioPlayer.ToggleVisibility();
end);