-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiled with Potassium's decompiler.

local u1 = {
    Settings = nil,
    SkinPresets = nil,
    Categories = { "General", "Graphics", "Controls", "Sound", "Gamepad" },
    Config = {
        General = { {
                Type = "Slider",
                Text = "Field Of View",
                Id = 1,
                DefaultValue = 70,
                SliderStep = 1,
                InputStep = 0.01,
                Range = { 60, 80 }
            }, {
                Type = "Slider",
                Text = "Chat Scale",
                Id = 49,
                DefaultValue = 0.85,
                SliderStep = 0.01,
                InputStep = 0.01,
                Range = { 0.1, 1 }
            }, {
                Type = "Checkbox",
                Text = "Auto Hide All Signs",
                Id = 2,
                DefaultValue = false
            }, {
                Type = "Checkbox",
                Text = "Hide Chat",
                Id = 33,
                DefaultValue = false
            }, {
                Type = "Checkbox",
                Text = "Mute Jukeboxes",
                Id = 34,
                DefaultValue = false
            }, {
                Type = "Checkbox",
                Text = "Decrease Camera Shake",
                Id = 35,
                DefaultValue = false
            }, {
                Type = "Checkbox",
                Text = "Randomize Skin Selection",
                Id = 47,
                DefaultValue = false
            } },
        Graphics = { {
                Type = "Header",
                Text = "Performance"
            }, {
                Type = "Checkbox",
                Text = "Shadows",
                Id = 3,
                DefaultValue = true
            }, {
                Type = "Slider",
                Text = "Max Gib Count",
                Id = 4,
                DefaultValue = 100,
                SliderStep = 1,
                InputStep = 1,
                Range = { 10, 100 }
            }, {
                Type = "Checkbox",
                Text = "Impacts",
                Id = 43,
                DefaultValue = true
            }, {
                Type = "Checkbox",
                Text = "Blood",
                Id = 44,
                DefaultValue = true
            }, {
                Type = "Checkbox",
                Text = "Bullet Casings",
                Id = 45,
                DefaultValue = true
            }, {
                Type = "Header",
                Text = "Viewmodel"
            }, {
                Type = "Slider",
                Text = "Outline Transparency",
                Id = 5,
                DefaultValue = 0,
                SliderStep = 0.1,
                InputStep = 0.01,
                Range = { 0, 1 }
            }, {
                Type = "Checkbox",
                Text = "Toggle Outline",
                Id = 6,
                DefaultValue = true
            }, {
                Type = "Header",
                Text = "Crosshair"
            }, {
                Type = "Checkbox",
                Text = "Toggle Crosshair",
                Id = 36,
                DefaultValue = true
            } },
        Controls = {
            {
                Type = "Header",
                Text = "Sensitivity"
            },
            {
                Type = "Slider",
                Text = "Mouse Sensitivity",
                Id = 7,
                DefaultValue = 1,
                SliderStep = 0.01,
                InputStep = 0.001,
                Range = { 0.001, 10 }
            },
            {
                Type = "Slider",
                Text = "Vehicle Sensitivity",
                Id = 50,
                DefaultValue = 0.3,
                SliderStep = 0.01,
                InputStep = 0.001,
                Range = { 0.001, 10 }
            },
            {
                Type = "Header",
                Text = "Movement"
            },
            {
                Type = "Keybind",
                Text = "Move Forward",
                Id = 8,
                DefaultValue = "W"
            },
            {
                Type = "Keybind",
                Text = "Move Backward",
                Id = 9,
                DefaultValue = "S"
            },
            {
                Type = "Keybind",
                Text = "Move Right",
                Id = 10,
                DefaultValue = "D"
            },
            {
                Type = "Keybind",
                Text = "Move Left",
                Id = 11,
                DefaultValue = "A"
            },
            {
                Type = "Keybind",
                Text = "Jump",
                Id = 12,
                DefaultValue = "Space"
            },
            {
                Type = "Keybind",
                Text = "Sprint",
                Id = 13,
                DefaultValue = "LeftShift"
            },
            {
                Type = "Checkbox",
                Text = "Toggle Sprint",
                Id = 14,
                DefaultValue = false
            },
            {
                Type = "Keybind",
                Text = "Crouch",
                Id = 15,
                DefaultValue = "C"
            },
            {
                Type = "Checkbox",
                Text = "Toggle Crouch",
                Id = 16,
                DefaultValue = false
            },
            {
                Type = "Keybind",
                Text = "Free Look",
                Id = 17,
                DefaultValue = "LeftAlt"
            },
            {
                Type = "Header",
                Text = "Actions"
            },
            {
                Type = "Keybind",
                Text = "Interact",
                Id = 18,
                DefaultValue = "E"
            },
            {
                Type = "Keybind",
                Text = "Open Map",
                Id = 19,
                DefaultValue = "G"
            },
            {
                Type = "Header",
                Text = "Combat"
            },
            {
                Type = "Keybind",
                Text = "Reload",
                Id = 20,
                DefaultValue = "R"
            },
            {
                Type = "Keybind",
                Text = "Aim Down Sight",
                Id = 37,
                DefaultValue = "MB2",
                AllowMouse = true
            },
            {
                Type = "Keybind",
                Text = "Use Attachment",
                Id = 21,
                DefaultValue = "F"
            },
            {
                Type = "Keybind",
                Text = "Inspect",
                Id = 22,
                DefaultValue = "N"
            },
            {
                Type = "Keybind",
                Text = "Use Armor Mod",
                Id = 48,
                DefaultValue = "X"
            },
            {
                Type = "Header",
                Text = "Building"
            },
            {
                Type = "Keybind",
                Text = "Rotate Building",
                Id = 38,
                DefaultValue = "R",
                IgnoreConflict = true
            },
            {
                Type = "Keybind",
                Text = "Change Building",
                Id = 39,
                DefaultValue = "MB2",
                IgnoreConflict = true,
                AllowMouse = true
            },
            {
                Type = "Header",
                Text = "Inventory"
            },
            {
                Type = "Keybind",
                Text = "Toolbar Left",
                Id = 40,
                DefaultValue = "M.WheelUp",
                AllowMouse = true
            },
            {
                Type = "Keybind",
                Text = "Toolbar Right",
                Id = 41,
                DefaultValue = "M.WheelDown",
                AllowMouse = true
            },
            {
                Type = "Keybind",
                Text = "Open Inventory",
                Id = 23,
                DefaultValue = "Tab"
            },
            {
                Type = "Keybind",
                Text = "Open Crafting",
                Id = 24,
                DefaultValue = "Q"
            },
            {
                Type = "Keybind",
                Text = "Quick Loot",
                Id = 25,
                DefaultValue = "H"
            },
            {
                Type = "Header",
                Text = "Chat"
            },
            {
                Type = "Keybind",
                Text = "Start Typing",
                Id = 26,
                DefaultValue = "Return"
            },
            {
                Type = "Keybind",
                Text = "Start Command",
                Id = 27,
                DefaultValue = "Slash"
            },
            {
                Type = "Keybind",
                Text = "Switch Channels",
                Id = 28,
                DefaultValue = "Tab",
                IgnoreConflict = true
            },
            {
                Type = "Header",
                Text = "Cinematic Mode"
            },
            {
                Type = "Keybind",
                Text = "Hide UI",
                Id = 29,
                DefaultValue = "M"
            }
        },
        Sound = { {
                Type = "Slider",
                Text = "Master Volume",
                Id = 30,
                DefaultValue = 1,
                SliderStep = 0.1,
                InputStep = 0.01,
                Range = { 0, 1 }
            }, {
                Type = "Slider",
                Text = "SFX Volume",
                Id = 31,
                DefaultValue = 1,
                SliderStep = 0.1,
                InputStep = 0.01,
                Range = { 0, 1 }
            }, {
                Type = "Slider",
                Text = "Gunshot Volume",
                Id = 42,
                DefaultValue = 1,
                SliderStep = 0.1,
                InputStep = 0.01,
                Range = { 0, 1 }
            }, {
                Type = "Slider",
                Text = "Jukebox Volume",
                Id = 32,
                DefaultValue = 1,
                SliderStep = 0.1,
                InputStep = 0.01,
                Range = { 0, 1 }
            }, {
                Type = "Slider",
                Text = "Music Volume",
                Id = 46,
                DefaultValue = 1,
                SliderStep = 0.1,
                InputStep = 0.01,
                Range = { 0, 1 }
            } },
        Gamepad = {
            {
                Type = "Header",
                Text = "Sensitivity"
            },
            {
                Type = "Slider",
                Text = "Mouse Sensitivity",
                Id = 67,
                DefaultValue = 0.65,
                SliderStep = 0.01,
                InputStep = 0.001,
                Range = { 0.001, 3 }
            },
            {
                Type = "Slider",
                Text = "Aiming Sensitivty",
                Id = 68,
                DefaultValue = 0.27,
                SliderStep = 0.01,
                InputStep = 0.001,
                Range = { 0.001, 3 }
            },
            {
                Type = "Slider",
                Text = "Joystick Deadzone",
                Id = 70,
                DefaultValue = 0.225,
                SliderStep = 0.01,
                InputStep = 0.001,
                Range = { 0.001, 0.9 }
            },
            {
                Type = "Header",
                Text = "Movement"
            },
            {
                Type = "Keybind",
                Text = "Jump",
                Id = 51,
                DefaultValue = "ButtonA"
            },
            {
                Type = "Keybind",
                Text = "Sprint",
                Id = 64,
                DefaultValue = "ButtonL3"
            },
            {
                Type = "Checkbox",
                Text = "Toggle Sprint",
                Id = 52,
                DefaultValue = false
            },
            {
                Type = "Keybind",
                Text = "Crouch",
                Id = 53,
                DefaultValue = "ButtonB"
            },
            {
                Type = "Checkbox",
                Text = "Toggle Crouch",
                Id = 65,
                DefaultValue = true
            },
            {
                Type = "Header",
                Text = "Actions"
            },
            {
                Type = "Keybind",
                Text = "Interact/Reload",
                Id = 54,
                DefaultValue = "ButtonX"
            },
            {
                Type = "Keybind",
                Text = "Open Map",
                Id = 55,
                DefaultValue = "DPadDown"
            },
            {
                Type = "Header",
                Text = "Combat"
            },
            {
                Type = "Keybind",
                Text = "Aim Down Sight",
                Id = 56,
                DefaultValue = "ButtonL2",
                AllowMouse = true
            },
            {
                Type = "Keybind",
                Text = "Use Attachment",
                Id = 57,
                DefaultValue = "DPadUp"
            },
            {
                Type = "Keybind",
                Text = "Inspect",
                Id = 58,
                DefaultValue = "DPadLeft"
            },
            {
                Type = "Keybind",
                Text = "Use Armor Mod",
                Id = 59,
                DefaultValue = "DPadRight"
            },
            {
                Type = "Header",
                Text = "Building"
            },
            {
                Type = "Keybind",
                Text = "Rotate Building",
                Id = 60,
                DefaultValue = "ButtonX",
                IgnoreConflict = true
            },
            {
                Type = "Keybind",
                Text = "Change Building",
                Id = 66,
                DefaultValue = "ButtonL2",
                IgnoreConflict = true,
                AllowMouse = true
            },
            {
                Type = "Keybind",
                Text = "Place Building",
                Id = 69,
                DefaultValue = "ButtonR2",
                IgnoreConflict = true
            },
            {
                Type = "Header",
                Text = "Inventory"
            },
            {
                Type = "Keybind",
                Text = "Toolbar Left",
                Id = 61,
                DefaultValue = "ButtonL1",
                AllowMouse = true
            },
            {
                Type = "Keybind",
                Text = "Toolbar Right",
                Id = 62,
                DefaultValue = "ButtonR1",
                AllowMouse = true
            },
            {
                Type = "Keybind",
                Text = "Open Inventory/Crafting",
                Id = 63,
                DefaultValue = "ButtonY"
            }
        }
    }
};
local Players = game:GetService("Players");
local u2 = {};
local u3 = nil;

