-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local UserService = game:GetService("UserService");
game:GetService("SoundService");
local GamepadService = game:GetService("GamepadService");
local GuiService = game:GetService("GuiService");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Values = ReplicatedStorage:WaitForChild("Values");
ReplicatedStorage:WaitForChild("LocalSounds");
local ClientSignals = ReplicatedStorage:WaitForChild("ClientSignals");
local Items = require(Modules:WaitForChild("Items"));
local TweenUtil = require(Modules:WaitForChild("TweenUtil"));
local NumberUtil = require(Modules:WaitForChild("NumberUtil"));
local ButtonClass = require(Modules:WaitForChild("ButtonClass"));
local ViewportModule = require(Modules:WaitForChild("ViewportModule"));
local SoundModule = require(Modules:WaitForChild("SoundModule"));
local ToolInfo = require(Modules:WaitForChild("ToolInfo"));
local ResearchModule = require(Modules:WaitForChild("ResearchModule"));
local RecipeModule = require(Modules:WaitForChild("RecipeModule"));
local ItemClass = require(Modules:WaitForChild("ItemClass"));
local GamepadIconModule = require(Modules:WaitForChild("GamepadIconModule"));
local ItemSearchModule = require(Modules:WaitForChild("ItemSearchModule"));
ItemSearchModule.CancelSearch(true);
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local ActiveBenchModule = require(Modules:WaitForChild("ActiveBenchModule"));
local SkinsModule = require(Modules:WaitForChild("SkinsModule"));
local u1 = require(Modules:WaitForChild("AssetContainer"))();
local Fetch = script:WaitForChild("Fetch");
local GetBench = script:WaitForChild("GetBench");
local ItemStats = script:WaitForChild("ItemStats");
local Toggle = script:WaitForChild("Toggle");
local LocalPlayer = Players.LocalPlayer;
local Parent = script.Parent;
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui");
local Humanoid = Parent:WaitForChild("Humanoid");
local u2 = LocalPlayer:GetMouse();
local CurrentCamera = workspace.CurrentCamera;
local ViewmodelController = Parent:WaitForChild("ViewmodelController");
local WheelController = Parent:WaitForChild("WheelController");
local CraftingController = Parent:WaitForChild("CraftingController");
local StateController = Parent:WaitForChild("StateController");
local TeamNavigationController = Parent:WaitForChild("TeamNavigationController");
local InteractController = Parent:WaitForChild("InteractController");
local PreferredInputController = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local Main = PlayerGui:WaitForChild("Main");
local Boombox = PlayerGui:WaitForChild("Boombox");
local BG = Main:WaitForChild("BG");
local Inventory = Main:WaitForChild("Inventory");
local Toolbar = Main:WaitForChild("Toolbar");
local Drag = Main:WaitForChild("Drag");
local Inv = Inventory:WaitForChild("Inv");
local Backpack = Inventory:WaitForChild("Backpack");
local ActionMenu = Inventory:WaitForChild("ActionMenu");
local ImageLabel = ActionMenu:WaitForChild("Actions"):WaitForChild("Drop"):WaitForChild("Label"):WaitForChild("ImageLabel");
GamepadIconModule.Register(ImageLabel, "ButtonX");
local ItemStats2 = ActionMenu:WaitForChild("ItemStats");
local Benches = Inventory:WaitForChild("Benches");
local Armor = Inventory:WaitForChild("Armor");
local ViewportFrame = Armor:WaitForChild("ViewportFrame");
local HitboxChest = Armor:WaitForChild("HitboxChest");
local HitboxHead = Armor:WaitForChild("HitboxHead");
local HitboxLegs = Armor:WaitForChild("HitboxLegs");
local CraftingKeyboard = Inventory:WaitForChild("CraftingKeyboard");
local CraftingConsole = Inventory:WaitForChild("CraftingConsole");
GamepadIconModule.Register(CraftingConsole:WaitForChild("ImageLabel"), "ButtonY");
local Crafting = Main:WaitForChild("Crafting");
local CraftingKeyboard2 = Crafting:WaitForChild("CraftingKeyboard");
local CraftingConsole2 = Crafting:WaitForChild("CraftingConsole");
GamepadIconModule.Register(CraftingConsole2:WaitForChild("ImageLabel"), "ButtonY");
local Stats = Main:WaitForChild("Stats");
local Team = Main:WaitForChild("Team");
local GamepadControls = Main:WaitForChild("GamepadControls");
local ToolTip = GamepadControls:WaitForChild("ToolTip");
local u3 = { GamepadControls:WaitForChild("TopControls"), GamepadControls:WaitForChild("ToolbarRight"), GamepadControls:WaitForChild("ToolbarLeft") };
local DragEntry = ToolTip:WaitForChild("DragEntry");
local MenuEntry = ToolTip:WaitForChild("MenuEntry");
local TransferEntry = ToolTip:WaitForChild("TransferEntry");
GamepadIconModule.Register(DragEntry:FindFirstChildWhichIsA("ImageLabel"), "ButtonA");
GamepadIconModule.Register(MenuEntry:FindFirstChildWhichIsA("ImageLabel"), "ButtonX");
local u4 = {};
local u5 = {};
local u6 = {};
local u7 = {
    Inventory = Inv,
    Toolbar = Toolbar,
    Armor = Armor
};
local u8 = nil;
local u9 = nil;
local u10 = nil;
local u11 = nil;
local u12 = nil;
local u13 = 1;
local Size = ActionMenu.Size;
local u14 = true;
local u15 = false;
local u16 = nil;
local u17 = nil;
local u18 = false;
local u19 = false;
local u20 = 0;
local u21 = 0;
local u22 = {};
local u23 = 0;
local u24 = false;
local u25 = {};
local u26 = nil;
local u27 = nil;
local u28 = 0;
local u29 = 1;
local u30 = 0;
local u31 = 1;
local u32 = {};
local u33 = false;
local u34 = false;
local u35 = nil;

local function v37() -- Line: 155
    -- upvalues: PreferredInputController (copy)
    local v36 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    return v36;
end;

local function u40() -- Line: 158
    -- upvalues: u2 (copy), u7 (copy)
    local X = u2.X;
    local Y = u2.Y;

    for i, v in pairs(u7) do
        local v38 = v:FindFirstChild("Inv") or v;

        for _, child in pairs(v38:GetChildren()) do
            if child.Name:sub(1, 4) == "Slot" and (child:IsA("ImageButton") and child.Visible) then
                local AbsolutePosition = child.AbsolutePosition;
                local AbsoluteSize = child.AbsoluteSize;

                if AbsolutePosition.X <= X and (X <= AbsolutePosition.X + AbsoluteSize.X and (AbsolutePosition.Y <= Y and Y <= AbsolutePosition.Y + AbsoluteSize.Y)) then
                    local v39 = tonumber(child.Name:sub(5));

                    if v39 then
                        return child, i, v39;
                    end;
                end;
            end;
        end;
    end;
end;

local function _() -- Line: 175
    -- upvalues: Humanoid (copy)
    return Humanoid and Humanoid.Parent and Humanoid.Health > 0;
end;

local function _() -- Line: 179
    -- upvalues: Drag (copy), RunService (copy), u11 (ref)
    Drag.Visible = false;
    RunService:UnbindFromRenderStep("Drag");
    u11 = nil;
end;

local u41 = nil;

local function u42() -- Line: 186
    -- upvalues: SoundModule (copy), u17 (ref), ItemSearchModule (copy), u7 (copy), u4 (ref), u11 (ref), Drag (copy), RunService (copy), u10 (ref), u41 (ref)
    SoundModule:PlayBenchSound(u17 and u17.Name, "Close");
    ItemSearchModule.CancelSearch(true);
    u17 = nil;
    local Bench = u7.Bench;

    if Bench and Bench.Parent then
        Bench.Visible = false;
    end;

    u7.Bench = nil;
    u4.Bench = nil;

    if u11 and u11.Container == "Bench" then
        Drag.Visible = false;
        RunService:UnbindFromRenderStep("Drag");
        u11 = nil;
    end;

    if u10 and u10.Container == "Bench" then
        u41(nil);
    end;
end;

local function u51(p43, p44) -- Line: 204
    -- upvalues: u8 (ref), TweenUtil (copy), BG (copy), u9 (ref), PreferredInputController (copy), u35 (ref), Humanoid (copy), GamepadService (copy), u17 (ref), u1 (copy), u42 (copy), Drag (copy), RunService (copy), u11 (ref), u33 (ref), Inventory (copy), Crafting (copy), TeamNavigationController (copy), UserInputService (copy), Boombox (copy), SettingsModule (copy), CraftingKeyboard (copy), CraftingConsole (copy), CraftingKeyboard2 (copy), CraftingConsole2 (copy), ToolTip (copy), DragEntry (copy), MenuEntry (copy), TransferEntry (copy), u3 (copy), u2 (copy)
    if not u8 then
        u8 = TweenUtil:Tween(BG, "BackgroundTransparency", 0.5, 0.15, "Quart", "Out", true);
        u9 = TweenUtil:Tween(BG, "BackgroundTransparency", 1, 0.15, "Quart", "In", true);
    end;

    local v45 = p43 ~= "None";

    if v45 then
        if p44 then
            BG.BackgroundTransparency = 0.5;
        else
            u8:Play();
        end;

        local v46 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v46 and not u35 then
            u35 = Humanoid.WalkSpeed;
            Humanoid.WalkSpeed = 0;
        end;

        local v47 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v47 then
            pcall(function() -- Line: 224
                -- upvalues: GamepadService (ref)
                GamepadService:EnableGamepadCursor(nil);
            end);
        end;
    else
        if u17 and u17.Parent then
            u1("Fire", "\156\2I=\144i\181\249\200\249\198Q\20\205\1431\142\1\1391", "\140^\1720\244\2504\202,\206\1\142\2236\218!\233fN\t", "Close", u17);
        end;

        u42();

        if p44 then
            BG.BackgroundTransparency = 1;
        else
            u9:Play();
        end;

        Drag.Visible = false;
        RunService:UnbindFromRenderStep("Drag");
        u11 = nil;
        u33 = false;

        if u35 then
            Humanoid.WalkSpeed = u35;
            u35 = nil;
        end;

        pcall(function() -- Line: 247
            -- upvalues: GamepadService (ref)
            GamepadService:DisableGamepadCursor();
        end);
    end;

    Inventory:TweenPosition(UDim2.new(p43 == "Crafting" and 1 or (p43 == "Inventory" and 0 or -1), 0, 0, 0), v45 and "Out" or "In", "Quart", p44 and 0 or 0.1, true);
    Crafting:TweenPosition(UDim2.new(p43 == "Crafting" and 0 or (p43 == "Inventory" and -1 or -2), 0, 0, 0), v45 and "Out" or "In", "Quart", p44 and 0 or 0.1, true);

    if not TeamNavigationController:GetAttribute("MapOpen") or v45 then
        UserInputService.MouseBehavior = Enum.MouseBehavior[v45 and "Default" or "LockCenter"];
        UserInputService.MouseIconEnabled = v45;
    end;

    Boombox.Enabled = Boombox.Enabled and v45;
    script:SetAttribute("Open", v45);
    script:SetAttribute("CurOpen", p43);
    local v48 = SettingsModule.GetSetting("Controls", "Open Crafting");
    local v49 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
    CraftingKeyboard.Text = `CRAFTING [<font color="rgb(255, 244, 88)">{v48}</font>]`;
    CraftingConsole.Text = "CRAFTING    ";
    CraftingKeyboard.Visible = not v49;
    CraftingConsole.Visible = v49;
    CraftingKeyboard2.Text = `INVENTORY [<font color="rgb(255, 244, 88)">{v48}</font>]`;
    CraftingConsole2.Text = "INVENTORY    ";
    CraftingKeyboard2.Visible = not v49;
    CraftingConsole2.Visible = v49;

    if not v45 then
        script:SetAttribute("ClosedTick", tick());
    end;

    local v50 = v45 and PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
    ToolTip.Visible = v50;

    if p43 == "Crafting" then
        DragEntry.Visible = true;
        DragEntry.Text = " - Double Tap Craft";
        MenuEntry.Visible = false;
        TransferEntry.Visible = false;
    else
        DragEntry.Visible = true;
        DragEntry.Text = " - Drag Item";
        MenuEntry.Visible = true;
        TransferEntry.Visible = true;
    end;

    for _, v in pairs(u3) do
        v.Visible = not v45;
    end;

    if not v50 then
        pcall(function() -- Line: 298
            -- upvalues: RunService (ref)
            RunService:UnbindFromRenderStep("GamepadTooltip");
        end);

        return;
    end;

    pcall(function() -- Line: 293
        -- upvalues: RunService (ref)
        RunService:UnbindFromRenderStep("GamepadTooltip");
    end);
    RunService:BindToRenderStep("GamepadTooltip", Enum.RenderPriority.Last.Value, function() -- Line: 294
        -- upvalues: ToolTip (ref), u2 (ref)
        ToolTip.Position = UDim2.new(0, u2.X - 10, 0, u2.Y - ToolTip.AbsoluteSize.Y + 80);
    end);
end;

