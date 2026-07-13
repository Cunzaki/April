-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local Players_1 = game:GetService("Players");
local ReplicatedStorage_1 = game:GetService("ReplicatedStorage");
local UserInputService_1 = game:GetService("UserInputService");
local TweenService_upv_1 = game:GetService("TweenService");
local SoundService_1 = game:GetService("SoundService");
local LocalPlayer_1 = Players_1.LocalPlayer;
local Character_upv_1 = LocalPlayer_1.Character;
local HumanoidRootPart_upv_1 = Character_upv_1:WaitForChild("HumanoidRootPart");
local RootRigAttachment_upv_1 = HumanoidRootPart_upv_1:WaitForChild("RootRigAttachment");
local Bases_upv_1 = workspace:WaitForChild("Bases");
local Value_upv_1 = ReplicatedStorage_1:WaitForChild("Values"):WaitForChild("ElectricBenchClientUpdateSeconds").Value;
local ClientSignals_1 = ReplicatedStorage_1:WaitForChild("ClientSignals");
local UpdateBenchConnections_1 = ClientSignals_1:WaitForChild("UpdateBenchConnections");
local UpdateBenchPower_1 = ClientSignals_1:WaitForChild("UpdateBenchPower");
local TemplateWire_upv_1 = script:WaitForChild("TemplateWire");
local VFX_upv_1 = workspace:WaitForChild("VFX");
local Wires_upv_1 = VFX_upv_1:WaitForChild("Wires");
local WireCutters_upv_1 = SoundService_1:WaitForChild("WireCutters");
local tbl_upv_1 = {};
tbl_upv_1.Green = ColorSequence.new(Color3.fromRGB(63, 194, 46));
tbl_upv_1.Red = ColorSequence.new(Color3.fromRGB(194, 40, 50));
tbl_upv_1.Black = ColorSequence.new(Color3.fromRGB(40, 40, 40));
local Modules_1 = ReplicatedStorage_1:WaitForChild("Modules");
local Items_upv_1 = require(Modules_1:WaitForChild("Items"));
local BenchInfo_1 = require(Modules_1:WaitForChild("BenchInfo"));
local NumberUtil_upv_1 = require(Modules_1:WaitForChild("NumberUtil"));
local RaycastUtil_upv_1 = require(Modules_1:WaitForChild("RaycastUtil"));
local ActiveBenchModule_upv_1 = require(Modules_1:WaitForChild("ActiveBenchModule"));
local ViewmodelController_1 = Character_upv_1:WaitForChild("ViewmodelController");
local u1 = require(Modules_1:WaitForChild("AssetContainer"))();
local PlayerGui_1 = LocalPlayer_1:WaitForChild("PlayerGui");
local WireCutterInfo_upv_1 = PlayerGui_1:WaitForChild("Main"):WaitForChild("WireCutterInfo");
local ConnectionsBillboardGui_upv_1 = PlayerGui_1:WaitForChild("ConnectionsBillboardGui");
local ButtonFrame_upv_1 = ConnectionsBillboardGui_upv_1:WaitForChild("ButtonFrame");
local OpenBench_1 = script:WaitForChild("OpenBench");
local EquipWires_1 = script:WaitForChild("EquipWires");
local PlayVMAnimation_upv_1 = ViewmodelController_1:WaitForChild("PlayVMAnimation");
local u2 = nil;
local u3 = nil;
local u4 = nil;
local u5 = nil;
local u6 = nil;
local tbl_2 = {};
local u7 = os.clock() - Value_upv_1;
local tbl_3 = {};
local tbl_upv_4 = {};
shared.CachedElectricalBenchNames = {};
shared.CachedConnections = {};
local u8 = nil;
local tbl_upv_5, tbl_upv_6 = tbl_3, tbl_2;
local u9 = nil;
for key_1, value_upv_1 in BenchInfo_1 do
    u9 = value_upv_1.TypeArguments and (value_upv_1.TypeArguments());
    if (value_upv_1.Type == "Electricity" or value_upv_1.ElectricityType) then
        shared.CachedElectricalBenchNames[key_1] = true;
        continue;
    end;
    if (not (u9)) then
        continue;
    end;
    if (u9.PowerIn ~= nil) then
        shared.CachedElectricalBenchNames[key_1] = true;
    end;