function u1.CreateDefaultSettings() -- Line: 593
    -- upvalues: u1 (copy)
    local v4 = {};

    for _, v in u1.Config do
        for _, v2 in v do
            local Id = v2.Id;

            if Id then
                v4[Id] = v2.DefaultValue;
            end;
        end;
    end;

    return v4;
end;

function u1.GetSettingFromId(p5) -- Line: 605
    -- upvalues: u2 (copy), u1 (copy)
    local v6 = u2[p5];

    if v6 then
        return v6;
    end;

    for _, v in u1.Config do
        for _, v2 in v do
            if v2.Id == p5 then
                u2[p5] = v2;

                return v2;
            end;
        end;
    end;
end;

function u1.CheckKeybind(p7, p8, p9) -- Line: 619
    -- upvalues: u1 (copy)
    if p9 then
        local v10 = u1.GetSettingFromId(p9);

        if v10 and v10.IgnoreConflict then
            return;
        end;
    end;

    for i, v in p7 do
        if i ~= p9 and v == p8 then
            local v11 = u1.GetSettingFromId(i);

            if not v11.IgnoreConflict then
                return v11;
            end;
        end;
    end;
end;

function u1.ApplySettings(p12, p13) -- Line: 632
    -- upvalues: u1 (copy)
    u1.Settings = p12;

    if p13 then
        u1.SkinPresets = p13;
    end;