local function u61(p52, p53, p54, p55, p56, p57, p58, p59) -- Line: 302
    -- upvalues: u11 (ref), Drag (copy), RunService (copy), u2 (copy), SoundModule (copy)
    if script:GetAttribute("Open") then
        u11 = {
            Slot = p52,
            Container = p54,
            Index = p55,
            Mouse = p56,
            IsActionMenu = p57,
            EditIndex = p59
        };
        Drag.Image = p53;
        local u60 = false;
        RunService:BindToRenderStep("Drag", Enum.RenderPriority.Input.Value + 1, function() -- Line: 317
            -- upvalues: u60 (ref), Drag (ref), u2 (ref)
            if not u60 then
                Drag.Visible = true;
                u60 = true;
            end;

            Drag.Position = UDim2.new(0, u2.X + 1, 0, u2.Y + 1);
        end);
        SoundModule:PlayItemSound(p58.ID, "Drag");

        return true;
    end;
end;

local function u80(p62, p63, p64, p65, p66, p67, p68) -- Line: 328
    -- upvalues: u4 (ref), Items (copy), Backpack (copy), u17 (ref), u20 (ref), SoundModule (copy), RunService (copy), u21 (ref), u1 (copy)
    if p66 ~= "ArmorEquip" and not script:GetAttribute("Open") then
        return;
    end;

    local v69 = u4[p63];

    if not v69 or (tick() - (p62.Fill:GetAttribute("Cooldown") or 0) < 0.4 or p62.Fill.Visible) then
        return;
    end;

    local v70 = v69[p64];

    if not v70 or (v70 == 0 or p68 and (not p68 or p68 == 0)) then
        return;
    end;

    local ID = (p68 or v70).ID;
    local _ = (Items[ID] or {}).Type:find("Armor") == nil;
    p62.Fill.Visible = true;
    local v71 = Backpack.Visible and not u17 and (p63 == "Inventory" and true or p63 == "Toolbar");
    local v72 = p66 == "ArmorEquip" and 0.9 or ((u17 and p63 ~= "Armor" or (v71 or p68)) and 0.3 or 0.1);
    local v73 = false;
    local v74 = 0;
    local v75;

    if p66 then
        v75 = u20;
        u20 = u20 + 1;
    else
        v75 = nil;
    end;

    SoundModule:PlayItemSound(ID, "Drag");

    while u4[p63] and (v69[p64] and v69[p64] ~= 0) do
        local v76 = math.min(v74, v72);
        local v77 = v76 / v72;

        if p66 then
            v77 = 1 - v77;
        end;

        local v78 = math.clamp(v77, 0, 1);
        p62.Fill.Size = UDim2.new(1, 0, v78, 0);
        p62.Fill.Position = UDim2.new(0, 0, 1 - v78, 0);

        if v72 <= v76 then
            v73 = true;
            break;
        end;

        local v79 = RunService.Heartbeat:Wait();

        if not p66 or v75 <= u21 then
            v74 = v74 + v79;
        end;
    end;

    if v73 then
        SoundModule:PlayItemSound(ID, "Drop");

        if v71 then
            u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", p63, p64, nil, "Armor", 8);
        elseif p68 then
            u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", p63, p64, "QuickStack", p65, p67);
        else
            u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", p63, p64, "QuickStack", p65);
        end;
    end;

    p62.Fill:SetAttribute("Cooldown", tick());
    p62.Fill.Visible = false;

    if p66 then
        u21 = u21 + 1;
    end;
end;

local function u83(p81) -- Line: 404
    -- upvalues: u12 (ref), ActionMenu (copy), NumberUtil (copy)
    if not u12 then
        u12 = {};

        for _, descendant in pairs(ActionMenu:GetDescendants()) do
            if not descendant:IsA("UIGradient") then
                local v82 = `{descendant:IsA("TextLabel") and "Text" or (descendant:IsA("UIStroke") and "" or ((descendant:IsA("Frame") or descendant.Image == "") and "Background" or "Image"))}Transparency`;
                u12[descendant] = { v82, descendant[v82] };
            end;
        end;
    end;

    for i, v in u12 do
        i[v[1]] = NumberUtil:Lerp(v[2], 1, p81);
    end;

    ActionMenu.Visible = p81 < 1;
end;

local function u86() -- Line: 421
    -- upvalues: u10 (ref), u4 (ref), u16 (ref), ActionMenu (copy), NumberUtil (copy)
    if u10 then
        local v84 = u4[u10.Container];

        if not v84 then
            return;
        end;

        local v85 = v84[u10.Index];

        if not v85 or (v85 == 0 or v85.Amount <= 0) then
            return;
        end;

        u16 = math.clamp(u16, 1, v85.Amount);
        ActionMenu.SplitBar.Fill:TweenSize(UDim2.new(u16 / v85.Amount, 0, 1, 0), "Out", "Quart", 0.15, true);
        ActionMenu.SplitBar.Amount.Text = NumberUtil:FormatNumber(u16);
    end;
end;

