-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local _ = game:GetService("UserInputService");
local v38 = game:GetService("RunService");
local Lighting_1 = game:GetService("Lighting");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local v39 = require(Modules_1:WaitForChild("Items"));
local TweenUtil_upv_1 = require(Modules_1:WaitForChild("TweenUtil"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local StatusClass_1 = require(Modules_1:WaitForChild("StatusClass"));
local v40 = require(Modules_1:WaitForChild("RaycastUtil"));
local ViewportModule_upv_1 = require(Modules_1:WaitForChild("ViewportModule"));
local v1 = require(Modules_1:WaitForChild("AssetContainer"))();
local Blur_upv_1 = Lighting_1:WaitForChild("Blur");
local ColorCorrection_upv_1 = Lighting_1:WaitForChild("ColorCorrection");
local Radiation_upv_1 = script:WaitForChild("Radiation");
local CraftUpdate_1 = script:WaitForChild("CraftUpdate");
local LocalPlayer_upv_1 = Players_1.LocalPlayer;
local PlayerGui_1 = LocalPlayer_upv_1:WaitForChild("PlayerGui");
local Humanoid_upv_1 = script.Parent:WaitForChild("Humanoid");
local Main_1 = PlayerGui_1:WaitForChild("Main");
local Stats_upv_1 = Main_1:WaitForChild("Stats");
local v41 = Stats_upv_1:WaitForChild("Health");
local v42 = Stats_upv_1:WaitForChild("Hunger");
local v43 = Stats_upv_1:WaitForChild("Thirst");
local Cold_upv_1 = Main_1:WaitForChild("Cold");
local Hot_upv_1 = Main_1:WaitForChild("Hot");
local Armor_upv_1 = Main_1:WaitForChild("Inventory"):WaitForChild("Armor");
local ViewportFrame_upv_1 = Armor_upv_1:WaitForChild("ViewportFrame");
local HitboxHead_1 = Armor_upv_1:WaitForChild("HitboxHead");
local HitboxChest_1 = Armor_upv_1:WaitForChild("HitboxChest");
local HitboxLegs_1 = Armor_upv_1:WaitForChild("HitboxLegs");
local BulletBars_upv_1 = Armor_upv_1:WaitForChild("BulletBars");
local BulletDetail_upv_1 = Armor_upv_1:WaitForChild("BulletDetail");
local MeleeBars_upv_1 = Armor_upv_1:WaitForChild("MeleeBars");
local MeleeDetail_upv_1 = Armor_upv_1:WaitForChild("MeleeDetail");
local u1 = StatusClass_1.new();
local tbl_upv_1 = {};
local tbl_upv_2 = {};
tbl_upv_2.BCAccess = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.BCDenied = {Color = Color3.fromRGB(255, 66, 69)};
tbl_upv_2.Safezone = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.Recipes = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.Comfort = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.Craft = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.Wet = {Color = Color3.fromRGB(255, 66, 69)};
tbl_upv_2.Drowning = {Color = Color3.fromRGB(255, 66, 69)};
tbl_upv_2.Temperature = {Color = Color3.fromRGB(255, 66, 69)};
tbl_upv_2.Bleed = {Color = Color3.fromRGB(255, 66, 69)};
tbl_upv_2.Radiation = {Color = Color3.fromRGB(182, 179, 89)};
tbl_upv_2.Pickup = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.Drop = {Color = Color3.fromRGB(255, 94, 0)};
tbl_upv_2.Decay = {Color = Color3.fromRGB(255, 94, 0)};
tbl_upv_2.Health_Buff = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.Node_Buff = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.Wood_Buff = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.Caps_Buff = {Color = Color3.fromRGB(89, 148, 64)};
tbl_upv_2.Regen_Buff = {Color = Color3.fromRGB(89, 148, 64)};
local tbl_upv_3 = {};
tbl_upv_3.Radiation = {};
tbl_upv_3.Health = {};
local v44 = tick();
local v2 = tick();
local v3 = tick();
local tbl_upv_4 = {};
local tbl_upv_5 = {};
tbl_upv_5.Head = {};
tbl_upv_5.Chest = {};
tbl_upv_5.Legs = {};
local u2 = "";
local function u3(a1, a2)
    --[[
      line: 241
      upvalues:
        TweenUtil_upv_1 (copy, index: 1)
    ]]
    for key_1, value_1 in pairs(a1:GetAttributes()) do
        if (pcall(function()
            --[[
              line: 244
            ]]
        end)) then
            TweenUtil_upv_1:Tween(a1, key_1, (a2 and value_1) or 1, 0.4);
        end;
    end;
end;
local function u4(a1, a2)
    --[[
      line: 202
      upvalues:
        NumberUtil_upv_1 (copy, index: 1)
    ]]
    if (string.find(a2, "Pickup")) then
        return "+" .. math.ceil(a1);
    elseif (string.find(a2, "Drop")) then
        return "-" .. math.ceil(a1);
    elseif (a2 == "Wet") then
        return "" .. math.ceil(a1) .. "%";
    elseif (a2 == "Drowning") then
        return "X";
    elseif (a2 ~= "BCAccess") then
        if (a2 ~= "BCDenied" and a2 ~= "Decay") then
            if (a2 ~= "Craft") then
                if (a2 ~= "Safezone") then
                    if (a2 ~= "Temperature") then
                        if (a2 ~= "Comfort") then
                            if (string.find(a2, "Buff")) then
                                local v4;
                                if (a1 ~= -1) then
                                    v4 = a1;
                                else
                                    v4 = 0;
                                end;
                                return NumberUtil_upv_1:FormatTime(v4, "Minutes", "Seconds", true, 2);
                            end;
                            return (tostring(math.ceil(a1)));
                        end;
                        return "" .. math.ceil(a1) .. "%";
                    end;
                    return "" .. math.ceil(a1) .. "\194\176C";
                end;
                return "X";
            end;
            return a1 .. "s";
        end;
        return "X";
    else
        local v5;
        if (a1 ~= -1) then
            v5 = a1;
        else
            v5 = 0;
        end;
        return NumberUtil_upv_1:FormatTime(v5, "Days", "Minutes", true, 2);
    end;
end;
local function u5(a1, a2)
    --[[
      line: 253
      upvalues:
        u3 (copy, index: 1)
    ]]
    u3(a2, a1);
    for _, value_2 in pairs(a2:GetChildren()) do
        u3(value_2, a1);
    end;
end;
local function u6()
    --[[
      line: 261
      upvalues:
        u1 (copy, index: 1)
        Stats_upv_1 (copy, index: 2)
        TweenUtil_upv_1 (copy, index: 3)
        tbl_upv_2 (copy, index: 4)
        u2 (ref,  index: 5)
        u4 (copy, index: 6)
        u5 (copy, index: 7)
    ]]
    local tbl_6 = {"I", "II", "III", "IV"};
    local v6 = u1:GetStatsPickupTableCombined();
    local Position_1 = Stats_upv_1.Template.Position;
    local v7, _ = nil, nil;
    local v8 = nil;
    local v9 = nil;
    local v10 = nil;
    local v15 = nil;
    local v11 = nil;
    local v12 = nil;
    for key_2, value_3 in pairs(v6) do
        v8 = false;
        if (string.find(value_3[1], "Buff")) then
            local v16 = true;
        end;
        v9 = Stats_upv_1:FindFirstChild(value_3[1]);
        if (v9) then
            v7 = ((typeof(value_3[2]) == "table") and (value_3[2][2])) or (value_3[2]);
            v9:SetAttribute("Reach", v7);
            if (key_2 ~= v9:GetAttribute("Index")) then
                v9:SetAttribute("Index", key_2);
                TweenUtil_upv_1:Tween(v9, "Position", UDim2.new(Position_1.X.Scale, 0, Position_1.Y.Scale - (0.04 * (key_2 - 1)), 0), 0.4);
            end;
            if (v8) then
                v11 = tbl_upv_2[value_3[1]];
                v9.StatLabel.Text = (v11 and (v11.Name)) or (value_3[1]);
                v9.StatLabel.Text = (v8 and (v9.StatLabel.Text .. " " .. tbl_6[value_3[2][1]])) or (v9.StatLabel.Text);
            end;
        else
            v7 = tbl_upv_2[value_3[1]];
            if (string.find(value_3[1], "Pickup")) then
                v7 = tbl_upv_2.Pickup;
            else
                v12 = string.find(value_3[1], "Drop");
                if (v12) then
                    v7 = tbl_upv_2.Drop;
                end;
            end;
            if (not (v7)) then
                continue;
            end;
            v12 = Stats_upv_1.Template:Clone();
            v12.Color.BackgroundColor3 = v7.Color;
            v12.Name = value_3[1];
            if (v7.Remove == nil) then
                v12.StatLabel.Text = value_3[1];
            else
                v11 = string.gsub(value_3[1], v7.Remove, "");
                v10 = v12.StatLabel;
                local v13;
                if (v11:find(" Trophy")) then
                    v13 = "Bone Trophy";
                else
                    v13 = v11;
                end;
                v10.Text = v13;
            end;
            v12.StatLabel.Text = ((v7.Name == "Craft") and u2) or (((v7.Name ~= nil) and (v7.Name)) or (v12.StatLabel.Text));
            local StatLabel_1 = v12.StatLabel;
            if (v8) then
                if (v7.SkipLabelNumber) then
                    v10 = v12.StatLabel.Text;
                else
                    v10 = v12.StatLabel.Text .. " " .. tbl_6[value_3[2][1]];
                    v10 = v10 or v12.StatLabel.Text;
                end;
            else
                v10 = v12.StatLabel.Text;
            end;
            StatLabel_1.Text = v10;
            v11 = (v8 and (value_3[2][2])) or (value_3[2]);
            v10 = u4(v11, value_3[1]);
            if (v10 == "X") then
                v12.BackColor.Visible = false;
                v12.Num.Visible = false;
            end;
            v12.Num.Text = v10;
            v12:SetAttribute("CurrentNum", v11);
            v12:SetAttribute("Reach", v11);
            v12:SetAttribute("Index", key_2);
            v12.Parent = Stats_upv_1;
            v12.Position = UDim2.new(Position_1.X.Scale, 0, Position_1.Y.Scale - (0.04 * (key_2 - 1)), 0);
            u5(true, v12);
        end;
    end;
    local Name_1 = nil;
    local v14 = nil;
    for v17, value_4 in pairs(Stats_upv_1:GetChildren()) do
        v14 = u1:GetIndexOfStat(value_4.Name);
        Name_1 = value_4.Name;
        if (not (v14)) then
            continue;
        end;
        if (Name_1 == "Health" or Name_1 ~= "Health" and Name_1 == "Hunger" or Name_1 ~= "Health" and Name_1 ~= "Hunger" and Name_1 == "Thirst" or Name_1 ~= "Health" and Name_1 ~= "Hunger" and Name_1 ~= "Thirst" and Name_1 == "Template" or Name_1 ~= "Health" and Name_1 ~= "Hunger" and Name_1 ~= "Thirst" and Name_1 ~= "Template" and not string.find(Name_1, "Pickup") and not string.find(Name_1, "Drop")) then
            v7 = false;
            for v18, value_5 in pairs(v6) do
                if (value_5[1] == Name_1) then
                    v7 = true;
                end;
            end;
            if (v7) then
                continue;
            end;
            if (value_4) then
                value_4:Destroy();
            end;
        end;
    end;
end;
local function u7(a1, a2)
    --[[
      line: 408
    ]]
    local value_6 = nil;
    for _, value_6 in pairs(a1:GetChildren()) do
        if (value_6:IsA("Frame")) then
            value_6.BackgroundColor3 = a2;
            value_6.Fill.BackgroundColor3 = a2;
        end;
    end;
end;
local function u8(a1, a2)
    --[[
      line: 416
      upvalues:
        u7 (copy, index: 1)
    ]]
    if (a2 >= 0 or not (a1:GetAttribute("ColorNegative"))) then
        if (a1:GetAttribute("ColorPositive") ~= nil) then
            u7(a1, a1:GetAttribute("ColorPositive"));
        end;
    else
        a2 = a2 * -1;
        u7(a1, a1:GetAttribute("ColorNegative"));
    end;
    local v15 = math.ceil(a2 / 10);
    for n_1 = 1, 10 do
        local v16 = ((n_1 >= 10) and (tostring(n_1))) or ("0" .. n_1);
        local v17 = a1:FindFirstChild(v16);
        local v18 = ((v15 < n_1) and 0) or (math.min((a2 - ((n_1 - 1) * 10)) / 10, 1));
        v17.Fill.Size = UDim2.new(v18, 0, 1, 0);
    end;
end;
HitboxHead_1.MouseEnter:Connect(
    function()
        --[[
          line: 494
          upvalues:
            u8 (copy, index: 1)
            BulletBars_upv_1 (copy, index: 2)
            tbl_upv_5 (copy, index: 3)
            MeleeBars_upv_1 (copy, index: 4)
            BulletDetail_upv_1 (copy, index: 5)
            MeleeDetail_upv_1 (copy, index: 6)
            ViewportModule_upv_1 (copy, index: 7)
            ViewportFrame_upv_1 (copy, index: 8)
        ]]
        u8(BulletBars_upv_1, tbl_upv_5.Head.Bullet);
        u8(MeleeBars_upv_1, tbl_upv_5.Head.Melee);
        BulletBars_upv_1.Visible = true;
        BulletDetail_upv_1.Visible = true;
        MeleeBars_upv_1.Visible = true;
        MeleeDetail_upv_1.Visible = true;
        ViewportModule_upv_1:HighlightCharArea(ViewportFrame_upv_1, "Head");
    end
);
HitboxHead_1.MouseLeave:Connect(
    function()
        --[[
          line: 498
          upvalues:
            BulletBars_upv_1 (copy, index: 1)
            BulletDetail_upv_1 (copy, index: 2)
            MeleeBars_upv_1 (copy, index: 3)
            MeleeDetail_upv_1 (copy, index: 4)
            ViewportModule_upv_1 (copy, index: 5)
            ViewportFrame_upv_1 (copy, index: 6)
        ]]
        BulletBars_upv_1.Visible = false;
        BulletDetail_upv_1.Visible = false;
        MeleeBars_upv_1.Visible = false;
        MeleeDetail_upv_1.Visible = false;
        ViewportModule_upv_1:HighlightCharArea(ViewportFrame_upv_1);
    end
);
HitboxChest_1.MouseEnter:Connect(
    function()
        --[[
          line: 503
          upvalues:
            u8 (copy, index: 1)
            BulletBars_upv_1 (copy, index: 2)
            tbl_upv_5 (copy, index: 3)
            MeleeBars_upv_1 (copy, index: 4)
            BulletDetail_upv_1 (copy, index: 5)
            MeleeDetail_upv_1 (copy, index: 6)
            ViewportModule_upv_1 (copy, index: 7)
            ViewportFrame_upv_1 (copy, index: 8)
        ]]
        u8(BulletBars_upv_1, tbl_upv_5.Chest.Bullet);
        u8(MeleeBars_upv_1, tbl_upv_5.Chest.Melee);
        BulletBars_upv_1.Visible = true;
        BulletDetail_upv_1.Visible = true;
        MeleeBars_upv_1.Visible = true;
        MeleeDetail_upv_1.Visible = true;
        ViewportModule_upv_1:HighlightCharArea(ViewportFrame_upv_1, "Chest");
    end
);
HitboxChest_1.MouseLeave:Connect(
    function()
        --[[
          line: 507
          upvalues:
            BulletBars_upv_1 (copy, index: 1)
            BulletDetail_upv_1 (copy, index: 2)
            MeleeBars_upv_1 (copy, index: 3)
            MeleeDetail_upv_1 (copy, index: 4)
            ViewportModule_upv_1 (copy, index: 5)
            ViewportFrame_upv_1 (copy, index: 6)
        ]]
        BulletBars_upv_1.Visible = false;
        BulletDetail_upv_1.Visible = false;
        MeleeBars_upv_1.Visible = false;
        MeleeDetail_upv_1.Visible = false;
        ViewportModule_upv_1:HighlightCharArea(ViewportFrame_upv_1);
    end
);
HitboxLegs_1.MouseEnter:Connect(
    function()
        --[[
          line: 512
          upvalues:
            u8 (copy, index: 1)
            BulletBars_upv_1 (copy, index: 2)
            tbl_upv_5 (copy, index: 3)
            MeleeBars_upv_1 (copy, index: 4)
            BulletDetail_upv_1 (copy, index: 5)
            MeleeDetail_upv_1 (copy, index: 6)
            ViewportModule_upv_1 (copy, index: 7)
            ViewportFrame_upv_1 (copy, index: 8)
        ]]
        u8(BulletBars_upv_1, tbl_upv_5.Legs.Bullet);
        u8(MeleeBars_upv_1, tbl_upv_5.Legs.Melee);
        BulletBars_upv_1.Visible = true;
        BulletDetail_upv_1.Visible = true;
        MeleeBars_upv_1.Visible = true;
        MeleeDetail_upv_1.Visible = true;
        ViewportModule_upv_1:HighlightCharArea(ViewportFrame_upv_1, "Legs");
    end
);
HitboxLegs_1.MouseLeave:Connect(
    function()
        --[[
          line: 516
          upvalues:
            BulletBars_upv_1 (copy, index: 1)
            BulletDetail_upv_1 (copy, index: 2)
            MeleeBars_upv_1 (copy, index: 3)
            MeleeDetail_upv_1 (copy, index: 4)
            ViewportModule_upv_1 (copy, index: 5)
            ViewportFrame_upv_1 (copy, index: 6)
        ]]
        BulletBars_upv_1.Visible = false;
        BulletDetail_upv_1.Visible = false;
        MeleeBars_upv_1.Visible = false;
        MeleeDetail_upv_1.Visible = false;
        ViewportModule_upv_1:HighlightCharArea(ViewportFrame_upv_1);
    end
);
LocalPlayer_upv_1:GetAttributeChangedSignal("SafeZone"):Connect(
    function()
        --[[
          line: 521
          upvalues:
            LocalPlayer_upv_1 (copy, index: 1)
            u1 (copy, index: 2)
        ]]
        if (LocalPlayer_upv_1:GetAttribute("SafeZone")) then
            u1:InsertStat("Safezone", 1);
        else
            u1:UpdateStat("Safezone", 0);
        end;
    end
);
CraftUpdate_1.Event:Connect(
    function(a1, a2, a3)
        --[[
          line: 531
          upvalues:
            u1 (copy, index: 1)
            u2 (ref,  index: 2)
            u6 (copy, index: 3)
        ]]
        if (a1 ~= "UpdateRecipes") then
            if (a1 == "UpdateCraft") then
                u2 = a2;
                u1:InsertStat("Craft", a3);
            elseif (a1 == "RemoveCraft") then
                u1:InsertStat("Craft", 0);
            end;
            u6();
        elseif (a2 > 0) then
            u1:InsertStat("Recipes", a2);
        else
            u1:InsertStat("Recipes", 0);
        end;
    end
);
local function u9(a1)
    --[[
      line: 351
      upvalues:
        u1 (copy, index: 1)
        Stats_upv_1 (copy, index: 2)
        Humanoid_upv_1 (copy, index: 3)
        TweenUtil_upv_1 (copy, index: 4)
        tbl_upv_1 (copy, index: 5)
        u6 (copy, index: 6)
        NumberUtil_upv_1 (copy, index: 7)
        Radiation_upv_1 (copy, index: 8)
        tbl_upv_3 (copy, index: 9)
        Blur_upv_1 (copy, index: 10)
        ColorCorrection_upv_1 (copy, index: 11)
        Cold_upv_1 (copy, index: 12)
        Hot_upv_1 (copy, index: 13)
    ]]
    u1:CompareServerTable(a1);
    local Health_1 = Stats_upv_1:FindFirstChild("Health");
    local Health_2 = Humanoid_upv_1.Health;
    local Bar_1 = Health_1.Bar;
    TweenUtil_upv_1:Tween(Bar_1.Fill, "Size", UDim2.new(math.clamp(Health_2 / 100, 0, 1), 0, 1, 0), 0.4);
    Bar_1.StatLabel.Text = tostring(math.ceil(Health_2));
    local v19 = nil;
    local v20 = nil;
    for key_3, value_7 in pairs(a1) do
        v19 = Stats_upv_1:FindFirstChild(key_3);
        if (v19) then
            if (key_3 == "Hunger") then
                v20 = v19.Bar;
                TweenUtil_upv_1:Tween(v20.Fill, "Size", UDim2.new(value_7 / tbl_upv_1[key_3], 0, 1, 0), 0.4);
                v20.StatLabel.Text = tostring(math.ceil(value_7));
                continue;
            end;
            if (key_3 == "Thirst") then
                v20 = v19.Bar;
                TweenUtil_upv_1:Tween(v20.Fill, "Size", UDim2.new(value_7 / tbl_upv_1[key_3], 0, 1, 0), 0.4);
                v20.StatLabel.Text = tostring(math.ceil(value_7));
                continue;
            end;
        end;
        if (key_3 == "HQueue") then
            TweenUtil_upv_1:Tween(Stats_upv_1.Health.Bar.HQueue, "Size", UDim2.new(math.clamp((Humanoid_upv_1.Health + value_7) / 100, 0, 1), 0, 1, 0), 0.4);
        end;
    end;
    u6();
    local v21 = (Stats_upv_1:FindFirstChild("Radiation") and (Stats_upv_1.Radiation:GetAttribute("Reach"))) or 0;
    local v22 = v21 / 120;
    local v23 = math.clamp(NumberUtil_upv_1:Lerp(0.8, 1.3, v22), 0.8, 1.3);
    local key_3 = math.clamp(NumberUtil_upv_1:Lerp(0.9, 1.2, v22), 0.9, 1.2);
    Radiation_upv_1.Volume = v23;
    Radiation_upv_1.PlaybackSpeed = key_3;
    if (v21 <= 0) then
        Radiation_upv_1:Stop();
    else
        Radiation_upv_1:Play();
    end;
    local v24 = ((Health_2 <= 40) and (tbl_upv_3.Health.BlurSize - (Health_2 / 40) * tbl_upv_3.Health.BlurSize)) or 0;
    local v25 = ((v21 >= 15) and (math.clamp((v21 / 120) * tbl_upv_3.Radiation.BlurSize, 0, tbl_upv_3.Radiation.BlurSize))) or 0;
    if (v25 > v24 or not (v24)) then

    end;
    v20 = ((Health_2 <= 40) and (255 - (tbl_upv_3.Health.ColorCorrectionLowest - ((Health_2 / 40) * tbl_upv_3.Health.ColorCorrectionLowest)))) or 255;
    local v26 = ((v21 >= 15) and (math.clamp(255 - ((v21 / 120) * tbl_upv_3.Radiation.ColorCorrectionLowest), tbl_upv_3.Radiation.ColorCorrectionLowest, 255))) or 255;
    local v27;
    if (v20 > v26 or not (v20)) then
        v27 = v26;
    else
        v27 = v20;
    end;
    Blur_upv_1.Size = nil;
    ColorCorrection_upv_1.TintColor = Color3.fromRGB(v27, v27, v27);
    local v28 = (Stats_upv_1:FindFirstChild("Temperature") and (Stats_upv_1.Temperature:GetAttribute("Reach"))) or 0;
    local v29;
    if (v28 <= -8) then
        v29 = true;
    else
        v29 = false;
    end;
    Cold_upv_1.Visible = v29;
    Hot_upv_1.Visible = v28 >= 29;
end;
v1(
    "Setup",
    "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145",
    "s*\016a\192\2250C\152\156\243g\250hL\178\001\205\248!",
    function(a1, a2)
        --[[
          line: 558
          upvalues:
            u9 (copy, index: 1)
            tbl_upv_5 (copy, index: 2)
            Armor_upv_1 (copy, index: 3)
            u8 (copy, index: 4)
        ]]
        if (a1 ~= nil) then
            u9(a1);
        end;
        if (a2 ~= nil) then
            local v30 = nil;
            for key_4, value_8 in pairs(a2) do
                if (key_4 == "Head" or key_4 == "Chest" or key_4 == "Legs") then
                    tbl_upv_5[key_4].Bullet = value_8.Bullet;
                    tbl_upv_5[key_4].Melee = value_8.Melee;
                    continue;
                end;
                v30 = Armor_upv_1:FindFirstChild(key_4 .. "Bars");
                if (v30) then
                    u8(v30, value_8);
                else
                    print("BAR CONTAINER NOT FOUND FOR " .. key_4);
                end;
            end;
        end;
    end
);
v1(
    "Setup",
    "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145",
    "\159\132\143\252\001]\204\184\151\141\207\171\176J\191\252\164Bn\175",
    function(a1, a2)
        --[[
          line: 577
          upvalues:
            tbl_upv_4 (copy, index: 1)
            u6 (copy, index: 2)
        ]]
        table.insert(tbl_upv_4, a1);
        u6();
    end
);
Blur_upv_1.Size = 0;
ColorCorrection_upv_1.TintColor = Color3.fromRGB(255, 255, 255);
v1("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "s*\016a\192\2250C\152\156\243g\250hL\178\001\205\248!");
v2, v3 = v2, v3;
local v31 = false;
if (tick() - v2 < 0.2) then
    local u10 = nil;
    for v45, value_9 in pairs(u1:GetPickups()) do
        if (tick() - value_9[3] < 5) then
            continue;
        end;
        u10 = Stats_upv_1:FindFirstChild(value_9[1]);
        if (u10) then
            delay(
                0.4,
                function()
                    --[[
                      line: 608
                      upvalues:
                        u10 (copy, index: 1)
                    ]]
                    u10:Destroy();
                end
            );
            u5(false, u10);
        end;
        u1:RemovePickup(value_9[1]);
        v31 = true;
    end;
    if (tick() - v3 >= 0.06) then
        v3 = tick();
        local v32 = nil;
        local tbl_7 = nil;
        local v33 = nil;
        local v34 = nil;
        local v35 = nil;
        for v46, value_10 in pairs(Stats_upv_1:GetChildren()) do
            tbl_7 = {"Health", "Hunger", "Thirst", "Template"};
            v32 = false;
            for v47, value_11 in pairs(tbl_7) do
                if (value_10.Name == value_11) then
                    v32 = true;
                    break;
                end;
            end;
            if (v32) then
                continue;
            end;
            v33 = value_10:GetAttribute("CurrentNum");
            v34 = value_10:GetAttribute("Reach");
            v35 = value_10.Num;
            if (not (v34) or v33 == v34) then
                continue;
            end;
            if (v34 - 0.4 > v33) then
                local v36 = NumberUtil_upv_1:Lerp(v33, v34, 0.45);
                value_10:SetAttribute("CurrentNum", v36);
                v35.Text = u4(v36, value_10.Name);
            else
                value_10:SetAttribute("CurrentNum", v34);
                v35.Text = u4(v34, value_10.Name);
            end;
        end;
    end;
    if (v31) then
        u6();
    end;
    if (#u1:GetPickups() > 0) then
        wait();
    else
        wait(0.5);
    end;
else
    v2 = tick();
    local v37 = tbl_upv_4[1];
    if (v37) then
        table.remove(tbl_upv_4, 1);
        u1:InsertStat(v37[1], v37[2]);
        v31 = true;
    end;
    local u10 = nil;
    for v45, value_9 in pairs(u1:GetPickups()) do
        if (tick() - value_9[3] < 5) then
            continue;
        end;
        u10 = Stats_upv_1:FindFirstChild(value_9[1]);
        if (u10) then
            delay(
                0.4,
                function()
                    --[[
                      line: 608
                      upvalues:
                        u10 (copy, index: 1)
                    ]]
                    u10:Destroy();
                end
            );
            u5(false, u10);
        end;
        u1:RemovePickup(value_9[1]);
        v31 = true;
    end;
    if (tick() - v3 >= 0.06) then
        v3 = tick();
        local v32 = nil;
        local tbl_7 = nil;
        local v33 = nil;
        local v34 = nil;
        local v35 = nil;
        for v46, value_10 in pairs(Stats_upv_1:GetChildren()) do
            tbl_7 = {"Health", "Hunger", "Thirst", "Template"};
            v32 = false;
            for v47, value_11 in pairs(tbl_7) do
                if (value_10.Name == value_11) then
                    v32 = true;
                    break;
                end;
            end;
            if (v32) then
                continue;
            end;
            v33 = value_10:GetAttribute("CurrentNum");
            v34 = value_10:GetAttribute("Reach");
            v35 = value_10.Num;
            if (not (v34) or v33 == v34) then
                continue;
            end;
            if (v34 - 0.4 > v33) then
                local v36 = NumberUtil_upv_1:Lerp(v33, v34, 0.45);
                value_10:SetAttribute("CurrentNum", v36);
                v35.Text = u4(v36, value_10.Name);
            else
                value_10:SetAttribute("CurrentNum", v34);
                v35.Text = u4(v34, value_10.Name);
            end;
        end;
    end;
    if (not v31) then
        return;
    end;
    u6();
end;