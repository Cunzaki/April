-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local Lighting = game:GetService("Lighting");
local SoundService = game:GetService("SoundService");
local LocalPlayer = Players.LocalPlayer;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local UpdateFontSize = PlayerScripts:WaitForChild("ChatController"):WaitForChild("UpdateFontSize");
local Jukebox = SoundService:WaitForChild("Jukebox");
local Gunshots = SoundService:WaitForChild("Gunshots");
local GunshotReverb = SoundService:WaitForChild("GunshotReverb");
local General = SoundService:WaitForChild("General");

while true do
    local CustomChat = PlayerGui:FindFirstChild("CustomChat");
    CustomChat = CustomChat;
    local u1;

    if CustomChat then
        u1 = CustomChat:FindFirstChild("ChatFrame");
    end;

    if CustomChat and u1 then
        local Signs = ReplicatedStorage:WaitForChild("Signs");

        while not SettingsModule.Settings do
            task.wait();
        end;

        local function v6(p2) -- Line: 51
            -- upvalues: ReplicatedStorage (copy), Signs (copy), SettingsModule (copy), CustomChat (ref), Lighting (copy), Jukebox (copy), Gunshots (copy), GunshotReverb (copy), General (copy), u1 (ref), UpdateFontSize (copy)
            if p2 ~= true and not ReplicatedStorage:GetAttribute("Settings") then
                return;
            end;

            Signs:SetAttribute("ToggleSigns", SettingsModule.GetSetting("General", "Auto Hide All Signs") == true);
            CustomChat:SetAttribute("Hidden", SettingsModule.GetSetting("General", "Hide Chat") == true);
            Lighting.GlobalShadows = SettingsModule.GetSetting("Graphics", "Shadows") == true;
            local v3 = SettingsModule.GetSetting("Sound", "Master Volume");
            Jukebox.Volume = SettingsModule.GetSetting("General", "Mute Jukeboxes") and 0 or SettingsModule.GetSetting("Sound", "Jukebox Volume") * v3;
            Gunshots.Volume = SettingsModule.GetSetting("Sound", "Gunshot Volume") * v3;
            GunshotReverb.Volume = SettingsModule.GetSetting("Sound", "Gunshot Volume") * v3;

            for _, v in { General } do
                v.Volume = SettingsModule.GetSetting("Sound", "SFX Volume") * v3;
            end;

            if u1 then
                local v4 = SettingsModule.GetSetting("General", "Chat Scale");
                local v5 = u1:GetAttribute("BaseSize");
                u1.Size = UDim2.new(v5.X.Scale * v4, 0, v5.Y.Scale * v4, 0);
                task.delay(0.5, function() -- Line: 69
                    -- upvalues: UpdateFontSize (ref)
                    UpdateFontSize:Fire();
                end);
            end;

            ReplicatedStorage:SetAttribute("Settings", nil);
        end;

        ReplicatedStorage:GetAttributeChangedSignal("Settings"):Connect(v6);
        v6(true);

        return;
    end;

    task.wait();
end;