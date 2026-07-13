-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local v1 = game:GetService("Players").LocalPlayer == nil;
local v2, v3, v4;
do
    local tbl_1 = {};
    tbl_1.Default = function(a1, a2, a3)
        --[[
          name: Default
          line: 21
        ]]
        local tbl_2 = {};
        tbl_2.Offset = CFrame.new(a2, 0, 0);
        tbl_2.Range = a1;
        local tbl_3 = {};
        tbl_3.Offset = CFrame.new(-a2, 0, 0);
        tbl_3.Range = a1;
        local tbl_4 = {};
        tbl_4.Offset = CFrame.new(0, a3, 0);
        tbl_4.Range = a1;
        local tbl_5 = {};
        tbl_5.Offset = CFrame.new(0, -a3, 0);
        tbl_5.Range = a1;
        local tbl_6 = {};
        tbl_6.Offset = CFrame.new(a2, a3, 0);
        tbl_6.Range = a1;
        local tbl_7 = {};
        tbl_7.Offset = CFrame.new(a2, -a3, 0);
        tbl_7.Range = a1;
        local tbl_8 = {};
        tbl_8.Offset = CFrame.new(-a2, a3, 0);
        tbl_8.Range = a1;
        local tbl_9 = {};
        tbl_9.Offset = CFrame.new(-a2, -a3, 0);
        tbl_9.Range = a1;
        return {{Offset = CFrame.new(), Range = a1}, tbl_2, tbl_3, tbl_4, tbl_5, tbl_6, tbl_7, tbl_8, tbl_9};
    end;
    v2 = {};
    do
        local tbl_10 = {};
        tbl_10.Offsets = {Global = CFrame.new(-0.0062, -0.5775, -0.6094, 1, 0, -0, -0, 0, 1, 0, -1, 0), Local = CFrame.new()};
        tbl_10.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_11 = {};
        tbl_11.Speed = 2100;
        tbl_11.Gravity = 0.55;
        tbl_11.MaxRange = 1100;
        tbl_11.Dropoff = {};
        tbl_11.HumanoidDamages = {};
        tbl_11.SoftSideMult = 2;
        local v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.24, 0.99};
            v5.Y = {-1.85, 0.02};
            v5.Z = {-5.45, -2};
        end;
        tbl_11["[DEBUG]"] = v5;
        tbl_10.Bullet = tbl_11;
        tbl_10.ObjectDamages = {Benches = {}};
        tbl_10.Casing = {Velocity = {10, 11}, Offset = CFrame.Angles(0, 0, 0.3490658503988659), ExtraMoveVelocities = {-10, 13}};
        tbl_10.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_12 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.3, 0.3}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 171
            ]]
            return (math.max(a1 - 6, 0) * 0.09) + 3.05, 0;
        end;
        v5.RecoilFinish = function(a1)
            --[[
              name: RecoilFinish
              line: 174
            ]]
            return 0, 0;
        end;
        tbl_12.Camera = v5;
        tbl_12.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_10.Recoil = tbl_12;
        tbl_10.Shake = {Angles = {-179, 180}};
        v2["Salvaged M14"] = tbl_10;
        local v5;
        do
            local tbl_13 = {};
            tbl_13.AimDownSpeed = {};
            tbl_13.VMMovementMults = {};
            local tbl_14 = {};
            tbl_14.Dropoff = {};
            tbl_14.HumanoidDamages = {};
            local tbl_15 = {};
            tbl_15.Benches = {};
            local tbl_16 = {};
            tbl_16.Velocity = {10, 11};
            tbl_16.Offset = CFrame.Angles(0, 0, 0.3490658503988659);
            tbl_16.ExtraMoveVelocities = {-10, 13};
            local tbl_17 = {};
            tbl_17.Hip = {};
            tbl_17.Aiming = {};
            tbl_17.Shooting = {};
            local tbl_18 = {};
            v5 = {};
            v5.Decay = {};
            v5.Shake = {X = {-0.3, 0.3}, Y = {0, 0}};
            v5.RecoilStart = function(a1)
                --[[
                  name: RecoilStart
                  line: 308
                ]]
                return (math.max(a1 - 6, 0) * 0.09) + 3.05, 0;
            end;
            v5.RecoilFinish = function(a1)
                --[[
                  name: RecoilFinish
                  line: 311
                ]]
                return 0, 0;
            end;
            tbl_18.Camera = v5;
            tbl_18.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
            do
                local tbl_19 = {};
                tbl_19.Angles = {-179, 180};
                v2["Military M39"] = {Offsets = {Global = CFrame.new(-0.1977, -0.7646, -0.6572, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(0.018, -0.7479, -0.0819, 1, -0, 1e-04, 1e-04, 1, 1e-04, -0, -0, 1)}, Weapon = tbl_13, Bullet = tbl_14, ObjectDamages = tbl_15, Casing = tbl_16, Spread = tbl_17, Recoil = tbl_18, Shake = tbl_19};
            end;
        end;
        local tbl_20 = {};
        tbl_20.Offsets = {Global = CFrame.new(0.0434, -0.3856, -0.2963, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new(0.1041, 0.136, 0.2841, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1), ["LocalHot Rod"] = CFrame.new(-0.0259, -0.5738, -0.0719, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)};
        tbl_20.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_21 = {};
        tbl_21.Speed = 2100;
        tbl_21.Gravity = 0.55;
        tbl_21.MaxRange = 1100;
        tbl_21.Dropoff = {};
        tbl_21.HumanoidDamages = {};
        tbl_21.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.24, 0.77};
            v5.Y = {-1.18, -0.05};
            v5.Z = {-3.89, -1.85};
        end;
        tbl_21["[DEBUG]"] = v5;
        tbl_20.Bullet = tbl_21;
        tbl_20.ObjectDamages = {Benches = {}};
        tbl_20.Casing = {Velocity = {12, 13}, Offset = CFrame.Angles(-1.5707963267948966, 0, 0), ExtraMoveVelocities = {13, -10}};
        tbl_20.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_22 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {0, 0}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 445
            ]]
            return (1 - math.min(math.max(a1 - 7, 0) / 40, 0.5)) * 3.5, ((3 - math.min(a1 / 10, 0.9)) * math.sin(math.min(a1, 29) / 9.55)) * 1.1;
        end;
        v5.RecoilFinish = function(a1)
            --[[
              name: RecoilFinish
              line: 452
            ]]
            return 0, 0;
        end;
        tbl_22.Camera = v5;
        tbl_22.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_20.Recoil = tbl_22;
        tbl_20.Shake = {Angles = {-179, 180}};
        v2["Salvaged AK47"] = tbl_20;
        local tbl_23 = {};
        tbl_23.Offsets = {Global = CFrame.new(-0.0261, -0.6152, -0.4132, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new(0.0501, 0.0601, 0.0041, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)};
        tbl_23.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_24 = {};
        tbl_24.Speed = 2100;
        tbl_24.Gravity = 0.55;
        tbl_24.MaxRange = 1050;
        tbl_24.Dropoff = {};
        tbl_24.HumanoidDamages = {};
        tbl_24.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.22, 0.82};
            v5.Y = {-1.47, -0.15};
            v5.Z = {-4.33, -2.55};
        end;
        tbl_24["[DEBUG]"] = v5;
        tbl_23.Bullet = tbl_24;
        tbl_23.ObjectDamages = {Benches = {}};
        tbl_23.Casing = {Velocity = {12, 13}, Offset = CFrame.Angles(-1.5707963267948966, 0, 0), ExtraMoveVelocities = {13, -10}};
        tbl_23.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_25 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.05, 0.05}, Y = {0, 0.1}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 585
            ]]
            return (1 - math.min(math.max(a1 - 5, 0) / 30, 0.3)) * 2.9, ((math.sin((a1 - 2) / 5) * 1.8) + 0.3) * 0.7;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 590
            ]]
            return 0, 0;
        end;
        tbl_25.Camera = v5;
        tbl_25.VM = {Pos = {}, Rot = {X = {-1.3, 1.3}, Z = {-0.9, 0.9}}};
        tbl_23.Recoil = tbl_25;
        tbl_23.Shake = {Angles = {-179, 180}};
        v2["Military M4A1"] = tbl_23;
        local tbl_26 = {};
        tbl_26.Offsets = {Global = CFrame.new(-0.0261, -0.6152, -0.4132, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new(0.0501, 0.0601, 0.0041, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)};
        tbl_26.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_27 = {};
        tbl_27.Speed = 2100;
        tbl_27.Gravity = 0.55;
        tbl_27.MaxRange = 1050;
        tbl_27.Dropoff = {};
        tbl_27.HumanoidDamages = {};
        tbl_27.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.22, 0.82};
            v5.Y = {-1.47, -0.15};
            v5.Z = {-4.33, -2.55};
        end;
        tbl_27["[DEBUG]"] = v5;
        tbl_26.Bullet = tbl_27;
        tbl_26.ObjectDamages = {Benches = {}};
        tbl_26.Casing = {Velocity = {12, 13}, Offset = CFrame.Angles(-1.5707963267948966, 0, 0), ExtraMoveVelocities = {13, -10}};
        tbl_26.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_28 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.05, 0.05}, Y = {0, 0.1}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 723
            ]]
            return (1 - math.min(math.max(a1 - 5, 0) / 30, 0.3)) * 2.2, ((math.sin((a1 - 2) / 5) * 1.8) + 0.3) * 0.53;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 728
            ]]
            return 0, 0;
        end;
        tbl_28.Camera = v5;
        tbl_28.VM = {Pos = {}, Rot = {X = {-1.3, 1.3}, Z = {-0.9, 0.9}}};
        tbl_26.Recoil = tbl_28;
        tbl_26.Shake = {Angles = {-179, 180}};
        v2["Bruno's M4A1"] = tbl_26;
        local tbl_29 = {};
        tbl_29.Offsets = {Global = CFrame.new(0.0409, -0.4636, -0.6307, 0, 0, -1, 1, 0, 0, 0, -1, 0), Local = CFrame.new()};
        tbl_29.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_30 = {};
        tbl_30.Speed = 2400;
        tbl_30.Gravity = 0.55;
        tbl_30.MaxRange = 1250;
        tbl_30.Dropoff = {};
        tbl_30.HumanoidDamages = {};
        tbl_30.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.26, 0.85};
            v5.Y = {-1.87, -0.12};
            v5.Z = {-5.57, -3.35};
        end;
        tbl_30["[DEBUG]"] = v5;
        tbl_29.Bullet = tbl_30;
        tbl_29.ObjectDamages = {Benches = {}};
        tbl_29.Casing = {Velocity = {12, 13}, Offset = CFrame.Angles(-1.5707963267948966, 0, 0), ExtraMoveVelocities = {13, -10}};
        tbl_29.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_31 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.1, 0.1}, Y = {0, 0.2}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 861
            ]]
            return 3.5, 0.3;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 864
            ]]
            return 0, 0;
        end;
        tbl_31.Camera = v5;
        tbl_31.VM = {Pos = {}, Rot = {X = {-1.3, 1.3}, Z = {-0.9, 0.9}}};
        tbl_29.Recoil = tbl_31;
        tbl_29.Shake = {Angles = {-179, 180}};
        v2["Military PKM"] = tbl_29;
        local tbl_32 = {};
        tbl_32.Offsets = {Global = CFrame.new(-0.0209, -0.7758, -0.3914, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(0.0421, 0.0261, -0.1839, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1), LocalMP5 = CFrame.new(0.1901, -0.7978, -0.1059, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1), GlobalMP5 = CFrame.new(-0.0209, -0.7758, -0.3914, 1, 0, 0, 0, 0, 1, 0, -1, 0) * CFrame.Angles(0, math.pi, 0)};
        tbl_32.Weapon = {AimDownSpeed = {}, ReloadAnimSpeed = {}, EquipAnimSpeed = {}, VMMovementMults = {}};
        local tbl_33 = {};
        tbl_33.Speed = 1800;
        tbl_33.Gravity = 0.6;
        tbl_33.MaxRange = 800;
        tbl_33.Dropoff = {};
        tbl_33.HumanoidDamages = {};
        tbl_33.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.19, 0.82};
            v5.Y = {-1.42, -0.22};
            v5.Z = {-3.93, -1.6};
        end;
        tbl_33["[DEBUG]"] = v5;
        tbl_32.Bullet = tbl_33;
        tbl_32.ObjectDamages = {Benches = {}};
        tbl_32.Casing = {Velocity = {10, 12}, Offset = CFrame.Angles(-1.5707963267948966, 0, 0.5235987755982988), ExtraMoveVelocities = {-10, 13}};
        tbl_32.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_34 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {0, 0}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 996
            ]]
            local v6 = a1 * ((2 - (math.max(a1 - 13, 0) / 10)) * math.sin(a1 / 5)) / 8;
            return math.max(1 - (math.max(a1 - 19, 0) / 6), 0) * 2.75, v6 * 0.95;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 1001
            ]]
            return 0, 0;
        end;
        tbl_34.Camera = v5;
        tbl_34.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_32.Recoil = tbl_34;
        tbl_32.Shake = {Angles = {-179, 180}};
        v2["Salvaged AK74u"] = tbl_32;
        local tbl_35 = {};
        tbl_35.Offsets = {Global = CFrame.new(0.0215, -0.4132, -0.421, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(0.0842, -0.7978, 0.0962, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)};
        tbl_35.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_36 = {};
        tbl_36.Speed = 1900;
        tbl_36.Gravity = 0.6;
        tbl_36.MaxRange = 800;
        tbl_36.Dropoff = {};
        tbl_36.HumanoidDamages = {};
        tbl_36.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.19, 0.82};
            v5.Y = {-1.42, -0.22};
            v5.Z = {-3.93, -1.4};
        end;
        tbl_36["[DEBUG]"] = v5;
        tbl_35.Bullet = tbl_36;
        tbl_35.ObjectDamages = {Benches = {}};
        tbl_35.Casing = {Velocity = {10, 12}, Offset = CFrame.Angles(-1.5707963267948966, 0, 0.5235987755982988), ExtraMoveVelocities = {-10, 13}};
        tbl_35.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_37 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {0, 0}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 1125
            ]]
            local v7 = a1 * ((2 - (math.max(a1 - 13, 0) / 10)) * math.sin(a1 / 5)) / 8;
            return math.max(1 - (math.max(a1 - 19, 0) / 6), 0) * 2.3, v7 * 0.3;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 1130
            ]]
            return 0, 0;
        end;
        tbl_37.Camera = v5;
        tbl_37.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_35.Recoil = tbl_37;
        tbl_35.Shake = {Angles = {-179, 180}};
        v2["Military MP7"] = tbl_35;
        local tbl_38 = {};
        tbl_38.Offsets = {Global = CFrame.new(-0.0255, -0.3972, -0.433, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new()};
        tbl_38.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_39 = {};
        tbl_39.Offset = 0.005235987755982988;
        tbl_39.Speed = 420;
        tbl_39.Gravity = 0.2;
        tbl_39.MaxRange = 500;
        tbl_39.Dropoff = {};
        tbl_39.HumanoidDamages = {};
        tbl_39.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.09, 0.88};
            v5.Y = {-1.64, -0.08};
            v5.Z = {-3.47, -2.2};
        end;
        tbl_39["[DEBUG]"] = v5;
        tbl_38.Bullet = tbl_39;
        tbl_38.ObjectDamages = {Benches = {}};
        tbl_38.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_40 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-1, 1}, Y = {0, 0.5}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 1249
            ]]
            return 5, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 1252
            ]]
            return -1, 0;
        end;
        tbl_40.Camera = v5;
        tbl_40.VM = {Pos = {X = {-0.05, 0.05}}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_38.Recoil = tbl_40;
        v2.Crossbow = tbl_38;
        local tbl_41 = {};
        tbl_41.Offsets = {Global = CFrame.new(-0.0501, -0.1349, 0.1087, 0, 0.0075, 1, 0.9999, -0.0173, 2e-04, 0.0174, 0.9999, -0.0074), Local = CFrame.new(), Aim = CFrame.new(-0.224, 0.4922, 0.6801, 1, 0, 0, 0, 1, 0, 0, 0, 1)};
        tbl_41.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_42 = {};
        tbl_42.Offset = 0.010471975511965976;
        tbl_42.Speed = 280;
        tbl_42.Gravity = 0.2;
        tbl_42.MaxRange = 400;
        tbl_42.Dropoff = {};
        tbl_42.HumanoidDamages = {};
        tbl_42.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.11, 0.58};
            v5.Y = {-1.12, 0.1};
            v5.Z = {-2.6, -1.45};
        end;
        tbl_42["[DEBUG]"] = v5;
        tbl_41.Bullet = tbl_42;
        tbl_41.ObjectDamages = {Benches = {}};
        tbl_41.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_43 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.1, 0.1}, Y = {-0.1, 0.1}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 1366
            ]]
            return 0, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 1369
            ]]
            return 0, 0;
        end;
        tbl_43.Camera = v5;
        tbl_43.VM = {Pos = {X = {-0.05, 0.05}}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_41.Recoil = tbl_43;
        v2["Wooden Bow"] = tbl_41;
        local tbl_44 = {};
        tbl_44.Offsets = {Global = CFrame.new(-0.17, -0.3834, -0.2964, 0, 0, -1, 1, 0, 0, 0, -1, 0), Local = CFrame.new(-0.0918, 0.1341, 0.0101, 1, 0, 0, 0, 1, 0, 0, 0, 1)};
        tbl_44.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_45 = {};
        tbl_45.Speed = 1400;
        tbl_45.Gravity = 0.6;
        tbl_45.MaxRange = 600;
        tbl_45.Dropoff = {};
        tbl_45.HumanoidDamages = {};
        tbl_45.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.14, 0.62};
            v5.Y = {-0.99, -0.09};
            v5.Z = {-2.86, -0.87};
        end;
        tbl_45["[DEBUG]"] = v5;
        tbl_44.Bullet = tbl_45;
        tbl_44.ObjectDamages = {Benches = {}};
        tbl_44.Casing = {Velocity = {8, 10}, Offset = CFrame.Angles(0, 0, 0.3490658503988659), ExtraMoveVelocities = {-8, 11}};
        tbl_44.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_46 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.5, 0.5}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 1487
            ]]
            return (math.max(a1 - 2.5, 0) * 0.14) + 2.2, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 1490
            ]]
            return 0, 0;
        end;
        tbl_46.Camera = v5;
        tbl_46.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_44.Recoil = tbl_46;
        tbl_44.Shake = {Angles = {-179, 180}};
        v2["Salvaged P250"] = tbl_44;
        local tbl_47 = {};
        tbl_47.Offsets = {Global = CFrame.new(-0.2371, -0.3779, -0.2677, 0, 0, -0.9999, 1, 0, 0, 0, -1, 0), Local = CFrame.new(-0.0918, 0.1341, 0.0101, 1, 0, 0, 0, 1, 0, 0, 0, 1)};
        tbl_47.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_48 = {};
        tbl_48.Speed = 1500;
        tbl_48.Gravity = 0.6;
        tbl_48.MaxRange = 650;
        tbl_48.Dropoff = {};
        tbl_48.HumanoidDamages = {};
        tbl_48.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.14, 0.62};
            v5.Y = {-0.99, -0.09};
            v5.Z = {-2.86, -0.87};
        end;
        tbl_48["[DEBUG]"] = v5;
        tbl_47.Bullet = tbl_48;
        tbl_47.ObjectDamages = {Benches = {}};
        tbl_47.Casing = {Velocity = {8, 10}, Offset = CFrame.Angles(0, 0, 0.3490658503988659), ExtraMoveVelocities = {-8, 11}};
        tbl_47.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_49 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.5, 0.5}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 1615
            ]]
            return (math.max(a1 - 2.5, 0) * 0.14) + 2.2, 0;
        end;
        v5.RecoilFinish = function(a1)
            --[[
              name: RecoilFinish
              line: 1618
            ]]
            return 0, 0;
        end;
        tbl_49.Camera = v5;
        tbl_49.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_47.Recoil = tbl_49;
        tbl_47.Shake = {Angles = {-179, 180}};
        v2["Military USP"] = tbl_47;
        local tbl_50 = {};
        tbl_50.Offsets = {Global = CFrame.new(0.0146, -0.6745, -0.4232, 1, 1e-04, -0, 1e-04, -0, 1, -0, -1, 0), Local = CFrame.new(0.0083, -0.0439, -0.3758, 1, 0, 0, 0, 1, 0, 0, 0, 1)};
        tbl_50.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_51 = {};
        tbl_51.Speed = 1800;
        tbl_51.Gravity = 0.6;
        tbl_51.MaxRange = 750;
        tbl_51.Dropoff = {};
        tbl_51.HumanoidDamages = {};
        tbl_51.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.15, 0.74};
            v5.Y = {-1.48, -0.06};
            v5.Z = {-4.17, -1.95};
        end;
        tbl_51["[DEBUG]"] = v5;
        tbl_50.Bullet = tbl_51;
        tbl_50.ObjectDamages = {Benches = {}};
        tbl_50.Casing = {Velocity = {12, 13}, Offset = CFrame.Angles(-1.5707963267948966, 0, 0.5235987755982988)};
        tbl_50.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_52 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {0, 0}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 1741
            ]]
            return (math.max(a1 - 5, 0) * 0.04) + 2.6, (math.min(2.5 + (a1 / 8), 5) * math.sin(a1 / 2.3)) * 0.56;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 1745
            ]]
            return 0, 0;
        end;
        tbl_52.Camera = v5;
        tbl_52.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_50.Recoil = tbl_52;
        tbl_50.Shake = {Angles = {-179, 180}};
        v2["Salvaged SMG"] = tbl_50;
        local tbl_53 = {};
        tbl_53.Offsets = {Global = CFrame.new(-0.0179, -0.2526, -0.3474, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new(0.0043, 0.0801, -0.0257, 1, 1e-04, 1e-04, -0, 1, 1e-04, -0, -0, 1)};
        tbl_53.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_54 = {};
        tbl_54.Speed = 1600;
        tbl_54.Gravity = 0.6;
        tbl_54.MaxRange = 550;
        tbl_54.Dropoff = {};
        tbl_54.HumanoidDamages = {};
        tbl_54.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.14, 0.59};
            v5.Y = {-0.68, -0.07};
            v5.Z = {-2.89, -1.3};
        end;
        tbl_54["[DEBUG]"] = v5;
        tbl_53.Bullet = tbl_54;
        tbl_53.ObjectDamages = {Benches = {}};
        tbl_53.Casing = {Velocity = {12, 13}, Offset = CFrame.Angles(-1.5707963267948966, 0, 0.5235987755982988)};
        tbl_53.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_55 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {0, 0}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 1868
            ]]
            return (math.max(a1 - 5, 0) * 0.06) + 2.75, (math.min(2.5 + (a1 / 8), 5) * math.sin(a1 / 6)) * 0.3;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 1871
            ]]
            return 0, 0;
        end;
        tbl_55.Camera = v5;
        tbl_55.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_53.Recoil = tbl_55;
        tbl_53.Shake = {Angles = {-179, 180}};
        v2["Salvaged Skorpion"] = tbl_53;
        local tbl_56 = {};
        tbl_56.Offsets = {Global = CFrame.new(-0.0319, -0.0594, -0.5213, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new(-0.0617, 0.1222, -0.1778, 1, 0, 0, 0, 1, 0, 0, 0, 1)};
        tbl_56.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_57 = {};
        tbl_57.Speed = 1800;
        tbl_57.Gravity = 0.6;
        tbl_57.MaxRange = 700;
        tbl_57.Dropoff = {};
        tbl_57.HumanoidDamages = {};
        tbl_57.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.07, 0.54};
            v5.Y = {-0.94, -0.15};
            v5.Z = {-3.08, -1.6};
        end;
        tbl_57["[DEBUG]"] = v5;
        tbl_56.Bullet = tbl_57;
        tbl_56.ObjectDamages = {Benches = {}};
        tbl_56.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_58 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-1.5, 1.5}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 1989
            ]]
            return (math.max(a1 - 1, 0) * 0.4) + 5.4, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 1992
            ]]
            return 0, 0;
        end;
        tbl_58.Camera = v5;
        tbl_58.VM = {Pos = {}, Rot = {X = {-1.5, 1.5}, Z = {-1, 1}}};
        tbl_56.Recoil = tbl_58;
        tbl_56.Shake = {Angles = {-179, 180}};
        v2["Salvaged Python"] = tbl_56;
        local tbl_59 = {};
        tbl_59.Offsets = {Global = CFrame.new(-0.016, 0.1562, -0.4697, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new(-0.05, 0.0081, 0.146, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)};
        tbl_59.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_60 = {};
        tbl_60.Offset = 0.026179938779914945;
        tbl_60.Speed = 165;
        tbl_60.Gravity = 0.25;
        tbl_60.MaxRange = 125;
        tbl_60.Dropoff = {};
        tbl_60.HumanoidDamages = {};
        tbl_60.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.08, 0.54};
            v5.Y = {-0.98, -0.2};
            v5.Z = {-1.98, -1.42};
        end;
        tbl_60["[DEBUG]"] = v5;
        tbl_59.Bullet = tbl_60;
        tbl_59.ObjectDamages = {Benches = {}};
        tbl_59.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_61 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.2, 0.2}, Y = {0, 0}};
        v5.RecoilStart = function(a1)
            --[[
              name: RecoilStart
              line: 2108
            ]]
            return (math.max(a1 - 3, 0) * 0.06) + 2, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 2111
            ]]
            return 0, 0;
        end;
        tbl_61.Camera = v5;
        tbl_61.VM = {Pos = {}, Rot = {X = {-1, 1}, Z = {-0.5, 0.5}}};
        tbl_59.Recoil = tbl_61;
        tbl_59.Shake = {Angles = {-179, 180}};
        v2["Nail Gun"] = tbl_59;
        local tbl_62 = {};
        tbl_62.Offsets = {Global = CFrame.new(-0.1689, -0.549, -0.1655, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new(-0.05, 0.0081, 0.146, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1), SightBack = CFrame.Angles(0, 0, -0.2617993877991494)};
        tbl_62.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_63 = {};
        tbl_63.Offset = 0.04363323129985824;
        tbl_63.Speed = 100;
        tbl_63.Gravity = 0.12;
        tbl_63.MaxRange = 1000;
        tbl_63.Dropoff = {};
        tbl_63.DisplayDamage = 175;
        tbl_63.HumanoidDamages = {};
        tbl_63.SoftSideMult = 1;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {0, 0.16};
            v5.Y = {-0.45, -0.35};
            v5.Z = {-2.85, -2.4};
        end;
        tbl_63["[DEBUG]"] = v5;
        tbl_62.Bullet = tbl_63;
        tbl_62.ObjectDamages = {Benches = {}};
        tbl_62.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_64 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-3, 3}, Y = {0, 2}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 2244
            ]]
            return 10, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 2247
            ]]
            return -3.5, 0;
        end;
        tbl_64.Camera = v5;
        tbl_64.VM = {Pos = {X = {-0.2, 0.2}}, Rot = {X = {-2.25, 2.25}, Z = {-1.3, 1.3}}};
        tbl_62.Recoil = tbl_64;
        tbl_62.Shake = {Angles = {-179, 180}};
        v2["Salvaged RPG"] = tbl_62;
        local v5;
        do
            local tbl_65 = {};
            tbl_65.ReloadAnimSpeed = {1, 1, 1};
            tbl_65.VMMovementMults = {};
            local tbl_66 = {};
            tbl_66.Dropoff = {};
            tbl_66.HumanoidDamages = {};
            local tbl_67 = {};
            tbl_67.Benches = {};
            local tbl_68 = {};
            tbl_68.Hip = {};
            tbl_68.Aiming = {};
            tbl_68.Shooting = {};
            local tbl_69 = {};
            v5 = {};
            v5.Decay = {};
            v5.Shake = {X = {-0.5, 0.5}, Y = {0, 1}};
            v5.RecoilStart = function()
                --[[
                  name: RecoilStart
                  line: 2377
                ]]
                return 6, 0;
            end;
            v5.RecoilFinish = function()
                --[[
                  name: RecoilFinish
                  line: 2380
                ]]
                return -1, 0;
            end;
            tbl_69.Camera = v5;
            tbl_69.VM = {Pos = {X = {-0.2, 0.2}}, Rot = {X = {-2, 2}, Z = {-1.2, 1.2}}};
            do
                local tbl_70 = {};
                tbl_70.Angles = {-179, 180};
                v2["Pumpkin Launcher"] = {Offsets = {Global = CFrame.new(-0.1653, -0.9892, -0.7487, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(-0.0379, 0.0121, 0.3782, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)}, Weapon = tbl_65, Bullet = tbl_66, ObjectDamages = tbl_67, Spread = tbl_68, Recoil = tbl_69, Shake = tbl_70};
            end;
        end;
        local tbl_71 = {};
        tbl_71.AimDownSpeed = {};
        tbl_71.ReloadAnimSpeed = {0.7, 0.6, 0.78};
        tbl_71.VMMovementMults = {};
        local tbl_72 = {};
        tbl_72.Dropoff = {};
        tbl_72.HumanoidDamages = {};
        local tbl_73 = {};
        tbl_73.Benches = {};
        local tbl_74 = {};
        tbl_74.Hip = {};
        tbl_74.Aiming = {};
        tbl_74.Shooting = {};
        local tbl_75 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.5, 0.5}, Y = {0, 1}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 2522
            ]]
            return 6, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 2525
            ]]
            return -1, 0;
        end;
        tbl_75.Camera = v5;
        tbl_75.VM = {Pos = {X = {-0.2, 0.2}}, Rot = {X = {-2, 2}, Z = {-1.2, 1.2}}};
        do
            local tbl_76 = {};
            tbl_76.Angles = {-179, 180};
            v2["Military Grenade Launcher"] = {Offsets = {Global = CFrame.new(-0.1841, -0.331, -0.5153, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(0.0641, -0.9498, -0.0658, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_71, Bullet = tbl_72, ObjectDamages = tbl_73, Spread = tbl_74, Recoil = tbl_75, Shake = tbl_76};
        end;
        local tbl_77 = {};
        tbl_77.AimDownSpeed = {};
        tbl_77.VMMovementMults = {};
        local tbl_78 = {};
        tbl_78.Dropoff = {};
        tbl_78.HumanoidDamages = {};
        local tbl_79 = {};
        tbl_79.Benches = {};
        local tbl_80 = {};
        tbl_80.Hip = {};
        tbl_80.Aiming = {};
        tbl_80.Shooting = {};
        local tbl_81 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-0.5, 0.5}, Y = {0, 1}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 2667
            ]]
            return 6, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 2670
            ]]
            return -1, 0;
        end;
        tbl_81.Camera = v5;
        tbl_81.VM = {Pos = {X = {-0.2, 0.2}}, Rot = {X = {-2, 2}, Z = {-1.2, 1.2}}};
        do
            local tbl_82 = {};
            tbl_82.Angles = {-179, 180};
            v2["Salvaged Grenade Launcher"] = {Offsets = {Global = CFrame.new(-0.2028, -0.6356, -0.6213, 0.0098, 0, 1, -0.9999, 0, 0.0098, 0, -1, 0), Local = CFrame.new(0.0641, -0.8658, -0.0719, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_77, Bullet = tbl_78, ObjectDamages = tbl_79, Spread = tbl_80, Recoil = tbl_81, Shake = tbl_82};
        end;
        local tbl_83 = {};
        tbl_83.Offsets = {Global = CFrame.new(0.0119, -0.9016, -0.361, 0, 0, -1, 1, 0, 0, 0, -1, 0), Local = CFrame.new(-0.0119, 0.004, -0.462, 1, 0, 0, 0, 1, 0, 0, 0, 1)};
        tbl_83.Weapon = {AimDownSpeed = {}, ReloadAnimSpeed = {0.8280000000000001, 0.54, 0.7020000000000001}, VMMovementMults = {}};
        local tbl_84 = {};
        tbl_84.Speed = 1700;
        tbl_84.Gravity = 0.6;
        tbl_84.MaxRange = 850;
        tbl_84.Dropoff = {};
        tbl_84.HumanoidDamages = {};
        tbl_84.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.17, 0.69};
            v5.Y = {-0.99, -0.11};
            v5.Z = {-3.1, -2.11};
        end;
        tbl_84["[DEBUG]"] = v5;
        tbl_83.Bullet = tbl_84;
        tbl_83.ObjectDamages = {Benches = {}};
        tbl_83.Casing = {Velocity = {16, 18}, Offset = CFrame.Angles(0, 0, 0.5235987755982988), ExtraMoveVelocities = {-10, 13}};
        tbl_83.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_85 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-3, 3}, Y = {0, 0.5}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 2799
            ]]
            return 6.5, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 2802
            ]]
            return -1.5, 0;
        end;
        tbl_85.Camera = v5;
        tbl_85.VM = {Pos = {X = {-0.05, 0.05}}, Rot = {X = {-1, 1}, Z = {-0.5, 0.5}}};
        tbl_83.Recoil = tbl_85;
        tbl_83.Shake = {Angles = {-179, 180}};
        v2["Salvaged Pipe Rifle"] = tbl_83;
        local tbl_86 = {};
        tbl_86.Offsets = {Global = CFrame.new(-0.1934, 0.2028, -0.1084, -1, 0, 0, 0, 0, -1, 0, -1, 0), Local = CFrame.new()};
        tbl_86.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_87 = {};
        tbl_87.Speed = 2500;
        tbl_87.Gravity = 0.55;
        tbl_87.MaxRange = 1100;
        tbl_87.Dropoff = {};
        tbl_87.HumanoidDamages = {};
        tbl_87.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.1, 0.78};
            v5.Y = {-2.21, -0.25};
            v5.Z = {-6.25, -4.13};
        end;
        tbl_87["[DEBUG]"] = v5;
        tbl_86.Bullet = tbl_87;
        tbl_86.ObjectDamages = {Benches = {}};
        tbl_86.Casing = {Velocity = {12, 13}, Offset = CFrame.Angles(1.5707963267948966, 0, math.pi), ExtraMoveVelocities = {-10, 13}};
        tbl_86.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_88 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-3, 3}, Y = {0, 0.5}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 2938
            ]]
            return 8, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 2941
            ]]
            return -1.75, 0;
        end;
        tbl_88.Camera = v5;
        tbl_88.VM = {Pos = {X = {-0.06, 0.06}}, Rot = {X = {-1.2, 1.2}, Z = {-0.6, 0.6}}};
        tbl_86.Recoil = tbl_88;
        tbl_86.Shake = {Angles = {-179, 180}};
        v2["Military Barrett"] = tbl_86;
        local tbl_89 = {};
        tbl_89.Offsets = {Global = CFrame.new(-0.1551, -0.4768, -0.7609, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(0.172, -0.9079, -0.0019, 1, 0, 0, 0, 1, 0, 0, 0, 1)};
        tbl_89.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_90 = {};
        tbl_90.Speed = 2400;
        tbl_90.Gravity = 0.55;
        tbl_90.MaxRange = 1100;
        tbl_90.Dropoff = {};
        tbl_90.HumanoidDamages = {};
        tbl_90.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.12, 0.76};
            v5.Y = {-1.7, -0.04};
            v5.Z = {-5.34, -4.7};
        end;
        tbl_90["[DEBUG]"] = v5;
        tbl_89.Bullet = tbl_90;
        tbl_89.ObjectDamages = {Benches = {}};
        tbl_89.Casing = {Velocity = {12, 13}, Offset = CFrame.Angles(1.5707963267948966, 0, math.pi), ExtraMoveVelocities = {-10, 13}};
        tbl_89.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_91 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-3, 3}, Y = {0, 0.5}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 3077
            ]]
            return 7, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 3080
            ]]
            return -1.5, 0;
        end;
        tbl_91.Camera = v5;
        tbl_91.VM = {Pos = {X = {-0.06, 0.06}}, Rot = {X = {-1.2, 1.2}, Z = {-0.6, 0.6}}};
        tbl_89.Recoil = tbl_91;
        tbl_89.Shake = {Angles = {-179, 180}};
        v2["Salvaged Sniper"] = tbl_89;
        local tbl_92 = {};
        tbl_92.Offsets = {Global = CFrame.new(-0.1776, 0.0137, -0.4418, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(0.1, -0.7558, -0.094, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)};
        tbl_92.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_93 = {};
        tbl_93.Speed = 550;
        tbl_93.Gravity = 0.6;
        tbl_93.MaxRange = 200;
        tbl_93.Dropoff = {};
        tbl_93.HumanoidDamages = {};
        tbl_93.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.11, 0.49};
            v5.Y = {-0.98, -0.03};
            v5.Z = {-2.52, -2.09};
        end;
        tbl_93["[DEBUG]"] = v5;
        tbl_92.Bullet = tbl_93;
        tbl_92.ObjectDamages = {Benches = {}};
        tbl_92.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_94 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-3, 3}, Y = {0, 0.5}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 3196
            ]]
            return 6, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 3199
            ]]
            return -1, 0;
        end;
        tbl_94.Camera = v5;
        tbl_94.VM = {Pos = {X = {-0.05, 0.05}}, Rot = {X = {-1, 1}, Z = {-0.5, 0.5}}};
        tbl_92.Recoil = tbl_94;
        tbl_92.Shake = {Angles = {-179, 180}};
        v2["Salvaged Double Barrel"] = tbl_92;
        local tbl_95 = {};
        tbl_95.Offsets = {Global = CFrame.new(0.006, -0.4763, -0.696, 0, 0, -1, 1, 1e-04, 0, -0, -1, 0), Local = CFrame.new(0.096, 0.0382, -0.17, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)};
        tbl_95.Weapon = {AimDownSpeed = {}, VMMovementMults = {}};
        local tbl_96 = {};
        tbl_96.Speed = 550;
        tbl_96.Gravity = 0.6;
        tbl_96.MaxRange = 200;
        tbl_96.Dropoff = {};
        tbl_96.HumanoidDamages = {};
        tbl_96.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.08, 0.59};
            v5.Y = {-0.99, -0.06};
            v5.Z = {-2.69, -2.2};
        end;
        tbl_96["[DEBUG]"] = v5;
        tbl_95.Bullet = tbl_96;
        tbl_95.ObjectDamages = {Benches = {}};
        tbl_95.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_97 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-3, 3}, Y = {0, 0.5}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 3317
            ]]
            return 6.5, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 3320
            ]]
            return -1.5, 0;
        end;
        tbl_97.Camera = v5;
        tbl_97.VM = {Pos = {X = {-0.05, 0.05}}, Rot = {X = {-1, 1}, Z = {-0.5, 0.5}}};
        tbl_95.Recoil = tbl_97;
        tbl_95.Shake = {Angles = {-179, 180}};
        v2["Salvaged Break Action"] = tbl_95;
        local tbl_98 = {};
        tbl_98.Offsets = {Global = CFrame.new(0.015, -0.6085, -0.3974, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(0.2481, -0.0258, 0.83, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)};
        tbl_98.Weapon = {VMMovementMults = {}};
        local tbl_99 = {};
        tbl_99.Speed = 400;
        tbl_99.Gravity = 0.6;
        tbl_99.MaxRange = 100;
        tbl_99.Dropoff = {};
        tbl_99.HumanoidDamages = {};
        tbl_99.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {0.46, 0.96};
            v5.Y = {-1.1, 0};
            v5.Z = {-2.86, -2.25};
        end;
        tbl_99["[DEBUG]"] = v5;
        tbl_98.Bullet = tbl_99;
        tbl_98.ObjectDamages = {Benches = {}};
        tbl_98.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_100 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-3, 3}, Y = {0, 0.5}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 3431
            ]]
            return 8, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 3434
            ]]
            return -2, 0;
        end;
        tbl_100.Camera = v5;
        tbl_100.VM = {Pos = {X = {-0.1, 0.1}}, Rot = {X = {-1.2, 1.2}, Z = {-0.6, 0.6}}};
        tbl_98.Recoil = tbl_100;
        tbl_98.Shake = {Angles = {-179, 180}};
        v2["Salvaged Shotgun"] = tbl_98;
        local tbl_101 = {};
        tbl_101.Offsets = {Global = CFrame.new(-0.0212, -0.3769, -0.3103, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new(0.096, 0.0382, -0.17, 1, 1e-04, 1e-04, -0, 1, -0, -0, 1e-04, 1)};
        tbl_101.Weapon = {AimDownSpeed = {}, ReloadAnimSpeed = {1, 1, 1}, VMMovementMults = {}};
        local tbl_102 = {};
        tbl_102.Speed = 600;
        tbl_102.Gravity = 0.6;
        tbl_102.MaxRange = 200;
        tbl_102.Dropoff = {};
        tbl_102.HumanoidDamages = {};
        tbl_102.SoftSideMult = 2;
        v5 = v1;
        if (v5) then
            v5 = {};
            v5.X = {-0.05, 0.65};
            v5.Y = {-1.55, -0.35};
            v5.Z = {-3.09, -2.33};
        end;
        tbl_102["[DEBUG]"] = v5;
        tbl_101.Bullet = tbl_102;
        tbl_101.ObjectDamages = {Benches = {}};
        tbl_101.Casing = {Velocity = {16, 18}, Offset = CFrame.Angles(0, 0, 0.5235987755982988), ExtraMoveVelocities = {-10, 13}};
        tbl_101.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_103 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-2, 2}, Y = {0, 0.4}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 3560
            ]]
            return 5.5, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 3563
            ]]
            return -1.5, 0;
        end;
        tbl_103.Camera = v5;
        tbl_103.VM = {Pos = {X = {-0.04, 0.04}}, Rot = {X = {-0.75, 0.75}, Z = {-0.4, 0.4}}};
        tbl_101.Recoil = tbl_103;
        tbl_101.Shake = {Angles = {-179, 180}};
        v2["Military AA12"] = tbl_101;
        local tbl_104 = {};
        tbl_104.Offsets = {Global = CFrame.new(0.0119, -0.9016, -0.361, 0, 0, -1, 1, 0, 0, 0, -1, 0), Local = CFrame.new(-0.0759, 0.0181, -0.1519, 1, 0, 0, 0, 1, -0, 0, 1e-04, 1)};
        tbl_104.Weapon = {AimDownSpeed = {}, ReloadAnimSpeed = {0.83, 0.7, 0.8}, VMMovementMults = {}};
        local tbl_105 = {};
        tbl_105.Speed = 650;
        tbl_105.Gravity = 0.6;
        tbl_105.MaxRange = 200;
        tbl_105.Dropoff = {};
        tbl_105.HumanoidDamages = {};
        tbl_105.SoftSideMult = 2;
        if (v1) then
            v5 = {};
            v5.X = {-0.2, 0.62};
            v5.Y = {-1.3, -0.06};
            v5.Z = {-3.73, -2.45};
        else
            v5 = v1;
        end;
        tbl_105["[DEBUG]"] = v5;
        tbl_104.Bullet = tbl_105;
        tbl_104.ObjectDamages = {Benches = {}};
        tbl_104.Casing = {Velocity = {16, 18}, Offset = CFrame.Angles(0, 0, 0.5235987755982988), ExtraMoveVelocities = {-10, 13}};
        tbl_104.Spread = {Hip = {}, Aiming = {}, Shooting = {}};
        local tbl_106 = {};
        v5 = {};
        v5.Decay = {};
        v5.Shake = {X = {-3, 3}, Y = {0, 0.5}};
        v5.RecoilStart = function()
            --[[
              name: RecoilStart
              line: 3691
            ]]
            return 6.5, 0;
        end;
        v5.RecoilFinish = function()
            --[[
              name: RecoilFinish
              line: 3694
            ]]
            return -1.5, 0;
        end;
        tbl_106.Camera = v5;
        tbl_106.VM = {Pos = {X = {-0.05, 0.05}}, Rot = {X = {-1, 1}, Z = {-0.5, 0.5}}};
        tbl_104.Recoil = tbl_106;
        tbl_104.Shake = {Angles = {-179, 180}};
        v2["Salvaged Pump Action"] = tbl_104;
    end;
    local tbl_107 = {};
    tbl_107.AimDownSpeed = {};
    tbl_107.ThrowInfo = {SpinSpeed = {0, 0, 7.5}, ThrowCFrameOffset = CFrame.Angles(0, -1.5707963267948966, 0), LandOffset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0, -1, 0)};
    tbl_107.UsePositionTimes = {};
    tbl_107.VMMovementMults = {};
    local tbl_108 = {};
    tbl_108.MeleeChecks = {{0.6, tbl_1.Default(5, 0.2, 0.2)}, {0.8, tbl_1.Default(5, 0.2, 0.2)}, {1, tbl_1.Default(5, 0.2, 0.2)}};
    tbl_108.HumanoidDamages = {};
    tbl_108.ThrowDamages = {};
    tbl_108.Durabilities = {};
    local tbl_109 = {};
    tbl_109.Benches = {};
    tbl_109.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    tbl_109.Trees = {Desert = {}, Small = {}, Medium = {}, Giant = {}};
    tbl_109.Logs = {};
    tbl_109.Cactus = {Small = {}, Medium = {}, Large = {}};
    local tbl_110 = {};
    tbl_110.Hip = {};
    tbl_110.Aiming = {};
    local tbl_111 = {};
    tbl_111.Angles = {-75, 75};
    v2["Stone Hatchet"] = {
        Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(0.0429758094, -0.533661604, -0.128225714, 1, -8.40779079e-45, 8.40779079e-45, 8.40779079e-45, 1, -8.40779079e-45, -8.40779079e-45, 8.40779079e-45, 1), LocalUse = CFrame.new(-0.538181007, -0.69784683, -0.138619661, 0.985808969, -0.150060594, 0.0749957785, 0.162847772, 0.963356495, -0.213055477, -0.0402772278, 0.222248882, 0.974134088)},
        Weapon = tbl_107,
        Melee = tbl_108,
        ObjectDamages = tbl_109,
        Spread = tbl_110,
        Shake = tbl_111
    };
    local tbl_112 = {};
    tbl_112.AimDownSpeed = {};
    tbl_112.ThrowInfo = {SpinSpeed = {0, 0, 7.5}, ThrowCFrameOffset = CFrame.Angles(0, -1.5707963267948966, 0), LandOffset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0.5, -0.75, 0)};
    tbl_112.UsePositionTimes = {};
    tbl_112.VMMovementMults = {};
    local tbl_113 = {};
    tbl_113.MeleeChecks = {{0.6, tbl_1.Default(5, 0.2, 0.2)}, {0.8, tbl_1.Default(5, 0.2, 0.2)}, {1, tbl_1.Default(5, 0.2, 0.2)}};
    tbl_113.HumanoidDamages = {};
    tbl_113.ThrowDamages = {};
    tbl_113.Durabilities = {};
    local tbl_114 = {};
    tbl_114.Benches = {};
    tbl_114.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    tbl_114.Trees = {Desert = {}, Small = {}, Medium = {}, Giant = {}};
    tbl_114.Logs = {};
    tbl_114.Cactus = {Small = {}, Medium = {}, Large = {}};
    local tbl_115 = {};
    tbl_115.Hip = {};
    tbl_115.Aiming = {};
    local tbl_116 = {};
    tbl_116.Angles = {-75, 75};
    v2["Iron Shard Hatchet"] = {
        Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(0.0429758094, -0.533661604, -0.128225714, 1, -8.40779079e-45, 8.40779079e-45, 8.40779079e-45, 1, -8.40779079e-45, -8.40779079e-45, 8.40779079e-45, 1), LocalUse = CFrame.new(-0.538181007, -0.69784683, -0.138619661, 0.985808969, -0.150060594, 0.0749957785, 0.162847772, 0.963356495, -0.213055477, -0.0402772278, 0.222248882, 0.974134088)},
        Weapon = tbl_112,
        Melee = tbl_113,
        ObjectDamages = tbl_114,
        Spread = tbl_115,
        Shake = tbl_116
    };
    local tbl_117 = {};
    tbl_117.AimDownSpeed = {};
    tbl_117.ThrowInfo = {SpinSpeed = {-6, 0, 0}, ThrowCFrameOffset = CFrame.Angles(0, 0, 0), LandOffset = CFrame.Angles(0.5235987755982988, math.pi, 0) * CFrame.new(0, -1.1, 0.5)};
    tbl_117.UsePositionTimes = {};
    tbl_117.VMMovementMults = {};
    local tbl_118 = {};
    tbl_118.MeleeChecks = {{0.6, tbl_1.Default(5.5, 0.2, 0.2)}, {0.8, tbl_1.Default(5.5, 0.2, 0.2)}, {1, tbl_1.Default(5.5, 0.2, 0.2)}};
    tbl_118.HumanoidDamages = {};
    tbl_118.ThrowDamages = {};
    tbl_118.Durabilities = {};
    local tbl_119 = {};
    tbl_119.Benches = {};
    tbl_119.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    tbl_119.Trees = {Desert = {}, Small = {}, Medium = {}, Giant = {}};
    tbl_119.Logs = {};
    tbl_119.Cactus = {Small = {}, Medium = {}, Large = {}};
    local tbl_120 = {};
    tbl_120.Hip = {};
    tbl_120.Aiming = {};
    local tbl_121 = {};
    tbl_121.Angles = {-75, 75};
    v2["Steel Axe"] = {Offsets = {Global = CFrame.new(-0.0097, -0.1736, -0.8023, 1, 1e-04, -0, 1e-04, -0, 1, 1e-04, -1, -0), Local = CFrame.new(-0.3259, -0.0815, -0.0937, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.238, -0.0798, -0.6528, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_117, Melee = tbl_118, ObjectDamages = tbl_119, Spread = tbl_120, Shake = tbl_121};
    do
        local tbl_122 = {};
        tbl_122.UsePositionTimes = {};
        tbl_122.VMMovementMults = {};
        local tbl_123 = {};
        tbl_123.MeleeChecks = {{0.6, tbl_1.Default(6.5, 0.2, 0.2)}, {0.8, tbl_1.Default(6.5, 0.2, 0.2)}, {1, tbl_1.Default(6.5, 0.2, 0.2)}};
        tbl_123.HumanoidDamages = {};
        tbl_123.Durabilities = {};
        local tbl_124 = {};
        tbl_124.Benches = {};
        tbl_124.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
        tbl_124.Trees = {Desert = {}, Small = {}, Medium = {}, Giant = {}};
        tbl_124.Logs = {};
        tbl_124.Cactus = {Small = {}, Medium = {}, Large = {}};
        local tbl_125 = {};
        tbl_125.Hip = {};
        local tbl_126 = {};
        tbl_126.Angles = {-179, 179};
        v2.Chainsaw = {Offsets = {Global = CFrame.new(-0.2936, -0.1131, -0.3604, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(-0.284, -0.6319, -0.5619, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.284, -0.6319, -0.5619, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_122, Melee = tbl_123, ObjectDamages = tbl_124, Spread = tbl_125, Shake = tbl_126};
    end;
    local tbl_127 = {};
    tbl_127.AimDownSpeed = {};
    tbl_127.ThrowInfo = {SpinSpeed = {0, 0, 7.5}, ThrowCFrameOffset = CFrame.Angles(0, -1.5707963267948966, 0), LandOffset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0, -1, 0)};
    tbl_127.UsePositionTimes = {};
    tbl_127.VMMovementMults = {};
    local tbl_128 = {};
    tbl_128.MeleeChecks = {{0.6, tbl_1.Default(5, 0.2, 0.2)}, {0.8, tbl_1.Default(5, 0.2, 0.2)}, {1, tbl_1.Default(5, 0.2, 0.2)}};
    tbl_128.HumanoidDamages = {};
    tbl_128.ThrowDamages = {};
    tbl_128.Durabilities = {};
    local tbl_129 = {};
    tbl_129.Benches = {};
    tbl_129.Nodes = {Stone = {}, Metal = {}, Phosphate = {}};
    tbl_129.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    local tbl_130 = {};
    tbl_130.Hip = {};
    tbl_130.Aiming = {};
    local tbl_131 = {};
    tbl_131.Angles = {-75, 75};
    v2["Stone Pickaxe"] = {
        Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(0.0429758094, -0.533661604, -0.128225714, 1, -8.40779079e-45, 8.40779079e-45, 8.40779079e-45, 1, -8.40779079e-45, -8.40779079e-45, 8.40779079e-45, 1), LocalUse = CFrame.new(-0.538181007, -0.69784683, -0.138619661, 0.985808969, -0.150060594, 0.0749957785, 0.162847772, 0.963356495, -0.213055477, -0.0402772278, 0.222248882, 0.974134088)},
        Weapon = tbl_127,
        Melee = tbl_128,
        ObjectDamages = tbl_129,
        Spread = tbl_130,
        Shake = tbl_131
    };
    local tbl_132 = {};
    tbl_132.AimDownSpeed = {};
    tbl_132.ThrowInfo = {SpinSpeed = {0, 0, 7.5}, ThrowCFrameOffset = CFrame.Angles(0, -1.5707963267948966, 0), LandOffset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0.5, -0.75, 0)};
    tbl_132.UsePositionTimes = {};
    tbl_132.VMMovementMults = {};
    local tbl_133 = {};
    tbl_133.MeleeChecks = {{0.6, tbl_1.Default(5, 0.2, 0.2)}, {0.8, tbl_1.Default(5, 0.2, 0.2)}, {1, tbl_1.Default(5, 0.2, 0.2)}};
    tbl_133.HumanoidDamages = {};
    tbl_133.ThrowDamages = {};
    tbl_133.Durabilities = {};
    local tbl_134 = {};
    tbl_134.Benches = {};
    tbl_134.Nodes = {Stone = {}, Metal = {}, Phosphate = {}};
    tbl_134.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    local tbl_135 = {};
    tbl_135.Hip = {};
    tbl_135.Aiming = {};
    local tbl_136 = {};
    tbl_136.Angles = {-75, 75};
    v2["Iron Shard Pickaxe"] = {
        Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(0.0429758094, -0.533661604, -0.128225714, 1, -8.40779079e-45, 8.40779079e-45, 8.40779079e-45, 1, -8.40779079e-45, -8.40779079e-45, 8.40779079e-45, 1), LocalUse = CFrame.new(-0.538181007, -0.69784683, -0.138619661, 0.985808969, -0.150060594, 0.0749957785, 0.162847772, 0.963356495, -0.213055477, -0.0402772278, 0.222248882, 0.974134088)},
        Weapon = tbl_132,
        Melee = tbl_133,
        ObjectDamages = tbl_134,
        Spread = tbl_135,
        Shake = tbl_136
    };
    local tbl_137 = {};
    tbl_137.AimDownSpeed = {};
    tbl_137.ThrowInfo = {SpinSpeed = {0, 0, 7.5}, ThrowCFrameOffset = CFrame.Angles(0, -1.5707963267948966, 0), LandOffset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0.5, -0.75, 0)};
    tbl_137.UsePositionTimes = {};
    tbl_137.VMMovementMults = {};
    local tbl_138 = {};
    tbl_138.MeleeChecks = {{0.6, tbl_1.Default(5, 0.2, 0.2)}, {0.8, tbl_1.Default(5, 0.2, 0.2)}, {1, tbl_1.Default(5, 0.2, 0.2)}};
    tbl_138.HumanoidDamages = {};
    tbl_138.ThrowDamages = {};
    tbl_138.Durabilities = {};
    local tbl_139 = {};
    tbl_139.Benches = {};
    tbl_139.Nodes = {Stone = {}, Metal = {}, Phosphate = {}};
    tbl_139.Logs = {};
    tbl_139.Cactus = {Small = {}, Medium = {}, Large = {}};
    tbl_139.Trees = {Desert = {}, Small = {}, Medium = {}, Giant = {}};
    tbl_139.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    local tbl_140 = {};
    tbl_140.Hip = {};
    tbl_140.Aiming = {};
    local tbl_141 = {};
    tbl_141.Angles = {-75, 75};
    v2["Bone Tool"] = {
        Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(0.0429758094, -0.533661604, -0.128225714, 1, -8.40779079e-45, 8.40779079e-45, 8.40779079e-45, 1, -8.40779079e-45, -8.40779079e-45, 8.40779079e-45, 1), LocalUse = CFrame.new(-0.538181007, -0.69784683, -0.138619661, 0.985808969, -0.150060594, 0.0749957785, 0.162847772, 0.963356495, -0.213055477, -0.0402772278, 0.222248882, 0.974134088)},
        Weapon = tbl_137,
        Melee = tbl_138,
        ObjectDamages = tbl_139,
        Spread = tbl_140,
        Shake = tbl_141
    };
    local tbl_142 = {};
    tbl_142.AimDownSpeed = {};
    tbl_142.ThrowInfo = {SpinSpeed = {0, 0, 7.5}, ThrowCFrameOffset = CFrame.Angles(0, -1.5707963267948966, 0), LandOffset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0.5, -0.75, 0)};
    tbl_142.UsePositionTimes = {};
    tbl_142.VMMovementMults = {};
    local tbl_143 = {};
    tbl_143.MeleeChecks = {{0.6, tbl_1.Default(5, 0.2, 0.2)}, {0.8, tbl_1.Default(5, 0.2, 0.2)}, {1, tbl_1.Default(5, 0.2, 0.2)}};
    tbl_143.HumanoidDamages = {};
    tbl_143.ThrowDamages = {};
    tbl_143.Durabilities = {};
    local tbl_144 = {};
    tbl_144.Benches = {};
    tbl_144.Nodes = {Stone = {}, Metal = {}, Phosphate = {}};
    tbl_144.Logs = {};
    tbl_144.Cactus = {Small = {}, Medium = {}, Large = {}};
    tbl_144.Trees = {Desert = {}, Small = {}, Medium = {}, Giant = {}};
    tbl_144.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    local tbl_145 = {};
    tbl_145.Hip = {};
    tbl_145.Aiming = {};
    local tbl_146 = {};
    tbl_146.Angles = {-75, 75};
    v2["Candy Cane"] = {
        Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(0.0429758094, -0.533661604, -0.128225714, 1, -8.40779079e-45, 8.40779079e-45, 8.40779079e-45, 1, -8.40779079e-45, -8.40779079e-45, 8.40779079e-45, 1), LocalUse = CFrame.new(-0.538181007, -0.69784683, -0.138619661, 0.985808969, -0.150060594, 0.0749957785, 0.162847772, 0.963356495, -0.213055477, -0.0402772278, 0.222248882, 0.974134088)},
        Weapon = tbl_142,
        Melee = tbl_143,
        ObjectDamages = tbl_144,
        Spread = tbl_145,
        Shake = tbl_146
    };
    local tbl_147 = {};
    tbl_147.AimDownSpeed = {};
    tbl_147.ThrowInfo = {SpinSpeed = {0, 0, 7.5}, ThrowCFrameOffset = CFrame.Angles(0, -1.5707963267948966, 0), LandOffset = CFrame.Angles(0, 1.5707963267948966, 0) * CFrame.new(0.5, -0.75, 0)};
    tbl_147.UsePositionTimes = {};
    tbl_147.VMMovementMults = {};
    local tbl_148 = {};
    tbl_148.MeleeChecks = {{0.6, tbl_1.Default(5, 0.2, 0.2)}, {0.8, tbl_1.Default(5, 0.2, 0.2)}, {1, tbl_1.Default(5, 0.2, 0.2)}};
    tbl_148.HumanoidDamages = {};
    tbl_148.ThrowDamages = {};
    tbl_148.Durabilities = {};
    local tbl_149 = {};
    tbl_149.Benches = {};
    tbl_149.Nodes = {Stone = {}, Metal = {}, Phosphate = {}};
    tbl_149.Logs = {};
    tbl_149.Cactus = {Small = {}, Medium = {}, Large = {}};
    tbl_149.Trees = {Desert = {}, Small = {}, Medium = {}, Giant = {}};
    tbl_149.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    local tbl_150 = {};
    tbl_150.Hip = {};
    tbl_150.Aiming = {};
    local tbl_151 = {};
    tbl_151.Angles = {-75, 75};
    v2["Carrot Blade"] = {
        Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(0.0429758094, -0.533661604, -0.128225714, 1, -8.40779079e-45, 8.40779079e-45, 8.40779079e-45, 1, -8.40779079e-45, -8.40779079e-45, 8.40779079e-45, 1), LocalUse = CFrame.new(-0.538181007, -0.69784683, -0.138619661, 0.985808969, -0.150060594, 0.0749957785, 0.162847772, 0.963356495, -0.213055477, -0.0402772278, 0.222248882, 0.974134088)},
        Weapon = tbl_147,
        Melee = tbl_148,
        ObjectDamages = tbl_149,
        Spread = tbl_150,
        Shake = tbl_151
    };
    local tbl_152 = {};
    tbl_152.AimDownSpeed = {};
    tbl_152.ThrowInfo = {SpinSpeed = {-6, 0, 0}, ThrowCFrameOffset = CFrame.Angles(0, 0, 0), LandOffset = CFrame.Angles(0.5235987755982988, math.pi, 0) * CFrame.new(0, -1.1, 0.5)};
    tbl_152.UsePositionTimes = {};
    tbl_152.VMMovementMults = {};
    local tbl_153 = {};
    tbl_153.MeleeChecks = {{0.6, tbl_1.Default(5.5, 0.2, 0.2)}, {0.8, tbl_1.Default(5.5, 0.2, 0.2)}, {1, tbl_1.Default(5.5, 0.2, 0.2)}};
    tbl_153.HumanoidDamages = {};
    tbl_153.ThrowDamages = {};
    tbl_153.Durabilities = {};
    local tbl_154 = {};
    tbl_154.Benches = {};
    tbl_154.Nodes = {Stone = {}, Metal = {}, Phosphate = {}};
    tbl_154.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    local tbl_155 = {};
    tbl_155.Hip = {};
    tbl_155.Aiming = {};
    local tbl_156 = {};
    tbl_156.Angles = {-75, 75};
    v2["Steel Pickaxe"] = {Offsets = {Global = CFrame.new(-0.0097, -0.1736, -0.8023, 1, 1e-04, -0, 1e-04, -0, 1, 1e-04, -1, -0), Local = CFrame.new(-0.238, -0.0735, 0.1723, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.238, -0.0798, -0.6528, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_152, Melee = tbl_153, ObjectDamages = tbl_154, Spread = tbl_155, Shake = tbl_156};
    do
        local tbl_157 = {};
        tbl_157.UsePositionTimes = {};
        tbl_157.VMMovementMults = {};
        local tbl_158 = {};
        tbl_158.MeleeChecks = {{0.6, tbl_1.Default(6.5, 0.2, 0.2)}, {0.8, tbl_1.Default(6.5, 0.2, 0.2)}, {1, tbl_1.Default(6.5, 0.2, 0.2)}};
        tbl_158.HumanoidDamages = {};
        tbl_158.Durabilities = {};
        local tbl_159 = {};
        tbl_159.Benches = {};
        tbl_159.Nodes = {Stone = {}, Metal = {}, Phosphate = {}};
        tbl_159.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
        local tbl_160 = {};
        tbl_160.Hip = {};
        local tbl_161 = {};
        tbl_161.Angles = {-179, 179};
        v2["Mining Drill"] = {Offsets = {Global = CFrame.new(-0.0326, -0.6497, -0.0256, 1e-04, 0, 1, -1, 0, 1e-04, 0, -1, 0), Local = CFrame.new(-0.002, -0.6619, 0.4041, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.1619, -0.6058, 0.2282, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_157, Melee = tbl_158, ObjectDamages = tbl_159, Spread = tbl_160, Shake = tbl_161};
    end;
    do
        local tbl_162 = {};
        tbl_162.AimDownSpeed = {};
        tbl_162.ThrowInfo = {SpinSpeed = {0, 0, 0}, ThrowCFrameOffset = CFrame.Angles(0, math.pi, 0), LandOffset = CFrame.new(0, 0, -1.5)};
        tbl_162.UsePositionTimes = {};
        tbl_162.VMMovementMults = {};
        local tbl_163 = {};
        tbl_163.MeleeChecks = {{0.6, tbl_1.Default(7.5, 0.2, 0.2)}, {0.8, tbl_1.Default(7.5, 0.2, 0.2)}, {1, tbl_1.Default(7.5, 0.2, 0.2)}};
        tbl_163.HumanoidDamages = {};
        tbl_163.ThrowDamages = {};
        tbl_163.Durabilities = {};
        local tbl_164 = {};
        tbl_164.Benches = {};
        local tbl_165 = {};
        tbl_165.Hip = {};
        tbl_165.Aiming = {};
        local tbl_166 = {};
        tbl_166.Angles = {-75, 75};
        v2["Wooden Spear"] = {
            Offsets = {
                Global = CFrame.new(-0.0196, -0.1961, -0.0096, 0, 1e-04, 1, 0, 1, 0, -0.9999, 1e-04, 0),
                Local = CFrame.new(-0.7787, -0.1986, 0.2951, 0.9875, -0.1576, -0.0094, 0.1556, 0.981, -0.1161, 0.0276, 0.1133, 0.9932),
                LocalUse = CFrame.new(-0.8928442, -0.242026985, 0.514454186, 0.911695421, -0.410821944, 0.00587406289, 0.402106851, 0.889236391, -0.218097121, 0.0843757689, 0.201200515, 0.975907624),
                Aim = CFrame.new(-0.551757753, -0.177877635, 0.30824694, 0.987818241, -0.146761477, -0.0514304191, 0.143076792, 0.987271965, -0.069209449, 0.0609331839, 0.0610083342, 0.996260107)
            },
            Weapon = tbl_162,
            Melee = tbl_163,
            ObjectDamages = tbl_164,
            Spread = tbl_165,
            Shake = tbl_166
        };
    end;
    local tbl_167 = {};
    tbl_167.AimDownSpeed = {};
    tbl_167.ThrowInfo = {SpinSpeed = {0, 0, 0}, ThrowCFrameOffset = CFrame.Angles(0, math.pi, 0), LandOffset = CFrame.new(0, 0, -1.5)};
    tbl_167.UsePositionTimes = {};
    tbl_167.VMMovementMults = {};
    local tbl_168 = {};
    tbl_168.MeleeChecks = {{0.6, tbl_1.Default(7.5, 0.2, 0.2)}, {0.8, tbl_1.Default(7.5, 0.2, 0.2)}, {1, tbl_1.Default(7.5, 0.2, 0.2)}};
    tbl_168.HumanoidDamages = {};
    tbl_168.ThrowDamages = {};
    tbl_168.Durabilities = {};
    local tbl_169 = {};
    tbl_169.Benches = {};
    local tbl_170 = {};
    tbl_170.Hip = {};
    tbl_170.Aiming = {};
    local tbl_171 = {};
    tbl_171.Angles = {-75, 75};
    v2["Stone Spear"] = {
        Offsets = {
            Global = CFrame.new(-0.0196, -0.1961, -0.0096, 0, 1e-04, 1, 0, 1, 0, -0.9999, 1e-04, 0),
            Local = CFrame.new(-0.7787, -0.1986, 0.2951, 0.9875, -0.1576, -0.0094, 0.1556, 0.981, -0.1161, 0.0276, 0.1133, 0.9932),
            LocalUse = CFrame.new(-0.8928442, -0.242026985, 0.514454186, 0.911695421, -0.410821944, 0.00587406289, 0.402106851, 0.889236391, -0.218097121, 0.0843757689, 0.201200515, 0.975907624),
            Aim = CFrame.new(-0.551757753, -0.177877635, 0.30824694, 0.987818241, -0.146761477, -0.0514304191, 0.143076792, 0.987271965, -0.069209449, 0.0609331839, 0.0610083342, 0.996260107)
        },
        Weapon = tbl_167,
        Melee = tbl_168,
        ObjectDamages = tbl_169,
        Spread = tbl_170,
        Shake = tbl_171
    };
    local tbl_172 = {};
    tbl_172.AimDownSpeed = {};
    tbl_172.ThrowInfo = {SpinSpeed = {-6, 0, 0}, ThrowCFrameOffset = CFrame.Angles(0, 0, 0), LandOffset = CFrame.Angles(0.5235987755982988, math.pi, 0) * CFrame.new(0, -1.1, 0.5)};
    tbl_172.UsePositionTimes = {};
    tbl_172.VMMovementMults = {};
    local tbl_173 = {};
    tbl_173.MeleeChecks = {{0.6, tbl_1.Default(5.5, 0.2, 0.2)}, {0.8, tbl_1.Default(5.5, 0.2, 0.2)}, {1, tbl_1.Default(5.5, 0.2, 0.2)}};
    tbl_173.HumanoidDamages = {};
    tbl_173.ThrowDamages = {};
    tbl_173.Durabilities = {};
    local tbl_174 = {};
    tbl_174.Benches = {};
    tbl_174.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    local tbl_175 = {};
    tbl_175.Hip = {};
    tbl_175.Aiming = {};
    local tbl_176 = {};
    tbl_176.Angles = {-75, 75};
    v2["Halloween Scythe"] = {Offsets = {Global = CFrame.new(-0.0097, -0.1736, -0.8023, 1, 1e-04, -0, 1e-04, -0, 1, 1e-04, -1, -0), Local = CFrame.new(-0.238, -0.0735, 0.1723, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.238, -0.0798, -0.6528, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_172, Melee = tbl_173, ObjectDamages = tbl_174, Spread = tbl_175, Shake = tbl_176};
    local tbl_177 = {};
    tbl_177.AimDownSpeed = {};
    tbl_177.ThrowInfo = {SpinSpeed = {0, 0, 10}, ThrowCFrameOffset = CFrame.Angles(0, 0.7853981633974483, 0), LandOffset = CFrame.new(0, 0, -0.5)};
    tbl_177.UsePositionTimes = {};
    tbl_177.VMMovementMults = {};
    local tbl_178 = {};
    tbl_178.MeleeChecks = {{0.6, tbl_1.Default(4.5, 0.2, 0.2)}, {0.8, tbl_1.Default(4.5, 0.2, 0.2)}, {1, tbl_1.Default(4.5, 0.2, 0.2)}};
    tbl_178.HumanoidDamages = {};
    tbl_178.ThrowDamages = {};
    tbl_178.Durabilities = {};
    local tbl_179 = {};
    tbl_179.Benches = {};
    tbl_179.Nodes = {Stone = {}, Metal = {}, Phosphate = {}};
    tbl_179.Trees = {Desert = {}, Small = {}, Medium = {}, Giant = {}};
    tbl_179.Logs = {};
    tbl_179.Cactus = {Small = {}, Medium = {}, Large = {}};
    tbl_179.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    local tbl_180 = {};
    tbl_180.Hip = {};
    tbl_180.Aiming = {};
    local tbl_181 = {};
    tbl_181.Angles = {-75, 75};
    v2.Boulder = {Offsets = {Global = CFrame.new(-0.0126, -0.3809, -0.0042, -1, 0, -0, 0, 1, 0, 1e-04, 0, -1), Local = CFrame.new(-0.271, -0.0755, -0.3162, 1, -0, 1e-04, 1e-04, 1, -0, -0, 1e-04, 1), LocalUse = CFrame.new(-0.193, 0.4544, -0.1361, 1, -0, 1e-04, 1e-04, 1, -0, -0, 1e-04, 1)}, Weapon = tbl_177, Melee = tbl_178, ObjectDamages = tbl_179, Spread = tbl_180, Shake = tbl_181};
    local tbl_182 = {};
    tbl_182.AimDownSpeed = {};
    tbl_182.ThrowInfo = {SpinSpeed = {0, 0, -7.5}, ThrowCFrameOffset = CFrame.Angles(math.pi, 1.5707963267948966, 0), LandOffset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 1.1, 0)};
    tbl_182.UsePositionTimes = {};
    tbl_182.VMMovementMults = {};
    local tbl_183 = {};
    tbl_183.MeleeChecks = {{0.6, tbl_1.Default(6, 0.2, 0.2)}, {0.8, tbl_1.Default(6, 0.2, 0.2)}, {1, tbl_1.Default(6, 0.2, 0.2)}};
    tbl_183.HumanoidDamages = {};
    tbl_183.Durabilities = {};
    tbl_183.ThrowDamages = {};
    local tbl_184 = {};
    tbl_184.Benches = {};
    local tbl_185 = {};
    tbl_185.Hip = {};
    tbl_185.Aiming = {};
    local tbl_186 = {};
    tbl_186.Angles = {-75, 75};
    v2["Steel Shovel"] = {Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(-0.046, -0.27, -0.0599, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.0799, -0.0439, -0.06, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_182, Melee = tbl_183, ObjectDamages = tbl_184, Spread = tbl_185, Shake = tbl_186};
    local tbl_187 = {};
    tbl_187.AimDownSpeed = {};
    tbl_187.ThrowInfo = {SpinSpeed = {0, 0, -7.5}, ThrowCFrameOffset = CFrame.Angles(math.pi, 1.5707963267948966, 0), LandOffset = CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.65, 0)};
    tbl_187.UsePositionTimes = {};
    tbl_187.VMMovementMults = {};
    local tbl_188 = {};
    tbl_188.MeleeChecks = {{0.6, tbl_1.Default(6, 0.2, 0.2)}, {0.8, tbl_1.Default(6, 0.2, 0.2)}, {1, tbl_1.Default(6, 0.2, 0.2)}};
    tbl_188.HumanoidDamages = {};
    tbl_188.Durabilities = {};
    tbl_188.ThrowDamages = {};
    local tbl_189 = {};
    tbl_189.Benches = {};
    local tbl_190 = {};
    tbl_190.Hip = {};
    tbl_190.Aiming = {};
    local tbl_191 = {};
    tbl_191.Angles = {-75, 75};
    v2["Salvaged Shovel"] = {Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(-0.046, -0.27, -0.0599, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.0799, -0.0439, -0.06, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_187, Melee = tbl_188, ObjectDamages = tbl_189, Spread = tbl_190, Shake = tbl_191};
    do
        local tbl_192 = {};
        tbl_192.UsePositionTimes = {};
        tbl_192.VMMovementMults = {};
        local tbl_193 = {};
        tbl_193.MeleeChecks = {{0.6, tbl_1.Default(6, 0.2, 0.2)}, {0.8, tbl_1.Default(6, 0.2, 0.2)}, {1, tbl_1.Default(6, 0.2, 0.2)}};
        tbl_193.HumanoidDamages = {};
        local tbl_194 = {};
        tbl_194.Benches = {};
        local tbl_195 = {};
        tbl_195.Hip = {};
        local tbl_196 = {};
        tbl_196.Angles = {-75, 75};
        v2["ez shovel"] = {Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(-0.046, -0.27, -0.0599, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.0799, -0.0439, -0.06, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_192, Melee = tbl_193, ObjectDamages = tbl_194, Spread = tbl_195, Shake = tbl_196};
    end;
    local tbl_197 = {};
    tbl_197.UsePositionTimes = {};
    tbl_197.VMMovementMults = {};
    local tbl_198 = {};
    tbl_198.MeleeChecks = {{0.6, tbl_1.Default(100, 0.2, 0.2)}, {0.8, tbl_1.Default(100, 0.2, 0.2)}, {1, tbl_1.Default(100, 0.2, 0.2)}};
    tbl_198.HumanoidDamages = {};
    local tbl_199 = {};
    tbl_199.Benches = {};
    local tbl_200 = {};
    tbl_200.Hip = {};
    v2["Admin Tool"] = {Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(-0.046, -0.27, -0.0599, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.0799, -0.0439, -0.06, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_197, Melee = tbl_198, ObjectDamages = tbl_199, Spread = tbl_200};
    local tbl_201 = {};
    tbl_201.AimDownSpeed = {};
    tbl_201.ThrowInfo = {SpinSpeed = {-7, 0, 0}, ThrowCFrameOffset = CFrame.Angles(1.5707963267948966, 0, 0), LandOffset = CFrame.Angles(2.6179938779914944, 0, 0) * CFrame.new(0, 0, 1.2)};
    tbl_201.UsePositionTimes = {};
    tbl_201.VMMovementMults = {};
    local tbl_202 = {};
    tbl_202.MeleeChecks = {{0.6, tbl_1.Default(6.5, 0.2, 0.2)}, {0.8, tbl_1.Default(6.5, 0.2, 0.2)}, {1, tbl_1.Default(6.5, 0.2, 0.2)}};
    tbl_202.HumanoidDamages = {};
    tbl_202.Durabilities = {};
    tbl_202.ThrowDamages = {};
    local tbl_203 = {};
    tbl_203.Benches = {};
    tbl_203.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    tbl_203.Cactus = {Small = {}, Medium = {}, Large = {}};
    local tbl_204 = {};
    tbl_204.Hip = {};
    tbl_204.Aiming = {};
    local tbl_205 = {};
    tbl_205.Angles = {-75, 75};
    v2["Saw Bat"] = {Offsets = {Global = CFrame.new(0.0056, -0.1169, -1.3109, 1, 0, 0, 0, 1, 0, 0, 0, 1), Local = CFrame.new(-0.046, -0.27, -0.0599, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.0799, -0.0439, -0.06, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_201, Melee = tbl_202, ObjectDamages = tbl_203, Spread = tbl_204, Shake = tbl_205};
    local tbl_206 = {};
    tbl_206.AimDownSpeed = {};
    tbl_206.ThrowInfo = {SpinSpeed = {-7.5, 0, 0}, ThrowCFrameOffset = CFrame.Angles(1.5707963267948966, 0, 0), LandOffset = CFrame.Angles(2.6179938779914944, 0, 0) * CFrame.new(0, 0, 1.2)};
    tbl_206.UsePositionTimes = {};
    tbl_206.VMMovementMults = {};
    local tbl_207 = {};
    tbl_207.MeleeChecks = {{0.6, tbl_1.Default(5.5, 0.2, 0.2)}, {0.8, tbl_1.Default(5.5, 0.2, 0.2)}, {1, tbl_1.Default(5.5, 0.2, 0.2)}};
    tbl_207.HumanoidDamages = {};
    tbl_207.Durabilities = {};
    tbl_207.ThrowDamages = {};
    local tbl_208 = {};
    tbl_208.Benches = {};
    tbl_208.Animals = {PREFAB_ANIMAL_DEER = {}, PREFAB_ANIMAL_WOLF = {}, PREFAB_ANIMAL_WILDBOAR = {}};
    tbl_208.Trees = {Desert = {}, Small = {}, Medium = {}, Giant = {}};
    tbl_208.Logs = {};
    tbl_208.Cactus = {Small = {}, Medium = {}, Large = {}};
    local tbl_209 = {};
    tbl_209.Hip = {};
    tbl_209.Aiming = {};
    local tbl_210 = {};
    tbl_210.Angles = {-75, 75};
    v2.Machete = {Offsets = {Global = CFrame.new(0.0277, -0.1464, -1.0165, 1, 0, 0, 0, 1, 0, 0, 0, 1), GlobalOni = CFrame.new(-0.0225, -0.142, -1.2887, 0, 0, 1, -1, 0, 0, 0, -1, 0), Local = CFrame.new(-0.04, -0.0093, -0.2099, 1, 0, 0, 0, 1, 0, 0, 0, 1), LocalUse = CFrame.new(-0.0799, -0.0439, -0.06, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_206, Melee = tbl_207, ObjectDamages = tbl_208, Spread = tbl_209, Shake = tbl_210};
    v2.Blueprint = {Offsets = {Global = CFrame.new(-2e-04, 3e-04, 5e-04, 1e-04, 0, -1, 0, 1, 0, 1, 0, 1e-04), Local = CFrame.new()}};
    v3 = {};
    v3.UsePositionTimes = {};
    v3.VMMovementMults = {};
    v4 = {};
    local tbl_211 = {0.6, tbl_1.Default(10, 0.2, 0.2)};
    local tbl_212 = {0.8, tbl_1.Default(10, 0.2, 0.2)};
    v4.MeleeChecks = {tbl_211, tbl_212, {1, tbl_1.Default(10, 0.2, 0.2)}};
end;
local tbl_213 = {};
tbl_213.Hip = {};
v2.Hammer = {
    Offsets = {Global = CFrame.new(0.128, -0.3583, -0.6082, 0, 0, -0.9999, 0.9136, 0.4068, 0, 0.4068, -0.9135, 0), Local = CFrame.new(0.0429758094, -0.533661604, -0.128225714, 1, -8.40779079e-45, 8.40779079e-45, 8.40779079e-45, 1, -8.40779079e-45, -8.40779079e-45, 8.40779079e-45, 1), LocalUse = CFrame.new(-0.538181007, -0.69784683, -0.138619661, 0.985808969, -0.150060594, 0.0749957785, 0.162847772, 0.963356495, -0.213055477, -0.0402772278, 0.222248882, 0.974134088)},
    Weapon = v3,
    Melee = v4,
    Spread = tbl_213
};
local tbl_214 = {};
tbl_214.VMMovementMults = {};
local tbl_215 = {};
tbl_215.Hip = {};
v2.Lighter = {Offsets = {Global = CFrame.new(-0.0058, -0.2429, -0.3194, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(), LocalLantern = CFrame.new(0.5221, 0, -0.054, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_214, Spread = tbl_215};
local tbl_216 = {};
tbl_216.VMMovementMults = {};
local tbl_217 = {};
tbl_217.Hip = {};
v2["Yellow Keycard"] = {Offsets = {Global = CFrame.new(-0.164, -0.2533, -0.3431, 1, 0, 1e-04, 0, 1, 0, -0, 0, 1), Local = CFrame.new()}, Weapon = tbl_216, Spread = tbl_217};
local tbl_218 = {};
tbl_218.VMMovementMults = {};
local tbl_219 = {};
tbl_219.Hip = {};
v2["Purple Keycard"] = {Offsets = {Global = CFrame.new(-0.164, -0.2533, -0.3431, 1, 0, 1e-04, 0, 1, 0, -0, 0, 1), Local = CFrame.new()}, Weapon = tbl_218, Spread = tbl_219};
local tbl_220 = {};
tbl_220.VMMovementMults = {};
local tbl_221 = {};
tbl_221.Hip = {};
v2["Pink Keycard"] = {Offsets = {Global = CFrame.new(-0.164, -0.2533, -0.3431, 1, 0, 1e-04, 0, 1, 0, -0, 0, 1), Local = CFrame.new()}, Weapon = tbl_220, Spread = tbl_221};
local tbl_222 = {};
tbl_222.VMMovementMults = {};
local tbl_223 = {};
tbl_223.Hip = {};
v2["Red Keycard"] = {Offsets = {Global = CFrame.new(-0.164, -0.2533, -0.3431, 1, 0, 1e-04, 0, 1, 0, -0, 0, 1), Local = CFrame.new()}, Weapon = tbl_222, Spread = tbl_223};
local tbl_224 = {};
tbl_224.VMMovementMults = {};
local tbl_225 = {};
tbl_225.Hip = {};
v2["Black Keycard"] = {Offsets = {Global = CFrame.new(-0.164, -0.2533, -0.3431, 1, 0, 1e-04, 0, 1, 0, -0, 0, 1), Local = CFrame.new()}, Weapon = tbl_224, Spread = tbl_225};
local tbl_226 = {};
tbl_226.VMMovementMults = {};
local tbl_227 = {};
tbl_227.Hip = {};
v2.Bandage = {Offsets = {Global = CFrame.new(-0.0031, -0.154, -0.2158, 1, 0, 0, 0, 1, 0, 0, 0, 1), Local = CFrame.new(-0.0179, -0.026, 0.0942, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_226, Spread = tbl_227};
local tbl_228 = {};
tbl_228.VMMovementMults = {};
local tbl_229 = {};
tbl_229.Hip = {};
v2["Small Medkit"] = {Offsets = {Global = CFrame.new(-196.4214, -0.0628, -116.1838, -1, 0, 0, 0, 0, -1, 0, -1, 0), Local = CFrame.new(-0.0459, -0.1859, 0.0223, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_228, Spread = tbl_229};
local tbl_230 = {};
tbl_230.ThrowInfo = {ThrowCFrameOffset = CFrame.Angles(1.5707963267948966, 0, 0), LandOffset = CFrame.Angles(-1.5707963267948966, math.pi, 0), Explosive = {}};
tbl_230.VMMovementMults = {};
local tbl_231 = {};
tbl_231.Benches = {};
local tbl_232 = {};
tbl_232.Hip = {};
v2["Timed Charge"] = {Offsets = {Global = CFrame.new(-0.0127, -0.2815, -0.0174, 0, 0, -1, 0, -1, 0, -1, 0, 0), Local = CFrame.new(0.043, -0.0276, -0.1282, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_230, ObjectDamages = tbl_231, Spread = tbl_232};
local tbl_233 = {};
tbl_233.ThrowInfo = {ThrowCFrameOffset = CFrame.new(), LandOffset = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, 0.25), Explosive = {}};
tbl_233.VMMovementMults = {};
local tbl_234 = {};
tbl_234.Benches = {};
local tbl_235 = {};
tbl_235.Hip = {};
v2["Dynamite Bundle"] = {Offsets = {Global = CFrame.new(-0.0127, -0.2815, -0.0174, 0, 0, -1, 0, -1, 0, -1, 0, 0), Local = CFrame.new(0.043, -0.0276, -0.1282, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_233, ObjectDamages = tbl_234, Spread = tbl_235};
local tbl_236 = {};
tbl_236.ThrowInfo = {ThrowCFrameOffset = CFrame.new(), LandOffset = CFrame.Angles(0, 0, 0) * CFrame.new(0, 0, -0.18), Explosive = {}};
tbl_236.VMMovementMults = {};
local tbl_237 = {};
tbl_237.Benches = {};
local tbl_238 = {};
tbl_238.Hip = {};
v2["Dynamite Stick"] = {Offsets = {Global = CFrame.new(-0.0127, -0.2815, -0.0174, 0, 0, -1, 0, -1, 0, -1, 0, 0), Local = CFrame.new(0.043, -0.0276, -0.1282, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_236, ObjectDamages = tbl_237, Spread = tbl_238};
local tbl_239 = {};
tbl_239.ThrowInfo = {ThrowCFrameOffset = CFrame.new(), LandOffset = CFrame.Angles(0, 0, 0) * CFrame.new(0, 0, -0.18), Explosive = {}};
tbl_239.VMMovementMults = {};
local tbl_240 = {};
tbl_240.Benches = {};
local tbl_241 = {};
tbl_241.Hip = {};
v2["Military Grenade"] = {Offsets = {Global = CFrame.new(-0.0127, -0.2815, -0.0174, 0, 0, -1, 0, -1, 0, -1, 0, 0), Local = CFrame.new(0.043, -0.0276, -0.1282, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_239, ObjectDamages = tbl_240, Spread = tbl_241};
local tbl_242 = {};
tbl_242.ThrowInfo = {ThrowCFrameOffset = CFrame.new()};
tbl_242.VMMovementMults = {};
local tbl_243 = {};
tbl_243.Hip = {};
v2["Care Package Signal"] = {Offsets = {Global = CFrame.new(-0.0127, -0.2815, -0.0174, 0, 0, -1, 0, -1, 0, -1, 0, 0), Local = CFrame.new(0.043, -0.0276, -0.1282, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_242, Spread = tbl_243};
local tbl_244 = {};
tbl_244.VMMovementMults = {};
local tbl_245 = {};
tbl_245.Hip = {};
v2["Wire Cutters"] = {Offsets = {Global = CFrame.new(-0.2106, -0.4638, -0.6135, 1, 0, 0, 0, 0, 1, 0, -1, 0), Local = CFrame.new(0.212, -0.738, -0.1359, 1, 0, 0, 0, 1, 0, 0, 0, 1)}, Weapon = tbl_244, Spread = tbl_245};
local v8 = nil;
local _ = nil;
local v11 = nil;
local v9 = nil;
local v10 = nil;
for v12, value_1 in pairs(v2) do
    v10 = value_1.ObjectDamages;
    if (not (v10)) then
        continue;
    end;
    v8 = v10.Benches;
    if (not (v8)) then
        continue;
    end;
    for key_1, value_2 in pairs(v8) do
        if (value_2 == 0) then
            continue;
        end;
        if (not (key_1:find("Bench"))) then
            v9 = ((key_1:find("Twig")) and 10) or (((key_1:find("Wood")) and 250) or (((key_1:find("Stone")) and 500) or (((key_1:find("Metal")) and 1000) or 2000)));
            v8[key_1] = v9 / value_2;
        end;
    end;
end;
return v2;