end;
local function u10(a1)
    --[[
      line: 175
      upvalues:
        Wires_upv_1 (copy, index: 1)
    ]]
    local value_2 = nil;
    for _, value_2 in Wires_upv_1:GetChildren() do
        value_2.Enabled = a1;
        if (value_2:FindFirstChild("WireDetail")) then
            value_2.WireDetail.Enabled = a1;
        end;
    end;
end;
u9 = function()
    --[[
      line: 205
      upvalues:
        Character_upv_1 (copy, index: 1)
        HumanoidRootPart_upv_1 (copy, index: 2)
        tbl_upv_5 (ref,  index: 3)
        Bases_upv_1 (copy, index: 4)
        NumberUtil_upv_1 (copy, index: 5)
    ]]
    if (not Character_upv_1) then
        return;
    end;
    if (HumanoidRootPart_upv_1) then
        tbl_upv_5 = {};
        local _ = nil;
        local v1 = nil;
        for v2, value_3 in pairs(Bases_upv_1:GetChildren()) do
            _ = nil;
            for v3, value_4 in value_3:GetChildren() do
                if (not (shared.CachedElectricalBenchNames[value_4.Name])) then
                    continue;
                end;
                for v4, value_5 in pairs(value_4:GetChildren()) do
                    if (not (value_5.Main) or not (value_5.Main.Position)) then
                        continue;
                    end;
                    if (NumberUtil_upv_1:IsWithin(value_5.Main.Position, HumanoidRootPart_upv_1.Position, 70)) then
                        table.insert(tbl_upv_5, value_5);
                    end;
                end;
            end;
        end;
    end;
end;
local function u11()
    --[[
      line: 318
      upvalues:
        tbl_upv_6 (ref, index: 1)
    ]]
    for _, value_6 in pairs(tbl_upv_6) do
        value_6:Disconnect();
    end;
    tbl_upv_6 = {};
end;
local function value_upv_1(a1)
    --[[
      line: 190
      upvalues:
        Items_upv_1 (copy, index: 1)
        WireCutterInfo_upv_1 (copy, index: 2)
    ]]
    local _ = a1 and (a1:GetAttribute("ID"));
    local v5 = a1 and (a1:GetAttribute("Skin"));
    local v1 = a1 and (Items_upv_1[a1]);
    local v2 = v1;
    local v3 = (v2 and (v1.Image[a1 or "Default"])) ~= nil;
    local TopLabel_1 = WireCutterInfo_upv_1.TopLabel;
    local v4;
    if (v3) then
        v4 = "CREATING NEW CONNECTION FROM";
    else
        v4 = "[MOUSE1] ON ELECTRICITY BENCH TO SHOW CONNECTIONS";
    end;
    TopLabel_1.Text = v4;
    local ImageLabel_1 = WireCutterInfo_upv_1.ImageLabel;
    v4 = v2 and v2 or "";
    ImageLabel_1.Image = v4;
    WireCutterInfo_upv_1.ImageLabel.Visible = v3;
    WireCutterInfo_upv_1.ItemLabel.Text = (a1 and (a1.Name)) or "";
    WireCutterInfo_upv_1.ItemLabel.Visible = v3;
    WireCutterInfo_upv_1.BottomLabel.Visible = v3;
    WireCutterInfo_upv_1.Visible = true;