end;

function u1.GetSkinPreset(p14, p15, p16, p17) -- Line: 639
    -- upvalues: u1 (copy)
    local v18 = (p17 or u1.SkinPresets)[tostring(p15)];

    if not v18 then
        return "Default";
    end;

    local v19 = `{p16}/{v18}`;

    return not table.find(p14, v19) and "Default" or v18;
end;

function u1.SetSkinPreset(p20, p21, p22) -- Line: 647
    if not p20 then
        return;
    end;

    local v23 = tostring(p21);

    if p22 == "Default" then
        p22 = nil;
    end;

    p20[v23] = p22;
end;

function u1.GetSetting(p24, p25, p26) -- Line: 652
    -- upvalues: u1 (copy)
    for _, v in u1.Config[p24] do
        if v.Text == p25 then
            local v27 = p26 or u1.Settings;

            if v27 then
                local v28 = v27[v.Id];

                if v28 ~= nil then
                    return v28;
                end;
            end;

            return v.DefaultValue;
        end;
    end;
end;

function u1.ResetSettings(p29, p30, p31) -- Line: 668
    -- upvalues: u1 (copy)
    local v32 = u1.Config[p30];

    if not v32 then
        return false;
    end;

    local v33 = false;

    for _, v in v32 do
        local Id = v.Id;

        if Id then
            local DefaultValue = v.DefaultValue;
            local v34 = p29[Id] ~= DefaultValue;

            if not v33 and v34 then
                if p31 == false then
                    return true;
                end;

                v33 = true;
            end;

            if p31 ~= false then
                p29[Id] = DefaultValue;

                if v34 and p31 then
                    p31(Id, v);
                end;
            end;
        end;
    end;

    return v33;
end;

function u1.MainMenuOpen() -- Line: 689
    -- upvalues: Players (copy), u3 (ref)
    local LocalPlayer = Players.LocalPlayer;

    if not LocalPlayer then
        return;
    end;

    if not u3 then
        u3 = LocalPlayer.PlayerGui:FindFirstChild("MainMenu");
    end;

    if u3 then
        return u3.Enabled;
    end;
end;

local v35 = {};
local v36 = 0;

for i, v in u1.Config do
    for _, v2 in v do
        local Id = v2.Id;

        if Id then
            local v37 = v35[Id];

            if v37 then
                error((`TWO SETTINGS WITH SAME ID ({Id}) WERE FOUND ({v37.Text} = {v2.Text}, CATEGORY = {i})`));
            end;

            v35[Id] = v2;
            v36 = math.max(v36, Id);
        end;
    end;
end;

for i = 1, v36 do
    if not v35[i] then
        error((`GAP BETWEEN SETTING IDS - THIS CAN CAUSE SAVING ISSUES (ID: {i}) (LENGTH: {#v35}) (HIGHEST: {v36})`));
    end;
end;

return u1;