local function u110(p87, p88, p89, p90) -- Line: 434
    -- upvalues: Items (copy), NumberUtil (copy), ViewmodelController (copy), Toolbar (copy)
    local v91 = tonumber(p87.Name:sub(5));
    local v92 = (1 / 0);
    local v93, v94, v95, v96, v97, v98, v99;

    if p88 and p88 ~= 0 then
        v93 = Items[p88.ID];
        v94 = v93.Image;
        v95 = v93.MaxDurability;
        v96 = v93.Attachments;
        v97 = p88.Ammo;
        v98 = p88.CookTimes;
        v99 = p88.Container;
        v92 = v93.MaxAttachments or v92;
    else
        v93 = nil;
        v97 = nil;
        v99 = nil;
        v95 = nil;
        v96 = nil;
        v94 = nil;
        v98 = nil;
    end;

    local Durability = p87:FindFirstChild("Durability");
    local v100;

    if Durability then
        v100 = v95 ~= nil;

        if v95 then
            Durability.Fill.Size = UDim2.new(math.clamp(p88.Durability / v95, 0, 1), 0, 1, 0);
            local v101 = math.min(p88.Repair, 1);
            Durability.Repair.Position = UDim2.new(1 - v101, 0, 0, 0);
            Durability.Repair.Size = UDim2.new(v101, 0, 1, 0);
        end;

        Durability.Visible = v100;
    else
        v100 = false;
    end;

    for i = 1, 4 do
        local v102 = p87:FindFirstChild("Att" .. i);

        if v102 then
            if v96 then
                v102.BackgroundColor3 = i <= #p88.Attachments and Color3.fromRGB(255, 244, 88) or Color3.fromRGB(167, 165, 130);
            end;

            local v103;

            if v96 == nil then
                v103 = false;
            else
                v103 = i <= math.min(#v96, v92);
            end;

            v102.Visible = v103;
        end;
    end;

    p87.ItemImage.Image = v94 and (type(v94) == "table" and v94[p88.Skin] or (v94 or "")) or "";

    if v93 and (v93.Type == "Backpack" and v99) then
        local v104 = 0;

        for _, v in v99 do
            if type(v) == "table" and v.Amount > 0 then
                v104 = v104 + 1;
            end;
        end;

        p87.ItemAmount.Text = `{v104}/{#v99}`;
    else
        p87.ItemAmount.Text = v93 and (v93.Type:find("Ammo") == nil and v93.AmmoType ~= nil and NumberUtil:FormatNumber(v97 == nil and 0 or (p89 or (v97.Amount or 0))) or (p88.Amount > 1 and ("x" .. NumberUtil:FormatNumber(p88.Amount) or "") or "")) or "";
    end;

    p87.ItemAmount.Position = UDim2.new(0.25, 0, v100 and 0.71 or 0.76, 0);
    local Broken = p87:FindFirstChild("Broken");

    if Broken then
        local v105;

        if v95 == nil then
            v105 = false;
        else
            v105 = p88.Durability <= 0;
        end;

        Broken.Visible = v105;
    end;

    local Empty = p87:FindFirstChild("Empty");

    if Empty then
        Empty.Visible = v94 == nil;
    end;

    local Checker = p87:FindFirstChild("Checker");

    if Checker then
        Checker.Visible = false;
    end;

    local CookBar = p87:FindFirstChild("CookBar");

    if CookBar then
        if v98 then
            local u106 = math.clamp(v98[1] / v98[2], 0, 1);
            local v107;

            if u106 < CookBar.Fill.Size.Y.Scale then
                v107 = CookBar.Visible;
            else
                v107 = false;
            end;

            local v108 = u106 <= 0.001;
            CookBar.Fill:TweenSize(UDim2.new(1, 0, v107 and not v108 and 1 or u106, 0), "InOut", "Linear", CookBar.Visible and not v108 and (v107 and 0.8 or 1) or 0, true);

            if v107 and not v108 then
                task.delay(0.8, function() -- Line: 504
                    -- upvalues: CookBar (copy), u106 (copy)
                    if not CookBar or (not CookBar.Parent or (not CookBar.Visible or CookBar.Fill.Size.Y.Scale < 0.99)) then
                        return;
                    end;

                    CookBar.Fill:TweenSize(UDim2.new(1, 0, u106, 0), "InOut", "Linear", 0.1, true);
                end);
            end;
        end;

        CookBar.Visible = v98 ~= nil;
    end;

    local v109 = ViewmodelController:GetAttribute("Equipped");

    if p90 or (p87.Parent ~= Toolbar or v91 ~= v109) then
        return;
    end;

    ViewmodelController.UpdateVM:Fire(p88);
end;

local function u115(p111, ...) -- Line: 517
    local v112 = { ... };

    for i = 1, 8 do
        local v113 = p111["Stat" .. i];
        local v114 = v112[i] or "";
        v113.Size = UDim2.new(i > 4 and 0.5 or 1, 0, 0.24, 0);
        v113.RichText = v114:find("</") ~= nil;
        v113.Text = v114;

        if i > 4 then
            p111["Stat" .. i - 4].Size = UDim2.new(0.5, 0, 0.24, 0);
        end;
    end;
end;

local function u173(p116, p117, p118) -- Line: 531
    -- upvalues: u115 (copy), Items (copy), ToolInfo (copy), NumberUtil (copy)
    u115(p116);
    local v119 = p118 or Items[p117];
    local AmmoStats = v119.AmmoStats;
    local ConsumableStats = v119.ConsumableStats;
    local Resistances = v119.Resistances;
    local v120 = ToolInfo[v119.Name];

    if v119.Type == "Gun" and v120 then
        local Weapon = v120.Weapon;
        local Bullet = v120.Bullet;

        if Bullet then
            local Dropoff = Bullet.Dropoff;
            local ActualRPM = Weapon.ActualRPM;
            local v121 = `Base Damage: {NumberUtil:RoundNumber(Bullet.DisplayDamage or Bullet.HumanoidDamages.Chest)}`;

            if type(ActualRPM) ~= "string" then
                ActualRPM = NumberUtil:FormatNumber(ActualRPM or Weapon.RPM);
            end;

            u115(p116, v121, `RPM: {ActualRPM}`, `Range Dropoff: {NumberUtil:FormatNumber(Dropoff.Start) .. (Dropoff.End == Dropoff.Start and "" or "-" .. NumberUtil:FormatNumber(Dropoff.End))}`, (`Bullet Velocity: {NumberUtil:FormatNumber(Bullet.Speed)}`));
        end;
    else
        if v119.Type == "Tool" or v119.Type:find("Consumable") then
            local v122 = {};

            if v120 then
                local Weapon = v120.Weapon;
                local Melee = v120.Melee;
                local ObjectDamages = v120.ObjectDamages;
                local v123 = Melee and Melee.HumanoidDamages;

                if v123 then
                    local v124 = `Base Damage: {NumberUtil:RoundNumber(v123.Chest)}`;
                    table.insert(v122, v124);
                end;

                local v125;

                if Weapon then
                    v125 = Weapon.ThrowInfo;
                else
                    v125 = Weapon;
                end;

                local v126 = v125 and v125.Explosive;

                if v126 then
                    local v127 = `Splash Damage: {NumberUtil:RoundNumber(v126.HumanoidMaxDamage)}`;
                    table.insert(v122, v127);
                end;

                if Weapon then
                    Weapon = Weapon.Cooldown;
                end;

                if Weapon then
                    local v128 = `Cooldown: {NumberUtil:RoundNumber(Weapon)}`;
                    table.insert(v122, v128);
                end;

                if ObjectDamages then
                    local Trees = ObjectDamages.Trees;

                    if Trees then
                        local v129 = `Tree Gather: {math.round(Trees.Medium.Mult * 1000) / 100}`;
                        table.insert(v122, v129);
                    end;

                    local Nodes = ObjectDamages.Nodes;

                    if Nodes then
                        local v130 = `Node Gather: {math.round(Nodes.Stone.Mult * 1000) / 100}`;
                        table.insert(v122, v130);
                    end;
                end;
            end;

            if ConsumableStats then
                for i, v in pairs(ConsumableStats) do
                    if v ~= 0 and type(v) == "number" then
                        local v131 = NumberUtil:RoundNumber(v);
                        local v132 = math.abs(v);
                        local v133 = script:GetAttribute(v131 < 0 == (i ~= "Radiation") and "StatRedColor" or "StatGreenColor");
                        local v134 = `{i == "HQueue" and "Health Regen" or (i == "Health" and "Instant Health" or i)}: <font color="rgb({math.round(v133.R * 255)}, {math.round(v133.G * 255)}, {math.round(v133.B * 255)})">{(v131 < 0 and "-" or "+") .. v132}</font>`;
                        table.insert(v122, v134);
                    end;
                end;
            end;

            u115(p116, unpack(v122));

            return;
        end;

        if AmmoStats then
            local v135 = {};

            for i, v in pairs(AmmoStats) do
                if i:sub(#i - 3) == "Mult" then
                    local v136 = i:sub(1, #i - 4);
                    local v137 = v136 == "Gravity";
                    local v138 = math.round(((v137 or v136 == "ArmorPen") and 1 - v or (v136 == "HeadshotDamage" and v and v or v * (AmmoStats.Bullets or 1) - 1)) * 100);
                    local v139 = math.abs(v138);
                    local v140 = v138 < 0 == (v136:find("Spread") == nil);
                    local v141 = script:GetAttribute(v140 and "StatRedColor" or "StatGreenColor");
                    local v142 = `{v137 and "Drop" or (v136 == "ArmorPen" and "Armor Penetration" or (v136 == "HeadshotDamage" and "HS Mult" or v136:gsub("Spread", " Spread")))}: <font color="rgb({math.round(v141.R * 255)}, {math.round(v141.G * 255)}, {math.round(v141.B * 255)})">{(v138 < 0 and "-" or "+") .. v139}%</font>`;
                    table.insert(v135, v142);
                elseif i == "Explosive" then
                    local v143 = NumberUtil:FormatNumber(v.HumanoidMaxDamage);

                    if v119.AmmoType == "Rocket" then
                        if v119.Name ~= "Rocket" then
                            local v144 = `Damage Override: {NumberUtil:FormatNumber(v143)}`;
                            table.insert(v135, v144);
                        end;
                    else
                        local v145 = script:GetAttribute("StatGreenColor");
                        local v146 = `Splash Damage: <font color="rgb({math.round(v145.R * 255)}, {math.round(v145.G * 255)}, {math.round(v145.B * 255)})">+{v143}</font>`;
                        table.insert(v135, v146);
                    end;
                elseif i == "Bullets" then
                    local v147 = `Pellets: {v}`;
                    table.insert(v135, v147);
                end;
            end;

            u115(p116, unpack(v135));

            return;
        end;

        if Resistances then
            local v148 = {};

            for _, v in pairs({ "Chest", "Legs", "Head" }) do
                local v149 = Resistances[v];
                local Bullet = v149.Bullet;
                local Melee = v149.Melee;

                if Bullet ~= 0 or Melee ~= 0 then
                    if Bullet ~= 0 then
                        table.insert(v148, { "Bullet", Bullet });
                    end;

                    if Melee ~= 0 then
                        table.insert(v148, { "Melee", Melee });
                    end;

                    break;
                end;
            end;

            for i, v in pairs(Resistances) do
                if v ~= 0 and type(v) == "number" then
                    table.insert(v148, { i, v });
                end;
            end;

            local v150 = {};

            for _, v in pairs(v148) do
                local v151 = v[2];
                local v152 = NumberUtil:RoundNumber((math.abs(v151)));
                local v153 = script:GetAttribute(v151 < 0 and "StatRedColor" or "StatGreenColor");
                local v154 = `{v[1]}: <font color="rgb({math.round(v153.R * 255)}, {math.round(v153.G * 255)}, {math.round(v153.B * 255)})">{(v151 < 0 and "-" or "+") .. v152}</font>`;
                table.insert(v150, v154);
            end;

            u115(p116, unpack(v150));

            return;
        end;

        if v119.Name == "Armor Plate" then
            local v155 = script:GetAttribute("StatGreenColor");
            u115(p116, `Armor Mod Type: {v119.AttachmentType:upper()}`, (`Bullet Resistance: <font color="rgb({math.round(v155.R * 255)}, {math.round(v155.G * 255)}, {math.round(v155.B * 255)})">+5%</font>`));

            return;
        end;

        if v119.Name == "Heavy Padding" then
            local v156 = script:GetAttribute("StatGreenColor");
            u115(p116, `Armor Mod Type: {v119.AttachmentType:upper()}`, (`Melee Resistance: <font color="rgb({math.round(v156.R * 255)}, {math.round(v156.G * 255)}, {math.round(v156.B * 255)})">+5%</font>`));

            return;
        end;

        if v119.Name == "Night Vision Goggles" then
            local v157 = script:GetAttribute("StatGreenColor");
            local v158 = script:GetAttribute("StatRedColor");
            u115(p116, `Armor Mod Type: {v119.AttachmentType:upper()}`, `Night Visibility: <font color="rgb({math.round(v157.R * 255)}, {math.round(v157.G * 255)}, {math.round(v157.B * 255)})">+100%</font>`, (`Daytime Visibility: <font color="rgb({math.round(v158.R * 255)}, {math.round(v158.G * 255)}, {math.round(v158.B * 255)})">-100%</font>`));

            return;
        end;

        if v119.Name == "Lightweight Padding" then
            local v159 = script:GetAttribute("StatGreenColor");
            u115(p116, `Armor Mod Type: {v119.AttachmentType:upper()}`, (`Footstep Range: <font color="rgb({math.round(v159.R * 255)}, {math.round(v159.G * 255)}, {math.round(v159.B * 255)})">-25%</font>`));

            return;
        end;

        if v119.Name == "Resistant Rubber" then
            local v160 = script:GetAttribute("StatGreenColor");
            u115(p116, `Armor Mod Type: {v119.AttachmentType:upper()}`, (`Radiation Resistance: <font color="rgb({math.round(v160.R * 255)}, {math.round(v160.G * 255)}, {math.round(v160.B * 255)})">+5%</font>`));

            return;
        end;

        if v119.Name == "Armor Polish" then
            local v161 = script:GetAttribute("StatGreenColor");
            u115(p116, `Armor Mod Type: {v119.AttachmentType:upper()}`, (`Durability Damage: <font color="rgb({math.round(v161.R * 255)}, {math.round(v161.G * 255)}, {math.round(v161.B * 255)})">-25%</font>`));

            return;
        end;

        if v119.Name == "Steel Toes" then
            local v162 = script:GetAttribute("StatGreenColor");
            u115(p116, `Armor Mod Type: {v119.AttachmentType:upper()}`, (`Fall Damage: <font color="rgb({math.round(v162.R * 255)}, {math.round(v162.G * 255)}, {math.round(v162.B * 255)})">-25%</font>`));

            return;
        end;

        if v119.Name == "Snorkle" then
            local v163 = script:GetAttribute("StatGreenColor");
            u115(p116, `Armor Mod Type: {v119.AttachmentType:upper()}`, (`Breathing Time: <font color="rgb({math.round(v163.R * 255)}, {math.round(v163.G * 255)}, {math.round(v163.B * 255)})">+150%</font>`));

            return;
        end;

        if v119.Name == "Water Filter" then
            script:GetAttribute("StatGreenColor");
            u115(p116, `Armor Mod Type: {v119.AttachmentType:upper()}`, "Salt Water Filtering: YES", "Water Heal Max Health: 60");

            return;
        end;

        local AttachmentStats = v119.AttachmentStats;

        if AttachmentStats then
            local v164 = {};

            for i, v in pairs(AttachmentStats) do
                local v165 = i == "ZoomLevel";

                if i ~= "GunRecoilAimMult" and (type(v) == "number" and (v ~= 0 and (i:sub(#i - 3) == "Mult" or v165))) then
                    local v166 = v165 and i and i or i:sub(1, #i - 4);
                    local v167 = v166 == "Sway" and "Aim Sway" or v166:gsub("(%u)", " %1"):gsub("^%s", "");
                    local v168 = v165 and NumberUtil:RoundNumber(v, 2) or math.round(v * 100);
                    local v169 = math.abs(v168);
                    local v170 = v168 < 0 == (v166 == "Damage" and true or v166 == "FireRate");

                    if v165 then
                        v170 = v168 < 1.2;
                    end;

                    local v171 = script:GetAttribute(v170 and "StatRedColor" or "StatGreenColor");
                    local v172 = `{v167}: <font color="rgb({math.round(v171.R * 255)}, {math.round(v171.G * 255)}, {math.round(v171.B * 255)})">{(v165 and "" or (v168 < 0 and "-" or "+")) .. v169 .. (v165 and "x" or "%")}</font>`;
                    table.insert(v164, v172);
                end;
            end;

            u115(p116, unpack(v164));
        end;
    end;
end;

local function u187(u174, u175, u176, u177, u178) -- Line: 702
    -- upvalues: u2 (copy), u33 (ref), PreferredInputController (copy), NumberUtil (copy), RunService (copy), u11 (ref), Drag (copy)
    local u179 = nil;
    local u180 = 0;
    local u181 = false;
    u174["MouseButton" .. u175 .. "Down"]:Connect(function() -- Line: 706
        -- upvalues: u180 (ref), u175 (copy), u179 (ref), u2 (ref), u181 (ref), u33 (ref), PreferredInputController (ref), u174 (copy), NumberUtil (ref), u176 (copy), RunService (ref)
        u180 = u175;
        u179 = Vector2.new(u2.X, u2.Y);
        u181 = false;

        if not u33 then
            local v182 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

            if not v182 then
                while u180 > 0 and u174.Parent do
                    if not NumberUtil:IsWithin(u179, Vector2.new(u2.X, u2.Y), 5) then
                        if u176 then
                            local v183, v184 = u176(u181, u180);
                            u181 = v183;
                            u180 = v184;

                            return;
                        end;

                        break;
                    end;

                    RunService.RenderStepped:Wait();
                end;
            end;
        end;
    end);
    u174["MouseButton" .. u175 .. "Up"]:Connect(function() -- Line: 725
        -- upvalues: u33 (ref), u180 (ref), u178 (copy), u11 (ref), u175 (copy), u177 (copy), Drag (ref), RunService (ref), u181 (ref)
        if u33 then
            if u180 > 0 then
                local v185 = u180;
                u180 = 0;

                if u178 then
                    u178(v185);
                end;
            end;

            return;
        end;

        if not u11 or u11.Mouse ~= u175 then
            if u180 > 0 then
                local v186 = u180;
                u180 = 0;

                if u178 and not u181 then
                    u178(v186);
                end;
            end;

            return;
        end;

        if u177 then
            u177();
        end;

        Drag.Visible = false;
        RunService:UnbindFromRenderStep("Drag");
        u11 = nil;
    end);
end;

local function u192() -- Line: 754
    -- upvalues: u11 (ref), u4 (ref), UserInputService (copy), StateController (copy), u16 (ref)
    local Index = u11.Index;
    local v188 = u4[u11.Container];

    if v188 then
        local v189 = v188[Index];
        local v190 = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and not StateController:GetAttribute("IsSprint");
        local Mouse = u11.Mouse;
        local v191 = u11.IsActionMenu == true and u16;

        if not v191 then
            if Mouse == 1 and v190 then
                return 1;
            end;

            v191 = math.ceil(v189.Amount / (Mouse == 2 and v190 and 3 or Mouse));
        end;

        return v191;
    end;
end;

local function QuickStackBackpackSlot(p193, p194) -- Line: 766
    -- upvalues: u10 (ref), u4 (ref), u80 (copy), u19 (ref)
    local Container = u10.Container;
    local v195 = u4[Container];

    if not v195 then
        return;
    end;

    local v196 = v195[u10.Index];

    if not v196 or v196 == 0 then
        return;
    end;

    local Container2 = v196.Container;
    local v197;

    if Container2 == nil then
        v197 = false;
    else
        v197 = Container2[p194];
    end;

    if not v197 or v197 == 0 then
        return;
    end;

    u80(p193, Container, u10.Index, u19, true, p194, v197);
end;

local function u228() -- Line: 779
    -- upvalues: u10 (ref), u4 (ref), Items (copy), ActionMenu (copy), SkinsModule (copy), u110 (copy), u31 (ref), Backpack (copy), u32 (copy), u18 (ref), PreferredInputController (copy), GuiService (copy), QuickStackBackpackSlot (copy), u187 (copy), u11 (ref), u61 (copy), u192 (copy), SoundModule (copy), u1 (copy), ViewportModule (copy), ViewportFrame (copy), u16 (ref), u173 (copy), ItemStats2 (copy), u86 (copy), u25 (copy), UserService (copy)
    if u10 then
        local Container = u10.Container;
        local v198 = u4[Container];

        if not v198 then
            return;
        end;

        local Index = u10.Index;
        local v199 = v198[Index];

        if not v199 or (v199 == 0 or v199.Amount <= 0) then
            return;
        end;

        local v200 = Items[v199.ID];
        local Attachments = v199.Attachments;
        local Attachments2 = v200.Attachments;
        local Skin = v199.Skin;
        local v201 = v200.MaxAttachments or (1 / 0);
        local Image = v200.Image;
        local _ = v200.AmmoStats;
        local ConsumableStats = v200.ConsumableStats;
        local _ = v200.Resistances;
        local v202 = Image and (type(Image) == "table" and Image[Skin] or (Image or "")) or "";
        ActionMenu.Split.ItemImage.Image = v202;
        ActionMenu.ItemInfo.ItemImage.Image = v202;

        if Skin and Skin ~= "Default" then
            local v203 = "Common";
            local v204 = SkinsModule:GetSkinInfo((`{v200.Name}/{Skin}`));

            if type(v204) == "table" then
                v203 = v204.Rarity or v203;
            end;

            for _, child in ActionMenu.Skin:GetChildren() do
                if child:IsA("UIGradient") then
                    child.Enabled = child.Name == v203;
                end;
            end;

            ActionMenu.Skin.Text = Skin;
        else
            ActionMenu.Skin.Text = "";
        end;

        for i = 1, 4 do
            local v205 = ActionMenu.ItemDetails["Slot" .. i];

            if Attachments2 then
                u110(v205, Attachments[i]);
            end;

            v205.Checker.Visible = (Attachments2 and (math.min(#Attachments2, v201) or 0) or 0) < i;
            v205.Visible = Attachments2 ~= nil;
        end;

        local Container2 = v199.Container;

        if Container2 then
            local v206 = false;

            for _, v in Container2 do
                if v and v ~= 0 then
                    v206 = true;
                    break;
                end;
            end;

            if v206 or (Container == "Armor" or Container == "Bench") then
                if u31 ~= #Container2 then
                    for i = 1, math.max(u31, #Container2) do
                        local v207 = `Slot{i}`;
                        local v208;

                        if i <= u31 then
                            v208 = Backpack[v207];
                        else
                            v208 = false;
                        end;

                        if v208 or i > #Container2 then
                            if v208 and #Container2 < i then
                                v208:Destroy();
                                u32[v208] = nil;
                            end;
                        else
                            local v209 = Backpack.Slot1:Clone();
                            v209.Name = v207;
                            v209.Parent = Backpack;
                        end;
                    end;

                    u31 = #Container2;
                end;

                for i, v in Container2 do
                    local u210 = Backpack[`Slot{i}`];
                    u110(u210, v);

                    if not u32[u210] then
                        u32[u210] = true;
                        u210.InputChanged:Connect(function(p211) -- Line: 854
                            -- upvalues: u18 (ref), u10 (ref), PreferredInputController (ref), GuiService (ref), u210 (copy), QuickStackBackpackSlot (ref), i (copy)
                            if p211.UserInputType ~= Enum.UserInputType.MouseMovement or not (u18 and u10) then
                                return;
                            end;

                            local v212 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

                            if v212 and GuiService.SelectedObject ~= u210 then
                                return;
                            end;

                            QuickStackBackpackSlot(u210, i);
                        end);
                        u210.MouseButton2Click:Connect(function() -- Line: 860
                            -- upvalues: QuickStackBackpackSlot (ref), u210 (copy), i (copy)
                            QuickStackBackpackSlot(u210, i);
                        end);

                        for i2 = 1, 2 do
                            u187(u210, i2, function(p213, p214) -- Line: 864
                                -- upvalues: u10 (ref), u4 (ref), u11 (ref), i (copy), u61 (ref), u210 (copy)
                                local Slot = u10.Slot;
                                local v215 = u4[u10.Container];

                                if v215 then
                                    local v216 = v215[u10.Index];

                                    if v216 and (v216 ~= 0 and (v216.Amount > 0 and not u11)) then
                                        local Container3 = v216.Container;
                                        local v217;

                                        if Container3 == nil then
                                            v217 = false;
                                        else
                                            v217 = Container3[i];
                                        end;

                                        if v217 and v217 ~= 0 then
                                            p213 = u61(Slot, u210.ItemImage.Image, u10.Container, u10.Index, p214, nil, v217, i);
                                        end;
                                    end;
                                end;

                                return p213, p214;
                            end, function() -- Line: 878
                                -- upvalues: u10 (ref), u11 (ref), u4 (ref), u192 (ref), SoundModule (ref), u1 (ref)
                                if u10 then
                                    local Container3 = u11.Container;
                                    local Index2 = u11.Index;
                                    local v218 = u4[Container3];

                                    if not v218 then
                                        return;
                                    end;

                                    local v219 = v218[Index2];
                                    local v220 = u192();

                                    if v219 and (v219 ~= 0 and v220 > 0) then
                                        SoundModule:PlayItemSound(v219.ID, "Drop");
                                    end;

                                    u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", Container3, Index2, v220, u10.Container, u10.Index);
                                end;
                            end);
                        end;
                    end;
                end;
            else
                Container2 = nil;
            end;
        end;

        local v221 = Container2 ~= nil;

        if Backpack.Visible ~= v221 then
            local v222;

            if v221 then
                v222 = CFrame.new(-2, 0, 0);
            else
                v222 = CFrame.new();
            end;

            ViewportModule:TweenCamera(ViewportFrame, v222);
        end;

        Backpack.Visible = v221;
        local DropInfo = v200.DropInfo;

        if v200.Type == "Gun" then
            ActionMenu.Actions.Action1.Label.Text = "UNLOAD AMMO";
        elseif v200.Type:find("Consumable") and (ConsumableStats and ConsumableStats.Instant) then
            ActionMenu.Actions.Action1.Label.Text = "EAT";
        elseif DropInfo then
            ActionMenu.Actions.Action1.Label.Text = DropInfo.ButtonName;
        end;

        local v223 = v200.Type == "Gun";
        local v224 = v200.Type:find("Consumable") ~= nil;
        ActionMenu.Actions.Action1.Visible = v223 or (v224 or DropInfo ~= nil);
        u16 = u16 or math.ceil(v199.Amount / 2);
        u173(ItemStats2, v199.ID, v200);
        u86();
        local v225 = "[ERR]";
        local v226 = "[ERR]";
        local Owner = v199.Owner;

        if Owner then
            local v227 = u25[Owner];

            if not v227 or tick() - v227.Called >= 600 then
                local success, result = pcall(function() -- Line: 948
                    -- upvalues: UserService (ref), Owner (copy)
                    return UserService:GetUserInfosByUserIdsAsync({ Owner });
                end);

                if success and (result and #result > 0) then
                    v227 = result[1];
                    v227.Called = tick();
                end;
            end;

            if v227 then
                u25[Owner] = v227;
                v225 = `{v227.DisplayName}{not v227.HasVerifiedBadge and "" or utf8.char(57344)}`;

                if v227.DisplayName == v227.Username then
                    v226 = `@{v225}`;
                else
                    v226 = `{v225}(@{v227.Username})`;
                end;
            end;
        end;

        if u10 and (u10.Container == Container and u10.Index == Index) then
            ActionMenu.ItemName.Text = string.format(v200.Name, v225);
            ActionMenu.ItemInfo.ItemDesc.Text = string.format(v200.Description, v226);
        end;
    end;
end;

u41 = function(p229, p230, p231) -- Line: 969
    -- upvalues: u10 (ref), u4 (ref), SoundModule (copy), u228 (copy), u14 (ref), ActionMenu (copy), NumberUtil (copy), Size (copy), Backpack (copy), ViewportModule (copy), ViewportFrame (copy), u13 (ref), u83 (copy)
    local v232 = u10;

    if u10 and u10.Slot then
        u10.Slot.BackgroundColor3 = u10.Color;
    end;

    u10 = nil;

    if p229 and (not v232 or p229 ~= v232.Slot) then
        u10 = {
            Slot = p229,
            Container = p230,
            Index = p231,
            Color = p229.BackgroundColor3
        };
        p229.BackgroundColor3 = script:GetAttribute("SelectedSlotColor");
    end;

    local v233 = u10;

    if v233 ~= v232 then
        local v234 = v233 ~= nil;

        if v234 then
            local v235 = u4[v233.Container];

            if v235 then
                local v236 = v235[v233.Index];

                if v236 == nil or v236 == 0 then
                    v234 = false;
                else
                    v234 = v236.Amount > 0;
                end;

                if v234 then
                    SoundModule:PlayItemSound(v236.ID, "Drag");
                end;
            else
                v234 = false;
            end;
        end;

        u228();

        if u14 then
            ActionMenu.Size = NumberUtil:MultUDim2ByNum(Size, 1.3);
            u14 = false;
        end;

        ActionMenu:TweenSize(NumberUtil:MultUDim2ByNum(Size, v234 and 1 or 1.3), v234 and "Out" or "In", "Quart", 0.175, true);
        local v237 = tick();
        local v238 = v234 and 0 or 1;

        if not v234 then
            if Backpack.Visible then
                ViewportModule:TweenCamera(ViewportFrame, CFrame.new());
            end;

            Backpack.Visible = false;
        end;

        if u13 ~= v238 then
            u13 = v238;

            while true do
                local v239 = tick() - v237;
                local v240 = math.min(v239 / 0.1, 1);

                if v234 then
                    v240 = 1 - v240 or v240;
                end;

                u83(v240);

                if v239 >= 0.1 then
                    break;
                end;

                task.wait(0.016666666666666666);
            end;
        end;
    end;
end;

local function u247(p241, p242) -- Line: 1034
    -- upvalues: u11 (ref), u192 (copy), CurrentCamera (copy), u4 (ref), SoundModule (copy), u1 (copy)
    local Container = u11.Container;
    local Index = u11.Index;
    local IsActionMenu = u11.IsActionMenu;
    local EditIndex = u11.EditIndex;
    local v243 = u192();
    local v244;

    if p241 == "Drop" then
        v244 = CurrentCamera.CFrame;
    else
        v244 = false;
    end;

    local v245 = v244 and u4[Container];

    if v245 then
        local v246 = v245[Index];

        if v246 and v246 ~= 0 then
            SoundModule:PlayItemSound(v246.ID, "Drop");
        end;
    end;

    if (not IsActionMenu or type(IsActionMenu) ~= "number") and not EditIndex then
        u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", Container, Index, v243, p241, p242, "none", "none", v244);

        return;
    end;

    if EditIndex then
        v243 = nil;
    end;

    u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", Container, Index, v243, p241, p242, EditIndex and "RemoveItem" or "RemoveAttachment", EditIndex or IsActionMenu, v244);
end;

local function v267(u248, u249, u250) -- Line: 1074
    -- upvalues: TweenUtil (copy), NumberUtil (copy), u18 (ref), PreferredInputController (copy), GuiService (copy), u80 (copy), u19 (ref), u187 (copy), u4 (ref), u11 (ref), u61 (copy), u41 (ref), SoundModule (copy), u247 (copy), u33 (ref), Drag (copy), RunService (copy)
    local u251 = TweenUtil:Tween(u248, "Size", NumberUtil:MultUDim2ByNum(u248.Size, 1.05), 0.04, "Quart", "Out", true);
    local u252 = TweenUtil:Tween(u248, "Size", u248.Size, 0.46, "Elastic", "Out", true);
    local Checker = u248:FindFirstChild("Checker");
    u248.MouseEnter:Connect(function() -- Line: 1079
        -- upvalues: Checker (copy), u251 (copy), u252 (copy)
        if Checker and Checker.Visible then
            return;
        end;

        u251:Play();
        wait(0.04);
        u252:Play();
    end);
    u248.InputChanged:Connect(function(p253) -- Line: 1085
        -- upvalues: u18 (ref), PreferredInputController (ref), GuiService (ref), u248 (copy), u80 (ref), u249 (copy), u250 (copy), u19 (ref)
        if p253.UserInputType ~= Enum.UserInputType.MouseMovement or not u18 then
            return;
        end;

        local v254 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v254 and GuiService.SelectedObject ~= u248 then
            return;
        end;

        u80(u248, u249, u250, u19, true);
    end);

    for i = 1, 2 do
        u187(u248, i, function(p255, p256) -- Line: 1092
            -- upvalues: u4 (ref), u249 (copy), u250 (copy), u11 (ref), u61 (ref), u248 (copy)
            local v257 = u4[u249];

            if v257 then
                local v258 = v257[u250];

                if v258 and (v258 ~= 0 and not u11) then
                    p255 = u61(u248, u248.ItemImage.Image, u249, u250, p256, nil, v258);
                end;
            end;

            return p255, p256;
        end, function() -- Line: 1101
            -- upvalues: u11 (ref), u248 (copy), u41 (ref), u249 (copy), u250 (copy), u80 (ref), u19 (ref), u4 (ref), SoundModule (ref), u247 (ref)
            if u11.Slot == u248 then
                if u11.Mouse == 1 then
                    task.spawn(u41, u248, u249, u250);

                    return;
                end;

                task.spawn(u80, u248, u249, u250, u19);

                return;
            end;

            local Index = u11.Index;
            local v259 = u4[u11.Container];

            if v259 then
                local v260 = v259[Index];

                if v260 and v260 ~= 0 then
                    SoundModule:PlayItemSound(v260.ID, "Drop");
                end;
            end;

            u247(u249, u250);
        end, function(p261) -- Line: 1123
            -- upvalues: u80 (ref), u248 (copy), u249 (copy), u250 (copy), u19 (ref), PreferredInputController (ref), u33 (ref), u11 (ref), Drag (ref), RunService (ref), u4 (ref), SoundModule (ref), u247 (ref), u61 (ref), u41 (ref)
            if p261 == 2 then
                u80(u248, u249, u250, u19);

                return;
            end;

            local v262 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

            if v262 and script:GetAttribute("Open") then
                if u33 and u11 then
                    if u11.Slot == u248 then
                        Drag.Visible = false;
                        RunService:UnbindFromRenderStep("Drag");
                        u11 = nil;
                    else
                        local Index = u11.Index;
                        local v263 = u4[u11.Container];

                        if v263 then
                            local v264 = v263[Index];

                            if v264 and v264 ~= 0 then
                                SoundModule:PlayItemSound(v264.ID, "Drop");
                            end;
                        end;

                        u247(u249, u250);
                    end;

                    Drag.Visible = false;
                    RunService:UnbindFromRenderStep("Drag");
                    u11 = nil;
                    u33 = false;

                    return;
                end;

                local v265 = u4[u249];

                if v265 then
                    local v266 = v265[u250];

                    if not v266 or (v266 == 0 or (v266.Amount <= 0 or u11)) then
                        u41(u248, u249, u250);

                        return;
                    end;

                    u61(u248, u248.ItemImage.Image, u249, u250, 1, nil, v266);
                    u33 = true;
                end;
            else
                u41(u248, u249, u250);
            end;
        end);
    end;
end;

local function u272(u268, u269) -- Line: 1172
    -- upvalues: u11 (ref), ActionMenu (copy), Values (copy), u247 (copy), Drag (copy), RunService (copy)
    local u270 = 1;
    u268["MouseButton" .. 1 .. "Up"]:Connect(function() -- Line: 1174
        -- upvalues: u11 (ref), u270 (copy), u268 (copy), ActionMenu (ref), Values (ref), u269 (copy), u247 (ref), Drag (ref), RunService (ref)
        if not u11 or u11.Mouse ~= u270 then
            return;
        end;

        if u11.IsActionMenu and u268 == ActionMenu.Split then
            return;
        end;

        if Values.ClientDropping.Value and u269 then
            u247("Drop");
        end;

        Drag.Visible = false;
        RunService:UnbindFromRenderStep("Drag");
        u11 = nil;
    end);
    local u271 = 2;
    u268["MouseButton" .. 2 .. "Up"]:Connect(function() -- Line: 1174
        -- upvalues: u11 (ref), u271 (copy), u268 (copy), ActionMenu (ref), Values (ref), u269 (copy), u247 (ref), Drag (ref), RunService (ref)
        if not u11 or u11.Mouse ~= u271 then
            return;
        end;

        if u11.IsActionMenu and u268 == ActionMenu.Split then
            return;
        end;

        if Values.ClientDropping.Value and u269 then
            u247("Drop");
        end;

        Drag.Visible = false;
        RunService:UnbindFromRenderStep("Drag");
        u11 = nil;
    end);
end;

local function u273() -- Line: 1185
    -- upvalues: WheelController (copy), Humanoid (copy), u51 (copy)
    if not (WheelController:GetAttribute("Open") or Humanoid:GetAttribute("Downed")) then
        if Humanoid and Humanoid.Parent and Humanoid.Health > 0 then
            u51(script:GetAttribute("CurOpen") == "None" and "Inventory" or "None");
        end;
    end;
end;

local function u274() -- Line: 1190
    -- upvalues: WheelController (copy), Humanoid (copy), u51 (copy)
    if not (WheelController:GetAttribute("Open") or Humanoid:GetAttribute("Downed")) then
        if Humanoid and Humanoid.Parent and Humanoid.Health > 0 then
            u51(script:GetAttribute("CurOpen") == "Crafting" and "Inventory" or "Crafting");
        end;
    end;
end;

local function _() -- Line: 1195
    -- upvalues: u18 (ref)
    u18 = true;
end;

local function _() -- Line: 1199
    -- upvalues: u18 (ref)
    u18 = false;
end;

local function _() -- Line: 1203
    -- upvalues: u19 (ref)
    u19 = true;
end;

local function _() -- Line: 1207
    -- upvalues: u19 (ref)
    u19 = false;
end;

local function u276() -- Line: 1211
    -- upvalues: u4 (ref)
    local v275 = {};

    for i, v in pairs(u4) do
        if i == "Inventory" or i == "Toolbar" then
            for _, v2 in pairs(v) do
                if v2 and v2 ~= 0 then
                    local ID = v2.ID;
                    v275[ID] = (v275[ID] or 0) + v2.Amount;
                end;
            end;
        end;
    end;

    return v275;
end;

local function _() -- Line: 1225
    -- upvalues: u7 (copy), u17 (ref)
    local Bench = u7.Bench;

    if not u17 or (not u17.Parent or (not Bench or (not Bench.Parent or Bench.Name ~= "CraftingStation"))) then
        return;
    end;

    local v277 = u17:GetAttribute("ID");

    if v277 then
        return Bench, v277;
    end;
end;

local function u287(p278, p279, p280) -- Line: 1233
    -- upvalues: u7 (copy), u17 (ref), Items (copy), ResearchModule (copy), u5 (ref), u276 (copy), u26 (ref)
    if not (p278 and p279) then
        p278 = u7.Bench;

        if u17 and (u17.Parent and (p278 and (p278.Parent and p278.Name == "CraftingStation"))) then
            p279 = u17:GetAttribute("ID");

            if not p279 then
                p278 = nil;
                p279 = nil;
            end;
        else
            p278 = nil;
            p279 = nil;
        end;

        if not p278 then
            return;
        end;
    end;

    if not p280 then
        local v281 = Items[p279];

        if not v281 then
            return;
        end;

        local Name = v281.Name;
        local v282 = ResearchModule:GetInfoFromName(Name);

        if not v282 then
            return;
        end;

        p280 = v282.Tiers[(u5[Name] or 0) + 1];
    end;

    local v283 = p280 ~= nil;

    if p280 then
        local v284 = u276();

        for _, v in pairs(p280) do
            local ID = v.ID;
            local v285 = p278.UpgradeFrame.Items:FindFirstChild(ID);

            if v285 then
                local v286 = (v284[ID] or 0) >= v.Amount;
                v285.Grey.Visible = not v286;

                if not v286 then
                    v283 = false;
                end;
            end;
        end;
    end;

    if u26 and (v283 and not u26:IsToggled()) or v283 == false and u26:IsToggled() then
        task.defer(u26.ToggleButton, u26, v283);
    end;
end;

local function u303(p288, p289) -- Line: 1268
    -- upvalues: u7 (copy), u17 (ref), Items (copy), ResearchModule (copy), u5 (ref), NumberUtil (copy), u287 (copy)
    if not (p288 and p289) then
        p288 = u7.Bench;

        if u17 and (u17.Parent and (p288 and (p288.Parent and p288.Name == "CraftingStation"))) then
            p289 = u17:GetAttribute("ID");

            if not p289 then
                p288 = nil;
                p289 = nil;
            end;
        else
            p288 = nil;
            p289 = nil;
        end;

        if not p288 then
            return;
        end;
    end;

    local Items2 = p288.UnlocksFrame.Items;
    local Items3 = p288.UpgradeFrame.Items;

    for _, child in pairs(Items3:GetChildren()) do
        if child:IsA("ImageButton") then
            child:Destroy();
        end;
    end;

    for _, child in pairs(Items2:GetChildren()) do
        if child.Name ~= "Template" then
            child:Destroy();
        end;
    end;

    p288.UnlocksFrame.Maxed.Visible = false;
    local v290 = Items[p289];

    if not v290 then
        return;
    end;

    local Name = v290.Name;
    local v291 = ResearchModule:GetInfoFromName(Name);

    if not v291 then
        return;
    end;

    local Tiers = v291.Tiers;
    local Unlocks = v291.Unlocks;
    local v292 = u5[Name] or 0;
    local v293 = #Tiers <= v292;
    p288.Item.Label.Image = type(v290.Image) == "table" and v290.Image.Default or v290.Image;
    p288.CurrentTier.Text = `Current Tier: <font color="rgb(255, 248, 41)">{v292}</font>`;
    p288.UpgradeTier.Text = `Upgrade Current Tier: <font color="rgb(255, 248, 41)">{v292 .. (v293 and " (MAX)" or "")}</font>` .. (v293 and "" or ` -> <font color="rgb(255, 248, 41)">{v292 + 1 .. (v292 + 1 == #Tiers and " (MAX)" or "")}</font>`);

    if v293 then
        p288.UnlocksFrame.Maxed.Visible = true;
        p288.UpgradeFrame.Free.Text = "N/A";

        return;
    end;

    local v294 = Tiers[v292 + 1];
    local v295 = Unlocks[v292 + 1] or {};
    local v296 = math.floor((#v295 - 1) / 4) * 0.42 + 0.4;
    local v297 = math.max(v296, 1);
    Items2.CanvasSize = UDim2.new(0, 0, v297 * 0.76 - 0.001, 0);
    local Template = Items2.Template;
    Template.Size = UDim2.new(0.24, 0, 0.4 / v297, 0);
    local v298 = -1;

    for _, v in pairs(v295) do
        v298 = v298 + 1;
        local v299 = Items[v.ID];
        local u300 = Template:Clone();
        u300.Name = "Slot" .. v298 + 1;
        u300.ItemImage.Image = type(v299.Image) == "table" and v299.Image.Default or v299.Image;
        u300.ItemName.Text = v299.Name;
        u300.Position = UDim2.new(v298 % 4 * 0.25, 0, math.floor(v298 / 4) * 0.42 / v297, 0);
        u300.Parent = Items2;
        u300.MouseEnter:Connect(function() -- Line: 1318
            -- upvalues: u300 (copy)
            u300.ItemName:TweenPosition(UDim2.new(0.5, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.4, true);
        end);
        u300.MouseLeave:Connect(function() -- Line: 1321
            -- upvalues: u300 (copy)
            u300.ItemName:TweenPosition(UDim2.new(0.5, 0, -0.26, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.15, true);
        end);
        u300.Visible = true;
    end;

    for _, v in pairs(v294) do
        local v301 = Items[v.ID];
        local v302 = Items3.Layout.Template:Clone();
        v302.Name = tostring(v.ID);
        v302.ItemImage.Image = type(v301.Image) == "table" and v301.Image.Default or v301.Image;
        v302.ItemName.Text = v301.Name;
        v302.ItemAmount.Text = "x" .. NumberUtil:FormatNumber(v.Amount);
        v302.Parent = Items3;
    end;

    p288.UpgradeFrame.Free.Text = #v294 <= 0 and "FREE" or "";
    u287(p288, p289, v294);
end;

local u304 = {};
local u305 = nil;

local function u330(u306) -- Line: 1343
    -- upvalues: u4 (ref), u305 (ref), u304 (ref), Items (copy), u6 (ref), ButtonClass (copy), u28 (ref), u1 (copy), u17 (ref), RecipeModule (copy), ResearchModule (copy), u5 (ref), u276 (copy), NumberUtil (copy), u27 (ref)
    local Bench = u4.Bench;

    if not (Bench and (u306 and u306.Parent)) then
        return;
    end;

    local v307 = Bench[1];
    local v308 = v307 == 0 and 0 or v307.ID;
    local v309 = u305 == v308;
    u305 = v308;
    local Items2 = u306.CostFrame.Items;
    local Items3 = u306.SkinsFrame.Items;

    if not v309 then
        for _, child in pairs(Items2:GetChildren()) do
            if child:IsA("ImageButton") then
                child:Destroy();
            end;
        end;

        for i, v in pairs(u304) do
            v:Destroy();

            if i.Parent then
                i:Destroy();
            end;
        end;

        u304 = {};
    end;

    local v310 = false;
    u306.DetailExtra.Text = "";

    if type(v307) == "table" then
        local v311 = Items[v308];
        local Image = v311.Image;

        if type(Image) == "table" then
            if not v309 then
                local v312 = {};

                for i, _ in pairs(Image) do
                    local v313 = table.find(u6 or {}, v311.Name .. "/" .. i);

                    if i ~= "Default" and v313 then
                        table.insert(v312, i);
                    end;
                end;

                table.insert(v312, "Default");
                local v314 = math.floor((#v312 - 1) / 4) * 0.42 + 0.4;
                local v315 = math.max(v314, 1);
                Items3.CanvasSize = UDim2.new(0, 0, v315 * 0.76 - 0.001, 0);
                local Template = Items3.Template;
                Template.Size = UDim2.new(0.24, 0, 0.4 / v315, 0);
                local v316 = -1;

                for _, v in pairs(v312) do
                    v316 = v316 + 1;
                    local v317 = Template:Clone();
                    v317.Name = "Skin" .. v;
                    v317.ItemImage.Image = Image[v];
                    v317.ItemName.Text = v;
                    v317.Position = UDim2.new(v316 % 4 * 0.25 + 0.12, 0, (math.floor(v316 / 4) * 0.42 + 0.2) / v315, 0);
                    v317.Parent = Items3;
                    u304[v317] = ButtonClass.new(v317, "BackgroundColor3", function() -- Line: 1399
                        -- upvalues: u4 (ref), u306 (copy), u28 (ref), v (copy), u1 (ref), u17 (ref)
                        local Bench2 = u4.Bench;

                        if not (Bench2 and u306.Visible) then
                            return;
                        end;

                        local v318 = Bench2[1];

                        if tick() - u28 < 0.4 or (not v318 or (v318 == 0 or (v318.Amount <= 0 or v318.Skin == v))) then
                            return;
                        end;

                        u28 = tick();
                        u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u17, "Repair2", v);
                    end, 1.3, script:GetAttribute("SelectedSlotColor"));
                    v317.Visible = true;
                end;
            end;

            for i, v in pairs(u304) do
                local v319 = i.Name:sub(5);

                if v307.Skin == v319 and not v:IsToggled() then
                    task.defer(v.ToggleButton, v, true);
                elseif v307.Skin ~= v319 and v:IsToggled() then
                    task.defer(v.ToggleButton, v, false);
                end;
            end;

            u306.SkinsFrame.Visible = true;
        else
            u306.SkinsFrame.Visible = false;
        end;

        local v320 = (RecipeModule:GetRecipesForItem(v308) or {})[1];

        if v320 and (v307.Repair < 1 and v311.MaxDurability) then
            local BenchNeeded = v320.BenchNeeded;
            local TierNeeded = v320.TierNeeded;
            local v321 = 0.5;

            if (TierNeeded or 0) > 0 then
                local v322 = ResearchModule:GetInfoFromName(BenchNeeded);

                if v322 then
                    local _ = #v322.Tiers;
                    local v323 = TierNeeded - (u5[BenchNeeded] or 0);
                    v321 = v323 <= 0 and 0.5 or v323;

                    if v323 > 4 then
                        u306.CostFrame.Extra.Text = `Level {math.max(TierNeeded - 4, 0)} {BenchNeeded} or higher required.`;
                        v321 = nil;
                    elseif v321 > 0.5 then
                        u306.DetailExtra.Text = `<font color="rgb(255, 66, 69)">{math.round(v321 / 0.5)}X COST PENALTY</font> (<font color="rgb(0, 157, 255)">{v323}</font> more <font color="rgb(255, 248, 41)">{BenchNeeded}</font> tiers needed for no penalty)`;
                    end;
                end;
            end;

            if v321 then
                local v324 = RecipeModule:CalculateTotalCost(v320, v321, v320.SplitComponentOverride or { 24 }, v320.RepairOverride or { 6, 68, 179 });

                if not v309 then
                    for i, v in pairs(v324) do
                        local v325 = Items[v.ID];
                        local v326 = Items2.Layout.Template:Clone();
                        v326.Name = "Slot" .. i;
                        v326.ItemImage.Image = type(v325.Image) == "table" and v325.Image.Default or v325.Image;
                        v326.ItemName.Text = v325.Name;
                        v326.Parent = Items2;
                    end;
                end;

                local v327 = u276();
                v310 = true;

                for i, v in pairs(v324) do
                    local v328 = Items2:FindFirstChild("Slot" .. i);

                    if v328 then
                        v328.ItemAmount.Text = "x" .. NumberUtil:FormatNumber((math.ceil(v.Amount)));
                        local v329 = (v327[v.ID] or 0) < math.ceil(v.Amount);
                        v328.Grey.Visible = v329;

                        if v329 then
                            v310 = false;
                        end;
                    end;
                end;

                if v310 and v307.Durability >= (v311.MaxDurability or 0) * (1 - v307.Repair) - 0.01 then
                    v310 = false;
                end;

                u306.CostFrame.Extra.Text = "";
            end;
        else
            u306.CostFrame.Extra.Text = "Item unavailable for repairing.";
        end;
    else
        u306.SkinsFrame.Visible = false;
        u306.CostFrame.Extra.Text = "Insert an item into the slot to Repair.";
    end;

    if not u27 then
        return;
    end;

    if v310 and not u27:IsToggled() then
        task.defer(u27.ToggleButton, u27, true);

        return;
    end;

    if not v310 and u27:IsToggled() then
        task.defer(u27.ToggleButton, u27, false);
    end;
end;

UserInputService.InputBegan:Connect(function(p331, p332) -- Line: 1492
    -- upvalues: SettingsModule (copy), UserInputService (copy), u273 (copy), u274 (copy), u18 (ref), u19 (ref), WheelController (copy), Humanoid (copy), InteractController (copy), u51 (copy), u33 (ref), u10 (ref), ActionMenu (copy), u2 (copy), u4 (ref), u11 (ref), u61 (copy), u34 (ref), u40 (copy), Values (copy), u247 (copy), Drag (copy), RunService (copy), u1 (copy), CurrentCamera (copy), u41 (ref)
    if SettingsModule.MainMenuOpen() then
        return;
    end;

    local UserInputType = p331.UserInputType;
    local v333 = UserInputService:GetFocusedTextBox();

    if UserInputType == Enum.UserInputType.Keyboard and not v333 then
        local Name = p331.KeyCode.Name;

        if Name == SettingsModule.GetSetting("Controls", "Open Inventory") then
            u273();

            return;
        end;

        if Name == SettingsModule.GetSetting("Controls", "Open Crafting") then
            u274();

            return;
        end;

        if Name == SettingsModule.GetSetting("Controls", "Quick Loot") and not p332 then
            u18 = true;

            return;
        end;

        if Name == "LeftShift" then
            u19 = true;
        end;
    elseif UserInputType == Enum.UserInputType.Gamepad1 then
        local Name = p331.KeyCode.Name;
        local v334 = script:GetAttribute("Open");
        local v335 = script:GetAttribute("CurOpen");

        if Name == SettingsModule.GetSetting("Gamepad", "Open Inventory/Crafting") then
            if WheelController:GetAttribute("Open") or Humanoid:GetAttribute("Downed") then
                return;
            end;

            if not (Humanoid and Humanoid.Parent and Humanoid.Health > 0) or InteractController:GetAttribute("Dialog") then
                return;
            end;

            if not v334 then
                u51("Inventory");

                return;
            end;

            if v335 == "Inventory" then
                u51("Crafting");

                return;
            end;

            if v335 == "Crafting" then
                u51("Inventory");
            end;
        else
            if Name == "ButtonB" and v334 then
                u51("None");

                return;
            end;

            if Name == SettingsModule.GetSetting("Gamepad", "Jump") and (v334 and (not u33 and (u10 and ActionMenu.Visible))) then
                local Split = ActionMenu.Split;
                local AbsolutePosition = Split.AbsolutePosition;
                local AbsoluteSize = Split.AbsoluteSize;
                local v336 = Split.Visible and (u2.X >= AbsolutePosition.X and (u2.X <= AbsolutePosition.X + AbsoluteSize.X and (u2.Y >= AbsolutePosition.Y and (u2.Y <= AbsolutePosition.Y + AbsoluteSize.Y and u4[u10.Container]))));

                if v336 then
                    local v337 = v336[u10.Index];

                    if v337 and v337 ~= 0 then
                        if not u11 then
                            u61(u10.Slot, u10.Slot.ItemImage.Image, u10.Container, u10.Index, 1, true, v337);
                        end;

                        u33 = true;
                        u34 = true;
                    end;
                end;
            elseif Name == SettingsModule.GetSetting("Gamepad", "Jump") and (v334 and (u33 and u11)) then
                if not u40() then
                    if Values.ClientDropping.Value then
                        u247("Drop");
                    end;

                    Drag.Visible = false;
                    RunService:UnbindFromRenderStep("Drag");
                    u11 = nil;
                    u33 = false;
                end;
            elseif Name == SettingsModule.GetSetting("Gamepad", "Interact/Reload") and v334 then
                if u33 and u11 then
                    Drag.Visible = false;
                    RunService:UnbindFromRenderStep("Drag");
                    u11 = nil;
                    u33 = false;

                    return;
                end;

                local v338, v339, v340 = u40();

                if v338 then
                    if not u10 or (u10.Slot ~= v338 or not Values.ClientDropping.Value) then
                        u41(v338, v339, v340);

                        return;
                    end;

                    local Container = u10.Container;
                    local Index = u10.Index;
                    local v341 = u4[Container];

                    if v341 then
                        local v342 = v341[Index];

                        if v342 and (v342 ~= 0 and v342.Amount > 0) then
                            u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", Container, Index, nil, "Drop", "none", "none", "none", CurrentCamera.CFrame);
                        end;
                    end;
                elseif u10 then
                    u41(nil);
                end;
            elseif Name == "ButtonR2" and v334 then
                u18 = true;
            end;
        end;
    end;
end);
UserInputService.InputEnded:Connect(function(p343, p344) -- Line: 1589
    -- upvalues: UserInputService (copy), u15 (ref), u33 (ref), u11 (ref), u34 (ref), u40 (copy), Values (copy), u247 (copy), Drag (copy), RunService (copy), SettingsModule (copy), u18 (ref), u19 (ref)
    local UserInputType = p343.UserInputType;
    local v345 = UserInputService:GetFocusedTextBox();

    if UserInputType == Enum.UserInputType.MouseButton1 then
        u15 = false;

        if u33 and u11 then
            if u34 then
                u34 = false;

                return;
            end;

            if not u40() then
                if Values.ClientDropping.Value then
                    u247("Drop");
                end;

                Drag.Visible = false;
                RunService:UnbindFromRenderStep("Drag");
                u11 = nil;
                u33 = false;
            end;
        elseif u11 and (u11.Mouse == 1 and not p344) then
            if Values.ClientDropping.Value then
                u247("Drop");
            end;

            Drag.Visible = false;
            RunService:UnbindFromRenderStep("Drag");
            u11 = nil;
        end;
    else
        if UserInputType == Enum.UserInputType.MouseButton2 and (u11 and (u11.Mouse == 2 and not p344)) then
            if Values.ClientDropping.Value then
                u247("Drop");
            end;

            Drag.Visible = false;
            RunService:UnbindFromRenderStep("Drag");
            u11 = nil;

            return;
        end;

        if UserInputType == Enum.UserInputType.Keyboard and not v345 then
            local Name = p343.KeyCode.Name;

            if Name == SettingsModule.GetSetting("Controls", "Quick Loot") then
                u18 = false;

                return;
            end;

            if Name == "LeftShift" then
                u19 = false;
            end;
        elseif UserInputType == Enum.UserInputType.Gamepad1 then
            local Name = p343.KeyCode.Name;
            local v346 = script:GetAttribute("Open");

            if Name == SettingsModule.GetSetting("Gamepad", "Jump") and v346 then
                u15 = false;

                return;
            end;

            if Name == "ButtonR2" and v346 then
                u18 = false;
            end;
        end;
    end;
end);
ViewmodelController.AttributeChanged:Connect(function(p347) -- Line: 1638
    -- upvalues: ViewmodelController (copy), u110 (copy), Toolbar (copy), u4 (ref)
    if p347 ~= "LocalAmmo" then
        return;
    end;

    local v348 = ViewmodelController:GetAttribute("Equipped");

    if v348 <= 0 then
        return;
    end;

    u110(Toolbar["Slot" .. v348], u4.Toolbar[v348], ViewmodelController:GetAttribute("LocalAmmo"));
end);
Humanoid.Died:Connect(function() -- Line: 1645
    -- upvalues: ItemSearchModule (copy), Drag (copy), RunService (copy), u11 (ref), ViewportModule (copy), ViewportFrame (copy), WheelController (copy), u51 (copy)
    ItemSearchModule.CancelSearch(true);
    Drag.Visible = false;
    RunService:UnbindFromRenderStep("Drag");
    u11 = nil;
    ViewportModule:ClearViewport(ViewportFrame);
    WheelController:SetAttribute("Open", false);
    u51("None", true);
end);
Humanoid:GetAttributeChangedSignal("Downed"):Connect(function() -- Line: 1653
    -- upvalues: Humanoid (copy), WheelController (copy), u51 (copy)
    if not Humanoid:GetAttribute("Downed") then
        return;
    end;

    WheelController:SetAttribute("Open", false);
    u51("None", true);
end);
PreferredInputController:GetAttributeChangedSignal("PreferredInput"):Connect(function() -- Line: 1659
    -- upvalues: PreferredInputController (copy), CraftingKeyboard (copy), CraftingConsole (copy), CraftingKeyboard2 (copy), CraftingConsole2 (copy), ImageLabel (copy), GamepadService (copy)
    local v349 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";
    CraftingKeyboard.Visible = not v349;
    CraftingConsole.Visible = v349;
    CraftingKeyboard2.Visible = not v349;
    CraftingConsole2.Visible = v349;
    ImageLabel.Visible = v349;

    if not script:GetAttribute("Open") then
        return;
    end;

    if v349 then
        pcall(function() -- Line: 1668
            -- upvalues: GamepadService (ref)
            GamepadService:EnableGamepadCursor(nil);
        end);

        return;
    end;

    pcall(function() -- Line: 1670
        -- upvalues: GamepadService (ref)
        GamepadService:DisableGamepadCursor();
    end);
end);
u272(HitboxHead, false);
u272(HitboxChest, false);
u272(HitboxLegs, false);

for _, child in Stats:GetChildren() do
    if child:IsA("ImageButton") or child:IsA("TextButton") then
        u272(child, false);
    end;
end;

Stats.ChildAdded:Connect(function(p350) -- Line: 1681
    -- upvalues: u272 (copy)
    if not (p350:IsA("ImageButton") or p350:IsA("TextButton")) then
        return;
    end;

    u272(p350, false);
end);

for _, child in Team:GetChildren() do
    if child:IsA("ImageButton") or child:IsA("TextButton") then
        u272(child, false);
    end;
end;

ClientSignals:WaitForChild("Inventory").OnClientEvent:Connect(function(...) -- Line: 1691
    -- upvalues: u17 (ref), Benches (copy), u26 (ref), ButtonClass (copy), u28 (ref), u1 (copy), u303 (copy), u29 (ref), Values (copy), u110 (copy), SoundModule (copy), u7 (copy), u4 (ref), u27 (ref), u51 (copy), u22 (copy), u23 (ref), u24 (ref), NumberUtil (copy), u5 (ref), TweenUtil (copy), ViewmodelController (copy), u10 (ref), u41 (ref), u228 (copy), u330 (copy), CraftingController (copy), u287 (copy), ViewportModule (copy), ViewportFrame (copy), u11 (ref), Drag (copy), RunService (copy), ActiveBenchModule (copy), ItemClass (copy)
    local v351 = false;
    local v352 = false;
    local v353 = false;
    local v354 = false;
    local v355 = false;
    local v356 = false;

    for _, v in pairs({ ... }) do
        if type(v) == "table" then
            local v357 = v[1];

            if v357 then
                local v358 = v[2];
                local v359 = v[3];
                local v360 = v[4];
                local v361 = u4[v357];
                local v362 = u7[v357];

                if v361 and v362 then
                    if v360 == "LocalAmmo" and v359.Ammo then
                        ViewmodelController:SetAttribute("LocalAmmo", v359.Ammo.Amount);
                    end;

                    local v363 = (v362:FindFirstChild("Inv") or v362):FindFirstChild("Slot" .. v358);
                    local v364 = v361[v358];

                    if u10 and (u10.Slot == v363 and (v364 ~= 0 and (v359 == 0 or v364.ID ~= v359.ID))) then
                        task.defer(u41);
                    end;

                    if v351 == false and (v357 == "Inventory" or v357 == "Toolbar") and (v359 and v364) then
                        v351 = (v359 == 0 and 0 or v359.ID) ~= (v364 == 0 and 0 or v364.ID) and true or ((v359 == 0 and 0 or v359.Amount) ~= (v364 == 0 and 0 or v364.Amount) and true or v351);
                    end;

                    v361[v358] = v359;

                    if u10 and u10.Slot == v363 then
                        u228();
                    end;

                    if v363 then
                        u110(v363, v359, nil, v352);
                    end;

                    v356 = v357 == "Armor" and true or v356;

                    if v357 == "Bench" and v362.Name == "RepairTable" then
                        u330(v362);
                        v355 = true;
                    end;
                end;
            else
                local Bench = u7.Bench;

                if Bench then
                    local Upkeep = v.Upkeep;
                    local UpkeepTick = v.UpkeepTick;
                    local RL = v.RL;
                    local Offers = v.Offers;
                    local MaxPower = v.MaxPower;
                    local CurrentPower = v.CurrentPower;

                    if v.On == nil then
                        if Upkeep and UpkeepTick then
                            local C = Bench:FindFirstChild("C");

                            if C then
                                local ProtectionFrame = Bench:FindFirstChild("ProtectionFrame");

                                if ProtectionFrame then
                                    for _, child in pairs(Bench:GetChildren()) do
                                        if child.Name:sub(1, 4) == "Cost" and child:IsA("ImageButton") then
                                            child:Destroy();
                                        end;
                                    end;

                                    for i, v2 in pairs(Upkeep) do
                                        local v365 = C:Clone();
                                        v365.Position = UDim2.new(0.5 - (#Upkeep - 1) * 0.1 + (i - 1) * 0.2, 0, 0.711, 0);
                                        v365.Name = "Cost" .. i;
                                        v365.Parent = Bench;
                                        u110(v365, v2);
                                        v365.Visible = true;
                                    end;

                                    u23 = UpkeepTick;

                                    if not u24 then
                                        u24 = true;
                                        Values.ServerTick.Changed:Connect(function() -- Line: 1814
                                            -- upvalues: u23 (ref), Values (ref), ProtectionFrame (copy), NumberUtil (ref)
                                            local v366 = math.max(u23 - Values.ServerTick.Value, 0);

                                            if not (ProtectionFrame and ProtectionFrame.Parent) then
                                                return;
                                            end;

                                            ProtectionFrame.Timer.TextColor3 = ProtectionFrame.Timer:GetAttribute(v366 > 0 and "Protected" or "Decaying");
                                            ProtectionFrame.Timer.Text = v366 > 0 and NumberUtil:FormatTime(v366, "Days", "Minutes", true) or "Base is Decaying!";
                                        end);
                                    end;
                                end;
                            end;
                        elseif RL then
                            u5 = v.RL;
                            v354 = true;
                        elseif type(Offers) == "table" and not v353 then
                            v353 = Offers;
                        elseif type(v.ShpAnim) == "number" and (u7.Bench and u7.Bench.Name == "TradingPost") then
                            local v367 = u7.Bench:FindFirstChild("Trade" .. v.ShpAnim);

                            if v367 then
                                v367.Arrow.Rotation = 0;
                                TweenUtil:Tween(v367.Arrow, "Rotation", 360, 0.5, "Quart", "InOut");
                            end;
                        elseif CurrentPower and (u7.Bench and u7.Bench.Name == "Battery") then
                            local Bar = u7.Bench.Bar;
                            u7.Bench.PowerLabel.Text = CurrentPower .. "kw / " .. MaxPower .. "kw";
                            Bar.Fill.Size = UDim2.new(CurrentPower / MaxPower, 0, 1, 0);
                        end;
                    else
                        local ControlFrame = Bench:FindFirstChild("ControlFrame");

                        if ControlFrame then
                            local Toggle2 = ControlFrame:FindFirstChild("Toggle");

                            if Toggle2 then
                                local v368 = u22[Toggle2];

                                if v368 then
                                    Toggle2.Label.Text = v.On and "Turn Off" or "Turn On";
                                    v368:ToggleButton(v.On);
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        elseif v == "IgnoreVMUpdate" then
            v352 = true;
        elseif typeof(v) == "Instance" then
            u17 = v;
        elseif type(v) == "string" and v:sub(1, 5) == "Bench" then
            local v369 = Benches:FindFirstChild(v:sub(6));

            if not v369 then
                return;
            end;

            for _, child in pairs(Benches:GetChildren()) do
                child.Visible = child == v369;

                if child == v369 and child:FindFirstChild("BenchName") then
                    local v370 = child:FindFirstChild("Inv") or child;
                    local Name = u17.Name;
                    local NameTag = u17:FindFirstChild("NameTag");
                    local v371 = Name == "Sleeper";
                    child.BenchName.Text = u17:GetAttribute("BenchName") or Name == "Body Bag" and "CORPSE OF <b>" .. (u17:GetAttribute("OwnerName") or "[ERR]") .. "</b>" or (v371 and `INVENTORY OF <b>{NameTag and NameTag.Label.Text or "[ERR]"}</b>` or Name:upper());

                    if child.Name == "BodyLoot" then
                        child.BenchName.Position = UDim2.new(v371 and 0.808 or 0.858, 0, 0.36, 0);
                    elseif child.Name == "CraftingStation" then
                        if not u26 then
                            u26 = ButtonClass.new(child.UpgradeFrame.Upgrade, "BackgroundColor3", function() -- Line: 1723
                                -- upvalues: u28 (ref), u17 (ref), u1 (ref)
                                if tick() - u28 < 0.5 or not (u17 and u17.Parent) then
                                    return;
                                end;

                                u28 = tick();
                                u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u17, "Upgrade");
                            end, 1.3, Color3.fromRGB(89, 148, 64));
                        end;

                        u303(child, u17:GetAttribute("ID"));
                    elseif child.Name == "Plinko" then
                        u29 = u17:GetAttribute("PlinkoIndex");
                        child.Timer.Text = Values["PlinkoTimer" .. u29].Value .. "s";
                    end;

                    for _, child2 in pairs(v370:GetChildren()) do
                        if child2.Name:sub(1, 4) == "Slot" and child2:IsA("ImageButton") then
                            u110(child2, 0);
                            local Checker = child2:FindFirstChild("Checker");

                            if Checker then
                                Checker.Visible = true;
                            end;
                        end;
                    end;
                end;
            end;

            SoundModule:PlayBenchSound(u17.Name, v369 and v369.Name == "TradingPost" and "Open2" or "Open", u17:GetAttribute("Skin"));
            u7.Bench = v369;
            local v372 = v369:FindFirstChild("Inv") or v369;
            local v373 = {};

            for _, child in pairs(v372:GetChildren()) do
                if child.Name:sub(1, 4) == "Slot" then
                    table.insert(v373, 0);
                end;
            end;

            u4.Bench = v373;

            if v369.Name == "RepairTable" and not u27 then
                u27 = ButtonClass.new(v369.CostFrame.Repair, "BackgroundColor3", function() -- Line: 1758
                    -- upvalues: u17 (ref), u28 (ref), u27 (ref), u1 (ref)
                    if not u17 or (not u17.Parent or (tick() - u28 < 0.4 or not u27:IsToggled())) then
                        return;
                    end;

                    u28 = tick();
                    u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u17, "Repair1");
                end, 1.3, Color3.fromRGB(89, 148, 64));
            end;

            u51("Inventory");
        end;
    end;

    if v354 then
        CraftingController.Update:Fire("Research");
        u303();
    elseif v351 then
        u287();
        CraftingController.Update:Fire();
        local Bench = u7.Bench;

        if Bench and (Bench.Parent and (Bench.Name == "RepairTable" and not v355)) then
            u330(Bench);
        end;
    end;

    if v356 then
        ViewportModule:UpdateArmors(ViewportFrame, u4.Armor);
    end;

    if u11 then
        local v374 = u4[u11.Container];

        if v374 then
            if v374[u11.Index] == 0 then
                Drag.Visible = false;
                RunService:UnbindFromRenderStep("Drag");
                u11 = nil;
            end;
        elseif u11.Container == "Bench" then
            Drag.Visible = false;
            RunService:UnbindFromRenderStep("Drag");
            u11 = nil;
        end;
    end;

    if v353 and (u7.Bench and (u7.Bench.Name == "TradingPost" and (u4.Bench and (u17 and u17.Parent)))) then
        local v375 = ActiveBenchModule.GetClientInfo(u17);
        local v376;

        if type(v375) == "table" then
            v376 = v375.CanEdit == true;
        else
            v376 = false;
        end;

        local Bench = u7.Bench;
        local v377 = 1;
        local v378 = 2;

        for i = 1, 5 do
            local v379 = Bench[`Give{i}`];
            local v380 = Bench[`Receive{i}`];
            local v381 = u22[Bench[`Trade{i}`]];
            local v382 = u22[v379];
            local v383 = u22[v380];
            local v384 = v353[v377];
            local v385 = v353[v378];
            local v386 = (type(v384) ~= "table" or (v384[1] == 0 or v384[2] < 0)) and 0 or ItemClass.new(v384[1], v384[2]);
            local v387, v388;

            if type(v385) == "table" and (v385[1] ~= 0 and v385[2] > 0) then
                if u17:GetAttribute("ShopOnly") then
                    v387 = ItemClass.new(v385[1], v385[2]);
                    v388 = true;
                else
                    local v389 = 0;
                    local v390 = nil;

                    for _, v in pairs(u4.Bench) do
                        if v ~= 0 and v.ID == v385[1] then
                            v389 = v389 + v.Amount;

                            if not v390 then
                                v390 = v;
                            end;
                        end;
                    end;

                    if v390 then
                        v387 = table.clone(v390);
                        v387.Amount = v385[2];
                    else
                        v387 = ItemClass.new(v385[1], v385[2]);
                    end;

                    if v385[2] <= v389 then
                        v388 = type(v386) == "table";
                    else
                        v388 = false;
                    end;
                end;
            else
                v387 = 0;
                v388 = false;
            end;

            if v382 then
                v382:Enable(v376);
            end;

            if v383 then
                v383:Enable(v376);
            end;

            if v381 and (not v388 and v381:IsToggled()) or v388 and not v381:IsToggled() then
                task.defer(v381.ToggleButton, v381, v388);
            end;

            u110(v379, v386);

            if type(v386) == "table" then
                v379.ItemAmount.Text = `x{NumberUtil:FormatNumber(v386.Amount)}`;
            end;

            u110(v380, v387);

            if type(v387) == "table" then
                v380.ItemAmount.Text = `x{NumberUtil:FormatNumber(v387.Amount)}`;
            end;

            v377 = v377 + 2;
            v378 = v378 + 2;
        end;
    end;
end);
u1("Setup", "\156\2I=\144i\181\249\200\249\198Q\20\205\1431\142\1\1391", "\140^\1720\244\2504\202,\206\1\142\2236\218!\233fN\t", function(p391, ...) -- Line: 1996
    -- upvalues: u7 (copy), u42 (copy)
    local v392 = { ... };

    if p391 == "Close" then
        local Bench = u7.Bench;

        if not Bench or Bench.Name ~= v392[1] then
            return;
        end;

        u42();
    end;
end);

function Fetch.OnInvoke() -- Line: 2008
    -- upvalues: u4 (ref), u5 (ref), u6 (ref)
    return u4, u5, u6;
end;

function GetBench.OnInvoke() -- Line: 2014
    -- upvalues: u17 (ref)
    return u17;
end;

ItemStats.OnInvoke = u173;
Toggle.Event:Connect(u51);
script:WaitForChild("EquipArmor").Event:Connect(function(p393) -- Line: 2020
    -- upvalues: Toolbar (copy), u80 (copy), u19 (ref)
    u80(Toolbar[`Slot{p393}`], "Toolbar", p393, u19, "ArmorEquip");
end);
BG.Visible = true;
Inventory.Visible = true;
Crafting.Visible = true;
CraftingKeyboard.Visible = not v37();
CraftingConsole.Visible = v37();
local v394 = SettingsModule.GetSetting("Controls", "Open Crafting");
CraftingKeyboard.Text = `CRAFTING [<font color="rgb(255, 244, 88)">{v394}</font>]`;
CraftingConsole.Text = "CRAFTING    ";
CraftingKeyboard2.Text = `INVENTORY [<font color="rgb(255, 244, 88)">{v394}</font>]`;
CraftingConsole2.Text = "INVENTORY    ";
CraftingKeyboard2.Visible = not v37();
CraftingConsole2.Visible = v37();
ImageLabel.Visible = v37();
u51("None", true);
u83(1);
ActionMenu.Visible = false;
local v395, v396, v397 = u1(
    "Fire",
    "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217",
    "\163\246\172\'\216w\147D\2045\1\143IH\142\236Zk1\28"
);
u4 = v395;
u5 = v396;
u6 = v397;
ViewportModule:Initialize();
ViewportModule:ShowCharacter(ViewportFrame, Parent, { HitboxChest, HitboxHead, HitboxLegs }, u4.Armor);
script:SetAttribute("Initiated", true);
ActionMenu.SplitBar.MouseButton1Down:Connect(function() -- Line: 2049
    -- upvalues: u10 (ref), u4 (ref), u15 (ref), u2 (copy), ActionMenu (copy), u16 (ref), u86 (copy), RunService (copy)
    local v398 = u10;

    if v398 then
        local v399 = u4[v398.Container];

        if not v399 then
            return;
        end;

        local v400 = v399[v398.Index];

        if v400 and (v400 ~= 0 and v400.Amount > 0) then
            u15 = true;

            while u15 and (u10 and u10 == v398) do
                local v401 = math.clamp((u2.X - ActionMenu.SplitBar.AbsolutePosition.X) / ActionMenu.SplitBar.AbsoluteSize.X, 0, 1);
                local v402 = v400.Amount * math.clamp(v401, 0, 1);
                u16 = math.ceil(v402);
                u86();
                RunService.Heartbeat:Wait();
            end;
        end;
    end;
end);
u272(ActionMenu.SplitBar, true);
u187(ActionMenu.Split, 1, function(p403, p404) -- Line: 2068
    -- upvalues: u10 (ref), u4 (ref), u11 (ref), u61 (copy)
    if u10 then
        local Slot = u10.Slot;
        local v405 = u4[u10.Container];

        if v405 and Slot then
            local v406 = v405[u10.Index];

            if v406 and (v406 ~= 0 and not u11) then
                p403 = u61(Slot, Slot.ItemImage.Image, u10.Container, u10.Index, p404, true, v406);
            end;
        end;
    end;

    return p403, p404;
end);
u272(ActionMenu.Split, true);
pcall(function() -- Line: 2083
    -- upvalues: RunService (copy)
    RunService:UnbindFromRenderStep("SliderTextPosition");
end);
RunService:BindToRenderStep("SliderTextPosition", Enum.RenderPriority.Last.Value, function() -- Line: 2086
    -- upvalues: ActionMenu (copy)
    ActionMenu.SplitBar.Amount.Position = UDim2.new(math.max(ActionMenu.SplitBar.Fill.Size.X.Scale, 0.1), 0, 0.5, 0);
end);

for i = 1, 4 do
    local u407 = ActionMenu.ItemDetails["Slot" .. i];
    u187(u407, 1, function(p408, p409) -- Line: 2092
        -- upvalues: u10 (ref), u4 (ref), u11 (ref), i (copy), u61 (copy), u407 (copy)
        local Slot = u10.Slot;
        local v410 = u4[u10.Container];

        if v410 then
            local v411 = v410[u10.Index];

            if v411 and (v411 ~= 0 and (v411.Amount > 0 and not u11)) then
                local v412 = v411.Attachments[i];

                if v412 then
                    p408 = u61(Slot, u407.ItemImage.Image, u10.Container, u10.Index, p409, i, v412);
                end;
            end;
        end;

        return p408, p409;
    end, function() -- Line: 2105
        -- upvalues: u10 (ref), u11 (ref), u4 (ref), SoundModule (copy), u1 (copy)
        if u10 then
            local Container = u11.Container;
            local Index = u11.Index;
            local v413 = u4[Container];

            if not v413 then
                return;
            end;

            local v414 = v413[Index];

            if v414 and (v414 ~= 0 and v414.Amount > 0) then
                SoundModule:PlayItemSound(v414.ID, "Drop");
            end;

            u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", Container, Index, v414.Amount, u10.Container, u10.Index);
        end;
    end, function(p415) -- Line: 2123
        -- upvalues: PreferredInputController (copy), u10 (ref), u11 (ref), u4 (ref), i (copy), u61 (copy), u407 (copy), u33 (ref)
        local v416 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

        if v416 and (u10 and not u11) then
            local v417 = u4[u10.Container];
            local v418 = v417 and v417[u10.Index];
            local v419 = v418 and (v418 ~= 0 and (v418.Amount > 0 and v418.Attachments[i]));

            if v419 then
                u61(u10.Slot, u407.ItemImage.Image, u10.Container, u10.Index, p415, i, v419);
                u33 = true;
            end;
        end;
    end);
end;

for _, child in pairs(ActionMenu.Actions:GetChildren()) do
    local Name = child.Name;
    child.Activated:Connect(function() -- Line: 2141
        -- upvalues: u10 (ref), u4 (ref), Items (copy), Name (copy), Values (copy), u1 (copy), CurrentCamera (copy), u30 (ref)
        if u10 then
            local Container = u10.Container;
            local Index = u10.Index;
            local v420 = u4[Container];

            if v420 then
                local v421 = v420[Index];

                if v421 and (v421 ~= 0 and v421.Amount > 0) then
                    local v422 = Items[v421.ID];

                    if Name == "Drop" and Values.ClientDropping.Value then
                        u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", Container, Index, nil, "Drop", "none", "none", "none", CurrentCamera.CFrame);

                        return;
                    end;

                    if Name == "Action1" then
                        local DropInfo = v422.DropInfo;

                        if v422.Type == "Gun" and (v421.Ammo and v421.Ammo.Amount > 0) then
                            u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", Container, Index, "UnloadAmmo");

                            return;
                        end;

                        if DropInfo then
                            u1("Fire", "\136\189BE\23r\255\1<\18\185S9\215\198\26B\245\16\217", "E\1\190\156a`O;8\201\21480MNv\127\190\255\23", Container, Index, "ItemDrop");

                            return;
                        end;

                        if v422.Type:find("Consumable") then
                            local v423 = tick();

                            if v423 - u30 < 0.15 then
                                return;
                            end;

                            u30 = v423;
                            u1("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "\245A\150x@\231Er*\173\173b\191\178\1\138|\178\150\187", Container, Index);
                        end;
                    end;
                end;
            end;
        end;
    end);
    u272(child, true);
end;

for i, v in pairs(u4) do
    for i2, v2 in pairs(v) do
        local v424 = u7[i];

        if v424 then
            local v425 = v424["Slot" .. i2];
            v267(v425, i, i2);
            u110(v425, v2);
        end;
    end;
end;

for _, child in pairs(Benches:GetChildren()) do
    child.Visible = false;
    local v426 = child:FindFirstChild("Inv") or child;

    for _, child2 in pairs(v426:GetChildren()) do
        if v426.Name == "TradingPost" then
            local u427 = 0;
            local v428 = child2.Name:gsub("%D", "");
            local u429 = tonumber(v428);
            local v430 = child2.Name:sub(1, 4) == "Give";

            if child2.Name:sub(1, 5) == "Trade" then
                child2.BackgroundColor3 = child2:GetAttribute("ColorOff");
                u22[child2] = ButtonClass.new(child2, "BackgroundColor3", function() -- Line: 2215
                    -- upvalues: u17 (ref), u427 (ref), u1 (copy), u429 (copy)
                    if not u17 then
                        return;
                    end;

                    local v431 = tick();

                    if v431 - u427 < 0.2 then
                        return;
                    end;

                    u427 = v431;
                    u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u17, "ShopBuy", u429);
                end, 1.3, child2:GetAttribute("ColorOn"));
            elseif v430 or child2.Name:sub(1, 7) == "Receive" then
                local u432 = u429 * 2 - (v430 and 1 or 0);
                u22[child2] = ButtonClass.new(child2, "BackgroundColor3", function() -- Line: 2228
                    -- upvalues: u17 (ref), ItemSearchModule (copy), u427 (ref), u1 (copy), u432 (copy)
                    if not u17 or (not u17.Parent or (u17:GetAttribute("OffersLocked") or ItemSearchModule.IsSearching())) then
                        return;
                    end;

                    local v433 = tick();

                    if v433 - u427 < 0.2 then
                        return;
                    end;

                    u427 = v433;
                    local v434, v435 = ItemSearchModule.BeginSearch();

                    if not (v434 and v435) then
                        return;
                    end;

                    u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u17, "ShopUpdate", (`{u432}/{v434}/{v435}`));
                end, 1.3, Color3.fromRGB(75, 35, 35), function() -- Line: 2240
                    -- upvalues: u17 (ref), u427 (ref), u1 (copy), u432 (copy)
                    if not u17 then
                        return;
                    end;

                    local v436 = tick();

                    if v436 - u427 < 0.2 then
                        return;
                    end;

                    u427 = v436;
                    u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u17, "ShopUpdate", (`{u432}/0/0`));
                end);
            end;
        else
            if v426.Name == "ArmorStand" and child2.Name == "Swap" then
                local u437 = false;
                child2.BackgroundColor3 = child2:GetAttribute("ColorOn");
                u22[child2] = ButtonClass.new(child2, "BackgroundColor3", function() -- Line: 2256
                    -- upvalues: u17 (ref), u437 (ref), child2 (copy), TweenUtil (copy), u22 (copy), u1 (copy)
                    if not u17 then
                        return;
                    end;

                    if u437 then
                        return;
                    end;

                    u437 = true;
                    child2.Arrow.Rotation = 0;
                    TweenUtil:Tween(child2.Arrow, "Rotation", 360, 0.5, "Quart", "InOut");
                    task.spawn(u22[child2].ToggleButton, u22[child2], true);
                    u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u17, "StandSwap");
                    task.wait(1);

                    if not child2.Parent then
                        return;
                    end;

                    u437 = false;
                    u22[child2]:ToggleButton(false);
                end, 1.3, child2:GetAttribute("ColorOff"));
            end;

            if child2.Name:sub(1, 4) == "Slot" then
                local v438 = tonumber(child2.Name:sub(5));

                if v438 then
                    v267(child2, "Bench", v438);
                    u110(child2, 0);
                end;
            end;
        end;
    end;

    local u439 = 0;
    local ControlFrame = child:FindFirstChild("ControlFrame");

    if ControlFrame then
        local Toggle2 = ControlFrame:FindFirstChild("Toggle");

        if Toggle2 then
            Toggle2.BackgroundColor3 = Toggle2:GetAttribute("ColorOff");
            u22[Toggle2] = ButtonClass.new(Toggle2, "BackgroundColor3", function() -- Line: 2285
                -- upvalues: u17 (ref), u439 (ref), u1 (copy), u22 (copy), Toggle2 (copy)
                if not u17 then
                    return;
                end;

                local v440 = tick();

                if v440 - u439 < 0.2 then
                    return;
                end;

                u439 = v440;
                u1("Fire", "\151\234\n\219\1715KF\162l\239L\1[\150fF\3\157D", "\240`\1`O\159\252\242~E\23\213K\175\17\t\227c\31\130", u17, u22[Toggle2]:IsToggled() and "Turn Off" or "Turn On");
            end, 1.3, Toggle2:GetAttribute("ColorOn"));
        end;
    end;
end;

for i = 1, 4 do
    local u441 = Values:WaitForChild("PlinkoTimer" .. i);
    u441:GetPropertyChangedSignal("Value"):Connect(function() -- Line: 2300
        -- upvalues: i (copy), u29 (ref), Benches (copy), u441 (copy)
        if i ~= u29 or not Benches.Plinko.Visible then
            return;
        end;

        Benches.Plinko.Timer.Text = u441.Value .. "s";
    end);
end;