end;
local function u12()
    --[[
      line: 325
      upvalues:
        tbl_upv_6 (ref,  index: 1)
        u2 (ref,  index: 2)
        u5 (ref,  index: 3)
        tbl_upv_1 (copy, index: 4)
        u3 (ref,  index: 5)
        u4 (ref,  index: 6)
        u1 (copy, index: 7)
        value_upv_1 (copy, index: 8)
        u11 (copy, index: 9)
        ButtonFrame_upv_1 (copy, index: 10)
        Items_upv_1 (copy, index: 11)
    ]]
    local function v5(a1)
        --[[
          line: 326
          upvalues:
            tbl_upv_6 (ref,  index: 1)
            u2 (ref,  index: 2)
            u5 (ref,  index: 3)
            tbl_upv_1 (copy, index: 4)
            u3 (ref,  index: 5)
            u4 (ref,  index: 6)
            u1 (copy, index: 7)
            value_upv_1 (copy, index: 8)
        ]]
        table.insert(
            tbl_upv_6,
            a1.MouseEnter:Connect(
                function()
                    --[[
                      line: 328
                      upvalues:
                        a1 (copy, index: 1)
                        u2 (ref,  index: 2)
                        u5 (ref,  index: 3)
                        tbl_upv_1 (copy, index: 4)
                    ]]
                    a1:FindFirstChild("Hover").Enabled = true;
                    local v6 = a1.Name:find("In");
                    local num_1 = tonumber(string.sub(a1.Name, -1));
                    local v7 = shared.CachedConnections[u2];
                    if (v7 and (not v6 or (v7.PowerIn)) and ((v6) or (v7.PowerOut))) then
                        local v8 = nil;
                        if (v6) then
                            v8 = v7.PowerIn[num_1];
                            local v9 = nil;
                            if (v8 ~= 0) then
                                v9 = shared.CachedConnections[v8];
                                if (v9) then
                                    local v10;
                                    v10 = nil;
                                    for key_2, value_7 in v9.PowerOut do
                                        if (value_7 == u2) then
                                            v10 = key_2;
                                            break;
                                        end;
                                    end;
                                    if (not v10) then
                                        return;
                                    end;
                                    local v11 = v9.Wires and (v9.Wires[v10]);
                                    if (v10 and v11 and v11 ~= 0) then
                                        u5 = v11;
                                        u5.Color = tbl_upv_1.Red;
                                    end;
                                end;
                            end;
                        else
                            local v12 = v7.Wires and (v7.Wires[num_1]);
                            if (not v12 or v12 == 0) then
                                return;
                            end;
                            u5 = v12;
                            u5.Color = tbl_upv_1.Green;
                        end;
                    end;
                end
            )
        );
        table.insert(
            tbl_upv_6,
            a1.MouseLeave:Connect(
                function()
                    --[[
                      line: 362
                      upvalues:
                        a1 (copy, index: 1)
                        u5 (ref,  index: 2)
                        tbl_upv_1 (copy, index: 3)
                    ]]
                    a1:FindFirstChild("Hover").Enabled = false;
                    if (not u5) then
                        return;
                    end;
                    u5.Color = tbl_upv_1.Black;
                    u5 = nil;
                end
            )
        );
        table.insert(
            tbl_upv_6,
            a1.MouseButton1Click:Connect(
                function()
                    --[[
                      line: 371
                      upvalues:
                        u3 (ref,  index: 1)
                        a1 (copy, index: 2)
                        u4 (ref,  index: 3)
                        u2 (ref,  index: 4)
                        u1 (copy, index: 5)
                        value_upv_1 (copy, index: 6)
                    ]]
                    u3 = tonumber(string.sub(a1.Name, -1));
                    local v13 = string.sub(a1.Name, 1, -2);
                    u4 = v13;
                    local v14;
                    v14 = nil;
                    local v15 = shared.CachedConnections[u2];
                    if (v15 and v15[v13] and v15[v13][u3] ~= 0) then
                        v14 = true;
                    end;
                    if (v14) then
                        u1("Fire", "\016\168\031#\163\001W\225^\130b\156a\179\208\211\023\185\2266", "\142H\187\n}UX\242}\152O[\161\206\030\154\001\139\243D", u2, v15[v13][u3], u3, v13, true);
                        u3 = nil;
                        u4 = nil;
                        script:SetAttribute("Placing", false);
                    else
                        script:SetAttribute("Placing", true);
                        value_upv_1(u2);
                    end;
                end
            )
        );
    end;
    u11();
    local v16 = nil;
    local v17 = nil;
    local num_2 = nil;
    local v18 = nil;
    local v19 = nil;
    local v20 = nil;
    for _, value_8 in ButtonFrame_upv_1:GetChildren() do
        v17 = nil;
        num_2 = nil;
        v18 = nil;
        for v25, value_9 in value_8:GetChildren() do
            v20 = value_9:IsA("ImageButton");
            if (not (v20) or not (shared.CachedConnections[u2])) then
                continue;
            end;
            v17 = ((value_9.Name:find("PowerIn")) and "PowerIn") or "PowerOut";
            num_2 = tonumber(string.sub(value_9.Name, -1));
            v18 = shared.CachedConnections[u2][v17];
            v19 = v18 and (#v18);
            if (not (v18)) then
                value_9.Visible = false;
                continue;
            end;
            if (v18) then
                if (v19 < num_2) then
                    value_9.Visible = false;
                    continue;
                end;
                value_9.Visible = true;
                if (v18[num_2] == 0) then
                    value_9.ImageLabel.Visible = v18[num_2] ~= 0;
                    value_9.TextLabel.Visible = v18[num_2] == 0;
                    v5(value_9);
                    continue;
                end;
                local v21 = v18[num_2];
                local v22 = v21:GetAttribute("ID");
                local v23 = v21:GetAttribute("Skin");
                local v24 = v22 and (Items_upv_1[v22]);
                v16 = v24;
                if (not v16 or not v24.Image[v23 or "Default"]) then
                    v16 = v22.Image;
                end;
                if (not (v16)) then
                    warn("[ElectricityController] - Image not found for connection slot, bench found name : " .. v21.Name);
                end;
                value_9.ImageLabel.Image = v16;
                value_9.ImageLabel.Visible = v18[num_2] ~= 0;
                value_9.TextLabel.Visible = v18[num_2] == 0;
                v5(value_9);
            else
                value_9.Visible = true;
                if (v18[num_2] == 0) then
                    value_9.ImageLabel.Visible = v18[num_2] ~= 0;
                    value_9.TextLabel.Visible = v18[num_2] == 0;
                    v5(value_9);
                    continue;
                end;
                local v21 = v18[num_2];
                local v22 = v21:GetAttribute("ID");
                local v23 = v21:GetAttribute("Skin");
                local v24 = v22 and (Items_upv_1[v22]);
                v16 = v24;
                if (not v16 or not v24.Image[v23 or "Default"]) then
                    v16 = v22.Image;
                end;
                if (not (v16)) then
                    warn("[ElectricityController] - Image not found for connection slot, bench found name : " .. v21.Name);
                end;
                value_9.ImageLabel.Image = v16;
                value_9.ImageLabel.Visible = v18[num_2] ~= 0;
                value_9.TextLabel.Visible = v18[num_2] == 0;
                v5(value_9);
            end;
        end;
    end;
end;
local function u13(a1)
    --[[
      line: 224
      upvalues:
        WireCutterInfo_upv_1 (copy, index: 1)
        TweenService_upv_1 (copy, index: 2)
    ]]
    local tbl_7 = {};
    local v25 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0);
    local v26 = WireCutterInfo_upv_1.Message:Clone();
    v26.Parent = WireCutterInfo_upv_1;
    v26.Text = a1;
    TweenService_upv_1:Create(v26, v25, tbl_7):Play();
    task.wait(4);
    v26:Destroy();
