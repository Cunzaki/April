-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_1 = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}};
local ContentProvider_1 = game:GetService("ContentProvider");
for _, value_1 in tbl_1 do
    ContentProvider_1:RegisterEncryptedAsset(value_1.id, value_1.secret);
end;
local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local _ = game:GetService("UserInputService");
local LocalPlayer_1 = Players_1.LocalPlayer;
local ClientSignals_1 = ReplicatedStorage_1:WaitForChild("ClientSignals");
local Boombox_upv_1 = LocalPlayer_1.PlayerGui:WaitForChild("Boombox");
local v1 = LocalPlayer_1.Character or (LocalPlayer_1.CharacterAdded:Wait());
shared.LastJukebox = nil;
local Toggle_upv_1 = v1:WaitForChild("InventoryController"):WaitForChild("Toggle");
ClientSignals_1.Radio.OnClientEvent:Connect(
    function(a1)
        --[[
          line: 63
          upvalues:
            Toggle_upv_1 (copy, index: 1)
            Boombox_upv_1 (copy, index: 2)
        ]]
        shared.LastJukebox = a1;
        Toggle_upv_1:Fire("Inventory");
        Boombox_upv_1.Enabled = true;
    end
);