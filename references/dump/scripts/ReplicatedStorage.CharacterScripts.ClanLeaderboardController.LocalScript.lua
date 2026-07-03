-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local LocalPlayer = game:GetService("Players").LocalPlayer;
local Leaderboard = game:GetService("ReplicatedStorage"):WaitForChild("ClientSignals"):WaitForChild("Leaderboard");
local Update = script:WaitForChild("Update");
local u1 = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Inventory"):WaitForChild("Benches"):WaitForChild("Clan Table");
local u2 = {};

local function u8(p3) -- Line: 29
    -- upvalues: u1 (copy), u2 (ref), LocalPlayer (copy)
    local ScrollingFrame = u1:WaitForChild("ScrollingFrame");
    local t = ScrollingFrame:WaitForChild("t");
    local UIGridLayout = ScrollingFrame:WaitForChild("UIGridLayout");
    local v4 = math.ceil(#u2 / 4);
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, v4 * 1, 0);
    UIGridLayout.CellPadding = UDim2.new(0, 0, 0.05 / v4, 0);
    UIGridLayout.CellSize = UDim2.new(0.9, 0, 0.2 / v4, 0);
    local v5 = false;

    for _, child in pairs(ScrollingFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "t" then
            child:Destroy();
        end;
    end;

    for i, v in pairs(u2) do
        local v6 = t:Clone();
        local v7 = v[1] and v7:GetAttribute("ClanTag");

        if v7 then
            v6.Name = i;
            v6.PositionLabel.Text = i;
            v6.ClanTag.Text = v7;
            v6.ClanName.Text = v[2];
            v6.ClanDecal.Image = "rbxassetid://" .. v[3];
            v6.Score.Text = v[4];
            v6.Visible = true;
            v6.Parent = ScrollingFrame;

            if v7 == LocalPlayer:GetAttribute("ClanTag") then
                local YourClan = u1.YourClan;
                YourClan.PositionLabel.Text = i;
                YourClan.ClanTag.Text = v7;
                YourClan.ClanName.Text = v[2];
                YourClan.ClanDecal.Image = "rbxassetid://" .. v[3];
                YourClan.Score.Text = v[4];
                v5 = true;
            end;
        else
            warn("bench model did not have a clan tag attached");
        end;
    end;

    u1.YourClan.Visible = v5;
    u1.NoClan.Visible = not v5;
end;

Leaderboard.OnClientEvent:Connect(function(p9) -- Line: 78
    -- upvalues: u2 (ref)
    u2 = p9;
end);
Update.Event:Connect(function(p10) -- Line: 82
    -- upvalues: u8 (copy)
    u8(p10);
end);

while true do
    u8();
    task.wait(15);
end;