end;
OpenBench_1.Event:Connect(
    function(a1)
        --[[
          line: 447
          upvalues:
            u2 (ref,  index: 1)
            HumanoidRootPart_upv_1 (copy, index: 2)
            RaycastUtil_upv_1 (copy, index: 3)
            ActiveBenchModule_upv_1 (copy, index: 4)
            u13 (copy, index: 5)
            u3 (ref,  index: 6)
            NumberUtil_upv_1 (copy, index: 7)
            u1 (copy, index: 8)
            u4 (ref,  index: 9)
            ConnectionsBillboardGui_upv_1 (copy, index: 10)
            value_upv_1 (copy, index: 11)
            u12 (copy, index: 12)
        ]]
        if (not a1.Main) then
            return;
        end;
        if (u2 ~= a1) then
            local v27 = nil;
            if (HumanoidRootPart_upv_1) then
                v27 = RaycastUtil_upv_1:GetBaseCabinetUnder(HumanoidRootPart_upv_1.Position);
                local v28 = false;
                local v29 = nil;
                if (v27) then
                    v29 = ActiveBenchModule_upv_1.GetClientInfo(v27);
                    local v30 = false;
                    if (type(v29) == "table") then
                        v30 = not v29.Access;
                    end;
                    v28 = v30;
                end;
                if (v28) then
                    u13("You are building blocked");
                else
                    if (u2 and u3) then
                        if (NumberUtil_upv_1:IsWithin(HumanoidRootPart_upv_1.Position, a1.Main.Position, 40)) then
                            u1("Fire", "\016\168\031#\163\001W\225^\130b\156a\179\208\211\023\185\2266", "\142H\187\n}UX\242}\152O[\161\206\030\154\001\139\243D", u2, a1, u3, u4);
                            ConnectionsBillboardGui_upv_1.Adornee = nil;
                            u2 = nil;
                            u3 = nil;
                            u4 = nil;
                            script:SetAttribute("Placing", false);
                            value_upv_1();
                        end;
                        return;
                    end;
                    u2 = a1;
                    if (not u2) then
                        return;
                    end;
                    ConnectionsBillboardGui_upv_1.Adornee = u2:FindFirstChild("Main");
                    u12();
                end;
            end;
        end;
    end
);
local function u14(a1, a2)
    --[[
      line: 131
      upvalues:
        TemplateWire_upv_1 (copy, index: 1)
        Wires_upv_1 (copy, index: 2)
    ]]
    local tbl_8 = {};
    for key_3, value_10 in a2 do
        if (value_10 == 0 or not (a1.Main) or not (value_10.Main)) then
            tbl_8[key_3] = 0;
            continue;
        end;
        if (not (a1.Main:FindFirstChild("WireAttachment"))) then
            local v31 = Instance.new("Attachment");
            v31.Name = "WireAttachment";
            v31.Parent = a1.Main;
        end;
        if (not (value_10.Main:FindFirstChild("WireAttachment"))) then
            local v32 = Instance.new("Attachment");
            v32.Name = "WireAttachment";
            v32.Parent = value_10.Main;
        end;
        local v33 = TemplateWire_upv_1:Clone();
        tbl_8[key_3] = v33;
        v33.Attachment0 = a1.Main.WireAttachment;
        v33.Attachment1 = value_10.Main.WireAttachment;
        v33.Enabled = script:GetAttribute("WiresEquipped");
        local WireDetail_1 = v33:FindFirstChild("WireDetail");
        WireDetail_1.Attachment0 = a1.Main.WireAttachment;
        WireDetail_1.Attachment1 = value_10.Main.WireAttachment;
        WireDetail_1.Enabled = true;
        v33.Parent = Wires_upv_1;
    end;
    return tbl_8;
