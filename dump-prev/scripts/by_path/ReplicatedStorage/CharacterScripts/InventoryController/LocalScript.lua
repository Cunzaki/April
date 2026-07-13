-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local UserInputService_upv_1 = game:GetService("UserInputService");
local RunService_upv_1 = game:GetService("RunService");
local UserService_upv_1 = game:GetService("UserService");
local _ = game:GetService("SoundService");
local GamepadService_upv_1 = game:GetService("GamepadService");
local GuiService_upv_1 = game:GetService("GuiService");
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Values_upv_1 = ReplicatedStorage_1:WaitForChild("Values");
local v341 = ReplicatedStorage_1:WaitForChild("LocalSounds");
local ClientSignals_1 = ReplicatedStorage_1:WaitForChild("ClientSignals");
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local TweenUtil_upv_1 = require(Modules_1:WaitForChild("TweenUtil"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local ButtonClass_upv_1 = require(Modules_1:WaitForChild("ButtonClass"));
local ViewportModule_upv_1 = require(Modules_1:WaitForChild("ViewportModule"));
local SoundModule_upv_1 = require(Modules_1:WaitForChild("SoundModule"));
local ToolInfo_upv_1 = require(Modules_1:WaitForChild("ToolInfo"));
local ResearchModule_upv_1 = require(Modules_1:WaitForChild("ResearchModule"));
local RecipeModule_upv_1 = require(Modules_1:WaitForChild("RecipeModule"));
local ItemClass_upv_1 = require(Modules_1:WaitForChild("ItemClass"));
local GamepadIconModule_1 = require(Modules_1:WaitForChild("GamepadIconModule"));
local ItemSearchModule_upv_1 = require(Modules_1:WaitForChild("ItemSearchModule"));
ItemSearchModule_upv_1.CancelSearch(true);
local SettingsModule_upv_1 = require(Modules_1:WaitForChild("SettingsModule"));
local ActiveBenchModule_upv_1 = require(Modules_1:WaitForChild("ActiveBenchModule"));
local SkinsModule_upv_1 = require(Modules_1:WaitForChild("SkinsModule"));
local u1 = require(Modules_1:WaitForChild("AssetContainer"))();
local Fetch_1 = script:WaitForChild("Fetch");
local GetBench_1 = script:WaitForChild("GetBench");
local ItemStats_1 = script:WaitForChild("ItemStats");
local Toggle_1 = script:WaitForChild("Toggle");
local LocalPlayer_1 = Players_1.LocalPlayer;
local Parent_1 = script.Parent;
local PlayerGui_1 = LocalPlayer_1:WaitForChild("PlayerGui");
local Humanoid_upv_1 = Parent_1:WaitForChild("Humanoid");
local u2 = LocalPlayer_1:GetMouse();
local CurrentCamera_upv_1 = workspace.CurrentCamera;
local ViewmodelController_upv_1 = Parent_1:WaitForChild("ViewmodelController");
local WheelController_upv_1 = Parent_1:WaitForChild("WheelController");
local CraftingController_upv_1 = Parent_1:WaitForChild("CraftingController");
local StateController_upv_1 = Parent_1:WaitForChild("StateController");
local TeamNavigationController_upv_1 = Parent_1:WaitForChild("TeamNavigationController");
local InteractController_upv_1 = Parent_1:WaitForChild("InteractController");
local PreferredInputController_upv_1 = LocalPlayer_1:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local Main_1 = PlayerGui_1:WaitForChild("Main");
local Boombox_upv_1 = PlayerGui_1:WaitForChild("Boombox");
local BG_upv_1 = Main_1:WaitForChild("BG");
local Inventory_upv_1 = Main_1:WaitForChild("Inventory");
local Toolbar_upv_1 = Main_1:WaitForChild("Toolbar");
local Drag_upv_1 = Main_1:WaitForChild("Drag");
local Inv_1 = Inventory_upv_1:WaitForChild("Inv");
local Backpack_upv_1 = Inventory_upv_1:WaitForChild("Backpack");
local ActionMenu_upv_1 = Inventory_upv_1:WaitForChild("ActionMenu");
local ImageLabel_upv_1 = ActionMenu_upv_1:WaitForChild("Actions"):WaitForChild("Drop"):WaitForChild("Label"):WaitForChild("ImageLabel");
GamepadIconModule_1.Register(ImageLabel_upv_1, "ButtonX");
local ItemStats_upv_2 = ActionMenu_upv_1:WaitForChild("ItemStats");
local Benches_upv_1 = Inventory_upv_1:WaitForChild("Benches");
local Armor_1 = Inventory_upv_1:WaitForChild("Armor");
local ViewportFrame_upv_1 = Armor_1:WaitForChild("ViewportFrame");
local HitboxChest_1 = Armor_1:WaitForChild("HitboxChest");
local HitboxHead_1 = Armor_1:WaitForChild("HitboxHead");
local HitboxLegs_1 = Armor_1:WaitForChild("HitboxLegs");
local CraftingKeyboard_upv_1 = Inventory_upv_1:WaitForChild("CraftingKeyboard");
local CraftingConsole_upv_1 = Inventory_upv_1:WaitForChild("CraftingConsole");
GamepadIconModule_1.Register(CraftingConsole_upv_1:WaitForChild("ImageLabel"), "ButtonY");
local Crafting_upv_1 = Main_1:WaitForChild("Crafting");
local CraftingKeyboard_upv_2 = Crafting_upv_1:WaitForChild("CraftingKeyboard");
local CraftingConsole_upv_2 = Crafting_upv_1:WaitForChild("CraftingConsole");
GamepadIconModule_1.Register(CraftingConsole_upv_2:WaitForChild("ImageLabel"), "ButtonY");
local Stats_1 = Main_1:WaitForChild("Stats");
local Team_1 = Main_1:WaitForChild("Team");
local GamepadControls_1 = Main_1:WaitForChild("GamepadControls");
local ToolTip_upv_1 = GamepadControls_1:WaitForChild("ToolTip");
local tbl_upv_1 = {GamepadControls_1:WaitForChild("TopControls"), GamepadControls_1:WaitForChild("ToolbarRight"), GamepadControls_1:WaitForChild("ToolbarLeft")};
local DragEntry_upv_1 = ToolTip_upv_1:WaitForChild("DragEntry");
local MenuEntry_upv_1 = ToolTip_upv_1:WaitForChild("MenuEntry");
local TransferEntry_upv_1 = ToolTip_upv_1:WaitForChild("TransferEntry");
GamepadIconModule_1.Register(DragEntry_upv_1:FindFirstChildWhichIsA("ImageLabel"), "ButtonA");
GamepadIconModule_1.Register(MenuEntry_upv_1:FindFirstChildWhichIsA("ImageLabel"), "ButtonX");
local u3 = {};
local u4 = {};
local u5 = {};
local tbl_upv_2 = {};
tbl_upv_2.Inventory = Inv_1;
tbl_upv_2.Toolbar = Toolbar_upv_1;
tbl_upv_2.Armor = Armor_1;
local u6 = nil;
local u7 = nil;
local tbl_upv_3 = nil;
local u8 = nil;
local tbl_upv_4 = nil;
local u9 = 1;
local Size_upv_1 = ActionMenu_upv_1.Size;
local u10 = true;
local u11 = false;
local u12 = nil;
local u13 = nil;
local u14 = false;
local u15 = false;
local u16 = 0;
local u17 = 0;
local tbl_upv_5 = {};
local u18 = 0;
local u19 = false;
local tbl_upv_6 = {};
local u20 = nil;
local u21 = nil;
local u22 = 0;
local u23 = 1;
local u24;
local v1_1;
do
    local u25 = 0;
    local u26 = 1;
    local tbl_upv_7 = {};
    local u27 = false;
    local u28 = false;
    local u29 = nil;
    local u30 = nil;
    local u31;
    local function u32()
        --[[
          line: 186
          upvalues:
            SoundModule_upv_1 (copy, index: 1)
            u13 (ref,  index: 2)
            ItemSearchModule_upv_1 (copy, index: 3)
            tbl_upv_2 (copy, index: 4)
            u31 (ref,  index: 5)
            u8 (ref,  index: 6)
            Drag_upv_1 (copy, index: 7)
            RunService_upv_1 (copy, index: 8)
            tbl_upv_3 (ref,  index: 9)
            u30 (ref,  index: 10)
        ]]
        SoundModule_upv_1:PlayBenchSound(u13 and (u13.Name), "Close");
        ItemSearchModule_upv_1.CancelSearch(true);
        u13 = nil;
        local Bench_1 = tbl_upv_2.Bench;
        if (Bench_1 and Bench_1.Parent) then
            Bench_1.Visible = false;
        end;
        tbl_upv_2.Bench = nil;
        u31.Bench = nil;
        if (u8 and u8.Container == "Bench") then
            Drag_upv_1.Visible = false;
            RunService_upv_1:UnbindFromRenderStep("Drag");
            u8 = nil;
        end;
        if (not tbl_upv_3 or tbl_upv_3.Container ~= "Bench") then
            return;
        end;
        u30(nil);
    end;
    local function u33(a1, a2)
        --[[
          line: 204
          upvalues:
            u6 (ref,  index: 1)
            TweenUtil_upv_1 (copy, index: 2)
            BG_upv_1 (copy, index: 3)
            u7 (ref,  index: 4)
            PreferredInputController_upv_1 (copy, index: 5)
            u29 (ref,  index: 6)
            Humanoid_upv_1 (copy, index: 7)
            GamepadService_upv_1 (copy, index: 8)
            u13 (ref,  index: 9)
            u1 (copy, index: 10)
            u32 (copy, index: 11)
            Drag_upv_1 (copy, index: 12)
            RunService_upv_1 (copy, index: 13)
            u8 (ref,  index: 14)
            Inventory_upv_1 (copy, index: 16)
            Crafting_upv_1 (copy, index: 17)
            TeamNavigationController_upv_1 (copy, index: 18)
            UserInputService_upv_1 (copy, index: 19)
            Boombox_upv_1 (copy, index: 20)
            SettingsModule_upv_1 (copy, index: 21)
            CraftingKeyboard_upv_1 (copy, index: 22)
            CraftingConsole_upv_1 (copy, index: 23)
            CraftingKeyboard_upv_2 (copy, index: 24)
            CraftingConsole_upv_2 (copy, index: 25)
            ToolTip_upv_1 (copy, index: 26)
            DragEntry_upv_1 (copy, index: 27)
            MenuEntry_upv_1 (copy, index: 28)
            TransferEntry_upv_1 (copy, index: 29)
            tbl_upv_1 (copy, index: 30)
            u2 (copy, index: 31)
        ]]
        if (not (u6)) then
            u6 = TweenUtil_upv_1:Tween(BG_upv_1, "BackgroundTransparency", 0.5, 0.15, "Quart", "Out", true);
            u7 = TweenUtil_upv_1:Tween(BG_upv_1, "BackgroundTransparency", 1, 0.15, "Quart", "In", true);
        end;
        local v2 = a1 ~= "None";
        if (v2) then
            if (a2) then
                BG_upv_1.BackgroundTransparency = 0.5;
            else
                u6:Play();
            end;
            local v3 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
            if (v3 and not (u29)) then
                u29 = Humanoid_upv_1.WalkSpeed;
                Humanoid_upv_1.WalkSpeed = 0;
            end;
            local v4 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
            if (v4) then
                pcall(
                    function()
                        --[[
                          line: 224
                          upvalues:
                            GamepadService_upv_1 (copy, index: 1)
                        ]]
                        GamepadService_upv_1:EnableGamepadCursor(nil);
                    end
                );
            end;
        else
            if (u13 and u13.Parent) then
                u1("Fire", "\156\002I=\144i\181\249\200\249\198Q\020\205\1431\142\001\1391", "\140^\1720\244\2504\202,\206\001\142\2236\218!\233fN\t", "Close", u13);
            end;
            u32();
            if (a2) then
                BG_upv_1.BackgroundTransparency = 1;
            else
                u7:Play();
            end;
            Drag_upv_1.Visible = false;
            RunService_upv_1:UnbindFromRenderStep("Drag");
            u8 = nil;
            u8 = false;
            if (u29) then
                Humanoid_upv_1.WalkSpeed = u29;
                u29 = nil;
            end;
            pcall(
                function()
                    --[[
                      line: 247
                      upvalues:
                        GamepadService_upv_1 (copy, index: 1)
                    ]]
                    GamepadService_upv_1:DisableGamepadCursor();
                end
            );
        end;
        local v5 = UDim2.new(((a1 == "Crafting") and 1) or (((a1 ~= "Inventory") and -1) or 0), 0, 0, 0);
        local v6 = (v2 and "Out") or "In";
        Inventory_upv_1:TweenPosition(v5, v6, "Quart", (a2 and 0) or 0.1, true);
        local v7 = UDim2.new(((a1 == "Crafting") and 0) or (((a1 ~= "Inventory") and -2) or -1), 0, 0, 0);
        local v8 = (v2 and "Out") or "In";
        Crafting_upv_1:TweenPosition(v7, v8, "Quart", (a2 and 0) or 0.1, true);
        if (not (TeamNavigationController_upv_1:GetAttribute("MapOpen")) or v2) then
            UserInputService_upv_1.MouseBehavior = Enum.MouseBehavior[(v2 and "Default") or "LockCenter"];
            UserInputService_upv_1.MouseIconEnabled = v2;
        end;
        Boombox_upv_1.Enabled = Boombox_upv_1.Enabled and v2;
        script:SetAttribute("Open", v2);
        script:SetAttribute("CurOpen", a1);
        local v9 = SettingsModule_upv_1.GetSetting("Controls", "Open Crafting");
        local v10 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
        CraftingKeyboard_upv_1.Text = ("CRAFTING [<font color=\"rgb(255, 244, 88)\">%*</font>]"):format(v9);
        CraftingConsole_upv_1.Text = "CRAFTING    ";
        CraftingKeyboard_upv_1.Visible = not v10;
        CraftingConsole_upv_1.Visible = v10;
        CraftingKeyboard_upv_2.Text = ("INVENTORY [<font color=\"rgb(255, 244, 88)\">%*</font>]"):format(v9);
        CraftingConsole_upv_2.Text = "INVENTORY    ";
        CraftingKeyboard_upv_2.Visible = not v10;
        CraftingConsole_upv_2.Visible = v10;
        if (not (v2)) then
            script:SetAttribute("ClosedTick", tick());
        end;
        local v11 = v2 and (PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad"));
        ToolTip_upv_1.Visible = v11;
        if (a1 == "Crafting") then
            DragEntry_upv_1.Visible = true;
            DragEntry_upv_1.Text = " - Double Tap Craft";
            MenuEntry_upv_1.Visible = false;
            TransferEntry_upv_1.Visible = false;
        else
            DragEntry_upv_1.Visible = true;
            DragEntry_upv_1.Text = " - Drag Item";
            MenuEntry_upv_1.Visible = true;
            TransferEntry_upv_1.Visible = true;
        end;
        for _, value_1 in pairs(tbl_upv_1) do
            value_1.Visible = not v2;
        end;
        if (v11) then
            pcall(
                function()
                    --[[
                      line: 293
                      upvalues:
                        RunService_upv_1 (copy, index: 1)
                    ]]
                    RunService_upv_1:UnbindFromRenderStep("GamepadTooltip");
                end
            );
            RunService_upv_1:BindToRenderStep(
                "GamepadTooltip",
                Enum.RenderPriority.Last.Value,
                function()
                    --[[
                      line: 294
                      upvalues:
                        ToolTip_upv_1 (copy, index: 1)
                        u2 (copy, index: 2)
                    ]]
                    ToolTip_upv_1.Position = UDim2.new(0, u2.X - 10, 0, (u2.Y - ToolTip_upv_1.AbsoluteSize.Y) + 80);
                end
            );
        else
            pcall(
                function()
                    --[[
                      line: 298
                      upvalues:
                        RunService_upv_1 (copy, index: 1)
                    ]]
                    RunService_upv_1:UnbindFromRenderStep("GamepadTooltip");
                end
            );
        end;
    end;
    local function u34(a1, a2, a3, a4, a5, a6, a7, a8)
        --[[
          line: 302
          upvalues:
            u8 (ref,  index: 1)
            Drag_upv_1 (copy, index: 2)
            RunService_upv_1 (copy, index: 3)
            u2 (copy, index: 4)
            SoundModule_upv_1 (copy, index: 5)
        ]]
        if (script:GetAttribute("Open")) then
            u8 = {Slot = a1, Container = a3, Index = a4, Mouse = a5, IsActionMenu = a6, EditIndex = a8};
            Drag_upv_1.Image = a2;
            local u35 = false;
            RunService_upv_1:BindToRenderStep(
                "Drag",
                Enum.RenderPriority.Input.Value + 1,
                function()
                    --[[
                      line: 317
                      upvalues:
                        u35 (ref,  index: 1)
                        Drag_upv_1 (copy, index: 2)
                        u2 (copy, index: 3)
                    ]]
                    if (not (u35)) then
                        Drag_upv_1.Visible = true;
                        u35 = true;
                    end;
                    Drag_upv_1.Position = UDim2.new(0, u2.X + 1, 0, u2.Y + 1);
                end
            );
            SoundModule_upv_1:PlayItemSound(a7.ID, "Drag");
            return true;
        end;
    end;
    local function u36(a1, a2, a3, a4, a5, a6, a7)
        --[[
          line: 328
          upvalues:
            u31 (ref,  index: 1)
            Backpack_upv_1 (copy, index: 3)
            u13 (ref,  index: 4)
            u16 (ref,  index: 5)
            SoundModule_upv_1 (copy, index: 6)
            RunService_upv_1 (copy, index: 7)
            u17 (ref,  index: 8)
            u1 (copy, index: 9)
        ]]
        if (a5 ~= "ArmorEquip" and not (script:GetAttribute("Open"))) then
            return;
        end;
        local v12 = u31[a2];
        if (not v12) then
            return;
        end;
        if (tick() - (a1.Fill:GetAttribute("Cooldown") or 0) >= 0.4) then
            local v13 = nil;
            if (not a1.Fill.Visible) then
                v13 = v12[a3];
                if (v13) then
                    local v14 = nil;
                    if (v13 ~= 0 and (not a7 or a7 and a7 ~= 0)) then
                        local ID_1 = (a7 or v13).ID;
                        a1.Fill.Visible = true;
                        v14 = Backpack_upv_1.Visible;
                        local v15 = nil;
                        if (v14) then
                            v15 = not u13;
                            if (v15) then
                                local v16 = true;
                                if (a2 == "Inventory") then
                                    v14 = v16;
                                else
                                    v14 = a2 == "Toolbar";
                                end;
                            else
                                v14 = v15;
                            end;
                        end;
                        local v17;
                        if (a5 == "ArmorEquip") then
                            v17 = 0.9;
                        elseif (u13) then
                            if (a2 ~= "Armor" or v14 or a7) then
                                v17 = 0.3;
                            else
                                v17 = 0.1;
                            end;
                        elseif (v14 or a7) then
                            v17 = 0.3;
                        else
                            v17 = 0.1;
                        end;
                        local v18 = false;
                        local v19 = 0;
                        if (a5) then
                            u16 = u16 + 1;
                        end;
                        SoundModule_upv_1:PlayItemSound(ID_1, "Drag");
                        v19 = nil;
                        while ((u31[a2])) do
                            if (v12[a3] and v12[a3] ~= 0) then
                                local v20 = math.min(v19, v17);
                                local v21 = v20 / v17;
                                local v22;
                                if (a5) then
                                    v22 = 1 - v21;
                                else
                                    v22 = v21;
                                end;
                                local v23 = math.clamp(v22, 0, 1);
                                a1.Fill.Size = UDim2.new(1, 0, v23, 0);
                                a1.Fill.Position = UDim2.new(0, 0, 1 - v23, 0);
                                if (v17 > v20) then
                                    local v24 = RunService_upv_1.Heartbeat:Wait();
                                    if (not (a5)) then
                                        v19 = v19 + v24;
                                        continue;
                                    end;
                                    if (u17 >= nil) then
                                        v19 = v19 + v24;
                                        continue;
                                    end;
                                else
                                    v18 = true;
                                end;
                            end;
                            break;
                        end;
                        if (v18) then
                            SoundModule_upv_1:PlayItemSound(ID_1, "Drop");
                            if (v14) then
                                u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", a2, a3, nil, "Armor", 8);
                            elseif (a7) then
                                u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", a2, a3, "QuickStack", a4, a6);
                            else
                                u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", a2, a3, "QuickStack", a4);
                            end;
                        end;
                        a1.Fill:SetAttribute("Cooldown", tick());
                        a1.Fill.Visible = false;
                        if (not a5) then
                            return;
                        end;
                        u17 = u17 + 1;
                    end;
                end;
            end;
        end;
    end;
    local function u37(a1)
        --[[
          line: 404
          upvalues:
            tbl_upv_4 (ref,  index: 1)
            ActionMenu_upv_1 (copy, index: 2)
            NumberUtil_upv_1 (copy, index: 3)
        ]]
        if (not (tbl_upv_4)) then
            tbl_upv_4 = {};
            local v25 = nil;
            local v26 = nil;
            for _, value_2 in pairs(ActionMenu_upv_1:GetDescendants()) do
                v26 = value_2:IsA("UIGradient");
                if (v26) then
                    continue;
                end;
                if (value_2:IsA("TextLabel")) then
                    v25 = "Text";
                    local v27 = ("%*Transparency"):format(v25);
                    tbl_upv_4[value_2] = {v27, value_2[v27]};
                    continue;
                end;
                if (value_2:IsA("UIStroke")) then
                    v25 = "";
                    local v27 = ("%*Transparency"):format(v25);
                    tbl_upv_4[value_2] = {v27, value_2[v27]};
                    continue;
                end;
                if (value_2:IsA("Frame")) then
                    v25 = "Background";
                    local v27 = ("%*Transparency"):format(v25);
                    tbl_upv_4[value_2] = {v27, value_2[v27]};
                    continue;
                end;
                if (value_2.Image ~= "") then
                    v25 = "Image";
                else
                    v25 = "Background";
                end;
                local v27 = ("%*Transparency"):format(v25);
                tbl_upv_4[value_2] = {v27, value_2[v27]};
            end;
        end;
        for key_1, value_3 in tbl_upv_4 do
            key_1[value_3[1]] = NumberUtil_upv_1:Lerp(value_3[2], 1, a1);
        end;
        ActionMenu_upv_1.Visible = a1 < 1;
    end;
    local function u38()
        --[[
          line: 421
          upvalues:
            tbl_upv_3 (ref,  index: 1)
            u31 (ref,  index: 2)
            u12 (ref,  index: 3)
            ActionMenu_upv_1 (copy, index: 4)
            NumberUtil_upv_1 (copy, index: 5)
        ]]
        local v28 = nil;
        if (tbl_upv_3) then
            v28 = u31[tbl_upv_3.Container];
            local v29;
            if (not v28) then
                return;
            end;
            v29 = v28[tbl_upv_3.Index];
            if (v29 and v29 ~= 0 and v29.Amount > 0) then
                u12 = math.clamp(u12, 1, v29.Amount);
                ActionMenu_upv_1.SplitBar.Fill:TweenSize(UDim2.new(u12 / v29.Amount, 0, 1, 0), "Out", "Quart", 0.15, true);
                ActionMenu_upv_1.SplitBar.Amount.Text = NumberUtil_upv_1:FormatNumber(u12);
                return;
            end;
        end;
    end;
    local function u39(a1, a2, a3, a4, a5)
        --[[
          line: 702
          upvalues:
            u2 (copy, index: 1)
            u27 (ref,  index: 2)
            PreferredInputController_upv_1 (copy, index: 3)
            NumberUtil_upv_1 (copy, index: 4)
            RunService_upv_1 (copy, index: 5)
            u8 (ref,  index: 6)
            Drag_upv_1 (copy, index: 7)
        ]]
        local u40 = nil;
        local u41 = 0;
        local u42 = false;
        a1["MouseButton" .. a2 .. "Down"]:Connect(
            function()
                --[[
                  line: 706
                  upvalues:
                    u41 (ref,  index: 1)
                    a2 (copy, index: 2)
                    u40 (ref,  index: 3)
                    u2 (copy, index: 4)
                    u42 (ref,  index: 5)
                    u27 (ref,  index: 6)
                    PreferredInputController_upv_1 (copy, index: 7)
                    a1 (copy, index: 8)
                    NumberUtil_upv_1 (copy, index: 9)
                    a3 (copy, index: 10)
                    RunService_upv_1 (copy, index: 11)
                ]]
                u41 = a2;
                u40 = Vector2.new(u2.X, u2.Y);
                u42 = false;
                local v30;
                if (u27) then
                    return;
                end;
                v30 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                if (v30) then
                    return;
                end;
                while (a2 > 0 and (a1.Parent)) do
                    if (NumberUtil_upv_1:IsWithin(u40, Vector2.new(u2.X, u2.Y), 5)) then
                        RunService_upv_1.RenderStepped:Wait();
                        continue;
                    end;
                    if (not (a3)) then
                        break;
                    end;
                    u42, u41 = a3(u42, a2);
                    return;
                end;
            end
        );
        a1["MouseButton" .. a2 .. "Up"]:Connect(
            function()
                --[[
                  line: 725
                  upvalues:
                    u27 (ref,  index: 1)
                    u41 (ref,  index: 2)
                    a5 (copy, index: 3)
                    u8 (ref,  index: 4)
                    a2 (copy, index: 5)
                    a4 (copy, index: 6)
                    Drag_upv_1 (copy, index: 7)
                    RunService_upv_1 (copy, index: 8)
                    u42 (ref,  index: 9)
                ]]
                if (u27) then
                    if (u41 > 0) then
                        u41 = 0;
                        if (a5) then
                            a5(u41);
                        end;
                    end;
                else
                    if (u8 and u8.Mouse == a2) then
                        if (a4) then
                            a4();
                        end;
                        Drag_upv_1.Visible = false;
                        RunService_upv_1:UnbindFromRenderStep("Drag");
                        u8 = nil;
                        return;
                    end;
                    if (u41 > 0) then
                        u41 = 0;
                        if (a5 and not (u42)) then
                            a5(u41);
                        end;
                    end;
                end;
            end
        );
    end;
    local function u43()
        --[[
          line: 754
          upvalues:
            u8 (ref,  index: 1)
            u31 (ref,  index: 2)
            UserInputService_upv_1 (copy, index: 3)
            StateController_upv_1 (copy, index: 4)
            u12 (ref,  index: 5)
        ]]
        local Index_1 = u8.Index;
        local v31 = u31[u8.Container];
        if (v31) then
            local v32 = v31[Index_1];
            local v33 = UserInputService_upv_1:IsKeyDown(Enum.KeyCode.LeftShift) and (not StateController_upv_1:GetAttribute("IsSprint"));
            local Mouse_1 = u8.Mouse;
            local v34, v34 = nil, nil;
            if (u8.IsActionMenu == true) then
                v34 = u12;
                if (v34) then
                    return v34;
                end;
            end;
            if (Mouse_1 == 1 and v33) then
                return 1;
            end;
            local Amount_1 = v32.Amount;
            local v35;
            if (Mouse_1 == 2 and (v33)) then
                v35 = 3;
            else
                v35 = Mouse_1;
            end;
            v34 = math.ceil(Amount_1 / v35);
            return v34;
        end;
    end;
    local function QuickStackBackpackSlot_upv_1(a1, a2)
        --[[
          name: QuickStackBackpackSlot
          line: 766
          upvalues:
            tbl_upv_3 (ref,  index: 1)
            u31 (ref,  index: 2)
            u36 (copy, index: 3)
            u15 (ref,  index: 4)
        ]]
        local Container_1 = tbl_upv_3.Container;
        local Index_2 = tbl_upv_3.Index;
        local v36 = u31[Container_1];
        local v37;
        if (not v36) then
            return;
        end;
        v37 = v36[tbl_upv_3.Index];
        if (v37) then
            local v38 = nil;
            if (v37 ~= 0) then
                v38 = v37.Container;
                local v39 = false;
                if (v38 ~= nil) then
                    v39 = v38[a2];
                end;
                if (v39 and v39 ~= 0) then
                    u36(a1, Container_1, Index_2, u15, true, a2, v39);
                end;
                return;
            end;
        end;
    end;
    local function u44(a1, ...)
        --[[
          line: 517
        ]]
        local tbl_8 = {...};
        for n_1 = 1, 8 do
            local v40 = a1["Stat" .. n_1];
            local v41 = tbl_8[n_1] or "";
            v40.Size = UDim2.new(((n_1 <= 4) and 1) or 0.5, 0, 0.24, 0);
            v40.RichText = true;
            v40.Text = v41;
            if (n_1 > 4) then
                a1["Stat" .. n_1 - 4].Size = UDim2.new(0.5, 0, 0.24, 0);
            end;
        end;
    end;
    u24 = function(a1, a2, a3, a4)
        --[[
          line: 434
          upvalues:
            Items_upv_1 (copy, index: 1)
            NumberUtil_upv_1 (copy, index: 2)
            ViewmodelController_upv_1 (copy, index: 3)
            Toolbar_upv_1 (copy, index: 4)
        ]]
        local num_1 = tonumber(a1.Name:sub(5));
        local v42 = nil;
        local v43 = nil;
        local v44 = nil;
        local v45 = nil;
        local v46 = nil;
        local v47 = nil;
        local v48 = nil;
        local v49 = math.huge;
        if (a2 and a2 ~= 0) then
            v42 = Items_upv_1[a2.ID];
            v43 = v42.Image;
            v44 = v42.MaxDurability;
            v45 = v42.Attachments;
            v46 = a2.Ammo;
            v47 = a2.CookTimes;
            v48 = a2.Container;
            v49 = v42.MaxAttachments or v49;
        end;
        local Durability_1 = a1:FindFirstChild("Durability");
        local v50 = false;
        if (Durability_1) then
            v50 = v44 ~= nil;
            if (v44) then
                Durability_1.Fill.Size = UDim2.new(math.clamp(a2.Durability / v44, 0, 1), 0, 1, 0);
                local v51 = math.min(a2.Repair, 1);
                Durability_1.Repair.Position = UDim2.new(1 - v51, 0, 0, 0);
                Durability_1.Repair.Size = UDim2.new(v51, 0, 1, 0);
            end;
            Durability_1.Visible = v50;
        end;
        local u45;
        local v55 = nil;
        for v52 = 1, 4 do
            v55 = a1:FindFirstChild("Att" .. v52);
            if (not (v55)) then
                continue;
            end;
            if (v45) then
                v55.BackgroundColor3 = v52 <= #a2.Attachments and (Color3.fromRGB(255, 244, 88)) or Color3.fromRGB(167, 165, 130);
            end;
            if (v45 == nil) then
                v55.Visible = false;
                continue;
            end;
            if (v52 <= math.min(#v45, v49)) then
                local _ = true;
            else
                local v54 = false;
            end;
            v55.Visible = false;
        end;
        local ItemImage_1 = a1.ItemImage;
        if (v43) then
            local v56 = nil;
            if (type(v43) ~= "table") then
                v55 = v43 or "";
            else
                v56 = v43[a2.Skin];
                v55 = v56 or v43 or "";
            end;
        else
            v55 = "";
        end;
        ItemImage_1.Image = v55;
        if (v42 and v42.Type == "Backpack" and v48) then
            local Broken_1 = 0;
            for _, value_4 in v48 do
                if (type(value_4) ~= "table") then
                    continue;
                end;
                if (value_4.Amount > 0) then
                    Broken_1 = Broken_1 + 1;
                end;
            end;
            a1.ItemAmount.Text = ("%*/%*"):format(Broken_1, #v48);
        else
            local ItemAmount_1 = a1.ItemAmount;
            if (v42) then
                if (v42.Type:find("Ammo") ~= nil) then
                    v55 = ((a2.Amount > 1) and ("x" .. NumberUtil_upv_1:FormatNumber(a2.Amount))) or "";
                else
                    local v58 = nil;
                    if (v42.AmmoType == nil) then
                        v55 = ((a2.Amount > 1) and ("x" .. NumberUtil_upv_1:FormatNumber(a2.Amount))) or "";
                    else
                        local v53;
                        if (v46 == nil) then
                            v53 = 0;
                        else
                            v53 = a3 or v46.Amount or 0;
                        end;
                        v58 = NumberUtil_upv_1:FormatNumber(v53);
                        v55 = v58 or ((a2.Amount > 1) and ("x" .. NumberUtil_upv_1:FormatNumber(a2.Amount))) or "";
                    end;
                end;
            else
                v55 = "";
            end;
            ItemAmount_1.Text = v55;
        end;
        local ItemAmount_2 = a1.ItemAmount;
        ItemAmount_2.Position = UDim2.new(0.25, 0, (v50 and 0.71) or 0.76, 0);
        local Broken_1 = a1:FindFirstChild("Broken");
        if (Broken_1) then
            v55 = false;
            if (v44 ~= nil) then
                v55 = a2.Durability <= 0;
            end;
            Broken_1.Visible = v55;
        end;
        v55 = a1:FindFirstChild("Empty");
        if (v55) then
            v55.Visible = v43 == nil;
        end;
        local v52 = a1:FindFirstChild("Checker");
        if (v52) then
            v52.Visible = false;
        end;
        local CookBar_upv_1 = a1:FindFirstChild("CookBar");
        if (CookBar_upv_1) then
            if (v47) then
                u45 = math.clamp(v47[1] / v47[2], 0, 1);
                local v59 = false;
                if (u45 < CookBar_upv_1.Fill.Size.Y.Scale) then
                    v59 = CookBar_upv_1.Visible;
                end;
                local v60 = u45 <= 0.001;
                local Fill_1 = CookBar_upv_1.Fill;
                local new_1 = UDim2.new;
                local v61;
                if (not (v59) or v60) then
                    v61 = u45;
                else
                    v61 = 1;
                end;
                new_1 = new_1(1, 0, v61, 0);
                if (not (CookBar_upv_1.Visible) or v60) then
                    v61 = 0;
                else
                    v61 = (v59 and 0.8) or 1;
                end;
                Fill_1:TweenSize(new_1, "InOut", "Linear", v61, true);
                if (v59 and not (v60)) then
                    task.delay(
                        0.8,
                        function()
                            --[[
                              line: 504
                              upvalues:
                                CookBar_upv_1 (copy, index: 1)
                                u45 (copy, index: 2)
                            ]]
                            if (not CookBar_upv_1 or not CookBar_upv_1.Parent or not CookBar_upv_1.Visible or CookBar_upv_1.Fill.Size.Y.Scale < 0.99) then
                                return;
                            end;
                            CookBar_upv_1.Fill:TweenSize(UDim2.new(1, 0, u45, 0), "InOut", "Linear", 0.1, true);
                        end
                    );
                end;
            end;
            CookBar_upv_1.Visible = true;
        end;
        local v62 = ViewmodelController_upv_1:GetAttribute("Equipped");
        if ((a4) or a1.Parent ~= Toolbar_upv_1 or num_1 ~= v62) then
            return;
        end;
        ViewmodelController_upv_1.UpdateVM:Fire(a2);
    end;
    local function u46(a1, a2, a3)
        --[[
          line: 531
          upvalues:
            u44 (copy, index: 1)
            Items_upv_1 (copy, index: 2)
            ToolInfo_upv_1 (copy, index: 3)
            NumberUtil_upv_1 (copy, index: 4)
        ]]
        u44(a1);
        local v63 = a3 or (Items_upv_1[a2]);
        local AmmoStats_1 = v63.AmmoStats;
        local ConsumableStats_1 = v63.ConsumableStats;
        local Resistances_1 = v63.Resistances;
        local v64 = ToolInfo_upv_1[v63.Name];
        if (v63.Type == "Gun") then
            local v65 = nil;
            if (v64) then
                local v66 = v64.Weapon;
                v65 = v64.Bullet;
                if (v65) then
                    local Dropoff_1 = v65.Dropoff;
                    local ActualRPM_1 = v66.ActualRPM;
                    local v67 = ("Base Damage: %*"):format(NumberUtil_upv_1:RoundNumber(v65.DisplayDamage or (v65.HumanoidDamages.Chest)));
                    local v68;
                    if (type(ActualRPM_1) ~= "string") then
                        v68 = NumberUtil_upv_1:FormatNumber(ActualRPM_1 or (v66.RPM));
                    else
                        v68 = ActualRPM_1;
                    end;
                    local v69 = ("RPM: %*"):format(v68);
                    local v70 = NumberUtil_upv_1:FormatNumber(Dropoff_1.Start);
                    local v71 = ((Dropoff_1.End ~= Dropoff_1.Start) and ("-" .. NumberUtil_upv_1:FormatNumber(Dropoff_1.End))) or "";
                    u44(a1, v67, v69, ("Range Dropoff: %*"):format(v70 .. v71), (("Bullet Velocity: %*"):format(NumberUtil_upv_1:FormatNumber(v65.Speed))));
                end;
                return;
            end;
        end;
        if (v63.Type == "Tool" or v63.Type:find("Consumable")) then
            local tbl_9 = {};
            local v72, v73, v74, v75 = nil, nil, nil, nil;
            local v66 = nil;
            if (v64) then
                local Weapon_1 = v64.Weapon;
                v72 = v64.Melee;
                v73 = v64.ObjectDamages;
                if (v72) then
                    v74 = v72.HumanoidDamages;
                    if (v74) then
                        table.insert(tbl_9, (("Base Damage: %*"):format(NumberUtil_upv_1:RoundNumber(v74.Chest))));
                    end;
                end;
                local v76 = Weapon_1 and (Weapon_1.ThrowInfo);
                if (v76) then
                    v75 = v76.Explosive;
                    if (v75) then
                        table.insert(tbl_9, (("Splash Damage: %*"):format(NumberUtil_upv_1:RoundNumber(v75.HumanoidMaxDamage))));
                    end;
                end;
                local value_5 = Weapon_1 and (Weapon_1.Cooldown);
                if (value_5) then
                    table.insert(tbl_9, (("Cooldown: %*"):format(NumberUtil_upv_1:RoundNumber(value_5))));
                end;
                if (v73) then
                    v66 = v73.Trees;
                    if (v66) then
                        table.insert(tbl_9, (("Tree Gather: %*"):format(math.round(v66.Medium.Mult * 1000) / 100)));
                    end;
                    local Nodes_1 = v73.Nodes;
                    if (Nodes_1) then
                        table.insert(tbl_9, (("Node Gather: %*"):format(math.round(Nodes_1.Stone.Mult * 1000) / 100)));
                    end;
                end;
            end;
            if (ConsumableStats_1) then
                v66 = tbl_9;
                local v78 = nil;
                local v79 = nil;
                local v80 = nil;
                local v81 = nil;
                v66 = nil;
                local v82 = nil;
                local v126 = nil;
                local key_2 = nil;
                local v83 = nil;
                for key_2, value_6 in pairs(ConsumableStats_1) do
                    if (value_6 == 0 or type(value_6) ~= "number") then
                        continue;
                    end;
                    v78 = NumberUtil_upv_1:RoundNumber(value_6);
                    v79 = math.abs(value_6);
                    v80 = v78 < 0;
                    v81 = v80 == (key_2 ~= "Radiation");
                    v80 = script;
                    if (v81) then
                        v82 = "StatRedColor";
                    else
                        v82 = "StatGreenColor";
                    end;
                    v80 = v80:GetAttribute(v82);
                    if (key_2 == "HQueue") then
                        v83 = "Health Regen";
                        local v84 = math.round(v80.R * 255);
                        local v85 = math.round(v80.G * 255);
                        local v86 = math.round(v80.B * 255);
                        table.insert(v66, (("%*: <font color=\"rgb(%*, %*, %*)\">%*</font>"):format(v83, v84, v85, v86, (((v78 >= 0) and "+") or "-") .. v79)));
                        continue;
                    end;
                    if (key_2 ~= "Health") then
                        v83 = key_2;
                    else
                        v83 = "Instant Health";
                    end;
                    local v84 = math.round(v80.R * 255);
                    local v85 = math.round(v80.G * 255);
                    local v86 = math.round(v80.B * 255);
                    table.insert(v66, (("%*: <font color=\"rgb(%*, %*, %*)\">%*</font>"):format(v83, v84, v85, v86, (((v78 >= 0) and "+") or "-") .. v79)));
                end;
            else
                v66 = tbl_9;
            end;
            u44(a1, unpack(v66));
        elseif (AmmoStats_1) then
            local tbl_10 = {};
            local v68;
            local v87 = nil;
            for key_3, value_5 in pairs(AmmoStats_1) do
                if (key_3:sub(#key_3 - 3) == "Mult") then
                    local v88 = key_3:sub(1, #key_3 - 4);
                    local v89 = v88 == "Gravity";
                    if (not v89 and v88 ~= "ArmorPen") then
                        v87 = v88 == "HeadshotDamage" and value_5 or value_5 * (AmmoStats_1.Bullets or 1) - 1;
                    else
                        v87 = 1 - value_5;
                        v87 = v87 or v88 == "HeadshotDamage" and value_5 or value_5 * (AmmoStats_1.Bullets or 1) - 1;
                    end;
                    local v90 = math.round(v87 * 100);
                    local v91 = math.abs(v90);
                    local v82 = v90 < 0;
                    local v70 = v88:find("Spread") == nil;
                    if (v82 == v70) then
                        v87 = true;
                    else
                        v87 = false;
                    end;
                    local script_1 = script;
                    local v71;
                    if (v87) then
                        v71 = "StatRedColor";
                    else
                        v71 = "StatGreenColor";
                    end;
                    local v92 = script_1:GetAttribute(v71);
                    local v93 = (v89 and "Drop") or (((v88 == "ArmorPen") and "Armor Penetration") or (((v88 == "HeadshotDamage") and "HS Mult") or (v88:gsub("Spread", " Spread"))));
                    local v94 = math.round(v92.R * 255);
                    local v95 = math.round(v92.G * 255);
                    local v96 = math.round(v92.B * 255);
                    table.insert(tbl_10, (("%*: <font color=\"rgb(%*, %*, %*)\">%*%%</font>"):format(v93, v94, v95, v96, (((v90 >= 0) and "+") or "-") .. v91)));
                elseif (key_3 == "Explosive") then
                    local v97 = NumberUtil_upv_1:FormatNumber(value_5.HumanoidMaxDamage);
                    if (v63.AmmoType ~= "Rocket") then
                        local v98 = script:GetAttribute("StatGreenColor");
                        table.insert(tbl_10, (("Splash Damage: <font color=\"rgb(%*, %*, %*)\">+%*</font>"):format(math.round(v98.R * 255), math.round(v98.G * 255), math.round(v98.B * 255), v97)));
                        continue;
                    end;
                    if (v63.Name ~= "Rocket") then
                        table.insert(tbl_10, (("Damage Override: %*"):format(NumberUtil_upv_1:FormatNumber(v97))));
                    end;
                elseif (key_3 == "Bullets") then
                    table.insert(tbl_10, (("Pellets: %*"):format(value_5)));
                end;
            end;
            u44(a1, unpack(tbl_10));
        elseif (Resistances_1) then
            local tbl_11 = {};
            for _, value_7 in pairs({"Chest", "Legs", "Head"}) do
                local v99, v81;
                local v100 = Resistances_1[value_7];
                v99 = v100.Bullet;
                v81 = v100.Melee;
                if (v99 ~= 0 or v99 == 0 and v81 ~= 0) then
                    if (v99 ~= 0) then
                        table.insert(tbl_11, {"Bullet", v99});
                    end;
                    if (v81 ~= 0) then
                        table.insert(tbl_11, {"Melee", v81});
                    end;
                end;
            end;
            for key_4, value_8 in pairs(Resistances_1) do
                if (value_8 == 0) then
                    continue;
                end;
                if (type(value_8) == "number") then
                    table.insert(tbl_11, {key_4, value_8});
                end;
            end;
            local tbl_12 = {};
            local v101 = nil;
            local v102 = nil;
            local v103 = nil;
            local v83 = nil;
            local v104 = nil;
            local v105 = nil;
            local v106 = nil;
            for _, value_9 in pairs(tbl_11) do
                v101 = value_9[2];
                v102 = NumberUtil_upv_1:RoundNumber(math.abs(v101));
                v103 = script:GetAttribute(((v101 >= 0) and "StatGreenColor") or "StatRedColor");
                v83 = value_9[1];
                v104 = math.round(v103.R * 255);
                v105 = math.round(v103.G * 255);
                v106 = math.round(v103.B * 255);
                table.insert(tbl_12, (("%*: <font color=\"rgb(%*, %*, %*)\">%*</font>"):format(v83, v104, v105, v106, (((v101 >= 0) and "+") or "-") .. v102)));
            end;
            u44(a1, unpack(tbl_12));
        elseif (v63.Name == "Armor Plate") then
            local v107 = script:GetAttribute("StatGreenColor");
            u44(a1, ("Armor Mod Type: %*"):format(v63.AttachmentType:upper()), (("Bullet Resistance: <font color=\"rgb(%*, %*, %*)\">+5%%</font>"):format(math.round(v107.R * 255), math.round(v107.G * 255), math.round(v107.B * 255))));
        elseif (v63.Name == "Heavy Padding") then
            local v108 = script:GetAttribute("StatGreenColor");
            u44(a1, ("Armor Mod Type: %*"):format(v63.AttachmentType:upper()), (("Melee Resistance: <font color=\"rgb(%*, %*, %*)\">+5%%</font>"):format(math.round(v108.R * 255), math.round(v108.G * 255), math.round(v108.B * 255))));
        elseif (v63.Name == "Night Vision Goggles") then
            local v109 = script:GetAttribute("StatGreenColor");
            local v110 = script:GetAttribute("StatRedColor");
            u44(a1, ("Armor Mod Type: %*"):format(v63.AttachmentType:upper()), ("Night Visibility: <font color=\"rgb(%*, %*, %*)\">+100%%</font>"):format(math.round(v109.R * 255), math.round(v109.G * 255), math.round(v109.B * 255)), (("Daytime Visibility: <font color=\"rgb(%*, %*, %*)\">-100%%</font>"):format(math.round(v110.R * 255), math.round(v110.G * 255), math.round(v110.B * 255))));
        elseif (v63.Name == "Lightweight Padding") then
            local v111 = script:GetAttribute("StatGreenColor");
            u44(a1, ("Armor Mod Type: %*"):format(v63.AttachmentType:upper()), (("Footstep Range: <font color=\"rgb(%*, %*, %*)\">-25%%</font>"):format(math.round(v111.R * 255), math.round(v111.G * 255), math.round(v111.B * 255))));
        elseif (v63.Name == "Resistant Rubber") then
            local v112 = script:GetAttribute("StatGreenColor");
            u44(a1, ("Armor Mod Type: %*"):format(v63.AttachmentType:upper()), (("Radiation Resistance: <font color=\"rgb(%*, %*, %*)\">+5%%</font>"):format(math.round(v112.R * 255), math.round(v112.G * 255), math.round(v112.B * 255))));
        elseif (v63.Name == "Armor Polish") then
            local v113 = script:GetAttribute("StatGreenColor");
            u44(a1, ("Armor Mod Type: %*"):format(v63.AttachmentType:upper()), (("Durability Damage: <font color=\"rgb(%*, %*, %*)\">-25%%</font>"):format(math.round(v113.R * 255), math.round(v113.G * 255), math.round(v113.B * 255))));
        elseif (v63.Name == "Steel Toes") then
            local v114 = script:GetAttribute("StatGreenColor");
            u44(a1, ("Armor Mod Type: %*"):format(v63.AttachmentType:upper()), (("Fall Damage: <font color=\"rgb(%*, %*, %*)\">-25%%</font>"):format(math.round(v114.R * 255), math.round(v114.G * 255), math.round(v114.B * 255))));
        elseif (v63.Name ~= "Snorkle") then
            local v115 = nil;
            if (v63.Name ~= "Water Filter") then
                v115 = v63.AttachmentStats;
                if (v115) then
                    local tbl_13 = {};
                    local v83, v70 = nil, nil;
                    local v89 = nil;
                    for key_5, value_10 in pairs(v115) do
                        v89 = key_5 == "ZoomLevel";
                        if (key_5 == "GunRecoilAimMult" or type(value_10) ~= "number" or value_10 == 0) then
                            continue;
                        end;
                        if (key_5:sub(#key_5 - 3) == "Mult") then
                            local v116;
                            v116 = (v89 and key_5) or (key_5:sub(1, #key_5 - 4));
                            local v117;
                            if (v116 ~= "Sway") then
                                v117 = v116:gsub("(%u)", " %1"):gsub("^%s", "");
                            else
                                v117 = "Aim Sway";
                            end;
                            local v68 = (v89 and (NumberUtil_upv_1:RoundNumber(value_10, 2))) or (math.round(value_10 * 100));
                            local v118 = math.abs(v68);
                            if (v68 < 0) then
                                local v71 = true;
                            else
                                local v71;
                                v71 = false;
                            end;
                            local v119 = true;
                            if (v116 == "Damage") then
                                v83 = v119;
                            else
                                v83 = v116 == "FireRate";
                            end;
                            local v71 = nil;
                            if (v71 == v83) then
                                v70 = true;
                            else
                                v70 = false;
                            end;
                            if (v89) then
                                v70 = v68 < 1.2;
                            end;
                            local script_2 = script;
                            local v120;
                            if (v70) then
                                v120 = "StatRedColor";
                            else
                                v120 = "StatGreenColor";
                            end;
                            local v121 = script_2:GetAttribute(v120);
                            local v122 = math.round(v121.R * 255);
                            local v123 = math.round(v121.G * 255);
                            local v124 = math.round(v121.B * 255);
                            table.insert(tbl_13, (("%*: <font color=\"rgb(%*, %*, %*)\">%*</font>"):format(v117, v122, v123, v124, ((v89 and "") or (((v68 >= 0) and "+") or "-")) .. v118 .. ((v89 and "x") or "%"))));
                        else
                            local v116;
                            if (not (v89)) then
                                continue;
                            end;
                            v116 = (v89 and key_5) or (key_5:sub(1, #key_5 - 4));
                            local v117;
                            if (v116 ~= "Sway") then
                                v117 = v116:gsub("(%u)", " %1"):gsub("^%s", "");
                            else
                                v117 = "Aim Sway";
                            end;
                            local v68 = (v89 and (NumberUtil_upv_1:RoundNumber(value_10, 2))) or (math.round(value_10 * 100));
                            local v118 = math.abs(v68);
                            if (v68 < 0) then
                                local v71 = true;
                            else
                                local v71;
                                v71 = false;
                            end;
                            local v119 = true;
                            if (v116 == "Damage") then
                                v83 = v119;
                            else
                                v83 = v116 == "FireRate";
                            end;
                            local v71 = nil;
                            if (v71 == v83) then
                                v70 = true;
                            else
                                v70 = false;
                            end;
                            if (v89) then
                                v70 = v68 < 1.2;
                            end;
                            local script_2 = script;
                            local v120;
                            if (v70) then
                                v120 = "StatRedColor";
                            else
                                v120 = "StatGreenColor";
                            end;
                            local v121 = script_2:GetAttribute(v120);
                            local v122 = math.round(v121.R * 255);
                            local v123 = math.round(v121.G * 255);
                            local v124 = math.round(v121.B * 255);
                            table.insert(tbl_13, (("%*: <font color=\"rgb(%*, %*, %*)\">%*</font>"):format(v117, v122, v123, v124, ((v89 and "") or (((v68 >= 0) and "+") or "-")) .. v118 .. ((v89 and "x") or "%"))));
                        end;
                    end;
                    u44(a1, unpack(tbl_13));
                end;
            else
                local _ = script:GetAttribute("StatGreenColor");
                u44(a1, ("Armor Mod Type: %*"):format(v63.AttachmentType:upper()), "Salt Water Filtering: YES", "Water Heal Max Health: 60");
            end;
        else
            local v125 = script:GetAttribute("StatGreenColor");
            u44(a1, ("Armor Mod Type: %*"):format(v63.AttachmentType:upper()), (("Breathing Time: <font color=\"rgb(%*, %*, %*)\">+150%%</font>"):format(math.round(v125.R * 255), math.round(v125.G * 255), math.round(v125.B * 255))));
        end;
    end;
    local function u47()
        --[[
          line: 779
          upvalues:
            tbl_upv_3 (ref,  index: 1)
            u31 (ref,  index: 2)
            Items_upv_1 (copy, index: 3)
            ActionMenu_upv_1 (copy, index: 4)
            SkinsModule_upv_1 (copy, index: 5)
            u24 (copy, index: 6)
            u26 (ref,  index: 7)
            Backpack_upv_1 (copy, index: 8)
            tbl_upv_7 (copy, index: 9)
            u14 (ref,  index: 10)
            PreferredInputController_upv_1 (copy, index: 11)
            GuiService_upv_1 (copy, index: 12)
            QuickStackBackpackSlot_upv_1 (copy, index: 13)
            u39 (copy, index: 14)
            u8 (ref,  index: 15)
            u34 (copy, index: 16)
            u43 (copy, index: 17)
            SoundModule_upv_1 (copy, index: 18)
            u1 (copy, index: 19)
            ViewportModule_upv_1 (copy, index: 20)
            ViewportFrame_upv_1 (copy, index: 21)
            u12 (ref,  index: 22)
            u46 (copy, index: 23)
            ItemStats_upv_2 (copy, index: 24)
            u38 (copy, index: 25)
            tbl_upv_6 (copy, index: 26)
            UserService_upv_1 (copy, index: 27)
        ]]
        local v126, v127 = nil, nil;
        if (tbl_upv_3) then
            v126 = tbl_upv_3.Container;
            v127 = u31[v126];
            local v128 = nil;
            if (v127) then
                local Index_3 = tbl_upv_3.Index;
                v128 = v127[tbl_upv_3.Index];
            end;
            if (not v127 or not v128) then
                return;
            end;
            if (v128 ~= 0) then
                local v129, v130, Owner_upv_1 = nil, nil, nil;
                if (v128.Amount > 0) then
                    local v131 = Items_upv_1[v128.ID];
                    local Attachments_1 = v128.Attachments;
                    local Attachments_2 = v131.Attachments;
                    local Skin_1 = v128.Skin;
                    v129 = v131.Image;
                    local ConsumableStats_2 = v131.ConsumableStats;
                    local v132;
                    if (v129) then
                        if (type(v129) ~= "table") then
                            v132 = v129 or "";
                        else
                            v132 = v129[Skin_1] or v129 or "";
                        end;
                    else
                        v132 = "";
                    end;
                    ActionMenu_upv_1.Split.ItemImage.Image = v132;
                    ActionMenu_upv_1.ItemInfo.ItemImage.Image = v132;
                    local v135 = nil;
                    local v139 = nil;
                    if (Skin_1) then
                        if (Skin_1 == "Default") then
                            ActionMenu_upv_1.Skin.Text = "";
                        else
                            v139 = "Common";
                            v135 = SkinsModule_upv_1:GetSkinInfo(("%*/%*"):format(v131.Name, Skin_1));
                            if (type(v135) == "table") then
                                v139 = v135.Rarity or v139;
                            end;
                            for _, value_11 in ActionMenu_upv_1.Skin:GetChildren() do
                                Owner_upv_1 = value_11:IsA("UIGradient");
                                if (Owner_upv_1) then
                                    value_11.Enabled = value_11.Name == v139;
                                end;
                            end;
                            ActionMenu_upv_1.Skin.Text = Skin_1;
                        end;
                    else
                        ActionMenu_upv_1.Skin.Text = "";
                    end;
                    for n_2 = 1, 4 do
                        local v136 = ActionMenu_upv_1.ItemDetails["Slot" .. n_2];
                        if (Attachments_2) then
                            u24(v136, Attachments_1[n_2]);
                        end;
                        v135 = v136.Checker;
                        local v137 = (Attachments_2 and (math.min(#Attachments_2, v131.MaxAttachments or math.huge))) or 0;
                        if (v137 < n_2) then
                            v139 = true;
                        else
                            v139 = false;
                        end;
                        v135.Visible = v139;
                        if (Attachments_2 ~= nil) then
                            v135 = true;
                        else
                            v135 = false;
                        end;
                        v136.Visible = v135;
                    end;
                    v130 = v128.Container;
                    local v140 = nil;
                    if (v130) then
                        local _ = false;
                        for key_6, value_12 in v130 do
                            if (value_12) then
                                if (value_12 == 0) then
                                    break;
                                else
                                    v140 = true;
                                end;
                            else
                                continue;
                            end;
                        end;
                        if (not v140 and v126 ~= "Armor" and v126 ~= "Bench") then
                            v139 = nil;
                        else
                            if (u26 ~= #v130) then
                                for n_3 = 1, math.max(u26, #v130) do
                                    local key_6 = ("Slot%*"):format(n_3);
                                    v140 = false;
                                    if (n_3 <= u26) then
                                        v140 = Backpack_upv_1[key_6];
                                    end;
                                    if (v140 or n_3 > #v130) then
                                        if (not (v140)) then
                                            continue;
                                        end;
                                        if (#v130 < n_3) then
                                            v140:Destroy();
                                            tbl_upv_7[v140] = nil;
                                        end;
                                    else
                                        v140 = Backpack_upv_1.Slot1:Clone();
                                        v140.Name = key_6;
                                        v140.Parent = Backpack_upv_1;
                                    end;
                                end;
                                u26 = #v130;
                            end;
                            for key_upv_7, value_13 in v130 do
                                Owner_upv_1 = Backpack_upv_1[("Slot%*"):format(key_upv_7)];
                                u24(Owner_upv_1, value_13);
                                if (tbl_upv_7[Owner_upv_1]) then
                                    continue;
                                end;
                                tbl_upv_7[Owner_upv_1] = true;
                                Owner_upv_1.InputChanged:Connect(
                                    function(a1)
                                        --[[
                                          line: 854
                                          upvalues:
                                            u14 (ref,  index: 1)
                                            tbl_upv_3 (ref,  index: 2)
                                            PreferredInputController_upv_1 (copy, index: 3)
                                            GuiService_upv_1 (copy, index: 4)
                                            Owner_upv_1 (copy, index: 5)
                                            QuickStackBackpackSlot_upv_1 (copy, index: 6)
                                            key_upv_7 (copy, index: 7)
                                        ]]
                                        if (a1.UserInputType ~= Enum.UserInputType.MouseMovement or not u14) then
                                            return;
                                        end;
                                        if (tbl_upv_3) then
                                            local v142 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                                            if (v142 and GuiService_upv_1.SelectedObject ~= Owner_upv_1) then
                                                return;
                                            end;
                                            QuickStackBackpackSlot_upv_1(Owner_upv_1, key_upv_7);
                                        end;
                                    end
                                );
                                Owner_upv_1.MouseButton2Click:Connect(
                                    function()
                                        --[[
                                          line: 860
                                          upvalues:
                                            QuickStackBackpackSlot_upv_1 (copy, index: 1)
                                            Owner_upv_1 (copy, index: 2)
                                            key_upv_7 (copy, index: 3)
                                        ]]
                                        QuickStackBackpackSlot_upv_1(Owner_upv_1, key_upv_7);
                                    end
                                );
                                for n_4 = 1, 2 do
                                    u39(
                                        Owner_upv_1,
                                        n_4,
                                        function(a2, a3)
                                            --[[
                                              line: 864
                                              upvalues:
                                                tbl_upv_3 (ref,  index: 1)
                                                u31 (ref,  index: 2)
                                                u8 (ref,  index: 3)
                                                key_upv_7 (copy, index: 4)
                                                u34 (copy, index: 5)
                                                Owner_upv_1 (copy, index: 6)
                                            ]]
                                            local Slot_1 = tbl_upv_3.Slot;
                                            local v143 = u31[tbl_upv_3.Container];
                                            local v144 = nil;
                                            if (v143) then
                                                v144 = v143[tbl_upv_3.Index];
                                                if (v144 and v144 ~= 0 and v144.Amount > 0) then
                                                    local v145 = nil;
                                                    if (not (u8)) then
                                                        v145 = v144.Container;
                                                        local v146 = false;
                                                        if (v145 ~= nil) then
                                                            v146 = v145[key_upv_7];
                                                        end;
                                                        if (v146 and v146 ~= 0) then
                                                            a2 = u34(Slot_1, Owner_upv_1.ItemImage.Image, tbl_upv_3.Container, tbl_upv_3.Index, a3, nil, v146, key_upv_7);
                                                        end;
                                                    end;
                                                end;
                                            end;
                                            return a2, a3;
                                        end,
                                        function()
                                            --[[
                                              line: 878
                                              upvalues:
                                                tbl_upv_3 (ref,  index: 1)
                                                u8 (ref,  index: 2)
                                                u31 (ref,  index: 3)
                                                u43 (copy, index: 4)
                                                SoundModule_upv_1 (copy, index: 5)
                                                u1 (copy, index: 6)
                                            ]]
                                            local v147 = nil;
                                            if (tbl_upv_3) then
                                                local Container_2 = u8.Container;
                                                local Index_4 = u8.Index;
                                                v147 = u31[Container_2];
                                                local v148 = nil;
                                                if (v147) then
                                                    v148 = v147[Index_4];
                                                    local v149 = u43();
                                                    if (v148 and v148 ~= 0 and v149 > 0) then
                                                        SoundModule_upv_1:PlayItemSound(v148.ID, "Drop");
                                                    end;
                                                    u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", Container_2, Index_4, v149, tbl_upv_3.Container, tbl_upv_3.Index);
                                                end;
                                            end;
                                        end
                                    );
                                end;
                            end;
                            v139 = v130;
                        end;
                    else
                        v139 = v130;
                    end;
                    if (v139 ~= nil) then
                        v140 = true;
                    else
                        v140 = false;
                    end;
                    local v151 = nil;
                    if (Backpack_upv_1.Visible ~= v140) then
                        if (v140) then
                            v151 = CFrame.new(-2, 0, 0);
                        else
                            v151 = CFrame.new();
                        end;
                        ViewportModule_upv_1:TweenCamera(ViewportFrame_upv_1, v151);
                    end;
                    Backpack_upv_1.Visible = v140;
                    local DropInfo_1 = v131.DropInfo;
                    if (v131.Type ~= "Gun") then
                        v151 = v131.Type:find("Consumable");
                        if (v151 and ConsumableStats_2 and ConsumableStats_2.Instant) then
                            ActionMenu_upv_1.Actions.Action1.Label.Text = "EAT";
                        elseif (DropInfo_1) then
                            ActionMenu_upv_1.Actions.Action1.Label.Text = DropInfo_1.ButtonName;
                        end;
                    else
                        ActionMenu_upv_1.Actions.Action1.Label.Text = "UNLOAD AMMO";
                    end;
                    local v152 = v131.Type == "Gun";
                    local v153 = v131.Type:find("Consumable") ~= nil;
                    ActionMenu_upv_1.Actions.Action1.Visible = v152 or (v153 or (DropInfo_1 ~= nil));
                    local v154 = u12 or (math.ceil(v128.Amount / 2));
                    u12 = v154;
                    u46(ItemStats_upv_2, v128.ID, v131);
                    u38();
                    local _ = "[ERR]";
                    local v155 = "[ERR]";
                    Owner_upv_1 = v128.Owner;
                    local v156, success_1 = nil, nil;
                    if (Owner_upv_1) then
                        v156 = tbl_upv_6[Owner_upv_1];
                        if (not (v156) or tick() - v156.Called >= 600) then
                            local success_1, v157 = pcall(
                                function()
                                    --[[
                                      line: 948
                                      upvalues:
                                        UserService_upv_1 (copy, index: 1)
                                        Owner_upv_1 (copy, index: 2)
                                    ]]
                                    return UserService_upv_1:GetUserInfosByUserIdsAsync({Owner_upv_1});
                                end
                            );
                            if (success_1 and v157 and #v157 > 0) then
                                v156 = v157[1];
                                v156.Called = tick();
                            end;
                        end;
                        if (v156) then
                            tbl_upv_6[Owner_upv_1] = v156;
                            local DisplayName_1 = v156.DisplayName;
                            local v158 = ((not (v156.HasVerifiedBadge)) and "") or (utf8.char(57344));
                            local v159 = ("%*%*"):format(DisplayName_1, v158);
                            if (v156.DisplayName ~= v156.Username) then
                                v154, v155 = v159, ("%*(@%*)"):format(v159, v156.Username);
                            else
                                v154, v155 = v159, ("@%*"):format(v159);
                            end;
                        end;
                    end;
                    if (tbl_upv_3 and tbl_upv_3.Container == v126 and tbl_upv_3.Index == Index_3) then
                        ActionMenu_upv_1.ItemName.Text = string.format(v131.Name, v154);
                        ActionMenu_upv_1.ItemInfo.ItemDesc.Text = string.format(v131.Description, v155);
                    end;
                end;
            end;
        end;
    end;
    u30 = function(a1, a2, a3)
        --[[
          line: 969
          upvalues:
            tbl_upv_3 (ref,  index: 1)
            u31 (ref,  index: 2)
            SoundModule_upv_1 (copy, index: 3)
            u47 (copy, index: 4)
            u10 (ref,  index: 5)
            ActionMenu_upv_1 (copy, index: 6)
            NumberUtil_upv_1 (copy, index: 7)
            Size_upv_1 (copy, index: 8)
            Backpack_upv_1 (copy, index: 9)
            ViewportModule_upv_1 (copy, index: 10)
            ViewportFrame_upv_1 (copy, index: 11)
            u9 (ref,  index: 12)
            u37 (copy, index: 13)
        ]]
        if (tbl_upv_3 and tbl_upv_3.Slot) then
            tbl_upv_3.Slot.BackgroundColor3 = tbl_upv_3.Color;
        end;
        tbl_upv_3 = nil;
        if (a1 and (not (tbl_upv_3) or a1 ~= tbl_upv_3.Slot)) then
            tbl_upv_3 = {Slot = a1, Container = a2, Index = a3, Color = a1.BackgroundColor3};
            a1.BackgroundColor3 = script:GetAttribute("SelectedSlotColor");
        end;
        local v160 = tbl_upv_3;
        local v161 = nil;
        if (v160 ~= tbl_upv_3) then
            local v162 = v160 ~= nil;
            local v163 = nil;
            if (v162) then
                v163 = u31[tbl_upv_3.Container];
                if (v163) then
                    v161 = v163[tbl_upv_3.Index];
                    local v164 = false;
                    if (v161 ~= nil) then
                        v164 = false;
                        if (v161 ~= 0) then
                            v164 = v161.Amount > 0;
                        end;
                    end;
                    if (v164) then
                        SoundModule_upv_1:PlayItemSound(v161.ID, "Drag");
                    end;
                    v162 = v164;
                else
                    v162 = false;
                end;
            end;
            u47();
            if (u10) then
                ActionMenu_upv_1.Size = NumberUtil_upv_1:MultUDim2ByNum(Size_upv_1, 1.3);
                u10 = false;
            end;
            local v165 = NumberUtil_upv_1:MultUDim2ByNum(Size_upv_1, (v162 and 1) or 1.3);
            ActionMenu_upv_1:TweenSize(v165, (v162 and "Out") or "In", "Quart", 0.175, true);
            local time_1 = tick();
            v161 = (v162 and 0) or 1;
            if (not (v162)) then
                if (Backpack_upv_1.Visible) then
                    ViewportModule_upv_1:TweenCamera(ViewportFrame_upv_1, CFrame.new());
                end;
                Backpack_upv_1.Visible = false;
            end;
            local v166 = nil;
            if (u9 == v161) then
                return;
            end;
            u9 = v161;
            while (true) do
                v165 = tick() - time_1;
                local v167 = math.min(v165 / 0.1, 1);
                v166 = v162 and 1 - v167 or v167;
                u37(v166);
                if (v165 >= 0.1) then
                    break;
                end;
                task.wait(0.016666666666666666);
            end;
        end;
    end;
    local function u48(a1, a2)
        --[[
          line: 1034
          upvalues:
            u8 (ref,  index: 1)
            u43 (copy, index: 2)
            CurrentCamera_upv_1 (copy, index: 3)
            u31 (ref,  index: 4)
            SoundModule_upv_1 (copy, index: 5)
            u1 (copy, index: 6)
        ]]
        local Container_3 = u8.Container;
        local Index_5 = u8.Index;
        local IsActionMenu_1 = u8.IsActionMenu;
        local EditIndex_1 = u8.EditIndex;
        local v168 = u43();
        local v169 = false;
        if (a1 == "Drop") then
            v169 = CurrentCamera_upv_1.CFrame;
        end;
        local v170 = nil;
        if (v169) then
            v170 = u31[Container_3];
            local v171 = nil;
            if (v170) then
                v171 = v170[Index_5];
                if (v171 and v171 ~= 0) then
                    SoundModule_upv_1:PlayItemSound(v171.ID, "Drop");
                end;
            end;
        end;
        if (IsActionMenu_1 and type(IsActionMenu_1) == "number" or EditIndex_1) then
            local v172;
            v172 = EditIndex_1 or v168;
            u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", Container_3, Index_5, v172, a1, a2, (EditIndex_1 and "RemoveItem") or "RemoveAttachment", EditIndex_1 or IsActionMenu_1, v169);
            return;
        end;
        u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", Container_3, Index_5, v168, a1, a2, "none", "none", v169);
    end;
    v1_1 = function(a1, a2, a3)
        --[[
          line: 1074
          upvalues:
            TweenUtil_upv_1 (copy, index: 1)
            NumberUtil_upv_1 (copy, index: 2)
            u14 (ref,  index: 3)
            PreferredInputController_upv_1 (copy, index: 4)
            GuiService_upv_1 (copy, index: 5)
            u36 (copy, index: 6)
            u15 (ref,  index: 7)
            u39 (copy, index: 8)
            u31 (ref,  index: 9)
            u8 (ref,  index: 10)
            u34 (copy, index: 11)
            u30 (ref,  index: 12)
            SoundModule_upv_1 (copy, index: 13)
            u48 (copy, index: 14)
            u27 (ref,  index: 15)
            Drag_upv_1 (copy, index: 16)
            RunService_upv_1 (copy, index: 17)
        ]]
        local u49 = TweenUtil_upv_1:Tween(a1, "Size", NumberUtil_upv_1:MultUDim2ByNum(a1.Size, 1.05), 0.04, "Quart", "Out", true);
        local u50 = TweenUtil_upv_1:Tween(a1, "Size", a1.Size, 0.46, "Elastic", "Out", true);
        local Checker_upv_1 = a1:FindFirstChild("Checker");
        a1.MouseEnter:Connect(
            function()
                --[[
                  line: 1079
                  upvalues:
                    Checker_upv_1 (copy, index: 1)
                    u49 (copy, index: 2)
                    u50 (copy, index: 3)
                ]]
                if (Checker_upv_1 and Checker_upv_1.Visible) then
                    return;
                end;
                u49:Play();
                wait(0.04);
                u50:Play();
            end
        );
        a1.InputChanged:Connect(
            function(a4)
                --[[
                  line: 1085
                  upvalues:
                    u14 (ref,  index: 1)
                    PreferredInputController_upv_1 (copy, index: 2)
                    GuiService_upv_1 (copy, index: 3)
                    a1 (copy, index: 4)
                    u36 (copy, index: 5)
                    a2 (copy, index: 6)
                    a3 (copy, index: 7)
                    u15 (ref,  index: 8)
                ]]
                if (a4.UserInputType ~= Enum.UserInputType.MouseMovement) then
                    return;
                end;
                if (u14) then
                    local v173 = PreferredInputController_upv_1 and (PreferredInputController_upv_1:GetAttribute("PreferredInput") == "Gamepad");
                    if (v173 and GuiService_upv_1.SelectedObject ~= a1) then
                        return;
                    end;
                    u36(a1, a2, a3, u15, true);
                end;
            end
        );
        for n_5 = 1, 2 do
            u39(
                a1,
                n_5,
                function(a5, a6)
                    --[[
                      line: 1092
                      upvalues:
                        u31 (ref,  index: 1)
                        a2 (copy, index: 2)
                        a3 (copy, index: 3)
                        u8 (ref,  index: 4)
                        u34 (copy, index: 5)
                        a1 (copy, index: 6)
                    ]]
                    local v174 = u31[a2];
                    local v175 = nil;
                    if (v174) then
                        v175 = v174[a3];
                        if (v175 and v175 ~= 0 and not (u8)) then
                            a5 = u34(a1, a1.ItemImage.Image, a2, a3, a6, nil, v175);
                        end;
                    end;
                    return a5, a6;
                end,
                function()
                    --[[
                      line: 1101
                      upvalues:
                        u8 (ref,  index: 1)
                        a1 (copy, index: 2)
                        u30 (ref,  index: 3)
                        a2 (copy, index: 4)
                        a3 (copy, index: 5)
                        u36 (copy, index: 6)
                        u15 (ref,  index: 7)
                        u31 (ref,  index: 8)
                        SoundModule_upv_1 (copy, index: 9)
                        u48 (copy, index: 10)
                    ]]
                    if (u8.Slot ~= a1) then
                        local Index_6 = u8.Index;
                        local v176 = u31[u8.Container];
                        local v177 = nil;
                        if (v176) then
                            v177 = v176[Index_6];
                            if (v177 and v177 ~= 0) then
                                SoundModule_upv_1:PlayItemSound(v177.ID, "Drop");
                            end;
                        end;
                        u48(a2, a3);
                    elseif (u8.Mouse ~= 1) then
                        task.spawn(u36, a1, a2, a3, u15);
                    else
                        task.spawn(u30, a1, a2, a3);
                    end;
                end,
                function(a7)
                    --[[
                      line: 1123
                      upvalues:
                        u36 (copy, index: 1)
                        a1 (copy, index: 2)
                        a2 (copy, index: 3)
                        a3 (copy, index: 4)
                        u15 (ref,  index: 5)
                        PreferredInputController_upv_1 (copy, index: 6)
                        u27 (ref,  index: 7)
                        u8 (ref,  index: 8)
                        Drag_upv_1 (copy, index: 9)
                        RunService_upv_1 (copy, index: 10)
                        u31 (ref,  index: 11)
                        SoundModule_upv_1 (copy, index: 12)
                        u48 (copy, index: 13)
                        u34 (copy, index: 14)
                        u30 (ref,  index: 15)
                    ]]
                    if (a7 ~= 2) then
                        if (PreferredInputController_upv_1) then
                            local v178 = nil;
                            if (script:GetAttribute("Open")) then
                                local v181 = nil;
                                if (u27 and u8) then
                                    if (u8.Slot ~= a1) then
                                        v181 = u8.Index;
                                        local v179 = u31[u8.Container];
                                        local v180 = nil;
                                        if (v179) then
                                            v180 = v179[v181];
                                            if (v180 and v180 ~= 0) then
                                                SoundModule_upv_1:PlayItemSound(v180.ID, "Drop");
                                            end;
                                        end;
                                        u48(a2, a3);
                                    else
                                        Drag_upv_1.Visible = false;
                                        RunService_upv_1:UnbindFromRenderStep("Drag");
                                        u8 = nil;
                                    end;
                                    Drag_upv_1.Visible = false;
                                    RunService_upv_1:UnbindFromRenderStep("Drag");
                                    u8 = nil;
                                    u8 = false;
                                    return;
                                end;
                                v178 = u31[a2];
                                if (v178) then
                                    v181 = v178[a3];
                                    if (v181 and v181 ~= 0 and v181.Amount > 0 and not (u8)) then
                                        u34(a1, a1.ItemImage.Image, a2, a3, 1, nil, v181);
                                        u27 = true;
                                        return;
                                    end;
                                    u30(a1, a2, a3);
                                end;
                                return;
                            end;
                        end;
                        u30(a1, a2, a3);
                    else
                        u36(a1, a2, a3, u15);
                    end;
                end
            );
        end;
    end;
    local function u51(a1, a2)
        --[[
          line: 1172
          upvalues:
            u8 (ref,  index: 1)
            ActionMenu_upv_1 (copy, index: 2)
            Values_upv_1 (copy, index: 3)
            u48 (copy, index: 4)
            Drag_upv_1 (copy, index: 5)
            RunService_upv_1 (copy, index: 6)
        ]]
        local u52 = 1;
        a1["MouseButton" .. 1 .. "Up"]:Connect(
            function()
                --[[
                  line: 1174
                  upvalues:
                    u8 (ref,  index: 1)
                    u52 (copy, index: 2)
                    a1 (copy, index: 3)
                    ActionMenu_upv_1 (copy, index: 4)
                    Values_upv_1 (copy, index: 5)
                    a2 (copy, index: 6)
                    u48 (copy, index: 7)
                    Drag_upv_1 (copy, index: 8)
                    RunService_upv_1 (copy, index: 9)
                ]]
                if (not u8 or u8.Mouse ~= u52) then
                    return;
                end;
                if (not u8.IsActionMenu or a1 ~= ActionMenu_upv_1.Split) then
                    if (Values_upv_1.ClientDropping.Value and a2) then
                        u48("Drop");
                    end;
                    Drag_upv_1.Visible = false;
                    RunService_upv_1:UnbindFromRenderStep("Drag");
                    u8 = nil;
                    return;
                end;
            end
        );
        local u53 = 2;
        a1["MouseButton" .. 2 .. "Up"]:Connect(
            function()
                --[[
                  line: 1174
                  upvalues:
                    u8 (ref,  index: 1)
                    u53 (copy, index: 2)
                    a1 (copy, index: 3)
                    ActionMenu_upv_1 (copy, index: 4)
                    Values_upv_1 (copy, index: 5)
                    a2 (copy, index: 6)
                    u48 (copy, index: 7)
                    Drag_upv_1 (copy, index: 8)
                    RunService_upv_1 (copy, index: 9)
                ]]
                if (not u8 or u8.Mouse ~= u53) then
                    return;
                end;
                if (not u8.IsActionMenu or a1 ~= ActionMenu_upv_1.Split) then
                    if (Values_upv_1.ClientDropping.Value and a2) then
                        u48("Drop");
                    end;
                    Drag_upv_1.Visible = false;
                    RunService_upv_1:UnbindFromRenderStep("Drag");
                    u8 = nil;
                    return;
                end;
            end
        );
    end;
    local function u54()
        --[[
          line: 158
          upvalues:
            u2 (copy, index: 1)
            tbl_upv_2 (copy, index: 2)
        ]]
        local X_1 = u2.X;
        local Y_1 = u2.Y;
        local v182 = nil;
        local v183 = nil;
        local v184 = nil;
        for key_8, value_14 in pairs(tbl_upv_2) do
            v182 = nil;
            v183 = nil;
            for _, value_15 in pairs((value_14:FindFirstChild("Inv") or value_14):GetChildren()) do
                if (value_15.Name:sub(1, 4) ~= "Slot" or not (value_15:IsA("ImageButton")) or not (value_15.Visible)) then
                    continue;
                end;
                v182 = value_15.AbsolutePosition;
                v183 = value_15.AbsoluteSize;
                if (v182.X > X_1 or X_1 > v182.X + v183.X or v182.Y > Y_1 or Y_1 > v182.Y + v183.Y) then
                    continue;
                end;
                v184 = tonumber(value_15.Name:sub(5));
                if (not (v184)) then
                    continue;
                end;
                return value_15, key_8, v184;
            end;
        end;
    end;
    do
        local function u55()
            --[[
              line: 1211
              upvalues:
                u31 (ref, index: 1)
            ]]
            local tbl_14 = {};
            for key_9, value_16 in pairs(u31) do
                if (key_9 ~= "Inventory") then
                    local v1;
                    if (key_9 ~= "Toolbar") then
                        continue;
                    end;
                end;
                for _, value_17 in pairs(value_16) do
                    if (not (value_17)) then
                        continue;
                    end;
                    if (value_17 ~= 0) then
                        local ID_2 = value_17.ID;
                        tbl_14[ID_2] = (tbl_14[ID_2] or 0) + value_17.Amount;
                    end;
                end;
            end;
            return tbl_14;
        end;
        local u56;
        local function u57(a1, a2, a3)
            --[[
              line: 1233
              upvalues:
                tbl_upv_2 (copy, index: 1)
                u13 (ref,  index: 2)
                Items_upv_1 (copy, index: 3)
                ResearchModule_upv_1 (copy, index: 4)
                u56 (ref,  index: 5)
                u55 (copy, index: 6)
                u20 (ref,  index: 7)
            ]]
            local v188 = nil;
            if (not (a1) or not (a2)) then
                local Bench_2 = tbl_upv_2.Bench;
                local v186;
                if (u13 and u13.Parent and Bench_2 and Bench_2.Parent) then
                    local v187 = nil;
                    if (Bench_2.Name == "CraftingStation") then
                        v187 = u13:GetAttribute("ID");
                        if (v187) then
                            v188, v186 = Bench_2, v187;
                        else
                            v188 = nil;
                            v186 = nil;
                        end;
                    else
                        v188, v186 = nil, nil;
                    end;
                else
                    v188, v186 = nil, nil;
                end;
                if (not v188) then
                    return;
                end;
                a2, a1 = v186, v188;
            end;
            if (not (a3)) then
                v188 = Items_upv_1[a2];
                local v189 = nil;
                if (v188) then
                    local Name_1 = v188.Name;
                    v189 = ResearchModule_upv_1:GetInfoFromName(Name_1);
                    if (not v189) then
                        return;
                    end;
                    a3 = v189.Tiers[(u56[Name_1] or 0) + 1];
                else
                    return;
                end;
            end;
            if (a3 ~= nil) then
                local v185 = true;
            else
                local v185 = false;
            end;
            if (a3) then
                local v190 = u55();
                local ID_3 = nil;
                local v191 = nil;
                local v192 = nil;
                for _, value_18 in pairs(a3) do
                    ID_3 = value_18.ID;
                    v192 = a1.UpgradeFrame.Items:FindFirstChild(ID_3);
                    if (not (v192)) then
                        continue;
                    end;
                    v191 = value_18.Amount <= (v190[ID_3] or 0);
                    v192.Grey.Visible = not v191;
                    if (not (v191)) then
                        local v185 = false;
                    end;
                end;
            end;
            if ((not u20 or not v188 or (u20:IsToggled())) and (v188 ~= false or not u20:IsToggled())) then
                return;
            end;
            task.defer(u20.ToggleButton, u20, v188);
        end;
        local function u58(a1, a2)
            --[[
              line: 1268
              upvalues:
                tbl_upv_2 (copy, index: 1)
                u13 (ref,  index: 2)
                Items_upv_1 (copy, index: 3)
                ResearchModule_upv_1 (copy, index: 4)
                u56 (ref,  index: 5)
                NumberUtil_upv_1 (copy, index: 6)
                u57 (copy, index: 7)
            ]]
            if (not (a1) or not (a2)) then
                local Bench_3 = tbl_upv_2.Bench;
                local v193;
                local v195 = nil;
                if (u13 and u13.Parent and Bench_3 and Bench_3.Parent) then
                    if (Bench_3.Name == "CraftingStation") then
                        v195 = u13:GetAttribute("ID");
                        if (v195) then
                            v195, v193 = Bench_3, v195;
                        else
                            v195 = nil;
                            v193 = nil;
                        end;
                    else
                        v195, v193 = nil, nil;
                    end;
                else
                    v195, v193 = nil, nil;
                end;
                if (not v195) then
                    return;
                end;
                a1, a2 = v195, v193;
            end;
            local Items_2 = a1.UnlocksFrame.Items;
            local Items_3 = a1.UpgradeFrame.Items;
            for _, value_19 in pairs(Items_3:GetChildren()) do
                if (value_19:IsA("ImageButton")) then
                    value_19:Destroy();
                end;
            end;
            for v196, v197 in pairs(Items_2:GetChildren()) do
                if (v197.Name ~= "Template") then
                    v197:Destroy();
                end;
            end;
            a1.UnlocksFrame.Maxed.Visible = false;
            local v198 = Items_upv_1[a2];
            local v199 = nil;
            if (v198) then
                local Name_2 = v198.Name;
                v199 = ResearchModule_upv_1:GetInfoFromName(Name_2);
                if (v199) then
                    local v196 = v199.Tiers;
                    local v197 = v199.Unlocks;
                    local v200 = u56[Name_2] or 0;
                    local v201 = #v196 <= v200;
                    local Label_1 = a1.Item.Label;
                    Label_1.Image = type(v198.Image) == "table" and v198.Image.Default or v198.Image;
                    a1.CurrentTier.Text = ("Current Tier: <font color=\"rgb(255, 248, 41)\">%*</font>"):format(v200);
                    local UpgradeTier_1 = a1.UpgradeTier;
                    local v203 = ("Upgrade Current Tier: <font color=\"rgb(255, 248, 41)\">%*</font>"):format(v200 .. ((v201 and " (MAX)") or ""));
                    local v204;
                    if (v201) then
                        v204 = "";
                    else
                        v204 = (" -> <font color=\"rgb(255, 248, 41)\">%*</font>"):format(v200 + 1 .. (((v200 + 1 ~= #v196) and "") or " (MAX)"));
                    end;
                    UpgradeTier_1.Text = v203 .. v204;
                    if (v201) then
                        a1.UnlocksFrame.Maxed.Visible = true;
                        a1.UpgradeFrame.Free.Text = "N/A";
                    else
                        local v205 = v196[v200 + 1];
                        local v206 = v197[v200 + 1] or {};
                        local v207 = math.max((math.floor((#v206 - 1) / 4) * 0.42) + 0.4, 1);
                        Items_2.CanvasSize = UDim2.new(0, 0, (v207 * 0.76) - 0.001, 0);
                        local Template_1 = Items_2.Template;
                        Template_1.Size = UDim2.new(0.24, 0, 0.4 / v207, 0);
                        local v208 = -1;
                        local v209 = nil;
                        local u59 = nil;
                        local ItemImage_2 = nil;
                        local v210 = nil;
                        for _, value_20 in pairs(v206) do
                            v208 = v208 + 1;
                            v209 = Items_upv_1[value_20.ID];
                            u59 = Template_1:Clone();
                            u59.Name = "Slot" .. v208 + 1;
                            ItemImage_2 = u59.ItemImage;
                            v210 = ((type(v209.Image) == "table") and (v209.Image.Default)) or (v209.Image);
                            ItemImage_2.Image = v210;
                            u59.ItemName.Text = v209.Name;
                            u59.Position = UDim2.new((v208 % 4) * 0.25, 0, (math.floor(v208 / 4) * 0.42) / v207, 0);
                            u59.Parent = Items_2;
                            u59.MouseEnter:Connect(
                                function()
                                    --[[
                                      line: 1318
                                      upvalues:
                                        u59 (copy, index: 1)
                                    ]]
                                    u59.ItemName:TweenPosition(UDim2.new(0.5, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.4, true);
                                end
                            );
                            u59.MouseLeave:Connect(
                                function()
                                    --[[
                                      line: 1321
                                      upvalues:
                                        u59 (copy, index: 1)
                                    ]]
                                    u59.ItemName:TweenPosition(UDim2.new(0.5, 0, -0.26, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.15, true);
                                end
                            );
                            u59.Visible = true;
                        end;
                        local v211 = nil;
                        local v212 = nil;
                        u59 = nil;
                        for _, value_21 in pairs(v205) do
                            v211 = Items_upv_1[value_21.ID];
                            v212 = Items_3.Layout.Template:Clone();
                            v212.Name = tostring(value_21.ID);
                            u59 = v212.ItemImage;
                            ItemImage_2 = ((type(v211.Image) == "table") and (v211.Image.Default)) or (v211.Image);
                            u59.Image = ItemImage_2;
                            v212.ItemName.Text = v211.Name;
                            u59 = v212.ItemAmount;
                            u59.Text = "x" .. NumberUtil_upv_1:FormatNumber(value_21.Amount);
                            v212.Parent = Items_3;
                        end;
                        a1.UpgradeFrame.Free.Text = ((#v205 > 0) and "") or "FREE";
                        u57(a1, a2, v205);
                    end;
                end;
            end;
        end;
        local tbl_upv_15 = {};
        local u60 = nil;
        local u61;
        local function u62(a1)
            --[[
              line: 1343
              upvalues:
                u31 (ref,  index: 1)
                u60 (ref,  index: 2)
                tbl_upv_15 (ref,  index: 3)
                Items_upv_1 (copy, index: 4)
                u61 (ref,  index: 5)
                ButtonClass_upv_1 (copy, index: 6)
                u22 (ref,  index: 7)
                u1 (copy, index: 8)
                u13 (ref,  index: 9)
                RecipeModule_upv_1 (copy, index: 10)
                ResearchModule_upv_1 (copy, index: 11)
                u56 (ref,  index: 12)
                u55 (copy, index: 13)
                NumberUtil_upv_1 (copy, index: 14)
                u21 (ref,  index: 15)
            ]]
            local Bench_4 = u31.Bench;
            if (not Bench_4 or not a1) then
                return;
            end;
            if (a1.Parent) then
                local v213 = Bench_4[1];
                local v214 = ((v213 == 0) and 0) or (v213.ID);
                local v215;
                if (u60 == v214) then
                    v215 = true;
                else
                    v215 = false;
                end;
                u60 = v214;
                local Items_4 = a1.CostFrame.Items;
                local Items_5 = a1.SkinsFrame.Items;
                if (not (v215)) then
                    local v216 = nil;
                    for _, value_22 in pairs(Items_4:GetChildren()) do
                        v216 = value_22:IsA("ImageButton");
                        if (v216) then
                            value_22:Destroy();
                        end;
                    end;
                    for key_10, value_23 in pairs(tbl_upv_15) do
                        value_23:Destroy();
                        if (key_10.Parent) then
                            key_10:Destroy();
                        end;
                    end;
                    tbl_upv_15 = {};
                end;
                local v217 = false;
                a1.DetailExtra.Text = "";
                local v218, v219 = nil, nil;
                if (type(v213) ~= "table") then
                    a1.SkinsFrame.Visible = false;
                    a1.CostFrame.Extra.Text = "Insert an item into the slot to Repair.";
                else
                    local v220 = Items_upv_1[v214];
                    v218 = v220.Image;
                    if (type(v218) ~= "table") then
                        a1.SkinsFrame.Visible = false;
                    else
                        if (not (v215)) then
                            local tbl_16 = {};
                            local v221 = nil;
                            for key_11, _ in pairs(v218) do
                                v221 = table.find(u61 or {}, v220.Name .. "/" .. key_11);
                                if (key_11 == "Default") then
                                    continue;
                                end;
                                if (v221) then
                                    table.insert(tbl_16, key_11);
                                end;
                            end;
                            table.insert(tbl_16, "Default");
                            local v222 = math.max((math.floor((#tbl_16 - 1) / 4) * 0.42) + 0.4, 1);
                            Items_5.CanvasSize = UDim2.new(0, 0, (v222 * 0.76) - 0.001, 0);
                            local v223 = Items_5.Template;
                            v223.Size = UDim2.new(0.24, 0, 0.4 / v222, 0);
                            local v224 = -1;
                            local v225 = nil;
                            for _, u63 in pairs(tbl_16) do
                                v224 = v224 + 1;
                                v225 = v223:Clone();
                                v225.Name = "Skin" .. u63;
                                v225.ItemImage.Image = v218[u63];
                                v225.ItemName.Text = u63;
                                v225.Position = UDim2.new(((v224 % 4) * 0.25) + 0.12, 0, ((math.floor(v224 / 4) * 0.42) + 0.2) / v222, 0);
                                v225.Parent = Items_5;
                                tbl_upv_15[v225] = ButtonClass_upv_1.new(
                                    v225,
                                    "BackgroundColor3",
                                    function()
                                        --[[
                                          line: 1399
                                          upvalues:
                                            u31 (ref,  index: 1)
                                            a1 (copy, index: 2)
                                            u22 (ref,  index: 3)
                                            u63 (copy, index: 4)
                                            u1 (copy, index: 5)
                                            u13 (ref,  index: 6)
                                        ]]
                                        local Bench_5 = u31.Bench;
                                        if (not Bench_5) then
                                            return;
                                        end;
                                        if (a1.Visible) then
                                            local v226 = Bench_5[1];
                                            if (tick() - u22 >= 0.4 and v226 and v226 ~= 0 and v226.Amount > 0 and v226.Skin ~= u63) then
                                                u22 = tick();
                                                u1("Fire", "\151\234\n\219\1715KF\162l\239L\001[\150fF\003\157D", "\240`\001`O\159\252\242~E\023\213K\175\017\t\227c\031\130", u13, "Repair2", u63);
                                                return;
                                            end;
                                        end;
                                    end,
                                    1.3,
                                    script:GetAttribute("SelectedSlotColor")
                                );
                                v225.Visible = true;
                            end;
                        end;
                        local v227 = nil;
                        for key_12, value_24 in pairs(tbl_upv_15) do
                            v227 = key_12.Name:sub(5);
                            if (v213.Skin ~= v227 or value_24:IsToggled()) then
                                if (v213.Skin == v227) then
                                    continue;
                                end;
                                if (value_24:IsToggled()) then
                                    task.defer(value_24.ToggleButton, value_24, false);
                                end;
                            else
                                task.defer(value_24.ToggleButton, value_24, true);
                            end;
                        end;
                        a1.SkinsFrame.Visible = true;
                    end;
                    local v228 = RecipeModule_upv_1:GetRecipesForItem(v214) or {};
                    v219 = v228[1];
                    if (v219) then
                        if (v213.Repair >= 1) then
                            a1.CostFrame.Extra.Text = "Item unavailable for repairing.";
                        else
                            local v229 = nil;
                            if (v220.MaxDurability) then
                                local BenchNeeded_1 = v219.BenchNeeded;
                                v229 = v219.TierNeeded;
                                local v230 = 0.5;
                                local v231 = nil;
                                if ((v229 or 0) > 0) then
                                    v231 = ResearchModule_upv_1:GetInfoFromName(BenchNeeded_1);
                                    local v232 = nil;
                                    if (v231) then
                                        v232 = v229 - (u56[BenchNeeded_1] or 0);
                                        local u63;
                                        if (v232 > 0) then
                                            u63 = v232;
                                        else
                                            u63 = 0.5;
                                        end;
                                        v230 = u63;
                                        if (v232 <= 4) then
                                            if (v230 > 0.5) then
                                                a1.DetailExtra.Text = ("<font color=\"rgb(255, 66, 69)\">%*X COST PENALTY</font> (<font color=\"rgb(0, 157, 255)\">%*</font> more <font color=\"rgb(255, 248, 41)\">%*</font> tiers needed for no penalty)"):format(math.round(v230 / 0.5), v232, BenchNeeded_1);
                                            end;
                                        else
                                            v230 = nil;
                                            a1.CostFrame.Extra.Text = ("Level %* %* or higher required."):format(math.max(v229 - 4, 0), BenchNeeded_1);
                                        end;
                                    end;
                                end;
                                if (v230) then
                                    local u63 = v219.SplitComponentOverride or {24};
                                    local v233 = RecipeModule_upv_1:CalculateTotalCost(v219, v230, u63, v219.RepairOverride or {6, 68, 179});
                                    if (not (v215)) then
                                        local v234 = nil;
                                        local v235 = nil;
                                        local v236 = nil;
                                        local v237 = nil;
                                        for key_13, value_25 in pairs(v233) do
                                            v234 = Items_upv_1[value_25.ID];
                                            v235 = Items_4.Layout.Template:Clone();
                                            v235.Name = "Slot" .. key_13;
                                            v236 = v235.ItemImage;
                                            v237 = ((type(v234.Image) == "table") and (v234.Image.Default)) or (v234.Image);
                                            v236.Image = v237;
                                            v235.ItemName.Text = v234.Name;
                                            v235.Parent = Items_4;
                                        end;
                                    end;
                                    local v238 = u55();
                                    local v239 = true;
                                    v217 = v239;
                                    local v236 = nil;
                                    local v240 = nil;
                                    for key_14, value_26 in pairs(v233) do
                                        v240 = Items_4:FindFirstChild("Slot" .. key_14);
                                        if (not (v240)) then
                                            continue;
                                        end;
                                        v240.ItemAmount.Text = "x" .. NumberUtil_upv_1:FormatNumber(math.ceil(value_26.Amount));
                                        v236 = (v238[value_26.ID] or 0) < math.ceil(value_26.Amount);
                                        v240.Grey.Visible = v236;
                                        if (v236) then
                                            v217 = false;
                                        end;
                                    end;
                                    if (v217 and ((v220.MaxDurability or 0) * (1 - v213.Repair)) - 0.01 <= v213.Durability) then
                                        v217 = false;
                                    end;
                                    a1.CostFrame.Extra.Text = "";
                                end;
                            else
                                a1.CostFrame.Extra.Text = "Item unavailable for repairing.";
                            end;
                        end;
                    else
                        a1.CostFrame.Extra.Text = "Item unavailable for repairing.";
                    end;
                end;
                if (not u21) then
                    return;
                end;
                if (not v217 or (u21:IsToggled())) then
                    if (not (v217) and u21:IsToggled()) then
                        task.defer(u21.ToggleButton, u21, false);
                    end;
                    return;
                end;
                task.defer(u21.ToggleButton, u21, true);
            end;
        end;
        local function u64()
            --[[
              line: 1190
              upvalues:
                WheelController_upv_1 (copy, index: 1)
                Humanoid_upv_1 (copy, index: 2)
                u33 (copy, index: 3)
            ]]
            if ((WheelController_upv_1:GetAttribute("Open")) or (Humanoid_upv_1:GetAttribute("Downed"))) then
                return;
            end;
            if (Humanoid_upv_1 and (Humanoid_upv_1.Parent and (Humanoid_upv_1.Health > 0))) then
                local v241 = ((script:GetAttribute("CurOpen") ~= "Crafting") and "Crafting") or "Inventory";
                u33(v241);
            end;
        end;
        local function u65()
            --[[
              line: 1185
              upvalues:
                WheelController_upv_1 (copy, index: 1)
                Humanoid_upv_1 (copy, index: 2)
                u33 (copy, index: 3)
            ]]
            if ((WheelController_upv_1:GetAttribute("Open")) or (Humanoid_upv_1:GetAttribute("Downed"))) then
                return;
            end;
            if (Humanoid_upv_1 and (Humanoid_upv_1.Parent and (Humanoid_upv_1.Health > 0))) then
                local v242 = ((script:GetAttribute("CurOpen") ~= "None") and "None") or "Inventory";
                u33(v242);
            end;
        end;
        UserInputService_upv_1.InputBegan:Connect(
            function(a1, a2)
                --[[
                  line: 1492
                  upvalues:
                    SettingsModule_upv_1 (copy, index: 1)
                    UserInputService_upv_1 (copy, index: 2)
                    u65 (copy, index: 3)
                    u64 (copy, index: 4)
                    u14 (ref,  index: 5)
                    u15 (ref,  index: 6)
                    WheelController_upv_1 (copy, index: 7)
                    Humanoid_upv_1 (copy, index: 8)
                    InteractController_upv_1 (copy, index: 9)
                    u33 (copy, index: 10)
                    u27 (ref,  index: 11)
                    tbl_upv_3 (ref,  index: 12)
                    ActionMenu_upv_1 (copy, index: 13)
                    u2 (copy, index: 14)
                    u31 (ref,  index: 15)
                    u8 (ref,  index: 16)
                    u34 (copy, index: 17)
                    u28 (ref,  index: 18)
                    u54 (copy, index: 19)
                    Values_upv_1 (copy, index: 20)
                    u48 (copy, index: 21)
                    Drag_upv_1 (copy, index: 22)
                    RunService_upv_1 (copy, index: 23)
                    u1 (copy, index: 24)
                    CurrentCamera_upv_1 (copy, index: 25)
                    u30 (ref,  index: 26)
                ]]
                local v243 = nil;
                if (not SettingsModule_upv_1.MainMenuOpen()) then
                    v243 = a1.UserInputType;
                    local v244 = UserInputService_upv_1:GetFocusedTextBox();
                    if (v243 == Enum.UserInputType.Keyboard) then
                        local v245 = nil;
                        if (not (v244)) then
                            v245 = a1.KeyCode.Name;
                            if (v245 == SettingsModule_upv_1.GetSetting("Controls", "Open Inventory")) then
                                u65();
                            elseif (v245 ~= SettingsModule_upv_1.GetSetting("Controls", "Open Crafting")) then
                                if (v245 == SettingsModule_upv_1.GetSetting("Controls", "Quick Loot") and not (a2)) then
                                    u14 = true;
                                    return;
                                end;
                                if (v245 == "LeftShift") then
                                    u15 = true;
                                end;
                            else
                                u64();
                            end;
                            return;
                        end;
                    end;
                    local v246, v247, v248, v249 = nil, nil, nil, nil;
                    if (v243 == Enum.UserInputType.Gamepad1) then
                        v246 = a1.KeyCode.Name;
                        local v250 = script:GetAttribute("Open");
                        v247 = script:GetAttribute("CurOpen");
                        if (v246 ~= SettingsModule_upv_1.GetSetting("Gamepad", "Open Inventory/Crafting")) then
                            if (v246 ~= "ButtonB" or not v250) then
                                if (v246 == SettingsModule_upv_1.GetSetting("Gamepad", "Jump") and v250 and not (u27) and tbl_upv_3) then
                                    local v251 = nil;
                                    if (ActionMenu_upv_1.Visible) then
                                        v251 = ActionMenu_upv_1.Split;
                                        v248 = v251.AbsolutePosition;
                                        v249 = v251.AbsoluteSize;
                                        if (v251.Visible and v248.X <= u2.X and u2.X <= v248.X + v249.X and v248.Y <= u2.Y) then
                                            local v252 = nil;
                                            if (u2.Y <= v248.Y + v249.Y) then
                                                v252 = u31[tbl_upv_3.Container];
                                                local v253 = nil;
                                                if (v252) then
                                                    v253 = v252[tbl_upv_3.Index];
                                                end;
                                                if (v252 and v253 and v253 ~= 0) then
                                                    if (not (u8)) then
                                                        u34(tbl_upv_3.Slot, tbl_upv_3.Slot.ItemImage.Image, tbl_upv_3.Container, tbl_upv_3.Index, 1, true, v253);
                                                    end;
                                                    u27 = true;
                                                    u28 = true;
                                                end;
                                            end;
                                        end;
                                        return;
                                    end;
                                end;
                                if (v246 == SettingsModule_upv_1.GetSetting("Gamepad", "Jump") and v250 and u27 and u8) then
                                    if (not u54()) then
                                        if (Values_upv_1.ClientDropping.Value) then
                                            u48("Drop");
                                        end;
                                        Drag_upv_1.Visible = false;
                                        RunService_upv_1:UnbindFromRenderStep("Drag");
                                        u8 = nil;
                                        u8 = false;
                                    end;
                                    return;
                                end;
                                if (v246 == SettingsModule_upv_1.GetSetting("Gamepad", "Interact/Reload")) then
                                    local v254 = nil;
                                    if (v250) then
                                        if (u27 and u8) then
                                            Drag_upv_1.Visible = false;
                                            RunService_upv_1:UnbindFromRenderStep("Drag");
                                            u8 = nil;
                                            u8 = false;
                                            return;
                                        end;
                                        local v254, v255, v256 = u54();
                                        if (v254) then
                                            if (tbl_upv_3 and tbl_upv_3.Slot == v254) then
                                                local v257 = nil;
                                                if (Values_upv_1.ClientDropping.Value) then
                                                    local Container_4 = tbl_upv_3.Container;
                                                    local Index_8 = tbl_upv_3.Index;
                                                    v257 = u31[Container_4];
                                                    local v258 = nil;
                                                    if (v257) then
                                                        v258 = v257[Index_8];
                                                    end;
                                                    if (v257 and v258 and v258 ~= 0 and v258.Amount > 0) then
                                                        u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", Container_4, Index_8, nil, "Drop", "none", "none", "none", CurrentCamera_upv_1.CFrame);
                                                    end;
                                                    return;
                                                end;
                                            end;
                                            u30(v254, v255, v256);
                                        elseif (tbl_upv_3) then
                                            u30(nil);
                                        end;
                                        return;
                                    end;
                                end;
                                if (v246 == "ButtonR2" and v250) then
                                    u14 = true;
                                end;
                                return;
                            end;
                            u33("None");
                        elseif (not (WheelController_upv_1:GetAttribute("Open")) and not (Humanoid_upv_1:GetAttribute("Downed")) and Humanoid_upv_1 and (Humanoid_upv_1.Parent and (Humanoid_upv_1.Health > 0)) and not (InteractController_upv_1:GetAttribute("Dialog"))) then
                            if (v250) then
                                if (v247 == "Inventory") then
                                    u33("Crafting");
                                elseif (v247 == "Crafting") then
                                    u33("Inventory");
                                end;
                            else
                                u33("Inventory");
                            end;
                            return;
                        end;
                    end;
                end;
            end
        );
        UserInputService_upv_1.InputEnded:Connect(
            function(a1, a2)
                --[[
                  line: 1589
                  upvalues:
                    UserInputService_upv_1 (copy, index: 1)
                    u11 (ref,  index: 2)
                    u27 (ref,  index: 3)
                    u8 (ref,  index: 4)
                    u28 (ref,  index: 5)
                    u54 (copy, index: 6)
                    Values_upv_1 (copy, index: 7)
                    u48 (copy, index: 8)
                    Drag_upv_1 (copy, index: 9)
                    RunService_upv_1 (copy, index: 10)
                    SettingsModule_upv_1 (copy, index: 11)
                    u14 (ref,  index: 12)
                    u15 (ref,  index: 13)
                ]]
                local UserInputType_1 = a1.UserInputType;
                local v259 = UserInputService_upv_1:GetFocusedTextBox();
                if (UserInputType_1 ~= Enum.UserInputType.MouseButton1) then
                    if (UserInputType_1 == Enum.UserInputType.MouseButton2 and u8 and u8.Mouse == 2 and not (a2)) then
                        if (Values_upv_1.ClientDropping.Value) then
                            u48("Drop");
                        end;
                        Drag_upv_1.Visible = false;
                        RunService_upv_1:UnbindFromRenderStep("Drag");
                        u8 = nil;
                        return;
                    end;
                    local v261 = nil;
                    if (UserInputType_1 == Enum.UserInputType.Keyboard) then
                        if (not (v259)) then
                            v261 = a1.KeyCode.Name;
                            if (v261 == SettingsModule_upv_1.GetSetting("Controls", "Quick Loot")) then
                                u14 = false;
                            elseif (v261 == "LeftShift") then
                                u15 = false;
                            end;
                            return;
                        end;
                    end;
                    if (UserInputType_1 == Enum.UserInputType.Gamepad1) then
                        v261 = a1.KeyCode.Name;
                        local v262 = script:GetAttribute("Open");
                        if ((v261 ~= SettingsModule_upv_1.GetSetting("Gamepad", "Jump") or not v262) and v261 == "ButtonR2") then
                            if (not v262) then
                                return;
                            end;
                            u14 = false;
                        end;
                        u11 = false;
                    end;
                else
                    u11 = false;
                    if (u27 and u8) then
                        if (u28) then
                            u28 = false;
                        elseif (not u54()) then
                            if (Values_upv_1.ClientDropping.Value) then
                                u48("Drop");
                            end;
                            Drag_upv_1.Visible = false;
                            RunService_upv_1:UnbindFromRenderStep("Drag");
                            u8 = nil;
                            u8 = false;
                        end;
                        return;
                    end;
                    if (not u8 or u8.Mouse ~= 1 or (a2)) then
                        return;
                    end;
                    if (Values_upv_1.ClientDropping.Value) then
                        u48("Drop");
                    end;
                    Drag_upv_1.Visible = false;
                    RunService_upv_1:UnbindFromRenderStep("Drag");
                    u8 = nil;
                end;
            end
        );
        ViewmodelController_upv_1.AttributeChanged:Connect(
            function(a1)
                --[[
                  line: 1638
                  upvalues:
                    ViewmodelController_upv_1 (copy, index: 1)
                    u24 (copy, index: 2)
                    Toolbar_upv_1 (copy, index: 3)
                    u31 (ref,  index: 4)
                ]]
                local v263;
                if (a1 ~= "LocalAmmo") then
                    return;
                end;
                v263 = ViewmodelController_upv_1:GetAttribute("Equipped");
                if (v263 <= 0) then
                    return;
                end;
                u24(Toolbar_upv_1["Slot" .. v263], u31.Toolbar[v263], ViewmodelController_upv_1:GetAttribute("LocalAmmo"));
            end
        );
        Humanoid_upv_1.Died:Connect(
            function()
                --[[
                  line: 1645
                  upvalues:
                    ItemSearchModule_upv_1 (copy, index: 1)
                    Drag_upv_1 (copy, index: 2)
                    RunService_upv_1 (copy, index: 3)
                    u8 (ref,  index: 4)
                    ViewportModule_upv_1 (copy, index: 5)
                    ViewportFrame_upv_1 (copy, index: 6)
                    WheelController_upv_1 (copy, index: 7)
                    u33 (copy, index: 8)
                ]]
                ItemSearchModule_upv_1.CancelSearch(true);
                Drag_upv_1.Visible = false;
                RunService_upv_1:UnbindFromRenderStep("Drag");
                u8 = nil;
                ViewportModule_upv_1:ClearViewport(ViewportFrame_upv_1);
                WheelController_upv_1:SetAttribute("Open", false);
                u33("None", true);
            end
        );
        Humanoid_upv_1:GetAttributeChangedSignal("Downed"):Connect(
            function()
                --[[
                  line: 1653
                  upvalues:
                    Humanoid_upv_1 (copy, index: 1)
                    WheelController_upv_1 (copy, index: 2)
                    u33 (copy, index: 3)
                ]]
                if (not Humanoid_upv_1:GetAttribute("Downed")) then
                    return;
                end;
                WheelController_upv_1:SetAttribute("Open", false);
                u33("None", true);
            end
        );
        PreferredInputController_upv_1:GetAttributeChangedSignal("PreferredInput"):Connect(
            function()
                --[[
                  line: 1659
                  upvalues:
                    PreferredInputController_upv_1 (copy, index: 1)
                    CraftingKeyboard_upv_1 (copy, index: 2)
                    CraftingConsole_upv_1 (copy, index: 3)
                    CraftingKeyboard_upv_2 (copy, index: 4)
                    CraftingConsole_upv_2 (copy, index: 5)
                    ImageLabel_upv_1 (copy, index: 6)
                    GamepadService_upv_1 (copy, index: 7)
                ]]
                CraftingKeyboard_upv_1.Visible = not PreferredInputController_upv_1;
                CraftingConsole_upv_1.Visible = PreferredInputController_upv_1;
                CraftingKeyboard_upv_2.Visible = not PreferredInputController_upv_1;
                CraftingConsole_upv_2.Visible = PreferredInputController_upv_1;
                ImageLabel_upv_1.Visible = PreferredInputController_upv_1;
                if (not script:GetAttribute("Open")) then
                    return;
                end;
                if (PreferredInputController_upv_1) then
                    pcall(
                        function()
                            --[[
                              line: 1668
                              upvalues:
                                GamepadService_upv_1 (copy, index: 1)
                            ]]
                            GamepadService_upv_1:EnableGamepadCursor(nil);
                        end
                    );
                else
                    pcall(
                        function()
                            --[[
                              line: 1670
                              upvalues:
                                GamepadService_upv_1 (copy, index: 1)
                            ]]
                            GamepadService_upv_1:DisableGamepadCursor();
                        end
                    );
                end;
            end
        );
        u51(HitboxHead_1, false);
        u51(HitboxChest_1, false);
        u51(HitboxLegs_1, false);
        u3, u4, u5 = u31, u56, u61;
        local v264 = nil;
        local v265 = nil;
        for v342, value_27 in Stats_1:GetChildren() do
            v264 = value_27:IsA("ImageButton");
            if (v264) then
                u3, u4, u5 = u31, u56, u61;
                u51(value_27, false);
                continue;
            end;
            v265 = value_27:IsA("TextButton");
            if (v265) then
                u3, u4, u5 = u31, u56, u61;
                u51(value_27, false);
            end;
        end;
        Stats_1.ChildAdded:Connect(
            function(a1)
                --[[
                  line: 1681
                  upvalues:
                    u51 (copy, index: 1)
                ]]
                if (not a1:IsA("ImageButton") and not a1:IsA("TextButton")) then
                    return;
                end;
                u51(a1, false);
            end
        );
        local u66 = nil;
        local v266 = nil;
        local v267 = nil;
        for v343, value_28 in Team_1:GetChildren() do
            v266 = value_28:IsA("ImageButton");
            if (v266) then
                u3 = u66;
                u3, u4, u5 = u31, u56, u61;
                u51(value_28, false);
                continue;
            end;
            v267 = value_28:IsA("TextButton");
            if (v267) then
                u3 = u66;
                u3, u4, u5 = u31, u56, u61;
                u51(value_28, false);
            else
                u3 = u66;
            end;
        end;
        ClientSignals_1:WaitForChild("Inventory").OnClientEvent:Connect(
            function(...)
                --[[
                  line: 1691
                  upvalues:
                    u13 (ref,  index: 1)
                    Benches_upv_1 (copy, index: 2)
                    u20 (ref,  index: 3)
                    ButtonClass_upv_1 (copy, index: 4)
                    u22 (ref,  index: 5)
                    u1 (copy, index: 6)
                    u58 (copy, index: 7)
                    u23 (ref,  index: 8)
                    Values_upv_1 (copy, index: 9)
                    u24 (copy, index: 10)
                    SoundModule_upv_1 (copy, index: 11)
                    tbl_upv_2 (copy, index: 12)
                    u66 (ref,  index: 13)
                    u21 (ref,  index: 14)
                    u33 (copy, index: 15)
                    tbl_upv_5 (copy, index: 16)
                    u18 (ref,  index: 17)
                    u19 (ref,  index: 18)
                    NumberUtil_upv_1 (copy, index: 19)
                    u4 (ref,  index: 20)
                    TweenUtil_upv_1 (copy, index: 21)
                    ViewmodelController_upv_1 (copy, index: 22)
                    tbl_upv_3 (ref,  index: 23)
                    u30 (ref,  index: 24)
                    u47 (copy, index: 25)
                    u62 (copy, index: 26)
                    CraftingController_upv_1 (copy, index: 27)
                    u57 (copy, index: 28)
                    ViewportModule_upv_1 (copy, index: 29)
                    ViewportFrame_upv_1 (copy, index: 30)
                    u8 (ref,  index: 31)
                    Drag_upv_1 (copy, index: 32)
                    RunService_upv_1 (copy, index: 33)
                    ActiveBenchModule_upv_1 (copy, index: 34)
                    ItemClass_upv_1 (copy, index: 35)
                ]]
                local tbl_17 = {...};
                local v268 = false;
                local v269 = false;
                local v270 = false;
                local v271 = false;
                local v272 = false;
                local v273 = false;
                local _;
                local v274 = nil;
                local v275 = nil;
                local v276 = nil;
                local v277 = nil;
                local v278 = nil;
                local u67 = nil;
                local v279 = nil;
                local v301 = nil;
                for key_15, value_29 in pairs(tbl_17) do
                    if (type(value_29) == "table") then
                        v274 = value_29[1];
                        if (v274) then
                            local v280 = value_29[2];
                            local v281 = value_29[3];
                            local v282 = value_29[4];
                            v275 = u66[v274];
                            local v283 = tbl_upv_2[v274];
                            if (not (v275) or not (v283)) then
                                continue;
                            end;
                            if (v282 == "LocalAmmo" and v281.Ammo) then
                                ViewmodelController_upv_1:SetAttribute("LocalAmmo", v281.Ammo.Amount);
                            end;
                            local v284 = (v283:FindFirstChild("Inv") or v283):FindFirstChild("Slot" .. v280);
                            local v285 = v275[v280];
                            if (tbl_upv_3 and tbl_upv_3.Slot == v284) then
                                if (v285 == 0 or v281 ~= 0 and v285.ID == v281.ID) then
                                    if (v270 == false and (v274 == "Inventory" or v274 == "Toolbar") and v281 and v285) then
                                        local v286 = ((v281 == 0) and 0) or (v281.ID);
                                        if (v286 ~= (((v285 == 0) and 0) or (v285.ID))) then
                                            v270 = true;
                                        else
                                            v286 = ((v281 == 0) and 0) or (v281.Amount);
                                            if (v286 ~= (((v285 == 0) and 0) or (v285.Amount))) then
                                                v270 = true;
                                            end;
                                        end;
                                    end;
                                    v275[v280] = v281;
                                    if (tbl_upv_3 and tbl_upv_3.Slot == v284) then
                                        u47();
                                    end;
                                    if (v284) then
                                        u24(v284, v281, nil, v268);
                                    end;
                                    if (v274 == "Armor") then
                                        v269 = true;
                                    end;
                                    if (v274 ~= "Bench") then
                                        continue;
                                    end;
                                    if (v283.Name == "RepairTable") then
                                        u62(v283);
                                        v272 = true;
                                        continue;
                                    end;
                                end;
                                task.defer(u30);
                            end;
                            if (v270 == false and (v274 == "Inventory" or v274 == "Toolbar") and v281 and v285) then
                                local v286 = ((v281 == 0) and 0) or (v281.ID);
                                if (v286 ~= (((v285 == 0) and 0) or (v285.ID))) then
                                    v270 = true;
                                else
                                    v286 = ((v281 == 0) and 0) or (v281.Amount);
                                    if (v286 ~= (((v285 == 0) and 0) or (v285.Amount))) then
                                        v270 = true;
                                    end;
                                end;
                            end;
                            v275[v280] = v281;
                            if (tbl_upv_3 and tbl_upv_3.Slot == v284) then
                                u47();
                            end;
                            if (v284) then
                                u24(v284, v281, nil, v268);
                            end;
                            if (v274 == "Armor") then
                                v269 = true;
                            end;
                            if (v274 ~= "Bench") then
                                continue;
                            end;
                            if (v283.Name == "RepairTable") then
                                u62(v283);
                                v272 = true;
                                continue;
                            end;
                        else
                            v276 = tbl_upv_2.Bench;
                            local v287, v288, v289, v290, v291;
                            if (not (v276)) then
                                continue;
                            end;
                            v287 = value_29.Upkeep;
                            v288 = value_29.UpkeepTick;
                            v275 = value_29.RL;
                            v289 = value_29.Offers;
                            v290 = value_29.MaxPower;
                            v291 = value_29.CurrentPower;
                            if (value_29.On == nil) then
                                if (v287 and v288) then
                                    v277 = v276:FindFirstChild("C");
                                    if (not (v277)) then
                                        continue;
                                    end;
                                    u67 = v276:FindFirstChild("ProtectionFrame");
                                    local v318, v319;
                                    if (not (u67)) then
                                        continue;
                                    end;
                                    for v320, value_30 in pairs(v276:GetChildren()) do
                                        if (value_30.Name:sub(1, 4) ~= "Cost") then
                                            continue;
                                        end;
                                        v278 = value_30:IsA("ImageButton");
                                        if (v278) then
                                            value_30:Destroy();
                                        end;
                                    end;
                                    local v292 = nil;
                                    for key_16, value_31 in pairs(v287) do
                                        v292 = v277:Clone();
                                        v292.Position = UDim2.new((0.5 - ((#v287 - 1) * 0.1)) + ((key_16 - 1) * 0.2), 0, 0.711, 0);
                                        v292.Name = "Cost" .. key_16;
                                        v292.Parent = v276;
                                        u24(v292, value_31);
                                        v292.Visible = true;
                                    end;
                                    u18 = v288;
                                    if (not (u19)) then
                                        u19 = true;
                                        Values_upv_1.ServerTick.Changed:Connect(
                                            function()
                                                --[[
                                                  line: 1814
                                                  upvalues:
                                                    u18 (ref,  index: 1)
                                                    Values_upv_1 (copy, index: 2)
                                                    u67 (copy, index: 3)
                                                    NumberUtil_upv_1 (copy, index: 4)
                                                ]]
                                                local v293 = math.max(u18 - Values_upv_1.ServerTick.Value, 0);
                                                if (not u67) then
                                                    return;
                                                end;
                                                if (u67.Parent) then
                                                    local Timer_1 = u67.Timer;
                                                    Timer_1.TextColor3 = u67.Timer:GetAttribute(((v293 <= 0) and "Decaying") or "Protected");
                                                    local Timer_2 = u67.Timer;
                                                    Timer_2.Text = v293 > 0 and NumberUtil_upv_1:FormatTime(v293, "Days", "Minutes", true) or "Base is Decaying!";
                                                end;
                                            end
                                        );
                                        continue;
                                    end;
                                else
                                    if (v275) then
                                        u4 = value_29.RL;
                                        v271 = true;
                                        continue;
                                    end;
                                    if (type(v289) ~= "table" or v273) then
                                        if (type(value_29.ShpAnim) == "number" and tbl_upv_2.Bench) then
                                            if (tbl_upv_2.Bench.Name ~= "TradingPost") then
                                                if (not (v291) or not (tbl_upv_2.Bench) or not (tbl_upv_2.Bench) or not (tbl_upv_2.Bench)) then
                                                    continue;
                                                end;
                                                if (tbl_upv_2.Bench.Name == "Battery") then
                                                    tbl_upv_2.Bench.PowerLabel.Text = v291 .. "kw / " .. v290 .. "kw";
                                                    tbl_upv_2.Bench.Bar.Fill.Size = UDim2.new(v291 / v290, 0, 1, 0);
                                                    continue;
                                                end;
                                            else
                                                u67 = tbl_upv_2.Bench:FindFirstChild("Trade" .. value_29.ShpAnim);
                                                if (u67) then
                                                    u67.Arrow.Rotation = 0;
                                                    TweenUtil_upv_1:Tween(u67.Arrow, "Rotation", 360, 0.5, "Quart", "InOut");
                                                    continue;
                                                end;
                                            end;
                                        else
                                            if (not (v291) or not (tbl_upv_2.Bench) or not (tbl_upv_2.Bench) or not (tbl_upv_2.Bench)) then
                                                continue;
                                            end;
                                            if (tbl_upv_2.Bench.Name == "Battery") then
                                                tbl_upv_2.Bench.PowerLabel.Text = v291 .. "kw / " .. v290 .. "kw";
                                                tbl_upv_2.Bench.Bar.Fill.Size = UDim2.new(v291 / v290, 0, 1, 0);
                                                continue;
                                            end;
                                        end;
                                    else
                                        v273 = v289;
                                        continue;
                                    end;
                                end;
                            else
                                v279 = v276:FindFirstChild("ControlFrame");
                                if (not (v279)) then
                                    continue;
                                end;
                                u67 = v279:FindFirstChild("Toggle");
                                if (not (u67)) then
                                    continue;
                                end;
                                v301 = tbl_upv_5[u67];
                                if (v301) then
                                    u67.Label.Text = ((value_29.On) and "Turn Off") or "Turn On";
                                    v301:ToggleButton(value_29.On);
                                    continue;
                                end;
                            end;
                        end;
                        continue;
                    else
                        if (value_29 == "IgnoreVMUpdate") then
                            v268 = true;
                            continue;
                        end;
                        if (typeof(value_29) == "Instance") then
                            u13 = value_29;
                            continue;
                        end;
                        if (type(value_29) ~= "string" or value_29:sub(1, 5) ~= "Bench") then
                            continue;
                        end;
                        v274 = Benches_upv_1:FindFirstChild(value_29:sub(6));
                        local key_17, v296, v297, v298, v321 = nil, nil, nil, nil, nil;
                        if (v274) then
                            key_17 = nil;
                            local v299 = nil;
                            v277 = nil;
                            u67 = nil;
                            local BenchName_1 = nil;
                            local value_32 = nil;
                            for _, value_32 in pairs(Benches_upv_1:GetChildren()) do
                                value_32.Visible = value_32 == v274;
                                if (value_32 ~= v274) then
                                    continue;
                                end;
                                key_17 = value_32:FindFirstChild("BenchName");
                                if (not (key_17)) then
                                    continue;
                                end;
                                key_17 = value_32:FindFirstChild("Inv") or value_32;
                                v299 = u13.Name;
                                v277 = u13:FindFirstChild("NameTag");
                                u67 = v299 == "Sleeper";
                                BenchName_1 = value_32.BenchName;
                                v296 = u13:GetAttribute("BenchName");
                                if (not (v296)) then
                                    if (v299 ~= "Body Bag") then
                                        v296 = u67 and ("INVENTORY OF <b>%*</b>"):format(v277 and v277.Label.Text or "[ERR]") or v299:upper();
                                    else
                                        v297 = "CORPSE OF <b>" .. (u13:GetAttribute("OwnerName") or "[ERR]") .. "</b>";
                                        v296 = v297 or u67 and ("INVENTORY OF <b>%*</b>"):format(v277 and v277.Label.Text or "[ERR]") or v299:upper();
                                    end;
                                end;
                                BenchName_1.Text = v296;
                                if (value_32.Name == "BodyLoot") then
                                    local BenchName_2 = value_32.BenchName;
                                    BenchName_2.Position = UDim2.new((u67 and 0.808) or 0.858, 0, 0.36, 0);
                                elseif (value_32.Name == "CraftingStation") then
                                    if (not (u20)) then
                                        u20 = ButtonClass_upv_1.new(
                                            value_32.UpgradeFrame.Upgrade,
                                            "BackgroundColor3",
                                            function()
                                                --[[
                                                  line: 1723
                                                  upvalues:
                                                    u22 (ref,  index: 1)
                                                    u13 (ref,  index: 2)
                                                    u1 (copy, index: 3)
                                                ]]
                                                if (tick() - u22 < 0.5 or not u13 or not u13.Parent) then
                                                    return;
                                                end;
                                                u22 = tick();
                                                u1("Fire", "\151\234\n\219\1715KF\162l\239L\001[\150fF\003\157D", "\240`\001`O\159\252\242~E\023\213K\175\017\t\227c\031\130", u13, "Upgrade");
                                            end,
                                            1.3,
                                            Color3.fromRGB(89, 148, 64)
                                        );
                                    end;
                                    u58(value_32, u13:GetAttribute("ID"));
                                elseif (value_32.Name == "Plinko") then
                                    u23 = u13:GetAttribute("PlinkoIndex");
                                    value_32.Timer.Text = Values_upv_1["PlinkoTimer" .. u23].Value .. "s";
                                end;
                                for v322, value_33 in pairs(key_17:GetChildren()) do
                                    if (value_33.Name:sub(1, 4) ~= "Slot") then
                                        continue;
                                    end;
                                    v298 = value_33:IsA("ImageButton");
                                    if (not (v298)) then
                                        continue;
                                    end;
                                    u24(value_33, 0);
                                    v298 = value_33:FindFirstChild("Checker");
                                    if (v298) then
                                        v298.Visible = true;
                                    end;
                                end;
                            end;
                            local Name_3 = u13.Name;
                            if ((v274) and v274.Name == "TradingPost") then
                                v275 = "Open2";
                            else
                                v275 = "Open";
                            end;
                            SoundModule_upv_1:PlayBenchSound(Name_3, v275, u13:GetAttribute("Skin"));
                            tbl_upv_2.Bench = v274;
                            local tbl_18 = {};
                            for key_17, value_34 in pairs((v274:FindFirstChild("Inv") or v274):GetChildren()) do
                                if (value_34.Name:sub(1, 4) == "Slot") then
                                    table.insert(tbl_18, 0);
                                end;
                            end;
                            u66.Bench = tbl_18;
                            if (v274.Name ~= "RepairTable") then
                                u33("Inventory");
                                continue;
                            end;
                            if (not (u21)) then
                                u21 = ButtonClass_upv_1.new(
                                    v274.CostFrame.Repair,
                                    "BackgroundColor3",
                                    function()
                                        --[[
                                          line: 1758
                                          upvalues:
                                            u13 (ref,  index: 1)
                                            u22 (ref,  index: 2)
                                            u21 (ref,  index: 3)
                                            u1 (copy, index: 4)
                                        ]]
                                        if (not u13 or not u13.Parent or tick() - u22 < 0.4 or not u21:IsToggled()) then
                                            return;
                                        end;
                                        u22 = tick();
                                        u1("Fire", "\151\234\n\219\1715KF\162l\239L\001[\150fF\003\157D", "\240`\001`O\159\252\242~E\023\213K\175\017\t\227c\031\130", u13, "Repair1");
                                    end,
                                    1.3,
                                    Color3.fromRGB(89, 148, 64)
                                );
                            end;
                            u33("Inventory");
                        else
                            return;
                        end;
                    end;
                end;
                if (v271) then
                    CraftingController_upv_1.Update:Fire("Research");
                    u58();
                elseif (v270) then
                    u57();
                    CraftingController_upv_1.Update:Fire();
                    v301 = tbl_upv_2.Bench;
                    if (v301 and v301.Parent and v301.Name == "RepairTable" and not (v272)) then
                        u62(v301);
                    end;
                end;
                if (v269) then
                    ViewportModule_upv_1:UpdateArmors(ViewportFrame_upv_1, u66.Armor);
                end;
                if (u8) then
                    v301 = u66[u8.Container];
                    if (v301) then
                        if (v301[u8.Index] == 0) then
                            Drag_upv_1.Visible = false;
                            RunService_upv_1:UnbindFromRenderStep("Drag");
                            u8 = nil;
                        end;
                    elseif (u8.Container == "Bench") then
                        Drag_upv_1.Visible = false;
                        RunService_upv_1:UnbindFromRenderStep("Drag");
                        u8 = nil;
                    end;
                end;
                if (not v273 or not tbl_upv_2.Bench or tbl_upv_2.Bench.Name ~= "TradingPost" or not u66.Bench or not u13) then
                    return;
                end;
                if (u13.Parent) then
                    v301 = ActiveBenchModule_upv_1.GetClientInfo(u13);
                    local v302 = false;
                    if (type(v301) == "table") then
                        v302 = v301.CanEdit == true;
                    end;
                    local Bench_6 = tbl_upv_2.Bench;
                    local key_15 = 1;
                    local value_29 = 2;
                    local v303, v304, v305, v305 = nil, nil, nil, nil;
                    for n_6 = 1, 5 do
                        local v306 = Bench_6[("Give%*"):format(n_6)];
                        local v307 = Bench_6[("Receive%*"):format(n_6)];
                        local v308 = tbl_upv_5[Bench_6[("Trade%*"):format(n_6)]];
                        local v309 = tbl_upv_5[v306];
                        local v310 = tbl_upv_5[v307];
                        local v311;
                        v311 = v273[key_15];
                        local v312 = v273[value_29];
                        v303 = 0;
                        v305 = 0;
                        if (type(v311) == "table" and v311[1] ~= 0 and v311[2] >= 0) then
                            v303 = ItemClass_upv_1.new(v311[1], v311[2]);
                        end;
                        v304 = false;
                        if (type(v312) == "table" and v312[1] ~= 0 and v312[2] > 0) then
                            if (u13:GetAttribute("ShopOnly")) then
                                v304 = true;
                                v305 = ItemClass_upv_1.new(v312[1], v312[2]);
                            else
                                local v313 = 0;
                                local v314 = nil;
                                local v315 = nil;
                                for v323, value_35 in pairs(u66.Bench) do
                                    if (value_35 == 0 or value_35.ID ~= v312[1]) then
                                        continue;
                                    end;
                                    v315 = v313 + value_35.Amount;
                                    if (v314) then
                                        v313 = v315;
                                    else
                                        v313, v314 = v315, value_35;
                                    end;
                                end;
                                if (v314) then
                                    v305 = table.clone(v314);
                                    v305.Amount = v312[2];
                                else
                                    v305 = ItemClass_upv_1.new(v312[1], v312[2]);
                                end;
                                v278 = false;
                                if (v312[2] <= v313) then
                                    v278 = type(v303) == "table";
                                end;
                                v304 = v278;
                            end;
                        end;
                        if (v309) then
                            v309:Enable(v302);
                        end;
                        if (v310) then
                            v310:Enable(v302);
                        end;
                        if (v308) then
                            if (v304) then
                                if (v304) then
                                    local v316;
                                    v316 = v308:IsToggled();
                                    if (not (v316)) then
                                        task.defer(v308.ToggleButton, v308, v304);
                                    end;
                                end;
                            else
                                local v317;
                                v317 = v308:IsToggled();
                                if (v317) then
                                    task.defer(v308.ToggleButton, v308, v304);
                                elseif (v304) then
                                    local v316;
                                    v316 = v308:IsToggled();
                                    if (not (v316)) then
                                        task.defer(v308.ToggleButton, v308, v304);
                                    end;
                                end;
                            end;
                        elseif (v304) then
                            local v316;
                            v316 = v308:IsToggled();
                            if (not (v316)) then
                                task.defer(v308.ToggleButton, v308, v304);
                            end;
                        end;
                        u24(v306, v303);
                        if (type(v303) == "table") then
                            v306.ItemAmount.Text = ("x%*"):format(NumberUtil_upv_1:FormatNumber(v303.Amount));
                        end;
                        u24(v307, v305);
                        if (type(v305) == "table") then
                            v307.ItemAmount.Text = ("x%*"):format(NumberUtil_upv_1:FormatNumber(v305.Amount));
                        end;
                        key_15 = key_15 + 2;
                        value_29 = value_29 + 2;
                    end;
                end;
            end
        );
        u1(
            "Setup",
            "\156\002I=\144i\181\249\200\249\198Q\020\205\1431\142\001\1391",
            "\140^\1720\244\2504\202,\206\001\142\2236\218!\233fN\t",
            function(a1, ...)
                --[[
                  line: 1996
                  upvalues:
                    tbl_upv_2 (copy, index: 1)
                    u32 (copy, index: 2)
                ]]
                local tbl_19 = {...};
                local v318 = nil;
                if (a1 == "Close") then
                    local v319 = tbl_19[1];
                    v318 = tbl_upv_2.Bench;
                    if (v318 and v318.Name == v319) then
                        u32();
                        return;
                    end;
                end;
            end
        );
        Fetch_1.OnInvoke = function()
            --[[
              line: 2008
              upvalues:
                u66 (ref, index: 1)
                u4 (ref, index: 2)
                u5 (ref, index: 3)
            ]]
            return u66, u4, u5;
        end;
    end;
    GetBench_1.OnInvoke = function()
        --[[
          line: 2014
          upvalues:
            u13 (ref, index: 1)
        ]]
        return u13;
    end;
    ItemStats_1.OnInvoke = u46;
    Toggle_1.Event:Connect(u33);
    script:WaitForChild("EquipArmor").Event:Connect(
        function(a1)
            --[[
              line: 2020
              upvalues:
                Toolbar_upv_1 (copy, index: 1)
                u36 (copy, index: 2)
                u15 (ref,  index: 3)
            ]]
            u36(Toolbar_upv_1[("Slot%*"):format(a1)], "Toolbar", a1, u15, "ArmorEquip");
        end
    );
    BG_upv_1.Visible = true;
    Inventory_upv_1.Visible = true;
    Crafting_upv_1.Visible = true;
    local function v320()
        --[[
          line: 155
          upvalues:
            PreferredInputController_upv_1 (copy, index: 1)
        ]]
        return PreferredInputController_upv_1;
    end;
    CraftingKeyboard_upv_1.Visible = not v320();
    CraftingConsole_upv_1.Visible = v320();
    local v321 = SettingsModule_upv_1.GetSetting("Controls", "Open Crafting");
    CraftingKeyboard_upv_1.Text = ("CRAFTING [<font color=\"rgb(255, 244, 88)\">%*</font>]"):format(v321);
    CraftingConsole_upv_1.Text = "CRAFTING    ";
    CraftingKeyboard_upv_2.Text = ("INVENTORY [<font color=\"rgb(255, 244, 88)\">%*</font>]"):format(v321);
    CraftingConsole_upv_2.Text = "INVENTORY    ";
    CraftingKeyboard_upv_2.Visible = not v320();
    CraftingConsole_upv_2.Visible = v320();
    ImageLabel_upv_1.Visible = v320();
    u33("None", true);
    u37(1);
    ActionMenu_upv_1.Visible = false;
    u3, u4, u5 = u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "\163\246\172'\216w\147D\2045\001\143IH\142\236Zk1\028");
    ViewportModule_upv_1:Initialize();
    local u68 = nil;
    ViewportModule_upv_1:ShowCharacter(ViewportFrame_upv_1, Parent_1, {HitboxChest_1, HitboxHead_1, HitboxLegs_1}, u68.Armor);
    script:SetAttribute("Initiated", true);
    ActionMenu_upv_1.SplitBar.MouseButton1Down:Connect(
        function()
            --[[
              line: 2049
              upvalues:
                tbl_upv_3 (ref,  index: 1)
                u68 (ref,  index: 2)
                u11 (ref,  index: 3)
                u2 (copy, index: 4)
                ActionMenu_upv_1 (copy, index: 5)
                u12 (ref,  index: 6)
                u38 (copy, index: 7)
                RunService_upv_1 (copy, index: 8)
            ]]
            local v322 = nil;
            if (tbl_upv_3) then
                v322 = u68[tbl_upv_3.Container];
                local v323;
                if (not v322) then
                    return;
                end;
                v323 = v322[tbl_upv_3.Index];
                if (v323 and v323 ~= 0 and v323.Amount > 0) then
                    u11 = true;
                    while (u11 and (tbl_upv_3) and tbl_upv_3 == tbl_upv_3) do
                        u12 = math.ceil(v323.Amount * math.clamp(math.clamp((u2.X - ActionMenu_upv_1.SplitBar.AbsolutePosition.X) / ActionMenu_upv_1.SplitBar.AbsoluteSize.X, 0, 1), 0, 1));
                        u38();
                        RunService_upv_1.Heartbeat:Wait();
                    end;
                end;
            end;
        end
    );
    u51(ActionMenu_upv_1.SplitBar, true);
    u39(
        ActionMenu_upv_1.Split,
        1,
        function(a1, a2)
            --[[
              line: 2068
              upvalues:
                tbl_upv_3 (ref,  index: 1)
                u68 (ref,  index: 2)
                u8 (ref,  index: 3)
                u34 (copy, index: 4)
            ]]
            local v324 = nil;
            if (tbl_upv_3) then
                local Slot_2 = tbl_upv_3.Slot;
                v324 = u68[tbl_upv_3.Container];
                if (v324) then
                    local v325 = nil;
                    if (Slot_2) then
                        v325 = v324[tbl_upv_3.Index];
                        if (v325 and v325 ~= 0 and not (u8)) then
                            a1 = u34(Slot_2, Slot_2.ItemImage.Image, tbl_upv_3.Container, tbl_upv_3.Index, a2, true, v325);
                        end;
                    end;
                end;
            end;
            return a1, a2;
        end
    );
    u51(ActionMenu_upv_1.Split, true);
    pcall(
        function()
            --[[
              line: 2083
              upvalues:
                RunService_upv_1 (copy, index: 1)
            ]]
            RunService_upv_1:UnbindFromRenderStep("SliderTextPosition");
        end
    );
    RunService_upv_1:BindToRenderStep(
        "SliderTextPosition",
        Enum.RenderPriority.Last.Value,
        function()
            --[[
              line: 2086
              upvalues:
                ActionMenu_upv_1 (copy, index: 1)
            ]]
            ActionMenu_upv_1.SplitBar.Amount.Position = UDim2.new(math.max(ActionMenu_upv_1.SplitBar.Fill.Size.X.Scale, 0.1), 0, 0.5, 0);
        end
    );
    u3 = u68;
    for n_upv_7 = 1, 4 do
        local u69 = ActionMenu_upv_1.ItemDetails["Slot" .. n_upv_7];
        u39(
            u69,
            1,
            function(a1, a2)
                --[[
                  line: 2092
                  upvalues:
                    tbl_upv_3 (ref,  index: 1)
                    u70 (ref,  index: 2)
                    u8 (ref,  index: 3)
                    n_upv_7 (copy, index: 4)
                    u34 (copy, index: 5)
                    u69 (copy, index: 6)
                ]]
                local Slot_3 = tbl_upv_3.Slot;
                local v326 = u70[tbl_upv_3.Container];
                local v327 = nil;
                if (v326) then
                    v327 = v326[tbl_upv_3.Index];
                    if (v327 and v327 ~= 0 and v327.Amount > 0) then
                        local v328 = nil;
                        if (not (u8)) then
                            v328 = v327.Attachments[u70];
                            if (v328) then
                                a1 = u34(Slot_3, u69.ItemImage.Image, tbl_upv_3.Container, tbl_upv_3.Index, a2, u70, v328);
                            end;
                        end;
                    end;
                end;
                return a1, a2;
            end,
            function()
                --[[
                  line: 2105
                  upvalues:
                    tbl_upv_3 (ref,  index: 1)
                    u8 (ref,  index: 2)
                    u70 (ref,  index: 3)
                    SoundModule_upv_1 (copy, index: 4)
                    u1 (copy, index: 5)
                ]]
                local v329 = nil;
                if (tbl_upv_3) then
                    local Container_5 = u8.Container;
                    local Index_9 = u8.Index;
                    v329 = u70[Container_5];
                    local v330;
                    if (not v329) then
                        return;
                    end;
                    v330 = v329[Index_9];
                    if (v330 and v330 ~= 0 and v330.Amount > 0) then
                        SoundModule_upv_1:PlayItemSound(v330.ID, "Drop");
                    end;
                    u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", Container_5, Index_9, v330.Amount, tbl_upv_3.Container, tbl_upv_3.Index);
                end;
            end,
            function(a1)
                --[[
                  line: 2123
                  upvalues:
                    PreferredInputController_upv_1 (copy, index: 1)
                    tbl_upv_3 (ref,  index: 2)
                    u8 (ref,  index: 3)
                    u70 (ref,  index: 4)
                    n_upv_7 (copy, index: 5)
                    u34 (copy, index: 6)
                    u69 (copy, index: 7)
                    u27 (ref,  index: 8)
                ]]
                if (not PreferredInputController_upv_1) then
                    return;
                end;
                if (tbl_upv_3) then
                    local v331 = nil;
                    if (not (u8)) then
                        v331 = u70[tbl_upv_3.Container];
                        local v332;
                        if (not v331) then
                            return;
                        end;
                        v332 = v331[tbl_upv_3.Index];
                        if (not v332 or v332 == 0) then
                            return;
                        end;
                        if (v332.Amount > 0) then
                            local v333 = v332.Attachments[u70];
                            if (not v333) then
                                return;
                            end;
                            u34(tbl_upv_3.Slot, u69.ItemImage.Image, tbl_upv_3.Container, tbl_upv_3.Index, a1, u70, v333);
                            u27 = true;
                        end;
                    end;
                end;
            end
        );
        u3 = u70;
        u3 = u70;
    end;
    u3 = u70;
    local Name_upv_4 = nil;
    for v344, value_36 in pairs(ActionMenu_upv_1.Actions:GetChildren()) do
        Name_upv_4 = value_36.Name;
        value_36.Activated:Connect(
            function()
                --[[
                  line: 2141
                  upvalues:
                    tbl_upv_3 (ref,  index: 1)
                    u3 (ref,  index: 2)
                    Items_upv_1 (copy, index: 3)
                    Name_upv_4 (copy, index: 4)
                    Values_upv_1 (copy, index: 5)
                    u1 (copy, index: 6)
                    CurrentCamera_upv_1 (copy, index: 7)
                    u25 (ref,  index: 8)
                ]]
                local v334 = nil;
                if (tbl_upv_3) then
                    local Container_6 = tbl_upv_3.Container;
                    local Index_10 = tbl_upv_3.Index;
                    v334 = u3[Container_6];
                    local v335;
                    if (not v334) then
                        return;
                    end;
                    v335 = v334[Index_10];
                    if (not v335) then
                        return;
                    end;
                    if (v335 ~= 0) then
                        local v336;
                        if (v335.Amount <= 0) then
                            return;
                        end;
                        v336 = Items_upv_1[v335.ID];
                        if ((Name_upv_4 ~= "Drop" or not Values_upv_1.ClientDropping.Value) and Name_upv_4 == "Action1") then
                            local DropInfo_2 = v336.DropInfo;
                            if (v336.Type == "Gun" and v335.Ammo and v335.Ammo.Amount > 0) then
                                u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", Container_6, Index_10, "UnloadAmmo");
                                return;
                            end;
                            if (DropInfo_2) then
                                u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", Container_6, Index_10, "ItemDrop");
                            else
                                local v337;
                                if (not v336.Type:find("Consumable")) then
                                    return;
                                end;
                                v337 = tick();
                                if (v337 - u25 < 0.15) then
                                    return;
                                end;
                                u25 = v337;
                                u1("Fire", "\134n&\002\225A|[\0191\025\027m\001\128O>p\183\145", "\245A\150x@\231Er*\173\173b\191\178\001\138|\178\150\187", Container_6, Index_10);
                            end;
                        end;
                        u1("Fire", "\136\189BE\023r\255\001<\018\185S9\215\198\026B\245\016\217", "E\001\190\156a`O;8\201\21480MNv\127\190\255\023", Container_6, Index_10, nil, "Drop", "none", "none", "none", CurrentCamera_upv_1.CFrame);
                    end;
                end;
            end
        );
        u51(value_36, true);
    end;
end;
local u71 = nil;
local u72 = nil;
for key_18, value_37 in pairs(u3) do
    for key_19, value_38 in pairs(value_37) do
        u71 = tbl_upv_2[key_18];
        if (u71) then
            u72 = u71["Slot" .. key_19];
            v1_1(u72, key_18, key_19);
            u24(u72, value_38);
        end;
    end;
end;
local v345, v346, ButtonClass_upv_1, ItemSearchModule_upv_1, u1, u73, Values_upv_1, Benches_upv_1 = nil, nil, nil, nil, nil, nil, nil, nil;
u73 = tbl_upv_5;
local v338 = nil;
local v339 = nil;
local u74 = nil;
local value_39 = nil;
local u75 = nil;
local v347 = nil;
for key_upv_20, value_39 in pairs(Benches_upv_1:GetChildren()) do
    value_39.Visible = false;
    v338 = value_39:FindFirstChild("Inv") or value_39;
    u74 = u73;
    for v348, value_40 in pairs(v338:GetChildren()) do
        if (v338.Name ~= "TradingPost") then
            if (v338.Name == "ArmorStand" and u71.Name == "Swap") then
                u72 = false;
                u71.BackgroundColor3 = u71:GetAttribute("ColorOn");
                u73[u71] = ButtonClass_upv_1.new(
                    u71,
                    "BackgroundColor3",
                    function()
                        --[[
                          line: 2256
                          upvalues:
                            u13 (ref,  index: 1)
                            u72 (ref,  index: 2)
                            u71 (copy, index: 3)
                            TweenUtil_upv_1 (copy, index: 4)
                            u73 (copy, index: 5)
                            u1 (copy, index: 6)
                        ]]
                        if (not u13 or u72) then
                            return;
                        end;
                        u72 = true;
                        u71.Arrow.Rotation = 0;
                        TweenUtil_upv_1:Tween(u71.Arrow, "Rotation", 360, 0.5, "Quart", "InOut");
                        task.spawn(u73[u71].ToggleButton, u73[u71], true);
                        u1("Fire", "\151\234\n\219\1715KF\162l\239L\001[\150fF\003\157D", "\240`\001`O\159\252\242~E\023\213K\175\017\t\227c\031\130", u13, "StandSwap");
                        task.wait(1);
                        if (not u71.Parent) then
                            return;
                        end;
                        u72 = false;
                        u73[u71]:ToggleButton(false);
                    end,
                    1.3,
                    u71:GetAttribute("ColorOff")
                );
            end;
            if (u71.Name:sub(1, 4) ~= "Slot") then
                u74 = u73;
                continue;
            end;
            u72 = tonumber(u71.Name:sub(5));
            if (u72) then
                v1_1(u71, "Bench", u72);
                u24(u71, 0);
            end;
            u74 = u73;
        else
            u72 = 0;
            local num_upv_2 = tonumber(value_40.Name:gsub("%D", ""));
            local v340 = value_40.Name:sub(1, 4) == "Give";
            if (value_40.Name:sub(1, 5) == "Trade") then
                value_40.BackgroundColor3 = value_40:GetAttribute("ColorOff");
                u74[value_40] = ButtonClass_upv_1.new(
                    value_40,
                    "BackgroundColor3",
                    function()
                        --[[
                          line: 2215
                          upvalues:
                            u13 (ref,  index: 1)
                            u72 (ref,  index: 2)
                            u1 (copy, index: 3)
                            num_upv_2 (copy, index: 4)
                        ]]
                        local v341;
                        if (not u13) then
                            return;
                        end;
                        v341 = tick();
                        if (v341 - u72 < 0.2) then
                            return;
                        end;
                        u72 = v341;
                        u1("Fire", "\151\234\n\219\1715KF\162l\239L\001[\150fF\003\157D", "\240`\001`O\159\252\242~E\023\213K\175\017\t\227c\031\130", u13, "ShopBuy", num_upv_2);
                    end,
                    1.3,
                    value_40:GetAttribute("ColorOn")
                );
                continue;
            end;
            if (v340 or value_40.Name:sub(1, 7) == "Receive") then
                local u76 = num_upv_2 * 2 - ((v340 and 1) or 0);
                u74[value_40] = ButtonClass_upv_1.new(
                    value_40,
                    "BackgroundColor3",
                    function()
                        --[[
                          line: 2228
                          upvalues:
                            u13 (ref,  index: 1)
                            ItemSearchModule_upv_1 (copy, index: 2)
                            u72 (ref,  index: 3)
                            u1 (copy, index: 4)
                            u76 (copy, index: 5)
                        ]]
                        if (not u13 or not u13.Parent) then
                            return;
                        end;
                        if (not (u13:GetAttribute("OffersLocked"))) then
                            local v342 = nil;
                            if (not (ItemSearchModule_upv_1.IsSearching())) then
                                v342 = tick();
                                local v343 = nil;
                                if (v342 - u72 >= 0.2) then
                                    u72 = v342;
                                    local v343, v344 = ItemSearchModule_upv_1.BeginSearch();
                                    if (not v343 or not v344) then
                                        return;
                                    end;
                                    u1("Fire", "\151\234\n\219\1715KF\162l\239L\001[\150fF\003\157D", "\240`\001`O\159\252\242~E\023\213K\175\017\t\227c\031\130", u13, "ShopUpdate", (("%*/%*/%*"):format(u76, v343, v344)));
                                end;
                            end;
                        end;
                    end,
                    1.3,
                    Color3.fromRGB(75, 35, 35),
                    function()
                        --[[
                          line: 2240
                          upvalues:
                            u13 (ref,  index: 1)
                            u72 (ref,  index: 2)
                            u1 (copy, index: 3)
                            u76 (copy, index: 4)
                        ]]
                        local v345;
                        if (not u13) then
                            return;
                        end;
                        v345 = tick();
                        if (v345 - u72 < 0.2) then
                            return;
                        end;
                        u72 = v345;
                        u1("Fire", "\151\234\n\219\1715KF\162l\239L\001[\150fF\003\157D", "\240`\001`O\159\252\242~E\023\213K\175\017\t\227c\031\130", u13, "ShopUpdate", (("%*/0/0"):format(u76)));
                    end
                );
            end;
        end;
    end;
    u75 = 0;
    v339 = value_39:FindFirstChild("ControlFrame");
    if (not (v339)) then
        u73 = u74;
        continue;
    end;
    local Toggle_upv_2 = v339:FindFirstChild("Toggle");
    if (Toggle_upv_2) then
        Toggle_upv_2.BackgroundColor3 = Toggle_upv_2:GetAttribute("ColorOff");
        u74[Toggle_upv_2] = ButtonClass_upv_1.new(
            Toggle_upv_2,
            "BackgroundColor3",
            function()
                --[[
                  line: 2285
                  upvalues:
                    u13 (ref,  index: 1)
                    u75 (ref,  index: 2)
                    u1 (copy, index: 3)
                    u74 (copy, index: 4)
                    Toggle_upv_2 (copy, index: 5)
                ]]
                local v346;
                if (not u13) then
                    return;
                end;
                v346 = tick();
                if (v346 - u75 >= 0.2) then
                    u75 = v346;
                    local v347 = ((u74[Toggle_upv_2]:IsToggled()) and "Turn Off") or "Turn On";
                    u1("Fire", "\151\234\n\219\1715KF\162l\239L\001[\150fF\003\157D", "\240`\001`O\159\252\242~E\023\213K\175\017\t\227c\031\130", u13, v347);
                end;
            end,
            1.3,
            Toggle_upv_2:GetAttribute("ColorOn")
        );
    end;
    u73 = u74;
end;
for n_upv_8 = 1, 4 do
    local key_upv_20 = Values_upv_1:WaitForChild("PlinkoTimer" .. n_upv_8);
    key_upv_20:GetPropertyChangedSignal("Value"):Connect(
        function()
            --[[
              line: 2300
              upvalues:
                n_upv_8 (copy, index: 1)
                u23 (ref,  index: 2)
                Benches_upv_1 (copy, index: 3)
                key_upv_20 (copy, index: 4)
            ]]
            if (n_upv_8 ~= u23 or not Benches_upv_1.Plinko.Visible) then
                return;
            end;
            Benches_upv_1.Plinko.Timer.Text = key_upv_20.Value .. "s";
        end
    );
end;