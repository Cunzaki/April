-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local LocalPlayer_upv_1 = game:GetService("Players").LocalPlayer;
local Leaderboard_1 = game:GetService("ReplicatedStorage"):WaitForChild("ClientSignals"):WaitForChild("Leaderboard");
local Update_1 = script:WaitForChild("Update");
local u1 = LocalPlayer_upv_1:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Inventory"):WaitForChild("Benches"):WaitForChild("Clan Table");
local u2 = {};
local function u3(a1)
    --[[
      line: 29
      upvalues:
        u1 (copy, index: 1)
        u2 (ref,  index: 2)
        LocalPlayer_upv_1 (copy, index: 3)
    ]]
    local v1 = false;
    local ScrollingFrame_1 = u1:WaitForChild("ScrollingFrame");
    local t_1 = ScrollingFrame_1:WaitForChild("t");
    local UIGridLayout_1 = ScrollingFrame_1:WaitForChild("UIGridLayout");
    local v2 = math.ceil(#u2 / 4);
    ScrollingFrame_1.CanvasSize = UDim2.new(0, 0, v2 * 1, 0);
    UIGridLayout_1.CellPadding = UDim2.new(0, 0, 0.05 / v2, 0);
    UIGridLayout_1.CellSize = UDim2.new(0.9, 0, 0.2 / v2, 0);
    for _, value_1 in pairs(ScrollingFrame_1:GetChildren()) do
        if (not (value_1:IsA("Frame"))) then
            continue;
        end;
        if (value_1.Name ~= "t") then
            value_1:Destroy();
        end;
    end;
    local v3 = nil;
    local v4 = nil;
    local v5 = nil;
    for key_1, value_2 in pairs(u2) do
        v3 = t_1:Clone();
        v4 = value_2[1];
        v5 = v4 and (v4:GetAttribute("ClanTag"));
        if (not (v5)) then
            warn("bench model did not have a clan tag attached");
            continue;
        end;
        v3.Name = key_1;
        v3.PositionLabel.Text = key_1;
        v3.ClanTag.Text = v5;
        v3.ClanName.Text = value_2[2];
        v3.ClanDecal.Image = "rbxassetid://" .. value_2[3];
        v3.Score.Text = value_2[4];
        v3.Visible = true;
        v3.Parent = ScrollingFrame_1;
        if (v5 == LocalPlayer_upv_1:GetAttribute("ClanTag")) then
            local v6 = true;
            local YourClan_1 = u1.YourClan;
            YourClan_1.PositionLabel.Text = key_1;
            YourClan_1.ClanTag.Text = v5;
            YourClan_1.ClanName.Text = value_2[2];
            YourClan_1.ClanDecal.Image = "rbxassetid://" .. value_2[3];
            YourClan_1.Score.Text = value_2[4];
            v1 = v6;
        end;
    end;
    u1.YourClan.Visible = v1;
    u1.NoClan.Visible = not v1;
end;
Leaderboard_1.OnClientEvent:Connect(
    function(a1)
        --[[
          line: 78
          upvalues:
            u2 (ref, index: 1)
        ]]
        u2 = a1;
    end
);
Update_1.Event:Connect(
    function(a1)
        --[[
          line: 82
          upvalues:
            u3 (copy, index: 1)
        ]]
        u3(a1);
    end
);
u3();
task.wait(15);