end;
EquipWires_1.Event:Connect(
    function(a1)
        --[[
          line: 473
          upvalues:
            value_upv_1 (copy, index: 1)
            u8 (ref,  index: 2)
            u7 (ref,  index: 3)
            Value_upv_1 (copy, index: 4)
            u9 (copy, index: 5)
            tbl_upv_5 (ref,  index: 6)
            u1 (copy, index: 7)
            u14 (copy, index: 8)
            Wires_upv_1 (copy, index: 9)
            WireCutterInfo_upv_1 (copy, index: 10)
            ConnectionsBillboardGui_upv_1 (copy, index: 11)
            u2 (ref,  index: 12)
            u3 (ref,  index: 13)
        ]]
        local v34 = nil;
        if (a1) then
            v34 = script:GetAttribute("WiresEquipped");
            if (not (v34)) then
                value_upv_1();
                if (u8) then
                    task.cancel(u8);
                end;
                u8 = task.defer(
                    function()
                        --[[
                          line: 240
                          upvalues:
                            u7 (ref,  index: 1)
                            Value_upv_1 (copy, index: 2)
                            u9 (copy, index: 3)
                            tbl_upv_5 (ref,  index: 4)
                            u1 (copy, index: 5)
                            u14 (copy, index: 6)
                            Wires_upv_1 (copy, index: 7)
                        ]]
                        repeat
                            task.wait(0.25);
                        until (os.clock() - u7 > Value_upv_1);
                        u7 = os.clock();
                        u9();
                        if (#tbl_upv_5 ~= 0) then
                            local tbl_9 = {};
                            local tbl_10 = {};
                            local v35 = nil;
                            local v36 = nil;
                            local v37 = nil;
                            for _, value_11 in u1("Fire", "\016\168\031#\163\001W\225^\130b\156a\179\208\211\023\185\2266", "<\018\187]\005X\199\020\025\224V\147\005\147\001:\230D!\247", unpack(tbl_upv_5, 1, 300)) do
                                v36 = value_11[1];
                                tbl_9[v36] = {PowerIn = value_11[2], PowerOut = value_11[3]};
                                v37 = shared.CachedConnections[v36];
                                if (v37 and v37.Wires) then
                                    if (v37.PowerOut) then
                                        v35 = true;
                                        if (v37.PowerOut) then
                                            for key_4, value_12 in v37.PowerOut do
                                                if (tbl_9[v36].PowerOut[key_4] ~= value_12) then
                                                    v35 = false;
                                                    break;
                                                end;
                                            end;
                                            if (v35 and v37.Wires) then
                                                tbl_9[v36].Wires = v37.Wires;
                                            else
                                                tbl_9[v36].Wires = u14(v36, tbl_9[v36].PowerOut);
                                            end;
                                            local v38;
                                            if (not (tbl_9[v36].Wires)) then
                                                continue;
                                            end;
                                            for v39, value_13 in tbl_9[v36].Wires do
                                                if (value_13 ~= 0) then
                                                    tbl_10[value_13] = true;
                                                end;
                                            end;
                                        elseif (v35) then
                                            if (v37.Wires) then
                                                tbl_9[v36].Wires = v37.Wires;
                                            else
                                                tbl_9[v36].Wires = u14(v36, tbl_9[v36].PowerOut);
                                            end;
                                        else
                                            tbl_9[v36].Wires = u14(v36, tbl_9[v36].PowerOut);
                                            local v38;
                                            if (not (tbl_9[v36].Wires)) then
                                                continue;
                                            end;
                                            for v39, value_13 in tbl_9[v36].Wires do
                                                if (value_13 ~= 0) then
                                                    tbl_10[value_13] = true;
                                                end;
                                            end;
                                        end;
                                    else
                                        if (tbl_9[v36].PowerOut) then
                                            tbl_9[v36].Wires = u14(v36, tbl_9[v36].PowerOut);
                                        end;
                                        local v38;
                                        if (not (tbl_9[v36].Wires)) then
                                            continue;
                                        end;
                                        for v39, value_13 in tbl_9[v36].Wires do
                                            if (value_13 ~= 0) then
                                                tbl_10[value_13] = true;
                                            end;
                                        end;
                                    end;
                                elseif (tbl_9[v36].PowerOut) then
                                    tbl_9[v36].Wires = u14(v36, tbl_9[v36].PowerOut);
                                end;
                            end;
                            shared.CachedConnections = tbl_9;
                            for _, value_14 in Wires_upv_1:GetChildren() do
                                if (not (tbl_10[value_14])) then
                                    value_14:Destroy();
                                end;
                            end;
                        else
                            shared.CachedConnections = {};
                        end;
                    end
                );
            end;
        end;
        script:SetAttribute("WiresEquipped", a1);
        WireCutterInfo_upv_1.Visible = a1;
        if ((a1)) then
            return;
        end;
        if (u8) then
            task.cancel(u8);
        end;
        ConnectionsBillboardGui_upv_1.Adornee = nil;
        u2 = nil;
        u3 = nil;
    end
);
UserInputService_1.InputBegan:Connect(
    function(a1)
        --[[
          line: 488
          upvalues:
            u2 (ref,  index: 1)
            u3 (ref,  index: 2)
            ConnectionsBillboardGui_upv_1 (copy, index: 3)
            u4 (ref,  index: 4)
            value_upv_1 (copy, index: 5)
        ]]
        if (a1.UserInputType == Enum.UserInputType.MouseButton2 and ((u2) or (u3))) then
            ConnectionsBillboardGui_upv_1.Adornee = nil;
            u2 = nil;
            u3 = nil;
            u4 = nil;
            script:SetAttribute("Placing", false);
            value_upv_1();
        end;
    end
);
UpdateBenchConnections_1.OnClientEvent:Connect(
    function(a1, a2)
        --[[
          line: 501
          upvalues:
            HumanoidRootPart_upv_1 (copy, index: 1)
            u13 (copy, index: 2)
            NumberUtil_upv_1 (copy, index: 3)
            u14 (copy, index: 4)
            u2 (ref,  index: 5)
            ConnectionsBillboardGui_upv_1 (copy, index: 6)
            u12 (copy, index: 7)
        ]]
        if (not a1 or not HumanoidRootPart_upv_1) then
            return;
        end;
        if (typeof(a1) == "string") then
            u13(a1);
        elseif (typeof(a1) ~= "table") then
            if (a1:FindFirstChild("Main")) then
                local v38 = nil;
                if (NumberUtil_upv_1:IsWithin(a1.Main.Position, HumanoidRootPart_upv_1.Position, 40)) then
                    v38 = shared.CachedConnections[a1];
                    local v39 = nil;
                    if (v38) then
                        v39 = v38.Wires;
                        if (v39) then
                            for _, value_15 in v39 do
                                if (value_15 ~= 0) then
                                    value_15:Destroy();
                                end;
                            end;
                        end;
                        a2.Wires = a2.PowerOut and u14(a1, a2.PowerOut);
                        a2.PowerThroughput = v38.PowerThroughput;
                        shared.CachedConnections[a1] = a2;
                    end;
                    if (not u2) then
                        return;
                    end;
                    ConnectionsBillboardGui_upv_1.Adornee = u2:FindFirstChild("Main");
                    u12();
                end;
            end;
        end;
    end
);
UpdateBenchPower_1.OnClientEvent:Connect(
    function(a1, a2)
        --[[
          line: 534
        ]]
        for key_5, value_16 in a1 do
            if (shared.CachedConnections[value_16]) then
                shared.CachedConnections[value_16].PowerThroughput = a2[key_5];
            end;
        end;
    end
);
script:GetAttributeChangedSignal("WiresEquipped"):Connect(
    function()
        --[[
          line: 546
          upvalues:
            u10 (copy, index: 1)
        ]]
        u10((script:GetAttribute("WiresEquipped")));
    end
);
script:GetAttributeChangedSignal("Placing"):Connect(
    function()
        --[[
          line: 551
          upvalues:
            WireCutterInfo_upv_1 (copy, index: 1)
            PlayVMAnimation_upv_1 (copy, index: 2)
            WireCutters_upv_1 (copy, index: 3)
            u2 (ref,  index: 4)
            NumberUtil_upv_1 (copy, index: 5)
            HumanoidRootPart_upv_1 (copy, index: 6)
            u6 (ref,  index: 7)
            TemplateWire_upv_1 (copy, index: 8)
            RootRigAttachment_upv_1 (copy, index: 9)
            u4 (ref,  index: 10)
            tbl_upv_1 (copy, index: 11)
            VFX_upv_1 (copy, index: 12)
        ]]
        local v41 = script:GetAttribute("Placing");
        PlayVMAnimation_upv_1:Fire("WireCutter");
        WireCutters_upv_1:Play();
        if (v41) then
            while (script:GetAttribute("Placing")) do
                if (not (u2) or not (u2.Main)) then
                    script:SetAttribute("Placing", false);
                    continue;
                end;
                WireCutterInfo_upv_1.DistanceLabel.Visible = true;
                WireCutterInfo_upv_1.DistanceDetailLabel.Visible = true;
                WireCutterInfo_upv_1.DistanceFailLabel.Visible = true;
                local v42 = NumberUtil_upv_1:RoundNumber((HumanoidRootPart_upv_1.Position - u2.Main.Position).Magnitude, 1);
                local v43 = v42 <= 40;
                local DistanceLabel_1 = WireCutterInfo_upv_1.DistanceLabel;
                local DistanceLabel_2 = WireCutterInfo_upv_1.DistanceLabel;
                local v44;
                if (v43) then
                    v44 = "Green";
                else
                    v44 = "Red";
                end;
                DistanceLabel_1.TextColor3 = DistanceLabel_2:GetAttribute(v44);
                WireCutterInfo_upv_1.DistanceLabel.Text = tostring(v42);
                WireCutterInfo_upv_1.DistanceFailLabel.Visible = not v43;
                if (u6) then
                    u6.Enabled = v43;
                    task.wait();
                    continue;
                end;
                local v45 = TemplateWire_upv_1:Clone();
                if (not (u2.Main:FindFirstChild("WireAttachment"))) then
                    local v46 = Instance.new("Attachment");
                    v46.Name = "WireAttachment";
                    v46.Parent = u2.Main;
                end;
                v45.Attachment0 = u2.Main.WireAttachment;
                v45.Attachment1 = RootRigAttachment_upv_1;
                v45.Color = ((u4 == "PowerIn") and (tbl_upv_1.Red)) or (tbl_upv_1.Green);
                v45.Parent = VFX_upv_1;
                u6 = v45;
                u6.Enabled = v43;
                task.wait();
            end;
            WireCutterInfo_upv_1.DistanceLabel.Visible = false;
            WireCutterInfo_upv_1.DistanceDetailLabel.Visible = false;
            WireCutterInfo_upv_1.DistanceFailLabel.Visible = false;
            if (u6) then
                u6:Destroy();
            end;
            u6 = nil;
        else
            WireCutterInfo_upv_1.DistanceLabel.Visible = false;
            WireCutterInfo_upv_1.DistanceDetailLabel.Visible = false;
            WireCutterInfo_upv_1.DistanceFailLabel.Visible = false;
        end;
    end
);
task.wait(8);
local _ = nil;
local v1 = nil;
for v2, value_17 in pairs(Bases_upv_1:GetChildren()) do
    for v3, value_18 in value_17:GetChildren() do
        if (value_18.Name ~= "Windmill") then
            local v4, v5;
            if (value_18.Name ~= "Water Turbine") then
                continue;
            end;
        end;
        for v6, value_19 in pairs(value_18:GetChildren()) do
            if (not (value_19.Main) or not (value_19.Main.Position)) then
                continue;
            end;
            if (NumberUtil_upv_1:IsWithin(value_19.Main.Position, HumanoidRootPart_upv_1.Position, 70)) then
                (function(a1)
                    --[[
                      line: 107
                      upvalues:
                        tbl_upv_4 (copy, index: 1)
                    ]]
                    local v47 = nil;
                    if (a1) then
                        v47 = a1:FindFirstChild("AnimationController");
                        local SpinAnimation_1 = a1:FindFirstChild("SpinAnimation");
                        if (v47 and SpinAnimation_1) then
                            local v48 = nil;
                            if (not tbl_upv_4[a1]) then
                                tbl_upv_4[a1] = true;
                                local v49 = v47:LoadAnimation(SpinAnimation_1);
                                v48 = a1:FindFirstChild("WaterCollision");
                                local v50 = nil;
                                if (v48) then
                                    local Position_1 = v48.Position;
                                    v50 = workspace.Terrain:ReadVoxels(Region3.new(Position_1, Position_1):ExpandToGrid(4), 4);
                                    print(v50);
                                    if (v50 and v50[1] and v50[1][1] and v50[1][1][1] == Enum.Material.Water) then
                                        v49:Play();
                                        return;
                                    end;
                                else
                                    v49:Play();
                                end;
                            end;
                            return;
                        end;
                        warn("[ElectricityController] - No animation/controller found on windmill model ");
                    else
                        warn("[ElectricityController] - NewWindmill called without a windmill model");
                    end;
                end)(value_19, value_18.Name);
                task.wait();
            end;
        end;
        task.wait();
    end;
    task.wait();
end;