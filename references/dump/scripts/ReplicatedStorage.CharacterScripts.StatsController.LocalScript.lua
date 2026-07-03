-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
game:GetService("UserInputService");
game:GetService("RunService");
local Lighting = game:GetService("Lighting");
local Modules = ReplicatedStorage:WaitForChild("Modules");
require(Modules:WaitForChild("Items"));
local TweenUtil = require(Modules:WaitForChild("TweenUtil"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local StatusClass = require(Modules:WaitForChild("StatusClass"));
require(Modules:WaitForChild("RaycastUtil"));
local ViewportModule = require(Modules:WaitForChild("ViewportModule"));
local v1 = require(Modules:WaitForChild("AssetContainer"))();
local Blur = Lighting:WaitForChild("Blur");
local ColorCorrection = Lighting:WaitForChild("ColorCorrection");
local Radiation = script:WaitForChild("Radiation");
local CraftUpdate = script:WaitForChild("CraftUpdate");
local LocalPlayer = Players.LocalPlayer;
local Parent = script.Parent;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local Humanoid = Parent:WaitForChild("Humanoid");
local _ = workspace.CurrentCamera;
local Main = PlayerGui:WaitForChild("Main");
local Stats = Main:WaitForChild("Stats");
Stats:WaitForChild("Health");
Stats:WaitForChild("Hunger");
Stats:WaitForChild("Thirst");
local Cold = Main:WaitForChild("Cold");
local Hot = Main:WaitForChild("Hot");
local Armor = Main:WaitForChild("Inventory"):WaitForChild("Armor");
local ViewportFrame = Armor:WaitForChild("ViewportFrame");
local HitboxHead = Armor:WaitForChild("HitboxHead");
local HitboxChest = Armor:WaitForChild("HitboxChest");
local HitboxLegs = Armor:WaitForChild("HitboxLegs");
local BulletBars = Armor:WaitForChild("BulletBars");
local BulletDetail = Armor:WaitForChild("BulletDetail");
local MeleeBars = Armor:WaitForChild("MeleeBars");
local MeleeDetail = Armor:WaitForChild("MeleeDetail");
local u2 = StatusClass.new();
local u3 = {
    Health = 100,
    Hunger = 100,
    Thirst = 100,
    Bleeding = 100,
    Radiation = 499,
    Comfort = 100,
    Wet = 100,
    Temperature = 40
};
local u4 = {
    BCAccess = {
        Name = "Building Privilege",
        Color = Color3.fromRGB(89, 148, 64)
    },
    BCDenied = {
        Name = "Building Blocked",
        Color = Color3.fromRGB(255, 66, 69)
    },
    Safezone = {
        Name = "Safezone!",
        Color = Color3.fromRGB(89, 148, 64)
    },
    Recipes = {
        Name = "Recipes Available",
        Color = Color3.fromRGB(89, 148, 64)
    },
    Comfort = {
        Color = Color3.fromRGB(89, 148, 64)
    },
    Craft = {
        Name = "Craft",
        Color = Color3.fromRGB(89, 148, 64)
    },
    Wet = {
        Color = Color3.fromRGB(255, 66, 69)
    },
    Drowning = {
        Color = Color3.fromRGB(255, 66, 69)
    },
    Temperature = {
        Color = Color3.fromRGB(255, 66, 69)
    },
    Bleed = {
        Name = "Bleeding",
        Color = Color3.fromRGB(255, 66, 69)
    },
    Radiation = {
        Color = Color3.fromRGB(182, 179, 89)
    },
    Pickup = {
        Remove = "Pickup",
        Color = Color3.fromRGB(89, 148, 64)
    },
    Drop = {
        Remove = "Drop",
        Color = Color3.fromRGB(255, 94, 0)
    },
    Decay = {
        Name = "Building Decaying!",
        Color = Color3.fromRGB(255, 94, 0)
    },
    Health_Buff = {
        Name = "Health Buff",
        Color = Color3.fromRGB(89, 148, 64)
    },
    Node_Buff = {
        Name = "Mining Buff",
        Color = Color3.fromRGB(89, 148, 64)
    },
    Wood_Buff = {
        Name = "Chopping Buff",
        Color = Color3.fromRGB(89, 148, 64)
    },
    Caps_Buff = {
        Name = "Barrel Caps Buff",
        Color = Color3.fromRGB(89, 148, 64)
    },
    Regen_Buff = {
        Name = "Regeneration Buff",
        SkipLabelNumber = true,
        Color = Color3.fromRGB(89, 148, 64)
    }
};
local u5 = {
    Radiation = {
        BlurSize = 8,
        ColorCorrectionLowest = 83
    },
    Health = {
        BlurSize = 4,
        ColorCorrectionLowest = 83
    }
};
tick();
local v6 = tick();
local v7 = tick();
local u8 = {};
local u9 = {
    Head = {
        Bullet = 0,
        Melee = 0
    },
    Chest = {
        Bullet = 0,
        Melee = 0
    },
    Legs = {
        Bullet = 0,
        Melee = 0
    }
};
local u10 = "";

local function u14(p11, p12) -- Line: 202
    -- upvalues: NumberUtil (copy)
    if string.find(p12, "Pickup") then
        return "+" .. math.ceil(p11);
    end;

    if string.find(p12, "Drop") then
        return "-" .. math.ceil(p11);
    end;

    if p12 == "Wet" then
        return "" .. math.ceil(p11) .. "%";
    end;

    if p12 == "Drowning" then
        return "X";
    end;

    if p12 == "BCAccess" then
        return NumberUtil:FormatTime(p11 == -1 and 0 or p11, "Days", "Minutes", true, 2);
    end;

    if p12 == "BCDenied" then
        return "X";
    end;

    if p12 == "Decay" then
        return "X";
    end;

    if p12 == "Craft" then
        return p11 .. "s";
    end;

    if p12 == "Safezone" then
        return "X";
    end;

    if p12 == "Temperature" then
        return "" .. math.ceil(p11) .. "°C";
    end;

    if p12 == "Comfort" then
        return "" .. math.ceil(p11) .. "%";
    end;

    if string.find(p12, "Buff") then
        return NumberUtil:FormatTime(p11 == -1 and 0 or p11, "Minutes", "Seconds", true, 2);
    end;

    local v13 = math.ceil(p11);

    return tostring(v13);
end;

local function _(p15) -- Line: 235
    if not p15 then
        return;
    end;

    p15:Destroy();
end;

local function u19(u16, p17) -- Line: 241
    -- upvalues: TweenUtil (copy)
    local v18 = u16:GetAttributes();

    for i, v in pairs(v18) do
        if pcall(function() -- Line: 244
            -- upvalues: u16 (copy), i (copy)
            local _ = u16[i];
        end) then
            TweenUtil:Tween(u16, i, p17 and v and v or 1, 0.4);
        end;
    end;
end;

local function u22(p20, p21) -- Line: 253
    -- upvalues: u19 (copy)
    u19(p21, p20);

    for _, child in pairs(p21:GetChildren()) do
        u19(child, p20);
    end;
end;

local function u35() -- Line: 261
    -- upvalues: u2 (copy), Stats (copy), TweenUtil (copy), u4 (copy), u10 (ref), u14 (copy), u22 (copy)
    local v23 = u2:GetStatsPickupTableCombined();
    local Position = Stats.Template.Position;
    local v24 = { "I", "II", "III", "IV" };

    for i, v in pairs(v23) do
        local v25 = string.find(v[1], "Buff") and true or false;
        local v26 = Stats:FindFirstChild(v[1]);

        if v26 then
            v26:SetAttribute("Reach", typeof(v[2]) == "table" and v[2][2] or v[2]);

            if i ~= v26:GetAttribute("Index") then
                v26:SetAttribute("Index", i);
                TweenUtil:Tween(v26, "Position", UDim2.new(Position.X.Scale, 0, Position.Y.Scale - 0.04 * (i - 1), 0), 0.4);
            end;

            if v25 then
                local v27 = u4[v[1]];
                v26.StatLabel.Text = v27 and v27.Name or v[1];
                v26.StatLabel.Text = v25 and v26.StatLabel.Text .. " " .. v24[v[2][1]] or v26.StatLabel.Text;
            end;
        else
            local v28 = u4[v[1]];

            if string.find(v[1], "Pickup") then
                v28 = u4.Pickup;
            elseif string.find(v[1], "Drop") then
                v28 = u4.Drop;
            end;

            if v28 then
                local v29 = Stats.Template:Clone();
                v29.Color.BackgroundColor3 = v28.Color;
                v29.Name = v[1];

                if v28.Remove == nil then
                    v29.StatLabel.Text = v[1];
                else
                    local v30 = string.gsub(v[1], v28.Remove, "");
                    v29.StatLabel.Text = v30:find(" Trophy") and "Bone Trophy" or v30;
                end;

                v29.StatLabel.Text = v28.Name == "Craft" and u10 or (v28.Name ~= nil and v28.Name or v29.StatLabel.Text);
                v29.StatLabel.Text = v25 and not v28.SkipLabelNumber and v29.StatLabel.Text .. " " .. v24[v[2][1]] or v29.StatLabel.Text;
                local v31 = v25 and v[2][2] or v[2];
                local v32 = u14(v31, v[1]);

                if v32 == "X" then
                    v29.BackColor.Visible = false;
                    v29.Num.Visible = false;
                end;

                v29.Num.Text = v32;
                v29:SetAttribute("CurrentNum", v31);
                v29:SetAttribute("Reach", v31);
                v29:SetAttribute("Index", i);
                v29.Parent = Stats;
                v29.Position = UDim2.new(Position.X.Scale, 0, Position.Y.Scale - 0.04 * (i - 1), 0);
                u22(true, v29);
            end;
        end;
    end;

    for _, child in pairs(Stats:GetChildren()) do
        local v33 = u2:GetIndexOfStat(child.Name);
        local Name = child.Name;

        if v33 and (Name == "Health" or (Name == "Hunger" or (Name == "Thirst" or (Name == "Template" or not (string.find(Name, "Pickup") or string.find(Name, "Drop")))))) then
            local v34 = false;

            for _, v in pairs(v23) do
                if v[1] == Name then
                    v34 = true;
                end;
            end;

            if not v34 then
                if child then
                    child:Destroy();
                end;
            end;
        end;
    end;
end;

local function u51(p36) -- Line: 351
    -- upvalues: u2 (copy), Stats (copy), Humanoid (copy), TweenUtil (copy), u3 (copy), u35 (copy), NumberUtil (copy), Radiation (copy), u5 (copy), Blur (copy), ColorCorrection (copy), Cold (copy), Hot (copy)
    u2:CompareServerTable(p36);
    local Health = Stats:FindFirstChild("Health");
    local Health2 = Humanoid.Health;
    local Bar = Health.Bar;
    TweenUtil:Tween(Bar.Fill, "Size", UDim2.new(math.clamp(Health2 / 100, 0, 1), 0, 1, 0), 0.4);
    local StatLabel = Bar.StatLabel;
    local v37 = math.ceil(Health2);
    StatLabel.Text = tostring(v37);

    for i, v in pairs(p36) do
        local v38 = Stats:FindFirstChild(i);

        if v38 and (i == "Hunger" or i == "Thirst") then
            local Bar2 = v38.Bar;
            TweenUtil:Tween(Bar2.Fill, "Size", UDim2.new(v / u3[i], 0, 1, 0), 0.4);
            local StatLabel2 = Bar2.StatLabel;
            local v39 = math.ceil(v);
            StatLabel2.Text = tostring(v39);
        elseif i == "HQueue" then
            TweenUtil:Tween(Stats.Health.Bar.HQueue, "Size", UDim2.new(math.clamp((Humanoid.Health + v) / 100, 0, 1), 0, 1, 0), 0.4);
        end;
    end;

    u35();
    local v40 = Stats:FindFirstChild("Radiation") and Stats.Radiation:GetAttribute("Reach") or 0;
    local v41 = v40 / 120;
    local v42 = NumberUtil:Lerp(0.8, 1.3, v41);
    local v43 = math.clamp(v42, 0.8, 1.3);
    local v44 = NumberUtil:Lerp(0.9, 1.2, v41);
    local v45 = math.clamp(v44, 0.9, 1.2);
    Radiation.Volume = v43;
    Radiation.PlaybackSpeed = v45;

    if v40 > 0 then
        Radiation:Play();
    else
        Radiation:Stop();
    end;

    local v46 = Health2 <= 40 and (u5.Health.BlurSize - Health2 / 40 * u5.Health.BlurSize or 0) or 0;
    local v47 = v40 >= 15 and (math.clamp(v40 / 120 * u5.Radiation.BlurSize, 0, u5.Radiation.BlurSize) or 0) or 0;

    if v47 <= v46 then
        v47 = v46 or v47;
    end;

    local v48 = Health2 <= 40 and 255 - (u5.Health.ColorCorrectionLowest - Health2 / 40 * u5.Health.ColorCorrectionLowest) or 255;
    local v49 = v40 >= 15 and math.clamp(255 - v40 / 120 * u5.Radiation.ColorCorrectionLowest, u5.Radiation.ColorCorrectionLowest, 255) or 255;

    if v48 <= v49 then
        v49 = v48 or v49;
    end;

    Blur.Size = v47;
    ColorCorrection.TintColor = Color3.fromRGB(v49, v49, v49);
    local v50 = Stats:FindFirstChild("Temperature") and Stats.Temperature:GetAttribute("Reach") or 0;
    Cold.Visible = v50 <= -8;
    Hot.Visible = v50 >= 29;
end;

local function u54(p52, p53) -- Line: 408
    for _, child in pairs(p52:GetChildren()) do
        if child:IsA("Frame") then
            child.BackgroundColor3 = p53;
            child.Fill.BackgroundColor3 = p53;
        end;
    end;
end;

local function u60(p55, p56) -- Line: 416
    -- upvalues: u54 (copy)
    if p56 < 0 and p55:GetAttribute("ColorNegative") then
        p56 = p56 * -1;
        u54(p55, p55:GetAttribute("ColorNegative"));
    elseif p55:GetAttribute("ColorPositive") ~= nil then
        u54(p55, p55:GetAttribute("ColorPositive"));
    end;

    local v57 = math.ceil(p56 / 10);

    for i = 1, 10 do
        local v58 = p55:FindFirstChild(i >= 10 and tostring(i) or "0" .. i);
        local v59 = v57 < i and 0 or math.min((p56 - (i - 1) * 10) / 10, 1);
        v58.Fill.Size = UDim2.new(v59, 0, 1, 0);
    end;
end;

local function _(p61) -- Line: 471
    -- upvalues: BulletBars (copy), BulletDetail (copy), MeleeBars (copy), MeleeDetail (copy)
    BulletBars.Visible = p61;
    BulletDetail.Visible = p61;
    MeleeBars.Visible = p61;
    MeleeDetail.Visible = p61;
end;

local function _(p62, p63) -- Line: 478
    -- upvalues: u60 (copy), BulletBars (copy), u9 (copy), MeleeBars (copy), BulletDetail (copy), MeleeDetail (copy)
    if not p62 then
        BulletBars.Visible = p62;
        BulletDetail.Visible = p62;
        MeleeBars.Visible = p62;
        MeleeDetail.Visible = p62;

        return;
    end;

    u60(BulletBars, u9[p63].Bullet);
    u60(MeleeBars, u9[p63].Melee);
    BulletBars.Visible = p62;
    BulletDetail.Visible = p62;
    MeleeBars.Visible = p62;
    MeleeDetail.Visible = p62;
end;

HitboxHead.MouseEnter:Connect(function() -- Line: 494
    -- upvalues: u60 (copy), BulletBars (copy), u9 (copy), MeleeBars (copy), BulletDetail (copy), MeleeDetail (copy), ViewportModule (copy), ViewportFrame (copy)
    u60(BulletBars, u9.Head.Bullet);
    u60(MeleeBars, u9.Head.Melee);
    BulletBars.Visible = true;
    BulletDetail.Visible = true;
    MeleeBars.Visible = true;
    MeleeDetail.Visible = true;
    ViewportModule:HighlightCharArea(ViewportFrame, "Head");
end);
HitboxHead.MouseLeave:Connect(function() -- Line: 498
    -- upvalues: BulletBars (copy), BulletDetail (copy), MeleeBars (copy), MeleeDetail (copy), ViewportModule (copy), ViewportFrame (copy)
    BulletBars.Visible = false;
    BulletDetail.Visible = false;
    MeleeBars.Visible = false;
    MeleeDetail.Visible = false;
    ViewportModule:HighlightCharArea(ViewportFrame);
end);
HitboxChest.MouseEnter:Connect(function() -- Line: 503
    -- upvalues: u60 (copy), BulletBars (copy), u9 (copy), MeleeBars (copy), BulletDetail (copy), MeleeDetail (copy), ViewportModule (copy), ViewportFrame (copy)
    u60(BulletBars, u9.Chest.Bullet);
    u60(MeleeBars, u9.Chest.Melee);
    BulletBars.Visible = true;
    BulletDetail.Visible = true;
    MeleeBars.Visible = true;
    MeleeDetail.Visible = true;
    ViewportModule:HighlightCharArea(ViewportFrame, "Chest");
end);
HitboxChest.MouseLeave:Connect(function() -- Line: 507
    -- upvalues: BulletBars (copy), BulletDetail (copy), MeleeBars (copy), MeleeDetail (copy), ViewportModule (copy), ViewportFrame (copy)
    BulletBars.Visible = false;
    BulletDetail.Visible = false;
    MeleeBars.Visible = false;
    MeleeDetail.Visible = false;
    ViewportModule:HighlightCharArea(ViewportFrame);
end);
HitboxLegs.MouseEnter:Connect(function() -- Line: 512
    -- upvalues: u60 (copy), BulletBars (copy), u9 (copy), MeleeBars (copy), BulletDetail (copy), MeleeDetail (copy), ViewportModule (copy), ViewportFrame (copy)
    u60(BulletBars, u9.Legs.Bullet);
    u60(MeleeBars, u9.Legs.Melee);
    BulletBars.Visible = true;
    BulletDetail.Visible = true;
    MeleeBars.Visible = true;
    MeleeDetail.Visible = true;
    ViewportModule:HighlightCharArea(ViewportFrame, "Legs");
end);
HitboxLegs.MouseLeave:Connect(function() -- Line: 516
    -- upvalues: BulletBars (copy), BulletDetail (copy), MeleeBars (copy), MeleeDetail (copy), ViewportModule (copy), ViewportFrame (copy)
    BulletBars.Visible = false;
    BulletDetail.Visible = false;
    MeleeBars.Visible = false;
    MeleeDetail.Visible = false;
    ViewportModule:HighlightCharArea(ViewportFrame);
end);
LocalPlayer:GetAttributeChangedSignal("SafeZone"):Connect(function() -- Line: 521
    -- upvalues: LocalPlayer (copy), u2 (copy)
    if LocalPlayer:GetAttribute("SafeZone") then
        u2:InsertStat("Safezone", 1);

        return;
    end;

    u2:UpdateStat("Safezone", 0);
end);
CraftUpdate.Event:Connect(function(p64, p65, p66) -- Line: 531
    -- upvalues: u2 (copy), u10 (ref), u35 (copy)
    if p64 == "UpdateRecipes" then
        if p65 <= 0 then
            u2:InsertStat("Recipes", 0);

            return;
        end;

        u2:InsertStat("Recipes", p65);

        return;
    end;

    if p64 == "UpdateCraft" then
        u10 = p65;
        u2:InsertStat("Craft", p66);
    elseif p64 == "RemoveCraft" then
        u2:InsertStat("Craft", 0);
    end;

    u35();
end);
v1("Setup", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "s*\16a\192\2250C\152\156\243g\250hL\178\1\205\248!", function(p67, p68) -- Line: 558
    -- upvalues: u51 (copy), u9 (copy), Armor (copy), u60 (copy)
    if p67 ~= nil then
        u51(p67);
    end;

    if p68 ~= nil then
        for i, v in pairs(p68) do
            if i == "Head" or (i == "Chest" or i == "Legs") then
                u9[i].Bullet = v.Bullet;
                u9[i].Melee = v.Melee;
            else
                local v69 = Armor:FindFirstChild(i .. "Bars");

                if v69 then
                    u60(v69, v);
                else
                    print("BAR CONTAINER NOT FOUND FOR " .. i);
                end;
            end;
        end;
    end;
end);
v1("Setup", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "\159\132\143\252\1]\204\184\151\141\207\171\176J\191\252\164Bn\175", function(p70, p71) -- Line: 577
    -- upvalues: u8 (copy), u35 (copy)
    table.insert(u8, p70);
    u35();
end);
Blur.Size = 0;
ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255);
v1(
    "Fire",
    "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145",
    "s*\16a\192\2250C\152\156\243g\250hL\178\1\205\248!"
);

while true do
    local v72 = false;

    if tick() - v6 >= 0.2 then
        v6 = tick();
        local v73 = u8[1];

        if v73 then
            table.remove(u8, 1);
            u2:InsertStat(v73[1], v73[2]);
            v72 = true;
        end;
    end;

    for _, v in pairs(u2:GetPickups()) do
        if tick() - v[3] >= 5 then
            local u74 = Stats:FindFirstChild(v[1]);

            if u74 then
                delay(0.4, function() -- Line: 608
                    -- upvalues: u74 (copy)
                    u74:Destroy();
                end);
                u22(false, u74);
            end;

            u2:RemovePickup(v[1]);
            v72 = true;
        end;
    end;

    if tick() - v7 >= 0.06 then
        v7 = tick();

        for _, child in pairs(Stats:GetChildren()) do
            local v75 = false;

            for _, v in pairs({ "Health", "Hunger", "Thirst", "Template" }) do
                if child.Name == v then
                    v75 = true;
                end;
            end;

            if not v75 then
                local v76 = child:GetAttribute("CurrentNum");
                local v77 = child:GetAttribute("Reach");
                local Num = child.Num;

                if v77 then
                    if v76 ~= v77 then
                        if v77 - 0.4 <= v76 then
                            child:SetAttribute("CurrentNum", v77);
                            Num.Text = u14(v77, child.Name);
                        else
                            local v78 = NumberUtil:Lerp(v76, v77, 0.45);
                            child:SetAttribute("CurrentNum", v78);
                            Num.Text = u14(v78, child.Name);
                        end;
                    end;
                end;
            end;
        end;
    end;

    if v72 then
        u35();
    end;

    if #u2:GetPickups() <= 0 then
        wait(0.5);
    else
        wait();
    end;
end;