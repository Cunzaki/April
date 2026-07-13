-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local tbl_upv_1 = {};
tbl_upv_1.Categories = {"General", "Graphics", "Controls", "Sound", "Gamepad"};
local MainMenuOpen = {};
local tbl_2 = {};
local tbl_3 = {};
tbl_3.Range = {10, 100};
local tbl_4 = {};
local tbl_5 = {};
local tbl_6 = {};
local tbl_7 = {};
local tbl_8 = {{}, {Range = {0.001, 10}}, {Range = {0.001, 10}}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}};
local tbl_9 = {};
tbl_9.Range = {0, 1};
local tbl_10 = {};
tbl_10.Range = {0, 1};
MainMenuOpen = {};
local tbl_11 = {};
tbl_11.Range = {0.001, 3};
local tbl_12 = {};
tbl_12.Range = {0.001, 3};
local tbl_13 = {};
tbl_13.Range = {0.001, 0.9};
local v1 = nil;
tbl_upv_1.Config = {General = {{Range = {60, 80}}, {Range = {0.1, 1}}, {}, {}, {}, {}, {}}, Graphics = {MainMenuOpen, tbl_2, tbl_3, tbl_4, tbl_5, tbl_6, tbl_7, {Range = {0, 1}}, {}, {}, {}}, Controls = tbl_8, Sound = {{Range = {0, 1}}, tbl_9, tbl_10, {Range = {0, 1}}, {Range = {0, 1}}}, Gamepad = {v1, tbl_11, tbl_12, tbl_13, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}};
local Players_upv_1 = game:GetService("Players");
local tbl_upv_14 = {};
MainMenuOpen = nil;
tbl_upv_1.CreateDefaultSettings = function()
    --[[
      name: CreateDefaultSettings
      line: 593
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local tbl_15 = {};
    local v2 = nil;
    for _, value_1 in tbl_upv_1.Config do
        for v3, value_2 in value_1 do
            v2 = value_2.Id;
            if (v2) then
                tbl_15[v2] = value_2.DefaultValue;
            end;
        end;
    end;
    return tbl_15;
end;
tbl_upv_1.GetSettingFromId = function(a1)
    --[[
      name: GetSettingFromId
      line: 605
      upvalues:
        tbl_upv_14 (copy, index: 1)
        tbl_upv_1 (copy, index: 2)
    ]]
    local v3 = tbl_upv_14[a1];
    if (v3) then
        return v3;
    end;
    for _, value_3 in tbl_upv_1.Config do
        for v4, value_4 in value_3 do
            if (value_4.Id ~= a1) then
                continue;
            end;
            tbl_upv_14[a1] = value_4;
            return value_4;
        end;
    end;
end;
tbl_upv_1.CheckKeybind = function(a1, a2, a3)
    --[[
      name: CheckKeybind
      line: 619
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v4 = nil;
    if (a3) then
        v4 = tbl_upv_1.GetSettingFromId(a3);
        if (v4 and v4.IgnoreConflict) then
            return;
        end;
    end;
    local v5 = nil;
    for key_1, value_5 in a1 do
        if (key_1 == a3 or value_5 ~= a2) then
            continue;
        end;
        v5 = tbl_upv_1.GetSettingFromId(key_1);
        if (v5.IgnoreConflict) then
            continue;
        end;
        return v5;
    end;
end;
tbl_upv_1.ApplySettings = function(a1, a2)
    --[[
      name: ApplySettings
      line: 632
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    tbl_upv_1.Settings = a1;
    if (not a2) then
        return;
    end;
    tbl_upv_1.SkinPresets = a2;
end;
tbl_upv_1.GetSkinPreset = function(a1, a2, a3, a4)
    --[[
      name: GetSkinPreset
      line: 639
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v6 = (a4 or (tbl_upv_1.SkinPresets))[tostring(a2)];
    if (v6 and table.find(a1, ("%*/%*"):format(a3, v6))) then
        return v6;
    end;
    return "Default";
end;
tbl_upv_1.SetSkinPreset = function(a1, a2, a3)
    --[[
      name: SetSkinPreset
      line: 647
    ]]
    if (a1) then
        local str_1 = tostring(a2);
        local v7;
        if (a3 ~= "Default") then
            v7 = a3;
        else
            v7 = nil;
        end;
        a1[str_1] = v7;
    end;
end;
tbl_upv_1.GetSetting = function(a1, a2, a3)
    --[[
      name: GetSetting
      line: 652
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    for _, value_6 in tbl_upv_1.Config[a1] do
        if (value_6.Text == a2) then
            a3 = a3 or (tbl_upv_1.Settings);
            local v8 = nil;
            if (a3) then
                v8 = a3[value_6.Id];
                if (v8 ~= nil) then
                    return v8;
                end;
            end;
            return value_6.DefaultValue;
        end;
    end;
end;
tbl_upv_1.ResetSettings = function(a1, a2, a3)
    --[[
      name: ResetSettings
      line: 668
      upvalues:
        tbl_upv_1 (copy, index: 1)
    ]]
    local v9 = tbl_upv_1.Config[a2];
    if (v9) then
        local v10 = false;
        local v11 = nil;
        local v12 = nil;
        local v13 = nil;
        for _, value_7 in v9 do
            v13 = value_7.Id;
            if (not (v13)) then
                continue;
            end;
            v11 = value_7.DefaultValue;
            v12 = a1[v13] ~= v11;
            if (v10 or not v12) then
                if (a3 == false) then
                    continue;
                end;
                a1[v13] = v11;
                if (not (v12)) then
                    continue;
                end;
                if (a3) then
                    a3(v13, value_7);
                end;
            elseif (a3 ~= false) then
                v10 = true;
                if (a3 == false) then
                    continue;
                end;
                a1[v13] = v11;
                if (not (v12)) then
                    continue;
                end;
                if (a3) then
                    a3(v13, value_7);
                end;
            else
                return true;
            end;
        end;
        return v10;
    end;
    return false;
end;
MainMenuOpen = function()
    --[[
      name: MainMenuOpen
      line: 689
      upvalues:
        Players_upv_1 (copy, index: 1)
        MainMenuOpen (ref,  index: 2)
    ]]
    local LocalPlayer_1 = Players_upv_1.LocalPlayer;
    if (not LocalPlayer_1) then
        return;
    end;
    MainMenuOpen = MainMenuOpen or (LocalPlayer_1.PlayerGui:FindFirstChild("MainMenu"));
    if (MainMenuOpen) then
        return MainMenuOpen.Enabled;
    end;
end;
tbl_upv_1.MainMenuOpen = MainMenuOpen;
local tbl_16 = {};
local v14 = 0;
tbl_3 = v14;
local v15 = nil;
local v16 = nil;
for key_2, value_8 in tbl_upv_1.Config do
    v15 = nil;
    for _, value_9 in value_8 do
        v16 = value_9.Id;
        if (not (v16)) then
            continue;
        end;
        v15 = tbl_16[v16];
        if (v15) then
            error((("TWO SETTINGS WITH SAME ID (%*) WERE FOUND (%* = %*, CATEGORY = %*)"):format(v16, v15.Text, value_9.Text, key_2)));
        end;
        tbl_16[v16] = value_9;
        tbl_3 = math.max(tbl_3, v16);
    end;
end;
for n_1 = 1, tbl_3 do
    if (not (tbl_16[n_1])) then
        error((("GAP BETWEEN SETTING IDS - THIS CAN CAUSE SAVING ISSUES (ID: %*) (LENGTH: %*) (HIGHEST: %*)"):format(n_1, #tbl_16, tbl_3)));
    end;
end;
return tbl_upv_1;