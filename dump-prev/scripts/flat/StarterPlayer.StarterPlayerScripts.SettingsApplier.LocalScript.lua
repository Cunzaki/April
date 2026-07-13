-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage_upv_1 = game:GetService("ReplicatedStorage");
local Players_1 = game:GetService("Players");
local Lighting_upv_1 = game:GetService("Lighting");
local SoundService_1 = game:GetService("SoundService");
local LocalPlayer_1 = Players_1.LocalPlayer;
local PlayerGui_1 = LocalPlayer_1:WaitForChild("PlayerGui");
local PlayerScripts_1 = LocalPlayer_1:WaitForChild("PlayerScripts");
local SettingsModule_upv_1 = require(ReplicatedStorage_upv_1:WaitForChild("Modules"):WaitForChild("SettingsModule"));
local UpdateFontSize_upv_1 = PlayerScripts_1:WaitForChild("ChatController"):WaitForChild("UpdateFontSize");
local Jukebox_upv_1 = SoundService_1:WaitForChild("Jukebox");
local Gunshots_upv_1 = SoundService_1:WaitForChild("Gunshots");
local GunshotReverb_upv_1 = SoundService_1:WaitForChild("GunshotReverb");
local General_upv_1 = SoundService_1:WaitForChild("General");
local CustomChat_upv_1;
local u1;
while (true) do
    CustomChat_upv_1 = PlayerGui_1:FindFirstChild("CustomChat");
    local v1 = CustomChat_upv_1 and (CustomChat_upv_1:FindFirstChild("ChatFrame"));
    u1 = v1;
    if (not (CustomChat_upv_1)) then
        task.wait();
        continue;
    end;
    if (u1) then
        break;
    end;
    task.wait();
end;
local Signs_upv_1 = ReplicatedStorage_upv_1:WaitForChild("Signs");
while (not (SettingsModule_upv_1.Settings)) do
    task.wait();
end;
local function v2(a1)
    --[[
      line: 51
      upvalues:
        ReplicatedStorage_upv_1 (copy, index: 1)
        Signs_upv_1 (copy, index: 2)
        SettingsModule_upv_1 (copy, index: 3)
        CustomChat_upv_1 (ref,  index: 4)
        Lighting_upv_1 (copy, index: 5)
        Jukebox_upv_1 (copy, index: 6)
        Gunshots_upv_1 (copy, index: 7)
        GunshotReverb_upv_1 (copy, index: 8)
        General_upv_1 (copy, index: 9)
        u1 (ref,  index: 10)
        UpdateFontSize_upv_1 (copy, index: 11)
    ]]
    if (a1 ~= true and not (ReplicatedStorage_upv_1:GetAttribute("Settings"))) then
        return;
    end;
    local v3 = SettingsModule_upv_1.GetSetting("General", "Auto Hide All Signs") == true;
    Signs_upv_1:SetAttribute("ToggleSigns", v3);
    local v4 = SettingsModule_upv_1.GetSetting("General", "Hide Chat") == true;
    CustomChat_upv_1:SetAttribute("Hidden", v4);
    Lighting_upv_1.GlobalShadows = SettingsModule_upv_1.GetSetting("Graphics", "Shadows") == true;
    local v6 = SettingsModule_upv_1.GetSetting("Sound", "Master Volume");
    Jukebox_upv_1.Volume = SettingsModule_upv_1.GetSetting("General", "Mute Jukeboxes") and 0 or SettingsModule_upv_1.GetSetting("Sound", "Jukebox Volume") * v6;
    Gunshots_upv_1.Volume = SettingsModule_upv_1.GetSetting("Sound", "Gunshot Volume") * v6;
    GunshotReverb_upv_1.Volume = SettingsModule_upv_1.GetSetting("Sound", "Gunshot Volume") * v6;
    for _, value_1 in {General_upv_1} do
        value_1.Volume = SettingsModule_upv_1.GetSetting("Sound", "SFX Volume") * v6;
    end;
    if (u1) then
        local v8 = SettingsModule_upv_1.GetSetting("General", "Chat Scale");
        local v9 = u1:GetAttribute("BaseSize");
        u1.Size = UDim2.new(v9.X.Scale * v8, 0, v9.Y.Scale * v8, 0);
        task.delay(
            0.5,
            function()
                --[[
                  line: 69
                  upvalues:
                    UpdateFontSize_upv_1 (copy, index: 1)
                ]]
                UpdateFontSize_upv_1:Fire();
            end
        );
    end;
    ReplicatedStorage_upv_1:SetAttribute("Settings", nil);
end;
ReplicatedStorage_upv_1:GetAttributeChangedSignal("Settings"):Connect(v2);
v2(true);