-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local UserInputService = game:GetService("UserInputService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
game:GetService("RunService");
local Values = ReplicatedStorage:WaitForChild("Values");
local LocalPlayer = Players.LocalPlayer;
local PlayerGui = LocalPlayer.PlayerGui;
local Parent = script.Parent;
local Humanoid = Parent:WaitForChild("Humanoid");
local InventoryController = Parent:WaitForChild("InventoryController");
local ViewmodelController = Parent:WaitForChild("ViewmodelController");
local BuildController = Parent:WaitForChild("BuildController");
local CameraController = Parent:WaitForChild("CameraController");
local InteractController = Parent:WaitForChild("InteractController");
local ElectricityController = Parent:WaitForChild("ElectricityController");
local Modules = ReplicatedStorage:WaitForChild("Modules");
local Items = require(Modules:WaitForChild("Items"));
local SettingsModule = require(Modules:WaitForChild("SettingsModule"));
local u1 = require(Modules:WaitForChild("AssetContainer"))();
local u2 = {
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
    Enum.KeyCode.Five,
    Enum.KeyCode.Six
};
local Main = PlayerGui:WaitForChild("Main");
local Toolbar = Main:WaitForChild("Toolbar");
local Codelock = Main:WaitForChild("Codelock");
local Fetch = InventoryController:WaitForChild("Fetch");
local EquipWires = ElectricityController:WaitForChild("EquipWires");
local PreferredInputController = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PreferredInputController");
local u3 = {};
local u4 = false;
local u5 = 0;

local function _() -- Line: 72
    -- upvalues: Humanoid (copy), CameraController (copy)
    local v6 = Humanoid and Humanoid.Parent;

    if v6 then
        if Humanoid.Health > 0 then
            v6 = not CameraController:GetAttribute("ViewmodelCFrame");
        else
            v6 = false;
        end;
    end;

    return v6;
end;

local function _(p7) -- Line: 76
    -- upvalues: Toolbar (copy), InventoryController (copy)
    local v8 = script:GetAttribute("Equipped");
    local v9 = Toolbar:FindFirstChild("Slot" .. p7);

    if not v9 then
        return;
    end;

    v9.BackgroundColor3 = InventoryController:GetAttribute((v8 == p7 and "Selected" or "Default") .. "SlotColor");
end;

local function _(p10) -- Line: 84
    -- upvalues: Fetch (copy), Items (copy)
    local v11 = Fetch:Invoke().Toolbar[p10];
    local v12;

    if v11 then
        if v11 == 0 or v11.Amount <= 0 then
            v12 = false;
        else
            v12 = Items[v11.ID];
        end;
    else
        v12 = v11;
    end;

    return v11, v12;
end;

local function u22(p13) -- Line: 92
    -- upvalues: Toolbar (copy), InventoryController (copy), Fetch (copy), Items (copy), ViewmodelController (copy), BuildController (copy), EquipWires (copy)
    local v14 = script:GetAttribute("Equipped");
    script:SetAttribute("Equipped", p13);

    if v14 ~= p13 then
        local v15 = script:GetAttribute("Equipped");
        local v16 = Toolbar:FindFirstChild("Slot" .. v14);

        if v16 then
            v16.BackgroundColor3 = InventoryController:GetAttribute((v15 == v14 and "Selected" or "Default") .. "SlotColor");
        end;
    end;

    local v17 = script:GetAttribute("Equipped");
    local v18 = Toolbar:FindFirstChild("Slot" .. p13);

    if v18 then
        v18.BackgroundColor3 = InventoryController:GetAttribute((v17 == p13 and "Selected" or "Default") .. "SlotColor");
    end;

    local v19 = Fetch:Invoke().Toolbar[p13];
    local v20;

    if v19 then
        if v19 == 0 or v19.Amount <= 0 then
            v20 = false;
        else
            v20 = Items[v19.ID];
        end;
    else
        v20 = v19;
    end;

    local v21 = (v20 and (v20.Type ~= "Gun" and (v20.Type ~= "Tool" and v20.Type ~= "Bench")) or v20 and (v20.MaxDurability and v19.Durability <= 0)) and 0 or p13;
    ViewmodelController.EquipVM:Fire(v21);
    BuildController.EquipBench:Fire(v21);

    if v21 == 0 then
        v19 = false;
    elseif v19 then
        if typeof(v19) == "number" then
            v19 = false;
        else
            v19 = v19.ID == 326;
        end;
    end;

    EquipWires:Fire(v19);

    return true;
end;

local function u32(p23, p24, p25) -- Line: 108
    -- upvalues: Fetch (copy), Items (copy), InventoryController (copy), u22 (copy), u5 (ref), u1 (copy), LocalPlayer (copy)
    local v26 = Fetch:Invoke().Toolbar[p23];
    local v27;

    if v26 then
        if v26 == 0 or v26.Amount <= 0 then
            v27 = false;
        else
            v27 = Items[v26.ID];
        end;
    else
        v27 = v26;
    end;

    if p23 ~= 0 and (type(v27) == "table" and (v27.Type:find("Armor") and not v27.Type:find("Consumable"))) then
        InventoryController.EquipArmor:Fire(p23);
    end;

    if not (v27 and v27.Type:find("Consumable")) then
        if type(v26) == "table" and v26.Amount <= 0 then
            return;
        end;

        local v28 = script:GetAttribute("Equipped") == p23 and 0 or p23;

        if v28 ~= 0 and LocalPlayer:GetAttribute("SafeZone") then
            local v29 = Fetch:Invoke().Toolbar[v28];

            if v29 then
                if v29 == 0 or v29.Amount <= 0 then
                    v29 = false;
                else
                    v29 = Items[v29.ID];
                end;
            end;

            if type(v29) == "table" and v29.Type == "Gun" then
                return;
            end;
        end;

        local v30 = u22(v28);

        if v30 then
            u1("Fire", "fD\21[\243Hg\20\166i%\2156N#\225\1\228\150\253", "\1\234\217\168\252\254\20,E\28\230\15\240\130>\29\157Q\26\244", v28);

            return v30;
        end;

        return;
    end;

    if p25 then
        u22(p23);

        return true;
    end;

    if p24 then
        return;
    end;

    local v31 = tick();

    if v31 - u5 < 0.2 then
        return;
    end;

    u5 = v31;
    u1("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "\245A\150x@\231Er*\173\173b\191\178\1\138|\178\150\187", "Toolbar", p23);
end;

local function u37(p33) -- Line: 167
    -- upvalues: u3 (copy), u4 (ref)
    if #u3 > 3 then
        return;
    end;

    table.insert(u3, p33);

    if not u4 then
        u4 = true;
        local v34 = os.clock();

        while #u3 > 0 do
            local v35 = os.clock();

            if v35 - v34 >= 0.1 then
                while v35 - v34 >= 0.1 do
                    v35 = v35 - 0.1;
                    local v36 = u3[1];

                    if not v36 then
                        break;
                    end;

                    v36();
                    table.remove(u3, 1);

                    if #u3 <= 0 then
                        u4 = false;
                        break;
                    end;
                end;

                v34 = os.clock();
            end;

            task.wait();
        end;
    end;
end;

local function u43(p38) -- Line: 145
    -- upvalues: u2 (copy), PreferredInputController (copy), u32 (copy)
    local v39 = script:GetAttribute("Equipped");
    local v40 = v39 + p38;
    local v41;

    if v40 < 0 then
        v41 = #u2;
    else
        v41 = #u2 < v40 and 0 or v40;
    end;

    local v42 = PreferredInputController and PreferredInputController:GetAttribute("PreferredInput") == "Gamepad";

    return v41 == v39 and true or u32(v41, true, v42);
end;

while Fetch and Fetch.Parent do
    local v44 = Fetch:Invoke();

    if type(v44) == "table" and type(v44.Toolbar) == "table" then
        UserInputService.InputBegan:Connect(function(p45) -- Line: 206
            -- upvalues: SettingsModule (copy), UserInputService (copy), Codelock (copy), Humanoid (copy), CameraController (copy), u2 (copy), InteractController (copy), u37 (copy), u32 (copy), u43 (copy), Fetch (copy), Items (copy), u5 (ref), u1 (copy)
            if SettingsModule.MainMenuOpen() then
                return;
            end;

            local UserInputType = p45.UserInputType;

            if not (UserInputService:GetFocusedTextBox() or (Codelock.Visible or Humanoid:GetAttribute("Downed"))) then
                local v46 = Humanoid and Humanoid.Parent;

                if v46 then
                    if Humanoid.Health > 0 then
                        v46 = not CameraController:GetAttribute("ViewmodelCFrame");
                    else
                        v46 = false;
                    end;
                end;

                if v46 then
                    if UserInputType == Enum.UserInputType.Keyboard then
                        local KeyCode = p45.KeyCode;

                        for i, v in pairs(u2) do
                            if v == KeyCode then
                                if i <= 2 and InteractController:GetAttribute("Dialog") then
                                    return;
                                end;

                                u37(function() -- Line: 216
                                    -- upvalues: CameraController (ref), u32 (ref), i (copy)
                                    if CameraController:GetAttribute("ViewmodelCFrame") then
                                        return;
                                    end;

                                    u32(i);
                                end);

                                return;
                            end;
                        end;

                        if KeyCode.Name == SettingsModule.GetSetting("Controls", "Toolbar Left") then
                            u43(-1);

                            return;
                        end;

                        if KeyCode.Name == SettingsModule.GetSetting("Controls", "Toolbar Right") then
                            u43(1);
                        end;
                    elseif UserInputType == Enum.UserInputType.Gamepad1 then
                        local KeyCode = p45.KeyCode;

                        if KeyCode.Name == "ButtonR2" then
                            local v47 = script:GetAttribute("Equipped");
                            local v48 = Fetch:Invoke().Toolbar[v47];

                            if v48 then
                                if v48 == 0 or v48.Amount <= 0 then
                                    v48 = false;
                                else
                                    v48 = Items[v48.ID];
                                end;
                            end;

                            if v48 and v48.Type:find("Consumable") then
                                local v49 = tick();

                                if v49 - u5 < 0.2 then
                                    return;
                                end;

                                u5 = v49;
                                u1("Fire", "\134n&\2\225A|[\0191\25\27m\1\128O>p\183\145", "\245A\150x@\231Er*\173\173b\191\178\1\138|\178\150\187", "Toolbar", v47);
                            end;
                        else
                            if KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Toolbar Left") then
                                u43(-1);

                                return;
                            end;

                            if KeyCode.Name == SettingsModule.GetSetting("Gamepad", "Toolbar Right") then
                                u43(1);
                            end;
                        end;
                    end;
                end;
            end;
        end);
        UserInputService.InputChanged:Connect(function(p50, p51) -- Line: 247
            -- upvalues: SettingsModule (copy), UserInputService (copy), Codelock (copy), Humanoid (copy), LocalPlayer (copy), CameraController (copy), u37 (copy), u43 (copy)
            if SettingsModule.MainMenuOpen() then
                return;
            end;

            local UserInputType = p50.UserInputType;
            local v52 = UserInputService:GetFocusedTextBox();

            if UserInputType == Enum.UserInputType.MouseWheel and not (v52 or (p51 or (Codelock.Visible or (Humanoid:GetAttribute("Downed") or LocalPlayer:GetAttribute("SafeZone"))))) then
                local v53 = Humanoid and Humanoid.Parent;

                if v53 then
                    if Humanoid.Health > 0 then
                        v53 = not CameraController:GetAttribute("ViewmodelCFrame");
                    else
                        v53 = false;
                    end;
                end;

                if v53 then
                    local Z = p50.Position.Z;

                    if Z >= 0.5 and SettingsModule.GetSetting("Controls", "Toolbar Right") ~= "M.WheelDown" then
                        return;
                    end;

                    if Z <= -0.5 and SettingsModule.GetSetting("Controls", "Toolbar Left") ~= "M.WheelUp" then
                        return;
                    end;

                    if math.abs(Z) < 0.5 then
                        return;
                    end;

                    u37(function() -- Line: 256
                        -- upvalues: u43 (ref), Z (copy)
                        u43(Z > 0 and -1 or 1);
                    end);
                end;
            end;
        end);
        u1("Setup", "fD\21[\243Hg\20\166i%\2156N#\225\1\228\150\253", "\1\234\217\168\252\254\20,E\28\230\15\240\130>\29\157Q\26\244", u22);

        if Values.ServerType.Value == "GunGame" then
            u32(1);
        end;

        return;
    end;

    task.wait();
end;